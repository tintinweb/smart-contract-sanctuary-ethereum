//"SPDX-License-Identifier: MIT"
pragma solidity 0.8.6;

import "./RC3_Auction.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RC3_Mall is RC3_Auction, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter public marketId;
    Counters.Counter public marketsSold;
    Counters.Counter public marketsDelisted;

    uint96 public ethFee; // 1% = 1000

    enum Asset {
        ETH,
        RCDY
    }

    struct Market {
        address payable seller;
        address payable buyer;
        address nifty;
        uint256 tokenId;
        uint256 tokenAmount;
        uint256 price; //in RCDY or ETH
        TokenType tokenType;
        State state;
        Asset asset;
    }

    mapping(uint256 => Market) private markets;

    event NewMarket(
        address indexed caller,
        address indexed nifty,
        uint256 indexed marketId,
        uint256 tokenId,
        uint256 amount,
        uint256 price,
        TokenType tokenType,
        Asset asset
    );

    event MarketSale(
        address indexed caller,
        address indexed nifty,
        uint256 indexed marketId,
        uint256 tokenId,
        uint256 price,
        Asset asset
    );

    event MarketCancelled(
        address indexed caller,
        address indexed nifty,
        uint256 marketId,
        uint256 tokenId
    );

    event FeeSet(address indexed sender, uint256 feePercentage, Asset asset);

    event FeeRecipientSet(address indexed sender, address feeReceipient);

    constructor(
        address _rcdy,
        address payable _feeReceipient,
        uint96 _feeRCDY,
        uint96 _ethFee
    ) RC3_Auction(_rcdy) Ownable() {
        _setFeeRecipient(_feeReceipient);
        _setFeePercentage(_feeRCDY);
        ethFee = _ethFee;
        transferOwnership(msg.sender);
    }

    modifier buyCheck(uint256 _marketId) {
        _buyCheck(_marketId);
        _;
    }

    ///-----------------///
    /// ADMIN FUNCTIONS ///
    ///-----------------///

    function setFeeRecipient(address payable _newRecipient) external onlyOwner {
        _setFeeRecipient(_newRecipient);
        emit FeeRecipientSet(msg.sender, _newRecipient);
    }

    function setFeeRCDY(uint96 _newFee) external onlyOwner {
        _setFeePercentage(_newFee);
        emit FeeSet(msg.sender, _newFee, Asset.RCDY);
    }

    function setFeeETH(uint96 _newFee) public onlyOwner {
        uint96 fee = ethFee;
        require(_newFee != fee, "Error: already set");
        ethFee = _newFee;
        emit FeeSet(msg.sender, _newFee, Asset.ETH);
    }

    function listMarket(
        address nifty,
        uint256 _tokenId,
        uint256 amount,
        uint256 _price,
        TokenType _type,
        Asset _asset
    ) external returns (uint256 marketId_) {
        require(_price > 0, "INVALID_PRICE");
        marketId.increment();
        marketId_ = marketId.current();

        if (_type == TokenType.ERC_721) {
            IERC721 nft = IERC721(nifty);
            address nftOwner = nft.ownerOf(_tokenId);
            nft.safeTransferFrom(nftOwner, address(this), _tokenId);

            _registerMarket(
                nifty,
                marketId_,
                _tokenId,
                1,
                _price,
                TokenType.ERC_721,
                _asset
            );
        } else {
            require(amount > 0, "INVALID_AMOUNT");
            IERC1155 nft = IERC1155(nifty);
            nft.safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId,
                amount,
                "0x0"
            );
            _registerMarket(
                nifty,
                marketId_,
                _tokenId,
                amount,
                _price,
                TokenType.ERC_1155,
                _asset
            );
        }

        return marketId_;
    }

    function delistMarket(uint256 _marketId)
        external
        nonReentrant
        returns (State status)
    {
        Market storage market = markets[_marketId];

        require(State.LISTED == market.state, "MARKET_NOT_LISTED");
        require(msg.sender == market.seller, "UNAUTHORIZED_CALLER");

        market.tokenType == TokenType.ERC_721
            ? IERC721(market.nifty).safeTransferFrom(
                address(this),
                market.seller,
                market.tokenId
            )
            : IERC1155(market.nifty).safeTransferFrom(
                address(this),
                market.seller,
                market.tokenId,
                market.tokenAmount,
                "0x0"
            );

        market.state = State.DELISTED;
        marketsDelisted.increment();

        emit MarketCancelled(
            msg.sender,
            market.nifty,
            _marketId,
            market.tokenId
        );
        return market.state;
    }

    function buyWithETH(uint256 _marketId)
        external
        payable
        buyCheck(_marketId)
        returns (bool bought)
    {
        Market memory market = markets[_marketId];
        uint96 feeRate = ethFee;
        uint256 fee = (feeRate * market.price) / 100000;
        require(msg.value == market.price, "INVALID_PAYMENT_AMOUNT");

        feeRecipient.transfer(fee);
        market.seller.transfer(market.price - fee);
        _buy(_marketId);
        return true;
    }

    function buyWithRCDY(uint256 _marketId)
        external
        buyCheck(_marketId)
        returns (bool bought)
    {
        Market memory market = markets[_marketId];
        uint96 feeRate = feePercentage;
        uint256 fee = (feeRate * market.price) / 100000;

        rcdy.transferFrom(msg.sender, feeRecipient, fee);
        rcdy.transferFrom(msg.sender, market.seller, market.price - fee);

        _buy(_marketId);
        return true;
    }

    function getMarket(uint256 _marketId)
        external
        view
        returns (Market memory)
    {
        return markets[_marketId];
    }

    function getListedMarkets()
        external
        view
        returns (Market[] memory marketItems)
    {
        uint256 itemCount = marketId.current();
        uint256 listedItemCount = itemCount -
            marketsDelisted.current() -
            marketsSold.current();
        uint256 currentIndex;

        Market[] memory items = new Market[](listedItemCount);

        for (uint256 i; i < itemCount; i++) {
            if (markets[i + 1].state == State.LISTED) {
                Market memory currentItem = markets[i + 1];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        return items;
    }

    function myTradedNFTs() external view returns (Market[] memory myNfts) {
        uint256 totalItemCount = marketId.current();
        uint256 itemCount;
        uint256 currentIndex;

        for (uint256 i; i < totalItemCount; i++) {
            if (markets[i + 1].buyer == payable(msg.sender)) {
                itemCount++;
            }
        }

        Market[] memory items = new Market[](itemCount);

        for (uint256 i; i < totalItemCount; i++) {
            Market memory item = markets[i + 1];
            if (item.buyer == payable(msg.sender)) {
                items[currentIndex] = item;
                currentIndex++;
            }
        }
        return items;
    }

    function _setFeePercentage(uint96 _newFee) internal {
        uint96 fee = feePercentage;
        require(_newFee != fee, "Error: already set");
        feePercentage = _newFee;
    }

    function _setFeeRecipient(address payable _newFeeRecipient) internal {
        address rec = feeRecipient;
        require(_newFeeRecipient != rec, "Error: already receipient");
        feeRecipient = _newFeeRecipient;
    }

    function _registerMarket(
        address nifty,
        uint256 _marketId,
        uint256 _tokenId,
        uint256 amount,
        uint256 _price,
        TokenType _type,
        Asset _asset
    ) private {
        Market storage market = markets[_marketId];

        market.seller = payable(msg.sender);
        market.nifty = nifty;
        market.tokenId = _tokenId;
        market.tokenAmount = amount;
        market.price = _price;
        market.state = State.LISTED;
        market.tokenType = _type;
        market.asset = _asset;

        emit NewMarket(
            msg.sender,
            nifty,
            _marketId,
            _tokenId,
            amount,
            _price,
            _type,
            _asset
        );
    }

    function _buy(uint256 _marketId) private nonReentrant {
        Market storage market = markets[_marketId];
        market.buyer = payable(msg.sender);
        market.state = State.SOLD;
        marketsSold.increment();

        market.tokenType == TokenType.ERC_721
            ? IERC721(market.nifty).safeTransferFrom(
                address(this),
                msg.sender,
                market.tokenId
            )
            : IERC1155(market.nifty).safeTransferFrom(
                address(this),
                msg.sender,
                market.tokenId,
                market.tokenAmount,
                "0x0"
            );

        emit MarketSale(
            msg.sender,
            market.nifty,
            _marketId,
            market.tokenId,
            market.price,
            market.asset
        );
    }

    function _buyCheck(uint256 _marketId) private view {
        Market memory market = markets[_marketId];

        require(market.state == State.LISTED, "MARKET_NOT_LISTED");
        require(market.seller != msg.sender, "OWNER_CANNOT_BUY");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RC3_Auction is ERC721Holder, ERC1155Holder, ReentrancyGuard {
    using Counters for Counters.Counter;

    //state variables
    IERC20 internal rcdy;
    Counters.Counter public auctionId;
    Counters.Counter public auctionsClosed;

    uint96 public feePercentage; // 1% = 1000
    uint96 private immutable DIVISOR;
    address payable public feeRecipient;

    enum TokenType {
        ERC_721,
        ERC_1155
    }

    enum State {
        UNLISTED,
        LISTED,
        DELISTED,
        SOLD
    }

    //struct
    struct Auction {
        address payable seller;
        address payable highestBidder;
        address nifty;
        uint256 tokenId;
        uint256 tokenAmount;
        uint256 initialBidAmount;
        uint256 highestBidAmount;
        uint256 startPeriod;
        uint256 endPeriod;
        uint256 bidCount;
        TokenType tokenType;
        State state;
    }

    //auction id to Auction
    mapping(uint256 => Auction) private auctions;

    event AuctionUpdated(
        address indexed caller,
        address indexed nft,
        uint256 indexed auctionId,
        uint256 _tokenId,
        uint256 newEndPeriod
    );

    event AuctionCancelled(
        address indexed caller,
        address indexed nft,
        uint256 indexed auctionId,
        uint256 tokenID
    );

    event AuctionResulted(
        address indexed caller,
        address seller,
        address highestBidder,
        address indexed nft,
        uint256 indexed auctionId,
        uint256 tokenId,
        uint256 amount,
        uint256 winPrice
    );

    event EndTimeUpdated(
        address indexed creator,
        address indexed nft,
        uint256 indexed auctionId,
        uint256 tokenId,
        uint256 newEndTime
    );

    event NewAuction(
        address indexed seller,
        address indexed nft,
        uint256 indexed auctionId,
        uint256 tokenId,
        uint256 amount,
        uint256 floorPrice,
        uint256 startPeriod,
        uint256 endPeriod,
        TokenType tokenType
    );

    event NewBid(
        address indexed bidder,
        address indexed nft,
        uint256 indexed auctionId,
        uint256 tokenId,
        uint256 price
    );

    //Deployer
    constructor(address _rcdy) {
        rcdy = IERC20(_rcdy);
        DIVISOR = 100 * 1000;
    }

    //Modifier to check all conditions are met before bid
    modifier bidCheck(uint256 _auctionId, uint256 _bidAmount) {
        _bidCheck(_auctionId, _bidAmount);
        _;
    }

    ///-----------------///
    /// WRITE FUNCTIONS ///
    ///-----------------///

    function listAuction(
        address nifty,
        uint256 _tokenId,
        uint256 amount,
        uint256 _startsIn,
        uint256 _lastsFor,
        uint256 _initialBidAmount,
        TokenType _type
    ) external returns (uint256 auctionId_) {
        auctionId.increment();
        auctionId_ = auctionId.current();
        require(_lastsFor != 0, "INVALID_DURATION");

        if (_type == TokenType.ERC_721) {
            IERC721 nft = IERC721(nifty);
            address nftOwner = nft.ownerOf(_tokenId);
            nft.safeTransferFrom(nftOwner, address(this), _tokenId);

            _registerAuction(
                nifty,
                auctionId_,
                _tokenId,
                1,
                _startsIn,
                _lastsFor,
                _initialBidAmount,
                TokenType.ERC_721
            );
        } else {
            require(amount > 0, "INVALID_AMOUNT");
            IERC1155 nft = IERC1155(nifty);
            nft.safeTransferFrom(
                msg.sender,
                address(this),
                _tokenId,
                amount,
                "0x0"
            );

            _registerAuction(
                nifty,
                auctionId_,
                _tokenId,
                amount,
                _startsIn,
                _lastsFor,
                _initialBidAmount,
                TokenType.ERC_1155
            );
        }
    }

    function bid(uint256 _auctionId, uint256 _bidAmount)
        external
        nonReentrant
        bidCheck(_auctionId, _bidAmount)
        returns (bool bidded)
    {
        Auction storage auction = auctions[_auctionId];

        rcdy.transferFrom(msg.sender, address(this), _bidAmount);

        if (auction.bidCount != 0) {
            //return token to the prevous highest bidder
            rcdy.transfer(auction.highestBidder, auction.highestBidAmount);
        }

        //update data
        auction.highestBidder = payable(msg.sender);
        auction.highestBidAmount = _bidAmount;
        auction.bidCount++;

        emit NewBid(
            msg.sender,
            auction.nifty,
            _auctionId,
            auction.tokenId,
            _bidAmount
        );

        //increase countdown clock
        (, uint256 timeLeft) = _bidTimeRemaining(_auctionId);
        if (timeLeft < 1 hours) {
            timeLeft + 10 minutes <= 1 hours
                ? auction.endPeriod += 10 minutes
                : auction.endPeriod += (1 hours - timeLeft);

            (, uint256 newTimeLeft) = _bidTimeRemaining(_auctionId);

            emit AuctionUpdated(
                msg.sender,
                auction.nifty,
                _auctionId,
                auction.tokenId,
                block.timestamp + newTimeLeft
            );
        }

        return true;
    }

    function closeBid(uint256 _auctionId)
        external
        nonReentrant
        returns (State status)
    {
        Auction storage auction = auctions[_auctionId];
        require(auction.state == State.LISTED, "AUCTION_NOT_LISTED");

        (uint256 startTime, uint256 timeLeft) = _bidTimeRemaining(_auctionId);
        require(startTime == 0, "AUCTION_NOT_STARTED");
        require(timeLeft == 0, "AUCTION_NOT_ENDED");

        uint256 highestBidAmount = auction.highestBidAmount;

        if (highestBidAmount == 0) {
            auction.tokenType == TokenType.ERC_721
                ? IERC721(auction.nifty).safeTransferFrom(
                    address(this),
                    auction.seller,
                    auction.tokenId
                )
                : IERC1155(auction.nifty).safeTransferFrom(
                    address(this),
                    auction.seller,
                    auction.tokenId,
                    auction.tokenAmount,
                    "0x0"
                );
            auction.state = State.DELISTED;
            emit AuctionCancelled(
                msg.sender,
                auction.nifty,
                _auctionId,
                auction.tokenId
            );
        } else {
            //auction succeeded, pay fee, send money to seller, and token to buyer
            uint256 fee = (feePercentage * highestBidAmount) / DIVISOR;
            address highestBidder = auction.highestBidder;

            rcdy.transfer(feeRecipient, fee);
            rcdy.transfer(auction.seller, highestBidAmount - fee);

            auction.tokenType == TokenType.ERC_721
                ? IERC721(auction.nifty).safeTransferFrom(
                    address(this),
                    highestBidder,
                    auction.tokenId
                )
                : IERC1155(auction.nifty).safeTransferFrom(
                    address(this),
                    highestBidder,
                    auction.tokenId,
                    auction.tokenAmount,
                    "0x0"
                );
            auction.state = State.SOLD;
            emit AuctionResulted(
                msg.sender,
                auction.seller,
                highestBidder,
                auction.nifty,
                _auctionId,
                auction.tokenId,
                auction.tokenAmount,
                highestBidAmount
            );
        }

        auctionsClosed.increment();
        return auction.state;
    }

    function updateEndTime(uint256 _auctionId, uint256 _endsIn)
        external
        returns (bool updated)
    {
        Auction storage auction = auctions[_auctionId];

        require(auction.seller == msg.sender, "ONLY_SELLER");
        require(auction.startPeriod <= block.timestamp, "AUCTION_NOT_STARTED");

        auction.endPeriod = block.timestamp + _endsIn;

        emit EndTimeUpdated(
            msg.sender,
            auction.nifty,
            _auctionId,
            auction.tokenId,
            auction.endPeriod
        );
        return true;
    }

    ///-----------------///
    /// READ FUNCTIONS ///
    ///-----------------///

    function bidTimeRemaining(uint256 _auctionId)
        external
        view
        returns (uint256 startsIn, uint256 endsIn)
    {
        return _bidTimeRemaining(_auctionId);
    }

    function nextBidAmount(uint256 _auctionId)
        external
        view
        returns (uint256 amount)
    {
        return _nextBidAmount(_auctionId);
    }

    function getAuction(uint256 _auctionId)
        external
        view
        returns (Auction memory)
    {
        return auctions[_auctionId];
    }

    ///-----------------///
    /// PRIVATE FUNCTIONS ///
    ///-----------------///

    function _registerAuction(
        address nifty,
        uint256 _auctionId,
        uint256 _tokenId,
        uint256 amount,
        uint256 _startsIn,
        uint256 _lastsFor,
        uint256 _initialBidAmount,
        TokenType _type
    ) private {
        Auction storage auction = auctions[_auctionId];

        //create auction
        uint256 startsIn = block.timestamp + _startsIn;
        uint256 period = startsIn + _lastsFor;

        auction.nifty = nifty;
        auction.tokenId = _tokenId;
        auction.startPeriod = startsIn;
        auction.endPeriod = period;
        auction.seller = payable(msg.sender);
        auction.initialBidAmount = _initialBidAmount;
        auction.tokenType = _type;
        auction.tokenAmount = amount;
        auction.state = State.LISTED;

        emit NewAuction(
            msg.sender,
            nifty,
            _auctionId,
            _tokenId,
            amount,
            _initialBidAmount,
            startsIn,
            period,
            _type
        );
    }

    function _bidTimeRemaining(uint256 _auctionId)
        private
        view
        returns (uint256 startsIn, uint256 endsIn)
    {
        Auction memory auction = auctions[_auctionId];

        startsIn = auction.startPeriod > block.timestamp
            ? auction.startPeriod - block.timestamp
            : 0;

        endsIn = auction.endPeriod > block.timestamp
            ? auction.endPeriod - block.timestamp
            : 0;
    }

    function _nextBidAmount(uint256 _auctionId)
        private
        view
        returns (uint256 amount)
    {
        Auction memory auction = auctions[_auctionId];
        if (auction.seller != address(0)) {
            uint256 current = auction.highestBidAmount;

            if (current == 0) {
                return auction.initialBidAmount;
            } else {
                //10% more of current highest bid
                return ((current * 10000) / DIVISOR) + current;
            }
        }
        return 0;
    }

    function _bidCheck(uint256 _auctionId, uint256 _bidAmount) private view {
        Auction memory auction = auctions[_auctionId];
        uint256 endPeriod = auction.endPeriod;
        require(auction.state == State.LISTED, "AUCTION_NOT_LISTED");
        require(auction.seller != msg.sender, "OWNER_CANNOT_BID");
        require(auction.startPeriod <= block.timestamp, "AUCTION_NOT_STARTED");
        require(endPeriod > block.timestamp, "AUCTION_ENDED");
        require(
            _bidAmount >= _nextBidAmount(_auctionId),
            "INVALID_INPUT_AMOUNT"
        );
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
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