//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/ExchangeInterface.sol";
import "./interfaces/ConfigInterface.sol";
import "./interfaces/VotePoolInterface.sol";
import "./interfaces/NFTVoteErrors.sol";
import "./lib/Constants.sol";
import "./lib/VoteContextCenter.sol";
import "./lib/Upgradeable.sol";

import "oz/token/ERC721/IERC721.sol";
import "oz/token/ERC721/IERC721Receiver.sol";
import "oz/security/ReentrancyGuard.sol";
import "oz/utils/Multicall.sol";

contract NFTExchangeLayout is ReentrancyGuard, Upgradeable, Multicall, VoteContextCenter {
    /// @dev order order data.
    mapping(bytes32 => Order) internal _orders;

    ConfigInterface public config;
    /// @notice Record if there is a transaction history.
    /// @dev first-time vs second-time tx:
    //     1. Only auctions are allowed for the first transaction of each NFT.
    //     2. Diffrent transaction fees for first-time and second-time transactions.
    //
    /// @dev Retruns whether the given NFT item has been a sold transaction.
    mapping(address => mapping(uint256 => bool)) public isExistSold;

    /// @dev Sending eth may fail. we will add it here
    ///      to keep the order working.
    ///
    /// This is prevent from DOS attacks. For exmaple:
    ///   1.when a new bid is placed. the last bidder's money need to be refunded.
    ///     New bids will not submit sucessfully when the last bidder refuse.
    ///   2.Likewise,the seller also refuse to agree to a deal for some reasons.
    ///
    /// the key is account address.
    mapping(address => uint256) public unclaimedETH;

    address[] public votePools;

    /**
     * @dev no constructor in upgradable contracts. Instead we have initializers
     * @param _config initial  config address
     */
    function initialize(ConfigInterface _config) external initializer {
        require(address(_config) != address(0), "config is empty");
        config = _config;

        _init();
    }
}

