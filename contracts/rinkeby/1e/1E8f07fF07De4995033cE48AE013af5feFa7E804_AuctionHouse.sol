// SPDX-License-Identifier: None
pragma solidity 0.8.11;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interface/IAuctionHouse.sol";
import "../interface/IERC2981.sol";
import "../interface/IWETH.sol";

/**
 * @title An open auction house, enabling collectors and curators to run their own auctions
 */
contract AuctionHouse is
    IAuctionHouse,
    ReentrancyGuard,
    Pausable,
    ERC721Holder,
    Ownable
 {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using Counters for Counters.Counter;

    uint constant DENOMINATOR = 10000;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The fee percentage deduct after auction/sale complete.
    uint256 public platformFeePercentage;

    //WETH contract address
    address public immutable wethAddress;

    // A mapping of all of the auctions currently running.
    mapping(uint256 => IAuctionHouse.Auction) public auctions;

    // A mapping of all of the sale order currently running.
    mapping(uint256 => IAuctionHouse.Order) public saleOrder;

    bytes4 constant ERC721_INTERFACE_ID = 0x80ac58cd;
    bytes4 constant ERC1155_INTERFACE_ID = 0xd9b67a26;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    Counters.Counter private _auctionIdTracker;
    Counters.Counter private _saleOrderTracker;

    // set all platform fee transsfer to this address
    address public treasury;

    /**
     * @notice Constructor
     * @param _wethAddress WETH Contract address
     */
    constructor(address _wethAddress)
    {
        platformFeePercentage = 200; // for 5% fee
        timeBuffer = 0;
        wethAddress = _wethAddress;
    }

    /**
     * @notice Require that the specified auction exists
     */
    modifier auctionExists(uint256 auctionId) {
        require(_exists(auctionId, true), "MarketPlace: Auction doesn't exist");
        _;
    }

    /**
     * @notice Require that the specified order exists
     */
    modifier orderExists(uint256 orderId) {
        require(_exists(orderId, false), "MarketPlace: Order doesn't exist");
        _;
    }

    /**
     * @notice valid token amount
     */
    modifier validTokenAmount(uint256 tokenAmount) {
        require(tokenAmount > 0, "MarketPlace: Invalid token amount");
        _;
    }

    /**
     * @notice only english function
     */
    modifier englishAuction(uint256 auctionId) {
        require(auctions[auctionId].auctionType == IAuctionHouse.AuctionType.English, "MarketPlace: Auction is not english");
        _;
    }

    /**
     * @notice check valid contract standard interface
     */
    modifier validCollection(address tokenContract) {
        require(
            IERC165(tokenContract).supportsInterface(ERC721_INTERFACE_ID) || IERC165(tokenContract).supportsInterface(ERC1155_INTERFACE_ID),
            "MarketPlace: tokenContract does not support ERC721/ERC1155 interface"
        );
        _;
    }

    // This is matic receive function
    receive() external payable {
        emit MaticReceive(_msgSender(), msg.value);
    }

    fallback() external payable {}

    /**
     * @notice Create an Sale oder.
     * @param tokenId NFT id want to sale
     * @param tokenContract pass collection address
     * @param reservePrice want to sale NFT on what Price (in wei if 10LNQ than pass 10**Decimal)
     */
    function createSaleOrder(
        uint256 tokenId,
        uint256 tokenAmount,
        address tokenContract,
        address currency,
        uint256 reservePrice
    )
        external
        validCollection(tokenContract)
        validTokenAmount(tokenAmount)
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        address tokenOwner = _checkAndGetTokenOwner(tokenContract,tokenId,tokenAmount);
        uint256 orderId = _saleOrderTracker.current();
        saleOrder[orderId] = Order({
            tokenId: tokenId,
            tokenAmount: tokenAmount,
            tokenContract: tokenContract,
            currency: currency,
            reservePrice: reservePrice,
            tokenOwner: tokenOwner
        });
        _saleOrderTracker.increment();
        _transferNFTToken(tokenContract,tokenOwner,address(this),tokenId,tokenAmount);
        emit OrderPlaced(
            orderId,
            tokenId,
            tokenContract,
            reservePrice,
            tokenOwner
        );
        return orderId;
    }

    /**
     * @notice Cancel an order.
     * @dev Transfers the NFT back to the auction creator and emits an AuctionCancelled event
     */
    function cancelOrder(uint256 orderId)
        external
        nonReentrant
        orderExists(orderId)
    {
        require(
            saleOrder[orderId].tokenOwner == _msgSender(),
            "MarketPlace: Can only be called by auction creator or curator"
        );
        _cancelOrder(orderId);
    }

    /**
     * @notice change reserve price.
     * @dev change and set new saling price
     */
    function setOrderReservePrice(uint256 orderId, uint256 reservePrice)
        external
        orderExists(orderId)
    {
        require(
            reservePrice != saleOrder[orderId].reservePrice,
            "MarketPlace: price must be difference"
        );
        require(
            _msgSender() == saleOrder[orderId].tokenOwner,
            "MarketPlace: Must be sale order owner can change"
        );
        saleOrder[orderId].reservePrice = reservePrice;
        emit OrderReservePriceUpdated(
            orderId,
            saleOrder[orderId].tokenId,
            saleOrder[orderId].tokenContract,
            reservePrice
        );
    }

    /**
     * @notice buy order.
     * @param orderId pass order id
     */
    function buyOrder(uint256 orderId)
        external payable
        orderExists(orderId)
        nonReentrant
    {
        uint256 platformFee = 0;
        uint256 royaltyFee = 0;
        Order memory order = saleOrder[orderId];
        uint256 tokenOwnerProfit = order.reservePrice;
        delete saleOrder[orderId];
        _handleIncomingBid(tokenOwnerProfit, order.currency);
        if (treasury != address(0)) {
            platformFee = (tokenOwnerProfit * platformFeePercentage) / (10000);
            _handleOutgoingBid(treasury, platformFee, order.currency);
        }
        if (checkRoyalties(order.tokenContract)) {
            (address receiver, uint256 royaltyAmount) = IERC2981(
                order.tokenContract
            ).royaltyInfo(order.tokenId, tokenOwnerProfit);
            if (receiver != address(0)) {
                _handleOutgoingBid(receiver, royaltyAmount, order.currency);
                emit RoyaltyTransafer(
                    order.tokenId,
                    order.tokenContract,
                    receiver,
                    royaltyAmount
                );
                royaltyFee = royaltyAmount;
            }
        }
        tokenOwnerProfit = tokenOwnerProfit - (platformFee + (royaltyFee));
        _handleOutgoingBid(order.tokenOwner, tokenOwnerProfit, order.currency);
        _transferNFTToken(order.tokenContract,address(this),_msgSender(), order.tokenId, order.tokenAmount);
        emit OrderSaleEnded(
            orderId,
            order.tokenId,
            order.tokenContract,
            order.tokenOwner,
            _msgSender(),
            tokenOwnerProfit
        );
    }

    // /**
    //  * @notice Create an auction.
    //  * @dev Store the auction details in the auctions mapping and emit an AuctionCreated event.
    //  * @param tokenId NFT id want to sale
    //  * @param tokenContract pass collection address
    //  * @param startTime at what time auction will start (if zero auction start at create time)
    //  * @param duration time period in which auction will run
    //  * @param reservePrice want to sale NFT on what Price (in wei if 10LNQ than pass 10**Decimal)
    //  **/
    function createAuction(
        AuctionType auctionType,
        uint256 tokenId,
        uint256 tokenAmount,
        address tokenContract,
        address currency,
        uint256 duration,
        uint256 reservePrice,
        uint256 extra                       
    )
        external
        validCollection(tokenContract)
        validTokenAmount(tokenAmount)
        nonReentrant
        whenNotPaused
        returns (uint256)
    {
        require(
            duration >= 300,"MarketPlace: duration must be greater than 300"
        );
        if(auctionType == IAuctionHouse.AuctionType.English){
            require(
                extra <= 500,"MarketPlace: extra must be less than 5%"
            );
        }else{
            require(
                extra > reservePrice,"MarketPlace: extra must be less than 10%"
            );
        }
        address tokenOwner = _checkAndGetTokenOwner(tokenContract, tokenId,tokenAmount);
        uint256 auctionId = _auctionIdTracker.current();
        auctions[auctionId] = Auction({
            auctionType: auctionType,
            tokenId: tokenId,
            tokenContract: tokenContract,
            tokenAmount: tokenAmount,
            startTime: block.timestamp,
            duration: duration,
            firstBidTime: 0,
            reservePrice: reservePrice,
            tokenOwner: tokenOwner,
            bidder: payable(address(0)),
            bidAmount: 0,
            currency: currency,
            extra: extra
        });
        _auctionIdTracker.increment();
        _transferNFTToken(tokenContract,tokenOwner,address(this),tokenId,tokenAmount);
        emit AuctionCreated(
            auctionId,
            tokenId,
            tokenContract,
            duration,
            reservePrice,
            tokenOwner
        );
        return auctionId;
    }

    /**
     * @notice change reserve price of auction .
     * @dev change and set new first bid price
     */
    function setAuctionReservePrice(uint256 auctionId, uint256 reservePrice)
        external
        auctionExists(auctionId)
        englishAuction(auctionId)
    {
        require(
            reservePrice != auctions[auctionId].reservePrice,
            "MarketPlace: price must be difference"
        );
        require(
            _msgSender() == auctions[auctionId].tokenOwner,
            "MarketPlace: Must be auction token owner"
        );
        require(
            auctions[auctionId].firstBidTime == 0,
            "MarketPlace: Auction has already started"
        );
        auctions[auctionId].reservePrice = reservePrice;
        emit AuctionReservePriceUpdated(
            auctionId,
            auctions[auctionId].tokenId,
            auctions[auctionId].tokenContract,
            reservePrice
        );
    }

    /**
     * @notice Create a bid on a token, with a given amount.
     * @dev If provided a valid bid, transfers the provided amount to this contract.
     * @param auctionId pass auction id
     * @param amount amount for next bid amount must be greater than last bid amount and auction.extra amount
     */
    function createBid(uint256 auctionId, uint256 amount)
        external
        payable
        auctionExists(auctionId)
        englishAuction(auctionId)
        nonReentrant
        whenNotPaused
    {
        Auction storage auction = auctions[auctionId];
        address payable lastBidder = auction.bidder;
        require(
            auction.startTime <= block.timestamp,
            "MarketPlace: auction is not started yet"
        );
        require(
            block.timestamp < auction.startTime + (auction.duration),
            "MarketPlace: Auction expired"
        );
        require(
            amount >= auction.reservePrice,
            "MarketPlace: Must send at least reservePrice"
        );
        uint extraAmount = (auction.bidAmount * auction.extra)/10000;
        require(
            amount >= auction.bidAmount + extraAmount,
            "MarketPlace: Must send more than last bid by auction.extra amount"
        );

        if (auction.firstBidTime == 0) {
            auction.firstBidTime = block.timestamp;
        } else if (lastBidder != address(0)) {
            _handleOutgoingBid(lastBidder, auction.bidAmount, auction.currency);
            emit RefundPreviousBidder(auctionId,lastBidder,auction.bidAmount,amount);
        }
        auction.bidAmount = amount;
        auction.bidder = payable(_msgSender());
        bool extended = false;
        if (
            auction.startTime + (auction.duration) - (block.timestamp) <
            timeBuffer //if the timegap
        ) {
            // Playing code golf for gas optimization:
            // uint256 expectedEnd = auction.firstBidTime.add(auction.duration);//it needs to be ended
            // uint256 timeRemaining = expectedEnd.sub(block.timestamp);
            // uint256 timeToAdd = timeBuffer.sub(timeRemaining);
            // uint256 newDuration = auction.duration.add(timeToAdd);//extend the time by the 15 min
            uint256 oldDuration = auction.duration;
            auction.duration =
                oldDuration +
                (timeBuffer -
                    ((auction.startTime + (oldDuration)) - (block.timestamp)));
            extended = true;
        }
        bool firstBid = lastBidder == address(0);
        _handleIncomingBid(amount, auction.currency);
        emit AuctionBid(
            auctionId,
            auction.tokenId,
            auction.tokenContract,
            _msgSender(),
            amount,
            firstBid,
            extended
        );
        if (extended) {
            emit AuctionDurationExtended(
                auctionId,
                auction.tokenId,
                auction.tokenContract,
                auction.duration
            );
        }
    }

    /**
     * @notice End an auction, finalizing the bid on Zora if applicable and paying out the respective parties.
     * @dev If for some reason the auction cannot be finalized (invalid token recipient, for example),
     * The auction is reset and the NFT is transferred back to the auction creator.
     */
    function endAuction(uint256 auctionId)
        external
        auctionExists(auctionId)
        englishAuction(auctionId)
        nonReentrant
    {
        Auction memory auction = auctions[auctionId];
        require(
            uint256(auction.firstBidTime) != 0,
            "MarketPlace: Auction hasn't begun"
        );
        if (auction.tokenOwner != _msgSender()) {
            require(
                block.timestamp >= auction.startTime + (auction.duration),
                "MarketPlace: Auction hasn't completed"
            );
        }
        uint256 platformFee = 0;
        uint256 royaltiyFee = 0;
        uint256 tokenOwnerProfit = auction.bidAmount;
        delete auctions[auctionId];
        if (treasury != address(0)) {
            platformFee = (tokenOwnerProfit * platformFeePercentage) / (10000);
            _handleOutgoingBid(treasury, platformFee, auction.currency);
        }
        if (checkRoyalties(auction.tokenContract)) {
            (address receiver, uint256 royaltyAmount) = IERC2981(
                auction.tokenContract
            ).royaltyInfo(auction.tokenId, tokenOwnerProfit);
            if (receiver != address(0)) {
                _handleOutgoingBid(receiver, royaltyAmount, auction.currency);
                emit RoyaltyTransafer(
                    auction.tokenId,
                    auction.tokenContract,
                    receiver,
                    royaltyAmount
                );
                royaltiyFee = royaltyAmount;
            }
        }
        tokenOwnerProfit = tokenOwnerProfit - (platformFee + royaltiyFee);
        _handleOutgoingBid(
            auction.tokenOwner,
            tokenOwnerProfit,
            auction.currency
        );
        _transferNFTToken(auction.tokenContract,address(this),auction.bidder,auction.tokenId,auction.tokenAmount);
        emit AuctionEnded(
            auctionId,
            auction.tokenId,
            auction.tokenContract,
            auction.tokenOwner,
            auction.bidder,
            tokenOwnerProfit
        );
    }

    /**
     * @notice End an auction, finalizing the bid on Zora if applicable and paying out the respective parties.
     * @dev If for some reason the auction cannot be finalized (invalid token recipient, for example),
     * The auction is reset and the NFT is transferred back to the auction creator.
     */
    function buyDuctchAuction(uint256 auctionId)
        external
        auctionExists(auctionId)
        nonReentrant
    {
        Auction memory auction = auctions[auctionId];
        require(auction.auctionType == IAuctionHouse.AuctionType.Dutch, "MarketPlace: Auction is not a DuctchAuction");
        require(
            block.timestamp < auction.startTime + (auction.duration),
            "MarketPlace: Auction has completed"
            );
        uint256 platformFee = 0;
        uint256 royaltiyFee = 0;
        uint256 tokenOwnerProfit = getCurrentPrice(auctionId);
        delete auctions[auctionId];
        if (treasury != address(0)) {
            platformFee = (tokenOwnerProfit * platformFeePercentage) / (10000);
            _handleOutgoingBid(treasury, platformFee, auction.currency);
        }
        if (checkRoyalties(auction.tokenContract)) {
            (address receiver, uint256 royaltyAmount) = IERC2981(
                auction.tokenContract
            ).royaltyInfo(auction.tokenId, tokenOwnerProfit);
            if (receiver != address(0)) {
                _handleOutgoingBid(receiver, royaltyAmount, auction.currency);
                emit RoyaltyTransafer(
                    auction.tokenId,
                    auction.tokenContract,
                    receiver,
                    royaltyAmount
                );
                royaltiyFee = royaltyAmount;
            }
        }
        tokenOwnerProfit = tokenOwnerProfit - (platformFee + royaltiyFee);
        _handleOutgoingBid(
            auction.tokenOwner,
            tokenOwnerProfit,
            auction.currency
        );
        _transferNFTToken(auction.tokenContract,address(this),auction.bidder,auction.tokenId,auction.tokenAmount);
        emit AuctionEnded(
            auctionId,
            auction.tokenId,
            auction.tokenContract,
            auction.tokenOwner,
            auction.bidder,
            tokenOwnerProfit
        );
    }

    /**
     * @notice Cancel an auction.
     * @dev Transfers the NFT back to the auction creator and emits an AuctionCancelled event
     */
    function cancelAuction(uint256 auctionId)
        external
        nonReentrant
        auctionExists(auctionId)
    {
        require(
            auctions[auctionId].tokenOwner == _msgSender(),
            "MarketPlace: Can only be called by auction creator or curator"
        );
        require(
            uint256(auctions[auctionId].firstBidTime) == 0,
            "MarketPlace: Can't cancel an auction once it's begun"
        );
        _cancelAuction(auctionId);
    }

    //// Addmin Funcions

    /**
     * @dev Triggers smart contract to stopped state
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Returns smart contract to normal state
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Set the treasury address
     */
    function SetTreasuryAddress(address _treasury) external onlyOwner {
        require(_treasury != address(0));
        emit TreasuryAddressChanged(treasury, _treasury);
        treasury = _treasury;
    }

    /**
     *@dev owner can platform fee percentage
     */
    function changePlatformFeePercentage(uint256 _platformFeePercentage)
        external
        onlyOwner
    {
        require(
            platformFeePercentage != _platformFeePercentage,
            "MarketPlace: platformFeePercentage is already same"
        );
        emit platFormFeeChanged(platformFeePercentage, _platformFeePercentage);
        platformFeePercentage = _platformFeePercentage;
    }

    /**
     *@dev owner can set buffer time
     */
    function changeBufferTime(uint256 _timeBuffer) external onlyOwner {
        require(
            timeBuffer != _timeBuffer,
            "MarketPlace: _timeBuffer is already same"
        );
        emit BufferTimeChanged(timeBuffer, _timeBuffer);
        timeBuffer = _timeBuffer;
    }

    function getCurrentPrice(uint256 auctionId) internal view returns (uint256) {
        Auction memory auction = auctions[auctionId];
        uint256 currentPrice = 0;
        if(auction.startTime + auction.duration > block.timestamp && auction.auctionType == IAuctionHouse.AuctionType.Dutch) {
            uint perSecAmount = (auction.extra - auction.reservePrice) / (auction.duration);
            currentPrice = auction.extra - ((block.timestamp - auction.startTime) * perSecAmount);
        }
        return currentPrice;
    }

    /// internal Function

    function checkRoyalties(address _contract) internal view returns (bool) {
        bool success = IERC165(_contract).supportsInterface(
            _INTERFACE_ID_ERC2981
        );
        return success;
    }

    /**
     * @dev Given an amount and a currency, transfer the currency to this contract.
     */
    function _handleIncomingBid(uint256 amount, address currency) internal {
        if (amount > 0) {
            // If this is an ETH bid, ensure they sent enough and convert it to WETH under the hood
            if(currency == address(0)) {
                require(msg.value == amount, "Sent ETH Value does not match specified bid amount");
                IWETH(wethAddress).deposit{value: amount}();
            } else {
                // We must check the balance that was actually transferred to the auction,
                // as some tokens impose a transfer fee and would not actually transfer the
                // full amount to the market, resulting in potentally locked funds
                IERC20 token = IERC20(currency);
                uint256 beforeBalance = token.balanceOf(address(this));
                token.safeTransferFrom(msg.sender, address(this), amount);
                uint256 afterBalance = token.balanceOf(address(this));
                require(beforeBalance.add(amount) == afterBalance, "Token transfer call did not transfer expected amount");
            }
        }
    }

    function _handleOutgoingBid(
        address to,
        uint256 amount,
        address currency
    ) internal {
        if (amount > 0) {
            if(currency == address(0)) {
            IWETH(wethAddress).withdraw(amount);

            // If the ETH transfer fails (sigh), rewrap the ETH and try send it as WETH.
            if(!_safeTransferETH(to, amount)) {
                IWETH(wethAddress).deposit{value: amount}();
                IERC20(wethAddress).safeTransfer(to, amount);
            }
        } else {
            IERC20(currency).safeTransfer(to, amount);
        }
        }
    }

    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{value: value}(new bytes(0));
        return success;
    }

    function _transferNFTToken(address _tokenContract,address _from,address _to, uint256 _tokenId,uint256 _tokenAmount) internal {
        if(_checkCollectionType(_tokenContract) == CollectionType.ERC721Type) {
            IERC721(_tokenContract).safeTransferFrom(
            _from,
            _to,
            _tokenId
            );
        }
        else{
            IERC1155(_tokenContract).safeTransferFrom(_from, _to, _tokenId, _tokenAmount,"0x0");
        }
    }

    /**
     * @dev Cancel the Auction by the given auctionId
     */
    function _cancelAuction(uint256 auctionId) internal {
        Auction memory auction = auctions[auctionId];
        delete auctions[auctionId];
        _transferNFTToken(auction.tokenContract,address(this),auction.tokenOwner,auction.tokenId,auction.tokenAmount);
        emit AuctionCancelled(
            auctionId,
            auction.tokenId,
            auction.tokenContract,
            auction.tokenOwner
        );
        
    }

    /**
     * @dev Cancel the Order by the the orderId
     */
    function _cancelOrder(uint256 orderId) internal {
        Order memory order = saleOrder[orderId];
        delete saleOrder[orderId];
        _transferNFTToken(order.tokenContract,address(this),order.tokenOwner,order.tokenId,order.tokenAmount);
        emit OrderCancelled(
            orderId,
            order.tokenId,
            order.tokenContract,
            order.tokenOwner
        );
    }

    function _checkCollectionType(address _contract) internal view returns (CollectionType) {
        if((IERC165(_contract).supportsInterface(ERC721_INTERFACE_ID)) == true) {
            return CollectionType.ERC721Type;
        } else {
            return CollectionType.ERC1155Type;
        }
    }

    /**
     * @dev get token onwer by tokenId
     */
    function _checkAndGetTokenOwner(address tokenContract, uint256 tokenId,uint _tokenAmount) internal view returns (address) {
        address tokenOwner;
        if(_checkCollectionType(tokenContract) == CollectionType.ERC721Type) {
            tokenOwner = IERC721(tokenContract).ownerOf(tokenId);
            require(
                _msgSender() == IERC721(tokenContract).getApproved(tokenId) ||
                _msgSender() == tokenOwner,
                "MarketPlace: Caller must be approved or owner for token id"
            );
        }
        else{
            if(_checkCollectionType(tokenContract) == CollectionType.ERC1155Type) {
                require(
                    IERC1155(tokenContract).balanceOf(_msgSender(), tokenId) <= _tokenAmount,
                    "MarketPlace: Caller must have token amount"
                );
                tokenOwner = _msgSender();
            }
        }
        return tokenOwner;
    }

    /**
     * @dev Check if the Auction / order existed or not
     */
    function _exists(uint256 id, bool isAuction) internal view returns (bool) {
        if (isAuction) {
            return auctions[id].tokenOwner != address(0);
        }
        return saleOrder[id].tokenOwner != address(0);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: None
pragma solidity 0.8.11;

/**
 * @title Interface for Auction
 */
interface IAuctionHouse {
    // Auction Struct
    struct Auction {
        // Auction Type true = english,false = dutch
        AuctionType auctionType;
        // ID for the ERC721 token
        uint256 tokenId;
        // Address for the ERC721 contract_msg
        address tokenContract;
        // The current highest bid amount
        uint256 tokenAmount;
        // the auction starting Time
        uint256 startTime;
        // The length of time to run the auction for, after the state time
        uint256 duration;
        // The time of the first bid
        uint256 firstBidTime;
        // The minimum price of the first bid
        uint256 reservePrice;
        // The address that should receive the funds once the NFT is sold.
        address tokenOwner; //Owner of the token address
        // The address of the current highest bid
        address payable bidder; //address of current highest bidder
        // The amount of the current highest bid
        uint256 bidAmount; //amount of current highest bid
        // currency (e.g., WETH)
        address currency;
        // auction extra info 
        uint256 extra; // english auction bid increment percentage, dutch auction starting price
    }

    // simple sale Order struct
    struct Order {
        // ID for the ERC721 token
        uint256 tokenId;
        // The current highest bid amount
        uint256 tokenAmount;
        // Address for the ERC721 contract
        address tokenContract;
        // currency (e.g., WETH)
        address currency;
        // The minimum price of the sale
        uint256 reservePrice;
        // The address that should receive the funds once the NFT is sold.
        address tokenOwner;
    }

    enum CollectionType{
        ERC721Type,
        ERC1155Type
    }

    enum AuctionType{
        English,
        Dutch
    }
    // emit when order place
    event OrderPlaced(
        uint256 indexed orderId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 reservePrice,
        address tokenOwner
    );

    //emit when auction created
    event AuctionCreated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 duration,
        uint256 reservePrice,
        address tokenOwner
    );

    //emit when order price update
    event OrderReservePriceUpdated(
        uint256 indexed orderId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 reservePrice
    );

    // emit when auction price update
    event AuctionReservePriceUpdated(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 reservePrice
    );

    // emit when auction bid place
    event AuctionBid(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address sender,
        uint256 value,
        bool firstBid,
        bool extended
    );

    // emit when amount is refunded to previous bidder
    event RefundPreviousBidder(
        uint256 indexed auctionId,
        address bidder,
        uint256 amount,
        uint256 nextBidAmount
    );


    // emit when auction duration extended
    event AuctionDurationExtended(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        uint256 duration
    );
    // emit when sale order end
    event OrderSaleEnded(
        uint256 indexed orderId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner,
        address Buyer,
        uint256 amount
    );
    // emit when auction ended
    event AuctionEnded(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner,
        address winner,
        uint256 amount
    );
    // emit when order canceleed
    event OrderCancelled(
        uint256 indexed orderId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner
    );
    // emit when Auction cancel
    event AuctionCancelled(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address indexed tokenContract,
        address tokenOwner
    );

    // emit when Auction cancel
    event RoyaltyTransafer(
        uint256 indexed tokenId,
        address indexed tokenContract,
        address indexed to,
        uint256 amount
    );
    event BufferTimeChanged(uint256 _oldtime, uint256 _newtime);
    event platFormFeeChanged(uint256 _oldFee, uint256 _newFee);
    event AuctionCreatorStateChanged(bool _oldValue, bool _newValue);
    event MinBidIncrementAmountChanged(
        uint256 _oldIncreament,
        uint256 _newIncrement
    );
    event TreasuryAddressChanged(
        address _oldTreasuryAddress,
        address _newTreasuryAddress
    );
    event MaticReceive(address _spender, uint256 amount);
}

// SPDX-License-Identifier: None
pragma solidity 0.8.11;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

///
/// @dev Interface for the NFT Royalty Standard
///
interface IERC2981 is IERC165 {
    /// ERC165 bytes to add to interface array - set in parent contract
    /// implementing this standard
    ///
    /// bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    /// bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    /// _registerInterface(_INTERFACE_ID_ERC2981);

    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: None
pragma solidity 0.8.11;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
    function transfer(address to, uint256 value) external returns (bool);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
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