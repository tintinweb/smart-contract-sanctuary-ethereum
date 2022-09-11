// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/// @notice Base contract that provides an OWNER_ROLE and convenience function/modifier for
///   checking sender against this role. Inherting contracts must set up this role using
///   `_setupRole` and `_setRoleAdmin`.
contract Administrator is AccessControlUpgradeable {
  /// @notice ID for OWNER_ROLE
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

  /// @notice Determine whether msg.sender has OWNER_ROLE
  /// @return isAdmin True when msg.sender has OWNER_ROLE
  function isAdmin() public view returns (bool) {
    return hasRole(OWNER_ROLE, msg.sender);
  }

  modifier onlyAdmin() {
    /// @dev AD: Must have admin role to perform this action
    require(isAdmin(), "AD");
    _;
  }
}

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
pragma solidity 0.8.5;

import "../external/ERC721PresetMinterPauserAutoId.sol";
import "../interfaces/IOvenueConfig.sol";
import "../libraries/OvenueConfigHelper.sol";
import "../interfaces/IOvenueJuniorPool.sol";
import "../interfaces/IOvenueJuniorLP.sol";
import "./Administrator.sol";

/**
 * @title PoolTokens
 * @notice PoolTokens is an ERC721 compliant contract, which can represent
 *  junior tranche or senior tranche shares of any of the borrower pools.
 * @author Ovenue
 */
contract OvenueJuniorLP is
    IOvenueJuniorLP,
    ERC721PresetMinterPauserAutoIdUpgradeSafe,
    Administrator
{
    error ExceededRedeemAmount();
    error OnlyBeCalledByPool();

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    IOvenueConfig public config;
    using OvenueConfigHelper for IOvenueConfig;

    string public extendTokenURI;

    struct PoolInfo {
        uint256 totalMinted;
        uint256 totalPrincipalRedeemed;
        bool created;
    }

    // tokenId => tokenInfo
    mapping(uint256 => TokenInfo) public tokens;
    // poolAddress => poolInfo
    mapping(address => PoolInfo) public pools;

    /*
    We are using our own initializer function so that OZ doesn't automatically
    set owner as msg.sender. Also, it lets us set our config contract
  */
    // solhint-disable-next-line func-name-mixedcase
    function initialize(address owner, IOvenueConfig _config)
        external
        initializer
    {
        require(
            owner != address(0) && address(_config) != address(0),
            "Owner and config addresses cannot be empty"
        );

        __Context_init_unchained();
        __AccessControl_init_unchained();
        __ERC165_init_unchained();
        // This is setting name and symbol of the NFT's
        __ERC721_init_unchained("Ovenue V2 Junior LP Tokens", "OVN-V2-PT");
        __Pausable_init_unchained();
        __ERC721Pausable_init_unchained();

        config = _config;

        _setupRole(PAUSER_ROLE, owner);
        _setupRole(OWNER_ROLE, owner);

        _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    }

    /**
     * @notice Called by pool to create a debt position in a particular tranche and amount
     * @param params Struct containing the tranche and the amount
     * @param to The address that should own the position
     * @return tokenId The token ID (auto-incrementing integer across all pools)
     */
    function mint(MintParams calldata params, address to)
        external
        virtual
        override
        onlyPool
        whenNotPaused
        returns (uint256 tokenId)
    {
        address poolAddress = _msgSender();
        tokenId = _createToken(params, poolAddress);
        _mint(to, tokenId);
        config
            .getJuniorRewards()
            .setPoolTokenAccRewardsPerPrincipalDollarAtMint(
                _msgSender(),
                tokenId
            );
        emit TokenMinted(
            to,
            poolAddress,
            tokenId,
            params.principalAmount,
            params.tranche
        );
        return tokenId;
    }

      /**
       * @notice Updates a token to reflect the principal and interest amounts that have been redeemed.
       * @param tokenId The token id to update (must be owned by the pool calling this function)
       * @param principalRedeemed The incremental amount of principal redeemed (cannot be more than principal deposited)
       * @param interestRedeemed The incremental amount of interest redeemed
       */
      function redeem(
        uint256 tokenId,
        uint256 principalRedeemed,
        uint256 interestRedeemed
      ) external virtual override onlyPool whenNotPaused {
        TokenInfo storage token = tokens[tokenId];
        address poolAddr = token.pool;
        require(token.pool != address(0), "Invalid tokenId");

        if (_msgSender() != poolAddr) {
            revert OnlyBeCalledByPool();
        }
        
        PoolInfo storage pool = pools[poolAddr];
        pool.totalPrincipalRedeemed = pool.totalPrincipalRedeemed + principalRedeemed;
        require(pool.totalPrincipalRedeemed <= pool.totalMinted, "Cannot redeem more than we minted");

        token.principalRedeemed = token.principalRedeemed + principalRedeemed;
        // require(
        //   token.principalRedeemed <= token.principalAmount,
        //   "Cannot redeem more than principal-deposited amount for token"
        // );
        if (token.principalRedeemed > token.principalAmount) {
            revert ExceededRedeemAmount();
        }
        token.interestRedeemed = token.interestRedeemed + interestRedeemed;

        emit TokenRedeemed(ownerOf(tokenId), poolAddr, tokenId, principalRedeemed, interestRedeemed, token.tranche);
      }

      /** @notice reduce a given pool token's principalAmount and principalRedeemed by a specified amount
       *  @dev uses safemath to prevent underflow
       *  @dev this function is only intended for use as part of the v2.6.0 upgrade
       *    to rectify a bug that allowed users to create a PoolToken that had a
       *    larger amount of principal than they actually made available to the
       *    borrower.  This bug is fixed in v2.6.0 but still requires past pool tokens
       *    to have their principal redeemed and deposited to be rectified.
       *  @param tokenId id of token to decrease
       *  @param amount amount to decrease by
       */
      function reducePrincipalAmount(uint256 tokenId, uint256 amount) external onlyAdmin {
        TokenInfo storage tokenInfo = tokens[tokenId];
        tokenInfo.principalAmount = tokenInfo.principalAmount - amount;
        tokenInfo.principalRedeemed = tokenInfo.principalRedeemed - amount;
      }

      /**
       * @notice Decrement a token's principal amount. This is different from `redeem`, which captures changes to
       *   principal and/or interest that occur when a loan is in progress.
       * @param tokenId The token id to update (must be owned by the pool calling this function)
       * @param principalAmount The incremental amount of principal redeemed (cannot be more than principal deposited)
       */
      function withdrawPrincipal(uint256 tokenId, uint256 principalAmount)
        external
        virtual
        override
        onlyPool
        whenNotPaused
      {
        TokenInfo storage token = tokens[tokenId];
        address poolAddr = token.pool;
        require(_msgSender() == poolAddr, "Invalid sender");
        require(token.principalRedeemed == 0, "Token redeemed");
        require(token.principalAmount >= principalAmount, "Insufficient principal");

        PoolInfo storage pool = pools[poolAddr];
        pool.totalMinted = pool.totalMinted - principalAmount;
        require(pool.totalPrincipalRedeemed <= pool.totalMinted, "Cannot withdraw more than redeemed");

        token.principalAmount = token.principalAmount - principalAmount;

        emit TokenPrincipalWithdrawn(ownerOf(tokenId), poolAddr, tokenId, principalAmount, token.tranche);
      }

      /**
       * @dev Burns a specific ERC721 token, and removes the data from our mappings
       * @param tokenId uint256 id of the ERC721 token to be burned.
       */
      function burn(uint256 tokenId) external virtual override whenNotPaused {
        TokenInfo memory token = _getTokenInfo(tokenId);
        bool canBurn = _isApprovedOrOwner(_msgSender(), tokenId);
        bool fromTokenPool = _validPool(_msgSender()) && token.pool == _msgSender();
        address owner = ownerOf(tokenId);
        require(canBurn || fromTokenPool, "ERC721Burnable: caller cannot burn this token");
        require(token.principalRedeemed == token.principalAmount, "Can only burn fully redeemed tokens");
        _destroyAndBurn(tokenId);
        emit TokenBurned(owner, token.pool, tokenId);
      }

      function getTokenInfo(uint256 tokenId) external view virtual override returns (TokenInfo memory) {
        return _getTokenInfo(tokenId);
      }

    /**
     * @notice Called by the GoldfinchFactory to register the pool as a valid pool. Only valid pools can mint/redeem
     * tokens
     * @param newPool The address of the newly created pool
     */
    function onPoolCreated(address newPool)
        external
        override
        onlyOvenueFactory
    {
        pools[newPool].created = true;
    }

    /**
     * @notice Returns a boolean representing whether the spender is the owner or the approved spender of the token
     * @param spender The address to check
     * @param tokenId The token id to check for
     * @return True if approved to redeem/transfer/burn the token, false if not
     */
    function isApprovedOrOwner(address spender, uint256 tokenId)
        external
        view
        override
        returns (bool)
    {
        return _isApprovedOrOwner(spender, tokenId);
    }

    function validPool(address sender)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _validPool(sender);
    }

    function _createToken(MintParams calldata params, address poolAddress)
        internal
        returns (uint256 tokenId)
    {
        PoolInfo storage pool = pools[poolAddress];

        _tokenIdTracker++;
        tokenId = _tokenIdTracker;
        tokens[tokenId] = TokenInfo({
            pool: poolAddress,
            tranche: params.tranche,
            principalAmount: params.principalAmount,
            principalRedeemed: 0,
            interestRedeemed: 0
        });
        pool.totalMinted = pool.totalMinted + params.principalAmount;
        return tokenId;
    }

    function _destroyAndBurn(uint256 tokenId) internal {
        delete tokens[tokenId];
        _burn(tokenId);
    }

    function _validPool(address poolAddress)
        internal
        view
        virtual
        returns (bool)
    {
        return pools[poolAddress].created;
    }

    function _getTokenInfo(uint256 tokenId)
        internal
        view
        returns (TokenInfo memory)
    {
        return tokens[tokenId];
    }

    function _baseURI() internal view override returns (string memory) {
        return extendTokenURI;
    }

    function setBaseURI(string calldata baseURI_) external onlyAdmin {
        extendTokenURI = baseURI_;
    }

    function supportsInterface(bytes4 id)
        public
        pure
        override(IERC165Upgradeable, AccessControlUpgradeable, ERC721PresetMinterPauserAutoIdUpgradeSafe)
        returns (bool)
    {
        return (id == _INTERFACE_ID_ERC721 ||
            id == _INTERFACE_ID_ERC721_METADATA ||
            id == _INTERFACE_ID_ERC721_ENUMERABLE ||
            id == _INTERFACE_ID_ERC165);
    }

    modifier onlyOvenueFactory() {
        require(
            _msgSender() == config.ovenueFactoryAddress(),
            "Only Ovenue factory is allowed"
        );
        _;
    }

    modifier onlyPool() {
        require(_validPool(_msgSender()), "Invalid pool!");
        _;
    }
}

// SPDX-License-Identifier: MIT
// solhint-disable
/*
  This is copied from OZ preset: https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/release-v3.0.0/contracts/presets/ERC721PresetMinterPauserAutoId.sol
  Alterations:
   * Make the counter public, so that we can use it in our custom mint function
   * Removed ERC721Burnable parent contract, but added our own custom burn function.
   * Removed original "mint" function, because we have a custom one.
   * Removed default initialization functions, because they set msg.sender as the owner, which
     we do not want, because we use a deployer account, which is separate from the protocol owner.
*/

pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721PausableUpgradeable.sol";

// import "@openzeppelin-upgradeable/contracts/proxy/utils/InitializableUpgrageable.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to aother accounts
 */
contract ERC721PresetMinterPauserAutoIdUpgradeSafe is
    Initializable,
    ContextUpgradeable,
    AccessControlUpgradeable,
    ERC721PausableUpgradeable
{
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    uint256 public _tokenIdTracker;

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC721PresetMinterPauserAutoId: must have pauser role to pause"
        );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public {
        require(
            hasRole(PAUSER_ROLE, _msgSender()),
            "ERC721PresetMinterPauserAutoId: must have pauser role to unpause"
        );
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721PausableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return (interfaceId == _INTERFACE_ID_ERC721 ||
            interfaceId == _INTERFACE_ID_ERC165);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IOvenueConfig {
  function getNumber(uint256 index) external view returns (uint256);

  function getAddress(uint256 index) external view returns (address);

  function setAddress(uint256 index, address newAddress) external returns (address);

  function setNumber(uint256 index, uint256 newNumber) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

// import {ImplementationRepository} from "./proxy/ImplementationRepository.sol";
import {OvenueConfigOptions} from "../core/OvenueConfigOptions.sol";

import {IOvenueCollateralCustody} from "../interfaces/IOvenueCollateralCustody.sol";

import {IOvenueConfig} from "../interfaces/IOvenueConfig.sol";
import {IOvenueSeniorLP} from "../interfaces/IOvenueSeniorLP.sol";
import {IOvenueSeniorPool} from "../interfaces/IOvenueSeniorPool.sol";
import {IOvenueSeniorPoolStrategy} from "../interfaces/IOvenueSeniorPoolStrategy.sol";
import {IERC20withDec} from "../interfaces/IERC20withDec.sol";
// import {ICUSDCContract} from "../../interfaces/ICUSDCContract.sol";
import {IOvenueJuniorLP} from "../interfaces/IOvenueJuniorLP.sol";
import {IOvenueJuniorRewards} from "../interfaces/IOvenueJuniorRewards.sol";
import {IOvenueFactory} from "../interfaces/IOvenueFactory.sol";
import {IGo} from "../interfaces/IGo.sol";
// import {IStakingRewards} from "../../interfaces/IStakingRewards.sol";
// import {ICurveLP} from "../../interfaces/ICurveLP.sol";

/**
 * @title ConfigHelper
 * @notice A convenience library for getting easy access to other contracts and constants within the
 *  protocol, through the use of the OvenueConfig contract
 * @author Goldfinch
 */

library OvenueConfigHelper {
  function getSeniorPool(IOvenueConfig config) internal view returns (IOvenueSeniorPool) {
    return IOvenueSeniorPool(seniorPoolAddress(config));
  }

  function getSeniorPoolStrategy(IOvenueConfig config) internal view returns (IOvenueSeniorPoolStrategy) {
    return IOvenueSeniorPoolStrategy(seniorPoolStrategyAddress(config));
  }

  function getUSDC(IOvenueConfig config) internal view returns (IERC20withDec) {
    return IERC20withDec(usdcAddress(config));
  }

  function getSeniorLP(IOvenueConfig config) internal view returns (IOvenueSeniorLP) {
    return IOvenueSeniorLP(fiduAddress(config));
  }

//   function getFiduUSDCCurveLP(OvenueConfig config) internal view returns (ICurveLP) {
//     return ICurveLP(fiduUSDCCurveLPAddress(config));
//   }

//   function getCUSDCContract(OvenueConfig config) internal view returns (ICUSDCContract) {
//     return ICUSDCContract(cusdcContractAddress(config));
//   }

  function getJuniorLP(IOvenueConfig config) internal view returns (IOvenueJuniorLP) {
    return IOvenueJuniorLP(juniorLPAddress(config));
  }

  function getJuniorRewards(IOvenueConfig config) internal view returns (IOvenueJuniorRewards) {
    return IOvenueJuniorRewards(juniorRewardsAddress(config));
  }

  function getOvenueFactory(IOvenueConfig config) internal view returns (IOvenueFactory) {
    return IOvenueFactory(ovenueFactoryAddress(config));
  }

  function getOVN(IOvenueConfig config) internal view returns (IERC20withDec) {
    return IERC20withDec(ovenueAddress(config));
  }

  function getGo(IOvenueConfig config) internal view returns (IGo) {
    return IGo(goAddress(config));
  }

  function getCollateralToken(IOvenueConfig config) internal view returns (IERC20withDec) {
    return IERC20withDec(collateralTokenAddress(config));
  }

  function getCollateralCustody(IOvenueConfig config) internal view returns (IOvenueCollateralCustody) {
    return IOvenueCollateralCustody(collateralCustodyAddress(config));
  }

//   function getStakingRewards(OvenueConfig config) internal view returns (IStakingRewards) {
//     return IStakingRewards(stakingRewardsAddress(config));
//   }

  // function getTranchedPoolImplementationRepository(IOvenueConfig config)
  //   internal
  //   view
  //   returns (ImplementationRepository)
  // {
  //   return
  //     ImplementationRepository(
  //       config.getAddress(uint256(OvenueConfigOptions.Addresses.TranchedPoolImplementation))
  //     );
  // }

//   function oneInchAddress(OvenueConfig config) internal view returns (address) {
//     return config.getAddress(uint256(OvenueOvenueConfigOptions.Addresses.OneInch));
//   }

  function creditLineImplementationAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.CreditLineImplementation));
  }

//   /// @dev deprecated because we no longer use GSN
//   function trustedForwarderAddress(OvenueConfig config) internal view returns (address) {
//     return config.getAddress(uint256(OvenueOvenueConfigOptions.Addresses.TrustedForwarder));
//   }

  function collateralCustodyAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.CollateralCustody));
  }
  function configAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.OvenueConfig));
  }

  function juniorLPAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.PoolTokens));
  }

  function juniorRewardsAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.JuniorRewards));
  }

  function seniorPoolAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.SeniorPool));
  }

  function seniorPoolStrategyAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.SeniorPoolStrategy));
  }

  function ovenueFactoryAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.OvenueFactory));
  }

  function ovenueAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.OVENUE));
  }

  function fiduAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.Fidu));
  }

  function collateralTokenAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.CollateralToken));
  }

//   function fiduUSDCCurveLPAddress(OvenueConfig config) internal view returns (address) {
//     return config.getAddress(uint256(OvenueConfigOptions.Addresses.FiduUSDCCurveLP));
//   }

//   function cusdcContractAddress(OvenueConfig config) internal view returns (address) {
//     return config.getAddress(uint256(OvenueConfigOptions.Addresses.CUSDCContract));
//   }

  function usdcAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.USDC));
  }

  function tranchedPoolAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.TranchedPoolImplementation));
  }

  function reserveAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.TreasuryReserve));
  }

  function protocolAdminAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.ProtocolAdmin));
  }

  function borrowerImplementationAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.BorrowerImplementation));
  }

  function goAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.Go));
  }

//   function stakingRewardsAddress(OvenueConfig config) internal view returns (address) {
//     return config.getAddress(uint256(OvenueConfigOptions.Addresses.StakingRewards));
//   }

  function getCollateraLockupPeriod(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.CollateralLockedUpInSeconds));
  }

  function getReserveDenominator(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.ReserveDenominator));
  }

  function getWithdrawFeeDenominator(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.WithdrawFeeDenominator));
  }

  function getLatenessGracePeriodInDays(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.LatenessGracePeriodInDays));
  }

  function getLatenessMaxDays(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.LatenessMaxDays));
  }

  function getDrawdownPeriodInSeconds(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.DrawdownPeriodInSeconds));
  }

  function getTransferRestrictionPeriodInDays(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.TransferRestrictionPeriodInDays));
  }

  function getLeverageRatio(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.LeverageRatio));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import {IV2OvenueCreditLine} from "./IV2OvenueCreditLine.sol";

