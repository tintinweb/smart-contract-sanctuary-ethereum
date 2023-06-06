// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { PRBMathSD59x18 } from "@prb-math/contracts/PRBMathSD59x18.sol";
import { Math }           from '@openzeppelin/contracts/utils/math/Math.sol';

import { PoolType } from '../../interfaces/pool/IPool.sol';

import {
    AuctionsState,
    Borrower,
    Bucket,
    BurnEvent,
    DepositsState,
    Liquidation,
    LoansState,
    PoolState,
    ReserveAuctionState
}                        from '../../interfaces/pool/commons/IPoolState.sol';
import {
    TakeResult
}                        from '../../interfaces/pool/commons/IPoolInternals.sol';

import {
    _auctionPrice,
    _bpf,
    _isCollateralized,
    _priceAt,
    _reserveAuctionPrice,
    _roundToScale
}                           from '../helpers/PoolHelper.sol';
import { _revertOnMinDebt } from '../helpers/RevertsHelper.sol';

import { SettlerActions } from './SettlerActions.sol';

import { Buckets }  from '../internal/Buckets.sol';
import { Deposits } from '../internal/Deposits.sol';
import { Loans }    from '../internal/Loans.sol';
import { Maths }    from '../internal/Maths.sol';

/**
    @title  Auction Taker Actions library
    @notice External library containing actions involving taking auctions within pool:
            - `take` and `bucketTake` auctioned collateral; take reserves
 */
