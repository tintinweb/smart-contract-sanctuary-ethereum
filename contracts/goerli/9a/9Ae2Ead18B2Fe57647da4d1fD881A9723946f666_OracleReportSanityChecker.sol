// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

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
library SafeCast {
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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

// SPDX-FileCopyrightText: 2023 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

/* See contracts/COMPILERS.md */
pragma solidity 0.8.9;

import {Math256} from "../../common/lib/Math256.sol";

/**
 * This library implements positive rebase limiter for `stETH` token.
 * One needs to initialize `LimiterState` with the desired parameters:
 * - _rebaseLimit (limiter max value, nominated in LIMITER_PRECISION_BASE)
 * - _preTotalPooledEther (see `Lido.getTotalPooledEther()`), pre-rebase value
 * - _preTotalShares (see `Lido.getTotalShares()`), pre-rebase value
 *
 * The limiter allows to account for:
 * - consensus layer balance updates (can be either positive or negative)
 * - total pooled ether changes (withdrawing funds from vaults on execution layer)
 * - total shares changes (burning due to coverage, NOR penalization, withdrawals finalization, etc.)
 */

/**
 * @dev Internal limiter representation struct (storing in memory)
 */
struct TokenRebaseLimiterData {
    uint256 preTotalPooledEther;     // pre-rebase total pooled ether
    uint256 preTotalShares;          // pre-rebase total shares
    uint256 currentTotalPooledEther; // intermediate total pooled ether amount while token rebase is in progress
    uint256 positiveRebaseLimit;     // positive rebase limit (target value) with 1e9 precision (`LIMITER_PRECISION_BASE`)
}

/**
 *
 * Two-steps flow: account for total supply changes and then determine the shares allowed to be burnt.
 *
 * Conventions:
 *     R - token rebase limit (i.e, {postShareRate / preShareRate - 1} <= R);
 *   inc - total pooled ether increase;
 *   dec - total shares decrease.
 *
 * ### Step 1. Calculating the allowed total pooled ether changes (preTotalShares === postTotalShares)
 *     Used for `PositiveTokenRebaseLimiter.increaseEther()`, `PositiveTokenRebaseLimiter.decreaseEther()`.
 *
 * R = ((preTotalPooledEther + inc) / preTotalShares) / (preTotalPooledEther / preTotalShares) - 1
 * = ((preTotalPooledEther + inc) / preTotalShares) * (preTotalShares / preTotalPooledEther) - 1
 * = (preTotalPooledEther + inc) / preTotalPooledEther) - 1
 * = inc/preTotalPooledEther
 *
 * isolating inc:
 *
 * ``` inc = R * preTotalPooledEther ```
 *
 * ### Step 2. Calculating the allowed to burn shares (preTotalPooledEther != currentTotalPooledEther)
 *     Used for `PositiveTokenRebaseLimiter.getSharesToBurnLimit()`.
 *
 * R = (currentTotalPooledEther / (preTotalShares - dec)) / (preTotalPooledEther / preTotalShares) - 1,
 * let X = currentTotalPooledEther / preTotalPooledEther
 *
 * then:
 * R = X * (preTotalShares / (preTotalShares - dec)) - 1, or
 * (R+1) * (preTotalShares - dec) = X * preTotalShares
 *
 * isolating dec:
 * dec * (R + 1) = (R + 1 - X) * preTotalShares =>
 *
 * ``` dec = preTotalShares * (R + 1 - currentTotalPooledEther/preTotalPooledEther) / (R + 1) ```
 *
 */
library PositiveTokenRebaseLimiter {
    /// @dev Precision base for the limiter (e.g.: 1e6 - 0.1%; 1e9 - 100%)
    uint256 public constant LIMITER_PRECISION_BASE = 10**9;
    /// @dev Disabled limit
    uint256 public constant UNLIMITED_REBASE = type(uint64).max;

    /**
     * @dev Initialize the new `LimiterState` structure instance
     * @param _rebaseLimit max limiter value (saturation point), see `LIMITER_PRECISION_BASE`
     * @param _preTotalPooledEther pre-rebase total pooled ether, see `Lido.getTotalPooledEther()`
     * @param _preTotalShares pre-rebase total shares, see `Lido.getTotalShares()`
     * @return limiterState newly initialized limiter structure
     */
    function initLimiterState(
        uint256 _rebaseLimit,
        uint256 _preTotalPooledEther,
        uint256 _preTotalShares
    ) internal pure returns (TokenRebaseLimiterData memory limiterState) {
        if (_rebaseLimit == 0) revert TooLowTokenRebaseLimit();
        if (_rebaseLimit > UNLIMITED_REBASE) revert TooHighTokenRebaseLimit();

        // special case
        if (_preTotalPooledEther == 0) { _rebaseLimit = UNLIMITED_REBASE; }

        limiterState.currentTotalPooledEther = limiterState.preTotalPooledEther = _preTotalPooledEther;
        limiterState.preTotalShares = _preTotalShares;
        limiterState.positiveRebaseLimit = _rebaseLimit;
    }

    /**
     * @notice check if positive rebase limit is reached
     * @param _limiterState limit repr struct
     * @return true if limit is reached
     */
    function isLimitReached(TokenRebaseLimiterData memory _limiterState) internal pure returns (bool) {
        if (_limiterState.positiveRebaseLimit == UNLIMITED_REBASE) return false;
        if (_limiterState.currentTotalPooledEther < _limiterState.preTotalPooledEther) return false;

        uint256 accumulatedEther = _limiterState.currentTotalPooledEther - _limiterState.preTotalPooledEther;
        uint256 accumulatedRebase;

        if (_limiterState.preTotalPooledEther > 0) {
            accumulatedRebase = accumulatedEther * LIMITER_PRECISION_BASE / _limiterState.preTotalPooledEther;
        }

        return accumulatedRebase >= _limiterState.positiveRebaseLimit;
    }

    /**
     * @notice decrease total pooled ether by the given amount of ether
     * @param _limiterState limit repr struct
     * @param _etherAmount amount of ether to decrease
     */
    function decreaseEther(
        TokenRebaseLimiterData memory _limiterState, uint256 _etherAmount
    ) internal pure {
        if (_limiterState.positiveRebaseLimit == UNLIMITED_REBASE) return;

        if (_etherAmount > _limiterState.currentTotalPooledEther) revert NegativeTotalPooledEther();

        _limiterState.currentTotalPooledEther -= _etherAmount;
    }

    /**
     * @dev increase total pooled ether up to the limit and return the consumed value (not exceeding the limit)
     * @param _limiterState limit repr struct
     * @param _etherAmount desired ether addition
     * @return consumedEther appended ether still not exceeding the limit
     */
    function increaseEther(
        TokenRebaseLimiterData memory _limiterState, uint256 _etherAmount
    )
        internal
        pure
        returns (uint256 consumedEther)
    {
        if (_limiterState.positiveRebaseLimit == UNLIMITED_REBASE) return _etherAmount;

        uint256 prevPooledEther = _limiterState.currentTotalPooledEther;
        _limiterState.currentTotalPooledEther += _etherAmount;

        uint256 maxTotalPooledEther = _limiterState.preTotalPooledEther +
            (_limiterState.positiveRebaseLimit * _limiterState.preTotalPooledEther) / LIMITER_PRECISION_BASE;

        _limiterState.currentTotalPooledEther
            = Math256.min(_limiterState.currentTotalPooledEther, maxTotalPooledEther);

        assert(_limiterState.currentTotalPooledEther >= prevPooledEther);

        return _limiterState.currentTotalPooledEther - prevPooledEther;
    }

    /**
     * @dev return shares to burn value not exceeding the limit
     * @param _limiterState limit repr struct
     * @return maxSharesToBurn allowed to deduct shares to not exceed the limit
     */
    function getSharesToBurnLimit(TokenRebaseLimiterData memory _limiterState)
        internal
        pure
        returns (uint256 maxSharesToBurn)
    {
        if (_limiterState.positiveRebaseLimit == UNLIMITED_REBASE) return _limiterState.preTotalShares;

        if (isLimitReached(_limiterState)) return 0;

        uint256 rebaseLimitPlus1 = _limiterState.positiveRebaseLimit + LIMITER_PRECISION_BASE;
        uint256 pooledEtherRate =
            (_limiterState.currentTotalPooledEther * LIMITER_PRECISION_BASE) / _limiterState.preTotalPooledEther;

        maxSharesToBurn = (_limiterState.preTotalShares * (rebaseLimitPlus1 - pooledEtherRate)) / rebaseLimitPlus1;
    }

    error TooLowTokenRebaseLimit();
    error TooHighTokenRebaseLimit();
    error NegativeTotalPooledEther();
}

// SPDX-FileCopyrightText: 2023 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

/* See contracts/COMPILERS.md */
pragma solidity 0.8.9;

import {SafeCast} from "@openzeppelin/contracts-v4.4/utils/math/SafeCast.sol";

import {Math256} from "../../common/lib/Math256.sol";
import {AccessControlEnumerable} from "../utils/access/AccessControlEnumerable.sol";
import {PositiveTokenRebaseLimiter, TokenRebaseLimiterData} from "../lib/PositiveTokenRebaseLimiter.sol";
import {ILidoLocator} from "../../common/interfaces/ILidoLocator.sol";
import {IBurner} from "../../common/interfaces/IBurner.sol";

interface IWithdrawalQueue {
    struct WithdrawalRequestStatus {
        /// @notice stETH token amount that was locked on withdrawal queue for this request
        uint256 amountOfStETH;
        /// @notice amount of stETH shares locked on withdrawal queue for this request
        uint256 amountOfShares;
        /// @notice address that can claim or transfer this request
        address owner;
        /// @notice timestamp of when the request was created, in seconds
        uint256 timestamp;
        /// @notice true, if request is finalized
        bool isFinalized;
        /// @notice true, if request is claimed. Request is claimable if (isFinalized && !isClaimed)
        bool isClaimed;
    }

    function getWithdrawalStatus(uint256[] calldata _requestIds)
        external
        view
        returns (WithdrawalRequestStatus[] memory statuses);
}

/// @notice The set of restrictions used in the sanity checks of the oracle report
/// @dev struct is loaded from the storage and stored in memory during the tx running
struct LimitsList {
    /// @notice The max possible number of validators that might appear or exit on the Consensus
    ///     Layer during one day
    /// @dev Must fit into uint16 (<= 65_535)
    uint256 churnValidatorsPerDayLimit;

    /// @notice The max decrease of the total validators' balances on the Consensus Layer since
    ///     the previous oracle report
    /// @dev Represented in the Basis Points (100% == 10_000)
    uint256 oneOffCLBalanceDecreaseBPLimit;

    /// @notice The max annual increase of the total validators' balances on the Consensus Layer
    ///     since the previous oracle report
    /// @dev Represented in the Basis Points (100% == 10_000)
    uint256 annualBalanceIncreaseBPLimit;

    /// @notice The max deviation of the provided `simulatedShareRate`
    ///     and the actual one within the currently processing oracle report
    /// @dev Represented in the Basis Points (100% == 10_000)
    uint256 simulatedShareRateDeviationBPLimit;

    /// @notice The max number of exit requests allowed in report to ValidatorsExitBusOracle
    uint256 maxValidatorExitRequestsPerReport;

    /// @notice The max number of data list items reported to accounting oracle in extra data
    /// @dev Must fit into uint16 (<= 65_535)
    uint256 maxAccountingExtraDataListItemsCount;

    /// @notice The max number of node operators reported per extra data list item
    /// @dev Must fit into uint16 (<= 65_535)
    uint256 maxNodeOperatorsPerExtraDataItemCount;

    /// @notice The min time required to be passed from the creation of the request to be
    ///     finalized till the time of the oracle report
    uint256 requestTimestampMargin;

    /// @notice The positive token rebase allowed per single LidoOracle report
    /// @dev uses 1e9 precision, e.g.: 1e6 - 0.1%; 1e9 - 100%, see `setMaxPositiveTokenRebase()`
    uint256 maxPositiveTokenRebase;
}

/// @dev The packed version of the LimitsList struct to be effectively persisted in storage
struct LimitsListPacked {
    uint16 churnValidatorsPerDayLimit;
    uint16 oneOffCLBalanceDecreaseBPLimit;
    uint16 annualBalanceIncreaseBPLimit;
    uint16 simulatedShareRateDeviationBPLimit;
    uint16 maxValidatorExitRequestsPerReport;
    uint16 maxAccountingExtraDataListItemsCount;
    uint16 maxNodeOperatorsPerExtraDataItemCount;
    uint64 requestTimestampMargin;
    uint64 maxPositiveTokenRebase;
}

uint256 constant MAX_BASIS_POINTS = 10_000;
uint256 constant SHARE_RATE_PRECISION_E27 = 1e27;

/// @title Sanity checks for the Lido's oracle report
/// @notice The contracts contain view methods to perform sanity checks of the Lido's oracle report
///     and lever methods for granular tuning of the params of the checks
contract OracleReportSanityChecker is AccessControlEnumerable {
    using LimitsListPacker for LimitsList;
    using LimitsListUnpacker for LimitsListPacked;
    using PositiveTokenRebaseLimiter for TokenRebaseLimiterData;

    bytes32 public constant ALL_LIMITS_MANAGER_ROLE = keccak256("ALL_LIMITS_MANAGER_ROLE");
    bytes32 public constant CHURN_VALIDATORS_PER_DAY_LIMIT_MANGER_ROLE =
        keccak256("CHURN_VALIDATORS_PER_DAY_LIMIT_MANGER_ROLE");
    bytes32 public constant ONE_OFF_CL_BALANCE_DECREASE_LIMIT_MANAGER_ROLE =
        keccak256("ONE_OFF_CL_BALANCE_DECREASE_LIMIT_MANAGER_ROLE");
    bytes32 public constant ANNUAL_BALANCE_INCREASE_LIMIT_MANAGER_ROLE =
        keccak256("ANNUAL_BALANCE_INCREASE_LIMIT_MANAGER_ROLE");
    bytes32 public constant SHARE_RATE_DEVIATION_LIMIT_MANAGER_ROLE =
        keccak256("SHARE_RATE_DEVIATION_LIMIT_MANAGER_ROLE");
    bytes32 public constant MAX_VALIDATOR_EXIT_REQUESTS_PER_REPORT_ROLE =
        keccak256("MAX_VALIDATOR_EXIT_REQUESTS_PER_REPORT_ROLE");
    bytes32 public constant MAX_ACCOUNTING_EXTRA_DATA_LIST_ITEMS_COUNT_ROLE =
        keccak256("MAX_ACCOUNTING_EXTRA_DATA_LIST_ITEMS_COUNT_ROLE");
    bytes32 public constant MAX_NODE_OPERATORS_PER_EXTRA_DATA_ITEM_COUNT_ROLE =
        keccak256("MAX_NODE_OPERATORS_PER_EXTRA_DATA_ITEM_COUNT_ROLE");
    bytes32 public constant REQUEST_TIMESTAMP_MARGIN_MANAGER_ROLE = keccak256("REQUEST_TIMESTAMP_MARGIN_MANAGER_ROLE");
    bytes32 public constant MAX_POSITIVE_TOKEN_REBASE_MANAGER_ROLE =
        keccak256("MAX_POSITIVE_TOKEN_REBASE_MANAGER_ROLE");

    uint256 private constant DEFAULT_TIME_ELAPSED = 1 hours;
    uint256 private constant DEFAULT_CL_BALANCE = 1 gwei;
    uint256 private constant SECONDS_PER_DAY = 24 * 60 * 60;

    ILidoLocator private immutable LIDO_LOCATOR;

    LimitsListPacked private _limits;

    struct ManagersRoster {
        address[] allLimitsManagers;
        address[] churnValidatorsPerDayLimitManagers;
        address[] oneOffCLBalanceDecreaseLimitManagers;
        address[] annualBalanceIncreaseLimitManagers;
        address[] shareRateDeviationLimitManagers;
        address[] maxValidatorExitRequestsPerReportManagers;
        address[] maxAccountingExtraDataListItemsCountManagers;
        address[] maxNodeOperatorsPerExtraDataItemCountManagers;
        address[] requestTimestampMarginManagers;
        address[] maxPositiveTokenRebaseManagers;
    }

    /// @param _lidoLocator address of the LidoLocator instance
    /// @param _admin address to grant DEFAULT_ADMIN_ROLE of the AccessControl contract
    /// @param _limitsList initial values to be set for the limits list
    /// @param _managersRoster list of the address to grant permissions for granular limits management
    constructor(
        address _lidoLocator,
        address _admin,
        LimitsList memory _limitsList,
        ManagersRoster memory _managersRoster
    ) {
        LIDO_LOCATOR = ILidoLocator(_lidoLocator);

        _updateLimits(_limitsList);

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(ALL_LIMITS_MANAGER_ROLE, _managersRoster.allLimitsManagers);
        _grantRole(CHURN_VALIDATORS_PER_DAY_LIMIT_MANGER_ROLE, _managersRoster.churnValidatorsPerDayLimitManagers);
        _grantRole(ONE_OFF_CL_BALANCE_DECREASE_LIMIT_MANAGER_ROLE,
                   _managersRoster.oneOffCLBalanceDecreaseLimitManagers);
        _grantRole(ANNUAL_BALANCE_INCREASE_LIMIT_MANAGER_ROLE, _managersRoster.annualBalanceIncreaseLimitManagers);
        _grantRole(MAX_POSITIVE_TOKEN_REBASE_MANAGER_ROLE, _managersRoster.maxPositiveTokenRebaseManagers);
        _grantRole(MAX_VALIDATOR_EXIT_REQUESTS_PER_REPORT_ROLE,
                   _managersRoster.maxValidatorExitRequestsPerReportManagers);
        _grantRole(MAX_ACCOUNTING_EXTRA_DATA_LIST_ITEMS_COUNT_ROLE,
                   _managersRoster.maxAccountingExtraDataListItemsCountManagers);
        _grantRole(MAX_NODE_OPERATORS_PER_EXTRA_DATA_ITEM_COUNT_ROLE,
                   _managersRoster.maxNodeOperatorsPerExtraDataItemCountManagers);
        _grantRole(SHARE_RATE_DEVIATION_LIMIT_MANAGER_ROLE, _managersRoster.shareRateDeviationLimitManagers);
        _grantRole(REQUEST_TIMESTAMP_MARGIN_MANAGER_ROLE, _managersRoster.requestTimestampMarginManagers);
    }

    /// @notice returns the address of the LidoLocator
    function getLidoLocator() public view returns (address) {
        return address(LIDO_LOCATOR);
    }

    /// @notice Returns the limits list for the Lido's oracle report sanity checks
    function getOracleReportLimits() public view returns (LimitsList memory) {
        return _limits.unpack();
    }

    /// @notice Returns max positive token rebase value with 1e9 precision:
    ///     e.g.: 1e6 - 0.1%; 1e9 - 100%
    ///     - zero value means uninitialized
    ///     - type(uint64).max means unlimited
    ///
    /// @dev Get max positive rebase allowed per single oracle report token rebase happens on total
    ///     supply adjustment, huge positive rebase can incur oracle report sandwiching.
    ///
    ///     stETH balance for the `account` defined as:
    ///         balanceOf(account) =
    ///             shares[account] * totalPooledEther / totalShares = shares[account] * shareRate
    ///
    ///     Suppose shareRate changes when oracle reports (see `handleOracleReport`)
    ///     which means that token rebase happens:
    ///
    ///         preShareRate = preTotalPooledEther() / preTotalShares()
    ///         postShareRate = postTotalPooledEther() / postTotalShares()
    ///         R = (postShareRate - preShareRate) / preShareRate
    ///
    ///         R > 0 corresponds to the relative positive rebase value (i.e., instant APR)
    ///
    /// NB: The value is not set by default (explicit initialization required),
    ///     the recommended sane values are from 0.05% to 0.1%.
    function getMaxPositiveTokenRebase() public view returns (uint256) {
        return _limits.maxPositiveTokenRebase;
    }

    /// @notice Sets the new values for the limits list
    /// @param _limitsList new limits list
    function setOracleReportLimits(LimitsList memory _limitsList) external onlyRole(ALL_LIMITS_MANAGER_ROLE) {
        _updateLimits(_limitsList);
    }

    /// @notice Sets the new value for the churnValidatorsPerDayLimit
    /// @param _churnValidatorsPerDayLimit new churnValidatorsPerDayLimit value
    function setChurnValidatorsPerDayLimit(uint256 _churnValidatorsPerDayLimit)
        external
        onlyRole(CHURN_VALIDATORS_PER_DAY_LIMIT_MANGER_ROLE)
    {
        _checkLimitValue(_churnValidatorsPerDayLimit, type(uint16).max);
        LimitsList memory limitsList = _limits.unpack();
        limitsList.churnValidatorsPerDayLimit = _churnValidatorsPerDayLimit;
        _updateLimits(limitsList);
    }

    /// @notice Sets the new value for the oneOffCLBalanceDecreaseBPLimit
    /// @param _oneOffCLBalanceDecreaseBPLimit new oneOffCLBalanceDecreaseBPLimit value
    function setOneOffCLBalanceDecreaseBPLimit(uint256 _oneOffCLBalanceDecreaseBPLimit)
        external
        onlyRole(ONE_OFF_CL_BALANCE_DECREASE_LIMIT_MANAGER_ROLE)
    {
        _checkLimitValue(_oneOffCLBalanceDecreaseBPLimit, MAX_BASIS_POINTS);
        LimitsList memory limitsList = _limits.unpack();
        limitsList.oneOffCLBalanceDecreaseBPLimit = _oneOffCLBalanceDecreaseBPLimit;
        _updateLimits(limitsList);
    }

    /// @notice Sets the new value for the annualBalanceIncreaseBPLimit
    /// @param _annualBalanceIncreaseBPLimit new annualBalanceIncreaseBPLimit value
    function setAnnualBalanceIncreaseBPLimit(uint256 _annualBalanceIncreaseBPLimit)
        external
        onlyRole(ANNUAL_BALANCE_INCREASE_LIMIT_MANAGER_ROLE)
    {
        _checkLimitValue(_annualBalanceIncreaseBPLimit, MAX_BASIS_POINTS);
        LimitsList memory limitsList = _limits.unpack();
        limitsList.annualBalanceIncreaseBPLimit = _annualBalanceIncreaseBPLimit;
        _updateLimits(limitsList);
    }

    /// @notice Sets the new value for the simulatedShareRateDeviationBPLimit
    /// @param _simulatedShareRateDeviationBPLimit new simulatedShareRateDeviationBPLimit value
    function setSimulatedShareRateDeviationBPLimit(uint256 _simulatedShareRateDeviationBPLimit)
        external
        onlyRole(SHARE_RATE_DEVIATION_LIMIT_MANAGER_ROLE)
    {
        _checkLimitValue(_simulatedShareRateDeviationBPLimit, MAX_BASIS_POINTS);
        LimitsList memory limitsList = _limits.unpack();
        limitsList.simulatedShareRateDeviationBPLimit = _simulatedShareRateDeviationBPLimit;
        _updateLimits(limitsList);
    }

    /// @notice Sets the new value for the maxValidatorExitRequestsPerReport
    /// @param _maxValidatorExitRequestsPerReport new maxValidatorExitRequestsPerReport value
    function setMaxExitRequestsPerOracleReport(uint256 _maxValidatorExitRequestsPerReport)
        external
        onlyRole(MAX_VALIDATOR_EXIT_REQUESTS_PER_REPORT_ROLE)
    {
        _checkLimitValue(_maxValidatorExitRequestsPerReport, type(uint16).max);
        LimitsList memory limitsList = _limits.unpack();
        limitsList.maxValidatorExitRequestsPerReport = _maxValidatorExitRequestsPerReport;
        _updateLimits(limitsList);
    }

    /// @notice Sets the new value for the requestTimestampMargin
    /// @param _requestTimestampMargin new requestTimestampMargin value
    function setRequestTimestampMargin(uint256 _requestTimestampMargin)
        external
        onlyRole(REQUEST_TIMESTAMP_MARGIN_MANAGER_ROLE)
    {
        _checkLimitValue(_requestTimestampMargin, type(uint64).max);
        LimitsList memory limitsList = _limits.unpack();
        limitsList.requestTimestampMargin = _requestTimestampMargin;
        _updateLimits(limitsList);
    }

    /// @notice Set max positive token rebase allowed per single oracle report token rebase happens
    ///     on total supply adjustment, huge positive rebase can incur oracle report sandwiching.
    ///
    /// @param _maxPositiveTokenRebase max positive token rebase value with 1e9 precision:
    ///     e.g.: 1e6 - 0.1%; 1e9 - 100%
    ///     - passing zero value is prohibited
    ///     - to allow unlimited rebases, pass max uint64, i.e.: type(uint64).max
    function setMaxPositiveTokenRebase(uint256 _maxPositiveTokenRebase)
        external
        onlyRole(MAX_POSITIVE_TOKEN_REBASE_MANAGER_ROLE)
    {
        _checkLimitValue(_maxPositiveTokenRebase, type(uint64).max);
        LimitsList memory limitsList = _limits.unpack();
        limitsList.maxPositiveTokenRebase = _maxPositiveTokenRebase;
        _updateLimits(limitsList);
    }

    /// @notice Sets the new value for the maxAccountingExtraDataListItemsCount
    /// @param _maxAccountingExtraDataListItemsCount new maxAccountingExtraDataListItemsCount value
    function setMaxAccountingExtraDataListItemsCount(uint256 _maxAccountingExtraDataListItemsCount)
        external
        onlyRole(MAX_ACCOUNTING_EXTRA_DATA_LIST_ITEMS_COUNT_ROLE)
    {
        _checkLimitValue(_maxAccountingExtraDataListItemsCount, type(uint16).max);
        LimitsList memory limitsList = _limits.unpack();
        limitsList.maxAccountingExtraDataListItemsCount = _maxAccountingExtraDataListItemsCount;
        _updateLimits(limitsList);
    }

    /// @notice Sets the new value for the max maxNodeOperatorsPerExtraDataItemCount
    /// @param _maxNodeOperatorsPerExtraDataItemCount new maxNodeOperatorsPerExtraDataItemCount value
    function setMaxNodeOperatorsPerExtraDataItemCount(uint256 _maxNodeOperatorsPerExtraDataItemCount)
        external
        onlyRole(MAX_NODE_OPERATORS_PER_EXTRA_DATA_ITEM_COUNT_ROLE)
    {
        _checkLimitValue(_maxNodeOperatorsPerExtraDataItemCount, type(uint16).max);
        LimitsList memory limitsList = _limits.unpack();
        limitsList.maxNodeOperatorsPerExtraDataItemCount = _maxNodeOperatorsPerExtraDataItemCount;
        _updateLimits(limitsList);
    }

    /// @notice Returns the allowed ETH amount that might be taken from the withdrawal vault and EL
    ///     rewards vault during Lido's oracle report processing
    /// @param _preTotalPooledEther total amount of ETH controlled by the protocol
    /// @param _preTotalShares total amount of minted stETH shares
    /// @param _preCLBalance sum of all Lido validators' balances on the Consensus Layer before the
    ///     current oracle report
    /// @param _postCLBalance sum of all Lido validators' balances on the Consensus Layer after the
    ///     current oracle report
    /// @param _withdrawalVaultBalance withdrawal vault balance on Execution Layer for the report calculation moment
    /// @param _elRewardsVaultBalance elRewards vault balance on Execution Layer for the report calculation moment
    /// @param _sharesRequestedToBurn shares requested to burn through Burner for the report calculation moment
    /// @param _etherToLockForWithdrawals ether to lock on withdrawals queue contract
    /// @param _newSharesToBurnForWithdrawals new shares to burn due to withdrawal request finalization
    /// @return withdrawals ETH amount allowed to be taken from the withdrawals vault
    /// @return elRewards ETH amount allowed to be taken from the EL rewards vault
    /// @return simulatedSharesToBurn simulated amount to be burnt (if no ether locked on withdrawals)
    /// @return sharesToBurn amount to be burnt (accounting for withdrawals finalization)
    function smoothenTokenRebase(
        uint256 _preTotalPooledEther,
        uint256 _preTotalShares,
        uint256 _preCLBalance,
        uint256 _postCLBalance,
        uint256 _withdrawalVaultBalance,
        uint256 _elRewardsVaultBalance,
        uint256 _sharesRequestedToBurn,
        uint256 _etherToLockForWithdrawals,
        uint256 _newSharesToBurnForWithdrawals
    ) external view returns (
        uint256 withdrawals,
        uint256 elRewards,
        uint256 simulatedSharesToBurn,
        uint256 sharesToBurn
    ) {
        TokenRebaseLimiterData memory tokenRebaseLimiter = PositiveTokenRebaseLimiter.initLimiterState(
            getMaxPositiveTokenRebase(),
            _preTotalPooledEther,
            _preTotalShares
        );

        if (_postCLBalance < _preCLBalance) {
            tokenRebaseLimiter.decreaseEther(_preCLBalance - _postCLBalance);
        } else {
            tokenRebaseLimiter.increaseEther(_postCLBalance - _preCLBalance);
        }

        withdrawals = tokenRebaseLimiter.increaseEther(_withdrawalVaultBalance);
        elRewards = tokenRebaseLimiter.increaseEther(_elRewardsVaultBalance);

        // determining the shares to burn limit that would have been
        // if no withdrawals finalized during the report
        // it's used to check later the provided `simulatedShareRate` value
        // after the off-chain calculation via `eth_call` of `Lido.handleOracleReport()`
        // see also step 9 of the `Lido._handleOracleReport()`
        simulatedSharesToBurn = Math256.min(tokenRebaseLimiter.getSharesToBurnLimit(), _sharesRequestedToBurn);

        // remove ether to lock for withdrawals from total pooled ether
        tokenRebaseLimiter.decreaseEther(_etherToLockForWithdrawals);
        // re-evaluate shares to burn after TVL was updated due to withdrawals finalization
        sharesToBurn = Math256.min(
            tokenRebaseLimiter.getSharesToBurnLimit(),
            _newSharesToBurnForWithdrawals + _sharesRequestedToBurn
        );
    }

    /// @notice Applies sanity checks to the accounting params of Lido's oracle report
    /// @param _timeElapsed time elapsed since the previous oracle report
    /// @param _preCLBalance sum of all Lido validators' balances on the Consensus Layer before the
    ///     current oracle report (NB: also include the initial balance of newly appeared validators)
    /// @param _postCLBalance sum of all Lido validators' balances on the Consensus Layer after the
    ///     current oracle report
    /// @param _withdrawalVaultBalance withdrawal vault balance on Execution Layer for the report reference slot
    /// @param _elRewardsVaultBalance el rewards vault balance on Execution Layer for the report reference slot
    /// @param _sharesRequestedToBurn shares requested to burn for the report reference slot
    /// @param _preCLValidators Lido-participating validators on the CL side before the current oracle report
    /// @param _postCLValidators Lido-participating validators on the CL side after the current oracle report
    function checkAccountingOracleReport(
        uint256 _timeElapsed,
        uint256 _preCLBalance,
        uint256 _postCLBalance,
        uint256 _withdrawalVaultBalance,
        uint256 _elRewardsVaultBalance,
        uint256 _sharesRequestedToBurn,
        uint256 _preCLValidators,
        uint256 _postCLValidators
    ) external view {
        LimitsList memory limitsList = _limits.unpack();

        address withdrawalVault = LIDO_LOCATOR.withdrawalVault();
        // 1. Withdrawals vault reported balance
        _checkWithdrawalVaultBalance(withdrawalVault.balance, _withdrawalVaultBalance);

        address elRewardsVault = LIDO_LOCATOR.elRewardsVault();
        // 2. EL rewards vault reported balance
        _checkELRewardsVaultBalance(elRewardsVault.balance, _elRewardsVaultBalance);

        // 3. Burn requests
        _checkSharesRequestedToBurn(_sharesRequestedToBurn);

        // 4. Consensus Layer one-off balance decrease
        _checkOneOffCLBalanceDecrease(limitsList, _preCLBalance, _postCLBalance + _withdrawalVaultBalance);

        // 5. Consensus Layer annual balances increase
        _checkAnnualBalancesIncrease(limitsList, _preCLBalance, _postCLBalance, _timeElapsed);

        // 6. Appeared validators increase
        if (_postCLValidators > _preCLValidators) {
            _checkValidatorsChurnLimit(limitsList, (_postCLValidators - _preCLValidators), _timeElapsed);
        }
    }

    /// @notice Applies sanity checks to the number of validator exit requests supplied to ValidatorExitBusOracle
    /// @param _exitRequestsCount Number of validator exit requests supplied per oracle report
    function checkExitBusOracleReport(uint256 _exitRequestsCount)
        external
        view
    {
        uint256 limit = _limits.unpack().maxValidatorExitRequestsPerReport;
        if (_exitRequestsCount > limit) {
            revert IncorrectNumberOfExitRequestsPerReport(limit);
        }
    }

    /// @notice Check rate of exited validators per day
    /// @param _exitedValidatorsCount Number of validator exit requests supplied per oracle report
    function checkExitedValidatorsRatePerDay(uint256 _exitedValidatorsCount)
        external
        view
    {
        uint256 limit = _limits.unpack().churnValidatorsPerDayLimit;
        if (_exitedValidatorsCount > limit) {
            revert ExitedValidatorsLimitExceeded(limit, _exitedValidatorsCount);
        }
    }

    /// @notice Check number of node operators reported per extra data item in accounting oracle
    /// @param _itemIndex Index of item in extra data
    /// @param _nodeOperatorsCount Number of validator exit requests supplied per oracle report
    /// @dev Checks against the same limit as used in checkAccountingExtraDataListItemsCount
    function checkNodeOperatorsPerExtraDataItemCount(uint256 _itemIndex, uint256 _nodeOperatorsCount)
        external
        view
    {
        uint256 limit = _limits.unpack().maxNodeOperatorsPerExtraDataItemCount;
        if (_nodeOperatorsCount > limit) {
            revert TooManyNodeOpsPerExtraDataItem(_itemIndex, _nodeOperatorsCount);
        }
    }

    /// @notice Check max accounting extra data list items count
    /// @param _extraDataListItemsCount Number of validator exit requests supplied per oracle report
    function checkAccountingExtraDataListItemsCount(uint256 _extraDataListItemsCount)
        external
        view
    {
        uint256 limit = _limits.unpack().maxAccountingExtraDataListItemsCount;
        if (_extraDataListItemsCount > limit) {
            revert MaxAccountingExtraDataItemsCountExceeded(limit, _extraDataListItemsCount);
        }
    }

    /// @notice Applies sanity checks to the withdrawal requests finalization
    /// @param _lastFinalizableRequestId last finalizable withdrawal request id
    /// @param _reportTimestamp timestamp when the originated oracle report was submitted
    function checkWithdrawalQueueOracleReport(
        uint256 _lastFinalizableRequestId,
        uint256 _reportTimestamp
    )
        external
        view
    {
        LimitsList memory limitsList = _limits.unpack();
        address withdrawalQueue = LIDO_LOCATOR.withdrawalQueue();

        _checkLastFinalizableId(limitsList, withdrawalQueue, _lastFinalizableRequestId, _reportTimestamp);
    }

    /// @notice Applies sanity checks to the simulated share rate for withdrawal requests finalization
    /// @param _postTotalPooledEther total pooled ether after report applied
    /// @param _postTotalShares total shares after report applied
    /// @param _etherLockedOnWithdrawalQueue ether locked on withdrawal queue for the current oracle report
    /// @param _sharesBurntDueToWithdrawals shares burnt due to withdrawals finalization
    /// @param _simulatedShareRate share rate provided with the oracle report (simulated via off-chain "eth_call")
    function checkSimulatedShareRate(
        uint256 _postTotalPooledEther,
        uint256 _postTotalShares,
        uint256 _etherLockedOnWithdrawalQueue,
        uint256 _sharesBurntDueToWithdrawals,
        uint256 _simulatedShareRate
    ) external view {
        LimitsList memory limitsList = _limits.unpack();

        // Pretending that withdrawals were not processed
        // virtually return locked ether back to `_postTotalPooledEther`
        // virtually return burnt just finalized withdrawals shares back to `_postTotalShares`
        _checkSimulatedShareRate(
            limitsList,
            _postTotalPooledEther + _etherLockedOnWithdrawalQueue,
            _postTotalShares + _sharesBurntDueToWithdrawals,
            _simulatedShareRate
        );
    }

    function _checkWithdrawalVaultBalance(
        uint256 _actualWithdrawalVaultBalance,
        uint256 _reportedWithdrawalVaultBalance
    ) internal pure {
        if (_reportedWithdrawalVaultBalance > _actualWithdrawalVaultBalance) {
            revert IncorrectWithdrawalsVaultBalance(_actualWithdrawalVaultBalance);
        }
    }

    function _checkELRewardsVaultBalance(
        uint256 _actualELRewardsVaultBalance,
        uint256 _reportedELRewardsVaultBalance
    ) internal pure {
        if (_reportedELRewardsVaultBalance > _actualELRewardsVaultBalance) {
            revert IncorrectELRewardsVaultBalance(_actualELRewardsVaultBalance);
        }
    }

    function _checkSharesRequestedToBurn(uint256 _sharesRequestedToBurn) internal view {
        (uint256 coverShares, uint256 nonCoverShares) = IBurner(LIDO_LOCATOR.burner()).getSharesRequestedToBurn();
        uint256 actualSharesToBurn = coverShares + nonCoverShares;
        if (_sharesRequestedToBurn > actualSharesToBurn) {
            revert IncorrectSharesRequestedToBurn(actualSharesToBurn);
        }
    }

    function _checkOneOffCLBalanceDecrease(
        LimitsList memory _limitsList,
        uint256 _preCLBalance,
        uint256 _unifiedPostCLBalance
    ) internal pure {
        if (_preCLBalance <= _unifiedPostCLBalance) return;
        uint256 oneOffCLBalanceDecreaseBP = (MAX_BASIS_POINTS * (_preCLBalance - _unifiedPostCLBalance)) /
            _preCLBalance;
        if (oneOffCLBalanceDecreaseBP > _limitsList.oneOffCLBalanceDecreaseBPLimit) {
            revert IncorrectCLBalanceDecrease(oneOffCLBalanceDecreaseBP);
        }
    }

    function _checkAnnualBalancesIncrease(
        LimitsList memory _limitsList,
        uint256 _preCLBalance,
        uint256 _postCLBalance,
        uint256 _timeElapsed
    ) internal pure {
        // allow zero values for scratch deploy
        // NB: annual increase have to be large enough for scratch deploy
        if (_preCLBalance == 0) {
            _preCLBalance = DEFAULT_CL_BALANCE;
        }

        if (_preCLBalance >= _postCLBalance) return;

        if (_timeElapsed == 0) {
            _timeElapsed = DEFAULT_TIME_ELAPSED;
        }

        uint256 balanceIncrease = _postCLBalance - _preCLBalance;
        uint256 annualBalanceIncrease = ((365 days * MAX_BASIS_POINTS * balanceIncrease) /
            _preCLBalance) /
            _timeElapsed;

        if (annualBalanceIncrease > _limitsList.annualBalanceIncreaseBPLimit) {
            revert IncorrectCLBalanceIncrease(annualBalanceIncrease);
        }
    }

    function _checkValidatorsChurnLimit(
        LimitsList memory _limitsList,
        uint256 _appearedValidators,
        uint256 _timeElapsed
    ) internal pure {
        if (_timeElapsed == 0) {
            _timeElapsed = DEFAULT_TIME_ELAPSED;
        }

        uint256 churnLimit = (_limitsList.churnValidatorsPerDayLimit * _timeElapsed) / SECONDS_PER_DAY;

        if (_appearedValidators > churnLimit) revert IncorrectAppearedValidators(_appearedValidators);
    }

    function _checkLastFinalizableId(
        LimitsList memory _limitsList,
        address _withdrawalQueue,
        uint256 _lastFinalizableId,
        uint256 _reportTimestamp
    ) internal view {
        uint256[] memory requestIds = new uint256[](1);
        requestIds[0] = _lastFinalizableId;

        IWithdrawalQueue.WithdrawalRequestStatus[] memory statuses = IWithdrawalQueue(_withdrawalQueue)
            .getWithdrawalStatus(requestIds);
        if (_reportTimestamp < statuses[0].timestamp + _limitsList.requestTimestampMargin)
            revert IncorrectRequestFinalization(statuses[0].timestamp);
    }

    function _checkSimulatedShareRate(
        LimitsList memory _limitsList,
        uint256 _noWithdrawalsPostTotalPooledEther,
        uint256 _noWithdrawalsPostTotalShares,
        uint256 _simulatedShareRate
    ) internal pure {
        uint256 actualShareRate = (
            _noWithdrawalsPostTotalPooledEther * SHARE_RATE_PRECISION_E27
        ) / _noWithdrawalsPostTotalShares;

        if (actualShareRate == 0) {
            // can't finalize anything if the actual share rate is zero
            revert ActualShareRateIsZero();
        }

        if (_simulatedShareRate > actualShareRate) {
            // the simulated share rate can't be higher than the actual one
            // invariant: rounding only can lower the simulated share rate
            revert TooHighSimulatedShareRate(_simulatedShareRate, actualShareRate);
        }

        uint256 simulatedShareDiff = actualShareRate - _simulatedShareRate;
        uint256 simulatedShareDeviation = (MAX_BASIS_POINTS * simulatedShareDiff) / actualShareRate;

        if (simulatedShareDeviation > _limitsList.simulatedShareRateDeviationBPLimit) {
            // the simulated share rate can be lower than the actual one due to rounding
            // e.g., new user-submitted ether & minted `stETH`
            // between an oracle reference slot and an actual accounting report delivery
            revert TooLowSimulatedShareRate(_simulatedShareRate, actualShareRate);
        }
    }

    function _grantRole(bytes32 _role, address[] memory _accounts) internal {
        for (uint256 i = 0; i < _accounts.length; ++i) {
            _grantRole(_role, _accounts[i]);
        }
    }

    function _updateLimits(LimitsList memory _newLimitsList) internal {
        LimitsList memory _oldLimitsList = _limits.unpack();
        if (_oldLimitsList.churnValidatorsPerDayLimit != _newLimitsList.churnValidatorsPerDayLimit) {
            _checkLimitValue(_newLimitsList.churnValidatorsPerDayLimit, type(uint16).max);
            emit ChurnValidatorsPerDayLimitSet(_newLimitsList.churnValidatorsPerDayLimit);
        }
        if (_oldLimitsList.oneOffCLBalanceDecreaseBPLimit != _newLimitsList.oneOffCLBalanceDecreaseBPLimit) {
            _checkLimitValue(_newLimitsList.oneOffCLBalanceDecreaseBPLimit, MAX_BASIS_POINTS);
            emit OneOffCLBalanceDecreaseBPLimitSet(_newLimitsList.oneOffCLBalanceDecreaseBPLimit);
        }
        if (_oldLimitsList.annualBalanceIncreaseBPLimit != _newLimitsList.annualBalanceIncreaseBPLimit) {
            _checkLimitValue(_newLimitsList.annualBalanceIncreaseBPLimit, MAX_BASIS_POINTS);
            emit AnnualBalanceIncreaseBPLimitSet(_newLimitsList.annualBalanceIncreaseBPLimit);
        }
        if (_oldLimitsList.simulatedShareRateDeviationBPLimit != _newLimitsList.simulatedShareRateDeviationBPLimit) {
            _checkLimitValue(_newLimitsList.simulatedShareRateDeviationBPLimit, MAX_BASIS_POINTS);
            emit SimulatedShareRateDeviationBPLimitSet(_newLimitsList.simulatedShareRateDeviationBPLimit);
        }
        if (_oldLimitsList.maxValidatorExitRequestsPerReport != _newLimitsList.maxValidatorExitRequestsPerReport) {
            _checkLimitValue(_newLimitsList.maxValidatorExitRequestsPerReport, type(uint16).max);
            emit MaxValidatorExitRequestsPerReportSet(_newLimitsList.maxValidatorExitRequestsPerReport);
        }
        if (_oldLimitsList.maxAccountingExtraDataListItemsCount != _newLimitsList.maxAccountingExtraDataListItemsCount) {
            _checkLimitValue(_newLimitsList.maxAccountingExtraDataListItemsCount, type(uint16).max);
            emit MaxAccountingExtraDataListItemsCountSet(_newLimitsList.maxAccountingExtraDataListItemsCount);
        }
        if (_oldLimitsList.maxNodeOperatorsPerExtraDataItemCount != _newLimitsList.maxNodeOperatorsPerExtraDataItemCount) {
            _checkLimitValue(_newLimitsList.maxNodeOperatorsPerExtraDataItemCount, type(uint16).max);
            emit MaxNodeOperatorsPerExtraDataItemCountSet(_newLimitsList.maxNodeOperatorsPerExtraDataItemCount);
        }
        if (_oldLimitsList.requestTimestampMargin != _newLimitsList.requestTimestampMargin) {
            _checkLimitValue(_newLimitsList.requestTimestampMargin, type(uint64).max);
            emit RequestTimestampMarginSet(_newLimitsList.requestTimestampMargin);
        }
        if (_oldLimitsList.maxPositiveTokenRebase != _newLimitsList.maxPositiveTokenRebase) {
            _checkLimitValue(_newLimitsList.maxPositiveTokenRebase, type(uint64).max);
            emit MaxPositiveTokenRebaseSet(_newLimitsList.maxPositiveTokenRebase);
        }
        _limits = _newLimitsList.pack();
    }

    function _checkLimitValue(uint256 _value, uint256 _maxAllowedValue) internal pure {
        if (_value > _maxAllowedValue) {
            revert IncorrectLimitValue(_value, _maxAllowedValue);
        }
    }

    event ChurnValidatorsPerDayLimitSet(uint256 churnValidatorsPerDayLimit);
    event OneOffCLBalanceDecreaseBPLimitSet(uint256 oneOffCLBalanceDecreaseBPLimit);
    event AnnualBalanceIncreaseBPLimitSet(uint256 annualBalanceIncreaseBPLimit);
    event SimulatedShareRateDeviationBPLimitSet(uint256 simulatedShareRateDeviationBPLimit);
    event MaxPositiveTokenRebaseSet(uint256 maxPositiveTokenRebase);
    event MaxValidatorExitRequestsPerReportSet(uint256 maxValidatorExitRequestsPerReport);
    event MaxAccountingExtraDataListItemsCountSet(uint256 maxAccountingExtraDataListItemsCount);
    event MaxNodeOperatorsPerExtraDataItemCountSet(uint256 maxNodeOperatorsPerExtraDataItemCount);
    event RequestTimestampMarginSet(uint256 requestTimestampMargin);

    error IncorrectLimitValue(uint256 value, uint256 maxAllowedValue);
    error IncorrectWithdrawalsVaultBalance(uint256 actualWithdrawalVaultBalance);
    error IncorrectELRewardsVaultBalance(uint256 actualELRewardsVaultBalance);
    error IncorrectSharesRequestedToBurn(uint256 actualSharesToBurn);
    error IncorrectCLBalanceDecrease(uint256 oneOffCLBalanceDecreaseBP);
    error IncorrectCLBalanceIncrease(uint256 annualBalanceDiff);
    error IncorrectAppearedValidators(uint256 churnLimit);
    error IncorrectNumberOfExitRequestsPerReport(uint256 maxRequestsCount);
    error IncorrectExitedValidators(uint256 churnLimit);
    error IncorrectRequestFinalization(uint256 requestCreationBlock);
    error ActualShareRateIsZero();
    error TooHighSimulatedShareRate(uint256 simulatedShareRate, uint256 actualShareRate);
    error TooLowSimulatedShareRate(uint256 simulatedShareRate, uint256 actualShareRate);
    error MaxAccountingExtraDataItemsCountExceeded(uint256 maxItemsCount, uint256 receivedItemsCount);
    error ExitedValidatorsLimitExceeded(uint256 limitPerDay, uint256 exitedPerDay);
    error TooManyNodeOpsPerExtraDataItem(uint256 itemIndex, uint256 nodeOpsCount);
}

library LimitsListPacker {
    function pack(LimitsList memory _limitsList) internal pure returns (LimitsListPacked memory res) {
        res.churnValidatorsPerDayLimit = SafeCast.toUint16(_limitsList.churnValidatorsPerDayLimit);
        res.oneOffCLBalanceDecreaseBPLimit = _toBasisPoints(_limitsList.oneOffCLBalanceDecreaseBPLimit);
        res.annualBalanceIncreaseBPLimit = _toBasisPoints(_limitsList.annualBalanceIncreaseBPLimit);
        res.simulatedShareRateDeviationBPLimit = _toBasisPoints(_limitsList.simulatedShareRateDeviationBPLimit);
        res.requestTimestampMargin = SafeCast.toUint64(_limitsList.requestTimestampMargin);
        res.maxPositiveTokenRebase = SafeCast.toUint64(_limitsList.maxPositiveTokenRebase);
        res.maxValidatorExitRequestsPerReport = SafeCast.toUint16(_limitsList.maxValidatorExitRequestsPerReport);
        res.maxAccountingExtraDataListItemsCount = SafeCast.toUint16(_limitsList.maxAccountingExtraDataListItemsCount);
        res.maxNodeOperatorsPerExtraDataItemCount = SafeCast.toUint16(_limitsList.maxNodeOperatorsPerExtraDataItemCount);
    }

    function _toBasisPoints(uint256 _value) private pure returns (uint16) {
        require(_value <= MAX_BASIS_POINTS, "BASIS_POINTS_OVERFLOW");
        return uint16(_value);
    }
}

library LimitsListUnpacker {
    function unpack(LimitsListPacked memory _limitsList) internal pure returns (LimitsList memory res) {
        res.churnValidatorsPerDayLimit = _limitsList.churnValidatorsPerDayLimit;
        res.oneOffCLBalanceDecreaseBPLimit = _limitsList.oneOffCLBalanceDecreaseBPLimit;
        res.annualBalanceIncreaseBPLimit = _limitsList.annualBalanceIncreaseBPLimit;
        res.simulatedShareRateDeviationBPLimit = _limitsList.simulatedShareRateDeviationBPLimit;
        res.requestTimestampMargin = _limitsList.requestTimestampMargin;
        res.maxPositiveTokenRebase = _limitsList.maxPositiveTokenRebase;
        res.maxValidatorExitRequestsPerReport = _limitsList.maxValidatorExitRequestsPerReport;
        res.maxAccountingExtraDataListItemsCount = _limitsList.maxAccountingExtraDataListItemsCount;
        res.maxNodeOperatorsPerExtraDataItemCount = _limitsList.maxNodeOperatorsPerExtraDataItemCount;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)
//
// A modified AccessControl contract using unstructured storage. Copied from tree:
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/6bd6b76/contracts/access
//
/* See contracts/COMPILERS.md */
pragma solidity 0.8.9;

import "@openzeppelin/contracts-v4.4/access/IAccessControl.sol";
import "@openzeppelin/contracts-v4.4/utils/Context.sol";
import "@openzeppelin/contracts-v4.4/utils/Strings.sol";
import "@openzeppelin/contracts-v4.4/utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    /// @dev Storage slot: mapping(bytes32 => RoleData) _roles
    bytes32 private constant ROLES_POSITION = keccak256("openzeppelin.AccessControl._roles");

    function _storageRoles() private pure returns (mapping(bytes32 => RoleData) storage _roles) {
        bytes32 position = ROLES_POSITION;
        assembly { _roles.slot := position }
    }

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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _storageRoles()[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _storageRoles()[role].adminRole;
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
        _storageRoles()[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _storageRoles()[role].members[account] = true;
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
            _storageRoles()[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControlEnumerable.sol)
//
// A modified AccessControlEnumerable contract using unstructured storage. Copied from tree:
// https://github.com/OpenZeppelin/openzeppelin-contracts/tree/6bd6b76/contracts/access
//
/* See contracts/COMPILERS.md */
pragma solidity 0.8.9;

import "@openzeppelin/contracts-v4.4/access/IAccessControlEnumerable.sol";
import "@openzeppelin/contracts-v4.4/utils/structs/EnumerableSet.sol";

import "./AccessControl.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @dev Storage slot: mapping(bytes32 => EnumerableSet.AddressSet) _roleMembers
    bytes32 private constant ROLE_MEMBERS_POSITION = keccak256("openzeppelin.AccessControlEnumerable._roleMembers");

    function _storageRoleMembers() private pure returns (
        mapping(bytes32 => EnumerableSet.AddressSet) storage _roleMembers
    ) {
        bytes32 position = ROLE_MEMBERS_POSITION;
        assembly { _roleMembers.slot := position }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _storageRoleMembers()[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _storageRoleMembers()[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _storageRoleMembers()[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _storageRoleMembers()[role].remove(account);
    }
}

// SPDX-FileCopyrightText: 2023 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

// See contracts/COMPILERS.md
// solhint-disable-next-line
pragma solidity >=0.4.24 <0.9.0;

interface IBurner {
    /**
     * Commit cover/non-cover burning requests and logs cover/non-cover shares amount just burnt.
     *
     * NB: The real burn enactment to be invoked after the call (via internal Lido._burnShares())
     */
    function commitSharesToBurn(uint256 _stETHSharesToBurn) external;

    /**
     * Request burn shares
     */
    function requestBurnShares(address _from, uint256 _sharesAmount) external;

    /**
      * Returns the current amount of shares locked on the contract to be burnt.
      */
    function getSharesRequestedToBurn() external view returns (uint256 coverShares, uint256 nonCoverShares);

    /**
      * Returns the total cover shares ever burnt.
      */
    function getCoverSharesBurnt() external view returns (uint256);

    /**
      * Returns the total non-cover shares ever burnt.
      */
    function getNonCoverSharesBurnt() external view returns (uint256);
}

// SPDX-FileCopyrightText: 2023 Lido <[email protected]>
// SPDX-License-Identifier: GPL-3.0

// See contracts/COMPILERS.md
// solhint-disable-next-line
pragma solidity >=0.4.24 <0.9.0;

interface ILidoLocator {
    function accountingOracle() external view returns(address);
    function depositSecurityModule() external view returns(address);
    function elRewardsVault() external view returns(address);
    function legacyOracle() external view returns(address);
    function lido() external view returns(address);
    function oracleReportSanityChecker() external view returns(address);
    function burner() external view returns(address);
    function stakingRouter() external view returns(address);
    function treasury() external view returns(address);
    function validatorsExitBusOracle() external view returns(address);
    function withdrawalQueue() external view returns(address);
    function withdrawalVault() external view returns(address);
    function postTokenRebaseReceiver() external view returns(address);
    function oracleDaemonConfig() external view returns(address);
    function coreComponents() external view returns(
        address elRewardsVault,
        address oracleReportSanityChecker,
        address stakingRouter,
        address treasury,
        address withdrawalQueue,
        address withdrawalVault
    );
    function oracleReportComponentsForLido() external view returns(
        address accountingOracle,
        address elRewardsVault,
        address oracleReportSanityChecker,
        address burner,
        address withdrawalQueue,
        address withdrawalVault,
        address postTokenRebaseReceiver
    );
}

// SPDX-FileCopyrightText: 2023 Lido <[email protected]>
// SPDX-License-Identifier: MIT

// Copied from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/0457042d93d9dfd760dbaa06a4d2f1216fdbe297/contracts/utils/math/Math.sol

// See contracts/COMPILERS.md
// solhint-disable-next-line
pragma solidity >=0.4.24 <0.9.0;

library Math256 {
    /// @dev Returns the absolute unsigned value of a signed value.
    function abs(int256 n) internal pure returns (uint256) {
        return uint256(n >= 0 ? n : -n);
    }

    /// @dev Returns the largest of two numbers.
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /// @dev Returns the smallest of two numbers.
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @dev Returns the largest of two numbers.
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /// @dev Returns the smallest of two numbers.
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /// @dev Returns the ceiling of the division of two numbers.
    ///
    /// This differs from standard division with `/` in that it rounds up instead
    /// of rounding down.
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }
}