// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
     * This empty reserved space is put in place to allow future versions to add new
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
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
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

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
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
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
     * This empty reserved space is put in place to allow future versions to add new
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-4.5.0-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-4.5.0-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-4.5.0-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-4.5.0-upgradeable/utils/math/MathUpgradeable.sol";

import "./libraries/EnumerableQueueUpgradeable.sol";
import "./interfaces/IRateLimiter.sol";

import {StringsUpgradeable} from "@openzeppelin/contracts-4.5.0-upgradeable/utils/StringsUpgradeable.sol";

// solhint-disable not-rely-on-time

interface IBridge {
    function kappaExists(bytes32 kappa) external view returns (bool);
}

// @title RateLimiter
// @dev a bridge asset rate limiter based on https://github.com/gnosis/safe-modules/blob/master/allowances/contracts/AlowanceModule.sol
contract RateLimiter is
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    IRateLimiter
{
    using EnumerableQueueUpgradeable for EnumerableQueueUpgradeable.KappaQueue;
    /*** STATE ***/

    string public constant NAME = "Rate Limiter";
    string public constant VERSION = "0.1.0";

    // roles
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant LIMITER_ROLE = keccak256("LIMITER_ROLE");
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");

    // Token -> Allowance
    mapping(address => Allowance) public allowances;
    // Kappa->Retry Selector
    EnumerableQueueUpgradeable.KappaQueue private rateLimitedQueue;
    mapping(bytes32 => bytes) private failedRetries;
    // Bridge Address
    address public BRIDGE_ADDRESS;
    // Time period after anyone can retry a rate limited tx
    uint32 public retryTimeout;
    uint32 public constant MIN_RETRY_TIMEOUT = 10;

    // List of tokens
    address[] public tokens;

    /*** EVENTS ***/

    event SetAllowance(
        address indexed token,
        uint96 allowanceAmount,
        uint16 resetTime
    );
    event ResetAllowance(address indexed token);

    /*** STRUCTS ***/

    // The allowance info is optimized to fit into one word of storage.
    struct Allowance {
        uint96 amount;
        uint96 spent;
        uint16 resetTimeMin; // Maximum reset time span is 65k minutes
        uint32 lastResetMin; // epoch/60
        bool initialized;
    }

    /*** FUNCTIONS ***/

    function initialize() external initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        __AccessControl_init();
        retryTimeout = MIN_RETRY_TIMEOUT;
    }

    /*** VIEWS ***/

    function getTokenAllowance(address token)
        external
        view
        returns (uint256[4] memory)
    {
        Allowance memory allowance = _getAllowance(token);
        return [
            uint256(allowance.amount),
            uint256(allowance.spent),
            uint256(allowance.resetTimeMin),
            uint256(allowance.lastResetMin)
        ];
    }

    /**
     * @notice Gets a  list of tokens with allowances
     **/
    function getTokens() external view returns (address[] memory) {
        return tokens;
    }

    function retryQueueLength() external view returns (uint256 length) {
        length = rateLimitedQueue.length();
    }

    /*** RESTRICTED: GOVERNANCE ***/

    function setBridgeAddress(address bridge)
        external
        onlyRole(GOVERNANCE_ROLE)
    {
        BRIDGE_ADDRESS = bridge;
    }

    function setRetryTimeout(uint32 _retryTimeout)
        external
        onlyRole(GOVERNANCE_ROLE)
    {
        require(_retryTimeout >= MIN_RETRY_TIMEOUT, "Timeout too short");
        retryTimeout = _retryTimeout;
    }

    /*** RESTRICTED: LIMITER ***/

    function deleteByKappa(bytes32 kappa) external onlyRole(LIMITER_ROLE) {
        rateLimitedQueue.deleteKey(kappa);
    }

    function resetAllowance(address token) external onlyRole(LIMITER_ROLE) {
        Allowance memory allowance = _getAllowance(token);
        allowance.spent = 0;
        _updateAllowance(token, allowance);
        emit ResetAllowance(token);
    }

    /**
     * @notice Updates the allowance for a given token
     * @param token to update the allowance for
     * @param allowanceAmount for the token
     * @param resetTimeMin minimum reset time (amount goes to 0 after this)
     * @param resetBaseMin amount Amount in native token decimals to transfer cross-chain pre-fees
     **/
    function setAllowance(
        address token,
        uint96 allowanceAmount,
        uint16 resetTimeMin,
        uint32 resetBaseMin
    ) external onlyRole(LIMITER_ROLE) {
        Allowance memory allowance = _getAllowance(token);
        if (!allowance.initialized) {
            // New token
            allowance.initialized = true;
            tokens.push(token);
        }
        // Divide by 60 to get current time in minutes
        // solium-disable-next-line security/no-block-members
        uint32 currentMin = uint32(block.timestamp / 60);
        if (resetBaseMin > 0) {
            require(resetBaseMin <= currentMin, "resetBaseMin <= currentMin");
            allowance.lastResetMin =
                currentMin -
                ((currentMin - resetBaseMin) % resetTimeMin);
        } else if (allowance.lastResetMin == 0) {
            allowance.lastResetMin = currentMin;
        }
        allowance.resetTimeMin = resetTimeMin;
        allowance.amount = allowanceAmount;
        _updateAllowance(token, allowance);
        emit SetAllowance(token, allowanceAmount, resetTimeMin);
    }

    /*** RESTRICTED: BRIDGE ***/

    function addToRetryQueue(bytes32 kappa, bytes memory toRetry)
        external
        onlyRole(BRIDGE_ROLE)
    {
        rateLimitedQueue.add(kappa, toRetry);
    }

    /**
     * @notice Checks the allowance for a given token. If the new amount exceeds the allowance, it is not updated and false is returned
     * otherwise true is returned and the transaction can proceed
     * @param amount to transfer
     **/
    function checkAndUpdateAllowance(address token, uint256 amount)
        external
        nonReentrant
        onlyRole(BRIDGE_ROLE)
        returns (bool)
    {
        Allowance memory allowance = _getAllowance(token);

        // Update state
        // @dev reverts if amount > (2^96 - 1)
        uint96 newSpent = allowance.spent + uint96(amount);

        // do not proceed. Store the transaction for later
        if (newSpent > allowance.amount) {
            return false;
        }

        allowance.spent = newSpent;
        _updateAllowance(token, allowance);

        return true;
    }

    /*** INTERNAL: ALLOWANCE ***/

    function _getAllowance(address token)
        internal
        view
        returns (Allowance memory allowance)
    {
        allowance = allowances[token];
        // solium-disable-next-line security/no-block-members
        uint32 currentMin = uint32(block.timestamp / 60);
        // Check if we should reset the time. We do this on load to minimize storage read/ writes
        if (
            allowance.resetTimeMin > 0 &&
            allowance.lastResetMin <= currentMin - allowance.resetTimeMin
        ) {
            allowance.spent = 0;
            // Resets happen in regular intervals and `lastResetMin` should be aligned to that
            allowance.lastResetMin =
                currentMin -
                ((currentMin - allowance.lastResetMin) %
                    allowance.resetTimeMin);
        }
        return allowance;
    }

    function _updateAllowance(address token, Allowance memory allowance)
        internal
    {
        allowances[token] = allowance;
    }

    /*** RETRY FUNCTIONS ***/

    function retryByKappa(bytes32 kappa) external {
        (bytes memory toRetry, uint32 storedAtMin) = rateLimitedQueue.get(
            kappa
        );
        if (toRetry.length > 0) {
            if (!hasRole(LIMITER_ROLE, msg.sender)) {
                // Permissionless retry is only available once timeout is finished
                uint32 currentMin = uint32(block.timestamp / 60);
                require(
                    currentMin >= storedAtMin + retryTimeout,
                    "Retry timeout not finished"
                );
            }
            rateLimitedQueue.deleteKey(kappa);
            _retry(kappa, toRetry);
        } else {
            // Try looking up in the failed txs:
            // anyone should be able to do so, with no timeout
            _retryFailed(kappa);
        }
    }

    function retryCount(uint8 count) external onlyRole(LIMITER_ROLE) {
        // no issues casting to uint8 here. If length is greater then 255, min is always taken
        uint8 attempts = uint8(
            MathUpgradeable.min(uint256(count), rateLimitedQueue.length())
        );

        for (uint8 i = 0; i < attempts; i++) {
            // check out the first element
            (bytes32 kappa, bytes memory toRetry, ) = rateLimitedQueue
            .pop_front();

            if (toRetry.length > 0) {
                _retry(kappa, toRetry);
            }
        }
    }

    function _retry(bytes32 kappa, bytes memory toRetry) internal {
        (bool success, ) = BRIDGE_ADDRESS.call(toRetry);
        if (!success && !IBridge(BRIDGE_ADDRESS).kappaExists(kappa)) {
            // save payload for failed transactions
            // that haven't been processed by Bridge yet
            failedRetries[kappa] = toRetry;
        }
    }

    function _retryFailed(bytes32 kappa) internal {
        bytes memory toRetry = failedRetries[kappa];
        if (toRetry.length > 0) {
            failedRetries[kappa] = bytes("");
            (bool success, bytes memory returnData) = BRIDGE_ADDRESS.call(
                toRetry
            );
            require(
                success,
                string(
                    abi.encodePacked(
                        "Could not call bridge for kappa: ",
                        StringsUpgradeable.toHexString(uint256(kappa), 32),
                        " reverted with: ",
                        _getRevertMsg(returnData)
                    )
                )
            );
        }
    }

    function _getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.23 <0.9.0;

