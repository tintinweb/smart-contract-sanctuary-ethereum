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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
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

        /// @solidity memory-safe-assembly
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

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUniblockProxy {
    /**
     * initializes the new proxy with the owner and inputted data.
     *
     * @param owner owner of the proxy contract.
     * @param data data to be passed into initialize call on the clone.
     */
    function initialize(address owner, bytes calldata data) external;
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

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/utils/math/Math.sol';
import '../../interfaces/IUniblockProxy.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

contract UniblockERC20Presale is Initializable, AccessControl, IUniblockProxy {
    using EnumerableSet for EnumerableSet.AddressSet;

    /*********************************** Structs **********************************/

    struct ContractOptions {
        bool enableWhitelist;
    }

    struct TokenRate {
        uint256 presaleToken;
        uint256 paymentToken;
    }

    /********************************** Constants *********************************/

    bytes32 public constant IMPLEMENTATION_TYPE =
        keccak256('UNIBLOCK_ERC20_PRESALE');

    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

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

    bool public presaleConfigured;

    EnumerableSet.AddressSet private acceptedPaymentMethods;

    mapping(address => TokenRate) public paymentMethods;

    // Mapping of the amount of tokens that an address has purchased
    mapping(address => uint256) public purchasedTokens;

    // Mapping of the amount of tokens that an address has previously claimed
    mapping(address => uint256) public claimedTokens;

    mapping(address => bool) public whitelist;

    ContractOptions public contractOptions;

    string public contractURI;
    /*********************************** Events ***********************************/

    /**
     * @notice Emitted when a purchase occurs.
     *
     * @param buyer The address buyer of the presale token.
     * @param paymentToken The address of the token that the buyer paid with.
     * @param paymentAmount The amount of the payment token that the buyer spent.
     * @param amountPurchased The amount of the presale token that the buyer gets allotted.
     */
    event Purchased(
        address indexed buyer,
        address indexed paymentToken,
        uint256 paymentAmount,
        uint256 amountPurchased
    );

    /**
     * @notice Emitted when the presale gets configured.
     *
     * @param startTime The start time of the presale.
     * @param endTime The end time of the presale.
     * @param withdrawAfterTime The timestamp after which buyers are allowed to withdraw their allotted tokens.
     * @param supply The supply of the presale token that the presale will have.
     * @param maxAmountPerBuyer The maximum amount that a buyer can purchase.
     * @param minInvestment The minimum amount that a buyer can purchase at one time.
     */
    event PresaleConfigured(
        uint256 startTime,
        uint256 endTime,
        uint256 withdrawAfterTime,
        uint256 supply,
        uint256 maxAmountPerBuyer,
        uint256 minInvestment
    );

    /**
     * @notice Emitted when a payment method gets modified.
     *
     * @param paymentAddress The payment address of the token that got modified.
     * @param presaleToken The amount of presale token for the rate calculations.
     * @param paymentToken The amount of payment token for the rate calculations.
     */
    event PaymentModified(
        address indexed paymentAddress,
        uint256 presaleToken,
        uint256 paymentToken
    );

    /**
     * @notice Emitted when a buyer withdraws their allotted presale tokens.
     *
     * @param receiver The receiver of the withdrawn tokens.
     * @param amount The amount tokens withdrawn to the receiver.
     */
    event Withdraw(address indexed receiver, uint256 amount);

    /**
     * @notice Emitted when the owner withdraws any token.
     *
     * @param receiver The receiver of the withdrawn tokens.
     * @param tokenAddress The address tokens that got withdrawn.
     * @param amount The amount tokens withdrawn to the receiver.
     */
    event OwnerWithdraw(
        address indexed receiver,
        address indexed tokenAddress,
        uint256 amount
    );

    /**
     * @notice Emitted when an address gets added to the whitelist.
     *
     * @param _address The address that got added to the whitelist.
     */
    event AddedToWhitelist(address indexed _address);

    /**
     * @notice Emitted when an address gets removed from the whitelist.
     *
     * @param _address The address that got removed from the whitelist.
     */
    event RemovedFromWhitelist(address indexed _address);

    /*********************************** Errors ***********************************/

    /**
     * @notice Purchase is requested which exceeds the supply provided to this presale contract.
     */
    error ExceededTotalSupply();

    /**
     * @notice Insufficient permissions for caller.
     *
     * @param _address The address that has insufficient permissions.
     * @param requiredRole Requested amount to transfer.
     */
    error InsufficientPermissions(address _address, bytes32 requiredRole);

    /**
     * @notice Lengths of the inputted arrays do not match.
     *
     * @param paymentMethodLength Length of the payment methods array.
     * @param tokenRateLength Length of the token rates array.
     */
    error InvalidArrayLengths(
        uint256 paymentMethodLength,
        uint256 tokenRateLength
    );

    /**
     * @notice Sent ether does not match payment amount.
     */
    error IncorrectEtherValue(uint256 sentAmount, uint256 correctAmount);

    /**
     * @notice Input parameters for a function are incorrect.
     */
    error InvalidInput();

    /**
     * @notice Submitted payment token is not supported.
     *
     * @param paymentToken The address of the payment token that the caller submitted.
     */
    error InvalidPaymentToken(address paymentToken);

    /**
     * @notice Provided address is the zero address when it should not be.
     *
     * @param field The type of the provided address (token, reciever, etc.)
     */
    error InvalidZeroAddress(string field);

    /**
     * @notice Purchase is requested which amounts to less than the minimum purchase requirement.
     */
    error LessThanMinimumPurchaseRequirement();

    /**
     * @notice Purchase is requested which amounts to more than the allotted limit.
     */
    error ExceededMaximumPurchaseLimit();

    /**
     * @notice Withdrawl is requested for too many tokens.
     */
    error NotEnoughBalance();

    /**
     * @notice Function is called while the presale has not yet been configured.
     */
    error PresaleNotConfigured();

    /**
     * @notice Funds for the presale have already been provided by the owner or an admin.
     */
    error PresaleAlreadyConfigured();

    /**
     * @notice The sale is not active.
     *
     * @param currentTimestamp The timestamp at the time of the error.
     * @param startTimestamp Timestamp of the start of the presale.
     * @param endTimestamp Timestamp of the end of the presale.
     */
    error SaleNotActive(
        uint256 currentTimestamp,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    /**
     * @notice Address is not whitelisted.
     *
     * @param buyer Address that requested to participate in presale.
     */
    error NotWhitelisted(address buyer);

    /**
     * @notice Whitelist feature is not enabled.
     */
    error WhitelistNotEnabled();

    /**
     * @notice Withdrawl is requested before the withdrawAfterTime.
     *
     */
    error WithdrawalTooEarly();

    /********************************* Modifiers **********************************/

    /**
     * @notice Reverts PresaleNotConfigured error if the presale has not been configured.
     */
    modifier configured() {
        if (!presaleConfigured) {
            revert PresaleNotConfigured();
        }
        _;
    }

    /**
     * @notice Reverts NotWhitelisted error if caller is not whitelisted.
     */
    modifier isWhitelisted() {
        if (contractOptions.enableWhitelist && !whitelist[msg.sender]) {
            revert NotWhitelisted({buyer: msg.sender});
        }
        _;
    }

    /**
     * @notice Reverts WhitelistNotEnabled error if whitelist is not enabled.
     */
    modifier whitelistEnabled() {
        if (!contractOptions.enableWhitelist) {
            revert WhitelistNotEnabled();
        }
        _;
    }

    /**
     * @notice Reverts InsufficientPermissions error if caller does not have admin or owner role.
     */
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

    /**
     * @notice Reverts InsufficientPermissions error if caller does not have owner role.
     */
    modifier onlyOwner() {
        if (!hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert InsufficientPermissions({
                _address: msg.sender,
                requiredRole: DEFAULT_ADMIN_ROLE
            });
        }
        _;
    }

    /**
     * @notice Reverts SaleNotActive error if the sale is not active.
     */
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
     * @notice The initializer function of this presale contract.
     *
     * @param defaultAdmin The owner of the presale.
     * @param data All of the data to set the presale contract options and admins.
     */
    function initialize(address defaultAdmin, bytes calldata data)
        public
        initializer
    {
        /**
         * _tokenAddress Token address for presale
         * _paymentReceiver Address to receive payments
         * _admins Sets the admins
         * _contractOptions Sets which features to enable
         */
        (
            address _tokenAddress,
            address payable _paymentReceiver,
            string memory _contractURI,
            address[] memory _admins,
            ContractOptions memory _contractOptions
        ) = abi.decode(
                data,
                (address, address, string, address[], ContractOptions)
            );

        if (_tokenAddress == address(0)) {
            revert InvalidZeroAddress('tokenAddress');
        }

        if (_paymentReceiver == address(0)) {
            revert InvalidZeroAddress('paymentReceiver');
        }

        // Setting the presale contract options
        tokenAddress = _tokenAddress;
        paymentReceiver = _paymentReceiver;
        contractURI = _contractURI;
        contractOptions = _contractOptions;

        // Granting the owner and admin roles
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        for (uint256 i = 0; i < _admins.length; i++) {
            _grantRole(ADMIN_ROLE, _admins[i]);
        }
    }

    /******************************* Read Functions *******************************/

    /**
     * @notice Get the whitelist status for an address.
     *
     * @param _address The address to fetch the whitelist status for.
     *
     * @return bool True if the address is permitted to participate in the presale, and false otherwise.
     */
    function whitelistStatus(address _address) public view returns (bool) {
        return !contractOptions.enableWhitelist || whitelist[_address];
    }

    /**
     * @notice Get the remaining amount of tokens an address can withdraw.
     *
     * @param _address The address to get the claimable amount of.
     *
     * @return uint256 The remaining amount of tokens address can withdraw
     */
    function claimableAmount(address _address) public view returns (uint256) {
        return purchasedTokens[_address] - claimedTokens[_address];
    }

    /**
     * @notice Get the remaining amount of tokens that an address is allowed to purchase.
     *
     * @param _address The address to fetch the remaining presale allocation for.
     *
     * @return uint256 The remaining presale allocation for an address.
     */
    function remainingAllocation(address _address)
        public
        view
        returns (uint256)
    {
        return maxAmountPerBuyer - purchasedTokens[_address];
    }

    /**
     * @notice Get all accepted payment methods.
     *
     * @return address[] The list of payment methods.
     */
    function allPaymentMethods() public view returns (address[] memory) {
        return acceptedPaymentMethods.values();
    }

    /******************************* Write Functions ******************************/

    /**
     * @notice Buy in the presale.
     *
     * @param paymentAddress The address of the token to purchase with.
     * @param payAmount The amount of payment token to purchase with.
     */
    function buy(address paymentAddress, uint256 payAmount)
        public
        payable
        configured
        saleActive
        isWhitelisted
        returns (uint256)
    {
        if (
            paymentMethods[paymentAddress].presaleToken == 0 ||
            paymentMethods[paymentAddress].paymentToken == 0
        ) {
            revert InvalidPaymentToken({paymentToken: paymentAddress});
        }

        uint256 amount = (payAmount *
            paymentMethods[paymentAddress].presaleToken) /
            paymentMethods[paymentAddress].paymentToken;

        // Check if the purchase amount is less than minimum allowed purchase
        if (amount == 0 || amount < minInvestment) {
            revert LessThanMinimumPurchaseRequirement();
        }

        payAmount = Math.ceilDiv(
            (amount * paymentMethods[paymentAddress].paymentToken),
            paymentMethods[paymentAddress].presaleToken
        );

        // Check if the amount to be purchased is greater than maximum allowed purchase
        if (amount + purchasedTokens[msg.sender] > maxAmountPerBuyer) {
            revert ExceededMaximumPurchaseLimit();
        }

        // Check if the amount is greater than current supply
        if (amount > currentSupply) {
            revert ExceededTotalSupply();
        }

        // Add the newly purchased amount to the previously purchased tokens for the caller
        purchasedTokens[msg.sender] = purchasedTokens[msg.sender] + amount;

        // Subtract the newly purchased amount from the current supply
        currentSupply = currentSupply - amount;

        // Gets the payment from the caller
        if (paymentAddress == address(0)) {
            // If the ether sent does not match payAmount
            if (msg.value != payAmount) {
                revert IncorrectEtherValue(msg.value, payAmount);
            }
        } else {
            if (msg.value > 0) {
                revert IncorrectEtherValue(msg.value, 0);
            }
            IERC20 paymentTokenContract = IERC20(paymentAddress);
            paymentTokenContract.transferFrom(
                msg.sender,
                address(this),
                payAmount
            );
        }
        emit Purchased(msg.sender, paymentAddress, payAmount, amount);
        return amount;
    }

    /**
     * @notice Configure the presale options.
     *
     * @param _startTime The start timestamp for the presale.
     * @param _endTime The end timestamp for the presale.
     * @param _withdrawAfterTime The timestamp where participants can withdraw their tokens.
     * @param _supply The supply of the presale token provided to the presale contract.
     * @param _maxAmountPerBuyer The maximum amount an address can purchase as part of the presale.
     * @param _minInvestment The minimum amount an address can purchase as part of the presale.
     * @param _paymentMethods An array of addresses of the tokens that will be payment tokens.
     * @param _tokenRate An array of token purchase rates that correspond to _paymentMethods.
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
            // Add the payment method to the list of accepted payment methods
            // if the _tokenRate is not 0
            if (
                _tokenRate[i].presaleToken != 0 &&
                _tokenRate[i].paymentToken != 0
            ) {
                acceptedPaymentMethods.add(_paymentMethods[i]);
            }
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
        presaleConfigured = true;
    }

    /**
     * @notice Modify payment methods for the presale.
     *
     * @param _paymentMethods An array of addresses of the tokens that will be payment methods.
     * @param _tokenRate An array of token purchase rates that correspond to _paymentMethods.
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
            if (
                _tokenRate[i].presaleToken == 0 ||
                _tokenRate[i].paymentToken == 0
            ) {
                acceptedPaymentMethods.remove(_paymentMethods[i]);
            } else {
                acceptedPaymentMethods.add(_paymentMethods[i]);
            }
            paymentMethods[_paymentMethods[i]] = _tokenRate[i];

            emit PaymentModified(
                _paymentMethods[i],
                _tokenRate[i].presaleToken,
                _tokenRate[i].paymentToken
            );
        }
    }

    /**
     * @notice Withdraw a specified amount of purchased presale tokens to the caller.
     *
     * @param amount The amount of presale token to withdraw to the caller.
     */
    function withdraw(uint256 amount) public configured {
        if (amount == 0) {
            revert InvalidInput();
        }

        if (block.timestamp <= withdrawAfterTime) {
            revert WithdrawalTooEarly();
        }

        if (purchasedTokens[msg.sender] - claimedTokens[msg.sender] < amount) {
            revert NotEnoughBalance();
        }

        claimedTokens[msg.sender] = claimedTokens[msg.sender] + amount;
        // Transfer the presale token to the caller
        IERC20 tokenContract = IERC20(tokenAddress);
        tokenContract.transfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    /**
     * @notice Withdraw all purchased presale tokens to the caller.
     */
    function withdrawAll() public configured {
        withdraw(purchasedTokens[msg.sender] - claimedTokens[msg.sender]);
    }

    /**
     * @notice Withdraw a speicifed amount of a token to the owner.
     *
     * @param _tokenAddress The address of the token that the owner requests to withdraw.
     * @param amount The amount of the token that the owner requests to withdraw.
     */
    function ownerWithdraw(address _tokenAddress, uint256 amount)
        public
        onlyOwner
    {
        if (
            _tokenAddress == tokenAddress &&
            block.timestamp <= withdrawAfterTime
        ) {
            revert WithdrawalTooEarly();
        }

        // If the owner requests to withdraw more than the current supply for presale token, revert
        if (_tokenAddress == tokenAddress && amount > currentSupply) {
            revert NotEnoughBalance();
        }

        // If the owner withdraws the presale token, subtract it from current supply
        if (_tokenAddress == tokenAddress) {
            currentSupply -= amount;
        }

        // Transfer the tokens to the payment receiver
        if (_tokenAddress == address(0)) {
            payable(paymentReceiver).transfer(amount);
        } else {
            IERC20 tokenContract = IERC20(_tokenAddress);
            tokenContract.transfer(paymentReceiver, amount);
        }
        emit OwnerWithdraw(paymentReceiver, _tokenAddress, amount);
    }

    /**
     * @notice Withdraw all of specified token to the owner.
     *
     * @param _tokenAddress The address of the token that the owner requests to withdraw.
     */
    function ownerWithdrawAll(address _tokenAddress) public onlyOwner {
        if (_tokenAddress == address(0)) {
            ownerWithdraw(_tokenAddress, address(this).balance);
        } else if (_tokenAddress == tokenAddress) {
            ownerWithdraw(_tokenAddress, currentSupply);
        } else {
            IERC20 tokenContract = IERC20(_tokenAddress);
            ownerWithdraw(
                _tokenAddress,
                tokenContract.balanceOf(address(this))
            );
        }
    }

    /**
     * @notice Add addresses to the whitelist.
     *
     * @param addresses An array of addresses to add to the whitelist.
     */
    function addToWhitelist(address[] memory addresses)
        public
        onlyAdmin
        whitelistEnabled
    {
        // Add the addresses to the whitelist
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = true;
            emit AddedToWhitelist(addresses[i]);
        }
    }

    /**
     * @notice Remove addresses from the whitelist.
     *
     * @param addresses An array of addresses to remove from the whitelist.
     */
    function removeFromWhitelist(address[] memory addresses)
        public
        onlyAdmin
        whitelistEnabled
    {
        // Remove the addresses from the whitelist
        for (uint256 i = 0; i < addresses.length; i++) {
            whitelist[addresses[i]] = false;
            emit RemovedFromWhitelist(addresses[i]);
        }
    }

    /**
     * @notice Change the payment receiver.
     *
     * @param _paymentReceiver The new payment receiver.
     */
    function setPaymentReceiver(address _paymentReceiver) public onlyOwner {
        if (_paymentReceiver == address(0)) {
            revert InvalidZeroAddress('paymentReceiver');
        }

        paymentReceiver = _paymentReceiver;
    }

    /**
     * @notice Buy and withdraw presale tokens.
     *
     * @param paymentAddress The address of the payment token.
     * @param payAmount The amount of payment token to buy presale token.
     */

    function buyAndWithdraw(address paymentAddress, uint256 payAmount)
        public
        payable
        configured
        saleActive
        isWhitelisted
    {
        uint256 amount = buy(paymentAddress, payAmount);
        withdraw(amount);
    }

    /**
     * @dev Sets the contract metadata uri
     */
    function setContractUri(string calldata _contractURI) public onlyAdmin {
        contractURI = _contractURI;
    }
}