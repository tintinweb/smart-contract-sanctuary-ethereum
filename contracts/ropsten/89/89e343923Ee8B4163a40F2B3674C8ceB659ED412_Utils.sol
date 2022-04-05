//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

library Utils {
    function recoverSigner(
        bytes memory hashedMessage,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public pure returns (address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", hashedMessage)
        );

        return ecrecover(messageDigest, v, r, s);
    }

    function recoverSignerFromSignedMessage(
        bytes memory hashedMessage,
        bytes memory signedMessage
    ) public pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;

        (v, r, s) = splitSignature(signedMessage);

        address signer = recoverSigner(hashedMessage, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65, "Invalid signature length");

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

    function hashArgs(
        uint16 sourceChain,
        address nativeToken,
        uint256 amount,
        address receiver
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(sourceChain, nativeToken, amount, receiver)
            );
    }

    function bytesToAddress(bytes memory bys)
        public
        pure
        returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function bytesToTxHash(bytes memory bys)
        public
        pure
        returns (bytes32 txHash)
    {
        assembly {
            txHash := mload(add(bys, 32))
        }
    }
}