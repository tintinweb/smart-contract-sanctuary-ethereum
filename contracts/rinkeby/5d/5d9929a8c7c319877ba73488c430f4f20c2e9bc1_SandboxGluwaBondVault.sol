/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File contracts/libs/GluwaBondModel.sol

pragma solidity ^0.8.15;

/** @title Library functions used by contracts within this ecosystem.*/
library GluwaBondModel {
    /**
     * @dev Enum of the different states a Bond Account can be in.
     */
    enum BondAccountState {
        /*0*/
        Pending,
        /*1*/
        Active,
        /*2*/
        Defaulted,
        /*3*/
        Locked,
        /*4*/
        Closed
    }

    /**
     * @dev Enum of the different states a Bond Balance can be in.
     */
    enum BondBalanceState {
        /*0*/
        Pending,
        /*1*/
        Active,
        /*2*/
        Mature,
        /*3*/
        Defaulted,
        /*4*/
        Locked,
        /*5*/
        Closed /* The balance is matured and winthdrawn */
    }

    struct BondAccount {
        // Different states an account can be in
        BondAccountState state;
        uint64 creationDate;
        // address of the owner
        address owner;
        uint256 totalDeposit;
        bytes32 securityReferenceHash;
        // Index of this Account
        uint256 idx;
    }

    struct BondBalance {
        // Different states a balance can be in
        BondBalanceState state;
        uint32 interestRate;
        uint32 interestRatePercentageBase;
        // DateTime stamps for the balance
        uint64 creationDate;
        uint64 maturityDate;
        // address of the owner
        address owner;
        uint256 yield;
        uint256 principal;
        // Index of this balance
        uint256 idx;
        uint256 idxBondAccount;
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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


// File @openzeppelin/contracts-upgradeable/access/[email protected]


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


// File @openzeppelin/contracts-upgradeable/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]


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


// File @openzeppelin/contracts-upgradeable/utils/introspection/[email protected]


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


// File @openzeppelin/contracts-upgradeable/access/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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


// File @openzeppelin/contracts-upgradeable/utils/structs/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/EnumerableSet.sol)

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
 */
library EnumerableSetUpgradeable {
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

        assembly {
            result := store
        }

        return result;
    }
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]


// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;




/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal onlyInitializing {
    }

    function __AccessControlEnumerable_init_unchained() internal onlyInitializing {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}


// File contracts/abstracts/VaultControl.sol

pragma solidity ^0.8.15;



contract VaultControl is Initializable, ContextUpgradeable, AccessControlEnumerableUpgradeable {
    bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR');
    bytes32 public constant CONTROLLER_ROLE = keccak256('CONTROLLER');

    function _VaultControl_Init(address account) internal onlyInitializing {
        __AccessControl_init();
        _setRoleAdmin(OPERATOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(CONTROLLER_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(DEFAULT_ADMIN_ROLE, account);
        _setupRole(OPERATOR_ROLE, account);
        _setupRole(CONTROLLER_ROLE, account);
    }

    /// @dev Restricted to members of the admin role.
    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), 'Restricted to Admins.');
        _;
    }

    /// @dev Restricted to members of the Controller role.
    modifier onlyController() {
        require(isController(_msgSender()), 'Restricted to Controllers.');
        _;
    }

    /// @dev Restricted to members of the Operator role.
    modifier onlyOperator() {
        require(isOperator(_msgSender()), 'Restricted to Operators.');
        _;
    }

    /// @dev Return `true` if the account belongs to the admin role.
    function isAdmin(address account) public view returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Add an account to the admin role. Restricted to admins.
    function addAdmin(address account) public onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    /// @dev Return `true` if the account belongs to the operator role.
    function isOperator(address account) public view returns (bool) {
        return hasRole(OPERATOR_ROLE, account);
    }

    /// @dev Add an account to the operator role. Restricted to admins.
    function addOperator(address account) public onlyAdmin {
        grantRole(OPERATOR_ROLE, account);
    }

    /// @dev Remove an account from the Operator role. Restricted to admins.
    function removeOperator(address account) public onlyAdmin {
        revokeRole(OPERATOR_ROLE, account);
    }

    /// @dev Return `true` if the account belongs to the Controller role.
    function isController(address account) public view returns (bool) {
        return hasRole(CONTROLLER_ROLE, account);
    }

    /// @dev Add an account to the Controller role. Restricted to admins.
    function addController(address account) public onlyAdmin {
        grantRole(CONTROLLER_ROLE, account);
    }

    /// @dev Remove an account from the Controller role. Restricted to Admins.
    function removeController(address account) public onlyAdmin {
        revokeRole(CONTROLLER_ROLE, account);
    }

    /// @dev Remove oneself from the Admin role thus all other roles.
    function renounceAdmin() public {
        address sender = _msgSender();
        renounceRole(DEFAULT_ADMIN_ROLE, sender);
        renounceRole(OPERATOR_ROLE, sender);
        renounceRole(CONTROLLER_ROLE, sender);
    }

    /// @dev Remove oneself from the Operator role.
    function renounceOperator() public {
        renounceRole(OPERATOR_ROLE, _msgSender());
    }

    /// @dev Remove oneself from the Controller role.
    function renounceController() public {
        renounceRole(CONTROLLER_ROLE, _msgSender());
    }

    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]


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


