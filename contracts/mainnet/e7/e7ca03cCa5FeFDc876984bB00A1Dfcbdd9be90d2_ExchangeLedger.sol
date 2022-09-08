//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../lib/FsMath.sol";
import "../lib/Utils.sol";
import "../upgrade/FsBase.sol";
import "./interfaces/IAmm.sol";
import "./interfaces/IExchangeLedger.sol";
import "./interfaces/IExchangeHook.sol";

library Packing {
    struct Position {
        int128 asset;
        int128 stableExcludingFunding;
    }

    struct EntranchedPosition {
        int112 shares;
        int112 stableExcludingFundingTranche;
        uint32 trancheIdx;
    }

    struct TranchePosition {
        Position position;
        int256 totalShares;
    }

    struct Funding {
        /// @notice Because of invariant (2), longAsset == shortAsset, so we only need to keep track of one.
        int128 openAsset;
        /// @notice Accumulates stable paid by longs for time fees and DFR.
        int128 longAccumulatedFunding;
        /// @notice Accumulates stable paid by shorts for time fees and DFR.
        int128 shortAccumulatedFunding;
        /// @notice Last time that funding was updated.
        uint128 lastUpdatedTimestamp;
    }
}

/// @title The implementation of Futureswap's V4.1 exchange.
/// The ExchangeLedger keeps track of the position of all traders (including the AMM) that interact with
/// the system. A position of a trader is just its asset and stable balance.
/// A trade is an exchange of asset and stable between two traders, and is reflected
/// by the elementary function `tradeInternal`. Stable corresponds to an actual ERC20 that is
/// used for collateral in the system (usually a stable token, hence its name, but note that this is not
/// actually a restriction, and in fact we could have any ERC20 as stable). On the other hand, asset can
/// be synthetic, depending on the AMM (in our SpotMarketAmm, asset is directly tied to ERC20).
/// The invariants are thus:
///
/// (1) sum_traders stable(trader) = sum stable ERC20 send in - ERC20 send out = stableToken.balance(vault)
/// (2) sum_traders asset(trader) = 0
///
/// The value of a position is `stable(trader) + priceAssetInStable * asset(trader)`.
/// Using invariant (2), it's easy to see that the total value of all positions equals the stable token
/// balance in the vault. Furthermore, if no position has negative value (bankrupt) this implies that we
/// can close out all positions and return every trader the proper value of its position. For this reason,
/// we have a `liquidate` function that anybody can call to eliminate positions near bankruptcy and keep
/// the system safe.
///
/// Under normal operation, the AMM acts as another trader that is the counter-party to all trades
/// happening in the system. However, the AMM can reject a trade (ie. revert), for example,
/// in our SpotMarketAmm if there is not enough liquidity in the AMM to hedge the trade on a spot market.
/// If this is the case, then normally the exchange would reject the trade. However, there are situations
/// where it won't reject the trade. Liquidations and closes should not be rejected.
/// Liquidations should not be rejected because failing to eliminate bankrupt positions poses risk to the
/// integrity of the system. Closes should not be rejected because we want traders to always be able to exit
/// the system. In these cases, the system resorts to executing the trade against other traders as counter-party,
/// this is called `ADL` (Auto DeLeveraging).
///
/// ADL:
/// ADL is the most complicated part of the system. The blockchain constrains do not allow iterating over
/// all traders, so we need to be able to trade against traders in aggregate. ADL is essentially forcing
/// a trade on traders against their explicit wish to do so. Therefore we have another constraint from a
/// product design perspective that ADL'ing should happen against the riskiest traders first.
///
/// We met these constraints by aggregating traders based on their leverage (risk) and long/short into
/// tranches. For instance, if we ADL a long, we iterate over the short tranches from riskiest to
/// safest and iterate until we're done. If the long is still not fully closed, we ADL the remaining
/// against the AMM position (the AMM as a trader doesn't participate in any tranche).
///
/// Because we bundle trades into tranches, the actual data structure for a trader is `EntranchedPosition`
/// which consist of (trancheShares, stable, trancheIdx). And we have the following triangular matrix
/// transformation, to translate between them.
///
/// asset(trader)  = | asset(tranche)/totalTrancheShares   0 | x | trancheShares(trader) |
/// stable(trader)   | stable(tranche)/totalTrancheShares  1 |   | stable(trader)        |
///
/// We structured the code to first extract the trader position from the tranche, execute the trade,
/// and then insert the trade back in a tranche (could be a different one than the original).
/// ADL'ing simply executes a trade against the position of the tranche. One extra complication is that
/// over time, the above matrix can become ill-conditioned (ie. become singular and non-invertible).
/// This happens when `asset(tranche)/totalTrancheShares` becomes small. When we detect this case,
/// we ditch the tranche and start a new one. See `TRANCHE_INFLATION_MAX`.
///
/// Funding:
/// The system charges time fees and dynamic funding rate (DFR).
/// These fees are continuously charged over time and paid in stable. Both fees are designed such that
/// they are only dependent on the asset value of the position.
/// Because we cannot loop over all positions to update the positions with the correct funding at each time
/// we use a funding pot that each position has a share in (actually two pots one for long and one for short positions,
/// in the code called `longAccumulatedFunding` and `shortAccumulatedFunding`).
/// This way updating funding is a O(1) step of just updating the pot. Each positions share in the pot is
/// determined by the size of the position giving precisely the correct proportional funding rate.
/// The consequence is that a positions actual amount of stable satisfies
///        `stable = stable_without_funding + share_of_funding_pot`
/// We store stable_without_funding as it doesn't change on funding updates. This means that in order to correctly state
/// a position we need to add the share_of_funding_pot, this matters at all places where we calculate the value of
/// the position (for leverage/liquidation) or to calculate the execution price.
/// This accounting is similar to how we do tranches, by extracting the position out of the funding pool
/// before the trade and inserting it back in after the trade.
contract ExchangeLedger is IExchangeLedger, FsBase {
    /// @notice The maximum amount of long tranches and short tranches.
    /// If this constant is set to x there can be x long tranches and x short tranches.
    uint8 private constant MAX_TRANCHES = 10;

    /// @notice When tranches are getting ADL'ed the share ratio per asset share of their respective
    /// main position changes. Once this moves past a certain point we run the risk of rounding
    /// errors becoming signicant. This constant denominates when to switch over to a new tranche.
    int256 private constant TRANCHE_INFLATION_MAX = 1000;

    /// @notice Struct that contains all the funding related information. Useful to bundle all the funding
    /// data at the beginning of a trade operation, manipulate it in memory, and save it back into storage
    /// at the end.
    struct Funding {
        int256 longAccumulatedFunding;
        int256 longAsset;
        int256 shortAccumulatedFunding;
        // While at the beginning/end of the `doChangePosition`
        // longAsset == shortAsset (because of invariant 2), this is not true after extracting
        // a single position (see `tradeInternal`).
        int256 shortAsset;
        uint256 lastUpdatedTimestamp;
    }

    /// @notice Elemental building block used to represent a position.
    struct Position {
        int256 asset;
        int256 stableExcludingFunding;
    }

    /// @notice Used to represent the position of a trader in storage.
    struct EntranchedPosition {
        // Share of the tranche asset and stable that this position owns.
        // The total number of shares is stored in the tranche as `totalShares`.
        int256 trancheShares;
        // Stable that this trader owns in addition to their stable share from the tranche.
        int256 stableExcludingFundingTranche;
        // Tranche that contains the trader's position.
        uint32 trancheIdx;
    }

    /// @notice Used to represent the position of a tranche in storage.
    struct TranchePosition {
        // The actual position of the tranche. Each trader within the tranche owns a fraction of this
        // position, given by `EntranchedPosition.trancheShares / TranchePosition.totalShares`.
        Position position;
        // Total number of shares in this tranche. It holds the invariant that this number is equal
        // to the sum of all EntranchedPosition.trancheShares where EntranchedPosition.trancheIdx is
        // equal to the index of this tranche.
        int256 totalShares;
    }

    /// @notice The AMM is considered just another trader in the system, with the exception that it doesn't
    /// belong to any tranche, so it's position can be represented with `Position` instead of `EntranchedPosition`
    Packing.Position public ammPosition;

    /// @notice Each trader can have at most one position in the exchange at any given time.
    mapping(address => Packing.EntranchedPosition) public traderPositions;

    /// @notice Map from trancheId to tranche position (see definition of trancheId below).
    mapping(uint32 => Packing.TranchePosition) public tranchePositions;

    /// @notice The system can have MAX_TRANCHES long tranches and MAX_TRANCHES short tranches, and they
    /// are assigned an id, which is represented in this map. The id of a tranche changes when the tranche
    /// reaches the TRANCHE_INFLATION_MAX, and a new tranche is created. `nextTrancheIdx` keeps track
    /// of the next id that can be used.
    mapping(uint8 => uint32) public trancheIds;
    uint32 private nextTrancheIdx;

    Packing.Funding public packedFundingData;

    ExchangeConfig public exchangeConfig;
    // Storage gaps for extending exchange config in the future.
    // slither-disable-next-line unused-state
    uint256[52] ____configStorageGap;

    /// @inheritdoc IExchangeLedger
    ExchangeState public override exchangeState;
    /// @inheritdoc IExchangeLedger
    int256 public override pausePrice;

    address public tradeRouter;
    IAmm public override amm;
    IExchangeHook public hook;
    address public treasury;

    /// @dev Reserves storage for future upgrades. Each contract will use exactly storage slot 1000 until 2000.
    /// When adding new fields to this contract, one must decrement this counter proportional to the
    /// number of uint256 slots used.
    //slither-disable-next-line unused-state
    uint256[924] private _____contractGap;

    /// @notice Only for testing our contract gap mechanism, never use in prod.
    //slither-disable-next-line constable-states,unused-state
    uint256 private ___storageMarker;

    function initialize(address _treasury) external initializer {
        //slither-disable-next-line missing-zero-check
        treasury = nonNull(_treasury);
        initializeFsOwnable();
    }

    /// @inheritdoc IExchangeLedger
    function changePosition(
        address trader,
        int256 deltaAsset,
        int256 deltaStable,
        int256 stableBound,
        int256 oraclePrice,
        uint256 time
    ) external override returns (Payout[] memory, bytes memory) {
        require(msg.sender == tradeRouter, "Only TradeRouter");

        //slither-disable-next-line uninitialized-local
        ChangePositionData memory cpd;
        cpd.trader = trader;
        cpd.deltaAsset = deltaAsset;
        cpd.deltaStable = deltaStable;
        cpd.stableBound = stableBound;
        cpd.time = time;
        cpd.oraclePrice = oraclePrice;

        return doChangePosition(cpd);
    }

    /// @inheritdoc IExchangeLedger
    function liquidate(
        address trader,
        address liquidator,
        int256 oraclePrice,
        uint256 time
    ) external override returns (Payout[] memory, bytes memory) {
        require(msg.sender == tradeRouter, "Only TradeRouter");

        //slither-disable-next-line uninitialized-local
        ChangePositionData memory cpd;
        cpd.trader = trader;
        cpd.liquidator = liquidator;
        cpd.time = time;
        cpd.oraclePrice = oraclePrice;

        return doChangePosition(cpd);
    }

    /// @inheritdoc IExchangeLedger
    function getPosition(
        address trader,
        int256 price,
        uint256 time
    )
        external
        view
        override
        returns (
            int256,
            int256,
            uint32
        )
    {
        // Load Amm position and funding data into memory to avoid repeatedly reading from storage.
        Funding memory fundingData = loadFunding();
        Position memory ammPositionMem = loadPosition(ammPosition);
        updateFunding(ammPositionMem, fundingData, time, price);
        (Position memory traderPosition, , uint32 trancheIdx) = extractPosition(trader);
        int256 stable = stableIncludingFunding(traderPosition, fundingData);
        return (traderPosition.asset, stable, trancheIdx);
    }

    /// @inheritdoc IExchangeLedger
    function getAmmPosition(int256 price, uint256 time)
        external
        view
        override
        returns (int256 stableAmount, int256 assetAmount)
    {
        // Load Amm position and funding data into memory to avoid repeatedly reading from storage.
        Funding memory fundingData = loadFunding();
        Position memory ammPositionMem = loadPosition(ammPosition);
        updateFunding(ammPositionMem, fundingData, time, price);
        int256 stable = stableIncludingFunding(ammPositionMem, fundingData);
        // TODO(gerben): return (asset, stable) instead of (stable, asset) for consistency with all our other APIs.
        return (stable, ammPositionMem.asset);
    }

    // doChangePosition loads all necessary data in memory and after calling
    // doChangePositionMemory stores the updated state back.
    function doChangePosition(ChangePositionData memory cpd)
        private
        returns (Payout[] memory, bytes memory)
    {
        //slither-disable-next-line uninitialized-local
        // Passing zero for asset and stable is treated as closing a trade.
        // The trader can not simply pass in the reverse of their position since the position might slightly change
        // because of funding and mining timestamp.
        cpd.isClosing = cpd.deltaAsset == 0 && cpd.deltaStable == 0;

        // Makes sure the exchange is allowed to changePositions right now
        {
            ExchangeState state = exchangeState;
            require(state != ExchangeState.STOPPED, "Exchange stopped, can't change position");

            if (state == ExchangeState.PAUSED) {
                require(cpd.isClosing, "Exchange paused, only closing positions");
            }
        }

        // Load Amm position and funding data into memory to avoid repeatedly reading from storage.
        Funding memory fundingData = loadFunding();
        Position memory ammPositionMem = loadPosition(ammPosition);

        // Updates the funding for all traders. This has to be done before loading a specific trader
        // so that these changes are reflected in the traders position.
        (cpd.timeFeeCharged, cpd.dfrCharged) = updateFunding(
            ammPositionMem,
            fundingData,
            cpd.time,
            cpd.oraclePrice
        );

        // Load the trader's position from storage and remove them from the tranche.
        (
            Position memory traderPositionMem,
            TranchePosition memory tranchePosition,
            uint32 trancheIdx
        ) = extractPosition(cpd.trader);
        // This removes the trader's position from the tranche. Trader will be added to a tranche later after the swap.
        storeTranchePosition(tranchePositions[trancheIdx], tranchePosition);
        Payout[] memory payouts =
            doChangePositionMemory(cpd, traderPositionMem, ammPositionMem, fundingData);

        // Save the updated funding data to storage
        storeFunding(fundingData);

        // Save the Amm position to storage
        storePosition(ammPosition, ammPositionMem);

        // Save the trader position to storage.
        insertPosition(fundingData, cpd.trader, traderPositionMem, cpd.oraclePrice);

        return (payouts, abi.encode(cpd));
    }

    // The logic of the exchange. Works mostly on loaded memory. Except for
    // tranches which are updated in storage on ADL.
    function doChangePositionMemory(
        ChangePositionData memory cpd,
        Position memory traderPositionMem,
        Position memory ammPositionMem,
        Funding memory fundingData
    ) private returns (Payout[] memory) {
        // If the change position is a liquidation make sure the trade can actually be liquidated
        if (cpd.liquidator != address(0)) {
            require(
                canBeLiquidated(
                    traderPositionMem.asset,
                    stableIncludingFunding(traderPositionMem, fundingData),
                    cpd.oraclePrice
                ),
                "Position not liquidatable"
            );
        }

        // Capture the start asset and stable of the trader for the PositionChangedEvent
        cpd.startAsset = traderPositionMem.asset;
        cpd.startStable = stableIncludingFunding(traderPositionMem, fundingData);

        // If the user added stable, add it to his position. We are not deducing stable here since this is handled
        // in payments after the swap is performed.
        if (cpd.deltaStable > 0) {
            traderPositionMem.stableExcludingFunding += cpd.deltaStable;
        }

        // If the trade is closing we need to revert the asset position.
        if (cpd.isClosing) {
            cpd.deltaAsset = -traderPositionMem.asset;
        }

        bool isPartialOrFullClose =
            computeIsPartialOrFullClose(traderPositionMem.asset, cpd.deltaAsset);
        int256 stableSwappedAgainstPool = 0;
        {
            int256 prevAsset = traderPositionMem.asset;
            int256 prevStable = stableIncludingFunding(traderPositionMem, fundingData);
            // If we do not have a change in deltaAsset we do not need to perform a swap.
            if (cpd.deltaAsset != 0) {
                // The amm trade is done in a different execution context. This allows the amm to revert and
                // guarantee no state change in the amm. For instance for a spot market amm, if the amm
                // determines that after the swap on the spot market it's left with not enough liquidity
                // reserved it can safely revert.
                // If the swap succeeded, `stableSwappedAgainstPool` contains the amount of stable
                // that the trader received / paid (if negative).

                // We trust amm.
                //slither-disable-next-line reentrancy-no-eth,reentrancy-benign,reentrancy-events,unused-return
                try amm.trade(cpd.deltaAsset, cpd.oraclePrice, isPartialOrFullClose) returns (
                    //slither-disable-next-line uninitialized-local
                    int256 stableSwapped
                ) {
                    // Slither 0.8.2 does not understand the try/retrurns constract, claiming
                    // `stableSwapped` could be used before it is initialized.
                    // slither-disable-next-line variable-scope
                    stableSwappedAgainstPool = stableSwapped;
                    // If the swap succeeded make sure the trader's bounds are met otherwise revert
                    requireStableBound(cpd.stableBound, stableSwappedAgainstPool);
                    // Update the trader position to their new position
                    tradeInternal(
                        traderPositionMem,
                        ammPositionMem,
                        fundingData,
                        cpd.deltaAsset,
                        stableSwappedAgainstPool
                    );
                } catch {
                    // If we could not do a trade with the AMM, ADL can kick in to allow trader to close their positions
                    // However, we don't allow ADL to apply on non-closing trades.
                    require(isPartialOrFullClose, "IVS");
                    stableSwappedAgainstPool = adlTrade(
                        cpd.deltaAsset,
                        cpd.stableBound,
                        cpd.liquidator != address(0),
                        cpd.oraclePrice,
                        traderPositionMem,
                        ammPositionMem,
                        fundingData
                    );
                    // We do not need to call `requireStableBound()` here. ADL handles bounds internally since they are
                    // slightly different to regular bounds.
                }
            }
            if (traderPositionMem.asset != prevAsset) {
                int256 newStable = stableIncludingFunding(traderPositionMem, fundingData);
                cpd.executionPrice =
                    (-(newStable - prevStable) * FsMath.FIXED_POINT_BASED) /
                    (traderPositionMem.asset - prevAsset);
            }
        }

        // Compute payments to all actors
        if (cpd.liquidator != address(0)) {
            computeLiquidationPayments(traderPositionMem, ammPositionMem, cpd);
        } else {
            computeTradePayments(traderPositionMem, ammPositionMem, cpd, stableSwappedAgainstPool);
        }

        if (cpd.liquidator == address(0)) {
            // Liquidation check needs to be performed here since the trade might be in a liquidatable state after the
            // swap and paying its fees
            require(
                (cpd.isClosing && traderPositionMem.stableExcludingFunding == 0) ||
                    !canBeLiquidated(
                        traderPositionMem.asset,
                        stableIncludingFunding(traderPositionMem, fundingData),
                        cpd.oraclePrice
                    ),
                "Trade liquidatable after change position"
            );
        }

        // If the user does not have a position but still has stable we pay him out.
        if (traderPositionMem.asset == 0 && traderPositionMem.stableExcludingFunding > 0) {
            // Because asset is 0 the position has no contribution from funding
            cpd.traderPayment += traderPositionMem.stableExcludingFunding;
            traderPositionMem.stableExcludingFunding = 0;
        }

        cpd.totalAsset = traderPositionMem.asset;
        cpd.totalStable = stableIncludingFunding(traderPositionMem, fundingData);

        if (address(hook) != address(0)) {
            // Call the hook as a fire-and-forget so if anything fails, the transaction will not revert.
            // Slither is confused about `reason`, claiming it is not initialized.
            // slither-disable-next-line uninitialized-local
            try hook.onChangePosition(cpd) {} catch Error(string memory reason) {
                // Slither 0.8.2 does not understand the try/retrurns constract, claiming `reason`
                // could be used before it is initialized.
                // slither-disable-next-line variable-scope
                emit OnChangePositionHookFailed(reason, cpd);
            } catch {
                emit OnChangePositionHookFailed("No revert reason", cpd);
            }
        }
        emit PositionChanged(cpd);

        // Record payouts that need to be made to external parties. TradeRouter will make the payments accordingly.
        return recordPayouts(treasury, cpd);
    }

    /// @dev Update internal accounting for a trade between two given parties. Accounting invariants should be
    /// maintained with all credits being matched by debits.
    function tradeInternal(
        Position memory traderPosition,
        Position memory counterPartyPosition,
        Funding memory fundingData,
        int256 deltaAsset,
        int256 deltaStable
    ) private pure {
        extractFromFunding(traderPosition, fundingData);
        extractFromFunding(counterPartyPosition, fundingData);
        traderPosition.asset += deltaAsset;
        counterPartyPosition.asset -= deltaAsset;
        traderPosition.stableExcludingFunding += deltaStable;
        counterPartyPosition.stableExcludingFunding -= deltaStable;
        insertInFunding(counterPartyPosition, fundingData);
        insertInFunding(traderPosition, fundingData);
        FsUtils.Assert(fundingData.longAsset == fundingData.shortAsset);
    }

    function computeIsPartialOrFullClose(int256 startingAsset, int256 deltaAsset)
        private
        pure
        returns (bool)
    {
        uint256 newPositionSize = FsMath.abs(startingAsset + deltaAsset);
        uint256 oldPositionSize = FsMath.abs(startingAsset);
        uint256 positionChange = FsMath.abs(deltaAsset);
        return newPositionSize < oldPositionSize && positionChange <= oldPositionSize;
    }

    function requireStableBound(int256 stableBound, int256 stableSwapped) private pure {
        // A stableBound of zero means no bound
        if (stableBound == 0) {
            return;
        }

        // 1. A long trade opening:
        //    stableSwapped will be a negative number (payed by the user),
        //    users are expected to set a lower negative number
        // 2. A short trade opening:
        //    stableSwapped will be a positive number (stable received by the user)
        //    The user is expected to set a lower positive number
        // 3. A long trade closing:
        //    stableSwapped will be a positive number (stable received by the user)
        //    The user is expected to set a lower positve number
        // 4. A short trade closing
        //    stableSwapped will be a negative number (stable payed by the user)
        //    The user is expected to set a lower negative number
        require(stableBound <= stableSwapped, "Trade stable bounds violated");
    }

    function computeLiquidationPayments(
        Position memory traderPositionMem,
        Position memory ammPositionMem,
        ChangePositionData memory cpd
    ) private view {
        // After liquidation there should be no net position
        FsUtils.Assert(traderPositionMem.asset == 0);
        // Because asset == 0 we don't need to include funding

        //slither-disable-next-line uninitialized-local
        int256 remainingCollateral = traderPositionMem.stableExcludingFunding;
        traderPositionMem.stableExcludingFunding = 0;

        if (remainingCollateral <= 0) {
            // The position is bankrupt and so pool takes the loss.
            ammPositionMem.stableExcludingFunding += remainingCollateral;
            return;
        }

        int256 liquidatorFee =
            (remainingCollateral * exchangeConfig.liquidatorFrac) / FsMath.FIXED_POINT_BASED;
        liquidatorFee = FsMath.min(liquidatorFee, exchangeConfig.maxLiquidatorFee);
        cpd.liquidatorPayment = liquidatorFee;

        int256 poolLiquidationFee =
            (remainingCollateral * exchangeConfig.poolLiquidationFrac) / FsMath.FIXED_POINT_BASED;
        poolLiquidationFee = FsMath.min(poolLiquidationFee, exchangeConfig.maxPoolLiquidationFee);
        ammPositionMem.stableExcludingFunding += poolLiquidationFee;

        int256 sumFees = liquidatorFee + poolLiquidationFee;
        cpd.tradeFee = sumFees;
        remainingCollateral -= sumFees;
        cpd.traderPayment = remainingCollateral;

        // treasury payment comes from the poolLiquidationFee and not the full remainingCollateral
        cpd.treasuryPayment =
            (poolLiquidationFee * exchangeConfig.treasuryFraction) /
            FsMath.FIXED_POINT_BASED;
        ammPositionMem.stableExcludingFunding -= cpd.treasuryPayment;
    }

    function computeTradePayments(
        Position memory traderPositionMem,
        Position memory ammPositionMem,
        ChangePositionData memory cpd,
        int256 stableSwapped
    ) private view {
        // If closing the net asset should be zero.
        FsUtils.Assert(!cpd.isClosing || traderPositionMem.asset == 0);

        if (cpd.isClosing && traderPositionMem.stableExcludingFunding < 0) {
            // Trade is bankrupt, pool acquires the loss
            // Because asset is zero we don't need funding
            ammPositionMem.stableExcludingFunding += traderPositionMem.stableExcludingFunding;
            traderPositionMem.stableExcludingFunding = 0;
            return;
        }

        // Trade fee is a percentage on the size of the trade (ie stableSwapped)
        int256 tradeFee =
            (FsMath.sabs(stableSwapped) * exchangeConfig.tradeFeeFraction) /
                FsMath.FIXED_POINT_BASED;
        cpd.tradeFee = tradeFee;
        traderPositionMem.stableExcludingFunding -= tradeFee;
        ammPositionMem.stableExcludingFunding += tradeFee;

        // Above we checked that if closing the asset is zero, so we do not
        // need the funding correction.  And then `stableExcludingFunding`
        // contains an accurate stable value.
        int256 traderPayment =
            cpd.isClosing
                ? traderPositionMem.stableExcludingFunding > 0
                    ? traderPositionMem.stableExcludingFunding
                    : int256(0)
                : (cpd.deltaStable < 0 ? -cpd.deltaStable : int256(0));
        traderPositionMem.stableExcludingFunding -= traderPayment; //  This is compensated by ERC20 transfer to trader
        cpd.traderPayment = traderPayment;
        cpd.treasuryPayment =
            (tradeFee * exchangeConfig.treasuryFraction) /
            FsMath.FIXED_POINT_BASED;
        ammPositionMem.stableExcludingFunding -= cpd.treasuryPayment; // Compensated by treasury payment
    }

    function recordPayouts(address _treasury, ChangePositionData memory cpd)
        private
        pure
        returns (Payout[] memory payouts)
    {
        // Create a fixed array of payouts as there's no way to add to a dynamic array in memory.
        // slither-disable-next-line uninitialized-local
        Payout[3] memory tmpPayouts;
        uint256 payoutCount = 0;
        if (cpd.traderPayment > 0) {
            // slither-disable-next-line safe-cast
            tmpPayouts[payoutCount++] = Payout(cpd.trader, uint256(cpd.traderPayment));
        }

        if (cpd.liquidator != address(0) && cpd.liquidatorPayment > 0) {
            // slither-disable-next-line safe-cast
            tmpPayouts[payoutCount++] = Payout(cpd.liquidator, uint256(cpd.liquidatorPayment));
        }

        if (cpd.treasuryPayment > 0) {
            // For internal payments we use ERC20 exclusively, so that our
            // contracts do not need to be able to receive ETH.
            // slither-disable-next-line safe-cast
            tmpPayouts[payoutCount++] = Payout(_treasury, uint256(cpd.treasuryPayment));
        }
        payouts = new Payout[](payoutCount);
        // Convert fixed array to dynamic so we don't have gaps.
        for (uint256 i = 0; i < payoutCount; i++) payouts[i] = tmpPayouts[i];
        return payouts;
    }

    function calculateTranche(
        Position memory traderPositionMem,
        int256 price,
        Funding memory fundingData
    ) private view returns (uint8) {
        uint256 leverage =
            FsMath.calculateLeverage(
                traderPositionMem.asset,
                stableIncludingFunding(traderPositionMem, fundingData),
                price
            );
        uint256 trancheLevel = (MAX_TRANCHES * leverage) / exchangeConfig.maxLeverage;
        bool isLong = traderPositionMem.asset > 0;
        uint256 trancheIdAsUint256 = (trancheLevel << 1) + (isLong ? 0 : 1);

        require(trancheIdAsUint256 < 2 * MAX_TRANCHES, "Over max tranches limit");
        // The above check validates that `trancheIdAsUint256` fits into `uint8` as long as
        // `MAX_TRANCHES` is below 128.  It is currently set to 10.
        // slither-disable-next-line safe-cast
        return uint8(trancheIdAsUint256);
    }

    function extractPosition(address trader)
        private
        view
        returns (
            Position memory,
            TranchePosition memory,
            uint32
        )
    {
        EntranchedPosition memory traderPosition = loadEntranchedPosition(traderPositions[trader]);
        TranchePosition memory tranchePosition =
            loadTranchePosition(tranchePositions[traderPosition.trancheIdx]);

        //slither-disable-next-line uninitialized-local
        Position memory traderPos;

        // If the trader has no trancheShares we can take a simpler route here:
        // The trader will not own any asset nor stable from the tranche
        if (traderPosition.trancheShares == 0) {
            // The only stable the trader might own is stored in his position directly
            traderPos.stableExcludingFunding = traderPosition.stableExcludingFundingTranche;
            return (traderPos, tranchePosition, traderPosition.trancheIdx);
        }

        int256 trancheAsset = tranchePosition.position.asset;

        // used twice below optimizing for gas
        int256 traderTrancheShares = traderPosition.trancheShares;
        // used below multiple times optimizing for gas
        int256 trancheTotalShares = tranchePosition.totalShares;

        // Calculate how much of the tranches asset belongs to the trader
        FsUtils.Assert(trancheTotalShares >= traderPosition.trancheShares);
        FsUtils.Assert(trancheTotalShares > 0);
        traderPos.asset = (trancheAsset * traderTrancheShares) / trancheTotalShares;

        // Calculate how much of the tranches stable belongs to the trader
        int256 stableFromTranche =
            (tranchePosition.position.stableExcludingFunding * traderTrancheShares) /
                trancheTotalShares;

        // The total stable to the trader owns is his stable stored in the position
        // combined with the stable he owns from the tranchePosition
        traderPos.stableExcludingFunding =
            traderPosition.stableExcludingFundingTranche +
            stableFromTranche;

        tranchePosition.position.asset -= traderPos.asset;
        tranchePosition.position.stableExcludingFunding -= stableFromTranche;
        tranchePosition.totalShares -= traderPosition.trancheShares;

        return (traderPos, tranchePosition, traderPosition.trancheIdx);
    }

    function extractFromFunding(Position memory position, Funding memory fundingData) private pure {
        int256 asset = position.asset;
        int256 stable = 0;
        if (asset > 0) {
            FsUtils.Assert(fundingData.longAsset > 0);
            stable = (fundingData.longAccumulatedFunding * asset) / fundingData.longAsset;
            fundingData.longAccumulatedFunding -= stable;
            fundingData.longAsset -= asset;
        } else if (asset < 0) {
            FsUtils.Assert(fundingData.shortAsset > 0);
            stable = (fundingData.shortAccumulatedFunding * (-asset)) / fundingData.shortAsset;
            fundingData.shortAccumulatedFunding -= stable;
            fundingData.shortAsset -= (-asset);
        }
        position.stableExcludingFunding += stable;
    }

    function stableIncludingFunding(Position memory position, Funding memory fundingData)
        private
        pure
        returns (int256)
    {
        int256 asset = position.asset;
        int256 stable = 0;
        if (asset > 0) {
            FsUtils.Assert(fundingData.longAsset > 0);
            stable = (fundingData.longAccumulatedFunding * asset) / fundingData.longAsset;
        } else if (asset < 0) {
            FsUtils.Assert(fundingData.shortAsset > 0);
            stable = (fundingData.shortAccumulatedFunding * (-asset)) / fundingData.shortAsset;
        }
        return position.stableExcludingFunding + stable;
    }

    function insertInFunding(Position memory position, Funding memory fundingData) private pure {
        int256 asset = position.asset;
        int256 stable = 0;
        if (asset > 0) {
            if (fundingData.longAsset != 0) {
                stable = (fundingData.longAccumulatedFunding * asset) / fundingData.longAsset;
            }
            fundingData.longAccumulatedFunding += stable;
            fundingData.longAsset += asset;
        } else if (asset < 0) {
            if (fundingData.shortAsset != 0) {
                stable = (fundingData.shortAccumulatedFunding * (-asset)) / fundingData.shortAsset;
            }
            fundingData.shortAccumulatedFunding += stable;
            fundingData.shortAsset += (-asset);
        }
        position.stableExcludingFunding -= stable;
    }

    function insertPosition(
        Funding memory fundingData,
        address trader,
        Position memory traderPositionMem,
        int256 price
    ) private {
        // If the trader owns no asset we can skip all the computations below
        if (traderPositionMem.asset == 0) {
            traderPositions[trader] = Packing.EntranchedPosition(0, 0, 0);
            // Trades that have no asset can not have stable and will be paid out
            FsUtils.Assert(traderPositionMem.stableExcludingFunding == 0);
            return;
        }

        // Find the tranche the trade has to be stored in
        uint8 tranche = calculateTranche(traderPositionMem, price, fundingData);
        uint32 trancheIdx = trancheIds[tranche];
        Packing.TranchePosition storage packedTranchePosition = tranchePositions[trancheIdx];

        TranchePosition memory tranchePosition = loadTranchePosition(packedTranchePosition);

        // Over time tranches might inflate their shares (if the tranche got ADL'ed), which will lead to a precision
        // loss for the tranche. Before the precision loss becomes significant, we switch over to a new tranche.
        // We can see the precision loss for a trade by looking at the ratio of `tranche.totalShares` and
        // `tranche.position.asset`. The ratio for each tranche starts out at 1 to 1, and changes if the tranche gets
        // ADL'ed. Once the ratio has changed more then TRANCHE_INFLATION_MAX we create a new tranche and replace the
        // current one.
        int256 trancheAsset = tranchePosition.position.asset;
        int256 totalShares = tranchePosition.totalShares;
        FsUtils.Assert(totalShares >= 0);

        if (trancheIdx == 0 || totalShares > FsMath.sabs(trancheAsset) * TRANCHE_INFLATION_MAX) {
            // Either this is the first time a trader is put in this tranche or the tranche-transformation
            // has become numerically unstable. So create a new tranche position for this tranche.
            trancheIdx = ++nextTrancheIdx; // pre-increment to ensure tranche index 0 is never used
            trancheIds[tranche] = trancheIdx;
            packedTranchePosition = tranchePositions[trancheIdx];
            tranchePosition = loadTranchePosition(packedTranchePosition);

            trancheAsset = tranchePosition.position.asset;
            totalShares = tranchePosition.totalShares;
        }

        // Calculate how many shares of the tranche the trader is going to get.
        int256 trancheShares =
            trancheAsset == 0
                ? FsMath.sabs(traderPositionMem.asset)
                : (traderPositionMem.asset * totalShares) / trancheAsset;
        // Note that traderPos.asset and trancheAsset will have the same sign.
        FsUtils.Assert(trancheShares >= 0);

        // If there is any stable in the tranche we need to see how much of the stable the trader now gets from the
        // tranche so we can subtract it from the stable in their position.
        int256 trancheStable = tranchePosition.position.stableExcludingFunding;
        int256 deltaStable =
            totalShares == 0 ? int256(0) : (trancheStable * trancheShares) / totalShares;
        int256 traderStable = traderPositionMem.stableExcludingFunding - deltaStable;

        tranchePosition.position = Position(
            trancheAsset + traderPositionMem.asset,
            trancheStable + deltaStable
        );
        tranchePosition.totalShares = totalShares + trancheShares;
        storeEntranchedPosition(
            traderPositions[trader],
            EntranchedPosition(trancheShares, traderStable, trancheIdx)
        );
        storeTranchePosition(packedTranchePosition, tranchePosition);
    }

    function computeAssetAndStableToADL(
        Position memory traderPositionMem,
        int256 deltaAsset,
        bool isLiquidation,
        int256 oraclePrice,
        Funding memory fundingData
    )
        private
        view
        returns (
            int256,
            int256,
            bool
        )
    {
        // If the previous position of the trader was bankrupt or is being liquidated
        // we have to ADL the entire position
        int256 stable = stableIncludingFunding(traderPositionMem, fundingData);
        int256 traderPositionValue =
            FsMath.assetToStable(traderPositionMem.asset, oraclePrice) + stable;
        if (traderPositionValue < 0 || isLiquidation) {
            // If the position is bankrupt we ADL at the bankruptcy price, which is the best
            // price we can close the position without a loss for the pool.
            // TODO(gerben) Should we do this at liquidation too, because if it's not bankrupt
            // and thus has still positive value, ADL'ing at a price that makes it 0 value means
            // liquidator is not getting any money and the opposite traders get a very good deal.
            return (-traderPositionMem.asset, -stable, false);
        }

        int256 stableToADL = FsMath.assetToStable(-deltaAsset, oraclePrice);
        stableToADL -=
            (FsMath.sabs(stableToADL) * exchangeConfig.adlFeePercent) /
            FsMath.FIXED_POINT_BASED;

        return (deltaAsset, stableToADL, true);
    }

    function adlTrade(
        int256 deltaAsset,
        int256 stableBound,
        bool isLiquidation,
        int256 oraclePrice,
        Position memory traderPositionMem,
        Position memory ammPositionMem,
        Funding memory fundingData
    ) private returns (int256) {
        // regularClose is not a liquidation or bankruptcy.
        (int256 assetToADL, int256 stableToADL, bool regularClose) =
            computeAssetAndStableToADL(
                traderPositionMem,
                deltaAsset,
                isLiquidation,
                oraclePrice,
                fundingData
            );

        if (regularClose) {
            requireStableBound(stableBound, stableToADL);
        }

        uint8 offset = assetToADL > 0 ? 0 : 1;
        for (uint8 i = 0; i < MAX_TRANCHES; i++) {
            uint8 tranche = (MAX_TRANCHES - 1 - i) * 2 + offset;

            uint32 trancheIdx = trancheIds[tranche];

            (int256 assetADLInTranche, int256 stableADLInTranche) =
                adlTranche(
                    traderPositionMem,
                    tranchePositions[trancheIdx],
                    fundingData,
                    assetToADL,
                    stableToADL
                );

            assetToADL -= assetADLInTranche;
            stableToADL -= stableADLInTranche;

            if (assetADLInTranche != 0) {
                emit TrancheAutoDeleveraged(
                    tranche,
                    trancheIdx,
                    assetADLInTranche,
                    stableADLInTranche,
                    tranchePositions[trancheIdx].totalShares
                );
            }

            //slither-disable-next-line incorrect-equality
            if (assetToADL == 0) {
                FsUtils.Assert(stableToADL == 0);
                return 0;
            }
        }

        // If there is any assetToADL or stableToADL this means that we ran out of opposing trade
        // traderPositions to ADL and now liquidity providers take over the remainder of the position
        tradeInternal(traderPositionMem, ammPositionMem, fundingData, assetToADL, stableToADL);
        emit AmmAdl(assetToADL, stableToADL);

        return stableToADL;
    }

    function adlTranche(
        Position memory traderPosition,
        Packing.TranchePosition storage packedTranchePosition,
        Funding memory fundingData,
        int256 assetToADL,
        int256 stableToADL
    ) private returns (int256, int256) {
        int256 assetToADLInTranche;

        TranchePosition memory tranchePosition = loadTranchePosition(packedTranchePosition);

        int256 assetInTranche = tranchePosition.position.asset;

        if (assetToADL < 0) {
            assetToADLInTranche = assetInTranche > assetToADL ? assetInTranche : assetToADL;
        } else {
            assetToADLInTranche = assetInTranche > assetToADL ? assetToADL : assetInTranche;
        }

        int256 stableToADLInTranche = (stableToADL * assetToADLInTranche) / assetToADL;

        tradeInternal(
            traderPosition,
            tranchePosition.position,
            fundingData,
            assetToADLInTranche,
            stableToADLInTranche
        );

        storeTranchePosition(packedTranchePosition, tranchePosition);

        return (assetToADLInTranche, stableToADLInTranche);
    }

    function updateFunding(
        Position memory ammPositionMem,
        Funding memory funding,
        uint256 time,
        int256 price
    ) private view returns (int256 timeFee, int256 dfrFee) {
        if (time <= funding.lastUpdatedTimestamp) {
            // Normally time < lastUpdatedTimestamp cannot occur, only
            // time == lastUpdatedTimestamp as block timestamps are non-decreasing.
            // However we allow time equals 0 for convenience in the view functions
            // when callers are not interested in the effect of funding on the position.
            return (0, 0);
        }

        FsUtils.Assert(time > funding.lastUpdatedTimestamp); // See above condition
        // slither-disable-next-line safe-cast
        int256 deltaTime = int256(time - funding.lastUpdatedTimestamp);

        funding.lastUpdatedTimestamp = time;

        timeFee = calculateTimeFee(deltaTime, funding.longAsset, price);
        dfrFee = calculateDFR(deltaTime, ammPosition.asset, price);

        // Writing both asset changes back here once, to optimize for gas
        funding.longAccumulatedFunding -= timeFee - dfrFee;
        funding.shortAccumulatedFunding -= timeFee + dfrFee;
        // Note both longs and shorts pay time fee (hence factor of 2)
        timeFee *= 2;
        ammPositionMem.stableExcludingFunding += timeFee;
    }

    /// @notice Calculates the DFR fee to pay in stable. The result is positive when shorts pay longs
    /// (ie, there are more shorts than longs), and negative otherwise.
    /// @param deltaTime period of time for which to compute the DFR fee.
    /// @param ammAsset The asset position of the AMM, which is the oposite to the overall traders position in the
    /// exchange. If ammAsset is positive (ie, AMM is long), then the traders in the exchange are short, and viceversa.
    /// @param assetPrice DFR is charged in stable using the `assetPrice` to convert from asset.
    function calculateDFR(
        int256 deltaTime,
        int256 ammAsset,
        int256 assetPrice
    ) private view returns (int256) {
        int256 dfrRate = exchangeConfig.dfrRate;
        return
            (FsMath.assetToStable(ammAsset, assetPrice) * dfrRate * deltaTime) /
            FsMath.FIXED_POINT_BASED;
    }

    /// @notice Calculates the Time fee to pay in stable. The result is positive the total exchange position is long
    /// and negative otherwise.
    /// @param deltaTime period of time for which to compute the time fee.
    /// @param totalAsset The asset position of the traders in the exchange.
    /// @param assetPrice Time fee is charged in stable using the `assetPrice` to convert from asset.
    function calculateTimeFee(
        int256 deltaTime,
        int256 totalAsset,
        int256 assetPrice
    ) private view returns (int256) {
        int256 timeFee = exchangeConfig.timeFee;
        return
            (FsMath.assetToStable(totalAsset, assetPrice) * deltaTime * timeFee) /
            FsMath.FIXED_POINT_BASED;
    }

    function canBeLiquidated(
        int256 asset,
        int256 stable,
        int256 assetPrice
    ) private view returns (bool) {
        if (asset == 0) {
            return stable < 0;
        }

        int256 assetInStable = FsMath.assetToStable(asset, assetPrice);
        int256 collateral = assetInStable + stable;

        // Safe cast does not evaluate compile time constants yet. `type(int256).max` is within the
        // `uint256` type range.
        // slither-disable-next-line safe-cast
        FsUtils.Assert(
            0 < exchangeConfig.minCollateral &&
                exchangeConfig.minCollateral <= uint256(type(int256).max)
        );
        // `exchangeConfig.minCollateral` is checked in `setExchangeConfig` to be within range for
        // `int256`.
        // slither-disable-next-line safe-cast
        if (collateral < int256(exchangeConfig.minCollateral)) {
            return true;
        }
        // We check for `collateral` to be equal or above `exchangeConfig.minCollateral`.
        // `exchangeConfig.minCollateral` is strictly positive, so it is safe to convert
        // `collateral` to `uint256`.  And it is safe to divide, as we know the number is not going
        // to be zero.  If `exchangeConfig.minCollateral` will allow `0` as a valid value, we need
        // an additions check for `collateral` to be equal to `0`.
        //
        // slither-disable-next-line safe-cast
        uint256 leverage = FsMath.calculateLeverage(asset, stable, assetPrice);
        return leverage >= exchangeConfig.maxLeverage;
    }

    function loadFunding() private view returns (Funding memory) {
        return
            Funding(
                packedFundingData.longAccumulatedFunding,
                packedFundingData.openAsset,
                packedFundingData.shortAccumulatedFunding,
                packedFundingData.openAsset,
                packedFundingData.lastUpdatedTimestamp
            );
    }

    function storeFunding(Funding memory fundingData) private {
        FsUtils.Assert(fundingData.longAsset == fundingData.shortAsset);
        packedFundingData.openAsset = int128(fundingData.longAsset);
        packedFundingData.longAccumulatedFunding = int128(fundingData.longAccumulatedFunding);
        packedFundingData.shortAccumulatedFunding = int128(fundingData.shortAccumulatedFunding);
        packedFundingData.lastUpdatedTimestamp = uint128(fundingData.lastUpdatedTimestamp);
    }

    function loadPosition(Packing.Position storage packedPosition)
        private
        view
        returns (Position memory)
    {
        return Position(packedPosition.asset, packedPosition.stableExcludingFunding);
    }

    function storePosition(Packing.Position storage packedPosition, Position memory position)
        private
    {
        packedPosition.asset = int128(position.asset);
        packedPosition.stableExcludingFunding = int128(position.stableExcludingFunding);
    }

    function loadTranchePosition(Packing.TranchePosition storage packedTranchePosition)
        private
        view
        returns (TranchePosition memory)
    {
        return
            TranchePosition(
                loadPosition(packedTranchePosition.position),
                packedTranchePosition.totalShares
            );
    }

    function storeTranchePosition(
        Packing.TranchePosition storage packedTranchePosition,
        TranchePosition memory tranchePosition
    ) private {
        storePosition(packedTranchePosition.position, tranchePosition.position);
        packedTranchePosition.totalShares = tranchePosition.totalShares;
    }

    function loadEntranchedPosition(Packing.EntranchedPosition storage packedEntranchedPosition)
        private
        view
        returns (EntranchedPosition memory)
    {
        return
            EntranchedPosition(
                packedEntranchedPosition.shares,
                packedEntranchedPosition.stableExcludingFundingTranche,
                packedEntranchedPosition.trancheIdx
            );
    }

    function storeEntranchedPosition(
        Packing.EntranchedPosition storage packedEntranchedPosition,
        EntranchedPosition memory entranchedPosition
    ) private {
        packedEntranchedPosition.shares = int112(entranchedPosition.trancheShares);
        packedEntranchedPosition.stableExcludingFundingTranche = int112(
            entranchedPosition.stableExcludingFundingTranche
        );
        packedEntranchedPosition.trancheIdx = entranchedPosition.trancheIdx;
    }

    /// @inheritdoc IExchangeLedger
    function setExchangeConfig(ExchangeConfig calldata config) external override onlyOwner {
        if (keccak256(abi.encode(config)) == keccak256(abi.encode(exchangeConfig))) {
            return;
        }

        // We use `minCollateral` in `int256` calculations.  In particular, in `canBeLiquidated()`
        // we expect `minCollateral` to be positive.
        //
        // `canBeLiquidated()` relies on `minCollateral` to be non-zero.  If `minCollateral` is `0`
        // and a position slides to have `0` in their `collateral` it becomes unliquidatable, due to
        // a division by zero in `canBeLiquidated()`.
        //
        // slither-disable-next-line safe-cast
        require(
            0 < config.minCollateral && config.minCollateral <= uint256(type(int256).max),
            "minCollateral outside valid range"
        );

        emit ExchangeConfigChanged(exchangeConfig, config);

        exchangeConfig = config;
    }

    /// @inheritdoc IExchangeLedger
    function setExchangeState(ExchangeState _exchangeState, int256 _pausePrice)
        external
        override
        onlyOwner
    {
        _pausePrice = _exchangeState == ExchangeState.PAUSED ? _pausePrice : int256(0);

        if (exchangeState == _exchangeState && pausePrice == _pausePrice) {
            return;
        }

        emit ExchangeStateChanged(exchangeState, pausePrice, _exchangeState, _pausePrice);
        pausePrice = _pausePrice;
        exchangeState = _exchangeState;
    }

    /// @inheritdoc IExchangeLedger
    function setHook(address _hook) external override onlyOwner {
        if (address(hook) == _hook) {
            return;
        }

        emit ExchangeHookAddressChanged(address(hook), _hook);
        hook = IExchangeHook(_hook);
    }

    /// @inheritdoc IExchangeLedger
    function setAmm(address _amm) external override onlyOwner {
        if (address(amm) == _amm) {
            return;
        }

        emit AmmAddressChanged(address(amm), _amm);
        // slither-disable-next-line missing-zero-check
        amm = IAmm(FsUtils.nonNull(_amm));
    }

    /// @inheritdoc IExchangeLedger
    function setTradeRouter(address _tradeRouter) external override onlyOwner {
        if (address(tradeRouter) == _tradeRouter) {
            return;
        }

        emit TradeRouterAddressChanged(address(tradeRouter), _tradeRouter);
        // slither-disable-next-line missing-zero-check
        tradeRouter = FsUtils.nonNull(_tradeRouter);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

/// @title Utility methods basic math operations.
///      NOTE In order for the fuzzing tests to be isolated, all functions in this library need to
///      be `internal`.  Otherwise a contract that uses this library has a dependency on the
///      library.
///
///      Our current Echidna setup requires contracts to be deployable in isolation, so make sure to
///      keep the functions `internal`, until we update our Echidna tests to support more complex
///      setups.
library FsMath {
    uint256 constant BITS_108 = (1 << 108) - 1;
    int256 constant BITS_108_MIN = -(1 << 107);
    uint256 constant BITS_108_MASKED = ~BITS_108;
    uint256 constant BITS_108_SIGN = 1 << 107;
    int256 constant FIXED_POINT_BASED = 1 ether;

    function abs(int256 value) internal pure returns (uint256) {
        if (value >= 0) {
            // slither-disable-next-line safe-cast
            return uint256(value);
        }
        // slither-disable-next-line safe-cast
        return uint256(-value);
    }

    function sabs(int256 value) internal pure returns (int256) {
        if (value >= 0) {
            return value;
        }
        return -value;
    }

    function sign(int256 value) internal pure returns (int256) {
        if (value < 0) {
            return -1;
        } else if (value > 0) {
            return 1;
        } else {
            return 0;
        }
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    // Clip val into interval [lower, upper]
    function clip(
        int256 val,
        int256 lower,
        int256 upper
    ) internal pure returns (int256) {
        return min(max(val, lower), upper);
    }

    function safeCastToSigned(uint256 x) internal pure returns (int256) {
        // slither-disable-next-line safe-cast
        int256 ret = int256(x);
        require(ret >= 0, "Cast overflow");
        return ret;
    }

    function safeCastToUnsigned(int256 x) internal pure returns (uint256) {
        require(x >= 0, "Cast underflow");
        // slither-disable-next-line safe-cast
        return uint256(x);
    }

    /// @notice Encode a int256 into a string hex value prepended with a magic identifier "stable0x"
    function encodeValue(int256 value) external pure returns (string memory) {
        return encodeValueStatic(value);
    }

    /// @notice Encode a int256 into a string hex value prepended with a magic identifier "stable0x"
    ///
    /// @dev This is a "static" version of `encodeValue`.  A contract using this method will not
    ///      have a dependency on the library.
    function encodeValueStatic(int256 value) internal pure returns (string memory) {
        // We are going to encode the two's complement representation.  To be consumed
        // by`decodeValue()`.
        // slither-disable-next-line safe-cast
        bytes32 y = bytes32(uint256(value));
        bytes memory bytesArray = new bytes(8 + 64);
        bytesArray[0] = "s";
        bytesArray[1] = "t";
        bytesArray[2] = "a";
        bytesArray[3] = "b";
        bytesArray[4] = "l";
        bytesArray[5] = "e";
        bytesArray[6] = "0";
        bytesArray[7] = "x";
        for (uint256 i = 0; i < 32; i++) {
            // slither-disable-next-line safe-cast
            uint8 x = uint8(y[i]);
            uint8 u = x >> 4;
            uint8 l = x & 0xF;
            bytesArray[8 + 2 * i] = u >= 10 ? bytes1(u + 65 - 10) : bytes1(u + 48);
            bytesArray[8 + 2 * i + 1] = l >= 10 ? bytes1(l + 65 - 10) : bytes1(l + 48);
        }
        // Bytes we generated above are valid UTF-8.
        // slither-disable-next-line safe-cast
        return string(bytesArray);
    }

    /// @notice Decode an encoded int256 value above.
    /// @return 0 if string is not of the right format.
    function decodeValue(bytes memory r) external pure returns (int256) {
        return decodeValueStatic(r);
    }

    /// @notice Decode an encoded int256 value above.
    /// @dev This is a "static" version of `encodeValue`.  A contract using this method will not
    ///      have a dependency on the library.
    /// @return 0 if string is not of the right format.
    function decodeValueStatic(bytes memory r) internal pure returns (int256) {
        if (
            r.length == 8 + 64 &&
            r[0] == "s" &&
            r[1] == "t" &&
            r[2] == "a" &&
            r[3] == "b" &&
            r[4] == "l" &&
            r[5] == "e" &&
            r[6] == "0" &&
            r[7] == "x"
        ) {
            uint256 y;
            for (uint256 i = 0; i < 64; i++) {
                // slither-disable-next-line safe-cast
                uint8 h = uint8(r[8 + i]);
                uint256 x;
                if (h >= 65) {
                    if (h >= 65 + 16) return 0;
                    x = (h + 10) - 65;
                } else {
                    if (!(h >= 48 && h < 48 + 10)) return 0;
                    x = h - 48;
                }
                y |= x << (256 - 4 - 4 * i);
            }
            // We were decoding a two's complement representation.  Produced by `encodeValue()`.
            // slither-disable-next-line safe-cast
            return int256(y);
        } else {
            return 0;
        }
    }

    /// @notice Returns the lower 108 bits of data as a positive int256
    function read108(uint256 data) internal pure returns (int256) {
        // slither-disable-next-line safe-cast
        return int256(data & BITS_108);
    }

    /// @notice Returns the lower 108 bits sign extended as a int256
    function readSigned108(uint256 data) internal pure returns (int256) {
        uint256 temp = data & BITS_108;

        if (temp & BITS_108_SIGN > 0) {
            temp = temp | BITS_108_MASKED;
        }
        // slither-disable-next-line safe-cast
        return int256(temp);
    }

    /// @notice Performs a range check and returns the lower 108 bits of the value
    function pack108(int256 value) internal pure returns (uint256) {
        if (value >= 0) {
            // slither-disable-next-line safe-cast
            require(value <= int256(BITS_108), "RE");
        } else {
            require(value >= BITS_108_MIN, "RE");
        }

        // Ranges were checked above.  And we expect negative values to be encoded in a two's
        // complement form, as this is how we decode them in `readSigned108()`.
        // slither-disable-next-line safe-cast
        return uint256(value) & BITS_108;
    }

    /// @notice Calculate the leverage amount given amounts of stable/asset and the asset price.
    function calculateLeverage(
        int256 assetAmount,
        int256 stableAmount,
        int256 assetPrice
    ) internal pure returns (uint256) {
        // Return early for gas saving.
        if (assetAmount == 0) {
            return 0;
        }
        int256 assetInStable = assetToStable(assetAmount, assetPrice);
        int256 collateral = assetInStable + stableAmount;
        // Avoid division by 0.
        require(collateral > 0, "Insufficient collateral");
        // slither-disable-next-line safe-cast
        return FsMath.abs(assetInStable * FIXED_POINT_BASED) / uint256(collateral);
    }

    /// @notice Returns the worth of the given asset amount in stable token.
    function assetToStable(int256 assetAmount, int256 assetPrice) internal pure returns (int256) {
        return (assetAmount * assetPrice) / FIXED_POINT_BASED;
    }

    /// @notice Returns the worth of the given stable amount in asset token.
    function stableToAsset(int256 stableAmount, int256 assetPrice) internal pure returns (int256) {
        return (stableAmount * FIXED_POINT_BASED) / assetPrice;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

// BEGIN STRIP
// Used in `FsUtils.Log` which is a debugging tool.
import "hardhat/console.sol";

// END STRIP

library FsUtils {
    function nonNull(address _address) internal pure returns (address) {
        require(_address != address(0), "Zero address");
        return _address;
    }

    // Slither sees this function is not used, but it is convenient to have it around, as it
    // actually provides better error messages than `nonNull` above.
    // slither-disable-next-line dead-code
    function nonNull(address _address, string memory message) internal pure returns (address) {
        require(_address != address(0), message);
        return _address;
    }

    // Assert a condition. Assert should be used to assert an invariant that should be true
    // logically.
    // This is useful for readability and debugability. A failing assert is always a bug.
    //
    // In production builds (non-hardhat, and non-localhost deployments) this method is a noop.
    //
    // Use "require" to enforce requirements on data coming from outside of a contract. Ie.,
    //
    // ```solidity
    // function nonNegativeX(int x) external { require(x >= 0, "non-negative"); }
    // ```
    //
    // But
    // ```solidity
    // function nonNegativeX(int x) private { assert(x >= 0); }
    // ```
    //
    // If a private function has a pre-condition that it should only be called with non-negative
    // values it's a bug in the contract if it's called with a negative value.
    function Assert(bool cond) internal pure {
        // BEGIN STRIP
        assert(cond);
        // END STRIP
    }

    // BEGIN STRIP
    // This method is only mean to be used in local testing.  See `preprocess` property in
    // `packages/contracts/hardhat.config.ts`.
    // Slither sees this function is not used, but it is convenient to have it around for debugging
    // purposes.
    // slither-disable-next-line dead-code
    function Log(string memory s) internal view {
        console.log(s);
    }

    // END STRIP

    // BEGIN STRIP
    // This method is only mean to be used in local testing.  See `preprocess` property in
    // `packages/contracts/hardhat.config.ts`.
    // Slither sees this function is not used, but it is convenient to have it around for debugging
    // purposes.
    // slither-disable-next-line dead-code
    function Log(string memory s, int256 x) internal view {
        console.log(s);
        console.logInt(x);
    }
    // END STRIP
}

contract ImmutableOwnable {
    address public immutable owner;

    constructor(address _owner) {
        // slither-disable-next-line missing-zero-check
        owner = FsUtils.nonNull(_owner);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }
}

// Contracts deriving from this contract will have a public pure function
// that returns a gitCommitHash at the moment it was compiled.
contract GitCommitHash {
    // A purely random string that's being replaced in a prod build by
    // the git hash at build time.
    uint256 public immutable gitCommitHash =
        0xDEADBEEFCAFEBABEBEACBABEBA5EBA11B0A710ADB00BBABEDEFACA7EDEADFA11;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./FsOwnable.sol";
import "../lib/Utils.sol";

contract FsBase is Initializable, FsOwnable, GitCommitHash {
    /// @notice We reserve 1000 slots for the base contract in case
    //          we ever need to add fields to the contract.
    //slither-disable-next-line unused-state
    uint256[999] private _____baseGap;

    function nonNull(address _address) internal pure returns (address) {
        require(_address != address(0), "Zero address");
        return _address;
    }

    function nonNull(address _address, string memory message) internal pure returns (address) {
        require(_address != address(0), message);
        return _address;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

/// @title An interface for the internal AMM that trades with the users of an exchange.
///
/// @notice When a user trades on an exchange, the AMM will automatically take the opposite position, effectively
/// acting like a market maker in a traditional order book market.
///
/// An AMM can execute any hedging or arbitraging strategies internally. For example, it can trade with a spot market
/// such as Uniswap to hedge a position.
interface IAmm {
    /// @notice Takes a position in token1 against token0. Can only be called by the exchange to take the opposite
    /// position to a trader. The trade can fail for several different reasons: its hedging strategy failed, it has
    /// insufficient funds, out of gas, etc.
    ///
    /// @param _assetAmount The position to take in asset. Positive for long and negative for short.
    /// @param _oraclePrice The reference price for the trade.
    /// @param _isClosingTraderPosition Whether the trade is for closing a trader's position partially or fully.
    /// @return stableAmount The amount of stable amount received or paid.
    function trade(
        int256 _assetAmount,
        int256 _oraclePrice,
        bool _isClosingTraderPosition
    ) external returns (int256 stableAmount);

    /// @notice Returns the asset price that this AMM quotes for trading with it.
    /// @return assetPrice The asset price that this AMM quotes for trading with it
    function getAssetPrice() external view returns (int256 assetPrice);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./IAmm.sol";
import "./IOracle.sol";

/// @title Futureswap V4.1 exchange for a single pair of tokens.
///
/// @notice An API for an exchange that manages leveraged trades for one pair of tokens.  One token
/// is called "asset" and it's address is returned by `assetToken()`. The other token is called
/// "stable" and it's address is returned by `stableToken()`.  Exchange is mostly symmetrical with
/// regard to how "asset" and "stable" are treated.
///
/// The exchange only deals with abstract accounting. It requires a trusted setup with a TokenRouter
/// to do actual transfers of ERC20's. The two basic operations are
///
///  - Trade: Implemented by `changePosition()`, requires collateral to be deposited by caller.
///  - Liquidation bot(s): Implemented by `liquidate()`.
///
interface IExchangeLedger {
    /// @notice Restricts exchange functionality.
    enum ExchangeState {
        // All functions are operational.
        NORMAL,
        // Only allow positions to be closed and liquidity removed.
        PAUSED,
        // No operations all allowed.
        STOPPED
    }

    /// @notice Emitted on all trades/liquidations containing all information of the update.
    /// @param cpd The `ChangePositionData` struct that contains all information collected.
    event PositionChanged(ChangePositionData cpd);

    /// @notice Emitted when exchange config is updated.
    event ExchangeConfigChanged(ExchangeConfig previousConfig, ExchangeConfig newConfig);

    /// @notice Emitted when the exchange state is updated.
    /// @param previousState the old state.
    /// @param previousPausePrice the oracle price the exchange is paused at.
    /// @param newState the new state.
    /// @param newPausePrice the new oracle price in case the exchange is paused.
    event ExchangeStateChanged(
        ExchangeState previousState,
        int256 previousPausePrice,
        ExchangeState newState,
        int256 newPausePrice
    );

    /// @notice Emitted when exchange hook is updated.
    event ExchangeHookAddressChanged(address previousHook, address newHook);

    /// @notice Emitted when AMM used by the exchange is updated.
    event AmmAddressChanged(address previousAmm, address newAmm);

    /// @notice Emitted when the TradeRouter authorized by the exchange is updated.
    event TradeRouterAddressChanged(address previousTradeRouter, address newTradeRouter);

    /// @notice Emitted when an ADL happens against the pool.
    /// @param deltaAsset How much asset transferred to pool.
    /// @param deltaStable How much stable transferred to pool.
    event AmmAdl(int256 deltaAsset, int256 deltaStable);

    /// @notice Emitted if the hook call fails.
    /// @param reason Revert reason.
    /// @param cpd The change position data of this trade.
    event OnChangePositionHookFailed(string reason, ChangePositionData cpd);

    /// @notice Emitted when a tranche is ADL'd.
    /// @param tranche This risk tranche
    /// @param trancheIdx The id of the tranche that was ADL'd.
    /// @param assetADL Amount of asset ADL'd against this tranche.
    /// @param stableADL Amount of stable ADL'd against this tranche.
    /// @param totalTrancheShares Total amount of shares in this tranche.
    event TrancheAutoDeleveraged(
        uint8 tranche,
        uint32 trancheIdx,
        int256 assetADL,
        int256 stableADL,
        int256 totalTrancheShares
    );

    /// @notice Represents a payout of `amount` with recipient `to`.
    struct Payout {
        address to;
        uint256 amount;
    }

    /// @dev Data tracked throughout changePosition and used in the `PositionChanged` event.
    struct ChangePositionData {
        // The address of the trader whose position is being changed.
        address trader;
        // The liquidator address is only non zero if this is a liquidation.
        address liquidator;
        // Whether or not this change is a request to close the trade.
        bool isClosing;
        // The change in asset that we are being asked to make to the position.
        int256 deltaAsset;
        // The change in stable that we are being asked to make to the position.
        int256 deltaStable;
        // A bound for the amount in stable paid / received for making the change.
        // Note: If this is set to zero no bounds are enforced.
        // Note: This is set to zero for liquidations.
        int256 stableBound;
        // Oracle price
        int256 oraclePrice;
        // Time used to compute funding.
        uint256 time;
        // Time fee charged.
        int256 timeFeeCharged;
        // Funding paid from longs to shorts (negative if other direction).
        int256 dfrCharged;
        // The amount of stable tokens being paid to liquidity providers as a trade fee.
        int256 tradeFee;
        // The amount of asset the position had before changing it.
        int256 startAsset;
        // The amount of stable the position had before changing it.
        int256 startStable;
        // The amount of asset the position had after changing it.
        int256 totalAsset;
        // The amount of stable the position had after changing it.
        int256 totalStable;
        // The amount of stable tokens being paid to the trader.
        int256 traderPayment;
        // The amount of stable tokens being paid to the liquidator.
        int256 liquidatorPayment;
        // The amount of stable tokens being paid to the treasury.
        int256 treasuryPayment;
        // The price at which the trade was executed.
        int256 executionPrice;
    }

    /// @dev Exchange config parameters
    struct ExchangeConfig {
        // The trade fee to be charged in percent for a trade range: [0, 1 ether]
        int256 tradeFeeFraction;
        // The time fee to be charged in percent for a trade range: [0, 1 ether]
        int256 timeFee;
        // The maximum leverage that the exchange allows before a trade becomes liquidatable, range: [0, 200 ether),
        // 0 (inclusive) to 200x leverage (exclusive)
        uint256 maxLeverage;
        // The minimum of collateral (stable token amount) a position needs to have. If a position falls below this
        // number it becomes liquidatable
        uint256 minCollateral;
        // The percentage of the trade fee being paid to the treasury, range: [0, 1 ether]
        int256 treasuryFraction;
        // A fee for imbalancing the exchange, range: [0, 1 ether].
        int256 dfrRate;
        // A fee that is paid to a liquidator for liquidating a trade expressed as percentage of remaining collateral,
        // range: [0, 1 ether]
        int256 liquidatorFrac;
        // A maximum amount of stable tokens that a liquidator can receive for a liquidation.
        int256 maxLiquidatorFee;
        // A fee that is paid to a liquidity providers if a trade gets liquidated expressed as percentage of
        // remaining collateral, range: [0, 1 ether]
        int256 poolLiquidationFrac;
        // A maximum amount of stable tokens that the liquidity providers can receive for a liquidation.
        int256 maxPoolLiquidationFee;
        // A fee that a trade experiences if its causing other trades to get ADL'ed, range: [0, 1 ether].
        int256 adlFeePercent;
    }

    /// @notice Returns the current state of the exchange. See description on ExchangeState for details.
    function exchangeState() external view returns (ExchangeState);

    /// @notice Returns the price that exchange was paused at.
    /// If the exchange got paused, this price overrides the oracle price for liquidations and liquidity
    /// providers redeeming their liquidity.
    function pausePrice() external view returns (int256);

    /// @notice Address of the amm this exchange calls to take the opposite of trades.
    function amm() external view returns (IAmm);

    /// @notice Changes a traders position in the exchange.
    /// @param deltaStable The amount of stable to change the position by.
    /// Positive values will add stable to the position (move stable token from the trader) into the exchange
    /// Negative values will remove stable from the position and send the trader tokens
    /// @param deltaAsset  The amount of asset the position should be changed by.
    /// @param stableBound The maximum/minimum amount of stable that the user is willing to pay/receive for the
    /// `deltaAsset` change.
    /// If the user is buying asset (deltaAsset > 0), the user will have to choose a maximum negative number that he is
    /// going to be in debt for.
    /// If the user is selling asset (deltaAsset < 0) the user will have to choose a minimum positive number of stable
    /// that he wants to be credited with.
    /// @return the payouts that need to be made, plus serialized of the `ChangePositionData` struct
    function changePosition(
        address trader,
        int256 deltaStable,
        int256 deltaAsset,
        int256 stableBound,
        int256 oraclePrice,
        uint256 time
    ) external returns (Payout[] memory, bytes memory);

    /// @notice Liquidates a trader's position.
    /// For a position to be liquidatable, it needs to either have less collateral (stable) left than
    /// ExchangeConfig.minCollateral or exceed a leverage higher than ExchangeConfig.maxLeverage.
    /// If this is a case, anyone can liquidate the position and receive a reward.
    /// @param trader The trader to liquidate.
    /// @return The needed payouts plus a serialized `ChangePositionData`.
    function liquidate(
        address trader,
        address liquidator,
        int256 oraclePrice,
        uint256 time
    ) external returns (Payout[] memory, bytes memory);

    /// @notice Position for a particular trader.
    /// @param trader The address to use for obtaining the position.
    /// @param price The oracle price at which to evaluate funding/
    /// @param time The time at which to evaluate the funding (0 means no funding).
    function getPosition(
        address trader,
        int256 price,
        uint256 time
    )
        external
        view
        returns (
            int256 asset,
            int256 stable,
            uint32 trancheIdx
        );

    /// @notice Returns the position of the AMM in the exchange.
    /// @param price The oracle price at which to evaluate funding.
    /// @param time The time at which to evaluate the funding (0 means no funding).
    function getAmmPosition(int256 price, uint256 time)
        external
        view
        returns (int256 stableAmount, int256 assetAmount);

    /// @notice Updates the config of the exchange, can only be performed by the voting executor.
    function setExchangeConfig(ExchangeConfig calldata _config) external;

    /// @notice Update the exchange state.
    /// Is used to PAUSE or STOP the exchange. When PAUSED, trades cannot open, liquidity cannot be added, and a
    /// fixed oracle price is set. When STOPPED no user actions can occur.
    function setExchangeState(ExchangeState _state, int256 _pausePrice) external;

    /// @notice Update the exchange hook.
    function setHook(address _hook) external;

    /// @notice Update the AMM used in the exchange.
    function setAmm(address _amm) external;

    /// @notice Update the TradeRouter authorized for this exchange.
    function setTradeRouter(address _tradeRouter) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

import "./IExchangeLedger.sol";

/// @notice IExchangeHook allows to plug a custom handler in the ExchangeLedger.changePosition() execution flow,
/// for example, to grant incentives. This pattern allows us to keep the ExchangeLedger simple, and extend its
/// functionality with a plugin model.
interface IExchangeHook {
    /// `onChangePosition` is called by the ExchangeLedger when there's a position change.
    function onChangePosition(IExchangeLedger.ChangePositionData calldata cpd) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/// @dev Contract module which provides a basic access control mechanism, where
/// there is an account (an owner) that can be granted exclusive access to
/// specific functions.
///
/// By default, the owner account will be the one that deploys the contract. This
/// can later be changed with {transferOwnership}.
///
/// This module is used through inheritance. It will make available the modifier
/// `onlyOwner`, which can be applied to your functions to restrict their use to
/// the owner.
abstract contract FsOwnable is Context {
    address private _owner;
    // We removed a field here, but we do not want to change a layout, as this contract is use as
    // abase by a lot of other contracts.
    // slither-disable-next-line unused-state,constable-states
    bool private ____unused1;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function initializeFsOwnable() internal {
        require(_owner == address(0), "Non zero owner");

        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /// @dev Returns the address of the current owner.
    function owner() public view returns (address) {
        return _owner;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) external virtual onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

/// @title An interface for interacting with oracles such as Chainlink, Uniswap V2/V3 TWAP, Band etc.
/// @notice This interface allows fetching prices for two tokens.
interface IOracle {
    /// @notice Address of the first token this oracle adapter supports.
    function token0() external view returns (address);

    /// @notice Address of the second token this oracle adapter supports.
    function token1() external view returns (address);

    /// @notice Returns the price of a supported token, relatively to the other token.
    function getPrice(address _token) external view returns (int256);
}