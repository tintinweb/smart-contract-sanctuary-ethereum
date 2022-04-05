/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File @openzeppelin/contracts/access/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;




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


// File @openzeppelin/contracts/utils/structs/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;



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


// File @openzeppelin/contracts/token/ERC20/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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


// File contracts/Interfaces/PresaleInterface.sol


pragma solidity 0.8.11;

interface PresaleInterface is IAccessControlEnumerable {

    /* solhint-disable */
    function ADMIN_ROLE() external pure returns(bytes32);
    function MODERATOR_ROLE() external pure returns(bytes32);
    /* solhint-enable */

    // ******************************************
    // ************* PUBLIC REGION **************
    // ******************************************
    function contributeFirstStage(address tokenInvested_, uint amountInvested_, bytes memory signature_) external;
    function contributeSecondStage(address tokenInvested_, uint amountInvested_, bytes memory signature_) external;

    // *******************************************
    // ************* MANAGER REGION **************
    // *******************************************
    function setMinimumContributionRequierment(uint minimumContributionRequierment_) external returns (bool);
    function setPresaleCap(uint presaleCap_) external returns (bool);

    function setFirstStageBlockStart(uint firstStageBlockStart_) external returns (bool);
    function setFirstStageBlockEnd(uint firstStageBlockEnd_) external returns (bool);
    function setFirstStageMaxContributorCount(uint firstStageMaxContributorCount_) external returns (bool);
    function setFirstStageMaxContribution(uint firstStageMaxContribution_) external returns (bool);

    function setSecondStageBlockStart(uint secondStageBlockStart_) external returns (bool);
    function setSecondStageBlockEnd(uint secondStageBlockEnd_) external returns (bool);
    function setSecondStageMaxContribution(uint secondStageMaxContribution_) external returns (bool);

    function setTokenAllowed(address token_, bool option_) external returns (bool);
    function setDataInstance(address dataAddress_) external returns (bool);
    function setCorporateAddress(address corporateAddress_) external returns (bool);
                            
    // *************************************************
    // ************* DEFAULT_ADMIN REGION **************
    // *************************************************
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external returns (bool);
    function salvageTokensFromContract(address tokenAddress, address to, uint amount) external returns (bool);
    function killContract() external returns (bool);

    // **************************************************
    // ************* PUBLIC GETTERS REGION **************
    // **************************************************
    function getPresaleActive() external view returns (bool);
    function getFirstStageActive() external view returns (bool);
    function getSecondStageActive() external view returns (bool);

    function getFirstStageParticipantMaxContribution(address participant_) external view returns (uint);
    function getSecondStageParticipantMaxContribution(address participant_) external view returns (uint);

    function getMinimumContributionRequierment() external view returns (uint);
    function getPresaleCap() external view returns (uint);

    function getFirstStageBlockStart() external view returns (uint);
    function getFirstStageBlockEnd() external view returns (uint);
    function getFirstStageMaxContributorCount() external view returns (uint);
    function getFirstStageMaxContribution() external view returns (uint);

    function getSecondStageBlockStart() external view returns (uint);
    function getSecondStageBlockEnd() external view returns (uint);
    function getSecondStageMaxContribution() external view returns (uint);
    function getTokenAllowed(address token_) external view returns (bool);

    function getDataAddress() external view returns (address);
    function getCorporateAddress() external view returns (address);

    // ******************************************
    // ************* EVENTS REGION **************
    // ******************************************
    event MinimumContributionRequiermentChanged(uint oldValue, uint newValue);
    event PresaleCapChanged(uint oldValue, uint newValue);

    event FirstStageBlockStartChanged(uint oldValue,  uint newValue);
    event FirstStageBlockEndChanged(uint oldValue,  uint newValue);
    event FirstStageMaxContributorCountChanged(uint oldValue, uint newValue);
    event FirstStageMaxContributionChanged(uint oldValue, uint newValue);

    event SecondStageBlockStartChanged(uint oldValue, uint newValue);
    event SecondStageBlockEndChanged(uint oldValue, uint newValue);
    event SecondStageMaxContributionChanged(uint oldValue, uint newValue);

    event TokenAllowedChanged(bool oldValue, bool newValue);

    event DataAddressChanged(address oldValue, address newValue);
    event CorporateAddressChanged(address oldValue, address newValue);

