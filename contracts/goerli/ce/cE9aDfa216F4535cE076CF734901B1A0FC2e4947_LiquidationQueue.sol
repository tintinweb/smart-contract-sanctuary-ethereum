// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import '@boringcrypto/boring-solidity/contracts/BoringOwnable.sol';
import '@boringcrypto/boring-solidity/contracts/ERC20.sol';
import '../mixologist/Mixologist.sol';
import './ILiquidationQueue.sol';

enum MODE {
    ADD,
    SUB
}

/// @title LiquidationQueue
/// @author @0xRektora, TapiocaDAO
// TODO: Capital efficiency? (register assets to strategies) (farm strat for TAP)
// TODO: ERC20 impl?
contract LiquidationQueue {
    // ************ //
    // *** VARS *** //
    // ************ //

    /**
     * General information about the LiquidationQueue contract.
     */

    LiquidationQueueMeta public liquidationQueueMeta; // Meta-data for this contract.
    Mixologist public mixologist; // The target market.
    BeachBar public beachBar;
    YieldBox public yieldBox;

    uint256 public lqAssetId; // The liquidation queue BeachBar asset id.
    uint256 public marketAssetId; // The mixologist asset id.
    uint256 public liquidatedAssetId; // The asset that is being liquidated.
    bool onlyOnce; // Contract init variable.

    /**
     * Pools & order books information.
     */

    // Bid pools, x% premium => bid pool
    // 0 ... 30 range
    // poolId => userAddress => userBidInfo.
    mapping(uint256 => mapping(address => Bidder)) public bidPools;

    // The actual order book. Entries are stored only once a bid has been activated
    // poolId => bidIndex => bidEntry).
    mapping(uint256 => mapping(uint256 => OrderBookPoolEntry))
        public orderBookEntries;
    // Meta-data about the order book pool
    // poolId => poolInfo.
    mapping(uint256 => OrderBookPoolInfo) public orderBookInfos;

    /**
     * Ledger.
     */

    // user => orderBookEntries[poolId][bidIndex]
    mapping(address => mapping(uint256 => uint256[])) public userBidIndexes; // User current bids.

    // user => amountDue.
    mapping(address => uint256) public balancesDue; // Due balance of users.

    // ***************** //
    // *** CONSTANTS *** //
    // ***************** //

    uint256 constant MAX_BID_POOLS = 10; // Maximum amount of pools.
    // `amount` * ((`bidPool` * `PREMIUM_FACTOR`) / `PREMIUM_FACTOR_PRECISION`) = premium.
    uint256 constant PREMIUM_FACTOR = 100; // Premium factor.
    uint256 constant PREMIUM_FACTOR_PRECISION = 10_000; // Precision of the premium factor.

    uint256 private constant EXCHANGE_RATE_PRECISION = 1e18;

    uint256 private constant WITHDRAWAL_FEE = 50; // 0.5%
    uint256 private constant WITHDRAWAL_FEE_PRECISION = 10_000;

    // ************ //
    // *** INIT *** //
    // ************ //

    /// @notice Acts as a 'constructor', should be called by a Mixologist market.
    /// @param  _liquidationQueueMeta Info about the liquidations.
    function init(LiquidationQueueMeta calldata _liquidationQueueMeta)
        external
    {
        require(!onlyOnce, 'LQ: Initialized');

        liquidationQueueMeta = _liquidationQueueMeta;

        mixologist = Mixologist(msg.sender);
        liquidatedAssetId = mixologist.collateralId();
        marketAssetId = mixologist.assetId();
        beachBar = mixologist.beachBar();
        yieldBox = mixologist.yieldBox();

        lqAssetId = _registerAsset();

        IERC20(mixologist.asset()).approve(
            address(yieldBox),
            type(uint256).max
        );
        yieldBox.setApprovalForAll(address(mixologist), true);

        // We initialize the pools to save gas on conditionals later on.
        for (uint256 i = 0; i <= MAX_BID_POOLS; ) {
            _initOrderBookPoolInfo(i);
            ++i;
        }

        onlyOnce = true; // We set the init flag.
    }

    // ************** //
    // *** EVENTS *** //
    // ************** //

    event Bid(
        address indexed caller,
        address indexed bidder,
        uint256 indexed pool,
        uint256 usdoAmount,
        uint256 liquidatedAssetAmount,
        uint256 timestamp
    );

    event ActivateBid(
        address indexed caller,
        address indexed bidder,
        uint256 indexed pool,
        uint256 usdoAmount,
        uint256 liquidatedAssetAmount,
        uint256 collateralValue,
        uint256 timestamp
    );

    event RemoveBid(
        address indexed caller,
        address indexed bidder,
        uint256 indexed pool,
        uint256 usdoAmount,
        uint256 liquidatedAssetAmount,
        uint256 collateralValue,
        uint256 timestamp
    );

    event ExecuteBids(
        address indexed caller,
        uint256 indexed pool,
        uint256 usdoAmountExecuted,
        uint256 liquidatedAssetAmountExecuted,
        uint256 collateralLiquidated,
        uint256 timestamp
    );

    event Redeem(address indexed redeemer, address indexed to, uint256 amount);
    event BidSwapperUpdated(IBidder indexed _old, IBidder indexed _new);
    event UsdoSwapperUpdated(IBidder indexed _old, IBidder indexed _new);

    // ***************** //
    // *** MODIFIERS *** //
    // ***************** //

    modifier Active() {
        require(onlyOnce, 'LQ: Not initialized');
        _;
    }

    // ************* //
    // *** VIEWS *** //
    // ************* //

    function market() public view returns (string memory) {
        return mixologist.name();
    }

    function getOrderBookSize(uint256 pool) public view returns (uint256 size) {
        OrderBookPoolInfo memory poolInfo = orderBookInfos[pool];
        unchecked {
            size = poolInfo.nextBidPush - poolInfo.nextBidPull;
        }
    }

    // /!\ GAS COST /!\
    function getOrderBookPoolEntries(uint256 pool)
        external
        view
        returns (OrderBookPoolEntry[] memory x)
    {
        OrderBookPoolInfo memory poolInfo = orderBookInfos[pool];
        uint256 orderBookSize = poolInfo.nextBidPush - poolInfo.nextBidPull;

        x = new OrderBookPoolEntry[](orderBookSize); // Initialize the return array.

        mapping(uint256 => OrderBookPoolEntry)
            storage entries = orderBookEntries[pool];
        for (
            (uint256 i, uint256 j) = (poolInfo.nextBidPull, 0);
            i < poolInfo.nextBidPush;

        ) {
            x[j] = entries[i]; // Copy the entry to the return array.

            unchecked {
                ++i;
                ++j;
            }
        }
    }

    // *********** //
    // *** TXS *** //
    // *********** //

    /// @notice Add a bid to a bid pool using stablecoins.
    /// @dev Works the same way as `bid` but performs a swap from the stablecoin to USDO
    ///      - if stableAssetId == usdoAssetId, no swap is performed
    /// @param user The bidder
    /// @param pool To which pool the bid should go
    /// @param stableAssetId Stablecoin YieldBox asset id
    /// @param amountIn Stablecoin amount
    /// @param data Extra data for swap operations
    function bidWithStable(
        address user,
        uint256 pool,
        uint256 stableAssetId,
        uint256 amountIn,
        bytes calldata data
    ) external Active {
        require(pool <= MAX_BID_POOLS, 'LQ: premium too high');
        require(
            address(liquidationQueueMeta.usdoSwapper) != address(0),
            'LQ: USD0 swapper not set'
        );

        uint256 usdoAssetId = beachBar.usdoAssetId();
        yieldBox.transfer(
            msg.sender,
            address(liquidationQueueMeta.usdoSwapper),
            stableAssetId,
            yieldBox.toShare(stableAssetId, amountIn, false)
        );

        uint256 usdoAmount = liquidationQueueMeta.usdoSwapper.swap(
            mixologist,
            stableAssetId,
            amountIn,
            data
        );

        Bidder memory bidder = _bid(user, pool, usdoAmount, true);

        uint256 usdoValueInLqAsset = bidder.swapOnExecute
            ? liquidationQueueMeta.bidExecutionSwapper.getOutputAmount(
                mixologist,
                usdoAssetId,
                usdoAmount,
                data
            )
            : bidder.usdoAmount;

        require(
            usdoValueInLqAsset >= liquidationQueueMeta.minBidAmount,
            'LQ: bid too low'
        );
    }

    /// @notice Add a bid to a bid pool.
    /// @dev Create an entry in `bidPools`.
    ///      Clean the userBidIndex here instead of the `executeBids()` function to save on gas.
    /// @param user The bidder.
    /// @param pool To which pool the bid should go.
    /// @param amount The amount in asset to bid.
    function bid(
        address user,
        uint256 pool,
        uint256 amount
    ) external Active {
        require(pool <= MAX_BID_POOLS, 'LQ: premium too high');
        require(amount >= liquidationQueueMeta.minBidAmount, 'LQ: bid too low');

        // Transfer assets to the LQ contract.
        uint256 assetId = lqAssetId;
        yieldBox.transfer(
            msg.sender,
            address(this),
            assetId,
            yieldBox.toShare(assetId, amount, false)
        );
        _bid(user, pool, amount, false);
    }

    /// @notice Activate a bid by putting it in the order book.
    /// @dev Create an entry in `orderBook` and remove it from `bidPools`.
    /// @dev Spam vector attack is mitigated the min amount req., 10min CD + activation fees.
    /// @param user The user to activate the bid for.
    /// @param pool The target pool.
    function activateBid(address user, uint256 pool) external {
        Bidder memory bidder = bidPools[pool][user];
        require(
            block.timestamp >=
                bidder.timestamp + liquidationQueueMeta.activationTime,
            'LQ: too soon'
        );

        OrderBookPoolInfo memory poolInfo = orderBookInfos[pool]; // Info about the pool array indexes.

        // Create a new order book entry.
        OrderBookPoolEntry memory orderBookEntry;
        orderBookEntry.bidder = user;
        orderBookEntry.bidInfo = bidder;

        // Insert the order book entry and delete the bid entry from the given pool.
        orderBookEntries[pool][poolInfo.nextBidPush] = orderBookEntry;
        delete bidPools[pool][user];

        // Add the index to the user bid index.
        userBidIndexes[user][pool].push(poolInfo.nextBidPush);

        // Update the `orderBookInfos`.
        unchecked {
            ++poolInfo.nextBidPush;
        }
        orderBookInfos[pool] = poolInfo;

        uint256 bidAmount = orderBookEntry.bidInfo.isUsdo
            ? orderBookEntry.bidInfo.usdoAmount
            : orderBookEntry.bidInfo.liquidatedAssetAmount;
        emit ActivateBid(
            msg.sender,
            user,
            pool,
            orderBookEntry.bidInfo.usdoAmount,
            orderBookEntry.bidInfo.liquidatedAssetAmount,
            orderBookEntry.bidInfo.swapOnExecute
                ? liquidationQueueMeta.bidExecutionSwapper.getOutputAmount(
                    mixologist,
                    beachBar.usdoAssetId(),
                    orderBookEntry.bidInfo.usdoAmount,
                    ''
                )
                : bidAmount,
            block.timestamp
        );
    }

    /// @notice Remove a not yet activated bid from the bid pool.
    /// @dev Remove `msg.sender` funds.
    /// @param user The user to send the funds to.
    /// @param pool The pool to remove the bid from.
    /// @return amountRemoved The amount of the bid.
    function removeInactivatedBid(address user, uint256 pool)
        external
        returns (uint256 amountRemoved)
    {
        bool isUsdo = bidPools[pool][msg.sender].isUsdo;
        amountRemoved = isUsdo
            ? bidPools[pool][msg.sender].usdoAmount
            : bidPools[pool][msg.sender].liquidatedAssetAmount;
        delete bidPools[pool][msg.sender];

        uint256 lqAssetValue = amountRemoved;
        if (bidPools[pool][msg.sender].swapOnExecute) {
            lqAssetValue = liquidationQueueMeta
                .bidExecutionSwapper
                .getOutputAmount(
                    mixologist,
                    beachBar.usdoAssetId(),
                    amountRemoved,
                    ''
                );
        }
        require(
            lqAssetValue >= liquidationQueueMeta.minBidAmount,
            'LQ: bid does not exist'
        ); //save gas

        // Transfer assets
        uint256 assetId = isUsdo ? beachBar.usdoAssetId() : lqAssetId;
        yieldBox.transfer(
            address(this),
            user,
            assetId,
            yieldBox.toShare(assetId, amountRemoved, false)
        );

        emit RemoveBid(
            msg.sender,
            user,
            pool,
            isUsdo ? amountRemoved : 0,
            isUsdo ? 0 : amountRemoved,
            lqAssetValue,
            block.timestamp
        );
    }

    /// @notice Remove an activated bid from a given pool.
    /// @dev Clean the userBidIndex here instead of the `executeBids()` function to save on gas.
    ///      To prevent DoS attacks on `executeBids()` and gas costs, the last activated bid
    ///      will take the position of the removed bid.
    /// @param user The user to send the funds to.
    /// @param pool The target pool.
    /// @param bidPosition The position of the bid index inside the `userBidIndexes[msg.sender][pool]`.
    /// @return amountRemoved The amount of the bid removed.
    function removeBid(
        address user,
        uint256 pool,
        uint256 bidPosition
    ) external returns (uint256 amountRemoved) {
        uint256[] storage bidIndexes = userBidIndexes[msg.sender][pool];
        uint256 bidIndexesLen = bidIndexes.length;
        OrderBookPoolInfo memory poolInfo = orderBookInfos[pool];

        uint256 orderBookIndex = bidIndexes[bidPosition];
        bool isUsdo = orderBookEntries[pool][orderBookIndex].bidInfo.isUsdo;

        amountRemoved = isUsdo
            ? orderBookEntries[pool][orderBookIndex].bidInfo.usdoAmount
            : orderBookEntries[pool][orderBookIndex]
                .bidInfo
                .liquidatedAssetAmount;

        // Clean expired bids.
        for (uint256 i = 0; i < bidIndexesLen; ) {
            if (bidIndexes[i] > poolInfo.nextBidPull) {
                bidIndexesLen = bidIndexes.length;
                bidIndexes[i] = bidIndexes[bidIndexesLen - 1];
                bidIndexes.pop();
            }
            unchecked {
                ++i;
            }
        }

        // There might be a case when all bids are expired
        if (bidIndexes.length > 0) {
            // Remove bid from the order book by replacing it with the last activated bid.
            orderBookIndex = bidIndexes[bidPosition];
            isUsdo = orderBookEntries[pool][orderBookIndex].bidInfo.isUsdo;
            amountRemoved = isUsdo
                ? orderBookEntries[pool][orderBookIndex].bidInfo.usdoAmount
                : orderBookEntries[pool][orderBookIndex]
                    .bidInfo
                    .liquidatedAssetAmount;
            orderBookEntries[pool][orderBookIndex] = orderBookEntries[pool][
                poolInfo.nextBidPush - 1
            ];

            // Remove latest userBidIndex
            bidIndexesLen = bidIndexes.length;
            bidIndexes[bidPosition] = bidIndexes[bidIndexesLen - 1];
            bidIndexes.pop();
        }
        // Transfer assets
        uint256 assetId = isUsdo ? beachBar.usdoAssetId() : lqAssetId;
        yieldBox.transfer(
            address(this),
            user,
            assetId,
            yieldBox.toShare(assetId, amountRemoved, false)
        );
        uint256 lqAssetValue = amountRemoved;
        if (orderBookEntries[pool][orderBookIndex].bidInfo.swapOnExecute) {
            lqAssetValue = liquidationQueueMeta
                .bidExecutionSwapper
                .getOutputAmount(
                    mixologist,
                    beachBar.usdoAssetId(),
                    amountRemoved,
                    ''
                );
        }
        emit RemoveBid(
            msg.sender,
            user,
            pool,
            isUsdo ? amountRemoved : 0,
            isUsdo ? 0 : amountRemoved,
            lqAssetValue,
            block.timestamp
        );
    }

    /// @notice Redeem a balance.
    /// @dev `msg.sender` is used as the redeemer.
    /// @param to The address to redeem to.
    function redeem(address to) external {
        require(balancesDue[msg.sender] > 0, 'LQ: No balance due');

        uint256 balance = balancesDue[msg.sender];
        uint256 fee = (balance * WITHDRAWAL_FEE) / WITHDRAWAL_FEE_PRECISION;
        uint256 redeemable = balance - fee;

        balancesDue[msg.sender] = 0;
        balancesDue[liquidationQueueMeta.feeCollector] += fee;

        uint256 assetId = liquidatedAssetId;
        yieldBox.transfer(
            address(this),
            to,
            assetId,
            yieldBox.toShare(assetId, redeemable, false)
        );

        emit Redeem(msg.sender, to, redeemable);
    }

    function _viewBidderDiscountedCollateralAmount(
        Bidder memory entry,
        uint256 exchangeRate,
        uint256 poolId
    ) private view returns (uint256) {
        uint256 bidAmount = entry.isUsdo
            ? entry.usdoAmount
            : entry.liquidatedAssetAmount;
        uint256 liquidatedAssetAmount = entry.swapOnExecute
            ? liquidationQueueMeta.bidExecutionSwapper.getOutputAmount(
                mixologist,
                beachBar.usdoAssetId(),
                entry.usdoAmount,
                ''
            )
            : bidAmount;
        return
            _getPremiumAmount(
                _bidToCollateral(liquidatedAssetAmount, exchangeRate),
                poolId,
                MODE.ADD
            );
    }

    function _useEntireBidAmount(
        Bidder memory entry,
        uint256 discountedBidderAmount,
        uint256 exchangeRate,
        uint256 poolId,
        bytes memory swapData
    )
        private
        returns (
            uint256 finalCollateralAmount,
            uint256 finalDiscountedCollateralAmount,
            uint256 finalUsdoAmount
        )
    {
        finalCollateralAmount = entry.liquidatedAssetAmount;
        finalDiscountedCollateralAmount = discountedBidderAmount;
        finalUsdoAmount = entry.usdoAmount;
        //Execute the swap if USD0 was provided and it's different from the liqudation asset id
        if (entry.swapOnExecute) {
            yieldBox.transfer(
                address(this),
                address(liquidationQueueMeta.bidExecutionSwapper),
                beachBar.usdoAssetId(),
                yieldBox.toShare(
                    beachBar.usdoAssetId(),
                    entry.usdoAmount,
                    false
                )
            );

            finalCollateralAmount = liquidationQueueMeta
                .bidExecutionSwapper
                .swap(
                    mixologist,
                    beachBar.usdoAssetId(),
                    entry.usdoAmount,
                    swapData
                );
            finalDiscountedCollateralAmount = _getPremiumAmount(
                _bidToCollateral(finalCollateralAmount, exchangeRate),
                poolId,
                MODE.ADD
            );
        }
    }

    function _userPartiallyBidAmount(
        Bidder memory entry,
        uint256 collateralAmountToLiquidate,
        uint256 exchangeRate,
        uint256 poolId,
        bytes memory swapData
    )
        private
        returns (
            uint256 finalDiscountedCollateralAmount,
            uint256 finalUsdoAmount
        )
    {
        finalUsdoAmount = 0;
        finalDiscountedCollateralAmount = _getPremiumAmount(
            _collateralToBid(collateralAmountToLiquidate, exchangeRate),
            poolId,
            MODE.SUB
        );

        //Execute the swap if USD0 was provided and it's different from the liqudation asset id
        uint256 usdoAssetId = beachBar.usdoAssetId();
        if (entry.swapOnExecute) {
            finalUsdoAmount = liquidationQueueMeta
                .bidExecutionSwapper
                .getInputAmount(
                    mixologist,
                    usdoAssetId,
                    finalDiscountedCollateralAmount,
                    ''
                );

            yieldBox.transfer(
                address(this),
                address(liquidationQueueMeta.bidExecutionSwapper),
                usdoAssetId,
                yieldBox.toShare(usdoAssetId, finalUsdoAmount, false)
            );
            uint256 returnedCollateral = liquidationQueueMeta
                .bidExecutionSwapper
                .swap(mixologist, usdoAssetId, finalUsdoAmount, swapData);
            require(
                returnedCollateral >= finalDiscountedCollateralAmount,
                'need-more-collateral'
            );
        }
    }

    struct BidExecutionData {
        uint256 curPoolId;
        bool isBidAvail;
        OrderBookPoolInfo poolInfo;
        OrderBookPoolEntry orderBookEntry;
        OrderBookPoolEntry orderBookEntryCopy;
        uint256 totalPoolAmountExecuted;
        uint256 totalPoolCollateralLiquidated;
        uint256 totalUsdoAmountUsed;
        uint256 exchangeRate;
        uint256 discountedBidderAmount;
    }

    /// @notice Execute the liquidation call by executing the bids placed in the pools in ASC order.
    /// @dev Should only be called from Mixologist.
    ///      Mixologist should send the `collateralAmountToLiquidate` to this contract before calling this function.
    /// Tx will fail if it can't transfer allowed BeachBar asset from Mixologist.
    /// @param collateralAmountToLiquidate The amount of collateral to liquidate.
    /// @param swapData Swap data necessary for swapping USD0 to market asset; necessary only if bidder added USD0
    /// @return totalAmountExecuted The amount of asset that was executed.
    /// @return totalCollateralLiquidated The amount of collateral that was liquidated.
    function executeBids(
        uint256 collateralAmountToLiquidate,
        bytes calldata swapData
    )
        external
        returns (uint256 totalAmountExecuted, uint256 totalCollateralLiquidated)
    {
        require(msg.sender == address(mixologist), 'LQ: Only Mixologist');
        BidExecutionData memory data;

        (data.curPoolId, data.isBidAvail) = getNextAvailBidPool();
        data.exchangeRate = mixologist.exchangeRate();
        // We loop through all the bids for each pools until all the collateral is liquidated
        // or no more bid are available.
        while (collateralAmountToLiquidate > 0 && data.isBidAvail) {
            data.poolInfo = orderBookInfos[data.curPoolId];
            // Reset pool vars.
            data.totalPoolAmountExecuted = 0;
            data.totalPoolCollateralLiquidated = 0;
            // While bid pool is not empty and we haven't liquidated enough collateral.
            while (
                collateralAmountToLiquidate > 0 &&
                data.poolInfo.nextBidPull != data.poolInfo.nextBidPush
            ) {
                // Get the next bid.
                data.orderBookEntry = orderBookEntries[data.curPoolId][
                    data.poolInfo.nextBidPull
                ];
                data.orderBookEntryCopy = data.orderBookEntry;

                // Get the total amount of asset with the pool discount applied for the bidder.
                data
                    .discountedBidderAmount = _viewBidderDiscountedCollateralAmount(
                    data.orderBookEntryCopy.bidInfo,
                    data.exchangeRate,
                    data.curPoolId
                );

                // Check if the bidder can pay the remaining collateral to liquidate `collateralAmountToLiquidate`.
                if (data.discountedBidderAmount > collateralAmountToLiquidate) {
                    (
                        uint256 finalDiscountedCollateralAmount,
                        uint256 finalUsdoAmount
                    ) = _userPartiallyBidAmount(
                            data.orderBookEntryCopy.bidInfo,
                            collateralAmountToLiquidate,
                            data.exchangeRate,
                            data.curPoolId,
                            swapData
                        );

                    // Execute the bid.
                    balancesDue[
                        data.orderBookEntryCopy.bidder
                    ] += collateralAmountToLiquidate; // Write balance.

                    if (!data.orderBookEntry.bidInfo.isUsdo) {
                        data
                            .orderBookEntry
                            .bidInfo
                            .liquidatedAssetAmount -= finalDiscountedCollateralAmount; // Update bid entry amount.
                    } else {
                        data
                            .orderBookEntry
                            .bidInfo
                            .usdoAmount -= finalUsdoAmount;
                    }

                    // Update the total amount executed, the total collateral liquidated and collateral to liquidate.
                    data
                        .totalPoolAmountExecuted += finalDiscountedCollateralAmount;
                    data
                        .totalPoolCollateralLiquidated += collateralAmountToLiquidate;
                    collateralAmountToLiquidate = 0; // Since we have liquidated all the collateral.
                    data.totalUsdoAmountUsed += finalUsdoAmount;
                } else {
                    (
                        uint256 finalCollateralAmount,
                        uint256 finalDiscountedCollateralAmount,
                        uint256 finalUsdoAmount
                    ) = _useEntireBidAmount(
                            data.orderBookEntryCopy.bidInfo,
                            data.discountedBidderAmount,
                            data.exchangeRate,
                            data.curPoolId,
                            swapData
                        );

                    // Execute the bid.
                    balancesDue[
                        data.orderBookEntryCopy.bidder
                    ] += finalDiscountedCollateralAmount; // Write balance.
                    data.orderBookEntry.bidInfo.usdoAmount = 0; // Update bid entry amount.
                    data.orderBookEntry.bidInfo.liquidatedAssetAmount = 0; // Update bid entry amount.
                    // Update the total amount executed, the total collateral liquidated and collateral to liquidate.
                    data.totalUsdoAmountUsed += finalUsdoAmount;
                    data.totalPoolAmountExecuted += finalCollateralAmount;
                    data
                        .totalPoolCollateralLiquidated += finalDiscountedCollateralAmount;

                    collateralAmountToLiquidate -= finalDiscountedCollateralAmount;

                    // Since the current bid was fulfilled, get the next one.
                    unchecked {
                        ++data.poolInfo.nextBidPull;
                    }
                }
            }
            // Update the totals.
            totalAmountExecuted += data.totalPoolAmountExecuted;
            totalCollateralLiquidated += data.totalPoolCollateralLiquidated;
            orderBookInfos[data.curPoolId] = data.poolInfo; // Update the pool info for the current pool.
            // Look up for the next available bid pool.
            (data.curPoolId, data.isBidAvail) = getNextAvailBidPool();

            emit ExecuteBids(
                msg.sender,
                data.curPoolId,
                data.totalUsdoAmountUsed,
                data.totalPoolAmountExecuted,
                data.totalPoolCollateralLiquidated,
                block.timestamp
            );
        }
        // Stack too deep
        {
            uint256 toSend = totalAmountExecuted;

            // Transfer the assets to the Mixologist.
            yieldBox.withdraw(
                lqAssetId,
                address(this),
                address(this),
                toSend,
                0
            );
            yieldBox.depositAsset(
                marketAssetId,
                address(this),
                address(mixologist),
                toSend,
                0
            );
        }
    }

    /// @notice updates the bid swapper address
    /// @param _swapper thew new ICollateralSwaper contract address
    function setBidExecutionSwapper(IBidder _swapper) external {
        require(msg.sender == address(mixologist), 'unauthorized');
        emit BidSwapperUpdated(
            liquidationQueueMeta.bidExecutionSwapper,
            _swapper
        );
        liquidationQueueMeta.bidExecutionSwapper = _swapper;
        // yieldBox.setApprovalForAll(address(_swapper), true);
    }

    /// @notice updates the bid swapper address
    /// @param _swapper thew new ICollateralSwaper contract address
    function setUsdoSwapper(IBidder _swapper) external {
        require(msg.sender == address(mixologist), 'unauthorized');
        emit UsdoSwapperUpdated(liquidationQueueMeta.usdoSwapper, _swapper);
        liquidationQueueMeta.usdoSwapper = _swapper;
        // yieldBox.setApprovalForAll(address(_swapper), true);
    }

    // ************* //
    // *** VIEWS *** //
    // ************* //

    /// @notice Get the next not empty bid pool in ASC order.
    /// @return i The bid pool id.
    /// @return available True if there is at least 1 bid available across all the order books.
    function getNextAvailBidPool()
        public
        view
        returns (uint256 i, bool available)
    {
        for (; i <= MAX_BID_POOLS; ) {
            if (getOrderBookSize(i) != 0) {
                available = true;
                break;
            }
            ++i;
        }
    }

    function userBidIndexLength(address user, uint256 pool)
        external
        view
        returns (uint256 len)
    {
        uint256[] memory bidIndexes = userBidIndexes[user][pool];

        uint256 bidIndexesLen = bidIndexes.length;
        OrderBookPoolInfo memory poolInfo = orderBookInfos[pool];
        for (uint256 i = 0; i < bidIndexesLen; ) {
            if (bidIndexes[i] >= poolInfo.nextBidPull) {
                bidIndexesLen--;
            }
            unchecked {
                ++i;
            }
        }

        return bidIndexes.length;
    }

    // **************** //
    // *** INTERNAL *** //
    // **************** //

    function _bid(
        address user,
        uint256 pool,
        uint256 amount,
        bool isUsdo
    ) internal returns (Bidder memory bidder) {
        bidder.usdoAmount = isUsdo ? amount : 0;
        bidder.liquidatedAssetAmount = isUsdo ? 0 : amount;
        bidder.timestamp = block.timestamp;
        bidder.isUsdo = isUsdo;
        bidder.swapOnExecute = isUsdo && lqAssetId != beachBar.usdoAssetId();

        bidPools[pool][user] = bidder;

        emit Bid(
            msg.sender,
            user,
            pool,
            isUsdo ? amount : 0, //USD0 amount
            isUsdo ? 0 : amount, //liquidated asset amount
            block.timestamp
        );

        // Clean the userBidIndex.
        uint256[] storage bidIndexes = userBidIndexes[user][pool];
        uint256 bidIndexesLen = bidIndexes.length;
        OrderBookPoolInfo memory poolInfo = orderBookInfos[pool];
        for (uint256 i = 0; i < bidIndexesLen; ) {
            if (bidIndexes[i] >= poolInfo.nextBidPull) {
                bidIndexesLen = bidIndexes.length;
                bidIndexes[i] = bidIndexes[bidIndexesLen - 1];
                bidIndexes.pop();
            }
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Create an asset inside of BeachBar that will hold the funds.
    function _registerAsset() internal returns (uint256) {
        (, address contractAddress, , ) = yieldBox.assets(marketAssetId);
        return
            yieldBox.registerAsset(
                TokenType.ERC20,
                contractAddress,
                IStrategy(address(0)),
                0
            );
    }

    /// @notice Called with `init`, setup the initial pool info values.
    /// @param pool The targeted pool.
    function _initOrderBookPoolInfo(uint256 pool) internal {
        OrderBookPoolInfo memory poolInfo;
        poolInfo.poolId = uint32(pool);
        orderBookInfos[pool] = poolInfo;
    }

    /// @notice Get the discount gained from a bid in a `poolId` given a `amount`.
    /// @param amount The amount of collateral to get the discount from.
    /// @param poolId The targeted pool.
    /// @param mode 0 subtract - 1 add.
    function _getPremiumAmount(
        uint256 amount,
        uint256 poolId,
        MODE mode
    ) internal pure returns (uint256) {
        uint256 premium = (amount * poolId * PREMIUM_FACTOR) /
            PREMIUM_FACTOR_PRECISION;
        return mode == MODE.ADD ? amount + premium : amount - premium;
    }

    /// @notice Convert a bid amount to a collateral amount.
    /// @param amount The amount of bid to convert.
    /// @param exchangeRate The exchange rate to use.
    function _bidToCollateral(uint256 amount, uint256 exchangeRate)
        internal
        pure
        returns (uint256)
    {
        return (amount * exchangeRate) / EXCHANGE_RATE_PRECISION;
    }

    /// @notice Convert a collateral amount to a bid amount.
    /// @param collateralAmount The amount of collateral to convert.
    /// @param exchangeRate The exchange rate to use.
    function _collateralToBid(uint256 collateralAmount, uint256 exchangeRate)
        internal
        pure
        returns (uint256)
    {
        return (collateralAmount * EXCHANGE_RATE_PRECISION) / exchangeRate;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import './MXCommon.sol';
import './MXLiquidation.sol';
import './MXLendingBorrowing.sol';

// solhint-disable max-line-length

contract Mixologist is MXCommon {
    using RebaseLibrary for Rebase;

    enum Module {
        Base,
        LendingBorrowing,
        Liquidation
    }
    MXLiquidation liquidationModule;
    MXLendingBorrowing lendingBorrowingModule;

    /// @notice Allows batched call to Mixologist.
    /// @param calls An array encoded call data.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    function execute(bytes[] calldata calls, bool revertOnFail)
        external
        returns (bool[] memory successes, string[] memory results)
    {
        successes = new bool[](calls.length);
        results = new string[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(
                calls[i]
            );
            require(success || !revertOnFail, _getRevertMsg(result));
            successes[i] = success;
            results[i] = _getRevertMsg(result);
        }
    }

    function _getRevertMsg(bytes memory _returnData)
        private
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Mx: no return data';
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function _executeModule(Module _module, bytes memory _data)
        private
        returns (bytes memory returnData)
    {
        address module;
        bool success = true;

        if (_module == Module.LendingBorrowing) {
            module = address(lendingBorrowingModule);
        } else if (_module == Module.Liquidation) {
            module = address(liquidationModule);
        }

        if (module == address(0)) {
            revert('Mx: module not set');
        }

        (success, returnData) = module.delegatecall(_data);
        if (!success) {
            revert(_getRevertMsg(returnData));
        }
    }

    function _executeViewModule(Module _module, bytes memory _data)
        private
        view
        returns (bytes memory returnData)
    {
        address module;
        bool success = true;

        if (_module == Module.LendingBorrowing) {
            module = address(lendingBorrowingModule);
        } else if (_module == Module.Liquidation) {
            module = address(liquidationModule);
        }

        if (module == address(0)) {
            revert('Mx: module not set');
        }

        (success, returnData) = module.staticcall(_data);
        if (!success) {
            revert(_getRevertMsg(returnData));
        }
    }

    /**
     * @notice Sets approval status for an `operator` to manage user account.
     * @param operator Address of Operator.
     * @param approved Status of approval.
     */
    function setApprovalForAll(address operator, bool approved) external {
        // Effects
        isApprovedForAll[msg.sender][operator] = approved;

        emit LogApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice The init function that acts as a constructor
    function init(bytes calldata data) external onlyOnce {
        (
            address _liquidationModule,
            address _lendingBorrowingModule,
            BeachBar tapiocaBar_,
            IERC20 _asset,
            uint256 _assetId,
            IERC20 _collateral,
            uint256 _collateralId,
            IOracle _oracle,
            address[] memory _collateralSwapPath,
            address[] memory _tapSwapPath
        ) = abi.decode(
                data,
                (
                    address,
                    address,
                    BeachBar,
                    IERC20,
                    uint256,
                    IERC20,
                    uint256,
                    IOracle,
                    address[],
                    address[]
                )
            );

        liquidationModule = MXLiquidation(_liquidationModule);
        lendingBorrowingModule = MXLendingBorrowing(_lendingBorrowingModule);
        beachBar = tapiocaBar_;
        yieldBox = tapiocaBar_.yieldBox();
        owner = address(beachBar);

        require(
            address(_collateral) != address(0) &&
                address(_asset) != address(0) &&
                address(_oracle) != address(0),
            'Mx: bad pair'
        );
        asset = _asset;
        collateral = _collateral;
        assetId = _assetId;
        collateralId = _collateralId;
        oracle = _oracle;
        collateralSwapPath = _collateralSwapPath;
        tapSwapPath = _tapSwapPath;

        accrueInfo.interestPerSecond = uint64(STARTING_INTEREST_PER_SECOND); // 1% APR, with 1e18 being 100%

        updateExchangeRate();
    }

    /// @notice Return the amount of collateral for a `user` to be solvent. Returns 0 if user already solvent.
    /// @dev We use a `CLOSED_COLLATERIZATION_RATE` that is a safety buffer when making the user solvent again,
    ///      To prevent from being liquidated. This function is valid only if user is not solvent by `_isSolvent()`.
    /// @param user The user to check solvency.
    /// @param _exchangeRate The exchange rate asset/collateral.
    /// @return amountToSolvency The amount of collateral to be solvent.
    function computeAssetAmountToSolvency(address user, uint256 _exchangeRate)
        public
        view
        returns (uint256 amountToSolvency)
    {
        bytes memory result = _executeViewModule(
            Module.Liquidation,
            abi.encodeWithSelector(
                MXLiquidation.computeAssetAmountToSolvency.selector,
                user,
                _exchangeRate
            )
        );
        amountToSolvency = abi.decode(result, (uint256));
    }

    /// @notice Calculate the collateral amount off the shares.
    /// @param share The shares.
    /// @return amount The amount.
    function getCollateralAmountForShare(uint256 share)
        public
        view
        returns (uint256 amount)
    {
        return _getCollateralAmountForShare(share);
    }

    /// @notice Calculate the collateral shares that are needed for `borrowPart`,
    /// taking the current exchange rate into account.
    /// @param borrowPart The borrow part.
    /// @return collateralShares The collateral shares.
    function getCollateralSharesForBorrowPart(uint256 borrowPart)
        public
        view
        returns (uint256 collateralShares)
    {
        return _getCollateralSharesForBorrowPart(borrowPart);
    }

    /// @notice Compute the amount of `mixologist.assetId` from `fraction`
    /// `fraction` can be `mixologist.accrueInfo.feeFraction` or `mixologist.balanceOf`
    /// @param fraction The fraction.
    /// @return amount The amount.
    function getAmountForAssetFraction(uint256 fraction)
        public
        view
        returns (uint256 amount)
    {
        return _getAmountForAssetFraction(fraction);
    }

    /// @notice Return the equivalent of borrow part in asset amount.
    /// @param borrowPart The amount of borrow part to convert.
    /// @return amount The equivalent of borrow part in asset amount.
    function getAmountForBorrowPart(uint256 borrowPart)
        public
        view
        returns (uint256 amount)
    {
        return _getAmountForBorrowPart(borrowPart);
    }

    /// @notice Adds `collateral` from msg.sender to the account `to`.
    /// @param from Account to transfer shares from.
    /// @param to The receiver of the tokens.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    /// @param share The amount of shares to add for `to`.
    function addCollateral(
        address from,
        address to,
        bool skim,
        uint256 share
    ) public {
        _executeModule(
            Module.LendingBorrowing,
            abi.encodeWithSelector(
                MXLendingBorrowing.addCollateral.selector,
                from,
                to,
                skim,
                share
            )
        );
    }

    /// @notice Removes `share` amount of collateral and transfers it to `to`.
    /// @param from Account to debit collateral from.
    /// @param to The receiver of the shares.
    /// @param share Amount of shares to remove.
    function removeCollateral(
        address from,
        address to,
        uint256 share
    ) public {
        _executeModule(
            Module.LendingBorrowing,
            abi.encodeWithSelector(
                MXLendingBorrowing.removeCollateral.selector,
                from,
                to,
                share
            )
        );
    }

    /// @notice Sender borrows `amount` and transfers it to `to`.
    /// @param from Account to borrow for.
    /// @param to The receiver of borrowed tokens.
    /// @param amount Amount to borrow.
    /// @return part Total part of the debt held by borrowers.
    /// @return share Total amount in shares borrowed.
    function borrow(
        address from,
        address to,
        uint256 amount
    ) public returns (uint256 part, uint256 share) {
        bytes memory result = _executeModule(
            Module.LendingBorrowing,
            abi.encodeWithSelector(
                MXLendingBorrowing.borrow.selector,
                from,
                to,
                amount
            )
        );
        (part, share) = abi.decode(result, (uint256, uint256));
    }

    /// @notice Repays a loan.
    /// @param from Address to repay from.
    /// @param to Address of the user this payment should go.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    /// @param part The amount to repay. See `userBorrowPart`.
    /// @return amount The total amount repayed.
    function repay(
        address from,
        address to,
        bool skim,
        uint256 part
    ) public returns (uint256 amount) {
        bytes memory result = _executeModule(
            Module.LendingBorrowing,
            abi.encodeWithSelector(
                MXLendingBorrowing.repay.selector,
                from,
                to,
                skim,
                part
            )
        );
        amount = abi.decode(result, (uint256));
    }

    /// @notice Entry point for liquidations.
    /// @dev Will call `closedLiquidation()` if not LQ exists or no LQ bid avail exists. Otherwise use LQ.
    /// @param users An array of user addresses.
    /// @param maxBorrowParts A one-to-one mapping to `users`, contains maximum (partial) borrow amounts (to liquidate) of the respective user.
    ///        Ignore for `orderBookLiquidation()`
    /// @param swapper Contract address of the `MultiSwapper` implementation. See `setSwapper`.
    ///        Ignore for `orderBookLiquidation()`
    /// @param collateralToAssetSwapData Extra swap data
    ///        Ignore for `orderBookLiquidation()`
    /// @param usdoToBorrowedSwapData Extra swap data
    ///        Ignore for `closedLiquidation()`
    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        MultiSwapper swapper,
        bytes calldata collateralToAssetSwapData,
        bytes calldata usdoToBorrowedSwapData
    ) external {
        _executeModule(
            Module.Liquidation,
            abi.encodeWithSelector(
                MXLiquidation.liquidate.selector,
                users,
                maxBorrowParts,
                swapper,
                collateralToAssetSwapData,
                usdoToBorrowedSwapData
            )
        );
    }

    /// @notice Flashloan ability.
    /// @dev The contract expect the `borrower` to have at the end of `onFlashLoan` `amount` + the incurred fees.
    /// The borrower is expected to `approve()` yieldBox for this number at the end of its `onFlashLoan()`.
    /// @param borrower The address of the contract that implements and conforms to `IFlashBorrower` and handles the flashloan.
    /// @param receiver Address of the token receiver.
    /// @param amount of the tokens to receive.
    /// @param data The calldata to pass to the `borrower` contract.
    function flashLoan(
        IFlashBorrower borrower,
        address receiver,
        uint256 amount,
        bytes memory data
    ) public {
        _executeModule(
            Module.LendingBorrowing,
            abi.encodeWithSelector(
                MXLendingBorrowing.flashLoan.selector,
                borrower,
                receiver,
                amount,
                data
            )
        );
    }

    /// @notice Withdraw the fees accumulated in `accrueInfo.feesEarnedFraction` to the balance of `feeTo`.
    function withdrawFeesEarned() public {
        accrue();
        address _feeTo = beachBar.feeTo();
        uint256 _feesEarnedFraction = accrueInfo.feesEarnedFraction;
        balanceOf[_feeTo] += _feesEarnedFraction;
        emit Transfer(address(0), _feeTo, _feesEarnedFraction);
        accrueInfo.feesEarnedFraction = 0;
        emit LogWithdrawFees(_feeTo, _feesEarnedFraction);
    }

    /// @notice Withdraw the balance of `feeTo`, swap asset into TAP and deposit it to yieldBox of `feeTo`
    function depositFeesToYieldBox(
        MultiSwapper swapper,
        SwapData calldata swapData
    ) public {
        if (accrueInfo.feesEarnedFraction > 0) {
            withdrawFeesEarned();
        }
        require(beachBar.swappers(swapper), 'Mx: Invalid swapper');
        address _feeTo = beachBar.feeTo();
        address _feeVeTap = beachBar.feeVeTap();

        uint256 feeShares = _removeAsset(
            _feeTo,
            address(this),
            balanceOf[_feeTo]
        );

        yieldBox.transfer(address(this), address(swapper), assetId, feeShares);

        (uint256 tapAmount, ) = swapper.swap(
            assetId,
            beachBar.tapAssetId(),
            swapData.minAssetAmount,
            _feeVeTap,
            tapSwapPath,
            feeShares
        );

        emit LogYieldBoxFeesDeposit(feeShares, tapAmount);
    }

    /// @notice Used to set the swap path of closed liquidations
    /// @param _collateralSwapPath The Uniswap path .
    function setCollateralSwapPath(address[] calldata _collateralSwapPath)
        public
        onlyOwner
    {
        collateralSwapPath = _collateralSwapPath;
    }

    /// @notice Used to set the swap path of Asset -> TAP
    /// @param _tapSwapPath The Uniswap path .
    function setTapSwapPath(address[] calldata _tapSwapPath) public onlyOwner {
        tapSwapPath = _tapSwapPath;
    }

    /// @notice Set a new LiquidationQueue.
    /// @param _liquidationQueue The address of the new LiquidationQueue contract.
    /// It should be a new contract as `init()` can be called only one time.
    /// @param _liquidationQueueMeta The liquidation queue info.
    function setLiquidationQueue(
        ILiquidationQueue _liquidationQueue,
        LiquidationQueueMeta calldata _liquidationQueueMeta
    ) public onlyOwner {
        _liquidationQueue.init(_liquidationQueueMeta);
        liquidationQueue = _liquidationQueue;
    }

    /// @notice Execute an only owner function inside of the LiquidationQueue
    function updateLQExecutionSwapper(address _swapper) external onlyOwner {
        liquidationQueue.setBidExecutionSwapper(_swapper);
    }

    /// @notice Execute an only owner function inside of the LiquidationQueue
    function updateLQUsdoSwapper(address _swapper) external onlyOwner {
        liquidationQueue.setUsdoSwapper(_swapper);
    }

    /// @notice sets max borrowable amount
    function setBorrowCap(uint256 _cap) external onlyOwner {
        emit LogBorrowCapUpdated(totalBorrowCap, _cap);
        totalBorrowCap = _cap;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './bidders/IBidder.sol';

struct Bidder {
    bool isUsdo;
    bool swapOnExecute;
    uint256 usdoAmount;
    uint256 liquidatedAssetAmount;
    uint256 timestamp; // Timestamp in second of the last bid.
}

struct OrderBookPoolEntry {
    address bidder;
    Bidder bidInfo;
}

struct OrderBookPoolInfo {
    uint32 poolId;
    uint32 nextBidPull; // Next position in `entries` to start pulling bids from
    uint32 nextBidPush; // Next position in `entries` to start pushing bids to
}

struct LiquidationQueueMeta {
    uint256 activationTime; // Time needed before a bid can be activated for execution
    uint256 minBidAmount; // Minimum bid amount
    address feeCollector; // Address of the fee collector
    IBidder bidExecutionSwapper; //Allows swapping USD0 to collateral when a bid is executed
    IBidder usdoSwapper; //Allows swapping any other stablecoin to USD0
}

interface ILiquidationQueue {
    function init(LiquidationQueueMeta calldata) external;

    function setBidExecutionSwapper(address swapper) external;

    function setUsdoSwapper(address swapper) external;

    function getNextAvailBidPool()
        external
        view
        returns (uint256 i, bool available);

    function executeBids(
        uint256 collateralAmountToLiquidate,
        bytes calldata swapData
    ) external returns (uint256 amountExecuted, uint256 collateralLiquidated);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Simplified by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IERC20.sol";
import "./Domain.sol";

// solhint-disable no-inline-assembly
// solhint-disable not-rely-on-time

// Data part taken out for building of contracts that receive delegate calls
contract ERC20Data {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;
}

abstract contract ERC20 is IERC20, Domain {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public override balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public override allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;

    /// @notice Transfers `amount` tokens from `msg.sender` to `to`.
    /// @param to The address to move the tokens.
    /// @param amount of the tokens to move.
    /// @return (bool) Returns True if succeeded.
    function transfer(address to, uint256 amount) public returns (bool) {
        // If `amount` is 0, or `msg.sender` is `to` nothing happens
        if (amount != 0 || msg.sender == to) {
            uint256 srcBalance = balanceOf[msg.sender];
            require(srcBalance >= amount, "ERC20: balance too low");
            if (msg.sender != to) {
                require(to != address(0), "ERC20: no zero address"); // Moved down so low balance calls safe some gas

                balanceOf[msg.sender] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfers `amount` tokens from `from` to `to`. Caller needs approval for `from`.
    /// @param from Address to draw tokens from.
    /// @param to The address to move the tokens.
    /// @param amount The token amount to move.
    /// @return (bool) Returns True if succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        // If `amount` is 0, or `from` is `to` nothing happens
        if (amount != 0) {
            uint256 srcBalance = balanceOf[from];
            require(srcBalance >= amount, "ERC20: balance too low");

            if (from != to) {
                uint256 spenderAllowance = allowance[from][msg.sender];
                // If allowance is infinite, don't decrease it to save on gas (breaks with EIP-20).
                if (spenderAllowance != type(uint256).max) {
                    require(spenderAllowance >= amount, "ERC20: allowance too low");
                    allowance[from][msg.sender] = spenderAllowance - amount; // Underflow is checked
                }
                require(to != address(0), "ERC20: no zero address"); // Moved down so other failed calls safe some gas

                balanceOf[from] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Approves `amount` from sender to be spend by `spender`.
    /// @param spender Address of the party that can draw from msg.sender's account.
    /// @param amount The maximum collective amount that `spender` can draw.
    /// @return (bool) Returns True if approved.
    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Approves `value` from `owner_` to be spend by `spender`.
    /// @param owner_ Address of the owner.
    /// @param spender The address of the spender that gets approved to draw from `owner_`.
    /// @param value The maximum collective amount that `spender` can draw.
    /// @param deadline This permit must be redeemed before this deadline (UTC timestamp in seconds).
    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner_ != address(0), "ERC20: Owner cannot be 0");
        require(block.timestamp < deadline, "ERC20: Expired");
        require(
            ecrecover(_getDigest(keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owner_, spender, value, nonces[owner_]++, deadline))), v, r, s) ==
                owner_,
            "ERC20: Invalid Signature"
        );
        allowance[owner_][spender] = value;
        emit Approval(owner_, spender, value);
    }
}

contract ERC20WithSupply is IERC20, ERC20 {
    uint256 public override totalSupply;

    function _mint(address user, uint256 amount) internal {
        uint256 newTotalSupply = totalSupply + amount;
        require(newTotalSupply >= totalSupply, "Mint overflow");
        totalSupply = newTotalSupply;
        balanceOf[user] += amount;
        emit Transfer(address(0), user, amount);
    }

    function _burn(address user, uint256 amount) internal {
        require(balanceOf[user] >= amount, "Burn too much");
        totalSupply -= amount;
        balanceOf[user] -= amount;
        emit Transfer(user, address(0), amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './MXCommon.sol';

// solhint-disable max-line-length

contract MXLiquidation is MXCommon {
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    // ************** //
    // *** PUBLIC *** //
    // ************** //

    /// @notice Return the amount of collateral for a `user` to be solvent. Returns 0 if user already solvent.
    /// @dev We use a `CLOSED_COLLATERIZATION_RATE` that is a safety buffer when making the user solvent again,
    ///      To prevent from being liquidated. This function is valid only if user is not solvent by `_isSolvent()`.
    /// @param user The user to check solvency.
    /// @param _exchangeRate The exchange rate asset/collateral.
    /// @return The amount of collateral to be solvent.
    function computeAssetAmountToSolvency(address user, uint256 _exchangeRate)
        public
        view
        returns (uint256)
    {
        // accrue must have already been called!
        uint256 borrowPart = userBorrowPart[user];
        if (borrowPart == 0) return 0;
        uint256 collateralShare = userCollateralShare[user];

        Rebase memory _totalBorrow = totalBorrow;

        uint256 collateralAmountInAsset = yieldBox.toAmount(
            collateralId,
            (collateralShare *
                (EXCHANGE_RATE_PRECISION / COLLATERIZATION_RATE_PRECISION) *
                LQ_COLLATERIZATION_RATE),
            false
        ) / _exchangeRate;
        // Obviously it's not `borrowPart` anymore but `borrowAmount`
        borrowPart = (borrowPart * _totalBorrow.elastic) / _totalBorrow.base;

        return
            borrowPart >= collateralAmountInAsset
                ? borrowPart - collateralAmountInAsset
                : 0;
    }

    /// @notice Entry point for liquidations.
    /// @dev Will call `closedLiquidation()` if not LQ exists or no LQ bid avail exists. Otherwise use LQ.
    /// @param users An array of user addresses.
    /// @param maxBorrowParts A one-to-one mapping to `users`, contains maximum (partial) borrow amounts (to liquidate) of the respective user.
    ///        Ignore for `orderBookLiquidation()`
    /// @param swapper Contract address of the `MultiSwapper` implementation. See `setSwapper`.
    ///        Ignore for `orderBookLiquidation()`
    /// @param collateralToAssetSwapData Extra swap data
    ///        Ignore for `orderBookLiquidation()`
    /// @param usdoToBorrowedSwapData Extra swap data
    ///        Ignore for `closedLiquidation()`
    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        MultiSwapper swapper,
        bytes calldata collateralToAssetSwapData,
        bytes calldata usdoToBorrowedSwapData
    ) external {
        // Oracle can fail but we still need to allow liquidations
        (, uint256 _exchangeRate) = updateExchangeRate();
        accrue();

        if (address(liquidationQueue) != address(0)) {
            (, bool bidAvail) = liquidationQueue.getNextAvailBidPool();
            if (bidAvail) {
                _orderBookLiquidation(
                    users,
                    _exchangeRate,
                    usdoToBorrowedSwapData
                );
                return;
            }
        }
        _closedLiquidation(
            users,
            maxBorrowParts,
            swapper,
            _exchangeRate,
            collateralToAssetSwapData
        );
    }

    // *************** //
    // *** PRIVATE *** //
    // *************** //
    function _orderBookLiquidation(
        address[] calldata users,
        uint256 _exchangeRate,
        bytes memory swapData
    ) private {
        uint256 allCollateralShare;
        uint256 allBorrowAmount;
        uint256 allBorrowPart;
        Rebase memory _totalBorrow = totalBorrow;

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (!_isSolvent(user, _exchangeRate)) {
                uint256 borrowAmount = computeAssetAmountToSolvency(
                    user,
                    _exchangeRate
                );
                if (borrowAmount == 0) {
                    continue;
                }

                uint256 borrowPart;
                {
                    uint256 availableBorrowPart = userBorrowPart[user];
                    borrowPart = _totalBorrow.toBase(borrowAmount, false);
                    userBorrowPart[user] = availableBorrowPart - borrowPart;
                }
                uint256 collateralShare = yieldBox.toShare(
                    collateralId,
                    (borrowAmount * _exchangeRate * LIQUIDATION_MULTIPLIER) /
                        (EXCHANGE_RATE_PRECISION *
                            LIQUIDATION_MULTIPLIER_PRECISION),
                    false
                );
                userCollateralShare[user] -= collateralShare;
                emit LogRemoveCollateral(
                    user,
                    address(liquidationQueue),
                    collateralShare
                );
                emit LogRepay(
                    address(liquidationQueue),
                    user,
                    borrowAmount,
                    borrowPart
                );

                // Keep totals
                allCollateralShare += collateralShare;
                allBorrowAmount += borrowAmount;
                allBorrowPart += borrowPart;
            }
        }
        require(allBorrowAmount != 0, 'Mx: solvent');

        _totalBorrow.elastic -= uint128(allBorrowAmount);
        _totalBorrow.base -= uint128(allBorrowPart);
        totalBorrow = _totalBorrow;
        totalCollateralShare -= allCollateralShare;

        uint256 allBorrowShare = yieldBox.toShare(
            assetId,
            allBorrowAmount,
            true
        );

        // Transfer collateral to be liquidated
        yieldBox.transfer(
            address(this),
            address(liquidationQueue),
            collateralId,
            allCollateralShare
        );

        // LiquidationQueue pay debt
        liquidationQueue.executeBids(
            yieldBox.toAmount(collateralId, allCollateralShare, true),
            swapData
        );

        uint256 returnedShare = yieldBox.balanceOf(address(this), assetId) -
            uint256(totalAsset.elastic);
        uint256 extraShare = returnedShare - allBorrowShare;
        uint256 callerShare = (extraShare * CALLER_FEE) / CALLER_FEE_DIVISOR; // 1% goes to caller

        yieldBox.transfer(address(this), msg.sender, assetId, callerShare);

        totalAsset.elastic += uint128(returnedShare - callerShare);
        emit LogAddAsset(
            address(liquidationQueue),
            address(this),
            returnedShare - callerShare,
            0
        );
    }

    /// @notice Handles the liquidation of users' balances, once the users' amount of collateral is too low.
    /// @dev Closed liquidations Only, 90% of extra shares goes to caller and 10% to protocol
    /// @param users An array of user addresses.
    /// @param maxBorrowParts A one-to-one mapping to `users`, contains maximum (partial) borrow amounts (to liquidate) of the respective user.
    /// @param swapper Contract address of the `MultiSwapper` implementation. See `setSwapper`.
    /// @param swapData Swap necessar data
    function _closedLiquidation(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        MultiSwapper swapper,
        uint256 _exchangeRate,
        bytes calldata swapData
    ) private {
        uint256 allCollateralShare;
        uint256 allBorrowAmount;
        uint256 allBorrowPart;
        Rebase memory _totalBorrow = totalBorrow;
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (!_isSolvent(user, _exchangeRate)) {
                uint256 borrowPart;
                {
                    uint256 availableBorrowPart = userBorrowPart[user];
                    borrowPart = maxBorrowParts[i] > availableBorrowPart
                        ? availableBorrowPart
                        : maxBorrowParts[i];
                    userBorrowPart[user] = availableBorrowPart - borrowPart;
                }
                uint256 borrowAmount = _totalBorrow.toElastic(
                    borrowPart,
                    false
                );
                uint256 collateralShare = yieldBox.toShare(
                    collateralId,
                    (borrowAmount * LIQUIDATION_MULTIPLIER * _exchangeRate) /
                        (LIQUIDATION_MULTIPLIER_PRECISION *
                            EXCHANGE_RATE_PRECISION),
                    false
                );
                userCollateralShare[user] -= collateralShare;
                emit LogRemoveCollateral(
                    user,
                    address(swapper),
                    collateralShare
                );
                emit LogRepay(address(swapper), user, borrowAmount, borrowPart);

                // Keep totals
                allCollateralShare += collateralShare;
                allBorrowAmount += borrowAmount;
                allBorrowPart += borrowPart;
            }
        }
        require(allBorrowAmount != 0, 'Mx: solvent');
        _totalBorrow.elastic -= uint128(allBorrowAmount);
        _totalBorrow.base -= uint128(allBorrowPart);
        totalBorrow = _totalBorrow;
        totalCollateralShare -= allCollateralShare;

        uint256 allBorrowShare = yieldBox.toShare(
            assetId,
            allBorrowAmount,
            true
        );

        // Closed liquidation using a pre-approved swapper
        require(beachBar.swappers(swapper), 'Mx: Invalid swapper');

        // Swaps the users collateral for the borrowed asset
        yieldBox.transfer(
            address(this),
            address(swapper),
            collateralId,
            allCollateralShare
        );

        uint256 minAssetMount = 0;
        if (swapData.length > 0) {
            minAssetMount = abi.decode(swapData, (uint256));
        }
        swapper.swap(
            collateralId,
            assetId,
            minAssetMount,
            address(this),
            collateralSwapPath,
            allCollateralShare
        );

        uint256 returnedShare = yieldBox.balanceOf(address(this), assetId) -
            uint256(totalAsset.elastic);
        uint256 extraShare = returnedShare - allBorrowShare;
        uint256 feeShare = (extraShare * PROTOCOL_FEE) / PROTOCOL_FEE_DIVISOR; // 10% of profit goes to fee.
        uint256 callerShare = (extraShare * CALLER_FEE) / CALLER_FEE_DIVISOR; //  1%  of profit goes to caller.

        yieldBox.transfer(address(this), beachBar.feeTo(), assetId, feeShare);
        yieldBox.transfer(address(this), msg.sender, assetId, callerShare);

        totalAsset.elastic += uint128(returnedShare - feeShare - callerShare);
        emit LogAddAsset(
            address(swapper),
            address(this),
            extraShare - feeShare - callerShare,
            0
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './MXStorage.sol';

contract MXCommon is MXStorage {
    using RebaseLibrary for Rebase;

    /// Modifier to check if the msg.sender is allowed to use funds belonging to the 'from' address.
    /// If 'from' is msg.sender, it's allowed.
    /// If 'msg.sender' is an address (an operator) that is approved by 'from', it's allowed.
    modifier allowed(address from) virtual {
        if (from != msg.sender && !isApprovedForAll[from][msg.sender]) {
            revert NotApproved(from, msg.sender);
        }
        _;
    }

    /// @dev Checks if the user is solvent in the closed liquidation case at the end of the function body.
    modifier solvent(address from) {
        _;
        require(_isSolvent(from, exchangeRate), 'Mx: insolvent');
    }

    bool private initialized;
    modifier onlyOnce() {
        require(!initialized, 'Mx: initialized');
        _;
        initialized = true;
    }

    // ************** //
    // *** PUBLIC *** //
    // ************** //
    /// @notice Gets the exchange rate. I.e how much collateral to buy 1e18 asset.
    /// This function is supposed to be invoked if needed because Oracle queries can be expensive.
    /// @return updated True if `exchangeRate` was updated.
    /// @return rate The new exchange rate.
    function updateExchangeRate() public returns (bool updated, uint256 rate) {
        (updated, rate) = oracle.get(oracleData);

        if (updated) {
            exchangeRate = rate;
            emit LogExchangeRate(rate);
        } else {
            // Return the old rate if fetching wasn't successful
            rate = exchangeRate;
        }
    }

    /// @notice Accrues the interest on the borrowed tokens and handles the accumulation of fees.
    function accrue() public {
        AccrueInfo memory _accrueInfo = accrueInfo;
        // Number of seconds since accrue was called
        uint256 elapsedTime = block.timestamp - _accrueInfo.lastAccrued;
        if (elapsedTime == 0) {
            return;
        }
        _accrueInfo.lastAccrued = uint64(block.timestamp);

        Rebase memory _totalBorrow = totalBorrow;
        if (_totalBorrow.base == 0) {
            // If there are no borrows, reset the interest rate
            if (_accrueInfo.interestPerSecond != STARTING_INTEREST_PER_SECOND) {
                _accrueInfo.interestPerSecond = STARTING_INTEREST_PER_SECOND;
                emit LogAccrue(0, 0, STARTING_INTEREST_PER_SECOND, 0);
            }
            accrueInfo = _accrueInfo;
            return;
        }

        uint256 extraAmount = 0;
        uint256 feeFraction = 0;
        Rebase memory _totalAsset = totalAsset;

        // Accrue interest
        extraAmount =
            (uint256(_totalBorrow.elastic) *
                _accrueInfo.interestPerSecond *
                elapsedTime) /
            1e18;
        _totalBorrow.elastic += uint128(extraAmount);
        uint256 fullAssetAmount = yieldBox.toAmount(
            assetId,
            _totalAsset.elastic,
            false
        ) + _totalBorrow.elastic;

        uint256 feeAmount = (extraAmount * PROTOCOL_FEE) / PROTOCOL_FEE_DIVISOR; // % of interest paid goes to fee
        feeFraction = (feeAmount * _totalAsset.base) / fullAssetAmount;
        _accrueInfo.feesEarnedFraction += uint128(feeFraction);
        totalAsset.base = _totalAsset.base + uint128(feeFraction);
        totalBorrow = _totalBorrow;

        // Update interest rate
        uint256 utilization = (uint256(_totalBorrow.elastic) *
            UTILIZATION_PRECISION) / fullAssetAmount;
        if (utilization < MINIMUM_TARGET_UTILIZATION) {
            uint256 underFactor = ((MINIMUM_TARGET_UTILIZATION - utilization) *
                FACTOR_PRECISION) / MINIMUM_TARGET_UTILIZATION;
            uint256 scale = INTEREST_ELASTICITY +
                (underFactor * underFactor * elapsedTime);
            _accrueInfo.interestPerSecond = uint64(
                (uint256(_accrueInfo.interestPerSecond) * INTEREST_ELASTICITY) /
                    scale
            );

            if (_accrueInfo.interestPerSecond < MINIMUM_INTEREST_PER_SECOND) {
                _accrueInfo.interestPerSecond = MINIMUM_INTEREST_PER_SECOND; // 0.25% APR minimum
            }
        } else if (utilization > MAXIMUM_TARGET_UTILIZATION) {
            uint256 overFactor = ((utilization - MAXIMUM_TARGET_UTILIZATION) *
                FACTOR_PRECISION) / FULL_UTILIZATION_MINUS_MAX;
            uint256 scale = INTEREST_ELASTICITY +
                (overFactor * overFactor * elapsedTime);
            uint256 newInterestPerSecond = (uint256(
                _accrueInfo.interestPerSecond
            ) * scale) / INTEREST_ELASTICITY;
            if (newInterestPerSecond > MAXIMUM_INTEREST_PER_SECOND) {
                newInterestPerSecond = MAXIMUM_INTEREST_PER_SECOND; // 1000% APR maximum
            }
            _accrueInfo.interestPerSecond = uint64(newInterestPerSecond);
        }

        emit LogAccrue(
            extraAmount,
            feeFraction,
            _accrueInfo.interestPerSecond,
            utilization
        );
        accrueInfo = _accrueInfo;
    }

    // *************** //
    // *** PRIVATE *** //
    // *************** //
    /// @notice Concrete implementation of `isSolvent`. Includes a parameter to allow caching `exchangeRate`.
    /// @param _exchangeRate The exchange rate. Used to cache the `exchangeRate` between calls.
    function _isSolvent(address user, uint256 _exchangeRate)
        internal
        view
        returns (bool)
    {
        // accrue must have already been called!
        uint256 borrowPart = userBorrowPart[user];
        if (borrowPart == 0) return true;
        uint256 collateralShare = userCollateralShare[user];
        if (collateralShare == 0) return false;

        Rebase memory _totalBorrow = totalBorrow;

        return
            yieldBox.toAmount(
                collateralId,
                collateralShare *
                    (EXCHANGE_RATE_PRECISION / COLLATERIZATION_RATE_PRECISION) *
                    CLOSED_COLLATERIZATION_RATE,
                false
            ) >=
            // Moved exchangeRate here instead of dividing the other side to preserve more precision
            (borrowPart * _totalBorrow.elastic * _exchangeRate) /
                _totalBorrow.base;
    }

    /// @dev Helper function to move tokens.
    /// @param from Account to debit tokens from, in `yieldBox`.
    /// @param _assetId The ERC-20 token asset ID in yieldBox.
    /// @param share The amount in shares to add.
    /// @param total Grand total amount to deduct from this contract's balance. Only applicable if `skim` is True.
    /// Only used for accounting checks.
    /// @param skim If True, only does a balance check on this contract.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    function _addTokens(
        address from,
        uint256 _assetId,
        uint256 share,
        uint256 total,
        bool skim
    ) internal {
        if (skim) {
            require(
                share <= yieldBox.balanceOf(address(this), _assetId) - total,
                'Mx: too much'
            );
        } else {
            yieldBox.transfer(from, address(this), _assetId, share); // added a 'from' instead of 'msg.sender' -0xGAB
        }
    }

    /// @dev Concrete implementation of `addAsset`.
    function _addAsset(
        address from,
        address to,
        bool skim,
        uint256 share
    ) internal returns (uint256 fraction) {
        Rebase memory _totalAsset = totalAsset;
        uint256 totalAssetShare = _totalAsset.elastic;
        uint256 allShare = _totalAsset.elastic +
            yieldBox.toShare(assetId, totalBorrow.elastic, true);
        fraction = allShare == 0
            ? share
            : (share * _totalAsset.base) / allShare;
        if (_totalAsset.base + uint128(fraction) < 1000) {
            return 0;
        }
        totalAsset = _totalAsset.add(share, fraction);
        balanceOf[to] += fraction;
        emit Transfer(address(0), to, fraction);
        _addTokens(from, assetId, share, totalAssetShare, skim);
        emit LogAddAsset(skim ? address(yieldBox) : from, to, share, fraction);
    }

    /// @notice Adds assets to the lending pair.
    /// @param from Address to add asset from.
    /// @param to The address of the user to receive the assets.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    /// @param share The amount of shares to add.
    /// @return fraction Total fractions added.
    function addAsset(
        address from,
        address to,
        bool skim,
        uint256 share
    ) public allowed(from) returns (uint256 fraction) {
        accrue();
        fraction = _addAsset(from, to, skim, share);
    }

    /// @dev Concrete implementation of `removeAsset`.
    /// @param from The account to remove from. Should always be msg.sender except for `depositFeesToyieldBox()`.
    function _removeAsset(
        address from,
        address to,
        uint256 fraction
    ) internal returns (uint256 share) {
        Rebase memory _totalAsset = totalAsset;
        uint256 allShare = _totalAsset.elastic +
            yieldBox.toShare(assetId, totalBorrow.elastic, true);
        share = (fraction * allShare) / _totalAsset.base;
        balanceOf[from] -= fraction;
        emit Transfer(from, address(0), fraction);
        _totalAsset.elastic -= uint128(share);
        _totalAsset.base -= uint128(fraction);
        require(_totalAsset.base >= 1000, 'Mx: min limit');
        totalAsset = _totalAsset;
        emit LogRemoveAsset(from, to, share, fraction);
        yieldBox.transfer(address(this), to, assetId, share);
    }

    /// @notice Removes an asset from msg.sender and transfers it to `to`.
    /// @param from Account to debit Assets from.
    /// @param to The user that receives the removed assets.
    /// @param fraction The amount/fraction of assets held to remove.
    /// @return share The amount of shares transferred to `to`.
    function removeAsset(
        address from,
        address to,
        uint256 fraction
    ) public allowed(from) returns (uint256 share) {
        accrue();

        share = _removeAsset(from, to, fraction);
    }

    function _getCollateralAmountForShare(uint256 share)
        internal
        view
        returns (uint256)
    {
        return yieldBox.toAmount(collateralId, share, false);
    }

    /// @dev Return the equivalent of collateral borrow part in asset amount.
    function _getAmountForBorrowPart(uint256 borrowPart)
        internal
        view
        returns (uint256)
    {
        return totalBorrow.toElastic(borrowPart, false);
    }

    /// @dev Calculate the collateral shares that are needed for `borrowPart`,
    /// taking the current exchange rate into account.
    function _getCollateralSharesForBorrowPart(uint256 borrowPart)
        internal
        view
        returns (uint256)
    {
        uint256 borrowAmount = totalBorrow.toElastic(borrowPart, false);
        return
            yieldBox.toShare(
                collateralId,
                (borrowAmount * LIQUIDATION_MULTIPLIER * exchangeRate) /
                    (LIQUIDATION_MULTIPLIER_PRECISION *
                        EXCHANGE_RATE_PRECISION),
                false
            );
    }

    /// @dev Compute the amount of `mixologist.assetId` from `fraction`
    /// `fraction` can be `mixologist.accrueInfo.feeFraction` or `mixologist.balanceOf`
    function _getAmountForAssetFraction(uint256 fraction)
        internal
        view
        returns (uint256)
    {
        Rebase memory _totalAsset = totalAsset;
        return
            yieldBox.toAmount(
                assetId,
                (fraction * _totalAsset.elastic) / _totalAsset.base,
                false
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './MXCommon.sol';

contract MXLendingBorrowing is MXCommon {
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    // ************** //
    // *** PUBLIC *** //
    // ************** //
    /// @notice Sender borrows `amount` and transfers it to `to`.
    /// @param from Account to borrow for.
    /// @param to The receiver of borrowed tokens.
    /// @param amount Amount to borrow.
    /// @return part Total part of the debt held by borrowers.
    /// @return share Total amount in shares borrowed.
    function borrow(
        address from,
        address to,
        uint256 amount
    ) public solvent(from) allowed(from) returns (uint256 part, uint256 share) {
        accrue();

        (part, share) = _borrow(from, to, amount);
    }

    /// @notice Repays a loan.
    /// @param from Address to repay from.
    /// @param to Address of the user this payment should go.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    /// @param part The amount to repay. See `userBorrowPart`.
    /// @return amount The total amount repayed.
    function repay(
        address from,
        address to,
        bool skim,
        uint256 part
    ) public allowed(from) returns (uint256 amount) {
        accrue();

        amount = _repay(from, to, skim, part);
    }

    /// @notice Adds `collateral` from msg.sender to the account `to`.
    /// @param from Account to transfer shares from.
    /// @param to The receiver of the tokens.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `yieldBox` should be transferred.
    /// @param share The amount of shares to add for `to`.
    function addCollateral(
        address from,
        address to,
        bool skim,
        uint256 share
    ) public allowed(from) {
        userCollateralShare[to] += share;
        uint256 oldTotalCollateralShare = totalCollateralShare;
        totalCollateralShare = oldTotalCollateralShare + share;
        _addTokens(from, collateralId, share, oldTotalCollateralShare, skim);
        emit LogAddCollateral(skim ? address(yieldBox) : from, to, share);
    }

    /// @notice Removes `share` amount of collateral and transfers it to `to`.
    /// @param from Account to debit collateral from.
    /// @param to The receiver of the shares.
    /// @param share Amount of shares to remove.
    function removeCollateral(
        address from,
        address to,
        uint256 share
    ) public solvent(from) allowed(from) {
        // accrue must be called because we check solvency
        accrue();

        _removeCollateral(from, to, share);
    }

    /// @notice Flashloan ability.
    /// @dev The contract expect the `borrower` to have at the end of `onFlashLoan` `amount` + the incurred fees.
    /// The borrower is expected to `approve()` yieldBox for this number at the end of its `onFlashLoan()`.
    /// @param borrower The address of the contract that implements and conforms to `IFlashBorrower` and handles the flashloan.
    /// @param receiver Address of the token receiver.
    /// @param amount of the tokens to receive.
    /// @param data The calldata to pass to the `borrower` contract.
    function flashLoan(
        IFlashBorrower borrower,
        address receiver,
        uint256 amount,
        bytes memory data
    ) public {
        Rebase memory _totalAsset = totalAsset;
        uint256 feeAmount = (amount * FLASHLOAN_FEE) / FLASHLOAN_FEE_PRECISION;
        uint256 feeFraction = (yieldBox.toShare(assetId, feeAmount, false) *
            _totalAsset.base) / _totalAsset.elastic;

        yieldBox.withdraw(assetId, address(this), receiver, amount, 0);

        borrower.onFlashLoan(msg.sender, asset, amount, feeAmount, data);

        require(
            yieldBox.amountOf(address(this), assetId) >= amount + feeAmount,
            'Mx: insufficient funds'
        );

        totalAsset.base = _totalAsset.base + uint128(feeFraction);
        accrueInfo.feesEarnedFraction += uint128(feeFraction);

        emit LogFlashLoan(address(borrower), amount, feeAmount, receiver);
    }

    // *************** //
    // *** PRIVATE *** //
    // *************** //
    /// @dev Concrete implementation of `removeCollateral`.
    function _removeCollateral(
        address from,
        address to,
        uint256 share
    ) internal {
        userCollateralShare[from] -= share;
        totalCollateralShare -= share;
        emit LogRemoveCollateral(from, to, share);
        yieldBox.transfer(address(this), to, collateralId, share);
    }

    /// @dev Concrete implementation of `borrow`.
    function _borrow(
        address from,
        address to,
        uint256 amount
    ) internal returns (uint256 part, uint256 share) {
        uint256 feeAmount = (amount * BORROW_OPENING_FEE) /
            BORROW_OPENING_FEE_PRECISION; // A flat % fee is charged for any borrow

        (totalBorrow, part) = totalBorrow.add(amount + feeAmount, true);
        require(
            totalBorrowCap == 0 || totalBorrow.base <= totalBorrowCap,
            'Mx: borrow cap reached'
        );
        userBorrowPart[from] += part;
        emit LogBorrow(from, to, amount, feeAmount, part);

        share = yieldBox.toShare(assetId, amount, false);
        Rebase memory _totalAsset = totalAsset;
        require(_totalAsset.base >= 1000, 'Mx: min limit');
        _totalAsset.elastic -= uint128(share);
        totalAsset = _totalAsset;

        yieldBox.transfer(address(this), to, assetId, share);
    }

    /// @dev Concrete implementation of `repay`.
    function _repay(
        address from,
        address to,
        bool skim,
        uint256 part
    ) internal returns (uint256 amount) {
        (totalBorrow, amount) = totalBorrow.sub(part, true);

        userBorrowPart[to] -= part;

        uint256 share = yieldBox.toShare(assetId, amount, true);
        uint128 totalShare = totalAsset.elastic;
        _addTokens(from, assetId, share, uint256(totalShare), skim);
        totalAsset.elastic = totalShare + uint128(share);
        emit LogRepay(skim ? address(yieldBox) : from, to, amount, part);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@boringcrypto/boring-solidity/contracts/BoringOwnable.sol';
import '@boringcrypto/boring-solidity/contracts/ERC20.sol';
import '@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol';
import '@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol';
import '../../yieldbox/contracts/YieldBox.sol';
import '../swappers/MultiSwapper.sol';
import '../mixologist/interfaces/IOracle.sol';
import '../mixologist/interfaces/IFlashLoan.sol';
import '../liquidationQueue/ILiquidationQueue.sol';

// solhint-disable max-line-length

contract MXStorage is BoringOwnable, ERC20 {
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    // ************* //
    // *** ERC20 *** //
    // ************* //

    function symbol() external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'tm',
                    collateral.safeSymbol(),
                    '/',
                    asset.safeSymbol(),
                    '-',
                    oracle.symbol(oracleData)
                )
            );
    }

    function name() external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'Tapioca Mixologist ',
                    collateral.safeName(),
                    '/',
                    asset.safeName(),
                    '-',
                    oracle.name(oracleData)
                )
            );
    }

    function decimals() external view returns (uint8) {
        return asset.safeDecimals();
    }

    // totalSupply for ERC20 compatibility
    // BalanceOf[user] represent a fraction
    function totalSupply() public view override returns (uint256) {
        return totalAsset.base;
    }

    // ************ //
    // *** VARS *** //
    // ************ //
    struct AccrueInfo {
        uint64 interestPerSecond;
        uint64 lastAccrued;
        uint128 feesEarnedFraction;
    }

    AccrueInfo public accrueInfo;

    BeachBar public beachBar;
    YieldBox public yieldBox;
    ILiquidationQueue public liquidationQueue;
    IERC20 public collateral;
    IERC20 public asset;
    uint256 public collateralId;
    uint256 public assetId;

    // Total amounts
    uint256 public totalCollateralShare; // Total collateral supplied
    Rebase public totalAsset; // elastic = yieldBox shares held by the Mixologist, base = Total fractions held by asset suppliers
    Rebase public totalBorrow; // elastic = Total token amount to be repayed by borrowers, base = Total parts of the debt held by borrowers
    uint256 public totalBorrowCap;

    // User balances
    mapping(address => uint256) public userCollateralShare;
    // userAssetFraction is called balanceOf for ERC20 compatibility (it's in ERC20.sol)
    mapping(address => uint256) public userBorrowPart;
    // map of operator approval
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @notice Exchange and interest rate tracking.
    /// This is 'cached' here because calls to Oracles can be very expensive.
    /// Asset -> collateral = assetAmount * exchangeRate.
    uint256 public exchangeRate;

    IOracle public oracle;
    bytes public oracleData;
    address[] collateralSwapPath; // Collateral -> Asset
    address[] tapSwapPath; // Asset -> Tap

    //errors
    error NotApproved(address _from, address _operator);

    // ************** //
    // *** EVENTS *** //
    // ************** //
    event LogExchangeRate(uint256 rate);
    event LogAccrue(
        uint256 accruedAmount,
        uint256 feeFraction,
        uint64 rate,
        uint256 utilization
    );
    event LogAddCollateral(
        address indexed from,
        address indexed to,
        uint256 share
    );
    event LogAddAsset(
        address indexed from,
        address indexed to,
        uint256 share,
        uint256 fraction
    );
    event LogRemoveCollateral(
        address indexed from,
        address indexed to,
        uint256 share
    );
    event LogRemoveAsset(
        address indexed from,
        address indexed to,
        uint256 share,
        uint256 fraction
    );
    event LogBorrow(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 feeAmount,
        uint256 part
    );
    event LogRepay(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 part
    );
    event LogWithdrawFees(address indexed feeTo, uint256 feesEarnedFraction);
    event LogFlashLoan(
        address indexed borrower,
        uint256 amount,
        uint256 feeAmount,
        address indexed receiver
    );
    event LogYieldBoxFeesDeposit(uint256 feeShares, uint256 tapAmount);
    event LogApprovalForAll(
        address indexed _from,
        address indexed _operator,
        bool _approved
    );
    event LogBorrowCapUpdated(uint256 _oldVal, uint256 _newVal);

    // ***************** //
    // *** CONSTANTS *** //
    // ***************** //
    uint256 internal constant CLOSED_COLLATERIZATION_RATE = 75000; // 75%
    uint256 internal constant LQ_COLLATERIZATION_RATE = 25000; // 25%
    uint256 internal constant COLLATERIZATION_RATE_PRECISION = 1e5; // Must be less than EXCHANGE_RATE_PRECISION (due to optimization in math)
    uint256 internal constant MINIMUM_TARGET_UTILIZATION = 7e17; // 70%
    uint256 internal constant MAXIMUM_TARGET_UTILIZATION = 8e17; // 80%
    uint256 internal constant UTILIZATION_PRECISION = 1e18;
    uint256 internal constant FULL_UTILIZATION = 1e18;
    uint256 internal constant FULL_UTILIZATION_MINUS_MAX =
        FULL_UTILIZATION - MAXIMUM_TARGET_UTILIZATION;
    uint256 internal constant FACTOR_PRECISION = 1e18;

    uint64 internal constant STARTING_INTEREST_PER_SECOND = 317097920; // approx 1% APR
    uint64 internal constant MINIMUM_INTEREST_PER_SECOND = 79274480; // approx 0.25% APR
    uint64 internal constant MAXIMUM_INTEREST_PER_SECOND = 317097920000; // approx 1000% APR
    uint256 internal constant INTEREST_ELASTICITY = 28800e36; // Half or double in 28800 seconds (8 hours) if linear

    uint256 internal constant EXCHANGE_RATE_PRECISION = 1e18;

    uint256 internal constant ORDER_BOOK_LIQUIDATION_MULTIPLIER = 127000; // add 27%
    uint256 internal constant LIQUIDATION_MULTIPLIER = 112000; // add 12%
    uint256 internal constant LIQUIDATION_MULTIPLIER_PRECISION = 1e5;

    // Fees
    uint256 internal constant CALLER_FEE = 1000; // 1%
    uint256 internal constant CALLER_FEE_DIVISOR = 1e5;
    uint256 internal constant PROTOCOL_FEE = 10000; // 10%
    uint256 internal constant PROTOCOL_FEE_DIVISOR = 1e5;
    uint256 internal constant BORROW_OPENING_FEE = 50; // 0.05%
    uint256 internal constant BORROW_OPENING_FEE_PRECISION = 1e5;
    uint256 internal constant FLASHLOAN_FEE = 90; // 0.09%
    uint256 internal constant FLASHLOAN_FEE_PRECISION = 1e5;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol';
import '../libraries/IUniswapV2Factory.sol';
import '../libraries/UniswapV2Library.sol';
import '../libraries/IUniswapV2Pair.sol';
import '../BeachBar.sol';
import '../../yieldbox/contracts//YieldBox.sol';


/// Modified from https://github.com/sushiswap/kashi-lending/blob/master/contracts/swappers/SushiSwapMultiSwapper.sol

contract MultiSwapper {
    using BoringERC20 for IERC20;

    address private immutable factory;

    BeachBar private immutable beachBar;
    YieldBox private immutable yieldBox;

    bytes32 private immutable pairCodeHash;

    constructor(
        address _factory,
        BeachBar _tapiocaBar,
        bytes32 _pairCodeHash
    ) {
        factory = _factory;
        beachBar = _tapiocaBar;
        yieldBox = _tapiocaBar.yieldBox();
        pairCodeHash = _pairCodeHash;
    }

    function getOutputAmount(
        uint256 tokenInId,
        address[] calldata path,
        uint256 shareIn
    ) external view returns (uint256 amountOut) {
        uint256 amountIn = yieldBox.toAmount(tokenInId, shareIn, false);
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(
            factory,
            amountIn,
            path,
            pairCodeHash
        );
        amountOut = amounts[amounts.length - 1];
    }

    function getInputAmount(
        uint256 tokenOutId,
        address[] calldata path,
        uint256 shareOut
    ) external view returns (uint256 amountIn) {
        uint256 amountOut = yieldBox.toAmount(tokenOutId, shareOut, false);
        uint256[] memory amounts = UniswapV2Library.getAmountsIn(
            factory,
            amountOut,
            path,
            pairCodeHash
        );
        amountIn = amounts[0];
    }

    function swap(
        uint256 tokenInId,
        uint256 tokenOutId,
        uint256 amountMinOut,
        address to,
        address[] calldata path,
        uint256 shareIn
    ) external returns (uint256 amountOut, uint256 shareOut) {
        (uint256 amountIn, ) = yieldBox.withdraw(
            tokenInId,
            address(this),
            address(this),
            0,
            shareIn
        );

        amountOut = _swapExactTokensForTokens(
            amountIn,
            amountMinOut,
            path,
            address(this)
        );

        IERC20(path[path.length - 1]).approve(address(yieldBox), amountOut);
        (, shareOut) = yieldBox.depositAsset(
            tokenOutId,
            address(this),
            to,
            amountOut,
            0
        );
    }

    // Swaps an exact amount of tokens for another token through the path passed as an argument
    // Returns the amount of the final token
    function _swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory path,
        address to
    ) internal returns (uint256 amountOut) {
        uint256[] memory amounts = UniswapV2Library.getAmountsOut(
            factory,
            amountIn,
            path,
            pairCodeHash
        );
        amountOut = amounts[amounts.length - 1];
        require(amountOut >= amountOutMin, 'insufficient-amount-out');
        // Required for the next step
        IERC20(path[0]).safeTransfer(
            UniswapV2Library.pairFor(factory, path[0], path[1], pairCodeHash),
            amountIn
        );
        _swap(amounts, path, to);
    }

    // requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal virtual {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = UniswapV2Library.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2
                ? UniswapV2Library.pairFor(
                    factory,
                    output,
                    path[i + 2],
                    pairCodeHash
                )
                : _to;

            IUniswapV2Pair(
                UniswapV2Library.pairFor(factory, input, output, pairCodeHash)
            ).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

// The YieldBox
// The original BentoBox is owned by the Sushi team to set strategies for each token. Abracadabra wanted different strategies, which led to
// them launching their own DegenBox. The YieldBox solves this by allowing an unlimited number of strategies for each token in a fully
// permissionless manner. The YieldBox has no owner and operates fully permissionless.

// Other improvements:
// Better system to make sure the token to share ratio doesn't reset.
// Full support for rebasing tokens.

// This contract stores funds, handles their transfers, approvals and strategies.

// Copyright (c) 2021, 2022 BoringCrypto - All rights reserved
// Twitter: @Boring_Crypto

// Since the contract is permissionless, only one deployment per chain is needed. If it's not yet deployed
// on a chain or if you want to make a derivative work, contact @BoringCrypto. The core of YieldBox is
// copyrighted. Most of the contracts that it builds on are open source though.

// BEWARE: Still under active development
// Security review not done yet

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;
import "./interfaces/IWrappedNative.sol";
import "./interfaces/IStrategy.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC721.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/Base64.sol";
import "@boringcrypto/boring-solidity/contracts/Domain.sol";
import "./ERC1155TokenReceiver.sol";
import "./ERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./AssetRegister.sol";
import "./NativeTokenFactory.sol";
import "./YieldBoxRebase.sol";
import "./YieldBoxURIBuilder.sol";

// solhint-disable no-empty-blocks

/// @title YieldBox
/// @author BoringCrypto, Keno
/// @notice The YieldBox is a vault for tokens. The stored tokens can assigned to strategies.
/// Yield from this will go to the token depositors.
/// Any funds transfered directly onto the YieldBox will be lost, use the deposit function instead.
contract YieldBox is BoringBatchable, NativeTokenFactory, ERC1155TokenReceiver {
    using BoringAddress for address;
    using BoringERC20 for IERC20;
    using BoringERC20 for IWrappedNative;
    using YieldBoxRebase for uint256;

    // ************** //
    // *** EVENTS *** //
    // ************** //

    // TODO: Add events

    // ******************* //
    // *** CONSTRUCTOR *** //
    // ******************* //

    IWrappedNative public immutable wrappedNative;
    YieldBoxURIBuilder public immutable uriBuilder;

    constructor(IWrappedNative wrappedNative_, YieldBoxURIBuilder uriBuilder_) {
        wrappedNative = wrappedNative_;
        uriBuilder = uriBuilder_;
    }

    // ************************** //
    // *** INTERNAL FUNCTIONS *** //
    // ************************** //

    /// @dev Returns the total balance of `token` this contracts holds,
    /// plus the total amount this contract thinks the strategy holds.
    function _tokenBalanceOf(Asset storage asset) internal view returns (uint256 amount) {
        if (asset.strategy == NO_STRATEGY) {
            if (asset.tokenType == TokenType.ERC20) {
                return IERC20(asset.contractAddress).safeBalanceOf(address(this));
            } else {
                return IERC1155(asset.contractAddress).balanceOf(address(this), asset.tokenId);
            }
        } else {
            return asset.strategy.currentBalance();
        }
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param assetId The id of the asset.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function depositAsset(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) public allowed(from) returns (uint256 amountOut, uint256 shareOut) {
        // Checks
        Asset storage asset = assets[assetId];
        require(asset.tokenType != TokenType.Native, "YieldBox: can't deposit Native");
        require(asset.tokenType != TokenType.ERC721, "YieldBox: use DepositNFT");

        // Effects
        uint256 totalAmount = _tokenBalanceOf(asset);
        if (share == 0) {
            // value of the share may be lower than the amount due to rounding, that's ok
            share = amount._toShares(totalSupply[assetId], totalAmount, false);
        } else {
            // amount may be lower than the value of share due to rounding, in that case, add 1 to amount (Always round up)
            amount = share._toAmount(totalSupply[assetId], totalAmount, true);
        }

        _mint(to, assetId, share);

        address destination = asset.strategy == NO_STRATEGY ? address(this) : address(asset.strategy);

        // Interactions
        if (asset.tokenType == TokenType.ERC20) {
            IERC20(asset.contractAddress).safeTransferFrom(from, destination, amount);
        } else {
            // ERC1155
            // When depositing yieldBox tokens into the yieldBox, things can be simplified
            if (asset.contractAddress == address(this)) {
                _transferSingle(from, destination, asset.tokenId, amount);
            } else {
                IERC1155(asset.contractAddress).safeTransferFrom(from, destination, asset.tokenId, amount, "");
            }
        }

        if (asset.strategy != NO_STRATEGY) {
            asset.strategy.deposited(amount);
        }

        return (amount, share);
    }

    /// @notice Deposit an NFT asset
    /// @param assetId The id of the asset.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function depositNFTAsset(
        uint256 assetId,
        address from,
        address to
    ) public allowed(from) returns (uint256 amountOut, uint256 shareOut) {
        // Checks
        Asset storage asset = assets[assetId];
        require(asset.tokenType == TokenType.ERC721, "YieldBox: not ERC721");

        // Effects
        _mint(to, assetId, 1);

        address destination = asset.strategy == NO_STRATEGY ? address(this) : address(asset.strategy);

        // Interactions
        IERC721(asset.contractAddress).safeTransferFrom(from, destination, asset.tokenId);

        if (asset.strategy != NO_STRATEGY) {
            asset.strategy.deposited(1);
        }

        return (1, 1);
    }

    function depositETHAsset(
        uint256 assetId,
        address to,
        uint256 amount
    )
        public
        payable
        returns (
            // TODO: allow shares with refund?
            uint256 amountOut,
            uint256 shareOut
        )
    {
        // Checks
        Asset storage asset = assets[assetId];
        require(asset.tokenType == TokenType.ERC20 && asset.contractAddress == address(wrappedNative), "YieldBox: not wrappedNative");

        // Effects
        uint256 share = amount._toShares(totalSupply[assetId], _tokenBalanceOf(asset), false);

        _mint(to, assetId, share);

        // Interactions
        wrappedNative.deposit{ value: amount }();
        if (asset.strategy != NO_STRATEGY) {
            // Strategies always receive wrappedNative (supporting both wrapped and raw native tokens adds too much complexity)
            wrappedNative.safeTransfer(address(asset.strategy), amount);
        }

        if (asset.strategy != NO_STRATEGY) {
            asset.strategy.deposited(amount);
        }

        return (amount, share);
    }

    /// @notice Withdraws an amount of `token` from a user account.
    /// @param assetId The id of the asset.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function withdraw(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) public allowed(from) returns (uint256 amountOut, uint256 shareOut) {
        // Checks
        Asset storage asset = assets[assetId];
        require(asset.tokenType != TokenType.Native, "YieldBox: can't withdraw Native");

        // Effects
        uint256 totalAmount = _tokenBalanceOf(asset);
        if (share == 0) {
            // value of the share paid could be lower than the amount paid due to rounding, in that case, add a share (Always round up)
            share = amount._toShares(totalSupply[assetId], totalAmount, true);
        } else {
            // amount may be lower than the value of share due to rounding, that's ok
            amount = share._toAmount(totalSupply[assetId], totalAmount, false);
        }

        _burn(from, assetId, share);

        // Interactions
        if (asset.strategy == NO_STRATEGY) {
            if (asset.tokenType == TokenType.ERC20) {
                // Native tokens are always unwrapped when withdrawn
                if (asset.contractAddress == address(wrappedNative)) {
                    wrappedNative.withdraw(amount);
                    to.sendNative(amount);
                } else {
                    IERC20(asset.contractAddress).safeTransfer(to, amount);
                }
            } else if (asset.tokenType == TokenType.ERC721) {
                IERC721(asset.contractAddress).safeTransferFrom(address(this), to, asset.tokenId);
            } else {
                // IERC1155
                IERC1155(asset.contractAddress).safeTransferFrom(address(this), to, asset.tokenId, amount, "");
            }
        } else {
            asset.strategy.withdraw(to, amount);
        }

        return (amount, share);
    }

    function _requireTransferAllowed(address from) internal view override allowed(from) {}

    /// @notice Transfer shares from a user account to another one.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param assetId The id of the asset.
    /// @param share The amount of `token` in shares.
    function transfer(
        address from,
        address to,
        uint256 assetId,
        uint256 share
    ) public allowed(from) {
        _transferSingle(from, to, assetId, share);
    }

    function batchTransfer(
        address from,
        address to,
        uint256[] calldata assetIds_,
        uint256[] calldata shares_
    ) public allowed(from) {
        _transferBatch(from, to, assetIds_, shares_);
    }

    /// @notice Transfer shares from a user account to multiple other ones.
    /// @param assetId The id of the asset.
    /// @param from which user to pull the tokens.
    /// @param tos The receivers of the tokens.
    /// @param shares The amount of `token` in shares for each receiver in `tos`.
    function transferMultiple(
        address from,
        address[] calldata tos,
        uint256 assetId,
        uint256[] calldata shares
    ) public allowed(from) {
        // Checks
        uint256 len = tos.length;
        for (uint256 i = 0; i < len; i++) {
            require(tos[i] != address(0), "YieldBox: to not set"); // To avoid a bad UI from burning funds
        }

        // Effects
        uint256 totalAmount;
        for (uint256 i = 0; i < len; i++) {
            address to = tos[i];
            uint256 share_ = shares[i];
            balanceOf[to][assetId] += share_;
            totalAmount += share_;
            emit TransferSingle(msg.sender, from, to, assetId, share_);
        }
        balanceOf[from][assetId] -= totalAmount;
    }

    function setApprovalForAll(address operator, bool approved) external override {
        // Checks
        require(operator != address(0), "YieldBox: operator not set"); // Important for security
        require(masterContractOf[msg.sender] == address(0), "YieldBox: user is clone");
        require(operator != address(this), "YieldBox: can't approve yieldBox");

        // Effects
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // This functionality has been split off into a separate contract. This is only a view function, so gas usage isn't a huge issue.
    // This keeps the YieldBox contract smaller, so it can be optimized more.
    function uri(uint256 assetId) external view override returns (string memory) {
        return uriBuilder.uri(assets[assetId], nativeTokens[assetId], totalSupply[assetId], owner[assetId]);
    }

    function name(uint256 assetId) external view returns (string memory) {
        return uriBuilder.name(assets[assetId], nativeTokens[assetId].name);
    }

    function symbol(uint256 assetId) external view returns (string memory) {
        return uriBuilder.symbol(assets[assetId], nativeTokens[assetId].symbol);
    }

    function decimals(uint256 assetId) external view returns (uint8) {
        return uriBuilder.decimals(assets[assetId], nativeTokens[assetId].decimals);
    }

    // Included to support unwrapping wrapped native tokens such as WETH
    receive() external payable {}

    // Helper functions

    function assetTotals(uint256 assetId) external view returns (uint256 totalShare, uint256 totalAmount) {
        totalShare = totalSupply[assetId];
        totalAmount = _tokenBalanceOf(assets[assetId]);
    }

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param assetId The id of the asset.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(
        uint256 assetId,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share) {
        if (assets[assetId].tokenType == TokenType.Native || assets[assetId].tokenType == TokenType.ERC721) {
            share = amount;
        } else {
            share = amount._toShares(totalSupply[assetId], _tokenBalanceOf(assets[assetId]), roundUp);
        }
    }

    /// @dev Helper function represent shares back into the `token` amount.
    /// @param assetId The id of the asset.
    /// @param share The amount of shares.
    /// @param roundUp If the result should be rounded up.
    /// @return amount The share amount back into native representation.
    function toAmount(
        uint256 assetId,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount) {
        if (assets[assetId].tokenType == TokenType.Native || assets[assetId].tokenType == TokenType.ERC721) {
            amount = share;
        } else {
            amount = share._toAmount(totalSupply[assetId], _tokenBalanceOf(assets[assetId]), roundUp);
        }
    }

    /// @dev Helper function represent the balance in `token` amount for a `user` for an `asset`.
    /// @param user The `user` to get the amount for.
    /// @param assetId The id of the asset.
    function amountOf(address user, uint256 assetId) external view returns (uint256 amount) {
        if (assets[assetId].tokenType == TokenType.Native || assets[assetId].tokenType == TokenType.ERC721) {
            amount = balanceOf[user][assetId];
        } else {
            amount = balanceOf[user][assetId]._toAmount(totalSupply[assetId], _tokenBalanceOf(assets[assetId]), false);
        }
    }

    function deposit(
        TokenType tokenType,
        address contractAddress,
        IStrategy strategy,
        uint256 tokenId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) public returns (uint256 amountOut, uint256 shareOut) {
        if (tokenType == TokenType.Native) {
            // If native token, register it as an ERC1155 asset (as that's what it is)
            return depositAsset(registerAsset(TokenType.ERC1155, address(this), strategy, tokenId), from, to, amount, share);
        } else {
            return depositAsset(registerAsset(tokenType, contractAddress, strategy, tokenId), from, to, amount, share);
        }
    }

    function depositETH(
        IStrategy strategy,
        address to,
        uint256 amount
    ) public payable returns (uint256 amountOut, uint256 shareOut) {
        return depositETHAsset(registerAsset(TokenType.ERC20, address(wrappedNative), strategy, 0), to, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data)
        external
        returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data)
        external
        view
        returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import '@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol';

// solhint-disable max-line-length

interface IFlashBorrower {
    /// @notice The flashloan callback. `amount` + `fee` needs to repayed to msg.sender before this call returns.
    /// @param sender The address of the invoker of this flashloan.
    /// @param token The address of the token that is loaned.
    /// @param amount of the `token` that is loaned.
    /// @param fee The fee that needs to be paid on top for this loan. Needs to be the same as `token`.
    /// @param data Additional data that was passed to the flashloan function.
    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

interface IBatchFlashBorrower {
    /// @notice The callback for batched flashloans. Every amount + fee needs to repayed to msg.sender before this call returns.
    /// @param sender The address of the invoker of this flashloan.
    /// @param tokens Array of addresses for ERC-20 tokens that is loaned.
    /// @param amounts A one-to-one map to `tokens` that is loaned.
    /// @param fees A one-to-one map to `tokens` that needs to be paid on top for each loan. Needs to be the same token.
    /// @param data Additional data that was passed to the flashloan function.
    function onBatchFlashLoan(
        address sender,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
            if (roundUp && (base * total.elastic) / total.base < elastic) {
                base++;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
            if (roundUp && (elastic * total.base) / total.elastic < base) {
                elastic++;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic += uint128(elastic);
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic -= uint128(elastic);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_BALANCE_OF = 0x70a08231; // balanceOf(address)
    bytes4 private constant SIG_TOTALSUPPLY = 0x18160ddd; // balanceOf(address)
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a gas-optimized balance check to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @param to The address of the user to check.
    /// @return amount The token amount.
    function safeBalanceOf(IERC20 token, address to) internal view returns (uint256 amount) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_BALANCE_OF, to));
        require(success && data.length >= 32, "BoringERC20: BalanceOf failed");
        amount = abi.decode(data, (uint256));
    }

    /// @notice Provides a gas-optimized totalSupply to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @return totalSupply The token totalSupply.
    function safeTotalSupply(IERC20 token) internal view returns (uint256 totalSupply) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_TOTALSUPPLY));
        require(success && data.length >= 32, "BoringERC20: totalSupply failed");
        totalSupply = abi.decode(data, (uint256));
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
// Based on code and smartness by Ross Campbell and Keno
// Uses immutable to store the domain separator to reduce gas usage
// If the chain id changes due to a fork, the forked chain will calculate on the fly.
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly

contract Domain {
    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH = keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    // See https://eips.ethereum.org/EIPS/eip-191
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";

    // solhint-disable var-name-mixedcase
    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 private immutable DOMAIN_SEPARATOR_CHAIN_ID;

    /// @dev Calculate the DOMAIN_SEPARATOR
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_SIGNATURE_HASH, chainId, address(this)));
    }

    constructor() {
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = block.chainid);
    }

    /// @dev Return the DOMAIN_SEPARATOR
    // It's named internal to allow making it public from the contract that uses it by creating a simple view function
    // with the desired public name, such as DOMAIN_SEPARATOR or domainSeparator.
    // solhint-disable-next-line func-name-mixedcase
    function _domainSeparator() internal view returns (bytes32) {
        return block.chainid == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(block.chainid);
    }

    function _getDigest(bytes32 dataHash) internal view returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked(EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA, _domainSeparator(), dataHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    // Use BoringERC20 with `using BoringERC20 for IERC20` and call `safeTransfer`, `safeTransferFrom`, etc instead.
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStrictERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../../mixologist/Mixologist.sol';

/// @notice Used for performing swap operations when bidding on LiquidationQueue
interface IBidder {
    /// @notice returns the unique name
    function name() external view returns (string memory);

    /// @notice returns the amount of collateral
    /// @param mixologist Market to query for
    /// @param tokenInId Token in YieldBox asset id
    /// @param amountIn Token in amount
    /// @param data extra data used for retrieving the ouput
    function getOutputAmount(
        Mixologist mixologist,
        uint256 tokenInId,
        uint256 amountIn,
        bytes calldata data
    ) external view returns (uint256);

    /// @notice swap USD0 to collateral
    /// @param mixologist Market to swap for
    /// @param tokenInId Token in asset id
    /// @param amountIn Token in amount
    /// @param data extra data used for the swap operation
    function swap(
        Mixologist mixologist,
        uint256 tokenInId,
        uint256 amountIn,
        bytes calldata data
    ) external returns (uint256);

    /// @notice returns token tokenIn amount based on tokenOut amount
    /// @param mixologist Market to query for
    /// @param tokenInId Token in asset id
    /// @param amountOut Token out amount
    /// @param data extra data used for retrieving the ouput
    function getInputAmount(
        Mixologist mixologist,
        uint256 tokenInId,
        uint256 amountOut,
        bytes calldata data
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import '../yieldbox/contracts/YieldBox.sol';
import '../yieldbox/contracts/interfaces/IWrappedNative.sol';
import '../yieldbox/contracts/interfaces/IStrategy.sol';
import '../yieldbox/contracts/enums/YieldBoxTokenType.sol';
import './swappers/MultiSwapper.sol';
import './mixologist/interfaces/IMixologist.sol';
import '@boringcrypto/boring-solidity/contracts/BoringOwnable.sol';
import './usd0/IUSD0.sol';

enum ContractType {
    lowRisk,
    mediumRisk,
    highRisk
}

struct MasterContract {
    address location;
    ContractType risk;
}

struct SwapData {
    uint256 minAssetAmount;
}

// TODO: Permissionless market deployment
///     + asset registration? (toggle to renounce ownership so users can call)
contract BeachBar is BoringOwnable {
    YieldBox public immutable yieldBox;

    IERC20 public immutable tapToken;
    uint256 public immutable tapAssetId;

    IUSD0 public usdoToken;
    uint256 public usdoAssetId;

    MasterContract[] public masterContracts;

    // Used to check if a master contract is registered to be used as a Mixologist template
    mapping(address => bool) isMasterContractRegistered;

    address public feeTo; // Protocol
    address public feeVeTap; // TAP distributors

    mapping(MultiSwapper => bool) public swappers;

    constructor(YieldBox _yieldBox, IERC20 tapToken_) {
        yieldBox = _yieldBox;
        tapToken = tapToken_;
        tapAssetId = uint96(
            _yieldBox.registerAsset(
                TokenType.ERC20,
                address(tapToken_),
                IStrategy(address(0)),
                0
            )
        );
    }

    // **************//
    // *** EVENTS *** //
    // ************** //

    event ProtocolWithdrawal(address[] markets, uint256 timestamp);
    event RegisterMasterContract(address location, ContractType risk);
    event RegisterMixologist(address location, address masterContract);
    event FeeToUpdate(address newFeeTo);
    event FeeVeTapUpdate(address newFeeVeTap);
    event SwapperUpdate(address swapper, bool isRegistered);
    event UsdoTokenUpdated(address indexed usdoToken, uint256 assetId);

    // ******************//
    // *** MODIFIERS *** //
    // ***************** //

    modifier registeredMasterContract(address mc) {
        require(
            isMasterContractRegistered[mc] == true,
            'BeachBar: MC not registered'
        );
        _;
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //

    /// @notice Get all the Mixologist contract addresses
    function tapiocaMarkets() public view returns (address[] memory markets) {
        uint256 _masterContractLength = masterContracts.length;
        uint256 marketsLength = 0;

        unchecked {
            // We first compute the length of the markets array
            for (uint256 i = 0; i < _masterContractLength; ) {
                marketsLength += yieldBox.clonesOfCount(
                    masterContracts[i].location
                );

                ++i;
            }
        }

        markets = new address[](marketsLength);

        uint256 marketIndex;
        uint256 clonesOfLength;

        unchecked {
            // We populate the array
            for (uint256 i = 0; i < _masterContractLength; ) {
                address mcLocation = masterContracts[i].location;
                clonesOfLength = yieldBox.clonesOfCount(mcLocation);

                // Loop through clones of the current MC.
                for (uint256 j = 0; j < clonesOfLength; ) {
                    markets[marketIndex] = yieldBox.clonesOf(mcLocation, j);
                    ++marketIndex;
                    ++j;
                }
                ++i;
            }
        }
    }

    /// @notice Get the length of `masterContracts`
    function masterContractLength() public view returns (uint256) {
        return masterContracts.length;
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    /// @notice Loop through the master contracts and call `depositFeesToYieldBox()` to each one of their clones.
    /// @dev `swappers_` can have one element that'll be used for all clones. Or one swapper per MasterContract.
    /// @dev Fees are withdrawn in TAP and sent to the FeeDistributor contract
    /// @param swappers_ One or more swappers to convert the asset to TAP.
    function withdrawAllProtocolFees(
        MultiSwapper[] calldata swappers_,
        SwapData[] calldata swapData_
    ) public {
        require(address(swappers_[0]) != address(0), 'BeachBar: zero address');

        uint256 _masterContractLength = masterContracts.length;
        bool singleSwapper = swappers_.length != _masterContractLength;

        address[] memory markets = tapiocaMarkets();
        uint256 length = markets.length;

        unchecked {
            for (uint256 i = 0; i < length; ) {
                IMixologist(markets[i]).depositFeesToYieldBox(
                    singleSwapper ? swappers_[0] : swappers_[i],
                    singleSwapper ? swapData_[0] : swapData_[i]
                );
                ++i;
            }
        }

        emit ProtocolWithdrawal(markets, block.timestamp);
    }

    // *********************** //
    // *** OWNER FUNCTIONS *** //
    // *********************** //

    /// @notice Used to set the USD0 token
    /// @dev sets usdoToken and usdoAssetId
    /// @param _usdoToken the USD0 token address
    function setUsdoToken(address _usdoToken) external onlyOwner {
        usdoToken = IUSD0(_usdoToken);
        usdoAssetId = uint96(
            yieldBox.registerAsset(
                TokenType.ERC20,
                _usdoToken,
                IStrategy(address(0)),
                0
            )
        );
        emit UsdoTokenUpdated(_usdoToken, usdoAssetId);
    }

    /// @notice Register a master contract
    /// @param mcAddress The address of the contract
    /// @param contractType_ The risk type of the contract
    function registerMasterContract(
        address mcAddress,
        ContractType contractType_
    ) external onlyOwner {
        require(
            isMasterContractRegistered[mcAddress] == false,
            'BeachBar: MC registered'
        );

        MasterContract memory mc;
        mc.location = mcAddress;
        mc.risk = contractType_;
        masterContracts.push(mc);
        isMasterContractRegistered[mcAddress] = true;

        emit RegisterMasterContract(mcAddress, contractType_);
    }

    /// @notice Register a Mixologist
    /// @param mc The address of the master contract which must be already registered
    /// @param data The init data of the Mixologist
    /// @param useCreate2 Whether to use create2 or not
    function registerMixologist(
        address mc,
        bytes calldata data,
        bool useCreate2
    )
        external
        payable
        onlyOwner
        registeredMasterContract(mc)
        returns (address _contract)
    {
        _contract = yieldBox.deploy(mc, data, useCreate2);
        emit RegisterMixologist(_contract, mc);
    }

    /// @notice Execute an only owner function inside of a Mixologist market
    function executeMixologistFn(address[] calldata mc, bytes[] memory data)
        external
        onlyOwner
        returns (bool[] memory success, bytes[] memory result)
    {
        uint256 len = mc.length;
        success = new bool[](len);
        result = new bytes[](len);
        for (uint256 i = 0; i < len; ) {
            require(
                isMasterContractRegistered[yieldBox.masterContractOf(mc[i])],
                'BeachBar: MC not registered'
            );
            (success[i], result[i]) = mc[i].call(data[i]);
            ++i;
        }
    }

    function setFeeTo(address feeTo_) external onlyOwner {
        feeTo = feeTo_;
        emit FeeToUpdate(feeTo_);
    }

    function setFeeVeTap(address feeVeTap_) external onlyOwner {
        feeVeTap = feeVeTap_;
        emit FeeVeTapUpdate(feeVeTap_);
    }

    /// @notice Used to register and enable or disable swapper contracts used in closed liquidations.
    /// MasterContract Only Admin function.
    /// @param swapper The address of the swapper contract that conforms to `ISwapper`.
    /// @param enable True to enable the swapper. To disable use False.
    function setSwapper(MultiSwapper swapper, bool enable) external onlyOwner {
        swappers[swapper] = enable;
        emit SwapperUpdate(address(swapper), enable);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import './IUniswapV2Pair.sol';
import './SafeMath.sol';

// solhint-disable max-line-length

library UniswapV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 pairCodeHash
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex'ff',
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            pairCodeHash // init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 pairCodeHash
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB, pairCodeHash)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path,
        bytes32 pairCodeHash
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1], pairCodeHash);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path,
        bytes32 pairCodeHash
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i], pairCodeHash);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import '@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol';

interface IUSD0 is IStrictERC20 {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";

interface IWrappedNative is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "../enums/YieldBoxTokenType.sol";
import "./IYieldBox.sol";

interface IStrategy {
    /// Each strategy only works with a single asset. This should help make implementations simpler and more readable.
    /// To safe gas a proxy pattern (YieldBox factory) could be used to deploy the same strategy for multiple tokens.

    /// It is recommended that strategies keep a small amount of funds uninvested (like 5%) to handle small withdrawals
    /// and deposits without triggering costly investing/divesting logic.

    /// #########################
    /// ### Basic Information ###
    /// #########################

    /// Returns the address of the yieldBox that this strategy is for
    function yieldBox() external view returns (IYieldBox yieldBox_);

    /// Returns a name for this strategy
    function name() external view returns (string memory name_);

    /// Returns a description for this strategy
    function description() external view returns (string memory description_);

    /// #######################
    /// ### Supported Token ###
    /// #######################

    /// Returns the standard that this strategy works with
    function tokenType() external view returns (TokenType tokenType_);

    /// Returns the contract address that this strategy works with
    function contractAddress() external view returns (address contractAddress_);

    /// Returns the tokenId that this strategy works with (for EIP1155)
    /// This is always 0 for EIP20 tokens
    function tokenId() external view returns (uint256 tokenId_);

    /// ###########################
    /// ### Balance Information ###
    /// ###########################

    /// Returns the total value the strategy holds (principle + gain) expressed in asset token amount.
    /// This should be cheap in gas to retrieve. Can return a bit less than the actual, but MUST NOT return more.
    /// The gas cost of this function will be paid on any deposit or withdrawal onto and out of the YieldBox
    /// that uses this strategy. Also, anytime a protocol converts between shares and amount, this gets called.
    function currentBalance() external view returns (uint256 amount);

    /// Returns the maximum amount that can be withdrawn
    function withdrawable() external view returns (uint256 amount);

    /// Returns the maximum amount that can be withdrawn for a low gas fee
    /// When more than this amount is withdrawn it will trigger divesting from the actual strategy
    /// which will incur higher gas costs
    function cheapWithdrawable() external view returns (uint256 amount);

    /// ##########################
    /// ### YieldBox Functions ###
    /// ##########################

    /// Is called by YieldBox to signal funds have been added, the strategy may choose to act on this
    /// When a large enough deposit is made, this should trigger the strategy to invest into the actual
    /// strategy. This function should normally NOT be used to invest on each call as that would be costly
    /// for small deposits.
    /// If the strategy handles native tokens (ETH) it will receive it directly (not wrapped). It will be
    /// up to the strategy to wrap it if needed.
    /// Only accept this call from the YieldBox
    function deposited(uint256 amount) external;

    /// Is called by the YieldBox to ask the strategy to withdraw to the user
    /// When a strategy keeps a little reserve for cheap withdrawals and the requested withdrawal goes over this amount,
    /// the strategy should divest enough from the strategy to complete the withdrawal and rebalance the reserve.
    /// If the strategy handles native tokens (ETH) it should send this, not a wrapped version.
    /// With some strategies it might be hard to withdraw exactly the correct amount.
    /// Only accept this call from the YieldBox
    function withdraw(address to, uint256 amount) external;
}

IStrategy constant NO_STRATEGY = IStrategy(address(0));

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title TokenType
/// @author BoringCrypto (@Boring_Crypto)
/// @notice The YieldBox can hold different types of tokens:
/// Native: These are ERC1155 tokens native to YieldBox. Protocols using YieldBox should use these is possible when simple token creation is needed.
/// ERC20: ERC20 tokens (including rebasing tokens) can be added to the YieldBox.
/// ERC1155: ERC1155 tokens are also supported. This can also be used to add YieldBox Native tokens to strategies since they are ERC1155 tokens.
enum TokenType {
    Native,
    ERC20,
    ERC721,
    ERC1155,
    None
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import '@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol';
import '../../BeachBar.sol';
import './IOracle.sol';
import '../../swappers/MultiSwapper.sol';

interface IMixologist {
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    event LogAccrue(
        uint256 accruedAmount,
        uint256 feeFraction,
        uint64 rate,
        uint256 utilization
    );
    event LogAddAsset(
        address indexed from,
        address indexed to,
        uint256 share,
        uint256 fraction
    );
    event LogAddCollateral(
        address indexed from,
        address indexed to,
        uint256 share
    );
    event LogBorrow(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 feeAmount,
        uint256 part
    );
    event LogExchangeRate(uint256 rate);
    event LogFeeTo(address indexed newFeeTo);
    event LogRemoveAsset(
        address indexed from,
        address indexed to,
        uint256 share,
        uint256 fraction
    );
    event LogRemoveCollateral(
        address indexed from,
        address indexed to,
        uint256 share
    );
    event LogRepay(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 part
    );
    event LogWithdrawFees(address indexed feeTo, uint256 feesEarnedFraction);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event LogFlashLoan(
        address indexed borrower,
        uint256 amount,
        uint256 feeAmount,
        address indexed receiver
    );
    event LogYieldBoxFeesDeposit(uint256 feeShares, uint256 tapAmount);
    event LogApprovalForAll(
        address indexed _from,
        address indexed _operator,
        bool _approved
    );
    error NotApproved(address _from, address _operator);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function accrue() external;

    function accrueInfo()
        external
        view
        returns (
            uint64 interestPerSecond,
            uint64 lastBlockAccrued,
            uint128 feesEarnedFraction
        );

    function setApprovalForAll(address operator, bool approved) external;

    function addAsset(
        address from,
        address to,
        bool skim,
        uint256 share
    ) external returns (uint256 fraction);

    function addCollateral(
        address from,
        address to,
        bool skim,
        uint256 share
    ) external;

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function asset() external view returns (IERC20);

    function balanceOf(address) external view returns (uint256);

    function beachBar() external view returns (BeachBar);

    function borrow(
        address from,
        address to,
        uint256 amount
    ) external returns (uint256 part, uint256 share);

    function claimOwnership() external;

    function collateral() external view returns (IERC20);

    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2);

    function decimals() external view returns (uint8);

    function exchangeRate() external view returns (uint256);

    function feeTo() external view returns (address);

    function getInitData(
        IERC20 collateral_,
        IERC20 asset_,
        IOracle oracle_,
        bytes calldata oracleData_
    ) external pure returns (bytes memory data);

    function init(bytes calldata data) external payable;

    function isSolvent(address user, bool open) external view returns (bool);

    function liquidate(
        address[] calldata users,
        uint256[] calldata borrowParts,
        address to,
        MultiSwapper swapper,
        bool open
    ) external;

    function masterContract() external view returns (address);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function oracle() external view returns (IOracle);

    function oracleData() external view returns (bytes memory);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function removeAsset(
        address from,
        address to,
        uint256 fraction
    ) external returns (uint256 share);

    function removeCollateral(
        address from,
        address to,
        uint256 share
    ) external;

    function repay(
        address from,
        address to,
        bool skim,
        uint256 part
    ) external returns (uint256 amount);

    function setFeeTo(address newFeeTo) external;

    function setSwapper(MultiSwapper swapper, bool enable) external;

    function swappers(MultiSwapper) external view returns (bool);

    function symbol() external view returns (string memory);

    function totalAsset() external view returns (uint128 elastic, uint128 base);

    function totalBorrow()
        external
        view
        returns (uint128 elastic, uint128 base);

    function totalCollateralShare() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function updateExchangeRate() external returns (bool updated, uint256 rate);

    function userBorrowPart(address) external view returns (uint256);

    function userCollateralShare(address) external view returns (uint256);

    function withdrawFees() external;

    function depositFeesToYieldBox(MultiSwapper, SwapData calldata) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155TokenReceiver.sol";

contract ERC1155TokenReceiver is IERC1155TokenReceiver {
    // ERC1155 receivers that simple accept the transfer
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xf23a6e61; //bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xbc197c81; //bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155TokenReceiver.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringAddress.sol";

// Written by OreNoMochi (https://github.com/OreNoMochii), BoringCrypto

contract ERC1155 is IERC1155 {
    using BoringAddress for address;

    // mappings
    mapping(address => mapping(address => bool)) public override isApprovedForAll; // map of operator approval
    mapping(address => mapping(uint256 => uint256)) public override balanceOf; // map of tokens owned by
    mapping(uint256 => uint256) public totalSupply; // totalSupply per token

    function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
        return
            interfaceID == this.supportsInterface.selector || // EIP-165
            interfaceID == 0xd9b67a26 || // ERC-1155
            interfaceID == 0x0e89341c; // EIP-1155 Metadata
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view override returns (uint256[] memory balances) {
        uint256 len = owners.length;
        require(len == ids.length, "ERC1155: Length mismatch");

        balances = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            balances[i] = balanceOf[owners[i]][ids[i]];
        }
    }

    function _mint(
        address to,
        uint256 id,
        uint256 value
    ) internal {
        require(to != address(0), "No 0 address");

        balanceOf[to][id] += value;
        totalSupply[id] += value;

        emit TransferSingle(msg.sender, address(0), to, id, value);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 value
    ) internal {
        require(from != address(0), "No 0 address");

        balanceOf[from][id] -= value;
        totalSupply[id] -= value;

        emit TransferSingle(msg.sender, from, address(0), id, value);
    }

    function _transferSingle(
        address from,
        address to,
        uint256 id,
        uint256 value
    ) internal {
        require(to != address(0), "No 0 address");

        balanceOf[from][id] -= value;
        balanceOf[to][id] += value;

        emit TransferSingle(msg.sender, from, to, id, value);
    }

    function _transferBatch(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values
    ) internal {
        require(to != address(0), "No 0 address");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 value = values[i];
            balanceOf[from][id] -= value;
            balanceOf[to][id] += value;
        }

        emit TransferBatch(msg.sender, from, to, ids, values);
    }

    function _requireTransferAllowed(address from) internal view virtual {
        require(from == msg.sender || isApprovedForAll[from][msg.sender] == true, "Transfer not allowed");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override {
        _requireTransferAllowed(from);

        _transferSingle(from, to, id, value);

        if (to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, value, data) ==
                    bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")),
                "Wrong return value"
            );
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override {
        require(ids.length == values.length, "ERC1155: Length mismatch");
        _requireTransferAllowed(from);

        _transferBatch(from, to, ids, values);

        if (to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, values, data) ==
                    bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")),
                "Wrong return value"
            );
        }
    }

    function setApprovalForAll(address operator, bool approved) external virtual override {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function uri(
        uint256 /*assetId*/
    ) external view virtual returns (string memory) {
        return "";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./interfaces/IStrategy.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringAddress.sol";
import "./ERC1155.sol";

// An asset is a token + a strategy
struct Asset {
    TokenType tokenType;
    address contractAddress;
    IStrategy strategy;
    uint256 tokenId;
}

contract AssetRegister is ERC1155 {
    using BoringAddress for address;

    event AssetRegistered(
        TokenType indexed tokenType,
        address indexed contractAddress,
        IStrategy strategy,
        uint256 indexed tokenId,
        uint256 assetId
    );

    // ids start at 1 so that id 0 means it's not yet registered
    mapping(TokenType => mapping(address => mapping(IStrategy => mapping(uint256 => uint256)))) public ids;
    Asset[] public assets;

    constructor() {
        assets.push(Asset(TokenType.None, address(0), NO_STRATEGY, 0));
    }

    function assetCount() public view returns (uint256) {
        return assets.length;
    }

    function _registerAsset(
        TokenType tokenType,
        address contractAddress,
        IStrategy strategy,
        uint256 tokenId
    ) internal returns (uint256 assetId) {
        // Checks
        assetId = ids[tokenType][contractAddress][strategy][tokenId];

        // If assetId is 0, this is a new asset that needs to be registered
        if (assetId == 0) {
            // Only do these checks if a new asset needs to be created
            require(tokenId == 0 || tokenType != TokenType.ERC20, "YieldBox: No tokenId for ERC20");
            require(
                strategy == NO_STRATEGY ||
                    (tokenType == strategy.tokenType() && contractAddress == strategy.contractAddress() && tokenId == strategy.tokenId()),
                "YieldBox: Strategy mismatch"
            );
            // If a new token gets added, the isContract checks that this is a deployed contract. Needed for security.
            // Prevents getting shares for a future token whose address is known in advance. For instance a token that will be deployed with CREATE2 in the future or while the contract creation is
            // in the mempool
            require((tokenType == TokenType.Native && contractAddress == address(0)) || contractAddress.isContract(), "YieldBox: Not a token");

            // Effects
            assetId = assets.length;
            assets.push(Asset(tokenType, contractAddress, strategy, tokenId));
            ids[tokenType][contractAddress][strategy][tokenId] = assetId;

            // The actual URI isn't emitted here as per EIP1155, because that would make this call super expensive.
            emit URI("", assetId);
            emit AssetRegistered(tokenType, contractAddress, strategy, tokenId, assetId);
        }
    }

    function registerAsset(
        TokenType tokenType,
        address contractAddress,
        IStrategy strategy,
        uint256 tokenId
    ) public returns (uint256 assetId) {
        // Native assets can only be added internally by the NativeTokenFactory
        require(
            tokenType == TokenType.ERC20 || tokenType == TokenType.ERC721 || tokenType == TokenType.ERC1155,
            "AssetManager: cannot add Native"
        );
        assetId = _registerAsset(tokenType, contractAddress, strategy, tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./AssetRegister.sol";
import "./BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/BoringFactory.sol";

struct NativeToken {
    string name;
    string symbol;
    uint8 decimals;
    string uri;
}

/// @title NativeTokenFactory
/// @author BoringCrypto (@Boring_Crypto)
/// @notice The NativeTokenFactory is a token factory to create ERC1155 tokens. This is used by YieldBox to create
/// native tokens in YieldBox. These have many benefits:
/// - low and predictable gas usage
/// - simplified approval
/// - no hidden features, all these tokens behave the same
/// TODO: MintBatch? BurnBatch?
contract NativeTokenFactory is AssetRegister, BoringFactory {
    using BoringMath for uint256;

    mapping(uint256 => NativeToken) public nativeTokens;
    mapping(uint256 => address) public owner;
    mapping(uint256 => address) public pendingOwner;

    event TokenCreated(address indexed creator, string name, string symbol, uint8 decimals, uint256 tokenId);
    event OwnershipTransferred(uint256 indexed tokenId, address indexed previousOwner, address indexed newOwner);

    // ***************** //
    // *** MODIFIERS *** //
    // ***************** //

    /// Modifier to check if the msg.sender is allowed to use funds belonging to the 'from' address.
    /// If 'from' is msg.sender, it's allowed.
    /// If 'msg.sender' is an address (an operator) that is approved by 'from', it's allowed.
    /// If 'msg.sender' is a clone of a masterContract that is approved by 'from', it's allowed.
    modifier allowed(address from) {
        if (from != msg.sender && !isApprovedForAll[from][msg.sender]) {
            address masterContract = masterContractOf[msg.sender];
            require(masterContract != address(0) && isApprovedForAll[from][masterContract], "YieldBox: Not approved");
        }
        _;
    }

    /// @notice Only allows the `owner` to execute the function.
    /// @param tokenId The `tokenId` that the sender has to be owner of.
    modifier onlyOwner(uint256 tokenId) {
        require(msg.sender == owner[tokenId], "NTF: caller is not the owner");
        _;
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param tokenId The `tokenId` of the token that ownership whose ownership will be transferred/renounced.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        uint256 tokenId,
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner(tokenId) {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "NTF: zero address");

            // Effects
            emit OwnershipTransferred(tokenId, owner[tokenId], newOwner);
            owner[tokenId] = newOwner;
            pendingOwner[tokenId] = address(0);
        } else {
            // Effects
            pendingOwner[tokenId] = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    /// @param tokenId The `tokenId` of the token that ownership is claimed for.
    function claimOwnership(uint256 tokenId) public {
        address _pendingOwner = pendingOwner[tokenId];

        // Checks
        require(msg.sender == _pendingOwner, "NTF: caller != pending owner");

        // Effects
        emit OwnershipTransferred(tokenId, owner[tokenId], _pendingOwner);
        owner[tokenId] = _pendingOwner;
        pendingOwner[tokenId] = address(0);
    }

    /// @notice Create a new native token. This will be an ERC1155 token. If later it's needed as an ERC20 token it can
    /// be wrapped into an ERC20 token. Native support for ERC1155 tokens is growing though.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    /// @param decimals The number of decimals of the token (this is just for display purposes). Should be set to 18 in normal cases.
    function createToken(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        string calldata uri
    ) public returns (uint32 tokenId) {
        // To keep each Token unique in the AssetRegister, we use the assetId as the tokenId. So for native assets, the tokenId is always equal to the assetId.
        tokenId = assets.length.to32();
        _registerAsset(TokenType.Native, address(0), NO_STRATEGY, tokenId);
        // Initial supply is 0, use owner can mint. For a fixed supply the owner can mint and revoke ownership.
        // The msg.sender is the initial owner, can be changed after.
        nativeTokens[tokenId] = NativeToken(name, symbol, decimals, uri);
        owner[tokenId] = msg.sender;

        emit TokenCreated(msg.sender, name, symbol, decimals, tokenId);
        emit TransferSingle(msg.sender, address(0), address(0), tokenId, 0);
        emit OwnershipTransferred(tokenId, address(0), msg.sender);
    }

    /// @notice The `owner` can mint tokens. If a fixed supply is needed, the `owner` should mint the totalSupply and renounce ownership.
    /// @param tokenId The token to be minted.
    /// @param to The account to transfer the minted tokens to.
    /// @param amount The amount of tokens to mint.
    function mint(
        uint256 tokenId,
        address to,
        uint256 amount
    ) public onlyOwner(tokenId) {
        _mint(to, tokenId, amount);
    }

    /// @notice Burns tokens. Only the holder of tokens can burn them.
    /// @param tokenId The token to be burned.
    /// @param amount The amount of tokens to burn.
    function burn(
        uint256 tokenId,
        address from,
        uint256 amount
    ) public allowed(from) {
        require(assets[tokenId].tokenType == TokenType.Native, "NTF: Not native");
        _burn(msg.sender, tokenId, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;
import "./interfaces/IStrategy.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/Base64.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringAddress.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity/contracts/Domain.sol";
import "./ERC1155TokenReceiver.sol";
import "./ERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";
import "@boringcrypto/boring-solidity/contracts/BoringFactory.sol";

library YieldBoxRebase {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function _toShares(
        uint256 amount,
        uint256 totalShares_,
        uint256 totalAmount,
        bool roundUp
    ) internal pure returns (uint256 share) {
        // To prevent reseting the ratio due to withdrawal of all shares, we start with
        // 1 amount/1e8 shares already burned. This also starts with a 1 : 1e8 ratio which
        // functions like 8 decimal fixed point math. This prevents ratio attacks or inaccuracy
        // due to 'gifting' or rebasing tokens. (Up to a certain degree)
        totalAmount++;
        totalShares_ += 1e8;

        // Calculte the shares using te current amount to share ratio
        share = (amount * totalShares_) / totalAmount;

        // Default is to round down (Solidity), round up if required
        if (roundUp && (share * totalAmount) / totalShares_ < amount) {
            share++;
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function _toAmount(
        uint256 share,
        uint256 totalShares_,
        uint256 totalAmount,
        bool roundUp
    ) internal pure returns (uint256 amount) {
        // To prevent reseting the ratio due to withdrawal of all shares, we start with
        // 1 amount/1e8 shares already burned. This also starts with a 1 : 1e8 ratio which
        // functions like 8 decimal fixed point math. This prevents ratio attacks or inaccuracy
        // due to 'gifting' or rebasing tokens. (Up to a certain degree)
        totalAmount++;
        totalShares_ += 1e8;

        // Calculte the amount using te current amount to share ratio
        amount = (share * totalAmount) / totalShares_;

        // Default is to round down (Solidity), round up if required
        if (roundUp && (amount * totalShares_) / totalAmount < share) {
            amount++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/Base64.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "./interfaces/IYieldBox.sol";
import "./NativeTokenFactory.sol";

// solhint-disable quotes

contract YieldBoxURIBuilder {
    using BoringERC20 for IERC20;
    using Strings for uint256;
    using Base64 for bytes;

    struct AssetDetails {
        string tokenType;
        string name;
        string symbol;
        uint256 decimals;
    }

    function name(Asset calldata asset, string calldata nativeName) external view returns (string memory) {
        if (asset.strategy == NO_STRATEGY) {
            if (asset.tokenType == TokenType.ERC20) {
                IERC20 token = IERC20(asset.contractAddress);
                return token.safeName();
            } else if (asset.tokenType == TokenType.ERC1155) {
                return
                    string(abi.encodePacked("ERC1155:", uint256(uint160(asset.contractAddress)).toHexString(20), "/", asset.tokenId.toString()));
            } else {
                return nativeName;
            }
        } else {
            if (asset.tokenType == TokenType.ERC20) {
                IERC20 token = IERC20(asset.contractAddress);
                return string(abi.encodePacked(token.safeName(), " (", asset.strategy.name(), ")"));
            } else if (asset.tokenType == TokenType.ERC1155) {
                return
                    string(
                        abi.encodePacked(
                            string(
                                abi.encodePacked(
                                    "ERC1155:",
                                    uint256(uint160(asset.contractAddress)).toHexString(20),
                                    "/",
                                    asset.tokenId.toString()
                                )
                            ),
                            " (",
                            asset.strategy.name(),
                            ")"
                        )
                    );
            } else {
                return string(abi.encodePacked(nativeName, " (", asset.strategy.name(), ")"));
            }
        }
    }

    function symbol(Asset calldata asset, string calldata nativeSymbol) external view returns (string memory) {
        if (asset.strategy == NO_STRATEGY) {
            if (asset.tokenType == TokenType.ERC20) {
                IERC20 token = IERC20(asset.contractAddress);
                return token.safeSymbol();
            } else if (asset.tokenType == TokenType.ERC1155) {
                return "ERC1155";
            } else {
                return nativeSymbol;
            }
        } else {
            if (asset.tokenType == TokenType.ERC20) {
                IERC20 token = IERC20(asset.contractAddress);
                return string(abi.encodePacked(token.safeSymbol(), " (", asset.strategy.name(), ")"));
            } else if (asset.tokenType == TokenType.ERC1155) {
                return string(abi.encodePacked("ERC1155", " (", asset.strategy.name(), ")"));
            } else {
                return string(abi.encodePacked(nativeSymbol, " (", asset.strategy.name(), ")"));
            }
        }
    }

    function decimals(Asset calldata asset, uint8 nativeDecimals) external view returns (uint8) {
        if (asset.tokenType == TokenType.ERC1155) {
            return 0;
        } else if (asset.tokenType == TokenType.ERC20) {
            IERC20 token = IERC20(asset.contractAddress);
            return token.safeDecimals();
        } else {
            return nativeDecimals;
        }
    }

    function uri(
        Asset calldata asset,
        NativeToken calldata nativeToken,
        uint256 totalSupply,
        address owner
    ) external view returns (string memory) {
        AssetDetails memory details;
        if (asset.tokenType == TokenType.ERC1155) {
            // Contracts can't retrieve URIs, so the details are out of reach
            details.tokenType = "ERC1155";
            details.name = string(
                abi.encodePacked("ERC1155:", uint256(uint160(asset.contractAddress)).toHexString(20), "/", asset.tokenId.toString())
            );
            details.symbol = "ERC1155";
        } else if (asset.tokenType == TokenType.ERC20) {
            IERC20 token = IERC20(asset.contractAddress);
            details = AssetDetails("ERC20", token.safeName(), token.safeSymbol(), token.safeDecimals());
        } else {
            // Native
            details.tokenType = "Native";
            details.name = nativeToken.name;
            details.symbol = nativeToken.symbol;
            details.decimals = nativeToken.decimals;
        }

        string memory properties = string(
            asset.tokenType != TokenType.Native
                ? abi.encodePacked(',"tokenAddress":"', uint256(uint160(asset.contractAddress)).toHexString(20), '"')
                : abi.encodePacked(',"totalSupply":', totalSupply.toString(), ',"fixedSupply":', owner == address(0) ? "true" : "false")
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    abi
                        .encodePacked(
                            '{"name":"',
                            details.name,
                            '","symbol":"',
                            details.symbol,
                            '"',
                            asset.tokenType == TokenType.ERC1155 ? "" : ',"decimals":',
                            asset.tokenType == TokenType.ERC1155 ? "" : details.decimals.toString(),
                            ',"properties":{"strategy":"',
                            uint256(uint160(address(asset.strategy))).toHexString(20),
                            '","tokenType":"',
                            details.tokenType,
                            '"',
                            properties,
                            asset.tokenType == TokenType.ERC1155 ? string(abi.encodePacked(',"tokenId":', asset.tokenId.toString())) : "",
                            "}}"
                        )
                        .encode()
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// WARNING!!!
// Combining BoringBatchable with msg.value can cause double spending issues
// https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/

import "./interfaces/IERC20.sol";

contract BaseBoringBatchable {
    error BatchError(bytes innerError);

    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure{
        // If the _res length is less than 68, then
        // the transaction failed with custom error or silently (without a revert message)
        if (_returnData.length < 68) revert BatchError(_returnData);

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        revert(abi.decode(_returnData, (string))); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) {
                _getRevertMsg(result);
            }
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface IERC721Enumerable /* is ERC721 */ {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC165.sol";

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly
// solhint-disable no-empty-blocks

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
                case 1 {
                    mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
                }
                case 2 {
                    mstore(sub(resultPtr, 1), shl(248, 0x3d))
                }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155TokenReceiver {
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly

library BoringAddress {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendNative(address to, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: amount}("");
        require(success, "BoringAddress: transfer failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "../enums/YieldBoxTokenType.sol";

interface IYieldBox {
    function wrappedNative() external view returns (address wrappedNative);

    function assets(uint256 assetId)
        external
        view
        returns (
            TokenType tokenType,
            address contractAddress,
            address strategy,
            uint256 tokenId
        );

    function nativeTokens(uint256 assetId)
        external
        view
        returns (
            string memory name,
            string memory symbol,
            uint8 decimals
        );

    function owner(uint256 assetId) external view returns (address owner);

    function totalSupply(uint256 assetId) external view returns (uint256 totalSupply);

    function depositAsset(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function withdraw(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function transfer(
        address from,
        address to,
        uint256 assetId,
        uint256 share
    ) external;

    function batchTransfer(
        address from,
        address to,
        uint256[] calldata assetIds_,
        uint256[] calldata shares_
    ) external;

    function transferMultiple(
        address from,
        address[] calldata tos,
        uint256 assetId,
        uint256[] calldata shares
    ) external;

    function toShare(
        uint256 assetId,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function toAmount(
        uint256 assetId,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library BoringMath {
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= type(uint128).max, "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= type(uint64).max, "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= type(uint32).max, "BoringMath: uint32 Overflow");
        c = uint32(a);
    }

    function muldiv(
        uint256 value,
        uint256 mul,
        uint256 div,
        bool roundUp
    ) internal pure returns (uint256 result) {
        result = (value * mul) / div;
        if (roundUp && (result * div) / mul < value) {
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./interfaces/IMasterContract.sol";

// solhint-disable no-inline-assembly

contract BoringFactory {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);

    /// @notice Mapping from clone contracts to their masterContract.
    mapping(address => address) public masterContractOf;

    /// @notice Mapping from masterContract to an array of all clones
    /// On mainnet events can be used to get this list, but events aren't always easy to retrieve and
    /// barely work on sidechains. While this adds gas, it makes enumerating all clones much easier.
    mapping(address => address[]) public clonesOf;

    /// @notice Returns the count of clones that exists for a specific masterContract
    /// @param masterContract The address of the master contract.
    /// @return cloneCount total number of clones for the masterContract.
    function clonesOfCount(address masterContract) public view returns (uint256 cloneCount) {
        cloneCount = clonesOf[masterContract].length;
    }

    /// @notice Deploys a given master Contract as a clone.
    /// Any ETH transferred with this call is forwarded to the new clone.
    /// Emits `LogDeploy`.
    /// @param masterContract The address of the contract to clone.
    /// @param data Additional abi encoded calldata that is passed to the new clone via `IMasterContract.init`.
    /// @param useCreate2 Creates the clone by using the CREATE2 opcode, in this case `data` will be used as salt.
    /// @return cloneAddress Address of the created clone contract.
    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) public payable returns (address cloneAddress) {
        require(masterContract != address(0), "BoringFactory: No masterContract");
        bytes20 targetBytes = bytes20(masterContract); // Takes the first 20 bytes of the masterContract's address

        if (useCreate2) {
            // each masterContract has different code already. So clones are distinguished by their data only.
            bytes32 salt = keccak256(data);

            // Creates clone, more info here: https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create2(0, clone, 0x37, salt)
            }
        } else {
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create(0, clone, 0x37)
            }
        }
        masterContractOf[cloneAddress] = masterContract;
        clonesOf[masterContract].push(cloneAddress);

        IMasterContract(cloneAddress).init{value: msg.value}(data);

        emit LogDeploy(masterContract, data, cloneAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}