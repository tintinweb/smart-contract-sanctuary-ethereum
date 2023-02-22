// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        Strings.toHexString(account),
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

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
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
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
            return toHexString(value, Math.log256(value) + 1);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "./ITradeCoinContract.sol";

interface ITradeCoinCompositionContract {
    struct TradeCoinComposition {
        uint256[] tokenIdsOfTC;
        string composition;
        uint256 amount;
        bytes32 unit;
        bool reversible;
        string state;
        address currentHandler;
        string[] transformations;
    }

    struct Documents {
        bytes32[] docHashes;
        bytes32[] docTypes;
    }

    // Definition of Events
    event CreateComposition(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256[] productIds,
        uint256 compositionAmount,
        bytes32 compositionUnit,
        string geoLocation,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event AddTransformation(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256 indexed CO2Emissions,
        int256 weightResult,
        string transformationCode,
        string geoLocation,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event ChangeCompositionHandler(
        uint256 indexed tokenId,
        address indexed functionCaller,
        address indexed newCurrentHandler,
        string geoLocation,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event ChangeCompositionState(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256 indexed CO2Emissionss,
        string newState,
        string geoLocation,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event RemoveProductFromComposition(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256 tokenIdOfProduct,
        uint256 amountRemoved,
        string geoLocation,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event AppendProductToComposition(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256 tokenIdOfProduct,
        uint256 amountAdded,
        string geoLocation,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event AddInformation(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event AddValidation(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 validationType,
        string description,
        string result,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event Decomposition(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256[] productIds,
        string geoLocation,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event Burn(
        uint256 indexed tokenId,
        address indexed functionCaller,
        string geoLocation,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event UnitConversion(
        uint256 indexed tokenId,
        uint256 indexed amount,
        uint256 indexed CO2Emissions,
        bytes32 previousAmountUnit,
        bytes32 newAmountUnit,
        string geoLocation,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    function createComposition(
        string memory compositionName,
        uint256[] memory tokenIdsOfTC,
        uint256 compositionAmount,
        bytes32 compositionUnit,
        bool reversible,
        string memory geoLocation,
        Documents memory documents
    ) external;

    function appendProductToComposition(
        uint256 tokenIdComposition,
        uint256 tokenIdTC,
        uint256 amountOfProductToAdd,
        string memory geoLocation,
        Documents memory documents
    ) external;

    function removeProductFromComposition(
        uint256 tokenIdComposition,
        uint256 indexTokenIdTC,
        uint256 amountOfProductToSubtract,
        string memory geoLocation,
        Documents memory documents
    ) external;

    function decomposition(
        uint256 tokenId,
        string memory geoLocation,
        Documents memory documents
    ) external;

    // Can only be called if Owner or approved account
    // In case of being an approved account, this account must be a Minter Role and Burner Role (Admin)
    function addTransformation(
        uint256 tokenId,
        int256 weightDifference,
        string memory transformationCode,
        uint256 CO2Emissions,
        string memory geoLocation,
        Documents memory documents
    ) external;

    function addTransformationToSingleProduct(
        uint256 tokenId,
        uint256 productTokenId,
        int256 weightDifference,
        string memory transformationCode,
        uint256 CO2Emissions,
        string memory geoLocation,
        ITradeCoinContract.Documents memory documents
    ) external;

    function addInformation(
        uint256[] memory tokenIds,
        Documents memory documents
    ) external;

    function addValidation(
        uint256 _tokenId,
        bytes32 _type,
        string memory _description,
        string memory _result,
        Documents memory _documents
    ) external;

    function changeCompositionHandler(
        uint256 tokenId,
        address newCurrentHandler,
        string memory geoLocation,
        Documents memory documents
    ) external;

    function changeCompositionState(
        uint256 tokenId,
        string memory newState,
        uint256 CO2Emissions,
        string memory geoLocation,
        Documents memory documents
    ) external;

    function massApproval(uint256[] memory tokenIds, address to) external;

    function isProductPartOfComposition(uint256 tokenId, uint256 productTokenId)
        external
        view
        returns (bool);

    function tradeCoinComposition(uint256 tokenId)
        external
        view
        returns (
            string memory composition,
            uint256 amount,
            bytes32 unit,
            bool isReversible,
            string memory state,
            address currentHandler,
            string[] memory transformations,
            uint256[] memory tokenIdsOfProducts
        );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ITradeCoinContract is IERC165 {
    struct TradeCoin {
        string product;
        uint256 amount;
        bytes32 unit;
        string state;
        uint256 CO2Emissions;
        address currentHandler;
        string[] transformations;
    }

    struct Documents {
        bytes32[] docHashes;
        bytes32[] docTypes;
    }

    struct TradeCoinInit {
        address owner;
        string product;
        uint256 amount;
        bytes32 unit;
        string state;
        uint256 CO2Emissions;
        string transformation;
        uint256 paymentInWei;
        uint256 deadline;
        Documents documents;
    }

    struct SignatureWithAddress {
        address signer;
        bytes32 role;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    event InitialTokenization(
        uint256 indexed tokenId,
        address indexed functionCaller,
        string geoLocation
    );

    event MintAfterSplitOrBatch(
        uint256 indexed tokenId,
        address indexed functionCaller,
        string geoLocation
    );

    event ApproveTokenization(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed functionCaller,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event InitiateCommercialTx(
        uint256 indexed tokenId,
        address indexed functionCaller,
        address indexed buyer,
        bool payInFiat,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event AddTransformation(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256 indexed CO2Emissions,
        int256 weightResult,
        string transformationCode,
        string geoLocation,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event ChangeProductHandler(
        uint256 indexed tokenId,
        address indexed functionCaller,
        address indexed newCurrentHandler,
        string geoLocation,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event ChangeProductState(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256 indexed CO2Emissionss,
        string newState,
        string geoLocation,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event SplitProduct(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256 indexed CO2Emissionss,
        uint256[] splitTokenIds,
        string geoLocation,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event BatchProduct(
        uint256 indexed tokenId,
        address indexed functionCaller,
        uint256 indexed CO2Emissionss,
        uint256[] batchedTokenIds,
        string geoLocation,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event WithdrawPayment(address indexed withdrawer, uint256 withdrawnAmount);

    event FinishCommercialTx(
        uint256 indexed tokenId,
        address indexed seller,
        address indexed functionCaller,
        bytes32[] dochashes,
        bytes32[] docTypes
    );

    event ServicePayment(
        uint256 indexed tokenId,
        address indexed receiver,
        address indexed sender,
        uint256 paymentInWei,
        bool payInFiat,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event Burn(
        uint256 indexed tokenId,
        address indexed functionCaller,
        string geoLocation,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event AddInformation(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event AddValidation(
        uint256 indexed tokenId,
        address indexed functionCaller,
        bytes32 validationType,
        string description,
        string result,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event UnitConversion(
        uint256 indexed tokenId,
        uint256 indexed amount,
        uint256 indexed CO2Emissions,
        bytes32 previousAmountUnit,
        bytes32 newAmountUnit,
        string geoLocation,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event InitializeProductSale(
        uint256 indexed burnerId,
        address indexed seller,
        address indexed newOwner,
        address handler,
        uint256 priceInWei,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event AddCustomData(
        uint256 indexed tokenId,
        address indexed caller,
        bytes4 indexed customCode,
        string payload,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    event MintProduct(
        address indexed owner,
        uint256 indexed productId,
        uint256 indexed CO2Emissions,
        address[] validators,
        string product,
        uint256 amount,
        bytes32 unit,
        string state,
        string firstTransformation,
        address currentHandler,
        bytes32[] docHashes,
        bytes32[] docTypes
    );

    function mintProduct(
        TradeCoinInit memory productInit,
        address currentHandler,
        SignatureWithAddress[] memory validators
    ) external payable;

    function withdrawPayment() external;

    function unitConversion(
        uint256 tokenId,
        uint256 amount,
        bytes32 previousAmountUnit,
        bytes32 newAmountUnit,
        uint256 CO2Emissions,
        string memory geoLocation,
        Documents memory documents
    ) external;

    function initiateCommercialTx(
        uint256 tokenId,
        uint256 paymentInWei,
        address newOwner,
        bool payInFiat,
        Documents memory documents
    ) external;

    function addTransformation(
        uint256 tokenId,
        int256 weightDifference,
        string memory transformationCode,
        uint256 CO2Emissions,
        string memory geoLocation,
        Documents memory documents
    ) external;

    function changeProductHandler(
        uint256 tokenId,
        address newCurrentHandler,
        string memory geoLocation,
        Documents memory documents
    ) external;

    function changeProductState(
        uint256 tokenId,
        string memory newState,
        uint256 CO2Emissions,
        string memory geoLocation,
        Documents memory documents
    ) external;

    function splitProduct(
        uint256 tokenId,
        uint256[] memory partitions,
        uint256 CO2Emissions,
        string memory geoLocation,
        Documents memory documents
    ) external;

    function batchProduct(
        uint256[] memory tokenIds,
        uint256 CO2Emissions,
        string memory geoLocation,
        Documents memory documents
    ) external;

    function finishCommercialTx(uint256 tokenId, Documents memory documents)
        external
        payable;

    function servicePayment(
        uint256 tokenId,
        address receiver,
        uint256 paymentInWei,
        bool payInFiat,
        Documents memory documents
    ) external payable;

    function addInformation(
        uint256[] memory tokenIds,
        Documents memory documents
    ) external;

    function addCustomData(
        uint256 tokenId,
        bytes4 customCode,
        string memory payload,
        Documents memory documents
    ) external;

    function addValidation(
        uint256 tokenId,
        bytes32 Validationtype,
        string memory description,
        string memory result,
        Documents memory documents
    ) external;

    function tradeCoin(uint256 tokenId)
        external
        view
        returns (
            string memory product,
            uint256 amount,
            bytes32 unit,
            string memory state,
            uint256 CO2Emissions,
            address currentHandler,
            string[] memory transformations
        );

    function massApproval(uint256[] memory tokenIds, address to) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract RoleControl is AccessControl {
    // We use keccak256 to create a hash that identifies this constant in the contract
    bytes32 public constant TOKENIZER_ROLE = keccak256("TOKENIZER_ROLE"); // hash a MINTER_ROLE as a role constant
    bytes32 public constant PRODUCT_HANDLER_ROLE =
        keccak256("PRODUCT_HANDLER_ROLE"); // hash a BURNER_ROLE as a role constant
    bytes32 public constant INFORMATION_HANDLER_ROLE =
        keccak256("INFORMATION_HANDLER_ROLE"); // hash a BURNER_ROLE as a role constant

    // Constructor of the RoleControl contract
    constructor(address root) {
        // NOTE: Other DEFAULT_ADMIN's can remove other admins, give this role with great care
        _setupRole(DEFAULT_ADMIN_ROLE, root); // The creator of the contract is the default admin

        // SETUP role Hierarchy:
        // DEFAULT_ADMIN_ROLE > MINTER_ROLE > BURNER_ROLE > no role
        _setRoleAdmin(TOKENIZER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(PRODUCT_HANDLER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(INFORMATION_HANDLER_ROLE, DEFAULT_ADMIN_ROLE);
    }

    // Create a bool check to see if a account address has the role admin
    function isAdmin(address account) public view virtual returns (bool) {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender)  is a admin
    modifier onlyAdmin() {
        require(isAdmin(msg.sender), "Restricted to admins.");
        _;
    }

    // Add a user address as a admin
    function addAdmin(address account) public virtual onlyAdmin {
        grantRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Remove a user as a admin
    function removeAdmin(address account) public virtual onlyAdmin {
        revokeRole(DEFAULT_ADMIN_ROLE, account);
    }

    // Create a bool check to see if a account address has the role admin or Tokenizer
    function isTokenizerOrAdmin(address account)
        public
        view
        virtual
        returns (bool)
    {
        return (hasRole(TOKENIZER_ROLE, account) ||
            hasRole(DEFAULT_ADMIN_ROLE, account));
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender) is a admin or Tokenizer
    modifier onlyTokenizerOrAdmin() {
        require(
            isTokenizerOrAdmin(msg.sender),
            "Restricted to FTokenizer or admins."
        );
        _;
    }

    // Add a user address as a Tokenizer
    function addTokenizer(address account) public virtual onlyAdmin {
        grantRole(TOKENIZER_ROLE, account);
    }

    // remove a user address as a Tokenizer
    function removeTokenizer(address account) public virtual onlyAdmin {
        revokeRole(TOKENIZER_ROLE, account);
    }

    // Create a bool check to see if a account address has the role admin or ProductHandlers
    function isProductHandlerOrAdmin(address account)
        public
        view
        virtual
        returns (bool)
    {
        return (hasRole(PRODUCT_HANDLER_ROLE, account) ||
            hasRole(DEFAULT_ADMIN_ROLE, account));
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender) is a admin or ProductHandlers
    modifier onlyProductHandlerOrAdmin() {
        require(
            isProductHandlerOrAdmin(msg.sender),
            "Restricted to ProductHandlers or admins."
        );
        _;
    }

    // Add a user address as a ProductHandlers
    function addProductHandler(address account) public virtual onlyAdmin {
        grantRole(PRODUCT_HANDLER_ROLE, account);
    }

    // remove a user address as a ProductHandlers
    function removeProductHandler(address account) public virtual onlyAdmin {
        revokeRole(PRODUCT_HANDLER_ROLE, account);
    }

    // Create a bool check to see if a account address has the role admin or InformationHandlers
    function isInformationHandlerOrAdmin(address account)
        public
        view
        virtual
        returns (bool)
    {
        return (hasRole(INFORMATION_HANDLER_ROLE, account) ||
            hasRole(DEFAULT_ADMIN_ROLE, account));
    }

    // Create a modifier that can be used in other contract to make a pre-check
    // That makes sure that the sender of the transaction (msg.sender) is a admin or InformationHandlers
    modifier onlyInformationHandlerOrAdmin() {
        require(
            isInformationHandlerOrAdmin(msg.sender),
            "Restricted to InformationHandlers or admins."
        );
        _;
    }

    // Add a user address as a InformationHandlers
    function addInformationHandler(address account) public virtual onlyAdmin {
        grantRole(INFORMATION_HANDLER_ROLE, account);
    }

    // remove a user address as a InformationHandlers
    function removeInformationHandler(address account)
        public
        virtual
        onlyAdmin
    {
        revokeRole(INFORMATION_HANDLER_ROLE, account);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Multicall.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// import "solmate/src/tokens/ERC721.sol";
import "solmate/src/utils/ReentrancyGuard.sol";

import "./RoleControl.sol";

import "./interfaces/ITradeCoinContract.sol";
import "./interfaces/ITradeCoinCompositionContract.sol";

contract TradeCoinCompositionContract is
    ERC721,
    RoleControl,
    ReentrancyGuard,
    Multicall,
    ITradeCoinCompositionContract
{
    using Strings for uint256;

    uint256 private _tokenIdCounter;

    address public immutable tradeCoin;

    modifier onlyLegalOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "Not NFTOwner");
        _;
    }

    modifier isLegalOwnerOrCurrentHandler(uint256 tokenId) {
        require(
            _tradeCoinComposition[tokenId].currentHandler == msg.sender ||
                ownerOf(tokenId) == msg.sender,
            "Not Owner/Handler"
        );
        _;
    }

    modifier onlyExistingTokens(uint256 tokenId) {
        require(tokenId <= _tokenIdCounter, "Token does not exist");
        _;
    }

    modifier onlyReversible(uint256 tokenId) {
        require(
            _tradeCoinComposition[tokenId].reversible,
            "Token is irreversible"
        );
        _;
    }

    modifier onlyIrreversible(uint256 tokenId) {
        require(
            !_tradeCoinComposition[tokenId].reversible,
            "Token is reversible"
        );
        _;
    }

    // Mapping for the metadata of the tradecoinComposition
    mapping(uint256 => TradeCoinComposition) private _tradeCoinComposition;
    mapping(uint256 => string) private _tokenURIs;

    mapping(uint256 => address) public addressOfNewOwner;
    mapping(uint256 => uint256) public priceForOwnership;
    mapping(uint256 => bool) public paymentInFiat;

    /// block number in which the contract was deployed.
    uint256 public immutable deployedOn = block.number;

    constructor(
        string memory name,
        string memory symbol,
        address _tradeCoin
    ) ERC721(name, symbol) RoleControl(msg.sender) {
        tradeCoin = _tradeCoin;
    }

    function createComposition(
        string memory compositionName,
        uint256[] memory tokenIdsOfTC,
        uint256 compositionAmount,
        bytes32 compositionUnit,
        bool reversible,
        string memory geoLocation,
        Documents memory documents
    ) external override {
        uint256 length = tokenIdsOfTC.length;
        require(length > 1, "Invalid Length");
        require(
            documents.docHashes.length == documents.docTypes.length,
            "Document hash amount must match document type"
        );

        // Get new tokenId by incrementing
        _tokenIdCounter++;
        uint256 id = _tokenIdCounter;

        string[] memory emptyTransformations = new string[](0);

        ITradeCoinContract.Documents memory _docs = ITradeCoinContract
            .Documents(documents.docHashes, documents.docTypes);

        for (uint256 i; i < length; ) {
            IERC721(tradeCoin).transferFrom(
                msg.sender,
                address(this),
                tokenIdsOfTC[i]
            );
            ITradeCoinContract(tradeCoin).changeProductHandler(
                tokenIdsOfTC[i],
                address(this),
                geoLocation,
                _docs
            );

            unchecked {
                ++i;
            }
        }

        // Mint new token
        _mint(msg.sender, id);
        // Store data on-chain
        _tradeCoinComposition[id] = TradeCoinComposition(
            tokenIdsOfTC,
            compositionName,
            compositionAmount,
            compositionUnit,
            reversible,
            "created",
            msg.sender,
            emptyTransformations
        );

        // Fire off the event
        emit CreateComposition(
            id,
            msg.sender,
            tokenIdsOfTC,
            compositionAmount,
            compositionUnit,
            geoLocation,
            documents.docHashes,
            documents.docTypes
        );
    }

    function appendProductToComposition(
        uint256 tokenIdComposition,
        uint256 tokenIdTC,
        uint256 amountOfProductToAdd,
        string memory geoLocation,
        Documents memory documents
    ) external override onlyReversible(tokenIdComposition) {
        require(
            ownerOf(tokenIdComposition) != address(0),
            "Non-existent token"
        );

        IERC721(tradeCoin).transferFrom(msg.sender, address(this), tokenIdTC);

        _tradeCoinComposition[tokenIdComposition].tokenIdsOfTC.push(tokenIdTC);

        _tradeCoinComposition[tokenIdComposition]
            .amount += amountOfProductToAdd;

        emit AppendProductToComposition(
            tokenIdComposition,
            msg.sender,
            tokenIdTC,
            amountOfProductToAdd,
            geoLocation,
            documents.docHashes,
            documents.docTypes
        );
    }

    function removeProductFromComposition(
        uint256 tokenIdComposition,
        uint256 indexTokenIdTC,
        uint256 amountOfProductToSubtract,
        string memory geoLocation,
        Documents memory documents
    )
        external
        override
        onlyReversible(tokenIdComposition)
        onlyLegalOwner(tokenIdComposition)
    {
        uint256 lengthTokenIds = _tradeCoinComposition[tokenIdComposition]
            .tokenIdsOfTC
            .length;
        require(lengthTokenIds > 2, "Invalid lengths");
        require((lengthTokenIds - 1) >= indexTokenIdTC, "Index not in range");

        uint256 tokenIdTC = _tradeCoinComposition[tokenIdComposition]
            .tokenIdsOfTC[indexTokenIdTC];
        uint256 lastTokenId = _tradeCoinComposition[tokenIdComposition]
            .tokenIdsOfTC[lengthTokenIds - 1];

        IERC721(tradeCoin).transferFrom(address(this), msg.sender, tokenIdTC);

        _tradeCoinComposition[tokenIdComposition].tokenIdsOfTC[
            indexTokenIdTC
        ] = lastTokenId;

        _tradeCoinComposition[tokenIdComposition].tokenIdsOfTC.pop();

        _tradeCoinComposition[tokenIdComposition]
            .amount -= amountOfProductToSubtract;

        emit RemoveProductFromComposition(
            tokenIdComposition,
            msg.sender,
            indexTokenIdTC,
            amountOfProductToSubtract,
            geoLocation,
            documents.docHashes,
            documents.docTypes
        );
    }

    function decomposition(
        uint256 tokenId,
        string memory geoLocation,
        Documents memory documents
    ) external override onlyReversible(tokenId) onlyLegalOwner(tokenId) {
        require(
            documents.docHashes.length == documents.docTypes.length,
            "Document hash amount must match document type"
        );

        uint256[] memory productIds = _tradeCoinComposition[tokenId]
            .tokenIdsOfTC;
        uint256 length = productIds.length;
        for (uint256 i; i < length; ) {
            IERC721(tradeCoin).transferFrom(
                address(this),
                msg.sender,
                productIds[i]
            );
            unchecked {
                ++i;
            }
        }

        _burn(tokenId);

        emit Decomposition(
            tokenId,
            msg.sender,
            productIds,
            geoLocation,
            documents.docHashes,
            documents.docTypes
        );
    }

    // Can only be called if Owner or approved account
    // In case of being an approved account, this account must be a Minter Role and Burner Role (Admin)
    function addTransformation(
        uint256 tokenId,
        int256 weightDifference,
        string memory transformationCode,
        uint256 CO2Emissions,
        string memory geoLocation,
        Documents memory documents
    ) external override isLegalOwnerOrCurrentHandler(tokenId) {
        require(ownerOf(tokenId) != address(0), "Token id does not exist");
        int256 intValue = int256(_tradeCoinComposition[tokenId].amount);
        if (
            keccak256(abi.encodePacked(transformationCode)) ==
            keccak256(abi.encodePacked("Certification"))
        ) {
            require(weightDifference == 0, "Invalid Certification");
        } else {
            require(
                weightDifference != 0 && (intValue + weightDifference) > 0,
                "Invalid weight difference"
            );
        }

        require(
            documents.docHashes.length == documents.docTypes.length,
            "Document hash amount must match document type"
        );

        _tradeCoinComposition[tokenId].transformations.push(transformationCode);

        int256 newAmount = intValue += weightDifference;
        _tradeCoinComposition[tokenId].amount = uint256(newAmount);

        emit AddTransformation(
            tokenId,
            msg.sender,
            CO2Emissions,
            newAmount,
            transformationCode,
            geoLocation,
            documents.docHashes,
            documents.docTypes
        );
    }

    function addTransformationToSingleProduct(
        uint256 tokenId,
        uint256 productTokenId,
        int256 weightDifference,
        string memory transformationCode,
        uint256 CO2Emissions,
        string memory geoLocation,
        ITradeCoinContract.Documents memory documents
    )
        external
        override
        isLegalOwnerOrCurrentHandler(tokenId)
        onlyReversible(tokenId)
    {
        require(
            isProductPartOfComposition(tokenId, productTokenId),
            "Token is not part of composition"
        );

        ITradeCoinContract(tradeCoin).addTransformation(
            productTokenId,
            weightDifference,
            transformationCode,
            CO2Emissions,
            geoLocation,
            documents
        );
        int256 intValue = int256(_tradeCoinComposition[tokenId].amount);

        int256 newAmount = intValue += weightDifference;
        _tradeCoinComposition[tokenId].amount = uint256(newAmount);
    }

    function addInformation(
        uint256[] memory tokenIds,
        Documents memory documents
    ) external override onlyInformationHandlerOrAdmin {
        uint256 length = tokenIds.length;

        require(
            documents.docHashes.length == documents.docTypes.length,
            "Document hash amount must match document type"
        );

        for (uint256 tokenId; tokenId < length; ) {
            emit AddInformation(
                tokenIds[tokenId],
                msg.sender,
                documents.docHashes,
                documents.docTypes
            );
            unchecked {
                ++tokenId;
            }
        }
    }

    function addValidation(
        uint256 tokenId,
        bytes32 validationType,
        string memory description,
        string memory result,
        Documents memory documents
    ) external override {
        require(
            documents.docHashes.length == documents.docTypes.length,
            "Document hash amount must match document type"
        );

        emit AddValidation(
            tokenId,
            msg.sender,
            validationType,
            description,
            result,
            documents.docHashes,
            documents.docTypes
        );
    }

    function changeCompositionHandler(
        uint256 tokenId,
        address newCurrentHandler,
        string memory geoLocation,
        Documents memory documents
    ) external override isLegalOwnerOrCurrentHandler(tokenId) {
        require(
            documents.docHashes.length == documents.docTypes.length,
            "Document hash amount must match document type"
        );

        _tradeCoinComposition[tokenId].currentHandler = newCurrentHandler;

        emit ChangeCompositionHandler(
            tokenId,
            msg.sender,
            newCurrentHandler,
            geoLocation,
            documents.docHashes,
            documents.docTypes
        );
    }

    function changeCompositionState(
        uint256 tokenId,
        string memory newState,
        uint256 CO2Emissions,
        string memory geoLocation,
        Documents memory documents
    ) external override isLegalOwnerOrCurrentHandler(tokenId) {
        require(
            documents.docHashes.length == documents.docTypes.length,
            "Document hash amount must match document type"
        );

        _tradeCoinComposition[tokenId].state = newState;

        emit ChangeCompositionState(
            tokenId,
            msg.sender,
            CO2Emissions,
            newState,
            geoLocation,
            documents.docHashes,
            documents.docTypes
        );
    }

    function massApproval(uint256[] memory tokenIds, address to)
        external
        override
    {
        for (uint256 i; i < tokenIds.length; i++) {
            approve(to, tokenIds[i]);
        }
    }

    function burn(
        uint256 tokenId,
        string memory geoLocation,
        Documents memory documents
    ) public onlyLegalOwner(tokenId) {
        _burn(tokenId);

        emit Burn(
            tokenId,
            msg.sender,
            geoLocation,
            documents.docHashes,
            documents.docTypes
        );
    }

    function tradeCoinComposition(uint256 tokenId)
        external
        view
        override
        onlyExistingTokens(tokenId)
        returns (
            string memory composition,
            uint256 amount,
            bytes32 unit,
            bool isReversible,
            string memory state,
            address currentHandler,
            string[] memory transformations,
            uint256[] memory tokenIdsOfProducts
        )
    {
        TradeCoinComposition storage _tccPointer = _tradeCoinComposition[
            tokenId
        ];

        composition = _tccPointer.composition;
        amount = _tccPointer.amount;
        unit = _tccPointer.unit;
        isReversible = _tccPointer.reversible;
        state = _tccPointer.state;
        currentHandler = _tccPointer.currentHandler;
        transformations = _tccPointer.transformations;
        tokenIdsOfProducts = _tccPointer.tokenIdsOfTC;
    }

    function isProductPartOfComposition(uint256 tokenId, uint256 productTokenId)
        public
        view
        override
        onlyExistingTokens(tokenId)
        returns (bool)
    {
        uint256[] memory tokenIdsOfTC = _tradeCoinComposition[tokenId]
            .tokenIdsOfTC;
        uint256 length = tokenIdsOfTC.length;
        for (uint256 i; i < length; i++) {
            if (tokenIdsOfTC[i] == productTokenId) {
                return true;
            }
        }
        return false;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return
            type(ITradeCoinCompositionContract).interfaceId == interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256) public pure override returns (string memory) {
        return "TradeCoinComposition";
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}