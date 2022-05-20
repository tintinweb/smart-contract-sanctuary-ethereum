// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./libraries/Decimal.sol";
import "./interfaces/IInterestRateModel.sol";

/// @notice This contract represent interest rate calculation model for a pool
contract InterestRateModel is IInterestRateModel {
    using Decimal for uint256;

    /// @notice Base interest rate (as 18-digit decimal)
    uint256 public immutable baseRate;

    /// @notice Interest rate multiplier (as 18-digit decimal)
    uint256 public immutable multiplier;

    /// @notice Interest rate jump multiplier (as 18-digit decimal)
    uint256 public immutable jumpMultiplier;

    /// @notice Utilization above which jump multiplier is applied
    uint256 public immutable kink;

    /// @notice Contract's constructor
    /// @param baseRate_ Base rate value
    /// @param multiplier_ Multiplier value
    /// @param jumpMultiplier_ Jump multiplier value
    /// @param kink_ Kink value
    constructor(
        uint256 baseRate_,
        uint256 multiplier_,
        uint256 jumpMultiplier_,
        uint256 kink_
    ) {
        baseRate = baseRate_;
        multiplier = multiplier_;
        jumpMultiplier = jumpMultiplier_;
        kink = kink_;
    }

    /// @notice Function that calculates utilization rate for pool
    /// @param balance Total pool balance
    /// @param borrows Total pool borrows
    /// @param reserves Sum of pool reserves and insurance
    /// @return Utilization rate
    function utilizationRate(
        uint256 balance,
        uint256 borrows,
        uint256 reserves
    ) public pure returns (uint256) {
        if (borrows == 0) {
            return 0;
        }
        return borrows.divDecimal(balance + borrows - reserves);
    }

    /// @notice Function that calculates borrow interest rate for pool
    /// @param balance Total pool balance
    /// @param borrows Total pool borrows
    /// @param reserves Sum of pool reserves and insurance
    /// @return Borrow rate per second
    function getBorrowRate(
        uint256 balance,
        uint256 borrows,
        uint256 reserves
    ) public view returns (uint256) {
        if (borrows == 0) {
            return 0;
        }

        uint256 util = utilizationRate(balance, borrows, reserves);
        if (util <= kink) {
            return baseRate + multiplier.mulDecimal(util);
        } else {
            return
                baseRate +
                multiplier.mulDecimal(kink) +
                jumpMultiplier.mulDecimal(util - kink);
        }
    }

    /// @notice Function that calculates supply interest rate for pool
    /// @param balance Total pool balance
    /// @param borrows Total pool borrows
    /// @param reserves Sum of pool reserves and insurance
    /// @param reserveFactor Pool reserve factor
    /// @return Supply rate per second
    function getSupplyRate(
        uint256 balance,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactor
    ) external view returns (uint256) {
        uint256 util = utilizationRate(balance, borrows, reserves);

        return
            util
                .mulDecimal(getBorrowRate(balance, borrows, reserves))
                .mulDecimal(Decimal.ONE - reserveFactor);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Decimal {
    /// @notice Number one as 18-digit decimal
    uint256 internal constant ONE = 1e18;

    /**
     * @notice Internal function for 10-digits decimal division
     * @param number Integer number
     * @param decimal Decimal number
     * @return Returns multiplied numbers
     */
    function mulDecimal(uint256 number, uint256 decimal)
        internal
        pure
        returns (uint256)
    {
        return (number * decimal) / ONE;
    }

    /**
     * @notice Internal function for 10-digits decimal multiplication
     * @param number Integer number
     * @param decimal Decimal number
     * @return Returns integer number divided by second
     */
    function divDecimal(uint256 number, uint256 decimal)
        internal
        pure
        returns (uint256)
    {
        return (number * ONE) / decimal;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IInterestRateModel {
    function getBorrowRate(
        uint256 balance,
        uint256 totalBorrows,
        uint256 totalReserves
    ) external view returns (uint256);

    function utilizationRate(
        uint256 balance,
        uint256 borrows,
        uint256 reserves
    ) external pure returns (uint256);

    function getSupplyRate(
        uint256 balance,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactor
    ) external view returns (uint256);
}