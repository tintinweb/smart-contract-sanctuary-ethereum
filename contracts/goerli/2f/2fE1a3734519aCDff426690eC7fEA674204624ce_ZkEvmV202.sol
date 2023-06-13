// SPDX-License-Identifier: OWNED BY ConsenSys Software Inc.
pragma solidity ^0.8.19;

import "./ZkEvmV2.sol";

/**
 * @title Contract to reinitialize cross-chain messaging on L1 and rollup proving.
 * @author ConsenSys Software Inc.
 */
contract ZkEvmV202 is ZkEvmV2 {
  /*
   * @notice Reinitializes zkEvm and underlying service dependencies.
   * @param _initialStateRootHash The initial hash at migration used for proof verification.
   * @param _initialL2BlockNumber The initial block number at migration.
   **/
  function initializeV2(uint256 _initialL2BlockNumber, bytes32 _initialStateRootHash) public reinitializer(2) {
    currentL2BlockNumber = _initialL2BlockNumber;
    stateRootHashes[_initialL2BlockNumber] = _initialStateRootHash;
  }
}

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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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

// SPDX-License-Identifier: OWNED BY ConsenSys Software Inc.
pragma solidity ^0.8.19;

interface IZkEvmV2 {
  struct BlockData {
    bytes32 blockRootHash;
    uint32 l2BlockTimestamp;
    bytes[] transactions;
    bytes[] l2l1logs;
    uint16[] batchReceptionIndices;
  }

  /**
   * @dev Emitted when a L2 block has been finalized on L1
   */
  event BlockFinalized(uint256 indexed blockNumber, bytes32 stateRootHash);
  /**
   * @dev Emitted when a L2 blocks have been finalized on L1
   */
  event BlocksVerificationDone(uint256 indexed lastBlockFinalized, bytes32 startingRootHash, bytes32 finalRootHash);

  /**
   * @dev Thrown when l2 block timestamp is not correct
   */
  error BlockTimestampError();

  /**
   * @dev Thrown when the starting rootHash does not match the existing state
   */
  error StartingRootHashDoesNotMatch();

  /**
   * @dev Thrown when block contains zero transactions
   */
  error EmptyBlock();

  /**
   * @dev Thrown when zk proof is empty bytes
   */
  error ProofIsEmpty();

  /**
   * @dev Thrown when zk proof type is invalid
   */
  error InvalidProofType();

  /**
   * @dev Thrown when zk proof is invalid
   */
  error InvalidProof();

  /**
   * @notice Adds or updated the verifier contract address for a proof type
   * @dev DEFAULT_ADMIN_ROLE is required to execute
   * @param _newVerifierAddress The address for the verifier contract
   * @param _proofType The proof type being set/updated
   **/
  function setVerifierAddress(address _newVerifierAddress, uint256 _proofType) external;

  /**
   * @notice Finalizes blocks without using a proof
   * @dev DEFAULT_ADMIN_ROLE is required to execute
   * @param _calldata The full BlockData collection - block, transaction and log data
   **/
  function finalizeBlocksWithoutProof(BlockData[] calldata _calldata) external;

  /**
   * @notice Finalizes blocks without using a proof
   * @dev OPERATOR_ROLE is required to execute
   * @dev If the verifier based on proof type is not found, it defaults to the default verifier type
   * @param _calldata The full BlockData collection - block, transaction and log data
   * @param _proof The proof to verified with the proof type verifier contract
   * @param _proofType The proof type to determine which verifier contract to use
   * @param _parentStateRootHash The beginning roothash to start with
   **/
  function finalizeBlocks(
    BlockData[] calldata _calldata,
    bytes calldata _proof,
    uint256 _proofType,
    bytes32 _parentStateRootHash
  ) external;
}

// SPDX-License-Identifier: OWNED BY ConsenSys Software Inc.
pragma solidity ^0.8.19;

interface IGenericErrors {
  /**
   * @dev Thrown when a parameter is the zero address.
   */
  error ZeroAddressNotAllowed();
}

// SPDX-License-Identifier: OWNED BY ConsenSys Software Inc.
pragma solidity ^0.8.19;

interface IL1MessageManager {
  /**
   * @dev Emitted when L2->L1 message hashes have been added to L1 storage.
   */
  event L2L1MessageHashAddedToInbox(bytes32 indexed messageHash);

  /**
   * @dev Emitted when L1->L2 message hashes have been added to L1 storage.
   */
  event L1L2MessageHashAddedToOutbox(bytes32 indexed messageHash);

  /**
   * @dev Emitted when the L2->L1 message has been claimed.
   */
  event L2L1MessageClaimed(bytes32 indexed messageHash);

  /**
   * @dev Emitted when L1->L2 messages have been anchored on L2 and updated on L1.
   */
  event L1L2MessagesReceivedOnL2(bytes32[] messageHashes);

  /**
   * @dev Thrown when the message has been already sent.
   */
  error MessageAlreadySent();

  /**
   * @dev Thrown when the message has already been claimed.
   */
  error MessageAlreadyClaimed();

  /**
   * @dev Thrown when the message has already been received.
   */
  error MessageAlreadyReceived(bytes32 messageHash);

  /**
   * @dev Thrown when the L1->L2 message has not been sent.
   */
  error L1L2MessageNotSent(bytes32 messageHash);
}

// SPDX-License-Identifier: OWNED BY ConsenSys Software Inc.
pragma solidity ^0.8.19;

interface IMessageService {
  /**
   * @dev Emitted when a message is sent.
   * @dev We include the message hash to save hashing costs on the rollup.
   */
  event MessageSent(
    address indexed _from,
    address indexed _to,
    uint256 _fee,
    uint256 _value,
    uint256 _nonce,
    bytes _calldata,
    bytes32 indexed _messageHash
  );

  /**
   * @dev Emitted when a message is claimed.
   */
  event MessageClaimed(bytes32 indexed _messageHash);

  /**
   * @dev Thrown when fees are lower than the minimum fee.
   */
  error FeeTooLow();

  /**
   * @dev Thrown when fees are lower than value.
   */
  error ValueShouldBeGreaterThanFee();

  /**
   * @dev Thrown when the value sent is less than the fee.
   * @dev Value to forward on is msg.value - _fee.
   */
  error ValueSentTooLow();

  /**
   * @dev Thrown when the destination address reverts.
   */
  error MessageSendingFailed(address destination);

