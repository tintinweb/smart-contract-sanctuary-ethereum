// Sources flattened with hardhat v2.8.0 https://hardhat.org

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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




/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}




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

    function toString(bytes32 value) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && value[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && value[i] != 0; i++) {
            bytesArray[i] = value[i];
        }
        return string(bytesArray);
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




/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via _msgSender() and msg.data, they should not be accessed in such a direct
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



/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}




/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
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




/**
 * @dev Interface of a contract containing identifier for Root role.
 */
interface IRoleContainerRoot {
    /**
    * @dev Returns Root role identifier.
    */
    function ROOT_ROLE() external view returns (bytes32);
}




/**
 * @dev Interface of a contract containing identifier for Admin role.
 */
interface IRoleContainerAdmin {
    /**
    * @dev Returns Admin role identifier.
    */
    function ADMIN_ROLE() external view returns (bytes32);
}



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
 *     require(hasRole(MY_ROLE, _msgSender()));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 */
abstract contract AccessControl is Context, ERC165Storage, IAccessControl, IRoleContainerAdmin {
    /**
    * @dev Root Admin role identifier.
    */
    bytes32 public constant ROOT_ROLE = "Root";

    /**
    * @dev Admin role identifier.
    */
    bytes32 public constant ADMIN_ROLE = "Admin";

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    constructor() {
        _registerInterface(type(IAccessControl).interfaceId);

        _setupRole(ROOT_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toString(role)
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
        _setRoleAdmin(role, ROOT_ROLE);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}




/**
 * @dev Interface for contract which allows to pause and unpause the contract.
 */
interface IPausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);
    
    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() external view returns (bool);

    /**
    * @dev Pauses the contract.
    */
    function pause() external;

    /**
    * @dev Unpauses the contract.
    */
    function unpause() external;
}




/**
 * @dev Interface of a contract containing identifier for Pauser role.
 */
interface IRoleContainerPauser {
    /**
    * @dev Returns Pauser role identifier.
    */
    function PAUSER_ROLE() external view returns (bytes32);
}



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is AccessControl, IPausable, IRoleContainerPauser {
    /**
    * @dev Pauser role identifier.
    */
    bytes32 public constant PAUSER_ROLE = "Pauser";

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _registerInterface(type(IPausable).interfaceId);

        _setupRole(PAUSER_ROLE, _msgSender());

        _paused = true;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
   
    /**
    * @dev This function is called before pausing the contract.
    * Override to add custom pausing conditions or actions.
    */
    function _beforePause() internal virtual {
    }

    /**
    * @dev This function is called before unpausing the contract.
    * Override to add custom unpausing conditions or actions.
    */
    function _beforeUnpause() internal virtual {
    }

    /**
    * @dev Pauses the contract.
    * Requirements:
    * - Caller must have 'PAUSER_ROLE';
    * - Contract must be unpaused.
    */
    function pause() external onlyRole(PAUSER_ROLE) whenNotPaused {
        _beforePause();
        _pause();
    }

    /**
    * @dev Unpauses the contract.
    * Requirements:
    * - Caller must have 'PAUSER_ROLE';
    * - Contract must be unpaused;
    */
    function unpause() external onlyRole(PAUSER_ROLE) whenPaused {
        _beforeUnpause();
        _unpause();
    }
}




/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}



/**
 * @dev Interface of extension of {IERC165} that allows to handle receipts on receiving {IERC1155} assets.
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. _msgSender())
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. _msgSender())
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}



/**
 * @dev Extension of {ERC165} that allows to handle receipts on receiving {ERC1155} assets.
 */
abstract contract ERC1155Receiver is ERC165Storage, IERC1155Receiver {

    constructor() {
        _registerInterface(type(IERC1155Receiver).interfaceId);
    }
}



/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}



/**
 * @dev Contract module which allows to perform basic checks on arguments.
 */
