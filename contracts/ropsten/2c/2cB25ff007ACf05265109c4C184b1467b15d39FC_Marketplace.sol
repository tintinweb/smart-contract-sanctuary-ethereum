/**
 *Submitted for verification at Etherscan.io on 2022-10-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
pragma abicoder v2;
interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
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
        uint256 price;
        uint256 duration;
        SaleStatus status;
    }
    struct AuctionOrder {
        uint256 startTime;
        uint256 endtime;
        uint256 bid_price;
        uint256 bidAmount;
        address payable seller;
        address payable lastBidder;
        AuctionStatus status;
    }
    Counters.Counter private _tokenIds;
    Counters.Counter private _totalAmount;
    Counters.Counter private _itemsSold;
    IERC721 private _NFT;
    uint256 private _mintPrice;
    uint256 private _auctionDuration;
    uint256 private _auctionMinimalBidAmount;

    function minNFT(IERC721 nft) public {
        _NFT = nft ;
    }
    mapping(uint256 => TokenStatus) private _idToItemStatus;
    mapping(uint256 => SaleOrder) private _idToOrder;
    mapping(uint256 => AuctionOrder) private _idToAuctionOrder;
    mapping(uint256 => bool) islisted;
    address payable minter ;
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
    modifier onlyminter() {
        require(
        payable(msg.sender) == minter,"minter");
        _;
    }
    function listItem(uint256 tokenId, uint256 price)
        external
    {
        require(islisted[tokenId] == false,"tokenId is listed");
        address owner = _NFT.ownerOf(tokenId);
        _NFT.safeTransferFrom(owner, address(this), tokenId);
        _idToItemStatus[tokenId] = TokenStatus.ONSELL;
        minter = payable(msg.sender);
        _idToOrder[tokenId] = SaleOrder(
           payable(minter),
            price,
            0,
            SaleStatus.ACTIVE
        );
        islisted[tokenId] = true;
        emit ListedForSale(tokenId, price, block.timestamp, owner, msg.sender);
    }
    function listItemtime(uint256 tokenId, uint256 price,uint256 _duration)
        external
    {
        require(islisted[tokenId] == false,"tokenId is listed");
        address owner = _NFT.ownerOf(tokenId);
        minter = payable(msg.sender);
        _NFT.safeTransferFrom(owner, address(this), tokenId);
        _idToItemStatus[tokenId] = TokenStatus.ONSELL;
        _idToOrder[tokenId] = SaleOrder(
           payable(minter),
            price,
            block.timestamp + _duration,
            SaleStatus.ACTIVE
        );
        islisted[tokenId] = true;
        emit ListedForSale(tokenId, price, block.timestamp, owner, msg.sender);
    }
    function buyItem(uint256 tokenId) external payable nonReentrant {
        SaleOrder storage order = _idToOrder[tokenId];
        require(islisted[tokenId] == true,"tokenId is not listed");
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
        islisted[tokenId] = false;
    }
    function buyItemtime(uint256 tokenId) external payable nonReentrant {
        SaleOrder storage order = _idToOrder[tokenId];
        require(islisted[tokenId] == true,"tokenId is not listed");
        require(msg.value == order.price,"price should be equal to price of NFT");
        require(block.timestamp <= order.duration,"time is over");
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
        islisted[tokenId] = false;
    }
    function cancel(uint256 tokenId) external nonReentrant onlyminter onlyOwner {
        SaleOrder storage order = _idToOrder[tokenId];
        require(
            _idToOrder[tokenId].status == SaleStatus.ACTIVE,
            "Marketplace: The token wasn't on sale"
        );
        _NFT.safeTransferFrom(address(this), order.seller, tokenId);
        order.status = SaleStatus.CANCELLED;
        _idToItemStatus[tokenId] = TokenStatus.ACTIVE;
        islisted[tokenId] = false ;
        emit EventCanceled(tokenId, msg.sender);
    }
    function listItemOnAuction(uint256 tokenId, uint256 bidPrice,uint256 duration)
        external
    {
        address owner = _NFT.ownerOf(tokenId);
        minter = payable(msg.sender);
        _NFT.safeTransferFrom(owner, address(this), tokenId);
        _idToItemStatus[tokenId] = TokenStatus.ONAUCTION;
        _idToAuctionOrder[tokenId] = AuctionOrder(
            block.timestamp,
            block.timestamp + duration,
            bidPrice,
            0,
            payable(minter),
            payable(address(0)),
            AuctionStatus.ACTIVE
        );
        emit StartAuction(tokenId, bidPrice, msg.sender, block.timestamp);
    }
    function makeBid(uint256 tokenId)
        external payable 
    {
        uint256 _bidprice = msg.value;
        AuctionOrder storage order = _idToAuctionOrder[tokenId];
        require(_bidprice > order.bid_price,"Marketplace: Your bid less or equal to current bid!");
        require(block.timestamp <= order.endtime,"auction is ended");
        order.lastBidder = payable(msg.sender);
        order.bid_price = _bidprice;
        address payable sendTo = payable(address(this));
        sendTo.transfer(_bidprice);
        emit BidIsMade(tokenId, _bidprice, order.bidAmount, order.lastBidder);
    }
    function finishAuction(uint256 tokenId)
        external
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
        (order.seller).transfer(order.bid_price);
        order.status = AuctionStatus.SUCCESSFUL_ENDED;
        _idToItemStatus[tokenId] = TokenStatus.ACTIVE;
        _itemsSold.increment();
        emit PositiveEndAuction(
            tokenId,
            order.bid_price,
            order.bidAmount,
            block.timestamp,
            order.seller,
            order.lastBidder
        );
        islisted[tokenId] = false ;
    }
    function cancelAuction(uint256 tokenId) external nonReentrant onlyminter{
        require(
            _idToAuctionOrder[tokenId].bidAmount == 0,
            "Marketplace: You can't cancel the auction which already has a bidder!"
        );
        _cancelAuction(tokenId);
        islisted[tokenId] = false ;
        emit EventCanceled(tokenId, _idToAuctionOrder[tokenId].seller);
    }

    function _cancelAuction(uint256 tokenId) private {
        _idToAuctionOrder[tokenId].status = AuctionStatus.UNSUCCESSFULLY_ENDED;
        _NFT.safeTransferFrom(
            address(this),
            _idToAuctionOrder[tokenId].seller,
            tokenId
        );
        _idToItemStatus[tokenId] = TokenStatus.ACTIVE;
        if (_idToAuctionOrder[tokenId].bidAmount != 0) {
            (_idToAuctionOrder[tokenId].lastBidder).transfer(_idToAuctionOrder[tokenId].bid_price);
        }
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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        emit NFTReceived(operator, from, tokenId, data);
        return IERC721Receiver.onERC721Received.selector;
    }
    function setAuctionDuration(uint256 newAuctionDuration,uint256 _tokenId) public onlyminter {
        AuctionOrder storage order = _idToAuctionOrder[_tokenId];
        order.endtime = block.timestamp + newAuctionDuration;
        emit AuctionDurationUpgraded(order.endtime, _tokenId);
    }
}