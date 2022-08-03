//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract Verifier {
    function verifyHash(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address signer) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
        );

        return ecrecover(messageDigest, v, r, s);
    }
}