interface IRateLimiter {
    function addToRetryQueue(bytes32 kappa, bytes memory rateLimited) external;
    function checkAndUpdateAllowance(address token, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library EnumerableQueueUpgradeable {
    struct RetryableTx {
        /// @dev epoch time in minutes the tx was stored at. Always non-zero on initialized struct
        uint32 storedAtMin;
        /// @dev bridge calldata for retrying
        bytes toRetry;
    }

    /**
     * @dev New elements are added to the tail of queue:
     *
     *                H=T=0
     *                  v
     * Initial state: EMPTY [head (H) = 0, tail(T) = 0]
     *
     *          H    T
     * add(1): [1]
     *
     *          H         T
     * add(2): [1]<>[2]
     *
     *          H              T
     * add(3): [1]<>[2]<>[3]
     */

    /**
     * @dev Getting arbitrary elements is supported, but not their deletion:
     * Initial state: [1]<>[2]<>[3]
     *  get(key=2) -> [2]: gets data for a given key
     * at(index=0) -> [1]: gets data for a given queue index (queue head index is always 0)
     */

    /**
     * @dev Elements are polled from the head of queue:
     *           H              T
     * State  : [1]<>[2]<>[3]
     *
     *                H         T
     * poll() :      [2]<>[3]
     *
     *                     H    T
     * poll() :           [3]
     */

    struct KappaQueue {
        /// @dev Array of keys for data. Every existing key is unique.
        /// Can't add the same key twice, but it's possible
        /// to add the key again once it is deleted from the Queue.
        mapping(uint256 => bytes32) _keys;
        /// @dev Data map for each key.
        mapping(bytes32 => RetryableTx) _data;
        /// @dev Index of the first Queue key.
        uint128 _head;
        /// @dev Index following the last Queue key, i.e.
        /// index, where newly added key would reside.
        /// _head == _tail => Queue is empty
        uint128 _tail;
    }

    /**
     * @notice Adds [key, value] pair to the `queue`. Will not to anything, if
     * a key already exists in the `queue`.
     *
     * Returns true only if [key, value] was added to the Queue.
     */
    function add(
        KappaQueue storage queue,
        bytes32 key,
        bytes memory value
    ) internal returns (bool) {
        if (contains(queue, key)) {
            // key already exists, don't add anything
            return false;
        }

        queue._keys[queue._tail] = key;
        queue._data[key] = RetryableTx({
            storedAtMin: uint32(block.timestamp / 60),
            toRetry: value
        });

        ++queue._tail;

        return true;
    }

    /**
     * @notice Returns data for N-th element of the Queue:
     * key, value and the time it was stored.
     * @dev All return variables will be zero, if `index >= queue.length()`.
     * `value` will be zero, if `deleteKey(key)` was called previously.
     */
    function at(KappaQueue storage queue, uint256 index)
        internal
        view
        returns (
            bytes32 key,
            bytes memory value,
            uint32 storedAtMin
        )
    {
        key = queue._keys[queue._head + index];
        (value, storedAtMin) = get(queue, key);
    }

    /**
     * @notice Checks whether `key` is present in the Queue.
     */
    function contains(KappaQueue storage queue, bytes32 key)
        internal
        view
        returns (bool)
    {
        return queue._data[key].storedAtMin != 0;
    }

    /**
     * @notice Delete key from the Queue.
     * @dev For gas efficiency we don't use the double-linked queue implementation,
     * allowing to remove an arbitrary element. All we're doing is setting
     * the stored value for the given key to zero.
     * It means, that one should check value obtained by `get(key)` before using it.
     */
    function deleteKey(KappaQueue storage queue, bytes32 key) internal {
        queue._data[key].toRetry = bytes("");
    }

    /**
     * @notice Checks whether Queue is empty.
     */
    function isEmpty(KappaQueue storage queue) internal view returns (bool) {
        return queue._head == queue._tail;
    }

    /**
     * @notice Gets data associated with the given `key`: value and the time it was stored.
     * @dev All return variables will be zero, if `key` is not added to the Queue.
     * `value` will be zero, if `deleteKey(key)` was called previously.
     */
    function get(KappaQueue storage queue, bytes32 key)
        internal
        view
        returns (bytes memory value, uint32 storedAtMin)
    {
        (value, storedAtMin) = (
            queue._data[key].toRetry,
            queue._data[key].storedAtMin
        );
    }

    /**
     * @notice Returns the number of elements in the Queue.
     */
    function length(KappaQueue storage queue) internal view returns (uint256) {
        // This never underflows
        return queue._tail - queue._head;
    }

    /**
     * @notice Returns data for the first (head) element from
     * the Queue, without removing it.
     * Data: key, value and the time it was stored.
     * @dev All return variables will be zero, Queue is empty.
     * `value` will be zero, if `deleteKey(key)` was called previously.
     */
    function peek(KappaQueue storage queue)
        internal
        view
        returns (
            bytes32 key,
            bytes memory value,
            uint32 storedAtMin
        )
    {
        key = queue._keys[queue._head];
        (value, storedAtMin) = get(queue, key);
    }

    /**
     * @notice Returns data for the first (head) element from
     * the Queue and removes the element from Queue.
     * Data: key, value and the time it was stored.
     * @dev All return variables will be zero, Queue is empty.
     * `value` will be zero, if `deleteKey(key)` was called previously.
     */
    function pop_front(KappaQueue storage queue)
        internal
        returns (
            bytes32 key,
            bytes memory value,
            uint32 storedAtMin
        )
    {
        (uint256 head, uint256 tail) = (queue._head, queue._tail);
        if (head != tail) {
            key = queue._keys[head];
            (value, storedAtMin) = get(queue, key);

            delete queue._keys[head];
            delete queue._data[key];

            ++head;
            if (head == tail) {
                (queue._head, queue._tail) = (0, 0);
            } else {
                queue._head = uint128(head);
            }
        }
    }
}