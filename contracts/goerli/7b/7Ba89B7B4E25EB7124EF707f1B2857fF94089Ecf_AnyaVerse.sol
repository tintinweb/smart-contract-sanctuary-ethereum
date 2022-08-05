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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal onlyInitializing {
    }

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );

    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    event RevokedOperator(address indexed operator, address indexed tokenHolder);
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

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

import { ISuperAgreement } from "../superfluid/ISuperAgreement.sol";
import { ISuperfluidToken } from "../superfluid/ISuperfluidToken.sol";


/**
 * @title Instant Distribution Agreement interface
 * @author Superfluid
 *
 * @notice 
 *   - A publisher can create as many as indices as possibly identifiable with `indexId`.
 *     - `indexId` is deliberately limited to 32 bits, to avoid the chance for sha-3 collision.
 *       Despite knowing sha-3 collision is only theoretical.
 *   - A publisher can create a subscription to an index for any subscriber.
 *   - A subscription consists of:
 *     - The index it subscribes to.
 *     - Number of units subscribed.
 *   - An index consists of:
 *     - Current value as `uint128 indexValue`.
 *     - Total units of the approved subscriptions as `uint128 totalUnitsApproved`.
 *     - Total units of the non approved subscription as `uint128 totalUnitsPending`.
 *   - A publisher can update an index with a new value that doesn't decrease.
 *   - A publisher can update a subscription with any number of units.
 *   - A publisher or a subscriber can delete a subscription and reset its units to zero.
 *   - A subscriber must approve the index in order to receive distributions from the publisher
 *     each time the index is updated.
 *     - The amount distributed is $$\Delta{index} * units$$
 *   - Distributions to a non approved subscription stays in the publisher's deposit until:
 *     - the subscriber approves the subscription (side effect),
 *     - the publisher updates the subscription (side effect),
 *     - the subscriber deletes the subscription even if it is never approved (side effect),
 *     - or the subscriber can explicitly claim them.
 */
abstract contract IInstantDistributionAgreementV1 is ISuperAgreement {

    /// @dev ISuperAgreement.agreementType implementation
    function agreementType() external override pure returns (bytes32) {
        return keccak256("org.superfluid-finance.agreements.InstantDistributionAgreement.v1");
    }

    /**************************************************************************
     * Index operations
     *************************************************************************/

    /**
     * @dev Create a new index for the publisher
     * @param token Super token address
     * @param indexId Id of the index
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     *
     * @custom:callbacks 
     * None
     */
    function createIndex(
        ISuperfluidToken token,
        uint32 indexId,
        bytes calldata ctx)
            external
            virtual
            returns(bytes memory newCtx);
    /**
    * @dev Index created event
    * @param token Super token address
    * @param publisher Index creator and publisher
    * @param indexId The specified indexId of the newly created index
    * @param userData The user provided data
    */
    event IndexCreated(
        ISuperfluidToken indexed token,
        address indexed publisher,
        uint32 indexed indexId,
        bytes userData);

    /**
     * @dev Query the data of a index
     * @param token Super token address
     * @param publisher The publisher of the index
     * @param indexId Id of the index
     * @return exist Does the index exist
     * @return indexValue Value of the current index
     * @return totalUnitsApproved Total units approved for the index
     * @return totalUnitsPending Total units pending approval for the index
     */
    function getIndex(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId)
            external
            view
            virtual
            returns(
                bool exist,
                uint128 indexValue,
                uint128 totalUnitsApproved,
                uint128 totalUnitsPending);

    /**
     * @dev Calculate actual distribution amount
     * @param token Super token address
     * @param publisher The publisher of the index
     * @param indexId Id of the index
     * @param amount The amount of tokens desired to be distributed
     * @return actualAmount The amount to be distributed after ensuring no rounding errors
     * @return newIndexValue The index value given the desired amount of tokens to be distributed
     */
    function calculateDistribution(
       ISuperfluidToken token,
       address publisher,
       uint32 indexId,
       uint256 amount)
           external view
           virtual
           returns(
               uint256 actualAmount,
               uint128 newIndexValue);

    /**
     * @dev Update index value of an index
     * @param token Super token address
     * @param indexId Id of the index
     * @param indexValue Value of the index
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     *
     * @custom:callbacks 
     * None
     */
    function updateIndex(
        ISuperfluidToken token,
        uint32 indexId,
        uint128 indexValue,
        bytes calldata ctx)
            external
            virtual
            returns(bytes memory newCtx);
    /**
      * @dev Index updated event
      * @param token Super token address
      * @param publisher Index updater and publisher
      * @param indexId The specified indexId of the updated index
      * @param oldIndexValue The previous index value
      * @param newIndexValue The updated index value
      * @param totalUnitsPending The total units pending when the indexValue was updated
      * @param totalUnitsApproved The total units approved when the indexValue was updated
      * @param userData The user provided data
      */
    event IndexUpdated(
        ISuperfluidToken indexed token,
        address indexed publisher,
        uint32 indexed indexId,
        uint128 oldIndexValue,
        uint128 newIndexValue,
        uint128 totalUnitsPending,
        uint128 totalUnitsApproved,
        bytes userData);

    /**
     * @dev Distribute tokens through the index
     * @param token Super token address
     * @param indexId Id of the index
     * @param amount The amount of tokens desired to be distributed
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     *
     * @custom:note 
     * - This is a convenient version of updateIndex. It adds to the index
     *   a delta that equals to `amount / totalUnits`
     * - The actual amount distributed could be obtained via
     *   `calculateDistribution`. This is due to precision error with index
     *   value and units data range
     *
     * @custom:callbacks 
     * None
     */
    function distribute(
        ISuperfluidToken token,
        uint32 indexId,
        uint256 amount,
        bytes calldata ctx)
            external
            virtual
            returns(bytes memory newCtx);


    /**************************************************************************
     * Subscription operations
     *************************************************************************/

    /**
     * @dev Approve the subscription of an index
     * @param token Super token address
     * @param publisher The publisher of the index
     * @param indexId Id of the index
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     *
     * @custom:callbacks 
     * - if subscription exist
     *   - AgreementCreated callback to the publisher:
     *      - agreementId is for the subscription
     * - if subscription does not exist
     *   - AgreementUpdated callback to the publisher:
     *      - agreementId is for the subscription
     */
    function approveSubscription(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        bytes calldata ctx)
            external
            virtual
            returns(bytes memory newCtx);
    /**
      * @dev Index subscribed event
      * @param token Super token address
      * @param publisher Index publisher
      * @param indexId The specified indexId
      * @param subscriber The approved subscriber
      * @param userData The user provided data
      */
    event IndexSubscribed(
        ISuperfluidToken indexed token,
        address indexed publisher,
        uint32 indexed indexId,
        address subscriber,
        bytes userData);

    /**
      * @dev Subscription approved event
      * @param token Super token address
      * @param subscriber The approved subscriber
      * @param publisher Index publisher
      * @param indexId The specified indexId
      * @param userData The user provided data
      */
    event SubscriptionApproved(
        ISuperfluidToken indexed token,
        address indexed subscriber,
        address publisher,
        uint32 indexId,
        bytes userData);

    /**
    * @notice Revoke the subscription of an index
    * @dev "Unapproves" the subscription and moves approved units to pending
    * @param token Super token address
    * @param publisher The publisher of the index
    * @param indexId Id of the index
    * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
    *
    * @custom:callbacks 
    * - AgreementUpdated callback to the publisher:
    *    - agreementId is for the subscription
    */
    function revokeSubscription(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        bytes calldata ctx)
         external
         virtual
         returns(bytes memory newCtx);
    /**
      * @dev Index unsubscribed event
      * @param token Super token address
      * @param publisher Index publisher
      * @param indexId The specified indexId
      * @param subscriber The unsubscribed subscriber
      * @param userData The user provided data
      */
    event IndexUnsubscribed(
        ISuperfluidToken indexed token,
        address indexed publisher,
        uint32 indexed indexId,
        address subscriber,
        bytes userData);
    
    /**
      * @dev Subscription approved event
      * @param token Super token address
      * @param subscriber The approved subscriber
      * @param publisher Index publisher
      * @param indexId The specified indexId
      * @param userData The user provided data
      */
    event SubscriptionRevoked(
        ISuperfluidToken indexed token,
        address indexed subscriber,
        address publisher,
        uint32 indexId,
        bytes userData);

    /**
     * @dev Update the nuber of units of a subscription
     * @param token Super token address
     * @param indexId Id of the index
     * @param subscriber The subscriber of the index
     * @param units Number of units of the subscription
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     *
     * @custom:callbacks 
     * - if subscription exist
     *   - AgreementCreated callback to the subscriber:
     *      - agreementId is for the subscription
     * - if subscription does not exist
     *   - AgreementUpdated callback to the subscriber:
     *      - agreementId is for the subscription
     */
    function updateSubscription(
        ISuperfluidToken token,
        uint32 indexId,
        address subscriber,
        uint128 units,
        bytes calldata ctx)
            external
            virtual
            returns(bytes memory newCtx);

    /**
      * @dev Index units updated event
      * @param token Super token address
      * @param publisher Index publisher
      * @param indexId The specified indexId
      * @param subscriber The subscriber units updated
      * @param units The new units amount
      * @param userData The user provided data
      */
    event IndexUnitsUpdated(
        ISuperfluidToken indexed token,
        address indexed publisher,
        uint32 indexed indexId,
        address subscriber,
        uint128 units,
        bytes userData);
    
    /**
      * @dev Subscription units updated event
      * @param token Super token address
      * @param subscriber The subscriber units updated
      * @param indexId The specified indexId
      * @param publisher Index publisher
      * @param units The new units amount
      * @param userData The user provided data
      */
    event SubscriptionUnitsUpdated(
        ISuperfluidToken indexed token,
        address indexed subscriber,
        address publisher,
        uint32 indexId,
        uint128 units,
        bytes userData);

    /**
     * @dev Get data of a subscription
     * @param token Super token address
     * @param publisher The publisher of the index
     * @param indexId Id of the index
     * @param subscriber The subscriber of the index
     * @return exist Does the subscription exist?
     * @return approved Is the subscription approved?
     * @return units Units of the suscription
     * @return pendingDistribution Pending amount of tokens to be distributed for unapproved subscription
     */
    function getSubscription(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber)
            external
            view
            virtual
            returns(
                bool exist,
                bool approved,
                uint128 units,
                uint256 pendingDistribution
            );

    /**
     * @notice Get data of a subscription by agreement ID
     * @dev indexId (agreementId) is the keccak256 hash of encodePacked("publisher", publisher, indexId)
     * @param token Super token address
     * @param agreementId The agreement ID
     * @return publisher The publisher of the index
     * @return indexId Id of the index
     * @return approved Is the subscription approved?
     * @return units Units of the suscription
     * @return pendingDistribution Pending amount of tokens to be distributed for unapproved subscription
     */
    function getSubscriptionByID(
        ISuperfluidToken token,
        bytes32 agreementId)
            external
            view
            virtual
            returns(
                address publisher,
                uint32 indexId,
                bool approved,
                uint128 units,
                uint256 pendingDistribution
            );

    /**
     * @dev List subscriptions of an user
     * @param token Super token address
     * @param subscriber The subscriber's address
     * @return publishers Publishers of the subcriptions
     * @return indexIds Indexes of the subscriptions
     * @return unitsList Units of the subscriptions
     */
    function listSubscriptions(
        ISuperfluidToken token,
        address subscriber)
            external
            view
            virtual
            returns(
                address[] memory publishers,
                uint32[] memory indexIds,
                uint128[] memory unitsList);

    /**
     * @dev Delete the subscription of an user
     * @param token Super token address
     * @param publisher The publisher of the index
     * @param indexId Id of the index
     * @param subscriber The subscriber's address
     * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
     *
     * @custom:callbacks 
     * - if the subscriber called it
     *   - AgreementTerminated callback to the publsiher:
     *      - agreementId is for the subscription
     * - if the publisher called it
     *   - AgreementTerminated callback to the subscriber:
     *      - agreementId is for the subscription
     */
    function deleteSubscription(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber,
        bytes calldata ctx)
            external
            virtual
            returns(bytes memory newCtx);

    /**
    * @dev Claim pending distributions
    * @param token Super token address
    * @param publisher The publisher of the index
    * @param indexId Id of the index
    * @param subscriber The subscriber's address
    * @param ctx Context bytes (see ISuperfluid.sol for Context struct)
    *
    * @custom:note The subscription should not be approved yet
    *
    * @custom:callbacks 
    * - AgreementUpdated callback to the publisher:
    *    - agreementId is for the subscription
    */
    function claim(
        ISuperfluidToken token,
        address publisher,
        uint32 indexId,
        address subscriber,
        bytes calldata ctx)
        external
        virtual
        returns(bytes memory newCtx);
    
    /**
      * @dev Index distribution claimed event
      * @param token Super token address
      * @param publisher Index publisher
      * @param indexId The specified indexId
      * @param subscriber The subscriber units updated
      * @param amount The pending amount claimed
      */
    event IndexDistributionClaimed(
        ISuperfluidToken indexed token,
        address indexed publisher,
        uint32 indexed indexId,
        address subscriber,
        uint256 amount);
    
    /**
      * @dev Subscription distribution claimed event
      * @param token Super token address
      * @param subscriber The subscriber units updated
      * @param publisher Index publisher
      * @param indexId The specified indexId
      * @param amount The pending amount claimed
      */
    event SubscriptionDistributionClaimed(
        ISuperfluidToken indexed token,
        address indexed subscriber,
        address publisher,
        uint32 indexId,
        uint256 amount);

}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

