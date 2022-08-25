/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

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


// File @openzeppelin/contracts/access/[email protected]

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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

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


// File contracts/CommissionStorage.sol


pragma solidity ^0.8.0;

contract CreatorDAOCommissionStorage {
    enum CommissionStatus {
        queued,
        accepted,
        removed,
        finished
    }

    struct Shop {
        uint256 minBid;
        uint256 tax; // e.g 50 represent for 5%
        address payable owner;
    }

    struct Commission {
        address payable recipient;
        uint256 shopId;
        uint256 bid;
        CommissionStatus status;
    }

    address payable public admin;
    address payable public recipientDao;

    mapping(uint256 => Commission) public commissions;
    mapping(uint256 => Shop) public shops;

    //uint256public minBid; // the number of wei required to create a commission
    uint256 public newCommissionIndex; // the index of the next commission which should be created in the mapping
    uint256 public newShopIndex;
    bool public callStarted; // ensures no re-entrancy can occur
}


// File contracts/AccessControl.sol







// File @openzeppelin/contracts/access/[email protected]

   
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;




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
    bytes32 public constant OP_ROLE = keccak256("OPERATOR");

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


// File contracts/ERC2771Context.sol

pragma solidity ^0.8.0;

abstract contract ERC2771Context is AccessControl  {
    address public  _trustedForwarder;

    function setTrustedForwarder(address trustedForwarder) public virtual {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }
 
    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}


// File contracts/RoleControl.sol

pragma solidity ^0.8.0;

contract RoleControl is Initializable,   CreatorDAOCommissionStorage, ERC2771Context {

  

  function setRoot (address root) public  {
    require(_msgSender() == admin, "not an admin");

    // NOTE: Other DEFAULT_ADMIN's can remove other admins, give this role with great care
    _setupRole(DEFAULT_ADMIN_ROLE, root); 

    _setRoleAdmin(OP_ROLE, DEFAULT_ADMIN_ROLE);
  }

  // Create a bool check to see if a account address has the role admin
  function isAdmin(address account) public virtual view returns(bool)
  {
    return hasRole(DEFAULT_ADMIN_ROLE, account);
  }

  // Create a modifier that can be used in other contract to make a pre-check
  // That makes sure that the sender of the transaction (msg.sender)  is a admin
  modifier onlyAdmin() {
    require(isAdmin(_msgSender()), "Restricted to admins.");
      _; 
  }

  // Add a user address as a admin
  function addAdmin(address account) public virtual onlyAdmin
  {
    grantRole(DEFAULT_ADMIN_ROLE, account);
  }


    function isOp(address account) public virtual view returns(bool)
  {
    return hasRole(OP_ROLE, account);
  }

  // Create a modifier that can be used in other contract to make a pre-check
  // That makes sure that the sender of the transaction (msg.sender)  is a admin
  modifier onlyOp() {
    require(isOp(_msgSender()), "Restricted to OP.");
      _;
  }

  // Add a user address as a admin
  function addOp(address account) public virtual onlyAdmin
  {
    grantRole(OP_ROLE, account);
  }


  function setTrustedForwarder(address trustedForwarder) public override virtual onlyAdmin {
        _trustedForwarder = trustedForwarder;
    }

}


// File contracts/CreatorDAOCommissionV1_1.sol

pragma solidity ^0.8.2;