// File contracts/libs/HashMapIndex.sol

pragma solidity ^0.8.15;


/** @title Library functions used by contracts within this ecosystem.*/
library HashMapIndex {

    /**
     * @dev Enum to store the states of HashMapping entries
     */
    enum HashState {
        /*0*/
        Invalid,
        /*1*/
        Active,
        /*2*/
        Archived
    }

    /**
     * @dev Efficient storage container for active and archived hashes enabling iteration
     */
    struct HashMapping {
        mapping(bytes32 => HashState) hashState;
        mapping(uint256 => bytes32) itHashMap;
        uint256 firstIdx;
        uint256 nextIdx;
        uint256 count;
    }

    /**
     * @dev Add a new hash to the storage container if it is not yet part of it
     * @param self Struct storage container pointing to itself
     * @param _hash Hash to add to the struct
     */
    function add(HashMapping storage self, bytes32 _hash) internal {
        // Ensure that the hash has not been previously already been added (is still in an invalid state)
        assert(self.hashState[_hash] == HashState.Invalid);
        // Set the state of hash to Active
        self.hashState[_hash] = HashState.Active;
        // Index the hash with the next idx
        self.itHashMap[self.nextIdx] = _hash;
        self.nextIdx++;
        self.count++;
    }

    /**
     * @dev Archives an existing hash if it is an active hash part of the struct
     * @param self Struct storage container pointing to itself
     * @param _hash Hash to archive in the struct
     */
    function archive(HashMapping storage self, bytes32 _hash) internal {
        // Ensure that the state of the hash is active
        assert(self.hashState[_hash] == HashState.Active);
        // Set the State of hash to Archived
        self.hashState[_hash] = HashState.Archived;
        // Reduce the size of the number of active hashes
        self.count--;

        // Check if the first hash in the active list is in an archived state
        if (
            self.hashState[self.itHashMap[self.firstIdx]] == HashState.Archived
        ) {
            self.firstIdx++;
        }

        // Repeat one more time to allowing for 'catch up' of firstIdx;
        // Check if the first hash in the active list is still active or has it already been archived
        if (
            self.hashState[self.itHashMap[self.firstIdx]] == HashState.Archived
        ) {
            self.firstIdx++;
        }
    }

    /**
     * @dev Verifies if the hash provided is a currently active hash and part of the mapping
     * @param self Struct storage container pointing to itself
     * @param _hash Hash to verify
     * @return Indicates if the hash is active (and part of the mapping)
     */
    function isActive(HashMapping storage self, bytes32 _hash)
        internal
        view
        returns (bool)
    {
        return self.hashState[_hash] == HashState.Active;
    }

    /**
     * @dev Verifies if the hash provided is an archived hash and part of the mapping
     * @param self Struct storage container pointing to itself
     * @param _hash Hash to verify
     * @return Indicates if the hash is archived (and part of the mapping)
     */
    function isArchived(HashMapping storage self, bytes32 _hash)
        internal
        view
        returns (bool)
    {
        return self.hashState[_hash] == HashState.Archived;
    }

    /**
     * @dev Verifies if the hash provided is either an active or archived hash and part of the mapping
     * @param self Struct storage container pointing to itself
     * @param _hash Hash to verify
     * @return Indicates if the hash is either active or archived (part of the mapping)
     */
    function isValid(HashMapping storage self, bytes32 _hash)
        internal
        view
        returns (bool)
    {
        return self.hashState[_hash] != HashState.Invalid;
    }

    /**
     * @dev Retrieve the specified (_idx) hash from the struct
     * @param self Struct storage container pointing to itself
     * @param _idx Index of the hash to retrieve
     * @return Hash specified by the _idx value (returns 0x0 if _idx is an invalid index)
     */
    function get(HashMapping storage self, uint256 _idx)
        internal
        view
        returns (bytes32)
    {
        return self.itHashMap[_idx];
    }
}


