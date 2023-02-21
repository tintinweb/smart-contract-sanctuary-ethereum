/**
 *Submitted for verification at Etherscan.io on 2023-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library Signature {
    function getMessageHash(
        address _owner,
        uint _id,
        uint _stakedAt,
        uint _expiresAt
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_owner, _id, _stakedAt, _expiresAt));
    }

    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) public pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function verify(
        address _signer,
        address _owner,
        uint _id,
        uint _stakedAt,
        uint _expiresAt,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(
            _owner,
            _id,
            _stakedAt,
            _expiresAt
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }
}