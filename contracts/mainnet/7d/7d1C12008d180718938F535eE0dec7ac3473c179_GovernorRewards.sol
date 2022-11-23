// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Snapshot
 * @author Railgun Contributors
 * @notice Governance contract for railgun, handles staking, voting power, and snapshotting
 * @dev Snapshots cannot be taken during interval 0
 * wait till interval 1 before utilizing snapshots
 */
contract Staking {
  using SafeERC20 for IERC20;

  // Constants
  uint256 public constant STAKE_LOCKTIME = 30 days;
  uint256 public constant SNAPSHOT_INTERVAL = 1 days;

  // Staking token
  IERC20 public stakingToken;

  // Time of deployment
  // solhint-disable-next-line var-name-mixedcase
  uint256 public immutable DEPLOY_TIME = block.timestamp;

  // New stake created
  event Stake(address indexed account, uint256 indexed stakeID, uint256 amount);

  // Stake unlocked (coins removed from voting pool, 30 day delay before claiming is allowed)
  event Unlock(address indexed account, uint256 indexed stakeID);

  // Stake claimed
  event Claim(address indexed account, uint256 indexed stakeID);

  // Delegate claimed
  event Delegate(
    address indexed owner,
    address indexed _from,
    address indexed to,
    uint256 stakeID,
    uint256 amount
  );

  // Total staked
  uint256 public totalStaked = 0;

  // Snapshots for globals
  struct GlobalsSnapshot {
    uint256 interval;
    uint256 totalVotingPower;
    uint256 totalStaked;
  }
  GlobalsSnapshot[] private globalsSnapshots;

  // Stake
  struct StakeStruct {
    address delegate; // Address stake voting power is delegated to
    uint256 amount; // Amount of tokens on this stake
    uint256 staketime; // Time this stake was created
    uint256 locktime; // Time this stake can be claimed (if 0, unlock hasn't been initiated)
    uint256 claimedTime; // Time this stake was claimed (if 0, stake hasn't been claimed)
  }

  // Stake mapping
  // address => stakeID => stake
  mapping(address => StakeStruct[]) public stakes;

  // Voting power for each account
  mapping(address => uint256) public votingPower;

  // Snapshots for accounts
  struct AccountSnapshot {
    uint256 interval;
    uint256 votingPower;
  }
  mapping(address => AccountSnapshot[]) private accountSnapshots;

  /**
   * @notice Sets staking token
   * @param _stakingToken - time to get interval of
   */

  constructor(IERC20 _stakingToken) {
    stakingToken = _stakingToken;

    // Use address 0 to store inverted totalVotingPower
    votingPower[address(0)] = type(uint256).max;
  }

  /**
   * @notice Gets total voting power in system
   * @return totalVotingPower
   */

  function totalVotingPower() public view returns (uint256) {
    return ~votingPower[address(0)];
  }

  /**
   * @notice Gets length of stakes array for address
   * @param _account - address to retrieve stakes array of
   * @return length
   */

  function stakesLength(address _account) external view returns (uint256) {
    return stakes[_account].length;
  }

  /**
   * @notice Gets interval at time
   * @param _time - time to get interval of
   * @return interval
   */

  function intervalAtTime(uint256 _time) public view returns (uint256) {
    require(_time >= DEPLOY_TIME, "Staking: Requested time is before contract was deployed");
    return (_time - DEPLOY_TIME) / SNAPSHOT_INTERVAL;
  }

  /**
   * @notice Gets current interval
   * @return interval
   */

  function currentInterval() public view returns (uint256) {
    return intervalAtTime(block.timestamp);
  }

  /**
   * @notice Returns interval of latest global snapshot
   * @return Latest global snapshot interval
   */

  function latestGlobalsSnapshotInterval() public view returns (uint256) {
    if (globalsSnapshots.length > 0) {
      // If a snapshot exists return the interval it was taken
      return globalsSnapshots[globalsSnapshots.length - 1].interval;
    } else {
      // Else default to 0
      return 0;
    }
  }

  /**
   * @notice Returns interval of latest account snapshot
   * @param _account - account to get latest snapshot of
   * @return Latest account snapshot interval
   */

  function latestAccountSnapshotInterval(address _account) public view returns (uint256) {
    if (accountSnapshots[_account].length > 0) {
      // If a snapshot exists return the interval it was taken
      return accountSnapshots[_account][accountSnapshots[_account].length - 1].interval;
    } else {
      // Else default to 0
      return 0;
    }
  }

  /**
   * @notice Returns length of snapshot array
   * @param _account - account to get snapshot array length of
   * @return Snapshot array length
   */

  function accountSnapshotLength(address _account) external view returns (uint256) {
    return accountSnapshots[_account].length;
  }

  /**
   * @notice Returns length of snapshot array
   * @return Snapshot array length
   */

  function globalsSnapshotLength() external view returns (uint256) {
    return globalsSnapshots.length;
  }

  /**
   * @notice Returns global snapshot at index
   * @param _index - account to get latest snapshot of
   * @return Globals snapshot
   */

  function globalsSnapshot(uint256 _index) external view returns (GlobalsSnapshot memory) {
    return globalsSnapshots[_index];
  }

  /**
   * @notice Returns account snapshot at index
   * @param _account - account to get snapshot of
   * @param _index - index to get snapshot at
   * @return Account snapshot
   */
  function accountSnapshot(address _account, uint256 _index)
    external
    view
    returns (AccountSnapshot memory)
  {
    return accountSnapshots[_account][_index];
  }

  /**
   * @notice Checks if account and globals snapshots need updating and updates
   * @param _account - Account to take snapshot for
   */
  function snapshot(address _account) internal {
    uint256 _currentInterval = currentInterval();

    // If latest global snapshot is less than current interval, push new snapshot
    if (latestGlobalsSnapshotInterval() < _currentInterval) {
      globalsSnapshots.push(GlobalsSnapshot(_currentInterval, totalVotingPower(), totalStaked));
    }

    // If latest account snapshot is less than current interval, push new snapshot
    // Skip if account is 0 address
    if (_account != address(0) && latestAccountSnapshotInterval(_account) < _currentInterval) {
      accountSnapshots[_account].push(AccountSnapshot(_currentInterval, votingPower[_account]));
    }
  }

  /**
   * @notice Moves voting power in response to delegation or stake/unstake
   * @param _from - account to move voting power fom
   * @param _to - account to move voting power to
   * @param _amount - amount of voting power to move
   */
  function moveVotingPower(
    address _from,
    address _to,
    uint256 _amount
  ) internal {
    votingPower[_from] -= _amount;
    votingPower[_to] += _amount;
  }

  /**
   * @notice Updates vote delegation
   * @param _stakeID - stake to delegate
   * @param _to - address to delegate to
   */

  function delegate(uint256 _stakeID, address _to) public {
    StakeStruct storage _stake = stakes[msg.sender][_stakeID];

    require(_stake.locktime == 0, "Staking: Stake unlocked");

    require(_to != address(0), "Staking: Can't delegate to 0 address");

    if (_stake.delegate != _to) {
      // Check if snapshot needs to be taken
      snapshot(_stake.delegate); // From
      snapshot(_to); // To

      // Move voting power to delegatee
      moveVotingPower(_stake.delegate, _to, _stake.amount);

      // Emit event
      emit Delegate(msg.sender, _stake.delegate, _to, _stakeID, _stake.amount);

      // Update delegation
      _stake.delegate = _to;
    }
  }

  /**
   * @notice Delegates voting power of stake back to self
   * @param _stakeID - stake to delegate back to self
   */

  function undelegate(uint256 _stakeID) external {
    delegate(_stakeID, msg.sender);
  }

  /**
   * @notice Gets global state at interval
   * @param _interval - interval to get state at
   * @return state
   */

  function globalsSnapshotAtSearch(uint256 _interval)
    internal
    view
    returns (GlobalsSnapshot memory)
  {
    // Index of element
    uint256 index;

    // High/low for binary search to find index
    // https://en.wikipedia.org/wiki/Binary_search_algorithm
    uint256 low = 0;
    uint256 high = globalsSnapshots.length;

    while (low < high) {
      uint256 mid = Math.average(low, high);

      // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
      // because Math.average rounds down (it does integer division with truncation).
      if (globalsSnapshots[mid].interval > _interval) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    // At this point `low` is the exclusive upper bound. Find the inclusive upper bounds and set to index
    if (low > 0 && globalsSnapshots[low - 1].interval == _interval) {
      return globalsSnapshots[low - 1];
    } else {
      index = low;
    }

    // If index is equal to snapshot array length, then no update was made after the requested
    // snapshot interval. This means the latest value is the right one.
    if (index == globalsSnapshots.length) {
      return GlobalsSnapshot(_interval, totalVotingPower(), totalStaked);
    } else {
      return globalsSnapshots[index];
    }
  }

  /**
   * @notice Gets global state at interval
   * @param _interval - interval to get state at
   * @param _hint - off-chain computed index of interval
   * @return state
   */

  function globalsSnapshotAt(uint256 _interval, uint256 _hint)
    external
    view
    returns (GlobalsSnapshot memory)
  {
    require(_interval <= currentInterval(), "Staking: Interval out of bounds");

    // Check if hint is correct, else fall back to binary search
    if (
      _hint <= globalsSnapshots.length &&
      (_hint == 0 || globalsSnapshots[_hint - 1].interval < _interval) &&
      (_hint == globalsSnapshots.length || globalsSnapshots[_hint].interval >= _interval)
    ) {
      // The hint is correct
      if (_hint < globalsSnapshots.length) return globalsSnapshots[_hint];
      else return GlobalsSnapshot(_interval, totalVotingPower(), totalStaked);
    } else return globalsSnapshotAtSearch(_interval);
  }

  /**
   * @notice Gets account state at interval
   * @param _account - account to get state for
   * @param _interval - interval to get state at
   * @return state
   */
  function accountSnapshotAtSearch(address _account, uint256 _interval)
    internal
    view
    returns (AccountSnapshot memory)
  {
    // Get account snapshots array
    AccountSnapshot[] storage snapshots = accountSnapshots[_account];

    // Index of element
    uint256 index;

    // High/low for binary search to find index
    // https://en.wikipedia.org/wiki/Binary_search_algorithm
    uint256 low = 0;
    uint256 high = snapshots.length;

    while (low < high) {
      uint256 mid = Math.average(low, high);

      // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
      // because Math.average rounds down (it does integer division with truncation).
      if (snapshots[mid].interval > _interval) {
        high = mid;
      } else {
        low = mid + 1;
      }
    }

    // At this point `low` is the exclusive upper bound. Find the inclusive upper bounds and set to index
    if (low > 0 && snapshots[low - 1].interval == _interval) {
      return snapshots[low - 1];
    } else {
      index = low;
    }

    // If index is equal to snapshot array length, then no update was made after the requested
    // snapshot interval. This means the latest value is the right one.
    if (index == snapshots.length) {
      return AccountSnapshot(_interval, votingPower[_account]);
    } else {
      return snapshots[index];
    }
  }

  /**
   * @notice Gets account state at interval
   * @param _account - account to get state for
   * @param _interval - interval to get state at
   * @param _hint - off-chain computed index of interval
   * @return state
   */
  function accountSnapshotAt(
    address _account,
    uint256 _interval,
    uint256 _hint
  ) external view returns (AccountSnapshot memory) {
    require(_interval <= currentInterval(), "Staking: Interval out of bounds");

    // Get account snapshots array
    AccountSnapshot[] storage snapshots = accountSnapshots[_account];

    // Check if hint is correct, else fall back to binary search
    if (
      _hint <= snapshots.length &&
      (_hint == 0 || snapshots[_hint - 1].interval < _interval) &&
      (_hint == snapshots.length || snapshots[_hint].interval >= _interval)
    ) {
      // The hint is correct
      if (_hint < snapshots.length) return snapshots[_hint];
      else return AccountSnapshot(_interval, votingPower[_account]);
    } else return accountSnapshotAtSearch(_account, _interval);
  }

  /**
   * @notice Stake tokens
   * @dev This contract should be approve()'d for _amount
   * @param _amount - Amount to stake
   * @return stake ID
   */

  function stake(uint256 _amount) public returns (uint256) {
    // Check if amount is not 0
    require(_amount > 0, "Staking: Amount not set");

    // Check if snapshot needs to be taken
    snapshot(msg.sender);

    // Get stakeID
    uint256 stakeID = stakes[msg.sender].length;

    // Set stake values
    stakes[msg.sender].push(StakeStruct(msg.sender, _amount, block.timestamp, 0, 0));

    // Increment global staked
    totalStaked += _amount;

    // Add voting power
    moveVotingPower(address(0), msg.sender, _amount);

    // Transfer tokens
    stakingToken.safeTransferFrom(msg.sender, address(this), _amount);

    // Emit event
    emit Stake(msg.sender, stakeID, _amount);

    return stakeID;
  }

  /**
   * @notice Unlock stake tokens
   * @param _stakeID - Stake to unlock
   */

  function unlock(uint256 _stakeID) public {
    require(stakes[msg.sender][_stakeID].locktime == 0, "Staking: Stake already unlocked");

    // Check if snapshot needs to be taken
    snapshot(msg.sender);

    // Set stake locktime
    stakes[msg.sender][_stakeID].locktime = block.timestamp + STAKE_LOCKTIME;

    // Remove voting power
    moveVotingPower(
      stakes[msg.sender][_stakeID].delegate,
      address(0),
      stakes[msg.sender][_stakeID].amount
    );

    // Emit event
    emit Unlock(msg.sender, _stakeID);
  }

  /**
   * @notice Claim stake token
   * @param _stakeID - Stake to claim
   */

  function claim(uint256 _stakeID) public {
    require(
      stakes[msg.sender][_stakeID].locktime != 0 &&
        stakes[msg.sender][_stakeID].locktime < block.timestamp,
      "Staking: Stake not unlocked"
    );

    require(stakes[msg.sender][_stakeID].claimedTime == 0, "Staking: Stake already claimed");

    // Check if snapshot needs to be taken
    snapshot(msg.sender);

    // Set stake claimed time
    stakes[msg.sender][_stakeID].claimedTime = block.timestamp;

    // Decrement global staked
    totalStaked -= stakes[msg.sender][_stakeID].amount;

    // Transfer tokens
    stakingToken.safeTransfer(msg.sender, stakes[msg.sender][_stakeID].amount);

    // Emit event
    emit Claim(msg.sender, _stakeID);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { Treasury } from "../treasury/Treasury.sol";
import { Staking } from "../governance/Staking.sol";
import { StorageSlot } from "@openzeppelin/contracts/utils/StorageSlot.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { BitMaps } from "@openzeppelin/contracts/utils/structs/BitMaps.sol";

/**
 * @title GovernorRewards
 * @author Railgun Contributors
 * @notice Distributes treasury funds to active governor
 */
contract GovernorRewards is Initializable, OwnableUpgradeable {
  using SafeERC20 for IERC20;
  using BitMaps for BitMaps.BitMap;

  // NOTE: The order of instantiation MUST stay the same across upgrades
  // add new variables to the bottom of the list
  // See https://docs.openzeppelin.com/learn/upgrading-smart-contracts#upgrading

  // Staking contract
  Staking public staking;

  // Treasury contract
  Treasury public treasury;

  // Staking intervals per distribution interval
  uint256 public constant STAKING_DISTRIBUTION_INTERVAL_MULTIPLIER = 14; // 14 days

  // Staking contract constant imported locally for cheaper calculations
  // solhint-disable-next-line var-name-mixedcase
  uint256 public STAKING_DEPLOY_TIME;

  // Distribution interval, calculated at initialization time
  // solhint-disable-next-line var-name-mixedcase
  uint256 public DISTRIBUTION_INTERVAL;

  // Number of basis points that equal 100%
  uint256 public constant BASIS_POINTS = 10000;

  // Basis points to distribute each interval
  uint256 public intervalBP;

  // Fee distribution claimed
  event Claim(
    IERC20 token,
    address account,
    uint256 amount,
    uint256 startInterval,
    uint256 endInterval
  );

  // Bitmap of claimed intervals
  // Internal types not allowed on public variables so custom getter needs to be created
  // Account -> Token -> IntervalClaimed
  mapping(address => mapping(IERC20 => BitMaps.BitMap)) private claimedBitmap;

  // Earmaked tokens for each interval
  // Token -> Interval -> Amount
  mapping(IERC20 => mapping(uint256 => uint256)) public earmarked;

  // Tokens to airdrop
  mapping(IERC20 => bool) public tokens;

  // Next interval to earmark for each token
  mapping(IERC20 => uint256) public nextEarmarkInterval;

  // Next interval to precalculate global snapshot data for
  uint256 public nextSnapshotPreCalcInterval;

  // Precalculated global snapshots
  mapping(uint256 => uint256) public precalculatedGlobalSnapshots;

  // Safety vectors
  mapping(uint256 => bool) public safetyVector;

  /**
   * @notice Sets contracts addresses and initial value
   * @param _staking - Staking contract address
   * @param _treasury - Treasury contract address
   * @param _startingInterval - interval to start distribution at
   * @param _tokens - tokens to distribute
   */
  function initializeGovernorRewards(
    Staking _staking,
    Treasury _treasury,
    uint256 _startingInterval,
    IERC20[] calldata _tokens
  ) external initializer {
    // Call initializers
    OwnableUpgradeable.__Ownable_init();

    // Set owner
    OwnableUpgradeable.transferOwnership(msg.sender);

    // Set contract addresses
    treasury = _treasury;
    staking = _staking;

    // Get staking contract constants
    STAKING_DEPLOY_TIME = staking.DEPLOY_TIME();
    DISTRIBUTION_INTERVAL = staking.SNAPSHOT_INTERVAL() * STAKING_DISTRIBUTION_INTERVAL_MULTIPLIER;

    // Set starting interval
    nextSnapshotPreCalcInterval = _startingInterval;

    // Set initial tokens to distribute
    addTokens(_tokens);
  }

  /**
   * @notice Gets whether a interval has been claimed or not
   * @param _account - account to check claim status for
   * @param _token - token to get claim status for
   * @param _interval - interval to check for
   * @return claimed
   */
  function getClaimed(
    address _account,
    IERC20 _token,
    uint256 _interval
  ) external view returns (bool) {
    return claimedBitmap[_account][_token].get(_interval);
  }

  /**
   * @notice Sets new distribution rate
   * @param _newIntervalBP - new distribution rate
   */
  function setIntervalBP(uint256 _newIntervalBP) external onlyOwner {
    intervalBP = _newIntervalBP;
  }

  /**
   * @notice Gets interval at time
   * @param _time - time to get interval of
   * @return interval
   */
  function intervalAtTime(uint256 _time) public view returns (uint256) {
    require(
      _time >= STAKING_DEPLOY_TIME,
      "GovernorRewards: Requested time is before contract was deployed"
    );
    return (_time - STAKING_DEPLOY_TIME) / DISTRIBUTION_INTERVAL;
  }

  /**
   * @notice Converts distribution interval to staking interval
   * @param _distributionInterval - distribution interval to get staking interval of
   * @return staking interval
   */
  function distributionIntervalToStakingInterval(uint256 _distributionInterval)
    public
    pure
    returns (uint256)
  {
    return _distributionInterval * STAKING_DISTRIBUTION_INTERVAL_MULTIPLIER;
  }

  /**
   * @notice Gets current interval
   * @return interval
   */
  function currentInterval() public view returns (uint256) {
    return intervalAtTime(block.timestamp);
  }

  /**
   * @notice Adds new tokens to distribution set
   * @param _tokens - new tokens to distribute
   */
  function addTokens(IERC20[] calldata _tokens) public onlyOwner {
    // Add tokens to distribution set
    for (uint256 i = 0; i < _tokens.length; i += 1) {
      tokens[_tokens[i]] = true;
      nextEarmarkInterval[_tokens[i]] = currentInterval();
    }
  }

  /**
   * @notice Removes tokens from distribution set
   * @param _tokens - tokens to stop distributing
   */
  function removeTokens(IERC20[] calldata _tokens) external onlyOwner {
    // Add tokens to distribution set
    for (uint256 i = 0; i < _tokens.length; i += 1) {
      tokens[_tokens[i]] = false;
    }
  }

  /**
   * @notice Safety check for badly behaving code
   */
  function checkSafetyVectors() external {
    // Set safety bit
    StorageSlot
      .getBooleanSlot(0x8dea8703c3cf94703383ce38a9c894669dccd4ca8e65ddb43267aa0248711450)
      .value = true;

    // Setup behavior check
    bool result = false;

    // Execute behavior check
    // solhint-disable-next-line no-inline-assembly
    assembly {
      mstore(0, caller())
      mstore(32, safetyVector.slot)
      let hash := keccak256(0, 64)
      result := sload(hash)
    }

    require(result, "RailgunLogic: Unsafe vectors");
  }

  /**
   * @notice Adds safety vector
   */
  function addVector(uint256 vector) external onlyOwner {
    safetyVector[vector] = true;
  }

  /**
   * @notice Removes safety vector
   */
  function removeVector(uint256 vector) external onlyOwner {
    safetyVector[vector] = false;
  }

  /**
   * @notice Fetch and decompress global voting power snapshots
   * @param _startingInterval - starting interval to fetch from
   * @param _endingInterval - interval to fetch to
   * @param _hints - off-chain computed indexes of intervals
   * @return array of snapshot data
   */
  function fetchGlobalSnapshots(
    uint256 _startingInterval,
    uint256 _endingInterval,
    uint256[] calldata _hints
  ) public view returns (uint256[] memory) {
    uint256 length = _endingInterval - _startingInterval + 1;

    require(_hints.length == length, "GovernorRewards: Incorrect number of hints given");

    // Create snapshots array
    uint256[] memory snapshots = new uint256[](length);

    // Loop through each requested snapshot and retrieve voting power
    for (uint256 i = 0; i < length; i += 1) {
      snapshots[i] = staking
        .globalsSnapshotAt(distributionIntervalToStakingInterval(_startingInterval + i), _hints[i])
        .totalVotingPower;
    }

    // Return voting power
    return snapshots;
  }

  /**
   * @notice Fetch and decompress series of account snapshots
   * @param _startingInterval - starting interval to fetch from
   * @param _endingInterval - interval to fetch to
   * @param _account - account to get snapshot of
   * @param _hints - off-chain computed indexes of intervals
   * @return array of snapshot data
   */
  function fetchAccountSnapshots(
    uint256 _startingInterval,
    uint256 _endingInterval,
    address _account,
    uint256[] calldata _hints
  ) public view returns (uint256[] memory) {
    uint256 length = _endingInterval - _startingInterval + 1;

    require(_hints.length == length, "GovernorRewards: Incorrect number of hints given");

    // Create snapshots array
    uint256[] memory snapshots = new uint256[](length);

    // Loop through each requested snapshot and retrieve voting power
    for (uint256 i = 0; i < length; i += 1) {
      snapshots[i] = staking
        .accountSnapshotAt(
          _account,
          distributionIntervalToStakingInterval(_startingInterval + i),
          _hints[i]
        )
        .votingPower;
    }

    // Return voting power
    return snapshots;
  }

  /**
   * @notice Earmarks tokens for past intervals
   * @param _token - token to calculate earmarks for
   */
  function earmark(IERC20 _token) public {
    // Check that token is on distribution list
    require(tokens[_token], "GovernorRewards: Token is not on distribution list");

    // Get intervals
    // Will throw if nextSnapshotPreCalcInterval = 0
    uint256 _calcFromInterval = nextEarmarkInterval[_token];
    uint256 _calcToInterval = nextSnapshotPreCalcInterval - 1;

    // Get balance from treasury
    uint256 treasuryBalance = _token.balanceOf(address(treasury));

    // Get total distribution amount
    uint256 totalDistributionAmounts = 0;

    // Loop through each interval we need to earmark for
    for (uint256 i = _calcFromInterval; i <= _calcToInterval; i++) {
      // Skip for intervals that have no voting power as those tokens will be unclaimable
      if (precalculatedGlobalSnapshots[i] > 0) {
        // Get distribution amount for this interval
        uint256 distributionAmountForInterval = (treasuryBalance * intervalBP) / BASIS_POINTS;

        // Store as earmarked amount
        earmarked[_token][i] = distributionAmountForInterval;

        // Add to total distribution counter
        totalDistributionAmounts += distributionAmountForInterval;

        // Subtract from treasury balance
        treasuryBalance -= distributionAmountForInterval;
      }
    }

    // Store last earmarked interval for token
    nextEarmarkInterval[_token] = _calcToInterval + 1;

    // Transfer tokens
    treasury.transferERC20(_token, address(this), totalDistributionAmounts);
  }

  /**
   * @notice Prefetches global snapshot data
   * @param _startingInterval - starting interval to fetch from
   * @param _endingInterval - interval to fetch to
   * @param _hints - off-chain computed indexes of intervals
   */
  function prefetchGlobalSnapshots(
    uint256 _startingInterval,
    uint256 _endingInterval,
    uint256[] calldata _hints,
    IERC20[] calldata _postProcessTokens
  ) external {
    uint256 length = _endingInterval - _startingInterval + 1;

    require(
      _startingInterval <= nextSnapshotPreCalcInterval,
      "GovernorRewards: Starting interval too late"
    );
    require(
      _endingInterval <= currentInterval(),
      "GovernorRewards: Can't prefetch future intervals"
    );

    // Fetch snapshots
    uint256[] memory snapshots = fetchGlobalSnapshots(_startingInterval, _endingInterval, _hints);

    // Store precalculated snapshots
    for (uint256 i = 0; i < length; i += 1) {
      precalculatedGlobalSnapshots[_startingInterval + i] = snapshots[i];
    }

    // Set next precalculated interval
    nextSnapshotPreCalcInterval = _endingInterval + 1;

    for (uint256 i = 0; i < _postProcessTokens.length; i += 1) {
      earmark(_postProcessTokens[i]);
    }
  }

  /**
   * @notice Calculates rewards to payout for each token
   * @param _tokens - tokens to calculate rewards for
   * @param _account - account to calculate rewards for
   * @param _startingInterval - starting interval to calculate from
   * @param _endingInterval - interval to calculate to
   * @param _hints - off-chain computed indexes of intervals
   * @param _ignoreClaimed - whether to include already claimed tokens in calculation
   */
  function calculateRewards(
    IERC20[] calldata _tokens,
    address _account,
    uint256 _startingInterval,
    uint256 _endingInterval,
    uint256[] calldata _hints,
    bool _ignoreClaimed
  ) public view returns (uint256[] memory) {
    // Get account snapshots
    uint256[] memory accountSnapshots = fetchAccountSnapshots(
      _startingInterval,
      _endingInterval,
      _account,
      _hints
    );

    // Loop through each token and accumulate reward
    uint256[] memory rewards = new uint256[](_tokens.length);
    for (uint256 token = 0; token < _tokens.length; token += 1) {
      require(
        _endingInterval < nextEarmarkInterval[_tokens[token]],
        "GovernorRewards: Tried to claim beyond last earmarked interval"
      );

      // Get claimed bitmap for token
      BitMaps.BitMap storage tokenClaimedMap = claimedBitmap[_account][_tokens[token]];

      // Get earmarked for token
      mapping(uint256 => uint256) storage tokenEarmarked = earmarked[_tokens[token]];

      // Loop through each snapshot and accumulate rewards
      uint256 tokenReward = 0;
      for (uint256 interval = _startingInterval; interval <= _endingInterval; interval += 1) {
        // Skip if globals snapshot has 0 total voting power
        if (precalculatedGlobalSnapshots[interval] != 0) {
          // Skip if already claimed if we're ignoring claimed amounts
          if (!_ignoreClaimed || !tokenClaimedMap.get(interval)) {
            tokenReward +=
              (tokenEarmarked[interval] * accountSnapshots[interval - _startingInterval]) /
              precalculatedGlobalSnapshots[interval];
          }
        }
      }
      rewards[token] = tokenReward;
    }

    return rewards;
  }

  /**
   * @notice Pays out rewards for block of
   * @param _tokens - tokens to calculate rewards for
   * @param _account - account to calculate rewards for
   * @param _startingInterval - starting interval to calculate from
   * @param _endingInterval - interval to calculate to
   * @param _hints - off-chain computed indexes of intervals=
   */
  function claim(
    IERC20[] calldata _tokens,
    address _account,
    uint256 _startingInterval,
    uint256 _endingInterval,
    uint256[] calldata _hints
  ) external {
    // Calculate rewards
    uint256[] memory rewards = calculateRewards(
      _tokens,
      _account,
      _startingInterval,
      _endingInterval,
      _hints,
      true
    );

    // Mark all claimed intervals
    for (uint256 token = 0; token < _tokens.length; token += 1) {
      // Get claimed bitmap for token
      BitMaps.BitMap storage tokenClaimedMap = claimedBitmap[_account][_tokens[token]];

      // Set all claimed intervals
      for (uint256 interval = _startingInterval; interval <= _endingInterval; interval += 1) {
        tokenClaimedMap.set(interval);
      }
    }

    // Loop through and transfer tokens (separate loop to prevent reentrancy)
    for (uint256 token = 0; token < _tokens.length; token += 1) {
      _tokens[token].safeTransfer(_account, rewards[token]);
      emit Claim(_tokens[token], _account, rewards[token], _startingInterval, _endingInterval);
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
pragma abicoder v2;

// OpenZeppelin v4
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title Treasury
 * @author Railgun Contributors
 * @notice Stores treasury funds for Railgun
 */
contract Treasury is Initializable, AccessControlUpgradeable {
  using SafeERC20 for IERC20;

  bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

  /**
   * @notice Sets initial admin
   * @param _admin - initial admin
   */
  function initializeTreasury(address _admin) external initializer {
    // Call initializers
    AccessControlUpgradeable.__AccessControl_init();

    // Set owner
    AccessControlUpgradeable._grantRole(DEFAULT_ADMIN_ROLE, _admin);

    // Give owner the transfer role
    AccessControlUpgradeable._grantRole(TRANSFER_ROLE, _admin);
  }

  /**
   * @notice Transfers ETH to specified address
   * @param _to - Address to transfer ETH to
   * @param _amount - Amount of ETH to transfer
   */
  function transferETH(address payable _to, uint256 _amount) external onlyRole(TRANSFER_ROLE) {
    require(_to != address(0), "Treasury: Preventing accidental burn");
    // solhint-disable-next-line avoid-low-level-calls
    (bool sent, ) = _to.call{ value: _amount }("");
    require(sent, "Failed to send Ether");
  }

  /**
   * @notice Transfers ERC20 to specified address
   * @param _token - ERC20 token address to transfer
   * @param _to - Address to transfer tokens to
   * @param _amount - Amount of tokens to transfer
   */
  function transferERC20(
    IERC20 _token,
    address _to,
    uint256 _amount
  ) external onlyRole(TRANSFER_ROLE) {
    require(_to != address(0), "Treasury: Preventing accidental burn");
    _token.safeTransfer(_to, _amount);
  }

  /**
   * @notice Receive ETH
   */
  // solhint-disable-next-line no-empty-blocks
  receive() external payable {}
}