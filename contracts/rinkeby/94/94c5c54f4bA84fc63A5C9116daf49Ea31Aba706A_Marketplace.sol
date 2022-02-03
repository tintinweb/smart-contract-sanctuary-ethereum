/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;
pragma abicoder v2;



// Part: OpenZeppelin/[email protected]/Context

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

// Part: OpenZeppelin/[email protected]/IERC165

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

// Part: OpenZeppelin/[email protected]/IERC721

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// Part: OpenZeppelin/[email protected]/Ownable

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

// File: Marketplace.sol

contract Marketplace is Ownable {
	address public tokenContractAddress; // ERC721 NFT contract address
	address public communityOwnerAddress;
	string public name; // conctract name
	uint8 public decimals; // decimals
	uint16 public totalSupply; // number of NFTs in circulation
	uint16 public royalty; // royalty percentege (expressed in thousandths 0-1000)
	IERC721 private tokenContract; // ERC721 NFT token contract

	struct Offer {
		bool isForSale;
		address seller;
		uint256 value; // in ether
		address onlySellTo; // specify to sell only to a specific person
	}

	struct Bid {
		bool hasBid;
		address bidder;
		uint256 value;
	}

	// map offers and bids for each token
	mapping(uint256 => Offer) public cardsForSale;
	mapping(uint256 => Bid) public cardBids;
	mapping(address => bool) public permitted;

	event OfferForSale(address _from, address _to, uint16 _tokenId, uint256 _value);
	event OfferExecuted(address _from, address _to, uint16 _tokenId, uint256 _value);
	event OfferRevoked(address _from, address _to, uint16 _tokenId, uint256 _value);

	event ModifyOfferValue(address _from, uint16 _tokenId, uint256 _value);
	event ModifyOfferSellTo(address _from, uint16 _tokenId, address _sellOnlyTo);
	event ModifyOfferBoth(address _from, uint16 _tokenId, uint256 _value, address _sellOnlyTo);

	event BidReceived(address _from, address _to, uint16 _tokenId, uint256 _newValue, uint256 _prevValue);
	event BidAccepted(address _from, address _to, uint16 _tokenId, uint256 _value);
	event BidRevoked(address _from, address _to, uint16 _tokenId, uint256 _value);

	event RoyaltyChanged(address _from, uint16 _royalty);

	modifier onlyAllowed() {
		require(permitted[msg.sender], "Unauthorised");
		_;
	}

	constructor(
		address _tokenContract,
		address _communityOwnerAddress,
		string memory _name,
		uint16 _royalty
	) {
		require(royalty <= 10000, "Royalty value should be below 10000.");
		name = _name; // set the name for display purposes
		decimals = 0; // amount of decimals for display purposes - unused right now
		tokenContractAddress = _tokenContract;
		communityOwnerAddress = _communityOwnerAddress;
		royalty = _royalty;
		totalSupply = 10000;

		tokenContract = IERC721(_tokenContract); // initialize the NFT contract
		permitted[msg.sender] = true; // sender is going to be permitted to change royalty
		permitted[communityOwnerAddress] = true; // community owner address
	}

	function _split(address _seller, uint256 _amount) internal {
		uint256 royaltyAmount = (royalty * _amount) / 10000;
		uint256 sellerAmount = _amount - royaltyAmount;
		bool sent;

		(sent, ) = _seller.call{ value: sellerAmount }("");
		require(sent, "Failed to send ether");
		(sent, ) = communityOwnerAddress.call{ value: royaltyAmount }("");
		require(sent, "Failed to send ether");
	}

	// set the percentage for royalty (expressed in ten-thousandths)
	function setSplitTenThousandths(uint16 _royalty) external onlyAllowed {
		require(_royalty < 10000, "Royalty over 100%.");
		royalty = _royalty;

		emit RoyaltyChanged(msg.sender, royalty);
	}

	function offerCardForSale(uint16 _tokenId, uint256 _minPriceInWei) external {
		// check if the contract is approved by token owner
		require(tokenContract.isApprovedForAll(msg.sender, address(this)), "Contract is not approved.");
		// check if the offerer owns the card
		require(msg.sender == tokenContract.ownerOf(_tokenId), "Sender does not own this token.");
		// check if card id is correct
		require(_tokenId < totalSupply, "Token ID should be smaller than total supply.");
		// check if price is set to higher than 0
		require(_minPriceInWei > 0, "Price should be higher than 0.");
		// initialize offer for only 1 buyer - _sellOnlyTo
		cardsForSale[_tokenId] = Offer(true, msg.sender, _minPriceInWei, address(0));

		// emit sale event
		emit OfferForSale(msg.sender, address(0), _tokenId, _minPriceInWei);
	}

	function offerCardForSale(
		uint16 _tokenId,
		uint256 _minPriceInWei,
		address _sellOnlyTo
	) external {
		// check if the contract is approved by token owner
		require(tokenContract.isApprovedForAll(msg.sender, address(this)), "Contract is not approved.");
		// check if the offerer owns the card
		require(msg.sender == tokenContract.ownerOf(_tokenId), "Sender does not own this token.");
		// check if card id is correct
		require(_tokenId < totalSupply, "Token ID should be smaller than total supply.");
		// check if price is set to higher than 0
		require(_minPriceInWei > 0, "Price should be higher than 0.");
		// make sure sell only to is not 0x0
		require(_sellOnlyTo != address(0), "Sell only to address cannot be null.");
		// initialize offer for only 1 buyer - _sellOnlyTo
		cardsForSale[_tokenId] = Offer(true, msg.sender, _minPriceInWei, _sellOnlyTo);

		// emit sale event
		emit OfferForSale(msg.sender, _sellOnlyTo, _tokenId, _minPriceInWei);
	}

	function modifyOffer(uint16 _tokenId, uint256 _value) external {
		Offer memory offer = cardsForSale[_tokenId];
		require(msg.sender == offer.seller, "Sender is not the seller of this token."); // check if the offer is active and the seller is the sender
		require(_value > 0, "Price should be higher than 0."); // change value has to be higher than 0
		// modify offer
		cardsForSale[_tokenId] = Offer(offer.isForSale, offer.seller, _value, offer.onlySellTo);

		// emit modification event
		emit ModifyOfferValue(msg.sender, _tokenId, _value);
	}

	function modifyOffer(uint16 _tokenId, address _sellOnlyTo) external {
		Offer memory offer = cardsForSale[_tokenId];
		require(msg.sender == offer.seller, "Sender is not the seller of this token."); // check if the offer is active and the seller is the sender
		// modify offer
		cardsForSale[_tokenId] = Offer(offer.isForSale, offer.seller, offer.value, _sellOnlyTo);

		// emit modification event
		emit ModifyOfferSellTo(msg.sender, _tokenId, _sellOnlyTo);
	}

	function modifyOffer(
		uint16 _tokenId,
		uint256 _value,
		address _sellOnlyTo
	) external {
		Offer memory offer = cardsForSale[_tokenId];
		// check if the offer is active and the seller is the sender
		require(msg.sender == offer.seller, "Sender is not the seller of this token."); // check if the offer is active and the seller is the sender
		// modify offer
		require(_value > 0, "Price should be higher than 0.");
		cardsForSale[_tokenId] = Offer(offer.isForSale, offer.seller, _value, _sellOnlyTo);
		emit ModifyOfferBoth(msg.sender, _tokenId, _value, _sellOnlyTo);
	}

	function revokeOffer(uint16 _tokenId) external {
		Offer memory offer = cardsForSale[_tokenId];
		// check if the offer is ours
		require(msg.sender == offer.seller, "Sender is not the seller of this token."); // check if the offer is active and the seller is the sender

		cardsForSale[_tokenId] = Offer(false, address(0), 0, address(0));
		emit OfferRevoked(offer.seller, offer.onlySellTo, _tokenId, offer.value);
	}

	function buyItNow(uint16 _tokenId) external payable {
		Offer memory offer = cardsForSale[_tokenId];
		// check if it for sale for someone specific
		if (offer.onlySellTo != address(0)) {
			// only sell to someone specific
			require(offer.onlySellTo == msg.sender, "This coin can be sold only for a specific address.");
		}

		// check approval status, user may have modified transfer approval
		require(tokenContract.isApprovedForAll(offer.seller, address(this)), "Contract is not approved.");

		// check if the offer is valid
		require(offer.seller != address(0), "This token is not for sale.");
		// check if offer value is correct
		require(offer.value > 0, "This token is not for sale.");
		// check if offer value and sent values march
		require(offer.value == msg.value, "Offer ask price and sent ETH mismatch.");
		// make sure buyer is not the owner
		require(msg.sender != tokenContract.ownerOf(_tokenId), "Buyer already owns this token.");
		// make sure the seller is the owner
		require(offer.seller == tokenContract.ownerOf(_tokenId), "Seller no longer owns this token.");

		// save the seller variable
		address seller = offer.seller;
		// reset offer for this card
		cardsForSale[_tokenId] = Offer(false, address(0), 0, address(0));

		// check if there were any bids on this card
		Bid memory bid = cardBids[_tokenId];
		if (bid.hasBid) {
			// save bid values and bidder variables
			address bidder = bid.bidder;
			uint256 amount = bid.value;
			// reset bid
			cardBids[_tokenId] = Bid(false, address(0), 0);
			// send back bid value to bidder
			bool sent;
			(sent, ) = bidder.call{ value: amount }("");
			require(sent, "Failed to send back ether to bidder.");
		}

		// first send the token to the buyer
		tokenContract.safeTransferFrom(seller, msg.sender, _tokenId);
		// transfer ether to acceptor and pay royalty to the community owner
		_split(seller, msg.value);

		// check if the user recieved the item
		require(tokenContract.ownerOf(_tokenId) == msg.sender);

		// emit event
		emit OfferExecuted(offer.seller, msg.sender, _tokenId, offer.value);
	}

	function bidOnCard(uint16 _tokenId) external payable {
		address cardOwner = tokenContract.ownerOf(_tokenId);
		// check if card id is valid
		require(_tokenId < totalSupply, "Token ID should be smaller than total supply.");
		// make sure the bidder is not the owner
		require(msg.sender != cardOwner, "Cannot bid on owned card.");
		// check if bid value is valid
		require(msg.value > 0, "Bid price has to be higher than 0.");

		// check if there were any bids on this card
		Bid memory bid = cardBids[_tokenId];
		if (bid.hasBid) {
			// the current bid has to be higher than the previous
			require(bid.value < msg.value, "Bid price is below current bid.");
			address previousBidder = bid.bidder;
			uint256 amount = bid.value;
			// pay back the previous bidder's ether
			bool sent;
			(sent, ) = previousBidder.call{ value: amount }("");
			require(sent, "Failed to send back ether to previous bidder.");
		}

		// initialize the bid with the new values
		cardBids[_tokenId] = Bid(true, msg.sender, msg.value);

		// emit event
		emit BidReceived(msg.sender, cardOwner, _tokenId, msg.value, bid.value);
	}

	function acceptBid(uint16 _tokenId) external {
		Bid memory bid = cardBids[_tokenId];

		// make sure there is a valid bid on the card
		require(bid.hasBid, "This token has no bid on it.");
		// check if the contract is still approved for transfer
		require(tokenContract.isApprovedForAll(msg.sender, address(this)), "Contract is not approved.");
		// check if the token id is valid
		require(_tokenId < totalSupply, "Token ID should be smaller than total supply.");
		// make sure the acceptor owns the card
		require(msg.sender == tokenContract.ownerOf(_tokenId), "Sender does not own this token.");

		// check if the card is offered for sale
		Offer memory offer = cardsForSale[_tokenId];
		if (offer.seller != address(0)) {
			// reset offer if the offer exits
			cardsForSale[_tokenId] = Offer(false, address(0), 0, address(0));
		}

		address buyer = bid.bidder;
		uint256 amount = bid.value;

		// reset bid
		cardBids[_tokenId] = Bid(false, address(0), 0);
		// transfer ether to acceptor and pay royalty to the community owner
		_split(msg.sender, amount);
		// send token from acceptor to the bidder
		tokenContract.safeTransferFrom(msg.sender, buyer, _tokenId);

		// check if the user receiver the
		require(tokenContract.ownerOf(_tokenId) == buyer);

		// emit event
		emit BidAccepted(msg.sender, bid.bidder, _tokenId, amount);
	}

	function revokeBid(uint16 _tokenId) external {
		Bid memory bid = cardBids[_tokenId];
		// check if the bid exists
		require(bid.hasBid, "This token has no bid on it.");
		// check if the bidder is the sender of the message
		require(bid.bidder == msg.sender, "Sender is not the current highest bidder.");
		// save bid value into a variable
		uint256 amount = bid.value;

		// reset bid
		cardBids[_tokenId] = Bid(false, address(0), 0);

		// transfer back their ether
		bool sent;
		(sent, ) = msg.sender.call{ value: amount }("");
		require(sent, "Failed to retrieve ether.");

		// emit event
		emit BidRevoked(msg.sender, bid.bidder, _tokenId, amount);
	}
}