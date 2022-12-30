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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/extensions/ERC1155Burnable.sol)

pragma solidity ^0.8.0;

import "./ERC1155SetUri.sol";

/**
 * @dev Extension of {ERC1155} that allows token holders to destroy both their
 * own tokens and those that they have been approved to use.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155BurnableSetUri is ERC1155SetUri {
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );

        _burnBatch(account, ids, values);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/ERC1155Pausable.sol)

pragma solidity ^0.8.0;

import "./ERC1155SetUri.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/**
 * @dev ERC1155 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * _Available since v3.1._
 */
abstract contract ERC1155PausableSetUri is ERC1155SetUri, Pausable {
    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
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

        require(!paused(), "ERC1155Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155SetUri is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    /**@dev 
    *we set the _uri variable as internal 
    */
    string internal _uri;

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
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "./core/UbiquityDollarManager.sol";
import "./interfaces/IERC20Ubiquity.sol";

/// @title ERC20 Ubiquity preset
/// @author Ubiquity DAO
/// @notice ERC20 with :
/// - ERC20 minter, burner and pauser
/// - draft-ERC20 permit
/// - Ubiquity Manager access control
contract ERC20Ubiquity is
    IERC20Ubiquity,
    ERC20,
    ERC20Burnable,
    ERC20Pausable
{
    UbiquityDollarManager public manager;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,
    //                   uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH =
        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint256) public nonces;
    string private _tokenName;
    string private _symbol;

    // ----------- Modifiers -----------
    modifier onlyMinter() {
        require(
            manager.hasRole(manager.GOVERNANCE_TOKEN_MINTER_ROLE(), msg.sender),
            "Governance token: not minter"
        );
        _;
    }

    modifier onlyBurner() {
        require(
            manager.hasRole(manager.GOVERNANCE_TOKEN_BURNER_ROLE(), msg.sender),
            "Governance token: not burner"
        );
        _;
    }

    modifier onlyPauser() {
        require(
            manager.hasRole(manager.PAUSER_ROLE(), msg.sender),
            "Governance token: not pauser"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            manager.hasRole(manager.DEFAULT_ADMIN_ROLE(), msg.sender),
            "ERC20: deployer must be manager admin"
        );
        _;
    }

    constructor(address _manager, string memory name_, string memory symbol_)
        ERC20(name_, symbol_)
    {
        _tokenName = name_;
        _symbol = symbol_;
        manager = UbiquityDollarManager(_manager);
        // sender must be UbiquityDollarManager roleAdmin
        // because he will get the admin, minter and pauser role on Ubiquity Dollar and we want to
        // manage all permissions through the manager
        require(
            manager.hasRole(manager.DEFAULT_ADMIN_ROLE(), msg.sender),
            "ERC20: deployer must be manager admin"
        );
        uint256 chainId;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    // solhint-disable-next-line max-line-length
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes(name())),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /// @notice setSymbol update token symbol
    /// @param newSymbol new token symbol
    function setSymbol(string memory newSymbol) external onlyAdmin {
        _symbol = newSymbol;
    }

    /// @notice setName update token name
    /// @param newName new token name
    function setName(string memory newName) external onlyAdmin {
        _tokenName = newName;
    }

    /// @notice permit spending of Ubiquity Dollar. owner has signed a message allowing
    ///         spender to transfer up to amount Ubiquity Dollar
    /// @param owner the Ubiquity Dollar holder
    /// @param spender the approved operator
    /// @param value the amount approved
    /// @param deadline the deadline after which the approval is no longer valid
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        // solhint-disable-next-line not-rely-on-time
        require(deadline >= block.timestamp, "Dollar: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "Dollar: INVALID_SIGNATURE"
        );
        _approve(owner, spender, value);
    }

    /// @notice burn Ubiquity Dollar tokens from caller
    /// @param amount the amount to burn
    function burn(uint256 amount)
        public
        override (ERC20Burnable, IERC20Ubiquity)
        whenNotPaused
    {
        super.burn(amount);
        emit Burning(msg.sender, amount);
    }

    /// @notice burn Ubiquity Dollar tokens from specified account
    /// @param account the account to burn from
    /// @param amount the amount to burn
    function burnFrom(address account, uint256 amount)
        public
        override (ERC20Burnable, IERC20Ubiquity)
        onlyBurner
        whenNotPaused // to suppress ? if BURNER_ROLE should do it even paused ?
    {
        _burn(account, amount);
        emit Burning(account, amount);
    }

    // @dev Creates `amount` new tokens for `to`.
    function mint(address to, uint256 amount)
        public
        override
        onlyMinter
        whenNotPaused
    {
        _mint(to, amount);
        emit Minting(to, msg.sender, amount);
    }

    // @dev Pauses all token transfers.
    function pause() public onlyPauser {
        _pause();
    }

    // @dev Unpauses all token transfers.
    function unpause() public onlyPauser {
        _unpause();
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override (ERC20) returns (string memory) {
        return _tokenName;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override (ERC20) returns (string memory) {
        return _symbol;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        virtual
        override (ERC20, ERC20Pausable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount)
        internal
        virtual
        override
        whenNotPaused
    {
        super._transfer(sender, recipient, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./core/UbiquityDollarToken.sol";
import "./core/UbiquityDollarManager.sol";
import "./interfaces/IERC1155Ubiquity.sol";
import "./interfaces/IMetaPool.sol";
import "./interfaces/IUbiquityFormulas.sol";
import "./interfaces/ISablier.sol";
import "./interfaces/IUbiquityChef.sol";
import "./interfaces/ITWAPOracleDollar3pool.sol";
import "./interfaces/IERC1155Ubiquity.sol";
import "./utils/CollectableDust.sol";
import "./StakingFormulas.sol";
import "./StakingShare.sol";

contract Staking is CollectableDust, Pausable {
    using SafeERC20 for IERC20;

    bytes public data = "";
    UbiquityDollarManager public manager;
    uint256 public constant ONE = uint256(1 ether); // 3Crv has 18 decimals
    uint256 public stakingDiscountMultiplier = uint256(1000000 gwei); // 0.001
    uint256 public blockCountInAWeek = 45361;
    uint256 public accLpRewardPerShare = 0;

    uint256 public lpRewards;
    uint256 public totalLpToMigrate;
    address public stakingFormulasAddress;

    address public migrator; // temporary address to handle migration
    address[] private _toMigrateOriginals;
    uint256[] private _toMigrateLpBalances;
    uint256[] private _toMigrateWeeks;

    // toMigrateId[address] > 0 when address is to migrate, or 0 in all other cases
    mapping(address => uint256) public toMigrateId;
    bool public migrating = false;

    event PriceReset(
        address _tokenWithdrawn,
        uint256 _amountWithdrawn,
        uint256 _amountTransferred
    );

    event Deposit(
        address indexed _user,
        uint256 indexed _id,
        uint256 _lpAmount,
        uint256 _stakingShareAmount,
        uint256 _weeks,
        uint256 _endBlock
    );
    event RemoveLiquidityFromStake(
        address indexed _user,
        uint256 indexed _id,
        uint256 _lpAmount,
        uint256 _lpAmountTransferred,
        uint256 _lpRewards,
        uint256 _stakingShareAmount
    );

    event AddLiquidityFromStake(
        address indexed _user,
        uint256 indexed _id,
        uint256 _lpAmount,
        uint256 _stakingShareAmount
    );

    event StakingDiscountMultiplierUpdated(uint256 _stakingDiscountMultiplier);
    event BlockCountInAWeekUpdated(uint256 _blockCountInAWeek);

    event Migrated(
        address indexed _user,
        uint256 indexed _id,
        uint256 _lpsAmount,
        uint256 _sharesAmount,
        uint256 _weeks
    );

    modifier onlyStakingManager() {
        require(
            manager.hasRole(manager.STAKING_MANAGER_ROLE(), msg.sender),
            "not manager"
        );
        _;
    }

    modifier onlyPauser() {
        require(
            manager.hasRole(manager.PAUSER_ROLE(), msg.sender), "not pauser"
        );
        _;
    }

    modifier onlyMigrator() {
        require(msg.sender == migrator, "not migrator");
        _;
    }

    modifier whenMigrating() {
        require(migrating, "not in migration");
        _;
    }

    constructor(
        address _manager,
        address _stakingFormulasAddress,
        address[] memory _originals,
        uint256[] memory _lpBalances,
        uint256[] memory _weeks
    ) CollectableDust() Pausable() {
        manager = UbiquityDollarManager(_manager);
        stakingFormulasAddress = _stakingFormulasAddress;
        migrator = msg.sender;

        uint256 lgt = _originals.length;
        require(lgt > 0, "address array empty");
        require(lgt == _lpBalances.length, "balances array not same length");
        require(lgt == _weeks.length, "weeks array not same length");

        _toMigrateOriginals = _originals;
        _toMigrateLpBalances = _lpBalances;
        _toMigrateWeeks = _weeks;
        for (uint256 i = 0; i < lgt; ++i) {
            toMigrateId[_originals[i]] = i + 1;
            totalLpToMigrate += _lpBalances[i];
        }
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /// @dev addUserToMigrate add a user to migrate from V1.
    ///      IMPORTANT execute that function BEFORE sending the corresponding LP token
    ///      otherwise they will have extra LP rewards
    /// @param _original address of v1 user
    /// @param _lpBalance LP Balance of v1 user
    /// @param _weeks weeks lockup of v1 user
    /// @notice user will then be able to migrate.
    function addUserToMigrate(
        address _original,
        uint256 _lpBalance,
        uint256 _weeks
    ) external onlyMigrator {
        _toMigrateOriginals.push(_original);
        _toMigrateLpBalances.push(_lpBalance);
        totalLpToMigrate += _lpBalance;
        _toMigrateWeeks.push(_weeks);
        toMigrateId[_original] = _toMigrateOriginals.length;
    }

    function setMigrator(address _migrator) external onlyMigrator {
        migrator = _migrator;
    }

    function setMigrating(bool _migrating) external onlyMigrator {
        migrating = _migrating;
    }

    /// @dev dollarPriceReset remove Ubiquity Dollar unilaterally from the curve LP share sitting inside
    ///      the staking contract and send the Ubiquity Dollar received to the treasury.
    ///      This will have the immediate effect of pushing the Ubiquity Dollar price HIGHER
    /// @param amount of LP token to be removed for Ubiquity Dollar
    /// @notice it will remove one coin only from the curve LP share sitting in the staking contract
    function dollarPriceReset(uint256 amount) external onlyStakingManager {
        IMetaPool metaPool = IMetaPool(manager.stableSwapMetaPoolAddress());
        // remove one coin
        uint256 coinWithdrawn = metaPool.remove_liquidity_one_coin(amount, 0, 0);
        ITWAPOracleDollar3pool(manager.twapOracleAddress()).update();
        uint256 toTransfer =
            IERC20(manager.dollarTokenAddress()).balanceOf(address(this));
        IERC20(manager.dollarTokenAddress()).transfer(
            manager.treasuryAddress(), toTransfer
        );
        emit PriceReset(manager.dollarTokenAddress(), coinWithdrawn, toTransfer);
    }

    /// @dev crvPriceReset remove 3CRV unilaterally from the curve LP share sitting inside
    ///      the staking contract and send the 3CRV received to the treasury
    ///      This will have the immediate effect of pushing the Ubiquity Dollar price LOWER
    /// @param amount of LP token to be removed for 3CRV tokens
    /// @notice it will remove one coin only from the curve LP share sitting in the staking contract
    function crvPriceReset(uint256 amount) external onlyStakingManager {
        IMetaPool metaPool = IMetaPool(manager.stableSwapMetaPoolAddress());
        // remove one coin
        uint256 coinWithdrawn = metaPool.remove_liquidity_one_coin(amount, 1, 0);
        // update twap
        ITWAPOracleDollar3pool(manager.twapOracleAddress()).update();
        uint256 toTransfer =
            IERC20(manager.curve3PoolTokenAddress()).balanceOf(address(this));
        IERC20(manager.curve3PoolTokenAddress()).transfer(
            manager.treasuryAddress(), toTransfer
        );
        emit PriceReset(
            manager.curve3PoolTokenAddress(), coinWithdrawn, toTransfer
            );
    }

    function setStakingFormulasAddress(address _stakingFormulasAddress)
        external
        onlyStakingManager
    {
        stakingFormulasAddress = _stakingFormulasAddress;
    }

    /// Collectable Dust
    function addProtocolToken(address _token)
        external
        override
        onlyStakingManager
    {
        _addProtocolToken(_token);
    }

    function removeProtocolToken(address _token)
        external
        override
        onlyStakingManager
    {
        _removeProtocolToken(_token);
    }

    function sendDust(address _to, address _token, uint256 _amount)
        external
        override
        onlyStakingManager
    {
        _sendDust(_to, _token, _amount);
    }

    function setStakingDiscountMultiplier(uint256 _stakingDiscountMultiplier)
        external
        onlyStakingManager
    {
        stakingDiscountMultiplier = _stakingDiscountMultiplier;
        emit StakingDiscountMultiplierUpdated(_stakingDiscountMultiplier);
    }

    function setBlockCountInAWeek(uint256 _blockCountInAWeek)
        external
        onlyStakingManager
    {
        blockCountInAWeek = _blockCountInAWeek;
        emit BlockCountInAWeekUpdated(_blockCountInAWeek);
    }

    /// @dev deposit UbiquityDollar-3CRV LP tokens for a duration to receive staking shares
    /// @param _lpsAmount of LP token to send
    /// @param _weeks during lp token will be held
    /// @notice weeks act as a multiplier for the amount of staking shares to be received
    function deposit(uint256 _lpsAmount, uint256 _weeks)
        external
        whenNotPaused
        returns (uint256 _id)
    {
        require(
            1 <= _weeks && _weeks <= 208,
            "Staking: duration must be between 1 and 208 weeks"
        );
        ITWAPOracleDollar3pool(manager.twapOracleAddress()).update();

        // update the accumulated lp rewards per shares
        _updateLpPerShare();
        // transfer lp token to the staking contract
        IERC20(manager.stableSwapMetaPoolAddress()).safeTransferFrom(
            msg.sender, address(this), _lpsAmount
        );

        // calculate the amount of share based on the amount of lp deposited and the duration
        uint256 _sharesAmount = IUbiquityFormulas(manager.formulasAddress())
            .durationMultiply(_lpsAmount, _weeks, stakingDiscountMultiplier);
        // calculate end locking period block number
        uint256 _endBlock = block.number + _weeks * blockCountInAWeek;
        _id = _mint(msg.sender, _lpsAmount, _sharesAmount, _endBlock);

        // set masterchef for Governance rewards
        IUbiquityChef(manager.masterChefAddress()).deposit(
            msg.sender, _sharesAmount, _id
        );

        emit Deposit(
            msg.sender, _id, _lpsAmount, _sharesAmount, _weeks, _endBlock
            );
    }

    /// @dev Add an amount of UbiquityDollar-3CRV LP tokens
    /// @param _amount of LP token to deposit
    /// @param _id staking shares id
    /// @param _weeks during lp token will be held
    /// @notice staking shares are ERC1155 (aka NFT) because they have an expiration date
    function addLiquidity(uint256 _amount, uint256 _id, uint256 _weeks)
        external
        whenNotPaused
    {
        (uint256[2] memory bs, StakingShare.Stake memory stake) =
            _checkForLiquidity(_id);

        // calculate pending LP rewards
        uint256 sharesToRemove = bs[0];
        _updateLpPerShare();
        uint256 pendingLpReward =
            lpRewardForShares(sharesToRemove, stake.lpRewardDebt);

        // add an extra step to be able to decrease rewards if locking end is near
        pendingLpReward = StakingFormulas(this.stakingFormulasAddress())
            .lpRewardsAddLiquidityNormalization(stake, bs, pendingLpReward);
        // add these LP Rewards to the deposited amount of LP token
        stake.lpAmount += pendingLpReward;
        lpRewards -= pendingLpReward;
        IERC20(manager.stableSwapMetaPoolAddress()).safeTransferFrom(
            msg.sender, address(this), _amount
        );
        stake.lpAmount += _amount;

        // redeem all shares
        IUbiquityChef(manager.masterChefAddress()).withdraw(
            msg.sender, sharesToRemove, _id
        );

        // calculate the amount of share based on the new amount of lp deposited and the duration
        uint256 _sharesAmount = IUbiquityFormulas(manager.formulasAddress())
            .durationMultiply(stake.lpAmount, _weeks, stakingDiscountMultiplier);

        // deposit new shares
        IUbiquityChef(manager.masterChefAddress()).deposit(
            msg.sender, _sharesAmount, _id
        );
        // calculate end locking period block number
        // 1 week = 45361 blocks = 2371753*7/366
        // n = (block + duration * 45361)
        stake.endBlock = block.number + _weeks * blockCountInAWeek;

        // should be done after masterchef withdraw
        _updateLpPerShare();
        stake.lpRewardDebt = (
            IUbiquityChef(manager.masterChefAddress()).getStakingShareInfo(_id)[0]
                * accLpRewardPerShare
        ) / 1e12;

        StakingShare(manager.stakingShareAddress()).updateStake(
            _id, stake.lpAmount, stake.lpRewardDebt, stake.endBlock
        );
        emit AddLiquidityFromStake(
            msg.sender, _id, stake.lpAmount, _sharesAmount
            );
    }

    /// @dev Remove an amount of UbiquityDollar-3CRV LP tokens
    /// @param _amount of LP token deposited when _id was created to be withdrawn
    /// @param _id staking shares id
    /// @notice staking shares are ERC1155 (aka NFT) because they have an expiration date
    function removeLiquidity(uint256 _amount, uint256 _id)
        external
        whenNotPaused
    {
        (uint256[2] memory bs, StakingShare.Stake memory stake) =
            _checkForLiquidity(_id);
        require(stake.lpAmount >= _amount, "Staking: amount too big");
        // we should decrease the Governance token rewards proportionally to the LP removed
        // sharesToRemove = (staking shares * _amount )  / stake.lpAmount ;
        uint256 sharesToRemove = StakingFormulas(this.stakingFormulasAddress())
            .sharesForLP(stake, bs, _amount);

        //get all its pending LP Rewards
        _updateLpPerShare();
        uint256 pendingLpReward = lpRewardForShares(bs[0], stake.lpRewardDebt);
        // update staking shares
        // stake.shares = stake.shares - sharesToRemove;
        // get masterchef for Governance token rewards To ensure correct computation
        // it needs to be done BEFORE updating the bonding share
        IUbiquityChef(manager.masterChefAddress()).withdraw(
            msg.sender, sharesToRemove, _id
        );

        // redeem of the extra LP
        // staking lp balance - StakingShare.totalLP
        IERC20 metapool = IERC20(manager.stableSwapMetaPoolAddress());

        // add an extra step to be able to decrease rewards if locking end is near
        pendingLpReward = StakingFormulas(this.stakingFormulasAddress())
            .lpRewardsRemoveLiquidityNormalization(stake, bs, pendingLpReward);

        uint256 correctedAmount = StakingFormulas(this.stakingFormulasAddress())
            .correctedAmountToWithdraw(
            StakingShare(manager.stakingShareAddress()).totalLP(),
            metapool.balanceOf(address(this)) - lpRewards,
            _amount
        );

        lpRewards -= pendingLpReward;
        stake.lpAmount -= _amount;

        // stake.lpRewardDebt = (staking shares * accLpRewardPerShare) /  1e18;
        // user.amount.mul(pool.accSushiPerShare).div(1e12);
        // should be done after masterchef withdraw
        stake.lpRewardDebt = (
            IUbiquityChef(manager.masterChefAddress()).getStakingShareInfo(_id)[0]
                * accLpRewardPerShare
        ) / 1e12;

        StakingShare(manager.stakingShareAddress()).updateStake(
            _id, stake.lpAmount, stake.lpRewardDebt, stake.endBlock
        );

        // lastly redeem lp tokens
        metapool.safeTransfer(msg.sender, correctedAmount + pendingLpReward);
        emit RemoveLiquidityFromStake(
            msg.sender,
            _id,
            _amount,
            correctedAmount,
            pendingLpReward,
            sharesToRemove
            );
    }

    // View function to see pending lpRewards on frontend.
    function pendingLpRewards(uint256 _id) external view returns (uint256) {
        StakingShare staking = StakingShare(manager.stakingShareAddress());
        StakingShare.Stake memory stake = staking.getStake(_id);
        uint256[2] memory bs =
            IUbiquityChef(manager.masterChefAddress()).getStakingShareInfo(_id);

        uint256 lpBalance =
            IERC20(manager.stableSwapMetaPoolAddress()).balanceOf(address(this));
        // the excess LP is the current balance minus the total deposited LP
        if (lpBalance >= (staking.totalLP() + totalLpToMigrate)) {
            uint256 currentLpRewards =
                lpBalance - (staking.totalLP() + totalLpToMigrate);
            uint256 curAccLpRewardPerShare = accLpRewardPerShare;
            // if new rewards we should calculate the new curAccLpRewardPerShare
            if (currentLpRewards > lpRewards) {
                uint256 newLpRewards = currentLpRewards - lpRewards;
                curAccLpRewardPerShare = accLpRewardPerShare
                    + (
                        (newLpRewards * 1e12)
                            / IUbiquityChef(manager.masterChefAddress()).totalShares()
                    );
            }
            // we multiply the shares amount by the accumulated lpRewards per share
            // and remove the lp Reward Debt
            return (bs[0] * (curAccLpRewardPerShare)) / (1e12)
                - (stake.lpRewardDebt);
        }
        return 0;
    }

    function pause() public virtual onlyPauser {
        _pause();
    }

    function unpause() public virtual onlyPauser {
        _unpause();
    }

    /// @dev migrate let a user migrate from V1
    /// @notice user will then be able to migrate
    function migrate() public whenMigrating returns (uint256 _id) {
        _id = toMigrateId[msg.sender];
        require(_id > 0, "not v1 address");

        _migrate(
            _toMigrateOriginals[_id - 1],
            _toMigrateLpBalances[_id - 1],
            _toMigrateWeeks[_id - 1]
        );
    }

    /// @dev return the amount of Lp token rewards an amount of shares entitled
    /// @param amount of staking shares
    /// @param lpRewardDebt lp rewards that has already been distributed
    function lpRewardForShares(uint256 amount, uint256 lpRewardDebt)
        public
        view
        returns (uint256 pendingLpReward)
    {
        if (accLpRewardPerShare > 0) {
            pendingLpReward =
                (amount * accLpRewardPerShare) / 1e12 - (lpRewardDebt);
        }
    }

    function currentShareValue() public view returns (uint256 priceShare) {
        uint256 totalShares =
            IUbiquityChef(manager.masterChefAddress()).totalShares();
        // priceShare = totalLP / totalShares
        priceShare = IUbiquityFormulas(manager.formulasAddress()).bondPrice(
            StakingShare(manager.stakingShareAddress()).totalLP(),
            totalShares,
            ONE
        );
    }

    /// @dev migrate let a user migrate from V1
    /// @notice user will then be able to migrate
    function _migrate(address user, uint256 _lpsAmount, uint256 _weeks)
        internal
        returns (uint256 _id)
    {
        require(toMigrateId[user] > 0, "not v1 address");
        require(_lpsAmount > 0, "LP amount is zero");
        require(
            1 <= _weeks && _weeks <= 208,
            "Duration must be between 1 and 208 weeks"
        );

        // unregister address
        toMigrateId[user] = 0;

        // calculate the amount of share based on the amount of lp deposited and the duration
        uint256 _sharesAmount = IUbiquityFormulas(manager.formulasAddress())
            .durationMultiply(_lpsAmount, _weeks, stakingDiscountMultiplier);

        // update the accumulated lp rewards per shares
        _updateLpPerShare();
        // calculate end locking period block number
        uint256 endBlock = block.number + _weeks * blockCountInAWeek;
        _id = _mint(user, _lpsAmount, _sharesAmount, endBlock);
        // reduce the total LP to migrate after the minting
        // to keep the _updateLpPerShare calculation consistent
        totalLpToMigrate -= _lpsAmount;
        // set masterchef for Governance token rewards
        IUbiquityChef(manager.masterChefAddress()).deposit(
            user, _sharesAmount, _id
        );

        emit Migrated(user, _id, _lpsAmount, _sharesAmount, _weeks);
    }

    /// @dev update the accumulated excess LP per share
    function _updateLpPerShare() internal {
        StakingShare stake = StakingShare(manager.stakingShareAddress());
        uint256 lpBalance =
            IERC20(manager.stableSwapMetaPoolAddress()).balanceOf(address(this));
        // the excess LP is the current balance
        // minus the total deposited LP + LP that needs to be migrated
        uint256 totalShares =
            IUbiquityChef(manager.masterChefAddress()).totalShares();
        if (
            lpBalance >= (stake.totalLP() + totalLpToMigrate) && totalShares > 0
        ) {
            uint256 currentLpRewards =
                lpBalance - (stake.totalLP() + totalLpToMigrate);

            // is there new LP rewards to be distributed ?
            if (currentLpRewards > lpRewards) {
                // we calculate the new accumulated LP rewards per share
                accLpRewardPerShare = accLpRewardPerShare
                    + (((currentLpRewards - lpRewards) * 1e12) / totalShares);

                // update the bonding contract lpRewards
                lpRewards = currentLpRewards;
            }
        }
    }

    function _mint(
        address to,
        uint256 lpAmount,
        uint256 shares,
        uint256 endBlock
    ) internal returns (uint256) {
        uint256 _currentShareValue = currentShareValue();
        require(
            _currentShareValue != 0, "Staking: share value should not be null"
        );
        // set the lp rewards debts so that this staking share only get lp rewards from this day
        uint256 lpRewardDebt = (shares * accLpRewardPerShare) / 1e12;
        return StakingShare(manager.stakingShareAddress()).mint(
            to, lpAmount, lpRewardDebt, endBlock
        );
    }

    function _checkForLiquidity(uint256 _id)
        internal
        returns (uint256[2] memory bs, StakingShare.Stake memory stake)
    {
        require(
            IERC1155Ubiquity(manager.stakingShareAddress()).balanceOf(
                msg.sender, _id
            ) == 1,
            "Staking: caller is not owner"
        );
        StakingShare staking = StakingShare(manager.stakingShareAddress());
        stake = staking.getStake(_id);
        require(
            block.number > stake.endBlock,
            "Staking: Redeem not allowed before staking time"
        );

        ITWAPOracleDollar3pool(manager.twapOracleAddress()).update();
        bs = IUbiquityChef(manager.masterChefAddress()).getStakingShareInfo(_id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./StakingShare.sol";
import "./libs/ABDKMathQuad.sol";

contract StakingFormulas {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    uint256 public constant ONE = uint256(1 ether); //   18 decimals

    /// @dev formula Governance Rights corresponding to a staking shares LP amount
    /// @param _stake , staking share
    /// @param _amount , amount of LP tokens
    /// @notice shares = (stake.shares * _amount )  / stake.lpAmount ;
    function sharesForLP(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) public pure returns (uint256 _uLP) {
        bytes16 a = _shareInfo[0].fromUInt(); // shares amount
        bytes16 v = _amount.fromUInt();
        bytes16 t = _stake.lpAmount.fromUInt();

        _uLP = a.mul(v).div(t).toUInt();
    }

    /// @dev formula may add a decreasing rewards if locking end is near when removing liquidity
    /// @param _stake , staking share
    /// @param _amount , amount of LP tokens
    /// @notice rewards = _amount;
    // solhint-disable-block  no-unused-vars
    /* solhint-disable no-unused-vars */
    function lpRewardsRemoveLiquidityNormalization(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) public pure returns (uint256) {
        return _amount;
    }

    /* solhint-enable no-unused-vars */
    /// @dev formula may add a decreasing rewards if locking end is near when adding liquidity
    /// @param _stake , staking share
    /// @param _amount , amount of LP tokens
    /// @notice rewards = _amount;
    // solhint-disable-block  no-unused-vars
    /* solhint-disable no-unused-vars */
    function lpRewardsAddLiquidityNormalization(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) public pure returns (uint256) {
        return _amount;
    }

    /* solhint-enable no-unused-vars */

    /// @dev formula to calculate the corrected amount to withdraw based on the proportion of
    ///      lp deposited against actual LP token on the staking contract
    /// @param _totalLpDeposited , Total amount of LP deposited by users
    /// @param _stakingLpBalance , actual staking contract LP tokens balance minus lp rewards
    /// @param _amount , amount of LP tokens
    /// @notice corrected_amount = amount * ( stakingLpBalance / totalLpDeposited)
    ///         if there is more or the same amount of LP than deposited then do nothing
    function correctedAmountToWithdraw(
        uint256 _totalLpDeposited,
        uint256 _stakingLpBalance,
        uint256 _amount
    ) public pure returns (uint256) {
        if (_stakingLpBalance < _totalLpDeposited && _stakingLpBalance > 0) {
            // if there is less LP token inside the staking contract that what have been deposited
            // we have to reduce proportionally the lp amount to withdraw
            return _amount.fromUInt().mul(_stakingLpBalance.fromUInt()).div(
                _totalLpDeposited.fromUInt()
            ).toUInt();
        }
        return _amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "./ERC1155SetUri/ERC1155SetUri.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ERC1155SetUri/ERC1155BurnableSetUri.sol";
import "./ERC1155SetUri/ERC1155PausableSetUri.sol";
import "./core/UbiquityDollarManager.sol";
import "./utils/SafeAddArray.sol";

contract StakingShare is ERC1155SetUri, ERC1155BurnableSetUri, ERC1155PausableSetUri {
    using SafeAddArray for uint256[];

    struct Stake {
        // address of the minter
        address minter;
        // lp amount deposited by the user
        uint256 lpFirstDeposited;
        uint256 creationBlock;
        // lp that were already there when created
        uint256 lpRewardDebt;
        uint256 endBlock;
        // lp remaining for a user
        uint256 lpAmount;
    }

    UbiquityDollarManager public manager;
    // Mapping from account to operator approvals
    mapping(address => uint256[]) private _holderBalances;
    mapping(uint256 => Stake) private _stakes;
    uint256 private _totalLP;
    uint256 private _totalSupply;

    // ----------- Modifiers -----------
    modifier onlyMinter() {
        require(
            manager.hasRole(manager.GOVERNANCE_TOKEN_MINTER_ROLE(), msg.sender),
            "Governance token: not minter"
        );
        _;
    }
    
    modifier onlyStakingManager() {
        require(
            manager.hasRole(manager.STAKING_MANAGER_ROLE(), msg.sender),
            "Governance token: not staking manager"
        );
        _;
    }

    modifier onlyBurner() {
        require(
            manager.hasRole(manager.GOVERNANCE_TOKEN_BURNER_ROLE(), msg.sender),
            "Governance token: not burner"
        );
        _;
    }

    modifier onlyPauser() {
        require(
            manager.hasRole(manager.PAUSER_ROLE(), msg.sender),
            "Governance token: not pauser"
        );
        _;
    }

    /**
     * @dev constructor
     */
    constructor(address _manager, string memory uri) ERC1155SetUri(uri) {
        manager = UbiquityDollarManager(_manager);
    }

    /// @dev update stake LP amount , LP rewards debt and end block.
    /// @param _stakeId staking share id
    /// @param _lpAmount amount of LP token deposited
    /// @param _lpRewardDebt amount of excess LP token inside the staking contract
    /// @param _endBlock end locking period block number
    function updateStake(
        uint256 _stakeId,
        uint256 _lpAmount,
        uint256 _lpRewardDebt,
        uint256 _endBlock
    ) external onlyMinter whenNotPaused {
        Stake storage stake = _stakes[_stakeId];
        uint256 curLpAmount = stake.lpAmount;
        if (curLpAmount > _lpAmount) {
            // we are removing LP
            _totalLP -= curLpAmount - _lpAmount;
        } else {
            // we are adding LP
            _totalLP += _lpAmount - curLpAmount;
        }
        stake.lpAmount = _lpAmount;
        stake.lpRewardDebt = _lpRewardDebt;
        stake.endBlock = _endBlock;
    }

    // @dev Creates `amount` new tokens for `to`, of token type `id`.
    /// @param to owner address
    /// @param lpDeposited amount of LP token deposited
    /// @param lpRewardDebt amount of excess LP token inside the staking contract
    /// @param endBlock block number when the locking period ends
    function mint(
        address to,
        uint256 lpDeposited,
        uint256 lpRewardDebt,
        uint256 endBlock
    ) public virtual onlyMinter whenNotPaused returns (uint256 id) {
        id = _totalSupply + 1;
        _mint(to, id, 1, bytes(""));
        _totalSupply += 1;
        _holderBalances[to].add(id);
        Stake storage _stake = _stakes[id];
        _stake.minter = to;
        _stake.lpFirstDeposited = lpDeposited;
        _stake.lpAmount = lpDeposited;
        _stake.lpRewardDebt = lpRewardDebt;
        _stake.creationBlock = block.number;
        _stake.endBlock = endBlock;
        _totalLP += lpDeposited;
    }

    /**
     * @dev Pauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_pause}.
     *
     */
    function pause() public virtual onlyPauser {
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {ERC1155Pausable} and {Pausable-_unpause}.
     *
     */
    function unpause() public virtual onlyPauser {
        _unpause();
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
    ) public override whenNotPaused {
        super.safeTransferFrom(from, to, id, amount, data);
        _holderBalances[to].add(id);
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
    ) public virtual override whenNotPaused {
        super.safeBatchTransferFrom(from, to, ids, amounts, data);
        _holderBalances[to].add(ids);
    }

    /**
     * @dev Total amount of tokens  .
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Total amount of LP tokens deposited.
     */
    function totalLP() public view virtual returns (uint256) {
        return _totalLP;
    }

    /**
     * @dev return stake details.
     */
    function getStake(uint256 id) public view returns (Stake memory) {
        return _stakes[id];
    }

    /**
     * @dev array of token Id held by the msg.sender.
     */
    function holderTokens(address holder)
        public
        view
        returns (uint256[] memory)
    {
        return _holderBalances[holder];
    }

    function _burn(address account, uint256 id, uint256 amount)
        internal
        virtual
        override
        whenNotPaused
    {
        require(amount == 1, "amount <> 1");
        super._burn(account, id, 1);
        Stake storage _stake = _stakes[id];
        require(_stake.lpAmount == 0, "LP <> 0");
        _totalSupply -= 1;
    }

    function _burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual override whenNotPaused {
        super._burnBatch(account, ids, amounts);
        for (uint256 i = 0; i < ids.length; ++i) {
            _totalSupply -= amounts[i];
        }
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override (ERC1155SetUri, ERC1155PausableSetUri) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
    
    /**
    *@dev this function is used to allow the staking manage to fix the uri should anything be wrong with the current one.
     */
    
    function setUri(string memory newUri) external onlyStakingManager{
        _uri = newUri;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./core/UbiquityDollarManager.sol";
import "./interfaces/IERC20Ubiquity.sol";
import "./interfaces/ITWAPOracleDollar3pool.sol";
import "./StakingShare.sol";
import "./interfaces/IUbiquityFormulas.sol";
import "./interfaces/IERC1155Ubiquity.sol";

contract UbiquityChef is ReentrancyGuard {
    using SafeERC20 for IERC20Ubiquity;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct StakingShareInfo {
        uint256 amount; // staking rights.
        uint256 rewardDebt; // Reward debt. See explanation below.
            //
            // We do some fancy math here. Basically, any point in time, the amount of Governance Tokens
            // entitled to a user but is pending to be distributed is:
            //
            //   pending reward = (user.amount * pool.accGovernancePerShare) - user.rewardDebt
            //
            // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
            //   1. The pool's `accGovernancePerShare` (and `lastRewardBlock`) gets updated.
            //   2. User receives the pending reward sent to his/her address.
            //   3. User's `amount` gets updated.
            //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.

    struct PoolInfo {
        uint256 lastRewardBlock; // Last block number that Governance Token distribution occurs.
        uint256 accGovernancePerShare; // Accumulated Governance Tokens per share, times 1e12. See below.
    }

    uint256 private _totalShares;

    // Ubiquity Manager
    UbiquityDollarManager public manager;

    // Governance Tokens created per block.
    uint256 public governancePerBlock;
    // Bonus multiplier for early Governance Token makers.
    uint256 public governanceMultiplier = 1e18;
    uint256 public minPriceDiffToUpdateMultiplier = 1e15;
    uint256 public lastPrice = 1e18;
    uint256 public governanceDivider;
    // Info of each pool.
    PoolInfo public pool;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => StakingShareInfo) private _ssInfo;

    event Deposit(
        address indexed user, uint256 amount, uint256 indexed stakingShareId
    );

    event Withdraw(
        address indexed user, uint256 amount, uint256 indexed stakingShareId
    );

    event GovernancePerBlockModified(uint256 indexed governancePerBlock);

    event MinPriceDiffToUpdateMultiplierModified(
        uint256 indexed minPriceDiffToUpdateMultiplier
    );

    // ----------- Modifiers -----------
    modifier onlyTokenManager() {
        require(
            manager.hasRole(manager.GOVERNANCE_TOKEN_MANAGER_ROLE(), msg.sender),
            "MasterChef: not Governance Token manager"
        );
        _;
    }

    modifier onlyStakingContract() {
        require(
            msg.sender == manager.stakingContractAddress(),
            "MasterChef: not Staking Contract"
        );
        _;
    }

    constructor(
        address _manager,
        address[] memory _tos,
        uint256[] memory _amounts,
        uint256[] memory _stakingShareIDs
    ) {
        manager = UbiquityDollarManager(_manager);
        pool.lastRewardBlock = block.number;
        pool.accGovernancePerShare = 0; // uint256(1e12);
        governanceDivider = 5; // 100 / 5 = 20% extra minted Governance Tokens for treasury
        _updateGovernanceMultiplier();

        uint256 lgt = _tos.length;
        require(lgt == _amounts.length, "_amounts array not same length");
        require(
            lgt == _stakingShareIDs.length,
            "_stakingShareIDs array not same length"
        );

        for (uint256 i = 0; i < lgt; ++i) {
            _deposit(_tos[i], _amounts[i], _stakingShareIDs[i]);
        }
    }

    function setGovernancePerBlock(uint256 _governancePerBlock)
        external
        onlyTokenManager
    {
        governancePerBlock = _governancePerBlock;
        emit GovernancePerBlockModified(_governancePerBlock);
    }

    // the bigger governanceDivider is the less extra Governance Tokens will be minted for the treasury
    function setGovernanceShareForTreasury(uint256 _governanceDivider)
        external
        onlyTokenManager
    {
        governanceDivider = _governanceDivider;
    }

    function setMinPriceDiffToUpdateMultiplier(
        uint256 _minPriceDiffToUpdateMultiplier
    ) external onlyTokenManager {
        minPriceDiffToUpdateMultiplier = _minPriceDiffToUpdateMultiplier;
        emit MinPriceDiffToUpdateMultiplierModified(
            _minPriceDiffToUpdateMultiplier
            );
    }

    // Deposit LP tokens to MasterChef for Governance Tokens allocation.
    function deposit(address to, uint256 _amount, uint256 _stakingShareID)
        external
        nonReentrant
        onlyStakingContract
    {
        _deposit(to, _amount, _stakingShareID);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(address to, uint256 _amount, uint256 _stakingShareID)
        external
        nonReentrant
        onlyStakingContract
    {
        StakingShareInfo storage ss = _ssInfo[_stakingShareID];
        require(ss.amount >= _amount, "MC: amount too high");
        _updatePool();
        uint256 pending =
            ((ss.amount * pool.accGovernancePerShare) / 1e12) - ss.rewardDebt;
        // send Governance Tokens to Staking Share holder

        _safeGovernanceTransfer(to, pending);
        ss.amount -= _amount;
        ss.rewardDebt = (ss.amount * pool.accGovernancePerShare) / 1e12;
        _totalShares -= _amount;
        emit Withdraw(to, _amount, _stakingShareID);
    }

    /// @dev get pending Governance Token rewards from MasterChef.
    /// @return amount of pending rewards transferred to msg.sender
    /// @notice only send pending rewards
    function getRewards(uint256 stakingShareID) external returns (uint256) {
        require(
            IERC1155Ubiquity(manager.stakingShareAddress()).balanceOf(
                msg.sender, stakingShareID
            ) == 1,
            "MS: caller is not owner"
        );

        // calculate user reward
        StakingShareInfo storage user = _ssInfo[stakingShareID];
        _updatePool();
        uint256 pending = ((user.amount * pool.accGovernancePerShare) / 1e12)
            - user.rewardDebt;
        _safeGovernanceTransfer(msg.sender, pending);
        user.rewardDebt = (user.amount * pool.accGovernancePerShare) / 1e12;
        return pending;
    }

    // View function to see pending Governance Tokens on frontend.
    function pendingGovernance(uint256 stakingShareID)
        external
        view
        returns (uint256)
    {
        StakingShareInfo storage user = _ssInfo[stakingShareID];
        uint256 accGovernancePerShare = pool.accGovernancePerShare;

        if (block.number > pool.lastRewardBlock && _totalShares != 0) {
            uint256 multiplier = _getMultiplier();
            uint256 governanceReward = (multiplier * governancePerBlock) / 1e18;
            accGovernancePerShare = accGovernancePerShare
                + ((governanceReward * 1e12) / _totalShares);
        }
        return (user.amount * accGovernancePerShare) / 1e12 - user.rewardDebt;
    }

    /**
     * @dev get the amount of shares and the reward debt of a staking share .
     */
    function getStakingShareInfo(uint256 _id)
        external
        view
        returns (uint256[2] memory)
    {
        return [_ssInfo[_id].amount, _ssInfo[_id].rewardDebt];
    }

    /**
     * @dev Total amount of shares .
     */
    function totalShares() external view virtual returns (uint256) {
        return _totalShares;
    }

    // _Deposit LP tokens to MasterChef for Governance Token allocation.
    function _deposit(address to, uint256 _amount, uint256 _stakingShareID)
        internal
    {
        StakingShareInfo storage ss = _ssInfo[_stakingShareID];
        _updatePool();
        if (ss.amount > 0) {
            uint256 pending = ((ss.amount * pool.accGovernancePerShare) / 1e12)
                - ss.rewardDebt;
            _safeGovernanceTransfer(to, pending);
        }
        ss.amount += _amount;
        ss.rewardDebt = (ss.amount * pool.accGovernancePerShare) / 1e12;
        _totalShares += _amount;
        emit Deposit(to, _amount, _stakingShareID);
    }

    // UPDATE Governance Token multiplier
    function _updateGovernanceMultiplier() internal {
        // (1.05/(1+abs(1-TWAP_PRICE)))
        uint256 currentPrice = _getTwapPrice();

        bool isPriceDiffEnough = false;
        // a minimum price variation is needed to update the multiplier
        if (currentPrice > lastPrice) {
            isPriceDiffEnough =
                currentPrice - lastPrice > minPriceDiffToUpdateMultiplier;
        } else {
            isPriceDiffEnough =
                lastPrice - currentPrice > minPriceDiffToUpdateMultiplier;
        }

        if (isPriceDiffEnough) {
            governanceMultiplier = IUbiquityFormulas(manager.formulasAddress())
                .governanceMultiply(governanceMultiplier, currentPrice);
            lastPrice = currentPrice;
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool() internal {
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        _updateGovernanceMultiplier();

        if (_totalShares == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = _getMultiplier();
        uint256 governanceReward = (multiplier * governancePerBlock) / 1e18;
        IERC20Ubiquity(manager.governanceTokenAddress()).mint(
            address(this), governanceReward
        );
        // mint another x% for the treasury
        IERC20Ubiquity(manager.governanceTokenAddress()).mint(
            manager.treasuryAddress(), governanceReward / governanceDivider
        );
        pool.accGovernancePerShare = pool.accGovernancePerShare
            + ((governanceReward * 1e12) / _totalShares);
        pool.lastRewardBlock = block.number;
    }

    // Safe Governance Token transfer function, just in case if rounding
    // error causes pool to not have enough Governance Tokens.
    function _safeGovernanceTransfer(address _to, uint256 _amount) internal {
        IERC20Ubiquity governanceToken =
            IERC20Ubiquity(manager.governanceTokenAddress());
        uint256 governanceBalance = governanceToken.balanceOf(address(this));
        if (_amount > governanceBalance) {
            governanceToken.safeTransfer(_to, governanceBalance);
        } else {
            governanceToken.safeTransfer(_to, _amount);
        }
    }

    function _getMultiplier() internal view returns (uint256) {
        return (block.number - pool.lastRewardBlock) * governanceMultiplier;
    }

    function _getTwapPrice() internal view returns (uint256) {
        return ITWAPOracleDollar3pool(manager.twapOracleAddress()).consult(
            manager.dollarTokenAddress()
        );
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "../interfaces/IMetaPool.sol";

contract TWAPOracleDollar3pool {
    address public immutable pool;
    address public immutable token0;
    address public immutable token1;
    uint256 public price0Average;
    uint256 public price1Average;
    uint256 public pricesBlockTimestampLast;
    uint256[2] public priceCumulativeLast;

    constructor(
        address _pool,
        address _dollarToken0,
        address _curve3CRVToken1
    ) {
        pool = _pool;
        // coin at index 0 is Ubiquity Dollar and index 1 is 3CRV
        require(
            IMetaPool(_pool).coins(0) == _dollarToken0
                && IMetaPool(_pool).coins(1) == _curve3CRVToken1,
            "TWAPOracle: COIN_ORDER_MISMATCH"
        );

        token0 = _dollarToken0;
        token1 = _curve3CRVToken1;

        uint256 _reserve0 = uint112(IMetaPool(_pool).balances(0));
        uint256 _reserve1 = uint112(IMetaPool(_pool).balances(1));

        // ensure that there's liquidity in the pair
        require(_reserve0 != 0 && _reserve1 != 0, "TWAPOracle: NO_RESERVES");
        // ensure that pair balance is perfect
        require(_reserve0 == _reserve1, "TWAPOracle: PAIR_UNBALANCED");
        priceCumulativeLast = IMetaPool(_pool).get_price_cumulative_last();
        pricesBlockTimestampLast = IMetaPool(_pool).block_timestamp_last();

        price0Average = 1 ether;
        price1Average = 1 ether;
    }

    // calculate average price
    function update() external {
        (uint256[2] memory priceCumulative, uint256 blockTimestamp) =
            _currentCumulativePrices();

        if (blockTimestamp - pricesBlockTimestampLast > 0) {
            // get the balances between now and the last price cumulative snapshot
            uint256[2] memory twapBalances = IMetaPool(pool).get_twap_balances(
                priceCumulativeLast,
                priceCumulative,
                blockTimestamp - pricesBlockTimestampLast
            );

            // price to exchange amountIn Ubiquity Dollar to 3CRV based on TWAP
            price0Average = IMetaPool(pool).get_dy(0, 1, 1 ether, twapBalances);
            // price to exchange amountIn 3CRV to Ubiquity Dollar based on TWAP
            price1Average = IMetaPool(pool).get_dy(1, 0, 1 ether, twapBalances);
            // we update the priceCumulative
            priceCumulativeLast = priceCumulative;
            pricesBlockTimestampLast = blockTimestamp;
        }
    }

    // note this will always return 0 before update has been called successfully
    // for the first time.
    function consult(address token) external view returns (uint256 amountOut) {
        if (token == token0) {
            // price to exchange 1 Ubiquity Dollar to 3CRV based on TWAP
            amountOut = price0Average;
        } else {
            require(token == token1, "TWAPOracle: INVALID_TOKEN");
            // price to exchange 1 3CRV to Ubiquity Dollar based on TWAP
            amountOut = price1Average;
        }
    }

    function _currentCumulativePrices()
        internal
        view
        returns (uint256[2] memory priceCumulative, uint256 blockTimestamp)
    {
        priceCumulative = IMetaPool(pool).get_price_cumulative_last();
        blockTimestamp = IMetaPool(pool).block_timestamp_last();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IUbiquityDollarToken.sol";
import "../interfaces/ICurveFactory.sol";
import "../interfaces/IMetaPool.sol";

import "./TWAPOracleDollar3pool.sol";

/// @title A central config for the Ubiquity Dollar system. Also acts as a central
/// access control manager.
/// @notice For storing constants. For storing variables and allowing them to
/// be changed by the admin (governance)
/// @dev This should be used as a central access control manager which other
/// contracts use to check permissions
contract UbiquityDollarManager is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 public constant GOVERNANCE_TOKEN_MINTER_ROLE =
        keccak256("GOVERNANCE_TOKEN_MINTER_ROLE");
    bytes32 public constant GOVERNANCE_TOKEN_BURNER_ROLE =
        keccak256("GOVERNANCE_TOKEN_BURNER_ROLE");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant CREDIT_NFT_MANAGER_ROLE =
        keccak256("CREDIT_NFT_MANAGER_ROLE");
    bytes32 public constant STAKING_MANAGER_ROLE =
        keccak256("STAKING_MANAGER_ROLE");
    bytes32 public constant INCENTIVE_MANAGER_ROLE =
        keccak256("INCENTIVE_MANAGER");
    bytes32 public constant GOVERNANCE_TOKEN_MANAGER_ROLE =
        keccak256("GOVERNANCE_TOKEN_MANAGER_ROLE");
    address public twapOracleAddress;
    address public creditNFTAddress;
    address public dollarTokenAddress;
    address public creditNFTCalculatorAddress;
    address public dollarMintCalculatorAddress;
    address public stakingShareAddress;
    address public stakingContractAddress;
    address public stableSwapMetaPoolAddress;
    address public curve3PoolTokenAddress; // 3CRV
    address public treasuryAddress;
    address public governanceTokenAddress;
    address public sushiSwapPoolAddress; // sushi pool UbiquityDollar-GovernanceToken
    address public masterChefAddress;
    address public formulasAddress;
    address public creditTokenAddress;
    address public creditCalculatorAddress;

    //key = address of CreditNFTManager, value = DollarMintExcess
    mapping(address => address) private _excessDollarDistributors;

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "MGR: Caller is not admin"
        );
        _;
    }

    constructor(address _admin) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setupRole(GOVERNANCE_TOKEN_MINTER_ROLE, _admin);
        _setupRole(PAUSER_ROLE, _admin);
        _setupRole(CREDIT_NFT_MANAGER_ROLE, _admin);
        _setupRole(STAKING_MANAGER_ROLE, _admin);
        _setupRole(INCENTIVE_MANAGER_ROLE, _admin);
        _setupRole(GOVERNANCE_TOKEN_MANAGER_ROLE, address(this));
    }

    // TODO Add a generic setter for extra addresses that needs to be linked
    function setTwapOracleAddress(address _twapOracleAddress)
        external
        onlyAdmin
    {
        twapOracleAddress = _twapOracleAddress;
        // to be removed

        TWAPOracleDollar3pool oracle = TWAPOracleDollar3pool(twapOracleAddress);
        oracle.update();
    }

    function setCreditTokenAddress(address _creditTokenAddress)
        external
        onlyAdmin
    {
        creditTokenAddress = _creditTokenAddress;
    }

    function setCreditNFTAddress(address _creditNFTAddress)
        external
        onlyAdmin
    {
        creditNFTAddress = _creditNFTAddress;
    }

    function setIncentiveToDollar(address _account, address _incentiveAddress)
        external
        onlyAdmin
    {
        IUbiquityDollarToken(dollarTokenAddress).setIncentiveContract(
            _account, _incentiveAddress
        );
    }

    function setDollarTokenAddress(address _dollarTokenAddress)
        external
        onlyAdmin
    {
        dollarTokenAddress = _dollarTokenAddress;
    }

    function setGovernanceTokenAddress(address _governanceTokenAddress)
        external
        onlyAdmin
    {
        governanceTokenAddress = _governanceTokenAddress;
    }

    function setSushiSwapPoolAddress(address _sushiSwapPoolAddress)
        external
        onlyAdmin
    {
        sushiSwapPoolAddress = _sushiSwapPoolAddress;
    }

    function setCreditCalculatorAddress(address _creditCalculatorAddress)
        external
        onlyAdmin
    {
        creditCalculatorAddress = _creditCalculatorAddress;
    }

    function setCreditNFTCalculatorAddress(address _creditNFTCalculatorAddress)
        external
        onlyAdmin
    {
        creditNFTCalculatorAddress = _creditNFTCalculatorAddress;
    }

    function setDollarMintCalculatorAddress(
        address _dollarMintCalculatorAddress
    ) external onlyAdmin {
        dollarMintCalculatorAddress = _dollarMintCalculatorAddress;
    }

    function setExcessDollarsDistributor(
        address creditNFTManagerAddress,
        address dollarMintExcess
    ) external onlyAdmin {
        _excessDollarDistributors[creditNFTManagerAddress] = dollarMintExcess;
    }

    function setMasterChefAddress(address _masterChefAddress)
        external
        onlyAdmin
    {
        masterChefAddress = _masterChefAddress;
    }

    function setFormulasAddress(address _formulasAddress) external onlyAdmin {
        formulasAddress = _formulasAddress;
    }

    function setStakingShareAddress(address _stakingShareAddress)
        external
        onlyAdmin
    {
        stakingShareAddress = _stakingShareAddress;
    }

    function setStableSwapMetaPoolAddress(address _stableSwapMetaPoolAddress)
        external
        onlyAdmin
    {
        stableSwapMetaPoolAddress = _stableSwapMetaPoolAddress;
    }

    /**
     * @notice set the staking smart contract address
     * @dev staking contract participants deposit  curve LP token
     * for a certain duration to earn Governance Tokens and more curve LP token
     * @param _stakingContractAddress staking contract address
     */
    function setStakingContractAddress(address _stakingContractAddress)
        external
        onlyAdmin
    {
        stakingContractAddress = _stakingContractAddress;
    }

    /**
     * @notice set the treasury address
     * @dev the treasury fund is used to maintain the protocol
     * @param _treasuryAddress treasury fund address
     */
    function setTreasuryAddress(address _treasuryAddress) external onlyAdmin {
        treasuryAddress = _treasuryAddress;
    }

    /**
     * @notice deploy a new Curve metapools for Dollar Token Dollar/3Pool
     * @dev  From the curve documentation for uncollateralized algorithmic
     * stablecoins amplification should be 5-10
     * @param _curveFactory MetaPool factory address
     * @param _crvBasePool Address of the base pool to use within the new metapool.
     * @param _crv3PoolTokenAddress curve 3Pool token Address
     * @param _amplificationCoefficient amplification coefficient. The smaller
     * it is the closer to a constant product we are.
     * @param _fee Trade fee, given as an integer with 1e10 precision.
     */
    function deployStableSwapPool(
        address _curveFactory,
        address _crvBasePool,
        address _crv3PoolTokenAddress,
        uint256 _amplificationCoefficient,
        uint256 _fee
    ) external onlyAdmin {
        // Create new StableSwap meta pool (uAD <-> 3Crv)
        address metaPool = ICurveFactory(_curveFactory).deploy_metapool(
            _crvBasePool,
            ERC20(dollarTokenAddress).name(),
            ERC20(dollarTokenAddress).symbol(),
            dollarTokenAddress,
            _amplificationCoefficient,
            _fee
        );
        stableSwapMetaPoolAddress = metaPool;

        // Approve the newly-deployed meta pool to transfer this contract's funds
        uint256 crv3PoolTokenAmount =
            IERC20(_crv3PoolTokenAddress).balanceOf(address(this));
        uint256 dollarTokenAmount =
            IERC20(dollarTokenAddress).balanceOf(address(this));

        // safe approve revert if approve from non-zero to non-zero allowance
        IERC20(_crv3PoolTokenAddress).safeApprove(metaPool, 0);
        IERC20(_crv3PoolTokenAddress).safeApprove(metaPool, crv3PoolTokenAmount);

        IERC20(dollarTokenAddress).safeApprove(metaPool, 0);
        IERC20(dollarTokenAddress).safeApprove(metaPool, dollarTokenAmount);

        // coin at index 0 is Ubiquity Dollar and index 1 is 3CRV
        require(
            IMetaPool(metaPool).coins(0) == dollarTokenAddress
                && IMetaPool(metaPool).coins(1) == _crv3PoolTokenAddress,
            "MGR: COIN_ORDER_MISMATCH"
        );
        // Add the initial liquidity to the StableSwap meta pool
        uint256[2] memory amounts = [
            IERC20(dollarTokenAddress).balanceOf(address(this)),
            IERC20(_crv3PoolTokenAddress).balanceOf(address(this))
        ];

        // set curve 3Pool address
        curve3PoolTokenAddress = _crv3PoolTokenAddress;
        IMetaPool(metaPool).add_liquidity(amounts, 0, msg.sender);
    }

    function getExcessDollarsDistributor(address _creditNFTManagerAddress)
        external
        view
        returns (address)
    {
        return _excessDollarDistributors[_creditNFTManagerAddress];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../interfaces/IIncentive.sol";
import "../ERC20Ubiquity.sol";

contract UbiquityDollarToken is ERC20Ubiquity {
    /// @notice get associated incentive contract, 0 address if N/A
    mapping(address => address) public incentiveContract;

    event IncentiveContractUpdate(
        address indexed _incentivized, address indexed _incentiveContract
    );

    constructor(address _manager)
        ERC20Ubiquity(_manager, "Ubiquity Algorithmic Dollar", "uAD")
    {} // solhint-disable-line no-empty-blocks

    /// @param account the account to incentivize
    /// @param incentive the associated incentive contract
    /// @notice only Ubiquity Dollar manager can set Incentive contract
    function setIncentiveContract(address account, address incentive)
        external
    {
        require(
            ERC20Ubiquity.manager.hasRole(
                ERC20Ubiquity.manager.GOVERNANCE_TOKEN_MANAGER_ROLE(),
                msg.sender
            ),
            "Dollar: must have admin role"
        );

        incentiveContract[account] = incentive;
        emit IncentiveContractUpdate(account, incentive);
    }

    function _checkAndApplyIncentives(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        // incentive on sender
        address senderIncentive = incentiveContract[sender];
        if (senderIncentive != address(0)) {
            IIncentive(senderIncentive).incentivize(
                sender, recipient, msg.sender, amount
            );
        }

        // incentive on recipient
        address recipientIncentive = incentiveContract[recipient];
        if (recipientIncentive != address(0)) {
            IIncentive(recipientIncentive).incentivize(
                sender, recipient, msg.sender, amount
            );
        }

        // incentive on operator
        address operatorIncentive = incentiveContract[msg.sender];
        if (
            msg.sender != sender && msg.sender != recipient
                && operatorIncentive != address(0)
        ) {
            IIncentive(operatorIncentive).incentivize(
                sender, recipient, msg.sender, amount
            );
        }

        // all incentive, if active applies to every transfer
        address allIncentive = incentiveContract[address(0)];
        if (allIncentive != address(0)) {
            IIncentive(allIncentive).incentivize(
                sender, recipient, msg.sender, amount
            );
        }
    }

    function _transfer(address sender, address recipient, uint256 amount)
        internal
        override
    {
        super._transfer(sender, recipient, amount);
        _checkAndApplyIncentives(sender, recipient, amount);
    }
}

// SPDX-License-Identifier: MIT
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol. SEE BELOW FOR SOURCE. !!
pragma solidity ^0.8.3;

interface ICurveFactory {
    event BasePoolAdded(address base_pool, address implementat);
    event MetaPoolDeployed(
        address coin,
        address base_pool,
        uint256 A,
        uint256 fee,
        address deployer
    );

    function find_pool_for_coins(address _from, address _to)
        external
        view
        returns (address);

    function find_pool_for_coins(address _from, address _to, uint256 i)
        external
        view
        returns (address);

    function get_n_coins(address _pool)
        external
        view
        returns (uint256, uint256);

    function get_coins(address _pool)
        external
        view
        returns (address[2] memory);

    function get_underlying_coins(address _pool)
        external
        view
        returns (address[8] memory);

    function get_decimals(address _pool)
        external
        view
        returns (uint256[2] memory);

    function get_underlying_decimals(address _pool)
        external
        view
        returns (uint256[8] memory);

    function get_rates(address _pool)
        external
        view
        returns (uint256[2] memory);

    function get_balances(address _pool)
        external
        view
        returns (uint256[2] memory);

    function get_underlying_balances(address _pool)
        external
        view
        returns (uint256[8] memory);

    function get_A(address _pool) external view returns (uint256);

    function get_fees(address _pool) external view returns (uint256, uint256);

    function get_admin_balances(address _pool)
        external
        view
        returns (uint256[2] memory);

    function get_coin_indices(address _pool, address _from, address _to)
        external
        view
        returns (int128, int128, bool);

    function add_base_pool(
        address _base_pool,
        address _metapool_implementation,
        address _fee_receiver
    ) external;

    function deploy_metapool(
        address _base_pool,
        string memory _name,
        string memory _symbol,
        address _coin,
        uint256 _A,
        uint256 _fee
    ) external returns (address);

    function commit_transfer_ownership(address addr) external;

    function accept_transfer_ownership() external;

    function set_fee_receiver(address _base_pool, address _fee_receiver)
        external;

    function convert_fees() external returns (bool);

    function admin() external view returns (address);

    function future_admin() external view returns (address);

    function pool_list(uint256 arg0) external view returns (address);

    function pool_count() external view returns (uint256);

    function base_pool_list(uint256 arg0) external view returns (address);

    function base_pool_count() external view returns (uint256);

    function fee_receiver(address arg0) external view returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @title ERC1155 Ubiquity preset interface
/// @author Ubiquity DAO
interface IERC1155Ubiquity is IERC1155 {
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    function burn(address account, uint256 id, uint256 value) external;

    function burnBatch(address account, uint256[] memory ids, uint256[] memory values) external;

    function pause() external;

    function unpause() external;

    function totalSupply() external view returns (uint256);

    function exists(uint256 id) external view returns (bool);

    function holderTokens(address holder) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title ERC20 Ubiquity preset interface
/// @author Ubiquity DAO
interface IERC20Ubiquity is IERC20 {
    // ----------- Events -----------
    event Minting(
        address indexed _to, address indexed _minter, uint256 _amount
    );

    event Burning(address indexed _burned, uint256 _amount);

    // ----------- State changing api -----------
    function burn(uint256 amount) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // ----------- Burner only state changing api -----------
    function burnFrom(address account, uint256 amount) external;

    // ----------- Minter only state changing api -----------
    function mint(address account, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

/// @title incentive contract interface
/// @notice Called by Ubiquity Dollar token contract when transferring with an incentivized address
/// @dev should be appointed as a Minter or Burner as needed
interface IIncentive {
    /// @notice apply incentives on transfer
    /// @param sender the sender address of Ubiquity Dollar
    /// @param receiver the receiver address of Ubiquity Dollar
    /// @param operator the operator (msg.sender) of the transfer
    /// @param amount the amount of Ubiquity Dollar transferred
    function incentivize(
        address sender,
        address receiver,
        address operator,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol. SEE BELOW FOR SOURCE. !!
pragma solidity ^0.8.3;

interface IMetaPool {
    event Transfer(
        address indexed sender, address indexed receiver, uint256 value
    );
    event Approval(
        address indexed owner, address indexed spender, uint256 value
    );
    event TokenExchange(
        address indexed buyer,
        int128 sold_id,
        uint256 tokens_sold,
        int128 bought_id,
        uint256 tokens_bought
    );
    event TokenExchangeUnderlying(
        address indexed buyer,
        int128 sold_id,
        uint256 tokens_sold,
        int128 bought_id,
        uint256 tokens_bought
    );
    event AddLiquidity(
        address indexed provider,
        uint256[2] token_amounts,
        uint256[2] fees,
        uint256 invariant,
        uint256 token_supply
    );
    event RemoveLiquidity(
        address indexed provider,
        uint256[2] token_amounts,
        uint256[2] fees,
        uint256 token_supply
    );
    event RemoveLiquidityOne(
        address indexed provider,
        uint256 token_amount,
        uint256 coin_amount,
        uint256 token_supply
    );
    event RemoveLiquidityImbalance(
        address indexed provider,
        uint256[2] token_amounts,
        uint256[2] fees,
        uint256 invariant,
        uint256 token_supply
    );
    event CommitNewAdmin(uint256 indexed deadline, address indexed admin);
    event NewAdmin(address indexed admin);
    event CommitNewFee(
        uint256 indexed deadline, uint256 fee, uint256 admin_fee
    );
    event NewFee(uint256 fee, uint256 admin_fee);
    event RampA(
        uint256 old_A, uint256 new_A, uint256 initial_time, uint256 future_time
    );
    event StopRampA(uint256 A, uint256 t);

    function initialize(
        string memory _name,
        string memory _symbol,
        address _coin,
        uint256 _decimals,
        uint256 _A,
        uint256 _fee,
        address _admin
    ) external;

    function decimals() external view returns (uint256);

    function transfer(address _to, uint256 _value) external returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
        external
        returns (bool);

    function approve(address _spender, uint256 _value)
        external
        returns (bool);

    function get_previous_balances()
        external
        view
        returns (uint256[2] memory);

    function get_balances() external view returns (uint256[2] memory);

    function get_twap_balances(
        uint256[2] memory _first_balances,
        uint256[2] memory _last_balances,
        uint256 _time_elapsed
    ) external view returns (uint256[2] memory);

    function get_price_cumulative_last()
        external
        view
        returns (uint256[2] memory);

    function admin_fee() external view returns (uint256);

    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function calc_token_amount(uint256[2] memory _amounts, bool _is_deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(
        uint256[2] memory _amounts,
        bool _is_deposit,
        bool _previous
    ) external view returns (uint256);

    function add_liquidity(
        uint256[2] memory _amounts,
        uint256 _min_mint_amount,
        address _receiver
    ) external returns (uint256);

    function get_dy(int128 i, int128 j, uint256 dx)
        external
        view
        returns (uint256);

    function get_dy(int128 i, int128 j, uint256 dx, uint256[2] memory _balances)
        external
        view
        returns (uint256);

    function get_dy_underlying(int128 i, int128 j, uint256 dx)
        external
        view
        returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256[2] memory _balances
    ) external view returns (uint256);

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy)
        external
        returns (uint256);

    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy)
        external
        returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy,
        address _receiver
    ) external returns (uint256);

    function remove_liquidity(
        uint256 _burn_amount,
        uint256[2] memory _min_amounts
    ) external returns (uint256[2] memory);

    function remove_liquidity(
        uint256 _burn_amount,
        uint256[2] memory _min_amounts,
        address _receiver
    ) external returns (uint256[2] memory);

    function remove_liquidity_imbalance(
        uint256[2] memory _amounts,
        uint256 _max_burn_amount
    ) external returns (uint256);

    function remove_liquidity_imbalance(
        uint256[2] memory _amounts,
        uint256 _max_burn_amount,
        address _receiver
    ) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(
        uint256 _burn_amount,
        int128 i,
        bool _previous
    ) external view returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received
    ) external returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received,
        address _receiver
    ) external returns (uint256);

    function ramp_A(uint256 _future_A, uint256 _future_time) external;

    function stop_ramp_A() external;

    function admin_balances(uint256 i) external view returns (uint256);

    function withdraw_admin_fees() external;

    function admin() external view returns (address);

    function coins(uint256 arg0) external view returns (address);

    function balances(uint256 arg0) external view returns (uint256);

    function fee() external view returns (uint256);

    function block_timestamp_last() external view returns (uint256);

    function initial_A() external view returns (uint256);

    function future_A() external view returns (uint256);

    function initial_A_time() external view returns (uint256);

    function future_A_time() external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address arg0) external view returns (uint256);

    function allowance(address arg0, address arg1)
        external
        view
        returns (uint256);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol. SEE BELOW FOR SOURCE. !!
pragma solidity ^0.8.3;

interface ISablier {
    event CreateCompoundingStream(
        uint256 indexed streamId,
        uint256 exchangeRate,
        uint256 senderSharePercentage,
        uint256 recipientSharePercentage
    );
    event PayInterest(
        uint256 indexed streamId,
        uint256 senderInterest,
        uint256 recipientInterest,
        uint256 sablierInterest
    );
    event TakeEarnings(address indexed tokenAddress, uint256 indexed amount);
    event UpdateFee(uint256 indexed fee);
    event Paused(address account);
    event Unpaused(address account);
    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);
    event OwnershipTransferred(
        address indexed previousOwner, address indexed newOwner
    );
    event CreateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    );
    event WithdrawFromStream(
        uint256 indexed streamId, address indexed recipient, uint256 amount
    );
    event CancelStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 senderBalance,
        uint256 recipientBalance
    );

    function unpause() external;

    function cancelStream(uint256 streamId) external returns (bool);

    function withdrawFromStream(uint256 streamId, uint256 amount)
        external
        returns (bool);

    function initialize() external;

    function createCompoundingStream(
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime,
        uint256 senderSharePercentage,
        uint256 recipientSharePercentage
    ) external returns (uint256);

    function addPauser(address account) external;

    function pause() external;

    function interestOf(uint256 streamId, uint256 amount)
        external
        returns (
            uint256 senderInterest,
            uint256 recipientInterest,
            uint256 sablierInterest
        );

    function updateFee(uint256 feePercentage) external;

    function takeEarnings(address tokenAddress, uint256 amount) external;

    function initialize(address sender) external;

    function createStream(
        address recipient,
        uint256 deposit,
        address tokenAddress,
        uint256 startTime,
        uint256 stopTime
    ) external returns (uint256);

    function transferOwnership(address newOwner) external;

    function getEarnings(address tokenAddress)
        external
        view
        returns (uint256);

    function nextStreamId() external view returns (uint256);

    function getCompoundingStream(uint256 streamId)
        external
        view
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond,
            uint256 exchangeRateInitial,
            uint256 senderSharePercentage,
            uint256 recipientSharePercentage
        );

    function balanceOf(uint256 streamId, address who)
        external
        view
        returns (uint256 balance);

    function isPauser(address account) external view returns (bool);

    function paused() external view returns (bool);

    function getStream(uint256 streamId)
        external
        view
        returns (
            address sender,
            address recipient,
            uint256 deposit,
            address tokenAddress,
            uint256 startTime,
            uint256 stopTime,
            uint256 remainingBalance,
            uint256 ratePerSecond
        );

    function owner() external view returns (address);

    function isOwner() external view returns (bool);

    function isCompoundingStream(uint256 streamId)
        external
        view
        returns (bool);

    function deltaOf(uint256 streamId) external view returns (uint256 delta);

    function cTokenManager() external view returns (address);

    function fee() external view returns (uint256 mantissa);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface ITWAPOracleDollar3pool {
    function update() external;

    function consult(address token) external view returns (uint256 amountOut);
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol. SEE BELOW FOR SOURCE. !!
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../UbiquityChef.sol";

interface IUbiquityChef {
    struct StakingShareInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct PoolInfo {
        uint256 lastRewardBlock; // Last block number that Governance Token distribution occurs.
        uint256 accGovernancePerShare; // Accumulated Governance Token per share, times 1e12. See below.
    }

    event Deposit(address indexed user, uint256 amount, uint256 stakingShareID);
    event Withdraw(
        address indexed user, uint256 amount, uint256 stakingShareID
    );

    function deposit(address sender, uint256 amount, uint256 stakingShareID)
        external;

    // Withdraw LP tokens from MasterChef.
    function withdraw(address sender, uint256 amount, uint256 stakingShareID)
        external;

    // Info about a staking share
    function getStakingShareInfo(uint256 _id)
        external
        view
        returns (uint256[2] memory);

    // Total amount of shares
    function totalShares() external view returns (uint256);

    // View function to see pending Governance Tokens on frontend.
    function pendingGovernance(address _user) external view returns (uint256);
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "./IERC20Ubiquity.sol";

/// @title Ubiquity Dollar stablecoin interface
/// @author Ubiquity DAO
interface IUbiquityDollarToken is IERC20Ubiquity {
    event IncentiveContractUpdate(
        address indexed _incentivized, address indexed _incentiveContract
    );

    function setIncentiveContract(address account, address incentive)
        external;

    function incentiveContract(address account)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IUbiquityFormulas {
    function durationMultiply(uint256 _uLP, uint256 _weeks, uint256 _multiplier)
        external
        pure
        returns (uint256 _shares);

    function bonding(
        uint256 _shares,
        uint256 _currentShareValue,
        uint256 _targetPrice
    ) external pure returns (uint256 _uBOND);

    function redeemBonds(
        uint256 _uBOND,
        uint256 _currentShareValue,
        uint256 _targetPrice
    ) external pure returns (uint256 _uLP);

    function bondPrice(
        uint256 _totalULP,
        uint256 _totalUBOND,
        uint256 _targetPrice
    ) external pure returns (uint256 _priceUBOND);

    function governanceMultiply(uint256 _multiplier, uint256 _price)
        external
        pure
        returns (uint256 _newMultiplier);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface ICollectableDust {
    event DustSent(address _to, address token, uint256 amount);
    event ProtocolTokenAdded(address _token);
    event ProtocolTokenRemoved(address _token);

    function addProtocolToken(address _token) external;

    function removeProtocolToken(address _token) external;

    function sendDust(address _to, address _token, uint256 _amount) external;
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math Quad Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with IEEE 754
 * quadruple-precision binary floating-point numbers (quadruple precision
 * numbers).  As long as quadruple precision numbers are 16-bytes long, they are
 * represented by bytes16 type.
 */
library ABDKMathQuad {
    /*
     * 0.
     */
    bytes16 private constant _POSITIVE_ZERO = 0x00000000000000000000000000000000;

    /*
     * -0.
     */
    bytes16 private constant _NEGATIVE_ZERO = 0x80000000000000000000000000000000;

    /*
     * +Infinity.
     */
    bytes16 private constant _POSITIVE_INFINITY =
        0x7FFF0000000000000000000000000000;

    /*
     * -Infinity.
     */
    bytes16 private constant _NEGATIVE_INFINITY =
        0xFFFF0000000000000000000000000000;

    /*
     * Canonical NaN value.
     */
    bytes16 private constant NaN = 0x7FFF8000000000000000000000000000;

    /**
     * Convert signed 256-bit integer number into quadruple precision number.
     *
     * @param x signed 256-bit integer number
     * @return quadruple precision number
     */
    function fromInt(int256 x) internal pure returns (bytes16) {
        unchecked {
            if (x == 0) {
                return bytes16(0);
            } else {
                // We rely on overflow behavior here
                uint256 result = uint256(x > 0 ? x : -x);

                uint256 msb = mostSignificantBit(result);
                if (msb < 112) {
                    result <<= 112 - msb;
                } else if (msb > 112) {
                    result >>= msb - 112;
                }

                result = (result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                    | ((16383 + msb) << 112);
                if (x < 0) {
                    result |= 0x80000000000000000000000000000000;
                }

                return bytes16(uint128(result));
            }
        }
    }

    /**
     * Convert quadruple precision number into signed 256-bit integer number
     * rounding towards zero.  Revert on overflow.
     *
     * @param x quadruple precision number
     * @return signed 256-bit integer number
     */
    function toInt(bytes16 x) internal pure returns (int256) {
        unchecked {
            uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

            require(exponent <= 16638); // Overflow
            if (exponent < 16383) {
                return 0;
            } // Underflow

            uint256 result = (
                uint256(uint128(x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            ) | 0x10000000000000000000000000000;

            if (exponent < 16495) {
                result >>= 16495 - exponent;
            } else if (exponent > 16495) {
                result <<= exponent - 16495;
            }

            if (uint128(x) >= 0x80000000000000000000000000000000) {
                // Negative
                require(
                    result
                        <=
                        0x8000000000000000000000000000000000000000000000000000000000000000
                );
                return -int256(result); // We rely on overflow behavior here
            } else {
                require(
                    result
                        <=
                        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                );
                return int256(result);
            }
        }
    }

    /**
     * Convert unsigned 256-bit integer number into quadruple precision number.
     *
     * @param x unsigned 256-bit integer number
     * @return quadruple precision number
     */
    function fromUInt(uint256 x) internal pure returns (bytes16) {
        unchecked {
            if (x == 0) {
                return bytes16(0);
            } else {
                uint256 result = x;

                uint256 msb = mostSignificantBit(result);
                if (msb < 112) {
                    result <<= 112 - msb;
                } else if (msb > 112) {
                    result >>= msb - 112;
                }

                result = (result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                    | ((16383 + msb) << 112);

                return bytes16(uint128(result));
            }
        }
    }

    /**
     * Convert quadruple precision number into unsigned 256-bit integer number
     * rounding towards zero.  Revert on underflow.  Note, that negative floating
     * point numbers in range (-1.0 .. 0.0) may be converted to unsigned integer
     * without error, because they are rounded to zero.
     *
     * @param x quadruple precision number
     * @return unsigned 256-bit integer number
     */
    function toUInt(bytes16 x) internal pure returns (uint256) {
        unchecked {
            uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

            if (exponent < 16383) {
                return 0;
            } // Underflow

            require(uint128(x) < 0x80000000000000000000000000000000); // Negative

            require(exponent <= 16638); // Overflow
            uint256 result = (
                uint256(uint128(x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            ) | 0x10000000000000000000000000000;

            if (exponent < 16495) {
                result >>= 16495 - exponent;
            } else if (exponent > 16495) {
                result <<= exponent - 16495;
            }

            return result;
        }
    }

    /**
     * Convert signed 128.128 bit fixed point number into quadruple precision
     * number.
     *
     * @param x signed 128.128 bit fixed point number
     * @return quadruple precision number
     */
    function from128x128(int256 x) internal pure returns (bytes16) {
        unchecked {
            if (x == 0) {
                return bytes16(0);
            } else {
                // We rely on overflow behavior here
                uint256 result = uint256(x > 0 ? x : -x);

                uint256 msb = mostSignificantBit(result);
                if (msb < 112) {
                    result <<= 112 - msb;
                } else if (msb > 112) {
                    result >>= msb - 112;
                }

                result = (result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                    | ((16255 + msb) << 112);
                if (x < 0) {
                    result |= 0x80000000000000000000000000000000;
                }

                return bytes16(uint128(result));
            }
        }
    }

    /**
     * Convert quadruple precision number into signed 128.128 bit fixed point
     * number.  Revert on overflow.
     *
     * @param x quadruple precision number
     * @return signed 128.128 bit fixed point number
     */
    function to128x128(bytes16 x) internal pure returns (int256) {
        unchecked {
            uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

            require(exponent <= 16510); // Overflow
            if (exponent < 16255) {
                return 0;
            } // Underflow

            uint256 result = (
                uint256(uint128(x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            ) | 0x10000000000000000000000000000;

            if (exponent < 16367) {
                result >>= 16367 - exponent;
            } else if (exponent > 16367) {
                result <<= exponent - 16367;
            }

            if (uint128(x) >= 0x80000000000000000000000000000000) {
                // Negative
                require(
                    result
                        <=
                        0x8000000000000000000000000000000000000000000000000000000000000000
                );
                return -int256(result); // We rely on overflow behavior here
            } else {
                require(
                    result
                        <=
                        0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                );
                return int256(result);
            }
        }
    }

    /**
     * Convert signed 64.64 bit fixed point number into quadruple precision
     * number.
     *
     * @param x signed 64.64 bit fixed point number
     * @return quadruple precision number
     */
    function from64x64(int128 x) internal pure returns (bytes16) {
        unchecked {
            if (x == 0) {
                return bytes16(0);
            } else {
                // We rely on overflow behavior here
                uint256 result = uint128(x > 0 ? x : -x);

                uint256 msb = mostSignificantBit(result);
                if (msb < 112) {
                    result <<= 112 - msb;
                } else if (msb > 112) {
                    result >>= msb - 112;
                }

                result = (result & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                    | ((16319 + msb) << 112);
                if (x < 0) {
                    result |= 0x80000000000000000000000000000000;
                }

                return bytes16(uint128(result));
            }
        }
    }

    /**
     * Convert quadruple precision number into signed 64.64 bit fixed point
     * number.  Revert on overflow.
     *
     * @param x quadruple precision number
     * @return signed 64.64 bit fixed point number
     */
    function to64x64(bytes16 x) internal pure returns (int128) {
        unchecked {
            uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

            require(exponent <= 16446); // Overflow
            if (exponent < 16319) {
                return 0;
            } // Underflow

            uint256 result = (
                uint256(uint128(x)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF
            ) | 0x10000000000000000000000000000;

            if (exponent < 16431) {
                result >>= 16431 - exponent;
            } else if (exponent > 16431) {
                result <<= exponent - 16431;
            }

            if (uint128(x) >= 0x80000000000000000000000000000000) {
                // Negative
                require(result <= 0x80000000000000000000000000000000);
                return -int128(int256(result)); // We rely on overflow behavior here
            } else {
                require(result <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                return int128(int256(result));
            }
        }
    }

    /**
     * Convert octuple precision number into quadruple precision number.
     *
     * @param x octuple precision number
     * @return quadruple precision number
     */
    function fromOctuple(bytes32 x) internal pure returns (bytes16) {
        unchecked {
            bool negative = x
                & 0x8000000000000000000000000000000000000000000000000000000000000000
                > 0;

            uint256 exponent = (uint256(x) >> 236) & 0x7FFFF;
            uint256 significand = uint256(x)
                & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (exponent == 0x7FFFF) {
                if (significand > 0) {
                    return NaN;
                } else {
                    return negative ? _NEGATIVE_INFINITY : _POSITIVE_INFINITY;
                }
            }

            if (exponent > 278526) {
                return negative ? _NEGATIVE_INFINITY : _POSITIVE_INFINITY;
            } else if (exponent < 245649) {
                return negative ? _NEGATIVE_ZERO : _POSITIVE_ZERO;
            } else if (exponent < 245761) {
                significand = (
                    significand
                        |
                        0x100000000000000000000000000000000000000000000000000000000000
                ) >> (245885 - exponent);
                exponent = 0;
            } else {
                significand >>= 124;
                exponent -= 245760;
            }

            uint128 result = uint128(significand | (exponent << 112));
            if (negative) {
                result |= 0x80000000000000000000000000000000;
            }

            return bytes16(result);
        }
    }

    /**
     * Convert quadruple precision number into octuple precision number.
     *
     * @param x quadruple precision number
     * @return octuple precision number
     */
    function toOctuple(bytes16 x) internal pure returns (bytes32) {
        unchecked {
            uint256 exponent = (uint128(x) >> 112) & 0x7FFF;

            uint256 result = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (exponent == 0x7FFF) {
                exponent = 0x7FFFF;
            } // Infinity or NaN
            else if (exponent == 0) {
                if (result > 0) {
                    uint256 msb = mostSignificantBit(result);
                    result = (result << (236 - msb))
                        &
                        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    exponent = 245649 + msb;
                }
            } else {
                result <<= 124;
                exponent += 245760;
            }

            result |= exponent << 236;
            if (uint128(x) >= 0x80000000000000000000000000000000) {
                result |=
                    0x8000000000000000000000000000000000000000000000000000000000000000;
            }

            return bytes32(result);
        }
    }

    /**
     * Convert double precision number into quadruple precision number.
     *
     * @param x double precision number
     * @return quadruple precision number
     */
    function fromDouble(bytes8 x) internal pure returns (bytes16) {
        unchecked {
            uint256 exponent = (uint64(x) >> 52) & 0x7FF;

            uint256 result = uint64(x) & 0xFFFFFFFFFFFFF;

            if (exponent == 0x7FF) {
                exponent = 0x7FFF;
            } // Infinity or NaN
            else if (exponent == 0) {
                if (result > 0) {
                    uint256 msb = mostSignificantBit(result);
                    result =
                        (result << (112 - msb)) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    exponent = 15309 + msb;
                }
            } else {
                result <<= 60;
                exponent += 15360;
            }

            result |= exponent << 112;
            if (x & 0x8000000000000000 > 0) {
                result |= 0x80000000000000000000000000000000;
            }

            return bytes16(uint128(result));
        }
    }

    /**
     * Convert quadruple precision number into double precision number.
     *
     * @param x quadruple precision number
     * @return double precision number
     */
    function toDouble(bytes16 x) internal pure returns (bytes8) {
        unchecked {
            bool negative = uint128(x) >= 0x80000000000000000000000000000000;

            uint256 exponent = (uint128(x) >> 112) & 0x7FFF;
            uint256 significand = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (exponent == 0x7FFF) {
                if (significand > 0) {
                    return 0x7FF8000000000000;
                }
                // NaN
                else {
                    return negative
                        ? bytes8(0xFFF0000000000000) // -Infinity
                        : bytes8(0x7FF0000000000000);
                } // Infinity
            }

            if (exponent > 17406) {
                return negative
                    ? bytes8(0xFFF0000000000000) // -Infinity
                    : bytes8(0x7FF0000000000000);
            }
            // Infinity
            else if (exponent < 15309) {
                return negative
                    ? bytes8(0x8000000000000000) // -0
                    : bytes8(0x0000000000000000);
            }
            // 0
            else if (exponent < 15361) {
                significand = (significand | 0x10000000000000000000000000000)
                    >> (15421 - exponent);
                exponent = 0;
            } else {
                significand >>= 60;
                exponent -= 15360;
            }

            uint64 result = uint64(significand | (exponent << 52));
            if (negative) {
                result |= 0x8000000000000000;
            }

            return bytes8(result);
        }
    }

    /**
     * Test whether given quadruple precision number is NaN.
     *
     * @param x quadruple precision number
     * @return true if x is NaN, false otherwise
     */
    function isNaN(bytes16 x) internal pure returns (bool) {
        unchecked {
            return uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                > 0x7FFF0000000000000000000000000000;
        }
    }

    /**
     * Test whether given quadruple precision number is positive or negative
     * infinity.
     *
     * @param x quadruple precision number
     * @return true if x is positive or negative infinity, false otherwise
     */
    function isInfinity(bytes16 x) internal pure returns (bool) {
        unchecked {
            return uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                == 0x7FFF0000000000000000000000000000;
        }
    }

    /**
     * Calculate sign of x, i.e. -1 if x is negative, 0 if x if zero, and 1 if x
     * is positive.  Note that sign (-0) is zero.  Revert if x is NaN.
     *
     * @param x quadruple precision number
     * @return sign of x
     */
    function sign(bytes16 x) internal pure returns (int8) {
        unchecked {
            uint128 absoluteX = uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            require(absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

            if (absoluteX == 0) {
                return 0;
            } else if (uint128(x) >= 0x80000000000000000000000000000000) {
                return -1;
            } else {
                return 1;
            }
        }
    }

    /**
     * Calculate sign (x - y).  Revert if either argument is NaN, or both
     * arguments are infinities of the same sign.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return sign (x - y)
     */
    function cmp(bytes16 x, bytes16 y) internal pure returns (int8) {
        unchecked {
            uint128 absoluteX = uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            require(absoluteX <= 0x7FFF0000000000000000000000000000); // Not NaN

            uint128 absoluteY = uint128(y) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            require(absoluteY <= 0x7FFF0000000000000000000000000000); // Not NaN

            // Not infinities of the same sign
            require(x != y || absoluteX < 0x7FFF0000000000000000000000000000);

            if (x == y) {
                return 0;
            } else {
                bool negativeX =
                    uint128(x) >= 0x80000000000000000000000000000000;
                bool negativeY =
                    uint128(y) >= 0x80000000000000000000000000000000;

                if (negativeX) {
                    if (negativeY) {
                        return absoluteX > absoluteY ? -1 : int8(1);
                    } else {
                        return -1;
                    }
                } else {
                    if (negativeY) {
                        return 1;
                    } else {
                        return absoluteX > absoluteY ? int8(1) : -1;
                    }
                }
            }
        }
    }

    /**
     * Test whether x equals y.  NaN, infinity, and -infinity are not equal to
     * anything.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return true if x equals to y, false otherwise
     */
    function eq(bytes16 x, bytes16 y) internal pure returns (bool) {
        unchecked {
            if (x == y) {
                return uint128(x) & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                    < 0x7FFF0000000000000000000000000000;
            } else {
                return false;
            }
        }
    }

    /**
     * Calculate x + y.  Special values behave in the following way:
     *
     * NaN + x = NaN for any x.
     * Infinity + x = Infinity for any finite x.
     * -Infinity + x = -Infinity for any finite x.
     * Infinity + Infinity = Infinity.
     * -Infinity + -Infinity = -Infinity.
     * Infinity + -Infinity = -Infinity + Infinity = NaN.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function add(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        unchecked {
            uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
            uint256 yExponent = (uint128(y) >> 112) & 0x7FFF;

            if (xExponent == 0x7FFF) {
                if (yExponent == 0x7FFF) {
                    if (x == y) {
                        return x;
                    } else {
                        return NaN;
                    }
                } else {
                    return x;
                }
            } else if (yExponent == 0x7FFF) {
                return y;
            } else {
                bool xSign = uint128(x) >= 0x80000000000000000000000000000000;
                uint256 xSignifier = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xExponent == 0) {
                    xExponent = 1;
                } else {
                    xSignifier |= 0x10000000000000000000000000000;
                }

                bool ySign = uint128(y) >= 0x80000000000000000000000000000000;
                uint256 ySignifier = uint128(y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (yExponent == 0) {
                    yExponent = 1;
                } else {
                    ySignifier |= 0x10000000000000000000000000000;
                }

                if (xSignifier == 0) {
                    return y == _NEGATIVE_ZERO ? _POSITIVE_ZERO : y;
                } else if (ySignifier == 0) {
                    return x == _NEGATIVE_ZERO ? _POSITIVE_ZERO : x;
                } else {
                    int256 delta = int256(xExponent) - int256(yExponent);

                    if (xSign == ySign) {
                        if (delta > 112) {
                            return x;
                        } else if (delta > 0) {
                            ySignifier >>= uint256(delta);
                        } else if (delta < -112) {
                            return y;
                        } else if (delta < 0) {
                            xSignifier >>= uint256(-delta);
                            xExponent = yExponent;
                        }

                        xSignifier += ySignifier;

                        if (xSignifier >= 0x20000000000000000000000000000) {
                            xSignifier >>= 1;
                            xExponent += 1;
                        }

                        if (xExponent == 0x7FFF) {
                            return xSign
                                ? _NEGATIVE_INFINITY
                                : _POSITIVE_INFINITY;
                        } else {
                            if (xSignifier < 0x10000000000000000000000000000) {
                                xExponent = 0;
                            } else {
                                xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                            }

                            return bytes16(
                                uint128(
                                    (
                                        xSign
                                            ? 0x80000000000000000000000000000000
                                            : 0
                                    ) | (xExponent << 112) | xSignifier
                                )
                            );
                        }
                    } else {
                        if (delta > 0) {
                            xSignifier <<= 1;
                            xExponent -= 1;
                        } else if (delta < 0) {
                            ySignifier <<= 1;
                            xExponent = yExponent - 1;
                        }

                        if (delta > 112) {
                            ySignifier = 1;
                        } else if (delta > 1) {
                            ySignifier =
                                ((ySignifier - 1) >> uint256(delta - 1)) + 1;
                        } else if (delta < -112) {
                            xSignifier = 1;
                        } else if (delta < -1) {
                            xSignifier =
                                ((xSignifier - 1) >> uint256(-delta - 1)) + 1;
                        }

                        if (xSignifier >= ySignifier) {
                            xSignifier -= ySignifier;
                        } else {
                            xSignifier = ySignifier - xSignifier;
                            xSign = ySign;
                        }

                        if (xSignifier == 0) {
                            return _POSITIVE_ZERO;
                        }

                        uint256 msb = mostSignificantBit(xSignifier);

                        if (msb == 113) {
                            xSignifier = (xSignifier >> 1)
                                & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                            xExponent += 1;
                        } else if (msb < 112) {
                            uint256 shift = 112 - msb;
                            if (xExponent > shift) {
                                xSignifier = (xSignifier << shift)
                                    & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                                xExponent -= shift;
                            } else {
                                xSignifier <<= xExponent - 1;
                                xExponent = 0;
                            }
                        } else {
                            xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                        }

                        if (xExponent == 0x7FFF) {
                            return xSign
                                ? _NEGATIVE_INFINITY
                                : _POSITIVE_INFINITY;
                        } else {
                            return bytes16(
                                uint128(
                                    (
                                        xSign
                                            ? 0x80000000000000000000000000000000
                                            : 0
                                    ) | (xExponent << 112) | xSignifier
                                )
                            );
                        }
                    }
                }
            }
        }
    }

    /**
     * Calculate x - y.  Special values behave in the following way:
     *
     * NaN - x = NaN for any x.
     * Infinity - x = Infinity for any finite x.
     * -Infinity - x = -Infinity for any finite x.
     * Infinity - -Infinity = Infinity.
     * -Infinity - Infinity = -Infinity.
     * Infinity - Infinity = -Infinity - -Infinity = NaN.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function sub(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        unchecked {
            return add(x, y ^ 0x80000000000000000000000000000000);
        }
    }

    /**
     * Calculate x * y.  Special values behave in the following way:
     *
     * NaN * x = NaN for any x.
     * Infinity * x = Infinity for any finite positive x.
     * Infinity * x = -Infinity for any finite negative x.
     * -Infinity * x = -Infinity for any finite positive x.
     * -Infinity * x = Infinity for any finite negative x.
     * Infinity * 0 = NaN.
     * -Infinity * 0 = NaN.
     * Infinity * Infinity = Infinity.
     * Infinity * -Infinity = -Infinity.
     * -Infinity * Infinity = -Infinity.
     * -Infinity * -Infinity = Infinity.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function mul(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        unchecked {
            uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
            uint256 yExponent = (uint128(y) >> 112) & 0x7FFF;

            if (xExponent == 0x7FFF) {
                if (yExponent == 0x7FFF) {
                    if (x == y) {
                        return x ^ (y & 0x80000000000000000000000000000000);
                    } else if (x ^ y == 0x80000000000000000000000000000000) {
                        return x | y;
                    } else {
                        return NaN;
                    }
                } else {
                    if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
                        return NaN;
                    } else {
                        return x ^ (y & 0x80000000000000000000000000000000);
                    }
                }
            } else if (yExponent == 0x7FFF) {
                if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
                    return NaN;
                } else {
                    return y ^ (x & 0x80000000000000000000000000000000);
                }
            } else {
                uint256 xSignifier = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xExponent == 0) {
                    xExponent = 1;
                } else {
                    xSignifier |= 0x10000000000000000000000000000;
                }

                uint256 ySignifier = uint128(y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (yExponent == 0) {
                    yExponent = 1;
                } else {
                    ySignifier |= 0x10000000000000000000000000000;
                }

                xSignifier *= ySignifier;
                if (xSignifier == 0) {
                    return (x ^ y) & 0x80000000000000000000000000000000 > 0
                        ? _NEGATIVE_ZERO
                        : _POSITIVE_ZERO;
                }

                xExponent += yExponent;

                uint256 msb = xSignifier
                    >= 0x200000000000000000000000000000000000000000000000000000000
                    ? 225
                    : xSignifier
                        >= 0x100000000000000000000000000000000000000000000000000000000
                        ? 224
                        : mostSignificantBit(xSignifier);

                if (xExponent + msb < 16496) {
                    // Underflow
                    xExponent = 0;
                    xSignifier = 0;
                } else if (xExponent + msb < 16608) {
                    // Subnormal
                    if (xExponent < 16496) {
                        xSignifier >>= 16496 - xExponent;
                    } else if (xExponent > 16496) {
                        xSignifier <<= xExponent - 16496;
                    }
                    xExponent = 0;
                } else if (xExponent + msb > 49373) {
                    xExponent = 0x7FFF;
                    xSignifier = 0;
                } else {
                    if (msb > 112) {
                        xSignifier >>= msb - 112;
                    } else if (msb < 112) {
                        xSignifier <<= 112 - msb;
                    }

                    xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                    xExponent = xExponent + msb - 16607;
                }

                return bytes16(
                    uint128(
                        uint128((x ^ y) & 0x80000000000000000000000000000000)
                            | (xExponent << 112) | xSignifier
                    )
                );
            }
        }
    }

    /**
     * Calculate x / y.  Special values behave in the following way:
     *
     * NaN / x = NaN for any x.
     * x / NaN = NaN for any x.
     * Infinity / x = Infinity for any finite non-negative x.
     * Infinity / x = -Infinity for any finite negative x including -0.
     * -Infinity / x = -Infinity for any finite non-negative x.
     * -Infinity / x = Infinity for any finite negative x including -0.
     * x / Infinity = 0 for any finite non-negative x.
     * x / -Infinity = -0 for any finite non-negative x.
     * x / Infinity = -0 for any finite non-negative x including -0.
     * x / -Infinity = 0 for any finite non-negative x including -0.
     *
     * Infinity / Infinity = NaN.
     * Infinity / -Infinity = -NaN.
     * -Infinity / Infinity = -NaN.
     * -Infinity / -Infinity = NaN.
     *
     * Division by zero behaves in the following way:
     *
     * x / 0 = Infinity for any finite positive x.
     * x / -0 = -Infinity for any finite positive x.
     * x / 0 = -Infinity for any finite negative x.
     * x / -0 = Infinity for any finite negative x.
     * 0 / 0 = NaN.
     * 0 / -0 = NaN.
     * -0 / 0 = NaN.
     * -0 / -0 = NaN.
     *
     * @param x quadruple precision number
     * @param y quadruple precision number
     * @return quadruple precision number
     */
    function div(bytes16 x, bytes16 y) internal pure returns (bytes16) {
        unchecked {
            uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
            uint256 yExponent = (uint128(y) >> 112) & 0x7FFF;

            if (xExponent == 0x7FFF) {
                if (yExponent == 0x7FFF) {
                    return NaN;
                } else {
                    return x ^ (y & 0x80000000000000000000000000000000);
                }
            } else if (yExponent == 0x7FFF) {
                if (y & 0x0000FFFFFFFFFFFFFFFFFFFFFFFFFFFF != 0) {
                    return NaN;
                } else {
                    return _POSITIVE_ZERO
                        | ((x ^ y) & 0x80000000000000000000000000000000);
                }
            } else if (y & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
                if (x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0) {
                    return NaN;
                } else {
                    return _POSITIVE_INFINITY
                        | ((x ^ y) & 0x80000000000000000000000000000000);
                }
            } else {
                uint256 ySignifier = uint128(y) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (yExponent == 0) {
                    yExponent = 1;
                } else {
                    ySignifier |= 0x10000000000000000000000000000;
                }

                uint256 xSignifier = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xExponent == 0) {
                    if (xSignifier != 0) {
                        uint256 shift = 226 - mostSignificantBit(xSignifier);

                        xSignifier <<= shift;

                        xExponent = 1;
                        yExponent += shift - 114;
                    }
                } else {
                    xSignifier =
                        (xSignifier | 0x10000000000000000000000000000) << 114;
                }

                xSignifier = xSignifier / ySignifier;
                if (xSignifier == 0) {
                    return (x ^ y) & 0x80000000000000000000000000000000 > 0
                        ? _NEGATIVE_ZERO
                        : _POSITIVE_ZERO;
                }

                assert(xSignifier >= 0x1000000000000000000000000000);

                uint256 msb = xSignifier >= 0x80000000000000000000000000000
                    ? mostSignificantBit(xSignifier)
                    : xSignifier >= 0x40000000000000000000000000000
                        ? 114
                        : xSignifier >= 0x20000000000000000000000000000 ? 113 : 112;

                if (xExponent + msb > yExponent + 16497) {
                    // Overflow
                    xExponent = 0x7FFF;
                    xSignifier = 0;
                } else if (xExponent + msb + 16380 < yExponent) {
                    // Underflow
                    xExponent = 0;
                    xSignifier = 0;
                } else if (xExponent + msb + 16268 < yExponent) {
                    // Subnormal
                    if (xExponent + 16380 > yExponent) {
                        xSignifier <<= xExponent + 16380 - yExponent;
                    } else if (xExponent + 16380 < yExponent) {
                        xSignifier >>= yExponent - xExponent - 16380;
                    }

                    xExponent = 0;
                } else {
                    // Normal
                    if (msb > 112) {
                        xSignifier >>= msb - 112;
                    }

                    xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

                    xExponent = xExponent + msb + 16269 - yExponent;
                }

                return bytes16(
                    uint128(
                        uint128((x ^ y) & 0x80000000000000000000000000000000)
                            | (xExponent << 112) | xSignifier
                    )
                );
            }
        }
    }

    /**
     * Calculate -x.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function neg(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            return x ^ 0x80000000000000000000000000000000;
        }
    }

    /**
     * Calculate |x|.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function abs(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            return x & 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
        }
    }

    /**
     * Calculate square root of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function sqrt(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            if (uint128(x) > 0x80000000000000000000000000000000) {
                return NaN;
            } else {
                uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
                if (xExponent == 0x7FFF) {
                    return x;
                } else {
                    uint256 xSignifier =
                        uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    if (xExponent == 0) {
                        xExponent = 1;
                    } else {
                        xSignifier |= 0x10000000000000000000000000000;
                    }

                    if (xSignifier == 0) {
                        return _POSITIVE_ZERO;
                    }

                    bool oddExponent = xExponent & 0x1 == 0;
                    xExponent = (xExponent + 16383) >> 1;

                    if (oddExponent) {
                        if (xSignifier >= 0x10000000000000000000000000000) {
                            xSignifier <<= 113;
                        } else {
                            uint256 msb = mostSignificantBit(xSignifier);
                            uint256 shift = (226 - msb) & 0xFE;
                            xSignifier <<= shift;
                            xExponent -= (shift - 112) >> 1;
                        }
                    } else {
                        if (xSignifier >= 0x10000000000000000000000000000) {
                            xSignifier <<= 112;
                        } else {
                            uint256 msb = mostSignificantBit(xSignifier);
                            uint256 shift = (225 - msb) & 0xFE;
                            xSignifier <<= shift;
                            xExponent -= (shift - 112) >> 1;
                        }
                    }

                    uint256 r = 0x10000000000000000000000000000;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1;
                    r = (r + xSignifier / r) >> 1; // Seven iterations should be enough
                    uint256 r1 = xSignifier / r;
                    if (r1 < r) {
                        r = r1;
                    }

                    return bytes16(
                        uint128(
                            (xExponent << 112)
                                | (r & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                        )
                    );
                }
            }
        }
    }

    /**
     * Calculate binary logarithm of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function log_2(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            if (uint128(x) > 0x80000000000000000000000000000000) {
                return NaN;
            } else if (x == 0x3FFF0000000000000000000000000000) {
                return _POSITIVE_ZERO;
            } else {
                uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
                if (xExponent == 0x7FFF) {
                    return x;
                } else {
                    uint256 xSignifier =
                        uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    if (xExponent == 0) {
                        xExponent = 1;
                    } else {
                        xSignifier |= 0x10000000000000000000000000000;
                    }

                    if (xSignifier == 0) {
                        return _NEGATIVE_INFINITY;
                    }

                    bool resultNegative;
                    uint256 resultExponent = 16495;
                    uint256 resultSignifier;

                    if (xExponent >= 0x3FFF) {
                        resultNegative = false;
                        resultSignifier = xExponent - 0x3FFF;
                        xSignifier <<= 15;
                    } else {
                        resultNegative = true;
                        if (xSignifier >= 0x10000000000000000000000000000) {
                            resultSignifier = 0x3FFE - xExponent;
                            xSignifier <<= 15;
                        } else {
                            uint256 msb = mostSignificantBit(xSignifier);
                            resultSignifier = 16493 - msb;
                            xSignifier <<= 127 - msb;
                        }
                    }

                    if (xSignifier == 0x80000000000000000000000000000000) {
                        if (resultNegative) {
                            resultSignifier += 1;
                        }
                        uint256 shift =
                            112 - mostSignificantBit(resultSignifier);
                        resultSignifier <<= shift;
                        resultExponent -= shift;
                    } else {
                        uint256 bb = resultNegative ? 1 : 0;
                        while (
                            resultSignifier < 0x10000000000000000000000000000
                        ) {
                            resultSignifier <<= 1;
                            resultExponent -= 1;

                            xSignifier *= xSignifier;
                            uint256 b = xSignifier >> 255;
                            resultSignifier += b ^ bb;
                            xSignifier >>= 127 + b;
                        }
                    }

                    return bytes16(
                        uint128(
                            (
                                resultNegative
                                    ? 0x80000000000000000000000000000000
                                    : 0
                            ) | (resultExponent << 112)
                                | (resultSignifier & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
                        )
                    );
                }
            }
        }
    }

    /**
     * Calculate natural logarithm of x.  Return NaN on negative x excluding -0.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function ln(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            return mul(log_2(x), 0x3FFE62E42FEFA39EF35793C7673007E5);
        }
    }

    /**
     * Calculate 2^x.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function pow_2(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            bool xNegative = uint128(x) > 0x80000000000000000000000000000000;
            uint256 xExponent = (uint128(x) >> 112) & 0x7FFF;
            uint256 xSignifier = uint128(x) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

            if (xExponent == 0x7FFF && xSignifier != 0) {
                return NaN;
            } else if (xExponent > 16397) {
                return xNegative ? _POSITIVE_ZERO : _POSITIVE_INFINITY;
            } else if (xExponent < 16255) {
                return 0x3FFF0000000000000000000000000000;
            } else {
                if (xExponent == 0) {
                    xExponent = 1;
                } else {
                    xSignifier |= 0x10000000000000000000000000000;
                }

                if (xExponent > 16367) {
                    xSignifier <<= xExponent - 16367;
                } else if (xExponent < 16367) {
                    xSignifier >>= 16367 - xExponent;
                }

                if (
                    xNegative
                        && xSignifier > 0x406E00000000000000000000000000000000
                ) {
                    return _POSITIVE_ZERO;
                }

                if (
                    !xNegative
                        && xSignifier > 0x3FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                ) {
                    return _POSITIVE_INFINITY;
                }

                uint256 resultExponent = xSignifier >> 128;
                xSignifier &= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                if (xNegative && xSignifier != 0) {
                    xSignifier = ~xSignifier;
                    resultExponent += 1;
                }

                uint256 resultSignifier = 0x80000000000000000000000000000000;
                if (xSignifier & 0x80000000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x16A09E667F3BCC908B2FB1366EA957D3E
                    ) >> 128;
                }
                if (xSignifier & 0x40000000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1306FE0A31B7152DE8D5A46305C85EDEC
                    ) >> 128;
                }
                if (xSignifier & 0x20000000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1172B83C7D517ADCDF7C8C50EB14A791F
                    ) >> 128;
                }
                if (xSignifier & 0x10000000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10B5586CF9890F6298B92B71842A98363
                    ) >> 128;
                }
                if (xSignifier & 0x8000000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1059B0D31585743AE7C548EB68CA417FD
                    ) >> 128;
                }
                if (xSignifier & 0x4000000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x102C9A3E778060EE6F7CACA4F7A29BDE8
                    ) >> 128;
                }
                if (xSignifier & 0x2000000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10163DA9FB33356D84A66AE336DCDFA3F
                    ) >> 128;
                }
                if (xSignifier & 0x1000000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100B1AFA5ABCBED6129AB13EC11DC9543
                    ) >> 128;
                }
                if (xSignifier & 0x800000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10058C86DA1C09EA1FF19D294CF2F679B
                    ) >> 128;
                }
                if (xSignifier & 0x400000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1002C605E2E8CEC506D21BFC89A23A00F
                    ) >> 128;
                }
                if (xSignifier & 0x200000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100162F3904051FA128BCA9C55C31E5DF
                    ) >> 128;
                }
                if (xSignifier & 0x100000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000B175EFFDC76BA38E31671CA939725
                    ) >> 128;
                }
                if (xSignifier & 0x80000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100058BA01FB9F96D6CACD4B180917C3D
                    ) >> 128;
                }
                if (xSignifier & 0x40000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10002C5CC37DA9491D0985C348C68E7B3
                    ) >> 128;
                }
                if (xSignifier & 0x20000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000162E525EE054754457D5995292026
                    ) >> 128;
                }
                if (xSignifier & 0x10000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000B17255775C040618BF4A4ADE83FC
                    ) >> 128;
                }
                if (xSignifier & 0x8000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB
                    ) >> 128;
                }
                if (xSignifier & 0x4000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9
                    ) >> 128;
                }
                if (xSignifier & 0x2000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000162E43F4F831060E02D839A9D16D
                    ) >> 128;
                }
                if (xSignifier & 0x1000000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000B1721BCFC99D9F890EA06911763
                    ) >> 128;
                }
                if (xSignifier & 0x800000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000058B90CF1E6D97F9CA14DBCC1628
                    ) >> 128;
                }
                if (xSignifier & 0x400000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000002C5C863B73F016468F6BAC5CA2B
                    ) >> 128;
                }
                if (xSignifier & 0x200000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000162E430E5A18F6119E3C02282A5
                    ) >> 128;
                }
                if (xSignifier & 0x100000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000B1721835514B86E6D96EFD1BFE
                    ) >> 128;
                }
                if (xSignifier & 0x80000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000058B90C0B48C6BE5DF846C5B2EF
                    ) >> 128;
                }
                if (xSignifier & 0x40000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000002C5C8601CC6B9E94213C72737A
                    ) >> 128;
                }
                if (xSignifier & 0x20000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000162E42FFF037DF38AA2B219F06
                    ) >> 128;
                }
                if (xSignifier & 0x10000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000B17217FBA9C739AA5819F44F9
                    ) >> 128;
                }
                if (xSignifier & 0x8000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000058B90BFCDEE5ACD3C1CEDC823
                    ) >> 128;
                }
                if (xSignifier & 0x4000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000002C5C85FE31F35A6A30DA1BE50
                    ) >> 128;
                }
                if (xSignifier & 0x2000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000162E42FF0999CE3541B9FFFCF
                    ) >> 128;
                }
                if (xSignifier & 0x1000000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000B17217F80F4EF5AADDA45554
                    ) >> 128;
                }
                if (xSignifier & 0x800000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000058B90BFBF8479BD5A81B51AD
                    ) >> 128;
                }
                if (xSignifier & 0x400000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000002C5C85FDF84BD62AE30A74CC
                    ) >> 128;
                }
                if (xSignifier & 0x200000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000162E42FEFB2FED257559BDAA
                    ) >> 128;
                }
                if (xSignifier & 0x100000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000B17217F7D5A7716BBA4A9AE
                    ) >> 128;
                }
                if (xSignifier & 0x80000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000058B90BFBE9DDBAC5E109CCE
                    ) >> 128;
                }
                if (xSignifier & 0x40000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000002C5C85FDF4B15DE6F17EB0D
                    ) >> 128;
                }
                if (xSignifier & 0x20000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000162E42FEFA494F1478FDE05
                    ) >> 128;
                }
                if (xSignifier & 0x10000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000B17217F7D20CF927C8E94C
                    ) >> 128;
                }
                if (xSignifier & 0x8000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000058B90BFBE8F71CB4E4B33D
                    ) >> 128;
                }
                if (xSignifier & 0x4000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000002C5C85FDF477B662B26945
                    ) >> 128;
                }
                if (xSignifier & 0x2000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000162E42FEFA3AE53369388C
                    ) >> 128;
                }
                if (xSignifier & 0x1000000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000B17217F7D1D351A389D40
                    ) >> 128;
                }
                if (xSignifier & 0x800000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000058B90BFBE8E8B2D3D4EDE
                    ) >> 128;
                }
                if (xSignifier & 0x400000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000002C5C85FDF4741BEA6E77E
                    ) >> 128;
                }
                if (xSignifier & 0x200000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000162E42FEFA39FE95583C2
                    ) >> 128;
                }
                if (xSignifier & 0x100000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000B17217F7D1CFB72B45E1
                    ) >> 128;
                }
                if (xSignifier & 0x80000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000058B90BFBE8E7CC35C3F0
                    ) >> 128;
                }
                if (xSignifier & 0x40000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000002C5C85FDF473E242EA38
                    ) >> 128;
                }
                if (xSignifier & 0x20000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000162E42FEFA39F02B772C
                    ) >> 128;
                }
                if (xSignifier & 0x10000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000B17217F7D1CF7D83C1A
                    ) >> 128;
                }
                if (xSignifier & 0x8000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000058B90BFBE8E7BDCBE2E
                    ) >> 128;
                }
                if (xSignifier & 0x4000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000002C5C85FDF473DEA871F
                    ) >> 128;
                }
                if (xSignifier & 0x2000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000162E42FEFA39EF44D91
                    ) >> 128;
                }
                if (xSignifier & 0x1000000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000B17217F7D1CF79E949
                    ) >> 128;
                }
                if (xSignifier & 0x800000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000058B90BFBE8E7BCE544
                    ) >> 128;
                }
                if (xSignifier & 0x400000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000002C5C85FDF473DE6ECA
                    ) >> 128;
                }
                if (xSignifier & 0x200000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000162E42FEFA39EF366F
                    ) >> 128;
                }
                if (xSignifier & 0x100000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000B17217F7D1CF79AFA
                    ) >> 128;
                }
                if (xSignifier & 0x80000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000058B90BFBE8E7BCD6D
                    ) >> 128;
                }
                if (xSignifier & 0x40000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000002C5C85FDF473DE6B2
                    ) >> 128;
                }
                if (xSignifier & 0x20000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000162E42FEFA39EF358
                    ) >> 128;
                }
                if (xSignifier & 0x10000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000B17217F7D1CF79AB
                    ) >> 128;
                }
                if (xSignifier & 0x8000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000058B90BFBE8E7BCD5
                    ) >> 128;
                }
                if (xSignifier & 0x4000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000002C5C85FDF473DE6A
                    ) >> 128;
                }
                if (xSignifier & 0x2000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000162E42FEFA39EF34
                    ) >> 128;
                }
                if (xSignifier & 0x1000000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000B17217F7D1CF799
                    ) >> 128;
                }
                if (xSignifier & 0x800000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000058B90BFBE8E7BCC
                    ) >> 128;
                }
                if (xSignifier & 0x400000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000002C5C85FDF473DE5
                    ) >> 128;
                }
                if (xSignifier & 0x200000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000162E42FEFA39EF2
                    ) >> 128;
                }
                if (xSignifier & 0x100000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000000B17217F7D1CF78
                    ) >> 128;
                }
                if (xSignifier & 0x80000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000058B90BFBE8E7BB
                    ) >> 128;
                }
                if (xSignifier & 0x40000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000002C5C85FDF473DD
                    ) >> 128;
                }
                if (xSignifier & 0x20000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000000162E42FEFA39EE
                    ) >> 128;
                }
                if (xSignifier & 0x10000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000000B17217F7D1CF6
                    ) >> 128;
                }
                if (xSignifier & 0x8000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000000058B90BFBE8E7A
                    ) >> 128;
                }
                if (xSignifier & 0x4000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000002C5C85FDF473C
                    ) >> 128;
                }
                if (xSignifier & 0x2000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000000162E42FEFA39D
                    ) >> 128;
                }
                if (xSignifier & 0x1000000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000000B17217F7D1CE
                    ) >> 128;
                }
                if (xSignifier & 0x800000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000000058B90BFBE8E6
                    ) >> 128;
                }
                if (xSignifier & 0x400000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000000002C5C85FDF472
                    ) >> 128;
                }
                if (xSignifier & 0x200000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000000162E42FEFA38
                    ) >> 128;
                }
                if (xSignifier & 0x100000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000000000B17217F7D1B
                    ) >> 128;
                }
                if (xSignifier & 0x80000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000000058B90BFBE8D
                    ) >> 128;
                }
                if (xSignifier & 0x40000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000000002C5C85FDF46
                    ) >> 128;
                }
                if (xSignifier & 0x20000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000000000162E42FEFA2
                    ) >> 128;
                }
                if (xSignifier & 0x10000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000000000B17217F7D0
                    ) >> 128;
                }
                if (xSignifier & 0x8000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000000000058B90BFBE7
                    ) >> 128;
                }
                if (xSignifier & 0x4000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000000002C5C85FDF3
                    ) >> 128;
                }
                if (xSignifier & 0x2000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000000000162E42FEF9
                    ) >> 128;
                }
                if (xSignifier & 0x1000000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000000000B17217F7C
                    ) >> 128;
                }
                if (xSignifier & 0x800000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000000000058B90BFBD
                    ) >> 128;
                }
                if (xSignifier & 0x400000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000000000002C5C85FDE
                    ) >> 128;
                }
                if (xSignifier & 0x200000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000000000162E42FEE
                    ) >> 128;
                }
                if (xSignifier & 0x100000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000000000000B17217F6
                    ) >> 128;
                }
                if (xSignifier & 0x80000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000000000058B90BFA
                    ) >> 128;
                }
                if (xSignifier & 0x40000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000000000002C5C85FC
                    ) >> 128;
                }
                if (xSignifier & 0x20000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000000000000162E42FD
                    ) >> 128;
                }
                if (xSignifier & 0x10000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000000000000B17217E
                    ) >> 128;
                }
                if (xSignifier & 0x8000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000000000000058B90BE
                    ) >> 128;
                }
                if (xSignifier & 0x4000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000000000002C5C85E
                    ) >> 128;
                }
                if (xSignifier & 0x2000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000000000000162E42E
                    ) >> 128;
                }
                if (xSignifier & 0x1000000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000000000000B17216
                    ) >> 128;
                }
                if (xSignifier & 0x800000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000000000000058B90A
                    ) >> 128;
                }
                if (xSignifier & 0x400000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000000000000002C5C84
                    ) >> 128;
                }
                if (xSignifier & 0x200000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000000000000162E41
                    ) >> 128;
                }
                if (xSignifier & 0x100000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000000000000000B1720
                    ) >> 128;
                }
                if (xSignifier & 0x80000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000000000000058B8F
                    ) >> 128;
                }
                if (xSignifier & 0x40000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000000000000002C5C7
                    ) >> 128;
                }
                if (xSignifier & 0x20000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000000000000000162E3
                    ) >> 128;
                }
                if (xSignifier & 0x10000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000000000000000B171
                    ) >> 128;
                }
                if (xSignifier & 0x8000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000000000000000058B8
                    ) >> 128;
                }
                if (xSignifier & 0x4000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000000000000002C5B
                    ) >> 128;
                }
                if (xSignifier & 0x2000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000000000000000162D
                    ) >> 128;
                }
                if (xSignifier & 0x1000 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000000000000000B16
                    ) >> 128;
                }
                if (xSignifier & 0x800 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000000000000000058A
                    ) >> 128;
                }
                if (xSignifier & 0x400 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000000000000000002C4
                    ) >> 128;
                }
                if (xSignifier & 0x200 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000000000000000161
                    ) >> 128;
                }
                if (xSignifier & 0x100 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x1000000000000000000000000000000B0
                    ) >> 128;
                }
                if (xSignifier & 0x80 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000000000000000057
                    ) >> 128;
                }
                if (xSignifier & 0x40 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000000000000000002B
                    ) >> 128;
                }
                if (xSignifier & 0x20 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000000000000000015
                    ) >> 128;
                }
                if (xSignifier & 0x10 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x10000000000000000000000000000000A
                    ) >> 128;
                }
                if (xSignifier & 0x8 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000000000000000004
                    ) >> 128;
                }
                if (xSignifier & 0x4 > 0) {
                    resultSignifier = (
                        resultSignifier * 0x100000000000000000000000000000001
                    ) >> 128;
                }

                if (!xNegative) {
                    resultSignifier =
                        (resultSignifier >> 15) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    resultExponent += 0x3FFF;
                } else if (resultExponent <= 0x3FFE) {
                    resultSignifier =
                        (resultSignifier >> 15) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
                    resultExponent = 0x3FFF - resultExponent;
                } else {
                    resultSignifier =
                        resultSignifier >> (resultExponent - 16367);
                    resultExponent = 0;
                }

                return bytes16(
                    uint128((resultExponent << 112) | resultSignifier)
                );
            }
        }
    }

    /**
     * Calculate e^x.
     *
     * @param x quadruple precision number
     * @return quadruple precision number
     */
    function exp(bytes16 x) internal pure returns (bytes16) {
        unchecked {
            return pow_2(mul(x, 0x3FFF71547652B82FE1777D0FFDA0D23A));
        }
    }

    /**
     * Get index of the most significant non-zero bit in binary representation of
     * x.  Reverts if x is zero.
     *
     * @return index of the most significant non-zero bit in binary representation
     * of x
     */
    function mostSignificantBit(uint256 x) private pure returns (uint256) {
        unchecked {
            require(x > 0);

            uint256 result = 0;

            if (x >= 0x100000000000000000000000000000000) {
                x >>= 128;
                result += 128;
            }
            if (x >= 0x10000000000000000) {
                x >>= 64;
                result += 64;
            }
            if (x >= 0x100000000) {
                x >>= 32;
                result += 32;
            }
            if (x >= 0x10000) {
                x >>= 16;
                result += 16;
            }
            if (x >= 0x100) {
                x >>= 8;
                result += 8;
            }
            if (x >= 0x10) {
                x >>= 4;
                result += 4;
            }
            if (x >= 0x4) {
                x >>= 2;
                result += 2;
            }
            if (x >= 0x2) {
                result += 1;
            } // No need to shift x anymore

            return result;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/utils/ICollectableDust.sol";

abstract contract CollectableDust is ICollectableDust {
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public constant ETH_ADDRESS =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    EnumerableSet.AddressSet internal _protocolTokens;

    // solhint-disable-next-line no-empty-blocks
    constructor() {}

    function _addProtocolToken(address _token) internal {
        require(
            !_protocolTokens.contains(_token),
            "collectable-dust::token-is-part-of-the-protocol"
        );
        _protocolTokens.add(_token);
        emit ProtocolTokenAdded(_token);
    }

    function _removeProtocolToken(address _token) internal {
        require(
            _protocolTokens.contains(_token),
            "collectable-dust::token-not-part-of-the-protocol"
        );
        _protocolTokens.remove(_token);
        emit ProtocolTokenRemoved(_token);
    }

    function _sendDust(address _to, address _token, uint256 _amount) internal {
        require(
            _to != address(0),
            "collectable-dust::cant-send-dust-to-zero-address"
        );
        require(
            !_protocolTokens.contains(_token),
            "collectable-dust::token-is-part-of-the-protocol"
        );
        if (_token == ETH_ADDRESS) {
            payable(_to).transfer(_amount);
        } else {
            IERC20(_token).safeTransfer(_to, _amount);
        }
        emit DustSent(_to, _token, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

/**
 * @dev Wrappers over Solidity's array push operations with added check
 *
 */
library SafeAddArray {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     */
    function add(bytes32[] storage array, bytes32 value) internal {
        for (uint256 i; i < array.length; i++) {
            if (array[i] == value) {
                return;
            }
        }
        array.push(value);
    }

    function add(string[] storage array, string memory value) internal {
        bytes32 hashValue = keccak256(bytes(value));
        for (uint256 i; i < array.length; i++) {
            if (keccak256(bytes(array[i])) == hashValue) {
                return;
            }
        }
        array.push(value);
    }

    function add(uint256[] storage array, uint256 value) internal {
        for (uint256 i; i < array.length; i++) {
            if (array[i] == value) {
                return;
            }
        }
        array.push(value);
    }

    function add(uint256[] storage array, uint256[] memory values) internal {
        for (uint256 i; i < values.length; i++) {
            bool exist = false;
            for (uint256 j; j < array.length; j++) {
                if (array[j] == values[i]) {
                    exist = true;
                    break;
                }
            }
            if (!exist) {
                array.push(values[i]);
            }
        }
    }
}