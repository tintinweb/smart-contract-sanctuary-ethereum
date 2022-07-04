pragma solidity ^0.8.12;



// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)
/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)
/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)
/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)
/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)
/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)
/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)
/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)
/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)
/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)
/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)
/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)
/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 51
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal onlyInitializing {
        __EIP712_init_unchained(name, "1");
    }

    function __ERC20Permit_init_unchained(string memory) internal onlyInitializing {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

library BalanceQueue {
    
    struct QueueStorage {
        mapping(uint32 => BalanceData) data;
        uint32 first;
        uint32 last;
    }

    struct BalanceData {
        uint32 blockNumber;
        uint96 value;
    }

    modifier isNotEmpty(QueueStorage storage queue) {
        require(!_isEmpty(queue), "Queue is empty.");
        _;
    }

    /**
     * @dev Sets the queue's initial state, with a queue size of 0.
     * @param queue QueueStorage struct from contract.
     */
    function _initialize(QueueStorage storage queue) internal {
        queue.first = 1;
        queue.last = 0;
    }

    /**
     * @dev Gets the number of elements in the queue. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function _length(QueueStorage storage queue)
        internal
        view
        returns (uint256)
    {
        if (queue.last < queue.first || queue.last == 0) {
            return 0;
        }
        return queue.last - queue.first + 1;
    }

    /**
     * @dev Returns if queue is empty. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function _isEmpty(QueueStorage storage queue) internal view returns (bool) {
        return _length(queue) == 0;
    }

    /**
     * @dev Adds an element to the back of the queue. O(1)
     * @param queue QueueStorage struct from contract.
     * @param blockNumber_ blocknumber when balance data is added.
     * @param value_ blocknumber when balance data is added.
     */
    function _enqueue(
        QueueStorage storage queue,
        uint32 blockNumber_,
        uint96 value_
    ) internal {
        queue.data[++queue.last] = BalanceData({blockNumber: blockNumber_,value: value_});
    }

    /**
     * @dev Removes an element from the front of the queue and returns it. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function _dequeue(QueueStorage storage queue)
        internal
        isNotEmpty(queue)
        returns (BalanceData memory data)
    {
        data = queue.data[queue.first];
        delete queue.data[queue.first++];
    }

    /**
     * @dev Returns the data from the front of the queue, without removing it. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function _peek(QueueStorage storage queue)
        internal
        view
        isNotEmpty(queue)
        returns (BalanceData storage)
    {
        return queue.data[queue.first];
    }

    /**
     * @dev Returns the data from the back of the queue. O(1)
     * @param queue QueueStorage struct from contract.
     */
    function _peekLast(QueueStorage storage queue)
        internal
        view
        isNotEmpty(queue)
        returns (BalanceData storage)
    {
        return queue.data[queue.last];
    }    
}

// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)
/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)
/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)
/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)
/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)
/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)
/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)
/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

library GluwacoinModel {   
    /**
     * @dev Enum of the different domains of signature.
     */
    enum SigDomain {
        /*0*/
        Nothing,
        /*1*/
        Burn,
        /*2*/
        Mint,
        /*3*/
        Transfer,
        /*4*/
        Reserve
    }
}

/**
 * @dev Signature verification
 */
library Validate {    
    using ECDSAUpgradeable for bytes32;

    /**
     * @dev Throws if given `sig` is an incorrect signature of the `sender`.
     */
    function validateSignature(bytes32 hash, address sender, bytes memory sig) internal pure {
        bytes32 messageHash = hash.toEthSignedMessageHash();

        address signer = messageHash.recover(sig);
        require(signer == sender, "Validate: invalid signature");
    }
}

/**
 * @dev Extension of {ERC20} that allows users to send ETHless transfer by hiring a transaction relayer to pay the
 * gas fee for them. The relayer gets paid in this ERC20 token for `fee`.
 */
abstract contract ERC20ETHless is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ERC20Upgradeable
{  
    mapping(address => mapping(uint256 => bool)) private _usedNonces;

    // collects transaction relay fee
    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    function __ERC20ETHless_init(string memory name, string memory symbol)
        internal
        initializer
    {        
        __Context_init_unchained(); 
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20ETHless_init_unchained();
    }

    function __ERC20ETHless_init_unchained() internal onlyInitializing {
        _setupRole(RELAYER_ROLE, _msgSender());
    }

    /**
     * @dev Moves `amount` tokens from the `sender`'s account to `recipient`
     * and moves `fee` tokens from the `sender`'s account to a relayer's address.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits two {Transfer} events.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the `sender` must have a balance of at least the sum of `amount` and `fee`.
     * - the `nonce` is only used once per `sender`.
     */
    function transfer(
        address sender,
        address recipient,
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        bytes calldata sig
    ) external returns (bool success) {
        uint256 senderBalance = balanceOf(sender);
        require(
            senderBalance >= (amount + fee),
            "ERC20ETHless: the balance is not sufficient"
        );

        _useNonce(sender, nonce);

        bytes32 hash = keccak256(
            abi.encodePacked(
                GluwacoinModel.SigDomain.Transfer,
                block.chainid,
                address(this),
                sender,
                recipient,
                amount,
                fee,
                nonce
            )
        );
        Validate.validateSignature(hash, sender, sig);

        _collect(sender, fee);
        _transfer(sender, recipient, amount);

        return true;
    }

    /* @dev Uses `nonce` for the signer.
     */
    function _useNonce(address signer, uint256 nonce) private {
        require(
            !_usedNonces[signer][nonce],
            "ERC20ETHless: the nonce has already been used for this address"
        );
        _usedNonces[signer][nonce] = true;
    }

    /** @dev Collects `fee` from the sender.
     *
     * Emits a {Transfer} event.
     */
    function _collect(address sender, uint256 amount) internal {
        address relayer = getRoleMember(RELAYER_ROLE, 0);

        _transfer(sender, relayer, amount);
    }

    uint256[50] private __gap;
}