  /**
   * @dev Thrown when the destination address reverts.
   */
  error FeePaymentFailed(address recipient);

  /**
   * @notice Sends a message for transporting from the given chain.
   * @dev This function should be called with a msg.value = _value + _fee. The fee will be paid on the destination chain.
   * @param _to The destination address on the destination chain.
   * @param _fee The message service fee on the origin chain.
   * @param _calldata The calldata used by the destination message service to call the destination contract.
   */
  function sendMessage(address _to, uint256 _fee, bytes calldata _calldata) external payable;

  /**
   * @notice Deliver a message to the destination chain.
   * @notice Is called automatically by the Postman, dApp or end user.
   * @param _from The msg.sender calling the origin message service.
   * @param _to The destination address on the destination chain.
   * @param _value The value to be transferred to the destination address.
   * @param _fee The message service fee on the origin chain.
   * @param _feeRecipient Address that will receive the fees.
   * @param _calldata The calldata used by the destination message service to call/forward to the destination contract.
   * @param _nonce Unique message number.
   */
  function claimMessage(
    address _from,
    address _to,
    uint256 _fee,
    uint256 _value,
    address payable _feeRecipient,
    bytes calldata _calldata,
    uint256 _nonce
  ) external;

  /**
   * @notice Returns the original sender of the message on the origin layer.
   * @return The original sender of the message on the origin layer.
   */
  function sender() external view returns (address);
}

// SPDX-License-Identifier: OWNED BY ConsenSys Software Inc.
pragma solidity ^0.8.19;

interface IPauseManager {
  /**
   * @dev Thrown when a specific pause type is paused.
   */
  error IsPaused(bytes32 pauseType);

  /**
   * @dev Emitted when a pause type is paused.
   */
  event Paused(address messageSender, bytes32 pauseType);

  /**
   * @dev Emitted when a pause type is unpaused.
   */
  event UnPaused(address messageSender, bytes32 pauseType);
}

// SPDX-License-Identifier: OWNED BY ConsenSys Software Inc.
pragma solidity ^0.8.19;

/**
 * @title Contract to manage cross-chain messaging on L1 and rollup proving
 * @author ConsenSys Software Inc.
 */
interface IPlonkVerifier {
  /**
   * @notice Interface for verifier contracts.
   * @param _proof The proof used to verify.
   * @param _public_inputs The computed public inputs for the proof verification.
   */
  function Verify(bytes memory _proof, uint256[] memory _public_inputs) external returns (bool);
}

// SPDX-License-Identifier: OWNED BY ConsenSys Software Inc.
pragma solidity ^0.8.19;

interface IRateLimiter {
  /**
   * @dev Thrown when an amount breaches the limit in the period.
   */
  error RateLimitExceeded();

  /**
   * @dev Thrown when the period is initialised to zero.
   */
  error PeriodIsZero();

  /**
   * @dev Thrown when the limit is initialised to zero.
   */
  error LimitIsZero();

  /**
   * @dev Emitted when the amount in the period is reset to zero.
   */
  event AmountUsedInPeriodReset(address indexed resettingAddress);

  /**
   * @dev Emitted when the limit is changed.
   * @dev If the current used amount is higher than the new limit, the used amount is lowered to the limit.
   */
  event LimitAmountChange(address indexed amountChangeBy, uint256 amount, bool amountUsedLoweredToLimit);

  /**
   * @notice Resets the rate limit amount to the amount specified.
   * @param _amount New message hashes.
   */
  function resetRateLimitAmount(uint256 _amount) external;

  /**
   * @notice Resets the amount used in the period to zero.
   */
  function resetAmountUsedInPeriod() external;
}

// SPDX-License-Identifier: OWNED BY ConsenSys Software Inc.
pragma solidity ^0.8.19;

import "../interfaces/IL1MessageManager.sol";

/**
 * @title Contract to manage cross-chain message hashes storage and status on L1.
 * @author ConsenSys Software Inc.
 */
abstract contract L1MessageManager is IL1MessageManager {
  uint8 public constant INBOX_STATUS_UNKNOWN = 0;
  uint8 public constant INBOX_STATUS_RECEIVED = 1;

  uint8 public constant OUTBOX_STATUS_UNKNOWN = 0;
  uint8 public constant OUTBOX_STATUS_SENT = 1;
  uint8 public constant OUTBOX_STATUS_RECEIVED = 2;

  /// @dev There is a uint216 worth of storage layout here.

  /// @dev Mapping to store L1->L2 message hashes status.
  /// @dev messageHash => messageStatus (0: unknown, 1: sent, 2: received).
  mapping(bytes32 => uint256) public outboxL1L2MessageStatus;

  /// @dev Mapping to store L2->L1 message hashes status.
  /// @dev messageHash => messageStatus (0: unknown, 1: received).
  mapping(bytes32 => uint256) public inboxL2L1MessageStatus;

  /// @dev Keep free storage slots for future implementation updates to avoid storage collision.
  uint256[50] private __gap;

  /**
   * @notice Add a cross-chain L2->L1 message hash in storage.
   * @dev Once the event is emitted, it should be ready for claiming (post block finalization).
   * @param  _messageHash Hash of the message.
   */
  function _addL2L1MessageHash(bytes32 _messageHash) internal {
    if (inboxL2L1MessageStatus[_messageHash] != INBOX_STATUS_UNKNOWN) {
      revert MessageAlreadyReceived(_messageHash);
    }

    inboxL2L1MessageStatus[_messageHash] = INBOX_STATUS_RECEIVED;

    emit L2L1MessageHashAddedToInbox(_messageHash);
  }

  /**
   * @notice Update the status of L2->L1 message when a user claims a message on L1.
   * @dev The L2->L1 message is removed from storage.
   * @dev Due to the nature of the rollup, we should not get a second entry of this.
   * @param  _messageHash Hash of the message.
   */
  function _updateL2L1MessageStatusToClaimed(bytes32 _messageHash) internal {
    if (inboxL2L1MessageStatus[_messageHash] != INBOX_STATUS_RECEIVED) {
      revert MessageAlreadyClaimed();
    }

    delete inboxL2L1MessageStatus[_messageHash];

    emit L2L1MessageClaimed(_messageHash);
  }

  /**
   * @notice Add L1->L2 message hash in storage when a message is sent on L1.
   * @param  _messageHash Hash of the message.
   */
  function _addL1L2MessageHash(bytes32 _messageHash) internal {
    outboxL1L2MessageStatus[_messageHash] = OUTBOX_STATUS_SENT;
    emit L1L2MessageHashAddedToOutbox(_messageHash);
  }

  /**
   * @notice Update the status of L1->L2 messages as received when messages has been stored on L2.
   * @dev The expectation here is that the rollup is limited to 100 hashes being added here - array is not open ended.
   * @param  _messageHashes List of message hashes.
   */
  function _updateL1L2MessageStatusToReceived(bytes32[] memory _messageHashes) internal {
    uint256 messageHashArrayLength = _messageHashes.length;

    for (uint256 i; i < messageHashArrayLength; ) {
      bytes32 messageHash = _messageHashes[i];
      uint256 existingStatus = outboxL1L2MessageStatus[messageHash];

      if (existingStatus == INBOX_STATUS_UNKNOWN) {
        revert L1L2MessageNotSent(messageHash);
      }

      if (existingStatus != OUTBOX_STATUS_RECEIVED) {
        outboxL1L2MessageStatus[messageHash] = OUTBOX_STATUS_RECEIVED;
      }

      unchecked {
        i++;
      }
    }

    emit L1L2MessagesReceivedOnL2(_messageHashes);
  }
}