contract CreatorDAOCommissionV1_1 is RoleControl {

    modifier callNotStarted() {
        require(!callStarted, "callNotStarted");
        callStarted = true;
        _;
        callStarted = false;
    }

    function initialize(address payable _admin, address payable _recipientDao)
        public
        initializer
    {
        admin = _admin;
        recipientDao = _recipientDao;
        newCommissionIndex = 1;
        newShopIndex = 1;
    }



    function updateTaxRecipient(address payable _newRecipientDao)
        public
        callNotStarted
        onlyAdmin
    {
        recipientDao = _newRecipientDao;
    }

    function updateMinBid(uint256 _shopId, uint256 _newMinBid)
        public
        callNotStarted
        onlyOp
    {
        Shop storage shop = shops[_shopId];
        shop.minBid = _newMinBid;
        emit MinBidUpdated(_shopId, _newMinBid);
    }

    function updateShopOwner(uint256 _shopId, address payable _newOwner)
        public
    {
        Shop storage shop = shops[_shopId];
        require(shop.owner == msg.sender || isOp(msg.sender), "only old owner could set new owner");
        shop.owner = _newOwner;
        emit OwnerUpdated(_shopId, _newOwner);
    }

     function updateAdmin(address payable _newAdmin)
        public
        callNotStarted
        
    {
        require(msg.sender == admin, "not an admin");
        admin = _newAdmin;
        emit AdminUpdated(_newAdmin);
    }

    function commission(string memory _id, uint256 _shopId)
        public
        payable
        callNotStarted
    {
        Shop memory shop = shops[_shopId];
        require(shop.minBid != 0, "undefined shopId");
        require(msg.value >= shop.minBid, "bid below minimum"); // must send the proper amount of into the bid

        // Next, initialize the new commission
        Commission storage newCommission = commissions[newCommissionIndex];
        newCommission.shopId = _shopId;
        newCommission.bid = msg.value;
        newCommission.status = CommissionStatus.queued;
        newCommission.recipient = payable(msg.sender);

        emit NewCommission(
            newCommissionIndex,
            _id,
            _shopId,
            msg.value,
            msg.sender
        );

        newCommissionIndex++; // for the subsequent commission to be added into the next slot
    }

    function rescindCommission(uint256 _commissionIndex) public callNotStarted {
        Commission storage selectedCommission = commissions[_commissionIndex];
        require(
            msg.sender == selectedCommission.recipient,
            "Only recipient could rescind"
        ); // may only be performed by the person who commissioned it
        require(
            selectedCommission.status == CommissionStatus.queued,
            "commission not in queue"
        ); // the commission must still be queued

        // we mark it as removed and return the individual their bid
        selectedCommission.status = CommissionStatus.removed;
        (bool success, ) = selectedCommission.recipient.call{
            value: selectedCommission.bid
        }("");
        require(success, "Transfer failed.");

        emit CommissionRescinded(_commissionIndex, selectedCommission.bid);
    }

    function increaseCommissionBid(uint256 _commissionIndex)
        public
        payable
        callNotStarted
    {
        Commission storage selectedCommission = commissions[_commissionIndex];
        require(
            msg.sender == selectedCommission.recipient,
            "commission not yours"
        ); // may only be performed by the person who commissioned it
        require(
            selectedCommission.status == CommissionStatus.queued,
            "commission not in queue"
        ); // the commission must still be queued

        // then we update the commission's bid
        selectedCommission.bid = selectedCommission.bid + msg.value;

        emit CommissionBidUpdated(
            _commissionIndex,
            msg.value,
            selectedCommission.bid
        );
    }

    function processCommissions(uint256[] memory _commissionIndexes)
        public
        callNotStarted
    {
        for (uint256 i = 0; i < _commissionIndexes.length; i++) {
            Commission storage selectedCommission = commissions[
                _commissionIndexes[i]
            ];

            //the queue my not be empty when processing more commissions
            require(
                selectedCommission.status == CommissionStatus.queued,
                "commission not in the queue"
            );

            require(
                msg.sender == shops[selectedCommission.shopId].owner || isOp(msg.sender),
                "Only shop owner could accept commission"
            );

            selectedCommission.status = CommissionStatus.accepted; // first, we change the status of the commission to accepted

            emit CommissionProcessed(
                _commissionIndexes[i],
                selectedCommission.status
            );
        }
    }

    function settleCommissions(uint256[] memory _commissionIndexes)
        public
        onlyAdmin
        callNotStarted
    {
        uint256 totalTaxAmount = 0;
        for (uint256 i = 0; i < _commissionIndexes.length; i++) {
            Commission storage selectedCommission = commissions[
                _commissionIndexes[i]
            ];

            //the queue my not be empty when processing more commissions
            require(
                selectedCommission.status == CommissionStatus.accepted,
                "commission not in the queue"
            );

            selectedCommission.status = CommissionStatus.finished; // first, we change the status of the commission to accepted

            uint256 taxAmount = (selectedCommission.bid *
                shops[selectedCommission.shopId].tax) / 1000;

            uint256 payAmount = selectedCommission.bid - taxAmount;

            totalTaxAmount = totalTaxAmount + taxAmount;

            (bool success, ) = shops[selectedCommission.shopId].owner.call{
                value: payAmount
            }(""); // next we accept the payment for the commission
            require(success, "Transfer failed.");

            emit CommissionSettled(
                _commissionIndexes[i],
                selectedCommission.status,
                taxAmount,
                payAmount
            );
        }

        (bool success, ) = recipientDao.call{value: totalTaxAmount}("");

        require(success, "Transfer failed.");
    }

    function rescindCommissionByAdmin(uint256 _commissionIndex)
        public
        onlyAdmin
        callNotStarted
    {
        Commission storage selectedCommission = commissions[_commissionIndex];
        require(
            selectedCommission.status == CommissionStatus.accepted,
            "commission not in queue"
        ); // the commission must still be accepted

        // we mark it as removed and return the individual their bid
        selectedCommission.status = CommissionStatus.removed;
        (bool success, ) = selectedCommission.recipient.call{
            value: selectedCommission.bid
        }("");
        require(success, "Transfer failed.");

        emit CommissionRescinded(_commissionIndex, selectedCommission.bid);
    }

    function addShop(
        uint256 _minBid,
        uint256 _tax,
        address _owner
    ) public {
        require(_minBid != 0, "minBid must not zero");
        require(_tax < 1000, "tax too high");
        Shop storage shop = shops[newShopIndex];
        shop.minBid = _minBid;
        shop.tax = _tax;
        shop.owner = payable(_owner);

        emit NewShop(newShopIndex, _minBid, _tax, _owner);
        newShopIndex++;
    }

    event AdminUpdated(address _newAdmin);
    event MinBidUpdated(uint256 _shopId, uint256 _newMinBid);
    event NewCommission(
        uint256 _commissionIndex,
        string _id,
        uint256 _shopId,
        uint256 _bid,
        address _recipient
    );
    event CommissionBidUpdated(
        uint256 _commissionIndex,
        uint256 _addedBid,
        uint256 _newBid
    );
    event CommissionRescinded(uint256 _commissionIndex, uint256 _bid);
    event CommissionProcessed(
        uint256 _commissionIndex,
        CommissionStatus _status
    );
    event CommissionSettled(
        uint256 _commissionIndex,
        CommissionStatus _status,
        uint256 taxAmount,
        uint256 payAmount
    );
    event NewShop(
        uint256 _newShopIndex,
        uint256 _minBid,
        uint256 _tax,
        address owner
    );
    event OwnerUpdated(uint256 _shopId, address _newOwner);
}


