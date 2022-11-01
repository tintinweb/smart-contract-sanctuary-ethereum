// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

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

/*
 ___  ___  ________   ___  ________  ___       ________  ________  ___  __       
|\  \|\  \|\   ___  \|\  \|\   __  \|\  \     |\   __  \|\   ____\|\  \|\  \     
\ \  \\\  \ \  \\ \  \ \  \ \  \|\ /\ \  \    \ \  \|\  \ \  \___|\ \  \/  /|_   
 \ \  \\\  \ \  \\ \  \ \  \ \   __  \ \  \    \ \  \\\  \ \  \    \ \   ___  \  
  \ \  \\\  \ \  \\ \  \ \  \ \  \|\  \ \  \____\ \  \\\  \ \  \____\ \  \\ \  \ 
   \ \_______\ \__\\ \__\ \__\ \_______\ \_______\ \_______\ \_______\ \__\\ \__\
    \|_______|\|__| \|__|\|__|\|_______|\|_______|\|_______|\|_______|\|__| \|__|
                                                                                 
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract UniblockERC20Presale is Initializable, AccessControl {
    /*********************************** Structs **********************************/

    struct ContractOptions {
        bool enableWhitelist;
    }

    struct TokenRate {
        uint256 presaleToken;
        uint256 paymentToken;
    }

    /********************************** Constants *********************************/

    bytes32 internal constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /************************************ Vars ************************************/

    uint256 public startTime;
    uint256 public endTime;
    uint256 public withdrawAfterTime;

    uint256 public supply;
    uint256 public currentSupply;

    uint256 public maxAmountPerBuyer;
    uint256 public minInvestment;
    address public tokenAddress;
    address public paymentReceiver;

    bool public presaleConfigured = false;

    mapping(address => TokenRate) paymentMethods;

    // Mapping of the amount of tokens that an address has purchased
    mapping(address => uint256) purchasedTokens;

    // Mapping of the amount of tokens that an address has left to withdraw
    mapping(address => uint256) claimableTokens;

    mapping(address => bool) whitelist;

    ContractOptions public contractOptions;

    /*********************************** Events ***********************************/

    // TODO: Add comments for events

    event Purchased(
        address indexed buyer,
        address indexed paymentToken,
        uint256 paymentAmount,
        uint256 amountPurchased
    );

    event PresaleConfigured(
        uint256 startTime,
        uint256 endTime,
        uint256 withdrawAfterTime,
        uint256 supply,
        uint256 maxAmountPerBuyer,
        uint256 minInvestment
    );

    event PaymentModified(
        address paymentAddress,
        uint256 presaleToken,
        uint256 paymentToken
    );

    event Withdraw(address indexed receiver, uint256 amount);

    event OwnerWithdraw(
        address indexed receiver,
        address indexed tokenAddress,
        uint256 amount
    );

    event AddedToWhitelist(address indexed _address);

    event RemovedFromWhitelist(address indexed _address);

    /*********************************** Errors ***********************************/

    /**
     * When a purchase is requested which exceeds the supply provided to this presale contract.
     *
     */
    error ExceededTotalSupply();

    /**
     * Insufficient permissions for caller.
     *
     * @param _address the address that has insufficient permissions
     * @param requiredRole requested amount to transfer
     */
    error InsufficientPermissions(address _address, bytes32 requiredRole);

    /**
     * When the lengths of the inputted arrays do not match.
     *
     * @param paymentMethodLength length of the payment methods array
     * @param tokenRateLength length of the token rates array
     */
    error InvalidArrayLengths(
        uint256 paymentMethodLength,
        uint256 tokenRateLength
    );

    /**
     * When the sent ether does not match pay amount.
     */
    error IncorrectEtherValue(uint256 sentAmount, uint256 correctAmount);

    /**
     * When the input parameters for a function is incorrect.
     */
    error InvalidInput();

    /**
     * When a submitted payment token is not supported.
     *
     * @param paymentToken The address of the payment token that the caller submitted
     */
    error InvalidPaymentToken(address paymentToken);

    /**
     * When a purchase is requested which amounts to less than the minimum purchase requirement.
     *
     */
    error LessThanMinimumPurchaseRequirement();

    /**
     * When a purchase is requested which amounts to more than the allotted limit.
     *
     */
    error ExceededMaximumPurchaseLimit();

    /**
     * When a withdrawl is requested for too many tokens.
     *
     */
    error NotEnoughBalance();

    /**
     * When a function is called while the presale has not yet been configured.
     */
    error PresaleNotConfigured();

    /**
     * When funds for the presale have already been provided by the owner or an admin.
     */
    error PresaleAlreadyConfigured();

    /**
     * When the sale is not active.
     *
     * @param currentTimestamp The timestamp at the time of the error
     * @param startTimestamp Timestamp of the start of the presale
     * @param endTimestamp Timestamp of the end of the presale
     */
    error SaleNotActive(
        uint256 currentTimestamp,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    /**
     * When address is not whitelisted.
     *
     * @param buyer address that requested to participate in presale.
     */
    error NotWhitelisted(address buyer);

    /**
     * When the whitelist feature is not enabled.
     */
    error WhitelistNotEnabled();

    /**
     * When a withdrawl is requested before the withdrawAfterTime.
     *
     */
    error WithdrawalTooEarly();

    /********************************* Modifiers **********************************/

    /// reverts PresaleNotConfigured error if the presale has not been configured.
    modifier configured() {
        if (!presaleConfigured) {
            revert PresaleNotConfigured();
        }
        _;
    }

    /// reverts NotWhitelisted error if caller is not whitelisted.
    modifier isWhitelisted() {
        if (contractOptions.enableWhitelist && !whitelist[msg.sender]) {
            revert NotWhitelisted({buyer: msg.sender});
        }
        _;
    }

    /// reverts InsufficientPermissions error if caller does not have admin or owner role.
    modifier onlyAdmin() {
        if (
            !hasRole(ADMIN_ROLE, msg.sender) &&
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender)
        ) {
            revert InsufficientPermissions({
                _address: msg.sender,
                requiredRole: ADMIN_ROLE
            });
        }
        _;
    }

    /// reverts InsufficientPermissions error if caller does not have owner role.
    modifier onlyOwner() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert InsufficientPermissions({
                _address: msg.sender,
                requiredRole: DEFAULT_ADMIN_ROLE
            });
        }
        _;
    }

    /// reverts SaleNotActive error if the sale is not active.
    modifier saleActive() {
        if (block.timestamp < startTime || block.timestamp > endTime) {
            revert SaleNotActive(block.timestamp, startTime, endTime);
        }
        _;
    }

    /******************************** Constructor *********************************/

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /********************************* Initialize *********************************/

    /**
     * The initializer function of this presale contract
     *
     * @param _defaultAdmin The owner of the presale
     * @param data All of the data to set the presale contract options and admins
     */
    function initialize(address _defaultAdmin, bytes calldata data)
        public
        initializer
    {
        // Decoding the data into usable parameters
        (
            address _tokenAddress,
            address payable _paymentReceiver,
            address[] memory _admins,
            ContractOptions memory _contractOptions
        ) = abi.decode(data, (address, address, address[], ContractOptions));

        // Setting the presale contract options
        tokenAddress = _tokenAddress;
        paymentReceiver = _paymentReceiver;
        contractOptions = _contractOptions;

        // Granting the owner and admin roles
        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);
        for (uint256 i = 0; i < _admins.length; i++) {
            _grantRole(ADMIN_ROLE, _admins[i]);
        }
    }

    /******************************* Read Functions *******************************/

    /**
     * Function to fetch the whitelist status for an address
     *
     * @param _address The address to fetch the whitelist status for
     *
     * @return bool True if the address is permitted to participate in the presale, and false otherwise
     */
    function getWhitelistStatus(address _address) public view returns (bool) {
        if (!contractOptions.enableWhitelist) {
            return true;
        }

        return whitelist[_address];
    }

    /**
     * Function to fetch the amount left for an address to withdraw
     *
     * @param _address The address of the address to fetch their whitelist status for
     *
     * @return uint256 True if the address is permitted to participate in the presale, and false otherwise
     */
    function getClaimableAmount(address _address)
        public
        view
        returns (uint256)
    {
        return claimableTokens[_address];
    }

    /**
     * Function to fetch the remaining amount of tokens that an address is allowed to purchase
     *
     * @param _address The address to fetch the remaining presale allocation for
     *
     * @return uint256 The remaining presale allocation for an address
     */
    function getPurchasedAmount(address _address)
        public
        view
        returns (uint256)
    {
        return maxAmountPerBuyer - purchasedTokens[_address];
    }

    /**
     * Function to fetch the remaining amount of tokens that an address is allowed to purchase
     *
     * @param _address The address to fetch the remaining presale allocation for
     *
     * @return uint256 The remaining presale allocation for an address
     */
    function getRemainingAllocation(address _address)
        public
        view
        returns (uint256)
    {
        return maxAmountPerBuyer - purchasedTokens[_address];
    }

    /**
     * Function to fetch the purchase rate for a token
     *
     * @param _tokenAddress The address to fetch the purchase rate for
     *
     * @return TokenRate The rate that the token is on sale for
     */
    function getPaymentMethodRate(address _tokenAddress)
        public
        view
        returns (TokenRate memory)
    {
        return paymentMethods[_tokenAddress];
    }

    /******************************* Write Functions ******************************/

    /**
     * Function to buy in the presale
     *
     * @param _paymentAddress The address of the token to purchase with
     * @param _payAmount The amount of payment token to purchase with
     */
    function buy(address _paymentAddress, uint256 _payAmount)
        public
        payable
        configured
        saleActive
        isWhitelisted
    {
        if (
            paymentMethods[_paymentAddress].presaleToken == 0 ||
            paymentMethods[_paymentAddress].paymentToken == 0
        ) {
            revert InvalidPaymentToken({paymentToken: _paymentAddress});
        }

        uint256 amount = (_payAmount *
            paymentMethods[_paymentAddress].presaleToken) /
            paymentMethods[_paymentAddress].paymentToken;

        // Check if the purchase amount is less than minimum allowed purchase
        if (amount < minInvestment) {
            revert LessThanMinimumPurchaseRequirement();
        }

        // Check if the amount to be purchased is greater than maximum allowed purchase
        if (amount + purchasedTokens[msg.sender] > maxAmountPerBuyer) {
            revert ExceededMaximumPurchaseLimit();
        }

        // Check if the amount is greater than current supply
        if (amount > currentSupply) {
            revert ExceededTotalSupply();
        }

        // Gets the payment from the caller
        if (_paymentAddress == address(0)) {
            // If the ether sent does not match _payAmount
            if (msg.value != _payAmount) {
                revert IncorrectEtherValue(msg.value, _payAmount);
            }
        } else {
            // Note: Can add a check for if the msg.value is 0, if not refund/revert

            IERC20 paymentTokenContract = IERC20(_paymentAddress);
            paymentTokenContract.transferFrom(
                msg.sender,
                address(this),
                _payAmount
            );
        }

        // Add the newly purchased amount to the previously purchased tokens for the caller
        claimableTokens[msg.sender] = claimableTokens[msg.sender] + amount;
        purchasedTokens[msg.sender] = purchasedTokens[msg.sender] + amount;

        // Subtract the newly purchased amount from the current supply
        currentSupply = currentSupply - amount;

        emit Purchased(msg.sender, _paymentAddress, _payAmount, amount);
    }

    /**
     * Function to configure the presale options
     *
     * @param _startTime The start timestamp for the presale
     * @param _endTime The end timestamp for the presale
     * @param _withdrawAfterTime The timestamp where participants can withdraw their tokens
     * @param _supply The supply of the presale token provided to the presale contract
     * @param _maxAmountPerBuyer The maximum amount an address can purchase as part of the presale
     * @param _minInvestment The minimum amount an address can purchase as part of the presale
     * @param _paymentMethods An array of addresses of the tokens that will be payment tokens
     * @param _tokenRate An array of token purchase rates that correspond to _paymentMethods
     */
    function configurePresale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _withdrawAfterTime,
        uint256 _supply,
        uint256 _maxAmountPerBuyer,
        uint256 _minInvestment,
        address[] memory _paymentMethods,
        TokenRate[] memory _tokenRate
    ) public onlyAdmin {
        // If the presale has already been configured, then revert
        if (presaleConfigured) {
            revert PresaleAlreadyConfigured();
        }
        presaleConfigured = true;

        // If the start time is the same or greater than end time, then revert
        // Also if the minimum investment is greater than the total supply, then revert
        if (
            _startTime >= _endTime ||
            block.timestamp > _endTime ||
            _minInvestment > _supply ||
            _maxAmountPerBuyer < _minInvestment
        ) {
            revert InvalidInput();
        }

        // If the payment methods array and token rate array have different lengths
        if (_paymentMethods.length != _tokenRate.length) {
            revert InvalidArrayLengths({
                paymentMethodLength: _paymentMethods.length,
                tokenRateLength: _tokenRate.length
            });
        }

        // Add the payment methods
        for (uint256 i = 0; i < _paymentMethods.length; i++) {
            paymentMethods[_paymentMethods[i]] = _tokenRate[i];
            emit PaymentModified(
                _paymentMethods[i],
                _tokenRate[i].presaleToken,
                _tokenRate[i].paymentToken
            );
        }

        // Setting up presale details
        startTime = _startTime;
        endTime = _endTime;
        withdrawAfterTime = _withdrawAfterTime;
        supply = _supply;
        maxAmountPerBuyer = _maxAmountPerBuyer;
        minInvestment = _minInvestment;

        // Transfering the tokens from the sender to this contract
        IERC20 tokenContract = IERC20(tokenAddress);
        tokenContract.transferFrom(msg.sender, address(this), supply);

        currentSupply = supply;
    }

    /**
     * Function to modify payment methods for the presale
     *
     * @param _paymentMethods An array of addresses of the tokens that will be payment tokens
     * @param _tokenRate An array of token purchase rates that correspond to _paymentMethods
     */
    function modifyPaymentMethods(
        address[] memory _paymentMethods,
        TokenRate[] memory _tokenRate
    ) public configured onlyAdmin {
        // If the payment methods array and token rate array have different lengths
        if (_paymentMethods.length != _tokenRate.length) {
            revert InvalidArrayLengths({
                paymentMethodLength: _paymentMethods.length,
                tokenRateLength: _tokenRate.length
            });
        }

        // Add the payment methods
        for (uint256 i = 0; i < _paymentMethods.length; i++) {
            paymentMethods[_paymentMethods[i]] = _tokenRate[i];
            emit PaymentModified(
                _paymentMethods[i],
                _tokenRate[i].presaleToken,
                _tokenRate[i].paymentToken
            );
        }
    }

    /**
     * Function to withdraw purchased presale tokens
     *
     * @param _amount The amount of presale token to withdraw to the caller
     */
    function withdraw(uint256 _amount) public configured {
        if (block.timestamp <= withdrawAfterTime) {
            revert WithdrawalTooEarly();
        }

        if (claimableTokens[msg.sender] < _amount) {
            revert NotEnoughBalance();
        }

        claimableTokens[msg.sender] = claimableTokens[msg.sender] - _amount;

        // Transfer the presale token to the caller
        IERC20 tokenContract = IERC20(tokenAddress);
        tokenContract.transfer(msg.sender, _amount);
        emit Withdraw(msg.sender, _amount);
    }

    /**
     * Function to withdraw all purchased presale tokens to the caller
     */
    function withdrawAll() public configured {
        if (block.timestamp <= withdrawAfterTime) {
            revert WithdrawalTooEarly();
        }

        if (claimableTokens[msg.sender] == 0) {
            revert NotEnoughBalance();
        }

        // This is here in case of a re-entrancy attack
        uint256 amountToTransfer = claimableTokens[msg.sender];
        claimableTokens[msg.sender] = 0;

        // Transfer the presale token to the caller
        IERC20 tokenContract = IERC20(tokenAddress);
        tokenContract.transfer(msg.sender, amountToTransfer);
        emit Withdraw(msg.sender, amountToTransfer);
    }

    /**
     * Function to withdraw any token to the paymentReceiver
     *
     * @param _tokenAddress The token address of the token that the owner requests to withdraw
     * @param _amount The amount of the token that the owner requests to withdraw
     */
    function ownerWithdraw(address _tokenAddress, uint256 _amount)
        public
        onlyOwner
    {
        if (
            _tokenAddress == tokenAddress &&
            block.timestamp <= withdrawAfterTime
        ) {
            revert WithdrawalTooEarly();
        }

        // If the owner withdraws the presale token, subtract it from current supply
        if (_tokenAddress == tokenAddress) {
            currentSupply -= _amount;
        }

        // Transfer the tokens to the payment receiver
        if (_tokenAddress == address(0)) {
            payable(paymentReceiver).transfer(_amount);
        } else {
            IERC20 tokenContract = IERC20(_tokenAddress);
            tokenContract.transfer(paymentReceiver, _amount);
        }
        emit OwnerWithdraw(paymentReceiver, _tokenAddress, _amount);
    }

    /**
     * Function to withdraw all of any token to the paymentReceiver
     *
     * @param _tokenAddress The token address of the token that the owner requests to withdraw
     */
    function ownerWithdrawAll(address _tokenAddress) public onlyOwner {
        if (
            _tokenAddress == tokenAddress &&
            block.timestamp <= withdrawAfterTime
        ) {
            revert WithdrawalTooEarly();
        }

        // If the owner withdraws the presale token, subtract it from current supply
        if (_tokenAddress == tokenAddress) {
            currentSupply = 0;
        }

        if (_tokenAddress == address(0)) {
            payable(paymentReceiver).transfer(address(this).balance);
            emit OwnerWithdraw(
                paymentReceiver,
                _tokenAddress,
                address(this).balance
            );
        } else {
            IERC20 tokenContract = IERC20(_tokenAddress);

            // Transfer the tokens to the payment receiver
            tokenContract.transfer(
                paymentReceiver,
                tokenContract.balanceOf(address(this))
            );
            emit OwnerWithdraw(
                paymentReceiver,
                _tokenAddress,
                tokenContract.balanceOf(address(this))
            );
        }
    }

    /**
     * Function to add addresses to the whitelist
     *
     * @param addresses An array of addresses to add to the whitelist
     */
    function addToWhitelist(address[] memory addresses) public onlyAdmin {
        if (!contractOptions.enableWhitelist) {
            revert WhitelistNotEnabled();
        }

        // Add the addresses to the whitelist
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
            emit AddedToWhitelist(addresses[i]);
        }
    }

    /**
     * Function to remove addresses from the whitelist
     *
     * @param addresses An array of addresses to remove from the whitelist
     */
    function removeFromWhitelist(address[] memory addresses) public onlyAdmin {
        if (!contractOptions.enableWhitelist) {
            revert WhitelistNotEnabled();
        }

        // Remove the addresses from the whitelist
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
            emit RemovedFromWhitelist(addresses[i]);
        }
    }

    /***************************** Internal Functions *****************************/
}