// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./Common/ITrade.sol";
import "./Common/ISale.sol";
import "./Common/IOffer.sol";
import "./Common/IAuction.sol";
import "./Common/IDutchAuction.sol";

//----------------------------------------------------------------
// Market (this contract must not change no matter what happens once it is released)
//----------------------------------------------------------------
contract Market is Ownable {
    //-----------------------------------------
    // event
    //-----------------------------------------
    event SaleStartSuspended(bool);
    event OfferStartSuspended(bool);
    event AuctionStartSuspended(bool);
    event DutchAuctionStartSuspended(bool);

    event SaleModified(address contractAddress);
    event OfferModified(address contractAddress);
    event AuctionModified(address contractAddress);
    event DutchAuctionModified(address contractAddress);

    event DefaultMarketFeeModified(uint256 feeRate);
    event DefaultCollectionFeeModified(uint256 feeRate);

    event MarketFeeModified(address indexed contractAddress, uint256 feeRate);
    event CollectionFeeModified(
        address indexed contractAdress,
        uint256 feeRate
    );
    event MarketFeeReset(address indexed contractAddress);
    event CollectionFeeReset(address indexed contractAdress);

    // Present(Since it is just a transfer, it will be completed inside Market without preparing an IPresent interface)
    event Presented(
        address indexed contractAddress,
        uint256 indexed tokenId,
        address from,
        address to
    );

    //-----------------------------------------
    // Constant
    //-----------------------------------------
    uint256 private constant FEE_RATE_BASE = 10000; // Base value of fee (percentage) (Because if you specify more than this value, it will be free / 0 will refer to the default as an invalid value)

    //-----------------------------------------
    // Setting
    //-----------------------------------------
    // Start / stop flag
    bool private _sale_start_suspended;
    bool private _offer_start_suspended;
    bool private _auction_start_suspended;
    bool private _dutch_auction_start_suspended;

    // Component
    ISale private _sale;
    IOffer private _offer;
    IAuction private _auction;
    IDutchAuction private _dutch_auction;

    // commission
    uint256 private _default_fee_rate_market; // Basic market fee ratio
    uint256 private _default_fee_rate_collection; // Basic collection fee percentage

    // Individual fee
    mapping(address => uint256) private _fixed_fee_rate_market;
    mapping(address => uint256) private _fixed_fee_rate_collection;

    //-----------------------------------------
    // Constructor
    //-----------------------------------------
    constructor() Ownable() {
        _default_fee_rate_market = 1000; // 10.0 %
        _default_fee_rate_collection = 1000; // 10.0 %

        emit DefaultMarketFeeModified(_default_fee_rate_market);
        emit DefaultCollectionFeeModified(_default_fee_rate_collection);
    }

    

    // State Variables
  
   
mapping(address => mapping(uint256 => bool)) private listing;
    
function setListed(address _nft , uint256 _token, bool status) public onlyOwner {
    listing[_nft][_token] = status;
}

function get(address _nft, uint256 _token) public view returns (bool) {
        return  listing[_nft][_token];
    }


    //-----------------------------------------
    // [external] Get
    //-----------------------------------------
    function saleStartSuspended() external view returns (bool) {
        return (_sale_start_suspended);
    }

    function offerStartSuspended() external view returns (bool) {
        return (_offer_start_suspended);
    }

    function auctionStartSuspended() external view returns (bool) {
        return (_auction_start_suspended);
    }

    function dutchAuctionStartSuspended() external view returns (bool) {
        return (_dutch_auction_start_suspended);
    }

    function getsale() external view returns (address) {
        return (address(_sale));
    }

    function getoffer() external view returns (address) {
        return (address(_offer));
    }

    function getauction() external view returns (address) {
        return (address(_auction));
    }

    function dutchAuction() external view returns (address) {
        return (address(_dutch_auction));
    }

    function defaultFeeRateForMarket() external view returns (uint256) {
        return (_default_fee_rate_market);
    }

    function defaultFeeRateForCollection() external view returns (uint256) {
        return (_default_fee_rate_collection);
    }

    //-----------------------------------------
    // [external/onlyOwner] Setting
    //-----------------------------------------
    function setSaleStartSuspended(bool flag) external onlyOwner {
        _sale_start_suspended = flag;

        emit SaleStartSuspended(flag);
    }

    function setOfferStartSuspended(bool flag) external onlyOwner {
        _offer_start_suspended = flag;

        emit OfferStartSuspended(flag);
    }

    function setAuctionStartSuspended(bool flag) external onlyOwner {
        _auction_start_suspended = flag;

        emit AuctionStartSuspended(flag);
    }

    function setDutchAuctionStartSuspended(bool flag) external onlyOwner {
        _dutch_auction_start_suspended = flag;

        emit DutchAuctionStartSuspended(flag);
    }

    function setSale(address contractAddress) external onlyOwner {
        _sale = ISale(contractAddress);

        emit SaleModified(contractAddress);
    }

    function setOffer(address contractAddress) external onlyOwner {
        _offer = IOffer(contractAddress);

        emit OfferModified(contractAddress);
    }

    function setAuction(address contractAddress) external onlyOwner {
        _auction = IAuction(contractAddress);

        emit AuctionModified(contractAddress);
    }

    function setDutchAuction(address contractAddress) external onlyOwner {
        _dutch_auction = IDutchAuction(contractAddress);

        emit DutchAuctionModified(contractAddress);
    }

    function setDefaultFeeRateForMarket(uint256 rate) external onlyOwner {
        _default_fee_rate_market = rate;

        emit DefaultMarketFeeModified(rate);
    }

    function setDefaultFeeRateForCollection(uint256 rate) external onlyOwner {
        _default_fee_rate_collection = rate;

        emit DefaultCollectionFeeModified(rate);
    }

    //----------------------------------------
    // [external] Obtaining individual fees
    //----------------------------------------
    function fixedFeeRateForMarket(address contractAddress)
        external
        view
        returns (uint256)
    {
        return (_fixed_fee_rate_market[contractAddress]);
    }

    function fixedFeeRateForCollection(address contractAddress)
        external
        view
        returns (uint256)
    {
        return (_fixed_fee_rate_collection[contractAddress]);
    }

    //----------------------------------------
    // [external/onlyOwner] Individual fee setting
    //----------------------------------------
    function setFixedFeeRateForMarket(address contractAddress, uint256 rate)
        external
        onlyOwner
    {
        _fixed_fee_rate_market[contractAddress] = rate;

        emit MarketFeeModified(contractAddress, rate);
    }

    function setFixedFeeRateForCollection(address contractAddress, uint256 rate)
        external
        onlyOwner
    {
        _fixed_fee_rate_collection[contractAddress] = rate;

        emit CollectionFeeModified(contractAddress, rate);
    }

    function resetFixedFeeRateForMarket(address contractAddress)
        external
        onlyOwner
    {
        delete _fixed_fee_rate_market[contractAddress];

        emit MarketFeeReset(contractAddress);
    }

    function resetFixedFeeRateForCollection(address contractAddress)
        external
        onlyOwner
    {
        delete _fixed_fee_rate_collection[contractAddress];

        emit CollectionFeeReset(contractAddress);
    }

    //----------------------------------------
    // [public] Acquisition of actual fee ratio
    //----------------------------------------
    function feeRateForMarket(address contractAddress)
        public
        view
        returns (uint256)
    {
        uint256 fee = _fixed_fee_rate_market[contractAddress];

        // If valid
        if (fee > 0) {
            // Set to 0 if it exceeds 1.
            if (fee > FEE_RATE_BASE) {
                return (0);
            }

            return (fee);
        }

        return (_default_fee_rate_market);
    }

    function feeRateForCollection(address contractAddress)
        public
        view
        returns (uint256)
    {
        uint256 fee = _fixed_fee_rate_collection[contractAddress];

        // If valid
        if (fee > 0) {
            // Set to 0 if it exceeds 1.
            if (fee > FEE_RATE_BASE) {
                return (0);
            }

            return (fee);
        }

        return (_default_fee_rate_collection);
    }

    //-----------------------------------------
    // [external] Window: Sale
    //-----------------------------------------
    function sell(
        address contractAddress,
        uint256 tokenId,
        uint256 price,
        uint256 period
    ) external {
        require(address(_sale) != address(0), "invalid sale");
        require(!_sale_start_suspended, "sale suspended"); // 新規セール中止中

        _sale.sell(msg.sender, contractAddress, tokenId, price, period);
      
    }

    function cancelSale(uint256 saleId) external {
        require(address(_sale) != address(0), "invalid sale");

        _sale.cancelSale(msg.sender, saleId);
    }

    function buy(uint256 saleId) external payable {
        require(address(_sale) != address(0), "invalid sale");

        _sale.buy(msg.sender, saleId, msg.value);

        // Token transfer
        uint256[4] memory transferInfo = ITrade(address(_sale)).transferInfo(
            saleId
        );
        _transfer(transferInfo);

        // Payment
        uint256[3] memory payInfo = ITrade(address(_sale)).payInfo(saleId);
        _pay(payInfo);
    }

    //-----------------------------------------
    // [external] Window: Offer
    //-----------------------------------------
    function offer(
        address contractAddress,
        uint256 tokenId,
        uint256 price,
        uint256 period
    ) external payable {
        require(address(_offer) != address(0), "invalid offer");
        require(!_offer_start_suspended, "offer suspended"); // 新規オファー中止中

        _offer.offer(
            msg.sender,
            contractAddress,
            tokenId,
            price,
            period,
            msg.value
        );
    }

    function cancelOffer(uint256 offerId) external {
        require(address(_offer) != address(0), "invalid offer");

        _offer.cancelOffer(msg.sender, offerId);

        // Refund
        uint256[2] memory refundInfo = ITrade(address(_offer)).refundInfo(
            offerId
        );
        _refund(refundInfo);
    }

    function acceptOffer(uint256 offerId) external {
        require(address(_offer) != address(0), "invalid offer");

        _offer.acceptOffer(msg.sender, offerId);

        // Token transfer
        uint256[4] memory transferInfo = ITrade(address(_offer)).transferInfo(
            offerId
        );
        _transfer(transferInfo);

        // Payment
        uint256[3] memory payInfo = ITrade(address(_offer)).payInfo(offerId);
        _pay(payInfo);
    }

    function withdrawFromOffer(uint256 offerId) external {
        require(address(_offer) != address(0), "invalid offer");

        _offer.withdrawFromOffer(msg.sender, offerId);

        // Refund
        uint256[2] memory refundInfo = ITrade(address(_offer)).refundInfo(
            offerId
        );
        _refund(refundInfo);
    }

    //-----------------------------------------
    // [external] Window: Auction
    //-----------------------------------------
    function auction(
        address contractAddress,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 period
    ) external {
        require(address(_auction) != address(0), "invalid auction");
        require(!_auction_start_suspended, "auction suspended"); // New auction is being canceled

        _auction.auction(
            msg.sender,
            contractAddress,
            tokenId,
            startingPrice,
            period
        );
    }

    function cancelAuction(uint256 auctionId) external {
        require(address(_auction) != address(0), "invalid auction");

        _auction.cancelAuction(msg.sender, auctionId);
    }

    function bid(uint256 auctionId, uint256 price) external payable {
        require(address(_auction) != address(0), "invalid auction");

        // Refund for existing bids (if existing bids are valid)
        uint256[2] memory refundInfo = ITrade(address(_auction)).refundInfo(
            auctionId
        );
        if (refundInfo[0] != 0) {
            _refund(refundInfo);
        }

        _auction.bid(msg.sender, auctionId, price, msg.value);
    }

    function finishAuction(uint256 auctionId) external {
        require(address(_auction) != address(0), "invalid auction");

        _auction.finishAuction(msg.sender, auctionId);

        // Token transfer
        uint256[4] memory transferInfo = ITrade(address(_auction)).transferInfo(
            auctionId
        );
        _transfer(transferInfo);

        // Payment
        uint256[3] memory payInfo = ITrade(address(_auction)).payInfo(
            auctionId
        );
        _pay(payInfo);
    }

    function withdrawFromAuction(uint256 auctionId) external {
        require(address(_auction) != address(0), "invalid auction");

        _auction.withdrawFromAuction(msg.sender, auctionId);

        // Refund
        uint256[2] memory refundInfo = ITrade(address(_auction)).refundInfo(
            auctionId
        );
        _refund(refundInfo);
    }

    //-----------------------------------------
    // [external] Window: Dutch Auction
    //-----------------------------------------
    function dutchAuction(
        address contractAddress,
        uint256 tokenId,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 period,
        uint256 startMargin,
        uint256 endMargin
    ) external {
        require(address(_dutch_auction) != address(0), "invalid dutch auction");
        require(!_dutch_auction_start_suspended, "dutch_auction suspended"); // New Dutch auction is being canceled

        _dutch_auction.dutchAuction(
            msg.sender,
            contractAddress,
            tokenId,
            startingPrice,
            endingPrice,
            period,
            startMargin,
            endMargin
        );
    }

    function cancelDutchAuction(uint256 auctionId) external {
        require(address(_dutch_auction) != address(0), "invalid dutch auction");

        _dutch_auction.cancelDutchAuction(msg.sender, auctionId);
    }

    function dutchAuctionBuy(uint256 auctionId) external payable {
        require(address(_dutch_auction) != address(0), "invalid dutch_auction");

        _dutch_auction.buyDutchAuction(msg.sender, auctionId, msg.value);

        // Token transfer
        uint256[4] memory transferInfo = ITrade(address(_dutch_auction))
            .transferInfo(auctionId);
        _transfer(transferInfo);

        // Payment
        uint256[3] memory payInfo = ITrade(address(_dutch_auction)).payInfo(
            auctionId
        );
        _pay(payInfo);
    }

    //---------------------------------------------------------------------------
    // [external] Contact: Present (I will implement it on the market because it is not enough to make it Trade)
    //---------------------------------------------------------------------------
    function present(
        address contractAddress,
        uint256 tokenId,
        address to
    ) external {
        // No need for stop control (because it is a process that does not rot)

        // Is the owner valid?
     IERC721 tokenContract = IERC721(contractAddress);
        address owner = tokenContract.ownerOf(tokenId);
        require(owner == msg.sender, "sender is not the owner");

        // event
        emit Presented(contractAddress, tokenId, msg.sender, to);

        // Token transfer
        uint256[4] memory transferInfo;
        transferInfo[0] = uint256(uint160(contractAddress));
        transferInfo[1] = tokenId;
        transferInfo[2] = uint256(uint160(msg.sender));
        transferInfo[3] = uint256(uint160(to));
        _transfer(transferInfo);
    }

    //-----------------------------------
    // [internal] Common processing: Token transfer
    //-----------------------------------
    function _transfer(uint256[4] memory words) internal {
        require(words[0] != 0, "invalid contract");
        require(words[2] != 0, "invalid from");
        require(words[3] != 0, "invalid to");

        // See [ITrade.sol] for a breakdown of words
        IERC721 tokenContract = IERC721(address(uint160(words[0])));
        uint256 tokenId = words[1];
        address from = address(uint160(words[2]));
        address to = address(uint160(words[3]));
        tokenContract.safeTransferFrom(from, to, tokenId);
    }

    //-----------------------------------
    // [internal] Common processing: Payment
    //-----------------------------------
    function _pay(uint256[3] memory words) internal {
        require(words[0] != 0, "invalid to");
        require(words[1] != 0, "invalid contract address");

        // Transfer destination of sales
        address payable to = payable(address(uint160(words[0])));

        // Creator (owner of collection contract)
        address contractAddress = address(uint160(words[1]));
        Ownable collectionContract = Ownable(contractAddress);
        address payable creator = payable(collectionContract.owner());

        // Market (owner of this contract)
        address payable market = payable(owner());

        // Clearing
        uint256 amount = words[2];

        // Market fee (ignored if it is the same as the payee)
        if (market != to) {
            uint256 fee = feeRateForMarket(contractAddress);
            fee = (words[2] * fee) / FEE_RATE_BASE;
            if (fee > 0) {
                if (fee > amount) {
                    fee = amount;
                }
                market.transfer(fee);
                amount -= fee;
            }
        }

        // Creator fee (ignored if it is the same as the payee)
        if (creator != to) {
            uint256 fee = feeRateForCollection(contractAddress);
            fee = (words[2] * fee) / FEE_RATE_BASE;
            if (fee > 0) {
                if (fee > amount) {
                    fee = amount;
                }
                creator.transfer(fee);
                amount -= fee;
            }
        }

        // Sales
        if (amount > 0) {
            to.transfer(amount);
        }
    }

    //-----------------------------------
    // [internal] Common processing: Refund of deposit
    //-----------------------------------
    function _refund(uint256[2] memory words) internal {
        require(words[0] != 0, "invalid to");

        address payable to = payable(address(uint160(words[0])));

        if (words[1] > 0) {
            to.transfer(words[1]);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//-----------------------------------------------------------------------
// IOffer
//-----------------------------------------------------------------------
interface IOffer {
    //----------------------------------------
    // Events
    //----------------------------------------
    event Offer( address indexed contractAddress, uint256 indexed tokenId, address owner, address offeror, uint256 price, uint256 expireDate, uint256 offerId );
    event OfferCanceled( uint256 indexed offerId, address indexed contractAddress, uint256 indexed tokenId, address owner, address offeror, uint256 price );
    event OfferAccepted( uint256 indexed offerId, address indexed contractAddress, uint256 indexed tokenId, address owner, address offeror, uint256 price );
    event OfferWithdrawn( uint256 indexed offerId, address indexed contractAddress, uint256 indexed tokenId, address owner, address offeror, uint256 price );
    event OfferInvalidated( uint256 indexed offerId, address indexed contractAddress, uint256 indexed tokenId, address owner, address offeror );

    //----------------------------------------
    // Functions
    //----------------------------------------
    function offer( address msgSender, address contractAddress, uint256 tokenId, uint256 price, uint256 period, uint256 amount ) external;
    function cancelOffer( address msgSender, uint256 offerId ) external;
    function acceptOffer( address msgSender, uint256 offerId ) external;
    function withdrawFromOffer( address msgSender, uint256 offerId ) external;
    function invalidateOffers( uint256[] calldata offerIds ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//-----------------------------------------------------------------------
// IAuction
//-----------------------------------------------------------------------
interface IAuction  {
    //----------------------------------------
    // Events
    //----------------------------------------
    event Auction( address indexed contractAddress, uint256 indexed tokenId, address auctioneer, uint256 startingPrice, uint256 expireDate, uint256 auctionId );
    event AuctionCanceled( uint256 indexed auctionId, address indexed contractAddress, uint256 indexed tokenId, address auctioneer );
    event AuctionBidded ( uint256 indexed auctionId,  address indexed contractAddress, uint256 indexed tokenId, address auctioneer, address newBidder, address oldBidder, uint256 newPrice, uint256 updatedExpireDate ); 
    event AuctionFinished( uint256 indexed auctionId, address indexed contractAddress, uint256 indexed tokenId, address auctioneer, address winner, uint256 price, uint256 expireDate );
    event AuctionWithdrawn( uint256 indexed auctionId, address indexed contractAddress, uint256 indexed tokenId, address auctioneer, address bidder, uint256 price );
    event AuctionInvalidated( uint256 indexed auctionId, address indexed contractAddress, uint256 indexed tokenId, address auctioneer, address bidder );

    //----------------------------------------
    // Functions
    //----------------------------------------
    function auction( address msgSender, address contractAddress, uint256 tokenId, uint256 startingPrice, uint256 period ) external;
    function cancelAuction( address msgSender, uint256 auctionId ) external;
    function bid( address msgSender, uint256 auctionId, uint256 price, uint256 amount ) external;
    function finishAuction( address msgSender, uint256 auctionId ) external;
    function withdrawFromAuction( address msgSender, uint256 auctionId ) external;
    function invalidateAuctions( uint256[] calldata auctionIds ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//-----------------------------------------------------------------------
// ITrade
//-----------------------------------------------------------------------
interface ITrade {
    //----------------------------------------
    // Events
    //----------------------------------------
    event MaxPriceModified( uint256 maxPrice );
    event MinPriceModified( uint256 minPrice );

    event MaxPeriodModified( uint256 maxPrice );
    event MinPeriodModified( uint256 minPrice );

    event OnlyNoLimitPeriodModified( bool );
    event AcceptNoLimiPeriodModified( bool );

    //----------------------------------------
    // Functions
    //----------------------------------------
    function maxPrice() external view returns ( uint256 );
    function minPrice() external view returns ( uint256 );
    function setMaxPrice( uint256 price ) external;
    function setMinPrice( uint256 price ) external;

    function maxPeriod() external view returns ( uint256 );
    function minPeriod() external view returns ( uint256 );
    function setMaxPeriod( uint256 period ) external;
    function setMinPeriod( uint256 period ) external;

    function onlyNoLimitPeriod() external view returns (bool);
    function acceptNoLimitPeriod() external view returns (bool);
    function setOnlyNoLimitPeriod( bool flag ) external;
    function setAcceptNoLimitPeriod( bool flag ) external;

    //----------------------------------------------
    // Token transfer information
    //----------------------------------------------
    // The breakdown of uint256 [4] is as follows
    // ・ [0]: Token contract (cast to ERC721 and use)
    // ・ [1]: Token ID
    // ・ [2]: Donor side (cast to address and use)
    // ・ [3]: Recipient (cast to address and use)
    //----------------------------------------------
    function transferInfo( uint256 tradeId ) external view returns (uint256[4] memory);

    // ----------------------------------------------
    // Get payment information
    // ----------------------------------------------
    // The breakdown of uint256 [2] is as follows
    // ・ [0]: Payment destination (cast to payable address)
    // ・ [1]: Contract address (cast to ERC721 and used)
    // ・ [2]: Payment amount
    // ----------------------------------------------
    function payInfo( uint256 tradeId ) external view returns (uint256[3] memory);

    //----------------------------------------------
    // Get refund information
    // ----------------------------------------------
    // The breakdown of uint256 [2] is as follows
    // ・ [0]: Refund destination (cast to payable address)
    // ・ [1]: Refund amount
    //----------------------------------------------
    function refundInfo( uint256 tradeId ) external view returns (uint256[2] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//-----------------------------------------------------------------------
// IDutchAuction
//-----------------------------------------------------------------------
interface IDutchAuction  {
    //----------------------------------------
    // Events
    //----------------------------------------
    event DutchAuction( address indexed contractAddress, uint256 indexed tokenId, address auctioneer, uint256 startingPrice, uint256 endingPrice, uint256 expireDate, uint256 startMargin, uint256 endMargin, uint256 auctionId );
    event DutchAuctionCanceled( uint256 indexed auctionId, address indexed contractAddress, uint256 indexed tokenId, address auctioneer );
    event DutchAuctionSold( uint256 indexed auctionId,  address indexed contractAddress, uint256 indexed tokenId, address auctioneer, address buyer, uint256 price ); 
    event DutchAuctionInvalidated( uint256 indexed auctionId, address indexed contractAddress, uint256 indexed tokenId, address auctioneer );

    //----------------------------------------
    // Functions
    //----------------------------------------
    function dutchAuction( address msgSender, address contractAddress, uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 period, uint256 startMargin, uint256 endMargin ) external;
    function cancelDutchAuction( address msgSender, uint256 auctionId ) external;
    function buyDutchAuction( address msgSender, uint256 auctionId, uint256 amount ) external;
    function invalidateDutchAuctions( uint256[] calldata auctionIds ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//-----------------------------------------------------------------------
// ISale
//-----------------------------------------------------------------------
interface ISale {
	//----------------------------------------
	// Events
	//----------------------------------------
    event Sale( address indexed contractAddress, uint256 indexed tokenId, address indexed seller, uint256 price, uint256 expireDate, uint256 saleId );
    event SaleCanceled( uint256 indexed saleId, address indexed contractAddress, uint256 indexed tokenId, address seller );
    event Sold( uint256 indexed saleId, address indexed contractAddress, uint256 indexed tokenId, address seller, address buyer, uint256 price );
    event SaleInvalidated( uint256 indexed saleId, address indexed contractAddress, uint256 indexed tokenId, address seller );

    //----------------------------------------
    // Functions
    //----------------------------------------
    function sell( address msgSender, address contractAddress, uint256 tokenId, uint256 price, uint256 period ) external;
    function cancelSale( address msgSender, uint256 saleId ) external;
    function buy( address msgSender, uint256 saleId, uint256 amount ) external;
    function invalidateSales( uint256[] calldata saleIds ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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