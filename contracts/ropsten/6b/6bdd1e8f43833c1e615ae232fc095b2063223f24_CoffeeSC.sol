/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// File: @openzeppelin\contracts\access\IAccessControl.sol

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

// File: @openzeppelin\contracts\access\IAccessControlEnumerable.sol

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

// File: @openzeppelin\contracts\utils\Context.sol

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

// File: @openzeppelin\contracts\utils\Strings.sol

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

// File: @openzeppelin\contracts\utils\introspection\IERC165.sol

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

// File: @openzeppelin\contracts\utils\introspection\ERC165.sol

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

// File: @openzeppelin\contracts\access\AccessControl.sol

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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
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
}

// File: @openzeppelin\contracts\utils\structs\EnumerableSet.sol

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

// File: @openzeppelin\contracts\access\AccessControlEnumerable.sol

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

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
}

// File: @openzeppelin\contracts\utils\Counters.sol

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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

// File: @openzeppelin\contracts\security\Pausable.sol

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
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
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
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
}

// File: contracts\DataStruct.sol

contract DataStruct {

    struct Metadata {
        uint256 id;
        address creator;
        uint256 createdTime;
        string dataType;
        string creatorType;
    }

    struct ParentData {
        uint256 parentId;
        string parentType;
        string parentCreatorType;
    }

    struct ShippingData {
        bool accepted;
        uint256 receiveTime;
        address receiver;
        string receiverType;
    }

    struct FarmerData {
        uint32 farmerId;
        uint256 harvestDate;
        uint256 pulpDate;
        string coffeeVariant;
        string coffeeType;
        uint32 weight;
        uint32 pricePerWeight;
    }

    struct CollectorData {
        Metadata metadata;
        ShippingData shipping;
        FarmerData[] farmer;
        uint32 weight;
        uint64 price;
    }

    struct ProcessorData {
        Metadata metadata;
        ParentData parent;
        string coffeeProcess;
        uint32 weight;
    }

    struct ProcessorPackageData {
        Metadata metadata;
        ParentData parent;
        ShippingData shipping;
        uint16 amount;
        uint32 weight;
        uint64 price;
    }

    struct TraderPackageData {
        Metadata metadata;
        ParentData parent;
        ShippingData shipping;
        uint16 amount;
        uint32 weight;
        uint64 price;
    }

    struct CoffeeData {
        uint8 temperature;
        string quality;
        uint8 coffeeBody;
        uint8 coffeeAroma;
        uint8 coffeeAcidity;
        string[] coffeeDescription;
    }

    struct RoasterData {
        Metadata metadata;
        ParentData parent;
        CoffeeData coffeeData;
        uint32 cupperId;
        uint32 weight;
    }

    struct RoasterPackageData {
        Metadata metadata;
        ParentData parent;
        ShippingData shipping;
        uint16 amount;
        uint32 weight;
        uint64 price;
    }

    struct BrewerData {
        Metadata metadata;
        ParentData parent;
    }
}

// File: contracts\CoffeeSC.sol

