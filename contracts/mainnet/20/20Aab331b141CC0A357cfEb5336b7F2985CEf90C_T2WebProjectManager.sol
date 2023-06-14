/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// Sources flattened with hardhat v2.9.6 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/access/[email protected]

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
        bool isTopLevelCall = _setInitializedVersion(1);
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
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}



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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


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


/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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


/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}



/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}



library Signature {

    function splitSignature(bytes memory sig) private pure returns (uint8 v, bytes32 r, bytes32 s) {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    function recoverSigner(bytes32 message, bytes memory sig) internal pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(message, v, r, s);
    }

    function prefixed(bytes32 msgHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
    }

    /**
     * @dev Make sure all signatures and signers are valid
     */
    function verifySignature(bytes32 msgHash, bytes memory signature, address signer) internal pure {
        bytes32 message = prefixed(msgHash);
        require(recoverSigner(message, signature) == signer, "INVALID_SIGNATURE");
    }

}



enum ProjectState {
  NEW,
  READY,
  CREATED,
  STARTED,
  FINISHED,
  ERROR
}

enum VaultType {
  MINT, // New mint NFTs
  MINTED // Use minted NFTs from external contracts
}

enum PriceType {
  PRICE,
  SWAP
}

enum SaleType {
  PRESALE,
  PUBLICSALE
}

struct ProjectRequest {
  uint256 backendId;
  string name;
  string symbol;
  string baseTokenURI;
  uint256 contractType; // 721, 1155, 4907
  uint256 vaultType; // 0: MINT; 1: MINTED
  uint256 adminFeeRate; // 2%
  uint256 devFeeRate; // 0.2%
  bool useMetaTransaction;
  bool canReveal;
  bool transferUnsoldDisabled;
  address forwarder;
  address paymentToken; // ERC20 or address(0) in case of native token
}

struct Project {
  uint256 id;
  uint256 backendId;
  address owner;
  uint256 contractType; // 721, 1155, 4907
  ProjectState state;
  VaultType vaultType;
  address contractAddress;
  uint256 adminFeeRate;
  uint256 devFeeRate;
  bool canReveal;
  bool isRevealed;
  bool transferUnsoldDisabled;
  bool useMetaTransaction;
  address forwarder;
  address paymentToken; // ERC20 or address(0) in case of native token
  uint256 finishAt;
}

struct SaleInfo {
  uint256 startTime;
  uint256 endTime;
  bool whitelistRequired;
  uint256 price;
  uint256 amount;
  uint256 maxPurchase;
  uint256 priceType;
  address burnContractAddress;
  uint256 burnContractType; // 721 | 1155
}

struct FundInfo {
  uint256 admin;
  uint256 dev;
  uint256 projectOwner;
}



interface IT2WebProjectManager {
  event ProjectCreated(
    uint256 backendId,
    uint256 projectId,
    uint256 contractType,
    address indexed contractAddress,
    address indexed owner,
    uint256 state
  );

  event ProjectRevealed(
    uint256 projectId,
    bool isRevealed,
    string baseTokenURI
  );

  event ProjectClosed(uint256 projectId);

  event ItemSold(
    address indexed buyer,
    uint256 projectId,
    uint256 amount,
    uint256 totalAmount,
    uint256 saleType,
    uint256[] funds,
    uint256[] tokenIds,
    uint256 swapTokenId,
    bool isMetaTx
  );

  event FeeClaimed(uint256 projectId, address user, uint256 amount);