abstract contract RequirementsChecker {
    uint256 internal constant inf = type(uint256).max;

    function _requireNonZeroAddress(address _address, string memory paramName) internal pure {
        require(_address != address(0), string(abi.encodePacked(paramName, ": cannot use zero address")));
    }

    function _requireArrayData(address[] memory _array, string memory paramName) internal pure {
        require(_array.length != 0, string(abi.encodePacked(paramName, ": cannot be empty")));
    }

    function _requireArrayData(uint256[] memory _array, string memory paramName) internal pure {
        require(_array.length != 0, string(abi.encodePacked(paramName, ": cannot be empty")));
    }

    function _requireStringData(string memory _string, string memory paramName) internal pure {
        require(bytes(_string).length != 0, string(abi.encodePacked(paramName, ": cannot be empty")));
    }

    function _requireSameLengthArrays(address[] memory _array1, uint256[] memory _array2, string memory paramName1, string memory paramName2) internal pure {
        require(_array1.length == _array2.length, string(abi.encodePacked(paramName1, ", ", paramName2, ": lengths must be equal")));
    }

    function _requireInRange(uint256 value, uint256 minValue, uint256 maxValue, string memory paramName) internal pure {
        string memory maxValueString = maxValue == inf ? "inf" : Strings.toString(maxValue);
        require(minValue <= value && (maxValue == inf || value <= maxValue), string(abi.encodePacked(paramName, ": must be in [", Strings.toString(minValue), "..", maxValueString, "] range")));
    }
}




/**
 * @dev Interface of a contract module which allows authorized account to withdraw assets in case of emergency.
 */
interface IEmergencyWithdrawer {
    /**
     * @dev Emitted when emergency withdrawal occurs.
     */
    event EmergencyWithdrawn(address asset, uint256[] ids, address to, string reason);

    /**
    * @dev Withdraws all balance of certain asset.
    * Emits a {EmergencyWithdrawn} event.
    */
    function emergencyWithdrawal(address asset, uint256[] calldata ids, address to, string calldata reason) external;
}




/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}



/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transfered from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}



/**
 * @dev Contract module which allows authorized account to withdraw assets in case of emergency.
 */
abstract contract EmergencyWithdrawer is AccessControl, RequirementsChecker, IEmergencyWithdrawer {

    constructor () {
        _registerInterface(type(IEmergencyWithdrawer).interfaceId);
    }

    /**
    * @dev Withdraws all balance of certain asset.
    * @param asset Address of asset to withdraw.
    * @param ids Array of NFT ids to withdraw - if it is empty, withdrawing asset is considered to be IERC20, otherwise - IERC1155.
    * @param to Address where to transfer specified asset.
    * Requirements:
    * - Caller must have 'ADMIN_ROLE';
    * - 'asset' address must be non-zero;
    * - 'to' address must be non-zero;
    * - 'reason' must be provided.
    * Emits {EmergencyWithdrawn} event.
    */
    function emergencyWithdrawal(address asset, uint256[] calldata ids, address to, string calldata reason) external onlyRole(ADMIN_ROLE) {
        _requireNonZeroAddress(asset, "asset");
        _requireNonZeroAddress(to, "to");
        _requireStringData(reason, "reason");

        if (ids.length == 0) {
            IERC20 token = IERC20(asset);
            token.transfer(to, token.balanceOf(address(this)));
        }
        else {
            IERC1155 token = IERC1155(asset);

            address[] memory addresses = new address[](ids.length);
            for(uint256 i = 0; i < ids.length; i++)
                addresses[i] = address(this); // actually only this one, but multiple times to call balanceOfBatch

            uint256[] memory balances = token.balanceOfBatch(addresses, ids);
            token.safeBatchTransferFrom(address(this), to, ids, balances, "");
        }

        emit EmergencyWithdrawn(asset, ids, to, reason);
    }
}



/**
 * @dev Stub interface for FearWolf contract (we need only one function here).
 */
interface IFearWolfStub {
    /**
    * @dev Draws a random wolf from available (not owned yet) and sets initial owner.
    */
    function assignRandomWolf(address initialOwner) external;

    function resetAll() external;
}

/**
 * @dev Contract for distribution FEAR Wolf NFT within presale and public sale phases.
 */
