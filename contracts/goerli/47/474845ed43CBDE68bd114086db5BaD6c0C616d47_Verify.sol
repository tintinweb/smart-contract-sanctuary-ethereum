// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Verify {
    function verifySignMessage(
        bytes32 msgHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        bytes32 prefixedHash = keccak256(abi.encodePacked(msgHash));
        address signer = ecrecover(prefixedHash, v, r, s);
        return signer;
    }

    function verifyPersonalSignMessage(
        bytes32 msgHash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, msgHash));
        address signer = ecrecover(prefixedHash, v, r, s);
        return signer;
    }
}