/**
 * @dev Extension of {ERC20} that allows users to escrow a transfer. When the fund is reserved, the sender designates
 * an `executor` of the `reserve`. The `executor` can `release` the fund to the pre-defined `recipient` and collect
 * a `fee`. If the `reserve` gets expired without getting executed, the `sender` or the `executor` can `reclaim`
 * the fund back to the `sender`.
 */
abstract contract ERC20Reservable is Initializable, ERC20Upgradeable {
        
    enum ReservationStatus {
        Draft,
        Active,
        Reclaimed,
        Completed
    }

    struct Reservation {
        uint256 _amount;
        uint256 _fee;
        address _recipient;
        address _executor;
        uint256 _expiryBlockNum;
        ReservationStatus _status;
    }

    /// @dev Address mapping to mapping of nonce to amount and expiry for that nonce.
    mapping(address => mapping(uint256 => Reservation)) private _reserved;

    /// @dev Total amount of reserved balance for address
    mapping(address => uint256) private _totalReserved;

    function __ERC20Reservable_init(string memory name, string memory symbol)
        internal
        initializer
    {
        __Context_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20Reservable_init_unchained();
    }

    function __ERC20Reservable_init_unchained() internal onlyInitializing {}

    /// @notice Retrieve a reserved record
    /// @param sender The token owner address whose token is reserved
    /// @param nonce The unique number to retrieve reserved data for each address
    /// @return amount in reserved for a specific address and nonce
    /// @return fee in reserved fee paid during executing a reserve
    /// @return recipient the address received the reserved amount less fee
    /// @return executor in reserved for a specific address and nonce
    /// @return expiryBlockNum the block number after which the reserved amount will be expired
    /// @return status in the reserve record
    function getReservation(address sender, uint256 nonce)
        external
        view
        returns (
            uint256 amount,
            uint256 fee,
            address recipient,
            address executor,
            uint256 expiryBlockNum,
            ReservationStatus status
        )
    {
        Reservation storage reservation = _reserved[sender][nonce];

        amount = reservation._amount;
        fee = reservation._fee;
        recipient = reservation._recipient;
        executor = reservation._executor;
        expiryBlockNum = reservation._expiryBlockNum;
        status = reservation._status;
    }

    /// @notice Get total amount in all reserves for an address.
    /// @param account The token owner address
    /// @return amount total amount put in all reserves of the given address
    function reservedBalanceOf(address account)
        external
        view
        returns (uint256 amount)
    {
        return balanceOf(account) - _unreservedBalance(account);
    }

    /// @notice Get total amount not in any reserve for an address.
    /// @param account The token owner address
    /// @return amount total amount put not in any reserve of the given address
    function unreservedBalanceOf(address account)
        external
        view
        returns (uint256 amount)
    {
        return _unreservedBalance(account);
    }

    /// @notice Create a reserved record
    /// @param sender The token owner address whose token is reserved
    /// @param recipient the address received the reserved amount less fee
    /// @param executor in reserved for a specific address and nonce
    /// @param amount in reserved for a specific address and nonce
    /// @param fee in reserved fee paid during executing a reserve
    /// @param nonce The unique number to retrieve reserved data for each address
    /// @param expiryBlockNum the block number after which the reserved amount will be expired
    /// @param sig the signature to include all the above params signed by the user's private key to authorize the reserve
    /// @return success indicate the outcome of the reserve funciton
    function reserve(
        address sender,
        address recipient,
        address executor,
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        uint256 expiryBlockNum,
        bytes calldata sig
    ) external returns (bool success) {
        require(
            _reserved[sender][nonce]._expiryBlockNum == 0,
            "ERC20Reservable: the sender used the nonce already"
        );

        require(
            expiryBlockNum > block.number,
            "ERC20Reservable: invalid block expiry number"
        );
        require(
            executor != address(0),
            "ERC20Reservable: cannot execute from zero address"
        );

        uint256 total = amount + fee;
        require(
            _unreservedBalance(sender) >= total,
            "ERC20Reservable: insufficient unreserved balance"
        );

        bytes32 hash = keccak256(
            abi.encodePacked(
                GluwacoinModel.SigDomain.Reserve,
                block.chainid,
                address(this),
                sender,
                recipient,
                executor,
                amount,
                fee,
                nonce,
                expiryBlockNum
            )
        );
        Validate.validateSignature(hash, sender, sig);

        _reserved[sender][nonce] = Reservation(
            amount,
            fee,
            recipient,
            executor,
            expiryBlockNum,
            ReservationStatus.Active
        );
        _totalReserved[sender] = _totalReserved[sender] + total;

        return true;
    }

    /// @notice Execute a reserved record before expired block
    /// @dev transaction caller must be the executor or the reserve's owner (sender)
    /// @param sender The token owner address whose token is reserved    
    /// @param nonce The unique number to retrieve reserved data for each address   
    /// @return success indicate the outcome of the execute funciton
    function execute(address sender, uint256 nonce)
        external
        returns (bool success)
    {
        Reservation storage reservation = _reserved[sender][nonce];

        require(
            reservation._expiryBlockNum != 0,
            "ERC20Reservable: reservation does not exist"
        );
        require(
            _msgSender() == sender || _msgSender() == reservation._executor,
            "ERC20Reservable: this address is not authorized to execute this reservation"
        );
        require(
            reservation._expiryBlockNum > block.number,
            "ERC20Reservable: reservation has expired and cannot be executed"
        );
        require(
            reservation._status == ReservationStatus.Active,
            "ERC20Reservable: invalid reservation status to execute"
        );

        address executor = reservation._executor;
        address recipient = reservation._recipient;
        uint256 fee = reservation._fee;
        uint256 amount = reservation._amount;
        uint256 total = amount + fee;

        _reserved[sender][nonce]._status = ReservationStatus.Completed;
        _totalReserved[sender] = _totalReserved[sender] - total;

        _transfer(sender, executor, fee);
        _transfer(sender, recipient, amount);

        return true;
    }

    /// @notice Reclaim a reserved record on or after expired block
    /// @dev transaction caller must be the executor or the reserve's owner (sender)
    /// @param sender The token owner address whose token is reserved    
    /// @param nonce The unique number to retrieve reserved data for each address   
    /// @return success indicate the outcome of the reclaim funciton
    function reclaim(address sender, uint256 nonce)
        external
        returns (bool success)
    {
        Reservation storage reservation = _reserved[sender][nonce];

        require(
            reservation._expiryBlockNum != 0,
            "ERC20Reservable: reservation does not exist"
        );
        require(
            _msgSender() == sender || _msgSender() == reservation._executor,
            "ERC20Reservable: only the sender or the executor can reclaim the reservation back to the sender"
        );
        require(
            reservation._expiryBlockNum <= block.number ||
                _msgSender() == reservation._executor,
            "ERC20Reservable: reservation has not expired or you are not the executor and cannot be reclaimed"
        );
        require(
            reservation._status == ReservationStatus.Active,
            "ERC20Reservable: invalid reservation status to reclaim"
        );

        _reserved[sender][nonce]._status = ReservationStatus.Reclaimed;
        _totalReserved[sender] =
            _totalReserved[sender] -
            reservation._amount -
            reservation._fee;

        return true;
    }

    function _unreservedBalance(address sender)
        internal
        view
        returns (uint256 amount)
    {
        return balanceOf(sender) - _totalReserved[sender];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable) {
        if (from != address(0)) {
            require(
                _unreservedBalance(from) >= amount,
                "ERC20Reservable: transfer amount exceeds unreserved balance"
            );
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    uint256[50] private __gap;
}

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)
/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @dev Extension of {ERC20} that allows a certain ERC20 token holders to wrap the token to mint this token.
 * Holder of this token can retrieve the wrapped token by burning this token.
 */
abstract contract ERC20Wrapper is
    Initializable,
    AccessControlEnumerableUpgradeable,
    ERC20Upgradeable
{    
    using SafeERC20Upgradeable for IERC20Upgradeable;
    // base token, the token to be wrapped
    IERC20Upgradeable internal _token;

    mapping(address => mapping(uint256 => bool)) private _usedNonces;

    // collects mint/burn relay fee
    bytes32 public constant WRAPPER_ROLE = keccak256("WRAPPER_ROLE");

    event Mint(address indexed _mintTo, uint256 _value);
    event Burnt(address indexed _burnFrom, uint256 _value);

    function __ERC20Wrapper_init(
        string memory name,
        string memory symbol,
        IERC20Upgradeable baseToken
    ) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20Wrapper_init_unchained(baseToken);
    }

    function __ERC20Wrapper_init_unchained(IERC20Upgradeable baseToken)
        internal
        virtual
        onlyInitializing
    {
        _setupToken(baseToken);
        _setupRole(WRAPPER_ROLE, _msgSender());
    }

    /**
     * @dev Returns the address of the base token.
     */
    function token() external view returns (IERC20Upgradeable) {
        return _token;
    }

    /**
     * @dev Creates `amount` tokens to the caller, transferring base tokens from the caller to the contract.
     *
     * See {ERC20-_mint} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have base tokens of at least `amount`.
     * - the contract must have allowance for caller's base tokens of at least
     * `amount`.
     */
    function mint(uint256 amount) external {
        __mint(_msgSender(), amount);
    }

    /**
     * @dev `mint` but with `minter`, `fee`, `nonce`, and `sig` as extra parameters.
     * `fee` is a mint fee amount in Gluwacoin, which the minter will pay for the mint.
     * `sig` is a signature created by signing the mint information with the minter’s private key.
     * Anyone can initiate the mint for the minter by calling the Etherless Mint function
     * with the mint information and the signature.
     * The caller will have to pay the gas for calling the function.
     *
     * Transfers `amount` + `fee` of base tokens from the minter to the contract using `transferFrom`.
     * Creates `amount` + `fee` of tokens to the minter and transfers `fee` tokens to the caller.
     *
     * See {ERC20-_mint} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the minter must have base tokens of at least `amount`.
     * - the contract must have allowance for receiver's base tokens of at least `amount`.
     * - `fee` will be deducted after successfully minting
     */
    function mint(
        address minter,
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        bytes calldata sig
    ) external virtual {
        _useWrapperNonce(minter, nonce);

        bytes32 hash = keccak256(
            abi.encodePacked(
                GluwacoinModel.SigDomain.Mint,
                block.chainid,
                address(this),
                minter,
                amount,
                fee,
                nonce
            )
        );
        Validate.validateSignature(hash, minter, sig);

        __mint(minter, amount);

        address wrapper = getRoleMember(WRAPPER_ROLE, 0);

        _transfer(minter, wrapper, fee);
    }

    /**
     * @dev Destroys `amount` tokens from the caller, transferring base tokens from the contract to the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) external {
        __burn(_msgSender(), amount);
    }

    /**
     * @dev `burn` but with `burner`, `fee`, `nonce`, and `sig` as extra parameters.
     * `fee` is a burn fee amount in Gluwacoin, which the burner will pay for the burn.
     * `sig` is a signature created by signing the burn information with the burner’s private key.
     * Anyone can initiate the burn for the burner by calling the Etherless Burn function
     * with the burn information and the signature.
     * The caller will have to pay the gas for calling the function.
     *
     * Destroys `amount` + `fee` tokens from the burner.
     * Transfers `amount` of base tokens from the contract to the burner and `fee` of base token to the caller.
     *
     * See {ERC20-_burn}.
     *
     * Requirements:
     *
     * - the burner must have tokens of at least `amount`, the `fee` is included in the amount.
     */
    function burn(
        address burner,
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        bytes calldata sig
    ) external virtual {
        uint256 burnerBalance = balanceOf(burner);
        require(
            burnerBalance >= amount,
            "ERC20Wrapper: burn amount exceed balance"
        );

        _useWrapperNonce(burner, nonce);

        bytes32 hash = keccak256(
            abi.encodePacked(
                GluwacoinModel.SigDomain.Burn,
                block.chainid,
                address(this),
                burner,
                amount,
                fee,
                nonce
            )
        );
        Validate.validateSignature(hash, burner, sig);

        address wrapper = getRoleMember(WRAPPER_ROLE, 0);
        _transfer(burner, wrapper, fee);

        __burn(burner, amount - fee);
    }    

    function __mint(address account, uint256 amount) internal virtual {
        _token.safeTransferFrom(account, address(this), amount);
        emit Mint(account, amount);

        _mint(account, amount);
    }

    function __burn(address account, uint256 amount) internal virtual {       
        _token.safeTransfer(account, amount);
        emit Burnt(account, amount);

        _burn(account, amount);
    }

    /**
     * @dev Sets {token} as the base token.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {token} to ever change, and may work incorrectly if it does.
     */
    function _setupToken(IERC20Upgradeable token_) internal {
        _token = token_;
    }

    /* @dev Uses `nonce` for the signer.
     */
    function _useWrapperNonce(address signer, uint256 nonce) internal {
        require(
            !_usedNonces[signer][nonce],
            "ERC20Wrapper: the nonce has already been used for this address"
        );
        _usedNonces[signer][nonce] = true;
    }

    uint256[50] private __gap;
}