/**
 * @title Super app definitions library
 * @author Superfluid
 */
library SuperAppDefinitions {

    /**************************************************************************
    / App manifest config word
    /**************************************************************************/

    /*
     * App level is a way to allow the app to whitelist what other app it can
     * interact with (aka. composite app feature).
     *
     * For more details, refer to the technical paper of superfluid protocol.
     */
    uint256 constant internal APP_LEVEL_MASK = 0xFF;

    // The app is at the final level, hence it doesn't want to interact with any other app
    uint256 constant internal APP_LEVEL_FINAL = 1 << 0;

    // The app is at the second level, it may interact with other final level apps if whitelisted
    uint256 constant internal APP_LEVEL_SECOND = 1 << 1;

    function getAppLevel(uint256 configWord) internal pure returns (uint8) {
        return uint8(configWord & APP_LEVEL_MASK);
    }

    uint256 constant internal APP_JAIL_BIT = 1 << 15;
    function isAppJailed(uint256 configWord) internal pure returns (bool) {
        return (configWord & SuperAppDefinitions.APP_JAIL_BIT) > 0;
    }

    /**************************************************************************
    / Callback implementation bit masks
    /**************************************************************************/
    uint256 constant internal AGREEMENT_CALLBACK_NOOP_BITMASKS = 0xFF << 32;
    uint256 constant internal BEFORE_AGREEMENT_CREATED_NOOP = 1 << (32 + 0);
    uint256 constant internal AFTER_AGREEMENT_CREATED_NOOP = 1 << (32 + 1);
    uint256 constant internal BEFORE_AGREEMENT_UPDATED_NOOP = 1 << (32 + 2);
    uint256 constant internal AFTER_AGREEMENT_UPDATED_NOOP = 1 << (32 + 3);
    uint256 constant internal BEFORE_AGREEMENT_TERMINATED_NOOP = 1 << (32 + 4);
    uint256 constant internal AFTER_AGREEMENT_TERMINATED_NOOP = 1 << (32 + 5);

    /**************************************************************************
    / App Jail Reasons
    /**************************************************************************/

    uint256 constant internal APP_RULE_REGISTRATION_ONLY_IN_CONSTRUCTOR = 1;
    uint256 constant internal APP_RULE_NO_REGISTRATION_FOR_EOA = 2;
    uint256 constant internal APP_RULE_NO_REVERT_ON_TERMINATION_CALLBACK = 10;
    uint256 constant internal APP_RULE_NO_CRITICAL_SENDER_ACCOUNT = 11;
    uint256 constant internal APP_RULE_NO_CRITICAL_RECEIVER_ACCOUNT = 12;
    uint256 constant internal APP_RULE_CTX_IS_READONLY = 20;
    uint256 constant internal APP_RULE_CTX_IS_NOT_CLEAN = 21;
    uint256 constant internal APP_RULE_CTX_IS_MALFORMATED = 22;
    uint256 constant internal APP_RULE_COMPOSITE_APP_IS_NOT_WHITELISTED = 30;
    uint256 constant internal APP_RULE_COMPOSITE_APP_IS_JAILED = 31;
    uint256 constant internal APP_RULE_MAX_APP_LEVEL_REACHED = 40;

    // Validate configWord cleaness for future compatibility, or else may introduce undefined future behavior
    function isConfigWordClean(uint256 configWord) internal pure returns (bool) {
        return (configWord & ~(APP_LEVEL_MASK | APP_JAIL_BIT | AGREEMENT_CALLBACK_NOOP_BITMASKS)) == uint256(0);
    }
}

/**
 * @title Context definitions library
 * @author Superfluid
 */
library ContextDefinitions {

    /**************************************************************************
    / Call info
    /**************************************************************************/

    // app level
    uint256 constant internal CALL_INFO_APP_LEVEL_MASK = 0xFF;

    // call type
    uint256 constant internal CALL_INFO_CALL_TYPE_SHIFT = 32;
    uint256 constant internal CALL_INFO_CALL_TYPE_MASK = 0xF << CALL_INFO_CALL_TYPE_SHIFT;
    uint8 constant internal CALL_INFO_CALL_TYPE_AGREEMENT = 1;
    uint8 constant internal CALL_INFO_CALL_TYPE_APP_ACTION = 2;
    uint8 constant internal CALL_INFO_CALL_TYPE_APP_CALLBACK = 3;

    function decodeCallInfo(uint256 callInfo)
        internal pure
        returns (uint8 appLevel, uint8 callType)
    {
        appLevel = uint8(callInfo & CALL_INFO_APP_LEVEL_MASK);
        callType = uint8((callInfo & CALL_INFO_CALL_TYPE_MASK) >> CALL_INFO_CALL_TYPE_SHIFT);
    }

    function encodeCallInfo(uint8 appLevel, uint8 callType)
        internal pure
        returns (uint256 callInfo)
    {
        return uint256(appLevel) | (uint256(callType) << CALL_INFO_CALL_TYPE_SHIFT);
    }

}

