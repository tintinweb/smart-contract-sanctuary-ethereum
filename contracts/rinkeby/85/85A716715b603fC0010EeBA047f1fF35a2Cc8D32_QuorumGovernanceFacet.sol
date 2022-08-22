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
pragma solidity ^0.8.4;

import {IGovernance} from "../../interfaces/IGovernance.sol";
import {LibQuorumGovernance} from "../../libraries/LibQuorumGovernance.sol";
import {StorageQuorumGovernance} from "../../storage/StorageQuorumGovernance.sol";

/// @title Quorum Governance
/// @author Amit Molek
/// @dev A hash is verified based upon 2 factors:
///     - Quorum: minimum level of participation required for a vote to be valid
///     - Pass rate: the percentage of the votes cast that needs to be in favor in order for the hash to be accepted
/// See: https://aragon.org/how-to/setting-dao-governance-thresholds
/// Please see `IGovernance` and `LibQuorumGovernance` for more docs.
contract QuorumGovernanceFacet is IGovernance {
    function verifyHash(bytes32 hash, bytes[] memory signatures)
        external
        view
        override
        returns (bool)
    {
        return LibQuorumGovernance._verifyHash(hash, signatures);
    }

    function quorumPercentage() external view returns (uint256) {
        StorageQuorumGovernance.DiamondStorage
            storage ds = StorageQuorumGovernance.diamondStorage();

        return ds.quorumPercentage;
    }

    function passRatePercentage() external view returns (uint256) {
        StorageQuorumGovernance.DiamondStorage
            storage ds = StorageQuorumGovernance.diamondStorage();

        return ds.passRatePercentage;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
pragma solidity ^0.8.4;

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

    /// @dev Emitted on approved hash
    /// @param hash the approved hash
    event ApprovedHash(bytes32 hash);

    /// @return true if the hash has been approved
    function isHashApproved(bytes32 hash) external view returns (bool);

    /// @notice Execute proposition
    /// @param proposition the proposition to enact
    /// @param signatures a set of members EIP712 signatures on `proposition`
    /// @dev Emits `ExecutedTransaction` and `ApprovedHash` (only if `relevantHash` is passed) events
    function enactProposition(
        Proposition memory proposition,
        bytes[] memory signatures
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibGroup} from "./LibGroup.sol";
import {LibOwnership} from "./LibOwnership.sol";

/// @author Amit Molek
/// @dev Please see `IDeposit` for docs
library LibDeposit {
    event Deposited(address member, uint256 amount);

    function _deposit() internal {
        _deposit(msg.sender);
    }

    /// @dev Can revert:
    ///     - "Deposit: not a member": If the group is already formed
    ///     - "Storage: deposit not divisible by smallest unit": Deposit is not divisble by ownership smallest unit
    /// Emits `Deposited` event
    function _deposit(address member) internal returns (uint256 amount) {
        require(LibGroup._isMember(member), "Deposit: not a member");

        // Deposit must be divisble by the ownership smallest unit
        amount = msg.value;
        require(
            amount % LibOwnership._smallestUnit() == 0,
            "Storage: deposit not divisible by smallest unit"
        );

        emit Deposited(msg.sender, amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IWallet} from "../interfaces/IWallet.sol";
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

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.LibEIP712");

    struct DiamondStorage {
        bytes32 domainSeparator;
    }

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

    /// @dev Initializes the EIP712's domain seperator
    /// note Must be called at least once, because it saves the
    /// domain seperator in storage
    function _initDomainSeperator() internal {
        DiamondStorage storage ds = diamondStorage();
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
        return ECDSA.toTypedDataHash(_domainSeperator(), messageHash);
    }

    function _domainSeperator() internal view returns (bytes32) {
        DiamondStorage storage ds = diamondStorage();
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
pragma solidity ^0.8.4;

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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {LibDeposit} from "./LibDeposit.sol";
import {StorageGroupMembers} from "../storage/StorageGroupMembers.sol";
import {StorageState} from "../storage/StorageState.sol";
import {StateEnum} from "../structs/StateEnum.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {LibState} from "../libraries/LibState.sol";
import {LibOwnership} from "../libraries/LibOwnership.sol";
import {LibTransfer} from "../libraries/LibTransfer.sol";
import {LibWallet} from "../libraries/LibWallet.sol";
import {IWallet} from "../interfaces/IWallet.sol";
import {JoinData} from "../structs/JoinData.sol";

/// @author Amit Molek
/// @dev Please see `IGroup` for docs
library LibGroup {
    using EnumerableSet for EnumerableSet.AddressSet;

    event Joined(address account);
    event Left(address account);

    /// @dev Decodes `data` and passes it to `_join`
    /// `data` must be encoded `JoinData` struct
    function _joinDecode(bytes memory data) internal {
        JoinData memory joinData = abi.decode(data, (JoinData));

        _join(joinData.member, joinData.proposition, joinData.signatures);
    }

    /// @dev Can revert:
    ///     - "Group: group formed": If the group is already formed
    ///     - "Group: already a member": If the caller is already a member
    /// Emits `Joined` event
    function _join(
        address member,
        IWallet.Proposition memory proposition,
        bytes[] memory signatures
    ) internal {
        // Members can join only when the group is forming (open)
        require(LibState._state() == StateEnum.OPEN, "Group: group formed");

        // Add the member
        StorageGroupMembers.DiamondStorage
            storage groupMembers = StorageGroupMembers.diamondStorage();
        require(groupMembers.members.add(member), "Group: already a member");

        // Join deposit
        uint256 depositAmount = LibDeposit._deposit(member);

        // Add the member as a owner
        LibOwnership._addOwner(member, depositAmount);

        emit Joined(member);

        // Last member to acquire the remaining ownership units, enacts the proposition
        // and forms the group
        if (LibOwnership._isCompletelyOwned()) {
            // The group is now formed
            LibState._changeState(StateEnum.FORMED);

            LibWallet._enactProposition(proposition, signatures);
        }
    }

    /// @dev Can revert:
    ///     - "Group: group formed": If the group is already formed
    ///     - "Group: not a member": If the caller is not a member
    /// Emits `Left` event
    function _leave() internal {
        // Members can leave only while the group is forming (open)
        require(LibState._state() == StateEnum.OPEN, "Group: group formed");

        // Remove the member
        StorageGroupMembers.DiamondStorage
            storage groupMembers = StorageGroupMembers.diamondStorage();
        require(groupMembers.members.remove(msg.sender), "Group: not a member");

        // Caller renounce his ownership
        uint256 refundAmount = LibOwnership._renounceOwnership();

        // Refund the caller with his join deposit
        LibTransfer._transfer(msg.sender, refundAmount);

        emit Left(msg.sender);
    }

    function _isMember(address account) internal view returns (bool) {
        StorageGroupMembers.DiamondStorage
            storage groupMembers = StorageGroupMembers.diamondStorage();
        return groupMembers.members.contains(account);
    }

    function _members() internal view returns (address[] memory) {
        StorageGroupMembers.DiamondStorage
            storage groupMembers = StorageGroupMembers.diamondStorage();
        return groupMembers.members.values();
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {StorageOwnershipUnits} from "../storage/StorageOwnershipUnits.sol";
import {LibState} from "../libraries/LibState.sol";
import {StateEnum} from "../structs/StateEnum.sol";

/// @author Amit Molek
/// @dev Please see `IOwnership` for docs
library LibOwnership {
    /// @dev Can revert:
    ///     - "Ownership: group formed": If the group state is not valid
    function _addOwner(address account, uint256 units) internal {
        // Verify that the group is still open
        require(LibState._state() == StateEnum.OPEN, "Ownership: group formed");

        // Store the owner
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        // Update the member's ownership units and the total ownership units owned
        ds.ownershipUnits[account] = units;
        ds.totalOwnedOwnershipUnits += units;
    }

    /// @dev Can revert:
    ///     - "Ownership: group formed": If the group state is not valid
    ///     - "Ownership: not an owner": If the caller is not a group member
    function _renounceOwnership() internal returns (uint256 refund) {
        // Verify that the group is still open
        require(LibState._state() == StateEnum.OPEN, "Ownership: group formed");

        // Verify that the caller is a member
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();
        require(ds.ownershipUnits[msg.sender] > 0, "Ownership: not an owner");

        // Update the member ownership units and the total units owned
        refund = ds.ownershipUnits[msg.sender];
        ds.totalOwnedOwnershipUnits -= refund;
        delete ds.ownershipUnits[msg.sender];
    }

    function _ownershipUnits(address member) internal view returns (uint256) {
        StorageOwnershipUnits.DiamondStorage storage ds = StorageOwnershipUnits
            .diamondStorage();

        return ds.ownershipUnits[member];
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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
pragma solidity ^0.8.4;

import {LibSignature} from "./LibSignature.sol";
import {LibPercentage} from "./LibPercentage.sol";
import {LibGroup} from "./LibGroup.sol";
import {LibOwnership} from "./LibOwnership.sol";
import {StorageQuorumGovernance} from "../storage/StorageQuorumGovernance.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @author Amit Molek
/// @dev Implements the quorum governance system, based on:
/// https://aragon.org/how-to/setting-dao-governance-thresholds
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

        for (uint256 i = 0; i < signatures.length; i++) {
            address signer = LibSignature._recoverSigner(hash, signatures[i]);

            require(
                LibGroup._isMember(signer),
                string(
                    abi.encodePacked(
                        "Governance: Signer ",
                        Strings.toHexString(uint256(uint160(signer)), 20),
                        " is not a member"
                    )
                )
            );

            // Check for duplication (same signer)
            require(
                __contains(signer, members, i) == false,
                string(
                    abi.encodePacked(
                        "Governance: Signer ",
                        Strings.toHexString(uint256(uint160(signer)), 20),
                        " already signed"
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
        uint256 groupSize = LibGroup._members().length;
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

        return (totalSignersUnits * 100) / totalUnits;
    }

    function __contains(
        address addr,
        address[] memory addresses,
        uint256 length
    ) private pure returns (bool) {
        for (uint256 i = 0; i < length; i++) {
            if (addr == addresses[i]) {
                return true;
            }
        }

        return false;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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
pragma solidity ^0.8.4;

import {StorageState} from "../storage/StorageState.sol";
import {StateEnum} from "../structs/StateEnum.sol";

/// @author Amit Molek
/// @dev Contract/Group state
library LibState {
    /// @dev Emits on event change
    /// @param from the previous event
    /// @param to the new event
    event StateChanged(StateEnum from, StateEnum to);

    /// @dev Changes the state of the contract/group
    /// Can revert:
    ///     - "State: same state": When changing the state to the same one
    /// Emits `StateChanged` event
    /// @param state the new state
    function _changeState(StateEnum state) internal {
        StorageState.DiamondStorage storage ds = StorageState.diamondStorage();
        require(ds.state != state, "State: same state");

        ds.state = state;

        emit StateChanged(ds.state, state);
    }

    /// @return the current state of the contract/group
    function _state() internal view returns (StateEnum) {
        StorageState.DiamondStorage storage ds = StorageState.diamondStorage();

        return ds.state;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @author Amit Molek
/// @dev Transfer helpers
library LibTransfer {
    function _transfer(address recipient, uint256 value) internal {
        payable(recipient).transfer(value);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IWallet} from "../interfaces/IWallet.sol";
import {LibQuorumGovernance} from "../libraries/LibQuorumGovernance.sol";
import {LibEIP712Transaction} from "../libraries/LibEIP712Transaction.sol";
import {LibEIP712} from "../libraries/LibEIP712.sol";
import {LibGroup} from "../libraries/LibGroup.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {StorageEnactedPropositions} from "../storage/StorageEnactedPropositions.sol";
import {LibEIP712Proposition} from "../libraries/LibEIP712Proposition.sol";
import {StorageApprovedHashes} from "../storage/StorageApprovedHashes.sol";
import {LibState} from "../libraries/LibState.sol";
import {StateEnum} from "../structs/StateEnum.sol";

/// @author Amit Molek
/// @dev Please see `IWallet` for docs
library LibWallet {
    event ExecutedTransaction(
        bytes32 indexed hash,
        uint256 value,
        bool successful
    );
    event ApprovedHash(bytes32 hash);

    uint8 private constant WORD = 0x20; // 32

    function _isHashApproved(bytes32 hash) internal view returns (bool) {
        StorageApprovedHashes.DiamondStorage storage ds = StorageApprovedHashes
            .diamondStorage();

        return ds.approvedHashes[hash];
    }

    /// @dev Emits `ExecutedTransaction` event
    /// @param transaction the transaction to execute
    function _executeTransaction(IWallet.Transaction memory transaction)
        internal
        returns (bool successful)
    {
        address to = transaction.to;
        uint256 value = transaction.value;
        bytes memory data = transaction.data;
        assembly {
            successful := call(
                gas(),
                to,
                value,
                add(data, WORD), // skip first word (array's length)
                mload(data),
                0,
                0
            )
        }

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
    function _enactProposition(
        IWallet.Proposition memory proposition,
        bytes[] memory signatures
    ) internal {
        require(
            LibState._state() == StateEnum.FORMED,
            "Wallet: Group not formed"
        );

        bytes32 propositionHash = LibEIP712._toTypedDataHash(
            LibEIP712Proposition._hashProposition(proposition)
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
            StorageApprovedHashes.DiamondStorage
                storage ds = StorageApprovedHashes.diamondStorage();
            ds.approvedHashes[proposition.relevantHash] = true;

            emit ApprovedHash(proposition.relevantHash);
        }

        _executeTransaction(proposition.tx);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @author Amit Molek
/// @dev Diamond compatible storage for approved hashes
library StorageApprovedHashes {
    struct DiamondStorage {
        /// @dev Mapping of approved hashes
        mapping(bytes32 => bool) approvedHashes;
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
pragma solidity ^0.8.4;

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
pragma solidity ^0.8.4;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/// @author Amit Molek
/// @dev Diamond compatible storage for storing group members
library StorageGroupMembers {
    using EnumerableSet for EnumerableSet.AddressSet;

    struct DiamondStorage {
        /// @dev Set of all members addresses
        EnumerableSet.AddressSet members;
    }

    bytes32 public constant DIAMOND_STORAGE_POSITION =
        keccak256("antic.storage.GroupMembers");

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
pragma solidity ^0.8.4;

/// @author Amit Molek
/// @dev Diamond compatible storage for ownership units of members
library StorageOwnershipUnits {
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
        mapping(address => uint256) ownershipUnits;
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
pragma solidity ^0.8.4;

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
pragma solidity ^0.8.4;

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

    function _initStorage() internal {
        DiamondStorage storage ds = diamondStorage();
        ds.state = StateEnum.OPEN;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IWallet} from "../interfaces/IWallet.sol";

/// @author Amit Molek

/// @dev The data needed for `join`
/// This needs to be encoded (you can use `JoinDataCodec`) and be passed to `join`
struct JoinData {
    address member;
    IWallet.Proposition proposition;
    bytes[] signatures;
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
pragma solidity ^0.8.4;

/// @author Amit Molek

/// @dev State of the contract/group
enum StateEnum {
    OPEN,
    FORMED
}