contract CoffeeSC is DataStruct, Context, AccessControlEnumerable, Pausable {

    using Counters for Counters.Counter;

    bytes32 public constant SUPER_ADMIN_ROLE = keccak256("SUPER_ADMIN_ROLE");
    bytes32 public constant ADMIN_COLLECTOR_ROLE = keccak256("ADMIN_COLLECTOR_ROLE");
    bytes32 public constant COLLECTOR_ROLE = keccak256("COLLECTOR_ROLE");
    bytes32 public constant ADMIN_PROCESSOR_ROLE = keccak256("ADMIN_PROCESSOR_ROLE");
    bytes32 public constant PROCESSOR_ROLE = keccak256("PROCESSOR_ROLE");
    bytes32 public constant ADMIN_ROASTER_ROLE = keccak256("ADMIN_ROASTER_ROLE");
    bytes32 public constant ROASTER_ROLE = keccak256("ROASTER_ROLE");
    bytes32 public constant ADMIN_BREWER_ROLE = keccak256("ADMIN_BREWER_ROLE");
    bytes32 public constant BREWER_ROLE = keccak256("BREWER_ROLE");
    bytes32 public constant ADMIN_TRADER_ROLE = keccak256("ADMIN_TRADER_ROLE");
    bytes32 public constant TRADER_ROLE = keccak256("TRADER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant PAYEE_ROLE = keccak256("PAYEE_ROLE");

    mapping(uint8 => Counters.Counter) private _dataCounter;

    mapping(uint256 => CollectorData) private _collectorData;
    mapping(uint256 => ProcessorData) private _processorData;
    mapping(uint256 => ProcessorPackageData) private _processorPackageData;
    mapping(uint256 => TraderPackageData) private _traderPackageData;
    mapping(uint256 => RoasterData) private _roasterData;
    mapping(uint256 => RoasterPackageData) private _roasterPackageData;
    mapping(uint256 => BrewerData) private _brewerData;

    mapping(address => uint256) private _gasUsed;

    event CollectorDataCreated(
        uint256 indexed id,
        address indexed creator,
        uint256 timestamp,
        string dataType,
        string creatorType
    );
    event CollectorDataReceived(
        uint256 indexed id,
        address indexed receiver,
        uint256 receiveTime,
        string receiverType
    );
    event ProcessorDataCreated(
        uint256 indexed id,
        address indexed creator,
        uint256 timestamp,
        string dataType,
        string creatorType,
        uint256 parentId
    );
    event ProcessorPackageDataCreated(
        uint256 indexed id,
        address indexed creator,
        uint256 timestamp,
        string dataType,
        string creatorType,
        uint256 parentId
    );
    event ProcessorPackageDataReceived(
        uint256 indexed id,
        address indexed receiver,
        uint256 receiveTime,
        string receiverType
    );
    event TraderPackageDataCreated(
        uint256 indexed id,
        address indexed creator,
        uint256 timestamp,
        string dataType,
        string creatorType,
        uint256 parentId
    );
    event TraderPackageDataReceived(
        uint256 indexed id,
        address indexed receiver,
        uint256 receiveTime,
        string receiverType
    );
    event RoasterDataCreated(
        uint256 indexed id,
        address indexed creator,
        uint256 timestamp,
        string dataType,
        string creatorType,
        uint256 parentId
    );
    event RoasterPackageDataCreated(
        uint256 indexed id,
        address indexed creator,
        uint256 timestamp,
        string dataType,
        string creatorType,
        uint256 parentId
    );
    event RoasterPackageDataReceived(
        uint256 indexed id,
        address indexed receiver,
        uint256 receiveTime,
        string receiverType
    );
    event BrewerDataCreated(
        uint256 indexed id,
        address indexed creator,
        uint256 timestamp,
        string dataType,
        string creatorType,
        uint256 parentId
    );
    event gasUsedIncrease(
        address indexed user,
        uint256 amount
    );

    constructor()
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(SUPER_ADMIN_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
        _setupRole(PAYEE_ROLE, _msgSender());

        _setRoleAdmin(ADMIN_COLLECTOR_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(ADMIN_PROCESSOR_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(ADMIN_ROASTER_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(ADMIN_BREWER_ROLE, SUPER_ADMIN_ROLE);
        _setRoleAdmin(ADMIN_TRADER_ROLE, SUPER_ADMIN_ROLE);

        _setRoleAdmin(COLLECTOR_ROLE, ADMIN_COLLECTOR_ROLE);
        _setRoleAdmin(PROCESSOR_ROLE, ADMIN_PROCESSOR_ROLE);
        _setRoleAdmin(ROASTER_ROLE, ADMIN_ROASTER_ROLE);
        _setRoleAdmin(BREWER_ROLE, ADMIN_BREWER_ROLE);
        _setRoleAdmin(TRADER_ROLE, ADMIN_TRADER_ROLE);
    }

    function pause()
        public
        virtual
        whenNotPaused
    {
        require(hasRole(PAUSER_ROLE, _msgSender()), "CoffeeSC: must have pauser role to pause");

        _pause();
    }

    function unpause()
        public
        virtual
        whenPaused
    {
        require(hasRole(PAUSER_ROLE, _msgSender()), "CoffeeSC: must have pauser role to unpause");

        _unpause();
    }

    function resetGasUsed(address user)
        public
        whenNotPaused
    {
        require(hasRole(PAYEE_ROLE, _msgSender()), "CoffeeSC: must have admin role to call this");

        require(_gasUsed[user] != 0, "CoffeeSC: gas used already empty for this address");

        _gasUsed[user] = 0;
    }

    function gasUsed(address user)
        public
        view
        returns (uint256)
    {
        return _gasUsed[user];
    }

    function grantRole(
        bytes32 role,
        address account
    )
        public
        virtual
        override
    {
        uint256 startGas = gasleft();

        super.grantRole(role, account);

        uint256 endGas = startGas - gasleft();

        _gasUsed[_msgSender()] += endGas;

        emit gasUsedIncrease(
            _msgSender(),
            endGas
        );
    }

    function revokeRole(
        bytes32 role,
        address account
    )
        public
        virtual
        override
    {
        uint256 startGas = gasleft();

        super.revokeRole(role, account);

        uint256 endGas = startGas - gasleft();

        _gasUsed[_msgSender()] += endGas;

        emit gasUsedIncrease(
            _msgSender(),
            endGas
        );
    }

    function addCollectorData(
        address receiver,
        uint256 createdTime,
        uint32 weight,
        uint64 price,
        FarmerData[] calldata farmerData
    )
        external
        whenNotPaused
    {
        require(
            hasRole(ADMIN_COLLECTOR_ROLE, _msgSender()) ||
            hasRole(COLLECTOR_ROLE, _msgSender()) ||
            hasRole(ADMIN_PROCESSOR_ROLE, _msgSender()) ||
            hasRole(PROCESSOR_ROLE, _msgSender()),
            "CoffeeSC: only Collector and Processor can call this"
            );

        uint256 dataId = _dataCounter[0].current() + 1;
        CollectorData storage currentData = _collectorData[dataId];

        uint256 startGas = gasleft();

        currentData.metadata = Metadata({
            id: dataId,
            creator: _msgSender(),
            createdTime: createdTime,
            dataType: "Collecting",
            creatorType: "Collector"
        });

        if (hasRole(ADMIN_PROCESSOR_ROLE, _msgSender()) ||
            hasRole(PROCESSOR_ROLE, _msgSender())) {
            currentData.metadata.creatorType = "Processor";

            currentData.shipping = ShippingData({
                accepted: true,
                receiveTime: createdTime,
                receiver: _msgSender(),
                receiverType: "Processor"
            });
        }

        if (receiver != address(0)) {
            currentData.shipping.receiver = receiver;
            currentData.shipping.receiverType = "Processor";
        }

        currentData.weight = weight;
        currentData.price = price;

        for (uint8 i; i < farmerData.length; i++) {
            currentData.farmer.push(farmerData[i]);
        }

        uint256 endGas = startGas - gasleft();

        _gasUsed[_msgSender()] += endGas;

        _dataCounter[0].increment();

        emit CollectorDataCreated(
            currentData.metadata.id,
            currentData.metadata.creator,
            currentData.metadata.createdTime,
            currentData.metadata.dataType,
            currentData.metadata.creatorType
        );

        emit gasUsedIncrease(
            _msgSender(),
            endGas
        );
    }

    function receiveCollectorData(
        uint256 dataId,
        uint256 receiveTime
    )
        external
        whenNotPaused
    {
        require(
            hasRole(ADMIN_PROCESSOR_ROLE, _msgSender()) ||
            hasRole(PROCESSOR_ROLE, _msgSender()),
            "CoffeeSC: only Processor can call this"
        );

        require(_collectorData[dataId].metadata.id != 0, "CoffeeSC: data not exist");

        require(!_collectorData[dataId].shipping.accepted, "CoffeeSC: status already accepted");

        require(
            _collectorData[dataId].shipping.receiver == address(0) ||
            _collectorData[dataId].shipping.receiver == _msgSender(),
            "CoffeSC: the receiver did not match from data"
        );

        CollectorData storage currentData = _collectorData[dataId];

        uint256 startGas = gasleft();

        currentData.shipping = ShippingData({
            accepted: true,
            receiveTime: receiveTime,
            receiver: _msgSender(),
            receiverType: "Processor"
        });

        uint256 endGas = startGas - gasleft();

        _gasUsed[_msgSender()] += endGas;

        emit CollectorDataReceived(
            currentData.metadata.id,
            currentData.shipping.receiver,
            currentData.shipping.receiveTime,
            currentData.shipping.receiverType
        );

        emit gasUsedIncrease(
            _msgSender(),
            endGas
        );
    }

    function addProcessorData(
        uint256 createdTime,
        string calldata coffeeProcess,
        uint32 weight,
        ParentData calldata parentData
    )
        external
        whenNotPaused
    {
        require(
            hasRole(ADMIN_PROCESSOR_ROLE, _msgSender()) ||
            hasRole(PROCESSOR_ROLE, _msgSender()),
            "CoffeeSC: only Processor can call this"
        );

        uint256 dataId = _dataCounter[1].current() + 1;
        ProcessorData storage currentData = _processorData[dataId];

        uint256 startGas = gasleft();

        currentData.metadata = Metadata({
            id: dataId,
            creator: _msgSender(),
            createdTime: createdTime,
            dataType: "Processing",
            creatorType: "Processor"
        });

        currentData.parent = parentData;

        currentData.coffeeProcess = coffeeProcess;
        currentData.weight = weight;

        uint256 endGas = startGas - gasleft();

        _gasUsed[_msgSender()] += endGas;

        _dataCounter[1].increment();

        emit ProcessorDataCreated(
            currentData.metadata.id,
            currentData.metadata.creator,
            currentData.metadata.createdTime,
            currentData.metadata.dataType,
            currentData.metadata.creatorType,
            currentData.parent.parentId
        );

        emit gasUsedIncrease(
            _msgSender(),
            endGas
        );
    }

    function addProcessorPackageData(
        address receiver,
        uint256 createdTime,
        uint16 amount,
        uint32 weight,
        uint64 price,
        ParentData calldata parentData
    )
        external
        whenNotPaused
    {
        require(
            hasRole(ADMIN_PROCESSOR_ROLE, _msgSender()) ||
            hasRole(PROCESSOR_ROLE, _msgSender()),
            "CoffeeSC: only Processor can call this"
        );

        uint256 dataId = _dataCounter[2].current() + 1;
        ProcessorPackageData storage currentData = _processorPackageData[dataId];

        uint256 startGas = gasleft();

        currentData.metadata = Metadata({
            id: dataId,
            creator: _msgSender(),
            createdTime: createdTime,
            dataType: "Packaging",
            creatorType: "Processor"
        });

        currentData.parent = parentData;

        currentData.amount = amount;
        currentData.weight = weight;
        currentData.price = price;

        if (receiver != address(0)) {
            currentData.shipping.receiver = receiver;
        }

        uint256 endGas = startGas - gasleft();

        _gasUsed[_msgSender()] += endGas;

        _dataCounter[2].increment();

        emit ProcessorPackageDataCreated(
            currentData.metadata.id,
            currentData.metadata.creator,
            currentData.metadata.createdTime,
            currentData.metadata.dataType,
            currentData.metadata.creatorType,
            currentData.parent.parentId
        );

        emit gasUsedIncrease(
            _msgSender(),
            endGas
        );
    }

    function receiveProcessorPackageData(
        uint256 dataId,
        uint256 receiveTime
    )
        external
        whenNotPaused
    {
        require(
            hasRole(ADMIN_ROASTER_ROLE, _msgSender()) ||
            hasRole(ROASTER_ROLE, _msgSender()) ||
            hasRole(ADMIN_TRADER_ROLE, _msgSender()) ||
            hasRole(TRADER_ROLE, _msgSender()),
            "CoffeeSC: only Roaster or Trader can call this"
        );

        require(_processorPackageData[dataId].metadata.id != 0, "CoffeeSC: data not exist");

        require(!_processorPackageData[dataId].shipping.accepted, "CoffeeSC: status already accepted");

        require(
            _processorPackageData[dataId].shipping.receiver == address(0) ||
            _processorPackageData[dataId].shipping.receiver == _msgSender(),
            "CoffeSC: the receiver did not match from data"
        );

        ProcessorPackageData storage currentData = _processorPackageData[dataId];

        uint256 startGas = gasleft();

        currentData.shipping = ShippingData({
            accepted: true,
            receiveTime: receiveTime,
            receiver: _msgSender(),
            receiverType: "Roaster"
        });

        if (hasRole(ADMIN_TRADER_ROLE, _msgSender()) ||
            hasRole(TRADER_ROLE, _msgSender())) {
            currentData.shipping.receiverType = "Trader";
        }

        uint256 endGas = startGas - gasleft();

        _gasUsed[_msgSender()] += endGas;

        emit ProcessorPackageDataReceived(
            currentData.metadata.id,
            currentData.shipping.receiver,
            currentData.shipping.receiveTime,
            currentData.shipping.receiverType
        );

        emit gasUsedIncrease(
            _msgSender(),
            endGas
        );
    }

    function addTraderPackageData(
        address receiver,
        uint256 createdTime,
        uint16 amount,
        uint32 weight,
        uint64 price,
        ParentData calldata parentData
    )
        external
        whenNotPaused
    {
        require(
            hasRole(ADMIN_TRADER_ROLE, _msgSender()) ||
            hasRole(TRADER_ROLE, _msgSender()),
            "CoffeeSC: only Trader can call this"
        );

        uint256 dataId = _dataCounter[3].current() + 1;
        TraderPackageData storage currentData = _traderPackageData[dataId];

        uint256 startGas = gasleft();

        currentData.metadata = Metadata({
            id: dataId,
            creator: _msgSender(),
            createdTime: createdTime,
            dataType: "Packaging",
            creatorType: "Trader"
        });

        currentData.parent = parentData;

        currentData.amount = amount;
        currentData.weight = weight;
        currentData.price = price;

        if (receiver != address(0)) {
            currentData.shipping.receiver = receiver;
            currentData.shipping.receiverType = "Roaster";
        }

        uint256 endGas = startGas - gasleft();

        _gasUsed[_msgSender()] += endGas;

        _dataCounter[3].increment();

        emit TraderPackageDataCreated(
            currentData.metadata.id,
            currentData.metadata.creator,
            currentData.metadata.createdTime,
            currentData.metadata.dataType,
            currentData.metadata.creatorType,
            currentData.parent.parentId
        );

        emit gasUsedIncrease(
            _msgSender(),
            endGas
        );
    }

    function receiveTraderPackageData(
        uint256 dataId,
        uint256 receiveTime
    )
        external
        whenNotPaused
    {
        require(
            hasRole(ADMIN_ROASTER_ROLE, _msgSender()) ||
            hasRole(ROASTER_ROLE, _msgSender()),
            "CoffeeSC: only Roaster can call this"
        );

        require(_traderPackageData[dataId].metadata.id != 0, "CoffeeSC: data not exist");

        require(!_traderPackageData[dataId].shipping.accepted, "CoffeeSC: status already accepted");

        require(
            _traderPackageData[dataId].shipping.receiver == address(0) ||
            _traderPackageData[dataId].shipping.receiver == _msgSender(),
            "CoffeSC: the receiver did not match from data"
        );

        TraderPackageData storage currentData = _traderPackageData[dataId];

        uint256 startGas = gasleft();

        currentData.shipping = ShippingData({
            accepted: true,
            receiveTime: receiveTime,
            receiver: _msgSender(),
            receiverType: "Roaster"
        });

        uint256 endGas = startGas - gasleft();

        _gasUsed[_msgSender()] += endGas;

        emit TraderPackageDataReceived(
            currentData.metadata.id,
            currentData.shipping.receiver,
            currentData.shipping.receiveTime,
            currentData.shipping.receiverType
        );

        emit gasUsedIncrease(
            _msgSender(),
            endGas
        );
    }

    function addRoasterData(
        uint256 createdTime,
        uint32 cupperId,
        uint32 weight,
        CoffeeData calldata coffeeData,
        ParentData calldata parentData
    )
        external
        whenNotPaused
    {
        require(
            hasRole(ADMIN_ROASTER_ROLE, _msgSender()) ||
            hasRole(ROASTER_ROLE, _msgSender()),
            "CoffeeSC: only Roaster can call this"
        );

        uint256 dataId = _dataCounter[4].current() + 1;
        RoasterData storage currentData = _roasterData[dataId];

        uint256 startGas = gasleft();

        currentData.metadata = Metadata({
            id: dataId,
            creator: _msgSender(),
            createdTime: createdTime,
            dataType: "Roasting",
            creatorType: "Roaster"
        });

        currentData.parent = parentData;

        currentData.coffeeData = coffeeData;
        currentData.cupperId = cupperId;
        currentData.weight = weight;

        uint256 endGas = startGas - gasleft();

        _gasUsed[_msgSender()] += endGas;

        _dataCounter[4].increment();

        emit RoasterDataCreated(
            currentData.metadata.id,
            currentData.metadata.creator,
            currentData.metadata.createdTime,
            currentData.metadata.dataType,
            currentData.metadata.creatorType,
            currentData.parent.parentId
        );

        emit gasUsedIncrease(
            _msgSender(),
            endGas
        );
    }

    function addRoasterPackageData(
        address receiver,
        uint256 createdTime,
        uint16 amount,
        uint32 weight,
        uint64 price,
        ParentData calldata parentData
    )
        external
        whenNotPaused
    {
        require(
            hasRole(ADMIN_ROASTER_ROLE, _msgSender()) ||
            hasRole(ROASTER_ROLE, _msgSender()),
            "CoffeeSC: only Roaster can call this"
        );

        uint256 dataId = _dataCounter[5].current() + 1;
        RoasterPackageData storage currentData = _roasterPackageData[dataId];

        uint256 startGas = gasleft();

        currentData.metadata = Metadata({
            id: dataId,
            creator: _msgSender(),
            createdTime: createdTime,
            dataType: "Packaging",
            creatorType: "Roaster"
        });

        currentData.parent = parentData;

        currentData.amount = amount;
        currentData.weight = weight;
        currentData.price = price;

        if (receiver != address(0)) {
            currentData.shipping.receiver = receiver;
            currentData.shipping.receiverType = "Brewer";
        }

        uint256 endGas = startGas - gasleft();

        _gasUsed[_msgSender()] += endGas;

        _dataCounter[5].increment();

        emit RoasterPackageDataCreated(
            currentData.metadata.id,
            currentData.metadata.creator,
            currentData.metadata.createdTime,
            currentData.metadata.dataType,
            currentData.metadata.creatorType,
            currentData.parent.parentId
        );

        emit gasUsedIncrease(
            _msgSender(),
            endGas
        );
    }

    function receiveRoasterPackageData(
        uint256 dataId,
        uint256 receiveTime
    )
        external
        whenNotPaused
    {
        require(
            hasRole(ADMIN_BREWER_ROLE, _msgSender()) ||
            hasRole(BREWER_ROLE, _msgSender()),
            "CoffeeSC: only Brewer can call this"
        );

        require(_roasterPackageData[dataId].metadata.id != 0, "CoffeeSC: data not exist");

        require(!_roasterPackageData[dataId].shipping.accepted, "CoffeeSC: status already accepted");

        require(
            _roasterPackageData[dataId].shipping.receiver == address(0) ||
            _roasterPackageData[dataId].shipping.receiver == _msgSender(),
            "CoffeSC: the receiver did not match from data"
        );

        RoasterPackageData storage currentData = _roasterPackageData[dataId];

        uint256 startGas = gasleft();

        currentData.shipping = ShippingData({
            accepted: true,
            receiveTime: receiveTime,
            receiver: _msgSender(),
            receiverType: "Brewer"
        });

        uint256 endGas = startGas - gasleft();

        _gasUsed[_msgSender()] += endGas;

        emit RoasterPackageDataReceived(
            currentData.metadata.id,
            currentData.shipping.receiver,
            currentData.shipping.receiveTime,
            currentData.shipping.receiverType
        );

        emit gasUsedIncrease(
            _msgSender(),
            endGas
        );
    }

    function addBrewerData(
        uint256 createdTime,
        ParentData calldata parentData
    )
        external
        whenNotPaused
    {
        require(
            hasRole(ADMIN_BREWER_ROLE, _msgSender()) ||
            hasRole(BREWER_ROLE, _msgSender()),
            "CoffeeSC: only Brewer can call this"
        );

        uint256 dataId = _dataCounter[6].current() + 1;
        BrewerData storage currentData = _brewerData[dataId];

        uint256 startGas = gasleft();

        currentData.metadata = Metadata({
            id: dataId,
            creator: _msgSender(),
            createdTime: createdTime,
            dataType: "Opening Package",
            creatorType: "Brewer"
        });

        currentData.parent = parentData;

        uint256 endGas = startGas - gasleft();

        _gasUsed[_msgSender()] += endGas;

        _dataCounter[6].increment();

        emit BrewerDataCreated(
            currentData.metadata.id,
            currentData.metadata.creator,
            currentData.metadata.createdTime,
            currentData.metadata.dataType,
            currentData.metadata.creatorType,
            currentData.parent.parentId
        );

        emit gasUsedIncrease(
            _msgSender(),
            endGas
        );
    }

    function getCollectorData(uint256 dataId)
        external
        view
        returns (CollectorData memory)
    {
        require(_collectorData[dataId].metadata.id != 0, "CoffeeSC: data not exist");

        return _collectorData[dataId];
    }

    function getProcessorData(uint256 dataId)
        external
        view
        returns (ProcessorData memory)
    {
        require(_processorData[dataId].metadata.id != 0, "CoffeeSC: data not exist");

        return _processorData[dataId];
    }

    function getProcessorPackageData(uint256 dataId)
        external
        view
        returns (ProcessorPackageData memory)
    {
        require(_processorPackageData[dataId].metadata.id != 0, "CoffeeSC: data not exist");

        return _processorPackageData[dataId];
    }

    function getTraderPackageData(uint256 dataId)
        external
        view
        returns (TraderPackageData memory)
    {
        require(_traderPackageData[dataId].metadata.id != 0, "CoffeeSC: data not exist");

        return _traderPackageData[dataId];
    }

    function getRoasterData(uint256 dataId)
        external
        view
        returns (RoasterData memory)
    {
        require(_roasterData[dataId].metadata.id != 0, "CoffeeSC: data not exist");

        return _roasterData[dataId];
    }

    function getRoasterPackageData(uint256 dataId)
        external
        view
        returns (RoasterPackageData memory)
    {
        require(_roasterPackageData[dataId].metadata.id != 0, "CoffeeSC: data not exist");

        return _roasterPackageData[dataId];
    }

    function getBrewerData(uint256 dataId)
        external
        view
        returns (BrewerData memory)
    {
        require(_brewerData[dataId].metadata.id != 0, "CoffeeSC: data not exist");

        return _brewerData[dataId];
    }
}