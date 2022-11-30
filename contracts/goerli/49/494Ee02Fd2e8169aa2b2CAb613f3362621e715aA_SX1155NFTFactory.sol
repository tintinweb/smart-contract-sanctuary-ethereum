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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
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
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
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
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./RoleManager.sol";
import "./ArrayLimiter.sol";

abstract contract AccountControl is ArrayLimiter, RoleManager {
    mapping(address => bool) private _frozen;
    mapping(address => bool) private _whitelist;
    mapping(address => bool) private _greylist;

    ///@dev Events for displaying freeze/unfreeze accounts
    event AccountFrozen(address indexed account);
    event AccountUnFrozen(address indexed account);

    ///@dev Events for displaying adding/removing accounts from the whitelist
    event AccountWhitelisted(address indexed account);
    event AccountUnWhitelisted(address indexed account);

    ///@dev Events for displaying adding/removing accounts from the greylist
    event AccountGreylisted(address indexed account);
    event AccountUnGreylisted(address indexed account);

    // Frozen list functions

    /**
     * @dev Freezes account.
     *
     * Requirements:
     * - `msg.sender` must be an issuer.
     * - `account` cannot be the zero address.
     *
     * Emits AccountFrozen event.
     */
    function freezeAccount(address account) external onlyRole(ISSUER_ROLE) isNotZeroAddress(account) {
        require(!isAccountFrozen(account), "AC: Account already frozen");

        _frozen[account] = true;
        emit AccountFrozen(account);
    }

    /**
     * @dev Unfreezes account.
     *
     * Requirements:
     * - `msg.sender` must be an issuer.
     * - `account` cannot be the zero address.
     *
     * Emits AccountUnFrozen event.
     */
    function unFreezeAccount(address account) external onlyRole(ISSUER_ROLE) {
        require(isAccountFrozen(account), "AC: Account not frozen");

        _frozen[account] = false;
        emit AccountUnFrozen(account);
    }

    /**
     * @dev Checks if the specified account is frozen. The token issuer may freeze
     * any account at any time and stop account transfers.
     *
     * @return True if account is frozen.
     */
    function isAccountFrozen(address account) public view returns (bool) {
        return _frozen[account];
    }

    //End of Frozenlist functions

    // Whitelist functions

    /**
     * @dev Adds an account to the whitelist.
     *
     * Requirements:
     * - `msg.sender` must be an issuer.
     * - `account` cannot be the zero address.
     *
     * Emits AccountWhitelisted event.
     */
    function whitelistAccount(address account) public onlyRole(ISSUER_ROLE) isNotZeroAddress(account) {
        require(!isWhitelisted(account), "AC: Account already whitelisted");

        _whitelist[account] = true;
        emit AccountWhitelisted(account);
    }

    /**
     * @dev Adds an array of accounts to the whitelist.
     *
     * Requirements:
     * - `msg.sender` must be an issuer.
     * - `accounts` cannot be the zero address.
     *
     * Emits AccountWhitelisted event.
     */
    function bulkWhitelistAccount(address[] calldata accounts) external arrayMaxSize(accounts.length) {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            whitelistAccount(account);
        }
    }

    /**
     * @dev Removes an account from the whitelist.
     *
     * Requirements:
     * - `msg.sender` must be an issuer.
     * - `account` cannot be the zero address.
     *
     * Emits AccountUnWhitelisted event.
     */
    function unWhitelistAccount(address account) public onlyRole(ISSUER_ROLE) {
        require(isWhitelisted(account), "AC: Account not whitelisted");

        delete _whitelist[account];
        emit AccountUnWhitelisted(account);
    }

    /**
     * @dev Removes an array of accounts from the whitelist.
     *
     * Requirements:
     * - `msg.sender` must be an issuer.
     * - `accounts` cannot be the zero address.
     *
     * Emits AccountWhitelisted event.
     */
    function bulkUnWhitelistAccount(address[] calldata accounts) external arrayMaxSize(accounts.length) {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            unWhitelistAccount(account);
        }
    }

    /**
     * @dev Checks if the specified account has been whitelisted. The issuer of the token can
     * add to the white list.
     *
     * @return True if account is added to whitelist.
     */
    function isWhitelisted(address account) public view returns (bool) {
        return _whitelist[account];
    }

    // End of Whitelist functions

    // Greylist functions

    /**
     * @dev Adds an account to the greylist.
     *
     * Requirements:
     * - `msg.sender` must be an issuer.
     * - `account` cannot be the zero address.
     *
     * Emits AccountGreylisted event.
     */
    function greylistAccount(address account) public onlyRole(ISSUER_ROLE) isNotZeroAddress(account) {
        require(!isGreylisted(account), "AC: Account already greylisted");

        _greylist[account] = true;
        emit AccountGreylisted(account);
    }

    /**
     * @dev Adds an array of accounts to the greylist.
     *
     * Requirements:
     * - `msg.sender` must be an issuer.
     * - `accounts` cannot be the zero address.
     *
     * Emits AccountGreylisted event.
     */
    function bulkGreylistAccount(address[] calldata accounts) external arrayMaxSize(accounts.length) {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            greylistAccount(account);
        }
    }

    /**
     * @dev Removes an account from the greylist.
     *
     * Requirements:
     * - `msg.sender` must be an issuer.
     * - `account` cannot be the zero address.
     *
     * Emits AccountGreylisted event.
     */
    function unGreylistAccount(address account) public onlyRole(ISSUER_ROLE) {
        require(isGreylisted(account), "AC: Account not greylisted");

        delete _greylist[account];
        emit AccountUnGreylisted(account);
    }

    /**
     * @dev Removes an array of accounts from the greylist.
     *
     * Requirements:
     * - `msg.sender` must be an issuer.
     * - `accounts` cannot be the zero address.
     *
     * Emits AccountGreylisted event.
     */
    function bulkUnGreylistAccount(address[] calldata accounts) external arrayMaxSize(accounts.length) {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            unGreylistAccount(account);
        }
    }

    /**
     * @dev Checks if the specified account has been greylisted. The issuer of the token can
     * add to the grey list.
     *
     * @return True if account is added to greylist.
     */
    function isGreylisted(address account) public view returns (bool) {
        return _greylist[account];
    }

    // End of Greylist functions
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