// File contracts/CreatorDAOCommissionV2.sol

pragma solidity ^0.8.0;


contract CreatorDAOCommissionV2 is RoleControl {

    modifier callNotStarted() {
        require(!callStarted, "callNotStarted");
        callStarted = true;
        _;
        callStarted = false;
    }

    function initialize(address payable _admin, address payable _recipientDao)
        public
        initializer
    {
        admin = _admin;
        recipientDao = _recipientDao;
        newCommissionIndex = 1;
        newShopIndex = 1;
    }



    function updateTaxRecipient(address payable _newRecipientDao)
        public
        callNotStarted
        onlyAdmin
    {
        recipientDao = _newRecipientDao;
    }

    function updateMinBid(uint256 _shopId, uint256 _newMinBid)
        public
        callNotStarted
        onlyOp
    {
        Shop storage shop = shops[_shopId];
        shop.minBid = _newMinBid;
        emit MinBidUpdated(_shopId, _newMinBid);
    }

    function updateTax(uint256 _shopId, uint256 _tax)
        public
        callNotStarted
    {       
        Shop storage shop = shops[_shopId];
        require(shop.owner == _msgSender() || isOp(_msgSender()), "only owner could update tax");
        shop.tax = _tax;
        emit TaxUpdated(_shopId, _tax);
    }

    function updateShopOwner(uint256 _shopId, address payable _newOwner)
        public
    {
        Shop storage shop = shops[_shopId];
        require(shop.owner == _msgSender() || isOp(_msgSender()), "only old owner could set new owner");
        shop.owner = _newOwner;
        emit OwnerUpdated(_shopId, _newOwner);
    }

     function updateAdmin(address payable _newAdmin)
        public
        callNotStarted
        
    {
        require(_msgSender() == admin, "not an admin");
        admin = _newAdmin;
        emit AdminUpdated(_newAdmin);
    }

    function commission(string memory _id, uint256 _shopId)
        public
        payable
        callNotStarted
    {
        Shop memory shop = shops[_shopId];
        require(shop.minBid != 0, "undefined shopId");
        require(msg.value >= shop.minBid, "bid below minimum"); // must send the proper amount of into the bid

        // Next, initialize the new commission
        Commission storage newCommission = commissions[newCommissionIndex];
        newCommission.shopId = _shopId;
        newCommission.bid = msg.value;
        newCommission.status = CommissionStatus.queued;
        newCommission.recipient = payable(_msgSender());

        emit NewCommission(
            newCommissionIndex,
            _id,
            _shopId,
            msg.value,
            _msgSender()
        );

        newCommissionIndex++; // for the subsequent commission to be added into the next slot
    }

    function rescindCommission(uint256 _commissionIndex) public callNotStarted {
        Commission storage selectedCommission = commissions[_commissionIndex];
        require(
            _msgSender() == selectedCommission.recipient,
            "Only recipient could rescind"
        ); // may only be performed by the person who commissioned it
        require(
            selectedCommission.status == CommissionStatus.queued,
            "commission not in queue"
        ); // the commission must still be queued

        // we mark it as removed and return the individual their bid
        selectedCommission.status = CommissionStatus.removed;
        (bool success, ) = selectedCommission.recipient.call{
            value: selectedCommission.bid
        }("");
        require(success, "Transfer failed.");

        emit CommissionRescinded(_commissionIndex, selectedCommission.bid);
    }

    function increaseCommissionBid(uint256 _commissionIndex)
        public
        payable
        callNotStarted
    {
        Commission storage selectedCommission = commissions[_commissionIndex];
        require(
            _msgSender() == selectedCommission.recipient,
            "commission not yours"
        ); // may only be performed by the person who commissioned it
        require(
            selectedCommission.status == CommissionStatus.queued,
            "commission not in queue"
        ); // the commission must still be queued

        // then we update the commission's bid
        selectedCommission.bid = selectedCommission.bid + msg.value;

        emit CommissionBidUpdated(
            _commissionIndex,
            msg.value,
            selectedCommission.bid
        );
    }

    function processCommissions(uint256[] memory _commissionIndexes)
        public
        callNotStarted
    {
        for (uint256 i = 0; i < _commissionIndexes.length; i++) {
            Commission storage selectedCommission = commissions[
                _commissionIndexes[i]
            ];

            //the queue my not be empty when processing more commissions
            require(
                selectedCommission.status == CommissionStatus.queued,
                "commission not in the queue"
            );

            require(
                _msgSender() == shops[selectedCommission.shopId].owner || isOp(_msgSender()),
                "Only shop owner could accept commission"
            );

            selectedCommission.status = CommissionStatus.accepted; // first, we change the status of the commission to accepted

            emit CommissionProcessed(
                _commissionIndexes[i],
                selectedCommission.status
            );
        }
    }

    function settleCommissions(uint256[] memory _commissionIndexes)
        public
        callNotStarted
    {
        uint256 totalTaxAmount = 0;
        for (uint256 i = 0; i < _commissionIndexes.length; i++) {
            Commission storage selectedCommission = commissions[
                _commissionIndexes[i]
            ];

            //the queue my not be empty when processing more commissions
            require(
                selectedCommission.status == CommissionStatus.accepted,
                "commission not in the queue"
            );
            require(selectedCommission.recipient == _msgSender() || isAdmin(_msgSender()), "only commission owner cloud settle it:)");
            selectedCommission.status = CommissionStatus.finished; // first, we change the status of the commission to accepted

            uint256 taxAmount = (selectedCommission.bid *
                shops[selectedCommission.shopId].tax) / 1000;

            uint256 payAmount = selectedCommission.bid - taxAmount;

            totalTaxAmount = totalTaxAmount + taxAmount;

            (bool success, ) = shops[selectedCommission.shopId].owner.call{
                value: payAmount
            }(""); // next we accept the payment for the commission
            require(success, "Transfer failed.");

            emit CommissionSettled(
                _commissionIndexes[i],
                selectedCommission.status,
                taxAmount,
                payAmount
            );
        }

        (bool success, ) = recipientDao.call{value: totalTaxAmount}("");

        require(success, "Transfer failed.");
    }

    function rescindCommissionByAdmin(uint256 _commissionIndex)
        public
        onlyAdmin
        callNotStarted
    {
        Commission storage selectedCommission = commissions[_commissionIndex];
        require(
            selectedCommission.status == CommissionStatus.accepted,
            "commission not in queue"
        ); // the commission must still be accepted

        // we mark it as removed and return the individual their bid
        selectedCommission.status = CommissionStatus.removed;
        (bool success, ) = selectedCommission.recipient.call{
            value: selectedCommission.bid
        }("");
        require(success, "Transfer failed.");

        emit CommissionRescinded(_commissionIndex, selectedCommission.bid);
    }

    function addShop(
        uint256 _minBid,
        uint256 _tax,
        address _owner
    ) public  onlyOp{
        require(_minBid != 0, "minBid must not zero");
        require(_tax < 1000, "tax too high");
        Shop storage shop = shops[newShopIndex];
        shop.minBid = _minBid;
        shop.tax = _tax;
        shop.owner = payable(_owner);

        emit NewShop(newShopIndex, _minBid, _tax, _owner);
        newShopIndex++;
    }

    event AdminUpdated(address _newAdmin);
    event MinBidUpdated(uint256 _shopId, uint256 _newMinBid);
    event NewCommission(
        uint256 _commissionIndex,
        string _id,
        uint256 _shopId,
        uint256 _bid,
        address _recipient
    );
    event CommissionBidUpdated(
        uint256 _commissionIndex,
        uint256 _addedBid,
        uint256 _newBid
    );
    event CommissionRescinded(uint256 _commissionIndex, uint256 _bid);
    event CommissionProcessed(
        uint256 _commissionIndex,
        CommissionStatus _status
    );
    event CommissionSettled(
        uint256 _commissionIndex,
        CommissionStatus _status,
        uint256 taxAmount,
        uint256 payAmount
    );
    event NewShop(
        uint256 _newShopIndex,
        uint256 _minBid,
        uint256 _tax,
        address owner
    );
    event OwnerUpdated(uint256 _shopId, address _newOwner);
    event TaxUpdated(
        uint256 _shopId,
        uint256 _tax
    );
}