contract FearWolfDistributor is AccessControl, Pausable, ReentrancyGuard, ERC1155Holder, EmergencyWithdrawer {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    /**
    * @dev Emitted when users's stake is changed by staking or unstaking.
    */
    event StakeUpdated(address indexed account, uint256 stake);
    /**
    * @dev Emitted when stake amount to reserve 1 FEAR Wolf on presale is changed.
    */
    event StakePerWolfChanged(uint256 stakePerWolf);
    /**
    * @dev Emitted when the stake lock period is changed.
    */
    event StakeLockPeriodChanged(uint16 stakeLockPeriod);
    /**
    * @dev Emitted when number of wolves an account can reserve on presale is changed.
    */
    event PresaleWolvesPerAccountLimitChanged(uint256 presaleWolvesPerAccountLimit);
    /**
    * @dev Emitted when presale/sale start timestamps are changed.
    */
    event SaleStartChanged(uint256 presaleStart, uint256 saleStart);
    /**
    * @dev Emitted when prices are changed.
    */
    event PricesChanged(uint256 presalePrice, uint256 salePriceMax, uint256 salePriceMin);
    /**
    * @dev Emitted when dutch auction parameters are changed.
    */
    event DutchAuctionParametersChanged(uint256 dutchAuctionStep, uint256 dutchAuctionStepDuration);
    /**
    * @dev Emitted when wolves count is changed.
    */
    event WolvesCountChanged(uint256 presaleWolvesCount, uint256 saleWolvesCount, uint256 giftWolvesCount);
    /**
    * @dev Emitted when FEAR Wolf contract address is set.
    */
    event FearWolfContractAddressSet(address fearWolfContractAddress);
    /**
    * @dev Emitted when FEAR Wolf is bought (used for both presale claiming, public sale direct buying and gifting).
    */
    event WolfBought(address indexed account, uint256 price);


    /**
    * @dev Amount of FEAR must be staked on presale phase to reserve 1 Fear Wolf.
    */
    uint256 public stakePerWolf = 500 * 10 ** 18;

    /**
    * @dev Count of days since staking before unstaking is possible.
    */
    uint256 public stakeLockPeriod = 30;

    /**
    * @dev Number of wolves an account can reserve on presale.
    */
    uint256 public presaleWolvesPerAccountLimit = 2;

    // Timestamps
    uint256 public presaleStart = 1646132400; // 2022-Mar-01 11:00:00 UTC
    uint256 public saleStart = 1647342000; // 2022-Mar-15 11:00:00 UTC

    // Prices in ETH
    uint256 public presalePrice = 1 * 10 ** 17; // 0.10 ETH
    uint256 public salePriceMax = 2 * 10 ** 17; // 0.20 ETH
    uint256 public salePriceMin = 18 * 10 ** 16; // 0.18 ETH

    // Dutch Auction - 0.001 ETH price drop every 2 hours, 40 hours totally
    uint256 public dutchAuctionStep = 1 * 10 ** 15;
    uint256 public dutchAuctionStepDuration = 2 hours;

    // Wolves Counts
    uint256 private presaleWolvesCount = 3960;
    uint256 private saleWolvesCount = 2640;
    uint256 private giftWolvesCount = 66;

    // FIXME: FOR DEBUG PURPOSES ONLY!!! DO NOT INCLUDE IN REAL CONTRACT
    bool public DEBUG_SALE_ACTIVE = false;
    // FIXME ^^^^^^^

    /**
    * @dev FearWolf contract address.
    */
    address public fearWolfContractAddress;

    IERC20 private fearToken;
    IFearWolfStub private fearWolfContract;

    EnumerableSet.AddressSet private fearStakers;
    EnumerableSet.AddressSet private fearWolvesReservers;

    // address => staked amount
    mapping (address => uint256) private stakes;

    // address => stake lock release date
    mapping (address => uint256) private stakeLockExpiration;

    // address => wolves reserved
    mapping (address => uint256) private wolvesReserved;

    // address => true for whitelisted without staking
    mapping (address => bool) private whitelistedWithoutStaking;


    constructor(address fearTokenAddress) {
        fearToken = IERC20(fearTokenAddress);
    }

    function _beforeUnpause() internal view virtual override {
        require(fearWolfContractAddress != address(0), "FEAR Wolf main contract must be set before unpausing");
    }

    function _buyWolf(uint256 wolvesCount, uint256 price) private {
        address caller = _msgSender();

        if (presaleWolvesCount > 0) {
            // moving any wolves left after presale to public sale
            saleWolvesCount += presaleWolvesCount;
            presaleWolvesCount = 0;
        }
        saleWolvesCount -= wolvesCount;

        for (uint i = 0; i < wolvesCount; i++) {
            fearWolfContract.assignRandomWolf(caller);
            emit WolfBought(caller, price);
        }
    }

    /**
    * @dev Returns stake amount of the caller.
    * @return Amount of FEAR the caller has staked in this contract.
    */
    function getMyStakeAmount() external view returns (uint256) {
        return stakes[_msgSender()];
    }

    /**
    * @dev Returns a timestamp of stake lock expiration for the caller.
    * @return UTC timestamp.
    */
    function getMyStakeLockExpiration() external view returns (uint256) {
        return stakeLockExpiration[_msgSender()];
    }

    /**
    * @dev Returns number of FEAR Wolves reserved for the caller.
    * @return Number of FEAR Wolves.
    */
    function getMyNumberOfWolvesReserved() external view returns (uint256) {
        return wolvesReserved[_msgSender()];
    }

    /**
    * @dev Returns current FEAR Wolf price in ETH for public sale.
    * @return Amount of ETH.
    */
    function getCurrentPrice() public view returns (uint256) {
        if (DEBUG_SALE_ACTIVE)
            return salePriceMax;

        if (block.timestamp < saleStart)
            return 0;

        uint256 stepsCount = (block.timestamp - saleStart) / dutchAuctionStepDuration;
        if (stepsCount < (salePriceMax - salePriceMin) / dutchAuctionStep)
            return salePriceMax - stepsCount * dutchAuctionStep;
        else
            return salePriceMin;
    }

    /**
    * @dev Returns number of FEAR Wolves left available for reservation on presale.
    * @return Number of FEAR Wolves.
    */
    function getPresaleWolvesAvailable() external view returns (uint256) {
        if (!DEBUG_SALE_ACTIVE || block.timestamp < saleStart)
            return presaleWolvesCount;
        else
            return 0;
    }

    /**
    * @dev Returns number of FEAR Wolves left available for buying on public sale.
    * @return Number of FEAR Wolves.
    */
    function getPublicSaleWolvesAvailable() external view returns (uint256) {
        if (!DEBUG_SALE_ACTIVE || block.timestamp < saleStart)
            return saleWolvesCount;
        else
            return presaleWolvesCount + saleWolvesCount;
    }

    /**
    * @dev Returns number of FEAR Wolves left available for gifting.
    * @return Number of FEAR Wolves.
    */
    function getGiftWolvesAvailable() external view onlyRole(ADMIN_ROLE) returns (uint256) {
        return giftWolvesCount;
    }


    /**
    * @dev Allows caller to reserve FEAR Wolf by staking FEAR and paying special presale price.
    * @param wolvesCount Number of wolves to reserve.
    * Requirements:
    * - Presale phase must be active;
    * - Caller must be a wallet address and not a contract;
    * - Number of wolves to reserve must be greater than zero;
    * - Number of wolves to reserve must be less or equal to wolves left available for reservation;
    * - The sum of wolves to reserve and wolves reserved by the caller already must be less or equal to maximum allowed number of reserved wolves per account;
    * - Sum of ETH sent must be exactly equal to presale price multiplied by number of wolves to reserve;
    * - If caller is not whitelisted to reserve whithout staking, he must have enough FEAR to stake for requested number of wolves;
    * - If caller is not whitelisted to reserve whithout staking, the contract must be allowed to move enough FEAR from callers account to stake for requested number of woles.
    * Emits {StakeUpdated} event on success.
    */
    function reserveWolf(uint256 wolvesCount) external payable nonReentrant {
        address caller = _msgSender();

        // FIXME: INCLUDE COMMENTED REQUIREMENT TO REAL CONTRACT
        // require(block.timestamp >= presaleStart, "Presale phase is not active yet");
        require(!DEBUG_SALE_ACTIVE || block.timestamp < saleStart, "Presale phase is over");
        require(tx.origin == caller, "Contracts are not allowed");
        require(wolvesCount > 0, "Cannot reserve zero wolves");
        require(presaleWolvesCount >= wolvesCount, "Not enough wolves available for reservation");
        require(wolvesReserved[caller] + wolvesCount <= presaleWolvesPerAccountLimit, "Amount of wolves to reserve exceeds presale wolves per account limit");

        require(msg.value >= wolvesCount * presalePrice, "Insufficient ETH sent");
        require(msg.value <= wolvesCount * presalePrice, "Too much ETH sent");
        
        fearWolvesReservers.add(caller);
        wolvesReserved[caller] += wolvesCount;

        if (!whitelistedWithoutStaking[caller]) {
            uint256 stakeAmount = wolvesCount * stakePerWolf;
            require(fearToken.balanceOf(caller) >= stakeAmount, "You do not have enough FEAR in your wallet to stake");
            require(fearToken.allowance(caller, address(this)) >= stakeAmount, "Contract allowance is less than stake amount");

            stakeLockExpiration[caller] = block.timestamp + stakeLockPeriod * (1 days);
            stakes[caller] = stakes[caller].add(stakeAmount);
            fearStakers.add(caller);
            fearToken.transferFrom(caller, address(this), stakeAmount);
            emit StakeUpdated(caller, stakes[caller]);
        }
    }

    /**
    * @dev Allows caller to unstake FEAR.
    * Requirements:
    * - Caller must have FEAR staked;
    * - Staking lock period must pass after the caller's last staking.
    * Emits {StakeUpdated} event on success.
    */
    function unstake() external nonReentrant {
        address caller = _msgSender();
        uint256 stakeAmount = stakes[caller];

        require(stakeAmount >= 0, "You did not stake anything");
        require(block.timestamp > stakeLockExpiration[caller], "Stake lock period is not over yet");
        
        stakes[caller] = 0;
        fearStakers.remove(caller);

        fearToken.transfer(caller, stakeAmount);
        emit StakeUpdated(caller, 0);
    }

    /**
    * @dev Allows caller to claim reserved FEAR Wolf.
    * Requirements:
    * - Contract must not be paused;
    * - Public sale phase must be active;
    * - Caller must have at least one FEAR wolf reserved and unclaimed.
    * Emits {WolfBought} event on success.
    */
    function claimWolf() external whenNotPaused nonReentrant {
        address caller = _msgSender();
        require(DEBUG_SALE_ACTIVE || block.timestamp >= saleStart, "Public sale is not active yet");
        require(wolvesReserved[caller] > 0, "You don't have any unclaimed wolf");

        wolvesReserved[caller]--;
        fearWolfContract.assignRandomWolf(caller);
        emit WolfBought(caller, presalePrice);
    }

    /**
    * @dev Allows caller to buy FEAR Wolf during public sale phase. This function is called when pure ETH transfer takes place without any calldata.
    * Please note: it is preferable to call buyWolf() function to buy precise amount of wolves.
    * Please note: only integer number of wolves which is covered by ETH sent will be sold.
    * Please note: if wolves available for buing by ETH sent is less than totally wolves left, only number of the wolves left will be sold.
    * Please note: No automatic refund of change takes place.
    * Requirements:
    * - Contract must not be paused;
    * - Public sale phase must be active;
    * - Caller must be a wallet address and not a contract;
    * - Number of wolves left available for buying at public sale must be greater than zero;
    * - Sum of ETH sent must be enough to buy at least 1 wolf;
    * Emits {WolfBought} event on success.
    */
    receive() external payable whenNotPaused nonReentrant {
        address caller = _msgSender();
        require(DEBUG_SALE_ACTIVE || block.timestamp >= saleStart, "Public sale is not active yet");
        require(tx.origin == caller, "Contracts are not allowed");
        require(presaleWolvesCount + saleWolvesCount > 0, "Not enough wolves available for buying");

        uint256 price = getCurrentPrice();
        require(msg.value >= price, "Insufficient ETH sent");
        uint256 wolvesCount = msg.value / price;
        if (wolvesCount < presaleWolvesCount + saleWolvesCount)
            wolvesCount = presaleWolvesCount + saleWolvesCount;

        _buyWolf(wolvesCount, price);
    }

    /**
    * @dev Allows caller to buy FEAR Wolf during public sale phase.
    * @param wolvesCount Number of wolves to buy.
    * Requirements:
    * - Contract must not be paused;
    * - Public sale phase must be active;
    * - Caller must be a wallet address and not a contract;
    * - Number of wolves to buy must be greater than zero;
    * - Number of wolves to buy must be less or equal to wolves left available for buying at public sale;
    * - Sum of ETH sent must be greater or equal to current price (dutch auction takes place) multiplied by number of wolves to buy;
    * Emits {WolfBought} event on success.
    */
    function buyWolf(uint256 wolvesCount) external payable whenNotPaused nonReentrant {
        require(DEBUG_SALE_ACTIVE || block.timestamp >= saleStart, "Public sale is not active yet");
        require(tx.origin == _msgSender(), "Contracts are not allowed");
        require(wolvesCount > 0, "Cannot buy zero wolves");
        require(presaleWolvesCount + saleWolvesCount >= wolvesCount, "Not enough wolves available for buying");

        uint256 price = getCurrentPrice();
        require(msg.value >= wolvesCount * price, "Insufficient ETH sent");

        _buyWolf(wolvesCount, price);
    }


    function setSaleStart(uint256 _presaleStart, uint256 _saleStart) external onlyRole(ADMIN_ROLE) {
        require(block.timestamp < presaleStart || _presaleStart == presaleStart, "Too late, presale is already active");
        require(block.timestamp < saleStart, "Too late, sale is already active");
        require(block.timestamp < _presaleStart && block.timestamp < _saleStart, "Cannot set timestamps to the past");
        require(_presaleStart < _saleStart, "Wrong presale/sale timestamps order");
        presaleStart = _presaleStart;
        saleStart = _saleStart;
        emit SaleStartChanged(presaleStart, saleStart);
    }
    function setPrices(uint256 _presalePrice, uint256 _salePriceMax, uint256 _salePriceMin) external onlyRole(ADMIN_ROLE) {
        require(block.timestamp < presaleStart || _presalePrice == presalePrice, "Too late, presale is already active");
        require(block.timestamp < saleStart, "Too late, sale is already active");
        presalePrice = _presalePrice;
        salePriceMax = _salePriceMax;
        salePriceMin = _salePriceMin;
        emit PricesChanged(presalePrice, salePriceMax, salePriceMin);
    }
    function setStakePerWolf(uint256 _stakePerWolf) external onlyRole(ADMIN_ROLE) {
        require(block.timestamp < presaleStart, "Too late, presale is already active");
        stakePerWolf = _stakePerWolf;
        emit StakePerWolfChanged(stakePerWolf);
    }
    function setStakeLockPeriod(uint16 _days) external onlyRole(ADMIN_ROLE) {
        stakeLockPeriod = _days;
        emit StakeLockPeriodChanged(_days);
    }
    function setPresaleWolvesPerAccountLimit(uint256 _presaleWolvesPerAccountLimit) external onlyRole(ADMIN_ROLE) {
        require(block.timestamp < presaleStart, "Too late, presale is already active");
        presaleWolvesPerAccountLimit = _presaleWolvesPerAccountLimit;
        emit PresaleWolvesPerAccountLimitChanged(presaleWolvesPerAccountLimit);
    }
    function setDutchAuctionParameters(uint256 _dutchAuctionStep, uint256 _dutchAuctionStepDuration) external onlyRole(ADMIN_ROLE) {
        require(block.timestamp < saleStart, "Too late, sale is already active");
        dutchAuctionStep = _dutchAuctionStep;
        dutchAuctionStepDuration = _dutchAuctionStepDuration;
        emit DutchAuctionParametersChanged(dutchAuctionStep, dutchAuctionStepDuration);
    }
    function setWolvesCount(uint256 _presaleWolvesCount, uint256 _saleWolvesCount, uint256 _giftWolvesCount) external onlyRole(ADMIN_ROLE) {
        require(block.timestamp < presaleStart, "Too late, presale is already active");
        presaleWolvesCount = _presaleWolvesCount;
        saleWolvesCount = _saleWolvesCount;
        giftWolvesCount = _giftWolvesCount;
        emit WolvesCountChanged(presaleWolvesCount, saleWolvesCount, giftWolvesCount);
    }

    function releaseAllLocks() external onlyRole(ADMIN_ROLE) {
        for (uint i = 0; i < fearStakers.length(); i++)
            stakeLockExpiration[fearStakers.at(i)] = block.timestamp;
    }

    function setFearWolfContractAddress(address _address) external onlyRole(ADMIN_ROLE) {
        require(_address != address(0), "Cannot set zero address");
        require(block.timestamp < presaleStart, "Cannot change main FEAR Wolf contract address after presale begins");
        fearWolfContractAddress = _address;
        fearWolfContract = IFearWolfStub(fearWolfContractAddress);
        emit FearWolfContractAddressSet(fearWolfContractAddress);
    }

    function giftWolf(address _address) external onlyRole(ADMIN_ROLE) {
        require(giftWolvesCount > 0, "No more wolves left to gift");
        giftWolvesCount--;
        fearWolfContract.assignRandomWolf(_address);
        emit WolfBought(_address, 0);
    }

    function whitelistAddress(address _address) external onlyRole(ADMIN_ROLE) {
        whitelistedWithoutStaking[_address] = true;
        fearStakers.add(_address); // FIXME: REMOVE THIS ADDING IN REAL CONTRACT
    }

    function forceClaimWolf() external onlyRole(ADMIN_ROLE) {
        require(DEBUG_SALE_ACTIVE || block.timestamp >= saleStart, "Public sale is not active yet");
        
        for(uint i = 0; i < fearWolvesReservers.length(); i++) {
            address user = fearWolvesReservers.at(i);

            if (wolvesReserved[user] > 0) {
                for (uint j = 0; j < wolvesReserved[user]; j++) {
                    fearWolfContract.assignRandomWolf(user);
                    emit WolfBought(user, presalePrice);
                }

                wolvesReserved[user] = 0;
            }            
        }
    }


    // FIXME: FUNCTIONS FOR DEBUG PURPOSES!!! DO NOT INCLUDE IN REAL CONTRACT
    function activateSale() external onlyRole(ADMIN_ROLE) {
        DEBUG_SALE_ACTIVE = true;
    }
    function resetAll() external onlyRole(ADMIN_ROLE) {
        DEBUG_SALE_ACTIVE = false;

        stakePerWolf = 500 * 10 ** 18;
        stakeLockPeriod = 30;
        presaleWolvesPerAccountLimit = 2;
        presaleStart = 1646132400; // 2022-Mar-01 11:00:00 UTC
        saleStart = 1647342000; // 2022-Mar-15 11:00:00 UTC
        presalePrice = 1 * 10 ** 17;
        salePriceMax = 2 * 10 ** 17;
        salePriceMin = 18 * 10 ** 16;
        dutchAuctionStep = 1 * 10 ** 15;
        dutchAuctionStepDuration = 2 hours;
        presaleWolvesCount = 3960;
        saleWolvesCount = 2640;
        giftWolvesCount = 66;

        for(uint i = 0; i < fearStakers.length(); i++) {
            address user = fearStakers.at(i);
            stakes[user] = 0;
            stakeLockExpiration[user] = 0;
            wolvesReserved[user] = 0;
            whitelistedWithoutStaking[user] = false;
        }

        fearWolfContract.resetAll();
    }
    // FIXME: ^^^^^^^^^^^^^^^^^^^^^^
}