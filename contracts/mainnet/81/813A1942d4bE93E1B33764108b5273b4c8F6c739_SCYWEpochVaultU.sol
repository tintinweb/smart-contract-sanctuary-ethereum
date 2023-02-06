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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
                        Strings.toHexString(account),
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
}

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
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
            return toHexString(value, Math.log256(value) + 1);
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
pragma solidity 0.8.16;

import { FixedPointMathLib } from "../libraries/FixedPointMathLib.sol";
import { IERC4626Accounting } from "../interfaces/ERC4626/IERC4626Accounting.sol";

// import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// import "hardhat/console.sol";

abstract contract Accounting is IERC4626Accounting {
	using FixedPointMathLib for uint256;

	function totalAssets() public view virtual returns (uint256);

	function totalSupply() public view virtual returns (uint256);

	function toSharesAfterDeposit(uint256 assets) public view virtual returns (uint256) {
		uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.
		uint256 _totalAssets = totalAssets() - assets;
		if (_totalAssets == 0) return assets;
		return supply == 0 ? assets : assets.mulDivDown(supply, _totalAssets);
	}

	function convertToShares(uint256 assets) public view virtual returns (uint256) {
		uint256 supply = totalSupply();

		return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
	}

	function convertToAssets(uint256 shares) public view virtual returns (uint256) {
		uint256 supply = totalSupply(); // Saves an extra SLOAD if totalSupply is non-zero.

		return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
	}

	error ZeroAmount();

	uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

struct AuthConfig {
	address owner;
	address guardian;
	address manager;
}

contract Auth is AccessControl {
	event OwnershipTransferInitiated(address owner, address pendingOwner);
	event OwnershipTransferred(address oldOwner, address newOwner);

	////////// CONSTANTS //////////

	/// Update vault params, perform time-sensitive operations, set manager
	bytes32 public constant GUARDIAN = keccak256("GUARDIAN");

	/// Hot-wallet bots that route funds between vaults, rebalance and harvest strategies
	bytes32 public constant MANAGER = keccak256("MANAGER");

	/// Add and remove vaults and strategies and other critical operations behind timelock
	/// Default admin role
	/// There should only be one owner, so it is not a role
	address public owner;
	address public pendingOwner;

	modifier onlyOwner() {
		require(msg.sender == owner, "ONLY_OWNER");
		_;
	}

	constructor(AuthConfig memory authConfig) {
		/// Set up the roles
		// owner can manage all roles
		owner = authConfig.owner;
		emit OwnershipTransferred(address(0), authConfig.owner);

		// TODO do we want cascading roles like this?
		_grantRole(DEFAULT_ADMIN_ROLE, authConfig.owner);
		_grantRole(GUARDIAN, owner);
		_grantRole(GUARDIAN, authConfig.guardian);
		_grantRole(MANAGER, authConfig.owner);
		_grantRole(MANAGER, authConfig.guardian);
		_grantRole(MANAGER, authConfig.manager);

		/// Allow the guardian role to manage manager
		_setRoleAdmin(MANAGER, GUARDIAN);
	}

	// ----------- Ownership -----------

	/// @dev Init transfer of ownership of the contract to a new account (`_pendingOwner`).
	/// @param _pendingOwner pending owner of contract
	/// Can only be called by the current owner.
	function transferOwnership(address _pendingOwner) external onlyOwner {
		pendingOwner = _pendingOwner;
		emit OwnershipTransferInitiated(owner, pendingOwner);
	}

	/// @dev Accept transfer of ownership of the contract.
	/// Can only be called by the pendingOwner.
	function acceptOwnership() external {
		require(msg.sender == pendingOwner, "ONLY_PENDING_OWNER");
		address oldOwner = owner;
		owner = pendingOwner;

		// revoke the DEFAULT ADMIN ROLE from prev owner
		_revokeRole(DEFAULT_ADMIN_ROLE, oldOwner);
		_revokeRole(GUARDIAN, oldOwner);
		_revokeRole(MANAGER, oldOwner);

		_grantRole(DEFAULT_ADMIN_ROLE, owner);
		_grantRole(GUARDIAN, owner);
		_grantRole(MANAGER, owner);

		emit OwnershipTransferred(oldOwner, owner);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { AuthConfig } from "./Auth.sol";

contract AuthU is AccessControlUpgradeable {
	event OwnershipTransferInitiated(address owner, address pendingOwner);
	event OwnershipTransferred(address oldOwner, address newOwner);

	////////// CONSTANTS //////////

	/// Update vault params, perform time-sensitive operations, set manager
	bytes32 public constant GUARDIAN = keccak256("GUARDIAN");

	/// Hot-wallet bots that route funds between vaults, rebalance and harvest strategies
	bytes32 public constant MANAGER = keccak256("MANAGER");

	/// Add and remove vaults and strategies and other critical operations behind timelock
	/// Default admin role
	/// There should only be one owner, so it is not a role
	address public owner;
	address public pendingOwner;

	modifier onlyOwner() {
		require(msg.sender == owner, "ONLY_OWNER");
		_;
	}

	/// security no undefined constructor
	constructor() {}

	function __Auth_init(AuthConfig memory authConfig) public onlyInitializing {
		/// Set up the roles
		// owner can manage all roles
		owner = authConfig.owner;
		emit OwnershipTransferred(address(0), authConfig.owner);

		// TODO do we want cascading roles like this?
		_grantRole(DEFAULT_ADMIN_ROLE, authConfig.owner);
		_grantRole(GUARDIAN, owner);
		_grantRole(GUARDIAN, authConfig.guardian);
		_grantRole(MANAGER, authConfig.owner);
		_grantRole(MANAGER, authConfig.guardian);
		_grantRole(MANAGER, authConfig.manager);

		/// Allow the guardian role to manage manager
		_setRoleAdmin(MANAGER, GUARDIAN);
	}

	// ----------- Ownership -----------

	/// @dev Init transfer of ownership of the contract to a new account (`_pendingOwner`).
	/// @param _pendingOwner pending owner of contract
	/// Can only be called by the current owner.
	function transferOwnership(address _pendingOwner) external onlyOwner {
		pendingOwner = _pendingOwner;
		emit OwnershipTransferInitiated(owner, pendingOwner);
	}

	/// @dev Accept transfer of ownership of the contract.
	/// Can only be called by the pendingOwner.
	function acceptOwnership() external {
		require(msg.sender == pendingOwner, "ONLY_PENDING_OWNER");
		address oldOwner = owner;
		owner = pendingOwner;

		// revoke the DEFAULT ADMIN ROLE from prev owner
		_revokeRole(DEFAULT_ADMIN_ROLE, oldOwner);
		_grantRole(DEFAULT_ADMIN_ROLE, owner);

		emit OwnershipTransferred(oldOwner, owner);
	}

	uint256[50] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.16;

import { Accounting } from "./Accounting.sol";
import { SectorErrors } from "../interfaces/SectorErrors.sol";
import { EpochType } from "../interfaces/Structs.sol";

// import "hardhat/console.sol";

struct WithdrawRecord {
	uint256 epoch;
	uint256 shares;
}

abstract contract BatchedWithdrawEpoch is Accounting, SectorErrors {
	// using SafeERC20 for IERC20;

	event RequestWithdraw(address indexed caller, address indexed owner, uint256 shares);

	uint256 public epoch;
	uint256 public pendingRedeem; // pending shares
	uint256 public requestedRedeem; // requested shares
	uint256 public pendingWithdrawU; // pending underlying

	EpochType public constant epochType = EpochType.Withdraw;

	mapping(address => WithdrawRecord) public withdrawLedger;
	mapping(uint256 => uint256) public epochExchangeRate;

	function requestRedeem(uint256 shares) public {
		return requestRedeem(shares, msg.sender);
	}

	function requestRedeem(uint256 shares, address owner) public {
		if (msg.sender != owner) _spendAllowance(owner, msg.sender, shares);
		_requestRedeem(shares, owner, msg.sender);
	}

	/// @dev redeem request records the value of the redeemed shares at the time of request
	/// at the time of claim, user is able to withdraw the minimum of the
	/// current value and value at time of request
	/// this is to prevent users from pre-emptively submitting redeem claims
	/// and claiming any rewards after the request has been made
	function _requestRedeem(
		uint256 shares,
		address owner,
		address redeemer
	) internal {
		_transfer(owner, address(this), shares);
		WithdrawRecord storage withdrawRecord = withdrawLedger[redeemer];
		if (withdrawRecord.shares != 0) revert RedeemRequestExists();

		withdrawRecord.epoch = epoch;
		withdrawRecord.shares = shares;
		// track requested shares
		requestedRedeem += shares;
		emit RequestWithdraw(msg.sender, owner, shares);
	}

	function _redeem(address account) internal returns (uint256 amountOut, uint256 shares) {
		WithdrawRecord storage withdrawRecord = withdrawLedger[account];

		if (withdrawRecord.shares == 0) revert ZeroAmount();

		/// withdrawRecord.epoch can never be greater than current epoch
		if (withdrawRecord.epoch == epoch) revert NotReady();

		shares = withdrawRecord.shares;

		// actual amount out is the smaller of currentValue and redeemValue
		amountOut = (shares * epochExchangeRate[withdrawRecord.epoch]) / 1e18;

		// update total pending redeem
		pendingRedeem -= shares;
		pendingWithdrawU -= amountOut;

		// important pendingRedeem should update prior to beforeWithdraw call
		withdrawRecord.shares = 0;
	}

	function processRedeem(uint256 slippageParam) public virtual;

	/// @notice this methods updates lastEpochTimestamp and alows all pending withdrawals to be completed
	/// @dev ensure that we we have enought funds to process withdrawals
	/// before calling this method
	function _processRedeem(uint256 sharesToUnderlying) internal {
		// store current epoch exchange rate

		epochExchangeRate[epoch] = sharesToUnderlying;

		pendingRedeem += requestedRedeem;
		pendingWithdrawU += (sharesToUnderlying * requestedRedeem) / 1e18;
		requestedRedeem = 0;
		// advance epoch
		++epoch;
	}

	function cancelRedeem() public virtual {
		WithdrawRecord storage withdrawRecord = withdrawLedger[msg.sender];

		if (withdrawRecord.epoch < epoch) revert CannotCancelProccesedRedeem();

		uint256 shares = withdrawRecord.shares;

		// update accounting
		withdrawRecord.shares = 0;
		requestedRedeem -= shares;

		_transfer(address(this), msg.sender, shares);
	}

	/// UTILS
	function redeemIsReady(address user) external view returns (bool) {
		WithdrawRecord storage withdrawRecord = withdrawLedger[user];
		return epoch > withdrawRecord.epoch && withdrawRecord.shares > 0;
	}

	function getWithdrawStatus(address user) external view returns (WithdrawRecord memory) {
		return withdrawLedger[user];
	}

	function getRequestedShares(address user) external view returns (uint256) {
		return withdrawLedger[user].shares;
	}

	/// VIRTUAL ERC20 METHODS

	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal virtual;

	function _spendAllowance(
		address owner,
		address spender,
		uint256 amount
	) internal virtual;

	error RedeemRequestExists();
	error CannotCancelProccesedRedeem();
	error NotNativeAsset();
	error NotReady();

	uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Auth } from "./Auth.sol";

// import "hardhat/console.sol";

struct FeeConfig {
	address treasury;
	uint256 performanceFee;
	uint256 managementFee;
}

abstract contract Fees is Auth {
	uint256 public constant MAX_MANAGEMENT_FEE = .05e18; // 5%
	uint256 public constant MAX_PERFORMANCE_FEE = .25e18; // 25%

	/// @notice The percentage of profit recognized each harvest to reserve as fees.
	/// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
	uint256 public performanceFee;

	/// @notice Annual management fee.
	/// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
	uint256 public managementFee;

	/// @notice address where all fees are sent to
	address public treasury;

	constructor(FeeConfig memory feeConfig) {
		treasury = feeConfig.treasury;
		performanceFee = feeConfig.performanceFee;
		managementFee = feeConfig.managementFee;
		emit SetTreasury(feeConfig.treasury);
		emit SetPerformanceFee(feeConfig.performanceFee);
		emit SetManagementFee(feeConfig.managementFee);
	}

	/// @notice Sets a new performanceFee.
	/// @param _performanceFee The new performance fee.
	function setPerformanceFee(uint256 _performanceFee) public onlyOwner {
		if (_performanceFee > MAX_PERFORMANCE_FEE) revert OverMaxFee();

		performanceFee = _performanceFee;
		emit SetPerformanceFee(performanceFee);
	}

	/// @notice Sets a new performanceFee.
	/// @param _managementFee The new performance fee.
	function setManagementFee(uint256 _managementFee) public onlyOwner {
		if (_managementFee > MAX_MANAGEMENT_FEE) revert OverMaxFee();

		managementFee = _managementFee;
		emit SetManagementFee(_managementFee);
	}

	/// @notice Updates treasury.
	/// @param _treasury New treasury address.
	function setTreasury(address _treasury) public onlyOwner {
		treasury = _treasury;
		emit SetTreasury(_treasury);
	}

	/// @notice Emitted when performance fee is updated.
	/// @param performanceFee The new perforamance fee.
	event SetPerformanceFee(uint256 performanceFee);

	/// @notice Emitted when management fee is updated.
	/// @param managementFee The new management fee.
	event SetManagementFee(uint256 managementFee);

	event SetTreasury(address indexed treasury);

	error OverMaxFee();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { SafeERC20Upgradeable as SafeERC20, IERC20Upgradeable as IERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import { AuthU } from "./AuthU.sol";
import { FeeConfig } from "./Fees.sol";

// import "hardhat/console.sol";

abstract contract FeesU is AuthU {
	uint256 public constant MAX_MANAGEMENT_FEE = .05e18; // 5%
	uint256 public constant MAX_PERFORMANCE_FEE = .25e18; // 25%

	/// @notice The percentage of profit recognized each harvest to reserve as fees.
	/// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
	uint256 public performanceFee;

	/// @notice Annual management fee.
	/// @dev A fixed point number where 1e18 represents 100% and 0 represents 0%.
	uint256 public managementFee;

	/// @notice address where all fees are sent to
	address public treasury;

	function __Fees_init(FeeConfig memory feeConfig) public onlyInitializing {
		treasury = feeConfig.treasury;
		performanceFee = feeConfig.performanceFee;
		managementFee = feeConfig.managementFee;
		emit SetTreasury(feeConfig.treasury);
		emit SetPerformanceFee(feeConfig.performanceFee);
		emit SetManagementFee(feeConfig.managementFee);
	}

	/// @notice Sets a new performanceFee.
	/// @param _performanceFee The new performance fee.
	function setPerformanceFee(uint256 _performanceFee) public onlyOwner {
		if (_performanceFee > MAX_PERFORMANCE_FEE) revert OverMaxFee();

		performanceFee = _performanceFee;
		emit SetPerformanceFee(performanceFee);
	}

	/// @notice Sets a new performanceFee.
	/// @param _managementFee The new performance fee.
	function setManagementFee(uint256 _managementFee) public onlyOwner {
		if (_managementFee > MAX_MANAGEMENT_FEE) revert OverMaxFee();

		managementFee = _managementFee;
		emit SetManagementFee(_managementFee);
	}

	/// @notice Updates treasury.
	/// @param _treasury New treasury address.
	function setTreasury(address _treasury) public onlyOwner {
		treasury = _treasury;
		emit SetTreasury(_treasury);
	}

	/// @notice Emitted when performance fee is updated.
	/// @param performanceFee The new perforamance fee.
	event SetPerformanceFee(uint256 performanceFee);

	/// @notice Emitted when management fee is updated.
	/// @param managementFee The new management fee.
	event SetManagementFee(uint256 managementFee);

	event SetTreasury(address indexed treasury);

	error OverMaxFee();

	uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { Auth } from "./Auth.sol";
import { EAction } from "../interfaces/Structs.sol";
import { SectorErrors } from "../interfaces/SectorErrors.sol";

// import "hardhat/console.sol";

abstract contract StratAuth is Auth, SectorErrors {
	address public vault;

	modifier onlyVault() {
		if (msg.sender != vault) revert OnlyVault();
		_;
	}

	event EmergencyAction(address indexed target, bytes data);

	/// @notice calls arbitrary function on target contract in case of emergency
	function emergencyAction(EAction[] calldata actions) public payable onlyOwner {
		uint256 l = actions.length;
		for (uint256 i; i < l; ++i) {
			address target = actions[i].target;
			bytes memory data = actions[i].data;
			(bool success, ) = target.call{ value: actions[i].value }(data);
			require(success, "emergencyAction failed");
			emit EmergencyAction(target, data);
		}
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

interface IERC4626Accounting {
	function totalAssets() external view returns (uint256);

	function convertToShares(uint256 assets) external view returns (uint256);

	function convertToAssets(uint256 shares) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { HarvestSwapParams } from "../../interfaces/Structs.sol";
import { SectorErrors } from "../../interfaces/SectorErrors.sol";

interface ISCYStrategy {
	function underlying() external view returns (IERC20);

	function deposit(uint256 amount) external returns (uint256);

	function redeem(address to, uint256 amount) external returns (uint256 amntOut);

	function closePosition(uint256 slippageParam) external returns (uint256);

	function getAndUpdateTvl() external returns (uint256);

	function getTvl() external view returns (uint256);

	function getMaxTvl() external view returns (uint256);

	function collateralToUnderlying() external view returns (uint256);

	function harvest(
		HarvestSwapParams[] calldata farm1Params,
		HarvestSwapParams[] calldata farm2Parms
	) external returns (uint256[] memory harvest1, uint256[] memory harvest2);

	function getWithdrawAmnt(uint256 lpTokens) external view returns (uint256);

	function getDepositAmnt(uint256 uAmnt) external view returns (uint256);

	function getLpBalance() external view returns (uint256);

	function getLpToken() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { HarvestSwapParams } from "../Structs.sol";
import { ISCYStrategy } from "./ISCYStrategy.sol";

struct SCYVaultConfig {
	string symbol;
	string name;
	address addr;
	uint16 strategyId; // this is strategy specific token if 1155
	bool acceptsNativeToken;
	address yieldToken;
	IERC20 underlying;
	uint128 maxTvl; // pack all params and balances
	uint128 balance; // strategy balance in underlying
	uint128 uBalance; // underlying balance
	uint128 yBalance; // yield token balance
}

interface ISCYVault {
	// scy deposit
	function deposit(
		address receiver,
		address tokenIn,
		uint256 amountTokenToPull,
		uint256 minSharesOut
	) external payable returns (uint256 amountSharesOut);

	function redeem(
		address receiver,
		uint256 amountSharesToPull,
		address tokenOut,
		uint256 minTokenOut
	) external returns (uint256 amountTokenOut);

	function getAndUpdateTvl() external returns (uint256 tvl);

	function getTvl() external view returns (uint256 tvl);

	function MIN_LIQUIDITY() external view returns (uint256);

	function underlying() external view returns (IERC20);

	function yieldToken() external view returns (address);

	function sendERC20ToStrategy() external view returns (bool);

	function strategy() external view returns (ISCYStrategy);

	function underlyingBalance(address) external view returns (uint256);

	function underlyingToShares(uint256 amnt) external view returns (uint256);

	function exchangeRateUnderlying() external view returns (uint256);

	function sharesToUnderlying(uint256 shares) external view returns (uint256);

	function getUpdatedUnderlyingBalance(address) external returns (uint256);

	function getFloatingAmount(address) external view returns (uint256);

	function getStrategyTvl() external view returns (uint256);

	function acceptsNativeToken() external view returns (bool);

	function underlyingDecimals() external view returns (uint8);

	function getMaxTvl() external view returns (uint256);

	function closePosition(uint256 minAmountOut, uint256 slippageParam) external;

	function initStrategy(address) external;

	function harvest(
		uint256 expectedTvl,
		uint256 maxDelta,
		HarvestSwapParams[] calldata swap1,
		HarvestSwapParams[] calldata swap2
	) external returns (uint256[] memory harvest1, uint256[] memory harvest2);

	function withdrawFromStrategy(uint256 shares, uint256 minAmountOut) external;

	function depositIntoStrategy(uint256 amount, uint256 minSharesOut) external;

	function uBalance() external view returns (uint256);

	function setMaxTvl(uint256) external;

	function getDepositAmnt(uint256 amount) external view returns (uint256);

	function getWithdrawAmnt(uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
/*
 * MIT License
 * ===========
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 */

pragma solidity 0.8.16;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ISCYVault } from "./ISCYVault.sol";

interface ISuperComposableYield is ISCYVault {
	/// @dev Emitted whenever the exchangeRate is updated
	event ExchangeRateUpdated(uint256 oldExchangeRate, uint256 newExchangeRate);

	/// @dev Emitted when any base tokens is deposited to mint shares
	event Deposit(
		address indexed caller,
		address indexed receiver,
		address indexed tokenIn,
		uint256 amountDeposited,
		uint256 amountScyOut
	);

	/// @dev Emitted when any shares are redeemed for base tokens
	event Redeem(
		address indexed caller,
		address indexed receiver,
		address indexed tokenOut,
		uint256 amountScyToRedeem,
		uint256 amountTokenOut
	);

	/// @dev check assetInfo for more information
	enum AssetType {
		TOKEN,
		LIQUIDITY
	}

	/**
	 * @notice mints an amount of shares by depositing a base token.
	 * @param receiver shares recipient address
	 * @param tokenIn address of the base tokens to mint shares
	 * @param amountTokenToPull amount of base tokens to be transferred from (`msg.sender`)
	 * @param minSharesOut reverts if amount of shares minted is lower than this
	 * @return amountSharesOut amount of shares minted
	 * @dev
	 *
	 * This contract receives base tokens using these two (possibly both) methods:
	 * - The tokens have been transferred directly to this contract prior to calling deposit().
	 * - Exactly `amountTokenToPull` are transferred to this contract using `transferFrom()` upon calling deposit().
	 *
	 * The amount of shares minted will be based on the combined amount of base tokens deposited
	 * using the given two methods.
	 *
	 * Emits a {Deposit} event
	 *
	 * Requirements:
	 * - (`baseTokenIn`) must be a valid base token.
	 * - There must be an ongoing approval from (`msg.sender`) for this contract with
	 * at least `amountTokenToPull` base tokens.
	 */
	function deposit(
		address receiver,
		address tokenIn,
		uint256 amountTokenToPull,
		uint256 minSharesOut
	) external payable returns (uint256 amountSharesOut);

	/**
	 * @notice redeems an amount of base tokens by burning some shares
	 * @param receiver recipient address
	 * @param amountSharesToPull amount of shares to be transferred from (`msg.sender`)
	 * @param tokenOut address of the base token to be redeemed
	 * @param minTokenOut reverts if amount of base token redeemed is lower than this
	 * @return amountTokenOut amount of base tokens redeemed
	 * @dev
	 *
	 * This contract receives shares using these two (possibly both) methods:
	 * - The shares have been transferred directly to this contract prior to calling redeem().
	 * - Exactly `amountSharesToPull` are transferred to this contract using `transferFrom()` upon calling redeem().
	 *
	 * The amount of base tokens redeemed based on the combined amount of shares deposited
	 * using the given two methods
	 *
	 * Emits a {Redeem} event
	 *
	 * Requirements:
	 * - (`tokenOut`) must be a valid base token.
	 * - There must be an ongoing approval from (`msg.sender`) for this contract with
	 * at least `amountSharesToPull` shares.
	 */
	function redeem(
		address receiver,
		uint256 amountSharesToPull,
		address tokenOut,
		uint256 minTokenOut
	) external returns (uint256 amountTokenOut);

	/**
	 * @notice returns the address of the underlying yield token
	 */
	function yieldToken() external view returns (address);

	/**
	 * @notice returns a list of all the base tokens that can be deposited to mint shares
	 */
	function getBaseTokens() external view returns (address[] memory res);

	/**
	 * @notice checks whether a token is a valid base token
	 * @notice returns a boolean indicating whether this is a valid token
	 */
	function isValidBaseToken(address token) external view returns (bool);

	/**
    * @notice This function contains information to interpret what the asset is
    * @notice decimals is the decimals to format asset balances
    * @notice if asset is an ERC20 token, assetType = 0, assetAddress is the address of the token
    * @notice if asset is liquidity of an AMM (like sqrt(k) in UniswapV2 forks), assetType = 1,
    assetAddress is the address of the LP token
    * @notice assetDecimals is the decimals of the asset
    */
	function assetInfo()
		external
		view
		returns (
			AssetType assetType,
			address assetAddress,
			uint8 assetDecimals
		);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

interface SectorErrors {
	error NotImplemented();
	error MaxTvlReached();
	error StrategyHasBalance();
	error MinLiquidity();
	error OnlyVault();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

enum CallType {
	ADD_LIQUIDITY_AND_MINT,
	BORROWB,
	REMOVE_LIQ_AND_REPAY
}

enum VaultType {
	Strategy,
	Aggregator
}

enum EpochType {
	None,
	Withdraw,
	Full
}

enum NativeToken {
	None,
	Underlying,
	Short
}

struct CalleeData {
	CallType callType;
	bytes data;
}
struct AddLiquidityAndMintCalldata {
	uint256 uAmnt;
	uint256 sAmnt;
}
struct BorrowBCalldata {
	uint256 borrowAmount;
	bytes data;
}
struct RemoveLiqAndRepayCalldata {
	uint256 removeLpAmnt;
	uint256 repayUnderlying;
	uint256 repayShort;
	uint256 borrowUnderlying;
	// uint256 amountAMin;
	// uint256 amountBMin;
}

struct HarvestSwapParams {
	address[] path; //path that the token takes
	uint256 min; // min price of in token * 1e18 (computed externally based on spot * slippage + fees)
	uint256 deadline;
	bytes pathData; // uniswap3 path data
}

struct IMXConfig {
	address vault;
	address underlying;
	address short;
	address uniPair;
	address poolToken;
	address farmToken;
	address farmRouter;
}

struct HLPConfig {
	string symbol;
	string name;
	address underlying;
	address short;
	address cTokenLend;
	address cTokenBorrow;
	address uniPair;
	address uniFarm;
	address farmToken;
	uint256 farmId;
	address farmRouter;
	address comptroller;
	address lendRewardRouter;
	address lendRewardToken;
	address vault;
	NativeToken nativeToken;
}

struct EAction {
	address target;
	uint256 value;
	bytes data;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

interface IMXRouter2 {
	function mint(
		address collateralToken,
		uint256 amount,
		address to,
		uint256 deadline
	) external returns (uint256 tokens);

	function borrow(
		address borrowable,
		uint256 amount,
		address to,
		uint256 deadline,
		bytes memory permitData
	) external;

	function borrowETH(
		address borrowable,
		uint256 amountETH,
		address to,
		uint256 deadline,
		bytes memory permitData
	) external;
}

interface IPoolToken {
	function totalBalance() external view returns (uint256);

	function mint(address minter) external returns (uint256 mintTokens);

	function underlying() external view returns (address);

	function exchangeRate() external view returns (uint256);

	function redeem(address redeemer) external returns (uint256 redeemAmount);
}

interface IBorrowable {
	function borrow(
		address borrower,
		address receiver,
		uint256 borrowAmount,
		bytes calldata data
	) external;

	function borrowApprove(address spender, uint256 value) external returns (bool);

	function accrueInterest() external;

	function borrowBalance(address borrower) external view returns (uint256);

	function underlying() external view returns (address);

	function exchangeRate() external returns (uint256);

	function exchangeRateLast() external view returns (uint256);

	function totalSupply() external view returns (uint256);

	function totalBorrows() external view returns (uint256);

	function totalBalance() external view returns (uint256);

	function borrowTracker() external view returns (address);
}

interface ICollateral {
	function safetyMarginSqrt() external view returns (uint256);

	function liquidationIncentive() external view returns (uint256);

	function underlying() external view returns (address);

	function borrowable0() external view returns (address);

	function borrowable1() external view returns (address);

	function accountLiquidity(address account)
		external
		view
		returns (uint256 liquidity, uint256 shortfall);

	function flashRedeem(
		address redeemer,
		uint256 redeemAmount,
		bytes calldata data
	) external;

	function mint(address minter) external returns (uint256 mintTokens);

	function exchangeRate() external view returns (uint256);

	function getPrices() external view returns (uint256 price0, uint256 price1);

	function balanceOf(address) external view returns (uint256);

	function getTwapPrice112x112() external view returns (uint224 twapPrice112x112);

	function simpleUniswapOracle() external view returns (address);

	function tarotPriceOracle() external view returns (address);
}

interface ImpermaxChef {
	function pendingReward(address borrowable, address _user) external view returns (uint256);

	function harvest(address borrowable, address to) external;

	function massHarvest(address[] calldata borrowables, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ISimpleUniswapOracle {
	event PriceUpdate(
		address indexed pair,
		uint256 priceCumulative,
		uint32 blockTimestamp,
		bool lastIsA
	);

	function MIN_T() external pure returns (uint32);

	function getBlockTimestamp() external view returns (uint32);

	function getPair(address uniswapV2Pair)
		external
		view
		returns (
			uint256 priceCumulativeA,
			uint256 priceCumulativeB,
			uint32 updateA,
			uint32 updateB,
			bool lastIsA,
			bool initialized
		);

	function initialize(address uniswapV2Pair) external;

	function getResult(address uniswapV2Pair) external returns (uint224 price, uint32 T);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IUniswapV2Factory {
	event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

	function feeTo() external view returns (address);

	function feeToSetter() external view returns (address);

	function getPair(address tokenA, address tokenB) external view returns (address pair);

	function allPairs(uint256) external view returns (address pair);

	function allPairsLength() external view returns (uint256);

	function createPair(address tokenA, address tokenB) external returns (address pair);

	function setFeeTo(address) external;

	function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IUniswapV2Pair {
	event Approval(address indexed owner, address indexed spender, uint256 value);
	event Transfer(address indexed from, address indexed to, uint256 value);

	function name() external pure returns (string memory);

	function symbol() external pure returns (string memory);

	function decimals() external pure returns (uint8);

	function totalSupply() external view returns (uint256);

	function balanceOf(address owner) external view returns (uint256);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 value) external returns (bool);

	function transfer(address to, uint256 value) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 value
	) external returns (bool);

	function DOMAIN_SEPARATOR() external view returns (bytes32);

	function PERMIT_TYPEHASH() external pure returns (bytes32);

	function nonces(address owner) external view returns (uint256);

	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	event Mint(address indexed sender, uint256 amount0, uint256 amount1);
	event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
	event Swap(
		address indexed sender,
		uint256 amount0In,
		uint256 amount1In,
		uint256 amount0Out,
		uint256 amount1Out,
		address indexed to
	);
	event Sync(uint112 reserve0, uint112 reserve1);

	function MINIMUM_LIQUIDITY() external pure returns (uint256);

	function factory() external view returns (address);

	function token0() external view returns (address);

	function token1() external view returns (address);

	function getReserves()
		external
		view
		returns (
			uint112 reserve0,
			uint112 reserve1,
			uint32 blockTimestampLast
		);

	function price0CumulativeLast() external view returns (uint256);

	function price1CumulativeLast() external view returns (uint256);

	function kLast() external view returns (uint256);

	function mint(address to) external returns (uint256 liquidity);

	function burn(address to) external returns (uint256 amount0, uint256 amount1);

	function swap(
		uint256 amount0Out,
		uint256 amount1Out,
		address to,
		bytes calldata data
	) external;

	function skim(address to) external;

	function sync() external;

	function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IUniswapV2Router01 {
	function factory() external pure returns (address);

	function WETH() external pure returns (address);

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint256 amountADesired,
		uint256 amountBDesired,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	)
		external
		returns (
			uint256 amountA,
			uint256 amountB,
			uint256 liquidity
		);

	function addLiquidityETH(
		address token,
		uint256 amountTokenDesired,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	)
		external
		payable
		returns (
			uint256 amountToken,
			uint256 amountETH,
			uint256 liquidity
		);

	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETH(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline
	) external returns (uint256 amountToken, uint256 amountETH);

	function removeLiquidityWithPermit(
		address tokenA,
		address tokenB,
		uint256 liquidity,
		uint256 amountAMin,
		uint256 amountBMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountA, uint256 amountB);

	function removeLiquidityETHWithPermit(
		address token,
		uint256 liquidity,
		uint256 amountTokenMin,
		uint256 amountETHMin,
		address to,
		uint256 deadline,
		bool approveMax,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external returns (uint256 amountToken, uint256 amountETH);

	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactETHForTokens(
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function swapTokensForExactETH(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapExactTokensForETH(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to,
		uint256 deadline
	) external returns (uint256[] memory amounts);

	function swapETHForExactTokens(
		uint256 amountOut,
		address[] calldata path,
		address to,
		uint256 deadline
	) external payable returns (uint256[] memory amounts);

	function quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) external pure returns (uint256 amountB);

	function getAmountOut(
		uint256 amountIn,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountOut);

	function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) external pure returns (uint256 amountIn);

	function getAmountsOut(uint256 amountIn, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);

	function getAmountsIn(uint256 amountOut, address[] calldata path)
		external
		view
		returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IWETH {
	function deposit() external payable;

	function transfer(address to, uint256 value) external returns (bool);

	function withdraw(uint256) external;

	function balanceOf(address) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
	/*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

	uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

	function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
		return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
	}

	function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
		return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
	}

	function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
		return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
	}

	function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
		return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
	}

	/*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

	function mulDivDown(
		uint256 x,
		uint256 y,
		uint256 denominator
	) internal pure returns (uint256 z) {
		assembly {
			// Store x * y in z for now.
			z := mul(x, y)

			// Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
			if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
				revert(0, 0)
			}

			// Divide z by the denominator.
			z := div(z, denominator)
		}
	}

	function mulDivUp(
		uint256 x,
		uint256 y,
		uint256 denominator
	) internal pure returns (uint256 z) {
		assembly {
			// Store x * y in z for now.
			z := mul(x, y)

			// Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
			if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
				revert(0, 0)
			}

			// First, divide z - 1 by the denominator and add 1.
			// We allow z - 1 to underflow if z is 0, because we multiply the
			// end result by 0 if z is zero, ensuring we return 0 if z is zero.
			z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
		}
	}

	function rpow(
		uint256 x,
		uint256 n,
		uint256 scalar
	) internal pure returns (uint256 z) {
		assembly {
			switch x
			case 0 {
				switch n
				case 0 {
					// 0 ** 0 = 1
					z := scalar
				}
				default {
					// 0 ** n = 0
					z := 0
				}
			}
			default {
				switch mod(n, 2)
				case 0 {
					// If n is even, store scalar in z for now.
					z := scalar
				}
				default {
					// If n is odd, store x in z for now.
					z := x
				}

				// Shifting right by 1 is like dividing by 2.
				let half := shr(1, scalar)

				for {
					// Shift n right by 1 before looping to halve it.
					n := shr(1, n)
				} n {
					// Shift n right by 1 each iteration to halve it.
					n := shr(1, n)
				} {
					// Revert immediately if x ** 2 would overflow.
					// Equivalent to iszero(eq(div(xx, x), x)) here.
					if shr(128, x) {
						revert(0, 0)
					}

					// Store x squared.
					let xx := mul(x, x)

					// Round to the nearest number.
					let xxRound := add(xx, half)

					// Revert if xx + half overflowed.
					if lt(xxRound, xx) {
						revert(0, 0)
					}

					// Set x to scaled xxRound.
					x := div(xxRound, scalar)

					// If n is even:
					if mod(n, 2) {
						// Compute z * x.
						let zx := mul(z, x)

						// If z * x overflowed:
						if iszero(eq(div(zx, x), z)) {
							// Revert if x is non-zero.
							if iszero(iszero(x)) {
								revert(0, 0)
							}
						}

						// Round to the nearest number.
						let zxRound := add(zx, half)

						// Revert if zx + half overflowed.
						if lt(zxRound, zx) {
							revert(0, 0)
						}

						// Return properly scaled zxRound.
						z := div(zxRound, scalar)
					}
				}
			}
		}
	}

	/*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

	function sqrt(uint256 x) internal pure returns (uint256 z) {
		assembly {
			// Start off with z at 1.
			z := 1

			// Used below to help find a nearby power of 2.
			let y := x

			// Find the lowest power of 2 that is at least sqrt(x).
			if iszero(lt(y, 0x100000000000000000000000000000000)) {
				y := shr(128, y) // Like dividing by 2 ** 128.
				z := shl(64, z) // Like multiplying by 2 ** 64.
			}
			if iszero(lt(y, 0x10000000000000000)) {
				y := shr(64, y) // Like dividing by 2 ** 64.
				z := shl(32, z) // Like multiplying by 2 ** 32.
			}
			if iszero(lt(y, 0x100000000)) {
				y := shr(32, y) // Like dividing by 2 ** 32.
				z := shl(16, z) // Like multiplying by 2 ** 16.
			}
			if iszero(lt(y, 0x10000)) {
				y := shr(16, y) // Like dividing by 2 ** 16.
				z := shl(8, z) // Like multiplying by 2 ** 8.
			}
			if iszero(lt(y, 0x100)) {
				y := shr(8, y) // Like dividing by 2 ** 8.
				z := shl(4, z) // Like multiplying by 2 ** 4.
			}
			if iszero(lt(y, 0x10)) {
				y := shr(4, y) // Like dividing by 2 ** 4.
				z := shl(2, z) // Like multiplying by 2 ** 2.
			}
			if iszero(lt(y, 0x8)) {
				// Equivalent to 2 ** z.
				z := shl(1, z)
			}

			// Shifting right by 1 is like dividing by 2.
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))
			z := shr(1, add(z, div(x, z)))

			// Compute a rounded down version of z.
			let zRoundDown := div(x, z)

			// If zRoundDown is smaller, use it.
			if lt(zRoundDown, z) {
				z := zRoundDown
			}
		}
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

library SafeETH {
	function safeTransferETH(address to, uint256 amount) internal {
		bool callStatus;

		assembly {
			// Transfer the ETH and store if it succeeded or not.
			callStatus := call(gas(), to, amount, 0, 0, 0, 0)
		}

		require(callStatus, "ETH_TRANSFER_FAILED");
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "../interfaces/uniswap/IUniswapV2Pair.sol";
import "../interfaces/uniswap/IUniswapV2Router01.sol";
import "../interfaces/uniswap/IUniswapV2Factory.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library UniUtils {
	using SafeERC20 for IERC20;

	function _getPairTokens(IUniswapV2Pair pair) internal view returns (address, address) {
		return (pair.token0(), pair.token1());
	}

	function _getPairReserves(
		IUniswapV2Pair pair,
		address tokenA,
		address tokenB
	) internal view returns (uint256 reserveA, uint256 reserveB) {
		(address token0, ) = _sortTokens(tokenA, tokenB);
		(uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
		(reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
	}

	// given some amount of an asset and lp reserves, returns an equivalent amount of the other asset
	function _quote(
		uint256 amountA,
		uint256 reserveA,
		uint256 reserveB
	) internal pure returns (uint256 amountB) {
		require(amountA > 0, "UniUtils: INSUFFICIENT_AMOUNT");
		require(reserveA > 0 && reserveB > 0, "UniUtils: INSUFFICIENT_LIQUIDITY");
		amountB = (amountA * reserveB) / reserveA;
	}

	function _sortTokens(address tokenA, address tokenB)
		internal
		pure
		returns (address token0, address token1)
	{
		require(tokenA != tokenB, "UniUtils: IDENTICAL_ADDRESSES");
		(token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
		require(token0 != address(0), "UniUtils: ZERO_ADDRESS");
	}

	function _getAmountOut(
		IUniswapV2Pair pair,
		uint256 amountIn,
		address inToken,
		address outToken
	) internal view returns (uint256 amountOut) {
		require(amountIn > 0, "UniUtils: INSUFFICIENT_INPUT_AMOUNT");
		(uint256 reserveIn, uint256 reserveOut) = _getPairReserves(pair, inToken, outToken);
		uint256 amountInWithFee = amountIn * 997;
		uint256 numerator = amountInWithFee * reserveOut;
		uint256 denominator = reserveIn * 1000 + amountInWithFee;
		amountOut = numerator / denominator;
	}

	function _getAmountIn(
		IUniswapV2Pair pair,
		uint256 amountOut,
		address inToken,
		address outToken
	) internal view returns (uint256 amountIn) {
		require(amountOut > 0, "UniUtils: INSUFFICIENT_OUTPUT_AMOUNT");
		(uint256 reserveIn, uint256 reserveOut) = _getPairReserves(pair, inToken, outToken);
		uint256 numerator = reserveIn * amountOut * 1000;
		uint256 denominator = (reserveOut - amountOut) * 997;
		amountIn = (numerator / denominator) + 1;
	}

	function _swapExactTokensForTokens(
		IUniswapV2Pair pair,
		uint256 amountIn,
		address inToken,
		address outToken
	) internal returns (uint256) {
		uint256 amountOut = _getAmountOut(pair, amountIn, inToken, outToken);
		if (amountOut == 0) return 0;
		_swap(pair, amountIn, amountOut, inToken, outToken);
		return amountOut;
	}

	function _swapTokensForExactTokens(
		IUniswapV2Pair pair,
		uint256 amountOut,
		address inToken,
		address outToken
	) internal returns (uint256) {
		uint256 amountIn = _getAmountIn(pair, amountOut, inToken, outToken);
		_swap(pair, amountIn, amountOut, inToken, outToken);
		return amountIn;
	}

	function _swap(
		IUniswapV2Pair pair,
		uint256 amountIn,
		uint256 amountOut,
		address inToken,
		address outToken
	) internal {
		(address token0, ) = _sortTokens(outToken, inToken);
		(uint256 amount0Out, uint256 amount1Out) = inToken == token0
			? (uint256(0), amountOut)
			: (amountOut, uint256(0));
		IERC20(inToken).safeTransfer(address(pair), amountIn);
		pair.swap(amount0Out, amount1Out, address(this), new bytes(0));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IMXCore, IBase, IERC20 } from "./IMXCore.sol";
import { IMXFarm } from "./IMXFarm.sol";
import { IMXConfig } from "../../interfaces/Structs.sol";
import { Auth, AuthConfig } from "../../common/Auth.sol";

// import "hardhat/console.sol";

contract IMX is IMXCore, IMXFarm {
	constructor(AuthConfig memory authConfig, IMXConfig memory config)
		Auth(authConfig)
		IMXFarm(
			config.underlying,
			config.uniPair,
			config.poolToken,
			config.farmRouter,
			config.farmToken
		)
		IMXCore(config.vault, config.underlying, config.short)
	{
		isInitialized = true;
	}

	function tarotBorrow(
		address a,
		address b,
		uint256 c,
		bytes calldata data
	) external {
		impermaxBorrow(a, b, c, data);
	}

	function tarotRedeem(
		address a,
		uint256 redeemAmount,
		bytes calldata data
	) external {
		impermaxRedeem(a, redeemAmount, data);
	}

	function underlying() public view override(IBase, IMXCore) returns (IERC20) {
		return super.underlying();
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { IBase, HarvestSwapParams } from "../mixins/IBase.sol";
import { IIMXFarm } from "../mixins/IIMXFarm.sol";
import { UniUtils, IUniswapV2Pair } from "../../libraries/UniUtils.sol";
import { FixedPointMathLib } from "../../libraries/FixedPointMathLib.sol";
import { ISimpleUniswapOracle } from "../../interfaces/uniswap/ISimpleUniswapOracle.sol";

import { StratAuth } from "../../common/StratAuth.sol";
import { ISCYStrategy } from "../../interfaces/ERC5115/ISCYStrategy.sol";

// import "hardhat/console.sol";

abstract contract IMXCore is ReentrancyGuard, StratAuth, IBase, IIMXFarm, ISCYStrategy {
	using FixedPointMathLib for uint256;
	using UniUtils for IUniswapV2Pair;
	using SafeERC20 for IERC20;

	event Deposit(address sender, uint256 amount);
	event Redeem(address sender, uint256 amount);

	// event RebalanceLoan(address indexed sender, uint256 startLoanHealth, uint256 updatedLoanHealth);
	event SetRebalanceThreshold(uint256 rebalanceThreshold);
	// this determines our default leverage position
	event SetSafetyMarginSqrt(uint256 safetyMarginSqrt);

	event Harvest(uint256 harvested); // this is actual the tvl before harvest
	event Rebalance(uint256 shortPrice, uint256 tvlBeforeRebalance, uint256 positionOffset);
	event SetMaxPriceOffset(uint256 maxPriceOffset);

	uint256 constant MINIMUM_LIQUIDITY = 1000;
	uint256 constant BPS_ADJUST = 10000;

	IERC20 private _underlying;
	IERC20 private _short;

	uint16 public rebalanceThreshold = 400; // 4% of lp
	// price move before liquidation
	uint256 private _safetyMarginSqrt = 1.140175425e18; // sqrt of 130%
	uint256 public maxPriceOffset = .2e18;

	modifier checkPrice(uint256 expectedPrice, uint256 maxDelta) {
		// parameter validation
		// to prevent manipulation by manager
		if (!hasRole(GUARDIAN, msg.sender)) {
			uint256 oraclePrice = shortToUnderlyingOracleUpdate(1e18);
			uint256 oracleDelta = oraclePrice > expectedPrice
				? oraclePrice - expectedPrice
				: expectedPrice - oraclePrice;
			if ((1e18 * (oracleDelta + maxDelta)) / expectedPrice > maxPriceOffset)
				revert OverMaxPriceOffset();
		}

		uint256 currentPrice = _shortToUnderlying(1e18);
		uint256 delta = expectedPrice > currentPrice
			? expectedPrice - currentPrice
			: currentPrice - expectedPrice;
		if (delta > maxDelta) revert SlippageExceeded();
		_;
	}

	constructor(
		address vault_,
		address underlying_,
		address short_
	) {
		vault = vault_;
		_underlying = IERC20(underlying_);
		_short = IERC20(short_);

		// _underlying.safeApprove(vault, type(uint256).max);

		// init default params
		// deployer is not owner so we set these manually

		// TODO param?
		rebalanceThreshold = 400;
		emit SetRebalanceThreshold(400);

		maxPriceOffset = .2e18;
		emit SetMaxPriceOffset(maxPriceOffset);

		_safetyMarginSqrt = 1.140175425e18;
		emit SetSafetyMarginSqrt(_safetyMarginSqrt);
	}

	// guardian can adjust max price offset if needed
	function setMaxPriceOffset(uint256 _maxPriceOffset) public onlyRole(GUARDIAN) {
		maxPriceOffset = _maxPriceOffset;
		emit SetMaxPriceOffset(_maxPriceOffset);
	}

	function safetyMarginSqrt() public view override returns (uint256) {
		return _safetyMarginSqrt;
	}

	function decimals() public view returns (uint8) {
		return IERC20Metadata(address(_underlying)).decimals();
	}

	// OWNER CONFIG

	function setRebalanceThreshold(uint16 rebalanceThreshold_) public onlyOwner {
		require(rebalanceThreshold_ >= 100, "STRAT: BAD_INPUT");
		rebalanceThreshold = rebalanceThreshold_;
		emit SetRebalanceThreshold(rebalanceThreshold_);
	}

	function setSafetyMarginSqrt(uint256 safetyMarginSqrt_) public onlyOwner {
		_safetyMarginSqrt = safetyMarginSqrt_;
		emit SetSafetyMarginSqrt(_safetyMarginSqrt);
	}

	// PUBLIC METHODS

	function short() public view override returns (IERC20) {
		return _short;
	}

	function underlying() public view virtual override(IBase, ISCYStrategy) returns (IERC20) {
		return _underlying;
	}

	// deposit underlying and recieve lp tokens
	function deposit(uint256 underlyingAmnt) external onlyVault nonReentrant returns (uint256) {
		if (underlyingAmnt == 0) return 0; // cannot deposit 0
		uint256 startBalance = collateralToken().balanceOf(address(this));
		_increasePosition(underlyingAmnt);
		uint256 endBalance = collateralToken().balanceOf(address(this));
		return endBalance - startBalance;
	}

	// redeem lp for underlying
	function redeem(address recipient, uint256 removeCollateral)
		public
		onlyVault
		returns (uint256 amountTokenOut)
	{
		if (removeCollateral < MINIMUM_LIQUIDITY) return 0; // cannot redeem 0
		// this is the full amount of LP tokens totalSupply of shares is entitled to
		_decreasePosition(removeCollateral);

		// make sure we never have any extra underlying dust sitting around
		// all 'extra' underlying should allways be transferred back to the vault

		unchecked {
			amountTokenOut = _underlying.balanceOf(address(this));
		}
		_underlying.safeTransfer(recipient, amountTokenOut);
		emit Redeem(msg.sender, amountTokenOut);
	}

	/// @notice decreases position based to desired LP amount
	/// @dev ** does not rebalance remaining portfolio
	/// @param removeCollateral amount of callateral token to remove
	function _decreasePosition(uint256 removeCollateral) internal {
		(uint256 uBorrowBalance, uint256 sBorrowBalance) = _updateAndGetBorrowBalances();

		uint256 balance = collateralToken().balanceOf(address(this));
		uint256 lp = _getLiquidity(balance);

		// remove lp & repay underlying loan
		// round up to avoid under-repaying
		uint256 removeLp = lp.mulDivUp(removeCollateral, balance);
		uint256 uRepay = uBorrowBalance.mulDivUp(removeCollateral, balance);
		uint256 sRepay = sBorrowBalance.mulDivUp(removeCollateral, balance);

		_removeIMXLiquidity(removeLp, uRepay, sRepay, 0);
	}

	// increases the position based on current desired balance
	// ** does not rebalance remaining portfolio
	function _increasePosition(uint256 amntUnderlying) internal {
		if (amntUnderlying < MINIMUM_LIQUIDITY) return; // avoid imprecision
		(uint256 uLp, uint256 sLp) = _getLPBalances();
		(uint256 uBorrowBalance, uint256 sBorrowBalance) = _getBorrowBalances();

		uint256 tvl = getAndUpdateTvl() - amntUnderlying;

		uint256 uBorrow;
		uint256 sBorrow;
		uint256 uAddLp;
		uint256 sAddLp;

		// on initial deposit or if amount are below threshold for accurate accounting
		if (
			tvl < MINIMUM_LIQUIDITY ||
			uLp < MINIMUM_LIQUIDITY ||
			sLp < MINIMUM_LIQUIDITY ||
			uBorrowBalance < MINIMUM_LIQUIDITY ||
			sBorrowBalance < MINIMUM_LIQUIDITY
		) {
			uBorrow = (_optimalUBorrow() * amntUnderlying) / 1e18;
			uAddLp = amntUnderlying + uBorrow;
			sBorrow = _underlyingToShort(uAddLp);
			sAddLp = sBorrow;
		} else {
			// if tvl > 0 we need to keep the exact proportions of current position
			// to ensure we have correct accounting independent of price moves
			uBorrow = (uBorrowBalance * amntUnderlying) / tvl;
			uAddLp = (uLp * amntUnderlying) / tvl;
			sBorrow = (sBorrowBalance * amntUnderlying) / tvl;
			sAddLp = _underlyingToShort(uAddLp);
		}

		_addIMXLiquidity(uAddLp, sAddLp, uBorrow, sBorrow);
	}

	// use the return of the function to estimate pending harvest via staticCall
	function harvest(HarvestSwapParams[] calldata harvestParams, HarvestSwapParams[] calldata)
		external
		onlyVault
		nonReentrant
		returns (uint256[] memory farmHarvest, uint256[] memory)
	{
		(uint256 startTvl, , , , , ) = getTVL();

		farmHarvest = new uint256[](1);
		// return amount of underlying tokens harvested
		(, farmHarvest[0]) = _harvestFarm(harvestParams[0]);

		// compound our lp position
		_increasePosition(_underlying.balanceOf(address(this)));
		emit Harvest(startTvl);
		return (farmHarvest, new uint256[](0));
	}

	function rebalance(uint256 expectedPrice, uint256 maxDelta)
		external
		onlyRole(MANAGER)
		checkPrice(expectedPrice, maxDelta)
		nonReentrant
	{
		// call this first to ensure we use an updated borrowBalance when computing offset
		uint256 tvl = getAndUpdateTvl();
		uint256 positionOffset = getPositionOffset();

		// don't rebalance unless we exceeded the threshold
		// GUARDIAN can execute rebalance any time
		if (positionOffset <= rebalanceThreshold && !hasRole(GUARDIAN, msg.sender))
			revert RebalanceThreshold();

		if (tvl == 0) return;
		uint256 targetUBorrow = (tvl * _optimalUBorrow()) / 1e18;
		uint256 targetUnderlyingLP = tvl + targetUBorrow;

		(uint256 underlyingLp, ) = _getLPBalances();
		uint256 targetShortLp = _underlyingToShort(targetUnderlyingLP);
		(uint256 uBorrowBalance, uint256 sBorrowBalance) = _updateAndGetBorrowBalances();

		// TODO account for uBalance?
		// uint256 uBalance = underlying().balanceOf(address(this));

		if (underlyingLp > targetUnderlyingLP) {
			uint256 uRepay;
			uint256 uBorrow;
			if (uBorrowBalance > targetUBorrow) uRepay = uBorrowBalance - targetUBorrow;
			else uBorrow = targetUBorrow - uBorrowBalance;

			uint256 sRepay = sBorrowBalance > targetShortLp ? sBorrowBalance - targetShortLp : 0;

			uint256 lp = _getLiquidity();
			uint256 removeLp = lp - (lp * targetUnderlyingLP) / underlyingLp;
			_removeIMXLiquidity(removeLp, uRepay, sRepay, uBorrow);
		} else if (targetUnderlyingLP > underlyingLp) {
			uint256 uBorrow = targetUBorrow > uBorrowBalance ? targetUBorrow - uBorrowBalance : 0;
			uint256 sBorrow = targetShortLp > sBorrowBalance ? targetShortLp - sBorrowBalance : 0;

			uint256 uAdd = targetUnderlyingLP - underlyingLp;

			// extra underlying balance will get re-paid automatically
			_addIMXLiquidity(
				uAdd,
				_underlyingToShort(uAdd), // this is more precise than targetShortLp - shortLP because of rounding
				uBorrow,
				sBorrow
			);
		}
		emit Rebalance(_shortToUnderlying(1e18), positionOffset, tvl);
	}

	// vault handles slippage
	function closePosition(uint256) public onlyVault returns (uint256 balance) {
		(uint256 uRepay, uint256 sRepay) = _updateAndGetBorrowBalances();
		uint256 removeLp = _getLiquidity();
		_removeIMXLiquidity(removeLp, uRepay, sRepay, 0);
		// transfer funds to vault
		balance = _underlying.balanceOf(address(this));
		_underlying.safeTransfer(vault, balance);
	}

	// TVL
	function getMaxTvl() public view returns (uint256) {
		(uint256 uBorrow, uint256 sBorrow) = _getBorrowBalances();
		uint256 sMax = sBorrowable().totalBalance();
		uint256 optimalBorrow = _optimalUBorrow();
		return
			// adjust the availableToBorrow to account for leverage
			min(
				((uBorrow + uBorrowable().totalBalance()) * 1e18) / optimalBorrow,
				_shortToUnderlying((sBorrow + sMax) * 1e18) / (optimalBorrow + 1e18)
			);
	}

	// TODO should we compute pending farm & lending rewards here?
	function getAndUpdateTvl() public returns (uint256 tvl) {
		(uint256 uBorrow, uint256 shortPosition) = _updateAndGetBorrowBalances();
		uint256 borrowBalance = _shortToUnderlying(shortPosition) + uBorrow;
		uint256 shortP = _short.balanceOf(address(this));
		uint256 shortBalance = shortP == 0
			? 0
			: _shortToUnderlying(_short.balanceOf(address(this)));
		(uint256 underlyingLp, ) = _getLPBalances();
		uint256 underlyingBalance = _underlying.balanceOf(address(this));
		uint256 assets = underlyingLp * 2 + underlyingBalance + shortBalance;
		tvl = assets > borrowBalance ? assets - borrowBalance : 0;
	}

	function getTotalTVL() public view returns (uint256 tvl) {
		(tvl, , , , , ) = getTVL();
	}

	function getTvl() public view returns (uint256 tvl) {
		(tvl, , , , , ) = getTVL();
	}

	function getTVL()
		public
		view
		returns (
			uint256 tvl,
			uint256,
			uint256 borrowPosition,
			uint256 borrowBalance,
			uint256 lpBalance,
			uint256 underlyingBalance
		)
	{
		uint256 underlyingBorrow;
		(underlyingBorrow, borrowPosition) = _getBorrowBalances();
		borrowBalance = _shortToUnderlying(borrowPosition) + underlyingBorrow;

		uint256 shortPosition = _short.balanceOf(address(this));
		uint256 shortBalance = shortPosition == 0 ? 0 : _shortToUnderlying(shortPosition);

		(uint256 underlyingLp, uint256 shortLp) = _getLPBalances();
		lpBalance = underlyingLp + _shortToUnderlying(shortLp);
		underlyingBalance = _underlying.balanceOf(address(this));
		uint256 assets = lpBalance + underlyingBalance + shortBalance;
		tvl = assets > borrowBalance ? assets - borrowBalance : 0;
	}

	function getPositionOffset() public view returns (uint256 positionOffset) {
		(, uint256 shortLp) = _getLPBalances();
		(, uint256 borrowBalance) = _getBorrowBalances();
		uint256 shortBalance = shortLp + _short.balanceOf(address(this));
		if (shortBalance == borrowBalance) return 0;
		// if short lp > 0 and borrowBalance is 0 we are off by inf, returning 100% should be enough
		if (borrowBalance == 0) return 10000;
		// this is the % by which our position has moved from beeing balanced

		positionOffset = shortBalance > borrowBalance
			? ((shortBalance - borrowBalance) * BPS_ADJUST) / borrowBalance
			: ((borrowBalance - shortBalance) * BPS_ADJUST) / borrowBalance;
	}

	// UTILS
	function getExpectedPrice() external view returns (uint256) {
		return _shortToUnderlying(1e18);
	}

	function getLPBalances() public view returns (uint256 underlyingLp, uint256 shortLp) {
		return _getLPBalances();
	}

	function getLiquidity() external view returns (uint256) {
		return _getLiquidity();
	}

	// used to estimate price of collateral token in underlying
	function collateralToUnderlying() public view returns (uint256) {
		(uint256 uR, uint256 sR, ) = pair().getReserves();
		(uR, sR) = address(_underlying) == pair().token0() ? (uR, sR) : (sR, uR);
		uint256 lp = pair().totalSupply();
		// for deposit of 1 underlying we get 1+_optimalUBorrow worth of lp -> collateral token
		return (1e18 * (uR * _getLiquidity(1e18))) / lp / (1e18 + _optimalUBorrow());
	}

	// in some cases the oracle needs to be updated externally
	// to be accessible by read methods like loanHealth();
	function updateOracle() public {
		try collateralToken().tarotPriceOracle() returns (address _oracle) {
			ISimpleUniswapOracle oracle = ISimpleUniswapOracle(_oracle);
			oracle.getResult(collateralToken().underlying());
		} catch {
			ISimpleUniswapOracle oracle = ISimpleUniswapOracle(
				collateralToken().simpleUniswapOracle()
			);
			oracle.getResult(collateralToken().underlying());
		}
	}

	function getLpToken() public view returns (address) {
		return address(collateralToken());
	}

	function getLpBalance() external view returns (uint256) {
		return collateralToken().balanceOf(address(this));
	}

	function getWithdrawAmnt(uint256 lpTokens) public view returns (uint256) {
		return (lpTokens * collateralToUnderlying()) / 1e18;
	}

	function getDepositAmnt(uint256 uAmnt) public view returns (uint256) {
		return (uAmnt * 1e18) / collateralToUnderlying();
	}

	/// @dev we can call this method via staticall to get the loan health
	/// even when oracle has not been updated
	function callLoanHealth() external returns (uint256) {
		updateOracle();
		return loanHealth();
	}

	/**
	 * @dev Returns the smallest of two numbers.
	 */
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	error RebalanceThreshold();
	error LowLoanHealth();
	error SlippageExceeded();
	error OverMaxPriceOffset();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { ICollateral, IPoolToken, IBorrowable, ImpermaxChef } from "../../interfaces/imx/IImpermax.sol";
import { HarvestSwapParams, IIMXFarm, IERC20, SafeERC20, IUniswapV2Pair, IUniswapV2Router01 } from "../mixins/IIMXFarm.sol";
import { UniUtils } from "../../libraries/UniUtils.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { CallType, CalleeData, AddLiquidityAndMintCalldata, BorrowBCalldata, RemoveLiqAndRepayCalldata } from "../../interfaces/Structs.sol";

// import "hardhat/console.sol";

abstract contract IMXFarm is IIMXFarm {
	using SafeERC20 for IERC20;
	using UniUtils for IUniswapV2Pair;
	// using FixedPointMathLib for uint256;

	IUniswapV2Pair public _pair;
	ICollateral private _collateralToken;
	IBorrowable private _uBorrowable;
	IBorrowable private _sBorrowable;
	IPoolToken private stakedToken;
	ImpermaxChef private _impermaxChef;

	IERC20 private _farmToken;
	IUniswapV2Router01 private _farmRouter;

	bool public flip;

	constructor(
		address underlying_,
		address pair_,
		address collateralToken_,
		address farmRouter_,
		address farmToken_
	) {
		_pair = IUniswapV2Pair(pair_);
		_collateralToken = ICollateral(collateralToken_);
		_uBorrowable = IBorrowable(_collateralToken.borrowable0());
		_sBorrowable = IBorrowable(_collateralToken.borrowable1());

		if (underlying_ != _uBorrowable.underlying()) {
			flip = true;
			(_uBorrowable, _sBorrowable) = (_sBorrowable, _uBorrowable);
		}
		stakedToken = IPoolToken(_collateralToken.underlying());
		_impermaxChef = ImpermaxChef(_uBorrowable.borrowTracker());
		_farmToken = IERC20(farmToken_);
		_farmRouter = IUniswapV2Router01(farmRouter_);

		// necessary farm approvals
		_farmToken.safeApprove(address(farmRouter_), type(uint256).max);
	}

	function impermaxChef() public view override returns (ImpermaxChef) {
		return _impermaxChef;
	}

	function collateralToken() public view override returns (ICollateral) {
		return _collateralToken;
	}

	function sBorrowable() public view override returns (IBorrowable) {
		return _sBorrowable;
	}

	function uBorrowable() public view override returns (IBorrowable) {
		return _uBorrowable;
	}

	function farmRouter() public view override returns (IUniswapV2Router01) {
		return _farmRouter;
	}

	function pair() public view override returns (IUniswapV2Pair) {
		return _pair;
	}

	function _addIMXLiquidity(
		uint256 underlyingAmnt,
		uint256 shortAmnt,
		uint256 uBorrow,
		uint256 sBorrow
	) internal virtual override {
		_sBorrowable.borrowApprove(address(_sBorrowable), sBorrow);

		// mint collateral
		bytes memory addLPData = abi.encode(
			CalleeData({
				callType: CallType.ADD_LIQUIDITY_AND_MINT,
				data: abi.encode(
					AddLiquidityAndMintCalldata({ uAmnt: underlyingAmnt, sAmnt: shortAmnt })
				)
			})
		);

		// borrow short data
		bytes memory borrowSData = abi.encode(
			CalleeData({
				callType: CallType.BORROWB,
				data: abi.encode(BorrowBCalldata({ borrowAmount: uBorrow, data: addLPData }))
			})
		);

		// flashloan borrow then add lp
		_sBorrowable.borrow(address(this), address(this), sBorrow, borrowSData);
	}

	function impermaxBorrow(
		address,
		address,
		uint256,
		bytes calldata data
	) public {
		// ensure that msg.sender is correct
		require(
			msg.sender == address(_sBorrowable) || msg.sender == address(_uBorrowable),
			"IMXFarm: NOT_BORROWABLE"
		);
		CalleeData memory calleeData = abi.decode(data, (CalleeData));

		if (calleeData.callType == CallType.ADD_LIQUIDITY_AND_MINT) {
			AddLiquidityAndMintCalldata memory d = abi.decode(
				calleeData.data,
				(AddLiquidityAndMintCalldata)
			);
			_addLp(d.uAmnt, d.sAmnt);
		} else if (calleeData.callType == CallType.BORROWB) {
			BorrowBCalldata memory d = abi.decode(calleeData.data, (BorrowBCalldata));
			_uBorrowable.borrow(address(this), address(this), d.borrowAmount, d.data);
		}
	}

	function _addLp(uint256 uAmnt, uint256 sAmnt) internal {
		{
			uint256 sBalance = short().balanceOf(address(this));
			uint256 uBalance = underlying().balanceOf(address(this));

			// TODO use swap fee to get exact amount out
			// if we have extra short tokens, trade them for underlying
			if (sBalance > sAmnt) {
				uBalance += pair()._swapExactTokensForTokens(
					sBalance - sAmnt,
					address(short()),
					address(underlying())
				);
				// sBalance = sAmnt now
			} else if (sAmnt > sBalance) {
				// when rebalancing we will never have more sAmnt than sBalance
				uBalance -= pair()._swapTokensForExactTokens(
					sAmnt - sBalance,
					address(underlying()),
					address(short())
				);
			}

			// we know that now our short balance is now exact sBalance = sAmnt
			// if we don't have enough underlying, we need to decrase sAmnt slighlty
			if (uBalance < uAmnt) {
				uAmnt = uBalance;
				uint256 sAmntNew = _underlyingToShort(uAmnt);
				// make sure we're not increaseing the amount
				if (sAmnt > sAmntNew) sAmnt = sAmntNew;
				else uAmnt = _shortToUnderlying(sAmnt);
			}
			if (uBalance > uAmnt) {
				// if we have extra underlying return to borrowable
				// TODO check that this gets accounted for
				underlying().safeTransfer(address(_uBorrowable), uBalance - uAmnt);
			}
		}

		underlying().safeTransfer(address(_pair), uAmnt);
		short().safeTransfer(address(_pair), sAmnt);

		uint256 liquidity = _pair.mint(address(this));

		// first we create staked token, then collateral token
		IERC20(address(_pair)).safeTransfer(address(stakedToken), liquidity);
		stakedToken.mint(address(_collateralToken));
		_collateralToken.mint(address(this));
	}

	function _removeIMXLiquidity(
		uint256 removeLpAmnt,
		uint256 repayUnderlying,
		uint256 repayShort,
		uint256 borrowUnderlying
	) internal override {
		uint256 redeemAmount = (removeLpAmnt * 1e18) / stakedToken.exchangeRate() + 1;

		bytes memory data = abi.encode(
			RemoveLiqAndRepayCalldata({
				removeLpAmnt: removeLpAmnt,
				repayUnderlying: repayUnderlying,
				repayShort: repayShort,
				borrowUnderlying: borrowUnderlying
			})
		);

		_collateralToken.flashRedeem(address(this), redeemAmount, data);
	}

	function impermaxRedeem(
		address,
		uint256 redeemAmount,
		bytes calldata data
	) public {
		require(msg.sender == address(_collateralToken), "IMXFarm: NOT_COLLATERAL");

		RemoveLiqAndRepayCalldata memory d = abi.decode(data, (RemoveLiqAndRepayCalldata));

		// redeem withdrawn staked coins
		IERC20(address(stakedToken)).safeTransfer(address(stakedToken), redeemAmount);
		stakedToken.redeem(address(this));

		// remove collateral
		(, uint256 shortAmnt) = _removeLiquidity(d.removeLpAmnt);

		// in some cases we need to borrow extra underlying
		if (d.borrowUnderlying > 0)
			_uBorrowable.borrow(address(this), address(this), d.borrowUnderlying, "");

		// trade extra tokens

		// if we have extra short tokens, trade them for underlying
		if (shortAmnt > d.repayShort) {
			// TODO edge case - not enough underlying?
			pair()._swapExactTokensForTokens(
				shortAmnt - d.repayShort,
				address(short()),
				address(underlying())
			);
			shortAmnt = d.repayShort;
		}
		// if we know the exact amount of short we must repay, then ensure we have that amount
		else if (shortAmnt < d.repayShort && d.repayShort != type(uint256).max) {
			uint256 amountOut = d.repayShort - shortAmnt;
			uint256 amountIn = pair()._getAmountIn(
				amountOut,
				address(underlying()),
				address(short())
			);
			uint256 inTokenBalance = underlying().balanceOf(address(this));
			if (amountIn > inTokenBalance) {
				shortAmnt += pair()._swapExactTokensForTokens(
					inTokenBalance,
					address(underlying()),
					address(short())
				);
			} else {
				pair()._swap(amountIn, amountOut, address(underlying()), address(short()));
				shortAmnt = d.repayShort;
			}
		}

		uint256 uBalance = underlying().balanceOf(address(this));

		// repay short loan
		short().safeTransfer(address(_sBorrowable), shortAmnt);
		_sBorrowable.borrow(address(this), address(0), 0, new bytes(0));

		// repay underlying loan
		if (uBalance > 0) {
			underlying().safeTransfer(
				address(_uBorrowable),
				d.repayUnderlying > uBalance ? uBalance : d.repayUnderlying
			);
			_uBorrowable.borrow(address(this), address(0), 0, new bytes(0));
		}

		uint256 cAmount = (redeemAmount * 1e18) / _collateralToken.exchangeRate() + 1;

		// uint256 colBal = _collateralToken.balanceOf(address(this));
		// TODO add tests to make ensure cAmount < colBal

		// return collateral token
		IERC20(address(_collateralToken)).safeTransfer(
			address(_collateralToken),
			// colBal < cAmount ? colBal : cAmount
			cAmount
		);
	}

	function pendingHarvest() external view override returns (uint256 harvested) {
		if (address(_impermaxChef) == address(0)) return 0;
		harvested =
			_impermaxChef.pendingReward(address(_sBorrowable), address(this)) +
			_impermaxChef.pendingReward(address(_uBorrowable), address(this));
	}

	function harvestIsEnabled() public view returns (bool) {
		return address(_impermaxChef) != address(0);
	}

	function _harvestFarm(HarvestSwapParams calldata harvestParams)
		internal
		override
		returns (uint256 harvested, uint256 amountOut)
	{
		// rewards are not enabled
		if (address(_impermaxChef) == address(0)) return (harvested, amountOut);
		address[] memory borrowables = new address[](2);
		borrowables[0] = address(_sBorrowable);
		borrowables[1] = address(_uBorrowable);

		_impermaxChef.massHarvest(borrowables, address(this));

		harvested = _farmToken.balanceOf(address(this));
		if (harvested == 0) return (harvested, amountOut);

		uint256[] memory amounts = _swap(
			_farmRouter,
			harvestParams,
			address(_farmToken),
			harvested
		);
		amountOut = amounts[amounts.length - 1];
		emit HarvestedToken(address(_farmToken), harvested);
	}

	function _getLiquidity() internal view override returns (uint256) {
		return _getLiquidity(_collateralToken.balanceOf(address(this)));
	}

	function _getLiquidity(uint256 balance) internal view override returns (uint256) {
		if (balance == 0) return 0;
		return
			(stakedToken.exchangeRate() * (_collateralToken.exchangeRate() * (balance - 1))) /
			1e18 /
			1e18;
	}

	function _getBorrowBalances() internal view override returns (uint256, uint256) {
		return (
			_uBorrowable.borrowBalance(address(this)),
			_sBorrowable.borrowBalance(address(this))
		);
	}

	function accrueInterest() public override {
		_sBorrowable.accrueInterest();
		_uBorrowable.accrueInterest();
	}

	function _updateAndGetBorrowBalances() internal override returns (uint256, uint256) {
		accrueInterest();
		return _getBorrowBalances();
	}

	/// @notice borrow amount of underlying for every 1e18 of deposit
	/// @dev currently cannot go below ~2.02x lev
	function _optimalUBorrow() internal view override returns (uint256 uBorrow) {
		uint256 l = _collateralToken.liquidationIncentive();
		// this is the adjusted safety margin - how far we stay from liquidation
		uint256 s = (_collateralToken.safetyMarginSqrt() * safetyMarginSqrt()) / 1e18;
		uBorrow = (1e18 * (2e18 - (l * s) / 1e18)) / ((l * 1e18) / s + (l * s) / 1e18 - 2e18);
	}

	function loanHealth() public view override returns (uint256) {
		// this updates the oracle
		uint256 balance = IERC20(address(_collateralToken)).balanceOf(address(this));
		if (balance == 0) return 100e18;
		uint256 liq = (balance * _collateralToken.exchangeRate()) / 1e18;
		(uint256 available, uint256 shortfall) = _collateralToken.accountLiquidity(address(this));
		if (liq < shortfall) return 0; // we are way past liquidation
		return shortfall == 0 ? (1e18 * (liq + available)) / liq : (1e18 * (liq - shortfall)) / liq;
	}

	function shortToUnderlyingOracleUpdate(uint256 amount) public override returns (uint256) {
		(bool success, bytes memory data) = address(collateralToken()).call(
			abi.encodeWithSignature("getPrices()")
		);
		if (!success) revert OracleUpdate();
		(uint256 price0, uint256 price1) = abi.decode(data, (uint256, uint256));
		return flip ? (amount * price0) / price1 : (amount * price1) / price0;
	}

	function shortToUnderlyingOracle(uint256 amount) public view override returns (uint256) {
		try collateralToken().getPrices() returns (uint256 price0, uint256 price1) {
			return flip ? (amount * price0) / price1 : (amount * price1) / price0;
		} catch {
			revert OracleUpdate();
		}
	}

	error OracleUpdate();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { HarvestSwapParams } from "../../interfaces/Structs.sol";

// all interfaces need to inherit from base
abstract contract IBase {
	bool public isInitialized;

	modifier initializer() {
		require(isInitialized == false, "INITIALIZED");
		_;
	}

	function short() public view virtual returns (IERC20);

	function underlying() public view virtual returns (IERC20);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { IUniswapV2Router01 } from "../../interfaces/uniswap/IUniswapV2Router01.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { HarvestSwapParams, IBase } from "./IBase.sol";

abstract contract IFarmable is IBase {
	using SafeERC20 for IERC20;

	event HarvestedToken(address indexed token, uint256 amount);

	function _swap(
		IUniswapV2Router01 router,
		HarvestSwapParams calldata swapParams,
		address from,
		uint256 amount
	) internal returns (uint256[] memory) {
		address out = swapParams.path[swapParams.path.length - 1];
		// ensure malicious harvester is not trading with wrong tokens
		// TODO should we add more validation to prevent malicious path?
		require(
			((swapParams.path[0] == address(from) && (out == address(short()))) ||
				out == address(underlying())),
			"IFarmable: WRONG_PATH"
		);
		return
			router.swapExactTokensForTokens(
				amount,
				swapParams.min,
				swapParams.path, // optimal route determined externally
				address(this),
				swapParams.deadline
			);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import { IBorrowable, ICollateral, ImpermaxChef } from "../../interfaces/imx/IImpermax.sol";

import { IBase, HarvestSwapParams } from "./IBase.sol";
import { IUniLp, IUniswapV2Pair, SafeERC20, IERC20 } from "./IUniLp.sol";
import { IFarmable, IUniswapV2Router01 } from "./IFarmable.sol";

abstract contract IIMXFarm is IBase, IFarmable, IUniLp {
	function loanHealth() public view virtual returns (uint256);

	function sBorrowable() public view virtual returns (IBorrowable);

	function uBorrowable() public view virtual returns (IBorrowable);

	function collateralToken() public view virtual returns (ICollateral);

	function impermaxChef() public view virtual returns (ImpermaxChef);

	function pendingHarvest() external view virtual returns (uint256 harvested);

	function farmRouter() public view virtual returns (IUniswapV2Router01);

	function _getBorrowBalances()
		internal
		view
		virtual
		returns (uint256 underlyingAmnt, uint256 shortAmnt);

	function _updateAndGetBorrowBalances()
		internal
		virtual
		returns (uint256 underlyingAmnt, uint256 shortAmnt);

	function _optimalUBorrow() internal view virtual returns (uint256 uBorrow);

	function _harvestFarm(HarvestSwapParams calldata swapParams)
		internal
		virtual
		returns (uint256, uint256);

	function safetyMarginSqrt() public view virtual returns (uint256);

	function accrueInterest() public virtual;

	function _addIMXLiquidity(
		uint256 underlyingAmnt,
		uint256 shortAmnt,
		uint256 uBorrow,
		uint256 sBorrow
	) internal virtual;

	function _removeIMXLiquidity(
		uint256 removeLp,
		uint256 repayUnderlying,
		uint256 repayShort,
		uint256 uBorrow
	) internal virtual;

	function shortToUnderlyingOracleUpdate(uint256 amount) public virtual returns (uint256);

	function shortToUnderlyingOracle(uint256 amount) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

abstract contract ILp {
	function _quote(
		uint256 amount,
		address token0,
		address token1
	) internal view virtual returns (uint256 price);

	function _getLiquidity() internal view virtual returns (uint256);

	function _getLiquidity(uint256) internal view virtual returns (uint256);

	function _addLiquidity(uint256 amountToken0, uint256 amountToken1)
		internal
		virtual
		returns (uint256 liquidity);

	function _removeLiquidity(uint256 liquidity) internal virtual returns (uint256, uint256);

	function _getLPBalances()
		internal
		view
		virtual
		returns (uint256 underlyingBalance, uint256 shortBalance);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IUniswapV2Pair } from "../../interfaces/uniswap/IUniswapV2Pair.sol";
import { UniUtils } from "../../libraries/UniUtils.sol";

import { IBase } from "./IBase.sol";
import { ILp } from "./ILp.sol";

// import "hardhat/console.sol";

abstract contract IUniLp is IBase, ILp {
	using SafeERC20 for IERC20;
	using UniUtils for IUniswapV2Pair;

	function pair() public view virtual returns (IUniswapV2Pair);

	// should only be called after oracle or user-input swap price check
	function _addLiquidity(uint256 amountToken0, uint256 amountToken1)
		internal
		virtual
		override
		returns (uint256 liquidity)
	{
		underlying().safeTransfer(address(pair()), amountToken0);
		short().safeTransfer(address(pair()), amountToken1);
		liquidity = pair().mint(address(this));
	}

	function _removeLiquidity(uint256 liquidity)
		internal
		virtual
		override
		returns (uint256, uint256)
	{
		IERC20(address(pair())).safeTransfer(address(pair()), liquidity);
		(address tokenA, ) = UniUtils._sortTokens(address(underlying()), address(short()));
		(uint256 amountToken0, uint256 amountToken1) = pair().burn(address(this));
		return
			tokenA == address(underlying())
				? (amountToken0, amountToken1)
				: (amountToken1, amountToken0);
	}

	function _quote(
		uint256 amount,
		address token0,
		address token1
	) internal view virtual override returns (uint256 price) {
		if (amount == 0) return 0;
		(uint256 reserve0, uint256 reserve1) = pair()._getPairReserves(token0, token1);
		price = UniUtils._quote(amount, reserve0, reserve1);
	}

	// fetches and sorts the reserves for a uniswap pair
	function getUnderlyingShortReserves() public view returns (uint256 reserveA, uint256 reserveB) {
		(reserveA, reserveB) = pair()._getPairReserves(address(underlying()), address(short()));
	}

	function _getLPBalances()
		internal
		view
		override
		returns (uint256 underlyingBalance, uint256 shortBalance)
	{
		uint256 totalLp = _getLiquidity();
		(uint256 totalUnderlyingBalance, uint256 totalShortBalance) = getUnderlyingShortReserves();
		uint256 total = pair().totalSupply();
		underlyingBalance = (totalUnderlyingBalance * totalLp) / total;
		shortBalance = (totalShortBalance * totalLp) / total;
	}

	// this is the current uniswap price
	function _shortToUnderlying(uint256 amount) internal view virtual returns (uint256) {
		return amount == 0 ? 0 : _quote(amount, address(short()), address(underlying()));
	}

	// this is the current uniswap price
	function _underlyingToShort(uint256 amount) internal view virtual returns (uint256) {
		return amount == 0 ? 0 : _quote(amount, address(underlying()), address(short()));
	}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import { ERC20Upgradeable as ERC20 } from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ISuperComposableYield } from "../../interfaces/ERC5115/ISuperComposableYield.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20MetadataUpgradeable as IERC20Metadata } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import { Accounting } from "../../common/Accounting.sol";
// import { ERC20PermitUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import { SectorErrors } from "../../interfaces/SectorErrors.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { FeesU } from "../../common/FeesU.sol";

// import "hardhat/console.sol";

abstract contract SCYBaseU is
	Initializable,
	ISuperComposableYield,
	ReentrancyGuardUpgradeable,
	ERC20,
	Accounting,
	FeesU,
	SectorErrors
	// ERC20PermitUpgradeable,
{
	using SafeERC20 for IERC20;

	address internal constant NATIVE = address(0);
	uint256 internal constant ONE = 1e18;
	uint256 public constant MIN_LIQUIDITY = 1e3;

	uint256 public version;

	// solhint-disable no-empty-blocks
	receive() external payable {}

	/// @custom:oz-upgrades-unsafe-allow constructor
	constructor() {
		_disableInitializers();
	}

	function __SCYBase_init(string memory _name, string memory _symbol) internal onlyInitializing {
		__ReentrancyGuard_init();
		__ERC20_init(_name, _symbol);
		// __ERC20Permit_init(_name);
	}

	/*///////////////////////////////////////////////////////////////
                    DEPOSIT/REDEEM USING BASE TOKENS
    //////////////////////////////////////////////////////////////*/

	/**
	 * @dev See {ISuperComposableYield-deposit}
	 */
	function deposit(
		address receiver,
		address tokenIn,
		uint256 amountTokenToPull,
		uint256 minSharesOut
	) external payable nonReentrant returns (uint256 amountSharesOut) {
		require(isValidBaseToken(tokenIn), "SCY: Invalid tokenIn");

		if (tokenIn == NATIVE && amountTokenToPull != 0) revert CantPullEth();
		else if (amountTokenToPull != 0) _transferIn(tokenIn, msg.sender, amountTokenToPull);

		// this depends on strategy
		// this supports depositing directly into strategy to save gas
		uint256 amountIn = getFloatingAmount(tokenIn);
		if (amountIn == 0) revert ZeroAmount();

		amountSharesOut = _deposit(receiver, tokenIn, amountIn);
		if (amountSharesOut < minSharesOut) revert InsufficientOut(amountSharesOut, minSharesOut);

		// lock minimum liquidity if totalSupply is 0
		if (totalSupply() == 0) {
			if (MIN_LIQUIDITY > amountSharesOut) revert MinLiquidity();
			amountSharesOut -= MIN_LIQUIDITY;
			_mint(address(1), MIN_LIQUIDITY);
		}

		_mint(receiver, amountSharesOut);
		emit Deposit(msg.sender, receiver, tokenIn, amountIn, amountSharesOut);
	}

	/**
	 * @dev See {ISuperComposableYield-redeem}
	 */
	function redeem(
		address receiver,
		uint256 amountSharesToRedeem,
		address tokenOut,
		uint256 minTokenOut
	) external nonReentrant returns (uint256 amountTokenOut) {
		require(isValidBaseToken(tokenOut), "SCY: invalid tokenOut");

		// this is to handle a case where the strategy sends funds directly to user
		uint256 amountToTransfer;
		(amountTokenOut, amountToTransfer) = _redeem(receiver, tokenOut, amountSharesToRedeem);
		if (amountTokenOut < minTokenOut) revert InsufficientOut(amountTokenOut, minTokenOut);

		if (amountToTransfer > 0) _transferOut(tokenOut, receiver, amountToTransfer);

		emit Redeem(msg.sender, receiver, tokenOut, amountSharesToRedeem, amountTokenOut);
	}

	/**
	 * @notice mint shares based on the deposited base tokens
	 * @param tokenIn base token address used to mint shares
	 * @param amountDeposited amount of base tokens deposited
	 * @return amountSharesOut amount of shares minted
	 */
	function _deposit(
		address receiver,
		address tokenIn,
		uint256 amountDeposited
	) internal virtual returns (uint256 amountSharesOut);

	/**
	 * @notice redeems base tokens based on amount of shares to be burned
	 * @param tokenOut address of the base token to be redeemed
	 * @param amountSharesToRedeem amount of shares to be burned
	 * @return amountTokenOut amount of base tokens redeemed
	 */
	function _redeem(
		address receiver,
		address tokenOut,
		uint256 amountSharesToRedeem
	) internal virtual returns (uint256 amountTokenOut, uint256 tokensToTransfer);

	// VIRTUALS
	function getFloatingAmount(address token) public view virtual returns (uint256);

	/**
	 * @notice See {ISuperComposableYield-getBaseTokens}
	 */
	function getBaseTokens() external view virtual override returns (address[] memory res);

	/**
	 * @dev See {ISuperComposableYield-isValidBaseToken}
	 */
	function isValidBaseToken(address token) public view virtual override returns (bool);

	function _transferIn(
		address token,
		address to,
		uint256 amount
	) internal virtual;

	function _transferOut(
		address token,
		address to,
		uint256 amount
	) internal virtual;

	function _depositNative() internal virtual;

	// OVERRIDES
	function totalSupply() public view virtual override(Accounting, ERC20) returns (uint256) {
		return ERC20.totalSupply();
	}

	function sendERC20ToStrategy() public view virtual returns (bool) {
		return true;
	}

	error CantPullEth();
	error InsufficientOut(uint256 amountOut, uint256 minOut);

	uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import { SCYBaseU, Accounting, IERC20, ERC20, IERC20Metadata, SafeERC20 } from "./SCYBaseU.sol";
import { IMX } from "../../strategies/imx/IMX.sol";
import { Auth } from "../../common/Auth.sol";
import { SafeETH } from "../../libraries/SafeETH.sol";
import { FixedPointMathLib } from "../../libraries/FixedPointMathLib.sol";
import { IWETH } from "../../interfaces/uniswap/IWETH.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { EAction, HarvestSwapParams } from "../../interfaces/Structs.sol";
import { VaultType, EpochType } from "../../interfaces/Structs.sol";
import { BatchedWithdrawEpoch } from "../../common/BatchedWithdrawEpoch.sol";
import { SectorErrors } from "../../interfaces/SectorErrors.sol";
import { ISCYStrategy } from "../../interfaces/ERC5115/ISCYStrategy.sol";
import { SCYVaultConfig } from "../../interfaces/ERC5115/ISCYVault.sol";
import { AuthConfig } from "../../common/Auth.sol";
import { FeeConfig } from "../../common/Fees.sol";

// import "hardhat/console.sol";

contract SCYWEpochVaultU is SCYBaseU, BatchedWithdrawEpoch {
	using SafeERC20 for IERC20;
	using FixedPointMathLib for uint256;

	VaultType public constant vaultType = VaultType.Strategy;
	// inherits epochType from BatchedWithdrawEpoch
	// EpochType public constant epochType = EpochType.Withdraw;

	event Harvest(
		address indexed treasury,
		uint256 underlyingProfit,
		uint256 performanceFee,
		uint256 managementFee,
		uint256 sharesFees,
		uint256 tvl
	);

	uint256 public lastHarvestTimestamp;

	ISCYStrategy public strategy;

	// immutables
	address public override yieldToken;
	uint16 public strategyId; // strategy-specific id ex: for MasterChef or 1155
	bool public acceptsNativeToken;
	IERC20 public underlying;

	uint256 public maxTvl; // pack all params and balances
	uint256 public vaultTvl; // strategy balance in underlying
	uint256 public uBalance; // underlying balance held by vault

	event MaxTvlUpdated(uint256 maxTvl);
	event StrategyUpdated(address strategy);

	modifier isInitialized() {
		if (address(strategy) == address(0)) revert NotInitialized();
		_;
	}

	function initialize(
		AuthConfig memory authConfig,
		FeeConfig memory feeConfig,
		SCYVaultConfig memory vaultConfig
	) external initializer {
		__Auth_init(authConfig);
		__Fees_init(feeConfig);
		__SCYBase_init(vaultConfig.name, vaultConfig.symbol);

		yieldToken = vaultConfig.yieldToken;
		strategy = ISCYStrategy(vaultConfig.addr);
		strategyId = vaultConfig.strategyId;
		underlying = vaultConfig.underlying;
		acceptsNativeToken = vaultConfig.acceptsNativeToken;
		maxTvl = vaultConfig.maxTvl;

		lastHarvestTimestamp = block.timestamp;
	}

	// we should never send tokens directly to strategy for Epoch-based vaults
	function sendERC20ToStrategy() public pure override returns (bool) {
		return false;
	}

	/*///////////////////////////////////////////////////////////////
                    CONFIG
    //////////////////////////////////////////////////////////////*/

	function getMaxTvl() public view returns (uint256) {
		return min(maxTvl, strategy.getMaxTvl());
	}

	function setMaxTvl(uint256 _maxTvl) public onlyRole(GUARDIAN) {
		maxTvl = _maxTvl;
		emit MaxTvlUpdated(min(maxTvl, strategy.getMaxTvl()));
	}

	function initStrategy(address _strategy) public onlyRole(GUARDIAN) {
		if (address(strategy) != address(0)) revert NoReInit();
		strategy = ISCYStrategy(_strategy);
		_validateStrategy();
		emit StrategyUpdated(_strategy);
	}

	function updateStrategy(address _strategy) public onlyOwner {
		uint256 tvl = strategy.getAndUpdateTvl();
		if (tvl > 0) revert InvalidStrategyUpdate();
		strategy = ISCYStrategy(_strategy);
		_validateStrategy();
		emit StrategyUpdated(_strategy);
	}

	function _validateStrategy() internal view {
		if (strategy.underlying() != underlying) revert InvalidStrategy();
	}

	function _depositNative() internal override {
		IWETH(address(underlying)).deposit{ value: msg.value }();
	}

	function _deposit(
		address,
		address token,
		uint256 amount
	) internal override isInitialized returns (uint256 sharesOut) {
		if (vaultTvl + amount > getMaxTvl()) revert MaxTvlReached();

		// if we have any float in the contract we cannot do deposit accounting
		uint256 _totalAssets = totalAssets();
		if (uBalance > 0 && _totalAssets > 0) revert DepositsPaused();

		if (token == NATIVE) _depositNative();

		// if the strategy is active, we can deposit dirictly into strategy
		// if not, we deposit into the vault for a future strategy deposit
		if (_totalAssets > 0) {
			underlying.safeTransfer(address(strategy), amount);
			uint256 yieldTokenAdded = strategy.deposit(amount);
			// don't include newly minted shares and pendingRedeem in the calculation
			sharesOut = toSharesAfterDeposit(yieldTokenAdded);
		} else {
			// sharesOut = underlyingToSharesAfterDeposit(amount);
			sharesOut = underlyingToSharesAfterDeposit(amount);
			uBalance += amount;
		}

		vaultTvl += amount;
	}

	function _redeem(
		address,
		address token,
		uint256 expectedShares
	) internal override returns (uint256 amountTokenOut, uint256 amountToTransfer) {
		uint256 sharesToRedeem;
		(amountTokenOut, sharesToRedeem) = _redeem(msg.sender);
		if (sharesToRedeem != expectedShares) revert InvalidSharesOut();
		_burn(address(this), sharesToRedeem);

		if (token == NATIVE) IWETH(address(underlying)).withdraw(amountTokenOut);
		return (amountTokenOut, amountTokenOut);
	}

	/// @notice harvest strategy
	function harvest(
		uint256 expectedTvl,
		uint256 maxDelta,
		HarvestSwapParams[] calldata swap1,
		HarvestSwapParams[] calldata swap2
	) external onlyRole(MANAGER) returns (uint256[] memory harvest1, uint256[] memory harvest2) {
		/// TODO refactor this
		uint256 _uBalance = underlying.balanceOf(address(this));
		uint256 startTvl = strategy.getAndUpdateTvl() + _uBalance;

		_checkSlippage(expectedTvl, startTvl, maxDelta);

		if (swap1.length > 0 || swap2.length > 0)
			(harvest1, harvest2) = strategy.harvest(swap1, swap2);

		uint256 tvl = strategy.getTvl() + _uBalance;

		uint256 prevTvl = vaultTvl;
		uint256 timestamp = block.timestamp;
		uint256 profit = tvl > prevTvl ? tvl - prevTvl : 0;

		// PROCESS VAULT FEES
		uint256 _performanceFee = profit == 0 ? 0 : (profit * performanceFee) / 1e18;
		uint256 _managementFee = managementFee == 0
			? 0
			: (managementFee * tvl * (timestamp - lastHarvestTimestamp)) / 1e18 / 365 days;

		uint256 totalFees = _performanceFee + _managementFee;
		uint256 feeShares;
		if (totalFees > 0) {
			// we know that totalSupply != 0 and tvl > totalFees
			// this results in more accurate accounting considering dilution
			feeShares = totalFees.mulDivDown(totalSupply(), tvl - totalFees);
			_mint(treasury, feeShares);
		}

		emit Harvest(treasury, profit, _performanceFee, _managementFee, feeShares, tvl);

		vaultTvl = tvl;

		lastHarvestTimestamp = timestamp;
	}

	// minAmountOut is a slippage parameter for withdrawing requestedRedeem shares
	function processRedeem(uint256 minAmountOut) public override onlyRole(MANAGER) {
		// we must subtract pendingRedeem form totalSupply
		uint256 _totalSupply = totalSupply() - pendingRedeem;

		uint256 yeildTokenRedeem = convertToAssets(requestedRedeem);

		// account for any extra underlying balance to avoide DOS attacks
		uint256 balance = underlying.balanceOf(address(this));
		if (balance > (pendingWithdrawU + uBalance)) {
			uint256 extraFloat = balance - (pendingWithdrawU + uBalance);
			uBalance += extraFloat;
		}

		// vault may hold float of underlying, in this case, add a share of reserves to withdrawal
		// TODO why not use underlying.balanceOf?
		uint256 reserves = uBalance;
		uint256 shareOfReserves = (reserves * requestedRedeem) / (_totalSupply);

		// Update strategy underlying reserves balance
		if (shareOfReserves > 0) uBalance -= shareOfReserves;

		uint256 stratTvl = strategy.getAndUpdateTvl();
		uint256 amountTokenOut = stratTvl == 0
			? 0
			: strategy.redeem(address(this), yeildTokenRedeem);
		emit WithdrawFromStrategy(msg.sender, amountTokenOut);

		amountTokenOut += shareOfReserves;

		// its possible that cached vault tvl is lower than actual tvl
		uint256 _vaultTvl = vaultTvl;
		vaultTvl = _vaultTvl > amountTokenOut ? _vaultTvl - amountTokenOut : 0;

		if (amountTokenOut < minAmountOut) revert InsufficientOut(amountTokenOut, minAmountOut);

		// manually compute redeem shares here
		_processRedeem((1e18 * amountTokenOut) / requestedRedeem);
	}

	function _checkSlippage(
		uint256 expectedValue,
		uint256 actualValue,
		uint256 maxDelta
	) internal pure {
		uint256 delta = expectedValue > actualValue
			? expectedValue - actualValue
			: actualValue - expectedValue;
		if (delta > maxDelta) revert SlippageExceeded();
	}

	/// @notice slippage is computed in shares
	function depositIntoStrategy(uint256 underlyingAmount, uint256 minAmountOut)
		public
		onlyRole(MANAGER)
	{
		if (underlyingAmount > uBalance) revert NotEnoughUnderlying();
		uBalance -= underlyingAmount;
		underlying.safeTransfer(address(strategy), underlyingAmount);
		uint256 yAdded = strategy.deposit(underlyingAmount);
		uint256 virtualSharesOut = convertToShares(yAdded);
		if (virtualSharesOut < minAmountOut) revert InsufficientOut(virtualSharesOut, minAmountOut);
		emit DepositIntoStrategy(msg.sender, underlyingAmount);
	}

	/// @notice slippage is computed in underlying
	function withdrawFromStrategy(uint256 shares, uint256 minAmountOut) public onlyRole(MANAGER) {
		uint256 yieldTokenAmnt = convertToAssets(shares);
		uint256 underlyingWithdrawn = strategy.redeem(address(this), yieldTokenAmnt);
		if (underlyingWithdrawn < minAmountOut)
			revert InsufficientOut(underlyingWithdrawn, minAmountOut);
		uBalance += underlyingWithdrawn;
		emit WithdrawFromStrategy(msg.sender, underlyingWithdrawn);
	}

	function closePosition(uint256 minAmountOut, uint256 slippageParam) public onlyRole(MANAGER) {
		uint256 underlyingWithdrawn = strategy.closePosition(slippageParam);
		if (underlyingWithdrawn < minAmountOut)
			revert InsufficientOut(underlyingWithdrawn, minAmountOut);
		uBalance += underlyingWithdrawn;
		emit ClosePosition(msg.sender, underlyingWithdrawn);
	}

	/// @notice this method allows an arbitrary method to be called by the owner in case of emergency
	/// owner must be a timelock contract in order to allow users to redeem funds in case they suspect
	/// this action to be malicious
	function emergencyAction(EAction[] calldata actions) public payable onlyOwner {
		uint256 l = actions.length;
		for (uint256 i = 0; i < l; i++) {
			address target = actions[i].target;
			bytes memory data = actions[i].data;
			(bool success, ) = target.call{ value: actions[i].value }(data);
			require(success, "emergencyAction failed");
			emit EmergencyAction(target, data);
		}
	}

	function getStrategyTvl() public view returns (uint256) {
		return strategy.getTvl();
	}

	/// no slippage check - slippage can be done on vault level
	/// against total expected balance of all strategies
	function getAndUpdateTvl() public returns (uint256 tvl) {
		uint256 stratTvl = strategy.getAndUpdateTvl();
		uint256 balance = underlying.balanceOf(address(this));
		tvl = balance + stratTvl;
	}

	function getTvl() public view returns (uint256 tvl) {
		uint256 stratTvl = strategy.getTvl();
		uint256 balance = underlying.balanceOf(address(this));
		tvl = balance + stratTvl;
	}

	function totalAssets() public view override returns (uint256) {
		return strategy.getLpBalance();
	}

	function isPaused() public view returns (bool) {
		return (uBalance > 0 && totalAssets() > 0);
	}

	/// @dev used for estimates only
	/// @dev includes pendingRedeem shares and pendingWithdrawUnderlying
	function exchangeRateUnderlying() public view returns (uint256) {
		uint256 _totalSupply = totalSupply();
		if (_totalSupply == 0) return strategy.collateralToUnderlying();
		uint256 tvl = underlying.balanceOf(address(this)) + strategy.getTvl();
		return tvl.mulDivUp(ONE, _totalSupply);
	}

	/// @dev includes pendingRedeem shares and pendingWithdrawUnderlying
	function getUpdatedUnderlyingBalance(address user) external returns (uint256) {
		uint256 userBalance = balanceOf(user);
		uint256 _totalSupply = totalSupply();
		if (_totalSupply == 0 || userBalance == 0) return 0;
		uint256 tvl = underlying.balanceOf(address(this)) + strategy.getAndUpdateTvl();
		return (tvl * userBalance) / _totalSupply;
	}

	/// @dev includes pendingRedeem shares and pendingWithdrawUnderlying
	function underlyingBalance(address user) external view returns (uint256) {
		uint256 userBalance = balanceOf(user);
		uint256 _totalSupply = totalSupply();
		if (_totalSupply == 0 || userBalance == 0) return 0;
		uint256 tvl = underlying.balanceOf(address(this)) + strategy.getTvl();
		return (tvl * userBalance) / _totalSupply;
	}

	/// @dev includes pendingRedeem shares and pendingWithdrawUnderlying
	function underlyingToShares(uint256 uAmnt) public view returns (uint256) {
		uint256 _totalSupply = totalSupply();
		if (_totalSupply == 0) return uAmnt.mulDivDown(ONE, strategy.collateralToUnderlying());
		return uAmnt.mulDivDown(_totalSupply, getTvl());
	}

	/// @dev includes pendingRedeem shares and pendingWithdrawUnderlying
	function underlyingToSharesAfterDeposit(uint256 uAmnt) public view returns (uint256) {
		uint256 _totalSupply = totalSupply();
		if (_totalSupply == 0) return uAmnt.mulDivDown(ONE, strategy.collateralToUnderlying());
		return uAmnt.mulDivDown(_totalSupply, getTvl() - uAmnt);
	}

	/// @dev includes pendingRedeem shares and pendingWithdrawUnderlying
	function sharesToUnderlying(uint256 shares) public view returns (uint256) {
		uint256 _totalSupply = totalSupply();
		if (_totalSupply == 0) return (shares * strategy.collateralToUnderlying()) / ONE;
		return shares.mulDivDown(getTvl(), _totalSupply);
	}

	///
	///  Yield Token Overrides
	///

	function convertToAssets(uint256 shares) public view override returns (uint256) {
		// we need to subtract pendingReedem because it is not included in totalAssets
		// pendingRedeem should allways be smaller than totalSupply
		uint256 supply = totalSupply() - pendingRedeem;
		return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
	}

	function convertToShares(uint256 assets) public view override returns (uint256) {
		// we need to subtract pendingReedem because it is not included in totalAssets
		// pendingRedeem should allways be smaller than totalSupply
		uint256 supply = totalSupply() - pendingRedeem;
		return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
	}

	function assetInfo()
		public
		view
		returns (
			AssetType assetType,
			address assetAddress,
			uint8 assetDecimals
		)
	{
		address yToken = yieldToken;
		return (AssetType.LIQUIDITY, yToken, IERC20Metadata(yToken).decimals());
	}

	function underlyingDecimals() public view returns (uint8) {
		return IERC20Metadata(address(underlying)).decimals();
	}

	/// make sure to override this - actual logic should use floating strategy balances
	function getFloatingAmount(address token)
		public
		view
		virtual
		override
		returns (uint256 fltAmnt)
	{
		if (token == address(underlying))
			return underlying.balanceOf(address(this)) - uBalance - pendingWithdrawU;
		if (token == NATIVE) return address(this).balance;
	}

	function decimals() public pure override returns (uint8) {
		return 18;
	}

	function getBaseTokens() external view virtual override returns (address[] memory res) {
		if (acceptsNativeToken) {
			res = new address[](2);
			res[1] = NATIVE;
		} else res = new address[](1);
		res[0] = address(underlying);
	}

	function isValidBaseToken(address token) public view virtual override returns (bool) {
		return token == address(underlying) || (acceptsNativeToken && token == NATIVE);
	}

	// send funds to strategy
	function _transferIn(
		address token,
		address from,
		uint256 amount
	) internal virtual override {
		address to = address(this);
		IERC20(token).safeTransferFrom(from, to, amount);
	}

	// send funds to user
	function _transferOut(
		address token,
		address to,
		uint256 amount
	) internal virtual override {
		if (token == NATIVE) {
			SafeETH.safeTransferETH(to, amount);
		} else {
			IERC20(token).safeTransfer(to, amount);
		}
	}

	function _transfer(
		address sender,
		address recipient,
		uint256 amount
	) internal override(BatchedWithdrawEpoch, ERC20) {
		super._transfer(sender, recipient, amount);
	}

	function _spendAllowance(
		address owner,
		address spender,
		uint256 amount
	) internal override(BatchedWithdrawEpoch, ERC20) {
		super._spendAllowance(owner, spender, amount);
	}

	function totalSupply() public view override(Accounting, SCYBaseU) returns (uint256) {
		return ERC20.totalSupply();
	}

	/// @dev used to compute slippage on withdraw
	function getWithdrawAmnt(uint256 shares) public view returns (uint256) {
		uint256 assets = convertToAssets(shares);
		return ISCYStrategy(strategy).getWithdrawAmnt(assets);
	}

	/// @dev used to compute slippage on deposit
	function getDepositAmnt(uint256 uAmnt) public view returns (uint256) {
		uint256 assets = ISCYStrategy(strategy).getDepositAmnt(uAmnt);
		return convertToShares(assets);
	}

	/**
	 * @dev Returns the smallest of two numbers.
	 */
	function min(uint256 a, uint256 b) internal pure returns (uint256) {
		return a < b ? a : b;
	}

	event WithdrawFromStrategy(address indexed caller, uint256 amount);
	event DepositIntoStrategy(address indexed caller, uint256 amount);
	event ClosePosition(address indexed caller, uint256 amount);
	event EmergencyAction(address target, bytes callData);

	error InvalidStrategyUpdate();
	error NoReInit();
	error InvalidStrategy();
	error NotInitialized();
	error DepositsPaused();
	error StrategyExists();
	error StrategyDoesntExist();
	error NotEnoughUnderlying();
	error SlippageExceeded();
	error InvalidSharesOut();
}