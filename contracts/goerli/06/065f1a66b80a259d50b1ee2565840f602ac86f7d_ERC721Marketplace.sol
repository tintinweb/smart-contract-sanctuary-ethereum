/**
 *Submitted for verification at Etherscan.io on 2023-01-28
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
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
     * 'interfaceId'. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721Permit {
  /// ERC165 bytes to add to interface array - set in parent contract
  ///
  /// _INTERFACE_ID_ERC4494 = 0x5604e225

  /// @notice Function to approve by way of owner signature
  /// @param spender the address to approve
  /// @param tokenId the index of the NFT to approve the spender on
  /// @param deadline a timestamp expiry for the permit
  /// @param sig a traditional or EIP-2098 signature
  function permit(
    address spender,
    uint256 tokenId,
    uint256 deadline,
    bytes memory sig
  ) external;
}

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     * The royalty receivers[] will split the royaltyAmount the addresses.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

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

/* 
* @title Marketplace
* @dev Implements the functionality of a marketplace for NFTs
* @author Wisdom A. https://abkabioye.me
* @notice Contract is not audited, use at your own risk
*/
contract ERC721Marketplace is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;

    Counters.Counter private _itemsSold;

    enum SaleType { Fixed, Auction }
    enum OrderSide { Buy, Sell }

    struct MarketItem {
        address payable seller;
        uint256 price; // sale now price for auction and sale price for fixed
        SaleType saleType;
        uint256 startPrice; // for auction
        uint256 duration; // for Auction
        uint256 endsAt; // for Auction
        bool priceMet; // for Auction
    }

    struct Bid {
        address payable bidder;
        uint256 price;
    }

    struct MarketOrder {
        OrderSide side;
        address payable seller;
        address payable buyer;
        address token;
        uint256 tokenId;
        uint256 price;        
        uint256 deadline;
    }

    mapping(IERC721 => mapping(uint256 => MarketItem)) private _idToMarketItem;
    mapping(IERC721 => mapping(uint256 => Bid)) private _idToBid; // we keep only the highest bid

    uint96 public constant MAX_FEE = 369; // 3.69% * feeBase
    uint96 public fee = 0; // 0.1% = 10
    uint96 public feeBase = 10000; // 100%
    address payable public feeAddress;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    // bytes4 private constant _INTERFACE_ID_ERC4494 = 0x5604e225;

    constructor(address payable _feeAddress, uint96 _fee) {
        setFeeAddress(_feeAddress);
        setFee(_fee);
    }

    event NewFixedListing(
        IERC721 indexed token,
        uint256 tokenId,
        address indexed seller,
        uint256 price
    );

    event NewAuctionListing(
        IERC721 indexed token,
        uint256 tokenId,
        address indexed seller,
        uint256 startPrice,
        uint256 endsAt
    );

    event ListingCancelled(
        IERC721 indexed token,
        uint256 tokenId,
        address seller
    );

    event NewSale(
        IERC721 indexed token,
        uint256 tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 price
    );

    event NewBid(
        IERC721 indexed token,
        uint256 tokenId,
        address indexed bidder,
        uint256 price
    );

    function getListing(IERC721 token, uint256 tokenId) public view returns (MarketItem memory) {
        return _idToMarketItem[token][tokenId];
    }

    function getBid(IERC721 token, uint256 tokenId) public view returns (Bid memory) {
        return _idToBid[token][tokenId];
    }

    /* 
    * CREATE LISTING
    */

    /* 
    * @param token - ERC721 token address
    * @param tokenId - ERC721 token id
    * @param price: buy now price
    */
    function createFixedListing(IERC721 token, uint256 tokenId, uint256 price) public {
        address sender = _msgSender();
        require(token.ownerOf(tokenId) == sender, "You must be the owner of the token");
        require(_idToMarketItem[token][tokenId].seller == address(0), "Item is already on sale");
        require(price > 0, "Start price must be at least 1 wei");

        token.transferFrom(sender, address(this), tokenId);

        _idToMarketItem[token][tokenId] = MarketItem({
            seller: payable(sender),
            price: price,
            saleType: SaleType.Fixed,
            startPrice: 0,
            duration: 0,
            endsAt: 0,
            priceMet: false
        });

        emit NewFixedListing(token, tokenId, sender, price);
    }

    /* 
    * @param token - ERC721 token address
    * @param tokenId - ERC721 token id
    * @param price: buy now price
    * @param startPrice: starting price for auction
    * @param duration: duration of auction in seconds
     */
    function createAuctionListing(IERC721 token, uint256 tokenId, uint256 price, uint256 startPrice, uint256 duration) public {
        address sender = _msgSender();
        require(token.ownerOf(tokenId) == sender, "You must be the owner of the token");
        require(_idToMarketItem[token][tokenId].seller == address(0), "Item is already on sale");
        require(price > startPrice, "Buy now price must be higher than start price");
        require(duration > 0, "Duration must be greater than zero");

        token.transferFrom(sender, address(this), tokenId);

        _idToMarketItem[token][tokenId] = MarketItem({
            seller: payable(sender),
            price: price,
            saleType: SaleType.Auction,
            startPrice: startPrice,
            endsAt: block.timestamp + duration,
            duration: duration,
            priceMet: false
        });

        emit NewAuctionListing(token, tokenId, sender, startPrice, block.timestamp + duration);
    }

    function cancelListing(IERC721 token, uint256 tokenId) external {
        address sender = _msgSender();
        MarketItem memory item = _idToMarketItem[token][tokenId];
        require(item.seller == sender, "You must be the seller of the token");
        require(item.endsAt < block.timestamp, "Auction has not ended yet"); // fixed listing 'endsAt' is always 0
    
        delete _idToMarketItem[token][tokenId];
        
        token.transferFrom(address(this), item.seller, tokenId);
        emit ListingCancelled(token, tokenId, sender);
    }

    function bulkFixedListing(IERC721[] calldata token, uint256[] calldata tokenId, uint256[] calldata price) external {
        require(token.length == tokenId.length, "Token and tokenId must be same length");
        require(token.length == price.length, "Token and price must be same length");

        for (uint256 i = 0; i < token.length; i++) {
            createFixedListing(token[i], tokenId[i], price[i]);
        }
    }
    function bulkAuction(IERC721[] calldata token, uint256[] calldata tokenId, uint256[] calldata price, uint256[] calldata startPrice, uint256[] calldata duration) external {
        require(token.length == tokenId.length, "Token and tokenId must be same length");
        require(token.length == price.length, "Token and price must be same length");
        require(token.length == startPrice.length, "Token and startPrice must be same length");
        require(token.length == duration.length, "Token and duration must be same length");

        for (uint256 i = 0; i < token.length; i++) {
            createAuctionListing(token[i], tokenId[i], price[i], startPrice[i], duration[i]);
        }
    }

    /* 
    * BID
    */
    function createBid(IERC721 token, uint256 tokenId) public payable {
        address sender = _msgSender();
        uint incomingBidPrice = msg.value; // expected to be greater than the last bid or start price
        MarketItem storage item = _idToMarketItem[token][tokenId];
        
        require(item.seller != sender, "You cannot bid on your own item");
        require(item.saleType == SaleType.Auction, "Item is not an auction");
        require(item.endsAt > block.timestamp, "Auction has ended");

        uint256 lastBidPrice = item.startPrice;
        Bid storage bid = _idToBid[token][tokenId];

        if (bid.price > 0) {
            lastBidPrice = bid.price;
            bid.bidder.transfer(bid.price); // will be reverted if the incoming bid value is less than the current bid
        }

        require(incomingBidPrice > lastBidPrice, "Bid must be higher than the last bid");

        if (
            item.duration <= 24 hours &&
            incomingBidPrice >= item.price
        ) {
            // finalise auction immediately
            _finaliseSale(token, tokenId, item, bid);
        } else if (
            item.duration > 24 hours &&
            incomingBidPrice >= item.price &&
            !item.priceMet
        ) {
            // this can only evaluate to true once
            item.priceMet = true;
            item.endsAt = block.timestamp + 24 hours; // extend auction by 24 hours for fair bidding
            
            bid.bidder = payable(sender);
            bid.price = incomingBidPrice;
            emit NewBid(token, tokenId, sender, incomingBidPrice);
    
        } else {
            bid.bidder = payable(sender);
            bid.price = incomingBidPrice;
            emit NewBid(token, tokenId, sender, incomingBidPrice);
        }
    }
    
    /* 
    * Anyone can call this function to finalise an auction
    * This is useful if the auction has ended and the seller has not called acceptBid
    * Auction must have ended, and there must be a bid
    */
    function finaliseAuction(IERC721 token, uint256 tokenId) public nonReentrant {
        MarketItem memory item = _idToMarketItem[token][tokenId];
        Bid memory bid = _idToBid[token][tokenId];
        
        require(item.saleType == SaleType.Auction, "Item is not an auction");
        require(item.endsAt < block.timestamp, "Auction has not ended yet");
        require(bid.price > 0, "No bids have been made");
        
        _finaliseSale(token, tokenId, item, bid);
    }

    function acceptBid(IERC721 token, uint256 tokenId) public nonReentrant {
        MarketItem memory item = _idToMarketItem[token][tokenId];
        require(item.seller == _msgSender(), "You must be the seller of the token");
        require(item.saleType == SaleType.Auction, "Item is not an auction");

        Bid memory bid = _idToBid[token][tokenId];
        require(bid.price > 0, "No bids for this item");
 
        _finaliseSale(token, tokenId, item, bid);
    }

    /* 
    * BUY NOW FOR FIXED LISTING
    */
    function buy(IERC721 token, uint256 tokenId) public payable nonReentrant {
        address sender = _msgSender();
        uint incomingBidPrice = msg.value;

        MarketItem memory item = _idToMarketItem[token][tokenId];
        require(item.seller != sender, "You cannot buy your own item");
        require(item.saleType == SaleType.Fixed, "Item is not a fixed listing");
        require(incomingBidPrice == item.price, "Incorrect price");

        _finaliseSale(token, tokenId, item, Bid(payable(sender), incomingBidPrice));
    }

    function getRoyaltyInfo(address tokenContract, uint tokenId, uint256 salePrice) public view returns (address, uint256) {
        if (_checkRoyalties(tokenContract)) {
            return IERC2981(tokenContract).royaltyInfo(tokenId, salePrice);
        } else {
            return (address(0), 0);
        }
    }

    /* 
    * Atomic buy, instant buy
    */
    function atomicBuy(MarketOrder memory order, bytes memory signature) public payable nonReentrant {
        address sender = _msgSender();
        uint incomingBidPrice = msg.value;

        require(order.buyer == sender, "You must be the buyer of the token");
        require(order.side == OrderSide.Buy, "Wrong order side");
        require(incomingBidPrice == order.price, "Incorrect price");

        IERC721Permit(order.token).permit(
            address(this), 
            order.tokenId, 
            order.deadline, 
            signature
        );

        (address _royaltyAddress, uint256 _royaltyAmount) = getRoyaltyInfo(address(order.token), order.tokenId, order.price);
        uint256 _mfee = _calculateFee(order.price);
        uint256 _sellAmount = order.price - (_mfee + _royaltyAmount);
       
        IERC721(order.token).safeTransferFrom(
            order.seller, 
            order.buyer, 
            order.tokenId
        );
        order.seller.transfer(_sellAmount);
        feeAddress.transfer(_mfee);
       
        if (_royaltyAddress != address(0) && _royaltyAmount > 0) {
            payable(_royaltyAddress).transfer(_royaltyAmount);
        }
        _itemsSold.increment();
        emit NewSale(
            IERC721(order.token), 
            order.tokenId, 
            order.seller, 
            order.buyer, 
            order.price
        );
    }

    /* 
    * INTERNAL FUNCTIONS
    */    
    function _finaliseSale(IERC721 token, uint256 tokenId, MarketItem memory item, Bid memory sale) internal {
        
        delete _idToMarketItem[token][tokenId];
        delete _idToBid[token][tokenId];

        (address _royaltyAddress, uint256 _royaltyAmount) = getRoyaltyInfo(address(token), tokenId, sale.price);
        uint256 _mfee = _calculateFee(sale.price);
        uint256 _sellAmount = sale.price - (_mfee + _royaltyAmount);
        
        token.transferFrom(address(this), sale.bidder, tokenId);
        item.seller.transfer(_sellAmount);
        feeAddress.transfer(_mfee);
        if (_royaltyAddress != address(0) && _royaltyAmount > 0) {
            payable(_royaltyAddress).transfer(_royaltyAmount);
        }
        _itemsSold.increment();
        emit NewSale(token, tokenId, item.seller, sale.bidder, sale.price);
    }

    function _checkRoyalties(address _contract) internal view returns (bool) {
        (bool success) = IERC2981(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
        return success;
    }

    function _calculateFee(uint256 price) internal view returns (uint256) {
        return (price * fee) / feeBase;
    }

    /* 
    * ADMIN FUNCTIONS
    */   
    function setFee(uint96 _fee) public onlyOwner {
        require( _fee <= MAX_FEE, "Max fee is 369 - 3.69%");
        fee = _fee;
    }

    function setFeeAddress(address payable _receipient) public onlyOwner {
        require(_receipient != address(0), "Fee address cannot be zero address");
        feeAddress = _receipient;
    } 
}