// SPDX-License-Identifier: OWNED BY ConsenSys Software Inc.
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../lib/Codec.sol";
import "../interfaces/IMessageService.sol";
import "../interfaces/IGenericErrors.sol";
import "../lib/PauseManager.sol";
import "../lib/RateLimiter.sol";
import "./L1MessageManager.sol";

/**
 * @title Contract to manage cross-chain messaging on L1.
 * @author ConsenSys Software Inc.
 */
abstract contract L1MessageService is
  Initializable,
  RateLimiter,
  L1MessageManager,
  PauseManager,
  IMessageService,
  IGenericErrors
{
  using CodecV2 for *;
  // @dev This is initialised to save user cost with existing slot.
  uint256 public nextMessageNumber;

  address private _messageSender;

  // Keep free storage slots for future implementation updates to avoid storage collision.
  uint256[50] private __gap;

  /**
   * @notice Initialises underlying message service dependencies.
   * @dev _messageSender is initialised to a non-zero value for gas efficiency on claiming.
   * @param _limitManagerAddress The address owning the rate limiting management role.
   * @param _pauseManagerAddress The address owning the pause management role.
   * @param _rateLimitPeriod The period to rate limit against.
   * @param _rateLimitAmount The limit allowed for withdrawing the period.
   **/
  function __MessageService_init(
    address _limitManagerAddress,
    address _pauseManagerAddress,
    uint256 _rateLimitPeriod,
    uint256 _rateLimitAmount
  ) public onlyInitializing {
    if (_limitManagerAddress == address(0)) {
      revert ZeroAddressNotAllowed();
    }

    if (_pauseManagerAddress == address(0)) {
      revert ZeroAddressNotAllowed();
    }

    __ERC165_init();
    __Context_init();
    __AccessControl_init();
    __PauseManager_init();
    __RateLimiter_init(_rateLimitPeriod, _rateLimitAmount);

    _grantRole(RATE_LIMIT_SETTER_ROLE, _limitManagerAddress);
    _grantRole(PAUSE_MANAGER_ROLE, _pauseManagerAddress);

    nextMessageNumber = 1;
    _messageSender = address(123456789);
  }

  /**
   * @notice Adds a message for sending cross-chain and emits MessageSent.
   * @dev The message number is preset (nextMessageNumber) and only incremented at the end if successful for the next caller.
   * @dev This function should be called with a msg.value = _value + _fee. The fee will be paid on the destination chain.
   * @param _to The address the message is intended for.
   * @param _fee The fee being paid for the message delivery.
   * @param _calldata The calldata to pass to the recipient.
   **/
  function sendMessage(
    address _to,
    uint256 _fee,
    bytes calldata _calldata
  ) external payable whenTypeNotPaused(L1_L2_PAUSE_TYPE) whenTypeNotPaused(GENERAL_PAUSE_TYPE) {
    if (_to == address(0)) {
      revert ZeroAddressNotAllowed();
    }

    if (_fee > msg.value) {
      revert ValueSentTooLow();
    }

    uint256 messageNumber = nextMessageNumber;
    uint256 valueSent = msg.value - _fee;

    bytes32 messageHash = keccak256(abi.encode(msg.sender, _to, _fee, valueSent, messageNumber, _calldata));

    // @dev Status check and revert is in the message manager
    _addL1L2MessageHash(messageHash);

    nextMessageNumber++;

    emit MessageSent(msg.sender, _to, _fee, valueSent, messageNumber, _calldata, messageHash);
  }

  /**
   * @notice Claims and delivers a cross-chain message.
   * @dev _feeRecipient can be set to address(0) to receive as msg.sender.
   * @dev _messageSender is set temporarily when claiming and reset post. Used in sender().
   * @dev _messageSender is reset to address(123456789) to be more gas efficient.
   * @param _from The address of the original sender.
   * @param _to The address the message is intended for.
   * @param _fee The fee being paid for the message delivery.
   * @param _value The value to be transferred to the destination address.
   * @param _feeRecipient The recipient for the fee.
   * @param _calldata The calldata to pass to the recipient.
   * @param _nonce The unique auto generated nonce used when sending the message.
   **/
  function claimMessage(
    address _from,
    address _to,
    uint256 _fee,
    uint256 _value,
    address payable _feeRecipient,
    bytes calldata _calldata,
    uint256 _nonce
  ) external whenTypeNotPaused(L2_L1_PAUSE_TYPE) whenTypeNotPaused(GENERAL_PAUSE_TYPE) {
    bytes32 messageHash = keccak256(abi.encode(_from, _to, _fee, _value, _nonce, _calldata));

    // @dev Status check and revert is in the message manager.
    _updateL2L1MessageStatusToClaimed(messageHash);

    _addUsedAmount(_fee + _value);

    _messageSender = _from;

    (bool success, bytes memory returnData) = _to.call{ value: _value }(_calldata);
    if (!success) {
      if (returnData.length > 0) {
        assembly {
          let data_size := mload(returnData)
          revert(add(32, returnData), data_size)
        }
      } else {
        revert MessageSendingFailed(_to);
      }
    }

    if (_fee > 0) {
      address feeReceiver = _feeRecipient == address(0) ? msg.sender : _feeRecipient;
      (bool feePaymentSuccess, ) = feeReceiver.call{ value: _fee }("");
      if (!feePaymentSuccess) {
        revert FeePaymentFailed(feeReceiver);
      }
    }

    _messageSender = address(123456789);

    emit MessageClaimed(messageHash);
  }

  /**
   * @notice Claims and delivers a cross-chain message.
   * @dev _messageSender is set temporarily when claiming.
   **/
  function sender() external view returns (address) {
    return _messageSender;
  }

  /**
   * @notice Function to receive funds for liquidity purposes.
   **/
  receive() external payable virtual {}
}

