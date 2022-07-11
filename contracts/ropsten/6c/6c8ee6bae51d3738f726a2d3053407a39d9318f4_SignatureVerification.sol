/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract SignatureVerification {
    function messageHash(string memory _message) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_message));
    }

    function getEthMessageHash(bytes32 _hash) public pure returns(bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    }

    function verifySignature(string memory _message, address _signer, bytes memory _sign) public pure returns(bool) {
        bytes32 message = messageHash(_message);
        bytes32 ethMessageHash = getEthMessageHash(message);

        return recover(ethMessageHash, _sign) == _signer;
    }

    function recover(bytes32 _ethMessageHash, bytes memory _sign) public pure returns(address) {
        (bytes32 r, bytes32 s, uint8 v) = _split(_sign);
        return ecrecover(_ethMessageHash, v, r, s);
    }

    function _split(bytes memory _sign) private pure returns(bytes32 r, bytes32 s, uint8 v) {
        require(_sign.length == 65, "Invalid Signature Length");

        assembly {
            r := mload(add(_sign, 32))
            s := mload(add(_sign, 64))
            v := byte(0, mload(add(_sign, 96)))
        }
    }
}