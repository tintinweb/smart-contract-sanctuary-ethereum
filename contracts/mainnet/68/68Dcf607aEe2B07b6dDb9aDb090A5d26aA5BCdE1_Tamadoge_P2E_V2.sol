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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
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
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";


interface IERC20Burnable is IERC20Upgradeable {
    function burn(uint256 amount) external;
}


contract Tamadoge_P2E_V2 is 
    Initializable,
    AccessControlUpgradeable,
    OwnableUpgradeable
{
    
    /// @dev Tamadoge Token Address
    IERC20Burnable public tamaToken;

    /// @dev Total tama burned till now by this P2E contract.
    uint256 public totalTamaBurned;

    /// @dev Total tama staked in this contract by users.
    uint256 public totalStakedAmountInContract;

    /// @dev Current amount of tama available in contract out of total staked by users.
    uint256 public currentStakedAmountAvailableInContract;

    /// @dev Tama Per Arcade Credit bought to send to reward pool.
    uint256 public tamaPerCreditToSendToRewardPool;

    /**
     * Percentage of tama to
     * - Send to staking reward pool
     * - To burn
     * From the tama left after sending (tamaPerCreditToSendToRewardPool * creditsBought) to p2eRewardPoolBalance.
     */
    uint256 public tamaPercentageToSendToStakingRewardPool;
    uint256 public tamaPercentageToBurn;

    /// @dev Balance of P2E Reward Pool used to distribute rewards to game winners from leaderboard.
    uint256 public p2eRewardPoolBalance;

    /// @dev Balance of Staking Reward pool, used to buy arcade credits for users staking tama.
    uint256 public stakingRewardsPoolBalance;

    /// @dev Total available plans for buying arcade credits with tama (active + inactive)
    uint256 public arcadeCreditBuyPlansAvailable;

    /// @dev Total available plans for staking tama (active + inactive)
    uint256 public tamaStakePlansAvailable;


    struct ArcadeCreditBuyPlan {
        uint256 arcadeCredits;
        uint256 tamaRequired;
        bool isActive;
    }

    struct TamaStakePlan {
        uint256 stakeDurationInSeconds;
        bool isActive;
    }

    struct TamaStake {
        uint256 stakedAmount;
        uint256 stakeTime;
        uint256 tamaStakePlanId;
    }

    struct UserStakes {
        uint256 totalStakes;
        uint256 totalAmountStaked;
        mapping(uint256 => TamaStake) tamaStakes;
    }

    // Mapping arcade credit buy plan id => plan struct
    mapping(uint256 => ArcadeCreditBuyPlan) public arcadeCreditBuyPlans;

    // Mapping tama stake plan id => plan struct
    mapping(uint256 => TamaStakePlan) public tamaStakePlans;

    // Mapping address to UserStakes struct
    mapping(address => UserStakes) private stakes;

    // Map gameIds to IPFS result hash
    mapping(uint256 => string) public gameResults;

    // Storage variables for EIP-712 signatures.
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant _TAMA_REWARD_CLAIM_TYPEHASH = keccak256("TamaRewardClaim(address receiver,uint256 tamaAmount,uint256 claimNumber)");

    struct TamaRewardClaim {
        address receiver;
        uint256 tamaAmount;
        uint256 claimNumber;
    }

    mapping(bytes => bool) private isSignatureUsed;
    // Mapping addresses to the total no of times they have claimed tama rewards.
    mapping(address => uint256) public totalTamaClaims;

    

    // Event for users buying arcade credits with tama.
    event ArcadeCreditsBought(
        address indexed by,
        uint256 indexed arcadeCreditBuyPlan,
        uint256 arcadeCreditsBought,
        uint256 tamaPaid,
        uint256 timestamp
    );
    
    // Event for arcade credits bought from stakingRewardsPoolBalance by owner/admin.
    event ArcadeCreditsBoughtFromStakingRewardsPool(
        address indexed by, 
        uint256 indexed totalArcadeCreditsBought, 
        uint256 indexed totalTamaRequired, 
        uint256 tamaPercentageToBurn, 
        uint256 tamaPercentageToSendToStakingRewardPool,
        uint256 tamaAddedToP2eRewardPool,
        uint256 tamaBurned,
        uint256 stakingRewardsPoolBalance,
        uint256 timestamp
    );

    // Events for users staking/unstaking tama tokens in contract for receiving arcade credits.
    event TamaStaked(
        address indexed by,
        uint256 indexed planId,
        uint256 stakeId,
        uint256 amount,
        uint256 timestamp,
        uint256 unlockTime
    );
    
    event TamaUnstakedBatch(
        address indexed by,
        uint256[] stakeIds,
        uint256 totalUnstakedTamaAmount,
        uint256 timestamp
    );
    
    // Events for owner/admin withdrawing user-deposited tama from contract or depositing it back.
    event TamaTokensWithdrawnFromUserStakes(
        address indexed by,
        uint256 amount,
        uint256 timestamp
    );

    event TamaTokensDepositedToUserStakes(
        address indexed by,
        uint256 amount,
        uint256 timestamp
    );

    // Events for activating, deactivating, updating an existing ArcadeCreditBuyPlan and for adding a new one.
    event ActivatedArcadeCreditBuyPlans(
        address indexed by,
        uint256[] planIds,
        uint256 timestamp
    );

    event DeactivatedArcadeCreditBuyPlans(
        address indexed by,
        uint256[] planIds,
        uint256 timestamp
    );

    event UpdatedArcadeCreditBuyPlan(
        address indexed by,
        uint256 indexed planId,
        uint256 arcadeCredits,
        uint256 tamaRequired,
        uint256 timestamp
    );

    event AddedNewArcadeCreditBuyPlan(
        address indexed by,
        uint256 indexed planId,
        uint256 arcadeCredits,
        uint256 tamaRequired,
        bool isActivated,
        uint256 timestamp
    );

    // Events for activating, deactivating, updating an existing TamaStakePlan and for adding a new one.
    event ActivatedTamaStakePlans(
        address indexed by,
        uint256[] planIds,
        uint256 timestamp
    );

    event DeactivatedTamaStakePlans(
        address indexed by,
        uint256[] planIds,
        uint256 timestamp
    );

    event UpdatedTamaStakePlan(
        address indexed by,
        uint256 indexed planId,
        uint256 stakeDurationInSeconds,
        uint256 timestamp
    );

    event AddedNewTamaStakePlan(
        address indexed by,
        uint256 indexed planId,
        uint256 stakeDurationInSeconds,
        bool isActivated,
        uint256 timestamp
    );

    // Event for tama payouts from p2e reward pool balance.
    event TamaPayoutFromP2eRewardPool(
        address indexed by,
        address[] addresses,
        uint256[] amounts,
        uint256 p2eRewardPoolBalanceLeft,
        uint256 timestamp
    );

    // Event for publishing game results on IPFS.
    event GameResultPublished(
        address indexed by,
        uint256 indexed gameId,
        string result,
        uint256 timestamp
    );

    event UpdatedTamaPerCreditToRewardPool (
        address indexed by,
        uint256 tamaPerCreditToSendToRewardPool,
        uint256 timestamp
    );

    event UpdatedTamaDistributionPercentages(
        address indexed by,
        uint256 tamaPercentageToBurn,
        uint256 tamaPercentageToSendToStakingRewardPool,
        uint256 timestamp
    );

    event TamaRewardClaimed(
        address indexed by,
        uint256 amount,
        uint256 claimNumber,
        bytes signature,
        uint256 timestamp
    );


    /// @dev msg.sender must be contract owner or have DEFAULT_ADMIN_ROLE.
    modifier onlyAdminOrOwner() {
        require(
            msg.sender == owner() || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Only admin/owner."
        );
        _;
    }


    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }


    /**
     * @notice Initializes the contract.
     * @param _tamaToken Address of the deployed tama token contract.
     * @param _adminWallet Address of the account to be given the DEFAULT_ADMIN_ROLE.
     * @param _tamaPerCreditToSendToRewardPool Amount to tama to be sent to P2E reward pool on each arcade credit bought.
     * @param _tamaPercentageToSendToStakingRewardPool Percentage of tama to be sent to Staking reward pool from tama left after its sent to p2eRewardPool.
     * @param _tamaPercentageToBurn Percentage of tama to be burned from tama left after its sent to p2eRewardPool.
     * @param _arcadeCreditBuyPlans Arcade Credit Buy Plans with which contract is to be initialized.
     * @param _tamaStakePlans Tama Stake Plans with which contract is to be initialized.
     */
    function initialize(
        address _tamaToken,
        address _adminWallet,
        uint256 _tamaPerCreditToSendToRewardPool,
        uint256 _tamaPercentageToSendToStakingRewardPool,
        uint256 _tamaPercentageToBurn,
        ArcadeCreditBuyPlan[] memory _arcadeCreditBuyPlans,
        TamaStakePlan[] memory _tamaStakePlans
    ) external initializer {
        require(
            _tamaToken != address(0) && _adminWallet != address(0),
            "Null address."
        );
        require(
            _tamaPercentageToBurn + _tamaPercentageToSendToStakingRewardPool == 10000,
            "Burn and Staking reward pool percentage sum should be 10000."
        );

        __AccessControl_init();
        __Ownable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _adminWallet);
        tamaToken = IERC20Burnable(_tamaToken);

        tamaPerCreditToSendToRewardPool = _tamaPerCreditToSendToRewardPool;
        tamaPercentageToSendToStakingRewardPool = _tamaPercentageToSendToStakingRewardPool;
        tamaPercentageToBurn = _tamaPercentageToBurn;

        addNewArcadeCreditBuyPlans(_arcadeCreditBuyPlans);
        addNewTamaStakePlans(_tamaStakePlans);
    }


    /**
     * @notice Creates the EIP-712 domain separator.
     * @param _name Domain name
     * @param _version Domain version
     * @param _reinitializeVersion Re-Initialization version number.
     */
    function createEip712Domain(
        string memory _name,
        string memory _version,
        uint8 _reinitializeVersion
    ) external onlyAdminOrOwner reinitializer(_reinitializeVersion) {
        bytes32 hashedName = keccak256(bytes(_name));
        bytes32 hashedVersion = keccak256(bytes(_version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }


    /**
     * @notice Function to buy arcade credits with tamadoge tokens.
     * @dev Needs tama allowance from buyer.
     * @param _planId Id of the available arcade credit buy plan that user wants to buy arcade credits with.
     */
    function buyArcadeCredits(uint256 _planId) external {
        // Plan must be valid.
        require(
            _planId != 0 && _planId <= arcadeCreditBuyPlansAvailable,
            "Invalid plan id."
        );

        // Retrieve arcade buy plan details for given id.
        ArcadeCreditBuyPlan memory plan = arcadeCreditBuyPlans[_planId];

        // Plan must be active.
        require(plan.isActive, "Plan inactive.");

        // This contract should have sufficient tama allowance from msg.sender.
        require(
            tamaToken.allowance(msg.sender, address(this)) >= plan.tamaRequired,
            "Insufficient tama allowance."
        );
        
        // Calculate tama to be sent to p2eRewardPool.
        uint256 tamaToSendToP2EPool = tamaPerCreditToSendToRewardPool * plan.arcadeCredits;

        // Calculate the value of tama tokens to be burned.
        uint256 tamaToBurn = ((plan.tamaRequired - tamaToSendToP2EPool) * tamaPercentageToBurn) / 10000;

        // Increment value of total tama burned by contract.
        totalTamaBurned += tamaToBurn;

        // Increment Staking Reward Pool balance by percentage set.
        stakingRewardsPoolBalance += (plan.tamaRequired - tamaToSendToP2EPool - tamaToBurn);
        
        // Increment p2eRewardPoolBalance.
        p2eRewardPoolBalance += tamaToSendToP2EPool;

        // Emit ArcadeCreditsBought event.
        emit ArcadeCreditsBought(
            msg.sender,
            _planId,
            plan.arcadeCredits,
            plan.tamaRequired,
            block.timestamp
        );

        // Transfer tama from msg.sender to this contract.
        require(
            tamaToken.transferFrom(msg.sender, address(this), plan.tamaRequired),
            "Error in transferring tama."
        );

        // Burn tama tokens.
        tamaToken.burn(tamaToBurn);
    }


    /**
     * @notice Function for admin/owner to buy arcade credits from stakingRewardsPoolBalance for users who have staked tama in this contract.
     * @param _totalArcadeCreditsToBuy Total amount of arcade credits to be bought.
     * @param _totalTamaRequired Total amount of tama required for buying these arcade credits. Should be >= (tamaPerCreditToSendToRewardPool * _totalArcadeCreditsToBuy).
     * @param _tamaPercentageToBurn Percentage of tama tokens to burn.
     * @param _tamaPercentageToSendToStakingRewardPool Percentage of tama to be sent/kept back in the stakingRewardsPool.
     */
    function buyArcadeCreditsFromStakingRewardPool(
        uint256 _totalArcadeCreditsToBuy,
        uint256 _totalTamaRequired,
        uint256 _tamaPercentageToBurn,
        uint256 _tamaPercentageToSendToStakingRewardPool
    ) external onlyAdminOrOwner {

        require(
            _totalArcadeCreditsToBuy * tamaPerCreditToSendToRewardPool <= _totalTamaRequired,
            "_totalArcadeCreditsToBuy * tamaPerCreditToSendToRewardPool is greater than _totalTamaRequired"
        );
        require(
            _totalTamaRequired <= stakingRewardsPoolBalance,
            "Insufficient tama in stakingRewardsPoolBalance"
        );
        require(
            _tamaPercentageToBurn + _tamaPercentageToSendToStakingRewardPool == 10000,
            "Burn and Staking reward pool percentage sum should be 10000."
        );
        
        // Calculate tama to be sent to p2eRewardPool.
        uint256 tamaToSendToP2EPool = tamaPerCreditToSendToRewardPool * _totalArcadeCreditsToBuy;

        // Calculate the value of tama tokens to be burned.
        uint256 tamaToBurn = ((_totalTamaRequired - tamaToSendToP2EPool) * _tamaPercentageToBurn) / 10000;

        // Increment value of total tama burned by contract.
        totalTamaBurned += tamaToBurn;

        // Decrement the stakingRewardsPoolBalance.
        stakingRewardsPoolBalance -= (tamaToSendToP2EPool + tamaToBurn);

        // Increment p2eRewardPoolBalance.
        p2eRewardPoolBalance += tamaToSendToP2EPool;

        // Emit ArcadeCreditsBoughtFromStakingRewardsPool event.
        emit ArcadeCreditsBoughtFromStakingRewardsPool(
            msg.sender, 
            _totalArcadeCreditsToBuy, 
            _totalTamaRequired, 
            _tamaPercentageToBurn, 
            _tamaPercentageToSendToStakingRewardPool, 
            tamaToSendToP2EPool, 
            tamaToBurn, 
            stakingRewardsPoolBalance, 
            block.timestamp
        );

        // Burn tama tokens.
        tamaToken.burn(tamaToBurn);
    }


    /**
     * @notice Function for user to lock tama tokens for fixed period of time to get arcade credits as reward.
     * @param _planId Id of the stake plan to use for locking tama tokens.
     * @param _amountToStake Amount of tama tokens to lock/stake.
     */
    function stakeTama(uint256 _planId, uint256 _amountToStake) external {
        // Stake amount must be greater than zero.
        require(_amountToStake > 0, "Stake amount must be greater than zero.");

        // PLan must be valid.
        require(_planId != 0 && _planId <= tamaStakePlansAvailable , "Invalid plan id.");

        // Plan must be active.
        require(tamaStakePlans[_planId].isActive, "Plan inactive.");

        // This contract should have sufficient tama allowance from msg.sender.
        require(
            tamaToken.allowance(msg.sender, address(this)) >= _amountToStake,
            "Insufficient tama allowance."
        );

        // Update storage variables for user's stakes.
        UserStakes storage userStake = stakes[msg.sender];
        userStake.totalStakes += 1;
        userStake.totalAmountStaked += _amountToStake;

        userStake.tamaStakes[userStake.totalStakes] = TamaStake(
            _amountToStake,
            block.timestamp,
            _planId
        );

        // Update storage values of totalStakedAmountInContract and currentStakedAmountAvailableInContract.
        totalStakedAmountInContract += _amountToStake;
        currentStakedAmountAvailableInContract += _amountToStake;

        // Emit the TamaStaked event.
        emit TamaStaked(
            msg.sender,
            _planId,
            userStake.totalStakes,
            _amountToStake,
            block.timestamp,
            block.timestamp + tamaStakePlans[_planId].stakeDurationInSeconds
        );

        // Transfer tama from msg.sender to this contract.
        require(
            tamaToken.transferFrom(msg.sender, address(this), _amountToStake),
            "Error while transferring tama."
        );
    }


    /**
     * @notice Batch function for unlocking/ unstaking tama tokens with the given stake ids.
     * @param _stakeIds An array of stake ids to be unstaked.
     */
    function batchUnstakeTama(uint256[] memory _stakeIds) external {
        // Read stake from storage.
        UserStakes storage userStakes = stakes[msg.sender];
        uint256 totalTamaUnstaked = 0;

        for(uint256 i=0; i<_stakeIds.length; i++) {

            uint256 _stakeId = _stakeIds[i];
            TamaStake memory userTamaStake = userStakes.tamaStakes[_stakeId];

            // Check if id given is valid. 
            require(_stakeId <= userStakes.totalStakes, "Invalid id.");

            // If amount = 0, then tokens are unstaked already.
            require(userTamaStake.stakedAmount != 0, "Already unstaked.");

            // Check if the stake with given id can be unstaked.
            require(
                (userTamaStake.stakeTime + tamaStakePlans[userTamaStake.tamaStakePlanId].stakeDurationInSeconds) < block.timestamp,
                "Unlock time not reached."
            );

            // Delete stake struct info for this id in the mapping/ set values to 0.
            userStakes.tamaStakes[_stakeId].stakedAmount = 0;
            userStakes.tamaStakes[_stakeId].stakeTime = 0;
            userStakes.tamaStakes[_stakeId].tamaStakePlanId = 0;

            // Increment totalTamaUnstaked.
            totalTamaUnstaked += userTamaStake.stakedAmount;
        }
        
        // Check if currentStakedAmountAvailableInContract >= total amount being unstaked.
        require(
            currentStakedAmountAvailableInContract >= totalTamaUnstaked,
            "Insufficent staked balance in contract."
        );
        
        // Update totalAmountStaked for user.
        userStakes.totalAmountStaked -= totalTamaUnstaked;

        // Update totalStakedAmountInContract and currentStakedAmountAvailableInContract for this contract.
        totalStakedAmountInContract -= totalTamaUnstaked;
        currentStakedAmountAvailableInContract -= totalTamaUnstaked;

        // Emit the TamaUnstaked event.
        emit TamaUnstakedBatch(
            msg.sender,
            _stakeIds,
            totalTamaUnstaked,
            block.timestamp
        );

        // Transfer the tama tokens to msg.sender.
        require(
            tamaToken.transfer(msg.sender, totalTamaUnstaked),
            "Error while transferring tama."
        );
    }


    /**
     * @notice Function for contract owner to withdraw tama from user stakes.
     * @dev Owner cannot withdraw more than currentStakedAmountAvailableInContract, even if contract has more tama.
     * @param _tokenAmount Amount of tama tokens to withdraw.
     */
    function withdrawTamaTokensFromUserStakes(uint256 _tokenAmount) external onlyOwner {
        // currentStakedAmountAvailableInContract must be equal/greater than amount being withdrawn.
        require(
            currentStakedAmountAvailableInContract >= _tokenAmount,
            "Insufficient staked balance."
        );

        // Decrement currentStakedAmountAvailableInContract storage variable value.
        currentStakedAmountAvailableInContract -= _tokenAmount;

        // Emit the event.
        emit TamaTokensWithdrawnFromUserStakes(
            msg.sender,
            _tokenAmount,
            block.timestamp
        );

        // Transfer tama tokens to msg.sender
        require(
            tamaToken.transfer(msg.sender, _tokenAmount),
            "Error while transferring tama."
        );
    }


    /**
     * @notice Function for contract owner to deposit back tama that was withdrawn from user stakes.
     * @dev Increases value of currentStakedAmountAvailableInContract by _tokenAmount, if resultant value <= totalStakedAmountInContract.
     * @param _tokenAmount Amount to tama tokens to deposit back.
     */
    function depositTamaTokensBackToUserStakes(uint256 _tokenAmount) external onlyOwner {
        // currentStakedAmountAvailableInContract + _tokenAmount should be <= totalStakedAmountInContract
        require(
            currentStakedAmountAvailableInContract + _tokenAmount <= totalStakedAmountInContract,
            "Excessive deposit amount"
        );

        // Increment currentStakedAmountAvailableInContract storage variable value.
        currentStakedAmountAvailableInContract += _tokenAmount;

        // Emit the event.
        emit TamaTokensDepositedToUserStakes(
            msg.sender,
            _tokenAmount,
            block.timestamp
        );

        // Transfer tama tokens from msg.sender to this contract.
        require(
            tamaToken.transferFrom(msg.sender, address(this), _tokenAmount),
            "Error while transferring tama."
        );
    }


    /**
     * @notice Batch function for owner/admin to activate multiple arcade credit buy plans at once.
     * @param _planIds An array of plan ids to be activated.
     */
    function batchActivateArcadeCreditBuyPlans(uint256[] memory _planIds) external onlyAdminOrOwner {
        for(uint256 i=0; i<_planIds.length; i++) {

            uint256 planId = _planIds[i];
            // Plan id should be valid.
            require(
                planId != 0 && planId <= arcadeCreditBuyPlansAvailable,
                "Invalid plan id."
            );

            // Activate the plan id.
            arcadeCreditBuyPlans[planId].isActive = true;
        }

        emit ActivatedArcadeCreditBuyPlans(
            msg.sender,
            _planIds,
            block.timestamp
        );
    }


    /**
     * @notice Batch function for owner/admin to deactivate multiple arcade credit buy plans at once.
     * @param _planIds An array of plan ids to be deactivated.
     */
    function batchDeactivateArcadeCreditBuyPlans(uint256[] memory _planIds) external onlyAdminOrOwner {
        for(uint256 i=0; i<_planIds.length; i++) {

            uint256 planId = _planIds[i];
            // Plan id should be valid.
            require(
                planId != 0 && planId <= arcadeCreditBuyPlansAvailable,
                "Invalid plan id."
            );

            // Deactivate the plan id.
            arcadeCreditBuyPlans[planId].isActive = false;
        }

        emit DeactivatedArcadeCreditBuyPlans(
            msg.sender,
            _planIds,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner/admin to update an existing arcade credit buy plan.
     * @param _planId Id of the arcade credit buy plan to be updated.
     * @param _arcadeCredits New value of arcade credits for this plan.
     * @param _tamaRequired New value of tama required for this plan.
     */
    function updateArcadeCreditBuyPlan(uint256 _planId, uint256 _arcadeCredits, uint256 _tamaRequired) external onlyAdminOrOwner {
        // _planId should be valid.
        require(
            _planId != 0 && _planId <= arcadeCreditBuyPlansAvailable,
            "Invalid plan id."
        );
        
        // _arcadeCredits and _tamaRequired values must be greater than 0.
        require(_arcadeCredits > 0 && _tamaRequired > 0, "Cannot be zero.");
        
        // _tamaRequired should be >= (_arcadeCredits * tamaPerCreditToSendToRewardPool)
        require(
            _arcadeCredits * tamaPerCreditToSendToRewardPool <= _tamaRequired,
            "arcadeCredits * tamaPerCredit is greater than tama required."
        );
        // Read the plan from storage.
        ArcadeCreditBuyPlan storage plan = arcadeCreditBuyPlans[_planId];

        // Update the plan.
        plan.arcadeCredits = _arcadeCredits;
        plan.tamaRequired = _tamaRequired;

        emit UpdatedArcadeCreditBuyPlan(
            msg.sender,
            _planId,
            _arcadeCredits,
            _tamaRequired,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner/admin to add new arcade credit buy plans.
     * @param _arcadeCreditBuyPlans New arcade credit buy plans to be added.
     */
    function addNewArcadeCreditBuyPlans(ArcadeCreditBuyPlan[] memory _arcadeCreditBuyPlans)
        public
        onlyAdminOrOwner
    {
        uint256 tamaPerCredit = tamaPerCreditToSendToRewardPool;
        uint256 totalPlans = arcadeCreditBuyPlansAvailable;

        for(uint256 i=0; i<_arcadeCreditBuyPlans.length; i++) {
            require(
                _arcadeCreditBuyPlans[i].arcadeCredits > 0,
                "Arcade credits for plan cannot be 0."
            );
            require(
                _arcadeCreditBuyPlans[i].tamaRequired > 0,
                "Tama required for plan cannot be 0."
            );
            require(
                _arcadeCreditBuyPlans[i].arcadeCredits * tamaPerCredit <= _arcadeCreditBuyPlans[i].tamaRequired,
                "arcadeCredits * tamaPerCredit is greater than tama required."
            );

            // Increment local variable for total plans count, and store the new plan in storage.
            totalPlans += 1;
            arcadeCreditBuyPlans[totalPlans] = _arcadeCreditBuyPlans[i];

            emit AddedNewArcadeCreditBuyPlan(
                msg.sender,
                totalPlans,
                _arcadeCreditBuyPlans[i].arcadeCredits,
                _arcadeCreditBuyPlans[i].tamaRequired,
                _arcadeCreditBuyPlans[i].isActive,
                block.timestamp
            );
        }

        // Set arcadeCreditBuyPlansAvailable equal to totalPlans.
        arcadeCreditBuyPlansAvailable = totalPlans;
    }


    /**
     * @notice Batch function for owner/admin to activate multiple tama stake plans at once.
     * @param _planIds An array of plan ids to be activated.
     */
    function batchActivateTamaStakePlans(uint256[] memory _planIds) external onlyAdminOrOwner {
        for(uint256 i=0; i<_planIds.length; i++) {
            
            uint256 planId = _planIds[i];
            // planId should be valid.
            require(
                planId != 0 && planId <= tamaStakePlansAvailable,
                "Invalid plan id."
            );

            // Activate the plan id.
            tamaStakePlans[planId].isActive = true;
        }

        emit ActivatedTamaStakePlans(
            msg.sender,
            _planIds,
            block.timestamp
        );
    }


    /**
     * @notice Batch function for owner/admin to deactivate multiple tama stake plans at once.
     * @param _planIds An array of plan ids to be deactivated.
     */
    function batchDeactivateTamaStakePlans(uint256[] memory _planIds) external onlyAdminOrOwner {
        for(uint256 i=0; i<_planIds.length; i++) {
            
            uint256 planId = _planIds[i];
            // planId should be valid.
            require(
                planId != 0 && planId <= tamaStakePlansAvailable,
                "Invalid plan id."
            );

            // Deactivate the plan id.
            tamaStakePlans[planId].isActive = false;
        }

        emit DeactivatedTamaStakePlans(
            msg.sender,
            _planIds,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner/admin to update an existing tama stake plan.
     * @param _planId Id of the tama stake plan to be updated.
     * @param _stakeDurationInSeconds New value of time for which tokens will be staked/locked for this plan.
     */
    function updateTamaStakePlan(uint256 _planId, uint256 _stakeDurationInSeconds) external onlyAdminOrOwner {
        // _planId should be valid.
        require(
            _planId != 0 && _planId <= tamaStakePlansAvailable,
            "Invalid plan id."
        );

        // _stakeDurationInSeconds must be greater than 0.
        require(_stakeDurationInSeconds > 0, "Stake duration cannot be zero.");

        // Update the plan.
        tamaStakePlans[_planId].stakeDurationInSeconds = _stakeDurationInSeconds;

        emit UpdatedTamaStakePlan(
            msg.sender,
            _planId,
            _stakeDurationInSeconds,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner/admin to add new tama stake plans.
     * @param _tamaStakePlans New tama stake plans to be added.
     */
    function addNewTamaStakePlans(TamaStakePlan[] memory _tamaStakePlans) public onlyAdminOrOwner {
        uint256 totalPlans = tamaStakePlansAvailable;

        for(uint256 i=0; i<_tamaStakePlans.length; i++) {
            require(
                _tamaStakePlans[i].stakeDurationInSeconds > 0,
                "Stake duration cannot be 0."
            );
            totalPlans += 1;
            tamaStakePlans[totalPlans] = _tamaStakePlans[i];
            emit AddedNewTamaStakePlan(
                msg.sender,
                totalPlans,
                _tamaStakePlans[i].stakeDurationInSeconds,
                _tamaStakePlans[i].isActive,
                block.timestamp
            );
        }
        // Set the value of tamaStakePlansAvailable equal to totalPlans.
        tamaStakePlansAvailable = totalPlans;
    }


    /**
     * @notice Function for owner/admin to payout tama tokens to leaderboard winners from p2eRewardPoolBalance.
     * @dev p2eRewardPoolBalance must have sufficient tama to carry out all transfers.
     * @param _addresses An array of addresses to be given the tama payout.
     * @param _amounts An array of tama token amounts to be given as payout to respective address from _addresses array.
     */
    function payoutTama(address[] memory _addresses, uint256[] memory _amounts) external onlyAdminOrOwner {
        require(_addresses.length == _amounts.length, "Array length mismatch.");
        uint256 totalTamaPaid;

        for(uint i=0; i<_addresses.length; i++) {
            totalTamaPaid += _amounts[i];
            require(
                tamaToken.transfer(_addresses[i], _amounts[i]),
                "Error while transferring tama."
            );
        }

        require(
            totalTamaPaid <= p2eRewardPoolBalance,
            "Insufficient tama in p2eRewardPoolBalance"
        );

        // Decrement p2e reward pool balance.
        p2eRewardPoolBalance -= totalTamaPaid;

        emit TamaPayoutFromP2eRewardPool(
            msg.sender,
            _addresses,
            _amounts,
            p2eRewardPoolBalance,
            block.timestamp
        );
    }


    /**
     * @notice Function to claim tama tokens from p2eRewardPool with admin signature.
     */
    function claimTamaRewards(TamaRewardClaim memory _data, bytes memory _signature) external {
        require(
            !isSignatureUsed[_signature],
            "Already claimed!"
        );
        require(
            msg.sender == _data.receiver,
            "Not the receiver!"
        );
        require(
            _data.claimNumber == ++totalTamaClaims[_data.receiver],
            "Invalid claim number!"
        );
        require(
            p2eRewardPoolBalance >= _data.tamaAmount,
            "Insufficient p2e reward pool balance!"
        );
        require(
            _verifySignature(_data, _signature),
            "Invalid signature!"
        );

        isSignatureUsed[_signature] = true;
        p2eRewardPoolBalance -= _data.tamaAmount;
        require(
            tamaToken.transfer(msg.sender, _data.tamaAmount),
            "Error while transferring tama."
        );

        emit TamaRewardClaimed(
            msg.sender,
            _data.tamaAmount,
            _data.claimNumber,
            _signature,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner/admin to change the tama per credit to be sent to p2e reward pool when arcade credits are bought.
     * @param _tamaPerCreditToSendToRewardPool New value for tamaPerCreditToSendToRewardPool, cannot be zero.
     */
    function updateTamaPerCreditToSendToRewardPool(uint256 _tamaPerCreditToSendToRewardPool) external onlyAdminOrOwner {
        require(
            _tamaPerCreditToSendToRewardPool != 0,
            "Cannot be zero."
        );
        tamaPerCreditToSendToRewardPool = _tamaPerCreditToSendToRewardPool;
        emit UpdatedTamaPerCreditToRewardPool(
            msg.sender,
            _tamaPerCreditToSendToRewardPool,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner/admin to change the tama token distribution percentages when arcade credits are bought.
     */
    function updateTamaDistributionPercentages(
        uint256 _tamaPercentageToSendToStakingRewardPool,
        uint256 _tamaPercentageToBurn
    ) external onlyAdminOrOwner {
        require(
            _tamaPercentageToBurn + _tamaPercentageToSendToStakingRewardPool == 10000,
            "Burn and Staking reward pool percentage sum should be 10000."
        );
        tamaPercentageToSendToStakingRewardPool = _tamaPercentageToSendToStakingRewardPool;
        tamaPercentageToBurn = _tamaPercentageToBurn;

        emit UpdatedTamaDistributionPercentages(
            msg.sender,
            _tamaPercentageToBurn,
            _tamaPercentageToSendToStakingRewardPool,
            block.timestamp
        );
    }


    /**
     * @notice Function for owner/admin to publish the IPFS result hash onchain for a gameId.
     * @param _gameId Id of the game for which result is being published.
     * @param _result String with IPFS result hash of the game.
     */
    function publishIpfsResult(uint256 _gameId, string memory _result) external onlyAdminOrOwner {
        // Result should not be declared already for this id.
        require(
            bytes(gameResults[_gameId]).length == 0,
            "Result already declared for this game id."
        );

        // Result string passed should not be empty.
        require(
            bytes(_result).length != 0,
            "Empty string."
        );

        // Store the result in gameResults mapping.
        gameResults[_gameId] = _result;

        emit GameResultPublished(
            msg.sender,
            _gameId,
            _result,
            block.timestamp
        );
    }


    /**
     * @notice Function to get total amount of tama currently staked in contract by an address.
     * @param _address Address for which to get the amount of tama staked.
     */
    function getTotalTamaStaked(address _address) external view returns(uint256) {
        return stakes[_address].totalAmountStaked;
    }


    /**
     * @notice Function to get total no of tama stakes ever done by an address in this contract.
     * @param _address Address for which to get the number of tama stakes done..
     */
    function getTotalStakes(address _address) external view returns(uint256) {
        return stakes[_address].totalStakes;
    }


    /**
     * @notice Function to get info of a particular stake id for an address.
     * @param _address Address of user for whom to get the stake info.
     * @param _stakeId Id of the stake whose info to get.
     */
    function getStake(address _address, uint256 _stakeId) external view returns(TamaStake memory) {
        return stakes[_address].tamaStakes[_stakeId];
    }


    /**
     * @notice Function to get info of all stakes for an address.
     * @param _address Address for which to get stake info.
     */
    function getAllStakes(address _address) external view returns(TamaStake[] memory) {
        UserStakes storage userStakesInfo = stakes[_address];

        uint256 totalUserStakes = userStakesInfo.totalStakes;
        TamaStake[] memory allStakes = new TamaStake[](totalUserStakes);

        for(uint256 i=0; i<userStakesInfo.totalStakes; i++) {
            allStakes[i] = userStakesInfo.tamaStakes[i+1];
        }

        return allStakes;
    }


    /**
     * @notice Function to get the total no of active stakes for an address.
     * @param _address Address for whom to get the total active stakes.
     */
    function getTotalActiveStakes(address _address) public view returns(uint256) {
        UserStakes storage userStakesInfo = stakes[_address];
        uint256 totalUserStakes = userStakesInfo.totalStakes;

        uint256 totalActiveStakes = 0;
        for(uint256 i=1; i<=totalUserStakes; i++) {
            if (
                userStakesInfo.tamaStakes[i].stakeTime + 
                    tamaStakePlans[userStakesInfo.tamaStakes[i].tamaStakePlanId].stakeDurationInSeconds >
                        block.timestamp
            ) {
                totalActiveStakes += 1;
            }
        }
        return totalActiveStakes;
    }


    /**
     * @notice Function to get info about the active tama stakes for an address.
     * @param _address Address of user for whom to return the all active stakes.
     */
    function getAllActiveStakes(address _address) external view returns(TamaStake[] memory) {
        uint256 totalActiveStakes = getTotalActiveStakes(_address);

        UserStakes storage userStakesInfo = stakes[_address];
        TamaStake[] memory activeStakes = new TamaStake[](totalActiveStakes);
        uint256 index = 0;

        for(uint256 i=1; i<=userStakesInfo.totalStakes; i++) {
            if(
                userStakesInfo.tamaStakes[i].stakeTime +
                    tamaStakePlans[userStakesInfo.tamaStakes[i].tamaStakePlanId].stakeDurationInSeconds >
                        block.timestamp
            ) {
                activeStakes[index] = userStakesInfo.tamaStakes[i];
                index += 1;
            }
        }

        return activeStakes;
    }


    /**
     * @notice Returns details of all the arcade credit buy plans available.
     */
    function getAllArcadeCreditBuyPlans() external view returns(ArcadeCreditBuyPlan[] memory) {
        uint256 totalPlans = arcadeCreditBuyPlansAvailable;
        ArcadeCreditBuyPlan[] memory plans = new ArcadeCreditBuyPlan[](totalPlans);

        for(uint256 i=0; i<totalPlans; i++) {
            plans[i] = arcadeCreditBuyPlans[i+1];
        }
        return plans;
    }


    /**
     * @notice Returns details of all the tama stake plans available.
     */
    function getAllTamaStakePlans() external view returns(TamaStakePlan[] memory) {
        uint256 totalPlans = tamaStakePlansAvailable;
        TamaStakePlan[] memory plans = new TamaStakePlan[](totalPlans);

        for(uint256 i=0; i<totalPlans; i++) {
            plans[i] = tamaStakePlans[i+1];
        }
        return plans;
    }


    // ----------------------------EIP-712 functions.------------------------------------------------------------------
    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }


    /**
     * @dev Verifies the given signature. Signer should have DEFAULT_ADMIN_ROLE.
     * @param _data Tuple for TamaRewardClaim struct input.
     * @param _signature The signature to verify.
     * @return Boolean, true if signature is valid & signer has DEFAULT_ADMIN_ROLE, otherwise false.
     */
    function _verifySignature(TamaRewardClaim memory _data, bytes memory _signature) private view returns(bool) {
        bytes32 digest = _getDigest(_data);
        address signer = _getSigner(digest, _signature);

        // Check if signer has DEFAULT_ADMIN_ROLE.
        return hasRole(DEFAULT_ADMIN_ROLE, signer);
    }

    function _getDigest(TamaRewardClaim memory _data) private view returns(bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(
                _TAMA_REWARD_CLAIM_TYPEHASH,
                _data.receiver,
                _data.tamaAmount,
                _data.claimNumber
            ))
        );
    }

    function _getSigner(bytes32 _digest, bytes memory _signature) private pure returns(address) {
        return ECDSAUpgradeable.recover(_digest, _signature);
    }

}