// SPDX-License-Identifier: OWNED BY ConsenSys Software Inc.
pragma solidity ^0.8.19;

/**
 * @title Decoding functions for message service anchoring and bytes slicing.
 * @author ConsenSys Software Inc.
 * @notice You can use this to slice bytes and extract anchoring hashes from calldata.
 **/
library CodecV2 {
  /**
   * @notice Decodes a collection of bytes32 (hashes) from the calldata of a transaction.
   * @dev Extracts and decodes skipping the function selector (selector is expected in the input).
   * @dev A check beforehand must be performed to confirm this is the correct type of transaction.
   * @param _calldataWithSelector The calldata for the transaction.
   * @return bytes32[] - array of message hashes.
   **/
  function _extractXDomainAddHashes(bytes memory _calldataWithSelector) internal pure returns (bytes32[] memory) {
    return abi.decode(_slice(_calldataWithSelector, 4, _calldataWithSelector.length - 4), (bytes32[]));
  }

  // Returns a slice of bytes. Taken from:
  // https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
  function _slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory tempBytes) {
    if (_bytes.length < 4) {
      revert();
    }

    if (_bytes.length < _start + _length) {
      revert();
    }

    assembly {
      switch iszero(_length)
      case 0 {
        // Get a location of some free memory and store it in tempBytes as
        // Solidity does for memory variables.
        tempBytes := mload(0x40)

        // The first word of the slice result is potentially a partial
        // word read from the original array. To read it, we calculate
        // the length of that partial word and start copying that many
        // bytes into the array. The first word we copy will start with
        // data we don't care about, but the last `lengthmod` bytes will
        // land at the beginning of the contents of the new array. When
        // we're done copying, we overwrite the full first word with
        // the actual length of the slice.
        let lengthmod := and(_length, 31)

        // The multiplication in the next line is necessary.
        // because when slicing multiples of 32 bytes (lengthmod == 0).
        // the following copy loop was copying the origin's length.
        // and then ending prematurely not copying everything it should.
        let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
        let end := add(mc, _length)

        for {
          // The multiplication in the next line has the same exact purpose.
          // as the one above.
          let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
        } lt(mc, end) {
          mc := add(mc, 0x20)
          cc := add(cc, 0x20)
        } {
          mstore(mc, mload(cc))
        }

        mstore(tempBytes, _length)

        //update free-memory pointer.
        //allocating the array padded to 32 bytes like the compiler does now.
        mstore(0x40, and(add(mc, 31), not(31)))
      }
      //if we want a zero-length slice let's just return a zero-length array.
      default {
        tempBytes := mload(0x40)
        //zero out the 32 bytes slice we are about to return.
        //we need to do it because Solidity does not garbage collect.
        mstore(tempBytes, 0)

        mstore(0x40, add(tempBytes, 0x20))
      }
    }
  }
}

// SPDX-License-Identifier: OWNED BY ConsenSys Software Inc.

pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../interfaces/IPauseManager.sol";

/**
 * @title Contract to manage cross-chain function pausing.
 * @author ConsenSys Software Inc.
 */
abstract contract PauseManager is Initializable, IPauseManager, AccessControlUpgradeable {
  bytes32 public constant PAUSE_MANAGER_ROLE = keccak256("PAUSE_MANAGER_ROLE");

  bytes32 public constant GENERAL_PAUSE_TYPE = keccak256("GENERAL_PAUSE_TYPE");
  bytes32 public constant L1_L2_PAUSE_TYPE = keccak256("L1_L2_PAUSE_TYPE");
  bytes32 public constant L2_L1_PAUSE_TYPE = keccak256("L2_L1_PAUSE_TYPE");
  bytes32 public constant PROVING_SYSTEM_PAUSE_TYPE = keccak256("PROVING_SYSTEM_PAUSE_TYPE");

  mapping(bytes32 => bool) public pauseTypeStatuses;

  uint256[10] private _gap;

  /**
   * @dev Modifier to make a function callable only when the type is not paused.
   *
   * Requirements:
   *
   * - The type must not be paused.
   */
  modifier whenTypeNotPaused(bytes32 _pauseType) {
    _requireTypeNotPaused(_pauseType);
    _;
  }

  /**
   * @dev Throws if the type is paused.
   * @param _pauseType The keccak256 pause type being checked,
   */
  function _requireTypeNotPaused(bytes32 _pauseType) internal view virtual {
    if (pauseTypeStatuses[_pauseType]) {
      revert IsPaused(_pauseType);
    }
  }

  /**
   * @dev Initializes the known types in unpaused state.
   */
  function __PauseManager_init() internal onlyInitializing {
    pauseTypeStatuses[L1_L2_PAUSE_TYPE] = false;
    pauseTypeStatuses[L2_L1_PAUSE_TYPE] = false;
    pauseTypeStatuses[PROVING_SYSTEM_PAUSE_TYPE] = false;
  }

  /**
   * @notice Pauses functionality by specific type.
   * @dev Requires PAUSE_MANAGER_ROLE.
   * @param _pauseType keccak256 pause type.
   **/
  function pauseByType(bytes32 _pauseType) external onlyRole(PAUSE_MANAGER_ROLE) {
    pauseTypeStatuses[_pauseType] = true;
    emit Paused(_msgSender(), _pauseType);
  }

  /**
   * @notice Unpauses functionality by specific type.
   * @dev Requires PAUSE_MANAGER_ROLE.
   * @param _pauseType keccak256 pause type.
   **/
  function unPauseByType(bytes32 _pauseType) external onlyRole(PAUSE_MANAGER_ROLE) {
    pauseTypeStatuses[_pauseType] = false;
    emit UnPaused(_msgSender(), _pauseType);
  }
}

// SPDX-License-Identifier: OWNED BY ConsenSys Software Inc.
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../interfaces/IRateLimiter.sol";

