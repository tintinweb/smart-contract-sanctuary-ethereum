// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableMap.sol)

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32`) since v4.6.0
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

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
library EnumerableSet {
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ReentrancyGuardStatus} from "../structs/ReentrancyGuardStatus.sol";
import {StorageReentrancyGuard} from "../storage/StorageReentrancyGuard.sol";

/// @author Amit Molek
/// @dev Diamond compatible reentrancy guard
contract DiamondReentrancyGuard {
    modifier nonReentrant() {
        StorageReentrancyGuard.DiamondStorage
            storage ds = StorageReentrancyGuard.diamondStorage();

        // On first call, status MUST be NOT_ENTERED
        require(
            ds.status != ReentrancyGuardStatus.ENTERED,
            "LibReentrancyGuard: reentrant call"
        );

        // About to enter the function, set guard.
        ds.status = ReentrancyGuardStatus.ENTERED;
        _;

        // Existed function, reset guard
        ds.status = ReentrancyGuardStatus.NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LibGroup} from "../../libraries/LibGroup.sol";
import {IGroup} from "../../interfaces/IGroup.sol";
import {IWallet} from "../../interfaces/IWallet.sol";
import {DiamondReentrancyGuard} from "../../access/DiamondReentrancyGuard.sol";

/// @author Amit Molek
/// @dev Please see `IGroup` for docs
contract GroupFacet is IGroup, DiamondReentrancyGuard {
    function join(bytes memory data) external payable override {
        LibGroup._untrustedJoinDecode(data);
    }

    function acquireMore(bytes memory data) external payable override {
        LibGroup._untrustedAcquireMoreDecode(data);
    }

    function leave() external override nonReentrant {
        LibGroup._leave();
    }

    /// @dev Returns the value needed to send when a members wants to `join` the group, if the
    /// member wants to acquire `ownershipUnits` ownership units.
    /// You can use this function to know the value to pass to `join`/`acquireMore`.
    /// @return total The total value you need to pass on `join` (`ownershipUnits` + `anticFee` + `deploymentRefund`)
    /// @return anticFee The antic fee that will be collected
    /// @return deploymentRefund The deployment refund that will be passed to the group deployer
    function calculateValueToPass(uint256 ownershipUnits)
        public
        view
        returns (
            uint256 total,
            uint256 anticFee,
            uint256 deploymentRefund
        )
    {
        (anticFee, deploymentRefund) = LibGroup._calculateExpectedValue(
            ownershipUnits
        );
        total = anticFee + deploymentRefund + ownershipUnits;
    }

    /// @return true, if `proposition` is the forming proposition
    function isValidFormingProposition(IWallet.Proposition memory proposition)
        external
        view
        returns (bool)
    {
        return LibGroup._isValidFormingProposition(proposition);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Group managment interface
/// @author Amit Molek
interface IGroup {
    /// @dev Emitted when a member joins the group
    /// @param account the member that joined the group
    /// @param ownershipUnits number of ownership units bought
    event Joined(address account, uint256 ownershipUnits);

    /// @dev Emitted when a member acquires more ownership units
    /// @param account the member that acquired more
    /// @param ownershipUnits number of ownership units bought
    event AcquiredMore(address account, uint256 ownershipUnits);

    /// @dev Emitted when a member leaves the group
    /// @param account the member that leaved the group
    event Left(address account);

    /// @notice Join the group
    /// @dev The caller must pass contribution to the group
    /// which also represent the ownership units.
    /// The value passed to this function MUST include:
    /// the ownership units cost, Antic fee and deployment cost refund
    /// (ownership units + Antic fee + deployment refund)
    /// Emits `Joined` event
    function join(bytes memory data) external payable;

    /// @notice Acquire more ownership units
    /// @dev The caller must pass contribution to the group
    /// which also represent the ownership units.
    /// The value passed to this function MUST include:
    /// the ownership units cost, Antic fee and deployment cost refund
    /// (ownership units + Antic fee + deployment refund)
    /// Emits `AcquiredMore` event
    function acquireMore(bytes memory data) external payable;

    /// @notice Leave the group
    /// @dev The member will be refunded with his join contribution and Antic fee
    /// Emits `Leaved` event
    function leave() external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Multisig wallet interface
/// @author Amit Molek
interface IWallet {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
    }

    struct Proposition {
        /// @dev Proposition's deadline
        uint256 endsAt;
        /// @dev Proposed transaction to execute
        Transaction tx;
        /// @dev can be useful if your `transaction` needs an accompanying hash.
        /// For example in EIP1271 `isValidSignature` function.
        /// Note: Pass zero hash (0x0) if you don't need this.
        bytes32 relevantHash;
    }

    /// @dev Emitted on proposition execution
    /// @param hash the transaction's hash
    /// @param value the value passed with `transaction`
    /// @param successful is the transaction were successfully executed
    event ExecutedTransaction(
        bytes32 indexed hash,
        uint256 value,
        bool successful
    );

    /// @notice Execute proposition
    /// @param proposition the proposition to enact
    /// @param signatures a set of members EIP712 signatures on `proposition`
    /// @dev Emits `ExecutedTransaction` and `ApprovedHash` (only if `relevantHash` is passed) events
    /// @return successful true if the `proposition`'s transaction executed successfully
    /// @return returnData the data returned from the transaction
    function enactProposition(
        Proposition memory proposition,
        bytes[] memory signatures
    ) external returns (bool successful, bytes memory returnData);

    /// @return true, if the proposition has been enacted
    function isPropositionEnacted(bytes32 propositionHash)
        external
        view
        returns (bool);

    /// @return the maximum amount of value allowed to be transferred out of the contract
    function maxAllowedTransfer() external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LibTransfer} from "./LibTransfer.sol";
import {StorageAnticFee} from "../storage/StorageAnticFee.sol";

/// @author Amit Molek
/// @dev Please see `IAnticFee` for docs
library LibAnticFee {
    event TransferredToAntic(uint256 amount);

    function _antic() internal view returns (address) {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        return ds.antic;
    }

    /// @return The amount of fee collected so far from `join`
    function _totalJoinFeeDeposits() internal view returns (uint256) {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        return ds.totalJoinFeeDeposits;
    }

    function _calculateAnticJoinFee(uint256 value)
        internal
        view
        returns (uint256)
    {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        return
            (value * ds.joinFeePercentage) / StorageAnticFee.PERCENTAGE_DIVIDER;
    }

    function _calculateAnticSellFee(uint256 value)
        internal
        view
        returns (uint256)
    {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        return
            (value * ds.sellFeePercentage) / StorageAnticFee.PERCENTAGE_DIVIDER;
    }

    /// @dev Store `member`'s join fee
    function _depositJoinFeePayment(address member, uint256 value) internal {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        ds.memberFeeDeposits[member] += value;
        ds.totalJoinFeeDeposits += value;
    }

    /// @dev Removes `member` from fee collection
    /// @return amount The amount that needs to be refunded to `member`
    function _refundFeePayment(address member)
        internal
        returns (uint256 amount)
    {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        amount = ds.memberFeeDeposits[member];
        ds.totalJoinFeeDeposits -= amount;
        delete ds.memberFeeDeposits[member];
    }

    /// @dev Transfer `value` to Antic
    function _untrustedTransferToAntic(uint256 value) internal {
        emit TransferredToAntic(value);

        LibTransfer._untrustedSendValue(payable(_antic()), value);
    }

    /// @dev Transfer all the `join` fees collected to Antic
    function _untrustedTransferJoinAnticFee() internal {
        _untrustedTransferToAntic(_totalJoinFeeDeposits());
    }

    function _anticFeePercentages()
        internal
        view
        returns (uint16 joinFeePercentage, uint16 sellFeePercentage)
    {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        joinFeePercentage = ds.joinFeePercentage;
        sellFeePercentage = ds.sellFeePercentage;
    }

    function _memberFeeDeposits(address member)
        internal
        view
        returns (uint256)
    {
        StorageAnticFee.DiamondStorage storage ds = StorageAnticFee
            .diamondStorage();

        return ds.memberFeeDeposits[member];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StorageDeploymentCost} from "../storage/StorageDeploymentCost.sol";
import {LibOwnership} from "./LibOwnership.sol";
import {LibTransfer} from "./LibTransfer.sol";

/// @author Amit Molek
/// @dev Please see `IDeploymentRefund` for docs
library LibDeploymentRefund {
    event WithdrawnDeploymentRefund(address account, uint256 amount);
    event InitializedDeploymentCost(
        uint256 gasUsed,
        uint256 gasPrice,
        address deployer
    );
    event DeployerJoined(uint256 ownershipUnits);

    /// @dev The total refund amount can't exceed the deployment cost, so
    /// if the deployment cost refund based on `ownershipUnits` exceeds the
    /// deployment cost, the refund will be equal to only the delta left (deploymentCost - paidSoFar)
    /// @return The deployment cost refund amount that needs to be paid,
    /// if the member acquires `ownershipUnits` ownership units
    function _calculateDeploymentCostRefund(uint256 ownershipUnits)
        internal
        view
        returns (uint256)
    {
        uint256 totalOwnershipUnits = LibOwnership._totalOwnershipUnits();

        require(
            ownershipUnits <= totalOwnershipUnits,
            "DeploymentRefund: Invalid units"
        );

        uint256 deploymentCost = _deploymentCostToRefund();
        uint256 refundPayment = (deploymentCost * ownershipUnits) /
            totalOwnershipUnits;
        uint256 paidSoFar = _deploymentCostPaid();

        // Can't refund more than the deployment cost
        return
            refundPayment + paidSoFar > deploymentCost
                ? deploymentCost - paidSoFar
                : refundPayment;
    }

    function _payDeploymentCost(uint256 refundAmount) internal {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        ds.paid += refundAmount;
    }

    function _initDeploymentCost(uint256 deploymentGasUsed, address deployer)
        internal
    {
        require(
            deploymentGasUsed > 0,
            "DeploymentRefund: Deployment gas can't be 0"
        );
        require(
            deployer != address(0),
            "DeploymentRefund: Invalid deployer address"
        );

        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        require(
            ds.deploymentCostToRefund == 0,
            "DeploymentRefund: Deployment cost already initialized"
        );

        uint256 gasPrice = tx.gasprice;
        ds.deploymentCostToRefund = deploymentGasUsed * gasPrice;
        ds.deployer = deployer;

        emit InitializedDeploymentCost(deploymentGasUsed, gasPrice, deployer);
    }

    function _deployerJoin(address member, uint256 deployerOwnershipUnits)
        internal
    {
        require(
            !_isDeployerJoined(),
            "DeploymentRefund: Deployer already joined"
        );

        require(
            _isDeploymentCostSet(),
            "DeploymentRefund: Must initialized deployment cost first"
        );

        require(member == _deployer(), "DeploymentRefund: Not the deployer");

        require(
            deployerOwnershipUnits > 0,
            "DeploymentRefund: Invalid ownership units"
        );

        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        uint256 deployerDeploymentCost = _calculateDeploymentCostRefund(
            deployerOwnershipUnits
        );

        // The deployer already paid
        ds.paid += deployerDeploymentCost;
        // The deployer can't withdraw his payment
        ds.withdrawn += deployerDeploymentCost;
        ds.isDeployerJoined = true;

        emit DeployerJoined(deployerOwnershipUnits);
    }

    function _isDeploymentCostSet() internal view returns (bool) {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        return ds.deploymentCostToRefund > 0;
    }

    function _deploymentCostToRefund() internal view returns (uint256) {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        return ds.deploymentCostToRefund;
    }

    function _deploymentCostPaid() internal view returns (uint256) {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        return ds.paid;
    }

    function _withdrawn() internal view returns (uint256) {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        return ds.withdrawn;
    }

    function _deployer() internal view returns (address) {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        return ds.deployer;
    }

    function _refundable() internal view returns (uint256) {
        return _deploymentCostPaid() - _withdrawn();
    }

    function _isDeployerJoined() internal view returns (bool) {
        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();

        return ds.isDeployerJoined;
    }

    function _withdrawDeploymentRefund() internal {
        address deployer = _deployer();

        // Only the deployer can withdraw the deployment cost refund
        require(
            msg.sender == deployer,
            "DeploymentRefund: caller not the deployer"
        );

        uint256 refundAmount = _refundable();
        require(refundAmount > 0, "DeploymentRefund: nothing to withdraw");

        StorageDeploymentCost.DiamondStorage storage ds = StorageDeploymentCost
            .diamondStorage();
        ds.withdrawn += refundAmount;

        emit WithdrawnDeploymentRefund(deployer, refundAmount);

        LibTransfer._untrustedSendValue(payable(deployer), refundAmount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StorageAnticDomain} from "../storage/StorageAnticDomain.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @author Amit Molek
/// @dev Please see `IEIP712` for docs
/// Also please make sure you are familiar with EIP712 before editing anything
library LibEIP712 {
    bytes32 internal constant _DOMAIN_NAME = keccak256("Antic");
    bytes32 internal constant _DOMAIN_VERSION = keccak256("1");
    bytes32 internal constant _SALT = keccak256("Magrathea");

    bytes32 internal constant _EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
        );

    /// @dev Initializes the EIP712's domain separator
    /// note Must be called at least once, because it saves the
    /// domain separator in storage
    function _initDomainSeparator() internal {
        StorageAnticDomain.DiamondStorage storage ds = StorageAnticDomain
            .diamondStorage();

        ds.domainSeparator = keccak256(
            abi.encode(
                _EIP712_DOMAIN_TYPEHASH,
                _DOMAIN_NAME,
                _DOMAIN_VERSION,
                _chainId(),
                _verifyingContract(),
                _salt()
            )
        );
    }

    function _toTypedDataHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return ECDSA.toTypedDataHash(_domainSeparator(), messageHash);
    }

    function _domainSeparator() internal view returns (bytes32) {
        StorageAnticDomain.DiamondStorage storage ds = StorageAnticDomain
            .diamondStorage();

        return ds.domainSeparator;
    }

    function _chainId() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function _verifyingContract() internal view returns (address) {
        return address(this);
    }

    function _salt() internal pure returns (bytes32) {
        return _SALT;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWallet} from "../interfaces/IWallet.sol";
import {LibEIP712} from "./LibEIP712.sol";
import {LibSignature} from "./LibSignature.sol";
import {LibEIP712Transaction} from "./LibEIP712Transaction.sol";

/// @author Amit Molek
/// @dev Please see `IEIP712Proposition` for docs
/// Also please make sure you are familiar with EIP712 before editing anything
library LibEIP712Proposition {
    bytes32 internal constant _PROPOSITION_TYPEHASH =
        keccak256(
            "Proposition(uint256 endsAt,Transaction tx,bytes32 relevantHash)Transaction(address to,uint256 value,bytes data)"
        );

    function _verifyPropositionSigner(
        address signer,
        IWallet.Proposition memory proposition,
        bytes memory signature
    ) internal view returns (bool) {
        return
            LibSignature._verifySigner(
                signer,
                LibEIP712._toTypedDataHash(_hashProposition(proposition)),
                signature
            );
    }

    function _recoverPropositionSigner(
        IWallet.Proposition memory proposition,
        bytes memory signature
    ) internal view returns (address) {
        return
            LibSignature._recoverSigner(
                LibEIP712._toTypedDataHash(_hashProposition(proposition)),
                signature
            );
    }

    function _hashProposition(IWallet.Proposition memory proposition)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _PROPOSITION_TYPEHASH,
                    proposition.endsAt,
                    LibEIP712Transaction._hashTransaction(proposition.tx),
                    proposition.relevantHash
                )
            );
    }

    function _toTypedDataHash(IWallet.Proposition memory proposition)
        internal
        view
        returns (bytes32)
    {
        return LibEIP712._toTypedDataHash(_hashProposition(proposition));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWallet} from "../interfaces/IWallet.sol";
import {LibEIP712} from "./LibEIP712.sol";
import {LibSignature} from "./LibSignature.sol";

/// @author Amit Molek
/// @dev Please see `IEIP712Transaction` for docs
/// Also please make sure you are familiar with EIP712 before editing anything
library LibEIP712Transaction {
    bytes32 internal constant _TRANSACTION_TYPEHASH =
        keccak256("Transaction(address to,uint256 value,bytes data)");

    function _verifyTransactionSigner(
        address signer,
        IWallet.Transaction memory transaction,
        bytes memory signature
    ) internal view returns (bool) {
        return
            LibSignature._verifySigner(
                signer,
                LibEIP712._toTypedDataHash(_hashTransaction(transaction)),
                signature
            );
    }

    function _recoverTransactionSigner(
        IWallet.Transaction memory transaction,
        bytes memory signature
    ) internal view returns (address) {
        return
            LibSignature._recoverSigner(
                LibEIP712._toTypedDataHash(_hashTransaction(transaction)),
                signature
            );
    }

    function _hashTransaction(IWallet.Transaction memory transaction)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _TRANSACTION_TYPEHASH,
                    transaction.to,
                    transaction.value,
                    keccak256(transaction.data)
                )
            );
    }

    function _toTypedDataHash(IWallet.Transaction memory transaction)
        internal
        view
        returns (bytes32)
    {
        return LibEIP712._toTypedDataHash(_hashTransaction(transaction));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StateEnum} from "../structs/StateEnum.sol";
import {LibState} from "../libraries/LibState.sol";
import {LibOwnership} from "../libraries/LibOwnership.sol";
import {LibTransfer} from "../libraries/LibTransfer.sol";
import {LibWallet} from "../libraries/LibWallet.sol";
import {IWallet} from "../interfaces/IWallet.sol";
import {JoinData} from "../structs/JoinData.sol";
import {LibAnticFee} from "../libraries/LibAnticFee.sol";
import {LibDeploymentRefund} from "../libraries/LibDeploymentRefund.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {StorageFormingProposition} from "../storage/StorageFormingProposition.sol";
import {LibEIP712Proposition} from "./LibEIP712Proposition.sol";

/// @author Amit Molek
/// @dev Please see `IGroup` for docs
library LibGroup {
    event Joined(address account, uint256 ownershipUnits);
    event AcquiredMore(address account, uint256 ownershipUnits);
    event Left(address account);

    function _calculateExpectedValue(uint256 ownershipUnits)
        internal
        view
        returns (uint256 anticFee, uint256 deploymentRefund)
    {
        require(
            LibDeploymentRefund._isDeploymentCostSet(),
            "Group: Deployment cost must be initialized"
        );

        anticFee = LibAnticFee._calculateAnticJoinFee(ownershipUnits);

        // If the deployer has not joined yet, he/she MUST be the next one to join,
        // and he/she doesn't need to pay the deployment cost refund.
        // Otherwise the next one to join, MUST pay the deployment refund
        deploymentRefund = !LibDeploymentRefund._isDeployerJoined()
            ? deploymentRefund = 0
            : LibDeploymentRefund._calculateDeploymentCostRefund(
                ownershipUnits
            );
    }

    function _internalJoin(
        address member,
        uint256 ownershipUnits,
        uint256 anticFee,
        uint256 deploymentRefund,
        bool newOwner
    ) internal {
        uint256 expectedTotal = anticFee + deploymentRefund + ownershipUnits;
        uint256 value = msg.value;

        // Verify that the caller passed enough value
        require(
            value == expectedTotal,
            string(
                abi.encodePacked(
                    "Group: Expected ",
                    Strings.toString(expectedTotal),
                    " but received ",
                    Strings.toString(value)
                )
            )
        );

        // Transfer fee to antic
        LibAnticFee._depositJoinFeePayment(member, anticFee);

        // Pay deployment cost
        LibDeploymentRefund._payDeploymentCost(deploymentRefund);

        if (newOwner) {
            // Add the member as a owner
            LibOwnership._addOwner(member, ownershipUnits);
        } else {
            // Update member's ownership
            LibOwnership._acquireMoreOwnershipUnits(member, ownershipUnits);
        }
    }

    /// @dev Decodes `data` and passes it to `_join`
    /// `data` must be encoded `JoinData` struct
    function _untrustedJoinDecode(bytes memory data) internal {
        JoinData memory joinData = abi.decode(data, (JoinData));

        _untrustedJoin(
            joinData.member,
            joinData.proposition,
            joinData.signatures,
            joinData.ownershipUnits
        );
    }

    /// @notice Internal join
    /// @dev Adds `member` to the group
    /// If the `member` fulfills the targeted ownership units -> enacts `proposition`
    /// Emits `Joined` event
    function _untrustedJoin(
        address member,
        IWallet.Proposition memory proposition,
        bytes[] memory signatures,
        uint256 ownershipUnits
    ) internal {
        // Members can join only when the group is forming (open)
        LibState._stateGuard(StateEnum.OPEN);

        (uint256 anticFee, uint256 deploymentRefund) = _calculateExpectedValue(
            ownershipUnits
        );

        if (!LibDeploymentRefund._isDeployerJoined()) {
            LibDeploymentRefund._deployerJoin(member, ownershipUnits);
        }

        _internalJoin(member, ownershipUnits, anticFee, deploymentRefund, true);

        emit Joined(member, ownershipUnits);

        _untrustedTryEnactFormingProposition(proposition, signatures);
    }

    /// @dev Decodes `data` and passes it to `_acquireMore`
    /// `data` must be encoded `JoinData` struct
    function _untrustedAcquireMoreDecode(bytes memory data) internal {
        JoinData memory joinData = abi.decode(data, (JoinData));

        _untrustedAcquireMore(
            joinData.member,
            joinData.proposition,
            joinData.signatures,
            joinData.ownershipUnits
        );
    }

    /// @notice Internal acquire more
    /// @dev `member` obtains more ownership units
    /// `member` must be an actual group member
    /// if the `member` fulfills the targeted ownership units -> enacts `proposition`
    /// Emits `AcquiredMore` event
    function _untrustedAcquireMore(
        address member,
        IWallet.Proposition memory proposition,
        bytes[] memory signatures,
        uint256 ownershipUnits
    ) internal {
        // Members can acquire more ownership units only when the group is forming (open)
        LibState._stateGuard(StateEnum.OPEN);

        (uint256 anticFee, uint256 deploymentRefund) = _calculateExpectedValue(
            ownershipUnits
        );

        _internalJoin(
            member,
            ownershipUnits,
            anticFee,
            deploymentRefund,
            false
        );

        emit AcquiredMore(member, ownershipUnits);

        _untrustedTryEnactFormingProposition(proposition, signatures);
    }

    /// @notice Enacts the group forming proposition
    /// @dev Enacts the given `proposition` if the group completely owns all the ownership units
    function _untrustedTryEnactFormingProposition(
        IWallet.Proposition memory proposition,
        bytes[] memory signatures
    ) internal {
        // Enacting the forming proposition is only available while the group is open
        // because this is the last step to form the group
        LibState._stateGuard(StateEnum.OPEN);

        // Last member to acquire the remaining ownership units, enacts the proposition
        // and forms the group
        if (LibOwnership._isCompletelyOwned()) {
            // Verify that we are going to enact the expected forming proposition
            require(
                _isValidFormingProposition(proposition),
                "Group: Unexpected proposition"
            );

            // The group is now formed
            LibState._changeState(StateEnum.FORMED);

            // Transfer Antic fee
            LibAnticFee._untrustedTransferJoinAnticFee();

            (bool successful, bytes memory returnData) = LibWallet
                ._untrustedEnactProposition(proposition, signatures);

            if (!successful) {
                LibTransfer._revertWithReason(returnData);
            }
        }
    }

    /// @notice Internal member leaves
    /// @dev `member` will be refunded with his join deposit and Antic fee
    /// Emits `Left` event
    function _leave() internal {
        // Members can leave only while the group is forming (open)
        LibState._stateGuard(StateEnum.OPEN);

        address member = msg.sender;

        // Caller renounce his ownership
        uint256 ownershipRefundAmount = LibOwnership._renounceOwnership();
        uint256 anticFeeRefundAmount = LibAnticFee._refundFeePayment(member);
        uint256 refundAmount = ownershipRefundAmount + anticFeeRefundAmount;

        emit Left(member);

        // Refund the caller with his join deposit
        LibTransfer._untrustedSendValue(payable(member), refundAmount);
    }

    function _isValidFormingProposition(IWallet.Proposition memory proposition)
        internal
        view
        returns (bool)
    {
        StorageFormingProposition.DiamondStorage
            storage ds = StorageFormingProposition.diamondStorage();

        bytes32 propositionHash = LibEIP712Proposition._toTypedDataHash(
            proposition
        );
        return propositionHash == ds.formingPropositionHash;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StorageOwnershipUnits} from "../storage/StorageOwnershipUnits.sol";
import {LibState} from "../libraries/LibState.sol";
import {StateEnum} from "../structs/StateEnum.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

/// @author Amit Molek
/// @dev Please see `IOwnership` for docs
library LibOwnership {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    /// @notice Adds `account` as an onwer
    /// @dev For internal use only
    /// You must call this function with join's deposit value attached
    function _addOwner(address account, uint256 ownershipUnits) internal {
        // Verify that the group is still open
        LibState._stateGuard(StateEnum.OPEN);

        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        // Update the member's ownership units
        require(
            ds.ownershipUnits.set(account, ownershipUnits),
            "Ownership: existing member"
        );

        // Verify ownership deposit is valid
        _depositGuard(ownershipUnits);

        // Update the total ownership units owned
        ds.totalOwnedOwnershipUnits += ownershipUnits;
    }

    /// @notice `account` acquires more ownership units
    /// @dev You must call this with value attached
    function _acquireMoreOwnershipUnits(address account, uint256 ownershipUnits)
        internal
    {
        // Verify that the group is still open
        LibState._stateGuard(StateEnum.OPEN);

        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        // Only existing member can obtain more units
        require(ds.ownershipUnits.contains(account), "Ownership: not a member");

        // Verify ownership deposit is valid
        _depositGuard(ownershipUnits);

        uint256 currentOwnerUnits = ds.ownershipUnits.get(account);
        ds.ownershipUnits.set(account, currentOwnerUnits + ownershipUnits);
        ds.totalOwnedOwnershipUnits += ownershipUnits;
    }

    /// @dev Guard that verifies that the ownership deposit is valid
    /// Can revert:
    ///     - "Ownership: deposit not divisible by smallest unit"
    ///     - "Ownership: deposit exceeds total ownership units"
    ///     - "Ownership: deposit must be bigger than 0"
    function _depositGuard(uint256 ownershipUnits) internal {
        uint256 value = msg.value;
        uint256 smallestUnit = _smallestUnit();

        require(
            value >= ownershipUnits,
            "Ownership: mismatch between units and deposit amount"
        );

        require(ownershipUnits > 0, "Ownership: deposit must be bigger than 0");

        require(
            ownershipUnits % smallestUnit == 0,
            "Ownership: deposit not divisible by smallest unit"
        );

        require(
            ownershipUnits + _totalOwnedOwnershipUnits() <=
                _totalOwnershipUnits(),
            "Ownership: deposit exceeds total ownership units"
        );
    }

    /// @notice Renounce ownership
    /// @dev The caller renounce his ownership
    /// @return refund the amount to refund to the caller
    function _renounceOwnership() internal returns (uint256 refund) {
        // Verify that the group is still open
        require(
            LibState._state() == StateEnum.OPEN,
            "Ownership: group formed or uninitialized"
        );

        // Verify that the caller is a member
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        require(
            ds.ownershipUnits.contains(msg.sender),
            "Ownership: not an owner"
        );

        // Update the member ownership units and the total units owned
        refund = ds.ownershipUnits.get(msg.sender);
        ds.totalOwnedOwnershipUnits -= refund;
        ds.ownershipUnits.remove(msg.sender);
    }

    function _ownershipUnits(address member) internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.ownershipUnits.get(member);
    }

    function _totalOwnershipUnits() internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.totalOwnershipUnits;
    }

    function _smallestUnit() internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.smallestOwnershipUnit;
    }

    function _totalOwnedOwnershipUnits() internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.totalOwnedOwnershipUnits;
    }

    function _isCompletelyOwned() internal view returns (bool) {
        return _totalOwnedOwnershipUnits() == _totalOwnershipUnits();
    }

    function _isMember(address account) internal view returns (bool) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.ownershipUnits.contains(account);
    }

    function _memberAt(uint256 index)
        internal
        view
        returns (address member, uint256 units)
    {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        (member, units) = ds.ownershipUnits.at(index);
    }

    function _memberCount() internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.ownershipUnits.length();
    }

    function _members() internal view returns (address[] memory members) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        uint256 length = ds.ownershipUnits.length();
        members = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            (members[i], ) = ds.ownershipUnits.at(i);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/// @author Amit Molek
/// @dev Percentages helper
library LibPercentage {
    uint256 public constant PERCENTAGE_DIVIDER = 100; // 1 percent precision

    /// @dev Returns the ceil value of `percentage` out of `value`.
    function _calculateCeil(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        return Math.ceilDiv(value * percentage, PERCENTAGE_DIVIDER);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LibSignature} from "./LibSignature.sol";
import {LibPercentage} from "./LibPercentage.sol";
import {LibOwnership} from "./LibOwnership.sol";
import {StorageQuorumGovernance} from "../storage/StorageQuorumGovernance.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @author Amit Molek
/// @dev Please see `QuorumGovernanceFacet` for docs
library LibQuorumGovernance {
    /// @param hash the hash to verify
    /// @param signatures array of the members signatures on `hash`
    /// @return true, if enough members signed the `hash` with enough voting powers
    function _verifyHash(bytes32 hash, bytes[] memory signatures)
        internal
        view
        returns (bool)
    {
        address[] memory signedMembers = _extractMembers(hash, signatures);

        return _verifyQuorum(signedMembers) && _verifyPassRate(signedMembers);
    }

    /// @param hash the hash to verify
    /// @param signatures array of the members signatures on `hash`
    /// @return members a list of the members that signed `hash`
    function _extractMembers(bytes32 hash, bytes[] memory signatures)
        internal
        view
        returns (address[] memory members)
    {
        members = new address[](signatures.length);

        address lastSigner = address(0);
        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = LibSignature._recoverSigner(hash, signatures[i]);
            // Check for duplication (same signer)
            require(signer > lastSigner, "Governance: Invalid signatures");
            lastSigner = signer;

            require(
                LibOwnership._isMember(signer),
                string(
                    abi.encodePacked(
                        "Governance: Signer ",
                        Strings.toHexString(uint256(uint160(signer)), 20),
                        " is not a member"
                    )
                )
            );

            members[i] = signer;
        }
    }

    /// @dev Explain to a developer any extra details
    /// @param members the members to check the quorum of
    /// @return true, if enough members signed the hash
    function _verifyQuorum(address[] memory members)
        internal
        view
        returns (bool)
    {
        return members.length >= _quorumThreshold();
    }

    /// @dev The calculation always rounds up (ceil) the threshold
    /// e.g. if the group size is 3 and the quorum percentage is 50% the threshold is 2
    /// ceil((3 * 50) / 100) = ceil(1.5) -> 2
    /// @return the quorum threshold amount of members that must sign for the hash to be verified
    function _quorumThreshold() internal view returns (uint256) {
        uint256 groupSize = LibOwnership._members().length;
        uint256 quorumPercentage = StorageQuorumGovernance
            .diamondStorage()
            .quorumPercentage;

        return LibPercentage._calculateCeil(groupSize, quorumPercentage);
    }

    /// @dev Verifies that the pass rate of `members` passes the minimum pass rate
    /// @param members the members to check the pass rate of
    /// @return true, if the `members` pass rate has passed the minimum pass rate
    function _verifyPassRate(address[] memory members)
        internal
        view
        returns (bool)
    {
        uint256 passRate = _calculatePassRate(members);
        uint256 passRatePercentage = StorageQuorumGovernance
            .diamondStorage()
            .passRatePercentage;

        return passRate >= passRatePercentage;
    }

    /// @notice Calculate the weighted pass rate
    /// @dev The weight is based upon the ownership units of each member
    /// e.g. if Alice and Bob are the group members,
    /// they have 60 and 40 units respectively. So the group total is 100 units.
    /// so their weights are 60% (60/100*100) for Alice and 40% (40/100*100) for Bob.
    /// @param members the members to check the pass rate of
    /// @return the pass rate percentage of `members` (e.g. 46%)
    function _calculatePassRate(address[] memory members)
        internal
        view
        returns (uint256)
    {
        uint256 totalSignersUnits;
        for (uint256 i = 0; i < members.length; i++) {
            totalSignersUnits += LibOwnership._ownershipUnits(members[i]);
        }

        uint256 totalUnits = LibOwnership._totalOwnershipUnits();
        require(totalUnits > 0, "Governance: units can't be 0");

        return
            (totalSignersUnits * LibPercentage.PERCENTAGE_DIVIDER) / totalUnits;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LibAnticFee} from "./LibAnticFee.sol";
import {LibOwnership} from "./LibOwnership.sol";
import {StorageReceive} from "../storage/StorageReceive.sol";
import {LibTransfer} from "./LibTransfer.sol";
import {LibDeploymentRefund} from "./LibDeploymentRefund.sol";

/// @author Amit Molek
/// @dev Please see `IReceive` for docs
library LibReceive {
    event ValueWithdrawn(address member, uint256 value);
    event ValueReceived(address from, uint256 value);

    function _receive() internal {
        uint256 value = msg.value;

        emit ValueReceived(msg.sender, value);

        uint256 anticFee = LibAnticFee._calculateAnticSellFee(value);
        uint256 remainingValue = value - anticFee;

        _splitValueToMembers(remainingValue);
        LibAnticFee._untrustedTransferToAntic(anticFee);
    }

    /// @dev Splits `value` to the group members, based on their ownership units
    function _splitValueToMembers(uint256 value) internal {
        uint256 memberCount = LibOwnership._memberCount();
        uint256 totalOwnershipUnits = LibOwnership._totalOwnershipUnits();

        StorageReceive.DiamondStorage storage ds = StorageReceive
            .diamondStorage();

        // Iterate over all the group members and split the incoming funds to them.
        // *Based on their ownership units
        uint256 total = 0;
        for (uint256 i = 0; i < memberCount; i++) {
            (address member, uint256 units) = LibOwnership._memberAt(i);

            uint256 withdrawablePortion = (value * units) / totalOwnershipUnits;
            ds.withdrawable[member] += withdrawablePortion;
            total += withdrawablePortion;
        }

        // The loss of precision in the split calculation
        // can lead to trace funds unavailable to claim. So we tip
        // the deployer with the remainder
        if (value > total) {
            uint256 deployerTip = value - total;
            address deployer = LibDeploymentRefund._deployer();

            ds.withdrawable[deployer] += deployerTip;
        }

        // Update the total withdrawable amount by members.
        ds.totalWithdrawable += value;
    }

    /// @dev Transfer collected funds to the calling member
    /// Emits `ValueWithdrawn`
    function _withdraw() internal {
        address account = msg.sender;

        require(LibOwnership._isMember(account), "Receive: not a member");

        StorageReceive.DiamondStorage storage ds = StorageReceive
            .diamondStorage();

        uint256 withdrawable = ds.withdrawable[account];
        require(withdrawable > 0, "Receive: nothing to withdraw");

        ds.withdrawable[account] = 0;
        ds.totalWithdrawable -= withdrawable;

        emit ValueWithdrawn(account, withdrawable);

        LibTransfer._untrustedSendValue(payable(account), withdrawable);
    }

    function _withdrawable(address member) internal view returns (uint256) {
        StorageReceive.DiamondStorage storage ds = StorageReceive
            .diamondStorage();

        return ds.withdrawable[member];
    }

    function _totalWithdrawable() internal view returns (uint256) {
        StorageReceive.DiamondStorage storage ds = StorageReceive
            .diamondStorage();

        return ds.totalWithdrawable;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @author Amit Molek
/// @dev Please see `ISignature` for docs
library LibSignature {
    function _verifySigner(
        address signer,
        bytes32 hashToVerify,
        bytes memory signature
    ) internal pure returns (bool) {
        return (signer == _recoverSigner(hashToVerify, signature));
    }

    function _recoverSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return ECDSA.recover(hash, signature);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StorageState} from "../storage/StorageState.sol";
import {StateEnum} from "../structs/StateEnum.sol";

/// @author Amit Molek
/// @dev Contract/Group state
library LibState {
    string public constant INVALID_STATE_ERR = "State: Invalid state";

    event StateChanged(StateEnum from, StateEnum to);

    /// @dev Changes the state of the contract/group
    /// Can revert:
    ///     - "State: same state": When changing the state to the same one
    /// Emits `StateChanged` event
    /// @param state the new state
    function _changeState(StateEnum state) internal {
        StorageState.DiamondStorage storage ds = StorageState.diamondStorage();
        require(ds.state != state, "State: same state");

        emit StateChanged(ds.state, state);

        ds.state = state;
    }

    function _state() internal view returns (StateEnum) {
        StorageState.DiamondStorage storage ds = StorageState.diamondStorage();

        return ds.state;
    }

    /// @dev reverts if `state` is not the current contract state
    function _stateGuard(StateEnum state) internal view {
        require(_state() == state, INVALID_STATE_ERR);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Address.sol";

/// @author Amit Molek
/// @dev Transfer helpers
library LibTransfer {
    /// @dev Sends `value` in wei to `recipient`
    /// Reverts on failure
    function _untrustedSendValue(address payable recipient, uint256 value)
        internal
    {
        Address.sendValue(recipient, value);
    }

    /// @dev Performs a function call
    function _untrustedCall(
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bool successful, bytes memory returnData) {
        require(
            address(this).balance >= value,
            "Transfer: insufficient balance"
        );

        (successful, returnData) = to.call{value: value}(data);
    }

    /// @dev Extracts and bubbles the revert reason if exist, otherwise reverts with a hard-coded reason.
    function _revertWithReason(bytes memory returnData) internal pure {
        if (returnData.length == 0) {
            revert("Transfer: call reverted without a reason");
        }

        // Bubble the revert reason
        assembly {
            let returnDataSize := mload(returnData)
            revert(add(32, returnData), returnDataSize)
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWallet} from "../interfaces/IWallet.sol";
import {LibQuorumGovernance} from "../libraries/LibQuorumGovernance.sol";
import {LibEIP712Transaction} from "../libraries/LibEIP712Transaction.sol";
import {LibEIP712} from "../libraries/LibEIP712.sol";
import {StorageEnactedPropositions} from "../storage/StorageEnactedPropositions.sol";
import {LibEIP712Proposition} from "../libraries/LibEIP712Proposition.sol";
import {LibState} from "../libraries/LibState.sol";
import {StateEnum} from "../structs/StateEnum.sol";
import {LibTransfer} from "../libraries/LibTransfer.sol";
import {LibWalletHash} from "./LibWalletHash.sol";
import {LibDeploymentRefund} from "./LibDeploymentRefund.sol";
import {LibReceive} from "./LibReceive.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @author Amit Molek
/// @dev Please see `IWallet` for docs
library LibWallet {
    event ExecutedTransaction(
        bytes32 indexed hash,
        uint256 value,
        bool successful
    );

    function _maxAllowedTransfer() internal view returns (uint256) {
        return
            address(this).balance -
            LibDeploymentRefund._refundable() -
            LibReceive._totalWithdrawable();
    }

    /// @dev Reverts if the transaction's value exceeds the maximum allowed value
    /// max allowed = (balance - deployer's refund - total withdrawable value by members)
    /// revert message example: "Wallet: 42 exceeds maximum value of 6"
    function _maxAllowedTransferGuard(uint256 value) internal view {
        uint256 maxValueAllowed = _maxAllowedTransfer();
        require(
            value <= maxValueAllowed,
            string(
                abi.encodePacked(
                    "Wallet: ",
                    Strings.toString(value),
                    " exceeds maximum value of ",
                    Strings.toString(maxValueAllowed)
                )
            )
        );
    }

    /// @dev Emits `ExecutedTransaction` event
    /// @param transaction the transaction to execute
    function _untrustedExecuteTransaction(
        IWallet.Transaction memory transaction
    ) internal returns (bool successful, bytes memory returnData) {
        // Verify that the transaction's value doesn't exceeds
        // the maximum allowed value.
        // The deployer's refund and each member's withdrawable value
        _maxAllowedTransferGuard(transaction.value);

        (successful, returnData) = LibTransfer._untrustedCall(
            transaction.to,
            transaction.value,
            transaction.data
        );

        emit ExecutedTransaction(
            LibEIP712Transaction._hashTransaction(transaction),
            transaction.value,
            successful
        );
    }

    /// @dev Can revert:
    ///     - "Wallet: Enacted proposition given": If the proposition was already enacted
    ///     - "Wallet: Proposition ended": If the proposition's time-to-live ended
    ///     - "Wallet: Unapproved proposition": If group members did not reach on agreement on `proposition`
    ///     - "Wallet: Group not formed": If the group state is not valid
    /// Emits `ApprovedHash` and `ExecutedTransaction` events
    function _untrustedEnactProposition(
        IWallet.Proposition memory proposition,
        bytes[] memory signatures
    ) internal returns (bool successful, bytes memory returnData) {
        LibState._stateGuard(StateEnum.FORMED);

        bytes32 propositionHash = LibEIP712Proposition._toTypedDataHash(
            proposition
        );

        StorageEnactedPropositions.DiamondStorage
            storage enactedPropositionsStorage = StorageEnactedPropositions
                .diamondStorage();

        // A proposition can only be executed once
        require(
            !enactedPropositionsStorage.enactedPropositions[propositionHash],
            "Wallet: Enacted proposition given"
        );

        require(
            // solhint-disable-next-line not-rely-on-time
            proposition.endsAt >= block.timestamp,
            "Wallet: Proposition ended"
        );

        // Verify that the proposition is agreed upon
        bool isPropositionVerified = LibQuorumGovernance._verifyHash(
            propositionHash,
            signatures
        );
        require(isPropositionVerified, "Wallet: Unapproved proposition");

        // Tag the proposition as enacted
        enactedPropositionsStorage.enactedPropositions[propositionHash] = true;

        if (proposition.relevantHash != bytes32(0)) {
            // Store the approved hash for later (probably for EIP1271)
            LibWalletHash._internalApproveHash(proposition.relevantHash);
        }

        return _untrustedExecuteTransaction(proposition.tx);
    }

    function _isPropositionEnacted(bytes32 propositionHash)
        internal
        view
        returns (bool)
    {
        StorageEnactedPropositions.DiamondStorage
            storage ds = StorageEnactedPropositions.diamondStorage();

        return ds.enactedPropositions[propositionHash];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LibQuorumGovernance} from "../libraries/LibQuorumGovernance.sol";
import {StorageApprovedHashes} from "../storage/StorageApprovedHashes.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library LibWalletHash {
    event ApprovedHash(bytes32 hash);
    event RevokedHash(bytes32 hash);

    /// @dev The hash time-to-live
    uint256 internal constant HASH_TTL = 4 weeks;

    /// @dev Adds `hash` to the approved hashes list
    /// Emits `ApprovedHash`
    function _internalApproveHash(bytes32 hash) internal {
        StorageApprovedHashes.DiamondStorage storage ds = StorageApprovedHashes
            .diamondStorage();

        // solhint-disable-next-line not-rely-on-time
        ds.deadlines[hash] = block.timestamp + HASH_TTL;
        emit ApprovedHash(hash);
    }

    /// @dev Removes `hash` from the approved hashes list
    /// Emits `RevokedHash`
    function _internalRevokeHash(bytes32 hash) internal {
        StorageApprovedHashes.DiamondStorage storage ds = StorageApprovedHashes
            .diamondStorage();

        delete ds.deadlines[hash];
        emit RevokedHash(hash);
    }

    function _hashDeadline(bytes32 hash) internal view returns (uint256) {
        StorageApprovedHashes.DiamondStorage storage ds = StorageApprovedHashes
            .diamondStorage();

        return ds.deadlines[hash];
    }

    function _isHashApproved(bytes32 hash) internal view returns (bool) {
        StorageApprovedHashes.DiamondStorage storage ds = StorageApprovedHashes
            .diamondStorage();

        uint256 deadline = ds.deadlines[hash];

        // solhint-disable-next-line not-rely-on-time
        return deadline > block.timestamp;
    }

    function _approveHash(bytes32 hash, bytes[] memory signatures) internal {
        // Can only approve an unapproved hash
        require(hash != bytes32(0), "Wallet: Invalid hash");
        require(!_isHashApproved(hash), "Wallet: Approved hash");

        // Verify that the group agrees to approve the hash
        _verifyHashGuard(hash, signatures);

        _internalApproveHash(hash);
    }

    function _revokeHash(bytes32 hash, bytes[] memory signatures) internal {
        // Can only revoke an already approved hash
        require(hash != bytes32(0), "Wallet: Invalid hash");
        require(_isHashApproved(hash), "Wallet: Unapproved hash");

        // Verify that the group agrees to revoke the hash
        _verifyHashGuard(hash, signatures);

        _internalRevokeHash(hash);
    }

    /// @dev Reverts with "Wallet: Unapproved request", if `signatures` don't verify `hash`
    function _verifyHashGuard(bytes32 hash, bytes[] memory signatures)
        internal
        view
    {
        bytes32 ethSignedHash = ECDSA.toEthSignedMessageHash(hash);
        bool isAgreed = LibQuorumGovernance._verifyHash(
            ethSignedHash,
            signatures
        );
        require(isAgreed, "Wallet: Unapproved request");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for EIP712's domain separator
library StorageAnticDomain {
    struct DiamondStorage {
        bytes32 domainSeparator;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.AnticDomain");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for Antic fee
library StorageAnticFee {
    uint16 public constant PERCENTAGE_DIVIDER = 1000; // .1 precision
    uint16 public constant MAX_ANTIC_FEE_PERCENTAGE = 500; // 50%

    struct DiamondStorage {
        address antic;
        /// @dev Maps between member and it's Antic fee deposit
        /// Used only in `leave`
        mapping(address => uint256) memberFeeDeposits;
        /// @dev Total Antic join deposits mades
        uint256 totalJoinFeeDeposits;
        /// @dev Antic join fee percentage out of 1000
        /// e.g. 25 -> 25/1000 = 2.5%
        uint16 joinFeePercentage;
        /// @dev Antic sell/receive fee percentage out of 1000
        /// e.g. 25 -> 25/1000 = 2.5%
        uint16 sellFeePercentage;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.AnticFee");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }

    function _initStorage(
        address antic,
        uint16 joinFeePercentage,
        uint16 sellFeePercentage
    ) internal {
        DiamondStorage storage ds = diamondStorage();

        require(antic != address(0), "Storage: Invalid Antic address");

        require(
            joinFeePercentage <= MAX_ANTIC_FEE_PERCENTAGE,
            "Storage: Invalid Antic join fee percentage"
        );

        require(
            sellFeePercentage <= MAX_ANTIC_FEE_PERCENTAGE,
            "Storage: Invalid Antic sell/receive fee percentage"
        );

        ds.antic = antic;
        ds.joinFeePercentage = joinFeePercentage;
        ds.sellFeePercentage = sellFeePercentage;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for approved hashes
library StorageApprovedHashes {
    struct DiamondStorage {
        /// @dev Maps between hash and its deadline
        mapping(bytes32 => uint256) deadlines;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.ApprovedHashes");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for deployment cost split mechanism
library StorageDeploymentCost {
    struct DiamondStorage {
        /// @dev The account that deployed the contract
        address deployer;
        /// @dev Use to indicate that the deployer has joined the group
        /// (for deployment cost refund calculation)
        bool isDeployerJoined;
        /// @dev Contract deployment cost to refund (minus what the deployer already paid)
        uint256 deploymentCostToRefund;
        /// @dev Deployment cost refund paid so far
        uint256 paid;
        /// @dev Refund amount withdrawn by the deployer
        uint256 withdrawn;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.DeploymentCost");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for enacted propositions (propositions that already got executed)
library StorageEnactedPropositions {
    struct DiamondStorage {
        /// @dev Mapping of proposition's EIP712 hash to enacted flag
        mapping(bytes32 => bool) enactedPropositions;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.EnactedPropositions");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for the forming proposition
library StorageFormingProposition {
    struct DiamondStorage {
        /// @dev The hash of the forming proposition to be enacted
        bytes32 formingPropositionHash;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.FormingProposition");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }

    function _initStorage(bytes32 formingPropositionHash) internal {
        DiamondStorage storage ds = diamondStorage();

        require(
            formingPropositionHash != bytes32(0),
            "Storage: Invalid forming proposition hash"
        );

        ds.formingPropositionHash = formingPropositionHash;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

/// @author Amit Molek
/// @dev Diamond compatible storage for ownership units of members
library StorageOwnershipUnits {
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    struct DiamondStorage {
        /// @dev Smallest ownership unit
        uint256 smallestOwnershipUnit;
        /// @dev Total ownership units
        uint256 totalOwnershipUnits;
        /// @dev Amount of ownership units that are owned by members.
        /// join -> adding | leave -> subtracting
        /// This is used in the join process to know when the group is fully funded
        uint256 totalOwnedOwnershipUnits;
        /// @dev Maps between member and their ownership units
        EnumerableMap.AddressToUintMap ownershipUnits;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.OwnershipUnits");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }

    function _initStorage(
        uint256 smallestOwnershipUnit,
        uint256 totalOwnershipUnits
    ) internal {
        require(
            smallestOwnershipUnit > 0,
            "Storage: smallest ownership unit must be bigger than 0"
        );
        require(
            totalOwnershipUnits % smallestOwnershipUnit == 0,
            "Storage: total units not divisible by smallest unit"
        );

        DiamondStorage storage ds = diamondStorage();

        ds.smallestOwnershipUnit = smallestOwnershipUnit;
        ds.totalOwnershipUnits = totalOwnershipUnits;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for quorum governance
library StorageQuorumGovernance {
    struct DiamondStorage {
        /// @dev The minimum level of participation required for a vote to be valid.
        /// in percentages out of 100 (e.g. 40)
        uint8 quorumPercentage;
        /// @dev What percentage of the votes cast need to be in favor in order
        /// for the proposal to be accepted.
        /// in percentages out of 100 (e.g. 40)
        uint8 passRatePercentage;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.QuorumGovernance");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }

    function _initStorage(uint8 quorumPercentage, uint8 passRatePercentage)
        internal
    {
        require(
            quorumPercentage > 0 && quorumPercentage <= 100,
            "Storage: quorum percentage must be in range (0,100]"
        );
        require(
            passRatePercentage > 0 && passRatePercentage <= 100,
            "Storage: pass rate percentage must be in range (0,100]"
        );

        DiamondStorage storage ds = diamondStorage();

        ds.quorumPercentage = quorumPercentage;
        ds.passRatePercentage = passRatePercentage;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev Diamond compatible storage for receive funds
library StorageReceive {
    struct DiamondStorage {
        /// Map between a member and amount of funds it can withdraw
        mapping(address => uint256) withdrawable;
        /// Total withdrawable amount
        uint256 totalWithdrawable;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.Receive");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ReentrancyGuardStatus} from "../structs/ReentrancyGuardStatus.sol";

/// @author Amit Molek
/// @dev Diamond compatible storage for reentrancy guard
library StorageReentrancyGuard {
    struct DiamondStorage {
        /// @dev
        ReentrancyGuardStatus status;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.ReentrancyGuard");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {StateEnum} from "../structs/StateEnum.sol";

/// @author Amit Molek
/// @dev Diamond compatible storage for group state
library StorageState {
    struct DiamondStorage {
        /// @dev State of the group
        StateEnum state;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.State");

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 storagePosition = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := storagePosition
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWallet} from "../interfaces/IWallet.sol";

/// @author Amit Molek

/// @dev The data needed for `join`
/// This needs to be encoded (you can use `JoinDataCodec`) and be passed to `join`
struct JoinData {
    address member;
    IWallet.Proposition proposition;
    bytes[] signatures;
    /// @dev How much ownership units `member` want to acquire
    uint256 ownershipUnits;
}

/// @dev Codec for `JoinData`
contract JoinDataCodec {
    function encode(JoinData memory joinData)
        external
        pure
        returns (bytes memory)
    {
        return abi.encode(joinData);
    }

    function decode(bytes memory data) external pure returns (JoinData memory) {
        return abi.decode(data, (JoinData));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek

/// @dev Status enum for DiamondReentrancyGuard
enum ReentrancyGuardStatus {
    NOT_ENTERED,
    ENTERED
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek

/// @dev State of the contract/group
enum StateEnum {
    UNINITIALIZED,
    OPEN,
    FORMED
}