/**
 * @title Flow Operator definitions library
  * @author Superfluid
 */
 library FlowOperatorDefinitions {
    uint8 constant internal AUTHORIZE_FLOW_OPERATOR_CREATE = uint8(1) << 0;
    uint8 constant internal AUTHORIZE_FLOW_OPERATOR_UPDATE = uint8(1) << 1;
    uint8 constant internal AUTHORIZE_FLOW_OPERATOR_DELETE = uint8(1) << 2;
    uint8 constant internal AUTHORIZE_FULL_CONTROL =
        AUTHORIZE_FLOW_OPERATOR_CREATE | AUTHORIZE_FLOW_OPERATOR_UPDATE | AUTHORIZE_FLOW_OPERATOR_DELETE;
    uint8 constant internal REVOKE_FLOW_OPERATOR_CREATE = ~(uint8(1) << 0);
    uint8 constant internal REVOKE_FLOW_OPERATOR_UPDATE = ~(uint8(1) << 1);
    uint8 constant internal REVOKE_FLOW_OPERATOR_DELETE = ~(uint8(1) << 2);

    function isPermissionsClean(uint8 permissions) internal pure returns (bool) {
        return (
            permissions & ~(AUTHORIZE_FLOW_OPERATOR_CREATE
                | AUTHORIZE_FLOW_OPERATOR_UPDATE
                | AUTHORIZE_FLOW_OPERATOR_DELETE)
            ) == uint8(0);
    }
 }

/**
 * @title Batch operation library
 * @author Superfluid
 */
library BatchOperation {
    /**
     * @dev ERC20.approve batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationApprove(
     *     abi.decode(data, (address spender, uint256 amount))
     * )
     */
    uint32 constant internal OPERATION_TYPE_ERC20_APPROVE = 1;
    /**
     * @dev ERC20.transferFrom batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationTransferFrom(
     *     abi.decode(data, (address sender, address recipient, uint256 amount)
     * )
     */
    uint32 constant internal OPERATION_TYPE_ERC20_TRANSFER_FROM = 2;
    /**
     * @dev SuperToken.upgrade batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationUpgrade(
     *     abi.decode(data, (uint256 amount)
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERTOKEN_UPGRADE = 1 + 100;
    /**
     * @dev SuperToken.downgrade batch operation type
     *
     * Call spec:
     * ISuperToken(target).operationDowngrade(
     *     abi.decode(data, (uint256 amount)
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERTOKEN_DOWNGRADE = 2 + 100;
    /**
     * @dev Superfluid.callAgreement batch operation type
     *
     * Call spec:
     * callAgreement(
     *     ISuperAgreement(target)),
     *     abi.decode(data, (bytes calldata, bytes userdata)
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERFLUID_CALL_AGREEMENT = 1 + 200;
    /**
     * @dev Superfluid.callAppAction batch operation type
     *
     * Call spec:
     * callAppAction(
     *     ISuperApp(target)),
     *     data
     * )
     */
    uint32 constant internal OPERATION_TYPE_SUPERFLUID_CALL_APP_ACTION = 2 + 200;
}

/**
 * @title Superfluid governance configs library
 * @author Superfluid
 */
library SuperfluidGovernanceConfigs {

    bytes32 constant internal SUPERFLUID_REWARD_ADDRESS_CONFIG_KEY =
        keccak256("org.superfluid-finance.superfluid.rewardAddress");
    bytes32 constant internal CFAV1_PPP_CONFIG_KEY =
        keccak256("org.superfluid-finance.agreements.ConstantFlowAgreement.v1.PPPConfiguration");
    bytes32 constant internal SUPERTOKEN_MINIMUM_DEPOSIT_KEY = 
        keccak256("org.superfluid-finance.superfluid.superTokenMinimumDeposit");

    function getTrustedForwarderConfigKey(address forwarder) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            "org.superfluid-finance.superfluid.trustedForwarder",
            forwarder));
    }

    function getAppRegistrationConfigKey(address deployer, string memory registrationKey) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            "org.superfluid-finance.superfluid.appWhiteListing.registrationKey",
            deployer,
            registrationKey));
    }

    function getAppFactoryConfigKey(address factory) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            "org.superfluid-finance.superfluid.appWhiteListing.factory",
            factory));
    }

    function decodePPPConfig(uint256 pppConfig) internal pure returns (uint256 liquidationPeriod, uint256 patricianPeriod) {
        liquidationPeriod = (pppConfig >> 32) & type(uint32).max;
        patricianPeriod = pppConfig & type(uint32).max;
    }
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

import { ISuperfluidToken } from "./ISuperfluidToken.sol";

/**
 * @title Super agreement interface
 * @author Superfluid
 */
interface ISuperAgreement {

    /**
     * @dev Get the type of the agreement class
     */
    function agreementType() external view returns (bytes32);

    /**
     * @dev Calculate the real-time balance for the account of this agreement class
     * @param account Account the state belongs to
     * @param time Time used for the calculation
     * @return dynamicBalance Dynamic balance portion of real-time balance of this agreement
     * @return deposit Account deposit amount of this agreement
     * @return owedDeposit Account owed deposit amount of this agreement
     */
    function realtimeBalanceOf(
        ISuperfluidToken token,
        address account,
        uint256 time
    )
        external
        view
        returns (
            int256 dynamicBalance,
            uint256 deposit,
            uint256 owedDeposit
        );

}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

import { ISuperToken } from "./ISuperToken.sol";

/**
 * @title SuperApp interface
 * @author Superfluid
 * @dev Be aware of the app being jailed, when the word permitted is used.
 */
interface ISuperApp {

    /**
     * @dev Callback before a new agreement is created.
     * @param superToken The super token used for the agreement.
     * @param agreementClass The agreement class address.
     * @param agreementId The agreementId
     * @param agreementData The agreement data (non-compressed)
     * @param ctx The context data.
     * @return cbdata A free format in memory data the app can use to pass
     *          arbitary information to the after-hook callback.
     *
     * @custom:note 
     * - It will be invoked with `staticcall`, no state changes are permitted.
     * - Only revert with a "reason" is permitted.
     */
    function beforeAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    )
        external
        view
        returns (bytes memory cbdata);

    /**
     * @dev Callback after a new agreement is created.
     * @param superToken The super token used for the agreement.
     * @param agreementClass The agreement class address.
     * @param agreementId The agreementId
     * @param agreementData The agreement data (non-compressed)
     * @param cbdata The data returned from the before-hook callback.
     * @param ctx The context data.
     * @return newCtx The current context of the transaction.
     *
     * @custom:note 
     * - State changes is permitted.
     * - Only revert with a "reason" is permitted.
     */
    function afterAgreementCreated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external
        returns (bytes memory newCtx);

    /**
     * @dev Callback before a new agreement is updated.
     * @param superToken The super token used for the agreement.
     * @param agreementClass The agreement class address.
     * @param agreementId The agreementId
     * @param agreementData The agreement data (non-compressed)
     * @param ctx The context data.
     * @return cbdata A free format in memory data the app can use to pass
     *          arbitary information to the after-hook callback.
     *
     * @custom:note 
     * - It will be invoked with `staticcall`, no state changes are permitted.
     * - Only revert with a "reason" is permitted.
     */
    function beforeAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    )
        external
        view
        returns (bytes memory cbdata);


    /**
    * @dev Callback after a new agreement is updated.
    * @param superToken The super token used for the agreement.
    * @param agreementClass The agreement class address.
    * @param agreementId The agreementId
    * @param agreementData The agreement data (non-compressed)
    * @param cbdata The data returned from the before-hook callback.
    * @param ctx The context data.
    * @return newCtx The current context of the transaction.
    *
    * @custom:note 
    * - State changes is permitted.
    * - Only revert with a "reason" is permitted.
    */
    function afterAgreementUpdated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external
        returns (bytes memory newCtx);

    /**
    * @dev Callback before a new agreement is terminated.
    * @param superToken The super token used for the agreement.
    * @param agreementClass The agreement class address.
    * @param agreementId The agreementId
    * @param agreementData The agreement data (non-compressed)
    * @param ctx The context data.
    * @return cbdata A free format in memory data the app can use to pass arbitary information to the after-hook callback.
    *
    * @custom:note 
    * - It will be invoked with `staticcall`, no state changes are permitted.
    * - Revert is not permitted.
    */
    function beforeAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata ctx
    )
        external
        view
        returns (bytes memory cbdata);

    /**
    * @dev Callback after a new agreement is terminated.
    * @param superToken The super token used for the agreement.
    * @param agreementClass The agreement class address.
    * @param agreementId The agreementId
    * @param agreementData The agreement data (non-compressed)
    * @param cbdata The data returned from the before-hook callback.
    * @param ctx The context data.
    * @return newCtx The current context of the transaction.
    *
    * @custom:note 
    * - State changes is permitted.
    * - Revert is not permitted.
    */
    function afterAgreementTerminated(
        ISuperToken superToken,
        address agreementClass,
        bytes32 agreementId,
        bytes calldata agreementData,
        bytes calldata cbdata,
        bytes calldata ctx
    )
        external
        returns (bytes memory newCtx);
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

