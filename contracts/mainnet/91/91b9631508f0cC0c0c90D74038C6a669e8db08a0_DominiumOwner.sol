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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
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

/// @title Multisig Governance interface
/// @author Amit Molek
interface IGovernance {
    /// @notice Verify the given hash using the governance rules
    /// @param hash the hash you want to verify
    /// @param signatures the member's signatures of the given hash
    /// @return true, if all the hash is verified
    function verifyHash(bytes32 hash, bytes[] memory signatures)
        external
        view
        returns (bool);
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

import {PartialMultisigWallet} from "./base/PartialMultisigWallet.sol";

/// @title Dominium's owner
/// @author Amit Molek
/// @notice Safer multi-sig based owner for the Dominium system
contract DominiumOwner is PartialMultisigWallet {
    constructor(address[] memory owners) PartialMultisigWallet(owners) {}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IGovernance} from "../../interfaces/IGovernance.sol";

import {LibEIP712} from "../../libraries/LibEIP712.sol";
import {LibPercentage} from "../../libraries/LibPercentage.sol";
import {LibSignature} from "../../libraries/LibSignature.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @title Multi-sig quorum governance based immutable group
/// @author Amit Molek
/// @dev Please see `IGovernance`.
/// Each owner gets an equal vote. To verify a hash, a minimum number
/// of approve votes MUST be present.
/// The minimum group size is 3: 1 is not a group and 2 it risky (1 stolen account can cause harm)
/// And the quorum threshold is 60%.
contract ImmutableQuorumGovernanceGroup is IGovernance, ERC165 {
    using EnumerableSet for EnumerableSet.AddressSet;

    /* CONSTANTS */

    /// @dev Minimum number of owners at any time
    uint256 public constant MIN_OWNERS_LENGTH = 3;
    /// @dev Percentage of how many owners MUST sign the hash to verify it
    /// e.g. 3 owners, 60% => 60% out of 3 is 2, so 2 owners must sign
    uint256 public constant QUORUM_THRESHOLD_PERCENTAGE = 60; // 60%

    /* FIELDS */

    /// @dev Minimum number of signatures needed to verify a hash
    uint256 public quorumGovernanceThreshold;

    /// @dev Set of owners
    EnumerableSet.AddressSet internal _owners;

    /* ERRORS */

    /// @dev Not enough owners to initialize the contract (see MIN_OWNERS_LENGTH)
    error MinimumOwners();

    /// @dev Unknown or invalid owner (Not an owner, zero address...)
    /// @param account The account in question
    error InvalidOwner(address account);

    /// @dev Owner already exist
    /// @param account The duplicated account
    error DuplicateOwner(address account);

    /// @dev Recevied invalid signatures (Unsorted)
    error InvalidSignatures();

    /// @dev Unverified hash. Not enough owners signed to reach the quorum threshold
    /// @param hash The hash in question
    error UnapprovedHash(bytes32 hash);

    constructor(address[] memory owners) {
        LibEIP712._initDomainSeparator();
        _initOwners(owners);
    }

    /// @param signatures must be sorted by address
    function verifyHash(bytes32 hash, bytes[] memory signatures)
        public
        view
        override
        returns (bool)
    {
        uint256 length = signatures.length;
        address prevSigner = address(0);
        address signer;
        uint256 validSignaturesCount;

        // Iterate over the signatures and count the valid ones
        for (uint256 i = 0; i < length; i++) {
            // Check for duplicates
            signer = LibSignature._recoverSigner(hash, signatures[i]);
            if (signer <= prevSigner) {
                revert InvalidSignatures();
            }
            prevSigner = signer;

            // Verify that the signer is an owner
            if (_owners.contains(signer) == false) {
                revert InvalidOwner(signer);
            }

            validSignaturesCount++;
        }

        return validSignaturesCount >= quorumGovernanceThreshold;
    }

    /// @return How many owners are in the group
    function ownersLength() external view returns (uint256) {
        return _owners.length();
    }

    /// @return Owner at index `i`
    function ownerAt(uint256 i) external view returns (address) {
        return _owners.at(i);
    }

    /// @return true, if `account` is an owner
    function isOwner(address account) external view returns (bool) {
        return _owners.contains(account);
    }

    /// @dev Reverts with `UnapprovedHash` if `hash` can't be verified using `signatures`
    function _verifyHashGuard(bytes32 hash, bytes[] memory signatures)
        internal
        view
    {
        if (verifyHash(hash, signatures) == false) {
            revert UnapprovedHash(hash);
        }
    }

    /// @dev Initialize owner set and quorum threshold
    function _initOwners(address[] memory owners) internal {
        if (owners.length < MIN_OWNERS_LENGTH) {
            revert MinimumOwners();
        }

        uint256 length = owners.length;
        for (uint256 i = 0; i < length; i++) {
            address owner = owners[i];

            if (owner == address(0)) {
                revert InvalidOwner(owner);
            }

            // Add owner
            bool success = _owners.add(owner);
            if (success == false) {
                revert DuplicateOwner(owner);
            }
        }

        // Calculate the quorum threshold
        quorumGovernanceThreshold = _calculateQuorumGovernanceThreshold(length);
    }

    /// @return The quorum threshold (see `quorumGovernanceThreshold`)
    function _calculateQuorumGovernanceThreshold(uint256 ownerLength)
        internal
        pure
        returns (uint256)
    {
        return
            LibPercentage._calculateCeil(
                ownerLength,
                QUORUM_THRESHOLD_PERCENTAGE
            );
    }

    /* ERC165 */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IGovernance).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IMultisigOwnerCut} from "../interfaces/IMultisigOwnerCut.sol";

