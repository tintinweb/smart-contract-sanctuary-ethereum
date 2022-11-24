/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract TestIBIterestRateCalcs {

    uint256 public currentCash = 42892126521524751849599467;            // 42,892,126
    uint256 public currentBorrows = 5162882223197803500274313;          // 5,162,882
    uint256 public currentReserves = 12630104189193005337526;           // 12,630
    uint256 public currentReserveFactorMantissa = 100000000000000000;   // 0.10
    uint256 public baseRatePerBlock = 0;
    uint256 public multiplierPerBlock = 190258751902;

    event LogNum(
        string name,
        uint256 val
    );

    function utilizationRate() public view returns (uint256) {
        uint256 util = currentBorrows * 1e18 / (currentCash + currentBorrows - currentReserves);
        return util;                                                    // 107465166573619212 = .107
    }

    function getBorrowRate() public view returns (uint256) {
        uint256 util = utilizationRate();
        return util * multiplierPerBlock / 1e18 + baseRatePerBlock;     // 20446188465
    }
    
    function getSupplyRate() public returns (uint256) {
        uint256 oneMinusReserveFactor =
            uint256(1e18) - currentReserveFactorMantissa;               // 900000000000000000 = 0.9
        emit LogNum("oneMinusReserveFactor", oneMinusReserveFactor);
        
        uint256 borrowRate = getBorrowRate();                           // 20446188465
        emit LogNum("borrowRate", borrowRate);
        
        uint256 rateToPool = borrowRate * oneMinusReserveFactor / 1e18; // 18401569618
        emit LogNum("rateToPool", rateToPool);
        
        uint256 supplyRate = utilizationRate() * rateToPool / 1e18;     // 1977527744
        emit LogNum("supplyRate", supplyRate);

        return supplyRate;                                              // 1977527744
    }
}