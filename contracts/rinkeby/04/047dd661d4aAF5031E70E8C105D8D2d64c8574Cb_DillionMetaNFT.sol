// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
// import "hardhat/console.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
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
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

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
    function getRoleMember(bytes32 role, uint256 index)
        external
        view
        returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
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
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
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
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
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
    function getRoleAdmin(bytes32 role)
        public
        view
        virtual
        override
        returns (bytes32)
    {
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
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
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
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
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
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
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
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
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
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
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
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
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
    function values(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
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
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
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
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
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
    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
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
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
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
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
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
    function values(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

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

/**
 * @dev Interface of the KIP13 standard as defined in the KIP.
 *
 * See - http://kips.klaytn.com/KIPs/kip-13-interface_query_standard
 */
interface IKIP13 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`.
     * See - http://kips.klaytn.com/KIPs/kip-13-interface_query_standard#how-interface-identifiers-are-defined
     * to learn more about how these ids are created.
     *
     * Requirements:
     *
     * - implementation of this function call must use less than 30 000 gas
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Implementation of the {IKIP13} interface.
 */
abstract contract KIP13 is IKIP13 {
    /**
     * @dev See {IKIP13-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IKIP13).interfaceId;
    }
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IKIP17 is IKIP13 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

/**
 * @title KIP-17 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://kips.klaytn.com/KIPs/kip-17#metadata-extension
 */
interface IKIP17Metadata is IKIP17 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

/**
 * @title KIP17 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from KIP17 asset contracts.
 */
interface IKIP17Receiver {
    /**
     * @dev Whenever an {IKIP17} `tokenId` token is transferred to this contract via {IKIP17-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IKIP17Receiver.onKIp17Received.selector`.
     */
    function onKIP17Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of https://kips.klaytn.com/KIPs/kip-17 Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {KIP17Enumerable}.
 */
contract KIP17 is Context, KIP13, IKIP17, IKIP17Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IKIP13-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(KIP13, IKIP13)
        returns (bool)
    {
        return
            interfaceId == type(IKIP17).interfaceId ||
            interfaceId == type(IKIP17Metadata).interfaceId ||
            KIP13.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IKIP17-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "KIP17: address zero is not a valid owner"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IKIP17-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "KIP17: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IKIP17Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IKIP17Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IKIP17Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "KIP17Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IKIP17-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = KIP17.ownerOf(tokenId);
        require(to != owner, "KIP17: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "KIP17: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IKIP17-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "KIP17: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IKIP17-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IKIP17-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IKIP17-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "KIP17: transfer caller is not owner nor approved"
        );

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IKIP17-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IKIP17-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "KIP17: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the KIP17/ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IKIP17Receiver-onKIP17Received}
     *   OR {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnKIP17Received(from, to, tokenId, _data) ||
                _checkOnERC721Received(from, to, tokenId, _data),
            "KIP17: transfer to non IKIP17Receiver/IERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "KIP17: operator query for nonexistent token"
        );
        address owner = KIP17.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IKIP17Receiver-onKIP17Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-KIP17-_safeMint-address-uint256-}[`_safeMint`], with an additional `_data` parameter which is
     * forwarded in {IKIP17Receiver-onKIP17Received} OR {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnKIP17Received(address(0), to, tokenId, _data) ||
                _checkOnERC721Received(address(0), to, tokenId, _data),
            "KIP17: transfer to non IKIP17Receiver/IERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "KIP17: mint to the zero address");
        require(!_exists(tokenId), "KIP17: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = KIP17.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            KIP17.ownerOf(tokenId) == from,
            "KIP17: transfer from incorrect owner"
        );
        require(to != address(0), "KIP17: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(KIP17.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "KIP17: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IKIP17Receiver-onKIP17Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnKIP17Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IKIP17Receiver(to).onKIP17Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IKIP17Receiver.onKIP17Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    return false;
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    return false;
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

/**
 * @title KIP-17 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://kips.klaytn.com/KIPs/kip-17#enumeration-extension
 */
interface IKIP17Enumerable is IKIP17 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);
}

/**
 * @dev This implements an optional extension of {KIP17} defined in the KIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract KIP17Enumerable is KIP17, IKIP17Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IKIP13-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IKIP13, KIP17)
        returns (bool)
    {
        return
            interfaceId == type(IKIP17Enumerable).interfaceId ||
            KIP17.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IKIP17Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < KIP17.balanceOf(owner),
            "KIP17Enumerable: owner index out of bounds"
        );
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IKIP17Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IKIP17Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < KIP17Enumerable.totalSupply(),
            "KIP17Enumerable: global index out of bounds"
        );
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = KIP17.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = KIP17.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is
    IAccessControlEnumerable,
    AccessControl
{
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControlEnumerable).interfaceId ||
            super.supportsInterface(interfaceId);
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
    function getRoleMember(bytes32 role, uint256 index)
        public
        view
        virtual
        override
        returns (address)
    {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account)
        internal
        virtual
        override
    {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account)
        internal
        virtual
        override
    {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

/**
 * @dev Minting extension of the KIP17 standard as defined in the KIP.
 * See https://kips.klaytn.com/KIPs/kip-17#minting-extension
 */
interface IKIP17Mintable {
    /**
     * @dev Creates `tokenId` token and assigns them to `account`
     * increasing the total supply.
     *
     * Requirements:
     *
     * - caller must have the {KIP7Mintable-MINTER_ROLE}
     *
     * Emits a {Transfer} event with 0X0 as the `from` account
     */
    function mint(address to, uint256 tokenId) external returns (bool);

    /**
     * @dev Check if `account` has the assigned Minter role via {AccessControl-hasRole}
     */
    function isMinter(address account) external view returns (bool);

    /**
     * @dev Assign the Minter role to `account` via {AccessControl-grantRole}
     *
     * Emits a {RoleGranted} event
     *
     * Requirements:
     *
     * - caller must have the {KIP7Mintable-MINTER_ROLE}
     */
    function addMinter(address account) external;

    /**
     * @dev Renounce the Minter role of the caller via {AccessControl-renounceRole}
     *
     * Emits a {RoleRevoked} event
     */
    function renounceMinter() external;
}

/**
 * @dev Extension of KIP17 that supports permissioned token minting
 * See https://kips.klaytn.com/KIPs/kip-17#minting-extension
 */
abstract contract KIP17Mintable is
    KIP17,
    AccessControlEnumerable,
    IKIP17Mintable
{
    bytes32 public constant MINTER_ROLE = keccak256("KIP17_MINTER_ROLE");

    /**
     * @dev Returns true if `interfaceId` is implemented and false otherwise
     *
     * See {IKIP13} and {IERC165}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(KIP17, AccessControlEnumerable)
        returns (bool)
    {
        return
            interfaceId == type(IKIP17Mintable).interfaceId ||
            KIP17.supportsInterface(interfaceId) ||
            AccessControlEnumerable.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IKIP17Mintable-mint}
     *
     * IMPORTANT: this uses _safeMint internally, please be aware that if you do not want this safety functionality, replace with _mint
     *
     * Emits a {Transfer} event with 0X0 as the `from` account
     */
    function mint(address to, uint256 tokenId)
        public
        virtual
        override
        onlyRole(MINTER_ROLE)
        returns (bool)
    {
        _safeMint(to, tokenId);
        return true;
    }

    /**
     * @dev See {IKIP17Mintable-isMinter}
     */
    function isMinter(address account) public view returns (bool) {
        return hasRole(MINTER_ROLE, account);
    }

    /**
     * @dev See {IKIP17Mintable-addMinter}
     *
     * Emits a {RoleGranted} event
     */
    function addMinter(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, account);
    }

    /**
     * @dev See {IKIP17Mintable-renounceMinter}
     *
     * Emits a {RoleRevoked} event
     */
    function renounceMinter() public {
        renounceRole(MINTER_ROLE, _msgSender());
    }
}

/**
 * @title KIP17 Non-Fungible Token Standard, optional burnable extension
 * @dev See https://kips.klaytn.com/KIPs/kip-17#burning-extension
 */
interface IKIP17Burnable {
    /**
     * @dev Destroys `tokenId` token
     *
     * Emits a {Transfer} event with the 0x0 address as `to`.
     */
    function burn(uint256 tokenId) external;
}

/**
 * @title KIP17 Burnable Token
 * @dev KIP17 Token that can be burned (destroyed).
 */
abstract contract KIP17Burnable is Context, KIP17, IKIP17Burnable {
    /**
     * @dev See {IKIP13-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IKIP17Burnable).interfaceId ||
            KIP17.supportsInterface(interfaceId);
    }

    /**
     * @dev Burns `tokenId`. See {KIP17-_burn}.
     *
     * Requirements:
     *
     * - The caller must be the current owner, an authorized operator, or the approved address for `tokenId`
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Burnable: caller is not owner nor approved"
        );
        _burn(tokenId);
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
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

/**
 * @dev Pausing extension of the KIP17 standard as defined in the KIP.
 * See https://kips.klaytn.com/KIPs/kip-17#enumeration-extension
 */
interface IKIP17Pausable {
    /**
     * @dev Returns true if the contract is paused, false otherwise
     */
    function paused() external view returns (bool);

    /**
     * @dev Pause any function which triggers {KIP17-_beforeTokenTransfer}
     *
     * Emits a {Paused} event.
     *
     * Requirements:
     *
     * - caller must have the {KIP17Pausable-PAUSER_ROLE}
     */
    function pause() external;

    /**
     * @dev Resume normal function from the paused state
     *
     * Emits a {Unpaused} event.
     *
     * Requirements:
     *
     * - caller must have the {KIP17Pausable-PAUSER_ROLE}
     */
    function unpause() external;

    /**
     * @dev Check if `account` has the assigned Pauser role via {AccessControl-hasRole}
     */
    function isPauser(address account) external view returns (bool);

    /**
     * @dev Assign the Pauser role to `account` via {AccessControl-grantRole}
     *
     * Requirements:
     *
     * - caller must have the {AccessControl-DEFAULT_ADMIN_ROLE}
     */
    function addPauser(address _account) external;

    /**
     * @dev Renounce the Pauser role of the caller via {AccessControl-renounceRole}
     */
    function renouncePauser() external;
}

/**
 * @dev KIP17 token with pausable token transfers, minting and burning.
 */
abstract contract KIP17Pausable is
    KIP17,
    Pausable,
    AccessControlEnumerable,
    IKIP17Pausable
{
    bytes32 public constant PAUSER_ROLE = keccak256("KIP17_PAUSER_ROLE");

    /**
     * @dev Returns true if `interfaceId` is implemented and false otherwise
     *
     * See {IKIP13} and {IERC165}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(KIP17, AccessControlEnumerable)
        returns (bool)
    {
        return
            interfaceId == type(IKIP17Pausable).interfaceId ||
            KIP17.supportsInterface(interfaceId) ||
            AccessControlEnumerable.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IKIP17Pausable-pause}
     *
     * Emits a {Paused} event.
     *
     * Requirements:
     *
     * - caller must have the {PAUSER_ROLE}
     */
    function pause() public override {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "KIP17Pausable: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev See {IKIP17Pausable-unpause}
     *
     * Emits a {Unpaused} event.
     *
     * Requirements:
     *
     * - caller must have the {PAUSER_ROLE}
     */
    function unpause() public override {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "KIP17Pausable: must have pauser role to unpause"
        );
        _unpause();
    }

    /**
     * @dev Returns true if the contract is paused, false otherwise
     */
    function paused()
        public
        view
        override(IKIP17Pausable, Pausable)
        returns (bool)
    {
        return super.paused();
    }

    /**
     * @dev Check if `account` has the assigned Pauser role via {AccessControl-hasRole}
     */
    function isPauser(address _account) public view returns (bool) {
        return hasRole(PAUSER_ROLE, _account);
    }

    /**
     * @dev See {IKIP17Pausable-addPauser}
     *
     * Emits a {RoleGranted} event
     *
     * Requirements:
     *
     * - caller must have the {AccessControl-DEFAULT_ADMIN_ROLE}
     */
    function addPauser(address _account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(PAUSER_ROLE, _account);
    }

    /**
     * @dev See {IKIP17Pausable-renouncePauser}
     *
     * Emits a {RoleRevoked} event
     */
    function renouncePauser() public {
        renounceRole(PAUSER_ROLE, msg.sender);
    }

    /**
     * @dev See {KIP17-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!paused(), "KIP17Pausable: token transfer while paused");
    }
}

/**
 * @dev Interface of the KIP7 standard as defined in the KIP.
 * See http://kips.klaytn.com/KIPs/kip-7-fungible_token
 */
interface IKIP7 {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
     * This value changes when {approve}, {transferFrom}, or {safeTransferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`
     * and passes `data` for {IKIP7Receiver-onKIP7Received} handler logic.
     *
     * Emits a {Transfer} event.
     */
    function safeTransfer(
        address recipient,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * @dev  Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Emits a {Transfer} event.
     */
    function safeTransfer(address recipient, uint256 amount) external;

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the {allowance} mechanism
     * and passes `data` for {IKIP7Receiver-onKIP7Received} handler logic.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the {allowance} mechanism.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
}

/**
 * @dev Extension of {KIP7} which exposes metadata functions.
 * See https://kips.klaytn.com/KIPs/kip-7#metadata-extension
 */
interface IKIP7Metadata is IKIP7 {
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

interface IKIP7Receiver {
    /**
     * @dev Whenever an {IKIP7} `amount` is transferred to this contract via {IKIP7-safeTransfer}
     * or {IKIP7-safeTransferFrom} by `operator` from `from`, this function is called.
     *
     * {onKIP7Received} must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IKIP7Receiver.onKIP7Received.selector`.
     */
    function onKIP7Received(
        address operator,
        address from,
        uint256 amount,
        bytes calldata _data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of the {IKIP7} interface.
 *
 * See http://kips.klaytn.com/KIPs/kip-7-fungible_token
 */
contract KIP7 is Context, KIP13, IKIP7, IKIP7Metadata {
    using Address for address;

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
     * @dev See {IKIP13-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(KIP13)
        returns (bool)
    {
        return
            interfaceId == type(IKIP7).interfaceId ||
            interfaceId == type(IKIP7Metadata).interfaceId ||
            KIP13.supportsInterface(interfaceId);
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
     * Ether and Wei. This is the value {KIP7} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IKIP7-balanceOf} and {IKIP7-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IKIP7-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IKIP7-balanceOf}.
     */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IKIP7-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IKIP7-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IKIP7-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IKIP7-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {KIP7}.
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
     * problems described in {IKIP7-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IKIP7-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            "KIP7: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev See {IKIP7-safeTransfer}.
     *
     * Emits a {Transfer} event
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     * - if `recipient` is a smart contract, it must implement {IKIP7Receiver}
     */
    function safeTransfer(address recipient, uint256 amount)
        public
        virtual
        override
    {
        address owner = _msgSender();
        _safeTransfer(owner, recipient, amount, "");
    }

    /**
     * @dev Same as {xref-KIP7-safeTransfer-address-uint256-}[`safeTransfer`], with an additional `_data` parameter which is
     * forwarded in {IKIP7Receiver-onKIP7Received} to contract recipients.
     *
     * Emits a {Transfer} event
     */
    function safeTransfer(
        address recipient,
        uint256 amount,
        bytes memory _data
    ) public virtual override {
        address owner = _msgSender();
        _safeTransfer(owner, recipient, amount, _data);
    }

    /**
     * @dev See {IKIP7-safeTransferFrom}.
     *
     * Emits a {Transfer} event
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the KIP. See the note at the beginning of {KIP7}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least `amount`.
     * - if `recipient` is a smart contract, it must implement {IKIP7Receiver}
     */
    function safeTransferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override {
        address spender = _msgSender();
        _spendAllowance(sender, spender, amount);
        _safeTransfer(sender, recipient, amount, "");
    }

    /**
     * @dev Same as {xref-KIP7-safeTransferFrom-address-uint256-}[`safeTransferFrom`], with an additional `_data` parameter which is
     * forwarded in {IKIP7Receiver-onKIP7Received} to contract recipients.
     *
     * Emits a {Transfer} event
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function safeTransferFrom(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory _data
    ) public virtual override {
        address spender = _msgSender();
        _spendAllowance(sender, spender, amount);
        _safeTransfer(sender, recipient, amount, _data);
    }

    /**
     * @dev Safely transfers `amout` token from `from` to `to`, checking first that contract recipients
     * are aware of the KIP7 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to` to be used
     * for additional KIP7 receiver handler logic
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - if `to` is a contract it must implement {IKIP7Receiver} and
     * - If `to` refers to a smart contract, it must implement {IKIP7Receiver}, which is called upon
     *   a safe transfer.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 amount,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, amount);
        require(
            _checkOnKIP7Received(from, to, amount, _data),
            "KIP7: transfer to non IKIP7Receiver implementer"
        );
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
        require(from != address(0), "KIP7: transfer from the zero address");
        require(to != address(0), "KIP7: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "KIP7: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /**
     * @dev Safely mints `amount` and transfers it to `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IKIP7Receiver-onKIP7Received},
     *   which is called upon a safe mint.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address account, uint256 amount) internal virtual {
        _safeMint(account, amount, "");
    }

    /**
     * @dev Same as {xref-KIP7-_safeMint-address-uint256-}[`_safeMint`], with an additional `_data` parameter which is
     * forwarded in {IKIP7Receiver-onKIP7Received} to contract recipients.
     */
    function _safeMint(
        address account,
        uint256 amount,
        bytes memory _data
    ) internal virtual {
        _mint(account, amount);
        require(
            _checkOnKIP7Received(address(0), account, amount, _data),
            "KIP7: transfer to non IKIP7Receiver implementer"
        );
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "KIP7: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Internal function to invoke {IKIP7Receiver-onKIP7Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of transfer token amount
     * @param to target address that will receive the tokens
     * @param amount uint256 value to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnKIP7Received(
        address from,
        address to,
        uint256 amount,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IKIP7Receiver(to).onKIP7Received(
                    _msgSender(),
                    from,
                    amount,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IKIP7Receiver.onKIP7Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("KIP7: transfer to non KIP7Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
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
        require(account != address(0), "KIP7: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "KIP7: burn amount exceeds balance");
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
        require(owner != address(0), "KIP7: approve from the zero address");
        require(spender != address(0), "KIP7: approve to the zero address");

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
            require(currentAllowance >= amount, "KIP7: insufficient allowance");
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
}

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf)
        internal
        pure
        returns (bytes32)
    {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b)
        private
        pure
        returns (bytes32 value)
    {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

contract DillionMetaNFT is
    Ownable,
    AccessControlEnumerable,
    KIP17Enumerable,
    KIP17Mintable,
    KIP17Burnable,
    KIP17Pausable
{
    using Counters for Counters.Counter;
    using Address for address;

    // Type declarations

    // State variables
    Counters.Counter private _tokenIdTracker; // Tracking token id counter
    string private _baseTokenURI; // BaseURI of NFT

    // Whitelist mint
    bool private _isWhitelistMintEnabled; // Status of whitelist mint feature. True is enabled, false is disable
    uint256 private _whitelistMintPrice; // Price user must pay when execute whitelist mint feature
    uint256 private _whitelistMaxAmount; // The maximum number of NFTs a user can own when execute whitelist mint feature
    mapping(address => bool) private _isWhitelistMinted; // address => bool
    bytes32 private _merkleRoot;

    // Public mint
    bool private _isPublicMintEnabled; // Status of public mint feature. True is enabled, false is disable
    uint256 private _publicMintPrice; // Price user must pay when execute public mint feature
    uint256 private _publicMaxAmount; // The maximum number of NFTs a user can own when execute public mint feature
    // To detect a bot attack, the last contract call block number for each wallet must be recorded.
    mapping(address => uint256) private _lastMintBlockNumber;
    uint256 private _antiBotBlock; // Interval block that user can call public mint feature

    uint256 private _blockStartMining; // All function related mint must be execute after this _blockStartMining
    uint256 private _saleAmount; // Max amount of NFT can mint on the entire system

    // Airdrop
    bool private _isAirdropEnabled; // Status of airdrop feature. True is enabled, false is disable

    // Change name
    address private _changeNameTokenPayable; // kip7 token address can be pay for change name feature
    uint256 private _changeNamePrice; // Price user must pay when execute change name feature
    mapping(uint256 => string) private _tokenNames; // token id => name
    mapping(string => bool) private _existsNames; // name => bool. Check name existed yet

    // withdraw
    address private _adminWallet; //  Admin wallet address for receive KLAY and KIP7

    // Events
    event SettingMintStartBlock(uint256 mintStartBlock);
    event SettingSaleAmount(uint256 saleAmount);
    event SettingPublicMintStatus(bool isEnabled);
    event SettingPublicMintInfo(uint256 mintPrice, uint256 maxAmount);
    event SetWhitelistMintStatus(bool isEnabled);
    event SetWhitelistMintInfo(uint256 price, uint256 maxAmount);
    event NameTokenPayableForChangeNameChanged(
        address oldToken,
        address newToken
    );
    event NameTokenChanged(uint256 tokenId, string newName);
    event PriceForChangeNameChanged(uint256 oldPrice, uint256 newPrice);
    event RegisterWhitelistMint(bytes32 merkleRoot);
    event SettingAirdropStatus(bool isEnabled);

    // Modifiers
    modifier isPublicMintEnabled() {
        require(_isPublicMintEnabled, "The public sale is not enabled!");
        _;
    }

    modifier isAfterBlockStart() {
        require(block.number >= _blockStartMining, "Not started yet");
        _;
    }

    modifier isNotExceedAmount(uint256 amount) {
        require(
            _tokenIdTracker.current() + amount <= _saleAmount + 1,
            "Exceed max amount"
        );
        _;
    }

    modifier isAirdropEnabled() {
        require(_isAirdropEnabled, "The airdrop feature is not enabled!");
        _;
    }

    /**
     * @dev Initializes the contract with setting info below:
     * @param name of NFT
     * @param symbol of NFT
     * @param _uri is baseURL of token
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory _uri
    ) KIP17(name, symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());

        _baseTokenURI = _uri;
        _antiBotBlock = 1;
        _tokenIdTracker.increment(); // token id starts from 1
        _adminWallet = _msgSender();
    }

    /**
     * @dev Base URI for computing {tokenURI}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "KIP17Metadata: URI query for nonexistent token"
        );

        string memory baseURI_ = _baseURI();
        return
            bytes(baseURI_).length > 0
                ? string(
                    abi.encodePacked(
                        baseURI_,
                        Strings.toString(tokenId),
                        ".json"
                    )
                )
                : "";
    }

    /**
     * @dev Set baseURI for NFT.
     * @param newBaseTokenURI : new baseURL
     */
    function setBaseURI(string calldata newBaseTokenURI)
        external
        onlyRole(MINTER_ROLE)
    {
        _baseTokenURI = newBaseTokenURI;
    }

    /**
     * @dev Base URI for computing {tokenURI}.
     * If set, the resulting URI for each token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function baseURI() public view returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev See {IKIP13-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            AccessControlEnumerable,
            KIP17Burnable,
            KIP17Mintable,
            KIP17Pausable,
            KIP17Enumerable
        )
        returns (bool)
    {
        return
            AccessControlEnumerable.supportsInterface(interfaceId) ||
            KIP17Burnable.supportsInterface(interfaceId) ||
            KIP17Mintable.supportsInterface(interfaceId) ||
            KIP17Pausable.supportsInterface(interfaceId) ||
            KIP17Enumerable.supportsInterface(interfaceId);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning.
     * @param from: from
     * @param to: to
     * @param tokenId: tokenId
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(KIP17, KIP17Enumerable, KIP17Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Setting status of whitelist mint function
     * @param isEnabled: true is enable and false is disable
     * Emits a {SetWhitelistMintStatus} event.
     */
    function setWhitelistMintStatus(bool isEnabled)
        external
        onlyRole(MINTER_ROLE)
    {
        require(
            isEnabled != _isWhitelistMintEnabled,
            "Same current whitelist mint status"
        );

        _isWhitelistMintEnabled = isEnabled;

        emit SetWhitelistMintStatus(isEnabled);
    }

    /**
     * @dev Get status of whitelist mint function
     * @return bool: whitelist mint function status (enable/disable)
     */
    function getWhitelistMintStatus() external view returns (bool) {
        return _isWhitelistMintEnabled;
    }

    /**
     * @dev Setting info of whitelist mint function
     * @param price: Fee amount to be paid when mint
     * @param maxAmount: Max amount allow for each mint
     * Emits a {SetWhitelistMintInfo} event.
     */
    function setWhitelistMintInfo(uint256 price, uint256 maxAmount)
        external
        onlyRole(MINTER_ROLE)
    {
        require(
            price != _whitelistMintPrice || maxAmount != _whitelistMaxAmount,
            "Same current whitelist info setting"
        );

        require(maxAmount > 0, "Max amount must > 0");

        _whitelistMintPrice = price;
        _whitelistMaxAmount = maxAmount;

        emit SetWhitelistMintInfo(price, maxAmount);
    }

    /**
     * @dev Get information of whitelist mint function
     * @return price and maxAmount for each mint
     */
    function getWhitelistMintInfo() external view returns (uint256, uint256) {
        return (_whitelistMintPrice, _whitelistMaxAmount);
    }

    /**
     * @dev Setting merkle root
     * @param merkleRoot: new merkle root
     * Emits a {RegisterWhitelistMint} event.
     */
    function registerWhitelistMint(bytes32 merkleRoot)
        external
        onlyRole(MINTER_ROLE)
    {
        require(
            merkleRoot != bytes32(0) && merkleRoot != _merkleRoot,
            "Zero merkle root or same with current merkle root"
        );

        _merkleRoot = merkleRoot;

        emit RegisterWhitelistMint(merkleRoot);
    }

    /**
     * @dev Get current merkle root
     */
    function getMerkleRoot() external view returns (bytes32) {
        return _merkleRoot;
    }

    /**
     * @dev Whitelist mint
     * @param amount: amount nft
     * @param merkleProof: merkle proof of user
     */
    function userWhitelistMint(uint256 amount, bytes32[] calldata merkleProof)
        external
        payable
    {
        require(_isWhitelistMintEnabled, "Whitelist mint is not enabled");
        require(block.number >= _blockStartMining, "Not started yet");
        require(_merkleRoot != bytes32(0), "Not set merkle root");
        require(
            amount > 0 && amount <= _whitelistMaxAmount,
            "Too many requests or zero request"
        );
        require(msg.value == _whitelistMintPrice * amount, "Not enough KLAY");
        require(
            _tokenIdTracker.current() + amount <= _saleAmount + 1,
            "Exceed sale amount"
        );
        require(!_isWhitelistMinted[_msgSender()], "User already minted");
        require(isValidProof(_msgSender(), merkleProof), "Invalid proof");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(_msgSender(), _tokenIdTracker.current());
            _tokenIdTracker.increment();
        }

        _isWhitelistMinted[_msgSender()] = true;
    }

    function isWhitelist(address user, bytes32[] calldata merkleProof)
        external
        view
        returns (bool)
    {
        return isValidProof(user, merkleProof);
    }

    function isValidProof(address user, bytes32[] calldata merkleProof)
        internal
        view
        returns (bool)
    {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(merkleProof, _merkleRoot, leaf);
    }

    function isUserWhitelistMinted(address user) external view returns (bool) {
        return _isWhitelistMinted[user];
    }

    /**
     * @dev Setting status of public mint function
     * @param isEnabled: true is enable and false is disable
     * Emits a {SettingPublicMintStatus} event.
     */
    function setPublicMintStatus(bool isEnabled)
        external
        onlyRole(MINTER_ROLE)
    {
        require(
            _isPublicMintEnabled != isEnabled,
            "New public mint status must be different current public mint status"
        );

        _isPublicMintEnabled = isEnabled;

        emit SettingPublicMintStatus(isEnabled);
    }

    /**
     * @dev Get status of public mint function
     * @return bool: public mint function status (enable/disable)
     */
    function getPublicMintStatus() public view returns (bool) {
        return _isPublicMintEnabled;
    }

    /**
     * @dev Setting info of public mint function
     * @param price: Fee amount to be paid when mint
     * @param maxAmount: Max amount allow for each mint
     * Emits a {SettingPublicMintInfo} event.
     */
    function setPublicMintInfo(uint256 price, uint256 maxAmount)
        external
        onlyRole(MINTER_ROLE)
    {
        require(
            _publicMintPrice != price || _publicMaxAmount != maxAmount,
            "New public mint info must be different current public mint info"
        );
        require(
            maxAmount > 0,
            "Public max amount for each mint request must be greater than 0"
        );

        _publicMintPrice = price;
        _publicMaxAmount = maxAmount;

        emit SettingPublicMintInfo(price, maxAmount);
    }

    function setAntiBotBlock(uint256 numOfBlock)
        external
        onlyRole(MINTER_ROLE)
    {
        require(numOfBlock > 0, "Anti bot interval must be greater than 0");
        _antiBotBlock = numOfBlock;
    }

    function getAntiBotBlock() public view returns (uint256) {
        return _antiBotBlock;
    }

    /**
     * @dev Get information of public mint function
     * @return price and maxAmount for each mint
     */
    function getPublicMintInfo() public view returns (uint256, uint256) {
        return (_publicMintPrice, _publicMaxAmount);
    }

    function getLastMintBlockNumber(address userWallet)
        public
        view
        returns (uint256)
    {
        return _lastMintBlockNumber[userWallet];
    }

    /**
     * @dev Public mint feature
     * @param amount : amount of nft want to mint
     */
    function userPublicMint(uint256 amount)
        external
        payable
        isPublicMintEnabled
        isAfterBlockStart
        isNotExceedAmount(amount)
    {
        require(
            amount > 0 && amount <= _publicMaxAmount,
            "Too many requests or zero request"
        );
        require(msg.value == _publicMintPrice * amount, "Not enough KLAY");
        require(
            _lastMintBlockNumber[_msgSender()] + _antiBotBlock < block.number,
            "Detect and prevent BOT"
        );

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(_msgSender(), _tokenIdTracker.current());
            _tokenIdTracker.increment();
        }
        _lastMintBlockNumber[_msgSender()] = block.number;
    }

    /**
     * @dev Setting block start mint. All request mint must be do after this block number
     * @param blockNumber : blockNumber
     * Emits a {SettingMintStartBlock} event.
     */
    function setBlockStartMining(uint256 blockNumber)
        external
        onlyRole(MINTER_ROLE)
    {
        require(
            _blockStartMining != blockNumber,
            "New mint start block must be different current mint start block"
        );
        require(
            block.number < blockNumber,
            "Block start mining must be greater than current block"
        );

        _blockStartMining = blockNumber;

        emit SettingMintStartBlock(blockNumber);
    }

    /**
     * @dev Get block start mining
     * @return number: Block number can be start mining
     */
    function getBlockStartMining() public view returns (uint256) {
        return _blockStartMining;
    }

    /**
     * @dev Setting sale amount for mint. It is max amount of NFT allow mint
     * @param saleAmount : max amount of NFT allow mint
     * Emits a {SettingSaleAmount} event.
     */
    function setSaleAmount(uint256 saleAmount) external onlyRole(MINTER_ROLE) {
        require(
            _saleAmount != saleAmount,
            "New sale amount must be different current sale amount"
        );
        require(
            _tokenIdTracker.current() <= saleAmount,
            "New sale amount must be greater than amount of minted token"
        );

        _saleAmount = saleAmount;

        emit SettingSaleAmount(saleAmount);
    }

    /**
     * @dev Get sale amount
     * @return The number of NFTs allow for mint
     */
    function getSaleAmount() public view returns (uint256) {
        return _saleAmount;
    }

    /**
     * @dev Get current tokenIdTracker (counter of tokenId)
     * @return _tokenIdTracker
     */
    function getTokenIdTracker() public view returns (uint256) {
        return _tokenIdTracker.current();
    }

    // airdrop
    /**
     * @dev Setting status of airdrop function
     * @param isEnabled: true is enable and false is disable
     * Emits a {SettingAirdropStatus} event.
     */
    function setAirdropStatus(bool isEnabled) external onlyRole(MINTER_ROLE) {
        require(
            _isAirdropEnabled != isEnabled,
            "New airdrop status must be different current airdrop status"
        );

        _isAirdropEnabled = isEnabled;

        emit SettingAirdropStatus(isEnabled);
    }

    /**
     * @dev Get status of airdrop function
     * @return bool: airdrop status (enable/disable)
     */
    function getAirdropStatus() public view returns (bool) {
        return _isAirdropEnabled;
    }

    function airdrop(address userWallet, uint256 amount)
        external
        onlyRole(MINTER_ROLE)
        isAirdropEnabled
        isNotExceedAmount(amount)
    {
        require(amount > 0, "Amount must be greater than 0");

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(userWallet, _tokenIdTracker.current());
            _tokenIdTracker.increment();
        }
    }

    /**
     * @dev Get KIP7 token
     */
    function getKIP7Token() external view returns (address) {
        return _changeNameTokenPayable;
    }

    /**
     * @dev Set KIP7 token
     * @param tokenAddress KIP7 token address
     * Emits a {NameTokenPayableForChangeNameChanged} event
     */
    function setKIP7Token(address tokenAddress) external onlyRole(MINTER_ROLE) {
        bytes memory result = tokenAddress.functionCall(
            abi.encodeWithSignature(
                "supportsInterface(bytes4)",
                type(IKIP7).interfaceId
            )
        );

        bool isSupported = abi.decode(result, (bool));
        require(isSupported, "New token's type must be KIP7");

        address oldToken = _changeNameTokenPayable;
        require(
            oldToken != tokenAddress,
            "New token must be different old token"
        );

        if (_changeNameTokenPayable != address(0)) {
            uint256 kip7Balance = IKIP7(_changeNameTokenPayable).balanceOf(
                address(this)
            );

            if (kip7Balance > 0) {
                IKIP7(_changeNameTokenPayable).transfer(
                    _adminWallet,
                    kip7Balance
                );
            }
        }

        _changeNameTokenPayable = tokenAddress;

        emit NameTokenPayableForChangeNameChanged(
            oldToken,
            _changeNameTokenPayable
        );
    }

    /**
     * @dev Get admin wallet
     */
    function getAdminWallet() external view returns (address) {
        return _adminWallet;
    }

    /**
     * @dev Set admin wallet
     * @param newAddress new admin wallet address
     */
    function setAdminWallet(address newAddress) external onlyRole(MINTER_ROLE) {
        _adminWallet = newAddress;
    }

    /**
     * @dev Get change name price
     */
    function getChangeNamePrice() external view returns (uint256) {
        return _changeNamePrice;
    }

    /**
     * @dev Set change name price
     * @param newPrice new change name price
     * Emits a {PriceForChangeNameChanged} event
     */
    function setChangeNamePrice(uint256 newPrice)
        external
        onlyRole(MINTER_ROLE)
    {
        uint256 oldPrice = _changeNamePrice;
        require(oldPrice != newPrice, "New Price must be different old price");

        _changeNamePrice = newPrice;

        emit PriceForChangeNameChanged(oldPrice, _changeNamePrice);
    }

    /**
     * @dev Get token name by token id
     */
    function getNameByTokenId(uint256 tokenId)
        external
        view
        returns (string memory)
    {
        return _tokenNames[tokenId];
    }

    /**
     * @dev Change name of token
     * @param tokenId token id
     * @param newName token name
     * Emit a {NameTokenChanged} event
     */
    function changeName(uint256 tokenId, string memory newName) external {
        require(_msgSender() == ownerOf(tokenId), "Caller is not the owner");
        require(validateName(newName), "Not a valid new name");
        require(
            sha256(bytes(newName)) != sha256(bytes(_tokenNames[tokenId])),
            "New name is same as the current one"
        );
        require(!isNameExisted(newName), "Name is already existed");
        require(
            _changeNameTokenPayable != address(0),
            "KIP7 token hasn't been setted"
        );

        // kip7
        IKIP7(_changeNameTokenPayable).transferFrom(
            _msgSender(),
            address(this),
            _changeNamePrice
        );

        // change name
        if (bytes(_tokenNames[tokenId]).length > 0) {
            toggleNameExisted(_tokenNames[tokenId], false);
        }

        toggleNameExisted(newName, true);
        _tokenNames[tokenId] = newName;

        emit NameTokenChanged(tokenId, newName);
    }

    function isNameExisted(string memory name) public view returns (bool) {
        return _existsNames[toLower(name)];
    }

    function toggleNameExisted(string memory str, bool isExisted) internal {
        _existsNames[toLower(str)] = isExisted;
    }

    /**
     * @dev Check a name is valid
     */
    function validateName(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 25) return false;
        if (b[0] == 0x20) return false;
        if (b[b.length - 1] == 0x20) return false;

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];
            if (
                !(char >= 0x30 && char <= 0x39) &&
                !(char >= 0x41 && char <= 0x5A) &&
                !(char >= 0x61 && char <= 0x7A) &&
                !(char == 0x20)
            ) {
                return false;
            }
        }
        return true;
    }

    function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    /**
     * @dev Withdraw KLAY to admin wallet
     */
    function withdraw() external onlyRole(MINTER_ROLE) {
        uint256 balance = address(this).balance;
        require(balance > 0, "Nothing to claim");

        payable(_adminWallet).transfer(balance);
    }

    /**
     * @dev Withdraw KIP7 token to admin wallet
     */
    function withdrawKIP7() external onlyRole(MINTER_ROLE) {
        require(
            _changeNameTokenPayable != address(0),
            "KIP7 token not setting"
        );

        uint256 kip7Balance = IKIP7(_changeNameTokenPayable).balanceOf(
            address(this)
        );
        require(kip7Balance > 0, "Nothing to claim");

        IKIP7(_changeNameTokenPayable).transfer(_adminWallet, kip7Balance);
    }
}