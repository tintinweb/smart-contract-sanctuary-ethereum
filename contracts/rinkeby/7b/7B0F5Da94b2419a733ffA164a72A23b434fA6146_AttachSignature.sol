// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract AttachSignature{

    function verify(address signer,  string memory message, bytes memory signature ) public pure returns (bool){
    bytes32 messageHash= getMessageHash(message);
    bytes32 ethSignedMessageHash= getEthSignedMessageHash(messageHash);
    return recoverSigner(ethSignedMessageHash,signature) == signer;
    }

    function getMessageHash(string memory message) public pure returns(bytes32){
       return keccak256(abi.encodePacked(message));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns(bytes32){
        return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32',_messageHash));
    }

    function recoverSigner(bytes32 _getEthSignedMessageHash, bytes memory signature) public pure returns(address){
        (bytes32 r, bytes32 s, uint8 v)= _split(signature);
        return ecrecover(_getEthSignedMessageHash,v,r,s);
    }
    function _split(bytes memory signature) public pure returns(bytes32 r, bytes32 s, uint8 v){
      require(signature.length==65,"Invalid Signature Length");
      assembly{
         r:=mload(add(signature,32))
         s:=mload(add(signature,64))
         v:= byte(0, mload(add(signature,96)))
      }
     

    }
}