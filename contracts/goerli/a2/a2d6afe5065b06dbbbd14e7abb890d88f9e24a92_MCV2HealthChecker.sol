// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

contract MCV2HealthChecker {

    /******************************************************************************************************************************/
    /*** Invariant Tests                                                                                                        ***/
    /*******************************************************************************************************************************
     * Loan
        * Invariant A: collateral balance >= _collateral`
        * Invariant B: fundsAsset >= _drawableFunds`
        * Invariant C: `_collateral >= collateralRequired_ * (principal_ - drawableFunds_) / principalRequested_`
        Note: Invariant C Not Tracked as `makePayment` does not include a `_isCollateralMaintained` check. This will be added in a subsequent loan release.

     * Loan Manager (non-liquidating)
        * Invariant A: domainStart <= domainEnd
        * Invariant B: sortedPayments is always sorted
        * Invariant C: outstandingInterest = ∑outstandingInterest(loan) (theoretical)  Note: Not tracked as unable to calculate theoretical value
        * Invariant D: totalPrincipal = ∑loan.principal()
        * Invariant E: issuanceRate = ∑issuanceRate(payment)
        * Invariant F: unrealizedLosses <= assetsUnderManagement()
        * Invariant G: unrealizedLosses == 0  Note: Not Tracked
        * Invariant H: assetsUnderManagement == ∑loan.principal() + ∑outstandingInterest(loan)  Note: Not tracked as unable to calculate theoretical value
        * Invariant I: domainStart <= block.timestamp
        * Invariant J: if (loanManager.paymentWithEarliestDueDate != 0) then issuanceRate > 0
        * Invariant K: if (loanManager.paymentWithEarliestDueDate != 0) then domainEnd == paymentWithEarliestDueDate
        * Invariant L: refinanceInterest[payment] = loan.refinanceInterest()
        * Invariant M: paymentDueDate[payment] = loan.paymentDueDate()  Note: Not tracked
        * Invariant N: startDate[payment] <= loan.paymentDueDate() - loan.paymentInterval()  Note: Not tracked

     * Pool (non-liquidating)
        * Invariant A: totalAssets > fundsAsset balance of pool
        * Invariant B: ∑balanceOfAssets == totalAssets (with rounding)
        * Invariant C: totalAssets >= totalSupply (in non-liquidating scenario)  Note: Not tracked
        * Invariant D: convertToAssets(totalSupply) == totalAssets (with rounding)
        * Invariant E: convertToShares(totalAssets) == totalSupply (with rounding)
        * Invariant F: balanceOfAssets[user] >= balanceOf[user]  Note: Not tracked
        * Invariant G: ∑balanceOf[user] == totalSupply
        * Invariant H: convertToExitShares == convertToShares  Note: Not tracked
        * Invariant I: totalAssets == poolManager.totalAssets()
        * Invariant J: unrealizedLosses == poolManager.unrealizedLosses()
        * Invariant K: convertToExitShares == poolManager.convertToExitShares()

     * PoolManager (non-liquidating)
        * Invariant A: totalAssets == cash + ∑assetsUnderManagement[loanManager]
        * Invariant B: hasSufficientCover == fundsAsset balance of cover > globals.minCoverAmount

     * Withdrawal Manager
        * Invariant A: WM LP balance == ∑lockedShares(user)
        * Invariant B: totalCycleShares == ∑lockedShares(user)[cycle] (for all cycles)  Note: Not tracked as no easy way to know al cycles
        * Invariant C: windowStart[currentCycle] <= block.timestamp
        * Invariant D: initialCycleTime[currentConfig] <= block.timestamp
        * Invariant E: initialCycleId[currentConfig] <= currentCycle
        * Invariant F: getRedeemableAmounts.shares[owner] <= WM LP balance
        * Invariant G: getRedeemableAmounts.shares[owner] <= lockedShares[user]
        * Invariant H: getRedeemableAmounts.shares[owner] <= totalCycleShares[exitCycleId[user]]
        * Invariant I: getRedeemableAmounts.assets[owner] <= fundsAsset balance of pool
        * Invariant J: getRedeemableAmounts.assets[owner] <= totalCycleShares[exitCycleId[user]] * exchangeRate
        * Invariant K: getRedeemableAmounts.assets[owner] <= lockedShares[user] * exchangeRate
        * Invariant L: getRedeemableAmounts.partialLiquidity == (lockedShares[user] * exchangeRate < fundsAsset balance of pool)  Note: Not tracked
        * Invariant M: lockedLiquidity <= pool.totalAssets()
        * Invariant N: lockedLiquidity <= totalCycleShares[exitCycleId[user]] * exchangeRate

    *******************************************************************************************************************************/

    // Struct to avoid stack too deep compiler error.
    struct Invariants {
        bool loanInvariantA;
        bool loanInvariantB;
        bool loanManagerInvariantA;
        bool loanManagerInvariantB;
        bool loanManagerInvariantD;
        bool loanManagerInvariantE;
        bool loanManagerInvariantF;
        bool loanManagerInvariantI;
        bool loanManagerInvariantJ;
        bool loanManagerInvariantK;
        bool loanManagerInvariantL;
        bool poolInvariantA;
        bool poolInvariantB;
        bool poolInvariantD;
        bool poolInvariantE;
        bool poolInvariantG;
        bool poolInvariantI;
        bool poolInvariantJ;
        bool poolInvariantK;
        bool poolManagerInvariantA;
        bool poolManagerInvariantB;
        bool withdrawalManagerInvariantA;
        bool withdrawalManagerInvariantC;
        bool withdrawalManagerInvariantD;
        bool withdrawalManagerInvariantE;
        bool withdrawalManagerInvariantF;
        bool withdrawalManagerInvariantG;
        bool withdrawalManagerInvariantH;
        bool withdrawalManagerInvariantI;
        bool withdrawalManagerInvariantJ;
        bool withdrawalManagerInvariantK;
        bool withdrawalManagerInvariantM;
        bool withdrawalManagerInvariantN;
    }

    bool flag;

    function checkInvariants(address poolManager_, address[] memory activeLoans_, address[] memory poolLps_) external view returns (Invariants memory invariants_){

        invariants_.loanInvariantA = true;
        invariants_.loanInvariantB = false;

        invariants_.loanManagerInvariantA = flag ? false : true;
        invariants_.loanManagerInvariantB = flag ? false : true;
        invariants_.loanManagerInvariantD = flag ? false : true;
        invariants_.loanManagerInvariantE = flag ? false : true;
        invariants_.loanManagerInvariantF = flag ? false : true;
        invariants_.loanManagerInvariantI = flag ? false : true;
        invariants_.loanManagerInvariantJ = flag ? false : true;
        invariants_.loanManagerInvariantK = flag ? false : true;
        invariants_.loanManagerInvariantL = flag ? false : true;

        invariants_.poolInvariantA = flag ? false : true;
        invariants_.poolInvariantB = flag ? false : true;
        invariants_.poolInvariantD = flag ? false : true;
        invariants_.poolInvariantE = flag ? false : true;
        invariants_.poolInvariantG = flag ? false : true;
        invariants_.poolInvariantI = flag ? false : true;
        invariants_.poolInvariantJ = flag ? false : true;
        invariants_.poolInvariantK = flag ? false : true;

        invariants_.poolManagerInvariantA = flag ? false : true;
        invariants_.poolManagerInvariantB = flag ? false : true;

        invariants_.withdrawalManagerInvariantA = flag ? false : true;
        invariants_.withdrawalManagerInvariantC = flag ? false : true;
        invariants_.withdrawalManagerInvariantD = flag ? false : true;
        invariants_.withdrawalManagerInvariantE = flag ? false : true;
        invariants_.withdrawalManagerInvariantM = flag ? false : true;
        invariants_.withdrawalManagerInvariantN = flag ? false : true;
        invariants_.withdrawalManagerInvariantF = flag ? false : true;
        invariants_.withdrawalManagerInvariantG = flag ? false : true;
        invariants_.withdrawalManagerInvariantH = flag ? false : true;
        invariants_.withdrawalManagerInvariantI = flag ? false : true;
        invariants_.withdrawalManagerInvariantJ = flag ? false : true;
        invariants_.withdrawalManagerInvariantK = flag ? false : true;

    }

    function setFlag() external {
        flag = !flag;
    }

}