/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// Sources flattened with hardhat v2.10.2 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


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


library Signature {
  function splitSignature(bytes memory sig)
    private
    pure
    returns (
      uint8 v,
      bytes32 r,
      bytes32 s
    )
  {
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

  function recoverSigner(bytes32 message, bytes memory sig)
    internal
    pure
    returns (address)
  {
    (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

    return ecrecover(message, v, r, s);
  }

  function prefixed(bytes32 msgHash) internal pure returns (bytes32) {
    return
      keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
  }

  /**
   * @dev Make sure all signatures and signers are valid
   */
  function verifySignature(
    bytes32 msgHash,
    bytes memory signature,
    address signer
  ) internal pure {
    bytes32 message = prefixed(msgHash);
    require(recoverSigner(message, signature) == signer, "INVALID_SIGNATURE");
  }
}


interface IJobRewardMaster {
  event JobCreated(
    address project,
    uint256 jobId,
    uint256 minLock,
    bool isPrivate,
    uint256 state
  );

  event JobUpdated(
    address project,
    uint256 jobId,
    uint256 minLock,
    bool isPrivate,
    uint256 state
  );

  event JobDeposited(
    address project,
    uint256 jobId,
    uint256 depositAmount,
    uint256 state
  );

  event JobApplied(
    address kol,
    uint256 jobId,
    uint256 lockAmount,
    uint256 state
  );

  event SelectedKOL(address kol, uint256 jobId, uint256 state);

  event RejectedKOL(address kol, uint256 jobId, uint256 unlockAmount);

  event JobAccepted(
    address kol,
    uint256 jobId,
    uint256 lockAmount,
    uint256 state
  );

  event JobRejected(address kol, uint256 jobId, uint256 state);

  event JobFinished(
    address project,
    uint256 jobId,
    uint256 state,
    address kol,
    uint256 reward
  );

  event DisputeResolved(
    address project,
    uint256 jobId,
    address kol,
    uint256 state,
    uint256 kolRewardRate,
    uint256 projectDepositRate
  );

  event JobCanceled(address project, uint256 jobId, uint256 state);

  event JobApplicationCanceled(
    address kol,
    address project,
    uint256 jobId,
    uint256 unlockAmount
  );

  // Project create a job
  function createJob(uint256 minLock, bool isPrivate)
    external
    returns (uint256);

  // Project edit a job
  function updateJob(
    uint256 jobId,
    uint256 minLock,
    bool isPrivate
  ) external;

  // Project deposit reward token (USDC) to the job
  function depositJob(uint256 jobId, uint256 amount) external;

  // KOL apply to job
  function applyJob(uint256 jobId, uint256 deposit) external;

  // Project select a KOL for the job
  function selectKOL(uint256 jobId, address kol) external;

  // Project reject a KOL
  function rejectKOL(uint256 jobId, address kol) external;

  // KOL accept the job request, private job only
  function acceptJob(uint256 jobId, bytes calldata signature) external;

  // KOL reject the job request, private job only
  function rejectJob(uint256 jobId, bytes calldata signature) external;

  // Project owner mark job is completed
  function finishJob(uint256 jobId) external;

  // Operator finish a job with fraud resolve
  function resolveDispute(
    uint256 jobId,
    uint256 kolRewardRate,
    uint256 projectDepositRate
  ) external;

  // Project owner cancel a job
  function cancelJob(uint256 jobId) external;

  // KOL cancel a applied job
  function cancelJobApplication(uint256 jobId) external;

  function numberOfActiveJob(address project) external view returns (uint256);

  function appliedJob(uint256 jobId, address kol) external view returns (bool);

  function jobState(uint256 jobId) external view returns (uint256);
}


interface IKOLMasterChefV1 {
  event Staked(
    address user,
    uint256 amount,
    uint256 stakingAmount,
    uint256 lockAmount
  );

  event Unstaked(
    address user,
    uint256 amount,
    uint256 stakingAmount,
    uint256 lockAmount
  );

  event Reduced(
    address user,
    uint256 amount,
    uint256 stakingAmount,
    uint256 lockAmount
  );

  event EmergencyWithdraw(
    address user,
    uint256 stakingAmount,
    uint256 lockAmount
  );

  event Locked(
    address user,
    uint256 amount,
    uint256 stakingAmount,
    uint256 lockAmount
  );

  event Unlocked(
    address user,
    uint256 amount,
    uint256 stakingAmount,
    uint256 lockAmount
  );

  // Deposit CPDT
  function stake(uint256 amount) external;

  // Withdraw CPDT
  function unstake(uint256 amount) external;

  // Lock amount token of account, operator only
  function lock(address account, uint256 amount) external;

  // Unlock amount token of account, operator only
  function unlock(address account, uint256 amount) external;

  // Transfer token from account to receiver, operator only
  function transfer(
    address account,
    address receiver,
    uint256 amount
  ) external;

  // Unstaked without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw() external;

  function getRewardPerShare() external view returns (uint256);

  function getRewardPerBlock() external view returns (uint256);

  function rewardDebtOf(address account) external view returns (uint256);

  // Get pending account's reward
  function pendingRewardOf(address account) external view returns (uint256);

  function stakingAmountOf(address account) external view returns (uint256);

  function lockAmountOf(address account) external view returns (uint256);

  function availableStakingAmountOf(address account)
    external
    view
    returns (uint256);
}


interface IProjectMasterChefV1 {
  event Staked(
    address user,
    uint256 amount,
    uint256 stakingAmount,
    uint256 lockAmount
  );

  event Unstaked(
    address user,
    uint256 amount,
    uint256 stakingAmount,
    uint256 lockAmount
  );

  event EmergencyWithdraw(
    address user,
    uint256 stakingAmount,
    uint256 lockAmount
  );

  event Locked(
    address user,
    uint256 amount,
    uint256 stakingAmount,
    uint256 lockAmount
  );

  event Unlocked(
    address user,
    uint256 amount,
    uint256 stakingAmount,
    uint256 lockAmount
  );

  // Deposit CPDT
  function stake(uint256 amount) external;

  // Withdraw CPDT
  function unstake(uint256 amount) external;

  // Lock amount token of account, operator only
  function lock(address account, uint256 amount) external;

  // Unlock amount token of account, operator only
  function unlock(address account, uint256 amount) external;

  // Unstaked without caring about rewards. EMERGENCY ONLY.
  function emergencyWithdraw() external;

  function getRewardPerShare() external view returns (uint256);

  function getRewardPerBlock() external view returns (uint256);

  function rewardDebtOf(address account) external view returns (uint256);

  // Get pending account's reward
  function pendingRewardOf(address account) external view returns (uint256);

  function stakingAmountOf(address account) external view returns (uint256);

  function lockAmountOf(address account) external view returns (uint256);

  function availableStakingAmountOf(address account)
    external
    view
    returns (uint256);
}


contract JobRewardMaster is
  IJobRewardMaster,
  ReentrancyGuard,
  AccessControlUpgradeable,
  OwnableUpgradeable
{
  using SafeERC20 for IERC20;
  using Signature for bytes32;
  using Counters for Counters.Counter;

  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  uint256 public constant A_HUNDRED_PERCENT = 10_000; // 100%

  Counters.Counter private _jobIdTracker;

  enum JobState {
    NEW,
    READY_FOR_APPLY,
    APPLIED,
    IN_PROGRESS,
    FINISHED,
    FINISHED_WITH_DISPUTE,
    CANCELED,
    REJECTED
  }

  struct Job {
    uint256 id;
    address project;
    bool isPrivate;
    address selectedKOL;
    uint256 minLock;
    uint256 reward;
    JobState state;
  }

  address private _signer;

  IERC20 private _paymentToken; // Payment token - USDC
  IKOLMasterChefV1 private _kolStaking;
  IProjectMasterChefV1 private _projectStaking;

  uint256 private _lockPerJob; // Amount of locking token per job
  uint256 private _maxLock; // Maximum locking amount

  // project => number of active jobs
  mapping(address => uint256) private _numberOfActiveJobs;

  // job id => job
  mapping(uint256 => Job) private _jobs;

  // job id => list of kol address
  mapping(uint256 => address[]) private _jobCandidates;

  // job id => address => deposit amount
  mapping(uint256 => mapping(address => uint256)) private _jobDeposits;

  // job id => address => true | false
  mapping(uint256 => mapping(address => bool)) private _jobAppliedUsers;

  modifier notZeroAddress(address account) {
    require(account != address(0), "JobRewardMaster: address must not be zero");
    _;
  }

  modifier onlyOperator() {
    require(
      hasRole(OPERATOR_ROLE, _msgSender()),
      "JobRewardMaster: caller is not operator"
    );
    _;
  }

  function initialize(
    IERC20 paymentToken_,
    IKOLMasterChefV1 kolStaking_,
    IProjectMasterChefV1 projectStaking_,
    uint256 lockPerJob_,
    uint256 maxLock_,
    address signer_
  ) external initializer {
    address msgSender = _msgSender();
    _setupRole(DEFAULT_ADMIN_ROLE, msgSender);
    _setupRole(OPERATOR_ROLE, msgSender);

    _paymentToken = paymentToken_;
    _kolStaking = kolStaking_;
    _projectStaking = projectStaking_;
    _lockPerJob = lockPerJob_;
    _maxLock = maxLock_;
    _signer = signer_;

    __AccessControl_init();
    __Ownable_init();
  }

  function setSigner(address signer) external {
    require(
      hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
      "JobRewardMaster: caller is not admin"
    );
    _signer = signer;
  }

  // Project create a job
  function createJob(uint256 minLock, bool isPrivate)
    external
    returns (uint256)
  {
    address project = _msgSender();

    _lockIfNeeded(project);

    _jobIdTracker.increment();
    uint256 jobId = _jobIdTracker.current();

    _jobs[jobId] = Job({
      id: jobId,
      project: project,
      isPrivate: isPrivate,
      selectedKOL: address(0),
      minLock: minLock,
      reward: 0,
      state: JobState.NEW
    });

    emit JobCreated(project, jobId, minLock, isPrivate, uint256(JobState.NEW));

    return jobId;
  }

  function updateJob(
    uint256 jobId,
    uint256 minLock,
    bool isPrivate
  ) external nonReentrant {
    address msgSender = _msgSender();
    Job storage job = _jobs[jobId];

    require(
      job.project == msgSender,
      "JobRewardMaster: caller is not project owner"
    );
    require(
      job.state == JobState.NEW || job.state == JobState.READY_FOR_APPLY,
      "JobRewardMaster: job state is invalid"
    );
    job.minLock = minLock;
    job.isPrivate = isPrivate;

    emit JobUpdated(
      job.project,
      job.id,
      job.minLock,
      job.isPrivate,
      uint256(job.state)
    );
  }

  // Project cancel a job
  function cancelJob(uint256 jobId) external nonReentrant {
    address msgSender = _msgSender();
    Job storage job = _jobs[jobId];

    require(
      job.project == msgSender,
      "JobRewardMaster: caller is not project owner"
    );
    require(
      job.state == JobState.NEW ||
        job.state == JobState.READY_FOR_APPLY ||
        job.state == JobState.APPLIED,
      "JobRewardMaster: job state is invalid"
    );

    // Unlock CPDT to all candidates
    uint256 cnt = _jobCandidates[job.id].length;
    for (uint256 i = 0; i < cnt; i++) {
      address candidate = _jobCandidates[job.id][i];
      if (candidate == address(0) || _jobDeposits[job.id][candidate] == 0) {
        continue;
      }

      _kolStaking.unlock(candidate, _jobDeposits[job.id][candidate]);
      _jobDeposits[job.id][candidate] = 0;
    }

    // Refund reward to project
    if (job.reward > 0) {
      _paymentToken.transfer(job.project, job.reward);
      job.reward = 0;
    }

    _unlockIfNeeded(job.project);

    job.state = JobState.CANCELED;

    emit JobCanceled(msgSender, jobId, uint256(job.state));
  }

  // Project deposit reward token (USDC) to the job
  function depositJob(uint256 jobId, uint256 amount) external nonReentrant {
    address project = _msgSender();
    Job storage job = _jobs[jobId];

    require(
      job.project == project,
      "JobRewardMaster: caller is not project owner"
    );
    require(
      job.state == JobState.NEW || job.state == JobState.READY_FOR_APPLY,
      "JobRewardMaster: job state is invalid"
    );
    require(amount > 0, "JobRewardMaster: amount must greater than 0");
    require(amount != job.reward, "JobRewardMaster: already deposit");

    if (amount > job.reward) {
      // Deposit more
      _paymentToken.safeTransferFrom(
        project,
        address(this),
        amount - job.reward
      );
    } else if (amount < job.reward) {
      // Refund
      _paymentToken.transfer(project, job.reward - amount);
    }

    job.state = JobState.READY_FOR_APPLY;
    job.reward = amount;

    emit JobDeposited(job.project, jobId, amount, uint256(job.state));
  }

  // KOL apply to job
  function applyJob(uint256 jobId, uint256 deposit) external nonReentrant {
    address msgSender = _msgSender();
    Job storage job = _jobs[jobId];

    require(!job.isPrivate, "JobRewardMaster: private job");
    require(
      !_jobAppliedUsers[job.id][msgSender],
      "JobRewardMaster: already applied"
    );
    require(
      job.state == JobState.READY_FOR_APPLY || job.state == JobState.APPLIED,
      "JobRewardMaster: job state is invalid"
    );
    require(
      deposit >= job.minLock,
      "JobRewardMaster: deposit must be greater than minLock"
    );

    uint256 availableAmount = _kolStaking.availableStakingAmountOf(msgSender);
    require(availableAmount >= deposit, "JobRewardMaster: not enound stake");

    _kolStaking.lock(msgSender, deposit);

    _jobCandidates[job.id].push(msgSender);

    _jobDeposits[job.id][msgSender] = deposit;

    _jobAppliedUsers[job.id][msgSender] = true;

    if (job.state != JobState.APPLIED) {
      job.state = JobState.APPLIED;
    }

    emit JobApplied(msgSender, job.id, deposit, uint256(job.state));
  }

  // KOL cancel a job application
  function cancelJobApplication(uint256 jobId) external {
    address msgSender = _msgSender();
    Job storage job = _jobs[jobId];

    require(!job.isPrivate, "JobRewardMaster: not allowed");
    require(
      _jobAppliedUsers[job.id][msgSender],
      "JobRewardMaster: application not found"
    );
    require(
      job.state == JobState.NEW ||
        job.state == JobState.READY_FOR_APPLY ||
        job.state == JobState.APPLIED,
      "JobRewardMaster: job state is invalid"
    );

    require(
      job.selectedKOL != msgSender,
      "JobRewardMaster: application has been approved"
    );

    uint256 deposit = _jobDeposits[job.id][msgSender];
    if (deposit > 0) {
      _kolStaking.unlock(msgSender, deposit);

      _jobDeposits[job.id][msgSender] = 0;
    }

    _jobAppliedUsers[job.id][msgSender] = false;

    uint256 cnt = _jobCandidates[job.id].length;
    for (uint256 i = 0; i < cnt; i++) {
      if (_jobCandidates[job.id][i] == msgSender) {
        _jobCandidates[job.id][i] = address(0);
      }
    }

    emit JobApplicationCanceled(msgSender, job.project, job.id, deposit);
  }

  // Project select a candidate for the job
  function selectKOL(uint256 jobId, address kol) external nonReentrant {
    address msgSender = _msgSender();
    Job storage job = _jobs[jobId];

    require(
      job.project == msgSender,
      "JobRewardMaster: caller is not project owner"
    );
    require(!job.isPrivate, "JobRewardMaster: private job");
    require(
      job.state == JobState.APPLIED,
      "JobRewardMaster: job state is invalid"
    );
    require(
      _jobAppliedUsers[job.id][kol],
      "JobRewardMaster: kol has not applied"
    );

    // Unlock deposit for all unselect kols
    uint256 cnt = _jobCandidates[job.id].length;
    for (uint256 i = 0; i < cnt; i++) {
      address candidate = _jobCandidates[job.id][i];
      if (candidate == address(0) || candidate == kol) {
        continue;
      }
      uint256 deposit = _jobDeposits[job.id][candidate];
      if (deposit > 0) {
        _kolStaking.unlock(candidate, deposit);
        _jobDeposits[job.id][candidate] = 0;
      }
    }

    job.selectedKOL = kol;
    job.state = JobState.IN_PROGRESS;

    emit SelectedKOL(kol, jobId, uint256(job.state));
  }

  // Project reject a KOL
  function rejectKOL(uint256 jobId, address kol) external {
    address project = _msgSender();
    Job storage job = _jobs[jobId];

    require(
      job.project == project,
      "JobRewardMaster: caller is not project owner"
    );
    require(
      _jobAppliedUsers[job.id][kol],
      "JobRewardMaster: application not found"
    );
    require(
      job.state == JobState.APPLIED,
      "JobRewardMaster: job state is invalid"
    );

    uint256 deposit = _jobDeposits[job.id][kol];
    if (deposit > 0) {
      _kolStaking.unlock(kol, deposit);

      _jobDeposits[job.id][kol] = 0;
    }

    _jobAppliedUsers[job.id][kol] = false;

    uint256 cnt = _jobCandidates[job.id].length;
    for (uint256 i = 0; i < cnt; i++) {
      if (_jobCandidates[job.id][i] == kol) {
        _jobCandidates[job.id][i] = address(0);
      }
    }

    emit RejectedKOL(kol, job.id, deposit);
  }

  function acceptJob(uint256 jobId, bytes calldata signature)
    external
    nonReentrant
  {
    address msgSender = _msgSender();
    Job storage job = _jobs[jobId];

    // Verify sign
    bytes32 messageHash = keccak256(
      abi.encodePacked(job.project, job.id, msg.sender)
    );
    messageHash.verifySignature(signature, _signer);

    require(job.isPrivate, "JobRewardMaster: not allowed");
    require(
      job.state == JobState.READY_FOR_APPLY,
      "JobRewardMaster: job state is invalid"
    );
    require(
      !_jobAppliedUsers[job.id][msgSender],
      "JobRewardMaster: already applied"
    );

    uint256 availableAmount = _kolStaking.availableStakingAmountOf(msgSender);
    require(
      availableAmount >= job.minLock,
      "JobRewardMaster: not enound stake"
    );

    uint256 deposit = job.minLock;
    _kolStaking.lock(msgSender, deposit);

    _jobCandidates[job.id].push(msgSender);

    _jobDeposits[job.id][msgSender] = deposit;

    _jobAppliedUsers[job.id][msgSender] = true;

    job.selectedKOL = msgSender;
    job.state = JobState.IN_PROGRESS;

    emit JobAccepted(msgSender, jobId, deposit, uint256(job.state));
  }

  // KOL reject the job request, private job only
  function rejectJob(uint256 jobId, bytes calldata signature) external {
    address msgSender = _msgSender();
    Job storage job = _jobs[jobId];

    // Verify sign
    bytes32 messageHash = keccak256(
      abi.encodePacked(job.project, job.id, msg.sender)
    );
    messageHash.verifySignature(signature, _signer);

    require(job.isPrivate, "JobRewardMaster: not allowed");
    require(
      job.state == JobState.READY_FOR_APPLY || job.state == JobState.NEW,
      "JobRewardMaster: job state is invalid"
    );

    // Refund reward to project
    if (job.reward > 0) {
      _paymentToken.transfer(job.project, job.reward);
      job.reward = 0;
    }

    _unlockIfNeeded(job.project);

    job.state = JobState.REJECTED;

    emit JobRejected(msgSender, jobId, uint256(job.state));
  }

  // Project mark job is completed
  function finishJob(uint256 jobId) external nonReentrant {
    address project = _msgSender();
    Job storage job = _jobs[jobId];

    require(
      job.project == project,
      "JobRewardMaster: caller is not project owner"
    );
    require(
      job.state == JobState.IN_PROGRESS,
      "JobRewardMaster: job status is invalid"
    );
    require(job.selectedKOL != address(0), "JobRewardMaster: kol not found");

    // Unlock deposit for candidate
    uint256 deposit = _jobDeposits[job.id][job.selectedKOL];
    if (deposit > 0) {
      _kolStaking.unlock(job.selectedKOL, deposit);

      _jobDeposits[job.id][job.selectedKOL] = 0;
    }

    if (job.reward > 0) {
      _paymentToken.transfer(job.selectedKOL, job.reward);
    }

    _unlockIfNeeded(job.project);

    job.state = JobState.FINISHED;

    if (_numberOfActiveJobs[job.project] > 0) {
      _numberOfActiveJobs[job.project] = _numberOfActiveJobs[job.project] - 1;
    }

    emit JobFinished(
      project,
      jobId,
      uint256(job.state),
      job.selectedKOL,
      job.reward
    );
  }

  function resolveDispute(
    uint256 jobId,
    uint256 kolRewardRate,
    uint256 projectDepositRate
  ) external onlyOperator {
    Job storage job = _jobs[jobId];

    require(
      job.state == JobState.IN_PROGRESS,
      "JobRewardMaster: job status is invalid"
    );
    require(job.selectedKOL != address(0), "JobRewardMaster: kol not found");

    address candidate = job.selectedKOL;

    // Resolve award
    uint256 kolRewardAmount = (job.reward * kolRewardRate) / A_HUNDRED_PERCENT;
    uint256 projectRewardAmount = job.reward - kolRewardAmount;

    if (kolRewardAmount > 0) {
      _paymentToken.transfer(candidate, kolRewardAmount);
    }
    if (projectRewardAmount > 0) {
      _paymentToken.transfer(job.project, projectRewardAmount);
    }

    // Resolve deposit
    uint256 deposit = _jobDeposits[job.id][candidate];
    if (deposit > 0) {
      uint256 projectDepositAmount = (deposit * projectDepositRate) /
        A_HUNDRED_PERCENT;

      _kolStaking.unlock(candidate, deposit);

      _jobDeposits[job.id][candidate] = 0;

      if (projectDepositAmount > 0) {
        _kolStaking.transfer(candidate, job.project, projectDepositAmount);
      }
    }

    _unlockIfNeeded(job.project);

    job.state = JobState.FINISHED_WITH_DISPUTE;

    if (_numberOfActiveJobs[job.project] > 0) {
      _numberOfActiveJobs[job.project] = _numberOfActiveJobs[job.project] - 1;
    }

    emit DisputeResolved(
      job.project,
      job.id,
      candidate,
      uint256(job.state),
      kolRewardRate,
      projectDepositRate
    );
  }

  // Lock CPDT if needed
  function _lockIfNeeded(address project) internal {
    uint256 requiredLockAmount = _lockPerJob;
    uint256 lockingAmount = _projectStaking.lockAmountOf(project);
    if (lockingAmount + requiredLockAmount > _maxLock) {
      requiredLockAmount = _maxLock - lockingAmount;
    }

    uint256 availableAmount = _projectStaking.availableStakingAmountOf(project);
    require(
      availableAmount >= requiredLockAmount,
      "JobRewardMaster: not enound stake"
    );

    if (requiredLockAmount > 0) {
      _projectStaking.lock(project, requiredLockAmount);
    }

    _numberOfActiveJobs[project]++;
  }

  // Unlock CPDT if needed
  function _unlockIfNeeded(address project) internal {
    uint256 remainJob = _numberOfActiveJobs[project] - 1;

    uint256 unlockAmount = _lockPerJob;
    uint256 minLockAmount = remainJob * _lockPerJob;
    if (minLockAmount > _maxLock) {
      minLockAmount = _maxLock;
    }

    uint256 lockingAmount = _projectStaking.lockAmountOf(project);
    if (lockingAmount - unlockAmount < minLockAmount) {
      unlockAmount = lockingAmount - minLockAmount;
    }

    if (unlockAmount > 0) {
      _projectStaking.unlock(project, unlockAmount);
    }

    _numberOfActiveJobs[project] = remainJob;
  }

  function numberOfActiveJob(address project) external view returns (uint256) {
    return _numberOfActiveJobs[project];
  }

  function appliedJob(uint256 jobId, address kol) external view returns (bool) {
    return _jobAppliedUsers[jobId][kol];
  }

  function jobState(uint256 jobId) external view returns (uint256) {
    return uint256(_jobs[jobId].state);
  }
}