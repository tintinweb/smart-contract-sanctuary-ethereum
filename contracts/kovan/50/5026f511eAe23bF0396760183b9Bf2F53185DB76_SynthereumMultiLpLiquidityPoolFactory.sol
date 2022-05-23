// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

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
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override(AccessControl, IAccessControl) {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {
  ISynthereumMultiLpLiquidityPool
} from './interfaces/IMultiLpLiquidityPool.sol';
import {
  ISynthereumMultiLpLiquidityPoolEvents
} from './interfaces/IMultiLpLiquidityPoolEvents.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableERC20
} from '../../tokens/interfaces/IMintableBurnableERC20.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumPriceFeed
} from '../../oracle/common/interfaces/IPriceFeed.sol';
import {
  ILendingManager
} from '../../lending-module/interfaces/ILendingManager.sol';
import {
  ILendingStorageManager
} from '../../lending-module/interfaces/ILendingStorageManager.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import {
  EnumerableSet
} from '../../../@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {PreciseUnitMath} from '../../base/utils/PreciseUnitMath.sol';
import {ERC2771Context} from '../../common/ERC2771Context.sol';
import {
  ReentrancyGuard
} from '../../../@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {
  AccessControlEnumerable,
  Context
} from '../../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 * @title Multi LP Synthereum pool
 */
