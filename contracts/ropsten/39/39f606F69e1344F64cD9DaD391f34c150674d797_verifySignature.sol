/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract verifySignature {
    function verify(address _signer, string memory _message, bytes memory _sign) external pure returns(bool) {
        bytes32 signedMessage = messageHash(_message);
        bytes32 ethSignedMessage = ethSignedMessageHash(signedMessage);

        return recover(ethSignedMessage, _sign) == _signer;
    }

    function messageHash(string memory _message) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_message));
    }

    function ethSignedMessageHash(bytes32 _signedMessage) public pure returns(bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encodePacked(prefix,_signedMessage));
    }

    function recover(bytes32 _ethSignedMessage, bytes memory _sign) public pure returns(address) {
        (bytes32 r, bytes32 s, uint8 v) = _split(_sign);
        return ecrecover(_ethSignedMessage, v,r,s);
    }

    function _split(bytes memory _sign) internal pure returns(bytes32 r, bytes32 s, uint8 v) {
        require(_sign.length == 65, "Invalid Signature length");

        assembly {
            r := mload(add(_sign, 32))
            s := mload(add(_sign, 64))
            v := byte(0,mload(add(_sign, 96)))
        }
    }
}