// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./InterestRateModel.sol";
import "./SafeMath.sol";
contract JumpRateModel is InterestRateModel {
    using SafeMath for uint;
    event NewInterestParams(uint baseRatePerBlock, uint multiplierPerBlock, uint jumpMultiplierPerBlock, uint kink); 
    // @notice The approximate number of blocks per year that is assumed by the interest rate model
    uint public constant blocksPerYear = 2102400;
    // @notice The multiplier of utilization rate that gives the slope of the interest rate
    uint public multiplierPerBlock;
    // @notice The base interest rate which is the y-intercept when utilization rate is 0  
    uint public baseRatePerBlock;
    // @notice The multiplierPerBlock after hitting a specified utilization point
    uint public jumpMultiplierPerBlock; 
    // @notice The utilization point at which the jump multiplier is applied
    uint public kink;
    constructor(uint baseRatePerYear, uint multiplierPerYear, uint jumpMultiplierPerYear, uint kink_) public {
        baseRatePerBlock = baseRatePerYear.div(blocksPerYear);
        multiplierPerBlock = multiplierPerYear.div(blocksPerYear);
        jumpMultiplierPerBlock = jumpMultiplierPerYear.div(blocksPerYear);
        kink = kink_;
        emit NewInterestParams(baseRatePerBlock, multiplierPerBlock, jumpMultiplierPerBlock, kink);
    }      
    function utilizationRate(uint cash, uint borrows, uint reserves) public pure returns (uint) {
        // Utilization rate is 0 when there are no borrows
        if (borrows == 0) {
            return 0;
        }
        return borrows.mul(1e18).div(cash.add(borrows).sub(reserves));
    }      
    function getBorrowRate(uint cash, uint borrows, uint reserves) public view override returns (uint) {
        uint util = utilizationRate(cash, borrows, reserves);
        if (util <= kink) {
            return util.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
        } else {
            uint normalRate = kink.mul(multiplierPerBlock).div(1e18).add(baseRatePerBlock);
            uint excessUtil = util.sub(kink);
            return excessUtil.mul(jumpMultiplierPerBlock).div(1e18).add(normalRate);
        }
    } 
    function getSupplyRate(uint cash, uint borrows, uint reserves, uint reserveFactorMantissa) public override view returns (uint) {
        uint oneMinusReserveFactor = uint(1e18).sub(reserveFactorMantissa);
        uint borrowRate = getBorrowRate(cash, borrows, reserves);
        uint rateToPool = borrowRate.mul(oneMinusReserveFactor).div(1e18);
        return utilizationRate(cash, borrows, reserves).mul(rateToPool).div(1e18);
    }
}