contract SynthereumMultiLpLiquidityPool is
  ISynthereumMultiLpLiquidityPoolEvents,
  ISynthereumMultiLpLiquidityPool,
  ERC2771Context,
  ReentrancyGuard,
  AccessControlEnumerable
{
  using EnumerableSet for EnumerableSet.AddressSet;
  using PreciseUnitMath for uint256;
  using SafeERC20 for IStandardERC20;
  using SafeERC20 for IMintableBurnableERC20;
  using SafeERC20 for IERC20;

  struct PositionCache {
    // Address of the LP
    address lp;
    // Position of the LP
    LPPosition lpPosition;
  }

  struct ProfitOrLoss {
    // True if the LPs have a gain over users otherwise false
    bool isLpGain;
    // Amount of gain/loss of the LPs
    uint256 totalProfitOrLoss;
  }

  struct TempStorageArguments {
    // Actual price
    uint256 price;
    // Total actual collateral holded by users
    uint256 totalUserDeposits;
    // Total synthetic tokens of the pool
    uint256 totalSyntheticAsset;
    // Decimals of collateral
    uint8 decimals;
  }

  struct TempInterstArguments {
    uint256 totalCapacity;
    uint256 totalUtilization;
    uint256 capacityShare;
    uint256 utilizationShare;
    uint256 interest;
    uint256 remainingInterest;
    bool isTotCapacityNotZero;
    bool isTotUtilizationNotZero;
  }

  //----------------------------------------
  // Constants
  //----------------------------------------

  string public constant override typology = 'POOL';

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //----------------------------------------
  // Storage
  //----------------------------------------

  EnumerableSet.AddressSet internal registeredLPs;

  EnumerableSet.AddressSet internal activeLPs;

  mapping(address => LPPosition) internal lpPositions;

  uint256 internal totalSyntheticAsset;

  uint256 internal totalUserDeposits;

  uint256 internal fee;

  uint256 internal liquidationBonus;

  uint256 internal overCollateralRequirement;

  bytes32 internal priceIdentifier;

  string internal lendingModuleId;

  ISynthereumFinder internal finder;

  IMintableBurnableERC20 internal syntheticAsset;

  IStandardERC20 internal collateralAsset;

  uint8 internal collateralDecimals;

  uint8 internal poolVersion;

  bool internal isInitialized;

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  modifier isNotExpired(uint256 expirationTime) {
    require(block.timestamp <= expirationTime, 'Transaction expired');
    _;
  }

  /**
   * @notice Initialize pool
   * @param _params Params used for initialization (see InitializationParams struct)
   */
  function initialize(InitializationParams calldata _params)
    external
    override
    nonReentrant
  {
    require(!isInitialized, 'Pool already initialized');
    require(
      _params.overCollateralRequirement > 0,
      'Overcollateral requirement must be bigger than 0%'
    );

    uint8 collTokenDecimals = _params.collateralToken.decimals();
    require(collTokenDecimals <= 18, 'Collateral has more than 18 decimals');

    require(
      _params.syntheticToken.decimals() == 18,
      'Synthetic token has more or less than 18 decimals'
    );

    ISynthereumPriceFeed priceFeed =
      ISynthereumPriceFeed(
        _params.finder.getImplementationAddress(SynthereumInterfaces.PriceFeed)
      );
    require(
      priceFeed.isPriceSupported(_params.priceIdentifier),
      'Price identifier not supported'
    );

    finder = _params.finder;
    poolVersion = _params.version;
    collateralAsset = _params.collateralToken;
    collateralDecimals = collTokenDecimals;
    syntheticAsset = _params.syntheticToken;
    priceIdentifier = _params.priceIdentifier;
    overCollateralRequirement = _params.overCollateralRequirement;

    _setLiquidationReward(_params.liquidationReward);
    _setFee(_params.fee);
    _setLendingModule(_params.lendingModuleId);

    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, _params.roles.admin);
    _setupRole(MAINTAINER_ROLE, _params.roles.maintainer);

    isInitialized = true;
  }

  /**
   * @notice Register a liquidity provider to the LP's whitelist
   * @notice This can be called only by the maintainer
   * @param _lp Address of the LP
   */
  function registerLP(address _lp)
    external
    override
    nonReentrant
    onlyMaintainer
  {
    require(registeredLPs.add(_lp), 'LP already registered');
    emit RegisteredLp(_lp);
  }

  /**
   * @notice Add the Lp to the active list of the LPs and initialize collateral and overcollateralization
   * @notice Only a registered and inactive LP can call this function to add himself
   * @param _collateralAmount Collateral amount to deposit by the LP
   * @param _overCollateralization Overcollateralization to set by the LP
   * @return collateralDeposited Net collateral deposited in the LP position
   */
  function activateLP(uint256 _collateralAmount, uint256 _overCollateralization)
    external
    override
    nonReentrant
    returns (uint256 collateralDeposited)
  {
    address msgSender = _msgSender();

    require(isRegisteredLP(msgSender), 'Sender must be a registered LP');
    require(_collateralAmount > 0, 'No collateral deposited');
    require(
      _overCollateralization > overCollateralRequirement,
      'Overcollateralization must be bigger than Overcollateral requirement'
    );

    ISynthereumFinder synthFinder = finder;
    ILendingManager.ReturnValues memory lendingValues =
      _lendingDeposit(
        _getLendingManager(synthFinder),
        msgSender,
        collateralAsset,
        _collateralAmount
      );

    uint256 actualTotalUserDeposits = totalUserDeposits;
    (ProfitOrLoss memory profitOrLoss, PositionCache[] memory positionsCache) =
      _calculateNewPositions(
        lendingValues.poolInterest,
        _getPriceFeedRate(synthFinder, priceIdentifier),
        totalSyntheticAsset,
        actualTotalUserDeposits,
        collateralDecimals
      );

    totalUserDeposits = profitOrLoss.isLpGain
      ? actualTotalUserDeposits - profitOrLoss.totalProfitOrLoss
      : actualTotalUserDeposits + profitOrLoss.totalProfitOrLoss;

    _updateActualLPCollateral(positionsCache);

    collateralDeposited = lendingValues.tokensOut;
    lpPositions[msgSender] = LPPosition(
      collateralDeposited,
      0,
      _overCollateralization
    );

    require(activeLPs.add(msgSender), 'LP already active');

    emit ActivatedLP(msgSender);
    emit DepositedLiquidity(msgSender, _collateralAmount, collateralDeposited);
    emit SetOvercollateralization(msgSender, _overCollateralization);
  }

  /**
   * @notice Add collateral to an active LP position
   * @notice Only an active LP can call this function to add collateral to his position
   * @param _collateralAmount Collateral amount to deposit by the LP
   * @return collateralDeposited Net collateral deposited in the LP position
   */
  function addLiquidity(uint256 _collateralAmount)
    external
    override
    nonReentrant
    returns (uint256 collateralDeposited)
  {
    address msgSender = _msgSender();

    require(_collateralAmount > 0, 'No collateral deposited');
    require(isActiveLP(msgSender), 'Sender must be an active LP');

    ISynthereumFinder synthFinder = finder;
    ILendingManager.ReturnValues memory lendingValues =
      _lendingDeposit(
        _getLendingManager(synthFinder),
        msgSender,
        collateralAsset,
        _collateralAmount
      );

    TempStorageArguments memory tempStorage =
      TempStorageArguments(
        _getPriceFeedRate(synthFinder, priceIdentifier),
        totalUserDeposits,
        totalSyntheticAsset,
        collateralDecimals
      );

    (ProfitOrLoss memory profitOrLoss, PositionCache[] memory positionsCache) =
      _calculateNewPositions(
        lendingValues.poolInterest,
        tempStorage.price,
        tempStorage.totalSyntheticAsset,
        tempStorage.totalUserDeposits,
        tempStorage.decimals
      );

    totalUserDeposits = profitOrLoss.isLpGain
      ? tempStorage.totalUserDeposits - profitOrLoss.totalProfitOrLoss
      : tempStorage.totalUserDeposits + profitOrLoss.totalProfitOrLoss;

    collateralDeposited = lendingValues.tokensOut;
    _updateAndModifyActualLPCollateral(
      positionsCache,
      msgSender,
      true,
      collateralDeposited,
      tempStorage.price,
      tempStorage.decimals
    );

    emit DepositedLiquidity(msgSender, _collateralAmount, collateralDeposited);
  }

  /**
   * @notice Withdraw collateral from an active LP position
   * @notice Only an active LP can call this function to withdraw collateral from his position
   * @param _collateralAmount Collateral amount to withdraw by the LP
   * @param collateralWithdrawn Net collateral withdrawn from the LP position
   */
  function removeLiquidity(uint256 _collateralAmount)
    external
    override
    nonReentrant
    returns (uint256 collateralWithdrawn)
  {
    address msgSender = _msgSender();

    require(isActiveLP(msgSender), 'Sender must be an active LP');
    require(_collateralAmount > 0, 'No collateral deposited');

    ISynthereumFinder synthFinder = finder;
    ILendingManager.ReturnValues memory lendingValues =
      _lendingWithdraw(
        _getLendingManager(synthFinder),
        msgSender,
        _collateralAmount,
        true
      );

    TempStorageArguments memory tempStorage =
      TempStorageArguments(
        _getPriceFeedRate(synthFinder, priceIdentifier),
        totalUserDeposits,
        totalSyntheticAsset,
        collateralDecimals
      );

    (ProfitOrLoss memory profitOrLoss, PositionCache[] memory positionsCache) =
      _calculateNewPositions(
        lendingValues.poolInterest,
        tempStorage.price,
        tempStorage.totalSyntheticAsset,
        tempStorage.totalUserDeposits,
        tempStorage.decimals
      );

    totalUserDeposits = profitOrLoss.isLpGain
      ? tempStorage.totalUserDeposits - profitOrLoss.totalProfitOrLoss
      : tempStorage.totalUserDeposits + profitOrLoss.totalProfitOrLoss;

    collateralWithdrawn = lendingValues.tokensOut;
    _updateAndModifyActualLPCollateral(
      positionsCache,
      msgSender,
      false,
      collateralWithdrawn,
      tempStorage.price,
      tempStorage.decimals
    );

    emit WithdrawnLiquidity(msgSender, _collateralAmount, collateralWithdrawn);
  }

  /**
   * @notice Set the overCollateralization by an active LP
   * @notice This can be called only by an active LP
   * @param _overCollateralization New overCollateralizations
   */
  function setOvercollateralization(uint256 _overCollateralization)
    external
    override
    nonReentrant
  {
    address msgSender = _msgSender();

    require(isActiveLP(msgSender), 'Sender must be an active LP');

    require(
      _overCollateralization > overCollateralRequirement,
      'Overcollateralization must be bigger than Overcollateral requirement'
    );

    ISynthereumFinder synthFinder = finder;
    ILendingManager.ReturnValues memory lendingValues =
      _getLendingManager(synthFinder).updateAccumulatedInterest();

    TempStorageArguments memory tempStorage =
      TempStorageArguments(
        _getPriceFeedRate(synthFinder, priceIdentifier),
        totalUserDeposits,
        totalSyntheticAsset,
        collateralDecimals
      );

    (ProfitOrLoss memory profitOrLoss, PositionCache[] memory positionsCache) =
      _calculateNewPositions(
        lendingValues.poolInterest,
        tempStorage.price,
        tempStorage.totalSyntheticAsset,
        tempStorage.totalUserDeposits,
        tempStorage.decimals
      );

    totalUserDeposits = profitOrLoss.isLpGain
      ? tempStorage.totalUserDeposits - profitOrLoss.totalProfitOrLoss
      : tempStorage.totalUserDeposits + profitOrLoss.totalProfitOrLoss;

    _updateAndModifyActualLPOverCollateral(
      positionsCache,
      msgSender,
      _overCollateralization,
      tempStorage.price,
      tempStorage.decimals
    );

    emit SetOvercollateralization(msgSender, _overCollateralization);
  }

  /**
   * @notice Mint synthetic tokens using fixed amount of collateral
   * @notice This calculate the price using on chain price feed
   * @notice User must approve collateral transfer for the mint request to succeed
   * @param _mintParams Input parameters for minting (see MintParams struct)
   * @return Amount of synthetic tokens minted by a user
   * @return Amount of collateral paid by the user as fee
   */
  function mint(MintParams calldata _mintParams)
    external
    override
    nonReentrant
    isNotExpired(_mintParams.expiration)
    returns (uint256, uint256)
  {
    address msgSender = _msgSender();

    require(_mintParams.collateralAmount > 0, 'No collateral sent');

    ISynthereumFinder synthFinder = finder;
    ILendingManager.ReturnValues memory lendingValues =
      _lendingDeposit(
        _getLendingManager(synthFinder),
        msgSender,
        collateralAsset,
        _mintParams.collateralAmount
      );

    TempStorageArguments memory tempStorage =
      TempStorageArguments(
        _getPriceFeedRate(synthFinder, priceIdentifier),
        totalUserDeposits,
        totalSyntheticAsset,
        collateralDecimals
      );

    (ProfitOrLoss memory profitOrLoss, PositionCache[] memory positionsCache) =
      _calculateNewPositions(
        lendingValues.poolInterest,
        tempStorage.price,
        tempStorage.totalSyntheticAsset,
        tempStorage.totalUserDeposits,
        tempStorage.decimals
      );

    MintValues memory mintValues =
      _calculateMint(
        lendingValues.tokensOut,
        tempStorage.price,
        tempStorage.decimals
      );

    totalUserDeposits = profitOrLoss.isLpGain
      ? tempStorage.totalUserDeposits -
        profitOrLoss.totalProfitOrLoss +
        mintValues.exchangeAmount
      : tempStorage.totalUserDeposits +
        profitOrLoss.totalProfitOrLoss +
        mintValues.exchangeAmount;

    require(
      mintValues.numTokens >= _mintParams.minNumTokens,
      'Number of tokens less than minimum limit'
    );

    _calculateMintTokensAndFee(
      mintValues,
      tempStorage.price,
      tempStorage.decimals,
      positionsCache
    );

    _updateActualLPPositions(positionsCache);

    totalSyntheticAsset =
      tempStorage.totalSyntheticAsset +
      mintValues.numTokens;

    syntheticAsset.mint(_mintParams.recipient, mintValues.numTokens);

    mintValues.totalCollateral = _mintParams.collateralAmount;

    emit Mint(msgSender, mintValues, _mintParams.recipient);

    return (mintValues.numTokens, mintValues.feeAmount);
  }

  /**
   * @notice Redeem amount of collateral using fixed number of synthetic token
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param _redeemParams Input parameters for redeeming (see RedeemParams struct)
   * @return Amount of collateral redeemed by user
   * @return Amount of collateral paid by user as fee
   */
  function redeem(RedeemParams calldata _redeemParams)
    external
    override
    nonReentrant
    isNotExpired(_redeemParams.expiration)
    returns (uint256, uint256)
  {
    address msgSender = _msgSender();

    require(_redeemParams.numTokens > 0, 'Sending tokens amount is equal to 0');

    ISynthereumFinder synthFinder = finder;

    TempStorageArguments memory tempStorage =
      TempStorageArguments(
        _getPriceFeedRate(synthFinder, priceIdentifier),
        totalUserDeposits,
        totalSyntheticAsset,
        collateralDecimals
      );

    RedeemValues memory redeemValues =
      _calculateRedeem(
        _redeemParams.numTokens,
        tempStorage.price,
        tempStorage.decimals
      );

    ILendingManager.ReturnValues memory lendingValues =
      _lendingWithdraw(
        _getLendingManager(synthFinder),
        _redeemParams.recipient,
        redeemValues.collateralAmount,
        false
      );

    (ProfitOrLoss memory profitOrLoss, PositionCache[] memory positionsCache) =
      _calculateNewPositions(
        lendingValues.poolInterest,
        tempStorage.price,
        tempStorage.totalSyntheticAsset,
        tempStorage.totalUserDeposits,
        tempStorage.decimals
      );

    totalUserDeposits = profitOrLoss.isLpGain
      ? tempStorage.totalUserDeposits -
        profitOrLoss.totalProfitOrLoss -
        redeemValues.exchangeAmount
      : tempStorage.totalUserDeposits +
        profitOrLoss.totalProfitOrLoss -
        redeemValues.exchangeAmount;

    require(
      lendingValues.tokensTransferred >= _redeemParams.minCollateral,
      'Collateral amount less than minimum limit'
    );

    _calculateRedeemTokensAndFee(
      tempStorage.totalSyntheticAsset,
      _redeemParams.numTokens,
      redeemValues.feeAmount,
      positionsCache
    );

    _updateActualLPPositions(positionsCache);

    totalSyntheticAsset =
      tempStorage.totalSyntheticAsset -
      _redeemParams.numTokens;

    _burnSyntheticTokens(syntheticAsset, _redeemParams.numTokens, msgSender);

    redeemValues.collateralAmount = lendingValues.tokensTransferred;

    emit Redeem(msgSender, redeemValues, _redeemParams.recipient);

    return (redeemValues.collateralAmount, redeemValues.feeAmount);
  }

  /**
   * @notice Liquidate Lp position for an amount of synthetic tokens undercollateralized
   * @notice Revert if position is not undercollateralized
   * @param _lp LP that the the user wants to liquidate
   * @param _numSynthTokens Number of synthetic tokens that user wants to liquidate
   * @return Amount of collateral received (Amount of collateral + bonus)
   */
  function liquidate(address _lp, uint256 _numSynthTokens)
    external
    override
    nonReentrant
    returns (uint256)
  {
    address msgSender = _msgSender();

    require(isActiveLP(_lp), 'LP is not active');
    require(_numSynthTokens > 0, 'No synthetic tokens deposited');

    ISynthereumFinder synthFinder = finder;

    TempStorageArguments memory tempStorage =
      TempStorageArguments(
        _getPriceFeedRate(synthFinder, priceIdentifier),
        totalUserDeposits,
        totalSyntheticAsset,
        collateralDecimals
      );

    ILendingManager lendingManager = _getLendingManager(synthFinder);

    (uint256 poolInterest, ) = _getLendingInterest(lendingManager);

    (ProfitOrLoss memory profitOrLoss, PositionCache[] memory positionsCache) =
      _calculateNewPositions(
        poolInterest,
        tempStorage.price,
        tempStorage.totalSyntheticAsset,
        tempStorage.totalUserDeposits,
        tempStorage.decimals
      );

    (
      uint256 tokensInLiquidation,
      uint256 collateralAmount,
      uint256 bonusAmount
    ) =
      _updateAndLiquidate(
        positionsCache,
        _lp,
        _numSynthTokens,
        tempStorage.price,
        tempStorage.decimals,
        overCollateralRequirement
      );

    totalUserDeposits = profitOrLoss.isLpGain
      ? tempStorage.totalUserDeposits -
        profitOrLoss.totalProfitOrLoss -
        collateralAmount
      : tempStorage.totalUserDeposits +
        profitOrLoss.totalProfitOrLoss -
        collateralAmount;

    ILendingManager.ReturnValues memory lendingValues =
      _lendingWithdraw(
        lendingManager,
        msgSender,
        collateralAmount + bonusAmount,
        false
      );

    _burnSyntheticTokens(syntheticAsset, tokensInLiquidation, msgSender);

    uint256 collateralReceived = lendingValues.tokensTransferred;

    emit Liquidate(
      msgSender,
      tokensInLiquidation,
      collateralAmount,
      collateralReceived
    );

    return collateralReceived;
  }

  /**
   * @notice Update interests and positions ov every LP
   * @notice Everyone can call this function
   */
  function updatePositions() external override nonReentrant {
    ISynthereumFinder synthFinder = finder;
    ILendingManager.ReturnValues memory lendingValues =
      _getLendingManager(synthFinder).updateAccumulatedInterest();

    TempStorageArguments memory tempStorage =
      TempStorageArguments(
        _getPriceFeedRate(synthFinder, priceIdentifier),
        totalUserDeposits,
        totalSyntheticAsset,
        collateralDecimals
      );

    (ProfitOrLoss memory profitOrLoss, PositionCache[] memory positionsCache) =
      _calculateNewPositions(
        lendingValues.poolInterest,
        tempStorage.price,
        tempStorage.totalSyntheticAsset,
        tempStorage.totalUserDeposits,
        tempStorage.decimals
      );

    totalUserDeposits = profitOrLoss.isLpGain
      ? tempStorage.totalUserDeposits - profitOrLoss.totalProfitOrLoss
      : tempStorage.totalUserDeposits + profitOrLoss.totalProfitOrLoss;

    _updateActualLPPositions(positionsCache);
  }

  /**
   * @notice Transfer a bearing amount to the lending manager
   * @notice Only the lending manager can call the function
   * @param _bearingAmount Amount of bearing token to transfer
   */
  function transferToLendingManager(uint256 _bearingAmount) external override {
    ILendingManager lendingManager = _getLendingManager(finder);
    require(
      msg.sender == address(lendingManager),
      'Sender must be lending manager'
    );

    (uint256 poolInterest, uint256 totalActualCollateral) =
      _getLendingInterest(lendingManager);

    (uint256 poolBearingValue, address bearingToken) =
      lendingManager.collateralToInterestToken(
        address(this),
        totalActualCollateral + poolInterest,
        true
      );

    IERC20 bearingCurrency = IERC20(bearingToken);
    bearingCurrency.safeTransfer(msg.sender, _bearingAmount);

    uint256 remainingBearingValue = bearingCurrency.balanceOf(address(this));
    require(remainingBearingValue >= poolBearingValue, 'Unfunded pool');
  }

  /**
   * @notice Set new liquidation reward percentage
   * @notice This can be called only by the maintainer
   * @param _newLiquidationReward New liquidation reward percentage
   */
  function setLiquidationReward(uint256 _newLiquidationReward)
    external
    override
    nonReentrant
    onlyMaintainer
  {
    _setLiquidationReward(_newLiquidationReward);
  }

  /**
   * @notice Set new fee percentage
   * @notice This can be called only by the maintainer
   * @param _newFee New fee percentage
   */
  function setFee(uint256 _newFee)
    external
    override
    nonReentrant
    onlyMaintainer
  {
    _setFee(_newFee);
  }

  /**
   * @notice Set new lending protocol for this pool
   * @notice This can be called only by the maintainer
   * @param _lendingId Name of the new lending module
   * @param _bearingToken Token of the lending mosule to be used for intersts accrual
            (used only if the lending manager doesn't automatically find the one associated to the collateral fo this pool)
   */
  function switchLendingModule(
    string calldata _lendingId,
    address _bearingToken
  ) external nonReentrant onlyMaintainer {
    ISynthereumFinder synthFinder = finder;
    ILendingManager.MigrateReturnValues memory migrationValues =
      _lendingMigration(
        _getLendingManager(synthFinder),
        _getLendingStorageManager(synthFinder),
        _lendingId,
        _bearingToken
      );

    TempStorageArguments memory tempStorage =
      TempStorageArguments(
        _getPriceFeedRate(synthFinder, priceIdentifier),
        totalUserDeposits,
        totalSyntheticAsset,
        collateralDecimals
      );

    (ProfitOrLoss memory profitOrLoss, PositionCache[] memory positionsCache) =
      _calculateNewPositions(
        migrationValues.poolInterest,
        tempStorage.price,
        tempStorage.totalSyntheticAsset,
        tempStorage.totalUserDeposits,
        tempStorage.decimals
      );

    uint256 actualUserDeposits =
      profitOrLoss.isLpGain
        ? tempStorage.totalUserDeposits - profitOrLoss.totalProfitOrLoss
        : tempStorage.totalUserDeposits + profitOrLoss.totalProfitOrLoss;
    totalUserDeposits = actualUserDeposits;

    _calculateLendingModuleCollateral(
      actualUserDeposits,
      migrationValues,
      positionsCache
    );

    _updateActualLPPositions(positionsCache);

    _setLendingModule(_lendingId);
  }

  /**
   * @notice Get all the registered LPs of this pool
   * @return The list of addresses of all the registered LPs in the pool.
   */
  function getRegisteredLPs()
    external
    view
    override
    returns (address[] memory)
  {
    uint256 numberOfLPs = registeredLPs.length();
    address[] memory lpList = new address[](numberOfLPs);
    for (uint256 j = 0; j < numberOfLPs; j++) {
      lpList[j] = registeredLPs.at(j);
    }
    return lpList;
  }

  /**
   * @notice Get all the active LPs of this pool
   * @return The list of addresses of all the active LPs in the pool.
   */
  function getActiveLPs() external view override returns (address[] memory) {
    uint256 numberOfLPs = activeLPs.length();
    address[] memory lpList = new address[](numberOfLPs);
    for (uint256 j = 0; j < numberOfLPs; j++) {
      lpList[j] = activeLPs.at(j);
    }
    return lpList;
  }

  /**
   * @notice Returns total number of synthetic tokens generated by this pool
   * @return Number of synthetic tokens
   */
  function totalSyntheticTokens() external view override returns (uint256) {
    return totalSyntheticAsset;
  }

  /**
   * @notice Returns the total amounts of collateral
   * @return usersCollateral Total collateral amount currently holded by users
   * @return lpsCollateral Total collateral amount currently holded by LPs
   * @return totalCollateral Total collateral amount currently holded by users + LPs
   */
  function totalCollateralAmount()
    external
    view
    override
    returns (
      uint256 usersCollateral,
      uint256 lpsCollateral,
      uint256 totalCollateral
    )
  {
    ISynthereumFinder synthFinder = finder;
    usersCollateral = _calculateCollateralAmount(
      totalSyntheticAsset,
      _getPriceFeedRate(synthFinder, priceIdentifier),
      collateralDecimals
    );

    (uint256 poolInterest, uint256 totalActualCollateral) =
      _getLendingInterest(_getLendingManager(synthFinder));

    totalCollateral = totalActualCollateral + poolInterest;

    lpsCollateral = totalCollateral - usersCollateral;
  }

  /**
   * @notice Returns the total available liquidity of the LPs
   * @return totalLiquidity Total available liquidity for minting operation
   */
  function totalAvailableLiquidity()
    external
    view
    override
    returns (uint256 totalLiquidity)
  {
    ISynthereumFinder synthFinder = finder;
    uint256 price = _getPriceFeedRate(synthFinder, priceIdentifier);

    (uint256 poolInterest, ) =
      _getLendingInterest(_getLendingManager(synthFinder));

    uint8 decimals = collateralDecimals;
    (, PositionCache[] memory positionsCache) =
      _calculateNewPositions(
        poolInterest,
        price,
        totalSyntheticAsset,
        totalUserDeposits,
        decimals
      );

    LPPosition memory lpPosition;
    for (uint256 j = 0; j < positionsCache.length; j++) {
      lpPosition = positionsCache[j].lpPosition;
      uint256 lpLiquidity =
        _calculateCapacity(
          lpPosition.actualCollateralAmount,
          lpPosition.tokensCollateralized,
          lpPosition.overCollateralization,
          price,
          decimals
        );
      totalLiquidity += lpLiquidity;
    }
  }

  /**
   * @notice Returns the LP parametrs info
   * @return info Info of the input lp (see LPInfo struct)
   */
  function positionLPInfo(address _lp)
    external
    view
    override
    returns (LPInfo memory info)
  {
    require(isActiveLP(_lp), 'LP not active');

    ISynthereumFinder synthFinder = finder;
    uint256 price = _getPriceFeedRate(synthFinder, priceIdentifier);

    (uint256 poolInterest, ) =
      _getLendingInterest(_getLendingManager(synthFinder));

    uint256 totalSynthTokens = totalSyntheticAsset;

    uint8 decimals = collateralDecimals;
    (, PositionCache[] memory positionsCache) =
      _calculateNewPositions(
        poolInterest,
        price,
        totalSynthTokens,
        totalUserDeposits,
        decimals
      );

    uint256 overCollateralLimit = overCollateralRequirement;

    uint256[] memory capacityShares = new uint256[](positionsCache.length);
    uint256 totalCapacity =
      _calculateMintShares(
        price,
        collateralDecimals,
        positionsCache,
        capacityShares
      );

    LPPosition memory lpPosition;
    uint256 tokensValue;
    for (uint256 j = 0; j < positionsCache.length; j++) {
      if (positionsCache[j].lp == _lp) {
        lpPosition = positionsCache[j].lpPosition;
        info.actualCollateralAmount = lpPosition.actualCollateralAmount;
        info.tokensCollateralized = lpPosition.tokensCollateralized;
        info.overCollateralization = lpPosition.overCollateralization;
        info.availableLiquidity = capacityShares[j];
        tokensValue = _calculateCollateralAmount(
          lpPosition.tokensCollateralized,
          price,
          decimals
        );
        info.utilization = lpPosition.actualCollateralAmount != 0
          ? (tokensValue.mul(lpPosition.overCollateralization)).div(
            lpPosition.actualCollateralAmount
          )
          : lpPosition.tokensCollateralized > 0
          ? PreciseUnitMath.PRECISE_UNIT
          : 0;
        info.coverage = tokensValue != 0
          ? PreciseUnitMath.PRECISE_UNIT +
            (
              overCollateralLimit.mul(
                lpPosition.actualCollateralAmount.div(
                  tokensValue.mul(overCollateralLimit)
                )
              )
            )
          : lpPosition.actualCollateralAmount == 0
          ? 0
          : PreciseUnitMath.maxUint256();
        info.mintShares = totalCapacity != 0
          ? capacityShares[j].div(totalCapacity)
          : 0;
        info.redeemShares = totalSynthTokens != 0
          ? lpPosition.tokensCollateralized.div(totalSynthTokens)
          : 0;
        info.isOvercollateralized = _isOvercollateralizedLP(
          lpPosition.actualCollateralAmount,
          overCollateralLimit,
          tokensValue
        );
        return info;
      }
    }
  }

  /**
   * @notice Returns the lending protocol info
   * @return lendingId Name of the lending module
   * @return bearingToken Address of the bearing token held by the pool for interest accrual
   */
  function lendingProtocolInfo()
    external
    view
    returns (string memory lendingId, address bearingToken)
  {
    lendingId = lendingModuleId;
    bearingToken = _getLendingStorageManager(finder).getInterestBearingToken(
      address(this)
    );
  }

  /**
   * @notice Get Synthereum finder of the pool
   * @return Finder contract
   */
  function synthereumFinder()
    external
    view
    override
    returns (ISynthereumFinder)
  {
    return finder;
  }

  /**
   * @notice Get Synthereum version
   * @return The version of this pool
   */
  function version() external view override returns (uint8) {
    return poolVersion;
  }

  /**
   * @notice Get the collateral token of this pool
   * @return The ERC20 collateral token
   */
  function collateralToken() external view override returns (IERC20) {
    return collateralAsset;
  }

  /**
   * @notice Get the decimals of the collateral
   * @return Number of decimals of the collateral
   */
  function collateralTokenDecimals() external view override returns (uint8) {
    return collateralDecimals;
  }

  /**
   * @notice Get the synthetic token associated to this pool
   * @return The ERC20 synthetic token
   */
  function syntheticToken() external view override returns (IERC20) {
    return syntheticAsset;
  }

  /**
   * @notice Get the synthetic token symbol associated to this pool
   * @return The ERC20 synthetic token symbol
   */
  function syntheticTokenSymbol()
    external
    view
    override
    returns (string memory)
  {
    return IStandardERC20(address(syntheticAsset)).symbol();
  }

  /**
   * @notice Returns the percentage of overcollateralization to which a liquidation can triggered
   * @return Thresold percentage on a liquidation can be triggered
   */
  function collateralRequirement() external view override returns (uint256) {
    return PreciseUnitMath.PRECISE_UNIT + overCollateralRequirement;
  }

  /**
   * @notice Returns the percentage of reward for correct liquidation by a liquidator
   * @return Percentage of reward
   */
  function liquidationReward() external view override returns (uint256) {
    return liquidationBonus;
  }

  /**
   * @notice Returns price identifier of the pool
   * @return Price identifier
   */
  function priceFeedIdentifier() external view override returns (bytes32) {
    return priceIdentifier;
  }

  /**
   * @notice Returns fee percentage of the pool
   * @return Fee percentage
   */
  function feePercentage() external view override returns (uint256) {
    return fee;
  }

  /**
   * @notice Check if the input LP is registered
   * @param _lp Address of the LP
   * @return Return true if the LP is regitered, otherwise false
   */
  function isRegisteredLP(address _lp) public view override returns (bool) {
    return registeredLPs.contains(_lp);
  }

  /**
   * @notice Check if the input LP is active
   * @param _lp Address of the LP
   * @return Return true if the LP is active, otherwise false
   */
  function isActiveLP(address _lp) public view override returns (bool) {
    return activeLPs.contains(_lp);
  }

  /**
   * @notice Set new fee percentage
   * @param _newFee New fee percentage
   */
  function _setFee(uint256 _newFee) internal {
    require(
      _newFee < PreciseUnitMath.PRECISE_UNIT,
      'Fee Percentage must be less than 100%'
    );
    fee = _newFee;
    emit SetFeePercentage(_newFee);
  }

  /**
   * @notice Set new lending module name
   * @param _lendingModuleId Lending module name
   */
  function _setLendingModule(string calldata _lendingModuleId) internal {
    lendingModuleId = _lendingModuleId;
    emit NewLendingModule(_lendingModuleId);
  }

  /**
   * @notice Set new liquidation reward percentage
   * @param _newLiquidationReward New liquidation reward percentage
   */
  function _setLiquidationReward(uint256 _newLiquidationReward) internal {
    require(
      _newLiquidationReward > 0 &&
        _newLiquidationReward <= PreciseUnitMath.PRECISE_UNIT,
      'Liquidation reward must be between 0 and 100%'
    );
    liquidationBonus = _newLiquidationReward;
    emit SetLiquidationReward(_newLiquidationReward);
  }

  /**
   * @notice Deposit collateral to the lending manager
   * @param _lendingManager Addres of lendingManager
   * @param _msgSender User/LP depositing
   * @param _collateralAsset Collateral token of the pool
   * @param _collateralAmount Amount of collateral to deposit
   * @return Return values parameters from lending manager
   */
  function _lendingDeposit(
    ILendingManager _lendingManager,
    address _msgSender,
    IStandardERC20 _collateralAsset,
    uint256 _collateralAmount
  ) internal returns (ILendingManager.ReturnValues memory) {
    _collateralAsset.safeTransferFrom(
      _msgSender,
      address(_lendingManager),
      _collateralAmount
    );

    return _lendingManager.deposit(_collateralAmount, address(this));
  }

  /**
   * @notice Withdraw collateral from the lending manager
   * @param _lendingManager Addres of lendingManager
   * @param _recipient Recipient to which collateral is sent
   * @param _collateralAmount Gross/net collateral to withdraw
   * @param _isExactTransfer True if _collateralAmount is the exact collateral withdrawn,
   * otherwise false if _collateralAmount is the value in collateral sent to the lending manager
   * @return Return values parameters from lending manager
   */
  function _lendingWithdraw(
    ILendingManager _lendingManager,
    address _recipient,
    uint256 _collateralAmount,
    bool _isExactTransfer
  ) internal returns (ILendingManager.ReturnValues memory) {
    (uint256 bearingAmount, address bearingToken) =
      _lendingManager.collateralToInterestToken(
        address(this),
        _collateralAmount,
        _isExactTransfer
      );
    IERC20(bearingToken).safeTransfer(address(_lendingManager), bearingAmount);
    return _lendingManager.withdraw(bearingAmount, _recipient);
  }

  /**
   * @notice Migrate lending module protocol
   * @param _lendingManager Addres of lendingManager
   * @param _lendingStorageManager Addres of lendingStoarageManager
   * @param  _lendingId Name of the new lending protocol to migrate to
   * @param  _bearingToken Bearing token of the new lending protocol to switch (only if requetsed by the protocol)
   * @return Return migration values parameters from lending manager
   */
  function _lendingMigration(
    ILendingManager _lendingManager,
    ILendingStorageManager _lendingStorageManager,
    string calldata _lendingId,
    address _bearingToken
  ) internal returns (ILendingManager.MigrateReturnValues memory) {
    IERC20 actualBearingToken =
      IERC20(_lendingStorageManager.getInterestBearingToken(address(this)));
    uint256 actualBearingAmount = actualBearingToken.balanceOf(address(this));
    actualBearingToken.safeTransfer(
      address(_lendingManager),
      actualBearingAmount
    );
    return
      _lendingManager.migrateLendingModule(
        _lendingId,
        _bearingToken,
        actualBearingAmount
      );
  }

  /**
   * @notice Update collateral amount of every LP
   * @param _positionsCache Temporary memory cache containing LPs positions
   */
  function _updateActualLPCollateral(PositionCache[] memory _positionsCache)
    internal
  {
    PositionCache memory lpCache;
    for (uint256 j = 0; j < _positionsCache.length; j++) {
      lpCache = _positionsCache[j];
      lpPositions[lpCache.lp].actualCollateralAmount = lpCache
        .lpPosition
        .actualCollateralAmount;
    }
  }

  /**
   * @notice Update collateral amount and synthetic assets of every LP
   * @param _positionsCache Temporary memory cache containing LPs positions
   */
  function _updateActualLPPositions(PositionCache[] memory _positionsCache)
    internal
  {
    PositionCache memory lpCache;
    LPPosition memory lpPosition;
    for (uint256 j = 0; j < _positionsCache.length; j++) {
      lpCache = _positionsCache[j];
      lpPosition = lpCache.lpPosition;
      lpPositions[lpCache.lp].actualCollateralAmount = lpPosition
        .actualCollateralAmount;
      lpPositions[lpCache.lp].tokensCollateralized = lpPosition
        .tokensCollateralized;
    }
  }

  /**
   * @notice Update collateral amount of every LP and add the new deposit for one LP
   * @param _positionsCache Temporary memory cache containing LPs positions
   * @param _depositingLp Address of the LP depositing collateral
   * @param _isIncreased True if collateral to add for the LP, otherwise false
   * @param _changingCollateral Amount of collateral to increase/decrease to/from the LP
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   */
  function _updateAndModifyActualLPCollateral(
    PositionCache[] memory _positionsCache,
    address _depositingLp,
    bool _isIncreased,
    uint256 _changingCollateral,
    uint256 _price,
    uint8 _collateralDecimals
  ) internal {
    PositionCache memory lpCache;
    address lp;
    LPPosition memory lpPosition;
    uint256 actualCollateralAmount;
    uint256 newCollateralAmount;
    for (uint256 j = 0; j < _positionsCache.length; j++) {
      lpCache = _positionsCache[j];
      lp = lpCache.lp;
      lpPosition = _positionsCache[j].lpPosition;
      actualCollateralAmount = lpPosition.actualCollateralAmount;
      if (lp == _depositingLp) {
        if (_isIncreased) {
          lpPositions[lp].actualCollateralAmount =
            actualCollateralAmount +
            _changingCollateral;
        } else {
          newCollateralAmount = actualCollateralAmount - _changingCollateral;
          require(
            _isOvercollateralizedLP(
              newCollateralAmount,
              lpPosition.overCollateralization,
              _calculateCollateralAmount(
                lpPosition.tokensCollateralized,
                _price,
                _collateralDecimals
              )
            ),
            'LP is undercollateralized'
          );
          lpPositions[lp].actualCollateralAmount = newCollateralAmount;
        }
      } else {
        lpPositions[lp].actualCollateralAmount = actualCollateralAmount;
      }
    }
  }

  /**
   * @notice Update collateral amount of every LP and change overcollateralization for one LP
   * @param _positionsCache Temporary memory cache containing LPs positions
   * @param _lp Address of the LP changing overcollateralization
   * @param _newOverCollateralization New overcollateralization to be set for the LP
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   */
  function _updateAndModifyActualLPOverCollateral(
    PositionCache[] memory _positionsCache,
    address _lp,
    uint256 _newOverCollateralization,
    uint256 _price,
    uint8 _collateralDecimals
  ) internal {
    PositionCache memory lpCache;
    address lp;
    LPPosition memory lpPosition;
    uint256 actualCollateralAmount;
    for (uint256 j = 0; j < _positionsCache.length; j++) {
      lpCache = _positionsCache[j];
      lp = lpCache.lp;
      lpPosition = _positionsCache[j].lpPosition;
      actualCollateralAmount = lpPosition.actualCollateralAmount;
      if (lp == _lp) {
        require(
          _isOvercollateralizedLP(
            actualCollateralAmount,
            _newOverCollateralization,
            _calculateCollateralAmount(
              lpPosition.tokensCollateralized,
              _price,
              _collateralDecimals
            )
          ),
          'LP is undercollateralized'
        );
        lpPositions[lp].actualCollateralAmount = actualCollateralAmount;
        lpPositions[lp].overCollateralization = _newOverCollateralization;
      } else {
        lpPositions[lp].actualCollateralAmount = actualCollateralAmount;
      }
    }
  }

  /**
   * @notice Update collateral amount of every LP and add the new deposit for one LP
   * @param _positionsCache Temporary memory cache containing LPs positions
   * @param _liquidatedLp Address of the LP in liquidation
   * @param _tokensInLiquidation Amount of  synthetic asset to liquidate
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @param _overCollateralRequirement Overcollateral percentage needed to prevent liquidation
   * @return tokensToLiquidate Amount of tokens will be liquidated
   * @return tokensValue Amount of collateral value equivalent to tokens in liquidation
   * @return liquidationBonusAmount Amount of bonus collateral for the liquidation
   */
  function _updateAndLiquidate(
    PositionCache[] memory _positionsCache,
    address _liquidatedLp,
    uint256 _tokensInLiquidation,
    uint256 _price,
    uint8 _collateralDecimals,
    uint256 _overCollateralRequirement
  )
    internal
    returns (
      uint256 tokensToLiquidate,
      uint256 tokensValue,
      uint256 liquidationBonusAmount
    )
  {
    PositionCache memory lpCache;
    address lp;
    LPPosition memory lpPosition;
    uint256 actualCollateralAmount;
    for (uint256 j = 0; j < _positionsCache.length; j++) {
      lpCache = _positionsCache[j];
      lp = lpCache.lp;
      lpPosition = _positionsCache[j].lpPosition;
      actualCollateralAmount = lpPosition.actualCollateralAmount;
      if (lp == _liquidatedLp) {
        tokensToLiquidate = PreciseUnitMath.min(
          _tokensInLiquidation,
          lpPosition.tokensCollateralized
        );
        tokensValue = _calculateCollateralAmount(
          lpPosition.tokensCollateralized,
          _price,
          _collateralDecimals
        );
        require(
          !_isOvercollateralizedLP(
            actualCollateralAmount,
            _overCollateralRequirement,
            tokensValue
          ),
          'LP is overcollateralized'
        );
        liquidationBonusAmount = actualCollateralAmount
          .mul(liquidationBonus)
          .mul(tokensToLiquidate)
          .div(lpPosition.tokensCollateralized);
        lpPositions[lp].actualCollateralAmount =
          actualCollateralAmount -
          liquidationBonusAmount;
        lpPositions[lp].tokensCollateralized -= tokensToLiquidate;
      } else {
        lpPositions[lp].actualCollateralAmount = actualCollateralAmount;
      }
    }
  }

  /**
   * @notice Pulls and burns synthetic tokens from the sender
   * @param _syntheticAsset Synthetic asset of the pool
   * @param _numTokens The number of tokens to be burned
   * @param _sender Sender of synthetic tokens
   */
  function _burnSyntheticTokens(
    IMintableBurnableERC20 _syntheticAsset,
    uint256 _numTokens,
    address _sender
  ) internal {
    // Transfer synthetic token from the user to the pool
    _syntheticAsset.safeTransferFrom(_sender, address(this), _numTokens);

    // Burn synthetic asset
    _syntheticAsset.burn(_numTokens);
  }

  /**
   * @notice Calculate new positons from previous interaction
   * @param _totalInterests Amount of interests to split between active LPs
   * @param _price Actual price of the pair
   * @param _totalSynthTokens Amount of synthetic asset collateralized by the pool
   * @param _totalUserAmount Actual amount deposited by the users
   * @param _collateralDecimals Decimals of the collateral token
   * @return profitOrLoss Profit or loss result
   */
  function _calculateNewPositions(
    uint256 _totalInterests,
    uint256 _price,
    uint256 _totalSynthTokens,
    uint256 _totalUserAmount,
    uint8 _collateralDecimals
  )
    internal
    view
    returns (
      ProfitOrLoss memory profitOrLoss,
      PositionCache[] memory positionsCache
    )
  {
    uint256 lpNumbers = activeLPs.length();
    if (lpNumbers > 0) {
      positionsCache = new PositionCache[](lpNumbers);

      _calculateInterest(
        _totalInterests,
        _price,
        _collateralDecimals,
        positionsCache
      );

      profitOrLoss = _calculateProfitAndLoss(
        _price,
        _totalSynthTokens,
        _totalUserAmount,
        _collateralDecimals,
        positionsCache
      );
    }
  }

  /**
   * @notice Calculate interests of each Lp
   * @param _totalInterests Amount of interests to split between active LPs
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @param _positionsCache Temporary memory cache containing LPs positions
   */
  function _calculateInterest(
    uint256 _totalInterests,
    uint256 _price,
    uint8 _collateralDecimals,
    PositionCache[] memory _positionsCache
  ) internal view {
    uint256 lpNumbers = _positionsCache.length;
    TempInterstArguments memory tempInterstArguments;
    uint256[] memory capacityShares = new uint256[](_positionsCache.length);
    uint256[] memory utilizationShares = new uint256[](_positionsCache.length);

    (
      tempInterstArguments.totalCapacity,
      tempInterstArguments.totalUtilization
    ) = _calculateInterestShares(
      _price,
      _collateralDecimals,
      _positionsCache,
      capacityShares,
      utilizationShares
    );

    tempInterstArguments.isTotCapacityNotZero =
      tempInterstArguments.totalCapacity > 0;
    tempInterstArguments.isTotUtilizationNotZero =
      tempInterstArguments.totalUtilization > 0;
    require(
      tempInterstArguments.isTotCapacityNotZero ||
        tempInterstArguments.isTotUtilizationNotZero,
      'No capacity and utilization'
    );
    LPPosition memory lpPosition;
    tempInterstArguments.remainingInterest = _totalInterests;
    for (uint256 j = 0; j < lpNumbers - 1; j++) {
      tempInterstArguments.capacityShare = tempInterstArguments
        .isTotCapacityNotZero
        ? capacityShares[j].div(tempInterstArguments.totalCapacity)
        : 0;
      tempInterstArguments.utilizationShare = tempInterstArguments
        .isTotUtilizationNotZero
        ? utilizationShares[j].div(tempInterstArguments.totalUtilization)
        : 0;
      tempInterstArguments.interest = _totalInterests.mul(
        (tempInterstArguments.capacityShare +
          tempInterstArguments.utilizationShare) / 2
      );
      lpPosition = _positionsCache[j].lpPosition;
      lpPosition.actualCollateralAmount += tempInterstArguments.interest;
      tempInterstArguments.remainingInterest -= tempInterstArguments.interest;
    }

    lpPosition = _positionsCache[lpNumbers - 1].lpPosition;
    lpPosition.actualCollateralAmount += tempInterstArguments.remainingInterest;
  }

  /**
   * @notice Calculate interest shares of each LP
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @param _positionsCache Temporary memory cache containing LPs positions
   * @param _capacityShares Array to be populated with the capacity shares of every LP
   * @param _utilizationShares Array to be populated with the utilization shares of every LP
   * @return totalCapacity Sum of all the LP's capacities
   * @return totalUtilization Sum of all the LP's utilizations
   */
  function _calculateInterestShares(
    uint256 _price,
    uint8 _collateralDecimals,
    PositionCache[] memory _positionsCache,
    uint256[] memory _capacityShares,
    uint256[] memory _utilizationShares
  ) internal view returns (uint256 totalCapacity, uint256 totalUtilization) {
    address lp;
    LPPosition memory lpPosition;
    uint256 capacityShare;
    uint256 utilizationShare;
    for (uint256 j = 0; j < _positionsCache.length; j++) {
      lp = activeLPs.at(j);
      lpPosition = lpPositions[lp];
      capacityShare = _calculateCapacity(
        lpPosition.actualCollateralAmount,
        lpPosition.tokensCollateralized,
        lpPosition.overCollateralization,
        _price,
        _collateralDecimals
      );
      utilizationShare = _calculateUtilization(
        lpPosition.actualCollateralAmount,
        lpPosition.tokensCollateralized,
        lpPosition.overCollateralization,
        _price,
        _collateralDecimals
      );
      _capacityShares[j] = capacityShare;
      totalCapacity += capacityShare;
      _utilizationShares[j] = utilizationShare;
      totalUtilization += utilizationShare;
      _positionsCache[j] = PositionCache(
        lp,
        LPPosition(
          lpPosition.actualCollateralAmount,
          lpPosition.tokensCollateralized,
          lpPosition.overCollateralization
        )
      );
    }
  }

  /**
   * @notice Given a collateral value to be exchanged, returns the fee amount, net collateral and synthetic tokens
   * @param _totCollateralAmount Collateral amount to be exchanged
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @return Return netCollateralAmount, feeAmount and numTokens
   */
  function _calculateMint(
    uint256 _totCollateralAmount,
    uint256 _price,
    uint8 _collateralDecimals
  ) internal view returns (MintValues memory) {
    uint256 feeAmount = _totCollateralAmount.mul(fee);

    uint256 netCollateralAmount = _totCollateralAmount - feeAmount;

    uint256 numTokens =
      _calculateNumberOfTokens(
        netCollateralAmount,
        _price,
        _collateralDecimals
      );

    return
      MintValues(
        _totCollateralAmount,
        netCollateralAmount,
        feeAmount,
        numTokens
      );
  }

  /**
   * @notice Given a an amount of synthetic tokens to be exchanged, returns the fee amount, net collateral and gross collateral
   * @param _numTokens Synthetic tokens amount to be exchanged
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @return Return netCollateralAmount, feeAmount and totCollateralAmount
   */
  function _calculateRedeem(
    uint256 _numTokens,
    uint256 _price,
    uint8 _collateralDecimals
  ) internal view returns (RedeemValues memory) {
    uint256 totCollateralAmount =
      _calculateCollateralAmount(_numTokens, _price, _collateralDecimals);

    uint256 feeAmount = totCollateralAmount.mul(fee);

    uint256 netCollateralAmount = totCollateralAmount - feeAmount;

    return
      RedeemValues(
        _numTokens,
        totCollateralAmount,
        feeAmount,
        netCollateralAmount
      );
  }

  /**
   * @notice Return the on-chain oracle price for a pair
   * @param _finder Synthereum finder
   * @param _priceIdentifier Price identifier
   * @return Latest rate of the pair
   */
  function _getPriceFeedRate(
    ISynthereumFinder _finder,
    bytes32 _priceIdentifier
  ) internal view returns (uint256) {
    ISynthereumPriceFeed priceFeed =
      ISynthereumPriceFeed(
        _finder.getImplementationAddress(SynthereumInterfaces.PriceFeed)
      );

    return priceFeed.getLatestPrice(_priceIdentifier);
  }

  /**
   * @notice Return the address of the lendingManager
   * @param _finder Synthereum finder
   * @return Address of the lendingManager
   */
  function _getLendingManager(ISynthereumFinder _finder)
    internal
    view
    returns (ILendingManager)
  {
    return
      ILendingManager(
        _finder.getImplementationAddress(SynthereumInterfaces.LendingManager)
      );
  }

  /**
   * @notice Return the address of the lendingStorageManager
   * @param _finder Synthereum finder
   * @return Address of the lendingStorageManager
   */
  function _getLendingStorageManager(ISynthereumFinder _finder)
    internal
    view
    returns (ILendingStorageManager)
  {
    return
      ILendingStorageManager(
        _finder.getImplementationAddress(
          SynthereumInterfaces.LendingStorageManager
        )
      );
  }

  /**
   * @notice Calculate and returns interest generated by the pool from the last update
   * @param _lendingManager Address of lendingManager
   * @return poolInterests Return interest generated by the pool
   * @return collateralDeposited Collateral deposited in the pool (LPs + users) (excluding last intrest amount calculation)
   */
  function _getLendingInterest(ILendingManager _lendingManager)
    internal
    view
    returns (uint256 poolInterests, uint256 collateralDeposited)
  {
    (poolInterests, , collateralDeposited) = _lendingManager
      .getAccumulatedInterest(address(this));
  }

  /**
   * @notice Calculate and returns actual total collateral in the pool (users + Lps)
   * @param _lendingStorageManager Address of lendingStoargeManager
   * @return Return total collateral amount
   */
  function _getTotalCollateral(ILendingStorageManager _lendingStorageManager)
    internal
    view
    returns (uint256)
  {
    (ILendingStorageManager.PoolStorage memory poolStorage, ) =
      _lendingStorageManager.getPoolStorage(address(this));
    return poolStorage.collateralDeposited;
  }

  /**
   * @notice Calculate profit or loss of each Lp
   * @param _price Actual price of the pair
   * @param _totalSynthTokens Amount of synthetic asset collateralized by the pool
   * @param _totalUserAmount Actual amount deposited by the users
   * @param _positionsCache Temporary memory cache containing LPs positions
   * @param _collateralDecimals Decimals of the collateral token
   * @return profitOrLoss Profit or loss result
   */
  function _calculateProfitAndLoss(
    uint256 _price,
    uint256 _totalSynthTokens,
    uint256 _totalUserAmount,
    uint8 _collateralDecimals,
    PositionCache[] memory _positionsCache
  ) internal pure returns (ProfitOrLoss memory) {
    if (_totalSynthTokens == 0) {
      return ProfitOrLoss(true, 0);
    }

    uint256 lpNumbers = _positionsCache.length;

    uint256 totalAssetValue =
      _calculateCollateralAmount(
        _totalSynthTokens,
        _price,
        _collateralDecimals
      );

    bool isLpGain = totalAssetValue < _totalUserAmount;

    uint256 totalProfitOrLoss =
      isLpGain
        ? _totalUserAmount - totalAssetValue
        : totalAssetValue - _totalUserAmount;

    uint256 remainingProfitOrLoss = totalProfitOrLoss;

    LPPosition memory lpPosition;
    uint256 assetRatio;
    uint256 lpProfitOrLoss;
    for (uint256 j = 0; j < lpNumbers - 1; j++) {
      lpPosition = _positionsCache[j].lpPosition;
      assetRatio = lpPosition.tokensCollateralized.div(_totalSynthTokens);
      lpProfitOrLoss = totalProfitOrLoss.mul(assetRatio);
      lpPosition.actualCollateralAmount = isLpGain
        ? lpPosition.actualCollateralAmount + lpProfitOrLoss
        : lpPosition.actualCollateralAmount - lpProfitOrLoss;
      remainingProfitOrLoss -= lpProfitOrLoss;
    }

    lpPosition = _positionsCache[lpNumbers - 1].lpPosition;
    lpPosition.actualCollateralAmount = isLpGain
      ? lpPosition.actualCollateralAmount + remainingProfitOrLoss
      : lpPosition.actualCollateralAmount - remainingProfitOrLoss;

    return ProfitOrLoss(isLpGain, totalProfitOrLoss);
  }

  /**
   * @notice Calculate fee and synthetic asset of each Lp in a mint transaction
   * @param _mintValues ExchangeAmount, feeAmount and numTokens
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @param _positionsCache Temporary memory cache containing LPs positions
   */
  function _calculateMintTokensAndFee(
    MintValues memory _mintValues,
    uint256 _price,
    uint8 _collateralDecimals,
    PositionCache[] memory _positionsCache
  ) internal pure {
    uint256 lpNumbers = _positionsCache.length;

    uint256[] memory capacityShares = new uint256[](lpNumbers);
    uint256 totalCapacity =
      _calculateMintShares(
        _price,
        _collateralDecimals,
        _positionsCache,
        capacityShares
      );

    require(
      totalCapacity >= _mintValues.exchangeAmount,
      'No enough liquidity for covering mint operation'
    );

    uint256 remainingTokens = _mintValues.numTokens;
    uint256 remainingFees = _mintValues.feeAmount;
    LPPosition memory lpPosition;
    uint256 shareProportion;
    uint256 tokens;
    uint256 fees;
    for (uint256 j = 0; j < lpNumbers - 1; j++) {
      shareProportion = (capacityShares[j]).div(totalCapacity);
      tokens = _mintValues.numTokens.mul(shareProportion);
      fees = _mintValues.feeAmount.mul(shareProportion);
      lpPosition = _positionsCache[j].lpPosition;
      lpPosition.tokensCollateralized += tokens;
      lpPosition.actualCollateralAmount += fees;
      remainingTokens = remainingTokens - tokens;
      remainingFees = remainingFees - fees;
    }

    lpPosition = _positionsCache[lpNumbers - 1].lpPosition;
    lpPosition.tokensCollateralized += remainingTokens;
    lpPosition.actualCollateralAmount += remainingFees;
  }

  /**
   * @notice Calculate mint shares based on capacity
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @param _positionsCache Temporary memory cache containing LPs positions
   * @param _capacityShares Array to be populated with the capacity shares of every LPP
   * @return totalCapacity Sum of all the LP's capacities
   */
  function _calculateMintShares(
    uint256 _price,
    uint8 _collateralDecimals,
    PositionCache[] memory _positionsCache,
    uint256[] memory _capacityShares
  ) internal pure returns (uint256 totalCapacity) {
    LPPosition memory lpPosition;
    uint256 capacityShare;
    for (uint256 j = 0; j < _positionsCache.length; j++) {
      lpPosition = _positionsCache[j].lpPosition;
      capacityShare = _calculateCapacity(
        lpPosition.actualCollateralAmount,
        lpPosition.tokensCollateralized,
        lpPosition.overCollateralization,
        _price,
        _collateralDecimals
      );
      _capacityShares[j] = capacityShare;
      totalCapacity += capacityShare;
    }
  }

  /**
   * @notice Calculate fee and synthetic asset of each Lp in a redeem transaction
   * @param _totalNumTokens Total amount of synethtic asset in the pool
   * @param _redeemNumTokens Total amount of synethtic asset to redeem
   * @param _feeAmount Total amount of fee to charge to the LPs
   * @param _positionsCache Temporary memory cache containing LPs positions
   */
  function _calculateRedeemTokensAndFee(
    uint256 _totalNumTokens,
    uint256 _redeemNumTokens,
    uint256 _feeAmount,
    PositionCache[] memory _positionsCache
  ) internal pure {
    uint256 lpNumbers = _positionsCache.length;
    uint256 remainingTokens = _redeemNumTokens;
    uint256 remainingFees = _feeAmount;
    LPPosition memory lpPosition;
    uint256 shareProportion;
    uint256 tokens;
    uint256 fees;
    for (uint256 j = 0; j < lpNumbers - 1; j++) {
      lpPosition = _positionsCache[j].lpPosition;
      shareProportion = (lpPosition.tokensCollateralized).div(_totalNumTokens);
      tokens = _redeemNumTokens.mul(shareProportion);
      fees = _feeAmount.mul(shareProportion);
      lpPosition.tokensCollateralized -= tokens;
      lpPosition.actualCollateralAmount += fees;
      remainingTokens -= tokens;
      remainingFees -= fees;
    }

    lpPosition = _positionsCache[lpNumbers - 1].lpPosition;
    lpPosition.tokensCollateralized -= lpPosition.tokensCollateralized;
    lpPosition.actualCollateralAmount += remainingFees;
  }

  /**
   * @notice Calculate the new collateral amount of the LPs after the switching of lending module
   * @param _actualUserDeposits Total amount of collateral holded by the users
   * @param _migrationValues Values returned by the lending manager after the migration
   * @param _positionsCache Temporary memory cache containing LPs positions
   */
  function _calculateLendingModuleCollateral(
    uint256 _actualUserDeposits,
    ILendingManager.MigrateReturnValues memory _migrationValues,
    PositionCache[] memory _positionsCache
  ) internal pure {
    uint256 prevTotalAmount =
      _migrationValues.prevDepositedCollateral + _migrationValues.poolInterest;
    bool isLpGain =
      _migrationValues.actualCollateralDeposited > prevTotalAmount;
    uint256 globalLpsProfitOrLoss =
      isLpGain
        ? _migrationValues.actualCollateralDeposited - prevTotalAmount
        : prevTotalAmount - _migrationValues.actualCollateralDeposited;
    if (globalLpsProfitOrLoss == 0) return;

    LPPosition memory lpPosition;
    uint256 share;
    uint256 shareAmount;
    uint256 remainingAmount;
    uint256 prevLpAmount = prevTotalAmount - _actualUserDeposits;
    uint256 lpNumbers = _positionsCache.length;
    for (uint256 j = 0; j < lpNumbers - 1; j++) {
      lpPosition = _positionsCache[j].lpPosition;
      share = lpPosition.actualCollateralAmount.div(prevLpAmount);
      shareAmount = globalLpsProfitOrLoss.mul(share);
      lpPosition.actualCollateralAmount = isLpGain
        ? lpPosition.actualCollateralAmount + shareAmount
        : lpPosition.actualCollateralAmount - shareAmount;
      remainingAmount -= shareAmount;
    }

    lpPosition = _positionsCache[lpNumbers - 1].lpPosition;
    lpPosition.actualCollateralAmount = isLpGain
      ? lpPosition.actualCollateralAmount + remainingAmount
      : lpPosition.actualCollateralAmount - remainingAmount;
  }

  /**
   * @notice Calculate synthetic token amount starting from an amount of collateral
   * @param _collateralAmount Amount of collateral from which you want to calculate synthetic token amount
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @return Amount of tokens after on-chain oracle conversion
   */
  function _calculateNumberOfTokens(
    uint256 _collateralAmount,
    uint256 _price,
    uint8 _collateralDecimals
  ) internal pure returns (uint256) {
    return (_collateralAmount * (10**(18 - _collateralDecimals))).div(_price);
  }

  /**
   * @notice Calculate collateral amount starting from an amount of synthtic token
   * @param _numTokens Amount of synthetic tokens used for the conversion
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @return Amount of collateral after on-chain oracle conversion
   */
  function _calculateCollateralAmount(
    uint256 _numTokens,
    uint256 _price,
    uint8 _collateralDecimals
  ) internal pure returns (uint256) {
    return _numTokens.mul(_price) / (10**(18 - _collateralDecimals));
  }

  /**
   * @notice Calculate capacity of each LP
   * @dev Utilization = (actualCollateralAmount / overCollateralization) - (tokensCollateralized * price)
   * @dev Return 0 if underCollateralized
   * @param _actualCollateralAmount Actual collateral amount holded by the LP
   * @param _tokensCollateralized Actual amount of syntehtic asset collateralized by the LP
   * @param _overCollateralization Overcollateralization of the LP
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @return Capacity of the LP
   */
  function _calculateCapacity(
    uint256 _actualCollateralAmount,
    uint256 _tokensCollateralized,
    uint256 _overCollateralization,
    uint256 _price,
    uint8 _collateralDecimals
  ) internal pure returns (uint256) {
    uint256 maxCapacity = _actualCollateralAmount.div(_overCollateralization);
    uint256 usedCapacity =
      _calculateCollateralAmount(
        _tokensCollateralized,
        _price,
        _collateralDecimals
      );
    return maxCapacity > usedCapacity ? maxCapacity - usedCapacity : 0;
  }

  /**
   * @notice Calculate utilization of an LP
   * @dev Utilization = (tokensCollateralized * price * overCollateralization) / actualCollateralAmount
   * @dev Capped to 1 in case of underCollateralization
   * @param _actualCollateralAmount Actual collateral amount holded by the LP
   * @param _tokensCollateralized Actual amount of syntehtic asset collateralized by the LP
   * @param _overCollateralization Overcollateralization of the LP
   * @param _price Actual price of the pair
   * @param _collateralDecimals Decimals of the collateral token
   * @return Utilization of the LP
   */
  function _calculateUtilization(
    uint256 _actualCollateralAmount,
    uint256 _tokensCollateralized,
    uint256 _overCollateralization,
    uint256 _price,
    uint8 _collateralDecimals
  ) internal pure returns (uint256) {
    return
      _actualCollateralAmount != 0
        ? PreciseUnitMath.min(
          _calculateCollateralAmount(
            _tokensCollateralized,
            _price,
            _collateralDecimals
          )
            .mul(_overCollateralization)
            .div(_actualCollateralAmount),
          PreciseUnitMath.PRECISE_UNIT
        )
        : _tokensCollateralized > 0
        ? PreciseUnitMath.PRECISE_UNIT
        : 0;
  }

  /**
   * @notice Return if an LP is overcollateralized
   * @param _actualCollateralAmount Actual collateral amount holded by the LP
   * @param _overCollateralization Overcollateralization requested
   * @param _collateralCovered Collateral value of the tokens collateralized
   * @return True if LP is overcollateralized otherwise false
   */
  function _isOvercollateralizedLP(
    uint256 _actualCollateralAmount,
    uint256 _overCollateralization,
    uint256 _collateralCovered
  ) internal pure returns (bool) {
    return
      _actualCollateralAmount.div(_overCollateralization) >= _collateralCovered;
  }

  /**
   * @notice Check if an address is the trusted forwarder
   * @param  forwarder Address to check
   * @return True is the input address is the trusted forwarder, otherwise false
   */
  function isTrustedForwarder(address forwarder)
    public
    view
    override
    returns (bool)
  {
    try
      finder.getImplementationAddress(SynthereumInterfaces.TrustedForwarder)
    returns (address trustedForwarder) {
      if (forwarder == trustedForwarder) {
        return true;
      } else {
        return false;
      }
    } catch {
      return false;
    }
  }

  function _msgSender()
    internal
    view
    override(ERC2771Context, Context)
    returns (address sender)
  {
    return ERC2771Context._msgSender();
  }

  function _msgData()
    internal
    view
    override(ERC2771Context, Context)
    returns (bytes calldata)
  {
    return ERC2771Context._msgData();
  }
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ITypology} from '../../../common/interfaces/ITypology.sol';
import {IStandardERC20} from '../../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableERC20
} from '../../../tokens/interfaces/IMintableBurnableERC20.sol';
import {
  ISynthereumDeployment
} from '../../../common/interfaces/IDeployment.sol';
import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {
  FixedPoint
} from '../../../../@uma/core/contracts/common/implementation/FixedPoint.sol';

