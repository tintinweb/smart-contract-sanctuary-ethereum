// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
pragma abicoder v2;
import "NFT.sol";
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() {
        _status = _NOT_ENTERED;
    }
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
        _status = _NOT_ENTERED;
    }
}
library Counters {
    struct Counter {
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
contract Marketplace is ReentrancyGuard, Ownable, IERC721Receiver {
    using Counters for Counters.Counter;
    event NFTAddressChanged(address oldAddress, address newAddress);
    event MintPriceUpgraded(uint256 oldPrice, uint256 newPrice, uint256 time);
    event Burned(uint256 indexed tokenId, address sender, uint256 currentTime);
    event EventCanceled(uint256 indexed tokenId, address indexed seller);
    event AuctionMinimalBidAmountUpgraded(
        uint256 newAuctionMinimalBidAmount,
        uint256 time
    );
    event AuctionDurationUpgraded(
        uint256 newAuctionDuration,
        uint256 currentTime
    );
    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed owner,
        uint256 timeOfCreation
    );
    event ListedForSale(
        uint256 indexed itemId,
        uint256 price,
        uint256 listedTime,
        address indexed owner,
        address indexed seller
    );
    event Sold(
        uint256 indexed itemId,
        uint256 price,
        uint256 soldTime,
        address indexed seller,
        address indexed buyer
    );
    event StartAuction(
        uint256 indexed itemId,
        uint256 startPrice,
        address seller,
        uint256 listedTime
    );
    event BidIsMade(
        uint256 indexed tokenId,
        uint256 price,
        uint256 numberOfBid,
        address indexed bidder
    );
    event PositiveEndAuction(
        uint256 indexed itemId,
        uint256 endPrice,
        uint256 bidAmount,
        uint256 endTime,
        address indexed seller,
        address indexed winner
    );
    event NegativeEndAuction(
        uint256 indexed itemId,
        uint256 bidAmount,
        uint256 endTime
    );
    event NFTReceived(
        address operator,
        address from,
        uint256 tokenId,
        bytes data
    );
    enum TokenStatus {
        DEFAULT,
        ACTIVE,
        ONSELL,
        ONAUCTION,
        BURNED
    }
    enum SaleStatus {
        DEFAULT,
        ACTIVE,
        SOLD,
        CANCELLED
    }
    enum AuctionStatus {
        DEFAULT,
        ACTIVE,
        SUCCESSFUL_ENDED,
        UNSUCCESSFULLY_ENDED
    }
    struct SaleOrder {
        address payable seller;
        address payable owner;
        uint256 price;
        SaleStatus status;
    }
    struct AuctionOrder {
        uint256 startPrice;
        uint256 startTime;
        uint256 currentPrice;
        uint256 bidAmount;
        address payable owner;
        address payable seller;
        address payable lastBidder;
        AuctionStatus status;
    }
    Counters.Counter private _tokenIds;
    Counters.Counter private _totalAmount;
    Counters.Counter private _itemsSold;
    NFT private _NFT;
    uint256 private _mintPrice;
    uint256 private _auctionDuration;
    uint256 private _auctionMinimalBidAmount;
    constructor() {}
    mapping(uint256 => TokenStatus) private _idToItemStatus;
    mapping(uint256 => SaleOrder) private _idToOrder;
    mapping(uint256 => AuctionOrder) private _idToAuctionOrder;
    modifier isActive(uint256 tokenId) {
        require(
            _idToItemStatus[tokenId] == TokenStatus.ACTIVE,
            "Marketplace: This NFT has already been put up for sale or auction!"
        );
        _;
    }
    modifier auctionIsActive(uint256 tokenId) {
        require(
            _idToAuctionOrder[tokenId].status == AuctionStatus.ACTIVE,
            "Marketplace: Auction already ended!"
        );
        _;
    }
    function listItem(uint256 tokenId, uint256 price)
        external
        isActive(tokenId)
    {
        address owner = _NFT.ownerOf(tokenId);
        _NFT.safeTransferFrom(owner, address(this), tokenId);
        _idToItemStatus[tokenId] = TokenStatus.ONSELL;
        _idToOrder[tokenId] = SaleOrder(
           payable(msg.sender),
           payable( owner),
            price,
            SaleStatus.ACTIVE
        );
        emit ListedForSale(tokenId, price, block.timestamp, owner, msg.sender);
    }
    function buyItem(uint256 tokenId) external payable nonReentrant {
        SaleOrder storage order = _idToOrder[tokenId];
        require(
            order.status == SaleStatus.ACTIVE,
            "Marketplace: The token isn't on sale"
        );
        require(msg.value == order.price,"price should be equal to price of NFT");
        order.status = SaleStatus.SOLD;
        address payable sendTo = order.seller;
        // send token's worth of ethers to the owner
        sendTo.transfer(order.price);
        _NFT.safeTransferFrom(address(this), msg.sender, tokenId);
        _idToItemStatus[tokenId] = TokenStatus.ACTIVE;
        _itemsSold.increment();
        emit Sold(
            tokenId,
            order.price,
            block.timestamp,
            order.seller,
            msg.sender
        );
    }
    function cancel(uint256 tokenId) external nonReentrant {
        SaleOrder storage order = _idToOrder[tokenId];
        require(
            msg.sender == order.owner || msg.sender == order.seller,
            "Marketplace: You don't have the authority to cancel the sale of this token!"
        );
        require(
            _idToOrder[tokenId].status == SaleStatus.ACTIVE,
            "Marketplace: The token wasn't on sale"
        );
        _NFT.safeTransferFrom(address(this), order.owner, tokenId);
        order.status = SaleStatus.CANCELLED;
        _idToItemStatus[tokenId] = TokenStatus.ACTIVE;
        emit EventCanceled(tokenId, msg.sender);
    }
    function listItemOnAuction(uint256 newAuctionDuration,uint256 newAuctionMinimalBidAmount,uint256 tokenId, uint256 minPrice)
        external
        isActive(tokenId)
    {
        setAuctionDuration(newAuctionDuration);
        setAuctionMinimalBidAmount(newAuctionMinimalBidAmount);
        address owner = _NFT.ownerOf(tokenId);
        _NFT.safeTransferFrom(owner, address(this), tokenId);
        _idToItemStatus[tokenId] = TokenStatus.ONAUCTION;
        _idToAuctionOrder[tokenId] = AuctionOrder(
            minPrice,
            block.timestamp,
            0,
            0,
            payable(owner),
            payable(msg.sender),
            payable(address(0)),
            AuctionStatus.ACTIVE
        );
        emit StartAuction(tokenId, minPrice, msg.sender, block.timestamp);
    }
    function makeBid(uint256 tokenId, uint256 price)
        external payable 
        auctionIsActive(tokenId)
    {
        AuctionOrder storage order = _idToAuctionOrder[tokenId];
        require(
            price > order.currentPrice && price >= order.startPrice,
            "Marketplace: Your bid less or equal to current bid!"
        );
        if (order.currentPrice != 0)
        order.currentPrice = price;
        order.lastBidder = payable(msg.sender);
        order.bidAmount += 1;
        payable(address(this)).transfer(price);
        emit BidIsMade(tokenId, price, order.bidAmount, order.lastBidder);
    }
    function finishAuction(uint256 tokenId)
        external
        auctionIsActive(tokenId)
        nonReentrant
    {
        AuctionOrder storage order = _idToAuctionOrder[tokenId];
        require(
            order.startTime + _auctionDuration < block.timestamp,
            "Marketplace: Auction duration not complited!"
        );

        if (order.bidAmount < _auctionMinimalBidAmount) {
            _cancelAuction(tokenId);
            emit NegativeEndAuction(tokenId, order.bidAmount, block.timestamp);
            return;
        }
        _NFT.safeTransferFrom(address(this), order.lastBidder, tokenId);
        (order.seller).transfer(order.currentPrice);
        order.status = AuctionStatus.SUCCESSFUL_ENDED;
        _idToItemStatus[tokenId] = TokenStatus.ACTIVE;
        _itemsSold.increment();
        emit PositiveEndAuction(
            tokenId,
            order.currentPrice,
            order.bidAmount,
            block.timestamp,
            order.seller,
            order.lastBidder
        );
    }
    function cancelAuction(uint256 tokenId) external nonReentrant {
        // In the future, it's best to use Error()
        require(
            msg.sender == _idToAuctionOrder[tokenId].owner ||
                msg.sender == _idToAuctionOrder[tokenId].seller,
            "Marketplace: You don't have the authority to cancel the sale of this token!"
        );
        require(
            _idToAuctionOrder[tokenId].bidAmount == 0,
            "Marketplace: You can't cancel the auction which already has a bidder!"
        );
        _cancelAuction(tokenId);
        emit EventCanceled(tokenId, _idToAuctionOrder[tokenId].seller);
    }

    function _cancelAuction(uint256 tokenId) private {
        _idToAuctionOrder[tokenId].status = AuctionStatus.UNSUCCESSFULLY_ENDED;
        _NFT.safeTransferFrom(
            address(this),
            _idToAuctionOrder[tokenId].owner,
            tokenId
        );
        _idToItemStatus[tokenId] = TokenStatus.ACTIVE;
        if (_idToAuctionOrder[tokenId].bidAmount != 0) {
            (_idToAuctionOrder[tokenId].lastBidder).transfer(_idToAuctionOrder[tokenId].currentPrice);
        }
    }
    function setNFTAddress(address newNFTAddress) external onlyOwner {
        emit NFTAddressChanged(address(_NFT), newNFTAddress);
        _NFT = NFT(newNFTAddress);
    }
    function getNFT() external view returns (address) {
        return address(_NFT);
    }
    function getTokenStatus(uint256 tokenId)
        external
        view
        returns (TokenStatus)
    {
        return _idToItemStatus[tokenId];
    }
    function getSaleOrder(uint256 tokenId)
        external
        view
        returns (SaleOrder memory)
    {
        return _idToOrder[tokenId];
    }
    function getAuctionOrder(uint256 tokenId)
        external
        view
        returns (AuctionOrder memory)
    {
        return _idToAuctionOrder[tokenId];
    }
    function getMintPrice() external view returns (uint256) {
        return _mintPrice;
    }
    function getAuctionMinimalBidAmount() external view returns (uint256) {
        return _auctionMinimalBidAmount;
    }
    function getAuctionDuration() external view returns (uint256) {
        return _auctionDuration;
    }
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        emit NFTReceived(operator, from, tokenId, data);
        return IERC721Receiver.onERC721Received.selector;
    }
    function setAuctionMinimalBidAmount(uint256 newAuctionMinimalBidAmount)
        public
        onlyOwner
    {
        _auctionMinimalBidAmount = newAuctionMinimalBidAmount;
        emit AuctionMinimalBidAmountUpgraded(
            newAuctionMinimalBidAmount,
            block.timestamp
        );
    }
    function setAuctionDuration(uint256 newAuctionDuration) public onlyOwner {
        _auctionDuration = newAuctionDuration;
        emit AuctionDurationUpgraded(newAuctionDuration, block.timestamp);
    }
}