/**
 * @title Rate Limiter by period and amount using the block timestamp.
 * @author ConsenSys Software Inc.
 * @notice You can use this control numeric limits over a period using timestamp.
 **/
contract RateLimiter is Initializable, IRateLimiter, AccessControlUpgradeable {
  bytes32 public constant RATE_LIMIT_SETTER_ROLE = keccak256("RATE_LIMIT_SETTER_ROLE");

  uint256 public periodInSeconds; // how much time before limit resets.
  uint256 public limitInWei; // max ether to withdraw per period.

  // @dev Public for ease of consumption.
  // @notice The time at which the current period ends at.
  uint256 public currentPeriodEnd;

  // @dev Public for ease of consumption.
  // @notice Amounts already withdrawn this period.
  uint256 public currentPeriodAmountInWei;

  uint256[10] private _gap;

  /**
   * @notice Initialises the limits and period for the rate limiter.
   * @param _periodInSeconds The length of the period in seconds.
   * @param _limitInWei The limit allowed in the period in Wei.
   **/
  function __RateLimiter_init(uint256 _periodInSeconds, uint256 _limitInWei) internal {
    if (_periodInSeconds == 0) {
      revert PeriodIsZero();
    }

    if (_limitInWei == 0) {
      revert LimitIsZero();
    }

    periodInSeconds = _periodInSeconds;
    limitInWei = _limitInWei;
    currentPeriodEnd = block.timestamp + _periodInSeconds;
  }

  /**
   * @notice Increments the amount used in the period.
   * @dev The amount determining logic is external to this (e.g. fees are included when calling here).
   * @dev Reverts if the limit is breached.
   * @param _usedAmount The amount used to be added.
   **/
  function _addUsedAmount(uint256 _usedAmount) internal {
    uint256 currentPeriodAmountTemp;

    if (currentPeriodEnd < block.timestamp) {
      // Update period before proceeding
      currentPeriodEnd = block.timestamp + periodInSeconds;
      currentPeriodAmountTemp = _usedAmount;
    } else {
      currentPeriodAmountTemp = currentPeriodAmountInWei + _usedAmount;
    }

    if (currentPeriodAmountTemp > limitInWei) {
      revert RateLimitExceeded();
    }

    currentPeriodAmountInWei = currentPeriodAmountTemp;
  }

  /**
   * @notice Resets the rate limit amount.
   * @dev If the used amount is higher, it is set to the limit to avoid confusion/issues.
   * @dev Only the RATE_LIMIT_SETTER_ROLE is allowed to execute this function.
   * @dev Emits the LimitAmountChanged event.
   * @param _amount The amount to reset the limit to.
   **/
  function resetRateLimitAmount(uint256 _amount) external onlyRole(RATE_LIMIT_SETTER_ROLE) {
    bool amountUsedLoweredToLimit;

    if (_amount < currentPeriodAmountInWei) {
      currentPeriodAmountInWei = _amount;
      amountUsedLoweredToLimit = true;
    }

    limitInWei = _amount;

    emit LimitAmountChange(_msgSender(), _amount, amountUsedLoweredToLimit);
  }

  /**
   * @notice Resets the amount used to zero.
   * @dev Only the RATE_LIMIT_SETTER_ROLE is allowed to execute this function.
   * @dev Emits the AmountUsedInPeriodReset event.
   **/
  function resetAmountUsedInPeriod() external onlyRole(RATE_LIMIT_SETTER_ROLE) {
    currentPeriodAmountInWei = 0;

    emit AmountUsedInPeriodReset(_msgSender());
  }
}

// SPDX-License-Identifier: Apache-2.0

/**
 * @author Hamdi Allam [email protected]
 * @notice Please reach out with any questions or concerns.
 */
pragma solidity ^0.8.19;

error NotList();
error WrongBytesLength();
error NoNext();

