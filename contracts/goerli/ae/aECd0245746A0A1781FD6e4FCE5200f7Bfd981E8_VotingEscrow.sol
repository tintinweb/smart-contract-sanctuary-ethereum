// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
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
        _checkRole(role);
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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
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
                        StringsUpgradeable.toHexString(account),
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
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
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

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
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
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
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
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
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
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
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "../interfaces/IAgentManager.sol";

contract AgentManager is IAgentManager, Ownable2StepUpgradeable {
    /**
     * @dev Agent props
     */
    struct AgentProp {
        bool hasAgent;
        uint256 maxCredit;
        uint256 remainingCredit;
        uint256 effectiveBlock;
        uint256 expirationBlock;
        bool minable;
        bool burnable;
    }

    // agent map
    mapping(address => AgentProp) private _agents;

    modifier onlyAgent() {
        require(hasAgent(msg.sender), "AG000");
        _;
    }

    modifier onlyMinable() {
        require(isMinable(msg.sender), "AG002");
        _;
    }

    modifier onlyBurnable() {
        require(isBurnable(msg.sender), "AG003");
        _;
    }

    /**
     * @dev Return agent max credit
     */
    function getMaxCredit(address account) public view override returns (uint256) {
        require(hasAgent(account), "AG000");
        return _agents[account].maxCredit;
    }

    /**
     * @dev Return agent remaining credit
     * @dev Return zero when the block number does not reach the effective block number or exceeds the expiration block number
     */
    function getRemainingCredit(address account) public view override returns (uint256) {
        require(hasAgent(account), "AG000");
        if (_agents[account].effectiveBlock > block.number) {
            return 0;
        }
        if (_agents[account].expirationBlock < block.number) {
            return 0;
        }
        return _agents[account].remainingCredit;
    }

    /**
     * @dev Return agent minable status
     */
    function isMinable(address account) public view override returns (bool) {
        require(hasAgent(account), "AG000");
        return _agents[account].minable;
    }

    /**
     * @dev Return agent burnable status
     */
    function isBurnable(address account) public view override returns (bool) {
        require(hasAgent(account), "AG000");
        return _agents[account].burnable;
    }

    /**
     * @dev Return agent effective block number
     */
    function getEffectiveBlock(address account) public view override returns (uint256) {
        require(hasAgent(account), "AG000");
        return _agents[account].effectiveBlock;
    }

    /**
     * @dev Return agent expiration block number
     */
    function getExpirationBlock(address account) public view override returns (uint256) {
        require(hasAgent(account), "AG000");
        return _agents[account].expirationBlock;
    }

    /**
     * @dev Return whether the address is an agent
     */
    function hasAgent(address account) public view override returns (bool) {
        return _agents[account].hasAgent;
    }

    /**
     * @dev Grant the address as agent
     * @dev After setting credit, the max credit and the remaining credit are the same as credit
     * @param account Grant agent address
     * @param credit Grant agent Max credit & Remaining credit
     * @param effectiveBlock Agent effective block number
     * @param expirationBlock Agent expiration block number
     * @param minable Agent minable
     * @param burnable Agent burnable
     */
    function grantAgent(
        address account,
        uint256 credit,
        uint256 effectiveBlock,
        uint256 expirationBlock,
        bool minable,
        bool burnable
    ) public override onlyOwner {
        require(account != address(0), "CE000");
        require(!hasAgent(account), "AG001");
        require(credit > 0, "AG005");
        require(expirationBlock > block.number, "AG006");
        require(effectiveBlock < expirationBlock, "AG015");
        _grantAgent(account, credit, effectiveBlock, expirationBlock, minable, burnable);
    }

    function _grantAgent(
        address account,
        uint256 credit,
        uint256 effectiveBlock,
        uint256 expirationBlock,
        bool minable,
        bool burnable
    ) internal {
        _agents[account].hasAgent = true;
        _agents[account].maxCredit = credit;
        _agents[account].remainingCredit = credit;
        _agents[account].effectiveBlock = effectiveBlock;
        _agents[account].expirationBlock = expirationBlock;
        _agents[account].minable = minable;
        _agents[account].burnable = burnable;
        emit AgentGranted(account, credit, effectiveBlock, expirationBlock, minable, burnable, _msgSender());
    }

    /**
     * @dev Revoke the agent at the address
     * @param account Revoke agent address
     */
    function revokeAgent(address account) public override onlyOwner {
        require(account != address(0), "CE000");
        require(hasAgent(account), "AG000");
        _revokeAgent(account);
    }

    function _revokeAgent(address account) internal {
        delete _agents[account];
        emit AgentRevoked(account, _msgSender());
    }

    /**
     * @dev Change the effective block number of the address agent
     */
    function changeEffectiveBlock(address account, uint256 effectiveBlock) public override onlyOwner {
        require(account != address(0), "CE000");
        require(hasAgent(account), "AG000");
        require(effectiveBlock < _agents[account].expirationBlock, "AG012");
        _agents[account].effectiveBlock = effectiveBlock;
        emit AgentChangeEffectiveBlock(account, effectiveBlock, _msgSender());
    }

    /**
     * @dev Change the expiration block number of the address agent
     */
    function changeExpirationBlock(address account, uint256 expirationBlock) public override onlyOwner {
        require(account != address(0), "CE000");
        require(hasAgent(account), "AG000");
        require(expirationBlock != _agents[account].expirationBlock && expirationBlock > block.number, "AG013");
        _agents[account].expirationBlock = expirationBlock;
        emit AgentChangeExpirationBlock(account, expirationBlock, _msgSender());
    }

    /**
     * @dev Change the minable status of the address agent
     */
    function switchMinable(address account, bool minable) public override onlyOwner {
        require(account != address(0), "CE000");
        require(hasAgent(account), "AG000");
        require(minable != _agents[account].minable, "AG010");
        _agents[account].minable = minable;
        emit AgentSwitchMinable(account, minable, _msgSender());
    }

    /**
     * @dev Change the burnable status of the address agent
     */
    function switchBurnable(address account, bool burnable) public override onlyOwner {
        require(account != address(0), "CE000");
        require(hasAgent(account), "AG000");
        require(burnable != _agents[account].burnable, "AG010");
        _agents[account].burnable = burnable;
        emit AgentSwitchBurnable(account, burnable, _msgSender());
    }

    /**
     * @dev Increase credit of the address agent
     * @dev After increase credit, the max credit and the remaining credit increase simultaneously
     */
    function increaseCredit(address account, uint256 credit) public override onlyOwner {
        require(account != address(0), "CE000");
        require(hasAgent(account), "AG000");
        require(credit > 0, "AG007");
        _agents[account].maxCredit += credit;
        _agents[account].remainingCredit += credit;
        emit AgentIncreaseCredit(account, credit, _msgSender());
    }

    /**
     * @dev Decrease credit of the address agent
     * @dev After decrease credit, the max credit and the remaining credit decrease simultaneously
     */
    function decreaseCredit(address account, uint256 credit) public override onlyOwner {
        require(account != address(0), "CE000");
        require(hasAgent(account), "AG000");
        require(credit > 0, "AG008");
        require(credit <= _agents[account].remainingCredit, "AG009");
        _agents[account].maxCredit -= credit;
        _agents[account].remainingCredit -= credit;
        emit AgentDecreaseCredit(account, credit, _msgSender());
    }

    function _increaseRemainingCredit(address account, uint256 amount) internal {
        if (getRemainingCredit(account) + amount > getMaxCredit(account)) {
            _agents[account].remainingCredit = getMaxCredit(account);
        } else {
            _agents[account].remainingCredit += amount;
        }
    }

    function _decreaseRemainingCredit(address account, uint256 amount) internal {
        _agents[account].remainingCredit -= amount;
    }

    // @dev This empty reserved space is put in place to allow future versions to add new
    // variables without shifting down storage in the inheritance chain.
    // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[49] private __gap;
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "../interfaces/IHOPESalesAgent.sol";
import "../interfaces/IHOPE.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";
import {StringUtils} from "light-lib/contracts/StringUtils.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/**
 * @title LT Dao's HOPESalesAgent Contract
 * @notice HOPE Sales Agent
 * @author LT
 */
contract HOPESalesAgent is IHOPESalesAgent, Ownable2Step, Pausable {
    /**
     * @dev Currency info
     */
    struct Currency {
        address token;
        string symbol;
        uint256 rate;
    }

    // Currency rate denominator rate/rateDenominator,if TokenA:TokenB=1:1, set rate = 1000*10^(Adecimal-Bdecimal)
    uint256 public immutable rateDenominator;

    // HOPE token contract
    address public immutable hopeToken;

    // Permit2 contract
    address public permit2;

    // Map of currencies available for purchase  currencySymbol => Currency
    mapping(string => Currency) public currencys;

    constructor(address _hopeToken, address _permit2) {
        hopeToken = _hopeToken;
        permit2 = _permit2;
        rateDenominator = 1000;
    }

    /**
     * @dev Buy HOPE token
     * @notice If the user has no allowance, needs approve to Permit2
     * @param fromCurrency Payment ERC20 symbol
     * @param fromValue Payment amount
     * @param nonce Signature nonce
     * @param deadline Signature deadline
     * @param signature EIP712 signature
     */
    function buy(
        string memory fromCurrency,
        uint256 fromValue,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) external whenNotPaused {
        Currency storage cy = currencys[fromCurrency];
        require(cy.token != address(0), "HS000");

        uint256 toValue = _getToValue(fromValue, cy.rate);
        require(toValue > 0, "HS001");
        require(toValue <= this.remainingCredit(), "AG004");

        address buyer = _msgSender();
        TransferHelper.doTransferIn(permit2, cy.token, fromValue, buyer, nonce, deadline, signature);
        IHOPE(hopeToken).mint(buyer, toValue);

        emit Buy(fromCurrency, buyer, fromValue, toValue, block.timestamp);
    }

    /**
     * @dev Return agent remaining credit
     */
    function remainingCredit() external view returns (uint256) {
        return IHOPE(hopeToken).getRemainingCredit(address(this));
    }

    /**
     * @dev Return erc20 balance from sales contract
     */
    function balanceOf(string memory symbol) external view returns (uint256) {
        Currency storage cy = currencys[symbol];
        if (cy.token == address(0)) {
            return 0;
        }

        return IERC20(cy.token).balanceOf(address(this));
    }

    /**
     * @dev Redeem erc20 balance, onlyOwner
     * @param symbol Redeem erc20 symbol
     * @param to Redeem to address
     * @param amount Redeem amount
     */
    function redeem(string memory symbol, address to, uint256 amount) external onlyOwner whenNotPaused returns (bool) {
        Currency storage cy = currencys[symbol];
        require(cy.token != address(0), "CE001");

        uint256 balance = this.balanceOf(symbol);
        require(balance >= amount, "CE002");

        TransferHelper.doTransferOut(cy.token, to, amount);

        emit Redeem(symbol, to, amount);
        return true;
    }

    /**
     * @dev Add currency that can buy HOPE token, onlyOwner
     * @param symbol ERC20 symbol
     * @param token ERC20 address
     * @param rate Currency rate
     */
    function addCurrency(string memory symbol, address token, uint256 rate) external onlyOwner {
        Currency storage cy = currencys[symbol];
        require(cy.token == address(0), "HS002");
        require(rate > 0, "HS003");
        require(token != address(0), "CE000");

        IERC20Metadata erc20 = IERC20Metadata(token);
        string memory erc20Symbol = erc20.symbol();
        require(StringUtils.hashCompareWithLengthCheck(symbol, erc20Symbol), "HS004");
        cy.symbol = symbol;
        cy.token = token;
        cy.rate = rate;

        emit AddCurrency(symbol, token, rate);
    }

    /**
     * @dev Change currency exhange rate, onlyOwner
     * @param symbol ERC20 symbol
     * @param rate Currency rate
     */
    function changeCurrencyRate(string memory symbol, uint256 rate) external onlyOwner {
        Currency storage cy = currencys[symbol];
        require(cy.token != address(0), "CE001");
        require(rate > 0, "HS003");
        uint256 oldRate = cy.rate;
        cy.rate = rate;

        emit ChangeCurrencyRate(symbol, rate, oldRate);
    }

    /**
     * @dev Delete currency, onlyOwner
     * @notice Cannot delete currency if balanceOf(address(this)) > 0。 admin can redeem balance and delete currency
     * @param symbol ERC20 symbol
     */
    function deleteCurrency(string memory symbol) external onlyOwner {
        Currency storage cy = currencys[symbol];
        require(cy.token != address(0), "CE001");
        require(this.balanceOf(symbol) == 0, "HS005");

        delete currencys[symbol];

        emit DeleteCurrency(symbol);
    }

    /**
     * @dev Set permit2 address, onlyOwner
     * @param newAddress New permit2 address
     */
    function setPermit2Address(address newAddress) external onlyOwner {
        require(newAddress != address(0), "CE000");
        address oldAddress = permit2;
        permit2 = newAddress;
        emit SetPermit2Address(oldAddress, newAddress);
    }

    function _getToValue(uint256 fromValue, uint256 rate) internal view returns (uint256) {
        return (fromValue * rate) / rateDenominator;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

interface IConnet {
    function depositRewardToken(uint256 amount) external;

    function deposit(address token, address addr, uint256 amount) external returns (bool);
}

abstract contract AbsConnetVault is Ownable2StepUpgradeable, PausableUpgradeable, ERC20Upgradeable, AccessControlUpgradeable {
    event Deposit(address indexed from, uint256 amount);
    event ChangeConnet(address indexed newConnet);

    bytes32 public constant withrawAdminRole = keccak256("withraw_Admin_Role");

    // permit2 contract
    address public permit2Address;

    ///token address
    address public token;
    /// connnet address
    address public connet;

    function _initialize(
        address _permit2Address,
        address _token,
        address _connnet,
        address _withdrawAdmin,
        address _ownerAddress
    ) internal onlyInitializing {
        require(_ownerAddress != address(0), "CE000");
        // require(_connnet != address(0), "CE000");
        require(_token != address(0), "CE000");

        string memory _name = IERC20MetadataUpgradeable(_token).name();
        string memory _symbol = IERC20MetadataUpgradeable(_token).symbol();
        __ERC20_init(string.concat("b", _name), _symbol);

        connet = _connnet;
        permit2Address = _permit2Address;
        token = _token;
        _transferOwnership(_ownerAddress);
        if (_withdrawAdmin != address(0)) {
            _grantRole(withrawAdminRole, _withdrawAdmin);
        }
    }

    function deposit(uint256 amount, uint256 nonce, uint256 deadline, bytes memory signature) external whenNotPaused returns (uint256) {
        require(connet != address(0), "connet is not initialized, please deposit later");
        require(amount != 0, "INVALID_ZERO_AMOUNT");
        address from = _msgSender();
        /// transferFrom token to this contract
        TransferHelper.doTransferIn(permit2Address, token, amount, from, nonce, deadline, signature);
        /// mint bToken to user
        _mint(from, amount);
        /// tranfer bToken to connnet
        _transfer(from, connet, amount);
        /// notify connet transfer info
        IConnet(connet).deposit(token, from, amount);

        emit Deposit(from, amount);

        return amount;
    }

    function withdraw(address to, uint256 amount) external whenNotPaused onlyRole(withrawAdminRole) returns (uint256) {
        require(amount > 0, "INVALID_ZERO_AMOUNT");
        require(amount <= balanceOf(msg.sender), "insufficient balance");
        /// burn bToken
        _burn(msg.sender, amount);
        /// transfer token to toAccount
        TransferHelper.doTransferOut(token, to, amount);

        return amount;
    }

    function changeConnet(address newConnet) external onlyOwner {
        connet = newConnet;
        emit ChangeConnet(newConnet);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function grantRole(bytes32 role, address account) public override onlyOwner {
        _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public override onlyOwner {
        _revokeRole(role, account);
    }

    // @dev This empty reserved space is put in place to allow future versions to add new
    // variables without shifting down storage in the inheritance chain.
    // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[49] private __gap;
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "./AbsConnetVault.sol";

contract ConnetVault is AbsConnetVault {
    function initialize(
        address _permit2Address,
        address _token,
        address _connnet,
        address _withdrawAdmin,
        address _ownerAddress
    ) external initializer {
        _initialize(_permit2Address, _token, _connnet, _withdrawAdmin, _ownerAddress);
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "../interfaces/IMinter.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";
import "./AbsConnetVault.sol";

contract ConnetVaultOfStHOPE is Ownable2StepUpgradeable, PausableUpgradeable, ERC20Upgradeable, AbsConnetVault {
    event RewardsDistributed(address distributer, address to, uint256 amount);

    address public minter;
    address private ltToken;

    function initialize(
        address _permit2Address,
        address _token,
        address _connnet,
        address _withdrawAdmin,
        address _ownerAddress,
        address _minter,
        address _ltToken
    ) external initializer {
        require(_minter != address(0), "CE000");
        require(_ltToken != address(0), "CE000");
        minter = _minter;
        ltToken = _ltToken;
        _initialize(_permit2Address, _token, _connnet, _withdrawAdmin, _ownerAddress);
    }

    function transferLTRewards(address to, uint256 amount) external whenNotPaused returns (bool) {
        require(msg.sender == connet, "forbidden");
        /// mint stHopeGomboc reward for this contract
        IMinter(minter).mint(token);
        /// transfer LT
        bool success = ERC20Upgradeable(ltToken).transfer(to, amount);
        require(success, "Transfer FAILED");

        emit RewardsDistributed(msg.sender, to, amount);

        return true;
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "../interfaces/IBurner.sol";

contract BurnerManager is Ownable2Step {
    event AddBurner(IBurner indexed newBurner, IBurner indexed oldBurner);

    /// tokenAddress => burnerAddress
    mapping(address => IBurner) public burners;

    /**
     * @notice Contract constructor
     */
    constructor() {}

    /**
     * @notice Set burner of `token` to `burner` address
     * @param token token address
     * @param burner burner address
     */
    function setBurner(address token, IBurner burner) external onlyOwner returns (bool) {
        return _setBurner(token, burner);
    }

    /**
     * @notice Set burner of `token` to `burner` address
     * @param tokens token address
     * @param burnerList token address
     */
    function setManyBurner(address[] memory tokens, IBurner[] memory burnerList) external onlyOwner returns (bool) {
        require(tokens.length == burnerList.length, "invalid param");

        for (uint256 i = 0; i < tokens.length; i++) {
            _setBurner(tokens[i], burnerList[i]);
        }

        return true;
    }

    function _setBurner(address token, IBurner burner) internal returns (bool) {
        require(token != address(0), "CE000");
        require(burner != IBurner(address(0)), "CE000");

        IBurner oldBurner = burners[token];
        burners[token] = burner;

        emit AddBurner(burner, oldBurner);

        return true;
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/IFeeDistributor.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";
import "light-lib/contracts/LibTime.sol";
import "hardhat/console.sol";

struct Point {
    int256 bias;
    int256 slope;
    uint256 ts;
    uint256 blk;
}

interface IVotingEscrow {
    function epoch() external view returns (uint256);

    function userPointEpoch(address user) external view returns (uint256);

    function checkpointSupply() external;

    function supplyPointHistory(uint256 epoch) external view returns (Point memory);

    function userPointHistory(address user, uint256 epoch) external view returns (Point memory);
}

interface IStakingHOPE {
    function staking(uint256 amount, uint256 nonce, uint256 deadline, bytes memory signature) external returns (bool);
}

contract FeeDistributor is Ownable2StepUpgradeable, PausableUpgradeable, IFeeDistributor {
    uint256 constant WEEK = 7 * 86400;
    uint256 constant TOKEN_CHECKPOINT_DEADLINE = 86400;

    uint256 public startTime;
    uint256 public timeCursor;

    ///userAddress => timeCursor
    mapping(address => uint256) public timeCursorOf;
    ///userAddress => epoch
    mapping(address => uint256) public userEpochOf;

    ///lastTokenTime
    uint256 public lastTokenTime;
    /// tokensPreWeek
    mapping(uint256 => uint256) public tokensPerWeek;

    ///HOPE Token address
    address public token;
    /// staking hope address
    address public stHOPE;
    /// VeLT contract address
    address public votingEscrow;

    uint256 public tokenLastBalance;

    // VE total supply at week bounds
    mapping(uint256 => uint256) public veSupply;

    bool public canCheckpointToken;
    address public emergencyReturn;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Contract constructor
     * @param _votingEscrow VotingEscrow contract address
     * @param _startTime Epoch time for fee distribution to start
     * @param _token HOPE token address
     * @param _stHOPE stakingHOPE  address
     * @param _emergencyReturn Address to transfer `_token` balance to if this contract is killed
     */
    function initialize(
        address _votingEscrow,
        uint256 _startTime,
        address _token,
        address _stHOPE,
        address _emergencyReturn
    ) external initializer {
        require(_votingEscrow != address(0), "Invalid Address");
        require(_token != address(0), "Invalid Address");
        require(_stHOPE != address(0), "Invalid Address");

        __Ownable2Step_init();

        uint256 t = LibTime.timesRoundedByWeek(_startTime);
        startTime = t;
        lastTokenTime = t;
        timeCursor = t;
        emergencyReturn = _emergencyReturn;

        token = _token;
        stHOPE = _stHOPE;
        votingEscrow = _votingEscrow;
    }

    /**
     * @notice Update the token checkpoint
     * @dev Calculates the total number of tokens to be distributed in a given week.
         During setup for the initial distribution this function is only callable
         by the contract owner. Beyond initial distro, it can be enabled for anyone
         to call
     */
    function checkpointToken() external {
        require((msg.sender == owner()) || (canCheckpointToken && (block.timestamp > lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)), "FD001");
        _checkpointToken();
    }

    function _checkpointToken() internal {
        uint256 tokenBalance = IERC20Upgradeable(token).balanceOf(address(this));
        uint256 toDistribute = tokenBalance - tokenLastBalance;
        tokenLastBalance = tokenBalance;

        uint256 t = lastTokenTime;
        uint256 sinceLast = block.timestamp - t;
        lastTokenTime = block.timestamp;
        uint256 thisWeek = LibTime.timesRoundedByWeek(t);
        uint256 nextWeek = 0;

        for (uint i = 0; i < 20; i++) {
            nextWeek = thisWeek + WEEK;
            if (block.timestamp < nextWeek) {
                if (sinceLast == 0 && block.timestamp == t) {
                    tokensPerWeek[thisWeek] += toDistribute;
                } else {
                    tokensPerWeek[thisWeek] += (toDistribute * (block.timestamp - t)) / sinceLast;
                }
                break;
            } else {
                if (sinceLast == 0 && nextWeek == t) {
                    tokensPerWeek[thisWeek] += toDistribute;
                } else {
                    tokensPerWeek[thisWeek] += (toDistribute * (nextWeek - t)) / sinceLast;
                }
            }
            t = nextWeek;
            thisWeek = nextWeek;
        }
        emit CheckpointToken(block.timestamp, toDistribute);
    }

    /**
     * @notice Get the veLT balance for `_user` at `_timestamp`
     * @param _user Address to query balance for
     * @param _timestamp Epoch time
     * @return uint256 veLT balance
     */
    function veForAt(address _user, uint256 _timestamp) external view returns (uint256) {
        uint256 maxUserEpoch = IVotingEscrow(votingEscrow).userPointEpoch(_user);
        uint256 epoch = _findTimestampUserEpoch(votingEscrow, _user, _timestamp, maxUserEpoch);
        Point memory pt = IVotingEscrow(votingEscrow).userPointHistory(_user, epoch);
        return _getPointBalanceOf(pt.bias, pt.slope, _timestamp - pt.ts);
    }

    /**
     * @notice Get the VeLT voting percentage for `_user` in _gomboc  at `_timestamp`
     * @dev This function should be manually changed to "view" in the ABI
     * @param _user Address to query voting
     * @param _timestamp Epoch time
     * @return value of voting precentage normalized to 1e18
     */
    function vePrecentageForAt(address _user, uint256 _timestamp) external returns (uint256) {
        if (block.timestamp >= timeCursor) {
            _checkpointTotalSupply();
        }
        _timestamp = LibTime.timesRoundedByWeek(_timestamp);
        uint256 veForAtValue = this.veForAt(_user, _timestamp);
        uint256 supply = veSupply[_timestamp];
        if (supply == 0) {
            return 0;
        }
        return (veForAtValue * 1e18) / supply;
    }

    /**
     * @notice Update the veLT total supply checkpoint
     * @dev The checkpoint is also updated by the first claimant each
         new epoch week. This function may be called independently
         of a claim, to reduce claiming gas costs.
     */
    function checkpointTotalSupply() external {
        _checkpointTotalSupply();
    }

    function _checkpointTotalSupply() internal {
        uint256 t = timeCursor;
        uint256 roundedTimestamp = LibTime.timesRoundedByWeek(block.timestamp);
        IVotingEscrow(votingEscrow).checkpointSupply();

        for (int i = 0; i < 20; i++) {
            if (t > roundedTimestamp) {
                break;
            } else {
                uint256 epoch = _findTimestampEpoch(votingEscrow, t);
                Point memory pt = IVotingEscrow(votingEscrow).supplyPointHistory(epoch);
                uint256 dt = 0;
                if (t > pt.ts) {
                    /// If the point is at 0 epoch, it can actually be earlier than the first deposit
                    /// Then make dt 0
                    dt = t - pt.ts;
                }
                veSupply[t] = _getPointBalanceOf(pt.bias, pt.slope, dt);
            }
            t += WEEK;
        }
        timeCursor = t;
    }

    function _findTimestampEpoch(address ve, uint256 _timestamp) internal view returns (uint256) {
        uint256 _min = 0;
        uint256 _max = IVotingEscrow(ve).epoch();
        for (int i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 2) / 2;
            Point memory pt = IVotingEscrow(ve).supplyPointHistory(_mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    function _findTimestampUserEpoch(address ve, address user, uint256 _timestamp, uint256 maxUserEpoch) internal view returns (uint256) {
        uint256 _min = 0;
        uint256 _max = maxUserEpoch;
        for (int i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 2) / 2;
            Point memory pt = IVotingEscrow(ve).userPointHistory(user, _mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    function _claim(address addr, address ve, uint256 _lastTokenTime) internal returns (uint256) {
        ///Minimal userEpoch is 0 (if user had no point)
        uint256 userEpoch = 0;
        uint256 toDistribute = 0;

        uint256 maxUserEpoch = IVotingEscrow(ve).userPointEpoch(addr);
        uint256 _startTime = startTime;

        if (maxUserEpoch == 0) {
            /// No lock = no fees
            return 0;
        }

        uint256 weekCursor = timeCursorOf[addr];
        if (weekCursor == 0) {
            /// Need to do the initial binary search
            userEpoch = _findTimestampUserEpoch(ve, addr, _startTime, maxUserEpoch);
        } else {
            userEpoch = userEpochOf[addr];
        }
        if (userEpoch == 0) {
            userEpoch = 1;
        }

        Point memory userPoint = IVotingEscrow(ve).userPointHistory(addr, userEpoch);
        if (weekCursor == 0) {
            weekCursor = LibTime.timesRoundedByWeek(userPoint.ts + WEEK - 1);
        }

        if (weekCursor >= _lastTokenTime) {
            return 0;
        }

        if (weekCursor < _startTime) {
            weekCursor = _startTime;
        }
        Point memory oldUserPoint = Point({bias: 0, slope: 0, ts: 0, blk: 0});

        /// Iterate over weeks
        for (int i = 0; i < 50; i++) {
            if (weekCursor >= _lastTokenTime) {
                break;
            }

            if (weekCursor >= userPoint.ts && userEpoch <= maxUserEpoch) {
                userEpoch += 1;
                oldUserPoint = userPoint;
                if (userEpoch > maxUserEpoch) {
                    userPoint = Point({bias: 0, slope: 0, ts: 0, blk: 0});
                } else {
                    userPoint = IVotingEscrow(ve).userPointHistory(addr, userEpoch);
                }
            } else {
                // Calc
                // + i * 2 is for rounding errors
                uint256 dt = weekCursor - oldUserPoint.ts;
                uint256 balanceOf = _getPointBalanceOf(oldUserPoint.bias, oldUserPoint.slope, dt);
                if (balanceOf == 0 && userEpoch > maxUserEpoch) {
                    break;
                }
                if (balanceOf > 0) {
                    toDistribute += (balanceOf * tokensPerWeek[weekCursor]) / veSupply[weekCursor];
                }
                weekCursor += WEEK;
            }
        }

        userEpoch = Math.min(maxUserEpoch, userEpoch - 1);
        userEpochOf[addr] = userEpoch;
        timeCursorOf[addr] = weekCursor;

        emit Claimed(addr, toDistribute, userEpoch, maxUserEpoch);

        return toDistribute;
    }

    function _getPointBalanceOf(int256 bias, int256 slope, uint256 dt) internal pure returns (uint256) {
        uint256 currentBias = uint256(slope) * dt;
        uint256 oldBias = uint256(bias);
        if (currentBias > oldBias) {
            return 0;
        }
        return oldBias - currentBias;
    }

    /**
     * @notice Claim fees for `_addr`
     *  @dev Each call to claim look at a maximum of 50 user veLT points.
         For accounts with many veLT related actions, this function
         may need to be called more than once to claim all available
         fees. In the `Claimed` event that fires, if `claim_epoch` is
         less than `max_epoch`, the account may claim again.
         @param _addr Address to claim fees for
         @return uint256 Amount of fees claimed in the call
     *
     */
    function claim(address _addr) external whenNotPaused returns (uint256) {
        if (block.timestamp >= timeCursor) {
            _checkpointTotalSupply();
        }

        if (_addr == address(0)) {
            _addr = msg.sender;
        }
        uint256 _lastTokenTime = lastTokenTime;
        if (canCheckpointToken && (block.timestamp > _lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)) {
            _checkpointToken();
            _lastTokenTime = block.timestamp;
        }

        _lastTokenTime = LibTime.timesRoundedByWeek(_lastTokenTime);
        uint256 amount = _claim(_addr, votingEscrow, _lastTokenTime);
        if (amount != 0) {
            stakingHOPEAndTransfer2User(_addr, amount);
            tokenLastBalance -= amount;
        }
        return amount;
    }

    /**
     * @notice Claim fees for `_addr`
     * @dev This function should be manually changed to "view" in the ABI
     * @param _addr Address to claim fees for
     * @return uint256 Amount of fees claimed in the call
     *
     */
    function claimableToken(address _addr) external returns (uint256) {
        if (block.timestamp >= timeCursor) {
            _checkpointTotalSupply();
        }
        if (_addr == address(0)) {
            _addr = msg.sender;
        }
        uint256 _lastTokenTime = lastTokenTime;
        if (canCheckpointToken && (block.timestamp > _lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)) {
            _checkpointToken();
            _lastTokenTime = block.timestamp;
        }

        _lastTokenTime = LibTime.timesRoundedByWeek(_lastTokenTime);
        return _claim(_addr, votingEscrow, _lastTokenTime);
    }

    /**
     * @notice Make multiple fee claims in a single call
     * @dev Used to claim for many accounts at once, or to make
         multiple claims for the same address when that address
         has significant veLT history
     * @param _receivers List of addresses to claim for. Claiming terminates at the first `ZERO_ADDRESS`.
     * @return uint256 claim totol fee
     */
    function claimMany(address[] memory _receivers) external whenNotPaused returns (uint256) {
        if (block.timestamp >= timeCursor) {
            _checkpointTotalSupply();
        }

        uint256 _lastTokenTime = lastTokenTime;

        if (canCheckpointToken && (block.timestamp > _lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)) {
            _checkpointToken();
            _lastTokenTime = block.timestamp;
        }

        _lastTokenTime = LibTime.timesRoundedByWeek(_lastTokenTime);
        uint256 total = 0;

        for (uint256 i = 0; i < _receivers.length && i < 50; i++) {
            address addr = _receivers[i];
            if (addr == address(0)) {
                break;
            }
            uint256 amount = _claim(addr, votingEscrow, _lastTokenTime);
            if (amount != 0) {
                stakingHOPEAndTransfer2User(addr, amount);
                total += amount;
            }
        }

        if (total != 0) {
            tokenLastBalance -= total;
        }

        return total;
    }

    /**
     * @notice Receive HOPE into the contract and trigger a token checkpoint
     * @param amount burn amount
     * @return bool success
     */
    function burn(uint256 amount) external whenNotPaused returns (bool) {
        if (amount != 0) {
            require(IERC20Upgradeable(token).transferFrom(msg.sender, address(this), amount), "TRANSFER_FROM_FAILED");
            if (canCheckpointToken && (block.timestamp > lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)) {
                _checkpointToken();
            }
        }
        return true;
    }

    /**
     * @notice Toggle permission for checkpointing by any account
     */
    function toggleAllowCheckpointToken() external onlyOwner {
        bool flag = !canCheckpointToken;
        canCheckpointToken = !canCheckpointToken;
        emit ToggleAllowCheckpointToken(flag);
    }

    /**
     * @notice Recover ERC20 tokens from this contract
     * @dev Tokens are sent to the emergency return address.
     * @return bool success
     */
    function recoverBalance() external onlyOwner returns (bool) {
        uint256 amount = IERC20Upgradeable(token).balanceOf(address(this));
        TransferHelper.doTransferOut(token, emergencyReturn, amount);
        emit RecoverBalance(token, emergencyReturn, amount);
        return true;
    }

    /**
     * @notice Set the token emergency return address
     * @param _addr emergencyReturn address
     */
    function setEmergencyReturn(address _addr) external onlyOwner {
        emergencyReturn = _addr;
        emit SetEmergencyReturn(_addr);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function stakingHOPEAndTransfer2User(address to, uint256 amount) internal {
        TransferHelper.doApprove(token, stHOPE, amount);
        bool success = IStakingHOPE(stHOPE).staking(amount, 0, 0, "");
        require(success, "staking hope fail");
        TransferHelper.doTransferOut(stHOPE, to, amount);
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/IGombocFeeDistributor.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";
import "light-lib/contracts/LibTime.sol";
import "hardhat/console.sol";

struct Point {
    int256 bias;
    int256 slope;
    uint256 ts;
    uint256 blk;
}

struct SimplePoint {
    uint256 bias;
    uint256 slope;
}

interface IGombocController {
    function lastVoteVeLtPointEpoch(address user, address gomboc) external view returns (uint256);

    function pointsWeight(address gomboc, uint256 time) external view returns (SimplePoint memory);

    function voteVeLtPointHistory(address user, address gomboc, uint256 epoch) external view returns (Point memory);

    function gombocRelativeWeight(address gombocAddress, uint256 time) external view returns (uint256);

    function checkpointGomboc(address addr) external;
}

interface IStakingHOPE {
    function staking(uint256 amount, uint256 nonce, uint256 deadline, bytes memory signature) external returns (bool);
}

contract GombocFeeDistributor is Ownable2StepUpgradeable, PausableUpgradeable, IGombocFeeDistributor {
    uint256 constant WEEK = 7 * 86400;
    uint256 constant TOKEN_CHECKPOINT_DEADLINE = 86400;

    uint256 public startTime;
    uint256 public timeCursor;

    /// gombocAddress => userAddress => timeCursor
    mapping(address => mapping(address => uint256)) public timeCursorOf;
    /// gombocAddress => userAddress => epoch
    mapping(address => mapping(address => uint256)) public userEpochOf;

    /// lastTokenTime
    uint256 public lastTokenTime;
    /// tokensPreWeek
    mapping(uint256 => uint256) public tokensPerWeek;

    ///HOPE Token address
    address public token;
    /// staking hope address
    address public stHOPE;
    uint256 public tokenLastBalance;
    address public gombocController;

    bool public canCheckpointToken;
    address public emergencyReturn;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Contract constructor
     * @param _gombocController GombocController contract address
     * @param _startTime Epoch time for fee distribution to start
     * @param _token Fee token address list
     * @param _stHOPE stakingHOPE  address
     * @param _emergencyReturn Address to transfer `_token` balance to if this contract is killed
     */
    function initialize(
        address _gombocController,
        uint256 _startTime,
        address _token,
        address _stHOPE,
        address _emergencyReturn
    ) external initializer {
        require(_gombocController != address(0), "Invalid Address");
        require(_token != address(0), "Invalid Address");
        require(_stHOPE != address(0), "Invalid Address");

        __Ownable2Step_init();

        uint256 t = LibTime.timesRoundedByWeek(_startTime);
        startTime = t;
        lastTokenTime = t;

        token = _token;
        stHOPE = _stHOPE;
        timeCursor = t;
        gombocController = _gombocController;
        emergencyReturn = _emergencyReturn;
    }

    /**
     * @notice Update the token checkpoint
     * @dev Calculates the total number of tokens to be distributed in a given week.
         During setup for the initial distribution this function is only callable
         by the contract owner. Beyond initial distro, it can be enabled for anyone
         to call
     */
    function checkpointToken() external {
        require((msg.sender == owner()) || (canCheckpointToken && (block.timestamp > lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)), "FD001");
        _checkpointToken();
    }

    function _checkpointToken() internal {
        uint256 tokenBalance = IERC20Upgradeable(token).balanceOf(address(this));
        uint256 toDistribute = tokenBalance - tokenLastBalance;
        tokenLastBalance = tokenBalance;

        uint256 t = lastTokenTime;
        uint256 sinceLast = block.timestamp - t;
        lastTokenTime = block.timestamp;
        uint256 thisWeek = LibTime.timesRoundedByWeek(t);
        uint256 nextWeek = 0;

        for (uint i = 0; i < 20; i++) {
            nextWeek = thisWeek + WEEK;
            if (block.timestamp < nextWeek) {
                if (sinceLast == 0 && block.timestamp == t) {
                    tokensPerWeek[thisWeek] += toDistribute;
                } else {
                    tokensPerWeek[thisWeek] += (toDistribute * (block.timestamp - t)) / sinceLast;
                }
                break;
            } else {
                if (sinceLast == 0 && nextWeek == t) {
                    tokensPerWeek[thisWeek] += toDistribute;
                } else {
                    tokensPerWeek[thisWeek] += (toDistribute * (nextWeek - t)) / sinceLast;
                }
            }
            t = nextWeek;
            thisWeek = nextWeek;
        }
        emit CheckpointToken(block.timestamp, toDistribute);
    }

    /**
     * @notice Get the veLT balance for `_user` at `_timestamp`
     * @param _gomboc Address to query voting gomboc
     * @param _user Address to query voting amount
     * @param _timestamp Epoch time
     * @return uint256 veLT balance
     */
    function veForAt(address _gomboc, address _user, uint256 _timestamp) external view returns (uint256) {
        uint256 maxUserEpoch = IGombocController(gombocController).lastVoteVeLtPointEpoch(_user, _gomboc);
        uint256 epoch = _findTimestampUserEpoch(_gomboc, _user, _timestamp, maxUserEpoch);
        Point memory pt = IGombocController(gombocController).voteVeLtPointHistory(_user, _gomboc, epoch);
        return _getPointBalanceOf(pt.bias, pt.slope, _timestamp - pt.ts);
    }

    /**
     * @notice Get the VeLT voting percentage for `_user` in _gomboc  at `_timestamp`
     * @dev This function should be manually changed to "view" in the ABI
     * @param _gomboc Address to query voting gomboc
     * @param _user Address to query voting
     * @param _timestamp Epoch time
     * @return value of voting precentage normalized to 1e18
     */
    function vePrecentageForAt(address _gomboc, address _user, uint256 _timestamp) external returns (uint256) {
        IGombocController(gombocController).checkpointGomboc(_gomboc);
        _timestamp = LibTime.timesRoundedByWeek(_timestamp);
        uint256 veForAtValue = this.veForAt(_gomboc, _user, _timestamp);
        SimplePoint memory pt = IGombocController(gombocController).pointsWeight(_gomboc, _timestamp);
        if (pt.bias == 0) {
            return 0;
        }
        return (veForAtValue * 1e18) / pt.bias;
    }

    /**
     * @notice Get the HOPE balance for _gomboc  at `_weekCursor`
     * @param _gomboc Address to query voting gomboc
     * @param _weekCursor week cursor
     */
    function gombocBalancePreWeek(address _gomboc, uint256 _weekCursor) external view returns (uint256) {
        _weekCursor = LibTime.timesRoundedByWeek(_weekCursor);
        uint256 relativeWeight = IGombocController(gombocController).gombocRelativeWeight(_gomboc, _weekCursor);
        return (tokensPerWeek[_weekCursor] * relativeWeight) / 1e18;
    }

    function _findTimestampUserEpoch(
        address _gomboc,
        address user,
        uint256 _timestamp,
        uint256 maxUserEpoch
    ) internal view returns (uint256) {
        uint256 _min = 0;
        uint256 _max = maxUserEpoch;
        for (int i = 0; i < 128; i++) {
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 2) / 2;
            Point memory pt = IGombocController(gombocController).voteVeLtPointHistory(user, _gomboc, _mid);
            if (pt.ts <= _timestamp) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    /// avalid deep stack
    struct ClaimParam {
        uint256 userEpoch;
        uint256 toDistribute;
        uint256 maxUserEpoch;
        uint256 weekCursor;
        Point userPoint;
        Point oldUserPoint;
    }

    function _claim(address gomboc, address addr, uint256 _lastTokenTime) internal returns (uint256) {
        ClaimParam memory param;

        ///Minimal userEpoch is 0 (if user had no point)
        param.userEpoch = 0;
        param.toDistribute = 0;

        param.maxUserEpoch = IGombocController(gombocController).lastVoteVeLtPointEpoch(addr, gomboc);
        uint256 _startTime = startTime;
        if (param.maxUserEpoch == 0) {
            /// No lock = no fees
            return 0;
        }

        param.weekCursor = timeCursorOf[gomboc][addr];
        if (param.weekCursor == 0) {
            /// Need to do the initial binary search
            param.userEpoch = _findTimestampUserEpoch(gomboc, addr, _startTime, param.maxUserEpoch);
        } else {
            param.userEpoch = userEpochOf[gomboc][addr];
        }
        if (param.userEpoch == 0) {
            param.userEpoch = 1;
        }

        param.userPoint = IGombocController(gombocController).voteVeLtPointHistory(addr, gomboc, param.userEpoch);
        if (param.weekCursor == 0) {
            param.weekCursor = LibTime.timesRoundedByWeek(param.userPoint.ts + WEEK - 1);
        }

        if (param.weekCursor >= _lastTokenTime) {
            return 0;
        }

        if (param.weekCursor < _startTime) {
            param.weekCursor = _startTime;
        }
        param.oldUserPoint = Point({bias: 0, slope: 0, ts: 0, blk: 0});

        /// Iterate over weeks
        for (int i = 0; i < 50; i++) {
            if (param.weekCursor >= _lastTokenTime) {
                break;
            }
            if (param.weekCursor >= param.userPoint.ts && param.userEpoch <= param.maxUserEpoch) {
                param.userEpoch += 1;
                param.oldUserPoint = param.userPoint;
                if (param.userEpoch > param.maxUserEpoch) {
                    param.userPoint = Point({bias: 0, slope: 0, ts: 0, blk: 0});
                } else {
                    param.userPoint = IGombocController(gombocController).voteVeLtPointHistory(addr, gomboc, param.userEpoch);
                }
            } else {
                // Calc
                // + i * 2 is for rounding errors
                uint256 dt = param.weekCursor - param.oldUserPoint.ts;
                uint256 balanceOf = _getPointBalanceOf(param.oldUserPoint.bias, param.oldUserPoint.slope, dt);
                if (balanceOf == 0 && param.userEpoch > param.maxUserEpoch) {
                    break;
                }
                if (balanceOf > 0) {
                    SimplePoint memory pt = IGombocController(gombocController).pointsWeight(gomboc, param.weekCursor);
                    uint256 relativeWeight = IGombocController(gombocController).gombocRelativeWeight(gomboc, param.weekCursor);
                    param.toDistribute += ((balanceOf * tokensPerWeek[param.weekCursor] * relativeWeight) / pt.bias) / 1e18;
                }
                param.weekCursor += WEEK;
            }
        }

        param.userEpoch = Math.min(param.maxUserEpoch, param.userEpoch - 1);
        userEpochOf[gomboc][addr] = param.userEpoch;
        timeCursorOf[gomboc][addr] = param.weekCursor;

        emit Claimed(gomboc, addr, param.toDistribute, param.userEpoch, param.maxUserEpoch);

        return param.toDistribute;
    }

    /**
     * @notice Claim fees for `_addr`
     *  @dev Each call to claim look at a maximum of 50 user veCRV points.
         For accounts with many veCRV related actions, this function
         may need to be called more than once to claim all available
         fees. In the `Claimed` event that fires, if `claim_epoch` is
         less than `max_epoch`, the account may claim again.
         @param gomboc Address to claim fee of gomboc
         @param _addr Address to claim fees for
         @return uint256 Amount of fees claimed in the call
     *
     */
    function claim(address gomboc, address _addr) external whenNotPaused returns (uint256) {
        if (_addr == address(0)) {
            _addr = msg.sender;
        }
        uint256 _lastTokenTime = lastTokenTime;
        if (canCheckpointToken && (block.timestamp > _lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)) {
            _checkpointToken();
            _lastTokenTime = block.timestamp;
        }

        _lastTokenTime = LibTime.timesRoundedByWeek(_lastTokenTime);
        IGombocController(gombocController).checkpointGomboc(gomboc);
        uint256 amount = _claim(gomboc, _addr, _lastTokenTime);
        if (amount != 0) {
            stakingHOPEAndTransfer2User(_addr, amount);
            tokenLastBalance -= amount;
        }
        return amount;
    }

    /**
     * @notice Claim fees for `_addr`
     * @dev This function should be manually changed to "view" in the ABI
     * @param _addr Address to claim fees for
     * @return uint256 Amount of fees claimed in the call
     *
     */
    function claimableTokens(address gomboc, address _addr) external whenNotPaused returns (uint256) {
        if (_addr == address(0)) {
            _addr = msg.sender;
        }
        uint256 _lastTokenTime = lastTokenTime;
        if (canCheckpointToken && (block.timestamp > _lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)) {
            _checkpointToken();
            _lastTokenTime = block.timestamp;
        }

        _lastTokenTime = LibTime.timesRoundedByWeek(_lastTokenTime);
        IGombocController(gombocController).checkpointGomboc(gomboc);
        return _claim(gomboc, _addr, _lastTokenTime);
    }

    /**
     * @notice Make multiple fee claims in a single call
     * @dev Used to claim for many accounts at once, or to make
         multiple claims for the same address when that address
         has significant veLT history
       @param  gomboc  Address to claim fee of gomboc
     * @param _receivers List of addresses to claim for. Claiming terminates at the first `ZERO_ADDRESS`.
     * @return uint256 claim total fee
     */
    function claimMany(address gomboc, address[] memory _receivers) external whenNotPaused returns (uint256) {
        uint256 _lastTokenTime = lastTokenTime;

        if (canCheckpointToken && (block.timestamp > _lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)) {
            _checkpointToken();
            _lastTokenTime = block.timestamp;
        }

        _lastTokenTime = LibTime.timesRoundedByWeek(_lastTokenTime);
        uint256 total = 0;
        IGombocController(gombocController).checkpointGomboc(gomboc);
        for (uint256 i = 0; i < _receivers.length && i < 50; i++) {
            address addr = _receivers[i];
            if (addr == address(0)) {
                break;
            }
            uint256 amount = _claim(gomboc, addr, _lastTokenTime);
            if (amount != 0) {
                stakingHOPEAndTransfer2User(addr, amount);
                total += amount;
            }
        }

        if (total != 0) {
            tokenLastBalance -= total;
        }

        return total;
    }

    /**
     * @notice Make multiple fee claims in a single call
     * @dev This function should be manually changed to "view" in the ABI
     *  @param  gombocList  List of gombocs to claim
     * @param receiver address to claim for.
     * @return uint256 claim total fee
     */
    function claimManyGomboc(address[] memory gombocList, address receiver) external whenNotPaused returns (uint256) {
        uint256 _lastTokenTime = lastTokenTime;

        if (canCheckpointToken && (block.timestamp > _lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)) {
            _checkpointToken();
            _lastTokenTime = block.timestamp;
        }

        _lastTokenTime = LibTime.timesRoundedByWeek(_lastTokenTime);
        uint256 total = 0;

        for (uint256 i = 0; i < gombocList.length && i < 50; i++) {
            address gomboc = gombocList[i];
            if (gomboc == address(0)) {
                break;
            }
            IGombocController(gombocController).checkpointGomboc(gomboc);
            uint256 amount = _claim(gomboc, receiver, _lastTokenTime);
            if (amount != 0) {
                total += amount;
            }
        }

        if (total != 0) {
            tokenLastBalance -= total;
            stakingHOPEAndTransfer2User(receiver, total);
        }

        return total;
    }

    /**
     * @notice Make multiple fee claims in a single call
     * @dev Used to claim for many accounts at once, or to make
         multiple claims for the same address when that address
         has significant veLT history
       @param  gombocList  List of gombocs to claim
     * @param receiver address to claim for.
     * @return uint256 claim total fee
     */
    function claimableTokenManyGomboc(address[] memory gombocList, address receiver) external whenNotPaused returns (uint256) {
        return this.claimManyGomboc(gombocList, receiver);
    }

    /**
     * @notice Receive HOPE into the contract and trigger a token checkpoint
     * @param amount burn amount
     * @return bool success
     */
    function burn(uint256 amount) external whenNotPaused returns (bool) {
        if (amount != 0) {
            require(IERC20Upgradeable(token).transferFrom(msg.sender, address(this), amount), "TRANSFER_FROM_FAILED");
            if (canCheckpointToken && (block.timestamp > lastTokenTime + TOKEN_CHECKPOINT_DEADLINE)) {
                _checkpointToken();
            }
        }
        return true;
    }

    /**
     * @notice Toggle permission for checkpointing by any account
     */
    function toggleAllowCheckpointToken() external onlyOwner {
        bool flag = !canCheckpointToken;
        canCheckpointToken = !canCheckpointToken;
        emit ToggleAllowCheckpointToken(flag);
    }

    /**
     * @notice Recover ERC20 tokens from this contract
     * @dev Tokens are sent to the emergency return address.
     * @return bool success
     */
    function recoverBalance() external onlyOwner returns (bool) {
        uint256 amount = IERC20Upgradeable(token).balanceOf(address(this));
        TransferHelper.doTransferOut(token, emergencyReturn, amount);
        emit RecoverBalance(token, emergencyReturn, amount);
        return true;
    }

    /**
     * @notice Set the token emergency return address
     * @param _addr emergencyReturn address
     */
    function setEmergencyReturn(address _addr) external onlyOwner {
        emergencyReturn = _addr;
        emit SetEmergencyReturn(_addr);
    }

    function stakingHOPEAndTransfer2User(address to, uint256 amount) internal {
        require(IERC20Upgradeable(token).approve(stHOPE, amount), "APPROVE_FAILED");
        bool success = IStakingHOPE(stHOPE).staking(amount, 0, 0, "");
        require(success, "staking hope fail");
        TransferHelper.doTransferOut(stHOPE, to, amount);
    }

    function _getPointBalanceOf(int256 bias, int256 slope, uint256 dt) internal pure returns (uint256) {
        uint256 currentBias = uint256(slope) * dt;
        uint256 oldBias = uint256(bias);
        if (currentBias > oldBias) {
            return 0;
        }
        return oldBias - currentBias;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IBurner.sol";

interface ISwapRouter {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract HopeSwapBurner is IBurner, Ownable2Step {
    event SetRouters(ISwapRouter[] _routers);

    ISwapRouter[] public routers;
    IERC20 public immutable HOPE;
    address public immutable feeVault;
    mapping(ISwapRouter => mapping(IERC20 => bool)) public approved;

    constructor(IERC20 _HOPE, address _feeVault) {
        HOPE = _HOPE;
        feeVault = _feeVault;
    }

    /**
     * @notice Set routers
     * @param _routers routers implment ISwapRouter
     */
    function setRouters(ISwapRouter[] calldata _routers) external onlyOwner {
        require(_routers.length != 0, "invalid param");
        for (uint i = 0; i < routers.length; i++) {
            require(address(routers[i]) != address(0), "invalid address");
        }
        routers = _routers;
        emit SetRouters(_routers);
    }

    function burn(address to, IERC20 token, uint amount, uint amountOutMin) external {
        require(msg.sender == feeVault, "LSB04");

        if (token == HOPE) {
            require(token.transferFrom(msg.sender, to, amount), "LSB00");
            return;
        }

        uint256 balanceBefore = token.balanceOf(address(this));
        require(token.transferFrom(msg.sender, address(this), amount), "LSB01");
        uint256 balanceAfter = token.balanceOf(address(this));
        uint256 spendAmount = balanceAfter - balanceBefore;

        ISwapRouter bestRouter = routers[0];
        uint bestExpected = 0;
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(HOPE);

        for (uint i = 0; i < routers.length; i++) {
            uint[] memory expected = routers[i].getAmountsOut(spendAmount, path);
            if (expected[0] > bestExpected) {
                bestExpected = expected[0];
                bestRouter = routers[i];
            }
        }

        require(bestExpected >= amountOutMin, "LSB02");
        if (!approved[bestRouter][token]) {
            bool success = IERC20(token).approve(address(bestRouter), type(uint).max);
            require(success, "LSB03");
            approved[bestRouter][token] = true;
        }

        bestRouter.swapExactTokensForTokens(spendAmount, 0, path, to, block.timestamp);
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../feeDistributor/BurnerManager.sol";

interface SwapPair {
    function mintFee() external;

    function burn(address to) external returns (uint amount0, uint amount1);

    function balanceOf(address account) external returns (uint256);

    function transfer(address to, uint value) external returns (bool);
}

contract SwapFeeToVault is Ownable2Step, Pausable {
    BurnerManager public burnerManager;
    address public underlyingBurner;

    constructor(BurnerManager _burnerManager, address _underlyingBurner) {
        require(address(_burnerManager) != address(0), "Invalid Address");
        require(_underlyingBurner != address(0), "Invalid Address");

        burnerManager = _burnerManager;
        underlyingBurner = _underlyingBurner;
    }

    function withdrawAdminFee(address pool) external whenNotPaused {
        SwapPair pair = SwapPair(pool);
        pair.mintFee();
        uint256 tokenPBalance = SwapPair(pool).balanceOf(address(this));
        if (tokenPBalance > 0) {
            pair.transfer(address(pair), tokenPBalance);
            pair.burn(address(this));
        }
    }

    function withdrawMany(address[] memory pools) external whenNotPaused {
        for (uint256 i = 0; i < pools.length && i < 256; i++) {
            this.withdrawAdminFee(pools[i]);
        }
    }

    function _burn(IERC20 token, uint amountOutMin) internal {
        uint256 amount = token.balanceOf(address(this));
        // user choose to not burn token if not profitable
        if (amount > 0) {
            IBurner burner = burnerManager.burners(address(token));
            require(token.approve(address(burner), amount), "SFTV00");
            require(burner != IBurner(address(0)), "SFTV01");
            burner.burn(underlyingBurner, token, amount, amountOutMin);
        }
    }

    function burn(IERC20 token, uint amountOutMin) external whenNotPaused {
        require(msg.sender == tx.origin, "SFTV02");
        _burn(token, amountOutMin);
    }

    function burnMany(IERC20[] calldata tokens, uint[] calldata amountOutMin) external whenNotPaused {
        require(msg.sender == tx.origin, "SFTV02");
        for (uint i = 0; i < tokens.length && i < 128; i++) {
            _burn(tokens[i], amountOutMin[i]);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";

interface IFeeDistributor {
    function burn(uint256 amount) external returns (bool);
}

interface ISwapRouter {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract UnderlyingBurner is Ownable2StepUpgradeable, PausableUpgradeable {
    event ToFeeDistributor(address indexed feeDistributor, uint256 amount);

    event RecoverBalance(address indexed token, address indexed emergencyReturn, uint256 amount);

    event SetEmergencyReturn(address indexed emergencyReturn);

    event SetRouters(ISwapRouter[] _routers);

    address public feeDistributor;
    address public gombocFeeDistributor;
    address public emergencyReturn;
    address public hopeToken;

    ISwapRouter[] public routers;
    mapping(ISwapRouter => mapping(IERC20Upgradeable => bool)) public approved;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Contract constructor
     * @param _hopeToken HOPE token address
     * @param _feeDistributor total feeDistributor address
     * @param _gombocFeeDistributor gomboc feeDistributor address
     * @param _emergencyReturn Address to transfer `_token` balance to if this contract is killed
     */
    function initialize(
        address _hopeToken,
        address _feeDistributor,
        address _gombocFeeDistributor,
        address _emergencyReturn
    ) external initializer {
        require(_hopeToken != address(0), "Invalid Address");
        require(_feeDistributor != address(0), "Invalid Address");
        require(_gombocFeeDistributor != address(0), "Invalid Address");

        __Ownable2Step_init();

        hopeToken = _hopeToken;
        feeDistributor = _feeDistributor;
        gombocFeeDistributor = _gombocFeeDistributor;
        emergencyReturn = _emergencyReturn;

        IERC20Upgradeable(hopeToken).approve(feeDistributor, 2 ** 256 - 1);
        IERC20Upgradeable(hopeToken).approve(gombocFeeDistributor, 2 ** 256 - 1);
    }

    /**
     * @notice  transfer HOPE to the fee distributor and  gomboc fee distributor 50% each
     */
    function transferHopeToFeeDistributor() external whenNotPaused returns (uint256) {
        uint256 balance = IERC20Upgradeable(hopeToken).balanceOf(address(this));
        require(balance > 0, "insufficient balance");

        uint256 amount = balance / 2;

        IFeeDistributor(feeDistributor).burn(amount);
        IFeeDistributor(gombocFeeDistributor).burn(amount);

        emit ToFeeDistributor(feeDistributor, amount);
        emit ToFeeDistributor(gombocFeeDistributor, amount);
        return amount * 2;
    }

    /**
     * @notice Recover ERC20 tokens from this contract
     * @dev Tokens are sent to the emergency return address.
     * @return bool success
     */
    function recoverBalance(address token) external onlyOwner returns (bool) {
        uint256 amount = IERC20Upgradeable(token).balanceOf(address(this));
        TransferHelper.doTransferOut(token, emergencyReturn, amount);
        emit RecoverBalance(token, emergencyReturn, amount);
        return true;
    }

    /**
     * @notice Set routers
     * @param _routers routers implment ISwapRouter
     */
    function setRouters(ISwapRouter[] calldata _routers) external onlyOwner {
        require(_routers.length != 0, "invalid param");
        for (uint i = 0; i < routers.length; i++) {
            require(address(routers[i]) != address(0), "invalid address");
        }
        routers = _routers;
        emit SetRouters(_routers);
    }

    function burn(IERC20Upgradeable token, uint amount, uint amountOutMin) external {
        require(msg.sender == tx.origin, "not EOA");
        require(address(token) != hopeToken, "HOPE dosent need burn");

        ISwapRouter bestRouter = routers[0];
        uint bestExpected = 0;
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(hopeToken);

        for (uint i = 0; i < routers.length; i++) {
            uint[] memory expected = routers[i].getAmountsOut(amount, path);
            if (expected[0] > bestExpected) {
                bestExpected = expected[0];
                bestRouter = routers[i];
            }
        }

        require(bestExpected >= amountOutMin, "less than expected");
        if (!approved[bestRouter][token]) {
            bool success = IERC20Upgradeable(token).approve(address(bestRouter), type(uint).max);
            require(success, "approve failed");
            approved[bestRouter][token] = true;
        }

        bestRouter.swapExactTokensForTokens(amount, 0, path, address(this), block.timestamp);
    }

    /**
     * @notice Set the token emergency return address
     * @param _addr emergencyReturn address
     */
    function setEmergencyReturn(address _addr) external onlyOwner {
        require(_addr != address(0), "CE000");
        emergencyReturn = _addr;
        emit SetEmergencyReturn(_addr);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IGombocController.sol";
import "./interfaces/IVotingEscrow.sol";
import "light-lib/contracts/LibTime.sol";

contract GombocController is Ownable2Step, IGombocController {
    // 7 * 86400 seconds - all future times are rounded by week
    uint256 private constant _DAY = 86400;
    uint256 private constant _WEEK = _DAY * 7;
    // Cannot change weight votes more often than once in 10 days
    uint256 private constant _WEIGHT_VOTE_DELAY = 10 * _DAY;

    uint256 private constant _MULTIPLIER = 10 ** 18;

    // lt token
    address public immutable token;
    // veLT token
    address public immutable override votingEscrow;

    // Gomboc parameters
    // All numbers are "fixed point" on the basis of 1e18
    int128 public nGombocTypes;
    int128 public nGomboc;
    mapping(int128 => string) public gombocTypeNames;

    // Needed for enumeration
    mapping(uint256 => address) public gombocs;

    // we increment values by 1 prior to storing them here so we can rely on a value
    // of zero as meaning the gomboc has not been set
    mapping(address => int128) private _gombocTypes;

    // user -> gombocAddr -> VotedSlope
    mapping(address => mapping(address => VotedSlope)) public voteUserSlopes;
    // Total vote power used by user
    mapping(address => uint256) public voteUserPower;
    // Last user vote's timestamp for each gomboc address
    mapping(address => mapping(address => uint256)) public lastUserVote;

    // user -> gombocAddr -> epoch -> Point
    mapping(address => mapping(address => mapping(uint256 => UserPoint))) public voteVeLtPointHistory;
    // user -> gombocAddr -> lastEpoch
    mapping(address => mapping(address => uint256)) public lastVoteVeLtPointEpoch;

    // Past and scheduled points for gomboc weight, sum of weights per type, total weight
    // Point is for bias+slope
    // changes_* are for changes in slope
    // time_* are for the last change timestamp
    // timestamps are rounded to whole weeks

    // gombocAddr -> time -> Point
    mapping(address => mapping(uint256 => Point)) public pointsWeight;
    // gombocAddr -> time -> slope
    mapping(address => mapping(uint256 => uint256)) private _changesWeight;
    // gombocAddr -> last scheduled time (next week)
    mapping(address => uint256) public timeWeight;

    //typeId -> time -> Point
    mapping(int128 => mapping(uint256 => Point)) public pointsSum;
    // typeId -> time -> slope
    mapping(int128 => mapping(uint256 => uint256)) public changesSum;
    //typeId -> last scheduled time (next week)
    mapping(uint256 => uint256) public timeSum;

    // time -> total weight
    mapping(uint256 => uint256) public pointsTotal;
    // last scheduled time
    uint256 public timeTotal;

    // typeId -> time -> type weight
    mapping(int128 => mapping(uint256 => uint256)) public pointsTypeWeight;
    // typeId -> last scheduled time (next week)
    mapping(uint256 => uint256) public timeTypeWeight;

    /**
     * @notice Contract constructor
     * @param tokenAddress  LT contract address
     * @param votingEscrowAddress veLT contract address
     */
    constructor(address tokenAddress, address votingEscrowAddress) {
        require(tokenAddress != address(0), "CE000");
        require(votingEscrowAddress != address(0), "CE000");

        token = tokenAddress;
        votingEscrow = votingEscrowAddress;
        timeTotal = LibTime.timesRoundedByWeek(block.timestamp);
    }

    /**
     * @notice Get gomboc type for address
     *  @param _addr Gomboc address
     * @return Gomboc type id
     */
    function gombocTypes(address _addr) external view override returns (int128) {
        int128 gombocType = _gombocTypes[_addr];
        require(gombocType != 0, "CE000");
        return gombocType - 1;
    }

    /**
     * @notice Add gomboc `addr` of type `gombocType` with weight `weight`
     * @param addr Gomboc address
     * @param gombocType Gomboc type
     * @param weight Gomboc weight
     */
    function addGomboc(address addr, int128 gombocType, uint256 weight) external override onlyOwner {
        require(gombocType >= 0 && gombocType < nGombocTypes, "GC001");
        require(_gombocTypes[addr] == 0, "GC002");

        int128 n = nGomboc;
        nGomboc = n + 1;
        gombocs[_int128ToUint256(n)] = addr;

        _gombocTypes[addr] = gombocType + 1;
        uint256 nextTime = LibTime.timesRoundedByWeek(block.timestamp + _WEEK);

        if (weight > 0) {
            uint256 _typeWeight = _getTypeWeight(gombocType);
            uint256 _oldSum = _getSum(gombocType);
            uint256 _oldTotal = _getTotal();

            pointsSum[gombocType][nextTime].bias = weight + _oldSum;
            timeSum[_int128ToUint256(gombocType)] = nextTime;
            pointsTotal[nextTime] = _oldTotal + _typeWeight * weight;
            timeTotal = nextTime;

            pointsWeight[addr][nextTime].bias = weight;
        }

        if (timeSum[_int128ToUint256(gombocType)] == 0) {
            timeSum[_int128ToUint256(gombocType)] = nextTime;
        }
        timeWeight[addr] = nextTime;

        emit NewGomboc(addr, gombocType, weight);
    }

    /**
     * @notice Checkpoint to fill data common for all gombocs
     */
    function checkpoint() external override {
        _getTotal();
    }

    /**
     * @notice Checkpoint to fill data for both a specific gomboc and common for all gomboc
     * @param addr Gomboc address
     */
    function checkpointGomboc(address addr) external override {
        _getWeight(addr);
        _getTotal();
    }

    /**
     * @notice Get Gomboc relative weight (not more than 1.0) normalized to 1e18(e.g. 1.0 == 1e18). Inflation which will be received by
     * it is inflation_rate * relative_weight / 1e18
     * @param gombocAddress Gomboc address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gombocRelativeWeight(address gombocAddress, uint256 time) external view override returns (uint256) {
        return _gombocRelativeWeight(gombocAddress, time);
    }

    /**
     *  @notice Get gomboc weight normalized to 1e18 and also fill all the unfilled values for type and gomboc records
     * @dev Any address can call, however nothing is recorded if the values are filled already
     * @param gombocAddress Gomboc address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gombocRelativeWeightWrite(address gombocAddress, uint256 time) external override returns (uint256) {
        _getWeight(gombocAddress);
        // Also calculates get_sum;
        _getTotal();
        return _gombocRelativeWeight(gombocAddress, time);
    }

    /**
     * @notice Add gomboc type with name `_name` and weight `weight`
     * @dev only owner call
     * @param _name Name of gomboc type
     * @param weight Weight of gomboc type
     */
    function addType(string memory _name, uint256 weight) external override onlyOwner {
        int128 typeId = nGombocTypes;
        gombocTypeNames[typeId] = _name;
        nGombocTypes = typeId + 1;
        if (weight != 0) {
            _changeTypeWeight(typeId, weight);
        }
        emit AddType(_name, typeId);
    }

    /**
     * @notice Change gomboc type `typeId` weight to `weight`
     * @dev only owner call
     * @param typeId Gomboc type id
     * @param weight New Gomboc weight
     */
    function changeTypeWeight(int128 typeId, uint256 weight) external override onlyOwner {
        _changeTypeWeight(typeId, weight);
    }

    /**
     * @notice Change weight of gomboc `addr` to `weight`
     * @param gombocAddress `Gomboc` contract address
     * @param weight New Gomboc weight
     */
    function changeGombocWeight(address gombocAddress, uint256 weight) external override onlyOwner {
        int128 gombocType = _gombocTypes[gombocAddress] - 1;
        require(gombocType >= 0, "GC000");
        _changeGombocWeight(gombocAddress, weight);
    }

    /**
     * @notice Allocate voting power for changing pool weights
     * @param gombocAddressList Gomboc of list which `msg.sender` votes for
     * @param userWeightList Weight of list for a gomboc in bps (units of 0.01%). Minimal is 0.01%.
     */
    function batchVoteForGombocWeights(address[] memory gombocAddressList, uint256[] memory userWeightList) public {
        require(gombocAddressList.length == userWeightList.length, "GC007");
        for (uint256 i = 0; i < gombocAddressList.length && i < 128; i++) {
            voteForGombocWeights(gombocAddressList[i], userWeightList[i]);
        }
    }

    //avoid Stack too deep
    struct VoteForGombocWeightsParam {
        VotedSlope oldSlope;
        VotedSlope newSlope;
        uint256 oldDt;
        uint256 oldBias;
        uint256 newDt;
        uint256 newBias;
        UserPoint newUserPoint;
    }

    /**
     * @notice Allocate voting power for changing pool weights
     * @param gombocAddress Gomboc which `msg.sender` votes for
     * @param userWeight Weight for a gomboc in bps (units of 0.01%). Minimal is 0.01%.
     *        example: 10%=1000,3%=300,0.01%=1,100%=10000
     */
    function voteForGombocWeights(address gombocAddress, uint256 userWeight) public override {
        int128 gombocType = _gombocTypes[gombocAddress] - 1;
        require(gombocType >= 0, "GC000");

        uint256 slope = uint256(IVotingEscrow(votingEscrow).getLastUserSlope(msg.sender));
        uint256 lockEnd = IVotingEscrow(votingEscrow).lockedEnd(msg.sender);
        uint256 nextTime = LibTime.timesRoundedByWeek(block.timestamp + _WEEK);
        require(lockEnd > nextTime, "GC003");
        require(userWeight >= 0 && userWeight <= 10000, "GC004");
        require(block.timestamp >= lastUserVote[msg.sender][gombocAddress] + _WEIGHT_VOTE_DELAY, "GC005");

        VoteForGombocWeightsParam memory param;

        // Prepare slopes and biases in memory
        param.oldSlope = voteUserSlopes[msg.sender][gombocAddress];
        param.oldDt = 0;
        if (param.oldSlope.end > nextTime) {
            param.oldDt = param.oldSlope.end - nextTime;
        }
        param.oldBias = param.oldSlope.slope * param.oldDt;

        param.newSlope = VotedSlope({slope: (slope * userWeight) / 10000, end: lockEnd, power: userWeight});

        // dev: raises when expired
        param.newDt = lockEnd - nextTime;
        param.newBias = param.newSlope.slope * param.newDt;
        param.newUserPoint = UserPoint({bias: param.newBias, slope: param.newSlope.slope, ts: nextTime, blk: block.number});

        // Check and update powers (weights) used
        uint256 powerUsed = voteUserPower[msg.sender];
        powerUsed = powerUsed + param.newSlope.power - param.oldSlope.power;
        voteUserPower[msg.sender] = powerUsed;
        require((powerUsed >= 0) && (powerUsed <= 10000), "GC006");

        //// Remove old and schedule new slope changes
        // Remove slope changes for old slopes
        // Schedule recording of initial slope for nextTime
        uint256 oldWeightBias = _getWeight(gombocAddress);
        uint256 oldWeightSlope = pointsWeight[gombocAddress][nextTime].slope;
        uint256 oldSumBias = _getSum(gombocType);
        uint256 oldSumSlope = pointsSum[gombocType][nextTime].slope;

        pointsWeight[gombocAddress][nextTime].bias = Math.max(oldWeightBias + param.newBias, param.oldBias) - param.oldBias;
        pointsSum[gombocType][nextTime].bias = Math.max(oldSumBias + param.newBias, param.oldBias) - param.oldBias;

        if (param.oldSlope.end > nextTime) {
            pointsWeight[gombocAddress][nextTime].slope =
                Math.max(oldWeightSlope + param.newSlope.slope, param.oldSlope.slope) -
                param.oldSlope.slope;
            pointsSum[gombocType][nextTime].slope =
                Math.max(oldSumSlope + param.newSlope.slope, param.oldSlope.slope) -
                param.oldSlope.slope;
        } else {
            pointsWeight[gombocAddress][nextTime].slope += param.newSlope.slope;
            pointsSum[gombocType][nextTime].slope += param.newSlope.slope;
        }

        if (param.oldSlope.end > block.timestamp) {
            // Cancel old slope changes if they still didn't happen
            _changesWeight[gombocAddress][param.oldSlope.end] -= param.oldSlope.slope;
            changesSum[gombocType][param.oldSlope.end] -= param.oldSlope.slope;
        }

        //Add slope changes for new slopes
        _changesWeight[gombocAddress][param.newSlope.end] += param.newSlope.slope;
        changesSum[gombocType][param.newSlope.end] += param.newSlope.slope;

        _getTotal();

        voteUserSlopes[msg.sender][gombocAddress] = param.newSlope;

        // Record last action time
        lastUserVote[msg.sender][gombocAddress] = block.timestamp;

        //record user point history
        uint256 voteVeLtPointEpoch = lastVoteVeLtPointEpoch[msg.sender][gombocAddress] + 1;
        voteVeLtPointHistory[msg.sender][gombocAddress][voteVeLtPointEpoch] = param.newUserPoint;
        lastVoteVeLtPointEpoch[msg.sender][gombocAddress] = voteVeLtPointEpoch;

        emit VoteForGomboc(msg.sender, gombocAddress, block.timestamp, userWeight);
    }

    /**
     * @notice Get current gomboc weight
     * @param addr Gomboc address
     * @return Gomboc weight
     */
    function getGombocWeight(address addr) external view override returns (uint256) {
        return pointsWeight[addr][timeWeight[addr]].bias;
    }

    /**
     * @notice Get current type weight
     * @param typeId Type id
     * @return Type weight
     */
    function getTypeWeight(int128 typeId) external view override returns (uint256) {
        return pointsTypeWeight[typeId][timeTypeWeight[_int128ToUint256(typeId)]];
    }

    /**
     * @notice Get current total (type-weighted) weight
     * @return Total weight
     */
    function getTotalWeight() external view override returns (uint256) {
        return pointsTotal[timeTotal];
    }

    /**
     * @notice Get sum of gomboc weights per type
     * @param typeId Type id
     * @return Sum of gomboc weights
     */
    function getWeightsSumPreType(int128 typeId) external view override returns (uint256) {
        return pointsSum[typeId][timeSum[_int128ToUint256(typeId)]].bias;
    }

    /**
     * @notice Fill historic type weights week-over-week for missed checkins and return the type weight for the future week
     * @param gombocType Gomboc type id
     * @return Type weight
     */
    function _getTypeWeight(int128 gombocType) internal returns (uint256) {
        uint256 t = timeTypeWeight[_int128ToUint256(gombocType)];
        if (t <= 0) {
            return 0;
        }

        uint256 w = pointsTypeWeight[gombocType][t];
        for (uint256 i = 0; i < 500; i++) {
            if (t > block.timestamp) {
                break;
            }
            t += _WEEK;
            pointsTypeWeight[gombocType][t] = w;
            if (t > block.timestamp) {
                timeTypeWeight[_int128ToUint256(gombocType)] = t;
            }
        }
        return w;
    }

    /**
     * @notice Fill sum of gomboc weights for the same type week-over-week for missed checkins and return the sum for the future week
     * @param gombocType Gomboc type id
     * @return Sum of weights
     */
    function _getSum(int128 gombocType) internal returns (uint256) {
        uint256 ttype = _int128ToUint256(gombocType);
        uint256 t = timeSum[ttype];
        if (t <= 0) {
            return 0;
        }

        Point memory pt = pointsSum[gombocType][t];
        for (uint256 i = 0; i < 500; i++) {
            if (t > block.timestamp) {
                break;
            }
            t += _WEEK;
            uint256 dBias = pt.slope * _WEEK;
            if (pt.bias > dBias) {
                pt.bias -= dBias;
                uint256 dSlope = changesSum[gombocType][t];
                pt.slope -= dSlope;
            } else {
                pt.bias = 0;
                pt.slope = 0;
            }
            pointsSum[gombocType][t] = pt;
            if (t > block.timestamp) {
                timeSum[ttype] = t;
            }
        }
        return pt.bias;
    }

    /**
     * @notice Fill historic total weights week-over-week for missed checkins and return the total for the future week
     * @return Total weight
     */
    function _getTotal() internal returns (uint256) {
        uint256 t = timeTotal;
        int128 _nGombocTypes = nGombocTypes;
        if (t > block.timestamp) {
            // If we have already checkpointed - still need to change the value
            t -= _WEEK;
        }
        uint256 pt = pointsTotal[t];

        for (int128 gombocType = 0; gombocType < 100; gombocType++) {
            if (gombocType == _nGombocTypes) {
                break;
            }
            _getSum(gombocType);
            _getTypeWeight(gombocType);
        }

        for (uint256 i = 0; i < 500; i++) {
            if (t > block.timestamp) {
                break;
            }
            t += _WEEK;
            pt = 0;
            // Scales as n_types * n_unchecked_weeks (hopefully 1 at most)
            for (int128 gombocType = 0; gombocType < 100; gombocType++) {
                if (gombocType == _nGombocTypes) {
                    break;
                }
                uint256 typeSum = pointsSum[gombocType][t].bias;
                uint256 typeWeight = pointsTypeWeight[gombocType][t];
                pt += typeSum * typeWeight;
            }

            pointsTotal[t] = pt;
            if (t > block.timestamp) {
                timeTotal = t;
            }
        }

        return pt;
    }

    /**
     * @notice Fill historic gomboc weights week-over-week for missed checkins and return the total for the future week
     * @param gombocAddr Address of the gomboc
     * @return Gomboc weight
     */
    function _getWeight(address gombocAddr) internal returns (uint256) {
        uint256 t = timeWeight[gombocAddr];

        if (t <= 0) {
            return 0;
        }
        Point memory pt = pointsWeight[gombocAddr][t];
        for (uint256 i = 0; i < 500; i++) {
            if (t > block.timestamp) {
                break;
            }
            t += _WEEK;
            uint256 dBias = pt.slope * _WEEK;
            if (pt.bias > dBias) {
                pt.bias -= dBias;
                uint256 dSlope = _changesWeight[gombocAddr][t];
                pt.slope -= dSlope;
            } else {
                pt.bias = 0;
                pt.slope = 0;
            }
            pointsWeight[gombocAddr][t] = pt;
            if (t > block.timestamp) {
                timeWeight[gombocAddr] = t;
            }
        }
        return pt.bias;
    }

    /**
     * @notice Get Gomboc relative weight (not more than 1.0) normalized to 1e18 (e.g. 1.0 == 1e18).
     * Inflation which will be received by it is inflation_rate * relative_weight / 1e18
     * @param addr Gomboc address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function _gombocRelativeWeight(address addr, uint256 time) internal view returns (uint256) {
        uint256 t = LibTime.timesRoundedByWeek(time);
        uint256 _totalWeight = pointsTotal[t];
        if (_totalWeight <= 0) {
            return 0;
        }

        int128 gombocType = _gombocTypes[addr] - 1;
        uint256 _typeWeight = pointsTypeWeight[gombocType][t];
        uint256 _gombocWeight = pointsWeight[addr][t].bias;
        return (_MULTIPLIER * _typeWeight * _gombocWeight) / _totalWeight;
    }

    function _changeGombocWeight(address addr, uint256 weight) internal {
        // Change gomboc weight
        //Only needed when testing in reality
        int128 gombocType = _gombocTypes[addr] - 1;
        uint256 oldGombocWeight = _getWeight(addr);
        uint256 typeWeight = _getTypeWeight(gombocType);
        uint256 oldSum = _getSum(gombocType);
        uint256 _totalWeight = _getTotal();
        uint256 nextTime = LibTime.timesRoundedByWeek(block.timestamp + _WEEK);

        pointsWeight[addr][nextTime].bias = weight;
        timeWeight[addr] = nextTime;

        uint256 newSum = oldSum + weight - oldGombocWeight;
        pointsSum[gombocType][nextTime].bias = newSum;
        timeSum[_int128ToUint256(gombocType)] = nextTime;

        _totalWeight = _totalWeight + newSum * typeWeight - oldSum * typeWeight;
        pointsTotal[nextTime] = _totalWeight;
        timeTotal = nextTime;

        emit NewGombocWeight(addr, block.timestamp, weight, _totalWeight);
    }

    /**
     *  @notice Change type weight
     * @param typeId Type id
     * @param weight New type weight
     */
    function _changeTypeWeight(int128 typeId, uint256 weight) internal {
        uint256 oldWeight = _getTypeWeight(typeId);
        uint256 oldSum = _getSum(typeId);
        uint256 _totalWeight = _getTotal();
        uint256 nextTime = LibTime.timesRoundedByWeek(block.timestamp + _WEEK);

        _totalWeight = _totalWeight + oldSum * weight - oldSum * oldWeight;
        pointsTotal[nextTime] = _totalWeight;
        pointsTypeWeight[typeId][nextTime] = weight;
        timeTotal = nextTime;
        timeTypeWeight[_int128ToUint256(typeId)] = nextTime;

        emit NewTypeWeight(typeId, nextTime, weight, _totalWeight);
    }

    function _int128ToUint256(int128 from) internal pure returns (uint256) {
        return uint256(uint128(from));
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IMinter.sol";

interface ILightGomboc {
    function depositRewardToken(address rewardToken, uint256 amount) external;

    function claimableTokens(address addr) external returns (uint256);
}

/**
 *  the contract which escrow stHOPE should inherit `AbsExternalLTReward`
 */
abstract contract AbsExternalLTRewardDistributor {
    address private _stHopeGomboc;
    address private _minter;
    address private _ltToken;
    address private _gombocAddress;

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    event RewardsDistributed(uint256 claimableTokens);

    function _init(address stHopeGomboc, address minter, address ltToken) internal {
        require(stHopeGomboc != address(0), "CE000");
        require(minter != address(0), "CE000");
        require(ltToken != address(0), "CE000");
        require(!_initialized, "Initializable: contract is already initialized");
        _initialized = true;
        _stHopeGomboc = stHopeGomboc;
        _minter = minter;
        _ltToken = ltToken;
    }

    function refreshGombocRewards() external {
        require(_gombocAddress != address(0), "please set gombocAddress first");

        uint256 claimableTokens = ILightGomboc(_stHopeGomboc).claimableTokens(address(this));
        require(claimableTokens > 0, "Noting Token to Deposit");

        IMinter(_minter).mint(_stHopeGomboc);

        bool success = IERC20(_ltToken).approve(_gombocAddress, claimableTokens);
        require(success, "APPROVE FAILED");
        ILightGomboc(_gombocAddress).depositRewardToken(_ltToken, claimableTokens);

        emit RewardsDistributed(claimableTokens);
    }

    function _setGombocAddress(address gombocAddress) internal {
        _gombocAddress = gombocAddress;
    }
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/ILT.sol";
import "../interfaces/IGombocController.sol";
import "../interfaces/IVotingEscrow.sol";
import "../interfaces/IMinter.sol";
import "light-lib/contracts/LibTime.sol";

abstract contract AbsGomboc is Ownable2Step {
    event Deposit(address indexed provider, uint256 value);
    event Withdraw(address indexed provider, uint256 value);
    event UpdateLiquidityLimit(
        address user,
        uint256 originalBalance,
        uint256 originalSupply,
        uint256 workingBalance,
        uint256 workingSupply,
        uint256 votingBalance,
        uint256 votingTotal
    );
    event SetPermit2Address(address oldAddress, address newAddress);

    uint256 internal constant _TOKENLESS_PRODUCTION = 40;
    uint256 internal constant _DAY = 86400;
    uint256 internal constant _WEEK = _DAY * 7;

    bool public isKilled;
    // pool lp token
    address public lpToken;

    //Contracts
    IMinter public minter;
    // lt_token
    ILT public ltToken;
    //IERC20 public template;
    IGombocController public controller;
    IVotingEscrow public votingEscrow;

    uint256 public futureEpochTime;

    mapping(address => uint256) public workingBalances;
    uint256 public workingSupply;

    // The goal is to be able to calculate ∫(rate * balance / totalSupply dt) from 0 till checkpoint
    // All values are kept in units of being multiplied by 1e18
    uint256 public period; //modified from "int256 public period" since it never be minus.

    // uint256[100000000000000000000000000000] public period_timestamp;
    mapping(uint256 => uint256) public periodTimestamp;

    //uint256[100_000_000_000_000_000_000_000_000_000] public periodTimestamp;

    // 1e18 * ∫(rate(t) / totalSupply(t) dt) from 0 till checkpoint
    // bump epoch when rate() changes
    mapping(uint256 => uint256) integrateInvSupply;

    // 1e18 * ∫(rate(t) / totalSupply(t) dt) from (last_action) till checkpoint
    mapping(address => uint256) public integrateInvSupplyOf;
    mapping(address => uint256) public integrateCheckpointOf;

    // ∫(balance * rate(t) / totalSupply(t) dt) from 0 till checkpoint
    // Units rate * t = already number of coins per address to issue
    mapping(address => uint256) public integrateFraction; //Mintable Token amount (include minted amount)

    uint256 public inflationRate;

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    function _init(address _lpAddr, address _minter, address _owner) internal {
        require(_lpAddr != address(0), "CE000");
        require(_minter != address(0), "CE000");
        require(_owner != address(0), "CE000");
        require(!_initialized, "Initializable: contract is already initialized");
        _initialized = true;

        _transferOwnership(_owner);

        lpToken = _lpAddr;
        minter = IMinter(_minter);
        address _ltToken = minter.token();
        ltToken = ILT(_ltToken);
        controller = IGombocController(minter.controller());
        votingEscrow = IVotingEscrow(controller.votingEscrow());
        periodTimestamp[0] = block.timestamp;
        inflationRate = ltToken.rate();
        futureEpochTime = ltToken.futureEpochTimeWrite();
    }

    /***
     * @notice Calculate limits which depend on the amount of lp Token per-user.
     *        Effectively it calculates working balances to apply amplification
     *        of LT production by LT
     * @param _addr User address
     * @param _l User's amount of liquidity (LP tokens)
     * @param _L Total amount of liquidity (LP tokens)
     */
    function _updateLiquidityLimit(address _addr, uint256 _l, uint256 _L) internal {
        // To be called after totalSupply is updated
        uint256 _votingBalance = votingEscrow.balanceOfAtTime(_addr, block.timestamp);
        uint256 _votingTotal = votingEscrow.totalSupplyAtTime(block.timestamp);

        uint256 _lim = (_l * _TOKENLESS_PRODUCTION) / 100;
        if (_votingTotal > 0) {
            // 0.4 * _l + 0.6 * _L * balance/total
            _lim += (_L * _votingBalance * (100 - _TOKENLESS_PRODUCTION)) / _votingTotal / 100;
        }

        _lim = Math.min(_l, _lim);
        uint256 _oldBal = workingBalances[_addr];
        workingBalances[_addr] = _lim;
        uint256 _workingSupply = workingSupply + _lim - _oldBal;
        workingSupply = _workingSupply;

        emit UpdateLiquidityLimit(_addr, _l, _L, _lim, _workingSupply, _votingBalance, _votingTotal);
    }

    //to avoid "stack too deep"
    struct CheckPointParameters {
        uint256 _period;
        uint256 _periodTime;
        uint256 _integrateInvSupply;
        uint256 rate;
        uint256 newRate;
        uint256 prevFutureEpoch;
    }

    /***
     * @notice Checkpoint for a user
     * @param _addr User address
     *
     *This function does,
     *1. Calculate Iis for All: Calc and add Iis for every week. Iis only increses over time.
     *2. Calculate Iu for _addr: Calc by (defferece between Iis(last time) and Iis(this time))* LP deposit amount of _addr(include  locking boost)
     *
     * working_supply & working_balance = total_supply & total_balance with  locking boost。
     * Check whitepaper about Iis and Iu.
     */
    function _checkpoint(address _addr) internal {
        CheckPointParameters memory _st;

        _st._period = period;
        _st._periodTime = periodTimestamp[_st._period];
        _st._integrateInvSupply = integrateInvSupply[_st._period];
        _st.rate = inflationRate;
        _st.newRate = _st.rate;
        _st.prevFutureEpoch = futureEpochTime;
        if (_st.prevFutureEpoch >= _st._periodTime) {
            //update future_epoch_time & inflation_rate
            futureEpochTime = ltToken.futureEpochTimeWrite();
            _st.newRate = ltToken.rate();
            inflationRate = _st.newRate;
        }
        controller.checkpointGomboc(address(this));

        if (isKilled) {
            // Stop distributing inflation as soon as killed
            _st.rate = 0;
        }

        // Update integral of 1/supply
        if (block.timestamp > _st._periodTime) {
            uint256 _workingSupply = workingSupply;
            uint256 _prevWeekTime = _st._periodTime;
            uint256 _weekTime = Math.min(LibTime.timesRoundedByWeek(_st._periodTime + _WEEK), block.timestamp);
            for (uint256 i; i < 500; i++) {
                uint256 _dt = _weekTime - _prevWeekTime;
                uint256 _w = controller.gombocRelativeWeight(address(this), LibTime.timesRoundedByWeek(_prevWeekTime));

                if (_workingSupply > 0) {
                    if (_st.prevFutureEpoch >= _prevWeekTime && _st.prevFutureEpoch < _weekTime) {
                        // If we went across one or multiple epochs, apply the rate
                        // of the first epoch until it ends, and then the rate of
                        // the last epoch.
                        // If more than one epoch is crossed - the gauge gets less,
                        // but that'd meen it wasn't called for more than 1 year
                        _st._integrateInvSupply += (_st.rate * _w * (_st.prevFutureEpoch - _prevWeekTime)) / _workingSupply;
                        _st.rate = _st.newRate;
                        _st._integrateInvSupply += (_st.rate * _w * (_weekTime - _st.prevFutureEpoch)) / _workingSupply;
                    } else {
                        _st._integrateInvSupply += (_st.rate * _w * _dt) / _workingSupply;
                    }
                    // On precisions of the calculation
                    // rate ~= 10e18
                    // last_weight > 0.01 * 1e18 = 1e16 (if pool weight is 1%)
                    // _working_supply ~= TVL * 1e18 ~= 1e26 ($100M for example)
                    // The largest loss is at dt = 1
                    // Loss is 1e-9 - acceptable
                }
                if (_weekTime == block.timestamp) {
                    break;
                }
                _prevWeekTime = _weekTime;
                _weekTime = Math.min(_weekTime + _WEEK, block.timestamp);
            }
        }

        _st._period += 1;
        period = _st._period;
        periodTimestamp[_st._period] = block.timestamp;
        integrateInvSupply[_st._period] = _st._integrateInvSupply;

        uint256 _workingBalance = workingBalances[_addr];
        // Update user-specific integrals
        // Calc the ΔIu of _addr and add it to Iu.
        integrateFraction[_addr] += (_workingBalance * (_st._integrateInvSupply - integrateInvSupplyOf[_addr])) / 10 ** 18;
        integrateInvSupplyOf[_addr] = _st._integrateInvSupply;
        integrateCheckpointOf[_addr] = block.timestamp;
    }

    /***
     * @notice Record a checkpoint for `_addr`
     * @param _addr User address
     * @return bool success
     */
    function userCheckpoint(address _addr) external returns (bool) {
        require((msg.sender == _addr) || (msg.sender == address(minter)), "dev: unauthorized");
        _checkpoint(_addr);
        _updateLiquidityLimit(_addr, lpBalanceOf(_addr), lpTotalSupply());
        return true;
    }

    /***
     * @notice Get the number of claimable tokens per user
     * @dev This function should be manually changed to "view" in the ABI
     * @return uint256 number of claimable tokens per user
     */
    function claimableTokens(address _addr) external returns (uint256) {
        _checkpoint(_addr);
        return (integrateFraction[_addr] - minter.minted(_addr, address(this)));
    }

    /***
     * @notice Kick `_addr` for abusing their boost
     * @dev Only if either they had another voting event, or their voting escrow lock expired
     * @param _addr Address to kick
     */
    function kick(address _addr) external {
        uint256 _tLast = integrateCheckpointOf[_addr];
        uint256 _tVe = votingEscrow.userPointHistoryTs(_addr, votingEscrow.userPointEpoch(_addr));
        uint256 _balance = lpBalanceOf(_addr);

        require(votingEscrow.balanceOfAtTime(_addr, block.timestamp) == 0 || _tVe > _tLast, "dev: kick not allowed");
        require(workingBalances[_addr] > (_balance * _TOKENLESS_PRODUCTION) / 100, "dev: kick not needed");

        _checkpoint(_addr);
        _updateLiquidityLimit(_addr, lpBalanceOf(_addr), lpTotalSupply());
    }

    function integrateCheckpoint() external view returns (uint256) {
        return periodTimestamp[period];
    }

    /***
     * @notice Set the killed status for this contract
     * @dev When killed, the gauge always yields a rate of 0 and so cannot mint LT
     * @param _is_killed Killed status to set
     */
    function setKilled(bool _isKilled) external onlyOwner {
        isKilled = _isKilled;
    }

    /***
     * @notice The total amount of LP tokens that are currently deposited into the Gomboc.
     */
    function lpBalanceOf(address _addr) public view virtual returns (uint256);

    /***
     * @notice The total amount of LP tokens that are currently deposited into the Gomboc.
     */
    function lpTotalSupply() public view virtual returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IPoolGomboc.sol";

contract GombocFactory is Ownable2Step {
    event PoolGombocCreated(address indexed lpAddr, address indexed poolGomboc, uint);
    event SetPermit2Address(address oldAddress, address newAddress);

    address public immutable poolGombocImplementation;
    address public immutable miner;
    address public permit2;
    address public immutable onwer;

    // lpToken => poolGomboc
    mapping(address => address) public getPool;
    address[] public allPools;

    constructor(address _poolGombocImplementation, address _minter, address _permit2Address) {
        require(_poolGombocImplementation != address(0), "GombocFactory: invalid poolGomboc address");
        require(_minter != address(0), "GombocFactory: invalid minter address");
        require(_permit2Address != address(0), "GombocFactory: invalid permit2 address");
        onwer = _msgSender();
        poolGombocImplementation = _poolGombocImplementation;
        miner = _minter;
        permit2 = _permit2Address;
    }

    function createPool(address _lpAddr) external onlyOwner returns (address pool) {
        bytes32 salt = keccak256(abi.encodePacked(_lpAddr));
        pool = Clones.cloneDeterministic(poolGombocImplementation, salt);
        IPoolGomboc(pool).initialize(_lpAddr, miner, permit2, onwer);
        getPool[_lpAddr] = pool;
        allPools.push(pool);
        emit PoolGombocCreated(_lpAddr, pool, allPools.length);
    }

    function allPoolsLength() external view returns (uint) {
        return allPools.length;
    }

    /**
     * @dev Set permit2 address, onlyOwner
     * @param newAddress New permit2 address
     */
    function setPermit2Address(address newAddress) external onlyOwner {
        require(newAddress != address(0), "CE000");
        address oldAddress = permit2;
        permit2 = newAddress;
        emit SetPermit2Address(oldAddress, newAddress);
    }
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";
import "./AbsGomboc.sol";

contract PoolGomboc is AbsGomboc, ReentrancyGuard {
    uint256 private constant _MAX_REWARDS = 8;
    string public name;
    string public symbol;
    uint256 public decimals;
    // permit2 contract
    address public permit2Address;
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    mapping(address => mapping(address => uint256)) public allowance;

    // user -> [uint128 claimable amount][uint128 claimed amount]
    mapping(address => mapping(address => uint256)) public claimData;
    // For tracking external rewards
    uint256 public rewardCount;
    address[_MAX_REWARDS] public rewardTokens;
    mapping(address => Reward) public rewardData;
    // reward token -> claiming address -> integral
    mapping(address => mapping(address => uint256)) public rewardIntegralFor;
    // claimant -> default reward receiver
    mapping(address => address) public rewardsReceiver;
    address public factory;

    struct Reward {
        address token;
        address distributor;
        uint256 periodFinish;
        uint256 rate;
        uint256 lastUpdate;
        uint256 integral;
    }

    // Claim pending rewards and checkpoint rewards for a user
    struct CheckPointRewardsVars {
        uint256 userBalance;
        address receiver;
        uint256 _rewardCount;
        address token;
        uint256 integral;
        uint256 lastUpdate;
        uint256 duration;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event AddReward(address indexed sender, address indexed rewardToken, address indexed distributorAddress);
    event ChangeRewardDistributor(
        address sender,
        address indexed rewardToken,
        address indexed newDistributorAddress,
        address oldDistributorAddress
    );

    constructor() {
        factory = address(0xdead);
    }

    // called once by the factory at time of deployment
    function initialize(address _lpAddr, address _minter, address _permit2Address, address _owner) external {
        require(factory == address(0), "PoolGomboc: FORBIDDEN");
        // sufficient check
        factory = msg.sender;

        _init(_lpAddr, _minter, _owner);

        permit2Address = _permit2Address;
        symbol = IERC20Metadata(_lpAddr).symbol();
        decimals = IERC20Metadata(_lpAddr).decimals();
        name = string(abi.encodePacked(symbol, " Gomboc"));
    }

    /***
     * @notice Deposit `_value` LP tokens
     * @dev Depositting also claims pending reward tokens
     * @param _value Number of tokens to deposit
     * @param _addr Address to deposit for
     */
    function _deposit(
        uint256 _value,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature,
        address _addr,
        bool _claimRewards_
    ) private {
        _checkpoint(_addr);

        if (_value != 0) {
            bool isRewards = rewardCount != 0;
            uint256 _totalSupply = totalSupply;
            if (isRewards) {
                _checkpointRewards(_addr, _totalSupply, _claimRewards_, address(0));
            }

            _totalSupply += _value;
            uint256 newBalance = balanceOf[_addr] + _value;
            balanceOf[_addr] = newBalance;
            totalSupply = _totalSupply;

            _updateLiquidityLimit(_addr, newBalance, _totalSupply);

            TransferHelper.doTransferIn(permit2Address, lpToken, _value, msg.sender, _nonce, _deadline, _signature);
        }

        emit Deposit(_addr, _value);
        emit Transfer(address(0), _addr, _value);
    }

    /***
     * @notice Deposit `_value` LP tokens
     * @dev Depositting also claims pending reward tokens
     * @param _value Number of tokens to deposit
     * @param _nonce
     * @param _deadline
     * @param _signature
     */
    function deposit(uint256 _value, uint256 _nonce, uint256 _deadline, bytes memory _signature) external nonReentrant {
        _deposit(_value, _nonce, _deadline, _signature, msg.sender, false);
    }

    /***
     * @notice Deposit `_value` LP tokens
     * @dev Depositting also claims pending reward tokens
     * @param _value Number of tokens to deposit
     * @param _nonce
     * @param _deadline
     * @param _signature
     * @param _addr Address to deposit for
     */
    function deposit(uint256 _value, uint256 _nonce, uint256 _deadline, bytes memory _signature, address _addr) external nonReentrant {
        _deposit(_value, _nonce, _deadline, _signature, _addr, false);
    }

    /***
     * @notice Deposit `_value` LP tokens
     * @dev Depositting also claims pending reward tokens
     * @param _value Number of tokens to deposit
     * @param _nonce
     * @param _deadline
     * @param _signature
     * @param _addr Address to deposit for
     * @param _claimRewards_ receiver
     */
    function deposit(
        uint256 _value,
        uint256 _nonce,
        uint256 _deadline,
        bytes memory _signature,
        address _addr,
        bool _claimRewards_
    ) external nonReentrant {
        _deposit(_value, _nonce, _deadline, _signature, _addr, _claimRewards_);
    }

    /***
     * @notice Withdraw `_value` LP tokens
     * @dev Withdrawing also claims pending reward tokens
     * @param _value Number of tokens to withdraw
     */
    function _withdraw(uint256 _value, bool _claimRewards_) private {
        _checkpoint(msg.sender);

        if (_value != 0) {
            bool isRewards = rewardCount != 0;
            uint256 _totalSupply = totalSupply;
            if (isRewards) {
                _checkpointRewards(msg.sender, _totalSupply, _claimRewards_, address(0));
            }

            _totalSupply -= _value;
            uint256 newBalance = balanceOf[msg.sender] - _value;
            balanceOf[msg.sender] = newBalance;
            totalSupply = _totalSupply;

            _updateLiquidityLimit(msg.sender, newBalance, _totalSupply);

            bool success = IERC20Metadata(lpToken).transfer(msg.sender, _value);
            require(success, "TRANSFER FAILED");
        }

        emit Withdraw(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
    }

    function withdraw(uint256 _value) external nonReentrant {
        _withdraw(_value, false);
    }

    function withdraw(uint256 _value, bool _claimRewards_) external nonReentrant {
        _withdraw(_value, _claimRewards_);
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        _checkpoint(_from);
        _checkpoint(_to);
        if (_value != 0) {
            uint256 _totalSupply = totalSupply;
            bool isRewards = rewardCount != 0;
            if (isRewards) {
                _checkpointRewards(_from, _totalSupply, false, address(0));
            }
            uint256 newBalance = balanceOf[_from] - _value;
            balanceOf[_from] = newBalance;
            _updateLiquidityLimit(_from, newBalance, _totalSupply);

            if (isRewards) {
                _checkpointRewards(_to, _totalSupply, false, address(0));
            }
            newBalance = balanceOf[_to] + _value;
            balanceOf[_to] = newBalance;
            _updateLiquidityLimit(_to, newBalance, _totalSupply);
        }

        emit Transfer(_from, _to, _value);
    }

    /***
     * @notice Transfer token for a specified address
     * @dev Transferring claims pending reward tokens for the sender and receiver
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) external nonReentrant returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /***
    * @notice Transfer tokens from one address to another.
    * @dev Transferring claims pending reward tokens for the sender and receiver
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    """
    */
    function transferFrom(address _from, address _to, uint256 _value) external nonReentrant returns (bool) {
        uint256 _allowance = allowance[_from][msg.sender];
        if (_allowance != type(uint256).max) {
            allowance[_from][msg.sender] = _allowance - _value;
        }

        _transfer(_from, _to, _value);
        return true;
    }

    /***
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /***
     * @notice Approve the passed address to transfer the specified amount of
            tokens on behalf of msg.sender
     * @dev Beware that changing an allowance via this method brings the risk
         that someone may use both the old and new allowance by unfortunate
         transaction ordering. This may be mitigated with the use of
         {incraseAllowance} and {decreaseAllowance}.
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will transfer the funds
     * @param _value The amount of tokens that may be transferred
     * @return bool success
    */
    function approve(address _spender, uint256 _value) external returns (bool) {
        address owner = msg.sender;
        _approve(owner, _spender, _value);
        return true;
    }

    /***
     * @notice Increase the allowance granted to `_spender` by the caller
     * @dev This is alternative to {approve} that can be used as a mitigation for the potential race condition
     * @param _spender The address which will transfer the funds
     * @param _addedValue The amount of to increase the allowance
     * @return bool success
     */
    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool) {
        address owner = msg.sender;
        _approve(owner, _spender, allowance[owner][_spender] + _addedValue);
        return true;
    }

    /***
     * @notice Decrease the allowance granted to `_spender` by the caller
     * @dev This is alternative to {approve} that can be used as a mitigation for
         the potential race condition
     * @param _spender The address which will transfer the funds
     * @param _subtractedValue The amount of to decrease the allowance
     * @return bool success
     */
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance[owner][_spender];
        require(currentAllowance >= _subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, _spender, currentAllowance - _subtractedValue);
        }
        return true;
    }

    /***
     * @notice Set the active reward contract
     */
    function addReward(address _rewardToken, address _distributor) external onlyOwner {
        uint256 _rewardCount = rewardCount;
        require(_rewardCount < _MAX_REWARDS, "Reward Threshold");
        require(rewardData[_rewardToken].distributor == address(0), "Repeat setting");
        rewardData[_rewardToken].distributor = _distributor;
        rewardTokens[_rewardCount] = _rewardToken;
        rewardCount = _rewardCount + 1;
        emit AddReward(msg.sender, _rewardToken, _distributor);
    }

    function setRewardDistributor(address _rewardToken, address _distributor) external {
        address currentDistributor = rewardData[_rewardToken].distributor;
        require(msg.sender == currentDistributor || msg.sender == owner(), "Must currentDistributor or owner");
        require(currentDistributor != address(0), "currentDistributor the zero address");
        require(_distributor != address(0), "distributor the zero address");
        rewardData[_rewardToken].distributor = _distributor;
        emit ChangeRewardDistributor(msg.sender, _rewardToken, _distributor, currentDistributor);
    }

    function depositRewardToken(address _rewardToken, uint256 _amount) external payable nonReentrant {
        require(msg.sender == rewardData[_rewardToken].distributor, "No permission to execute");

        _checkpointRewards(address(0), totalSupply, false, address(0));

        require(IERC20Metadata(_rewardToken).transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        uint256 periodFinish = rewardData[_rewardToken].periodFinish;
        if (block.timestamp >= periodFinish) {
            rewardData[_rewardToken].rate = _amount / _WEEK;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardData[_rewardToken].rate;
            rewardData[_rewardToken].rate = (_amount + leftover) / _WEEK;
        }

        rewardData[_rewardToken].lastUpdate = block.timestamp;
        rewardData[_rewardToken].periodFinish = block.timestamp + _WEEK;
    }

    function _checkpointRewards(address _user, uint256 _totalSupply, bool _claim, address _receiver) internal {
        CheckPointRewardsVars memory vars;
        vars.userBalance = 0;
        vars.receiver = _receiver;
        if (_user != address(0)) {
            vars.userBalance = balanceOf[_user];
            if (_claim && _receiver == address(0)) {
                // if receiver is not explicitly declared, check if a default receiver is set
                vars.receiver = rewardsReceiver[_user];
                if (vars.receiver == address(0)) {
                    // if no default receiver is set, direct claims to the user
                    vars.receiver = _user;
                }
            }
        }

        vars._rewardCount = rewardCount;
        for (uint256 i = 0; i < _MAX_REWARDS; i++) {
            if (i == vars._rewardCount) {
                break;
            }
            vars.token = rewardTokens[i];

            vars.integral = rewardData[vars.token].integral;
            vars.lastUpdate = Math.min(block.timestamp, rewardData[vars.token].periodFinish);
            vars.duration = vars.lastUpdate - rewardData[vars.token].lastUpdate;
            if (vars.duration != 0) {
                rewardData[vars.token].lastUpdate = vars.lastUpdate;
                if (_totalSupply != 0) {
                    vars.integral += (vars.duration * rewardData[vars.token].rate * 10 ** 18) / _totalSupply;
                    rewardData[vars.token].integral = vars.integral;
                }
            }

            if (_user != address(0)) {
                uint256 _integralFor = rewardIntegralFor[vars.token][_user];
                uint256 newClaimable = 0;

                if (_integralFor < vars.integral) {
                    rewardIntegralFor[vars.token][_user] = vars.integral;
                    newClaimable = (vars.userBalance * (vars.integral - _integralFor)) / 10 ** 18;
                }

                uint256 _claimData = claimData[_user][vars.token];
                uint256 totalClaimable = (_claimData >> 128) + newClaimable;
                // shift(claim_data, -128)
                if (totalClaimable > 0) {
                    uint256 totalClaimed = _claimData % 2 ** 128;
                    if (_claim) {
                        claimData[_user][vars.token] = totalClaimed + totalClaimable;
                        require(IERC20Metadata(vars.token).transfer(vars.receiver, totalClaimable), "Transfer failed");
                    } else if (newClaimable > 0) {
                        claimData[_user][vars.token] = totalClaimed + (totalClaimable << 128);
                    }
                }
            }
        }
    }

    /***
     * @notice Get the number of already-claimed reward tokens for a user
     * @param _addr Account to get reward amount for
     * @param _token Token to get reward amount for
     * @return uint256 Total amount of `_token` already claimed by `_addr`
     */
    function claimedReward(address _addr, address _token) external view returns (uint256) {
        return claimData[_addr][_token] % 2 ** 128;
    }

    /***
     * @notice Get the number of claimable reward tokens for a user
     * @param _user Account to get reward amount for
     * @param _reward_token Token to get reward amount for
     * @return uint256 Claimable reward token amount
     */
    function claimableReward(address _user, address _reward_token) external view returns (uint256) {
        uint256 integral = rewardData[_reward_token].integral;
        uint256 _totalSupply = totalSupply;
        if (_totalSupply != 0) {
            uint256 lastUpdate = Math.min(block.timestamp, rewardData[_reward_token].periodFinish);
            uint256 duration = lastUpdate - rewardData[_reward_token].lastUpdate;
            integral += ((duration * rewardData[_reward_token].rate * 10 ** 18) / _totalSupply);
        }

        uint256 integralFor = rewardIntegralFor[_reward_token][_user];
        uint256 newClaimable = (balanceOf[_user] * (integral - integralFor)) / 10 ** 18;

        return (claimData[_user][_reward_token] >> 128) + newClaimable;
    }

    /***
     * @notice Set the default reward receiver for the caller.
     * @dev When set to ZERO_ADDRESS, rewards are sent to the caller
     * @param _receiver Receiver address for any rewards claimed via `claim_rewards`
     */
    function setRewardsReceiver(address _receiver) external {
        rewardsReceiver[msg.sender] = _receiver;
    }

    /**
     * @dev Set permit2 address, onlyOwner
     * @param newAddress New permit2 address
     */
    function setPermit2Address(address newAddress) external onlyOwner {
        require(newAddress != address(0), "CE000");
        address oldAddress = permit2Address;
        permit2Address = newAddress;
        emit SetPermit2Address(oldAddress, newAddress);
    }

    /***
     * @notice Claim available reward tokens for `_addr`
     * @param _addr Address to claim for
     * @param _receiver Address to transfer rewards to - if set to
                     ZERO_ADDRESS, uses the default reward receiver
                     for the caller
     */
    function _claimRewards(address _addr, address _receiver) private {
        if (_receiver != address(0)) {
            require(_addr == msg.sender, "Cannot redirect when claiming for another user");
            // dev: cannot redirect when claiming for another user
        }
        _checkpointRewards(_addr, totalSupply, true, _receiver);
    }

    function claimRewards() external nonReentrant {
        _claimRewards(msg.sender, address(0));
    }

    function claimRewards(address _addr) external nonReentrant {
        _claimRewards(_addr, address(0));
    }

    function claimRewards(address _addr, address _receiver) external nonReentrant {
        _claimRewards(_addr, _receiver);
    }

    function lpBalanceOf(address addr) public view override returns (uint256) {
        return balanceOf[addr];
    }

    function lpTotalSupply() public view override returns (uint256) {
        return totalSupply;
    }
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

interface IAgentManager {
    /**
     * @dev Emitted when grant agent data
     */
    event AgentGranted(
        address indexed account,
        uint256 credit,
        uint256 effectiveBlock,
        uint256 expirationBlock,
        bool minable,
        bool burnable,
        address sender
    );
    /**
     * @dev Emitted when revoked agent role
     */
    event AgentRevoked(address indexed account, address sender);

    /**
     * @dev Emitted when increase agent credit
     */
    event AgentIncreaseCredit(address indexed account, uint256 credit, address sender);

    /**
     * @dev Emitted when decrease agent credit
     */
    event AgentDecreaseCredit(address indexed account, uint256 credit, address sender);

    /**
     * @dev Emitted when change agent effective block number
     */
    event AgentChangeEffectiveBlock(address indexed account, uint256 effectiveBlock, address sender);

    /**
     * @dev Emitted when change agent expiration block number
     */
    event AgentChangeExpirationBlock(address indexed account, uint256 expirationBlock, address sender);

    /**
     * @dev Emitted when switch agent minable
     */
    event AgentSwitchMinable(address indexed account, bool minable, address sender);

    /**
     * @dev Emitted when switch agent burnable
     */
    event AgentSwitchBurnable(address indexed account, bool burnable, address sender);

    /**
     * @dev Return agent max credit
     */
    function getMaxCredit(address account) external view returns (uint256);

    /**
     * @dev Return agent remaining credit
     */
    function getRemainingCredit(address account) external view returns (uint256);

    /**
     * @dev Return agent minable status
     */
    function isMinable(address account) external view returns (bool);

    /**
     * @dev Return agent burnable status
     */
    function isBurnable(address account) external view returns (bool);

    /**
     * @dev Return agent effective block number
     */
    function getEffectiveBlock(address account) external view returns (uint256);

    /**
     * @dev Return agent expiration block number
     */
    function getExpirationBlock(address account) external view returns (uint256);

    /**
     * @dev Return whether the address is an agent
     */
    function hasAgent(address account) external view returns (bool);

    /**
     * @dev Grant the address as agent
     */
    function grantAgent(
        address account,
        uint256 credit,
        uint256 effectiveBlock,
        uint256 expirationBlock,
        bool minable,
        bool burnable
    ) external;

    /**
     * @dev Revoke the agent at the address
     */
    function revokeAgent(address account) external;

    /**
     * @dev Change the effective block number of the address agent
     */
    function changeEffectiveBlock(address account, uint256 effectiveBlock) external;

    /**
     * @dev Change the expiration block number of the address agent
     */
    function changeExpirationBlock(address account, uint256 expirationBlock) external;

    /**
     * @dev Change the minable status of the address agent
     */
    function switchMinable(address account, bool minable) external;

    /**
     * @dev Change the burnable status of the address agent
     */
    function switchBurnable(address account, bool burnable) external;

    /**
     * @dev Increase credit of the address agent
     */
    function increaseCredit(address account, uint256 credit) external;

    /**
     * @dev Decrease credit of the address agent
     */
    function decreaseCredit(address account, uint256 credit) external;
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBurner {
    function burn(address to, IERC20 token, uint amount, uint amountOutMin) external;
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IFeeDistributor {
    event ToggleAllowCheckpointToken(bool toggleFlag);

    event CheckpointToken(uint256 time, uint256 tokens);

    event Claimed(address indexed recipient, uint256 amount, uint256 claimEpoch, uint256 maxEpoch);

    event RecoverBalance(address indexed token, address indexed emergencyReturn, uint256 amount);

    event SetEmergencyReturn(address indexed emergencyReturn);

    /**
     * @notice Update the token checkpoint
     * @dev Calculates the total number of tokens to be distributed in a given week.
     *    During setup for the initial distribution this function is only callable
     *    by the contract owner. Beyond initial distro, it can be enabled for anyone
     *    to call
     */
    function checkpointToken() external;

    /**
     * @notice Get the veLT balance for `_user` at `_timestamp`
     * @param _user Address to query balance for
     * @param _timestamp Epoch time
     * @return uint256 veLT balance
     */
    function veForAt(address _user, uint256 _timestamp) external view returns (uint256);

    /**
     * @notice Get the VeLT voting percentage for `_user` in _gomboc  at `_timestamp`
     * @param _user Address to query voting
     * @param _timestamp Epoch time
     * @return value of voting precentage normalized to 1e18
     */
    function vePrecentageForAt(address _user, uint256 _timestamp) external returns (uint256);

    /**
     * @notice Update the veLT total supply checkpoint
     * @dev The checkpoint is also updated by the first claimant each
     *    new epoch week. This function may be called independently
     *    of a claim, to reduce claiming gas costs.
     */
    function checkpointTotalSupply() external;

    /**
     * @notice Claim fees for `_addr`
     *  @dev Each call to claim look at a maximum of 50 user veLT points.
     *    For accounts with many veLT related actions, this function
     *    may need to be called more than once to claim all available
     *    fees. In the `Claimed` event that fires, if `claim_epoch` is
     *    less than `max_epoch`, the account may claim again.
     *    @param _addr Address to claim fees for
     *    @return uint256 Amount of fees claimed in the call
     *
     */
    function claim(address _addr) external returns (uint256);

    /**
     * @notice Make multiple fee claims in a single call
     * @dev Used to claim for many accounts at once, or to make
     *    multiple claims for the same address when that address
     *    has significant veLT history
     * @param _receivers List of addresses to claim for. Claiming terminates at the first `ZERO_ADDRESS`.
     * @return uint256 claim totol fee
     */
    function claimMany(address[] memory _receivers) external returns (uint256);

    /**
     * @notice Receive HOPE into the contract and trigger a token checkpoint
     * @param amount burn amount
     * @return bool success
     */
    function burn(uint256 amount) external returns (bool);

    /**
     * @notice Toggle permission for checkpointing by any account
     */
    function toggleAllowCheckpointToken() external;

    /**
     * @notice Recover ERC20 tokens from this contract
     * @dev Tokens are sent to the emergency return address.
     * @return bool success
     */
    function recoverBalance() external returns (bool);

    /**
     * pause contract
     */
    function pause() external;

    /**
     * unpause contract
     */
    function unpause() external;
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

interface IGombocController {
    struct Point {
        uint256 bias;
        uint256 slope;
    }

    struct VotedSlope {
        uint256 slope;
        uint256 power;
        uint256 end;
    }

    struct UserPoint {
        uint256 bias;
        uint256 slope;
        uint256 ts;
        uint256 blk;
    }

    event AddType(string name, int128 type_id);

    event NewTypeWeight(int128 indexed type_id, uint256 time, uint256 weight, uint256 total_weight);

    event NewGombocWeight(address indexed gomboc_address, uint256 time, uint256 weight, uint256 total_weight);

    event VoteForGomboc(address indexed user, address indexed gomboc_address, uint256 time, uint256 weight);

    event NewGomboc(address indexed gomboc_address, int128 gomboc_type, uint256 weight);

    /**
     * @notice Get gomboc type for address
     *  @param _addr Gomboc address
     * @return Gomboc type id
     */
    function gombocTypes(address _addr) external view returns (int128);

    /**
     * @notice Add gomboc `addr` of type `gomboc_type` with weight `weight`
     * @param addr Gomboc address
     * @param gombocType Gomboc type
     * @param weight Gomboc weight
     */
    function addGomboc(address addr, int128 gombocType, uint256 weight) external;

    /**
     * @notice Checkpoint to fill data common for all gombocs
     */
    function checkpoint() external;

    /**
     * @notice Checkpoint to fill data for both a specific gomboc and common for all gomboc
     * @param addr Gomboc address
     */
    function checkpointGomboc(address addr) external;

    /**
     * @notice Get Gomboc relative weight (not more than 1.0) normalized to 1e18(e.g. 1.0 == 1e18). Inflation which will be received by
     * it is inflation_rate * relative_weight / 1e18
     * @param gombocAddress Gomboc address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gombocRelativeWeight(address gombocAddress, uint256 time) external view returns (uint256);

    /**
     *  @notice Get gomboc weight normalized to 1e18 and also fill all the unfilled values for type and gauge records
     * @dev Any address can call, however nothing is recorded if the values are filled already
     * @param gombocAddress Gomboc address
     * @param time Relative weight at the specified timestamp in the past or present
     * @return Value of relative weight normalized to 1e18
     */
    function gombocRelativeWeightWrite(address gombocAddress, uint256 time) external returns (uint256);

    /**
     * @notice Add gomboc type with name `_name` and weight `weight`
     * @dev only owner call
     * @param _name Name of gauge type
     * @param weight Weight of gauge type
     */
    function addType(string memory _name, uint256 weight) external;

    /**
     * @notice Change gomboc type `type_id` weight to `weight`
     * @dev only owner call
     * @param type_id Gomboc type id
     * @param weight New Gomboc weight
     */
    function changeTypeWeight(int128 type_id, uint256 weight) external;

    /**
     * @notice Change weight of gomboc `addr` to `weight`
     * @param gombocAddress `Gomboc` contract address
     * @param weight New Gomboc weight
     */
    function changeGombocWeight(address gombocAddress, uint256 weight) external;

    /**
     * @notice Allocate voting power for changing pool weights
     * @param gombocAddress Gomboc which `msg.sender` votes for
     * @param userWeight Weight for a gomboc in bps (units of 0.01%). Minimal is 0.01%. Ignored if 0.
     *        example: 10%=1000,3%=300,0.01%=1,100%=10000
     */
    function voteForGombocWeights(address gombocAddress, uint256 userWeight) external;

    /**
     * @notice Get current gomboc weight
     * @param addr Gomboc address
     * @return Gomboc weight
     */

    function getGombocWeight(address addr) external view returns (uint256);

    /**
     * @notice Get current type weight
     * @param type_id Type id
     * @return Type weight
     */
    function getTypeWeight(int128 type_id) external view returns (uint256);

    /**
     * @notice Get current total (type-weighted) weight
     * @return Total weight
     */
    function getTotalWeight() external view returns (uint256);

    /**
     * @notice Get sum of gomboc weights per type
     * @param type_id Type id
     * @return Sum of gomboc weights
     */
    function getWeightsSumPreType(int128 type_id) external view returns (uint256);

    function votingEscrow() external view returns (address);
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IGombocFeeDistributor {
    event ToggleAllowCheckpointToken(bool toggleFlag);

    event CheckpointToken(uint256 time, uint256 tokens);

    event Claimed(address indexed gomboc, address indexed recipient, uint256 amount, uint256 claimEpoch, uint256 maxEpoch);

    event RecoverBalance(address indexed token, address indexed emergencyReturn, uint256 amount);

    event SetEmergencyReturn(address indexed emergencyReturn);

    /**
     * @notice Update the token checkpoint
     * @dev Calculates the total number of tokens to be distributed in a given week.
     *    During setup for the initial distribution this function is only callable
     *    by the contract owner. Beyond initial distro, it can be enabled for anyone
     *    to call
     */
    function checkpointToken() external;

    /**
     * @notice Get the VeLT voting percentage for `_user` in _gomboc  at `_timestamp`
     * @param _gomboc Address to query voting gomboc
     * @param _user Address to query voting
     * @param _timestamp Epoch time
     * @return value of voting precentage normalized to 1e18
     */
    function vePrecentageForAt(address _gomboc, address _user, uint256 _timestamp) external returns (uint256);

    /**
     * @notice Get the veLT balance for `_user` at `_timestamp`
     * @param _gomboc Address to query voting gomboc
     * @param _user Address to query balance for
     * @param _timestamp Epoch time
     * @return uint256 veLT balance
     */
    function veForAt(address _gomboc, address _user, uint256 _timestamp) external view returns (uint256);

    /**
     * @notice Get the HOPE balance for _gomboc  at `_weekCursor`
     * @param _gomboc Address to query voting gomboc
     * @param _weekCursor week cursor
     */
    function gombocBalancePreWeek(address _gomboc, uint256 _weekCursor) external view returns (uint256);

    /**
     * @notice Claim fees for `_addr`
     * @dev Each call to claim look at a maximum of 50 user veLT points.
     *    For accounts with many veLT related actions, this function
     *    may need to be called more than once to claim all available
     *    fees. In the `Claimed` event that fires, if `claim_epoch` is
     *    less than `max_epoch`, the account may claim again.
     * @param gomboc Address to claim fee of gomboc
     * @param _addr Address to claim fees for
     * @return uint256 Amount of fees claimed in the call
     *
     */
    function claim(address gomboc, address _addr) external returns (uint256);

    /**
     * @notice Make multiple fee claims in a single call
     * @dev Used to claim for many accounts at once, or to make
     *    multiple claims for the same address when that address
     *    has significant veLT history
     * @param gomboc Address to claim fee of gomboc
     * @param _receivers List of addresses to claim for. Claiming terminates at the first `ZERO_ADDRESS`.
     * @return uint256 claim totol fee
     */
    function claimMany(address gomboc, address[] memory _receivers) external returns (uint256);

    /**
     * @notice Make multiple fee claims in a single call
     * @dev Used to claim for many accounts at once, or to make
         multiple claims for the same address when that address
         has significant veLT history
       @param  gombocList  List of gombocs to claim
     * @param receiver address to claim for.
     * @return uint256 claim total fee
     */
    function claimManyGomboc(address[] memory gombocList, address receiver) external returns (uint256);

    /**
     * @notice Receive HOPE into the contract and trigger a token checkpoint
     * @param amount burn amount
     * @return bool success
     */
    function burn(uint256 amount) external returns (bool);

    /**
     * @notice Toggle permission for checkpointing by any account
     */
    function toggleAllowCheckpointToken() external;

    /**
     * @notice Recover ERC20 tokens from this contract
     * @dev Tokens are sent to the emergency return address.
     * @return bool success
     */
    function recoverBalance() external returns (bool);

    /**
     * pause contract
     */
    function pause() external;

    /**
     * unpause contract
     */
    function unpause() external;
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

interface IHOPE {
    /**
     * @dev HOPE token mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev return HOPE agent remaining credit
     */
    function getRemainingCredit(address account) external view returns (uint256);

    /**
     * @dev HOPE token burn self address
     */
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

interface IHOPESalesAgent {
    /**
     * @dev Emitted when buy token
     */
    event Buy(string fromCurrency, address indexed buyer, uint256 fromValue, uint256 toValue, uint256 blockTimestamp);

    /**
     * @dev Emitted when add new currency that can buy HOPE token
     */
    event AddCurrency(string symbol, address token, uint256 rate);

    /**
     * @dev Emitted when currency rate change
     */
    event ChangeCurrencyRate(string symbol, uint256 newRate, uint256 oldRate);

    /**
     * @dev Emitted when delete currency.
     */
    event DeleteCurrency(string symbol);

    /**
     * @dev Emitted when redeem token.
     */
    event Redeem(string symbol, address indexed to, uint256 amount);

    /**
     * @dev Emitted when set permit2 address.
     */
    event SetPermit2Address(address oldAddress, address newAddress);

    /**
     * @dev Buy HOPE token
     * @notice user need to call fromCurrencyToken.approve(address(this),fromValue) before buy HOPE token;
     */
    function buy(string memory fromCurrency, uint256 fromValue, uint256 nonce, uint256 deadline, bytes memory signature) external;

    /**
     * @dev Return erc20 balance from sales contract
     */
    function balanceOf(string memory symbol) external view returns (uint256);

    /**
     * @dev Redeem erc20 balance, onlyOwner
     */
    function redeem(string memory symbol, address to, uint256 amount) external returns (bool);

    /**
     * @dev Add currency that can buy HOPE token , onlyOwner
     */
    function addCurrency(string memory symbol, address token, uint256 rate) external;

    /**
     * @dev Change currency exhange rate, onlyOwner
     */
    function changeCurrencyRate(string memory symbol, uint256 rate) external;

    /**
     * @dev Delete currency, onlyOwner
     * @notice Cannot delete currency if balanceOf(address(this)) > 0。 admin can redeem balance and delete currency
     */
    function deleteCurrency(string memory symbol) external;
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

interface ILT {
    /**
     * @dev Emitted when LT inflation rate update
     *
     * Note once a year
     */
    event UpdateMiningParameters(uint256 time, uint256 rate, uint256 supply);

    /**
     * @dev Emitted when set LT minter,can set the minter only once, at creation
     */
    event SetMinter(address indexed minter);

    function rate() external view returns (uint256);

    /**
     * @notice Update mining rate and supply at the start of the epoch
     * @dev   Callable by any address, but only once per epoch
     *        Total supply becomes slightly larger if this function is called late
     */
    function updateMiningParameters() external;

    /**
     * @notice Get timestamp of the next mining epoch start while simultaneously updating mining parameters
     * @return Timestamp of the next epoch
     */
    function futureEpochTimeWrite() external returns (uint256);

    /**
     * @notice Current number of tokens in existence (claimed or unclaimed)
     */
    function availableSupply() external view returns (uint256);

    /**
     * @notice How much supply is mintable from start timestamp till end timestamp
     * @param start Start of the time interval (timestamp)
     * @param end End of the time interval (timestamp)
     * @return Tokens mintable from `start` till `end`
     */
    function mintableInTimeframe(uint256 start, uint256 end) external view returns (uint256);

    /**
     *  @notice Set the minter address
     *  @dev Only callable once, when minter has not yet been set
     *  @param _minter Address of the minter
     */
    function setMinter(address _minter) external;

    /**
     *  @notice Mint `value` tokens and assign them to `to`
     *   @dev Emits a Transfer event originating from 0x00
     *   @param to The account that will receive the created tokens
     *   @param value The amount that will be created
     *   @return bool success
     */
    function mint(address to, uint256 value) external returns (bool);

    /**
     * @notice Burn `value` tokens belonging to `msg.sender`
     * @dev Emits a Transfer event with a destination of 0x00
     * @param value The amount that will be burned
     * @return bool success
     */
    function burn(uint256 value) external returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

interface IMinter {
    function token() external view returns (address);

    function controller() external view returns (address);

    function minted(address user, address gauge) external view returns (uint256);

    function mint(address gombocAddress) external;
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

interface IPermit2 {
    /// @notice The token and amount details for a transfer signed in the permit transfer signature
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice Specifies the recipient address and amount for batched transfers.
    /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
    /// @dev Reverts if the requested amount is greater than the permitted signed amount.
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /// @notice Used to reconstruct the signed permit message for multiple token transfers
    /// @dev Do not need to pass in spender address as it is required that it is msg.sender
    /// @dev Note that a user still signs over a spender address
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
    /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
    /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
    /// @dev It returns a uint256 bitmap
    /// @dev The index, or wordPosition is capped at type(uint248).max
    function nonceBitmap(address, uint256) external view returns (uint256);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers a token using a signed permit message
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Invalidates the bits specified in mask for the bitmap at the word position
    /// @dev The wordPos is maxed at type(uint248).max
    /// @param wordPos A number to index the nonceBitmap at
    /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

interface IPoolGomboc {
    function initialize(address _lpAddr, address _minter, address _permit2Address, address _owner) external;
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

interface IRestrictedList {
    /**
     * @dev Return whether the address exists in the restricted list
     */
    function isRestrictedList(address _maker) external view returns (bool);

    /**
     * @dev Add the address to the restricted list
     */
    function addRestrictedList(address _evilUser) external;

    /**
     * @dev Remove the address to the restricted list
     */
    function removeRestrictedList(address _clearedUser) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IStaking {
    event Staking(address indexed user, uint256 amount);
    event Unstaking(address indexed user, uint256 amount);
    event Redeem(address indexed user, uint256 amount);
    event RewardsAccrued(address user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);

    function staking(uint256 amount, uint256 nonce, uint256 deadline, bytes memory signature) external returns (bool);

    function redeemAll() external returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

interface IVotingEscrow {
    struct Point {
        int256 bias;
        int256 slope;
        uint256 ts;
        uint256 blk;
    }

    struct LockedBalance {
        int256 amount;
        uint256 end;
    }

    event Deposit(
        address indexed provider,
        address indexed beneficiary,
        uint256 value,
        uint256 afterAmount,
        uint256 indexed locktime,
        uint256 _type,
        uint256 ts
    );
    event Withdraw(address indexed provider, uint256 value, uint256 ts);

    event Supply(uint256 prevSupply, uint256 supply);

    event SetSmartWalletChecker(address sender, address indexed newChecker, address oldChecker);

    event SetPermit2Address(address oldAddress, address newAddress);

    /***
     * @dev Get the most recently recorded rate of voting power decrease for `_addr`
     * @param _addr Address of the user wallet
     * @return Value of the slope
     */
    function getLastUserSlope(address _addr) external view returns (int256);

    /***
     * @dev Get the timestamp for checkpoint `_idx` for `_addr`
     * @param _addr User wallet address
     * @param _idx User epoch number
     * @return Epoch time of the checkpoint
     */
    function userPointHistoryTs(address _addr, uint256 _idx) external view returns (uint256);

    /***
     * @dev Get timestamp when `_addr`'s lock finishes
     * @param _addr User wallet
     * @return Epoch time of the lock end
     */
    function lockedEnd(address _addr) external view returns (uint256);

    function createLock(uint256 _value, uint256 _unlockTime, uint256 nonce, uint256 deadline, bytes memory signature) external;

    function createLockFor(
        address _beneficiary,
        uint256 _value,
        uint256 _unlockTime,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) external;

    function increaseAmount(uint256 _value, uint256 nonce, uint256 deadline, bytes memory signature) external;

    function increaseAmountFor(address _beneficiary, uint256 _value, uint256 nonce, uint256 deadline, bytes memory signature) external;

    function increaseUnlockTime(uint256 _unlockTime) external;

    function checkpointSupply() external;

    function withdraw() external;

    function epoch() external view returns (uint256);

    function getUserPointHistory(address _userAddress, uint256 _index) external view returns (Point memory);

    function supplyPointHistory(uint256 _index) external view returns (int256 bias, int256 slope, uint256 ts, uint256 blk);

    /***
     * @notice Get the current voting power for `msg.sender`
     * @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
     * @param _addr User wallet address
     * @param _t Epoch time to return voting power at
     * @return User voting power
     * @dev return the present voting power if _t is 0
     */
    function balanceOfAtTime(address _addr, uint256 _t) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalSupplyAtTime(uint256 _t) external view returns (uint256);

    function userPointEpoch(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "./interfaces/ILT.sol";
import "./interfaces/IGombocController.sol";

interface LiquidityGomboc {
    function integrateFraction(address addr) external view returns (uint256);

    function userCheckpoint(address addr) external returns (bool);
}

contract Minter {
    event Minted(address indexed recipient, address gomboc, uint256 minted);
    event ToogleApproveMint(address sender, address indexed mintingUser, bool status);

    address public immutable token;
    address public immutable controller;

    // user -> gomboc -> value
    mapping(address => mapping(address => uint256)) public minted;

    // minter -> user -> can mint?
    mapping(address => mapping(address => bool)) public allowedToMintFor;

    /*
     * @notice Contract constructor
     * @param _token  LT Token Address
     * @param _controller gomboc Controller Address
     */
    constructor(address _token, address _controller) {
        token = _token;
        controller = _controller;
    }

    /**
     * @notice Mint everything which belongs to `msg.sender` and send to them
     * @param gombocAddress `LiquidityGomboc` address to get mintable amount from
     */
    function mint(address gombocAddress) external {
        _mintFor(gombocAddress, msg.sender);
    }

    /**
     * @notice Mint everything which belongs to `msg.sender` across multiple gombocs
     * @param gombocAddressList List of `LiquidityGomboc` addresses
     */
    function mintMany(address[] memory gombocAddressList) external {
        for (uint256 i = 0; i < gombocAddressList.length && i < 128; i++) {
            if (gombocAddressList[i] == address(0)) {
                continue;
            }
            _mintFor(gombocAddressList[i], msg.sender);
        }
    }

    /**
     * @notice Mint tokens for `_for`
     * @dev Only possible when `msg.sender` has been approved via `toggle_approve_mint`
     * @param gombocAddress `LiquidityGomboc` address to get mintable amount from
     * @param _for Address to mint to
     */
    function mintFor(address gombocAddress, address _for) external {
        if (allowedToMintFor[msg.sender][_for]) {
            _mintFor(gombocAddress, _for);
        }
    }

    /**
     * @notice allow `mintingUser` to mint for `msg.sender`
     * @param mintingUser Address to toggle permission for
     */
    function toggleApproveMint(address mintingUser) external {
        bool flag = allowedToMintFor[mintingUser][msg.sender];
        allowedToMintFor[mintingUser][msg.sender] = !flag;
        emit ToogleApproveMint(msg.sender, mintingUser, !flag);
    }

    function _mintFor(address gombocAddr, address _for) internal {
        ///Gomnoc not adde
        require(IGombocController(controller).gombocTypes(gombocAddr) >= 0, "CE000");

        bool success = LiquidityGomboc(gombocAddr).userCheckpoint(_for);
        require(success, "CHECK FAILED");
        uint256 totalMint = LiquidityGomboc(gombocAddr).integrateFraction(_for);
        uint256 toMint = totalMint - minted[_for][gombocAddr];

        if (toMint != 0) {
            minted[_for][gombocAddr] = totalMint;
            bool success = ILT(token).mint(_for, toMint);
            require(success, "MINT FAILED");
            emit Minted(_for, gombocAddr, toMint);
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "../interfaces/IHOPE.sol";

contract Admin {
    address hopeToken;

    constructor(address _hopeToken) {
        hopeToken = _hopeToken;
    }

    function mint(address to, uint256 amount) public {
        IHOPE(hopeToken).mint(to, amount);
    }

    function burn(uint256 amount) public {
        IHOPE(hopeToken).burn(amount);
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

interface IValut {
    function withdraw(address to, uint256 amount) external returns (uint256);

    function transferLTRewards(address to, uint256 amount) external returns (bool);
}

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract MockConnet is Ownable2Step {
    address public valut;
    address public ltToken;

    function setValut(address _valut) external onlyOwner returns (bool) {
        valut = _valut;
    }

    function setLt(address _addr) external onlyOwner returns (bool) {
        ltToken = _addr;
    }

    function depositRewardToken(uint256 amount) external {
        IERC20(ltToken).transferFrom(msg.sender, address(this), amount);
    }

    function deposit(address token, address addr, uint256 amount) external returns (bool) {
        return true;
    }

    function transferLTRewards(address to, uint256 amount) external onlyOwner returns (bool) {
        IValut(valut).transferLTRewards(to, amount);
        return true;
    }

    function withdraw(address to, uint256 amount) external onlyOwner {
        IValut(valut).withdraw(to, amount);
    }

    function transferBToken(address to, uint256 amount) external onlyOwner {
        IERC20(valut).transfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract MockGomboc {
    mapping(address => uint256) integrate;

    function integrateFraction(address addr) external view returns (uint256) {
        return integrate[addr];
    }

    function userCheckpoint(address addr) external returns (bool) {
        integrate[addr] = 100 * 1e18;

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract MockGombocV2 {
    mapping(address => uint256) integrate;

    function integrateFraction(address addr) external view returns (uint256) {
        return integrate[addr];
    }

    function userCheckpoint(address addr) external returns (bool) {
        integrate[addr] += 100 * 1e18;

        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MockLP {
    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint256 public decimals;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowances;
    uint256 public totalSupply;
    address public minter;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(string memory _name, string memory _symbol, uint256 _decimal, uint256 _supply) {
        uint256 initSupply = _supply.mul(10 ** _decimal);
        name = _name;
        symbol = _symbol;
        decimals = _decimal;
        balanceOf[msg.sender] = initSupply;
        totalSupply = initSupply;
        minter = msg.sender;

        emit Transfer(address(0), msg.sender, initSupply);
    }

    function setMinter(address _minter) external {
        minter = _minter;
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), "zero address");
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_from != address(0), "zero address");
        require(_to != address(0), "zero address");
        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        if (msg.sender != minter) {
            allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowances[msg.sender][_spender] = _value;
        return true;
    }

    function mint(address _to, uint256 _value) external {
        assert(msg.sender == minter);
        assert(_to != address(0));

        totalSupply = totalSupply.add(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        emit Transfer(address(0), _to, _value);
    }

    function _burn(address _to, uint256 _value) internal {
        assert(_to != address(0));

        totalSupply = totalSupply.sub(_value);
        balanceOf[_to] = balanceOf[_to].sub(_value);
        emit Transfer(_to, address(0), _value);
    }

    function burn(uint256 _value) external {
        require(msg.sender == minter, "only minter is allowed to burn");
        _burn(msg.sender, _value);
    }

    function burnFrom(address _to, uint256 _value) external {
        require(msg.sender == minter, "only minter is allowed to burn");
        _burn(_to, _value);
    }
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

contract MockSwap {
    function getHOPEPrice() public view returns (uint256) {
        return 1000;
    }

    function getStHOPEPrice() public view returns (uint256) {
        return 1000;
    }

    function getLTPrice() public view returns (uint256) {
        return 1;
    }
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

contract MyToken is ERC20Upgradeable, Ownable2StepUpgradeable {
    uint8 private _myDecimals;

    function initialize(string memory _name, string memory _symbol, uint256 initialSupply, uint8 _decimals) external initializer {
        __Ownable2Step_init();
        __ERC20_init(_name, _symbol);
        _mint(_msgSender(), initialSupply);
        _myDecimals = _decimals;
    }

    function decimals() public view override returns (uint8) {
        return _myDecimals;
    }
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import {SignatureTransfer} from "light-permit2/contracts/SignatureTransfer.sol";
import {AllowanceTransfer} from "light-permit2/contracts/AllowanceTransfer.sol";

/// @notice Permit2 handles signature-based transfers in SignatureTransfer and allowance-based transfers in AllowanceTransfer.
/// @dev Users must approve Permit2 before calling any of the transfer functions.
contract Permit2 is SignatureTransfer, AllowanceTransfer {
    // Permit2 unifies the two contracts so users have maximal flexibility with their approval.
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IVotingEscrow} from "../interfaces/IVotingEscrow.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";

contract VotingEscrowBoxMock {
    address public lt;
    address public veLT;

    constructor(address ltToken, address veLtAddress) {
        lt = ltToken;
        veLT = veLtAddress;

        TransferHelper.doApprove(lt, veLT, 2 ** 256 - 1);
    }

    function createLock(uint256 _value, uint256 _unlockTime) external {
        IVotingEscrow(veLT).createLock(_value, _unlockTime, 0, 0, "");
    }

    function increaseAmount(uint256 _value) external {
        IVotingEscrow(veLT).increaseAmount(_value, 0, 0, "");
    }

    function increaseUnlockTime(uint256 _unlockTime) external {
        IVotingEscrow(veLT).increaseUnlockTime(_unlockTime);
    }
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RestrictedList is Ownable2Step {
    /**
     * @dev Emitted when add the address to restricted list
     */
    event AddedRestrictedList(address _user);
    /**
     * @dev Emitted when remove the address to restricted list
     */
    event RemovedRestrictedList(address _user);

    mapping(address => bool) public isRestrictedList;

    /**
     * @dev Add the address to the restricted list
     */
    function addRestrictedList(address _evilUser) public onlyOwner {
        isRestrictedList[_evilUser] = true;
        emit AddedRestrictedList(_evilUser);
    }

    /**
     * @dev Remove the address to the restricted list
     */
    function removeRestrictedList(address _clearedUser) public onlyOwner {
        isRestrictedList[_clearedUser] = false;
        emit RemovedRestrictedList(_clearedUser);
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

interface SmartWalletChecker {
    function check(address) external view returns (bool);
}

contract SmartWalletWhitelist is Ownable2Step {
    mapping(address => bool) public wallets;
    address public checker;
    address public future_checker;

    event ApproveWallet(address);
    event RevokeWallet(address);

    function commitSetChecker(address _checker) external onlyOwner {
        future_checker = _checker;
    }

    function applySetChecker() external onlyOwner {
        checker = future_checker;
    }

    function approveWallet(address _wallet) public onlyOwner {
        wallets[_wallet] = true;

        emit ApproveWallet(_wallet);
    }

    function revokeWallet(address _wallet) external onlyOwner {
        wallets[_wallet] = false;

        emit RevokeWallet(_wallet);
    }

    function check(address _wallet) external view returns (bool) {
        bool _check = wallets[_wallet];
        if (_check) {
            return _check;
        } else {
            if (checker != address(0)) {
                return SmartWalletChecker(checker).check(_wallet);
            }
        }
        return false;
    }
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "./interfaces/IStaking.sol";
import "./gombocs/AbsGomboc.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";

contract StakingHOPE is IStaking, ERC20, AbsGomboc {
    uint256 internal constant _LOCK_TIME = 28;

    // permit2 contract
    address public permit2Address;

    struct UnstakingOrderDetail {
        uint256 amount;
        uint256 redeemTime;
        bool redeemExecuted;
    }

    struct UnstakingOrderSummary {
        uint256 notRedeemAmount;
        uint256 index;
        mapping(uint256 => UnstakingOrderDetail) orderMap;
    }

    uint256 public totalNotRedeemAmount;
    mapping(address => UnstakingOrderSummary) public unstakingMap;
    mapping(uint256 => uint256) public unstakingDayHistory;
    uint256 private _unstakeTotal;

    constructor(address _stakedToken, address _minter, address _permit2Address) ERC20("HOPE Staking", "stHOPE") {
        require(_stakedToken != address(0), "StakingHope::initialize: invalid staking address");
        require(_permit2Address != address(0), "StakingHope::initialize: invalid permit2 address");

        _init(_stakedToken, _minter, _msgSender());

        permit2Address = _permit2Address;
    }

    /***
     * @notice Stake HOPE to get stHOPE
     *
     * @param amount
     * @param nonce
     * @param deadline
     * @param signature
     */
    function staking(uint256 amount, uint256 nonce, uint256 deadline, bytes memory signature) external override returns (bool) {
        require(amount != 0, "INVALID_ZERO_AMOUNT");

        address staker = _msgSender();
        // checking amount
        uint256 balanceOfUser = IERC20(lpToken).balanceOf(staker);
        require(balanceOfUser >= amount, "INVALID_AMOUNT");
        TransferHelper.doTransferIn(permit2Address, lpToken, amount, staker, nonce, deadline, signature);

        _checkpoint(staker);

        _mint(staker, amount);

        _updateLiquidityLimit(staker, lpBalanceOf(staker), lpTotalSupply());

        emit Staking(staker, amount);
        return true;
    }

    /***
     * @notice unstaking the staked amount
     * The unstaking process takes 28 days to complete. During this period,
     *  the unstaked $HOPE cannot be traded, and no staking rewards are accrued.
     *
     * @param
     * @return
     */
    function unstaking(uint256 amount) external {
        require(amount != 0, "INVALID_ZERO_AMOUNT");

        address staker = _msgSender();
        // checking amount
        uint256 balanceOfUser = lpBalanceOf(staker);
        require(balanceOfUser >= amount, "INVALID_AMOUNT");

        _checkpoint(staker);

        uint256 nextDayTime = ((block.timestamp + _DAY) / _DAY) * _DAY;
        // lock 28 days
        uint256 redeemTime = nextDayTime + _DAY * _LOCK_TIME;

        unstakingDayHistory[nextDayTime] = unstakingDayHistory[nextDayTime] + amount;
        _unstakeTotal = _unstakeTotal + amount;

        UnstakingOrderSummary storage summaryMap = unstakingMap[staker];

        summaryMap.notRedeemAmount = summaryMap.notRedeemAmount + amount;
        summaryMap.index = summaryMap.index + 1;
        summaryMap.orderMap[summaryMap.index] = UnstakingOrderDetail(amount, redeemTime, false);
        totalNotRedeemAmount += amount;

        _updateLiquidityLimit(staker, lpBalanceOf(staker), lpTotalSupply());
        emit Unstaking(staker, amount);
    }

    /***
     * @notice get unstaking amount
     *
     * @return
     */
    function unstakingBalanceOf(address _addr) public view returns (uint256) {
        uint256 _unstakingAmount = 0;
        UnstakingOrderSummary storage summaryMap = unstakingMap[_addr];
        for (uint256 _index = summaryMap.index; _index > 0; _index--) {
            if (summaryMap.orderMap[_index].redeemExecuted) {
                break;
            }
            if (block.timestamp < summaryMap.orderMap[_index].redeemTime) {
                _unstakingAmount += summaryMap.orderMap[_index].amount;
            }
        }
        return _unstakingAmount;
    }

    function unstakingTotal() public view returns (uint256) {
        uint256 _unstakingTotal = 0;

        uint256 nextDayTime = ((block.timestamp + _DAY) / _DAY) * _DAY;
        for (uint256 i = 0; i < _LOCK_TIME; i++) {
            _unstakingTotal += unstakingDayHistory[nextDayTime - _DAY * i];
        }
        return _unstakingTotal;
    }

    /***
     * @notice get can redeem amount
     *
     * @param
     * @return
     */
    function unstakedBalanceOf(address _addr) public view returns (uint256) {
        uint256 amountToRedeem = 0;
        UnstakingOrderSummary storage summaryMap = unstakingMap[_addr];
        for (uint256 _index = summaryMap.index; _index > 0; _index--) {
            if (summaryMap.orderMap[_index].redeemExecuted) {
                break;
            }
            if (block.timestamp >= summaryMap.orderMap[_index].redeemTime) {
                amountToRedeem += summaryMap.orderMap[_index].amount;
            }
        }
        return amountToRedeem;
    }

    function unstakedTotal() external view returns (uint256) {
        return _unstakeTotal - unstakingTotal();
    }

    /***
     * @notice Redeem all amounts to your account
     *
     * @param
     * @return
     */
    function redeemAll() external override returns (uint256) {
        address redeemer = _msgSender();
        uint256 amountToRedeem = unstakedBalanceOf(redeemer);
        require(amountToRedeem != 0, "No redeemable amount");

        _checkpoint(redeemer);

        UnstakingOrderSummary storage summaryMap = unstakingMap[redeemer];
        for (uint256 _index = summaryMap.index; _index > 0; _index--) {
            if (summaryMap.orderMap[_index].redeemExecuted) {
                break;
            }
            if (block.timestamp > summaryMap.orderMap[_index].redeemTime) {
                uint256 amount = summaryMap.orderMap[_index].amount;
                summaryMap.orderMap[_index].redeemExecuted = true;
                summaryMap.notRedeemAmount = summaryMap.notRedeemAmount - amount;
                totalNotRedeemAmount -= amount;
            }
        }

        _burn(redeemer, amountToRedeem);
        TransferHelper.doTransferOut(lpToken, redeemer, amountToRedeem);
        _updateLiquidityLimit(redeemer, lpBalanceOf(redeemer), lpTotalSupply());

        _unstakeTotal = _unstakeTotal - amountToRedeem;

        emit Redeem(redeemer, amountToRedeem);
        return amountToRedeem;
    }

    /***
     * @notice redeem amount by index(Prevent the number of unstaking too much to redeem)
     *
     * @param maxIndex
     * @return
     */
    function redeemByMaxIndex(uint256 maxIndex) external returns (uint256) {
        address redeemer = _msgSender();

        uint256 allToRedeemAmount = unstakedBalanceOf(redeemer);
        require(allToRedeemAmount != 0, "No redeemable amount");

        uint256 amountToRedeem = 0;
        _checkpoint(redeemer);

        UnstakingOrderSummary storage summaryMap = unstakingMap[redeemer];
        uint256 indexCount = 0;
        for (uint256 _index = 1; _index <= summaryMap.index; _index++) {
            if (indexCount >= maxIndex) {
                break;
            }
            if (block.timestamp > summaryMap.orderMap[_index].redeemTime && !summaryMap.orderMap[_index].redeemExecuted) {
                uint256 amount = summaryMap.orderMap[_index].amount;
                amountToRedeem += amount;
                summaryMap.orderMap[_index].redeemExecuted = true;
                summaryMap.notRedeemAmount = summaryMap.notRedeemAmount - amount;
                totalNotRedeemAmount -= amount;
                indexCount++;
            }
        }

        if (amountToRedeem > 0) {
            _burn(redeemer, amountToRedeem);
            TransferHelper.doTransferOut(lpToken, redeemer, amountToRedeem);
            _updateLiquidityLimit(redeemer, lpBalanceOf(redeemer), lpTotalSupply());

            _unstakeTotal = _unstakeTotal - amountToRedeem;
            emit Redeem(redeemer, amountToRedeem);
        }
        return amountToRedeem;
    }

    /**
     * @dev Set permit2 address, onlyOwner
     * @param newAddress New permit2 address
     */
    function setPermit2Address(address newAddress) external onlyOwner {
        require(newAddress != address(0), "CE000");
        address oldAddress = permit2Address;
        permit2Address = newAddress;
        emit SetPermit2Address(oldAddress, newAddress);
    }

    function lpBalanceOf(address _addr) public view override returns (uint256) {
        return super.balanceOf(_addr) - unstakingMap[_addr].notRedeemAmount;
    }

    function lpTotalSupply() public view override returns (uint256) {
        return super.totalSupply() - totalNotRedeemAmount;
    }

    /***
     * @notice Transfers Gomboc deposit (stHOPE) from the caller to _to.
     *
     * @param to
     * @param amount
     * @return bool
     */
    function transfer(address _to, uint256 _amount) public virtual override returns (bool) {
        address owner = _msgSender();
        uint256 fromBalance = lpBalanceOf(owner);
        require(fromBalance >= _amount, "ERC20: transfer amount exceeds balance");

        _checkpoint(owner);
        _checkpoint(_to);

        bool result = super.transfer(_to, _amount);

        _updateLiquidityLimit(owner, lpBalanceOf(owner), lpTotalSupply());
        _updateLiquidityLimit(_to, lpBalanceOf(_to), lpTotalSupply());
        return result;
    }

    /***
     * @notice Tansfers a Gomboc deposit between _from and _to.
     *
     * @param from
     * @param to
     * @param amount
     * @return bool
     */
    function transferFrom(address _from, address _to, uint256 _amount) public override returns (bool) {
        uint256 fromBalance = lpBalanceOf(_from);
        require(fromBalance >= _amount, "ERC20: transfer amount exceeds balance");

        _checkpoint(_from);
        _checkpoint(_to);

        bool result = super.transferFrom(_from, _to, _amount);

        _updateLiquidityLimit(_from, lpBalanceOf(_from), lpTotalSupply());
        _updateLiquidityLimit(_to, lpBalanceOf(_to), lpTotalSupply());
        return result;
    }
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "../agents/AgentManager.sol";
import "../interfaces/IRestrictedList.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/**
 * @title LT Dao's HOPE Token Contract
 * @notice $HOPE, the ecosystem’s native pricing token backed by reserves
 * @author LT
 */
contract HOPE is ERC20Upgradeable, AgentManager {
    // RestrictedList contract
    address public restrictedList;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _restrictedList) external initializer {
        require(_restrictedList != address(0), "CE000");
        restrictedList = _restrictedList;
        __Ownable2Step_init();
        __ERC20_init("HOPE", "HOPE");
    }

    /**
     * @notice mint amount to address
     * @dev mint only support Agent & Minable
     * @param to min to address
     * @param amount mint amount
     */
    function mint(address to, uint256 amount) public onlyAgent onlyMinable {
        require(!IRestrictedList(restrictedList).isRestrictedList(to), "FA000");
        require(tx.origin != _msgSender(), "HO000");
        require(getEffectiveBlock(_msgSender()) <= block.number, "AG014");
        require(getExpirationBlock(_msgSender()) >= block.number, "AG011");
        require(getRemainingCredit(_msgSender()) >= amount, "AG004");
        _mint(to, amount);
        _decreaseRemainingCredit(_msgSender(), amount);
    }

    /**
     * @notice burn amount from sender
     * @dev mint only support Agent & Burnable
     * @param amount burn amount
     */
    function burn(uint256 amount) external onlyAgent onlyBurnable {
        require(getEffectiveBlock(_msgSender()) <= block.number, "AG014");
        require(getExpirationBlock(_msgSender()) >= block.number, "AG011");
        _burn(_msgSender(), amount);
        _increaseRemainingCredit(_msgSender(), amount);
    }

    /**
     * @notice restricted list cannot call
     * @dev transfer token for a specified address
     * @param to The address to transfer to.
     * @param amount The amount to be transferred.
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        require(
            !IRestrictedList(restrictedList).isRestrictedList(msg.sender) && !IRestrictedList(restrictedList).isRestrictedList(to),
            "FA000"
        );
        return super.transfer(to, amount);
    }

    /**
     * @notice restricted list cannot call
     * @dev Transfer tokens from one address to another
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param amount uint the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        require(!IRestrictedList(restrictedList).isRestrictedList(from) && !IRestrictedList(restrictedList).isRestrictedList(to), "FA000");
        return super.transferFrom(from, to, amount);
    }
}

// SPDX-License-Identifier: LGPL-3.0
/**
 *  @title Light DAO Token
 *  @author LT Finance
 *  @notice ERC20 with piecewise-linear mining supply.
 *  @dev Based on the ERC-20 token standard as defined at https://eips.ethereum.org/EIPS/eip-20
 */
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "../interfaces/ILT.sol";

contract LT is ERC20Upgradeable, Ownable2StepUpgradeable, ILT {
    //General constants
    uint256 private constant _DAY = 86400;
    uint256 private constant _YEAR = _DAY * 365;

    /// Allocation:
    /// =========
    /// total 1 trillion
    ///  30% to shareholders (team and investors) with 1 year cliff and 4 years vesting
    ///  5% to the treasury reserve
    ///  5% to LIGHT Foundation (grants)
    ///
    /// == 40% ==
    /// left for inflation: 60%

    /// Supply parameters
    uint256 private constant _INITIAL_SUPPLY = 400_000_000_000;
    /// _INITIAL_SUPPLY * 0.2387
    uint256 private constant _INITIAL_RATE = (95_480_000_000 * 10 ** 18) / _YEAR;
    uint256 private constant _RATE_REDUCTION_TIME = _YEAR;
    /// 2 ** (1/4) * 1e18
    uint256 private constant _RATE_REDUCTION_COEFFICIENT = 1189207115002721024;
    uint256 private constant _RATE_DENOMINATOR = 10 ** 18;
    uint256 private constant _INFLATION_DELAY = _DAY;

    address public minter;
    /// Supply variables
    int128 public miningEpoch;
    uint256 public startEpochTime;
    uint256 public rate;

    uint256 public startEpochSupply;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Contract constructor
     * @param _name Token full name
     * @param _symbol Token symbol
     */
    function initialize(string memory _name, string memory _symbol) external initializer {
        __Ownable2Step_init();
        __ERC20_init(_name, _symbol);

        uint256 initSupply = _INITIAL_SUPPLY * 10 ** decimals();
        _mint(_msgSender(), initSupply);

        startEpochTime = block.timestamp + _INFLATION_DELAY - _RATE_REDUCTION_TIME;
        miningEpoch = -1;
        rate = 0;
        startEpochSupply = initSupply;
    }

    /**
     *  @dev Update mining rate and supply at the start of the epoch
     *   Any modifying mining call must also call this
     */
    function __updateMiningParameters() internal {
        uint256 _rate = rate;
        uint256 _startEpochSupply = startEpochSupply;

        startEpochTime += _RATE_REDUCTION_TIME;
        miningEpoch += 1;

        if (_rate == 0) {
            _rate = _INITIAL_RATE;
        } else {
            _startEpochSupply += _rate * _RATE_REDUCTION_TIME;
            startEpochSupply = _startEpochSupply;
            _rate = (_rate * _RATE_DENOMINATOR) / _RATE_REDUCTION_COEFFICIENT;
        }
        rate = _rate;
        emit UpdateMiningParameters(block.timestamp, _rate, _startEpochSupply);
    }

    /**
     * @notice Update mining rate and supply at the start of the epoch
     * @dev   Callable by any address, but only once per epoch
     *  Total supply becomes slightly larger if this function is called late
     */
    function updateMiningParameters() external override {
        require(block.timestamp >= startEpochTime + _RATE_REDUCTION_TIME, "BA000");
        __updateMiningParameters();
    }

    /**
     * @notice Get timestamp of the next mining epoch start
     *       while simultaneously updating mining parameters
     * @return Timestamp of the next epoch
     */
    function futureEpochTimeWrite() external override returns (uint256) {
        uint256 _startEpochTime = startEpochTime;
        if (block.timestamp >= _startEpochTime + _RATE_REDUCTION_TIME) {
            __updateMiningParameters();
            return startEpochTime + _RATE_REDUCTION_TIME;
        } else {
            return _startEpochTime + _RATE_REDUCTION_TIME;
        }
    }

    function __availableSupply() internal view returns (uint256) {
        return startEpochSupply + (block.timestamp - startEpochTime) * rate;
    }

    /**
     * @notice Current number of tokens in existence (claimed or unclaimed)
     */
    function availableSupply() external view override returns (uint256) {
        return __availableSupply();
    }

    /**
     * @notice How much supply is mintable from start timestamp till end timestamp
     * @param start Start of the time interval (timestamp)
     * @param end End of the time interval (timestamp)
     * @return Tokens mintable from `start` till `end`
     */
    function mintableInTimeframe(uint256 start, uint256 end) external view override returns (uint256) {
        require(start <= end, "BA001");
        uint256 toMint = 0;
        uint256 currentEpochTime = startEpochTime;
        uint256 currentRate = rate;

        // Special case if end is in future (not yet minted) epoch
        if (end > currentEpochTime + _RATE_REDUCTION_TIME) {
            currentEpochTime += _RATE_REDUCTION_TIME;
            currentRate = (currentRate * _RATE_DENOMINATOR) / _RATE_REDUCTION_COEFFICIENT;
        }
        require(end <= currentEpochTime + _RATE_REDUCTION_TIME, "BA002");

        // LT will not work in 1000 years. Darn!
        for (uint256 i = 0; i < 1000; i++) {
            if (end >= currentEpochTime) {
                uint256 currentEnd = end;
                if (currentEnd > currentEpochTime + _RATE_REDUCTION_TIME) {
                    currentEnd = currentEpochTime + _RATE_REDUCTION_TIME;
                }
                uint256 currentStart = start;
                if (currentStart >= currentEpochTime + _RATE_REDUCTION_TIME) {
                    // We should never get here but what if...
                    break;
                } else if (currentStart < currentEpochTime) {
                    currentStart = currentEpochTime;
                }
                toMint += currentRate * (currentEnd - currentStart);
                if (start >= currentEpochTime) {
                    break;
                }
            }
            currentEpochTime -= _RATE_REDUCTION_TIME;
            //# double-division with rounding made rate a bit less => good
            currentRate = (currentRate * _RATE_REDUCTION_COEFFICIENT) / _RATE_DENOMINATOR;
            require(currentRate <= _INITIAL_RATE, "This should never happen");
        }
        return toMint;
    }

    /**
     *  @notice Set the minter address
     *  @dev Only callable once, when minter has not yet been set
     *  @param _minter Address of the minter
     */
    function setMinter(address _minter) external override onlyOwner {
        require(minter == address(0), "BA003");
        minter = _minter;
        emit SetMinter(_minter);
    }

    /**
     *  @notice Mint `value` tokens and assign them to `to`
     *   @dev Emits a Transfer event originating from 0x00
     *   @param to The account that will receive the created tokens
     *   @param value The amount that will be created
     *   @return bool success
     */
    function mint(address to, uint256 value) external override returns (bool) {
        require(msg.sender == minter, "BA004");
        require(to != address(0), "CE000");
        if (block.timestamp >= startEpochTime + _RATE_REDUCTION_TIME) {
            __updateMiningParameters();
        }
        uint256 totalSupply = totalSupply() + value;
        require(totalSupply <= __availableSupply(), "BA005");

        _mint(to, value);

        return true;
    }

    /**
     * @notice Burn `value` tokens belonging to `msg.sender`
     * @dev Emits a Transfer event with a destination of 0x00
     * @param value The amount that will be burned
     * @return bool success
     */
    function burn(uint256 value) external override returns (bool) {
        _burn(msg.sender, value);
        return true;
    }
}

// SPDX-License-Identifier: LGPL-3.0
pragma solidity 0.8.17;

/***
 *@title VotingEscrow
 *@notice Votes have a weight depending on time, so that users are
 *        committed to the future of (whatever they are voting for)
 *@dev Vote weight decays linearly over time. Lock time cannot be
 *     more than `MAXTIME` (4 years).
 */

// Voting escrow to have time-weighted votes
// Votes have a weight depending on time, so that users are committed
// to the future of (whatever they are voting for).
// The weight in this implementation is linear, and lock cannot be more than maxtime
// w ^
// 1 +        /
//   |      /
//   |    /
//   |  /
//   |/
// 0 +--------+------> time
//       maxtime (4 years?)

// Interface for checking whether address belongs to a whitelisted
// type of a smart wallet.
// When new types are added - the whole contract is changed
// The check() method is modifying to be able to use caching
// for individual wallet addresses

//libraries
import {IVotingEscrow} from "./interfaces/IVotingEscrow.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {TransferHelper} from "light-lib/contracts/TransferHelper.sol";

/// Interface for checking whether address belongs to a whitelisted
/// type of a smart wallet.
/// When new types are added - the whole contract is changed
/// The check() method is modifying to be able to use caching
/// for individual wallet addresses
interface SmartWalletChecker {
    function check(address _wallet) external view returns (bool);
}

contract VotingEscrow is IVotingEscrow, ReentrancyGuard, Ownable2Step {
    // We cannot really do block numbers per se b/c slope is per time, not per block
    // and per block could be fairly bad b/c Ethereum changes blocktimes.
    // What we can do is to extrapolate ***At functions

    uint256 private constant _DEPOSIT_FOR_TYPE = 0;
    uint256 private constant _CREATE_LOCK_TYPE = 1;
    uint256 private constant _INCREASE_LOCK_AMOUNT = 2;
    uint256 private constant _INCREASE_UNLOCK_TIME = 3;

    uint256 public constant _DAY = 86400; // all future times are rounded by week
    uint256 public constant WEEK = 7 * _DAY; // all future times are rounded by week
    uint256 public constant MAXTIME = 4 * 365 * _DAY; // 4 years
    uint256 public constant MULTIPLIER = 10 ** 18;

    int256 public constant BASE_RATE = 10000;

    /// LT token address
    address public immutable token;
    /// permit2 contract address
    address public permit2Address;
    /// total locked LT value
    uint256 public supply;

    mapping(address => LockedBalance) public locked;

    //everytime user deposit/withdraw/change_locktime, these values will be updated;
    uint256 public override epoch;
    mapping(uint256 => Point) public supplyPointHistory; // epoch -> unsigned point.
    mapping(address => mapping(uint256 => Point)) public userPointHistory; // user -> Point[user_epoch]
    mapping(address => uint256) public userPointEpoch;
    mapping(uint256 => int256) public slopeChanges; // time -> signed slope change

    string public name;
    string public symbol;
    uint256 public immutable decimals;
    address public smartWalletChecker;

    constructor(address _tokenAddr, address _permit2Address) {
        require(_permit2Address != address(0), "CE000");

        token = _tokenAddr;
        permit2Address = _permit2Address;
        supplyPointHistory[0] = Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number});
        uint256 _decimals = IERC20Metadata(_tokenAddr).decimals();
        decimals = _decimals;
        name = "Vote-escrowed LT";
        symbol = "veLT";
    }

    /***
     * @dev Get the user point for checkpoint for `_index` for `_userAddress`
     * @param _userAddress Address of the user wallet
     * @param _index User epoch number
     * @return user Epoch checkpoint
     */
    function getUserPointHistory(address _userAddress, uint256 _index) external view override returns (Point memory) {
        return userPointHistory[_userAddress][_index];
    }

    /***
     * @dev Get the most recently recorded rate of voting power decrease for `_addr`
     * @param _addr Address of the user wallet
     * @return Value of the slope
     */
    function getLastUserSlope(address _addr) external view override returns (int256) {
        uint256 uepoch = userPointEpoch[_addr];
        return userPointHistory[_addr][uepoch].slope;
    }

    /***
     * @dev Get the timestamp for checkpoint `_idx` for `_addr`
     * @param _addr User wallet address
     * @param _idx User epoch number
     * @return Epoch time of the checkpoint
     */
    function userPointHistoryTs(address _addr, uint256 _idx) external view override returns (uint256) {
        return userPointHistory[_addr][_idx].ts;
    }

    /***
     * @dev Get timestamp when `_addr`'s lock finishes
     * @param _addr User wallet
     * @return Epoch time of the lock end
     */
    function lockedEnd(address _addr) external view override returns (uint256) {
        return locked[_addr].end;
    }

    //Struct to avoid "Stack Too Deep"
    struct CheckpointParameters {
        Point userOldPoint;
        Point userNewPoint;
        int256 oldDslope;
        int256 newDslope;
        uint256 epoch;
    }

    /***
     * @dev Record global and per-user data to checkpoint
     * @param _addr User's wallet address. No user checkpoint if 0x0
     * @param _oldLocked Pevious locked amount / end lock time for the user
     * @param _newLocked New locked amount / end lock time for the user
     */
    function _checkpoint(address _addr, LockedBalance memory _oldLocked, LockedBalance memory _newLocked) internal {
        CheckpointParameters memory _st;
        _st.epoch = epoch;

        if (_addr != address(0)) {
            // Calculate slopes and biases
            // Kept at zero when they have to
            if (_oldLocked.end > block.timestamp && _oldLocked.amount > 0) {
                _st.userOldPoint.slope = _oldLocked.amount / BASE_RATE / int256(MAXTIME);
                _st.userOldPoint.bias = _st.userOldPoint.slope * int256(_oldLocked.end - block.timestamp);
            }
            if (_newLocked.end > block.timestamp && _newLocked.amount > 0) {
                _st.userNewPoint.slope = _newLocked.amount / BASE_RATE / int256(MAXTIME);
                _st.userNewPoint.bias = _st.userNewPoint.slope * int256(_newLocked.end - block.timestamp);
            }

            // Read values of scheduled changes in the slope
            // _oldLocked.end can be in the past and in the future
            // _newLocked.end can ONLY by in the FUTURE unless everything expired than zeros
            _st.oldDslope = slopeChanges[_oldLocked.end];
            if (_newLocked.end != 0) {
                if (_newLocked.end == _oldLocked.end) {
                    _st.newDslope = _st.oldDslope;
                } else {
                    _st.newDslope = slopeChanges[_newLocked.end];
                }
            }
        }

        Point memory _lastPoint = Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number});
        if (_st.epoch > 0) {
            _lastPoint = supplyPointHistory[_st.epoch];
        }
        uint256 _lastCheckPoint = _lastPoint.ts;
        // _initialLastPoint is used for extrapolation to calculate block number
        // (approximately, for *At methods) and save them
        // as we cannot figure that out exactly from inside the contract
        // Point memory _initialLastPoint = _lastPoint;
        uint256 _initBlk = _lastPoint.blk;
        uint256 _initTs = _lastPoint.ts;

        uint256 _blockSlope = 0; // dblock/dt
        if (block.timestamp > _lastPoint.ts) {
            _blockSlope = (MULTIPLIER * (block.number - _lastPoint.blk)) / (block.timestamp - _lastPoint.ts);
        }
        // If last point is already recorded in this block, slope=0
        // But that's ok b/c we know the block in such case

        // Go over weeks to fill history and calculate what the current point is
        uint256 _ti = (_lastCheckPoint / WEEK) * WEEK;
        for (uint256 i; i < 255; i++) {
            // Hopefully it won't happen that this won't get used in 5 years!
            // If it does, users will be able to withdraw but vote weight will be broken
            _ti += WEEK;
            int256 dSlope = 0;
            if (_ti > block.timestamp) {
                // reach future time, reset to blok time
                _ti = block.timestamp;
            } else {
                dSlope = slopeChanges[_ti];
            }
            _lastPoint.bias = _lastPoint.bias - _lastPoint.slope * int256(_ti - _lastCheckPoint);
            _lastPoint.slope += dSlope;
            if (_lastPoint.bias < 0) {
                // This can happen
                _lastPoint.bias = 0;
            }
            if (_lastPoint.slope < 0) {
                // This cannot happen - just in case
                _lastPoint.slope = 0;
            }
            _lastCheckPoint = _ti;
            _lastPoint.ts = _ti;
            _lastPoint.blk = _initBlk + ((_blockSlope * (_ti - _initTs)) / MULTIPLIER);
            _st.epoch += 1;
            if (_ti == block.timestamp) {
                // history filled over, break loop
                _lastPoint.blk = block.number;
                break;
            } else {
                supplyPointHistory[_st.epoch] = _lastPoint;
            }
        }
        epoch = _st.epoch;
        // Now supplyPointHistory is filled until t=now

        if (_addr != address(0)) {
            // If last point was in this block, the slope change has been applied already
            // But in such case we have 0 slope(s)
            _lastPoint.slope += _st.userNewPoint.slope - _st.userOldPoint.slope;
            _lastPoint.bias += _st.userNewPoint.bias - _st.userOldPoint.bias;
            if (_lastPoint.slope < 0) {
                _lastPoint.slope = 0;
            }
            if (_lastPoint.bias < 0) {
                _lastPoint.bias = 0;
            }
        }

        // Record the changed point into history
        supplyPointHistory[_st.epoch] = _lastPoint;
        if (_addr != address(0)) {
            // Schedule the slope changes (slope is going down)
            // We subtract new_user_slope from [_newLocked.end]
            // and add old_user_slope to [_oldLocked.end]
            if (_oldLocked.end > block.timestamp) {
                // _oldDslope was <something> - _userOldPoint.slope, so we cancel that
                _st.oldDslope += _st.userOldPoint.slope;
                if (_newLocked.end == _oldLocked.end) {
                    _st.oldDslope -= _st.userNewPoint.slope; // It was a new deposit, not extension
                }
                slopeChanges[_oldLocked.end] = _st.oldDslope;
            }
            if (_newLocked.end > block.timestamp) {
                if (_newLocked.end > _oldLocked.end) {
                    _st.newDslope -= _st.userNewPoint.slope; // old slope disappeared at this point
                    slopeChanges[_newLocked.end] = _st.newDslope;
                }
                // else we recorded it already in _oldDslope
            }

            // Now handle user history
            uint256 _userEpoch = userPointEpoch[_addr] + 1;

            userPointEpoch[_addr] = _userEpoch;
            _st.userNewPoint.ts = block.timestamp;
            _st.userNewPoint.blk = block.number;
            userPointHistory[_addr][_userEpoch] = _st.userNewPoint;
        }
    }

    /***
     * @dev Deposit and lock tokens for a user
     * @param _addr User's wallet address
     * @param _value Amount to deposit
     * @param _unlockTime New time when to unlock the tokens, or 0 if unchanged
     * @param _lockedBalance Previous locked amount / timestamp
     */
    function _depositFor(
        address _provider,
        address _beneficiary,
        uint256 _value,
        uint256 _unlockTime,
        LockedBalance memory _lockedBalance,
        uint256 _type,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) internal {
        LockedBalance memory _locked = LockedBalance(_lockedBalance.amount, _lockedBalance.end);
        LockedBalance memory _oldLocked = LockedBalance(_lockedBalance.amount, _lockedBalance.end);

        uint256 _supplyBefore = supply;
        supply = _supplyBefore + _value;
        //Adding to existing lock, or if a lock is expired - creating a new one
        _locked.amount = _locked.amount + int256(_value);
        if (_unlockTime != 0) {
            _locked.end = _unlockTime;
        }
        locked[_beneficiary] = _locked;

        // Possibilities
        // Both _oldLocked.end could be current or expired (>/< block.timestamp)
        // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
        // _locked.end > block.timestamp (always)
        _checkpoint(_beneficiary, _oldLocked, _locked);
        if (_value != 0) {
            TransferHelper.doTransferIn(permit2Address, token, _value, _provider, nonce, deadline, signature);
        }

        emit Deposit(_provider, _beneficiary, _value, uint256(_locked.amount), _locked.end, _type, block.timestamp);
        emit Supply(_supplyBefore, _supplyBefore + _value);
    }

    /***
     * @notice Record total supply to checkpoint
     */
    function checkpointSupply() public override {
        LockedBalance memory _a;
        LockedBalance memory _b;
        _checkpoint(address(0), _a, _b);
    }

    /**
     * @notice Deposit `_value` tokens for `_beneficiary` and lock until `_unlockTime`
     * @dev only owner can call
     */
    function createLockFor(
        address _beneficiary,
        uint256 _value,
        uint256 _unlockTime,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) external override onlyOwner {
        _createLock(_beneficiary, _value, _unlockTime, nonce, deadline, signature);
    }

    function createLock(uint256 _value, uint256 _unlockTime, uint256 nonce, uint256 deadline, bytes memory signature) external override {
        _assertNotContract(msg.sender);
        _createLock(msg.sender, _value, _unlockTime, nonce, deadline, signature);
    }

    /***
     * @dev Deposit `_value` tokens for `msg.sender` and lock until `_unlockTime`
     * @param _beneficiary
     * @param _value Amount to deposit
     * @param _unlockTime Epoch time when tokens unlock, rounded down to whole weeks
     * @param _
     */
    function _createLock(
        address _beneficiary,
        uint256 _value,
        uint256 _unlockTime,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) internal nonReentrant {
        _unlockTime = (_unlockTime / WEEK) * WEEK; // Locktime is rounded down to weeks
        LockedBalance memory _locked = locked[_beneficiary];

        require(_value > 0, "VE000");
        require(_locked.amount == 0, "VE001");
        //The locking time shall be at least two cycles
        require(_unlockTime > block.timestamp + WEEK, "VE002");
        require(_unlockTime <= block.timestamp + MAXTIME, "VE003");

        _depositFor(msg.sender, _beneficiary, _value, _unlockTime, _locked, _CREATE_LOCK_TYPE, nonce, deadline, signature);
    }

    /**
     * @notice Deposit `_value` additional tokens for `msg.sender` without modifying the unlock time
     * @param _value Amount of tokens to deposit and add to the lock
     */
    function increaseAmount(uint256 _value, uint256 nonce, uint256 deadline, bytes memory signature) external override {
        _assertNotContract(msg.sender);
        _increaseAmount(msg.sender, _value, nonce, deadline, signature);
    }

    /**
     * @notice Deposit `_value` tokens for `_beneficiary` and add to the lock
     * @dev Anyone (even a smart contract) can deposit for someone else, but cannot extend their locktime and deposit for a brand new user
     * @param _beneficiary User's wallet address
     * @param _value Amount to add to user's lock
     */
    function increaseAmountFor(
        address _beneficiary,
        uint256 _value,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) external override {
        _increaseAmount(_beneficiary, _value, nonce, deadline, signature);
    }

    /***
     * @dev Deposit `_value` additional tokens for `msg.sender`
     *        without modifying the unlock time
     * @param _value Amount of tokens to deposit and add to the lock
     */
    function _increaseAmount(
        address _beneficiary,
        uint256 _value,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) internal nonReentrant {
        LockedBalance memory _locked = locked[_beneficiary];

        require(_value > 0, "VE000");
        require(_locked.amount > 0, "VE004");
        require(_locked.end > block.timestamp, "VE005");

        _depositFor(msg.sender, _beneficiary, _value, 0, _locked, _INCREASE_LOCK_AMOUNT, nonce, deadline, signature);
    }

    /***
     * @dev Extend the unlock time for `msg.sender` to `_unlockTime`
     * @param _unlockTime New epoch time for unlocking
     */
    function increaseUnlockTime(uint256 _unlockTime) external override nonReentrant {
        _assertNotContract(msg.sender);
        LockedBalance memory _locked = locked[msg.sender];
        _unlockTime = (_unlockTime / WEEK) * WEEK; // Locktime is rounded down to weeks

        require(_locked.end > block.timestamp, "VE006");
        require(_locked.amount > 0, "VE007");
        require(_unlockTime > _locked.end, "VE008");
        require(_unlockTime <= block.timestamp + MAXTIME, "VE009");

        _depositFor(msg.sender, msg.sender, 0, _unlockTime, _locked, _INCREASE_UNLOCK_TIME, 0, 0, "");
    }

    /***
     * @dev Withdraw all tokens for `msg.sender`
     * @dev Only possible if the lock has expired
     */
    function withdraw() external override nonReentrant {
        LockedBalance memory _locked = LockedBalance(locked[msg.sender].amount, locked[msg.sender].end);

        require(block.timestamp >= _locked.end, "VE010");
        uint256 _value = uint256(_locked.amount);

        LockedBalance memory _oldLocked = LockedBalance(locked[msg.sender].amount, locked[msg.sender].end);

        _locked.end = 0;
        _locked.amount = 0;
        locked[msg.sender] = _locked;
        uint256 _supplyBefore = supply;
        supply = _supplyBefore - _value;

        // _oldLocked can have either expired <= timestamp or zero end
        // _locked has only 0 end
        // Both can have >= 0 amount
        _checkpoint(msg.sender, _oldLocked, _locked);

        TransferHelper.doTransferOut(token, msg.sender, _value);

        emit Withdraw(msg.sender, _value, block.timestamp);
        emit Supply(_supplyBefore, _supplyBefore - _value);
    }

    // The following ERC20/minime-compatible methods are not real balanceOf and supply!
    // They measure the weights for the purpose of voting, so they don't represent
    // real coins.

    /***
     * @dev Binary search to estimate timestamp for block number
     * @param blockNumber Block to find
     * @param maxEpoch Don't go beyond this epoch
     * @return Approximate timestamp for block
     */
    function _findBlockEpoch(uint256 blockNumber, uint256 maxEpoch) internal view returns (uint256) {
        // Binary search
        uint256 _min = 0;
        uint256 _max = maxEpoch;
        for (uint256 i; i <= 128; i++) {
            // Will be always enough for 128-bit numbers
            if (_min >= _max) {
                break;
            }
            uint256 _mid = (_min + _max + 1) / 2;
            if (supplyPointHistory[_mid].blk <= blockNumber) {
                _min = _mid;
            } else {
                _max = _mid - 1;
            }
        }
        return _min;
    }

    /***
     * @notice Get the current voting power for `msg.sender`
     * @dev Adheres to the ERC20 `balanceOf` interface for Metamask & Snapshot compatibility
     * @param _addr User wallet address
     * @return User's present voting power
     */
    function balanceOf(address _addr) external view returns (uint256) {
        uint256 _t = block.timestamp;

        uint256 _epoch = userPointEpoch[_addr];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory _lastPoint = userPointHistory[_addr][_epoch];
            unchecked {
                _lastPoint.bias -= _lastPoint.slope * int256(_t - _lastPoint.ts);
            }
            if (_lastPoint.bias < 0) {
                _lastPoint.bias = 0;
            }
            return uint256(_lastPoint.bias);
        }
    }

    /***
     * @notice Get the current voting power for `msg.sender`
     * @dev Adheres to the ERC20 `balanceOf` interface for Aragon compatibility
     * @param _addr User wallet address
     * @param _t Epoch time to return voting power at
     * @return User voting power
     * @dev return the present voting power if _t is 0
     */
    function balanceOfAtTime(address _addr, uint256 _t) external view override returns (uint256) {
        if (_t == 0) {
            _t = block.timestamp;
        }

        uint256 _epoch = userPointEpoch[_addr];
        if (_epoch == 0) {
            return 0;
        } else {
            Point memory _lastPoint = userPointHistory[_addr][_epoch];
            unchecked {
                _lastPoint.bias -= _lastPoint.slope * int256(_t - _lastPoint.ts);
            }
            if (_lastPoint.bias < 0) {
                _lastPoint.bias = 0;
            }
            return uint256(_lastPoint.bias);
        }
    }

    //Struct to avoid "Stack Too Deep"
    struct Parameters {
        uint256 min;
        uint256 max;
        uint256 maxEpoch;
        uint256 dBlock;
        uint256 dt;
    }

    /***
     * @notice Measure voting power of `_addr` at block height `_block`
     * @dev Adheres to MiniMe `balanceOfAt` interface https//github.com/Giveth/minime
     * @param _addr User's wallet address
     * @param _block Block to calculate the voting power at
     * @return Voting power
     */
    function balanceOfAt(address _addr, uint256 _block) external view returns (uint256) {
        // Copying and pasting totalSupply code because Vyper cannot pass by
        // reference yet
        require(_block <= block.number, "VE011");

        Parameters memory _st;

        // Binary search
        _st.min = 0;
        _st.max = userPointEpoch[_addr];

        for (uint256 i; i <= 128; i++) {
            // Will be always enough for 128-bit numbers
            if (_st.min >= _st.max) {
                break;
            }
            uint256 _mid = (_st.min + _st.max + 1) / 2;
            if (userPointHistory[_addr][_mid].blk <= _block) {
                _st.min = _mid;
            } else {
                _st.max = _mid - 1;
            }
        }
        Point memory _upoint = userPointHistory[_addr][_st.min];

        _st.maxEpoch = epoch;
        uint256 _epoch = _findBlockEpoch(_block, _st.maxEpoch);
        Point memory _point = supplyPointHistory[_epoch];
        _st.dBlock = 0;
        _st.dt = 0;
        if (_epoch < _st.maxEpoch) {
            Point memory _point1 = supplyPointHistory[_epoch + 1];
            _st.dBlock = _point1.blk - _point.blk;
            _st.dt = _point1.ts - _point.ts;
        } else {
            _st.dBlock = block.number - _point.blk;
            _st.dt = block.timestamp - _point.ts;
        }
        uint256 blockTime = _point.ts;
        if (_st.dBlock != 0) {
            blockTime += (_st.dt * (_block - _point.blk)) / _st.dBlock;
        }

        unchecked {
            _upoint.bias -= _upoint.slope * int256(blockTime - _upoint.ts);
        }
        if (_upoint.bias >= 0) {
            return uint256(_upoint.bias);
        } else {
            return 0;
        }
    }

    /***
     * @dev Calculate total voting power at some point in the past
     * @param point The point (bias/slope) to start search from
     * @param t Time to calculate the total voting power at
     * @return Total voting power at that time
     */
    function _supplyAt(Point memory point, uint256 t) internal view returns (uint256) {
        Point memory _lastPoint = point;
        uint256 _ti = (_lastPoint.ts / WEEK) * WEEK;
        for (uint256 i; i < 255; i++) {
            _ti += WEEK;
            int256 dSlope = 0;

            if (_ti > t) {
                _ti = t;
            } else {
                dSlope = slopeChanges[_ti];
            }
            unchecked {
                _lastPoint.bias -= _lastPoint.slope * int256(_ti - _lastPoint.ts);
            }
            if (_ti == t) {
                break;
            }
            _lastPoint.slope += dSlope;
            _lastPoint.ts = _ti;
        }

        if (_lastPoint.bias < 0) {
            _lastPoint.bias = 0;
        }
        return uint256(_lastPoint.bias);
    }

    /***
     * @notice Calculate total voting power
     * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     * @return Total voting power
     */
    function totalSupply() external view override returns (uint256) {
        uint256 _epoch = epoch;
        Point memory _lastPoint = supplyPointHistory[_epoch];

        return _supplyAt(_lastPoint, block.timestamp);
    }

    /***
     * @notice Calculate total voting power
     * @dev Adheres to the ERC20 `totalSupply` interface for Aragon compatibility
     * @return Total voting power
     */
    function totalSupplyAtTime(uint256 _t) external view override returns (uint256) {
        if (_t == 0) {
            _t = block.timestamp;
        }

        uint256 _epoch = epoch;
        Point memory _lastPoint = supplyPointHistory[_epoch];

        return _supplyAt(_lastPoint, _t);
    }

    /***
     * @notice Calculate total voting power at some point in the past
     * @param _block Block to calculate the total voting power at
     * @return Total voting power at `_block`
     */
    function totalSupplyAt(uint256 _block) external view returns (uint256) {
        require(_block <= block.number, "VE011");
        uint256 _epoch = epoch;
        uint256 _targetEpoch = _findBlockEpoch(_block, _epoch);

        Point memory _point = supplyPointHistory[_targetEpoch];
        uint256 dt = 0;
        if (_targetEpoch < _epoch) {
            Point memory _pointNext = supplyPointHistory[_targetEpoch + 1];
            if (_point.blk != _pointNext.blk) {
                dt = ((_block - _point.blk) * (_pointNext.ts - _point.ts)) / (_pointNext.blk - _point.blk);
            }
        } else {
            if (_point.blk != block.number) {
                dt = ((_block - _point.blk) * (block.timestamp - _point.ts)) / (block.number - _point.blk);
            }
        }
        // Now dt contains info on how far are we beyond point

        return _supplyAt(_point, _point.ts + dt);
    }

    /**
     * @notice Set an external contract to check for approved smart contract wallets
     * @param _check  Address of Smart contract checker
     */
    function setSmartWalletChecker(address _check) external onlyOwner {
        address oldChecker = smartWalletChecker;
        smartWalletChecker = _check;
        emit SetSmartWalletChecker(msg.sender, _check, oldChecker);
    }

    /**
     * @dev Set permit2 address, onlyOwner
     * @param newAddress New permit2 address
     */
    function setPermit2Address(address newAddress) external onlyOwner {
        require(newAddress != address(0), "CE000");
        address oldAddress = permit2Address;
        permit2Address = newAddress;
        emit SetPermit2Address(oldAddress, newAddress);
    }

    /**
     * @notice Check if the call is from a whitelisted smart contract, revert if not
     * @param addr Address to be checked
     */
    function _assertNotContract(address addr) internal view {
        if (addr != tx.origin) {
            if (smartWalletChecker != address(0)) {
                if (SmartWalletChecker(smartWalletChecker).check(addr)) {
                    return;
                }
            }
            revert("Smart contract depositors not allowed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

interface IPermit2 {
    /// @notice The token and amount details for a transfer signed in the permit transfer signature
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice Specifies the recipient address and amount for batched transfers.
    /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
    /// @dev Reverts if the requested amount is greater than the permitted signed amount.
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /// @notice Used to reconstruct the signed permit message for multiple token transfers
    /// @dev Do not need to pass in spender address as it is required that it is msg.sender
    /// @dev Note that a user still signs over a spender address
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
    /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
    /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
    /// @dev It returns a uint256 bitmap
    /// @dev The index, or wordPosition is capped at type(uint248).max
    function nonceBitmap(address, uint256) external view returns (uint256);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers a token using a signed permit message
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Invalidates the bits specified in mask for the bitmap at the word position
    /// @dev The wordPos is maxed at type(uint248).max
    /// @param wordPos A number to index the nonceBitmap at
    /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

library LibTime {

    // 7 * 86400 seconds - all future times are rounded by week
    uint256 public constant DAY = 86400;
    uint256 public constant WEEK = DAY * 7;

    /**
     * @dev times are rounded by week
     * @param time time
     */
    function timesRoundedByWeek(uint256 time) internal pure returns (uint256) {
        return (time / WEEK) * WEEK;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

library StringUtils {
    // This code has not been professionally audited, therefore I cannot make any promises about
    // safety or correctness. Use at own risk.
    function hashCompareWithLengthCheck(string memory a, string memory b) internal pure returns (bool) {
        if (bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(bytes(a)) == keccak256(bytes(b));
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0

pragma solidity 0.8.17;

import "./IERC20.sol";
import "./IPermit2.sol";

library TransferHelper {
    
    /**
     * @dev Similar to EIP20 transfer, except it handles a False result from `transferFrom` and reverts in that case.
     *      This will revert due to insufficient balance or insufficient allowance.
     *      This function returns the actual amount received,
     *      which may be less than `amount` if there is a fee attached to the transfer.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     */
    function doTransferFrom(address tokenAddress, address from, address to, uint256 amount) internal {
        IERC20 token = IERC20(tokenAddress);
        safeTransferFrom(token, from, to, amount);
    }

    /**
     * @dev transfer with permit2
     */
    function doTransferIn(
        address permit2Address,
        address tokenAddress,
        uint256 _value,
        address from,
        uint256 nonce,
        uint256 deadline,
        bytes memory signature
    ) internal returns (uint256) {
        IPermit2.PermitTransferFrom memory permit = IPermit2.PermitTransferFrom({
            permitted: IPermit2.TokenPermissions({token: tokenAddress, amount: _value}),
            nonce: nonce,
            deadline: deadline
        });
        IPermit2.SignatureTransferDetails memory transferDetails = IPermit2.SignatureTransferDetails({
            to: address(this),
            requestedAmount: _value
        });
        // Read from storage once
        IERC20 token = IERC20(permit.permitted.token);
        uint256 balanceBefore = token.balanceOf(transferDetails.to);
        if (nonce == 0 && deadline == 0 && signature.length == 0) {
            safeTransferFrom(token, from, transferDetails.to, transferDetails.requestedAmount);
        } else {
            IPermit2(permit2Address).permitTransferFrom(permit, transferDetails, from, signature);
        }
        // Calculate the amount that was *actually* transferred
        uint256 balanceAfter = IERC20(permit.permitted.token).balanceOf(address(this));
        uint256 spendAmount = balanceAfter - balanceBefore;
        assert(spendAmount == transferDetails.requestedAmount);
        
        return spendAmount;
    }

    /**
     * @dev Similar to EIP20 transfer, except it handles a False success from `transfer` and returns an explanatory
     *      error code rather than reverting. If caller has not called checked protocol's balance, this may revert due to
     *      insufficient cash held in this contract. If caller has checked protocol's balance prior to this call, and verified
     *      it is >= amount, this should not revert in normal conditions.
     *
     *      Note: This wrapper safely handles non-standard ERC-20 tokens that do not return a value.
     */
    function doTransferOut(address tokenAddress, address to, uint256 amount) internal {
        IERC20 token = IERC20(tokenAddress);
        safeTransfer(token, to, amount);
    }

    function doApprove(address tokenAddress, address to, uint256 amount) internal {
        IERC20 token = IERC20(tokenAddress);
        safeApprove(token, to, amount);
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {PermitHash} from "./libraries/PermitHash.sol";
import {SignatureVerification} from "./libraries/SignatureVerification.sol";
import {EIP712} from "./EIP712.sol";
import {IAllowanceTransfer} from "./interfaces/IAllowanceTransfer.sol";
import {SignatureExpired, InvalidNonce} from "./PermitErrors.sol";
import {Allowance} from "./libraries/Allowance.sol";

contract AllowanceTransfer is IAllowanceTransfer, EIP712 {
    using SignatureVerification for bytes;
    using SafeTransferLib for ERC20;
    using PermitHash for PermitSingle;
    using PermitHash for PermitBatch;
    using Allowance for PackedAllowance;

    /// @notice Maps users to tokens to spender addresses and information about the approval on the token
    /// @dev Indexed in the order of token owner address, token address, spender address
    /// @dev The stored word saves the allowed amount, expiration on the allowance, and nonce
    mapping(address => mapping(address => mapping(address => PackedAllowance))) public allowance;

    /// @inheritdoc IAllowanceTransfer
    function approve(address token, address spender, uint160 amount, uint48 expiration) external {
        PackedAllowance storage allowed = allowance[msg.sender][token][spender];
        allowed.updateAmountAndExpiration(amount, expiration);
        emit Approval(msg.sender, token, spender, amount, expiration);
    }

    /// @inheritdoc IAllowanceTransfer
    function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external {
        if (block.timestamp > permitSingle.sigDeadline) revert SignatureExpired(permitSingle.sigDeadline);

        // Verify the signer address from the signature.
        signature.verify(_hashTypedData(permitSingle.hash()), owner);

        _updateApproval(permitSingle.details, owner, permitSingle.spender);
    }

    /// @inheritdoc IAllowanceTransfer
    function permit(address owner, PermitBatch memory permitBatch, bytes calldata signature) external {
        if (block.timestamp > permitBatch.sigDeadline) revert SignatureExpired(permitBatch.sigDeadline);

        // Verify the signer address from the signature.
        signature.verify(_hashTypedData(permitBatch.hash()), owner);

        address spender = permitBatch.spender;
        unchecked {
            uint256 length = permitBatch.details.length;
            for (uint256 i = 0; i < length; ++i) {
                _updateApproval(permitBatch.details[i], owner, spender);
            }
        }
    }

    /// @inheritdoc IAllowanceTransfer
    function transferFrom(address from, address to, uint160 amount, address token) external {
        _transfer(from, to, amount, token);
    }

    /// @inheritdoc IAllowanceTransfer
    function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external {
        unchecked {
            uint256 length = transferDetails.length;
            for (uint256 i = 0; i < length; ++i) {
                AllowanceTransferDetails memory transferDetail = transferDetails[i];
                _transfer(transferDetail.from, transferDetail.to, transferDetail.amount, transferDetail.token);
            }
        }
    }

    /// @notice Internal function for transferring tokens using stored allowances
    /// @dev Will fail if the allowed timeframe has passed
    function _transfer(address from, address to, uint160 amount, address token) private {
        PackedAllowance storage allowed = allowance[from][token][msg.sender];

        if (block.timestamp > allowed.expiration) revert AllowanceExpired(allowed.expiration);

        uint256 maxAmount = allowed.amount;
        if (maxAmount != type(uint160).max) {
            if (amount > maxAmount) {
                revert InsufficientAllowance(maxAmount);
            } else {
                unchecked {
                    allowed.amount = uint160(maxAmount) - amount;
                }
            }
        }

        // Transfer the tokens from the from address to the recipient.
        ERC20(token).safeTransferFrom(from, to, amount);
    }

    /// @inheritdoc IAllowanceTransfer
    function lockdown(TokenSpenderPair[] calldata approvals) external {
        address owner = msg.sender;
        // Revoke allowances for each pair of spenders and tokens.
        unchecked {
            uint256 length = approvals.length;
            for (uint256 i = 0; i < length; ++i) {
                address token = approvals[i].token;
                address spender = approvals[i].spender;

                allowance[owner][token][spender].amount = 0;
                emit Lockdown(owner, token, spender);
            }
        }
    }

    /// @inheritdoc IAllowanceTransfer
    function invalidateNonces(address token, address spender, uint48 newNonce) external {
        uint48 oldNonce = allowance[msg.sender][token][spender].nonce;

        if (newNonce <= oldNonce) revert InvalidNonce();

        // Limit the amount of nonces that can be invalidated in one transaction.
        unchecked {
            uint48 delta = newNonce - oldNonce;
            if (delta > type(uint16).max) revert ExcessiveInvalidation();
        }

        allowance[msg.sender][token][spender].nonce = newNonce;
        emit NonceInvalidation(msg.sender, token, spender, newNonce, oldNonce);
    }

    /// @notice Sets the new values for amount, expiration, and nonce.
    /// @dev Will check that the signed nonce is equal to the current nonce and then incrememnt the nonce value by 1.
    /// @dev Emits a Permit event.
    function _updateApproval(PermitDetails memory details, address owner, address spender) private {
        uint48 nonce = details.nonce;
        address token = details.token;
        uint160 amount = details.amount;
        uint48 expiration = details.expiration;
        PackedAllowance storage allowed = allowance[owner][token][spender];

        if (allowed.nonce != nonce) revert InvalidNonce();

        allowed.updateAll(amount, expiration, nonce);
        emit Permit(owner, token, spender, amount, expiration, nonce);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice EIP712 helpers for permit2
/// @dev Maintains cross-chain replay protection in the event of a fork
/// @dev Reference: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/EIP712.sol
contract EIP712 {
    // Cache the domain separator as an immutable value, but also store the chain id that it
    // corresponds to, in order to invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;

    bytes32 private constant _HASHED_NAME = keccak256("Permit2");
    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    constructor() {
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME);
    }

    /// @notice Returns the domain separator for the current chain.
    /// @dev Uses cached version if chainid and address are unchanged from construction.
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return block.chainid == _CACHED_CHAIN_ID
            ? _CACHED_DOMAIN_SEPARATOR
            : _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME);
    }

    /// @notice Builds a domain separator using the current chainId and contract address.
    function _buildDomainSeparator(bytes32 typeHash, bytes32 nameHash) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, block.chainid, address(this)));
    }

    /// @notice Creates an EIP-712 typed data hash
    function _hashTypedData(bytes32 dataHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), dataHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title AllowanceTransfer
/// @notice Handles ERC20 token permissions through signature based allowance setting and ERC20 token transfers by checking allowed amounts
/// @dev Requires user's token approval on the Permit2 contract
interface IAllowanceTransfer {
    /// @notice Thrown when an allowance on a token has expired.
    /// @param deadline The timestamp at which the allowed amount is no longer valid
    error AllowanceExpired(uint256 deadline);

    /// @notice Thrown when an allowance on a token has been depleted.
    /// @param amount The maximum amount allowed
    error InsufficientAllowance(uint256 amount);

    /// @notice Thrown when too many nonces are invalidated.
    error ExcessiveInvalidation();

    /// @notice Emits an event when the owner successfully invalidates an ordered nonce.
    event NonceInvalidation(
        address indexed owner, address indexed token, address indexed spender, uint48 newNonce, uint48 oldNonce
    );

    /// @notice Emits an event when the owner successfully sets permissions on a token for the spender.
    event Approval(
        address indexed owner, address indexed token, address indexed spender, uint160 amount, uint48 expiration
    );

    /// @notice Emits an event when the owner successfully sets permissions using a permit signature on a token for the spender.
    event Permit(
        address indexed owner,
        address indexed token,
        address indexed spender,
        uint160 amount,
        uint48 expiration,
        uint48 nonce
    );

    /// @notice Emits an event when the owner sets the allowance back to 0 with the lockdown function.
    event Lockdown(address indexed owner, address token, address spender);

    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The permit message signed for multiple token allowances
    struct PermitBatch {
        // the permit data for multiple token allowances
        PermitDetails[] details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }

    /// @notice The saved permissions
    /// @dev This info is saved per owner, per token, per spender and all signed over in the permit message
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    struct PackedAllowance {
        // amount allowed
        uint160 amount;
        // permission expiry
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice A token spender pair.
    struct TokenSpenderPair {
        // the token the spender is approved
        address token;
        // the spender address
        address spender;
    }

    /// @notice Details for a token transfer.
    struct AllowanceTransferDetails {
        // the owner of the token
        address from;
        // the recipient of the token
        address to;
        // the amount of the token
        uint160 amount;
        // the token to be transferred
        address token;
    }

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(address, address, address) external view returns (uint160, uint48, uint48);

    /// @notice Approves the spender to use up to amount of the specified token up until the expiration
    /// @param token The token to approve
    /// @param spender The spender address to approve
    /// @param amount The approved amount of the token
    /// @param expiration The timestamp at which the approval is no longer valid
    /// @dev The packed allowance also holds a nonce, which will stay unchanged in approve
    /// @dev Setting amount to type(uint160).max sets an unlimited approval
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;

    /// @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitSingle Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitSingle memory permitSingle, bytes calldata signature) external;

    /// @notice Permit a spender to the signed amounts of the owners tokens via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitBatch Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(address owner, PermitBatch memory permitBatch, bytes calldata signature) external;

    /// @notice Transfer approved tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    /// @param token The token address to transfer
    /// @dev Requires the from address to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(address from, address to, uint160 amount, address token) external;

    /// @notice Transfer approved tokens in a batch
    /// @param transferDetails Array of owners, recipients, amounts, and tokens for the transfers
    /// @dev Requires the from addresses to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(AllowanceTransferDetails[] calldata transferDetails) external;

    /// @notice Enables performing a "lockdown" of the sender's Permit2 identity
    /// by batch revoking approvals
    /// @param approvals Array of approvals to revoke.
    function lockdown(TokenSpenderPair[] calldata approvals) external;

    /// @notice Invalidate nonces for a given (token, spender) pair
    /// @param token The token to invalidate nonces for
    /// @param spender The spender to invalidate nonces for
    /// @param newNonce The new nonce to set. Invalidates all nonces less than it.
    /// @dev Can't invalidate more than 2**16 nonces per transaction.
    function invalidateNonces(address token, address spender, uint48 newNonce) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC1271 {
    /// @dev Should return whether the signature provided is valid for the provided data
    /// @param hash      Hash of the data to be signed
    /// @param signature Signature byte array associated with _data
    /// @return magicValue The bytes4 magic value 0x1626ba7e
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title SignatureTransfer
/// @notice Handles ERC20 token transfers through signature based actions
/// @dev Requires user's token approval on the Permit2 contract
interface ISignatureTransfer {
    /// @notice Thrown when the requested amount for a transfer is larger than the permissioned amount
    /// @param maxAmount The maximum amount a spender can request to transfer
    error InvalidAmount(uint256 maxAmount);

    /// @notice Thrown when the number of tokens permissioned to a spender does not match the number of tokens being transferred
    /// @dev If the spender does not need to transfer the number of tokens permitted, the spender can request amount 0 to be transferred
    error LengthMismatch();

    /// @notice Emits an event when the owner successfully invalidates an unordered nonce.
    event UnorderedNonceInvalidation(address indexed owner, uint256 word, uint256 mask);

    /// @notice The token and amount details for a transfer signed in the permit transfer signature
    struct TokenPermissions {
        // ERC20 token address
        address token;
        // the maximum amount that can be spent
        uint256 amount;
    }

    /// @notice The signed permit message for a single token transfer
    struct PermitTransferFrom {
        TokenPermissions permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice Specifies the recipient address and amount for batched transfers.
    /// @dev Recipients and amounts correspond to the index of the signed token permissions array.
    /// @dev Reverts if the requested amount is greater than the permitted signed amount.
    struct SignatureTransferDetails {
        // recipient address
        address to;
        // spender requested amount
        uint256 requestedAmount;
    }

    /// @notice Used to reconstruct the signed permit message for multiple token transfers
    /// @dev Do not need to pass in spender address as it is required that it is msg.sender
    /// @dev Note that a user still signs over a spender address
    struct PermitBatchTransferFrom {
        // the tokens and corresponding amounts permitted for a transfer
        TokenPermissions[] permitted;
        // a unique value for every token owner's signature to prevent signature replays
        uint256 nonce;
        // deadline on the permit signature
        uint256 deadline;
    }

    /// @notice A map from token owner address and a caller specified word index to a bitmap. Used to set bits in the bitmap to prevent against signature replay protection
    /// @dev Uses unordered nonces so that permit messages do not need to be spent in a certain order
    /// @dev The mapping is indexed first by the token owner, then by an index specified in the nonce
    /// @dev It returns a uint256 bitmap
    /// @dev The index, or wordPosition is capped at type(uint248).max
    function nonceBitmap(address, uint256) external view returns (uint256);

    /// @notice Transfers a token using a signed permit message
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers a token using a signed permit message
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @dev Reverts if the requested amount is greater than the permitted signed amount
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param signature The signature to verify
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice Transfers multiple tokens using a signed permit message
    /// @dev The witness type string must follow EIP712 ordering of nested structs and must include the TokenPermissions type definition
    /// @notice Includes extra data provided by the caller to verify signature over
    /// @param permit The permit data signed over by the owner
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails Specifies the recipient and requested amount for the token transfer
    /// @param witness Extra data to include when checking the user signature
    /// @param witnessTypeString The EIP-712 type definition for remaining string stub of the typehash
    /// @param signature The signature to verify
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external;

    /// @notice Invalidates the bits specified in mask for the bitmap at the word position
    /// @dev The wordPos is maxed at type(uint248).max
    /// @param wordPos A number to index the nonceBitmap at
    /// @param mask A bitmap masked against msg.sender's current bitmap at the word position
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IAllowanceTransfer} from "../interfaces/IAllowanceTransfer.sol";

library Allowance {
    // note if the expiration passed is 0, then it the approval set to the block.timestamp
    uint256 private constant BLOCK_TIMESTAMP_EXPIRATION = 0;

    /// @notice Sets the allowed amount, expiry, and nonce of the spender's permissions on owner's token.
    /// @dev Nonce is incremented.
    /// @dev If the inputted expiration is 0, the stored expiration is set to block.timestamp
    function updateAll(
        IAllowanceTransfer.PackedAllowance storage allowed,
        uint160 amount,
        uint48 expiration,
        uint48 nonce
    ) internal {
        uint48 storedNonce;
        unchecked {
            storedNonce = nonce + 1;
        }

        uint48 storedExpiration = expiration == BLOCK_TIMESTAMP_EXPIRATION ? uint48(block.timestamp) : expiration;

        uint256 word = pack(amount, storedExpiration, storedNonce);
        assembly {
            sstore(allowed.slot, word)
        }
    }

    /// @notice Sets the allowed amount and expiry of the spender's permissions on owner's token.
    /// @dev Nonce does not need to be incremented.
    function updateAmountAndExpiration(
        IAllowanceTransfer.PackedAllowance storage allowed,
        uint160 amount,
        uint48 expiration
    ) internal {
        // If the inputted expiration is 0, the allowance only lasts the duration of the block.
        allowed.expiration = expiration == 0 ? uint48(block.timestamp) : expiration;
        allowed.amount = amount;
    }

    /// @notice Computes the packed slot of the amount, expiration, and nonce that make up PackedAllowance
    function pack(uint160 amount, uint48 expiration, uint48 nonce) internal pure returns (uint256 word) {
        word = (uint256(nonce) << 208) | uint256(expiration) << 160 | amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IAllowanceTransfer} from "../interfaces/IAllowanceTransfer.sol";
import {ISignatureTransfer} from "../interfaces/ISignatureTransfer.sol";

library PermitHash {
    bytes32 public constant _PERMIT_DETAILS_TYPEHASH =
        keccak256("PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)");

    bytes32 public constant _PERMIT_SINGLE_TYPEHASH = keccak256(
        "PermitSingle(PermitDetails details,address spender,uint256 sigDeadline)PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)"
    );

    bytes32 public constant _PERMIT_BATCH_TYPEHASH = keccak256(
        "PermitBatch(PermitDetails[] details,address spender,uint256 sigDeadline)PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)"
    );

    bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");

    bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );

    bytes32 public constant _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitBatchTransferFrom(TokenPermissions[] permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );

    string public constant _TOKEN_PERMISSIONS_TYPESTRING = "TokenPermissions(address token,uint256 amount)";

    string public constant _PERMIT_TRANSFER_FROM_WITNESS_TYPEHASH_STUB =
        "PermitWitnessTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline,";

    string public constant _PERMIT_BATCH_WITNESS_TRANSFER_FROM_TYPEHASH_STUB =
        "PermitBatchWitnessTransferFrom(TokenPermissions[] permitted,address spender,uint256 nonce,uint256 deadline,";

    function hash(IAllowanceTransfer.PermitSingle memory permitSingle) internal pure returns (bytes32) {
        bytes32 permitHash = _hashPermitDetails(permitSingle.details);
        return
            keccak256(abi.encode(_PERMIT_SINGLE_TYPEHASH, permitHash, permitSingle.spender, permitSingle.sigDeadline));
    }

    function hash(IAllowanceTransfer.PermitBatch memory permitBatch) internal pure returns (bytes32) {
        uint256 numPermits = permitBatch.details.length;
        bytes32[] memory permitHashes = new bytes32[](numPermits);
        for (uint256 i = 0; i < numPermits; ++i) {
            permitHashes[i] = _hashPermitDetails(permitBatch.details[i]);
        }
        return keccak256(
            abi.encode(
                _PERMIT_BATCH_TYPEHASH,
                keccak256(abi.encodePacked(permitHashes)),
                permitBatch.spender,
                permitBatch.sigDeadline
            )
        );
    }

    function hash(ISignatureTransfer.PermitTransferFrom memory permit) internal view returns (bytes32) {
        bytes32 tokenPermissionsHash = _hashTokenPermissions(permit.permitted);
        return keccak256(
            abi.encode(_PERMIT_TRANSFER_FROM_TYPEHASH, tokenPermissionsHash, msg.sender, permit.nonce, permit.deadline)
        );
    }

    function hash(ISignatureTransfer.PermitBatchTransferFrom memory permit) internal view returns (bytes32) {
        uint256 numPermitted = permit.permitted.length;
        bytes32[] memory tokenPermissionHashes = new bytes32[](numPermitted);

        for (uint256 i = 0; i < numPermitted; ++i) {
            tokenPermissionHashes[i] = _hashTokenPermissions(permit.permitted[i]);
        }

        return keccak256(
            abi.encode(
                _PERMIT_BATCH_TRANSFER_FROM_TYPEHASH,
                keccak256(abi.encodePacked(tokenPermissionHashes)),
                msg.sender,
                permit.nonce,
                permit.deadline
            )
        );
    }

    function hashWithWitness(
        ISignatureTransfer.PermitTransferFrom memory permit,
        bytes32 witness,
        string calldata witnessTypeString
    ) internal view returns (bytes32) {
        bytes32 typeHash = keccak256(abi.encodePacked(_PERMIT_TRANSFER_FROM_WITNESS_TYPEHASH_STUB, witnessTypeString));

        bytes32 tokenPermissionsHash = _hashTokenPermissions(permit.permitted);
        return keccak256(abi.encode(typeHash, tokenPermissionsHash, msg.sender, permit.nonce, permit.deadline, witness));
    }

    function hashWithWitness(
        ISignatureTransfer.PermitBatchTransferFrom memory permit,
        bytes32 witness,
        string calldata witnessTypeString
    ) internal view returns (bytes32) {
        bytes32 typeHash =
            keccak256(abi.encodePacked(_PERMIT_BATCH_WITNESS_TRANSFER_FROM_TYPEHASH_STUB, witnessTypeString));

        uint256 numPermitted = permit.permitted.length;
        bytes32[] memory tokenPermissionHashes = new bytes32[](numPermitted);

        for (uint256 i = 0; i < numPermitted; ++i) {
            tokenPermissionHashes[i] = _hashTokenPermissions(permit.permitted[i]);
        }

        return keccak256(
            abi.encode(
                typeHash,
                keccak256(abi.encodePacked(tokenPermissionHashes)),
                msg.sender,
                permit.nonce,
                permit.deadline,
                witness
            )
        );
    }

    function _hashPermitDetails(IAllowanceTransfer.PermitDetails memory details) private pure returns (bytes32) {
        return keccak256(abi.encode(_PERMIT_DETAILS_TYPEHASH, details));
    }

    function _hashTokenPermissions(ISignatureTransfer.TokenPermissions memory permitted)
        private
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permitted));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC1271} from "../interfaces/IERC1271.sol";

library SignatureVerification {
    /// @notice Thrown when the passed in signature is not a valid length
    error InvalidSignatureLength();

    /// @notice Thrown when the recovered signer is equal to the zero address
    error InvalidSignature();

    /// @notice Thrown when the recovered signer does not equal the claimedSigner
    error InvalidSigner();

    /// @notice Thrown when the recovered contract signature is incorrect
    error InvalidContractSignature();

    bytes32 constant UPPER_BIT_MASK = (0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);

    function verify(bytes calldata signature, bytes32 hash, address claimedSigner) internal view {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (claimedSigner.code.length == 0) {
            if (signature.length == 65) {
                (r, s) = abi.decode(signature, (bytes32, bytes32));
                v = uint8(signature[64]);
            } else if (signature.length == 64) {
                // EIP-2098
                bytes32 vs;
                (r, vs) = abi.decode(signature, (bytes32, bytes32));
                s = vs & UPPER_BIT_MASK;
                v = uint8(uint256(vs >> 255)) + 27;
            } else {
                revert InvalidSignatureLength();
            }
            address signer = ecrecover(hash, v, r, s);
            if (signer == address(0)) revert InvalidSignature();
            if (signer != claimedSigner) revert InvalidSigner();
        } else {
            bytes4 magicValue = IERC1271(claimedSigner).isValidSignature(hash, signature);
            if (magicValue != IERC1271.isValidSignature.selector) revert InvalidContractSignature();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Shared errors between signature based transfers and allowance based transfers.

/// @notice Thrown when validating an inputted signature that is stale
/// @param signatureDeadline The timestamp at which a signature is no longer valid
error SignatureExpired(uint256 signatureDeadline);

/// @notice Thrown when validating that the inputted nonce has not been used
error InvalidNonce();

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ISignatureTransfer} from "./interfaces/ISignatureTransfer.sol";
import {SignatureExpired, InvalidNonce} from "./PermitErrors.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {SignatureVerification} from "./libraries/SignatureVerification.sol";
import {PermitHash} from "./libraries/PermitHash.sol";
import {EIP712} from "./EIP712.sol";

contract SignatureTransfer is ISignatureTransfer, EIP712 {
    using SignatureVerification for bytes;
    using SafeTransferLib for ERC20;
    using PermitHash for PermitTransferFrom;
    using PermitHash for PermitBatchTransferFrom;

    /// @inheritdoc ISignatureTransfer
    mapping(address => mapping(uint256 => uint256)) public nonceBitmap;

    /// @inheritdoc ISignatureTransfer
    function permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external {
        _permitTransferFrom(permit, transferDetails, owner, permit.hash(), signature);
    }

    /// @inheritdoc ISignatureTransfer
    function permitWitnessTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external {
        _permitTransferFrom(permit, transferDetails, owner, permit.hashWithWitness(witness, witnessTypeString), signature);
    }

    /// @notice Transfers a token using a signed permit message.
    /// @param permit The permit data signed over by the owner
    /// @param dataHash The EIP-712 hash of permit data to include when checking signature
    /// @param owner The owner of the tokens to transfer
    /// @param transferDetails The spender's requested transfer details for the permitted token
    /// @param signature The signature to verify
    function _permitTransferFrom(
        PermitTransferFrom memory permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes32 dataHash,
        bytes calldata signature
    ) private {
        uint256 requestedAmount = transferDetails.requestedAmount;

        if (block.timestamp > permit.deadline) revert SignatureExpired(permit.deadline);
        if (requestedAmount > permit.permitted.amount) revert InvalidAmount(permit.permitted.amount);

        _useUnorderedNonce(owner, permit.nonce);

        signature.verify(_hashTypedData(dataHash), owner);

        ERC20(permit.permitted.token).safeTransferFrom(owner, transferDetails.to, requestedAmount);
    }

    /// @inheritdoc ISignatureTransfer
    function permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external {
        _permitTransferFrom(permit, transferDetails, owner, permit.hash(), signature);
    }

    /// @inheritdoc ISignatureTransfer
    function permitWitnessTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 witness,
        string calldata witnessTypeString,
        bytes calldata signature
    ) external {
        /// avoid stack too deep
        bytes32 dataHash = permit.hashWithWitness(witness, witnessTypeString);
        _permitTransferFrom(permit, transferDetails, owner, dataHash, signature);
    }

    /// @notice Transfers tokens using a signed permit messages
    /// @param permit The permit data signed over by the owner
    /// @param dataHash The EIP-712 hash of permit data to include when checking signature
    /// @param owner The owner of the tokens to transfer
    /// @param signature The signature to verify
    function _permitTransferFrom(
        PermitBatchTransferFrom memory permit,
        SignatureTransferDetails[] calldata transferDetails,
        address owner,
        bytes32 dataHash,
        bytes calldata signature
    ) private {
        uint256 numPermitted = permit.permitted.length;

        if (block.timestamp > permit.deadline) revert SignatureExpired(permit.deadline);
        if (numPermitted != transferDetails.length) revert LengthMismatch();

        _useUnorderedNonce(owner, permit.nonce);
        signature.verify(_hashTypedData(dataHash), owner);

        unchecked {
            for (uint256 i = 0; i < numPermitted; ++i) {
                TokenPermissions memory permitted = permit.permitted[i];
                uint256 requestedAmount = transferDetails[i].requestedAmount;

                if (requestedAmount > permitted.amount) revert InvalidAmount(permitted.amount);

                if (requestedAmount != 0) {
                    // allow spender to specify which of the permitted tokens should be transferred
                    ERC20(permitted.token).safeTransferFrom(owner, transferDetails[i].to, requestedAmount);
                }
            }
        }
    }

    /// @inheritdoc ISignatureTransfer
    function invalidateUnorderedNonces(uint256 wordPos, uint256 mask) external {
        nonceBitmap[msg.sender][wordPos] |= mask;

        emit UnorderedNonceInvalidation(msg.sender, wordPos, mask);
    }

    /// @notice Returns the index of the bitmap and the bit position within the bitmap. Used for unordered nonces
    /// @param nonce The nonce to get the associated word and bit positions
    /// @return wordPos The word position or index into the nonceBitmap
    /// @return bitPos The bit position
    /// @dev The first 248 bits of the nonce value is the index of the desired bitmap
    /// @dev The last 8 bits of the nonce value is the position of the bit in the bitmap
    function bitmapPositions(uint256 nonce) private pure returns (uint256 wordPos, uint256 bitPos) {
        wordPos = uint248(nonce >> 8);
        bitPos = uint8(nonce);
    }

    /// @notice Checks whether a nonce is taken and sets the bit at the bit position in the bitmap at the word position
    /// @param from The address to use the nonce at
    /// @param nonce The nonce to spend
    function _useUnorderedNonce(address from, uint256 nonce) internal {
        (uint256 wordPos, uint256 bitPos) = bitmapPositions(nonce);
        uint256 bit = 1 << bitPos;
        uint256 flipped = nonceBitmap[from][wordPos] ^= bit;

        if (flipped & bit == 0) revert InvalidNonce();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}