// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * Signature verification contract. Consist of two parts:
 *
 * 1. Signing a message:
 *  - Create a message
 *  - Hash the message
 *  - Sign the message
 *
 * 2. Veryfing the message:
 *  - Recreate the hash from recover message
 *  - Recover signer from hash and message
 *  - Compared recover signer to claimed signer
 */

error InvalidSignatureLength();

contract Signature {
    function getMessageHash(
        address _to,
        uint256 _amount,
        string memory _message,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _amount, _message, _nonce));
    }

    /**
     * A signed message is prefix with "\x19Ethereum Signed Message:\n" and the length of the message
     * using the hashedMethod (https://docs.ethers.org/v5/api/utils/hashing/#utils-hashMessage) so that
     * is EIP-191 complaint.
     *
     * The signature will be different for each account because each account holds a unique key.
     */
    function getEhtSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function verify(
        address _signer,
        address _to,
        uint256 _amount,
        string memory _message,
        uint256 _nonce,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(_to, _amount, _message, _nonce);
        bytes32 ethSignedMessageHash = getEhtSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ehtSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ehtSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v) {
        if (sig.length != 65) {
            revert InvalidSignatureLength();
        }

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after length prefix
            r := mload(add(sig, 32))

            // second 32 bytes
            s := mload(add(sig, 64))

            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicit return (r, v, s)
    }
}

contract VerifySignature {
    function verifyMessage(
        bytes32 _hashedMessage,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixHashedMessage = keccak256(abi.encodePacked(prefix, _hashedMessage));
        address signer = ecrecover(prefixHashedMessage, _v, _r, _s);

        return signer;
    }
}