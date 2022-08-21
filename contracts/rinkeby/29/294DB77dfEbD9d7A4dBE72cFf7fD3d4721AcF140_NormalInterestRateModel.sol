// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IInterestRateModel.sol";

contract NormalInterestRateModel is IInterestRateModel {
    bool public constant IS_INTEREST_RATE_MODEL = true;

    uint256 private constant BASE = 1e18;

    /**
     * @notice The approximate number of blocks per year that is assumed by the interest rate model
     */
    uint256 public constant blocksPerYear = 2102400;

    /**
     * @notice The multiplier of utilization rate that gives the slope of the interest rate
     */
    uint256 public multiplierPerBlock;

    /**
     * @notice The base interest rate which is the y-intercept when utilization rate is 0
     */
    uint256 public baseRatePerBlock;

    event NewInterestParams(
        uint256 baseRatePerBlock,
        uint256 multiplierPerBlock
    );

    /**
     * @notice Construct an interest rate model
     * @param _baseRatePerYear The approximate target base APR, as a mantissa (scaled by BASE)
     * @param _multiplierPerYear The rate of increase in interest rate wrt utilization (scaled by BASE)
     */
    constructor(uint256 _baseRatePerYear, uint256 _multiplierPerYear) {
        baseRatePerBlock = _baseRatePerYear / blocksPerYear;
        multiplierPerBlock = _multiplierPerYear / blocksPerYear;

        emit NewInterestParams(baseRatePerBlock, multiplierPerBlock);
    }

    function isInterestRateModel() public pure returns (bool) {
        return IS_INTEREST_RATE_MODEL;
    }

    /**
     * @notice Calculates the utilization rate of the market: `borrows / (cash + borrows - reserves)`
     * @param _cash The amount of cash in the market
     * @param _borrows The amount of borrows in the market
     * @param _reserves The amount of reserves in the market (currently unused)
     * @return The utilization rate as a mantissa between [0, BASE]
     */
    function utilizationRate(
        uint256 _cash,
        uint256 _borrows,
        uint256 _reserves
    ) public pure returns (uint256) {
        // Utilization rate is 0 when there are no borrows
        if (_borrows == 0) {
            return 0;
        }

        return (_borrows * BASE) / (_cash + _borrows - _reserves);
    }

    /**
     * @notice Calculates the current borrow rate per block, with the error code expected by the market
     * @param _cash The amount of cash in the market
     * @param _borrows The amount of borrows in the market
     * @param _reserves The amount of reserves in the market
     * @return The borrow rate percentage per block as a mantissa (scaled by BASE)
     */
    function getBorrowRate(
        uint256 _cash,
        uint256 _borrows,
        uint256 _reserves
    ) public view override returns (uint256) {
        uint256 ur = utilizationRate(_cash, _borrows, _reserves);
        return ((ur * multiplierPerBlock) / BASE) + baseRatePerBlock;
    }

    /**
     * @notice Calculates the current supply rate per block
     * @param _cash The amount of cash in the market
     * @param _borrows The amount of borrows in the market
     * @param _reserves The amount of reserves in the market
     * @param _reserveFactorMantissa The current reserve factor for the market
     * @return The supply rate percentage per block as a mantissa (scaled by BASE)
     */
    function getSupplyRate(
        uint256 _cash,
        uint256 _borrows,
        uint256 _reserves,
        uint256 _reserveFactorMantissa
    ) public view override returns (uint256) {
        uint256 oneMinusReserveFactor = BASE - _reserveFactorMantissa;
        uint256 borrowRate = getBorrowRate(_cash, _borrows, _reserves);
        uint256 rateToPool = (borrowRate * oneMinusReserveFactor) / BASE;
        return
            (utilizationRate(_cash, _borrows, _reserves) * rateToPool) / BASE;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IInterestRateModel {
    function isInterestRateModel() external view returns (bool);

    /**
     * @notice Calculates the current borrow interest rate per block
     * @param _cash The total amount of cash the market has
     * @param _borrows The total amount of borrows the market has outstanding
     * @param _reserves The total amount of reserves the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 _cash,
        uint256 _borrows,
        uint256 _reserves
    ) external view returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param _cash The total amount of cash the market has
     * @param _borrows The total amount of borrows the market has outstanding
     * @param _reserves The total amount of reserves the market has
     * @param _reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 _cash,
        uint256 _borrows,
        uint256 _reserves,
        uint256 _reserveFactorMantissa
    ) external view returns (uint256);
}