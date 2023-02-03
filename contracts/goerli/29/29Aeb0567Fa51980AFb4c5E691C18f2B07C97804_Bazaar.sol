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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../utils/HasAuthorization.sol";
import "../token/ERC2981/IERC2981.sol";
import "../token/ERC1155/extensions/ERC1155PreMintedCollection.sol";
import "../utils/Monetary.sol";
import "./Marketplace.sol";


/**
 * a Bazaar is an interactive marketplace where:
 * seller lists, potential buyer makes an offer, which the seller in turn either accepts or ignores
 *
 * this implementation varies in the following manner:
 *  1. the sale starts immediately and is not time-bounded
 *  2. a (potential) buyer can buy any amount of the tokenId, as long as the seller own such amount
 *  3. an offer involves an escrow and is not time-bounded
 *  4. an offer is accepted automatically if it is at the asking price or above
 *  5. the buyer can retract the offer at any time
 *  6. the buyer can update the offer at any time
 *  7. the seller can cancel the sale at any time
 *
 * @notice a Sale is conducted without an escrow
 */
contract Bazaar is Marketplace, HasAuthorization, ReentrancyGuard {
    using Address for address payable;
    using Monetary for Monetary.Crypto;

    event Created(uint id, address seller, Asset asset, Monetary.Crypto price);
    event OfferMade(uint id, address buyer, Asset asset, Monetary.Crypto price);
    event OfferRetracted(uint id, address buyer, Asset asset, Monetary.Crypto price);
    event Canceled(uint id, Asset asset);

    struct Sale {
        Asset asset;
//        address collection;
//        uint tokenId;
//        uint amount; // ceiling amount for sale. if tokenId == 0 & amount == 0, it means ALL owned by seller (ALL_OUT_SALE)
        address seller;
        Monetary.Crypto price; // per unit
    }
    struct Offer {
        Asset asset;
        Monetary.Crypto price; // per unit
    }

    uint constant ALL_OUT_SALE = 0;
    uint public currentSaleId;
    mapping(uint => Sale) public sales; // sale-id => Sale
    mapping(address => mapping(uint => mapping(uint => Offer))) public offers; // buyer => sale-id => tokenId => Offer

    modifier exists(uint id) { if (!isExistingSale(id)) revert NoSuchMarketplace(id); _; }

    constructor(address[] memory owners, address recipient, uint24 basispoints) HasFees(owners, recipient, basispoints) {}

    function _createSale(Asset memory asset, Monetary.Crypto memory price) private returns (uint) {
        uint id = ++currentSaleId;
        sales[id] = Sale(asset, msg.sender, price);
        emit Created(id, msg.sender, asset, price);
        return id;
    }

    function createSale(Asset memory asset, Monetary.Crypto memory price) external returns (uint) {
        validate(asset);
        return _createSale(asset, price);
    }

    function createAllOutSale(address collection, Monetary.Crypto memory price) external returns (uint) {
        validateAllOutSale(collection);
        return _createSale(Asset(collection, ALL_OUT_SALE, ALL_OUT_SALE), price);
    }

    function validateAllOutSale(address collection) private view {
        IERC165(collection).supportsInterface(type(IERC721).interfaceId) ?
            require(IERC721(collection).isApprovedForAll(msg.sender, address(this)), "ERC721: contract not approved for transfer") :
            IERC165(collection).supportsInterface(type(IERC1155).interfaceId) ?
                require(IERC1155(collection).isApprovedForAll(msg.sender, address(this)), "ERC1155: contract not approved for transfer") :
                revert("only ERC721 & ERC1155 collections are supported");
    }

    function isExistingSale(uint saleId) public view returns (bool) {
        return sales[saleId].seller != address(0);
    }

    function isAllOutSale(uint saleId) public view returns (bool) {
        return sales[saleId].asset.tokenId == ALL_OUT_SALE && sales[saleId].asset.amount == ALL_OUT_SALE;
    }

    function makeOffer(uint saleId, uint tokenId, uint amount, Monetary.Crypto memory price) external payable nonReentrant {
        _makeOffer(saleId, tokenId, amount, price, Monetary.Native(msg.value));
    }

    function makeOfferWithERC20(uint saleId, uint tokenId, uint amount, Monetary.Crypto memory price, Monetary.Crypto memory deposit) external nonReentrant {
        deposit.transferFromSender();
        _makeOffer(saleId, tokenId, amount, price, deposit);
    }

    function _makeOffer(uint saleId, uint tokenId, uint amount, Monetary.Crypto memory price, Monetary.Crypto memory deposit) private exists(saleId) {
        address buyer = msg.sender;
        Sale storage sale = sales[saleId];
        if (!isAllOutSale(saleId)) {
            require(sale.asset.tokenId == tokenId, "token id offered for is not for sale");
            require(sale.asset.amount >= amount, "desired amount exceeds amount sold limit");
        }
        Monetary.Crypto memory available = retractPrevious(buyer, saleId, tokenId).plus(deposit);
        Monetary.Crypto memory cost = price.multipliedBy(amount);
        if (cost.isGreaterThan(available)) revert InsufficientFunds(cost, available);
        if (available.isGreaterThan(cost)) available.minus(cost).transferTo(msg.sender); // refund overflow
        offers[buyer][saleId][tokenId] = Offer(Asset(sale.asset.collection, tokenId, amount), price);
        emit OfferMade(saleId, buyer, Asset(sale.asset.collection, tokenId, amount), price);
        if (!sale.price.isGreaterThan(price)) acceptOffer(saleId, sale, offers[buyer][saleId][tokenId], buyer, tokenId);
    }

    function retractOffer(uint saleId, uint tokenId) external {
        Monetary.Crypto memory deposit = retractPrevious(msg.sender, saleId, tokenId);
        require(!deposit.isZero(), "no such offer");
        deposit.transferTo(msg.sender);
    }

    function retractPrevious(address buyer, uint saleId, uint tokenId) private returns (Monetary.Crypto memory) {
        Offer storage offer = offers[buyer][saleId][tokenId];
        if (offer.asset.amount == 0) return Monetary.Zero(sales[saleId].price.currency); // offer does not exist
        Monetary.Crypto memory deposit = offer.price.multipliedBy(offer.asset.amount);
        emit OfferRetracted(saleId, buyer, offer.asset, offer.price);
        delete offers[buyer][saleId][tokenId];
        return deposit;
    }

    function acceptOffer(uint saleId, address buyer, uint tokenId, Monetary.Crypto memory price) external nonReentrant exists(saleId) only(sales[saleId].seller) {
        Sale storage sale = sales[saleId];
        Offer storage offer = offers[buyer][saleId][tokenId];
        require(offer.price.isEqualTo(price), "offer has changed");
        acceptOffer(saleId, sale, offer, buyer, tokenId);
    }

    function acceptOffer(uint saleId, Sale storage sale, Offer storage offer, address buyer, uint tokenId) private {
        uint balance = balanceOf(sale.asset.collection, sale.seller, tokenId);
        uint available = (isAllOutSale(saleId) || sale.asset.amount >= balance) ? balance : sale.asset.amount;
        if (available < offer.asset.amount) revert InsufficientTokens(saleId, offer.asset.amount, available);
        exchange(saleId, Asset(sale.asset.collection, tokenId, offer.asset.amount), offer.price, sale.seller, buyer);
        if (!isAllOutSale(saleId)) {
            sale.asset.amount -= offer.asset.amount;
            if (sale.asset.amount == 0) delete sales[saleId];
        }
        delete offers[buyer][saleId][tokenId];
    }

    function exchange(uint saleId, Asset memory asset, Monetary.Crypto memory price, address from, address to) internal virtual override {
        deliverSoldToken(saleId, asset, price, from, to);
        deliverPayment(saleId, asset, price.multipliedBy(asset.amount), from);
    }

    // the seller wishes to cancel sale of remaining tokens in collection
    function cancel(uint saleId) external exists(saleId) only(sales[saleId].seller) {
        emit Canceled(saleId, sales[saleId].asset);
        delete sales[saleId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../token/ERC2981/IERC2981.sol";
import "../utils/HasCosts.sol";
import "../utils/HasFees.sol";
import "../utils/Monetary.sol";


abstract contract Marketplace is ERC721Holder, ERC1155Holder, HasCosts, HasFees {
    using Address for address payable;
    using Monetary for Monetary.Crypto;

    struct Asset {
        address collection;
        uint tokenId;
        uint amount;
    }

    event Sold(uint id, address seller, address buyer, Asset asset, Monetary.Crypto price);
    event PaymentDelivered(uint id, Asset asset, address seller, Monetary.Crypto payment, Monetary.Crypto royalty, Monetary.Crypto fee);

    /// Marketplace `id` does not exist; it may have been deleted
    error NoSuchMarketplace(uint id);

    /// Marketplace `id` cannot provide sufficient tokens; requested `requested`, but only `provided` is provided
    error InsufficientTokens(uint id, uint requested, uint provided);

    function validate(Asset memory asset) internal view {
        require(asset.amount != 0, "token amount must be positive");
        if (IERC165(asset.collection).supportsInterface(type(IERC721).interfaceId))
            require(
                IERC721(asset.collection).getApproved(asset.tokenId) == address(this) || IERC721(asset.collection).isApprovedForAll(msg.sender, address(this)),
                "ERC721: token or contract not approved for transfer"
            );
        else if (IERC165(asset.collection).supportsInterface(type(IERC1155).interfaceId))
            require(IERC1155(asset.collection).isApprovedForAll(msg.sender, address(this)), "ERC1155: contract not approved for transfer");
        else
            revert("only ERC721 & ERC1155 collections are supported");
    }

    function balanceOf(address collection, address owner, uint tokenId) internal view returns (uint) {
        return IERC165(collection).supportsInterface(type(IERC1155).interfaceId) ?
            IERC1155(collection).balanceOf(owner, tokenId) :
            IERC721(collection).ownerOf(tokenId) == owner ? 1 : 0;
    }

    function transfer(Asset memory asset, address from, address to) internal {
        if (IERC165(asset.collection).supportsInterface(type(IERC721).interfaceId))
            IERC721(asset.collection).safeTransferFrom(from, to, asset.tokenId);
        else
            IERC1155(asset.collection).safeTransferFrom(from, to, asset.tokenId, asset.amount, bytes(""));
    }

    function exchange(uint id, Asset memory asset, Monetary.Crypto memory price, address from, address to) internal virtual {
        deliverSoldToken(id, asset, price, address(this), to);
        deliverPayment(id, asset, price, from);
    }

    function deliverSoldToken(uint id, Asset memory asset, Monetary.Crypto memory price, address from, address to) internal {
        transfer(asset, from, to);
        emit Sold(id, from, to, asset, price);
    }

    function royaltyInfo(Asset memory asset, Monetary.Crypto memory price) private view returns (address, Monetary.Crypto memory) {
        (address receiver, uint amount) = IERC165(asset.collection).supportsInterface(type(IERC2981).interfaceId) ?
            IERC2981(asset.collection).royaltyInfo(asset.tokenId, price.amount) :
            (address(0), 0);
        return (receiver, Monetary.Crypto(amount, price.currency));
    }

    function deliverPayment(uint id, Asset memory asset, Monetary.Crypto memory total, address seller) internal {
        (address royaltyRecipient, Monetary.Crypto memory royalty) = royaltyInfo(asset, total);
        (address feeRecipient, Monetary.Crypto memory fee) = feeInfo(total);
        Monetary.Crypto memory payment = total.minus(royalty).minus(fee);
        royalty.transferTo(royaltyRecipient);
        fee.transferTo(feeRecipient);
        payment.transferTo(seller);
        emit PaymentDelivered(id, asset, seller, payment, royalty, fee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";


/**
 * @dev Implementation of the basic standard multi-token.
 * see https://eips.ethereum.org/EIPS/eip-1155
 * based on https://docs.openzeppelin.com/contracts/4.x/api/token/erc1155#ERC1155
 */
contract ERC1155 is ERC165, IERC1155, ReentrancyGuard {
    using Address for address;

    /// cannot use the zero address
    error InvalidAddress();

    /// owner `owner` does not have sufficient amount of token `id`; requested `requested`, but has only `owned` is owned
    error InsufficientTokens(uint id, address owner, uint owned, uint requested);

    /// sender `operator` is not owner nor approved to transfer
    error UnauthorizedTransfer(address operator);

    /// receiver `receiver` has rejected token(s) transfer`
    error ERC1155ReceiverRejectedTokens(address receiver);

    mapping(uint => mapping(address => uint)) internal balances; // tokenId => account => balance
    mapping(address => mapping(address => bool)) internal operatorApprovals; // account => operator => approval

    modifier valid(address account) { if (account == address(0)) revert InvalidAddress(); _; }

    modifier canTransfer(address from) { if (from != msg.sender && !isApprovedForAll(from, msg.sender)) revert UnauthorizedTransfer(msg.sender); _; }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address account, uint id) public view virtual override valid(account) returns (uint) {
        return balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint[] memory ids) external view virtual override returns (uint[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");
        uint[] memory batchBalances = new uint[](accounts.length);
        for (uint i = 0; i < accounts.length; ++i) batchBalances[i] = balanceOf(accounts[i], ids[i]);
        return batchBalances;
    }

    function setApprovalForAll(address operator, bool approved) external {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    /// @dev Approve `operator` to operate on all of `owner` tokens
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return operatorApprovals[account][operator];
    }

    /**
     * @dev transfer `amount` tokens of token type `id` from `from` to `to`.
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received}
     *   and return the acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint id, uint amount, bytes memory data) external virtual override nonReentrant canTransfer(from) valid(to) {
        _safeTransferFrom(from, to, id, amount, data);
        emit TransferSingle(msg.sender, from, to, id, amount);
        _doSafeTransferAcceptanceCheck(msg.sender, from, to, id, amount, data);
    }

    function _safeTransferFrom(address from, address to, uint id, uint amount, bytes memory) internal virtual {
        uint balance = balances[id][from];
        if (balance < amount) revert InsufficientTokens(id, from, balance, amount);
        balances[id][from] = balance - amount;
        balances[id][to] += amount;
    }

    function safeBatchTransferFrom(address from, address to, uint[] memory ids, uint[] memory amounts, bytes memory data) external virtual override nonReentrant canTransfer(from) valid(to) {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        for (uint i = 0; i < ids.length; ++i) _safeTransferFrom(from, to, ids[i], amounts[i], data);
        emit TransferBatch(msg.sender, from, to, ids, amounts);
        _doSafeBatchTransferAcceptanceCheck(msg.sender, from, to, ids, amounts, data);
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint id,
        uint amount,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) revert ERC1155ReceiverRejectedTokens(to);
            } catch Error(string memory reason) {
                revert(reason);
            } // otherwise do nothing
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint[] memory ids,
        uint[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) revert ERC1155ReceiverRejectedTokens(to);
            } catch Error(string memory reason) {
                revert(reason);
            } // otherwise do nothing
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/extensions/IERC1155MetadataURI.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../ERC1155.sol";
import "../../../utils/structs/Bits.sol";


/**
 * @dev an ERC1155 that has a fixed supply for all its tokens.
 * it is created with an implicit finite set of 256 tokens, as the token id range is [1-256].
 * minting happens implicitly when only a portion of fixed supply is transferred.
 */
contract ERC1155PreMintedCollection is ERC1155, IERC1155MetadataURI {
    using Address for address payable;
    using Address for address;
    using Bits for Bits.Bitmap;

    address public creator;
    string public name;
    string public symbol;
    string public baseURI; // used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    uint public howManyTokens;
    uint public supplyPerToken;
    Bits.Bitmap private notOwnedByCreator; // in the beginning, creator owns it all (using reverse logic: 0 indicates ownership)

    constructor(
        string memory _name,
        string memory _symbol,
        uint _howManyTokens,
        uint _supplyPerToken,
        string memory _baseURI
    ) {
        creator = tx.origin;
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
        supplyPerToken = _supplyPerToken;
        howManyTokens = _howManyTokens;
    }

    function isOwnedByCreator(uint id) public view returns (bool) { return !notOwnedByCreator.get(id); }

    /// @dev for tracing
    function creatorOwnershipBitMap() external view returns (uint[] memory) {
        return notOwnedByCreator.toArray(howManyTokens);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC1155) returns (bool) {
        return
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function exists(uint id) public view virtual returns (bool) { return 0 <= id && id < howManyTokens; }

    function totalSupply(uint id) public view virtual returns (uint) { return exists(id) ? supplyPerToken : 0; }

    /**
     * This implementation relies on the token type ID substitution mechanism.
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the actual token type ID.
     */
    function uri(uint tokenId) public view virtual override returns (string memory) {
        require(exists(tokenId), "IERC1155MetadataURI: uri query for nonexistent token");
        return string(abi.encodePacked(baseURI, "/", uint2str(tokenId), ".json"));
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function balanceOf(address account, uint id) public view override(IERC1155, ERC1155) virtual returns (uint) {
        uint balance = super.balanceOf(account, id);
        return balance > 0 ?
            balance :
            account == creator && isOwnedByCreator(id) ?
                supplyPerToken :
                0;
    }

    function _safeTransferFrom(address from, address to, uint id, uint amount, bytes memory data) internal virtual override {
        if (from == creator && isOwnedByCreator(id)) {
            notOwnedByCreator.set(id);
            balances[id][creator] += supplyPerToken;
        }
        super._safeTransferFrom(from, to, id, amount, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint,uint)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty is owed and to whom.
    /// @param id - the NFT asset queried for royalty information
    /// @param salePrice - the sale price of the NFT asset specified by id
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for salePrice
    function royaltyInfo(uint id, uint salePrice) external view returns (address receiver, uint royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


abstract contract HasAuthorization {

    /// sender is not authorized for this action
    error Unauthorized();

    modifier only(address authorized) { if (msg.sender != authorized) revert Unauthorized(); _; }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "./Monetary.sol";


abstract contract HasCosts {
    using Address for address payable;
    using Monetary for Monetary.Crypto;

    /// Not enough funds for transfer; requested `requested`, but only `available` available
    error InsufficientFunds(Monetary.Crypto requested, Monetary.Crypto available);

    /// pre-condition: requires a certain fee being associated with the call.
    /// post-condition: if value sent is greater than the fee, the difference will be refunded.
    modifier costs(Monetary.Crypto memory cost) {
        Monetary.Crypto memory crypto = Monetary.Native(msg.value);
        if (cost.isGreaterThan(crypto)) revert InsufficientFunds(cost, crypto);
        _;
        if (crypto.isGreaterThan(cost)) crypto.minus(cost).transferTo(msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./HasOwners.sol";
import "./Monetary.sol";


abstract contract HasFees is HasOwners {
    using Monetary for Monetary.Crypto;

    struct FeeInfo {
        address recipient;
        uint24 basispoints;
    }

    FeeInfo public fees;

    constructor(address[] memory owners, address recipient, uint24 basispoints) HasOwners(owners) {
        setFees_(recipient, basispoints);
    }

    function setFees(address recipient, uint24 basispoints) external onlyOwner {
        setFees_(recipient, basispoints);
    }

    function setFees_(address recipient, uint24 basispoints) private {
        require(basispoints <= 10000, "HasFees: fee basispoints too high");
        fees.recipient = recipient;
        fees.basispoints = basispoints;
    }

    function feeInfo(Monetary.Crypto memory price) internal view returns (address receiver, Monetary.Crypto memory fee) {
        receiver = fees.recipient;
        fee = price.multipliedBy(fees.basispoints).dividedBy(10000);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


/// @notice providing an ownership access control mechanism
abstract contract HasOwners {

  event OwnerAdded(address indexed owner);
  event OwnerRemoved(address indexed owner);

  /// cannot use the zero address
  error InvalidAddress();

  address[] public owners;
  mapping(address => bool) public isOwner;

  constructor(address[] memory owners_) {
    require(owners_.length > 0, "there must be at least one owner");
    for (uint i = 0; i < owners_.length; i++) addOwner_(owners_[i]);
  }

  modifier onlyOwner { require(isOwner[msg.sender], "invalid sender; must be owner"); _; }

  modifier valid(address account) { if (account == address(0)) revert InvalidAddress(); _; }

  function getOwners() public view returns (address[] memory) { return owners; }

  function addOwner(address owner) external onlyOwner { addOwner_(owner); }

  function addOwner_(address owner) private valid(owner) {
    if (!isOwner[owner]) {
      isOwner[owner] = true;
      owners.push(owner);
      emit OwnerAdded(owner);
    }
  }

  /// @notice revoke an `account` owner access (while ensuring at least one owner remains)
  function removeOwner(address owner) external onlyOwner {
    require(isOwner[owner], 'only owners can be removed');
    require(owners.length > 1, 'can not remove last owner');
    isOwner[owner] = false;
    for (uint i = 0; i < owners.length; i++) {
      if (owners[i] == owner) {
        owners[i] = owners[owners.length - 1];
        owners.pop();
        emit OwnerRemoved(owner);
        break;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";


library Monetary {
    using Address for address;
    using Address for address payable;
    using SafeERC20 for IERC20;

    struct Crypto {
        uint amount;
        address currency;
    }

    error UnsupportedCurrency(address currency);

    address constant NativeCurrency = address(0);

    function Native(uint amount) public pure returns (Monetary.Crypto memory) { return Crypto(amount, NativeCurrency); }
    function Zero(address currency) public pure returns (Monetary.Crypto memory) { return Crypto(0, currency); }

    function isNative(Monetary.Crypto memory self) internal pure returns (bool) { return self.currency == NativeCurrency; }

    function isZero(Monetary.Crypto memory self) internal pure returns (bool) { return self.amount == 0; }

    function isValidCurrency(address currency) internal view returns (bool) {
        return currency.isContract();
    }

    function isEqualTo(Monetary.Crypto memory self, Monetary.Crypto memory other) internal pure returns (bool) {
        return self.currency == other.currency && self.amount == other.amount;
    }

    function isGreaterThan(Monetary.Crypto memory self, Monetary.Crypto memory other) internal pure returns (bool) {
        require(self.currency == other.currency, "incompatible currency");
        return self.amount > other.amount;
    }

    function plus(Monetary.Crypto memory self, Monetary.Crypto memory other) internal pure returns (Monetary.Crypto memory) {
        require(self.currency == other.currency, "incompatible currency");
        return Crypto(self.amount + other.amount, self.currency);
    }

    function minus(Monetary.Crypto memory self, Monetary.Crypto memory other) internal pure returns (Monetary.Crypto memory) {
        require(self.currency == other.currency, "incompatible currency");
        return Crypto(self.amount - other.amount, self.currency);
    }

    function multipliedBy(Monetary.Crypto memory self, uint value) internal pure returns (Monetary.Crypto memory) {
        return Crypto(self.amount * value, self.currency);
    }

    function dividedBy(Monetary.Crypto memory self, uint value) internal pure returns (Monetary.Crypto memory) {
        return Crypto(self.amount / value, self.currency);
    }

    function transferFromSender(Monetary.Crypto memory self) internal {
        if (!isZero(self)) {
            if (isValidCurrency(self.currency)) IERC20(self.currency).safeTransferFrom(msg.sender, address(this), self.amount);
            else revert UnsupportedCurrency(self.currency);
        }
    }

    function transferTo(Monetary.Crypto memory self, address recipient) internal {
        if (!isZero(self)) {
            if (isNative(self)) payable(recipient).sendValue(self.amount);
            else if (isValidCurrency(self.currency)) IERC20(self.currency).safeTransfer(recipient, self.amount);
            else revert UnsupportedCurrency(self.currency);
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


/**
 * @dev Library for managing uint to bool mapping in a compact and efficient way, providing the keys are sequential.
 * based on https://docs.openzeppelin.com/contracts/4.x/api/utils#BitMaps
 */
library Bits {

    struct Bitmap {
        mapping(uint => uint) data;
    }

    uint constant internal ONES = ~uint(0);

    function get(Bitmap storage self, uint index) internal view returns (bool) {
        uint bucket = index >> 8;
        uint mask = 1 << (index & 0xff);
        return self.data[bucket] & mask != 0;
    }

    function set(Bitmap storage self, uint index) internal {
        uint bucket = index >> 8;
        uint mask = 1 << (index & 0xff);
        self.data[bucket] |= mask;
    }

    function setAll(Bitmap storage self, uint size) internal {
        uint fullBuckets = size >> 8;
        if (fullBuckets > 0) for (uint i = 0; i < fullBuckets; i++) self.data[i] = ONES;
        uint remaining = size & 0xff;
        if(remaining == 0 ) return ;
        self.data[fullBuckets] = ONES >> (256 - remaining);
    }

    function unset(Bitmap storage self, uint index) internal {
        uint bucket = index >> 8;
        uint mask = 1 << (index & 0xff);
        self.data[bucket] &= ~mask;
    }

    function toggle(Bitmap storage self, uint index) internal {
        setTo(self, index, !get(self, index));
    }

    function setTo(Bitmap storage self, uint index, bool value) private {
        value ? set(self, index) : unset(self, index);
    }

    /// @dev for tracing
    function toArray(Bitmap storage self, uint size) internal view returns (uint[] memory result) {
        result = new uint[]((size >> 8) + ((size & 0xff) > 0 ? 1 : 0));
        for (uint i = 0; i < result.length; i++) result[i] = self.data[i];
    }
}