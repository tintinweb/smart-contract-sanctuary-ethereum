/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract BuyMeACoffee {
    // Event to emit when a Memo is created.
    event NewMemo(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );

    // Memo struct.
    struct Memo {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }

    // Address of contract deployer. Marked payable so that
    // we can withdraw to this address later.
    address payable owner;

    // List of all memos received from coffee purchases.
    Memo[] memos;

    constructor() {
        // Store the address of the deployer as a payable address.
        // When we withdraw funds, we'll withdraw here.
        owner = payable(msg.sender);
    }

    /**
     * @dev fetches all stored memos
     */
    function getMemos() public view returns (Memo[] memory) {
        return memos;
    }

    /**
     * @dev buy a coffee for owner (sends an ETH tip and leaves a memo)
     * @param _name name of the coffee purchaser
     * @param _message a nice message from the purchaser
     */
    function buyCoffee(string memory _name, string memory _message)
        public
        payable
    {
        // Must accept more than 0 ETH for a coffee.
        require(msg.value > 0, "can't buy coffee for free!");

        // Add the memo to storage!
        memos.push(Memo(msg.sender, block.timestamp, _name, _message));

        // Emit a NewMemo event with details about the memo.
        emit NewMemo(msg.sender, block.timestamp, _name, _message);
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    function withdrawTips() public {
        require(owner.send(address(this).balance));
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    function changeOwner(address _newOwner) public {
        require(msg.sender == owner, "Only owner can change to the new owner");
        owner = payable(_newOwner);
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    function changeOwnerSign(
        bytes32 _hashedMessage,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        address _newOwner
    ) public {
        require(
            VerifyMessage(_hashedMessage, _v, _r, _s) == owner,
            "Only owner can change to the new owner"
        );
        owner = payable(_newOwner);
    }

    function VerifyMessage(
        bytes32 _hashedMessage,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _hashedMessage)
        );
        address signer = ecrecover(prefixedHashMessage, _v, _r, _s);
        return signer;
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    function changeOwnerSignature(
        bytes32 _hashedMessage,
        bytes calldata signature,
        address _newOwner
    ) public {
        require(
            recoverAddressFromSignature(_hashedMessage, signature) == owner,
            "Only owner can change to the new owner"
        );
        owner = payable(_newOwner);
    }

    function recoverAddressFromSignature(
        bytes32 _hashedMessage,
        bytes memory signature
    ) private pure returns (address) {
        require(signature.length == 65, "Invalid signature - wrong length");

        // We need to unpack the signature, which is given as an array of 65 bytes (like eth.sign)
        bytes32 r;
        bytes32 s;
        uint8 v;

        // solhint-disable-next-line
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := and(mload(add(signature, 65)), 255)
        }
        if (v < 27) {
            v += 27; // Ethereum versions are 27 or 28 as opposed to 0 or 1 which is submitted by some signing libs
        }

        // protect against signature malleability
        // S value must be in the lower half orader
        // reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/051d340171a93a3d401aaaea46b4b62fa81e5d7c/contracts/cryptography/ECDSA.sol#L53
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );

        // note that this returns 0 if the signature is invalid
        // Since 0x0 can never be a signer, when the recovered signer address
        // is checked against our signer list, that 0x0 will cause an invalid signer failure
        return ecrecover(_hashedMessage, v, r, s);
    }
}