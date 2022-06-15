/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// Dependency file: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol

// SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// Dependency file: @openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol


// pragma solidity ^0.8.0;
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}


// Dependency file: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


// pragma solidity ^0.8.0;
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


// Dependency file: @openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}


// Dependency file: @openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}


// Dependency file: @openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

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
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
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
        _checkRole(role, _msgSender());
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
    uint256[49] private __gap;
}


// Dependency file: @openzeppelin/contracts/utils/structs/EnumerableSet.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/math/SafeMath.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

// pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}


// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/utils/Address.sol


// pragma solidity ^0.8.0;

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


// Dependency file: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "@openzeppelin/contracts/utils/Address.sol";

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


// Dependency file: contracts/traits/TransferHelpers.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TransferHelpers {
    using SafeERC20 for IERC20;

    function _deliverFunds(
        address _recipient,
        uint256 _value,
        string memory _message
    ) internal virtual {
        if (_value > address(this).balance) {
            _value = address(this).balance;
        }
        (bool sent, ) = payable(_recipient).call{value: _value}("");

        require(sent, _message);
    }

    function _safeApprove(
        address _token,
        address _spender,
        uint256 _amount
    ) internal virtual {
        require(_token != address(0x0), "Transfer Helpers: token address is zero");

        IERC20(_token).safeApprove(_spender, _amount);
    }

    function _safeTransfer(
        address _token,
        address _recipient,
        uint256 _amount
    ) internal virtual {
        require(_token != address(0x0), "Transfer Helpers: token address is zero");
        require(_amount > 0, "Transfer Helpers: amount cannot be zero");

        if (_amount > IERC20(_token).balanceOf(address(this))) {
            _amount = IERC20(_token).balanceOf(address(this));
        }

        IERC20(_token).safeTransfer(_recipient, _amount);
    }

    function _safeTransferAll(address _token, address _recipient) internal virtual returns (uint256 amount) {
        amount = IERC20(_token).balanceOf(address(this));

        if (amount > 0) {
            _safeTransfer(_token, _recipient, amount);
        }
    }

    function _safeTransferFrom(
        address _token,
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal virtual {
        require(_token != address(0x0), "Transfer Helpers: token address is zero");
        require(_amount > 0, "Transfer Helpers: amount cannot be zero");

        IERC20(_token).safeTransferFrom(_sender, _recipient, _amount);
    }
}


// Dependency file: contracts/interfaces/ITestSettings.sol


// pragma solidity ^0.8.0;

interface ITestSettings {
    function getBaseFee() external view returns (uint256);

    function getMaxIDOLength() external view returns (uint256);

    function getLockerFee() external view returns (uint256);

    function getLiquidityFee() external view returns (uint256);

    function getFeeRecipient() external view returns (address payable);

    function getMinLockLength() external view returns(uint256);
}


// Dependency file: contracts/interfaces/ITestRegistry.sol


// pragma solidity ^0.8.0;

interface ITestRegistry {
    function registerIDO(address _idoAddress, address _idoOwner) external;

    function isRegistered(address _idoAddress) external view returns (bool);
}


// Dependency file: contracts/interfaces/ITestLockForwarder.sol


// pragma solidity ^0.8.0;

interface ITestLockForwarder {
    function pairIsInitialised(address _token0, address _token1) external view returns (bool);

    function lockLiquidity(
        address _baseToken,
        address _saleToken,
        uint256 _baseAmount,
        uint256 _saleAmount,
        uint256 _unlockBlock,
        address _withdrawer,
        bool _isVestingEnabled,
        uint256 _cliffBlock
    ) external payable;
}


// Dependency file: contracts/interfaces/IERC20Decimals.sol


// pragma solidity ^0.8.0;

interface IERC20Decimals {
    function decimals() external view returns (uint8);
}


// Dependency file: contracts/interfaces/IWETH.sol


// pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}


// Dependency file: contracts/libraries/TestLibrary.sol


// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library TestLibrary {
    using SafeMath for uint256;

    enum IDO_STATUS {
        QUED,
        ACTIVE,
        SUCCESS,
        FAILED,
        FORCE_FAILED,
        LP_GENERATION_COMPLETE
    }

    struct IDOInfo {
        address baseToken; //base token, for native use 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
        address saleToken; // sale token
        uint256 tokenRate; // token rate
        uint256 amount; // amount for sale
        uint256 hardCap; //hardcap
        uint256 softCap; //softcap
        uint256 liquidityPercent; // divided by 10000
        uint256 listingRate; //listing rate
        uint256 startTime; //start time
        uint256 endTime; //end time
        uint256 lockPeriod; //lock period
        bool isVestingEnabled; // with vesting or no
        uint256 cliffPeriod; //cliff period
    }

    struct IDOUserLimits {
        uint256 minSpendPerBuyer; //max tx
        uint256 maxSpendPerBuyer;  //min tx
    }

    struct IDOStatus {
        bool lpGenerationComplete; // final flag required to end a presale and enable withdrawls
        bool forceFailed; // set this flag to force fail the presale
        bool whiteListOnly; // if set to true only whitelisted members may participate
        uint256 totalBaseCollected;
        uint256 totalTokenSold; // total ido tokens sold
        uint256 totalTokensWithdrawn; //total tokens withdrawan after successful ido
        uint256 totalBaseWithdrawn; // total base tokens withdrawn on ido failure
        uint256 numBuyers; // number of unique participants
    }

    struct BuyerInfo {
        uint256 baseDeposited; // total base token (usually ETH) deposited by user, can be withdrawn on presale failure
        uint256 tokensOwed; // num presale tokens a user is owed, can be withdrawn on presale success
    }

    struct IDOSettings {
        bool isBurnableRestTokens;
        bool lockTokens;
        bool whitelistOnly;
        bool kycRequired;
        bool verificationRequired;
    }

    function calculateAmountRequired(
        uint256 _amount,
        uint256 _tokenRate,
        uint256 _listingRate,
        uint256 _liquidityPercent
    ) internal pure returns (uint256) {
        uint256 listingRatePercent = _listingRate.mul(10**4).div(_tokenRate);
        uint256 liquidityRequired = _amount.mul(_liquidityPercent).mul(listingRatePercent).div(100000000);
        uint256 tokensRequiredForPresale = _amount.add(liquidityRequired);
        return tokensRequiredForPresale;
    }
}


// Root file: contracts/Test.sol


pragma solidity ^0.8.0;

// import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
// import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
// import "contracts/traits/TransferHelpers.sol";
// import "contracts/interfaces/ITestSettings.sol";
// import "contracts/interfaces/ITestRegistry.sol";
// import "contracts/interfaces/ITestLockForwarder.sol";
// import "contracts/interfaces/IERC20Decimals.sol";
// import "contracts/interfaces/IWETH.sol";
// import "contracts/libraries/TestLibrary.sol";