library RLPReader {
  uint8 constant STRING_SHORT_START = 0x80;
  uint8 constant STRING_LONG_START = 0xb8;
  uint8 constant LIST_SHORT_START = 0xc0;
  uint8 constant LIST_LONG_START = 0xf8;
  uint8 constant WORD_SIZE = 32;

  struct RLPItem {
    uint256 len;
    uint256 memPtr;
  }

  struct Iterator {
    RLPItem item; // Item that's being iterated over.
    uint256 nextPtr; // Position of the next item in the list.
  }

  /**
   * @dev Returns the next element in the iteration. Reverts if it has no next element.
   * @param _self The iterator.
   * @return nextItem The next element in the iteration.
   */
  function _next(Iterator memory _self) internal pure returns (RLPItem memory nextItem) {
    if (!_hasNext(_self)) {
      revert NoNext();
    }

    uint256 ptr = _self.nextPtr;
    uint256 itemLength = _itemLength(ptr);
    _self.nextPtr = ptr + itemLength;

    nextItem.len = itemLength;
    nextItem.memPtr = ptr;
  }

  /**
   * @dev Returns the number 'skiptoNum' element in the iteration.
   * @param _self The iterator.
   * @param _skipToNum Element position in the RLP item iterator to return.
   * @return item The number 'skipToNum' element in the iteration.
   */
  function _skipTo(Iterator memory _self, uint256 _skipToNum) internal pure returns (RLPItem memory item) {
    uint256 ptr = _self.nextPtr;
    uint256 itemLength = _itemLength(ptr);
    _self.nextPtr = ptr + itemLength;

    for (uint256 i; i < _skipToNum - 1; ) {
      ptr = _self.nextPtr;
      itemLength = _itemLength(ptr);
      _self.nextPtr = ptr + itemLength;

      unchecked {
        i++;
      }
    }

    item.len = itemLength;
    item.memPtr = ptr;
  }

  /**
   * @dev Returns true if the iteration has more elements.
   * @param _self The iterator.
   * @return True if the iteration has more elements.
   */
  function _hasNext(Iterator memory _self) internal pure returns (bool) {
    RLPItem memory item = _self.item;
    return _self.nextPtr < item.memPtr + item.len;
  }

  /**
   * @param item RLP encoded bytes.
   * @return newItem The RLP item.
   */
  function _toRlpItem(bytes memory item) internal pure returns (RLPItem memory newItem) {
    uint256 memPtr;

    assembly {
      memPtr := add(item, 0x20)
    }

    newItem.len = item.length;
    newItem.memPtr = memPtr;
  }

  /**
   * @dev Creates an iterator. Reverts if item is not a list.
   * @param _self The RLP item.
   * @return iterator 'Iterator' over the item.
   */
  function _iterator(RLPItem memory _self) internal pure returns (Iterator memory iterator) {
    if (!_isList(_self)) {
      revert NotList();
    }

    uint256 ptr = _self.memPtr + _payloadOffset(_self.memPtr);
    iterator.item = _self;
    iterator.nextPtr = ptr;
  }

  /**
   * @param _item The RLP item.
   * @return (memPtr, len) Tuple: Location of the item's payload in memory.
   */
  function _payloadLocation(RLPItem memory _item) internal pure returns (uint256, uint256) {
    uint256 offset = _payloadOffset(_item.memPtr);
    uint256 memPtr = _item.memPtr + offset;
    uint256 len = _item.len - offset; // data length
    return (memPtr, len);
  }

  /**
   * @param _item The RLP item.
   * @return Indicator whether encoded payload is a list.
   */
  function _isList(RLPItem memory _item) internal pure returns (bool) {
    if (_item.len == 0) return false;

    uint8 byte0;
    uint256 memPtr = _item.memPtr;
    assembly {
      byte0 := byte(0, mload(memPtr))
    }

    if (byte0 < LIST_SHORT_START) return false;
    return true;
  }

  /**
   * @param _item The RLP item.
   * @return result Returns the item as an address.
   */
  function _toAddress(RLPItem memory _item) internal pure returns (address) {
    // 1 byte for the length prefix
    if (_item.len != 21) {
      revert WrongBytesLength();
    }

    return address(uint160(_toUint(_item)));
  }

  /**
   * @param _item The RLP item.
   * @return result Returns the item as a uint256.
   */
  function _toUint(RLPItem memory _item) internal pure returns (uint256 result) {
    if (_item.len == 0 || _item.len > 33) {
      revert WrongBytesLength();
    }

    (uint256 memPtr, uint256 len) = _payloadLocation(_item);

    assembly {
      result := mload(memPtr)

      // Shfit to the correct location if neccesary.
      if lt(len, 32) {
        result := div(result, exp(256, sub(32, len)))
      }
    }
  }

  /**
   * @param _item The RLP item.
   * @return result Returns the item as bytes.
   */
  function _toBytes(RLPItem memory _item) internal pure returns (bytes memory result) {
    if (_item.len == 0) {
      revert WrongBytesLength();
    }

    (uint256 memPtr, uint256 len) = _payloadLocation(_item);
    result = new bytes(len);

    uint256 destPtr;
    assembly {
      destPtr := add(0x20, result)
    }

    _copy(memPtr, destPtr, len);
  }

  /*
   * Private Helpers
   */

  /**
   * @param _memPtr Item memory pointer.
   * @return Entire RLP item byte length.
   */
  function _itemLength(uint256 _memPtr) private pure returns (uint256) {
    uint256 itemLen;
    uint256 byte0;
    assembly {
      byte0 := byte(0, mload(_memPtr))
    }

    if (byte0 < STRING_SHORT_START) itemLen = 1;
    else if (byte0 < STRING_LONG_START) itemLen = byte0 - STRING_SHORT_START + 1;
    else if (byte0 < LIST_SHORT_START) {
      assembly {
        let byteLen := sub(byte0, 0xb7) // # Of bytes the actual length is.
        _memPtr := add(_memPtr, 1) // Skip over the first byte.

        /* 32 byte word size */
        let dataLen := div(mload(_memPtr), exp(256, sub(32, byteLen))) // Right shifting to get the len.
        itemLen := add(dataLen, add(byteLen, 1))
      }
    } else if (byte0 < LIST_LONG_START) {
      itemLen = byte0 - LIST_SHORT_START + 1;
    } else {
      assembly {
        let byteLen := sub(byte0, 0xf7)
        _memPtr := add(_memPtr, 1)

        let dataLen := div(mload(_memPtr), exp(256, sub(32, byteLen))) // Right shifting to the correct length.
        itemLen := add(dataLen, add(byteLen, 1))
      }
    }

    return itemLen;
  }

  /**
   * @param _memPtr Item memory pointer.
   * @return Number of bytes until the data.
   */
  function _payloadOffset(uint256 _memPtr) private pure returns (uint256) {
    uint256 byte0;
    assembly {
      byte0 := byte(0, mload(_memPtr))
    }

    if (byte0 < STRING_SHORT_START) return 0;
    else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) return 1;
    else if (byte0 < LIST_SHORT_START)
      // being explicit
      return byte0 - (STRING_LONG_START - 1) + 1;
    else return byte0 - (LIST_LONG_START - 1) + 1;
  }

  /**
   * @param _src Pointer to source.
   * @param _dest Pointer to destination.
   * @param _len Amount of memory to copy from the source.
   */
  function _copy(uint256 _src, uint256 _dest, uint256 _len) private pure {
    if (_len == 0) return;

    // copy as many word sizes as possible
    for (; _len >= WORD_SIZE; _len -= WORD_SIZE) {
      assembly {
        mstore(_dest, mload(_src))
      }

      _src += WORD_SIZE;
      _dest += WORD_SIZE;
    }

    if (_len > 0) {
      // Left over bytes. Mask is used to remove unwanted bytes from the word.
      uint256 mask = 256 ** (WORD_SIZE - _len) - 1;
      assembly {
        let srcpart := and(mload(_src), not(mask)) // Zero out src.
        let destpart := and(mload(_dest), mask) // Retrieve the bytes.
        mstore(_dest, or(destpart, srcpart))
      }
    }
  }
}

// SPDX-License-Identifier: OWNED BY ConsenSys Software Inc.
pragma solidity ^0.8.19;

import "./Rlp.sol";

using RLPReader for RLPReader.RLPItem;
using RLPReader for RLPReader.Iterator;
using RLPReader for bytes;

/*
 * dev Thrown when the transaction data length is too short.
 */
error TransactionShort();

/*
 * dev Thrown when the transaction type is unknown.
 */
error UnknownTransactionType();

/*
 * dev Thrown when the decoding action is invalid.
 */

error InvalidAction();

/**
 * @title Contract to decode RLP formatted transactions.
 * @author ConsenSys Software Inc.
 */