// File contracts/libs/UintArrayUtil.sol

pragma solidity ^0.8.15;

/** @title Library functions used by contracts within this ecosystem.*/
library UintArrayUtil {
    function removeByIndex(uint256[] storage self, uint256 index) internal {
        if (index >= self.length) return;

        for (uint256 i = index; i < self.length - 1; i++) {
            self[i] = self[i + 1];
        }
        self.pop();
    }

    /// @dev the value for each item in the array must be unique
    function removeByValue(uint256[] storage self, uint256 val) internal {
        if (self.length == 0) return;
        uint256 j;
        for (uint256 i = 0; i < self.length - 1; i++) {
            if (self[i] == val) {
                j = i + 1;
            }
            self[i] = self[j];
            j++;
        }
        self.pop();
    }

    /// @dev add new item into the array
    function add(uint256[] storage self, uint256 val) internal {
        self.push(val);
    }
}


// File contracts/abstracts/GluwacoinBond.sol

pragma solidity ^0.8.15;





contract GluwacoinBond is Initializable, ContextUpgradeable {
    using HashMapIndex for HashMapIndex.HashMapping;
    using UintArrayUtil for uint256[];

    /**
     * @dev
        if interest rate is 15%, the interestRatePercentageBase is 100 and interestRate is 15
        if interest rate is 15.5%, the interestRatePercentageBase is 1000 and interestRate is 155
     */
    uint32 internal _totalNonMaturedBond;
    uint32 private _standardInterestRate;
    uint32 private _standardInterestRatePercentageBase;
    uint64 private _standardMaturityTerm;

    /// @dev Each Bond's principal amount cannot exceed this cap.
    uint256 private _budget;
    uint256 private _minimumDeposit;
    uint256 private _maximumDeposit;

    HashMapIndex.HashMapping private _bondAccountIndex;
    HashMapIndex.HashMapping private _bondBalanceIndex;

    /// @dev The total amount users deposit to this bond contract minus the withdrawn principal
    uint256 internal _currentTotalContractDeposit;

    /// @dev The supported token which can be deposited to a bond account.
    IERC20Upgradeable internal _token;
    /// @dev The total holding balance is SUM of all principal and yeild of non-matured bond.
    mapping(address => bytes32) private _addressBondAccountMapping;
    mapping(bytes32 => bool) private _usedIdentityHash;
    mapping(address => uint256[]) private _addressNonMatureBondBalanceMapping;
    mapping(address => uint256) private _addressCurrentDeposit;
    mapping(bytes32 => GluwaBondModel.BondAccount) internal _bondAccountStorage;
    mapping(bytes32 => GluwaBondModel.BondBalance) internal _bondBalanceStorage;

    event LogBondAccount(bytes32 indexed bondHash, address indexed owner);

    event LogBondBalance(bytes32 indexed bondHash, address indexed owner, uint256 deposit, uint256 fee);

    /**
     * @return the total amount of token put into the bond contract.
     */
    function getCurrentTotalDeposit() public view returns (uint256) {
        return _currentTotalContractDeposit;
    }

    function _GluwacoinBond_init(
        address tokenAddress,
        uint32 standardInterestRate,
        uint32 standardInterestRatePercentageBase,
        uint64 standardMaturityTerm,
        uint256 budget,
        uint256 minimumDeposit,
        uint256 maximumDeposit
    ) internal onlyInitializing {
        _token = IERC20Upgradeable(tokenAddress);
        _standardInterestRate = standardInterestRate;
        _standardInterestRatePercentageBase = standardInterestRatePercentageBase;
        _standardMaturityTerm = standardMaturityTerm;
        _budget = budget;
        _minimumDeposit = minimumDeposit;
        _maximumDeposit = maximumDeposit;
        _bondAccountIndex.firstIdx = 1;
        _bondAccountIndex.nextIdx = 1;
        _bondAccountIndex.count = 0;
        _bondBalanceIndex.firstIdx = 1;
        _bondBalanceIndex.nextIdx = 1;
        _bondBalanceIndex.count = 0;
    }

    function getBondBalance(bytes32 bondBalanceHash)
        external
        view
        returns (
            uint256,
            uint256,
            address,
            uint32,
            uint32,
            uint256,
            uint256,
            uint256,
            uint256,
            GluwaBondModel.BondBalanceState
        )
    {
        address sender = _msgSender();
        GluwaBondModel.BondBalance storage bondBalance = _getBondBalance(bondBalanceHash);
        require(bondBalance.owner == sender, 'GluwacoinBond: Unauthorized access to the bond details');
        return (
            bondBalance.idx,
            bondBalance.idxBondAccount,
            bondBalance.owner,
            bondBalance.interestRate,
            bondBalance.interestRatePercentageBase,
            bondBalance.yield,
            bondBalance.principal,
            bondBalance.creationDate,
            bondBalance.maturityDate,
            bondBalance.state
        );
    }

    function getBondAccount()
        external
        view
        returns (
            uint256,
            address,
            uint256,
            uint256,
            GluwaBondModel.BondAccountState,
            bytes32
        )
    {
        return _getBondAccountFor(_msgSender());
    }

    function _getUserBondBalanceList(address account) internal view returns (uint256[] memory) {
        return _addressNonMatureBondBalanceMapping[account];
    }

    function _getBondAccountHashByIdx(uint256 idx) internal view returns (bytes32) {
        return _bondAccountIndex.get(idx);
    }

    function _getBondBalanceHashByIdx(uint256 idx) internal view returns (bytes32) {
        return _bondBalanceIndex.get(idx);
    }

    function _getBondAccountFor(address account)
        internal
        view
        returns (
            uint256,
            address,
            uint256,
            uint256,
            GluwaBondModel.BondAccountState,
            bytes32
        )
    {
        bytes32 bondAccountHash = _addressBondAccountMapping[account];
        GluwaBondModel.BondAccount storage bondAccount = _getBondAccount(bondAccountHash);
        return (bondAccount.idx, bondAccount.owner, bondAccount.totalDeposit, bondAccount.creationDate, bondAccount.state, bondAccount.securityReferenceHash);
    }

    function _createBondAccount(
        address account,
        uint256 initialDeposit,
        uint256 fee,
        uint64 startDate,
        bytes32 identityHash
    ) internal returns (bytes32, bytes32) {
        return
            _createBondAccount(
                account,
                initialDeposit,
                fee,
                startDate,
                _standardInterestRate,
                _standardInterestRatePercentageBase,
                _standardMaturityTerm,
                identityHash
            );
    }

    function _createBondAccount(
        address account,
        uint256 initialDeposit,
        uint256 fee,
        uint64 startDate,
        uint32 interestRate,
        uint32 interestRatePercentageBase,
        uint64 maturityTerm,
        bytes32 identityHash
    ) internal returns (bytes32, bytes32) {
        require(account != address(0), 'GluwacoinBond: Bond owner address must be defined');

        /// @dev ensure one address only have one account by using account hash (returned by addressBondAccountMapping[account]) to check
        if (_addressBondAccountMapping[account] != 0x0) {
            require(
                _bondAccountStorage[_addressBondAccountMapping[account]].creationDate == 0,
                'GluwacoinBond: Each address should have only 1 bond account only'
            );
        }

        require(_usedIdentityHash[identityHash] == false, 'GluwacoinBond: Identity hash is already used');

        bytes32 bondHash = keccak256(abi.encodePacked(_bondAccountIndex.nextIdx, 'Account', address(this), account));

        /// @dev Add the account to the data storage
        GluwaBondModel.BondAccount storage bondAccount = _bondAccountStorage[bondHash];
        bondAccount.idx = _bondAccountIndex.nextIdx;
        bondAccount.owner = account;
        bondAccount.creationDate = startDate;
        /// @dev set the account's initial status
        bondAccount.state = GluwaBondModel.BondAccountState.Active;
        bondAccount.securityReferenceHash = identityHash;

        _addressBondAccountMapping[account] = bondHash;
        _usedIdentityHash[identityHash] = true;
        _bondAccountIndex.add(bondHash);

        bytes32 bondBalanceHash = _createBondBalance(account, initialDeposit, fee, startDate, interestRate, interestRatePercentageBase, maturityTerm);

        emit LogBondAccount(bondHash, account);

        return (bondHash, bondBalanceHash);
    }

    function _createBondBalance(
        address account,
        uint256 deposit,
        uint256 fee,
        uint64 startDate
    ) internal returns (bytes32) {
        return _createBondBalance(account, deposit, fee, startDate, _standardInterestRate, _standardInterestRatePercentageBase, _standardMaturityTerm);
    }

    function _createBondBalance(
        address account,
        uint256 deposit,
        uint256 fee,
        uint64 startDate,
        uint32 interestRate,
        uint32 interestRatePercentageBase,
        uint64 maturityTerm
    ) internal returns (bytes32) {
        _validateBondBalance(account, deposit);

        require(_token.transferFrom(account, address(this), deposit + fee), 'GluwacoinBond: Unable to send amount to create bond account');

        bytes32 bondBalanceHash = keccak256(abi.encodePacked(_bondBalanceIndex.nextIdx, 'Balance', address(this), account));

        bytes32 hashOfReferenceBond = _addressBondAccountMapping[account];

        require(
            _bondAccountStorage[hashOfReferenceBond].state == GluwaBondModel.BondAccountState.Active,
            "GluwacoinBond: The user's bond account must be active to get more bond balance"
        );

        /// @dev Add the bond balance to the data storage
        GluwaBondModel.BondBalance storage balance = _bondBalanceStorage[bondBalanceHash];
        balance.idx = _bondBalanceIndex.nextIdx;
        balance.idxBondAccount = _bondAccountStorage[hashOfReferenceBond].idx;
        balance.owner = account;
        balance.interestRate = interestRate;
        balance.interestRatePercentageBase = interestRatePercentageBase;
        balance.principal = deposit;
        balance.creationDate = startDate;
        balance.maturityDate = startDate + maturityTerm;
        balance.state = GluwaBondModel.BondBalanceState.Active;

        unchecked {
            _bondAccountStorage[hashOfReferenceBond].totalDeposit += deposit;
            _currentTotalContractDeposit += deposit;
            _addressCurrentDeposit[account] += deposit;
        }
        _addressNonMatureBondBalanceMapping[account].add(_bondBalanceIndex.nextIdx);
        _bondBalanceIndex.add(bondBalanceHash);
        _totalNonMaturedBond += 1;

        emit LogBondBalance(bondBalanceHash, account, deposit, fee);

        return bondBalanceHash;
    }

    function getAllBondBalanceToBeMatured(uint256 targetMatureRange) external view returns (uint256, uint256[] memory) {
        uint256[] memory tobeMaturedList = new uint256[](_bondBalanceIndex.nextIdx - 1);
        uint32 j;
        uint256 currentBlockTime = block.timestamp;
        uint256 totalWithdrawable;
        for (uint256 i = 1; i < _bondBalanceIndex.nextIdx;) {
            GluwaBondModel.BondBalance storage bondBalance = _bondBalanceStorage[_bondBalanceIndex.get(i)];
            if (bondBalance.state == GluwaBondModel.BondBalanceState.Active && bondBalance.maturityDate <= currentBlockTime + targetMatureRange) {
                tobeMaturedList[j++] = i;
                unchecked {
                    totalWithdrawable +=
                        bondBalance.principal +
                        _calculateYield(
                            uint64(bondBalance.maturityDate - bondBalance.creationDate),
                            bondBalance.interestRate,
                            bondBalance.interestRatePercentageBase,
                            bondBalance.principal
                        );
                }
            }
            unchecked {
                ++i;
            }
        }
        return (totalWithdrawable, tobeMaturedList);
    }

    function _withdrawMatureBondBalance(address account) internal returns (uint256) {
        uint256[] storage allBondBalance = _addressNonMatureBondBalanceMapping[account];
        uint256[] memory maturedList = new uint256[](allBondBalance.length);
        uint32 j;
        uint256 currentBlockTime = block.timestamp;
        uint256 totalWithdrawalAmount;
        for (uint256 i = 0; i < allBondBalance.length;) {
            GluwaBondModel.BondBalance storage bondBalance = _bondBalanceStorage[_bondBalanceIndex.get(allBondBalance[i])];
            if (bondBalance.state == GluwaBondModel.BondBalanceState.Active && bondBalance.maturityDate <= currentBlockTime) {
                _matureBondBalance(bondBalance);
                unchecked {
                    totalWithdrawalAmount += bondBalance.yield + bondBalance.principal;
                    maturedList[j++] = allBondBalance[i];
                }
            }
            unchecked {
                ++i;
            }
        }
        for (uint256 i = 0; i < maturedList.length;) {
            if (maturedList[i] > 0) {
                allBondBalance.removeByValue(maturedList[i]);
            }
            unchecked {
                ++i;
            }
        }
        return totalWithdrawalAmount;
    }

    function _matureBondBalance(GluwaBondModel.BondBalance storage bondBalance) internal {
        require(bondBalance.creationDate > 0 && bondBalance.maturityDate <= block.timestamp, 'GluwacoinBond: The bond balance is not matured yet');
        require(bondBalance.state == GluwaBondModel.BondBalanceState.Active, 'GluwacoinBond: The bond balance state must be active');
        GluwaBondModel.BondAccount storage bondAccount = _bondAccountStorage[_bondAccountIndex.get(bondBalance.idxBondAccount)];

        unchecked {
            bondBalance.yield = _calculateYield(
                uint64(bondBalance.maturityDate - bondBalance.creationDate),
                bondBalance.interestRate,
                bondBalance.interestRatePercentageBase,
                bondBalance.principal
            );

            /// @dev Reduce total deposit for the holding bond account
            bondAccount.totalDeposit = bondAccount.totalDeposit - bondBalance.principal;
            _addressCurrentDeposit[bondBalance.owner] = _addressCurrentDeposit[bondBalance.owner] - bondBalance.principal;
            _currentTotalContractDeposit = _currentTotalContractDeposit - bondBalance.principal;
            _totalNonMaturedBond -= 1;
        }

        /// @dev Update the matured bond balance's status
        bondBalance.state = GluwaBondModel.BondBalanceState.Mature;
    }

    function _getBondBalance(bytes32 bondBalanceHash) internal view returns (GluwaBondModel.BondBalance storage) {
        return _bondBalanceStorage[bondBalanceHash];
    }

    function _getBondAccount(bytes32 bondAccountHash) internal view returns (GluwaBondModel.BondAccount storage) {
        return _bondAccountStorage[bondAccountHash];
    }

    /**
     * @return all the bond's settings;.
     */
    function getBondSettings()
        public
        view
        returns (
            uint64,
            uint32,
            uint32,
            uint256,
            uint256,
            uint256,
            IERC20Upgradeable
        )
    {
        return (_standardMaturityTerm, _standardInterestRate, _standardInterestRatePercentageBase, _budget, _minimumDeposit, _maximumDeposit, _token);
    }

    function _setBondSettings(
        uint64 standardMaturityTerm,
        uint32 standardInterestRate,
        uint32 standardInterestRatePercentageBase,
        uint256 budget,
        uint256 minimumDeposit,
        uint256 maximumDeposit
    ) internal {
        _standardMaturityTerm = standardMaturityTerm;
        _standardInterestRate = standardInterestRate;
        _standardInterestRatePercentageBase = standardInterestRatePercentageBase;
        _budget = budget;
        _minimumDeposit = minimumDeposit;
        _maximumDeposit = maximumDeposit;
    }

    /**
     * @dev calculate yield for given amount based on term and interest rate.
            if interest rate is 15%, the interestRatePercentageBase is 100 and interestRate is 15
            if interest rate is 15.5%, the interestRatePercentageBase is 1000 and interestRate is 155
     */
    function _calculateYield(
        uint64 term,
        uint32 interestRate,
        uint32 interestRatePercentageBase,
        uint256 amount
    ) private pure returns (uint256) {
        return (amount * interestRate * term) / (interestRatePercentageBase * 365 days);
    }

    function _validateBondBalance(address account, uint256 deposit) private view {
        require(
            _addressCurrentDeposit[account] + deposit <= _maximumDeposit && deposit >= _minimumDeposit && deposit + _currentTotalContractDeposit <= _budget,
            'GluwacoinBond: the deposit must be >= min deposit & cannot make the total balance > the investment cap.'
        );
    }

    uint256[50] private __gap;
}