  /*
    struct ProjectRequest {
      uint256 backendId;
      string name;
      string symbol;
      string baseTokenURI;
      uint256 contractType; // 721, 1155, 4907
      uint256 vaultType; // 0: MINT; 1: MINTED
      uint256 adminFeeRate; // 2%
      uint256 devFeeRate; // 0.2%
      bool useMetaTransaction;
      bool canReveal;
      bool transferUnsoldDisabled;
      address forwarder;
      address paymentToken; // ERC20 or address(0) in case of native token
    }

    struct SaleInfo {
      uint256 startTime;
      uint256 endTime;
      bool whitelistRequired;
      uint256 price;
      uint256 amount;
      uint256 maxPurchase;
      uint256 priceType; // 0: FT; 1: NFT (burn -> mint)
      address burnContractAddress;
      uint256 burnContractType; // 721 | 1155
    }

    saleData[0] = presale data (SaleInfo)
    saleData[1] = publicsale data (SaleInfo)
  */
  function createProject(
    ProjectRequest calldata projectInfo_,
    SaleInfo[] calldata saleData_,
    bytes calldata signature_
  ) external returns (uint256);

  function buy(
    uint256 projectId_,
    uint256 saleType_,
    uint256 amount_,
    bytes calldata signature_
  ) external payable;

  function swap(
    uint256 projectId_,
    uint256 saleType_,
    uint256 amount_,
    uint256 tokenId_,
    bytes calldata signature_
  ) external payable;

  function buyWithAuthorization(
    uint256 projectId_,
    uint256 saleType_,
    uint256 amount_,
    bytes calldata signature_,
    bytes calldata transferWithAuthorization_
  ) external;

  function swapWithAuthorization(
    uint256 projectId_,
    uint256 saleType_,
    uint256 amount_,
    uint256 swapTokenId_,
    bytes calldata signature_,
    bytes calldata burnWithAuthorization_
  ) external;

  function closeProject(uint256 projectId) external;

  function claimItems(uint256 projectId, uint256 amount) external;

  function claimFee(uint256 projectId) external payable returns (uint256);

  function getPendingFee(uint256 projectId) external view returns (uint256);

  function getSoldAmount(uint256 projectId, uint256 saleType)
    external
    view
    returns (uint256);

  function getPurchasedAmountOf(
    uint256 projectId,
    address userAddress,
    uint256 saleType
  ) external view returns (uint256);

  function getMaxSupply(uint256 projectId) external view returns (uint256);

  function getTotalSupply(uint256 projectId) external view returns (uint256);
}



interface IT2WebProjectMaster {
  function getProject(uint256 projectId_)
    external
    view
    returns (Project memory);

  function getSaleInfo(uint256 projectId_, uint256 saleType_)
    external
    view
    returns (SaleInfo memory);

  function createProject(
    address projectOwner_,
    ProjectRequest calldata projectInfo_,
    SaleInfo[] calldata saleData_
  ) external returns (Project memory);

  function revealProject(
    uint256 projectId,
    string memory baseTokenURI,
    address sender_
  ) external;

  function distributeNFTs(
    uint256 projectId_,
    address to_,
    uint256 amount_
  ) external returns (uint256[] memory);

  function getMaxSupply(uint256 projectId_) external view returns (uint256);

  function getTotalSupply(uint256 projectId_) external view returns (uint256);

  function closeProject(uint256 projectId_, address sender_) external;

  function claimItems(
    uint256 projectId_,
    uint256 amount_,
    address to_
  ) external;
}



interface IERC1155 {
  function burn(
    address account,
    uint256 id,
    uint256 amount
  ) external;

  /**
   * @notice Execute a burn with a signed authorization
   * @param account       Owner's address (Authorizer)
   * @param id            Token ID to be burned
   * @param amount        Amount to be burned
   * @param validAfter    The time after which this is valid (unix time)
   * @param validBefore   The time before which this is valid (unix time)
   * @param nonce         Unique nonce
   * @param v             v of the signature
   * @param r             r of the signature
   * @param s             s of the signature
   */
  function burnWithAuthorization(
    address account,
    uint256 id,
    uint256 amount,
    uint256 validAfter,
    uint256 validBefore,
    bytes32 nonce,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}


interface IERC20 {
  function balanceOf(address account) external view returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);