/**
 * @dev Extension of {Gluwacoin} that allows a certain ERC20 token holders to wrap the token to mint this token.
 * Holder of this token can retrieve the wrapped token by burning this token.
 */
contract ERC20WrapperGluwacoin is
    Initializable,
    ContextUpgradeable,
    ERC20Wrapper,
    ERC20ETHless,
    ERC20Reservable
{
    uint8 private _decimals;

    /// @dev `decimals` must match that of `token`
    function initialize(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        address admin,
        IERC20Upgradeable token
    ) public virtual {
        __ERC20WrapperGluwacoin_init(name, symbol, decimals_, admin, token);
    }

    /// @notice Return a number of decimals of the token
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function __ERC20WrapperGluwacoin_init(
        string memory name,
        string memory symbol,
        uint8 decimals_,
        address admin,
        IERC20Upgradeable token
    ) internal initializer {
        _decimals = decimals_;
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20Wrapper_init_unchained(token);
        __ERC20ETHless_init_unchained();
        __ERC20Reservable_init_unchained();
        __ERC20WrapperGluwacoin_init_unchained(decimals_, admin);
    }

    function __ERC20WrapperGluwacoin_init_unchained(
        uint8 decimals_,
        address admin
    ) internal onlyInitializing {
        _decimals = decimals_;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20Reservable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    uint256[50] private __gap;
}

interface IStakedVotesUpgradeable {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    /**
     * @dev Stake tokens on a given `daoContract`.
     */
    function stake(uint256 amount) external returns (bool);

    /**
     * @dev Stake tokens from signer on a given `daoContract`.
     */
    function stakeBySig(
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    /**
     * @dev Unstake tokens on a given `daoContract`.
     */
    function unstake(uint256 amount) external returns (bool);

    /**
     * @dev Unstake tokens from signer on a given `daoContract`.
     */
    function unstakeBySig(
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    /**
     * @dev Returns the amount of staked token that `account` made across all the supported contracts.
     */
    function stakeOf(address stakeholder) external view returns (uint256);

    /**
     * @dev Returns the total tokens of an address used to be staked token at the end of a past block (`blockNumber`).
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function stakeOf(address stakeholder, uint256 blockNumber)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had for a given `daoContract` at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the total staked token available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all total staked token for a croos all the `daoContract`.
     */
    function getPastTotalStaked(uint256 blockNumber)
        external
        view
        returns (uint256);

    /**
     * @dev Returns the current total staked tokens made by all users.
     * It is but NOT the sum of all the delegated votes!
    */
    function getTotalStaked() external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen for a given `daoContract`.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee` on a given `daoContract`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee` on a given `daoContract`.
     */
    function delegateBySig(
        address delegatee,
        uint256 fee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns(bool);
}

interface IRewardToken is IERC20Upgradeable{
   
    /**
     * @dev Update accumulatedPerBlock and user.debt when stake() is called
     */
    function updateAccumulatedWhenStake(address account, uint256 amount) external;
    /**
     * @dev Update accumulatedPerBlock and user.debt when unstake() is called
     */
    function updateAccumulatedWhenUnstake(address account, uint256 amount) external;

}

contract ERC20StakedVotesUpgradeable is
    IStakedVotesUpgradeable,
    Initializable,
    ERC20WrapperGluwacoin,
    ERC20PermitUpgradeable
{
    using BalanceQueue for BalanceQueue.QueueStorage;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    bytes32 private constant _STAKE_TYPEHASH =
        keccak256(
            "stake(uint256 amount,uint256 fee,uint256 nonce,uint256 expiry)"
        );

    bytes32 private constant _UNSTAKE_TYPEHASH =
        keccak256(
            "unstake(uint256 amount,uint256 fee,uint256 nonce,uint256 expiry)"
        );

    bytes32 private constant _MINTTOSTAKE_TYPEHASH =
        keccak256(
            "mintToStake(uint256 amount,uint256 fee,uint256 nonce,uint256 expiry)"
        );

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256(
            "delegate(address delegatee,uint256 fee,uint256 nonce,uint256 expiry)"
        );

    /// @dev due to limitted supply of GTD, we can minimize the checkpoint storage as below
    struct Checkpoint {
        uint32 fromBlock;
        uint96 balance;
    }

    IRewardToken private _rewardingToken;
    mapping(address => address) private _delegates;

    /// @dev checkpoints for staked amount
    mapping(address => Checkpoint[]) private _shareholderStakedCheckpoints;
    mapping(address => BalanceQueue.QueueStorage)
        private _tokenDelayedBalanceCheckpoints;
    mapping(address => Checkpoint[]) private _votingCheckpoints;

    Checkpoint[] private _totalStakedCheckpoints;

    uint8 private _processingCap;
    uint32 private _stakingLockup;
    uint32 private _unstakingLockup;
    uint32 private _wrappingRate;

    address public daoContract;

    function __ERC20StakedVotesUpgradeable_init(
        string calldata name,
        string calldata symbol,
        uint8 decimals_,
        address admin,
        uint8 processingCap,
        uint32 wrappingRate,
        uint32 stakingLockup,
        uint32 unstakingLockup,
        IERC20Upgradeable token
    ) internal onlyInitializing {
        __ERC20StakedVotesUpgradeable_init_unchained(
            name,
            symbol,
            decimals_,
            admin,
            processingCap,
            wrappingRate,
            stakingLockup,
            unstakingLockup,
            token
        );
    }

    function __ERC20StakedVotesUpgradeable_init_unchained(
        string calldata name,
        string calldata symbol,
        uint8 decimals_,
        address admin,
        uint8 processingCap,
        uint32 wrappingRate,
        uint32 stakingLockup,
        uint32 unstakingLockup,
        IERC20Upgradeable token
    ) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
        __ERC20_init_unchained(name, symbol);
        __ERC20Wrapper_init_unchained(token);
        __ERC20ETHless_init_unchained();
        __ERC20Reservable_init_unchained();
        __ERC20WrapperGluwacoin_init_unchained(decimals_, admin);
        _processingCap = processingCap;
        _wrappingRate = wrappingRate;
        _stakingLockup = stakingLockup;
        _unstakingLockup = unstakingLockup;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "ERC20StakedVotesUpgradeable: Restricted to Admin."
        );
        _;
    }

    function updateSupportedDAOContract(address daoContract_)
        external
        onlyAdmin
        returns (bool)
    {
        daoContract = daoContract_;
        return true;
    }

    function setRewardingToken(IRewardToken rewardingToken) external onlyAdmin {
        _rewardingToken = rewardingToken;
    }

    function settings()
        external
        view
        returns (
            uint8,
            uint32,
            uint32,
            uint32
        )
    {
        return (
            _processingCap,
            _wrappingRate,
            _stakingLockup,
            _unstakingLockup
        );
    }

    function applySettings(
        uint8 processingCap,
        uint32 wrappingRate,
        uint32 stakingLockup,
        uint32 unstakingLockup
    ) external onlyAdmin {
        _processingCap = processingCap;
        _wrappingRate = wrappingRate;
        _stakingLockup = stakingLockup;
        _unstakingLockup = unstakingLockup;
    }

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos)
        public
        view
        virtual
        returns (Checkpoint memory)
    {
        return _shareholderStakedCheckpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints of staked amount for `account`.
     */
    function numStakedCheckpoints(address account)
        public
        view
        virtual
        returns (uint32)
    {
        return
            SafeCastUpgradeable.toUint32(
                _shareholderStakedCheckpoints[account].length
            );
    }

    /**
     * @dev Get number of checkpoints of for `account` balance.
     */
    function numDelayedBalanceCheckpoints(address account)
        public
        view
        virtual
        returns (uint32)
    {
        return
            SafeCastUpgradeable.toUint32(
                _tokenDelayedBalanceCheckpoints[account]._length()
            );
    }

    /**
     * @dev Get number of checkpoints of total staked amount.
     */
    function numTotalStakedCheckpoints() public view virtual returns (uint32) {
        return SafeCastUpgradeable.toUint32(_totalStakedCheckpoints.length);
    }

    /**
     * @dev Gets the current votes balance for `account`.
     */
    function getVotes(address account) public view virtual returns (uint256) {
        uint256 pos = _votingCheckpoints[account].length;
        return pos == 0 ? 0 : _votingCheckpoints[account][pos - 1].balance;
    }

    /**
     * @dev Gets the current balance for `account`
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return super.balanceOf(account) - _getDelayedBalance(account);
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber)
        public
        view
        virtual
        returns (uint256)
    {
        require(blockNumber <= block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_votingCheckpoints[account], blockNumber);
    }

    /**
     * @dev Returns the total tokens used to be staked token at the end of a past block (`blockNumber`).
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalStaked(uint256 blockNumber)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalStakedCheckpoints, blockNumber);
    }

    /**
     * @dev Returns the current total staked tokens made by all users.
     * It is but NOT the sum of all the delegated votes!
     */
    function getTotalStaked() public view virtual override returns (uint256) {
        uint256 pos = _totalStakedCheckpoints.length;
        return pos == 0 ? 0 : _totalStakedCheckpoints[pos - 1].balance;
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber)
        private
        view
        returns (uint256)
    {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        unchecked {
            while (low < high) {
                uint256 mid = MathUpgradeable.average(low, high);
                if (ckpts[mid].fromBlock > blockNumber) {
                    high = mid;
                } else {
                    low = mid + 1;
                }
            }
        }
        return high == 0 ? 0 : ckpts[high - 1].balance;
    }

    function _mint(address account, uint256 amount) internal override {
        super._mint(account, amount / _wrappingRate);
    }

    /// @dev to avoid unfair loss of token due to rounding down, we will exclude the remainder during token wrapping
    function __mint(address account, uint256 amount) internal override {
        uint256 remainder = amount % _wrappingRate;
        super.__mint(account, amount - remainder);
    }

    function __burn(address account, uint256 amount) internal override {
        _token.safeTransfer(account, amount * _wrappingRate);
        emit Burnt(account, amount);

        _burn(account, amount);
    }

    /**
     * @dev `mint` but with `minter`, `fee`, `nonce`, and `sig` as extra parameters.
     * `fee` is a mint fee amount in Gluwacoin, which the minter will pay for the mint.
     * `sig` is a signature created by signing the mint information with the minter’s private key.
     * Anyone can initiate the mint for the minter by calling the Etherless Mint function
     * with the mint information and the signature.
     * The caller will have to pay the gas for calling the function.
     *
     * Transfers `amount` + `fee` of base tokens from the minter to the contract using `transferFrom`.
     * Creates `amount` + `fee` of tokens to the minter and transfers `fee` tokens to the caller.
     *
     * See {ERC20-_mint} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the minter must have base tokens of at least `amount`.
     * - the contract must have allowance for receiver's base tokens of at least `amount`.
     * - `fee` will be deducted after successfully minting
     */
    function mint(
        address minter,
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        bytes calldata sig
    ) external override {
        _useWrapperNonce(minter, nonce);

        bytes32 hash = keccak256(
            abi.encodePacked(
                GluwacoinModel.SigDomain.Mint,
                block.chainid,
                address(this),
                minter,
                amount,
                fee,
                nonce
            )
        );
        Validate.validateSignature(hash, minter, sig);

        __mint(minter, amount);
        _transfer(minter, _msgSender(), fee);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account)
        public
        view
        virtual
        override
        returns (address)
    {
        return _delegates[account];
    }

    function mintToStake(uint256 amount) external virtual returns (bool) {
        __mint(_msgSender(), amount);
        _stake(_msgSender(), amount / _wrappingRate);
        return true;
    }

    function mintToStakeBySig(
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (bool) {
        require(
            expiry >= block.timestamp,
            "ERC20StakedVotesUpgradeable: Sig is expired"
        );
        address stakeholder = ECDSAUpgradeable.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _MINTTOSTAKE_TYPEHASH,
                        amount,
                        fee,
                        nonce,
                        expiry
                    )
                )
            ),
            v,
            r,
            s
        );
        _useWrapperNonce(stakeholder, nonce);
        __mint(stakeholder, amount);
        _transfer(stakeholder, _msgSender(), fee);
        _stake(stakeholder, (amount / _wrappingRate) - fee);
        return true;
    }

    function _stake(address stakeholder, uint256 amount)
        internal
        returns (bool)
    {
        _transfer(stakeholder, daoContract, amount);
        _writeCheckpoint(_totalStakedCheckpoints, _add, amount, block.number);
        _writeCheckpoint(
            _shareholderStakedCheckpoints[stakeholder],
            _add,
            amount,
            block.number
        );
        if (_delegates[stakeholder] == address(0)) {
            _delegates[stakeholder] = stakeholder;
        }
        _rewardingToken.updateAccumulatedWhenStake(stakeholder, amount);

        _moveVotingPower(address(0), _delegates[stakeholder], amount);
        return true;
    }

    function _unstake(address stakeholder, uint256 amount)
        internal
        returns (bool)
    {
        /// @dev amount must be > 0 to reduce queue item
        require(
            stakeOf(stakeholder) >= amount && amount > 0,
            "ERC20StakedVotesUpgradeable: Invalid amount"
        );
        _transfer(daoContract, stakeholder, amount);
        _writeCheckpoint(
            _totalStakedCheckpoints,
            _subtract,
            amount,
            block.number
        );
        _writeCheckpoint(
            _shareholderStakedCheckpoints[stakeholder],
            _subtract,
            amount,
            block.number
        );
        BalanceQueue.QueueStorage
            storage balanceQueue = _tokenDelayedBalanceCheckpoints[stakeholder];
        uint8 processingCount;
        if (balanceQueue._isEmpty()) {
            balanceQueue._initialize();
        } else {
            while (
                !balanceQueue._isEmpty() &&
                balanceQueue._peek().blockNumber <= block.number &&
                processingCount < _processingCap
            ) {
                balanceQueue._dequeue();
                processingCount++;
            }
        }
        balanceQueue._enqueue(
            SafeCastUpgradeable.toUint32(block.number + _unstakingLockup),
            SafeCastUpgradeable.toUint96(amount)
        );

        _rewardingToken.updateAccumulatedWhenUnstake(stakeholder, amount);
        _moveVotingPower(_delegates[stakeholder], address(0), amount);
        return true;
    }

    function stake(uint256 amount) external virtual override returns (bool) {
        require(
            amount > 0,
            "ERC20StakedVotesUpgradeable: Cannot stake 0 amount"
        );
        return _stake(_msgSender(), amount);
    }

    function stakeBySig(
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (bool) {
        require(
            amount > 0,
            "ERC20StakedVotesUpgradeable: Cannot stake 0 amount"
        );
        require(
            expiry >= block.timestamp,
            "ERC20StakedVotesUpgradeable: Sig is expired"
        );
        address stakeholder = ECDSAUpgradeable.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(_STAKE_TYPEHASH, amount, fee, nonce, expiry)
                )
            ),
            v,
            r,
            s
        );
        _useWrapperNonce(stakeholder, nonce);
        _transfer(stakeholder, _msgSender(), fee);
        return _stake(stakeholder, amount);
    }

    function unstake(uint256 amount) external virtual override returns (bool) {
        return _unstake(_msgSender(), amount);
    }

    function unstakeBySig(
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (bool) {
        require(
            expiry >= block.timestamp,
            "ERC20StakedVotesUpgradeable: Sig is expired"
        );
        address stakeholder = ECDSAUpgradeable.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(_UNSTAKE_TYPEHASH, amount, fee, nonce, expiry)
                )
            ),
            v,
            r,
            s
        );
        _useWrapperNonce(stakeholder, nonce);
        _transfer(stakeholder, _msgSender(), fee);
        return _unstake(stakeholder, amount);
    }

    function stakeOf(address stakeholder)
        public
        view
        override
        returns (uint256)
    {
        uint256 pos = _shareholderStakedCheckpoints[stakeholder].length;
        return
            pos == 0
                ? 0
                : _shareholderStakedCheckpoints[stakeholder][pos - 1].balance;
    }

    /**
     * @dev Returns the total tokens of an address used to be staked token at the end of a past block (`blockNumber`).
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function stakeOf(address stakeholder, uint256 blockNumber)
        public
        view
        override
        returns (uint256)
    {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return
            _checkpointsLookup(
                _shareholderStakedCheckpoints[stakeholder],
                blockNumber
            );
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external virtual {
        _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 fee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual override returns (bool) {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSAUpgradeable.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        _DELEGATION_TYPEHASH,
                        delegatee,
                        fee,
                        nonce,
                        expiry
                    )
                )
            ),
            v,
            r,
            s
        );
        _useWrapperNonce(signer, nonce);
        _transfer(signer, _msgSender(), fee);
        _delegate(signer, delegatee);
        return true;
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = stakeOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    /// @notice Return a number of decimals of the token
    function decimals()
        public
        view
        override(ERC20Upgradeable, ERC20WrapperGluwacoin)
        returns (uint8)
    {
        return ERC20WrapperGluwacoin.decimals();
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(
                    _votingCheckpoints[src],
                    _subtract,
                    amount,
                    block.number
                );
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(
                    _votingCheckpoints[dst],
                    _add,
                    amount,
                    block.number
                );
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta,
        uint256 effectiveBlockNumber
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].balance;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && (ckpts[pos - 1].fromBlock == effectiveBlockNumber)) {
            ckpts[pos - 1].balance = SafeCastUpgradeable.toUint96(newWeight);
        } else {
            ckpts.push(
                Checkpoint({
                    fromBlock: SafeCastUpgradeable.toUint32(
                        effectiveBlockNumber
                    ),
                    balance: SafeCastUpgradeable.toUint96(newWeight)
                })
            );
        }
    }

    /**
     * @dev allow to query the delayed balance of an `account` which can be only received after the current block from unstaked process
     */
    function getDelayedBalance(address account)
        external
        view
        returns (uint256)
    {
        return _getDelayedBalance(account);
    }

    /**
     * @dev Get the balance for `account` which can be only received after the current block from unstaked process
     */
    function _getDelayedBalance(address account)
        private
        view
        returns (uint256)
    {
        BalanceQueue.QueueStorage
            storage balanceQueue = _tokenDelayedBalanceCheckpoints[account];
        uint32 queueIndex = balanceQueue.first;
        uint256 delayedBalance;
        while (true) {
            if (balanceQueue.data[queueIndex].blockNumber > block.number) {
                delayedBalance += balanceQueue.data[queueIndex].value;
                queueIndex++;
            } else {
                break;
            }
        }
        return delayedBalance;
    }

    function removeQueueData(address account, uint16 numberOfItem) public {
        BalanceQueue.QueueStorage
            storage balanceQueue = _tokenDelayedBalanceCheckpoints[account];
        for (uint8 i = 0; i < numberOfItem; i++) {
            if (
                !balanceQueue._isEmpty() &&
                balanceQueue._peek().blockNumber <= block.number
            ) {
                balanceQueue._dequeue();
            } else {
                break;
            }
        }
    }

    function _updateCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].balance;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].balance = SafeCastUpgradeable.toUint96(newWeight);
        } else {
            ckpts.push(
                Checkpoint({
                    fromBlock: SafeCastUpgradeable.toUint32(block.number),
                    balance: SafeCastUpgradeable.toUint96(newWeight)
                })
            );
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable, ERC20WrapperGluwacoin) {
        require(
            from == address(0) || balanceOf(from) >= amount,
            "ERC20StakedVotesUpgradeable: Insufficient balance"
        );
        ERC20WrapperGluwacoin._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(ERC20Upgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    uint256[50] private __gap;
}

contract GatewayGovernanceToken is ERC20StakedVotesUpgradeable {
    function initialize(
        string calldata name,
        string calldata symbol,
        uint8 decimals_,
        address admin,
        uint8 processingCap,
        uint32 wrappingRate,
        uint32 stakingLockup,
        uint32 unstakingLockup,
        IERC20Upgradeable token
    ) public virtual initializer {
        __ERC20StakedVotesUpgradeable_init_unchained(
            name,
            symbol,
            decimals_,
            admin,
            processingCap,
            wrappingRate,
            stakingLockup,
            unstakingLockup,
            token
        );
        __ERC20Permit_init_unchained(name);
        __GatewayGovernanceToken_init_unchained();
    }

    function __GatewayGovernanceToken_init_unchained()
        internal
        onlyInitializing
    {}

    function version() public pure returns (string memory) {
        return "0.1";
    }

    /**
     * @dev allow to get version for EIP712 domain dynamically. We do not need to init EIP712 anymore
     *   
     */
    function _EIP712VersionHash() internal pure override returns (bytes32) {
        return keccak256(bytes(version()));
    }

     /**
     * @dev The hash of the name parameter for the EIP712 domain based on token name. We do not need to init EIP712 anymore
     *   
     */
    function _EIP712NameHash() internal view override returns (bytes32) {
        return keccak256(bytes(name()));
    }

    function chainId() external view returns (uint256) {
        return block.chainid;
    }

    /**
     * @dev `burn` but with `burner`, `fee`, `nonce`, and `sig` as extra parameters.
     * `fee` is a burn fee amount in Gluwacoin, which the burner will pay for the burn.
     * `sig` is a signature created by signing the burn information with the burner’s private key.
     * Anyone can initiate the burn for the burner by calling the Etherless Burn function
     * with the burn information and the signature.
     * The caller will have to pay the gas for calling the function.
     *
     * Destroys `amount` + `fee` tokens from the burner.
     * Transfers `amount` of base tokens from the contract to the burner and `fee` of base token to the caller.
     *
     * See {ERC20-_burn}.
     *
     * Requirements:
     *
     * - the burner must have tokens of at least `amount`, the `fee` is included in the amount.
     */
    function burn(
        address burner,
        uint256 amount,
        uint256 fee,
        uint256 nonce,
        bytes calldata sig
    ) external override {
        uint256 burnerBalance = balanceOf(burner);
        require(
            burnerBalance >= amount,
            "ERC20Wrapper: burn amount exceed balance"
        );

        _useWrapperNonce(burner, nonce);

        bytes32 hash = keccak256(
            abi.encodePacked(
                GluwacoinModel.SigDomain.Burn,
                block.chainid,
                address(this),
                burner,
                amount,
                fee,
                nonce
            )
        );
        Validate.validateSignature(hash, burner, sig);

        _transfer(burner, _msgSender(), fee);
        __burn(burner, amount - fee);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20StakedVotesUpgradeable) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20StakedVotesUpgradeable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    uint256[50] private __gap;
}

contract SandboxGatewayGovernanceToken is GatewayGovernanceToken {
    function faucetMint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}