    event AdminRoleSet(bytes32 role, bytes32 adminRole);
    event TokensSalvaged(address tokenAddress, address reciever, uint amount);
    event ContractKilled();
}


// File contracts/Interfaces/DataInterface.sol


pragma solidity 0.8.11;

interface DataInterface is IAccessControlEnumerable{

    /* solhint-disable */
    function ADMIN_ROLE() external pure returns(bytes32);
    function MODERATOR_ROLE() external pure returns(bytes32);
    function SALECONTRACT_ROLE() external pure returns(bytes32);
    /* solhint-enable */

    // *******************************************
    // ************* MANAGER REGION **************
    // *******************************************
    function manuallyWhitelistParticipant(address participant_) external;
    function manuallyBlacklistParticipant(address participant_) external;

    function manuallyCreditParticipant(address participant_, address tokenInvested_, uint tokenAmount_) external;

    function setSignersAddress(address signersAddress_) external returns (bool);
    function setTokenConversion(uint tokenConversion_) external returns (bool);

    // *****************************************************
    // ************* SALECONTRACT_ROLE REGION **************
    // *****************************************************
    function whitelistParticipant(address participant_, bytes memory signature_) external;

    function creditParticipation(address participant_, address tokenInvested_, uint tokenAmount_) external;

    // *************************************************
    // ************* DEFAULT_ADMIN REGION **************
    // *************************************************
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external returns (bool);
    function salvageTokensFromContract(address tokenAddress, address to, uint amount) external returns (bool);
    function killContract() external returns (bool);

    // ********************************************
    // ************* INTERNAL REGION **************
    // ********************************************

    // **************************************************
    // ************* PUBLIC GETTERS REGION **************
    // **************************************************
    function getParticipantCount() external view returns (uint);
    function getCombinedContributions() external view returns (uint);
    function getIsParticipantWhitelisted(address participant_) external view returns (bool);
    function getParticipantContributions(address participant_) external view returns (uint);
    function getParticipantList(uint startIndex_, uint endIndex_) external view returns (address[] memory, uint[] memory);

    function getSignersAddress() external view returns (address);
    function getMessageHash(address contributor_, bool allowed_) external pure returns (bytes32);
    
    function getTokenConversion() external view returns (uint);

    // ******************************************
    // ************* EVENTS REGION **************
    // ******************************************
    event ContributionMade(address indexed contractAddress, address indexed participant_, address tokenInvested_, uint baseAmount_, uint tokensIssued_);
    event ParticipantWhitelisted(address participant_);
    event ParticipantBlacklisted(address participant_);

    event SignersAddressChanged(address oldValue, address newValue);
    event TokenConversionChanged(uint oldValue, uint newValue);

    event AdminRoleSet(bytes32 role, bytes32 adminRole);
    event TokensSalvaged(address tokenAddress, address reciever, uint amount);
    event ContractKilled();
}


// File contracts/PresaleContract.sol


pragma solidity 0.8.11;

//import "hardhat/console.sol";