import {ImmutableQuorumGovernanceGroup} from "./ImmutableQuorumGovernanceGroup.sol";
import {LibEIP712MultisigOwnerCut} from "../libraries/LibEIP712MultisigOwnerCut.sol";
import {LibEIP712} from "../../libraries/LibEIP712.sol";

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @title Multi-sig quorum governance based group
/// @author Amit Molek
/// @dev Please see `IMultisigOwnerCut` and `ImmutableQuorumGovernanceGroup`.
/// Gives the ability to Add/Replace/Remove owners from the group.
contract MutableQuorumGovernanceGroup is
    IMultisigOwnerCut,
    ImmutableQuorumGovernanceGroup
{
    using EnumerableSet for EnumerableSet.AddressSet;

    /* FIELDS */

    /// @dev Maps between owner cut hash and if it was already executed
    mapping(bytes32 => bool) public enactedOwnerCuts;

    /* ERRORS */

    /// @dev Already executed this owner cut
    /// @param cutHash The hash of the owner cut that was already executed
    error OwnerCutEnacted(bytes32 cutHash);

    /// @dev The owner cut ended/deadline passed
    /// @param cutHash The hash of the owner cut
    /// @param endedAt The owner cut deadline
    error OwnerCutEnded(bytes32 cutHash, uint256 endedAt);

    constructor(address[] memory owners)
        ImmutableQuorumGovernanceGroup(owners)
    {}

    function ownerCut(OwnerCut memory cut, bytes[] memory signatures)
        external
        override
    {
        bytes32 cutHash = toTypedDataHash(cut);

        // Verify that this cut is not already executed
        if (enactedOwnerCuts[cutHash]) {
            revert OwnerCutEnacted(cutHash);
        }

        // Make sure that the cut is still alive
        uint256 endsAt = cut.endsAt;
        // solhint-disable-next-line not-rely-on-time
        if (endsAt < block.timestamp) {
            revert OwnerCutEnded(cutHash, endsAt);
        }

        // Verify signatures
        _verifyHashGuard(cutHash, signatures);

        // Tag the cut as executed
        enactedOwnerCuts[cutHash] = true;

        emit IMultisigOwnerCut.OwnerCutExecuted(cut);

        IMultisigOwnerCut.OwnerCutAction action = cut.action;
        if (action == IMultisigOwnerCut.OwnerCutAction.ADD) {
            _safeAddOwnerCut(cut.account);
        } else if (action == IMultisigOwnerCut.OwnerCutAction.REPLACE) {
            _safeReplaceOwnerCut(cut.account, cut.prevAccount);
        } else if (action == IMultisigOwnerCut.OwnerCutAction.REMOVE) {
            _safeRemoveOwnerCut(cut.account);
        } else {
            revert IMultisigOwnerCut.InvalidOwnerCutAction(uint256(action));
        }
    }

    /// @dev Adds `account` as an owner and recalculated the quorum threshold
    function _safeAddOwnerCut(address account) internal {
        if (account == address(0)) {
            revert InvalidOwner(account);
        }

        bool success = _owners.add(account);
        if (success == false) {
            revert DuplicateOwner(account);
        }

        // Recalculate the quorum threshold
        quorumGovernanceThreshold = _calculateQuorumGovernanceThreshold(
            _owners.length()
        );
    }

    /// @dev Replaces `prevAccount` and `account` as owner
    function _safeReplaceOwnerCut(address account, address prevAccount)
        internal
    {
        if (account == address(0)) {
            revert InvalidOwner(account);
        }
        if (account == prevAccount) {
            revert DuplicateOwner(account);
        }

        // Remove previous owner
        bool success = _owners.remove(prevAccount);
        if (success == false) {
            revert InvalidOwner(prevAccount);
        }

        // Add new owner
        success = _owners.add(account);
        if (success == false) {
            revert DuplicateOwner(account);
        }
    }

    /// @dev Removes `account` as an owner and recalculates the quorum threshold
    function _safeRemoveOwnerCut(address account) internal {
        if (_owners.length() - 1 < MIN_OWNERS_LENGTH) {
            revert MinimumOwners();
        }

        bool success = _owners.remove(account);
        if (success == false) {
            revert InvalidOwner(account);
        }

        // Recalculate the quorum threshold
        quorumGovernanceThreshold = _calculateQuorumGovernanceThreshold(
            _owners.length()
        );
    }

    function toTypedDataHash(IMultisigOwnerCut.OwnerCut memory cut)
        public
        view
        returns (bytes32)
    {
        return
            LibEIP712._toTypedDataHash(
                LibEIP712MultisigOwnerCut._hashOwnerCut(cut)
            );
    }

    /* ERC165 */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IMultisigOwnerCut).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IWallet} from "../../interfaces/IWallet.sol";

