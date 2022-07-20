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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Metadata } from "./Metadata.sol";
import { Nation } from "./Nation/Nation.sol";
import { Notary } from "./Notary/Notary.sol";

/**
 * @title CitizenAlpha
 * @author Kames Geraghty
 * @notice A Web3 of Trust experiment.
 */
contract CitizenAlpha is ERC721, Ownable {
  /// @notice Total citizenships issued
  uint256 private _idCounter;

  /// @notice Metadata instance; External tokenURI call
  address private _metadata;

  /// @notice Nation instance; Global AccessControl
  address private _nation;

  /// @notice Notary instance; Citizenship Management
  address private _notary;

  /// @notice TrustResolver instance; Unique tokenURI
  address private _resolver;

  /// @notice Enable tokenURI split logic operator
  bool private _tokenURISplit;

  /// @notice Reverse lookup of a tokenId using the owner address
  mapping(address => uint256) private _tokenIds;

  /// @notice Lookup address of Citizenship trust link
  mapping(address => address) private _links;

  /**
   * @notice Emit when Citizenship is issued.
   * @param id Citizen ID
   * @param citizen Address of new Citizen
   * @param link Address of  Citizen issuing new Citizenship
   */
  event Issued(uint256 id, address indexed citizen, address indexed link);

  /**
   * @notice Emit when Citizenship is revoked.
   * @param id Citizen ID
   * @param citizen Address of new Citizen
   * @param link Address of Founder revoking Citizenship
   */
  event Revoked(uint256 id, address indexed citizen, address indexed link);

  /**
   * @notice Emit when Metadata instnace is updated.
   * @param metadata Address of new Metadata instance
   */
  event NewMetadata(address metadata);

  /**
   * @notice Emit when Nation instnace is updated.
   * @param nation Address of new Nation instance
   */
  event NewNation(address nation);

  /**
   * @notice Emit when Notary instnace is updated.
   * @param notary Address of new Notary instance
   */
  event NewNotary(address notary);

  /**
   * @notice Emit when Resolver instnace is updated.
   * @param resolver Address of new Resolver instance
   */
  event NewResolver(address resolver);

  /**
   * @notice CitizenAlpha Construction
   * @param metadata_ address - Metadata instance
   * @param name_ string - Name of ERC721 token
   * @param symbol_ string - Symbol of ERC721 token
   */
  constructor(
    address metadata_,
    string memory name_,
    string memory symbol_
  ) ERC721(name_, symbol_) {
    _metadata = metadata_;
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  /**
   * @notice Get Metadata instance
   * @return metadata Metadata
   */
  function getMetadata() external view returns (address metadata) {
    return _metadata;
  }

  /**
   * @notice Get Nation instance
   * @return nation Nation
   */
  function getNation() external view returns (address nation) {
    return _nation;
  }

  /**
   * @notice Get Notary instance
   * @return notary Notary
   */
  function getNotary() external view returns (address notary) {
    return _notary;
  }

  /**
   * @notice Get Resolver instance
   * @return resolver Resolver
   */
  function getResolver() external view returns (address resolver) {
    return _resolver;
  }

  /**
   * @notice Read totalIssued (_idCounter)
   * @return totalIssued uint256
   */
  function totalIssued() external view returns (uint256) {
    return _idCounter;
  }

  /**
   * @notice Check Citizenship ID
   * @param citizen address
   * @return id uint256
   */
  function getId(address citizen) external view returns (uint256) {
    require(_isCitizen(citizen), "CitizenAlpha:not-active-citizen");
    return _tokenIds[citizen];
  }

  /**
   * @notice Lookup Citizenship link
   * @param citizen address
   * @return link address
   */
  function getLink(address citizen) external view returns (address link) {
    return _links[citizen];
  }

  /**
   * @notice Check Role status of Citizen via Nation
   * @param citizen Address of Citizen
   * @return status bool
   */
  function hasRole(bytes32 role, address citizen) external view returns (bool) {
    return Nation(_nation).hasRole(role, citizen);
  }

  /**
   * @notice Check Citizenship status
   * @param citizen Address of potential Citizen
   * @return status bool
   */
  function isCitizen(address citizen) external view returns (bool status) {
    return balanceOf(citizen) == 1 ? true : false;
  }

  /**
   * @notice Generate token URI
   * @param tokenId uint256
   * @return metadata string
   */
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    Metadata metadata_ = Metadata(_metadata);
    if (!_tokenURISplit) {
      return metadata_.tokenURI(tokenId);
    } else {
      return
        _resolver == _msgSender()
          ? metadata_.tokenURIResolver(tokenId)
          : metadata_.tokenURI(tokenId);
    }
  }

  /**
   * @notice Issue a new Citizenship
   * @param to address
   */
  function issue(address to) external {
    address _sender = _msgSender();
    require(Notary(_notary).isNotary(_sender), "CitizenAlpha:not-notary");
    require(!_isCitizen(to), "CitizenAlpha:is-citizen");
    require(!_isPreviouslyIssued(to), "CitizenAlpha:revoked-citizenship");
    _issue(to, _sender);
  }

  /**
   * @notice Revoke an existing Citizenship
   * @param from address
   */
  function revoke(address from) external {
    address _sender = _msgSender();
    require(Notary(_notary).isNotary(_sender), "CitizenAlpha:not-notary");
    require(_isCitizen(from), "CitizenAlpha:not-citizen");
    _revoke(from, _sender);
  }

  /**
   * @notice Reset Citizenship status
   * @param citizen address
   */
  function reset(address citizen) external {
    require(Notary(_notary).isNotary(_msgSender()), "CitizenAlpha:not-notary");
    require(!_isCitizen(citizen), "CitizenAlpha:is-citizen");
    require(_isPreviouslyIssued(citizen), "CitizenAlpha:never-citizen");
    _tokenIds[citizen] = 0;
  }

  /**
   * @notice Set URI Splitter status
   * @param status bool
   */
  function setURISplitter(bool status) external onlyOwner {
    _tokenURISplit = status;
  }

  /**
   * @notice Set Metadata instance
   * @param metadata address
   */
  function setMetadata(address metadata) external onlyOwner {
    _metadata = metadata;
    emit NewMetadata(metadata);
  }

  /**
   * @notice Set Nation instance
   * @param nation address
   */
  function setNation(address nation) external onlyOwner {
    _nation = nation;
    emit NewNation(nation);
  }

  /**
   * @notice Set Notary instance
   * @param notary address
   */
  function setNotary(address notary) external onlyOwner {
    _notary = notary;
    emit NewNotary(notary);
  }

  /**
   * @notice Set Resolver instance
   * @param resolver address
   */
  function setResolver(address resolver) external onlyOwner {
    _resolver = resolver;
    emit NewResolver(resolver);
  }

  /**
   * @notice Override transferFrom to make non-transferable
   */
  function transferFrom(
    address,
    address,
    uint256
  ) public virtual override {
    revert("CitizenAlpha: Soulbound");
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /* ===================================================================================== */
  /* Internal Functions                                                                    */
  /* ===================================================================================== */

  function _isCitizen(address citizen) internal view returns (bool) {
    return balanceOf(citizen) == 1 ? true : false;
  }

  /**
   * @dev First Founder can be issued<>revoked<>issued.
   *      All other address can only be issued<>revoked.
   *      Unless the account is reset.
   */
  function _isPreviouslyIssued(address citizen) internal view returns (bool) {
    return _tokenIds[citizen] != 0 ? true : false;
  }

  function _issue(address to, address link) internal {
    uint256 __idCounter = _idCounter++;
    _links[to] = link;
    _tokenIds[to] = __idCounter;
    _mint(to, __idCounter);
    emit Issued(__idCounter, to, link);
  }

  function _revoke(address from, address link) internal {
    uint256 tokenId = _tokenIds[from];
    _burn(tokenId);
    emit Revoked(tokenId, from, link);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import { Base64 } from "base64-sol/base64.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { svg } from "./libraries/SVG.sol";
import { svgUtils } from "./libraries/SVGUtils.sol";
import { SVGColor } from "./libraries/SVGColor.sol";
import { ISource } from "./interfaces/ISource.sol";
import { ICitizenAlpha } from "./interfaces/ICitizenAlpha.sol";
import { SourceENS } from "./Sources/SourceENS.sol";
import { CitizenAlpha } from "./CitizenAlpha.sol";
import { SVGRender } from "./SVGRender.sol";

/**
 * @title Metadata
 * @author Kames Geraghty
 * @notice CitizenAlpha metadata resolver.
 */
contract Metadata is Ownable {
  using Strings for uint256;

  /// @notice Token instance
  address private _token;

  /// @notice SVGRender instance
  address private _svgRender;

  /// @notice ISources[] list
  address[] private _sources;

  struct Metadata {
    string name;
    string description;
    string avatar;
    string did;
    string ensAlias;
    string ensNode;
    string ensResolver;
    string traits;
  }

  struct ExternalMetadata {
    string avatar;
    string did;
    string ensNode;
    string ensAlias;
    string ensResolver;
    string traits;
  }

  constructor(address _svgRender_) {
    _svgRender = _svgRender_;
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  /**
   * @notice Get Token instance
   * @return token Token
   */
  function getToken() external view returns (address token) {
    return _token;
  }

  /**
   * @notice Get Token instance
   * @return token Token
   */
  function getSVGRender() external view returns (address token) {
    return _svgRender;
  }

  function getSourceData(uint256 idx, address user)
    external
    view
    returns (string[] memory, string[] memory)
  {
    return _getSourceData(idx, user);
  }

  function getSourcesData(address user) external view returns (string[] memory, string[] memory) {
    return _getSourcesData(user);
  }

  /**
   * @notice Construct tokenURI
   * @param tokenId address
   * @return uri string - Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId) external view returns (string memory) {
    return _constructTokenURI(tokenId);
  }

  /**
   * @notice Construct resolver tokenURI
   * @param tokenId address
   * @return uri string - Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURIResolver(uint256 tokenId) external view returns (string memory) {
    return _constructTokenURIResolver(tokenId);
  }

  /**
   * @notice Get User Metadata
   * @param user address
   * @return metadata Metadata
   */
  function getMetadata(address user) external view returns (Metadata memory) {
    return _constructMetadata(user, CitizenAlpha(_token).getId(user));
  }

  /**
   * @notice Get User Avatar
   * @param user address
   * @return avatar string
   */
  function getAvatar(address user) external view returns (string memory) {
    uint256 _tokenId = ICitizenAlpha(_token).getId(user);
    SourceENS _resolverEns = SourceENS(_sources[0]);
    (, string memory alias_, ) = _resolverEns.getMetadata(user);
    string memory avatar_ = _resolverEns.getValue(user, "avatar");
    return _generateAvatar(avatar_, _tokenId, alias_);
  }

  /**
   * @notice Get User Image
   * @param user address
   * @return avatar string
   */
  function getImage(address user) external view returns (string memory) {
    uint256 _tokenId = ICitizenAlpha(_token).getId(user);
    SourceENS _resolverEns = SourceENS(_sources[0]);
    (, string memory alias_, ) = _resolverEns.getMetadata(user);
    return _generateImage(_tokenId, alias_);
  }

  /**
   * @notice Append Source instance
   * @param source address
   */
  function appendSource(address source) external onlyOwner {
    _sources.push(source);
  }

  /**
   * @notice Set Source instance
   * @param idx uint256
   * @param source address
   */
  function updateSource(uint256 idx, address source) external onlyOwner {
    require(idx < _sources.length - 1, "Metadata:invalid-index");
    _sources[idx] = source;
  }

  /**
   * @notice Set Token instance
   * @param token_ address
   */
  function setToken(address token_) external onlyOwner {
    _token = token_;
  }

  /**
   * @notice Set SVGRender instance
   * @param svgRender_ address
   */
  function setSVGRender(address svgRender_) external onlyOwner {
    _svgRender = svgRender_;
  }

  /* ===================================================================================== */
  /* Internal Functions                                                                    */
  /* ===================================================================================== */

  function _constructTokenURI(uint256 _tokenId) internal view returns (string memory) {
    ICitizenAlpha token_ = ICitizenAlpha(_token);
    Metadata memory _meta = _constructMetadata(token_.ownerOf(_tokenId), _tokenId);

    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              string.concat(
                '{"name":',
                '"',
                _meta.name,
                '",',
                '"description":',
                '"',
                _meta.description,
                '",',
                '"image":',
                '"',
                _meta.avatar,
                '",',
                '"attributes": [',
                _meta.traits,
                "]",
                "}"
              )
            )
          )
        )
      );
  }

  function _constructTokenURIResolver(uint256 _tokenId) internal view returns (string memory) {
    ICitizenAlpha token_ = ICitizenAlpha(_token);
    address owner_ = token_.ownerOf(_tokenId);
    ExternalMetadata memory externalMetadata_ = _getExternalMetadata(owner_, _tokenId);
    string memory name_ = string(abi.encodePacked("Citizen #", _tokenId.toString()));
    string memory description_ = bytes(externalMetadata_.ensAlias).length > 0
      ? externalMetadata_.ensAlias
      : Strings.toHexString(uint256(uint160(owner_)), 20);
    string memory avatar_ = _generateImage(_tokenId, externalMetadata_.ensAlias);
    address link_ = ICitizenAlpha(_token).getLink(owner_);
    return
      string(
        abi.encodePacked(
          "data:application/json;base64,",
          Base64.encode(
            bytes(
              string.concat(
                '{"name":',
                '"',
                name_,
                '",',
                '"description":',
                '"',
                description_,
                '",',
                '"image":',
                '"',
                avatar_,
                '",',
                '"attributes": [',
                _generateTrait("link", Strings.toHexString(uint256(uint160(link_)), 20)),
                "]",
                "}"
              )
            )
          )
        )
      );
  }

  function _constructMetadata(address user, uint256 tokenId)
    internal
    view
    returns (Metadata memory)
  {
    ExternalMetadata memory externalMetadata_ = _getExternalMetadata(user, tokenId);
    string memory name_ = string(abi.encodePacked("Citizen #", tokenId.toString()));
    string memory description_ = bytes(externalMetadata_.ensAlias).length > 0
      ? externalMetadata_.ensAlias
      : Strings.toHexString(uint256(uint160(user)), 20);
    address link_ = ICitizenAlpha(_token).getLink(user);

    Metadata memory _meta = Metadata({
      name: name_,
      description: description_,
      avatar: externalMetadata_.avatar,
      did: externalMetadata_.did,
      ensNode: externalMetadata_.ensNode,
      ensAlias: externalMetadata_.ensAlias,
      ensResolver: externalMetadata_.ensResolver,
      traits: string.concat(
        externalMetadata_.traits,
        _generateTrait("link", Strings.toHexString(uint256(uint160(link_)), 20))
      )
    });

    return _meta;
  }

  function _getExternalMetadata(address user, uint256 _tokenId)
    internal
    view
    returns (ExternalMetadata memory)
  {
    /// @dev ENS resolver must always be in the first slot. TODO: make better
    SourceENS _resolverEns = SourceENS(_sources[0]);
    string memory did_ = _resolverEns.getValue(user, "did");
    string memory avatar_ = _resolverEns.getValue(user, "avatar");
    (bytes32 node, string memory alias_, address resolver_) = _resolverEns.getMetadata(user);
    string memory traits_ = _getUnwrappedTraits(user);
    return
      ExternalMetadata({
        avatar: _generateAvatar(avatar_, _tokenId, alias_),
        did: did_,
        ensNode: string(abi.encodePacked(node)),
        ensAlias: string(alias_),
        ensResolver: resolver_ != 0x0000000000000000000000000000000000000000
          ? Strings.toHexString(uint256(uint160(resolver_)), 20)
          : "",
        traits: traits_
      });
  }

  function _getExternalAvatar(address user, uint256 _tokenId)
    internal
    view
    returns (string memory)
  {
    /// @dev ENS PublicResolver must be in first slot. TODO: make better in V2
    SourceENS _resolverEns = SourceENS(_sources[0]);
    string memory avatar_ = _resolverEns.getValue(user, "avatar");
    (, string memory alias_, ) = _resolverEns.getMetadata(user);
    return _generateAvatar(avatar_, _tokenId, alias_);
  }

  function _getUnwrappedTraits(address user) internal view returns (string memory) {
    (string[] memory keys_, string[] memory values_) = _getSourcesData(user);
    return _generateTraits(keys_, values_);
  }

  function _getSourceData(uint256 _sourceIndex, address _user)
    internal
    view
    returns (string[] memory, string[] memory)
  {
    ISource _source = ISource(_sources[_sourceIndex]);
    uint256 count = _source.count(_user);

    string[] memory keys_ = new string[](count);
    string[] memory values_ = new string[](count);

    (string[] memory keys__, string[] memory values__) = _source.getData(_user);

    for (uint256 k = 0; k < count; k++) {
      keys_[k] = (keys__[k]);
      values_[k] = values__[k];
    }

    return (keys_, values_);
  }

  function _getSourcesData(address _user) internal view returns (string[] memory, string[] memory) {
    uint256 count = 0;
    address[] memory __sources = _sources;
    for (uint256 i = 0; i < __sources.length; i++) {
      ISource _source = ISource(__sources[i]);
      count = count + _source.count(_user);
    }

    string[] memory keys_ = new string[](count);
    string[] memory values_ = new string[](count);

    uint256 __start;
    for (uint256 i = 0; i < __sources.length; i++) {
      ISource _source = ISource(__sources[i]);
      (string[] memory keys__, string[] memory values__) = _source.getData(_user);
      for (uint256 k = __start; k < count; k++) {
        keys_[k] = (keys__[k]);
        values_[k] = values__[k];
      }
    }

    return (keys_, values_);
  }

  /* ===================================================================================== */
  /* Traits Functions                                                                      */
  /* ===================================================================================== */

  function _appendTrait(string memory _traits, string memory _traitAppending)
    internal
    pure
    returns (string memory)
  {
    return string.concat(_traits, bytes(_traits).length > 0 ? "," : "", _traitAppending);
  }

  function _generateTrait(string memory _key, string memory _value)
    internal
    pure
    returns (string memory __traits)
  {
    return string.concat('{"trait_type":' '"', _key, '",', '"value":', '"', _value, '"}');
  }

  function _generateTraits(string[] memory _keys, string[] memory _values)
    internal
    pure
    returns (string memory __traits)
  {
    string memory _traits = "";
    for (uint256 i = 0; i < _keys.length; i++) {
      if (bytes(_values[i]).length > 0) {
        _traits = string.concat(_traits, _generateTrait(_keys[i], _values[i]), ",");
      }
    }
    return _traits;
  }

  function _generateAvatar(
    string memory _avatar,
    uint256 tokenId,
    string memory alias_
  ) internal view returns (string memory) {
    if (bytes(_avatar).length == 0) {
      return
        string(
          abi.encodePacked(
            "data:image/svg+xml;base64,",
            Base64.encode(bytes(SVGRender(_svgRender).generate(tokenId, alias_)))
          )
        );
    }
    return _avatar;
  }

  function _generateImage(uint256 tokenId, string memory alias_)
    internal
    view
    returns (string memory)
  {
    return
      string(
        abi.encodePacked(
          "data:image/svg+xml;base64,",
          Base64.encode(bytes(SVGRender(_svgRender).generate(tokenId, alias_)))
        )
      );
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import { AccessControlEnumerable, AccessControl, IAccessControl } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { CitizenAlpha } from "../CitizenAlpha.sol";
import { Notary } from "../Notary/Notary.sol";

/**
 * @title Nation
 * @author Kames Geraghty
 * @notice Nation is an AccessControl layer for CitizenAlpha.
 * @dev Extends Citizen on-chain permissions using updatables nested Roles.
           
 */
contract Nation is AccessControlEnumerable {
  /// @notice CitizenAlpha instance
  address private _citizenAlpha;

  /// @notice Founder Role
  bytes32 private constant FOUNDER = keccak256("FOUNDER");

  /// @notice Governance Role
  bytes32 private constant GOVERNANCE = keccak256("GOVERNANCE");

  /// @notice Global Role AccessControl
  mapping(bytes32 => bool) private _roleActive;

  /**
   * @notice Nation Constructor
   * @param _founders addresses array of FOUNDERS
   */
  constructor(address _citizenAlpha_, address[] memory _founders) {
    _citizenAlpha = _citizenAlpha_;
    _roleActive[FOUNDER] = true;
    _roleActive[GOVERNANCE] = true;
    _roleActive[DEFAULT_ADMIN_ROLE] = true;
    for (uint256 i = 0; i < _founders.length; i++) {
      _setupRole(FOUNDER, _founders[i]);
      _setupRole(DEFAULT_ADMIN_ROLE, _founders[i]);
    }
    _setRoleAdmin(FOUNDER, DEFAULT_ADMIN_ROLE);
  }

  /**
   * @notice Admin modifier
   * @param role bytes32
   */
  modifier _onlyAdmin(bytes32 role) {
    address sender_ = _msgSender();
    require(
      hasRole(getRoleAdmin(role), sender_) ||
        hasRole(GOVERNANCE, sender_) ||
        hasRole(DEFAULT_ADMIN_ROLE, sender_),
      "Nation:unauthorized"
    );
    _;
  }

  /**
   * @notice Governance modifier
   */
  modifier _onlyGovernance() {
    address sender_ = _msgSender();
    require(
      (hasRole(GOVERNANCE, sender_) || hasRole(DEFAULT_ADMIN_ROLE, sender_)),
      "Nation:unauthorized"
    );
    _;
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  /**
   * @notice Get CitizenAlpha instance
   * @return citizenAlpha address of CitizenAlpha instance
   */
  function getCitizenAlpha() external view returns (address) {
    return _citizenAlpha;
  }

  /**
   * @notice Check if Account has Role
   * @dev Include check for Role activication is Citizenship
   * @return active bool
   */
  function hasRole(bytes32 role, address account)
    public
    view
    virtual
    override(AccessControl, IAccessControl)
    returns (bool)
  {
    if (!_roleActive[role] || !CitizenAlpha(_citizenAlpha).isCitizen(account)) {
      return false;
    }
    return super.hasRole(role, account);
  }

  /**
   * @notice Check Founder status
   * @param citizen address
   * @return status bool
   */
  function isFounder(address citizen) external view returns (bool status) {
    return hasRole(FOUNDER, citizen);
  }

  /**
   * @notice Check Governance status
   * @param module address
   * @return status bool
   */
  function isGovernance(address module) external view returns (bool status) {
    return hasRole(GOVERNANCE, module);
  }

  /**
   * @notice Get status of Role global settings
   * @return status bool
   */
  function roleStatus(bytes32 role) external view returns (bool status) {
    return _roleActive[role];
  }

  /**
   * @notice Grant Role to Citizen
   * @param role bytes32
   * @param citizen address
   */
  function grantRole(bytes32 role, address citizen)
    public
    virtual
    override(AccessControl, IAccessControl)
    _onlyAdmin(role)
  {
    require(_roleActive[role], "Nation:inactive-role");
    _grantRole(role, citizen);
  }

  /**
   * @notice Revoke Role from Citizen
   * @param role bytes32
   * @param citizen address
   */
  function revokeRole(bytes32 role, address citizen)
    public
    virtual
    override(AccessControl, IAccessControl)
    _onlyAdmin(role)
  {
    require(role != DEFAULT_ADMIN_ROLE, "Nation:invalid-request");
    require(_roleActive[role], "Nation:inactive-role");
    _revokeRole(role, citizen);
  }

  /**
   * @notice Enable Role status
   * @param role bytes32
   */
  function enableRole(bytes32 role) external onlyRole(FOUNDER) {
    require(_roleActive[role] == false, "Nation:role-enabled");
    _setRoleAdmin(role, FOUNDER);
    _roleActive[role] = true;
  }

  /**
   * @notice Enable Role status
   * @param role bytes32
   * @param adminRole bytes32
   */
  function enableRoleWithAdmin(bytes32 role, bytes32 adminRole) external _onlyGovernance {
    require(_roleActive[role] == false, "Nation:role-enabled");
    _setRoleAdmin(role, adminRole);
    _roleActive[role] = true;
  }

  /**
   * @notice Disable Role status
   * @param role bytes32
   */
  function disableRole(bytes32 role) external _onlyGovernance {
    require(_roleActive[role] == true, "Nation:role-disabled");
    _setRoleAdmin(role, DEFAULT_ADMIN_ROLE);
    _roleActive[role] = false;
  }

  /**
   * @notice Set Role admin
   * @param role bytes32
   * @param adminRole bytes32
   */
  function setRoleAdmin(bytes32 role, bytes32 adminRole) external _onlyGovernance {
    _setRoleAdmin(role, adminRole);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ICitizenAlpha } from "../interfaces/ICitizenAlpha.sol";

/**
 * @title Notary
 * @author Kames Geraghty
 * @notice Notary is a minimal AccessControl layer for Citizen issuance.
 */
contract Notary is AccessControl {
  /// @notice CitizenAlpha instance
  address private _citizenAlpha;

  /// @notice Notary Role
  bytes32 private constant NOTARY = keccak256("NOTARY");

  /**
   * @notice Notary Constructor
   * @dev Set CitizenAlpha instance and set start Notaries.
   * @param _citizenAlpha_ CitizenAlpha instance
   * @param _notaries Array of Notaries
   */
  constructor(address _citizenAlpha_, address[] memory _notaries) {
    _citizenAlpha = _citizenAlpha_;
    _setupRole(NOTARY, address(this));
    for (uint256 i = 0; i < _notaries.length; i++) {
      _setupRole(DEFAULT_ADMIN_ROLE, _notaries[i]);
      _setupRole(NOTARY, _notaries[i]);
    }
    _setRoleAdmin(NOTARY, DEFAULT_ADMIN_ROLE);
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  function getCitizenAlpha() external view returns (address) {
    return _citizenAlpha;
  }

  /**
   * @notice Check Notary status
   * @param citizen address
   * @return status bool
   */
  function isNotary(address citizen) external view returns (bool status) {
    return hasRole(NOTARY, citizen);
  }

  /**
   * @notice Issue Citizenship
   * @param to address
   */
  function issue(address to) external {
    require(hasRole(NOTARY, _msgSender()), "Notary:unauthorized-access");
    _issue(to);
  }

  /**
   * @notice Batch issue Citizenships
   * @param to address
   */
  function issueBatch(address[] calldata to) external {
    require(hasRole(NOTARY, _msgSender()), "Notary:unauthorized-access");
    for (uint256 i = 0; i < to.length; i++) {
      _issue(to[i]);
    }
  }

  /**
   * @notice Revoke Citizenship
   * @param from address
   */
  function revoke(address from) external {
    require(hasRole(NOTARY, _msgSender()), "Notary:unauthorized-access");
    _revoke(from);
  }

  /**
   * @notice Batch Revoke Citizenships
   * @param from address
   */
  function revokeBatch(address[] calldata from) external {
    require(hasRole(NOTARY, _msgSender()), "Notary:unauthorized-access");
    for (uint256 i = 0; i < from.length; i++) {
      _revoke(from[i]);
    }
  }

  /* ===================================================================================== */
  /* Internal Functions                                                                    */
  /* ===================================================================================== */

  function _issue(address _to) internal {
    ICitizenAlpha(_citizenAlpha).issue(_to);
  }

  function _revoke(address _from) internal {
    ICitizenAlpha(_citizenAlpha).revoke(_from);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import { Base64 } from "base64-sol/base64.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { svg } from "./libraries/SVG.sol";
import { svgUtils } from "./libraries/SVGUtils.sol";
import { SVGColor } from "./libraries/SVGColor.sol";

contract SVGRender is Ownable {
  using Strings for uint256;
  address public svgColor;

  constructor(address _svgColor) {
    svgColor = _svgColor;
  }

  function generate(uint256 _tokenId, string memory _alias) public view returns (string memory) {
    string memory _bgDef = svgUtils.getDefURL("charcoal");

    return
      string(
        abi.encodePacked(
          svg.start(),
          _getDefs(),
          svg.rect(
            string.concat(
              svg.prop("fill", _bgDef),
              svg.prop("x", "0"),
              svg.prop("y", "0"),
              svg.prop("width", "100%"),
              svg.prop("height", "100%")
            ),
            svgUtils.NULL
          ),
          svg.text(
            string.concat(
              svg.prop("x", "50%"),
              svg.prop("y", "50%"),
              svg.prop("dominant-baseline", "middle"),
              svg.prop("text-anchor", "middle"),
              svg.prop("font-size", "48px"),
              svg.prop("fill", "white")
            ),
            string.concat("CIV #", _tokenId.toString())
          ),
          svg.text(
            string.concat(
              svg.prop("x", "50%"),
              svg.prop("y", "60%"),
              svg.prop("dominant-baseline", "middle"),
              svg.prop("text-anchor", "middle"),
              svg.prop("font-size", "22px"),
              svg.prop("fill", "white")
            ),
            _alias
          ),
          svg.end()
        )
      );
  }

  function _getDefs() internal view returns (string memory) {
    return
      svg.defs(
        string.concat(
          svg.linearGradient(
            string.concat(svg.prop("id", "charcoal"), svg.prop("gradientTransform", "rotate(140)")),
            string.concat(
              svg.stop(
                string.concat(
                  svg.prop("offset", "0%"),
                  svg.prop("stop-color", SVGColor(svgColor).getRgba("Dark1"))
                )
              ),
              svg.stop(
                string.concat(
                  svg.prop("offset", "70%"),
                  svg.prop("stop-color", SVGColor(svgColor).getRgba("Dark2"))
                )
              )
            )
          )
        )
      );
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { NameEncoder } from "../libraries/NameEncoder.sol";
import { ISource } from "../interfaces/ISource.sol";
import { IReverseRegistrar } from "../interfaces/ENS/IReverseRegistrar.sol";
import { ITextResolver } from "../interfaces/ENS/ITextResolver.sol";
import { IDefaultReverseResolver } from "../interfaces/ENS/IDefaultReverseResolver.sol";

contract SourceENS is ISource, Ownable {
  using NameEncoder for string;

  string[] private _keys;
  address private constant RESOLVER = 0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41;
  address private constant REVERSE_REGISTRAR = 0x084b1c3C81545d370f3634392De611CaaBFf8148;
  address private constant DEFAULT_REVERSE_RESOLVER = 0xA2C122BE93b0074270ebeE7f6b7292C7deB45047;

  constructor() {
    _keys.push("avatar");
    _keys.push("url");
    _keys.push("description");
    _keys.push("com.github");
    _keys.push("com.twitter");
    _keys.push("org.telegram");
    _keys.push("did");
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  /**
   * @notice Get Keys
   * @return keys string[]
   */
  function getKeys() external view returns (string[] memory keys) {
    return _keys;
  }

  /**
   * @notice Get data fields count for user
   * @return count uint256
   */
  function count(address user) external view returns (uint256 count) {
    (, bytes32 node_, ITextResolver res_) = _resolveOwner(user);
    (string[] memory keys_, ) = _fetchNodeTextFields(_keys, node_, res_);
    return keys_.length;
  }

  /**
   * @notice Get all available data for user
   * @param user address
   * @return keys string[]
   * @return values string[]
   */
  function getData(address user)
    external
    view
    returns (string[] memory keys, string[] memory values)
  {
    (, bytes32 node_, ITextResolver res_) = _resolveOwner(user);
    (string[] memory keys_, string[] memory values_) = _fetchNodeTextFields(_keys, node_, res_);
    return (keys_, values_);
  }

  function getMetadata(address _address)
    external
    view
    returns (
      bytes32 node,
      string memory name,
      address resolver
    )
  {
    (string memory name, bytes32 node, ITextResolver resolver) = _resolveOwner(_address);
    return (node, name, address(resolver));
  }

  /**
   * @notice Get data value for user
   * @param user address
   * @param key string
   * @return value string
   */
  function getValue(address user, string memory key) external view returns (string memory) {
    (, bytes32 node_, ITextResolver res_) = _resolveOwner(user);
    return res_.text(node_, key);
  }

  /**
   * @notice Append Key
   * @param key string
   */
  function appendKey(string calldata key) external onlyOwner {
    _keys.push(key);
  }

  /**
   * @notice Set Key
   * @param idx uint256
   * @param key string
   */
  function updateKey(uint256 idx, string calldata key) external onlyOwner {
    _keys[idx] = key;
  }

  /* ===================================================================================== */
  /* Internal Functions                                                                    */
  /* ===================================================================================== */

  function _resolveOwner(address owner_)
    internal
    view
    returns (
      string memory,
      bytes32,
      ITextResolver
    )
  {
    bytes32 node_ = IReverseRegistrar(REVERSE_REGISTRAR).node(owner_);
    string memory _name = IDefaultReverseResolver(DEFAULT_REVERSE_RESOLVER).name(node_);
    (, bytes32 _node) = _name.dnsEncodeName();
    ITextResolver _resolver = ITextResolver(RESOLVER);
    return (_name, _node, _resolver);
  }

  function _fetchNodeTextFields(
    string[] memory _traits,
    bytes32 _node,
    ITextResolver _resolver
  ) internal view returns (string[] memory keys_, string[] memory values_) {
    string[] memory __keys = new string[](_traits.length);
    string[] memory __values = new string[](_traits.length);
    for (uint256 i = 0; i < _traits.length; i++) {
      __keys[i] = _traits[i];
      __values[i] = _resolver.text(_node, _traits[i]);
    }
    return (__keys, __values);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDefaultReverseResolver {
  function name(bytes32 input) external view returns (string calldata);
}

pragma solidity >=0.8.4;

interface IReverseRegistrar {
  function setDefaultResolver(address resolver) external;

  function claim(address owner) external returns (bytes32);

  function claimForAddr(
    address addr,
    address owner,
    address resolver
  ) external returns (bytes32);

  function claimWithResolver(address owner, address resolver) external returns (bytes32);

  function setName(string memory name) external returns (bytes32);

  function setNameForAddr(
    address addr,
    address owner,
    address resolver,
    string memory name
  ) external returns (bytes32);

  function node(address addr) external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ITextResolver {
  event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

  /**
   * Returns the text data associated with an ENS node and key.
   * @param node The ENS node to query.
   * @param key The text data key to query.
   * @return The associated text data.
   */
  function text(bytes32 node, string calldata key) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ICitizenAlpha {
  function ownerOf(uint256 _id) external view returns (address owner);

  function issue(address _citizen) external;

  function revoke(address _citizen) external;

  function getId(address citizen) external view returns (uint256);

  function getLink(address citizen) external view returns (address issuer);

  function hasRole(bytes32 role, address citizen) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ISource {
  function count(address _address) external view returns (uint256);

  function getData(address _address)
    external
    view
    returns (string[] memory keys, string[] memory values);

  function getValue(address _address, string memory _key) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

library BytesUtils {
  /*
   * @dev Returns the keccak-256 hash of a byte range.
   * @param self The byte string to hash.
   * @param offset The position to start hashing at.
   * @param len The number of bytes to hash.
   * @return The hash of the byte range.
   */
  function keccak(
    bytes memory self,
    uint256 offset,
    uint256 len
  ) internal pure returns (bytes32 ret) {
    require(offset + len <= self.length);
    assembly {
      ret := keccak256(add(add(self, 32), offset), len)
    }
  }

  /**
   * @dev Returns the ENS namehash of a DNS-encoded name.
   * @param self The DNS-encoded name to hash.
   * @param offset The offset at which to start hashing.
   * @return The namehash of the name.
   */
  function namehash(bytes memory self, uint256 offset) internal pure returns (bytes32) {
    (bytes32 labelhash, uint256 newOffset) = readLabel(self, offset);
    if (labelhash == bytes32(0)) {
      require(offset == self.length - 1, "namehash: Junk at end of name");
      return bytes32(0);
    }
    return keccak256(abi.encodePacked(namehash(self, newOffset), labelhash));
  }

  /**
   * @dev Returns the keccak-256 hash of a DNS-encoded label, and the offset to the start of the next label.
   * @param self The byte string to read a label from.
   * @param idx The index to read a label at.
   * @return labelhash The hash of the label at the specified index, or 0 if it is the last label.
   * @return newIdx The index of the start of the next label.
   */
  function readLabel(bytes memory self, uint256 idx)
    internal
    pure
    returns (bytes32 labelhash, uint256 newIdx)
  {
    require(idx < self.length, "readLabel: Index out of bounds");
    uint256 len = uint256(uint8(self[idx]));
    if (len > 0) {
      labelhash = keccak(self, idx + 1, len);
    } else {
      labelhash = bytes32(0);
    }
    newIdx = idx + len + 1;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./BytesUtils.sol";

library NameEncoder {
  using BytesUtils for bytes;

  function dnsEncodeName(string memory name)
    internal
    pure
    returns (bytes memory dnsName, bytes32 node)
  {
    uint8 labelLength = 0;
    bytes memory bytesName = bytes(name);
    uint256 length = bytesName.length;
    dnsName = new bytes(length + 2);
    node = 0;
    if (length == 0) {
      dnsName[0] = 0;
      return (dnsName, node);
    }

    // use unchecked to save gas since we check for an underflow
    // and we check for the length before the loop
    unchecked {
      for (uint256 i = length - 1; i >= 0; i--) {
        if (bytesName[i] == ".") {
          dnsName[i + 1] = bytes1(labelLength);
          node = keccak256(abi.encodePacked(node, bytesName.keccak(i + 1, labelLength)));
          labelLength = 0;
        } else {
          labelLength += 1;
          dnsName[i + 1] = bytesName[i];
        }
        if (i == 0) {
          break;
        }
      }
    }

    node = keccak256(abi.encodePacked(node, bytesName.keccak(0, labelLength)));

    dnsName[0] = bytes1(labelLength);
    return (dnsName, node);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/Strings.sol";
import "./SVGUtils.sol";

/**
 * @title svg
 * @author Kames Geraghty
 * @notice SVG construction library using web-like API.
 * @dev Original code from w1nt3r-eth/hot-chain-svg (https://github.com/w1nt3r-eth/hot-chain-svg)
 */
library svg {
  using Strings for uint256;
  using Strings for uint8;

  function g(string memory _props, string memory _children) internal pure returns (string memory) {
    return el("g", _props, _children);
  }

  function path(string memory _props, string memory _children)
    internal
    pure
    returns (string memory)
  {
    return el("path", _props, _children);
  }

  function text(string memory _props, string memory _children)
    internal
    pure
    returns (string memory)
  {
    return el("text", _props, _children);
  }

  function line(string memory _props, string memory _children)
    internal
    pure
    returns (string memory)
  {
    return el("line", _props, _children);
  }

  function circle(string memory _props, string memory _children)
    internal
    pure
    returns (string memory)
  {
    return el("circle", _props, _children);
  }

  function circle(string memory _props) internal pure returns (string memory) {
    return el("circle", _props);
  }

  function rect(string memory _props, string memory _children)
    internal
    pure
    returns (string memory)
  {
    return el("rect", _props, _children);
  }

  function rect(string memory _props) internal pure returns (string memory) {
    return el("rect", _props);
  }

  function stop(string memory _props) internal pure returns (string memory) {
    return el("stop", _props);
  }

  function filter(string memory _props, string memory _children)
    internal
    pure
    returns (string memory)
  {
    return el("filter", _props, _children);
  }

  function defs(string memory _children) internal pure returns (string memory) {
    return el("defs", "", _children);
  }

  function cdata(string memory _content) internal pure returns (string memory) {
    return string.concat("<![CDATA[", _content, "]]>");
  }

  /* GRADIENTS */
  function radialGradient(string memory _props, string memory _children)
    internal
    pure
    returns (string memory)
  {
    return el("radialGradient", _props, _children);
  }

  function linearGradient(string memory _props, string memory _children)
    internal
    pure
    returns (string memory)
  {
    return el("linearGradient", _props, _children);
  }

  function gradientStop(
    uint256 offset,
    string memory stopColor,
    string memory _props
  ) internal pure returns (string memory) {
    return
      el(
        "stop",
        string.concat(
          prop("stop-color", stopColor),
          " ",
          prop("offset", string.concat(svgUtils.uint2str(offset), "%")),
          " ",
          _props
        )
      );
  }

  function animateTransform(string memory _props) internal pure returns (string memory) {
    return el("animateTransform", _props);
  }

  function image(string memory _href, string memory _props) internal pure returns (string memory) {
    return el("image", string.concat(prop("href", _href), " ", _props));
  }

  function start() internal pure returns (string memory) {
    return
      string.concat(
        '<svg width="400" height="400" style="background:#541563" ',
        'viewBox="0 0 400 400" ',
        'xmlns="http://www.w3.org/2000/svg" ',
        ">"
      );
  }

  function end() internal pure returns (bytes memory) {
    return ("</svg>");
  }

  /* COMMON */
  // A generic element, can be used to construct any SVG (or HTML) element
  function el(
    string memory _tag,
    string memory _props,
    string memory _children
  ) internal pure returns (string memory) {
    return string.concat("<", _tag, " ", _props, ">", _children, "</", _tag, ">");
  }

  // A generic element, can be used to construct any SVG (or HTML) element without children
  function el(string memory _tag, string memory _props) internal pure returns (string memory) {
    return string.concat("<", _tag, " ", _props, "/>");
  }

  // an SVG attribute
  function prop(string memory _key, string memory _val) internal pure returns (string memory) {
    return string.concat(_key, "=", '"', _val, '" ');
  }

  function stringifyIntSet(
    bytes memory _data,
    uint256 _offset,
    uint256 _len
  ) public pure returns (bytes memory) {
    bytes memory res;
    require(_data.length >= _offset + _len, "Out of range");
    for (uint256 i = _offset; i < _offset + _len; i++) {
      res = abi.encodePacked(res, byte2uint8(_data, i).toString(), " ");
    }
    return res;
  }

  function byte2uint8(bytes memory _data, uint256 _offset) public pure returns (uint8) {
    require(_data.length > _offset, "Out of range");
    return uint8(_data[_offset]);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/Strings.sol";

contract SVGColor {
  using Strings for uint256;
  using Strings for uint8;

  mapping(string => bytes) public colors;

  constructor() {
    colors["Black"] = hex"000000";
    colors["White"] = hex"FFFFFF";
    colors["Dark1"] = hex"232323";
    colors["Dark2"] = hex"464646";
  }

  function getColor(string memory _colorName) public view returns (bytes memory) {
    require(colors[_colorName].length == 3, "Unknown color");
    return abi.encodePacked(colors[_colorName], hex"64");
  }

  function getColor(string memory _colorName, uint8 _alpha) public view returns (bytes memory) {
    require(colors[_colorName].length == 3, "Unknown color");
    return abi.encodePacked(colors[_colorName], _alpha);
  }

  function getRgba(string memory _colorName) public view returns (string memory) {
    return string(toRgba(getColor(_colorName), 0));
  }

  // Input: array of colors (without alpha)
  // Ouputs a linearGradient
  function autoLinearGradient(
    bytes memory _colors,
    bytes memory _id,
    bytes memory _customAttributes
  ) public view returns (bytes memory) {
    return this.autoLinearGradient("", _colors, _id, _customAttributes);
  }

  function autoLinearGradient(
    bytes memory _coordinates,
    bytes memory _colors,
    bytes memory _id,
    bytes memory _customAttributes
  ) external view returns (bytes memory) {
    bytes memory _b;
    if (_coordinates.length > 3) {
      _b = abi.encodePacked(uint8(128), _coordinates);
    } else {
      _b = hex"00";
    }
    // Count the number of colors passed, each on 4 byte
    uint256 colorCount = _colors.length / 4;
    uint8 i = 0;
    while (i < colorCount) {
      _b = abi.encodePacked(
        _b,
        uint8(i * (100 / (colorCount - 1))), // grad. stop %
        uint8(_colors[i * 4]),
        uint8(_colors[i * 4 + 1]),
        uint8(_colors[i * 4 + 2]),
        uint8(_colors[i * 4 + 3])
      );
      i++;
    }
    return linearGradient(_b, _id, _customAttributes);
  }

  function linearGradient(
    bytes memory _lg,
    bytes memory _id,
    bytes memory _customAttributes
  ) public pure returns (bytes memory) {
    bytes memory grdata;
    uint8 offset = 1;

    if (uint8(_lg[0]) & 128 == 128) {
      grdata = abi.encodePacked(
        'x1="',
        byte2uint8(_lg, 1).toString(),
        '%" x2="',
        byte2uint8(_lg, 2).toString(),
        '%" y1="',
        byte2uint8(_lg, 3).toString(),
        '%" y2="',
        byte2uint8(_lg, 4).toString(),
        '%"'
      );
      offset = 5;
    }
    grdata = abi.encodePacked('<linearGradient id="', _id, '" ', _customAttributes, grdata, ">");
    for (uint256 i = offset; i < _lg.length; i += 5) {
      grdata = abi.encodePacked(
        grdata,
        '<stop offset="',
        byte2uint8(_lg, i).toString(),
        '%" stop-color="',
        toRgba(_lg, i + 1),
        '" id="',
        _id,
        byte2uint8(_lg, i).toString(),
        '"/>'
      );
    }
    return abi.encodePacked(grdata, "</linearGradient>");
  }

  function toRgba(bytes memory _rgba, uint256 offset) public pure returns (bytes memory) {
    return
      abi.encodePacked(
        "rgba(",
        byte2uint8(_rgba, offset).toString(),
        ",",
        byte2uint8(_rgba, offset + 1).toString(),
        ",",
        byte2uint8(_rgba, offset + 2).toString(),
        ",",
        byte2uint8(_rgba, offset + 3).toString(),
        "%)"
      );
  }

  function byte2uint8(bytes memory _data, uint256 _offset) public pure returns (uint8) {
    require(_data.length > _offset, "Out of range");
    return uint8(_data[_offset]);
  }

  // formats rgba white with a specified opacity / alpha
  function white_a(uint256 _a) internal pure returns (string memory) {
    return rgba(255, 255, 255, _a);
  }

  // formats rgba black with a specified opacity / alpha
  function black_a(uint256 _a) internal pure returns (string memory) {
    return rgba(0, 0, 0, _a);
  }

  // formats generic rgba color in css
  function rgba(
    uint256 _r,
    uint256 _g,
    uint256 _b,
    uint256 _a
  ) internal pure returns (string memory) {
    string memory formattedA = _a < 100 ? string.concat("0.", uint2str(_a)) : "1";
    return
      string.concat(
        "rgba(",
        uint2str(_r),
        ",",
        uint2str(_g),
        ",",
        uint2str(_b),
        ",",
        formattedA,
        ")"
      );
  }

  function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/utils/Strings.sol";
/**
  * @title  SVG Utilities
  * @author Kames Geraghty
  * @notice The SVG Utilities Library provides functions for constructing SVG; format CSS and numbers.
  * @dev Original code from w1nt3r-eth/hot-chain-svg (https://github.com/w1nt3r-eth/hot-chain-svg)
*/
library svgUtils {
    using Strings for uint256;
    using Strings for uint8;
    
    /// @notice Empty SVG element
    string internal constant NULL = "";

    /**
     * @notice Formats a CSS variable line. Includes a semicolon for formatting.
     * @param _key User for which to calculate prize amount.
     * @param _val User for which to calculate prize amount.
     * @return string Generated CSS variable.
    */
    function setCssVar(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat("--", _key, ":", _val, ";");
    }

    /**
     * @notice Formats getting a css variable
     * @param _key User for which to calculate prize amount.
     * @return string Generated CSS variable.
    */
    function getCssVar(string memory _key)
        internal
        pure
        returns (string memory)
    {
        return string.concat("var(--", _key, ")");
    }

    // formats getting a def URL
    function getDefURL(string memory _id)
        internal
        pure
        returns (string memory)
    {
        return string.concat("url(#", _id, ")");
    }

    // checks if two strings are equal
    function stringsEqual(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    // returns the length of a string in characters
    function utfStringLength(string memory _str)
        internal
        pure
        returns (uint256 length)
    {
        uint256 i = 0;
        bytes memory string_rep = bytes(_str);

        while (i < string_rep.length) {
            if (string_rep[i] >> 7 == 0) i += 1;
            else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) i += 2;
            else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) i += 3;
            else if (string_rep[i] >> 3 == bytes1(uint8(0x1E)))
                i += 4;
                //For safety
            else i += 1;

            length++;
        }
    }

    function round2Txt(
        uint256 _value,
        uint8 _decimals,
        uint8 _prec
    ) internal pure returns (bytes memory) {
        return abi.encodePacked(
            (_value / 10 ** _decimals).toString(), 
            ".",
            ( _value / 10 ** (_decimals - _prec) -
                _value / 10 ** (_decimals ) * 10 ** _prec
            ).toString()
        );
    }

     // converts an unsigned integer to a string
     function uint2str(uint256 _i)
     internal
     pure
     returns (string memory _uintAsString)
 {
     if (_i == 0) {
         return "0";
     }
     uint256 j = _i;
     uint256 len;
     while (j != 0) {
         len++;
         j /= 10;
     }
     bytes memory bstr = new bytes(len);
     uint256 k = len;
     while (_i != 0) {
         k = k - 1;
         uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
         bytes1 b1 = bytes1(temp);
         bstr[k] = b1;
         _i /= 10;
     }
     return string(bstr);
 }
}