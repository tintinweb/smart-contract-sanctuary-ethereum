// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./BaseJumpRateModelV2.sol";
import "./LegacyInterestRateModel.sol";
contract LegacyJumpRateModelV2 is LegacyInterestRateModel, BaseJumpRateModelV2  {    
    constructor(uint baseRatePerYear, uint multiplierPerYear, uint jumpMultiplierPerYear, uint kink_, address owner_) 
    	BaseJumpRateModelV2(baseRatePerYear,multiplierPerYear,jumpMultiplierPerYear,kink_,owner_) public {}
    function getBorrowRate(uint cash, uint borrows, uint reserves) external override view returns (uint, uint) {
        return (0,getBorrowRateInternal(cash, borrows, reserves));
    }
}