///@notice IDO, main contract
///@dev have access control system, two roles: admin (platfrom admin) and owner (ido owner)
contract Test is AccessControlUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable, TransferHelpers {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    bytes32 public constant IDO_OWNER_ROLE = keccak256("IDO_OWNER_ROLE");
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    address public devAddress;
    address public idoOwner;

    ITestLockForwarder public lockForwarder;
    ITestSettings public settings;
    ITestRegistry public registry;

    IWETH public weth;

    TestLibrary.IDOInfo public idoInfo;
    TestLibrary.IDOStatus public idoStatus;
    TestLibrary.IDOUserLimits public userLimits;

    mapping(address => TestLibrary.BuyerInfo) public buyers;

    bool public isNativeTokenUsed;

    bool public isBurnableRestTokens;

    EnumerableSet.AddressSet private whitelist;


    string public cid;

    bool kycRequired;
    bool verificationRequired;
    bool kycVerified;
    bool verified;

    modifier onlyOwnerOrAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) || hasRole(IDO_OWNER_ROLE, _msgSender()), "IDO: caller is not admin or owner");
        _;
    }

    event UpdateIDOOwner(address _owner);
    event UpdateLockForwarder(address _lockForwarder);
    event UpdateRegistry(address _registry);
    event UpdateWETH(address _weth);
    event UpdateSettings(address _settings);

    event UpdateUserLimits(uint256 minSpendPerBuyer, uint256 maxSpendPerBuyer);
    event UpdateTimes(uint256 _startTime, uint256 _endTime);
    event UpdateLockPeriod(uint256 _lockPeriod);
    event setIsBurnableRestTokens(bool isBurnableRestTokens);
    event setIsVestingEnabled(bool isVestingEnabled, uint256 cliffPeriod);

    event EmergencyWithdraw(address token, address recipient, uint256 amount);
    event EmergencyWithdrawNative(address recipient, uint256 amount);


    event Deposit(address buyer, uint256 amount);
    event Claim(address buyer, uint256 amount);
    event ForceFail();
    event Refunded(address buyer, uint256 amount);
    event Finalized();

    event UpdateWhitelistFlag(bool flag);
    event UpdateCidPath(string cid);

    event UpdateKycVerified(bool kycVerified);
    event UpdateVerified(bool verified);

    /// @notice initialize contract
    /// @param _registry registry address
    /// @param _weth wrapped native token address
    /// @param _settings settings address
    /// @param _lockForwarder lock forwarder address
    /// @param _devAddress admin address
    /// @param _owner ido owner
    /// @param _idoInfo struct as format IDOInfo, see TestLibrary
    /// @param _userLimits struct as format IDOUserLimits, see TestLibrary
    /// @param _idoSettings struct as format of IDOSettings

    function initialize(
        ITestRegistry _registry,
        IWETH _weth,
        ITestSettings _settings,
        ITestLockForwarder _lockForwarder,
        address _devAddress,
        address _owner,
        TestLibrary.IDOInfo memory _idoInfo,
        TestLibrary.IDOUserLimits memory _userLimits,
        TestLibrary.IDOSettings memory _idoSettings
    ) public initializer {
        // basic parameters

        registry = _registry;
        weth = _weth;
        settings = _settings;
        lockForwarder = _lockForwarder;
        devAddress = _devAddress;

        //info
        idoInfo = _idoInfo;

        // limits

        userLimits = _userLimits;

        //additional

        isNativeTokenUsed = _idoInfo.baseToken == ETH_ADDRESS ? true : false;
        isBurnableRestTokens = _idoSettings.isBurnableRestTokens;

        AccessControlUpgradeable.__AccessControl_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        PausableUpgradeable.__Pausable_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _devAddress);
        _setupRole(IDO_OWNER_ROLE, _owner);

        idoOwner = _owner;

        idoStatus.whiteListOnly = _idoSettings.whitelistOnly;

        kycRequired = _idoSettings.kycRequired;
        verificationRequired = _idoSettings.verificationRequired;

    }

    function status() public view returns (TestLibrary.IDO_STATUS) {
        if (idoStatus.lpGenerationComplete) {
            return TestLibrary.IDO_STATUS.LP_GENERATION_COMPLETE;
        }
        if (idoStatus.forceFailed) {
            return TestLibrary.IDO_STATUS.FORCE_FAILED; // FAILED - force fail
        }
        if ((block.timestamp > idoInfo.endTime) && (idoStatus.totalBaseCollected < idoInfo.softCap)) {
            return TestLibrary.IDO_STATUS.FAILED; // FAILED - softcap not met by end time
        }

        if (idoStatus.totalBaseCollected >= idoInfo.hardCap) {
            return TestLibrary.IDO_STATUS.SUCCESS; // SUCCESS - hardcap met
        }
        if ((block.timestamp > idoInfo.endTime) && (idoStatus.totalBaseCollected >= idoInfo.softCap)) {
            return TestLibrary.IDO_STATUS.SUCCESS; // SUCCESS - endTime and soft cap reached
        }
        if ((block.timestamp >= idoInfo.startTime) && (block.timestamp <= idoInfo.endTime)) {
            return TestLibrary.IDO_STATUS.ACTIVE; // ACTIVE - deposits enabled
        }
        return TestLibrary.IDO_STATUS.QUED; // QUED - awaiting start time
    }

    /// @notice force fail ido
    /// from admin or owner
    function forceFail() external onlyOwnerOrAdmin {
        idoStatus.forceFailed = true;

        emit ForceFail();
    }

    /// @notice deposit base tokens to ido
    /// @param _amount. If base tokens, BNB or ETH, can be 0.  amount will be taken from value
    /// @dev support token ERC20 or native (BNB/ETH)
    function deposit(uint256 _amount) external payable nonReentrant whenNotPaused {
        require(status() == TestLibrary.IDO_STATUS.ACTIVE, "IDO: not active"); // ACTIVE

        if (idoStatus.whiteListOnly) {
            require(whitelist.contains(_msgSender()), "IDO: caller is not whitelisted");
        }

        TestLibrary.BuyerInfo storage buyer = buyers[_msgSender()];

        uint256 amountIn = isNativeTokenUsed ? msg.value : _amount;

        require(amountIn >= userLimits.minSpendPerBuyer && amountIn <= userLimits.maxSpendPerBuyer, "IDO: min and max amount required");

        uint256 allowance = userLimits.maxSpendPerBuyer <= buyer.baseDeposited ? 0 : userLimits.maxSpendPerBuyer.sub(buyer.baseDeposited);

        require(allowance > 0, "IDO: max spend balance reached");

        uint256 remaining = idoInfo.hardCap.sub(idoStatus.totalBaseCollected);

        require(remaining > 0, "IDO: hardcap reached");

        allowance = allowance > remaining ? remaining : allowance;

        if (amountIn > allowance) {
            amountIn = allowance;
        }

        uint256 tokensSold = isNativeTokenUsed
            ? amountIn.mul(idoInfo.tokenRate).div(10**18)
            : amountIn.mul(idoInfo.tokenRate).div(10**uint256(IERC20Decimals(idoInfo.baseToken).decimals()));

        require(tokensSold > 0, "IDO: zero tokens");

        if (buyer.baseDeposited == 0) {
            idoStatus.numBuyers = idoStatus.numBuyers + 1;
        }

        buyer.baseDeposited = buyer.baseDeposited.add(amountIn);
        buyer.tokensOwed = buyer.tokensOwed.add(tokensSold);
        idoStatus.totalBaseCollected = idoStatus.totalBaseCollected.add(amountIn);
        idoStatus.totalTokenSold = idoStatus.totalTokenSold.add(tokensSold);

        if (isNativeTokenUsed && amountIn < msg.value) {
            _deliverFunds(_msgSender(), msg.value.sub(amountIn), "IDO: cannnot send");
        }

        if (!isNativeTokenUsed) {
            _safeTransferFrom(idoInfo.baseToken, _msgSender(), address(this), amountIn);
        }

        emit Deposit(_msgSender(), amountIn);
    }

    /// @notice claim sale tokens
    /// @dev only after ido successful and finalized
    function claim() external nonReentrant whenNotPaused {
        require(status() == TestLibrary.IDO_STATUS.LP_GENERATION_COMPLETE, "IDO: awaiting lp generation");
        TestLibrary.BuyerInfo storage buyer = buyers[_msgSender()];

        uint256 tokensRemainingDenominator = idoStatus.totalTokenSold.sub(idoStatus.totalTokensWithdrawn);
        uint256 tokensOwed = IERC20(idoInfo.saleToken).balanceOf(address(this)).mul(buyer.tokensOwed).div(tokensRemainingDenominator);

        require(tokensOwed > 0, "IDO: nothing to withdraw");
        idoStatus.totalTokensWithdrawn = idoStatus.totalTokensWithdrawn.add(buyer.tokensOwed);
        buyer.tokensOwed = 0;

        _safeTransfer(idoInfo.saleToken, _msgSender(), tokensOwed);

        emit Claim(_msgSender(), tokensOwed);
    }

    /// @notice refund user tokens if ido failed or force failed

    function userRefund() external nonReentrant whenNotPaused {
        require(status() == TestLibrary.IDO_STATUS.FAILED || status() == TestLibrary.IDO_STATUS.FORCE_FAILED, "IDO: not failed"); // FAILED
        TestLibrary.BuyerInfo storage buyer = buyers[_msgSender()];
        uint256 baseRemainingDenominator = idoStatus.totalBaseCollected.sub(idoStatus.totalBaseWithdrawn);
        uint256 remainingBaseBalance = isNativeTokenUsed ? address(this).balance : IERC20(idoInfo.baseToken).balanceOf(address(this));

        uint256 tokensOwed = remainingBaseBalance.mul(buyer.baseDeposited).div(baseRemainingDenominator);
        require(tokensOwed > 0, "IDO: nothing to withdraw");

        idoStatus.totalBaseWithdrawn = idoStatus.totalBaseWithdrawn.add(buyer.baseDeposited);
        buyer.baseDeposited = 0;

        if (isNativeTokenUsed) {
            _deliverFunds(_msgSender(), tokensOwed, "IDO: cannot send");
        } else {
            _safeTransfer(idoInfo.baseToken, _msgSender(), tokensOwed);
        }

        emit Refunded(_msgSender(), tokensOwed);
    }

    /// @notice refund sale tokens to owner if ido failed or force failed
    function ownerRefund() external onlyRole(IDO_OWNER_ROLE) {
        require(status() == TestLibrary.IDO_STATUS.FAILED || status() == TestLibrary.IDO_STATUS.FORCE_FAILED, "IDO: not failed"); // FAILED
        _safeTransfer(idoInfo.saleToken, _msgSender(), IERC20(idoInfo.saleToken).balanceOf(address(this)));
    }

    /// @notice finalize ido of successful, add liquidity to pool and lock tokens
    ///@dev from owner or admin
    function finalize() external onlyOwnerOrAdmin {
        require(!idoStatus.lpGenerationComplete, "IDO: generation complete");

        require(status() == TestLibrary.IDO_STATUS.SUCCESS, "IDO: not success"); // SUCCESS

        address baseToken = isNativeTokenUsed ? address(weth) : idoInfo.baseToken;

        // Fail the presale if the pair exists and contains presale token liquidity
        if (lockForwarder.pairIsInitialised(baseToken, idoInfo.saleToken)) {
            idoStatus.forceFailed = true;
            return;
        }

        // base token liquidity
        uint256 baseLiquidity = idoStatus.totalBaseCollected.mul(idoInfo.liquidityPercent).div(10000);

        if (isNativeTokenUsed) {
            weth.deposit{value: baseLiquidity}();

            _safeApprove(address(weth), address(lockForwarder), baseLiquidity);
        } else {
            _safeApprove(idoInfo.baseToken, address(lockForwarder), baseLiquidity);
        }

        // sale token liquidity
        uint256 tokenLiquidity = baseLiquidity.mul(idoInfo.listingRate).div(10**uint256(IERC20Decimals(baseToken).decimals()));

        _safeApprove(idoInfo.saleToken, address(lockForwarder), tokenLiquidity);

        lockForwarder.lockLiquidity(
            baseToken,
            idoInfo.saleToken,
            baseLiquidity,
            tokenLiquidity,
            block.timestamp.add(idoInfo.lockPeriod),
            idoOwner,
            idoInfo.isVestingEnabled,
            idoInfo.cliffPeriod > 0 ? block.timestamp.add(idoInfo.cliffPeriod) : 0
        );

        // send back unsold tokens
        uint256 remainingSaleBalance = IERC20(idoInfo.saleToken).balanceOf(address(this));

        if (remainingSaleBalance > idoStatus.totalTokenSold) {
            uint256 sendAmount = remainingSaleBalance.sub(idoStatus.totalTokenSold);

            if (!isBurnableRestTokens) {
                _safeTransfer(idoInfo.saleToken, idoOwner, sendAmount);
            } else {
                _safeTransfer(idoInfo.saleToken, DEAD_ADDRESS, sendAmount);
            }
        }

        // send remaining base tokens to presale owner
        uint256 remainingBaseBalance = isNativeTokenUsed ? address(this).balance : IERC20(idoInfo.baseToken).balanceOf(address(this));

        if (isNativeTokenUsed) {
            _deliverFunds(idoOwner, remainingBaseBalance, "IDO: cannot send");
        } else {
            _safeTransfer(idoInfo.baseToken, idoOwner, remainingBaseBalance);
        }

        idoStatus.lpGenerationComplete = true;

        emit Finalized();
    }

    /// @notice withdraw tokens from contract
    /// @param _token token address
    /// @param _recipient recipient of tokens
    /// @dev only admin
    function withdrawTokens(address _token, address _recipient) external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = IERC20(_token).balanceOf(address(this));

        _safeTransferAll(_token, _recipient);
        emit EmergencyWithdraw(_token, _recipient, balance);
    }

    /// @notice withdraw from contract
    /// @param _recipient recipient of tokens
    /// @dev only admin
    function withdraw(address _recipient) external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        uint256 balance = address(this).balance;

        _deliverFunds(_recipient, balance, "IDO: cannnot send");
        emit EmergencyWithdrawNative(_recipient, balance);
    }

    /// @notice pause contract
    /// @dev from admin
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /// @notice unpause contract
    /// @dev from admin
    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /// @notice update ido owner
    /// @param _account new owner
    /// @dev from admin
    function updateIdoOwner(address _account) external onlyOwnerOrAdmin {
        idoOwner = _account;

        emit UpdateIDOOwner(_account);
    }

    /// @notice grant owner to new address
    /// @param _account to
    /// @dev from admin

    function grantOwnerRoleTo(address _account) external {
        grantRole(IDO_OWNER_ROLE, _account);
    }

    /// @notice revoke owner from address
    /// @param _account from
    /// @dev from admin

    function revokeOwnerRoleFrom(address _account) external {
        revokeRole(IDO_OWNER_ROLE, _account);
    }

    /// @notice grant admin role to address
    /// @param _account to
    /// @dev from admin
    function grantAdminRoleTo(address _account) external {
        grantRole(DEFAULT_ADMIN_ROLE, _account);
    }

    /// @notice revoke admin role from ddress
    /// @param _account from
    /// @dev from admin
    function revokeAdminRoleFrom(address _account) external {
        revokeRole(DEFAULT_ADMIN_ROLE, _account);
    }

    /// @notice update wrapped token address
    /// @param _weth new address
    /// @dev only when contract paused and from admin
    function updateWETH(IWETH _weth) external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        weth = _weth;
        emit UpdateWETH(address(_weth));
    }

    /// @notice update registry
    /// @param _registry new registry
    /// @dev only when contract paused and from admin
    function updateRegistry(ITestRegistry _registry) external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        registry = _registry;
        emit UpdateRegistry(address(_registry));
    }

    /// @notice update lock forwarder
    /// @param _lockForwarder new lock forwarder
    /// @dev only when contract paused and from admin
    function updateLockForwarder(ITestLockForwarder _lockForwarder) external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        lockForwarder = _lockForwarder;
        emit UpdateLockForwarder(address(lockForwarder));
    }

    /// @notice update settings
    /// @param _settings new settings
    /// @dev only when contract paused and from admin
    function updateSettings(ITestSettings _settings) external whenPaused onlyRole(DEFAULT_ADMIN_ROLE) {
        settings = _settings;
        emit UpdateSettings(address(_settings));
    }

    /// @notice update whitlist
    /// @param _flag enable/disable
    /// @dev from admin or owner
    function updateWhitelistFlag(bool _flag) external onlyOwnerOrAdmin {
        idoStatus.whiteListOnly = _flag;

        emit UpdateWhitelistFlag(_flag);
    }

    /// @notice add to whitelist
    /// @param _users, array of addresses
    /// @param _add true/false
    /// @dev from admin or owner
    function editWhitelist(address[] memory _users, bool _add) external onlyOwnerOrAdmin {
        if (_add) {
            for (uint256 i = 0; i < _users.length; i++) {
                whitelist.add(_users[i]);
            }
        } else {
            for (uint256 i = 0; i < _users.length; i++) {
                whitelist.remove(_users[i]);
            }
        }
    }


    /// @notice update cid path
    /// @param _cid new cid path
    /// @dev from admin
    function updateCidPath(string memory _cid) external onlyOwnerOrAdmin {
        cid = _cid;

        emit UpdateCidPath(_cid);
    }

    /*
        update base settings
    */

    /// @notice update user limits
    /// @param _userLimits, min and max value for deposits
    /// @dev from admin or owner
    function updateUserLimits(TestLibrary.IDOUserLimits memory _userLimits) external onlyOwnerOrAdmin {
        require(_userLimits.minSpendPerBuyer <= _userLimits.maxSpendPerBuyer, "IDO: invalid limits");

        userLimits = _userLimits;
        emit UpdateUserLimits(_userLimits.minSpendPerBuyer, _userLimits.maxSpendPerBuyer);
    }

    /// @notice update start and end times
    /// @param _startTime start time
    /// @param _endTime end time
    /// @dev from admin or owner

    function updateTimes(uint256 _startTime, uint256 _endTime) external onlyOwnerOrAdmin {
        require(idoInfo.startTime > block.timestamp, "IDO: already started");
        require(_endTime.sub(_startTime) <= settings.getMaxIDOLength(), "IDO: invalid start and end times");

        idoInfo.startTime = _startTime;
        idoInfo.endTime = _startTime;

        emit UpdateTimes(_startTime, _endTime);
    }

    /// @notice update lock period
    /// @param _lockPeriod new lock period
    /// @dev only admin
    function updateLockPeriod(uint256 _lockPeriod) external onlyOwnerOrAdmin {
        require(idoInfo.startTime > block.timestamp, "IDO: already started");
        idoInfo.lockPeriod = _lockPeriod;
        emit UpdateLockPeriod(_lockPeriod);
    }

    /// @notice update refund type
    /// @param _isBurnableRestTokens true or false
    /// @dev only admin

    function updateIsBurnableRestTokens(bool _isBurnableRestTokens) external onlyOwnerOrAdmin {
        require(idoInfo.startTime > block.timestamp, "IDO: already started");
        isBurnableRestTokens = _isBurnableRestTokens;
        emit setIsBurnableRestTokens(_isBurnableRestTokens);
    }


    function updateKycVerified(bool _kycVerified) external onlyRole(DEFAULT_ADMIN_ROLE) {
        kycRequired = _kycVerified;

        emit UpdateKycVerified(_kycVerified);
    }


    function updateVerified(bool _verified) external onlyRole(DEFAULT_ADMIN_ROLE) {
        verified = _verified;

        emit UpdateVerified(_verified);
    }

    /// @notice update vesting parameters
    /// @param _isVestingEnabled true or false
    /// @param _cliffPeriod in block numbers
    /// @dev only admin
    function updateIVestingEnabled(bool _isVestingEnabled, uint256 _cliffPeriod) external onlyOwnerOrAdmin {
        require(idoInfo.startTime > block.timestamp, "IDO: already started");
        require(_cliffPeriod < idoInfo.lockPeriod, "IDO: invalid cliff period");
        idoInfo.isVestingEnabled = _isVestingEnabled;
        idoInfo.cliffPeriod = _cliffPeriod;
        emit setIsVestingEnabled(_isVestingEnabled, _cliffPeriod);
    }

    function isOwner(address _account) external view returns (bool) {
        return hasRole(IDO_OWNER_ROLE, _account);
    }

    function isAdmin(address _account) external view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, _account);
    }

    function getWhitelistedUsersLength() external view returns (uint256) {
        return whitelist.length();
    }

    function getWhitelistedUserAtIndex(uint256 _index) external view returns (address) {
        return whitelist.at(_index);
    }

    function getUserWhitelistStatus(address _user) external view returns (bool) {
        return whitelist.contains(_user);
    }
}