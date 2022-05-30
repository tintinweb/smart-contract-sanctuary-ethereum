//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './SwapMarketplace.sol';

contract UnistoryMarketplace is SwapMarketplaceInterface, Ownable {
	uint256 public orderIndex;

	mapping(uint256 => SwapOrder) public SwapOrders;

	/*
	 * Order events
	 */
	event OrderCreated(uint256 indexed orderId);

	event OrderClosed(uint256 indexed orderId);

	/*
	 * Proposals events
	 */
	event ProposalMade(uint256 orderId, uint256 proposalId);

	event ProposalCanceled(uint256 orderId, uint256 proposalId);

	/*
	 * Orders functions
	 */
	function createOrder(OfferItem calldata _offerItem, address _considCollection) external {
		IERC721 collection = IERC721(_considCollection);

		require(msg.sender == collection.ownerOf(_offerItem.tokenId), 'You are not the owner of token');
		require(
			address(this) == collection.getApproved(_offerItem.tokenId),
			'You did`t approve token to smart contract'
		);

		SwapOrder storage newOrder = SwapOrders[orderIndex + 1];

		newOrder.offerer = msg.sender;
		newOrder.offerItem = _offerItem;
		newOrder.considCollection = _considCollection;
		newOrder.isActive = true;

		emit OrderCreated(orderIndex);
		orderIndex++;
	}

	function cancelOrder(uint256 orderId) external {
		SwapOrder storage order = SwapOrders[orderId];

		require(msg.sender == order.offerer, 'Only creator of order can cancel it');
		require(order.isActive, 'Order is already closed');

		order.isActive = false;

		emit OrderClosed(orderId);
	}

	function execute(uint256 orderId, uint256 proposalId) external {
		SwapOrder storage order = SwapOrders[orderId];
		Proposal storage proposal = order.proposals[proposalId];

		IERC721 offeredCollection = IERC721(order.offerItem.collection);
		IERC721 considCollection = IERC721(order.considCollection);

		require(msg.sender == order.offerer, 'Only creator of order can confirm proposal');

		// Order and proposal must be active
		require(order.isActive, 'Order was canceled');
		require(proposal.isActive, 'Proposal was canceled');

		require(proposal.proposer != address(0), 'Invalid proposal');

		// Offerer and proposer still should be the owners
		require(order.offerer == offeredCollection.ownerOf(order.offerItem.tokenId), 'You are not the owner of token');
		require(proposal.proposer == considCollection.ownerOf(proposal.tokenId), 'Proposer not the owner of token');

		// Offered and proposed tokens must be apporved
		require(
			address(this) == offeredCollection.getApproved(order.offerItem.tokenId),
			'You did`t approve token for smart contract'
		);
		require(
			address(this) == considCollection.getApproved(proposal.tokenId),
			'Proposer did`t approve token for smart contract'
		);

		offeredCollection.safeTransferFrom(order.offerer, proposal.proposer, order.offerItem.tokenId);
		considCollection.safeTransferFrom(proposal.proposer, order.offerer, proposal.tokenId);

		order.isActive = false;

		emit OrderClosed(orderId);
	}

	/*
	 * Proposals functions
	 */
	function makeProposal(uint256 orderId, uint256 tokenId) external returns (uint256 proposalId) {
		SwapOrder storage order = SwapOrders[orderId];

		IERC721 collection = IERC721(order.considCollection);

		require(order.isActive, 'Order is no longer active');
		require(msg.sender == collection.ownerOf(tokenId), 'Caller is not the owner of token');
		require(address(this) == collection.getApproved(tokenId), '');

		Proposal memory newProposal = Proposal(msg.sender, tokenId, true);

		order.proposals[order.proposalIndex] = newProposal;
		order.proposalIndex++;

		emit ProposalMade(orderId, proposalId);
	}

	function cancelProposal(uint256 orderId, uint256 proposalId) external returns (uint256) {
		SwapOrder storage order = SwapOrders[orderId];
		Proposal storage proposal = order.proposals[proposalId];

		require(msg.sender == proposal.proposer, 'Only creator of proposal can cancel it');

		proposal.isActive = false;

		emit ProposalCanceled(orderId, proposalId);
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT

struct SwapOrder {
	address offerer;
	OfferItem offerItem;
	address considCollection;
	bool isActive;
	uint256 proposalIndex;
	mapping(uint256 => Proposal) proposals;
}

struct OfferItem {
	address collection;
	uint256 tokenId;
}

struct Proposal {
	address proposer;
	uint256 tokenId;
	bool isActive;
}

interface SwapMarketplaceInterface {
	/*
	 * Orders functions
	 */
	function createOrder(OfferItem calldata offer, address considCollection) external;

	function cancelOrder(uint256 orderId) external;

	function execute(uint256 orderId, uint256 proposalId) external;

	/*
	 * Proposals functions
	 */
	function makeProposal(uint256 orderId, uint256 tokenId) external returns (uint256 proposalId);

	function cancelProposal(uint256 orderId, uint256 proposalId) external returns (uint256);
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