import {MutableQuorumGovernanceGroup} from "./MutableQuorumGovernanceGroup.sol";
import {LibEIP712Proposition} from "../../libraries/LibEIP712Proposition.sol";
import {LibEIP712Transaction} from "../../libraries/LibEIP712Transaction.sol";
import {LibTransfer} from "../../libraries/LibTransfer.sol";

/// @title Multi-sig wallet (without value transfer)
/// @author Amit Molek
/// @dev Please see `IWallet` and `MutableQuorumGovernanceGroup`.
/// Gives the ability to execute valueless transaction
contract PartialMultisigWallet is IWallet, MutableQuorumGovernanceGroup {
    /* FIELDS */

    /// @dev Maps between proposition hash and if it was already enacted
    mapping(bytes32 => bool) private _enactedPropositions;

    /* ERRORS */

    /// @dev Already enacted this proposition
    /// @param propositionHash The hash of the proposition
    error PropositionEnacted(bytes32 propositionHash);

    /// @dev The proposition ended/deadline passed
    /// @param propositionHash The hash of the proposition
    /// @param endedAt The proposition's deadline
    error PropositionEnded(bytes32 propositionHash, uint256 endedAt);

    /// @dev You can't transfer value using this wallet
    error ValueTransferUnsupported();

    constructor(address[] memory owners) MutableQuorumGovernanceGroup(owners) {}

    function enactProposition(
        Proposition memory proposition,
        bytes[] memory signatures
    ) external override returns (bool successful, bytes memory returnData) {
        // This wallet doesn't support transfer of value
        if (proposition.tx.value > 0) {
            revert ValueTransferUnsupported();
        }

        bytes32 propositionHash = toTypedDataHash(proposition);

        // A proposition can only be enacted once
        if (_enactedPropositions[propositionHash]) {
            revert PropositionEnacted(propositionHash);
        }

        // Make sure that the proposition is still alive
        uint256 endsAt = proposition.endsAt;
        // solhint-disable-next-line not-rely-on-time
        if (endsAt < block.timestamp) {
            revert PropositionEnded(propositionHash, endsAt);
        }

        // Verify that the proposition is agreed upon
        _verifyHashGuard(propositionHash, signatures);

        // Tag the proposition as enacted
        _enactedPropositions[propositionHash] = true;

        IWallet.Transaction memory transaction = proposition.tx;

        (successful, returnData) = LibTransfer._untrustedCall(
            transaction.to,
            0,
            transaction.data
        );

        emit ExecutedTransaction(toTypedDataHash(transaction), 0, successful);
    }

    function isPropositionEnacted(bytes32 propositionHash)
        external
        view
        override
        returns (bool)
    {
        return _enactedPropositions[propositionHash];
    }

    function maxAllowedTransfer() external pure override returns (uint256) {
        // This wallet doesn't allow to transfer or receive value
        return 0;
    }

    function toTypedDataHash(IWallet.Proposition memory proposition)
        public
        view
        returns (bytes32)
    {
        return LibEIP712Proposition._toTypedDataHash(proposition);
    }

    function toTypedDataHash(IWallet.Transaction memory transaction)
        public
        view
        returns (bytes32)
    {
        return LibEIP712Transaction._toTypedDataHash(transaction);
    }

    /* ERC165 */

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IWallet).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @title Owner managment using multi-sig
/// @author Amit Molek
interface IMultisigOwnerCut {
    enum OwnerCutAction {
        ADD,
        REPLACE,
        REMOVE
    }