abstract contract IOvenueJuniorPool {
    IV2OvenueCreditLine public creditLine;
    uint256 public createdAt;

     struct Collateral {
        address nftAddr;
        uint tokenId;
        uint collateralAmount;
        bool isLocked;
    }

    enum Tranches {
        Reserved,
        Senior,
        Junior
    }

    struct TrancheInfo {
        uint256 id;
        uint256 principalDeposited;
        uint256 principalSharePrice;
        uint256 interestSharePrice;
        uint256 lockedUntil;
    }

    struct PoolSlice {
        TrancheInfo seniorTranche;
        TrancheInfo juniorTranche;
        uint256 totalInterestAccrued;
        uint256 principalDeployed;
        uint256 collateralDeposited;
    }

    function initialize(
        // config - borrower
        address[2] calldata _addresses,
        // junior fee percent - late fee apr, interest apr
        uint256[3] calldata _fees,
        // _paymentPeriodInDays - _termInDays - _principalGracePeriodInDays - _fundableAt
        uint256[4] calldata _days,
        uint256 _limit,
        uint256[] calldata _allowedUIDTypes
    ) external virtual;

    function getTranche(uint256 tranche)
        external
        view
        virtual
        returns (TrancheInfo memory);

    function pay(uint256 amount) external virtual;

    function poolSlices(uint256 index)
        external
        view
        virtual
        returns (PoolSlice memory);

    function lockJuniorCapital() external virtual;

    function lockPool() external virtual;

    function initializeNextSlice(uint256 _fundableAt) external virtual;

    function totalJuniorDeposits() external view virtual returns (uint256);

    function drawdown(uint256 amount) external virtual;

    function setFundableAt(uint256 timestamp) external virtual;

    function deposit(uint256 tranche, uint256 amount)
        external
        virtual
        returns (uint256 tokenId);

    function assess() external virtual;

    function depositWithPermit(
        uint256 tranche,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (uint256 tokenId);

    function availableToWithdraw(uint256 tokenId)
        external
        view
        virtual
        returns (uint256 interestRedeemable, uint256 principalRedeemable);

    function withdraw(uint256 tokenId, uint256 amount)
        external
        virtual
        returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

    function withdrawMax(uint256 tokenId)
        external
        virtual
        returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

    function withdrawMultiple(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external virtual;

    // function claimCollateralNFT() external virtual;

    function numSlices() external view virtual returns (uint256);
    // function isCollateralLocked() external view virtual returns (bool);

    // function getCollateralInfo() external view virtual returns(address, uint, bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IOvenueJuniorLP is IERC721Upgradeable {
    event TokenPrincipalWithdrawn(
        address indexed owner,
        address indexed pool,
        uint256 indexed tokenId,
        uint256 principalWithdrawn,
        uint256 tranche
    );
    event TokenBurned(
        address indexed owner,
        address indexed pool,
        uint256 indexed tokenId
    );
    event TokenMinted(
        address indexed owner,
        address indexed pool,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 tranche
    );

    event TokenRedeemed(
        address indexed owner,
        address indexed pool,
        uint256 indexed tokenId,
        uint256 principalRedeemed,
        uint256 interestRedeemed,
        uint256 tranche
    );

    struct TokenInfo {
        address pool;
        uint256 tranche;
        uint256 principalAmount;
        uint256 principalRedeemed;
        uint256 interestRedeemed;
    }

    struct MintParams {
        uint256 principalAmount;
        uint256 tranche;
    }

    function mint(MintParams calldata params, address to)
        external
        returns (uint256);

    function redeem(
        uint256 tokenId,
        uint256 principalRedeemed,
        uint256 interestRedeemed
    ) external;

    function withdrawPrincipal(uint256 tokenId, uint256 principalAmount)
        external;

    function burn(uint256 tokenId) external;

    function onPoolCreated(address newPool) external;

    function getTokenInfo(uint256 tokenId)
        external
        view
        returns (TokenInfo memory);

    function validPool(address sender) external view returns (bool);

    function isApprovedOrOwner(address spender, uint256 tokenId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721PausableUpgradeable is Initializable, ERC721Upgradeable, PausableUpgradeable {
    function __ERC721Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __ERC721Pausable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
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

        require(!paused(), "ERC721Pausable: token transfer while paused");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
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
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
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
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

/**
 * @title ConfigOptions
 * @notice A central place for enumerating the configurable options of our GoldfinchConfig contract
 * @author Goldfinch
 */

library OvenueConfigOptions {
  // NEVER EVER CHANGE THE ORDER OF THESE!
  // You can rename or append. But NEVER change the order.
  enum Numbers {
    TransactionLimit, // 0
    /// @dev: TotalFundsLimit used to represent a total cap on senior pool deposits
    /// but is now deprecated
    TotalFundsLimit, // 1
    MaxUnderwriterLimit, // 2
    ReserveDenominator, // 3
    WithdrawFeeDenominator, // 4
    LatenessGracePeriodInDays, // 5
    LatenessMaxDays, // 6
    DrawdownPeriodInSeconds, // 7
    TransferRestrictionPeriodInDays, // 8
    LeverageRatio, // 9
    CollateralLockedUpInSeconds // 10
  }
  /// @dev TrustedForwarder is deprecated because we no longer use GSN. CreditDesk
  ///   and Pool are deprecated because they are no longer used in the protocol.
  enum Addresses {
    CreditLineImplementation, // 0
    OvenueFactory, // 1
    Fidu, // 2
    USDC, // 3
    OVENUE, // 4
    TreasuryReserve, // 5
    ProtocolAdmin, // 6
    // OneInch,
    // CUSDCContract,
    OvenueConfig, // 7
    PoolTokens, // 8
    SeniorPool, // 9
    SeniorPoolStrategy, // 10
    TranchedPoolImplementation, // 11
    BorrowerImplementation, // 12
    // OVENUE, 
    Go, // 13
    JuniorRewards, // 14
    CollateralToken, // 15
    CollateralCustody // 16
    // StakingRewards
    // FiduUSDCCurveLP
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./IOvenueJuniorPool.sol";

interface IOvenueCollateralCustody {
    function isCollateralFullyFunded(IOvenueJuniorPool _poolAddr) external virtual returns(bool);
    function createCollateralStats(
        IOvenueJuniorPool _poolAddr,
        address _nftAddr,
        uint256 _tokenId,
        uint256 _fungibleAmount
    ) external virtual;
    
    function collectFungibleCollateral(
        IOvenueJuniorPool _poolAddr,
        address _depositor,
        uint256 _amount
    ) external virtual;

    function redeemAllCollateral(
        IOvenueJuniorPool _poolAddr,
        address receiver
    ) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./IERC20withDec.sol";

interface IOvenueSeniorLP is IERC20withDec {
  function mintTo(address to, uint256 amount) external;

  function burnFrom(address to, uint256 amount) external;

  function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./IOvenueJuniorPool.sol";

abstract contract IOvenueSeniorPool {
  uint256 public sharePrice;
  uint256 public totalLoansOutstanding;
  uint256 public totalWritedowns;

  function deposit(uint256 amount) external virtual returns (uint256 depositShares);

  function depositWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual returns (uint256 depositShares);

  function withdraw(uint256 usdcAmount) external virtual returns (uint256 amount);

  function withdrawInLP(uint256 fiduAmount) external virtual returns (uint256 amount);

//   function sweepToCompound() public virtual;

//   function sweepFromCompound() public virtual;

  function invest(IOvenueJuniorPool pool) public virtual;

  function estimateInvestment(IOvenueJuniorPool pool) public view virtual returns (uint256);

  function redeem(uint256 tokenId) public virtual;

  function writedown(uint256 tokenId) public virtual;

  function calculateWritedown(uint256 tokenId) public view virtual returns (uint256 writedownAmount);

  function assets() public view virtual returns (uint256);

  function getNumShares(uint256 amount) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./IOvenueSeniorPool.sol";
import "./IOvenueJuniorPool.sol";

abstract contract IOvenueSeniorPoolStrategy {
//   function getLeverageRatio(IOvenueJuniorPool pool) public view virtual returns (uint256);
  function getLeverageRatio() public view virtual returns (uint256);

  function invest(IOvenueJuniorPool pool) public view virtual returns (uint256 amount);

  function estimateInvestment(IOvenueJuniorPool pool) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20withDec is IERC20Upgradeable {
  /**
   * @dev Returns the number of decimals used for the token
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IOvenueJuniorRewards {
  function allocateRewards(uint256 _interestPaymentAmount) external;

  // function onTranchedPoolDrawdown(uint256 sliceIndex) external;

  function setPoolTokenAccRewardsPerPrincipalDollarAtMint(address poolAddress, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IOvenueFactory {
  function createCreditLine() external returns (address);

  function createBorrower(address owner) external returns (address);

  function createPool(
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256[] calldata _allowedUIDTypes
  ) external returns (address);

  function createMigratedPool(
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256[] calldata _allowedUIDTypes
  ) external returns (address);

  function updateGoldfinchConfig() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

abstract contract IGo {
  uint256 public constant ID_TYPE_0 = 0;
  uint256 public constant ID_TYPE_1 = 1;
  uint256 public constant ID_TYPE_2 = 2;
  uint256 public constant ID_TYPE_3 = 3;
  uint256 public constant ID_TYPE_4 = 4;
  uint256 public constant ID_TYPE_5 = 5;
  uint256 public constant ID_TYPE_6 = 6;
  uint256 public constant ID_TYPE_7 = 7;
  uint256 public constant ID_TYPE_8 = 8;
  uint256 public constant ID_TYPE_9 = 9;
  uint256 public constant ID_TYPE_10 = 10;

  /// @notice Returns the address of the UniqueIdentity contract.
  function uniqueIdentity() external virtual returns (address);

  function go(address account) public view virtual returns (bool);

  function goOnlyIdTypes(address account, uint256[] calldata onlyIdTypes) public view virtual returns (bool);

  function goSeniorPool(address account) public view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./IOvenueCreditLine.sol";

abstract contract IV2OvenueCreditLine is IOvenueCreditLine {
  function principal() external view virtual returns (uint256);

  function totalInterestAccrued() external view virtual returns (uint256);

  function termStartTime() external view virtual returns (uint256);

  function setLimit(uint256 newAmount) external virtual;

  function setMaxLimit(uint256 newAmount) external virtual;

  function setBalance(uint256 newBalance) external virtual;

  function setPrincipal(uint256 _principal) external virtual;

  function setTotalInterestAccrued(uint256 _interestAccrued) external virtual;

  function drawdown(uint256 amount) external virtual;

  function assess()
    external
    virtual
    returns (
      uint256,
      uint256,
      uint256
    );

  function initialize(
    address _config,
    address owner,
    address _borrower,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays
  ) public virtual;

  function setTermEndTime(uint256 newTermEndTime) external virtual;

  function setNextDueTime(uint256 newNextDueTime) external virtual;

  function setInterestOwed(uint256 newInterestOwed) external virtual;

  function setPrincipalOwed(uint256 newPrincipalOwed) external virtual;

  function setInterestAccruedAsOf(uint256 newInterestAccruedAsOf) external virtual;

  function setWritedownAmount(uint256 newWritedownAmount) external virtual;

  function setLastFullPaymentTime(uint256 newLastFullPaymentTime) external virtual;

  function setLateFeeApr(uint256 newLateFeeApr) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IOvenueCreditLine {
  function borrower() external view returns (address);

  function limit() external view returns (uint256);

  function maxLimit() external view returns (uint256);

  function interestApr() external view returns (uint256);

  function paymentPeriodInDays() external view returns (uint256);

  function principalGracePeriodInDays() external view returns (uint256);

  function termInDays() external view returns (uint256);

  function lateFeeApr() external view returns (uint256);

  function isLate() external view returns (bool);

  function withinPrincipalGracePeriod() external view returns (bool);

  // Accounting variables
  function balance() external view returns (uint256);

  function interestOwed() external view returns (uint256);

  function principalOwed() external view returns (uint256);

  function termEndTime() external view returns (uint256);

  function nextDueTime() external view returns (uint256);

  function interestAccruedAsOf() external view returns (uint256);

  function lastFullPaymentTime() external view returns (uint256);
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
pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "../libraries/Math.sol";
import "../libraries/OvenueConfigHelper.sol";
import "../upgradeable/BaseUpgradeablePausable.sol";
import "../interfaces/IOvenueJuniorLP.sol";
import "../interfaces/IOvenueJuniorPool.sol";
import "../interfaces/IOvenueJuniorRewards.sol";
import "../interfaces/IERC20withDec.sol";

contract OvenueJuniorRewards is IOvenueJuniorRewards, BaseUpgradeablePausable {
    IOvenueConfig public config;
    using OvenueConfigHelper for IOvenueConfig;
    using SafeERC20Upgradeable for IERC20withDec;

    struct BackerRewardsInfo {
        uint256 accRewardsPerPrincipalDollar; // accumulator ovn per interest dollar
    }

    struct BackerRewardsTokenInfo {
        uint256 rewardsClaimed; // ovn claimed
        uint256 accRewardsPerPrincipalDollarAtMint; // Pool's accRewardsPerPrincipalDollar at Junior LP mint()
    }

    uint256 public totalRewards; // total amount of OVN rewards available, times 1e18
    uint256 public maxInterestDollarsEligible; // interest $ eligible for gfi rewards, times 1e18
    uint256 public totalInterestReceived; // counter of total interest repayments, times 1e6
    uint256 public totalRewardPercentOfTotalOVN; // totalRewards/totalGFISupply, times 1e18

    mapping(uint256 => BackerRewardsTokenInfo) public tokens; // poolTokenId -> BackerRewardsTokenInfo

    mapping(address => BackerRewardsInfo) public pools; // pool.address -> BackerRewardsInfo

    // solhint-disable-next-line func-name-mixedcase
    function initialize(address owner, IOvenueConfig _config)
        public
        initializer
    {
        require(
            owner != address(0) && address(_config) != address(0),
            "Owner and config addresses cannot be empty"
        );
        __BaseUpgradeablePausable__init(owner);
        config = _config;
    }

    /**
   * @notice Calculates the accRewardsPerPrincipalDollar for a given pool,
   when a interest payment is received by the protocol
   * @param _interestPaymentAmount The amount of total dollars the interest payment, expects 10^6 value
   */
    function allocateRewards(uint256 _interestPaymentAmount)
        external
        override
        onlyPool
    {
        // note: do not use a require statment because that will TranchedPool kill execution
        if (_interestPaymentAmount > 0) {
            _allocateRewards(_interestPaymentAmount);
        }
    }

    /**
     * @notice Set the total gfi rewards and the % of total GFI
     * @param _totalRewards The amount of GFI rewards available, expects 10^18 value
     */
    function setTotalRewards(uint256 _totalRewards) public onlyAdmin {
        totalRewards = _totalRewards;
        uint256 totalGFISupply = config.getOVN().totalSupply();
        totalRewardPercentOfTotalOVN =
            ((_totalRewards * mantissa()) / totalGFISupply) *
            100;
        emit BackerRewardsSetTotalRewards(
            _msgSender(),
            _totalRewards,
            totalRewardPercentOfTotalOVN
        );
    }

    /**
   * @notice Set the total interest received to date.
   This should only be called once on contract deploy.
   * @param _totalInterestReceived The amount of interest the protocol has received to date, expects 10^6 value
   */
    function setTotalInterestReceived(uint256 _totalInterestReceived)
        public
        onlyAdmin
    {
        totalInterestReceived = _totalInterestReceived;
        emit BackerRewardsSetTotalInterestReceived(
            _msgSender(),
            _totalInterestReceived
        );
    }

    /**
     * @notice Set the max dollars across the entire protocol that are eligible for GFI rewards
     * @param _maxInterestDollarsEligible The amount of interest dollars eligible for GFI rewards, expects 10^18 value
     */
    function setMaxInterestDollarsEligible(uint256 _maxInterestDollarsEligible)
        public
        onlyAdmin
    {
        maxInterestDollarsEligible = _maxInterestDollarsEligible;
        emit BackerRewardsSetMaxInterestDollarsEligible(
            _msgSender(),
            _maxInterestDollarsEligible
        );
    }

    /**
   * @notice When a pool token is minted for multiple drawdowns,
   set accRewardsPerPrincipalDollarAtMint to the current accRewardsPerPrincipalDollar price
   * @param tokenId Pool token id
   */
    function setPoolTokenAccRewardsPerPrincipalDollarAtMint(
        address poolAddress,
        uint256 tokenId
    ) external override {
        require(_msgSender() == config.juniorLPAddress(), "Invalid sender!");
        require(config.getJuniorLP().validPool(poolAddress), "Invalid pool!");
        if (tokens[tokenId].accRewardsPerPrincipalDollarAtMint != 0) {
            return;
        }
        IOvenueJuniorLP poolTokens = config.getJuniorLP();
        IOvenueJuniorLP.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(
            tokenId
        );
        require(
            poolAddress == tokenInfo.pool,
            "PoolAddress must equal PoolToken pool address"
        );

        tokens[tokenId].accRewardsPerPrincipalDollarAtMint = pools[
            tokenInfo.pool
        ].accRewardsPerPrincipalDollar;
    }

    /**
     * @notice Calculate the gross available gfi rewards for a PoolToken
     * @param tokenId Pool token id
     * @return The amount of GFI claimable
     */
    function poolTokenClaimableRewards(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        IOvenueJuniorLP poolTokens = config.getJuniorLP();
        IOvenueJuniorLP.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(
            tokenId
        );

        // Note: If a TranchedPool is oversubscribed, reward allocation's scale down proportionately.

        uint256 diffOfAccRewardsPerPrincipalDollar = pools[tokenInfo.pool]
            .accRewardsPerPrincipalDollar -
            (tokens[tokenId].accRewardsPerPrincipalDollarAtMint);
        uint256 rewardsClaimed = tokens[tokenId].rewardsClaimed * mantissa();

        /*
      equation for token claimable rewards:
        token.principalAmount
        * (pool.accRewardsPerPrincipalDollar - token.accRewardsPerPrincipalDollarAtMint)
        - token.rewardsClaimed
    */

        return
            (usdcToAtomic(tokenInfo.principalAmount) *
                diffOfAccRewardsPerPrincipalDollar -
                rewardsClaimed) / mantissa();
    }

    /**
     * @notice PoolToken request to withdraw multiple PoolTokens allocated rewards
     * @param tokenIds Array of pool token id
     */
    function withdrawMultiple(uint256[] calldata tokenIds) public {
        require(tokenIds.length > 0, "TokensIds length must not be 0");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            withdraw(tokenIds[i]);
        }
    }

    /**
     * @notice PoolToken request to withdraw all allocated rewards
     * @param tokenId Pool token id
     */
    function withdraw(uint256 tokenId) public {
        uint256 totalClaimableRewards = poolTokenClaimableRewards(tokenId);
        uint256 poolTokenRewardsClaimed = tokens[tokenId].rewardsClaimed;
        IOvenueJuniorLP poolTokens = config.getJuniorLP();
        IOvenueJuniorLP.TokenInfo memory tokenInfo = poolTokens.getTokenInfo(
            tokenId
        );

        address poolAddr = tokenInfo.pool;
        require(config.getJuniorLP().validPool(poolAddr), "Invalid pool!");
        require(
            msg.sender == poolTokens.ownerOf(tokenId),
            "Must be owner of PoolToken"
        );

        BaseUpgradeablePausable pool = BaseUpgradeablePausable(poolAddr);
        require(!pool.paused(), "Pool withdraw paused");

        IOvenueJuniorPool tranchedPool = IOvenueJuniorPool(poolAddr);
        require(
            !tranchedPool.creditLine().isLate(),
            "Pool is late on payments"
        );

        tokens[tokenId].rewardsClaimed =
            poolTokenRewardsClaimed +
            totalClaimableRewards;
        config.getOVN().safeTransferFrom(
            address(this),
            poolTokens.ownerOf(tokenId),
            totalClaimableRewards
        );
        emit BackerRewardsClaimed(_msgSender(), tokenId, totalClaimableRewards);
    }

    /* Internal functions  */
    function _allocateRewards(uint256 _interestPaymentAmount) internal {
        uint256 _totalInterestReceived = totalInterestReceived;
        if (
            usdcToAtomic(_totalInterestReceived) >= maxInterestDollarsEligible
        ) {
            return;
        }

        address _poolAddress = _msgSender();

        // Gross GFI Rewards earned for incoming interest dollars
        uint256 newGrossRewards = _calculateNewGrossGFIRewardsForInterestAmount(
            _interestPaymentAmount
        );

        IOvenueJuniorPool pool = IOvenueJuniorPool(_poolAddress);
        BackerRewardsInfo storage _poolInfo = pools[_poolAddress];

        uint256 totalJuniorDeposits = pool.totalJuniorDeposits();
        if (totalJuniorDeposits == 0) {
            return;
        }

        // example: (6708203932437400000000 * 10^18) / (100000*10^18)
        _poolInfo.accRewardsPerPrincipalDollar =
            _poolInfo.accRewardsPerPrincipalDollar +
            ((newGrossRewards * mantissa()) /
                usdcToAtomic(totalJuniorDeposits));

        totalInterestReceived = _totalInterestReceived + _interestPaymentAmount;
    }

    /**
     * @notice Calculate the rewards earned for a given interest payment
     * @param _interestPaymentAmount interest payment amount times 1e6
     */
    function _calculateNewGrossGFIRewardsForInterestAmount(
        uint256 _interestPaymentAmount
    ) internal view returns (uint256) {
        uint256 totalGFISupply = config.getOVN().totalSupply();

        // incoming interest payment, times * 1e18 divided by 1e6
        uint256 interestPaymentAmount = usdcToAtomic(_interestPaymentAmount);

        // all-time interest payments prior to the incoming amount, times 1e18
        uint256 _previousTotalInterestReceived = usdcToAtomic(
            totalInterestReceived
        );
        uint256 sqrtOrigTotalInterest = Math.sqrt(
            _previousTotalInterestReceived
        );

        // sum of new interest payment + previous total interest payments, times 1e18
        uint256 newTotalInterest = usdcToAtomic(
            atomicToUSDC(_previousTotalInterestReceived) +
                atomicToUSDC(interestPaymentAmount)
        );

        // interest payment passed the maxInterestDollarsEligible cap, should only partially be rewarded
        if (newTotalInterest > maxInterestDollarsEligible) {
            newTotalInterest = maxInterestDollarsEligible;
        }

        /*
      equation:
        (sqrtNewTotalInterest-sqrtOrigTotalInterest)
        * totalRewardPercentOfTotalOVN
        / sqrtMaxInterestDollarsEligible
        / 100
        * totalGFISupply
        / 10^18

      example scenario:
      - new payment = 5000*10^18
      - original interest received = 0*10^18
      - total reward percent = 3 * 10^18
      - max interest dollars = 1 * 10^27 ($1 billion)
      - totalGfiSupply = 100_000_000 * 10^18

      example math:
        (70710678118 - 0)
        * 3000000000000000000
        / 31622776601683
        / 100
        * 100000000000000000000000000
        / 10^18
        = 6708203932437400000000 (6,708.2039 GFI)
    */
        uint256 sqrtDiff = Math.sqrt(newTotalInterest) - sqrtOrigTotalInterest;
        uint256 sqrtMaxInterestDollarsEligible = Math.sqrt(
            maxInterestDollarsEligible
        );

        require(
            sqrtMaxInterestDollarsEligible > 0,
            "maxInterestDollarsEligible must not be zero"
        );

        uint256 newGrossRewards = (((sqrtDiff *
            (totalRewardPercentOfTotalOVN)) /
            (sqrtMaxInterestDollarsEligible) /
            (100)) * (totalGFISupply)) / (mantissa());

        // Extra safety check to make sure the logic is capped at a ceiling of potential rewards
        // Calculating the gfi/$ for first dollar of interest to the protocol, and multiplying by new interest amount
        uint256 absoluteMaxGfiCheckPerDollar = (((Math.sqrt(mantissa() * 1) *
            totalRewardPercentOfTotalOVN) /
            sqrtMaxInterestDollarsEligible /
            100) * totalGFISupply) / mantissa();
        require(
            newGrossRewards <
                absoluteMaxGfiCheckPerDollar * newTotalInterest,
            "newGrossRewards cannot be greater then the max gfi per dollar"
        );

        return newGrossRewards;
    }

    function mantissa() internal pure returns (uint256) {
        return uint256(10)**uint256(18);
    }

    function usdcMantissa() internal pure returns (uint256) {
        return uint256(10)**uint256(6);
    }

    function usdcToAtomic(uint256 amount) internal pure returns (uint256) {
        return amount * mantissa() / usdcMantissa();
    }

    function atomicToUSDC(uint256 amount) internal pure returns (uint256) {
        return amount / (mantissa() / usdcMantissa());
    }

    function updateOvenueConfig() external onlyAdmin {
        config = IOvenueConfig(config.configAddress());
        emit OvenueConfigUpdated(_msgSender(), address(config));
    }

    /* ======== MODIFIERS  ======== */

    modifier onlyPool() {
        require(
            config.getJuniorLP().validPool(_msgSender()),
            "Invalid pool!"
        );
        _;
    }

    /* ======== EVENTS ======== */
    event OvenueConfigUpdated(address indexed who, address configAddress);
    event BackerRewardsClaimed(
        address indexed owner,
        uint256 indexed tokenId,
        uint256 amount
    );
    event BackerRewardsSetTotalRewards(
        address indexed owner,
        uint256 totalRewards,
        uint256 totalRewardPercentOfTotalOVN
    );
    event BackerRewardsSetTotalInterestReceived(
        address indexed owner,
        uint256 totalInterestReceived
    );
    event BackerRewardsSetMaxInterestDollarsEligible(
        address indexed owner,
        uint256 maxInterestDollarsEligible
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)
pragma solidity ^0.8.5;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
   
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

/**
 * @title BaseUpgradeablePausable contract
 * @notice This is our Base contract that most other contracts inherit from. It includes many standard
 *  useful abilities like upgradeability, pausability, access control, and re-entrancy guards.
 * @author Goldfinch
 */

contract BaseUpgradeablePausable is
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    // Pre-reserving a few slots in the base contract in case we need to add things in the future.
    // This does not actually take up gas cost or storage cost, but it does reserve the storage slots.
    // See OpenZeppelin's use of this pattern here:
    // https://github.com/OpenZeppelin/openzeppelin-contracts-ethereum-package/blob/master/contracts/GSN/Context.sol#L37
    uint256[50] private __gap1;
    uint256[50] private __gap2;
    uint256[50] private __gap3;
    uint256[50] private __gap4;

    // solhint-disable-next-line func-name-mixedcase
    function __BaseUpgradeablePausable__init(address owner) public onlyInitializing {
        require(owner != address(0), "Owner cannot be the zero address");
        __AccessControl_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        _setupRole(OWNER_ROLE, owner);
        _setupRole(PAUSER_ROLE, owner);

        _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    }

    function isAdmin() public view returns (bool) {
        return hasRole(OWNER_ROLE, _msgSender());
    }

    modifier onlyAdmin() {
        require(isAdmin(), "Must have admin role to perform this action");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../security/PausableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC1155 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155PausableUpgradeable is Initializable, ERC1155Upgradeable, PausableUpgradeable {
    function __ERC1155Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __ERC1155Pausable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "../libraries/OvenueConfigHelper.sol";
import "../interfaces/IV2OvenueCreditLine.sol";
import "../interfaces/IOvenueConfig.sol";
import "../interfaces/IERC20withDec.sol";
import "../interfaces/IOvenueJuniorPool.sol";
import "../interfaces/IOvenueBorrower.sol";
import "../upgradeable/BaseUpgradeablePausable.sol";

// import "../../external/BaseRelayRecipient.sol";

/**
 * @title Ovenue's Borrower contract
 * @notice These contracts represent the a convenient way for a borrower to interact with Goldfinch
 *  They are 100% optional. However, they let us add many sophisticated and convient features for borrowers
 *  while still keeping our core protocol small and secure. We therefore expect most borrowers will use them.
 *  This contract is the "official" borrower contract that will be maintained by Goldfinch governance. However,
 *  in theory, anyone can fork or create their own version, or not use any contract at all. The core functionality
 *  is completely agnostic to whether it is interacting with a contract or an externally owned account (EOA).
 * @author Ovenue
 */

contract OvenueBorrower is BaseUpgradeablePausable, IOvenueBorrower {
    IOvenueConfig public config;
    using OvenueConfigHelper for IOvenueConfig;

    function initialize(address owner, address _config)
        external
        override
        initializer
    {
        require(
            owner != address(0) && _config != address(0),
            "Owner and config addresses cannot be empty"
        );
        __BaseUpgradeablePausable__init(owner);
        config = IOvenueConfig(_config);

        // IERC20withDec usdc = config.getUSDC();
        // usdc.approve(oneInch, type(uint256).max);
    }

    function lockCollateralToken(address _poolAddress, uint256 _amount) external onlyAdmin {
        config.getCollateralCustody().collectFungibleCollateral(
            IOvenueJuniorPool(_poolAddress),
            msg.sender,
            _amount
        );
    }

    function lockJuniorCapital(address poolAddress) external onlyAdmin {
        IOvenueJuniorPool pool = IOvenueJuniorPool(poolAddress);
        require(config.getCollateralCustody().isCollateralFullyFunded(pool), "Already redeem collateral!");
        IOvenueJuniorPool(poolAddress).lockJuniorCapital();
    }

    function lockPool(address poolAddress) external onlyAdmin {
        IOvenueJuniorPool(poolAddress).lockPool();
    }

    function redeemCollateral(
        address poolAddress, 
        address addressToSendTo
    ) external onlyAdmin {
        IOvenueJuniorPool pool = IOvenueJuniorPool(poolAddress);
        IV2OvenueCreditLine creditLine = pool.creditLine();
        IOvenueCollateralCustody custody = config.getCollateralCustody();

        if (creditLine.termEndTime() == 0) {
            custody.redeemAllCollateral(
                pool,
                addressToSendTo
            );
            return;
        }

        // pool.assess();

        uint totalOwned = creditLine.interestOwed() + creditLine.principalOwed();
        uint loanBalance = creditLine.balance();

        if (totalOwned == 0 && loanBalance == 0) {
            custody.redeemAllCollateral(
                pool,
                addressToSendTo
            );
        }
    }

    /**
     * @notice Allows a borrower to drawdown on their credit line through a TranchedPool.
     * @param poolAddress The creditline from which they would like to drawdown
     * @param amount The amount, in USDC atomic units, that a borrower wishes to drawdown
     * @param addressToSendTo The address where they would like the funds sent. If the zero address is passed,
     *  it will be defaulted to the contracts address (msg.sender). This is a convenience feature for when they would
     *  like the funds sent to an exchange or alternate wallet, different from the authentication address
     */
    function drawdown(
        address poolAddress,
        uint256 amount,
        address addressToSendTo
    ) external onlyAdmin {
        IOvenueJuniorPool(poolAddress).drawdown(amount);

        if (addressToSendTo == address(0) || addressToSendTo == address(this)) {
            addressToSendTo = msg.sender;
        }

        transferERC20(config.usdcAddress(), addressToSendTo, amount);
    }

    function transferERC20(
        address token,
        address to,
        uint256 amount
    ) public onlyAdmin {
        bytes memory _data = abi.encodeWithSignature(
            "transfer(address,uint256)",
            to,
            amount
        );
        _invoke(token, _data);
    }

    /**
     * @notice Allows a borrower to pay back loans by calling the `pay` function directly on a TranchedPool
     * @param poolAddress The credit line to be paid back
     * @param amount The amount, in USDC atomic units, that the borrower wishes to pay
     */
    function pay(address poolAddress, uint256 amount) external onlyAdmin {
        IERC20withDec usdc = config.getUSDC();
        bool success = usdc.transferFrom(msg.sender, address(this), amount);
        require(success, "Failed to transfer USDC");
        _transferAndPay(usdc, poolAddress, amount);
    }

    function payMultiple(address[] calldata pools, uint256[] calldata amounts)
        external
        onlyAdmin
    {
        require(
            pools.length == amounts.length,
            "Pools and amounts must be the same length"
        );

        uint256 totalAmount;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount = totalAmount + amounts[i];
        }

        IERC20withDec usdc = config.getUSDC();
        // Do a single transfer, which is cheaper
        bool success = usdc.transferFrom(
            msg.sender,
            address(this),
            totalAmount
        );
        require(success, "Failed to transfer USDC");

        for (uint256 i = 0; i < amounts.length; i++) {
            _transferAndPay(usdc, pools[i], amounts[i]);
        }
    }

    function payInFull(address poolAddress, uint256 amount) external onlyAdmin {
        IERC20withDec usdc = config.getUSDC();
        bool success = usdc.transferFrom(msg.sender, address(this), amount);
        require(success, "Failed to transfer USDC");

        _transferAndPay(usdc, poolAddress, amount);
        require(
            IOvenueJuniorPool(poolAddress).creditLine().balance() == 0,
            "Failed to fully pay off creditline"
        );
    }

    function _transferAndPay(
        IERC20withDec usdc,
        address poolAddress,
        uint256 amount
    ) internal {
        IOvenueJuniorPool pool = IOvenueJuniorPool(poolAddress);
        // We don't use transferFrom since it would require a separate approval per creditline
        bool success = usdc.transfer(address(pool.creditLine()), amount);
        require(success, "USDC Transfer to creditline failed");
        pool.assess();
    }

    function transferFrom(
        address erc20,
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        bytes memory _data;
        // Do a low-level _invoke on this transfer, since Tether fails if we use the normal IERC20 interface
        _data = abi.encodeWithSignature(
            "transferFrom(address,address,uint256)",
            sender,
            recipient,
            amount
        );
        _invoke(address(erc20), _data);
    }

    /**
     * @notice Performs a generic transaction.
     * @param _target The address for the transaction.
     * @param _data The data of the transaction.
     * Mostly copied from Argent:
     * https://github.com/argentlabs/argent-contracts/blob/develop/contracts/wallet/BaseWallet.sol#L111
     */
    function _invoke(address _target, bytes memory _data)
        internal
        returns (bytes memory)
    {
        // External contracts can be compiled with different Solidity versions
        // which can cause "revert without reason" when called through,
        // for example, a standard IERC20 ABI compiled on the latest version.
        // This low-level call avoids that issue.

        bool success;
        bytes memory _res;
        // solhint-disable-next-line avoid-low-level-calls
        (success, _res) = _target.call(_data);
        if (!success && _res.length > 0) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        } else if (!success) {
            revert("VM: wallet _invoke reverted");
        }
        return _res;
    }

    function _toUint256(bytes memory _bytes)
        internal
        pure
        returns (uint256 value)
    {
        assembly {
            value := mload(add(_bytes, 0x20))
        }
    }

    // function onERC721Received(
    //     address operator,
    //     address from,
    //     uint256 tokenId,
    //     bytes calldata data
    // ) external override pure returns (bytes4) {
    //     return IERC721Receiver.onERC721Received.selector;
    // }
}

// SPDX-Licence-Identifier: MIT
pragma solidity 0.8.5;

interface IOvenueBorrower {
  function initialize(address owner, address _config) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "../upgradeable/BaseUpgradeablePausable.sol";
import "../interfaces/IOvenueConfig.sol";
import "../interfaces/IOvenueCollateralCustody.sol";
import "../interfaces/IOvenueBorrower.sol";
import "../interfaces/IOvenueJuniorPool.sol";
import "../libraries/OvenueConfigHelper.sol";


/**
 * @title OvenueFactory
 * @notice Contract that allows us to create other contracts, such as CreditLines and BorrowerContracts
 *  Note OvenueFactory is a legacy name. More properly this can be considered simply the OvenueFactory
 * @author Ovenue
 */

contract OvenueFactory is BaseUpgradeablePausable {
    IOvenueConfig public config;
    IOvenueCollateralCustody public collateralCustody;

    /// Role to allow for pool creation
    bytes32 public constant BORROWER_ROLE = keccak256("BORROWER_ROLE");

    using OvenueConfigHelper for IOvenueConfig;

    event BorrowerCreated(address indexed borrower, address indexed owner);
    event PoolCreated(address indexed pool, address indexed borrower);
    event OvenueConfigUpdated(address indexed who, address configAddress);
    event CreditLineCreated(address indexed creditLine);

    function initialize(address owner, IOvenueConfig _config)
        public
        initializer
    {
        require(
            owner != address(0) && address(_config) != address(0),
            "Owner and config addresses cannot be empty"
        );
        __BaseUpgradeablePausable__init(owner);
        config = _config;
        _performUpgrade();
    }

    function performUpgrade() external onlyAdmin {
        _performUpgrade();
    }

    function _performUpgrade() internal {
        if (getRoleAdmin(BORROWER_ROLE) != OWNER_ROLE) {
            _setRoleAdmin(BORROWER_ROLE, OWNER_ROLE);
        }
    }

    /**
     * @notice Allows anyone to create a CreditLine contract instance
     * @dev There is no value to calling this function directly. It is only meant to be called
     *  by a TranchedPool during it's creation process.
     */
    function createCreditLine() external returns (address) {
        address creditLine = deployMinimal(
            config.creditLineImplementationAddress()
        );
        emit CreditLineCreated(creditLine);
        return creditLine;
    }

    /**
     * @notice Allows anyone to create a Borrower contract instance
     * @param owner The address that will own the new Borrower instance
     */
    function createBorrower(address owner) external returns (address) {
        address _borrower = deployMinimal(
            config.borrowerImplementationAddress()
        );
        IOvenueBorrower borrower = IOvenueBorrower(_borrower);
        borrower.initialize(owner, address(config));
        emit BorrowerCreated(address(borrower), owner);
        return address(borrower);
    }

    // /**
    //  * @notice Allows anyone to create a new TranchedPool for a single borrower
    //  * @param _borrower The borrower for whom the CreditLine will be created
    //  * @param _juniorFeePercent The percent of senior interest allocated to junior investors, expressed as
    //  *  integer percents. eg. 20% is simply 20
    //  * @param _limit The maximum amount a borrower can drawdown from this CreditLine
    //  * @param _interestApr The interest amount, on an annualized basis (APR, so non-compounding), expressed as an integer.
    //  *  We assume 18 digits of precision. For example, to submit 15.34%, you would pass up 153400000000000000,
    //  *  and 5.34% would be 53400000000000000
    //  * @param _paymentPeriodInDays How many days in each payment period.
    //  *  ie. the frequency with which they need to make payments.
    //  * @param _termInDays Number of days in the credit term. It is used to set the `termEndTime` upon first drawdown.
    //  *  ie. The credit line should be fully paid off {_termIndays} days after the first drawdown.
    //  * @param _lateFeeApr The additional interest you will pay if you are late. For example, if this is 3%, and your
    //  *  normal rate is 15%, then you will pay 18% while you are late. Also expressed as an 18 decimal precision integer
    //  *
    //  * Requirements:
    //  *  You are the admin
    //  */
    function createPool(
        // address _borrower,
        // uint256 _juniorFeePercent,
        // uint256 _limit,
        // uint256 _interestApr,
        // uint256 _paymentPeriodInDays,
        // uint256 _termInDays,
        // uint256 _lateFeeApr,
        // uint256 _principalGracePeriodInDays,
        // uint256 _fundableAt,
        // uint256[] calldata _allowedUIDTypes


        // address _config,
        // address _borrower,
        // address _nftAddr
        address[3] calldata _addresses,
        // junior fee percent - late fee apr, interest apr
        uint256[3] calldata _fees,
        // _paymentPeriodInDays - _termInDays - _principalGracePeriodInDays - _fundableAt
        uint256[4] calldata _days,
        uint256 _fungibleAmount,
        uint256 _limit,
        uint256 _tokenId,
        uint256[] calldata _allowedUIDTypes
    ) external onlyAdminOrBorrower returns (address pool) {
        address tranchedPoolImplAddress = config.tranchedPoolAddress();
        pool = deployMinimal(tranchedPoolImplAddress);
        IOvenueJuniorPool(pool).initialize(
            [_addresses[0], _addresses[1]],
            _fees,
            _days,
            _limit,
            _allowedUIDTypes
        );
        config.getCollateralCustody().createCollateralStats(
            IOvenueJuniorPool(pool),
            _addresses[2],
            _tokenId,
            _fungibleAmount
        );
        emit PoolCreated(pool, _addresses[1]);
        config.getJuniorLP().onPoolCreated(pool);
        return pool;
    }

    //   function createMigratedPool(
    //     address _borrower,
    //     uint256 _juniorFeePercent,
    //     uint256 _limit,
    //     uint256 _interestApr,
    //     uint256 _paymentPeriodInDays,
    //     uint256 _termInDays,
    //     uint256 _lateFeeApr,
    //     uint256 _principalGracePeriodInDays,
    //     uint256 _fundableAt,
    //     uint256[] calldata _allowedUIDTypes
    //   ) external onlyCreditDesk returns (address pool) {
    //     address tranchedPoolImplAddress = config.migratedTranchedPoolAddress();
    //     pool = deployMinimal(tranchedPoolImplAddress);
    //     ITranchedPool(pool).initialize(
    //       address(config),
    //       _borrower,
    //       _juniorFeePercent,
    //       _limit,
    //       _interestApr,
    //       _paymentPeriodInDays,
    //       _termInDays,
    //       _lateFeeApr,
    //       _principalGracePeriodInDays,
    //       _fundableAt,
    //       _allowedUIDTypes
    //     );
    //     emit PoolCreated(pool, _borrower);
    //     config.getPoolTokens().onPoolCreated(pool);
    //     return pool;
    //   }

    function updateOvenueConfig() external onlyAdmin {
        config = IOvenueConfig(config.configAddress());
        emit OvenueConfigUpdated(msg.sender, address(config));
    }

    // Stolen from:
    // https://github.com/OpenZeppelin/openzeppelin-sdk/blob/master/packages/lib/contracts/upgradeability/ProxyFactory.sol
    function deployMinimal(address _logic) internal returns (address proxy) {
        bytes20 targetBytes = bytes20(_logic);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            proxy := create(0, clone, 0x37)
        }
        return proxy;
    }

    function isBorrower() public view returns (bool) {
        return hasRole(BORROWER_ROLE, _msgSender());
    }

    modifier onlyAdminOrBorrower() {
        require(
            isAdmin() || isBorrower(),
            "Must have admin or borrower role to perform this action"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./Math.sol";
import "./WadRayMath.sol";
import {IV2OvenueCreditLine} from "../interfaces/IV2OvenueCreditLine.sol";
import {IOvenueJuniorPool} from "../interfaces/IOvenueJuniorPool.sol";
import {IOvenueJuniorLP} from "../interfaces/IOvenueJuniorLP.sol";
import {IOvenueConfig} from "../interfaces/IOvenueConfig.sol";
import {OvenueConfigHelper} from "./OvenueConfigHelper.sol";

/**
 * @title OvenueTranchingLogic
 * @notice Library for handling the payments waterfall
 * @author Goldfinch
 */

library OvenueTranchingLogic {
    // event TranchedPoolAssessed(address indexed pool);
    event PaymentApplied(
        address indexed payer,
        address indexed pool,
        uint256 interestAmount,
        uint256 principalAmount,
        uint256 remainingAmount,
        uint256 reserveAmount
    );

    using WadRayMath for uint256;

    using OvenueConfigHelper for IOvenueConfig;

    struct SliceInfo {
        uint256 reserveFeePercent;
        uint256 interestAccrued;
        uint256 principalAccrued;
    }

    struct ApplyResult {
        uint256 interestRemaining;
        uint256 principalRemaining;
        uint256 reserveDeduction;
        uint256 oldInterestSharePrice;
        uint256 oldPrincipalSharePrice;
    }

    uint256 internal constant FP_SCALING_FACTOR = 1e18;
    uint256 public constant NUM_TRANCHES_PER_SLICE = 2;

    function usdcToSharePrice(uint256 amount, uint256 totalShares)
        public
        pure
        returns (uint256)
    {
        return
            totalShares == 0
                ? 0
                : amount.wadDiv(totalShares);
    }

    function sharePriceToUsdc(uint256 sharePrice, uint256 totalShares)
        public
        pure
        returns (uint256)
    {
        return sharePrice * totalShares / WadRayMath.WAD;
    }

    function lockTranche(
        IOvenueJuniorPool.TrancheInfo storage tranche,
        IOvenueConfig config
    ) external {
        tranche.lockedUntil = block.timestamp + (
            config.getDrawdownPeriodInSeconds()
        );
        emit TrancheLocked(address(this), tranche.id, tranche.lockedUntil);
    }

    function redeemableInterestAndPrincipal(
        IOvenueJuniorPool.TrancheInfo storage trancheInfo,
        IOvenueJuniorLP.TokenInfo memory tokenInfo
    ) public view returns (uint256, uint256) {
        // This supports withdrawing before or after locking because principal share price starts at 1
        // and is set to 0 on lock. Interest share price is always 0 until interest payments come back, when it increases
        uint256 maxPrincipalRedeemable = sharePriceToUsdc(
            trancheInfo.principalSharePrice,
            tokenInfo.principalAmount
        );
        // The principalAmount is used as the totalShares because we want the interestSharePrice to be expressed as a
        // percent of total loan value e.g. if the interest is 10% APR, the interestSharePrice should approach a max of 0.1.
        uint256 maxInterestRedeemable = sharePriceToUsdc(
            trancheInfo.interestSharePrice,
            tokenInfo.principalAmount
        );

        uint256 interestRedeemable = maxInterestRedeemable - (
            tokenInfo.interestRedeemed
        );
        uint256 principalRedeemable = maxPrincipalRedeemable - (
            tokenInfo.principalRedeemed
        );

        return (interestRedeemable, principalRedeemable);
    }

    function calculateExpectedSharePrice(
        IOvenueJuniorPool.TrancheInfo memory tranche,
        uint256 amount,
        IOvenueJuniorPool.PoolSlice memory slice
    ) public pure returns (uint256) {
        uint256 sharePrice = usdcToSharePrice(
            amount,
            tranche.principalDeposited
        );
        return _scaleByPercentOwnership(tranche, sharePrice, slice);
    }

    function scaleForSlice(
        IOvenueJuniorPool.PoolSlice memory slice,
        uint256 amount,
        uint256 totalDeployed
    ) public pure returns (uint256) {
        return scaleByFraction(amount, slice.principalDeployed, totalDeployed);
    }

    // We need to create this struct so we don't run into a stack too deep error due to too many variables
    function getSliceInfo(
        IOvenueJuniorPool.PoolSlice memory slice,
        IV2OvenueCreditLine creditLine,
        uint256 totalDeployed,
        uint256 reserveFeePercent
    ) public view returns (SliceInfo memory) {
        (
            uint256 interestAccrued,
            uint256 principalAccrued
        ) = getTotalInterestAndPrincipal(slice, creditLine, totalDeployed);
        return
            SliceInfo({
                reserveFeePercent: reserveFeePercent,
                interestAccrued: interestAccrued,
                principalAccrued: principalAccrued
            });
    }

    function getTotalInterestAndPrincipal(
        IOvenueJuniorPool.PoolSlice memory slice,
        IV2OvenueCreditLine creditLine,
        uint256 totalDeployed
    ) public view returns (uint256, uint256) {
        uint256 principalAccrued = creditLine.principalOwed();
        // In addition to principal actually owed, we need to account for early principal payments
        // If the borrower pays back 5K early on a 10K loan, the actual principal accrued should be
        // 5K (balance- deployed) + 0 (principal owed)
        principalAccrued = totalDeployed - creditLine.balance() + principalAccrued;
        // Now we need to scale that correctly for the slice we're interested in
        principalAccrued = scaleForSlice(
            slice,
            principalAccrued,
            totalDeployed
        );
        // Finally, we need to account for partial drawdowns. e.g. If 20K was deposited, and only 10K was drawn down,
        // Then principal accrued should start at 10K (total deposited - principal deployed), not 0. This is because
        // share price starts at 1, and is decremented by what was drawn down.
        uint256 totalDeposited = slice.seniorTranche.principalDeposited + (
            slice.juniorTranche.principalDeposited
        );
        principalAccrued = totalDeposited - slice.principalDeployed + principalAccrued;
        return (slice.totalInterestAccrued, principalAccrued);
    }

    function scaleByFraction(
        uint256 amount,
        uint256 fraction,
        uint256 total
    ) public pure returns (uint256) {
        // uint256 totalAsFixedPoint = FixedPoint
        //     .fromUnscaledUint(total);
        // uint256 memory fractionAsFixedPoint = FixedPoint
        //     .fromUnscaledUint(fraction);
        // return
        //     fractionAsFixedPoint
        //         .div(totalAsFixedPoint)
        //         .mul(amount)
        //         .div(FP_SCALING_FACTOR)
        //         .rawValue;

        return fraction.wadDiv(total).wadMul(amount);
    }

    /// @notice apply a payment to all slices
    /// @param poolSlices slices to apply to
    /// @param numSlices number of slices
    /// @param interest amount of interest to apply
    /// @param principal amount of principal to apply
    /// @param reserveFeePercent percentage that protocol will take for reserves
    /// @param totalDeployed total amount of principal deployed
    /// @param creditLine creditline to account for
    /// @param juniorFeePercent percentage the junior tranche will take
    /// @return total amount that will be sent to reserves
    function applyToAllSlices(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage poolSlices,
        uint256 numSlices,
        uint256 interest,
        uint256 principal,
        uint256 reserveFeePercent,
        uint256 totalDeployed,
        IV2OvenueCreditLine creditLine,
        uint256 juniorFeePercent
    ) external returns (uint256) {
        ApplyResult memory result = OvenueTranchingLogic.applyToAllSeniorTranches(
            poolSlices,
            numSlices,
            interest,
            principal,
            reserveFeePercent,
            totalDeployed,
            creditLine,
            juniorFeePercent
        );

        return
            result.reserveDeduction + (
                OvenueTranchingLogic.applyToAllJuniorTranches(
                    poolSlices,
                    numSlices,
                    result.interestRemaining,
                    result.principalRemaining,
                    reserveFeePercent,
                    totalDeployed,
                    creditLine
                )
            );
    }

    function applyToAllSeniorTranches(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage poolSlices,
        uint256 numSlices,
        uint256 interest,
        uint256 principal,
        uint256 reserveFeePercent,
        uint256 totalDeployed,
        IV2OvenueCreditLine creditLine,
        uint256 juniorFeePercent
    ) internal returns (ApplyResult memory) {
        ApplyResult memory seniorApplyResult;
        for (uint256 i = 0; i < numSlices; i++) {
            IOvenueJuniorPool.PoolSlice storage slice = poolSlices[i];

            SliceInfo memory sliceInfo = getSliceInfo(
                slice,
                creditLine,
                totalDeployed,
                reserveFeePercent
            );

            // Since slices cannot be created when the loan is late, all interest collected can be assumed to split
            // pro-rata across the slices. So we scale the interest and principal to the slice
            ApplyResult memory applyResult = applyToSeniorTranche(
                slice,
                scaleForSlice(slice, interest, totalDeployed),
                scaleForSlice(slice, principal, totalDeployed),
                juniorFeePercent,
                sliceInfo
            );
            emitSharePriceUpdatedEvent(slice.seniorTranche, applyResult);
            seniorApplyResult.interestRemaining = seniorApplyResult
                .interestRemaining
                 + (applyResult.interestRemaining);
            seniorApplyResult.principalRemaining = seniorApplyResult
                .principalRemaining
                 + (applyResult.principalRemaining);
            seniorApplyResult.reserveDeduction = seniorApplyResult
                .reserveDeduction
                 + (applyResult.reserveDeduction);
        }
        return seniorApplyResult;
    }

    function applyToAllJuniorTranches(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage poolSlices,
        uint256 numSlices,
        uint256 interest,
        uint256 principal,
        uint256 reserveFeePercent,
        uint256 totalDeployed,
        IV2OvenueCreditLine creditLine
    ) internal returns (uint256 totalReserveAmount) {
        for (uint256 i = 0; i < numSlices; i++) {
            SliceInfo memory sliceInfo = getSliceInfo(
                poolSlices[i],
                creditLine,
                totalDeployed,
                reserveFeePercent
            );
            // Any remaining interest and principal is then shared pro-rata with the junior slices
            ApplyResult memory applyResult = applyToJuniorTranche(
                poolSlices[i],
                scaleForSlice(poolSlices[i], interest, totalDeployed),
                scaleForSlice(poolSlices[i], principal, totalDeployed),
                sliceInfo
            );
            emitSharePriceUpdatedEvent(
                poolSlices[i].juniorTranche,
                applyResult
            );
            totalReserveAmount = totalReserveAmount + applyResult.reserveDeduction;
        }
        return totalReserveAmount;
    }

    function emitSharePriceUpdatedEvent(
        IOvenueJuniorPool.TrancheInfo memory tranche,
        ApplyResult memory applyResult
    ) internal {
        emit SharePriceUpdated(
            address(this),
            tranche.id,
            tranche.principalSharePrice,
            int256(
                tranche.principalSharePrice - applyResult.oldPrincipalSharePrice
            ),
            tranche.interestSharePrice,
            int256(
                tranche.interestSharePrice - applyResult.oldInterestSharePrice
            )
        );
    }

    function applyToSeniorTranche(
        IOvenueJuniorPool.PoolSlice storage slice,
        uint256 interestRemaining,
        uint256 principalRemaining,
        uint256 juniorFeePercent,
        SliceInfo memory sliceInfo
    ) internal returns (ApplyResult memory) {
        // First determine the expected share price for the senior tranche. This is the gross amount the senior
        // tranche should receive.
        uint256 expectedInterestSharePrice = calculateExpectedSharePrice(
            slice.seniorTranche,
            sliceInfo.interestAccrued,
            slice
        );
        uint256 expectedPrincipalSharePrice = calculateExpectedSharePrice(
            slice.seniorTranche,
            sliceInfo.principalAccrued,
            slice
        );

        // Deduct the junior fee and the protocol reserve
        uint256 desiredNetInterestSharePrice = scaleByFraction(
            expectedInterestSharePrice,
            uint256(100) - (juniorFeePercent + (sliceInfo.reserveFeePercent)),
            uint256(100)
        );
        // Collect protocol fee interest received (we've subtracted this from the senior portion above)
        uint256 reserveDeduction = scaleByFraction(
            interestRemaining,
            sliceInfo.reserveFeePercent,
            uint256(100)
        );
        interestRemaining = interestRemaining - reserveDeduction;
        uint256 oldInterestSharePrice = slice.seniorTranche.interestSharePrice;
        uint256 oldPrincipalSharePrice = slice
            .seniorTranche
            .principalSharePrice;
        // Apply the interest remaining so we get up to the netInterestSharePrice
        (interestRemaining, principalRemaining) = _applyBySharePrice(
            slice.seniorTranche,
            interestRemaining,
            principalRemaining,
            desiredNetInterestSharePrice,
            expectedPrincipalSharePrice
        );
        return
            ApplyResult({
                interestRemaining: interestRemaining,
                principalRemaining: principalRemaining,
                reserveDeduction: reserveDeduction,
                oldInterestSharePrice: oldInterestSharePrice,
                oldPrincipalSharePrice: oldPrincipalSharePrice
            });
    }

    function applyToJuniorTranche(
        IOvenueJuniorPool.PoolSlice storage slice,
        uint256 interestRemaining,
        uint256 principalRemaining,
        SliceInfo memory sliceInfo
    ) public returns (ApplyResult memory) {
        // Then fill up the junior tranche with all the interest remaining, upto the principal share price
        uint256 expectedInterestSharePrice = slice
            .juniorTranche
            .interestSharePrice
            + (
                usdcToSharePrice(
                    interestRemaining,
                    slice.juniorTranche.principalDeposited
                )
            );
        uint256 expectedPrincipalSharePrice = calculateExpectedSharePrice(
            slice.juniorTranche,
            sliceInfo.principalAccrued,
            slice
        );
        uint256 oldInterestSharePrice = slice.juniorTranche.interestSharePrice;
        uint256 oldPrincipalSharePrice = slice
            .juniorTranche
            .principalSharePrice;
        (interestRemaining, principalRemaining) = _applyBySharePrice(
            slice.juniorTranche,
            interestRemaining,
            principalRemaining,
            expectedInterestSharePrice,
            expectedPrincipalSharePrice
        );

        // All remaining interest and principal is applied towards the junior tranche as interest
        interestRemaining = interestRemaining + principalRemaining;
        // Since any principal remaining is treated as interest (there is "extra" interest to be distributed)
        // we need to make sure to collect the protocol fee on the additional interest (we only deducted the
        // fee on the original interest portion)
        uint256 reserveDeduction = scaleByFraction(
            principalRemaining,
            sliceInfo.reserveFeePercent,
            uint256(100)
        );
        interestRemaining = interestRemaining - reserveDeduction;
        principalRemaining = 0;

        (interestRemaining, principalRemaining) = _applyByAmount(
            slice.juniorTranche,
            interestRemaining + principalRemaining,
            0,
            interestRemaining + principalRemaining,
            0
        );
        return
            ApplyResult({
                interestRemaining: interestRemaining,
                principalRemaining: principalRemaining,
                reserveDeduction: reserveDeduction,
                oldInterestSharePrice: oldInterestSharePrice,
                oldPrincipalSharePrice: oldPrincipalSharePrice
            });
    }

    function migrateAccountingVariables(
        IV2OvenueCreditLine originalCl,
        IV2OvenueCreditLine newCl
    ) external {
        // Copy over all accounting variables
        newCl.setBalance(originalCl.balance());
        newCl.setLimit(originalCl.limit());
        newCl.setInterestOwed(originalCl.interestOwed());
        newCl.setPrincipalOwed(originalCl.principalOwed());
        newCl.setTermEndTime(originalCl.termEndTime());
        newCl.setNextDueTime(originalCl.nextDueTime());
        newCl.setInterestAccruedAsOf(originalCl.interestAccruedAsOf());
        newCl.setLastFullPaymentTime(originalCl.lastFullPaymentTime());
        newCl.setTotalInterestAccrued(originalCl.totalInterestAccrued());
    }

    function closeCreditLine(IV2OvenueCreditLine cl) external {
        // Close out old CL
        cl.setBalance(0);
        cl.setLimit(0);
        cl.setMaxLimit(0);
    }

    function trancheIdToSliceIndex(uint256 trancheId)
        external
        pure
        returns (uint256)
    {
        return (trancheId - 1) / NUM_TRANCHES_PER_SLICE;
    }

    function initializeNextSlice(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage poolSlices,
        uint256 sliceIndex
    ) external {
        poolSlices[sliceIndex] = IOvenueJuniorPool.PoolSlice({
            seniorTranche: IOvenueJuniorPool.TrancheInfo({
                id: sliceIndexToSeniorTrancheId(sliceIndex),
                principalSharePrice: usdcToSharePrice(1, 1),
                interestSharePrice: 0,
                principalDeposited: 0,
                lockedUntil: 0
            }),
            juniorTranche: IOvenueJuniorPool.TrancheInfo({
                id: sliceIndexToJuniorTrancheId(sliceIndex),
                principalSharePrice: usdcToSharePrice(1, 1),
                interestSharePrice: 0,
                principalDeposited: 0,
                lockedUntil: 0
            }),
            totalInterestAccrued: 0,
            principalDeployed: 0,
            collateralDeposited: 0
        });
    }

    function sliceIndexToJuniorTrancheId(uint256 sliceIndex)
        public
        pure
        returns (uint256)
    {
        // 0 -> 2
        // 1 -> 4
        return sliceIndex* NUM_TRANCHES_PER_SLICE + 2;
    }

    function sliceIndexToSeniorTrancheId(uint256 sliceIndex)
        public
        pure
        returns (uint256)
    {
        // 0 -> 1
        // 1 -> 3
        return sliceIndex * NUM_TRANCHES_PER_SLICE + 1;
    }

    function isSeniorTrancheId(uint256 trancheId) external pure returns (bool) {
        uint seniorTrancheId;
        uint numberOfTranchesPerSlice = OvenueTranchingLogic.NUM_TRANCHES_PER_SLICE;
        
        assembly {
            seniorTrancheId := mod(trancheId, numberOfTranchesPerSlice)
        }

        return seniorTrancheId == 1;
    }

    function isJuniorTrancheId(uint256 trancheId) external pure returns (bool) {
        uint juniorTrancheId;
        uint numberOfTranchesPerSlice = OvenueTranchingLogic.NUM_TRANCHES_PER_SLICE;

        assembly {
            juniorTrancheId := mod(trancheId, numberOfTranchesPerSlice)
        }

        return trancheId != 0 && juniorTrancheId == 0;
    }

    // // INTERNAL //////////////////////////////////////////////////////////////////

    function _applyToSharePrice(
        uint256 amountRemaining,
        uint256 currentSharePrice,
        uint256 desiredAmount,
        uint256 totalShares
    ) internal pure returns (uint256, uint256) {
        // If no money left to apply, or don't need any changes, return the original amounts
        if (amountRemaining == 0 || desiredAmount == 0) {
            return (amountRemaining, currentSharePrice);
        }
        if (amountRemaining < desiredAmount) {
            // We don't have enough money to adjust share price to the desired level. So just use whatever amount is left
            desiredAmount = amountRemaining;
        }
        uint256 sharePriceDifference = usdcToSharePrice(
            desiredAmount,
            totalShares
        );
        return (
            amountRemaining - desiredAmount,
            currentSharePrice + sharePriceDifference
        );
    }

    function _scaleByPercentOwnership(
        IOvenueJuniorPool.TrancheInfo memory tranche,
        uint256 amount,
        IOvenueJuniorPool.PoolSlice memory slice
    ) internal pure returns (uint256) {
        uint256 totalDeposited = slice.juniorTranche.principalDeposited + (
            slice.seniorTranche.principalDeposited
        );
        return
            scaleByFraction(amount, tranche.principalDeposited, totalDeposited);
    }

    function _desiredAmountFromSharePrice(
        uint256 desiredSharePrice,
        uint256 actualSharePrice,
        uint256 totalShares
    ) internal pure returns (uint256) {
        // If the desired share price is lower, then ignore it, and leave it unchanged
        if (desiredSharePrice < actualSharePrice) {
            desiredSharePrice = actualSharePrice;
        }
        uint256 sharePriceDifference = desiredSharePrice - actualSharePrice;
        return sharePriceToUsdc(sharePriceDifference, totalShares);
    }

    function _applyByAmount(
        IOvenueJuniorPool.TrancheInfo storage tranche,
        uint256 interestRemaining,
        uint256 principalRemaining,
        uint256 desiredInterestAmount,
        uint256 desiredPrincipalAmount
    ) internal returns (uint256, uint256) {
        uint256 totalShares = tranche.principalDeposited;
        uint256 newSharePrice;

        (interestRemaining, newSharePrice) = _applyToSharePrice(
            interestRemaining,
            tranche.interestSharePrice,
            desiredInterestAmount,
            totalShares
        );
        tranche.interestSharePrice = newSharePrice;

        (principalRemaining, newSharePrice) = _applyToSharePrice(
            principalRemaining,
            tranche.principalSharePrice,
            desiredPrincipalAmount,
            totalShares
        );
        tranche.principalSharePrice = newSharePrice;
        return (interestRemaining, principalRemaining);
    }

    function _applyBySharePrice(
        IOvenueJuniorPool.TrancheInfo storage tranche,
        uint256 interestRemaining,
        uint256 principalRemaining,
        uint256 desiredInterestSharePrice,
        uint256 desiredPrincipalSharePrice
    ) internal returns (uint256, uint256) {
        uint256 desiredInterestAmount = _desiredAmountFromSharePrice(
            desiredInterestSharePrice,
            tranche.interestSharePrice,
            tranche.principalDeposited
        );
        uint256 desiredPrincipalAmount = _desiredAmountFromSharePrice(
            desiredPrincipalSharePrice,
            tranche.principalSharePrice,
            tranche.principalDeposited
        );
        return
            _applyByAmount(
                tranche,
                interestRemaining,
                principalRemaining,
                desiredInterestAmount,
                desiredPrincipalAmount
            );
    }

    // // Events /////////////////////////////////////////////////////////////////////

    // NOTE: this needs to match the event in TranchedPool
    event TrancheLocked(
        address indexed pool,
        uint256 trancheId,
        uint256 lockedUntil
    );

    event SharePriceUpdated(
        address indexed pool,
        uint256 indexed tranche,
        uint256 principalSharePrice,
        int256 principalDelta,
        uint256 interestSharePrice,
        int256 interestDelta
    );
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.5;

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library WadRayMath {
  // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
  uint256 internal constant WAD = 1e18;
  uint256 internal constant HALF_WAD = 0.5e18;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant HALF_RAY = 0.5e27;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_WAD), WAD)
    }
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, WAD), div(b, 2)), b)
    }
  }

  /**
   * @notice Multiplies two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raymul b
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_RAY), RAY)
    }
  }

  /**
   * @notice Divides two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raydiv b
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, RAY), div(b, 2)), b)
    }
  }

  /**
   * @dev Casts ray down to wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @return b = a converted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256 b) {
    assembly {
      b := div(a, WAD_RAY_RATIO)
      let remainder := mod(a, WAD_RAY_RATIO)
      if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
        b := add(b, 1)
      }
    }
  }

  /**
   * @dev Converts wad up to ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @return b = a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256 b) {
    // to avoid overflow, b/WAD_RAY_RATIO == a
    assembly {
      b := mul(a, WAD_RAY_RATIO)

      if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
        revert(0, 0)
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import {IOvenueJuniorRewards} from "../interfaces/IOvenueJuniorRewards.sol";
import {IOvenueJuniorPool} from "../interfaces/IOvenueJuniorPool.sol";
import {IOvenueJuniorLP} from "../interfaces/IOvenueJuniorLP.sol";
import {IOvenueConfig} from "../interfaces/IOvenueConfig.sol";
import {IERC20withDec} from "../interfaces/IERC20withDec.sol";
import {OvenueTranchingLogic} from "./OvenueTranchingLogic.sol";
import {OvenueConfigHelper} from "./OvenueConfigHelper.sol";
import {IV2OvenueCreditLine} from "../interfaces/IV2OvenueCreditLine.sol";
import {IGo} from "../interfaces/IGo.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./Math.sol";


library OvenueJuniorPoolLogic {
    using OvenueTranchingLogic for IOvenueJuniorPool.PoolSlice;
    using OvenueTranchingLogic for IOvenueJuniorPool.TrancheInfo;
    using OvenueConfigHelper for IOvenueConfig;
    using SafeERC20Upgradeable for IERC20withDec;

    event ReserveFundsCollected(address indexed from, uint256 amount);

    event PaymentApplied(
        address indexed payer,
        address indexed pool,
        uint256 interestAmount,
        uint256 principalAmount,
        uint256 remainingAmount,
        uint256 reserveAmount
    );

    event DepositMade(
        address indexed owner,
        uint256 indexed tranche,
        uint256 indexed tokenId,
        uint256 amount
    );

    event WithdrawalMade(
        address indexed owner,
        uint256 indexed tranche,
        uint256 indexed tokenId,
        uint256 interestWithdrawn,
        uint256 principalWithdrawn
    );

    event SharePriceUpdated(
        address indexed pool,
        uint256 indexed tranche,
        uint256 principalSharePrice,
        int256 principalDelta,
        uint256 interestSharePrice,
        int256 interestDelta
    );

    event DrawdownMade(address indexed borrower, uint256 amount);
    event EmergencyShutdown(address indexed pool);
    event SliceCreated(address indexed pool, uint256 sliceId);

    function pay(
         mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        // IV2OvenueCreditLine creditLine,
        // IOvenueConfig config,
        // creditline - config
        address[2] calldata addresses,
        // numSlices - totalDeployed - juniorFeePercent - amount
        uint256[4] memory uints
    ) external returns(uint) {
        uint paymentAmount = uints[3];
        /// @dev  IA: cannot pay 0
        require(paymentAmount > 0, "IA");
        IOvenueConfig(addresses[1]).getUSDC().safeTransferFrom(msg.sender, addresses[0], paymentAmount);
        return assess(
            _poolSlices,
            addresses,
            [uints[0], uints[1], uints[2]]
        );
    }

    function deposit(
        IOvenueJuniorPool.TrancheInfo storage trancheInfo,
        IOvenueConfig config,
        uint256 amount
    ) external returns (uint256) {
        trancheInfo.principalDeposited =
            trancheInfo.principalDeposited +
            amount;

        uint256 tokenId = config.getJuniorLP().mint(
            IOvenueJuniorLP.MintParams({
                tranche: trancheInfo.id,
                principalAmount: amount
            }),
            msg.sender
        );

        config.getUSDC().safeTransferFrom(msg.sender, address(this), amount);
        emit DepositMade(msg.sender, trancheInfo.id, tokenId, amount);
        return tokenId;
    }

    function withdraw(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 numSlices,
        uint256 tokenId,
        uint256 amount,
        IOvenueConfig config
    ) public returns (uint256, uint256) {
        IOvenueJuniorLP.TokenInfo memory tokenInfo = config
            .getJuniorLP()
            .getTokenInfo(tokenId);
        IOvenueJuniorPool.TrancheInfo storage trancheInfo = _getTrancheInfo(
            _poolSlices,
            numSlices,
            tokenInfo.tranche
        );

        /// @dev IA: invalid amount. Cannot withdraw 0
        require(amount > 0, "IA");
        (
            uint256 interestRedeemable,
            uint256 principalRedeemable
        ) = OvenueTranchingLogic.redeemableInterestAndPrincipal(
                trancheInfo,
                tokenInfo
            );
        uint256 netRedeemable = interestRedeemable + principalRedeemable;
        /// @dev IA: invalid amount. User does not have enough available to redeem
        require(amount <= netRedeemable, "IA");
        /// @dev TL: Tranched Locked
        require(block.timestamp > trancheInfo.lockedUntil, "TL");

        uint256 interestToRedeem = 0;
        uint256 principalToRedeem = 0;

        // If the tranche has not been locked, ensure the deposited amount is correct
        if (trancheInfo.lockedUntil == 0) {
            trancheInfo.principalDeposited =
                trancheInfo.principalDeposited -
                amount;

            principalToRedeem = amount;

            config.getJuniorLP().withdrawPrincipal(tokenId, principalToRedeem);
        } else {
            interestToRedeem = Math.min(interestRedeemable, amount);
            principalToRedeem = Math.min(
                principalRedeemable,
                amount - interestToRedeem
            );

            config.getJuniorLP().redeem(
                tokenId,
                principalToRedeem,
                interestToRedeem
            );
        }

        config.getUSDC().safeTransferFrom(
            address(this),
            msg.sender,
            principalToRedeem + interestToRedeem
        );

        emit WithdrawalMade(
            msg.sender,
            tokenInfo.tranche,
            tokenId,
            interestToRedeem,
            principalToRedeem
        );

        return (interestToRedeem, principalToRedeem);
    }

    function withdrawMax(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 numSlices,
        uint256 tokenId,
        IOvenueConfig config
    ) external returns (uint256, uint256) {
        IOvenueJuniorLP.TokenInfo memory tokenInfo = config
            .getJuniorLP()
            .getTokenInfo(tokenId);
        IOvenueJuniorPool.TrancheInfo storage trancheInfo = _getTrancheInfo(
            _poolSlices,
            numSlices,
            tokenInfo.tranche
        );

        (
            uint256 interestRedeemable,
            uint256 principalRedeemable
        ) = OvenueTranchingLogic.redeemableInterestAndPrincipal(
                trancheInfo,
                tokenInfo
            );

        uint256 amount = interestRedeemable + principalRedeemable;

        return withdraw(_poolSlices, numSlices, tokenId, amount, config);
    }

    function drawdown(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        IV2OvenueCreditLine creditLine,
        IOvenueConfig config,
        uint256 numSlices,
        uint256 amount,
        uint256 totalDeployed
    ) external returns (uint256) {
        if (!_locked(_poolSlices, numSlices)) {
            // Assumes the senior pool has invested already (saves the borrower a separate transaction to lock the pool)
            _lockPool(_poolSlices, creditLine, config, numSlices);
        }
        // Drawdown only draws down from the current slice for simplicity. It's harder to account for how much
        // money is available from previous slices since depositors can redeem after unlock.
        IOvenueJuniorPool.PoolSlice storage currentSlice = _poolSlices[
            numSlices - 1
        ];
        uint256 amountAvailable = OvenueTranchingLogic.sharePriceToUsdc(
            currentSlice.juniorTranche.principalSharePrice,
            currentSlice.juniorTranche.principalDeposited
        );
        amountAvailable =
            amountAvailable +
            (
                OvenueTranchingLogic.sharePriceToUsdc(
                    currentSlice.seniorTranche.principalSharePrice,
                    currentSlice.seniorTranche.principalDeposited
                )
            );

        // @dev IF: insufficient funds
        require(amount <= amountAvailable, "IF");

        creditLine.drawdown(amount);
        // Update the share price to reflect the amount remaining in the pool
        uint256 amountRemaining = amountAvailable - amount;
        uint256 oldJuniorPrincipalSharePrice = currentSlice
            .juniorTranche
            .principalSharePrice;
        uint256 oldSeniorPrincipalSharePrice = currentSlice
            .seniorTranche
            .principalSharePrice;
        currentSlice.juniorTranche.principalSharePrice = currentSlice
            .juniorTranche
            .calculateExpectedSharePrice(amountRemaining, currentSlice);
        currentSlice.seniorTranche.principalSharePrice = currentSlice
            .seniorTranche
            .calculateExpectedSharePrice(amountRemaining, currentSlice);
        currentSlice.principalDeployed =
            currentSlice.principalDeployed +
            amount;
        totalDeployed = totalDeployed + amount;

        address borrower = creditLine.borrower();

        // _calcJuniorRewards(config, numSlices);
        config.getUSDC().safeTransferFrom(address(this), borrower, amount);

        emit DrawdownMade(borrower, amount);
        emit SharePriceUpdated(
            address(this),
            currentSlice.juniorTranche.id,
            currentSlice.juniorTranche.principalSharePrice,
            int256(
                oldJuniorPrincipalSharePrice -
                    currentSlice.juniorTranche.principalSharePrice
            ) * -1,
            currentSlice.juniorTranche.interestSharePrice,
            0
        );
        emit SharePriceUpdated(
            address(this),
            currentSlice.seniorTranche.id,
            currentSlice.seniorTranche.principalSharePrice,
            int256(
                oldSeniorPrincipalSharePrice -
                    currentSlice.seniorTranche.principalSharePrice
            ) * -1,
            currentSlice.seniorTranche.interestSharePrice,
            0
        );

        return totalDeployed;
    }

    // function _calcJuniorRewards(IOvenueConfig config, uint256 numSlices)
    //     internal
    // {
    //     IOvenueJuniorRewards juniorRewards = IOvenueJuniorRewards(
    //         config.juniorRewardsAddress()
    //     );
    //     juniorRewards.onTranchedPoolDrawdown(numSlices - 1);
    // }

    function _lockPool(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        IV2OvenueCreditLine creditLine,
        IOvenueConfig config,
        uint256 numSlices
    ) internal {
        IOvenueJuniorPool.PoolSlice storage slice = _poolSlices[numSlices - 1];
        /// @dev NL: Not locked
        require(slice.juniorTranche.lockedUntil > 0, "NL");
        // Allow locking the pool only once; do not allow extending the lock of an
        // already-locked pool. Otherwise the locker could keep the pool locked
        // indefinitely, preventing withdrawals.
        /// @dev TL: tranche locked. The senior pool has already been locked.
        require(slice.seniorTranche.lockedUntil == 0, "TL");

        uint256 currentTotal = slice.juniorTranche.principalDeposited +
            slice.seniorTranche.principalDeposited;
        creditLine.setLimit(
            Math.min(creditLine.limit() + currentTotal, creditLine.maxLimit())
        );

        // We start the drawdown period, so backers can withdraw unused capital after borrower draws down
        OvenueTranchingLogic.lockTranche(slice.juniorTranche, config);
        OvenueTranchingLogic.lockTranche(slice.seniorTranche, config);
    }

    function _locked(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 numSlices
    ) internal view returns (bool) {
        return
            numSlices == 0 ||
            _poolSlices[numSlices - 1].seniorTranche.lockedUntil > 0;
    }

    // function locked(
    //     mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
    //     uint256 numSlices
    // ) internal view returns (bool) {
    //     return _locked(_poolSlices, numSlices);
    // }

    function lockPool(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        IV2OvenueCreditLine creditLine,
        IOvenueConfig config,
        uint256 numSlices
    ) external {
        _lockPool(_poolSlices, creditLine, config, numSlices);
    }

    function availableToWithdraw(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 numSlices,
        IOvenueConfig config,
        uint256 tokenId
    ) external view returns (uint256, uint256) {
        IOvenueJuniorLP.TokenInfo memory tokenInfo = config
            .getJuniorLP()
            .getTokenInfo(tokenId);

        IOvenueJuniorPool.TrancheInfo
            storage trancheInfo = OvenueJuniorPoolLogic._getTrancheInfo(
                _poolSlices,
                numSlices,
                tokenInfo.tranche
            );

        if (block.timestamp > trancheInfo.lockedUntil) {
            return
                OvenueTranchingLogic.redeemableInterestAndPrincipal(
                    trancheInfo,
                    tokenInfo
                );
        } else {
            return (0, 0);
        }
    }

    function emergencyShutdown(
        IOvenueConfig config,
        IV2OvenueCreditLine creditLine
    ) external {
        IERC20withDec usdc = config.getUSDC();
        address reserveAddress = config.reserveAddress();
        // // Sweep any funds to community reserve
        uint256 poolBalance = usdc.balanceOf(address(this));
        if (poolBalance > 0) {
            config.getUSDC().safeTransfer(reserveAddress, poolBalance);
        }

        uint256 clBalance = usdc.balanceOf(address(creditLine));
        if (clBalance > 0) {
            usdc.safeTransferFrom(
                address(creditLine),
                reserveAddress,
                clBalance
            );
        }
        emit EmergencyShutdown(address(this));
    }

    function assess(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        // creditline - config
        address[2] calldata addresses,
        // numSlices - totalDeployed - juniorFeePercent
        uint256[3] memory uints
    )
        public
        returns (
            // total deployed
            uint256
        )
    {
        require(_locked(_poolSlices, uints[0]), "NL");

        uint256 interestAccrued = IV2OvenueCreditLine(addresses[0])
            .totalInterestAccrued();
        (
            uint256 paymentRemaining,
            uint256 interestPayment,
            uint256 principalPayment
        ) = IV2OvenueCreditLine(addresses[0]).assess();
        interestAccrued =
            IV2OvenueCreditLine(addresses[0]).totalInterestAccrued() -
            interestAccrued;

        uint256[] memory principalPaymentsPerSlice = _calcInterest(
            _poolSlices,
            interestAccrued,
            principalPayment,
            uints[1],
            uints[0]
        );

        if (interestPayment > 0 || principalPayment > 0) {
            // uint256[] memory uintParams = new uint256[](5);
            uint256 reserveAmount = _applyToAllSlices(
                _poolSlices,
                [
                    uints[0],
                    interestPayment,
                    principalPayment + paymentRemaining,
                    uints[1],
                    uints[2]
                ],
                addresses
            );

            IOvenueConfig(addresses[1]).getUSDC().safeTransferFrom(
                addresses[0],
                address(this),
                principalPayment + paymentRemaining
            );
            IOvenueConfig(addresses[1]).getUSDC().safeTransferFrom(
                address(this),
                IOvenueConfig(addresses[1]).reserveAddress(),
                reserveAmount
            );

            emit ReserveFundsCollected(address(this), reserveAmount);

            // i < numSlices
            for (uint256 i = 0; i < uints[0]; i++) {
                _poolSlices[i].principalDeployed =
                    _poolSlices[i].principalDeployed -
                    principalPaymentsPerSlice[i];
                // totalDeployed = totalDeployed - principalPaymentsPerSlice[i];
                uints[1] = uints[1] - principalPaymentsPerSlice[i];
            }

            IOvenueConfig(addresses[1]).getJuniorRewards().allocateRewards(
                interestPayment
            );

            emit PaymentApplied(
                IV2OvenueCreditLine(addresses[0]).borrower(),
                address(this),
                interestPayment,
                principalPayment,
                paymentRemaining,
                reserveAmount
            );
        }

        // totaldeployed - uints[1]
        return uints[1];
    }

    function _applyToAllSlices(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        // numSlices - interest - principal - totalDeployed  - JuniorFeePercent
        uint256[5] memory uints,
        // creditline - config
        address[2] calldata addresses
    )
        internal
        returns (
            // IV2OvenueCreditLine creditLine
            uint256
        )
    {
        return
            OvenueTranchingLogic.applyToAllSlices(
                _poolSlices,
                uints[0],
                uints[1],
                uints[2],
                uint256(100) / (IOvenueConfig(addresses[1]).getReserveDenominator()), // Convert the denonminator to percent
                uints[3],
                IV2OvenueCreditLine(addresses[0]),
                uints[4]
            );
    }

    function _calcInterest(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 interestAccrued,
        uint256 principalPayment,
        uint256 totalDeployed,
        uint256 numSlices
    ) internal returns (uint256[] memory principalPaymentsPerSlice) {
        principalPaymentsPerSlice = new uint256[](numSlices);

        for (uint256 i = 0; i < numSlices; i++) {
            uint256 interestForSlice = OvenueTranchingLogic.scaleByFraction(
                interestAccrued,
                _poolSlices[i].principalDeployed,
                totalDeployed
            );
            principalPaymentsPerSlice[i] = OvenueTranchingLogic.scaleByFraction(
                principalPayment,
                _poolSlices[i].principalDeployed,
                totalDeployed
            );
            _poolSlices[i].totalInterestAccrued =
                _poolSlices[i].totalInterestAccrued +
                interestForSlice;
        }
    }

    function _getTrancheInfo(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 numSlices,
        uint256 trancheId
    ) internal view returns (IOvenueJuniorPool.TrancheInfo storage) {
        require(
            trancheId > 0 &&
                trancheId <= numSlices * OvenueTranchingLogic.NUM_TRANCHES_PER_SLICE,
            "invalid tranche"
        );
        uint256 sliceId = OvenueTranchingLogic.trancheIdToSliceIndex(trancheId);
        IOvenueJuniorPool.PoolSlice storage slice = _poolSlices[sliceId];
        IOvenueJuniorPool.TrancheInfo storage trancheInfo = OvenueTranchingLogic
            .isSeniorTrancheId(trancheId)
            ? slice.seniorTranche
            : slice.juniorTranche;
        return trancheInfo;
    }

    function getTrancheInfo(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 numSlices,
        uint256 trancheId
    ) external view returns (IOvenueJuniorPool.TrancheInfo storage) {
        return _getTrancheInfo(_poolSlices, numSlices, trancheId);
    }

    function initializeNextSlice(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 numSlices
    ) public returns (uint256) {
        /// @dev SL: slice limit
        require(numSlices < 5, "SL");
        OvenueTranchingLogic.initializeNextSlice(_poolSlices, numSlices);
        numSlices = numSlices + 1;

        return numSlices;
    }

    function initializeAnotherNextSlice(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        IV2OvenueCreditLine creditLine,
        uint256 numSlices
    ) external returns (uint256) {
        /// @dev NL: not locked
        require(_locked(_poolSlices, numSlices), "NL");
        /// @dev LP: late payment
        require(!creditLine.isLate(), "LP");
        /// @dev GP: beyond principal grace period
        require(creditLine.withinPrincipalGracePeriod(), "GP");
        emit SliceCreated(address(this), numSlices - 1);
        return initializeNextSlice(_poolSlices, numSlices);
    }

    function initialize(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 numSlices,
        IOvenueConfig config,
        address _borrower,
        // junior fee percent - late fee apr, interest apr
        uint256[3] calldata _fees,
        // _paymentPeriodInDays - _termInDays - _principalGracePeriodInDays - _fundableAt
        uint256[4] calldata _days,
        uint256 _limit
    )
        external
        returns (
            uint256,
            IV2OvenueCreditLine
        )
    {
        uint256 adjustedNumSlices = initializeNextSlice(
            _poolSlices,
            numSlices
        );

        IV2OvenueCreditLine creditLine = creditLineInitialize(
            config,
            _borrower,
            _fees,
            _days,
            _limit
        );

        return (adjustedNumSlices, creditLine);
    }

    function creditLineInitialize(
        IOvenueConfig config,
        address _borrower,
        // junior fee percent - late fee apr, interest apr
        uint256[3] calldata _fees,
        // _paymentPeriodInDays - _termInDays - _principalGracePeriodInDays - _fundableAt
        uint256[4] calldata _days,
        uint256 _maxLimit
    ) internal returns (IV2OvenueCreditLine) {
        IV2OvenueCreditLine creditLine = IV2OvenueCreditLine(
            config.getOvenueFactory().createCreditLine()
        );

        creditLine.initialize(
            address(config),
            address(this), // Set self as the owner
            _borrower,
            _maxLimit,
            _fees[2],
            _days[0],
            _days[1],
            _fees[1],
            _days[2]
        );

        return creditLine;
    }

    function lockJuniorCapital(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage _poolSlices,
        uint256 numSlices,
        IOvenueConfig config,
        uint256 sliceId
    ) external {
        /// @dev TL: tranch locked
        require(
            !_locked(_poolSlices, numSlices) &&
                _poolSlices[sliceId].juniorTranche.lockedUntil == 0,
            "TL"
        );

        OvenueTranchingLogic.lockTranche(_poolSlices[sliceId].juniorTranche, config);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../libraries/Math.sol";

import {IOvenueJuniorPool} from "../interfaces/IOvenueJuniorPool.sol";
import {IRequiresUID} from "../interfaces/IRequiresUID.sol";
import {IERC20withDec} from "../interfaces/IERC20withDec.sol";
import {IV2OvenueCreditLine} from "../interfaces/IV2OvenueCreditLine.sol";
import {IOvenueJuniorLP} from "../interfaces/IOvenueJuniorLP.sol";
import {IOvenueConfig} from "../interfaces/IOvenueConfig.sol";
import {BaseUpgradeablePausable} from "../upgradeable/BaseUpgradeablePausable.sol";
import {OvenueConfigHelper} from "../libraries/OvenueConfigHelper.sol";
import {OvenueTranchingLogic} from "../libraries/OvenueTranchingLogic.sol";
import {OvenueJuniorPoolLogic} from "../libraries/OvenueJuniorPoolLogic.sol";

contract OvenueJuniorPool is
    BaseUpgradeablePausable,
    IRequiresUID,
    IOvenueJuniorPool
{
    error NFTCollateralNotLocked();
    error CreditLineBalanceExisted(uint256 balance);
    error AddressZeroInitialization();
    error JuniorTranchAlreadyLocked();
    error PoolNotOpened();
    error InvalidDepositAmount(uint256 amount);
    error AllowedUIDNotGranted(address sender);
    error DrawnDownPaused();
    error UnauthorizedCaller();
    error UnmatchedArraysLength();
    error PoolBalanceNotEmpty();
    error NotFullyCollateral();

    IOvenueConfig public config;
    using OvenueConfigHelper for IOvenueConfig;

    // // Events ////////////////////////////////////////////////////////////////////

    event DrawdownsToggled(address indexed pool, bool isAllowed);
    // event TrancheLocked(
    //     address indexed pool,
    //     uint256 trancheId,
    //     uint256 lockedUntil
    // );

    bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");
    bytes32 public constant SENIOR_ROLE = keccak256("SENIOR_ROLE");
    // uint8 internal constant MAJOR_VERSION = 0;
    // uint8 internal constant MINOR_VERSION = 1;
    // uint8 internal constant PATCH_VERSION = 0;

    bool public drawdownsPaused;

    uint256 public juniorFeePercent;
    uint256 public totalDeployed;
    uint256 public fundableAt;
    uint256 public override numSlices;

    uint256[] public allowedUIDTypes;

    mapping(uint256 => PoolSlice) internal _poolSlices;

    function initialize(
        // config - borrower
        address[2] calldata _addresses,
        // junior fee percent - late fee apr, interest apr
        uint256[3] calldata _fees,
        // _paymentPeriodInDays - _termInDays - _principalGracePeriodInDays - _fundableAt
        uint256[4] calldata _days,
        uint256 _limit,
        uint256[] calldata _allowedUIDTypes
    ) external override initializer {
        if (
            !(address(_addresses[0]) != address(0) &&
                address(_addresses[1]) != address(0))
        ) {
            revert AddressZeroInitialization();
        }

     
        config = IOvenueConfig(_addresses[0]);

        address owner = config.protocolAdminAddress();
        __BaseUpgradeablePausable__init(owner);
        

        (numSlices, creditLine) = OvenueJuniorPoolLogic.initialize(
            _poolSlices,
            numSlices,
            config,
            _addresses[1],
            _fees,
            _days,
            _limit
        );

        if (_allowedUIDTypes.length == 0) {
            uint256[1] memory defaultAllowedUIDTypes = [
                config.getGo().ID_TYPE_0()
            ];
            allowedUIDTypes = defaultAllowedUIDTypes;
        } else {
            allowedUIDTypes = _allowedUIDTypes;
        }

        createdAt = block.timestamp;
        fundableAt = _days[3];
        juniorFeePercent = _fees[0];

        _setupRole(LOCKER_ROLE, _addresses[1]);
        _setupRole(LOCKER_ROLE, owner);
        _setRoleAdmin(LOCKER_ROLE, OWNER_ROLE);
        _setRoleAdmin(SENIOR_ROLE, OWNER_ROLE);

        // Give the senior pool the ability to deposit into the senior pool
        _setupRole(SENIOR_ROLE, address(config.getSeniorPool()));

        // Unlock self for infinite amount
        require(config.getUSDC().approve(address(this), type(uint256).max));
    }

    function setAllowedUIDTypes(uint256[] calldata ids) external onlyLocker {
        if (
            !(_poolSlices[0].juniorTranche.principalDeposited == 0 &&
                _poolSlices[0].seniorTranche.principalDeposited == 0)
        ) {
            revert PoolBalanceNotEmpty();
        }

        allowedUIDTypes = ids;
    }

    function getAllowedUIDTypes() external view returns (uint256[] memory) {
        return allowedUIDTypes;
    }

    /**
     * @notice Deposit a USDC amount into the pool for a tranche. Mints an NFT to the caller representing the position
     * @param tranche The number representing the tranche to deposit into
     * @param amount The USDC amount to tranfer from the caller to the pool
     * @return tokenId The tokenId of the NFT
     */
    function deposit(uint256 tranche, uint256 amount)
        public
        override
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        TrancheInfo storage trancheInfo = OvenueJuniorPoolLogic._getTrancheInfo(
            _poolSlices,
            numSlices,
            tranche
        );

        // /// @dev TL: Collateral locked
        if (!config.getCollateralCustody().isCollateralFullyFunded(IOvenueJuniorPool(address(this)))) {
            revert NotFullyCollateral();
        }

        /// @dev TL: tranche locked
        if (trancheInfo.lockedUntil != 0) {
            revert JuniorTranchAlreadyLocked();
        }

        /// @dev TL: Pool not opened
        if (block.timestamp < fundableAt) {
            revert PoolNotOpened();
        }

        /// @dev IA: invalid amount
        if (amount <= 0) {
            revert InvalidDepositAmount(amount);
        }

        /// @dev NA: not authorized. Must have correct UID or be go listed
        if (!hasAllowedUID(msg.sender)) {
            revert AllowedUIDNotGranted(msg.sender);
        }

        // senior tranche ids are always odd numbered
        if (OvenueTranchingLogic.isSeniorTrancheId(trancheInfo.id)) {
            if (!hasRole(SENIOR_ROLE, _msgSender())) {
                revert UnauthorizedCaller();
            }
        }

        return OvenueJuniorPoolLogic.deposit(trancheInfo, config, amount);
    }

    function depositWithPermit(
        uint256 tranche,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override returns (uint256 tokenId) {
        IERC20Permit(config.usdcAddress()).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        return deposit(tranche, amount);
    }

    /**
     * @notice Withdraw an already deposited amount if the funds are available
     * @param tokenId The NFT representing the position
     * @param amount The amount to withdraw (must be <= interest+principal currently available to withdraw)
     * @return interestWithdrawn The interest amount that was withdrawn
     * @return principalWithdrawn The principal amount that was withdrawn
     */
    function withdraw(uint256 tokenId, uint256 amount)
        public
        override
        nonReentrant
        whenNotPaused
        returns (uint256, uint256)
    {
        /// @dev NA: not authorized
        if (
            !(config.getJuniorLP().isApprovedOrOwner(msg.sender, tokenId) &&
                hasAllowedUID(msg.sender))
        ) {
            revert UnauthorizedCaller();
        }
        return
            OvenueJuniorPoolLogic.withdraw(
                _poolSlices,
                numSlices,
                tokenId,
                amount,
                config
            );
    }

    /**
     * @notice Withdraw from many tokens (that the sender owns) in a single transaction
     * @param tokenIds An array of tokens ids representing the position
     * @param amounts An array of amounts to withdraw from the corresponding tokenIds
     */
    function withdrawMultiple(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) public override {
        if (tokenIds.length != amounts.length) {
            revert UnmatchedArraysLength();
        }

        uint256 i;

        while (i < amounts.length) {
            withdraw(tokenIds[i], amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Similar to withdraw but will withdraw all available funds
     * @param tokenId The NFT representing the position
     * @return interestWithdrawn The interest amount that was withdrawn
     * @return principalWithdrawn The principal amount that was withdrawn
     */
    function withdrawMax(uint256 tokenId)
        external
        override
        nonReentrant
        whenNotPaused
        returns (uint256 interestWithdrawn, uint256 principalWithdrawn)
    {
        return
            OvenueJuniorPoolLogic.withdrawMax(
                _poolSlices,
                numSlices,
                tokenId,
                config
            );
    }

    /**
     * @notice Draws down the funds (and locks the pool) to the borrower address. Can only be called by the borrower
     * @param amount The amount to drawdown from the creditline (must be < limit)
     */
    function drawdown(uint256 amount)
        external
        override
        onlyLocker
        whenNotPaused
    {
        /// @dev DP: drawdowns paused
        if (drawdownsPaused) {
            revert DrawnDownPaused();
        }

        totalDeployed = OvenueJuniorPoolLogic.drawdown(
            _poolSlices,
            creditLine,
            config,
            numSlices,
            amount,
            totalDeployed
        );
    }

    function NUM_TRANCHES_PER_SLICE() external pure returns (uint256) {
        return OvenueTranchingLogic.NUM_TRANCHES_PER_SLICE;
    }

    /**
     * @notice Locks the junior tranche, preventing more junior deposits. Gives time for the senior to determine how
     * much to invest (ensure leverage ratio cannot change for the period)
     */
    function lockJuniorCapital() external override onlyLocker whenNotPaused {
        _lockJuniorCapital(numSlices - 1);
    }

    /**
     * @notice Locks the pool (locks both senior and junior tranches and starts the drawdown period). Beyond the drawdown
     * period, any unused capital is available to withdraw by all depositors
     */
    function lockPool() external override onlyLocker whenNotPaused {
        OvenueJuniorPoolLogic.lockPool(
            _poolSlices,
            creditLine,
            config,
            numSlices
        );
    }

    function setFundableAt(uint256 newFundableAt) external override onlyLocker {
        fundableAt = newFundableAt;
    }

    function initializeNextSlice(uint256 _fundableAt)
        external
        override
        onlyLocker
        whenNotPaused
    {
        fundableAt = _fundableAt;
        numSlices = OvenueJuniorPoolLogic.initializeAnotherNextSlice(
            _poolSlices,
            creditLine,
            numSlices
        );
    }

    /**
     * @notice Triggers an assessment of the creditline and the applies the payments according the tranche waterfall
     */
    function assess() external override whenNotPaused {
        totalDeployed = OvenueJuniorPoolLogic.assess(
            _poolSlices,
            [address(creditLine), address(config)],
            [numSlices, totalDeployed, juniorFeePercent]
        );
    }

    // function claimCollateralNFT() external virtual override onlyLocker {
    //     uint256 creditBalance = IV2OvenueCreditLine(creditLine).balance();
    //     if (creditBalance != 0) {
    //         revert CreditLineBalanceExisted(creditBalance);
    //     }

    //     IERC721(collateral.nftAddr).safeTransferFrom(
    //         address(this),
    //         msg.sender,
    //         collateral.tokenId,
    //         ""
    //     );
    //     collateral.isLocked = false;

    //     emit NFTCollateralClaimed(
    //         msg.sender,
    //         collateral.nftAddr,
    //         collateral.tokenId
    //     );
    // }

    /**
     * @notice Allows repaying the creditline. Collects the USDC amount from the sender and triggers an assess
     * @param amount The amount to repay
     */
    function pay(uint256 amount) external override whenNotPaused {
        totalDeployed = OvenueJuniorPoolLogic.pay(
            _poolSlices,
            [address(creditLine), address(config)],
            [numSlices, totalDeployed, juniorFeePercent, amount]
        );
    }

    /**
     * @notice Pauses the pool and sweeps any remaining funds to the treasury reserve.
     */
    function emergencyShutdown() public onlyAdmin {
        if (!paused()) {
            _pause();
        }

        OvenueJuniorPoolLogic.emergencyShutdown(config, creditLine);
    }

    /**
     * @notice Toggles all drawdowns (but not deposits/withdraws)
     */
    function toggleDrawdowns() public onlyAdmin {
        drawdownsPaused = drawdownsPaused ? false : true;
        emit DrawdownsToggled(address(this), drawdownsPaused);
    }

    // CreditLine proxy method
    function setLimit(uint256 newAmount) external onlyAdmin {
        return creditLine.setLimit(newAmount);
    }

    function setMaxLimit(uint256 newAmount) external onlyAdmin {
        return creditLine.setMaxLimit(newAmount);
    }

    function getTranche(uint256 tranche)
        public
        view
        override
        returns (TrancheInfo memory)
    {
        return
            OvenueJuniorPoolLogic._getTrancheInfo(
                _poolSlices,
                numSlices,
                tranche
            );
    }

    function poolSlices(uint256 index)
        external
        view
        override
        returns (PoolSlice memory)
    {
        return _poolSlices[index];
    }

    /**
     * @notice Returns the total junior capital deposited
     * @return The total USDC amount deposited into all junior tranches
     */
    function totalJuniorDeposits() external view override returns (uint256) {
        uint256 total;
        for (uint256 i = 0; i < numSlices; i++) {
            total = total + _poolSlices[i].juniorTranche.principalDeposited;
        }
        return total;
    }

    // /**
    //  * @notice Returns boolean to check if nft is locked
    //  * @return Check whether nft is locked as collateral
    //  */
    // function isCollateralLocked() external view override returns (bool) {
    //     return collateral.isLocked;
    // }

    // function getCollateralInfo()
    //     external
    //     view
    //     virtual
    //     override
    //     returns (
    //         address,
    //         uint256,
    //         bool
    //     )
    // {
    //     return (
    //         collateral.nftAddr,
    //         collateral.tokenId,
    //         collateral.isLocked
    //     );
    // }

    /**
     * @notice Determines the amount of interest and principal redeemable by a particular tokenId
     * @param tokenId The token representing the position
     * @return interestRedeemable The interest available to redeem
     * @return principalRedeemable The principal available to redeem
     */
    function availableToWithdraw(uint256 tokenId)
        public
        view
        override
        returns (uint256, uint256)
    {
        return
            OvenueJuniorPoolLogic.availableToWithdraw(
                _poolSlices,
                numSlices,
                config,
                tokenId
            );
    }

    function hasAllowedUID(address sender) public view override returns (bool) {
        return config.getGo().goOnlyIdTypes(sender, allowedUIDTypes);
    }

    function _lockJuniorCapital(uint256 sliceId) internal {
        OvenueJuniorPoolLogic.lockJuniorCapital(
            _poolSlices,
            numSlices,
            config,
            sliceId
        );
    }

    // // // Modifiers /////////////////////////////////////////////////////////////////

    modifier onlyLocker() {
        /// @dev NA: not authorized. not locker
        if (!hasRole(LOCKER_ROLE, msg.sender)) {
            revert UnauthorizedCaller();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IRequiresUID {
  function hasAllowedUID(address sender) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
pragma solidity 0.8.5;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IOvenueConfig.sol";
import "../interfaces/IOvenueSeniorPool.sol";
import "../interfaces/IOvenueJuniorLP.sol";
import "../helpers/Accountant.sol";
import "../upgradeable/BaseUpgradeablePausable.sol";
import "../libraries/OvenueConfigHelper.sol";
import "./OvenueConfigOptions.sol";


/**
 * @title Ovenue's SeniorPool contract
 * @notice Main entry point for senior LPs (a.k.a. capital providers)
 *  Automatically invests across borrower pools using an adjustable strategy.
 * @author Ovenue
 */
contract OvenueSeniorPool is BaseUpgradeablePausable, IOvenueSeniorPool {
  IOvenueConfig public config;
  using OvenueConfigHelper for IOvenueConfig;
  // using SafeERC20 for IERC20withDec;

  error InvalidWithdrawAmount();

  bytes32 public constant ZAPPER_ROLE = keccak256("ZAPPER_ROLE");

  uint256 public compoundBalance;
  mapping(IOvenueJuniorPool => uint256) public writedowns;

  event DepositMade(address indexed capitalProvider, uint256 amount, uint256 shares);
  event WithdrawalMade(address indexed capitalProvider, uint256 userAmount, uint256 reserveAmount);
  event InterestCollected(address indexed payer, uint256 amount);
  event PrincipalCollected(address indexed payer, uint256 amount);
  event ReserveFundsCollected(address indexed user, uint256 amount);

  event PrincipalWrittenDown(address indexed tranchedPool, int256 amount);
  event InvestmentMadeInSenior(address indexed tranchedPool, uint256 amount);
  event InvestmentMadeInJunior(address indexed tranchedPool, uint256 amount);

  event GoldfinchConfigUpdated(address indexed who, address configAddress);

  function initialize(address owner, IOvenueConfig _config) public initializer {
    require(owner != address(0) && address(_config) != address(0), "Owner and config addresses cannot be empty");

    __BaseUpgradeablePausable__init(owner);

    config = _config;
    sharePrice = _fiduMantissa();
    totalLoansOutstanding = 0;
    totalWritedowns = 0;

    IERC20withDec usdc = config.getUSDC();
    // Sanity check the address
    usdc.totalSupply();
    // shoudl use safe approve in here
    usdc.approve(address(this), type(uint256).max);
  }

  /**
   * @notice Deposits `amount` USDC from msg.sender into the SeniorPool, and grants you the
   *  equivalent value of FIDU tokens
   * @param amount The amount of USDC to deposit
   */
  function deposit(uint256 amount) public override whenNotPaused nonReentrant returns (uint256 depositShares) {
    require(config.getGo().goSeniorPool(msg.sender), "This address has not been go-listed");
    require(amount > 0, "Must deposit more than zero");
    // Check if the amount of new shares to be added is within limits
    depositShares = getNumShares(amount);
    uint256 potentialNewTotalShares = totalShares() + depositShares;
    require(sharesWithinLimit(potentialNewTotalShares), "Deposit would put the senior pool over the total limit.");
    emit DepositMade(msg.sender, amount, depositShares);
    bool success = doUSDCTransfer(msg.sender, address(this), amount);
    require(success, "Failed to transfer for deposit");

    config.getSeniorLP().mintTo(msg.sender, depositShares);
    return depositShares;
  }

  /**
   * @notice Identical to deposit, except it allows for a passed up signature to permit
   *  the Senior Pool to move funds on behalf of the user, all within one transaction.
   * @param amount The amount of USDC to deposit
   * @param v secp256k1 signature component
   * @param r secp256k1 signature component
   * @param s secp256k1 signature component
   */
  function depositWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) public override returns (uint256 depositShares) {
    IERC20Permit(config.usdcAddress()).permit(msg.sender, address(this), amount, deadline, v, r, s);
    return deposit(amount);
  }

  /**
   * @notice Withdraws USDC from the SeniorPool to msg.sender, and burns the equivalent value of FIDU tokens
   * @param usdcAmount The amount of USDC to withdraw
   */
  function withdraw(uint256 usdcAmount) external override whenNotPaused nonReentrant returns (uint256 amount) {
    require(config.getGo().goSeniorPool(msg.sender), "This address has not been go-listed");
    require(usdcAmount > 0, "Must withdraw more than zero");
    // // This MUST happen before calculating withdrawShares, otherwise the share price
    // // changes between calculation and burning of Fidu, which creates a asset/liability mismatch
    // if (compoundBalance > 0) {
    //   _sweepFromCompound();
    // }
    uint256 withdrawShares = getNumShares(usdcAmount);
    return _withdraw(usdcAmount, withdrawShares);
  }

  /**
   * @notice Withdraws USDC (denominated in FIDU terms) from the SeniorPool to msg.sender
   * @param lpAmount The amount of USDC to withdraw in terms of FIDU shares
   */
  function withdrawInLP(uint256 lpAmount) external override whenNotPaused nonReentrant returns (uint256 amount) {
    require(config.getGo().goSeniorPool(msg.sender), "This address has not been go-listed");
    require(lpAmount > 0, "Must withdraw more than zero");
    // // This MUST happen before calculating withdrawShares, otherwise the share price
    // // changes between calculation and burning of Fidu, which creates a asset/liability mismatch
    // if (compoundBalance > 0) {
    //   _sweepFromCompound();
    // }
    uint256 usdcAmount = _getUSDCAmountFromShares(lpAmount);
    uint256 withdrawShares = lpAmount;
    return _withdraw(usdcAmount, withdrawShares);
  }

//   /**
//    * @notice Moves any USDC still in the SeniorPool to Compound, and tracks the amount internally.
//    * This is done to earn interest on latent funds until we have other borrowers who can use it.
//    *
//    * Requirements:
//    *  - The caller must be an admin.
//    */
//   function sweepToCompound() public override onlyAdmin whenNotPaused {
//     IERC20 usdc = config.getUSDC();
//     uint256 usdcBalance = usdc.balanceOf(address(this));

//     ICUSDCContract cUSDC = config.getCUSDCContract();
//     // Approve compound to the exact amount
//     bool success = usdc.approve(address(cUSDC), usdcBalance);
//     require(success, "Failed to approve USDC for compound");

//     _sweepToCompound(cUSDC, usdcBalance);

//     // Remove compound approval to be extra safe
//     success = config.getUSDC().approve(address(cUSDC), 0);
//     require(success, "Failed to approve USDC for compound");
//   }

//   /**
//    * @notice Moves any USDC from Compound back to the SeniorPool, and recognizes interest earned.
//    * This is done automatically on drawdown or withdraw, but can be called manually if necessary.
//    *
//    * Requirements:
//    *  - The caller must be an admin.
//    */
//   function sweepFromCompound() public override onlyAdmin whenNotPaused {
//     _sweepFromCompound();
//   }

  /**
   * @notice Invest in an ITranchedPool's senior tranche using the senior pool's strategy
   * @param pool An ITranchedPool whose senior tranche should be considered for investment
   */
  function invest(IOvenueJuniorPool pool) public override whenNotPaused nonReentrant {
    require(_isValidPool(pool), "Pool must be valid");

    IOvenueSeniorPoolStrategy strategy = config.getSeniorPoolStrategy();
    uint256 amount = strategy.invest(pool);

    require(amount > 0, "Investment amount must be positive");

    _approvePool(pool, amount);
    uint256 nSlices = pool.numSlices();
    require(nSlices >= 1, "Pool has no slices");
    uint256 sliceIndex = nSlices - 1;
    uint256 seniorTrancheId = _sliceIndexToSeniorTrancheId(sliceIndex);
    pool.deposit(seniorTrancheId, amount);

    emit InvestmentMadeInSenior(address(pool), amount);
    totalLoansOutstanding = totalLoansOutstanding + amount;
  }

  function estimateInvestment(IOvenueJuniorPool pool) public view override returns (uint256) {
    require(_isValidPool(pool), "Pool must be valid");
    IOvenueSeniorPoolStrategy strategy = config.getSeniorPoolStrategy();
    return strategy.estimateInvestment(pool);
  }

  /**
   * @notice Redeem interest and/or principal from an ITranchedPool investment
   * @param tokenId the ID of an IPoolTokens token to be redeemed
   */
  function redeem(uint256 tokenId) public override whenNotPaused nonReentrant {
    IOvenueJuniorLP juniorLP = config.getJuniorLP();
    IOvenueJuniorLP.TokenInfo memory tokenInfo = juniorLP.getTokenInfo(tokenId);

    IOvenueJuniorPool pool = IOvenueJuniorPool(tokenInfo.pool);
    (uint256 interestRedeemed, uint256 principalRedeemed) = pool.withdrawMax(tokenId);

    _collectInterestAndPrincipal(address(pool), interestRedeemed, principalRedeemed);
  }

  /**
   * @notice Write down an ITranchedPool investment. This will adjust the senior pool's share price
   *  down if we're considering the investment a loss, or up if the borrower has subsequently
   *  made repayments that restore confidence that the full loan will be repaid.
   * @param tokenId the ID of an IPoolTokens token to be considered for writedown
   */
  function writedown(uint256 tokenId) public override whenNotPaused nonReentrant {
    IOvenueJuniorLP juniorLP = config.getJuniorLP();
    require(address(this) == juniorLP.ownerOf(tokenId), "Only tokens owned by the senior pool can be written down");

    IOvenueJuniorLP.TokenInfo memory tokenInfo = juniorLP.getTokenInfo(tokenId);
    IOvenueJuniorPool pool = IOvenueJuniorPool(tokenInfo.pool);
    require(_isValidPool(pool), "Pool must be valid");

    uint256 principalRemaining = tokenInfo.principalAmount - tokenInfo.principalRedeemed;

    (uint256 writedownPercent, uint256 writedownAmount) = _calculateWritedown(pool, principalRemaining);

    uint256 prevWritedownAmount = writedowns[pool];

    if (writedownPercent == 0 && prevWritedownAmount == 0) {
      return;
    }

    int256 writedownDelta = int256(prevWritedownAmount) - int256(writedownAmount);
    writedowns[pool] = writedownAmount;
    _distributeLosses(writedownDelta);
    if (writedownDelta > 0) {
      // If writedownDelta is positive, that means we got money back. So subtract from totalWritedowns.
      totalWritedowns = totalWritedowns - uint256(writedownDelta);
    } else {
      totalWritedowns = totalWritedowns + uint256(writedownDelta * -1);
    }
    emit PrincipalWrittenDown(address(pool), writedownDelta);
  }

  /**
   * @notice Calculates the writedown amount for a particular pool position
   * @param tokenId The token reprsenting the position
   * @return The amount in dollars the principal should be written down by
   */
  function calculateWritedown(uint256 tokenId) public view override returns (uint256) {
    IOvenueJuniorLP.TokenInfo memory tokenInfo = config.getJuniorLP().getTokenInfo(tokenId);
    IOvenueJuniorPool pool = IOvenueJuniorPool(tokenInfo.pool);

    uint256 principalRemaining = tokenInfo.principalAmount - tokenInfo.principalRedeemed;

    (, uint256 writedownAmount) = _calculateWritedown(pool, principalRemaining);
    return writedownAmount;
  }

  /**
   * @notice Returns the net assests controlled by and owed to the pool
   */
  function assets() public view override returns (uint256) {
    return
      compoundBalance + (config.getUSDC().balanceOf(address(this))) + totalLoansOutstanding - totalWritedowns;
  }

  /**
   * @notice Converts and USDC amount to FIDU amount
   * @param amount USDC amount to convert to FIDU
   */
  function getNumShares(uint256 amount) public view override returns (uint256) {
    return _usdcToFidu(amount) * _fiduMantissa() / sharePrice;
  }

//   /* Internal Functions */

  function _calculateWritedown(IOvenueJuniorPool pool, uint256 principal)
    internal
    view
    returns (uint256 writedownPercent, uint256 writedownAmount)
  {
    return
      Accountant.calculateWritedownForPrincipal(
        pool.creditLine(),
        principal,
        currentTime(),
        config.getLatenessGracePeriodInDays(),
        config.getLatenessMaxDays()
      );
  }

  function currentTime() internal view virtual returns (uint256) {
    return block.timestamp;
  }

  function _distributeLosses(int256 writedownDelta) internal {
    if (writedownDelta > 0) {
      uint256 delta = _usdcToSharePrice(uint256(writedownDelta));
      sharePrice = sharePrice + delta;
    } else {
      // If delta is negative, convert to positive uint, and sub from sharePrice
      uint256 delta = _usdcToSharePrice(uint256(writedownDelta * -1));
      sharePrice = sharePrice - delta;
    }
  }

  function _fiduMantissa() internal pure returns (uint256) {
    return uint256(10)**uint256(18);
  }

  function _usdcMantissa() internal pure returns (uint256) {
    return uint256(10)**uint256(6);
  }

  function _usdcToFidu(uint256 amount) internal pure returns (uint256) {
    return amount * _fiduMantissa() / _usdcMantissa();
  }

  function _fiduToUSDC(uint256 amount) internal pure returns (uint256) {
    return amount / _fiduMantissa() * _usdcMantissa();
  }

  function _getUSDCAmountFromShares(uint256 fiduAmount) internal view returns (uint256) {
    return _fiduToUSDC(fiduAmount * sharePrice / _fiduMantissa()) ;
  }

  function sharesWithinLimit(uint256 _totalShares) internal view returns (bool) {
    return
      _totalShares * sharePrice / _fiduMantissa() <=
      _usdcToFidu(config.getNumber(uint256(OvenueConfigOptions.Numbers.TotalFundsLimit)));
  }

  function doUSDCTransfer(
    address from,
    address to,
    uint256 amount
  ) internal returns (bool) {
    require(to != address(0), "Can't send to zero address");
    IERC20withDec usdc = config.getUSDC();
    return usdc.transferFrom(from, to, amount);
  }

  function _withdraw(uint256 usdcAmount, uint256 withdrawShares) internal returns (uint256 userAmount) {
    IOvenueSeniorLP seniorLP = config.getSeniorLP();
    // Determine current shares the address has and the shares requested to withdraw
    uint256 currentShares = seniorLP.balanceOf(msg.sender);
    // Ensure the address has enough value in the pool
    require(withdrawShares <= currentShares, "Amount requested is greater than what this address owns");

    // Send to reserves
    userAmount = usdcAmount;
    uint256 reserveAmount = 0;

    if (!isZapper()) {
      reserveAmount = usdcAmount / (config.getWithdrawFeeDenominator());
      userAmount = userAmount - reserveAmount;
      _sendToReserve(reserveAmount, msg.sender);
    }

    // Send to user
    bool success = doUSDCTransfer(address(this), msg.sender, userAmount);
    require(success, "Failed to transfer for withdraw");

    // Burn the shares
    seniorLP.burnFrom(msg.sender, withdrawShares);

    emit WithdrawalMade(msg.sender, userAmount, reserveAmount);

    return userAmount;
  }

//   function _sweepToCompound(ICUSDCContract cUSDC, uint256 usdcAmount) internal {
//     // Our current design requires we re-normalize by withdrawing everything and recognizing interest gains
//     // before we can add additional capital to Compound
//     require(compoundBalance == 0, "Cannot sweep when we already have a compound balance");
//     require(usdcAmount != 0, "Amount to sweep cannot be zero");
//     uint256 error = cUSDC.mint(usdcAmount);
//     require(error == 0, "Sweep to compound failed");
//     compoundBalance = usdcAmount;
//   }

//   function _sweepFromCompound() internal {
//     ICUSDCContract cUSDC = config.getCUSDCContract();
//     _sweepFromCompound(cUSDC, cUSDC.balanceOf(address(this)));
//   }

//   function _sweepFromCompound(ICUSDCContract cUSDC, uint256 cUSDCAmount) internal {
//     uint256 cBalance = compoundBalance;
//     require(cBalance != 0, "No funds on compound");
//     require(cUSDCAmount != 0, "Amount to sweep cannot be zero");

//     IERC20 usdc = config.getUSDC();
//     uint256 preRedeemUSDCBalance = usdc.balanceOf(address(this));
//     uint256 cUSDCExchangeRate = cUSDC.exchangeRateCurrent();
//     uint256 redeemedUSDC = _cUSDCToUSDC(cUSDCExchangeRate, cUSDCAmount);

//     uint256 error = cUSDC.redeem(cUSDCAmount);
//     uint256 postRedeemUSDCBalance = usdc.balanceOf(address(this));
//     require(error == 0, "Sweep from compound failed");
//     require(postRedeemUSDCBalance.sub(preRedeemUSDCBalance) == redeemedUSDC, "Unexpected redeem amount");

//     uint256 interestAccrued = redeemedUSDC.sub(cBalance);
//     uint256 reserveAmount = interestAccrued.div(config.getReserveDenominator());
//     uint256 poolAmount = interestAccrued.sub(reserveAmount);

//     _collectInterestAndPrincipal(address(this), poolAmount, 0);

//     if (reserveAmount > 0) {
//       _sendToReserve(reserveAmount, address(cUSDC));
//     }

//     compoundBalance = 0;
//   }

//   function _cUSDCToUSDC(uint256 exchangeRate, uint256 amount) internal pure returns (uint256) {
//     // See https://compound.finance/docs#protocol-math
//     // But note, the docs and reality do not agree. Docs imply that that exchange rate is
//     // scaled by 1e18, but tests and mainnet forking make it appear to be scaled by 1e16
//     // 1e16 is also what Sheraz at Certik said.
//     uint256 usdcDecimals = 6;
//     uint256 cUSDCDecimals = 8;

//     // We multiply in the following order, for the following reasons...
//     // Amount in cToken (1e8)
//     // Amount in USDC (but scaled by 1e16, cause that's what exchange rate decimals are)
//     // Downscale to cToken decimals (1e8)
//     // Downscale from cToken to USDC decimals (8 to 6)
//     return amount.mul(exchangeRate).div(10**(18 + usdcDecimals - cUSDCDecimals)).div(10**2);
//   }

  function _collectInterestAndPrincipal(
    address from,
    uint256 interest,
    uint256 principal
  ) internal {
    uint256 increment = _usdcToSharePrice(interest);
    sharePrice = sharePrice + increment;

    if (interest > 0) {
      emit InterestCollected(from, interest);
    }
    if (principal > 0) {
      emit PrincipalCollected(from, principal);
      totalLoansOutstanding = totalLoansOutstanding - principal;
    }
  }

  function _sendToReserve(uint256 amount, address userForEvent) internal {
    emit ReserveFundsCollected(userForEvent, amount);
    bool success = doUSDCTransfer(address(this), config.reserveAddress(), amount);
    require(success, "Reserve transfer was not successful");
  }

  function _usdcToSharePrice(uint256 usdcAmount) internal view returns (uint256) {
    return _usdcToFidu(usdcAmount) * _fiduMantissa() / totalShares();
  }

  function totalShares() internal view returns (uint256) {
    return config.getSeniorLP().totalSupply();
  }

  function _isValidPool(IOvenueJuniorPool pool) internal view returns (bool) {
    return config.getJuniorLP().validPool(address(pool));
  }

  function _approvePool(IOvenueJuniorPool pool, uint256 allowance) internal {
    IERC20withDec usdc = config.getUSDC();
    bool success = usdc.approve(address(pool), allowance);
    require(success, "Failed to approve USDC");
  }

  function isZapper() public view returns (bool) {
    return hasRole(ZAPPER_ROLE, _msgSender());
  }

  function initZapperRole() external onlyAdmin {
    _setRoleAdmin(ZAPPER_ROLE, OWNER_ROLE);
  }

  /// @notice Returns the senion tranche id for the given slice index
  /// @param index slice index
  /// @return senior tranche id of given slice index
  function _sliceIndexToSeniorTrancheId(uint256 index) internal pure returns (uint256) {
    return index * 2 + 1;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "../interfaces/IOvenueCreditLine.sol";
import "../libraries/WadRayMath.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
/**
 * @title The Accountant`
 * @notice Library for handling key financial calculations, such as interest and principal accrual.
 * @author Goldfinch
 */

library Accountant {
  using WadRayMath for int256;
  using WadRayMath for uint256;

  // Scaling factor used by FixedPoint.sol. We need this to convert the fixed point raw values back to unscaled
  uint256 private constant INTEREST_DECIMALS = 1e18;
  uint256 private constant SECONDS_PER_DAY = 1 days;
  uint256 private constant SECONDS_PER_YEAR = (SECONDS_PER_DAY * 365);

  struct PaymentAllocation {
    uint256 interestPayment;
    uint256 principalPayment;
    uint256 additionalBalancePayment;
  }

  function calculateInterestAndPrincipalAccrued(
    IOvenueCreditLine cl,
    uint256 timestamp,
    uint256 lateFeeGracePeriod
  ) public view returns (uint256, uint256) {
    uint256 balance = cl.balance(); // gas optimization
    uint256 interestAccrued = calculateInterestAccrued(cl, balance, timestamp, lateFeeGracePeriod);
    uint256 principalAccrued = calculatePrincipalAccrued(cl, balance, timestamp);
    return (interestAccrued, principalAccrued);
  }

  function calculateInterestAndPrincipalAccruedOverPeriod(
    IOvenueCreditLine cl,
    uint256 balance,
    uint256 startTime,
    uint256 endTime,
    uint256 lateFeeGracePeriod
  ) public view returns (uint256, uint256) {
    uint256 interestAccrued = calculateInterestAccruedOverPeriod(cl, balance, startTime, endTime, lateFeeGracePeriod);
    uint256 principalAccrued = calculatePrincipalAccrued(cl, balance, endTime);
    return (interestAccrued, principalAccrued);
  }

  function calculatePrincipalAccrued(
    IOvenueCreditLine cl,
    uint256 balance,
    uint256 timestamp
  ) public view returns (uint256) {
    // If we've already accrued principal as of the term end time, then don't accrue more principal
    uint256 termEndTime = cl.termEndTime();
    if (cl.interestAccruedAsOf() >= termEndTime) {
      return 0;
    }
    if (timestamp >= termEndTime) {
      return balance;
    } else {
      return 0;
    }
  }

  function calculateWritedownFor(
    IOvenueCreditLine cl,
    uint256 timestamp,
    uint256 gracePeriodInDays,
    uint256 maxDaysLate
  ) public view returns (uint256, uint256) {
    return calculateWritedownForPrincipal(cl, cl.balance(), timestamp, gracePeriodInDays, maxDaysLate);
  }

  function calculateWritedownForPrincipal(
    IOvenueCreditLine cl,
    uint256 principal,
    uint256 timestamp,
    uint256 gracePeriodInDays,
    uint256 maxDaysLate
  ) public view returns (uint256, uint256) {
    uint256 amountOwedPerDay = calculateAmountOwedForOneDay(cl);
    if (amountOwedPerDay == 0) {
      return (0, 0);
    }
    uint256 daysLate;

    // Excel math: =min(1,max(0,periods_late_in_days-graceperiod_in_days)/MAX_ALLOWED_DAYS_LATE) grace_period = 30,
    // Before the term end date, we use the interestOwed to calculate the periods late. However, after the loan term
    // has ended, since the interest is a much smaller fraction of the principal, we cannot reliably use interest to
    // calculate the periods later.
    uint256 totalOwed = cl.interestOwed() + cl.principalOwed();
    daysLate = totalOwed.wadDiv(amountOwedPerDay);
    if (timestamp > cl.termEndTime()) {
      uint256 secondsLate = timestamp- cl.termEndTime();
      daysLate = daysLate + secondsLate / SECONDS_PER_DAY;
    }

    uint256 writedownPercent;
    if (daysLate <= gracePeriodInDays) {
      // Within the grace period, we don't have to write down, so assume 0%
      writedownPercent = 0;
    } else {
      writedownPercent = MathUpgradeable.min(WadRayMath.WAD, (daysLate - gracePeriodInDays).wadDiv(maxDaysLate));
    }

    uint256 writedownAmount = writedownPercent.wadMul(principal);
    // This will return a number between 0-100 representing the write down percent with no decimals
    uint256 unscaledWritedownPercent = writedownPercent.wadMul(100);
    return (unscaledWritedownPercent, writedownAmount);
  }

  function calculateAmountOwedForOneDay(IOvenueCreditLine cl) public view returns (uint256 interestOwed) {
    // Determine theoretical interestOwed for one full day
    uint256 totalInterestPerYear = cl.balance().wadMul(cl.interestApr());
    interestOwed = totalInterestPerYear.wadDiv(365);
    return interestOwed;
  }

  function calculateInterestAccrued(
    IOvenueCreditLine cl,
    uint256 balance,
    uint256 timestamp,
    uint256 lateFeeGracePeriodInDays
  ) public view returns (uint256) {
    // We use Math.min here to prevent integer overflow (ie. go negative) when calculating
    // numSecondsElapsed. Typically this shouldn't be possible, because
    // the interestAccruedAsOf couldn't be *after* the current timestamp. However, when assessing
    // we allow this function to be called with a past timestamp, which raises the possibility
    // of overflow.
    // This use of min should not generate incorrect interest calculations, since
    // this function's purpose is just to normalize balances, and handing in a past timestamp
    // will necessarily return zero interest accrued (because zero elapsed time), which is correct.
    uint256 startTime = MathUpgradeable.min(timestamp, cl.interestAccruedAsOf());
    return calculateInterestAccruedOverPeriod(cl, balance, startTime, timestamp, lateFeeGracePeriodInDays);
  }

  function calculateInterestAccruedOverPeriod(
    IOvenueCreditLine cl,
    uint256 balance,
    uint256 startTime,
    uint256 endTime,
    uint256 lateFeeGracePeriodInDays
  ) public view returns (uint256 interestOwed) {
    uint256 secondsElapsed = endTime - startTime;
    uint256 totalInterestPerYear = balance * cl.interestApr() / INTEREST_DECIMALS;
    interestOwed = totalInterestPerYear * secondsElapsed / SECONDS_PER_YEAR;
    if (lateFeeApplicable(cl, endTime, lateFeeGracePeriodInDays)) {
      uint256 lateFeeInterestPerYear = balance * cl.lateFeeApr() / INTEREST_DECIMALS;
      uint256 additionalLateFeeInterest = lateFeeInterestPerYear * secondsElapsed / SECONDS_PER_YEAR;
      interestOwed = interestOwed + additionalLateFeeInterest;
    }

    return interestOwed;
  }

  function lateFeeApplicable(
    IOvenueCreditLine cl,
    uint256 timestamp,
    uint256 gracePeriodInDays
  ) public view returns (bool) {
    uint256 secondsLate = timestamp - cl.lastFullPaymentTime();
    return cl.lateFeeApr() > 0 && secondsLate > gracePeriodInDays * SECONDS_PER_DAY;
  }

  function allocatePayment(
    uint256 paymentAmount,
    uint256 balance,
    uint256 interestOwed,
    uint256 principalOwed
  ) public pure returns (PaymentAllocation memory) {
    uint256 paymentRemaining = paymentAmount;
    uint256 interestPayment = MathUpgradeable.min(interestOwed, paymentRemaining);
    paymentRemaining = paymentRemaining - interestPayment;

    uint256 principalPayment = MathUpgradeable.min(principalOwed, paymentRemaining);
    paymentRemaining = paymentRemaining - principalPayment;

    uint256 balanceRemaining = balance - principalPayment;
    uint256 additionalBalancePayment = MathUpgradeable.min(paymentRemaining, balanceRemaining);

    return
      PaymentAllocation({
        interestPayment: interestPayment,
        principalPayment: principalPayment,
        additionalBalancePayment: additionalBalancePayment
      });
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
pragma solidity 0.8.5;

import "../upgradeable/BaseUpgradeablePausable.sol";
import "../interfaces/IOvenueConfig.sol";
import "./OvenueConfigOptions.sol";

/**
 * @title GoldfinchConfig
 * @notice This contract stores mappings of useful "protocol config state", giving a central place
 *  for all other contracts to access it. For example, the TransactionLimit, or the PoolAddress. These config vars
 *  are enumerated in the `ConfigOptions` library, and can only be changed by admins of the protocol.
 *  Note: While this inherits from BaseUpgradeablePausable, it is not deployed as an upgradeable contract (this
 *    is mostly to save gas costs of having each call go through a proxy)
 * @author Goldfinch
 */

contract OvenueConfig is BaseUpgradeablePausable {
  bytes32 public constant GO_LISTER_ROLE = keccak256("GO_LISTER_ROLE");

  mapping(uint256 => address) public addresses;
  mapping(uint256 => uint256) public numbers;
  mapping(address => bool) public goList;

  event AddressUpdated(address owner, uint256 index, address oldValue, address newValue);
  event NumberUpdated(address owner, uint256 index, uint256 oldValue, uint256 newValue);

  event GoListed(address indexed member);
  event NoListed(address indexed member);

  bool public valuesInitialized;

  function initialize(address owner) public initializer {
    require(owner != address(0), "Owner address cannot be empty");

    __BaseUpgradeablePausable__init(owner);

    _setupRole(GO_LISTER_ROLE, owner);

    _setRoleAdmin(GO_LISTER_ROLE, OWNER_ROLE);
  }

  function setAddress(uint256 addressIndex, address newAddress) public onlyAdmin {
    require(addresses[addressIndex] == address(0), "Address has already been initialized");

    emit AddressUpdated(msg.sender, addressIndex, addresses[addressIndex], newAddress);
    addresses[addressIndex] = newAddress;
  }

  function setNumber(uint256 index, uint256 newNumber) public onlyAdmin {
    emit NumberUpdated(msg.sender, index, numbers[index], newNumber);
    numbers[index] = newNumber;
  }

  function setTreasuryReserve(address newTreasuryReserve) public onlyAdmin {
    uint256 key = uint256(OvenueConfigOptions.Addresses.TreasuryReserve);
    emit AddressUpdated(msg.sender, key, addresses[key], newTreasuryReserve);
    addresses[key] = newTreasuryReserve;
  }

  function setSeniorPoolStrategy(address newStrategy) public onlyAdmin {
    uint256 key = uint256(OvenueConfigOptions.Addresses.SeniorPoolStrategy);
    emit AddressUpdated(msg.sender, key, addresses[key], newStrategy);
    addresses[key] = newStrategy;
  }

  function setCreditLineImplementation(address newAddress) public onlyAdmin {
    uint256 key = uint256(OvenueConfigOptions.Addresses.CreditLineImplementation);
    emit AddressUpdated(msg.sender, key, addresses[key], newAddress);
    addresses[key] = newAddress;
  }

  function setTranchedPoolImplementation(address newAddress) public onlyAdmin {
    uint256 key = uint256(OvenueConfigOptions.Addresses.TranchedPoolImplementation);
    emit AddressUpdated(msg.sender, key, addresses[key], newAddress);
    addresses[key] = newAddress;
  }

  function setBorrowerImplementation(address newAddress) public onlyAdmin {
    uint256 key = uint256(OvenueConfigOptions.Addresses.BorrowerImplementation);
    emit AddressUpdated(msg.sender, key, addresses[key], newAddress);
    addresses[key] = newAddress;
  }

  function setOvenueConfig(address newAddress) public onlyAdmin {
    uint256 key = uint256(OvenueConfigOptions.Addresses.OvenueConfig);
    emit AddressUpdated(msg.sender, key, addresses[key], newAddress);
    addresses[key] = newAddress;
  }

  function initializeFromOtherConfig(
    address _initialConfig,
    uint256 numbersLength,
    uint256 addressesLength
  ) public onlyAdmin {
    require(!valuesInitialized, "Already initialized values");
    IOvenueConfig initialConfig = IOvenueConfig(_initialConfig);
    for (uint256 i = 0; i < numbersLength; i++) {
      setNumber(i, initialConfig.getNumber(i));
    }

    for (uint256 i = 0; i < addressesLength; i++) {
      if (getAddress(i) == address(0)) {
        setAddress(i, initialConfig.getAddress(i));
      }
    }
    valuesInitialized = true;
  }

  /**
   * @dev Adds a user to go-list
   * @param _member address to add to go-list
   */
  function addToGoList(address _member) public onlyGoListerRole {
    goList[_member] = true;
    emit GoListed(_member);
  }

  /**
   * @dev removes a user from go-list
   * @param _member address to remove from go-list
   */
  function removeFromGoList(address _member) public onlyGoListerRole {
    goList[_member] = false;
    emit NoListed(_member);
  }

  /**
   * @dev adds many users to go-list at once
   * @param _members addresses to ad to go-list
   */
  function bulkAddToGoList(address[] calldata _members) external onlyGoListerRole {
    for (uint256 i = 0; i < _members.length; i++) {
      addToGoList(_members[i]);
    }
  }

  /**
   * @dev removes many users from go-list at once
   * @param _members addresses to remove from go-list
   */
  function bulkRemoveFromGoList(address[] calldata _members) external onlyGoListerRole {
    for (uint256 i = 0; i < _members.length; i++) {
      removeFromGoList(_members[i]);
    }
  }

  /*
    Using custom getters in case we want to change underlying implementation later,
    or add checks or validations later on.
  */
  function getAddress(uint256 index) public view returns (address) {
    return addresses[index];
  }

  function getNumber(uint256 index) public view returns (uint256) {
    return numbers[index];
  }

  modifier onlyGoListerRole() {
    require(hasRole(GO_LISTER_ROLE, _msgSender()), "Must have go-lister role to perform this action");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "../upgradeable/BaseUpgradeablePausable.sol";
import "../libraries/OvenueConfigHelper.sol";
import "../interfaces/IOvenueSeniorPoolStrategy.sol";
import "../interfaces/IOvenueSeniorPool.sol";
import "../interfaces/IOvenueJuniorPool.sol";

abstract contract LeverageRatioStrategy is BaseUpgradeablePausable, IOvenueSeniorPoolStrategy {

  uint256 internal constant LEVERAGE_RATIO_DECIMALS = 1e18;

  /**
   * @notice Determines how much money to invest in the senior tranche based on what is committed to the junior
   * tranche, what is committed to the senior tranche, and a leverage ratio to the junior tranche. Because
   * it takes into account what is already committed to the senior tranche, the value returned by this
   * function can be used "idempotently" to achieve the investment target amount without exceeding that target.
   * @param pool The tranched pool to invest into (as the senior)
   * @return The amount of money to invest into the tranched pool's senior tranche, from the senior pool
   */
  function invest(IOvenueJuniorPool pool) public view override returns (uint256) {
    uint256 nSlices = pool.numSlices();
    // If the pool has no slices, we cant invest
    if (nSlices == 0) {
      return 0;
    }
    uint256 sliceIndex = nSlices - 1;
    (
      IOvenueJuniorPool.TrancheInfo memory juniorTranche,
      IOvenueJuniorPool.TrancheInfo memory seniorTranche
    ) = _getTranchesInSlice(pool, sliceIndex);
    // If junior capital is not yet invested, or pool already locked, then don't invest anything.
    if (juniorTranche.lockedUntil == 0 || seniorTranche.lockedUntil > 0) {
      return 0;
    }

    // return _invest(pool, juniorTranche, seniorTranche);
    return _invest(juniorTranche, seniorTranche);
  }

  /**
   * @notice A companion of `invest()`: determines how much would be returned by `invest()`, as the
   * value to invest into the senior tranche, if the junior tranche were locked and the senior tranche
   * were not locked.
   * @param pool The tranched pool to invest into (as the senior)
   * @return The amount of money to invest into the tranched pool's senior tranche, from the senior pool
   */
  function estimateInvestment(IOvenueJuniorPool pool) public view override returns (uint256) {
    uint256 nSlices = pool.numSlices();
    // If the pool has no slices, we cant invest
    if (nSlices == 0) {
      return 0;
    }
    uint256 sliceIndex = nSlices - 1;
    (
      IOvenueJuniorPool.TrancheInfo memory juniorTranche,
      IOvenueJuniorPool.TrancheInfo memory seniorTranche
    ) = _getTranchesInSlice(pool, sliceIndex);

    // return _invest(pool, juniorTranche, seniorTranche);
    return _invest(juniorTranche, seniorTranche);
  }

  function _invest(
    // IOvenueJuniorPool pool,
    IOvenueJuniorPool.TrancheInfo memory juniorTranche,
    IOvenueJuniorPool.TrancheInfo memory seniorTranche
  ) internal view returns (uint256) {
    uint256 juniorCapital = juniorTranche.principalDeposited;
    uint256 existingSeniorCapital = seniorTranche.principalDeposited;
    uint256 seniorTarget = juniorCapital * (getLeverageRatio() / LEVERAGE_RATIO_DECIMALS);
    if (existingSeniorCapital >= seniorTarget) {
      return 0;
    }

    return seniorTarget - existingSeniorCapital;
  }

  /// @notice Return the junior and senior tranches from a given pool in a specified slice
  /// @param pool pool to fetch tranches from
  /// @param sliceIndex slice index to fetch tranches from
  /// @return (juniorTranche, seniorTranche)
  function _getTranchesInSlice(IOvenueJuniorPool pool, uint256 sliceIndex)
    internal
    view
    returns (
      IOvenueJuniorPool.TrancheInfo memory, // junior tranche
      IOvenueJuniorPool.TrancheInfo memory // senior tranche
    )
  {
    uint256 juniorTrancheId = _sliceIndexToJuniorTrancheId(sliceIndex);
    uint256 seniorTrancheId = _sliceIndexToSeniorTrancheId(sliceIndex);

    IOvenueJuniorPool.TrancheInfo memory juniorTranche = pool.getTranche(juniorTrancheId);
    IOvenueJuniorPool.TrancheInfo memory seniorTranche = pool.getTranche(seniorTrancheId);
    return (juniorTranche, seniorTranche);
  }

  /// @notice Returns the junior tranche id for the given slice index
  /// @param index slice index
  /// @return junior tranche id of given slice index
  function _sliceIndexToJuniorTrancheId(uint256 index) internal pure returns (uint256) {
    return index * 2 + 2;
  }

  /// @notice Returns the senion tranche id for the given slice index
  /// @param index slice index
  /// @return senior tranche id of given slice index
  function _sliceIndexToSeniorTrancheId(uint256 index) internal pure returns (uint256) {
    return index * 2 + 1;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "../upgradeable/BaseUpgradeablePausable.sol";
import "../libraries/OvenueConfigHelper.sol";
import "./LeverageRatioStrategy.sol";
import "../interfaces/IOvenueSeniorPoolStrategy.sol";
import "../interfaces/IOvenueSeniorPool.sol";
import "../interfaces/IOvenueJuniorPool.sol";

contract FixedLeverageRatioStrategy is LeverageRatioStrategy {
  IOvenueConfig public config;
  using OvenueConfigHelper for IOvenueConfig;

  event OvenueConfigUpdated(address indexed who, address configAddress);

  function initialize(address owner, IOvenueConfig _config) public initializer {
    require(owner != address(0) && address(_config) != address(0), "Owner and config addresses cannot be empty");
    __BaseUpgradeablePausable__init(owner);
    config = _config;
  }

  function updateOvenueConfig() external onlyAdmin {
    config = IOvenueConfig(config.configAddress());
    emit OvenueConfigUpdated(msg.sender, address(config));
  }

  function getLeverageRatio() public view override returns (uint256) {
    return config.getLeverageRatio();
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "../upgradeable/BaseUpgradeablePausable.sol";
import "../interfaces/IOvenueConfig.sol";
import "../interfaces/IOvenueFactory.sol";
import "../interfaces/IOvenueCollateralCustody.sol";
import "../libraries/OvenueConfigHelper.sol";

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IAccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

contract OvenueCollateralCustody is BaseUpgradeablePausable, IERC721Receiver, IOvenueCollateralCustody {
    using OvenueConfigHelper for IOvenueConfig;
    using SafeERC20Upgradeable for IERC20withDec;
    
    error UnauthorizedCaller();
    error WrongNFTCollateral();
    error CollateralAlreadyInitialized(address poolAddr);
    error PoolNotExisted(address poolAddr);
    error ConfigNotSetup();
    error InvalidAmount();
    error InLockupPeriod();

    struct Collateral {
        address nftAddr;
        uint256 tokenId;
        uint256 fungibleAmount;
    }

    struct CollateralStatus {
        uint256 lockedUntil;
        uint256 fundedFungibleAmount;
        bool nftLocked;
    }

    bytes32 public constant LOCKER_ROLE = keccak256("LOCKER_ROLE");

    IOvenueConfig public config;

    // mapping(address => mapping(uint => IOvenueJuniorPool)) public lockedNftCollaterals;
    mapping(IOvenueJuniorPool => Collateral) public poolCollaterals;
    mapping(IOvenueJuniorPool => CollateralStatus) public poolCollateralStatus;

    event OvenueConfigUpdated(address indexed who, address configAddress);
    event CollateralStatsCreated(address indexed nftAddr, uint256 tokenId, uint256 collateralAmount);
    event NFTCollateralLocked(address indexed nftAddr, uint256 tokenId, address indexed poolAddr);
    event FungibleCollateralCollected(address indexed poolAddr, uint256 funded, uint256 amount);
    event NFTCollateralRedeemed(address indexed poolAddr, address indexed nftAddr, uint256 tokenId);
    event FungibleCollateralRedeemed(address indexed poolAddr, uint amount);

    function initialize(
        address owner,
        address _config
    ) public initializer {
        __BaseUpgradeablePausable__init(owner);
        config = IOvenueConfig(_config);
    }

    function createCollateralStats(
        IOvenueJuniorPool _poolAddr,
        address _nftAddr,
        uint256 _tokenId,
        uint256 _fungibleAmount
    ) external override onlyFactory {
        Collateral storage collateral = poolCollaterals[_poolAddr];
        CollateralStatus storage collateralStatus = poolCollateralStatus[_poolAddr];

        if (collateral.nftAddr != address(0)) {
            revert CollateralAlreadyInitialized(address(_poolAddr));
        }

        collateral.nftAddr = _nftAddr;
        collateral.tokenId = _tokenId;
        collateral.fungibleAmount = _fungibleAmount;

        collateralStatus.nftLocked = false;
        collateralStatus.fundedFungibleAmount = 0;

        emit CollateralStatsCreated(
            _nftAddr,
            _tokenId,
            _fungibleAmount
        );
    }

    function collectFungibleCollateral(
        IOvenueJuniorPool _poolAddr,
        address _depositor,
        uint256 _amount
    ) external override {
        if (_amount == 0) {
            revert InvalidAmount();
        }

        _checkPoolExisted(_poolAddr);

        if (!IAccessControlUpgradeable(address(_poolAddr)).hasRole(
            LOCKER_ROLE,
            msg.sender
        )) {
            revert UnauthorizedCaller();
        }

        if (address(config) == address(0)) {    
            revert ConfigNotSetup();            
        }

        CollateralStatus storage collateralStatus = poolCollateralStatus[_poolAddr];

        collateralStatus.fundedFungibleAmount += _amount;
        collateralStatus.lockedUntil = config.getCollateraLockupPeriod() + block.timestamp;

        config.getCollateralToken().safeTransferFrom(_depositor, address(this), _amount);
    
        emit FungibleCollateralCollected(
            address(_poolAddr),
            collateralStatus.fundedFungibleAmount,
            _amount
        );
    }

    function redeemAllCollateral(
        IOvenueJuniorPool _poolAddr,
        address receiver
    ) external override {
        _checkPoolExisted(_poolAddr);

        if (!IAccessControlUpgradeable(address(_poolAddr)).hasRole(
            LOCKER_ROLE,
            msg.sender
        )) {
            revert UnauthorizedCaller();
        }

        CollateralStatus storage collateralStatus = poolCollateralStatus[_poolAddr];
        Collateral storage collateral = poolCollaterals[_poolAddr];

        /// @dev: check if lock up period is passed
        if (block.timestamp <= collateralStatus.lockedUntil) {
            revert InLockupPeriod();
        }

        if (collateralStatus.nftLocked) {
            address nftAddr = collateral.nftAddr;
            uint256 tokenId = collateral.tokenId;
            
            collateralStatus.nftLocked = false;
            
            IERC721Upgradeable(nftAddr).safeTransferFrom(address(this), receiver, tokenId, "");
            emit NFTCollateralRedeemed(address(_poolAddr), nftAddr, tokenId);
        }

        if (collateralStatus.fundedFungibleAmount > 0) {
            uint fundedFungibleAmount = collateralStatus.fundedFungibleAmount;
            
            config.getCollateralToken().safeTransferFrom(address(this), receiver, fundedFungibleAmount);
            collateralStatus.fundedFungibleAmount = 0;
            
            emit FungibleCollateralRedeemed(
                address(_poolAddr),
                fundedFungibleAmount
            );
        }
    }

    function updateOvenueConfig() external onlyAdmin {
        config = IOvenueConfig(config.configAddress());
        emit OvenueConfigUpdated(msg.sender, address(config));
    }

    // function updateOvenueFactory() external onlyAdmin {
    //     factory = IOvenueFactory(config.ovenueFactoryAddress());
    //     emit OvenueFactoryUpdated(msg.sender, address(factory));
    // }

    function isCollateralFullyFunded(IOvenueJuniorPool _poolAddr) public view override returns(bool) {
        CollateralStatus storage collateralStatus = poolCollateralStatus[_poolAddr];
        Collateral storage collateral = poolCollaterals[_poolAddr];

        return collateralStatus.nftLocked && collateralStatus.fundedFungibleAmount >= collateral.fungibleAmount;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        (address poolAddr) = abi.decode(data, (address));  

        Collateral storage collateral = poolCollaterals[IOvenueJuniorPool(poolAddr)];
        CollateralStatus storage collateralStatus = poolCollateralStatus[IOvenueJuniorPool(poolAddr)];

        _checkPoolExisted(IOvenueJuniorPool(poolAddr));

        if (
            !(msg.sender == collateral.nftAddr &&
                tokenId == collateral.tokenId)
        ) {
            revert WrongNFTCollateral();
        }

        
        
        collateralStatus.nftLocked = true;
        collateralStatus.lockedUntil = config.getCollateraLockupPeriod() + block.timestamp;
        emit NFTCollateralLocked(msg.sender, tokenId, poolAddr);

        return IERC721Receiver.onERC721Received.selector;
    }


    function _checkPoolExisted(IOvenueJuniorPool poolAddr) internal {
        Collateral storage collateral = poolCollaterals[poolAddr];

        if (collateral.nftAddr == address(0)) {
            revert PoolNotExisted(address(poolAddr));
        }
    }

    modifier onlyFactory {
        if (msg.sender != address(config.getOvenueFactory())) {
            revert UnauthorizedCaller();
        }
        _;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
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
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
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
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
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
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

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
        address owner = ERC721.ownerOf(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC721 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC721Pausable is ERC721, Pausable {
    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
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

        require(!paused(), "ERC721Pausable: token transfer while paused");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../extensions/ERC721Enumerable.sol";
import "../extensions/ERC721Burnable.sol";
import "../extensions/ERC721Pausable.sol";
import "../../../access/AccessControlEnumerable.sol";
import "../../../utils/Context.sol";
import "../../../utils/Counters.sol";

/**
 * @dev {ERC721} token, including:
 *
 *  - ability for holders to burn (destroy) their tokens
 *  - a minter role that allows for token minting (creation)
 *  - a pauser role that allows to stop all token transfers
 *  - token ID and URI autogeneration
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * The account that deploys the contract will be granted the minter and pauser
 * roles, as well as the default admin role, which will let it grant both minter
 * and pauser roles to other accounts.
 *
 * _Deprecated in favor of https://wizard.openzeppelin.com/[Contracts Wizard]._
 */
contract ERC721PresetMinterPauserAutoId is
    Context,
    AccessControlEnumerable,
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable
{
    using Counters for Counters.Counter;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    Counters.Counter private _tokenIdTracker;

    string private _baseTokenURI;

    /**
     * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE` and `PAUSER_ROLE` to the
     * account that deploys the contract.
     *
     * Token URIs will be autogenerated based on `baseURI` and their token IDs.
     * See {ERC721-tokenURI}.
     */
    constructor(
        string memory name,
        string memory symbol,
        string memory baseTokenURI
    ) ERC721(name, symbol) {
        _baseTokenURI = baseTokenURI;

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        _setupRole(MINTER_ROLE, _msgSender());
        _setupRole(PAUSER_ROLE, _msgSender());
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev Creates a new token for `to`. Its token ID will be automatically
     * assigned (and available on the emitted {IERC721-Transfer} event), and the token
     * URI autogenerated based on the base URI passed at construction.
     *
     * See {ERC721-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to) public virtual {
        require(hasRole(MINTER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have minter role to mint");

        // We cannot just use balanceOf to create the new tokenId because tokens
        // can be burned (destroyed), so we need a separate counter.
        _mint(to, _tokenIdTracker.current());
        _tokenIdTracker.increment();
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC721Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        require(hasRole(PAUSER_ROLE, _msgSender()), "ERC721PresetMinterPauserAutoId: must have pauser role to unpause");
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

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
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
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
        uint256 length = ERC721.balanceOf(to);
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
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

/**
 * @title GFI
 * @notice GFI is Goldfinch's governance token.
 * @author Goldfinch
 */
contract OvenueSeniorLP is Context, AccessControl, ERC20Burnable, ERC20Pausable {
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /// The maximum number of tokens that can be minted
  uint256 public cap;

  event CapUpdated(address indexed who, uint256 cap);

  constructor(
    address owner,
    string memory name,
    string memory symbol,
    uint256 initialCap
  ) public ERC20(name, symbol) {
    cap = initialCap;

    _setupRole(MINTER_ROLE, owner);
    _setupRole(PAUSER_ROLE, owner);
    _setupRole(OWNER_ROLE, owner);

    _setRoleAdmin(MINTER_ROLE, OWNER_ROLE);
    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  /**
   * @notice create and send tokens to a specified address
   * @dev this function will fail if the caller attempts to mint over the current cap
   */
  function mint(address account, uint256 amount) public onlyMinter whenNotPaused {
    require(mintingAmountIsWithinCap(amount), "Cannot mint more than cap");
    _mint(account, amount);
  }

  /**
   * @notice sets the maximum number of tokens that can be minted
   * @dev the cap must be greater than the current total supply
   */
  function setCap(uint256 _cap) external onlyOwner {
    require(_cap >= totalSupply(), "Cannot decrease the cap below existing supply");
    cap = _cap;
    emit CapUpdated(_msgSender(), cap);
  }

  function mintingAmountIsWithinCap(uint256 amount) internal view returns (bool) {
    return totalSupply() + amount <= cap;
  }

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() external onlyPauser {
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() external onlyPauser {
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20, ERC20Pausable) {
    super._beforeTokenTransfer(from, to, amount);
  }

  modifier onlyOwner() {
    require(hasRole(OWNER_ROLE, _msgSender()), "Must be owner");
    _;
  }

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), "Must be minter");
    _;
  }

  modifier onlyPauser() {
    require(hasRole(PAUSER_ROLE, _msgSender()), "Must be pauser");
    _;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
        }
        _balances[to] += amount;

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
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
pragma solidity 0.8.5;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

/**
 * @title GFI
 * @notice GFI is Goldfinch's governance token.
 * @author Goldfinch
 */
contract Ovenue is Context, AccessControl, ERC20Burnable, ERC20Pausable {
  bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

  /// The maximum number of tokens that can be minted
  uint256 public cap;

  event CapUpdated(address indexed who, uint256 cap);

  constructor(
    address owner,
    string memory name,
    string memory symbol,
    uint256 initialCap
  ) public ERC20(name, symbol) {
    cap = initialCap;

    _setupRole(MINTER_ROLE, owner);
    _setupRole(PAUSER_ROLE, owner);
    _setupRole(OWNER_ROLE, owner);

    _setRoleAdmin(MINTER_ROLE, OWNER_ROLE);
    _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
  }

  /**
   * @notice create and send tokens to a specified address
   * @dev this function will fail if the caller attempts to mint over the current cap
   */
  function mint(address account, uint256 amount) public onlyMinter whenNotPaused {
    require(mintingAmountIsWithinCap(amount), "Cannot mint more than cap");
    _mint(account, amount);
  }

  /**
   * @notice sets the maximum number of tokens that can be minted
   * @dev the cap must be greater than the current total supply
   */
  function setCap(uint256 _cap) external onlyOwner {
    require(_cap >= totalSupply(), "Cannot decrease the cap below existing supply");
    cap = _cap;
    emit CapUpdated(_msgSender(), cap);
  }

  function mintingAmountIsWithinCap(uint256 amount) internal view returns (bool) {
    return totalSupply() + amount <= cap;
  }

  /**
   * @dev Pauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_pause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function pause() external onlyPauser {
    _pause();
  }

  /**
   * @dev Unpauses all token transfers.
   *
   * See {ERC20Pausable} and {Pausable-_unpause}.
   *
   * Requirements:
   *
   * - the caller must have the `PAUSER_ROLE`.
   */
  function unpause() external onlyPauser {
    _unpause();
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal override(ERC20, ERC20Pausable) {
    super._beforeTokenTransfer(from, to, amount);
  }

  modifier onlyOwner() {
    require(hasRole(OWNER_ROLE, _msgSender()), "Must be owner");
    _;
  }

  modifier onlyMinter() {
    require(hasRole(MINTER_ROLE, _msgSender()), "Must be minter");
    _;
  }

  modifier onlyPauser() {
    require(hasRole(PAUSER_ROLE, _msgSender()), "Must be pauser");
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";

/**
 * @title GFI
 * @notice GFI is Goldfinch's governance token.
 * @author Goldfinch
 */
contract USDT is Context, AccessControl, ERC20Burnable, ERC20Pausable {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// The maximum number of tokens that can be minted
    uint256 public cap;

    event CapUpdated(address indexed who, uint256 cap);

    constructor(
        address owner,
        string memory name,
        string memory symbol,
        uint256 initialCap
    ) public ERC20(name, symbol) {
        cap = initialCap;

        _setupRole(MINTER_ROLE, owner);
        _setupRole(PAUSER_ROLE, owner);
        _setupRole(OWNER_ROLE, owner);

        _setRoleAdmin(MINTER_ROLE, OWNER_ROLE);
        _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    }

    /**
     * @notice create and send tokens to a specified address
     * @dev this function will fail if the caller attempts to mint over the current cap
     */
    function mint(address account, uint256 amount) public whenNotPaused {
        require(mintingAmountIsWithinCap(amount), "Cannot mint more than cap");
        _mint(account, amount);
    }

    /**
     * @notice sets the maximum number of tokens that can be minted
     * @dev the cap must be greater than the current total supply
     */
    function setCap(uint256 _cap) external onlyOwner {
        require(
            _cap >= totalSupply(),
            "Cannot decrease the cap below existing supply"
        );
        cap = _cap;
        emit CapUpdated(_msgSender(), cap);
    }

    function mintingAmountIsWithinCap(uint256 amount)
        internal
        view
        returns (bool)
    {
        return totalSupply() + amount <= cap;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() external onlyPauser {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC20Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() external onlyPauser {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, amount);
    }

    modifier onlyOwner() {
        require(hasRole(OWNER_ROLE, _msgSender()), "Must be owner");
        _;
    }

    modifier onlyMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Must be minter");
        _;
    }

    modifier onlyPauser() {
        require(hasRole(PAUSER_ROLE, _msgSender()), "Must be pauser");
        _;
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

contract SPV is ERC721PresetMinterPauserAutoId{
    constructor() ERC721PresetMinterPauserAutoId(
        "Special Vehicle Purpose",
        "SPV",
        ""
    ) {

    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "../libraries/OvenueConfigHelper.sol";
import "../upgradeable/BaseUpgradeablePausable.sol";
import "../helpers/Accountant.sol";
import "../interfaces/IERC20withDec.sol";
import "../interfaces/IOvenueCreditLine.sol";
import "../interfaces/IOvenueConfig.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";


/**
 * @title CreditLine
 * @notice A contract that represents the agreement between Backers and
 *  a Borrower. Includes the terms of the loan, as well as the current accounting state, such as interest owed.
 *  A CreditLine belongs to a TranchedPool, and is fully controlled by that TranchedPool. It does not
 *  operate in any standalone capacity. It should generally be considered internal to the TranchedPool.
 * @author Goldfinch
 */

// solhint-disable-next-line max-states-count
contract CreditLine is BaseUpgradeablePausable, IOvenueCreditLine {
  uint256 public constant SECONDS_PER_DAY = 1 days;


  // Credit line terms
  address public override borrower;
  uint256 public currentLimit;
  uint256 public override maxLimit;
  uint256 public override interestApr;
  uint256 public override paymentPeriodInDays;
  uint256 public override termInDays;
  uint256 public override principalGracePeriodInDays;
  uint256 public override lateFeeApr;

  // Accounting variables
  uint256 public override balance;
  uint256 public override interestOwed;
  uint256 public override principalOwed;
  uint256 public override termEndTime;
  uint256 public override nextDueTime;
  uint256 public override interestAccruedAsOf;
  uint256 public override lastFullPaymentTime;
  uint256 public totalInterestAccrued;

  IOvenueConfig public config;
  using OvenueConfigHelper for IOvenueConfig;

  function initialize(
    address _config,
    address owner,
    address _borrower,
    uint256 _maxLimit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays
  ) public initializer {
    require(_config != address(0) && owner != address(0) && _borrower != address(0), "Zero address passed in");
    __BaseUpgradeablePausable__init(owner);
    config = IOvenueConfig(_config);
    borrower = _borrower;
    maxLimit = _maxLimit;
    interestApr = _interestApr;
    paymentPeriodInDays = _paymentPeriodInDays;
    termInDays = _termInDays;
    lateFeeApr = _lateFeeApr;
    principalGracePeriodInDays = _principalGracePeriodInDays;
    interestAccruedAsOf = block.timestamp;

    // Unlock owner, which is a TranchedPool, for infinite amount
    bool success = config.getUSDC().approve(owner, type(uint256).max);
    require(success, "Failed to approve USDC");
  }

  function limit() external view override returns (uint256) {
    return currentLimit;
  }

  /**
   * @notice Updates the internal accounting to track a drawdown as of current block timestamp.
   * Does not move any money
   * @param amount The amount in USDC that has been drawndown
   */
  function drawdown(uint256 amount) external onlyAdmin {
    uint256 timestamp = currentTime();
    require(termEndTime == 0 || (timestamp < termEndTime), "After termEndTime");
    require(amount + balance <= currentLimit, "Cannot drawdown more than the limit");
    require(amount > 0, "Invalid drawdown amount");

    if (balance == 0) {
      setInterestAccruedAsOf(timestamp);
      setLastFullPaymentTime(timestamp);
      setTotalInterestAccrued(0);
      // Set termEndTime only once to prevent extending
      // the loan's end time on every 0 balance drawdown
      if (termEndTime == 0) {
        setTermEndTime(timestamp + (SECONDS_PER_DAY * termInDays));
      }
    }

    (uint256 _interestOwed, uint256 _principalOwed) = _updateAndGetInterestAndPrincipalOwedAsOf(timestamp);
    balance = balance + amount;

    updateCreditLineAccounting(balance, _interestOwed, _principalOwed);
    require(!_isLate(timestamp), "Cannot drawdown when payments are past due");
  }

  function setLateFeeApr(uint256 newLateFeeApr) external onlyAdmin {
    lateFeeApr = newLateFeeApr;
  }

  function setLimit(uint256 newAmount) external onlyAdmin {
    require(newAmount <= maxLimit, "Cannot be more than the max limit");
    currentLimit = newAmount;
  }

  function setMaxLimit(uint256 newAmount) external onlyAdmin {
    maxLimit = newAmount;
  }

  function termStartTime() external view returns (uint256) {
    return _termStartTime();
  }

  function isLate() external view override returns (bool) {
    return _isLate(block.timestamp);
  }

  function withinPrincipalGracePeriod() external view override returns (bool) {
    if (termEndTime == 0) {
      // Loan hasn't started yet
      return true;
    }
    return block.timestamp < (_termStartTime() + principalGracePeriodInDays) * SECONDS_PER_DAY;
  }

  function setTermEndTime(uint256 newTermEndTime) public onlyAdmin {
    termEndTime = newTermEndTime;
  }

  function setNextDueTime(uint256 newNextDueTime) public onlyAdmin {
    nextDueTime = newNextDueTime;
  }

  function setBalance(uint256 newBalance) public onlyAdmin {
    balance = newBalance;
  }

  function setTotalInterestAccrued(uint256 _totalInterestAccrued) public onlyAdmin {
    totalInterestAccrued = _totalInterestAccrued;
  }

  function setInterestOwed(uint256 newInterestOwed) public onlyAdmin {
    interestOwed = newInterestOwed;
  }

  function setPrincipalOwed(uint256 newPrincipalOwed) public onlyAdmin {
    principalOwed = newPrincipalOwed;
  }

  function setInterestAccruedAsOf(uint256 newInterestAccruedAsOf) public onlyAdmin {
    interestAccruedAsOf = newInterestAccruedAsOf;
  }

  function setLastFullPaymentTime(uint256 newLastFullPaymentTime) public onlyAdmin {
    lastFullPaymentTime = newLastFullPaymentTime;
  }

  /**
   * @notice Triggers an assessment of the creditline. Any USDC balance available in the creditline is applied
   * towards the interest and principal.
   * @return Any amount remaining after applying payments towards the interest and principal
   * @return Amount applied towards interest
   * @return Amount applied towards principal
   */
  function assess()
    public
    onlyAdmin
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    // Do not assess until a full period has elapsed or past due
    require(balance > 0, "Must have balance to assess credit line");

    // Don't assess credit lines early!
    if (currentTime() < nextDueTime && !_isLate(currentTime())) {
      return (0, 0, 0);
    }
    uint256 timeToAssess = calculateNextDueTime();
    setNextDueTime(timeToAssess);

    // We always want to assess for the most recently *past* nextDueTime.
    // So if the recalculation above sets the nextDueTime into the future,
    // then ensure we pass in the one just before this.
    if (timeToAssess > currentTime()) {
      uint256 secondsPerPeriod = paymentPeriodInDays * SECONDS_PER_DAY;
      timeToAssess = timeToAssess - secondsPerPeriod;
    }
    return handlePayment(_getUSDCBalance(address(this)), timeToAssess);
  }

  function calculateNextDueTime() internal view returns (uint256) {
    uint256 newNextDueTime = nextDueTime;
    uint256 secondsPerPeriod = paymentPeriodInDays * SECONDS_PER_DAY;
    uint256 curTimestamp = currentTime();
    // You must have just done your first drawdown
    if (newNextDueTime == 0 && balance > 0) {
      return curTimestamp + secondsPerPeriod;
    }

    // Active loan that has entered a new period, so return the *next* newNextDueTime.
    // But never return something after the termEndTime
    if (balance > 0 && curTimestamp >= newNextDueTime) {
      uint256 secondsToAdvance = ((curTimestamp - newNextDueTime) / secondsPerPeriod + 1) * secondsPerPeriod;
      newNextDueTime = newNextDueTime + secondsToAdvance;
      return Math.min(newNextDueTime, termEndTime);
    }

    // You're paid off, or have not taken out a loan yet, so no next due time.
    if (balance == 0 && newNextDueTime != 0) {
      return 0;
    }
    // Active loan in current period, where we've already set the newNextDueTime correctly, so should not change.
    if (balance > 0 && curTimestamp < newNextDueTime) {
      return newNextDueTime;
    }
    revert("Error: could not calculate next due time.");
  }

  function currentTime() internal view virtual returns (uint256) {
    return block.timestamp;
  }

  function _isLate(uint256 timestamp) internal view returns (bool) {
    uint256 secondsElapsedSinceFullPayment = timestamp - lastFullPaymentTime;
    return balance > 0 && secondsElapsedSinceFullPayment > paymentPeriodInDays * SECONDS_PER_DAY;
  }

  function _termStartTime() internal view returns (uint256) {
    return termEndTime - (SECONDS_PER_DAY * termInDays);
  }

  /**
   * @notice Applies `amount` of payment for a given credit line. This moves already collected money into the Pool.
   *  It also updates all the accounting variables. Note that interest is always paid back first, then principal.
   *  Any extra after paying the minimum will go towards existing principal (reducing the
   *  effective interest rate). Any extra after the full loan has been paid off will remain in the
   *  USDC Balance of the creditLine, where it will be automatically used for the next drawdown.
   * @param paymentAmount The amount, in USDC atomic units, to be applied
   * @param timestamp The timestamp on which accrual calculations should be based. This allows us
   *  to be precise when we assess a Credit Line
   */
  function handlePayment(uint256 paymentAmount, uint256 timestamp)
    internal
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    (uint256 newInterestOwed, uint256 newPrincipalOwed) = _updateAndGetInterestAndPrincipalOwedAsOf(timestamp);
    Accountant.PaymentAllocation memory pa = Accountant.allocatePayment(
      paymentAmount,
      balance,
      newInterestOwed,
      newPrincipalOwed
    );

    uint256 newBalance = balance - pa.principalPayment;
    // Apply any additional payment towards the balance
    newBalance = newBalance - pa.additionalBalancePayment;
    uint256 totalPrincipalPayment = balance - newBalance;
    uint256 paymentRemaining = paymentAmount - pa.interestPayment - totalPrincipalPayment;

    updateCreditLineAccounting(
      newBalance,
      newInterestOwed - pa.interestPayment,
      newPrincipalOwed - pa.principalPayment
    );

    assert(paymentRemaining + pa.interestPayment + totalPrincipalPayment == paymentAmount);

    return (paymentRemaining, pa.interestPayment, totalPrincipalPayment);
  }

  function _updateAndGetInterestAndPrincipalOwedAsOf(uint256 timestamp) internal returns (uint256, uint256) {
    (uint256 interestAccrued, uint256 principalAccrued) = Accountant.calculateInterestAndPrincipalAccrued(
      this,
      timestamp,
      config.getLatenessGracePeriodInDays()
    );
    if (interestAccrued > 0) {
      // If we've accrued any interest, update interestAccruedAsOf to the time that we've
      // calculated interest for. If we've not accrued any interest, then we keep the old value so the next
      // time the entire period is taken into account.
      setInterestAccruedAsOf(timestamp);
      totalInterestAccrued = totalInterestAccrued + interestAccrued;
    }
    return (interestOwed + interestAccrued, principalOwed + principalAccrued);
  }

  function updateCreditLineAccounting(
    uint256 newBalance,
    uint256 newInterestOwed,
    uint256 newPrincipalOwed
  ) internal nonReentrant {
    setBalance(newBalance);
    setInterestOwed(newInterestOwed);
    setPrincipalOwed(newPrincipalOwed);

    // This resets lastFullPaymentTime. These conditions assure that they have
    // indeed paid off all their interest and they have a real nextDueTime. (ie. creditline isn't pre-drawdown)
    uint256 _nextDueTime = nextDueTime;
    if (newInterestOwed == 0 && _nextDueTime != 0) {
      // If interest was fully paid off, then set the last full payment as the previous due time
      uint256 mostRecentLastDueTime;
      if (currentTime() < _nextDueTime) {
        uint256 secondsPerPeriod = paymentPeriodInDays * SECONDS_PER_DAY;
        mostRecentLastDueTime = _nextDueTime - secondsPerPeriod;
      } else {
        mostRecentLastDueTime = _nextDueTime;
      }
      setLastFullPaymentTime(mostRecentLastDueTime);
    }

    setNextDueTime(calculateNextDueTime());
  }

  function _getUSDCBalance(address _address) internal view returns (uint256) {
    return config.getUSDC().balanceOf(_address);
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
pragma solidity 0.8.5;

import "../upgradeable/BaseUpgradeablePausable.sol";
import "../libraries/OvenueConfigHelper.sol";
import "../interfaces/IGo.sol";
import "../interfaces/IUniqueIdentity0612.sol";
import "../interfaces/IOvenueConfig.sol";

contract Go is IGo, BaseUpgradeablePausable {
  bytes32 public constant ZAPPER_ROLE = keccak256("ZAPPER_ROLE");

  address public override uniqueIdentity;

  IOvenueConfig public config;
  using OvenueConfigHelper for IOvenueConfig;

//   IOvenueConfig public legacyGoList;
  uint256[11] public allIdTypes;
  event OvenueConfigUpdated(address indexed who, address configAddress);

  function initialize(
    address owner,
    IOvenueConfig _config,
    address _uniqueIdentity
  ) public initializer {
    require(
      owner != address(0) && address(_config) != address(0) && _uniqueIdentity != address(0),
      "Owner and config and UniqueIdentity addresses cannot be empty"
    );
    __BaseUpgradeablePausable__init(owner);
    _performUpgrade();
    config = _config;
    uniqueIdentity = _uniqueIdentity;
  }

  function performUpgrade() external onlyAdmin {
    return _performUpgrade();
  }

  function _performUpgrade() internal {
    allIdTypes[0] = ID_TYPE_0;
    allIdTypes[1] = ID_TYPE_1;
    allIdTypes[2] = ID_TYPE_2;
    allIdTypes[3] = ID_TYPE_3;
    allIdTypes[4] = ID_TYPE_4;
    allIdTypes[5] = ID_TYPE_5;
    allIdTypes[6] = ID_TYPE_6;
    allIdTypes[7] = ID_TYPE_7;
    allIdTypes[8] = ID_TYPE_8;
    allIdTypes[9] = ID_TYPE_9;
    allIdTypes[10] = ID_TYPE_10;
  }

  /**
   * @notice Returns whether the provided account is go-listed for use of the Ovenue protocol
   * for any of the UID token types.
   * This status is defined as: whether `balanceOf(account, id)` on the UniqueIdentity
   * contract is non-zero (where `id` is a supported token id on UniqueIdentity), falling back to the
   * account's status on the legacy go-list maintained on OvenueConfig.
   * @param account The account whose go status to obtain
   * @return The account's go status
   */
  function go(address account) public view override returns (bool) {
    require(account != address(0), "Zero address is not go-listed");

    if (IUniqueIdentity0612(uniqueIdentity).balanceOf(account, ID_TYPE_0) > 0) {
      return true;
    }

    // start loop at index 1 because we checked index 0 above
    for (uint256 i = 1; i < allIdTypes.length; ++i) {
      uint256 idTypeBalance = IUniqueIdentity0612(uniqueIdentity).balanceOf(account, allIdTypes[i]);
      if (idTypeBalance > 0) {
        return true;
      }
    }
    return false;
  }

  /**
   * @notice Returns whether the provided account is go-listed for use of the Goldfinch protocol
   * for defined UID token types
   * @param account The account whose go status to obtain
   * @param onlyIdTypes Array of id types to check balances
   * @return The account's go status
   */
  function goOnlyIdTypes(address account, uint256[] memory onlyIdTypes) public view override returns (bool) {
    require(account != address(0), "Zero address is not go-listed");

    if (hasRole(ZAPPER_ROLE, account)) {
      return true;
    }

    for (uint256 i = 0; i < onlyIdTypes.length; ++i) {
      uint256 idTypeBalance = IUniqueIdentity0612(uniqueIdentity).balanceOf(account, onlyIdTypes[i]);
      if (idTypeBalance > 0) {
        return true;
      }
    }
    return false;
  }

  function getSeniorPoolIdTypes() public pure returns (uint256[] memory) {
    // using a fixed size array because you can only define fixed size array literals.
    uint256[4] memory allowedSeniorPoolIdTypesStaging = [ID_TYPE_0, ID_TYPE_1, ID_TYPE_3, ID_TYPE_4];

    // create a dynamic array and copy the fixed array over so we return a dynamic array
    uint256[] memory allowedSeniorPoolIdTypes = new uint256[](allowedSeniorPoolIdTypesStaging.length);
    for (uint256 i = 0; i < allowedSeniorPoolIdTypesStaging.length; i++) {
      allowedSeniorPoolIdTypes[i] = allowedSeniorPoolIdTypesStaging[i];
    }

    return allowedSeniorPoolIdTypes;
  }

  /**
   * @notice Returns whether the provided account is go-listed for use of the SeniorPool on the Goldfinch protocol.
   * @param account The account whose go status to obtain
   * @return The account's go status
   */
  function goSeniorPool(address account) public view override returns (bool) {
    require(account != address(0), "Zero address is not go-listed");
    if (
      hasRole(ZAPPER_ROLE, account)
    ) {
      return true;
    }
    uint256[] memory seniorPoolIdTypes = getSeniorPoolIdTypes();
    for (uint256 i = 0; i < seniorPoolIdTypes.length; ++i) {
      uint256 idTypeBalance = IUniqueIdentity0612(uniqueIdentity).balanceOf(account, seniorPoolIdTypes[i]);
      if (idTypeBalance > 0) {
        return true;
      }
    }
    return false;
  }

//   function _getLegacyGoList() internal view returns (GoldfinchConfig) {
//     return address(legacyGoList) == address(0) ? config : legacyGoList;
//   }

  function initZapperRole() external onlyAdmin {
    _setRoleAdmin(ZAPPER_ROLE, OWNER_ROLE);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

/// @dev This interface provides a subset of the functionality of the IUniqueIdentity
/// interface -- namely, the subset of functionality needed by Goldfinch protocol contracts
/// compiled with Solidity version 0.6.12.
interface IUniqueIdentity0612 {
  function balanceOf(address account, uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev {ERC1155} token, including a pauser role that allows to stop all token transfers
 * (including minting and burning).
 *
 * This contract uses {AccessControl} to lock permissioned functions using the
 * different roles - head to its documentation for details.
 *
 * Adapted from OZ's ERC1155PresetMinterPauserUpgradeable.sol: removed inheritance of
 * ERC1155BurnableUpgradeable; removed MINTER_ROLE; replaced DEFAULT_ADMIN_ROLE with OWNER_ROLE;
 * grants roles to owner param rather than `_msgSender()`; added `setURI()`, to give owner ability
 * to set the URI after initialization; added `isAdmin()` helper and `onlyAdmin` modifier.
 */
contract ERC1155PresetPauserUpgradeable is
    ContextUpgradeable,
    AccessControlUpgradeable,
    ERC1155PausableUpgradeable
{
    error UnAnthorizedPauser();
    error UnAnthorizedOwner();

    bytes32 public constant OWNER_ROLE = 0xb19546dff01e856fb3f010c267a7b1c60363cf8a4664e21cc89c26224620214e;
    bytes32 public constant PAUSER_ROLE = 0x65d7a28e3265b37a6474929f336521b332c1681b933f6cb9f3376673440d862a;

    function __ERC1155PresetPauser_init(address owner, string memory uri) public virtual initializer {
        __ERC1155_init_unchained(uri);
        __Pausable_init_unchained();

        _setupRole(OWNER_ROLE, owner);
        _setupRole(PAUSER_ROLE, owner);

        _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    }

    // /**
    //  * @dev Grants `DEFAULT_ADMIN_ROLE`, `MINTER_ROLE`, and `PAUSER_ROLE` to the account that
    //  * deploys the contract.
    //  */
    // function __ERC1155PresetPauser_init(address owner, string memory uri)
    //     internal
    //     onlyInitializing
    // {
    //     __ERC1155_init_unchained(uri);
    //     __Pausable_init_unchained();
    //     __ERC1155PresetPauser_init_unchained(owner);
    // }

    // function __ERC1155PresetPauser_init_unchained(address owner)
    //     internal
    //     initializer
    // {
    //     _setupRole(OWNER_ROLE, owner);
    //     _setupRole(PAUSER_ROLE, owner);

    //     _setRoleAdmin(PAUSER_ROLE, OWNER_ROLE);
    //     _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    // }

    function setURI(string memory newuri) external onlyAdmin {
        /// @dev Because the `newuri` is not id-specific, we do not emit a URI event here. See the comment
        /// on `_setURI()`.
        _setURI(newuri);
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function pause() public virtual {
        if (!hasRole(PAUSER_ROLE, _msgSender())) {
            revert UnAnthorizedPauser();
        }
        // require(
        //     hasRole(PAUSER_ROLE, _msgSender()),
        //     "ERC1155PresetMinterPauser: must have pauser role to pause"
        // );
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `PAUSER_ROLE`.
     */
    function unpause() public virtual {
        if (!hasRole(PAUSER_ROLE, _msgSender())) {
            revert UnAnthorizedPauser();
        }
        // require(
        //     hasRole(PAUSER_ROLE, _msgSender()),
        //     "ERC1155PresetMinterPauser: must have pauser role to unpause"
        // );
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC1155Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155PausableUpgradeable) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;

    function isAdmin() public view returns (bool) {
        return hasRole(OWNER_ROLE, _msgSender());
    }

    modifier onlyAdmin() {
        if (!isAdmin()) {
            revert UnAnthorizedOwner();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

import "../external/ERC1155PresetPauserUpgradeable.sol";
import "../interfaces/IUniqueIdentity.sol";


/**
 * @title UniqueIdentity
 * @notice UniqueIdentity is an ERC1155-compliant contract for representing
 * the identity verification status of addresses.
 * @author Ovenue
 */

contract UniqueIdentity is ERC1155PresetPauserUpgradeable, IUniqueIdentity {
    error UnmatchedArraysLength();
    error SignatureExpired();
    error MintCostNotEnough(uint256 cost);
    error BalanceNotEqualZero();
    error TokenIDNotSupported();
    error OnlyMintAndBurnActs();
    error UnAuthorizedCaller();
    error AddressZeroInput();

    bytes32 public constant SIGNER_ROLE =
        0xe2f4eaae4a9751e85a3e4a7b9587827a877f29914755229b07a7b2da98285f70;

    uint256 public constant ID_TYPE_0 = 0; // non-US individual
    uint256 public constant ID_TYPE_1 = 1; // US accredited individual
    uint256 public constant ID_TYPE_2 = 2; // US non accredited individual
    uint256 public constant ID_TYPE_3 = 3; // US entity
    uint256 public constant ID_TYPE_4 = 4; // non-US entity
    uint256 public constant ID_TYPE_5 = 5;
    uint256 public constant ID_TYPE_6 = 6;
    uint256 public constant ID_TYPE_7 = 7;
    uint256 public constant ID_TYPE_8 = 8;
    uint256 public constant ID_TYPE_9 = 9;
    uint256 public constant ID_TYPE_10 = 10;

    uint256 public constant MINT_COST_PER_TOKEN = 830000 gwei;

    //   /// @dev We include a nonce in every hashed message, and increment the nonce as part of a
    //   /// state-changing operation, so as to prevent replay attacks, i.e. the reuse of a signature.
    mapping(address => uint256) public nonces;
    mapping(uint256 => bool) public supportedUIDTypes;

    function initialize(address owner, string memory uri) public initializer {
        if (owner == address(0)) {
            revert AddressZeroInput();
        }
        __ERC1155PresetPauser_init(owner, uri);
        _setupRole(SIGNER_ROLE, owner);
        _setRoleAdmin(SIGNER_ROLE, OWNER_ROLE);
    }

    //   // solhint-disable-next-line func-name-mixedcase
    //   function c(address owner) internal initializer {
    //     _setupRole(SIGNER_ROLE, owner);
    //     _setRoleAdmin(SIGNER_ROLE, OWNER_ROLE);
    //   }

    //   // solhint-disable-next-line func-name-mixedcase
    //   function __UniqueIdentity_init_unchained(address owner) internal initializer {
    //     _setupRole(SIGNER_ROLE, owner);
    //     _setRoleAdmin(SIGNER_ROLE, OWNER_ROLE);
    //   }

    function setSupportedUIDTypes(
        uint256[] calldata ids,
        bool[] calldata values
    ) public onlyAdmin {
        if (ids.length != values.length) {
            revert UnmatchedArraysLength();
        }

        for (uint256 i = 0; i < ids.length; ++i) {
            supportedUIDTypes[ids[i]] = values[i];
        }
    }

    /**
     * @dev Gets the token name.
     * @return string representing the token name
     */
    function name() public pure returns (string memory) {
        return "Unique Identity";
    }

    /**
     * @dev Gets the token symbol.
     * @return string representing the token symbol
     */
    function symbol() public pure returns (string memory) {
        return "UID";
    }

    function mint(
        uint256 id,
        uint256 expiresAt,
        bytes calldata signature
    )
        public
        payable
        override
        onlySigner(_msgSender(), id, expiresAt, signature)
        incrementNonce(_msgSender())
    {
        if (msg.value < MINT_COST_PER_TOKEN) {
            revert MintCostNotEnough(msg.value);
        }

        if (!supportedUIDTypes[id]) {
            revert TokenIDNotSupported();
        }

        if (balanceOf(_msgSender(), id) != 0) {
            revert BalanceNotEqualZero();
        }

        _mint(_msgSender(), id, 1, "");
    }

    function burn(
        address account,
        uint256 id,
        uint256 expiresAt,
        bytes calldata signature
    )
        public
        override
        onlySigner(account, id, expiresAt, signature)
        incrementNonce(account)
    {
        _burn(account, id, 1);

        uint256 accountBalance = balanceOf(account, id);
        // require(accountBalance == 0, "Balance after burn must be 0");

        if (accountBalance != 0) {
            revert BalanceNotEqualZero();
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155PresetPauserUpgradeable) {
        if (
            !((from == address(0) && to != address(0)) ||
                (from != address(0) && to == address(0)))
        ) {
            revert OnlyMintAndBurnActs();
        }
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    modifier onlySigner(
        address account,
        uint256 id,
        uint256 expiresAt,
        bytes calldata signature
    ) {
        if (block.timestamp >= expiresAt) {
            revert SignatureExpired();
        }
        // require(block.timestamp < expiresAt, "Signature has expired");

        bytes32 hash = keccak256(
            abi.encodePacked(
                account,
                id,
                expiresAt,
                address(this),
                nonces[account],
                block.chainid
            )
        );
        bytes32 ethSignedMessage = ECDSAUpgradeable.toEthSignedMessageHash(
            hash
        );
        if (
            !hasRole(
                SIGNER_ROLE,
                ECDSAUpgradeable.recover(ethSignedMessage, signature)
            )
        ) {
            revert UnAuthorizedCaller();
        }
        _;
    }

    modifier incrementNonce(address account) {
        ++nonces[account];
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

interface IUniqueIdentity is IERC1155Upgradeable {
  function mint(
    uint256 id,
    uint256 expiresAt,
    bytes calldata signature
  ) external payable;

  function burn(
    address account,
    uint256 id,
    uint256 expiresAt,
    bytes calldata signature
  ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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
pragma solidity 0.8.5;

interface IERC2981 {
  /// @notice Called with the sale price to determine how much royalty
  //          is owed and to whom.
  /// @param _tokenId - the NFT asset queried for royalty information
  /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
  /// @return receiver - address of who should be sent the royalty payment
  /// @return royaltyAmount - the royalty payment amount for _salePrice
  function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
    external
    view
    returns (address receiver, uint256 royaltyAmount);
}