abstract contract ArrayLimiter {
    event NewMaxArraySizeSet(uint256 newMaxArraySize);
    uint256 public maxArraySize = 20;

    ///@dev Throws an error if the array size is greater than maxArraySize
    modifier arrayMaxSize(uint256 arraySize) {
        require(arraySize <= maxArraySize, "AL: Array size must be <= maxArraySize");
        _;
    }

    function _setMaxArraySize(uint256 _maxArraySize) internal {
        maxArraySize = _maxArraySize;

        emit NewMaxArraySizeSet(_maxArraySize);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/IAuthorizationContract.sol";

/// @title Token authorization contracts manager
abstract contract AuthorizeManager {
    /// @dev Mapping for NFT token id to Authorization contract
    mapping(uint256 => address) private authorizeContracts;

    /// @dev Default authorization contract, used when not configured for each NFT
    address public globalAuthContract;

    /// @dev Emitted when a default authorization contract is set
    /// @param from address of the setter/updater
    /// @param authContract Authorization contact address
    event GlobalAuthContractSet(address from, address authContract);

    /// @dev Emitted when a token id authorization contract is set
    /// @param from address of the setter/updater
    /// @param id token id
    /// @param authContract authorization contact address
    event TokenAuthContractSet(address from, uint256 indexed id, address authContract);

    /// @dev Called for each token transfer. It invokes authorization contract's
    /// isAccountAuthorized() and decides whether to allow or deny the transfer
    /// @param _from transfer from account
    /// @param _to transfer to account
    /// @param _id token id
    /// @return returns whether to allow or deny transfer, true or false
    function mustBeAuthorizedHolders(
        address _from,
        address _to,
        uint256 _id,
        bytes memory _data
    ) public view returns (bool) {
        return (mustBeAuthorizedHolder(_from, _id, _data) && mustBeAuthorizedHolder(_to, _id, _data));
    }

    function mustBeAuthorizedHolder(
        address _address,
        uint256 _id,
        bytes memory /*_data */
    ) public view returns (bool) {
        address authContract = authorizeContracts[_id];

        /*
         * If authorization contract not set for this id, fall back to default authorization
         * contract
         */
        if (authContract == address(0)) authContract = globalAuthContract;

        // No authorizarion contract set, defaults to 'DENY' the transfer
        if (authContract == address(0)) return false;

        try IAuthorizationContract(authContract).isAccountAuthorized(_address) returns (bool response) {
            return response;
        } catch Error(string memory) {
            // Call rejected/reverted
            return false;
        } catch {
            // Authorization contract has not implemented the API
            return false;
        }
    }

    /// @dev Sets default authorization contract
    function _setDefaultAuthorizationContract(address authContract) internal {
        if (authContract != address(0)) require(_isContract(authContract), "AM: Not a valid auth contract address");
        globalAuthContract = authContract;
        emit GlobalAuthContractSet(msg.sender, authContract);
    }

    /// @dev Sets token id specific authorization contract
    function _setAuthorizationContract(uint256 id, address authContract) internal {
        /* If the given contract is 0, reset it so that it falls back to defaultAuthorizeContract */
        if (authContract != address(0)) require(_isContract(authContract), "AM: Not a valid auth contract address");
        authorizeContracts[id] = authContract;
        emit TokenAuthContractSet(msg.sender, id, authContract);
    }

    /// @dev Checks if an address is a contract or not
    function _isContract(address _contractAddress) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(_contractAddress)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAuthorizationContract {
    function isAccountAuthorized(address _to) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title Contract for managing roles
 * @notice It is based on Openzeppelin AccessControl to manage users roles.
 */
abstract contract RoleManager is AccessControl {
    /// Following are the default roles, assinged when the contract is
    /// deployed.
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER");
    bytes32 public constant EDITOR_ROLE = keccak256("EDITOR");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT");

    modifier isNotZeroAddress(address account) {
        require(account != address(0), "Passed address = zero address");
        _;
    }

    /// @dev Constructor for assigning default issuer and editor roles
    /// @param admin address to be assigned DEFAULT_ADMIN_ROLE role
    /// @param issuer address to be assigned ISSUER role
    /// @param editor adress to be assigned EDITOR role
    constructor(
        address admin,
        address issuer,
        address editor
    ) isNotZeroAddress(admin) isNotZeroAddress(issuer) isNotZeroAddress(editor) {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ISSUER_ROLE, issuer);
        _grantRole(EDITOR_ROLE, editor);
    }

    /// @dev Returns if this contract supports openzeppelin AccessControl
    /// interface.
    /// @param interfaceId interface ID to check against
    /// @return whether this contacts supports given interfaceId, true or false
    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     *  @dev Assigns an account to a given role. this is a generic function
     * to create and/or assign a role. This can be done only by DEFAULT_ADMIN_ROLE.
     * @param role role bytes, usually a keccak hash of a role string.
     * @param account account to which this role to be assigned
     */
    function grantRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(role, account);
    }

    /// @dev Revoke a role of an account
    /// @param role role
    /// @param account account to remove from the role
    function revokeRole(bytes32 role, address account) public override onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(role, account);
    }

    /// @dev Grants EDITOR role to a given account, only an ISSUER can do this.
    /// @param to account to which the role to be granted.
    function grantEditorRole(address to) external onlyRole(ISSUER_ROLE) {
        _grantRole(EDITOR_ROLE, to);
    }

    /// @dev Revokes EDITOR role to a given account, only ISSUER can do this.
    /// @param account address of the account to remove from the EDITOR role
    function revokeEditorRole(address account) external onlyRole(ISSUER_ROLE) {
        _revokeRole(EDITOR_ROLE, account);
    }

    /// @dev Grants ISSUER role to a given account, only an ISSUER can do this.
    /// @param to account to which the role to be granted.
    function grantIssuerRole(address to) external onlyRole(ISSUER_ROLE) {
        _grantRole(ISSUER_ROLE, to);
    }

    /// @dev Revokes ISSUER role to a given account, only ISSUER can do this.
    /// @param account address of the account to remove from the ISSUER role
    function revokeIssuerRole(address account) external onlyRole(ISSUER_ROLE) {
        _revokeRole(ISSUER_ROLE, account);
    }

    /// @dev Grants AGENT role to a given account, only an ISSUER can do this.
    /// @param to account to which the role to be granted.
    function grantAgentRole(address to) external onlyRole(ISSUER_ROLE) {
        _grantRole(AGENT_ROLE, to);
    }

    /// @dev Revokes AGENT role to a given account, only ISSUER can do this.
    /// @param account address of the account to remove from the AGENT role
    function revokeAgentRole(address account) external onlyRole(ISSUER_ROLE) {
        _revokeRole(AGENT_ROLE, account);
    }

    function _grantRole(bytes32 role, address account) internal override isNotZeroAddress(account) {
        require(!hasRole(role, account), "RM: Account already has role");

        super._grantRole(role, account);
    }

    function _revokeRole(bytes32 role, address account) internal override {
        require(hasRole(role, account), "RM: Account has no role");
        require(msg.sender != account, "RM: You can't revoke your role");

        super._revokeRole(role, account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./SX1155NFTBase.sol";
import "./RoleManager.sol";
import "./AuthorizeManager.sol";
import "./AccountControl.sol";

/// @title SX1155NFT
/// @notice SX1155 NFT Contract with rules and authorizations
contract SX1155NFT is Pausable, SX1155NFTBase, RoleManager, AuthorizeManager, AccountControl {
    struct GreylistTransferRequest {
        address from;
        address to;
        uint256 tokenId;
        uint256 quantity;
        bool valid;
    }

    ///@notice Next greylist transfer request ID
    uint256 greylistNextReqId = 1;

    ///@notice List of greylist transfers waiting for confirmation from ISSUER
    mapping(uint256 => GreylistTransferRequest) internal greylistTransferRequests;

    ///@notice Emitted when an issuer does a 'force' transfer
    event ForceTransfer(address indexed issuer, address indexed from, address indexed to, uint256 tokenId);
    ///@notice Emitted when an issuer does a 'force' burn of an account tokens
    event ForceBurn(address indexed issuer, address indexed from, uint256 indexed tokenId, string reason);
    ///@notice Emitted when a user creates a transfer request to be confirmed by issuer.
    event GreylistTransferRequestCreated(
        uint256 indexed reqId,
        address indexed from,
        address indexed to,
        uint256 tokenId,
        uint256 quantity
    );
    ///@notice Emitted when an issuer approves a greylist transfer request
    event GreylistTransferApproved(uint256 indexed reqId, address indexed issuer, uint256 indexed tokenId);
    ///@notice Emitted when a user cancels previously created greylist transfer request
    event GreylistTransferCancelled(uint256 indexed reqId, address indexed from, address indexed to, uint256 tokenId);

    /// @dev Constructor for setting basic configurations.
    /// @param _name a name for all tokens under this contract
    /// @param _symbol a symbol for all tokens under this contract
    /// @param _admin default admin address, will be assigned DEFAULT_ADMIN_ROLE Role
    /// @param _issuer default issuer address, will be assigned ISSUER Role
    /// @param _editor default editor address, will be assigned EDITOR Role
    constructor(
        string memory _name,
        string memory _symbol,
        address _admin,
        address _issuer,
        address _editor
    ) SX1155NFTBase(_name, _symbol) RoleManager(_admin, _issuer, _editor) {}

    function supportsInterface(bytes4 _interfaceId) public view override(SX1155NFTBase, RoleManager) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    /// @dev Sets KYA of the contract. Only EDITOR can do this.
    /// @param _kya KYA string
    function setKya(string calldata _kya) external onlyRole(EDITOR_ROLE) {
        _setKya(_kya);
    }

    /// @dev Sets KYA of a single token id. Only EDITOR can do this.
    /// @param _id token id
    /// @param _kya KYA string
    function setTokenKya(uint256 _id, string calldata _kya) external onlyRole(EDITOR_ROLE) {
        _setTokenKya(_id, _kya);
    }

    /// @dev Sets the contract level URI. Only ISSUER can do this.
    /// @param _contract_uri URI string
    function setContractURI(string calldata _contract_uri) external onlyRole(ISSUER_ROLE) {
        _setContractURI(_contract_uri);
    }

    /// @dev Pauses the token contract, no more transfers allowed. Only ISSUER can do this.
    function pauseToken() external onlyRole(ISSUER_ROLE) {
        _pause();
    }

    /// @dev Unpause/resume the contract. Only ISSUER can do this.
    function unPauseToken() external onlyRole(ISSUER_ROLE) {
        _unpause();
    }

    /// @dev Sets authorization contract of a token id. One contract for each
    /// token id. Only AGENT can do this.
    /// @param _id token id
    /// @param _authContract Authorization contract address, must be a contract address
    /// which implements IAuthorizationContract interface.
    function setTokenAuthContract(uint256 _id, address _authContract) external onlyRole(AGENT_ROLE) {
        _setAuthorizationContract(_id, _authContract);
    }

    /// @dev Sets default authorization contract, this is used when token id
    /// specific auth contact is not set
    /// @param _authContract authorization contract address, must be a contract address
    /// which implements IAuthorizationContract interface.
    function setGlobalAuthContract(address _authContract) external onlyRole(AGENT_ROLE) {
        _setDefaultAuthorizationContract(_authContract);
    }

    /// @dev Sets the maximum size of an array that can be passed as a parameter
    /// @param _maxArraySize the maximum size of the array, which will be the size limit of the array
    function setMaxArraySize(uint256 _maxArraySize) external onlyRole(ISSUER_ROLE) {
        _setMaxArraySize(_maxArraySize);
    }

    /// @dev Creates a transfer request that requires issuer confirmation. Only Greylisted users
    /// can do this.
    /// @param to receiver address
    /// @param tokenId token ID to transfer
    /// @param quantity number of tokens to transfer
    /// @return reqId request ID assigned to this request.
    function requestTransfer(
        address to,
        uint256 tokenId,
        uint256 quantity
    ) external isNotZeroAddress(to) returns (uint256 reqId) {
        // No transfers from users when token is paused
        _requireNotPaused();

        // 'sender' or 'receiver' account must not be frozen
        if (isAccountFrozen(msg.sender) || isAccountFrozen(to)) revert("SX1155: Sender or receiver account frozen");

        require(isGreylisted(msg.sender) || isGreylisted(to), "SX1155: Account not in greylist");

        // Add the request into the list and return reqId
        reqId = greylistNextReqId;
        greylistTransferRequests[reqId] = GreylistTransferRequest(msg.sender, to, tokenId, quantity, true);

        greylistNextReqId++;

        emit GreylistTransferRequestCreated(reqId, msg.sender, to, tokenId, quantity);
        return reqId;
    }

    /// @dev Approves a greylist transfer request, does the transfer and removes the request.
    /// Only ISSUER can do this.
    /// @param reqId request id, returned by requestTransfer().
    function approveTransferRequest(uint256 reqId) external onlyRole(ISSUER_ROLE) {
        GreylistTransferRequest memory req = greylistTransferRequests[reqId];

        require(req.valid, "SX1155: Invalid request id");
        delete greylistTransferRequests[reqId];

        _safeTransferFrom(req.from, req.to, req.tokenId, req.quantity, "");
        emit GreylistTransferApproved(reqId, msg.sender, req.tokenId);
    }

    /// @dev Cancels a greylist transfer request. can be issued only by the request creator.
    /// @param reqId request id returned by requestTransfer().
    function cancelTransferRequest(uint256 reqId) external {
        GreylistTransferRequest memory req = greylistTransferRequests[reqId];

        require(req.valid, "SX1155: Invalid request id");

        require(req.from == msg.sender, "SX1155: Sender is not owner of the transfer request");

        delete greylistTransferRequests[reqId];

        emit GreylistTransferCancelled(reqId, req.from, req.to, req.tokenId);
    }

    /// @dev Returns information of a greylist transfer request.
    /// @param reqId request id returned by requestTransfer().
    function transferRequestInfo(uint256 reqId)
        external
        view
        returns (
            address from,
            address to,
            uint256 tokenId,
            uint256 quantity
        )
    {
        return (
            greylistTransferRequests[reqId].from,
            greylistTransferRequests[reqId].to,
            greylistTransferRequests[reqId].tokenId,
            greylistTransferRequests[reqId].quantity
        );
    }

    /// @dev Mints a token to a given account. Only ISSUER can do this
    /// @param _to account to mint to
    /// @param _quantity number of tokens
    /// @param _tokenURI token URI string
    /// @param _data an arbitrary array of bytes
    function mint(
        address _to,
        uint256 _quantity,
        string calldata _tokenURI,
        bytes calldata _data
    ) public onlyRole(ISSUER_ROLE) {
        _mintToken(_to, _quantity, _tokenURI, _data);
    }

    /// @dev Mints a batch of tokens, only ISSUER can do this
    /// @param _accounts array of accounts to mint to
    /// @param _quantities array of quantities
    /// @param _tokenURIs array of token URI strings
    /// @param _data an arbitrary array of bytes
    function mintBatch(
        address[] calldata _accounts,
        uint256[] calldata _quantities,
        string[] calldata _tokenURIs,
        bytes[] calldata _data
    ) external arrayMaxSize(_accounts.length) {
        require(
            _accounts.length == _quantities.length &&
                _accounts.length == _tokenURIs.length &&
                _accounts.length == _data.length,
            "SX1155: Invalid inputs"
        );

        for (uint256 i = 0; i < _accounts.length; i++) {
            mint(_accounts[i], _quantities[i], _tokenURIs[i], _data[i]);
        }
    }

    /// @dev Burns a token, token owner can call this
    /// @param _id token id
    /// @param _quantity number of tokens to burn
    function burn(uint256 _id, uint256 _quantity) external {
        _burnToken(msg.sender, _id, _quantity);
    }

    /// @dev Allows an isssuer to burn a token of any account. Only ISSUER can do this.
    /// @param from token owner address
    /// @param tokenId token ID
    /// @param quantity number of tokens to burn
    /// @param reason a reason/reference string which will be emitted
    function forceBurn(
        address from,
        uint256 tokenId,
        uint256 quantity,
        string calldata reason
    ) public onlyRole(ISSUER_ROLE) {
        _burnToken(from, tokenId, quantity);
        emit ForceBurn(msg.sender, from, tokenId, reason);
    }

    /// @dev Allows an isssuer to burn tokens from a batch accounts. Only ISSUER can do this.
    /// @param _accounts an array of accounts
    /// @param _tokenIds an array of  token IDs
    /// @param _quantities an array of number of tokens to burn
    /// @param reason a reason/reference string which will be emitted
    function forceBurnBatch(
        address[] calldata _accounts,
        uint256[] calldata _tokenIds,
        uint256[] calldata _quantities,
        string calldata reason
    ) external arrayMaxSize(_accounts.length) {
        require(
            _accounts.length == _tokenIds.length && _accounts.length == _quantities.length,
            "SX1155: Invalid inputs"
        );

        for (uint256 i = 0; i < _accounts.length; i++) {
            forceBurn(_accounts[i], _tokenIds[i], _quantities[i], reason);
        }
    }

    /// @dev Allows an issuer to transfer a token from any account. Only ISSUER can do this.
    /// @param from token owner address
    /// @param to receiver address
    /// @param tokenId token ID.
    /// @param quantity number of tokens to transfer
    function forceTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) external onlyRole(ISSUER_ROLE) {
        _safeTransferFrom(from, to, tokenId, quantity, "");
        emit ForceTransfer(msg.sender, from, to, tokenId);
    }

    /// @dev Called internally before each token transfer. This allows transfers only after
    ///  all the rules and authorizations are performed.
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory quantities,
        bytes memory data
    ) internal override {
        uint256 i;

        super._beforeTokenTransfer(operator, from, to, ids, quantities, data);

        // Dont apply any restrictions on transfers from Issuer, can tranfer even when the token is paused
        if (hasRole(ISSUER_ROLE, msg.sender)) return;

        // No transfers from users when token is paused
        _requireNotPaused();

        // Cannot transfer from/to a frozen account
        if (isAccountFrozen(from) || isAccountFrozen(to)) revert("SX1155: Sender or receiver account frozen");

        // Greylisted users cannot transfer without ISSUER confirmation
        if (isGreylisted(from) || isGreylisted(to))
            revert("SX1155: Sender or receiver are greylisted. Use requestTransfer");

        // Whitelisted accounts can transfer, overrides all rules from authorized contracts
        bool senderWhitelisted = isWhitelisted(from);
        bool receiverWhitelisted = isWhitelisted(to);

        if (senderWhitelisted && receiverWhitelisted) return;

        /*
         * Authorization contracts checks on each token.
         * Skip authorization checks for burns.
         * Skip authorization on the account which is already whitelisted.
         */
        if (to != address(0)) {
            if (!senderWhitelisted && !receiverWhitelisted) {
                // Run checks on both sender and receiver

                // Check authorization for each NFT transfer
                for (i = 0; i < ids.length; i++) {
                    require(mustBeAuthorizedHolders(from, to, ids[i], data), "SX1155: Not authorized");
                }
            } else if (senderWhitelisted) {
                // Run checks on receiver
                for (i = 0; i < ids.length; i++) {
                    require(mustBeAuthorizedHolder(to, ids[i], data), "SX1155: receiver is not authorized");
                }
            } else {
                // Run checks on sender
                for (i = 0; i < ids.length; i++) {
                    require(mustBeAuthorizedHolder(from, ids[i], data), "SX1155: sender is not authorized");
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/// @title SX1155NFTBase
/// @notice SX1155 NFT Base Contract
contract SX1155NFTBase is ERC1155 {
    ///@notice SX1155NFT KYA
    string public kya;

    ///@notice NFT tokenId to KYA mapping
    mapping(uint256 => string) public tokenKya;

    ///@notice token to total supply mapping
    mapping(uint256 => uint256) private tokenSupply;

    ///@notice Contract-level metadata URI
    string public contractURI;

    ///@notice tokenID to URI mapping
    mapping(uint256 => string) private tokenURIs;

    ///@notice NFT name, a common name for all of the tokens under this contract
    string public name;

    ///@notice NFT symbol, a common symbol for all the tokens under this contract
    string public symbol;

    ///@notice Next NFT id
    uint256 public currentTokenId = 1;

    /// @dev Emitted when KYA of the contract is set
    /// @param from address of the setter
    /// @param kya KYA, a string
    event KyaUpdated(address from, string kya);

    /// @dev Emitted when KYA of a tokenId is set
    /// @param from address of the setter
    /// @param id token id
    /// @param kya KYA, a string
    event TokenKyaUpdated(address from, uint256 indexed id, string kya);
    /// @dev Emitted when contract URI set
    /// @param from address of the setter
    /// @param uri URI string
    event ContractURISet(address from, string uri);

    /// @dev Constructor for setting basic configurations.
    /// @param _name a name for all tokens under this contract
    /// @param _symbol a symbol for all tokens under this contract
    constructor(string memory _name, string memory _symbol) ERC1155("") {
        name = _name;
        symbol = _symbol;
    }

    /// @dev Returns whether this contract supports the given EIP165 interface.
    /// @param _interfaceId interface ID
    /// @return bool true or false
    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    /// @dev Returns token URI.
    /// @param _id token id
    /// @return token URI string
    function uri(uint256 _id) public view override returns (string memory) {
        return tokenURIs[_id];
    }

    /// @dev Returns the total quantity for a token ID
    /// @param _id uint256 ID of the token to query
    /// @return quantity of token in existence
    function totalSupply(uint256 _id) external view returns (uint256) {
        return tokenSupply[_id];
    }

    /// @dev Sets KYA of the contract.
    /// @param _kya KYA string
    function _setKya(string calldata _kya) internal {
        kya = _kya;
        emit KyaUpdated(msg.sender, _kya);
    }

    /// @param _kya KYA string
    function _setTokenKya(uint256 _id, string calldata _kya) internal {
        require(tokenSupply[_id] > 0, "SX1155: Token does not exist");
        tokenKya[_id] = _kya;
        emit TokenKyaUpdated(msg.sender, _id, _kya);
    }

    function _setContractURI(string calldata _contract_uri) internal {
        require(bytes(contractURI).length == 0, "SX1155: Already set");
        contractURI = _contract_uri;
        emit ContractURISet(msg.sender, _contract_uri);
    }

    /// @dev Mints a token to a given account
    /// @param _to account to mint to
    /// @param _quantity number of tokens
    /// @param _tokenURI token URI string
    /// @param _data an array of bytes
    function _mintToken(
        address _to,
        uint256 _quantity,
        string calldata _tokenURI,
        bytes calldata _data
    ) internal {
        require(_quantity > 0, "SX1155: Invalid quantity");
        uint256 _id = currentTokenId;
        tokenURIs[_id] = _tokenURI;
        tokenSupply[_id] = _quantity;
        currentTokenId++;
        _mint(_to, _id, _quantity, _data);
    }

    /// @dev Burns a token, called by owner/operator of the token
    /// @param _id token id
    /// @param _quantity number of tokens of type id to burn
    function _burnToken(
        address from,
        uint256 _id,
        uint256 _quantity
    ) internal {
        /* underflow reverts */
        tokenSupply[_id] -= _quantity;
        if (tokenSupply[_id] == 0) {
            delete tokenURIs[_id];
            delete tokenKya[_id];
        }
        _burn(from, _id, _quantity);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SX1155NFT.sol";

/// @title SX1155NFT Factory
/// @notice SX1155 NFT token deployer
contract SX1155NFTFactory is AccessControl {
    event SX1155NFTDeployed(SX1155NFT deployedAt);

    bytes32 public constant NFT_DEPLOYER_ROLE = keccak256("NFT_DEPLOYER");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @dev Function for deploy SX1155 token.
    /// @param _name a name for all tokens under this token
    /// @param _symbol a symbol for all tokens under this token
    /// @param _admin default admin address, will be assigned DEFAULT_ADMIN_ROLE Role
    /// @param _issuer default issuer address, will be assigned ISSUER Role
    /// @param _editor default editor address, will be assigned EDITOR Role
    function deployNFTContract(
        string memory _name,
        string memory _symbol,
        address _admin,
        address _issuer,
        address _editor
    ) public onlyRole(NFT_DEPLOYER_ROLE) {
        SX1155NFT newSX1155 = new SX1155NFT(_name, _symbol, _admin, _issuer, _editor);
        emit SX1155NFTDeployed(newSX1155);
    }
}