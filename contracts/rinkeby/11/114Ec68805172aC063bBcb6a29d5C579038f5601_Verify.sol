/**
 *Submitted for verification at Etherscan.io on 2022-10-03
*/

// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.7;

 contract Verify {

    function VerifyMessage(address _signer, string memory _message, bytes memory _sig) external pure returns (bool) {
        bytes32 messageHash = getMessageHash(_message);
        bytes32 getEthSignMessage = getETHSignedMessageHash(messageHash);
        
        return recover(getEthSignMessage, _sig) == _signer;
    }

    function getMessageHash(string memory _message) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_message));
    }

    function getETHSignedMessageHash(bytes32 _messageHash) public pure returns(bytes32){
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32",_messageHash));
    }

    function recover(bytes32 _getEthSignMessage, bytes memory _sig) public pure returns (address) {
       (bytes32 r, uint8 v , bytes32 s) = _split(_sig);
       return ecrecover(_getEthSignMessage, v, r, s);
    }

    function _split(bytes memory _sig) internal pure returns (bytes32 r, uint8 v , bytes32 s) {
        require(_sig.length == 65, "invalid signature length");

        assembly {
            r:=mload(add(_sig,32))
            s:=mload(add(_sig,64))
            v:=byte(0,mload(add(_sig,94)))
        }
    }

}