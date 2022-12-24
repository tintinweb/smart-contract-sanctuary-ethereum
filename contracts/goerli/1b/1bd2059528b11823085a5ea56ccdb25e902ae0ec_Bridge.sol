/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

//POTENTIAL ISSUES: if keys were both compromised and they signed the messages and sent them to layer 1 without approval from layer 2, tokens will sit in this contract

contract Bridge {
    // Don't modify the order, as the sender & approver will be compacted into a single slot.
    struct Submission {
        uint256 value;
        address sender;
        bool approved;
    }

    struct SignedMessage {
        bytes sig;
        bytes32 message;
    }

    event Received(bytes32 indexed key, address indexed sender, uint256 bridgedAmount, uint256 feePaid);
    event Approved(bytes32 indexed key, address indexed sender, uint256 bridgedAmount, address approver);
    event Notarized(address indexed sender, uint256 bridgedAmount, bytes32 nonce, SignedMessage approvedMessage, SignedMessage notarizeMessage, address notary);

    address private owner;
    address private approver;
    address private notary;
    uint256 public constant eth = 1 ether;
    uint256 public fee = 5 * 10**17;
    address private feeReceiver;
    bool paused = false;

    mapping(bytes32 => Submission) private pending;
    mapping(bytes32 => SignedMessage) private approvedMessage;

    constructor(address _owner, address _approver, address _notary, address _feeReceiver){
        owner = _owner;
        approver = _approver;
        notary = _notary;
        feeReceiver = _feeReceiver;
    }

    modifier checkPaused(){
        require(paused == false);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner); // dev: invalid owner
        _;
    }

    receive() external payable { // msg.data is empty
        process();
    }

    fallback() external payable { // msg.data is NOT empty
        // TODO: Decide if we want to revert here, as this may be a call to a nonexistent function.
        //       It may also just be a message sent along with the transaction.
        process();
    }

    function getFee() public view returns(uint256){
        return fee;
    }

    function setApprover(address replacement)
    external
    onlyOwner {
        approver = replacement;
    }

    function setNotary(address replacement)
    external
    onlyOwner {
        notary = replacement;
    }

    function setPaused()
    external
    onlyOwner {
        paused = !paused;
    }

    function process()
    checkPaused
    private {
        require(tx.origin == msg.sender); // dev: sender must be the signer
        require(msg.value > fee); // dev: insufficient funds

        uint256 receiveAmount = msg.value-fee;
        require(receiveAmount > 0); //dev: invalid amount
        //TODO: should this go here or after notarized and the other amount is burned? is this the best way to transfer?
        payable(address(feeReceiver)).transfer(fee); 

        bytes32 key = keccak256(abi.encode(block.number, block.timestamp, msg.sender, receiveAmount));
        require(pending[key].sender == address(0)); // dev: submission already exists
        pending[key] = Submission(receiveAmount, msg.sender, false);

        emit Received(key, msg.sender, receiveAmount, fee);
    }

    function approve(bytes32 submission, bytes32 verifyHash, bytes memory sig)
    checkPaused
    external {
        require(pending[submission].sender != address(0)); // dev: invalid submission

        if (msg.sender == approver) {
            require(pending[submission].approved == false); // dev: already approved
            require(checkEncoding(verifyHash,  sig, submission)); // dev: invalid signed message

            pending[submission].approved = true;
            approvedMessage[submission] = SignedMessage(sig,verifyHash);
            emit Approved(submission, pending[submission].sender, pending[submission].value, approver);
        }
        else if (msg.sender == notary) {
            Submission memory s = pending[submission];
            require(s.approved); // dev: requires prior approval
            require(checkEncoding(verifyHash,  sig, submission)); //dev: invalid signed message

            (bool sent, bytes memory data) = address(0).call{value: s.value}("");
            require(sent); // dev: failed to burn eth
            delete pending[submission];

            emit Notarized(s.sender, s.value, submission, approvedMessage[submission], SignedMessage(sig,verifyHash), notary);
            delete approvedMessage[submission];

        } else {
            revert(); // dev: invalid signer
        }
    }

    function checkEncoding(bytes32 verifyHash, bytes memory sig, bytes32 submission) 
    internal view returns(bool verified){
        Submission memory sub = pending[submission];

        bytes32 hashToVerify = keccak256(
            abi.encodePacked(submission,sub.sender,sub.value)
        );

        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix,hashToVerify));
        require(verifyHash == prefixedHash); //dev: values do not match
        if(sub.approved == false){
            return approver == recoverSigner(verifyHash, sig);
        }
        else if(sub.approved){
            return notary == recoverSigner(verifyHash, sig);
        }
    }

    function splitSignature(bytes memory sig)
    internal pure returns (uint8 v, bytes32 r, bytes32 s){
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig)
        internal
        pure
        returns (address)
    {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

}