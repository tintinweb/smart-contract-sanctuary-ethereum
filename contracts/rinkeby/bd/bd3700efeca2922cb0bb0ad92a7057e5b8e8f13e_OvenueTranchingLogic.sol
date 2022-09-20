// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./Math.sol";
import "./WadRayMath.sol";
import {IV2OvenueCreditLine} from "../interfaces/IV2OvenueCreditLine.sol";
import {IOvenueJuniorPool} from "../interfaces/IOvenueJuniorPool.sol";
import {IOvenueJuniorLP} from "../interfaces/IOvenueJuniorLP.sol";
import {IOvenueConfig} from "../interfaces/IOvenueConfig.sol";
import {OvenueConfigHelper} from "./OvenueConfigHelper.sol";

/**
 * @title OvenueTranchingLogic
 * @notice Library for handling the payments waterfall
 * @author Goldfinch
 */

library OvenueTranchingLogic {
    // event TranchedPoolAssessed(address indexed pool);
    event PaymentApplied(
        address indexed payer,
        address indexed pool,
        uint256 interestAmount,
        uint256 principalAmount,
        uint256 remainingAmount,
        uint256 reserveAmount
    );

    using WadRayMath for uint256;

    using OvenueConfigHelper for IOvenueConfig;

    struct SliceInfo {
        uint256 reserveFeePercent;
        uint256 interestAccrued;
        uint256 principalAccrued;
    }

    struct ApplyResult {
        uint256 interestRemaining;
        uint256 principalRemaining;
        uint256 reserveDeduction;
        uint256 oldInterestSharePrice;
        uint256 oldPrincipalSharePrice;
    }

    uint256 internal constant FP_SCALING_FACTOR = 1e18;
    uint256 public constant NUM_TRANCHES_PER_SLICE = 2;

    function usdcToSharePrice(uint256 amount, uint256 totalShares)
        public
        pure
        returns (uint256)
    {
        return
            totalShares == 0
                ? 0
                : amount.wadDiv(totalShares);
    }

    function sharePriceToUsdc(uint256 sharePrice, uint256 totalShares)
        public
        pure
        returns (uint256)
    {
        return sharePrice * totalShares / WadRayMath.WAD;
    }

    function lockTranche(
        IOvenueJuniorPool.TrancheInfo storage tranche,
        IOvenueConfig config
    ) external {
        tranche.lockedUntil = block.timestamp + (
            config.getDrawdownPeriodInSeconds()
        );
        emit TrancheLocked(address(this), tranche.id, tranche.lockedUntil);
    }

    function redeemableInterestAndPrincipal(
        IOvenueJuniorPool.TrancheInfo storage trancheInfo,
        IOvenueJuniorLP.TokenInfo memory tokenInfo
    ) public view returns (uint256, uint256) {
        // This supports withdrawing before or after locking because principal share price starts at 1
        // and is set to 0 on lock. Interest share price is always 0 until interest payments come back, when it increases
        uint256 maxPrincipalRedeemable = sharePriceToUsdc(
            trancheInfo.principalSharePrice,
            tokenInfo.principalAmount
        );
        // The principalAmount is used as the totalShares because we want the interestSharePrice to be expressed as a
        // percent of total loan value e.g. if the interest is 10% APR, the interestSharePrice should approach a max of 0.1.
        uint256 maxInterestRedeemable = sharePriceToUsdc(
            trancheInfo.interestSharePrice,
            tokenInfo.principalAmount
        );

        uint256 interestRedeemable = maxInterestRedeemable - (
            tokenInfo.interestRedeemed
        );
        uint256 principalRedeemable = maxPrincipalRedeemable - (
            tokenInfo.principalRedeemed
        );

        return (interestRedeemable, principalRedeemable);
    }

    function calculateExpectedSharePrice(
        IOvenueJuniorPool.TrancheInfo memory tranche,
        uint256 amount,
        IOvenueJuniorPool.PoolSlice memory slice
    ) public pure returns (uint256) {
        uint256 sharePrice = usdcToSharePrice(
            amount,
            tranche.principalDeposited
        );
        return _scaleByPercentOwnership(tranche, sharePrice, slice);
    }

    function scaleForSlice(
        IOvenueJuniorPool.PoolSlice memory slice,
        uint256 amount,
        uint256 totalDeployed
    ) public pure returns (uint256) {
        return scaleByFraction(amount, slice.principalDeployed, totalDeployed);
    }

    // We need to create this struct so we don't run into a stack too deep error due to too many variables
    function getSliceInfo(
        IOvenueJuniorPool.PoolSlice memory slice,
        IV2OvenueCreditLine creditLine,
        uint256 totalDeployed,
        uint256 reserveFeePercent
    ) public view returns (SliceInfo memory) {
        (
            uint256 interestAccrued,
            uint256 principalAccrued
        ) = getTotalInterestAndPrincipal(slice, creditLine, totalDeployed);
        return
            SliceInfo({
                reserveFeePercent: reserveFeePercent,
                interestAccrued: interestAccrued,
                principalAccrued: principalAccrued
            });
    }

    function getTotalInterestAndPrincipal(
        IOvenueJuniorPool.PoolSlice memory slice,
        IV2OvenueCreditLine creditLine,
        uint256 totalDeployed
    ) public view returns (uint256, uint256) {
        uint256 principalAccrued = creditLine.principalOwed();
        // In addition to principal actually owed, we need to account for early principal payments
        // If the borrower pays back 5K early on a 10K loan, the actual principal accrued should be
        // 5K (balance- deployed) + 0 (principal owed)
        principalAccrued = totalDeployed - creditLine.balance() + principalAccrued;
        // Now we need to scale that correctly for the slice we're interested in
        principalAccrued = scaleForSlice(
            slice,
            principalAccrued,
            totalDeployed
        );
        // Finally, we need to account for partial drawdowns. e.g. If 20K was deposited, and only 10K was drawn down,
        // Then principal accrued should start at 10K (total deposited - principal deployed), not 0. This is because
        // share price starts at 1, and is decremented by what was drawn down.
        uint256 totalDeposited = slice.seniorTranche.principalDeposited + (
            slice.juniorTranche.principalDeposited
        );
        principalAccrued = totalDeposited - slice.principalDeployed + principalAccrued;
        return (slice.totalInterestAccrued, principalAccrued);
    }

    function scaleByFraction(
        uint256 amount,
        uint256 fraction,
        uint256 total
    ) public pure returns (uint256) {
        // uint256 totalAsFixedPoint = FixedPoint
        //     .fromUnscaledUint(total);
        // uint256 memory fractionAsFixedPoint = FixedPoint
        //     .fromUnscaledUint(fraction);
        // return
        //     fractionAsFixedPoint
        //         .div(totalAsFixedPoint)
        //         .mul(amount)
        //         .div(FP_SCALING_FACTOR)
        //         .rawValue;

        return fraction.wadDiv(total).wadMul(amount);
    }

    /// @notice apply a payment to all slices
    /// @param poolSlices slices to apply to
    /// @param numSlices number of slices
    /// @param interest amount of interest to apply
    /// @param principal amount of principal to apply
    /// @param reserveFeePercent percentage that protocol will take for reserves
    /// @param totalDeployed total amount of principal deployed
    /// @param creditLine creditline to account for
    /// @param juniorFeePercent percentage the junior tranche will take
    /// @return total amount that will be sent to reserves
    function applyToAllSlices(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage poolSlices,
        uint256 numSlices,
        uint256 interest,
        uint256 principal,
        uint256 reserveFeePercent,
        uint256 totalDeployed,
        IV2OvenueCreditLine creditLine,
        uint256 juniorFeePercent
    ) external returns (uint256) {
        ApplyResult memory result = OvenueTranchingLogic.applyToAllSeniorTranches(
            poolSlices,
            numSlices,
            interest,
            principal,
            reserveFeePercent,
            totalDeployed,
            creditLine,
            juniorFeePercent
        );

        return
            result.reserveDeduction + (
                OvenueTranchingLogic.applyToAllJuniorTranches(
                    poolSlices,
                    numSlices,
                    result.interestRemaining,
                    result.principalRemaining,
                    reserveFeePercent,
                    totalDeployed,
                    creditLine
                )
            );
    }

    function applyToAllSeniorTranches(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage poolSlices,
        uint256 numSlices,
        uint256 interest,
        uint256 principal,
        uint256 reserveFeePercent,
        uint256 totalDeployed,
        IV2OvenueCreditLine creditLine,
        uint256 juniorFeePercent
    ) internal returns (ApplyResult memory) {
        ApplyResult memory seniorApplyResult;
        for (uint256 i = 0; i < numSlices; i++) {
            IOvenueJuniorPool.PoolSlice storage slice = poolSlices[i];

            SliceInfo memory sliceInfo = getSliceInfo(
                slice,
                creditLine,
                totalDeployed,
                reserveFeePercent
            );

            // Since slices cannot be created when the loan is late, all interest collected can be assumed to split
            // pro-rata across the slices. So we scale the interest and principal to the slice
            ApplyResult memory applyResult = applyToSeniorTranche(
                slice,
                scaleForSlice(slice, interest, totalDeployed),
                scaleForSlice(slice, principal, totalDeployed),
                juniorFeePercent,
                sliceInfo
            );
            emitSharePriceUpdatedEvent(slice.seniorTranche, applyResult);
            seniorApplyResult.interestRemaining = seniorApplyResult
                .interestRemaining
                 + (applyResult.interestRemaining);
            seniorApplyResult.principalRemaining = seniorApplyResult
                .principalRemaining
                 + (applyResult.principalRemaining);
            seniorApplyResult.reserveDeduction = seniorApplyResult
                .reserveDeduction
                 + (applyResult.reserveDeduction);
        }
        return seniorApplyResult;
    }

    function applyToAllJuniorTranches(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage poolSlices,
        uint256 numSlices,
        uint256 interest,
        uint256 principal,
        uint256 reserveFeePercent,
        uint256 totalDeployed,
        IV2OvenueCreditLine creditLine
    ) internal returns (uint256 totalReserveAmount) {
        for (uint256 i = 0; i < numSlices; i++) {
            SliceInfo memory sliceInfo = getSliceInfo(
                poolSlices[i],
                creditLine,
                totalDeployed,
                reserveFeePercent
            );
            // Any remaining interest and principal is then shared pro-rata with the junior slices
            ApplyResult memory applyResult = applyToJuniorTranche(
                poolSlices[i],
                scaleForSlice(poolSlices[i], interest, totalDeployed),
                scaleForSlice(poolSlices[i], principal, totalDeployed),
                sliceInfo
            );
            emitSharePriceUpdatedEvent(
                poolSlices[i].juniorTranche,
                applyResult
            );
            totalReserveAmount = totalReserveAmount + applyResult.reserveDeduction;
        }
        return totalReserveAmount;
    }

    function emitSharePriceUpdatedEvent(
        IOvenueJuniorPool.TrancheInfo memory tranche,
        ApplyResult memory applyResult
    ) internal {
        emit SharePriceUpdated(
            address(this),
            tranche.id,
            tranche.principalSharePrice,
            int256(
                tranche.principalSharePrice - applyResult.oldPrincipalSharePrice
            ),
            tranche.interestSharePrice,
            int256(
                tranche.interestSharePrice - applyResult.oldInterestSharePrice
            )
        );
    }

    function applyToSeniorTranche(
        IOvenueJuniorPool.PoolSlice storage slice,
        uint256 interestRemaining,
        uint256 principalRemaining,
        uint256 juniorFeePercent,
        SliceInfo memory sliceInfo
    ) internal returns (ApplyResult memory) {
        // First determine the expected share price for the senior tranche. This is the gross amount the senior
        // tranche should receive.
        uint256 expectedInterestSharePrice = calculateExpectedSharePrice(
            slice.seniorTranche,
            sliceInfo.interestAccrued,
            slice
        );
        uint256 expectedPrincipalSharePrice = calculateExpectedSharePrice(
            slice.seniorTranche,
            sliceInfo.principalAccrued,
            slice
        );

        // Deduct the junior fee and the protocol reserve
        uint256 desiredNetInterestSharePrice = scaleByFraction(
            expectedInterestSharePrice,
            uint256(100) - (juniorFeePercent + (sliceInfo.reserveFeePercent)),
            uint256(100)
        );
        // Collect protocol fee interest received (we've subtracted this from the senior portion above)
        uint256 reserveDeduction = scaleByFraction(
            interestRemaining,
            sliceInfo.reserveFeePercent,
            uint256(100)
        );
        interestRemaining = interestRemaining - reserveDeduction;
        uint256 oldInterestSharePrice = slice.seniorTranche.interestSharePrice;
        uint256 oldPrincipalSharePrice = slice
            .seniorTranche
            .principalSharePrice;
        // Apply the interest remaining so we get up to the netInterestSharePrice
        (interestRemaining, principalRemaining) = _applyBySharePrice(
            slice.seniorTranche,
            interestRemaining,
            principalRemaining,
            desiredNetInterestSharePrice,
            expectedPrincipalSharePrice
        );
        return
            ApplyResult({
                interestRemaining: interestRemaining,
                principalRemaining: principalRemaining,
                reserveDeduction: reserveDeduction,
                oldInterestSharePrice: oldInterestSharePrice,
                oldPrincipalSharePrice: oldPrincipalSharePrice
            });
    }

    function applyToJuniorTranche(
        IOvenueJuniorPool.PoolSlice storage slice,
        uint256 interestRemaining,
        uint256 principalRemaining,
        SliceInfo memory sliceInfo
    ) public returns (ApplyResult memory) {
        // Then fill up the junior tranche with all the interest remaining, upto the principal share price
        uint256 expectedInterestSharePrice = slice
            .juniorTranche
            .interestSharePrice
            + (
                usdcToSharePrice(
                    interestRemaining,
                    slice.juniorTranche.principalDeposited
                )
            );
        uint256 expectedPrincipalSharePrice = calculateExpectedSharePrice(
            slice.juniorTranche,
            sliceInfo.principalAccrued,
            slice
        );
        uint256 oldInterestSharePrice = slice.juniorTranche.interestSharePrice;
        uint256 oldPrincipalSharePrice = slice
            .juniorTranche
            .principalSharePrice;
        (interestRemaining, principalRemaining) = _applyBySharePrice(
            slice.juniorTranche,
            interestRemaining,
            principalRemaining,
            expectedInterestSharePrice,
            expectedPrincipalSharePrice
        );

        // All remaining interest and principal is applied towards the junior tranche as interest
        interestRemaining = interestRemaining + principalRemaining;
        // Since any principal remaining is treated as interest (there is "extra" interest to be distributed)
        // we need to make sure to collect the protocol fee on the additional interest (we only deducted the
        // fee on the original interest portion)
        uint256 reserveDeduction = scaleByFraction(
            principalRemaining,
            sliceInfo.reserveFeePercent,
            uint256(100)
        );
        interestRemaining = interestRemaining - reserveDeduction;
        principalRemaining = 0;

        (interestRemaining, principalRemaining) = _applyByAmount(
            slice.juniorTranche,
            interestRemaining + principalRemaining,
            0,
            interestRemaining + principalRemaining,
            0
        );
        return
            ApplyResult({
                interestRemaining: interestRemaining,
                principalRemaining: principalRemaining,
                reserveDeduction: reserveDeduction,
                oldInterestSharePrice: oldInterestSharePrice,
                oldPrincipalSharePrice: oldPrincipalSharePrice
            });
    }

    function migrateAccountingVariables(
        IV2OvenueCreditLine originalCl,
        IV2OvenueCreditLine newCl
    ) external {
        // Copy over all accounting variables
        newCl.setBalance(originalCl.balance());
        newCl.setLimit(originalCl.limit());
        newCl.setInterestOwed(originalCl.interestOwed());
        newCl.setPrincipalOwed(originalCl.principalOwed());
        newCl.setTermEndTime(originalCl.termEndTime());
        newCl.setNextDueTime(originalCl.nextDueTime());
        newCl.setInterestAccruedAsOf(originalCl.interestAccruedAsOf());
        newCl.setLastFullPaymentTime(originalCl.lastFullPaymentTime());
        newCl.setTotalInterestAccrued(originalCl.totalInterestAccrued());
    }

    function closeCreditLine(IV2OvenueCreditLine cl) external {
        // Close out old CL
        cl.setBalance(0);
        cl.setLimit(0);
        cl.setMaxLimit(0);
    }

    function trancheIdToSliceIndex(uint256 trancheId)
        external
        pure
        returns (uint256)
    {
        return (trancheId - 1) / NUM_TRANCHES_PER_SLICE;
    }

    function initializeNextSlice(
        mapping(uint256 => IOvenueJuniorPool.PoolSlice) storage poolSlices,
        uint256 sliceIndex
    ) external {
        poolSlices[sliceIndex] = IOvenueJuniorPool.PoolSlice({
            seniorTranche: IOvenueJuniorPool.TrancheInfo({
                id: sliceIndexToSeniorTrancheId(sliceIndex),
                principalSharePrice: usdcToSharePrice(1, 1),
                interestSharePrice: 0,
                principalDeposited: 0,
                lockedUntil: 0
            }),
            juniorTranche: IOvenueJuniorPool.TrancheInfo({
                id: sliceIndexToJuniorTrancheId(sliceIndex),
                principalSharePrice: usdcToSharePrice(1, 1),
                interestSharePrice: 0,
                principalDeposited: 0,
                lockedUntil: 0
            }),
            totalInterestAccrued: 0,
            principalDeployed: 0,
            collateralDeposited: 0
        });
    }

    function sliceIndexToJuniorTrancheId(uint256 sliceIndex)
        public
        pure
        returns (uint256)
    {
        // 0 -> 2
        // 1 -> 4
        return sliceIndex* NUM_TRANCHES_PER_SLICE + 2;
    }

    function sliceIndexToSeniorTrancheId(uint256 sliceIndex)
        public
        pure
        returns (uint256)
    {
        // 0 -> 1
        // 1 -> 3
        return sliceIndex * NUM_TRANCHES_PER_SLICE + 1;
    }

    function isSeniorTrancheId(uint256 trancheId) external pure returns (bool) {
        uint seniorTrancheId;
        uint numberOfTranchesPerSlice = OvenueTranchingLogic.NUM_TRANCHES_PER_SLICE;
        
        assembly {
            seniorTrancheId := mod(trancheId, numberOfTranchesPerSlice)
        }

        return seniorTrancheId == 1;
    }

    function isJuniorTrancheId(uint256 trancheId) external pure returns (bool) {
        uint juniorTrancheId;
        uint numberOfTranchesPerSlice = OvenueTranchingLogic.NUM_TRANCHES_PER_SLICE;

        assembly {
            juniorTrancheId := mod(trancheId, numberOfTranchesPerSlice)
        }

        return trancheId != 0 && juniorTrancheId == 0;
    }

    // // INTERNAL //////////////////////////////////////////////////////////////////

    function _applyToSharePrice(
        uint256 amountRemaining,
        uint256 currentSharePrice,
        uint256 desiredAmount,
        uint256 totalShares
    ) internal pure returns (uint256, uint256) {
        // If no money left to apply, or don't need any changes, return the original amounts
        if (amountRemaining == 0 || desiredAmount == 0) {
            return (amountRemaining, currentSharePrice);
        }
        if (amountRemaining < desiredAmount) {
            // We don't have enough money to adjust share price to the desired level. So just use whatever amount is left
            desiredAmount = amountRemaining;
        }
        uint256 sharePriceDifference = usdcToSharePrice(
            desiredAmount,
            totalShares
        );
        return (
            amountRemaining - desiredAmount,
            currentSharePrice + sharePriceDifference
        );
    }

    function _scaleByPercentOwnership(
        IOvenueJuniorPool.TrancheInfo memory tranche,
        uint256 amount,
        IOvenueJuniorPool.PoolSlice memory slice
    ) internal pure returns (uint256) {
        uint256 totalDeposited = slice.juniorTranche.principalDeposited + (
            slice.seniorTranche.principalDeposited
        );
        return
            scaleByFraction(amount, tranche.principalDeposited, totalDeposited);
    }

    function _desiredAmountFromSharePrice(
        uint256 desiredSharePrice,
        uint256 actualSharePrice,
        uint256 totalShares
    ) internal pure returns (uint256) {
        // If the desired share price is lower, then ignore it, and leave it unchanged
        if (desiredSharePrice < actualSharePrice) {
            desiredSharePrice = actualSharePrice;
        }
        uint256 sharePriceDifference = desiredSharePrice - actualSharePrice;
        return sharePriceToUsdc(sharePriceDifference, totalShares);
    }

    function _applyByAmount(
        IOvenueJuniorPool.TrancheInfo storage tranche,
        uint256 interestRemaining,
        uint256 principalRemaining,
        uint256 desiredInterestAmount,
        uint256 desiredPrincipalAmount
    ) internal returns (uint256, uint256) {
        uint256 totalShares = tranche.principalDeposited;
        uint256 newSharePrice;

        (interestRemaining, newSharePrice) = _applyToSharePrice(
            interestRemaining,
            tranche.interestSharePrice,
            desiredInterestAmount,
            totalShares
        );
        tranche.interestSharePrice = newSharePrice;

        (principalRemaining, newSharePrice) = _applyToSharePrice(
            principalRemaining,
            tranche.principalSharePrice,
            desiredPrincipalAmount,
            totalShares
        );
        tranche.principalSharePrice = newSharePrice;
        return (interestRemaining, principalRemaining);
    }

    function _applyBySharePrice(
        IOvenueJuniorPool.TrancheInfo storage tranche,
        uint256 interestRemaining,
        uint256 principalRemaining,
        uint256 desiredInterestSharePrice,
        uint256 desiredPrincipalSharePrice
    ) internal returns (uint256, uint256) {
        uint256 desiredInterestAmount = _desiredAmountFromSharePrice(
            desiredInterestSharePrice,
            tranche.interestSharePrice,
            tranche.principalDeposited
        );
        uint256 desiredPrincipalAmount = _desiredAmountFromSharePrice(
            desiredPrincipalSharePrice,
            tranche.principalSharePrice,
            tranche.principalDeposited
        );
        return
            _applyByAmount(
                tranche,
                interestRemaining,
                principalRemaining,
                desiredInterestAmount,
                desiredPrincipalAmount
            );
    }

    // // Events /////////////////////////////////////////////////////////////////////

    // NOTE: this needs to match the event in TranchedPool
    event TrancheLocked(
        address indexed pool,
        uint256 trancheId,
        uint256 lockedUntil
    );

    event SharePriceUpdated(
        address indexed pool,
        uint256 indexed tranche,
        uint256 principalSharePrice,
        int256 principalDelta,
        uint256 interestSharePrice,
        int256 interestDelta
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)
pragma solidity ^0.8.5;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
   
    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./IOvenueCreditLine.sol";

abstract contract IV2OvenueCreditLine is IOvenueCreditLine {
  function principal() external view virtual returns (uint256);

  function totalInterestAccrued() external view virtual returns (uint256);

  function termStartTime() external view virtual returns (uint256);

  function setLimit(uint256 newAmount) external virtual;

  function setMaxLimit(uint256 newAmount) external virtual;

  function setBalance(uint256 newBalance) external virtual;

  function setPrincipal(uint256 _principal) external virtual;

  function setTotalInterestAccrued(uint256 _interestAccrued) external virtual;

  function drawdown(uint256 amount) external virtual;

  function assess()
    external
    virtual
    returns (
      uint256,
      uint256,
      uint256
    );

  function initialize(
    address _config,
    address owner,
    address _borrower,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256 _principalGracePeriodInDays
  ) public virtual;

  function setTermEndTime(uint256 newTermEndTime) external virtual;

  function setNextDueTime(uint256 newNextDueTime) external virtual;

  function setInterestOwed(uint256 newInterestOwed) external virtual;

  function setPrincipalOwed(uint256 newPrincipalOwed) external virtual;

  function setInterestAccruedAsOf(uint256 newInterestAccruedAsOf) external virtual;

  function setWritedownAmount(uint256 newWritedownAmount) external virtual;

  function setLastFullPaymentTime(uint256 newLastFullPaymentTime) external virtual;

  function setLateFeeApr(uint256 newLateFeeApr) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

// import {ImplementationRepository} from "./proxy/ImplementationRepository.sol";
import {OvenueConfigOptions} from "../core/OvenueConfigOptions.sol";

import {IOvenueCollateralCustody} from "../interfaces/IOvenueCollateralCustody.sol";

import {IOvenueConfig} from "../interfaces/IOvenueConfig.sol";
import {IOvenueSeniorLP} from "../interfaces/IOvenueSeniorLP.sol";
import {IOvenueSeniorPool} from "../interfaces/IOvenueSeniorPool.sol";
import {IOvenueSeniorPoolStrategy} from "../interfaces/IOvenueSeniorPoolStrategy.sol";
import {IERC20withDec} from "../interfaces/IERC20withDec.sol";
// import {ICUSDCContract} from "../../interfaces/ICUSDCContract.sol";
import {IOvenueJuniorLP} from "../interfaces/IOvenueJuniorLP.sol";
import {IOvenueJuniorRewards} from "../interfaces/IOvenueJuniorRewards.sol";
import {IOvenueFactory} from "../interfaces/IOvenueFactory.sol";
import {IGo} from "../interfaces/IGo.sol";
// import {IStakingRewards} from "../../interfaces/IStakingRewards.sol";
// import {ICurveLP} from "../../interfaces/ICurveLP.sol";

/**
 * @title ConfigHelper
 * @notice A convenience library for getting easy access to other contracts and constants within the
 *  protocol, through the use of the OvenueConfig contract
 * @author Goldfinch
 */

library OvenueConfigHelper {
  function getSeniorPool(IOvenueConfig config) internal view returns (IOvenueSeniorPool) {
    return IOvenueSeniorPool(seniorPoolAddress(config));
  }

  function getSeniorPoolStrategy(IOvenueConfig config) internal view returns (IOvenueSeniorPoolStrategy) {
    return IOvenueSeniorPoolStrategy(seniorPoolStrategyAddress(config));
  }

  function getUSDC(IOvenueConfig config) internal view returns (IERC20withDec) {
    return IERC20withDec(usdcAddress(config));
  }

  function getSeniorLP(IOvenueConfig config) internal view returns (IOvenueSeniorLP) {
    return IOvenueSeniorLP(fiduAddress(config));
  }

//   function getFiduUSDCCurveLP(OvenueConfig config) internal view returns (ICurveLP) {
//     return ICurveLP(fiduUSDCCurveLPAddress(config));
//   }

//   function getCUSDCContract(OvenueConfig config) internal view returns (ICUSDCContract) {
//     return ICUSDCContract(cusdcContractAddress(config));
//   }

  function getJuniorLP(IOvenueConfig config) internal view returns (IOvenueJuniorLP) {
    return IOvenueJuniorLP(juniorLPAddress(config));
  }

  function getJuniorRewards(IOvenueConfig config) internal view returns (IOvenueJuniorRewards) {
    return IOvenueJuniorRewards(juniorRewardsAddress(config));
  }

  function getOvenueFactory(IOvenueConfig config) internal view returns (IOvenueFactory) {
    return IOvenueFactory(ovenueFactoryAddress(config));
  }

  function getOVN(IOvenueConfig config) internal view returns (IERC20withDec) {
    return IERC20withDec(ovenueAddress(config));
  }

  function getGo(IOvenueConfig config) internal view returns (IGo) {
    return IGo(goAddress(config));
  }

  function getCollateralToken(IOvenueConfig config) internal view returns (IERC20withDec) {
    return IERC20withDec(collateralTokenAddress(config));
  }

  function getCollateralCustody(IOvenueConfig config) internal view returns (IOvenueCollateralCustody) {
    return IOvenueCollateralCustody(collateralCustodyAddress(config));
  }

//   function getStakingRewards(OvenueConfig config) internal view returns (IStakingRewards) {
//     return IStakingRewards(stakingRewardsAddress(config));
//   }

  // function getTranchedPoolImplementationRepository(IOvenueConfig config)
  //   internal
  //   view
  //   returns (ImplementationRepository)
  // {
  //   return
  //     ImplementationRepository(
  //       config.getAddress(uint256(OvenueConfigOptions.Addresses.TranchedPoolImplementation))
  //     );
  // }

//   function oneInchAddress(OvenueConfig config) internal view returns (address) {
//     return config.getAddress(uint256(OvenueOvenueConfigOptions.Addresses.OneInch));
//   }

  function creditLineImplementationAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.CreditLineImplementation));
  }