// File contracts/GluwaBondVault.sol

pragma solidity ^0.8.15;



contract GluwaBondVault is VaultControl, GluwacoinBond {
    uint8 private _lowerLimitPercentage;
    uint32 private _withdrawFee;
    uint32 private _withdrawFeePercentageBase;

    function initialize(
        address adminAccount,
        address token,
        uint8 lowerLimitPercentage,
        uint32 standardInterestRate,
        uint32 standardInterestRatePercentageBase,
        uint64 standardMaturityTerm,
        uint256 budget,
        uint256 minimumDeposit,
        uint256 maximumDeposit,
        uint32 withdrawFee,
        uint32 withdrawFeePercentageBase
    ) external initializer {
        _VaultControl_Init(adminAccount);
        _GluwacoinBond_init(token, standardInterestRate, standardInterestRatePercentageBase, standardMaturityTerm, budget, minimumDeposit, maximumDeposit);
        _lowerLimitPercentage = lowerLimitPercentage;
        _withdrawFee = withdrawFee;
        _withdrawFeePercentageBase = withdrawFeePercentageBase;
    }

    event Withdraw(address indexed beneficiary, uint256 amount, uint256 fee);
    event Invest(address indexed recipient, uint256 amount);

    function setVaultSettings(
        uint8 lowerLimitPercentage,
        uint32 withdrawFee,
        uint32 withdrawFeePercentageBase         
    ) external onlyOperator {
        _lowerLimitPercentage = lowerLimitPercentage;
        _withdrawFee = withdrawFee;
        _withdrawFeePercentageBase = withdrawFeePercentageBase;
    }

    function getVaultSettings()
        external
        view
        returns (
            uint8,
            uint32,
            uint32            
        )
    {
        return (_lowerLimitPercentage, _withdrawFee, _withdrawFeePercentageBase);
    }

    function version() public pure returns (string memory) {
        return '3.0.0';
    }

    function setBondSettings(
        uint64 standardMaturityTerm,
        uint32 standardInterestRate,
        uint32 standardInterestRatePercentageBase,
        uint256 budget,
        uint256 minimumDeposit,
        uint256 maximumDeposit
    ) external onlyOperator {
        _setBondSettings(standardMaturityTerm, standardInterestRate, standardInterestRatePercentageBase, budget, minimumDeposit, maximumDeposit);
    }

    function setBondAccountState(bytes32 bondAccountHash, GluwaBondModel.BondAccountState state) public onlyController returns (bool) {
        GluwaBondModel.BondAccount storage bondAccount = _bondAccountStorage[bondAccountHash];
        require(bondAccount.creationDate > 0, 'GluwaBondVault: Invalid hash');
        bondAccount.state = state;
        return true;
    }

    function setBondBalanceState(bytes32 bondBalanceHash, GluwaBondModel.BondBalanceState state) public onlyController returns (bool) {
        GluwaBondModel.BondBalance storage bondBalance = _bondBalanceStorage[bondBalanceHash];
        require(
            state != GluwaBondModel.BondBalanceState.Mature && bondBalance.creationDate > 0,
            'GluwaBondVault: Set state to Mature is not allowed or Invalid hash'
        );
        bondBalance.state = state;
        return true;
    }

    function invest(address recipient, uint256 amount) external onlyOperator returns (bool) {
        require(recipient != address(0), 'GluwaBondVault: Recipient address for investment must be defined');
        uint256 totalBalance = _token.balanceOf(address(this));
        unchecked {
            uint256 lowerLimit = (totalBalance * _lowerLimitPercentage) / 100;
            require(
                totalBalance - amount >= lowerLimit || _totalNonMaturedBond == 0,
                'GluwaBondVault: the investment amount will make the total balance lower than the bottom threshold.'
            );
        }
        _token.transfer(recipient, amount);
        emit Invest(recipient, amount);
        return true;
    }

    function createBondAccount(
        address account,
        uint256 amount,
        uint256 fee,
        bytes32 identityHash
    )
        external
        virtual
        onlyController
        returns (
            bool,
            bytes32,
            bytes32
        )
    {
        (bytes32 bondHash, bytes32 bondBalanceHash) = _createBondAccount(account, amount, fee, uint64(block.timestamp), identityHash);
        return (true, bondHash, bondBalanceHash);
    }

    function createBondBalance(
        address account,
        uint256 amount,
        uint256 fee
    ) external virtual onlyController returns (bool, bytes32) {
        return (true, _createBondBalance(account, amount, fee, uint64(block.timestamp)));
    }

    function createBondAccountWithCustomRate(
        address account,
        uint256 amount,
        uint256 fee,
        uint64 startDate,
        uint32 interestRate,
        uint32 interestRatePercentageBase,
        uint64 maturityTerm,
        bytes32 identityHash
    )
        external
        virtual
        onlyAdmin
        returns (
            bool,
            bytes32,
            bytes32
        )
    {
        (bytes32 bondHash, bytes32 bondBalanceHash) = _createBondAccount(
            account,
            amount,
            fee,
            startDate,
            interestRate,
            interestRatePercentageBase,
            maturityTerm,
            identityHash
        );
        return (true, bondHash, bondBalanceHash);
    }

    function createBondBalanceWithCustomRate(
        address account,
        uint256 amount,
        uint256 fee,
        uint64 startDate,
        uint32 interestRate,
        uint32 interestRatePercentageBase,
        uint64 maturityTerm
    ) external onlyAdmin returns (bool, bytes32) {
        return (true, _createBondBalance(account, amount, fee, startDate, interestRate, interestRatePercentageBase, maturityTerm));
    }

    function withdrawMatureBondFor(address account, uint256 fee) external onlyController returns (bool) {
        /// @dev get the withdrawal amount and do the transfer to user's address
        _token.transfer(account, _withdrawMatureBond(account) - fee);
        return true;
    }

    function withdrawAndCloseBalanceFor(bytes32 bondBalanceHash) external onlyController returns (bool) {
        GluwaBondModel.BondBalance storage bondBalance = _getBondBalance(bondBalanceHash);
        /// @dev we only withdraw the balance which is not closed and its term hasn't started yet
        require(
            bondBalance.state != GluwaBondModel.BondBalanceState.Closed && bondBalance.creationDate >= block.timestamp,
            'GluwaBondVault: Unable to withdraw the balance'
        );
        bondBalance.state = GluwaBondModel.BondBalanceState.Closed;
        _token.transfer(bondBalance.owner, bondBalance.principal);
        emit Withdraw(bondBalance.owner, bondBalance.principal, 0);
        return true;
    }

    function withdrawUnclaimedMatureBond(address account, address recipient, uint256 fee) external onlyAdmin {
        _token.transfer(recipient, _withdrawMatureBond(account) - fee);
    }

    function withdrawMatureBond() external {
        _token.transfer(_msgSender(), _withdrawMatureBond(_msgSender()));
    }

    function _withdrawMatureBond(address account) internal returns (uint256) {
        uint256 totalBondWithdrawableAmount = _withdrawMatureBondBalance(account);
        require(totalBondWithdrawableAmount > 0, 'GluwaBondVault: No bond is withdrawable.');
        uint256 totalFee = _calculateFee(totalBondWithdrawableAmount);
        uint256 withdrwalAmount = totalBondWithdrawableAmount - totalFee;
        emit Withdraw(account, withdrwalAmount, totalFee);
        return withdrwalAmount;
    }

    function getUserBondBalanceList(address account) external view onlyController returns (uint256[] memory) {
        return _getUserBondBalanceList(account);
    }

    function getUserBondBalance(bytes32 bondBalanceHash)
        external
        view
        onlyController
        returns (
            uint256,
            uint256,
            address,
            uint32,
            uint32,
            uint256,
            uint256,
            uint256,
            uint256,
            GluwaBondModel.BondBalanceState
        )
    {
        GluwaBondModel.BondBalance storage bondBalance = _getBondBalance(bondBalanceHash);
        return (
            bondBalance.idx,
            bondBalance.idxBondAccount,
            bondBalance.owner,
            bondBalance.interestRate,
            bondBalance.interestRatePercentageBase,
            bondBalance.yield,
            bondBalance.principal,
            bondBalance.creationDate,
            bondBalance.maturityDate,
            bondBalance.state
        );
    }

    function getUserBondAccount(bytes32 bondAccountHash)
        external
        view
        onlyController
        returns (
            uint256,
            address,
            uint256,
            uint256,
            GluwaBondModel.BondAccountState,
            bytes32
        )
    {
        GluwaBondModel.BondAccount storage bondAccount = _getBondAccount(bondAccountHash);
        return (bondAccount.idx, bondAccount.owner, bondAccount.totalDeposit, bondAccount.creationDate, bondAccount.state, bondAccount.securityReferenceHash);
    }

    function getBondAccountFor(address account)
        external
        view
        onlyController
        returns (
            uint256,
            address,
            uint256,
            uint256,
            GluwaBondModel.BondAccountState,
            bytes32
        )
    {
        return _getBondAccountFor(account);
    }

    function getBondAccountHashByIdx(uint256 idx) external view onlyController returns (bytes32) {
        return _getBondAccountHashByIdx(idx);
    }

    function getBondBalanceHashByIdx(uint256 idx) external view onlyController returns (bytes32) {
        return _getBondBalanceHashByIdx(idx);
    }

    function _calculateFee(uint256 amount) private view returns (uint256) {
        return ((amount * _withdrawFee) / (_withdrawFeePercentageBase));
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// File contracts/mock/SandboxGluwaBondVault.sol

pragma solidity ^0.8.15;

contract SandboxGluwaBondVault is GluwaBondVault {
    function createBondAccount(
        address account,
        uint256 amount,
        uint256 fee,
        bytes32 identityHash
    )
        external
        override
        onlyController
        returns (
            bool,
            bytes32,
            bytes32
        )
    {
        (bytes32 bondHash, bytes32 bondBalanceHash) = _createBondAccount(account, amount, fee, uint64(block.timestamp - 365 days), identityHash);
        return (true, bondHash, bondBalanceHash);
    }

    function getTotalNonMaturedBond() external view returns (uint32) {
        return _totalNonMaturedBond;
    }

    function createBondBalance(
        address account,
        uint256 amount,
        uint256 fee
    ) external override onlyController returns (bool, bytes32) {
        return (true, _createBondBalance(account, amount, fee, uint64(block.timestamp - 365 days)));
    }
}