contract NFTExchange is ExchangeInterface, IERC721Receiver, NFTExchangeLayout {
    function getOrder(bytes32 orderHash) external view override returns (Order memory) {
        Order memory o = _orders[orderHash];
        o.status = _getStatus(_orders[orderHash]);
        return o;
    }

    /// @dev claim eth.
    function claimETH() external {
        uint256 amount = unclaimedETH[msg.sender];
        unclaimedETH[msg.sender] = 0;
        _transferETH(payable(msg.sender), amount, false);
    }

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
        address,
        address,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        OriginOrder memory order = abi.decode(data, (OriginOrder));

        if (order.token != msg.sender || order.tokenId != tokenId) {
            revert TokenIsNotReceived();
        }
        _sell(order);

        return IERC721Receiver.onERC721Received.selector;
    }

    /**
     * @notice unstake vote
     * @dev You can call unstak and other function through Multicall
     */
    function unstake(VotePoolInterface vpool, uint256[] calldata voteIds) external {
        if (voteIds.length == 1) {
            vpool.unstake(voteIds[0]);
        } else if (voteIds.length > 1) {
            vpool.batchUnstake(voteIds);
        }
        //ignore empty
    }

    /// @notice Sell One ERC721 NFT and list it on NFTVoter Protocol.
    /// @dev Provide order entry for some non-standard NFTs.
    ///
    /// Emits a `NewOrder` event.
    ///
    /// Please use `safeTransferFrom` method to create order for standard NFT,as below:
    /// ```
    ///   Order memory order;// set order
    ///   IERC721(order.token).safeTransferFrom(order.seller,address(NFTExchange),abi.encode(order));
    /// ```
    ///
    /// How to identiy the order type:
    ///   1. Auction with reserve: reservePrice>0 && startingPrice!=reservePrice
    ///   1. Auction without reserve: reservePrice=0 && startingPrice>0
    ///   2. Fixed-price Mode: reservePrice>0 && startingPrice=reservePrice
    ///
    /// Requirements:
    ///
    ///  1. `order` may not be duplicated.
    ///  2. Only auctions are allowed for the first transaction of each NFT.
    ///  3. has approved to NFTExchange to transfer nft.
    ///
    /// @param order order parameters,see `Order` struct.
    function sell(OriginOrder calldata order) external override nonReentrant {
        IERC721(order.token).transferFrom(order.seller, address(this), order.tokenId);
        _sell(order);
    }

    /// @notice Bidder bid for the given order.
    /// @dev
    ///
    /// Requirements:
    ///
    /// - order is still in the list(order status does not include unsold and sold).
    /// - `msg.sender` can't be order seller.
    /// - Diffrent requirements  for offer for diffrent kinds of order:
    ///     1. Filexed Price Order:  `msg.value` must be equal `order.reservePrice`.
    ///     2. Auction Order:  `msg.value` must be hegher then `last offer price * 1.05`.
    ///
    /// Order sold conditions:
    ///  1. FixedPrice :  `msg.value` = `order.reservePrice`
    ///  2. Auction with reserve: `msg.value` >= `order.reservePrice`
    ///  3. Auction without reserve: auction end.
    ///
    /// @param orderHash the hash of order.
    ///
    /// Emits a `Bid` events and a `OrderSold` event if sold.
    ///
    function buy(bytes32 orderHash) external payable override nonReentrant {
        Order storage order = _orders[orderHash];

        OrderStatus status = _getStatus(order);

        if (status != OrderStatus.Listing) {
            revert OrderIsNotInListing();
        }
        uint256 reservePrice = order.reservePrice;
        uint256 offerPrice = msg.value;

        OrderKind kind = _getKind(order);
        bool sold;
        if (kind == OrderKind.FixedPrice) {
            if (offerPrice != reservePrice) {
                revert OfferPriceNotEqualClosePrice();
            }
            sold = true;
        } else if (kind == OrderKind.AuctionWithReserve) {
            if (offerPrice >= reservePrice) {
                sold = true;
            } else if (offerPrice < _getMinAuctionPrice(order)) {
                revert OfferPriceTooLow();
            }
        } else if (kind == OrderKind.AuctionWithoutReserve) {
            if (offerPrice < _getMinAuctionPrice(order)) {
                revert OfferPriceTooLow();
            }
            //slither-disable-next-line timestamp
            sold = block.timestamp == order.endTime;
        } else {
            revert("F");
        }

        if (reservePrice > 0 && offerPrice > reservePrice) {
            // return of excess funds
            _transferETH(payable(msg.sender), offerPrice - reservePrice, false);
            // reset offerPrice = min(offerprice, reservePrice)
            offerPrice = reservePrice;
        }

        // update last bid and return
        {
            address last = order.lastBidder;
            uint256 lastBid = order.lastBid;

            order.lastBidder = payable(msg.sender);
            order.lastBid = uint120(offerPrice); //safe
            // return last
            if (last != address(0)) {
                _transferETH(payable(last), lastBid, true);
            }
            emit Bid(orderHash, msg.sender, offerPrice);
        }
        if (sold) {
            _sold(orderHash);
        }
    }

    /// @notice Seller cancel the given order.
    /// @dev Orders can only be canceled if order does not have any
    ///       votes and auctions.
    /// Requirements:
    ///
    ///   1. `msg.sender` must be the order seller.
    ///   2.  no votes
    ///   3.  no auctions.
    ///   4.  order is in list.
    ///
    /// @param orderHash Exepcted cancellation order hash.
    ///
    /// Emits an `OrderCanceled` event.
    function cancel(bytes32 orderHash) external override nonReentrant {
        Order storage order = _orders[orderHash];

        if (msg.sender != order.seller) {
            revert InvalidOrderOwner();
        }

        if (order.lastBidder != address(0)) {
            revert DisableCancelOrder();
        }
        if (order.status != OrderStatus.Unknown) {
            revert DisableCancelOrder();
        }
        // disable cancel when order is expired.
        //slither-disable-next-line timestamp
        if (order.endTime < block.timestamp) {
            revert DisableCancelOrder();
        }

        VoteContext memory ctx = VoteContextCenter.version(order.contextId);
        for (uint256 i = 0; i < ctx.pools.length; i++) {
            if (VotePoolInterface(ctx.pools[i].pool).voted(orderHash)) {
                revert DisableCancelOrder();
            }
        }

        order.status = OrderStatus.Canceled;

        IERC721(order.token).transferFrom(address(this), order.seller, order.tokenId);

        emit OrderCanceled(orderHash);
    }

    /// @notice  Close expired orders.
    /// @dev Everyone can close an order after it has expired.
    ///
    /// @param orderHash the hash of order.
    ///
    /// Emits an `OrderSold` event or `OrderUnsold` event.
    function close(bytes32 orderHash) external override nonReentrant {
        _close(orderHash, false);
    }

    /**
     * @notice Close expired orders but ignore duplicate close errors.
     * @dev see `close` method.
     */
    function keepClose(bytes32 orderHash) external override nonReentrant {
        _close(orderHash, true);
    }

    /**
     * @notice Retrieve the status of a given order by hash.
     *
     * @param orderHash The order hash.
     */
    function getOrderStatus(bytes32 orderHash) external view override returns (OrderStatus) {
        return _getStatus(_orders[orderHash]);
    }

    function lastBidder(bytes32 orderHash) external view override returns (address) {
        return _orders[orderHash].lastBidder;
    }

    function endTime(bytes32 orderHash) external view override returns (uint256) {
        return _orders[orderHash].endTime;
    }

    function getOrderHash(OriginOrder memory order) public pure override returns (bytes32) {
        return keccak256(abi.encode(order));
    }

    /**
     * @dev create new order after receiving the NFT.
     */
    function _sell(OriginOrder memory order) private {
        bytes32 orderHash = getOrderHash(order);

        if (_orders[orderHash].seller != address(0)) {
            revert DuplicateOrder();
        }
        // safe check nft
        if (IERC721(order.token).ownerOf(order.tokenId) != address(this)) {
            revert NFTNotReceived();
        }
        if (order.seller == address(0)) {
            revert MissingAddress();
        }
        //slither-disable-next-line timestamp
        if (order.endTime <= block.timestamp) {
            revert InvalidEndTime();
        }
        if (order.endTime > block.timestamp + MAX_ORDER_LIVE_TIME) {
            revert OrderEndTimeOverLimit();
        }
        if (order.startingPrice < MIN_STARTING_PRICE) {
            revert InvalidStartingPrice();
        }

        if (order.reservePrice > 0 && order.reservePrice < order.startingPrice) {
            revert InvalidReservePrice();
        }

        bool firstBidding = !isExistSold[order.token][order.tokenId];
        if (firstBidding && order.startingPrice == order.reservePrice) {
            // first transaction
            // Only auctions are allowed for the first transaction of each NFT.
            revert DisableFirstSellWithFixedPrice();
        }

        bytes32 contextId = VoteContextCenter._loadOrSave(firstBidding, order.votePools);

        //save
        _orders[orderHash] = Order({
            status: OrderStatus.Unknown,
            seller: order.seller,
            salt: order.salt,
            reservePrice: order.reservePrice,
            startingPrice: order.startingPrice,
            startTime: order.startTime,
            endTime: order.endTime,
            token: order.token,
            tokenId: order.tokenId,
            lastBidder: payable(address(0)),
            lastBid: 0,
            contextId: contextId
        });
        // emit
        emit NewOrder(order.seller, orderHash);
    }

    function _close(bytes32 orderHash, bool ignoreRepeat) private {
        Order storage order = _orders[orderHash];
        if (order.status != OrderStatus.Unknown) {
            if (ignoreRepeat) {
                return;
            }
            revert OrderIsClosed();
        }
        //slither-disable-next-line timestamp
        if (order.endTime > block.timestamp) {
            revert OrderIsListing();
        }

        OrderKind kind = _getKind(order);
        if (kind == OrderKind.AuctionWithoutReserve && order.lastBidder != address(0)) {
            // to heighest bidder
            _sold(orderHash);
        } else {
            _unsold(orderHash);
        }
    }

    /// @dev Returns the real time status of order.
    function _getStatus(Order storage order) internal view returns (OrderStatus) {
        // safe check
        assert(order.seller != address(0));

        // Use the order status if exists.
        if (order.status != OrderStatus.Unknown) {
            return order.status;
        }
        // check real status
        //slither-disable-next-line timestamp
        return order.endTime < block.timestamp ? OrderStatus.Unsold : OrderStatus.Listing;
    }

    /// @notice Retruns the kind of order(FixedPrice、AuctionWithoutReserve、AuctionWithReserve)
    /// @dev
    /// How to identiy the order type:
    ///   1. Auction with reserve: reservePrice>0 && startingPrice!=reservePrice
    ///   1. Auction without reserve: reservePrice=0 && startingPrice>=0
    ///   2. Fixed-price Mode: reservePrice>0 && startingPrice=reservePrice
    function _getKind(Order storage order) internal view returns (OrderKind) {
        // safe check
        assert(order.seller != address(0));

        uint256 reservePrice = order.reservePrice;
        uint256 startingPrice = order.startingPrice;
        if (reservePrice == 0) {
            return OrderKind.AuctionWithoutReserve;
        } else {
            if (startingPrice == reservePrice) {
                return OrderKind.FixedPrice;
            } else {
                return OrderKind.AuctionWithReserve;
            }
        }
    }

    function _getMinAuctionPrice(Order storage order) internal view returns (uint256) {
        uint120 last = order.lastBid;
        if (last == 0) {
            return order.startingPrice;
        } else {
            return (last + (last * MinQuoteIncreaseFactor) / FACTOR_DENOMINATOR);
        }
    }

    function _sold(bytes32 orderHash) internal {
        Order storage order = _orders[orderHash];

        address bidder = order.lastBidder;
        uint256 amount = order.lastBid;

        //update status
        order.status = OrderStatus.Sold;

        //transfer NFT to bidder
        IERC721(order.token).transferFrom(address(this), bidder, order.tokenId);

        VoteContext memory ctx = VoteContextCenter.version(order.contextId);

        uint256 totalFee;
        // send to ori
        {
            uint256 fee0 = (amount * ctx.protocolEarnFactor) / FACTOR_DENOMINATOR;
            if (fee0 > 0) {
                totalFee += fee0;
                _transferETH(payable(config.getAddress(KEY_ORI_TAX_RECEIVER)), fee0, false);
            }
        }
        // send to vote pool
        {
            for (uint256 i = 0; i < ctx.pools.length; i++) {
                uint256 fee = (amount * ctx.pools[i].earnFactor) / FACTOR_DENOMINATOR;
                if (fee > 0) {
                    totalFee += fee;
                    VotePoolInterface(ctx.pools[i].pool).deposit{value: fee}(orderHash, fee);
                }
            }
        }
        //transfer ETH to seller
        _transferETH(payable(order.seller), amount - totalFee, true);
        isExistSold[order.token][order.tokenId] = true;
        emit OrderSold(orderHash);
    }

    function _unsold(bytes32 orderHash) internal {
        Order storage order = _orders[orderHash];
        //expired
        order.status = OrderStatus.Unsold;
        // refund the last offer
        if (order.lastBidder != address(0)) {
            _transferETH(order.lastBidder, order.lastBid, true);
        }

        IERC721(order.token).transferFrom(address(this), order.seller, order.tokenId);

        emit OrderUnsold(orderHash);
    }

    /**
     * @dev Internal function to transfer Ether  to a given recipient.
     *
     * @param to     The recipient of the transfer.
     * @param amount The amount to transfer.
     * @param pickupOnFailure  Whether to pick up on transfer failure.
     */
    function _transferETH(
        address payable to,
        uint256 amount,
        bool pickupOnFailure
    ) private {
        if (amount == 0) {
            revert MissingItemAmount();
        }
        if (to == address(0)) {
            revert MissingAddress();
        }
        //slither-disable-next-line low-level-calls arbitrary-send-eth
        (bool success, ) = to.call{value: amount}("");
        if (!success) {
            if (pickupOnFailure) {
                // update.
                unclaimedETH[to] += amount;
            } else {
                revert EtherTransferGenericFailure();
            }
        }
    }

    /**
     * @notice Reset the default voting config.
     * @dev Settings will take effect on the next bidding order.
     */
    function resetDefaultVoteContext(VoteContext calldata forFirst, VoteContext calldata forOther) external {
        if (msg.sender != config.owner()) {
            revert InvalidSender();
        }
        VoteContextCenter._reset(true, forFirst);
        VoteContextCenter._reset(false, forOther);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../lib/Structs.sol";

/**
 * @notice NFT exchange
 * @author ysqi
 * @dev An EIP721 NFT trading exchange protocol with support
 * for fixed-price and bidding acutions.
 */
interface ExchangeInterface {
    /// @notice `seller` has created a new order.
    /// @param seller the order creator.
    /// @param orderHash the hash of new order.
    event NewOrder(address indexed seller, bytes32 orderHash);

    /// @notice `bidder` bid
    /// @param orderHash the hash of target order.
    /// @param bidder the sender of this offer.
    /// @param amount the offer price.
    event Bid(bytes32 indexed orderHash, address indexed bidder, uint256 amount);

    event OrderSold(bytes32 indexed orderHash);

    /// @dev `seller` cancels order.
    event OrderCanceled(bytes32 indexed orderHash);

    /// @dev The order has expired and failed to sell.
    event OrderUnsold(bytes32 indexed orderHash);

    /// @notice Bidder bid for the given order.
    /// @dev
    ///
    /// Requirements:
    ///
    /// - order is still in the list(order status does not include unsold and sold).
    /// - `msg.sender` can't be order seller.
    /// - Diffrent requirements  for offer for diffrent kinds of order:
    ///     1. Filexed Price Order:  `msg.value` must be equal `order.reservePrice`.
    ///     2. Auction Order:  `msg.value` must be hegher then `last offer price * 1.05`.
    ///
    /// Order sold conditions:
    ///  1. FixedPrice :  `msg.value` = `order.reservePrice`
    ///  2. Auction with reserve: `msg.value` >= `order.reservePrice`
    ///  3. Auction without reserve: auction end.
    ///
    /// @param orderHash the hash of order.
    ///
    /// Emits a `Bid` events and a `OrderSold` event if sold.
    ///
    function buy(bytes32 orderHash) external payable;

    /// @notice Sell One ERC721 NFT and list it on NFTVoter Protocol.
    /// @dev Provide order entry for some non-standard NFTs.
    ///
    /// Emits a `NewOrder` event.
    ///
    /// Please use `safeTransferFrom` methodto create order for standard NFT,as below:
    /// ```
    ///   Order memory order;// set order
    ///   IERC721(order.token).safeTransferFrom(order.seller,address(NFTExchange),abi.encode(order));
    /// ```
    ///
    /// How to identiy the order type:
    ///   1. Auction Mode with limit: closePrice>0 && startingPrice!=closePrice
    ///   1. Auction Mode with nolimit: closePrice=0 && startingPrice>0
    ///   2. Fixed-price Mode: closePrice>0 && startingPrice=closePrice
    ///
    /// Requirements:
    ///
    ///  1. `order` may not be duplicated.
    ///  2. Only auctions are allowed for the first transaction of each NFT.
    ///  3. has approved to NFTExchange to transfer nft.
    ///
    /// @param order order parameters,see `Order` struct.
    function sell(OriginOrder calldata order) external;

    /// @notice Seller cancel the given order.
    /// @dev Orders can only be canceled if order does not have any
    ///       votes and auctions.
    /// Requirements:
    ///
    ///   1. `msg.sender` must be the order seller.
    ///   2.  no votes
    ///   3.  no auctions.
    ///   4.  order is in list.
    ///
    /// @param orderHash Exepcted cancellation order hash.
    ///
    /// Emits an `OrderCanceled` event.
    function cancel(bytes32 orderHash) external;

    /// @notice  Close expired orders.
    /// @dev Everyone can close an order after it has expired.
    ///
    /// @param orderHash the hash of order.
    ///
    /// Emits an `OrderSold` event or `OrderUnsold` event.
    function close(bytes32 orderHash) external;

    /**
     * @notice Close expired orders but ignore duplicate close errors.
     * @dev see `close` method.
     */
    function keepClose(bytes32 orderHash) external;

    function getOrder(bytes32 orderHash) external view returns (Order calldata);

    /**
     * @notice Retrieve the status of a given order by hash.
     *
     * @param orderHash The order hash.
     */
    function getOrderStatus(bytes32 orderHash) external view returns (OrderStatus);

    function getOrderHash(OriginOrder calldata order) external view returns (bytes32);

    function lastBidder(bytes32 orderHash) external view returns (address);

    function endTime(bytes32 orderHash) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Config Center
 * @author ysqi
 * @notice  Manage all configs for nttvoter protocol.
 * each config the type of item key is bytes32, the item value type is bytes32 too.
 */
interface ConfigInterface {
    /*
     * @notice Configuration change event
     * @param key
     * @param value is the new value.
     */
    event Changed(bytes32 indexed key, bytes32 value);

    function owner() external view returns (address);

    /**
     * @dev Returns the value of the given configuration item.
     */
    function get(bytes32 key) external view returns (bytes32);

    /**
     * @dev Returns value of the given configuration item.
     * Safely convert the bytes32 value to address before returning.
     */
    function getAddress(bytes32 key) external view returns (address);

    /**
     * @dev Returns value of the given configuration item.
     */
    function getUint256(bytes32 key) external view returns (uint256);

    /**
     * @notice Reset the configuration item value to an address.
     *
     * Emits an `Changed` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function resetAddress(bytes32 key, address value) external;

    /**
     * @notice Reset the configuration item value to a uint256.
     *
     * Emits an `Changed` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function resetUint256(bytes32 key, uint256 value) external;

    /**
     * @notice Reset the configuration item value to a bytes32.
     *
     * Emits an `Changed` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function reset(bytes32 key, bytes32 value) external;
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../lib/Structs.sol";

interface VotePoolInterface {
    event Voted(bytes32 indexed orderHash, address indexed voter, uint256 voteId);

    function stakeETH(bytes32 orderHash) external payable;

    function stakeERC20(bytes32 orderHash, uint256 amount) external;

    function unstake(uint256 voteId) external;

    function batchUnstake(uint256[] calldata voteIds) external;

    function deposit(bytes32 orderHash, uint256 fee) external payable;

    function voted(bytes32 orderHash) external view returns (bool);

    /**
     * @dev Returns the vote weight for a given number of votes.
     *
     */
    function currentShare(bytes32 orderHash, uint256 amount) external view returns (uint120);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

error TokenIsNotReceived();
error OrderIsNotInListing();
error OfferPriceNotEqualClosePrice();
error OfferPriceTooLow();
error InvalidOrderOwner();
error DisableCancelOrder();
error OrderIsClosed();
error OrderIsListing();
error OrderIsNotListing();
error DuplicateOrder();
error NFTNotReceived();
error InvalidEndTime();
error InvalidStartingPrice();
error InvalidReservePrice();
error DisableFirstSellWithFixedPrice();
error MissingItemAmount();
error MissingAddress();
error EtherTransferGenericFailure();
error ERC20TransferGenericFailure();
error OnlyCallByVotePool();
error RepeatWithdrawal();
error InvalidAmount();
error VoteAmoutTooLow();
error VoteWeightIsZero();
error InvalidSender();
error InvalidShare();
error VotePoolMismatch();
error InvalidTax();
error InvalidDeposit();
error OrderEndTimeOverLimit();
error NotFoundVote(uint256 voteId);

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev the key of trade fee receiver
 * key= Keccak-256(KEY_ORI_TAX_RECEIVER)
 */
bytes32 constant KEY_ORI_TAX_RECEIVER = 0xbc8378c341cc1e99afa602b3a2f6ed732baaa175989ee07ef7cdb098ff3286d3;

/**
 * @dev
 */
bytes32 constant KEY_VOTE_CANCEL_FEE_RECEIVER = 0xb7c55bf209a75a5dfac723c0a43aefe1ecc4f32bf3545d8bc7fe9ebf80d2404b;

bytes32 constant KEY_VOTE_CANCEL_FEE = 0x0792ddd065b2799bd31414a0ea136022cdcedd222353debd2ea1b84fcbd71509;

uint256 constant FACTOR_DENOMINATOR = 10_000;

uint16 constant MinQuoteIncreaseFactor = 500; // 5%

uint256 constant MIN_STARTING_PRICE = 0.01 * 1e18; //0.01 ETH

uint256 constant VOTING_LOCKOUT_DURATION = 2 days;

uint256 constant VOTE_WEIGHT_FACTOR_DENOMINATOR = 10_000;

uint256 constant MAX_ORDER_LIVE_TIME = 15 days;

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Structs.sol";
import "./Constants.sol";
import "../interfaces/VotePoolInterface.sol";
import "../interfaces/NFTVoteErrors.sol";

/**
 * @notice Voting Context
 * @author ysqi
 * @dev Versioning of the voting environment for each bid order.
 */
contract VoteContextCenter {
    event NewContext(bytes32 id, uint256 protocolEarnFactor, uint256 poolEarnFactor);
    event DefaultContextChanged(bytes32 id, bool forFirstBid, uint256 protocolEarnFactor, uint256 poolEarnFactor);

    /**
     * @dev First bid config id for one NFT.
     * ID is the hash of config.
     */
    bytes32 private _v0;
    bytes32 private _v1;

    mapping(bytes32 => VoteContext) private _versions;

    /**
     * @dev Change default config.
     * Repalces the current default config with the new one.
     */
    function _reset(bool forFirstBid, VoteContext calldata ctx) internal {
        require(ctx.protocolEarnFactor > 0, "earn is zero");
        require(ctx.pools.length > 0, "pools is empty");

        uint256 factor;
        for (uint256 i = 0; i < ctx.pools.length; i++) {
            VotePoolMeta memory meta = ctx.pools[i];
            require(meta.pool != address(0), "address is empty");
            require(meta.earnFactor > 0, "earn is zero");

            //safecheck
            VotePoolInterface(meta.pool).voted(bytes32(0));

            factor += meta.earnFactor;
        }
        require(factor + ctx.protocolEarnFactor < FACTOR_DENOMINATOR, "earn overflow");

        bytes32 id = versionId(ctx);
        _versions[id] = ctx;
        if (forFirstBid) {
            _v0 = id;
        } else {
            _v1 = id;
        }
        emit DefaultContextChanged(id, forFirstBid, ctx.protocolEarnFactor, factor);
    }

    function _loadOrSave(bool forFirstBid, VotePoolMeta[] memory pools) internal returns (bytes32 id) {
        uint16 protocolEarnFactor = _versions[forFirstBid ? _v0 : _v1].protocolEarnFactor;
        id = versionId(VoteContext({protocolEarnFactor: protocolEarnFactor, pools: pools}));
        if (_versions[id].protocolEarnFactor > 0) {
            return id; //exist
        }

        // check and save it.
        VoteContext memory current = currentVersion(forFirstBid);

        if (pools.length != current.pools.length) {
            revert VotePoolMismatch();
        }

        VoteContext storage ctx_s = _versions[id];

        uint256 factor;
        for (uint256 i = 0; i < pools.length; i++) {
            if (pools[i].pool != current.pools[i].pool) {
                revert VotePoolMismatch();
            }
            if (pools[i].earnFactor <= current.pools[i].earnFactor) {
                revert InvalidTax();
            }
            factor += pools[i].earnFactor;
            ctx_s.pools.push(pools[i]);
        }

        if (factor + protocolEarnFactor >= FACTOR_DENOMINATOR) {
            revert InvalidTax();
        }

        ctx_s.protocolEarnFactor = protocolEarnFactor;

        emit NewContext(id, protocolEarnFactor, factor);
    }

    function versionId(VoteContext memory ctx) public pure returns (bytes32) {
        return keccak256(abi.encode(ctx));
    }

    function currentVersion(bool forFirstBid) public view returns (VoteContext memory) {
        return _versions[forFirstBid ? _v0 : _v1];
    }

    function version(bytes32 id) public view returns (VoteContext memory) {
        return _versions[id];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "oz-upgradeable/proxy/utils/Initializable.sol";
import "oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "oz-upgradeable/access/OwnableUpgradeable.sol";

abstract contract Upgradeable is UUPSUpgradeable, OwnableUpgradeable {
    /**
     * @dev oz-upgrades-unsafe-allow constructor
     */
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev no constructor in upgradable contracts. Instead we have initializers
     */
    function _init() internal {
        ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
        __Ownable_init();
    }

    /**
     * @dev required by the OZ UUPS module
     */
    function _authorizeUpgrade(address) internal view override {
        _checkOwner();
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
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
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./Enums.sol";

struct Order {
    //solt
    address payable seller; // 20bytes- The sellers of NFT
    uint64 startTime; // Order effective time.
    OrderStatus status; // 1byte
    //solt
    bytes32 contextId; // voting context.
    //solt
    uint64 endTime; //  Order expiration time.
    address token; // The contract address of the nft token.
    //solt
    uint256 tokenId; // The token id of the nft token.
    //solt
    uint120 startingPrice; // Starting price of the auction.
    uint120 reservePrice; // The seller' expected closing price.
    //solt
    uint120 salt; // The salt of the order.
    uint120 lastBid;
    //solt
    address payable lastBidder;
}

struct OriginOrder {
    address payable seller; // The sellers of NFT
    uint120 salt; // The salt of the order.
    uint120 reservePrice; // The seller' expected closing price.
    uint120 startingPrice; // Starting price of the auction.
    uint64 startTime; // Order effective time.
    uint64 endTime; //  Order expiration time.
    address token; // The contract address of the nft token.
    uint256 tokenId; // The token id of the nft token.
    VotePoolMeta[] votePools;
}

struct VoteMeta {
    bytes32 orderHash;
    uint120 amount;
    uint64 mintTime;
    uint120 share;
    bool withdrawn;
}

struct VotePoolMeta {
    address pool;
    uint16 earnFactor;
}

/**
 * @dev Voting configuration information.
 */
struct VoteContext {
    /**
     * @dev Transaction taxes charged by the platform
     */
    uint16 protocolEarnFactor;
    /**
     * @dev Supported voting pools.
     */
    VotePoolMeta[] pools;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

enum OrderStatus
// 0
{
    Unknown,
    // 1-Orders can continue to be traded while they are still pending
    Listing,
    // 2-The order has been canceled by the seller
    Canceled,
    // 3-The order has expired and failed to sell
    Unsold,
    // 4-The order has been filled
    Sold
}

enum OrderKind
// 0-
{
    FixedPrice,
    // 1-
    AuctionWithoutReserve,
    // 2-
    AuctionWithReserve
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}