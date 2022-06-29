/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


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

// File: contracts/p2p.sol



pragma solidity >=0.8.9 <0.9.0;







// import "@openzeppelin/contracts/utils/Counters.sol";
// import "@openzeppelin/contracts/security/Pausable.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract p2p is Ownable, ReentrancyGuard, ERC721Holder, ERC1155Holder {

	uint64 private _swapsCounter;
	uint256 private _etherLocked;
	uint256 public fee;
    address private beneficiary;

	mapping (uint64 => Swap) private _swaps;

	struct Swap {
		address payable initiator;
		address[] initiatorNftAddresses;
		uint256[] initiatorNftIds;
		uint256[] initiatorNftAmounts;
		address payable secondUser;
		address[] secondUserNftAddresses;
		uint256[] secondUserNftIds;
		uint256[] secondUserNftAmounts;
		uint256 initiatorEtherValue;
		uint256 secondUserEtherValue;
	}

    event SwapExecuted(address indexed from, address indexed to, uint64 indexed swapId);

	event SwapCanceled(address indexed canceledBy, uint64 indexed swapId);

	event SwapProposed(
		address indexed from,
		address indexed to,
		uint64 indexed swapId,
		uint256 etherValue,
		address[] nftAddresses,
		uint256[] nftIds,
		uint256[] nftAmounts
	);

	event SwapInitiated(
		address indexed from,
		address indexed to,
		uint64 indexed swapId,
		uint256 etherValue,
		address[] nftAddresses,
		uint256[] nftIds,
		uint256[] nftAmounts
	);

	event AppFeeChanged(
		uint256 fee
	);

	modifier onlyInitiator(uint64 swapId) {
		require(msg.sender == _swaps[swapId].initiator,
			"Caller is not swap initiator");
		_;
	}

	modifier requireSameLength(address[] memory nftAddresses, uint256[] memory nftIds, uint256[] memory nftAmounts) {
		require(nftAddresses.length == nftIds.length, "NFT and ID arrays have to be same length");
		require(nftAddresses.length == nftAmounts.length, "NFT and AMOUNT arrays have to be same length");
		_;
	}

	modifier chargeAppFee() {
		require(msg.value >= fee, "Sent ETH amount needs to be more or equal application fee");
		_;
	}

    constructor(uint256 initalAppFee, address contractOwnerAddress, address _beneficiary) {
		fee = initalAppFee;
        setBeneficiary(_beneficiary);
		super.transferOwnership(contractOwnerAddress);
	}

	function setAppFee(uint256 newFee) external onlyOwner {
		fee = newFee;
		emit AppFeeChanged(newFee);
	}

    //--------------- SWAP FUNCTION ------------------------------------------------------------

	/**
	* @dev First user proposes a swap to the second user with the NFTs that he deposits and wants to trade.
	*      Proposed NFTs are transfered to this contract and
	*      kept there until the swap is accepted or canceled/rejected.
	*
	* @param secondUser address of the user that the first user wants to trade NFTs with
	* @param nftAddresses array of NFT addressed that want to be traded
	* @param nftIds array of IDs belonging to NFTs that want to be traded
	* @param nftAmounts array of NFT amounts that want to be traded. If the amount is zero, that means 
	* the token is ERC721 token. Otherwise the token is ERC1155 token.
	*/
    function proposeSwap(
		address secondUser,
		address[] memory nftAddresses,
		uint256[] memory nftIds,
		uint256[] memory nftAmounts
	) external payable chargeAppFee requireSameLength(nftAddresses, nftIds, nftAmounts) {
		_swapsCounter += 1;

		safeMultipleTransfersFrom(
			msg.sender,
			address(this),
			nftAddresses,
			nftIds,
			nftAmounts
		);

		Swap storage swap = _swaps[_swapsCounter];
		swap.initiator = payable(msg.sender);
		swap.initiatorNftAddresses = nftAddresses;
		swap.initiatorNftIds = nftIds;
		swap.initiatorNftAmounts = nftAmounts;

		uint256 _fee = fee;

		if (msg.value > _fee) {
			swap.initiatorEtherValue = uint256(msg.value) - _fee;
			_etherLocked += swap.initiatorEtherValue;
		}
		swap.secondUser = payable(secondUser);

		emit SwapProposed(
			msg.sender,
			secondUser,
			_swapsCounter,
			swap.initiatorEtherValue,
			nftAddresses,
			nftIds,
			nftAmounts
		);
	}

    /**
	* @dev Second user accepts the swap (with proposed NFTs) from swap initiator and
	*      deposits his NFTs into this contract.
	*      Callable only by second user that is invited by swap initiator.
	*
	* @param swapId ID of the swap that the second user is invited to participate in
	* @param nftAddresses array of NFT addressed that want to be traded
	* @param nftIds array of IDs belonging to NFTs that want to be traded
	* @param nftAmounts array of NFT amounts that want to be traded. If the amount is zero, that means 
	* the token is ERC721 token. Otherwise the token is ERC1155 token.
	*/
    function initiateSwap(
		uint64 swapId,
		address[] memory nftAddresses,
		uint256[] memory nftIds,
		uint256[] memory nftAmounts
	) external payable chargeAppFee requireSameLength(nftAddresses, nftIds, nftAmounts) {
		require(_swaps[swapId].secondUser == msg.sender, "Caller is not swap participator");
		require(
			_swaps[swapId].secondUserEtherValue == 0 &&
			( _swaps[swapId].secondUserNftAddresses.length == 0 &&
			_swaps[swapId].secondUserNftIds.length == 0 &&
			_swaps[swapId].secondUserNftAmounts.length == 0
			), "Swap already initiated"
		);

		safeMultipleTransfersFrom(
			msg.sender,
			address(this),
			nftAddresses,
			nftIds,
			nftAmounts
		);

		_swaps[swapId].secondUserNftAddresses = nftAddresses;
		_swaps[swapId].secondUserNftIds = nftIds;
		_swaps[swapId].secondUserNftAmounts = nftAmounts;

		uint256 _fee = fee;

		if (msg.value > _fee) {
			_swaps[swapId].secondUserEtherValue = uint256(msg.value) - _fee;
			_etherLocked += _swaps[swapId].secondUserEtherValue;
		}

		emit SwapInitiated(
			msg.sender,
			_swaps[swapId].initiator,
			swapId,
			_swaps[swapId].secondUserEtherValue,
			nftAddresses,
			nftIds,
			nftAmounts
		);
	}

	/**
	* @dev Swap initiator accepts the swap (NFTs proposed by the second user).
	*      Executeds the swap - transfers NFTs from this conntract to the participating users.
	*      Callable only by swap initiator.
	*
	* @param swapId ID of the swap that the initator wants to execute
	*/
    function acceptSwap(uint64 swapId) external onlyInitiator(swapId) {
		require(
			(_swaps[swapId].secondUserNftAddresses.length != 0 || _swaps[swapId].secondUserEtherValue > 0) &&
			(_swaps[swapId].initiatorNftAddresses.length != 0 || _swaps[swapId].initiatorEtherValue > 0),
			"Can't accept swap, both participants didn't add NFTs"
		);

		// transfer NFTs from escrow to initiator
		safeMultipleTransfersFrom(
			address(this),
			_swaps[swapId].initiator,
			_swaps[swapId].secondUserNftAddresses,
			_swaps[swapId].secondUserNftIds,
			_swaps[swapId].secondUserNftAmounts
		);

		// transfer NFTs from escrow to second user
		safeMultipleTransfersFrom(
			address(this),
			_swaps[swapId].secondUser,
			_swaps[swapId].initiatorNftAddresses,
			_swaps[swapId].initiatorNftIds,
			_swaps[swapId].initiatorNftAmounts
		);

		if (_swaps[swapId].initiatorEtherValue != 0) {
			_etherLocked -= _swaps[swapId].initiatorEtherValue;
			uint256 amountToTransfer = _swaps[swapId].initiatorEtherValue;
			_swaps[swapId].initiatorEtherValue = 0;
			_swaps[swapId].secondUser.transfer(amountToTransfer);
		}
		if (_swaps[swapId].secondUserEtherValue != 0) {
			_etherLocked -= _swaps[swapId].secondUserEtherValue;
			uint256 amountToTransfer = _swaps[swapId].secondUserEtherValue;
			_swaps[swapId].secondUserEtherValue = 0;
			_swaps[swapId].initiator.transfer(amountToTransfer);
		}

		emit SwapExecuted(_swaps[swapId].initiator, _swaps[swapId].secondUser, swapId);

		delete _swaps[swapId];
	}

    /**
	* @dev Returns NFTs from this contract to swap initator.
	*      Callable only if second user hasn't yet added NFTs.
	*
	* @param swapId ID of the swap that the swap participants want to cancel
	*/
    function cancelSwap(uint64 swapId) external {
		require(
			_swaps[swapId].initiator == msg.sender || _swaps[swapId].secondUser == msg.sender,
			"Can't cancel swap, must be swap participant"
		);
		// return initiator NFTs
		safeMultipleTransfersFrom(
			address(this),
			_swaps[swapId].initiator,
			_swaps[swapId].initiatorNftAddresses,
			_swaps[swapId].initiatorNftIds,
			_swaps[swapId].initiatorNftAmounts
		);

		if(_swaps[swapId].secondUserNftAddresses.length != 0) {
			// return second user NFTs
			safeMultipleTransfersFrom(
				address(this),
				_swaps[swapId].secondUser,
				_swaps[swapId].secondUserNftAddresses,
				_swaps[swapId].secondUserNftIds,
				_swaps[swapId].secondUserNftAmounts
			);
		}

		if (_swaps[swapId].initiatorEtherValue != 0) {
			_etherLocked -= _swaps[swapId].initiatorEtherValue;
			uint256 amountToTransfer = _swaps[swapId].initiatorEtherValue;
			_swaps[swapId].initiatorEtherValue = 0;
			_swaps[swapId].initiator.transfer(amountToTransfer);
		}
		if (_swaps[swapId].secondUserEtherValue != 0) {
			_etherLocked -= _swaps[swapId].secondUserEtherValue;
			uint256 amountToTransfer = _swaps[swapId].secondUserEtherValue;
			_swaps[swapId].secondUserEtherValue = 0;
			_swaps[swapId].secondUser.transfer(amountToTransfer);
		}

		emit SwapCanceled(msg.sender, swapId);

		delete _swaps[swapId];
	}

     //--------------- END OF SWAP FUNCTION ------------------------------------------------------------

    function safeMultipleTransfersFrom(
		address from,
		address to,
		address[] memory nftAddresses,
		uint256[] memory nftIds,
		uint256[] memory nftAmounts
	) internal virtual {
		for (uint256 i=0; i < nftIds.length; i++){
			safeTransferFrom(from, to, nftAddresses[i], nftIds[i], nftAmounts[i], "");
		}
	}

	function safeTransferFrom(
		address from,
		address to,
		address tokenAddress,
		uint256 tokenId,
		uint256 tokenAmount,
		bytes memory _data
	) internal virtual {
		if (tokenAmount == 0) {
			IERC721(tokenAddress).safeTransferFrom(from, to, tokenId, _data);
		} else {
			IERC1155(tokenAddress).safeTransferFrom(from, to, tokenId, tokenAmount, _data);
		}
		
	}

    function setBeneficiary(address _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }

    function withdraw() external onlyOwner nonReentrant {
        require(beneficiary != address(0), "Transfer to the zero address");
        payable(beneficiary).transfer((address(this).balance - _etherLocked));
    }


}