//   /// @dev deprecated because we no longer use GSN
//   function trustedForwarderAddress(OvenueConfig config) internal view returns (address) {
//     return config.getAddress(uint256(OvenueOvenueConfigOptions.Addresses.TrustedForwarder));
//   }

  function collateralCustodyAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.CollateralCustody));
  }
  function configAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.OvenueConfig));
  }

  function juniorLPAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.PoolTokens));
  }

  function juniorRewardsAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.JuniorRewards));
  }

  function seniorPoolAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.SeniorPool));
  }

  function seniorPoolStrategyAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.SeniorPoolStrategy));
  }

  function ovenueFactoryAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.OvenueFactory));
  }

  function ovenueAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.OVENUE));
  }

  function fiduAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.Fidu));
  }

  function collateralTokenAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.CollateralToken));
  }

//   function fiduUSDCCurveLPAddress(OvenueConfig config) internal view returns (address) {
//     return config.getAddress(uint256(OvenueConfigOptions.Addresses.FiduUSDCCurveLP));
//   }

//   function cusdcContractAddress(OvenueConfig config) internal view returns (address) {
//     return config.getAddress(uint256(OvenueConfigOptions.Addresses.CUSDCContract));
//   }

  function usdcAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.USDC));
  }

  function tranchedPoolAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.TranchedPoolImplementation));
  }

  function reserveAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.TreasuryReserve));
  }

  function protocolAdminAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.ProtocolAdmin));
  }

  function borrowerImplementationAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.BorrowerImplementation));
  }

  function goAddress(IOvenueConfig config) internal view returns (address) {
    return config.getAddress(uint256(OvenueConfigOptions.Addresses.Go));
  }