library TransactionDecoder {
  /**
   * @notice Decodes the transaction extracting the calldata.
   * @param _transaction The RLP transaction.
   * @return data Returns the transaction calldata as bytes.
   */
  function decodeTransaction(bytes calldata _transaction) external pure returns (bytes memory) {
    if (_transaction.length < 1) {
      revert TransactionShort();
    }

    bytes1 version = _transaction[0];

    if (version == 0x01) {
      return _decodeEIP2930Transaction(_transaction);
    }

    if (version == 0x02) {
      return _decodeEIP1559Transaction(_transaction);
    }

    if (version >= 0xc0) {
      return _decodeLegacyTransaction(_transaction);
    }

    revert UnknownTransactionType();
  }

  /**
   * @notice Decodes the EIP1559 transaction extracting the calldata.
   * @param _transaction The RLP transaction.
   * @return data Returns the transaction calldata as bytes.
   */
  function _decodeEIP1559Transaction(bytes calldata _transaction) private pure returns (bytes memory data) {
    bytes memory txData = _transaction[1:]; // skip the version byte

    RLPReader.RLPItem memory rlp = txData._toRlpItem();
    RLPReader.Iterator memory it = rlp._iterator();

    data = it._skipTo(8)._toBytes();
  }

  /**
   * @notice Decodes the EIP29230 transaction extracting the calldata.
   * @param _transaction The RLP transaction.
   * @return data Returns the transaction calldata as bytes.
   */
  function _decodeEIP2930Transaction(bytes calldata _transaction) private pure returns (bytes memory data) {
    bytes memory txData = _transaction[1:]; // skip the version byte

    RLPReader.RLPItem memory rlp = txData._toRlpItem();
    RLPReader.Iterator memory it = rlp._iterator();

    data = it._skipTo(7)._toBytes();
  }

  /**
   * @notice Decodes the legacy transaction extracting the calldata.
   * @param _transaction The RLP transaction.
   * @return data Returns the transaction calldata as bytes.
   */
  function _decodeLegacyTransaction(bytes calldata _transaction) private pure returns (bytes memory data) {
    bytes memory txData = _transaction;

    RLPReader.RLPItem memory rlp = txData._toRlpItem();
    RLPReader.Iterator memory it = rlp._iterator();

    data = it._skipTo(6)._toBytes();
  }
}

// SPDX-License-Identifier: OWNED BY ConsenSys Software Inc.
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./messageService/l1/L1MessageService.sol";
import "./messageService/lib/TransactionDecoder.sol";
import "./IZkEvmV2.sol";
import "./messageService/interfaces/IPlonkVerifier.sol";

/**
 * @title Contract to manage cross-chain messaging on L1 and rollup proving.
 * @author ConsenSys Software Inc.
 */
