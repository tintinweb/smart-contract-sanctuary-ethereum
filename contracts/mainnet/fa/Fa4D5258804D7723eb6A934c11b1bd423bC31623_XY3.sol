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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.1) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector));
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IConfig.sol";
import {MANAGER_ROLE, SIGNER_ROLE} from "./Roles.sol";

bytes32 constant PERMIT_MANAGER_ROLE = keccak256("PERMIT_MANAGER");

/**
 * @title  Configurations for both ERC721 token and ERC20 currency.
 * @author XY3 g
 * @dev Implements token and currency management and security functions.
 */
abstract contract Config is AccessControl, Pausable, ReentrancyGuard, IConfig {

    /**
     * @dev Admin fee receiver, can be updated by admin.
     */
    address public adminFeeReceiver;

    /**
     * @dev Borrow durations, can be updated by admin.
     */
    uint256 public override maxBorrowDuration = 365 days;
    uint256 public override minBorrowDuration = 1 days;

    /**
     * @dev The fee percentage is taken by the contract admin's as a
     * fee, which is from the the percentage of lender earned.
     * Unit is hundreths of percent, like adminShare/10000.
     */
    uint16 public override adminShare = 25;
    uint16 public constant HUNDRED_PERCENT = 10000;

    /**
     * @dev The permitted ERC20 currency for this contract.
     */
    mapping(address => bool) private erc20Permits;

    /**
     * @dev The permitted ERC721 token or collections for this contract.
     */
    mapping(address => bool) private erc721Permits;

    /**
     * @dev The permitted agent for this contract, index is target + selector;
     */
    mapping(address => mapping(bytes4 => bool)) private agentPermits;

    /**
     * @dev Address Provider
     */
    address private addressProvider;

    /**
     * @dev Init the contract admin.
     * @param _admin - Initial admin of this contract and fee receiver.
     */
    constructor(address _admin, address _addressProvider) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _setRoleAdmin(MANAGER_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(SIGNER_ROLE, DEFAULT_ADMIN_ROLE);
        adminFeeReceiver = _admin;
        addressProvider = _addressProvider;
    }

    /**
     * @dev Sets contract to be stopped state.
     */
    function pause() external onlyRole(MANAGER_ROLE) {
        _pause();
    }

    /**
     * @dev Restore the contract from stopped state.
     */
    function unpause() external onlyRole(MANAGER_ROLE) {
        _unpause();
    }

    /**
     * @dev Update the maxBorrowDuration by manger role.
     * @param _newMaxBorrowDuration - The new max borrow duration, measured in seconds.
     */
    function updateMaxBorrowDuration(
        uint256 _newMaxBorrowDuration
    ) external override onlyRole(MANAGER_ROLE) {
        require(_newMaxBorrowDuration >= minBorrowDuration, "Invalid duration");
        if (maxBorrowDuration != _newMaxBorrowDuration) {
            maxBorrowDuration = _newMaxBorrowDuration;
            emit MaxBorrowDurationUpdated(_newMaxBorrowDuration);
        }
    }

    /**
     * @dev Update the minBorrowDuration by manger role.
     * @param _newMinBorrowDuration - The new min borrow duration, measured in seconds.
     */
    function updateMinBorrowDuration(
        uint256 _newMinBorrowDuration
    ) external override onlyRole(MANAGER_ROLE) {
        require(_newMinBorrowDuration <= maxBorrowDuration, "Invalid duration");
        if (minBorrowDuration != _newMinBorrowDuration) {
            minBorrowDuration = _newMinBorrowDuration;
            emit MinBorrowDurationUpdated(_newMinBorrowDuration);
        }
    }

    /**
     * @notice Update the adminShaer by manger role. The newAdminFee can be bigger than 10,000.
     * @param _newAdminShare - The new admin fee measured in basis points.
     */
    function updateAdminShare(
        uint16 _newAdminShare
    ) external override onlyRole(MANAGER_ROLE) {
        require(_newAdminShare <= HUNDRED_PERCENT, "basis points > 10000");
        if (adminShare != _newAdminShare) {
            adminShare = _newAdminShare;
            emit AdminFeeUpdated(_newAdminShare);
        }
    }

    /**
     * @dev Update the adminFeeReceiver by manger role.
     * @param _newAdminFeeReceiver - The new admin fee receiver address.
     */
    function updateAdminFeeReceiver(
        address _newAdminFeeReceiver
    ) external override onlyRole(MANAGER_ROLE) {
        require(_newAdminFeeReceiver != address(0), "Invalid receiver address");
        if (adminFeeReceiver != _newAdminFeeReceiver) {
            adminFeeReceiver = _newAdminFeeReceiver;
            emit AdminFeeReceiverUpdated(adminFeeReceiver);
        }
    }

    /**
     * @dev Set or remove the ERC20 currency permit by manger role.
     * @param _erc20s - The addresses of the ERC20 currencies.
     * @param _permits - The new statuses of the currencies.
     */
    function setERC20Permits(
        address[] memory _erc20s,
        bool[] memory _permits
    ) external override onlyRole(MANAGER_ROLE) {
        require(
            _erc20s.length == _permits.length,
            "address and permits length mismatch"
        );

        for (uint256 i = 0; i < _erc20s.length; i++) {
            _setERC20Permit(_erc20s[i], _permits[i]);
        }
    }

    /**
     * @dev Set or remove the ERC721 token permit by manger role.
     * @param _erc721s - The addresses of the ERC721 collection.
     * @param _permits - The new statuses of the collection.
     */
    function setERC721Permits(
        address[] memory _erc721s,
        bool[] memory _permits
    ) external override onlyRole(MANAGER_ROLE) {
        require(
            _erc721s.length == _permits.length,
            "address and permits length mismatch"
        );

        for (uint256 i = 0; i < _erc721s.length; i++) {
            _setERC721Permit(_erc721s[i], _permits[i]);
        }
    }

    /**
     * @dev Set or remove the ERC721 token permit by manger role.
     * @param _agents - The addresses of the ERC721 collection.
     * @param _permits - The new statuses of the collection.
     */
    function setAgentPermits(
        address[] memory _agents,
        bytes4[] memory _selectors,
        bool[] memory _permits
    ) external override onlyRole(PERMIT_MANAGER_ROLE) {
        require(
            _agents.length == _permits.length && _selectors.length == _permits.length,
            "address and permits length mismatch"
        );

        for (uint256 i = 0; i < _agents.length; i++) {
            _setAgentPermit(_agents[i], _selectors[i], _permits[i]);
        }
    }

    /**
     * @dev Get the permit of the ERC20 token, public reading.
     * @param _erc20 - The address of the ERC20 token.
     * @return The ERC20 permit boolean value
     */
    function getERC20Permit(
        address _erc20
    ) public view override returns (bool) {
        return erc20Permits[_erc20];
    }

    /**
     * @dev Get the permit of the ERC721 collection, public reading.
     * @param _erc721 - The address of the ERC721 collection.
     * @return The ERC721 collection permit boolean value
     */
    function getERC721Permit(
        address _erc721
    ) public view override returns (bool) {
        return erc721Permits[_erc721];
    }

    /**
     * @dev Get the permit of agent, public reading.
     * @param _agent - The address of the agent.
     * @return The agent permit boolean value
     */
    function getAgentPermit(
        address _agent,
        bytes4 _selector
    ) public view override returns (bool) {
        return agentPermits[_agent][_selector];
    }

    function getAddressProvider()
        public
        view
        override
        returns (IAddressProvider)
    {
        return IAddressProvider(addressProvider);
    }

    /**
     * @dev Permit or remove ERC20 currency.
     * @param _erc20 - The operated ERC20 currency address.
     * @param _permit - The currency new status, permitted or not.
     */
    function _setERC20Permit(address _erc20, bool _permit) internal {
        require(_erc20 != address(0), "erc20 is zero address");

        erc20Permits[_erc20] = _permit;

        emit ERC20Permit(_erc20, _permit);
    }

    /**
     * @dev Permit or remove ERC721 token.
     * @param _erc721 - The operated ERC721 token address.
     * @param _permit - The token new status, permitted or not.
     */
    function _setERC721Permit(address _erc721, bool _permit) internal {
        require(_erc721 != address(0), "erc721 is zero address");

        erc721Permits[_erc721] = _permit;

        emit ERC721Permit(_erc721, _permit);
    }

    /**
     * @dev Permit or remove ERC721 token.
     * @param _agent - The operated ERC721 token address.
     * @param _permit - The token new status, permitted or not.
     */
    function _setAgentPermit(address _agent, bytes4 _selector, bool _permit) internal {
        require(_agent != address(0) && _selector != bytes4(0), "agent is zero address");

        agentPermits[_agent][_selector] = _permit;

        emit AgentPermit(_agent, _selector, _permit);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

/**
 * @title  Loan data types
 * @author XY3
 */

/**
 * @dev Signature data for both lender & broker.
 * @param signer - The address of the signer.
 * @param nonce User offer nonce.
 * @param expiry  The signature expires date.
 * @param signature  The ECDSA signature, singed off-chain.
 */
struct Signature {
    uint256 nonce;
    uint256 expiry;
    address signer;
    bytes signature;
}

/**
 * @dev Saved the loan related data.
 * 
 * @param borrowAmount - The original amount of money transferred from lender to borrower.
 * @param repayAmount - The maximum amount of money that the borrower would be required to retrieve their collateral.
 * @param nftTokenId - The ID within the Xy3 NFT.
 * @param borrowAsset - The ERC20 currency address.
 * @param loanDuration - The alive time of loan in seconds.
 * @param adminShare - The admin fee percent from paid loan.
 * @param loanStart - The block.timestamp the loan start in seconds.
 * @param nftAsset - The address of the the Xy3 NFT contract.
 * @param isCollection - The accepted offer is a collection or not.
*/
struct LoanDetail {
    uint256 borrowAmount;
    uint256 repayAmount;
    uint256 nftTokenId;
    address borrowAsset;
    uint32 loanDuration;
    uint16 adminShare;
    uint64 loanStart;
    address nftAsset;
    bool isCollection;
}

/**
 * @dev The offer made by the lender. Used as parameter on borrow.
 *
 * @param borrowAsset - The address of the ERC20 currency.
 * @param borrowAmount - The original amount of money transferred from lender to borrower.
 * @param repayAmount - The maximum amount of money that the borrower would be required to retrieve their collateral.
 * @param nftAsset - The address of the the Xy3 NFT contract.
 * @param borrowDuration - The alive time of borrow in seconds.
 * @param timestamp - For timestamp cancel
 * @param extra - Extra bytes for only signed check
 */
struct Offer {
    uint256 borrowAmount;
    uint256 repayAmount;
    address nftAsset;
    uint32 borrowDuration;
    address borrowAsset;
    uint256 timestamp;
    bytes extra;
}

/**
 * @dev The data for borrow external call.
 *
 * @param target - The target contract address.
 * @param selector - The target called function.
 * @param data - The target function call data with parameters only.
 * @param referral - The referral code for borrower.
 *
 */
struct CallData {
    address target;
    bytes4 selector;
    bytes data;
    uint256 referral;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;
import "@openzeppelin/contracts/access/AccessControl.sol";
import {INTERCEPTOR_ROLE, MANAGER_ROLE} from "./Roles.sol";
uint constant BORROW_QUEUE = 0;
uint constant REPAY_QUEUE = 1;
uint constant LIQUIDATE_QUEUE = 2;
uint constant QUEUE_LEN = 3;

interface IInterceptor {
    function beforeEvent(
        uint _eventId,
        address _nftAsset,
        uint _tokenId
    ) external;

    function afterEvent(
        uint _eventId,
        address _nftAsset,
        uint _tokenId
    ) external;
}

abstract contract InterceptorManager is AccessControl {
    event UpdageInterceptor(uint256 indexed queueId, address indexed nftAsset, uint256 tokenId, address interceptor, bool add);
    event ExecuteInterceptor(uint256 indexed queueId, address indexed nftAsset, uint256 tokenId, address interceptor, bool before);

    mapping(address => mapping(uint256 => address[]))[QUEUE_LEN]
        private _interceptors;

    function addInterceptor(
        uint _queueId,
        address _nftAsset,
        uint _tokenId
    ) external onlyRole(INTERCEPTOR_ROLE) {
        require(_queueId < QUEUE_LEN, "Invalid queueId");
        address interceptor = msg.sender;
        address[] storage interceptors = _interceptors[_queueId][_nftAsset][
            _tokenId
        ];
        for (uint i = 0; i < interceptors.length; i++) {
            if (interceptors[i] == interceptor) {
                return;
            }
        }
        interceptors.push(interceptor);
        emit UpdageInterceptor(_queueId, _nftAsset, _tokenId, interceptor, true);
    }

    function deleteInterceptor(
        uint _queueId,
        address _nftAsset,
        uint _tokenId
    ) external onlyRole(INTERCEPTOR_ROLE) {
        address interceptor = msg.sender;

        address[] storage interceptors = _interceptors[_queueId][_nftAsset][
            _tokenId
        ];

        uint256 findIndex = 0;
        for (; findIndex < interceptors.length; findIndex++) {
            if (interceptors[findIndex] == interceptor) {
                break;
            }
        }

        if (findIndex != _interceptors.length) {
            _deleteInterceptor(_queueId, _nftAsset, _tokenId, findIndex);
        }
    }

    function purgeInterceptor(
        uint256 _queueId,
        address nftAsset,
        uint256[] calldata tokenIds,
        address interceptor
    ) public onlyRole(MANAGER_ROLE) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            address[] storage interceptors = _interceptors[_queueId][nftAsset][
                tokenIds[i]
            ];
            for (
                uint256 findIndex = 0;
                findIndex < interceptors.length;
                findIndex++
            ) {
                if (interceptors[findIndex] == interceptor) {
                    _deleteInterceptor(
                        _queueId,
                        nftAsset,
                        tokenIds[i],
                        findIndex
                    );
                    break;
                }
            }
        }
    }

    function getInterceptors(
        uint _queueId,
        address nftAsset,
        uint256 tokenId
    ) public view returns (address[] memory) {
        return _interceptors[_queueId][nftAsset][tokenId];
    }

    function _deleteInterceptor(
        uint queueId,
        address nftAsset,
        uint256 tokenId,
        uint256 findIndex
    ) internal {
        address[] storage interceptors = _interceptors[queueId][nftAsset][
            tokenId
        ];
        address findInterceptor = interceptors[findIndex];
        uint256 lastInterceptorIndex = interceptors.length - 1;
        // When the token to delete is the last item, the swap operation is unnecessary.
        // Move the last interceptor to the slot of the to-delete interceptor
        if (findIndex < lastInterceptorIndex) {
            address lastInterceptorAddr = interceptors[lastInterceptorIndex];
            interceptors[findIndex] = lastInterceptorAddr;
        }
        interceptors.pop();
        emit UpdageInterceptor(queueId, nftAsset, tokenId, findInterceptor, false);
    }

    function executeInterceptors(
        uint queueId,
        bool before,
        address nftAsset,
        uint tokenId
    ) internal {
        address[] memory interceptors = _interceptors[queueId][nftAsset][
            tokenId
        ];
        for (uint i = 0; i < interceptors.length; i++) {
            if (before) {
                IInterceptor(interceptors[i]).beforeEvent(
                    queueId,
                    nftAsset,
                    tokenId
                );
            } else {
                IInterceptor(interceptors[i]).afterEvent(
                    queueId,
                    nftAsset,
                    tokenId
                );
            }

            emit ExecuteInterceptor(queueId, nftAsset, tokenId, interceptors[i], before);
        }
    }

    function beforeBorrow(address nftAsset, uint tokenId) internal {
        executeInterceptors(BORROW_QUEUE, true, nftAsset, tokenId);
    }

    function beforeRepay(address nftAsset, uint tokenId) internal {
        executeInterceptors(REPAY_QUEUE, true, nftAsset, tokenId);
    }

    function beforeLiquidate(address nftAsset, uint tokenId) internal {
        executeInterceptors(LIQUIDATE_QUEUE, true, nftAsset, tokenId);
    }

    function afterBorrow(address nftAsset, uint tokenId) internal {
        executeInterceptors(BORROW_QUEUE, false, nftAsset, tokenId);
    }

    function afterRepay(address nftAsset, uint tokenId) internal {
        executeInterceptors(REPAY_QUEUE, false, nftAsset, tokenId);
    }

    function afterLiquidate(address nftAsset, uint tokenId) internal {
        executeInterceptors(LIQUIDATE_QUEUE, false, nftAsset, tokenId);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;
bytes32 constant ADDR_LENDER_NOTE = "LENDER_NOTE";
bytes32 constant ADDR_BORROWER_NOTE = "BORROWER_NOTE";
bytes32 constant ADDR_FLASH_EXEC_PERMITS = "FLASH_EXEC_PERMITS";
bytes32 constant ADDR_TRANSFER_DELEGATE = "TRANSFER_DELEGATE";
bytes32 constant ADDR_SERVICE_FEE = "SERVICE_FEE";
bytes32 constant ADDR_XY3 = "XY3";
interface IAddressProvider {
    function getAddress(bytes32 id) external view returns (address);

    function getXY3() external view returns (address);

    function getLenderNote() external view returns (address);

    function getBorrowerNote() external view returns (address);

    function getFlashExecPermits() external view returns (address);

    function getTransferDelegate() external view returns (address);

    function getServiceFee() external view returns (address);

    function setAddress(bytes32 id, address newAddress) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;
import {IAddressProvider} from "./IAddressProvider.sol";

interface IConfig {
    /**
     * @notice This event is emitted when admin fee percent changed.
     * @param  newAdminFee - The new admin fee measured in basis points.
     */
    event AdminFeeUpdated(uint16 newAdminFee);

    /**
     * @notice This event is emitted when the max duration of all borrows.
     * @param  newMaxBorrowDuration - The new max duration in seconds.
     */
    event MaxBorrowDurationUpdated(uint256 newMaxBorrowDuration);

    /**
     * @notice This event is emitted when the min duration of all borrows.
     * @param  newMinBorrowDuration - The new min duration.
     */
    event MinBorrowDurationUpdated(uint256 newMinBorrowDuration);

    /**
     * @notice This event is emitted when the ERC20 permit is set.
     * @param erc20Contract - Address of the ERC20 token.
     * @param isPermitted - ERC20 permit bool value.
     */
    event ERC20Permit(address indexed erc20Contract, bool isPermitted);

    /**
     * @notice This event is emitted when the ERC721 permit is set.
     * @param erc721Contract - Address of the ERC721 collection address.
     * @param isPermitted - ERC721 permit bool value.
     */
    event ERC721Permit(address indexed erc721Contract, bool isPermitted);

    /**
     * @notice This event is emitted when the agent permit is set.
     * @param agent - Address of the agent.
     * @param isPermitted - Agent permit bool value.
     */
    event AgentPermit(address indexed agent, bytes4 selector, bool isPermitted);

    /**
     * @notice This event is emitted when the ERC20 approved to user.
     * @param user - User account.
     * @param erc20Contract - Address of the ERC20 token.
     * @param amount - ERC20 amount.
     */
    event ERC20Approve(address indexed user, address indexed erc20Contract, uint256 amount);

    /**
     * @notice This event is emitted when the ERC721 permit is set.
     * @param user - User account.
     * @param erc721Contract - Address of the ERC721 collection address.
     * @param isPermitted - ERC721 permit bool value.
     */
    event ERC721Approve(address indexed user, address indexed erc721Contract, bool isPermitted);

    /**
     * @notice This event is emitted when the admin fee receiver address is changed.
     */
    event AdminFeeReceiverUpdated(address);

    /**
     * @notice Get the current max allowed borrow duration.
     */
    function maxBorrowDuration() external view returns (uint256);

    /**
     * @notice Get the current min allowed borrow duration.
     */
    function minBorrowDuration() external view returns (uint256);

    /**
     * @notice Get percent of admin fee charged from lender earned.
     */
    function adminShare() external view returns (uint16);

    /**
     * @notice Update max borrow duration
     * @param  _newMaxBorrowDuration - The new max duration.
     */
    function updateMaxBorrowDuration(uint256 _newMaxBorrowDuration)
        external;

    /**
     * @notice Update min borrow duration
     * @param  _newMinBorrowDuration - The new min duration.
     */
    function updateMinBorrowDuration(uint256 _newMinBorrowDuration)
        external;

    /**
     * @notice Update admin fee.
     * @param  _newAdminShare - The new admin fee.
     */
    function updateAdminShare(uint16 _newAdminShare) external;

    /**
     * @notice Update admin fee receiver.
     * @param _newAdminFeeReceiver - The new admin fee receiver address.
     */
    function updateAdminFeeReceiver(address _newAdminFeeReceiver) external;

    /**
     * @notice Get the erc20 token permitted status.
     * @param _erc20 - The address of the ERC20 token.
     * @return The ERC20 permit boolean value
     */
    function getERC20Permit(address _erc20) external view returns (bool);

    /**
     * @notice Get the erc721 token permitted status.
     * @param _erc721 - The address of the ERC721 collection.
     * @return The ERC721 collection permit boolean value
     */
    function getERC721Permit(address _erc721) external view returns (bool);

    /**
     * @dev Get the permit of agent, public reading.
     * @param _agent - The address of the agent.
     * @return The agent permit boolean value
     */
    function getAgentPermit(address _agent, bytes4 _selector) external view returns (bool);

    /**
     * @notice Update a set of the ERC20 tokens permitted status.
     * @param _erc20s - The addresses of the ERC20 currencies.
     * @param _permits - The new statuses of the currencies.
     */
    function setERC20Permits(address[] memory _erc20s, bool[] memory _permits)
        external;

    /**
     * @notice Update a set of the ERC721 collection permitted status.
     * @param _erc721s - The addresses of the ERC721 collection.
     * @param _permits - The new statuses of the collection.
     */
    function setERC721Permits(address[] memory _erc721s, bool[] memory _permits)
        external;

    function setAgentPermits(address[] memory _agents, bytes4[] memory _selectors, bool[] memory _permits)
        external;

    function getAddressProvider() external view returns (IAddressProvider);
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.4;
pragma abicoder v2;

interface IDelegateV3 {
    function erc20Transfer(
        address sender,
        address receiver,
        address token,
        uint256 amount
    ) external;
    function erc721Transfer(
        address sender,
        address receiver,
        address token,
        uint256 tokenId
    )external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;
interface IFlashExecPermits {
  event AddPermit(address indexed target, bytes4 indexed selector);
  event RemovePermit(address indexed target, bytes4 indexed selector);

  function isPermitted(address target, bytes4 selector) external returns (bool);
  function addPermit(address target, bytes4 selector) external;
  function removePermit(address target, bytes4 selector) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface ILoanStatus {
    /**
     * @dev loan status
     */
    enum StatusType {
        NOT_EXISTS,
        NEW,
        RESOLVED
    }
    
    /**
     * @dev load status record structure
     */
    struct LoanState {
        uint64 xy3NftId;
        StatusType status;
    }

    /**
     * @dev get load status
     * @param _loanId load ID
     */
    function getLoanState(uint32 _loanId)
        external
        view
        returns (LoanState memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

interface IServiceFee {
    function setServiceFee(
        address _target,
        address _sender,
        address _nftAsset,
        uint16 _fee
    ) external;

    function clearServiceFee(
        address _target,
        address _sender,
        address _nftAsset
    ) external;

    function getServiceFee(
        address _target,
        address _sender,
        address _nftAsset
    ) external view returns (uint16);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.4;

import "../DataTypes.sol";

interface IXY3 {
    /**
     * @dev This event is emitted when  calling acceptOffer(), need both the lender and borrower to approve their ERC721 and ERC20 contracts to XY3.
     *
     * @param  loanId - A unique identifier for the loan.
     * @param  borrower - The address of the borrower.
     * @param  lender - The address of the lender.
     * @param  nonce - nonce of the lender's offer signature
     */
    event LoanStarted(
        uint32 indexed loanId,
        address indexed borrower,
        address indexed lender,
        uint256 nonce,
        LoanDetail loanDetail,
        address target,
        bytes4 selector
    );

    /**
     * @dev This event is emitted when a borrower successfully repaid the loan.
     *
     * @param  loanId - A unique identifier for the loan.
     * @param  borrower - The address of the borrower.
     * @param  lender - The address of the lender.
     * @param  borrowAmount - The original amount of money transferred from lender to borrower.
     * @param  nftTokenId - The ID of the borrowd.
     * @param  repayAmount The amount of ERC20 that the borrower paid back.
     * @param  adminFee The amount of interest paid to the contract admins.
     * @param  nftAsset - The ERC721 contract of the NFT collateral
     * @param  borrowAsset - The ERC20 currency token.
     */
    event LoanRepaid(
        uint32 indexed loanId,
        address indexed borrower,
        address indexed lender,
        uint256 borrowAmount,
        uint256 nftTokenId,
        uint256 repayAmount,
        uint256 adminFee,
        address nftAsset,
        address borrowAsset
    );

    /**
     * @dev This event is emitted when cancelByNonce called.
     * @param  lender - The address of the lender.
     * @param  nonce - nonce of the lender's offer signature
     */
    event NonceCancelled(address lender, uint256 nonce);

    /**
     * @dev This event is emitted when cancelByTimestamp called
     * @param  lender - The address of the lender.
     * @param timestamp - cancelled timestamp
     */
    event TimeStampCancelled(address lender, uint256 timestamp);

    /**
     * @dev This event is emitted when liquidates happened
     * @param  loanId - A unique identifier for this particular loan.
     * @param  borrower - The address of the borrower.
     * @param  lender - The address of the lender.
     * @param  borrowAmount - The original amount of money transferred from lender to borrower.
     * @param  nftTokenId - The ID of the borrowd.
     * @param  loanMaturityDate - The unix time (measured in seconds) that the loan became due and was eligible for liquidation.
     * @param  loanLiquidationDate - The unix time (measured in seconds) that liquidation occurred.
     * @param  nftAsset - The ERC721 contract of the NFT collateral
     */
    event LoanLiquidated(
        uint32 indexed loanId,
        address indexed borrower,
        address indexed lender,
        uint256 borrowAmount,
        uint256 nftTokenId,
        uint256 loanMaturityDate,
        uint256 loanLiquidationDate,
        address nftAsset
    );

    event BorrowRefferal(
        uint32 indexed loanId,
        address indexed borrower,
        uint256 referral
    );

    event FlashExecute(
        uint32 indexed loanId,
        address nft,
        uint256 nftTokenId,
        address flashTarget
    );

    event ServiceFee(uint32 indexed loanId, address indexed target, uint16 serviceFeeRate, uint256 feeAmount);

    /**
     * @dev Get the load info by loadId
     */
    function loanDetails(
        uint32
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            uint32,
            uint16,
            uint64,
            address,
            bool
        );

    function loanIds(
        address collection,
        uint256 tokenId
    ) external view returns (uint32);

    /**
     * @dev The borrower accept a lender's offer to create a loan.
     *
     * @param _offer - The offer made by the lender.
     * @param _nftId - The ID
     * @param _isCollectionOffer - Wether the offer is a collection offer.
     * @param _lenderSignature - The lender's signature.
     * @param _brokerSignature - The broker's signature.
     * @param _extraDeal - Create a new loan by getting a NFT colleteral from external contract call.
     * The external contract can be lending market or deal market, specially included the restricted repay of myself.
     * But should not be the Xy3Nft.mint, though this contract maybe have the permission.
     */
    function borrow(
        Offer memory _offer,
        uint256 _nftId,
        bool _isCollectionOffer,
        Signature memory _lenderSignature,
        Signature memory _brokerSignature,
        CallData memory _extraDeal
    ) external returns (uint32);

    /**
     * @dev A lender or a borrower to cancel all off-chain orders signed that contain this nonce.
     * @param  _nonce - User nonce
     */
    function cancelByNonce(uint256 _nonce) external;

    /**
     * @dev A borrower cancel all offers with timestamp before the _timestamp parameter.
     * @param _timestamp - cancelled timestamp
     */
    function cancelByTimestamp(uint256 _timestamp) external;

    /**
     * @notice Check a nonce has been used or not
     * @param _user - The user address.
     * @param _nonce - The order Id
     *
     * @return A bool for used or not.
     */
    function getNonceUsed(
        address _user,
        uint256 _nonce
    ) external view returns (bool);

    /**
     * @dev This function can be used to view the last cancel timestamp a borrower has set.
     * @param _user User address
     * @return The cancel timestamp
     */
    function getTimestampCancelled(
        address _user
    ) external view returns (uint256);

    /**
     * @dev Public function for anyone to repay a loan, and return the NFT token to origin borrower.
     * @param _loanId  The loan Id.
     */
    function repay(uint32 _loanId) external;

    /**
     * @dev Lender ended the load which not paid by borrow and expired.
     * @param _loanId The loan Id.
     */
    function liquidate(uint32 _loanId) external;

    /**
     * @dev Allow admin to claim airdroped erc20 tokens
     */
    function adminClaimErc20(
        address _to,
        address[] memory tokens,
        uint256[] memory amounts
    ) external;

    /**
     * @dev Allow admin to claim airdroped erc721 tokens
     */

    function adminClaimErc721(
        address _to,
        address[] memory tokens,
        uint256[] memory tokenIds
    ) external;

    /**
     * @dev Allow admin to claim airdroped erc1155 tokens
     */

    function adminClaimErc1155(
        address _to,
        address[] memory tokens,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external;

    /**
     * @dev The amount of ERC20 currency for the loan.
     * @param _loanId  A unique identifier for this particular loan.
     * @return The amount of ERC20 currency.
     */
    function getRepayAmount(uint32 _loanId) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "./Xy3Nft.sol";
import "./interfaces/ILoanStatus.sol";
import "./interfaces/IConfig.sol";

/**
 * @title  LoanStatus
 * @author XY3
 */
contract LoanStatus is ILoanStatus {

    event UpdateStatus(
        uint32 indexed loanId,
        uint64 indexed xy3NftId,
        StatusType newStatus
    );

    uint32 public totalNumLoans = 10000;
    mapping(uint32 => LoanState) private loanStatus;

    /**
     * @dev XY3 mint a NFT to the lender as a ticket for collateral
     * @param _lender Lender address
     * @param _borrower Borrower address
     */
    function createLoan(address _lender, address _borrower) internal returns (uint32) {
        // skip 0, loanIds start from 1
        totalNumLoans += 1;

        uint64 xy3NftId = uint64(
            uint256(keccak256(abi.encodePacked(address(this), totalNumLoans)))
        );

        LoanState memory newLoan = LoanState({
            status: StatusType.NEW,
            xy3NftId: xy3NftId
        });

        (Xy3Nft borrowerNote, Xy3Nft lenderNote) = getNotes();
        // Mint an ERC721 to the lender as the ticket for the collateral
        lenderNote.mint(
            _lender,
            xy3NftId,
            abi.encode(totalNumLoans)
        );

        // Mint an ERC721 to the borrower as the ticket for the collateral
        borrowerNote.mint(
            _borrower,
            xy3NftId,
            abi.encode(totalNumLoans)
        );

        loanStatus[totalNumLoans] = newLoan;
        emit UpdateStatus(totalNumLoans, xy3NftId, StatusType.NEW);

        return totalNumLoans;
    }

    /**
     * @dev XY3 close the loan when load paid
     * Update the loan status to be RESOLVED and burns Xy3Nft token.
     * @param _loanId - Id of loan
     */
    function resolveLoan(uint32 _loanId) internal {
        LoanState storage loan = loanStatus[_loanId];
        require(loan.status == StatusType.NEW, "Loan is not a new one");

        loan.status = StatusType.RESOLVED;
        (Xy3Nft borrowerNote, Xy3Nft lenderNote) = getNotes();
        lenderNote.burn(loan.xy3NftId);
        borrowerNote.burn(loan.xy3NftId);

        emit UpdateStatus(_loanId, loan.xy3NftId, StatusType.RESOLVED);
        delete loanStatus[_loanId];
    }

    /**
     * @dev Get loan state for a given id.
     * @param _loanId The given load Id.
     */
    function getLoanState(uint32 _loanId)
        public
        view
        override
        returns (LoanState memory)
    {
        return loanStatus[_loanId];
    }

    function getNotes() private view returns(Xy3Nft borrowerNote, Xy3Nft lenderNote) {
        IAddressProvider addressProvider = IConfig(address(this)).getAddressProvider();
        borrowerNote = Xy3Nft(addressProvider.getBorrowerNote());
        lenderNote = Xy3Nft(addressProvider.getLenderNote());
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

/**
 * @dev Role for interceptor contracts
 */
bytes32 constant INTERCEPTOR_ROLE = keccak256("INTERCEPTOR");
/**
 * @dev Role for configration management.
 */
bytes32 constant MANAGER_ROLE = keccak256("MANAGER");
/**
 * @dev Role for singed, used by the main contract.
 */
bytes32 constant SIGNER_ROLE = keccak256("SIGNER");

/**
 * @dev Role for calling transfer delegator
 */
bytes32 constant DELEGATION_CALLER_ROLE = keccak256("DELEGATION_CALLER");

/**
 * @dev Role for xy3nft minter
 */
bytes32 constant MINTER_ROLE = keccak256("MINTER");

/**
 * @dev Role for those can call exchange contracts
 */
bytes32 constant EXCHANGE_CALLER_ROLE = keccak256("EXCHANGE_CALLER");

/**
 * @dev Role for those can be called by FlashTrade
 */
bytes32 constant FLASH_TRADE_CALLEE_ROLE = keccak256("FLASH_TRADE_CALLEE");

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import {Offer, Signature} from "../DataTypes.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

/**
 * @title  SigningUtils
 * @author XY3
 * @notice Helper functions for signature.
 */
library SigningUtils {
    /**
     * @dev Get the current chain ID.
     */
    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    /**
     * @dev check signature without nftId.
     * @param _offer  The offer data
     * @param _nftId The NFT Id
     * @param _signature The signature data
     */

    function offerSignatureIsValid(
        Offer memory _offer,
        uint256 _nftId,
        Signature memory _signature
    ) public view returns(bool) {
        require(block.timestamp <= _signature.expiry, "Signature expired");
        if (_signature.signer == address(0)) {
            return false;
        } else {
            bytes32 message = keccak256(
                abi.encodePacked(getEncodedOffer(_offer), _nftId, getEncodedSignature(_signature), address(this), getChainID())
            );
            return
                SignatureChecker.isValidSignatureNow(
                    _signature.signer,
                    ECDSA.toEthSignedMessageHash(message),
                    _signature.signature
                );
        }
    }

    /**
     * @dev check signature without nftId.
     * @param _offer  The offer data
     * @param _signature - The signature data
     */
    function offerSignatureIsValid(
        Offer memory _offer,
        Signature memory _signature
    ) public view returns (bool) {
        require(block.timestamp <= _signature.expiry, "Signature has expired");
        if (_signature.signer == address(0)) {
            return false;
        } else {
            bytes32 message = keccak256(
                abi.encodePacked(getEncodedOffer(_offer), getEncodedSignature(_signature), address(this), getChainID())
            );

            return
                SignatureChecker.isValidSignatureNow(
                    _signature.signer,
                    ECDSA.toEthSignedMessageHash(message),
                    _signature.signature
                );
        }
    }

    /**
     * @dev Helper function.
     */
    function getEncodedOffer(Offer memory _offer) internal pure returns (bytes memory data) {
            data = 
                abi.encodePacked(
                    _offer.borrowAsset,
                    _offer.borrowAmount,
                    _offer.repayAmount,
                    _offer.nftAsset,
                    _offer.borrowDuration,
                    _offer.timestamp,
                    _offer.extra
                );
    }

    /**
     * @dev Helper function.
     */
    function getEncodedSignature(Signature memory _signature) internal pure returns (bytes memory) {
        return abi.encodePacked(_signature.signer, _signature.nonce, _signature.expiry);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "./interfaces/IXY3.sol";
import "./interfaces/IDelegateV3.sol";
import "./interfaces/IAddressProvider.sol";
import "./interfaces/IServiceFee.sol";
import {IFlashExecPermits} from "./interfaces/IFlashExecPermits.sol";
import "./DataTypes.sol";
import "./LoanStatus.sol";
import "./Config.sol";
import "./utils/SigningUtils.sol";
import {InterceptorManager} from "./InterceptorManager.sol";
import {SIGNER_ROLE} from "./Roles.sol";

/**
 * @title  XY3
 * @author XY3
 * @notice Main contract for XY3 lending.
 */
contract XY3 is
    IXY3,
    Config,
    LoanStatus,
    InterceptorManager,
    ERC721Holder,
    ERC1155Holder
{
    using SafeERC20 for IERC20;

    /**
     * @notice A mapping from a loan's identifier to the loan's terms, represted by the LoanTerms struct.
     */
    mapping(uint32 => LoanDetail) public override loanDetails;

    /**
     * @notice A mapping, (collection address, token Id) -> loan ID.
     */
    mapping(address => mapping(uint256 => uint32)) public override loanIds;

    /**
     * @notice A mapping, (user address , nonce) -> boolean.
     */
    mapping(address => mapping(uint256 => bool)) internal _invalidNonce;

    /**
     * @notice A mapping that takes a user's address and a cancel timestamp.
     *
     */
    mapping(address => uint256) internal _offerCancelTimestamp;

    /**
     * modifier
     */
    modifier loanIsOpen(uint32 _loanId) {
        require(
            getLoanState(_loanId).status == StatusType.NEW,
            "Loan is not open"
        );
        _;
    }

    /**
     * @dev Init contract
     *
     * @param _admin - Initial admin of this contract.
     * @param _addressProvider - AddressProvider contract
     */
    constructor(
        address _admin,
        address _addressProvider
    )
        Config(_admin, _addressProvider)
        LoanStatus()
        InterceptorManager()
    {
    }

    /**
     PUBLIC FUNCTIONS
     */

    /**
     * @dev The borrower accept a lender's offer to create a loan.
     *
     * @param _offer - The offer made by the lender.
     * @param _nftId - The ID
     * @param _isCollectionOffer - Wether the offer is a collection offer.
     * @param _lenderSignature - The lender's signature.
     * @param _brokerSignature - The broker's signature.
     * @param _extraDeal - Create a new loan by getting a NFT colleteral from external contract call.
     * The external contract can be lending market or deal market, specially included the restricted repay of myself.
     * But should not be the Xy3Nft.mint, though this contract maybe have the permission.
     */
    function borrow(
        Offer calldata _offer,
        uint256 _nftId,
        bool _isCollectionOffer,
        Signature calldata _lenderSignature,
        Signature calldata _brokerSignature,
        CallData calldata _extraDeal
    ) external override whenNotPaused nonReentrant returns (uint32) {
        _loanSanityChecks(_offer);
        address nftAsset = _offer.nftAsset;

        beforeBorrow(nftAsset, _nftId);
        LoanDetail memory _loanDetail = _createLoanDetail(
            _offer,
            _nftId,
            _isCollectionOffer
        );
        _checkBorrow(
            _offer,
            _nftId,
            _isCollectionOffer,
            _lenderSignature,
            _brokerSignature
        );

        IAddressProvider addressProvider = getAddressProvider();
        IDelegateV3(addressProvider.getTransferDelegate()).erc20Transfer(
            _lenderSignature.signer,
            msg.sender,
            _offer.borrowAsset,
            _offer.borrowAmount
        );

        if (_extraDeal.target != address(0)) {
            require(getAgentPermit(_extraDeal.target, _extraDeal.selector), "Not valide agent");
            bytes memory data = abi.encodeWithSelector(
                _extraDeal.selector,
                msg.sender,
                _extraDeal.data
            );
            (bool succ, ) = _extraDeal.target.call(data);
            require(succ, "Borrow extra call failed");
        }
        IDelegateV3(addressProvider.getTransferDelegate()).erc721Transfer(
            msg.sender,
            address(this),
            nftAsset,
            _nftId
        );

        uint32 loanId = _createBorrowNote(
            _lenderSignature.signer,
            msg.sender,
            _loanDetail,
            _lenderSignature,
            _extraDeal
        );

        _serviceFee(_offer, loanId, _extraDeal.target);

        loanIds[nftAsset][_nftId] = loanId;
        afterBorrow(nftAsset, _nftId);
        emit BorrowRefferal(loanId, msg.sender, _extraDeal.referral);

        return loanId;
    }

    /**
     * @dev Restricted function, only called by self from borrow with target.
     * @param _sender  The borrow's msg.sender.
     * @param _param  The borrow CallData's data, encode loadId only.
     */
    function repay(address _sender, bytes calldata _param) external {
        require(msg.sender == address(this), "Invalide caller");
        uint32 loanId = abi.decode(_param, (uint32));
        _repay(_sender, loanId);
    }

    /**
     * @dev Public function for anyone to repay a loan, and return the NFT token to origin borrower.
     * @param _loanId  The loan Id.
     */
    function repay(uint32 _loanId) public override nonReentrant {
        _repay(msg.sender, _loanId);
    }

    /**
     * @dev Lender ended the load which not paid by borrow and expired.
     *
     * @param _loanId The loan Id.
     */
    function liquidate(
        uint32 _loanId
    ) external override nonReentrant loanIsOpen(_loanId) {
        (
            address borrower,
            address lender,
            LoanDetail memory loan
        ) = _getPartiesAndData(_loanId);
        address nftAsset = loan.nftAsset;
        uint nftId = loan.nftTokenId;
        beforeLiquidate(nftAsset, nftId);

        uint256 loanMaturityDate = _loanMaturityDate(loan);
        require(block.timestamp > loanMaturityDate, "Loan is not overdue yet");

        require(msg.sender == lender, "Only lender can liquidate");

        // Emit an event with all relevant details from this transaction.
        emit LoanLiquidated(
            _loanId,
            borrower,
            lender,
            loan.borrowAmount,
            nftId,
            loanMaturityDate,
            block.timestamp,
            nftAsset
        );

        // nft to lender
        IERC721(nftAsset).safeTransferFrom(address(this), lender, nftId);
        _resolveLoanNote(_loanId);
        delete loanIds[nftAsset][nftId];

        afterLiquidate(nftAsset, nftId);
    }

    /**
     * @dev Flash out the colleteral NFT.
     *
     * @param _loanId The loan Id.
     * @param _target The target contract.
     * @param _selector The callback selector.
     * @param _data The callback data.
     */
    function flashExecute(
        uint32 _loanId,
        address _target,
        bytes4 _selector,
        bytes memory _data
    ) external {
        (address borrower, , LoanDetail memory loan) = _getPartiesAndData(
            _loanId
        );
        IAddressProvider addressProvider = getAddressProvider();
        require(
            IFlashExecPermits(addressProvider.getFlashExecPermits())
                .isPermitted(_target, _selector),
            "Invalid airdrop target"
        );
        require(block.timestamp <= _loanMaturityDate(loan), "Loan is expired");
        require(msg.sender == borrower, "Only borrower");
        IERC721(loan.nftAsset).safeTransferFrom(
            address(this),
            _target,
            loan.nftTokenId
        );
        (bool succ, ) = _target.call(
            abi.encodeWithSelector(_selector, msg.sender, _data)
        );
        require(succ, "External call failed");
        address owner = IERC721(loan.nftAsset).ownerOf(loan.nftTokenId);
        require(owner == address(this), "Nft not returned");
        emit FlashExecute(_loanId, loan.nftAsset, loan.nftTokenId, _target);
    }

    /**
     * @dev A lender or a borrower to cancel all off-chain orders signed that contain this nonce.
     * @param  _nonce - User nonce
     */
    function cancelByNonce(uint256 _nonce) external override {
        require(!_invalidNonce[msg.sender][_nonce], "Invalid nonce");
        _invalidNonce[msg.sender][_nonce] = true;
        emit NonceCancelled(msg.sender, _nonce);
    }

    /**
     * @dev A borrower cancel all offers with timestamp before the _timestamp parameter.
     * @param _timestamp - cancelled timestamp
     */
    function cancelByTimestamp(uint256 _timestamp) external override {
        require(_timestamp < block.timestamp, "Invalid timestamp");
        if (_timestamp > _offerCancelTimestamp[msg.sender]) {
            _offerCancelTimestamp[msg.sender] = _timestamp;
            emit TimeStampCancelled(msg.sender, _timestamp);
        }
    }

    /**
     * @dev The amount of ERC20 currency for the loan.
     *
     * @param _loanId  loan Id.
     * @return The amount of ERC20 currency.
     */
    function getRepayAmount(
        uint32 _loanId
    ) external view override returns (uint256) {
        LoanDetail storage loan = loanDetails[_loanId];
        return loan.repayAmount;
    }

    /**
     * @notice Check a nonce has been used or not
     * @param _user - The user address.
     * @param _nonce - The order Id.
     *
     * @return A bool for used or not.
     */
    function getNonceUsed(
        address _user,
        uint256 _nonce
    ) external view override returns (bool) {
        return _invalidNonce[_user][_nonce];
    }

    /**
     * @dev This function can be used to view the last cancel timestamp a borrower has set.
     * @param _user User address
     * @return The cancel timestamp
     */
    function getTimestampCancelled(
        address _user
    ) external view override returns (uint256) {
        return _offerCancelTimestamp[_user];
    }

    /**
     * @dev Claim the ERC20 airdrop by admin timelock.
     * @param  _to - Receiver address
     * @param  tokens - Claimed token list
     * @param  amounts - Clamined amount list
     */
    function adminClaimErc20(
        address _to,
        address[] memory tokens,
        uint256[] memory amounts
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_to != address(0x0), "Invalid address");
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            IERC20(token).safeTransfer(_to, amounts[i]);
        }
    }

    /**
     * @dev Claim the ERC721 airdrop by admin timelock.
     * @param  _to - Receiver address
     * @param  tokens - Claimed token list
     * @param  tokenIds - Clamined ID list
     */
    function adminClaimErc721(
        address _to,
        address[] memory tokens,
        uint256[] memory tokenIds
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 tokenId = tokenIds[i];
            uint32 loanId = loanIds[token][tokenId];
            if (loanId == 0) {
                IERC721(token).safeTransferFrom(
                    address(this),
                    _to,
                    tokenIds[i]
                );
            }
        }
    }

    /**
     * @dev Claim the ERC1155 airdrop by admin timelock.
     * @param  _to - Receiver address
     * @param  tokens - Claimed token list
     * @param  tokenIds - Clamined ID list
     * @param  amounts - Clamined amount list
     */
    function adminClaimErc1155(
        address _to,
        address[] memory tokens,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            IERC1155(token).safeTransferFrom(
                address(this),
                _to,
                tokenIds[i],
                amounts[i],
                ""
            );
        }
    }

    /**
     * @dev ERC165 support
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControl, ERC1155Receiver)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @param _loanId  Load Id.
     */
    function _resolveLoanNote(uint32 _loanId) internal {
        resolveLoan(_loanId);
        delete loanDetails[_loanId];
    }

    /**
     * @dev Check loan parameters validation
     *
     */
    function _loanSanityChecks(Offer memory _offer) internal view {
        require(getERC20Permit(_offer.borrowAsset), "Invalid currency");
        require(getERC721Permit(_offer.nftAsset), "Invalid ERC721 token");
        require(
            uint256(_offer.borrowDuration) <= maxBorrowDuration,
            "Invalid maximum duration"
        );
        require(
            uint256(_offer.borrowDuration) >= minBorrowDuration,
            "Invalid minimum duration"
        );
        require(
            _offer.repayAmount >= _offer.borrowAmount,
            "Invalid interest rate"
        );
    }

    function _getPartiesAndData(
        uint32 _loanId
    )
        internal
        view
        returns (address borrower, address lender, LoanDetail memory loan)
    {
        uint256 xy3NftId = getLoanState(_loanId).xy3NftId;
        loan = loanDetails[_loanId];

        borrower = IERC721(getAddressProvider().getBorrowerNote()).ownerOf(xy3NftId);
        lender = IERC721(getAddressProvider().getLenderNote()).ownerOf(xy3NftId);
    }

    /**
     * @dev Get the payoff amount and admin fee
     * @param _loanDetail - Loan parameters
     */
    function _payoffAndFee(
        LoanDetail memory _loanDetail
    ) internal pure returns (uint256 adminFee, uint256 payoffAmount) {
        uint256 interestDue = _loanDetail.repayAmount -
            _loanDetail.borrowAmount;
        adminFee = (interestDue * _loanDetail.adminShare) / HUNDRED_PERCENT;
        payoffAmount = _loanDetail.repayAmount - adminFee;
    }

    /**
     * @param _offer - Offer parameters
     * @param _nftId - NFI ID
     * @param _isCollection - is collection or not
     * @param _lenderSignature - lender signature
     * @param _brokerSignature - broker signature
     */
    function _checkBorrow(
        Offer memory _offer,
        uint256 _nftId,
        bool _isCollection,
        Signature memory _lenderSignature,
        Signature memory _brokerSignature
    ) internal view {
        address _lender = _lenderSignature.signer;

        require(
            !_invalidNonce[_lender][_lenderSignature.nonce],
            "Lender nonce invalid"
        );
        require(
            hasRole(SIGNER_ROLE, _brokerSignature.signer),
            "Invalid broker signer"
        );
        require(
            _offerCancelTimestamp[_lender] < _offer.timestamp,
            "Offer cancelled"
        );

        _checkSignatures(
            _offer,
            _nftId,
            _isCollection,
            _lenderSignature,
            _brokerSignature
        );
    }

    function _createBorrowNote(
        address _lender,
        address _borrower,
        LoanDetail memory _loanDetail,
        Signature memory _lenderSignature,
        CallData memory _extraDeal
    ) internal returns (uint32) {
        _invalidNonce[_lender][_lenderSignature.nonce] = true;
        // Mint ERC721 note to the lender and borrower
        uint32 loanId = createLoan(_lender, _borrower);
        // Record
        loanDetails[loanId] = _loanDetail;
        emit LoanStarted(
            loanId,
            msg.sender,
            _lenderSignature.signer,
            _lenderSignature.nonce,
            _loanDetail,
            _extraDeal.target,
            _extraDeal.selector
        );

        return loanId;
    }

    function _repay(
        address payer,
        uint32 _loanId
    ) internal loanIsOpen(_loanId) {
        (
            address borrower,
            address lender,
            LoanDetail memory loan
        ) = _getPartiesAndData(_loanId);
        require(block.timestamp <= _loanMaturityDate(loan), "Loan is expired");

        address nftAsset = loan.nftAsset;
        uint nftId = loan.nftTokenId;

        beforeRepay(nftAsset, nftId);
        IERC721(nftAsset).safeTransferFrom(address(this), borrower, nftId);

        // pay from the payer
        _repayAsset(payer, borrower, lender, _loanId, loan);
        _resolveLoanNote(_loanId);
        delete loanIds[nftAsset][nftId];
        afterRepay(nftAsset, nftId);
    }

    function _repayAsset(
        address payer,
        address borrower,
        address lender,
        uint32 _loanId,
        LoanDetail memory loan
    ) internal {
        (uint256 adminFee, uint256 payoffAmount) = _payoffAndFee(loan);
        IAddressProvider addressProvider = getAddressProvider();
        // Paid back to lender
        IDelegateV3(addressProvider.getTransferDelegate()).erc20Transfer(
            payer,
            lender,
            loan.borrowAsset,
            payoffAmount
        );
        // Transfer admin fee
        IDelegateV3(addressProvider.getTransferDelegate()).erc20Transfer(
            payer,
            adminFeeReceiver,
            loan.borrowAsset,
            adminFee
        );

        emit LoanRepaid(
            _loanId,
            borrower,
            lender,
            loan.borrowAmount,
            loan.nftTokenId,
            payoffAmount,
            adminFee,
            loan.nftAsset,
            loan.borrowAsset
        );
    }

    /**
     * @param _offer - Offer parameters
     * @param _nftId - NFI ID
     * @param _isCollection - is collection or not
     * @param _lenderSignature - lender signature
     * @param _brokerSignature - broker signature
     */
    function _checkSignatures(
        Offer memory _offer,
        uint256 _nftId,
        bool _isCollection,
        Signature memory _lenderSignature,
        Signature memory _brokerSignature
    ) private view {
        if (_isCollection) {
            require(
                SigningUtils.offerSignatureIsValid(_offer, _lenderSignature),
                "Lender signature is invalid"
            );
        } else {
            require(
                SigningUtils.offerSignatureIsValid(
                    _offer,
                    _nftId,
                    _lenderSignature
                ),
                "Lender signature is invalid"
            );
        }
        require(
            SigningUtils.offerSignatureIsValid(
                _offer,
                _nftId,
                _brokerSignature
            ),
            "Signer signature is invalid"
        );
    }

    /**
     * @param _offer - Offer parameters
     * @param _nftId - NFI ID
     * @param _isCollection - is collection or not
     */
    function _createLoanDetail(
        Offer memory _offer,
        uint256 _nftId,
        bool _isCollection
    ) internal view returns (LoanDetail memory) {
        return
            LoanDetail({
                borrowAsset: _offer.borrowAsset,
                borrowAmount: _offer.borrowAmount,
                repayAmount: _offer.repayAmount,
                nftAsset: _offer.nftAsset,
                nftTokenId: _nftId,
                loanStart: uint64(block.timestamp),
                loanDuration: _offer.borrowDuration,
                adminShare: adminShare,
                isCollection: _isCollection
            });
    }

    /**
     * @param loan - Loan parameters
     */
    function _loanMaturityDate(
        LoanDetail memory loan
    ) private pure returns (uint256) {
        return uint256(loan.loanStart) + uint256(loan.loanDuration);
    }

    function _serviceFee(Offer memory offer, uint32 loanId, address target) internal {
        if (target != address(0)) {
            IAddressProvider addressProvider = getAddressProvider();
            address nftAsset = offer.nftAsset;
            uint256 borrowAmount = offer.borrowAmount;
            address borrowAsset = offer.borrowAsset;
            address serviceFeeAddr = addressProvider.getServiceFee();
            uint16 serviceFeeRate = 0;
            uint256 fee = 0;
            if(serviceFeeAddr != address(0)) {
                serviceFeeRate = IServiceFee(serviceFeeAddr).getServiceFee(
                    target,
                    msg.sender,
                    nftAsset
                );
                if(serviceFeeRate > 0) {
                    fee = borrowAmount * serviceFeeRate / HUNDRED_PERCENT;
                    IDelegateV3(addressProvider.getTransferDelegate()).erc20Transfer(
                        msg.sender,
                        adminFeeReceiver,
                        borrowAsset,
                        fee
                    );
                }

                emit ServiceFee(loanId, target, serviceFeeRate, fee);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title Xy3Nft
 * @author XY3
 * @dev ERC721 token for promissory note.
 */
contract Xy3Nft is ERC721, AccessControl {
    using Strings for uint256;

    /**
     * @dev Record the data for findig the loan linked to a Xy3.
     */
    struct Ticket {
        uint256 loanId;
        address minter;
    }

    /**
     * @dev base URI for token
     */
    string public baseURI;

    /*
     * @dev map Xy3Id to Ticket
     */
    mapping(uint256 => Ticket) public tickets;

    /**
     * @dev Role for token URI and mint
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER");
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER");

    /**
     * @dev Init the contract and set the default admin role.
     *
     * @param _admin Admin role account
     * @param _name Xy3NFT name
     * @param _symbol Xy3NFT symbol
     * @param _customBaseURI Xy3NFT Base URI
     */
    constructor(
        address _admin,
        string memory _name,
        string memory _symbol,
        string memory _customBaseURI
    ) ERC721(_name, _symbol) {
        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
        _setBaseURI(_customBaseURI);
    }

    /**
     * @dev Burn token by minter.
     * @param _tokenId The ERC721 token Id
     */
    function burn(uint256 _tokenId) external onlyRole(MINTER_ROLE) {
        delete tickets[_tokenId];
        _burn(_tokenId);
    }

    /**
     * @dev Mint a new token and assigned to receiver
     *
     * @param _to The receiver address
     * @param _tokenId The token ID of the Xy3 
     * @param _data The first 32 bytes is an integer for the loanId in Xy3
     */
    function mint(
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external onlyRole(MINTER_ROLE) {
        require(_data.length > 0, "no data");

        uint256 loanId = abi.decode(_data, (uint256));
        tickets[_tokenId] = Ticket({loanId: loanId, minter: msg.sender});
        _safeMint(_to, _tokenId, _data);
    }

    /**
     * @dev Set baseURI by URI manager
     * @param _customBaseURI - Base URI for the Xy3NFT
     */
    function setBaseURI(string memory _customBaseURI)
        external
        onlyRole(MANAGER_ROLE)
    {
        _setBaseURI(_customBaseURI);
    }

    /**
     * @dev Defined by IERC165
     * @param _interfaceId The queried selector Id
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool) 
    {
        return super.supportsInterface(_interfaceId);
    }

    /**
     * @dev Check the token exist or not.
     * @param _tokenId The ERC721 token id
     */
    function exists(uint256 _tokenId)
        external
        view
        returns (bool)
    {
        return _exists(_tokenId);
    }

    /**
     * @dev Get the current chain ID.
     */
    function _getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    /** 
     * @dev Base URI for concat {tokenURI} by `baseURI` and `tokenId`.
     */
    function _baseURI()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return baseURI;
    }

    /**
     * @dev Set baseURI, internal used.
     * @param _customBaseURI The new URI.
     */
    function _setBaseURI(string memory _customBaseURI) internal virtual {
        baseURI = bytes(_customBaseURI).length > 0
            ? string(abi.encodePacked(_customBaseURI, _getChainID().toString(), "/"))
            : "";
    }
}