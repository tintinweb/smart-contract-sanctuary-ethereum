/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract ReceiverPays  {
    
    address owner;
    // uint256 amount;
    mapping(uint256 => bool) usedNonces;


    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
    }

    // creator can deposit any amount here 
    function deposit() public payable { 
        // amount += msg.value;

        // keccak256(abi.encodePacked(reciever, msg.value, nonce, address(this)));

    }

    // function claimPayment(uint256 amount, uint256 nonce, bytes sig) public {
    //     require(!usedNonces[nonce]);
    //     usedNonces[nonce] = true;

    //     // This recreates the message that was signed on the client.
    //     bytes32 message = prefixed(keccak256(msg.sender, amount, nonce, this));

    //     require(recoverSigner(message, sig) == owner);

    //     msg.sender.transfer(amount);
    // }

    function claimPayment(uint256 amount, uint256 nonce, bytes memory sig) public {
        require(!usedNonces[nonce]);
        usedNonces[nonce] = true;
    
        // This recreates the message that was signed on the client.
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, amount, nonce, address(this)));
        bytes32 signedMessageHash = prefixed(messageHash);

        require(recoverSigner(signedMessageHash, sig) == owner);

        payable(msg.sender).transfer(amount);
    }

    

    // Builds a prefixed hash to mimic the behavior of eth_sign.
    function prefixed(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }
    
    
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8, bytes32, bytes32)
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }
    
    // input the getEthSignedHash results and the signature hash results
    // the output of this function will be the account number that signed the original message
    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        // (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }


}