// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Strings.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/math/Math.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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

/*********************************** Imports **********************************/

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC1155/IERC1155.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

contract Marketplace is
    Initializable,
    ReentrancyGuardUpgradeable,
    AccessControlUpgradeable,
    IERC721ReceiverUpgradeable,
    IERC1155ReceiverUpgradeable
{
    /*********************************** Structs **********************************/

    enum TokenType {
        ERC721,
        ERC1155
    }

    struct ContractOptions {
        bool adjustableFee;
        bool listerWhitelist;
        bool nftWhitelist;
        bool paymentWhitelist;
    }

    struct Auction {
        address seller;
        address contractAddress;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        address paymentToken;
        uint256 miniumumPrice;
        uint256 maximumPrice;
        TokenType tokenType;
        uint256 amount;
        bool paymentFulfilled;
        bool nftTransferFulfilled;
    }

    struct Sale {
        //Id?
        address seller;
        address contractAddress;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        address paymentToken;
        uint256 price;
        TokenType tokenType;
        uint256 amount;
        uint256 purchasedAmount;
    }

    struct Bid {
        uint256 auctionId;
        uint256 price;
        address bidder;
    }

    struct CreateAuction {
        //Id?
        address seller;
        address contractAddress;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        address paymentToken;
        uint256 miniumumPrice;
        uint256 maximumPrice;
        TokenType tokenType;
        uint256 amount;
    }

    struct CreateSale {
        address contractAddress;
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        address paymentToken;
        uint256 price;
        TokenType tokenType;
        uint256 amount;
    }

    /********************************** Constants *********************************/

    bytes32 public constant IMPLEMENTATION_TYPE = keccak256('MARKETPLACE');

    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    bytes32 public constant LISTER_ROLE = keccak256('LISTER_ROLE');

    uint256 public constant BPS_DENOM = 10000;

    /************************************ Vars ************************************/

    /// @dev Returns the URI for the metadata of the contract.
    string public contractURI;

    ContractOptions public contractOptions;

    uint256 public totalAuctions;
    uint256 public totalSales;

    mapping(uint256 => Sale) public sales;
    mapping(uint256 => Auction) public auctions;
    mapping(uint256 => Bid) public topBids;

    mapping(address => bool) public nftWhitelist;
    mapping(address => bool) public paymentWhitelist;

    //Fees
    uint256 public listingFee;
    address public feeToken;
    address public listingFeeToken;
    uint256 public fulfillmentFeeBPS;
    address public feeReceiver;

    /*********************************** Events ***********************************/

    /*
     * Emitted when a fee has been changed
     *
     * @param feeReceiver feeReceiver
     * @param listingFeeToken listingFeeToken
     * @param listingFee listingFee
     * @param fulfillmentFee fulfillmentFee
     */
    event FeeChanged(
        address indexed feeReceiver,
        address indexed listingFeeToken,
        uint256 listingFee,
        uint256 fulfillmentFee
    );

    /*
     * Emitted when the nft whitelist has changed
     *
     * @param nftAddresses nftAddresses
     * @param isEnabled isEnabled
     */
    event UpdatedNFTWhitelist(address[] nftAddresses, bool[] isEnabled);

    /*
     * Emitted when the listers has changed
     *
     * @param listers listers
     * @param isEnabled isEnabled
     */
    event UpdatedListerWhitelist(address[] listers, bool[] isEnabled);

    /*
     * Emitted when the payment addresses has changed
     *
     * @param paymentAddresses paymentAddresses
     * @param isEnabled isEnabled
     */
    event UpdatedPaymentWhitelist(address[] paymentAddresses, bool[] isEnabled);

    /*
     * Emitted when a sale is created
     *
     * @param saleId id of the sale
     * @param sale the sale details
     */
    event SaleCreated(uint256 indexed saleId, Sale sale);

    /*
     * Emitted when a sale is modified
     *
     * @param saleId id of the sale
     * @param sale the sale details
     */
    event SaleModified(uint256 indexed saleId, Sale sale);

    /*
     * Emitted when a sale is cancelled
     *
     * @param saleId id of the sale
     * @param sale the sale details
     */
    event SaleCancelled(uint256 indexed saleId, Sale sale);

    /*
     * Emitted when there is a purchasing of a sale
     *
     * @param saleId id of the sale
     * @param sale the sale details
     * @param amount the amount of NFTs bought
     */
    event SalePurchased(uint256 indexed saleId, Sale sale, uint256 amount);

    /*
     * Emitted when a auction is created
     *
     * @param auctionId id of the auction
     * @param auction the auction details
     */
    event AuctionCreated(uint256 indexed auctionId, Auction auction);

    /*
     * Emitted when a auction is modified
     *
     * @param auctionId id of the auction
     * @param auction the auction details
     */
    event AuctionModified(uint256 indexed auctionId, Auction auction);

    /*
     * Emitted when a auction is cancelled
     *
     * @param auctionId id of the auction
     * @param auction the auction details
     */
    event AuctionCancelled(uint256 indexed auctionId, Auction auction);

    /*
     * Emitted when a bid for an auction is created
     *
     * @param auctionId id of the auction
     * @param auction the auction details
     * @param bid the bid details
     */
    event AuctionBid(uint256 indexed auctionId, Auction auction, Bid bid);

    /*
     * Emitted when the nft has been moved from a completed auction
     *
     * @param auctionId id of the auction
     */
    event AuctionNFTFulfilled(uint256 indexed auctionId);

    /*
     * Emitted when the payment has been moved from a completed auction
     *
     * @param auctionId id of the auction
     */
    event AuctionPaymentFulfilled(uint256 indexed auctionId);

    /*********************************** Errors ***********************************/

    /**
     * Field has invalid field
     *
     * @param field the field which is invalid
     */
    error InvalidInitializationField(string field);

    /**
     * Field has invalid field
     *
     * @param field the field which is invalid
     * @param value the value provided
     */
    error InvalidField(string field, uint256 value);

    /**
     * Address has invalid address
     *
     * @param field the field which is invalid
     * @param value the value provided
     */
    error InvalidAddress(string field, address value);

    /**
     * End time is invalid
     *
     * @param value the value provided
     */
    error InvalidEndTime(uint256 value);

    /**
     * InvalidPayment payment is invalid
     *
     */
    error InvalidPayment();

    /**
     * Not enough NFTs
     *
     * @param want amount of tokens trying to purchase
     * @param have amoutn of tokens trying to be purchased
     */
    error NotEnoughNFTs(uint256 want, uint256 have);

    /**
     * NFT address not whitelisted
     */
    error NotWhitelistedNFT();

    /**
     * Payment token address not whitelisted
     */
    error NotWhitelistedPayment();

    /**
     * Not enough native token provided
     */
    error NotEnoughNativeToken();

    /**
     * Catch all for native transfer failing
     *
     * @param recipient recipient of native funds
     * @param amount amount of native funds
     */
    error NativeTransferFailed(address recipient, uint256 amount);

    /**
     * Not sale owner
     *
     * @param saleId id of sale
     * @param sender the value provided
     */
    error NotSaleOwner(uint256 saleId, address sender);

    /**
     * Not auction owner
     *
     * @param auctionId id of auction
     * @param sender the value provided
     */
    error NotAuctionOwner(uint256 auctionId, address sender);

    /**
     * Sale is over
     */
    error SaleOver();

    /**
     * Auction is over
     */
    error AuctionOver();

    /**
     * Auction has already started
     */
    error AuctionStarted();

    /**
     * Auction not finished
     */
    error AuctionNotFinished();

    /**
     * Auction has already been fulfilled
     */
    error AuctionAlreadyFulfilled();

    /**
     * Bid too low
     */
    error BidTooLow();

    /**
     * When the auction is not active.
     *
     * @param currentTimestamp The timestamp at the time of the error
     * @param startTimestamp Timestamp of the start of the auction
     * @param endTimestamp Timestamp of the end of the auction
     */
    error AuctionNotActive(
        uint256 currentTimestamp,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    /**
     * When the sale is not active.
     *
     * @param currentTimestamp The timestamp at the time of the error
     * @param startTimestamp Timestamp of the start of the sale
     * @param endTimestamp Timestamp of the end of the sale
     */
    error SaleNotActive(
        uint256 currentTimestamp,
        uint256 startTimestamp,
        uint256 endTimestamp
    );

    /**
     * Insufficient permissions for caller.
     *
     * @param userAddress user address.
     * @param requiredRole requested amount to transfer.
     */
    error InsufficientPermissions(address userAddress, bytes32 requiredRole);

    /**
     * Option was not initialized on contract creation.
     *
     * @param option the option that was disabled.
     */
    error DisabledOption(string option);

    /********************************* Modifiers **********************************/

    /**
     * @dev Throws InsufficientPermissions if called by any account other than the owner or admins.
     */
    modifier onlyAdmin() {
        if (
            !hasRole(DEFAULT_ADMIN_ROLE, _msgSender()) &&
            !hasRole(ADMIN_ROLE, _msgSender())
        ) {
            revert InsufficientPermissions({
                userAddress: _msgSender(),
                requiredRole: ADMIN_ROLE
            });
        }
        _;
    }

    /**
     * @dev Throws NotSaleOwner if sender is not sale Owner
     */
    modifier isSaleOwner(uint256 _saleId) {
        Sale memory sale = sales[_saleId];

        //Only sale creator
        if (sale.seller != _msgSender()) {
            revert NotSaleOwner(_saleId, _msgSender());
        }
        _;
    }

    /**
     * @dev Throws NotAuctionOwner if sender is not sale Owner
     */
    modifier isAuctionOwner(uint256 _auctionId) {
        Auction memory auction = auctions[_auctionId];

        //Only sale creator
        if (auction.seller != _msgSender()) {
            revert NotAuctionOwner(_auctionId, _msgSender());
        }
        _;
    }

    /**
     * @dev Throws SaleOver if sale is over
     */
    modifier isSaleNotFinished(uint256 _saleId) {
        Sale memory sale = sales[_saleId];

        if (sale.endTime <= block.timestamp) {
            revert SaleOver();
        }
        _;
    }

    /**
     * @dev Throws SaleOver if sale is over
     */
    modifier isAuctionNotFinished(uint256 _auctionId) {
        Auction memory auction = auctions[_auctionId];

        if (auction.endTime <= block.timestamp) {
            revert AuctionOver();
        }
        _;
    }

    /**
     * @dev Throws InsufficientPermissions if called by a non lister
     */
    modifier onlyListers() {
        if (
            contractOptions.listerWhitelist &&
            !hasRole(LISTER_ROLE, _msgSender())
        ) {
            revert InsufficientPermissions({
                userAddress: _msgSender(),
                requiredRole: LISTER_ROLE
            });
        }
        _;
    }

    /**
     * @dev Throws DisabledOption if adjustableFee option was not enabled on contract creation.
     */
    modifier feeAdjustable() {
        if (!contractOptions.adjustableFee) {
            revert DisabledOption({option: 'adjustableFee'});
        }
        _;
    }

    /**
     * @dev Throws DisabledOption if lister whitelist was not enabled on contract creation.
     */
    modifier listerWhitelistEnabled() {
        if (!contractOptions.listerWhitelist) {
            revert DisabledOption({option: 'listerWhitelist'});
        }
        _;
    }

    /**
     * @dev Throws DisabledOption if NFT whitelist was not enabled on contract creation.
     */
    modifier nftWhitelistEnabled() {
        if (!contractOptions.nftWhitelist) {
            revert DisabledOption({option: 'nftWhitelist'});
        }
        _;
    }

    /**
     * @dev Throws DisabledOption if payment whitelist was not enabled on contract creation.
     */
    modifier paymentWhitelistEnabled() {
        if (!contractOptions.paymentWhitelist) {
            revert DisabledOption({option: 'paymentWhitelist'});
        }
        _;
    }

    /******************************** Constructor *********************************/

    constructor() {
        _disableInitializers();
    }

    /********************************* Initialize *********************************/

    /**
     * @dev initializes clones of this contract
     * @param _defaultAdmin owner address
     * @param data encoded data used for initialization
     */
    function initialize(address _defaultAdmin, bytes calldata data)
        external
        initializer
    {
        /**
         *   _contractURI Returns the URI for the storefront-level metadata of the contract.
         *   _feeToken the token in which fees are taken
         *   _listingFee the fee to create a listing
         *   _fulfillmentFee the fee for a completed sale / auction
         *   _feeReceiver address where fees are deposited
         *   _admins admins to be added
         *   _listers addresses permitted to create a listing
         *   _paymentWhitelist addresses that are acceptable as payment
         *   _nftWhitelist address of nfts that are permitted on this marketplace
         *   _contractOptions contractOptions
         */
        (
            string memory _contractURI,
            address _feeToken,
            uint256 _listingFee,
            uint256 _fulfillmentFeeBPS,
            address _feeReceiver,
            address[] memory _admins,
            address[] memory _listers,
            address[] memory _paymentWhitelist,
            address[] memory _nftWhitelist,
            ContractOptions memory _contractOptions
        ) = abi.decode(
                data,
                (
                    string,
                    address,
                    uint256,
                    uint256,
                    address,
                    address[],
                    address[],
                    address[],
                    address[],
                    ContractOptions
                )
            );
        __AccessControl_init();
        __ReentrancyGuard_init();
        contractURI = _contractURI;

        contractOptions = _contractOptions;

        if (
            (_listingFee != 0 || _fulfillmentFeeBPS != 0) &&
            _feeReceiver == address(0)
        ) {
            revert InvalidAddress('feeReceiver', _feeReceiver);
        }
        if (_fulfillmentFeeBPS > BPS_DENOM) {
            revert InvalidField('_fulfillmentFeeBPS', _fulfillmentFeeBPS);
        }

        feeToken = _feeToken;
        listingFee = _listingFee;
        fulfillmentFeeBPS = _fulfillmentFeeBPS;
        feeReceiver = _feeReceiver;

        if (_nftWhitelist.length > 0) {
            if (contractOptions.nftWhitelist) {
                for (uint256 i; i < _nftWhitelist.length; i++) {
                    nftWhitelist[_nftWhitelist[i]] = true;
                }
            } else {
                revert InvalidInitializationField('_nftWhitelist');
            }
        }

        if (_paymentWhitelist.length > 0) {
            if (contractOptions.paymentWhitelist) {
                for (uint256 i; i < _paymentWhitelist.length; i++) {
                    paymentWhitelist[_paymentWhitelist[i]] = true;
                }
            } else {
                revert InvalidInitializationField('_paymentWhitelist');
            }
        }

        _grantRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);

        for (uint256 i; i < _admins.length; i++) {
            _grantRole(ADMIN_ROLE, _admins[i]);
        }

        _setRoleAdmin(LISTER_ROLE, ADMIN_ROLE);
        if (_listers.length > 0) {
            if (contractOptions.listerWhitelist) {
                for (uint256 i; i < _listers.length; i++) {
                    _grantRole(LISTER_ROLE, _listers[i]);
                }
            } else {
                revert InvalidInitializationField('_listers');
            }
        }
    }

    /******************************* Read Functions *******************************/

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

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /******************************* Write Functions ******************************/

    /**
     * @dev Sets the contract metadata uri
     */
    function setContractUri(string calldata _contractURI) external onlyAdmin {
        contractURI = _contractURI;
    }

    // Sales
    function createSale(CreateSale memory _params) external onlyListers {
        uint256 id = ++totalSales;

        validateEndTime(_params.endTime);
        validateContractAddress(_params.contractAddress);
        validatePaymentToken(_params.paymentToken);
        transferListingFee();

        transferNFT(
            _params.tokenType,
            _msgSender(),
            address(this),
            _params.contractAddress,
            _params.tokenId,
            _params.amount
        );

        Sale memory newSale = Sale({
            seller: _msgSender(),
            contractAddress: _params.contractAddress,
            tokenId: _params.tokenId,
            startTime: _params.startTime,
            endTime: _params.endTime,
            paymentToken: _params.paymentToken,
            price: _params.price,
            tokenType: _params.tokenType,
            amount: _params.amount,
            purchasedAmount: 0
        });
        sales[id] = newSale;

        emit SaleCreated(id, newSale);
    }

    function editSale(
        uint256 _saleId,
        uint256 _startTime,
        uint256 _endTime,
        address _paymentToken,
        uint256 _price,
        uint256 _amount
    ) external nonReentrant isSaleOwner(_saleId) isSaleNotFinished(_saleId) {
        validateEndTime(_endTime);
        validatePaymentToken(_paymentToken);

        Sale memory sale = sales[_saleId];

        //Cannot change startTime after sale has started
        if (sale.startTime > block.timestamp) {
            _startTime = sale.startTime;
        }

        //Transfer Nfts based on amount change
        if (sale.amount < _amount) {
            transferNFT(
                sale.tokenType,
                _msgSender(),
                address(this),
                sale.contractAddress,
                sale.tokenId,
                _amount - sale.amount
            );
        } else if (sale.amount > _amount) {
            if (_amount > sale.purchasedAmount) {
                revert InvalidField('amount', _amount);
            }
            transferNFT(
                sale.tokenType,
                address(this),
                _msgSender(),
                sale.contractAddress,
                sale.tokenId,
                sale.amount - _amount
            );
        }

        sales[_saleId] = Sale({
            seller: _msgSender(),
            contractAddress: sale.contractAddress,
            tokenId: sale.tokenId,
            startTime: _startTime,
            endTime: _endTime,
            paymentToken: _paymentToken,
            price: _price,
            tokenType: sale.tokenType,
            amount: _amount,
            purchasedAmount: sale.purchasedAmount
        });
        emit SaleModified(_saleId, sales[_saleId]);
    }

    function cancelSale(uint256 _saleId)
        external
        isSaleOwner(_saleId)
        isSaleNotFinished(_saleId)
    {
        sales[_saleId].endTime = block.timestamp;
        emit SaleCancelled(_saleId, sales[_saleId]);
    }

    function buy(
        uint256 _saleId,
        uint256 purchaseAmount,
        address paymentToken,
        uint256 paymentAmount
    ) external payable isSaleNotFinished(_saleId) {
        Sale memory sale = sales[_saleId];

        uint256 remainingNFTs = sale.amount - sale.purchasedAmount;
        if (purchaseAmount > remainingNFTs) {
            revert NotEnoughNFTs(purchaseAmount, remainingNFTs);
        }

        uint256 totalPayment = sale.price * purchaseAmount;
        if (
            paymentToken != sale.paymentToken || paymentAmount != totalPayment
        ) {
            revert InvalidPayment();
        }

        if (paymentToken == address(0) && msg.value < totalPayment) {
            revert NotEnoughNativeToken();
        }

        (uint256 transferValue, uint256 fee) = calculateFulfillmentFee(
            totalPayment
        );

        sales[_saleId].purchasedAmount += purchaseAmount;

        transferPayment(paymentToken, _msgSender(), feeReceiver, fee);
        transferPayment(paymentToken, _msgSender(), sale.seller, transferValue);

        transferNFT(
            sale.tokenType,
            address(this),
            _msgSender(),
            sale.contractAddress,
            sale.tokenId,
            purchaseAmount
        );

        emit SalePurchased(_saleId, sales[_saleId], purchaseAmount);
    }

    //Auctions
    function createAuction(CreateAuction memory _params) external onlyListers {
        uint256 id = ++totalAuctions;

        validateEndTime(_params.endTime);
        validateContractAddress(_params.contractAddress);
        validatePaymentToken(_params.paymentToken);
        transferListingFee();

        transferNFT(
            _params.tokenType,
            _msgSender(),
            address(this),
            _params.contractAddress,
            _params.tokenId,
            _params.amount
        );

        Auction memory newAuction = Auction({
            seller: _msgSender(),
            contractAddress: _params.contractAddress,
            tokenId: _params.tokenId,
            startTime: _params.startTime,
            endTime: _params.endTime,
            paymentToken: _params.paymentToken,
            miniumumPrice: _params.miniumumPrice,
            maximumPrice: _params.maximumPrice,
            tokenType: _params.tokenType,
            amount: _params.amount,
            paymentFulfilled: false,
            nftTransferFulfilled: false
        });
        auctions[id] = newAuction;

        emit AuctionCreated(id, newAuction);
    }

    function editAuction(
        uint256 _auctionId,
        uint256 _startTime,
        uint256 _endTime,
        address _paymentToken,
        uint256 _minimumPrice,
        uint256 _maximumPrice,
        uint256 _amount
    )
        external
        nonReentrant
        isAuctionOwner(_auctionId)
        isAuctionNotFinished(_auctionId)
    {
        Auction memory auction = auctions[_auctionId];

        //Auction not started
        if (auction.startTime < block.timestamp) {
            revert AuctionStarted();
        }

        //End time doesn't cancel the auction
        validateEndTime(_endTime);
        validatePaymentToken(_paymentToken);

        //Cannot change startTime after auction has started
        if (auction.startTime > block.timestamp) {
            _startTime = auction.startTime;
        }

        //Transfer Nfts based on amount change
        if (auction.amount < _amount) {
            transferNFT(
                auction.tokenType,
                _msgSender(),
                address(this),
                auction.contractAddress,
                auction.tokenId,
                _amount - auction.amount
            );
        } else if (auction.amount > _amount) {
            transferNFT(
                auction.tokenType,
                address(this),
                _msgSender(),
                auction.contractAddress,
                auction.tokenId,
                auction.amount - _amount
            );
        }

        auctions[_auctionId] = Auction({
            seller: _msgSender(),
            contractAddress: auction.contractAddress,
            tokenId: auction.tokenId,
            startTime: _startTime,
            endTime: _endTime,
            paymentToken: _paymentToken,
            miniumumPrice: _minimumPrice,
            maximumPrice: _maximumPrice,
            tokenType: auction.tokenType,
            amount: _amount,
            paymentFulfilled: auction.paymentFulfilled,
            nftTransferFulfilled: auction.nftTransferFulfilled
        });

        emit AuctionModified(_auctionId, auctions[_auctionId]);
    }

    function cancelAuction(uint256 _auctionId)
        external
        isSaleOwner(_auctionId)
        isSaleNotFinished(_auctionId)
    {
        Auction memory auction = auctions[_auctionId];
        //Auction not started
        if (auction.startTime < block.timestamp) {
            revert AuctionStarted();
        }

        auctions[_auctionId].endTime = block.timestamp;
        emit AuctionCancelled(_auctionId, auctions[_auctionId]);
    }

    function bid(uint256 _auctionId, uint256 _price) payable external {
        Auction memory auction = auctions[_auctionId];

        //Auction not started
        if (
            block.timestamp < auction.startTime ||
            block.timestamp > auction.endTime
        ) {
            revert AuctionNotActive(
                block.timestamp,
                auction.startTime,
                auction.endTime
            );
        }

        Bid memory prevTopBid = topBids[_auctionId];

        if (prevTopBid.price >= _price) {
            revert BidTooLow();
        }

        Bid memory newBid = Bid({
            auctionId: _auctionId,
            price: _price,
            bidder: _msgSender()
        });
        topBids[_auctionId] = newBid;

        //Hold payment from new top bid
        transferPayment(
            auction.paymentToken,
            _msgSender(),
            address(this),
            _price
        );

        //Refund old Bidder
        transferPayment(
            auction.paymentToken,
            address(this),
            prevTopBid.bidder,
            prevTopBid.price
        );

        emit AuctionBid(_auctionId, auctions[_auctionId], newBid);
    }

    function claimAuctionNFT(uint256 _auctionId) external {
        Auction memory auction = auctions[_auctionId];
        Bid memory topBid = topBids[_auctionId];

        //Auction not started
        if (block.timestamp < auction.endTime) {
            revert AuctionNotFinished();
        }
        if (auction.nftTransferFulfilled) {
            revert AuctionAlreadyFulfilled();
        }
        auctions[_auctionId].nftTransferFulfilled = true;

        address transferToAddress = topBid.bidder;
        //If there are no bidders, return the nft to owner
        if (transferToAddress == address(0)) {
            auctions[_auctionId].paymentFulfilled = true;
            transferToAddress = auction.seller;
        }

        transferNFT(
            auction.tokenType,
            address(this),
            transferToAddress,
            auction.contractAddress,
            auction.tokenId,
            auction.amount
        );

        emit AuctionNFTFulfilled(_auctionId);
    }

    function claimAuctionPayment(uint256 _auctionId) external {
        Auction memory auction = auctions[_auctionId];
        Bid memory topBid = topBids[_auctionId];

        //Auction not started
        if (block.timestamp < auction.endTime) {
            revert AuctionNotFinished();
        }
        if (auction.paymentFulfilled) {
            revert AuctionAlreadyFulfilled();
        }
        auctions[_auctionId].paymentFulfilled = true;

        (uint256 transferValue, uint256 fee) = calculateFulfillmentFee(
            topBid.price
        );

        transferPayment(auction.paymentToken, address(this), feeReceiver, fee);
        transferPayment(
            auction.paymentToken,
            address(this),
            auction.seller,
            transferValue
        );

        emit AuctionPaymentFulfilled(_auctionId);
    }

    // Admin Functions
    function updateFees(
        address _feeReceiver,
        address _listingFeeToken,
        uint256 _listingFee,
        uint256 _fulfillmentFeeBPS
    ) external onlyAdmin feeAdjustable {
        if (
            (_listingFee != 0 || _fulfillmentFeeBPS != 0) &&
            _feeReceiver == address(0)
        ) {
            revert InvalidAddress('feeReceiver', _feeReceiver);
        }
        if (_fulfillmentFeeBPS > BPS_DENOM) {
            revert InvalidField('fulfillmentFee', _fulfillmentFeeBPS);
        }

        feeReceiver = _feeReceiver;
        listingFeeToken = _listingFeeToken;
        listingFee = _listingFee;
        fulfillmentFeeBPS = _fulfillmentFeeBPS;

        emit FeeChanged(
            feeReceiver,
            listingFeeToken,
            listingFee,
            fulfillmentFeeBPS
        );
    }

    function updateListerWhitelist(
        address[] calldata _listers,
        bool[] calldata _isEnabled
    ) external onlyAdmin listerWhitelistEnabled {
        for (uint256 i; i < _listers.length; i++) {
            if (_isEnabled[i]) {
                _grantRole(LISTER_ROLE, _listers[i]);
            } else {
                _revokeRole(LISTER_ROLE, _listers[i]);
            }
        }
        emit UpdatedListerWhitelist(_listers, _isEnabled);
    }

    function updateNFTWhitelist(
        address[] calldata _nftAddresses,
        bool[] calldata _isEnabled
    ) external onlyAdmin nftWhitelistEnabled {
        for (uint256 i; i < _nftAddresses.length; i++) {
            nftWhitelist[_nftAddresses[i]] = _isEnabled[i];
        }
        emit UpdatedNFTWhitelist(_nftAddresses, _isEnabled);
    }

    function updatePaymentWhitelist(
        address[] calldata _paymentAddresses,
        bool[] calldata _isEnabled
    ) external onlyAdmin paymentWhitelistEnabled {
        for (uint256 i; i < _paymentAddresses.length; i++) {
            paymentWhitelist[_paymentAddresses[i]] = _isEnabled[i];
        }
        emit UpdatedPaymentWhitelist(_paymentAddresses, _isEnabled);
    }

    /***************************** Internal Functions *****************************/

    function validateEndTime(uint256 endTime) internal view {
        if (endTime < block.timestamp) {
            revert InvalidEndTime(endTime);
        }
    }

    function validateContractAddress(address contractAddress) internal view {
        if (!contractOptions.nftWhitelist) {
            return;
        }
        if (nftWhitelist[contractAddress]) {
            return;
        }
        revert NotWhitelistedNFT();
    }

    function validatePaymentToken(address paymentToken) internal view {
        if (!contractOptions.paymentWhitelist) {
            return;
        }
        if (paymentWhitelist[paymentToken]) {
            return;
        }
        revert NotWhitelistedPayment();
    }

    function transferListingFee() internal {
        if (listingFee == 0) {
            return;
        }
        if (feeToken == address(0)) {
            if (msg.value < listingFee) {
                revert NotEnoughNativeToken();
            }
            (bool success, ) = feeReceiver.call{value: listingFee}('');
            if (!success) {
                revert NativeTransferFailed({
                    recipient: feeReceiver,
                    amount: listingFee
                });
            }
        } else {
            IERC20(feeToken).transferFrom(
                _msgSender(),
                feeReceiver,
                listingFee
            );
        }
    }

    function transferNFT(
        TokenType tokenType,
        address from,
        address to,
        address contractAddress,
        uint256 tokenId,
        uint256 amount
    ) internal {
        if (amount == 0) {
            revert InvalidField('amount', amount);
        }
        if (tokenType == TokenType.ERC721) {
            if (amount != 1) {
                revert InvalidField('amount', amount);
            }
            IERC721(contractAddress).safeTransferFrom(from, to, tokenId);
        } else {
            IERC1155(contractAddress).safeTransferFrom(
                from,
                to,
                tokenId,
                amount,
                ''
            );
        }
    }

    function transferPayment(
        address tokenAddress,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (tokenAddress == address(0)) {
            if (from != address(this) && from != _msgSender()) {
                revert InvalidAddress('from', from);
            }
            if (_msgSender() == from) {
                if (msg.value < amount) {
                    revert NotEnoughNativeToken();
                }
            }
            (bool success, ) = to.call{value: amount}('');
            if (!success) {
                revert NativeTransferFailed({recipient: to, amount: amount});
            }
        } else {
            IERC20(tokenAddress).transferFrom(from, to, amount);
        }
    }

    function calculateFulfillmentFee(uint256 amount)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 fee = (amount * fulfillmentFeeBPS) / BPS_DENOM;
        return (amount - fee, fee);
    }
}