/// @title Authtrail presale contract
/// @author Authtrail llc
/// @dev Presale contract that serves as an interface for collecting stable coins in presale
/// @custom:experimental This is an experimental contract.
contract PresaleContract is AccessControlEnumerable, PresaleInterface {

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    DataInterface private _dataInstance;
    address private _corporateAddress;

    uint private _minimumContributionRequierment = 1000 * 10 ** 6;
    uint private _presaleCap = 6000000 * 10 ** 6;
    // TODO: adjust the blocks closer to the crowsale
    uint private _firstStageBlockStart = 14571380;              // https://etherscan.io/block/countdown/14571380 - 12.4 14:00 UTC
    uint private _firstStageBlockEnd = 14573680;                // https://etherscan.io/block/countdown/14573680 - 12.4 23:59 UTC
    uint private _firstStageMaxContributorCount = 1000;
    uint private _firstStageMaxContribution = 5000 * 10**6;

    uint private _secondStageBlockStart = 14584200;             // https://etherscan.io/block/countdown/14584200 - 14.4 14:00 UTC
    uint private _secondStageBlockEnd = 14586600;               // https://etherscan.io/block/countdown/14586600 - 14.4 23:59 UTC
    uint private _secondStageMaxContribution = 50000 * 10**6;

    mapping(address => bool) private _allowedTokens;

    constructor(address defaultAdminAddress_, address adminAddress_, address moderatorAddress_, address dataAddress_, address corporateAddress_) {
        _setupRole(DEFAULT_ADMIN_ROLE, defaultAdminAddress_);
        _setupRole(ADMIN_ROLE, adminAddress_);
        _setupRole(MODERATOR_ROLE, moderatorAddress_);
        _setRoleAdmin(MODERATOR_ROLE, ADMIN_ROLE);

        _dataInstance = DataInterface(dataAddress_);
        _corporateAddress = corporateAddress_;

        _allowedTokens[0xdAC17F958D2ee523a2206206994597C13D831ec7] = true; // Allow USDT as participation currency
        _allowedTokens[0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48] = true; // Allow USDC as participation currency
    }

    // ******************************************
    // ************* PUBLIC REGION **************
    // ******************************************
    /// @notice Executes the code for participating in the crowdsale @ First stage
    /// @dev This is a public method that users should execute for participating
    /// @param tokenInvested_ The ERC20 token address that participant wants to contribute
    /// @param amountInvested_ The amount of tokens contributed to presale, will be transfered to corpo from 
    /// @param signature_ Cryptographic proof that participant is whitelisted
    function contributeFirstStage(address tokenInvested_, uint amountInvested_, bytes memory signature_) public override {
        require(getFirstStageActive(), "FirstStage is not active!");
        require(getTokenAllowed(tokenInvested_), "Token is not allowed!");

        uint allowedContribution = getFirstStageParticipantMaxContribution(msg.sender);
        require(allowedContribution > 0, "Allowed amount is 0!");
        if (allowedContribution > amountInvested_) {
            allowedContribution = amountInvested_;
        }
        
        if (!_dataInstance.getIsParticipantWhitelisted(msg.sender)) {
            require(amountInvested_ >= _minimumContributionRequierment, "Not enough tokens contributed!");
            _dataInstance.whitelistParticipant(msg.sender, signature_);
        }

        _dataInstance.creditParticipation(msg.sender, tokenInvested_, allowedContribution);
        require(IERC20(tokenInvested_).transferFrom(msg.sender, _corporateAddress, allowedContribution), "TransferFrom failed");
    }
    /// @notice Executes the code for participating in the crowdsale @ Second stage
    /// @dev This is a public method that users should execute for participating
    /// @param tokenInvested_ The ERC20 token address that participant wants to contribute
    /// @param amountInvested_ The amount of tokens contributed to presale, will be transfered to corpo from 
    /// @param signature_ Cryptographic proof that participant is whitelisted
    function contributeSecondStage(address tokenInvested_, uint amountInvested_, bytes memory signature_) public override {
        require(getSecondStageActive(), "Presale is not active!");
        require(getTokenAllowed(tokenInvested_), "Token is not allowed!");

        uint allowedContribution = getSecondStageParticipantMaxContribution(msg.sender);
        require(allowedContribution > 0, "Allowed amount is 0!");
        if (allowedContribution > amountInvested_) {
            allowedContribution = amountInvested_;
        }
         
        if (!_dataInstance.getIsParticipantWhitelisted(msg.sender)) {
            require(amountInvested_ >= _minimumContributionRequierment, "Not enough tokens contributed!");
            _dataInstance.whitelistParticipant(msg.sender, signature_);
        } 

        _dataInstance.creditParticipation(msg.sender, tokenInvested_, allowedContribution);
        require(IERC20(tokenInvested_).transferFrom(msg.sender, _corporateAddress, allowedContribution), "TransferFrom failed");
    }

    // *********************************************
    // ************* MODERATOR REGION **************
    // *********************************************
    /// @notice Sets new minimum ammount users can invest
    /// @dev This method should only be used in ongoing presale if something goes wrong
    /// @param minimumContributionRequierment_ Minimum ammount of allowed tokens user can invest
    /// @return default return True after everything is processed
    function setMinimumContributionRequierment(uint minimumContributionRequierment_) public onlyRole(MODERATOR_ROLE) override returns (bool) {
        uint oldValue = _minimumContributionRequierment;
        require(oldValue != minimumContributionRequierment_, "Value is already set!");
        _minimumContributionRequierment = minimumContributionRequierment_;
        emit MinimumContributionRequiermentChanged(oldValue, minimumContributionRequierment_);
        return true;
    }
    /// @notice Sets new amount of stablecoins that needs to be colected for presale to be over
    /// @dev This method should only be used in ongoing presale if something goes wrong
    /// @param presaleCap_ The new cap on presale
    /// @return default return True after everything is processed
    function setPresaleCap(uint presaleCap_) public onlyRole(MODERATOR_ROLE) override returns (bool) {
        uint oldValue = _presaleCap;
        require(oldValue != presaleCap_, "Value is already set!");
        _presaleCap = presaleCap_;
        emit PresaleCapChanged(oldValue, presaleCap_);
        return true;
    }

    /// @notice Sets new block number on which presales phase one should start
    /// @dev This method should only be used in ongoing presale if something goes wrong
    /// @param firstStageBlockStart_ The block number on which crowdsales first phase will start
    /// @return default return True after everything is processed
    function setFirstStageBlockStart(uint firstStageBlockStart_) public onlyRole(MODERATOR_ROLE) override returns (bool) {
        uint oldValue = _firstStageBlockStart;
        require(oldValue != firstStageBlockStart_, "Value is already set!");
        _firstStageBlockStart = firstStageBlockStart_;
        emit FirstStageBlockStartChanged(oldValue, firstStageBlockStart_);
        return true;
    }
    /// @notice Sets new block on which presales first stage will end
    /// @dev This method should only be used in ongoing presale if something goes wrong
    /// @param firstStageBlockEnd_ The block number on which presales first stage will end
    /// @return default return True after everything is processed
    function setFirstStageBlockEnd(uint firstStageBlockEnd_) public onlyRole(MODERATOR_ROLE) override returns (bool) {
        uint oldValue = _firstStageBlockEnd;
        require(oldValue != firstStageBlockEnd_, "Value is already set!");
        _firstStageBlockEnd = firstStageBlockEnd_;
        emit FirstStageBlockEndChanged(oldValue, firstStageBlockEnd_);
        return true;
    }
    /// @notice Sets new amount of participants in first stage
    /// @dev This method should only be used in ongoing presale if something goes wrong
    /// @param firstStageMaxContributorCount_ The block number on which maxContribution limit is waived
    /// @return default return True after everything is processed
    function setFirstStageMaxContributorCount(uint firstStageMaxContributorCount_) public onlyRole(MODERATOR_ROLE) override returns (bool) {
        uint oldValue = _firstStageMaxContributorCount;
        require(oldValue != firstStageMaxContributorCount_, "Value is already set!");
        _firstStageMaxContributorCount = firstStageMaxContributorCount_;
        emit FirstStageMaxContributorCountChanged(oldValue, firstStageMaxContributorCount_);
        return true;
    }
    /// @notice Sets new amount of stablecoins that participant can contribute during first phase
    /// @dev This method should only be used in ongoing presale if something goes wrong
    /// @param firstStageMaxContribution_ The new cap on users contribution on first phase
    /// @return default return True after everything is processed
    function setFirstStageMaxContribution(uint firstStageMaxContribution_) public onlyRole(MODERATOR_ROLE) override returns (bool) {
        uint oldValue = _firstStageMaxContribution;
        require(oldValue != firstStageMaxContribution_, "Value is already set!");
        _firstStageMaxContribution = firstStageMaxContribution_;
        emit FirstStageMaxContributionChanged(oldValue, firstStageMaxContribution_);
        return true;
    }

    /// @notice Sets new block number on which presales phase two should start
    /// @dev This method should only be used in ongoing presale if something goes wrong
    /// @param secondStageBlockStart_ The block number on which crowdsales second phase will start
    /// @return default return True after everything is processed
    function setSecondStageBlockStart(uint secondStageBlockStart_) public onlyRole(MODERATOR_ROLE) override returns (bool) {
        uint oldValue = _secondStageBlockStart;
        require(oldValue != secondStageBlockStart_, "Value is already set!");
        _secondStageBlockStart = secondStageBlockStart_;
        emit SecondStageBlockStartChanged(oldValue, secondStageBlockStart_);
        return true;
    }
    /// @notice Sets new block on which presales second stage will end
    /// @dev This method should only be used in ongoing presale if something goes wrong
    /// @param secondStageBlockEnd_ The block number on which presales second stage will end
    /// @return default return True after everything is processed
    function setSecondStageBlockEnd(uint secondStageBlockEnd_) public onlyRole(MODERATOR_ROLE) override returns (bool) {
        uint oldValue = _secondStageBlockEnd;
        require(oldValue != secondStageBlockEnd_, "Value is already set!");
        _secondStageBlockEnd = secondStageBlockEnd_;
        emit SecondStageBlockEndChanged(oldValue, secondStageBlockEnd_);
        return true;
    }
    /// @notice Sets new amount of stablecoins that participant can contribute during first phase
    /// @dev This method should only be used in ongoing presale if something goes wrong
    /// @param secondStageMaxContribution_ The new cap on users contribution on first phase
    /// @return default return True after everything is processed
    function setSecondStageMaxContribution(uint secondStageMaxContribution_) public onlyRole(MODERATOR_ROLE) override returns (bool) {
        uint oldValue = _secondStageMaxContribution;
        require(oldValue != secondStageMaxContribution_, "Value is already set!");
        _secondStageMaxContribution = secondStageMaxContribution_;
        emit SecondStageMaxContributionChanged(oldValue, secondStageMaxContribution_);
        return true;
    }

    /// @notice Disables or enables ERC20 token that can be used by contributors
    /// @dev This method should only be used in ongoing presale if something goes wrong
    /// @param token_ The ERC20 token we want to edit
    /// @param option_ Option on what we want to do with the token, True - Enabled, False - disabled
    /// @return default return True after everything is processed
    function setTokenAllowed(address token_, bool option_) public onlyRole(MODERATOR_ROLE) override returns (bool) {
        bool oldValue = _allowedTokens[token_];
        require(oldValue != option_, "Value is already set!");
        _allowedTokens[token_] = option_;
        emit TokenAllowedChanged(oldValue, option_);
        return true;
    }

    /// @notice Sets new data contract address to be used internally
    /// @dev This method should only be used in ongoing presale if something goes wrong
    /// @param dataAddress_ Address of new DataContract
    /// @return default return True after everything is processed
    function setDataInstance(address dataAddress_) public onlyRole(MODERATOR_ROLE) override returns (bool) {
        address oldValue = address(_dataInstance);
        require(oldValue != dataAddress_, "Value is already set!");
        _dataInstance = DataInterface(dataAddress_);
        emit DataAddressChanged(oldValue, dataAddress_);
        return true;
    }
    /// @notice Sets new address on which contribution funds will be sent
    /// @dev This method should only be used in ongoing presale if something goes wrong
    /// @param corporateAddress_ New destination for funds
    /// @return default return True after everything is processed
    function setCorporateAddress(address corporateAddress_) public onlyRole(MODERATOR_ROLE) override returns (bool) {
        address oldValue = _corporateAddress;
        require(oldValue != corporateAddress_, "Value is already set!");
        _corporateAddress = corporateAddress_;
        emit CorporateAddressChanged(oldValue, corporateAddress_);
        return true;
    }

    // *************************************************
    // ************* DEFAULT_ADMIN REGION **************
    // *************************************************
    /// @notice Sets new role admin to the role defined
    /// @dev This method should only be used if some of priviliged keys are compromised, can only be done by defaultAdmin
    /// @param role_ Role that we want to change
    /// @param adminRole_ Role that will become new admin of the changed role
    /// @return default return True after everything is processed
    function setRoleAdmin(bytes32 role_, bytes32 adminRole_) public onlyRole(DEFAULT_ADMIN_ROLE) override returns (bool) {
        _setRoleAdmin(role_, adminRole_);
        emit AdminRoleSet(role_, adminRole_);
        return true;
    }
    /// @notice Transfer tokens from the contract to desiered address
    /// @dev This method should be used if users accedentaly sends tokens to our contract address
    /// @param tokenAddress_ Token address of the token that we want to salvage
    /// @param to_ Destination where salvaged tokens will be sent
    /// @param amount_ Amount of tokens we want to salvage
    /// @return default return True after everything is processed
    function salvageTokensFromContract(address tokenAddress_, address to_, uint amount_) public onlyRole(DEFAULT_ADMIN_ROLE) override returns (bool){
        IERC20(tokenAddress_).transfer(to_, amount_);
        emit TokensSalvaged(tokenAddress_, to_, amount_);
        return true;
    }
    /// @notice Destroys the contract
    /// @dev This method should NEVER be used if you don't know the implications!!!!!!!!
    /// @return default return True after everything is processed
    function killContract() public onlyRole(DEFAULT_ADMIN_ROLE) override returns (bool){
        emit ContractKilled();
        selfdestruct(payable(msg.sender));
        return true;
    }

    // **************************************************
    // ************* PUBLIC GETTERS REGION **************
    // **************************************************
    /// @notice Returns if presale is active or notActive
    function getPresaleActive() public view override returns (bool) {
        if (getFirstStageActive() || getSecondStageActive()) { return true; }
        return false;
    }
    /// @notice Returns if first stage of presale is active or notActive
    function getFirstStageActive() public view override returns (bool) {
        if (block.number < _firstStageBlockStart) { return false; }
        if (block.number > _firstStageBlockEnd) { return false; }
        if (_dataInstance.getParticipantCount() >= _firstStageMaxContributorCount ) { return false; }
        if (_dataInstance.getCombinedContributions() >= _presaleCap ) { return false; }
        return true;
    }
    /// @notice Returns if second stage presale is active or notActive
    function getSecondStageActive() public view override returns (bool) {
        if (block.number < _secondStageBlockStart) { return false; }
        if (block.number > _secondStageBlockEnd) { return false; }
        if (_dataInstance.getCombinedContributions() >= _presaleCap ) { return false; }
        return true;
    }

    /// @notice Returns the amount that participant can contribute depending on the state of presale while in first stage
    function getFirstStageParticipantMaxContribution(address participant_) public view override returns (uint) {
        uint maxContribution = _firstStageMaxContribution - _dataInstance.getParticipantContributions(participant_);
        uint tokensLeftTillCap = _presaleCap - _dataInstance.getCombinedContributions();
        if (tokensLeftTillCap < maxContribution) {
            return tokensLeftTillCap;
        }
        return maxContribution;
    }
    /// @notice Returns the amount that participant can contribute depending on the state of presale while in second stage
    function getSecondStageParticipantMaxContribution(address participant_) public view override returns (uint) {
        uint maxContribution = _secondStageMaxContribution - _dataInstance.getParticipantContributions(participant_);
        uint tokensLeftTillCap = _presaleCap - _dataInstance.getCombinedContributions();
        if (tokensLeftTillCap < maxContribution) {
            return tokensLeftTillCap;
        }
        return maxContribution;
    }

    /// @notice Returns the lowest ammount that user can contribute
    function getMinimumContributionRequierment() public view override returns (uint) {
        return _minimumContributionRequierment;
    }
    /// @notice Returns the amount of tokens that presale will recieve
    function getPresaleCap() public view override returns (uint) {
        return _presaleCap;
    }

    /// @notice Returns block which starts first phase of presale
    function getFirstStageBlockStart() public view override returns (uint) {
        return _firstStageBlockStart;
    }
    /// @notice Returns block which ends first phase of presale
    function getFirstStageBlockEnd() public view override returns (uint) {
        return _firstStageBlockEnd;
    }
    /// @notice Returns the maximum number of participants in first stage
    function getFirstStageMaxContributorCount() public view override returns (uint) {
        return _firstStageMaxContributorCount;
    }
    /// @notice Returns the maximum amount that users can contribute in first phase
    function getFirstStageMaxContribution() public view override returns (uint) {
        return _firstStageMaxContribution;
    }

    /// @notice Returns block which starts second phase of presale
    function getSecondStageBlockStart() public view override returns (uint) {
        return _secondStageBlockStart;
    }
    /// @notice Returns block which ends second phase of presale
    function getSecondStageBlockEnd() public view override returns (uint) {
        return _secondStageBlockEnd;
    }
    /// @notice Returns the maximum amount that users can contribute in second phase
    function getSecondStageMaxContribution() public view override returns (uint) {
        return _secondStageMaxContribution;
    }

    /// @notice Returns if token is allowed in presale
    function getTokenAllowed(address token_) public view override returns (bool) {
        return _allowedTokens[token_];
    }
    /// @notice Returns the address of data contract
    function getDataAddress() public view override returns (address) {
        return address(_dataInstance);
    }
    /// @notice Returns the address on which tokens will be sent
    function getCorporateAddress() public view override returns (address) {
        return _corporateAddress;
    }
}