contract ZkEvmV2 is IZkEvmV2, Initializable, AccessControlUpgradeable, L1MessageService {
  using TransactionDecoder for *;

  uint256 private constant MODULO_R = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
  bytes32 internal constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  uint256 public currentTimestamp;
  uint256 public currentL2BlockNumber;

  mapping(uint256 => bytes32) public stateRootHashes;
  mapping(uint256 => address) public verifiers;

  uint256[50] private __gap;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice Initializes zkEvm and underlying service dependencies.
   * @dev DEFAULT_ADMIN_ROLE is set for the security council.
   * @dev OPERATOR_ROLE is set for operators.
   * @param _initialStateRootHash The initial hash at migration used for proof verification.
   * @param _initialL2BlockNumber The initial block number at migration.
   * @param _defaultVerifier The default verifier for rollup proofs.
   * @param _securityCouncil The address for the security council performing admin operations.
   * @param _operators The allowed rollup operators at initialization.
   * @param _rateLimitPeriodInSeconds The period in which withdrawal amounts and fees will be accumulated.
   * @param _rateLimitAmountInWei The limit allowed for withdrawing in the period.
   **/
  function initialize(
    bytes32 _initialStateRootHash,
    uint256 _initialL2BlockNumber,
    address _defaultVerifier,
    address _securityCouncil,
    address[] calldata _operators,
    uint256 _rateLimitPeriodInSeconds,
    uint256 _rateLimitAmountInWei
  ) public initializer {
    if (_defaultVerifier == address(0)) {
      revert ZeroAddressNotAllowed();
    }

    for (uint256 i; i < _operators.length; ) {
      if (_operators[i] == address(0)) {
        revert ZeroAddressNotAllowed();
      }
      _grantRole(OPERATOR_ROLE, _operators[i]);
      unchecked {
        i++;
      }
    }

    _grantRole(DEFAULT_ADMIN_ROLE, _securityCouncil);

    __MessageService_init(_securityCouncil, _securityCouncil, _rateLimitPeriodInSeconds, _rateLimitAmountInWei);

    verifiers[0] = _defaultVerifier;
    currentL2BlockNumber = _initialL2BlockNumber;
    stateRootHashes[_initialL2BlockNumber] = _initialStateRootHash;
  }

  /**
   * @notice Adds or updates the verifier contract address for a proof type.
   * @dev DEFAULT_ADMIN_ROLE is required to execute.
   * @param _newVerifierAddress The address for the verifier contract.
   * @param _proofType The proof type being set/updated.
   **/
  function setVerifierAddress(address _newVerifierAddress, uint256 _proofType) external onlyRole(DEFAULT_ADMIN_ROLE) {
    if (_newVerifierAddress == address(0)) {
      revert ZeroAddressNotAllowed();
    }
    verifiers[_proofType] = _newVerifierAddress;
  }

  /**
   * @notice Finalizes blocks without using a proof.
   * @dev DEFAULT_ADMIN_ROLE is required to execute.
   * @param _blocksData The full BlockData collection - block, transaction and log data.
   **/
  function finalizeBlocksWithoutProof(
    BlockData[] calldata _blocksData
  ) external whenTypeNotPaused(GENERAL_PAUSE_TYPE) onlyRole(DEFAULT_ADMIN_ROLE) {
    _finalizeBlocks(_blocksData, new bytes(0), 0, bytes32(0), false);
  }

  /**
   * @notice Finalizes blocks using a proof.
   * @dev OPERATOR_ROLE is required to execute.
   * @dev If the verifier based on proof type is not found, it reverts.
   * @param _blocksData The full BlockData collection - block, transaction and log data.
   * @param _proof The proof to be verified with the proof type verifier contract.
   * @param _proofType The proof type to determine which verifier contract to use.
   * @param _parentStateRootHash The starting roothash for the last known block.
   **/
  function finalizeBlocks(
    BlockData[] calldata _blocksData,
    bytes calldata _proof,
    uint256 _proofType,
    bytes32 _parentStateRootHash
  )
    external
    whenTypeNotPaused(PROVING_SYSTEM_PAUSE_TYPE)
    whenTypeNotPaused(GENERAL_PAUSE_TYPE)
    onlyRole(OPERATOR_ROLE)
  {
    if (stateRootHashes[currentL2BlockNumber] != _parentStateRootHash) {
      revert StartingRootHashDoesNotMatch();
    }

    _finalizeBlocks(_blocksData, _proof, _proofType, _parentStateRootHash, true);
  }

  /**
   * @notice Finalizes blocks with or without using a proof depending on _shouldProve
   * @dev If the verifier based on proof type is not found, it reverts.
   * @param _blocksData The full BlockData collection - block, transaction and log data.
   * @param _proof The proof to be verified with the proof type verifier contract.
   * @param _proofType The proof type to determine which verifier contract to use.
   * @param _parentStateRootHash The starting roothash for the last known block.
   **/
  function _finalizeBlocks(
    BlockData[] calldata _blocksData,
    bytes memory _proof,
    uint256 _proofType,
    bytes32 _parentStateRootHash,
    bool _shouldProve
  ) private {
    uint256 currentBlockNumberTemp = currentL2BlockNumber;
    uint256 firstBlockNumber = currentBlockNumberTemp + 1;

    uint256[] memory timestampHashes = new uint256[](_blocksData.length);
    bytes32[] memory blockHashes = new bytes32[](_blocksData.length);
    bytes32[] memory hashOfRootHashes = new bytes32[](_blocksData.length + 1);

    hashOfRootHashes[0] = _parentStateRootHash;

    bytes32 hashOfTxHashes;
    bytes32 hashOfLogHashes;

    for (uint256 i; i < _blocksData.length; ) {
      BlockData calldata blockInfo = _blocksData[i];

      if (blockInfo.l2BlockTimestamp >= block.timestamp) {
        revert BlockTimestampError();
      }

      hashOfTxHashes = _processBlockTransactions(blockInfo.transactions, blockInfo.batchReceptionIndices);
      hashOfLogHashes = _processBlockLogs(blockInfo.l2l1logs);

      ++currentBlockNumberTemp;
      stateRootHashes[currentBlockNumberTemp] = blockInfo.blockRootHash;

      blockHashes[i] = keccak256(
        abi.encodePacked(hashOfTxHashes, hashOfLogHashes, keccak256(abi.encodePacked(blockInfo.batchReceptionIndices)))
      );

      timestampHashes[i] = blockInfo.l2BlockTimestamp;
      hashOfRootHashes[i + 1] = blockInfo.blockRootHash;

      emit BlockFinalized(currentBlockNumberTemp, blockInfo.blockRootHash);

      unchecked {
        i++;
      }
    }

    currentTimestamp = _blocksData[_blocksData.length - 1].l2BlockTimestamp;
    currentL2BlockNumber = currentBlockNumberTemp;

    if (_shouldProve) {
      _verifyProof(
        uint256(
          keccak256(
            abi.encode(
              keccak256(abi.encodePacked(blockHashes)),
              firstBlockNumber,
              keccak256(abi.encodePacked(timestampHashes)),
              keccak256(abi.encodePacked(hashOfRootHashes))
            )
          )
        ) % MODULO_R,
        _proofType,
        _proof,
        _parentStateRootHash
      );
    }
  }

  /**
   * @notice Hashes all transactions individually and then hashes the packed hash array.
   * @dev Updates the outbox status on L1 as received.
   * @param _transactions The transactions in a particular block.
   * @param _batchReceptionIndices The indexes where the transaction type is the L1->L2 achoring message hashes transaction.
   **/
  function _processBlockTransactions(
    bytes[] calldata _transactions,
    uint16[] calldata _batchReceptionIndices
  ) internal returns (bytes32 hashOfTxHashes) {
    bytes32[] memory transactionHashes = new bytes32[](_transactions.length);

    if (_transactions.length == 0) {
      revert EmptyBlock();
    }

    for (uint256 i; i < _batchReceptionIndices.length; ) {
      _updateL1L2MessageStatusToReceived(
        CodecV2._extractXDomainAddHashes(TransactionDecoder.decodeTransaction(_transactions[_batchReceptionIndices[i]]))
      );

      unchecked {
        i++;
      }
    }

    for (uint256 i; i < _transactions.length; ) {
      transactionHashes[i] = keccak256(_transactions[i]);

      unchecked {
        i++;
      }
    }
    hashOfTxHashes = keccak256(abi.encodePacked(transactionHashes));
  }

  /**
   * @notice Hashes all logs individually and then hashes the packed hash array.
   * @dev Also adds L2->L1 sent message hashes for later claiming.
   * @param _logs The logs in a particular block.
   **/
  function _processBlockLogs(bytes[] calldata _logs) internal returns (bytes32 hashOfLogHashes) {
    bytes32[] memory logHashes = new bytes32[](_logs.length);
    bytes32 messageHash;

    for (uint256 i; i < _logs.length; ) {
      (, , , , , , messageHash) = abi.decode(_logs[i], (address, address, uint256, uint256, uint256, bytes, bytes32));
      _addL2L1MessageHash(messageHash);
      logHashes[i] = keccak256(_logs[i]);

      unchecked {
        i++;
      }
    }
    hashOfLogHashes = keccak256(abi.encodePacked(logHashes));
  }

  /**
   * @notice Verifies the proof with locally computed public inputs.
   * @dev If the verifier based on proof type is not found, it reverts with InvalidProofType.
   * @param _publicInputHash The full BlockData collection - block, transaction and log data.
   * @param _proofType The proof type to determine which verifier contract to use.
   * @param _proof The proof to be verified with the proof type verifier contract.
   * @param _parentStateRootHash The beginning roothash to start with.
   **/
  function _verifyProof(
    uint256 _publicInputHash,
    uint256 _proofType,
    bytes memory _proof,
    bytes32 _parentStateRootHash
  ) private {
    uint256[] memory input = new uint256[](1);
    input[0] = _publicInputHash;

    address verifierToUse = verifiers[_proofType];
    if (verifierToUse == address(0)) {
      revert InvalidProofType();
    }

    bool success = IPlonkVerifier(verifierToUse).Verify(_proof, input);
    if (!success) {
      revert InvalidProof();
    }

    emit BlocksVerificationDone(currentL2BlockNumber, _parentStateRootHash, stateRootHashes[currentL2BlockNumber]);
  }
}