// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

library SignatureLib {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function recoverSigner(
        bytes32 message,
        Signature memory signature
    ) public pure returns (address) {
        bytes32 prefixedHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", message)
        );
        return ecrecover(prefixedHash, signature.v, signature.r, signature.s);
    }
}