library TakerActions {

    /*******************************/
    /*** Function Params Structs ***/
    /*******************************/

    /// @dev Struct used to hold `bucketTake` function params.
    struct BucketTakeParams {
        address borrower;        // borrower address to take from
        bool    depositTake;     // deposit or arb take, used by bucket take
        uint256 index;           // bucket index, used by bucket take
        uint256 inflator;        // [WAD] current pool inflator
        uint256 collateralScale; // precision of collateral token based on decimals
    }

    /// @dev Struct used to hold `take` function params.
    struct TakeParams {
        address borrower;        // borrower address to take from
        uint256 takeCollateral;  // [WAD] desired amount to take
        uint256 inflator;        // [WAD] current pool inflator
        uint256 poolType;        // pool type (ERC20 or NFT)
        uint256 collateralScale; // precision of collateral token based on decimals
    }

    /*************************/
    /*** Local Var Structs ***/
    /*************************/

    /// @dev Struct used for `take` function local vars.
    struct TakeLocalVars {
        uint256 auctionPrice;             // [WAD] The price of auction.
        uint256 bondChange;               // [WAD] The change made on the bond size (beeing reward or penalty).
        uint256 borrowerDebt;             // [WAD] The accrued debt of auctioned borrower.
        int256  bpf;                      // The bond penalty factor.
        uint256 bucketPrice;              // [WAD] The bucket price.
        uint256 bucketScale;              // [WAD] The bucket scale.
        uint256 collateralAmount;         // [WAD] The amount of collateral taken.
        uint256 excessQuoteToken;         // [WAD] Difference of quote token that borrower receives after take (for fractional NFT only)
        uint256 factor;                   // The take factor, calculated based on bond penalty factor.
        bool    isRewarded;               // True if kicker is rewarded (auction price lower than neutral price), false if penalized (auction price greater than neutral price).
        address kicker;                   // Address of auction kicker.
        uint256 quoteTokenAmount;         // [WAD] Scaled quantity in Fenwick tree and before 1-bpf factor, paid for collateral
        uint256 t0RepayAmount;            // [WAD] The amount of debt (quote tokens) that is recovered / repayed by take t0 terms.
        uint256 t0BorrowerDebt;           // [WAD] Borrower's t0 debt.
        uint256 t0DebtPenalty;            // [WAD] Borrower's t0 penalty - 7% from current debt if intial take, 0 otherwise.
        uint256 unscaledDeposit;          // [WAD] Unscaled bucket quantity
        uint256 unscaledQuoteTokenAmount; // [WAD] The unscaled token amount that taker should pay for collateral taken.
    }

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolEvents` for descriptions
    event BucketTake(address indexed borrower, uint256 index, uint256 amount, uint256 collateral, uint256 bondChange, bool isReward);
    event BucketTakeLPAwarded(address indexed taker, address indexed kicker, uint256 lpAwardedTaker, uint256 lpAwardedKicker);
    event Take(address indexed borrower, uint256 amount, uint256 collateral, uint256 bondChange, bool isReward);
    event ReserveAuction(uint256 claimableReservesRemaining, uint256 auctionPrice, uint256 currentBurnEpoch);

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error AuctionPriceGtBucketPrice();
    error CollateralRoundingNeededButNotPossible();
    error InsufficientLiquidity();
    error InsufficientCollateral();
    error InvalidAmount();
    error NoAuction();
    error NoReserves();
    error NoReservesAuction();
    error ReserveAuctionTooSoon();
    error TakeNotPastCooldown();

    /***************************/
    /***  External Functions ***/
    /***************************/

    /**
     *  @notice See `IPoolTakerActions` for descriptions.
     *  @notice Performs bucket take collateral on an auction, rewards taker and kicker (if case) and updates loan info (settles auction if case).
     *  @dev    === Reverts on ===
     *  @dev    not enough collateral to take `InsufficientCollateral()`
     *  @return result_ `TakeResult` struct containing details of bucket take result.
    */
    function bucketTake(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState storage loans_,
        PoolState memory poolState_,
        address borrowerAddress_,
        bool    depositTake_,
        uint256 index_,
        uint256 collateralScale_
    ) external returns (TakeResult memory result_) {
        Borrower memory borrower = loans_.borrowers[borrowerAddress_];
        // revert if borrower's collateral is 0
        if (borrower.collateral == 0) revert InsufficientCollateral();

        result_.debtPreAction       = borrower.t0Debt;
        result_.collateralPreAction = borrower.collateral;

        // bucket take auction
        TakeLocalVars memory vars = _takeBucket(
            auctions_,
            buckets_,
            deposits_,
            borrower,
            BucketTakeParams({
                borrower:        borrowerAddress_,
                inflator:        poolState_.inflator,
                depositTake:     depositTake_,
                index:           index_,
                collateralScale: collateralScale_
            })
        );

        // update borrower after take
        borrower.collateral -= vars.collateralAmount;
        borrower.t0Debt     = vars.t0BorrowerDebt - vars.t0RepayAmount;
        // update pool params after take
        poolState_.t0Debt += vars.t0DebtPenalty;
        poolState_.t0Debt -= vars.t0RepayAmount;
        poolState_.debt   = Maths.wmul(poolState_.t0Debt, poolState_.inflator);

        // update loan after take
        (
            result_.newLup,
            result_.settledAuction,
            result_.remainingCollateral,
            result_.compensatedCollateral
        ) = _takeLoan(auctions_, buckets_, deposits_, loans_, poolState_, borrower, borrowerAddress_);

        // complete take result struct
        result_.debtPostAction       = borrower.t0Debt;
        result_.collateralPostAction = borrower.collateral;
        result_.t0PoolDebt           = poolState_.t0Debt;
        result_.poolDebt             = poolState_.debt;
        result_.collateralAmount     = vars.collateralAmount;
        result_.t0DebtPenalty        = vars.t0DebtPenalty;
        // if settled then debt in auction changed is the entire borrower debt, otherwise only repaid amount
        result_.t0DebtInAuctionChange = result_.settledAuction ? vars.t0BorrowerDebt : vars.t0RepayAmount;
    }

    /**
     *  @notice See `IPoolTakerActions` for descriptions.
     *  @notice Performs take collateral on an auction, rewards taker and kicker (if case) and updates loan info (settles auction if case).
     *  @dev    === Reverts on ===
     *  @dev    insufficient collateral to take `InsufficientCollateral()`
     *  @return result_ `TakeResult` struct containing details of take result.
    */
    function take(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState storage loans_,
        PoolState memory poolState_,
        address borrowerAddress_,
        uint256 collateral_,
        uint256 collateralScale_
    ) external returns (TakeResult memory result_) {
        // revert if no amount to take
        if (collateral_ == 0) revert InvalidAmount();

        Borrower memory borrower = loans_.borrowers[borrowerAddress_];

        if (
            // revert in case of NFT take when there isn't a full token to be taken
            (poolState_.poolType == uint8(PoolType.ERC721) && borrower.collateral < 1e18) ||
            // revert in case of ERC20 take when no collateral to be taken
            (poolState_.poolType == uint8(PoolType.ERC20)  && borrower.collateral == 0)
        ) {
            revert InsufficientCollateral();
        }

        result_.debtPreAction       = borrower.t0Debt;
        result_.collateralPreAction = borrower.collateral;

        // take auction
        TakeLocalVars memory vars = _take(
            auctions_,
            borrower,
            TakeParams({
                borrower:        borrowerAddress_,
                takeCollateral:  collateral_,
                inflator:        poolState_.inflator,
                poolType:        poolState_.poolType,
                collateralScale: collateralScale_
            })
        );

        // update borrower after take
        borrower.collateral -= vars.collateralAmount;
        borrower.t0Debt     = vars.t0BorrowerDebt - vars.t0RepayAmount;
        // update pool params after take
        poolState_.t0Debt += vars.t0DebtPenalty;
        poolState_.t0Debt -= vars.t0RepayAmount;
        poolState_.debt   = Maths.wmul(poolState_.t0Debt, poolState_.inflator);

        // update loan after take
        (
            result_.newLup,
            result_.settledAuction,
            result_.remainingCollateral,
            result_.compensatedCollateral
        ) = _takeLoan(auctions_, buckets_, deposits_, loans_, poolState_, borrower, borrowerAddress_);

        // complete take result struct
        result_.debtPostAction       = borrower.t0Debt;
        result_.collateralPostAction = borrower.collateral;
        result_.t0PoolDebt           = poolState_.t0Debt;
        result_.poolDebt             = poolState_.debt;
        result_.collateralAmount     = vars.collateralAmount;
        result_.t0DebtPenalty        = vars.t0DebtPenalty;
        result_.quoteTokenAmount     = vars.quoteTokenAmount;
        result_.excessQuoteToken     = vars.excessQuoteToken;
        // if settled then debt in auction changed is the entire borrower debt, otherwise only repaid amount
        result_.t0DebtInAuctionChange = result_.settledAuction ? vars.t0BorrowerDebt : vars.t0RepayAmount;
    }

    /*************************/
    /***  Reserve Auction  ***/
    /*************************/

    /**
     *  @notice See `IPoolTakerActions` for descriptions.
     *  @dev    === Write state ===
     *  @dev    decrement `reserveAuction.unclaimed` accumulator
     *  @dev    === Reverts on ===
     *  @dev    not kicked or `72` hours didn't pass `NoReservesAuction()`
     *  @dev    === Emit events ===
     *  @dev    - `ReserveAuction`
     */
    function takeReserves(
        ReserveAuctionState storage reserveAuction_,
        uint256 maxAmount_
    ) external returns (uint256 amount_, uint256 ajnaRequired_) {
        // revert if no amount to be taken
        if (maxAmount_ == 0) revert InvalidAmount();

        uint256 kicked = reserveAuction_.kicked;

        if (kicked != 0 && block.timestamp - kicked <= 72 hours) {
            uint256 unclaimed = reserveAuction_.unclaimed;
            uint256 price     = _reserveAuctionPrice(kicked);

            amount_       = Maths.min(unclaimed, maxAmount_);
            ajnaRequired_ = Maths.ceilWmul(amount_, price);

            unclaimed -= amount_;

            reserveAuction_.unclaimed = unclaimed;

            uint256 totalBurned = reserveAuction_.totalAjnaBurned + ajnaRequired_;
            
            // accumulate additional ajna burned
            reserveAuction_.totalAjnaBurned = totalBurned;

            uint256 burnEventEpoch = reserveAuction_.latestBurnEventEpoch;

            // record burn event information to enable querying by staking rewards
            BurnEvent storage burnEvent = reserveAuction_.burnEvents[burnEventEpoch];
            burnEvent.totalInterest = reserveAuction_.totalInterestEarned;
            burnEvent.totalBurned   = totalBurned;

            emit ReserveAuction(
                unclaimed,
                price,
                burnEventEpoch
            );
        } else {
            revert NoReservesAuction();
        }
    }

    /**************************/
    /*** Internal Functions ***/
    /**************************/

    /**
     *  @notice Performs take collateral on an auction and updates bond size and kicker balance accordingly.
     *  @dev    === Emit events ===
     *  @dev    - `Take`
     *  @param  auctions_ Struct for pool auctions state.
     *  @param  borrower_ Struct containing auctioned borrower details.
     *  @param  params_   Struct containing take action params details.
     *  @return vars_     Struct containing auction take vars.
    */
    function _take(
        AuctionsState storage auctions_,
        Borrower memory borrower_,
        TakeParams memory params_
    ) internal returns (TakeLocalVars memory vars_) {
        Liquidation storage liquidation = auctions_.liquidations[params_.borrower];

        vars_ = _prepareTake(
            liquidation,
            borrower_.t0Debt,
            borrower_.collateral,
            params_.inflator
        );

        // These are placeholder max values passed to calculateTakeFlows because there is no explicit bound on the
        // quote token amount in take calls (as opposed to bucketTake)
        vars_.unscaledDeposit = type(uint256).max;
        vars_.bucketScale     = Maths.WAD;

        uint256 takeableCollateral = borrower_.collateral;
        // for NFT take make sure the take flow and bond change calculation happens for the rounded collateral that can be taken
        if (params_.poolType == uint8(PoolType.ERC721)) {
            takeableCollateral = (takeableCollateral / 1e18) * 1e18;
        }

        // In the case of take, the taker binds the collateral qty but not the quote token qty
        // ugly to get take work like a bucket take -- this is the max amount of quote token from the take that could go to
        // reduce the debt of the borrower -- analagous to the amount of deposit in the bucket for a bucket take
        vars_ = _calculateTakeFlowsAndBondChange(
            Maths.min(takeableCollateral, params_.takeCollateral),
            params_.inflator,
            params_.collateralScale,
            vars_
        );

        _rewardTake(auctions_, liquidation, vars_);

        emit Take(
            params_.borrower,
            vars_.quoteTokenAmount,
            vars_.collateralAmount,
            vars_.bondChange,
            vars_.isRewarded
        );

        if (params_.poolType == uint8(PoolType.ERC721)) {
            // slither-disable-next-line divide-before-multiply
            uint256 collateralTaken = (vars_.collateralAmount / 1e18) * 1e18; // solidity rounds down, so if 2.5 it will be 2.5 / 1 = 2

            // collateral taken not a round number
            if (collateralTaken != vars_.collateralAmount) {
                if (Maths.min(borrower_.collateral, params_.takeCollateral) >= collateralTaken + 1e18) {
                    // round up collateral to take
                    collateralTaken += 1e18;

                    // taker should send additional quote tokens to cover difference between collateral needed to be taken and rounded collateral, at auction price
                    // borrower will get quote tokens for the difference between rounded collateral and collateral taken to cover debt
                    vars_.excessQuoteToken = Maths.wmul(collateralTaken - vars_.collateralAmount, vars_.auctionPrice);
                    vars_.collateralAmount = collateralTaken;
                } else {
                    // shouldn't get here, but just in case revert
                    revert CollateralRoundingNeededButNotPossible();
                }
            }
        }
    }

    /**
     *  @notice Performs bucket take collateral on an auction and rewards taker and kicker (if case).
     *  @dev    === Emit events ===
     *  @dev    - `BucketTake`
     *  @param  auctions_ Struct for pool auctions state.
     *  @param  buckets_  Struct for pool buckets state.
     *  @param  deposits_ Struct for pool deposits state.
     *  @param  borrower_ Struct containing auctioned borrower details.
     *  @param  params_   Struct containing take action details.
     *  @return vars_     Struct containing auction take vars.
    */
    function _takeBucket(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        Borrower memory borrower_,
        BucketTakeParams memory params_
    ) internal returns (TakeLocalVars memory vars_) {
        Liquidation storage liquidation = auctions_.liquidations[params_.borrower];

        vars_= _prepareTake(
            liquidation,
            borrower_.t0Debt,
            borrower_.collateral,
            params_.inflator
        );

        vars_.unscaledDeposit = Deposits.unscaledValueAt(deposits_, params_.index);

        // revert if no quote tokens in arbed bucket
        if (vars_.unscaledDeposit == 0) revert InsufficientLiquidity();

        vars_.bucketPrice  = _priceAt(params_.index);

        // cannot arb with a price lower than the auction price
        if (vars_.auctionPrice > vars_.bucketPrice) revert AuctionPriceGtBucketPrice();
        
        // if deposit take then price to use when calculating take is bucket price
        if (params_.depositTake) vars_.auctionPrice = vars_.bucketPrice;

        vars_.bucketScale = Deposits.scale(deposits_, params_.index);

        vars_ = _calculateTakeFlowsAndBondChange(
            borrower_.collateral,
            params_.inflator,
            params_.collateralScale,
            vars_
        );

        // revert if bucket deposit cannot cover at least one unit of collateral
        if (vars_.collateralAmount == 0) revert InsufficientLiquidity();

        _rewardBucketTake(
            auctions_,
            deposits_,
            buckets_,
            liquidation,
            params_.index,
            params_.depositTake,
            vars_
        );

        emit BucketTake(
            params_.borrower,
            params_.index,
            vars_.quoteTokenAmount,
            vars_.collateralAmount,
            vars_.bondChange,
            vars_.isRewarded
        );
    }

    /**
     *  @notice Performs update of an auctioned loan that was taken (using bucket or regular take).
     *  @notice If borrower becomes recollateralized then auction is settled. Update loan's state.
     *  @dev    === Reverts on ===
     *  @dev    borrower debt less than pool min debt `AmountLTMinDebt()`
     *  @param  auctions_              Struct for pool auctions state.
     *  @param  buckets_               Struct for pool buckets state.
     *  @param  deposits_              Struct for pool deposits state.
     *  @param  loans_                 Struct for pool loans state.
     *  @param  poolState_             Struct containing pool details.
     *  @param  borrower_              The borrower details owning loan that is taken.
     *  @param  borrowerAddress_       The address of the borrower.
     *  @return newLup_                The new `LUP` of pool (after debt is repaid).
     *  @return settledAuction_        True if auction is settled by the take action. (`NFT` take: rebalance borrower collateral in pool if true)
     *  @return remainingCollateral_   Borrower collateral remaining after take action. (`NFT` take: collateral to be rebalanced in case of `NFT` settlement)
     *  @return compensatedCollateral_ Amount of collateral compensated, to be deducted from pool pledged collateral accumulator.
    */
    function _takeLoan(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState storage loans_,
        PoolState memory poolState_,
        Borrower memory borrower_,
        address borrowerAddress_
    ) internal returns (
        uint256 newLup_,
        bool settledAuction_,
        uint256 remainingCollateral_,
        uint256 compensatedCollateral_
    ) {

        uint256 borrowerDebt = Maths.wmul(borrower_.t0Debt, poolState_.inflator);

        // check that taking from loan doesn't leave borrower debt under min debt amount
        _revertOnMinDebt(
            loans_,
            poolState_.debt,
            borrowerDebt,
            poolState_.quoteTokenScale
        );

        // calculate new lup with repaid debt from take
        newLup_ = Deposits.getLup(deposits_, poolState_.debt);

        remainingCollateral_ = borrower_.collateral;

        if (_isCollateralized(borrowerDebt, borrower_.collateral, newLup_, poolState_.poolType)) {
            settledAuction_ = true;

            // settle auction and update borrower's collateral with value after settlement
            (remainingCollateral_, compensatedCollateral_) = SettlerActions._settleAuction(
                auctions_,
                buckets_,
                deposits_,
                borrowerAddress_,
                borrower_.collateral,
                poolState_.poolType
            );

            borrower_.collateral = remainingCollateral_;
        }

        // update loan state, stamp borrower t0Np only when exiting from auction
        Loans.update(
            loans_,
            auctions_,
            deposits_,
            borrower_,
            borrowerAddress_,
            poolState_.debt,
            poolState_.rate,
            newLup_,
            !settledAuction_,
            settledAuction_ // stamp borrower t0Np if exiting from auction
        );
    }

    /**
     *  @notice Rewards actors of a regular take action.
     *  @dev    === Write state ===
     *  @dev    update liquidation `bond size` accumulator
     *  @dev    update kicker's `locked balance` accumulator
     *  @dev    update `auctions.totalBondEscrowed` accumulator
     *  @param  auctions_     Struct for pool auctions state.
     *  @param  liquidation_  Struct containing details of auction.
     *  @param  vars          Struct containing take action result details.
     */
    function _rewardTake(
        AuctionsState storage auctions_,
        Liquidation storage liquidation_,
        TakeLocalVars memory vars
    ) internal {
        if (vars.isRewarded) {
            // take is below neutralPrice, Kicker is rewarded
            liquidation_.bondSize                 += uint160(vars.bondChange);
            auctions_.kickers[vars.kicker].locked += vars.bondChange;
            auctions_.totalBondEscrowed           += vars.bondChange;
        } else {
            // take is above neutralPrice, Kicker is penalized
            vars.bondChange = Maths.min(liquidation_.bondSize, vars.bondChange);

            liquidation_.bondSize                 -= uint160(vars.bondChange);
            auctions_.kickers[vars.kicker].locked -= vars.bondChange;
            auctions_.totalBondEscrowed           -= vars.bondChange;
        }
    }

    /**
     *  @notice Rewards actors of a bucket take action.
     *  @dev    === Write state ===
     *  @dev    - `Buckets.addLenderLP`:
     *  @dev      increment taker `lender.lps` accumulator and `lender.depositTime` state
     *  @dev      increment kicker `lender.lps` accumulator and l`ender.depositTime` state
     *  @dev    - update liquidation bond size accumulator
     *  @dev    - update kicker's locked balance accumulator
     *  @dev    - update `auctions.totalBondEscrowed` accumulator
     *  @dev    - `Deposits.unscaledRemove()` (remove amount in `Fenwick` tree, from index):
     *  @dev      update `values` array state
     *  @dev    - increment `bucket.collateral` and `bucket.lps` accumulator
     *  @dev    === Emit events ===
     *  @dev    - `BucketTakeLPAwarded`
     *  @param  auctions_     Struct for pool auctions state.
     *  @param  deposits_     Struct for pool deposits state.
     *  @param  buckets_      Struct for pool buckets state.
     *  @param  liquidation_  Struct containing details of auction to be taken from.
     *  @param  bucketIndex_  Index of a bucket, likely the `HPB`, in which collateral will be deposited.
     *  @param  depositTake_  If `true` then the take will happen at an auction price equal with bucket price. Auction price is used otherwise.
     *  @param  vars          Struct containing bucket take action result details.
     */
    function _rewardBucketTake(
        AuctionsState storage auctions_,
        DepositsState storage deposits_,
        mapping(uint256 => Bucket) storage buckets_,
        Liquidation storage liquidation_,
        uint256 bucketIndex_,
        bool depositTake_,
        TakeLocalVars memory vars
    ) internal {
        Bucket storage bucket = buckets_[bucketIndex_];

        uint256 bankruptcyTime = bucket.bankruptcyTime;
        uint256 scaledDeposit  = Maths.wmul(vars.unscaledDeposit, vars.bucketScale);
        uint256 totalLPReward;
        uint256 takerLPReward;
        uint256 kickerLPReward;

        // if arb take - taker is awarded collateral * (bucket price - auction price) worth (in quote token terms) units of LPB in the bucket
        if (!depositTake_) {
            takerLPReward = Buckets.quoteTokensToLP(
                bucket.collateral,
                bucket.lps,
                scaledDeposit,
                Maths.wmul(vars.collateralAmount, vars.bucketPrice - vars.auctionPrice),
                vars.bucketPrice,
                Math.Rounding.Down
            );
            totalLPReward = takerLPReward;

            Buckets.addLenderLP(bucket, bankruptcyTime, msg.sender, takerLPReward);
        }

        // the bondholder/kicker is awarded bond change worth of LPB in the bucket
        if (vars.isRewarded) {
            kickerLPReward = Buckets.quoteTokensToLP(
                bucket.collateral,
                bucket.lps,
                scaledDeposit,
                vars.bondChange,
                vars.bucketPrice,
                Math.Rounding.Down
            );
            totalLPReward  += kickerLPReward;

            Buckets.addLenderLP(bucket, bankruptcyTime, vars.kicker, kickerLPReward);
        } else {
            // take is above neutralPrice, Kicker is penalized
            vars.bondChange = Maths.min(liquidation_.bondSize, vars.bondChange);

            liquidation_.bondSize -= uint160(vars.bondChange);

            auctions_.kickers[vars.kicker].locked -= vars.bondChange;
            auctions_.totalBondEscrowed           -= vars.bondChange;
        }

        // remove quote tokens from bucket’s deposit
        Deposits.unscaledRemove(deposits_, bucketIndex_, vars.unscaledQuoteTokenAmount);

        // total rewarded LP are added to the bucket LP balance
        if (totalLPReward != 0) bucket.lps += totalLPReward;
        // collateral is added to the bucket’s claimable collateral
        bucket.collateral += vars.collateralAmount;

        emit BucketTakeLPAwarded(
            msg.sender,
            vars.kicker,
            takerLPReward,
            kickerLPReward
        );
    }

    /**
     *  @notice Utility function to validate take and calculate take's parameters.
     *  @dev    write state:
     *              - update liquidation.alreadyTaken state
     *  @dev    reverts on:
     *              - loan is not in auction NoAuction()
     *              - in 1 hour cool down period TakeNotPastCooldown()
     *  @param  liquidation_ Liquidation struct holding auction details.
     *  @param  t0Debt_      Borrower t0 debt.
     *  @param  collateral_  Borrower collateral.
     *  @param  inflator_    The pool's inflator, used to calculate borrower debt.
     *  @return vars         The prepared vars for take action.
     */
    function _prepareTake(
        Liquidation storage liquidation_,
        uint256 t0Debt_,
        uint256 collateral_,
        uint256 inflator_
    ) internal returns (TakeLocalVars memory vars) {

        uint256 kickTime = liquidation_.kickTime;
        if (kickTime == 0) revert NoAuction();
        if (block.timestamp - kickTime <= 1 hours) revert TakeNotPastCooldown();

        vars.t0BorrowerDebt = t0Debt_;

        // if first take borrower debt is increased by 7% penalty
        if (!liquidation_.alreadyTaken) {
            vars.t0DebtPenalty  = Maths.wmul(t0Debt_, 0.07 * 1e18);
            vars.t0BorrowerDebt += vars.t0DebtPenalty;

            liquidation_.alreadyTaken = true;
        }

        vars.borrowerDebt = Maths.wmul(vars.t0BorrowerDebt, inflator_);

        uint256 neutralPrice = liquidation_.neutralPrice;

        vars.auctionPrice = _auctionPrice(liquidation_.kickMomp, neutralPrice, kickTime);
        vars.bpf          = _bpf(
            vars.borrowerDebt,
            collateral_,
            neutralPrice,
            liquidation_.bondFactor,
            vars.auctionPrice
        );
        vars.factor       = uint256(1e18 - Maths.maxInt(0, vars.bpf));
        vars.kicker       = liquidation_.kicker;
        vars.isRewarded   = (vars.bpf  >= 0);
    }

    /**
     *  @notice Computes the flows of collateral, quote token between the borrower, lender and kicker.
     *  @param  totalCollateral_        Total collateral in loan.
     *  @param  inflator_               Current pool inflator.
     *  @param  vars                    TakeParams for the take/buckettake
     */
    function _calculateTakeFlowsAndBondChange(
        uint256              totalCollateral_,
        uint256              inflator_,
        uint256              collateralScale_,
        TakeLocalVars memory vars
    ) internal pure returns (
        TakeLocalVars memory
    ) {
        // price is the current auction price, which is the price paid by the LENDER for collateral
        // from the borrower point of view, the price is actually (1-bpf) * price, as the rewards to the
        // bond holder are effectively paid for by the borrower.
        uint256 borrowerPayoffFactor = (vars.isRewarded) ? Maths.WAD - uint256(vars.bpf)                       : Maths.WAD;
        uint256 borrowerPrice        = (vars.isRewarded) ? Maths.wmul(borrowerPayoffFactor, vars.auctionPrice) : vars.auctionPrice;

        // If there is no unscaled quote token bound, then we pass in max, but that cannot be scaled without an overflow.  So we check in the line below.
        vars.quoteTokenAmount = (vars.unscaledDeposit != type(uint256).max) ? Maths.wmul(vars.unscaledDeposit, vars.bucketScale) : type(uint256).max;

        uint256 borrowerCollateralValue = Maths.wmul(totalCollateral_, borrowerPrice);
        
        if (vars.quoteTokenAmount <= vars.borrowerDebt && vars.quoteTokenAmount <= borrowerCollateralValue) {
            // quote token used to purchase is constraining factor
            vars.collateralAmount         = _roundToScale(Maths.wdiv(vars.quoteTokenAmount, borrowerPrice), collateralScale_);
            vars.t0RepayAmount            = Maths.wdiv(vars.quoteTokenAmount, inflator_);
            vars.unscaledQuoteTokenAmount = vars.unscaledDeposit;

            vars.quoteTokenAmount         = Maths.wmul(vars.collateralAmount, vars.auctionPrice);

        } else if (vars.borrowerDebt <= borrowerCollateralValue) {
            // borrower debt is constraining factor
            vars.collateralAmount         = _roundToScale(Maths.wdiv(vars.borrowerDebt, borrowerPrice), collateralScale_);
            vars.t0RepayAmount            = vars.t0BorrowerDebt;
            vars.unscaledQuoteTokenAmount = Maths.wdiv(vars.borrowerDebt, vars.bucketScale);

            vars.quoteTokenAmount         = (vars.isRewarded) ? Maths.wdiv(vars.borrowerDebt, borrowerPayoffFactor) : vars.borrowerDebt;

        } else {
            // collateral available is constraint
            vars.collateralAmount         = totalCollateral_;
            vars.t0RepayAmount            = Maths.wdiv(borrowerCollateralValue, inflator_);
            vars.unscaledQuoteTokenAmount = Maths.wdiv(borrowerCollateralValue, vars.bucketScale);

            vars.quoteTokenAmount         = Maths.wmul(vars.collateralAmount, vars.auctionPrice);
        }

        if (vars.isRewarded) {
            // take is below neutralPrice, Kicker is rewarded
            vars.bondChange = Maths.wmul(vars.quoteTokenAmount, uint256(vars.bpf));
        } else {
            // take is above neutralPrice, Kicker is penalized
            vars.bondChange = Maths.wmul(vars.quoteTokenAmount, uint256(-vars.bpf));
        }

        return vars;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivFixedPointOverflow(uint256 prod1);

/// @notice Emitted when the result overflows uint256.
error PRBMath__MulDivOverflow(uint256 prod1, uint256 denominator);

/// @notice Emitted when one of the inputs is type(int256).min.
error PRBMath__MulDivSignedInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows int256.
error PRBMath__MulDivSignedOverflow(uint256 rAbs);

/// @notice Emitted when the input is MIN_SD59x18.
error PRBMathSD59x18__AbsInputTooSmall();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMathSD59x18__CeilOverflow(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__DivInputTooSmall();

/// @notice Emitted when one of the intermediary unsigned results overflows SD59x18.
error PRBMathSD59x18__DivOverflow(uint256 rAbs);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathSD59x18__ExpInputTooBig(int256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathSD59x18__Exp2InputTooBig(int256 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMathSD59x18__FloorUnderflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMathSD59x18__FromIntOverflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMathSD59x18__FromIntUnderflow(int256 x);

/// @notice Emitted when the product of the inputs is negative.
error PRBMathSD59x18__GmNegativeProduct(int256 x, int256 y);

/// @notice Emitted when multiplying the inputs overflows SD59x18.
error PRBMathSD59x18__GmOverflow(int256 x, int256 y);

/// @notice Emitted when the input is less than or equal to zero.
error PRBMathSD59x18__LogInputTooSmall(int256 x);

/// @notice Emitted when one of the inputs is MIN_SD59x18.
error PRBMathSD59x18__MulInputTooSmall();

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__MulOverflow(uint256 rAbs);

/// @notice Emitted when the intermediary absolute result overflows SD59x18.
error PRBMathSD59x18__PowuOverflow(uint256 rAbs);

/// @notice Emitted when the input is negative.
error PRBMathSD59x18__SqrtNegativeInput(int256 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMathSD59x18__SqrtOverflow(int256 x);

/// @notice Emitted when addition overflows UD60x18.
error PRBMathUD60x18__AddOverflow(uint256 x, uint256 y);

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMathUD60x18__CeilOverflow(uint256 x);

/// @notice Emitted when the input is greater than 133.084258667509499441.
error PRBMathUD60x18__ExpInputTooBig(uint256 x);

/// @notice Emitted when the input is greater than 192.
error PRBMathUD60x18__Exp2InputTooBig(uint256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format format overflows UD60x18.
error PRBMathUD60x18__FromUintOverflow(uint256 x);

/// @notice Emitted when multiplying the inputs overflows UD60x18.
error PRBMathUD60x18__GmOverflow(uint256 x, uint256 y);

/// @notice Emitted when the input is less than 1.
error PRBMathUD60x18__LogInputTooSmall(uint256 x);

/// @notice Emitted when the calculating the square root overflows UD60x18.
error PRBMathUD60x18__SqrtOverflow(uint256 x);

/// @notice Emitted when subtraction underflows UD60x18.
error PRBMathUD60x18__SubUnderflow(uint256 x, uint256 y);

/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
/// representation. When it does not, it is explicitly mentioned in the NatSpec documentation.
library PRBMath {
    /// STRUCTS ///

    struct SD59x18 {
        int256 value;
    }

    struct UD60x18 {
        uint256 value;
    }

    /// STORAGE ///

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @dev Largest power of two divisor of SCALE.
    uint256 internal constant SCALE_LPOTD = 262144;

    /// @dev SCALE inverted mod 2^256.
    uint256 internal constant SCALE_INVERSE =
        78156646155174841979727994598816262306175212592076161876661_508869554232690281;

    /// FUNCTIONS ///

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Has to use 192.64-bit fixed-point numbers.
    /// See https://ethereum.stackexchange.com/a/96594/24693.
    /// @param x The exponent as an unsigned 192.64-bit fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^191 and all magic factors are less than 2^65.
            if (x & 0x8000000000000000 > 0) {
                result = (result * 0x16A09E667F3BCC909) >> 64;
            }
            if (x & 0x4000000000000000 > 0) {
                result = (result * 0x1306FE0A31B7152DF) >> 64;
            }
            if (x & 0x2000000000000000 > 0) {
                result = (result * 0x1172B83C7D517ADCE) >> 64;
            }
            if (x & 0x1000000000000000 > 0) {
                result = (result * 0x10B5586CF9890F62A) >> 64;
            }
            if (x & 0x800000000000000 > 0) {
                result = (result * 0x1059B0D31585743AE) >> 64;
            }
            if (x & 0x400000000000000 > 0) {
                result = (result * 0x102C9A3E778060EE7) >> 64;
            }
            if (x & 0x200000000000000 > 0) {
                result = (result * 0x10163DA9FB33356D8) >> 64;
            }
            if (x & 0x100000000000000 > 0) {
                result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }
            if (x & 0x80000000000000 > 0) {
                result = (result * 0x10058C86DA1C09EA2) >> 64;
            }
            if (x & 0x40000000000000 > 0) {
                result = (result * 0x1002C605E2E8CEC50) >> 64;
            }
            if (x & 0x20000000000000 > 0) {
                result = (result * 0x100162F3904051FA1) >> 64;
            }
            if (x & 0x10000000000000 > 0) {
                result = (result * 0x1000B175EFFDC76BA) >> 64;
            }
            if (x & 0x8000000000000 > 0) {
                result = (result * 0x100058BA01FB9F96D) >> 64;
            }
            if (x & 0x4000000000000 > 0) {
                result = (result * 0x10002C5CC37DA9492) >> 64;
            }
            if (x & 0x2000000000000 > 0) {
                result = (result * 0x1000162E525EE0547) >> 64;
            }
            if (x & 0x1000000000000 > 0) {
                result = (result * 0x10000B17255775C04) >> 64;
            }
            if (x & 0x800000000000 > 0) {
                result = (result * 0x1000058B91B5BC9AE) >> 64;
            }
            if (x & 0x400000000000 > 0) {
                result = (result * 0x100002C5C89D5EC6D) >> 64;
            }
            if (x & 0x200000000000 > 0) {
                result = (result * 0x10000162E43F4F831) >> 64;
            }
            if (x & 0x100000000000 > 0) {
                result = (result * 0x100000B1721BCFC9A) >> 64;
            }
            if (x & 0x80000000000 > 0) {
                result = (result * 0x10000058B90CF1E6E) >> 64;
            }
            if (x & 0x40000000000 > 0) {
                result = (result * 0x1000002C5C863B73F) >> 64;
            }
            if (x & 0x20000000000 > 0) {
                result = (result * 0x100000162E430E5A2) >> 64;
            }
            if (x & 0x10000000000 > 0) {
                result = (result * 0x1000000B172183551) >> 64;
            }
            if (x & 0x8000000000 > 0) {
                result = (result * 0x100000058B90C0B49) >> 64;
            }
            if (x & 0x4000000000 > 0) {
                result = (result * 0x10000002C5C8601CC) >> 64;
            }
            if (x & 0x2000000000 > 0) {
                result = (result * 0x1000000162E42FFF0) >> 64;
            }
            if (x & 0x1000000000 > 0) {
                result = (result * 0x10000000B17217FBB) >> 64;
            }
            if (x & 0x800000000 > 0) {
                result = (result * 0x1000000058B90BFCE) >> 64;
            }
            if (x & 0x400000000 > 0) {
                result = (result * 0x100000002C5C85FE3) >> 64;
            }
            if (x & 0x200000000 > 0) {
                result = (result * 0x10000000162E42FF1) >> 64;
            }
            if (x & 0x100000000 > 0) {
                result = (result * 0x100000000B17217F8) >> 64;
            }
            if (x & 0x80000000 > 0) {
                result = (result * 0x10000000058B90BFC) >> 64;
            }
            if (x & 0x40000000 > 0) {
                result = (result * 0x1000000002C5C85FE) >> 64;
            }
            if (x & 0x20000000 > 0) {
                result = (result * 0x100000000162E42FF) >> 64;
            }
            if (x & 0x10000000 > 0) {
                result = (result * 0x1000000000B17217F) >> 64;
            }
            if (x & 0x8000000 > 0) {
                result = (result * 0x100000000058B90C0) >> 64;
            }
            if (x & 0x4000000 > 0) {
                result = (result * 0x10000000002C5C860) >> 64;
            }
            if (x & 0x2000000 > 0) {
                result = (result * 0x1000000000162E430) >> 64;
            }
            if (x & 0x1000000 > 0) {
                result = (result * 0x10000000000B17218) >> 64;
            }
            if (x & 0x800000 > 0) {
                result = (result * 0x1000000000058B90C) >> 64;
            }
            if (x & 0x400000 > 0) {
                result = (result * 0x100000000002C5C86) >> 64;
            }
            if (x & 0x200000 > 0) {
                result = (result * 0x10000000000162E43) >> 64;
            }
            if (x & 0x100000 > 0) {
                result = (result * 0x100000000000B1721) >> 64;
            }
            if (x & 0x80000 > 0) {
                result = (result * 0x10000000000058B91) >> 64;
            }
            if (x & 0x40000 > 0) {
                result = (result * 0x1000000000002C5C8) >> 64;
            }
            if (x & 0x20000 > 0) {
                result = (result * 0x100000000000162E4) >> 64;
            }
            if (x & 0x10000 > 0) {
                result = (result * 0x1000000000000B172) >> 64;
            }
            if (x & 0x8000 > 0) {
                result = (result * 0x100000000000058B9) >> 64;
            }
            if (x & 0x4000 > 0) {
                result = (result * 0x10000000000002C5D) >> 64;
            }
            if (x & 0x2000 > 0) {
                result = (result * 0x1000000000000162E) >> 64;
            }
            if (x & 0x1000 > 0) {
                result = (result * 0x10000000000000B17) >> 64;
            }
            if (x & 0x800 > 0) {
                result = (result * 0x1000000000000058C) >> 64;
            }
            if (x & 0x400 > 0) {
                result = (result * 0x100000000000002C6) >> 64;
            }
            if (x & 0x200 > 0) {
                result = (result * 0x10000000000000163) >> 64;
            }
            if (x & 0x100 > 0) {
                result = (result * 0x100000000000000B1) >> 64;
            }
            if (x & 0x80 > 0) {
                result = (result * 0x10000000000000059) >> 64;
            }
            if (x & 0x40 > 0) {
                result = (result * 0x1000000000000002C) >> 64;
            }
            if (x & 0x20 > 0) {
                result = (result * 0x10000000000000016) >> 64;
            }
            if (x & 0x10 > 0) {
                result = (result * 0x1000000000000000B) >> 64;
            }
            if (x & 0x8 > 0) {
                result = (result * 0x10000000000000006) >> 64;
            }
            if (x & 0x4 > 0) {
                result = (result * 0x10000000000000003) >> 64;
            }
            if (x & 0x2 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }
            if (x & 0x1 > 0) {
                result = (result * 0x10000000000000001) >> 64;
            }

            // We're doing two things at the same time:
            //
            //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
            //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
            //      rather than 192.
            //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
            //
            // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
            result *= SCALE;
            result >>= (191 - (x >> 64));
        }
    }

    /// @notice Finds the zero-based index of the first one in the binary representation of x.
    /// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
    /// @param x The uint256 number for which to find the index of the most significant bit.
    /// @return msb The index of the most significant bit as an uint256.
    function mostSignificantBit(uint256 x) internal pure returns (uint256 msb) {
        if (x >= 2**128) {
            x >>= 128;
            msb += 128;
        }
        if (x >= 2**64) {
            x >>= 64;
            msb += 64;
        }
        if (x >= 2**32) {
            x >>= 32;
            msb += 32;
        }
        if (x >= 2**16) {
            x >>= 16;
            msb += 16;
        }
        if (x >= 2**8) {
            x >>= 8;
            msb += 8;
        }
        if (x >= 2**4) {
            x >>= 4;
            msb += 4;
        }
        if (x >= 2**2) {
            x >>= 2;
            msb += 2;
        }
        if (x >= 2**1) {
            // No need to shift x any more.
            msb += 1;
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2^256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division.
        if (prod1 == 0) {
            unchecked {
                result = prod0 / denominator;
            }
            return result;
        }

        // Make sure the result is less than 2^256. Also prevents denominator == 0.
        if (prod1 >= denominator) {
            revert PRBMath__MulDivOverflow(prod1, denominator);
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number.
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2^256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /// @notice Calculates floor(x*y÷1e18) with full precision.
    ///
    /// @dev Variant of "mulDiv" with constant folding, i.e. in which the denominator is always 1e18. Before returning the
    /// final result, we add 1 if (x * y) % SCALE >= HALF_SCALE. Without this, 6.6e-19 would be truncated to 0 instead of
    /// being rounded to 1e-18.  See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
    ///
    /// Requirements:
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    /// - It is assumed that the result can never be type(uint256).max when x and y solve the following two equations:
    ///     1. x * y = type(uint256).max * SCALE
    ///     2. (x * y) % SCALE >= SCALE / 2
    ///
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function mulDivFixedPoint(uint256 x, uint256 y) internal pure returns (uint256 result) {
        uint256 prod0;
        uint256 prod1;
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        if (prod1 >= SCALE) {
            revert PRBMath__MulDivFixedPointOverflow(prod1);
        }

        uint256 remainder;
        uint256 roundUpUnit;
        assembly {
            remainder := mulmod(x, y, SCALE)
            roundUpUnit := gt(remainder, 499999999999999999)
        }

        if (prod1 == 0) {
            unchecked {
                result = (prod0 / SCALE) + roundUpUnit;
                return result;
            }
        }

        assembly {
            result := add(
                mul(
                    or(
                        div(sub(prod0, remainder), SCALE_LPOTD),
                        mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, SCALE_LPOTD), SCALE_LPOTD), 1))
                    ),
                    SCALE_INVERSE
                ),
                roundUpUnit
            )
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev An extension of "mulDiv" for signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - None of the inputs can be type(int256).min.
    /// - The result must fit within int256.
    ///
    /// @param x The multiplicand as an int256.
    /// @param y The multiplier as an int256.
    /// @param denominator The divisor as an int256.
    /// @return result The result as an int256.
    function mulDivSigned(
        int256 x,
        int256 y,
        int256 denominator
    ) internal pure returns (int256 result) {
        if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
            revert PRBMath__MulDivSignedInputTooSmall();
        }

        // Get hold of the absolute values of x, y and the denominator.
        uint256 ax;
        uint256 ay;
        uint256 ad;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
            ad = denominator < 0 ? uint256(-denominator) : uint256(denominator);
        }

        // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
        uint256 rAbs = mulDiv(ax, ay, ad);
        if (rAbs > uint256(type(int256).max)) {
            revert PRBMath__MulDivSignedOverflow(rAbs);
        }

        // Get the signs of x, y and the denominator.
        uint256 sx;
        uint256 sy;
        uint256 sd;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
            sd := sgt(denominator, sub(0, 1))
        }

        // XOR over sx, sy and sd. This is checking whether there are one or three negative signs in the inputs.
        // If yes, the result should be negative.
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 0x8) {
            result <<= 1;
        }

        // The operations can never overflow because the result is max 2^127 when it enters this block.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1; // Seven iterations should be enough
            uint256 roundedDownResult = x / result;
            return result >= roundedDownResult ? roundedDownResult : result;
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathSD59x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with int256 numbers considered to have 18
/// trailing decimals. We call this number representation signed 59.18-decimal fixed-point, since the numbers can have
/// a sign and there can be up to 59 digits in the integer part and up to 18 decimals in the fractional part. The numbers
/// are bound by the minimum and the maximum values permitted by the Solidity type int256.
library PRBMathSD59x18 {
    /// @dev log2(e) as a signed 59.18-decimal fixed-point number.
    int256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev Half the SCALE number.
    int256 internal constant HALF_SCALE = 5e17;

    /// @dev The maximum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_792003956564819967;

    /// @dev The maximum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MAX_WHOLE_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev The minimum value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_792003956564819968;

    /// @dev The minimum whole value a signed 59.18-decimal fixed-point number can have.
    int256 internal constant MIN_WHOLE_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    int256 internal constant SCALE = 1e18;

    /// INTERNAL FUNCTIONS ///

    /// @notice Calculate the absolute value of x.
    ///
    /// @dev Requirements:
    /// - x must be greater than MIN_SD59x18.
    ///
    /// @param x The number to calculate the absolute value for.
    /// @param result The absolute value of x.
    function abs(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x == MIN_SD59x18) {
                revert PRBMathSD59x18__AbsInputTooSmall();
            }
            result = x < 0 ? -x : x;
        }
    }

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The arithmetic average as a signed 59.18-decimal fixed-point number.
    function avg(int256 x, int256 y) internal pure returns (int256 result) {
        // The operations can never overflow.
        unchecked {
            int256 sum = (x >> 1) + (y >> 1);
            if (sum < 0) {
                // If at least one of x and y is odd, we add 1 to the result. This is because shifting negative numbers to the
                // right rounds down to infinity.
                assembly {
                    result := add(sum, and(or(x, y), 1))
                }
            } else {
                // If both x and y are odd, we add 1 to the result. This is because if both numbers are odd, the 0.5
                // remainder gets truncated twice.
                result = sum + (x & y & 1);
            }
        }
    }

    /// @notice Yields the least greatest signed 59.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as a signed 58.18-decimal fixed-point number.
    function ceil(int256 x) internal pure returns (int256 result) {
        if (x > MAX_WHOLE_SD59x18) {
            revert PRBMathSD59x18__CeilOverflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x > 0) {
                    result += SCALE;
                }
            }
        }
    }

    /// @notice Divides two signed 59.18-decimal fixed-point numbers, returning a new signed 59.18-decimal fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers. Works by computing the signs and the absolute values separately.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDiv".
    /// - None of the inputs can be MIN_SD59x18.
    /// - The denominator cannot be zero.
    /// - The result must fit within int256.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDiv".
    ///
    /// @param x The numerator as a signed 59.18-decimal fixed-point number.
    /// @param y The denominator as a signed 59.18-decimal fixed-point number.
    /// @param result The quotient as a signed 59.18-decimal fixed-point number.
    function div(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__DivInputTooSmall();
        }

        // Get hold of the absolute values of x and y.
        uint256 ax;
        uint256 ay;
        unchecked {
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);
        }

        // Compute the absolute value of (x*SCALE)÷y. The result must fit within int256.
        uint256 rAbs = PRBMath.mulDiv(ax, uint256(SCALE), ay);
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__DivOverflow(rAbs);
        }

        // Get the signs of x and y.
        uint256 sx;
        uint256 sy;
        assembly {
            sx := sgt(x, sub(0, 1))
            sy := sgt(y, sub(0, 1))
        }

        // XOR over sx and sy. This is basically checking whether the inputs have the same sign. If yes, the result
        // should be positive. Otherwise, it should be negative.
        result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns Euler's number as a signed 59.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (int256 result) {
        result = 2_718281828459045235;
    }

    /// @notice Calculates the natural exponent of x.
    ///
    /// @dev Based on the insight that e^x = 2^(x * log2(e)).
    ///
    /// Requirements:
    /// - All from "log2".
    /// - x must be less than 133.084258667509499441.
    ///
    /// Caveats:
    /// - All from "exp2".
    /// - For any x less than -41.446531673892822322, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp(int256 x) internal pure returns (int256 result) {
        // Without this check, the value passed to "exp2" would be less than -59.794705707972522261.
        if (x < -41_446531673892822322) {
            return 0;
        }

        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathSD59x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            int256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - For any x less than -59.794705707972522261, the result is zero.
    ///
    /// @param x The exponent as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function exp2(int256 x) internal pure returns (int256 result) {
        // This works because 2^(-x) = 1/2^x.
        if (x < 0) {
            // 2^59.794705707972522262 is the maximum number whose inverse does not truncate down to zero.
            if (x < -59_794705707972522261) {
                return 0;
            }

            // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
            unchecked {
                result = 1e36 / exp2(-x);
            }
        } else {
            // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
            if (x >= 192e18) {
                revert PRBMathSD59x18__Exp2InputTooBig(x);
            }

            unchecked {
                // Convert x to the 192.64-bit fixed-point format.
                uint256 x192x64 = (uint256(x) << 64) / uint256(SCALE);

                // Safe to convert the result to int256 directly because the maximum input allowed is 192.
                result = int256(PRBMath.exp2(x192x64));
            }
        }
    }

    /// @notice Yields the greatest signed 59.18 decimal fixed-point number less than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be greater than or equal to MIN_WHOLE_SD59x18.
    ///
    /// @param x The signed 59.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as a signed 58.18-decimal fixed-point number.
    function floor(int256 x) internal pure returns (int256 result) {
        if (x < MIN_WHOLE_SD59x18) {
            revert PRBMathSD59x18__FloorUnderflow(x);
        }
        unchecked {
            int256 remainder = x % SCALE;
            if (remainder == 0) {
                result = x;
            } else {
                // Solidity uses C fmod style, which returns a modulus with the same sign as x.
                result = x - remainder;
                if (x < 0) {
                    result -= SCALE;
                }
            }
        }
    }

    /// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right
    /// of the radix point for negative numbers.
    /// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
    /// @param x The signed 59.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as a signed 59.18-decimal fixed-point number.
    function frac(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x % SCALE;
        }
    }

    /// @notice Converts a number from basic integer form to signed 59.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be greater than or equal to MIN_SD59x18 divided by SCALE.
    /// - x must be less than or equal to MAX_SD59x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in signed 59.18-decimal fixed-point representation.
    function fromInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < MIN_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntUnderflow(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__FromIntOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_SD59x18, lest it overflows.
    /// - x * y cannot be negative.
    ///
    /// @param x The first operand as a signed 59.18-decimal fixed-point number.
    /// @param y The second operand as a signed 59.18-decimal fixed-point number.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function gm(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            int256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathSD59x18__GmOverflow(x, y);
            }

            // The product cannot be negative.
            if (xy < 0) {
                revert PRBMathSD59x18__GmNegativeProduct(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = int256(PRBMath.sqrt(uint256(xy)));
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as a signed 59.18-decimal fixed-point number.
    function inv(int256 x) internal pure returns (int256 result) {
        unchecked {
            // 1e36 is SCALE * SCALE.
            result = 1e36 / x;
        }
    }

    /// @notice Calculates the natural logarithm of x.
    ///
    /// @dev Based on the insight that ln(x) = log2(x) / log2(e).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    /// - This doesn't return exactly 1 for 2718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as a signed 59.18-decimal fixed-point number.
    function ln(int256 x) internal pure returns (int256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 195205294292027477728.
        unchecked {
            result = (log2(x) * SCALE) / LOG2_E;
        }
    }

    /// @notice Calculates the common logarithm of x.
    ///
    /// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
    /// logarithm based on the insight that log10(x) = log2(x) / log2(10).
    ///
    /// Requirements:
    /// - All from "log2".
    ///
    /// Caveats:
    /// - All from "log2".
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as a signed 59.18-decimal fixed-point number.
    function log10(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly mul operation, not the "mul" function defined in this contract.
        // prettier-ignore
        assembly {
            switch x
            case 1 { result := mul(SCALE, sub(0, 18)) }
            case 10 { result := mul(SCALE, sub(1, 18)) }
            case 100 { result := mul(SCALE, sub(2, 18)) }
            case 1000 { result := mul(SCALE, sub(3, 18)) }
            case 10000 { result := mul(SCALE, sub(4, 18)) }
            case 100000 { result := mul(SCALE, sub(5, 18)) }
            case 1000000 { result := mul(SCALE, sub(6, 18)) }
            case 10000000 { result := mul(SCALE, sub(7, 18)) }
            case 100000000 { result := mul(SCALE, sub(8, 18)) }
            case 1000000000 { result := mul(SCALE, sub(9, 18)) }
            case 10000000000 { result := mul(SCALE, sub(10, 18)) }
            case 100000000000 { result := mul(SCALE, sub(11, 18)) }
            case 1000000000000 { result := mul(SCALE, sub(12, 18)) }
            case 10000000000000 { result := mul(SCALE, sub(13, 18)) }
            case 100000000000000 { result := mul(SCALE, sub(14, 18)) }
            case 1000000000000000 { result := mul(SCALE, sub(15, 18)) }
            case 10000000000000000 { result := mul(SCALE, sub(16, 18)) }
            case 100000000000000000 { result := mul(SCALE, sub(17, 18)) }
            case 1000000000000000000 { result := 0 }
            case 10000000000000000000 { result := SCALE }
            case 100000000000000000000 { result := mul(SCALE, 2) }
            case 1000000000000000000000 { result := mul(SCALE, 3) }
            case 10000000000000000000000 { result := mul(SCALE, 4) }
            case 100000000000000000000000 { result := mul(SCALE, 5) }
            case 1000000000000000000000000 { result := mul(SCALE, 6) }
            case 10000000000000000000000000 { result := mul(SCALE, 7) }
            case 100000000000000000000000000 { result := mul(SCALE, 8) }
            case 1000000000000000000000000000 { result := mul(SCALE, 9) }
            case 10000000000000000000000000000 { result := mul(SCALE, 10) }
            case 100000000000000000000000000000 { result := mul(SCALE, 11) }
            case 1000000000000000000000000000000 { result := mul(SCALE, 12) }
            case 10000000000000000000000000000000 { result := mul(SCALE, 13) }
            case 100000000000000000000000000000000 { result := mul(SCALE, 14) }
            case 1000000000000000000000000000000000 { result := mul(SCALE, 15) }
            case 10000000000000000000000000000000000 { result := mul(SCALE, 16) }
            case 100000000000000000000000000000000000 { result := mul(SCALE, 17) }
            case 1000000000000000000000000000000000000 { result := mul(SCALE, 18) }
            case 10000000000000000000000000000000000000 { result := mul(SCALE, 19) }
            case 100000000000000000000000000000000000000 { result := mul(SCALE, 20) }
            case 1000000000000000000000000000000000000000 { result := mul(SCALE, 21) }
            case 10000000000000000000000000000000000000000 { result := mul(SCALE, 22) }
            case 100000000000000000000000000000000000000000 { result := mul(SCALE, 23) }
            case 1000000000000000000000000000000000000000000 { result := mul(SCALE, 24) }
            case 10000000000000000000000000000000000000000000 { result := mul(SCALE, 25) }
            case 100000000000000000000000000000000000000000000 { result := mul(SCALE, 26) }
            case 1000000000000000000000000000000000000000000000 { result := mul(SCALE, 27) }
            case 10000000000000000000000000000000000000000000000 { result := mul(SCALE, 28) }
            case 100000000000000000000000000000000000000000000000 { result := mul(SCALE, 29) }
            case 1000000000000000000000000000000000000000000000000 { result := mul(SCALE, 30) }
            case 10000000000000000000000000000000000000000000000000 { result := mul(SCALE, 31) }
            case 100000000000000000000000000000000000000000000000000 { result := mul(SCALE, 32) }
            case 1000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 33) }
            case 10000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 34) }
            case 100000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 35) }
            case 1000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 36) }
            case 10000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 37) }
            case 100000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 38) }
            case 1000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 39) }
            case 10000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 40) }
            case 100000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 41) }
            case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 42) }
            case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 43) }
            case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 44) }
            case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 45) }
            case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 46) }
            case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 47) }
            case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 48) }
            case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 49) }
            case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 50) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 51) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 52) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 53) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 54) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 55) }
            case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 56) }
            case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 57) }
            case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 58) }
            default {
                result := MAX_SD59x18
            }
        }

        if (result == MAX_SD59x18) {
            // Do the fixed-point division inline to save gas. The denominator is log2(10).
            unchecked {
                result = (log2(x) * SCALE) / 3_321928094887362347;
            }
        }
    }

    /// @notice Calculates the binary logarithm of x.
    ///
    /// @dev Based on the iterative approximation algorithm.
    /// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
    ///
    /// Requirements:
    /// - x must be greater than zero.
    ///
    /// Caveats:
    /// - The results are not perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as a signed 59.18-decimal fixed-point number.
    function log2(int256 x) internal pure returns (int256 result) {
        if (x <= 0) {
            revert PRBMathSD59x18__LogInputTooSmall(x);
        }
        unchecked {
            // This works because log2(x) = -log2(1/x).
            int256 sign;
            if (x >= SCALE) {
                sign = 1;
            } else {
                sign = -1;
                // Do the fixed-point inversion inline to save gas. The numerator is SCALE * SCALE.
                assembly {
                    x := div(1000000000000000000000000000000000000, x)
                }
            }

            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(uint256(x / SCALE));

            // The integer part of the logarithm as a signed 59.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255, SCALE is 1e18 and sign is either 1 or -1.
            result = int256(n) * SCALE;

            // This is y = x * 2^(-n).
            int256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result * sign;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (int256 delta = int256(HALF_SCALE); delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
            result *= sign;
        }
    }

    /// @notice Multiplies two signed 59.18-decimal fixed-point numbers together, returning a new signed 59.18-decimal
    /// fixed-point number.
    ///
    /// @dev Variant of "mulDiv" that works with signed numbers and employs constant folding, i.e. the denominator is
    /// always 1e18.
    ///
    /// Requirements:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - None of the inputs can be MIN_SD59x18
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - The body is purposely left uncommented; see the NatSpec comments in "PRBMath.mulDiv" to understand how this works.
    ///
    /// @param x The multiplicand as a signed 59.18-decimal fixed-point number.
    /// @param y The multiplier as a signed 59.18-decimal fixed-point number.
    /// @return result The product as a signed 59.18-decimal fixed-point number.
    function mul(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == MIN_SD59x18 || y == MIN_SD59x18) {
            revert PRBMathSD59x18__MulInputTooSmall();
        }

        unchecked {
            uint256 ax;
            uint256 ay;
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);

            uint256 rAbs = PRBMath.mulDivFixedPoint(ax, ay);
            if (rAbs > uint256(MAX_SD59x18)) {
                revert PRBMathSD59x18__MulOverflow(rAbs);
            }

            uint256 sx;
            uint256 sy;
            assembly {
                sx := sgt(x, sub(0, 1))
                sy := sgt(y, sub(0, 1))
            }
            result = sx ^ sy == 1 ? -int256(rAbs) : int256(rAbs);
        }
    }

    /// @notice Returns PI as a signed 59.18-decimal fixed-point number.
    function pi() internal pure returns (int256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    /// - z cannot be zero.
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as a signed 59.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as a signed 59.18-decimal fixed-point number.
    /// @return result x raised to power y, as a signed 59.18-decimal fixed-point number.
    function pow(int256 x, int256 y) internal pure returns (int256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : int256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (signed 59.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - All from "abs" and "PRBMath.mulDivFixedPoint".
    /// - The result must fit within MAX_SD59x18.
    ///
    /// Caveats:
    /// - All from "PRBMath.mulDivFixedPoint".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as a signed 59.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as a signed 59.18-decimal fixed-point number.
    function powu(int256 x, uint256 y) internal pure returns (int256 result) {
        uint256 xAbs = uint256(abs(x));

        // Calculate the first iteration of the loop in advance.
        uint256 rAbs = y & 1 > 0 ? xAbs : uint256(SCALE);

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        uint256 yAux = y;
        for (yAux >>= 1; yAux > 0; yAux >>= 1) {
            xAbs = PRBMath.mulDivFixedPoint(xAbs, xAbs);

            // Equivalent to "y % 2 == 1" but faster.
            if (yAux & 1 > 0) {
                rAbs = PRBMath.mulDivFixedPoint(rAbs, xAbs);
            }
        }

        // The result must fit within the 59.18-decimal fixed-point representation.
        if (rAbs > uint256(MAX_SD59x18)) {
            revert PRBMathSD59x18__PowuOverflow(rAbs);
        }

        // Is the base negative and the exponent an odd number?
        bool isNegative = x < 0 && y & 1 == 1;
        result = isNegative ? -int256(rAbs) : int256(rAbs);
    }

    /// @notice Returns 1 as a signed 59.18-decimal fixed-point number.
    function scale() internal pure returns (int256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x cannot be negative.
    /// - x must be less than MAX_SD59x18 / SCALE.
    ///
    /// @param x The signed 59.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as a signed 59.18-decimal fixed-point .
    function sqrt(int256 x) internal pure returns (int256 result) {
        unchecked {
            if (x < 0) {
                revert PRBMathSD59x18__SqrtNegativeInput(x);
            }
            if (x > MAX_SD59x18 / SCALE) {
                revert PRBMathSD59x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two signed
            // 59.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = int256(PRBMath.sqrt(uint256(x * SCALE)));
        }
    }

    /// @notice Converts a signed 59.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The signed 59.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toInt(int256 x) internal pure returns (int256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IERC3156FlashBorrower {

    /**
     * @dev    Receive a flash loan.
     * @param  initiator The initiator of the loan.
     * @param  token     The loan currency.
     * @param  amount    The amount of tokens lent (token precision).
     * @param  fee       The additional amount of tokens to repay.
     * @param  data      Arbitrary data structure, intended to contain user-defined parameters.
     * @return The `keccak256` hash of `ERC3156FlashBorrower.onFlashLoan`
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes   calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
import { IERC3156FlashBorrower } from "./IERC3156FlashBorrower.sol";


interface IERC3156FlashLender {

    /**
     * @dev    The amount of currency available to be lent.
     * @param  token_ The loan currency.
     * @return The amount of `token` that can be borrowed (token precision).
     */
    function maxFlashLoan(
        address token_
    ) external view returns (uint256);

    /**
     * @dev    The fee to be charged for a given loan.
     * @param  token_    The loan currency.
     * @param  amount_   The amount of tokens lent (token precision).
     * @return The amount of `token` to be charged for the loan (token precision), on top of the returned principal .
     */
    function flashFee(
        address token_,
        uint256 amount_
    ) external view returns (uint256);

    /**
     * @dev    Initiate a flash loan.
     * @param  receiver_ The receiver of the tokens in the loan, and the receiver of the callback.
     * @param  token_    The loan currency.
     * @param  amount_   The amount of tokens lent (token precision).
     * @param  data_     Arbitrary data structure, intended to contain user-defined parameters.
     * @return `True` when successful flashloan, `false` otherwise.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver_,
        address token_,
        uint256 amount_,
        bytes   calldata data_
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import { IPoolBorrowerActions } from './commons/IPoolBorrowerActions.sol';
import { IPoolLPActions }       from './commons/IPoolLPActions.sol';
import { IPoolLenderActions }   from './commons/IPoolLenderActions.sol';
import { IPoolKickerActions }   from './commons/IPoolKickerActions.sol';
import { IPoolTakerActions }    from './commons/IPoolTakerActions.sol';
import { IPoolSettlerActions }  from './commons/IPoolSettlerActions.sol';

import { IPoolImmutables }      from './commons/IPoolImmutables.sol';
import { IPoolState }           from './commons/IPoolState.sol';
import { IPoolDerivedState }    from './commons/IPoolDerivedState.sol';
import { IPoolEvents }          from './commons/IPoolEvents.sol';
import { IPoolErrors }          from './commons/IPoolErrors.sol';
import { IERC3156FlashLender }  from './IERC3156FlashLender.sol';

/**
 * @title Base Pool Interface
 */
interface IPool is
    IPoolBorrowerActions,
    IPoolLPActions,
    IPoolLenderActions,
    IPoolKickerActions,
    IPoolTakerActions,
    IPoolSettlerActions,
    IPoolImmutables,
    IPoolState,
    IPoolDerivedState,
    IPoolEvents,
    IPoolErrors,
    IERC3156FlashLender
{

}

/// @dev Pool type enum - `ERC20` and `ERC721`
enum PoolType { ERC20, ERC721 }

/// @dev `ERC20` token interface.
interface IERC20Token {
    function balanceOf(address account) external view returns (uint256);
    function burn(uint256 amount) external;
    function decimals() external view returns (uint8);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

/// @dev `ERC721` token interface.
interface IERC721Token {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Borrower Actions
 */
interface IPoolBorrowerActions {

    /**
     *  @notice Called by fully colalteralized borrowers to restamp the `Neutral Price` of the loan (only if loan is fully collateralized and not in auction).
     *          The reason for stamping the neutral price on the loan is to provide some certainty to the borrower as to at what price they can expect to be liquidated.
     *          This action can restamp only the loan of `msg.sender`.
     */
    function stampLoan() external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Derived State
 */
interface IPoolDerivedState {

    /**
     *  @notice Returns the exchange rate for a given bucket index.
     *  @param  index_        The bucket index.
     *  @return exchangeRate_ Exchange rate of the bucket (`WAD` precision).
     */
    function bucketExchangeRate(
        uint256 index_
    ) external view returns (uint256 exchangeRate_);

    /**
     *  @notice Returns the prefix sum of a given bucket.
     *  @param  index_   The bucket index.
     *  @return The deposit up to given index (`WAD` precision).
     */
    function depositUpToIndex(
        uint256 index_
    ) external view returns (uint256);

    /**
     *  @notice Returns the bucket index for a given debt amount.
     *  @param  debt_  The debt amount to calculate bucket index for (`WAD` precision).
     *  @return Bucket index.
     */
    function depositIndex(
        uint256 debt_
    ) external view returns (uint256);

    /**
     *  @notice Returns the total amount of quote tokens deposited in pool.
     *  @return Total amount of deposited quote tokens (`WAD` precision).
     */
    function depositSize() external view returns (uint256);

    /**
     *  @notice Returns the meaningful actual utilization of the pool.
     *  @return Deposit utilization (`WAD` precision).
     */
    function depositUtilization() external view returns (uint256);

    /**
     *  @notice Returns the scaling value of deposit at given index.
     *  @param  index_  Deposit index.
     *  @return Deposit scaling (`WAD` precision).
     */
    function depositScale(
        uint256 index_
    ) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Errors.
 */
interface IPoolErrors {
    /**************************/
    /*** Common Pool Errors ***/
    /**************************/

    /**
     *  @notice `LP` allowance is already set by the owner.
     */
    error AllowanceAlreadySet();

    /**
     *  @notice The action cannot be executed on an active auction.
     */
    error AuctionActive();

    /**
     *  @notice Attempted auction to clear doesn't meet conditions.
     */
    error AuctionNotClearable();

    /**
     *  @notice Head auction should be cleared prior of executing this action.
     */
    error AuctionNotCleared();

    /**
     *  @notice The auction price is greater than the arbed bucket price.
     */
    error AuctionPriceGtBucketPrice();

    /**
     *  @notice Pool already initialized.
     */
    error AlreadyInitialized();

    /**
     *  @notice Borrower is attempting to create or modify a loan such that their loan's quote token would be less than the pool's minimum debt amount.
     */
    error AmountLTMinDebt();

    /**
     *  @notice Recipient of borrowed quote tokens doesn't match the caller of the `drawDebt` function.
     */
    error BorrowerNotSender();

    /**
     *  @notice Borrower has a healthy over-collateralized position.
     */
    error BorrowerOk();

    /**
     *  @notice Borrower is attempting to borrow more quote token than they have collateral for.
     */
    error BorrowerUnderCollateralized();

    /**
     *  @notice Operation cannot be executed in the same block when bucket becomes insolvent.
     */
    error BucketBankruptcyBlock();

    /**
     *  @notice User attempted to merge collateral from a lower price bucket into a higher price bucket.
     */
    error CannotMergeToHigherPrice();

    /**
     *  @notice User attempted an operation which does not exceed the dust amount, or leaves behind less than the dust amount.
     */
    error DustAmountNotExceeded();

    /**
     *  @notice Callback invoked by `flashLoan` function did not return the expected hash (see `ERC-3156` spec).
     */
    error FlashloanCallbackFailed();

    /**
     *  @notice Balance of pool contract before flashloan is different than the balance after flashloan.
     */
    error FlashloanIncorrectBalance();

    /**
     *  @notice Pool cannot facilitate a flashloan for the specified token address.
     */
    error FlashloanUnavailableForToken();

    /**
     *  @notice User is attempting to move or pull more collateral than is available.
     */
    error InsufficientCollateral();

    /**
     *  @notice Lender is attempting to move or remove more collateral they have claim to in the bucket.
     *  @notice Lender is attempting to remove more collateral they have claim to in the bucket.
     *  @notice Lender must have enough `LP` to claim the desired amount of quote from the bucket.
     */
    error InsufficientLP();

    /**
     *  @notice Bucket must have more quote available in the bucket than the lender is attempting to claim.
     */
    error InsufficientLiquidity();

    /**
     *  @notice When increasing / decreasing `LP` allowances indexes and amounts arrays parameters should have same length.
     */
    error InvalidAllowancesInput();

    /**
     *  @notice When transferring `LP` between indices, the new index must be a valid index.
     */
    error InvalidIndex();

    /**
     *  @notice The amount used for performed action should be greater than `0`.
     */
    error InvalidAmount();

    /**
     *  @notice Borrower is attempting to borrow more quote token than is available before the supplied `limitIndex`.
     */
    error LimitIndexExceeded();

    /**
     *  @notice When moving quote token `HTP` must stay below `LUP`.
     *  @notice When removing quote token `HTP` must stay below `LUP`.
     */
    error LUPBelowHTP();

    /**
     *  @notice Liquidation must result in `LUP` below the borrowers threshold price.
     */
    error LUPGreaterThanTP();

    /**
     *  @notice From index and to index arguments to move are the same.
     */
    error MoveToSameIndex();

    /**
     *  @notice Owner of the `LP` must have approved the new owner prior to transfer.
     */
    error NoAllowance();

    /**
     *  @notice Actor is attempting to take or clear an inactive auction.
     */
    error NoAuction();

    /**
     *  @notice No pool reserves are claimable.
     */
    error NoReserves();

    /**
     *  @notice Actor is attempting to take or clear an inactive reserves auction.
     */
    error NoReservesAuction();

    /**
     *  @notice Lender must have non-zero `LP` when attemptign to remove quote token from the pool.
     */
    error NoClaim();

    /**
     *  @notice Borrower has no debt to liquidate.
     *  @notice Borrower is attempting to repay when they have no outstanding debt.
     */
    error NoDebt();

    /**
     *  @notice Borrower is attempting to borrow an amount of quote tokens that will push the pool into under-collateralization.
     */
    error PoolUnderCollateralized();

    /**
     *  @notice Actor is attempting to remove using a bucket with price below the `LUP`.
     */
    error PriceBelowLUP();

    /**
     *  @notice Lender is attempting to remove quote tokens from a bucket that exists above active auction debt from top-of-book downward.
     */
    error RemoveDepositLockedByAuctionDebt();

    /**
     * @notice User attempted to kick off a new auction less than `2` weeks since the last auction completed.
     */
    error ReserveAuctionTooSoon();

    /**
     *  @notice Take was called before `1` hour had passed from kick time.
     */
    error TakeNotPastCooldown();

    /**
     *  @notice Current block timestamp has reached or exceeded a user-provided expiration.
     */
    error TransactionExpired();

    /**
     *  @notice The address that transfer `LP` is not approved by the `LP` receiving address.
     */
    error TransferorNotApproved();

    /**
     *  @notice Owner of the `LP` attemps to transfer `LP` to same address.
     */
    error TransferToSameOwner();

    /**
     *  @notice The threshold price of the loan to be inserted in loans heap is zero.
     */
    error ZeroThresholdPrice();

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Events
 */
interface IPoolEvents {

    /*********************/
    /*** Lender events ***/
    /*********************/

    /**
     *  @notice Emitted when lender adds quote token to the pool.
     *  @param  lender    Recipient that added quote tokens.
     *  @param  index     Index at which quote tokens were added.
     *  @param  amount    Amount of quote tokens added to the pool (`WAD` precision).
     *  @param  lpAwarded Amount of `LP` awarded for the deposit (`WAD` precision).
     *  @param  lup       `LUP` calculated after deposit.
     */
    event AddQuoteToken(
        address indexed lender,
        uint256 indexed index,
        uint256 amount,
        uint256 lpAwarded,
        uint256 lup
    );

    /**
     *  @notice Emitted when lender moves quote token from a bucket price to another.
     *  @param  lender         Recipient that moved quote tokens.
     *  @param  from           Price bucket from which quote tokens were moved.
     *  @param  to             Price bucket where quote tokens were moved.
     *  @param  amount         Amount of quote tokens moved (`WAD` precision).
     *  @param  lpRedeemedFrom Amount of `LP` removed from the `from` bucket (`WAD` precision).
     *  @param  lpAwardedTo    Amount of `LP` credited to the `to` bucket (`WAD` precision).
     *  @param  lup            `LUP` calculated after removal.
     */
    event MoveQuoteToken(
        address indexed lender,
        uint256 indexed from,
        uint256 indexed to,
        uint256 amount,
        uint256 lpRedeemedFrom,
        uint256 lpAwardedTo,
        uint256 lup
    );

    /**
     *  @notice Emitted when lender removes quote token from the pool.
     *  @param  lender     Recipient that removed quote tokens.
     *  @param  index      Index at which quote tokens were removed.
     *  @param  amount     Amount of quote tokens removed from the pool (`WAD` precision).
     *  @param  lpRedeemed Amount of `LP` exchanged for quote token (`WAD` precision).
     *  @param  lup        `LUP` calculated after removal.
     */
    event RemoveQuoteToken(
        address indexed lender,
        uint256 indexed index,
        uint256 amount,
        uint256 lpRedeemed,
        uint256 lup
    );

    /**
     *  @notice Emitted when lender claims collateral from a bucket.
     *  @param  claimer    Recipient that claimed collateral.
     *  @param  index      Index at which collateral was claimed.
     *  @param  amount     The amount of collateral (`WAD` precision for `ERC20` pools, number of `NFT` tokens for `ERC721` pools) transferred to the claimer.
     *  @param  lpRedeemed Amount of `LP` exchanged for quote token (`WAD` precision).
     */
    event RemoveCollateral(
        address indexed claimer,
        uint256 indexed index,
        uint256 amount,
        uint256 lpRedeemed
    );

    /***********************/
    /*** Borrower events ***/
    /***********************/

    /**
     *  @notice Emitted when borrower repays quote tokens to the pool and/or pulls collateral from the pool.
     *  @param  borrower         `msg.sender` or on behalf of sender.
     *  @param  quoteRepaid      Amount of quote tokens repaid to the pool (`WAD` precision).
     *  @param  collateralPulled The amount of collateral (`WAD` precision for `ERC20` pools, number of `NFT` tokens for `ERC721` pools) transferred to the claimer.
     *  @param  lup              `LUP` after repay.
     */
    event RepayDebt(
        address indexed borrower,
        uint256 quoteRepaid,
        uint256 collateralPulled,
        uint256 lup
    );

    /**********************/
    /*** Auction events ***/
    /**********************/

    /**
     *  @notice Emitted when a liquidation is initiated.
     *  @param  borrower   Identifies the loan being liquidated.
     *  @param  debt       Debt the liquidation will attempt to cover (`WAD` precision).
     *  @param  collateral Amount of collateral up for liquidation (`WAD` precision for `ERC20` pools, number of `NFT` tokens for `ERC721` pools).
     *  @param  bond       Bond amount locked by kicker (`WAD` precision).
     */
    event Kick(
        address indexed borrower,
        uint256 debt,
        uint256 collateral,
        uint256 bond
    );

    /**
     *  @notice Emitted when kickers are withdrawing funds posted as auction bonds.
     *  @param  kicker   The kicker withdrawing bonds.
     *  @param  reciever The address receiving withdrawn bond amount.
     *  @param  amount   The bond amount that was withdrawn (`WAD` precision).
     */
    event BondWithdrawn(
        address indexed kicker,
        address indexed reciever,
        uint256 amount
    );

    /**
     *  @notice Emitted when an actor uses quote token to arb higher-priced deposit off the book.
     *  @param  borrower    Identifies the loan being liquidated.
     *  @param  index       The index of the `Highest Price Bucket` used for this take.
     *  @param  amount      Amount of quote token used to purchase collateral (`WAD` precision).
     *  @param  collateral  Amount of collateral purchased with quote token (`WAD` precision).
     *  @param  bondChange  Impact of this take to the liquidation bond (`WAD` precision).
     *  @param  isReward    `True` if kicker was rewarded with `bondChange` amount, `false` if kicker was penalized.
     *  @dev    amount / collateral implies the auction price.
     */
    event BucketTake(
        address indexed borrower,
        uint256 index,
        uint256 amount,
        uint256 collateral,
        uint256 bondChange,
        bool    isReward
    );

    /**
     *  @notice Emitted when `LP` are awarded to a taker or kicker in a bucket take.
     *  @param  taker           Actor who invoked the bucket take.
     *  @param  kicker          Actor who started the auction.
     *  @param  lpAwardedTaker  Amount of `LP` awarded to the taker (`WAD` precision).
     *  @param  lpAwardedKicker Amount of `LP` awarded to the actor who started the auction (`WAD` precision).
     */
    event BucketTakeLPAwarded(
        address indexed taker,
        address indexed kicker,
        uint256 lpAwardedTaker,
        uint256 lpAwardedKicker
    );

    /**
     *  @notice Emitted when an actor uses quote token outside of the book to purchase collateral under liquidation.
     *  @param  borrower   Identifies the loan being liquidated.
     *  @param  amount     Amount of quote token used to purchase collateral (`WAD` precision).
     *  @param  collateral Amount of collateral purchased with quote token (for `ERC20` pool, `WAD` precision) or number of `NFT`s purchased (for `ERC721` pool).
     *  @param  bondChange Impact of this take to the liquidation bond (`WAD` precision).
     *  @param  isReward   `True` if kicker was rewarded with `bondChange` amount, `false` if kicker was penalized.
     *  @dev    amount / collateral implies the auction price.
     */
    event Take(
        address indexed borrower,
        uint256 amount,
        uint256 collateral,
        uint256 bondChange,
        bool    isReward
    );

    /**
     *  @notice Emitted when an actor settles debt in a completed liquidation
     *  @param  borrower    Identifies the loan under liquidation.
     *  @param  settledDebt Amount of pool debt settled in this transaction (`WAD` precision).
     *  @dev    When `amountRemaining_ == 0`, the auction has been completed cleared and removed from the queue.
     */
    event Settle(
        address indexed borrower,
        uint256 settledDebt
    );

    /**
     *  @notice Emitted when auction is completed.
     *  @param  borrower   Address of borrower that exits auction.
     *  @param  collateral Borrower's remaining collateral when auction completed (`WAD` precision).
     */
    event AuctionSettle(
        address indexed borrower,
        uint256 collateral
    );

    /**
     *  @notice Emitted when `NFT` auction is completed.
     *  @param  borrower   Address of borrower that exits auction.
     *  @param  collateral Borrower's remaining collateral when auction completed.
     *  @param  lp         Amount of `LP` given to the borrower to compensate fractional collateral (if any, `WAD` precision).
     *  @param  index      Index of the bucket with `LP` to compensate fractional collateral.
     */
    event AuctionNFTSettle(
        address indexed borrower,
        uint256 collateral,
        uint256 lp,
        uint256 index
    );

    /**
     *  @notice Emitted when a `Claimaible Reserve Auction` is started.
     *  @param  claimableReservesRemaining Amount of claimable reserves which has not yet been taken (`WAD` precision).
     *  @param  auctionPrice               Current price at which `1` quote token may be purchased, denominated in `Ajna`.
     *  @param  currentBurnEpoch           Current burn epoch.
     */
    event KickReserveAuction(
        uint256 claimableReservesRemaining,
        uint256 auctionPrice,
        uint256 currentBurnEpoch
    );

    /**
     *  @notice Emitted when a `Claimaible Reserve Auction` is taken.
     *  @param  claimableReservesRemaining Amount of claimable reserves which has not yet been taken (`WAD` precision).
     *  @param  auctionPrice               Current price at which `1` quote token may be purchased, denominated in `Ajna`.
     *  @param  currentBurnEpoch           Current burn epoch.
     */
    event ReserveAuction(
        uint256 claimableReservesRemaining,
        uint256 auctionPrice,
        uint256 currentBurnEpoch
    );

    /**************************/
    /*** LP transfer events ***/
    /**************************/

    /**
     *  @notice Emitted when owner increase the `LP` allowance of a spender at specified indexes with specified amounts.
     *  @param  owner     `LP` owner.
     *  @param  spender   Address approved to transfer `LP`.
     *  @param  indexes   Bucket indexes of `LP` approved.
     *  @param  amounts   `LP` amounts added (ordered by indexes, `WAD` precision).
     */
    event IncreaseLPAllowance(
        address indexed owner,
        address indexed spender,
        uint256[] indexes,
        uint256[] amounts
    );

    /**
     *  @notice Emitted when owner decrease the `LP` allowance of a spender at specified indexes with specified amounts.
     *  @param  owner     `LP` owner.
     *  @param  spender   Address approved to transfer `LP`.
     *  @param  indexes   Bucket indexes of `LP` approved.
     *  @param  amounts   `LP` amounts removed (ordered by indexes, `WAD` precision).
     */
    event DecreaseLPAllowance(
        address indexed owner,
        address indexed spender,
        uint256[] indexes,
        uint256[] amounts
    );

    /**
     *  @notice Emitted when lender removes the allowance of a spender for their `LP`.
     *  @param  owner   `LP` owner.
     *  @param  spender Address that is having it's allowance revoked.
     *  @param  indexes List of bucket index to remove the allowance from.
     */
    event RevokeLPAllowance(
        address indexed owner,
        address indexed spender,
        uint256[] indexes
    );

    /**
     *  @notice Emitted when lender whitelists addresses to accept `LP` from.
     *  @param  lender      Recipient that approves new owner for `LP`.
     *  @param  transferors List of addresses that can transfer `LP` to lender.
     */
    event ApproveLPTransferors(
        address indexed lender,
        address[] transferors
    );

    /**
     *  @notice Emitted when lender removes addresses from the `LP` transferors whitelist.
     *  @param  lender      Recipient that approves new owner for `LP`.
     *  @param  transferors List of addresses that won't be able to transfer `LP` to lender anymore.
     */
    event RevokeLPTransferors(
        address indexed lender,
        address[] transferors
    );

    /**
     *  @notice Emitted when a lender transfers their `LP` to a different address.
     *  @dev    Used by `PositionManager.memorializePositions()`.
     *  @param  owner    The original owner address of the position.
     *  @param  newOwner The new owner address of the position.
     *  @param  indexes  Array of price bucket indexes at which `LP` were transferred.
     *  @param  lp       Amount of `LP` transferred (`WAD` precision).
     */
    event TransferLP(
        address owner,
        address newOwner,
        uint256[] indexes,
        uint256 lp
    );

    /**************************/
    /*** Pool common events ***/
    /**************************/

    /**
     *  @notice Emitted when `LP` are forfeited as a result of the bucket losing all assets.
     *  @param  index       The index of the bucket.
     *  @param  lpForfeited Amount of `LP` forfeited by lenders (`WAD` precision).
     */
    event BucketBankruptcy(
        uint256 indexed index,
        uint256 lpForfeited
    );

    /**
     *  @notice Emitted when a flashloan is taken from pool.
     *  @param  receiver The address receiving the flashloan.
     *  @param  token    The address of token flashloaned from pool.
     *  @param  amount   The amount of tokens flashloaned from pool (token precision).
     */
    event Flashloan(
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    /**
     *  @notice Emitted when a loan `Neutral Price` is restamped.
     *  @param  borrower Identifies the loan to update the `Neutral Price`.
     */
    event LoanStamped(
        address indexed borrower
    );

    /**
     *  @notice Emitted when pool interest rate is reset. This happens when `interest rate > 10%` and `debtEma < 5%` of `depositEma`
     *  @param  oldRate Old pool interest rate.
     *  @param  newRate New pool interest rate.
     */
    event ResetInterestRate(
        uint256 oldRate,
        uint256 newRate
    );

    /**
     *  @notice Emitted when pool interest rate is updated.
     *  @param  oldRate Old pool interest rate.
     *  @param  newRate New pool interest rate.
     */
    event UpdateInterestRate(
        uint256 oldRate,
        uint256 newRate
    );

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Immutables
 */
interface IPoolImmutables {

    /**
     *  @notice Returns the type of the pool (`0` for `ERC20`, `1` for `ERC721`).
     */
    function poolType() external pure returns (uint8);

    /**
     *  @notice Returns the address of the pool's collateral token.
     */
    function collateralAddress() external pure returns (address);

    /**
     *  @notice Returns the address of the pool's quote token.
     */
    function quoteTokenAddress() external pure returns (address);

    /**
     *  @notice Returns the `quoteTokenScale` state variable.
     *  @notice Token scale is also the minimum amount a lender may have in a bucket (dust amount).
     *  @return The precision of the quote `ERC20` token based on decimals.
     */
    function quoteTokenScale() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Internal structs used by the pool / libraries
 */

/*****************************/
/*** Auction Param Structs ***/
/*****************************/

/// @dev Struct used to return result of `KickerAction.kick` action.
struct KickResult {
    uint256 amountToCoverBond;    // [WAD] amount of bond that needs to be covered
    uint256 t0PoolDebt;           // [WAD] t0 debt in pool after kick
    uint256 t0KickedDebt;         // [WAD] new t0 debt after kick
    uint256 lup;                  // [WAD] current lup
    uint256 debtPreAction;        // [WAD] The amount of borrower t0 debt before kick
    uint256 collateralPreAction;  // [WAD] The amount of borrower collateral before kick, same as the one after kick
}

/// @dev Struct used to hold parameters for `SettlerAction.settlePoolDebt` action.
struct SettleParams {
    address borrower;    // borrower address to settle
    uint256 bucketDepth; // number of buckets to use when settle debt
    uint256 poolBalance; // current pool quote token balance
}

/// @dev Struct used to return result of `SettlerAction.settlePoolDebt` action.
struct SettleResult {
    uint256 debtPreAction;       // [WAD] The amount of borrower t0 debt before settle
    uint256 debtPostAction;      // [WAD] The amount of borrower t0 debt remaining after settle
    uint256 collateralPreAction; // [WAD] The amount of borrower collateral before settle
    uint256 collateralRemaining; // [WAD] The amount of borrower collateral left after settle
    uint256 collateralSettled;   // [WAD] The amount of borrower collateral settled
    uint256 t0DebtSettled;       // [WAD] The amount of t0 debt settled
}

/// @dev Struct used to return result of `TakerAction.take` and `TakerAction.bucketTake` actions.
struct TakeResult {
    uint256 collateralAmount;      // [WAD] amount of collateral taken
    uint256 compensatedCollateral; // [WAD] amount of borrower collateral that is compensated with LP
    uint256 quoteTokenAmount;      // [WAD] amount of quote tokens paid by taker for taken collateral, used in take action
    uint256 t0DebtPenalty;         // [WAD] t0 penalty applied on first take
    uint256 excessQuoteToken;      // [WAD] (NFT only) amount of quote tokens to be paid by taker to borrower for fractional collateral, used in take action
    uint256 remainingCollateral;   // [WAD] amount of borrower collateral remaining after take
    uint256 poolDebt;              // [WAD] current pool debt
    uint256 t0PoolDebt;            // [WAD] t0 pool debt
    uint256 newLup;                // [WAD] current lup
    uint256 t0DebtInAuctionChange; // [WAD] the amount of t0 debt recovered by take action
    bool    settledAuction;        // true if auction is settled by take action
    uint256 debtPreAction;         // [WAD] The amount of borrower t0 debt before take
    uint256 debtPostAction;        // [WAD] The amount of borrower t0 debt after take
    uint256 collateralPreAction;   // [WAD] The amount of borrower collateral before take
    uint256 collateralPostAction;  // [WAD] The amount of borrower collateral after take
}

/// @dev Struct used to hold parameters for `KickerAction.kickReserveAuction` action.
struct KickReserveAuctionParams {
    uint256 poolSize;    // [WAD] total deposits in pool (with accrued debt)
    uint256 t0PoolDebt;  // [WAD] current t0 pool debt
    uint256 poolBalance; // [WAD] pool quote token balance
    uint256 inflator;    // [WAD] pool current inflator
}

/******************************************/
/*** Liquidity Management Param Structs ***/
/******************************************/

/// @dev Struct used to hold parameters for `LenderAction.addQuoteToken` action.
struct AddQuoteParams {
    uint256 amount;          // [WAD] amount to be added
    uint256 index;           // the index in which to deposit
}

/// @dev Struct used to hold parameters for `LenderAction.moveQuoteToken` action.
struct MoveQuoteParams {
    uint256 fromIndex;       // the deposit index from where amount is moved
    uint256 maxAmountToMove; // [WAD] max amount to move between deposits
    uint256 toIndex;         // the deposit index where amount is moved to
    uint256 thresholdPrice;  // [WAD] max threshold price in pool
}

/// @dev Struct used to hold parameters for `LenderAction.removeQuoteToken` action.
struct RemoveQuoteParams {
    uint256 index;           // the deposit index from where amount is removed
    uint256 maxAmount;       // [WAD] max amount to be removed
    uint256 thresholdPrice;  // [WAD] max threshold price in pool
}

/*************************************/
/*** Loan Management Param Structs ***/
/*************************************/

/// @dev Struct used to return result of `BorrowerActions.drawDebt` action.
struct DrawDebtResult {
    bool    inAuction;             // true if loan still in auction after pledge more collateral, false otherwise
    uint256 newLup;                // [WAD] new pool LUP after draw debt
    uint256 poolCollateral;        // [WAD] total amount of collateral in pool after pledge collateral
    uint256 poolDebt;              // [WAD] total accrued debt in pool after draw debt
    uint256 remainingCollateral;   // [WAD] amount of borrower collateral after draw debt (for NFT can be diminished if auction settled)
    bool    settledAuction;        // true if collateral pledged settles auction
    uint256 t0DebtInAuctionChange; // [WAD] change of t0 pool debt in auction after pledge collateral
    uint256 t0PoolDebt;            // [WAD] amount of t0 debt in pool after draw debt
    uint256 debtPreAction;         // [WAD] The amount of borrower t0 debt before draw debt
    uint256 debtPostAction;        // [WAD] The amount of borrower t0 debt after draw debt
    uint256 collateralPreAction;   // [WAD] The amount of borrower collateral before draw debt
    uint256 collateralPostAction;  // [WAD] The amount of borrower collateral after draw debt
}

/// @dev Struct used to return result of `BorrowerActions.repayDebt` action.
struct RepayDebtResult {
    bool    inAuction;             // true if loan still in auction after repay, false otherwise
    uint256 newLup;                // [WAD] new pool LUP after draw debt
    uint256 poolCollateral;        // [WAD] total amount of collateral in pool after pull collateral
    uint256 poolDebt;              // [WAD] total accrued debt in pool after repay debt
    uint256 remainingCollateral;   // [WAD] amount of borrower collateral after pull collateral
    bool    settledAuction;        // true if repay debt settles auction
    uint256 t0DebtInAuctionChange; // [WAD] change of t0 pool debt in auction after repay debt
    uint256 t0PoolDebt;            // [WAD] amount of t0 debt in pool after repay
    uint256 quoteTokenToRepay;     // [WAD] quote token amount to be transferred from sender to pool
    uint256 debtPreAction;         // [WAD] The amount of borrower t0 debt before repay debt
    uint256 debtPostAction;        // [WAD] The amount of borrower t0 debt after repay debt
    uint256 collateralPreAction;   // [WAD] The amount of borrower collateral before repay debt
    uint256 collateralPostAction;  // [WAD] The amount of borrower collateral after repay debt
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Kicker Actions
 */
interface IPoolKickerActions {

    /********************/
    /*** Liquidations ***/
    /********************/

    /**
     *  @notice Called by actors to initiate a liquidation.
     *  @param  borrower_     Identifies the loan to liquidate.
     *  @param  npLimitIndex_ Index of the lower bound of `NP` tolerated when kicking the auction.
     */
    function kick(
        address borrower_,
        uint256 npLimitIndex_
    ) external;

    /**
     *  @notice Called by lenders to liquidate the top loan using their deposits.
     *  @param  index_        The deposit index to use for kicking the top loan.
     *  @param  npLimitIndex_ Index of the lower bound of `NP` tolerated when kicking the auction.
     */
    function kickWithDeposit(
        uint256 index_,
        uint256 npLimitIndex_
    ) external;

    /**
     *  @notice Called by kickers to withdraw their auction bonds (the amount of quote tokens that are not locked in active auctions).
     *  @param  recipient_ Address to receive claimed bonds amount.
     *  @param  maxAmount_ The max amount to withdraw from auction bonds (`WAD` precision). Constrained by claimable amounts and liquidity.
     */
    function withdrawBonds(
        address recipient_,
        uint256 maxAmount_
    ) external;

    /***********************/
    /*** Reserve Auction ***/
    /***********************/

    /**
     *  @notice Called by actor to start a `Claimable Reserve Auction` (`CRA`).
     */
    function kickReserveAuction() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool `LP` Actions
 */
interface IPoolLPActions {

    /**
     *  @notice Called by `LP` owners to approve transfer of an amount of `LP` to a new owner.
     *  @dev    Intended for use by the `PositionManager` contract.
     *  @param  spender_ The new owner of the `LP`.
     *  @param  indexes_ Bucket indexes from where `LP` are transferred.
     *  @param  amounts_ The amounts of `LP` approved to transfer (`WAD` precision).
     */
    function increaseLPAllowance(
        address spender_,
        uint256[] calldata indexes_,
        uint256[] calldata amounts_
    ) external;

    /**
     *  @notice Called by `LP` owners to decrease the amount of `LP` that can be spend by a new owner.
     *  @dev    Intended for use by the `PositionManager` contract.
     *  @param  spender_ The new owner of the `LP`.
     *  @param  indexes_ Bucket indexes from where `LP` are transferred.
     *  @param  amounts_ The amounts of `LP` disapproved to transfer (`WAD` precision).
     */
    function decreaseLPAllowance(
        address spender_,
        uint256[] calldata indexes_,
        uint256[] calldata amounts_
    ) external;

    /**
     *  @notice Called by `LP` owners to decrease the amount of `LP` that can be spend by a new owner.
     *  @param  spender_ Address that is having it's allowance revoked.
     *  @param  indexes_ List of bucket index to remove the allowance from.
     */
    function revokeLPAllowance(
        address spender_,
        uint256[] calldata indexes_
    ) external;

    /**
     *  @notice Called by `LP` owners to allow addresses that can transfer LP.
     *  @dev    Intended for use by the `PositionManager` contract.
     *  @param  transferors_ Addresses that are allowed to transfer `LP` to new owner.
     */
    function approveLPTransferors(
        address[] calldata transferors_
    ) external;

    /**
     *  @notice Called by `LP` owners to revoke addresses that can transfer `LP`.
     *  @dev    Intended for use by the `PositionManager` contract.
     *  @param  transferors_ Addresses that are revoked to transfer `LP` to new owner.
     */
    function revokeLPTransferors(
        address[] calldata transferors_
    ) external;

    /**
     *  @notice Called by `LP` owners to transfers their `LP` to a different address. `approveLpOwnership` needs to be run first.
     *  @dev    Used by `PositionManager.memorializePositions()`.
     *  @param  owner_    The original owner address of the position.
     *  @param  newOwner_ The new owner address of the position.
     *  @param  indexes_  Array of price buckets index at which `LP` were moved.
     */
    function transferLP(
        address owner_,
        address newOwner_,
        uint256[] calldata indexes_
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Lender Actions
 */
interface IPoolLenderActions {

    /*********************************************/
    /*** Quote/collateral management functions ***/
    /*********************************************/

    /**
     *  @notice Called by lenders to add an amount of credit at a specified price bucket.
     *  @param  amount_   The amount of quote token to be added by a lender (`WAD` precision).
     *  @param  index_    The index of the bucket to which the quote tokens will be added.
     *  @param  expiry_   Timestamp after which this transaction will revert, preventing inclusion in a block with unfavorable price.
     *  @return bucketLP_ The amount of `LP` changed for the added quote tokens (`WAD` precision).
     */
    function addQuoteToken(
        uint256 amount_,
        uint256 index_,
        uint256 expiry_
    ) external returns (uint256 bucketLP_);

    /**
     *  @notice Called by lenders to move an amount of credit from a specified price bucket to another specified price bucket.
     *  @param  maxAmount_    The maximum amount of quote token to be moved by a lender (`WAD` precision).
     *  @param  fromIndex_    The bucket index from which the quote tokens will be removed.
     *  @param  toIndex_      The bucket index to which the quote tokens will be added.
     *  @param  expiry_       Timestamp after which this transaction will revert, preventing inclusion in a block with unfavorable price.
     *  @return fromBucketLP_ The amount of `LP` moved out from bucket (`WAD` precision).
     *  @return toBucketLP_   The amount of `LP` moved to destination bucket (`WAD` precision).
     *  @return movedAmount_  The amount of quote token moved (`WAD` precision).
     */
    function moveQuoteToken(
        uint256 maxAmount_,
        uint256 fromIndex_,
        uint256 toIndex_,
        uint256 expiry_
    ) external returns (uint256 fromBucketLP_, uint256 toBucketLP_, uint256 movedAmount_);

    /**
     *  @notice Called by lenders to claim collateral from a price bucket.
     *  @param  maxAmount_     The amount of collateral (`WAD` precision for `ERC20` pools, number of `NFT` tokens for `ERC721` pools) to claim.
     *  @param  index_         The bucket index from which collateral will be removed.
     *  @return removedAmount_ The amount of collateral removed (`WAD` precision).
     *  @return redeemedLP_    The amount of `LP` used for removing collateral amount (`WAD` precision).
     */
    function removeCollateral(
        uint256 maxAmount_,
        uint256 index_
    ) external returns (uint256 removedAmount_, uint256 redeemedLP_);

    /**
     *  @notice Called by lenders to remove an amount of credit at a specified price bucket.
     *  @param  maxAmount_     The max amount of quote token to be removed by a lender (`WAD` precision).
     *  @param  index_         The bucket index from which quote tokens will be removed.
     *  @return removedAmount_ The amount of quote token removed (`WAD` precision).
     *  @return redeemedLP_    The amount of `LP` used for removing quote tokens amount (`WAD` precision).
     */
    function removeQuoteToken(
        uint256 maxAmount_,
        uint256 index_
    ) external returns (uint256 removedAmount_, uint256 redeemedLP_);

    /********************************/
    /*** Interest update function ***/
    /********************************/

    /**
     *  @notice Called by actors to update pool interest rate (can be updated only once in a `12` hours period of time).
     */
    function updateInterest() external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Settler Actions
 */
interface IPoolSettlerActions {

    /**
     *  @notice Called by actors to settle an amount of debt in a completed liquidation.
     *  @param  borrowerAddress_ Address of the auctioned borrower.
     *  @param  maxDepth_        Measured from `HPB`, maximum number of buckets deep to settle debt.
     *  @dev    `maxDepth_` is used to prevent unbounded iteration clearing large liquidations.
     */
    function settle(
        address borrowerAddress_,
        uint256 maxDepth_
    ) external;

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool State
 */
interface IPoolState {

    /**
     *  @notice Returns details of an auction for a given borrower address.
     *  @param  borrower_     Address of the borrower that is liquidated.
     *  @return kicker_       Address of the kicker that is kicking the auction.
     *  @return bondFactor_   The factor used for calculating bond size.
     *  @return bondSize_     The bond amount in quote token terms.
     *  @return kickTime_     Time the liquidation was initiated.
     *  @return kickMomp_     Price where the average loan utilizes deposit, at the time when the loan is liquidated (kicked).
     *  @return neutralPrice_ `Neutral Price` of auction.
     *  @return head_         Address of the head auction.
     *  @return next_         Address of the next auction in queue.
     *  @return prev_         Address of the prev auction in queue.
     *  @return alreadyTaken_ True if take has been called on auction
     */
    function auctionInfo(address borrower_)
        external
        view
        returns (
            address kicker_,
            uint256 bondFactor_,
            uint256 bondSize_,
            uint256 kickTime_,
            uint256 kickMomp_,
            uint256 neutralPrice_,
            address head_,
            address next_,
            address prev_,
            bool alreadyTaken_
        );

    /**
     *  @notice Returns pool related debt values.
     *  @return debt_                Current amount of debt owed by borrowers in pool.
     *  @return accruedDebt_         Debt owed by borrowers based on last inflator snapshot.
     *  @return debtInAuction_       Total amount of debt in auction.
     *  @return t0Debt2ToCollateral_ t0debt accross all borrowers divided by their collateral, used in determining a collateralization weighted debt.
     */
    function debtInfo()
        external
        view
        returns (
            uint256 debt_,
            uint256 accruedDebt_,
            uint256 debtInAuction_,
            uint256 t0Debt2ToCollateral_
        );

    /**
     *  @notice Mapping of borrower addresses to `Borrower` structs.
     *  @dev    NOTE: Cannot use appended underscore syntax for return params since struct is used.
     *  @param  borrower_   Address of the borrower.
     *  @return t0Debt_     Amount of debt borrower would have had if their loan was the first debt drawn from the pool.
     *  @return collateral_ Amount of collateral that the borrower has deposited, in collateral token.
     *  @return t0Np_       t0 `Neutral Price`
     */
    function borrowerInfo(address borrower_)
        external
        view
        returns (
            uint256 t0Debt_,
            uint256 collateral_,
            uint256 t0Np_
        );

    /**
     *  @notice Mapping of buckets indexes to `Bucket` structs.
     *  @dev    NOTE: Cannot use appended underscore syntax for return params since struct is used.
     *  @param  index_               Bucket index.
     *  @return lpAccumulator_       Amount of `LP` accumulated in current bucket.
     *  @return availableCollateral_ Amount of collateral available in current bucket.
     *  @return bankruptcyTime_      Timestamp when bucket become insolvent, `0` if healthy.
     *  @return bucketDeposit_       Amount of quote tokens in bucket.
     *  @return bucketScale_         Bucket multiplier.
     */
    function bucketInfo(uint256 index_)
        external
        view
        returns (
            uint256 lpAccumulator_,
            uint256 availableCollateral_,
            uint256 bankruptcyTime_,
            uint256 bucketDeposit_,
            uint256 bucketScale_
        );

    /**
     *  @notice Mapping of burnEventEpoch to `BurnEvent` structs.
     *  @dev    Reserve auctions correspond to burn events.
     *  @param  burnEventEpoch_  Id of the current reserve auction.
     *  @return burnBlock_       Block in which a reserve auction started.
     *  @return totalInterest_   Total interest as of the reserve auction.
     *  @return totalBurned_     Total ajna tokens burned as of the reserve auction.
     */
    function burnInfo(uint256 burnEventEpoch_) external view returns (uint256, uint256, uint256);

    /**
     *  @notice Returns the latest `burnEventEpoch` of reserve auctions.
     *  @dev    If a reserve auction is active, it refers to the current reserve auction. If no reserve auction is active, it refers to the last reserve auction.
     *  @return Current `burnEventEpoch`.
     */
    function currentBurnEpoch() external view returns (uint256);

    /**
     *  @notice Returns information about the pool `EMA (Exponential Moving Average)` variables.
     *  @return debtColEma_   Debt squared to collateral Exponential, numerator to `TU` calculation.
     *  @return lupt0DebtEma_ Exponential of `LUP * t0 debt`, denominator to `TU` calculation
     *  @return debtEma_      Exponential debt moving average.
     *  @return depositEma_   sample of meaningful deposit Exponential, denominator to `MAU` calculation.
     */
    function emasInfo()
        external
        view
        returns (
            uint256 debtColEma_,
            uint256 lupt0DebtEma_,
            uint256 debtEma_,
            uint256 depositEma_
    );

    /**
     *  @notice Returns information about pool inflator.
     *  @return inflator_   Pool inflator value.
     *  @return lastUpdate_ The timestamp of the last `inflator` update.
     */
    function inflatorInfo()
        external
        view
        returns (
            uint256 inflator_,
            uint256 lastUpdate_
    );

    /**
     *  @notice Returns information about pool interest rate.
     *  @return interestRate_       Current interest rate in pool.
     *  @return interestRateUpdate_ The timestamp of the last interest rate update.
     */
    function interestRateInfo()
        external
        view
        returns (
            uint256 interestRate_,
            uint256 interestRateUpdate_
        );


    /**
     *  @notice Returns details about kicker balances.
     *  @param  kicker_    The address of the kicker to retrieved info for.
     *  @return claimable_ Amount of quote token kicker can claim / withdraw from pool at any time.
     *  @return locked_    Amount of quote token kicker locked in auctions (as bonds).
     */
    function kickerInfo(address kicker_)
        external
        view
        returns (
            uint256 claimable_,
            uint256 locked_
        );

    /**
     *  @notice Mapping of buckets indexes and owner addresses to `Lender` structs.
     *  @param  index_       Bucket index.
     *  @param  lender_      Address of the liquidity provider.
     *  @return lpBalance_   Amount of `LP` owner has in current bucket.
     *  @return depositTime_ Time the user last deposited quote token.
     */
    function lenderInfo(
        uint256 index_,
        address lender_
    )
        external
        view
        returns (
            uint256 lpBalance_,
            uint256 depositTime_
    );

    /**
     *  @notice Return the `LP` allowance a `LP` owner provided to a spender.
     *  @param  index_     Bucket index.
     *  @param  spender_   Address of the `LP` spender.
     *  @param  owner_     The initial owner of the `LP`.
     *  @return allowance_ Amount of `LP` spender can utilize.
     */
    function lpAllowance(
        uint256 index_,
        address spender_,
        address owner_
    ) external view returns (uint256 allowance_);

    /**
     *  @notice Returns information about a loan in the pool.
     *  @param  loanId_         Loan's id within loan heap. Max loan is position `1`.
     *  @return borrower_       Borrower address at the given position.
     *  @return thresholdPrice_ Borrower threshold price in pool.
     */
    function loanInfo(
        uint256 loanId_
    )
        external
        view
        returns (
            address borrower_,
            uint256 thresholdPrice_
    );

    /**
     *  @notice Returns information about pool loans.
     *  @return maxBorrower_       Borrower address with highest threshold price.
     *  @return maxThresholdPrice_ Highest threshold price in pool.
     *  @return noOfLoans_         Total number of loans.
     */
    function loansInfo()
        external
        view
        returns (
            address maxBorrower_,
            uint256 maxThresholdPrice_,
            uint256 noOfLoans_
    );

    /**
     *  @notice Returns information about pool reserves.
     *  @return liquidationBondEscrowed_ Amount of liquidation bond across all liquidators.
     *  @return reserveAuctionUnclaimed_ Amount of claimable reserves which has not been taken in the `Claimable Reserve Auction`.
     *  @return reserveAuctionKicked_    Time a `Claimable Reserve Auction` was last kicked.
     *  @return totalInterestEarned_     Total interest earned by all lenders in the pool
     */
    function reservesInfo()
        external
        view
        returns (
            uint256 liquidationBondEscrowed_,
            uint256 reserveAuctionUnclaimed_,
            uint256 reserveAuctionKicked_,
            uint256 totalInterestEarned_
    );

    /**
     *  @notice Returns the `pledgedCollateral` state variable.
     *  @return The total pledged collateral in the system, in WAD units.
     */
    function pledgedCollateral() external view returns (uint256);

    /**
     *  @notice Returns the total number of active auctions in pool.
     *  @return totalAuctions_ Number of active auctions.
     */
    function totalAuctionsInPool() external view returns (uint256);

     /**
     *  @notice Returns the `t0Debt` state variable.
     *  @dev    This value should be multiplied by inflator in order to calculate current debt of the pool.
     *  @return The total `t0Debt` in the system, in `WAD` units.
     */
    function totalT0Debt() external view returns (uint256);

    /**
     *  @notice Returns the `t0DebtInAuction` state variable.
     *  @dev    This value should be multiplied by inflator in order to calculate current debt in auction of the pool.
     *  @return The total `t0DebtInAuction` in the system, in `WAD` units.
     */
    function totalT0DebtInAuction() external view returns (uint256);

    /**
     *  @notice Mapping of addresses that can transfer `LP` to a given lender.
     *  @param  lender_     Lender that receives `LP`.
     *  @param  transferor_ Transferor that transfers `LP`.
     *  @return True if the transferor is approved by lender.
     */
    function approvedTransferors(
        address lender_,
        address transferor_
    ) external view returns (bool);

}

/*********************/
/*** State Structs ***/
/*********************/

/******************/
/*** Pool State ***/
/******************/

/// @dev Struct holding inflator state.
struct InflatorState {
    uint208 inflator;       // [WAD] pool's inflator
    uint48  inflatorUpdate; // [SEC] last time pool's inflator was updated
}

/// @dev Struct holding pool interest state.
struct InterestState {
    uint208 interestRate;        // [WAD] pool's interest rate
    uint48  interestRateUpdate;  // [SEC] last time pool's interest rate was updated (not before 12 hours passed)
    uint256 debt;                // [WAD] previous update's debt
    uint256 meaningfulDeposit;   // [WAD] previous update's meaningfulDeposit
    uint256 t0Debt2ToCollateral; // [WAD] utilization weight accumulator, tracks debt and collateral relationship accross borrowers 
    uint256 debtCol;             // [WAD] previous debt squared to collateral
    uint256 lupt0Debt;           // [WAD] previous LUP * t0 debt
}

/// @dev Struct holding pool EMAs state.
struct EmaState {
    uint256 debtEma;             // [WAD] sample of debt EMA, numerator to MAU calculation
    uint256 depositEma;          // [WAD] sample of meaningful deposit EMA, denominator to MAU calculation
    uint256 debtColEma;          // [WAD] debt squared to collateral EMA, numerator to TU calculation
    uint256 lupt0DebtEma;        // [WAD] EMA of LUP * t0 debt, denominator to TU calculation
    uint256 emaUpdate;           // [SEC] last time pool's EMAs were updated
}

/// @dev Struct holding pool balances state.
struct PoolBalancesState {
    uint256 pledgedCollateral; // [WAD] total collateral pledged in pool
    uint256 t0DebtInAuction;   // [WAD] Total debt in auction used to restrict LPB holder from withdrawing
    uint256 t0Debt;            // [WAD] Pool debt as if the whole amount was incurred upon the first loan
}

/// @dev Struct holding pool params (in memory only).
struct PoolState {
    uint8   poolType;             // pool type, can be ERC20 or ERC721
    uint256 t0Debt;               // [WAD] t0 debt in pool
    uint256 t0DebtInAuction;      // [WAD] t0 debt in auction within pool
    uint256 debt;                 // [WAD] total debt in pool, accrued in current block
    uint256 collateral;           // [WAD] total collateral pledged in pool
    uint256 inflator;             // [WAD] current pool inflator
    bool    isNewInterestAccrued; // true if new interest already accrued in current block
    uint256 rate;                 // [WAD] pool's current interest rate
    uint256 quoteTokenScale;      // [WAD] quote token scale of the pool. Same as quote token dust.
}

/*********************/
/*** Buckets State ***/
/*********************/

/// @dev Struct holding lender state.
struct Lender {
    uint256 lps;         // [WAD] Lender LP accumulator
    uint256 depositTime; // timestamp of last deposit
}

/// @dev Struct holding bucket state.
struct Bucket {
    uint256 lps;                        // [WAD] Bucket LP accumulator
    uint256 collateral;                 // [WAD] Available collateral tokens deposited in the bucket
    uint256 bankruptcyTime;             // Timestamp when bucket become insolvent, 0 if healthy
    mapping(address => Lender) lenders; // lender address to Lender struct mapping
}

/**********************/
/*** Deposits State ***/
/**********************/

/// @dev Struct holding deposits (Fenwick) values and scaling.
struct DepositsState {
    uint256[8193] values;  // Array of values in the FenwickTree.
    uint256[8193] scaling; // Array of values which scale (multiply) the FenwickTree accross indexes.
}

/*******************/
/*** Loans State ***/
/*******************/

/// @dev Struct holding loans state.
struct LoansState {
    Loan[] loans;
    mapping (address => uint)     indices;   // borrower address => loan index mapping
    mapping (address => Borrower) borrowers; // borrower address => Borrower struct mapping
}

/// @dev Struct holding loan state.
struct Loan {
    address borrower;       // borrower address
    uint96  thresholdPrice; // [WAD] Loan's threshold price.
}

/// @dev Struct holding borrower state.
struct Borrower {
    uint256 t0Debt;     // [WAD] Borrower debt time-adjusted as if it was incurred upon first loan of pool.
    uint256 collateral; // [WAD] Collateral deposited by borrower.
    uint256 t0Np;       // [WAD] Neutral Price time-adjusted as if it was incurred upon first loan of pool.
}

/**********************/
/*** Auctions State ***/
/**********************/

/// @dev Struct holding pool auctions state.
struct AuctionsState {
    uint96  noOfAuctions;                         // total number of auctions in pool
    address head;                                 // first address in auction queue
    address tail;                                 // last address in auction queue
    uint256 totalBondEscrowed;                    // [WAD] total amount of quote token posted as auction kick bonds
    mapping(address => Liquidation) liquidations; // mapping of borrower address and auction details
    mapping(address => Kicker)      kickers;      // mapping of kicker address and kicker balances
}

/// @dev Struct holding liquidation state.
struct Liquidation {
    address kicker;       // address that initiated liquidation
    uint96  bondFactor;   // [WAD] bond factor used to start liquidation
    uint96  kickTime;     // timestamp when liquidation was started
    address prev;         // previous liquidated borrower in auctions queue
    uint96  kickMomp;     // [WAD] Momp when liquidation was started
    address next;         // next liquidated borrower in auctions queue
    uint160 bondSize;     // [WAD] liquidation bond size
    uint96  neutralPrice; // [WAD] Neutral Price when liquidation was started
    bool    alreadyTaken; // true if take has been called on auction
}

/// @dev Struct holding kicker state.
struct Kicker {
    uint256 claimable; // [WAD] kicker's claimable balance
    uint256 locked;    // [WAD] kicker's balance of tokens locked in auction bonds
}

/******************************/
/*** Reserve Auctions State ***/
/******************************/

/// @dev Struct holding reserve auction state.
struct ReserveAuctionState {
    uint256 kicked;                            // Time a Claimable Reserve Auction was last kicked.
    uint256 unclaimed;                         // [WAD] Amount of claimable reserves which has not been taken in the Claimable Reserve Auction.
    uint256 latestBurnEventEpoch;              // Latest burn event epoch.
    uint256 totalAjnaBurned;                   // [WAD] Total ajna burned in the pool.
    uint256 totalInterestEarned;               // [WAD] Total interest earned by all lenders in the pool.
    mapping (uint256 => BurnEvent) burnEvents; // Mapping burnEventEpoch => BurnEvent.
}

/// @dev Struct holding burn event state.
struct BurnEvent {
    uint256 timestamp;     // time at which the burn event occured
    uint256 totalInterest; // [WAD] current pool interest accumulator `PoolCommons.accrueInterest().newInterest`
    uint256 totalBurned;   // [WAD] burn amount accumulator
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title Pool Taker Actions
 */
interface IPoolTakerActions {

    /**
     *  @notice Called by actors to use quote token to arb higher-priced deposit off the book.
     *  @param  borrowerAddress_  Address of the borower take is being called upon.
     *  @param  depositTake_      If `true` then the take will happen at an auction price equal with bucket price. Auction price is used otherwise.
     *  @param  index_            Index of a bucket, likely the `HPB`, in which collateral will be deposited.
     */
    function bucketTake(
        address borrowerAddress_,
        bool    depositTake_,
        uint256 index_
    ) external;

    /**
     *  @notice Called by actors to purchase collateral from the auction in exchange for quote token.
     *  @param  borrowerAddress_  Address of the borower take is being called upon.
     *  @param  maxAmount_        Max amount of collateral that will be taken from the auction (`WAD` precision for `ERC20` pools, max number of `NFT`s for `ERC721` pools).
     *  @param  callee_           Identifies where collateral should be sent and where quote token should be obtained.
     *  @param  data_             If provided, take will assume the callee implements `IERC*Taker`.  Take will send collateral to 
     *                            callee before passing this data to `IERC*Taker.atomicSwapCallback`.  If not provided, 
     *                            the callback function will not be invoked.
     */
    function take(
        address        borrowerAddress_,
        uint256        maxAmount_,
        address        callee_,
        bytes calldata data_
    ) external;

    /***********************/
    /*** Reserve Auction ***/
    /***********************/

    /**
     *  @notice Purchases claimable reserves during a `CRA` using `Ajna` token.
     *  @param  maxAmount_ Maximum amount of quote token to purchase at the current auction price (`WAD` precision).
     *  @return amount_    Actual amount of reserves taken (`WAD` precision).
     */
    function takeReserves(
        uint256 maxAmount_
    ) external returns (uint256 amount_);

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { PoolType } from '../../interfaces/pool/IPool.sol';

import {
    AuctionsState,
    Borrower,
    Bucket,
    DepositsState,
    Kicker,
    Liquidation,
    LoansState,
    PoolState,
    ReserveAuctionState
}                       from '../../interfaces/pool/commons/IPoolState.sol';
import {
    SettleParams,
    SettleResult
}                       from '../../interfaces/pool/commons/IPoolInternals.sol';

import {
    _auctionPrice,
    _indexOf,
    _priceAt,
    MAX_FENWICK_INDEX,
    MIN_PRICE,
    DEPOSIT_BUFFER   
}  from '../helpers/PoolHelper.sol';

import { Buckets }  from '../internal/Buckets.sol';
import { Deposits } from '../internal/Deposits.sol';
import { Loans }    from '../internal/Loans.sol';
import { Maths }    from '../internal/Maths.sol';

/**
    @title  Auction settler library
    @notice External library containing actions involving auctions within pool:
            - `settle` auctions
 */
library SettlerActions {

    /*************************/
    /*** Local Var Structs ***/
    /*************************/

    /// @dev Struct used for `_settlePoolDebtWithDeposit` function local vars.
    struct SettleLocalVars {
        uint256 collateralUsed;     // [WAD] collateral used to settle debt
        uint256 debt;               // [WAD] debt to settle
        uint256 hpbCollateral;      // [WAD] amount of collateral in HPB bucket
        uint256 hpbUnscaledDeposit; // [WAD] unscaled amount of of quote tokens in HPB bucket before settle
        uint256 hpbLP;              // [WAD] amount of LP in HPB bucket
        uint256 index;              // index of settling bucket
        uint256 maxSettleableDebt;  // [WAD] max amount that can be settled with existing collateral
        uint256 price;              // [WAD] price of settling bucket
        uint256 scaledDeposit;      // [WAD] scaled amount of quote tokens in bucket
        uint256 scale;              // [WAD] scale of settling bucket
        uint256 unscaledDeposit;    // [WAD] unscaled amount of quote tokens in bucket
    }

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolEvents` for descriptions
    event AuctionSettle(address indexed borrower, uint256 collateral);
    event AuctionNFTSettle(address indexed borrower, uint256 collateral, uint256 lp, uint256 index);
    event BucketBankruptcy(uint256 indexed index, uint256 lpForfeited);
    event Settle(address indexed borrower, uint256 settledDebt);

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error AuctionNotClearable();
    error NoAuction();

    /***************************/
    /***  External Functions ***/
    /***************************/

    /**
     *  @notice See `IPoolSettlerActions` for descriptions.
     *  @notice Settles the debt of the given loan / borrower by performing following steps:
     *          1. settle debt with `HPB`s deposit, up to specified buckets depth.
     *          2. settle debt with pool reserves (if there's still debt and no collateral left after step 1).
     *          3. forgive bad debt from next `HPB`, up to remaining buckets depth (and if there's still debt after step 2).
     *  @dev    === Write state ===
     *  @dev    update borrower state
     *  @dev    === Reverts on ===
     *  @dev    loan is not in auction `NoAuction()`
     *  @dev    `72` hours didn't pass and auction still has collateral `AuctionNotClearable()`
     *  @dev    === Emit events ===
     *  @dev    - `Settle`
     *  @return result_ The `SettleResult` struct result of settle action.
     */
    function settlePoolDebt(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState storage loans_,
        ReserveAuctionState storage reserveAuction_,
        PoolState calldata poolState_,
        SettleParams memory params_
    ) external returns (SettleResult memory result_) {
        uint256 kickTime = auctions_.liquidations[params_.borrower].kickTime;
        if (kickTime == 0) revert NoAuction();

        Borrower memory borrower = loans_.borrowers[params_.borrower];
        if ((block.timestamp - kickTime < 72 hours) && (borrower.collateral != 0)) revert AuctionNotClearable();

        result_.debtPreAction       = borrower.t0Debt;
        result_.collateralPreAction = borrower.collateral;
        result_.t0DebtSettled       = borrower.t0Debt;
        result_.collateralSettled   = borrower.collateral;

        // 1. settle debt with HPB deposit
        (
            borrower.t0Debt,
            borrower.collateral,
            params_.bucketDepth
        ) = _settlePoolDebtWithDeposit(
            buckets_,
            deposits_,
            params_,
            borrower,
            poolState_.inflator
        );

        if (borrower.t0Debt != 0 && borrower.collateral == 0) {
            // 2. settle debt with pool reserves
            uint256 assets = Maths.floorWmul(poolState_.t0Debt - result_.t0DebtSettled + borrower.t0Debt, poolState_.inflator) + params_.poolBalance;

            uint256 liabilities =
                // require 1.0 + 1e-9 deposit buffer (extra margin) for deposits
                Maths.wmul(DEPOSIT_BUFFER, Deposits.treeSum(deposits_)) +
                auctions_.totalBondEscrowed +
                reserveAuction_.unclaimed;

            // settle debt from reserves (assets - liabilities) if reserves positive, round reserves down however
            if (assets > liabilities) {
                borrower.t0Debt -= Maths.min(borrower.t0Debt, Maths.floorWdiv(assets - liabilities, poolState_.inflator));
            }

            // 3. forgive bad debt from next HPB
            if (borrower.t0Debt != 0) {
                borrower.t0Debt = _forgiveBadDebt(
                    buckets_,
                    deposits_,
                    params_,
                    borrower,
                    poolState_.inflator
                );
            }
        }

        // complete result struct with debt settled
        result_.t0DebtSettled -= borrower.t0Debt;

        emit Settle(
            params_.borrower,
            result_.t0DebtSettled
        );

        // if entire debt was settled then settle auction
        if (borrower.t0Debt == 0) {
            (borrower.collateral, ) = _settleAuction(
                auctions_,
                buckets_,
                deposits_,
                params_.borrower,
                borrower.collateral,
                poolState_.poolType
            );
        }

        // complete result struct with debt and collateral post action and collateral settled
        result_.debtPostAction      = borrower.t0Debt;
        result_.collateralRemaining = borrower.collateral;
        result_.collateralSettled   -= result_.collateralRemaining;

        // update borrower state
        loans_.borrowers[params_.borrower] = borrower;
    }

    /***************************/
    /***  Internal Functions ***/
    /***************************/

    /**
     *  @notice Performs auction settle based on pool type, emits settle event and removes auction from auctions queue.
     *  @dev    === Emit events ===
     *  @dev    - `AuctionNFTSettle` or `AuctionSettle`
     *  @param  auctions_              Struct for pool auctions state.
     *  @param  buckets_               Struct for pool buckets state.
     *  @param  deposits_              Struct for pool deposits state.
     *  @param  borrowerAddress_       Address of the borrower that exits auction.
     *  @param  borrowerCollateral_    Borrower collateral amount before auction exit (in `NFT` could be fragmented as result of partial takes).
     *  @param  poolType_              Type of the pool (can be `ERC20` or `ERC721`).
     *  @return remainingCollateral_   Collateral remaining after auction is settled (same amount for `ERC20` pool, rounded collateral for `ERC721` pool).
     *  @return compensatedCollateral_ Amount of collateral compensated (`ERC721` settle only), to be deducted from pool pledged collateral accumulator. Always `0` for `ERC20` pools.
     */
    function _settleAuction(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        address borrowerAddress_,
        uint256 borrowerCollateral_,
        uint256 poolType_
    ) internal returns (uint256 remainingCollateral_, uint256 compensatedCollateral_) {

        if (poolType_ == uint8(PoolType.ERC721)) {
            uint256 lp;
            uint256 bucketIndex;

            // floor collateral of borrower
            remainingCollateral_ = (borrowerCollateral_ / Maths.WAD) * Maths.WAD;

            // if there's fraction of NFTs remaining then reward difference to borrower as LP in auction price bucket
            if (remainingCollateral_ != borrowerCollateral_) {

                // calculate the amount of collateral that should be compensated with LP
                compensatedCollateral_ = borrowerCollateral_ - remainingCollateral_;

                uint256 auctionPrice = _auctionPrice(
                    auctions_.liquidations[borrowerAddress_].kickMomp,
                    auctions_.liquidations[borrowerAddress_].neutralPrice,
                    auctions_.liquidations[borrowerAddress_].kickTime
                );

                // determine the bucket index to compensate fractional collateral
                bucketIndex = auctionPrice > MIN_PRICE ? _indexOf(auctionPrice) : MAX_FENWICK_INDEX;

                // deposit collateral in bucket and reward LP to compensate fractional collateral
                lp = Buckets.addCollateral(
                    buckets_[bucketIndex],
                    borrowerAddress_,
                    Deposits.valueAt(deposits_, bucketIndex),
                    compensatedCollateral_,
                    _priceAt(bucketIndex)
                );
            }

            emit AuctionNFTSettle(
                borrowerAddress_,
                remainingCollateral_,
                lp,
                bucketIndex
            );

        } else {
            remainingCollateral_ = borrowerCollateral_;

            emit AuctionSettle(
                borrowerAddress_,
                remainingCollateral_
            );
        }

        _removeAuction(auctions_, borrowerAddress_);
    }

    /**
     *  @notice Removes auction and repairs the queue order.
     *  @notice Updates kicker's claimable balance with bond size awarded and subtracts bond size awarded from `liquidationBondEscrowed`.
     *  @dev    === Write state ===
     *  @dev    decrement kicker locked accumulator, increment kicker claimable accumumlator
     *  @dev    decrement auctions count accumulator
     *  @dev    update auction queue state
     *  @param  auctions_ Struct for pool auctions state.
     *  @param  borrower_ Auctioned borrower address.
     */
    function _removeAuction(
        AuctionsState storage auctions_,
        address borrower_
    ) internal {
        Liquidation memory liquidation = auctions_.liquidations[borrower_];
        // update kicker balances
        Kicker storage kicker = auctions_.kickers[liquidation.kicker];

        kicker.locked    -= liquidation.bondSize;
        kicker.claimable += liquidation.bondSize;

        // decrement number of active auctions
        -- auctions_.noOfAuctions;

        // update auctions queue
        if (auctions_.head == borrower_ && auctions_.tail == borrower_) {
            // liquidation is the head and tail
            auctions_.head = address(0);
            auctions_.tail = address(0);
        }
        else if(auctions_.head == borrower_) {
            // liquidation is the head
            auctions_.liquidations[liquidation.next].prev = address(0);
            auctions_.head = liquidation.next;
        }
        else if(auctions_.tail == borrower_) {
            // liquidation is the tail
            auctions_.liquidations[liquidation.prev].next = address(0);
            auctions_.tail = liquidation.prev;
        }
        else {
            // liquidation is in the middle
            auctions_.liquidations[liquidation.prev].next = liquidation.next;
            auctions_.liquidations[liquidation.next].prev = liquidation.prev;
        }
        // delete liquidation
        delete auctions_.liquidations[borrower_];
    }

    /**
     *  @notice Called to settle debt using `HPB` deposits, up to the number of specified buckets depth.
     *  @dev    === Write state ===
     *  @dev    - `Deposits.unscaledRemove()` (remove amount in `Fenwick` tree, from index):
     *  @dev      update `values` array state
     *  @dev    - `Buckets.addCollateral`:
     *  @dev      increment `bucket.collateral` and `bucket.lps` accumulator
     *  @dev      increment `lender.lps` accumulator and `lender.depositTime` state
     *  @dev    === Emit events ===
     *  @dev    - `BucketBankruptcy`
     *  @param  buckets_             Struct for pool buckets state.
     *  @param  deposits_            Struct for pool deposits state.
     *  @param  params_              Struct containing params for settle action.
     *  @param  borrower_            Struct containing borrower details.
     *  @param  inflator_            Current pool inflator.
     *  @return remainingt0Debt_     Remaining borrower `t0` debt after settle with `HPB`.
     *  @return remainingCollateral_ Remaining borrower collateral after settle with `HPB`.
     *  @return bucketDepth_         Number of buckets to use for forgiving debt in case there's more remaining.
     */
    function _settlePoolDebtWithDeposit(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        SettleParams memory params_,
        Borrower memory borrower_,
        uint256 inflator_
    ) internal returns (uint256 remainingt0Debt_, uint256 remainingCollateral_, uint256 bucketDepth_) {
        remainingt0Debt_     = borrower_.t0Debt;
        remainingCollateral_ = borrower_.collateral;
        bucketDepth_         = params_.bucketDepth;

        while (bucketDepth_ != 0 && remainingt0Debt_ != 0 && remainingCollateral_ != 0) {
            SettleLocalVars memory vars;

            (vars.index, , vars.scale) = Deposits.findIndexAndSumOfSum(deposits_, 1);
            vars.hpbUnscaledDeposit    = Deposits.unscaledValueAt(deposits_, vars.index);
            vars.unscaledDeposit       = vars.hpbUnscaledDeposit;
            vars.price                 = _priceAt(vars.index);

            if (vars.unscaledDeposit != 0) {
                vars.debt              = Maths.wmul(remainingt0Debt_, inflator_);           // current debt to be settled
                vars.maxSettleableDebt = Maths.floorWmul(remainingCollateral_, vars.price); // max debt that can be settled with existing collateral
                vars.scaledDeposit     = Maths.wmul(vars.scale, vars.unscaledDeposit);

                // 1) bucket deposit covers remaining loan debt to settle, loan's collateral can cover remaining loan debt to settle
                if (vars.scaledDeposit >= vars.debt && vars.maxSettleableDebt >= vars.debt) {
                    // remove only what's needed to settle the debt
                    vars.unscaledDeposit = Maths.wdiv(vars.debt, vars.scale);
                    vars.collateralUsed  = Maths.ceilWdiv(vars.debt, vars.price);

                    // settle the entire debt
                    remainingt0Debt_ = 0;
                }
                // 2) bucket deposit can not cover all of loan's remaining debt, bucket deposit is the constraint
                else if (vars.maxSettleableDebt >= vars.scaledDeposit) {
                    vars.collateralUsed = Maths.ceilWdiv(vars.scaledDeposit, vars.price);

                    // subtract from debt the corresponding t0 amount of deposit
                    remainingt0Debt_ -= Maths.floorWdiv(vars.scaledDeposit, inflator_);
                }
                // 3) loan's collateral can not cover remaining loan debt to settle, loan collateral is the constraint
                else {
                    vars.unscaledDeposit = Maths.wdiv(vars.maxSettleableDebt, vars.scale);
                    vars.collateralUsed  = remainingCollateral_;

                    remainingt0Debt_ -= Maths.floorWdiv(vars.maxSettleableDebt, inflator_);
                }

                // remove settled collateral from loan
                remainingCollateral_ -= vars.collateralUsed;

                // use HPB bucket to swap loan collateral for loan debt
                Bucket storage hpb = buckets_[vars.index];
                vars.hpbLP         = hpb.lps;
                vars.hpbCollateral = hpb.collateral + vars.collateralUsed;

                // set amount to remove as min of calculated amount and available deposit (to prevent rounding issues)
                vars.unscaledDeposit    = Maths.min(vars.hpbUnscaledDeposit, vars.unscaledDeposit);
                vars.hpbUnscaledDeposit -= vars.unscaledDeposit;

                // remove amount to settle debt from bucket (could be entire deposit or only the settled debt)
                Deposits.unscaledRemove(deposits_, vars.index, vars.unscaledDeposit);

                // check if bucket healthy - set bankruptcy if collateral is 0 and entire deposit was used to settle and there's still LP
                if (vars.hpbCollateral == 0 && vars.hpbUnscaledDeposit == 0 && vars.hpbLP != 0) {
                    hpb.lps            = 0;
                    hpb.bankruptcyTime = block.timestamp;

                    emit BucketBankruptcy(
                        vars.index,
                        vars.hpbLP
                    );
                } else {
                    // add settled collateral into bucket
                    hpb.collateral = vars.hpbCollateral;
                }

            } else {
                // Deposits in the tree is zero, insert entire collateral into lowest bucket 7388
                Buckets.addCollateral(
                    buckets_[vars.index],
                    params_.borrower,
                    0,  // zero deposit in bucket
                    remainingCollateral_,
                    vars.price
                );
                // entire collateral added into bucket, no borrower pledged collateral remaining
                remainingCollateral_ = 0;
            }

            --bucketDepth_;
        }
    }

    /**
     *  @notice Called to forgive bad debt starting from next `HPB`, up to the number of remaining buckets depth.
     *  @dev    === Write state ===
     *  @dev    - `Deposits.unscaledRemove()` (remove amount in `Fenwick` tree, from index):
     *  @dev      update `values` array state
     *  @dev      reset `bucket.lps` accumulator and update `bucket.bankruptcyTime`
     *  @dev    === Emit events ===
     *  @dev    - `BucketBankruptcy`
     *  @param  buckets_         Struct for pool buckets state.
     *  @param  deposits_        Struct for pool deposits state.
     *  @param  params_          Struct containing params for settle action.
     *  @param  borrower_        Struct containing borrower details.
     *  @param  inflator_        Current pool inflator.
     *  @return remainingt0Debt_ Remaining borrower `t0` debt after forgiving bad debt in case not enough buckets used.
     */
    function _forgiveBadDebt(
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        SettleParams memory params_,
        Borrower memory borrower_,
        uint256 inflator_
    ) internal returns (uint256 remainingt0Debt_) {
        remainingt0Debt_ = borrower_.t0Debt;

        // loop through remaining buckets if there's still debt to forgive
        while (params_.bucketDepth != 0 && remainingt0Debt_ != 0) {

            (uint256 index, , uint256 scale) = Deposits.findIndexAndSumOfSum(deposits_, 1);
            uint256 unscaledDeposit          = Deposits.unscaledValueAt(deposits_, index);
            uint256 depositToRemove          = Maths.wmul(scale, unscaledDeposit);
            uint256 debt                     = Maths.wmul(remainingt0Debt_, inflator_);
            uint256 depositRemaining;

            // 1) bucket deposit covers entire loan debt to settle, no constraints needed
            if (depositToRemove >= debt) {
                // no remaining debt to forgive
                remainingt0Debt_ = 0;

                uint256 depositUsed = Maths.wdiv(debt, scale);
                depositRemaining = unscaledDeposit - depositUsed;

                // Remove deposit used to forgive bad debt from bucket
                Deposits.unscaledRemove(deposits_, index, depositUsed);

            // 2) loan debt to settle exceeds bucket deposit, bucket deposit is the constraint
            } else {
                // subtract from remaining debt the corresponding t0 amount of deposit
                remainingt0Debt_ -= Maths.floorWdiv(depositToRemove, inflator_);

                // Remove all deposit from bucket
                Deposits.unscaledRemove(deposits_, index, unscaledDeposit);
            }

            Bucket storage hpbBucket = buckets_[index];
            uint256 bucketLP = hpbBucket.lps;
            // If the remaining deposit and resulting bucket collateral is so small that the exchange rate
            // rounds to 0, then bankrupt the bucket.  Note that lhs are WADs, so the
            // quantity is naturally 1e18 times larger than the actual product
            if (depositRemaining * Maths.WAD + hpbBucket.collateral * _priceAt(index) <= bucketLP) {
                // existing LP for the bucket shall become unclaimable
                hpbBucket.lps            = 0;
                hpbBucket.bankruptcyTime = block.timestamp;

                emit BucketBankruptcy(
                    index,
                    bucketLP
                );
            }

            --params_.bucketDepth;
        }
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { PRBMathSD59x18 } from "@prb-math/contracts/PRBMathSD59x18.sol";
import { Math }           from '@openzeppelin/contracts/utils/math/Math.sol';

import { PoolType } from '../../interfaces/pool/IPool.sol';

import { Buckets } from '../internal/Buckets.sol';
import { Maths }   from '../internal/Maths.sol';

    error BucketIndexOutOfBounds();
    error BucketPriceOutOfBounds();

    /*************************/
    /*** Price Conversions ***/
    /*************************/

    /// @dev constant price indices defining the min and max of the potential price range
    int256  constant MAX_BUCKET_INDEX  =  4_156;
    int256  constant MIN_BUCKET_INDEX  = -3_232;
    uint256 constant MAX_FENWICK_INDEX =  7_388;

    uint256 constant MIN_PRICE = 99_836_282_890;
    uint256 constant MAX_PRICE = 1_004_968_987.606512354182109771 * 1e18;

    uint256 constant MAX_NEUTRAL_PRICE = 50_248_449_380.325617709105488550 * 1e18; // 50 * MAX_PRICE

    /// @dev deposit buffer (extra margin) used for calculating reserves
    uint256 constant DEPOSIT_BUFFER = 1.000000001 * 1e18;

    /// @dev step amounts in basis points. This is a constant across pools at `0.005`, achieved by dividing `WAD` by `10,000`
    int256 constant FLOAT_STEP_INT = 1.005 * 1e18;

    /**
     *  @notice Calculates the price (`WAD` precision) for a given `Fenwick` index.
     *  @dev    Reverts with `BucketIndexOutOfBounds` if index exceeds maximum constant.
     *  @dev    Uses fixed-point math to get around lack of floating point numbers in `EVM`.
     *  @dev    Fenwick index is converted to bucket index.
     *  @dev    Fenwick index to bucket index conversion:
     *  @dev      `1.00`      : bucket index `0`,     fenwick index `4156`: `7388-4156-3232=0`.
     *  @dev      `MAX_PRICE` : bucket index `4156`,  fenwick index `0`:    `7388-0-3232=4156`.
     *  @dev      `MIN_PRICE` : bucket index - `3232`, fenwick index `7388`: `7388-7388-3232=-3232`.
     *  @dev    `V1`: `price = MIN_PRICE + (FLOAT_STEP * index)`
     *  @dev    `V2`: `price = MAX_PRICE * (FLOAT_STEP ** (abs(int256(index - MAX_PRICE_INDEX))));`
     *  @dev    `V3 (final)`: `x^y = 2^(y*log_2(x))`
     */
    function _priceAt(
        uint256 index_
    ) pure returns (uint256) {
        // Lowest Fenwick index is highest price, so invert the index and offset by highest bucket index.
        int256 bucketIndex = MAX_BUCKET_INDEX - int256(index_);
        if (bucketIndex < MIN_BUCKET_INDEX || bucketIndex > MAX_BUCKET_INDEX) revert BucketIndexOutOfBounds();

        return uint256(
            PRBMathSD59x18.exp2(
                PRBMathSD59x18.mul(
                    PRBMathSD59x18.fromInt(bucketIndex),
                    PRBMathSD59x18.log2(FLOAT_STEP_INT)
                )
            )
        );
    }

    /**
     *  @notice Calculates the  Fenwick  index for a given price.
     *  @dev    Reverts with `BucketPriceOutOfBounds` if price exceeds maximum constant.
     *  @dev    Price expected to be inputted as a `WAD` (`18` decimal).
     *  @dev    `V1`: `bucket index = (price - MIN_PRICE) / FLOAT_STEP`
     *  @dev    `V2`: `bucket index = (log(FLOAT_STEP) * price) /  MAX_PRICE`
     *  @dev    `V3 (final)`: `bucket index =  log_2(price) / log_2(FLOAT_STEP)`
     *  @dev    `Fenwick index = 7388 - bucket index + 3232`
     */
    function _indexOf(
        uint256 price_
    ) pure returns (uint256) {
        if (price_ < MIN_PRICE || price_ > MAX_PRICE) revert BucketPriceOutOfBounds();

        int256 index = PRBMathSD59x18.div(
            PRBMathSD59x18.log2(int256(price_)),
            PRBMathSD59x18.log2(FLOAT_STEP_INT)
        );

        int256 ceilIndex = PRBMathSD59x18.ceil(index);
        if (index < 0 && ceilIndex - index > 0.5 * 1e18) {
            return uint256(4157 - PRBMathSD59x18.toInt(ceilIndex));
        }
        return uint256(4156 - PRBMathSD59x18.toInt(ceilIndex));
    }

    /**********************/
    /*** Pool Utilities ***/
    /**********************/

    /**
     *  @notice Calculates the minimum debt amount that can be borrowed or can remain in a loan in pool.
     *  @param  debt_          The debt amount to calculate minimum debt amount for.
     *  @param  loansCount_    The number of loans in pool.
     *  @return minDebtAmount_ Minimum debt amount value of the pool.
     */
    function _minDebtAmount(
        uint256 debt_,
        uint256 loansCount_
    ) pure returns (uint256 minDebtAmount_) {
        if (loansCount_ != 0) {
            minDebtAmount_ = Maths.wdiv(Maths.wdiv(debt_, Maths.wad(loansCount_)), 10**19);
        }
    }

    /**
     *  @notice Calculates origination fee for a given interest rate.
     *  @notice Calculated as greater of the current annualized interest rate divided by `52` (one week of interest) or `5` bps.
     *  @param  interestRate_ The current interest rate.
     *  @return Fee rate based upon the given interest rate.
     */
    function _borrowFeeRate(
        uint256 interestRate_
    ) pure returns (uint256) {
        // greater of the current annualized interest rate divided by 52 (one week of interest) or 5 bps
        return Maths.max(Maths.wdiv(interestRate_, 52 * 1e18), 0.0005 * 1e18);
    }

    /**
     * @notice Calculates the unutilized deposit fee, charged to lenders who deposit below the `LUP`.
     * @param  interestRate_ The current interest rate.
     * @return Fee rate based upon the given interest rate, capped at 10%.
     */
    function _depositFeeRate(
        uint256 interestRate_
    ) pure returns (uint256) {
        // current annualized rate divided by 365 (24 hours of interest), capped at 10%
        return Maths.min(Maths.wdiv(interestRate_, 365 * 1e18), 0.1 * 1e18);
    }

    /**
     *  @notice Calculates debt-weighted average threshold price.
     *  @param  t0Debt_              Pool debt owed by borrowers in `t0` terms.
     *  @param  inflator_            Pool's borrower inflator.
     *  @param  t0Debt2ToCollateral_ `t0-debt-squared-to-collateral` accumulator. 
     */
    function _dwatp(
        uint256 t0Debt_,
        uint256 inflator_,
        uint256 t0Debt2ToCollateral_
    ) pure returns (uint256) {
        return t0Debt_ == 0 ? 0 : Maths.wdiv(Maths.wmul(inflator_, t0Debt2ToCollateral_), t0Debt_);
    }

    /**
     *  @notice Collateralization calculation.
     *  @param debt_       Debt to calculate collateralization for.
     *  @param collateral_ Collateral to calculate collateralization for.
     *  @param price_      Price to calculate collateralization for.
     *  @param type_       Type of the pool.
     *  @return `True` if collateralization calculated is equal or greater than `1`.
     */
    function _isCollateralized(
        uint256 debt_,
        uint256 collateral_,
        uint256 price_,
        uint8 type_
    ) pure returns (bool) {
        if (type_ == uint8(PoolType.ERC20)) return Maths.wmul(collateral_, price_) >= debt_;
        else {
            //slither-disable-next-line divide-before-multiply
            collateral_ = (collateral_ / Maths.WAD) * Maths.WAD; // use collateral floor
            return Maths.wmul(collateral_, price_) >= debt_;
        }
    }

    /**
     *  @notice Price precision adjustment used in calculating collateral dust for a bucket.
     *          To ensure the accuracy of the exchange rate calculation, buckets with smaller prices require
     *          larger minimum amounts of collateral.  This formula imposes a lower bound independent of token scale.
     *  @param  bucketIndex_              Index of the bucket, or `0` for encumbered collateral with no bucket affinity.
     *  @return pricePrecisionAdjustment_ Unscaled integer of the minimum number of decimal places the dust limit requires.
     */
    function _getCollateralDustPricePrecisionAdjustment(
        uint256 bucketIndex_
    ) pure returns (uint256 pricePrecisionAdjustment_) {
        // conditional is a gas optimization
        if (bucketIndex_ > 3900) {
            int256 bucketOffset = int256(bucketIndex_ - 3900);
            int256 result = PRBMathSD59x18.sqrt(PRBMathSD59x18.div(bucketOffset * 1e18, int256(36 * 1e18)));
            pricePrecisionAdjustment_ = uint256(result / 1e18);
        }
    }

    /**
     *  @notice Returns the amount of collateral calculated for the given amount of `LP`.
     *  @dev    The value returned is capped at collateral amount available in bucket.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  lenderLPBalance_  The amount of `LP` to calculate collateral for.
     *  @param  bucketPrice_      Bucket's price.
     *  @return collateralAmount_ Amount of collateral calculated for the given `LP `amount.
     */
    function _lpToCollateral(
        uint256 bucketCollateral_,
        uint256 bucketLP_,
        uint256 deposit_,
        uint256 lenderLPBalance_,
        uint256 bucketPrice_
    ) pure returns (uint256 collateralAmount_) {
        collateralAmount_ = Buckets.lpToCollateral(
            bucketCollateral_,
            bucketLP_,
            deposit_,
            lenderLPBalance_,
            bucketPrice_,
            Math.Rounding.Down
        );

        if (collateralAmount_ > bucketCollateral_) {
            // user is owed more collateral than is available in the bucket
            collateralAmount_ = bucketCollateral_;
        }
    }

    /**
     *  @notice Returns the amount of quote tokens calculated for the given amount of `LP`.
     *  @dev    The value returned is capped at available bucket deposit.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  lenderLPBalance_  The amount of `LP` to calculate quote token amount for.
     *  @param  maxQuoteToken_    The max quote token amount to calculate `LP` for.
     *  @param  bucketPrice_      Bucket's price.
     *  @return quoteTokenAmount_ Amount of quote tokens calculated for the given `LP` amount, capped at available bucket deposit.
     */
    function _lpToQuoteToken(
        uint256 bucketLP_,
        uint256 bucketCollateral_,
        uint256 deposit_,
        uint256 lenderLPBalance_,
        uint256 maxQuoteToken_,
        uint256 bucketPrice_
    ) pure returns (uint256 quoteTokenAmount_) {
        quoteTokenAmount_ = Buckets.lpToQuoteTokens(
            bucketCollateral_,
            bucketLP_,
            deposit_,
            lenderLPBalance_,
            bucketPrice_,
            Math.Rounding.Down
        );

        if (quoteTokenAmount_ > deposit_)       quoteTokenAmount_ = deposit_;
        if (quoteTokenAmount_ > maxQuoteToken_) quoteTokenAmount_ = maxQuoteToken_;
    }

    /**
     *  @notice Rounds a token amount down to the minimum amount permissible by the token scale.
     *  @param  amount_       Value to be rounded.
     *  @param  tokenScale_   Scale of the token, presented as a power of `10`.
     *  @return scaledAmount_ Rounded value.
     */
    function _roundToScale(
        uint256 amount_,
        uint256 tokenScale_
    ) pure returns (uint256 scaledAmount_) {
        scaledAmount_ = (amount_ / tokenScale_) * tokenScale_;
    }

    /**
     *  @notice Rounds a token amount up to the next amount permissible by the token scale.
     *  @param  amount_       Value to be rounded.
     *  @param  tokenScale_   Scale of the token, presented as a power of `10`.
     *  @return scaledAmount_ Rounded value.
     */
    function _roundUpToScale(
        uint256 amount_,
        uint256 tokenScale_
    ) pure returns (uint256 scaledAmount_) {
        if (amount_ % tokenScale_ == 0)
            scaledAmount_ = amount_;
        else
            scaledAmount_ = _roundToScale(amount_, tokenScale_) + tokenScale_;
    }

    /*********************************/
    /*** Reserve Auction Utilities ***/
    /*********************************/

    uint256 constant MINUTE_HALF_LIFE    = 0.988514020352896135_356867505 * 1e27;  // 0.5^(1/60)

    /**
     *  @notice Calculates claimable reserves within the pool.
     *  @dev    Claimable reserve auctions and escrowed auction bonds are guaranteed by the pool.
     *  @param  debt_                    Pool's debt.
     *  @param  poolSize_                Pool's deposit size.
     *  @param  totalBondEscrowed_       Total bond escrowed.
     *  @param  reserveAuctionUnclaimed_ Pool's unclaimed reserve auction.
     *  @param  quoteTokenBalance_       Pool's quote token balance.
     *  @return claimable_               Calculated pool reserves.
     */  
    function _claimableReserves(
        uint256 debt_,
        uint256 poolSize_,
        uint256 totalBondEscrowed_,
        uint256 reserveAuctionUnclaimed_,
        uint256 quoteTokenBalance_
    ) pure returns (uint256 claimable_) {
        uint256 guaranteedFunds = totalBondEscrowed_ + reserveAuctionUnclaimed_;

        // calculate claimable reserves if there's quote token excess
        if (quoteTokenBalance_ > guaranteedFunds) {
            claimable_ = Maths.wmul(0.995 * 1e18, debt_) + quoteTokenBalance_;

            claimable_ -= Maths.min(
                claimable_,
                // require 1.0 + 1e-9 deposit buffer (extra margin) for deposits
                Maths.wmul(DEPOSIT_BUFFER, poolSize_) + guaranteedFunds
            );

            // incremental claimable reserve should not exceed excess quote in pool
            claimable_ = Maths.min(
                claimable_,
                quoteTokenBalance_ - guaranteedFunds
            );
        }
    }

    /**
     *  @notice Calculates reserves auction price.
     *  @param  reserveAuctionKicked_ Time when reserve auction was started (kicked).
     *  @return price_                Calculated auction price.
     */     
    function _reserveAuctionPrice(
        uint256 reserveAuctionKicked_
    ) view returns (uint256 price_) {
        if (reserveAuctionKicked_ != 0) {
            uint256 secondsElapsed   = block.timestamp - reserveAuctionKicked_;
            uint256 hoursComponent   = 1e27 >> secondsElapsed / 3600;
            uint256 minutesComponent = Maths.rpow(MINUTE_HALF_LIFE, secondsElapsed % 3600 / 60);

            price_ = Maths.rayToWad(1_000_000_000 * Maths.rmul(hoursComponent, minutesComponent));
        }
    }

    /*************************/
    /*** Auction Utilities ***/
    /*************************/

    /**
     *  @notice Calculates auction price.
     *  @param  kickMomp_     `MOMP` recorded at the time of kick.
     *  @param  neutralPrice_ `Neutral Price` of the auction.
     *  @param  kickTime_      Time when auction was kicked.
     *  @return price_         Calculated auction price.
     */
    function _auctionPrice(
        uint256 kickMomp_,
        uint256 neutralPrice_,
        uint256 kickTime_
    ) view returns (uint256 price_) {
        uint256 elapsedHours = Maths.wdiv((block.timestamp - kickTime_) * 1e18, 1 hours * 1e18);

        elapsedHours -= Maths.min(elapsedHours, 1e18);  // price locked during cure period

        int256 timeAdjustment  = PRBMathSD59x18.mul(-1 * 1e18, int256(elapsedHours)); 
        uint256 referencePrice = Maths.max(kickMomp_, neutralPrice_); 

        price_ = 32 * Maths.wmul(referencePrice, uint256(PRBMathSD59x18.exp2(timeAdjustment)));
    }

    /**
     *  @notice Calculates bond penalty factor.
     *  @dev    Called in kick and take.
     *  @param debt_         Borrower debt.
     *  @param collateral_   Borrower collateral.
     *  @param neutralPrice_ `NP` of auction.
     *  @param bondFactor_   Factor used to determine bondSize.
     *  @param auctionPrice_ Auction price at the time of call.
     *  @return bpf_         Factor used in determining bond `reward` (positive) or `penalty` (negative).
     */
    function _bpf(
        uint256 debt_,
        uint256 collateral_,
        uint256 neutralPrice_,
        uint256 bondFactor_,
        uint256 auctionPrice_
    ) pure returns (int256) {
        int256 thresholdPrice = int256(Maths.wdiv(debt_, collateral_));

        int256 sign;
        if (thresholdPrice < int256(neutralPrice_)) {
            // BPF = BondFactor * min(1, max(-1, (neutralPrice - price) / (neutralPrice - thresholdPrice)))
            sign = Maths.minInt(
                1e18,
                Maths.maxInt(
                    -1 * 1e18,
                    PRBMathSD59x18.div(
                        int256(neutralPrice_) - int256(auctionPrice_),
                        int256(neutralPrice_) - thresholdPrice
                    )
                )
            );
        } else {
            int256 val = int256(neutralPrice_) - int256(auctionPrice_);
            if (val < 0 )      sign = -1e18;
            else if (val != 0) sign = 1e18;
        }

        return PRBMathSD59x18.mul(int256(bondFactor_), sign);
    }

    /**
     *  @notice Calculates bond parameters of an auction.
     *  @param  borrowerDebt_ Borrower's debt before entering in liquidation.
     *  @param  collateral_   Borrower's collateral before entering in liquidation.
     *  @param  momp_         Current pool `momp`.
     */
    function _bondParams(
        uint256 borrowerDebt_,
        uint256 collateral_,
        uint256 momp_
    ) pure returns (uint256 bondFactor_, uint256 bondSize_) {
        uint256 thresholdPrice = borrowerDebt_  * Maths.WAD / collateral_;

        // bondFactor = min(30%, max(1%, (MOMP - thresholdPrice) / MOMP))
        if (thresholdPrice >= momp_) {
            bondFactor_ = 0.01 * 1e18;
        } else {
            bondFactor_ = Maths.min(
                0.3 * 1e18,
                Maths.max(
                    0.01 * 1e18,
                    1e18 - Maths.wdiv(thresholdPrice, momp_)
                )
            );
        }

        bondSize_ = Maths.wmul(bondFactor_,  borrowerDebt_);
    }

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import {
    AuctionsState,
    Borrower,
    DepositsState,
    LoansState,
    PoolBalancesState
} from '../../interfaces/pool/commons/IPoolState.sol';

import { _minDebtAmount, _priceAt } from './PoolHelper.sol';

import { Loans }    from '../internal/Loans.sol';
import { Deposits } from '../internal/Deposits.sol';
import { Maths }    from '../internal/Maths.sol';

    // See `IPoolErrors` for descriptions
    error AuctionNotCleared();
    error AmountLTMinDebt();
    error DustAmountNotExceeded();
    error LimitIndexExceeded();
    error RemoveDepositLockedByAuctionDebt();
    error TransactionExpired();

    /**
     *  @notice Called by `LP` removal functions assess whether or not `LP` is locked.
     *  @dev    Reverts with `RemoveDepositLockedByAuctionDebt` if debt locked.
     *  @param  t0DebtInAuction_ Pool's t0 debt currently in auction.
     *  @param  index_           The deposit index from which `LP` is attempting to be removed.
     *  @param  inflator_        The pool inflator used to properly assess t0 debt in auctions.
     */
    function _revertIfAuctionDebtLocked(
        DepositsState storage deposits_,
        uint256 t0DebtInAuction_,
        uint256 index_,
        uint256 inflator_
    ) view {
        if (t0DebtInAuction_ != 0 ) {
            // deposit in buckets within liquidation debt from the top-of-book down are frozen.
            if (index_ <= Deposits.findIndexOfSum(deposits_, Maths.wmul(t0DebtInAuction_, inflator_))) revert RemoveDepositLockedByAuctionDebt();
        } 
    }

    /**
     *  @notice Check if head auction is clearable (auction is kicked and `72` hours passed since kick time or auction still has debt but no remaining collateral).
     *  @dev    Reverts with `AuctionNotCleared` if auction is clearable.
     */
    function _revertIfAuctionClearable(
        AuctionsState storage auctions_,
        LoansState    storage loans_
    ) view {
        address head     = auctions_.head;
        uint256 kickTime = auctions_.liquidations[head].kickTime;
        if (kickTime != 0) {
            if (block.timestamp - kickTime > 72 hours) revert AuctionNotCleared();

            Borrower storage borrower = loans_.borrowers[head];
            if (borrower.t0Debt != 0 && borrower.collateral == 0) revert AuctionNotCleared();
        }
    }

    /**
     *  @notice  Check if provided price is at or above index limit provided by borrower.
     *  @notice  Prevents stale transactions and certain `MEV` manipulations.
     *  @dev     Reverts with `LimitIndexExceeded` if index limit provided exceeded.
     *  @param newPrice_   New price to be compared with given limit price (can be `LUP`, `NP`).
     *  @param limitIndex_ Limit price index provided by user creating the transaction.
     */
    function _revertIfPriceDroppedBelowLimit(
        uint256 newPrice_,
        uint256 limitIndex_
    ) pure {
        if (newPrice_ < _priceAt(limitIndex_)) revert LimitIndexExceeded();
    }

    /**
     *  @notice Check if expiration provided by user has met or exceeded current block height timestamp.
     *  @notice Prevents stale transactions interacting with the pool at potentially unfavorable prices.
     *  @dev    Reverts with `TransactionExpired` if expired.
     *  @param  expiry_ Expiration provided by user when creating the transaction.
     */
    function _revertAfterExpiry(
        uint256 expiry_
    ) view {
        if (block.timestamp > expiry_) revert TransactionExpired();
    }

    /**
     *  @notice Called when borrower debt changes, ensuring minimum debt rules are honored.
     *  @dev    Reverts with `DustAmountNotExceeded` if under dust amount or with `AmountLTMinDebt` if amount under min debt value.
     *  @param  loans_        Loans heap, used to determine loan count.
     *  @param  poolDebt_     Total pool debt, used to calculate average debt.
     *  @param  borrowerDebt_ New debt for the borrower, assuming the current transaction succeeds.
     *  @param  quoteDust_    Smallest amount of quote token when can be transferred, determined by token scale.
     */
    function _revertOnMinDebt(
        LoansState storage loans_,
        uint256 poolDebt_,
        uint256 borrowerDebt_,
        uint256 quoteDust_
    ) view {
        if (borrowerDebt_ != 0) {
            if (borrowerDebt_ < quoteDust_) revert DustAmountNotExceeded();
            uint256 loansCount = Loans.noOfLoans(loans_);
            if (loansCount >= 10)
                if (borrowerDebt_ < _minDebtAmount(poolDebt_, loansCount)) revert AmountLTMinDebt();
        }
    }

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';

import { Bucket, Lender } from '../../interfaces/pool/commons/IPoolState.sol';

import { Maths } from './Maths.sol';

/**
    @title  Buckets library
    @notice Internal library containing common logic for buckets management.
 */
library Buckets {

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolError` for descriptions
    error BucketBankruptcyBlock();

    /***********************************/
    /*** Bucket Management Functions ***/
    /***********************************/

    /**
     *  @notice Add collateral to a bucket and updates `LP` for bucket and lender with the amount coresponding to collateral amount added.
     *  @dev    Increment `bucket.collateral` and `bucket.lps` accumulator
     *  @dev    - `addLenderLP`:
     *  @dev    increment `lender.lps` accumulator and `lender.depositTime` state
     *  @param  lender_                Address of the lender.
     *  @param  deposit_               Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  collateralAmountToAdd_ Additional collateral amount to add to bucket.
     *  @param  bucketPrice_           Bucket price.
     *  @return addedLP_               Amount of bucket `LP` for the collateral amount added.
     */
    function addCollateral(
        Bucket storage bucket_,
        address lender_,
        uint256 deposit_,
        uint256 collateralAmountToAdd_,
        uint256 bucketPrice_
    ) internal returns (uint256 addedLP_) {
        // cannot deposit in the same block when bucket becomes insolvent
        uint256 bankruptcyTime = bucket_.bankruptcyTime;
        if (bankruptcyTime == block.timestamp) revert BucketBankruptcyBlock();

        // calculate amount of LP to be added for the amount of collateral added to bucket
        addedLP_ = collateralToLP(
            bucket_.collateral,
            bucket_.lps,
            deposit_,
            collateralAmountToAdd_,
            bucketPrice_,
            Math.Rounding.Down
        );
        // update bucket LP balance and collateral

        // update bucket collateral
        bucket_.collateral += collateralAmountToAdd_;
        // update bucket and lender LP balance and deposit timestamp
        bucket_.lps += addedLP_;

        addLenderLP(bucket_, bankruptcyTime, lender_, addedLP_);
    }

    /**
     *  @notice Add amount of `LP` for a given lender in a given bucket.
     *  @dev    Increments lender lps accumulator and updates the deposit time.
     *  @param  bucket_         Bucket to record lender `LP`.
     *  @param  bankruptcyTime_ Time when bucket become insolvent.
     *  @param  lender_         Lender address to add `LP` for in the given bucket.
     *  @param  lpAmount_       Amount of `LP` to be recorded for the given lender.
     */
    function addLenderLP(
        Bucket storage bucket_,
        uint256 bankruptcyTime_,
        address lender_,
        uint256 lpAmount_
    ) internal {
        if (lpAmount_ != 0) {
            Lender storage lender = bucket_.lenders[lender_];

            if (bankruptcyTime_ >= lender.depositTime) lender.lps = lpAmount_;
            else lender.lps += lpAmount_;

            lender.depositTime = block.timestamp;
        }
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    /****************************/
    /*** Assets to LP helpers ***/
    /****************************/

    /**
     *  @notice Returns the amount of bucket `LP` calculated for the given amount of collateral.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  collateral_       The amount of collateral to calculate bucket LP for.
     *  @param  bucketPrice_      Bucket's price.
     *  @param  rounding_         The direction of rounding when calculating LP (down when adding, up when removing collateral from pool).
     *  @return Amount of `LP` calculated for the amount of collateral.
     */
    function collateralToLP(
        uint256 bucketCollateral_,
        uint256 bucketLP_,
        uint256 deposit_,
        uint256 collateral_,
        uint256 bucketPrice_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        // case when there's no deposit nor collateral in bucket
        if (deposit_ == 0 && bucketCollateral_ == 0) return Maths.wmul(collateral_, bucketPrice_);

        // case when there's deposit or collateral in bucket but no LP to cover
        if (bucketLP_ == 0) return Maths.wmul(collateral_, bucketPrice_);

        // case when there's deposit or collateral and bucket has LP balance
        return Math.mulDiv(
            bucketLP_,
            collateral_ * bucketPrice_,
            deposit_ * Maths.WAD + bucketCollateral_ * bucketPrice_,
            rounding_
        );
    }

    /**
     *  @notice Returns the amount of `LP` calculated for the given amount of quote tokens.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  quoteTokens_      The amount of quote tokens to calculate `LP` amount for.
     *  @param  bucketPrice_      Bucket's price.
     *  @param  rounding_         The direction of rounding when calculating LP (down when adding, up when removing quote tokens from pool).
     *  @return The amount of `LP` coresponding to the given quote tokens in current bucket.
     */
    function quoteTokensToLP(
        uint256 bucketCollateral_,
        uint256 bucketLP_,
        uint256 deposit_,
        uint256 quoteTokens_,
        uint256 bucketPrice_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        // case when there's no deposit nor collateral in bucket
        if (deposit_ == 0 && bucketCollateral_ == 0) return quoteTokens_;

        // case when there's deposit or collateral in bucket but no LP to cover
        if (bucketLP_ == 0) return quoteTokens_;

        // case when there's deposit or collateral and bucket has LP balance
        return Math.mulDiv(
            bucketLP_,
            quoteTokens_ * Maths.WAD,
            deposit_ * Maths.WAD + bucketCollateral_ * bucketPrice_,
            rounding_
        );
    }

    /****************************/
    /*** LP to Assets helpers ***/
    /****************************/

    /**
     *  @notice Returns the amount of collateral calculated for the given amount of lp
     *  @dev    The value returned is not capped at collateral amount available in bucket.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  lp_               The amount of LP to calculate collateral amount for.
     *  @param  bucketPrice_      Bucket's price.
     *  @return The amount of collateral coresponding to the given `LP` in current bucket.
     */
    function lpToCollateral(
        uint256 bucketCollateral_,
        uint256 bucketLP_,
        uint256 deposit_,
        uint256 lp_,
        uint256 bucketPrice_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        // case when there's no deposit nor collateral in bucket
        if (deposit_ == 0 && bucketCollateral_ == 0) return Maths.wdiv(lp_, bucketPrice_);

        // case when there's deposit or collateral in bucket but no LP to cover
        if (bucketLP_ == 0) return Maths.wdiv(lp_, bucketPrice_);

        // case when there's deposit or collateral and bucket has LP balance
        return Math.mulDiv(
            deposit_ * Maths.WAD + bucketCollateral_ * bucketPrice_,
            lp_,
            bucketLP_ * bucketPrice_,
            rounding_
        );
    }

    /**
     *  @notice Returns the amount of quote token (in value) calculated for the given amount of `LP`.
     *  @dev    The value returned is not capped at available bucket deposit.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / `LP`.
     *  @param  lp_               The amount of LP to calculate quote tokens amount for.
     *  @param  bucketPrice_      Bucket's price.
     *  @return The amount coresponding to the given quote tokens in current bucket.
     */
    function lpToQuoteTokens(
        uint256 bucketCollateral_,
        uint256 bucketLP_,
        uint256 deposit_,
        uint256 lp_,
        uint256 bucketPrice_,
        Math.Rounding rounding_
    ) internal pure returns (uint256) {
        // case when there's no deposit nor collateral in bucket
        if (deposit_ == 0 && bucketCollateral_ == 0) return lp_;

        // case when there's deposit or collateral in bucket but no LP to cover
        if (bucketLP_ == 0) return lp_;

        // case when there's deposit or collateral and bucket has LP balance
        return Math.mulDiv(
            deposit_ * Maths.WAD + bucketCollateral_ * bucketPrice_,
            lp_,
            bucketLP_ * Maths.WAD,
            rounding_
        );
    }

    /****************************/
    /*** Exchange Rate helper ***/
    /****************************/

    /**
     *  @notice Returns the exchange rate for a given bucket (conversion of 1 lp to quote token).
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLP_         Amount of `LP` in bucket.
     *  @param  bucketDeposit_    The amount of quote tokens deposited in the given bucket.
     *  @param  bucketPrice_      Bucket's price.
     */
    function getExchangeRate(
        uint256 bucketCollateral_,
        uint256 bucketLP_,
        uint256 bucketDeposit_,
        uint256 bucketPrice_
    ) internal pure returns (uint256) {
        return lpToQuoteTokens(
            bucketCollateral_,
            bucketLP_,
            bucketDeposit_,
            Maths.WAD,
            bucketPrice_,
            Math.Rounding.Up
        );
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { Math } from '@openzeppelin/contracts/utils/math/Math.sol';

import { DepositsState } from '../../interfaces/pool/commons/IPoolState.sol';

import { _priceAt, MAX_FENWICK_INDEX } from '../helpers/PoolHelper.sol';

import { Maths } from './Maths.sol';

/**
    @title  Deposits library
    @notice Internal library containing common logic for deposits management.
    @dev    Implemented as `Fenwick Tree` data structure.
 */
library Deposits {

    /// @dev Max index supported in the `Fenwick` tree
    uint256 internal constant SIZE = 8192;

    /**
     *  @notice Increase a value in the FenwickTree at an index.
     *  @dev    Starts at leaf/target and moved up towards root
     *  @param  deposits_          Deposits state struct.
     *  @param  index_             The deposit index.
     *  @param  unscaledAddAmount_ The unscaled amount to increase deposit by.
     */
    function unscaledAdd(
        DepositsState storage deposits_,
        uint256 index_,
        uint256 unscaledAddAmount_
    ) internal {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++index_;

        // unscaledAddAmount_ is the raw amount to add directly to the value at index_, unaffected by the scale array
        // For example, to denote an amount of deposit added to the array, we would need to call unscaledAdd with
        // (deposit amount) / scale(index).  There are two reasons for this:
        // 1- scale(index) is often already known in the context of where unscaledAdd(..) is called, and we want to avoid
        //    redundant iterations through the Fenwick tree.
        // 2- We often need to precisely change the value in the tree, avoiding the rounding that dividing by scale(index).
        //    This is more relevant to unscaledRemove(...), where we need to ensure the value is precisely set to 0, but we
        //    also prefer it here for consistency.

        uint256 value;
        uint256 scaling;
        uint256 newValue;

        while (index_ <= SIZE) {
            value    = deposits_.values[index_];
            scaling  = deposits_.scaling[index_];

            // Compute the new value to be put in location index_
            newValue = value + unscaledAddAmount_;

            // Update unscaledAddAmount to propogate up the Fenwick tree
            // Note: we can't just multiply addAmount_ by scaling[i_] due to rounding
            // We need to track the precice change in values[i_] in order to ensure
            // obliterated indices remain zero after subsequent adding to related indices
            // if scaling==0, the actual scale value is 1, otherwise it is scaling
            if (scaling != 0) unscaledAddAmount_ = Maths.wmul(newValue, scaling) - Maths.wmul(value, scaling);

            deposits_.values[index_] = newValue;

            // traverse upwards through tree via "update" route
            index_ += lsb(index_);
        }
    }

    /**
     *  @notice Finds index and sum of first bucket that EXCEEDS the given sum
     *  @dev    Used in `LUP` and `MOMP` calculation
     *  @param  deposits_      Struct for deposits state.
     *  @param  targetSum_     The sum to find index for.
     *  @return sumIndex_      Smallest index where prefixsum greater than the sum.
     *  @return sumIndexSum_   Sum at index PRECEDING `sumIndex_`.
     *  @return sumIndexScale_ Scale of bucket PRECEDING `sumIndex_`.
     */
    function findIndexAndSumOfSum(
        DepositsState storage deposits_,
        uint256 targetSum_
    ) internal view returns (uint256 sumIndex_, uint256 sumIndexSum_, uint256 sumIndexScale_) {
        // i iterates over bits from MSB to LSB.  We check at each stage if the target sum is to the left or right of sumIndex_+i
        uint256 i  = 4096; // 1 << (_numBits - 1) = 1 << (13 - 1) = 4096
        uint256 runningScale = Maths.WAD;

        // We construct the target sumIndex_ bit by bit, from MSB to LSB.  lowerIndexSum_ always maintains the sum
        // up to the current value of sumIndex_
        uint256 lowerIndexSum;
        uint256 curIndex;
        uint256 value;
        uint256 scaling;
        uint256 scaledValue;

        while (i > 0) {
            // Consider if the target index is less than or greater than sumIndex_ + i
            curIndex = sumIndex_ + i;
            value    = deposits_.values[curIndex];
            scaling  = deposits_.scaling[curIndex];

            // Compute sum up to sumIndex_ + i
            scaledValue =
                lowerIndexSum +
                (
                    scaling != 0 ? Math.mulDiv(
                        runningScale * scaling,
                        value,
                        1e36
                    ) : Maths.wmul(runningScale, value)
                );

            if (scaledValue  < targetSum_) {
                // Target value is too small, need to consider increasing sumIndex_ still
                if (curIndex <= MAX_FENWICK_INDEX) {
                    // sumIndex_+i is in range of Fenwick prices.  Target index has this bit set to 1.  
                    sumIndex_ = curIndex;
                    lowerIndexSum = scaledValue;
                }
            } else {
                // Target index has this bit set to 0
                // scaling == 0 means scale factor == 1, otherwise scale factor == scaling
                if (scaling != 0) runningScale = Maths.floorWmul(runningScale, scaling);

                // Current scaledValue is <= targetSum_, it's a candidate value for sumIndexSum_
                sumIndexSum_   = scaledValue;
                sumIndexScale_ = runningScale;
            }
            // Shift i to next less significant bit
            i = i >> 1;
        }
    }

    /**
     *  @notice Finds index of passed sum. Helper function for `findIndexAndSumOfSum`.
     *  @dev    Used in `LUP` and `MOMP` calculation
     *  @param  deposits_ Deposits state struct.
     *  @param  sum_      The sum to find index for.
     *  @return sumIndex_ Smallest index where prefixsum greater than the sum.
     */
    function findIndexOfSum(
        DepositsState storage deposits_,
        uint256 sum_
    ) internal view returns (uint256 sumIndex_) {
        (sumIndex_,,) = findIndexAndSumOfSum(deposits_, sum_);
    }

    /**
     *  @notice Get least significant bit (`LSB`) of integer `i_`.
     *  @dev    Used primarily to decrement the binary index in loops, iterating over range parents.
     *  @param  i_  The integer with which to return the `LSB`.
     */
    function lsb(
        uint256 i_
    ) internal pure returns (uint256 lsb_) {
        if (i_ != 0) {
            // "i & (-i)"
            lsb_ = i_ & ((i_ ^ 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) + 1);
        }
    }

    /**
     *  @notice Scale values in the tree from the index provided, upwards.
     *  @dev    Starts at passed in node and increments through range parent nodes, and ends at `8192`.
     *  @param  deposits_ Deposits state struct.
     *  @param  index_    The index to start scaling from.
     *  @param  factor_   The factor to scale the values by.
     */
    function mult(
        DepositsState storage deposits_,
        uint256 index_,
        uint256 factor_
    ) internal {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++index_;

        uint256 sum;
        uint256 value;
        uint256 scaling;
        uint256 bit = lsb(index_);

        // Starting with the LSB of index, we iteratively move up towards the MSB of SIZE
        // Case 1:     the bit of index_ is set to 1.  In this case, the entire subtree below index_
        //             is scaled.  So, we include factor_ into scaling[index_], and remember in sum how much
        //             we increased the subtree by, so that we can use it in case we encounter 0 bits (below).
        // Case 2:     The bit of index_ is set to 0.  In this case, consider the subtree below the node
        //             index_+bit. The subtree below that is not entirely scaled, but it does contain the
        //             subtree what was scaled earlier.  Therefore: we need to increment it's stored value
        //             (in sum) which was set in a prior interation in case 1.
        while (bit <= SIZE) {
            if ((bit & index_) != 0) {
                // Case 1 as described above
                value   = deposits_.values[index_];
                scaling = deposits_.scaling[index_];

                // Calc sum, will only be stored in range parents of starting node, index_
                if (scaling != 0) {
                    // Note: we can't just multiply by factor_ - 1 in the following line, as rounding will
                    // cause obliterated indices to have nonzero values.  Need to track the actual
                    // precise delta in the value array
                    uint256 scaledFactor = Maths.wmul(factor_, scaling);

                    sum += Maths.wmul(scaledFactor, value) - Maths.wmul(scaling, value);

                    // Apply scaling to all range parents less then starting node, index_
                    deposits_.scaling[index_] = scaledFactor;
                } else {
                    // this node's scale factor is 1
                    sum += Maths.wmul(factor_, value) - value;
                    deposits_.scaling[index_] = factor_;
                }
                // Unset the bit in index to continue traversing up the Fenwick tree
                index_ -= bit;
            } else {
                // Case 2 above.  superRangeIndex is the index of the node to consider that
                //                contains the sub range that was already scaled in prior iteration
                uint256 superRangeIndex = index_ + bit;

                value   = (deposits_.values[superRangeIndex] += sum);
                scaling = deposits_.scaling[superRangeIndex];

                // Need to be careful due to rounding to propagate actual changes upwards in tree.
                // sum is always equal to the actual value we changed deposits_.values[] by
                if (scaling != 0) sum = Maths.wmul(value, scaling) - Maths.wmul(value - sum, scaling);
            }
            // consider next most significant bit
            bit = bit << 1;
        }
    }

    /**
     *  @notice Get prefix sum of all indexes from provided index downwards.
     *  @dev    Starts at tree root and decrements through range parent nodes summing from index `sumIndex_`'s range to index `0`.
     *  @param  deposits_  Deposits state struct.
     *  @param  sumIndex_  The index to receive the prefix sum.
     *  @param  sum_       The prefix sum from current index downwards.
     */
    function prefixSum(
        DepositsState storage deposits_,
        uint256 sumIndex_
    ) internal view returns (uint256 sum_) {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++sumIndex_;

        uint256 runningScale = Maths.WAD; // Tracks scale(index_) as we move down Fenwick tree
        uint256 j            = SIZE;      // bit that iterates from MSB to LSB
        uint256 index        = 0;         // build up sumIndex bit by bit

        // Used to terminate loop.  We don't need to consider final 0 bits of sumIndex_
        uint256 indexLSB = lsb(sumIndex_);
        uint256 curIndex;

        while (j >= indexLSB) {
            curIndex = index + j;

            // Skip considering indices outside bounds of Fenwick tree
            if (curIndex > SIZE) continue;

            // We are considering whether to include node index + j in the sum or not.  Either way, we need to scaling[index + j],
            // either to increment sum_ or to accumulate in runningScale
            uint256 scaled = deposits_.scaling[curIndex];

            if (sumIndex_ & j != 0) {
                // node index + j of tree is included in sum
                uint256 value = deposits_.values[curIndex];

                // Accumulate in sum_, recall that scaled==0 means that the scale factor is actually 1
                sum_  += scaled != 0 ? Math.mulDiv(
                    runningScale * scaled,
                    value,
                    1e36
                ) : Maths.wmul(runningScale, value);

                // Build up index bit by bit
                index = curIndex;

                // terminate if we've already matched sumIndex_
                if (index == sumIndex_) break;
            } else {
                // node is not included in sum, but its scale needs to be included for subsequent sums
                if (scaled != 0) runningScale = Maths.floorWmul(runningScale, scaled);
            }
            // shift j to consider next less signficant bit
            j = j >> 1;
        }
    }

    /**
     *  @notice Decrease a node in the `FenwickTree` at an index.
     *  @dev    Starts at leaf/target and moved up towards root.
     *  @param  deposits_             Deposits state struct.
     *  @param  index_                The deposit index.
     *  @param  unscaledRemoveAmount_ Unscaled amount to decrease deposit by.
     */
    function unscaledRemove(
        DepositsState storage deposits_,
        uint256 index_,
        uint256 unscaledRemoveAmount_
    ) internal {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++index_;

        // We operate with unscaledRemoveAmount_ here instead of a scaled quantity to avoid duplicate computation of scale factor
        // (thus redundant iterations through the Fenwick tree), and ALSO so that we can set the value of a given deposit exactly
        // to 0.
        
        while (index_ <= SIZE) {
            // Decrement deposits_ at index_ for removeAmount, storing new value in value
            uint256 value   = (deposits_.values[index_] -= unscaledRemoveAmount_);
            uint256 scaling = deposits_.scaling[index_];

            // If scale factor != 1, we need to adjust unscaledRemoveAmount by scale factor to adjust values further up in tree
            // On the line below, it would be tempting to replace this with:
            // unscaledRemoveAmount_ = Maths.wmul(unscaledRemoveAmount, scaling).  This will introduce nonzero values up
            // the tree due to rounding.  It's important to compute the actual change in deposits_.values[index_]
            // and propogate that upwards.
            if (scaling != 0) unscaledRemoveAmount_ = Maths.wmul(value + unscaledRemoveAmount_, scaling) - Maths.wmul(value,  scaling);

            // Traverse upward through the "update" path of the Fenwick tree
            index_ += lsb(index_);
        }
    }

    /**
     *  @notice Scale tree starting from given index.
     *  @dev    Starts at leaf/target and moved up towards root.
     *  @param  deposits_ Deposits state struct.
     *  @param  index_    The deposit index.
     *  @return scaled_   Scaled value.
     */
    function scale(
        DepositsState storage deposits_,
        uint256 index_
    ) internal view returns (uint256 scaled_) {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++index_;

        // start with scaled_1 = 1
        scaled_ = Maths.WAD;
        while (index_ <= SIZE) {
            // Traverse up through Fenwick tree via "update" path, accumulating scale factors as we go
            uint256 scaling = deposits_.scaling[index_];
            // scaling==0 means actual scale factor is 1
            if (scaling != 0) scaled_ = Maths.wmul(scaled_, scaling);
            index_ += lsb(index_);
        }
    }

    /**
     *  @notice Returns sum of all deposits.
     *  @param  deposits_ Deposits state struct.
     *  @return Sum of all deposits in tree.
     */
    function treeSum(
        DepositsState storage deposits_
    ) internal view returns (uint256) {
        // In a scaled Fenwick tree, sum is at the root node and never scaled
        return deposits_.values[SIZE];
    }

    /**
     *  @notice Returns deposit value for a given deposit index.
     *  @param  deposits_     Deposits state struct.
     *  @param  index_        The deposit index.
     *  @return depositValue_ Value of the deposit.
     */
    function valueAt(
        DepositsState storage deposits_,
        uint256 index_
    ) internal view returns (uint256 depositValue_) {
        // Get unscaled value at index and multiply by scale
        depositValue_ = Maths.wmul(unscaledValueAt(deposits_, index_), scale(deposits_,index_));
    }

    /**
     *  @notice Returns unscaled (deposit without interest) deposit value for a given deposit index.
     *  @param  deposits_             Deposits state struct.
     *  @param  index_                The deposit index.
     *  @return unscaledDepositValue_ Value of unscaled deposit.
     */
    function unscaledValueAt(
        DepositsState storage deposits_,
        uint256 index_
    ) internal view returns (uint256 unscaledDepositValue_) {
        // In a scaled Fenwick tree, sum is at the root node, but needs to be scaled
        ++index_;

        uint256 j = 1;

        // Returns the unscaled value at the node.  We consider the unscaled value for two reasons:
        // 1- If we want to zero out deposit in bucket, we need to subtract the exact unscaled value
        // 2- We may already have computed the scale factor, so we can avoid duplicate traversal

        unscaledDepositValue_ = deposits_.values[index_];
        uint256 curIndex;
        uint256 value;
        uint256 scaling;

        while (j & index_ == 0) {
            curIndex = index_ - j;

            value   = deposits_.values[curIndex];
            scaling = deposits_.scaling[curIndex];

            unscaledDepositValue_ -= scaling != 0 ? Maths.wmul(scaling, value) : value;
            j = j << 1;
        }
    }

    /**
     *  @notice Returns `LUP` for a given debt value (capped at min bucket price).
     *  @param  deposits_ Deposits state struct.
     *  @param  debt_     The debt amount to calculate `LUP` for.
     *  @return `LUP` for given debt.
     */
    function getLup(
        DepositsState storage deposits_,
        uint256 debt_
    ) internal view returns (uint256) {
        return _priceAt(findIndexOfSum(deposits_, debt_));
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import {
    AuctionsState,
    Borrower,
    DepositsState,
    Loan,
    LoansState
} from '../../interfaces/pool/commons/IPoolState.sol';

import { _priceAt } from '../helpers/PoolHelper.sol';

import { Deposits } from './Deposits.sol';
import { Maths }    from './Maths.sol';

/**
    @title  Loans library
    @notice Internal library containing common logic for loans management.
    @dev    The `Loans` heap is a `Max Heap` data structure (complete binary tree), the root node is the loan with the highest threshold price (`TP`)
            at a given time. The heap is represented as an array, where the first element is a dummy element (`Loan(address(0), 0)`) and the first
            value of the heap starts at index `1`, `ROOT_INDEX`. The threshold price of a loan's parent is always greater than or equal to the
            threshold price of the loan.
    @dev    This code was modified from the following source: https://github.com/zmitton/eth-heap/blob/master/contracts/Heap.sol
 */
library Loans {

    uint256 constant ROOT_INDEX = 1;

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error ZeroThresholdPrice();

    /***********************/
    /***  Initialization ***/
    /***********************/

    /**
     *  @notice Initializes Loans Max Heap.
     *  @dev    Organizes loans so `Highest Threshold Price` can be retrieved easily.
     *  @param  loans_ Holds Loan heap data.
     */
    function init(LoansState storage loans_) internal {
        loans_.loans.push(Loan(address(0), 0));
    }

    /***********************************/
    /***  Loans Management Functions ***/
    /***********************************/

    /**
     *  @notice Updates a loan: updates heap (`upsert` if `TP` not `0`, `remove` otherwise) and borrower balance.
     *  @dev    === Write state ===
     *  @dev    - `_upsert`:
     *  @dev      insert or update loan in `loans` array
     *  @dev    - `remove`:
     *  @dev      remove loan from `loans` array
     *  @dev    - update borrower in `address => borrower` mapping
     *  @param loans_           Holds loans heap data.
     *  @param auctions_        Struct for pool auctions state.
     *  @param deposits_        Struct for pool deposits state.
     *  @param borrower_        Borrower struct with borrower details.
     *  @param borrowerAddress_ Borrower's address to update.
     *  @param poolDebt_        Pool's current debt.
     *  @param poolRate_        Pool's current rate.
     *  @param lup_             Current LUP.
     *  @param inAuction_       Whether the loan is in auction or not.
     *  @param t0NpUpdate_      Whether the neutral price of borrower should be updated or not.
     */
    function update(
        LoansState storage loans_,
        AuctionsState storage auctions_,
        DepositsState storage deposits_,
        Borrower memory borrower_,
        address borrowerAddress_,
        uint256 poolDebt_,
        uint256 poolRate_,
        uint256 lup_,
        bool inAuction_,
        bool t0NpUpdate_
    ) internal {

        bool activeBorrower = borrower_.t0Debt != 0 && borrower_.collateral != 0;

        uint256 t0ThresholdPrice = activeBorrower ? Maths.wdiv(borrower_.t0Debt, borrower_.collateral) : 0;

        // loan not in auction, update threshold price and position in heap
        if (!inAuction_ ) {
            // get the loan id inside the heap
            uint256 loanId = loans_.indices[borrowerAddress_];
            if (activeBorrower) {
                // revert if threshold price is zero
                if (t0ThresholdPrice == 0) revert ZeroThresholdPrice();

                // update heap, insert if a new loan, update loan if already in heap
                _upsert(loans_, borrowerAddress_, loanId, uint96(t0ThresholdPrice));

            // if loan is in heap and borrwer is no longer active (no debt, no collateral) then remove loan from heap
            } else if (loanId != 0) {
                remove(loans_, borrowerAddress_, loanId);
            }
        }

        // update t0 neutral price of borrower
        if (t0NpUpdate_) {
            if (t0ThresholdPrice != 0) {
                uint256 loansInPool = loans_.loans.length - 1 + auctions_.noOfAuctions;
                uint256 curMomp     = _priceAt(Deposits.findIndexOfSum(deposits_, Maths.wdiv(poolDebt_, loansInPool * 1e18)));

                borrower_.t0Np = (1e18 + poolRate_) * curMomp * t0ThresholdPrice / lup_ / 1e18;
            } else {
                borrower_.t0Np = 0;
            }
        }

        // save borrower state
        loans_.borrowers[borrowerAddress_] = borrower_;
    }

    /**************************************/
    /***  Loans Heap Internal Functions ***/
    /**************************************/

    /**
     *  @notice Moves a `Loan` up the heap.
     *  @param loans_ Holds loans heap data.
     *  @param loan_  `Loan` to be moved.
     *  @param index_ Index of `Loan` to be moved to.
     */
    function _bubbleUp(LoansState storage loans_, Loan memory loan_, uint index_) private {
        uint256 count = loans_.loans.length;
        if (index_ == ROOT_INDEX || loan_.thresholdPrice <= loans_.loans[index_ / 2].thresholdPrice){
          _insert(loans_, loan_, index_, count);
        } else {
          _insert(loans_, loans_.loans[index_ / 2], index_, count);
          _bubbleUp(loans_, loan_, index_ / 2);
        }
    }

    /**
     *  @notice Moves a `Loan` down the heap.
     *  @param loans_ Holds loans heap data.
     *  @param loan_  `Loan` to be moved.
     *  @param index_ Index of `Loan` to be moved to.
     */
    function _bubbleDown(LoansState storage loans_, Loan memory loan_, uint index_) private {
        // Left child index.
        uint cIndex = index_ * 2;

        uint256 count = loans_.loans.length;
        if (count <= cIndex) {
            _insert(loans_, loan_, index_, count);
        } else {
            Loan memory largestChild = loans_.loans[cIndex];

            if (count > cIndex + 1 && loans_.loans[cIndex + 1].thresholdPrice > largestChild.thresholdPrice) {
                largestChild = loans_.loans[++cIndex];
            }

            if (largestChild.thresholdPrice <= loan_.thresholdPrice) {
              _insert(loans_, loan_, index_, count);
            } else {
              _insert(loans_, largestChild, index_, count);
              _bubbleDown(loans_, loan_, cIndex);
            }
        }
    }

    /**
     *  @notice Inserts a `Loan` in the heap.
     *  @param loans_ Holds loans heap data.
     *  @param loan_  `Loan` to be inserted.
     *  @param index_ Index of `Loan` to be inserted at.
     */
    function _insert(LoansState storage loans_, Loan memory loan_, uint index_, uint256 count_) private {
        if (index_ == count_) loans_.loans.push(loan_);
        else loans_.loans[index_] = loan_;

        loans_.indices[loan_.borrower] = index_;
    }

    /**
     *  @notice Removes `Loan` from heap given borrower address.
     *  @param loans_    Holds loans heap data.
     *  @param borrower_ Borrower address whose `Loan` is being updated or inserted.
     *  @param index_    Index of `Loan` to be removed.
     */
    function remove(LoansState storage loans_, address borrower_, uint256 index_) internal {
        delete loans_.indices[borrower_];
        uint256 tailIndex = loans_.loans.length - 1;
        if (index_ == tailIndex) loans_.loans.pop(); // we're removing the tail, pop without sorting
        else {
            Loan memory tail = loans_.loans[tailIndex];
            loans_.loans.pop();            // remove tail loan
            _bubbleUp(loans_, tail, index_);
            _bubbleDown(loans_, loans_.loans[index_], index_);
        }
    }

    /**
     *  @notice Performs an insert or an update dependent on borrowers existance.
     *  @param loans_          Holds loans heap data.
     *  @param borrower_       Borrower address that is being updated or inserted.
     *  @param index_          Index of `Loan` to be upserted.
     *  @param thresholdPrice_ `Threshold Price` that is updated or inserted.
     */
    function _upsert(
        LoansState storage loans_,
        address borrower_,
        uint256 index_,
        uint96 thresholdPrice_
    ) internal {
        // Loan exists, update in place.
        if (index_ != 0) {
            Loan memory currentLoan = loans_.loans[index_];
            if (currentLoan.thresholdPrice > thresholdPrice_) {
                currentLoan.thresholdPrice = thresholdPrice_;
                _bubbleDown(loans_, currentLoan, index_);
            } else {
                currentLoan.thresholdPrice = thresholdPrice_;
                _bubbleUp(loans_, currentLoan, index_);
            }

        // New loan, insert it
        } else {
            _bubbleUp(loans_, Loan(borrower_, thresholdPrice_), loans_.loans.length);
        }
    }


    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @notice Retreives `Loan` by index, `index_`.
     *  @param loans_ Holds loans heap data.
     *  @param index_ Index to retrieve `Loan`.
     *  @return `Loan` struct retrieved by index.
     */
    function getByIndex(LoansState storage loans_, uint256 index_) internal view returns(Loan memory) {
        return loans_.loans.length > index_ ? loans_.loans[index_] : Loan(address(0), 0);
    }

    /**
     *  @notice Retreives `Loan` with the highest threshold price value.
     *  @param loans_ Holds loans heap data.
     *  @return `Max Loan` in the heap.
     */
    function getMax(LoansState storage loans_) internal view returns(Loan memory) {
        return getByIndex(loans_, ROOT_INDEX);
    }

    /**
     *  @notice Returns number of loans in pool.
     *  @param loans_ Holds loans heap data.
     *  @return Number of loans in pool.
     */
    function noOfLoans(LoansState storage loans_) internal view returns (uint256) {
        return loans_.loans.length - 1;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.18;

/**
    @title  Maths library
    @notice Internal library containing common maths.
 */
library Maths {

    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y + WAD / 2) / WAD;
    }

    function floorWmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y) / WAD;
    }

    function ceilWmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y + WAD - 1) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * WAD + y / 2) / y;
    }

    function floorWdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * WAD) / y;
    }

    function ceilWdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * WAD + y - 1) / y;
    }

    function ceilDiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x + y - 1) / y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x : y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x <= y ? x : y;
    }

    function wad(uint256 x) internal pure returns (uint256) {
        return x * WAD;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y + RAY / 2) / RAY;
    }

    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rayToWad(uint256 x) internal pure returns (uint256) {
        return (x + 10**9 / 2) / 10**9;
    }

    /*************************/
    /*** Integer Functions ***/
    /*************************/

    function maxInt(int256 x, int256 y) internal pure returns (int256) {
        return x >= y ? x : y;
    }

    function minInt(int256 x, int256 y) internal pure returns (int256) {
        return x <= y ? x : y;
    }

}