//   function stakingRewardsAddress(OvenueConfig config) internal view returns (address) {
//     return config.getAddress(uint256(OvenueConfigOptions.Addresses.StakingRewards));
//   }

  function getCollateraLockupPeriod(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.CollateralLockedUpInSeconds));
  }

  function getReserveDenominator(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.ReserveDenominator));
  }

  function getWithdrawFeeDenominator(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.WithdrawFeeDenominator));
  }

  function getLatenessGracePeriodInDays(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.LatenessGracePeriodInDays));
  }

  function getLatenessMaxDays(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.LatenessMaxDays));
  }

  function getDrawdownPeriodInSeconds(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.DrawdownPeriodInSeconds));
  }

  function getTransferRestrictionPeriodInDays(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.TransferRestrictionPeriodInDays));
  }

  function getLeverageRatio(IOvenueConfig config) internal view returns (uint256) {
    return config.getNumber(uint256(OvenueConfigOptions.Numbers.LeverageRatio));
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.5;

/**
 * @title WadRayMath library
 * @author Aave
 * @notice Provides functions to perform calculations with Wad and Ray units
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits of precision) and rays (decimal numbers
 * with 27 digits of precision)
 * @dev Operations are rounded. If a value is >=.5, will be rounded up, otherwise rounded down.
 **/
library WadRayMath {
  // HALF_WAD and HALF_RAY expressed with extended notation as constant with operations are not supported in Yul assembly
  uint256 internal constant WAD = 1e18;
  uint256 internal constant HALF_WAD = 0.5e18;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant HALF_RAY = 0.5e27;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_WAD) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_WAD), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_WAD), WAD)
    }
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @param b Wad
   * @return c = a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / WAD
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), WAD))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, WAD), div(b, 2)), b)
    }
  }

  /**
   * @notice Multiplies two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raymul b
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - HALF_RAY) / b
    assembly {
      if iszero(or(iszero(b), iszero(gt(a, div(sub(not(0), HALF_RAY), b))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, b), HALF_RAY), RAY)
    }
  }

  /**
   * @notice Divides two ray, rounding half up to the nearest ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @param b Ray
   * @return c = a raydiv b
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // to avoid overflow, a <= (type(uint256).max - halfB) / RAY
    assembly {
      if or(iszero(b), iszero(iszero(gt(a, div(sub(not(0), div(b, 2)), RAY))))) {
        revert(0, 0)
      }

      c := div(add(mul(a, RAY), div(b, 2)), b)
    }
  }

  /**
   * @dev Casts ray down to wad
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Ray
   * @return b = a converted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256 b) {
    assembly {
      b := div(a, WAD_RAY_RATIO)
      let remainder := mod(a, WAD_RAY_RATIO)
      if iszero(lt(remainder, div(WAD_RAY_RATIO, 2))) {
        b := add(b, 1)
      }
    }
  }

  /**
   * @dev Converts wad up to ray
   * @dev assembly optimized for improved gas savings, see https://twitter.com/transmissions11/status/1451131036377571328
   * @param a Wad
   * @return b = a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256 b) {
    // to avoid overflow, b/WAD_RAY_RATIO == a
    assembly {
      b := mul(a, WAD_RAY_RATIO)

      if iszero(eq(div(b, WAD_RAY_RATIO), a)) {
        revert(0, 0)
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import {IV2OvenueCreditLine} from "./IV2OvenueCreditLine.sol";

abstract contract IOvenueJuniorPool {
    IV2OvenueCreditLine public creditLine;
    uint256 public createdAt;

     struct Collateral {
        address nftAddr;
        uint tokenId;
        uint collateralAmount;
        bool isLocked;
    }

    enum Tranches {
        Reserved,
        Senior,
        Junior
    }

    struct TrancheInfo {
        uint256 id;
        uint256 principalDeposited;
        uint256 principalSharePrice;
        uint256 interestSharePrice;
        uint256 lockedUntil;
    }

    struct PoolSlice {
        TrancheInfo seniorTranche;
        TrancheInfo juniorTranche;
        uint256 totalInterestAccrued;
        uint256 principalDeployed;
        uint256 collateralDeposited;
    }

    function initialize(
        // config - borrower
        address[2] calldata _addresses,
        // junior fee percent - late fee apr, interest apr
        uint256[3] calldata _fees,
        // _paymentPeriodInDays - _termInDays - _principalGracePeriodInDays - _fundableAt
        uint256[4] calldata _days,
        uint256 _limit,
        uint256[] calldata _allowedUIDTypes
    ) external virtual;

    function getTranche(uint256 tranche)
        external
        view
        virtual
        returns (TrancheInfo memory);

    function pay(uint256 amount) external virtual;

    function poolSlices(uint256 index)
        external
        view
        virtual
        returns (PoolSlice memory);

    function lockJuniorCapital() external virtual;

    function lockPool() external virtual;

    function initializeNextSlice(uint256 _fundableAt) external virtual;

    function totalJuniorDeposits() external view virtual returns (uint256);

    function drawdown(uint256 amount) external virtual;

    function setFundableAt(uint256 timestamp) external virtual;

    function deposit(uint256 tranche, uint256 amount)
        external
        virtual
        returns (uint256 tokenId);

    function assess() external virtual;

    function depositWithPermit(
        uint256 tranche,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual returns (uint256 tokenId);

    function availableToWithdraw(uint256 tokenId)
        external
        view
        virtual
        returns (uint256 interestRedeemable, uint256 principalRedeemable);

    function withdraw(uint256 tokenId, uint256 amount)
        external
        virtual
        returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

    function withdrawMax(uint256 tokenId)
        external
        virtual
        returns (uint256 interestWithdrawn, uint256 principalWithdrawn);

    function withdrawMultiple(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts
    ) external virtual;

    // function claimCollateralNFT() external virtual;

    function numSlices() external view virtual returns (uint256);
    // function isCollateralLocked() external view virtual returns (bool);

    // function getCollateralInfo() external view virtual returns(address, uint, bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

interface IOvenueJuniorLP is IERC721Upgradeable {
    event TokenPrincipalWithdrawn(
        address indexed owner,
        address indexed pool,
        uint256 indexed tokenId,
        uint256 principalWithdrawn,
        uint256 tranche
    );
    event TokenBurned(
        address indexed owner,
        address indexed pool,
        uint256 indexed tokenId
    );
    event TokenMinted(
        address indexed owner,
        address indexed pool,
        uint256 indexed tokenId,
        uint256 amount,
        uint256 tranche
    );

    event TokenRedeemed(
        address indexed owner,
        address indexed pool,
        uint256 indexed tokenId,
        uint256 principalRedeemed,
        uint256 interestRedeemed,
        uint256 tranche
    );

    struct TokenInfo {
        address pool;
        uint256 tranche;
        uint256 principalAmount;
        uint256 principalRedeemed;
        uint256 interestRedeemed;
    }

    struct MintParams {
        uint256 principalAmount;
        uint256 tranche;
    }

    function mint(MintParams calldata params, address to)
        external
        returns (uint256);

    function redeem(
        uint256 tokenId,
        uint256 principalRedeemed,
        uint256 interestRedeemed
    ) external;

    function withdrawPrincipal(uint256 tokenId, uint256 principalAmount)
        external;

    function burn(uint256 tokenId) external;

    function onPoolCreated(address newPool) external;

    function getTokenInfo(uint256 tokenId)
        external
        view
        returns (TokenInfo memory);

    function validPool(address sender) external view returns (bool);

    function isApprovedOrOwner(address spender, uint256 tokenId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IOvenueConfig {
  function getNumber(uint256 index) external view returns (uint256);

  function getAddress(uint256 index) external view returns (address);

  function setAddress(uint256 index, address newAddress) external returns (address);

  function setNumber(uint256 index, uint256 newNumber) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IOvenueCreditLine {
  function borrower() external view returns (address);

  function limit() external view returns (uint256);

  function maxLimit() external view returns (uint256);

  function interestApr() external view returns (uint256);

  function paymentPeriodInDays() external view returns (uint256);

  function principalGracePeriodInDays() external view returns (uint256);

  function termInDays() external view returns (uint256);

  function lateFeeApr() external view returns (uint256);

  function isLate() external view returns (bool);

  function withinPrincipalGracePeriod() external view returns (bool);

  // Accounting variables
  function balance() external view returns (uint256);

  function interestOwed() external view returns (uint256);

  function principalOwed() external view returns (uint256);

  function termEndTime() external view returns (uint256);

  function nextDueTime() external view returns (uint256);

  function interestAccruedAsOf() external view returns (uint256);

  function lastFullPaymentTime() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20withDec is IERC20Upgradeable {
  /**
   * @dev Returns the number of decimals used for the token
   */
  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./IOvenueSeniorPool.sol";