  /**
   * @notice Execute a transfer with a signed authorization
   * @param from          Payer's address (Authorizer)
   * @param to            Payee's address
   * @param value         Amount to be transferred
   * @param validAfter    The time after which this is valid (unix time)
   * @param validBefore   The time before which this is valid (unix time)
   * @param nonce         Unique nonce
   * @param v             v of the signature
   * @param r             r of the signature
   * @param s             s of the signature
   */
  function transferWithAuthorization(
    address from,
    address to,
    uint256 value,
    uint256 validAfter,
    uint256 validBefore,
    bytes32 nonce,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;
}












contract T2WebProjectManager is
  IT2WebProjectManager,
  AccessControlUpgradeable,
  ERC721Holder,
  ERC1155Holder
{
  using Signature for bytes32;

  // keccak256("transferWithAuthorization(address,address,uint256,uint256,uint256,bytes32,uint8,bytes32,bytes32)")[0:4]
  bytes4 private constant _ERC20_TRANSFER_WITH_AUTHORIZATION_SELECTOR =
    0xe3ee160e;

  // keccak256("transferWithAuthorization(address,address,uint256,uint256,bytes,uint256,uint256,bytes32,uint8,bytes32,bytes32)")[0:4]
  bytes4 private constant _ERC1155_TRANSFER_WITH_AUTHORIZATION_SELECTOR =
    0x7fe9985b;

  // keccak256("burnWithAuthorization(address,uint256,uint256,uint256,uint256,bytes32,uint8,bytes32,bytes32)")[0:4]
  bytes4 private constant _ERC1155_BURN_WITH_AUTHORIZATION_SELECTOR =
    0xb084e482;

  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  uint256 public constant A_HUNDRED_PERCENT = 10_000; // 100%

  IT2WebProjectMaster private _projectMaster;

  address private _trustedForwarder;
  address private _signer;
  address private _adminFeeReceiver; // admin fee receiver
  address private _devFeeReceiver; // dev fee receiver

  address private _deadAddress; // address to burn NFTs

  // project id => sale type => user => user purchased amount
  mapping(uint256 => mapping(uint256 => mapping(address => uint256)))
    private _userPurchased;

  // project id => sale type => purchased amount
  mapping(uint256 => mapping(uint256 => uint256)) private _purchased;

  // project id => fund info
  mapping(uint256 => FundInfo) private _fundData;

  modifier onlyAdmin() {
    require(
      hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
      "ProjectManager: caller is not admin"
    );
    _;
  }

  modifier onlyOperator() {
    require(
      hasRole(OPERATOR_ROLE, _msgSender()),
      "ProjectManager: caller is not operator"
    );
    _;
  }

  function initialize(
    address projectMaster_,
    address trustedForwarder_,
    address signer_,
    address adminFeeReceiver_,
    address devFeeReceiver_
  ) external initializer {
    __AccessControl_init();

    _projectMaster = IT2WebProjectMaster(projectMaster_);
    _signer = signer_;
    _adminFeeReceiver = adminFeeReceiver_;
    _devFeeReceiver = devFeeReceiver_;
    _trustedForwarder = trustedForwarder_;

    address msgSender = _msgSender();
    _setupRole(DEFAULT_ADMIN_ROLE, msgSender);
    _setupRole(OPERATOR_ROLE, msgSender);
  }

  function isTrustedForwarder(address forwarder)
    public
    view
    virtual
    returns (bool)
  {
    return forwarder == _trustedForwarder;
  }

  function _msgSender() internal view override returns (address sender) {
    if (isTrustedForwarder(msg.sender)) {
      // The assembly code is more direct than the Solidity version using `abi.decode`.
      assembly {
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else {
      return super._msgSender();
    }
  }

  function setProjectMaster(address projectMaster_) external onlyAdmin {
    _projectMaster = IT2WebProjectMaster(projectMaster_);
  }

  function setSigner(address signer_) external onlyAdmin {
    _signer = signer_;
  }

  function setAdminFeeReceiver(address adminFeeReceiver_) external onlyAdmin {
    _adminFeeReceiver = adminFeeReceiver_;
  }

  function setDevFeeReceiver(address devFeeReceiver_) external onlyAdmin {
    _devFeeReceiver = devFeeReceiver_;
  }

  function getProjectMaster() external view returns (address) {
    return address(_projectMaster);
  }

  receive() external payable {}

  function createProject(
    ProjectRequest calldata projectInfo_,
    SaleInfo[] calldata saleData_,
    bytes calldata signature_
  ) public returns (uint256 projectId) {
    address owner = _msgSender();
    bytes32 messageHash = keccak256(
      abi.encodePacked(
        projectInfo_.backendId,
        owner,
        // presale
        saleData_[0].price,
        saleData_[0].amount,
        saleData_[0].maxPurchase,
        saleData_[0].priceType,
        // public sale
        saleData_[1].price,
        saleData_[1].amount,
        saleData_[1].maxPurchase,
        saleData_[1].priceType
      )
    );
    messageHash.verifySignature(signature_, _signer);

    projectId = _createProject(projectInfo_, saleData_, owner);
  }

  function _createProject(
    ProjectRequest calldata projectInfo_,
    SaleInfo[] calldata saleData_,
    address projectOwner_
  ) internal returns (uint256) {
    Project memory project = _projectMaster.createProject(
      projectOwner_,
      projectInfo_,
      saleData_
    );

    emit ProjectCreated(
      project.backendId,
      project.id,
      project.contractType,
      project.contractAddress,
      project.owner,
      uint256(project.state)
    );

    return project.id;
  }

  function revealProject(uint256 projectId_, string memory baseTokenURI_)
    external
  {
    _projectMaster.revealProject(projectId_, baseTokenURI_, msg.sender);

    emit ProjectRevealed(projectId_, true, baseTokenURI_);
  }

  function _updateFunds(Project memory project_, uint256 totalPrice_)
    internal
    returns (uint256[] memory)
  {
    uint256[] memory funds = new uint256[](3);
    funds[0] = (totalPrice_ * project_.adminFeeRate) / A_HUNDRED_PERCENT;
    funds[1] = (totalPrice_ * project_.devFeeRate) / A_HUNDRED_PERCENT;
    funds[2] = totalPrice_ - funds[0] - funds[1];

    FundInfo storage data = _fundData[project_.id];
    if (funds[0] > 0) data.admin += funds[0];
    if (funds[1] > 0) data.dev += funds[1];
    if (funds[2] > 0) data.projectOwner += funds[2];

    return funds;
  }

  function _getPresaleRemaining(uint256 projectId_)
    internal
    view
    returns (uint256)
  {
    uint256 soldAmount = _purchased[projectId_][uint256(SaleType.PRESALE)];
    SaleInfo memory saleInfo = _projectMaster.getSaleInfo(
      projectId_,
      uint256(SaleType.PRESALE)
    );
    return saleInfo.amount > soldAmount ? saleInfo.amount - soldAmount : 0;
  }

  function _verifyBuy(
    address buyer_,
    Project memory project_,
    SaleInfo memory saleInfo_,
    uint256 saleType_,
    uint256 amount_,
    bytes calldata signature_
  ) internal view {
    require(project_.state == ProjectState.CREATED, "INVALID_STATE");
    require(saleInfo_.amount > 0, "BUY_NOT_ALLOWED");
    require(
      block.timestamp >= saleInfo_.startTime &&
        block.timestamp <= saleInfo_.endTime,
      "BUY_NOT_ALLOWED"
    );

    // Check max purchase if required
    if (saleInfo_.maxPurchase > 0) {
      uint256 purchasedAmount = _userPurchased[project_.id][saleType_][buyer_];
      require(
        purchasedAmount + amount_ <= saleInfo_.maxPurchase,
        "AMOUNT_OVER_LIMITATION"
      );
    }

    uint256 soldAmount = _purchased[project_.id][saleType_];
    uint256 maxSupply = saleInfo_.amount;
    if (
      project_.transferUnsoldDisabled &&
      SaleType(saleType_) == SaleType.PUBLICSALE
    ) {
      maxSupply += _getPresaleRemaining(project_.id);
    }
    require(soldAmount + amount_ <= maxSupply, "AMOUNT_INVALID");

    // Check whitelist if required
    if (saleInfo_.whitelistRequired) {
      bytes32 messageHash = keccak256(
        abi.encodePacked(project_.backendId, project_.id, buyer_, amount_)
      );
      messageHash.verifySignature(signature_, _signer);
    }
  }

  function _buyOrSwap(
    address buyer_,
    Project memory project_,
    SaleInfo memory saleInfo_,
    uint256 saleType_,
    uint256 amount_,
    uint256 swapTokenId_,
    bytes calldata signature_,
    bool isMetaTx_
  ) internal {
    _verifyBuy(buyer_, project_, saleInfo_, saleType_, amount_, signature_);

    uint256[] memory funds;
    if (PriceType(saleInfo_.priceType) == PriceType.PRICE) {
      if (saleInfo_.price > 0) {
        uint256 totalPrice = saleInfo_.price * amount_;

        if (!isMetaTx_) {
          if (address(project_.paymentToken) != address(0)) {
            IERC20(project_.paymentToken).transferFrom(
              buyer_,
              address(this),
              totalPrice
            );
          } else {
            require(
              msg.value == totalPrice,
              "ProjectManager: amount does not match with price"
            );
          }
        }

        funds = _updateFunds(project_, totalPrice);
      }
    } else if (PriceType(saleInfo_.priceType) == PriceType.SWAP) {
      if (!isMetaTx_) {
        IERC1155(saleInfo_.burnContractAddress).burn(
          buyer_,
          swapTokenId_,
          amount_
        );
      }
    }

    _purchased[project_.id][saleType_] += amount_;
    _userPurchased[project_.id][saleType_][buyer_] += amount_;

    // Distribute NFTs
    uint256[] memory tokenIds = _projectMaster.distributeNFTs(
      project_.id,
      buyer_,
      amount_
    );

    emit ItemSold(
      buyer_,
      project_.id,
      amount_,
      _purchased[project_.id][saleType_],
      saleType_,
      funds,
      tokenIds,
      swapTokenId_,
      isMetaTx_
    );
  }

  function buy(
    uint256 projectId_,
    uint256 saleType_,
    uint256 amount_,
    bytes calldata signature_
  ) external payable {
    Project memory project = _projectMaster.getProject(projectId_);
    SaleInfo memory saleInfo = _projectMaster.getSaleInfo(
      projectId_,
      saleType_
    );
    _buyOrSwap(
      msg.sender,
      project,
      saleInfo,
      saleType_,
      amount_,
      0,
      signature_,
      false
    );
  }

  function _receiveERC20WithAuthorization(
    address buyer_,
    uint256 totalPrice_,
    address contractAddress_,
    bytes calldata transferWithAuthorization_
  ) internal {
    (address from, address to, uint256 amount) = abi.decode(
      transferWithAuthorization_[0:96],
      (address, address, uint256)
    );
    require(from == buyer_, "ProjectManager: invalid buyer");
    require(to == address(this), "ProjectManager: invalid recipient");
    require(
      amount == totalPrice_,
      "ProjectManager: amount does not match with price"
    );

    (bool success, ) = contractAddress_.call(
      abi.encodePacked(
        _ERC20_TRANSFER_WITH_AUTHORIZATION_SELECTOR,
        transferWithAuthorization_
      )
    );

    require(success, "ProjectManager: failed to transfer tokens");
  }

  function _buyWithAuthorization(
    Project memory project_,
    SaleInfo memory saleInfo_,
    uint256 saleType_,
    uint256 amount_,
    bytes calldata signature_,
    bytes calldata transferWithAuthorization_
  ) internal {
    address buyer = _msgSender();
    uint256 totalPrice = saleInfo_.price * amount_;

    if (saleInfo_.price > 0) {
      _receiveERC20WithAuthorization(
        buyer,
        totalPrice,
        project_.paymentToken,
        transferWithAuthorization_
      );
    }

    _buyOrSwap(
      buyer,
      project_,
      saleInfo_,
      saleType_,
      amount_,
      0,
      signature_,
      true
    );
  }

  function buyWithAuthorization(
    uint256 projectId_,
    uint256 saleType_,
    uint256 amount_,
    bytes calldata signature_,
    bytes calldata transferWithAuthorization_
  ) external {
    Project memory project = _projectMaster.getProject(projectId_);
    SaleInfo memory saleInfo = _projectMaster.getSaleInfo(
      projectId_,
      saleType_
    );
    require(
      project.useMetaTransaction,
      "ProjectManager: must use meta transaction"
    );
    _buyWithAuthorization(
      project,
      saleInfo,
      saleType_,
      amount_,
      signature_,
      transferWithAuthorization_
    );
  }

  function swap(
    uint256 projectId_,
    uint256 saleType_,
    uint256 amount_,
    uint256 tokenId_,
    bytes calldata signature_
  ) external payable {
    Project memory project = _projectMaster.getProject(projectId_);
    SaleInfo memory saleInfo = _projectMaster.getSaleInfo(
      projectId_,
      saleType_
    );
    // Burn
    _buyOrSwap(
      _msgSender(),
      project,
      saleInfo,
      saleType_,
      amount_,
      tokenId_,
      signature_,
      false
    );
  }

  // function _receiveERC1155WithAuthorization(
  //   address buyer_,
  //   uint256 tokenId_,
  //   uint256 amount_,
  //   address contractAddress_,
  //   bytes calldata transferWithAuthorization_
  // ) internal {
  //   (address from, address to, uint256 id, uint256 amount, , , , , , , ) = abi
  //     .decode(
  //       transferWithAuthorization_,
  //       (
  //         address,
  //         address,
  //         uint256,
  //         uint256,
  //         bytes,
  //         uint256,
  //         uint256,
  //         bytes32,
  //         uint8,
  //         bytes32,
  //         bytes32
  //       )
  //     );
  //   require(from == buyer_, "ProjectManager: invalid buyer");
  //   require(to == address(this), "ProjectManager: invalid recipient");
  //   require(id == tokenId_, "ProjectManager: invalid tokenid");
  //   require(amount == amount_, "ProjectManager: invalid amount");

  //   (bool success, ) = contractAddress_.call(
  //     abi.encodePacked(
  //       _ERC1155_TRANSFER_WITH_AUTHORIZATION_SELECTOR,
  //       transferWithAuthorization_
  //     )
  //   );

  //   require(success, "ProjectManager: failed to transfer tokens");
  // }

  function _burnERC1155WithAuthorization(
    address buyer_,
    uint256 tokenId_,
    uint256 amount_,
    address contractAddress_,
    bytes calldata burnWithAuthorization_
  ) internal {
    (address account, uint256 id, uint256 amount, , , , , , ) = abi.decode(
      burnWithAuthorization_,
      (
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        bytes32,
        uint8,
        bytes32,
        bytes32
      )
    );
    require(account == buyer_, "ProjectManager: invalid buyer");
    require(id == tokenId_, "ProjectManager: invalid tokenid");
    require(amount == amount_, "ProjectManager: invalid amount");

    (bool success, ) = contractAddress_.call(
      abi.encodePacked(
        _ERC1155_BURN_WITH_AUTHORIZATION_SELECTOR,
        burnWithAuthorization_
      )
    );

    require(success, "ProjectManager: failed to burn token");
  }

  function _swapWithAuthorization(
    Project memory project_,
    SaleInfo memory saleInfo_,
    uint256 saleType_,
    uint256 amount_,
    uint256 tokenId_,
    bytes calldata signature_,
    bytes calldata burnWithAuthorization_
  ) internal {
    address buyer = _msgSender();

    _burnERC1155WithAuthorization(
      buyer,
      tokenId_,
      amount_,
      saleInfo_.burnContractAddress,
      burnWithAuthorization_
    );

    // Burn
    _buyOrSwap(
      buyer,
      project_,
      saleInfo_,
      saleType_,
      amount_,
      tokenId_,
      signature_,
      true
    );
  }

  function swapWithAuthorization(
    uint256 projectId_,
    uint256 saleType_,
    uint256 amount_,
    uint256 tokenId_,
    bytes calldata signature_,
    bytes calldata burnWithAuthorization_
  ) external {
    Project memory project = _projectMaster.getProject(projectId_);
    SaleInfo memory saleInfo = _projectMaster.getSaleInfo(
      projectId_,
      saleType_
    );
    require(
      project.useMetaTransaction,
      "ProjectManager: must use meta transaction"
    );
    // Burn
    _swapWithAuthorization(
      project,
      saleInfo,
      saleType_,
      amount_,
      tokenId_,
      signature_,
      burnWithAuthorization_
    );
  }

  function getMaxSupply(uint256 projectId) external view returns (uint256) {
    return _projectMaster.getMaxSupply(projectId);
  }

  function getTotalSupply(uint256 projectId) external view returns (uint256) {
    return _projectMaster.getTotalSupply(projectId);
  }

  function getPurchasedAmountOf(
    uint256 projectId,
    address userAddress,
    uint256 saleType
  ) external view returns (uint256) {
    return _userPurchased[projectId][saleType][userAddress];
  }

  function getSoldAmount(uint256 projectId, uint256 saleType)
    external
    view
    returns (uint256)
  {
    return _purchased[projectId][saleType];
  }

  function getPendingFee(uint256 projectId) external view returns (uint256) {
    Project memory project = _projectMaster.getProject(projectId);
    FundInfo memory funds = _fundData[projectId];
    address user = _msgSender();

    if (user == project.owner) {
      return funds.projectOwner;
    }
    if (user == _adminFeeReceiver) {
      return funds.admin;
    }
    if (user == _devFeeReceiver) {
      return funds.dev;
    }
    return 0;
  }

  function claimFee(uint256 projectId) external payable returns (uint256) {
    address user = _msgSender();
    Project memory project = _projectMaster.getProject(projectId);

    require(
      user == project.owner ||
        user == _adminFeeReceiver ||
        user == _devFeeReceiver,
      "ProjectManager: not allowed"
    );

    uint256 amount = 0;

    FundInfo storage fees = _fundData[projectId];
    if (user == project.owner) {
      amount = fees.projectOwner;
      fees.projectOwner = 0;
    } else if (user == _adminFeeReceiver) {
      amount = fees.admin;
      fees.admin = 0;
    } else if (user == _devFeeReceiver) {
      amount = fees.dev;
      fees.dev = 0;
    }

    if (amount > 0) {
      if (project.paymentToken != address(0)) {
        IERC20 paymentToken = IERC20(project.paymentToken);

        if (paymentToken.balanceOf(address(this)) < amount) {
          amount = paymentToken.balanceOf(address(this));
        }
        paymentToken.transfer(user, amount);
      } else {
        if (address(this).balance < amount) {
          amount = address(this).balance;
        }
        payable(user).transfer(amount);
      }
    }

    emit FeeClaimed(projectId, user, amount);

    return amount;
  }

  function claimItems(uint256 projectId, uint256 amount) external {
    _projectMaster.claimItems(projectId, amount, _msgSender());
  }

  function closeProject(uint256 projectId) external {
    _projectMaster.closeProject(projectId, _msgSender());

    emit ProjectClosed(projectId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC1155Receiver, AccessControlUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}