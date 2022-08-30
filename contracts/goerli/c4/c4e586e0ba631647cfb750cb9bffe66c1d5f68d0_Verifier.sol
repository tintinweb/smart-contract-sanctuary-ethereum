/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;


/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// File: contracts/Bytes.sol


pragma solidity ^0.8.2;

library Bytes {
    function toBytes32(bytes memory bz) internal pure returns (bytes32 ret) {
        require(bz.length == 32, "Bytes: toBytes32 invalid size");
        assembly {
            ret := mload(add(bz, 32))
        }
    }

    function toBytes(bytes32 data) public pure returns (bytes memory) {
        return abi.encodePacked(data);
    }

    function toBytes20(bytes memory bz) internal pure returns (bytes20 ret) {
        require(bz.length == 20, "Bytes: toBytes20 invalid size");
        assembly {
            ret := mload(add(bz, 32))
        }
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64 ret) {
        require(_bytes.length >= _start + 8, "Bytes: toUint64 out of bounds");
        assembly {
            ret := mload(add(add(_bytes, 0x8), _start))
        }
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "Bytes: toUint256 out of bounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toAddress(bytes memory _bytes) internal pure returns (address addr) {
        // convert last 20 bytes of keccak hash (bytes32) to address
        bytes32 hash = keccak256(_bytes);
        assembly {
            mstore(0, hash)
            addr := mload(0)
        }
    }

    function toTmAddress(bytes memory _bytes) internal pure returns (bytes20 addr) {
        // convert last 20 bytes of sha256 hash (bytes32) to address
        bytes32 hash = sha256(_bytes);
        assembly {
            mstore(0, hash)
            addr := mload(0)
        }
    }
}

// File: contracts/Secp256k1.sol



pragma solidity ^0.8.2;



library Secp256k1 {
    using Bytes for bytes;

    uint private constant _PUBKEY_BYTES_LEN_COMPRESSED   = 33;
    uint8 private constant _PUBKEY_COMPRESSED = 0x2;
    uint8 private constant _PUBKEY_UNCOMPRESSED = 0x4;

    /**
     * @dev verifies the secp256k1 signature against the public key and message
     * Tendermint uses RFC6979 and BIP0062 standard, meaning there is no recovery bit ("v" argument) present in the signature.
     * The "v" argument is required by the ecrecover precompile (https://eips.ethereum.org/EIPS/eip-2098) and it can be either 0 or 1.
     *
     * To leverage the ecrecover precompile this method opportunisticly guess the "v" argument. At worst the precompile is called twice,
     * which still might be cheaper than running the verification in EVM bytecode (as solidity lib)
     *
     * See: tendermint/crypto/secp256k1/secp256k1_nocgo.go (Sign, Verify methods)
     */
    function verify(bytes memory message, bytes memory publicKey, bytes memory signature) internal view returns (bool) {
        address signer = Bytes.toAddress(serializePubkey(publicKey, false));
        bytes32 hash = sha256(message);
        (address recovered, ECDSA.RecoverError error) = tryRecover(hash, signature, 27);
        if (error == ECDSA.RecoverError.NoError && recovered != signer) {
            (recovered, error) = tryRecover(hash, signature, 28);
        }

        return error == ECDSA.RecoverError.NoError && recovered == signer;
    }

    /**
     * @dev returns the address that signed the hash.
     * This function flavor forces the "v" parameter instead of trying to derive it from the signature
     *
     * Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol#L56
     */
    function tryRecover(bytes32 hash, bytes memory signature, uint8 v) internal pure returns (address, ECDSA.RecoverError) {
        if (signature.length == 65 || signature.length == 64) {
            bytes32 r;
            bytes32 s;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
            }

            return ECDSA.tryRecover(hash, v, r, s);
        } else {
            return (address(0), ECDSA.RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev check if public key is compressed (length and format)
     */
    function isCompressed(bytes memory pubkey) internal pure returns (bool) {
        return pubkey.length == _PUBKEY_BYTES_LEN_COMPRESSED && uint8(pubkey[0]) & 0xfe == _PUBKEY_COMPRESSED;
    }

    /**
     * @dev convert compressed PK to serialized-uncompressed format
     */
    function serializePubkey(bytes memory pubkey, bool prefix) internal view returns (bytes memory) {
        require(isCompressed(pubkey), "Secp256k1: PK must be compressed");

        uint8 yBit = uint8(pubkey[0]) & 1 == 1 ? 1 : 0;
        uint256 x = Bytes.toUint256(pubkey, 1);
        uint[2] memory xy = decompress(yBit, x);

        if (prefix) {
            return abi.encodePacked(_PUBKEY_UNCOMPRESSED, abi.encodePacked(xy[0]), abi.encodePacked(xy[1]));
        }

        return abi.encodePacked(abi.encodePacked(xy[0]), abi.encodePacked(xy[1]));
    }

    /**
     * @dev decompress a point 'Px', giving 'Py' for 'P = (Px, Py)'
     * 'yBit' is 1 if 'Qy' is odd, otherwise 0.
     *
     * Source: https://github.com/androlo/standard-contracts/blob/master/contracts/src/crypto/Secp256k1.sol#L82
     */
    function decompress(uint8 yBit, uint x) internal view returns (uint[2] memory point) {
        uint p = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;
        uint y2 = addmod(mulmod(x, mulmod(x, x, p), p), 7, p);
        uint y_ = modexp(y2, (p + 1) / 4, p);
        uint cmp = yBit ^ y_ & 1;
        point[0] = x;
        point[1] = (cmp == 0) ? y_ : p - y_;
    }

    /**
     * @dev modular exponentiation via EVM precompile (0x05)
     *
     * Source: https://docs.klaytn.com/smart-contract/precompiled-contracts#address-0x05-bigmodexp-base-exp-mod
     */
    function modexp(uint base, uint exponent, uint modulus) internal view returns (uint result) {
        assembly {
            // free memory pointer
            let memPtr := mload(0x40)

            // length of base, exponent, modulus
            mstore(memPtr, 0x20)
            mstore(add(memPtr, 0x20), 0x20)
            mstore(add(memPtr, 0x40), 0x20)

            // assign base, exponent, modulus
            mstore(add(memPtr, 0x60), base)
            mstore(add(memPtr, 0x80), exponent)
            mstore(add(memPtr, 0xa0), modulus)

            // call the precompiled contract BigModExp (0x05)
            let success := staticcall(gas(), 0x05, memPtr, 0xc0, memPtr, 0x20)
            switch success
            case 0 {
                revert(0x0, 0x0)
            } default {
                result := mload(memPtr)
            }
        }
    }
}

// File: contracts/Verifier.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Verifier {
    event Acceptance(bool);
    function verifyMessage2(bytes memory message, bytes memory publicKey, bytes memory signature) external {
        // bytes32 random = "HelloRandom";
        // bytes memory randomMessage = "HelloRanomMessage";

        bool isAccepted = Secp256k1.verify(message, publicKey, signature);
        emit Acceptance(isAccepted);
    }
}