import "./IOvenueJuniorPool.sol";

abstract contract IOvenueSeniorPoolStrategy {
//   function getLeverageRatio(IOvenueJuniorPool pool) public view virtual returns (uint256);
  function getLeverageRatio() public view virtual returns (uint256);

  function invest(IOvenueJuniorPool pool) public view virtual returns (uint256 amount);

  function estimateInvestment(IOvenueJuniorPool pool) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./IERC20withDec.sol";

interface IOvenueSeniorLP is IERC20withDec {
  function mintTo(address to, uint256 amount) external;

  function burnFrom(address to, uint256 amount) external;

  function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IOvenueJuniorRewards {
  function allocateRewards(uint256 _interestPaymentAmount) external;

  // function onTranchedPoolDrawdown(uint256 sliceIndex) external;

  function setPoolTokenAccRewardsPerPrincipalDollarAtMint(address poolAddress, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./IOvenueJuniorPool.sol";

interface IOvenueCollateralCustody {
    function isCollateralFullyFunded(IOvenueJuniorPool _poolAddr) external virtual returns(bool);
    function createCollateralStats(
        IOvenueJuniorPool _poolAddr,
        address _nftAddr,
        uint256 _tokenId,
        uint256 _fungibleAmount
    ) external virtual;
    
    function collectFungibleCollateral(
        IOvenueJuniorPool _poolAddr,
        address _depositor,
        uint256 _amount
    ) external virtual;

    function redeemAllCollateral(
        IOvenueJuniorPool _poolAddr,
        address receiver
    ) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

interface IOvenueFactory {
  function createCreditLine() external returns (address);

  function createBorrower(address owner) external returns (address);

  function createPool(
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256[] calldata _allowedUIDTypes
  ) external returns (address);

  function createMigratedPool(
    address _borrower,
    uint256 _juniorFeePercent,
    uint256 _limit,
    uint256 _interestApr,
    uint256 _paymentPeriodInDays,
    uint256 _termInDays,
    uint256 _lateFeeApr,
    uint256[] calldata _allowedUIDTypes
  ) external returns (address);

  function updateGoldfinchConfig() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

abstract contract IGo {
  uint256 public constant ID_TYPE_0 = 0;
  uint256 public constant ID_TYPE_1 = 1;
  uint256 public constant ID_TYPE_2 = 2;
  uint256 public constant ID_TYPE_3 = 3;
  uint256 public constant ID_TYPE_4 = 4;
  uint256 public constant ID_TYPE_5 = 5;
  uint256 public constant ID_TYPE_6 = 6;
  uint256 public constant ID_TYPE_7 = 7;
  uint256 public constant ID_TYPE_8 = 8;
  uint256 public constant ID_TYPE_9 = 9;
  uint256 public constant ID_TYPE_10 = 10;

  /// @notice Returns the address of the UniqueIdentity contract.
  function uniqueIdentity() external virtual returns (address);

  function go(address account) public view virtual returns (bool);

  function goOnlyIdTypes(address account, uint256[] calldata onlyIdTypes) public view virtual returns (bool);

  function goSeniorPool(address account) public view virtual returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

import "./IOvenueJuniorPool.sol";

abstract contract IOvenueSeniorPool {
  uint256 public sharePrice;
  uint256 public totalLoansOutstanding;
  uint256 public totalWritedowns;

  function deposit(uint256 amount) external virtual returns (uint256 depositShares);

  function depositWithPermit(
    uint256 amount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external virtual returns (uint256 depositShares);

  function withdraw(uint256 usdcAmount) external virtual returns (uint256 amount);

  function withdrawInLP(uint256 fiduAmount) external virtual returns (uint256 amount);

//   function sweepToCompound() public virtual;

//   function sweepFromCompound() public virtual;

  function invest(IOvenueJuniorPool pool) public virtual;

  function estimateInvestment(IOvenueJuniorPool pool) public view virtual returns (uint256);

  function redeem(uint256 tokenId) public virtual;

  function writedown(uint256 tokenId) public virtual;

  function calculateWritedown(uint256 tokenId) public view virtual returns (uint256 writedownAmount);

  function assets() public view virtual returns (uint256);

  function getNumShares(uint256 amount) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;

/**
 * @title ConfigOptions
 * @notice A central place for enumerating the configurable options of our GoldfinchConfig contract
 * @author Goldfinch
 */

library OvenueConfigOptions {
  // NEVER EVER CHANGE THE ORDER OF THESE!
  // You can rename or append. But NEVER change the order.
  enum Numbers {
    TransactionLimit, // 0
    /// @dev: TotalFundsLimit used to represent a total cap on senior pool deposits
    /// but is now deprecated
    TotalFundsLimit, // 1
    MaxUnderwriterLimit, // 2
    ReserveDenominator, // 3
    WithdrawFeeDenominator, // 4
    LatenessGracePeriodInDays, // 5
    LatenessMaxDays, // 6
    DrawdownPeriodInSeconds, // 7
    TransferRestrictionPeriodInDays, // 8
    LeverageRatio, // 9
    CollateralLockedUpInSeconds // 10
  }
  /// @dev TrustedForwarder is deprecated because we no longer use GSN. CreditDesk
  ///   and Pool are deprecated because they are no longer used in the protocol.
  enum Addresses {
    CreditLineImplementation, // 0
    OvenueFactory, // 1
    Fidu, // 2
    USDC, // 3
    OVENUE, // 4
    TreasuryReserve, // 5
    ProtocolAdmin, // 6
    // OneInch,
    // CUSDCContract,
    OvenueConfig, // 7
    PoolTokens, // 8
    SeniorPool, // 9
    SeniorPoolStrategy, // 10
    TranchedPoolImplementation, // 11
    BorrowerImplementation, // 12
    // OVENUE, 
    Go, // 13
    JuniorRewards, // 14
    CollateralToken, // 15
    CollateralCustody // 16
    // StakingRewards
    // FiduUSDCCurveLP
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
interface IERC165Upgradeable {
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