// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

contract ConsumeMsg {

    function getMessageHash(
        string memory _signingMsg
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                _signingMsg
        ));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function VerifySignature(
        address verifier,
        string memory _signingMsg,
        bytes memory _signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_signingMsg);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, _signature) == verifier;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory _sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_sig.length == 65, "invalid signature length");

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }
}
contract contractUDC is ConsumeMsg{

    bytes32 public nameHash;
    address public owner;
    address private verifier = 0xE3c19B6865f2602f30537309e7f8D011eF99C1E0;
    bool internal initialized = false;

    function initializer(
        string memory _name, 
        string memory _signingMsg,
        bytes memory _signature
    ) external{
        
        require(ConsumeMsg.VerifySignature(verifier, _signingMsg, _signature), "Caller is not commited by verifier!");
        nameHash = keccak256(abi.encode(_name));
        owner = msg.sender;
        initialized = true;
    }

    function changeNameHash(string memory _newName) onlyInitialized onlyOwner external {
        nameHash = keccak256(abi.encode(_newName));
    }

    modifier onlyInitialized() {
        require(initialized, "The contract hasn't been initialized!");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "This function should be called by owner!");
        _;
    }
}