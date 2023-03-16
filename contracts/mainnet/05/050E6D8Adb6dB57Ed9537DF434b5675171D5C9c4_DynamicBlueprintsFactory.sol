// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerableUpgradeable.sol";
import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

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
            "ERC1155: caller is not token owner or approved"
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
            "ERC1155: caller is not token owner or approved"
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
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155SupplyUpgradeable is Initializable, ERC1155Upgradeable {
    function __ERC1155Supply_init() internal onlyInitializing {
    }

    function __ERC1155Supply_init_unchained() internal onlyInitializing {
    }
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155SupplyUpgradeable.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
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

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

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
        address owner = _ownerOf(tokenId);
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
            "ERC721: approve caller is not token owner or approved for all"
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
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
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
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
        return _ownerOf(tokenId) != address(0);
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

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721Upgradeable.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
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
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165StorageUpgradeable is Initializable, ERC165Upgradeable {
    function __ERC165Storage_init() internal onlyInitializing {
    }

    function __ERC165Storage_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../../access/Ownable.sol";
import "../../utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon, Ownable {
    address private _implementation;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual onlyOwner {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/transparent/TransparentUpgradeableProxy.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967Proxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is ERC1967Proxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {ERC1967Proxy-constructor}.
     */
    constructor(
        address _logic,
        address admin_,
        bytes memory _data
    ) payable ERC1967Proxy(_logic, _data) {
        _changeAdmin(admin_);
    }

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _getAdmin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        _changeAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external ifAdmin {
        _upgradeToAndCall(newImplementation, bytes(""), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable ifAdmin {
        _upgradeToAndCall(newImplementation, data, true);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _getAdmin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165StorageUpgradeable.sol";

abstract contract HasSecondarySaleFees is ERC165StorageUpgradeable {
    /*
     * bytes4(keccak256('getFeeBps(uint256)')) == 0x0ebd4c7f
     * bytes4(keccak256('getFeeRecipients(uint256)')) == 0xb9c4d9fb
     *
     * => 0x0ebd4c7f ^ 0xb9c4d9fb == 0xb7799584
     */
    bytes4 private constant _INTERFACE_ID_FEES = 0xb7799584;

    event SecondarySaleFees(uint256 tokenId, address[] recipients, uint256[] bps);

    function getFeeRecipients(uint256 id) external view virtual returns (address[] memory);

    function getFeeBps(uint256 id) external view virtual returns (uint32[] memory);

    function _initialize() internal initializer {
        _registerInterface(_INTERFACE_ID_FEES);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../abstract/HasSecondarySaleFees.sol";
import "../common/IRoyalty.sol";
import "../common/IOperatorFilterer.sol";
import "../common/Royalty.sol";
import "./interfaces/IDynamicBlueprint.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IOperatorFilterRegistry } from "../operatorFilter/IOperatorFilterRegistry.sol";

/**
 * @notice Async Art Dynamic Blueprint NFT contract with true creator provenance
 * @author Async Art, Ohimire Labs
 */
contract DynamicBlueprint is
    ERC721Upgradeable,
    HasSecondarySaleFees,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuard,
    Royalty,
    IDynamicBlueprint
{
    using StringsUpgradeable for uint256;

    /**
     * @notice First token ID of the next Blueprint to be minted
     */
    uint64 public latestErc721TokenIndex;

    /**
     * @notice Account representing platform
     */
    address public platform;

    /**
     * @notice Account able to perform actions restricted to MINTER_ROLE holder
     */
    address public minterAddress;

    /**
     * @notice Blueprint artist
     */
    address public artist;

    /**
     * @notice Blueprint, core object of contract
     */
    Blueprint public blueprint;

    /**
     * @notice Token Ids to custom, per-token, overriding token URIs
     */
    mapping(uint256 => DynamicBlueprintTokenURI) public tokenIdsToURI;

    /**
     * @notice Contract-level metadata
     */
    string public contractURI;

    /**
     * @notice Broadcast contract
     */
    address public broadcast;

    /**
     * @notice Holders of this role are given minter privileges
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @notice Holders of this role are given storefront minter privileges
     */
    bytes32 public constant STOREFRONT_MINTER_ROLE = keccak256("STOREFRONT_MINTER_ROLE");

    /**
     * @notice A registry to check for blacklisted operator addresses.
     *      Used to only permit marketplaces enforcing creator royalites if desired
     */
    IOperatorFilterRegistry public operatorFilterRegistry;

    /**
     * @notice Royalty config
     */
    Royalty private _royalty;

    /**
     * @notice Emitted when NFTs of blueprint are minted
     * @param tokenId NFT minted
     * @param newMintedCount New amount of tokens minted
     * @param recipient Recipent of minted NFTs
     */
    event BlueprintMinted(uint128 indexed tokenId, uint64 newMintedCount, address recipient);

    /**
     * @notice Emitted when blueprint is prepared
     * @param artist Blueprint artist
     * @param capacity Number of NFTs in blueprint
     * @param blueprintMetaData Blueprint metadata uri
     * @param baseTokenUri Blueprint's base token uri.
     *                     Token uris are a result of the base uri concatenated with token id (unless overriden)
     */
    event BlueprintPrepared(address indexed artist, uint64 capacity, string blueprintMetaData, string baseTokenUri);

    /**
     * @notice Emitted when blueprint token uri is updated
     * @param newBaseTokenUri New base uri
     */
    event BlueprintTokenUriUpdated(string newBaseTokenUri);

    /**
     * @notice Checks if blueprint is prepared
     */
    modifier isBlueprintPrepared() {
        require(blueprint.prepared, "!prepared");
        _;
    }

    /**
     * @notice Check if token is not soulbound. Revert if it is
     * @param tokenId ID of token being checked
     */
    modifier isNotSoulbound(uint256 tokenId) {
        require(!blueprint.isSoulbound, "is soulbound");
        _;
    }

    /////////////////////////////////////////////////
    /// Required for CORI Operator Registry //////
    /////////////////////////////////////////////////

    // Custom Error Type For Operator Registry Methods
    error OperatorNotAllowed(address operator);

    /**
     * @notice Restrict operators who are allowed to transfer these tokens
     * @param from Account that token is being transferred out of
     */
    modifier onlyAllowedOperator(address from) {
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @notice Restrict operators who are allowed to approve transfer delegates
     * @param operator Operator that is attempting to move tokens
     */
    modifier onlyAllowedOperatorApproval(address operator) {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @notice Initialize the instance
     * @param dynamicBlueprintsInput Core parameters for contract initialization
     * @param _platform Platform admin account
     * @param _minter Minter admin account
     * @param _royaltyParameters Initial royalty settings
     * @param storefrontMinters Addresses to be given STOREFRONT_MINTER_ROLE
     * @param _broadcast Broadcast contract that intents are emitted from
     * @param operatorFiltererInputs OpenSea operator filterer addresses
     */
    function initialize(
        DynamicBlueprintsInput calldata dynamicBlueprintsInput,
        address _platform,
        address _minter,
        Royalty calldata _royaltyParameters,
        address[] calldata storefrontMinters,
        address _broadcast,
        IOperatorFilterer.OperatorFiltererInputs calldata operatorFiltererInputs
    ) external initializer royaltyValid(_royaltyParameters) {
        // Intialize parent contracts
        ERC721Upgradeable.__ERC721_init(dynamicBlueprintsInput.name, dynamicBlueprintsInput.symbol);
        HasSecondarySaleFees._initialize();
        AccessControlUpgradeable.__AccessControl_init();

        _setupRole(DEFAULT_ADMIN_ROLE, _platform);
        _setupRole(MINTER_ROLE, _minter);

        for (uint256 i = 0; i < storefrontMinters.length; i++) {
            _setupRole(STOREFRONT_MINTER_ROLE, storefrontMinters[i]);
        }

        platform = _platform;
        minterAddress = _minter;
        artist = dynamicBlueprintsInput.artist;

        contractURI = dynamicBlueprintsInput.contractURI;
        _royalty = _royaltyParameters;

        broadcast = _broadcast;

        // Store OpenSea's operator filter registry, (passed as parameter to constructor for dependency injection)
        // On mainnet the filter registry will be: 0x000000000000AAeB6D7670E522A718067333cd4E
        operatorFilterRegistry = IOperatorFilterRegistry(operatorFiltererInputs.operatorFilterRegistryAddress);

        // Register contract address with the registry and subscribe to
        // CORI canonical filter-list (passed via constructor for dependency injection)
        // On mainnet the subscription address will be: 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6
        operatorFilterRegistry.registerAndSubscribe(
            address(this),
            operatorFiltererInputs.coriCuratedSubscriptionAddress
        );
    }

    /**
     * @notice See {IDynamicBlueprint.prepareBlueprintAndCreateSale}
     */
    function prepareBlueprintAndCreateSale(
        BlueprintPreparationConfig calldata config,
        IStorefront.Sale memory sale,
        address storefront
    ) external override onlyRole(MINTER_ROLE) {
        require(blueprint.prepared == false, "already prepared");
        require(hasRole(STOREFRONT_MINTER_ROLE, storefront), "Storefront not authorized to mint");
        blueprint.capacity = config._capacity;

        _setupBlueprint(config._baseTokenUri, config._blueprintMetaData, config._isSoulbound);

        IStorefront(storefront).createSale(sale);

        _setBlueprintPrepared(config._blueprintMetaData);
    }

    /**
     * @notice See {IDynamicBlueprint.mintBlueprints}
     */
    function mintBlueprints(
        uint32 purchaseQuantity,
        address nftRecipient
    ) external override onlyRole(STOREFRONT_MINTER_ROLE) {
        Blueprint memory b = blueprint;
        // quantity must be available for minting
        require(b.mintedCount + purchaseQuantity <= b.capacity || b.capacity == 0, "quantity >");
        if (b.isSoulbound) {
            // if soulbound, can only mint one and the wallet must not already have a soulbound edition
            require(balanceOf(nftRecipient) == 0 && purchaseQuantity == 1, "max 1 soulbound/addr");
        }

        _mintQuantity(purchaseQuantity, nftRecipient);
    }

    /**
     * @notice See {IDynamicBlueprint.updateBlueprintArtist}
     */
    function updateBlueprintArtist(address _newArtist) external override onlyRole(MINTER_ROLE) {
        artist = _newArtist;
    }

    /**
     * @notice See {IDynamicBlueprint.updatePlatformAddress}
     */
    function updatePlatformAddress(address _platform) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, _platform);

        revokeRole(DEFAULT_ADMIN_ROLE, platform);
        platform = _platform;
    }

    /**
     * @notice See {IDynamicBlueprint.updateBlueprintCapacity}
     */
    function updateBlueprintCapacity(
        uint64 _newCapacity,
        uint64 _newLatestErc721TokenIndex
    ) external override onlyRole(MINTER_ROLE) {
        // why is this a requirement?
        require(blueprint.capacity > _newCapacity, "New cap too large");

        blueprint.capacity = _newCapacity;

        latestErc721TokenIndex = _newLatestErc721TokenIndex;
    }

    /**
     * @notice See {IDynamicBlueprint.updatePerTokenURI}
     */
    function updatePerTokenURI(uint256 _tokenId, string calldata _newURI) external override onlyRole(MINTER_ROLE) {
        require(_exists(_tokenId), "!minted");
        require(!tokenIdsToURI[_tokenId].isFrozen, "uri frozen");
        tokenIdsToURI[_tokenId].tokenURI = _newURI;
    }

    /**
     * @notice See {IDynamicBlueprint.lockPerTokenURI}
     */
    function lockPerTokenURI(uint256 _tokenId) external override {
        require(ownerOf(_tokenId) == msg.sender, "!owner");
        require(!tokenIdsToURI[_tokenId].isFrozen, "uri already frozen");
        tokenIdsToURI[_tokenId].isFrozen = true;
    }

    /**
     * @notice See {IDynamicBlueprint.updateBlueprintTokenUri}
     */
    function updateBlueprintTokenUri(
        string memory newBaseTokenUri
    ) external override onlyRole(MINTER_ROLE) isBlueprintPrepared {
        require(!blueprint.tokenUriLocked, "URI locked");

        blueprint.baseTokenUri = newBaseTokenUri;

        emit BlueprintTokenUriUpdated(newBaseTokenUri);
    }

    /**
     * @notice See {IDynamicBlueprint.updateBlueprintMetadataUri}
     */
    function updateBlueprintMetadataUri(
        string calldata newMetadataUri
    ) external override onlyRole(MINTER_ROLE) isBlueprintPrepared {
        require(!blueprint.metadataUriLocked, "metadata URI locked");
        blueprint.blueprintMetadata = newMetadataUri;
    }

    /**
     * @notice See {IDynamicBlueprint-updateOperatorFilterAndRegister}
     */
    function updateOperatorFilterAndRegister(
        address newRegistry,
        address coriCuratedSubscriptionAddress
    ) external override {
        updateOperatorFilterRegistryAddress(newRegistry);
        addOperatorFiltererSubscription(coriCuratedSubscriptionAddress);
    }

    ////////////////////////////
    /// ONLY ADMIN functions ///
    ////////////////////////////

    /**
     * @notice See {IDynamicBlueprint.lockBlueprintTokenUri}
     */
    function lockBlueprintTokenUri() external override onlyRole(DEFAULT_ADMIN_ROLE) isBlueprintPrepared {
        require(!blueprint.tokenUriLocked, "URI locked");

        blueprint.tokenUriLocked = true;
    }

    /**
     * @notice See {IDynamicBlueprint.lockBlueprintMetadataUri}
     */
    function lockBlueprintMetadataUri() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        blueprint.metadataUriLocked = true;
    }

    /**
     * @notice See {IDynamicBlueprint.updateRoyalty}
     */
    function updateRoyalty(
        Royalty calldata newRoyalty
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) royaltyValid(newRoyalty) {
        _royalty = newRoyalty;
    }

    /**
     * @notice See {IDynamicBlueprint.updateMinterAddress}
     */
    function updateMinterAddress(address newMinterAddress) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, newMinterAddress);

        revokeRole(MINTER_ROLE, minterAddress);
        minterAddress = newMinterAddress;
    }

    ////////////////////////////////////
    /// Secondary Fees implementation //
    ////////////////////////////////////

    /**
     * @notice See {IDynamicBlueprint.getFeeRecipients}
     */
    function getFeeRecipients(
        uint256 /* tokenId */
    ) external view override(HasSecondarySaleFees, IDynamicBlueprint) returns (address[] memory) {
        return _royalty.recipients;
    }

    /**
     * @notice See {IDynamicBlueprint.getFeeBps}
     */
    function getFeeBps(
        uint256 /* tokenId */
    ) external view override(HasSecondarySaleFees, IDynamicBlueprint) returns (uint32[] memory) {
        return _royalty.royaltyCutsBPS;
    }

    /**
     * @notice See {IDynamicBlueprint.metadataURI}
     */
    function metadataURI() external view virtual override isBlueprintPrepared returns (string memory) {
        return blueprint.blueprintMetadata;
    }

    /**
     * @notice Register this contract with the OpenSea operator registry. Subscribe to OpenSea's operator blacklist.
     * @param subscription An address that is currently registered with the operatorFiltererRegistry
     *                     that we will subscribe to.
     */
    function addOperatorFiltererSubscription(address subscription) public {
        require(owner() == msg.sender || artist == msg.sender, "unauthorized");
        operatorFilterRegistry.subscribe(address(this), subscription);
    }

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
     *         address, checks will be bypassed.
     * @param newRegistry New address to make checks against
     */
    function updateOperatorFilterRegistryAddress(address newRegistry) public {
        require(owner() == msg.sender || artist == msg.sender, "unauthorized");
        operatorFilterRegistry = IOperatorFilterRegistry(newRegistry);
        if (newRegistry != address(0)) {
            operatorFilterRegistry.register(address(this));
        }
    }

    /**
     * @notice Override {IERC721-setApprovalForAll} to check against operator filter registry if it exists
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Override {IERC721-approve} to check against operator filter registry if it exists
     */
    function approve(address operator, uint256 tokenId) public override onlyAllowedOperatorApproval(operator) {
        super.approve(operator, tokenId);
    }

    /**
     * @notice Override {IERC721-transferFrom} to check soulbound, and operator filter registry if it exists
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override onlyAllowedOperator(from) isNotSoulbound(tokenId) {
        super.transferFrom(from, to, tokenId);
    }

    /**
     * @notice Override {IERC721-safeTransferFrom} to check soulbound, and operator filter registry if it exists
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override onlyAllowedOperator(from) isNotSoulbound(tokenId) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    /**
     * @notice Return token's uri
     * @param tokenId ID of token to return uri for
     * @return Token uri, constructed by taking base uri of blueprint, and concatenating token id (unless overridden)
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");

        string memory customTokenURI = tokenIdsToURI[tokenId].tokenURI;
        if (bytes(customTokenURI).length != 0) {
            // if a custom token URI has been registered, prefer it to the default
            return customTokenURI;
        }

        string memory baseURI = blueprint.baseTokenUri;
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, "/", tokenId.toString(), "/", "token.json"))
                : "";
    }

    /**
     * @notice Used for interoperability purposes (EIP-173)
     * @return Returns platform address as owner of contract
     */
    function owner() public view virtual returns (address) {
        return platform;
    }

    ////////////////////////////////////
    /// Required function overide //////
    ////////////////////////////////////

    /**
     * @notice ERC165 - Validate that the contract supports a interface
     * @param interfaceId ID of interface being validated
     * @return Returns true if contract supports interface
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, ERC165StorageUpgradeable, AccessControlEnumerableUpgradeable)
        returns (bool)
    {
        return
            interfaceId == type(HasSecondarySaleFees).interfaceId ||
            ERC721Upgradeable.supportsInterface(interfaceId) ||
            ERC165StorageUpgradeable.supportsInterface(interfaceId) ||
            AccessControlEnumerableUpgradeable.supportsInterface(interfaceId);
    }

    /**
     * @notice Sets values after blueprint preparation
     * @param _blueprintMetaData Blueprint metadata uri
     */
    function _setBlueprintPrepared(string memory _blueprintMetaData) private {
        //assign the erc721 token index to the blueprint
        blueprint.erc721TokenIndex = latestErc721TokenIndex;
        blueprint.prepared = true;
        uint64 _capacity = blueprint.capacity;
        latestErc721TokenIndex += _capacity;

        emit BlueprintPrepared(artist, _capacity, _blueprintMetaData, blueprint.baseTokenUri);
    }

    /**
     * @notice Sets up core blueprint parameters
     * @param _baseTokenUri Base token uri for blueprint
     * @param _metadataUri Metadata uri for blueprint
     * @param _isSoulbound Denotes if tokens minted on blueprint are non-transferable
     */
    function _setupBlueprint(string memory _baseTokenUri, string memory _metadataUri, bool _isSoulbound) private {
        blueprint.baseTokenUri = _baseTokenUri;
        blueprint.blueprintMetadata = _metadataUri;

        if (_isSoulbound) {
            blueprint.isSoulbound = _isSoulbound;
        }
    }

    /**
     * @notice Mint a quantity of NFTs of blueprint to a recipient
     * @param _quantity Quantity to mint
     * @param _nftRecipient Recipient of minted NFTs
     */
    function _mintQuantity(uint32 _quantity, address _nftRecipient) private {
        uint128 newTokenId = blueprint.erc721TokenIndex;
        uint64 newMintedCount = blueprint.mintedCount;
        for (uint16 i; i < _quantity; i++) {
            _mint(_nftRecipient, newTokenId + i);
            emit BlueprintMinted(newTokenId + i, newMintedCount, _nftRecipient);
            ++newMintedCount;
        }

        blueprint.erc721TokenIndex += _quantity;
        blueprint.mintedCount = newMintedCount;
    }

    /**
     * @notice Check if operator can perform an action
     * @param operator Operator attempting to perform action
     */
    function _checkFilterOperator(address operator) private view {
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(registry) != address(0) && address(registry).code.length > 0) {
            if (!registry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../storefront/interfaces/IStorefront.sol";
import "../../common/IRoyalty.sol";

/**
 * @notice Async Art Dynamic Blueprint NFT contract interface
 * @author Ohimire Labs
 */
interface IDynamicBlueprint {
    /**
     * @notice Blueprint
     * @param capacity Number of NFTs in Blueprint
     * @param mintedCount Number of Blueprint NFTs minted so far
     * @param erc721TokenIndex First token ID of the next Blueprint to be prepared
     * @param tokenUriLocked If the token metadata isn't updatable
     * @param baseTokenUri Base URI for token, resultant uri for each token is base uri concatenated with token id
     * @param metadataUriLocked If the metadata uri is frozen (cannot be modified)
     * @param blueprintMetadata A URI to web2 metadata for this entire blueprint
     * @param prepared If the blueprint is prepared
     * @param isSouldbound If the blueprint editions are soulbound tokens
     */
    struct Blueprint {
        uint64 capacity;
        uint64 mintedCount;
        uint64 erc721TokenIndex;
        bool tokenUriLocked;
        string baseTokenUri;
        bool metadataUriLocked;
        string blueprintMetadata;
        bool prepared;
        bool isSoulbound;
    }

    /**
     * @notice Data passed in when preparing blueprint
     * @param _capacity Number of NFTs in Blueprint
     * @param _blueprintMetaData Blueprint metadata uri
     * @param _baseTokenUri Base URI for token, resultant uri for each token is base uri concatenated with token id
     * @param _isSoulbound If the Blueprint is soulbound
     */
    struct BlueprintPreparationConfig {
        uint64 _capacity;
        string _blueprintMetaData;
        string _baseTokenUri;
        bool _isSoulbound;
    }

    /**
     * @notice Creator config of contract
     * @param name Contract name
     * @param symbol Contract symbol
     * @param contractURI Contract-level metadata
     * @param artist Blueprint artist
     */
    struct DynamicBlueprintsInput {
        string name;
        string symbol;
        string contractURI;
        address artist;
    }

    /**
     * @notice Per-token optional struct tracking token-specific URIs which override baseTokenURI
     * @param tokenURI URI of token metadata
     * @param isFrozen whether or not the URI is frozen
     */
    struct DynamicBlueprintTokenURI {
        string tokenURI;
        bool isFrozen;
    }

    /**
     * @notice Prepare the blueprint and create a sale for it on a storefront 
               (this is the core operation to set up a blueprint)
     * @param config Object containing values required to prepare blueprint
     * @param sale Blueprint sale
     * @param storefront Storefront to create sale on
     */
    function prepareBlueprintAndCreateSale(
        BlueprintPreparationConfig calldata config,
        IStorefront.Sale memory sale,
        address storefront
    ) external;

    /**
     * @notice Mint a number of editions of this blueprint
     * @param purchaseQuantity How many blueprint editions to mint
     * @param nftRecipient Recipient of minted blueprints
     */
    function mintBlueprints(uint32 purchaseQuantity, address nftRecipient) external;

    /**
     * @notice Update the blueprint's artist
     * @param _newArtist New artist
     */
    function updateBlueprintArtist(address _newArtist) external;

    /**
     * @notice Update a blueprint's capacity
     * @param _newCapacity New capacity
     * @param _newLatestErc721TokenIndex Newly adjusted last ERC721 token id
     */
    function updateBlueprintCapacity(uint64 _newCapacity, uint64 _newLatestErc721TokenIndex) external;

    /**
     * @notice Update a specific token's URI
     * @param _tokenId The ID of the token
     * @param _newURI The new overriding token URI for the token
     */
    function updatePerTokenURI(uint256 _tokenId, string calldata _newURI) external;

    /**
     * @notice Lock the metadata URI of a specific token
     * @param _tokenId The ID of the token
     */
    function lockPerTokenURI(uint256 _tokenId) external;

    /**
     * @notice Update blueprint's token uri
     * @param newBaseTokenUri New base token uri to update to
     */
    function updateBlueprintTokenUri(string calldata newBaseTokenUri) external;

    /**
     * @notice Lock blueprint's token uri (from changing)
     */
    function lockBlueprintTokenUri() external;

    /**
     * @notice Update blueprint's metadata URI
     * @param newMetadataUri New metadata URI
     */
    function updateBlueprintMetadataUri(string calldata newMetadataUri) external;

    /**
     * @notice Lock blueprint's metadata uri (from changing)
     */
    function lockBlueprintMetadataUri() external;

    /**
     * @notice Update royalty config
     * @param newRoyalty New royalty parameters
     */
    function updateRoyalty(IRoyalty.Royalty calldata newRoyalty) external;

    /**
     * @notice Update contract-wide minter address, and MINTER_ROLE role ownership
     * @param newMinterAddress New minter address
     */
    function updateMinterAddress(address newMinterAddress) external;

    /**
     * @notice Update contract-wide platform address, and DEFAULT_ADMIN_ROLE role ownership
     * @param _platform New platform
     */
    function updatePlatformAddress(address _platform) external;

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. 
               Also register this contract with that registry.
     * @param newRegistry New Operator filter registry to check against
     * @param coriCuratedSubscriptionAddress CORI Curated subscription address 
     *        -> updates Async's operator filter list in coordination with OS
     */
    function updateOperatorFilterAndRegister(address newRegistry, address coriCuratedSubscriptionAddress) external;

    /**
     * @notice Return the blueprint's metadata URI
     */
    function metadataURI() external view returns (string memory);

    /**
     * @notice Get secondary fee recipients of a token
     * @param // tokenId Token ID
     */
    function getFeeRecipients(uint256 /* tokenId */) external view returns (address[] memory);

    /**
     * @notice Get secondary fee bps (allocations) of a token
     * @param // tokenId Token ID
     */
    function getFeeBps(uint256 /* tokenId */) external view returns (uint32[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Broadcasts signed intents of Expansion item applications to Dynamic Blueprint NFTs
 * @dev Allows the platform to emit bundled intents or users to submit intents themselves
 * @author Ohimire Labs
 */
contract DynamicBlueprintsBroadcast is Ownable {
    /**
     * @notice Emitted when bundled intents are emitted
     * @param intentsFile File of bundled signed intents
     */
    event CollatedIntents(string intentsFile);

    /**
     * @notice Emitted when a single intent is emitted
     * @param intentFile File of signed intent
     * @param applier User applying the expansion item to the dbp
     */
    event Intent(string intentFile, address indexed applier);

    /**
     * @notice Lets platform emit bundled user intents to apply expansion items to their DBPs
     * @param intentsFile File of bundled signed intents
     */
    function saveBatch(string memory intentsFile) external onlyOwner {
        emit CollatedIntents(intentsFile);
    }

    /**
     * @notice Lets user emit signed intents to apply expansion items to their Dynamic Blueprint NFTs
     * @param intentFile File of signed intent
     */
    function applyItems(string memory intentFile) external {
        emit Intent(intentFile, msg.sender);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/**
 * @notice Interface containing OS operator filterer inputs shared throughout Dynamic Blueprint system
 * @author Ohimire Labs
 */
interface IOperatorFilterer {
    /**
     * @notice Shared operator filterer inputs
     * @param operatorFilterRegistryAddress Address of OpenSea's operator filter registry contract
     * @param coriCuratedSubscriptionAddress Address of CORI canonical filtered-list
     *                                       (Async's filtered list will update in accordance with this parameter)
     */
    struct OperatorFiltererInputs {
        address operatorFilterRegistryAddress;
        address coriCuratedSubscriptionAddress;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/**
 * @notice Interface containing shared royalty object throughout Dynamic Blueprint system
 * @author Ohimire Labs
 */
interface IRoyalty {
    /**
     * @notice Shared royalty object
     * @param recipients Royalty recipients
     * @param royaltyCutsBPS Percentage of purchase allocated to each royalty recipient, in basis points
     */
    struct Royalty {
        address[] recipients;
        uint32[] royaltyCutsBPS;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./IRoyalty.sol";

/**
 * @notice Shared royalty validation logic in Dynamic Blueprints system
 * @author Ohimire Labs
 */
abstract contract Royalty is IRoyalty {
    /**
     * @notice Validate a royalty object
     * @param royalty Royalty being validated
     */
    modifier royaltyValid(Royalty memory royalty) {
        require(royalty.recipients.length == royalty.royaltyCutsBPS.length, "Royalty arrays mismatched lengths");
        uint256 royaltyCutsSum = 0;
        for (uint i = 0; i < royalty.recipients.length; i++) {
            royaltyCutsSum += royalty.royaltyCutsBPS[i];
        }
        require(royaltyCutsSum <= 10000, "Royalty too large");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

/**
 * @title Modifying OpenZeppelin's ERC1967Proxy to use UUPS
 * @author Ohimire Labs and OpenZeppelin Labs
 * @notice Implements an upgradeable proxy. OpenZeppelin template edited by Ohimire Labs
 */
contract StorefrontProxy is Proxy, ERC1967Upgrade {
    /**
     * @notice Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCallUUPS(_logic, _data, false);
    }

    /**
     * @notice Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IExpansion.sol";
import "../common/Royalty.sol";
import "../common/IOperatorFilterer.sol";
import "../operatorFilter/IOperatorFilterRegistry.sol";
import "../abstract/HasSecondarySaleFees.sol";

/**
 * @notice Dynamic Blueprint Expansion contract housing expansion packs/items that are used to augment DBP NFTs
 * @author Ohimire Labs
 */
contract Expansion is IExpansion, ERC1155SupplyUpgradeable, AccessControlUpgradeable, HasSecondarySaleFees, Royalty {
    using StringsUpgradeable for uint256;

    /**
     * @notice Number of packs created
     */
    uint256 public numPacks;

    /**
     * @notice Number of tokens created through created packs
     */
    uint256 public numTokens;

    /**
     * @notice Expansion artist
     */
    address public artist;

    /**
     * @notice Contract level metadata
     */
    string public contractURI;

    /**
     * @notice Broadcast contract
     */
    address public broadcast;

    /**
     * @notice A registry to check for blacklisted operator addresses.
     *      Used to only permit marketplaces enforcing creator royalites if desired
     */
    IOperatorFilterRegistry public operatorFilterRegistry;

    /**
     * @notice Holders of this role are given minter privileges
     */
    bytes32 public constant STOREFRONT_MINTER_ROLE = keccak256("STOREFRONT_MINTER_ROLE");

    /**
     * @notice Expansion contract's royalty
     */
    Royalty internal _royalty;

    /**
     * @notice Track packs
     */
    mapping(uint256 => Pack) private _packs;

    /**
     * @notice Platform address
     */
    address public platform;

    /**
     * @notice Amount of ether which artist has deposited to front gas for preparePack calls.
     *         These funds are pooled on the platform account, but the amount of deposit is tracked on contract state.
     */
    uint256 public gasAmountDeposited;

    /**
     * @notice Emitted when a pack is prepared
     * @param packId Identifier for AsyncArt platform to track pack creation.
     * @param capacity The maximum number of mintable pack's (0 -> infinite)
     * @param baseUri The pack's baseUri -> used to generate token URIs
     */
    event PackPrepared(uint256 indexed packId, uint256 capacity, string baseUri);

    /** TODO(sorend): think of the best way to do this event
     * @notice Emitted when a pack is minted
     * @param packId Identifier of the pack
     * @param recipient The address receiving the minted pack
     * @param tokenIdCombinations A list of sets of token ids.
     *                            Each of these sets was minted numMintsOfCombination[i] times
     * @param numMintsOfCombination The number of times each set of ids was minted
     */
    event PacksMinted(
        uint256 indexed packId,
        address recipient,
        uint256[][] tokenIdCombinations,
        uint32[] numMintsOfCombination
    );

    /**
     * @notice Reverts if caller isn't platform
     */
    // CR(sorend): why do we enforce on this and also onlyRole(DEFAULT_ADMIN_ROLE)
    modifier onlyPlatform() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not platform");
        _;
    }

    /////////////////////////////////////////////////
    /// Required for CORI Operator Registry //////
    /////////////////////////////////////////////////

    // Custom Error Type For Operator Registry Methods
    error OperatorNotAllowed(address operator);

    /**
     * @notice Restrict operators who are allowed to transfer these tokens
     * @param from Account that token is being transferred out of
     */
    modifier onlyAllowedOperator(address from) {
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @notice Restrict operators who are allowed to approve transfer delegates
     * @param operator Operator that is attempting to move tokens
     */
    modifier onlyAllowedOperatorApproval(address operator) {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @notice Initialize expansion instance
     * @param storefrontMinters Storefront minters to be given STOREFRONT_MINTER_ROLE
     * @param initialPlatform Address stored as platform initially
     * @param _contractURI Contract level metadata
     * @param _artist Expansion artist
     * @param initialRoyalty Initial royalty on contract
     * @param _broadcast Broadcast contract for protocol
     * @param operatorFiltererInputs OpenSea operator filterer addresses
     * @param _gasAmountDeposited The initial deposit the contract deployer made to
     *                            cover gas associated with preparePack calls
     */
    function initialize(
        address[] calldata storefrontMinters,
        address initialPlatform,
        string calldata _contractURI,
        address _artist,
        Royalty calldata initialRoyalty,
        address _broadcast,
        IOperatorFilterer.OperatorFiltererInputs calldata operatorFiltererInputs,
        uint256 _gasAmountDeposited
    ) external initializer royaltyValid(initialRoyalty) {
        // call inits on inherited contracts
        __ERC1155_init("");
        __AccessControl_init();
        HasSecondarySaleFees._initialize();

        // grant roles
        _setupRole(DEFAULT_ADMIN_ROLE, initialPlatform);
        for (uint i = 0; i < storefrontMinters.length; i++) {
            _setupRole(STOREFRONT_MINTER_ROLE, storefrontMinters[i]);
        }
        platform = initialPlatform;
        artist = _artist;

        contractURI = _contractURI;
        _royalty = initialRoyalty;

        broadcast = _broadcast;

        // Store OpenSea's operator filter registry, (passed as parameter to constructor for dependency injection)
        // On mainnet the filter registry will be: 0x000000000000AAeB6D7670E522A718067333cd4E
        operatorFilterRegistry = IOperatorFilterRegistry(operatorFiltererInputs.operatorFilterRegistryAddress);

        // Register contract address with the registry and subscribe to CORI canonical filter-list
        // (passed via constructor for dependency injection)
        // On mainnet the subscription address will be: 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6
        operatorFilterRegistry.registerAndSubscribe(
            address(this),
            operatorFiltererInputs.coriCuratedSubscriptionAddress
        );

        gasAmountDeposited = _gasAmountDeposited;
    }

    /**
     * @notice See {IExpansion-mintSameCombination}
     */
    function mintSameCombination(
        uint256 packId,
        uint256[] calldata tokenIds,
        uint32 numTimes,
        address nftRecipient
    ) external override onlyRole(STOREFRONT_MINTER_ROLE) {
        Pack memory pack = _packs[packId];
        uint256 newPackMintedCount = pack.mintedCount + numTimes;
        require(newPackMintedCount <= pack.capacity || pack.capacity == 0, "Over capacity");
        _packs[packId].mintedCount = newPackMintedCount;

        _mintPack(tokenIds, numTimes, nftRecipient, pack.itemSizes, pack.startTokenId);
    }

    /**
     * @notice See {IExpansion-mintDifferentCombination}
     */
    function mintDifferentCombination(
        uint256 packId,
        uint256[][] calldata tokenIdCombinations,
        uint32[] calldata numCombinationPurchases,
        address nftRecipient
    ) external override onlyRole(STOREFRONT_MINTER_ROLE) {
        require(tokenIdCombinations.length == numCombinationPurchases.length, "Combination arrays mismatched");
        Pack memory pack = _packs[packId];

        uint256 combinations = tokenIdCombinations.length;
        uint32 numPurchases = 0;
        for (uint256 i = 0; i < combinations; i++) {
            _mintPack(
                tokenIdCombinations[i],
                numCombinationPurchases[i],
                nftRecipient,
                pack.itemSizes,
                pack.startTokenId
            );
            numPurchases += numCombinationPurchases[i];
        }

        uint256 newPackMintedCount = pack.mintedCount + numPurchases;
        require(newPackMintedCount <= pack.capacity || pack.capacity == 0, "Over capacity");
        _packs[packId].mintedCount = newPackMintedCount;
    }

    /**
     * @notice See {IExpansion-preparePack}
     */
    function preparePack(Pack memory pack) external payable override onlyPlatform {
        _preparePack(pack);

        // If Async provided a msg.value refund the artist the difference between their gas deposit
        // and the actual gas cost of the preparePack call
        if (msg.value > 0) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = artist.call{ value: msg.value }("");
            /* solhint-enable avoid-low-level-calls */
            require(success, "gas deposit to platform failed");
        }
    }

    /**
     * @notice See {IExpansion-preparePackAndSale}
     */
    function preparePackAndSale(
        Pack memory pack,
        IStorefront.Sale memory sale,
        address storefront
    ) external override onlyPlatform {
        sale.packId = _preparePack(pack);

        IStorefront(storefront).createSale(sale);
    }

    /**
     * @notice See {IExpansion-updatePlatformAddress}
     */
    function updatePlatformAddress(address _platform) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, _platform);

        revokeRole(DEFAULT_ADMIN_ROLE, platform);
        platform = _platform;
    }

    /**
     * @notice See {IExpansion-updateArtist}
     */
    function updateArtist(address newArtist) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        artist = newArtist;
    }

    /**
     * @notice See {IExpansion-topUpGasFunds}
     */
    function topUpGasFunds() external payable override {
        gasAmountDeposited += msg.value;
        /* solhint-disable avoid-low-level-calls */
        (bool success, ) = platform.call{ value: msg.value }("");
        /* solhint-enable avoid-low-level-calls */
        require(success, "gas deposit to platform failed");
    }

    /**
     * @notice See {IExpansion-setBaseUri}
     */
    function setBaseUri(uint256 packId, string calldata newBaseUri) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_packs[packId].tokenUriLocked, "URI locked");
        _packs[packId].baseUri = newBaseUri;
    }

    /**
     * @notice See {IExpansion-lockBaseUri}
     */
    function lockBaseUri(uint256 packId) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(!_packs[packId].tokenUriLocked, "URI already locked");
        _packs[packId].tokenUriLocked = true;
    }

    /**
     * @notice See {IExpansion-updateOperatorFilterAndRegister}
     */
    function updateOperatorFilterAndRegister(address newRegistry, address newSubscription) external override {
        updateOperatorFilterRegistryAddress(newRegistry);
        addOperatorFiltererSubscription(newSubscription);
    }

    /**
     * @notice See {IExpansion-getPack}
     */
    function getPack(uint256 packId) external view override returns (Pack memory) {
        return _packs[packId];
    }

    /**
     * @notice See {IExpansion-getPacks}
     */
    function getPacks(uint256[] calldata packIds) external view override returns (Pack[] memory) {
        Pack[] memory packs = new Pack[](packIds.length);
        for (uint i = 0; i < packIds.length; i++) {
            packs[i] = _packs[packIds[i]];
        }

        return packs;
    }

    /**
     * @notice See {IExpansion-isPlatform}
     */
    function isPlatform(address account) external view override returns (bool) {
        return account == platform;
    }

    /**
     * @notice See {IExpansion-getFeeRecipients}
     */
    function getFeeRecipients(
        uint256 /* tokenId */
    ) external view override(HasSecondarySaleFees, IExpansion) returns (address[] memory) {
        return _royalty.recipients;
    }

    /**
     * @notice See {IExpansion-getFeeBps}
     */
    function getFeeBps(
        uint256 /* tokenId */
    ) external view override(HasSecondarySaleFees, IExpansion) returns (uint32[] memory) {
        return _royalty.royaltyCutsBPS;
    }

    /**
     * @notice See {IExpansion-getTokenPack}
     */
    function getTokenPack(uint256 tokenId) external view override returns (Pack memory) {
        return _getTokenPack(tokenId);
    }

    /**
     * @notice Subscribe to a new operator-filterer list.
     * @param subscription An address currently registered with the operatorFilterRegistry to subscribe to.
     */
    function addOperatorFiltererSubscription(address subscription) public {
        require(owner() == msg.sender || artist == msg.sender, "unauthorized");
        operatorFilterRegistry.subscribe(address(this), subscription);
    }

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against. When set to the zero
     *         address, checks will be bypassed. If not zero, this contract will be registered with the registry.
     * @param newRegistry New operator filterer address.
     */
    function updateOperatorFilterRegistryAddress(address newRegistry) public {
        require(owner() == msg.sender || artist == msg.sender, "unauthorized");
        operatorFilterRegistry = IOperatorFilterRegistry(newRegistry);
        if (newRegistry != address(0)) {
            operatorFilterRegistry.register(address(this));
        }
    }

    /**
     * @notice Override {IERC1155-setApprovalForAll} to check against operator filter registry if it exists
     */
    function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
        super.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Override {IERC1155-safeTransferFrom} to check against operator filter registry if it exists
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @notice Override {IERC1155-safeBatchTransferFrom} to check against operator filter registry if it exists
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public override onlyAllowedOperator(from) {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @notice Overrides {IERC1155-uri} to get base uri for pack that token is in, and concatenates token id
     * @param id ID of token to get uri for
     */
    function uri(uint256 id) public view override returns (string memory) {
        string memory baseUri = _getTokenPack(id).baseUri;

        return
            bytes(baseUri).length > 0 ? string(abi.encodePacked(baseUri, "/", id.toString(), "/", "token.json")) : "";
    }

    /**
     * @notice Used for interoperability purposes (EIP-173)
     * @return Returns platform address as owner of contract
     */
    function owner() public view virtual returns (address) {
        return platform;
    }

    /**
     * @notice See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControlUpgradeable, ERC1155Upgradeable, ERC165StorageUpgradeable)
        returns (bool)
    {
        return interfaceId == type(IExpansion).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Create a pack
     * @param pack Pack to create
     */
    function _preparePack(Pack memory pack) private returns (uint256) {
        // validate that pack is constructed properly
        uint256 itemsLength = pack.itemSizes.length;
        require(itemsLength > 0, "Items length invalid");
        uint256 newNumTokens = numTokens;
        pack.startTokenId = newNumTokens + 1;
        for (uint i = 0; i < itemsLength; i++) {
            newNumTokens += pack.itemSizes[i];
        }
        numTokens = newNumTokens;

        // No tokens have been minted yet
        pack.mintedCount = 0;

        // cache
        uint256 tempLatestPackId = numPacks;

        _packs[tempLatestPackId + 1] = pack;

        numPacks = tempLatestPackId + 1;

        emit PackPrepared(tempLatestPackId + 1, pack.capacity, pack.baseUri);

        return tempLatestPackId + 1;
    }

    /**
     * @notice Mint a combination of tokens on a pack
     * @param tokenIds Combination of tokens to mint
     * @param numPurchases How many of each token in the combination should be minted
     * @param nftRecipient Recipient of minted NFTs
     * @param itemSizes Pack's itemSizes
     * @param startTokenId Pack's start token id
     */
    function _mintPack(
        uint256[] calldata tokenIds,
        uint32 numPurchases,
        address nftRecipient,
        uint256[] memory itemSizes,
        uint256 startTokenId
    ) private {
        require(tokenIds.length == itemSizes.length, "Not same length");

        // assume token ids are aligned with itemIds order
        uint256 itemsLength = itemSizes.length;
        for (uint256 i = 0; i < itemsLength; i++) {
            uint256 tokenId = tokenIds[i];
            uint256 tokenIndex = tokenId - startTokenId;

            require(tokenIndex <= itemSizes[i] - 1, "Token id invalid");
            startTokenId += itemSizes[i];

            _mint(nftRecipient, tokenId, numPurchases, "");
        }
    }

    /**
     * @notice Get pack containing a given tokenId
     * @dev Avoid usage in state mutating functions (writes)
     * @param tokenId ID of token to get pack for
     */
    function _getTokenPack(uint256 tokenId) private view returns (Pack memory) {
        uint256 numPacksTemp = numPacks;
        for (uint256 i = 1; i <= numPacksTemp; i++) {
            Pack memory pack = _packs[i];
            uint256 itemsLength = pack.itemSizes.length;
            uint256 startTokenIdForItemInPack = pack.startTokenId;
            for (uint256 j = 0; j < itemsLength; j++) {
                uint256 itemSize = pack.itemSizes[j];
                if (j != 0) {
                    startTokenIdForItemInPack += itemSize;
                }
                if (startTokenIdForItemInPack > tokenId) {
                    revert("Skipped token id");
                }
                uint256 endTokenIdForItemInPack = startTokenIdForItemInPack + itemSize - 1;
                // If tokenId is in the range of token ids for a given pack
                if (tokenId <= endTokenIdForItemInPack && tokenId >= startTokenIdForItemInPack) {
                    return pack;
                }
            }
        }
        revert("Token id too big");
    }

    /**
     * @notice Check if operator can perform an action
     * @param operator Operator attempting to perform action
     */
    function _checkFilterOperator(address operator) private view {
        IOperatorFilterRegistry registry = operatorFilterRegistry;
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(registry) != address(0) && address(registry).code.length > 0) {
            if (!registry.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../../storefront/interfaces/IStorefront.sol";
import "../../common/IRoyalty.sol";

/**
 * @notice Interface for Dynamic Blueprint Expansion contract
 * @author Ohimire Labs
 */
interface IExpansion is IRoyalty {
    /**
     * @notice Atomic purchaseable unit
     * @param itemSizes The number of tokens in each item in pack
     * @param startTokenId Start token id of the pack
     * @param capacity The number of packs that can be purchased
     * @param mintedCount The number of packs that have been purchased
     * @param baseUri The base uri containing metadata for tokens in the pack
     * @param tokenUriLocked Denotes if changes to the baseUri is locked
     */
    struct Pack {
        uint256[] itemSizes;
        uint256 startTokenId;
        uint256 capacity;
        uint256 mintedCount;
        string baseUri;
        bool tokenUriLocked;
    }

    /**
     * @notice Mint the same combination of token ids in a pack. Each token is a token in one item in the pack
     * @param packId ID of pack
     * @param tokenIds Combination of tokens being minted
     * @param numTimes How many of each token in the combination are minted
     * @param nftRecipient Recipient of minted tokens
     */
    function mintSameCombination(
        uint256 packId,
        uint256[] calldata tokenIds,
        uint32 numTimes,
        address nftRecipient
    ) external;

    /**
     * @notice Mint different combinations of token ids in a pack.
     * @dev Could flatten 2d array to fully optimize for gas
     *      but logic would be too misaligned from natural function / readability
     * @param tokenIdCombinations The unique, different token id combinations being minted in pack
     * @param numCombinationPurchases How many times each unique combination is minted
     * @param nftRecipient Recipient of minted NFTs
     */
    function mintDifferentCombination(
        uint256 packId,
        uint256[][] calldata tokenIdCombinations,
        uint32[] calldata numCombinationPurchases,
        address nftRecipient
    ) external;

    /**
     * @notice Create a pack
     * @param pack Pack being created
     */
    function preparePack(Pack calldata pack) external payable;

    /**
     * @notice Create a pack and sale for the pack on a storefront
     * @param pack Pack being created
     * @param sale Sale being created
     * @param storefront Storefront that sale resides on
     */
    function preparePackAndSale(Pack calldata pack, IStorefront.Sale calldata sale, address storefront) external;

    /**
     * @notice Set a pack's base uri
     * @param packId ID of pack who's base uri is being set
     * @param newBaseUri New base uri for pack
     */
    function setBaseUri(uint256 packId, string calldata newBaseUri) external;

    /**
     * @notice Lock a pack's base uri
     * @param packId ID of pack who's base uri is being locked
     */
    function lockBaseUri(uint256 packId) external;

    /**
     * @notice Update expansion contract's artist
     * @param newArtist New artist to update to
     */
    function updateArtist(address newArtist) external;

    /**
     * @notice Update expansion contract's platform address and manage ownership of DEFAULT_ADMIN_ROLE accordingly
     * @param _platform New platform
     */
    function updatePlatformAddress(address _platform) external;

    /**
     * @notice Update the address that the contract will make OperatorFilter checks against.
               Also register this contract with that registry.
     * @param newRegistry New Operator filter registry to check against
     * @param newSubscription Filter-list to subscribe to 
     */
    function updateOperatorFilterAndRegister(address newRegistry, address newSubscription) external;

    /**
     * @notice Enable artist (although not restricted) to top-up funds which are used to cover AsyncArt gas fees for preparePack calls
     */
    function topUpGasFunds() external payable;

    /**
     * @notice Get a pack by its ID
     * @param packId ID of pack to get
     */
    function getPack(uint256 packId) external view returns (Pack memory);

    /**
     * @notice Get packs by their IDs
     * @param packIds IDs of packs to get
     */
    function getPacks(uint256[] calldata packIds) external view returns (Pack[] memory);

    /**
     * @notice Get the pack a token belongs to
     * @param tokenId ID of token who's pack is retrieved
     */
    function getTokenPack(uint256 tokenId) external view returns (Pack memory);

    /**
     * @notice Return true if account is the platform account
     * @param account Account being checked
     */
    function isPlatform(address account) external view returns (bool);

    /**
     * @notice Get secondary fee recipients of a token
     * @param // tokenId Token ID
     */
    function getFeeRecipients(uint256 /* tokenId */) external view returns (address[] memory);

    /**
     * @notice Get secondary fee bps (allocations) of a token
     * @param // tokenId Token ID
     */
    function getFeeBps(uint256 /* tokenId */) external view returns (uint32[] memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../blueprints/DynamicBlueprint.sol";
import "../expansion/Expansion.sol";
import "../broadcast/DynamicBlueprintsBroadcast.sol";
import "../storefront/SimpleExpansionStorefront.sol";
import "../storefront/RandomExpansionStorefront.sol";
import "../storefront/SimpleDBPStorefront.sol";
import "../common/StorefrontProxy.sol";
import "../common/IRoyalty.sol";
import "../common/IOperatorFilterer.sol";

import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @notice Used to deploy and configure DynamicBlueprint and DynamicBlueprintsExpansion contracts with multiple settings
 * @author Ohimire Labs
 */
contract DynamicBlueprintsFactory is Ownable {
    /**
     * @notice Default addresses given admin roles on DBP instances
     * @param defaultAdmin Account given DEFAULT_ADMIN_ROLE
     * @param minter Account made platform minter
     * @param storefrontMinters Storefronts initially registered as valid storefront minters
     */
    struct DynamicBlueprintsDefaultRoles {
        address defaultAdmin;
        address minter;
        address[] storefrontMinters;
    }

    /**
     * @notice Default addresses given admin roles on Expansion instances
     * @param defaultAdmin Account given DEFAULT_ADMIN_ROLE
     * @param storefrontMinters Storefronts initially registered as valid storefront minters
     */
    struct ExpansionDefaultRoles {
        address defaultAdmin;
        address[] storefrontMinters;
    }

    /**
     * @notice Beacon keeping track of current DynamicBlueprint implementation
     */
    address public immutable dynamicBlueprintsBeacon;

    /**
     * @notice Beacon keeping track of current Expansion implementation
     */
    address public immutable expansionBeacon;

    /**
     * @notice Broadcast contract where application intents are sent
     */
    address public immutable broadcast;

    /**
     * @notice Default addresses given administrative roles on dynamic blueprint instances
     */
    DynamicBlueprintsDefaultRoles public dbpDefaultRoles;

    /**
     * @notice Default addresses given administrative roles on expansion instances
     */
    ExpansionDefaultRoles public expansionDefaultRoles;

    /**
     * @notice Emitted when contract is deployed, exposing Async Art system contracts deployed in the process
     * @param dynamicBlueprintsImplementation Address of deployed DynamicBlueprints implementation
                                              used in beacon upgradability
     * @param dynamicBlueprintsBeacon Address of deployed beacon tracking DynamicBlueprints implementation
     * @param expansionImplementation Address of deployed DynamincBlueprintsExpansion implementation
                                      used in beacon upgradability
     * @param expansionBeacon Address of deployed beacon tracking BlueprintV12 implementation
     * @param broadcast Address of deployed broadcast contract
     */
    event FactoryDeployed(
        address dynamicBlueprintsImplementation,
        address dynamicBlueprintsBeacon,
        address expansionImplementation,
        address expansionBeacon,
        address broadcast
    );

    /**
     * @notice Emitted when storefront contracts are deployed
     * @param simpleExpansionStorefrontImplementation Address of deployed simple expansion contract implementation
     * @param simpleExpansionStorefront Address of deployed simple expansion contract
     * @param randomExpansionStorefrontImplementation Address of deployed random expansion contract implementation
     * @param randomExpansionStorefront Address of deployed random expansion contract
     * @param simpleDBPStorefrontImplementation Address of deployed simple DBP contract implementation
     * @param simpleDBPStorefront Address of deployed simple DBP contract
     */
    event StorefrontsSetup(
        address simpleExpansionStorefrontImplementation,
        address simpleExpansionStorefront,
        address randomExpansionStorefrontImplementation,
        address randomExpansionStorefront,
        address simpleDBPStorefrontImplementation,
        address simpleDBPStorefront
    );

    /**
     * @notice Emitted when DynamicBlueprint is deployed
     * @param dynamicBlueprint Address of deployed DynamicBlueprints BeaconProxy
     * @param dynamicBlueprintPlatformID Platform's identification of dynamic blueprint
     */
    event DynamicBlueprintDeployed(address indexed dynamicBlueprint, string dynamicBlueprintPlatformID);

    /**
     * @notice Emitted when Expansion is deployed
     * @param expansion Address of deployed DynamicBlueprintsExpansion BeaconProxy
     * @param expansionPlatformID Platform's identification of dynamic blueprint expansion
     */
    event ExpansionDeployed(address indexed expansion, string expansionPlatformID);

    /**
     * @notice This constructor takes a network to a fully deployed AsyncArt DynamicBlueprints system minus storefronts
     * @param dynamicBlueprintsBeaconUpgrader Account that can upgrade the DynamicBlueprint implementation (via beacon)
     * @param expansionBeaconUpgrader Account able to upgrade Expansion implementation (via beacon)
     * @param broadcastOwner Owner of broadcast contract
     * @param factoryOwner Initial owner of this contract
     */
    constructor(
        address dynamicBlueprintsBeaconUpgrader,
        address expansionBeaconUpgrader,
        address broadcastOwner,
        address factoryOwner
    ) {
        // deploy DynamicBlueprints implementation and beacon
        address dynamicBlueprintsImplementation = address(new DynamicBlueprint());
        address _dynamicBlueprintsBeacon = address(new UpgradeableBeacon(dynamicBlueprintsImplementation));
        Ownable(_dynamicBlueprintsBeacon).transferOwnership(dynamicBlueprintsBeaconUpgrader);
        // extra step, as one cannot read immutable variables in a constructor
        dynamicBlueprintsBeacon = _dynamicBlueprintsBeacon;

        // deploy expansion implementation and Beacon for it
        address expansionImplementation = address(new Expansion());
        address _expansionBeacon = address(new UpgradeableBeacon(expansionImplementation));
        Ownable(_expansionBeacon).transferOwnership(expansionBeaconUpgrader);
        // extra step as one cannot read immutable variables in a constructor
        expansionBeacon = _expansionBeacon;

        // deploy Broadcast
        address _broadcast = address(new DynamicBlueprintsBroadcast());
        Ownable(_broadcast).transferOwnership(broadcastOwner);
        // extra step as one cannot read immutable variables in a constructor
        broadcast = _broadcast;

        // transfer ownership of the factory
        _transferOwnership(factoryOwner);

        emit FactoryDeployed(
            dynamicBlueprintsImplementation,
            _dynamicBlueprintsBeacon,
            expansionImplementation,
            _expansionBeacon,
            _broadcast
        );
    }

    /**
     * @notice Deploys and sets up all async storefronts on a raw network. Also populates default addresses fields
     * @param platform Address given DEFAULT_ADMIN role on Storefronts, DBP instances, and expansion instances
     * @param minter Initial default address assigned MINTER_ROLE on Storefronts, DBP instances
     * @param fulfiller Fulfiller of random storefront's purchases
     * @param fulfillmentGasConstants Gas constants on random storefront
     * @param simpleExpansionStorefrontImplementation Simple expansion storefront implementation
     * @param randomExpansionStorefrontImplementation Random expansion storefront implementation
     * @param simpleDBPStorefrontImplementation Simple DBP storefront implementation
     */
    function setupStorefronts(
        address platform,
        address minter,
        address payable fulfiller,
        RandomExpansionStorefront.FulfillmentGasConstants memory fulfillmentGasConstants,
        address simpleExpansionStorefrontImplementation,
        address randomExpansionStorefrontImplementation,
        address simpleDBPStorefrontImplementation
    ) external onlyOwner {
        // deploy 3 storefront UUPS instances
        address simpleExpansionStorefront = address(
            new StorefrontProxy(
                simpleExpansionStorefrontImplementation,
                abi.encodeWithSelector(SimpleExpansionStorefront(address(0)).initialize.selector, platform, minter)
            )
        );

        address randomExpansionStorefront = address(
            new StorefrontProxy(
                randomExpansionStorefrontImplementation,
                abi.encodeWithSelector(
                    RandomExpansionStorefront(address(0)).initialize.selector,
                    platform,
                    minter,
                    fulfiller,
                    fulfillmentGasConstants
                )
            )
        );

        address simpleDBPStorefront = address(
            new StorefrontProxy(
                simpleDBPStorefrontImplementation,
                abi.encodeWithSelector(SimpleDBPStorefront(address(0)).initialize.selector, platform, minter)
            )
        );

        // populate default roles
        address[] memory dbpStorefrontMinters = new address[](1);
        dbpStorefrontMinters[0] = simpleDBPStorefront;

        address[] memory expansionStorefrontMinters = new address[](2);
        expansionStorefrontMinters[0] = simpleExpansionStorefront;
        expansionStorefrontMinters[1] = randomExpansionStorefront;

        dbpDefaultRoles = DynamicBlueprintsDefaultRoles(platform, minter, dbpStorefrontMinters);
        expansionDefaultRoles = ExpansionDefaultRoles(platform, expansionStorefrontMinters);

        emit StorefrontsSetup(
            simpleExpansionStorefrontImplementation,
            simpleExpansionStorefront,
            randomExpansionStorefrontImplementation,
            randomExpansionStorefront,
            simpleDBPStorefrontImplementation,
            simpleDBPStorefront
        );
    }

    /**
     * @notice Deploy DynamicBlueprintsExpansion instance only.
     *         The deployer can pay an optional fee in ether to front the gas cost of preparePack calls that
     *         AsyncArt will make on their behalf on the Expansion contract.
     * @param _contractURI Contract-level metadata for the Expansion contract
     * @param _artist The artist authorized to create items on the expansion
     * @param _royalty Expansion contracts' royalty parameters
     * @param operatorFiltererInputs OpenSea operator filterer addresses
     * @param expansionPlatformID Platform's identification of the expansion contract
     */
    function deployExpansion(
        string calldata _contractURI,
        address _artist,
        IRoyalty.Royalty calldata _royalty,
        IOperatorFilterer.OperatorFiltererInputs calldata operatorFiltererInputs,
        string calldata expansionPlatformID
    ) external payable {
        address expansion = address(
            new BeaconProxy(
                expansionBeacon,
                abi.encodeWithSelector(
                    Expansion(address(0)).initialize.selector,
                    expansionDefaultRoles.storefrontMinters,
                    expansionDefaultRoles.defaultAdmin,
                    _contractURI,
                    _artist,
                    _royalty,
                    broadcast,
                    operatorFiltererInputs,
                    msg.value
                )
            )
        );

        // If the deployer supplied a gas deposit, send it to the platform that will administrate preparePack calls
        if (msg.value > 0) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = (expansionDefaultRoles.defaultAdmin).call{ value: msg.value }("");
            /* solhint-enable avoid-low-level-calls */
            require(success, "gas deposit to platform failed");
        }
        emit ExpansionDeployed(expansion, expansionPlatformID);
    }

    /**
     * @notice Deploy DynamicBlueprint instance only
     * @param dynamicBlueprintsInput Dynamic Blueprint initialization input
     * @param _royalty Royalty for DBP instance
     * @param operatorFiltererInputs OpenSea operator filterer addresses
     * @param blueprintPlatformID Off-chain ID associated with DBP deployment
     */
    function deployDynamicBlueprint(
        IDynamicBlueprint.DynamicBlueprintsInput calldata dynamicBlueprintsInput,
        IRoyalty.Royalty calldata _royalty,
        IOperatorFilterer.OperatorFiltererInputs calldata operatorFiltererInputs,
        string calldata blueprintPlatformID
    ) external {
        address dynamicBlueprint = address(
            new BeaconProxy(
                dynamicBlueprintsBeacon,
                abi.encodeWithSelector(
                    DynamicBlueprint(address(0)).initialize.selector,
                    dynamicBlueprintsInput,
                    dbpDefaultRoles.defaultAdmin,
                    dbpDefaultRoles.minter,
                    _royalty,
                    dbpDefaultRoles.storefrontMinters,
                    broadcast,
                    operatorFiltererInputs
                )
            )
        );
        emit DynamicBlueprintDeployed(dynamicBlueprint, blueprintPlatformID);
    }

    /**
     * @notice Owner-only function to change the default addresses given privileges on DBP instances
     * @param newDBPDefaultRoles New DBP default roles
     */
    function changeDBPDefaultRoles(DynamicBlueprintsDefaultRoles calldata newDBPDefaultRoles) external onlyOwner {
        require(
            newDBPDefaultRoles.defaultAdmin != address(0) && newDBPDefaultRoles.minter != address(0),
            "Invalid address"
        );
        dbpDefaultRoles = newDBPDefaultRoles;
    }

    /**
     * @notice Owner-only function to change the default addresses given privileges on Expansion instances
     * @param newExpansionDefaultRoles New Expansion default roles
     */
    function changeExpansionDefaultRoles(ExpansionDefaultRoles calldata newExpansionDefaultRoles) external onlyOwner {
        require(newExpansionDefaultRoles.defaultAdmin != address(0), "Invalid address");
        expansionDefaultRoles = newExpansionDefaultRoles;
    }

    /**
     * @notice Get DBP default storefront minters
     */
    function getDBPDefaultStorefrontMinters() external view returns (address[] memory) {
        return dbpDefaultRoles.storefrontMinters;
    }

    /**
     * @notice Get Expansion default storefront minters
     */
    function getExpansionDefaultStorefrontMinters() external view returns (address[] memory) {
        return expansionDefaultRoles.storefrontMinters;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IOperatorFilterRegistry {
    function register(address registrant) external;

    function registerAndSubscribe(address registrant, address subscription) external;

    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    function unregister(address addr) external;

    function updateOperator(address registrant, address operator, bool filtered) external;

    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    function subscribe(address registrant, address registrantToSubscribe) external;

    function unsubscribe(address registrant, bool copyExistingEntries) external;

    function subscriptionOf(address addr) external returns (address registrant);

    function subscribers(address registrant) external returns (address[] memory);

    function subscriberAt(address registrant, uint256 index) external returns (address);

    function copyEntriesOf(address registrant, address registrantToCopy) external;

    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    function filteredOperators(address addr) external returns (address[] memory);

    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    function isRegistered(address addr) external returns (bool);

    function codeHashOf(address addr) external returns (bytes32);

    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./interfaces/IStorefront.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @notice Contract that is expected to be implemented by any storefront implementation
 * @author Ohimire Labs
 */
abstract contract AbstractStorefront is IStorefront, AccessControlEnumerableUpgradeable, UUPSUpgradeable {
    /**
     * @notice Denotes the purchaser type (of 3 categories that modify purchase behaviour)
     */
    enum PurchaserType {
        general,
        artist,
        platform
    }

    /**
     * @notice A mapping from sale ids to whitelisted addresses to amount of pre-sale units purchased
     */
    mapping(uint256 => mapping(address => uint32)) public whitelistedPurchases;

    /**
     * @notice Platform administrative account
     */
    address public platform;

    /**
     * @notice Platform minter
     */
    address public minterAddress;

    /**
     * @notice The number of sales on the storefront
     */
    uint256 public numSales;

    /**
     * @notice Holders of this role can execute operations requiring elevated authorization
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /**
     * @notice Track sales
     */
    mapping(uint256 => Sale) internal _sales;

    /**
     * @notice Tracks failed transfers of native gas token
     */
    mapping(address => uint256) private _failedTransferCredits;

    /**
     * @notice Reverts if caller is not authority for sale
     * @param tokenContract Token contract of sale
     */
    modifier onlyTokenContractAuthority(address tokenContract) {
        require(msg.sender == tokenContract || hasRole(MINTER_ROLE, msg.sender), "!authorized");
        _;
    }

    /**
     * @notice Checks if primary sale fee info is valid
     * @param feeInfo Primary sale fee info
     */
    modifier isPrimaryFeeInfoValid(PrimaryFeeInfo memory feeInfo) {
        require(_isPrimaryFeeInfoValid(feeInfo), "Fee invo invalid");
        _;
    }

    /**
     * @notice Checks if sale is still valid, given the sale end timestamp
     * @param _saleEndTimestamp Sale end timestamp
     */
    modifier isSaleEndTimestampCurrentlyValid(uint128 _saleEndTimestamp) {
        require(_isSaleEndTimestampCurrentlyValid(_saleEndTimestamp), "ended");
        _;
    }

    /**
     * @notice See {IStorefront-createSale}
     */
    function createSale(
        Sale calldata sale
    )
        external
        override
        onlyTokenContractAuthority(sale.tokenContract)
        isSaleEndTimestampCurrentlyValid(sale.saleEndTimestamp)
        isPrimaryFeeInfoValid(sale.primaryFee)
    {
        require(sale.saleState != SaleState.paused, "initial sale state invalid");
        uint256 saleId = numSales + 1;
        _sales[saleId] = sale;
        numSales = saleId;
        emit SaleCreated(saleId, sale.packId, sale.tokenContract);
    }

    /**
     * @notice See {IStorefront-updateSale}
     */
    function updateSale(
        uint256 saleId,
        uint64 maxPurchaseAmount,
        uint128 saleEndTimestamp,
        uint128 price,
        address erc20Token,
        bytes32 merkleroot,
        PrimaryFeeInfo calldata primaryFee,
        uint256 mintAmountArtist,
        uint256 mintAmountPlatform
    )
        external
        override
        onlyTokenContractAuthority(_sales[saleId].tokenContract)
        isSaleEndTimestampCurrentlyValid(saleEndTimestamp)
        isPrimaryFeeInfoValid(primaryFee)
    {
        // read result into memory
        Sale memory sale = _sales[saleId];
        sale.maxPurchaseAmount = maxPurchaseAmount;
        sale.saleEndTimestamp = saleEndTimestamp;
        sale.price = price;
        sale.erc20Token = erc20Token;
        sale.merkleroot = merkleroot;
        sale.primaryFee = primaryFee;
        sale.mintAmountArtist = mintAmountArtist;
        sale.mintAmountPlatform = mintAmountPlatform;
        // writeback result
        _sales[saleId] = sale;
    }

    /**
     * @notice See {IStorefront-updateSaleState}
     */
    function updateSaleState(
        uint256 saleId,
        SaleState saleState
    ) external override onlyTokenContractAuthority(_sales[saleId].tokenContract) {
        require(_isSaleStateUpdateValid(_sales[saleId].saleState, saleState, saleId), "invalid salestate update");
        _sales[saleId].saleState = saleState;
    }

    /**
     * @notice See {IStorefront-updatePrimaryFee}
     */
    function updatePrimaryFee(
        uint256 saleId,
        PrimaryFeeInfo calldata primaryFee
    ) external override onlyTokenContractAuthority(_sales[saleId].tokenContract) isPrimaryFeeInfoValid(primaryFee) {
        _sales[saleId].primaryFee = primaryFee;
    }

    /**
     * @notice See {IStorefront-updateMerkleroot}
     */
    function updateMerkleroot(
        uint256 saleId,
        bytes32 _newMerkleroot
    ) external override onlyTokenContractAuthority(_sales[saleId].tokenContract) {
        _sales[saleId].merkleroot = _newMerkleroot;
    }

    ////////////////////////////
    /// ONLY ADMIN functions ///
    ////////////////////////////

    /**
     * @notice See {IStorefront-updatePlatformAddress}
     */
    function updatePlatformAddress(address _platform) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(DEFAULT_ADMIN_ROLE, _platform);

        revokeRole(DEFAULT_ADMIN_ROLE, platform);
        platform = _platform;
    }

    /**
     * @notice See {IStorfront-withdrawAllFailedCredits}
     */
    function withdrawAllFailedCredits(address payable recipient) external override {
        uint256 amount = _failedTransferCredits[msg.sender];

        require(amount != 0, "no credits to withdraw");

        _failedTransferCredits[msg.sender] = 0;

        /* solhint-disable avoid-low-level-calls */
        (bool successfulWithdraw, ) = recipient.call{ value: amount, gas: 20000 }("");
        /* solhint-enable avoid-low-level-calls */
        require(successfulWithdraw, "withdraw failed");
    }

    /**
     * @notice See {IStorefront-getSale}
     */
    function getSale(uint256 saleId) external view override returns (Sale memory) {
        return _sales[saleId];
    }

    /**
     * @notice Initialize instance
     * @param _platform Platform address
     * @param _minter Minter address
     */
    function __AbstractStorefront_init__(address _platform, address _minter) internal onlyInitializing {
        // Initialize parent contracts
        AccessControlUpgradeable.__AccessControl_init();

        // Setup a default admin
        _setupRole(DEFAULT_ADMIN_ROLE, _platform);
        platform = _platform;

        // Setup auth role
        _setupRole(MINTER_ROLE, _minter);
        minterAddress = _minter;

        numSales = 0;
    }

    /**
     * @notice Pay primary fees owed to primary fee recipients
     * @param _sale Sale
     * @param _purchaseQuantity How many purchases on the sale are being invoked
     */
    function _payFeesAndArtist(Sale memory _sale, uint32 _purchaseQuantity) internal {
        uint256 totalPurchaseValue = _purchaseQuantity * _sale.price;
        uint256 feesPaid;

        for (uint256 i; i < _sale.primaryFee.feeBPS.length; i++) {
            uint256 fee = (totalPurchaseValue * _sale.primaryFee.feeBPS[i]) / 10000;
            feesPaid = feesPaid + fee;
            _payout(_sale.primaryFee.feeRecipients[i], _sale.erc20Token, fee);
        }
        if (totalPurchaseValue - feesPaid > 0) {
            _payout(_sale.artist, _sale.erc20Token, (totalPurchaseValue - feesPaid));
        }
    }

    /**
     * @notice Simple payment function to pay an amount of currency to a recipient
     * @param _recipient Recipient of payment
     * @param _erc20Token ERC20 token used for payment (if used)
     * @param _amount Payment amount
     */
    function _payout(address _recipient, address _erc20Token, uint256 _amount) internal {
        if (_erc20Token != address(0)) {
            IERC20(_erc20Token).transfer(_recipient, _amount);
        } else {
            // attempt to send the funds to the recipient
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = payable(_recipient).call{ value: _amount, gas: 20000 }("");
            /* solhint-enable avoid-low-level-calls */
            // if it failed, update their credit balance so they can pull it later
            if (!success) {
                /* solhint-disable reentrancy */
                _failedTransferCredits[_recipient] += _amount;
                /* solhint-enable reentrancy */
            }
        }
    }

    /**
     * @notice Validate payment and process part of it (if in ERC20)
     * @dev Doesn't send erc20 to primary fee recipients immediately, preferring n transfer + 1 transferFrom operations
     *      instead of n transferFrom operations b/c transferFrom is expensive as it checks
     *      approval storage on erc20 contract
     * @param sale Sale
     * @param purchaseQuantity How many purchases on the sale are being invoked
     */
    function _validateAndProcessPurchasePayment(Sale memory sale, uint32 purchaseQuantity) internal virtual {
        // Require valid payment
        if (sale.erc20Token == address(0)) {
            // The txn must come with a full ETH payment
            require(msg.value == purchaseQuantity * sale.price, "$ != expected");
        } else {
            // or we must be able to transfer the full purchase amount to the contract
            IERC20(sale.erc20Token).transferFrom(msg.sender, address(this), purchaseQuantity * sale.price);
        }
    }

    /**
     * @notice Validate purchase time and process quantity of purchase
     * @param sale Sale
     * @param saleId ID of sale
     * @param purchaseQuantity How many purchases on the sale are being invoked
     * @param presaleWhitelistedQuantity Whitelisted quantity to pair with address on leaf of merkle tree
     * @param proof Merkle proof for purchaser (if presale and whitelisted)
     */
    function _validatePurchaseTimeAndProcessQuantity(
        Sale memory sale,
        uint256 saleId,
        uint32 purchaseQuantity,
        uint32 presaleWhitelistedQuantity,
        bytes32[] calldata proof
    ) internal {
        // User is only guaranteed whitelisted allotment during pre-sale,
        // after sale becomes public all purchases are just routed through open public-sale
        if (_isWhitelistedAndPresale(presaleWhitelistedQuantity, proof, sale)) {
            uint32 whitelistedPurchase = whitelistedPurchases[saleId][msg.sender];
            require(whitelistedPurchase + purchaseQuantity <= presaleWhitelistedQuantity, "> whitelisted amount");
            whitelistedPurchases[saleId][msg.sender] = whitelistedPurchase + purchaseQuantity;
        } else {
            require(_isSaleOngoing(sale), "unavailable");
        }

        // Require that the purchase amount is within the sale's governance parameters
        require(
            sale.maxPurchaseAmount == 0 || purchaseQuantity <= sale.maxPurchaseAmount,
            "cannot buy > maxPurchaseAmount in one tx"
        );
    }

    /**
     * @notice Asserts that it is valid to update a sale's state from prev to new
     * @param prevState Previous sale state
     * @param newState New sale state
     * @param saleId ID of sale being updated
     */
    function _isSaleStateUpdateValid(SaleState prevState, SaleState newState, uint256 saleId) internal returns (bool) {
        if (prevState == SaleState.not_started) {
            emit SaleStarted(saleId);
            return newState == SaleState.started;
        } else if (prevState == SaleState.started) {
            emit SalePaused(saleId);
            return newState == SaleState.paused;
        } else if (prevState == SaleState.paused) {
            emit SaleUnpaused(saleId);
            return newState == SaleState.started;
        } else {
            // should never reach here
            return false;
        }
    }

    /* solhint-disable no-empty-blocks */
    /**
     * @notice See {UUPSUpgradeable-_authorizeUpgrade}
     * @param // New implementation to upgrade to
     */
    function _authorizeUpgrade(address) internal override onlyRole(DEFAULT_ADMIN_ROLE) {}

    /* solhint-enable no-empty-blocks */

    /**
     * @notice Return the purchaser's type
     * @param saleArtist Sale's artist
     * @param purchaser Purchaser who's type is returned
     */
    function _getPurchaserType(address saleArtist, address purchaser) internal view returns (PurchaserType) {
        if (purchaser == saleArtist) {
            return PurchaserType.artist;
        } else if (hasRole(MINTER_ROLE, purchaser)) {
            return PurchaserType.platform;
        } else {
            return PurchaserType.general;
        }
    }

    /**
     * @notice Checks if sale is still valid, given the sale end timestamp
     * @param _saleEndTimestamp Sale end timestamp
     */
    function _isSaleEndTimestampCurrentlyValid(uint128 _saleEndTimestamp) internal view returns (bool) {
        return _saleEndTimestamp > block.timestamp || _saleEndTimestamp == 0;
    }

    /**
     * @notice Validates that sale is still ongoing
     * @param sale Sale
     */
    function _isSaleOngoing(Sale memory sale) internal view returns (bool) {
        return sale.saleState == SaleState.started && _isSaleEndTimestampCurrentlyValid(sale.saleEndTimestamp);
    }

    /**
     * @notice Checks if user whitelisted for presale purchase
     * @param _whitelistedQuantity Purchaser's requested quantity. Validated against merkle tree
     * @param proof Merkle tree proof to use to validate account's inclusion in tree as leaf
     * @param sale The sale
     */
    function _isWhitelistedAndPresale(
        uint32 _whitelistedQuantity,
        bytes32[] calldata proof,
        Sale memory sale
    ) internal view returns (bool) {
        return (sale.saleState == SaleState.not_started &&
            _verify(_leaf(msg.sender, uint256(_whitelistedQuantity)), sale.merkleroot, proof));
    }

    /**
     * @notice Checks if primary sale fee info is valid
     * @param _feeInfo Primary sale fee info
     */
    function _isPrimaryFeeInfoValid(PrimaryFeeInfo memory _feeInfo) internal pure returns (bool) {
        uint totalBPS = 0;
        uint256 feeInfoLength = _feeInfo.feeBPS.length;
        for (uint i = 0; i < feeInfoLength; i++) {
            totalBPS += _feeInfo.feeBPS[i];
        }
        // Total payment distribution must be 100% and the fee recipients and allocation arrays must be equal size
        return totalBPS == 10000 && feeInfoLength == _feeInfo.feeRecipients.length;
    }

    ////////////////////////////////////
    ////// MERKLEROOT FUNCTIONS ////////
    ////////////////////////////////////

    /**
     * @notice Create a merkle tree with address: quantity pairs as the leaves.
     *      The msg.sender will be verified if it has a corresponding quantity value in the merkletree
     * @param account Minting account being verified
     * @param quantity Quantity to mint, being verified
     */
    function _leaf(address account, uint256 quantity) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, quantity));
    }

    /**
     * @notice Verify a leaf's inclusion in a merkle tree with its root and corresponding proof
     * @param leaf Leaf to verify
     * @param merkleroot Merkle tree's root
     * @param proof Corresponding proof for leaf
     */
    function _verify(bytes32 leaf, bytes32 merkleroot, bytes32[] memory proof) internal pure returns (bool) {
        return MerkleProof.verify(proof, merkleroot, leaf);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

/**
 * @notice Dynamic Blueprint and Expansion storefront interface
 * @author Ohimire Labs
 */
interface IStorefront {
    /**
     * @notice Denotes statate of sale
     */
    enum SaleState {
        not_started,
        started,
        paused
    }

    /**
     * @notice Sale data
     * @param maxPurchaseAmount Max number of purchases allowed in one tx on this sale
     * @param saleEndTimestamp Marks end of sale
     * @param price Price of each purchase of sale
     * @param packId ID of pack that sale is for (if for expansion pack). O if sale is for DBP
     * @param erc20Token Address of erc20 currency that payments must be made in. 0 address if in native gas token
     * @param merkleroot Root of merkle tree containing allowlist
     * @param saleState State of sale
     * @param tokenContract Address of contract where tokens to be minted in sale are
     * @param artist Sale artist
     * @param primaryFee Fee split on sales
     * @param mintAmountArtist How many purchases the artist can mint for free
     * @param mintAmountPlatform How many purchases the platform can mint for free
     */
    struct Sale {
        uint64 maxPurchaseAmount;
        uint128 saleEndTimestamp;
        uint128 price;
        uint256 packId;
        address erc20Token;
        bytes32 merkleroot;
        SaleState saleState;
        address tokenContract;
        address artist;
        PrimaryFeeInfo primaryFee;
        uint256 mintAmountArtist;
        uint256 mintAmountPlatform;
    }

    /**
     * @notice Object holding primary fee data
     * @param feeBPS Primary fee percentage allocations in basis points,
     *               should always add up to 10,000 and include the creator to payout
     * @param feeRecipients Primary fee recipients, including the artist/creator
     */
    struct PrimaryFeeInfo {
        uint32[] feeBPS;
        address[] feeRecipients;
    }

    /**
     * @notice Emitted when a new sale is created
     * @param saleId the ID of the sale which was just created
     * @param packId the ID of the pack which will be sold in the created sale
     * @param tokenContract the ID of the DBP/Expansion contract where the pack on sale was created
     */
    event SaleCreated(uint256 indexed saleId, uint256 indexed packId, address indexed tokenContract);

    /**
     * @notice Emitted when a sale is started
     * @param saleId ID of sale
     */
    event SaleStarted(uint256 indexed saleId);

    /**
     * @notice Emitted when a sale is paused
     * @param saleId ID of sale
     */
    event SalePaused(uint256 indexed saleId);

    /**
     * @notice Emitted when a sale is unpaused
     * @param saleId ID of sale
     */
    event SaleUnpaused(uint256 indexed saleId);

    /**
     * @notice Create a sale
     * @param sale Sale being created
     */
    function createSale(Sale calldata sale) external;

    /**
     * @notice Update a sale
     * @param saleId ID of sale being updated
     * @param maxPurchaseAmount New max purchase amount
     * @param saleEndTimestamp New sale end timestamp
     * @param price New price
     * @param erc20Token New ERC20 token
     * @param merkleroot New merkleroot
     * @param primaryFee New primaryFee
     * @param mintAmountArtist New mintAmountArtist
     * @param mintAmountPlatform New mintAmountPlatform
     */
    function updateSale(
        uint256 saleId,
        uint64 maxPurchaseAmount,
        uint128 saleEndTimestamp,
        uint128 price,
        address erc20Token,
        bytes32 merkleroot,
        PrimaryFeeInfo calldata primaryFee,
        uint256 mintAmountArtist,
        uint256 mintAmountPlatform
    ) external;

    /**
     * @notice Update a sale's state
     * @param saleId ID of sale that's being updated
     * @param saleState New sale state
     */
    function updateSaleState(uint256 saleId, SaleState saleState) external;

    /**
     * @notice Withdraw credits of native gas token that failed to send
     * @param recipient Recipient that was meant to receive failed payment
     */
    function withdrawAllFailedCredits(address payable recipient) external;

    /**
     * @notice Update primary fee for a sale
     * @param saleId ID of sale being updated
     * @param primaryFee New primary fee for sale
     */
    function updatePrimaryFee(uint256 saleId, PrimaryFeeInfo calldata primaryFee) external;

    /**
     * @notice Update merkleroot for a sale
     * @param saleId ID of sale being updated
     * @param _newMerkleroot New merkleroot for sale
     */
    function updateMerkleroot(uint256 saleId, bytes32 _newMerkleroot) external;

    /**
     * @notice Update the platform address
     * @param _platform New platform
     */
    function updatePlatformAddress(address _platform) external;

    /**
     * @notice Return a sale based on its sale ID
     * @param saleId ID of sale being returned
     */
    function getSale(uint256 saleId) external view returns (Sale memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "./interfaces/IStorefront.sol";
import "../expansion/interfaces/IExpansion.sol";
import "./AbstractStorefront.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Expansion storefront that facilitates purchases of randomly dispersed tokens in a RandomItem in a pack,
 *         via a 2 phase purchase process
 * @author Ohimire Labs
 */
contract RandomExpansionStorefront is AbstractStorefront {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    /**
     * @notice Data containing information on how to calculate a purchaser's expected gas cost.
     *         Pack purchasers must front the gas cost for the purchase fulfillment sent by AsyncArt.
     * @param operationBaseCompute Upper bound on base gas units consumed by a purchase fulfillment tx
     * @param perPackCompute Upper bound on base gas consumed to purchase a pack
     * @param perItemMintCompute Upper bound on cost to mint each item in a given pack
     * @param baseFeeMultiplier Multiplier on block.basefee used to account for uncertainty in future network state
     * @param baseFeeDenominator Denominator for block.basefee used to account for uncertainty in future network state
     * @param minerTip the tip that Async will specify for all purchase fulfillment transactions
     */
    struct FulfillmentGasConstants {
        uint64 operationBaseCompute;
        uint64 perPackCompute;
        uint32 perItemMintCompute;
        uint16 baseFeeMultiplier;
        uint16 baseFeeDenominator;
        uint64 minerTip;
    }

    /**
     * @notice The number of random expansion purchases made, used to id each purchase
     */
    uint256 public numRandomExpansionPurchases;

    /**
     * @notice Account expected to fulfill purchase requests
     */
    address payable public platformPurchaseFulfiller;

    /**
     * @notice Contract's instance of gas constants
     */
    FulfillmentGasConstants public fulfillmentGasConstants;

    /**
     * @notice Track processed purchases to avoid double spending
     */
    EnumerableSetUpgradeable.UintSet private _processedPurchases;

    /**
     * @notice The number of outstanding purchase requests for an expansion pack
     */
    mapping(uint256 => uint64) private _packIdToOutstandingMintRequests;

    /**
     * @notice Emitted when a user makes a request to purchase an expansion pack with random distribution strategy
     * @param purchaseId Purchase ID
     * @param saleId ID of sale
     * @param purchaseQuantity How many times a sale is purchased in one process
     * @param requestingPurchaser The initial purchaser
     * @param nftRecipient The recipient to send the randomly minted NFTs to
     * @param isAllocatedForFree The "purchase request" is part of the platform/artist's free allocation
     * @param prefixHash The prefix of the hash used by AsyncArt to determine the random Expanion items to be minted
     * @param gasSurcharge The amount of eth the requestingPurchaser was required to
     *                     front for the fulfillment transaction
     */
    event RandomExpansionPackPurchaseRequest(
        uint256 purchaseId,
        uint256 saleId,
        uint32 purchaseQuantity,
        address requestingPurchaser,
        address nftRecipient,
        bool isAllocatedForFree,
        bytes32 prefixHash,
        uint256 gasSurcharge
    );

    /**
     * @notice Emitted when Async fulfills a request to purchase an expansion pack
     * @param purchaseId Purchase ID
     */
    event PurchaseRequestFulfilled(uint256 purchaseId);

    /**
     * @notice Reverts if caller is not platform fulfiller
     */
    modifier onlyFulfiller() {
        require(msg.sender == platformPurchaseFulfiller, "Not fulfiller");
        _;
    }

    /**
     * @notice Initialize storefront instance
     * @param platform Platform account
     * @param minter Platform minter account
     * @param fulfiller Platform fulfiller account
     * @param _fulfillmentGasConstants Fulfillment gas constants
     */
    function initialize(
        address platform,
        address minter,
        address payable fulfiller,
        FulfillmentGasConstants calldata _fulfillmentGasConstants
    ) external initializer {
        // Initialize parent contracts
        __AbstractStorefront_init__(platform, minter);

        // Initialize state variables
        platformPurchaseFulfiller = fulfiller;
        fulfillmentGasConstants = _fulfillmentGasConstants;
    }

    /**
     * @notice Request a number of free pre-allocated pack mints, used by the artist and platform
     * @param saleId ID of sale
     * @param mintQuantity The number of pack mints which are desired
     * @param nftRecipient Recipient of minted NFTs
     */
    function requestFreeAllocatedPacks(uint256 saleId, uint32 mintQuantity, address nftRecipient) external payable {
        Sale memory sale = _sales[saleId];
        require(sale.packId != 0, "zero packId");

        PurchaserType purchaserType = _getPurchaserType(sale.artist, msg.sender);

        // Validate that the requestFreeAllocatedPacks caller is either the artist or the platform
        // and decrement the account's free pack allocation
        if (purchaserType == PurchaserType.artist) {
            require(mintQuantity <= sale.mintAmountArtist, "quantity >");
            _sales[saleId].mintAmountArtist -= mintQuantity;

            // validate that the artist provided enough gas to cover async's subsequent fulfilling transaction
            uint256 gasCost = _getGasSurcharge(sale, mintQuantity, block.basefee);
            require(msg.value >= gasCost, "$ < fulfilling gas");
            _transferGasCostToFulfiller(gasCost);
        } else if (purchaserType == PurchaserType.platform) {
            require(mintQuantity <= sale.mintAmountPlatform, "quantity >");
            _sales[saleId].mintAmountPlatform -= mintQuantity;
        } else {
            revert("!authorized");
        }

        uint64 numMintRequests = _packIdToOutstandingMintRequests[sale.packId];
        IExpansion.Pack memory packForSale = IExpansion(sale.tokenContract).getPack(sale.packId);

        // require that this mint request is fulfillable
        require(
            numMintRequests + mintQuantity + packForSale.mintedCount <= packForSale.capacity ||
                packForSale.capacity == 0,
            "cant service req"
        );

        numRandomExpansionPurchases += 1;
        _packIdToOutstandingMintRequests[sale.packId] = numMintRequests + mintQuantity;

        emit RandomExpansionPackPurchaseRequest(
            numRandomExpansionPurchases,
            saleId,
            mintQuantity,
            msg.sender,
            nftRecipient,
            true,
            _getPrefixHash(),
            msg.value
        );
    }

    /**
     * @notice Request a number of purchases on a sale, receving randomly distributed expansion NFTs
     * @param saleId ID of sale
     * @param purchaseQuantity How many times the sale is being purchased in a process
     * @param presaleWhitelistedQuantity Whitelisted quantity to pair with address on leaf of merkle tree
     * @param proof Merkle proof for purchaser (if presale and whitelisted)
     * @param nftRecipient Recipient of minted NFTs
     */
    function requestPurchaseExpansionPacks(
        uint256 saleId,
        uint32 purchaseQuantity,
        uint32 presaleWhitelistedQuantity,
        bytes32[] calldata proof,
        address nftRecipient
    ) external payable {
        Sale memory sale = _sales[saleId];
        require(sale.packId != 0, "zero packId");

        _validatePurchaseTimeAndProcessQuantity(sale, saleId, purchaseQuantity, presaleWhitelistedQuantity, proof);
        uint64 numMintRequests = _packIdToOutstandingMintRequests[sale.packId];
        IExpansion.Pack memory packForSale = IExpansion(sale.tokenContract).getPack(sale.packId);

        // require that this purchase request is fulfillable
        require(
            numMintRequests + purchaseQuantity + packForSale.mintedCount <= packForSale.capacity ||
                packForSale.capacity == 0,
            "cant service req"
        );

        uint256 gasDeposit = _validateAndProcessPurchasePaymentRandom(sale, purchaseQuantity);

        numRandomExpansionPurchases += 1;
        _packIdToOutstandingMintRequests[sale.packId] = numMintRequests + purchaseQuantity;
        emit RandomExpansionPackPurchaseRequest(
            numRandomExpansionPurchases,
            saleId,
            purchaseQuantity,
            msg.sender,
            nftRecipient,
            false,
            _getPrefixHash(),
            gasDeposit
        );
    }

    /**
     * @notice Execute a purchase request, minting the randomly generated token ids on a pack
     * @param purchaseId Purchase ID
     * @param saleId ID of sale
     * @param nftRecipient Recipient of minted NFTs
     * @param requestingPurchaser The initial purchaser
     * @param tokenIdCombinations The different, unique token id combinations being minted on a pack
     * @param numCombinationPurchases The number of times each unique combination should be minted
     * @param isForFreeAllocation Response to request to mint (part of) artist/platform's free expansion pack allocation
     */
    function executePurchaseExpansionPacks(
        uint256 purchaseId,
        uint256 saleId,
        address nftRecipient,
        address requestingPurchaser,
        uint256[][] calldata tokenIdCombinations,
        uint32[] calldata numCombinationPurchases,
        bool isForFreeAllocation
    ) external payable onlyFulfiller {
        // process purchase
        require(_processedPurchases.add(purchaseId), "Purchase already processed");

        uint32 purchaseQuantity = 0;
        for (uint i = 0; i < numCombinationPurchases.length; i++) {
            purchaseQuantity += numCombinationPurchases[i];
        }

        Sale memory sale = _sales[saleId];
        require(sale.packId != 0, "zero packId"); // reserved for DBP

        if (!isForFreeAllocation) {
            _payFeesAndArtist(sale, purchaseQuantity);
        }

        if (tokenIdCombinations.length == 1) {
            // gas optimization for common case, call lighter-weight method
            IExpansion(sale.tokenContract).mintSameCombination(
                sale.packId,
                tokenIdCombinations[0],
                numCombinationPurchases[0],
                nftRecipient
            );
        } else {
            IExpansion(sale.tokenContract).mintDifferentCombination(
                sale.packId,
                tokenIdCombinations,
                numCombinationPurchases,
                nftRecipient
            );
        }
        // record that the purchase has been fulfilled
        _packIdToOutstandingMintRequests[sale.packId] -= purchaseQuantity;

        // If Async fulfiller provided a gas refund amount, transfer it back to the requesting purchaser
        if (msg.value > 0) {
            /* solhint-disable avoid-low-level-calls */
            (bool success, ) = requestingPurchaser.call{ value: msg.value }("");
            /* solhint-enable avoid-low-level-calls */
            require(success, "gas refund transfer failed");
        }

        emit PurchaseRequestFulfilled(purchaseId);
    }

    /**
     * @notice Admin function to update the gas constants
     * @param newFulfillmentGasConstants New gas constants
     */
    function updateFulfillmentGasConstants(
        FulfillmentGasConstants calldata newFulfillmentGasConstants
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        fulfillmentGasConstants = newFulfillmentGasConstants;
    }

    /**
     * @notice Admin function to update the authorized fulifller
     * @param newFulfiller New fulfiller
     */
    function updatePlatformFulfiller(address payable newFulfiller) external onlyRole(DEFAULT_ADMIN_ROLE) {
        platformPurchaseFulfiller = newFulfiller;
    }

    /**
     * @notice Get the IDs of processed purchases
     */
    function getProcessedPurchases() external view returns (uint256[] memory) {
        return _processedPurchases.values();
    }

    /**
     * @notice Return true if a purchase has been processed
     * @param purchaseId ID of purchase being checked
     */
    function isPurchaseProcessed(uint256 purchaseId) external view returns (bool) {
        return _processedPurchases.contains(purchaseId);
    }

    /**
     * @notice Return the estimated excess gas a random purchase requester should provide in addition to
     *         the purchase price in order to successful submit their purchase request.
     * @param saleId The id of the sale on the pack which the user wants to purchase
     * @param purchaseQuantity The number of packs of the sale that the user wants to purchase
     * @param blockBaseFee The base fee of a recent block to anchor the estimate
     */
    function estimateGasSurcharge(
        uint256 saleId,
        uint256 purchaseQuantity,
        uint256 blockBaseFee
    ) external view returns (uint256) {
        return _getGasSurcharge(_sales[saleId], purchaseQuantity, blockBaseFee);
    }

    /**
     * @notice Return the estimated excess gas a random purchase requester should provide in addition
     *         to the purchase price in order to successful submit their purchase request.
     * @param sale The sale on the pack which the user wants to purchase
     * @param purchaseQuantity The number of packs of the sale that the user wants to purchase
     * @param blockBaseFee The basefee of a reference block
     */
    function _getGasSurcharge(
        Sale memory sale,
        uint256 purchaseQuantity,
        uint256 blockBaseFee
    ) internal view returns (uint256) {
        uint256 numItems = IExpansion(sale.tokenContract).getPack(sale.packId).itemSizes.length;
        FulfillmentGasConstants memory gasConstants = fulfillmentGasConstants;
        uint256 gasUnitEstimate = gasConstants.operationBaseCompute +
            ((gasConstants.perPackCompute + (numItems * gasConstants.perItemMintCompute)) * purchaseQuantity);
        uint256 estimatedFulfillmentBaseFee = (blockBaseFee * gasConstants.baseFeeMultiplier) /
            gasConstants.baseFeeDenominator;
        return (estimatedFulfillmentBaseFee + gasConstants.minerTip) * gasUnitEstimate;
    }

    /**
     * @notice Validate purchase and process payment. Returns the total size of the user's gas deposit.
     * @param sale Sale
     * @param purchaseQuantity How many times the sale is being purchased in a process
     */
    function _validateAndProcessPurchasePaymentRandom(
        Sale memory sale,
        uint32 purchaseQuantity
    ) private returns (uint256) {
        // Compute minimum gasSurcharge given current network state
        uint256 gasSurcharge = _getGasSurcharge(sale, purchaseQuantity, block.basefee);
        uint256 gasDeposit = msg.value;
        // Require valid payment
        if (sale.erc20Token == address(0)) {
            require(msg.value >= purchaseQuantity * sale.price + gasSurcharge, "$ < expected");
            gasDeposit = gasDeposit - (purchaseQuantity * sale.price);
        } else {
            require(msg.value >= gasSurcharge, "gas $ < expected");
            IERC20(sale.erc20Token).transferFrom(msg.sender, address(this), purchaseQuantity * sale.price);
        }
        _transferGasCostToFulfiller(gasDeposit);
        return gasDeposit;
    }

    /**
     * @notice Transfer the gas cost for a purchase fulfillment transaction to the AsyncArt platform purchase fulfiller
     * @param gasCost The amount of ether to transfer to the fulfiller account
     */
    function _transferGasCostToFulfiller(uint256 gasCost) private {
        /* solhint-disable avoid-low-level-calls */
        (bool success, ) = platformPurchaseFulfiller.call{ value: gasCost }("");
        /* solhint-enable avoid-low-level-calls */
        require(success, "fulfiller payment failed");
    }

    /**
     * @notice returns the prefix of the hash used by AsyncArt to determine which random tokens to mint
     */
    function _getPrefixHash() private view returns (bytes32) {
        return keccak256(abi.encodePacked(block.number, block.timestamp, block.coinbase));
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./AbstractStorefront.sol";
import "../blueprints/interfaces/IDynamicBlueprint.sol";

/**
 * @notice DBP storefront that facilitates purchases of DBP NFTs
 * @author Ohimire Labs
 */
contract SimpleDBPStorefront is AbstractStorefront {
    /**
     * @notice Emitted when DBPs are purchased
     * @param saleId ID of sale
     * @param purchaser Purchase transaction sender
     * @param quantity Amount purchased / minted
     */
    event DBPPurchased(uint256 indexed saleId, address indexed purchaser, uint32 quantity);

    /**
     * @notice Initiliaze the instance
     * @param platform Platform address
     * @param minter Minter address
     */
    function initialize(address platform, address minter) external initializer {
        // Initialize parent contracts
        __AbstractStorefront_init__(platform, minter);
    }

    /**
     * @notice Complimentary minting available in limited quantity to AsyncArt/DBP artists depending on config params
     * @param saleId Sale ID for the DBP
     * @param mintQuantity Number of NFTs to mint (should be within pre-configured limits)
     * @param nftRecipient Recipient of minted NFTs
     */
    function freeMint(uint256 saleId, uint32 mintQuantity, address nftRecipient) external payable {
        Sale memory sale = _sales[saleId];
        require(sale.packId == 0, "non-zero packId");

        PurchaserType purchaserType = _getPurchaserType(sale.artist, msg.sender);

        // Validate that the freeMint user is either the artist or the platform
        // and decrement the account's freeMint allocation
        if (purchaserType == PurchaserType.artist) {
            require(mintQuantity <= sale.mintAmountArtist, "quantity >");
            _sales[saleId].mintAmountArtist -= mintQuantity;
        } else if (purchaserType == PurchaserType.platform) {
            require(mintQuantity <= sale.mintAmountPlatform, "quantity >");
            _sales[saleId].mintAmountPlatform -= mintQuantity;
        } else {
            revert("!authorized");
        }

        IDynamicBlueprint(sale.tokenContract).mintBlueprints(mintQuantity, nftRecipient);

        emit DBPPurchased(saleId, msg.sender, mintQuantity);
    }

    /**
     * @notice Purchase dynamic blueprint NFTs on an active sale
     * @param saleId Sale ID
     * @param purchaseQuantity How many times the sale is being purchased in this transaction
     * @param presaleWhitelistedQuantity Whitelisted quantity to pair with address on leaf of merkle tree
     * @param proof Merkle proof for purchaser (if presale and whitelisted)
     * @param nftRecipient Recipient of minted NFTs
     */
    function purchaseDynamicBlueprints(
        uint256 saleId,
        uint32 purchaseQuantity,
        uint32 presaleWhitelistedQuantity,
        bytes32[] calldata proof,
        address nftRecipient
    ) external payable {
        Sale memory sale = _sales[saleId];
        require(sale.packId == 0, "non-zero packId");

        _validatePurchaseTimeAndProcessQuantity(sale, saleId, purchaseQuantity, presaleWhitelistedQuantity, proof);

        _validateAndProcessPurchasePayment(sale, purchaseQuantity);
        _payFeesAndArtist(sale, purchaseQuantity);

        IDynamicBlueprint(sale.tokenContract).mintBlueprints(purchaseQuantity, nftRecipient);

        emit DBPPurchased(saleId, msg.sender, presaleWhitelistedQuantity);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "../expansion/interfaces/IExpansion.sol";
import "./AbstractStorefront.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @notice Expansion storefront that facilitates purchases of chosen tokens on a pack, chosen by purchaser
 * @author Ohimire Labs
 */
contract SimpleExpansionStorefront is AbstractStorefront {
    /**
     * @notice Emitted when simple expansion packs are purchased
     * @param saleId ID of sale
     * @param purchaser Purchase transaction sender
     * @param numPurchases Number of purchases on the pack
     * @param tokenIds Chosen tokenIds purchased on the pack
     */
    event SimpleExpansionPackPurchased(
        uint256 indexed saleId,
        address indexed purchaser,
        uint32 numPurchases,
        uint256[] tokenIds
    );

    /**
     * @notice Initialize instance
     * @param platform Platform address
     * @param minter Minter address
     */
    function initialize(address platform, address minter) external initializer {
        // Initialize parent contracts
        __AbstractStorefront_init__(platform, minter);
    }

    /**
     * @notice Mint free packs
     * @param saleId Sale ID
     * @param nftRecipient Recipient of minted NFTs
     * @param tokenIds Tokens to mint on pack, each token must be part of a unique item in the pack
     * @param numPurchases How many of each token to mint
     */
    function mintFreePacks(
        uint256 saleId,
        address nftRecipient,
        uint256[] calldata tokenIds,
        uint32 numPurchases
    ) external payable {
        Sale memory sale = _sales[saleId];
        require(sale.packId != 0, "zero packId");

        PurchaserType purchaserType = _getPurchaserType(sale.artist, msg.sender);

        // Validate that the mintFreePacks user is either the artist or the platform
        // and decrement the account's freeMint allocation
        if (purchaserType == PurchaserType.artist) {
            require(numPurchases <= sale.mintAmountArtist, "quantity >");
            _sales[saleId].mintAmountArtist -= numPurchases;
        } else if (purchaserType == PurchaserType.platform) {
            require(numPurchases <= sale.mintAmountPlatform, "quantity >");
            _sales[saleId].mintAmountPlatform -= numPurchases;
        } else {
            revert("!authorized");
        }

        IExpansion(sale.tokenContract).mintSameCombination(sale.packId, tokenIds, numPurchases, nftRecipient);

        emit SimpleExpansionPackPurchased(saleId, msg.sender, numPurchases, tokenIds);
    }

    /**
     * @notice Purchase dynamic blueprint NFTs on an active sale
     * @param saleId Sale ID
     * @param presaleWhitelistedQuantity Whitelisted quantity to pair with address on leaf of merkle tree
     * @param proof Merkle proof for purchaser (if presale and whitelisted)
     * @param nftRecipient Recipient of minted NFTs
     * @param tokenIds Tokens to mint on pack, each token must be part of a unique item in the pack
     * @param numPurchases How many of each token to mint
     */
    function purchaseExpansionPacks(
        uint256 saleId,
        uint32 presaleWhitelistedQuantity,
        bytes32[] calldata proof,
        address nftRecipient,
        uint256[] calldata tokenIds,
        uint32 numPurchases
    ) external payable {
        Sale memory sale = _sales[saleId];
        require(sale.packId != 0, "zero packId");

        _validatePurchaseTimeAndProcessQuantity(sale, saleId, numPurchases, presaleWhitelistedQuantity, proof);

        _validateAndProcessPurchasePayment(sale, numPurchases);
        _payFeesAndArtist(sale, numPurchases);

        IExpansion(sale.tokenContract).mintSameCombination(sale.packId, tokenIds, numPurchases, nftRecipient);

        emit SimpleExpansionPackPurchased(saleId, msg.sender, numPurchases, tokenIds);
    }
}