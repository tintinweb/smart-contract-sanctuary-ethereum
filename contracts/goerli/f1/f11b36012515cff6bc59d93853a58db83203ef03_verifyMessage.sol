/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error  Invalid_Signature_Length();

contract verifyMessage {

    function verify(address _signer,string memory _message,bytes memory _signature)external pure returns(bool) {
        bytes32 messageHash = getMessageHash(_message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recover(ethSignedMessageHash, _signature) == _signer;
    }

    function getMessageHash(string memory message) public pure  returns (bytes32){
        return keccak256(abi.encodePacked(message));
    }

    function getEthSignedMessageHash(bytes32 ethSignedMessageHash) public pure returns(bytes32){
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",ethSignedMessageHash));
    }

    function recover(bytes32 _ethSignedMessageHash,bytes memory  signature) public pure returns(address){
        (bytes32 r,bytes32 s,uint8 v) = _split(signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _split(bytes memory _signature) internal pure returns(bytes32 r,bytes32 s,uint8 v){
       
        if(_signature.length != 65){
            revert Invalid_Signature_Length();
        }

        assembly {
            r := mload(add(_signature,32))
            s := mload(add(_signature,64))
            v := byte(0,mload(add(_signature,96)))
        }
    }

}