import { ISuperfluid } from "./ISuperfluid.sol";
import { ISuperfluidToken } from "./ISuperfluidToken.sol";
import { TokenInfo } from "../tokens/TokenInfo.sol";
import { IERC777 } from "@openzeppelin/contracts/token/ERC777/IERC777.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Super token (Superfluid Token + ERC20 + ERC777) interface
 * @author Superfluid
 */
interface ISuperToken is ISuperfluidToken, TokenInfo, IERC20, IERC777 {

    /**
     * @dev Initialize the contract
     */
    function initialize(
        IERC20 underlyingToken,
        uint8 underlyingDecimals,
        string calldata n,
        string calldata s
    ) external;

    /**************************************************************************
    * TokenInfo & ERC777
    *************************************************************************/

    /**
     * @dev Returns the name of the token.
     */
    function name() external view override(IERC777, TokenInfo) returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view override(IERC777, TokenInfo) returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * @custom:note SuperToken always uses 18 decimals.
     *
     * This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view override(TokenInfo) returns (uint8);

    /**************************************************************************
    * ERC20 & ERC777
    *************************************************************************/

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view override(IERC777, IERC20) returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address account) external view override(IERC777, IERC20) returns(uint256 balance);

    /**************************************************************************
    * ERC20
    *************************************************************************/

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * @return Returns Success a boolean value indicating whether the operation succeeded.
     *
     * @custom:emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external override(IERC20) returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     *         allowed to spend on behalf of `owner` through {transferFrom}. This is
     *         zero by default.
     *
     * @notice This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external override(IERC20) view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * @return Returns Success a boolean value indicating whether the operation succeeded.
     *
     * @custom:note Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * @custom:emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external override(IERC20) returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     *         allowance mechanism. `amount` is then deducted from the caller's
     *         allowance.
     *
     * @return Returns Success a boolean value indicating whether the operation succeeded.
     *
     * @custom:emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override(IERC20) returns (bool);

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * @custom:emits an {Approval} event indicating the updated allowance.
     *
     * @custom:requirements 
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * @custom:emits an {Approval} event indicating the updated allowance.
     *
     * @custom:requirements 
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
     function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**************************************************************************
    * ERC777
    *************************************************************************/

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     *         means all token operations (creation, movement and destruction) must have
     *         amounts that are a multiple of this number.
     *
     * @custom:note For super token contracts, this value is always 1
     */
    function granularity() external view override(IERC777) returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * @dev If send or receive hooks are registered for the caller and `recipient`,
     *      the corresponding functions will be called with `data` and empty
     *      `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * @custom:emits a {Sent} event.
     *
     * @custom:requirements 
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(address recipient, uint256 amount, bytes calldata data) external override(IERC777);

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * @custom:emits a {Burned} event.
     *
     * @custom:requirements 
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external override(IERC777);

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external override(IERC777) view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * @custom:emits an {AuthorizedOperator} event.
     *
     * @custom:requirements 
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external override(IERC777);

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * @custom:emits a {RevokedOperator} event.
     *
     * @custom:requirements 
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external override(IERC777);

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external override(IERC777) view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * @custom:emits a {Sent} event.
     *
     * @custom:requirements 
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external override(IERC777);

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * @custom:emits a {Burned} event.
     *
     * @custom:requirements 
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external override(IERC777);

    /**************************************************************************
     * SuperToken custom token functions
     *************************************************************************/

    /**
     * @dev Mint new tokens for the account
     *
     * @custom:modifiers 
     *  - onlySelf
     */
    function selfMint(
        address account,
        uint256 amount,
        bytes memory userData
    ) external;

   /**
    * @dev Burn existing tokens for the account
    *
    * @custom:modifiers 
    *  - onlySelf
    */
   function selfBurn(
       address account,
       uint256 amount,
       bytes memory userData
   ) external;

   /**
    * @dev Transfer `amount` tokens from the `sender` to `recipient`.
    * If `spender` isn't the same as `sender`, checks if `spender` has allowance to
    * spend tokens of `sender`.
    *
    * @custom:modifiers 
    *  - onlySelf
    */
   function selfTransferFrom(
        address sender,
        address spender,
        address recipient,
        uint256 amount
   ) external;

   /**
    * @dev Give `spender`, `amount` allowance to spend the tokens of
    * `account`.
    *
    * @custom:modifiers 
    *  - onlySelf
    */
   function selfApproveFor(
        address account,
        address spender,
        uint256 amount
   ) external;

    /**************************************************************************
     * SuperToken extra functions
     *************************************************************************/

    /**
     * @dev Transfer all available balance from `msg.sender` to `recipient`
     */
    function transferAll(address recipient) external;

    /**************************************************************************
     * ERC20 wrapping
     *************************************************************************/

    /**
     * @dev Return the underlying token contract
     * @return tokenAddr Underlying token address
     */
    function getUnderlyingToken() external view returns(address tokenAddr);

    /**
     * @dev Upgrade ERC20 to SuperToken.
     * @param amount Number of tokens to be upgraded (in 18 decimals)
     *
     * @custom:note It will use `transferFrom` to get tokens. Before calling this
     * function you should `approve` this contract
     */
    function upgrade(uint256 amount) external;

    /**
     * @dev Upgrade ERC20 to SuperToken and transfer immediately
     * @param to The account to received upgraded tokens
     * @param amount Number of tokens to be upgraded (in 18 decimals)
     * @param data User data for the TokensRecipient callback
     *
     * @custom:note It will use `transferFrom` to get tokens. Before calling this
     * function you should `approve` this contract
     */
    function upgradeTo(address to, uint256 amount, bytes calldata data) external;

    /**
     * @dev Token upgrade event
     * @param account Account where tokens are upgraded to
     * @param amount Amount of tokens upgraded (in 18 decimals)
     */
    event TokenUpgraded(
        address indexed account,
        uint256 amount
    );

    /**
     * @dev Downgrade SuperToken to ERC20.
     * @dev It will call transfer to send tokens
     * @param amount Number of tokens to be downgraded
     */
    function downgrade(uint256 amount) external;

    /**
     * @dev Token downgrade event
     * @param account Account whose tokens are upgraded
     * @param amount Amount of tokens downgraded
     */
    event TokenDowngraded(
        address indexed account,
        uint256 amount
    );

    /**************************************************************************
    * Batch Operations
    *************************************************************************/

    /**
    * @dev Perform ERC20 approve by host contract.
    * @param account The account owner to be approved.
    * @param spender The spender of account owner's funds.
    * @param amount Number of tokens to be approved.
    *
    * @custom:modifiers 
    *  - onlyHost
    */
    function operationApprove(
        address account,
        address spender,
        uint256 amount
    ) external;

    /**
    * @dev Perform ERC20 transfer from by host contract.
    * @param account The account to spend sender's funds.
    * @param spender  The account where the funds is sent from.
    * @param recipient The recipient of thefunds.
    * @param amount Number of tokens to be transferred.
    *
    * @custom:modifiers 
    *  - onlyHost
    */
    function operationTransferFrom(
        address account,
        address spender,
        address recipient,
        uint256 amount
    ) external;

    /**
    * @dev Upgrade ERC20 to SuperToken by host contract.
    * @param account The account to be changed.
    * @param amount Number of tokens to be upgraded (in 18 decimals)
    *
    * @custom:modifiers 
    *  - onlyHost
    */
    function operationUpgrade(address account, uint256 amount) external;

    /**
    * @dev Downgrade ERC20 to SuperToken by host contract.
    * @param account The account to be changed.
    * @param amount Number of tokens to be downgraded (in 18 decimals)
    *
    * @custom:modifiers 
    *  - onlyHost
    */
    function operationDowngrade(address account, uint256 amount) external;


    /**************************************************************************
    * Function modifiers for access control and parameter validations
    *
    * While they cannot be explicitly stated in function definitions, they are
    * listed in function definition comments instead for clarity.
    *
    * NOTE: solidity-coverage not supporting it
    *************************************************************************/

    /// @dev The msg.sender must be the contract itself
    //modifier onlySelf() virtual

}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

import { ISuperToken } from "./ISuperToken.sol";

import {
    IERC20,
    ERC20WithTokenInfo
} from "../tokens/ERC20WithTokenInfo.sol";

/**
 * @title Super token factory interface
 * @author Superfluid
 */
interface ISuperTokenFactory {

    /**
     * @dev Get superfluid host contract address
     */
    function getHost() external view returns(address host);

    /// @dev Initialize the contract
    function initialize() external;

    /**
     * @dev Get the current super token logic used by the factory
     */
    function getSuperTokenLogic() external view returns (ISuperToken superToken);

    /**
     * @dev Upgradability modes
     */
    enum Upgradability {
        /// Non upgradable super token, `host.updateSuperTokenLogic` will revert
        NON_UPGRADABLE,
        /// Upgradable through `host.updateSuperTokenLogic` operation
        SEMI_UPGRADABLE,
        /// Always using the latest super token logic
        FULL_UPGRADABE
    }

    /**
     * @dev Create new super token wrapper for the underlying ERC20 token
     * @param underlyingToken Underlying ERC20 token
     * @param underlyingDecimals Underlying token decimals
     * @param upgradability Upgradability mode
     * @param name Super token name
     * @param symbol Super token symbol
     */
    function createERC20Wrapper(
        IERC20 underlyingToken,
        uint8 underlyingDecimals,
        Upgradability upgradability,
        string calldata name,
        string calldata symbol
    )
        external
        returns (ISuperToken superToken);

    /**
     * @dev Create new super token wrapper for the underlying ERC20 token with extra token info
     * @param underlyingToken Underlying ERC20 token
     * @param upgradability Upgradability mode
     * @param name Super token name
     * @param symbol Super token symbol
     *
     * NOTE:
     * - It assumes token provide the .decimals() function
     */
    function createERC20Wrapper(
        ERC20WithTokenInfo underlyingToken,
        Upgradability upgradability,
        string calldata name,
        string calldata symbol
    )
        external
        returns (ISuperToken superToken);

    function initializeCustomSuperToken(
        address customSuperTokenProxy
    )
        external;

    /**
      * @dev Super token logic created event
      * @param tokenLogic Token logic address
      */
    event SuperTokenLogicCreated(ISuperToken indexed tokenLogic);

    /**
      * @dev Super token created event
      * @param token Newly created super token address
      */
    event SuperTokenCreated(ISuperToken indexed token);

    /**
      * @dev Custom super token created event
      * @param token Newly created custom super token address
      */
    event CustomSuperTokenCreated(ISuperToken indexed token);

}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.2;

import { ISuperfluidGovernance } from "./ISuperfluidGovernance.sol";
import { ISuperfluidToken } from "./ISuperfluidToken.sol";
import { ISuperToken } from "./ISuperToken.sol";
import { ISuperTokenFactory } from "./ISuperTokenFactory.sol";
import { ISuperAgreement } from "./ISuperAgreement.sol";
import { ISuperApp } from "./ISuperApp.sol";
import {
    BatchOperation,
    ContextDefinitions,
    FlowOperatorDefinitions,
    SuperAppDefinitions,
    SuperfluidGovernanceConfigs
} from "./Definitions.sol";
import { TokenInfo } from "../tokens/TokenInfo.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC777 } from "@openzeppelin/contracts/token/ERC777/IERC777.sol";

/**
 * @title Host interface
 * @author Superfluid
 * @notice This is the central contract of the system where super agreement, super app
 * and super token features are connected.
 *
 * The Superfluid host contract is also the entry point for the protocol users,
 * where batch call and meta transaction are provided for UX improvements.
 *
 */
interface ISuperfluid {

    /**************************************************************************
     * Time
     *
     * > The Oracle: You have the sight now, Neo. You are looking at the world without time.
     * > Neo: Then why can't I see what happens to her?
     * > The Oracle: We can never see past the choices we don't understand.
     * >       - The Oracle and Neo conversing about the future of Trinity and the effects of Neo's choices
     *************************************************************************/

    function getNow() external view returns (uint256);

    /**************************************************************************
     * Governance
     *************************************************************************/

    /**
     * @dev Get the current governance address of the Superfluid host
     */
    function getGovernance() external view returns(ISuperfluidGovernance governance);

    /**
     * @dev Replace the current governance with a new one
     */
    function replaceGovernance(ISuperfluidGovernance newGov) external;
    /**
     * @dev Governance replaced event
     * @param oldGov Address of the old governance contract
     * @param newGov Address of the new governance contract
     */
    event GovernanceReplaced(ISuperfluidGovernance oldGov, ISuperfluidGovernance newGov);

    /**************************************************************************
     * Agreement Whitelisting
     *************************************************************************/

    /**
     * @dev Register a new agreement class to the system
     * @param agreementClassLogic Initial agreement class code
     *
     * @custom:modifiers 
     * - onlyGovernance
     */
    function registerAgreementClass(ISuperAgreement agreementClassLogic) external;
    /**
     * @notice Agreement class registered event
     * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
     * @param agreementType The agreement type registered
     * @param code Address of the new agreement
     */
    event AgreementClassRegistered(bytes32 agreementType, address code);

    /**
    * @dev Update code of an agreement class
    * @param agreementClassLogic New code for the agreement class
    *
    * @custom:modifiers 
    *  - onlyGovernance
    */
    function updateAgreementClass(ISuperAgreement agreementClassLogic) external;
    /**
     * @notice Agreement class updated event
     * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
     * @param agreementType The agreement type updated
     * @param code Address of the new agreement
     */
    event AgreementClassUpdated(bytes32 agreementType, address code);

    /**
    * @notice Check if the agreement type is whitelisted
    * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
    */
    function isAgreementTypeListed(bytes32 agreementType) external view returns(bool yes);

    /**
    * @dev Check if the agreement class is whitelisted
    */
    function isAgreementClassListed(ISuperAgreement agreementClass) external view returns(bool yes);

    /**
    * @notice Get agreement class
    * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
    */
    function getAgreementClass(bytes32 agreementType) external view returns(ISuperAgreement agreementClass);

    /**
    * @dev Map list of the agreement classes using a bitmap
    * @param bitmap Agreement class bitmap
    */
    function mapAgreementClasses(uint256 bitmap)
        external view
        returns (ISuperAgreement[] memory agreementClasses);

    /**
    * @notice Create a new bitmask by adding a agreement class to it
    * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
    * @param bitmap Agreement class bitmap
    */
    function addToAgreementClassesBitmap(uint256 bitmap, bytes32 agreementType)
        external view
        returns (uint256 newBitmap);

    /**
    * @notice Create a new bitmask by removing a agreement class from it
    * @dev agreementType is the keccak256 hash of: "org.superfluid-finance.agreements.<AGREEMENT_NAME>.<VERSION>"
    * @param bitmap Agreement class bitmap
    */
    function removeFromAgreementClassesBitmap(uint256 bitmap, bytes32 agreementType)
        external view
        returns (uint256 newBitmap);

    /**************************************************************************
    * Super Token Factory
    **************************************************************************/

    /**
     * @dev Get the super token factory
     * @return factory The factory
     */
    function getSuperTokenFactory() external view returns (ISuperTokenFactory factory);

    /**
     * @dev Get the super token factory logic (applicable to upgradable deployment)
     * @return logic The factory logic
     */
    function getSuperTokenFactoryLogic() external view returns (address logic);

    /**
     * @dev Update super token factory
     * @param newFactory New factory logic
     */
    function updateSuperTokenFactory(ISuperTokenFactory newFactory) external;
    /**
     * @dev SuperToken factory updated event
     * @param newFactory Address of the new factory
     */
    event SuperTokenFactoryUpdated(ISuperTokenFactory newFactory);

    /**
     * @notice Update the super token logic to the latest
     * @dev Refer to ISuperTokenFactory.Upgradability for expected behaviours
     */
    function updateSuperTokenLogic(ISuperToken token) external;
    /**
     * @dev SuperToken logic updated event
     * @param code Address of the new SuperToken logic
     */
    event SuperTokenLogicUpdated(ISuperToken indexed token, address code);

    /**************************************************************************
     * App Registry
     *************************************************************************/

    /**
     * @dev Message sender (must be a contract) declares itself as a super app.
     * @custom:deprecated you should use `registerAppWithKey` or `registerAppByFactory` instead,
     * because app registration is currently governance permissioned on mainnets.
     * @param configWord The super app manifest configuration, flags are defined in
     * `SuperAppDefinitions`
     */
    function registerApp(uint256 configWord) external;
    /**
     * @dev App registered event
     * @param app Address of jailed app
     */
    event AppRegistered(ISuperApp indexed app);

    /**
     * @dev Message sender declares itself as a super app.
     * @param configWord The super app manifest configuration, flags are defined in `SuperAppDefinitions`
     * @param registrationKey The registration key issued by the governance, needed to register on a mainnet.
     * @notice See https://github.com/superfluid-finance/protocol-monorepo/wiki/Super-App-White-listing-Guide
     * On testnets or in dev environment, a placeholder (e.g. empty string) can be used.
     * While the message sender must be the super app itself, the transaction sender (tx.origin)
     * must be the deployer account the registration key was issued for.
     */
    function registerAppWithKey(uint256 configWord, string calldata registrationKey) external;

    /**
     * @dev Message sender (must be a contract) declares app as a super app
     * @param configWord The super app manifest configuration, flags are defined in `SuperAppDefinitions`
     * @notice On mainnet deployments, only factory contracts pre-authorized by governance can use this.
     * See https://github.com/superfluid-finance/protocol-monorepo/wiki/Super-App-White-listing-Guide
     */
    function registerAppByFactory(ISuperApp app, uint256 configWord) external;

    /**
     * @dev Query if the app is registered
     * @param app Super app address
     */
    function isApp(ISuperApp app) external view returns(bool);

    /**
     * @dev Query app level
     * @param app Super app address
     */
    function getAppLevel(ISuperApp app) external view returns(uint8 appLevel);

    /**
     * @dev Get the manifest of the super app
     * @param app Super app address
     */
    function getAppManifest(
        ISuperApp app
    )
        external view
        returns (
            bool isSuperApp,
            bool isJailed,
            uint256 noopMask
        );

    /**
     * @dev Query if the app has been jailed
     * @param app Super app address
     */
    function isAppJailed(ISuperApp app) external view returns (bool isJail);

    /**
     * @dev Whitelist the target app for app composition for the source app (msg.sender)
     * @param targetApp The target super app address
     */
    function allowCompositeApp(ISuperApp targetApp) external;

    /**
     * @dev Query if source app is allowed to call the target app as downstream app
     * @param app Super app address
     * @param targetApp The target super app address
     */
    function isCompositeAppAllowed(
        ISuperApp app,
        ISuperApp targetApp
    )
        external view
        returns (bool isAppAllowed);

    /**************************************************************************
     * Agreement Framework
     *
     * Agreements use these function to trigger super app callbacks, updates
     * app allowance and charge gas fees.
     *
     * These functions can only be called by registered agreements.
     *************************************************************************/

    /**
     * @dev (For agreements) StaticCall the app before callback
     * @param  app               The super app.
     * @param  callData          The call data sending to the super app.
     * @param  isTermination     Is it a termination callback?
     * @param  ctx               Current ctx, it will be validated.
     * @return cbdata            Data returned from the callback.
     */
    function callAppBeforeCallback(
        ISuperApp app,
        bytes calldata callData,
        bool isTermination,
        bytes calldata ctx
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns(bytes memory cbdata);

    /**
     * @dev (For agreements) Call the app after callback
     * @param  app               The super app.
     * @param  callData          The call data sending to the super app.
     * @param  isTermination     Is it a termination callback?
     * @param  ctx               Current ctx, it will be validated.
     * @return newCtx            The current context of the transaction.
     */
    function callAppAfterCallback(
        ISuperApp app,
        bytes calldata callData,
        bool isTermination,
        bytes calldata ctx
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns(bytes memory newCtx);

    /**
     * @dev (For agreements) Create a new callback stack
     * @param  ctx                     The current ctx, it will be validated.
     * @param  app                     The super app.
     * @param  appAllowanceGranted     App allowance granted so far.
     * @param  appAllowanceUsed        App allowance used so far.
     * @return newCtx                  The current context of the transaction.
     */
    function appCallbackPush(
        bytes calldata ctx,
        ISuperApp app,
        uint256 appAllowanceGranted,
        int256 appAllowanceUsed,
        ISuperfluidToken appAllowanceToken
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns (bytes memory newCtx);

    /**
     * @dev (For agreements) Pop from the current app callback stack
     * @param  ctx                     The ctx that was pushed before the callback stack.
     * @param  appAllowanceUsedDelta   App allowance used by the app.
     * @return newCtx                  The current context of the transaction.
     *
     * @custom:security 
     * - Here we cannot do assertValidCtx(ctx), since we do not really save the stack in memory.
     * - Hence there is still implicit trust that the agreement handles the callback push/pop pair correctly.
     */
    function appCallbackPop(
        bytes calldata ctx,
        int256 appAllowanceUsedDelta
    )
        external
        // onlyAgreement
        returns (bytes memory newCtx);

    /**
     * @dev (For agreements) Use app allowance.
     * @param  ctx                      The current ctx, it will be validated.
     * @param  appAllowanceWantedMore   See app allowance for more details.
     * @param  appAllowanceUsedDelta    See app allowance for more details.
     * @return newCtx                   The current context of the transaction.
     */
    function ctxUseAllowance(
        bytes calldata ctx,
        uint256 appAllowanceWantedMore,
        int256 appAllowanceUsedDelta
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns (bytes memory newCtx);

    /**
     * @dev (For agreements) Jail the app.
     * @param  app                     The super app.
     * @param  reason                  Jail reason code.
     * @return newCtx                  The current context of the transaction.
     */
    function jailApp(
        bytes calldata ctx,
        ISuperApp app,
        uint256 reason
    )
        external
        // onlyAgreement
        // assertValidCtx(ctx)
        returns (bytes memory newCtx);

    /**
     * @dev Jail event for the app
     * @param app Address of jailed app
     * @param reason Reason the app is jailed (see Definitions.sol for the full list)
     */
    event Jail(ISuperApp indexed app, uint256 reason);

    /**************************************************************************
     * Contextless Call Proxies
     *
     * NOTE: For EOAs or non-app contracts, they are the entry points for interacting
     * with agreements or apps.
     *
     * NOTE: The contextual call data should be generated using
     * abi.encodeWithSelector. The context parameter should be set to "0x",
     * an empty bytes array as a placeholder to be replaced by the host
     * contract.
     *************************************************************************/

     /**
      * @dev Call agreement function
      * @param agreementClass The agreement address you are calling
      * @param callData The contextual call data with placeholder ctx
      * @param userData Extra user data being sent to the super app callbacks
      */
     function callAgreement(
         ISuperAgreement agreementClass,
         bytes calldata callData,
         bytes calldata userData
     )
        external
        //cleanCtx
        //isAgreement(agreementClass)
        returns(bytes memory returnedData);

    /**
     * @notice Call app action
     * @dev Main use case is calling app action in a batch call via the host
     * @param callData The contextual call data
     *
     * @custom:note See "Contextless Call Proxies" above for more about contextual call data.
     */
    function callAppAction(
        ISuperApp app,
        bytes calldata callData
    )
        external
        //cleanCtx
        //isAppActive(app)
        //isValidAppAction(callData)
        returns(bytes memory returnedData);

    /**************************************************************************
     * Contextual Call Proxies and Context Utilities
     *
     * For apps, they must use context they receive to interact with
     * agreements or apps.
     *
     * The context changes must be saved and returned by the apps in their
     * callbacks always, any modification to the context will be detected and
     * the violating app will be jailed.
     *************************************************************************/

    /**
     * @dev Context Struct
     *
     * @custom:note on backward compatibility:
     * - Non-dynamic fields are padded to 32bytes and packed
     * - Dynamic fields are referenced through a 32bytes offset to their "parents" field (or root)
     * - The order of the fields hence should not be rearranged in order to be backward compatible:
     *    - non-dynamic fields will be parsed at the same memory location,
     *    - and dynamic fields will simply have a greater offset than it was.
     */
    struct Context {
        //
        // Call context
        //
        // callback level
        uint8 appLevel;
        // type of call
        uint8 callType;
        // the system timestamp
        uint256 timestamp;
        // The intended message sender for the call
        address msgSender;

        //
        // Callback context
        //
        // For callbacks it is used to know which agreement function selector is called
        bytes4 agreementSelector;
        // User provided data for app callbacks
        bytes userData;

        //
        // App context
        //
        // app allowance granted
        uint256 appAllowanceGranted;
        // app allowance wanted by the app callback
        uint256 appAllowanceWanted;
        // app allowance used, allowing negative values over a callback session
        int256 appAllowanceUsed;
        // app address
        address appAddress;
        // app allowance in super token
        ISuperfluidToken appAllowanceToken;
    }

    function callAgreementWithContext(
        ISuperAgreement agreementClass,
        bytes calldata callData,
        bytes calldata userData,
        bytes calldata ctx
    )
        external
        // requireValidCtx(ctx)
        // onlyAgreement(agreementClass)
        returns (bytes memory newCtx, bytes memory returnedData);

    function callAppActionWithContext(
        ISuperApp app,
        bytes calldata callData,
        bytes calldata ctx
    )
        external
        // requireValidCtx(ctx)
        // isAppActive(app)
        returns (bytes memory newCtx);

    function decodeCtx(bytes calldata ctx)
        external pure
        returns (Context memory context);

    function isCtxValid(bytes calldata ctx) external view returns (bool);

    /**************************************************************************
    * Batch call
    **************************************************************************/
    /**
     * @dev Batch operation data
     */
    struct Operation {
        // Operation type. Defined in BatchOperation (Definitions.sol)
        uint32 operationType;
        // Operation target
        address target;
        // Data specific to the operation
        bytes data;
    }

    /**
     * @dev Batch call function
     * @param operations Array of batch operations
     */
    function batchCall(Operation[] memory operations) external;

    /**
     * @dev Batch call function for trusted forwarders (EIP-2771)
     * @param operations Array of batch operations
     */
    function forwardBatchCall(Operation[] memory operations) external;

    /**************************************************************************
     * Function modifiers for access control and parameter validations
     *
     * While they cannot be explicitly stated in function definitions, they are
     * listed in function definition comments instead for clarity.
     *
     * TODO: turning these off because solidity-coverage doesn't like it
     *************************************************************************/

     /* /// @dev The current superfluid context is clean.
     modifier cleanCtx() virtual;

     /// @dev Require the ctx being valid.
     modifier requireValidCtx(bytes memory ctx) virtual;

     /// @dev Assert the ctx being valid.
     modifier assertValidCtx(bytes memory ctx) virtual;

     /// @dev The agreement is a listed agreement.
     modifier isAgreement(ISuperAgreement agreementClass) virtual;

     // onlyGovernance

     /// @dev The msg.sender must be a listed agreement.
     modifier onlyAgreement() virtual;

     /// @dev The app is registered and not jailed.
     modifier isAppActive(ISuperApp app) virtual; */
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

import { ISuperAgreement } from "./ISuperAgreement.sol";
import { ISuperToken } from "./ISuperToken.sol";
import { ISuperfluidToken  } from "./ISuperfluidToken.sol";
import { ISuperfluid } from "./ISuperfluid.sol";


/**
 * @title Superfluid governance interface
 * @author Superfluid
 */
interface ISuperfluidGovernance {

    /**
     * @dev Replace the current governance with a new governance
     */
    function replaceGovernance(
        ISuperfluid host,
        address newGov) external;

    /**
     * @dev Register a new agreement class
     */
    function registerAgreementClass(
        ISuperfluid host,
        address agreementClass) external;

    /**
     * @dev Update logics of the contracts
     *
     * @custom:note 
     * - Because they might have inter-dependencies, it is good to have one single function to update them all
     */
    function updateContracts(
        ISuperfluid host,
        address hostNewLogic,
        address[] calldata agreementClassNewLogics,
        address superTokenFactoryNewLogic
    ) external;

    /**
     * @dev Update supertoken logic contract to the latest that is managed by the super token factory
     */
    function batchUpdateSuperTokenLogic(
        ISuperfluid host,
        ISuperToken[] calldata tokens) external;
    
    /**
     * @dev Set configuration as address value
     */
    function setConfig(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key,
        address value
    ) external;
    
    /**
     * @dev Set configuration as uint256 value
     */
    function setConfig(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key,
        uint256 value
    ) external;

    /**
     * @dev Clear configuration
     */
    function clearConfig(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key
    ) external;

    /**
     * @dev Get configuration as address value
     */
    function getConfigAsAddress(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key) external view returns (address value);

    /**
     * @dev Get configuration as uint256 value
     */
    function getConfigAsUint256(
        ISuperfluid host,
        ISuperfluidToken superToken,
        bytes32 key) external view returns (uint256 value);

}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

import { ISuperAgreement } from "./ISuperAgreement.sol";


/**
 * @title Superfluid token interface
 * @author Superfluid
 */
interface ISuperfluidToken {

    /**************************************************************************
     * Basic information
     *************************************************************************/

    /**
     * @dev Get superfluid host contract address
     */
    function getHost() external view returns(address host);

    /**
     * @dev Encoded liquidation type data mainly used for handling stack to deep errors
     *
     * @custom:note 
     * - version: 1
     * - liquidationType key:
     *    - 0 = reward account receives reward (PIC period)
     *    - 1 = liquidator account receives reward (Pleb period)
     *    - 2 = liquidator account receives reward (Pirate period/bailout)
     */
    struct LiquidationTypeData {
        uint256 version;
        uint8 liquidationType;
    }

    /**************************************************************************
     * Real-time balance functions
     *************************************************************************/

    /**
    * @dev Calculate the real balance of a user, taking in consideration all agreements of the account
    * @param account for the query
    * @param timestamp Time of balance
    * @return availableBalance Real-time balance
    * @return deposit Account deposit
    * @return owedDeposit Account owed Deposit
    */
    function realtimeBalanceOf(
       address account,
       uint256 timestamp
    )
        external view
        returns (
            int256 availableBalance,
            uint256 deposit,
            uint256 owedDeposit);

    /**
     * @notice Calculate the realtime balance given the current host.getNow() value
     * @dev realtimeBalanceOf with timestamp equals to block timestamp
     * @param account for the query
     * @return availableBalance Real-time balance
     * @return deposit Account deposit
     * @return owedDeposit Account owed Deposit
     */
    function realtimeBalanceOfNow(
       address account
    )
        external view
        returns (
            int256 availableBalance,
            uint256 deposit,
            uint256 owedDeposit,
            uint256 timestamp);

    /**
    * @notice Check if account is critical
    * @dev A critical account is when availableBalance < 0
    * @param account The account to check
    * @param timestamp The time we'd like to check if the account is critical (should use future)
    * @return isCritical Whether the account is critical
    */
    function isAccountCritical(
        address account,
        uint256 timestamp
    )
        external view
        returns(bool isCritical);

    /**
    * @notice Check if account is critical now (current host.getNow())
    * @dev A critical account is when availableBalance < 0
    * @param account The account to check
    * @return isCritical Whether the account is critical
    */
    function isAccountCriticalNow(
        address account
    )
        external view
        returns(bool isCritical);

    /**
     * @notice Check if account is solvent
     * @dev An account is insolvent when the sum of deposits for a token can't cover the negative availableBalance
     * @param account The account to check
     * @param timestamp The time we'd like to check if the account is solvent (should use future)
     * @return isSolvent True if the account is solvent, false otherwise
     */
    function isAccountSolvent(
        address account,
        uint256 timestamp
    )
        external view
        returns(bool isSolvent);

    /**
     * @notice Check if account is solvent now
     * @dev An account is insolvent when the sum of deposits for a token can't cover the negative availableBalance
     * @param account The account to check
     * @return isSolvent True if the account is solvent, false otherwise
     */
    function isAccountSolventNow(
        address account
    )
        external view
        returns(bool isSolvent);

    /**
    * @notice Get a list of agreements that is active for the account
    * @dev An active agreement is one that has state for the account
    * @param account Account to query
    * @return activeAgreements List of accounts that have non-zero states for the account
    */
    function getAccountActiveAgreements(address account)
       external view
       returns(ISuperAgreement[] memory activeAgreements);


   /**************************************************************************
    * Super Agreement hosting functions
    *************************************************************************/

    /**
     * @dev Create a new agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    function createAgreement(
        bytes32 id,
        bytes32[] calldata data
    )
        external;
    /**
     * @dev Agreement created event
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    event AgreementCreated(
        address indexed agreementClass,
        bytes32 id,
        bytes32[] data
    );

    /**
     * @dev Get data of the agreement
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @return data Data of the agreement
     */
    function getAgreementData(
        address agreementClass,
        bytes32 id,
        uint dataLength
    )
        external view
        returns(bytes32[] memory data);

    /**
     * @dev Create a new agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    function updateAgreementData(
        bytes32 id,
        bytes32[] calldata data
    )
        external;
    /**
     * @dev Agreement updated event
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param data Agreement data
     */
    event AgreementUpdated(
        address indexed agreementClass,
        bytes32 id,
        bytes32[] data
    );

    /**
     * @dev Close the agreement
     * @param id Agreement ID
     */
    function terminateAgreement(
        bytes32 id,
        uint dataLength
    )
        external;
    /**
     * @dev Agreement terminated event
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     */
    event AgreementTerminated(
        address indexed agreementClass,
        bytes32 id
    );

    /**
     * @dev Update agreement state slot
     * @param account Account to be updated
     *
     * @custom:note 
     * - To clear the storage out, provide zero-ed array of intended length
     */
    function updateAgreementStateSlot(
        address account,
        uint256 slotId,
        bytes32[] calldata slotData
    )
        external;
    /**
     * @dev Agreement account state updated event
     * @param agreementClass Contract address of the agreement
     * @param account Account updated
     * @param slotId slot id of the agreement state
     */
    event AgreementStateUpdated(
        address indexed agreementClass,
        address indexed account,
        uint256 slotId
    );

    /**
     * @dev Get data of the slot of the state of an agreement
     * @param agreementClass Contract address of the agreement
     * @param account Account to query
     * @param slotId slot id of the state
     * @param dataLength length of the state data
     */
    function getAgreementStateSlot(
        address agreementClass,
        address account,
        uint256 slotId,
        uint dataLength
    )
        external view
        returns (bytes32[] memory slotData);

    /**
     * @notice Settle balance from an account by the agreement
     * @dev The agreement needs to make sure that the balance delta is balanced afterwards
     * @param account Account to query.
     * @param delta Amount of balance delta to be settled
     *
     * @custom:modifiers 
     *  - onlyAgreement
     */
    function settleBalance(
        address account,
        int256 delta
    )
        external;

    /**
     * @dev Make liquidation payouts (v2)
     * @param id Agreement ID
     * @param liquidationTypeData Data regarding the version of the liquidation schema and the type
     * @param liquidatorAccount Address of the executor of the liquidation
     * @param useDefaultRewardAccount Whether or not the default reward account receives the rewardAmount
     * @param targetAccount Account to be liquidated
     * @param rewardAmount The amount the rewarded account will receive
     * @param targetAccountBalanceDelta The delta amount the target account balance should change by
     *
     * @custom:note 
     * - If a bailout is required (bailoutAmount > 0)
     *   - the actual reward (single deposit) goes to the executor,
     *   - while the reward account becomes the bailout account
     *   - total bailout include: bailout amount + reward amount
     *   - the targetAccount will be bailed out
     * - If a bailout is not required
     *   - the targetAccount will pay the rewardAmount
     *   - the liquidator (reward account in PIC period) will receive the rewardAmount
     *
     * @custom:modifiers 
     *  - onlyAgreement
     */
    function makeLiquidationPayoutsV2
    (
        bytes32 id,
        bytes memory liquidationTypeData,
        address liquidatorAccount,
        bool useDefaultRewardAccount,
        address targetAccount,
        uint256 rewardAmount,
        int256 targetAccountBalanceDelta
    ) external;
    /**
     * @dev Agreement liquidation event v2 (including agent account)
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param liquidatorAccount Address of the executor of the liquidation
     * @param targetAccount Account of the stream sender
     * @param rewardAmountReceiver Account that collects the reward or bails out insolvent accounts
     * @param rewardAmount The amount the reward recipient account balance should change by
     * @param targetAccountBalanceDelta The amount the sender account balance should change by
     * @param liquidationTypeData The encoded liquidation type data including the version (how to decode)
     *
     * @custom:note 
     * Reward account rule:
     * - if the agreement is liquidated during the PIC period
     *   - the rewardAmountReceiver will get the rewardAmount (remaining deposit), regardless of the liquidatorAccount
     *   - the targetAccount will pay for the rewardAmount
     * - if the agreement is liquidated after the PIC period AND the targetAccount is solvent
     *   - the rewardAmountReceiver will get the rewardAmount (remaining deposit)
     *   - the targetAccount will pay for the rewardAmount
     * - if the targetAccount is insolvent
     *   - the liquidatorAccount will get the rewardAmount (single deposit)
     *   - the default reward account (governance) will pay for both the rewardAmount and bailoutAmount
     *   - the targetAccount will receive the bailoutAmount
     */
    event AgreementLiquidatedV2(
        address indexed agreementClass,
        bytes32 id,
        address indexed liquidatorAccount,
        address indexed targetAccount,
        address rewardAmountReceiver,
        uint256 rewardAmount,
        int256 targetAccountBalanceDelta,
        bytes liquidationTypeData
    );

    /**************************************************************************
     * Function modifiers for access control and parameter validations
     *
     * While they cannot be explicitly stated in function definitions, they are
     * listed in function definition comments instead for clarity.
     *
     * NOTE: solidity-coverage not supporting it
     *************************************************************************/

     /// @dev The msg.sender must be host contract
     //modifier onlyHost() virtual;

    /// @dev The msg.sender must be a listed agreement.
    //modifier onlyAgreement() virtual;

    /**************************************************************************
     * DEPRECATED
     *************************************************************************/

    /**
     * @dev Agreement liquidation event (DEPRECATED BY AgreementLiquidatedBy)
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param penaltyAccount Account of the agreement to be penalized
     * @param rewardAccount Account that collect the reward
     * @param rewardAmount Amount of liquidation reward
     *
     * @custom:deprecated Use AgreementLiquidatedV2 instead
     */
    event AgreementLiquidated(
        address indexed agreementClass,
        bytes32 id,
        address indexed penaltyAccount,
        address indexed rewardAccount,
        uint256 rewardAmount
    );

    /**
     * @dev System bailout occurred (DEPRECATED BY AgreementLiquidatedBy)
     * @param bailoutAccount Account that bailout the penalty account
     * @param bailoutAmount Amount of account bailout
     *
     * @custom:deprecated Use AgreementLiquidatedV2 instead
     */
    event Bailout(
        address indexed bailoutAccount,
        uint256 bailoutAmount
    );

    /**
     * @dev Agreement liquidation event (DEPRECATED BY AgreementLiquidatedV2)
     * @param liquidatorAccount Account of the agent that performed the liquidation.
     * @param agreementClass Contract address of the agreement
     * @param id Agreement ID
     * @param penaltyAccount Account of the agreement to be penalized
     * @param bondAccount Account that collect the reward or bailout accounts
     * @param rewardAmount Amount of liquidation reward
     * @param bailoutAmount Amount of liquidation bailouot
     *
     * @custom:deprecated Use AgreementLiquidatedV2 instead
     *
     * @custom:note 
     * Reward account rule:
     * - if bailout is equal to 0, then
     *   - the bondAccount will get the rewardAmount,
     *   - the penaltyAccount will pay for the rewardAmount.
     * - if bailout is larger than 0, then
     *   - the liquidatorAccount will get the rewardAmouont,
     *   - the bondAccount will pay for both the rewardAmount and bailoutAmount,
     *   - the penaltyAccount will pay for the rewardAmount while get the bailoutAmount.
     */
    event AgreementLiquidatedBy(
        address liquidatorAccount,
        address indexed agreementClass,
        bytes32 id,
        address indexed penaltyAccount,
        address indexed bondAccount,
        uint256 rewardAmount,
        uint256 bailoutAmount
    );
}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { TokenInfo } from "./TokenInfo.sol";

/**
 * @title ERC20 token with token info interface
 * @author Superfluid
 * @dev Using abstract contract instead of interfaces because old solidity
 *      does not support interface inheriting other interfaces
 * solhint-disable-next-line no-empty-blocks
 *
 */
// solhint-disable-next-line no-empty-blocks
abstract contract ERC20WithTokenInfo is IERC20, TokenInfo {}

// SPDX-License-Identifier: AGPLv3
pragma solidity >= 0.8.0;

/**
 * @title ERC20 token info interface
 * @author Superfluid
 * @dev ERC20 standard interface does not specify these functions, but
 *      often the token implementations have them.
 */
interface TokenInfo {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.9;

// Import this file to use console.log
import "hardhat/console.sol";

import { ISuperfluid, ISuperToken } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperfluid.sol";

import { IInstantDistributionAgreementV1 } from "@superfluid-finance/ethereum-contracts/contracts/interfaces/agreements/IInstantDistributionAgreementV1.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";


contract AnyaVerse is ERC721URIStorageUpgradeable, AccessControlUpgradeable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    /// @dev Initialization data.
    /// @param host Superfluid host contract for calling agreements.
    /// @param ida Instant Distribution Agreement contract.
    struct InitData {
        ISuperfluid host;
        IInstantDistributionAgreementV1 ida;
    }

    InitData public idaV1;

    ISuperToken public anyaToken;                   // Token to be distributed to unit holders by distribute() function

    uint32 public INDEX_ID = 0;                     // The IDA Index. Since this contract will only use one index, we'll hardcode it to "0".
    
    // Access role for minters
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyRoleOrAdminRole(bytes32 _role){
        require(hasRole(_role, _msgSender()) || hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "AccessControl: missing required role or super admin role");
        _;
    }

    function initialize(ISuperfluid _host, ISuperToken _anyaToken) external initializer{
        __ERC721_init("AnyaVerse", "AV");
        // Ensure _spreaderToken is indeed a super token
        require(address(_host) == _anyaToken.getHost(),"!superToken");
        anyaToken = _anyaToken;
        // Initializing the host and agreement type in the idaV1 object so the object can have them on hand for enacting IDA functions
        // Read more on initialization: https://docs.superfluid.finance/superfluid/developers/solidity-examples/solidity-libraries/idav1-library#importing-and-initialization
        idaV1 = InitData(
            _host,
            IInstantDistributionAgreementV1(
                address(_host.getAgreementClass(keccak256("org.superfluid-finance.agreements.InstantDistributionAgreement.v1")))
            )
        );
        // Creates the IDA Index through which tokens will be distributed
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
            idaV1.ida.createIndex.selector,
                anyaToken,
                INDEX_ID,
                new bytes(0)
            ),
            new bytes(0)
        );       
    }

    function mint(address _receiver, string calldata _tokenURI) external onlyRoleOrAdminRole(MINTER_ROLE){
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(_receiver, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        // Updates the subscribtion unit of receiver
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
                idaV1.ida.updateSubscription.selector,
                anyaToken,
                INDEX_ID,
                _receiver,
                balanceOf(_receiver),
                new bytes(0)
            ),
            new bytes(0)
        );
    }

    /// @notice Takes the entire balance of the designated spreaderToken in the contract and distributes it out to unit holders w/ IDA
    function distribute() external onlyRole(DEFAULT_ADMIN_ROLE) {
        
        uint256 anyaTokenBalance = anyaToken.balanceOf(address(this));

        (uint256 actualDistributionAmount,) = idaV1.ida.calculateDistribution(
            anyaToken,
            address(this),
            INDEX_ID,
            anyaTokenBalance
        );
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
                idaV1.ida.distribute.selector,
                anyaToken,
                INDEX_ID,
                actualDistributionAmount,
                new bytes(0)
            ),
            new bytes(0)
        );
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
        // Updates the subscribtion unit of receiver
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
                idaV1.ida.updateSubscription.selector,
                anyaToken,
                INDEX_ID,
                to,
                balanceOf(to),
                new bytes(0)
            ),
            new bytes(0)
        );
        // Updates the subscribtion unit of sender
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
                idaV1.ida.updateSubscription.selector,
                anyaToken,
                INDEX_ID,
                from,
                balanceOf(from),
                new bytes(0)
            ),
            new bytes(0)
        );
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
        // Updates the subscribtion unit of receiver
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
                idaV1.ida.updateSubscription.selector,
                anyaToken,
                INDEX_ID,
                to,
                balanceOf(to),
                new bytes(0)
            ),
            new bytes(0)
        );
        // Updates the subscribtion unit of sender
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
                idaV1.ida.updateSubscription.selector,
                anyaToken,
                INDEX_ID,
                from,
                balanceOf(from),
                new bytes(0)
            ),
            new bytes(0)
        );
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
        // Updates the subscribtion unit of receiver
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
                idaV1.ida.updateSubscription.selector,
                anyaToken,
                INDEX_ID,
                to,
                balanceOf(to),
                new bytes(0)
            ),
            new bytes(0)
        );
        // Updates the subscribtion unit of sender
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
                idaV1.ida.updateSubscription.selector,
                anyaToken,
                INDEX_ID,
                from,
                balanceOf(from),
                new bytes(0)
            ),
            new bytes(0)
        );
    }

    function burn(uint256 _tokenId) external{
        require(ownerOf(_tokenId) == _msgSender(), "ERC721: burn caller is not owner");
        _burn(_tokenId);
        // Delete the subscribtion of sender
        idaV1.host.callAgreement(
            idaV1.ida,
            abi.encodeWithSelector(
                idaV1.ida.deleteSubscription.selector,
                anyaToken,
                address(this),
                INDEX_ID,
                _msgSender(),
                new bytes(0)
            ),
            new bytes(0)
        );
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721Upgradeable, AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}