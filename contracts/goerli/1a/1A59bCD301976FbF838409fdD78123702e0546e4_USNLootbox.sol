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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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
pragma solidity ^0.8.18;

import "../INTERFACES/IPermissions.sol";
import "../lib/USNStrings.sol";

/**
 *  @title Permissions
 *  @dev This contracts provides extending-contracts with role-based access control mechanisms
 */
contract Permissions is IPermissions {
    /// @dev Map from keccak256 hash of a role => a map from address => whether address has role.
    mapping(bytes32 => mapping(address => bool)) private _hasRole;

    /// @dev Map from keccak256 hash of a role to role admin. See {getRoleAdmin}.
    mapping(bytes32 => bytes32) private _getRoleAdmin;

    /// @dev Default admin role for all roles. Only accounts with this role can grant/revoke other roles.
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /// @dev Modifier that checks if an account has the specified role; reverts otherwise.
    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
    }

    /**
     *  @notice Checks whether an account has a particular role.
     *  @param role keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account Address of the account for which the role is being checked.
     */
    function hasRole(
        bytes32 role,
        address account
    ) public view override returns (bool) {
        return _hasRole[role][account];
    }

    /**
     *  @notice Checks whether an account has a particular role; role restrictions can be swtiched on and off
     *  @param role keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account Address of the account for which the role is being checked.
     */
    function hasRoleWithSwitch(
        bytes32 role,
        address account
    ) public view returns (bool) {
        if (!_hasRole[role][address(0)]) {
            return _hasRole[role][account];
        }

        return true;
    }

    /**
     *  @notice  Returns the admin role that controls the specified role
     *  @param role keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     */
    function getRoleAdmin(
        bytes32 role
    ) external view override returns (bytes32) {
        return _getRoleAdmin[role];
    }

    /**
     *  @notice Grants a role to an account, if not previously granted
     *  @param role keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account Address of the account to which the role is being granted
     */
    function grantRole(bytes32 role, address account) public virtual override {
        _checkRole(_getRoleAdmin[role], msg.sender);
        if (_hasRole[role][account]) {
            revert("Can only grant to non holders");
        }
        _setupRole(role, account);
    }

    /**
     *  @notice Revokes role from an account
     *  @param role keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account Address of the account from which the role is being revoked
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        _checkRole(_getRoleAdmin[role], msg.sender);
        _revokeRole(role, account);
    }

    /**
     *  @notice Revokes role from the account
     *  @param role keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param account Address of the account from which the role is being revoked
     */
    function renounceRole(
        bytes32 role,
        address account
    ) public virtual override {
        if (msg.sender != account) {
            revert("Can only renounce for self");
        }
        _revokeRole(role, account);
    }

    /// @dev Sets `adminRole` as `role`'s admin role.
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = _getRoleAdmin[role];
        _getRoleAdmin[role] = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /// @dev Sets up `role` for `account`
    function _setupRole(bytes32 role, address account) internal virtual {
        _hasRole[role][account] = true;
        emit RoleGranted(role, account, msg.sender);
    }

    /// @dev Revokes `role` from `account`
    function _revokeRole(bytes32 role, address account) internal virtual {
        _checkRole(role, account);
        delete _hasRole[role][account];
        emit RoleRevoked(role, account, msg.sender);
    }

    /// @dev Checks `role` for `account`. Reverts with a message including the required role.
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_hasRole[role][account]) {
            revert(
                string(
                    abi.encodePacked(
                        "Permissions: account ",
                        USNStrings.toHexString(uint160(account), 20),
                        " is missing role ",
                        USNStrings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /// @dev Checks `role` for `account`. Reverts with a message including the required role.
    function _checkRoleWithSwitch(
        bytes32 role,
        address account
    ) internal view virtual {
        if (!hasRoleWithSwitch(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "Permissions: account ",
                        USNStrings.toHexString(uint160(account), 20),
                        " is missing role ",
                        USNStrings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../INTERFACES/IPermissionsEnumerable.sol";
import "./Permissions.sol";

/**
 *  @title PermissionsEnumerable
 *  @dev This contracts provides extending-contracts with role-based access control mechanisms
 *       Also provides INTERFACES to view all members with a given role, and total count of members
 */
contract PermissionsEnumerable is IPermissionsEnumerable, Permissions {
    /**
     *  @notice A data structure to store data of members for a given role
     *  @param index Current index in the list of accounts that have a role
     *  @param members map from index => address of account that has a role
     *  @param indexOf map from address => index which the account has
     */
    struct RoleMembers {
        uint256 index;
        mapping(uint256 => address) members;
        mapping(address => uint256) indexOf;
    }

    /// @dev map from keccak256 hash of a role to its members' data. See {RoleMembers}.
    mapping(bytes32 => RoleMembers) private roleMembers;

    /**
     *  @notice Returns the role-member from a list of members for a role, at a given index
     *  @param role keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @param index Index in list of current members for the role
     *  @return member  Address of account that has `role`
     */
    function getRoleMember(
        bytes32 role,
        uint256 index
    ) external view override returns (address member) {
        uint256 currentIndex = roleMembers[role].index;
        uint256 check;

        for (uint256 i; i < currentIndex; ) {
            if (roleMembers[role].members[i] != address(0)) {
                if (check == index) {
                    member = roleMembers[role].members[i];
                    return member;
                }
                check += 1;
            } else if (
                hasRole(role, address(0)) &&
                i == roleMembers[role].indexOf[address(0)]
            ) {
                check += 1;
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     *  @notice Returns total number of accounts that have a role
     *  @param role keccak256 hash of the role. e.g. keccak256("TRANSFER_ROLE")
     *  @return count Total number of accounts that have `role`
     */
    function getRoleMemberCount(
        bytes32 role
    ) external view override returns (uint256 count) {
        uint256 currentIndex = roleMembers[role].index;

        for (uint256 i; i < currentIndex; ) {
            if (roleMembers[role].members[i] != address(0)) {
                count += 1;
            }
            unchecked {
                ++i;
            }
        }
        if (hasRole(role, address(0))) {
            count += 1;
        }
    }

    /// @dev Revokes `role` from `account`, and removes `account` from {roleMembers}
    function _revokeRole(bytes32 role, address account) internal override {
        super._revokeRole(role, account);
        _removeMember(role, account);
    }

    /// @dev Grants `role` to `account`, and adds `account` to {roleMembers}
    function _setupRole(bytes32 role, address account) internal override {
        super._setupRole(role, account);
        _addMember(role, account);
    }

    /// @dev adds `account` to {roleMembers}, for `role`
    function _addMember(bytes32 role, address account) internal {
        uint256 idx = roleMembers[role].index;
        roleMembers[role].index += 1;

        roleMembers[role].members[idx] = account;
        roleMembers[role].indexOf[account] = idx;
    }

    /// @dev removes `account` from {roleMembers}, for `role`
    function _removeMember(bytes32 role, address account) internal {
        uint256 idx = roleMembers[role].indexOf[account];

        delete roleMembers[role].members[idx];
        delete roleMembers[role].indexOf[account];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../INTERFACES/IProtocolFee.sol";

/*
$$$$$$$\            $$\         $$\            $$$$$$\    $$\                     $$\ $$\                     
$$  __$$\           $$ |        $$ |          $$  __$$\   $$ |                    $$ |\__|                    
$$ |  $$ | $$$$$$\  $$ |  $$\ $$$$$$\         $$ /  \__|$$$$$$\   $$\   $$\  $$$$$$$ |$$\  $$$$$$\   $$$$$$$\ 
$$$$$$$  |$$  __$$\ $$ | $$  |\_$$  _|        \$$$$$$\  \_$$  _|  $$ |  $$ |$$  __$$ |$$ |$$  __$$\ $$  _____|
$$  __$$< $$$$$$$$ |$$$$$$  /   $$ |           \____$$\   $$ |    $$ |  $$ |$$ /  $$ |$$ |$$ /  $$ |\$$$$$$\  
$$ |  $$ |$$   ____|$$  _$$<    $$ |$$\       $$\   $$ |  $$ |$$\ $$ |  $$ |$$ |  $$ |$$ |$$ |  $$ | \____$$\ 
$$ |  $$ |\$$$$$$$\ $$ | \$$\   \$$$$  |      \$$$$$$  |  \$$$$  |\$$$$$$  |\$$$$$$$ |$$ |\$$$$$$  |$$$$$$$  |
\__|  \__| \_______|\__|  \__|   \____/        \______/    \____/  \______/  \_______|\__| \______/ \_______/                                                                                                                                                                     
*/

/**
 *  @title ProtocolFee Contract
 *  @notice Unseen ProtocolFee contract - to be used with any service contract to implement protocol fees
 *  @author Unseen | decapinator.eth
 **/
abstract contract ProtocolFee is IProtocolFee {
    /// @dev The address that receives all protocol fees from all service txs
    address private protocolFeeRecipient;

    /// @dev The % collected as protocol fees
    uint16 private protocolFeeBps;

    /// @dev Returns the protocol fee recipient and bps
    function getProtocolFeeInfo()
        public
        view
        override
        returns (address, uint16)
    {
        return (protocolFeeRecipient, uint16(protocolFeeBps));
    }

    /**
     *  @notice Updates the protocol fee recipient and bps
     *  @param _protocolFeeRecipient Address to be set as new protocolFeeRecipient
     *  @param _protocolFeeBps Updated protocolFeeBps.
     */
    function setProtocolFeeInfo(
        address _protocolFeeRecipient,
        uint16 _protocolFeeBps
    ) external override {
        if (!_canSetProtocolFeeInfo()) {
            revert("Not authorized");
        }
        _setupProtocolFeeInfo(_protocolFeeRecipient, _protocolFeeBps);
    }

    /// @dev Lets a contract admin update the protocol fee recipient and bps
    function _setupProtocolFeeInfo(
        address _protocolFeeRecipient,
        uint256 _protocolFeeBps
    ) internal {
        if (_protocolFeeBps > 10_000) {
            revert("Exceeds max bps");
        }

        protocolFeeBps = uint16(_protocolFeeBps);
        protocolFeeRecipient = _protocolFeeRecipient;

        emit ProtocolFeeInfoUpdated(_protocolFeeRecipient, _protocolFeeBps);
    }

    function changeProtocolFeeRecipient(
        address _protocolFeeRecipient
    ) external override {
        if (!_canSetProtocolFeeInfo()) {
            revert("Not authorized");
        }
        require(
            protocolFeeRecipient != _protocolFeeRecipient,
            "USN: Recipient is already set to the desired address"
        );
        emit ProtocolFeeRecipientUpdated(_protocolFeeRecipient);
        protocolFeeRecipient = _protocolFeeRecipient;
    }

    function changeProtocolFeeBps(uint16 _protocolFeeBps) external override {
        if (!_canSetProtocolFeeInfo()) {
            revert("Not authorized");
        }
        require(
            protocolFeeBps != _protocolFeeBps,
            "USN: Fee is already set to the desired amount"
        );
        emit ProtocolFeeBpsUpdated(_protocolFeeBps);
        protocolFeeBps = _protocolFeeBps;
    }

    /// @dev Returns whether protocol fee info can be set in the given execution context.
    function _canSetProtocolFeeInfo() internal view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../INTERFACES/ITokenBundle.sol";
import "../lib/CurrencyTransferLib.sol";

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 *  @title   Token Bundle
 *  @notice  `TokenBundle` contract extension allows bundling-up of ERC20/ERC721/ERC1155 and native-tokan assets
 *           in a data structure, and provides logic for setting/getting IDs for created bundles
 */

abstract contract TokenBundle is ITokenBundle {
    /// @dev Mapping from bundle UID => bundle info.
    mapping(uint256 => BundleInfo) private bundle;

    /// @dev Returns the total number of assets in a particular bundle.
    function getTokenCountOfBundle(
        uint256 _bundleId
    ) public view returns (uint256) {
        return bundle[_bundleId].count;
    }

    /// @dev Returns an asset contained in a particular bundle, at a particular index.
    function getTokenOfBundle(
        uint256 _bundleId,
        uint256 index
    ) public view returns (Token memory) {
        return bundle[_bundleId].tokens[index];
    }

    function bundleIsActive(uint256 _bundleId) public view returns (bool) {
        return bundle[_bundleId].bundleIsActive;
    }

    /// @dev Lets the calling contract create a bundle, by passing in a list of tokens and a unique id.
    function _createBundle(
        Token[] calldata _tokensToBind,
        uint256 _bundleId
    ) internal {
        uint256 targetCount = _tokensToBind.length;
        require(targetCount != 0, "TokenBundle: no tokens to bind.");
        require(
            bundle[_bundleId].count == 0,
            "TokenBundle: existent at bundleId"
        );

        for (uint256 i; i < targetCount; ) {
            _checkTokenType(_tokensToBind[i]);
            bundle[_bundleId].tokens[i] = _tokensToBind[i];
            unchecked {
                ++i;
            }
        }

        bundle[_bundleId].count = targetCount;
        bundle[_bundleId].bundleIsActive = true;
    }

    /// @dev Lets the calling contract add tokens to a bundle for a unique bundle id.
    function _addTokensInBundle(
        Token[] calldata _tokensToBind,
        uint256 _bundleId
    ) internal {
        uint256 initialCount = bundle[_bundleId].count;
        uint256 targetCount = initialCount + _tokensToBind.length;
        for (uint256 i; i + initialCount < targetCount; ) {
            _checkTokenType(_tokensToBind[i]);
            bundle[_bundleId].tokens[initialCount + i] = _tokensToBind[i];
            unchecked {
                ++i;
            }
        }
        bundle[_bundleId].count = targetCount;
    }

    /// @dev Lets the calling contract update a token in a bundle for a unique bundle id and index.
    function _updateTokenInBundle(
        Token memory _tokenToBind,
        uint256 _bundleId,
        uint256 _index
    ) internal {
        require(_index < bundle[_bundleId].count, "TokenBundle: index DNE.");
        _checkTokenType(_tokenToBind);
        bundle[_bundleId].tokens[_index] = _tokenToBind;
    }

    /// @dev Lets update the items weight in a bundle for a unique bundle Id.
    function _updateBundleItemsWeights(
        uint256[] calldata weights,
        uint256 _bundleId
    ) internal {
        uint256 weigthLength = weights.length;
        for (uint256 i; i < weigthLength; ) {
            bundle[_bundleId].tokens[i].weight = weights[i];
            unchecked {
                ++i;
            }
        }
    }

    /// @dev Checks if the type of asset-contract is same as the TokenType specified.
    function _checkTokenType(Token memory _token) internal view {
        if (_token.tokenType == TokenType.ERC721) {
            try
                IERC165(_token.assetContract).supportsInterface(0x80ac58cd)
            returns (bool supported721) {
                require(supported721, "Asset doesn't match TokenType");
            } catch {
                revert("Asset doesn't match TokenType");
            }
        } else if (_token.tokenType == TokenType.ERC1155) {
            try
                IERC165(_token.assetContract).supportsInterface(0xd9b67a26)
            returns (bool supported1155) {
                require(supported1155, "Asset doesn't match TokenType");
            } catch {
                revert("Asset doesn't match TokenType");
            }
        } else if (_token.tokenType == TokenType.ERC20) {
            if (_token.assetContract != CurrencyTransferLib.NATIVE_TOKEN) {
                try
                    IERC165(_token.assetContract).supportsInterface(0x80ac58cd)
                returns (bool supported721) {
                    require(!supported721, "Asset doesn't match TokenType");

                    try
                        IERC165(_token.assetContract).supportsInterface(
                            0xd9b67a26
                        )
                    returns (bool supported1155) {
                        require(
                            !supported1155,
                            "Asset doesn't match TokenType"
                        );
                    } catch Error(string memory) {} catch {}
                } catch Error(string memory) {} catch {}
            }
        }
    }

    /// @dev Lets the calling contract delete a particular bundle.
    function _deleteBundle(uint256 _bundleId) internal {
        bundle[_bundleId].bundleIsActive = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "../EXTENSIONS/ProtocolFee.sol";
import { TokenBundle, ITokenBundle } from "./TokenBundle.sol";
import "../lib/CurrencyTransferLib.sol";

/**
 *  @title  Token Store
 *  @notice `TokenStore` contract extension allows bundling-up of ERC20/ERC721/ERC1155 and native-tokan assets
 *           and provides logic for storing, releasing, and transferring them from the extending contract
 */

contract TokenStore is TokenBundle, ProtocolFee, ERC721Holder, ERC1155Holder {
    /// @dev The address interpreted as native token of the chain.
    address public constant NATIVE_TOKEN =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev The address of the native token wrapper contract.
    address internal immutable nativeTokenWrapper;

    constructor(
        address _nativeTokenWrapper,
        address _treasuryWallet,
        uint256 _protocolFeeBps
    ) {
        nativeTokenWrapper = _nativeTokenWrapper;
        _setupProtocolFeeInfo(_treasuryWallet, _protocolFeeBps);
    }

    /// @dev Store / escrow multiple ERC1155, ERC721, ERC20 tokens.
    function _storeTokens(
        address _tokenOwner,
        Token[] calldata _tokens,
        uint256 _idForTokens,
        bool init
    ) internal {
        init
            ? _createBundle(_tokens, _idForTokens)
            : _addTokensInBundle(_tokens, _idForTokens);
        _transferTokenBatch(_tokenOwner, address(this), _tokens);
    }

    /// @dev Release stored / escrowed ERC1155, ERC721, ERC20 tokens.
    function _destroyLootbox(
        address _recipient,
        uint256 _idForContent
    ) internal {
        uint256 count = getTokenCountOfBundle(_idForContent);
        Token[] memory tokensToRelease = new Token[](count);

        for (uint256 i; i < count; ) {
            Token memory _token = getTokenOfBundle(_idForContent, i);
            if (_token.totalAmount != 0) {
                tokensToRelease[i] = _token;
            }
            unchecked {
                ++i;
            }
        }
        _deleteBundle(_idForContent);
        _transferTokenBatch(address(this), _recipient, tokensToRelease);
    }

    /**
     *
     * @param _recipient address to transfer tokens to
     * @param _idForContent id of bundle to replace token in
     * @param _index index of token to replace
     * @param _newToken new token to replace old token with
     */
    function _replaceTokenInBundle(
        address _recipient,
        uint256 _idForContent,
        uint256 _index,
        Token calldata _newToken
    ) internal {
        _transferToken(_recipient, address(this), _newToken);
        Token memory _token = getTokenOfBundle(_idForContent, _index);
        if (_token.totalAmount != 0) {
            _transferToken(address(this), _recipient, _token);
        }
        _updateTokenInBundle(_newToken, _idForContent, _index);
    }

    /**
     * @dev Update token weights in bundle
     * @param _idForContent id of bundle to update token weights in
     * @param weights array of weights to update bundle with
     */
    function _updateTokensWeight(
        uint256 _idForContent,
        uint256[] calldata weights
    ) internal {
        _updateBundleItemsWeights(weights, _idForContent);
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetProtocolFeeInfo()
        internal
        view
        virtual
        override
        returns (bool)
    {}

    /// @dev Transfers an arbitrary ERC20 / ERC721 / ERC1155 token.
    function _transferToken(
        address _from,
        address _to,
        Token memory _token
    ) internal {
        if (_token.tokenType == TokenType.ERC20) {
            CurrencyTransferLib.transferCurrencyWithWrapper(
                _token.assetContract,
                _from,
                _to,
                _token.totalAmount,
                nativeTokenWrapper
            );
        } else if (_token.tokenType == TokenType.ERC721) {
            IERC721(_token.assetContract).safeTransferFrom(
                _from,
                _to,
                _token.tokenId
            );
        } else if (_token.tokenType == TokenType.ERC1155) {
            IERC1155(_token.assetContract).safeTransferFrom(
                _from,
                _to,
                _token.tokenId,
                _token.totalAmount,
                ""
            );
        }
    }

    /// @dev Transfers multiple arbitrary ERC20 / ERC721 / ERC1155 tokens.
    function _transferTokenBatch(
        address _from,
        address _to,
        Token[] memory _tokens
    ) internal {
        uint256 nativeTokenValue;
        uint256 cumulativeWeights;
        uint256 tokensLength = _tokens.length;
        for (uint256 i; i < tokensLength; ++i) {
            if (
                _tokens[i].assetContract == CurrencyTransferLib.NATIVE_TOKEN &&
                _to == address(this)
            ) {
                nativeTokenValue += _tokens[i].totalAmount;
                cumulativeWeights += _tokens[i].weight;
            } else {
                _transferToken(_from, _to, _tokens[i]);
            }
        }
        if (nativeTokenValue != 0) {
            Token memory _nativeToken = Token({
                assetContract: CurrencyTransferLib.NATIVE_TOKEN,
                tokenType: ITokenBundle.TokenType.ERC20,
                tokenId: 0,
                totalAmount: nativeTokenValue,
                weight: cumulativeWeights
            });
            _transferToken(_from, _to, _nativeToken);
        }
    }

    function _forwardFunds(
        address _paymentCurrency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount != 0) {
            (
                address treasuryWallet,
                uint16 protocolFeeBps
            ) = getProtocolFeeInfo();
            if (protocolFeeBps != 0) {
                CurrencyTransferLib.safeTransferERC20(
                    _paymentCurrency,
                    _from,
                    treasuryWallet,
                    (_amount * protocolFeeBps) / 10000
                );
                _amount -= (_amount * protocolFeeBps) / 10000;
            }
            CurrencyTransferLib.safeTransferERC20(
                _paymentCurrency,
                _from,
                _to,
                _amount
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../INTERFACES/ITwoStepOwnable.sol";

/**
 * @title   TwoStepOwnable
 * @author  Unseen | decapinator.eth
 * @notice  TwoStepOwnable is a module which provides access control
 *          where the ownership of a contract can be exchanged via a
 *          two step process. A potential owner is set by the current
 *          owner using transferOwnership, then accepted by the new
 *          potential owner using acceptOwnership.
 */
contract TwoStepOwnable is ITwoStepOwnable {
    // The address of the owner.
    address private _owner;

    // The address of the new potential owner.
    address private _potentialOwner;

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        // Ensure the caller is the owner.
        if (msg.sender != _owner) {
            revert CallerIsNotOwner();
        }
        // Continue with function execution.
        _;
    }

    /**
     * @notice Initiate ownership transfer by assigning a new potential owner
     *         to this contract. Once set, the new potential owner may call
     *         `acceptOwnership` to claim ownership. Only the owner may call
     *         this function.
     *
     * @param newPotentialOwner The address for which to initiate ownership
     *                          transfer to.
     */
    function transferOwnership(
        address newPotentialOwner
    ) external override onlyOwner {
        // Ensure the new potential owner is not an invalid address.
        if (newPotentialOwner == address(0)) {
            revert NewPotentialOwnerIsNullAddress();
        }

        // Emit an event indicating that the potential owner has been updated.
        emit PotentialOwnerUpdated(newPotentialOwner);

        // Set the new potential owner as the potential owner.
        _potentialOwner = newPotentialOwner;
    }

    /**
     * @notice Clear the currently set potential owner, if any.
     *         Only the owner of this contract may call this function.
     */
    function cancelOwnershipTransfer() external override onlyOwner {
        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner.
        delete _potentialOwner;
    }

    /**
     * @notice Accept ownership of this contract. Only the account that the
     *         current owner has set as the new potential owner may call this
     *         function.
     */
    function acceptOwnership() external override {
        // Ensure the caller is the potential owner.
        if (msg.sender != _potentialOwner) {
            // Revert, indicating that caller is not current potential owner.
            revert CallerIsNotNewPotentialOwner();
        }

        // Emit an event indicating that the potential owner has been cleared.
        emit PotentialOwnerUpdated(address(0));

        // Clear the current new potential owner.
        delete _potentialOwner;

        // Emit an event indicating ownership has been transferred.
        emit OwnershipTransferred(_owner, msg.sender);

        // Set the caller as the owner of this contract.
        _owner = msg.sender;
    }

    /**
     * @notice An external view function that returns the potential owner.
     *
     * @return The address of the potential owner.
     */
    function potentialOwner() external view override returns (address) {
        return _potentialOwner;
    }

    /**
     * @notice A public view function that returns the owner.
     *
     * @return The address of the owner.
     */
    function owner() public view virtual override returns (address) {
        return _owner;
    }

    /**
     * @notice Internal function that sets the inital owner of the
     *         base contract. The initial owner must not be set
     *         previously.
     *
     * @param initialOwner The address to set for initial ownership.
     */
    function _setInitialOwner(address initialOwner) internal {
        // Ensure the initial owner is not an invalid address.
        if (initialOwner == address(0)) {
            revert InitialOwnerIsNullAddress();
        }

        // Ensure the owner has not already been set.
        if (_owner != address(0)) {
            revert OwnerAlreadySet(_owner);
        }

        // Emit an event indicating ownership has been set.
        emit OwnershipTransferred(address(0), initialOwner);

        // Set the initial owner.
        _owner = initialOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./ITokenBundle.sol";

/**
 *  @title ILootbox
 *  @author Unseen | decapinator.eth
 *  The unseen `Lootbox` contract is a lootbox mechanism. An account can bundle up arbitrary ERC20, ERC721 and ERC1155 tokens into
 *  a set of lootboxes. A lootbox can then be opened in return for a selection of the tokens in the lootbox. The selection of tokens distributed
 *  on opening a lootbox depends on the relative supply of all tokens in the lootboxes.
 */
interface ILootbox is ITokenBundle {
    /**
     *  @notice All info relevant to lootboxes.
     *  @param perUnitAmounts Mapping from a UID -> to the per-unit amount of that asset i.e. `Token` at that index
     *  @param weights each token weight
     *  @param pricePerOpen The price to be paid before a box is opened
     *  @param amountDistributedPerOpen The number of reward units distributed per open
     *  @param creator address of lootbox creator and only authority
     *  @param withUpdate flag wether after each open , the box enter an update state
     */
    struct LootboxInfo {
        uint256[] perUnitAmounts;
        uint256 pricePerOpen;
        address creator;
        bool withUpdate;
        uint256 EmptySlotWeight;
    }

    /// @notice Emitted when a set of lootboxes is created.
    event LootboxCreated(
        uint256 indexed lootboxId,
        address indexed lootboxCreator
    );

    /// @notice Emitted when a lootbox is opened.
    event LootboxOpened(
        uint256 indexed lootboxId,
        address indexed opener,
        Token rewardUnitsDistributed
    );

    /// @notice Emitted when a lootbox is opened.
    event LootboxUpdated(uint256 indexed lootboxId, address lootboxCreator);

    /// @notice Emitted when a lootbox is destroyed.
    event LootboxDestroyed(uint256 indexed lootboxId, address lootboxCreator);

    /// @notice Emitted when payment currency is updated.
    event PaymentCurrencyUpdated(address currency);

    /**
     *  @notice Creates a lootbox with the stated contents
     *  @param contents The reward units to lootbox in the lootboxes
     *  @param numOfRewardUnits The number of reward units to create, for each asset specified in `contents`
     *  @param pricePerOpen The price to be paid each time the box is opened
     *  @param _withUpdate Flag wether creator has to update manually after each opening
     *  @return lootboxId The unique identifer of the created set of lootboxes
     */
    function createLootbox(
        Token[] calldata contents,
        uint256[] calldata numOfRewardUnits,
        uint256 pricePerOpen,
        bool _withUpdate,
        uint256 EmptySlotWeight
    ) external payable returns (uint256 lootboxId);

    /**
     *  @notice Destroy a lootbox and transfer assets back to creator
     *  @param _lootboxId The reward units to lootbox in the lootboxes
     */
    function destroyLootbox(uint256 _lootboxId) external;

    /**
     *  @notice Add contents to existing lootbox
     *  @param contents The reward units to lootbox in the lootboxes
     *  @param numOfRewardUnits The number of reward units to create, for each asset specified in `contents`
     *  @param _lootboxId The unique identifer of the created set of lootboxes
     */
    function addLootboxContents(
        uint256 _lootboxId,
        Token[] calldata contents,
        uint256[] calldata numOfRewardUnits
    ) external payable;

    /**
     *  @notice swap two token in/out
     *  @param token The reward units to lootbox in the lootboxes
     *  @param _numOfRewardUnits The number of reward units to create, for each asset specified in `contents`
     *  @param _lootboxId Flag wether creator has to update manually after each opening
     */
    function swapTokens(
        uint256 _lootboxId,
        uint256 _index,
        Token calldata token,
        uint256 _numOfRewardUnits
    ) external payable;

    /**
     *  @notice update tokens weight
     *  @param _lootboxId Flag wether creator has to update manually after each opening
     *  @param weights tokens weight when it gets picked
     */
    function updateTokensWeights(
        uint256 _lootboxId,
        uint256[] calldata weights,
        uint256 EmptyWeight
    ) external;

    /**
     *  @notice Remove Empty slot
     *  @param _lootboxId Flag wether creator has to update manually after each opening
     */
    function removeEmptySlot(uint256 _lootboxId) external;

    /**
     *  @notice Update Empty slot weight
     *  @param _lootboxId Flag wether creator has to update manually after each opening
     *  @param _EmptySlotWeight empty slot given weight
     */
    function updateEmptySlot(
        uint256 _lootboxId,
        uint256 _EmptySlotWeight
    ) external;

    /**
     *  @notice Lets a user open a lootbox open and receive the lootbox's reward unit
     *  @param lootboxId The identifier of the lootbox to open
     */
    function openLootbox(
        uint256 lootboxId
    ) external payable returns (Token memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection
 */
interface IPermissions {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sende
    );

    /**
     * @dev Emitted when `account` is revoked `role`
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

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
pragma solidity ^0.8.18;

import "./IPermissions.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IPermissionsEnumerable is IPermissions {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     */
    function getRoleMember(
        bytes32 role,
        uint256 index
    ) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 *  @title ProtocolFee Contract
 *  @notice Unseen ProtocolFee contract - to be used with any service contract to implement protocol fees
 *  @author Unseen | decapinator.eth
 **/
interface IProtocolFee {
    /// @dev Returns the protocol fee bps and recipient.
    function getProtocolFeeInfo() external view returns (address, uint16);

    /// @dev Lets a module admin update the fees on primary sales.
    function setProtocolFeeInfo(
        address _protocolFeeRecipient,
        uint16 _protocolFeeBps
    ) external;

    /// @dev Lets a module admin update the protocol fee recipient.
    function changeProtocolFeeRecipient(address _protocolFeeRecipient) external;

    /// @dev Lets a module admin update the protocol fee bps.
    function changeProtocolFeeBps(uint16 _protocolFeeBps) external;

    /// @dev Emitted when fee on primary sales is updated.
    event ProtocolFeeInfoUpdated(
        address indexed protocolFeeRecipient,
        uint256 protocolFeeBps
    );

    /// @dev Emitted when protocol fee recipient address is updated
    event ProtocolFeeRecipientUpdated(address indexed protocolFeeRecipient);

    /// @dev Emitted when protocol fee bps is updated
    event ProtocolFeeBpsUpdated(uint256 protocolFeeBps);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 *  @title ITokenBundle
 *  @author Unseen | decapinator.eth
 *  Group together arbitrary ERC20, ERC721 and ERC1155 tokens into a single bundle.
 *  The `Token` struct is a generic type that can describe any ERC20, ERC721 or ERC1155 token.
 *  The `Bundle` struct is a data structure to track a group/bundle of multiple assets i.e. ERC20,
 *  ERC721 and ERC1155 tokens, each described as a `Token`.
 */
interface ITokenBundle {
    /// @notice The type of assets that can be wrapped.
    enum TokenType {
        ERC20,
        ERC721,
        ERC1155
    }

    /**
     *  @notice A generic interface to describe any ERC20, ERC721 or ERC1155 token
     *  @param assetContract The contract address of the asset
     *  @param tokenType The token type (ERC20 / ERC721 / ERC1155) of the asset
     *  @param tokenId The token Id of the asset, if the asset is an ERC721 / ERC1155 NFT
     *  @param totalAmount The amount of the asset, if the asset is an ERC20 / ERC1155 fungible token
     */
    struct Token {
        address assetContract;
        TokenType tokenType;
        uint256 tokenId;
        uint256 totalAmount;
        uint256 weight;
    }

    /**
     *  @notice An internal data structure to track a group / bundle of multiple assets i.e. `Token`s
     *  @param count The total number of assets i.e. `Token` in a bundle
     *  @param tokens Mapping from a UID -> to a unique asset i.e. `Token` in the bundle
     */
    struct BundleInfo {
        uint256 count;
        bool bundleIsActive;
        mapping(uint256 => Token) tokens;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @title   TwoStepOwnableInterface
 * @author  Unseen | decapinator.eth
 * @notice  TwoStepOwnableInterface contains all external function INTERFACES,
 *          events and errors for the two step ownable access control module.
 */
interface ITwoStepOwnable {
    /**
     * @dev Emit an event whenever the contract owner registers a
     *      new potential owner.
     *
     * @param newPotentialOwner The new potential owner of the contract.
     */
    event PotentialOwnerUpdated(address newPotentialOwner);

    /**
     * @dev Emit an event whenever contract ownership is transferred.
     *
     * @param previousOwner The previous owner of the contract.
     * @param newOwner      The new owner of the contract.
     */
    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev Revert with an error when attempting to set an owner
     *      that is already set.
     */
    error OwnerAlreadySet(address currentOwner);

    /**
     * @dev Revert with an error when attempting to set the initial
     *      owner and supplying the null address.
     */
    error InitialOwnerIsNullAddress();

    /**
     * @dev Revert with an error when attempting to call an operation
     *      while the caller is not the owner.
     */
    error CallerIsNotOwner();

    /**
     * @dev Revert with an error when attempting to register a new potential
     *      owner and supplying the null address.
     */
    error NewPotentialOwnerIsNullAddress();

    /**
     * @dev Revert with an error when attempting to claim ownership of the
     *      contract with a caller that is not the current potential owner.
     */
    error CallerIsNotNewPotentialOwner();

    /**
     * @notice Initiate ownership transfer by assigning a new potential owner
     *         to this contract. Once set, the new potential owner may call
     *         `acceptOwnership` to claim ownership. Only the owner may call
     *         this function.
     *
     * @param newPotentialOwner The address for which to initiate ownership
     *                          transfer to.
     */
    function transferOwnership(address newPotentialOwner) external;

    /**
     * @notice Clear the currently set potential owner, if any.
     *         Only the owner of this contract may call this function.
     */
    function cancelOwnershipTransfer() external;

    /**
     * @notice Accept ownership of this contract. Only the account that the
     *         current owner has set as the new potential owner may call this
     *         function.
     */
    function acceptOwnership() external;

    /**
     * @notice An external view function that returns the potential owner.
     *
     * @return The address of the potential owner.
     */
    function potentialOwner() external view returns (address);

    /**
     * @notice An external view function that returns the owner.
     *
     * @return The address of the owner.
     */
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 *  @title IWETH
 *  @notice Interface for WETH.
 */
interface IWETH {
    ///@notice deposit ETH to WETH
    function deposit() external payable;

    ///@notice withdraw WETH to ETH
    function withdraw(uint256 amount) external;

    ///@notice transfer WETH
    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// Helper INTERFACES
import { IWETH } from "../INTERFACES/IWETH.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

library CurrencyTransferLib {
    using SafeERC20 for IERC20;

    /// @dev The address interpreted as native token of the chain.
    address public constant NATIVE_TOKEN =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Transfers a given amount of currency.
    function transferCurrency(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }

        if (_currency == NATIVE_TOKEN) {
            safeTransferNativeToken(_to, _amount);
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfers a given amount of currency. (With native token wrapping)
    function transferCurrencyWithWrapper(
        address _currency,
        address _from,
        address _to,
        uint256 _amount,
        address _nativeTokenWrapper
    ) internal {
        if (_amount == 0) {
            return;
        }
        if (_currency == NATIVE_TOKEN) {
            if (_from == address(this)) {
                // withdraw from weth then transfer withdrawn native token to recipient
                IWETH(_nativeTokenWrapper).withdraw(_amount);
                safeTransferNativeTokenWithWrapper(
                    _to,
                    _amount,
                    _nativeTokenWrapper
                );
            } else if (_to == address(this)) {
                // store native currency in weth
                require(_amount == msg.value, "msg.value != amount");
                IWETH(_nativeTokenWrapper).deposit{ value: _amount }();
            } else {
                safeTransferNativeTokenWithWrapper(
                    _to,
                    _amount,
                    _nativeTokenWrapper
                );
            }
        } else {
            safeTransferERC20(_currency, _from, _to, _amount);
        }
    }

    /// @dev Transfer `amount` of ERC20 token from `from` to `to`.
    function safeTransferERC20(
        address _currency,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_from == _to) {
            return;
        }

        if (_from == address(this)) {
            IERC20(_currency).safeTransfer(_to, _amount);
        } else {
            IERC20(_currency).safeTransferFrom(_from, _to, _amount);
        }
    }

    /// @dev Transfers `amount` of native token to `to`.
    function safeTransferNativeToken(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }("");
        require(success, "native token transfer failed");
    }

    /// @dev Transfers `amount` of native token to `to`. (With native token wrapping)
    function safeTransferNativeTokenWithWrapper(
        address to,
        uint256 value,
        address _nativeTokenWrapper
    ) internal {
        (bool success, ) = to.call{ value: value }("");
        if (!success) {
            IWETH(_nativeTokenWrapper).deposit{ value: value }();
            IERC20(_nativeTokenWrapper).safeTransfer(to, value);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * @dev String operations.
 */
library USNStrings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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
    function toHexString(
        uint256 value,
        uint256 length
    ) internal pure returns (string memory) {
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
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "../EXTENSIONS/TwoStepOwnable.sol";
import "../EXTENSIONS/PermissionsEnumerable.sol";
import { TokenStore, ERC1155Receiver } from "../EXTENSIONS/TokenStore.sol";
import "../INTERFACES/ILootbox.sol";

/*
$$$$$$$\            $$\         $$\            $$$$$$\    $$\                     $$\ $$\                     
$$  __$$\           $$ |        $$ |          $$  __$$\   $$ |                    $$ |\__|                    
$$ |  $$ | $$$$$$\  $$ |  $$\ $$$$$$\         $$ /  \__|$$$$$$\   $$\   $$\  $$$$$$$ |$$\  $$$$$$\   $$$$$$$\ 
$$$$$$$  |$$  __$$\ $$ | $$  |\_$$  _|        \$$$$$$\  \_$$  _|  $$ |  $$ |$$  __$$ |$$ |$$  __$$\ $$  _____|
$$  __$$< $$$$$$$$ |$$$$$$  /   $$ |           \____$$\   $$ |    $$ |  $$ |$$ /  $$ |$$ |$$ /  $$ |\$$$$$$\  
$$ |  $$ |$$   ____|$$  _$$<    $$ |$$\       $$\   $$ |  $$ |$$\ $$ |  $$ |$$ |  $$ |$$ |$$ |  $$ | \____$$\ 
$$ |  $$ |\$$$$$$$\ $$ | \$$\   \$$$$  |      \$$$$$$  |  \$$$$  |\$$$$$$  |\$$$$$$$ |$$ |\$$$$$$  |$$$$$$$  |
\__|  \__| \_______|\__|  \__|   \____/        \______/    \____/  \______/  \_______|\__| \______/ \_______/                                                                                                                                                                     
*/

/**
 *  @title Lootbox contract
 *  @notice Contract to bundle ERC20,ERC721 and ERC1155 tokens together and uint256 users pick randomly based on %
 *  @author decapinator.eth | USN
 **/
contract USNLootbox is
    TwoStepOwnable,
    TokenStore,
    Pausable,
    PermissionsEnumerable,
    ReentrancyGuard,
    ILootbox
{
    /// @dev Only assets with ASSET_ROLE can be lootboxed, when lootboxing is restricted to particular assets.
    bytes32 private constant ASSET_ROLE = keccak256("ASSET_ROLE");

    /// @dev The token Id of the next lootbox content to be created
    uint256 public nextLootboxId;

    /// @dev The address of the payment currency { RUN }
    address public paymentCurrency;

    /// @dev Mapping from lootbox ID => The state of that lootbox
    mapping(uint256 => LootboxInfo) private lootboxInfo;

    /// @dev Modifier to check if caller is the creator of the lootbox
    modifier onlyCreator(uint256 _lootboxId) {
        require(
            lootboxInfo[_lootboxId].creator == msg.sender,
            "USN: Just owner can add modify this lootbox!"
        );
        _;
    }

    /// @dev Modifier to check if the lootbox is active
    modifier isActiveBundle(uint256 _lootboxId) {
        require(bundleIsActive(_lootboxId), "USN: Lootbox doesn't exist");
        _;
    }

    /**
     *  @notice Constructor
     *  @param _nativeTokenWrapper Address of ETH wrapper contract
     *  @param _defaultAdmin Adderss of the admin
     **/
    constructor(
        address _nativeTokenWrapper,
        address _defaultAdmin,
        address _runToken,
        address _treasuryWallet,
        uint256 _protocolFeeBps
    )
        payable
        TokenStore(_nativeTokenWrapper, _treasuryWallet, _protocolFeeBps)
    {
        require(_runToken != address(0), "USN: Cannot be address 0");

        paymentCurrency = _runToken;

        _setInitialOwner(_defaultAdmin);

        _setupRole(DEFAULT_ADMIN_ROLE, _defaultAdmin);

        _setupRole(ASSET_ROLE, address(0));
    }

    /**
     * @notice Fallback function to receive ETH just from the native token wrapper
     */
    receive() external payable {
        require(
            msg.sender == nativeTokenWrapper,
            "USN: Caller is not native token wrapper."
        );
    }

    /**
     * @notice Pauses the contract functions that use a `whenPaused` flag
     */
    function pause() external onlyOwner {
        super._pause();
    }

    /**
     * @notice Unpauses the contract functions that use a `whenPaused` flag
     */
    function unpause() external onlyOwner {
        super._unpause();
    }

    /**
     * @notice Function to create a lootbox
     * @param _contents The contents of the lootbox
     * @param _numOfRewardUnits The number of reward units for each content
     * @param _pricePerOpen The price per open
     * @param _withUpdate If the lootbox can be updated
     * @param EmptySlotWeight The weight of the empty slot
     * @return lootboxId the lootbox id created
     */
    function createLootbox(
        Token[] calldata _contents,
        uint256[] calldata _numOfRewardUnits,
        uint256 _pricePerOpen,
        bool _withUpdate,
        uint256 EmptySlotWeight
    ) external payable nonReentrant whenNotPaused returns (uint256 lootboxId) {
        /// @notice content must not be empty
        require(_contents.length != 0, "USN: Numbers mismatch");
        require(
            _contents.length == _numOfRewardUnits.length,
            "USN: Numbers mismatch"
        );
        /// @notice if we have an asset_role assigned then we check for allowlist assets
        if (!hasRole(ASSET_ROLE, address(0))) {
            for (uint256 i; i < _contents.length; ) {
                /// @notice Check if the assets being lootboxed is in allowlist
                _checkRole(ASSET_ROLE, _contents[i].assetContract);
                unchecked {
                    ++i;
                }
            }
        }

        lootboxId = nextLootboxId;
        nextLootboxId++;

        escrowLootboxContents(_contents, _numOfRewardUnits, lootboxId, true);

        lootboxInfo[lootboxId].pricePerOpen = _pricePerOpen;
        lootboxInfo[lootboxId].creator = msg.sender;
        lootboxInfo[lootboxId].withUpdate = _withUpdate;
        if (EmptySlotWeight != 0) {
            lootboxInfo[lootboxId].EmptySlotWeight = EmptySlotWeight;
        }

        emit LootboxCreated(lootboxId, _msgSender());
    }

    /**
     * @notice Function to open a lootbox
     */
    function openLootbox(
        uint256 _lootboxId
    )
        external
        payable
        nonReentrant
        whenNotPaused
        isActiveBundle(_lootboxId)
        returns (Token memory rewardUnits)
    {
        LootboxInfo memory lootbox = lootboxInfo[_lootboxId];

        _forwardFunds(
            paymentCurrency,
            msg.sender,
            lootbox.creator,
            lootbox.pricePerOpen
        );

        rewardUnits = getRewardUnits(_lootboxId, lootbox);

        if (rewardUnits.totalAmount != 0) {
            _transferToken(address(this), _msgSender(), rewardUnits);
        }
        emit LootboxOpened(_lootboxId, _msgSender(), rewardUnits);
    }

    /**
     * @notice Function to update the lootbox contents
     */
    function addLootboxContents(
        uint256 _lootboxId,
        Token[] calldata _contents,
        uint256[] calldata _numOfRewardUnits
    )
        external
        payable
        nonReentrant
        whenNotPaused
        onlyCreator(_lootboxId)
        isActiveBundle(_lootboxId)
    {
        uint256 contentLength = _contents.length;
        require(contentLength != 0, "USN: !Len");
        require(contentLength == _numOfRewardUnits.length, "USN: !Len");
        if (!hasRole(ASSET_ROLE, address(0))) {
            for (uint256 i; i < contentLength; ) {
                _checkRole(ASSET_ROLE, _contents[i].assetContract);
                unchecked {
                    ++i;
                }
            }
        }
        escrowLootboxContents(_contents, _numOfRewardUnits, _lootboxId, false);
        emit LootboxUpdated(_lootboxId, _msgSender());
    }

    /**
     * @notice Function to swap tokens from the lootbox contents
     * @param _lootboxId  The lootbox id
     * @param _index  The index of the content to be replaced
     * @param _content  The new content
     * @param _numOfRewardUnits  The number of reward units for the new content
     */
    function swapTokens(
        uint256 _lootboxId,
        uint256 _index,
        Token calldata _content,
        uint256 _numOfRewardUnits
    )
        external
        payable
        nonReentrant
        whenNotPaused
        onlyCreator(_lootboxId)
        isActiveBundle(_lootboxId)
    {
        require(_content.totalAmount != 0, "USN: amount can't be zero");
        require(
            _content.totalAmount % _numOfRewardUnits == 0,
            "USN: invalid reward units"
        );
        require(
            _content.tokenType != TokenType.ERC721 || _content.totalAmount == 1,
            "USN: invalid erc721 rewards"
        );
        require(
            _index < getTokenCountOfBundle(_lootboxId),
            "USN: Token not found"
        );
        lootboxInfo[_lootboxId].perUnitAmounts[_index] =
            _content.totalAmount /
            _numOfRewardUnits;
        _replaceTokenInBundle(msg.sender, _lootboxId, _index, _content);
        emit LootboxUpdated(_lootboxId, _msgSender());
    }

    /**
     * @notice Function to destroy the lootbox
     */
    function destroyLootbox(
        uint256 _lootboxId
    )
        external
        nonReentrant
        whenNotPaused
        onlyCreator(_lootboxId)
        isActiveBundle(_lootboxId)
    {
        _destroyLootbox(msg.sender, _lootboxId);
        emit LootboxDestroyed(_lootboxId, _msgSender());
    }

    /**
     * @dev Update the lootbox price
     * @param _lootboxId The lootbox id
     * @param weights The new weights
     * @param EmptyWeight The new empty slot weight
     */
    function updateTokensWeights(
        uint256 _lootboxId,
        uint256[] calldata weights,
        uint256 EmptyWeight
    )
        external
        nonReentrant
        whenNotPaused
        onlyCreator(_lootboxId)
        isActiveBundle(_lootboxId)
    {
        require(
            weights.length == getTokenCountOfBundle(_lootboxId),
            "USN: items count mismatch"
        );
        _updateTokensWeight(_lootboxId, weights);
        if (lootboxInfo[_lootboxId].EmptySlotWeight != EmptyWeight) {
            lootboxInfo[_lootboxId].EmptySlotWeight = EmptyWeight;
        }
        emit LootboxUpdated(_lootboxId, _msgSender());
    }

    /**
     * @dev Remove the empty slot from the lootbox
     * @param _lootboxId The lootbox id
     */
    function removeEmptySlot(
        uint256 _lootboxId
    )
        external
        nonReentrant
        whenNotPaused
        onlyCreator(_lootboxId)
        isActiveBundle(_lootboxId)
    {
        require(
            lootboxInfo[_lootboxId].EmptySlotWeight != 0,
            "USN: Empty slot already removed"
        );
        lootboxInfo[_lootboxId].EmptySlotWeight = 0;
    }

    /**
     * @dev Update lootbox
     * @param _lootboxId  The lootbox id
     * @param _EmptySlotWeight  The weight of the empty slot
     */
    function updateEmptySlot(
        uint256 _lootboxId,
        uint256 _EmptySlotWeight
    )
        external
        nonReentrant
        whenNotPaused
        onlyCreator(_lootboxId)
        isActiveBundle(_lootboxId)
    {
        require(
            _EmptySlotWeight != lootboxInfo[_lootboxId].EmptySlotWeight,
            "USN: Empty slot weight already updated"
        );
        lootboxInfo[_lootboxId].EmptySlotWeight = _EmptySlotWeight;
    }

    /**
     * @dev Escrow the contents of a lootbox
     * @param _contents The contents of the lootbox
     * @param _numOfRewardUnits The number of reward units
     * @param lootboxId The lootbox id
     * @param init True if the lootbox is being created, false if it's being updated
     */
    function escrowLootboxContents(
        Token[] calldata _contents,
        uint256[] calldata _numOfRewardUnits,
        uint256 lootboxId,
        bool init
    ) internal {
        uint256 contents_ = _contents.length;
        for (uint256 i; i < contents_; ) {
            require(_contents[i].totalAmount != 0, "USN: amount can't be zero");
            require(
                _contents[i].totalAmount % _numOfRewardUnits[i] == 0,
                "USN: invalid reward units"
            );
            require(
                _contents[i].tokenType != TokenType.ERC721 ||
                    _contents[i].totalAmount == 1,
                "USN: invalid erc721 rewards"
            );

            lootboxInfo[lootboxId].perUnitAmounts.push(
                _contents[i].totalAmount / _numOfRewardUnits[i]
            );
            unchecked {
                ++i;
            }
        }
        _storeTokens(_msgSender(), _contents, lootboxId, init);
    }

    /**
     * @dev Returns the rewarded token
     * @param _lootboxId The id of the bundle
     * @param lootbox The lootbox info
     */
    function getRewardUnits(
        uint256 _lootboxId,
        LootboxInfo memory lootbox
    ) internal returns (Token memory token) {
        uint256 totalRewardKinds = getTokenCountOfBundle(_lootboxId);
        uint256[] memory cumulativeWeights = new uint256[](
            totalRewardKinds + (lootbox.EmptySlotWeight > 0 ? 1 : 0)
        );
        uint256 cumul;
        for (uint256 i; i < totalRewardKinds; ) {
            Token memory __token = getTokenOfBundle(_lootboxId, i);
            if (__token.totalAmount != 0) {
                cumul += __token.weight;
                cumulativeWeights[i] = cumul;
            } else {
                cumulativeWeights[i] = cumul;
            }
            unchecked {
                ++i;
            }
        }
        if (cumul == 0) {
            revert("USN: no rewards available");
        }
        uint256 cumulativeWeightsLength = cumulativeWeights.length;
        if (lootbox.EmptySlotWeight != 0) {
            cumul += lootbox.EmptySlotWeight;
            cumulativeWeights[cumulativeWeightsLength - 1] = cumul;
        }
        uint256 randomVal = uint256(
            keccak256(
                abi.encode(generateRandomValue(), uint256(uint160(msg.sender)))
            )
        );
        uint256 target = randomVal % cumul;
        for (uint256 i; i < cumulativeWeightsLength; ) {
            if (cumulativeWeights[i] >= target) {
                if (i == cumulativeWeightsLength - 1) {
                    if (lootbox.EmptySlotWeight != 0) {
                        return token;
                    }
                }
                Token memory _token = getTokenOfBundle(_lootboxId, i);
                _token.totalAmount -= lootbox.perUnitAmounts[i];
                _updateTokenInBundle(_token, _lootboxId, i);
                token = _token;
                token.totalAmount = lootbox.perUnitAmounts[i];
                return token;
            }
            unchecked {
                ++i;
            }
        }
        revert("USN: no rewards available");
    }

    /**
     * @dev Returns the contents of the lootbox
     */
    function getLootboxContents(
        uint256 _lootboxId
    )
        external
        view
        returns (
            Token[] memory contents,
            uint256[] memory perUnitAmounts,
            uint256 emptySlotWeight
        )
    {
        if (!bundleIsActive(_lootboxId))
            return (contents, perUnitAmounts, emptySlotWeight);
        LootboxInfo memory lootbox = lootboxInfo[_lootboxId];
        uint256 total = getTokenCountOfBundle(_lootboxId);
        contents = new Token[](total);
        perUnitAmounts = new uint256[](total);

        for (uint256 i; i < total; ) {
            contents[i] = getTokenOfBundle(_lootboxId, i);
            perUnitAmounts[i] = lootbox.perUnitAmounts[i];
            unchecked {
                ++i;
            }
        }
        emptySlotWeight = lootboxInfo[_lootboxId].EmptySlotWeight;
    }

    /**
     * @dev Generates a random value
     */
    function generateRandomValue() internal view returns (uint256 random) {
        random = uint256(
            keccak256(
                abi.encodePacked(
                    _msgSender(),
                    blockhash(block.number - 1),
                    block.prevrandao
                )
            )
        );
    }

    /**
     * @dev Updates the payment currency
     * @param currency The new payment currency
     */
    function updatePaymentCurrency(address currency) external onlyOwner {
        require(currency != address(0), "USN: Cannot be address 0");
        require(currency != paymentCurrency, "USN: Already updated");
        paymentCurrency = currency;
        emit PaymentCurrencyUpdated(currency);
    }

    /// @dev Returns whether royalty info can be set in the given execution context.
    function _canSetProtocolFeeInfo()
        internal
        view
        virtual
        override
        returns (bool)
    {
        return msg.sender == owner();
    }

    /// @dev See ERC 165
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155Receiver) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}