/**
 * @title Multi LP pool interface
 */
interface ISynthereumMultiLpLiquidityPool is ITypology, ISynthereumDeployment {
  // Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  struct InitializationParams {
    // Synthereum finder
    ISynthereumFinder finder;
    // Synthereum pool version
    uint8 version;
    // ERC20 collateral token
    IStandardERC20 collateralToken;
    // ERC20 synthetic token
    IMintableBurnableERC20 syntheticToken;
    // The addresses of admin and maintainer
    Roles roles;
    // The fee percentage
    uint256 fee;
    // Identifier of price to be used in the price feed
    bytes32 priceIdentifier;
    // Percentage of overcollateralization to which a liquidation can triggered
    uint256 overCollateralRequirement;
    // Percentage of reward for correct liquidation by a liquidator
    uint256 liquidationReward;
    // Name of the lending protocol used
    string lendingModuleId;
  }

  struct LPPosition {
    // Actual collateral owned
    uint256 actualCollateralAmount;
    // Number of tokens collateralized
    uint256 tokensCollateralized;
    // Overcollateralization percentage
    uint256 overCollateralization;
  }

  struct MintParams {
    // Minimum amount of synthetic tokens that a user wants to mint using collateral (anti-slippage)
    uint256 minNumTokens;
    // Amount of collateral that a user wants to spend for minting
    uint256 collateralAmount;
    // Expiration time of the transaction
    uint256 expiration;
    // Address to which send synthetic tokens minted
    address recipient;
  }

  struct RedeemParams {
    // Amount of synthetic tokens that user wants to use for redeeming
    uint256 numTokens;
    // Minimium amount of collateral that user wants to redeem (anti-slippage)
    uint256 minCollateral;
    // Expiration time of the transaction
    uint256 expiration;
    // Address to which send collateral tokens redeemed
    address recipient;
  }

  struct LPInfo {
    // Actual collateral owned
    uint256 actualCollateralAmount;
    // Number of tokens collateralized
    uint256 tokensCollateralized;
    // Overcollateralization percentage
    uint256 overCollateralization;
    // Available liquidity for minting
    uint256 availableLiquidity;
    // Utilization ratio: (numTokens * price * overCollateralization) / actualCollateralAmount
    uint256 utilization;
    // Collateral coverage: (actualCollateralAmount + numTokens * price) / (numTokens * price)
    uint256 coverage;
    // Mint shares percentage
    uint256 mintShares;
    // Redeem shares percentage
    uint256 redeemShares;
    // True if it's overcollateralized, otherwise false
    bool isOvercollateralized;
  }

  /**
   * @notice Initialize pool
   * @param _params Params used for initialization (see InitializationParams struct)
   */
  function initialize(InitializationParams calldata _params) external;

  /**
   * @notice Register a liquidity provider to the LP's whitelist
   * @notice This can be called only by the maintainer
   * @param _lp Address of the LP
   */
  function registerLP(address _lp) external;

  /**
   * @notice Add the Lp to the active list of the LPs and initialize collateral and overcollateralization
   * @notice Only a registered and inactive LP can call this function to add himself
   * @param _collateralAmount Collateral amount to deposit by the LP
   * @param _overCollateralization Overcollateralization to set by the LP
   * @return collateralDeposited Net collateral deposited in the LP position
   */
  function activateLP(uint256 _collateralAmount, uint256 _overCollateralization)
    external
    returns (uint256 collateralDeposited);

  /**
   * @notice Add collateral to an active LP position
   * @notice Only an active LP can call this function to add collateral to his position
   * @param _collateralAmount Collateral amount to deposit by the LP
   * @return collateralDeposited Net collateral deposited in the LP position
   */
  function addLiquidity(uint256 _collateralAmount)
    external
    returns (uint256 collateralDeposited);

  /**
   * @notice Withdraw collateral from an active LP position
   * @notice Only an active LP can call this function to withdraw collateral from his position
   * @param _collateralAmount Collateral amount to withdraw by the LP
   * @param collateralWithdrawn Net collateral withdrawn from the LP position
   */
  function removeLiquidity(uint256 _collateralAmount)
    external
    returns (uint256 collateralWithdrawn);

  /**
   * @notice Set the overCollateralization by an active LP
   * @notice This can be called only by an active LP
   * @param _overCollateralization New overCollateralizations
   */
  function setOvercollateralization(uint256 _overCollateralization) external;

  /**
   * @notice Mint synthetic tokens using fixed amount of collateral
   * @notice This calculate the price using on chain price feed
   * @notice User must approve collateral transfer for the mint request to succeed
   * @param mintParams Input parameters for minting (see MintParams struct)
   * @return syntheticTokensMinted Amount of synthetic tokens minted by a user
   * @return feePaid Amount of collateral paid by the user as fee
   */
  function mint(MintParams calldata mintParams)
    external
    returns (uint256 syntheticTokensMinted, uint256 feePaid);

  /**
   * @notice Redeem amount of collateral using fixed number of synthetic token
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param redeemParams Input parameters for redeeming (see RedeemParams struct)
   * @return collateralRedeemed Amount of collateral redeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function redeem(RedeemParams calldata redeemParams)
    external
    returns (uint256 collateralRedeemed, uint256 feePaid);

  /**
   * @notice Liquidate Lp position for an amount of synthetic tokens undercollateralized
   * @notice Revert if position is not undercollateralized
   * @param lp LP that the the user wants to liquidate
   * @param numSynthTokens Number of synthetic tokens that user wants to liquidate
   * @return Amount of collateral received (Amount of collateral + bonus)
   */
  function liquidate(address lp, uint256 numSynthTokens)
    external
    returns (uint256);

  /**
   * @notice Update interests and positions ov every LP
   * @notice Everyone can call this function
   */
  function updatePositions() external;

  /**
   * @notice Transfer a bearing amount to the lending manager
   * @notice Only the lending manager can call the function
   * @param _bearingAmount Amount of bearing token to transfer
   */
  function transferToLendingManager(uint256 _bearingAmount) external;

  /**
   * @notice Set new liquidation reward percentage
   * @notice This can be called only by the maintainer
   * @param _newLiquidationReward New liquidation reward percentage
   */
  function setLiquidationReward(uint256 _newLiquidationReward) external;

  /**
   * @notice Set new fee percentage
   * @notice This can be called only by the maintainer
   * @param _fee New fee percentage
   */
  function setFee(uint256 _fee) external;

  /**
   * @notice Set new lending protocol for this pool
   * @notice This can be called only by the maintainer
   * @param _lendingId Name of the new lending module
   * @param _bearingToken Token of the lending mosule to be used for intersts accrual
            (used only if the lending manager doesn't automatically find the one associated to the collateral fo this pool)
   */
  function switchLendingModule(
    string calldata _lendingId,
    address _bearingToken
  ) external;

  /**
   * @notice Get all the registered LPs of this pool
   * @return lps The list of addresses of all the registered LPs in the pool.
   */
  function getRegisteredLPs() external view returns (address[] memory lps);

  /**
   * @notice Get all the active LPs of this pool
   * @return lps The list of addresses of all the active LPs in the pool.
   */
  function getActiveLPs() external view returns (address[] memory lps);

  /**
   * @notice Check if the input LP is registered
   * @param _lp Address of the LP
   * @return isRegistered Return true if the LP is regitered, otherwise false
   */
  function isRegisteredLP(address _lp)
    external
    view
    returns (bool isRegistered);

  /**
   * @notice Check if the input LP is active
   * @param _lp Address of the LP
   * @return isActive Return true if the LP is active, otherwise false
   */
  function isActiveLP(address _lp) external view returns (bool isActive);

  /**
   * @notice Returns total number of synthetic tokens generated by this pool
   * @return totalTokens Number of total synthetic tokens in the pool
   */
  function totalSyntheticTokens() external view returns (uint256 totalTokens);

  /**
   * @notice Returns the total amounts of collateral
   * @return usersCollateral Total collateral amount currently holded by users
   * @return lpsCollateral Total collateral amount currently holded by LPs
   * @return totalCollateral Total collateral amount currently holded by users + LPs
   */
  function totalCollateralAmount()
    external
    view
    returns (
      uint256 usersCollateral,
      uint256 lpsCollateral,
      uint256 totalCollateral
    );

  /**
   * @notice Returns the total available liquidity of the LPs
   * @return totalLiquidity Total available liquidity for minting operation
   */
  function totalAvailableLiquidity()
    external
    view
    returns (uint256 totalLiquidity);

  /**
   * @notice Returns the LP parametrs info
   * @return info Info of the input lp (see LPInfo struct)
   */
  function positionLPInfo(address _lp)
    external
    view
    returns (LPInfo memory info);

  /**
   * @notice Returns the lending protocol info
   * @return lendingId Name of the lending module
   * @return bearingToken Address of the bearing token held by the pool for interest accrual
   */
  function lendingProtocolInfo()
    external
    view
    returns (string memory lendingId, address bearingToken);

  /**
   * @notice Get the decimals of the collateral
   * @return Number of decimals of the collateral
   */
  function collateralTokenDecimals() external view returns (uint8);

  /**
   * @notice Returns the percentage of overcollateralization to which a liquidation can triggered
   * @return requirement Thresold percentage on a liquidation can be triggered
   */
  function collateralRequirement() external view returns (uint256 requirement);

  /**
   * @notice Returns the percentage of reward for correct liquidation by a liquidator
   * @return reward Percentage of reward
   */
  function liquidationReward() external view returns (uint256 reward);

  /**
   * @notice Returns price identifier of the pool
   * @return identifier Price identifier
   */
  function priceFeedIdentifier() external view returns (bytes32 identifier);

  /**
   * @notice Returns fee percentage of the pool
   * @return fee Fee percentage
   */
  function feePercentage() external view returns (uint256 fee);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ISynthereumMultiLpLiquidityPoolEvents {
  struct MintValues {
    // collateral sent to the the pool by the user
    uint256 totalCollateral;
    // numTokens * price
    uint256 exchangeAmount;
    // Fee to be paid according to the fee percentage
    uint256 feeAmount;
    // Number of synthetic tokens will be received ((totalCollateral - feeAmount - lending fee/bonus) / price)
    uint256 numTokens;
  }

  struct RedeemValues {
    // Amount of synthetic asset sent by the user
    uint256 numTokens;
    // numTokens * price
    uint256 exchangeAmount;
    // Fee to be paid according to the fee percentage
    uint256 feeAmount;
    // Net collateral amount will be received (totCollateral - feeAmount -lending fee/bonus )
    uint256 collateralAmount;
  }

  /**
   * @notice Emitted when a LP is registered in the pool by the maintainer
   * @param lp Address of the LP to be registered
   */
  event RegisteredLp(address indexed lp);

  /**
   * @notice Emitted when a LP is activated in the pool by himself
   * @param lp Address of the LP to be activated
   */
  event ActivatedLP(address indexed lp);

  /**
   * @notice Emitted when a LP set his overCollateralization
   * @param lp Address of the LP to set overCollateralization
   * @param overCollateralization OverCollateralization percentage set
   */
  event SetOvercollateralization(
    address indexed lp,
    uint256 overCollateralization
  );

  /**
   * @notice Emitted when a LP deposits collateral
   * @param lp Address of the LP depositing
   * @param collateralSent Collateral sent to the the pool by the LP
   * @param collateralDeposited Net collateral amount added to the LP position
   */
  event DepositedLiquidity(
    address indexed lp,
    uint256 collateralSent,
    uint256 collateralDeposited
  );

  /**
   * @notice Emitted when a LP withdraws collateral
   * @param lp Address of the LP withdrawing
   * @param collateralReceived Collateral received from the pool by the LP
   * @param collateralWithdrawn Net collateral amount removed from the LP position
   */
  event WithdrawnLiquidity(
    address indexed lp,
    uint256 collateralReceived,
    uint256 collateralWithdrawn
  );

  /**
   * @notice Emitted when a user mint the synthetic asset
   * @param user Address of the user minting
   * @param mintvalues Include netCollateralAmount, feeAmount and numTokens
   * @param recipient Address receiving minted tokens
   */
  event Mint(address indexed user, MintValues mintvalues, address recipient);

  /**
   * @notice Emitted when a user redeem the synthetic asset
   * @param user Address of the user redeeming
   * @param redeemvalues Include exchangeAmount, feeAmount and collateralAmount
   * @param recipient Address receiving collateral unlocked
   */
  event Redeem(
    address indexed user,
    RedeemValues redeemvalues,
    address recipient
  );

  /**
   * @notice Emitted when a user liquidate an LP
   * @param user Address of the user liquidating
   * @param synthTokensInLiquidation Amount of synthetic asset in liquidation
   * @param collateralAmount Value of synthetic tokens in liquidation expressed in collateral (synthTokensInLiquidation * price)
   * @param collateralReceived Amount of collateral received by liquidator (collateralAmount + liquidation bonus - lending fee/bonus)
   */
  event Liquidate(
    address indexed user,
    uint256 synthTokensInLiquidation,
    uint256 collateralAmount,
    uint256 collateralReceived
  );

  /**
   * @notice Emitted when new fee percentage is set in the pool by the maintainer
   * @param newFee New fee percentage
   */
  event SetFeePercentage(uint256 newFee);

  /**
   * @notice Emitted when liquidation reward percentage is set in the pool by the maintainer
   * @param newLiquidationReward New liquidation reward percentage
   */
  event SetLiquidationReward(uint256 newLiquidationReward);

  /**
   * @notice Emitted when lending module is initialized or set
   * @param lendingModuleId Name of the lending module
   */
  event NewLendingModule(string lendingModuleId);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IStandardERC20 is IERC20 {
  /**
   * @dev Returns the name of the token.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the number of decimals used to get its user representation.
   * For example, if `decimals` equals `2`, a balance of `505` tokens should
   * be displayed to a user as `5,05` (`505 / 10 ** 2`).
   *
   * Tokens usually opt for a value of 18, imitating the relationship between
   * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
   * called.
   *
   * NOTE: This information is only used for _display_ purposes: it in
   * no way affects any of the arithmetic of the contract, including
   * {IERC20-balanceOf} and {IERC20-transfer}.
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title ERC20 interface that includes burn mint and roles methods.
 */
interface IMintableBurnableERC20 is IERC20 {
  /**
   * @notice Burns a specific amount of the caller's tokens.
   * @dev This method should be permissioned to only allow designated parties to burn tokens.
   */
  function burn(uint256 value) external;

  /**
   * @notice Mints tokens and adds them to the balance of the `to` address.
   * @dev This method should be permissioned to only allow designated parties to mint tokens.
   */
  function mint(address to, uint256 value) external returns (bool);

  /**
   * @notice Returns the number of decimals used to get its user representation.
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Provides addresses of the contracts implementing certain interfaces.
 */
interface ISynthereumFinder {
  /**
   * @notice Updates the address of the contract that implements `interfaceName`.
   * @param interfaceName bytes32 encoding of the interface name that is either changed or registered.
   * @param implementationAddress address of the deployed contract that implements the interface.
   */
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external;

  /**
   * @notice Gets the address of the contract that implements the given `interfaceName`.
   * @param interfaceName queried interface.
   * @return implementationAddress Address of the deployed contract that implements the interface.
   */
  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    returns (address);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ISynthereumPriceFeed {
  /**
   * @notice Get last chainlink oracle price for a given price identifier
   * @param priceIdentifier Price feed identifier
   * @return price Oracle price
   */
  function getLatestPrice(bytes32 priceIdentifier)
    external
    view
    returns (uint256 price);

  /**
   * @notice Return if price identifier is supported
   * @param priceIdentifier Price feed identifier
   * @return isSupported True if price is supported otherwise false
   */
  function isPriceSupported(bytes32 priceIdentifier)
    external
    view
    returns (bool isSupported);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ILendingStorageManager} from './ILendingStorageManager.sol';

interface ILendingManager {
  struct Roles {
    address admin;
    address maintainer;
  }

  struct ReturnValues {
    uint256 poolInterest; //accumulated pool interest since last state-changing operation;
    uint256 daoInterest; //acccumulated dao interest since last state-changing operation;
    uint256 tokensOut; //amount of tokens received from money market (including eventual fees)
    uint256 tokensTransferred; //amount of tokens finally transfered from money market (after eventual fees)
  }

  struct InterestSplit {
    uint256 poolInterest; // share of the total interest generated to the LPs;
    uint256 jrtInterest; // share of the total interest generated for jrt buyback;
    uint256 commissionInterest; // share of the total interest generated as dao commission;
  }

  struct MigrateReturnValues {
    uint256 prevDepositedCollateral; // prevDepositedCollateral collateral deposited (without last interests) before the migration
    uint256 poolInterest; // poolInterests collateral interests accumalated before the migration
    uint256 actualCollateralDeposited; // actualCollateralDeposited collateral deposited after the migration
  }

  /**
   * @notice deposits collateral into the pool's associated money market
   * @dev calculates and return the generated interest since last state-changing operation
   * @param collateralAmount amount of collateral to deposit
   * @param recipient the address receiving the interest tokens from money market
   * @return returnValues check struct
   */
  function deposit(uint256 collateralAmount, address recipient)
    external
    returns (ReturnValues memory returnValues);

  /**
   * @notice withdraw collateral from the pool's associated money market
   * @dev calculates and return the generated interest since last state-changing operation
   * @param interestTokenAmount amount of interest tokens to redeem
   * @param recipient the address receiving the collateral from money market
   * @return returnValues check struct
   */
  function withdraw(uint256 interestTokenAmount, address recipient)
    external
    returns (ReturnValues memory returnValues);

  /**
   * @notice calculate, split and update the generated interest of the caller pool since last state-changing operation
   * @return returnValues check struct
   */
  function updateAccumulatedInterest()
    external
    returns (ReturnValues memory returnValues);

  /**
   * @notice batches calls to redeem poolData.commissionInterest from multiple pools
   * @dev calculates and return the generated interest since last state-changing operation
   * @param pools array of pools to redeem commissions from
   * @param collateralAmounts array of amount of commission to redeem for each pool (matching pools order)
   */
  function batchClaimCommission(
    address[] memory pools,
    uint256[] memory collateralAmounts
  ) external;

  // TODO batching
  function executeBuyback(uint256 collateralAmount, bytes memory swapParams)
    external
    returns (ReturnValues memory returnValues);

  /**
   * @notice sets the address of the implementation of a lending module and its extraBytes
   * @param id associated to the lending module to be set
   * @param lendingInfo see lendingInfo struct
   */
  function setLendingModule(
    string memory id,
    ILendingStorageManager.LendingInfo memory lendingInfo
  ) external;

  /**
   * @notice sets an address as the swap module associated to a specific collateral
   * @dev the swapModule must implement the IJRTSwapModule interface
   * @param collateral collateral address associated to the swap module
   * @param swapModule IJRTSwapModule implementer contract
   */
  function setSwapModule(address collateral, address swapModule) external;

  /**
   * @notice set shares on interest generated by a pool collateral on the lending storage manager
   * @param pool pool address to set shares on
   * @param daoInterestShare share of total interest generated assigned to the dao
   * @param jrtBuybackShare share of the total dao interest used to buyback jrt from an AMM
   */
  function setShares(
    address pool,
    uint256 daoInterestShare,
    uint256 jrtBuybackShare
  ) external;

  /**
   * @notice migrates liquidity from one lending module (and money market), to a new one
   * @dev calculates and return the generated interest since last state-changing operation.
   * @dev The new lending module info must be have been previously set in the storage manager
   * @param newLendingID id associated to the new lending module info
   * @param newInterestBearingToken address of the interest token of the new money market
   * @param interestTokenAmount total amount of interest token to migrate from old to new money market
   * @return migrateReturnValues check struct
   */
  function migrateLendingModule(
    string memory newLendingID,
    address newInterestBearingToken,
    uint256 interestTokenAmount
  ) external returns (MigrateReturnValues memory);

  /**
   * @notice returns the conversion between collateral and interest token of a specific money market
   * @dev isExactTransfer indicates if the collateral has to be treated like exactInput or exactOutput
   * @dev considering potential money market fees that must be charged to the tx caller
   * @param pool reference pool to check conversion
   * @param collateralAmount amount of collateral to calculate conversion on
   * @param isExactTransfer indicates if the collateral has to be treated like exactInput or exactOutput
   * @return interestTokenAmount amount of interest token after conversion
   * @return interestTokenAddr address of the pool associated interest token
   */
  function collateralToInterestToken(
    address pool,
    uint256 collateralAmount,
    bool isExactTransfer
  )
    external
    view
    returns (uint256 interestTokenAmount, address interestTokenAddr);

  /**
   * @notice returns accumulated interest of a pool since state-changing last operation
   * @dev does not update state
   * @param pool reference pool to check accumulated interest
   * @return poolInterest amount of interest generated for the pool after splitting the dao share
   * @return daoInterest amount of interest generated for the dao after splitting the dao share
   * @return collateralDeposited total amount of collateral currently deposited by the pool
   */
  function getAccumulatedInterest(address pool)
    external
    view
    returns (
      uint256 poolInterest,
      uint256 daoInterest,
      uint256 collateralDeposited
    );
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ILendingStorageManager {
  struct PoolStorage {
    bytes32 lendingModuleId; // hash of the lending module id associated with the LendingInfo the pool currently is using
    address collateral; // collateral address of the pool
    address interestBearingToken; // interest token address of the pool
    uint256 JRTBuybackShare; // share of dao interest used to buyback JRT
    uint256 daoInterestShare; // share of total interest generated by the pool directed to the DAO
    uint256 collateralDeposited; // amount of collateral currently deposited in the MoneyMarket
    uint256 unclaimedDaoJRT; // amount of interest to be claimed to buyback JRT
    uint256 unclaimedDaoCommission; // amount of interest to be claimed as commission (in collateral)
  }

  struct LendingInfo {
    address lendingModule; // address of the ILendingModule interface implementer
    bytes args; // encoded args the ILendingModule implementer might need
  }

  /**
   * @notice sets a ILendingModule implementer info
   * @param id string identifying a specific ILendingModule implementer
   * @param lendingInfo see lendingInfo struct
   */
  function setLendingModule(string memory id, LendingInfo memory lendingInfo)
    external;

  /**
   * @notice sets an address as the swap module associated to a specific collateral
   * @dev the swapModule must implement the IJRTSwapModule interface
   * @param collateral collateral address associated to the swap module
   * @param swapModule IJRTSwapModule implementer contract
   */
  function setSwapModule(address collateral, address swapModule) external;

  /**
   * @notice set shares on interest generated by a pool collateral on the lending storage manager
   * @param pool pool address to set shares on
   * @param daoInterestShare share of total interest generated assigned to the dao
   * @param jrtBuybackShare share of the total dao interest used to buyback jrt from an AMM
   */
  function setShares(
    address pool,
    uint256 daoInterestShare,
    uint256 jrtBuybackShare
  ) external;

  /**
   * @notice store data for lending manager associated to a pool
   * @param lendingID string identifying the associated ILendingModule implementer
   * @param pool pool address to set info
   * @param collateral collateral address of the pool
   * @param interestBearingToken address of the interest token in use
   * @param daoInterestShare share of total interest generated assigned to the dao
   * @param jrtBuybackShare share of the total dao interest used to buyback jrt from an AMM
   */
  function setPoolStorage(
    string memory lendingID,
    address pool,
    address collateral,
    address interestBearingToken,
    uint256 daoInterestShare,
    uint256 jrtBuybackShare
  ) external;

  /**
   * @notice assign oldPool storage information and state to newPool address and deletes oldPool storage slot
   * @dev is used when a pool is redeployed and the liquidity transferred over
   * @param oldPool address of old pool to migrate storage from
   * @param newPool address of the new pool receiving state of oldPool
   */
  function migratePool(address oldPool, address newPool) external;

  /**
   * @notice sets new lending info on a pool
   * @dev used when migrating liquidity from one lending module (and money market), to a new one
   * @dev The new lending module info must be have been previously set in the storage manager
   * @param newLendingID id associated to the new lending module info
   * @param pool address of the pool whose associated lending module is being migrated
   * @param newInterestToken address of the interest token of the new Lending Module (can be set blank)
   * @return poolData with the updated state
   * @return lendingInfo of the new lending module
   */
  function migrateLendingModule(
    string memory newLendingID,
    address pool,
    address newInterestToken
  ) external returns (PoolStorage memory, LendingInfo memory);

  /**
   * @notice updates storage of a pool
   * @dev should be callable only by LendingManager after state-changing operations
   * @param pool address of the pool to update values
   * @param collateralDeposited updated amount of collateral deposited
   * @param daoJRT updated amount of unclaimed interest for JRT buyback
   * @param daoInterest updated amount of unclaimed interest as dao commission
   */
  function updateValues(
    address pool,
    uint256 collateralDeposited,
    uint256 daoJRT,
    uint256 daoInterest
  ) external;

  /**
   * @notice reads PoolStorage and LendingInfo of a pool
   * @param pool address of the pool to read storage
   * @return poolData pool struct info
   * @return lendingInfo information of the lending module associated with the pool
   */
  function getPoolStorage(address pool)
    external
    view
    returns (PoolStorage memory poolData, LendingInfo memory lendingInfo);

  /**
   * @notice reads PoolStorage of a pool
   * @param pool address of the pool to read storage
   * @return poolData pool struct info
   */
  function getPoolData(address pool)
    external
    view
    returns (PoolStorage memory poolData);

  /**
   * @notice reads the JRT Buyback module associated to a collateral
   * @param collateral address of the collateral to retrieve module
   * @return address interface implementer of the IJRTSwapModule
   */
  function getCollateralSwapModule(address collateral)
    external
    view
    returns (address);

  /**
   * @notice reads the interest beaaring token address associated to a pool
   * @param pool address of the pool to retrieve interest token
   * @return interestTokenAddr address of the interest token
   */
  function getInterestBearingToken(address pool)
    external
    view
    returns (address interestTokenAddr);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title Stores common interface names used throughout Synthereum.
 */
library SynthereumInterfaces {
  bytes32 public constant Deployer = 'Deployer';
  bytes32 public constant FactoryVersioning = 'FactoryVersioning';
  bytes32 public constant TokenFactory = 'TokenFactory';
  bytes32 public constant PoolRegistry = 'PoolRegistry';
  bytes32 public constant SelfMintingRegistry = 'SelfMintingRegistry';
  bytes32 public constant PriceFeed = 'PriceFeed';
  bytes32 public constant Manager = 'Manager';
  bytes32 public constant CreditLineController = 'CreditLineController';
  bytes32 public constant CollateralWhitelist = 'CollateralWhitelist';
  bytes32 public constant IdentifierWhitelist = 'IdentifierWhitelist';
  bytes32 public constant TrustedForwarder = 'TrustedForwarder';
  bytes32 public constant FixedRateRegistry = 'FixedRateRegistry';
  bytes32 public constant MoneyMarketManager = 'MoneyMarketManager';
  bytes32 public constant JarvisBrrrrr = 'JarvisBrrrrr';
  bytes32 public constant PrinterProxy = 'PrinterProxy';
  bytes32 public constant LendingManager = 'LendingManager';
  bytes32 public constant LendingStorageManager = 'LendingStorageManager';
}

library FactoryInterfaces {
  bytes32 public constant PoolFactory = 'PoolFactory';
  bytes32 public constant SelfMintingFactory = 'SelfMintingFactory';
  bytes32 public constant FixedRateFactory = 'FixedRateFactory';
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

/**
 * @title PreciseUnitMath
 * @author Synthereum Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision.
 *
 */
library PreciseUnitMath {
  // The number One in precise units.
  uint256 internal constant PRECISE_UNIT = 10**18;

  // Max unsigned integer value
  uint256 internal constant MAX_UINT_256 = type(uint256).max;

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function preciseUnit() internal pure returns (uint256) {
    return PRECISE_UNIT;
  }

  /**
   * @dev Getter function since constants can't be read directly from libraries.
   */
  function maxUint256() internal pure returns (uint256) {
    return MAX_UINT_256;
  }

  /**
   * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
   * of a number with 18 decimals precision.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * b) / PRECISE_UNIT;
  }

  /**
   * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
   * of a number with 18 decimals precision.
   */
  function mulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (((a * b) - 1) / PRECISE_UNIT) + 1;
  }

  /**
   * @dev Divides value a by value b (result is rounded down).
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return (a * PRECISE_UNIT) / b;
  }

  /**
   * @dev Divides value a by value b (result is rounded up or away from 0).
   */
  function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Cant divide by 0');

    return a > 0 ? (((a * PRECISE_UNIT) - 1) / b) + 1 : 0;
  }

  /**
   * @dev Performs the power on a specified value, reverts on overflow.
   */
  function safePower(uint256 a, uint256 pow) internal pure returns (uint256) {
    require(a > 0, 'Value must be positive');

    uint256 result = 1;
    for (uint256 i = 0; i < pow; i++) {
      uint256 previousResult = result;

      result = previousResult * a;
    }

    return result;
  }

  /**
   * @dev The minimum of `a` and `b`.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @dev The maximum of `a` and `b`.
   */
  function max(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? a : b;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import {Context} from '../../@openzeppelin/contracts/utils/Context.sol';

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
  function isTrustedForwarder(address forwarder)
    public
    view
    virtual
    returns (bool);

  function _msgSender()
    internal
    view
    virtual
    override
    returns (address sender)
  {
    if (isTrustedForwarder(msg.sender)) {
      // The assembly code is more direct than the Solidity version using `abi.decode`.
      assembly {
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else {
      return super._msgSender();
    }
  }

  function _msgData() internal view virtual override returns (bytes calldata) {
    if (isTrustedForwarder(msg.sender)) {
      return msg.data[0:msg.data.length - 20];
    } else {
      return super._msgData();
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ITypology {
  /**
   * @notice Return typology of the contract
   */
  function typology() external view returns (string memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';

/**
 * @title Interface that a pool MUST have in order to be included in the deployer
 */
interface ISynthereumDeployment {
  /**
   * @notice Get Synthereum finder of the pool/self-minting derivative
   * @return finder Returns finder contract
   */
  function synthereumFinder() external view returns (ISynthereumFinder finder);

  /**
   * @notice Get Synthereum version
   * @return contractVersion Returns the version of this pool/self-minting derivative
   */
  function version() external view returns (uint8 contractVersion);

  /**
   * @notice Get the collateral token of this pool/self-minting derivative
   * @return collateralCurrency The ERC20 collateral token
   */
  function collateralToken() external view returns (IERC20 collateralCurrency);

  /**
   * @notice Get the synthetic token associated to this pool/self-minting derivative
   * @return syntheticCurrency The ERC20 synthetic token
   */
  function syntheticToken() external view returns (IERC20 syntheticCurrency);

  /**
   * @notice Get the synthetic token symbol associated to this pool/self-minting derivative
   * @return symbol The ERC20 synthetic token symbol
   */
  function syntheticTokenSymbol() external view returns (string memory symbol);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../../../../../@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../../../@openzeppelin/contracts/utils/math/SignedSafeMath.sol";

/**
 * @title Library for fixed point arithmetic on uints
 */
library FixedPoint {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For unsigned values:
    //   This can represent a value up to (2^256 - 1)/10^18 = ~10^59. 10^59 will be stored internally as uint256 10^77.
    uint256 private constant FP_SCALING_FACTOR = 10**18;

    // --------------------------------------- UNSIGNED -----------------------------------------------------------------------------
    struct Unsigned {
        uint256 rawValue;
    }

    /**
     * @notice Constructs an `Unsigned` from an unscaled uint, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a uint to convert into a FixedPoint.
     * @return the converted FixedPoint.
     */
    function fromUnscaledUint(uint256 a) internal pure returns (Unsigned memory) {
        return Unsigned(a.mul(FP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if equal, or False.
     */
    function isEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a < b`, or False.
     */
    function isLessThan(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, Unsigned memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Unsigned memory a, uint256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledUint(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(uint256 a, Unsigned memory b) internal pure returns (bool) {
        return fromUnscaledUint(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the minimum of `a` and `b`.
     */
    function min(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the maximum of `a` and `b`.
     */
    function max(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Unsigned` to an unscaled uint, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the sum of `a` and `b`.
     */
    function add(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return add(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts two `Unsigned`s, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled uint256 from an `Unsigned`, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the difference of `a` and `b`.
     */
    function sub(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return sub(a, fromUnscaledUint(b));
    }

    /**
     * @notice Subtracts an `Unsigned` from an unscaled uint256, reverting on overflow.
     * @param a a uint256.
     * @param b a FixedPoint.
     * @return the difference of `a` and `b`.
     */
    function sub(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return sub(fromUnscaledUint(a), b);
    }

    /**
     * @notice Multiplies two `Unsigned`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as a uint256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because FP_SCALING_FACTOR != 0.
        return Unsigned(a.rawValue.mul(b.rawValue) / FP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.
     * @param b a uint256.
     * @return the product of `a` and `b`.
     */
    function mul(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Unsigned`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 mulRaw = a.rawValue.mul(b.rawValue);
        uint256 mulFloor = mulRaw / FP_SCALING_FACTOR;
        uint256 mod = mulRaw.mod(FP_SCALING_FACTOR);
        if (mod != 0) {
            return Unsigned(mulFloor.add(1));
        } else {
            return Unsigned(mulFloor);
        }
    }

    /**
     * @notice Multiplies an `Unsigned` and an unscaled uint256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.
     * @param b a FixedPoint.
     * @return the product of `a` and `b`.
     */
    function mulCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Unsigned(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as a uint256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Unsigned(a.rawValue.mul(FP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        return Unsigned(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled uint256 by an `Unsigned`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a uint256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(uint256 a, Unsigned memory b) internal pure returns (Unsigned memory) {
        return div(fromUnscaledUint(a), b);
    }

    /**
     * @notice Divides one `Unsigned` by an `Unsigned` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, Unsigned memory b) internal pure returns (Unsigned memory) {
        uint256 aScaled = a.rawValue.mul(FP_SCALING_FACTOR);
        uint256 divFloor = aScaled.div(b.rawValue);
        uint256 mod = aScaled.mod(b.rawValue);
        if (mod != 0) {
            return Unsigned(divFloor.add(1));
        } else {
            return Unsigned(divFloor);
        }
    }

    /**
     * @notice Divides one `Unsigned` by an unscaled uint256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divCeil(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Unsigned(a.rawValue.div(b))"
        // similarly to mulCeil with a uint256 as the second parameter. Therefore we need to convert b into an Unsigned.
        // This creates the possibility of overflow if b is very large.
        return divCeil(a, fromUnscaledUint(b));
    }

    /**
     * @notice Raises an `Unsigned` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint numerator.
     * @param b a uint256 denominator.
     * @return output is `a` to the power of `b`.
     */
    function pow(Unsigned memory a, uint256 b) internal pure returns (Unsigned memory output) {
        output = fromUnscaledUint(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }

    // ------------------------------------------------- SIGNED -------------------------------------------------------------
    // Supports 18 decimals. E.g., 1e18 represents "1", 5e17 represents "0.5".
    // For signed values:
    //   This can represent a value up (or down) to +-(2^255 - 1)/10^18 = ~10^58. 10^58 will be stored internally as int256 10^76.
    int256 private constant SFP_SCALING_FACTOR = 10**18;

    struct Signed {
        int256 rawValue;
    }

    function fromSigned(Signed memory a) internal pure returns (Unsigned memory) {
        require(a.rawValue >= 0, "Negative value provided");
        return Unsigned(uint256(a.rawValue));
    }

    function fromUnsigned(Unsigned memory a) internal pure returns (Signed memory) {
        require(a.rawValue <= uint256(type(int256).max), "Unsigned too large");
        return Signed(int256(a.rawValue));
    }

    /**
     * @notice Constructs a `Signed` from an unscaled int, e.g., `b=5` gets stored internally as `5*(10**18)`.
     * @param a int to convert into a FixedPoint.Signed.
     * @return the converted FixedPoint.Signed.
     */
    function fromUnscaledInt(int256 a) internal pure returns (Signed memory) {
        return Signed(a.mul(SFP_SCALING_FACTOR));
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a int256.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue == fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if equal, or False.
     */
    function isEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue == b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue > fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a > b`, or False.
     */
    function isGreaterThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue > b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue >= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is greater than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a >= b`, or False.
     */
    function isGreaterThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue >= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a < b`, or False.
     */
    function isLessThan(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue < fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a < b`, or False.
     */
    function isLessThan(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue < b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, Signed memory b) internal pure returns (bool) {
        return a.rawValue <= b.rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(Signed memory a, int256 b) internal pure returns (bool) {
        return a.rawValue <= fromUnscaledInt(b).rawValue;
    }

    /**
     * @notice Whether `a` is less than or equal to `b`.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return True if `a <= b`, or False.
     */
    function isLessThanOrEqual(int256 a, Signed memory b) internal pure returns (bool) {
        return fromUnscaledInt(a).rawValue <= b.rawValue;
    }

    /**
     * @notice The minimum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the minimum of `a` and `b`.
     */
    function min(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue < b.rawValue ? a : b;
    }

    /**
     * @notice The maximum of `a` and `b`.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the maximum of `a` and `b`.
     */
    function max(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return a.rawValue > b.rawValue ? a : b;
    }

    /**
     * @notice Adds two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.add(b.rawValue));
    }

    /**
     * @notice Adds an `Signed` to an unscaled int, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the sum of `a` and `b`.
     */
    function add(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return add(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts two `Signed`s, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.sub(b.rawValue));
    }

    /**
     * @notice Subtracts an unscaled int256 from an `Signed`, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the difference of `a` and `b`.
     */
    function sub(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return sub(a, fromUnscaledInt(b));
    }

    /**
     * @notice Subtracts an `Signed` from an unscaled int256, reverting on overflow.
     * @param a an int256.
     * @param b a FixedPoint.Signed.
     * @return the difference of `a` and `b`.
     */
    function sub(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return sub(fromUnscaledInt(a), b);
    }

    /**
     * @notice Multiplies two `Signed`s, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max output for the represented number is ~10^41, otherwise an intermediate value overflows. 10^41 is
        // stored internally as an int256 ~10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 1.4 * 2e-18 = 2.8e-18, which
        // would round to 3, but this computation produces the result 2.
        // No need to use SafeMath because SFP_SCALING_FACTOR != 0.
        return Signed(a.rawValue.mul(b.rawValue) / SFP_SCALING_FACTOR);
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256, reverting on overflow.
     * @dev This will "floor" the product.
     * @param a a FixedPoint.Signed.
     * @param b an int256.
     * @return the product of `a` and `b`.
     */
    function mul(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Multiplies two `Signed`s and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 mulRaw = a.rawValue.mul(b.rawValue);
        int256 mulTowardsZero = mulRaw / SFP_SCALING_FACTOR;
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = mulRaw % SFP_SCALING_FACTOR;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(mulTowardsZero.add(valueToAdd));
        } else {
            return Signed(mulTowardsZero);
        }
    }

    /**
     * @notice Multiplies an `Signed` and an unscaled int256 and "ceil's" the product, reverting on overflow.
     * @param a a FixedPoint.Signed.
     * @param b a FixedPoint.Signed.
     * @return the product of `a` and `b`.
     */
    function mulAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Since b is an int, there is no risk of truncation and we can just mul it normally
        return Signed(a.rawValue.mul(b));
    }

    /**
     * @notice Divides one `Signed` by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        // There are two caveats with this computation:
        // 1. Max value for the number dividend `a` represents is ~10^41, otherwise an intermediate value overflows.
        // 10^41 is stored internally as an int256 10^59.
        // 2. Results that can't be represented exactly are truncated not rounded. E.g., 2 / 3 = 0.6 repeating, which
        // would round to 0.666666666666666667, but this computation produces the result 0.666666666666666666.
        return Signed(a.rawValue.mul(SFP_SCALING_FACTOR).div(b.rawValue));
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(Signed memory a, int256 b) internal pure returns (Signed memory) {
        return Signed(a.rawValue.div(b));
    }

    /**
     * @notice Divides one unscaled int256 by an `Signed`, reverting on overflow or division by 0.
     * @dev This will "floor" the quotient.
     * @param a an int256 numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function div(int256 a, Signed memory b) internal pure returns (Signed memory) {
        return div(fromUnscaledInt(a), b);
    }

    /**
     * @notice Divides one `Signed` by an `Signed` and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b a FixedPoint denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, Signed memory b) internal pure returns (Signed memory) {
        int256 aScaled = a.rawValue.mul(SFP_SCALING_FACTOR);
        int256 divTowardsZero = aScaled.div(b.rawValue);
        // Manual mod because SignedSafeMath doesn't support it.
        int256 mod = aScaled % b.rawValue;
        if (mod != 0) {
            bool isResultPositive = isLessThan(a, 0) == isLessThan(b, 0);
            int256 valueToAdd = isResultPositive ? int256(1) : int256(-1);
            return Signed(divTowardsZero.add(valueToAdd));
        } else {
            return Signed(divTowardsZero);
        }
    }

    /**
     * @notice Divides one `Signed` by an unscaled int256 and "ceil's" the quotient, reverting on overflow or division by 0.
     * @param a a FixedPoint numerator.
     * @param b an int256 denominator.
     * @return the quotient of `a` divided by `b`.
     */
    function divAwayFromZero(Signed memory a, int256 b) internal pure returns (Signed memory) {
        // Because it is possible that a quotient gets truncated, we can't just call "Signed(a.rawValue.div(b))"
        // similarly to mulCeil with an int256 as the second parameter. Therefore we need to convert b into an Signed.
        // This creates the possibility of overflow if b is very large.
        return divAwayFromZero(a, fromUnscaledInt(b));
    }

    /**
     * @notice Raises an `Signed` to the power of an unscaled uint256, reverting on overflow. E.g., `b=2` squares `a`.
     * @dev This will "floor" the result.
     * @param a a FixedPoint.Signed.
     * @param b a uint256 (negative exponents are not allowed).
     * @return output is `a` to the power of `b`.
     */
    function pow(Signed memory a, uint256 b) internal pure returns (Signed memory output) {
        output = fromUnscaledInt(1);
        for (uint256 i = 0; i < b; i = i.add(1)) {
            output = mul(output, a);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableTokenFactory
} from '../../tokens/factories/interfaces/IMintableBurnableTokenFactory.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumMultiLpLiquidityPool
} from './interfaces/IMultiLpLiquidityPool.sol';
import {
  IMintableBurnableERC20
} from '../../tokens/interfaces/IMintableBurnableERC20.sol';
import {
  ILendingStorageManager
} from '../../lending-module/interfaces/ILendingStorageManager.sol';
import {
  BaseControlledMintableBurnableERC20
} from '../../tokens/interfaces/BaseControlledMintableBurnableERC20.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {Clones} from '../../../@openzeppelin/contracts/proxy/Clones.sol';
import {SynthereumMultiLpLiquidityPool} from './MultiLpLiquidityPool.sol';

contract SynthereumMultiLpLiquidityPoolCreator {
  using Clones for address;

  struct Params {
    uint8 version;
    IStandardERC20 collateralToken;
    string syntheticName;
    string syntheticSymbol;
    address syntheticToken;
    ISynthereumMultiLpLiquidityPool.Roles roles;
    uint256 fee;
    bytes32 priceIdentifier;
    uint256 overCollateralRequirement;
    uint256 liquidationReward;
    LendingManagerParams lendingManagerParams;
  }

  struct LendingManagerParams {
    string lendingId;
    address interestBearingToken;
    uint256 daoInterestShare;
    uint256 jrtBuybackShare;
  }

  // Address of Synthereum Finder
  ISynthereumFinder public immutable synthereumFinder;

  address public immutable poolImplementation;

  //----------------------------------------
  // Events
  //----------------------------------------
  event CreatedPool(
    address indexed poolAddress,
    uint8 indexed version,
    address indexed deployerAddress
  );

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs the Pool contract.
   * @param _synthereumFinder Synthereum Finder address used to discover other contracts
   * @param _poolImplementation Address of the deployed pool implementation used for EIP1167
   */
  constructor(address _synthereumFinder, address _poolImplementation) {
    synthereumFinder = ISynthereumFinder(_synthereumFinder);
    poolImplementation = _poolImplementation;
  }

  //----------------------------------------
  // Public functions
  //----------------------------------------

  /**
   * @notice Creates an instance of the pool
   * @param _params is a `ConstructorParams` object from LiquidityPool.
   * @return pool address of the deployed pool contract.
   */
  function createPool(Params calldata _params)
    public
    virtual
    returns (ISynthereumMultiLpLiquidityPool pool)
  {
    pool = ISynthereumMultiLpLiquidityPool(poolImplementation.clone());
    require(bytes(_params.syntheticName).length != 0, 'Missing synthetic name');
    require(
      bytes(_params.syntheticSymbol).length != 0,
      'Missing synthetic symbol'
    );
    BaseControlledMintableBurnableERC20 tokenCurrency;
    if (_params.syntheticToken == address(0)) {
      IMintableBurnableTokenFactory tokenFactory =
        IMintableBurnableTokenFactory(
          ISynthereumFinder(synthereumFinder).getImplementationAddress(
            SynthereumInterfaces.TokenFactory
          )
        );
      tokenCurrency = tokenFactory.createToken(
        _params.syntheticName,
        _params.syntheticSymbol,
        18
      );
      // Give permissions to new pool contract and then hand over ownership.
      tokenCurrency.addMinter(address(pool));
      tokenCurrency.addBurner(address(pool));
      tokenCurrency.addAdmin(
        synthereumFinder.getImplementationAddress(SynthereumInterfaces.Manager)
      );
      tokenCurrency.renounceAdmin();
    } else {
      tokenCurrency = BaseControlledMintableBurnableERC20(
        _params.syntheticToken
      );
      require(
        keccak256(abi.encodePacked(tokenCurrency.name())) ==
          keccak256(abi.encodePacked(_params.syntheticName)),
        'Wrong synthetic token name'
      );
      require(
        keccak256(abi.encodePacked(tokenCurrency.symbol())) ==
          keccak256(abi.encodePacked(_params.syntheticSymbol)),
        'Wrong synthetic token symbol'
      );
    }
    pool.initialize(_convertParams(_params, tokenCurrency));
    _setPoolParams(
      address(pool),
      address(_params.collateralToken),
      _params.lendingManagerParams
    );
    emit CreatedPool(address(pool), _params.version, msg.sender);
  }

  // Converts createPool params to constructor params.
  function _convertParams(
    Params memory _params,
    BaseControlledMintableBurnableERC20 _tokenCurrency
  )
    internal
    view
    returns (
      SynthereumMultiLpLiquidityPool.InitializationParams
        memory initializationParams
    )
  {
    require(_params.roles.admin != address(0), 'Admin cannot be 0x00');
    initializationParams.finder = synthereumFinder;
    initializationParams.version = _params.version;
    initializationParams.collateralToken = _params.collateralToken;
    initializationParams.syntheticToken = IMintableBurnableERC20(
      address(_tokenCurrency)
    );
    initializationParams.roles = _params.roles;
    initializationParams.fee = _params.fee;
    initializationParams.priceIdentifier = _params.priceIdentifier;
    initializationParams.overCollateralRequirement = _params
      .overCollateralRequirement;
    initializationParams.liquidationReward = _params.liquidationReward;
    initializationParams.lendingModuleId = _params
      .lendingManagerParams
      .lendingId;
  }

  // Set lending module params of the pool in the LendingStorageManager
  function _setPoolParams(
    address _pool,
    address _collateral,
    LendingManagerParams calldata _lendingManagerParams
  ) internal {
    ILendingStorageManager lendingStorageManager =
      ILendingStorageManager(
        synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.LendingStorageManager
        )
      );
    lendingStorageManager.setPoolStorage(
      _lendingManagerParams.lendingId,
      _pool,
      _collateral,
      _lendingManagerParams.interestBearingToken,
      _lendingManagerParams.daoInterestShare,
      _lendingManagerParams.jrtBuybackShare
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;
import {
  BaseControlledMintableBurnableERC20
} from '../../interfaces/BaseControlledMintableBurnableERC20.sol';

/**
 * @title Interface for interacting with the MintableBurnableTokenFactory contract
 */
interface IMintableBurnableTokenFactory {
  /** @notice Calls the deployment of a new ERC20 token
   * @param tokenName The name of the token to be deployed
   * @param tokenSymbol The symbol of the token that will be deployed
   * @param tokenDecimals Number of decimals for the token to be deployed
   */
  function createToken(
    string memory tokenName,
    string memory tokenSymbol,
    uint8 tokenDecimals
  ) external returns (BaseControlledMintableBurnableERC20 newToken);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from '../../../@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IMintableBurnableERC20} from './IMintableBurnableERC20.sol';

/**
 * @title ERC20 interface that includes burn mint and roles methods.
 */
abstract contract BaseControlledMintableBurnableERC20 is
  ERC20,
  IMintableBurnableERC20
{
  uint8 private _decimals;

  /**
   * @notice Constructs the ERC20 token contract
   * @param _tokenName Name of the token
   * @param _tokenSymbol Token symbol
   * @param _tokenDecimals Number of decimals for token
   */
  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint8 _tokenDecimals
  ) ERC20(_tokenName, _tokenSymbol) {
    _setupDecimals(_tokenDecimals);
  }

  /**
   * @notice Add Minter role to an account
   * @param account Address to which Minter role will be added
   */
  function addMinter(address account) external virtual;

  /**
   * @notice Add Burner role to an account
   * @param account Address to which Burner role will be added
   */
  function addBurner(address account) external virtual;

  /**
   * @notice Add Admin role to an account
   * @param account Address to which Admin role will be added
   */
  function addAdmin(address account) external virtual;

  /**
   * @notice Add Admin, Minter and Burner roles to an account
   * @param account Address to which Admin, Minter and Burner roles will be added
   */
  function addAdminAndMinterAndBurner(address account) external virtual;

  /**
   * @notice Add Admin, Minter and Burner roles to an account
   * @param account Address to which Admin, Minter and Burner roles will be added
   */
  /**
   * @notice Self renounce the address calling the function from minter role
   */
  function renounceMinter() external virtual;

  /**
   * @notice Self renounce the address calling the function from burner role
   */
  function renounceBurner() external virtual;

  /**
   * @notice Self renounce the address calling the function from admin role
   */
  function renounceAdmin() external virtual;

  /**
   * @notice Self renounce the address calling the function from admin, minter and burner role
   */
  function renounceAdminAndMinterAndBurner() external virtual;

  /**
   * @notice Returns the number of decimals used to get its user representation.
   */
  function decimals()
    public
    view
    virtual
    override(ERC20, IMintableBurnableERC20)
    returns (uint8)
  {
    return _decimals;
  }

  /**
   * @dev Sets {decimals} to a value other than the default one of 18.
   *
   * WARNING: This function should only be called from the constructor. Most
   * applications that interact with token contracts will not expect
   * {decimals} to ever change, and may work incorrectly if it does.
   */
  function _setupDecimals(uint8 decimals_) internal {
    _decimals = decimals_;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {
  IDeploymentSignature
} from '../../core/interfaces/IDeploymentSignature.sol';
import {
  SynthereumMultiLpLiquidityPoolCreator
} from './MultiLpLiquidityPoolCreator.sol';
import {
  ISynthereumMultiLpLiquidityPool
} from './interfaces/IMultiLpLiquidityPool.sol';
import {FactoryConditions} from '../../common/FactoryConditions.sol';
import {
  ReentrancyGuard
} from '../../../@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract SynthereumMultiLpLiquidityPoolFactory is
  IDeploymentSignature,
  ReentrancyGuard,
  FactoryConditions,
  SynthereumMultiLpLiquidityPoolCreator
{
  //----------------------------------------
  // Storage
  //----------------------------------------

  bytes4 public immutable override deploymentSignature;

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Set synthereum finder
   * @param _synthereumFinder Synthereum finder contract
   * @param _poolImplementation Address of the deployed pool implementation used for EIP1167
   */
  constructor(address _synthereumFinder, address _poolImplementation)
    SynthereumMultiLpLiquidityPoolCreator(
      _synthereumFinder,
      _poolImplementation
    )
  {
    deploymentSignature = this.createPool.selector;
  }

  //----------------------------------------
  // Public functions
  //----------------------------------------

  /**
   * @notice Check if the sender is the deployer and deploy a pool
   * @param params input parameters of the pool
   * @return pool Deployed pool
   */
  function createPool(Params calldata params)
    public
    override
    nonReentrant
    returns (ISynthereumMultiLpLiquidityPool pool)
  {
    checkDeploymentConditions(
      synthereumFinder,
      params.collateralToken,
      params.priceIdentifier
    );
    pool = super.createPool(params);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Provides signature of function for deployment
 */
interface IDeploymentSignature {
  /**
   * @notice Returns the bytes4 signature of the function used for the deployment of a contract in a factory
   * @return signature returns signature of the deployment function
   */
  function deploymentSignature() external view returns (bytes4 signature);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IStandardERC20} from '../base/interfaces/IStandardERC20.sol';
import {ISynthereumFinder} from '../core/interfaces/IFinder.sol';
import {
  ISynthereumCollateralWhitelist
} from '../core/interfaces/ICollateralWhitelist.sol';
import {
  ISynthereumIdentifierWhitelist
} from '../core/interfaces/IIdentifierWhitelist.sol';
import {SynthereumInterfaces} from '../core/Constants.sol';

/** @title Contract factory of self-minting derivatives
 */
contract FactoryConditions {
  /**
   * @notice Check if the sender is the deployer and if identifier and collateral are supported
   * @param synthereumFinder Synthereum finder
   * @param collateralToken Collateral token to check if it's in the whithelist
   * @param priceFeedIdentifier Identifier to check if it's in the whithelist
   */
  function checkDeploymentConditions(
    ISynthereumFinder synthereumFinder,
    IStandardERC20 collateralToken,
    bytes32 priceFeedIdentifier
  ) internal view {
    address deployer =
      synthereumFinder.getImplementationAddress(SynthereumInterfaces.Deployer);
    require(msg.sender == deployer, 'Sender must be Synthereum deployer');
    ISynthereumCollateralWhitelist collateralWhitelist =
      ISynthereumCollateralWhitelist(
        synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.CollateralWhitelist
        )
      );
    require(
      collateralWhitelist.isOnWhitelist(address(collateralToken)),
      'Collateral not supported'
    );
    ISynthereumIdentifierWhitelist identifierWhitelist =
      ISynthereumIdentifierWhitelist(
        synthereumFinder.getImplementationAddress(
          SynthereumInterfaces.IdentifierWhitelist
        )
      );
    require(
      identifierWhitelist.isOnWhitelist(priceFeedIdentifier),
      'Identifier not supported'
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title An interface to track a whitelist of addresses.
 */
interface ISynthereumCollateralWhitelist {
  /**
   * @notice Adds an address to the whitelist.
   * @param newCollateral the new address to add.
   */
  function addToWhitelist(address newCollateral) external;

  /**
   * @notice Removes an address from the whitelist.
   * @param collateralToRemove The existing address to remove.
   */
  function removeFromWhitelist(address collateralToRemove) external;

  /**
   * @notice Checks whether an address is on the whitelist.
   * @param collateralToCheck The address to check.
   * @return True if `collateralToCheck` is on the whitelist, or False.
   */
  function isOnWhitelist(address collateralToCheck)
    external
    view
    returns (bool);

  /**
   * @notice Gets all addresses that are currently included in the whitelist.
   * @return The list of addresses on the whitelist.
   */
  function getWhitelist() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title An interface to track a whitelist of identifiers.
 */
interface ISynthereumIdentifierWhitelist {
  /**
   * @notice Adds an identifier to the whitelist.
   * @param newIdentifier the new identifier to add.
   */
  function addToWhitelist(bytes32 newIdentifier) external;

  /**
   * @notice Removes an identifier from the whitelist.
   * @param identifierToRemove The existing identifier to remove.
   */
  function removeFromWhitelist(bytes32 identifierToRemove) external;

  /**
   * @notice Checks whether an address is on the whitelist.
   * @param identifierToCheck The address to check.
   * @return True if `identifierToCheck` is on the whitelist, or False.
   */
  function isOnWhitelist(bytes32 identifierToCheck)
    external
    view
    returns (bool);

  /**
   * @notice Gets all identifiers that are currently included in the whitelist.
   * @return The list of identifiers on the whitelist.
   */
  function getWhitelist() external view returns (bytes32[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  IDeploymentSignature
} from '../../core/interfaces/IDeploymentSignature.sol';
import {
  ISynthereumCollateralWhitelist
} from '../../core/interfaces/ICollateralWhitelist.sol';
import {
  ISynthereumIdentifierWhitelist
} from '../../core/interfaces/IIdentifierWhitelist.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {SynthereumLiquidityPoolCreator} from './LiquidityPoolCreator.sol';
import {SynthereumLiquidityPool} from './LiquidityPool.sol';
import {FactoryConditions} from '../../common/FactoryConditions.sol';
import {
  ReentrancyGuard
} from '../../../@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract SynthereumLiquidityPoolFactory is
  IDeploymentSignature,
  ReentrancyGuard,
  FactoryConditions,
  SynthereumLiquidityPoolCreator
{
  //----------------------------------------
  // Storage
  //----------------------------------------

  bytes4 public immutable override deploymentSignature;

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Set synthereum finder
   * @param synthereumFinder Synthereum finder contract
   */
  constructor(address synthereumFinder)
    SynthereumLiquidityPoolCreator(synthereumFinder)
  {
    deploymentSignature = this.createPool.selector;
  }

  //----------------------------------------
  // Public functions
  //----------------------------------------

  /**
   * @notice Check if the sender is the deployer and deploy a pool
   * @param params input parameters of the pool
   * @return pool Deployed pool
   */
  function createPool(Params calldata params)
    public
    override
    nonReentrant
    returns (SynthereumLiquidityPool pool)
  {
    checkDeploymentConditions(
      synthereumFinder,
      params.collateralToken,
      params.priceIdentifier
    );
    pool = super.createPool(params);
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableTokenFactory
} from '../../tokens/factories/interfaces/IMintableBurnableTokenFactory.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumLiquidityPoolStorage
} from './interfaces/ILiquidityPoolStorage.sol';
import {
  IMintableBurnableERC20
} from '../../tokens/interfaces/IMintableBurnableERC20.sol';
import {
  BaseControlledMintableBurnableERC20
} from '../../tokens/interfaces/BaseControlledMintableBurnableERC20.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {SynthereumLiquidityPool} from './LiquidityPool.sol';

contract SynthereumLiquidityPoolCreator {
  struct Params {
    IStandardERC20 collateralToken;
    string syntheticName;
    string syntheticSymbol;
    address syntheticToken;
    ISynthereumLiquidityPoolStorage.Roles roles;
    uint256 overCollateralization;
    ISynthereumLiquidityPoolStorage.FeeData feeData;
    bytes32 priceIdentifier;
    uint256 collateralRequirement;
    uint256 liquidationReward;
    uint8 version;
  }

  // Address of Synthereum Finder
  ISynthereumFinder public immutable synthereumFinder;

  //----------------------------------------
  // Events
  //----------------------------------------
  event CreatedPool(
    address indexed poolAddress,
    uint8 indexed version,
    address indexed deployerAddress
  );

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructs the Pool contract.
   * @param _synthereumFinder Synthereum Finder address used to discover other contracts
   */
  constructor(address _synthereumFinder) {
    synthereumFinder = ISynthereumFinder(_synthereumFinder);
  }

  //----------------------------------------
  // Public functions
  //----------------------------------------

  /**
   * @notice Creates an instance of the pool
   * @param params is a `ConstructorParams` object from LiquidityPool.
   * @return pool address of the deployed pool contract.
   */
  function createPool(Params calldata params)
    public
    virtual
    returns (SynthereumLiquidityPool pool)
  {
    require(bytes(params.syntheticName).length != 0, 'Missing synthetic name');
    require(
      bytes(params.syntheticSymbol).length != 0,
      'Missing synthetic symbol'
    );

    if (params.syntheticToken == address(0)) {
      IMintableBurnableTokenFactory tokenFactory =
        IMintableBurnableTokenFactory(
          ISynthereumFinder(synthereumFinder).getImplementationAddress(
            SynthereumInterfaces.TokenFactory
          )
        );
      BaseControlledMintableBurnableERC20 tokenCurrency =
        tokenFactory.createToken(
          params.syntheticName,
          params.syntheticSymbol,
          18
        );
      pool = new SynthereumLiquidityPool(_convertParams(params, tokenCurrency));
      // Give permissions to new pool contract and then hand over ownership.
      tokenCurrency.addMinter(address(pool));
      tokenCurrency.addBurner(address(pool));
      tokenCurrency.addAdmin(
        synthereumFinder.getImplementationAddress(SynthereumInterfaces.Manager)
      );
      tokenCurrency.renounceAdmin();
    } else {
      BaseControlledMintableBurnableERC20 tokenCurrency =
        BaseControlledMintableBurnableERC20(params.syntheticToken);
      require(
        keccak256(abi.encodePacked(tokenCurrency.name())) ==
          keccak256(abi.encodePacked(params.syntheticName)),
        'Wrong synthetic token name'
      );
      require(
        keccak256(abi.encodePacked(tokenCurrency.symbol())) ==
          keccak256(abi.encodePacked(params.syntheticSymbol)),
        'Wrong synthetic token symbol'
      );
      pool = new SynthereumLiquidityPool(_convertParams(params, tokenCurrency));
    }
    emit CreatedPool(address(pool), params.version, msg.sender);
    return pool;
  }

  // Converts createPool params to constructor params.
  function _convertParams(
    Params memory params,
    BaseControlledMintableBurnableERC20 tokenCurrency
  )
    internal
    view
    returns (SynthereumLiquidityPool.ConstructorParams memory constructorParams)
  {
    require(params.roles.admin != address(0), 'Admin cannot be 0x00');
    constructorParams.finder = synthereumFinder;
    constructorParams.version = params.version;
    constructorParams.collateralToken = params.collateralToken;
    constructorParams.syntheticToken = IMintableBurnableERC20(
      address(tokenCurrency)
    );
    constructorParams.roles = params.roles;
    constructorParams.overCollateralization = params.overCollateralization;
    constructorParams.feeData = params.feeData;
    constructorParams.priceIdentifier = params.priceIdentifier;
    constructorParams.collateralRequirement = params.collateralRequirement;
    constructorParams.liquidationReward = params.liquidationReward;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {IERC20} from '../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableERC20
} from '../../tokens/interfaces/IMintableBurnableERC20.sol';
import {ISynthereumLiquidityPool} from './interfaces/ILiquidityPool.sol';
import {
  ISynthereumLiquidityPoolStorage
} from './interfaces/ILiquidityPoolStorage.sol';
import {
  ISynthereumLiquidityPoolGeneral
} from './interfaces/ILiquidityPoolGeneral.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {
  FixedPoint
} from '../../../@uma/core/contracts/common/implementation/FixedPoint.sol';
import {SynthereumLiquidityPoolLib} from './LiquidityPoolLib.sol';
import {
  ReentrancyGuard
} from '../../../@openzeppelin/contracts/security/ReentrancyGuard.sol';
import {ERC2771Context} from '../../common/ERC2771Context.sol';
import {
  AccessControlEnumerable,
  Context
} from '../../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 * @title Token Issuer Contract
 * @notice Collects collateral and issues synthetic assets
 */
contract SynthereumLiquidityPool is
  ISynthereumLiquidityPoolStorage,
  ISynthereumLiquidityPool,
  AccessControlEnumerable,
  ERC2771Context,
  ReentrancyGuard
{
  using SynthereumLiquidityPoolLib for Storage;
  using SynthereumLiquidityPoolLib for Liquidation;

  struct ConstructorParams {
    // Synthereum finder
    ISynthereumFinder finder;
    // Synthereum pool version
    uint8 version;
    // ERC20 collateral token
    IStandardERC20 collateralToken;
    // ERC20 synthetic token
    IMintableBurnableERC20 syntheticToken;
    // The addresses of admin, maintainer, liquidity provider
    Roles roles;
    // Overcollateralization percentage
    uint256 overCollateralization;
    // The feeData structure
    FeeData feeData;
    // Identifier of price to be used in the price feed
    bytes32 priceIdentifier;
    // Percentage of overcollateralization to which a liquidation can triggered
    uint256 collateralRequirement;
    // Percentage of reward for correct liquidation by a liquidator
    uint256 liquidationReward;
  }

  //----------------------------------------
  // Constants
  //----------------------------------------

  string public constant override typology = 'POOL';

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  bytes32 public constant LIQUIDITY_PROVIDER_ROLE =
    keccak256('Liquidity Provider');

  //----------------------------------------
  // Storage
  //----------------------------------------

  Storage private poolStorage;

  LPPosition private lpPosition;

  Liquidation private liquidationData;

  FeeStatus private feeStatus;

  Shutdown private emergencyShutdownData;

  //----------------------------------------
  // Events
  //----------------------------------------

  event Mint(
    address indexed account,
    uint256 collateralSent,
    uint256 numTokensReceived,
    uint256 feePaid,
    address recipient
  );

  event Redeem(
    address indexed account,
    uint256 numTokensSent,
    uint256 collateralReceived,
    uint256 feePaid,
    address recipient
  );

  event Exchange(
    address indexed account,
    address indexed destPool,
    uint256 numTokensSent,
    uint256 destNumTokensReceived,
    uint256 feePaid,
    address recipient
  );

  event WithdrawLiquidity(
    address indexed lp,
    uint256 liquidityWithdrawn,
    uint256 remainingLiquidity
  );

  event IncreaseCollateral(
    address indexed lp,
    uint256 collateralAdded,
    uint256 newTotalCollateral
  );

  event DecreaseCollateral(
    address indexed lp,
    uint256 collateralRemoved,
    uint256 newTotalCollateral
  );

  event ClaimFee(
    address indexed claimer,
    uint256 feeAmount,
    uint256 totalRemainingFees
  );

  event Liquidate(
    address indexed liquidator,
    uint256 tokensLiquidated,
    uint256 price,
    uint256 collateralExpected,
    uint256 collateralReceived,
    uint256 rewardReceived
  );

  event EmergencyShutdown(
    uint256 timestamp,
    uint256 price,
    uint256 finalCollateral
  );

  event Settle(
    address indexed account,
    uint256 numTokensSettled,
    uint256 collateralExpected,
    uint256 collateralSettled
  );

  event SetFeePercentage(uint256 feePercentage);

  event SetFeeRecipients(address[] feeRecipients, uint32[] feeProportions);

  event SetOverCollateralization(uint256 overCollateralization);

  event SetLiquidationReward(uint256 liquidationReward);

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, _msgSender()),
      'Sender must be the maintainer'
    );
    _;
  }

  modifier onlyLiquidityProvider() {
    require(
      hasRole(LIQUIDITY_PROVIDER_ROLE, _msgSender()),
      'Sender must be the liquidity provider'
    );
    _;
  }

  modifier notEmergencyShutdown() {
    require(emergencyShutdownData.timestamp == 0, 'Pool emergency shutdown');
    _;
  }

  modifier isEmergencyShutdown() {
    require(
      emergencyShutdownData.timestamp != 0,
      'Pool not emergency shutdown'
    );
    _;
  }

  //----------------------------------------
  // Constructor
  //----------------------------------------

  /**
   * @notice Constructor of liquidity pool

   */
  constructor(ConstructorParams memory params) nonReentrant {
    poolStorage.initialize(
      liquidationData,
      params.finder,
      params.version,
      params.collateralToken,
      params.syntheticToken,
      FixedPoint.Unsigned(params.overCollateralization),
      params.priceIdentifier,
      FixedPoint.Unsigned(params.collateralRequirement),
      FixedPoint.Unsigned(params.liquidationReward)
    );
    poolStorage.setFeePercentage(params.feeData.feePercentage);
    poolStorage.setFeeRecipients(
      params.feeData.feeRecipients,
      params.feeData.feeProportions
    );
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(LIQUIDITY_PROVIDER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, params.roles.admin);
    _setupRole(MAINTAINER_ROLE, params.roles.maintainer);
    _setupRole(LIQUIDITY_PROVIDER_ROLE, params.roles.liquidityProvider);
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  /**
   * @notice Mint synthetic tokens using fixed amount of collateral
   * @notice This calculate the price using on chain price feed
   * @notice User must approve collateral transfer for the mint request to succeed
   * @param mintParams Input parameters for minting (see MintParams struct)
   * @return syntheticTokensMinted Amount of synthetic tokens minted by a user
   * @return feePaid Amount of collateral paid by the user as fee
   */
  function mint(MintParams calldata mintParams)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 syntheticTokensMinted, uint256 feePaid)
  {
    (syntheticTokensMinted, feePaid) = poolStorage.mint(
      lpPosition,
      feeStatus,
      mintParams,
      _msgSender()
    );
  }

  /**
   * @notice Redeem amount of collateral using fixed number of synthetic token
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param redeemParams Input parameters for redeeming (see RedeemParams struct)
   * @return collateralRedeemed Amount of collateral redeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function redeem(RedeemParams calldata redeemParams)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 collateralRedeemed, uint256 feePaid)
  {
    (collateralRedeemed, feePaid) = poolStorage.redeem(
      lpPosition,
      feeStatus,
      redeemParams,
      _msgSender()
    );
  }

  /**
   * @notice Exchange a fixed amount of synthetic token of this pool, with an amount of synthetic tokens of an another pool
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param exchangeParams Input parameters for exchanging (see ExchangeParams struct)
   * @return destNumTokensMinted Amount of collateral redeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function exchange(ExchangeParams calldata exchangeParams)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 destNumTokensMinted, uint256 feePaid)
  {
    (destNumTokensMinted, feePaid) = poolStorage.exchange(
      lpPosition,
      feeStatus,
      exchangeParams,
      _msgSender()
    );
  }

  /**
   * @notice Called by a source Pool's `exchange` function to mint destination tokens
   * @notice This functon can be called only by a pool registered in the PoolRegister contract
   * @param collateralAmount The amount of collateral to use from the source Pool
   * @param numTokens The number of new tokens to mint
   * @param recipient Recipient to which send synthetic token minted
   */
  function exchangeMint(
    uint256 collateralAmount,
    uint256 numTokens,
    address recipient
  ) external override notEmergencyShutdown nonReentrant {
    poolStorage.exchangeMint(
      lpPosition,
      feeStatus,
      FixedPoint.Unsigned(collateralAmount),
      FixedPoint.Unsigned(numTokens),
      recipient
    );
  }

  /**
   * @notice Withdraw unused deposited collateral by the LP
   * @notice Only a sender with LP role can call this function
   * @param collateralAmount Collateral to be withdrawn
   * @return remainingLiquidity Remaining unused collateral in the pool
   */
  function withdrawLiquidity(uint256 collateralAmount)
    external
    override
    onlyLiquidityProvider
    notEmergencyShutdown
    nonReentrant
    returns (uint256 remainingLiquidity)
  {
    remainingLiquidity = poolStorage.withdrawLiquidity(
      lpPosition,
      feeStatus,
      FixedPoint.Unsigned(collateralAmount),
      _msgSender()
    );
  }

  /**
   * @notice Increase collaterallization of Lp position
   * @notice Only a sender with LP role can call this function
   * @param collateralToTransfer Collateral to be transferred before increase collateral in the position
   * @param collateralToIncrease Collateral to be added to the position
   * @return newTotalCollateral New total collateral amount
   */
  function increaseCollateral(
    uint256 collateralToTransfer,
    uint256 collateralToIncrease
  )
    external
    override
    onlyLiquidityProvider
    nonReentrant
    returns (uint256 newTotalCollateral)
  {
    newTotalCollateral = poolStorage.increaseCollateral(
      lpPosition,
      feeStatus,
      FixedPoint.Unsigned(collateralToTransfer),
      FixedPoint.Unsigned(collateralToIncrease),
      _msgSender()
    );
  }

  /**
   * @notice Decrease collaterallization of Lp position
   * @notice Check that final poosition is not undercollateralized
   * @notice Only a sender with LP role can call this function
   * @param collateralToDecrease Collateral to decreased from the position
   * @param collateralToWithdraw Collateral to be transferred to the LP
   * @return newTotalCollateral New total collateral amount
   */
  function decreaseCollateral(
    uint256 collateralToDecrease,
    uint256 collateralToWithdraw
  )
    external
    override
    onlyLiquidityProvider
    notEmergencyShutdown
    nonReentrant
    returns (uint256 newTotalCollateral)
  {
    newTotalCollateral = poolStorage.decreaseCollateral(
      lpPosition,
      liquidationData,
      feeStatus,
      FixedPoint.Unsigned(collateralToDecrease),
      FixedPoint.Unsigned(collateralToWithdraw),
      _msgSender()
    );
  }

  /**
   * @notice Withdraw fees gained by the sender
   * @return feeClaimed Amount of fee claimed
   */
  function claimFee()
    external
    override
    nonReentrant
    returns (uint256 feeClaimed)
  {
    feeClaimed = poolStorage.claimFee(feeStatus, _msgSender());
  }

  /**
   * @notice Liquidate Lp position for an amount of synthetic tokens undercollateralized
   * @notice Revert if position is not undercollateralized
   * @param numSynthTokens Number of synthetic tokens that user wants to liquidate
   * @return synthTokensLiquidated Amount of synthetic tokens liquidated
   * @return collateralReceived Amount of received collateral equal to the value of tokens liquidated
   * @return rewardAmount Amount of received collateral as reward for the liquidation
   */
  function liquidate(uint256 numSynthTokens)
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (
      uint256 synthTokensLiquidated,
      uint256 collateralReceived,
      uint256 rewardAmount
    )
  {
    (synthTokensLiquidated, collateralReceived, rewardAmount) = poolStorage
      .liquidate(
      lpPosition,
      liquidationData,
      feeStatus,
      FixedPoint.Unsigned(numSynthTokens),
      _msgSender()
    );
  }

  /**
   * @notice Shutdown the pool in case of emergency
   * @notice Only Synthereum manager contract can call this function
   * @return timestamp Timestamp of emergency shutdown transaction
   * @return price Price of the pair at the moment of shutdown execution
   */
  function emergencyShutdown()
    external
    override
    notEmergencyShutdown
    nonReentrant
    returns (uint256 timestamp, uint256 price)
  {
    (timestamp, price) = poolStorage.emergencyShutdown(
      lpPosition,
      feeStatus,
      emergencyShutdownData
    );
  }

  /**
   * @notice Redeem tokens after emergency shutdown
   * @return synthTokensSettled Amount of synthetic tokens liquidated
   * @return collateralSettled Amount of collateral withdrawn after emergency shutdown
   */
  function settleEmergencyShutdown()
    external
    override
    isEmergencyShutdown
    nonReentrant
    returns (uint256 synthTokensSettled, uint256 collateralSettled)
  {
    address msgSender = _msgSender();
    bool isLiquidityProvider = hasRole(LIQUIDITY_PROVIDER_ROLE, msgSender);
    (synthTokensSettled, collateralSettled) = poolStorage
      .settleEmergencyShutdown(
      lpPosition,
      feeStatus,
      emergencyShutdownData,
      isLiquidityProvider,
      msgSender
    );
  }

  /**
   * @notice Update the fee percentage, recipients and recipient proportions
   * @notice Only the maintainer can call this function
   * @param _feeData Fee info (percentage + recipients + weigths)
   */
  function setFee(ISynthereumLiquidityPoolStorage.FeeData calldata _feeData)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.setFeePercentage(_feeData.feePercentage);
    poolStorage.setFeeRecipients(
      _feeData.feeRecipients,
      _feeData.feeProportions
    );
  }

  /**
   * @notice Update the fee percentage
   * @notice Only the maintainer can call this function
   * @param _feePercentage The new fee percentage
   */
  function setFeePercentage(uint256 _feePercentage)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.setFeePercentage(FixedPoint.Unsigned(_feePercentage));
  }

  /**
   * @notice Update the addresses of recipients for generated fees and proportions of fees each address will receive
   * @notice Only the maintainer can call this function
   * @param feeRecipients An array of the addresses of recipients that will receive generated fees
   * @param feeProportions An array of the proportions of fees generated each recipient will receive
   */
  function setFeeRecipients(
    address[] calldata feeRecipients,
    uint32[] calldata feeProportions
  ) external override onlyMaintainer nonReentrant {
    poolStorage.setFeeRecipients(feeRecipients, feeProportions);
  }

  /**
   * @notice Update the overcollateralization percentage
   * @notice Only the maintainer can call this function
   * @param _overCollateralization Overcollateralization percentage
   */
  function setOverCollateralization(uint256 _overCollateralization)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    poolStorage.setOverCollateralization(
      liquidationData,
      FixedPoint.Unsigned(_overCollateralization)
    );
  }

  /**
   * @notice Update the liquidation reward percentage
   * @notice Only the maintainer can call this function
   * @param _liquidationReward Percentage of reward for correct liquidation by a liquidator
   */
  function setLiquidationReward(uint256 _liquidationReward)
    external
    override
    onlyMaintainer
    nonReentrant
  {
    liquidationData.setLiquidationReward(
      FixedPoint.Unsigned(_liquidationReward)
    );
  }

  //----------------------------------------
  // External view functions
  //----------------------------------------

  /**
   * @notice Get Synthereum finder of the pool
   * @return finder Returns finder contract
   */
  function synthereumFinder()
    external
    view
    override
    returns (ISynthereumFinder finder)
  {
    finder = poolStorage.finder;
  }

  /**
   * @notice Get Synthereum version
   * @return poolVersion Returns the version of the Synthereum pool
   */
  function version() external view override returns (uint8 poolVersion) {
    poolVersion = poolStorage.version;
  }

  /**
   * @notice Get the collateral token
   * @return collateralCurrency The ERC20 collateral token
   */
  function collateralToken()
    external
    view
    override
    returns (IERC20 collateralCurrency)
  {
    collateralCurrency = poolStorage.collateralToken;
  }

  /**
   * @notice Get the synthetic token associated to this pool
   * @return syntheticCurrency The ERC20 synthetic token
   */
  function syntheticToken()
    external
    view
    override
    returns (IERC20 syntheticCurrency)
  {
    syntheticCurrency = poolStorage.syntheticToken;
  }

  /**
   * @notice Get the synthetic token symbol associated to this pool
   * @return symbol The ERC20 synthetic token symbol
   */
  function syntheticTokenSymbol()
    external
    view
    override
    returns (string memory symbol)
  {
    symbol = IStandardERC20(address(poolStorage.syntheticToken)).symbol();
  }

  /**
   * @notice Returns price identifier of the pool
   * @return identifier Price identifier
   */
  function getPriceFeedIdentifier()
    external
    view
    override
    returns (bytes32 identifier)
  {
    identifier = poolStorage.priceIdentifier;
  }

  /**
   * @notice Return overcollateralization percentage from the storage
   * @return Overcollateralization percentage
   */
  function overCollateralization() external view override returns (uint256) {
    return poolStorage.overCollateralization.rawValue;
  }

  /**
   * @notice Returns fee percentage set by the maintainer
   * @return Fee percentage
   */
  function feePercentage() external view override returns (uint256) {
    return poolStorage.fee.feeData.feePercentage.rawValue;
  }

  /**
   * @notice Returns fee recipients info
   * @return Addresses, weigths and total of weigths
   */
  function feeRecipientsInfo()
    external
    view
    override
    returns (
      address[] memory,
      uint32[] memory,
      uint256
    )
  {
    FeeData storage _feeData = poolStorage.fee.feeData;
    return (
      _feeData.feeRecipients,
      _feeData.feeProportions,
      poolStorage.fee.totalFeeProportions
    );
  }

  /**
   * @notice Returns total number of synthetic tokens generated by this pool
   * @return Number of synthetic tokens
   */
  function totalSyntheticTokens() external view override returns (uint256) {
    return lpPosition.tokensCollateralized.rawValue;
  }

  /**
   * @notice Returns the total amount of collateral used for collateralizing tokens (users + LP)
   * @return Total collateral amount
   */
  function totalCollateralAmount() external view override returns (uint256) {
    return lpPosition.totalCollateralAmount.rawValue;
  }

  /**
   * @notice Returns the total amount of liquidity deposited in the pool, but nut used as collateral
   * @return Total available liquidity
   */
  function totalAvailableLiquidity() external view override returns (uint256) {
    return poolStorage.totalAvailableLiquidity(lpPosition, feeStatus);
  }

  /**
   * @notice Returns the total amount of fees to be withdrawn
   * @return Total fee amount
   */
  function totalFeeAmount() external view override returns (uint256) {
    return feeStatus.totalFeeAmount.rawValue;
  }

  /**
   * @notice Returns the user's fee to be withdrawn
   * @param user User's address
   * @return User's fee
   */
  function userFee(address user) external view override returns (uint256) {
    return feeStatus.feeGained[user].rawValue;
  }

  /**
   * @notice Returns the percentage of overcollateralization to which a liquidation can triggered
   * @return Percentage of overcollateralization
   */
  function collateralRequirement() external view override returns (uint256) {
    return liquidationData.collateralRequirement.rawValue;
  }

  /**
   * @notice Returns the percentage of reward for correct liquidation by a liquidator
   * @return Percentage of reward
   */
  function liquidationReward() external view override returns (uint256) {
    return liquidationData.liquidationReward.rawValue;
  }

  /**
   * @notice Returns the price of the pair at the moment of the shutdown
   * @return Price of the pair
   */
  function emergencyShutdownPrice() external view override returns (uint256) {
    return emergencyShutdownData.price.rawValue;
  }

  /**
   * @notice Returns the timestamp (unix time) at the moment of the shutdown
   * @return Timestamp
   */
  function emergencyShutdownTimestamp()
    external
    view
    override
    returns (uint256)
  {
    return emergencyShutdownData.timestamp;
  }

  /**
   * @notice Returns if position is overcollateralized and thepercentage of coverage of the collateral according to the last price
   * @return True if position is overcollaterlized, otherwise false + percentage of coverage (totalCollateralAmount / (price * tokensCollateralized))
   */
  function collateralCoverage() external view override returns (bool, uint256) {
    return poolStorage.collateralCoverage(lpPosition, liquidationData);
  }

  /**
   * @notice Returns the synthetic tokens will be received and fees will be paid in exchange for an input collateral amount
   * @notice This function is only trading-informative, it doesn't check liquidity and collateralization conditions
   * @param inputCollateral Input collateral amount to be exchanged
   * @return synthTokensReceived Synthetic tokens will be minted
   * @return feePaid Collateral fee will be paid
   */
  function getMintTradeInfo(uint256 inputCollateral)
    external
    view
    override
    returns (uint256 synthTokensReceived, uint256 feePaid)
  {
    (synthTokensReceived, feePaid) = poolStorage.getMintTradeInfo(
      lpPosition,
      feeStatus,
      FixedPoint.Unsigned(inputCollateral)
    );
  }

  /**
   * @notice Returns the collateral amount will be received and fees will be paid in exchange for an input amount of synthetic tokens
   * @notice This function is only trading-informative, it doesn't check liquidity and collateralization conditions
   * @param  syntheticTokens Amount of synthetic tokens to be exchanged
   * @return collateralAmountReceived Collateral amount will be received by the user
   * @return feePaid Collateral fee will be paid
   */
  function getRedeemTradeInfo(uint256 syntheticTokens)
    external
    view
    override
    returns (uint256 collateralAmountReceived, uint256 feePaid)
  {
    (collateralAmountReceived, feePaid) = poolStorage.getRedeemTradeInfo(
      lpPosition,
      FixedPoint.Unsigned(syntheticTokens)
    );
  }

  /**
   * @notice Returns the destination synthetic tokens amount will be received and fees will be paid in exchange for an input amount of synthetic tokens
   * @notice This function is only trading-informative, it doesn't check liquidity and collateralization conditions
   * @param  syntheticTokens Amount of synthetic tokens to be exchanged
   * @param  destinationPool Pool in which mint the destination synthetic token
   * @return destSyntheticTokensReceived Synthetic tokens will be received from destination pool
   * @return feePaid Collateral fee will be paid
   */
  function getExchangeTradeInfo(
    uint256 syntheticTokens,
    ISynthereumLiquidityPoolGeneral destinationPool
  )
    external
    view
    override
    returns (uint256 destSyntheticTokensReceived, uint256 feePaid)
  {
    (destSyntheticTokensReceived, feePaid) = poolStorage.getExchangeTradeInfo(
      lpPosition,
      FixedPoint.Unsigned(syntheticTokens),
      destinationPool
    );
  }

  /**
   * @notice Check if an address is the trusted forwarder
   * @param  forwarder Address to check
   * @return True is the input address is the trusted forwarder, otherwise false
   */
  function isTrustedForwarder(address forwarder)
    public
    view
    override
    returns (bool)
  {
    try
      poolStorage.finder.getImplementationAddress(
        SynthereumInterfaces.TrustedForwarder
      )
    returns (address trustedForwarder) {
      if (forwarder == trustedForwarder) {
        return true;
      } else {
        return false;
      }
    } catch {
      return false;
    }
  }

  function _msgSender()
    internal
    view
    override(ERC2771Context, Context)
    returns (address sender)
  {
    return ERC2771Context._msgSender();
  }

  function _msgData()
    internal
    view
    override(ERC2771Context, Context)
    returns (bytes calldata)
  {
    return ERC2771Context._msgData();
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IStandardERC20} from '../../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableERC20
} from '../../../tokens/interfaces/IMintableBurnableERC20.sol';
import {ISynthereumFinder} from '../../../core/interfaces/IFinder.sol';
import {
  FixedPoint
} from '../../../../@uma/core/contracts/common/implementation/FixedPoint.sol';

interface ISynthereumLiquidityPoolStorage {
  // Describe role structure
  struct Roles {
    address admin;
    address maintainer;
    address liquidityProvider;
  }

  // Describe fee data structure
  struct FeeData {
    // Fees charged when a user mints, redeem and exchanges tokens
    FixedPoint.Unsigned feePercentage;
    // Recipient receiving fees
    address[] feeRecipients;
    // Proportion for each recipient
    uint32[] feeProportions;
  }

  // Describe fee structure
  struct Fee {
    // Fee data structure
    FeeData feeData;
    // Used with individual proportions to scale values
    uint256 totalFeeProportions;
  }

  struct Storage {
    // Synthereum finder
    ISynthereumFinder finder;
    // Synthereum version
    uint8 version;
    // Collateral token
    IStandardERC20 collateralToken;
    // Synthetic token
    IMintableBurnableERC20 syntheticToken;
    // Overcollateralization percentage
    FixedPoint.Unsigned overCollateralization;
    // Fees
    Fee fee;
    // Price identifier
    bytes32 priceIdentifier;
  }

  struct LPPosition {
    // Collateral used for collateralize tokens
    FixedPoint.Unsigned totalCollateralAmount;
    // Number of tokens collateralized
    FixedPoint.Unsigned tokensCollateralized;
  }

  struct Liquidation {
    // Percentage of overcollateralization to which a liquidation can triggered
    FixedPoint.Unsigned collateralRequirement;
    // Percentage of reward for correct liquidation by a liquidator
    FixedPoint.Unsigned liquidationReward;
  }

  struct FeeStatus {
    // Track the fee gained to be withdrawn by an address
    mapping(address => FixedPoint.Unsigned) feeGained;
    // Total amount of fees to be withdrawn
    FixedPoint.Unsigned totalFeeAmount;
  }

  struct Shutdown {
    // Timestamp of execution of shutdown
    uint256 timestamp;
    // Price of the pair at the moment of the shutdown
    FixedPoint.Unsigned price;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {
  IEmergencyShutdown
} from '../../../common/interfaces/IEmergencyShutdown.sol';
import {ISynthereumLiquidityPoolGeneral} from './ILiquidityPoolGeneral.sol';
import {ISynthereumLiquidityPoolStorage} from './ILiquidityPoolStorage.sol';
import {ITypology} from '../../../common/interfaces/ITypology.sol';

/**
 * @title Token Issuer Contract Interface
 */
interface ISynthereumLiquidityPool is
  ITypology,
  IEmergencyShutdown,
  ISynthereumLiquidityPoolGeneral
{
  struct MintParams {
    // Minimum amount of synthetic tokens that a user wants to mint using collateral (anti-slippage)
    uint256 minNumTokens;
    // Amount of collateral that a user wants to spend for minting
    uint256 collateralAmount;
    // Expiration time of the transaction
    uint256 expiration;
    // Address to which send synthetic tokens minted
    address recipient;
  }

  struct RedeemParams {
    // Amount of synthetic tokens that user wants to use for redeeming
    uint256 numTokens;
    // Minimium amount of collateral that user wants to redeem (anti-slippage)
    uint256 minCollateral;
    // Expiration time of the transaction
    uint256 expiration;
    // Address to which send collateral tokens redeemed
    address recipient;
  }

  struct ExchangeParams {
    // Destination pool
    ISynthereumLiquidityPoolGeneral destPool;
    // Amount of source synthetic tokens that user wants to use for exchanging
    uint256 numTokens;
    // Minimum Amount of destination synthetic tokens that user wants to receive (anti-slippage)
    uint256 minDestNumTokens;
    // Expiration time of the transaction
    uint256 expiration;
    // Address to which send synthetic tokens exchanged
    address recipient;
  }

  /**
   * @notice Mint synthetic tokens using fixed amount of collateral
   * @notice This calculate the price using on chain price feed
   * @notice User must approve collateral transfer for the mint request to succeed
   * @param mintParams Input parameters for minting (see MintParams struct)
   * @return syntheticTokensMinted Amount of synthetic tokens minted by a user
   * @return feePaid Amount of collateral paid by the user as fee
   */
  function mint(MintParams calldata mintParams)
    external
    returns (uint256 syntheticTokensMinted, uint256 feePaid);

  /**
   * @notice Redeem amount of collateral using fixed number of synthetic token
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param redeemParams Input parameters for redeeming (see RedeemParams struct)
   * @return collateralRedeemed Amount of collateral redeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function redeem(RedeemParams calldata redeemParams)
    external
    returns (uint256 collateralRedeemed, uint256 feePaid);

  /**
   * @notice Exchange a fixed amount of synthetic token of this pool, with an amount of synthetic tokens of an another pool
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param exchangeParams Input parameters for exchanging (see ExchangeParams struct)
   * @return destNumTokensMinted Amount of collateral redeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function exchange(ExchangeParams calldata exchangeParams)
    external
    returns (uint256 destNumTokensMinted, uint256 feePaid);

  /**
   * @notice Withdraw unused deposited collateral by the LP
   * @notice Only a sender with LP role can call this function
   * @param collateralAmount Collateral to be withdrawn
   * @return remainingLiquidity Remaining unused collateral in the pool
   */
  function withdrawLiquidity(uint256 collateralAmount)
    external
    returns (uint256 remainingLiquidity);

  /**
   * @notice Increase collaterallization of Lp position
   * @notice Only a sender with LP role can call this function
   * @param collateralToTransfer Collateral to be transferred before increase collateral in the position
   * @param collateralToIncrease Collateral to be added to the position
   * @return newTotalCollateral New total collateral amount
   */
  function increaseCollateral(
    uint256 collateralToTransfer,
    uint256 collateralToIncrease
  ) external returns (uint256 newTotalCollateral);

  /**
   * @notice Decrease collaterallization of Lp position
   * @notice Check that final poosition is not undercollateralized
   * @notice Only a sender with LP role can call this function
   * @param collateralToDecrease Collateral to decreased from the position
   * @param collateralToWithdraw Collateral to be transferred to the LP
   * @return newTotalCollateral New total collateral amount
   */
  function decreaseCollateral(
    uint256 collateralToDecrease,
    uint256 collateralToWithdraw
  ) external returns (uint256 newTotalCollateral);

  /**
   * @notice Withdraw fees gained by the sender
   * @return feeClaimed Amount of fee claimed
   */
  function claimFee() external returns (uint256 feeClaimed);

  /**
   * @notice Liquidate Lp position for an amount of synthetic tokens undercollateralized
   * @notice Revert if position is not undercollateralized
   * @param numSynthTokens Number of synthetic tokens that user wants to liquidate
   * @return synthTokensLiquidated Amount of synthetic tokens liquidated
   * @return collateralReceived Amount of received collateral equal to the value of tokens liquidated
   * @return rewardAmount Amount of received collateral as reward for the liquidation
   */
  function liquidate(uint256 numSynthTokens)
    external
    returns (
      uint256 synthTokensLiquidated,
      uint256 collateralReceived,
      uint256 rewardAmount
    );

  /**
   * @notice Redeem tokens after emergency shutdown
   * @return synthTokensSettled Amount of synthetic tokens liquidated
   * @return collateralSettled Amount of collateral withdrawn after emergency shutdown
   */
  function settleEmergencyShutdown()
    external
    returns (uint256 synthTokensSettled, uint256 collateralSettled);

  /**
   * @notice Update the fee percentage, recipients and recipient proportions
   * @notice Only the maintainer can call this function
   * @param _feeData Fee info (percentage + recipients + weigths)
   */
  function setFee(ISynthereumLiquidityPoolStorage.FeeData calldata _feeData)
    external;

  /**
   * @notice Update the fee percentage
   * @notice Only the maintainer can call this function
   * @param _feePercentage The new fee percentage
   */
  function setFeePercentage(uint256 _feePercentage) external;

  /**
   * @notice Update the addresses of recipients for generated fees and proportions of fees each address will receive
   * @notice Only the maintainer can call this function
   * @param feeRecipients An array of the addresses of recipients that will receive generated fees
   * @param feeProportions An array of the proportions of fees generated each recipient will receive
   */
  function setFeeRecipients(
    address[] calldata feeRecipients,
    uint32[] calldata feeProportions
  ) external;

  /**
   * @notice Update the overcollateralization percentage
   * @notice Only the maintainer can call this function
   * @param _overCollateralization Overcollateralization percentage
   */
  function setOverCollateralization(uint256 _overCollateralization) external;

  /**
   * @notice Update the liquidation reward percentage
   * @notice Only the maintainer can call this function
   * @param _liquidationReward Percentage of reward for correct liquidation by a liquidator
   */
  function setLiquidationReward(uint256 _liquidationReward) external;

  /**
   * @notice Returns fee percentage set by the maintainer
   * @return Fee percentage
   */
  function feePercentage() external view returns (uint256);

  /**
   * @notice Returns fee recipients info
   * @return Addresses, weigths and total of weigths
   */
  function feeRecipientsInfo()
    external
    view
    returns (
      address[] memory,
      uint32[] memory,
      uint256
    );

  /**
   * @notice Returns total number of synthetic tokens generated by this pool
   * @return Number of synthetic tokens
   */
  function totalSyntheticTokens() external view returns (uint256);

  /**
   * @notice Returns the total amount of collateral used for collateralizing tokens (users + LP)
   * @return Total collateral amount
   */
  function totalCollateralAmount() external view returns (uint256);

  /**
   * @notice Returns the total amount of fees to be withdrawn
   * @return Total fee amount
   */
  function totalFeeAmount() external view returns (uint256);

  /**
   * @notice Returns the user's fee to be withdrawn
   * @param user User's address
   * @return User's fee
   */
  function userFee(address user) external view returns (uint256);

  /**
   * @notice Returns the percentage of overcollateralization to which a liquidation can triggered
   * @return Percentage of overcollateralization
   */
  function collateralRequirement() external view returns (uint256);

  /**
   * @notice Returns the percentage of reward for correct liquidation by a liquidator
   * @return Percentage of reward
   */
  function liquidationReward() external view returns (uint256);

  /**
   * @notice Returns the price of the pair at the moment of the shutdown
   * @return Price of the pair
   */
  function emergencyShutdownPrice() external view returns (uint256);

  /**
   * @notice Returns the timestamp (unix time) at the moment of the shutdown
   * @return Timestamp
   */
  function emergencyShutdownTimestamp() external view returns (uint256);

  /**
   * @notice Returns if position is overcollateralized and thepercentage of coverage of the collateral according to the last price
   * @return True if position is overcollaterlized, otherwise false + percentage of coverage (totalCollateralAmount / (price * tokensCollateralized))
   */
  function collateralCoverage() external returns (bool, uint256);

  /**
   * @notice Returns the synthetic tokens will be received and fees will be paid in exchange for an input collateral amount
   * @notice This function is only trading-informative, it doesn't check liquidity and collateralization conditions
   * @param inputCollateral Input collateral amount to be exchanged
   * @return synthTokensReceived Synthetic tokens will be minted
   * @return feePaid Collateral fee will be paid
   */
  function getMintTradeInfo(uint256 inputCollateral)
    external
    view
    returns (uint256 synthTokensReceived, uint256 feePaid);

  /**
   * @notice Returns the collateral amount will be received and fees will be paid in exchange for an input amount of synthetic tokens
   * @notice This function is only trading-informative, it doesn't check liquidity and collateralization conditions
   * @param  syntheticTokens Amount of synthetic tokens to be exchanged
   * @return collateralAmountReceived Collateral amount will be received by the user
   * @return feePaid Collateral fee will be paid
   */
  function getRedeemTradeInfo(uint256 syntheticTokens)
    external
    view
    returns (uint256 collateralAmountReceived, uint256 feePaid);

  /**
   * @notice Returns the destination synthetic tokens amount will be received and fees will be paid in exchange for an input amount of synthetic tokens
   * @notice This function is only trading-informative, it doesn't check liquidity and collateralization conditions
   * @param  syntheticTokens Amount of synthetic tokens to be exchanged
   * @param  destinationPool Pool in which mint the destination synthetic token
   * @return destSyntheticTokensReceived Synthetic tokens will be received from destination pool
   * @return feePaid Collateral fee will be paid
   */
  function getExchangeTradeInfo(
    uint256 syntheticTokens,
    ISynthereumLiquidityPoolGeneral destinationPool
  )
    external
    view
    returns (uint256 destSyntheticTokensReceived, uint256 feePaid);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {
  ISynthereumLiquidityPoolInteraction
} from './ILiquidityPoolInteraction.sol';
import {
  ISynthereumDeployment
} from '../../../common/interfaces/IDeployment.sol';

interface ISynthereumLiquidityPoolGeneral is
  ISynthereumDeployment,
  ISynthereumLiquidityPoolInteraction
{}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {
  ISynthereumLiquidityPoolStorage
} from './interfaces/ILiquidityPoolStorage.sol';
import {ISynthereumLiquidityPool} from './interfaces/ILiquidityPool.sol';
import {
  FixedPoint
} from '../../../@uma/core/contracts/common/implementation/FixedPoint.sol';
import {IStandardERC20} from '../../base/interfaces/IStandardERC20.sol';
import {
  IMintableBurnableERC20
} from '../../tokens/interfaces/IMintableBurnableERC20.sol';
import {ISynthereumFinder} from '../../core/interfaces/IFinder.sol';
import {
  ISynthereumRegistry
} from '../../core/registries/interfaces/IRegistry.sol';
import {
  ISynthereumPriceFeed
} from '../../oracle/common/interfaces/IPriceFeed.sol';
import {
  ISynthereumLiquidityPoolGeneral
} from './interfaces/ILiquidityPoolGeneral.sol';
import {SynthereumInterfaces} from '../../core/Constants.sol';
import {
  SafeERC20
} from '../../../@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

/**
 * @notice Pool implementation is stored here to reduce deployment costs
 */

library SynthereumLiquidityPoolLib {
  using FixedPoint for FixedPoint.Unsigned;
  using FixedPoint for uint256;
  using SafeERC20 for IStandardERC20;
  using SafeERC20 for IMintableBurnableERC20;
  using SynthereumLiquidityPoolLib for ISynthereumLiquidityPoolStorage.Storage;
  using SynthereumLiquidityPoolLib for ISynthereumLiquidityPoolStorage.LPPosition;
  using SynthereumLiquidityPoolLib for ISynthereumLiquidityPoolStorage.FeeStatus;

  struct ExecuteMintParams {
    // Amount of synth tokens to mint
    FixedPoint.Unsigned numTokens;
    // Amount of collateral (excluding fees) needed for mint
    FixedPoint.Unsigned collateralAmount;
    // Amount of fees of collateral user must pay
    FixedPoint.Unsigned feeAmount;
    // Amount of collateral equal to collateral minted + fees
    FixedPoint.Unsigned totCollateralAmount;
    // Recipient address that will receive synthetic tokens
    address recipient;
    // Sender of the mint transaction
    address sender;
  }

  struct ExecuteRedeemParams {
    //Amount of synth tokens needed for redeem
    FixedPoint.Unsigned numTokens;
    // Amount of collateral that user will receive
    FixedPoint.Unsigned collateralAmount;
    // Amount of fees of collateral user must pay
    FixedPoint.Unsigned feeAmount;
    // Amount of collateral equal to collateral redeemed + fees
    FixedPoint.Unsigned totCollateralAmount;
    // Recipient address that will receive synthetic tokens
    address recipient;
    // Sender of the redeem transaction
    address sender;
  }

  struct ExecuteExchangeParams {
    // Destination pool in which mint new tokens
    ISynthereumLiquidityPoolGeneral destPool;
    // Amount of tokens to send
    FixedPoint.Unsigned numTokens;
    // Amount of collateral (excluding fees) equivalent to synthetic token (exluding fees) to send
    FixedPoint.Unsigned collateralAmount;
    // Amount of fees of collateral user must pay
    FixedPoint.Unsigned feeAmount;
    // Amount of collateral equal to collateral redemeed + fees
    FixedPoint.Unsigned totCollateralAmount;
    // Amount of synthetic token to receive
    FixedPoint.Unsigned destNumTokens;
    // Recipient address that will receive synthetic tokens
    address recipient;
    // Sender of the exchange transaction
    address sender;
  }

  struct ExecuteSettlement {
    // Price of emergency shutdown
    FixedPoint.Unsigned emergencyPrice;
    // Amount of synthtic tokens to be liquidated
    FixedPoint.Unsigned userNumTokens;
    // Total amount of collateral (excluding unused and fees) deposited
    FixedPoint.Unsigned totalCollateralAmount;
    // Total amount of synthetic tokens
    FixedPoint.Unsigned tokensCollaterlized;
    // Total actual amount of fees to be withdrawn
    FixedPoint.Unsigned totalFeeAmount;
    // Overcollateral to be withdrawn by Lp (0 if standard user)
    FixedPoint.Unsigned overCollateral;
    // Amount of collateral which value is equal to the synthetic tokens value according to the emergency price
    FixedPoint.Unsigned totalRedeemableCollateral;
    // Exepected amount of collateral
    FixedPoint.Unsigned redeemableCollateral;
    // Collateral deposited but not used to collateralize
    FixedPoint.Unsigned unusedCollateral;
    // Amount of collateral settled to the sender
    FixedPoint.Unsigned transferableCollateral;
  }

  struct ExecuteLiquidation {
    // Total amount of collateral in the Lp position
    FixedPoint.Unsigned totalCollateralAmount;
    // Total number of tokens collateralized in the Lp position
    FixedPoint.Unsigned tokensCollateralized;
    // Total number of tokens in liquidation
    FixedPoint.Unsigned tokensInLiquidation;
    // Amount of collateral used to collateralize user's tokens
    FixedPoint.Unsigned userCollateralization;
    // Available liquidity in the pool
    FixedPoint.Unsigned unusedCollateral;
    // Expected collateral received by the user according to the actual price
    FixedPoint.Unsigned expectedCollateral;
    // Collateral amount receieved by the user
    FixedPoint.Unsigned settledCollateral;
    // Reward amount received by the user
    FixedPoint.Unsigned rewardAmount;
    // Price rate at the moment of the liquidation
    FixedPoint.Unsigned priceRate;
  }

  //----------------------------------------
  // Events
  //----------------------------------------

  event Mint(
    address indexed account,
    uint256 collateralSent,
    uint256 numTokensReceived,
    uint256 feePaid,
    address recipient
  );

  event Redeem(
    address indexed account,
    uint256 numTokensSent,
    uint256 collateralReceived,
    uint256 feePaid,
    address recipient
  );

  event Exchange(
    address indexed account,
    address indexed destPool,
    uint256 numTokensSent,
    uint256 destNumTokensReceived,
    uint256 feePaid,
    address recipient
  );

  event WithdrawLiquidity(
    address indexed lp,
    uint256 liquidityWithdrawn,
    uint256 remainingLiquidity
  );

  event IncreaseCollateral(
    address indexed lp,
    uint256 collateralAdded,
    uint256 newTotalCollateral
  );

  event DecreaseCollateral(
    address indexed lp,
    uint256 collateralRemoved,
    uint256 newTotalCollateral
  );

  event ClaimFee(
    address indexed claimer,
    uint256 feeAmount,
    uint256 totalRemainingFees
  );

  event Liquidate(
    address indexed liquidator,
    uint256 tokensLiquidated,
    uint256 price,
    uint256 collateralExpected,
    uint256 collateralReceived,
    uint256 rewardReceived
  );

  event EmergencyShutdown(
    uint256 timestamp,
    uint256 price,
    uint256 finalCollateral
  );

  event Settle(
    address indexed account,
    uint256 numTokensSettled,
    uint256 collateralExpected,
    uint256 collateralSettled
  );

  event SetFeePercentage(uint256 feePercentage);

  event SetFeeRecipients(address[] feeRecipients, uint32[] feeProportions);

  event SetOverCollateralization(uint256 overCollateralization);

  event SetLiquidationReward(uint256 liquidationReward);

  //----------------------------------------
  // External functions
  //----------------------------------------

  /**
   * @notice Initializes a liquidity pool
   * @param self Data type the library is attached to
   * @param liquidationData Liquidation info (see LiquidationData struct)
   * @param _finder The Synthereum finder
   * @param _version Synthereum version
   * @param _collateralToken ERC20 collateral token
   * @param _syntheticToken ERC20 synthetic token
   * @param _overCollateralization Over-collateralization ratio
   * @param _priceIdentifier Identifier of price to be used in the price feed
   * @param _collateralRequirement Percentage of overcollateralization to which a liquidation can triggered
   * @param _liquidationReward Percentage of reward for correct liquidation by a liquidator
   */
  function initialize(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.Liquidation storage liquidationData,
    ISynthereumFinder _finder,
    uint8 _version,
    IStandardERC20 _collateralToken,
    IMintableBurnableERC20 _syntheticToken,
    FixedPoint.Unsigned calldata _overCollateralization,
    bytes32 _priceIdentifier,
    FixedPoint.Unsigned calldata _collateralRequirement,
    FixedPoint.Unsigned calldata _liquidationReward
  ) external {
    require(
      _collateralRequirement.isGreaterThan(1),
      'Collateral requirement must be bigger than 100%'
    );

    require(
      _overCollateralization.isGreaterThan(_collateralRequirement.sub(1)),
      'Overcollateralization must be bigger than the Lp part of the collateral requirement'
    );

    require(
      _liquidationReward.rawValue > 0 &&
        _liquidationReward.isLessThanOrEqual(1),
      'Liquidation reward must be between 0 and 100%'
    );

    require(
      _collateralToken.decimals() <= 18,
      'Collateral has more than 18 decimals'
    );

    require(
      _syntheticToken.decimals() == 18,
      'Synthetic token has more or less than 18 decimals'
    );

    ISynthereumPriceFeed priceFeed =
      ISynthereumPriceFeed(
        _finder.getImplementationAddress(SynthereumInterfaces.PriceFeed)
      );

    require(
      priceFeed.isPriceSupported(_priceIdentifier),
      'Price identifier not supported'
    );

    self.finder = _finder;
    self.version = _version;
    self.collateralToken = _collateralToken;
    self.syntheticToken = _syntheticToken;
    self.overCollateralization = _overCollateralization;
    self.priceIdentifier = _priceIdentifier;
    liquidationData.collateralRequirement = _collateralRequirement;
    liquidationData.liquidationReward = _liquidationReward;
  }

  /**
   * @notice Mint synthetic tokens using fixed amount of collateral
   * @notice This calculate the price using on chain price feed
   * @notice User must approve collateral transfer for the mint request to succeed
   * @param self Data type the library is attached to
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param feeStatus Actual status of fee gained (see FeeStatus struct)
   * @param mintParams Input parameters for minting (see MintParams struct)
   * @param sender Sender of the mint transaction
   * @return syntheticTokensMinted Amount of synthetic tokens minted by a user
   * @return feePaid Amount of collateral paid by the user as fee
   */
  function mint(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    ISynthereumLiquidityPoolStorage.FeeStatus storage feeStatus,
    ISynthereumLiquidityPool.MintParams calldata mintParams,
    address sender
  ) external returns (uint256 syntheticTokensMinted, uint256 feePaid) {
    FixedPoint.Unsigned memory totCollateralAmount =
      FixedPoint.Unsigned(mintParams.collateralAmount);

    (
      FixedPoint.Unsigned memory collateralAmount,
      FixedPoint.Unsigned memory feeAmount,
      FixedPoint.Unsigned memory numTokens
    ) = self.mintCalculation(totCollateralAmount);

    require(
      numTokens.rawValue >= mintParams.minNumTokens,
      'Number of tokens less than minimum limit'
    );

    checkExpiration(mintParams.expiration);

    self.executeMint(
      lpPosition,
      feeStatus,
      ExecuteMintParams(
        numTokens,
        collateralAmount,
        feeAmount,
        totCollateralAmount,
        mintParams.recipient,
        sender
      )
    );

    syntheticTokensMinted = numTokens.rawValue;
    feePaid = feeAmount.rawValue;
  }

  /**
   * @notice Redeem amount of collateral using fixed number of synthetic token
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param self Data type the library is attached to
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param feeStatus Actual status of fee gained (see FeeStatus struct)
   * @param redeemParams Input parameters for redeeming (see RedeemParams struct)
   * @param sender Sender of the redeem transaction
   * @return collateralRedeemed Amount of collateral redeem by user
   * @return feePaid Amount of collateral paid by user as fee
   */
  function redeem(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    ISynthereumLiquidityPoolStorage.FeeStatus storage feeStatus,
    ISynthereumLiquidityPool.RedeemParams calldata redeemParams,
    address sender
  ) external returns (uint256 collateralRedeemed, uint256 feePaid) {
    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(redeemParams.numTokens);

    (
      FixedPoint.Unsigned memory totCollateralAmount,
      FixedPoint.Unsigned memory feeAmount,
      FixedPoint.Unsigned memory collateralAmount
    ) = self.redeemCalculation(numTokens);

    require(
      collateralAmount.rawValue >= redeemParams.minCollateral,
      'Collateral amount less than minimum limit'
    );

    checkExpiration(redeemParams.expiration);

    self.executeRedeem(
      lpPosition,
      feeStatus,
      ExecuteRedeemParams(
        numTokens,
        collateralAmount,
        feeAmount,
        totCollateralAmount,
        redeemParams.recipient,
        sender
      )
    );

    feePaid = feeAmount.rawValue;
    collateralRedeemed = collateralAmount.rawValue;
  }

  /**
   * @notice Exchange a fixed amount of synthetic token of this pool, with an amount of synthetic tokens of an another pool
   * @notice This calculate the price using on chain price feed
   * @notice User must approve synthetic token transfer for the redeem request to succeed
   * @param self Data type the library is attached to
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param feeStatus Actual status of fee gained (see FeeStatus struct)
   * @param exchangeParams Input parameters for exchanging (see ExchangeParams struct)
   * @param sender Sender of the exchange transaction
   * @return destNumTokensMinted Amount of synthetic token minted in the destination pool
   * @return feePaid Amount of collateral paid by user as fee
   */
  function exchange(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    ISynthereumLiquidityPoolStorage.FeeStatus storage feeStatus,
    ISynthereumLiquidityPool.ExchangeParams calldata exchangeParams,
    address sender
  ) external returns (uint256 destNumTokensMinted, uint256 feePaid) {
    FixedPoint.Unsigned memory numTokens =
      FixedPoint.Unsigned(exchangeParams.numTokens);

    (
      FixedPoint.Unsigned memory totCollateralAmount,
      FixedPoint.Unsigned memory feeAmount,
      FixedPoint.Unsigned memory collateralAmount,
      FixedPoint.Unsigned memory destNumTokens
    ) = self.exchangeCalculation(numTokens, exchangeParams.destPool);

    require(
      destNumTokens.rawValue >= exchangeParams.minDestNumTokens,
      'Number of destination tokens less than minimum limit'
    );

    checkExpiration(exchangeParams.expiration);

    self.executeExchange(
      lpPosition,
      feeStatus,
      ExecuteExchangeParams(
        exchangeParams.destPool,
        numTokens,
        collateralAmount,
        feeAmount,
        totCollateralAmount,
        destNumTokens,
        exchangeParams.recipient,
        sender
      )
    );

    destNumTokensMinted = destNumTokens.rawValue;
    feePaid = feeAmount.rawValue;
  }

  /**
   * @notice Called by a source Pool's `exchange` function to mint destination tokens
   * @notice This functon can be called only by a pool registered in the deployer
   * @param self Data type the library is attached to
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param feeStatus Actual status of fee gained (see FeeStatus struct)
   * @param collateralAmount The amount of collateral to use from the source Pool
   * @param numTokens The number of new tokens to mint
   * @param recipient Recipient to which send synthetic token minted
   */
  function exchangeMint(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    ISynthereumLiquidityPoolStorage.FeeStatus storage feeStatus,
    FixedPoint.Unsigned calldata collateralAmount,
    FixedPoint.Unsigned calldata numTokens,
    address recipient
  ) external {
    self.checkPool(ISynthereumLiquidityPoolGeneral(msg.sender));

    // Sending amount must be different from 0
    require(
      collateralAmount.rawValue > 0,
      'Sending collateral amount is equal to 0'
    );

    // Collateral available
    FixedPoint.Unsigned memory unusedCollateral =
      self.calculateUnusedCollateral(
        lpPosition.totalCollateralAmount,
        feeStatus.totalFeeAmount,
        collateralAmount
      );

    // Update LP's collateralization status
    FixedPoint.Unsigned memory overCollateral =
      lpPosition.updateLpPositionInMint(
        self.overCollateralization,
        collateralAmount,
        numTokens
      );

    //Check there is enough liquidity in the pool for overcollateralization
    require(
      unusedCollateral.isGreaterThanOrEqual(overCollateral),
      'No enough liquidity for cover mint operation'
    );

    // Mint synthetic asset and transfer to the recipient
    self.syntheticToken.mint(recipient, numTokens.rawValue);
  }

  /**
   * @notice Withdraw unused deposited collateral by the LP
   * @param self Data type the library is attached to
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param feeStatus Actual status of fee gained (see FeeStatus struct)
   * @param collateralAmount Collateral to be withdrawn
   * @param sender Sender of the withdrawLiquidity transaction
   * @return remainingLiquidity Remaining unused collateral in the pool
   */
  function withdrawLiquidity(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    ISynthereumLiquidityPoolStorage.FeeStatus storage feeStatus,
    FixedPoint.Unsigned calldata collateralAmount,
    address sender
  ) external returns (uint256 remainingLiquidity) {
    remainingLiquidity = self._withdrawLiquidity(
      lpPosition,
      feeStatus,
      collateralAmount,
      sender
    );
  }

  /**
   * @notice Increase collaterallization of Lp position
   * @notice Only a sender with LP role can call this function
   * @param self Data type the library is attached to
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param feeStatus Actual status of fee gained (see FeeStatus struct)
   * @param collateralToTransfer Collateral to be transferred before increase collateral in the position
   * @param collateralToIncrease Collateral to be added to the position
   * @param sender Sender of the increaseCollateral transaction
   * @return newTotalCollateral New total collateral amount
   */
  function increaseCollateral(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    ISynthereumLiquidityPoolStorage.FeeStatus storage feeStatus,
    FixedPoint.Unsigned calldata collateralToTransfer,
    FixedPoint.Unsigned calldata collateralToIncrease,
    address sender
  ) external returns (uint256 newTotalCollateral) {
    // Check the collateral to be increased is not 0
    require(collateralToIncrease.rawValue > 0, 'No collateral to be increased');

    // Deposit collateral in the pool
    if (collateralToTransfer.rawValue > 0) {
      self.pullCollateral(sender, collateralToTransfer);
    }

    // Collateral available
    FixedPoint.Unsigned memory unusedCollateral =
      self.calculateUnusedCollateral(
        lpPosition.totalCollateralAmount,
        feeStatus.totalFeeAmount,
        FixedPoint.Unsigned(0)
      );

    // Check that there is enoush availabe collateral deposited in the pool
    require(
      unusedCollateral.isGreaterThanOrEqual(collateralToIncrease),
      'No enough liquidity for increasing collateral'
    );

    // Update new total collateral amount
    FixedPoint.Unsigned memory _newTotalCollateral =
      lpPosition.totalCollateralAmount.add(collateralToIncrease);

    lpPosition.totalCollateralAmount = _newTotalCollateral;

    newTotalCollateral = _newTotalCollateral.rawValue;

    emit IncreaseCollateral(
      sender,
      collateralToIncrease.rawValue,
      newTotalCollateral
    );
  }

  /**
   * @notice Decrease collaterallization of Lp position
   * @notice Check that final position is not undercollateralized
   * @notice Only a sender with LP role can call this function
   * @param self Data type the library is attached to
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param liquidationData Liquidation info (see LiquidationData struct)
   * @param feeStatus Actual status of fee gained (see FeeStatus struct)
   * @param collateralToDecrease Collateral to decreased from the position
   * @param collateralToWithdraw Collateral to be transferred to the LP
   * @param sender Sender of the decreaseCollateral transaction
   * @return newTotalCollateral New total collateral amount
   */
  function decreaseCollateral(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    ISynthereumLiquidityPoolStorage.Liquidation storage liquidationData,
    ISynthereumLiquidityPoolStorage.FeeStatus storage feeStatus,
    FixedPoint.Unsigned calldata collateralToDecrease,
    FixedPoint.Unsigned calldata collateralToWithdraw,
    address sender
  ) external returns (uint256 newTotalCollateral) {
    // Check that collateral to be decreased is not 0
    require(collateralToDecrease.rawValue > 0, 'No collateral to be decreased');

    // Resulting total collateral amount
    FixedPoint.Unsigned memory _newTotalCollateral =
      lpPosition.totalCollateralAmount.sub(collateralToDecrease);

    // Check that position doesn't become undercollateralized
    (bool _isOverCollateralized, , ) =
      lpPosition.isOverCollateralized(
        liquidationData,
        getPriceFeedRate(self.finder, self.priceIdentifier),
        getCollateralDecimals(self.collateralToken),
        _newTotalCollateral
      );

    require(_isOverCollateralized, 'Position undercollateralized');

    // Update new total collateral amount
    lpPosition.totalCollateralAmount = _newTotalCollateral;

    newTotalCollateral = _newTotalCollateral.rawValue;

    emit DecreaseCollateral(
      sender,
      collateralToDecrease.rawValue,
      newTotalCollateral
    );

    if (collateralToWithdraw.rawValue > 0) {
      self._withdrawLiquidity(
        lpPosition,
        feeStatus,
        collateralToWithdraw,
        sender
      );
    }
  }

  /**
   * @notice Withdraw fees gained by the sender
   * @param self Data type the library is attached to
   * @param feeStatus Actual status of fee gained (see FeeStatus struct)
   * @param sender Sender of the claimFee transaction
   * @return feeClaimed Amount of fee claimed
   */
  function claimFee(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.FeeStatus storage feeStatus,
    address sender
  ) external returns (uint256 feeClaimed) {
    // Fee to claim
    FixedPoint.Unsigned memory _feeClaimed = feeStatus.feeGained[sender];
    feeClaimed = _feeClaimed.rawValue;

    // Check that fee is available
    require(feeClaimed > 0, 'No fee to claim');

    // Update fee status
    delete feeStatus.feeGained[sender];

    FixedPoint.Unsigned memory _totalRemainingFees =
      feeStatus.totalFeeAmount.sub(_feeClaimed);

    feeStatus.totalFeeAmount = _totalRemainingFees;

    // Transfer amount to the sender
    self.collateralToken.safeTransfer(sender, feeClaimed);

    emit ClaimFee(sender, feeClaimed, _totalRemainingFees.rawValue);
  }

  /**
   * @notice Liquidate Lp position for an amount of synthetic tokens undercollateralized
   * @notice Revert if position is not undercollateralized
   * @param self Data type the library is attached to
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param liquidationData Liquidation info (see LiquidationData struct)
   * @param feeStatus Actual status of fee gained (see FeeStatus struct)
   * @param numSynthTokens Number of synthetic tokens that user wants to liquidate
   * @param sender Sender of the liquidation transaction
   * @return synthTokensLiquidated Amount of synthetic tokens liquidated
   * @return collateralReceived Amount of received collateral equal to the value of tokens liquidated
   * @return rewardAmount Amount of received collateral as reward for the liquidation
   */
  function liquidate(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    ISynthereumLiquidityPoolStorage.Liquidation storage liquidationData,
    ISynthereumLiquidityPoolStorage.FeeStatus storage feeStatus,
    FixedPoint.Unsigned calldata numSynthTokens,
    address sender
  )
    external
    returns (
      uint256 synthTokensLiquidated,
      uint256 collateralReceived,
      uint256 rewardAmount
    )
  {
    // Memory struct for saving local varibales
    ExecuteLiquidation memory executeLiquidation;

    executeLiquidation.totalCollateralAmount = lpPosition.totalCollateralAmount;

    executeLiquidation.priceRate = getPriceFeedRate(
      self.finder,
      self.priceIdentifier
    );

    uint8 collateralDecimals = getCollateralDecimals(self.collateralToken);

    // Collateral value of the synthetic token passed
    {
      (bool _isOverCollaterlized, , ) =
        lpPosition.isOverCollateralized(
          liquidationData,
          executeLiquidation.priceRate,
          collateralDecimals,
          executeLiquidation.totalCollateralAmount
        );

      // Revert if position is not undercollataralized
      require(!_isOverCollaterlized, 'Position is overcollateralized');
    }

    IStandardERC20 _collateralToken = self.collateralToken;

    executeLiquidation.tokensCollateralized = lpPosition.tokensCollateralized;

    executeLiquidation.tokensInLiquidation = FixedPoint.min(
      numSynthTokens,
      executeLiquidation.tokensCollateralized
    );

    executeLiquidation.expectedCollateral = calculateCollateralAmount(
      executeLiquidation.priceRate,
      collateralDecimals,
      executeLiquidation.tokensInLiquidation
    );

    executeLiquidation.userCollateralization = executeLiquidation
      .tokensInLiquidation
      .div(executeLiquidation.tokensCollateralized)
      .mul(executeLiquidation.totalCollateralAmount);

    if (
      executeLiquidation.userCollateralization.isGreaterThanOrEqual(
        executeLiquidation.expectedCollateral
      )
    ) {
      executeLiquidation.settledCollateral = executeLiquidation
        .expectedCollateral;
      executeLiquidation.rewardAmount = executeLiquidation
        .userCollateralization
        .sub(executeLiquidation.expectedCollateral)
        .mul(liquidationData.liquidationReward);

      // Update Lp position
      lpPosition.totalCollateralAmount = executeLiquidation
        .totalCollateralAmount
        .sub(executeLiquidation.settledCollateral)
        .sub(executeLiquidation.rewardAmount);
    } else {
      executeLiquidation.unusedCollateral = self.calculateUnusedCollateral(
        executeLiquidation.totalCollateralAmount,
        feeStatus.totalFeeAmount,
        FixedPoint.Unsigned(0)
      );
      executeLiquidation.settledCollateral = FixedPoint.min(
        executeLiquidation.expectedCollateral,
        executeLiquidation.userCollateralization.add(
          executeLiquidation.unusedCollateral
        )
      );

      // Update Lp position untill max 105% coverage using available liquidity
      lpPosition.totalCollateralAmount = FixedPoint.min(
        executeLiquidation
          .totalCollateralAmount
          .add(executeLiquidation.unusedCollateral)
          .sub(executeLiquidation.settledCollateral),
        calculateCollateralAmount(
          executeLiquidation
            .priceRate,
          collateralDecimals,
          executeLiquidation.tokensCollateralized.sub(
            executeLiquidation.tokensInLiquidation
          )
        )
          .mul(liquidationData.collateralRequirement)
      );
    }

    lpPosition.tokensCollateralized = executeLiquidation
      .tokensCollateralized
      .sub(executeLiquidation.tokensInLiquidation);

    collateralReceived = executeLiquidation.settledCollateral.rawValue;

    rewardAmount = executeLiquidation.rewardAmount.rawValue;

    synthTokensLiquidated = executeLiquidation.tokensInLiquidation.rawValue;

    // Burn synthetic tokens to be liquidated
    self.burnSyntheticTokens(synthTokensLiquidated, sender);

    // Transfer liquidated collateral and reward to the user
    _collateralToken.safeTransfer(sender, collateralReceived + rewardAmount);

    emit Liquidate(
      sender,
      synthTokensLiquidated,
      executeLiquidation.priceRate.rawValue,
      executeLiquidation.expectedCollateral.rawValue,
      collateralReceived,
      rewardAmount
    );
  }

  /**
   * @notice Shutdown the pool in case of emergency
   * @notice Only Synthereum manager contract can call this function
   * @param self Data type the library is attached to
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param feeStatus Actual status of fee gained (see FeeStatus struct)
   * @param emergencyShutdownData Emergency shutdown info (see Shutdown struct)
   * @return timestamp Timestamp of emergency shutdown transaction
   * @return price Price of the pair at the moment of shutdown execution
   */
  function emergencyShutdown(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    ISynthereumLiquidityPoolStorage.FeeStatus storage feeStatus,
    ISynthereumLiquidityPoolStorage.Shutdown storage emergencyShutdownData
  ) external returns (uint256 timestamp, uint256 price) {
    ISynthereumFinder _finder = self.finder;

    require(
      msg.sender ==
        _finder.getImplementationAddress(SynthereumInterfaces.Manager),
      'Caller must be the Synthereum manager'
    );

    timestamp = block.timestamp;

    emergencyShutdownData.timestamp = timestamp;

    FixedPoint.Unsigned memory _price =
      getPriceFeedRate(_finder, self.priceIdentifier);

    emergencyShutdownData.price = _price;

    price = _price.rawValue;

    // Move available liquidity in the position
    FixedPoint.Unsigned memory totalCollateral =
      lpPosition.totalCollateralAmount;

    FixedPoint.Unsigned memory unusedCollateral =
      self.calculateUnusedCollateral(
        totalCollateral,
        feeStatus.totalFeeAmount,
        FixedPoint.Unsigned(0)
      );

    FixedPoint.Unsigned memory finalCollateral =
      totalCollateral.add(unusedCollateral);

    lpPosition.totalCollateralAmount = finalCollateral;

    emit EmergencyShutdown(timestamp, price, finalCollateral.rawValue);
  }

  /**
   * @notice Redeem tokens after emergency shutdown
   * @param self Data type the library is attached to
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param feeStatus Actual status of fee gained (see FeeStatus struct)
   * @param emergencyShutdownData Emergency shutdown info (see Shutdown struct)
   * @param isLiquidityProvider True if the sender is an LP, otherwise false
   * @param sender Sender of the settleEmergencyShutdown transaction
   * @return synthTokensSettled Amount of synthetic tokens liquidated
   * @return collateralSettled Amount of collateral withdrawn after emergency shutdown
   */
  function settleEmergencyShutdown(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    ISynthereumLiquidityPoolStorage.FeeStatus storage feeStatus,
    ISynthereumLiquidityPoolStorage.Shutdown storage emergencyShutdownData,
    bool isLiquidityProvider,
    address sender
  ) external returns (uint256 synthTokensSettled, uint256 collateralSettled) {
    // Memory struct for saving local varibales
    ExecuteSettlement memory executeSettlement;

    IMintableBurnableERC20 syntheticToken = self.syntheticToken;

    executeSettlement.emergencyPrice = emergencyShutdownData.price;

    executeSettlement.userNumTokens = FixedPoint.Unsigned(
      syntheticToken.balanceOf(sender)
    );

    require(
      executeSettlement.userNumTokens.rawValue > 0 || isLiquidityProvider,
      'Sender has nothing to settle'
    );

    if (executeSettlement.userNumTokens.rawValue > 0) {
      // Move synthetic tokens from the user to the pool
      // - This is because derivative expects the tokens to come from the sponsor address
      syntheticToken.safeTransferFrom(
        sender,
        address(this),
        executeSettlement.userNumTokens.rawValue
      );
    }

    executeSettlement.totalCollateralAmount = lpPosition.totalCollateralAmount;
    executeSettlement.tokensCollaterlized = lpPosition.tokensCollateralized;
    executeSettlement.totalFeeAmount = feeStatus.totalFeeAmount;
    executeSettlement.overCollateral;

    IStandardERC20 _collateralToken = self.collateralToken;

    uint8 collateralDecimals = getCollateralDecimals(_collateralToken);

    // Add overcollateral and deposited synthetic tokens if the sender is the LP
    if (isLiquidityProvider) {
      FixedPoint.Unsigned memory totalRedeemableCollateral =
        calculateCollateralAmount(
          executeSettlement.emergencyPrice,
          collateralDecimals,
          executeSettlement.tokensCollaterlized
        );

      executeSettlement.overCollateral = executeSettlement
        .totalCollateralAmount
        .isGreaterThan(totalRedeemableCollateral)
        ? executeSettlement.totalCollateralAmount.sub(totalRedeemableCollateral)
        : FixedPoint.Unsigned(0);

      executeSettlement.userNumTokens = FixedPoint.Unsigned(
        syntheticToken.balanceOf(address(this))
      );
    }

    // Calculate expected and settled collateral
    executeSettlement.redeemableCollateral = calculateCollateralAmount(
      executeSettlement
        .emergencyPrice,
      collateralDecimals,
      executeSettlement
        .userNumTokens
    )
      .add(executeSettlement.overCollateral);

    executeSettlement.unusedCollateral = self.calculateUnusedCollateral(
      executeSettlement.totalCollateralAmount,
      executeSettlement.totalFeeAmount,
      FixedPoint.Unsigned(0)
    );

    executeSettlement.transferableCollateral = FixedPoint.min(
      executeSettlement.redeemableCollateral,
      executeSettlement.totalCollateralAmount
    );

    // Update Lp position
    lpPosition.totalCollateralAmount = executeSettlement
      .totalCollateralAmount
      .isGreaterThan(executeSettlement.redeemableCollateral)
      ? executeSettlement.totalCollateralAmount.sub(
        executeSettlement.redeemableCollateral
      )
      : FixedPoint.Unsigned(0);

    lpPosition.tokensCollateralized = executeSettlement.tokensCollaterlized.sub(
      executeSettlement.userNumTokens
    );

    synthTokensSettled = executeSettlement.userNumTokens.rawValue;

    collateralSettled = executeSettlement.transferableCollateral.rawValue;

    // Burn synthetic tokens
    syntheticToken.burn(synthTokensSettled);

    // Transfer settled collateral to the user
    _collateralToken.safeTransfer(sender, collateralSettled);

    emit Settle(
      sender,
      synthTokensSettled,
      executeSettlement.redeemableCollateral.rawValue,
      collateralSettled
    );
  }

  /**
   * @notice Update the fee percentage
   * @param self Data type the library is attached to
   * @param _feePercentage The new fee percentage
   */
  function setFeePercentage(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    FixedPoint.Unsigned calldata _feePercentage
  ) external {
    require(
      _feePercentage.rawValue < 10**(18),
      'Fee Percentage must be less than 100%'
    );

    self.fee.feeData.feePercentage = _feePercentage;

    emit SetFeePercentage(_feePercentage.rawValue);
  }

  /**
   * @notice Update the addresses of recipients for generated fees and proportions of fees each address will receive
   * @param self Data type the library is attached to
   * @param _feeRecipients An array of the addresses of recipients that will receive generated fees
   * @param _feeProportions An array of the proportions of fees generated each recipient will receive
   */
  function setFeeRecipients(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    address[] calldata _feeRecipients,
    uint32[] calldata _feeProportions
  ) external {
    require(
      _feeRecipients.length == _feeProportions.length,
      'Fee recipients and fee proportions do not match'
    );

    uint256 totalActualFeeProportions;

    // Store the sum of all proportions
    for (uint256 i = 0; i < _feeProportions.length; i++) {
      totalActualFeeProportions += _feeProportions[i];
    }

    ISynthereumLiquidityPoolStorage.FeeData storage _feeData = self.fee.feeData;

    _feeData.feeRecipients = _feeRecipients;
    _feeData.feeProportions = _feeProportions;
    self.fee.totalFeeProportions = totalActualFeeProportions;

    emit SetFeeRecipients(_feeRecipients, _feeProportions);
  }

  /**
   * @notice Update the overcollateralization percentage
   * @param self Data type the library is attached to
   * @param liquidationData Liquidation info (see LiquidationData struct)
   * @param _overCollateralization Overcollateralization percentage
   */
  function setOverCollateralization(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.Liquidation storage liquidationData,
    FixedPoint.Unsigned calldata _overCollateralization
  ) external {
    require(
      _overCollateralization.isGreaterThan(
        liquidationData.collateralRequirement.sub(1)
      ),
      'Overcollateralization must be bigger than the Lp part of the collateral requirement'
    );

    self.overCollateralization = _overCollateralization;

    emit SetOverCollateralization(_overCollateralization.rawValue);
  }

  /**
   * @notice Update the liquidation reward percentage
   * @param liquidationData Liquidation info (see LiquidationData struct)
   * @param _liquidationReward Percentage of reward for correct liquidation by a liquidator
   */
  function setLiquidationReward(
    ISynthereumLiquidityPoolStorage.Liquidation storage liquidationData,
    FixedPoint.Unsigned calldata _liquidationReward
  ) external {
    require(
      _liquidationReward.rawValue > 0 &&
        _liquidationReward.isLessThanOrEqual(1),
      'Liquidation reward must be between 0 and 100%'
    );

    liquidationData.liquidationReward = _liquidationReward;

    emit SetLiquidationReward(_liquidationReward.rawValue);
  }

  //----------------------------------------
  // External view functions
  //----------------------------------------

  /**
   * @notice Returns the total amount of liquidity deposited in the pool, but nut used as collateral
   * @param self Data type the library is attached to
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param feeStatus Actual status of fee gained (see FeeStatus struct)
   * @return Total available liquidity
   */
  function totalAvailableLiquidity(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    ISynthereumLiquidityPoolStorage.FeeStatus storage feeStatus
  ) external view returns (uint256) {
    return
      self
        .calculateUnusedCollateral(
        lpPosition
          .totalCollateralAmount,
        feeStatus
          .totalFeeAmount,
        FixedPoint.Unsigned(0)
      )
        .rawValue;
  }

  /**
   * @notice Returns if position is overcollateralized and thepercentage of coverage of the collateral according to the last price
   * @param self Data type the library is attached to
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param liquidationData Liquidation info (see LiquidationData struct)
   * @return True if position is overcollaterlized, otherwise false + percentage of coverage (totalCollateralAmount / (price * tokensCollateralized))
   */
  function collateralCoverage(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    ISynthereumLiquidityPoolStorage.Liquidation storage liquidationData
  ) external view returns (bool, uint256) {
    FixedPoint.Unsigned memory priceRate =
      getPriceFeedRate(self.finder, self.priceIdentifier);

    uint8 collateralDecimals = getCollateralDecimals(self.collateralToken);

    (
      bool _isOverCollateralized,
      ,
      FixedPoint.Unsigned memory overCollateralValue
    ) =
      lpPosition.isOverCollateralized(
        liquidationData,
        priceRate,
        collateralDecimals,
        lpPosition.totalCollateralAmount
      );

    FixedPoint.Unsigned memory coverageRatio =
      lpPosition.totalCollateralAmount.div(overCollateralValue);

    FixedPoint.Unsigned memory _collateralCoverage =
      liquidationData.collateralRequirement.mul(coverageRatio);

    return (_isOverCollateralized, _collateralCoverage.rawValue);
  }

  /**
   * @notice Returns the synthetic tokens will be received and fees will be paid in exchange for an input collateral amount
   * @notice This function is only trading-informative, it doesn't check liquidity and collateralization conditions
   * @param self Data type the library is attached to
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param feeStatus Actual status of fee gained (see FeeStatus struct)
   * @param inputCollateral Input collateral amount to be exchanged
   * @return synthTokensReceived Synthetic tokens will be minted
   * @return feePaid Collateral fee will be paid
   */
  function getMintTradeInfo(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    ISynthereumLiquidityPoolStorage.FeeStatus storage feeStatus,
    FixedPoint.Unsigned calldata inputCollateral
  ) external view returns (uint256 synthTokensReceived, uint256 feePaid) {
    (
      FixedPoint.Unsigned memory collateralAmount,
      FixedPoint.Unsigned memory _feePaid,
      FixedPoint.Unsigned memory _synthTokensReceived
    ) = self.mintCalculation(inputCollateral);

    require(
      collateralAmount.rawValue > 0,
      'Sending collateral amount is equal to 0'
    );

    FixedPoint.Unsigned memory overCollateral =
      collateralAmount.mul(self.overCollateralization);

    FixedPoint.Unsigned memory unusedCollateral =
      self.calculateUnusedCollateral(
        lpPosition.totalCollateralAmount,
        feeStatus.totalFeeAmount,
        FixedPoint.Unsigned(0)
      );

    require(
      unusedCollateral.isGreaterThanOrEqual(overCollateral),
      'No enough liquidity for covering mint operation'
    );

    synthTokensReceived = _synthTokensReceived.rawValue;
    feePaid = _feePaid.rawValue;
  }

  /**
   * @notice Returns the collateral amount will be received and fees will be paid in exchange for an input amount of synthetic tokens
   * @notice This function is only trading-informative, it doesn't check liquidity and collateralization conditions
   * @param self Data type the library is attached to
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param  syntheticTokens Amount of synthetic tokens to be exchanged
   * @return collateralAmountReceived Collateral amount will be received by the user
   * @return feePaid Collateral fee will be paid
   */
  function getRedeemTradeInfo(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    FixedPoint.Unsigned calldata syntheticTokens
  ) external view returns (uint256 collateralAmountReceived, uint256 feePaid) {
    FixedPoint.Unsigned memory totalActualTokens =
      lpPosition.tokensCollateralized;

    require(
      syntheticTokens.rawValue > 0,
      'Sending tokens amount is equal to 0'
    );

    require(
      syntheticTokens.isLessThanOrEqual(totalActualTokens),
      'Sending tokens amount bigger than amount in the position'
    );

    (
      FixedPoint.Unsigned memory totCollateralAmount,
      FixedPoint.Unsigned memory _feePaid,
      FixedPoint.Unsigned memory _collateralAmountReceived
    ) = self.redeemCalculation(syntheticTokens);

    FixedPoint.Unsigned memory collateralRedeemed =
      syntheticTokens.div(totalActualTokens).mul(
        lpPosition.totalCollateralAmount
      );

    require(
      collateralRedeemed.isGreaterThanOrEqual(totCollateralAmount),
      'Position undercapitalized'
    );

    collateralAmountReceived = _collateralAmountReceived.rawValue;
    feePaid = _feePaid.rawValue;
  }

  /**
   * @notice Returns the destination synthetic tokens amount will be received and fees will be paid in exchange for an input amount of synthetic tokens
   * @notice This function is only trading-informative, it doesn't check liquidity and collateralization conditions
   * @param self Data type the library is attached to
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param  syntheticTokens Amount of synthetic tokens to be exchanged
   * @param  destinationPool Pool in which mint the destination synthetic token
   * @return destSyntheticTokensReceived Synthetic tokens will be received from destination pool
   * @return feePaid Collateral fee will be paid
   */
  function getExchangeTradeInfo(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    FixedPoint.Unsigned calldata syntheticTokens,
    ISynthereumLiquidityPoolGeneral destinationPool
  )
    external
    view
    returns (uint256 destSyntheticTokensReceived, uint256 feePaid)
  {
    self.checkPool(destinationPool);

    require(
      address(this) != address(destinationPool),
      'Same source and destination pool'
    );

    FixedPoint.Unsigned memory totalActualTokens =
      lpPosition.tokensCollateralized;

    require(
      syntheticTokens.rawValue > 0,
      'Sending tokens amount is equal to 0'
    );

    require(
      syntheticTokens.isLessThanOrEqual(totalActualTokens),
      'Sending tokens amount bigger than amount in the position'
    );

    (
      FixedPoint.Unsigned memory totCollateralAmount,
      FixedPoint.Unsigned memory _feePaid,
      FixedPoint.Unsigned memory collateralAmount,
      FixedPoint.Unsigned memory _destSyntheticTokensReceived
    ) = self.exchangeCalculation(syntheticTokens, destinationPool);

    FixedPoint.Unsigned memory collateralRedeemed =
      syntheticTokens.div(totalActualTokens).mul(
        lpPosition.totalCollateralAmount
      );

    require(
      collateralRedeemed.isGreaterThanOrEqual(totCollateralAmount),
      'Position undercapitalized'
    );

    require(
      collateralAmount.rawValue > 0,
      'Sending collateral amount is equal to 0'
    );

    FixedPoint.Unsigned memory destOverCollateral =
      collateralAmount.mul(
        FixedPoint.Unsigned(destinationPool.overCollateralization())
      );

    FixedPoint.Unsigned memory destUnusedCollateral =
      FixedPoint.Unsigned(destinationPool.totalAvailableLiquidity());

    require(
      destUnusedCollateral.isGreaterThanOrEqual(destOverCollateral),
      'No enough liquidity for covering mint operation'
    );

    destSyntheticTokensReceived = _destSyntheticTokensReceived.rawValue;
    feePaid = _feePaid.rawValue;
  }

  //----------------------------------------
  //  Internal functions
  //----------------------------------------

  /**
   * @notice Execute mint of synthetic tokens
   * @param self Data type the library is attached to
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param feeStatus Actual status of fee gained (see FeeStatus struct)
   * @param executeMintParams Params for execution of mint (see ExecuteMintParams struct)
   */
  function executeMint(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    ISynthereumLiquidityPoolStorage.FeeStatus storage feeStatus,
    ExecuteMintParams memory executeMintParams
  ) internal {
    // Sending amount must be different from 0
    require(
      executeMintParams.collateralAmount.rawValue > 0,
      'Sending collateral amount is equal to 0'
    );

    // Collateral available
    FixedPoint.Unsigned memory unusedCollateral =
      self.calculateUnusedCollateral(
        lpPosition.totalCollateralAmount,
        feeStatus.totalFeeAmount,
        FixedPoint.Unsigned(0)
      );

    // Update LP's collateralization status
    FixedPoint.Unsigned memory overCollateral =
      lpPosition.updateLpPositionInMint(
        self.overCollateralization,
        executeMintParams.collateralAmount,
        executeMintParams.numTokens
      );

    //Check there is enough liquidity in the pool for overcollateralization
    require(
      unusedCollateral.isGreaterThanOrEqual(overCollateral),
      'No enough liquidity for covering mint operation'
    );

    // Update fees status
    feeStatus.updateFees(self.fee, executeMintParams.feeAmount);

    // Pull user's collateral
    self.pullCollateral(
      executeMintParams.sender,
      executeMintParams.totCollateralAmount
    );

    // Mint synthetic asset and transfer to the recipient
    self.syntheticToken.mint(
      executeMintParams.recipient,
      executeMintParams.numTokens.rawValue
    );

    emit Mint(
      executeMintParams.sender,
      executeMintParams.totCollateralAmount.rawValue,
      executeMintParams.numTokens.rawValue,
      executeMintParams.feeAmount.rawValue,
      executeMintParams.recipient
    );
  }

  /**
   * @notice Execute redeem of collateral
   * @param self Data type the library is attached tfo
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param feeStatus Actual status of fee gained (see FeeStatus struct)
   * @param executeRedeemParams Params for execution of redeem (see ExecuteRedeemParams struct)
   */
  function executeRedeem(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    ISynthereumLiquidityPoolStorage.FeeStatus storage feeStatus,
    ExecuteRedeemParams memory executeRedeemParams
  ) internal {
    // Sending amount must be different from 0
    require(
      executeRedeemParams.numTokens.rawValue > 0,
      'Sending tokens amount is equal to 0'
    );

    FixedPoint.Unsigned memory collateralRedeemed =
      lpPosition.updateLpPositionInRedeem(executeRedeemParams.numTokens);

    // Check that collateral redemeed is enough for cover the value of synthetic tokens
    require(
      collateralRedeemed.isGreaterThanOrEqual(
        executeRedeemParams.totCollateralAmount
      ),
      'Position undercapitalized'
    );

    // Update fees status
    feeStatus.updateFees(self.fee, executeRedeemParams.feeAmount);

    // Burn synthetic tokens
    self.burnSyntheticTokens(
      executeRedeemParams.numTokens.rawValue,
      executeRedeemParams.sender
    );

    //Send net amount of collateral to the user that submitted the redeem request
    self.collateralToken.safeTransfer(
      executeRedeemParams.recipient,
      executeRedeemParams.collateralAmount.rawValue
    );

    emit Redeem(
      executeRedeemParams.sender,
      executeRedeemParams.numTokens.rawValue,
      executeRedeemParams.collateralAmount.rawValue,
      executeRedeemParams.feeAmount.rawValue,
      executeRedeemParams.recipient
    );
  }

  /**
   * @notice Execute exchange between synthetic tokens
   * @param self Data type the library is attached tfo
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param feeStatus Actual status of fee gained (see FeeStatus struct)
   * @param executeExchangeParams Params for execution of exchange (see ExecuteExchangeParams struct)
   */
  function executeExchange(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    ISynthereumLiquidityPoolStorage.FeeStatus storage feeStatus,
    ExecuteExchangeParams memory executeExchangeParams
  ) internal {
    // Sending amount must be different from 0
    require(
      executeExchangeParams.numTokens.rawValue > 0,
      'Sending tokens amount is equal to 0'
    );

    FixedPoint.Unsigned memory collateralRedeemed =
      lpPosition.updateLpPositionInRedeem(executeExchangeParams.numTokens);

    // Check that collateral redemeed is enough for cover the value of synthetic tokens
    require(
      collateralRedeemed.isGreaterThanOrEqual(
        executeExchangeParams.totCollateralAmount
      ),
      'Position undercapitalized'
    );

    // Update fees status
    feeStatus.updateFees(self.fee, executeExchangeParams.feeAmount);

    // Burn synthetic tokens
    self.burnSyntheticTokens(
      executeExchangeParams.numTokens.rawValue,
      executeExchangeParams.sender
    );

    ISynthereumLiquidityPoolGeneral destinationPool =
      executeExchangeParams.destPool;

    // Check that destination pool is different from this pool
    require(
      address(this) != address(destinationPool),
      'Same source and destination pool'
    );

    self.checkPool(destinationPool);

    // Transfer collateral amount (without overcollateralization) to the destination pool
    self.collateralToken.safeTransfer(
      address(destinationPool),
      executeExchangeParams.collateralAmount.rawValue
    );

    // Mint the destination tokens with the withdrawn collateral
    destinationPool.exchangeMint(
      executeExchangeParams.collateralAmount.rawValue,
      executeExchangeParams.destNumTokens.rawValue,
      executeExchangeParams.recipient
    );

    emit Exchange(
      executeExchangeParams.sender,
      address(destinationPool),
      executeExchangeParams.numTokens.rawValue,
      executeExchangeParams.destNumTokens.rawValue,
      executeExchangeParams.feeAmount.rawValue,
      executeExchangeParams.recipient
    );
  }

  /**
   * @notice Withdraw unused deposited collateral by the LP
   * @param self Data type the library is attached to
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param feeStatus Actual status of fee gained (see FeeStatus struct)
   * @param collateralAmount Collateral to be withdrawn
   * @param sender Sender that withdraws liquidity
   * @return remainingLiquidity Remaining unused collateral in the pool
   */
  function _withdrawLiquidity(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    ISynthereumLiquidityPoolStorage.FeeStatus storage feeStatus,
    FixedPoint.Unsigned memory collateralAmount,
    address sender
  ) internal returns (uint256 remainingLiquidity) {
    // Collateral available
    FixedPoint.Unsigned memory unusedCollateral =
      self.calculateUnusedCollateral(
        lpPosition.totalCollateralAmount,
        feeStatus.totalFeeAmount,
        FixedPoint.Unsigned(0)
      );

    // Check that available collateral is bigger than collateral to be withdrawn and returns the difference
    remainingLiquidity = (unusedCollateral.sub(collateralAmount)).rawValue;

    // Transfer amount to the Lp
    uint256 _collateralAmount = collateralAmount.rawValue;

    self.collateralToken.safeTransfer(sender, _collateralAmount);

    emit WithdrawLiquidity(sender, _collateralAmount, remainingLiquidity);
  }

  /**
   * @notice Update LP's collateralization status after a mint
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param overCollateralization Overcollateralization rate
   * @param collateralAmount Collateral amount to be added (only user collateral)
   * @param numTokens Tokens to be added
   * @return overCollateral Amount of collateral to be provided by LP for overcollateralization
   */
  function updateLpPositionInMint(
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    FixedPoint.Unsigned storage overCollateralization,
    FixedPoint.Unsigned memory collateralAmount,
    FixedPoint.Unsigned memory numTokens
  ) internal returns (FixedPoint.Unsigned memory overCollateral) {
    overCollateral = collateralAmount.mul(overCollateralization);

    lpPosition.totalCollateralAmount = lpPosition
      .totalCollateralAmount
      .add(collateralAmount)
      .add(overCollateral);

    lpPosition.tokensCollateralized = lpPosition.tokensCollateralized.add(
      numTokens
    );
  }

  /**
   * @notice Update LP's collateralization status after a redeem
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param numTokens Tokens to be removed
   * @return collateralRedeemed Collateral redeemed
   */
  function updateLpPositionInRedeem(
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    FixedPoint.Unsigned memory numTokens
  ) internal returns (FixedPoint.Unsigned memory collateralRedeemed) {
    FixedPoint.Unsigned memory totalActualTokens =
      lpPosition.tokensCollateralized;

    FixedPoint.Unsigned memory totalActualCollateral =
      lpPosition.totalCollateralAmount;

    FixedPoint.Unsigned memory fractionRedeemed =
      numTokens.div(totalActualTokens);

    collateralRedeemed = fractionRedeemed.mul(totalActualCollateral);

    lpPosition.tokensCollateralized = totalActualTokens.sub(numTokens);

    lpPosition.totalCollateralAmount = totalActualCollateral.sub(
      collateralRedeemed
    );
  }

  /**
   * @notice Update fee gained by the fee recipients
   * @param feeStatus Actual status of fee gained to be withdrawn
   * @param feeInfo Actual status of fee recipients and their proportions
   * @param feeAmount Collateral fee charged
   */
  function updateFees(
    ISynthereumLiquidityPoolStorage.FeeStatus storage feeStatus,
    ISynthereumLiquidityPoolStorage.Fee storage feeInfo,
    FixedPoint.Unsigned memory feeAmount
  ) internal {
    FixedPoint.Unsigned memory feeCharged;

    address[] storage feeRecipients = feeInfo.feeData.feeRecipients;

    uint32[] storage feeProportions = feeInfo.feeData.feeProportions;

    uint256 totalFeeProportions = feeInfo.totalFeeProportions;

    uint256 numberOfRecipients = feeRecipients.length;

    mapping(address => FixedPoint.Unsigned) storage feeGained =
      feeStatus.feeGained;

    for (uint256 i = 0; i < numberOfRecipients - 1; i++) {
      address feeRecipient = feeRecipients[i];
      FixedPoint.Unsigned memory feeReceived =
        FixedPoint.Unsigned(
          (feeAmount.rawValue * feeProportions[i]) / totalFeeProportions
        );
      feeGained[feeRecipient] = feeGained[feeRecipient].add(feeReceived);
      feeCharged = feeCharged.add(feeReceived);
    }

    address lastRecipient = feeRecipients[numberOfRecipients - 1];

    feeGained[lastRecipient] = feeGained[lastRecipient].add(feeAmount).sub(
      feeCharged
    );

    feeStatus.totalFeeAmount = feeStatus.totalFeeAmount.add(feeAmount);
  }

  /**
   * @notice Pulls collateral tokens from the sender to store in the Pool
   * @param self Data type the library is attached to
   * @param numTokens The number of tokens to pull
   */
  function pullCollateral(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    address from,
    FixedPoint.Unsigned memory numTokens
  ) internal {
    self.collateralToken.safeTransferFrom(
      from,
      address(this),
      numTokens.rawValue
    );
  }

  /**
   * @notice Pulls synthetic tokens from the sender and burn them
   * @param self Data type the library is attached to
   * @param numTokens The number of tokens to be burned
   * @param sender Sender of synthetic tokens
   */
  function burnSyntheticTokens(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    uint256 numTokens,
    address sender
  ) internal {
    IMintableBurnableERC20 synthToken = self.syntheticToken;

    // Transfer synthetic token from the user to the pool
    synthToken.safeTransferFrom(sender, address(this), numTokens);

    // Burn synthetic asset
    synthToken.burn(numTokens);
  }

  //----------------------------------------
  //  Internal views functions
  //----------------------------------------

  /**
   * @notice Given a collateral value to be exchanged, returns the fee amount, net collateral and synthetic tokens
   * @param self Data type the library is attached tfo
   * @param totCollateralAmount Collateral amount to be exchanged
   * @return collateralAmount Net collateral amount (totCollateralAmount - feePercentage)
   * @return feeAmount Fee to be paid according to the fee percentage
   * @return numTokens Number of synthetic tokens will be received according to the actual price in exchange for collateralAmount
   */
  function mintCalculation(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    FixedPoint.Unsigned memory totCollateralAmount
  )
    internal
    view
    returns (
      FixedPoint.Unsigned memory collateralAmount,
      FixedPoint.Unsigned memory feeAmount,
      FixedPoint.Unsigned memory numTokens
    )
  {
    feeAmount = totCollateralAmount.mul(self.fee.feeData.feePercentage);

    collateralAmount = totCollateralAmount.sub(feeAmount);

    numTokens = calculateNumberOfTokens(
      getPriceFeedRate(self.finder, self.priceIdentifier),
      getCollateralDecimals(self.collateralToken),
      collateralAmount
    );
  }

  /**
   * @notice Given a an amount of synthetic tokens to be exchanged, returns the fee amount, net collateral and gross collateral
   * @param self Data type the library is attached tfo
   * @param numTokens Synthetic tokens amount to be exchanged
   * @return totCollateralAmount Gross collateral amount (collateralAmount + feeAmount)
   * @return feeAmount Fee to be paid according to the fee percentage
   * @return collateralAmount Net collateral amount will be received according to the actual price in exchange for numTokens
   */
  function redeemCalculation(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    FixedPoint.Unsigned memory numTokens
  )
    internal
    view
    returns (
      FixedPoint.Unsigned memory totCollateralAmount,
      FixedPoint.Unsigned memory feeAmount,
      FixedPoint.Unsigned memory collateralAmount
    )
  {
    totCollateralAmount = calculateCollateralAmount(
      getPriceFeedRate(self.finder, self.priceIdentifier),
      getCollateralDecimals(self.collateralToken),
      numTokens
    );

    feeAmount = totCollateralAmount.mul(self.fee.feeData.feePercentage);

    collateralAmount = totCollateralAmount.sub(feeAmount);
  }

  /**
   * @notice Given a an amount of synthetic tokens to be exchanged, returns the fee amount, net collateral and gross collateral and number of destination tokens
   * @param self Data type the library is attached tfo
   * @param numTokens Synthetic tokens amount to be exchanged
   * @param destinationPool Pool from which destination tokens will be received
   * @return totCollateralAmount Gross collateral amount according to the price
   * @return feeAmount Fee to be paid according to the fee percentage
   * @return collateralAmount Net collateral amount (totCollateralAmount - feeAmount)
   * @return destNumTokens Number of destination synthetic tokens will be received according to the actual price in exchange for synthetic tokens
   */
  function exchangeCalculation(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    FixedPoint.Unsigned memory numTokens,
    ISynthereumLiquidityPoolGeneral destinationPool
  )
    internal
    view
    returns (
      FixedPoint.Unsigned memory totCollateralAmount,
      FixedPoint.Unsigned memory feeAmount,
      FixedPoint.Unsigned memory collateralAmount,
      FixedPoint.Unsigned memory destNumTokens
    )
  {
    ISynthereumFinder _finder = self.finder;

    IStandardERC20 _collateralToken = self.collateralToken;

    uint8 collateralDecimals = getCollateralDecimals(_collateralToken);

    totCollateralAmount = calculateCollateralAmount(
      getPriceFeedRate(_finder, self.priceIdentifier),
      collateralDecimals,
      numTokens
    );

    feeAmount = totCollateralAmount.mul(self.fee.feeData.feePercentage);

    collateralAmount = totCollateralAmount.sub(feeAmount);

    destNumTokens = calculateNumberOfTokens(
      getPriceFeedRate(_finder, destinationPool.getPriceFeedIdentifier()),
      collateralDecimals,
      collateralAmount
    );
  }

  /**
   * @notice Check expiration of mint, redeem and exchange transaction
   * @param expiration Expiration time of the transaction
   */
  function checkExpiration(uint256 expiration) internal view {
    require(block.timestamp <= expiration, 'Transaction expired');
  }

  /**
   * @notice Check if sender or receiver pool is a correct registered pool
   * @param self Data type the library is attached to
   * @param poolToCheck Pool that should be compared with this pool
   */
  function checkPool(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    ISynthereumLiquidityPoolGeneral poolToCheck
  ) internal view {
    IStandardERC20 collateralToken = self.collateralToken;
    require(
      collateralToken == poolToCheck.collateralToken(),
      'Collateral tokens do not match'
    );

    ISynthereumFinder finder = self.finder;

    require(finder == poolToCheck.synthereumFinder(), 'Finders do not match');

    ISynthereumRegistry poolRegister =
      ISynthereumRegistry(
        finder.getImplementationAddress(SynthereumInterfaces.PoolRegistry)
      );

    require(
      poolRegister.isDeployed(
        poolToCheck.syntheticTokenSymbol(),
        collateralToken,
        poolToCheck.version(),
        address(poolToCheck)
      ),
      'Destination pool not registered'
    );
  }

  /**
   * @notice Check if an amount of collateral is enough to collateralize the position
   * @param lpPosition Position of the LP (see LPPosition struct)
   * @param priceRate Price rate of the pair
   * @param collateralDecimals Number of decimals of the collateral
   * @param liquidationData Liquidation info (see LiquidationData struct)
   * @param collateralToCompare collateral used for checking the overcollaterlization
   * @return _isOverCollateralized True if position is overcollaterlized, otherwise false
   * @return collateralValue Collateral amount equal to the value of tokens
   * @return overCollateralValue Collateral amount equal to the value of tokens * collateralRequirement
   */
  function isOverCollateralized(
    ISynthereumLiquidityPoolStorage.LPPosition storage lpPosition,
    ISynthereumLiquidityPoolStorage.Liquidation storage liquidationData,
    FixedPoint.Unsigned memory priceRate,
    uint8 collateralDecimals,
    FixedPoint.Unsigned memory collateralToCompare
  )
    internal
    view
    returns (
      bool _isOverCollateralized,
      FixedPoint.Unsigned memory collateralValue,
      FixedPoint.Unsigned memory overCollateralValue
    )
  {
    collateralValue = calculateCollateralAmount(
      priceRate,
      collateralDecimals,
      lpPosition.tokensCollateralized
    );

    overCollateralValue = collateralValue.mul(
      liquidationData.collateralRequirement
    );

    _isOverCollateralized = collateralToCompare.isGreaterThanOrEqual(
      overCollateralValue
    );
  }

  /**
   * @notice Calculate the unused collateral of this pool
   * @param self Data type the library is attached to
   * @param totalCollateral Total collateral used
   * @param totalFees Total fees gained to be whitdrawn
   * @param collateralReceived Collateral sent to the pool by a user or contract to be used for collateralization
   * @param unusedCollateral Unused collateral of the pool
   */
  function calculateUnusedCollateral(
    ISynthereumLiquidityPoolStorage.Storage storage self,
    FixedPoint.Unsigned memory totalCollateral,
    FixedPoint.Unsigned memory totalFees,
    FixedPoint.Unsigned memory collateralReceived
  ) internal view returns (FixedPoint.Unsigned memory unusedCollateral) {
    // Collateral available
    FixedPoint.Unsigned memory actualBalance =
      FixedPoint.Unsigned(self.collateralToken.balanceOf(address(this)));
    unusedCollateral = actualBalance.sub(
      totalCollateral.add(totalFees).add(collateralReceived)
    );
  }

  /**
   * @notice Retrun the on-chain oracle price for a pair
   * @param finder Synthereum finder
   * @param priceIdentifier Identifier of price pair
   * @return priceRate Latest rate of the pair
   */
  function getPriceFeedRate(ISynthereumFinder finder, bytes32 priceIdentifier)
    internal
    view
    returns (FixedPoint.Unsigned memory priceRate)
  {
    ISynthereumPriceFeed priceFeed =
      ISynthereumPriceFeed(
        finder.getImplementationAddress(SynthereumInterfaces.PriceFeed)
      );

    priceRate = FixedPoint.Unsigned(priceFeed.getLatestPrice(priceIdentifier));
  }

  /**
   * @notice Retrun the number of decimals of collateral token
   * @param collateralToken Collateral token contract
   * @return decimals number of decimals
   */
  function getCollateralDecimals(IStandardERC20 collateralToken)
    internal
    view
    returns (uint8 decimals)
  {
    decimals = collateralToken.decimals();
  }

  /**
   * @notice Calculate synthetic token amount starting from an amount of collateral
   * @param priceRate Price rate of the pair
   * @param collateralDecimals Number of decimals of the collateral
   * @param numTokens Amount of collateral from which you want to calculate synthetic token amount
   * @return numTokens Amount of tokens after on-chain oracle conversion
   */
  function calculateNumberOfTokens(
    FixedPoint.Unsigned memory priceRate,
    uint8 collateralDecimals,
    FixedPoint.Unsigned memory collateralAmount
  ) internal pure returns (FixedPoint.Unsigned memory numTokens) {
    numTokens = collateralAmount.mul(10**(18 - collateralDecimals)).div(
      priceRate
    );
  }

  /**
   * @notice Calculate collateral amount starting from an amount of synthtic token
   * @param priceRate Price rate of the pair
   * @param collateralDecimals Number of decimals of the collateral
   * @param numTokens Amount of synthetic tokens from which you want to calculate collateral amount
   * @return collateralAmount Amount of collateral after on-chain oracle conversion
   */
  function calculateCollateralAmount(
    FixedPoint.Unsigned memory priceRate,
    uint8 collateralDecimals,
    FixedPoint.Unsigned memory numTokens
  ) internal pure returns (FixedPoint.Unsigned memory collateralAmount) {
    collateralAmount = numTokens.mul(priceRate).div(
      10**(18 - collateralDecimals)
    );
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface IEmergencyShutdown {
  /**
   * @notice Shutdown the pool or self-minting-derivative in case of emergency
   * @notice Only Synthereum manager contract can call this function
   * @return timestamp Timestamp of emergency shutdown transaction
   * @return price Price of the pair at the moment of shutdown execution
   */
  function emergencyShutdown()
    external
    returns (uint256 timestamp, uint256 price);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

interface ISynthereumLiquidityPoolInteraction {
  /**
   * @notice Called by a source Pool's `exchange` function to mint destination tokens
   * @notice This functon can be called only by a pool registered in the PoolRegister contract
   * @param collateralAmount The amount of collateral to use from the source Pool
   * @param numTokens The number of new tokens to mint
   * @param recipient Recipient to which send synthetic token minted
   */
  function exchangeMint(
    uint256 collateralAmount,
    uint256 numTokens,
    address recipient
  ) external;

  /**
   * @notice Returns price identifier of the pool
   * @return identifier Price identifier
   */
  function getPriceFeedIdentifier() external view returns (bytes32 identifier);

  /**
   * @notice Return overcollateralization percentage from the storage
   * @return Overcollateralization percentage
   */
  function overCollateralization() external view returns (uint256);

  /**
   * @notice Returns the total amount of liquidity deposited in the pool, but nut used as collateral
   * @return Total available liquidity
   */
  function totalAvailableLiquidity() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {IERC20} from '../../../../@openzeppelin/contracts/token/ERC20/IERC20.sol';

/**
 * @title Provides interface with functions of SynthereumRegistry
 */

interface ISynthereumRegistry {
  /**
   * @notice Allow the deployer to register an element
   * @param syntheticTokenSymbol Symbol of the syntheticToken
   * @param collateralToken Collateral ERC20 token of the element deployed
   * @param version Version of the element deployed
   * @param element Address of the element deployed
   */
  function register(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version,
    address element
  ) external;

  /**
   * @notice Returns if a particular element exists or not
   * @param syntheticTokenSymbol Synthetic token symbol of the element
   * @param collateralToken ERC20 contract of collateral currency
   * @param version Version of the element
   * @param element Contract of the element to check
   * @return isElementDeployed Returns true if a particular element exists, otherwise false
   */
  function isDeployed(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version,
    address element
  ) external view returns (bool isElementDeployed);

  /**
   * @notice Returns all the elements with partcular symbol, collateral and version
   * @param syntheticTokenSymbol Synthetic token symbol of the element
   * @param collateralToken ERC20 contract of collateral currency
   * @param version Version of the element
   * @return List of all elements
   */
  function getElements(
    string calldata syntheticTokenSymbol,
    IERC20 collateralToken,
    uint8 version
  ) external view returns (address[] memory);

  /**
   * @notice Returns all the synthetic token symbol used
   * @return List of all synthetic token symbol
   */
  function getSyntheticTokens() external view returns (string[] memory);

  /**
   * @notice Returns all the versions used
   * @return List of all versions
   */
  function getVersions() external view returns (uint8[] memory);

  /**
   * @notice Returns all the collaterals used
   * @return List of all collaterals
   */
  function getCollaterals() external view returns (address[] memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {ISynthereumFinder} from './interfaces/IFinder.sol';
import {
  AccessControlEnumerable
} from '../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 * @title Provides addresses of contracts implementing certain interfaces.
 */
contract SynthereumFinder is ISynthereumFinder, AccessControlEnumerable {
  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------

  mapping(bytes32 => address) public interfacesImplemented;

  //----------------------------------------
  // Events
  //----------------------------------------

  event InterfaceImplementationChanged(
    bytes32 indexed interfaceName,
    address indexed newImplementationAddress
  );

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  //----------------------------------------
  // Constructors
  //----------------------------------------

  constructor(Roles memory roles) {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, roles.admin);
    _setupRole(MAINTAINER_ROLE, roles.maintainer);
  }

  //----------------------------------------
  // External view
  //----------------------------------------

  /**
   * @notice Updates the address of the contract that implements `interfaceName`.
   * @param interfaceName bytes32 of the interface name that is either changed or registered.
   * @param implementationAddress address of the implementation contract.
   */
  function changeImplementationAddress(
    bytes32 interfaceName,
    address implementationAddress
  ) external override onlyMaintainer {
    interfacesImplemented[interfaceName] = implementationAddress;

    emit InterfaceImplementationChanged(interfaceName, implementationAddress);
  }

  /**
   * @notice Gets the address of the contract that implements the given `interfaceName`.
   * @param interfaceName queried interface.
   * @return implementationAddress Address of the defined interface.
   */
  function getImplementationAddress(bytes32 interfaceName)
    external
    view
    override
    returns (address)
  {
    address implementationAddress = interfacesImplemented[interfaceName];
    require(implementationAddress != address(0x0), 'Implementation not found');
    return implementationAddress;
  }
}

// SPDX-License-Identifier: MIT

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
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
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

    struct Map {
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
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
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
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
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
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), errorMessage);
        return value;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
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
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
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
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
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
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
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
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {
  ISynthereumFactoryVersioning
} from './interfaces/IFactoryVersioning.sol';
import {
  EnumerableMap
} from '../../@openzeppelin/contracts/utils/structs/EnumerableMap.sol';
import {
  AccessControlEnumerable
} from '../../@openzeppelin/contracts/access/AccessControlEnumerable.sol';

/**
 * @title Provides addresses of different versions of pools factory and derivative factory
 */
contract SynthereumFactoryVersioning is
  ISynthereumFactoryVersioning,
  AccessControlEnumerable
{
  using EnumerableMap for EnumerableMap.UintToAddressMap;

  bytes32 public constant MAINTAINER_ROLE = keccak256('Maintainer');

  //Describe role structure
  struct Roles {
    address admin;
    address maintainer;
  }

  //----------------------------------------
  // Storage
  //----------------------------------------

  mapping(bytes32 => EnumerableMap.UintToAddressMap) private factories;

  //----------------------------------------
  // Events
  //----------------------------------------

  event AddFactory(
    bytes32 indexed factoryType,
    uint8 indexed version,
    address indexed factory
  );

  event SetFactory(
    bytes32 indexed factoryType,
    uint8 indexed version,
    address indexed factory
  );

  event RemoveFactory(
    bytes32 indexed factoryType,
    uint8 indexed version,
    address indexed factory
  );

  //----------------------------------------
  // Constructor
  //----------------------------------------
  constructor(Roles memory roles) {
    _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
    _setRoleAdmin(MAINTAINER_ROLE, DEFAULT_ADMIN_ROLE);
    _setupRole(DEFAULT_ADMIN_ROLE, roles.admin);
    _setupRole(MAINTAINER_ROLE, roles.maintainer);
  }

  //----------------------------------------
  // Modifiers
  //----------------------------------------

  modifier onlyMaintainer() {
    require(
      hasRole(MAINTAINER_ROLE, msg.sender),
      'Sender must be the maintainer'
    );
    _;
  }

  //----------------------------------------
  // External functions
  //----------------------------------------

  /** @notice Sets a Factory
   * @param factoryType Type of factory
   * @param version Version of the factory to be set
   * @param factory The pool factory address to be set
   */
  function setFactory(
    bytes32 factoryType,
    uint8 version,
    address factory
  ) external override onlyMaintainer {
    require(factory != address(0), 'Factory cannot be address 0');
    bool isNewVersion = factories[factoryType].set(version, factory);
    if (isNewVersion) {
      emit AddFactory(factoryType, version, factory);
    } else {
      emit SetFactory(factoryType, version, factory);
    }
  }

  /** @notice Removes a factory
   * @param factoryType The type of factory to be removed
   * @param version Version of the factory to be removed
   */
  function removeFactory(bytes32 factoryType, uint8 version)
    external
    override
    onlyMaintainer
  {
    EnumerableMap.UintToAddressMap storage selectedFactories =
      factories[factoryType];
    address factoryToRemove = selectedFactories.get(version);
    selectedFactories.remove(version);
    emit RemoveFactory(factoryType, version, factoryToRemove);
  }

  //----------------------------------------
  // External view functions
  //----------------------------------------

  /** @notice Gets a factory contract address
   * @param factoryType The type of factory to be checked
   * @param version Version of the factory to be checked
   * @return factory Address of the factory contract
   */
  function getFactoryVersion(bytes32 factoryType, uint8 version)
    external
    view
    override
    returns (address factory)
  {
    factory = factories[factoryType].get(version);
  }

  /** @notice Gets the number of factory versions for a specific type
   * @param factoryType The type of factory to be checked
   * @return numberOfVersions Total number of versions for a specific factory
   */
  function numberOfFactoryVersions(bytes32 factoryType)
    external
    view
    override
    returns (uint8 numberOfVersions)
  {
    numberOfVersions = uint8(factories[factoryType].length());
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**
 * @title Provides addresses of different versions of pools factory and derivative factory
 */
interface ISynthereumFactoryVersioning {
  /** @notice Sets a Factory
   * @param factoryType Type of factory
   * @param version Version of the factory to be set
   * @param factory The pool factory address to be set
   */
  function setFactory(
    bytes32 factoryType,
    uint8 version,
    address factory
  ) external;

  /** @notice Removes a factory
   * @param factoryType The type of factory to be removed
   * @param version Version of the factory to be removed
   */
  function removeFactory(bytes32 factoryType, uint8 version) external;

  /** @notice Gets a factory contract address
   * @param factoryType The type of factory to be checked
   * @param version Version of the factory to be checked
   * @return factory Address of the factory contract
   */
  function getFactoryVersion(bytes32 factoryType, uint8 version)
    external
    view
    returns (address factory);

  /** @notice Gets the number of factory versions for a specific type
   * @param factoryType The type of factory to be checked
   * @return numberOfVersions Total number of versions for a specific factory
   */
  function numberOfFactoryVersions(bytes32 factoryType)
    external
    view
    returns (uint8 numberOfVersions);
}