    struct OwnerCut {
        OwnerCutAction action;
        /// @dev ADD: The account you want to add as an owner
        /// REPLACE: The account you want to replace the old owner with
        /// REMOVE: The account you want to remove
        address account;
        /// @dev Used in REPLACE mode. This is the account you want to replace
        address prevAccount;
        /// @dev Cut's deadline
        uint256 endsAt;
    }

    /// @dev Emitted on `ownerCut`
    /// @param cut The cut that was executed
    event OwnerCutExecuted(OwnerCut cut);

    /// @dev Indicates that an invalid owner cut action happend
    error InvalidOwnerCutAction(uint256 action);

    /// @notice Add/Replace/Remove owners
    /// @dev Explain to a developer any extra details
    /// @param cut Contains the action to execute
    /// @param signatures A set of approving EIP712 signatures on `cut`
    function ownerCut(OwnerCut memory cut, bytes[] memory signatures) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {IMultisigOwnerCut} from "../interfaces/IMultisigOwnerCut.sol";

/// @author Amit Molek
/// @dev EIP712 helper functions for IMultisigOwnerCut multi-sig
library LibEIP712MultisigOwnerCut {
    bytes32 internal constant _OWNER_CUT_TYPEHASH =
        keccak256(
            "OwnerCut(uint256 action,address account,address prevAccount,uint256 endsAt)"
        );

    function _hashOwnerCut(IMultisigOwnerCut.OwnerCut memory cut)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _OWNER_CUT_TYPEHASH,
                    cut.action,
                    cut.account,
                    cut.prevAccount,
                    cut.endsAt
                )
            );
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