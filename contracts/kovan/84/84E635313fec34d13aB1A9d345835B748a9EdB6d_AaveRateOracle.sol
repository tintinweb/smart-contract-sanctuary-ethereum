// SPDX-License-Identifier: agpl-3.0
pragma solidity =0.8.9;

library AaveDataTypes {
    // refer to the Aave v2 whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity =0.8.9;
import "../interfaces/aave/IAaveV2LendingPool.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";
import "../aave/AaveDataTypes.sol";
import "../interfaces/aave/IAToken.sol";
import "../utils/Printer.sol";

/// @notice This Mock Aave pool can be used in 3 ways
/// - change the rate to a fixed value (`setReserveNormalizedIncome`)
/// - configure the rate to alter over time (`setFactorPerSecondInRay`) for more dynamic testing
contract MockAaveLendingPool is IAaveV2LendingPool {
    mapping(IERC20Minimal => uint256) internal reserveNormalizedIncome;
    mapping(IERC20Minimal => uint256) internal startTime;
    mapping(IERC20Minimal => uint256) internal factorPerSecondInRay; // E.g. 1000000001000000000000000000 for 0.0000001% per second = ~3.2% APY

    mapping(IERC20Minimal => AaveDataTypes.ReserveData) internal _reserves;

    function getReserveNormalizedIncome(IERC20Minimal _underlyingAsset)
        public
        view
        override
        returns (uint256)
    {
        uint256 factorPerSecond = factorPerSecondInRay[_underlyingAsset];
        if (factorPerSecond > 0) {
            uint256 secondsSinceNormalizedIncomeSet = block.timestamp -
                startTime[_underlyingAsset];
            return
                PRBMathUD60x18.mul(
                    reserveNormalizedIncome[_underlyingAsset],
                    PRBMathUD60x18.pow(
                        factorPerSecond,
                        secondsSinceNormalizedIncomeSet
                    )
                );
        } else {
            return reserveNormalizedIncome[_underlyingAsset];
        }
    }

    function setReserveNormalizedIncome(
        IERC20Minimal _underlyingAsset,
        uint256 _reserveNormalizedIncome
    ) public {
        reserveNormalizedIncome[_underlyingAsset] = _reserveNormalizedIncome;
        startTime[_underlyingAsset] = block.timestamp;
    }

    function setFactorPerSecondInRay(
        IERC20Minimal _underlyingAsset,
        uint256 _factorPerSecondInRay
    ) public {
        factorPerSecondInRay[_underlyingAsset] = _factorPerSecondInRay;
    }

    function initReserve(IERC20Minimal asset, address aTokenAddress) external {
        AaveDataTypes.ReserveData memory reserveData;
        reserveData.aTokenAddress = aTokenAddress;

        _reserves[asset] = reserveData;
    }

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(IERC20Minimal asset)
        external
        view
        override
        returns (AaveDataTypes.ReserveData memory)
    {
        return _reserves[asset];
    }

    function withdraw(
        IERC20Minimal asset,
        uint256 amount,
        address to
    ) external override returns (uint256) {
        AaveDataTypes.ReserveData storage reserve = _reserves[asset];
        address aToken = reserve.aTokenAddress;

        uint256 userBalance = IERC20Minimal(aToken).balanceOf(msg.sender);

        uint256 amountToWithdraw = amount;

        if (amount == type(uint256).max) {
            amountToWithdraw = userBalance;
        }

        //  ValidationLogic.validateWithdraw(
        //   asset,
        //   amountToWithdraw,
        //   userBalance,
        //   _reserves,
        //   _usersConfig[msg.sender],
        //   _reservesList,
        //   _reservesCount,
        //   _addressesProvider.getPriceOracle()
        // );

        // reserve.updateState();
        // reserve.updateInterestRates(asset, aToken, 0, amountToWithdraw);

        // if (amountToWithdraw == userBalance) {
        //   _usersConfig[msg.sender].setUsingAsCollateral(reserve.id, false);
        //   emit ReserveUsedAsCollateralDisabled(asset, msg.sender);
        // }

        // AB: replaced reserve.liquidityIndex with getReserveNormalizedIncome()
        IAToken(aToken).burn(
            msg.sender,
            to,
            amountToWithdraw,
            getReserveNormalizedIncome(asset)
        );

        return amountToWithdraw;
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity =0.8.9;
pragma abicoder v2;
import "../../aave/AaveDataTypes.sol";
import "../IERC20Minimal.sol";

interface IAaveV2LendingPool {

    /**
    * @dev Returns the normalized income normalized income of the reserve
    * @dev A return value of 1e27 indicates no income. As time passes, the income is accrued. A value of 2e27 indicates that for each unit of asset, two units of income have been accrued.
    * @param underlyingAsset The address of the underlying asset of the reserve
    * @return The reserve's normalized income
    */
    function getReserveNormalizedIncome(IERC20Minimal underlyingAsset) external view returns (uint256);


    /**
    * @dev Returns the state and configuration of the reserve
    * @param asset The address of the underlying asset of the reserve
    * @return The state of the reserve
    **/
    function getReserveData(IERC20Minimal asset) external view returns (AaveDataTypes.ReserveData memory);

    /**
    * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
    * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
    * @param asset The address of the underlying asset to withdraw
    * @param amount The underlying amount to be withdrawn
    *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
    * @param to Address that will receive the underlying, same as msg.sender if the user
    *   wants to receive it on his own wallet, or a different address if the beneficiary is a
    *   different wallet
    * @return The final amount withdrawn
    **/
    function withdraw(
        IERC20Minimal asset,
        uint256 amount,
        address to
    ) external returns (uint256);


}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.4;

import "./PRBMath.sol";

/// @title PRBMathUD60x18
/// @author Paul Razvan Berg
/// @notice Smart contract library for advanced fixed-point math that works with uint256 numbers considered to have 18
/// trailing decimals. We call this number representation unsigned 60.18-decimal fixed-point, since there can be up to 60
/// digits in the integer part and up to 18 decimals in the fractional part. The numbers are bound by the minimum and the
/// maximum values permitted by the Solidity type uint256.
library PRBMathUD60x18 {
    /// @dev Half the SCALE number.
    uint256 internal constant HALF_SCALE = 5e17;

    /// @dev log2(e) as an unsigned 60.18-decimal fixed-point number.
    uint256 internal constant LOG2_E = 1_442695040888963407;

    /// @dev The maximum value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_584007913129639935;

    /// @dev The maximum whole value an unsigned 60.18-decimal fixed-point number can have.
    uint256 internal constant MAX_WHOLE_UD60x18 =
        115792089237316195423570985008687907853269984665640564039457_000000000000000000;

    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates the arithmetic average of x and y, rounding down.
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The arithmetic average as an unsigned 60.18-decimal fixed-point number.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // The operations can never overflow.
        unchecked {
            // The last operand checks if both x and y are odd and if that is the case, we add 1 to the result. We need
            // to do this because if both numbers are odd, the 0.5 remainder gets truncated twice.
            result = (x >> 1) + (y >> 1) + (x & y & 1);
        }
    }

    /// @notice Yields the least unsigned 60.18 decimal fixed-point number greater than or equal to x.
    ///
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    ///
    /// Requirements:
    /// - x must be less than or equal to MAX_WHOLE_UD60x18.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number to ceil.
    /// @param result The least integer greater than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function ceil(uint256 x) internal pure returns (uint256 result) {
        if (x > MAX_WHOLE_UD60x18) {
            revert PRBMathUD60x18__CeilOverflow(x);
        }
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "SCALE - remainder" but faster.
            let delta := sub(SCALE, remainder)

            // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
            result := add(x, mul(delta, gt(remainder, 0)))
        }
    }

    /// @notice Divides two unsigned 60.18-decimal fixed-point numbers, returning a new unsigned 60.18-decimal fixed-point number.
    ///
    /// @dev Uses mulDiv to enable overflow-safe multiplication and division.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    ///
    /// @param x The numerator as an unsigned 60.18-decimal fixed-point number.
    /// @param y The denominator as an unsigned 60.18-decimal fixed-point number.
    /// @param result The quotient as an unsigned 60.18-decimal fixed-point number.
    function div(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDiv(x, SCALE, y);
    }

    /// @notice Returns Euler's number as an unsigned 60.18-decimal fixed-point number.
    /// @dev See https://en.wikipedia.org/wiki/E_(mathematical_constant).
    function e() internal pure returns (uint256 result) {
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
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp(uint256 x) internal pure returns (uint256 result) {
        // Without this check, the value passed to "exp2" would be greater than 192.
        if (x >= 133_084258667509499441) {
            revert PRBMathUD60x18__ExpInputTooBig(x);
        }

        // Do the fixed-point multiplication inline to save gas.
        unchecked {
            uint256 doubleScaleProduct = x * LOG2_E;
            result = exp2((doubleScaleProduct + HALF_SCALE) / SCALE);
        }
    }

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    ///
    /// @dev See https://ethereum.stackexchange.com/q/79903/24693.
    ///
    /// Requirements:
    /// - x must be 192 or less.
    /// - The result must fit within MAX_UD60x18.
    ///
    /// @param x The exponent as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (x >= 192e18) {
            revert PRBMathUD60x18__Exp2InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x192x64 = (x << 64) / SCALE;

            // Pass x to the PRBMath.exp2 function, which uses the 192.64-bit fixed-point number representation.
            result = PRBMath.exp2(x192x64);
        }
    }

    /// @notice Yields the greatest unsigned 60.18 decimal fixed-point number less than or equal to x.
    /// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
    /// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
    /// @param x The unsigned 60.18-decimal fixed-point number to floor.
    /// @param result The greatest integer less than or equal to x, as an unsigned 60.18-decimal fixed-point number.
    function floor(uint256 x) internal pure returns (uint256 result) {
        assembly {
            // Equivalent to "x % SCALE" but faster.
            let remainder := mod(x, SCALE)

            // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
            result := sub(x, mul(remainder, gt(remainder, 0)))
        }
    }

    /// @notice Yields the excess beyond the floor of x.
    /// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
    /// @param x The unsigned 60.18-decimal fixed-point number to get the fractional part of.
    /// @param result The fractional part of x as an unsigned 60.18-decimal fixed-point number.
    function frac(uint256 x) internal pure returns (uint256 result) {
        assembly {
            result := mod(x, SCALE)
        }
    }

    /// @notice Converts a number from basic integer form to unsigned 60.18-decimal fixed-point representation.
    ///
    /// @dev Requirements:
    /// - x must be less than or equal to MAX_UD60x18 divided by SCALE.
    ///
    /// @param x The basic integer to convert.
    /// @param result The same number in unsigned 60.18-decimal fixed-point representation.
    function fromUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__FromUintOverflow(x);
            }
            result = x * SCALE;
        }
    }

    /// @notice Calculates geometric mean of x and y, i.e. sqrt(x * y), rounding down.
    ///
    /// @dev Requirements:
    /// - x * y must fit within MAX_UD60x18, lest it overflows.
    ///
    /// @param x The first operand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The second operand as an unsigned 60.18-decimal fixed-point number.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function gm(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        unchecked {
            // Checking for overflow this way is faster than letting Solidity do it.
            uint256 xy = x * y;
            if (xy / x != y) {
                revert PRBMathUD60x18__GmOverflow(x, y);
            }

            // We don't need to multiply by the SCALE here because the x*y product had already picked up a factor of SCALE
            // during multiplication. See the comments within the "sqrt" function.
            result = PRBMath.sqrt(xy);
        }
    }

    /// @notice Calculates 1 / x, rounding toward zero.
    ///
    /// @dev Requirements:
    /// - x cannot be zero.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the inverse.
    /// @return result The inverse as an unsigned 60.18-decimal fixed-point number.
    function inv(uint256 x) internal pure returns (uint256 result) {
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
    /// - This doesn't return exactly 1 for 2.718281828459045235, for that we would need more fine-grained precision.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the natural logarithm.
    /// @return result The natural logarithm as an unsigned 60.18-decimal fixed-point number.
    function ln(uint256 x) internal pure returns (uint256 result) {
        // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
        // can return is 196205294292027477728.
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
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the common logarithm.
    /// @return result The common logarithm as an unsigned 60.18-decimal fixed-point number.
    function log10(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }

        // Note that the "mul" in this block is the assembly multiplication operation, not the "mul" function defined
        // in this contract.
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
            case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(SCALE, 59) }
            default {
                result := MAX_UD60x18
            }
        }

        if (result == MAX_UD60x18) {
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
    /// - x must be greater than or equal to SCALE, otherwise the result would be negative.
    ///
    /// Caveats:
    /// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the binary logarithm.
    /// @return result The binary logarithm as an unsigned 60.18-decimal fixed-point number.
    function log2(uint256 x) internal pure returns (uint256 result) {
        if (x < SCALE) {
            revert PRBMathUD60x18__LogInputTooSmall(x);
        }
        unchecked {
            // Calculate the integer part of the logarithm and add it to the result and finally calculate y = x * 2^(-n).
            uint256 n = PRBMath.mostSignificantBit(x / SCALE);

            // The integer part of the logarithm as an unsigned 60.18-decimal fixed-point number. The operation can't overflow
            // because n is maximum 255 and SCALE is 1e18.
            result = n * SCALE;

            // This is y = x * 2^(-n).
            uint256 y = x >> n;

            // If y = 1, the fractional part is zero.
            if (y == SCALE) {
                return result;
            }

            // Calculate the fractional part via the iterative approximation.
            // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
            for (uint256 delta = HALF_SCALE; delta > 0; delta >>= 1) {
                y = (y * y) / SCALE;

                // Is y^2 > 2 and so in the range [2,4)?
                if (y >= 2 * SCALE) {
                    // Add the 2^(-m) factor to the logarithm.
                    result += delta;

                    // Corresponds to z/2 on Wikipedia.
                    y >>= 1;
                }
            }
        }
    }

    /// @notice Multiplies two unsigned 60.18-decimal fixed-point numbers together, returning a new unsigned 60.18-decimal
    /// fixed-point number.
    /// @dev See the documentation for the "PRBMath.mulDivFixedPoint" function.
    /// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
    /// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
    /// @return result The product as an unsigned 60.18-decimal fixed-point number.
    function mul(uint256 x, uint256 y) internal pure returns (uint256 result) {
        result = PRBMath.mulDivFixedPoint(x, y);
    }

    /// @notice Returns PI as an unsigned 60.18-decimal fixed-point number.
    function pi() internal pure returns (uint256 result) {
        result = 3_141592653589793238;
    }

    /// @notice Raises x to the power of y.
    ///
    /// @dev Based on the insight that x^y = 2^(log2(x) * y).
    ///
    /// Requirements:
    /// - All from "exp2", "log2" and "mul".
    ///
    /// Caveats:
    /// - All from "exp2", "log2" and "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x Number to raise to given power y, as an unsigned 60.18-decimal fixed-point number.
    /// @param y Exponent to raise x to, as an unsigned 60.18-decimal fixed-point number.
    /// @return result x raised to power y, as an unsigned 60.18-decimal fixed-point number.
    function pow(uint256 x, uint256 y) internal pure returns (uint256 result) {
        if (x == 0) {
            result = y == 0 ? SCALE : uint256(0);
        } else {
            result = exp2(mul(log2(x), y));
        }
    }

    /// @notice Raises x (unsigned 60.18-decimal fixed-point number) to the power of y (basic unsigned integer) using the
    /// famous algorithm "exponentiation by squaring".
    ///
    /// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
    ///
    /// Requirements:
    /// - The result must fit within MAX_UD60x18.
    ///
    /// Caveats:
    /// - All from "mul".
    /// - Assumes 0^0 is 1.
    ///
    /// @param x The base as an unsigned 60.18-decimal fixed-point number.
    /// @param y The exponent as an uint256.
    /// @return result The result as an unsigned 60.18-decimal fixed-point number.
    function powu(uint256 x, uint256 y) internal pure returns (uint256 result) {
        // Calculate the first iteration of the loop in advance.
        result = y & 1 > 0 ? x : SCALE;

        // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
        for (y >>= 1; y > 0; y >>= 1) {
            x = PRBMath.mulDivFixedPoint(x, x);

            // Equivalent to "y % 2 == 1" but faster.
            if (y & 1 > 0) {
                result = PRBMath.mulDivFixedPoint(result, x);
            }
        }
    }

    /// @notice Returns 1 as an unsigned 60.18-decimal fixed-point number.
    function scale() internal pure returns (uint256 result) {
        result = SCALE;
    }

    /// @notice Calculates the square root of x, rounding down.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    ///
    /// Requirements:
    /// - x must be less than MAX_UD60x18 / SCALE.
    ///
    /// @param x The unsigned 60.18-decimal fixed-point number for which to calculate the square root.
    /// @return result The result as an unsigned 60.18-decimal fixed-point .
    function sqrt(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            if (x > MAX_UD60x18 / SCALE) {
                revert PRBMathUD60x18__SqrtOverflow(x);
            }
            // Multiply x by the SCALE to account for the factor of SCALE that is picked up when multiplying two unsigned
            // 60.18-decimal fixed-point numbers together (in this case, those two numbers are both the square root).
            result = PRBMath.sqrt(x * SCALE);
        }
    }

    /// @notice Converts a unsigned 60.18-decimal fixed-point number to basic integer form, rounding down in the process.
    /// @param x The unsigned 60.18-decimal fixed-point number to convert.
    /// @return result The same number in basic integer form.
    function toUint(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            result = x / SCALE;
        }
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity =0.8.9;
import "../IERC20Minimal.sol";


interface IAToken {

  /**
   * @dev Mints `amount` aTokens to `user`
   * @param user The address receiving the minted tokens
   * @param amount The amount of tokens getting minted
   * @param index The new liquidity index of the reserve
   * @return `true` if the the previous balance of the user was 0
   */
  function mint(
    address user,
    uint256 amount,
    uint256 index
  ) external returns (bool);

    /**
   * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
   * @param user The owner of the aTokens, getting them burned
   * @param receiverOfUnderlying The address that will receive the underlying
   * @param amount The amount being burned
   * @param index The new liquidity index of the reserve
   **/
  function burn(
    address user,
    address receiverOfUnderlying,
    uint256 amount,
    uint256 index
  ) external;

  /**
  * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
  * updated stored balance divided by the reserve's liquidity index at the moment of the update
  * @param user The user whose balance is calculated
  * @return The scaled balance of the user
  **/
  function scaledBalanceOf(address user) external view returns (uint256);

    /**
   * @dev Returns the scaled balance of the user and the scaled total supply.
   * @param user The address of the user
   * @return The scaled balance of the user
   * @return The scaled balance and the scaled total supply
   **/
  function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

  /**
   * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
   * @return The scaled total supply
   **/
  function scaledTotalSupply() external view returns (uint256);

  /**
  * @dev Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
  **/
  function UNDERLYING_ASSET_ADDRESS() external view returns (IERC20Minimal);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;

import "hardhat/console.sol";

/// @title Wrapper around hardhat/console.sol
library Printer {
    bool public constant PRINT = true;

    function printInt256(string memory reason, int256 number) internal view {
        if (!PRINT) return;

        if (number < 0) {
            console.log(reason, ": (-", uint256(-number), ") [FROM CONTRACT] ");
        } else {
            console.log(reason, ":", uint256(number), " [FROM CONTRACT] ");
        }
    }

    function printInt128(string memory reason, int128 number) internal view {
        if (!PRINT) return;

        if (number < 0) {
            console.log(reason, ": (-", uint128(-number), ") [FROM CONTRACT] ");
        } else {
            console.log(reason, ":", uint128(number), " [FROM CONTRACT] ");
        }
    }

    function printInt24(string memory reason, int24 number) internal view {
        if (!PRINT) return;

        if (number < 0) {
            console.log(reason, ": (-", uint24(-number), ") [FROM CONTRACT] ");
        } else {
            console.log(reason, ":", uint24(number), " [FROM CONTRACT] ");
        }
    }

    function printUint24(string memory reason, uint24 number) internal view {
        if (!PRINT) return;
        console.log(reason, ":", number, " [FROM CONTRACT] ");
    }

    function printUint32(string memory reason, uint32 number) internal view {
        if (!PRINT) return;
        console.log(reason, ":", number, " [FROM CONTRACT] ");
    }

    function printUint256(string memory reason, uint256 number) internal view {
        if (!PRINT) return;
        console.log(reason, ":", number, " [FROM CONTRACT] ");
    }

    function printUint128(string memory reason, uint128 number) internal view {
        if (!PRINT) return;
        console.log(reason, ":", number, " [FROM CONTRACT] ");
    }

    function printUint160(string memory reason, uint160 number) internal view {
        if (!PRINT) return;
        console.log(reason, ":", number, " [FROM CONTRACT] ");
    }

    function printAddress(string memory reason, address _address)
        internal
        view
    {
        if (!PRINT) return;
        console.log(reason, ":", _address, " [FROM CONTRACT] ");
    }

    function printBool(string memory reason, bool number) internal view {
        if (!PRINT) return;
        console.log(reason, number, " [FROM CONTRACT] ");
    }

    function printEmptyLine() internal view {
        if (!PRINT) return;
        console.log("");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.9;

/// @title Minimal ERC20 interface for Voltz
/// @notice Contains a subset of the full ERC20 interface that is used in Voltz
interface IERC20Minimal {
    /// @notice Returns the balance of a token
    /// @param account The account for which to look up the number of tokens it has, i.e. its balance
    /// @return The number of tokens held by the account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers the amount of token from the `msg.sender` to the recipient
    /// @param recipient The account that will receive the amount transferred
    /// @param amount The number of tokens to send from the sender to the recipient
    /// @return Returns true for a successful transfer, false for an unsuccessful transfer
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /// @notice Returns the current allowance given to a spender by an owner
    /// @param owner The account of the token owner
    /// @param spender The account of the token spender
    /// @return The current allowance granted by `owner` to `spender`
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /// @notice Sets the allowance of a spender from the `msg.sender` to the value `amount`
    /// @param spender The account which will be allowed to spend a given amount of the owners tokens
    /// @param amount The amount of tokens allowed to be used by `spender`
    /// @return Returns true for a successful approval, false for unsuccessful
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Transfers `amount` tokens from `sender` to `recipient` up to the allowance given to the `msg.sender`
    /// @param sender The account from which the transfer will be initiated
    /// @param recipient The recipient of the transfer
    /// @param amount The amount of the transfer
    /// @return Returns true for a successful transfer, false for unsuccessful
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /// @dev Returns the number of decimals used to get its user representation.
    // For example, if decimals equals 2, a balance of 505 tokens should be displayed to a user as 5,05 (505 / 10 ** 2).
    // Tokens usually opt for a value of 18, imitating the relationship between Ether and Wei.
    function decimals() external view returns (uint8);

    /// @notice Event emitted when tokens are transferred from one address to another, either via `#transfer` or `#transferFrom`.
    /// @param from The account from which the tokens were sent, i.e. the balance decreased
    /// @param to The account to which the tokens were sent, i.e. the balance increased
    /// @param value The amount of tokens that were transferred
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @notice Event emitted when the approval amount for the spender of a given owner's tokens changes.
    /// @param owner The account that approved spending of its tokens
    /// @param spender The account for which the spending allowance was modified
    /// @param value The new allowance from the owner to the spender
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

        // Set the initial guess to the closest power of two that is higher than x.
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

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
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

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
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

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
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

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
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

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
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

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
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

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
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

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
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

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
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

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
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

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
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

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
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

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
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

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
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

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
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

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
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

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
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

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
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

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
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

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
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

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
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

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
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

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
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

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
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

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
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

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
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

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
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

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
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

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
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

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
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

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
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

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
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

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
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

pragma solidity ^0.8.0;

import "../interfaces/compound/ICToken.sol";
import "../utils/WadRayMath.sol";
import "../utils/Printer.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IERC20Minimal.sol";
import "../core_libraries/SafeTransferLib.sol";

contract MockCToken is ICToken, ERC20 {
    using WadRayMath for uint256;
    address internal _cToken;
    address internal _underlyingAsset;
    uint256 internal _rate;

    using SafeTransferLib for IERC20Minimal;

    function balanceOfUnderlying(address owner) external returns (uint256) {
        return (balanceOf(owner) * exchangeRateCurrent()) / 1e18;
    }

    constructor(
        address underlyingAsset,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        _underlyingAsset = underlyingAsset;
    }

    function setExchangeRate(uint256 rate) external {
        _rate = rate;
    }

    function exchangeRateCurrent() public override returns (uint256) {
        return _rate;
    }

    function exchangeRateStored() public view override returns (uint256) {
        return _rate;
    }

    function underlying() external view override returns (address) {
        return _underlyingAsset;
    }

    function redeemUnderlying(uint256 redeemAmount)
        external
        override
        returns (uint256)
    {
        uint256 yieldBearingAmount = redeemAmount.wadDiv(_rate);
        IERC20Minimal(address(_cToken)).safeTransferFrom(
            msg.sender,
            address(this),
            yieldBearingAmount
        );
        IERC20Minimal(address(_underlyingAsset)).safeTransfer(
            msg.sender,
            redeemAmount
        );
        return 0;
    }

    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/CErc20.sol#L42
    /**
     * @dev Mints `amount` cTokens to `user`
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(address user, uint256 amount) external returns (bool) {
        uint256 previousBalance = super.balanceOf(user);

        require(amount != 0, "CT_INVALID_MINT_AMOUNT");
        _mint(user, amount);

        emit Transfer(address(0), user, amount);

        return previousBalance == 0;
    }

    function approveInternal(
        address owner,
        address spender,
        uint256 value
    ) public {
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

// Subset of https://github.com/compound-finance/compound-protocol/blob/master/contracts/CTokenInterfaces.sol
interface ICToken {

    /**
     * @notice Calculates the exchange rate from the underlying to the CToken
     * @dev This function does not accrue interest before calculating the exchange rate
     * @return Calculated exchange rate, scaled by 1 * 10^(18 - 8 + Underlying Token Decimals)
     */
  function exchangeRateStored() external view returns (uint256);

    /**
     * @notice Accrue interest then return the up-to-date exchange rate
     * @return Calculated exchange rate, scaled by 1 * 10^(18 - 8 + Underlying Token Decimals)
     */
  function exchangeRateCurrent() external returns (uint256);

  function redeemUnderlying(uint redeemAmount) external returns (uint);

      /**
     * @notice Underlying asset for this CToken
     */
  function underlying() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0

// solhint-disable const-name-snakecase

pragma solidity =0.8.9;
import "./Errors.sol";

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant halfWAD = WAD / 2;

    uint256 internal constant RAY = 1e27;
    uint256 internal constant halfRAY = RAY / 2;

    uint256 internal constant WAD_RAY_RATIO = 1e9;

    uint256 internal constant halfRatio = WAD_RAY_RATIO / 2;

    /**
     * @return One ray, 1e27
     **/
    function ray() internal pure returns (uint256) {
        return RAY;
    }

    /**
     * @return One wad, 1e18
     **/

    function wad() internal pure returns (uint256) {
        return WAD;
    }

    /**
     * @return Half ray, 1e27/2
     **/
    function halfRay() internal pure returns (uint256) {
        return halfRAY;
    }

    /**
     * @return Half ray, 1e18/2
     **/
    function halfWad() internal pure returns (uint256) {
        return halfWAD;
    }

    /**
     * @dev Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a*b, in wad
     **/
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        return (a * b + halfWAD) / WAD;
    }

    /**
     * @dev Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a/b, in wad
     **/
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfB = b / 2;

        return (a * WAD + halfB) / b;
    }

    /**
     * @dev Multiplies two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        return (a * b + halfRAY) / RAY;
    }

    /**
     * @dev Divides two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfB = b / 2;

        return (a * RAY + halfB) / b;
    }

    /**
     * @dev Casts ray down to wad
     * @param a Ray
     * @return a casted to wad, rounded half up to the nearest wad
     **/
    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 result = a / WAD_RAY_RATIO;

        if (a % WAD_RAY_RATIO >= halfRatio) {
            result += 1;
        }

        return result;
    }

    /**
     * @dev Converts wad up to ray
     * @param a Wad
     * @return a converted in ray
     **/
    function wadToRay(uint256 a) internal pure returns (uint256) {
        uint256 result = a * WAD_RAY_RATIO;
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity =0.8.9;

import "../interfaces/IERC20Minimal.sol";

// FROM https://github.com/Rari-Capital/solmate
// AB: replaced all instances of ERC20 in the original implenentation in the repo above with IERC20Minimal
// CR: ideally should be used as an npm package
/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        IERC20Minimal token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(
                freeMemoryPointer,
                0x23b872dd00000000000000000000000000000000000000000000000000000000
            ) // Begin with the function selector.
            mstore(
                add(freeMemoryPointer, 4),
                and(from, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "from" argument.
            mstore(
                add(freeMemoryPointer, 36),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(
            didLastOptionalReturnCallSucceed(callStatus),
            "TRANSFER_FROM_FAILED"
        );
    }

    function safeTransfer(
        IERC20Minimal token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(
                freeMemoryPointer,
                0xa9059cbb00000000000000000000000000000000000000000000000000000000
            ) // Begin with the function selector.
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(
            didLastOptionalReturnCallSucceed(callStatus),
            "TRANSFER_FAILED"
        );
    }

    function safeApprove(
        IERC20Minimal token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(
                freeMemoryPointer,
                0x095ea7b300000000000000000000000000000000000000000000000000000000
            ) // Begin with the function selector.
            mstore(
                add(freeMemoryPointer, 4),
                and(to, 0xffffffffffffffffffffffffffffffffffffffff)
            ) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus)
        private
        pure
        returns (bool success)
    {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity =0.8.9;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (AToken, VariableDebtToken and StableDebtToken)
 *  - AT = AToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - LP = LendingPool
 *  - LPAPR = LendingPoolAddressesProviderRegistry
 *  - LPC = LendingPoolConfiguration
 *  - RL = ReserveLogic
 *  - LPCM = LendingPoolCollateralManager
 *  - P = Pausable
 */
library Errors {
    //common errors
    string public constant CALLER_NOT_POOL_ADMIN = "33"; // "The caller must be the pool admin"
    string public constant BORROW_ALLOWANCE_NOT_ENOUGH = "59"; // User borrows on behalf, but allowance are too small

    //contract specific errors
    string public constant VL_INVALID_AMOUNT = "1"; // "Amount must be greater than 0"
    string public constant VL_NO_ACTIVE_RESERVE = "2"; // "Action requires an active reserve"
    string public constant VL_RESERVE_FROZEN = "3"; // "Action cannot be performed because the reserve is frozen"
    string public constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = "4"; // "The current liquidity is not enough"
    string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "5"; // "User cannot withdraw more than the available balance"
    string public constant VL_TRANSFER_NOT_ALLOWED = "6"; // "Transfer cannot be allowed."
    string public constant VL_BORROWING_NOT_ENABLED = "7"; // "Borrowing is not enabled"
    string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = "8"; // "Invalid interest rate mode selected"
    string public constant VL_COLLATERAL_BALANCE_IS_0 = "9"; // "The collateral balance is 0"
    string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD =
        "10"; // "Health factor is lesser than the liquidation threshold"
    string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = "11"; // "There is not enough collateral to cover a new borrow"
    string public constant VL_STABLE_BORROWING_NOT_ENABLED = "12"; // stable borrowing not enabled
    string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = "13"; // collateral is (mostly) the same currency that is being borrowed
    string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = "14"; // "The requested amount is greater than the max loan size in stable rate mode
    string public constant VL_NO_DEBT_OF_SELECTED_TYPE = "15"; // "for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt"
    string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = "16"; // "To repay on behalf of an user an explicit amount to repay is needed"
    string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = "17"; // "User does not have a stable rate loan in progress on this reserve"
    string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = "18"; // "User does not have a variable rate loan in progress on this reserve"
    string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = "19"; // "The underlying balance needs to be greater than 0"
    string public constant VL_DEPOSIT_ALREADY_IN_USE = "20"; // "User deposit is already being used as collateral"
    string public constant LP_NOT_ENOUGH_STABLE_BORROW_BALANCE = "21"; // "User does not have any stable rate loan for this reserve"
    string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = "22"; // "Interest rate rebalance conditions were not met"
    string public constant LP_LIQUIDATION_CALL_FAILED = "23"; // "Liquidation call failed"
    string public constant LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW = "24"; // "There is not enough liquidity available to borrow"
    string public constant LP_REQUESTED_AMOUNT_TOO_SMALL = "25"; // "The requested amount is too small for a FlashLoan."
    string public constant LP_INCONSISTENT_PROTOCOL_ACTUAL_BALANCE = "26"; // "The actual balance of the protocol is inconsistent"
    string public constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = "27"; // "The caller of the function is not the lending pool configurator"
    string public constant LP_INCONSISTENT_FLASHLOAN_PARAMS = "28";
    string public constant CT_CALLER_MUST_BE_LENDING_POOL = "29"; // "The caller of this function must be a lending pool"
    string public constant CT_CANNOT_GIVE_ALLOWANCE_TO_HIMSELF = "30"; // "User cannot give allowance to himself"
    string public constant CT_TRANSFER_AMOUNT_NOT_GT_0 = "31"; // "Transferred amount needs to be greater than zero"
    string public constant RL_RESERVE_ALREADY_INITIALIZED = "32"; // "Reserve has already been initialized"
    string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = "34"; // "The liquidity of the reserve needs to be 0"
    string public constant LPC_INVALID_ATOKEN_POOL_ADDRESS = "35"; // "The liquidity of the reserve needs to be 0"
    string public constant LPC_INVALID_STABLE_DEBT_TOKEN_POOL_ADDRESS = "36"; // "The liquidity of the reserve needs to be 0"
    string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_POOL_ADDRESS = "37"; // "The liquidity of the reserve needs to be 0"
    string public constant LPC_INVALID_STABLE_DEBT_TOKEN_UNDERLYING_ADDRESS =
        "38"; // "The liquidity of the reserve needs to be 0"
    string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_UNDERLYING_ADDRESS =
        "39"; // "The liquidity of the reserve needs to be 0"
    string public constant LPC_INVALID_ADDRESSES_PROVIDER_ID = "40"; // "The liquidity of the reserve needs to be 0"
    string public constant LPC_INVALID_CONFIGURATION = "75"; // "Invalid risk parameters for the reserve"
    string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = "76"; // "The caller must be the emergency admin"
    string public constant LPAPR_PROVIDER_NOT_REGISTERED = "41"; // "Provider is not registered"
    string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "42"; // "Health factor is not below the threshold"
    string public constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = "43"; // "The collateral chosen cannot be liquidated"
    string public constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "44"; // "User did not borrow the specified currency"
    string public constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = "45"; // "There isn"t enough liquidity available to liquidate"
    string public constant LPCM_NO_ERRORS = "46"; // "No errors"
    string public constant LP_INVALID_FLASHLOAN_MODE = "47"; //Invalid flashloan mode selected
    string public constant MATH_MULTIPLICATION_OVERFLOW = "48";
    string public constant MATH_ADDITION_OVERFLOW = "49";
    string public constant MATH_DIVISION_BY_ZERO = "50";
    string public constant RL_LIQUIDITY_INDEX_OVERFLOW = "51"; //  Liquidity index overflows uint128
    string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = "52"; //  Variable borrow index overflows uint128
    string public constant RL_LIQUIDITY_RATE_OVERFLOW = "53"; //  Liquidity rate overflows uint128
    string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = "54"; //  Variable borrow rate overflows uint128
    string public constant RL_STABLE_BORROW_RATE_OVERFLOW = "55"; //  Stable borrow rate overflows uint128
    string public constant CT_INVALID_MINT_AMOUNT = "56"; //invalid amount to mint
    string public constant LP_FAILED_REPAY_WITH_COLLATERAL = "57";
    string public constant CT_INVALID_BURN_AMOUNT = "58"; //invalid amount to burn
    string public constant LP_FAILED_COLLATERAL_SWAP = "60";
    string public constant LP_INVALID_EQUAL_ASSETS_TO_SWAP = "61";
    string public constant LP_REENTRANCY_NOT_ALLOWED = "62";
    string public constant LP_CALLER_MUST_BE_AN_ATOKEN = "63";
    string public constant LP_IS_PAUSED = "64"; // "Pool is paused"
    string public constant LP_NO_MORE_RESERVES_ALLOWED = "65";
    string public constant LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN = "66";
    string public constant RC_INVALID_LTV = "67";
    string public constant RC_INVALID_LIQ_THRESHOLD = "68";
    string public constant RC_INVALID_LIQ_BONUS = "69";
    string public constant RC_INVALID_DECIMALS = "70";
    string public constant RC_INVALID_RESERVE_FACTOR = "71";
    string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = "72";
    string public constant VL_INCONSISTENT_FLASHLOAN_PARAMS = "73";
    string public constant LP_INCONSISTENT_PARAMS_LENGTH = "74";
    string public constant UL_INVALID_INDEX = "77";
    string public constant LP_NOT_CONTRACT = "78";
    string public constant SDT_STABLE_DEBT_OVERFLOW = "79";
    string public constant SDT_BURN_EXCEEDS_BALANCE = "80";

    enum CollateralManagerErrors {
        NO_ERROR,
        NO_COLLATERAL_AVAILABLE,
        COLLATERAL_CANNOT_BE_LIQUIDATED,
        CURRRENCY_NOT_BORROWED,
        HEALTH_FACTOR_ABOVE_THRESHOLD,
        NOT_ENOUGH_LIQUIDITY,
        NO_ACTIVE_RESERVE,
        HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD,
        INVALID_EQUAL_ASSETS_TO_SWAP,
        FROZEN_RESERVE
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

pragma abicoder v2;

import "../interfaces/IMarginEngine.sol";
import "../interfaces/IVAMM.sol";
import "../interfaces/IPeriphery.sol";
import "../utils/TickMath.sol";
import "./peripheral_libraries/LiquidityAmounts.sol";
import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../core_libraries/SafeTransferLib.sol";
import "../core_libraries/Tick.sol";
import "../core_libraries/FixedAndVariableMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract Periphery is IPeriphery {
    using SafeCast for uint256;
    using SafeCast for int256;

    using SafeTransferLib for IERC20Minimal;

    /// @dev Voltz Protocol marginEngine => LP Notional Cap in Underlying Tokens
    /// @dev LP notional cap of zero implies no notional cap
    /// @inheritdoc IPeriphery
    mapping(IMarginEngine => uint256) public override lpNotionalCaps;

    /// @dev amount of notional (coming from the periphery) in terms of underlying tokens taken up by LPs in a given MarginEngine
    /// @inheritdoc IPeriphery
    mapping(IMarginEngine => uint256) public override lpNotionalCumulatives;

    modifier marginEngineOwnerOnly(IMarginEngine _marginEngine) {
        require(address(_marginEngine) != address(0), "me addr zero");
        address marginEngineOwner = OwnableUpgradeable(address(_marginEngine))
            .owner();
        require(msg.sender == marginEngineOwner, "only me owner");
        _;
    }

    modifier checkLPNotionalCap(
        IMarginEngine _marginEngine,
        uint256 _notionalDelta,
        bool _isMint
    ) {
        uint256 _lpNotionalCap = lpNotionalCaps[_marginEngine];

        if (_isMint) {
            lpNotionalCumulatives[_marginEngine] += _notionalDelta;

            if (_lpNotionalCap > 0) {
                /// @dev if > 0 the cap assumed to have been set, if == 0 assume no cap by convention
                require(
                    lpNotionalCumulatives[_marginEngine] < _lpNotionalCap,
                    "lp cap limit"
                );
            }
        } else {
            lpNotionalCumulatives[_marginEngine] -= _notionalDelta;
        }

        _;
    }

    function setLPNotionalCap(
        IMarginEngine _marginEngine,
        uint256 _lpNotionalCapNew
    ) external marginEngineOwnerOnly(_marginEngine) {
        if (lpNotionalCaps[_marginEngine] != _lpNotionalCapNew) {
            lpNotionalCaps[_marginEngine] = _lpNotionalCapNew;
            emit NotionalCap(_marginEngine, lpNotionalCaps[_marginEngine]);
        }
    }

    function updatePositionMargin(
        IMarginEngine _marginEngine,
        int24 _tickLower,
        int24 _tickUpper,
        uint256 _marginDelta
    ) internal {
        IERC20Minimal _underlyingToken = _marginEngine.underlyingToken();
        _underlyingToken.safeTransferFrom(
            msg.sender,
            address(this),
            _marginDelta
        );
        _underlyingToken.approve(address(_marginEngine), _marginDelta);
        _marginEngine.updatePositionMargin(
            msg.sender,
            _tickLower,
            _tickUpper,
            _marginDelta.toInt256()
        );
    }

    /// @notice Add liquidity to an initialized pool
    function mintOrBurn(MintOrBurnParams memory params)
        external
        override
        checkLPNotionalCap(params.marginEngine, params.notional, params.isMint)
        returns (int256 positionMarginRequirement)
    {
        Tick.checkTicks(params.tickLower, params.tickUpper);

        IVAMM vamm = params.marginEngine.vamm();

        IVAMM.VAMMVars memory _v = vamm.vammVars();
        bool vammUnlocked = _v.sqrtPriceX96 != 0;

        // get sqrt ratios

        uint160 sqrtRatioAX96 = TickMath.getSqrtRatioAtTick(params.tickLower);
        uint160 sqrtRatioBX96 = TickMath.getSqrtRatioAtTick(params.tickUpper);

        // initialize the vamm at midTick

        if (!vammUnlocked) {
            int24 midTick = (params.tickLower + params.tickUpper) / 2;
            uint160 sqrtRatioAtMidTickX96 = TickMath.getSqrtRatioAtTick(
                midTick
            );
            vamm.initializeVAMM(sqrtRatioAtMidTickX96);
        }

        // if margin delta is positive, top up position margin

        if (params.marginDelta > 0) {
            updatePositionMargin(
                params.marginEngine,
                params.tickLower,
                params.tickUpper,
                params.marginDelta
            );
        }

        // compute the liquidity amount for the amount of notional (amount1) specified

        uint128 liquidity = LiquidityAmounts.getLiquidityForAmount1(
            sqrtRatioAX96,
            sqrtRatioBX96,
            params.notional
        );

        positionMarginRequirement = 0;
        if (params.isMint) {
            positionMarginRequirement = vamm.mint(
                msg.sender,
                params.tickLower,
                params.tickUpper,
                liquidity
            );
        } else {
            // invoke a burn
            positionMarginRequirement = vamm.burn(
                msg.sender,
                params.tickLower,
                params.tickUpper,
                liquidity
            );
        }
    }

    function swap(SwapPeripheryParams memory params)
        external
        override
        returns (
            int256 _fixedTokenDelta,
            int256 _variableTokenDelta,
            uint256 _cumulativeFeeIncurred,
            int256 _fixedTokenDeltaUnbalanced,
            int256 _marginRequirement,
            int24 _tickAfter
        )
    {
        Tick.checkTicks(params.tickLower, params.tickUpper);

        IVAMM _vamm = params.marginEngine.vamm();

        if ((params.tickLower == 0) && (params.tickUpper == 0)) {
            int24 tickSpacing = _vamm.tickSpacing();
            IVAMM.VAMMVars memory _v = _vamm.vammVars();
            /// @dev assign default values to the upper and lower ticks

            int24 _tickLower = _v.tick - tickSpacing;
            int24 _tickUpper = _v.tick + tickSpacing;
            if (_tickLower < TickMath.MIN_TICK) {
                _tickLower = TickMath.MIN_TICK;
            }

            if (_tickUpper > TickMath.MAX_TICK) {
                _tickUpper = TickMath.MAX_TICK;
            }

            /// @audit add unit testsl, checks of tickLower/tickUpper divisiblilty by tickSpacing
            params.tickLower = _tickLower;
            params.tickUpper = _tickUpper;
        }

        // if margin delta is positive, top up position margin

        if (params.marginDelta > 0) {
            updatePositionMargin(
                params.marginEngine,
                params.tickLower,
                params.tickUpper,
                params.marginDelta
            );
        }

        int256 amountSpecified;

        if (params.isFT) {
            amountSpecified = params.notional.toInt256();
        } else {
            amountSpecified = -params.notional.toInt256();
        }

        IVAMM.SwapParams memory swapParams = IVAMM.SwapParams({
            recipient: msg.sender,
            amountSpecified: amountSpecified,
            sqrtPriceLimitX96: params.sqrtPriceLimitX96 == 0
                ? (
                    !params.isFT
                        ? TickMath.MIN_SQRT_RATIO + 1
                        : TickMath.MAX_SQRT_RATIO - 1
                )
                : params.sqrtPriceLimitX96,
            tickLower: params.tickLower,
            tickUpper: params.tickUpper
        });

        (
            _fixedTokenDelta,
            _variableTokenDelta,
            _cumulativeFeeIncurred,
            _fixedTokenDeltaUnbalanced,
            _marginRequirement
        ) = _vamm.swap(swapParams);
        _tickAfter = _vamm.vammVars().tick;
    }

    function getCurrentTick(IMarginEngine marginEngine)
        external
        view
        override
        returns (int24 currentTick)
    {
        IVAMM vamm = marginEngine.vamm();
        currentTick = vamm.vammVars().tick;
    }

    function estimatedCashflowAtMaturity(
        IMarginEngine marginEngine,
        address _owner,
        int24 _tickLower,
        int24 _tickUpper
    ) external override returns (int256 estimatedSettlementCashflow) {
        uint256 historicalAPYWad = marginEngine.getHistoricalApy();

        uint256 termStartTimestampWad = marginEngine.termStartTimestampWad();
        uint256 termEndTimestampWad = marginEngine.termEndTimestampWad();

        uint256 termInYears = FixedAndVariableMath.accrualFact(
            termEndTimestampWad - termStartTimestampWad
        );

        // calculate the estimated variable factor from start to maturity
        uint256 _estimatedVariableFactorFromStartToMaturity = PRBMathUD60x18
            .pow((PRBMathUD60x18.fromUint(1) + historicalAPYWad), termInYears) -
            PRBMathUD60x18.fromUint(1);

        Position.Info memory position = marginEngine.getPosition(
            _owner,
            _tickLower,
            _tickUpper
        );

        estimatedSettlementCashflow = FixedAndVariableMath
            .calculateSettlementCashflow(
                position.fixedTokenBalance,
                position.variableTokenBalance,
                termStartTimestampWad,
                termEndTimestampWad,
                _estimatedVariableFactorFromStartToMaturity
            );
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;
import "./IVAMM.sol";
import "./IPositionStructs.sol";
import "../core_libraries/Position.sol";
import "./rate_oracles/IRateOracle.sol";
import "./fcms/IFCM.sol";
import "./IFactory.sol";
import "./IERC20Minimal.sol";
import "contracts/utils/CustomErrors.sol";

interface IMarginEngine is IPositionStructs, CustomErrors {
    // structs

    struct MarginCalculatorParameters {
        /// @dev Upper bound of the underlying pool (e.g. Aave v2 USDC lending pool) APY from the initiation of the IRS AMM and until its maturity (18 decimals fixed point number)
        uint256 apyUpperMultiplierWad;
        /// @dev Lower bound of the underlying pool (e.g. Aave v2 USDC lending pool) APY from the initiation of the IRS AMM and until its maturity (18 decimals)
        uint256 apyLowerMultiplierWad;
        /// @dev The volatility of the underlying pool APY (settable by the owner of the Margin Engine) (18 decimals)
        int256 sigmaSquaredWad;
        /// @dev Margin Engine Parameter estimated via CIR model calibration (for details refer to litepaper) (18 decimals)
        int256 alphaWad;
        /// @dev Margin Engine Parameter estimated via CIR model calibration (for details refer to litepaper) (18 decimals)
        int256 betaWad;
        /// @dev Standard normal critical value used in the computation of the Upper APY Bound of the underlying pool
        int256 xiUpperWad;
        /// @dev Standard normal critical value used in the computation of the Lower APY Bound of the underlying pool
        int256 xiLowerWad;
        /// @dev Max term possible for a Voltz IRS AMM in seconds (18 decimals)
        int256 tMaxWad;
        /// @dev multiplier of the starting fixed rate (refer to the litepaper) if simulating a counterfactual fixed taker unwind (moving to the left along the VAMM) for purposes of calculating liquidation margin requirement
        uint256 devMulLeftUnwindLMWad;
        /// @dev multiplier of the starting fixed rate (refer to the litepaper) if simulating a counterfactual variable taker unwind (moving to the right along the VAMM) for purposes of calculating liquidation margin requirement
        uint256 devMulRightUnwindLMWad;
        /// @dev same as devMulLeftUnwindLMWad but for purposes of calculating the initial margin requirement
        uint256 devMulLeftUnwindIMWad;
        /// @dev same as devMulRightUnwindLMWad but for purposes of calculating the initial margin requirement
        uint256 devMulRightUnwindIMWad;
        /// @dev r_min from the litepaper eq. 11 for a scenario where counterfactual is a simulated fixed taker unwind (left unwind along the VAMM), used for liquidation margin calculation
        uint256 fixedRateDeviationMinLeftUnwindLMWad;
        /// @dev r_min from the litepaper eq. 11 for a scenario where counterfactual is a simulated variable taker unwind (right unwind along the VAMM), used for liquidation margin calculation
        uint256 fixedRateDeviationMinRightUnwindLMWad;
        /// @dev same as fixedRateDeviationMinLeftUnwindLMWad but for Initial Margin Requirement
        uint256 fixedRateDeviationMinLeftUnwindIMWad;
        /// @dev same as fixedRateDeviationMinRightUnwindLMWad but for Initial Margin Requirement
        uint256 fixedRateDeviationMinRightUnwindIMWad;
        /// @dev gamma from eqn. 12 [append this logic to the litepaper] from the litepaper, gamma is an adjustable parameter necessary to calculate scaled deviations to the fixed rate in counterfactual unwinds for minimum margin requirement calculations
        uint256 gammaWad;
        /// @dev settable parameter that ensures that minimumMarginRequirement is always above or equal to the minMarginToIncentiviseLiquidators which ensures there is always sufficient incentive for liquidators to liquidate positions given the fact their income is a proportion of position margin
        uint256 minMarginToIncentiviseLiquidators;
    }

    // Events
    event HistoricalApyWindowSetting(uint256 secondsAgo);
    event CacheMaxAgeSetting(uint256 cacheMaxAgeInSeconds);
    event RateOracle(uint256 cacheMaxAgeInSeconds);

    event ProtocolCollection(
        address sender,
        address indexed recipient,
        uint256 amount
    );
    event LiquidatorRewardSetting(uint256 liquidatorRewardWad);

    event VAMMSetting(IVAMM indexed vamm);

    event RateOracleSetting(IRateOracle indexed rateOracle);

    event FCMSetting(IFCM indexed fcm);

    event MarginCalculatorParametersSetting(
        MarginCalculatorParameters marginCalculatorParameters
    );

    event PositionMarginUpdate(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        int256 marginDelta
    );

    event HistoricalApy(uint256 value);

    event PositionSettlement(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        int256 settlementCashflow
    );

    event PositionLiquidation(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        address liquidator,
        int256 notionalUnwound,
        uint256 liquidatorReward
    );

    event PositionUpdate(
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 _liquidity,
        int256 margin,
        int256 fixedTokenBalance,
        int256 variableTokenBalance,
        uint256 accumulatedFees
    );

    // immutables

    /// @notice The Full Collateralisation Module (FCM)
    /// @dev The FCM is a smart contract that acts as an intermediary Position between the Voltz Core and traders who wish to take fully collateralised fixed taker positions
    /// @dev An example FCM is the AaveFCM.sol module which inherits from the IFCM interface, it lets fixed takers deposit underlying yield bearing tokens (e.g.) aUSDC as margin to enter into a fixed taker swap without the need to worry about liquidations
    /// @dev since the MarginEngine is confident the FCM is always fully collateralised, it does not let liquidators liquidate the FCM Position
    /// @return The Full Collateralisation Module linked to the MarginEngine
    function fcm() external view returns (IFCM);

    /// @notice The Factory
    /// @dev the factory that deployed the master Margin Engine
    function factory() external view returns (IFactory);

    /// @notice The address of the underlying (non-yield bearing) token - e.g. USDC
    /// @return The underlying ERC20 token (e.g. USDC)
    function underlyingToken() external view returns (IERC20Minimal);

    /// @notice The rateOracle contract which lets the protocol access historical apys in the yield bearing pools it is built on top of
    /// @return The underlying ERC20 token (e.g. USDC)
    function rateOracle() external view returns (IRateOracle);

    /// @notice The unix termStartTimestamp of the MarginEngine in Wad
    /// @return Term Start Timestamp in Wad
    function termStartTimestampWad() external view returns (uint256);

    /// @notice The unix termEndTimestamp of the MarginEngine in Wad
    /// @return Term End Timestamp in Wad
    function termEndTimestampWad() external view returns (uint256);

    /// @dev "constructor" for proxy instances
    function initialize(
        IERC20Minimal __underlyingToken,
        IRateOracle __rateOracle,
        uint256 __termStartTimestampWad,
        uint256 __termEndTimestampWad
    ) external;

    // view functions

    /// @notice The liquidator Reward Percentage (in Wad)
    /// @dev liquidatorReward (in wad) is the percentage of the margin (of a liquidated position) that is sent to the liquidator
    /// @dev following a successful liquidation that results in a trader/position unwind; example value:  2 * 10**16 => 2% of position margin is used to cover liquidator reward
    /// @return Liquidator Reward in Wad
    function liquidatorRewardWad() external view returns (uint256);

    /// @notice VAMM (Virtual Automated Market Maker) linked to the MarginEngine
    /// @dev The VAMM is responsible for pricing only (determining the effective fixed rate at which a given Interest Rate Swap notional will be executed)
    /// @return The VAMM
    function vamm() external view returns (IVAMM);

    /// @notice Returns the information about a position by the position's key
    /// @param _owner The address of the position owner
    /// @param _tickLower The lower tick boundary of the position
    /// @param _tickUpper The upper tick boundary of the position
    /// Returns position The Position.Info corresponding to the requested position
    function getPosition(
        address _owner,
        int24 _tickLower,
        int24 _tickUpper
    ) external returns (Position.Info memory position);

    /// @notice Gets the look-back window size that's used to request the historical APY from the rate Oracle
    /// @dev The historical APY of the Rate Oracle is necessary for MarginEngine computations
    /// @dev The look-back window is seconds from the current timestamp
    /// @dev This value is only settable by the the Factory owner and may be unique for each MarginEngine
    /// @dev When setting secondAgo, the setter needs to take into consideration the underlying volatility of the APYs in the reference yield-bearing pool (e.g. Aave v2 USDC)
    function lookbackWindowInSeconds() external view returns (uint256);

    // non-view functions

    /// @notice Sets secondsAgo: The look-back window size used to calculate the historical APY for margin purposes
    /// @param _secondsAgo the duration of the lookback window in seconds
    /// @dev Can only be set by the Factory Owner
    function setLookbackWindowInSeconds(uint256 _secondsAgo) external;

    /// @notice Set the MarginCalculatorParameters (each margin engine can have its own custom set of margin calculator parameters)
    /// @param _marginCalculatorParameters the MarginCalculatorParameters to set
    /// @dev marginCalculatorParameteres is of type MarginCalculatorParameters (refer to the definition of the struct for elaboration on what each parameter means)
    function setMarginCalculatorParameters(
        MarginCalculatorParameters memory _marginCalculatorParameters
    ) external;

    /// @notice Sets the liquidator reward: proportion of liquidated position's margin paid as a reward to the liquidator
    function setLiquidatorReward(uint256 _liquidatorRewardWad) external;

    /// @notice updates the margin account of a position which can be uniquily identified with its _owner, tickLower, tickUpper
    /// @dev if the position has positive liquidity then before the margin update, we call the updatePositionTokenBalancesAndAccountForFees functon that calculates up to date
    /// @dev margin, fixed and variable token balances by taking into account the fee income from their tick range and fixed and variable deltas settled along their tick range
    /// @dev marginDelta is the delta applied to the current margin of a position, if the marginDelta is negative, the position is withdrawing margin, if the marginDelta is positive, the position is depositing funds in terms of the underlying tokens
    /// @dev if marginDelta is negative, we need to check if the msg.sender is either the _owner of the position or the msg.sender is apporved by the _owner to act on their behalf in Voltz Protocol
    /// @dev the approval logic is implemented in the Factory.sol
    /// @dev if marginDelta is negative, we additionally need to check if post the initial margin requirement is still satisfied post withdrawal
    /// @dev if marginDelta is positive, the depositor of the margin is either the msg.sender or the owner who interacted through an approved peripheral contract
    function updatePositionMargin(
        address _owner,
        int24 _tickLower,
        int24 _tickUpper,
        int256 marginDelta
    ) external;

    /// @notice Settles a Position
    /// @dev Can be called by anyone
    /// @dev A position cannot be settled before maturity
    /// @dev Steps to settle a position:
    /// @dev 1. Retrieve the current fixed and variable token growth inside the tick range of a position
    /// @dev 2. Calculate accumulated fixed and variable balances of the position since the last mint/poke/burn
    /// @dev 3. Update the postion's fixed and variable token balances
    /// @dev 4. Update the postion's fixed and varaible token growth inside last to enable future updates
    /// @dev 5. Calculates the settlement cashflow from all of the IRS contracts the position has entered since entering the AMM
    /// @dev 6. Updates the fixed and variable token balances of the position to be zero, adds the settlement cashflow to the position's current margin
    function settlePosition(
        address _owner,
        int24 _tickLower,
        int24 _tickUpper
    ) external;

    /// @notice Liquidate a Position
    /// @dev Steps to liquidate: update position's fixed and variable token balances to account for balances accumulated throughout the trades made since the last mint/burn/poke,
    /// @dev Check if the position is liquidatable by calling the isLiquidatablePosition function of the calculator, revert if that is not the case,
    /// @dev Calculate the liquidation reward = current margin of the position * liquidatorReward, subtract the liquidator reward from the position margin,
    /// @dev Burn the position's liquidity, unwind unnetted fixed and variable balances of a position, transfer the reward to the liquidator
    function liquidatePosition(
        address _owner,
        int24 _tickLower,
        int24 _tickUpper
    ) external returns (uint256);

    /// @notice Update a Position post VAMM induced mint or burn
    /// @dev Steps taken:
    /// @dev 1. Update position liquidity based on params.liquidityDelta
    /// @dev 2. Update fixed and variable token balances of the position based on how much has been accumulated since the last mint/burn/poke
    /// @dev 3. Update position's margin by taking into account the position accumulated fees since the last mint/burn/poke
    /// @dev 4. Update fixed and variable token growth + fee growth in the position info struct for future interactions with the position
    /// @param _params necessary for the purposes of referencing the position being updated (owner, tickLower, tickUpper, _) and the liquidity delta that needs to be applied to position._liquidity
    function updatePositionPostVAMMInducedMintBurn(
        IPositionStructs.ModifyPositionParams memory _params
    ) external returns (int256 _positionMarginRequirement);

    // @notive Update a position post VAMM induced swap
    /// @dev Since every position can also engage in swaps with the VAMM, this function needs to be invoked after non-external calls are made to the VAMM's swap function
    /// @dev This purpose of this function is to:
    /// @dev 1. updatePositionTokenBalancesAndAccountForFees
    /// @dev 2. update position margin to account for fees paid to execute the swap
    /// @dev 3. calculate the position margin requrement given the swap, check if the position marigin satisfies the most up to date requirement
    /// @dev 4. if all the requirements are satisfied then position gets updated to take into account the swap that it just entered, if the minimum margin requirement is not satisfied then the transaction will revert
    function updatePositionPostVAMMInducedSwap(
        address _owner,
        int24 _tickLower,
        int24 _tickUpper,
        int256 _fixedTokenDelta,
        int256 _variableTokenDelta,
        uint256 _cumulativeFeeIncurred,
        int256 _fixedTokenDeltaUnbalanced
    ) external returns (int256 _positionMarginRequirement);

    /// @notice function that can only be called by the owner enables collection of protocol generated fees from any give margin engine
    /// @param _recipient the address which collects the protocol generated fees
    /// @param _amount the amount in terms of underlying tokens collected from the protocol's earnings
    function collectProtocol(address _recipient, uint256 _amount) external;

    /// @notice sets the Virtual Automated Market Maker (VAMM) attached to the MarginEngine
    /// @dev the VAMM is responsible for price discovery, whereas the management of the underlying collateral and liquidations are handled by the Margin Engine
    function setVAMM(IVAMM _vAMM) external;

    /// @notice sets the Virtual Automated Market Maker (VAMM) attached to the MarginEngine
    /// @dev the VAMM is responsible for price discovery, whereas the management of the underlying collateral and liquidations are handled by the Margin Engine
    function setRateOracle(IRateOracle __rateOracle) external;

    /// @notice sets the Full Collateralisation Module
    function setFCM(IFCM _newFCM) external;

    /// @notice transfers margin in terms of underlying tokens to a trader from the Full Collateralisation Module
    /// @dev post maturity date of the MarginEngine, the traders from the Full Collateralisation module will be able to settle with the MarginEngine
    /// @dev to ensure their fixed yield is guaranteed, in order to collect the funds from the MarginEngine, the FCM needs to invoke the transferMarginToFCMTrader function whcih is only callable by the FCM attached to a particular Margin Engine
    function transferMarginToFCMTrader(address _account, uint256 _marginDelta)
        external;

    /// @notice Gets the maximum age of the cached historical APY value can be without being refreshed
    function cacheMaxAgeInSeconds() external view returns (uint256);

    /// @notice Sets the maximum age that the cached historical APY value
    /// @param _cacheMaxAgeInSeconds The new maximum age that the historical APY cache can be before being considered stale
    function setCacheMaxAgeInSeconds(uint256 _cacheMaxAgeInSeconds) external;

    /// @notice Get Historical APY
    /// @dev The lookback window used by this function is determined by the secondsAgo state variable
    /// @dev refresh the historical apy cache if necessary
    /// @return historicalAPY (Wad)
    function getHistoricalApy() external returns (uint256);

    function getPositionMarginRequirement(
        address _recipient,
        int24 _tickLower,
        int24 _tickUpper,
        bool _isLM
    ) external returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.9;
import "./IMarginEngine.sol";
import "./IFactory.sol";
import "./IPositionStructs.sol";
import "../core_libraries/Tick.sol";
import "contracts/utils/CustomErrors.sol";

interface IVAMM is IPositionStructs, CustomErrors {
    // events
    event Swap(
        address sender,
        address indexed recipient,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        int256 desiredNotional,
        uint160 sqrtPriceLimitX96,
        uint256 cumulativeFeeIncurred,
        int256 fixedTokenDelta,
        int256 variableTokenDelta,
        int256 fixedTokenDeltaUnbalanced
    );

    /// @dev emitted after a given vamm is successfully initialized
    event VAMMInitialization(uint160 sqrtPriceX96, int24 tick);

    /// @dev emitted after a successful minting of a given LP position
    event Mint(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount
    );

    /// @dev emitted after a successful burning of a given LP position
    event Burn(
        address sender,
        address indexed owner,
        int24 indexed tickLower,
        int24 indexed tickUpper,
        uint128 amount
    );

    /// @dev emitted after setting feeProtocol
    event FeeProtocol(uint8 feeProtocol);

    /// @dev emitted after fee is set
    event Fee(uint256 feeWad);

    /// @dev emitted after the _isAlpha boolean is updated by the owner of the VAMM
    /// @dev _isAlpha boolean dictates whether the Margin Engine is in the Alpha State, i.e. mints can only be done via the periphery
    /// @dev additionally, the periphery has the logic to take care of lp notional caps in the Alpha State phase of VAMM
    /// @dev __isAlpha is the newly set value for the _isAlpha boolean
    event IsAlpha(bool __isAlpha);

    event VAMMPriceChange(int24 tick);

    // structs

    struct VAMMVars {
        /// @dev The current price of the pool as a sqrt(variableToken/fixedToken) Q64.96 value
        uint160 sqrtPriceX96;
        /// @dev The current tick of the vamm, i.e. according to the last tick transition that was run.
        int24 tick;
        // the current protocol fee as a percentage of the swap fee taken on withdrawal
        // represented as an integer denominator (1/x)
        uint8 feeProtocol;
    }

    struct SwapParams {
        /// @dev Address of the trader initiating the swap
        address recipient;
        /// @dev The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
        int256 amountSpecified;
        /// @dev The Q64.96 sqrt price limit. If !isFT, the price cannot be less than this
        uint160 sqrtPriceLimitX96;
        /// @dev lower tick of the position
        int24 tickLower;
        /// @dev upper tick of the position
        int24 tickUpper;
    }

    struct SwapCache {
        /// @dev liquidity at the beginning of the swap
        uint128 liquidityStart;
        // the current protocol fee as a percentage of the swap fee taken on withdrawal
        // represented as an integer denominator (1/x)%
        uint8 feeProtocol;
    }

    /// @dev the top level state of the swap, the results of which are recorded in storage at the end
    struct SwapState {
        /// @dev the amount remaining to be swapped in/out of the input/output asset
        int256 amountSpecifiedRemaining;
        /// @dev the amount already swapped out/in of the output/input asset
        int256 amountCalculated;
        /// @dev current sqrt(price)
        uint160 sqrtPriceX96;
        /// @dev the tick associated with the current price
        int24 tick;
        /// @dev the global fixed token growth
        int256 fixedTokenGrowthGlobalX128;
        /// @dev the global variable token growth
        int256 variableTokenGrowthGlobalX128;
        /// @dev the current liquidity in range
        uint128 liquidity;
        /// @dev the global fee growth of the underlying token
        uint256 feeGrowthGlobalX128;
        /// @dev amount of underlying token paid as protocol fee
        uint256 protocolFee;
        /// @dev cumulative fee incurred while initiating a swap
        uint256 cumulativeFeeIncurred;
        /// @dev fixedTokenDelta that will be applied to the fixed token balance of the position executing the swap (recipient)
        int256 fixedTokenDeltaCumulative;
        /// @dev variableTokenDelta that will be applied to the variable token balance of the position executing the swap (recipient)
        int256 variableTokenDeltaCumulative;
        /// @dev fixed token delta cumulative but without rebalancings applied
        int256 fixedTokenDeltaUnbalancedCumulative;
    }

    struct StepComputations {
        /// @dev the price at the beginning of the step
        uint160 sqrtPriceStartX96;
        /// @dev the next tick to swap to from the current tick in the swap direction
        int24 tickNext;
        /// @dev whether tickNext is initialized or not
        bool initialized;
        /// @dev sqrt(price) for the next tick (1/0)
        uint160 sqrtPriceNextX96;
        /// @dev how much is being swapped in in this step
        uint256 amountIn;
        /// @dev how much is being swapped out
        uint256 amountOut;
        /// @dev how much fee is being paid in (underlying token)
        uint256 feeAmount;
        /// @dev ...
        uint256 feeProtocolDelta;
        /// @dev ...
        int256 fixedTokenDeltaUnbalanced; // for LP
        /// @dev ...
        int256 fixedTokenDelta; // for LP
        /// @dev ...
        int256 variableTokenDelta; // for LP
    }

    /// @dev "constructor" for proxy instances
    function initialize(IMarginEngine __marginEngine, int24 __tickSpacing)
        external;

    // immutables

    /// @notice The vamm's fee (proportion) in wad
    /// @return The fee in wad
    function feeWad() external view returns (uint256);

    /// @notice The vamm tick spacing
    /// @dev Ticks can only be used at multiples of this value, minimum of 1 and always positive
    /// e.g.: a tickSpacing of 3 means ticks can be initialized every 3rd tick, i.e., ..., -6, -3, 0, 3, 6, ...
    /// This value is an int24 to avoid casting even though it is always positive.
    /// @return The tick spacing
    function tickSpacing() external view returns (int24);

    /// @notice The maximum amount of position liquidity that can use any tick in the range
    /// @dev This parameter should be enforced per tick (when setting) to prevent liquidity from overflowing a uint128 at any point, and
    /// also prevents out-of-range liquidity from being used to prevent adding in-range liquidity to the vamm
    /// @return The max amount of liquidity per tick
    function maxLiquidityPerTick() external view returns (uint128);

    // state variables

    /// @return The current VAMM Vars (see struct definition for semantics)
    function vammVars() external view returns (VAMMVars memory);

    /// @return If true, the VAMM Proxy is currently in alpha state, hence minting can only be done via the periphery. If false, minting can be done directly via VAMM.
    function isAlpha() external view returns (bool);

    /// @notice The fixed token growth accumulated per unit of liquidity for the entire life of the vamm
    /// @dev This value can overflow the uint256
    function fixedTokenGrowthGlobalX128() external view returns (int256);

    /// @notice The variable token growth accumulated per unit of liquidity for the entire life of the vamm
    /// @dev This value can overflow the uint256
    function variableTokenGrowthGlobalX128() external view returns (int256);

    /// @notice The fee growth collected per unit of liquidity for the entire life of the vamm
    /// @dev This value can overflow the uint256
    function feeGrowthGlobalX128() external view returns (uint256);

    /// @notice The currently in range liquidity available to the vamm
    function liquidity() external view returns (uint128);

    /// @notice The amount underlying token that are owed to the protocol
    /// @dev Protocol fees will never exceed uint256
    function protocolFees() external view returns (uint256);

    function marginEngine() external view returns (IMarginEngine);

    function factory() external view returns (IFactory);

    /// @notice Function that sets the feeProtocol of the vamm
    /// @dev the current protocol fee as a percentage of the swap fee taken on withdrawal
    // represented as an integer denominator (1/x)
    function setFeeProtocol(uint8 feeProtocol) external;

    /// @notice Function that sets the _isAlpha state variable, if it is set to true the protocol is in the Alpha State
    /// @dev if the VAMM is at the alpha state, mints can only be done via the periphery which in turn takes care of notional caps for the LPs
    /// @dev this function can only be called by the owner of the VAMM
    function setIsAlpha(bool __isAlpha) external;

    /// @notice Function that sets fee of the vamm
    /// @dev The vamm's fee (proportion) in wad
    function setFee(uint256 _fee) external;

    /// @notice Updates internal accounting to reflect a collection of protocol fees. The actual transfer of fees must happen separately in the AMM
    /// @dev can only be done via the collectProtocol function of the parent AMM of the vamm
    function updateProtocolFees(uint256 protocolFeesCollected) external;

    /// @notice Sets the initial price for the vamm
    /// @dev Price is represented as a sqrt(amountVariableToken/amountFixedToken) Q64.96 value
    /// @param sqrtPriceX96 the initial sqrt price of the vamm as a Q64.96
    function initializeVAMM(uint160 sqrtPriceX96) external;

    /// @notice removes liquidity given recipient/tickLower/tickUpper of the position
    /// @param recipient The address for which the liquidity will be removed
    /// @param tickLower The lower tick of the position in which to remove liquidity
    /// @param tickUpper The upper tick of the position in which to remove liqudiity
    /// @param amount The amount of liquidity to burn
    function burn(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (int256 positionMarginRequirement);

    /// @notice Adds liquidity for the given recipient/tickLower/tickUpper position
    /// @param recipient The address for which the liquidity will be created
    /// @param tickLower The lower tick of the position in which to add liquidity
    /// @param tickUpper The upper tick of the position in which to add liquidity
    /// @param amount The amount of liquidity to mint
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (int256 positionMarginRequirement);

    /// @notice Initiate an Interest Rate Swap
    /// @param params SwapParams necessary to initiate an Interest Rate Swap
    /// @return fixedTokenDelta Fixed Token Delta
    /// @return variableTokenDelta Variable Token Delta
    /// @return cumulativeFeeIncurred Cumulative Fee Incurred
    function swap(SwapParams memory params)
        external
        returns (
            int256 fixedTokenDelta,
            int256 variableTokenDelta,
            uint256 cumulativeFeeIncurred,
            int256 fixedTokenDeltaUnbalanced,
            int256 marginRequirement
        );

    /// @notice Look up information about a specific tick in the amm
    /// @param tick The tick to look up
    /// @return liquidityGross: the total amount of position liquidity that uses the vamm either as tick lower or tick upper,
    /// liquidityNet: how much liquidity changes when the vamm price crosses the tick,
    /// feeGrowthOutsideX128: the fee growth on the other side of the tick from the current tick in underlying token. i.e. if liquidityGross is greater than 0. In addition, these values are only relative.
    function ticks(int24 tick) external view returns (Tick.Info memory);

    /// @notice Returns 256 packed tick initialized boolean values. See TickBitmap for more information
    function tickBitmap(int16 wordPosition) external view returns (uint256);

    /// @notice Computes the current fixed and variable token growth inside a given tick range given the current tick in the vamm
    /// @param tickLower The lower tick of the position
    /// @param tickUpper The upper tick of the position
    /// @return fixedTokenGrowthInsideX128 Fixed Token Growth inside the given tick range
    /// @return variableTokenGrowthInsideX128 Variable Token Growth inside the given tick range
    /// @return feeGrowthInsideX128 Fee Growth Inside given tick range
    function computeGrowthInside(int24 tickLower, int24 tickUpper)
        external
        view
        returns (
            int256 fixedTokenGrowthInsideX128,
            int256 variableTokenGrowthInsideX128,
            uint256 feeGrowthInsideX128
        );
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../interfaces/IMarginEngine.sol";
import "../interfaces/IVAMM.sol";
import "contracts/utils/CustomErrors.sol";

interface IPeriphery is CustomErrors {
    // events

    /// @dev emitted after new lp notional cap is set
    event NotionalCap(IMarginEngine _marginEngine, uint256 _lpNotionalCapNew);

    // structs

    struct MintOrBurnParams {
        IMarginEngine marginEngine;
        int24 tickLower;
        int24 tickUpper;
        uint256 notional;
        bool isMint;
        uint256 marginDelta;
    }

    struct SwapPeripheryParams {
        IMarginEngine marginEngine;
        bool isFT;
        uint256 notional;
        uint160 sqrtPriceLimitX96;
        int24 tickLower;
        int24 tickUpper;
        uint256 marginDelta;
    }

    // view functions

    function getCurrentTick(IMarginEngine marginEngine)
        external
        view
        returns (int24 currentTick);

    /// @param _marginEngine MarginEngine for which to get the lp cap in underlying tokens
    /// @return Notional Cap for liquidity providers that mint or burn via periphery (enforced in the core if isAlpha is set to true)
    function lpNotionalCaps(IMarginEngine _marginEngine)
        external
        returns (uint256);

    /// @param _marginEngine MarginEngine for which to get the lp notional cumulative in underlying tokens
    /// @return Total amount of notional supplied by the LPs to a given _marginEngine via the periphery
    function lpNotionalCumulatives(IMarginEngine _marginEngine)
        external
        returns (uint256);

    // non-view functions

    function mintOrBurn(MintOrBurnParams memory params)
        external
        returns (int256 positionMarginRequirement);

    function swap(SwapPeripheryParams memory params)
        external
        returns (
            int256 _fixedTokenDelta,
            int256 _variableTokenDelta,
            uint256 _cumulativeFeeIncurred,
            int256 _fixedTokenDeltaUnbalanced,
            int256 _marginRequirement,
            int24 _tickAfter
        );

    function estimatedCashflowAtMaturity(
        IMarginEngine marginEngine,
        address _owner,
        int24 _tickLower,
        int24 _tickUpper
    ) external returns (int256 estimatedSettlementCashflow);
}

// SPDX-License-Identifier: GPL-2.0-or-later

// solhint-disable no-inline-assembly

pragma solidity =0.8.9;

/// @title Math library for computing sqrt prices from ticks and vice versa
/// @notice Computes sqrt price for ticks of size 1.0001, i.e. sqrt(1.0001^tick) as fixed point Q64.96 numbers. Supports
/// prices between 2**-128 and 2**128
library TickMath {
    /// @dev MIN_TICK corresponds to an annualized fixed rate of 1000%
    /// @dev MAX_TICK corresponds to an annualized fixed rate of 0.001%
    /// @dev MIN and MAX TICKs can't be safely changed without reinstating getSqrtRatioAtTick removed lines of code from original
    /// TickMath.sol implementation in uniswap v3

    /// @dev The minimum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**-128
    int24 internal constant MIN_TICK = -69100;
    /// @dev The maximum tick that may be passed to #getSqrtRatioAtTick computed from log base 1.0001 of 2**128
    int24 internal constant MAX_TICK = -MIN_TICK;

    /// @dev The minimum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MIN_TICK)
    uint160 internal constant MIN_SQRT_RATIO = 2503036416286949174936592462;
    /// @dev The maximum value that can be returned from #getSqrtRatioAtTick. Equivalent to getSqrtRatioAtTick(MAX_TICK)
    uint160 internal constant MAX_SQRT_RATIO = 2507794810551837817144115957740;

    /// @notice Calculates sqrt(1.0001^tick) * 2^96
    /// @dev Throws if |tick| > max tick
    /// @param tick The input tick for the above formula
    /// @return sqrtPriceX96 A Fixed point Q64.96 number representing the sqrt of the ratio of the two assets (token1/token0)
    /// at the given tick
    function getSqrtRatioAtTick(int24 tick)
        internal
        pure
        returns (uint160 sqrtPriceX96)
    {
        uint256 absTick = tick < 0
            ? uint256(-int256(tick))
            : uint256(int256(tick));
        require(absTick <= uint256(int256(MAX_TICK)), "T");

        uint256 ratio = absTick & 0x1 != 0
            ? 0xfffcb933bd6fad37aa2d162d1a594001
            : 0x100000000000000000000000000000000;
        if (absTick & 0x2 != 0)
            ratio = (ratio * 0xfff97272373d413259a46990580e213a) >> 128;
        if (absTick & 0x4 != 0)
            ratio = (ratio * 0xfff2e50f5f656932ef12357cf3c7fdcc) >> 128;
        if (absTick & 0x8 != 0)
            ratio = (ratio * 0xffe5caca7e10e4e61c3624eaa0941cd0) >> 128;
        if (absTick & 0x10 != 0)
            ratio = (ratio * 0xffcb9843d60f6159c9db58835c926644) >> 128;
        if (absTick & 0x20 != 0)
            ratio = (ratio * 0xff973b41fa98c081472e6896dfb254c0) >> 128;
        if (absTick & 0x40 != 0)
            ratio = (ratio * 0xff2ea16466c96a3843ec78b326b52861) >> 128;
        if (absTick & 0x80 != 0)
            ratio = (ratio * 0xfe5dee046a99a2a811c461f1969c3053) >> 128;
        if (absTick & 0x100 != 0)
            ratio = (ratio * 0xfcbe86c7900a88aedcffc83b479aa3a4) >> 128;
        if (absTick & 0x200 != 0)
            ratio = (ratio * 0xf987a7253ac413176f2b074cf7815e54) >> 128;
        if (absTick & 0x400 != 0)
            ratio = (ratio * 0xf3392b0822b70005940c7a398e4b70f3) >> 128;
        if (absTick & 0x800 != 0)
            ratio = (ratio * 0xe7159475a2c29b7443b29c7fa6e889d9) >> 128;
        if (absTick & 0x1000 != 0)
            ratio = (ratio * 0xd097f3bdfd2022b8845ad8f792aa5825) >> 128;
        if (absTick & 0x2000 != 0)
            ratio = (ratio * 0xa9f746462d870fdf8a65dc1f90e061e5) >> 128;
        if (absTick & 0x4000 != 0)
            ratio = (ratio * 0x70d869a156d2a1b890bb3df62baf32f7) >> 128;
        if (absTick & 0x8000 != 0)
            ratio = (ratio * 0x31be135f97d08fd981231505542fcfa6) >> 128;
        if (absTick & 0x10000 != 0)
            ratio = (ratio * 0x9aa508b5b7a84e1c677de54f3e99bc9) >> 128;
        if (tick > 0) ratio = type(uint256).max / ratio;

        // this divides by 1<<32 rounding up to go from a Q128.128 to a Q128.96.
        // we then downcast because we know the result always fits within 160 bits due to our tick input constraint
        // we round up in the division so getTickAtSqrtRatio of the output price is always consistent
        sqrtPriceX96 = uint160(
            (ratio >> 32) + (ratio % (1 << 32) == 0 ? 0 : 1)
        );
    }

    /// @notice Calculates the greatest tick value such that getRatioAtTick(tick) <= ratio
    /// @dev Throws in case sqrtPriceX96 < MIN_SQRT_RATIO, as MIN_SQRT_RATIO is the lowest value getRatioAtTick may
    /// ever return.
    /// @param sqrtPriceX96 The sqrt ratio for which to compute the tick as a Q64.96
    /// @return tick The greatest tick for which the ratio is less than or equal to the input ratio
    function getTickAtSqrtRatio(uint160 sqrtPriceX96)
        internal
        pure
        returns (int24 tick)
    {
        // second inequality must be < because the price can never reach the price at the max tick
        require(
            sqrtPriceX96 >= MIN_SQRT_RATIO && sqrtPriceX96 < MAX_SQRT_RATIO,
            "R"
        );
        uint256 ratio = uint256(sqrtPriceX96) << 32;

        uint256 r = ratio;
        uint256 msb = 0;

        assembly {
            let f := shl(7, gt(r, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(6, gt(r, 0xFFFFFFFFFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(5, gt(r, 0xFFFFFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(4, gt(r, 0xFFFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(3, gt(r, 0xFF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(2, gt(r, 0xF))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := shl(1, gt(r, 0x3))
            msb := or(msb, f)
            r := shr(f, r)
        }
        assembly {
            let f := gt(r, 0x1)
            msb := or(msb, f)
        }

        if (msb >= 128) r = ratio >> (msb - 127);
        else r = ratio << (127 - msb);

        // solhint-disable-next-line var-name-mixedcase
        int256 log_2 = (int256(msb) - 128) << 64;

        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(63, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(62, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(61, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(60, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(59, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(58, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(57, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(56, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(55, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(54, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(53, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(52, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(51, f))
            r := shr(f, r)
        }
        assembly {
            r := shr(127, mul(r, r))
            let f := shr(128, r)
            log_2 := or(log_2, shl(50, f))
        }

        // solhint-disable-next-line var-name-mixedcase
        int256 log_sqrt10001 = log_2 * 255738958999603826347141; // 128.128 number

        int24 tickLow = int24(
            (log_sqrt10001 - 3402992956809132418596140100660247210) >> 128
        );
        int24 tickHi = int24(
            (log_sqrt10001 + 291339464771989622907027621153398088495) >> 128
        );

        tick = tickLow == tickHi
            ? tickLow
            : getSqrtRatioAtTick(tickHi) <= sqrtPriceX96
            ? tickHi
            : tickLow;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.9;

import "../../utils/FullMath.sol";
import "../../utils/FixedPoint96.sol";

/// @title Liquidity amount functions
/// @notice Provides functions for computing liquidity amounts from token amounts and prices
library LiquidityAmounts {

    /// @notice Downcasts uint256 to uint128
    /// @param x The uint258 to be downcasted
    /// @return y The passed value, downcasted to uint128
    function toUint128(uint256 x) private pure returns (uint128 y) {
        require((y = uint128(x)) == x);
    }

    /// @notice Computes the amount of liquidity received for a given amount of amount1 (notional) and price range
    /// @dev Calculates amount1 / (sqrt(upper) - sqrt(lower)).
    /// @param sqrtRatioAX96 A sqrt price representing the first tick boundary
    /// @param sqrtRatioBX96 A sqrt price representing the second tick boundary
    /// @param amount1 The amount1 being sent in
    /// @return liquidity The amount of returned liquidity
    function getLiquidityForAmount1(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint256 amount1
    ) internal pure returns (uint128 liquidity) {
        if (sqrtRatioAX96 > sqrtRatioBX96) (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);
        return toUint128(FullMath.mulDiv(amount1, FixedPoint96.Q96, sqrtRatioBX96 - sqrtRatioAX96));
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeCast.sol)

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.9;
import "../utils/LiquidityMath.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "../utils/TickMath.sol";
import "../utils/Printer.sol";

/// @title Tick
/// @notice Contains functions for managing tick processes and relevant calculations
library Tick {
    using SafeCast for int256;
    using SafeCast for uint256;

    int24 public constant MAXIMUM_TICK_SPACING = 16384;

    // info stored for each initialized individual tick
    struct Info {
        /// @dev the total position liquidity that references this tick (either as tick lower or tick upper)
        uint128 liquidityGross;
        /// @dev amount of net liquidity added (subtracted) when tick is crossed from left to right (right to left),
        int128 liquidityNet;
        /// @dev fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        /// @dev only has relative meaning, not absolute — the value depends on when the tick is initialized
        int256 fixedTokenGrowthOutsideX128;
        int256 variableTokenGrowthOutsideX128;
        uint256 feeGrowthOutsideX128;
        /// @dev true iff the tick is initialized, i.e. the value is exactly equivalent to the expression liquidityGross != 0
        /// @dev these 8 bits are set to prevent fresh sstores when crossing newly initialized ticks
        bool initialized;
    }

    /// @notice Derives max liquidity per tick from given tick spacing
    /// @dev Executed within the pool constructor
    /// @param tickSpacing The amount of required tick separation, realized in multiples of `tickSpacing`
    ///     e.g., a tickSpacing of 3 requires ticks to be initialized every 3rd tick i.e., ..., -6, -3, 0, 3, 6, ...
    /// @return The max liquidity per tick
    function tickSpacingToMaxLiquidityPerTick(int24 tickSpacing)
        internal
        pure
        returns (uint128)
    {
        int24 minTick = TickMath.MIN_TICK - (TickMath.MIN_TICK % tickSpacing);
        int24 maxTick = -minTick;
        uint24 numTicks = uint24((maxTick - minTick) / tickSpacing) + 1;
        return type(uint128).max / numTicks;
    }

    /// @dev Common checks for valid tick inputs.
    function checkTicks(int24 tickLower, int24 tickUpper) internal pure {
        require(tickLower < tickUpper, "TLU");
        require(tickLower >= TickMath.MIN_TICK, "TLM");
        require(tickUpper <= TickMath.MAX_TICK, "TUM");
    }

    struct FeeGrowthInsideParams {
        int24 tickLower;
        int24 tickUpper;
        int24 tickCurrent;
        uint256 feeGrowthGlobalX128;
    }

    function _getGrowthInside(
        int24 _tickLower,
        int24 _tickUpper,
        int24 _tickCurrent,
        int256 _growthGlobalX128,
        int256 _lowerGrowthOutsideX128,
        int256 _upperGrowthOutsideX128
    ) private pure returns (int256) {
        // calculate the growth below
        int256 _growthBelowX128;

        if (_tickCurrent >= _tickLower) {
            _growthBelowX128 = _lowerGrowthOutsideX128;
        } else {
            _growthBelowX128 = _growthGlobalX128 - _lowerGrowthOutsideX128;
        }

        // calculate the growth above
        int256 _growthAboveX128;

        if (_tickCurrent < _tickUpper) {
            _growthAboveX128 = _upperGrowthOutsideX128;
        } else {
            _growthAboveX128 = _growthGlobalX128 - _upperGrowthOutsideX128;
        }

        int256 _growthInsideX128;

        _growthInsideX128 =
            _growthGlobalX128 -
            (_growthBelowX128 + _growthAboveX128);

        return _growthInsideX128;
    }

    function getFeeGrowthInside(
        mapping(int24 => Tick.Info) storage self,
        FeeGrowthInsideParams memory params
    ) internal view returns (uint256 feeGrowthInsideX128) {
        unchecked {
            Info storage lower = self[params.tickLower];
            Info storage upper = self[params.tickUpper];

            feeGrowthInsideX128 = uint256(
                _getGrowthInside(
                    params.tickLower,
                    params.tickUpper,
                    params.tickCurrent,
                    params.feeGrowthGlobalX128.toInt256(),
                    lower.feeGrowthOutsideX128.toInt256(),
                    upper.feeGrowthOutsideX128.toInt256()
                )
            );
        }
    }

    struct VariableTokenGrowthInsideParams {
        int24 tickLower;
        int24 tickUpper;
        int24 tickCurrent;
        int256 variableTokenGrowthGlobalX128;
    }

    function getVariableTokenGrowthInside(
        mapping(int24 => Tick.Info) storage self,
        VariableTokenGrowthInsideParams memory params
    ) internal view returns (int256 variableTokenGrowthInsideX128) {
        Info storage lower = self[params.tickLower];
        Info storage upper = self[params.tickUpper];

        variableTokenGrowthInsideX128 = _getGrowthInside(
            params.tickLower,
            params.tickUpper,
            params.tickCurrent,
            params.variableTokenGrowthGlobalX128,
            lower.variableTokenGrowthOutsideX128,
            upper.variableTokenGrowthOutsideX128
        );
    }

    struct FixedTokenGrowthInsideParams {
        int24 tickLower;
        int24 tickUpper;
        int24 tickCurrent;
        int256 fixedTokenGrowthGlobalX128;
    }

    function getFixedTokenGrowthInside(
        mapping(int24 => Tick.Info) storage self,
        FixedTokenGrowthInsideParams memory params
    ) internal view returns (int256 fixedTokenGrowthInsideX128) {
        Info storage lower = self[params.tickLower];
        Info storage upper = self[params.tickUpper];

        // do we need an unchecked block in here (given we are dealing with an int256)?
        fixedTokenGrowthInsideX128 = _getGrowthInside(
            params.tickLower,
            params.tickUpper,
            params.tickCurrent,
            params.fixedTokenGrowthGlobalX128,
            lower.fixedTokenGrowthOutsideX128,
            upper.fixedTokenGrowthOutsideX128
        );
    }

    /// @notice Updates a tick and returns true if the tick was flipped from initialized to uninitialized, or vice versa
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The tick that will be updated
    /// @param tickCurrent The current tick
    /// @param liquidityDelta A new amount of liquidity to be added (subtracted) when tick is crossed from left to right (right to left)
    /// @param fixedTokenGrowthGlobalX128 The fixed token growth accumulated per unit of liquidity for the entire life of the vamm
    /// @param variableTokenGrowthGlobalX128 The variable token growth accumulated per unit of liquidity for the entire life of the vamm
    /// @param upper true for updating a position's upper tick, or false for updating a position's lower tick
    /// @param maxLiquidity The maximum liquidity allocation for a single tick
    /// @return flipped Whether the tick was flipped from initialized to uninitialized, or vice versa
    function update(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        int24 tickCurrent,
        int128 liquidityDelta,
        int256 fixedTokenGrowthGlobalX128,
        int256 variableTokenGrowthGlobalX128,
        uint256 feeGrowthGlobalX128,
        bool upper,
        uint128 maxLiquidity
    ) internal returns (bool flipped) {
        Tick.Info storage info = self[tick];

        uint128 liquidityGrossBefore = info.liquidityGross;
        require(
            int128(info.liquidityGross) + liquidityDelta >= 0,
            "not enough liquidity to burn"
        );
        uint128 liquidityGrossAfter = LiquidityMath.addDelta(
            liquidityGrossBefore,
            liquidityDelta
        );

        require(liquidityGrossAfter <= maxLiquidity, "LO");

        flipped = (liquidityGrossAfter == 0) != (liquidityGrossBefore == 0);

        if (liquidityGrossBefore == 0) {
            // by convention, we assume that all growth before a tick was initialized happened _below_ the tick
            if (tick <= tickCurrent) {
                info.feeGrowthOutsideX128 = feeGrowthGlobalX128;

                info.fixedTokenGrowthOutsideX128 = fixedTokenGrowthGlobalX128;

                info
                    .variableTokenGrowthOutsideX128 = variableTokenGrowthGlobalX128;
            }

            info.initialized = true;
        }

        /// check shouldn't we unintialize the tick if liquidityGrossAfter = 0?

        info.liquidityGross = liquidityGrossAfter;

        /// add comments
        // when the lower (upper) tick is crossed left to right (right to left), liquidity must be added (removed)
        info.liquidityNet = upper
            ? info.liquidityNet - liquidityDelta
            : info.liquidityNet + liquidityDelta;
    }

    /// @notice Clears tick data
    /// @param self The mapping containing all initialized tick information for initialized ticks
    /// @param tick The tick that will be cleared
    function clear(mapping(int24 => Tick.Info) storage self, int24 tick)
        internal
    {
        delete self[tick];
    }

    /// @notice Transitions to next tick as needed by price movement
    /// @param self The mapping containing all tick information for initialized ticks
    /// @param tick The destination tick of the transition
    /// @param fixedTokenGrowthGlobalX128 The fixed token growth accumulated per unit of liquidity for the entire life of the vamm
    /// @param variableTokenGrowthGlobalX128 The variable token growth accumulated per unit of liquidity for the entire life of the vamm
    /// @param feeGrowthGlobalX128 The fee growth collected per unit of liquidity for the entire life of the vamm
    /// @return liquidityNet The amount of liquidity added (subtracted) when tick is crossed from left to right (right to left)
    function cross(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        int256 fixedTokenGrowthGlobalX128,
        int256 variableTokenGrowthGlobalX128,
        uint256 feeGrowthGlobalX128
    ) internal returns (int128 liquidityNet) {
        Tick.Info storage info = self[tick];

        info.feeGrowthOutsideX128 =
            feeGrowthGlobalX128 -
            info.feeGrowthOutsideX128;

        info.fixedTokenGrowthOutsideX128 =
            fixedTokenGrowthGlobalX128 -
            info.fixedTokenGrowthOutsideX128;

        info.variableTokenGrowthOutsideX128 =
            variableTokenGrowthGlobalX128 -
            info.variableTokenGrowthOutsideX128;

        liquidityNet = info.liquidityNet;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;
import "prb-math/contracts/PRBMathSD59x18.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";
import "./Time.sol";

/// @title A utility library for mathematics of fixed and variable token amounts.
library FixedAndVariableMath {
    using PRBMathSD59x18 for int256;
    using PRBMathUD60x18 for uint256;

    /// @notice Number of wei-seconds in a year
    /// @dev Ignoring leap years since we're only using it to calculate the eventual APY rate

    uint256 public constant SECONDS_IN_YEAR_IN_WAD = 31536000e18;
    uint256 public constant ONE_HUNDRED_IN_WAD = 100e18;

    /// @notice Caclulate the remaining cashflow to settle a position
    /// @param fixedTokenBalance The current balance of the fixed side of the position
    /// @param variableTokenBalance The current balance of the variable side of the position
    /// @param termStartTimestampWad When did the position begin, in seconds
    /// @param termEndTimestampWad When does the position reach maturity, in seconds
    /// @param variableFactorToMaturityWad What factor expresses the current remaining variable rate, up to position maturity? (in WAD)
    /// @return cashflow The remaining cashflow of the position
    function calculateSettlementCashflow(
        int256 fixedTokenBalance,
        int256 variableTokenBalance,
        uint256 termStartTimestampWad,
        uint256 termEndTimestampWad,
        uint256 variableFactorToMaturityWad
    ) internal view returns (int256 cashflow) {
        /// @dev convert fixed and variable token balances to their respective fixed token representations

        int256 fixedTokenBalanceWad = fixedTokenBalance.fromInt();
        int256 variableTokenBalanceWad = variableTokenBalance.fromInt();
        int256 fixedCashflowWad = fixedTokenBalanceWad.mul(
            int256(
                fixedFactor(true, termStartTimestampWad, termEndTimestampWad)
            )
        );

        int256 variableCashflowWad = variableTokenBalanceWad.mul(
            int256(variableFactorToMaturityWad)
        );

        int256 cashflowWad = fixedCashflowWad + variableCashflowWad;

        /// @dev convert back to non-fixed point representation
        cashflow = cashflowWad.toInt();
    }

    /// @notice Divide a given time in seconds by the number of seconds in a year
    /// @param timeInSecondsAsWad A time in seconds in Wad (i.e. scaled up by 10^18)
    /// @return timeInYearsWad An annualised factor of timeInSeconds, also in Wad
    function accrualFact(uint256 timeInSecondsAsWad)
        internal
        pure
        returns (uint256 timeInYearsWad)
    {
        timeInYearsWad = timeInSecondsAsWad.div(SECONDS_IN_YEAR_IN_WAD);
    }

    /// @notice Calculate the fixed factor for a position - that is, the percentage earned over
    /// the specified period of time, assuming 1% per year
    /// @param atMaturity Whether to calculate the factor at maturity (true), or now (false)
    /// @param termStartTimestampWad When does the period of time begin, in wei-seconds
    /// @param termEndTimestampWad When does the period of time end, in wei-seconds
    /// @return fixedFactorValueWad The fixed factor for the position (in Wad)
    function fixedFactor(
        bool atMaturity,
        uint256 termStartTimestampWad,
        uint256 termEndTimestampWad
    ) internal view returns (uint256 fixedFactorValueWad) {
        require(termEndTimestampWad > termStartTimestampWad, "E<=S");

        uint256 currentTimestampWad = Time.blockTimestampScaled();

        require(currentTimestampWad >= termStartTimestampWad, "B.T<S");

        uint256 timeInSecondsWad;

        if (atMaturity || (currentTimestampWad >= termEndTimestampWad)) {
            timeInSecondsWad = termEndTimestampWad - termStartTimestampWad;
        } else {
            timeInSecondsWad = currentTimestampWad - termStartTimestampWad;
        }

        uint256 timeInYearsWad = accrualFact(timeInSecondsWad);
        fixedFactorValueWad = timeInYearsWad.div(ONE_HUNDRED_IN_WAD);
    }

    /// @notice Calculate the fixed token balance for a position over a timespan
    /// @param amountFixedWad  A fixed amount
    /// @param excessBalanceWad Cashflows accrued to the fixed and variable token amounts since the inception of the IRS AMM
    /// @param termStartTimestampWad When does the period of time begin, in wei-seconds
    /// @param termEndTimestampWad When does the period of time end, in wei-seconds
    /// @return fixedTokenBalanceWad The fixed token balance for that time period
    function calculateFixedTokenBalance(
        int256 amountFixedWad,
        int256 excessBalanceWad,
        uint256 termStartTimestampWad,
        uint256 termEndTimestampWad
    ) internal view returns (int256 fixedTokenBalanceWad) {
        require(termEndTimestampWad > termStartTimestampWad, "E<=S");

        return
            amountFixedWad -
            excessBalanceWad.div(
                int256(
                    fixedFactor(
                        true,
                        termStartTimestampWad,
                        termEndTimestampWad
                    )
                )
            );
    }

    /// @notice Calculate the excess balance of both sides of a position in Wad
    /// @param amountFixedWad A fixed balance
    /// @param amountVariableWad A variable balance
    /// @param accruedVariableFactorWad An annualised factor in wei-years
    /// @param termStartTimestampWad When does the period of time begin, in wei-seconds
    /// @param termEndTimestampWad When does the period of time end, in wei-seconds
    /// @return excessBalanceWad The excess balance in wad
    function getExcessBalance(
        int256 amountFixedWad,
        int256 amountVariableWad,
        uint256 accruedVariableFactorWad,
        uint256 termStartTimestampWad,
        uint256 termEndTimestampWad
    ) internal view returns (int256) {
        int256 excessFixedAccruedBalanceWad;
        int256 excessVariableAccruedBalanceWad;
        int256 excessBalanceWad;

        excessFixedAccruedBalanceWad = amountFixedWad.mul(
            int256(
                fixedFactor(false, termStartTimestampWad, termEndTimestampWad)
            )
        );

        excessVariableAccruedBalanceWad = amountVariableWad.mul(
            int256(accruedVariableFactorWad)
        );

        /// @dev cashflows accrued since the inception of the IRS AMM

        excessBalanceWad =
            excessFixedAccruedBalanceWad +
            excessVariableAccruedBalanceWad;

        return excessBalanceWad;
    }

    /// @notice Calculate the fixed token balance given both fixed and variable balances
    /// @param amountFixed A fixed balance
    /// @param amountVariable A variable balance
    /// @param accruedVariableFactorWad An annualised factor in wei-years
    /// @param termStartTimestampWad When does the period of time begin, in wei-seconds
    /// @param termEndTimestampWad When does the period of time end, in wei-seconds
    /// @return fixedTokenBalance The fixed token balance for that time period
    function getFixedTokenBalance(
        int256 amountFixed,
        int256 amountVariable,
        uint256 accruedVariableFactorWad,
        uint256 termStartTimestampWad,
        uint256 termEndTimestampWad
    ) internal view returns (int256 fixedTokenBalance) {
        require(termEndTimestampWad > termStartTimestampWad, "E<=S");

        if (amountFixed == 0 && amountVariable == 0) return 0;

        int256 amountFixedWad = amountFixed.fromInt();
        int256 amountVariableWad = amountVariable.fromInt();

        int256 excessBalanceWad = getExcessBalance(
            amountFixedWad,
            amountVariableWad,
            accruedVariableFactorWad,
            termStartTimestampWad,
            termEndTimestampWad
        );

        int256 fixedTokenBalanceWad = calculateFixedTokenBalance(
            amountFixedWad,
            excessBalanceWad,
            termStartTimestampWad,
            termEndTimestampWad
        );

        fixedTokenBalance = fixedTokenBalanceWad.toInt();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.9;

interface IPositionStructs {
    struct ModifyPositionParams {
        // the address that owns the position
        address owner;
        // the lower and upper tick of the position
        int24 tickLower;
        int24 tickUpper;
        // any change in liquidity
        int128 liquidityDelta;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.9;

import "../utils/LiquidityMath.sol";
import "../utils/FixedPoint128.sol";
import "../core_libraries/Tick.sol";
import "../utils/FullMath.sol";
import "prb-math/contracts/PRBMathSD59x18.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @title Position
/// @notice Positions represent an owner address' liquidity between a lower and upper tick boundary
/// @dev Positions store additional state for tracking fees owed to the position as well as their fixed and variable token balances
library Position {
    using Position for Info;
    using SafeCast for uint256;
    using SafeCast for int256;

    // info stored for each user's position
    struct Info {
        // has the position been already burned
        // a burned position can no longer support new IRS contracts but still needs to cover settlement cash-flows of on-going IRS contracts it entered
        // bool isBurned;, equivalent to having zero liquidity
        // is position settled
        bool isSettled;
        // the amount of liquidity owned by this position
        uint128 _liquidity;
        // current margin of the position in terms of the underlyingToken
        int256 margin;
        // fixed token growth per unit of liquidity as of the last update to liquidity or fixed/variable token balance
        int256 fixedTokenGrowthInsideLastX128;
        // variable token growth per unit of liquidity as of the last update to liquidity or fixed/variable token balance
        int256 variableTokenGrowthInsideLastX128;
        // current Fixed Token balance of the position, 1 fixed token can be redeemed for 1% APY * (annualised amm term) at the maturity of the amm
        // assuming 1 token worth of notional "deposited" in the underlying pool at the inception of the amm
        // can be negative/positive/zero
        int256 fixedTokenBalance;
        // current Variable Token Balance of the position, 1 variable token can be redeemed for underlyingPoolAPY*(annualised amm term) at the maturity of the amm
        // assuming 1 token worth of notional "deposited" in the underlying pool at the inception of the amm
        // can be negative/positive/zero
        int256 variableTokenBalance;
        // fee growth per unit of liquidity as of the last update to liquidity or fees owed (via the margin)
        uint256 feeGrowthInsideLastX128;
        // amount of variable tokens at the initiation of liquidity
        uint256 rewardPerAmount;
        // amount of fees accumulated
        uint256 accumulatedFees;
    }

    /// @notice Returns the Info struct of a position, given an owner and position boundaries
    /// @param self The mapping containing all user positions
    /// @param owner The address of the position owner
    /// @param tickLower The lower tick boundary of the position
    /// @param tickUpper The upper tick boundary of the position
    /// @return position The position info struct of the given owners' position
    function get(
        mapping(bytes32 => Info) storage self,
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (Position.Info storage position) {
        Tick.checkTicks(tickLower, tickUpper);

        position = self[
            keccak256(abi.encodePacked(owner, tickLower, tickUpper))
        ];
    }

    function settlePosition(Info storage self) internal {
        require(!self.isSettled, "already settled");
        self.isSettled = true;
    }

    /// @notice Updates the Info struct of a position by changing the amount of margin according to marginDelta
    /// @param self Position Info Struct of the Liquidity Provider
    /// @param marginDelta Change in the margin account of the position (in wei)
    function updateMarginViaDelta(Info storage self, int256 marginDelta)
        internal
    {
        self.margin += marginDelta;
    }

    /// @notice Updates the Info struct of a position by changing the fixed and variable token balances of the position
    /// @param self Position Info struct of the liquidity provider
    /// @param fixedTokenBalanceDelta Change in the number of fixed tokens in the position's fixed token balance
    /// @param variableTokenBalanceDelta Change in the number of variable tokens in the position's variable token balance
    function updateBalancesViaDeltas(
        Info storage self,
        int256 fixedTokenBalanceDelta,
        int256 variableTokenBalanceDelta
    ) internal {
        if (fixedTokenBalanceDelta | variableTokenBalanceDelta != 0) {
            self.fixedTokenBalance += fixedTokenBalanceDelta;
            self.variableTokenBalance += variableTokenBalanceDelta;
        }
    }

    /// @notice Returns Fee Delta = (feeGrowthInside-feeGrowthInsideLast) * liquidity of the position
    /// @param self position info struct represeting a liquidity provider
    /// @param feeGrowthInsideX128 fee growth per unit of liquidity as of now
    /// @return _feeDelta Fee Delta
    function calculateFeeDelta(Info storage self, uint256 feeGrowthInsideX128)
        internal
        pure
        returns (uint256 _feeDelta)
    {
        Info memory _self = self;

        /// @dev 0xZenus: The multiplication overflows, need to wrap the below expression in an unchecked block.
        unchecked {
            _feeDelta = FullMath.mulDiv(
                feeGrowthInsideX128 - _self.feeGrowthInsideLastX128,
                _self._liquidity,
                FixedPoint128.Q128
            );
        }
    }

    /// @notice Returns Fixed and Variable Token Deltas
    /// @param self position info struct represeting a liquidity provider
    /// @param fixedTokenGrowthInsideX128 fixed token growth per unit of liquidity as of now (in wei)
    /// @param variableTokenGrowthInsideX128 variable token growth per unit of liquidity as of now (in wei)
    /// @return _fixedTokenDelta = (fixedTokenGrowthInside-fixedTokenGrowthInsideLast) * liquidity of a position
    /// @return _variableTokenDelta = (variableTokenGrowthInside-variableTokenGrowthInsideLast) * liquidity of a position
    function calculateFixedAndVariableDelta(
        Info storage self,
        int256 fixedTokenGrowthInsideX128,
        int256 variableTokenGrowthInsideX128
    )
        internal
        pure
        returns (int256 _fixedTokenDelta, int256 _variableTokenDelta)
    {
        Info memory _self = self;

        int256 fixedTokenGrowthInsideDeltaX128 = fixedTokenGrowthInsideX128 -
            _self.fixedTokenGrowthInsideLastX128;

        _fixedTokenDelta = FullMath.mulDivSigned(
            fixedTokenGrowthInsideDeltaX128,
            _self._liquidity,
            FixedPoint128.Q128
        );

        int256 variableTokenGrowthInsideDeltaX128 = variableTokenGrowthInsideX128 -
                _self.variableTokenGrowthInsideLastX128;

        _variableTokenDelta = FullMath.mulDivSigned(
            variableTokenGrowthInsideDeltaX128,
            _self._liquidity,
            FixedPoint128.Q128
        );
    }

    /// @notice Updates fixedTokenGrowthInsideLast and variableTokenGrowthInsideLast to the current values
    /// @param self position info struct represeting a liquidity provider
    /// @param fixedTokenGrowthInsideX128 fixed token growth per unit of liquidity as of now
    /// @param variableTokenGrowthInsideX128 variable token growth per unit of liquidity as of now
    function updateFixedAndVariableTokenGrowthInside(
        Info storage self,
        int256 fixedTokenGrowthInsideX128,
        int256 variableTokenGrowthInsideX128
    ) internal {
        self.fixedTokenGrowthInsideLastX128 = fixedTokenGrowthInsideX128;
        self.variableTokenGrowthInsideLastX128 = variableTokenGrowthInsideX128;
    }

    /// @notice Updates feeGrowthInsideLast to the current value
    /// @param self position info struct represeting a liquidity provider
    /// @param feeGrowthInsideX128 fee growth per unit of liquidity as of now
    function updateFeeGrowthInside(
        Info storage self,
        uint256 feeGrowthInsideX128
    ) internal {
        self.feeGrowthInsideLastX128 = feeGrowthInsideX128;
    }

    /// @notice Updates position's liqudity following either mint or a burn
    /// @param self The individual position to update
    /// @param liquidityDelta The change in pool liquidity as a result of the position update
    function updateLiquidity(Info storage self, int128 liquidityDelta)
        internal
    {
        Info memory _self = self;

        if (liquidityDelta == 0) {
            require(_self._liquidity > 0, "NP"); // disallow pokes for 0 liquidity positions
        } else {
            self._liquidity = LiquidityMath.addDelta(
                _self._liquidity,
                liquidityDelta
            );
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

import "contracts/utils/CustomErrors.sol";

pragma solidity =0.8.9;

import "contracts/utils/CustomErrors.sol";
import "../IERC20Minimal.sol";

/// @dev The RateOracle is used for two purposes on the Voltz Protocol
/// @dev Settlement: in order to be able to settle IRS positions after the termEndTimestamp of a given AMM
/// @dev Margin Engine Computations: getApyFromTo is used by the MarginCalculator and MarginEngine
/// @dev It is necessary to produce margin requirements for Trader and Liquidity Providers
interface IRateOracle is CustomErrors {

    // events
    event MinSecondsSinceLastUpdate(uint256 _minSecondsSinceLastUpdate);
    event OracleBufferUpdate(
        uint256 blockTimestampScaled,
        address source,
        uint16 index,
        uint32 blockTimestamp,
        uint256 observedValue,
        uint16 cardinality,
        uint16 cardinalityNext
    );

    /// @notice Emitted by the rate oracle for increases to the number of observations that can be stored
    /// @param observationCardinalityNextNew The updated value of the next observation cardinality
    event RateCardinalityNext(
        uint16 observationCardinalityNextNew
    );

    // view functions

    /// @notice Gets minimum number of seconds that need to pass since the last update to the rates array
    /// @dev This is a throttling mechanic that needs to ensure we don't run out of space in the rates array
    /// @dev The maximum size of the rates array is 65535 entries
    // AB: as long as this doesn't affect the termEndTimestamp rateValue too much
    // AB: can have a different minSecondsSinceLastUpdate close to termEndTimestamp to have more granularity for settlement purposes
    /// @return minSecondsSinceLastUpdate in seconds
    function minSecondsSinceLastUpdate() external view returns (uint256);

    /// @notice Gets the address of the underlying token of the RateOracle
    /// @return underlying The address of the underlying token
    function underlying() external view returns (IERC20Minimal);

    /// @notice Gets the variable factor between termStartTimestamp and termEndTimestamp
    /// @return result The variable factor
    /// @dev If the current block timestamp is beyond the maturity of the AMM, then the variableFactor is getRateFromTo(termStartTimestamp, termEndTimestamp). Term end timestamps are cached for quick retrieval later.
    /// @dev If the current block timestamp is before the maturity of the AMM, then the variableFactor is getRateFromTo(termStartTimestamp,Time.blockTimestampScaled());
    /// @dev if queried before maturity then returns the rate of return between pool initiation and current timestamp (in wad)
    /// @dev if queried after maturity then returns the rate of return between pool initiation and maturity timestamp (in wad)
    function variableFactor(uint256 termStartTimestamp, uint256 termEndTimestamp) external returns(uint256 result);

    /// @notice Gets the variable factor between termStartTimestamp and termEndTimestamp
    /// @return result The variable factor
    /// @dev If the current block timestamp is beyond the maturity of the AMM, then the variableFactor is getRateFromTo(termStartTimestamp, termEndTimestamp). No caching takes place.
    /// @dev If the current block timestamp is before the maturity of the AMM, then the variableFactor is getRateFromTo(termStartTimestamp,Time.blockTimestampScaled());
    function variableFactorNoCache(uint256 termStartTimestamp, uint256 termEndTimestamp) external view returns(uint256 result);

    
    /// @notice Calculates the observed interest returned by the underlying in a given period
    /// @dev Reverts if we have no data point for either timestamp
    /// @param from The timestamp of the start of the period, in seconds
    /// @param to The timestamp of the end of the period, in seconds
    /// @return The "floating rate" expressed in Wad, e.g. 4% is encoded as 0.04*10**18 = 4*10*16
    function getRateFromTo(uint256 from, uint256 to)
        external
        view
        returns (uint256);

    /// @notice Calculates the observed APY returned by the rate oracle in a given period
    /// @param from The timestamp of the start of the period, in seconds
    /// @param to The timestamp of the end of the period, in seconds
    /// @dev Reverts if we have no data point for either timestamp
    //  how is the returned rate encoded? Floating rate?
    function getApyFromTo(uint256 from, uint256 to)
        external
        view
        returns (uint256 apyFromTo);

    // non-view functions

    /// @notice Sets minSecondsSinceLastUpdate: The minimum number of seconds that need to pass since the last update to the rates array
    /// @dev Can only be set by the Factory Owner
    function setMinSecondsSinceLastUpdate(uint256 _minSecondsSinceLastUpdate) external;

    /// @notice Increase the maximum number of rates observations that this RateOracle will store
    /// @dev This method is no-op if the RateOracle already has an observationCardinalityNext greater than or equal to
    /// the input observationCardinalityNext.
    /// @param rateCardinalityNext The desired minimum number of observations for the pool to store
    function increaseObservationCardinalityNext(uint16 rateCardinalityNext) external;

    /// @notice Writes a rate observation to the rates array given the current rate cardinality, rate index and rate cardinality next
    /// Write oracle entry is called whenever a new position is minted via the vamm or when a swap is initiated via the vamm
    /// That way the gas costs of Rate Oracle updates can be distributed across organic interactions with the protocol
    function writeOracleEntry() external;

    /// @notice unique ID of the underlying yield bearing protocol (e.g. Aave v2 has id 1)
    /// @return yieldBearingProtocolID unique id of the underlying yield bearing protocol
    function UNDERLYING_YIELD_BEARING_PROTOCOL_ID() external view returns(uint8 yieldBearingProtocolID);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../IMarginEngine.sol";
import "../../utils/CustomErrors.sol";
import "../IERC20Minimal.sol";
import "../../core_libraries/TraderWithYieldBearingAssets.sol";

interface IFCM is CustomErrors {
    function getTraderWithYieldBearingAssets(address trader)
        external
        view
        returns (TraderWithYieldBearingAssets.Info memory traderInfo);

    /// @notice Initiate a Fully Collateralised Fixed Taker Swap
    /// @param notional amount of notional (in terms of the underlying token) to trade
    /// @param sqrtPriceLimitX96 the sqrtPriceLimit (in binary fixed point math notation) beyond which swaps won't be executed
    /// @dev An example of an initiated fully collateralised fixed taker swap is a scenario where a trader with 100 aTokens wishes to get a fixed return on them
    /// @dev they can choose to deposit their 100aTokens into the FCM (enter into a fixed taker position with a notional of 100) to swap variable cashflows from the aTokens
    /// @dev with the fixed cashflows from the variable takers
    function initiateFullyCollateralisedFixedTakerSwap(
        uint256 notional,
        uint160 sqrtPriceLimitX96
    ) external returns (int256 fixedTokenDelta, int256 variableTokenDelta, uint256 cumulativeFeeIncurred, int256 fixedTokenDeltaUnbalanced);

    /// @notice Unwind a Fully Collateralised Fixed Taker Swap
    /// @param notionalToUnwind The amount of notional of the original Fully Collateralised Fixed Taker swap to be unwound at the current VAMM fixed rates
    /// @param sqrtPriceLimitX96 the sqrtPriceLimit (in binary fixed point math notation) beyond which the unwind swaps won't be executed
    /// @dev The purpose of this function is to let fully collateralised fixed takers to exist their swaps by entering into variable taker positions against the VAMM
    /// @dev thus effectively releasing the margin in yield bearing tokens from the fixed swap contract
    function unwindFullyCollateralisedFixedTakerSwap(
        uint256 notionalToUnwind,
        uint160 sqrtPriceLimitX96
    ) external returns (int256 fixedTokenDelta, int256 variableTokenDelta, uint256 cumulativeFeeIncurred, int256 fixedTokenDeltaUnbalanced);

    /// @notice Settle Trader
    /// @dev this function in the fcm let's traders settle with the MarginEngine based on their settlement cashflows which is a functon of their fixed and variable token balances
    function settleTrader() external returns (int256);

    /// @notice
    /// @param account address of the position owner from the MarginEngine who wishes to settle with the FCM in underlying tokens
    /// @param marginDeltaInUnderlyingTokens amount in terms of underlying tokens that needs to be settled with the trader from the MarginEngine
    function transferMarginToMarginEngineTrader(
        address account,
        uint256 marginDeltaInUnderlyingTokens
    ) external;

    /// @notice initialize is the constructor for the proxy instances of the FCM
    /// @dev "constructor" for proxy instances
    /// @dev in the initialize function we set the vamm and the margiEngine associated with the fcm
    /// @dev different FCM implementations are free to have different implementations for the initialisation logic
    function initialize(IVAMM __vamm, IMarginEngine __marginEngine)
        external;

    /// @notice Margine Engine linked to the Full Collateralisation Module
    /// @return marginEngine Margine Engine linked to the Full Collateralisation Module
    function marginEngine() external view returns (IMarginEngine);

    /// @notice VAMM linked to the Full Collateralisation Module
    /// @return VAMM linked to the Full Collateralisation Module
    function vamm() external view returns (IVAMM);

    /// @notice Rate Oracle linked to the Full Collateralisation Module
    /// @return Rate Oracle linked to the Full Collateralisation Module
    function rateOracle() external view returns (IRateOracle);

    event FullyCollateralisedSwap(
        address indexed trader,
        uint256 desiredNotional,
        uint160 sqrtPriceLimitX96,
        uint256 cumulativeFeeIncurred,
        int256 fixedTokenDelta,
        int256 variableTokenDelta,
        int256 fixedTokenDeltaUnbalanced
    );

    event FullyCollateralisedUnwind(
        address indexed trader,
        uint256 desiredNotional,
        uint160 sqrtPriceLimitX96,
        uint256 cumulativeFeeIncurred,
        int256 fixedTokenDelta,
        int256 variableTokenDelta,
        int256 fixedTokenDeltaUnbalanced
    );

    event fcmPositionSettlement(
        address indexed trader,
        int256 settlementCashflow
    );

    event FCMTraderUpdate(
        address indexed trader,
        uint256 marginInScaledYieldBearingTokens,
        int256 fixedTokenBalance,
        int256 variableTokenBalance
    );
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "contracts/utils/CustomErrors.sol";
import "./rate_oracles/IRateOracle.sol";
import "./IMarginEngine.sol";
import "./IVAMM.sol";
import "./fcms/IFCM.sol";
import "./IERC20Minimal.sol";
import "./IPeriphery.sol";

/// @title The interface for the Voltz AMM Factory
/// @notice The AMM Factory facilitates creation of Voltz AMMs
interface IFactory is CustomErrors {
    event IrsInstance(
        IERC20Minimal indexed underlyingToken,
        IRateOracle indexed rateOracle,
        uint256 termStartTimestampWad,
        uint256 termEndTimestampWad,
        int24 tickSpacing,
        IMarginEngine marginEngine,
        IVAMM vamm,
        IFCM fcm,
        uint8 yieldBearingProtocolID,
        uint8 underlyingTokenDecimals
    );

    event MasterFCM(IFCM masterFCMAddress, uint8 yieldBearingProtocolID);

    event Approval(
        address indexed owner,
        address indexed intAddress,
        bool indexed isApproved
    );

    event PeripheryUpdate(IPeriphery periphery);

    // view functions

    function isApproved(address _owner, address intAddress)
        external
        view
        returns (bool);

    function masterVAMM() external view returns (IVAMM);

    function masterMarginEngine() external view returns (IMarginEngine);

    function periphery() external view returns (IPeriphery);

    // settters

    function setApproval(address intAddress, bool allowIntegration) external;

    function setMasterFCM(IFCM masterFCM, uint8 yieldBearingProtocolID)
        external;

    function setMasterVAMM(IVAMM _masterVAMM) external;

    function setMasterMarginEngine(IMarginEngine _masterMarginEngine) external;

    function setPeriphery(IPeriphery _periphery) external;

    /// @notice Deploys the contracts required for a new Interest Rate Swap instance
    function deployIrsInstance(
        IERC20Minimal _underlyingToken,
        IRateOracle _rateOracle,
        uint256 _termStartTimestampWad,
        uint256 _termEndTimestampWad,
        int24 _tickSpacing
    )
        external
        returns (
            IMarginEngine marginEngineProxy,
            IVAMM vammProxy,
            IFCM fcmProxy
        );

    function masterFCMs(uint8 yieldBearingProtocolID)
        external
        view
        returns (IFCM masterFCM);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

interface CustomErrors {
    /// @dev No need to unwind a net zero position
    error PositionNetZero();

    error DebugError(uint256 x, uint256 y);

    /// @dev Cannot have less margin than the minimum requirement
    error MarginLessThanMinimum(int256 marginRequirement);

    /// @dev We can't withdraw more margin than we have
    error WithdrawalExceedsCurrentMargin();

    /// @dev Position must be settled after AMM has reached maturity
    error PositionNotSettled();

    /// The resulting margin does not meet minimum requirements
    error MarginRequirementNotMet(
        int256 marginRequirement,
        int24 tick,
        int256 fixedTokenDelta,
        int256 variableTokenDelta,
        uint256 cumulativeFeeIncurred,
        int256 fixedTokenDeltaUnbalanced
    );

    /// The position/trader needs to be below the liquidation threshold to be liquidated
    error CannotLiquidate();

    /// Only the position/trade owner can update the LP/Trader margin
    error OnlyOwnerCanUpdatePosition();

    error OnlyVAMM();

    error OnlyFCM();

    /// Margin delta must not equal zero
    error InvalidMarginDelta();

    /// Positions and Traders cannot be settled before the applicable interest rate swap has matured
    error CannotSettleBeforeMaturity();

    error closeToOrBeyondMaturity();

    /// @dev There are not enough funds available for the requested operation
    error NotEnoughFunds(uint256 requested, uint256 available);

    /// @dev The two values were expected to have oppostite sigs, but do not
    error ExpectedOppositeSigns(int256 amount0, int256 amount1);

    /// @dev Error which is reverted if the sqrt price of the vamm is non-zero before a vamm is initialized
    error ExpectedSqrtPriceZeroBeforeInit(uint160 sqrtPriceX96);

    /// @dev Error which ensures the liquidity delta is positive if a given LP wishes to mint further liquidity in the vamm
    error LiquidityDeltaMustBePositiveInMint(uint128 amount);

    /// @dev Error which ensures the liquidity delta is positive if a given LP wishes to burn liquidity in the vamm
    error LiquidityDeltaMustBePositiveInBurn(uint128 amount);

    /// @dev Error which ensures the amount of notional specified when initiating an IRS contract (via the swap function in the vamm) is non-zero
    error IRSNotionalAmountSpecifiedMustBeNonZero();

    /// @dev Error which ensures the VAMM is unlocked
    error CanOnlyTradeIfUnlocked(bool unlocked);

    /// @dev only the margin engine can run a certain function
    error OnlyMarginEngine();

    /// The resulting margin does not meet minimum requirements
    error MarginRequirementNotMetFCM(int256 marginRequirement);

    /// @dev getReserveNormalizedIncome() returned zero for underlying asset. Oracle only supports active Aave-V2 assets.
    error AavePoolGetReserveNormalizedIncomeReturnedZero();

    /// @dev ctoken.exchangeRateStored() returned zero for a given Compound ctoken. Oracle only supports active Compound assets.
    error CTokenExchangeRateReturnedZero();

    /// @dev currentTime < queriedTime
    error OOO();
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.9;

/// @title Math library for liquidity
library LiquidityMath {
    /// @notice Add a signed liquidity delta to liquidity and revert if it overflows or underflows
    /// @param x The liquidity before change
    /// @param y The delta by which liquidity should be changed
    /// @return z The liquidity delta
    function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
        if (y < 0) {
            uint128 yAbsolute;

            unchecked {
                yAbsolute = uint128(-y);
            }

            z = x - yAbsolute;
        } else {
            z = x + uint128(y);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.9;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
}

// SPDX-License-Identifier: MIT

// solhint-disable no-inline-assembly

pragma solidity =0.8.9;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv

    function mulDivSigned(
        int256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        if (a < 0) return -int256(mulDiv(uint256(-a), b, denominator));
        return int256(mulDiv(uint256(a), b, denominator));
    }

    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product

        unchecked {
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0, "Division by zero");
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1, "overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            // uint256 twos = -denominator & denominator;
            // https://ethereum.stackexchange.com/questions/96642/unary-operator-cannot-be-applied-to-type-uint256
            uint256 twos = (type(uint256).max - denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max, "overflow");
            result++;
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

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;
import "./FixedAndVariableMath.sol";

/// @title Trader
library TraderWithYieldBearingAssets {
    // info stored for each user's position
    struct Info {
        // For Aave v2 The scaled balance is the sum of all the updated stored balances in the
        // underlying token, divided by the reserve's liquidity index at the moment of the update
        //
        // For componund, the scaled balance is the sum of all the updated stored balances in the
        // underlying token, divided by the cToken exchange rate at the moment of the update.
        // This is simply the number of cTokens!
        uint256 marginInScaledYieldBearingTokens;
        int256 fixedTokenBalance;
        int256 variableTokenBalance;
        bool isSettled;
    }

    function updateMarginInScaledYieldBearingTokens(
        Info storage self,
        uint256 _marginInScaledYieldBearingTokens
    ) internal {
        self
            .marginInScaledYieldBearingTokens = _marginInScaledYieldBearingTokens;
    }

    function settleTrader(Info storage self) internal {
        require(!self.isSettled, "already settled");
        self.isSettled = true;
    }

    function updateBalancesViaDeltas(
        Info storage self,
        int256 fixedTokenBalanceDelta,
        int256 variableTokenBalanceDelta
    )
        internal
        returns (int256 _fixedTokenBalance, int256 _variableTokenBalance)
    {
        _fixedTokenBalance = self.fixedTokenBalance + fixedTokenBalanceDelta;
        _variableTokenBalance =
            self.variableTokenBalance +
            variableTokenBalanceDelta;

        self.fixedTokenBalance = _fixedTokenBalance;
        self.variableTokenBalance = _variableTokenBalance;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;
import "prb-math/contracts/PRBMathUD60x18.sol";

library Time {
    uint256 public constant SECONDS_IN_DAY_WAD = 86400e18;

    /// @notice Calculate block.timestamp to wei precision
    /// @return Current timestamp in wei-seconds (1/1e18)
    function blockTimestampScaled() internal view returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return PRBMathUD60x18.fromUint(block.timestamp);
    }

    /// @dev Returns the block timestamp truncated to 32 bits, checking for overflow.
    function blockTimestampTruncated() internal view returns (uint32) {
        return timestampAsUint32(block.timestamp);
    }

    function timestampAsUint32(uint256 _timestamp)
        internal
        pure
        returns (uint32 timestamp)
    {
        require((timestamp = uint32(_timestamp)) == _timestamp, "TSOFLOW");
    }

    function isCloseToMaturityOrBeyondMaturity(uint256 termEndTimestampWad)
        internal
        view
        returns (bool vammInactive)
    {
        return
            Time.blockTimestampScaled() + SECONDS_IN_DAY_WAD >=
            termEndTimestampWad;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.9;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.9;
import "./core_libraries/Tick.sol";
import "./storage/VAMMStorage.sol";
import "./interfaces/IVAMM.sol";
import "./interfaces/IPeriphery.sol";
import "./core_libraries/TickBitmap.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./utils/SqrtPriceMath.sol";
import "./core_libraries/SwapMath.sol";
import "./interfaces/rate_oracles/IRateOracle.sol";
import "./interfaces/IERC20Minimal.sol";
import "./interfaces/IFactory.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";
import "prb-math/contracts/PRBMathSD59x18.sol";
import "./core_libraries/FixedAndVariableMath.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./utils/FixedPoint128.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract VAMM is VAMMStorage, IVAMM, Initializable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {
  using SafeCast for uint256;
  using SafeCast for int256;
  using Tick for mapping(int24 => Tick.Info);
  using TickBitmap for mapping(int16 => uint256);

  /// @dev 0.02 = 2% is the max fee as proportion of notional scaled by time to maturity (in wei fixed point notation 0.02 -> 2 * 10^16)
  uint256 public constant MAX_FEE = 20000000000000000;

  /// @dev Mutually exclusive reentrancy protection into the vamm to/from a method. This method also prevents entrance
  /// to a function before the vamm is initialized. The reentrancy guard is required throughout the contract.
  modifier lock() {
    require(_unlocked, "LOK");
    _unlocked = false;
    _;
    _unlocked = true;
  }

  // https://ethereum.stackexchange.com/questions/68529/solidity-modifiers-in-library
  /// @dev Modifier that ensures new LP positions cannot be minted after one day before the maturity of the vamm
  /// @dev also ensures new swaps cannot be conducted after one day before maturity of the vamm
  modifier checkCurrentTimestampTermEndTimestampDelta() {
    if (Time.isCloseToMaturityOrBeyondMaturity(termEndTimestampWad)) {
      revert("closeToOrBeyondMaturity");
    }
    _;
  }

  modifier checkIsAlpha() {
    
    if (_isAlpha) {
      IPeriphery _periphery = _factory.periphery();
      require(msg.sender==address(_periphery), "periphery only");
    }

    _;
    
  }

  // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor () initializer {}

  /// @inheritdoc IVAMM
  function initialize(IMarginEngine __marginEngine, int24 __tickSpacing) external override initializer {

    require(address(__marginEngine) != address(0), "ME must be set");
    // tick spacing is capped at 16384 to prevent the situation where tickSpacing is so large that
    // TickBitmap#nextInitializedTickWithinOneWord overflows int24 container from a valid tick
    // 16384 ticks represents a >5x price change with ticks of 1 bips
    require(__tickSpacing > 0 && __tickSpacing < Tick.MAXIMUM_TICK_SPACING, "TSOOB");

    _marginEngine = __marginEngine;
    rateOracle = _marginEngine.rateOracle();
    _factory = IFactory(msg.sender);
    _tickSpacing = __tickSpacing;
    _maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(_tickSpacing);
    termStartTimestampWad = _marginEngine.termStartTimestampWad();
    termEndTimestampWad = _marginEngine.termEndTimestampWad();

    __Ownable_init();
    __Pausable_init();
    __UUPSUpgradeable_init();
  }

  // To authorize the owner to upgrade the contract we implement _authorizeUpgrade with the onlyOwner modifier.
  // ref: https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786
  function _authorizeUpgrade(address) internal override onlyOwner {}


  // GETTERS FOR STORAGE SLOTS
  // Not auto-generated by public variables in the storage contract, cos solidity doesn't support that for functions that implement an interface
  /// @inheritdoc IVAMM
  function feeWad() external view override returns (uint256) {
      return _feeWad;
  }
  /// @inheritdoc IVAMM
  function tickSpacing() external view override returns (int24) {
      return _tickSpacing;
  }
  /// @inheritdoc IVAMM
  function maxLiquidityPerTick() external view override returns (uint128) {
      return _maxLiquidityPerTick;
  }
  /// @inheritdoc IVAMM
  function feeGrowthGlobalX128() external view override returns (uint256) {
      return _feeGrowthGlobalX128;
  }
  /// @inheritdoc IVAMM
  function protocolFees() external view override returns (uint256) {
      return _protocolFees;
  }
  /// @inheritdoc IVAMM
  function fixedTokenGrowthGlobalX128() external view override returns (int256) {
      return _fixedTokenGrowthGlobalX128;
  }
  /// @inheritdoc IVAMM
  function variableTokenGrowthGlobalX128() external view override returns (int256) {
      return _variableTokenGrowthGlobalX128;
  }
  /// @inheritdoc IVAMM
  function liquidity() external view override returns (uint128) {
      return _liquidity;
  }
  /// @inheritdoc IVAMM
  function factory() external view override returns (IFactory) {
      return _factory;
  }
  /// @inheritdoc IVAMM
  function marginEngine() external view override returns (IMarginEngine) {
      return _marginEngine;
  }
  /// @inheritdoc IVAMM
  function ticks(int24 tick)
    external
    view
    override
    returns (Tick.Info memory) {
    return _ticks[tick];
  }
  /// @inheritdoc IVAMM
  function tickBitmap(int16 wordPosition) external view override returns (uint256) {
    return _tickBitmap[wordPosition];
  }
  /// @inheritdoc IVAMM
  function vammVars() external view override returns (VAMMVars memory) {
      return _vammVars;
  }

  /// @inheritdoc IVAMM
  function isAlpha() external view override returns (bool) {
    return _isAlpha;
  }

  /// @dev modifier that ensures the
  modifier onlyMarginEngine () {
    if (msg.sender != address(_marginEngine)) {
        revert CustomErrors.OnlyMarginEngine();
    }
    _;
  }

  function updateProtocolFees(uint256 protocolFeesCollected)
    external
    override
    onlyMarginEngine
  {
    if (_protocolFees < protocolFeesCollected) {
      revert CustomErrors.NotEnoughFunds(protocolFeesCollected, _protocolFees);
    }
    _protocolFees -= protocolFeesCollected;
  }

  /// @dev not locked because it initializes unlocked
  function initializeVAMM(uint160 sqrtPriceX96) external override {

    require(sqrtPriceX96 != 0, "zero input price");
    require((sqrtPriceX96 < TickMath.MAX_SQRT_RATIO) && (sqrtPriceX96 >= TickMath.MIN_SQRT_RATIO), "R"); 

    /// @dev initializeVAMM should only be callable given the initialize function was already executed
    /// @dev we can check if the initialize function was executed by making sure the address of the margin engine is non-zero since it is set in the initialize function
    require(address(_marginEngine) != address(0), "vamm not initialized");

    if (_vammVars.sqrtPriceX96 != 0)  {
      revert CustomErrors.ExpectedSqrtPriceZeroBeforeInit(_vammVars.sqrtPriceX96);
    }

    int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);

    _vammVars = VAMMVars({ sqrtPriceX96: sqrtPriceX96, tick: tick, feeProtocol: 0 });

    _unlocked = true;

    emit VAMMInitialization(sqrtPriceX96, tick);
  }

  function setFeeProtocol(uint8 feeProtocol) external override onlyOwner {
    require(feeProtocol == 0 || (feeProtocol >= 3 && feeProtocol <= 50), "PR range");
    require(_vammVars.feeProtocol != feeProtocol, "PF value already set");

    _vammVars.feeProtocol = feeProtocol;
    emit FeeProtocol(feeProtocol);
  }

  function setFee(uint256 newFeeWad) external override onlyOwner {
    require(newFeeWad >= 0 && newFeeWad <= MAX_FEE, "fee range");
    require(_feeWad != newFeeWad, "fee value already set");

    _feeWad = newFeeWad;
    emit Fee(_feeWad);
  }

  
  /// @inheritdoc IVAMM
  function setIsAlpha(bool __isAlpha) external override onlyOwner {

    require(_isAlpha != __isAlpha, "alpha state already set");
    _isAlpha = __isAlpha;
    emit IsAlpha(_isAlpha);

  }

  // todo: prevent burning directly via the vamm if in Alpha State
  function burn(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    uint128 amount
  ) external override checkIsAlpha whenNotPaused lock returns(int256 positionMarginRequirement) {

    /// @dev if msg.sender is the MarginEngine, it is a burn induced by a position liquidation

    if (amount <= 0) {
      revert CustomErrors.LiquidityDeltaMustBePositiveInBurn(amount);
    }

    require((msg.sender==recipient) || (msg.sender == address(_marginEngine)) || _factory.isApproved(recipient, msg.sender) , "MS or ME");

    positionMarginRequirement = updatePosition(
      ModifyPositionParams({
        owner: recipient,
        tickLower: tickLower,
        tickUpper: tickUpper,
        liquidityDelta: -int256(uint256(amount)).toInt128()
      })
    );

    emit Burn(msg.sender, recipient, tickLower, tickUpper, amount);
  }

  function flipTicks(ModifyPositionParams memory params)
    internal
    returns (bool flippedLower, bool flippedUpper)
  {

    Tick.checkTicks(params.tickLower, params.tickUpper);


    /// @dev isUpper = false
    flippedLower = _ticks.update(
      params.tickLower,
      _vammVars.tick,
      params.liquidityDelta,
      _fixedTokenGrowthGlobalX128,
      _variableTokenGrowthGlobalX128,
      _feeGrowthGlobalX128,
      false,
      _maxLiquidityPerTick
    );

    /// @dev isUpper = true
    flippedUpper = _ticks.update(
      params.tickUpper,
      _vammVars.tick,
      params.liquidityDelta,
      _fixedTokenGrowthGlobalX128,
      _variableTokenGrowthGlobalX128,
      _feeGrowthGlobalX128,
      true,
      _maxLiquidityPerTick
    );

    if (flippedLower) {
      _tickBitmap.flipTick(params.tickLower, _tickSpacing);
    }

    if (flippedUpper) {
      _tickBitmap.flipTick(params.tickUpper, _tickSpacing);
    }
  }


  function updatePosition(ModifyPositionParams memory params) private returns(int256 positionMarginRequirement) {

    /// @dev give a more descriptive name

    Tick.checkTicks(params.tickLower, params.tickUpper);

    VAMMVars memory lvammVars = _vammVars; // SLOAD for gas optimization

    bool flippedLower;
    bool flippedUpper;

    /// @dev update the ticks if necessary
    if (params.liquidityDelta != 0) {
      (flippedLower, flippedUpper) = flipTicks(params);
    }

    positionMarginRequirement = 0;
    if (msg.sender != address(_marginEngine)) {
      // this only happens if the margin engine triggers a liquidation which in turn triggers a burn
      // the state updated in the margin engine in that case are done directly in the liquidatePosition function
      positionMarginRequirement = _marginEngine.updatePositionPostVAMMInducedMintBurn(params);
    }

    // clear any tick data that is no longer needed
    if (params.liquidityDelta < 0) {
      if (flippedLower) {
        _ticks.clear(params.tickLower);
      }
      if (flippedUpper) {
        _ticks.clear(params.tickUpper);
      }
    }

    rateOracle.writeOracleEntry();

    if (params.liquidityDelta != 0) {
      if (
        (lvammVars.tick >= params.tickLower) && (lvammVars.tick < params.tickUpper)
      ) {
        // current tick is inside the passed range
        uint128 liquidityBefore = _liquidity; // SLOAD for gas optimization

        _liquidity = LiquidityMath.addDelta(
          liquidityBefore,
          params.liquidityDelta
        );
      }
    }
  }

  /// @inheritdoc IVAMM
  function mint(
    address recipient,
    int24 tickLower,
    int24 tickUpper,
    uint128 amount
  ) external override checkIsAlpha whenNotPaused checkCurrentTimestampTermEndTimestampDelta lock returns(int256 positionMarginRequirement) {
    
    /// might be helpful to have a higher level peripheral function for minting a given amount given a certain amount of notional an LP wants to support

    if (amount <= 0) {
      revert CustomErrors.LiquidityDeltaMustBePositiveInMint(amount);
    }

    require(msg.sender==recipient || _factory.isApproved(recipient, msg.sender), "only msg.sender or approved can mint");

    positionMarginRequirement = updatePosition(
      ModifyPositionParams({
        owner: recipient,
        tickLower: tickLower,
        tickUpper: tickUpper,
        liquidityDelta: int256(uint256(amount)).toInt128()
      })
    );

    emit Mint(msg.sender, recipient, tickLower, tickUpper, amount);
  }


  /// @inheritdoc IVAMM
  function swap(SwapParams memory params)
    external
    override
    whenNotPaused
    checkCurrentTimestampTermEndTimestampDelta
    returns (int256 fixedTokenDelta, int256 variableTokenDelta, uint256 cumulativeFeeIncurred, int256 fixedTokenDeltaUnbalanced, int256 marginRequirement)
  {

    Tick.checkTicks(params.tickLower, params.tickUpper);

    VAMMVars memory vammVarsStart = _vammVars;

    checksBeforeSwap(params, vammVarsStart, params.amountSpecified > 0);

    if (!(msg.sender == address(_marginEngine) || msg.sender==address(_marginEngine.fcm()))) {
      require(msg.sender==params.recipient || _factory.isApproved(params.recipient, msg.sender), "only sender or approved integration");
    }

    /// @dev lock the vamm while the swap is taking place
    _unlocked = false;

    SwapCache memory cache = SwapCache({
      liquidityStart: _liquidity,
      feeProtocol: _vammVars.feeProtocol
    });

    /// @dev amountSpecified = The amount of the swap, which implicitly configures the swap as exact input (positive), or exact output (negative)
    /// @dev Both FTs and VTs care about the notional of their IRS contract, the notional is the absolute amount of variableTokens traded
    /// @dev Hence, if an FT wishes to trade x notional, amountSpecified needs to be an exact input (in terms of the variableTokens they provide), hence amountSpecified needs to be positive
    /// @dev Also, if a VT wishes to trade x notional, amountSpecified needs to be an exact output (in terms of the variableTokens they receive), hence amountSpecified needs to be negative
    /// @dev amountCalculated is the amount already swapped out/in of the output (variable taker) / input (fixed taker) asset
    /// @dev amountSpecified should always be in terms of the variable tokens

    SwapState memory state = SwapState({
      amountSpecifiedRemaining: params.amountSpecified,
      amountCalculated: 0,
      sqrtPriceX96: vammVarsStart.sqrtPriceX96,
      tick: vammVarsStart.tick,
      liquidity: cache.liquidityStart,
      fixedTokenGrowthGlobalX128: _fixedTokenGrowthGlobalX128,
      variableTokenGrowthGlobalX128: _variableTokenGrowthGlobalX128,
      feeGrowthGlobalX128: _feeGrowthGlobalX128,
      protocolFee: 0,
      cumulativeFeeIncurred: 0,
      fixedTokenDeltaCumulative: 0, // for Trader (user invoking the swap)
      variableTokenDeltaCumulative: 0, // for Trader (user invoking the swap),
      fixedTokenDeltaUnbalancedCumulative: 0 //  for Trader (user invoking the swap)
    });

    /// @dev write an entry to the rate oracle (given no throttling)

    rateOracle.writeOracleEntry();

    // continue swapping as long as we haven't used the entire input/output and haven't reached the price (implied fixed rate) limit
    if (params.amountSpecified > 0) {
      // Fixed Taker
      while (
      state.amountSpecifiedRemaining != 0 &&
      state.sqrtPriceX96 != params.sqrtPriceLimitX96
    ) {
      StepComputations memory step;

      step.sqrtPriceStartX96 = state.sqrtPriceX96;

      /// the nextInitializedTick should be more than or equal to the current tick
      /// add a test for the statement that checks for the above two conditions
      (step.tickNext, step.initialized) = _tickBitmap
        .nextInitializedTickWithinOneWord(state.tick, _tickSpacing, false);

      // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
      if (step.tickNext > TickMath.MAX_TICK) {
        step.tickNext = TickMath.MAX_TICK;
      }

      // get the price for the next tick
      step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

      // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
      /// @dev for a Fixed Taker (isFT) if the sqrtPriceNextX96 is larger than the limit, then the target price passed into computeSwapStep is sqrtPriceLimitX96
      /// @dev for a Variable Taker (!isFT) if the sqrtPriceNextX96 is lower than the limit, then the target price passed into computeSwapStep is sqrtPriceLimitX96
      (
        state.sqrtPriceX96,
        step.amountIn,
        step.amountOut,
        step.feeAmount
      ) = SwapMath.computeSwapStep(
        SwapMath.SwapStepParams({
            sqrtRatioCurrentX96: state.sqrtPriceX96,
            sqrtRatioTargetX96: step.sqrtPriceNextX96 > params.sqrtPriceLimitX96
          ? params.sqrtPriceLimitX96
          : step.sqrtPriceNextX96,
            liquidity: state.liquidity,
            amountRemaining: state.amountSpecifiedRemaining,
            feePercentageWad: _feeWad,
            timeToMaturityInSecondsWad: termEndTimestampWad - Time.blockTimestampScaled()
        })
      );

      // exact input
      /// prb math is not used in here (following v3 logic)
      state.amountSpecifiedRemaining -= (step.amountIn).toInt256(); // this value is positive
      state.amountCalculated -= step.amountOut.toInt256(); // this value is negative

      // LP is a Variable Taker
      step.variableTokenDelta = (step.amountIn).toInt256();
      step.fixedTokenDeltaUnbalanced = -step.amountOut.toInt256();

      // update cumulative fee incurred while initiating an interest rate swap
      state.cumulativeFeeIncurred = state.cumulativeFeeIncurred + step.feeAmount;

      // if the protocol fee is on, calculate how much is owed, decrement feeAmount, and increment protocolFee
      if (cache.feeProtocol > 0) {
        /// here we should round towards protocol fees (+ ((step.feeAmount % cache.feeProtocol == 0) ? 0 : 1)) ?
        step.feeProtocolDelta = step.feeAmount / cache.feeProtocol;
        step.feeAmount -= step.feeProtocolDelta;
        state.protocolFee += step.feeProtocolDelta;
      }

      // update global fee tracker
      if (state.liquidity > 0) {
        (
          state.feeGrowthGlobalX128,
          state.variableTokenGrowthGlobalX128,
          state.fixedTokenGrowthGlobalX128,
          step.fixedTokenDelta // for LP
        ) = calculateUpdatedGlobalTrackerValues(
          state,
          step,
          rateOracle.variableFactor(
          termStartTimestampWad,
          termEndTimestampWad
          )
        );

        state.fixedTokenDeltaCumulative -= step.fixedTokenDelta; // opposite sign from that of the LP's
        state.variableTokenDeltaCumulative -= step.variableTokenDelta; // opposite sign from that of the LP's

        // necessary for testing purposes, also handy to quickly compute the fixed rate at which an interest rate swap is created
        state.fixedTokenDeltaUnbalancedCumulative -= step.fixedTokenDeltaUnbalanced;
      }

      // shift tick if we reached the next price
      if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
        // if the tick is initialized, run the tick transition
        if (step.initialized) {
          int128 liquidityNet = _ticks.cross(
            step.tickNext,
            state.fixedTokenGrowthGlobalX128,
            state.variableTokenGrowthGlobalX128,
            state.feeGrowthGlobalX128
          );

          state.liquidity = LiquidityMath.addDelta(
            state.liquidity,
            liquidityNet
          );

        }

        state.tick = step.tickNext;
      } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
        // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
        state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
      }
    }
    }
    else {
      while (
      state.amountSpecifiedRemaining != 0 &&
      state.sqrtPriceX96 != params.sqrtPriceLimitX96
    ) {
      StepComputations memory step;

      step.sqrtPriceStartX96 = state.sqrtPriceX96;

      /// @dev if isFT (fixed taker) (moving right to left), the nextInitializedTick should be more than or equal to the current tick
      /// @dev if !isFT (variable taker) (moving left to right), the nextInitializedTick should be less than or equal to the current tick
      /// add a test for the statement that checks for the above two conditions
      (step.tickNext, step.initialized) = _tickBitmap
        .nextInitializedTickWithinOneWord(state.tick, _tickSpacing, true);

      // ensure that we do not overshoot the min/max tick, as the tick bitmap is not aware of these bounds
      if (step.tickNext < TickMath.MIN_TICK) {
        step.tickNext = TickMath.MIN_TICK;
      }

      // get the price for the next tick
      step.sqrtPriceNextX96 = TickMath.getSqrtRatioAtTick(step.tickNext);

      // compute values to swap to the target tick, price limit, or point where input/output amount is exhausted
      /// @dev for a Fixed Taker (isFT) if the sqrtPriceNextX96 is larger than the limit, then the target price passed into computeSwapStep is sqrtPriceLimitX96
      /// @dev for a Variable Taker (!isFT) if the sqrtPriceNextX96 is lower than the limit, then the target price passed into computeSwapStep is sqrtPriceLimitX96
      (
        state.sqrtPriceX96,
        step.amountIn,
        step.amountOut,
        step.feeAmount
      ) = SwapMath.computeSwapStep(

        SwapMath.SwapStepParams({
            sqrtRatioCurrentX96: state.sqrtPriceX96,
            sqrtRatioTargetX96: step.sqrtPriceNextX96 < params.sqrtPriceLimitX96
          ? params.sqrtPriceLimitX96
          : step.sqrtPriceNextX96,
            liquidity: state.liquidity,
            amountRemaining: state.amountSpecifiedRemaining,
            feePercentageWad: _feeWad,
            timeToMaturityInSecondsWad: termEndTimestampWad - Time.blockTimestampScaled()
        })

      );

      /// prb math is not used in here (following v3 logic)
      state.amountSpecifiedRemaining += step.amountOut.toInt256(); // this value is negative
      state.amountCalculated += step.amountIn.toInt256(); // this value is positive

      // LP is a Fixed Taker
      step.variableTokenDelta = -step.amountOut.toInt256();
      step.fixedTokenDeltaUnbalanced = step.amountIn.toInt256();

      // update cumulative fee incurred while initiating an interest rate swap
      state.cumulativeFeeIncurred = state.cumulativeFeeIncurred + step.feeAmount;

      // if the protocol fee is on, calculate how much is owed, decrement feeAmount, and increment protocolFee
      if (cache.feeProtocol > 0) {
        /// here we should round towards protocol fees (+ ((step.feeAmount % cache.feeProtocol == 0) ? 0 : 1)) ?
        step.feeProtocolDelta = step.feeAmount / cache.feeProtocol;
        step.feeAmount -= step.feeProtocolDelta;
        state.protocolFee += step.feeProtocolDelta;
      }

      // update global fee tracker
      if (state.liquidity > 0) {
        (
          state.feeGrowthGlobalX128,
          state.variableTokenGrowthGlobalX128,
          state.fixedTokenGrowthGlobalX128,
          step.fixedTokenDelta // for LP
        ) = calculateUpdatedGlobalTrackerValues(
          state,
          step,
          rateOracle.variableFactor(
          termStartTimestampWad,
          termEndTimestampWad
          )
        );

        state.fixedTokenDeltaCumulative -= step.fixedTokenDelta; // opposite sign from that of the LP's
        state.variableTokenDeltaCumulative -= step.variableTokenDelta; // opposite sign from that of the LP's

        // necessary for testing purposes, also handy to quickly compute the fixed rate at which an interest rate swap is created
        state.fixedTokenDeltaUnbalancedCumulative -= step.fixedTokenDeltaUnbalanced;
      }

      // shift tick if we reached the next price
      if (state.sqrtPriceX96 == step.sqrtPriceNextX96) {
        // if the tick is initialized, run the tick transition
        if (step.initialized) {
          int128 liquidityNet = _ticks.cross(
            step.tickNext,
            state.fixedTokenGrowthGlobalX128,
            state.variableTokenGrowthGlobalX128,
            state.feeGrowthGlobalX128
          );

          state.liquidity = LiquidityMath.addDelta(
            state.liquidity,
            -liquidityNet
          );

        }

        state.tick = step.tickNext - 1;
      } else if (state.sqrtPriceX96 != step.sqrtPriceStartX96) {
        // recompute unless we're on a lower tick boundary (i.e. already transitioned ticks), and haven't moved
        state.tick = TickMath.getTickAtSqrtRatio(state.sqrtPriceX96);
      }
    }
    }
    _vammVars.sqrtPriceX96 = state.sqrtPriceX96;

    if (state.tick != vammVarsStart.tick) {
       // update the tick in case it changed
      _vammVars.tick = state.tick;
    }

    // update liquidity if it changed
    if (cache.liquidityStart != state.liquidity) _liquidity = state.liquidity;

    _feeGrowthGlobalX128 = state.feeGrowthGlobalX128;
    _variableTokenGrowthGlobalX128 = state.variableTokenGrowthGlobalX128;
    _fixedTokenGrowthGlobalX128 = state.fixedTokenGrowthGlobalX128;

    cumulativeFeeIncurred = state.cumulativeFeeIncurred;
    fixedTokenDelta = state.fixedTokenDeltaCumulative;
    variableTokenDelta = state.variableTokenDeltaCumulative;
    fixedTokenDeltaUnbalanced = state.fixedTokenDeltaUnbalancedCumulative;

    if (state.protocolFee > 0) {
      _protocolFees += state.protocolFee;
    }

    /// @dev if it is an unwind then state change happen direcly in the MarginEngine to avoid making an unnecessary external call
    if (!(msg.sender == address(_marginEngine) || msg.sender==address(_marginEngine.fcm()))) {
      marginRequirement = _marginEngine.updatePositionPostVAMMInducedSwap(params.recipient, params.tickLower, params.tickUpper, state.fixedTokenDeltaCumulative, state.variableTokenDeltaCumulative, state.cumulativeFeeIncurred, state.fixedTokenDeltaUnbalancedCumulative);
    }

    emit VAMMPriceChange(_vammVars.tick);

    emit Swap(
      msg.sender,
      params.recipient,
      params.tickLower,
      params.tickUpper,
      params.amountSpecified,
      params.sqrtPriceLimitX96,
      cumulativeFeeIncurred,
      fixedTokenDelta,
      variableTokenDelta,
      fixedTokenDeltaUnbalanced
    );

    _unlocked = true;
  }

  /// @inheritdoc IVAMM
  function computeGrowthInside(
    int24 tickLower,
    int24 tickUpper
  )
    external
    view
    override
    returns (int256 fixedTokenGrowthInsideX128, int256 variableTokenGrowthInsideX128, uint256 feeGrowthInsideX128)
  {

    Tick.checkTicks(tickLower, tickUpper);

    fixedTokenGrowthInsideX128 = _ticks.getFixedTokenGrowthInside(
      Tick.FixedTokenGrowthInsideParams({
        tickLower: tickLower,
        tickUpper: tickUpper,
        tickCurrent: _vammVars.tick,
        fixedTokenGrowthGlobalX128: _fixedTokenGrowthGlobalX128
      })
    );

    variableTokenGrowthInsideX128 = _ticks.getVariableTokenGrowthInside(
      Tick.VariableTokenGrowthInsideParams({
        tickLower: tickLower,
        tickUpper: tickUpper,
        tickCurrent: _vammVars.tick,
        variableTokenGrowthGlobalX128: _variableTokenGrowthGlobalX128
      })
    );

    feeGrowthInsideX128 = _ticks.getFeeGrowthInside(
      Tick.FeeGrowthInsideParams({
        tickLower: tickLower,
        tickUpper: tickUpper,
        tickCurrent: _vammVars.tick,
        feeGrowthGlobalX128: _feeGrowthGlobalX128
      })
    );

  }

  function checksBeforeSwap(
      SwapParams memory params,
      VAMMVars memory vammVarsStart,
      bool isFT
  ) internal view {

      if (params.amountSpecified == 0) {
          revert CustomErrors.IRSNotionalAmountSpecifiedMustBeNonZero();
      }

      if (!_unlocked) {
          revert CustomErrors.CanOnlyTradeIfUnlocked(_unlocked);
      }

      /// @dev if a trader is an FT, they consume fixed in return for variable
      /// @dev Movement from right to left along the VAMM, hence the sqrtPriceLimitX96 needs to be higher than the current sqrtPriceX96, but lower than the MAX_SQRT_RATIO
      /// @dev if a trader is a VT, they consume variable in return for fixed
      /// @dev Movement from left to right along the VAMM, hence the sqrtPriceLimitX96 needs to be lower than the current sqrtPriceX96, but higher than the MIN_SQRT_RATIO

      require(
          isFT
              ? params.sqrtPriceLimitX96 > vammVarsStart.sqrtPriceX96 &&
                  params.sqrtPriceLimitX96 < TickMath.MAX_SQRT_RATIO
              : params.sqrtPriceLimitX96 < vammVarsStart.sqrtPriceX96 &&
                  params.sqrtPriceLimitX96 > TickMath.MIN_SQRT_RATIO,
          "SPL"
      );
  }

    function calculateUpdatedGlobalTrackerValues(
        SwapState memory state,
        StepComputations memory step,
        uint256 variableFactorWad
    )
        internal
        view
        returns (
            uint256 stateFeeGrowthGlobalX128,
            int256 stateVariableTokenGrowthGlobalX128,
            int256 stateFixedTokenGrowthGlobalX128,
            int256 fixedTokenDelta// for LP
        )
    {

        stateFeeGrowthGlobalX128 = state.feeGrowthGlobalX128 + FullMath.mulDiv(step.feeAmount, FixedPoint128.Q128, state.liquidity);

        fixedTokenDelta = FixedAndVariableMath.getFixedTokenBalance(
          step.fixedTokenDeltaUnbalanced,
          step.variableTokenDelta,
          variableFactorWad,
          termStartTimestampWad,
          termEndTimestampWad
        );

        stateVariableTokenGrowthGlobalX128 = state.variableTokenGrowthGlobalX128 + FullMath.mulDivSigned(step.variableTokenDelta, FixedPoint128.Q128, state.liquidity);

        stateFixedTokenGrowthGlobalX128 = state.fixedTokenGrowthGlobalX128 + FullMath.mulDivSigned(fixedTokenDelta, FixedPoint128.Q128, state.liquidity);
    }

}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;
import "../interfaces/IVAMM.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/IMarginEngine.sol";
import "../core_libraries/Tick.sol";

contract VAMMStorageV1 {
    // cached rateOracle from the MarginEngine associated with the VAMM
    IRateOracle internal rateOracle;
    // cached termStartTimstampWad from the MarginEngine associated with the VAMM
    uint256 internal termStartTimestampWad;
    // cached termEndTimestampWad from the MarginEngine associated with the VAMM
    uint256 internal termEndTimestampWad;
    IMarginEngine internal _marginEngine;
    uint128 internal _maxLiquidityPerTick;
    IFactory internal _factory;

    // Any variables that would implicitly implement an IMarginEngine function if public, must instead
    // be internal due to limitations in the solidity compiler (as of 0.8.12)
    uint256 internal _feeWad;
    // Mutex
    bool internal _unlocked;
    uint128 internal _liquidity;
    uint256 internal _feeGrowthGlobalX128;
    uint256 internal _protocolFees;
    int256 internal _fixedTokenGrowthGlobalX128;
    int256 internal _variableTokenGrowthGlobalX128;
    int24 internal _tickSpacing;
    mapping(int24 => Tick.Info) internal _ticks;
    mapping(int16 => uint256) internal _tickBitmap;
    IVAMM.VAMMVars internal _vammVars;
    bool internal _isAlpha;
}

contract VAMMStorage is VAMMStorageV1 {
    // Reserve some storage for use in future versions, without creating conflicts
    // with other inheritted contracts
    uint256[50] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.9;

import "../utils/BitMath.sol";

/// @title Packed tick initialized state library
/// @notice Stores a packed mapping of tick index to its initialized state
/// @dev The mapping uses int16 for keys since ticks are represented as int24 and there are 256 (2^8) values per word.
library TickBitmap {
    /// @notice Computes the position in the mapping where the initialized bit for a tick lives
    /// @param tick The tick for which to compute the position
    /// @return wordPos The key in the mapping containing the word in which the bit is stored
    /// @return bitPos The bit position in the word where the flag is stored
    function position(int24 tick)
        private
        pure
        returns (int16 wordPos, uint8 bitPos)
    {
        wordPos = int16(tick >> 8);
        bitPos = uint8(int8(tick % 256));
    }

    /// @notice Flips the initialized state for a given tick from false to true, or vice versa
    /// @param self The mapping in which to flip the tick
    /// @param tick The tick to flip
    /// @param tickSpacing The spacing between usable ticks
    function flipTick(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing
    ) internal {
        require(tick % tickSpacing == 0, "tick must be properly spaced"); // ensure that the tick is spaced
        (int16 wordPos, uint8 bitPos) = position(tick / tickSpacing);
        uint256 mask = 1 << bitPos;
        self[wordPos] ^= mask;
    }

    /// @notice Returns the next initialized tick contained in the same word (or adjacent word) as the tick that is either
    /// to the left (less than or equal to) or right (greater than) of the given tick
    /// @param self The mapping in which to compute the next initialized tick
    /// @param tick The starting tick
    /// @param tickSpacing The spacing between usable ticks
    /// @param lte Whether to search for the next initialized tick to the left (less than or equal to the starting tick)
    /// @return next The next initialized or uninitialized tick up to 256 ticks away from the current tick
    /// @return initialized Whether the next tick is initialized, as the function only searches within up to 256 ticks
    function nextInitializedTickWithinOneWord(
        mapping(int16 => uint256) storage self,
        int24 tick,
        int24 tickSpacing,
        bool lte
    ) internal view returns (int24 next, bool initialized) {
        int24 compressed = tick / tickSpacing;
        if (tick < 0 && tick % tickSpacing != 0) compressed--; // round towards negative infinity

        if (lte) {
            (int16 wordPos, uint8 bitPos) = position(compressed);
            // all the 1s at or to the right of the current bitPos
            uint256 mask = (1 << bitPos) - 1 + (1 << bitPos);
            uint256 masked = self[wordPos] & mask;

            // if there are no initialized ticks to the right of or at the current tick, return rightmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed -
                    int24(
                        uint24(bitPos - BitMath.mostSignificantBit(masked))
                    )) * tickSpacing
                : (compressed - int24(uint24(bitPos))) * tickSpacing;
        } else {
            // start from the word of the next tick, since the current tick state doesn't matter
            (int16 wordPos, uint8 bitPos) = position(compressed + 1);
            // all the 1s at or to the left of the bitPos
            uint256 mask = ~((1 << bitPos) - 1);
            uint256 masked = self[wordPos] & mask;

            // if there are no initialized ticks to the left of the current tick, return leftmost in the word
            initialized = masked != 0;
            // overflow/underflow is possible, but prevented externally by limiting both tickSpacing and tick
            next = initialized
                ? (compressed +
                    1 +
                    int24(
                        uint24(BitMath.leastSignificantBit(masked) - bitPos)
                    )) * tickSpacing
                : (compressed + 1 + int24(uint24(type(uint8).max - bitPos))) *
                    tickSpacing;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.9;

import "./SafeCastUni.sol";

import "./FullMath.sol";
import "./UnsafeMath.sol";
import "./FixedPoint96.sol";

/// @title Functions based on Q64.96 sqrt price and liquidity
/// @notice Contains the math that uses square root of price as a Q64.96 and liquidity to compute deltas
library SqrtPriceMath {
    using SafeCastUni for uint256;

    /// @notice Gets the next sqrt price given a delta of token0
    /// @dev Always rounds up, because in the exact output case (increasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (decreasing price) we need to move the
    /// price less in order to not send too much output.
    /// The most precise formula for this is liquidity * sqrtPX96 / (liquidity +- amount * sqrtPX96),
    /// if this is impossible because of overflow, we calculate liquidity / (liquidity / sqrtPX96 +- amount).
    /// @param sqrtPX96 The starting price, i.e. before accounting for the token0 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token0 to add or remove from virtual reserves
    /// @param add Whether to add or remove the amount of token0
    /// @return The price after adding or removing amount, depending on add
    function getNextSqrtPriceFromAmount0RoundingUp(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // we short circuit amount == 0 because the result is otherwise not guaranteed to equal the input price
        if (amount == 0) return sqrtPX96;
        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;

        if (add) {
            uint256 product;
            if ((product = amount * sqrtPX96) / amount == sqrtPX96) {
                uint256 denominator = numerator1 + product;
                if (denominator >= numerator1)
                    // always fits in 160 bits
                    return
                        uint160(
                            FullMath.mulDivRoundingUp(
                                numerator1,
                                sqrtPX96,
                                denominator
                            )
                        );
            }

            return
                uint160(
                    UnsafeMath.divRoundingUp(
                        numerator1,
                        (numerator1 / sqrtPX96) + amount
                    )
                );
        } else {
            uint256 product;
            // if the product overflows, we know the denominator underflows
            // in addition, we must check that the denominator does not underflow
            require(
                (product = amount * sqrtPX96) / amount == sqrtPX96 &&
                    numerator1 > product,
                "denominator underflows"
            );
            uint256 denominator = numerator1 - product;
            return
                FullMath
                    .mulDivRoundingUp(numerator1, sqrtPX96, denominator)
                    .toUint160();
        }
    }

    /// @notice Gets the next sqrt price given a delta of token1
    /// @dev Always rounds down, because in the exact output case (decreasing price) we need to move the price at least
    /// far enough to get the desired output amount, and in the exact input case (increasing price) we need to move the
    /// price less in order to not send too much output.
    /// The formula we compute is within <1 wei of the lossless version: sqrtPX96 +- amount / liquidity
    /// @param sqrtPX96 The starting price, i.e., before accounting for the token1 delta
    /// @param liquidity The amount of usable liquidity
    /// @param amount How much of token1 to add, or remove, from virtual reserves
    /// @param add Whether to add, or remove, the amount of token1
    /// @return The price after adding or removing `amount`
    function getNextSqrtPriceFromAmount1RoundingDown(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amount,
        bool add
    ) internal pure returns (uint160) {
        // if we're adding (subtracting), rounding down requires rounding the quotient down (up)
        // in both cases, avoid a mulDiv for most inputs
        if (add) {
            uint256 quotient = (
                amount <= type(uint160).max
                    ? (amount << FixedPoint96.RESOLUTION) / liquidity
                    : FullMath.mulDiv(amount, FixedPoint96.Q96, liquidity)
            );

            return sqrtPX96 + quotient.toUint160();
        } else {
            uint256 quotient = (
                amount <= type(uint160).max
                    ? UnsafeMath.divRoundingUp(
                        amount << FixedPoint96.RESOLUTION,
                        liquidity
                    )
                    : FullMath.mulDivRoundingUp(
                        amount,
                        FixedPoint96.Q96,
                        liquidity
                    )
            );

            require(sqrtPX96 > quotient, "starting px must be > quotient");
            // always fits 160 bits
            return uint160(sqrtPX96 - quotient);
        }
    }

    /// @notice Gets the next sqrt price given an input amount of token0 or token1
    /// @dev Throws if price or liquidity are 0, or if the next price is out of bounds
    /// @param sqrtPX96 The starting price, i.e., before accounting for the input amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountIn How much of token0, or token1, is being swapped in
    /// @param zeroForOne Whether the amount in is token0 or token1
    /// @return sqrtQX96 The price after adding the input amount to token0 or token1
    function getNextSqrtPriceFromInput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0, "starting price must be > 0");
        require(liquidity > 0, "liquidity must be > 0");

        // round to make sure that we don't pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount0RoundingUp(
                    sqrtPX96,
                    liquidity,
                    amountIn,
                    true
                )
                : getNextSqrtPriceFromAmount1RoundingDown(
                    sqrtPX96,
                    liquidity,
                    amountIn,
                    true
                );
    }

    /// @notice Gets the next sqrt price given an output amount of token0 or token1
    /// @dev Throws if price or liquidity are 0 or the next price is out of bounds
    /// @param sqrtPX96 The starting price before accounting for the output amount
    /// @param liquidity The amount of usable liquidity
    /// @param amountOut How much of token0, or token1, is being swapped out
    /// @param zeroForOne Whether the amount out is token0 or token1
    /// @return sqrtQX96 The price after removing the output amount of token0 or token1
    function getNextSqrtPriceFromOutput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountOut,
        bool zeroForOne
    ) internal pure returns (uint160 sqrtQX96) {
        require(sqrtPX96 > 0, "starting price must be > 0");
        require(liquidity > 0, "liquidity must be > 0");

        // round to make sure that we pass the target price
        return
            zeroForOne
                ? getNextSqrtPriceFromAmount1RoundingDown(
                    sqrtPX96,
                    liquidity,
                    amountOut,
                    false
                )
                : getNextSqrtPriceFromAmount0RoundingUp(
                    sqrtPX96,
                    liquidity,
                    amountOut,
                    false
                );
    }

    /// @notice Gets the amount0 delta between two prices
    /// @dev Calculates liquidity / sqrt(lower) - liquidity / sqrt(upper),
    /// i.e. liquidity * (sqrt(upper) - sqrt(lower)) / (sqrt(upper) * sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up or down
    /// @return amount0 Amount of token0 required to cover a position of size liquidity between the two passed prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount0) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        uint256 numerator1 = uint256(liquidity) << FixedPoint96.RESOLUTION;
        uint256 numerator2 = sqrtRatioBX96 - sqrtRatioAX96;

        require(sqrtRatioAX96 > 0, "sqrt price must be > 0");

        // test the effect of he unchecked blocks
        unchecked {
            return
                roundUp
                    ? UnsafeMath.divRoundingUp(
                        FullMath.mulDivRoundingUp(
                            numerator1,
                            numerator2,
                            sqrtRatioBX96
                        ),
                        sqrtRatioAX96
                    )
                    : FullMath.mulDiv(numerator1, numerator2, sqrtRatioBX96) /
                        sqrtRatioAX96;
        }
    }

    /// @notice Gets the amount1 delta between two prices
    /// @dev Calculates liquidity * (sqrt(upper) - sqrt(lower))
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The amount of usable liquidity
    /// @param roundUp Whether to round the amount up, or down
    /// @return amount1 Amount of token1 required to cover a position of size liquidity between the two passed prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        uint128 liquidity,
        bool roundUp
    ) internal pure returns (uint256 amount1) {
        if (sqrtRatioAX96 > sqrtRatioBX96)
            (sqrtRatioAX96, sqrtRatioBX96) = (sqrtRatioBX96, sqrtRatioAX96);

        unchecked {
            return
                roundUp
                    ? FullMath.mulDivRoundingUp(
                        liquidity,
                        sqrtRatioBX96 - sqrtRatioAX96,
                        FixedPoint96.Q96
                    )
                    : FullMath.mulDiv(
                        liquidity,
                        sqrtRatioBX96 - sqrtRatioAX96,
                        FixedPoint96.Q96
                    );
        }
    }

    /// @notice Helper that gets signed token0 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount0 delta
    /// @return amount0 Amount of token0 corresponding to the passed liquidityDelta between the two prices
    function getAmount0Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount0) {
        return
            liquidity < 0
                ? -getAmount0Delta(
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    uint128(-liquidity),
                    false
                ).toInt256()
                : getAmount0Delta(
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    uint128(liquidity),
                    true
                ).toInt256();
    }

    /// @notice Helper that gets signed token1 delta
    /// @param sqrtRatioAX96 A sqrt price
    /// @param sqrtRatioBX96 Another sqrt price
    /// @param liquidity The change in liquidity for which to compute the amount1 delta
    /// @return amount1 Amount of token1 corresponding to the passed liquidityDelta between the two prices
    function getAmount1Delta(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) internal pure returns (int256 amount1) {
        return
            liquidity < 0
                ? -getAmount1Delta(
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    uint128(-liquidity),
                    false
                ).toInt256()
                : getAmount1Delta(
                    sqrtRatioAX96,
                    sqrtRatioBX96,
                    uint128(liquidity),
                    true
                ).toInt256();
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.8.9;

import "../utils/FullMath.sol";
import "../utils/SqrtPriceMath.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";
import "prb-math/contracts/PRBMathSD59x18.sol";
import "../core_libraries/FixedAndVariableMath.sol";

/// @title Computes the result of a swap within ticks
/// @notice Contains methods for computing the result of a swap within a single tick price range, i.e., a single tick.
library SwapMath {
    struct SwapStepParams {
        uint160 sqrtRatioCurrentX96;
        uint160 sqrtRatioTargetX96;
        uint128 liquidity;
        int256 amountRemaining;
        uint256 feePercentageWad;
        uint256 timeToMaturityInSecondsWad;
    }

    function computeFeeAmount(
        uint256 notionalWad,
        uint256 timeToMaturityInSecondsWad,
        uint256 feePercentageWad
    ) internal pure returns (uint256 feeAmount) {
        uint256 timeInYearsWad = FixedAndVariableMath.accrualFact(
            timeToMaturityInSecondsWad
        );

        uint256 feeAmountWad = PRBMathUD60x18.mul(
            notionalWad,
            PRBMathUD60x18.mul(feePercentageWad, timeInYearsWad)
        );

        feeAmount = PRBMathUD60x18.toUint(feeAmountWad);
    }

    /// @notice Computes the result of swapping some amount in, or amount out, given the parameters of the swap
    /// @dev The fee, plus the amount in, will never exceed the amount remaining if the swap's `amountSpecified` is positive
    /// @param params.sqrtRatioCurrentX96 The current sqrt price of the pool
    /// @param params.sqrtRatioTargetX96 The price that cannot be exceeded, from which the direction of the swap is inferred
    /// @param params.liquidity The usable params.liquidity
    /// @param params.amountRemaining How much input or output amount is remaining to be swapped in/out
    /// @return sqrtRatioNextX96 The price after swapping the amount in/out, not to exceed the price target
    /// @return amountIn The amount to be swapped in, of either token0 or token1, based on the direction of the swap
    /// @return amountOut The amount to be received, of either token0 or token1, based on the direction of the swa
    /// @return feeAmount Amount of fees in underlying tokens incurred by the position during the swap step, i.e. single iteration of the while loop in the VAMM
    function computeSwapStep(SwapStepParams memory params)
        internal
        pure
        returns (
            uint160 sqrtRatioNextX96,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        )
    {
        bool zeroForOne = params.sqrtRatioCurrentX96 >=
            params.sqrtRatioTargetX96;
        bool exactIn = params.amountRemaining >= 0;

        uint256 amountRemainingAbsolute;

        /// @dev using unchecked block below since overflow is possible when calculating "-amountRemaining" and such overflow would cause a revert
        unchecked {
            amountRemainingAbsolute = uint256(-params.amountRemaining);
        }

        if (exactIn) {
            amountIn = zeroForOne
                ? SqrtPriceMath.getAmount0Delta(
                    params.sqrtRatioTargetX96,
                    params.sqrtRatioCurrentX96,
                    params.liquidity,
                    true
                )
                : SqrtPriceMath.getAmount1Delta(
                    params.sqrtRatioCurrentX96,
                    params.sqrtRatioTargetX96,
                    params.liquidity,
                    true
                );
            if (uint256(params.amountRemaining) >= amountIn)
                sqrtRatioNextX96 = params.sqrtRatioTargetX96;
            else
                sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromInput(
                    params.sqrtRatioCurrentX96,
                    params.liquidity,
                    uint256(params.amountRemaining),
                    zeroForOne
                );
        } else {
            amountOut = zeroForOne
                ? SqrtPriceMath.getAmount1Delta(
                    params.sqrtRatioTargetX96,
                    params.sqrtRatioCurrentX96,
                    params.liquidity,
                    false
                )
                : SqrtPriceMath.getAmount0Delta(
                    params.sqrtRatioCurrentX96,
                    params.sqrtRatioTargetX96,
                    params.liquidity,
                    false
                );
            if (amountRemainingAbsolute >= amountOut)
                sqrtRatioNextX96 = params.sqrtRatioTargetX96;
            else
                sqrtRatioNextX96 = SqrtPriceMath.getNextSqrtPriceFromOutput(
                    params.sqrtRatioCurrentX96,
                    params.liquidity,
                    amountRemainingAbsolute,
                    zeroForOne
                );
        }

        bool max = params.sqrtRatioTargetX96 == sqrtRatioNextX96;
        uint256 notional;

        // get the input/output amounts
        if (zeroForOne) {
            amountIn = max && exactIn
                ? amountIn
                : SqrtPriceMath.getAmount0Delta(
                    sqrtRatioNextX96,
                    params.sqrtRatioCurrentX96,
                    params.liquidity,
                    true
                );
            amountOut = max && !exactIn
                ? amountOut
                : SqrtPriceMath.getAmount1Delta(
                    sqrtRatioNextX96,
                    params.sqrtRatioCurrentX96,
                    params.liquidity,
                    false
                );
            // variable taker
            notional = amountOut;
        } else {
            amountIn = max && exactIn
                ? amountIn
                : SqrtPriceMath.getAmount1Delta(
                    params.sqrtRatioCurrentX96,
                    sqrtRatioNextX96,
                    params.liquidity,
                    true
                );
            amountOut = max && !exactIn
                ? amountOut
                : SqrtPriceMath.getAmount0Delta(
                    params.sqrtRatioCurrentX96,
                    sqrtRatioNextX96,
                    params.liquidity,
                    false
                );

            // fixed taker
            notional = amountIn;
        }

        // cap the output amount to not exceed the remaining output amount
        if (!exactIn && amountOut > amountRemainingAbsolute) {
            /// @dev if !exact in => fixedTaker => has no effect on notional since notional = amountIn
            amountOut = amountRemainingAbsolute;
        }

        // uint256 notionalWad = PRBMathUD60x18.fromUint(notional);

        feeAmount = computeFeeAmount(
            PRBMathUD60x18.fromUint(notional),
            params.timeToMaturityInSecondsWad,
            params.feePercentageWad
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.9;

/// @title BitMath
/// @dev This library provides functionality for computing bit properties of an unsigned integer
library BitMath {
    /// @notice Returns the index of the most significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     x >= 2**mostSignificantBit(x) and x < 2**(mostSignificantBit(x)+1)
    /// @param x the value for which to compute the most significant bit, must be greater than 0
    /// @return r the index of the most significant bit
    function mostSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, "x must be > 0");

        if (x >= 0x100000000000000000000000000000000) {
            x >>= 128;
            r += 128;
        }
        if (x >= 0x10000000000000000) {
            x >>= 64;
            r += 64;
        }
        if (x >= 0x100000000) {
            x >>= 32;
            r += 32;
        }
        if (x >= 0x10000) {
            x >>= 16;
            r += 16;
        }
        if (x >= 0x100) {
            x >>= 8;
            r += 8;
        }
        if (x >= 0x10) {
            x >>= 4;
            r += 4;
        }
        if (x >= 0x4) {
            x >>= 2;
            r += 2;
        }
        if (x >= 0x2) r += 1;
    }

    /// @notice Returns the index of the least significant bit of the number,
    ///     where the least significant bit is at index 0 and the most significant bit is at index 255
    /// @dev The function satisfies the property:
    ///     (x & 2**leastSignificantBit(x)) != 0 and (x & (2**(leastSignificantBit(x)) - 1)) == 0)
    /// @param x the value for which to compute the least significant bit, must be greater than 0
    /// @return r the index of the least significant bit
    function leastSignificantBit(uint256 x) internal pure returns (uint8 r) {
        require(x > 0, "x must be > 0");

        r = 255;
        if (x & type(uint128).max > 0) {
            r -= 128;
        } else {
            x >>= 128;
        }
        if (x & type(uint64).max > 0) {
            r -= 64;
        } else {
            x >>= 64;
        }
        if (x & type(uint32).max > 0) {
            r -= 32;
        } else {
            x >>= 32;
        }
        if (x & type(uint16).max > 0) {
            r -= 16;
        } else {
            x >>= 16;
        }
        if (x & type(uint8).max > 0) {
            r -= 8;
        } else {
            x >>= 8;
        }
        if (x & 0xf > 0) {
            r -= 4;
        } else {
            x >>= 4;
        }
        if (x & 0x3 > 0) {
            r -= 2;
        } else {
            x >>= 2;
        }
        if (x & 0x1 > 0) r -= 1;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity =0.8.9;

/// @title Safe casting methods
/// @notice Contains methods for safely casting between types
library SafeCastUni {
    /// @notice Cast a uint256 to a uint160, revert on overflow
    /// @param y The uint256 to be downcasted
    /// @return z The downcasted integer, now type uint160
    function toUint160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y, "overflow in toUint160");
    }

    /// @notice Cast a int256 to a int128, revert on overflow or underflow
    /// @param y The int256 to be downcasted
    /// @return z The downcasted integer, now type int128
    function toInt128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y, "overflow in toInt128");
    }

    /// @notice Cast a uint256 to a int256, revert on overflow
    /// @param y The uint256 to be casted
    /// @return z The casted integer, now type int256
    function toInt256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255, "overflow in toInt256");
        z = int256(y);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

// solhint-disable no-inline-assembly

pragma solidity =0.8.9;

/// @title Math functions that do not check inputs or outputs
/// @notice Contains methods that perform common math functions but do not do any overflow or underflow checks
library UnsafeMath {
    /// @notice Returns ceil(x / y)
    /// @dev division by 0 has unspecified behavior, and must be checked externally
    /// @param x The dividend
    /// @param y The divisor
    /// @return z The quotient, ceil(x / y)
    function divRoundingUp(uint256 x, uint256 y)
        internal
        pure
        returns (uint256 z)
    {
        assembly {
            z := add(div(x, y), gt(mod(x, y), 0))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;
import "./core_libraries/Tick.sol";
import "./interfaces/IMarginEngine.sol";
import "./core_libraries/MarginCalculator.sol";
import "./interfaces/rate_oracles/IRateOracle.sol";
import "./interfaces/fcms/IFCM.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";
import "./core_libraries/FixedAndVariableMath.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./core_libraries/SafeTransferLib.sol";
import "./storage/MarginEngineStorage.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MarginEngine is
    MarginEngineStorage,
    IMarginEngine,
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    UUPSUpgradeable
{
    using SafeCast for uint256;
    using SafeCast for int256;
    using Tick for mapping(int24 => Tick.Info);

    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;

    using SafeTransferLib for IERC20Minimal;

    uint256 public constant MAX_LOOKBACK_WINDOW_IN_SECONDS = 315360000; // ten years
    uint256 public constant MIN_LOOKBACK_WINDOW_IN_SECONDS = 3600; // one hour
    uint256 public constant MAX_CACHE_MAX_AGE_IN_SECONDS = 1209600; // two weeks
    uint256 public constant MAX_LIQUIDATOR_REWARD_WAD = 3e17; // 30%

    // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    struct PositionMarginRequirementLocalVars2 {
        int24 inRangeTick;
        int256 scenario1LPVariableTokenBalance;
        int256 scenario1LPFixedTokenBalance;
        uint160 scenario1SqrtPriceX96;
        int256 scenario2LPVariableTokenBalance;
        int256 scenario2LPFixedTokenBalance;
        uint160 scenario2SqrtPriceX96;
    }

    function initialize(
        IERC20Minimal __underlyingToken,
        IRateOracle __rateOracle,
        uint256 __termStartTimestampWad,
        uint256 __termEndTimestampWad
    ) external override initializer {
        require(address(__underlyingToken) != address(0), "UT");
        require(address(__rateOracle) != address(0), "RO");
        require(__termStartTimestampWad != 0, "TS");
        require(__termEndTimestampWad != 0, "TE");
        require(__termEndTimestampWad > __termStartTimestampWad, "TE<=TS");

        _underlyingToken = __underlyingToken;
        _termStartTimestampWad = __termStartTimestampWad;
        _termEndTimestampWad = __termEndTimestampWad;

        _rateOracle = __rateOracle;
        _factory = IFactory(msg.sender);

        // Todo: set default values for things like _secondsAgo, cacheMaxAge.
        // We should see if we need to do any similar defaulting for VAMM, FCM
        // _secondsAgo = 2 weeks; // can be changed by owner
        // _cacheMaxAgeInSeconds = 6 hours; // can be changed by owner

        __Ownable_init();
        __Pausable_init();
        __UUPSUpgradeable_init();
    }

    // To authorize the owner to upgrade the contract we implement _authorizeUpgrade with the onlyOwner modifier.
    // ref: https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786
    function _authorizeUpgrade(address) internal override onlyOwner {}

    modifier nonZeroDelta(int256 marginDelta) {
        if (marginDelta == 0) {
            revert CustomErrors.InvalidMarginDelta();
        }
        _;
    }

    /// @dev Modifier that ensures only the VAMM can execute certain actions
    modifier onlyVAMM() {
        if (msg.sender != address(_vamm)) {
            revert CustomErrors.OnlyVAMM();
        }
        _;
    }

    /// @dev Modifier that reverts if the msg.sender is not the Full Collateralisation Module
    modifier onlyFCM() {
        if (msg.sender != address(_fcm)) {
            revert CustomErrors.OnlyFCM();
        }
        _;
    }

    /// @dev Modifier that reverts if the termEndTimestamp is higher than the current block timestamp
    /// @dev This modifier ensures that actions such as settlePosition (can only be done after maturity)
    modifier onlyAfterMaturity() {
        if (_termEndTimestampWad > Time.blockTimestampScaled()) {
            revert CustomErrors.CannotSettleBeforeMaturity();
        }
        _;
    }

    /// @dev Modifier that ensures new LP positions cannot be minted after one day before the maturity of the vamm
    /// @dev also ensures new swaps cannot be conducted after one day before maturity of the vamm
    modifier checkCurrentTimestampTermEndTimestampDelta() {
        if (Time.isCloseToMaturityOrBeyondMaturity(_termEndTimestampWad)) {
            revert CustomErrors.closeToOrBeyondMaturity();
        }
        _;
    }

    // GETTERS FOR STORAGE SLOTS
    // Not auto-generated by public variables in the storage contract, cos solidity doesn't support that for functions that implement an interface
    /// @inheritdoc IMarginEngine
    function termStartTimestampWad() external view override returns (uint256) {
        return _termStartTimestampWad;
    }

    /// @inheritdoc IMarginEngine
    function termEndTimestampWad() external view override returns (uint256) {
        return _termEndTimestampWad;
    }

    /// @inheritdoc IMarginEngine
    function lookbackWindowInSeconds()
        external
        view
        override
        returns (uint256)
    {
        return _secondsAgo;
    }

    /// @inheritdoc IMarginEngine
    function cacheMaxAgeInSeconds() external view override returns (uint256) {
        return _cacheMaxAgeInSeconds;
    }

    /// @inheritdoc IMarginEngine
    function liquidatorRewardWad() external view override returns (uint256) {
        return _liquidatorRewardWad;
    }

    /// @inheritdoc IMarginEngine
    function underlyingToken() external view override returns (IERC20Minimal) {
        return _underlyingToken;
    }

    /// @inheritdoc IMarginEngine
    function fcm() external view override returns (IFCM) {
        return _fcm;
    }

    /// @inheritdoc IMarginEngine
    function vamm() external view override returns (IVAMM) {
        return _vamm;
    }

    /// @inheritdoc IMarginEngine
    function factory() external view override returns (IFactory) {
        return _factory;
    }

    /// @inheritdoc IMarginEngine
    function rateOracle() external view override returns (IRateOracle) {
        return _rateOracle;
    }

    /// @inheritdoc IMarginEngine
    function setMarginCalculatorParameters(
        MarginCalculatorParameters memory _marginCalculatorParameters
    ) external override onlyOwner {
        marginCalculatorParameters = _marginCalculatorParameters;
        emit MarginCalculatorParametersSetting(marginCalculatorParameters);
    }

    /// @inheritdoc IMarginEngine
    function setVAMM(IVAMM _vAMM) external override onlyOwner {
        _vamm = _vAMM;
        emit VAMMSetting(_vamm);
    }

    /// @inheritdoc IMarginEngine
    function setRateOracle(IRateOracle __rateOracle) external override onlyOwner {
        _rateOracle = __rateOracle;
        emit RateOracleSetting(_rateOracle);
    }

    /// @inheritdoc IMarginEngine
    function setFCM(IFCM _newFCM) external override onlyOwner {
        _fcm = _newFCM;
        emit FCMSetting(_fcm);
    }

    /// @inheritdoc IMarginEngine
    function setLookbackWindowInSeconds(uint256 _newSecondsAgo)
        external
        override
        onlyOwner
    {
        require(
            (_newSecondsAgo <= MAX_LOOKBACK_WINDOW_IN_SECONDS) &&
                (_newSecondsAgo >= MIN_LOOKBACK_WINDOW_IN_SECONDS),
            "LB OOB"
        );

        _secondsAgo = _newSecondsAgo;
        emit HistoricalApyWindowSetting(_secondsAgo);
    }

    /// @inheritdoc IMarginEngine
    function setCacheMaxAgeInSeconds(uint256 _newCacheMaxAgeInSeconds)
        external
        override
        onlyOwner
    {
        require(
            _newCacheMaxAgeInSeconds <= MAX_CACHE_MAX_AGE_IN_SECONDS,
            "CMA OOB"
        );

        _cacheMaxAgeInSeconds = _newCacheMaxAgeInSeconds;
        emit CacheMaxAgeSetting(_cacheMaxAgeInSeconds);
    }

    /// @inheritdoc IMarginEngine
    function collectProtocol(address _recipient, uint256 _amount)
        external
        override
        whenNotPaused
        onlyOwner
    {
        if (_amount > 0) {
            /// @dev if the amount exceeds the available balances, _vamm.updateProtocolFees(amount) should be reverted as intended
            _vamm.updateProtocolFees(_amount);
            _underlyingToken.safeTransfer(_recipient, _amount);
        }

        emit ProtocolCollection(msg.sender, _recipient, _amount);
    }

    /// @inheritdoc IMarginEngine
    function setLiquidatorReward(uint256 _newLiquidatorRewardWad)
        external
        override
        onlyOwner
    {
        require(
            _newLiquidatorRewardWad <= MAX_LIQUIDATOR_REWARD_WAD,
            "LR OOB"
        );

        _liquidatorRewardWad = _newLiquidatorRewardWad;
        emit LiquidatorRewardSetting(_liquidatorRewardWad);
    }

    /// @inheritdoc IMarginEngine
    function getPosition(
        address _owner,
        int24 _tickLower,
        int24 _tickUpper
    ) external override returns (Position.Info memory) {
        Position.Info storage _position = positions.get(
            _owner,
            _tickLower,
            _tickUpper
        );
        _updatePositionTokenBalancesAndAccountForFees(
            _position,
            _tickLower,
            _tickUpper,
            false
        ); // isMint=false
        return _position;
    }

    /// @notice _transferMargin function which:
    /// @dev Transfers funds in from account if _marginDelta is positive, or out to account if _marginDelta is negative
    /// @dev if the margiDelta is positive, we conduct a safe transfer from the _account address to the address of the MarginEngine
    /// @dev if the marginDelta is negative, the user wishes to withdraw underlying tokens from the MarginEngine,
    /// @dev in that case we first check the balance of the marginEngine in terms of the underlying tokens, if the balance is sufficient to cover the margin transfer, then we cover it via a safeTransfer
    /// @dev if the marginEngineBalance is not sufficient to cover the marginDelta then we cover the remainingDelta by invoking the transferMarginToMarginEngineTrader function of the fcm which in case of Aave will calls the Aave withdraw function to settle with the MarginEngine in underlying tokens
    function _transferMargin(address _account, int256 _marginDelta) internal {
        if (_marginDelta > 0) {
            _underlyingToken.safeTransferFrom(
                _account,
                address(this),
                uint256(_marginDelta)
            );
        } else {
            uint256 _marginEngineBalance = _underlyingToken.balanceOf(
                address(this)
            );

            uint256 _remainingDeltaToCover;
            unchecked {
                _remainingDeltaToCover = uint256(-_marginDelta);
            }

            if (_remainingDeltaToCover > _marginEngineBalance) {
                if (_marginEngineBalance > 0) {
                    _remainingDeltaToCover -= _marginEngineBalance;
                    _underlyingToken.safeTransfer(
                        _account,
                        _marginEngineBalance
                    );
                }
                _fcm.transferMarginToMarginEngineTrader(
                    _account,
                    _remainingDeltaToCover
                );
            } else {
                _underlyingToken.safeTransfer(_account, _remainingDeltaToCover);
            }
        }
    }

    /// @inheritdoc IMarginEngine
    function transferMarginToFCMTrader(address _account, uint256 _marginDelta)
        external
        override
        whenNotPaused
        onlyFCM
    {
        _underlyingToken.safeTransfer(_account, _marginDelta);
    }

    /// @inheritdoc IMarginEngine
    function updatePositionMargin(
        address _owner,
        int24 _tickLower,
        int24 _tickUpper,
        int256 _marginDelta
    ) external override whenNotPaused nonZeroDelta(_marginDelta) {
        require(_owner != address(0), "O0");

        Tick.checkTicks(_tickLower, _tickUpper);

        Position.Info storage _position = positions.get(
            _owner,
            _tickLower,
            _tickUpper
        );

        _updatePositionTokenBalancesAndAccountForFees(
            _position,
            _tickLower,
            _tickUpper,
            false
        ); // isMint=false

        if (_marginDelta < 0) {
            if (
                _owner != msg.sender && !_factory.isApproved(_owner, msg.sender)
            ) {
                revert CustomErrors.OnlyOwnerCanUpdatePosition();
            }

            _position.updateMarginViaDelta(_marginDelta);

            _checkPositionMarginCanBeUpdated(_position, _tickLower, _tickUpper);

            _transferMargin(_owner, _marginDelta);
        } else {
            _position.updateMarginViaDelta(_marginDelta);

            _transferMargin(msg.sender, _marginDelta);
        }

        _position.rewardPerAmount = 0;

        emit PositionMarginUpdate(
            msg.sender,
            _owner,
            _tickLower,
            _tickUpper,
            _marginDelta
        );

        emit PositionUpdate(
            _owner,
            _tickLower,
            _tickUpper,
            _position._liquidity,
            _position.margin,
            _position.fixedTokenBalance,
            _position.variableTokenBalance,
            _position.accumulatedFees
        );
    }

    /// @inheritdoc IMarginEngine
    function settlePosition(
        address _owner,
        int24 _tickLower,
        int24 _tickUpper
    ) external override whenNotPaused onlyAfterMaturity {
        Tick.checkTicks(_tickLower, _tickUpper);

        Position.Info storage _position = positions.get(
            _owner,
            _tickLower,
            _tickUpper
        );

        _updatePositionTokenBalancesAndAccountForFees(
            _position,
            _tickLower,
            _tickUpper,
            false
        );

        /// @audit [ABDK] This line is way too long.
        /// Consider reformatting and/or refactoring.

        int256 _settlementCashflow = FixedAndVariableMath
            .calculateSettlementCashflow(
                _position.fixedTokenBalance,
                _position.variableTokenBalance,
                _termStartTimestampWad,
                _termEndTimestampWad,
                _rateOracle.variableFactor(
                    _termStartTimestampWad,
                    _termEndTimestampWad
                )
            );

        _position.updateBalancesViaDeltas(
            -_position.fixedTokenBalance,
            -_position.variableTokenBalance
        );
        _position.updateMarginViaDelta(_settlementCashflow);
        _position.settlePosition();

        emit PositionSettlement(
            _owner,
            _tickLower,
            _tickUpper,
            _settlementCashflow
        );

        emit PositionUpdate(
            _owner,
            _tickLower,
            _tickUpper,
            _position._liquidity,
            _position.margin,
            _position.fixedTokenBalance,
            _position.variableTokenBalance,
            _position.accumulatedFees
        );
    }

    /// @inheritdoc IMarginEngine
    function getHistoricalApy() public override returns (uint256) {
        if (
            block.timestamp - cachedHistoricalApyWadRefreshTimestamp >
            _cacheMaxAgeInSeconds
        ) {
            // Cache is stale
            _refreshHistoricalApyCache();
            emit HistoricalApy(cachedHistoricalApyWad);
        }
        return cachedHistoricalApyWad;
    }

    /// @notice Computes the historical APY value of the RateOracle
    /// @dev The lookback window used by this function is determined by the _secondsAgo state variable
    function getHistoricalApyReadOnly() public view returns (uint256) {
        if (
            block.timestamp - cachedHistoricalApyWadRefreshTimestamp >
            _cacheMaxAgeInSeconds
        ) {
            // Cache is stale
            return _getHistoricalApy();
        }
        return cachedHistoricalApyWad;
    }

    /// @notice Computes the historical APY value of the RateOracle
    /// @dev The lookback window used by this function is determined by the _secondsAgo state variable
    function _getHistoricalApy() internal view returns (uint256) {
        uint256 _from = block.timestamp - _secondsAgo;

        uint256 historicalApy = _rateOracle.getApyFromTo(_from, block.timestamp);
        return historicalApy;
    }

    /// @notice Updates the cached historical APY value of the RateOracle even if the cache is not stale
    function _refreshHistoricalApyCache() internal {
        cachedHistoricalApyWad = _getHistoricalApy();
        cachedHistoricalApyWadRefreshTimestamp = block.timestamp;
    }

    /// @inheritdoc IMarginEngine
    function liquidatePosition(
        address _owner,
        int24 _tickLower,
        int24 _tickUpper
    )
        external
        override
        whenNotPaused
        checkCurrentTimestampTermEndTimestampDelta
        returns (uint256)
    {
        /// @dev can only happen before maturity, this is checked when an unwind is triggered which in turn triggers a swap which checks for this condition

        Tick.checkTicks(_tickLower, _tickUpper);

        Position.Info storage _position = positions.get(
            _owner,
            _tickLower,
            _tickUpper
        );

        _updatePositionTokenBalancesAndAccountForFees(
            _position,
            _tickLower,
            _tickUpper,
            false
        ); // isMint=false

        (bool _isLiquidatable, ) = _isLiquidatablePosition(
            _position,
            _tickLower,
            _tickUpper
        );

        if (!_isLiquidatable) {
            revert CannotLiquidate();
        }

        if (_position.rewardPerAmount == 0) {
            uint256 _absVariableTokenBalance = _position.variableTokenBalance <
                0
                ? uint256(-_position.variableTokenBalance)
                : uint256(_position.variableTokenBalance);
            if (_position.margin > 0) {
                _position.rewardPerAmount = PRBMathUD60x18.div(
                    PRBMathUD60x18.mul(
                        uint256(_position.margin),
                        _liquidatorRewardWad
                    ),
                    _absVariableTokenBalance
                );
            } else {
                _position.rewardPerAmount = 0;
            }
        }

        uint256 _liquidatorRewardValue = 0;
        if (_position._liquidity > 0) {
            /// @dev pass position._liquidity to ensure all of the liqudity is burnt
            _vamm.burn(_owner, _tickLower, _tickUpper, _position._liquidity);
            _position.updateLiquidity(-int128(_position._liquidity));

            /// @dev liquidator reward for burning liquidity
            _liquidatorRewardValue += PRBMathUD60x18.mul(
                uint256(_position.margin),
                _liquidatorRewardWad
            );
        }

        int256 _variableTokenDelta = _unwindPosition(
            _position,
            _owner,
            _tickLower,
            _tickUpper
        );

        /// @dev liquidator reward for unwinding position
        if (_variableTokenDelta != 0) {
            _liquidatorRewardValue += (_variableTokenDelta < 0)
                ? PRBMathUD60x18.mul(
                    uint256(-_variableTokenDelta),
                    _position.rewardPerAmount
                )
                : PRBMathUD60x18.mul(
                    uint256(_variableTokenDelta),
                    _position.rewardPerAmount
                );
        }

        if (_liquidatorRewardValue > 0) {
            _position.updateMarginViaDelta(-_liquidatorRewardValue.toInt256());
            _underlyingToken.safeTransfer(msg.sender, _liquidatorRewardValue);
        }

        emit PositionLiquidation(
            _owner,
            _tickLower,
            _tickUpper,
            msg.sender,
            _variableTokenDelta,
            _liquidatorRewardValue
        );

        emit PositionUpdate(
            _owner,
            _tickLower,
            _tickUpper,
            _position._liquidity,
            _position.margin,
            _position.fixedTokenBalance,
            _position.variableTokenBalance,
            _position.accumulatedFees
        );

        return _liquidatorRewardValue;
    }

    /// @inheritdoc IMarginEngine
    function updatePositionPostVAMMInducedMintBurn(
        IVAMM.ModifyPositionParams memory _params
    )
        external
        override
        whenNotPaused
        onlyVAMM
        returns (int256 _positionMarginRequirement)
    {
        Position.Info storage _position = positions.get(
            _params.owner,
            _params.tickLower,
            _params.tickUpper
        );

        _updatePositionTokenBalancesAndAccountForFees(
            _position,
            _params.tickLower,
            _params.tickUpper,
            true
        ); // isMint=true

        _position.updateLiquidity(_params.liquidityDelta);

        if (_params.liquidityDelta > 0) {
            _positionMarginRequirement = _checkPositionMarginAboveRequirement(
                _position,
                _params.tickLower,
                _params.tickUpper
            );
        }

        if (_position.rewardPerAmount >= 0) {
            _position.rewardPerAmount = 0;
        }

        emit PositionUpdate(
            _params.owner,
            _params.tickLower,
            _params.tickUpper,
            _position._liquidity,
            _position.margin,
            _position.fixedTokenBalance,
            _position.variableTokenBalance,
            _position.accumulatedFees
        );
    }

    /// @inheritdoc IMarginEngine
    function updatePositionPostVAMMInducedSwap(
        address _owner,
        int24 _tickLower,
        int24 _tickUpper,
        int256 _fixedTokenDelta,
        int256 _variableTokenDelta,
        uint256 _cumulativeFeeIncurred,
        int256 _fixedTokenDeltaUnbalanced
    )
        external
        override
        whenNotPaused
        onlyVAMM
        returns (int256 _positionMarginRequirement)
    {
        /// @dev this function can only be called by the vamm following a swap

        Position.Info storage _position = positions.get(
            _owner,
            _tickLower,
            _tickUpper
        );
        _updatePositionTokenBalancesAndAccountForFees(
            _position,
            _tickLower,
            _tickUpper,
            false
        ); // isMint=false

        /// @dev isUnwind means the trader is getting into a swap with the opposite direction to their net position
        /// @dev in that case it does not make sense to revert the transaction if the position margin requirement is not met since
        /// @dev it could have been even further from the requirement prior to the unwind
        bool _isUnwind = (_position.variableTokenBalance > 0 &&
            _variableTokenDelta < 0) ||
            (_position.variableTokenBalance < 0 && _variableTokenDelta > 0);

        if (_cumulativeFeeIncurred > 0) {
            _position.updateMarginViaDelta(-_cumulativeFeeIncurred.toInt256());
        }

        _position.updateBalancesViaDeltas(
            _fixedTokenDelta,
            _variableTokenDelta
        );

        _positionMarginRequirement = _getPositionMarginRequirement(
            _position,
            _tickLower,
            _tickUpper,
            false
        ).toInt256();

        /// @dev only check the margin requirement if it is not an unwind since an unwind could bring the position to a better state
        /// @dev and still not make it through the initial margin requirement
        if ((_positionMarginRequirement > _position.margin) && !_isUnwind) {
            IVAMM.VAMMVars memory _v = _vamm.vammVars();
            revert CustomErrors.MarginRequirementNotMet(
                _positionMarginRequirement,
                _v.tick,
                _fixedTokenDelta,
                _variableTokenDelta,
                _cumulativeFeeIncurred,
                _fixedTokenDeltaUnbalanced
            );
        }

        _position.rewardPerAmount = 0;

        emit PositionUpdate(
            _owner,
            _tickLower,
            _tickUpper,
            _position._liquidity,
            _position.margin,
            _position.fixedTokenBalance,
            _position.variableTokenBalance,
            _position.accumulatedFees
        );
    }

    /// @notice update position token balances and account for fees
    /// @dev if the _liquidity of the position supplied to this function is >0 then we
    /// @dev 1. retrieve the fixed, variable and fee Growth variables from the vamm by invoking the computeGrowthInside function of the VAMM
    /// @dev 2. calculate the deltas that need to be applied to the position's fixed and variable token balances by taking into account trades that took place in the VAMM since the last mint/poke/burn that invoked this function
    /// @dev 3. update the fixed and variable token balances and the margin of the position to account for deltas (outlined above) and fees generated by the active liquidity supplied by the position
    /// @dev 4. additionally, we need to update the last growth inside variables in the Position.Info struct so that we take a note that we've accounted for the changes up until this point
    /// @dev if _liquidity of the position supplied to this function is zero, then we need to check if isMintBurn is set to true (if it is set to true) then we know this function was called post a mint/burn event,
    /// @dev meaning we still need to correctly update the last fixed, variable and fee growth variables in the Position.Info struct
    function _updatePositionTokenBalancesAndAccountForFees(
        Position.Info storage _position,
        int24 _tickLower,
        int24 _tickUpper,
        bool _isMintBurn
    ) internal {
        if (_position._liquidity > 0) {
            (
                int256 _fixedTokenGrowthInsideX128,
                int256 _variableTokenGrowthInsideX128,
                uint256 _feeGrowthInsideX128
            ) = _vamm.computeGrowthInside(_tickLower, _tickUpper);
            (int256 _fixedTokenDelta, int256 _variableTokenDelta) = _position
                .calculateFixedAndVariableDelta(
                    _fixedTokenGrowthInsideX128,
                    _variableTokenGrowthInsideX128
                );
            uint256 _feeDelta = _position.calculateFeeDelta(
                _feeGrowthInsideX128
            );

            _position.updateBalancesViaDeltas(
                _fixedTokenDelta - 1,
                _variableTokenDelta - 1
            );
            _position.updateFixedAndVariableTokenGrowthInside(
                _fixedTokenGrowthInsideX128,
                _variableTokenGrowthInsideX128
            );
            /// @dev collect fees
            if (_feeDelta > 0) {
                _position.accumulatedFees += _feeDelta - 1;
                _position.updateMarginViaDelta(_feeDelta.toInt256() - 1);
            }
            
            _position.updateFeeGrowthInside(_feeGrowthInsideX128);
        } else {
            if (_isMintBurn) {
                (
                    int256 _fixedTokenGrowthInsideX128,
                    int256 _variableTokenGrowthInsideX128,
                    uint256 _feeGrowthInsideX128
                ) = _vamm.computeGrowthInside(_tickLower, _tickUpper);
                _position.updateFixedAndVariableTokenGrowthInside(
                    _fixedTokenGrowthInsideX128,
                    _variableTokenGrowthInsideX128
                );
                _position.updateFeeGrowthInside(_feeGrowthInsideX128);
            }
        }
    }

    /// @notice Internal function that checks if the position's current margin is above the requirement
    /// @param _position Position.Info of the position of interest, updates to position, edit it in storage
    /// @param _tickLower Lower Tick of the position
    /// @param _tickUpper Upper Tick of the position
    /// @dev This function calculates the position margin requirement, compares it with the position.margin and reverts if the current position margin is below the requirement
    function _checkPositionMarginAboveRequirement(
        Position.Info storage _position,
        int24 _tickLower,
        int24 _tickUpper
    ) internal returns (int256 _positionMarginRequirement) {
        _positionMarginRequirement = _getPositionMarginRequirement(
            _position,
            _tickLower,
            _tickUpper,
            false
        ).toInt256();

        if (_position.margin <= _positionMarginRequirement) {
            revert CustomErrors.MarginLessThanMinimum(
                _positionMarginRequirement
            );
        }
    }

    /// @notice Check the position margin can be updated
    /// @param _position Position.Info of the position of interest, updates to position, edit it in storage
    /// @param _tickLower Lower Tick of the position
    /// @param _tickUpper Upper Tick of the position
    function _checkPositionMarginCanBeUpdated(
        Position.Info storage _position,
        int24 _tickLower,
        int24 _tickUpper
    ) internal {
        /// @dev If the IRS AMM has reached maturity, the only reason why someone would want to update
        /// @dev their margin is to withdraw it completely. If so, the position needs to be settled
        if (Time.blockTimestampScaled() >= _termEndTimestampWad) {
            if (!_position.isSettled) {
                revert CustomErrors.PositionNotSettled();
            }
            if (_position.margin < 0) {
                revert CustomErrors.WithdrawalExceedsCurrentMargin();
            }
        } else {
            /// @dev if we haven't reached maturity yet, then check if the position margin requirement is satisfied if not then the position margin update will also revert
            _checkPositionMarginAboveRequirement(
                _position,
                _tickLower,
                _tickUpper
            );
        }
    }

    /// @notice Unwind a position
    /// @dev Before unwinding a position, need to check if it is even necessary to unwind it, i.e. check if the most up to date variable token balance of a position is non-zero
    /// @dev If the current variable token balance is negative, then it means the position is a net Fixed Taker
    /// @dev Hence to unwind, we need to enter into a Variable Taker IRS contract with notional = abs(current variable token balance of the position)
    /// @param _owner the owner of the position
    /// @param _tickLower the lower tick of the position's tick range
    /// @param _tickUpper the upper tick of the position's tick range
    function _unwindPosition(
        Position.Info storage _position,
        address _owner,
        int24 _tickLower,
        int24 _tickUpper
    ) internal returns (int256 _variableTokenDelta) {
        Tick.checkTicks(_tickLower, _tickUpper);

        if (_position.variableTokenBalance != 0) {
            int256 _fixedTokenDelta;
            uint256 _cumulativeFeeIncurred;

            /// @dev initiate a swap

            bool _isFT = _position.variableTokenBalance < 0;

            /// @dev if isFT
            /// @dev get into a Variable Taker swap (the opposite of LP's current position) --> hence params.isFT is set to false for the vamm swap call
            /// @dev amountSpecified needs to be negative (since getting into a variable taker swap)
            /// @dev since the position.variableTokenBalance is already negative, pass position.variableTokenBalance as amountSpecified
            /// @dev since moving from left to right along the virtual amm, sqrtPriceLimit is set to MIN_SQRT_RATIO + 1
            /// @dev isExternal is a boolean that ensures the state updates to the position are handled directly in the body of the unwind call
            /// @dev that's more efficient than letting the swap call the margin engine again to update position fixed and varaible token balances + account for fees
            /// @dev if !isFT
            /// @dev get into a Fixed Taker swap (the opposite of LP's current position)
            /// @dev amountSpecified needs to be positive, since we are executing a fixedd taker swap
            /// @dev since the position.variableTokenBalance is already positive, pass position.variableTokenBalance as amountSpecified
            /// @dev since moving from right to left along the virtual amm, sqrtPriceLimit is set to MAX_SQRT_RATIO - 1

            IVAMM.SwapParams memory _params = IVAMM.SwapParams({
                recipient: _owner,
                amountSpecified: _position.variableTokenBalance,
                sqrtPriceLimitX96: _isFT
                    ? TickMath.MIN_SQRT_RATIO + 1
                    : TickMath.MAX_SQRT_RATIO - 1,
                tickLower: _tickLower,
                tickUpper: _tickUpper
            });

            (
                _fixedTokenDelta,
                _variableTokenDelta,
                _cumulativeFeeIncurred,
                ,

            ) = _vamm.swap(_params);

            if (_cumulativeFeeIncurred > 0) {
                /// @dev update position margin to account for the fees incurred while conducting a swap in order to unwind
                _position.updateMarginViaDelta(
                    -_cumulativeFeeIncurred.toInt256()
                );
            }

            /// @dev passes the _fixedTokenBalance and _variableTokenBalance deltas
            _position.updateBalancesViaDeltas(
                _fixedTokenDelta,
                _variableTokenDelta
            );
        }
    }

    function _getExtraBalances(
        int24 _fromTick,
        int24 _toTick,
        uint128 _liquidity,
        uint256 _variableFactorWad
    )
        internal
        view
        returns (
            int256 _extraFixedTokenBalance,
            int256 _extraVariableTokenBalance
        )
    {
        if (_fromTick == _toTick) return (0, 0);

        uint160 _sqrtRatioAtFromTickX96 = TickMath.getSqrtRatioAtTick(
            _fromTick
        );
        uint160 _sqrtRatioAtToTickX96 = TickMath.getSqrtRatioAtTick(_toTick);

        int256 _amount0 = SqrtPriceMath.getAmount0Delta(
            _sqrtRatioAtFromTickX96,
            _sqrtRatioAtToTickX96,
            (_fromTick < _toTick) ? -int128(_liquidity) : int128(_liquidity)
        );

        int256 _amount1 = SqrtPriceMath.getAmount1Delta(
            _sqrtRatioAtFromTickX96,
            _sqrtRatioAtToTickX96,
            (_fromTick < _toTick) ? int128(_liquidity) : -int128(_liquidity)
        );

        _extraFixedTokenBalance = FixedAndVariableMath.getFixedTokenBalance(
            _amount0,
            _amount1,
            _variableFactorWad,
            _termStartTimestampWad,
            _termEndTimestampWad
        );

        _extraVariableTokenBalance = _amount1;
    }

    /// @notice Get Position Margin Requirement
    /// @dev if the position has no active liquidity in the VAMM, then we can compute its margin requirement by just passing its current fixed and variable token balances to the getMarginRequirement function
    /// @dev however, if the current _liquidity of the position is positive, it means that the position can potentially enter into interest rate swap positions with traders in their tick range
    /// @dev to account for that possibility, we analyse two scenarios:
    /// @dev scenario 1: a trader comes in and trades all the liquidity all the way to the the upper tick
    /// @dev scenario 2: a trader comes in and trades all the liquidity all the way to the the lower tick
    /// @dev one the fixed and variable token balances are calculated for each counterfactual scenarios, their margin requiremnets can be obtained by calling getMarginrRequirement for each scenario
    /// @dev finally, the output is the max of the margin requirements from two of the scenarios considered
    function _getPositionMarginRequirement(
        Position.Info storage _position,
        int24 _tickLower,
        int24 _tickUpper,
        bool _isLM
    ) internal returns (uint256 _margin) {
        Tick.checkTicks(_tickLower, _tickUpper);

        IVAMM.VAMMVars memory _vammVars = _vamm.vammVars();
        uint160 _sqrtPriceX96 = _vammVars.sqrtPriceX96;
        int24 _tick = _vammVars.tick;

        uint256 _variableFactorWad = _rateOracle.variableFactor(
            _termStartTimestampWad,
            _termEndTimestampWad
        );

        if (_position._liquidity > 0) {
            PositionMarginRequirementLocalVars2 memory _localVars;
            _localVars.inRangeTick = (_tick < _tickLower)
                ? _tickLower
                : ((_tick < _tickUpper) ? _tick : _tickUpper);

            // scenario 1: a trader comes in and trades all the liquidity all the way to the the upper tick
            // scenario 2: a trader comes in and trades all the liquidity all the way to the the lower tick

            int256 _extraFixedTokenBalance;
            int256 _extraVariableTokenBalance;

            if (_tick < _tickUpper) {
                (
                    _extraFixedTokenBalance,
                    _extraVariableTokenBalance
                ) = _getExtraBalances(
                    _localVars.inRangeTick,
                    _tickUpper,
                    _position._liquidity,
                    _variableFactorWad
                );
            }

            _localVars.scenario1LPVariableTokenBalance =
                _position.variableTokenBalance +
                _extraVariableTokenBalance;

            _localVars.scenario1LPFixedTokenBalance =
                _position.fixedTokenBalance +
                _extraFixedTokenBalance;

            if (_tick > _tickLower) {
                (
                    _extraFixedTokenBalance,
                    _extraVariableTokenBalance
                ) = _getExtraBalances(
                    _localVars.inRangeTick,
                    _tickLower,
                    _position._liquidity,
                    _variableFactorWad
                );
            } else {
                (_extraFixedTokenBalance, _extraVariableTokenBalance) = (0, 0);
            }

            _localVars.scenario2LPVariableTokenBalance =
                _position.variableTokenBalance +
                _extraVariableTokenBalance;

            _localVars.scenario2LPFixedTokenBalance =
                _position.fixedTokenBalance +
                _extraFixedTokenBalance;

            uint160 _lowPrice = TickMath.getSqrtRatioAtTick(_tickLower);
            uint160 _highPrice = TickMath.getSqrtRatioAtTick(_tickUpper);
            _lowPrice = _sqrtPriceX96 < _lowPrice ? _sqrtPriceX96 : _lowPrice;
            _highPrice = _sqrtPriceX96 > _highPrice
                ? _sqrtPriceX96
                : _highPrice;

            _localVars.scenario1SqrtPriceX96 = (_localVars
                .scenario1LPVariableTokenBalance > 0)
                ? _highPrice
                : _lowPrice;

            _localVars.scenario2SqrtPriceX96 = (_localVars
                .scenario2LPVariableTokenBalance > 0)
                ? _highPrice
                : _lowPrice;

            uint256 _scenario1MarginRequirement = _getMarginRequirement(
                _localVars.scenario1LPFixedTokenBalance,
                _localVars.scenario1LPVariableTokenBalance,
                _isLM,
                _localVars.scenario1SqrtPriceX96
            );
            uint256 _scenario2MarginRequirement = _getMarginRequirement(
                _localVars.scenario2LPFixedTokenBalance,
                _localVars.scenario2LPVariableTokenBalance,
                _isLM,
                _localVars.scenario2SqrtPriceX96
            );

            if (_scenario1MarginRequirement > _scenario2MarginRequirement) {
                return _scenario1MarginRequirement;
            } else {
                return _scenario2MarginRequirement;
            }
        } else {
            // directly get the trader margin requirement
            return
                _getMarginRequirement(
                    _position.fixedTokenBalance,
                    _position.variableTokenBalance,
                    _isLM,
                    _sqrtPriceX96
                );
        }
    }

    /// @notice Checks if a given position is liquidatable
    /// @dev In order for a position to be liquidatable its current margin needs to be lower than the position's liquidation margin requirement
    /// @return _isLiquidatable A boolean which suggests if a given position is liquidatable
    function _isLiquidatablePosition(
        Position.Info storage _position,
        int24 _tickLower,
        int24 _tickUpper
    ) internal returns (bool, int256) {
        int256 _marginRequirement = _getPositionMarginRequirement(
            _position,
            _tickLower,
            _tickUpper,
            true
        ).toInt256();

        /// @audit overflow is possible
        return (_position.margin < _marginRequirement, _marginRequirement);
    }

    /// @notice Returns either the Liquidation or Initial Margin Requirement given a fixed and variable token balance as well as the isLM boolean
    /// @return _margin  either liquidation or initial margin requirement of a given trader in terms of the underlying tokens
    function _getMarginRequirement(
        int256 _fixedTokenBalance,
        int256 _variableTokenBalance,
        bool _isLM,
        uint160 _sqrtPriceX96
    ) internal returns (uint256 _margin) {
        _margin = __getMarginRequirement(
            _fixedTokenBalance,
            _variableTokenBalance,
            _isLM
        );

        uint256 _minimumMarginRequirement = _getMinimumMarginRequirement(
            _fixedTokenBalance,
            _variableTokenBalance,
            _isLM,
            _sqrtPriceX96
        );

        if (_margin < _minimumMarginRequirement) {
            _margin = _minimumMarginRequirement;
        }
    }

    /// @notice get margin requirement based on a fixed and variable token balance and isLM boolean
    function __getMarginRequirement(
        int256 _fixedTokenBalance,
        int256 _variableTokenBalance,
        bool _isLM
    ) internal returns (uint256 _margin) {
        if (_fixedTokenBalance >= 0 && _variableTokenBalance >= 0) {
            return 0;
        }

        int256 _fixedTokenBalanceWad = PRBMathSD59x18.fromInt(
            _fixedTokenBalance
        );
        int256 _variableTokenBalanceWad = PRBMathSD59x18.fromInt(
            _variableTokenBalance
        );

        uint256 _timeInSecondsFromStartToMaturityWad = _termEndTimestampWad -
            _termStartTimestampWad;

        /// exp1 = fixedTokenBalance*timeInYearsFromTermStartToTermEnd*0.01
        // this can either be negative or positive depending on the sign of the fixedTokenBalance
        int256 _exp1Wad = PRBMathSD59x18.mul(
            _fixedTokenBalanceWad,
            FixedAndVariableMath
                .fixedFactor(true, _termStartTimestampWad, _termEndTimestampWad)
                .toInt256()
        );

        /// exp2 = variableTokenBalance*worstCaseVariableFactor(from term start to term end)
        // todo: minimise gas cost of the scenario where the balance is 0
        int256 _exp2Wad = 0;
        if (_variableTokenBalance != 0) {
            _exp2Wad = PRBMathSD59x18.mul(
                _variableTokenBalanceWad,
                MarginCalculator
                    .worstCaseVariableFactorAtMaturity(
                        _timeInSecondsFromStartToMaturityWad,
                        _termEndTimestampWad,
                        Time.blockTimestampScaled(),
                        _variableTokenBalance < 0,
                        _isLM,
                        getHistoricalApy(),
                        marginCalculatorParameters
                    )
                    .toInt256()
            );
        }

        // this is the worst case settlement cashflow expected by the position to cover
        int256 _maxCashflowDeltaToCoverPostMaturity = _exp1Wad + _exp2Wad;

        // hence if maxCashflowDeltaToCoverPostMaturity is negative then the margin needs to be sufficient to cover it
        // if maxCashflowDeltaToCoverPostMaturity is non-negative then it means according to this model the even in the worst case, the settlement cashflow is expected to be non-negative
        // hence, returning zero as the margin requirement
        if (_maxCashflowDeltaToCoverPostMaturity < 0) {
            _margin = PRBMathUD60x18.toUint(
                uint256(-_maxCashflowDeltaToCoverPostMaturity)
            );
        } else {
            _margin = 0;
        }
    }

    /// @notice Get Minimum Margin Requirement
    // given the fixed and variable balances and a starting sqrtPriceX96
    // we calculate the minimum marign requirement by simulating a counterfactual unwind at fixed rate that is a function of the current fixed rate (sqrtPriceX96) (details in the litepaper)
    // if the variable token balance is 0 or if the variable token balance is >0 and the fixed token balace >0 then the minimum margin requirement is zero
    function _getMinimumMarginRequirement(
        int256 _fixedTokenBalance,
        int256 _variableTokenBalance,
        bool _isLM,
        uint160 _sqrtPriceX96
    ) internal returns (uint256 _margin) {
        if (_variableTokenBalance == 0) {
            // if the variable token balance is zero there is no need for a minimum liquidator incentive since a liquidtion is not expected
            return 0;
        }

        int256 _fixedTokenDeltaUnbalanced;
        uint256 _devMulWad;
        uint256 _fixedRateDeviationMinWad;
        uint256 _absoluteVariableTokenBalance;
        bool _isVariableTokenBalancePositive;

        if (_variableTokenBalance > 0) {
            if (_fixedTokenBalance > 0) {
                // if both are positive, no need to have a margin requirement
                return 0;
            }

            if (_isLM) {
                _devMulWad = marginCalculatorParameters.devMulLeftUnwindLMWad;
                _fixedRateDeviationMinWad = marginCalculatorParameters
                    .fixedRateDeviationMinLeftUnwindLMWad;
            } else {
                _devMulWad = marginCalculatorParameters.devMulLeftUnwindIMWad;
                _fixedRateDeviationMinWad = marginCalculatorParameters
                    .fixedRateDeviationMinLeftUnwindIMWad;
            }

            _absoluteVariableTokenBalance = uint256(_variableTokenBalance);
            _isVariableTokenBalancePositive = true;
        } else {
            if (_isLM) {
                _devMulWad = marginCalculatorParameters.devMulRightUnwindLMWad;
                _fixedRateDeviationMinWad = marginCalculatorParameters
                    .fixedRateDeviationMinRightUnwindLMWad;
            } else {
                _devMulWad = marginCalculatorParameters.devMulRightUnwindIMWad;
                _fixedRateDeviationMinWad = marginCalculatorParameters
                    .fixedRateDeviationMinRightUnwindIMWad;
            }

            _absoluteVariableTokenBalance = uint256(-_variableTokenBalance);
        }

        // simulate an adversarial unwind (cumulative position is a Variable Taker --> simulate FT unwind --> movement to the left along the VAMM)
        // fixedTokenDelta unbalanced that results from the simulated unwind
        _fixedTokenDeltaUnbalanced = MarginCalculator
            .getAbsoluteFixedTokenDeltaUnbalancedSimulatedUnwind(
                uint256(_absoluteVariableTokenBalance),
                _sqrtPriceX96,
                _devMulWad,
                _fixedRateDeviationMinWad,
                _termEndTimestampWad,
                Time.blockTimestampScaled(),
                uint256(marginCalculatorParameters.tMaxWad),
                marginCalculatorParameters.gammaWad,
                _isVariableTokenBalancePositive
            )
            .toInt256();

        int256 _fixedTokenDelta = FixedAndVariableMath.getFixedTokenBalance(
            _isVariableTokenBalancePositive
                ? _fixedTokenDeltaUnbalanced
                : -_fixedTokenDeltaUnbalanced,
            -_variableTokenBalance,
            _rateOracle.variableFactor(
                _termStartTimestampWad,
                _termEndTimestampWad
            ),
            _termStartTimestampWad,
            _termEndTimestampWad
        );

        int256 _updatedFixedTokenBalance = _fixedTokenBalance +
            _fixedTokenDelta;

        _margin = __getMarginRequirement(_updatedFixedTokenBalance, 0, _isLM);

        if (
            _margin <
            marginCalculatorParameters.minMarginToIncentiviseLiquidators
        ) {
            _margin = marginCalculatorParameters
                .minMarginToIncentiviseLiquidators;
        }
    }

    function getPositionMarginRequirement(
        address _recipient,
        int24 _tickLower,
        int24 _tickUpper,
        bool _isLM
    ) external override returns (uint256) {
        Position.Info storage _position = positions.get(
            _recipient,
            _tickLower,
            _tickUpper
        );
        _updatePositionTokenBalancesAndAccountForFees(
            _position,
            _tickLower,
            _tickUpper,
            false
        ); // isMint=false
        
        emit PositionUpdate(
            _recipient,
            _tickLower,
            _tickUpper,
            _position._liquidity,
            _position.margin,
            _position.fixedTokenBalance,
            _position.variableTokenBalance,
            _position.accumulatedFees
        );

        return
            _getPositionMarginRequirement(
                _position,
                _tickLower,
                _tickUpper,
                _isLM
            );
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "prb-math/contracts/PRBMathUD60x18.sol";
import "prb-math/contracts/PRBMathSD59x18.sol";
import "../utils/TickMath.sol";
import "../utils/SqrtPriceMath.sol";
import "./FixedAndVariableMath.sol";
import "./Position.sol";
import "./Tick.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/IMarginEngine.sol";
import "../utils/FullMath.sol";
import "../utils/FixedPoint96.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

/// @title Margin Calculator
/// @notice Margin Calculator Performs the calculations necessary to establish Margin Requirements on Voltz Protocol
library MarginCalculator {
    using PRBMathSD59x18 for int256;
    using PRBMathUD60x18 for uint256;

    using SafeCast for uint256;
    using SafeCast for int256;

    // structs

    struct ApyBoundVars {
        /// @dev In the litepaper the timeFactor is exp(-beta*(t-s)/t_max) where t is the maturity timestamp, s is the current timestamp and beta is a diffusion process parameter set via calibration, t_max is the max possible duration of an IRS AMM
        int256 timeFactorWad;
        /// @dev 1 - timeFactor
        int256 oneMinusTimeFactorWad;
        /// @dev k = (4 * alpha/sigmaSquared)
        int256 kWad;
        /// @dev zeta = (sigmaSquared*(1-timeFactor))/ 4 * beta
        int256 zetaWad;
        /// @dev lambdaNum = 4 * beta * timeFactor * historicalApy
        int256 lambdaNumWad;
        /// @dev lambdaDen = sigmaSquared * (1 - timeFactor)
        int256 lambdaDenWad;
        /// @dev lambda = lambdaNum / lambdaDen
        int256 lambdaWad;
        /// @dev critical value multiplier = 2(k+2lambda)
        int256 criticalValueMultiplierWad;
        /// @dev critical value = sqrt(2(k+2*lambda))*xiUpper (for upper bound calculation), critical value = sqrt(2(k+2*lambda))*xiLower (for lower bound calculation)
        int256 criticalValueWad;
    }

    /// @dev Seconds in a year
    int256 public constant SECONDS_IN_YEAR = 31536000e18;

    uint256 public constant ONE_UINT = 1e18;
    int256 public constant ONE = 1e18;

    /// @dev In the litepaper the timeFactor is exp(-beta*(t-s)/t_max) where t is the maturity timestamp, and t_max is the max number of seconds for the IRS AMM duration, s is the current timestamp and beta is a diffusion process parameter set via calibration
    function computeTimeFactor(
        uint256 termEndTimestampWad,
        uint256 currentTimestampWad,
        IMarginEngine.MarginCalculatorParameters
            memory _marginCalculatorParameters
    ) internal pure returns (int256 timeFactorWad) {
        require(currentTimestampWad <= termEndTimestampWad, "CT<ET");

        int256 betaWad = _marginCalculatorParameters.betaWad;

        require(betaWad != 0, "B0");

        int256 tMaxWad = _marginCalculatorParameters.tMaxWad;

        int256 scaledTimeWad = (int256(termEndTimestampWad) -
            int256(currentTimestampWad)).div(tMaxWad);

        int256 expInputWad = scaledTimeWad.mul(-betaWad);

        timeFactorWad = expInputWad.exp();
    }

    /// @notice Calculates an APY Upper or Lower Bound of a given underlying pool (e.g. Aave v2 USDC Lending Pool)
    /// @param termEndTimestampWad termEndTimestampScaled
    /// @param currentTimestampWad currentTimestampScaled
    /// @param historicalApyWad Geometric Mean Time Weighted Average APY (TWAPPY) of the underlying pool (e.g. Aave v2 USDC Lending Pool)
    /// @param isUpper isUpper = true ==> calculating the APY Upper Bound, otherwise APY Lower Bound
    /// @param _marginCalculatorParameters Margin Calculator Parameters (more details in the litepaper) necessary to compute position margin requirements
    /// @return apyBoundWad APY Upper or Lower Bound of a given underlying pool (e.g. Aave v2 USDC Lending Pool)
    function computeApyBound(
        uint256 termEndTimestampWad,
        uint256 currentTimestampWad,
        uint256 historicalApyWad,
        bool isUpper,
        IMarginEngine.MarginCalculatorParameters
            memory _marginCalculatorParameters
    ) internal pure returns (uint256 apyBoundWad) {
        ApyBoundVars memory apyBoundVars;

        int256 beta4Wad = _marginCalculatorParameters.betaWad << 2;
        int256 alpha4Wad = _marginCalculatorParameters.alphaWad << 2;

        apyBoundVars.timeFactorWad = computeTimeFactor(
            termEndTimestampWad,
            currentTimestampWad,
            _marginCalculatorParameters
        );

        apyBoundVars.oneMinusTimeFactorWad = ONE - apyBoundVars.timeFactorWad; // ONE is in wei

        apyBoundVars.kWad = alpha4Wad.div(
            _marginCalculatorParameters.sigmaSquaredWad
        );
        apyBoundVars.zetaWad = (
            _marginCalculatorParameters.sigmaSquaredWad.mul(
                apyBoundVars.oneMinusTimeFactorWad
            )
        ).div(beta4Wad);
        apyBoundVars.lambdaNumWad = beta4Wad
            .mul(apyBoundVars.timeFactorWad)
            .mul(int256(historicalApyWad));
        apyBoundVars.lambdaDenWad = _marginCalculatorParameters
            .sigmaSquaredWad
            .mul(apyBoundVars.oneMinusTimeFactorWad);
        apyBoundVars.lambdaWad = apyBoundVars.lambdaNumWad.div(
            apyBoundVars.lambdaDenWad
        );

        apyBoundVars.criticalValueMultiplierWad =
            ((apyBoundVars.lambdaWad << 1) + apyBoundVars.kWad) <<
            1;

        apyBoundVars.criticalValueWad = apyBoundVars
            .criticalValueMultiplierWad
            .sqrt()
            .mul(
                (isUpper)
                    ? _marginCalculatorParameters.xiUpperWad
                    : _marginCalculatorParameters.xiLowerWad
            );

        int256 apyBoundIntWad = apyBoundVars.zetaWad.mul(
            apyBoundVars.kWad +
                apyBoundVars.lambdaWad +
                (
                    isUpper
                        ? apyBoundVars.criticalValueWad
                        : -apyBoundVars.criticalValueWad
                )
        );

        if (apyBoundIntWad < 0) {
            apyBoundWad = 0;
        } else {
            apyBoundWad = uint256(apyBoundIntWad);
        }
    }

    /// @notice Calculates the Worst Case Variable Factor At Maturity
    /// @param timeInSecondsFromStartToMaturityWad Duration of a given IRS AMM (18 decimals)
    /// @param termEndTimestampWad termEndTimestampWad
    /// @param currentTimestampWad currentTimestampWad
    /// @param isFT isFT => we are dealing with a Fixed Taker (short) IRS position, otherwise it is a Variable Taker (long) IRS position
    /// @param isLM isLM => we are computing a Liquidation Margin otherwise computing an Initial Margin
    /// @param historicalApyWad Historical Average APY of the underlying pool (e.g. Aave v2 USDC Lending Pool)
    /// @param _marginCalculatorParameters Margin Calculator Parameters (more details in the litepaper) necessary to compute position margin requirements
    /// @return variableFactorWad The Worst Case Variable Factor At Maturity = APY Bound * accrualFactor(timeInYearsFromStartUntilMaturity) where APY Bound = APY Upper Bound for Fixed Takers and APY Lower Bound for Variable Takers (18 decimals)
    function worstCaseVariableFactorAtMaturity(
        uint256 timeInSecondsFromStartToMaturityWad,
        uint256 termEndTimestampWad,
        uint256 currentTimestampWad,
        bool isFT,
        bool isLM,
        uint256 historicalApyWad,
        IMarginEngine.MarginCalculatorParameters
            memory _marginCalculatorParameters
    ) internal pure returns (uint256 variableFactorWad) {
        uint256 timeInYearsFromStartUntilMaturityWad = FixedAndVariableMath
            .accrualFact(timeInSecondsFromStartToMaturityWad);

        variableFactorWad = computeApyBound(
            termEndTimestampWad,
            currentTimestampWad,
            historicalApyWad,
            isFT,
            _marginCalculatorParameters
        ).mul(timeInYearsFromStartUntilMaturityWad);

        if (!isLM) {
            variableFactorWad = variableFactorWad.mul(
                isFT
                    ? _marginCalculatorParameters.apyUpperMultiplierWad
                    : _marginCalculatorParameters.apyLowerMultiplierWad
            );
        }
    }

    struct SimulatedUnwindLocalVars {
        uint256 sqrtRatioCurrWad;
        uint256 fixedRateStartWad;
        uint256 upperDWad;
        uint256 scaledTimeWad;
        int256 expInputWad;
        int256 oneMinusTimeFactorWad;
        uint256 dWad;
        uint256 fixedRateCFWad;
        uint256 fixedTokenDeltaUnbalancedWad;
    }

    /// @notice calculates the absolute fixed token delta unbalanced resulting from a simulated counterfactual unwind necessary to determine the minimum margin requirement of a trader
    /// @dev simulation of a swap without the need to involve the swap function
    /// @param variableTokenDeltaAbsolute absolute value of the variableTokenDelta for which the unwind is simulated
    /// @param sqrtRatioCurrX96 sqrtRatio necessary to calculate the starting fixed rate which is used to calculate the counterfactual unwind fixed rate
    /// @param startingFixedRateMultiplierWad the multiplier (lambda from the litepaper - minimum margin requirement equation) that is multiplied by the starting fixed rate to determine the deviation applied to the starting fixed rate (in Wad)
    /// @param fixedRateDeviationMinWad The minimum value the variable D (from the litepaper) can take
    /// @param termEndTimestampWad term end timestamp in wad
    /// @param currentTimestampWad current timestamp in wad
    /// @param tMaxWad the maximum duration for a Voltz Protocol IRS AMM
    /// @param gammaWad adjustable parameter that controls the rate of time decay applied to the deviation depending on time from now to maturity
    /// @param isFTUnwind isFTUnwind == true => the counterfactual unwind is in the Fixed Taker direction (from left to right along the VAMM), the opposite is true if isFTUnwind == false
    function getAbsoluteFixedTokenDeltaUnbalancedSimulatedUnwind(
        uint256 variableTokenDeltaAbsolute,
        uint160 sqrtRatioCurrX96,
        uint256 startingFixedRateMultiplierWad,
        uint256 fixedRateDeviationMinWad,
        uint256 termEndTimestampWad,
        uint256 currentTimestampWad,
        uint256 tMaxWad,
        uint256 gammaWad,
        bool isFTUnwind
    ) internal pure returns (uint256 fixedTokenDeltaUnbalanced) {
        SimulatedUnwindLocalVars memory simulatedUnwindLocalVars;

        // require checks

        // calculate fixedRateStart

        simulatedUnwindLocalVars.sqrtRatioCurrWad = FullMath.mulDiv(
            ONE_UINT,
            sqrtRatioCurrX96,
            FixedPoint96.Q96
        );

        simulatedUnwindLocalVars.fixedRateStartWad = ONE_UINT.div(
            simulatedUnwindLocalVars.sqrtRatioCurrWad.mul(
                simulatedUnwindLocalVars.sqrtRatioCurrWad
            )
        );

        // calculate D (from the litepaper)
        simulatedUnwindLocalVars.upperDWad = simulatedUnwindLocalVars
            .fixedRateStartWad
            .mul(startingFixedRateMultiplierWad);

        if (simulatedUnwindLocalVars.upperDWad < fixedRateDeviationMinWad) {
            simulatedUnwindLocalVars.upperDWad = fixedRateDeviationMinWad;
        }

        // calculate d (from the litepaper)

        simulatedUnwindLocalVars.scaledTimeWad = (termEndTimestampWad -
            currentTimestampWad).div(tMaxWad);

        simulatedUnwindLocalVars.expInputWad = simulatedUnwindLocalVars
            .scaledTimeWad
            .toInt256()
            .mul(-gammaWad.toInt256());
        simulatedUnwindLocalVars.oneMinusTimeFactorWad =
            ONE -
            simulatedUnwindLocalVars.expInputWad.exp();

        /// @audit-casting simulatedUnwindLocalVars.oneMinusTimeFactorWad is expected to be positive here, but what if goes below 0 due to rounding imprecision?
        simulatedUnwindLocalVars.dWad = simulatedUnwindLocalVars.upperDWad.mul(
            simulatedUnwindLocalVars.oneMinusTimeFactorWad.toUint256()
        );

        // calculate counterfactual fixed rate

        if (isFTUnwind) {
            if (
                simulatedUnwindLocalVars.fixedRateStartWad >
                simulatedUnwindLocalVars.dWad
            ) {
                simulatedUnwindLocalVars.fixedRateCFWad =
                    simulatedUnwindLocalVars.fixedRateStartWad -
                    simulatedUnwindLocalVars.dWad;
            } else {
                simulatedUnwindLocalVars.fixedRateCFWad = 0;
            }
        } else {
            simulatedUnwindLocalVars.fixedRateCFWad =
                simulatedUnwindLocalVars.fixedRateStartWad +
                simulatedUnwindLocalVars.dWad;
        }

        // calculate fixedTokenDeltaUnbalancedWad

        simulatedUnwindLocalVars
            .fixedTokenDeltaUnbalancedWad = variableTokenDeltaAbsolute
            .fromUint()
            .mul(simulatedUnwindLocalVars.fixedRateCFWad);

        // calculate fixedTokenDeltaUnbalanced

        fixedTokenDeltaUnbalanced = simulatedUnwindLocalVars
            .fixedTokenDeltaUnbalancedWad
            .toUint();
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../interfaces/IERC20Minimal.sol";
import "../interfaces/fcms/IFCM.sol";
import "../interfaces/IMarginEngine.sol";
import "../interfaces/IVAMM.sol";

contract MarginEngineStorageV1 {
    // Any variables that would implicitly implement an IMarginEngine function if public, must instead
    // be internal due to limitations in the solidity compiler (as of 0.8.12)
    uint256 internal _liquidatorRewardWad;
    IERC20Minimal internal _underlyingToken;
    uint256 internal _termStartTimestampWad;
    uint256 internal _termEndTimestampWad;
    IFCM internal _fcm;
    mapping(bytes32 => Position.Info) internal positions;
    IVAMM internal _vamm;
    uint256 internal _secondsAgo;
    uint256 internal cachedHistoricalApyWad;
    uint256 internal cachedHistoricalApyWadRefreshTimestamp;
    uint256 internal _cacheMaxAgeInSeconds;
    IFactory internal _factory;
    IRateOracle internal _rateOracle;
    IMarginEngine.MarginCalculatorParameters
        internal marginCalculatorParameters;
}

contract MarginEngineStorage is MarginEngineStorageV1 {
    // Reserve some storage for use in future versions, without creating conflicts
    // with other inheritted contracts
    uint256[69] private __gap; // total storage = 100 slots, including structs
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;

// needs to be refactored for the new setup

import "../MarginEngine.sol";
import "../core_libraries/Position.sol";

contract TestMarginEngine is MarginEngine {
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;

    uint256 public keepInMindMargin;

    function updatePositionTokenBalancesAndAccountForFeesTest(
        address owner,
        int24 tickLower,
        int24 tickUpper,
        bool isMintBurn
    ) external {
        Position.Info storage position = positions.get(
            owner,
            tickLower,
            tickUpper
        );

        _updatePositionTokenBalancesAndAccountForFees(
            position,
            tickLower,
            tickUpper,
            isMintBurn
        );
    }

    function getUnderlyingToken()
        external
        pure
        returns (address underlyingToken)
    {
        return underlyingToken;
    }

    function checkPositionMarginCanBeUpdatedTest(
        address owner,
        int24 tickLower,
        int24 tickUpper,
        uint128 counterfactualLiquidity,
        int256 counterfactualFixedTokenBalance,
        int256 counterfactualVariableTokenBalance,
        int256 counterfactualMargin
    ) public {
        Position.Info storage position = positions.get(
            owner,
            tickLower,
            tickUpper
        );

        uint128 originalLiquidity = position._liquidity;
        int256 originalFixedTokenBalance = position.fixedTokenBalance;
        int256 originalVariableTokenBalance = position.variableTokenBalance;
        int256 originalMargin = position.margin;

        position._liquidity = counterfactualLiquidity;
        position.fixedTokenBalance = counterfactualFixedTokenBalance;
        position.variableTokenBalance = counterfactualVariableTokenBalance;
        position.margin = counterfactualMargin;

        _checkPositionMarginCanBeUpdated(position, tickLower, tickUpper);

        position._liquidity = originalLiquidity;
        position.fixedTokenBalance = originalFixedTokenBalance;
        position.variableTokenBalance = originalVariableTokenBalance;
        position.margin = originalMargin;
    }

    function checkPositionMarginAboveRequirementTest(
        address owner,
        int24 tickLower,
        int24 tickUpper,
        uint128 counterfactualLiquidity,
        int256 counterfactualFixedTokenBalance,
        int256 counterfactualVariableTokenBalance,
        int256 counterfactualMargin
    ) public {
        Position.Info storage position = positions.get(
            owner,
            tickLower,
            tickUpper
        );

        uint128 originalLiquidity = position._liquidity;
        int256 originalFixedTokenBalance = position.fixedTokenBalance;
        int256 originalVariableTokenBalance = position.variableTokenBalance;
        int256 originalMargin = position.margin;

        position._liquidity = counterfactualLiquidity;
        position.fixedTokenBalance = counterfactualFixedTokenBalance;
        position.variableTokenBalance = counterfactualVariableTokenBalance;
        position.margin = counterfactualMargin;

        _checkPositionMarginAboveRequirement(position, tickLower, tickUpper);

        position._liquidity = originalLiquidity;
        position.fixedTokenBalance = originalFixedTokenBalance;
        position.variableTokenBalance = originalVariableTokenBalance;
        position.margin = originalMargin;
    }

    function getCounterfactualMarginRequirementTest(
        address owner,
        int24 tickLower,
        int24 tickUpper,
        uint128 counterfactualLiquidity,
        int256 counterfactualFixedTokenBalance,
        int256 counterfactualVariableTokenBalance,
        int256 counterfactualMargin,
        bool isLM
    ) external {
        Position.Info storage position = positions.get(
            owner,
            tickLower,
            tickUpper
        );

        uint128 originalLiquidity = position._liquidity;
        int256 originalFixedTokenBalance = position.fixedTokenBalance;
        int256 originalVariableTokenBalance = position.variableTokenBalance;
        int256 originalMargin = position.margin;

        position._liquidity = counterfactualLiquidity;
        position.fixedTokenBalance = counterfactualFixedTokenBalance;
        position.variableTokenBalance = counterfactualVariableTokenBalance;
        position.margin = counterfactualMargin;

        keepInMindMargin = _getPositionMarginRequirement(
            position,
            tickLower,
            tickUpper,
            isLM
        );

        position._liquidity = originalLiquidity;
        position.fixedTokenBalance = originalFixedTokenBalance;
        position.variableTokenBalance = originalVariableTokenBalance;
        position.margin = originalMargin;
    }

    function setPosition(
        address owner,
        int24 tickLower,
        int24 tickUpper,
        uint128 _liquidity,
        int256 margin,
        int256 fixedTokenGrowthInsideLastX128,
        int256 variableTokenGrowthInsideLastX128,
        int256 fixedTokenBalance,
        int256 variableTokenBalance,
        uint256 feeGrowthInsideLastX128,
        bool isSettled
    ) external {
        positions[
            keccak256(abi.encodePacked(owner, tickLower, tickUpper))
        ] = Position.Info({
            _liquidity: _liquidity,
            margin: margin,
            fixedTokenGrowthInsideLastX128: fixedTokenGrowthInsideLastX128,
            variableTokenGrowthInsideLastX128: variableTokenGrowthInsideLastX128,
            fixedTokenBalance: fixedTokenBalance,
            variableTokenBalance: variableTokenBalance,
            feeGrowthInsideLastX128: feeGrowthInsideLastX128,
            isSettled: isSettled,
            rewardPerAmount: 0,
            accumulatedFees: 0
        });
    }

    function unwindPositionTest(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) public {
        Position.Info storage position = positions.get(
            owner,
            tickLower,
            tickUpper
        );
        _unwindPosition(position, owner, tickLower, tickUpper);
    }

    function getCachedHistoricalApy() external view returns (uint256) {
        return cachedHistoricalApyWad;
    }

    function getPositionMarginRequirementTest(
        address owner,
        int24 tickLower,
        int24 tickUpper,
        bool isLM
    ) external {
        Position.Info storage position = positions.get(
            owner,
            tickLower,
            tickUpper
        );
        keepInMindMargin = _getPositionMarginRequirement(
            position,
            tickLower,
            tickUpper,
            isLM
        );
    }

    function getMargin() external view returns (uint256) {
        return keepInMindMargin;
    }

    function getMarginRequirementTest(
        int256 fixedTokenBalance,
        int256 variableTokenBalance,
        bool isLM,
        uint160 sqrtPriceX96
    ) external {
        keepInMindMargin = _getMarginRequirement(
            fixedTokenBalance,
            variableTokenBalance,
            isLM,
            sqrtPriceX96
        );
    }

    bool keepInMindIsLiquidatable;

    function isCounterfactualPositionLiquidatable(
        address owner,
        int24 tickLower,
        int24 tickUpper,
        uint128 counterfactualLiquidity,
        int256 counterfactualFixedTokenBalance,
        int256 counterfactualVariableTokenBalance,
        int256 counterfactualMargin
    ) external {
        Position.Info storage position = positions.get(
            owner,
            tickLower,
            tickUpper
        );

        uint128 originalLiquidity = position._liquidity;
        int256 originalFixedTokenBalance = position.fixedTokenBalance;
        int256 originalVariableTokenBalance = position.variableTokenBalance;
        int256 originalMargin = position.margin;

        position._liquidity = counterfactualLiquidity;
        position.fixedTokenBalance = counterfactualFixedTokenBalance;
        position.variableTokenBalance = counterfactualVariableTokenBalance;
        position.margin = counterfactualMargin;

        (keepInMindIsLiquidatable, ) = _isLiquidatablePosition(
            position,
            tickLower,
            tickUpper
        );

        position._liquidity = originalLiquidity;
        position.fixedTokenBalance = originalFixedTokenBalance;
        position.variableTokenBalance = originalVariableTokenBalance;
        position.margin = originalMargin;
    }

    function isLiquidatablePositionTest(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) external {
        Position.Info storage position = positions.get(
            owner,
            tickLower,
            tickUpper
        );

        (keepInMindIsLiquidatable, ) = _isLiquidatablePosition(
            position,
            tickLower,
            tickUpper
        );
    }

    function getIsLiquidatable() external view returns (bool) {
        return keepInMindIsLiquidatable;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;

import "contracts/test/Actor.sol";
import "contracts/test/TestMarginEngine.sol";
import "contracts/test/TestVAMM.sol";
import "contracts/test/TestAaveFCM.sol";
import "contracts/utils/Printer.sol";
import "../interfaces/aave/IAaveV2LendingPool.sol";
import "../interfaces/rate_oracles/IAaveRateOracle.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/IPeriphery.sol";
import "../utils/WadRayMath.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "contracts/utils/CustomErrors.sol";

contract E2ESetup is CustomErrors {
    struct UniqueIdentifiersPosition {
        address owner;
        int24 tickLower;
        int24 tickUpper;
    }

    struct PositionSnapshot {
        uint256 currentTimestampWad;
        uint256 termStartTimestampWad;
        uint256 termEndTimestampWad;
        int256 margin;
        uint256 marginRequirement;
        int256 estimatedSettlementCashflow;
        int256 fixedTokenBalance;
        int256 variableTokenBalance;
    }

    struct SwapSnapshot {
        uint256 reserveNormalizedIncomeAtSwap;
        uint256 swapInitiationTimestampWad;
        uint256 termEndTimestampWad;
        uint256 notional;
        bool isFT;
        uint256 fixedRateWad;
        uint256 feePaidInUnderlyingTokens;
    }

    function abs(int256 value) public pure returns (uint256) {
        if (value < 0) return uint256(-value);
        else return uint256(value);
    }

    using WadRayMath for uint256;
    using SafeMath for uint256;

    mapping(uint256 => UniqueIdentifiersPosition) public allPositions;
    mapping(bytes32 => uint256) public indexAllPositions;
    uint256 public sizeAllPositions = 0;

    mapping(uint256 => address) public allYBATraders;
    mapping(address => uint256) public indexAllYBATraders;
    uint256 public sizeAllYBATraders = 0;

    mapping(bytes32 => mapping(uint256 => PositionSnapshot))
        public positionHistory;
    mapping(bytes32 => uint256) public sizeOfPositionHistory;

    mapping(bytes32 => mapping(uint256 => SwapSnapshot))
        public positionSwapsHistory;
    mapping(bytes32 => uint256) public sizeOfPositionSwapsHistory;

    int256 public initialCashflow = 0;
    int256 public liquidationRewards = 0;
    int256 public fcmFees = 0;

    uint256 public keepInMindGas;

    // function getReserveNormalizedIncome() internal view returns (uint256) {
    //     IRateOracle rateOracle = IMarginEngine(MEAddress).rateOracle();
    //     IAaveV2LendingPool aaveLendingPool = IAaveV2LendingPool(
    //         IAaveRateOracle(address(rateOracle)).aaveLendingPool()
    //     );
    //     uint256 reserveNormalizedIncome = aaveLendingPool
    //         .getReserveNormalizedIncome(
    //             IMarginEngine(MEAddress).underlyingToken()
    //         );
    //     return reserveNormalizedIncome;
    // }

    function addSwapSnapshot(
        address owner,
        int24 tickLower,
        int24 tickUpper,
        int256 variableTokenDelta,
        int256 fixedTokenDeltaUnbalanced,
        uint256 cumulativeFeeIncurred
    ) public {
        bytes32 hashedPositon = keccak256(
            abi.encodePacked(owner, tickLower, tickUpper)
        );

        uint256 termEndTimestampWad = IMarginEngine(MEAddress)
            .termEndTimestampWad();

        uint256 fixedRateWad = PRBMathUD60x18.div(
            PRBMathUD60x18.div(
                PRBMathUD60x18.fromUint(abs(fixedTokenDeltaUnbalanced)),
                PRBMathUD60x18.fromUint(abs(variableTokenDelta))
            ),
            PRBMathUD60x18.fromUint(100)
        );

        // get the current reserve normalized income from Aave
        // uint256 reserveNormalizedIncome = getReserveNormalizedIncome();
        uint256 reserveNormalizedIncome = 1;

        SwapSnapshot memory swapSnapshot = SwapSnapshot({
            reserveNormalizedIncomeAtSwap: reserveNormalizedIncome,
            swapInitiationTimestampWad: Time.blockTimestampScaled(),
            termEndTimestampWad: termEndTimestampWad,
            notional: abs(variableTokenDelta),
            isFT: variableTokenDelta > 0 ? false : true,
            fixedRateWad: fixedRateWad,
            feePaidInUnderlyingTokens: cumulativeFeeIncurred
        });

        sizeOfPositionSwapsHistory[hashedPositon] += 1;
        positionSwapsHistory[hashedPositon][
            sizeOfPositionSwapsHistory[hashedPositon]
        ] = swapSnapshot;
    }

    function addPosition(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) public {
        bytes32 hashedPositon = keccak256(
            abi.encodePacked(owner, tickLower, tickUpper)
        );
        if (indexAllPositions[hashedPositon] > 0) {
            return;
        }
        sizeAllPositions += 1;
        allPositions[sizeAllPositions] = UniqueIdentifiersPosition(
            owner,
            tickLower,
            tickUpper
        );
        indexAllPositions[hashedPositon] = sizeAllPositions;
    }

    function addYBATrader(address trader) public {
        if (indexAllYBATraders[trader] > 0) {
            return;
        }
        sizeAllYBATraders += 1;
        allYBATraders[sizeAllYBATraders] = trader;
        indexAllYBATraders[trader] = sizeAllYBATraders;
    }

    address public MEAddress;
    address public VAMMAddress;
    address public FCMAddress;
    address public rateOracleAddress;
    address public peripheryAddress;

    function setPeripheryAddress(address _peripheryAddress) public {
        console.log("set _peripheryAddress", _peripheryAddress);
        peripheryAddress = _peripheryAddress;
    }

    function setMEAddress(address _MEAddress) public {
        MEAddress = _MEAddress;
    }

    function setVAMMAddress(address _VAMMAddress) public {
        VAMMAddress = _VAMMAddress;
    }

    function setFCMAddress(address _FCMAddress) public {
        FCMAddress = _FCMAddress;
    }

    function setRateOracleAddress(address _rateOracleAddress) public {
        rateOracleAddress = _rateOracleAddress;
    }

    function initiateFullyCollateralisedFixedTakerSwap(
        address trader,
        uint256 notional,
        uint160 sqrtPriceLimitX96
    ) external {
        addYBATrader(trader);

        uint256 MEBalanceBefore = IERC20Minimal(
            IMarginEngine(MEAddress).underlyingToken()
        ).balanceOf(MEAddress);

        Actor(trader).initiateFullyCollateralisedFixedTakerSwap(
            FCMAddress,
            notional,
            sqrtPriceLimitX96
        );

        uint256 MEBalanceAfter = IERC20Minimal(
            IMarginEngine(MEAddress).underlyingToken()
        ).balanceOf(MEAddress);

        fcmFees += int256(MEBalanceAfter) - int256(MEBalanceBefore);

        continuousInvariants();
    }

    function unwindFullyCollateralisedFixedTakerSwap(
        address trader,
        uint256 notionalToUnwind,
        uint160 sqrtPriceLimitX96
    ) external {
        addYBATrader(trader);

        uint256 MEBalanceBefore = IERC20Minimal(
            IMarginEngine(MEAddress).underlyingToken()
        ).balanceOf(MEAddress);

        Actor(trader).unwindFullyCollateralisedFixedTakerSwap(
            FCMAddress,
            notionalToUnwind,
            sqrtPriceLimitX96
        );

        uint256 MEBalanceAfter = IERC20Minimal(
            IMarginEngine(MEAddress).underlyingToken()
        ).balanceOf(MEAddress);

        fcmFees += int256(MEBalanceAfter) - int256(MEBalanceBefore);

        continuousInvariants();
    }

    function settleYBATrader(address trader) external {
        addYBATrader(trader);

        Actor(trader).settleYBATrader(FCMAddress);
    }

    function settlePositionViaAMM(
        address recipient,
        int24 tickLower,
        int24 tickUpper
    ) external {
        addPosition(recipient, tickLower, tickUpper);

        Actor(recipient).settlePositionViaAMM(
            MEAddress,
            recipient,
            tickLower,
            tickUpper
        );
    }

    function mintOrBurnViaPeriphery(
        address trader,
        IPeriphery.MintOrBurnParams memory params
    ) public returns (int256 positionMarginRequirement) {
        addPosition(trader, params.tickLower, params.tickUpper);
        positionMarginRequirement = Actor(trader).mintOrBurnViaPeriphery(
            peripheryAddress,
            params
        );
    }

    function swapViaPeriphery(
        address trader,
        IPeriphery.SwapPeripheryParams memory params
    )
        public
        returns (
            int256 _fixedTokenDelta,
            int256 _variableTokenDelta,
            uint256 _cumulativeFeeIncurred,
            int256 _fixedTokenDeltaUnbalanced,
            int256 _marginRequirement
        )
    {
        addPosition(trader, params.tickLower, params.tickUpper);
        (
            _fixedTokenDelta,
            _variableTokenDelta,
            _cumulativeFeeIncurred,
            _fixedTokenDeltaUnbalanced,
            _marginRequirement
        ) = Actor(trader).swapViaPeriphery(peripheryAddress, params);
    }

    function mintViaAMM(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) public returns (int256 positionMarginRequirement) {
        this.addPosition(recipient, tickLower, tickUpper);

        uint256 gasBefore = gasleft();
        positionMarginRequirement = Actor(recipient).mintViaAMM(
            VAMMAddress,
            recipient,
            tickLower,
            tickUpper,
            amount
        );
        keepInMindGas = gasBefore - gasleft();

        continuousInvariants();
    }

    function burnViaAMM(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) public {
        this.addPosition(recipient, tickLower, tickUpper);

        uint256 gasBefore = gasleft();
        Actor(recipient).burnViaAMM(
            VAMMAddress,
            recipient,
            tickLower,
            tickUpper,
            amount
        );
        keepInMindGas = gasBefore - gasleft();

        continuousInvariants();
    }

    function swapViaAMM(IVAMM.SwapParams memory params)
        public
        returns (
            int256 _fixedTokenDelta,
            int256 _variableTokenDelta,
            uint256 _cumulativeFeeIncurred,
            int256 _fixedTokenDeltaUnbalanced,
            int256 _marginRequirement
        )
    {
        this.addPosition(params.recipient, params.tickLower, params.tickUpper);

        uint256 gasBefore = gasleft();
        (
            _fixedTokenDelta,
            _variableTokenDelta,
            _cumulativeFeeIncurred,
            _fixedTokenDeltaUnbalanced,
            _marginRequirement
        ) = Actor(params.recipient).swapViaAMM(VAMMAddress, params);
        keepInMindGas = gasBefore - gasleft();

        continuousInvariants();

        this.addSwapSnapshot(
            params.recipient,
            params.tickLower,
            params.tickUpper,
            _fixedTokenDeltaUnbalanced,
            _variableTokenDelta,
            _cumulativeFeeIncurred
        );
    }

    function liquidatePosition(
        address liquidator,
        int24 lowerTickLiquidator,
        int24 upperTickLiquidator,
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) external {
        this.addPosition(liquidator, lowerTickLiquidator, upperTickLiquidator);
        this.addPosition(owner, tickLower, tickUpper);

        uint256 liquidatorBalanceBefore = IERC20Minimal(
            IMarginEngine(MEAddress).underlyingToken()
        ).balanceOf(liquidator);

        Actor(liquidator).liquidatePosition(
            MEAddress,
            tickLower,
            tickUpper,
            owner
        );

        uint256 liquidatorBalanceAfter = IERC20Minimal(
            IMarginEngine(MEAddress).underlyingToken()
        ).balanceOf(liquidator);

        require(
            liquidatorBalanceBefore <= liquidatorBalanceAfter,
            "liquidation reward should be positive"
        );

        liquidationRewards +=
            int256(liquidatorBalanceAfter) -
            int256(liquidatorBalanceBefore);

        continuousInvariants();
    }

    function setIntegrationApproval(
        address recipient,
        address intAddress,
        bool allowIntegration
    ) external {
        Actor(recipient).setIntegrationApproval(
            MEAddress,
            intAddress,
            allowIntegration
        );
    }

    function estimatedVariableFactorFromStartToMaturity()
        internal
        returns (uint256 _estimatedVariableFactorFromStartToMaturity)
    {
        uint256 historicalAPYWad = IMarginEngine(MEAddress).getHistoricalApy();

        uint256 termStartTimestampWad = IMarginEngine(MEAddress)
            .termStartTimestampWad();
        uint256 termEndTimestampWad = IMarginEngine(MEAddress)
            .termEndTimestampWad();

        uint256 termInYears = FixedAndVariableMath.accrualFact(
            termEndTimestampWad - termStartTimestampWad
        );

        // calculate the estimated variable factor from start to maturity
        _estimatedVariableFactorFromStartToMaturity =
            PRBMathUD60x18.pow(
                (PRBMathUD60x18.fromUint(1) + historicalAPYWad),
                termInYears
            ) -
            PRBMathUD60x18.fromUint(1);
    }

    function updatePositionMarginViaAMM(
        address _owner,
        int24 tickLower,
        int24 tickUpper,
        int256 marginDelta
    ) public {
        this.addPosition(_owner, tickLower, tickUpper);

        uint256 gasBefore = gasleft();
        Actor(_owner).updatePositionMarginViaAMM(
            MEAddress,
            _owner,
            tickLower,
            tickUpper,
            marginDelta
        );
        keepInMindGas = gasBefore - gasleft();
        initialCashflow += marginDelta;

        if (
            PRBMathUD60x18.fromUint(block.timestamp) <
            IMarginEngine(MEAddress).termEndTimestampWad()
        ) continuousInvariants();
    }

    // function computeSettlementCashflowForSwapSnapshot(
    //     SwapSnapshot memory snapshot
    // ) internal view returns (int256 settlementCashflow) {
    //     // calculate the variable factor for the period the swap was active
    //     // needs to be called at the same time as the term end timestamp, otherwise need to cache the reserve normalised income for the term end timestamp in the E2E setup

    //     uint256 reserveNormalizedIncomeRay = getReserveNormalizedIncome();
    //     uint256 reserveNormalizedIncomeAtSwapInceptionRay = snapshot
    //         .reserveNormalizedIncomeAtSwap;
    //     uint256 variableFactorFromSwapInceptionToMaturityWad = WadRayMath
    //         .rayToWad(
    //             WadRayMath
    //                 .rayDiv(
    //                     reserveNormalizedIncomeRay,
    //                     reserveNormalizedIncomeAtSwapInceptionRay
    //                 )
    //                 .sub(WadRayMath.RAY)
    //         );

    //     // swapInitiationTimestampWad
    //     uint256 termEndTimestampWad = IMarginEngine(MEAddress)
    //         .termEndTimestampWad();

    //     uint256 timeInSecondsBetweenSwapInitiationAndMaturityWad = termEndTimestampWad -
    //             snapshot.swapInitiationTimestampWad;
    //     uint256 timeInYearsWad = FixedAndVariableMath.accrualFact(
    //         timeInSecondsBetweenSwapInitiationAndMaturityWad
    //     );

    //     uint256 fixedFactorWad = PRBMathUD60x18.mul(
    //         snapshot.fixedRateWad,
    //         timeInYearsWad
    //     );

    //     int256 variableFixedFactorDelta;
    //     if (snapshot.isFT) {
    //         variableFixedFactorDelta =
    //             int256(fixedFactorWad) -
    //             int256(variableFactorFromSwapInceptionToMaturityWad);
    //     } else {
    //         variableFixedFactorDelta =
    //             int256(variableFactorFromSwapInceptionToMaturityWad) -
    //             int256(fixedFactorWad);
    //     }

    //     int256 settlementCashflowWad = PRBMathSD59x18.mul(
    //         int256(snapshot.notional),
    //         variableFixedFactorDelta
    //     );
    //     settlementCashflow = PRBMathSD59x18.toInt(settlementCashflowWad);
    // }

    // function settlementCashflowBasedOnSwapSnapshots(
    //     address _owner,
    //     int24 tickLower,
    //     int24 tickUpper
    // ) public view returns (int256) {
    //     (
    //         SwapSnapshot[] memory snapshots,
    //         uint256 len
    //     ) = getPositionSwapsHistory(_owner, tickLower, tickUpper);

    //     int256 settlementCashflow;

    //     for (uint256 i = 0; i < len; i++) {
    //         settlementCashflow += computeSettlementCashflowForSwapSnapshot(
    //             snapshots[i]
    //         );
    //     }

    //     return settlementCashflow;
    // }

    // function invariantPostMaturity() public {
    //     // calculate the cashflows for each position based on their swap snapshots and based on their fixed and variable token balances
    //     // this only works for Positins that have not minted liquidity since their settlementCashflow is also a function of trades in their tick range
    //     // assume in this scenarios all the swapper only swap

    //     uint256 termStartTimestampWad = uint256(
    //         IMarginEngine(MEAddress).termStartTimestampWad()
    //     );
    //     uint256 termEndTimestampWad = uint256(
    //         IMarginEngine(MEAddress).termEndTimestampWad()
    //     );

    //     for (uint256 i = 1; i <= sizeAllPositions; i++) {
    //         uint256 variableFactor = IRateOracle(rateOracleAddress)
    //             .variableFactor(termStartTimestampWad, termEndTimestampWad);

    //         TestMarginEngine(MEAddress)
    //             .updatePositionTokenBalancesAndAccountForFeesTest(
    //                 allPositions[i].owner,
    //                 allPositions[i].tickLower,
    //                 allPositions[i].tickUpper,
    //                 false
    //             );

    //         Position.Info memory position = IMarginEngine(MEAddress)
    //             .getPosition(
    //                 allPositions[i].owner,
    //                 allPositions[i].tickLower,
    //                 allPositions[i].tickUpper
    //             );

    //         int256 settlementCashflow = FixedAndVariableMath
    //             .calculateSettlementCashflow(
    //                 position.fixedTokenBalance,
    //                 position.variableTokenBalance,
    //                 termStartTimestampWad,
    //                 termEndTimestampWad,
    //                 variableFactor
    //             );

    //         int256 settlementCashflowSS = settlementCashflowBasedOnSwapSnapshots(
    //                 allPositions[i].owner,
    //                 allPositions[i].tickLower,
    //                 allPositions[i].tickUpper
    //             );

    //         int256 approximation = 100000;

    //         int256 delta = settlementCashflow - settlementCashflowSS;

    //         require(
    //             abs(delta) < uint256(approximation),
    //             "settlement cashflows from swap snapshots"
    //         );
    //     }
    // }

    function continuousInvariants() public {
        int256 totalFixedTokens = 0;
        int256 totalVariableTokens = 0;
        int256 totalCashflow = 0;

        uint256 termStartTimestampWad = uint256(
            IMarginEngine(MEAddress).termStartTimestampWad()
        );
        uint256 termEndTimestampWad = uint256(
            IMarginEngine(MEAddress).termEndTimestampWad()
        );

        int256 liquidatablePositions = 0;
        for (uint256 i = 1; i <= sizeAllPositions; i++) {
            TestMarginEngine(MEAddress)
                .updatePositionTokenBalancesAndAccountForFeesTest(
                    allPositions[i].owner,
                    allPositions[i].tickLower,
                    allPositions[i].tickUpper,
                    false
                );

            Position.Info memory position = IMarginEngine(MEAddress)
                .getPosition(
                    allPositions[i].owner,
                    allPositions[i].tickLower,
                    allPositions[i].tickUpper
                );

            // Printer.printInt256(
            //     "   fixedTokenBalance:",
            //     position.fixedTokenBalance
            // );
            // Printer.printInt256(
            //     "variableTokenBalance:",
            //     position.variableTokenBalance
            // );
            // Printer.printInt256("              margin:", position.margin);

            int256 estimatedSettlementCashflow = FixedAndVariableMath
                .calculateSettlementCashflow(
                    position.fixedTokenBalance,
                    position.variableTokenBalance,
                    termStartTimestampWad,
                    termEndTimestampWad,
                    estimatedVariableFactorFromStartToMaturity()
                );

            TestMarginEngine(MEAddress).getPositionMarginRequirementTest(
                allPositions[i].owner,
                allPositions[i].tickLower,
                allPositions[i].tickUpper,
                true
            );
            uint256 marginRequirement = TestMarginEngine(MEAddress).getMargin();
            // Printer.printUint256("  margin requirement:", marginRequirement);

            if (int256(marginRequirement) > position.margin) {
                liquidatablePositions += 1;
            }

            bytes32 hashedPositon = keccak256(
                abi.encodePacked(
                    allPositions[i].owner,
                    allPositions[i].tickLower,
                    allPositions[i].tickUpper
                )
            );

            PositionSnapshot memory positionSnapshot;

            positionSnapshot.margin = position.margin;
            positionSnapshot.marginRequirement = marginRequirement;

            positionSnapshot.termStartTimestampWad = termStartTimestampWad;
            positionSnapshot.termEndTimestampWad = termEndTimestampWad;
            positionSnapshot.currentTimestampWad = Time.blockTimestampScaled();

            positionSnapshot
                .estimatedSettlementCashflow = estimatedSettlementCashflow;

            positionSnapshot.fixedTokenBalance = position.fixedTokenBalance;
            positionSnapshot.variableTokenBalance = position
                .variableTokenBalance;

            sizeOfPositionHistory[hashedPositon] += 1;
            positionHistory[hashedPositon][
                sizeOfPositionHistory[hashedPositon]
            ] = positionSnapshot;

            totalFixedTokens += position.fixedTokenBalance;
            totalVariableTokens += position.variableTokenBalance;
            totalCashflow += position.margin;
            totalCashflow += estimatedSettlementCashflow;

            // Printer.printInt256(
            //     "              esc:",
            //     estimatedSettlementCashflow
            // );
        }

        for (uint256 i = 1; i <= sizeAllYBATraders; i++) {
            TraderWithYieldBearingAssets.Info memory trader = IFCM(FCMAddress)
                .getTraderWithYieldBearingAssets(allYBATraders[i]);
            totalFixedTokens += trader.fixedTokenBalance;
            totalVariableTokens += trader.variableTokenBalance;

            int256 estimatedSettlementCashflow = FixedAndVariableMath
                .calculateSettlementCashflow(
                    trader.fixedTokenBalance,
                    int256(trader.variableTokenBalance),
                    termStartTimestampWad,
                    termEndTimestampWad,
                    estimatedVariableFactorFromStartToMaturity()
                );

            totalCashflow += estimatedSettlementCashflow;

            // Printer.printInt256(
            //     "   fixedTokenBalance:",
            //     trader.fixedTokenBalance
            // );
            // Printer.printInt256(
            //     "variableTokenBalance:",
            //     trader.variableTokenBalance
            // );
            // Printer.printInt256(
            //     "              YBA esc:",
            //     estimatedSettlementCashflow
            // );
        }

        totalCashflow += int256(IVAMM(VAMMAddress).protocolFees());
        totalCashflow += int256(liquidationRewards);
        totalCashflow -= fcmFees;

        // Printer.printInt256("fcmFees", fcmFees);
        // Printer.printInt256("   totalFixedTokens:", totalFixedTokens);
        // Printer.printInt256("totalVariableTokens:", totalVariableTokens);
        // Printer.printInt256("   initialCashflow:", initialCashflow);
        // Printer.printInt256(
        //     "      deltaCashflow:",
        //     totalCashflow - initialCashflow
        // );
        // Printer.printInt256("liquidatable Positions", liquidatablePositions);
        // Printer.printEmptyLine();

        // ideally, this should be 0
        int256 approximation = 100000;

        // Printer.printUint256("      app:", uint256(approximation));

        require(
            -approximation < totalFixedTokens && totalFixedTokens <= 0,
            "fixed tokens don't net out"
        );
        require(
            -approximation < totalVariableTokens && totalVariableTokens <= 0,
            "variable tokens don't net out"
        );
        require(
            initialCashflow >= totalCashflow &&
                totalCashflow > initialCashflow - approximation,
            "system loss: undercollateralized"
        );

        // require(
        //     abs(totalFixedTokens) < uint256(approximation),
        //     "fixed tokens don't net out"
        // );
        // require(
        //     abs(totalVariableTokens) < uint256(approximation),
        //     "variable tokens don't net out"
        // );
        // require(
        //     abs(totalCashflow - initialCashflow) < uint256(approximation),
        //     "cashflows don't net out"
        // );
    }

    function getPositionSwapsHistory(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) public view returns (SwapSnapshot[] memory, uint256) {
        bytes32 hashedPositon = keccak256(
            abi.encodePacked(owner, tickLower, tickUpper)
        );
        uint256 len = sizeOfPositionSwapsHistory[hashedPositon];
        SwapSnapshot[] memory snapshots = new SwapSnapshot[](len);

        for (uint256 i = 0; i < len; i++) {
            snapshots[i] = positionSwapsHistory[hashedPositon][i + 1];
        }

        return (snapshots, len);
    }

    function getPositionHistory(
        address owner,
        int24 tickLower,
        int24 tickUpper
    ) public view returns (PositionSnapshot[] memory) {
        bytes32 hashedPositon = keccak256(
            abi.encodePacked(owner, tickLower, tickUpper)
        );
        uint256 len = sizeOfPositionHistory[hashedPositon];
        PositionSnapshot[] memory snapshots = new PositionSnapshot[](len);

        for (uint256 i = 0; i < len; i++) {
            snapshots[i] = positionHistory[hashedPositon][i + 1];
        }

        return snapshots;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;

import "contracts/test/TestMarginEngine.sol";
import "contracts/test/TestVAMM.sol";
import "contracts/test/TestAaveFCM.sol";
import "contracts/utils/Printer.sol";
import "../interfaces/aave/IAaveV2LendingPool.sol";
import "../interfaces/rate_oracles/IAaveRateOracle.sol";
import "../interfaces/IFactory.sol";
import "../interfaces/IPeriphery.sol";
import "../utils/WadRayMath.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "contracts/utils/CustomErrors.sol";

contract Actor is CustomErrors {
    function mintOrBurnViaPeriphery(
        address peripheryAddress,
        IPeriphery.MintOrBurnParams memory params
    ) external returns (int256 positionMarginRequirement) {
        positionMarginRequirement = IPeriphery(peripheryAddress).mintOrBurn(
            params
        );
    }

    function swapViaPeriphery(
        address peripheryAddress,
        IPeriphery.SwapPeripheryParams memory params
    )
        external
        returns (
            int256 _fixedTokenDelta,
            int256 _variableTokenDelta,
            uint256 _cumulativeFeeIncurred,
            int256 _fixedTokenDeltaUnbalanced,
            int256 _marginRequirement
        )
    {
        (
            _fixedTokenDelta,
            _variableTokenDelta,
            _cumulativeFeeIncurred,
            _fixedTokenDeltaUnbalanced,
            _marginRequirement,

        ) = IPeriphery(peripheryAddress).swap(params);
    }

    function updatePositionMarginViaAMM(
        address MEAddress,
        address _owner,
        int24 tickLower,
        int24 tickUpper,
        int256 marginDelta
    ) public {
        IMarginEngine(MEAddress).updatePositionMargin(
            _owner,
            tickLower,
            tickUpper,
            marginDelta
        );
    }

    function settlePositionViaAMM(
        address MEAddress,
        address _owner,
        int24 tickLower,
        int24 tickUpper
    ) public {
        IMarginEngine(MEAddress).settlePosition(_owner, tickLower, tickUpper);
    }

    function mintViaAMM(
        address VAMMAddress,
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external returns (int256 positionMarginRequirement) {
        positionMarginRequirement = IVAMM(VAMMAddress).mint(
            recipient,
            tickLower,
            tickUpper,
            amount
        );
    }

    function burnViaAMM(
        address VAMMAddress,
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external {
        IVAMM(VAMMAddress).burn(recipient, tickLower, tickUpper, amount);
    }

    function swapViaAMM(address VAMMAddress, IVAMM.SwapParams memory params)
        external
        returns (
            int256 _fixedTokenDelta,
            int256 _variableTokenDelta,
            uint256 _cumulativeFeeIncurred,
            int256 _fixedTokenDeltaUnbalanced,
            int256 _marginRequirement
        )
    {
        (
            _fixedTokenDelta,
            _variableTokenDelta,
            _cumulativeFeeIncurred,
            _fixedTokenDeltaUnbalanced,
            _marginRequirement
        ) = IVAMM(VAMMAddress).swap(params);
    }

    function setIntegrationApproval(
        address MEAddress,
        address intAddress,
        bool allowIntegration
    ) external {
        // get the factory
        IFactory factory = IMarginEngine(MEAddress).factory();
        // set integration approval
        factory.setApproval(intAddress, allowIntegration);
    }

    function liquidatePosition(
        address MEAddress,
        int24 tickLower,
        int24 tickUpper,
        address owner
    ) external {
        IMarginEngine(MEAddress).liquidatePosition(owner, tickLower, tickUpper);
    }

    function initiateFullyCollateralisedFixedTakerSwap(
        address FCMAddress,
        uint256 notional,
        uint160 sqrtPriceLimitX96
    ) external {
        IFCM(FCMAddress).initiateFullyCollateralisedFixedTakerSwap(
            notional,
            sqrtPriceLimitX96
        );
    }

    function unwindFullyCollateralisedFixedTakerSwap(
        address FCMAddress,
        uint256 notionalToUnwind,
        uint160 sqrtPriceLimitX96
    ) external {
        IFCM(FCMAddress).unwindFullyCollateralisedFixedTakerSwap(
            notionalToUnwind,
            sqrtPriceLimitX96
        );
    }

    function settleYBATrader(address FCMAddress) external {
        IFCM(FCMAddress).settleTrader();
    }

    function settlePosition(
        address MEAdrress,
        address recipient,
        int24 tickLower,
        int24 tickUpper
    ) external {
        IMarginEngine(MEAdrress).settlePosition(
            recipient,
            tickLower,
            tickUpper
        );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;

import "../VAMM.sol";

contract TestVAMM is VAMM {
    function checkMaturityDuration()
        external
        view
        checkCurrentTimestampTermEndTimestampDelta
        returns (uint256 currentTimestamp, uint256 termEndTimestamp)
    {
        currentTimestamp = Time.blockTimestampScaled();
        termEndTimestamp = termEndTimestampWad;
    }

    function testGetAMMTermEndTimestamp() external view returns (uint256) {
        return termEndTimestampWad;
    }

    function setTestProtocolFees(uint256 newProtocolFees) external {
        _protocolFees = newProtocolFees;
    }

    function getProtocolFees() external view returns (uint256) {
        return _protocolFees;
    }

    function setVariableTokenGrowthGlobal(
        int256 newVariableTokenGrowthGlobalX128
    ) external {
        _variableTokenGrowthGlobalX128 = newVariableTokenGrowthGlobalX128;
    }

    function setFixedTokenGrowthGlobal(int256 newFixedTokenGrowthGlobalX128)
        external
    {
        _fixedTokenGrowthGlobalX128 = newFixedTokenGrowthGlobalX128;
    }

    function setTickTest(int24 tick, Tick.Info memory info) external {
        _ticks[tick] = info;
    }

    function getCurrentTick() external view returns (int24 currentTick) {
        return _vammVars.tick;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;

import "../AaveFCM.sol";

contract TestAaveFCM is AaveFCM {
    function getTraderMarginInYieldBearingTokensTest(address traderAddress)
        external
        view
        returns (uint256 marginInYieldBearingTokens)
    {
        TraderWithYieldBearingAssets.Info storage trader = traders[
            traderAddress
        ];
        marginInYieldBearingTokens = getTraderMarginInYieldBearingTokens(
            trader.marginInScaledYieldBearingTokens
        );
    }

    function getVAMMAddress() external view returns (address) {
        return address(_vamm);
    }

    function getUnderlyingYieldBearingToken() external view returns (address) {
        return address(_underlyingYieldBearingToken);
    }

    function getAaveLendingPool() external view returns (address) {
        return address(_aaveLendingPool);
    }

    function estimateSettlementCashflow(
        address traderAddress,
        uint256 termStartTimestampWad,
        uint256 termEndTimestampWad,
        uint256 variableFactorWad
    ) external view returns (int256) {
        TraderWithYieldBearingAssets.Info storage trader = traders[
            traderAddress
        ];

        int256 settlementCashflow = FixedAndVariableMath
            .calculateSettlementCashflow(
                trader.fixedTokenBalance,
                trader.variableTokenBalance,
                termStartTimestampWad,
                termEndTimestampWad,
                variableFactorWad
            );

        // if settlement happens late, additional variable yield beyond maturity will accrue to the trader

        return settlementCashflow;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;
import "../aave/IAaveV2LendingPool.sol";
import "../rate_oracles/IRateOracle.sol";
import "contracts/utils/CustomErrors.sol";

interface IAaveRateOracle is IRateOracle {

    /// @notice Gets the address of the Aave Lending Pool
    /// @return Address of the Aave Lending Pool
    function aaveLendingPool() external view returns (IAaveV2LendingPool);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;
import "./interfaces/fcms/IFCM.sol";
import "./interfaces/fcms/IFCM.sol";
import "./interfaces/fcms/IAaveFCM.sol";
import "./storage/FCMStorage.sol";
import "./core_libraries/TraderWithYieldBearingAssets.sol";
import "./interfaces/IERC20Minimal.sol";
import "./interfaces/IVAMM.sol";
import "./interfaces/aave/IAaveV2LendingPool.sol";
import "./interfaces/rate_oracles/IAaveRateOracle.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";
import "./core_libraries/FixedAndVariableMath.sol";
import "./interfaces/rate_oracles/IRateOracle.sol";
import "./utils/WadRayMath.sol";
import "./utils/Printer.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./aave/AaveDataTypes.sol";
import "./core_libraries/SafeTransferLib.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract AaveFCM is AaveFCMStorage, IFCM, IAaveFCM, Initializable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {

  using WadRayMath for uint256;
  using SafeCast for uint256;
  using SafeCast for int256;

  using TraderWithYieldBearingAssets for TraderWithYieldBearingAssets.Info;

  using SafeTransferLib for IERC20Minimal;

  /// @dev modifier which checks if the msg.sender is not equal to the address of the MarginEngine, if that's the case, a revert is raised
  modifier onlyMarginEngine () {
    if (msg.sender != address(_marginEngine)) {
        revert CustomErrors.OnlyMarginEngine();
    }
    _;
  }

  // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor () initializer {}

  /// @dev in the initialize function we set the vamm and the margiEngine associated with the fcm
  function initialize(IVAMM __vamm, IMarginEngine __marginEngine) external override initializer {

    require(address(__vamm) != address(0), "vamm must exist");
    require(address(__marginEngine) != address(0), "margin engine must exist");

    /// @dev we additionally cache the rateOracle, _aaveLendingPool, underlyingToken, underlyingYieldBearingToken
    _vamm = __vamm;
    _marginEngine = __marginEngine;
    _rateOracle = _marginEngine.rateOracle();
    _aaveLendingPool = IAaveV2LendingPool(IAaveRateOracle(address(_rateOracle)).aaveLendingPool());
    underlyingToken = _marginEngine.underlyingToken();
    AaveDataTypes.ReserveData memory _aaveReserveData = _aaveLendingPool.getReserveData(underlyingToken);
    _underlyingYieldBearingToken = IERC20Minimal(_aaveReserveData.aTokenAddress);
    tickSpacing = _vamm.tickSpacing(); // retrieve tick spacing of the VAM

    __Ownable_init();
    __Pausable_init();
    __UUPSUpgradeable_init();
  }

    // GETTERS FOR STORAGE SLOTS
    // Not auto-generated by public variables in the storage contract, cos solidity doesn't support that for functions that implement an interface
    /// @inheritdoc IAaveFCM
    function underlyingYieldBearingToken() external view override returns (IERC20Minimal) {
        return _underlyingYieldBearingToken;
    }
    /// @inheritdoc IAaveFCM
    function aaveLendingPool() external view override returns (IAaveV2LendingPool) {
        return _aaveLendingPool;
    }
    /// @inheritdoc IFCM
    function marginEngine() external view override returns (IMarginEngine) {
        return _marginEngine;
    }
    /// @inheritdoc IFCM
    function vamm() external view override returns (IVAMM) {
        return _vamm;
    }
    /// @inheritdoc IFCM
    function rateOracle() external view override returns (IRateOracle) {
        return _rateOracle;
    }

  // To authorize the owner to upgrade the contract we implement _authorizeUpgrade with the onlyOwner modifier.
  // ref: https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786
  function _authorizeUpgrade(address) internal override onlyOwner {}

  function getTraderWithYieldBearingAssets(
        address trader
    ) external override view returns (TraderWithYieldBearingAssets.Info memory traderInfo) {
      return traders[trader];
    }


  /// @notice Initiate a Fully Collateralised Fixed Taker Swap
  /// @param notional Notional that cover by a fully collateralised fixed taker interest rate swap
  /// @param sqrtPriceLimitX96 The binary fixed point math representation of the sqrtPriceLimit beyond which the fixed taker swap will not be executed with the VAMM
  function initiateFullyCollateralisedFixedTakerSwap(uint256 notional, uint160 sqrtPriceLimitX96) external override returns 
    (int256 fixedTokenDelta, int256 variableTokenDelta, uint256 cumulativeFeeIncurred, int256 fixedTokenDeltaUnbalanced) {

    require(notional!=0, "notional = 0");

    // initiate a swap
    // the default tick range for a Position associated with the FCM is tickLower: -tickSpacing and tickUpper: tickSpacing
    // isExternal is true since the state updates following a VAMM induced swap are done in the FCM (below)
    IVAMM.SwapParams memory params = IVAMM.SwapParams({
        recipient: address(this),
        amountSpecified: notional.toInt256(),
        sqrtPriceLimitX96: sqrtPriceLimitX96,
        tickLower: -tickSpacing,
        tickUpper: tickSpacing
    });

    (fixedTokenDelta, variableTokenDelta, cumulativeFeeIncurred, fixedTokenDeltaUnbalanced,) = _vamm.swap(params);

    require(variableTokenDelta <=0, "VT delta sign");

    TraderWithYieldBearingAssets.Info storage trader = traders[msg.sender];

    uint256 currentRNI = _aaveLendingPool.getReserveNormalizedIncome(underlyingToken);

    uint256 updatedTraderMargin = trader.marginInScaledYieldBearingTokens + uint256(-variableTokenDelta).rayDiv(currentRNI);
    trader.updateMarginInScaledYieldBearingTokens(updatedTraderMargin);

    // update trader fixed and variable token balances
    trader.updateBalancesViaDeltas(fixedTokenDelta, variableTokenDelta);

    // deposit notional executed in terms of aTokens (e.g. aUSDC) to fully collateralise your position
    _underlyingYieldBearingToken.safeTransferFrom(msg.sender, address(this), uint256(-variableTokenDelta));

    // transfer fees to the margin engine (in terms of the underlyingToken e.g. USDC)
    underlyingToken.safeTransferFrom(msg.sender, address(_marginEngine), cumulativeFeeIncurred);

    emit FullyCollateralisedSwap(
      msg.sender,
      notional,
      sqrtPriceLimitX96,
      cumulativeFeeIncurred,
      fixedTokenDelta, 
      variableTokenDelta,
      fixedTokenDeltaUnbalanced
    );

    emit FCMTraderUpdate(
      msg.sender,
      trader.marginInScaledYieldBearingTokens,
      trader.fixedTokenBalance,
      trader.variableTokenBalance
    );
  }

  /// @notice Get Trader Margin In Yield Bearing Tokens
  /// @dev this function takes the scaledBalance associated with a trader and multiplies it by the current Reserve Normalised Income to get the balance (margin) in terms of the underlying token
  /// @param traderMarginInScaledYieldBearingTokens traderMarginInScaledYieldBearingTokens
  function getTraderMarginInYieldBearingTokens(uint256 traderMarginInScaledYieldBearingTokens) internal view returns (uint256 marginInYieldBearingTokens) {
    uint256 currentRNI = _aaveLendingPool.getReserveNormalizedIncome(underlyingToken);
    marginInYieldBearingTokens = traderMarginInScaledYieldBearingTokens.rayMul(currentRNI);
  }

  function getTraderMarginInATokens(address traderAddress)
        external
        view
        returns (uint256 marginInYieldBearingTokens)
    {
        TraderWithYieldBearingAssets.Info storage trader = traders[
            traderAddress
        ];
        marginInYieldBearingTokens = getTraderMarginInYieldBearingTokens(
            trader.marginInScaledYieldBearingTokens
        );
    }


  /// @notice Unwind Fully Collateralised Fixed Taker Swap
  /// @param notionalToUnwind The amount of notional to unwind (stop securing with a fixed rate)
  /// @param sqrtPriceLimitX96 The sqrt price limit (binary fixed point notation) beyond which the unwind cannot progress
  function unwindFullyCollateralisedFixedTakerSwap(uint256 notionalToUnwind, uint160 sqrtPriceLimitX96) external override returns 
    (int256 fixedTokenDelta, int256 variableTokenDelta, uint256 cumulativeFeeIncurred, int256 fixedTokenDeltaUnbalanced) {

    // add require statement and isApproval

    TraderWithYieldBearingAssets.Info storage trader = traders[msg.sender];

    require(trader.variableTokenBalance <= 0, "Trader VT balance positive");

    /// @dev it is impossible to unwind more variable token exposure than the user already has
    /// @dev hencel, the notionalToUnwind needs to be <= absolute value of the variable token balance of the trader
    require(uint256(-trader.variableTokenBalance) >= notionalToUnwind, "notional to unwind > notional");

    // initiate a swap
    /// @dev as convention, specify the tickLower to be equal to -tickSpacing and tickUpper to be equal to tickSpacing
    // since the unwind is in the Variable Taker direction, the amountSpecified needs to be exact output => needs to be negative = -int256(notionalToUnwind),
    IVAMM.SwapParams memory params = IVAMM.SwapParams({
        recipient: address(this),
        amountSpecified: -notionalToUnwind.toInt256(),
        sqrtPriceLimitX96: sqrtPriceLimitX96,
        tickLower: -tickSpacing,
        tickUpper: tickSpacing
    });

    (fixedTokenDelta, variableTokenDelta, cumulativeFeeIncurred, fixedTokenDeltaUnbalanced,) = _vamm.swap(params);

    require(variableTokenDelta >= 0, "VT delta negative");

    // update trader fixed and variable token balances
    (int256 _fixedTokenBalance, int256 _variableTokenBalance) = trader.updateBalancesViaDeltas(fixedTokenDelta, variableTokenDelta);

    uint256 currentRNI = _aaveLendingPool.getReserveNormalizedIncome(underlyingToken);

    uint256 updatedTraderMargin = trader.marginInScaledYieldBearingTokens - uint256(variableTokenDelta).rayDiv(currentRNI);
    trader.updateMarginInScaledYieldBearingTokens(updatedTraderMargin);

    // check the margin requirement of the trader post unwind, if the current balances still support the unwind, they it can happen, otherwise the unwind will get reverted
    checkMarginRequirement(_fixedTokenBalance, _variableTokenBalance, trader.marginInScaledYieldBearingTokens);

    // transfer fees to the margin engine
    underlyingToken.safeTransferFrom(msg.sender, address(_marginEngine), cumulativeFeeIncurred);

    // transfer the yield bearing tokens to trader address and update margin in terms of yield bearing tokens
    // variable token delta should be positive
    _underlyingYieldBearingToken.safeTransfer(msg.sender, uint256(variableTokenDelta));

    emit FullyCollateralisedUnwind(
      msg.sender,
      notionalToUnwind,
      sqrtPriceLimitX96,
      cumulativeFeeIncurred,
      fixedTokenDelta, 
      variableTokenDelta,
      fixedTokenDeltaUnbalanced
    );

    emit FCMTraderUpdate(
      msg.sender,
      trader.marginInScaledYieldBearingTokens,
      trader.fixedTokenBalance,
      trader.variableTokenBalance
    );
  }


  /// @notice Check Margin Requirement post unwind of a fully collateralised fixed taker
  function checkMarginRequirement(int256 traderFixedTokenBalance, int256 traderVariableTokenBalance, uint256 traderMarginInScaledYieldBearingTokens) internal {

    // variable token balance should never be positive
    // margin in scaled tokens should cover the variable leg from now to maturity

    /// @dev we can be confident the variable token balance of a fully collateralised fixed taker is always going to be negative (or zero)
    /// @dev hence, we can assume that the variable cashflows from now to maturity is covered by a portion of the trader's collateral in yield bearing tokens
    /// @dev once future variable cashflows are covered, we need to check if the remaining settlement cashflow is covered by the remaining margin in yield bearing tokens

    require(traderVariableTokenBalance <=0, "VTB sign");
    uint256 marginToCoverVariableLegFromNowToMaturity = uint256(-traderVariableTokenBalance);
    int256 marginToCoverRemainingSettlementCashflow = int256(getTraderMarginInYieldBearingTokens(traderMarginInScaledYieldBearingTokens)) - int256(marginToCoverVariableLegFromNowToMaturity);

    int256 remainingSettlementCashflow = calculateRemainingSettlementCashflow(traderFixedTokenBalance, traderVariableTokenBalance);

    if (remainingSettlementCashflow < 0) {

      if (-remainingSettlementCashflow > marginToCoverRemainingSettlementCashflow) {
        revert CustomErrors.MarginRequirementNotMetFCM(int256(marginToCoverVariableLegFromNowToMaturity) + remainingSettlementCashflow);
      }

    }

  }


  /// @notice Calculate remaining settlement cashflow
  function calculateRemainingSettlementCashflow(int256 traderFixedTokenBalance, int256 traderVariableTokenBalance) internal returns (int256 remainingSettlementCashflow) {

    int256 fixedTokenBalanceWad = PRBMathSD59x18.fromInt(traderFixedTokenBalance);

    int256 variableTokenBalanceWad = PRBMathSD59x18.fromInt(
        traderVariableTokenBalance
    );

    /// @dev fixed cashflow based on the full term of the margin engine
    int256 fixedCashflowWad = PRBMathSD59x18.mul(
      fixedTokenBalanceWad,
      int256(
        FixedAndVariableMath.fixedFactor(true, _marginEngine.termStartTimestampWad(), _marginEngine.termEndTimestampWad())
      )
    );

    int256 variableFactorFromTermStartTimestampToNow = int256(_rateOracle.variableFactor(
      _marginEngine.termStartTimestampWad(),
      _marginEngine.termEndTimestampWad()
    ));

    /// @dev variable cashflow form term start timestamp to now
    int256 variableCashflowWad = PRBMathSD59x18.mul(
      variableTokenBalanceWad,
      variableFactorFromTermStartTimestampToNow
    );

    /// @dev the total cashflows as a sum of fixed and variable cashflows
    int256 cashflowWad = fixedCashflowWad + variableCashflowWad;

    /// @dev convert back to non-fixed point representation
    remainingSettlementCashflow = PRBMathSD59x18.toInt(cashflowWad);

  }

  modifier onlyAfterMaturity () {
    if (_marginEngine.termEndTimestampWad() > Time.blockTimestampScaled()) {
        revert CannotSettleBeforeMaturity();
    }
    _;
  }

  /// @notice Settle Trader
  /// @dev This function lets us settle a fully collateralised fixed taker position post term end timestamp of the MarginEngine
  /// @dev the settlement cashflow is calculated by invoking the calculateSettlementCashflow function of FixedAndVariableMath.sol (based on the fixed and variable token balance)
  /// @dev if the settlement cashflow of the trader is positive, then the settleTrader() function invokes the transferMarginToFCMTrader function of the MarginEngine which transfers the settlement cashflow the trader in terms of the underlying tokens
  /// @dev if settlement cashflow of the trader is negative, we need to update trader's margin in terms of scaled yield bearing tokens to account the settlement casflow
  /// @dev once settlement cashflows are accounted for, we safeTransfer the scaled yield bearing tokens in the margin account of the trader back to their wallet address
  function settleTrader() external override onlyAfterMaturity returns (int256 traderSettlementCashflow) {

    TraderWithYieldBearingAssets.Info storage trader = traders[msg.sender];

    int256 settlementCashflow = FixedAndVariableMath.calculateSettlementCashflow(trader.fixedTokenBalance, trader.variableTokenBalance, _marginEngine.termStartTimestampWad(), _marginEngine.termEndTimestampWad(), _rateOracle.variableFactor(_marginEngine.termStartTimestampWad(), _marginEngine.termEndTimestampWad()));
    trader.updateBalancesViaDeltas(-trader.fixedTokenBalance, -trader.variableTokenBalance);

    if (settlementCashflow < 0) {
      uint256 currentRNI = _aaveLendingPool.getReserveNormalizedIncome(underlyingToken);
      uint256 updatedTraderMarginInScaledYieldBearingTokens = trader.marginInScaledYieldBearingTokens - uint256(-settlementCashflow).rayDiv(currentRNI);
      trader.updateMarginInScaledYieldBearingTokens(updatedTraderMarginInScaledYieldBearingTokens);
    }

    // if settlement happens late, additional variable yield beyond maturity will accrue to the trader
    uint256 traderMarginInYieldBearingTokens = getTraderMarginInYieldBearingTokens(trader.marginInScaledYieldBearingTokens);
    trader.updateMarginInScaledYieldBearingTokens(0);
    trader.settleTrader();
    _underlyingYieldBearingToken.safeTransfer(msg.sender, traderMarginInYieldBearingTokens);
    if (settlementCashflow > 0) {
      // transfers margin in terms of underlying tokens (e.g. USDC) from the margin engine to the msg.sender
      // as long as the margin engine is active and solvent it shoudl be able to cover the settlement cashflows of the fully collateralised traders
      _marginEngine.transferMarginToFCMTrader(msg.sender, uint256(settlementCashflow));
    }

    emit fcmPositionSettlement(
      msg.sender,
      settlementCashflow
    );

    emit FCMTraderUpdate(
      msg.sender,
      trader.marginInScaledYieldBearingTokens,
      trader.fixedTokenBalance,
      trader.variableTokenBalance
    );

    return settlementCashflow;
  }


  /// @notice Transfer Margin (in underlying tokens) from the FCM to a MarginEngine trader
  /// @dev in case of aave this is done by withdrawing aTokens from the aaveLendingPools resulting in burning of the aTokens in exchange for the ability to transfer underlying tokens to the margin engine trader
  function transferMarginToMarginEngineTrader(address account, uint256 marginDeltaInUnderlyingTokens) external onlyMarginEngine whenNotPaused override {
    if (underlyingToken.balanceOf(address(_underlyingYieldBearingToken)) >= marginDeltaInUnderlyingTokens) {
      _aaveLendingPool.withdraw(underlyingToken, marginDeltaInUnderlyingTokens, account);
    } else {
      _underlyingYieldBearingToken.safeTransfer(account, marginDeltaInUnderlyingTokens);
    }
  }


}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../aave/IAaveV2LendingPool.sol";
import "../IERC20Minimal.sol";

interface IAaveFCM { 
    
    function aaveLendingPool() external returns (IAaveV2LendingPool);

    function underlyingYieldBearingToken() external returns (IERC20Minimal); 
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity =0.8.9;

import "../interfaces/IERC20Minimal.sol";
import "../interfaces/IMarginEngine.sol";
import "../interfaces/IVAMM.sol";
import "../core_libraries/TraderWithYieldBearingAssets.sol";
import "../interfaces/aave/IAaveV2LendingPool.sol";
import "../interfaces/compound/ICToken.sol";

contract FCMStorageV1 {
    // Any variables that would implicitly implement an IMarginEngine function if public, must instead
    // be internal due to limitations in the solidity compiler (as of 0.8.12)
    IRateOracle internal _rateOracle;
    IMarginEngine internal _marginEngine;
    int24 internal tickSpacing;
    IVAMM internal _vamm;
    mapping(address => TraderWithYieldBearingAssets.Info) public traders;
    IERC20Minimal public underlyingToken;
}

contract AaveFCMStorageV1 {
    // Any variables that would implicitly implement an IMarginEngine function if public, must instead
    // be internal due to limitations in the solidity compiler (as of 0.8.12)
    IAaveV2LendingPool internal _aaveLendingPool;
    IERC20Minimal internal _underlyingYieldBearingToken;
}

contract CompoundFCMStorageV1 {
    // Any variables that would implicitly implement an IMarginEngine function if public, must instead
    // be internal due to limitations in the solidity compiler (as of 0.8.12)
    ICToken internal _ctoken;
}

contract FCMStorage is FCMStorageV1 {
    // Reserve some storage for use in future versions, without creating conflicts
    // with other inheritted contracts
    uint256[44] private __gap;
}

contract AaveFCMStorage is FCMStorage, AaveFCMStorageV1 {
    // Reserve some storage for use in future versions, without creating conflicts
    // with other inheritted contracts
    uint256[48] private __gap;
}

contract CompoundFCMStorage is FCMStorage, CompoundFCMStorageV1 {
    // Reserve some storage for use in future versions, without creating conflicts
    // with other inheritted contracts
    uint256[50] private __gap;
}

pragma solidity ^0.8.0;
import "../rate_oracles/BaseRateOracle.sol";
import "../rate_oracles/OracleBuffer.sol";
import "../rate_oracles/CompoundRateOracle.sol";
import "../interfaces/rate_oracles/ICompoundRateOracle.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../utils/WadRayMath.sol";
import "hardhat/console.sol";
import "../interfaces/compound/ICToken.sol";

contract TestCompoundRateOracle is CompoundRateOracle {
    using OracleBuffer for OracleBuffer.Observation[65535];

    int24 public tick;
    uint128 public liquidity;

    uint256 public latestObservedRateValue;
    uint256 public latestRateFromTo;

    uint256 public latestBeforeOrAtRateValue;
    uint256 public latestAfterOrAtRateValue;

    // rateOracleAddress should be a function of underlyingProtocol and underlyingToken?
    constructor(
        ICToken cToken,
        IERC20Minimal underlying,
        uint8 _decimals
    )
        CompoundRateOracle(
            cToken,
            underlying,
            _decimals,
            new uint32[](0),
            new uint256[](0)
        )
    {}

    function getOracleVars()
        external
        view
        returns (
            uint16,
            uint16,
            uint16
        )
    {
        return (
            oracleVars.rateIndex,
            oracleVars.rateCardinality,
            oracleVars.rateCardinalityNext
        );
    }

    function getRate(uint16 index) external view returns (uint256, uint256) {
        OracleBuffer.Observation memory rate = observations[index];
        return (rate.blockTimestamp, rate.observedValue);
    }

    function testObserveSingle(uint32 queriedTime)
        external
        returns (uint256 observedValue)
    {
        latestObservedRateValue = observeSingle(
            Time.blockTimestampTruncated(),
            queriedTime,
            oracleVars.rateIndex,
            oracleVars.rateCardinality
        );
        return latestObservedRateValue;
    }

    function testGrow(uint16 _rateCardinalityNext) external {
        oracleVars.rateCardinalityNext = observations.grow(
            oracleVars.rateCardinalityNext,
            _rateCardinalityNext
        );
    }

    function testGetRateFromTo(uint256 from, uint256 to)
        external
        returns (uint256)
    {
        latestRateFromTo = getRateFromTo(from, to);
        return latestRateFromTo;
    }

    // function testBinarySearch(uint32 target)
    //     external
    //     view
    //     returns (uint256 beforeOrAtRateValue, uint256 afterOrAtRateValue)
    // {
    //     (OracleBuffer.Observation memory beforeOrAt, OracleBuffer.Observation memory atOrAfter) = observations.binarySearch(
    //         Time.blockTimestampTruncated(),
    //         target,
    //         oracleVars.rateIndex,
    //         oracleVars.rateCardinality
    //     );
    //     beforeOrAtRateValue = beforeOrAt.observedValue;
    //     afterOrAtRateValue = atOrAfter.observedValue;
    // }
    function binarySearch(uint32 target)
        external
        view
        returns (
            OracleBuffer.Observation memory beforeOrAt,
            OracleBuffer.Observation memory atOrAfter
        )
    {
        return
            observations.binarySearch(
                target,
                oracleVars.rateIndex,
                oracleVars.rateCardinality
            );
    }

    // function testGetSurroundingRates(uint32 target) external {
    //     uint256 currentValue = ICToken(ctoken).exchangeRateCurrent();
    //     (
    //         OracleBuffer.Observation memory beforeOrAt,
    //         OracleBuffer.Observation memory atOrAfter
    //     ) = observations.getSurroundingObservations(
    //             target,
    //             currentValue,
    //             oracleVars.rateIndex,
    //             oracleVars.rateCardinality
    //         );

    //     latestBeforeOrAtRateValue = beforeOrAt.observedValue;
    //     latestAfterOrAtRateValue = atOrAfter.observedValue;
    // }

    function testComputeApyFromRate(uint256 rateFromTo, uint256 timeInYears)
        external
        pure
        returns (uint256)
    {
        return computeApyFromRate(rateFromTo, timeInYears);
    }

    // Checks that the observed value is within 0.0000001% of the expected value
    function rayValueIsCloseTo(
        uint256 observedValueInRay,
        uint256 expectedValueInRay
    ) external pure returns (bool) {
        uint256 upperBoundFactor = 1000000001 * 1e18;
        uint256 lowerBoundFactor = 999999999 * 1e18;
        uint256 upperBound = WadRayMath.rayMul(
            expectedValueInRay,
            upperBoundFactor
        );
        uint256 lowerBound = WadRayMath.rayMul(
            expectedValueInRay,
            lowerBoundFactor
        );
        // console.log('%s <= %s <= %s ??', lowerBound,observedValueInRay, upperBound);
        if (
            observedValueInRay <= upperBound && observedValueInRay >= lowerBound
        ) {
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "./OracleBuffer.sol";
import "../interfaces/rate_oracles/IRateOracle.sol";
import "../core_libraries/FixedAndVariableMath.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";
import "../interfaces/IFactory.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../core_libraries/Time.sol";
import "../utils/WadRayMath.sol";

/// @notice Common contract base for a Rate Oracle implementation.
/// @dev Each specific rate oracle implementation will need to implement the virtual functions
abstract contract BaseRateOracle is IRateOracle, Ownable {
    uint256 public constant ONE_IN_WAD = 1e18;

    using OracleBuffer for OracleBuffer.Observation[65535];

    /// @notice a cache of settlement rates for interest rate swaps associated with this rate oracle, indexed by start time and then end time
    mapping(uint32 => mapping(uint32 => uint256)) public settlementRateCache;
    struct OracleVars {
        /// @dev the most-recently updated index of the rates array
        uint16 rateIndex;
        /// @dev the current maximum number of rates that are being stored
        uint16 rateCardinality;
        /// @dev the next maximum number of rates to store, triggered in rates.write
        uint16 rateCardinalityNext;
    }

    /// @inheritdoc IRateOracle
    IERC20Minimal public immutable override underlying;

    /// @inheritdoc IRateOracle
    uint256 public override minSecondsSinceLastUpdate;

    OracleVars public oracleVars;

    /// @notice the observations tracked over time by this oracle
    OracleBuffer.Observation[65535] public observations;

    /// @inheritdoc IRateOracle
    function setMinSecondsSinceLastUpdate(uint256 _minSecondsSinceLastUpdate)
        external
        override
        onlyOwner
    {
        if (minSecondsSinceLastUpdate != _minSecondsSinceLastUpdate) {
            minSecondsSinceLastUpdate = _minSecondsSinceLastUpdate;

            emit MinSecondsSinceLastUpdate(_minSecondsSinceLastUpdate);
        }
    }

    constructor(IERC20Minimal _underlying) {
        require(address(_underlying) != address(0), "underlying must exist");
        underlying = _underlying;
    }

    /// @notice Calculates the interpolated (counterfactual) rate value
    /// @param beforeOrAtRateValueRay  Rate Value (in ray) before the timestamp for which we want to calculate the counterfactual rate value
    /// @param apyFromBeforeOrAtToAtOrAfterWad Apy in the period between the timestamp of the beforeOrAt Rate and the atOrAfter Rate
    /// @param timeDeltaBeforeOrAtToQueriedTimeWad Time Delta (in wei seconds) between the timestamp of the beforeOrAt Rate and the atOrAfter Rate
    /// @return rateValueRay Counterfactual (interpolated) rate value in ray
    /// @dev Given [beforeOrAt, atOrAfter] where the timestamp for which the counterfactual is calculated is within that range (but does not touch any of the bounds)
    /// @dev We can calculate the apy for [beforeOrAt, atOrAfter] --> refer to this value as apyFromBeforeOrAtToAtOrAfter
    /// @dev Then we want a counterfactual rate value which results in apy_before_after if the apy is calculated between [beforeOrAt, timestampForCounterfactual]
    /// @dev Hence (1+rateValueWei/beforeOrAtRateValueWei)^(1/timeInYears) = apyFromBeforeOrAtToAtOrAfter
    /// @dev Hence rateValueWei = beforeOrAtRateValueWei * (1+apyFromBeforeOrAtToAtOrAfter)^timeInYears - 1)
    function interpolateRateValue(
        uint256 beforeOrAtRateValueRay,
        uint256 apyFromBeforeOrAtToAtOrAfterWad,
        uint256 timeDeltaBeforeOrAtToQueriedTimeWad
    ) public pure virtual returns (uint256 rateValueRay) {
        uint256 timeInYearsWad = FixedAndVariableMath.accrualFact(
            timeDeltaBeforeOrAtToQueriedTimeWad
        );
        uint256 apyPlusOne = apyFromBeforeOrAtToAtOrAfterWad + ONE_IN_WAD;
        uint256 factorInWad = PRBMathUD60x18.pow(apyPlusOne, timeInYearsWad);
        uint256 factorInRay = WadRayMath.wadToRay(factorInWad);
        rateValueRay = WadRayMath.rayMul(beforeOrAtRateValueRay, factorInRay);
    }

    /// @inheritdoc IRateOracle
    function increaseObservationCardinalityNext(uint16 rateCardinalityNext)
        external
        override
    {
        uint16 rateCardinalityNextOld = oracleVars.rateCardinalityNext; // for the event

        uint16 rateCardinalityNextNew = observations.grow(
            rateCardinalityNextOld,
            rateCardinalityNext
        );

        oracleVars.rateCardinalityNext = rateCardinalityNextNew;

        if (rateCardinalityNextOld != rateCardinalityNextNew) {
            emit RateCardinalityNext(rateCardinalityNextNew);
        }
    }

    /// @notice Computes the APY based on the un-annualised rateFromTo value and timeInYears (in wei)
    /// @param rateFromToWad Un-annualised rate (in wei)
    /// @param timeInYearsWad Time in years for the period for which we want to calculate the apy (in wei)
    /// @return apyWad APY for a given rateFromTo and timeInYears
    function computeApyFromRate(uint256 rateFromToWad, uint256 timeInYearsWad)
        internal
        pure
        returns (uint256 apyWad)
    {
        if (rateFromToWad == 0) {
            return 0;
        }

        uint256 exponentWad = PRBMathUD60x18.div(
            PRBMathUD60x18.fromUint(1),
            timeInYearsWad
        );
        uint256 apyPlusOneWad = PRBMathUD60x18.pow(
            (PRBMathUD60x18.fromUint(1) + rateFromToWad),
            exponentWad
        );
        apyWad = apyPlusOneWad - PRBMathUD60x18.fromUint(1);
    }

    /// @inheritdoc IRateOracle
    function getRateFromTo(uint256 from, uint256 to)
        public
        view
        virtual
        override
        returns (uint256);

    /// @inheritdoc IRateOracle
    function getApyFromTo(uint256 from, uint256 to)
        public
        view
        override
        returns (uint256 apyFromToWad)
    {
        require(from <= to, "Misordered dates");

        uint256 rateFromToWad = getRateFromTo(from, to);

        uint256 timeInSeconds = to - from;

        uint256 timeInSecondsWad = PRBMathUD60x18.fromUint(timeInSeconds);

        uint256 timeInYearsWad = FixedAndVariableMath.accrualFact(
            timeInSecondsWad
        );

        apyFromToWad = computeApyFromRate(rateFromToWad, timeInYearsWad);
    }

    /// @inheritdoc IRateOracle
    function variableFactor(
        uint256 termStartTimestampInWeiSeconds,
        uint256 termEndTimestampInWeiSeconds
    ) public override(IRateOracle) returns (uint256 resultWad) {
        bool cacheable;

        (resultWad, cacheable) = _variableFactor(
            termStartTimestampInWeiSeconds,
            termEndTimestampInWeiSeconds
        );

        if (cacheable) {
            uint32 termStartTimestamp = Time.timestampAsUint32(
                PRBMathUD60x18.toUint(termStartTimestampInWeiSeconds)
            );
            uint32 termEndTimestamp = Time.timestampAsUint32(
                PRBMathUD60x18.toUint(termEndTimestampInWeiSeconds)
            );
            settlementRateCache[termStartTimestamp][
                termEndTimestamp
            ] = resultWad;
        }

        return resultWad;
    }

    /// @inheritdoc IRateOracle
    function variableFactorNoCache(
        uint256 termStartTimestampInWeiSeconds,
        uint256 termEndTimestampInWeiSeconds
    ) public view override(IRateOracle) returns (uint256 resultWad) {
        (resultWad, ) = _variableFactor(
            termStartTimestampInWeiSeconds,
            termEndTimestampInWeiSeconds
        );
    }

    function _variableFactor(
        uint256 termStartTimestampInWeiSeconds,
        uint256 termEndTimestampInWeiSeconds
    ) private view returns (uint256 resultWad, bool cacheable) {
        uint32 termStartTimestamp = Time.timestampAsUint32(
            PRBMathUD60x18.toUint(termStartTimestampInWeiSeconds)
        );
        uint32 termEndTimestamp = Time.timestampAsUint32(
            PRBMathUD60x18.toUint(termEndTimestampInWeiSeconds)
        );

        require(termStartTimestamp > 0 && termEndTimestamp > 0, "UNITS");
        if (settlementRateCache[termStartTimestamp][termEndTimestamp] != 0) {
            resultWad = settlementRateCache[termStartTimestamp][
                termEndTimestamp
            ];
            cacheable = false;
        } else if (Time.blockTimestampTruncated() >= termEndTimestamp) {
            resultWad = getRateFromTo(termStartTimestamp, termEndTimestamp);
            cacheable = true;
        } else {
            resultWad = getRateFromTo(
                termStartTimestamp,
                Time.blockTimestampTruncated()
            );
            cacheable = false;
        }
    }

    /// @inheritdoc IRateOracle
    function writeOracleEntry() external virtual override;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.8.9;

/// @title OracleBuffer
/// @notice Provides the value history needed by multiple oracle contracts
/// @dev Instances of stored oracle data, "observations", are collected in the oracle array
/// Every pool is initialized with an oracle array length of 1. Anyone can pay the SSTOREs to increase the
/// maximum length of the oracle array. New slots will be added when the array is fully populated.
/// Observations are overwritten when the full length of the oracle array is populated.
/// The most recent observation is available, independent of the length of the oracle array, by passing 0 to observe()
library OracleBuffer {
    uint256 public constant MAX_BUFFER_LENGTH = 65535;

    /// @dev An Observation fits in one storage slot, keeping gas costs down and allowing `grow()` to pre-pay for gas
    struct Observation {
        // The timesamp in seconds. uint32 allows tiemstamps up to the year 2105. Future versions may wish to use uint40.
        uint32 blockTimestamp;
        /// @dev Even if observedVale is a decimal with 27 decimal places, this still allows decimal values up to 1.053122916685572e+38
        uint216 observedValue;
        bool initialized;
    }

    /// @notice Creates an observation struct from the current timestamp and observed value
    /// @dev blockTimestamp _must_ be chronologically equal to or greater than last.blockTimestamp, safe for 0 or 1 overflows
    /// @param blockTimestamp The timestamp of the new observation
    /// @param observedValue The observed value (semantics may differ for different types of rate oracle)
    /// @return Observation The newly populated observation
    function observation(uint32 blockTimestamp, uint256 observedValue)
        private
        pure
        returns (Observation memory)
    {
        require(observedValue <= type(uint216).max, ">216");
        return
            Observation({
                blockTimestamp: blockTimestamp,
                observedValue: uint216(observedValue),
                initialized: true
            });
    }

    /// @notice Initialize the oracle array by writing the first slot(s). Called once for the lifecycle of the observations array
    /// @param self The stored oracle array
    /// @param times The times to populate in the Oracle buffe (block.timestamps truncated to uint32)
    /// @param observedValues The observed values to populate in the oracle buffer (semantics may differ for different types of rate oracle)
    /// @return cardinality The number of populated elements in the oracle array
    /// @return cardinalityNext The new length of the oracle array, independent of population
    /// @return rateIndex The index of the most recently populated element of the array
    function initialize(
        Observation[MAX_BUFFER_LENGTH] storage self,
        uint32[] memory times,
        uint256[] memory observedValues
    )
        internal
        returns (
            uint16 cardinality,
            uint16 cardinalityNext,
            uint16 rateIndex
        )
    {
        require(times.length < MAX_BUFFER_LENGTH, "MAXT");
        uint16 length = uint16(times.length);
        require(length == observedValues.length, "Lengths must match");
        require(length > 0, "0T");
        uint32 prevTime = 0;
        for (uint16 i = 0; i < length; i++) {
            require(prevTime < times[i], "input unordered");

            self[i] = observation(times[i], observedValues[i]);
            prevTime = times[i];
        }
        return (length, length, length - 1);
    }

    /// @notice Writes an oracle observation to the array
    /// @dev Writable at most once per block. Index represents the most recently written element. cardinality and index must be tracked externally.
    /// If the index is at the end of the allowable array length (according to cardinality), and the next cardinality
    /// is greater than the current one, cardinality may be increased. This restriction is created to preserve ordering.
    /// @param self The stored oracle array
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param blockTimestamp The timestamp of the new observation
    /// @param observedValue The observed value (semantics may differ for different types of rate oracle)
    /// @param cardinality The number of populated elements in the oracle array
    /// @param cardinalityNext The new length of the oracle array, independent of population
    /// @return indexUpdated The new index of the most recently written element in the oracle array
    /// @return cardinalityUpdated The new cardinality of the oracle array
    function write(
        Observation[MAX_BUFFER_LENGTH] storage self,
        uint16 index,
        uint32 blockTimestamp,
        uint256 observedValue,
        uint16 cardinality,
        uint16 cardinalityNext
    ) internal returns (uint16 indexUpdated, uint16 cardinalityUpdated) {
        Observation memory last = self[index];

        // early return if we've already written an observation this block
        if (last.blockTimestamp == blockTimestamp) return (index, cardinality);

        // if the conditions are right, we can bump the cardinality
        if (cardinalityNext > cardinality && index == (cardinality - 1)) {
            cardinalityUpdated = cardinalityNext;
        } else {
            cardinalityUpdated = cardinality;
        }

        indexUpdated = (index + 1) % cardinalityUpdated;
        self[indexUpdated] = observation(blockTimestamp, observedValue);
    }

    /// @notice Prepares the oracle array to store up to `next` observations
    /// @param self The stored oracle array
    /// @param current The current next cardinality of the oracle array
    /// @param next The proposed next cardinality which will be populated in the oracle array
    /// @return next The next cardinality which will be populated in the oracle array
    function grow(
        Observation[MAX_BUFFER_LENGTH] storage self,
        uint16 current,
        uint16 next
    ) internal returns (uint16) {
        require(current > 0, "I");
        require(next < MAX_BUFFER_LENGTH, "buffer limit");
        // no-op if the passed next value isn't greater than the current next value
        if (next <= current) return current;
        // store in each slot to prevent fresh SSTOREs in swaps
        // this data will not be used because the initialized boolean is still false
        for (uint16 i = current; i < next; i++) self[i].blockTimestamp = 1;
        return next;
    }

    /// @notice Fetches the observations beforeOrAt and atOrAfter a target, i.e. where [beforeOrAt, atOrAfter] is satisfied.
    /// The result may be the same observation, or adjacent observations.
    /// @dev The answer must be contained in the array, used when the target is located within the stored observation
    /// boundaries: older than the most recent observation and younger, or the same age as, the oldest observation
    /// @param self The stored oracle array
    /// @param target The timestamp at which the reserved observation should be for
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param cardinality The number of populated elements in the oracle array
    /// @return beforeOrAt The observation recorded before, or at, the target
    /// @return atOrAfter The observation recorded at, or after, the target
    function binarySearch(
        Observation[MAX_BUFFER_LENGTH] storage self,
        uint32 target,
        uint16 index,
        uint16 cardinality
    )
        internal
        view
        returns (Observation memory beforeOrAt, Observation memory atOrAfter)
    {
        uint256 l = (index + 1) % cardinality; // oldest observation
        uint256 r = l + cardinality - 1; // newest observation
        uint256 i;
        while (true) {
            // i = (l + r) / 2;
            i = (l + r) >> 1;

            beforeOrAt = self[i % cardinality];

            // we've landed on an uninitialized tick, keep searching higher (more recently)
            if (!beforeOrAt.initialized) {
                l = i + 1;
                continue;
            }

            atOrAfter = self[(i + 1) % cardinality];

            bool targetAtOrAfter = beforeOrAt.blockTimestamp <= target;

            // check if we've found the answer!
            if (targetAtOrAfter && target <= atOrAfter.blockTimestamp) break;

            if (!targetAtOrAfter) r = i - 1;
            else l = i + 1;
        }
    }

    /// @notice Fetches the observations beforeOrAt and atOrAfter a given target, i.e. where [beforeOrAt, atOrAfter] is satisfied
    /// @dev Assumes there is at least 1 initialized observation.
    /// Used by observeSingle() to compute the counterfactual accumulator values as of a given block timestamp.
    /// @param self The stored oracle array
    /// @param target The timestamp at which the reserved observation should be for. Must be chronologically before currentTime.
    /// @param currentTime The current timestamp, at which currentValue applies.
    /// @param currentValue The current observed value if we were writing a new observation now (semantics may differ for different types of rate oracle)
    /// @param index The index of the observation that was most recently written to the observations array
    /// @param cardinality The number of populated elements in the oracle array
    /// @return beforeOrAt The observation which occurred at, or before, the given timestamp
    /// @return atOrAfter The observation which occurred at, or after, the given timestamp
    function getSurroundingObservations(
        Observation[MAX_BUFFER_LENGTH] storage self,
        uint32 target,
        uint32 currentTime,
        uint256 currentValue,
        uint16 index,
        uint16 cardinality
    )
        internal
        view
        returns (Observation memory beforeOrAt, Observation memory atOrAfter)
    {
        // optimistically set before to the newest observation
        beforeOrAt = self[index];

        // if the target is chronologically at or after the newest observation, we can early return
        if (beforeOrAt.blockTimestamp <= target) {
            if (beforeOrAt.blockTimestamp == target) {
                // if newest observation equals target, we're in the same block, so we can ignore atOrAfter
                return (beforeOrAt, atOrAfter);
            } else {
                // otherwise, we need to transform
                return (beforeOrAt, observation(currentTime, currentValue));
            }
        }

        // now, set before to the oldest observation
        beforeOrAt = self[(index + 1) % cardinality];
        if (!beforeOrAt.initialized) beforeOrAt = self[0];

        // ensure that the target is chronologically at or after the oldest observation
        require(beforeOrAt.blockTimestamp <= target, "OLD");

        // if we've reached this point, we have to binary search
        return binarySearch(self, target, index, cardinality);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../interfaces/rate_oracles/ICompoundRateOracle.sol";
import "../interfaces/compound/ICToken.sol";
import "../core_libraries/FixedAndVariableMath.sol";
import "../utils/WadRayMath.sol";
import "../rate_oracles/BaseRateOracle.sol";

contract CompoundRateOracle is BaseRateOracle, ICompoundRateOracle {
    using OracleBuffer for OracleBuffer.Observation[65535];

    /// @inheritdoc ICompoundRateOracle
    ICToken public override ctoken;

    /// @inheritdoc ICompoundRateOracle
    uint256 public override decimals;

    uint8 public constant override UNDERLYING_YIELD_BEARING_PROTOCOL_ID = 2; // id of compound is 2

    constructor(
        ICToken _ctoken,
        IERC20Minimal underlying,
        uint8 _decimals,
        uint32[] memory _times,
        uint256[] memory _results
    ) BaseRateOracle(underlying) {
        ctoken = _ctoken;
        require(
            ctoken.underlying() == address(underlying),
            "Tokens do not match"
        );
        decimals = _decimals;

        // If we're using even half the max buffer size, something has gone wrong
        require(_times.length < OracleBuffer.MAX_BUFFER_LENGTH / 2, "MAXT");
        uint16 length = uint16(_times.length);
        require(length == _results.length, "Lengths must match");

        // We must pass equal-sized dynamic arrays containing initial timestamps and observed values
        uint32[] memory times = new uint32[](length + 1);
        uint256[] memory results = new uint256[](length + 1);
        for (uint256 i = 0; i < length; i++) {
            times[i] = _times[i];
            results[i] = _results[i];
        }
        times[length] = Time.blockTimestampTruncated();
        results[length] = exchangeRateInRay();
        (
            oracleVars.rateCardinality,
            oracleVars.rateCardinalityNext,
            oracleVars.rateIndex
        ) = observations.initialize(times, results);
    }

    function exchangeRateInRay() internal view returns (uint256 resultRay) {
        uint256 exchangeRateStored = ctoken.exchangeRateStored();
        if (exchangeRateStored == 0) {
            revert CustomErrors.CTokenExchangeRateReturnedZero();
        }

        // cToken exchangeRateStored() returns the current exchange rate as an unsigned integer, scaled by 1 * 10^(10 + Underlying Token Decimals)
        // source: https://compound.finance/docs/ctokens#exchange-rate and https://compound.finance/docs#protocol-math
        // We want the same number scaled by 10^27 (ray)
        // So: if Underlying Token Decimals == 17, no scaling is required
        //     if Underlying Token Decimals > 17, we scale down by a factor of 10^difference
        //     if Underlying Token Decimals < 17, we scale up by a factor of 10^difference
        if (decimals >= 17) {
            uint256 scalingFactor = 10**(decimals - 17);
            resultRay = exchangeRateStored / scalingFactor;
        } else {
            uint256 scalingFactor = 10**(17 - decimals);
            resultRay = exchangeRateStored * scalingFactor;
        }

        return resultRay;
    }

    /// @notice Store the CToken's current exchange rate, in Ray
    /// @param index The index of the Observation that was most recently written to the observations buffer
    /// @param cardinality The number of populated elements in the observations buffer
    /// @param cardinalityNext The new length of the observations buffer, independent of population
    /// @return indexUpdated The new index of the most recently written element in the oracle array
    /// @return cardinalityUpdated The new cardinality of the oracle array
    function writeRate(
        uint16 index,
        uint16 cardinality,
        uint16 cardinalityNext
    ) internal returns (uint16 indexUpdated, uint16 cardinalityUpdated) {
        OracleBuffer.Observation memory last = observations[index];
        uint32 blockTimestamp = Time.blockTimestampTruncated();

        // early return (to increase ttl of data in the observations buffer) if we've already written an observation recently
        if (blockTimestamp - minSecondsSinceLastUpdate < last.blockTimestamp)
            return (index, cardinality);

        uint256 resultRay = exchangeRateInRay();

        emit OracleBufferUpdate(
            Time.blockTimestampScaled(),
            address(this),
            index,
            blockTimestamp,
            resultRay,
            cardinality,
            cardinalityNext
        );

        return
            observations.write(
                index,
                blockTimestamp,
                resultRay,
                cardinality,
                cardinalityNext
            );
    }

    /// @notice Calculates the observed interest returned by the underlying in a given period
    /// @dev Reverts if we have no data point for either timestamp
    /// @param _from The timestamp of the start of the period, in seconds
    /// @param _to The timestamp of the end of the period, in seconds
    /// @return The "floating rate" expressed in Wad, e.g. 4% is encoded as 0.04*10**18 = 4*10**16
    function getRateFromTo(
        uint256 _from,
        uint256 _to //  move docs to IRateOracle. Add additional parameter to use cache and implement cache.
    ) public view override(BaseRateOracle, IRateOracle) returns (uint256) {
        require(_from <= _to, "from > to");

        if (_from == _to) {
            return 0;
        }

        // note that we have to convert comp index into "floating rate" for
        // swap calculations, e.g. an index multiple of 1.04*10**27 corresponds to
        // 0.04*10**27 = 4*10*25
        uint32 currentTime = Time.blockTimestampTruncated();
        uint32 from = Time.timestampAsUint32(_from);
        uint32 to = Time.timestampAsUint32(_to);

        uint256 rateFromRay = observeSingle(
            currentTime,
            from,
            oracleVars.rateIndex,
            oracleVars.rateCardinality
        );
        uint256 rateToRay = observeSingle(
            currentTime,
            to,
            oracleVars.rateIndex,
            oracleVars.rateCardinality
        );

        if (rateToRay > rateFromRay) {
            uint256 result = WadRayMath.rayToWad(
                WadRayMath.rayDiv(rateToRay, rateFromRay) - WadRayMath.RAY
            );
            return result;
        } else {
            return 0;
        }
    }

    function observeSingle(
        uint32 currentTime,
        uint32 queriedTime,
        uint16 index,
        uint16 cardinality
    ) internal view returns (uint256 rateValueRay) {
        if (currentTime < queriedTime) revert CustomErrors.OOO();

        if (currentTime == queriedTime) {
            OracleBuffer.Observation memory rate;
            rate = observations[index];
            if (rate.blockTimestamp != currentTime) {
                rateValueRay = exchangeRateInRay();
            } else {
                rateValueRay = rate.observedValue;
            }
            return rateValueRay;
        }

        uint256 currentValueRay = exchangeRateInRay();
        (
            OracleBuffer.Observation memory beforeOrAt,
            OracleBuffer.Observation memory atOrAfter
        ) = observations.getSurroundingObservations(
                queriedTime,
                currentTime,
                currentValueRay,
                index,
                cardinality
            );

        if (queriedTime == beforeOrAt.blockTimestamp) {
            // we are at the left boundary
            rateValueRay = beforeOrAt.observedValue;
        } else if (queriedTime == atOrAfter.blockTimestamp) {
            // we are at the right boundary
            rateValueRay = atOrAfter.observedValue;
        } else {
            // we are in the middle
            // find apy between beforeOrAt and atOrAfter

            uint256 rateFromBeforeOrAtToAtOrAfterWad;

            // more generally, what should our terminology be to distinguish cases where we represetn a 5% APY as = 1.05 vs. 0.05? We should pick a clear terminology and be use it throughout our descriptions / Hungarian notation / user defined types.

            if (atOrAfter.observedValue > beforeOrAt.observedValue) {
                uint256 rateFromBeforeOrAtToAtOrAfterRay = WadRayMath.rayDiv(
                    atOrAfter.observedValue,
                    beforeOrAt.observedValue
                ) - WadRayMath.RAY;

                rateFromBeforeOrAtToAtOrAfterWad = WadRayMath.rayToWad(
                    rateFromBeforeOrAtToAtOrAfterRay
                );
            }

            uint256 timeInYearsWad = FixedAndVariableMath.accrualFact(
                (atOrAfter.blockTimestamp - beforeOrAt.blockTimestamp) *
                    WadRayMath.wad()
            );

            uint256 apyFromBeforeOrAtToAtOrAfterWad = computeApyFromRate(
                rateFromBeforeOrAtToAtOrAfterWad,
                timeInYearsWad
            );

            // interpolate rateValue for queriedTime
            rateValueRay = interpolateRateValue(
                beforeOrAt.observedValue,
                apyFromBeforeOrAtToAtOrAfterWad,
                (queriedTime - beforeOrAt.blockTimestamp) * WadRayMath.wad()
            );
        }
    }

    function writeOracleEntry() external override(BaseRateOracle, IRateOracle) {
        (oracleVars.rateIndex, oracleVars.rateCardinality) = writeRate(
            oracleVars.rateIndex,
            oracleVars.rateCardinality,
            oracleVars.rateCardinalityNext
        );
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;
import "../compound/ICToken.sol";
import "../rate_oracles/IRateOracle.sol";

interface ICompoundRateOracle is IRateOracle {

    /// @notice Gets the address of the cToken
    /// @return Address of the cToken
    function ctoken() external view returns (ICToken);

    /// @notice Gets the number of decimals of the underlying
    /// @return Number of decimals of the underlying
    function decimals() external view returns (uint);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;
import "../rate_oracles/BaseRateOracle.sol";
import "../rate_oracles/OracleBuffer.sol";
import "../rate_oracles/AaveRateOracle.sol";
import "../interfaces/rate_oracles/IAaveRateOracle.sol";
import "../utils/WadRayMath.sol";
import "hardhat/console.sol";
import "../interfaces/aave/IAaveV2LendingPool.sol";

contract TestRateOracle is AaveRateOracle {
    using OracleBuffer for OracleBuffer.Observation[65535];

    int24 public tick;
    uint128 public liquidity;

    uint256 public latestObservedRateValue;
    uint256 public latestRateFromTo;

    uint256 public latestBeforeOrAtRateValue;
    uint256 public latestAfterOrAtRateValue;

    // rateOracleAddress should be a function of underlyingProtocol and underlyingToken?
    constructor(IAaveV2LendingPool aaveLendingPool, IERC20Minimal underlying)
        AaveRateOracle(
            aaveLendingPool,
            underlying,
            new uint32[](0),
            new uint256[](0)
        )
    {
        // if not done manually, doesn't work for some reason
        aaveLendingPool = aaveLendingPool;
        underlying = underlying;
    }

    // function getOracleVars()
    //     external
    //     view
    //     returns (
    //         uint16,
    //         uint16,
    //         uint16
    //     )
    // {
    //     return (
    //         oracleVars.rateIndex,
    //         oracleVars.rateCardinality,
    //         oracleVars.rateCardinalityNext
    //     );
    // }

    function getRate(uint16 index) external view returns (uint256, uint256) {
        OracleBuffer.Observation memory rate = observations[index];
        return (rate.blockTimestamp, rate.observedValue);
    }

    function testObserveSingle(uint32 queriedTime)
        external
        returns (uint256 observedValue)
    {
        latestObservedRateValue = observeSingle(
            Time.blockTimestampTruncated(),
            queriedTime,
            oracleVars.rateIndex,
            oracleVars.rateCardinality
        );
        return latestObservedRateValue;
    }

    function testGrow(uint16 _rateCardinalityNext) external {
        oracleVars.rateCardinalityNext = observations.grow(
            oracleVars.rateCardinalityNext,
            _rateCardinalityNext
        );
    }

    // function testBinarySearch(uint32 target)
    //     external
    //     view
    //     returns (uint256 beforeOrAtRateValue, uint256 afterOrAtRateValue)
    // {
    //     (OracleBuffer.Observation memory beforeOrAt, OracleBuffer.Observation memory atOrAfter) = observations.binarySearch(
    //         Time.blockTimestampTruncated(),
    //         target,
    //         oracleVars.rateIndex,
    //         oracleVars.rateCardinality
    //     );
    //     beforeOrAtRateValue = beforeOrAt.observedValue;
    //     afterOrAtRateValue = atOrAfter.observedValue;
    // }
    function binarySearch(uint32 target)
        external
        view
        returns (
            OracleBuffer.Observation memory beforeOrAt,
            OracleBuffer.Observation memory atOrAfter
        )
    {
        return
            observations.binarySearch(
                target,
                oracleVars.rateIndex,
                oracleVars.rateCardinality
            );
    }

    function testGetSurroundingRates(uint32 target) external {
        uint256 currentValue = IAaveV2LendingPool(aaveLendingPool)
            .getReserveNormalizedIncome(underlying);
        (
            OracleBuffer.Observation memory beforeOrAt,
            OracleBuffer.Observation memory atOrAfter
        ) = observations.getSurroundingObservations(
                target,
                Time.blockTimestampTruncated(),
                currentValue,
                oracleVars.rateIndex,
                oracleVars.rateCardinality
            );

        latestBeforeOrAtRateValue = beforeOrAt.observedValue;
        latestAfterOrAtRateValue = atOrAfter.observedValue;
    }

    function testComputeApyFromRate(uint256 rateFromTo, uint256 timeInYears)
        external
        pure
        returns (uint256)
    {
        return computeApyFromRate(rateFromTo, timeInYears);
    }

    // Checks that the observed value is within 0.0000001% of the expected value
    function rayValueIsCloseTo(
        uint256 observedValueInRay,
        uint256 expectedValueInRay
    ) external pure returns (bool) {
        uint256 upperBoundFactor = 1000000001 * 1e18;
        uint256 lowerBoundFactor = 999999999 * 1e18;
        uint256 upperBound = WadRayMath.rayMul(
            expectedValueInRay,
            upperBoundFactor
        );
        uint256 lowerBound = WadRayMath.rayMul(
            expectedValueInRay,
            lowerBoundFactor
        );
        // console.log('%s <= %s <= %s ??', lowerBound,observedValueInRay, upperBound);
        if (
            observedValueInRay <= upperBound && observedValueInRay >= lowerBound
        ) {
            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "../interfaces/rate_oracles/IAaveRateOracle.sol";
import "../interfaces/aave/IAaveV2LendingPool.sol";
import "../core_libraries/FixedAndVariableMath.sol";
import "../utils/WadRayMath.sol";
import "../rate_oracles/BaseRateOracle.sol";
import "./OracleBuffer.sol";

contract AaveRateOracle is BaseRateOracle, IAaveRateOracle {
    using OracleBuffer for OracleBuffer.Observation[65535];

    /// @inheritdoc IAaveRateOracle
    IAaveV2LendingPool public override aaveLendingPool;

    uint8 public constant override UNDERLYING_YIELD_BEARING_PROTOCOL_ID = 1; // id of aave v2 is 1

    constructor(
        IAaveV2LendingPool _aaveLendingPool,
        IERC20Minimal _underlying,
        uint32[] memory _times,
        uint256[] memory _results
    ) BaseRateOracle(_underlying) {
        require(
            address(_aaveLendingPool) != address(0),
            "aave pool must exist"
        );
        aaveLendingPool = _aaveLendingPool;
        require(address(_underlying) != address(0), "underlying must exist");

        // If we're using even half the max buffer size, something has gone wrong
        require(_times.length < OracleBuffer.MAX_BUFFER_LENGTH / 2, "MAXT");
        uint16 length = uint16(_times.length);
        require(length == _results.length, "Lengths must match");

        // We must pass equal-sized dynamic arrays containing initial timestamps and observed values
        uint32[] memory times = new uint32[](length + 1);
        uint256[] memory results = new uint256[](length + 1);
        for (uint256 i = 0; i < length; i++) {
            times[i] = _times[i];
            results[i] = _results[i];
        }
        times[length] = Time.blockTimestampTruncated();
        results[length] = aaveLendingPool.getReserveNormalizedIncome(
            _underlying
        );
        (
            oracleVars.rateCardinality,
            oracleVars.rateCardinalityNext,
            oracleVars.rateIndex
        ) = observations.initialize(times, results);
    }

    /// @notice Store the Aave Lending Pool's current normalized income per unit of an underlying asset, in Ray
    /// @param index The index of the Observation that was most recently written to the observations buffer
    /// @param cardinality The number of populated elements in the observations buffer
    /// @param cardinalityNext The new length of the observations buffer, independent of population
    /// @return indexUpdated The new index of the most recently written element in the oracle array
    /// @return cardinalityUpdated The new cardinality of the oracle array
    function writeRate(
        uint16 index,
        uint16 cardinality,
        uint16 cardinalityNext
    ) internal returns (uint16 indexUpdated, uint16 cardinalityUpdated) {
        OracleBuffer.Observation memory last = observations[index];
        uint32 blockTimestamp = Time.blockTimestampTruncated();

        // early return (to increase ttl of data in the observations buffer) if we've already written an observation recently
        if (blockTimestamp - minSecondsSinceLastUpdate < last.blockTimestamp)
            return (index, cardinality);

        uint256 resultRay = aaveLendingPool.getReserveNormalizedIncome(
            underlying
        );
        if (resultRay == 0) {
            revert CustomErrors.AavePoolGetReserveNormalizedIncomeReturnedZero();
        }

        emit OracleBufferUpdate(
            Time.blockTimestampScaled(),
            address(this),
            index,
            blockTimestamp,
            resultRay,
            cardinality,
            cardinalityNext
        );

        return
            observations.write(
                index,
                blockTimestamp,
                resultRay,
                cardinality,
                cardinalityNext
            );
    }

    /// @notice Calculates the observed interest returned by the underlying in a given period
    /// @dev Reverts if we have no data point for either timestamp
    /// @param _from The timestamp of the start of the period, in seconds
    /// @param _to The timestamp of the end of the period, in seconds
    /// @return The "floating rate" expressed in Wad, e.g. 4% is encoded as 0.04*10**18 = 4*10**16
    function getRateFromTo(
        uint256 _from,
        uint256 _to //  move docs to IRateOracle. Add additional parameter to use cache and implement cache.
    ) public view override(BaseRateOracle, IRateOracle) returns (uint256) {
        require(_from <= _to, "from > to");

        if (_from == _to) {
            return 0;
        }

        // note that we have to convert aave index into "floating rate" for
        // swap calculations, e.g. an index multiple of 1.04*10**27 corresponds to
        // 0.04*10**27 = 4*10*25
        uint32 currentTime = Time.blockTimestampTruncated();
        uint32 from = Time.timestampAsUint32(_from);
        uint32 to = Time.timestampAsUint32(_to);

        uint256 rateFromRay = observeSingle(
            currentTime,
            from,
            oracleVars.rateIndex,
            oracleVars.rateCardinality
        );
        uint256 rateToRay = observeSingle(
            currentTime,
            to,
            oracleVars.rateIndex,
            oracleVars.rateCardinality
        );

        if (rateToRay > rateFromRay) {
            uint256 result = WadRayMath.rayToWad(
                WadRayMath.rayDiv(rateToRay, rateFromRay) - WadRayMath.RAY
            );
            return result;
        } else {
            return 0;
        }
    }

    function observeSingle(
        uint32 currentTime,
        uint32 queriedTime,
        uint16 index,
        uint16 cardinality
    ) internal view returns (uint256 rateValueRay) {
        if (currentTime < queriedTime) revert CustomErrors.OOO();

        if (currentTime == queriedTime) {
            OracleBuffer.Observation memory rate;
            rate = observations[index];
            if (rate.blockTimestamp != currentTime) {
                rateValueRay = aaveLendingPool.getReserveNormalizedIncome(
                    underlying
                );
            } else {
                rateValueRay = rate.observedValue;
            }
            return rateValueRay;
        }

        uint256 currentValueRay = aaveLendingPool.getReserveNormalizedIncome(
            underlying
        );
        (
            OracleBuffer.Observation memory beforeOrAt,
            OracleBuffer.Observation memory atOrAfter
        ) = observations.getSurroundingObservations(
                queriedTime,
                currentTime,
                currentValueRay,
                index,
                cardinality
            );

        if (queriedTime == beforeOrAt.blockTimestamp) {
            // we are at the left boundary
            rateValueRay = beforeOrAt.observedValue;
        } else if (queriedTime == atOrAfter.blockTimestamp) {
            // we are at the right boundary
            rateValueRay = atOrAfter.observedValue;
        } else {
            // we are in the middle
            // find apy between beforeOrAt and atOrAfter

            uint256 rateFromBeforeOrAtToAtOrAfterWad;

            // more generally, what should our terminology be to distinguish cases where we represetn a 5% APY as = 1.05 vs. 0.05? We should pick a clear terminology and be use it throughout our descriptions / Hungarian notation / user defined types.

            if (atOrAfter.observedValue > beforeOrAt.observedValue) {
                uint256 rateFromBeforeOrAtToAtOrAfterRay = WadRayMath.rayDiv(
                    atOrAfter.observedValue,
                    beforeOrAt.observedValue
                ) - WadRayMath.RAY;

                rateFromBeforeOrAtToAtOrAfterWad = WadRayMath.rayToWad(
                    rateFromBeforeOrAtToAtOrAfterRay
                );
            }

            uint256 timeInYearsWad = FixedAndVariableMath.accrualFact(
                (atOrAfter.blockTimestamp - beforeOrAt.blockTimestamp) *
                    WadRayMath.wad()
            );

            uint256 apyFromBeforeOrAtToAtOrAfterWad = computeApyFromRate(
                rateFromBeforeOrAtToAtOrAfterWad,
                timeInYearsWad
            );

            // interpolate rateValue for queriedTime
            rateValueRay = interpolateRateValue(
                beforeOrAt.observedValue,
                apyFromBeforeOrAtToAtOrAfterWad,
                (queriedTime - beforeOrAt.blockTimestamp) * WadRayMath.wad()
            );
        }
    }

    function writeOracleEntry() external override(BaseRateOracle, IRateOracle) {
        // In the case of Aave, the values we write are obtained by calling aaveLendingPool.getReserveNormalizedIncome(underlying)
        (oracleVars.rateIndex, oracleVars.rateCardinality) = writeRate(
            oracleVars.rateIndex,
            oracleVars.rateCardinality,
            oracleVars.rateCardinalityNext
        );
    }
}

// SPDX-License-Identifier: agpl-3.0

pragma solidity =0.8.9;

import "../interfaces/aave/IAaveV2LendingPool.sol";
import "../interfaces/aave/IAToken.sol";
import "../utils/WadRayMath.sol";
import "../utils/Printer.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockAToken is IAToken, ERC20 {
    using WadRayMath for uint256;
    IAaveV2LendingPool internal _pool;
    IERC20Minimal internal _underlyingAsset;

    modifier onlyLendingPool() {
        require(msg.sender == address(_pool), "CT_CALLER_MUST_BE_LENDING_POOL");
        _;
    }

    constructor(
        IAaveV2LendingPool pool,
        IERC20Minimal underlyingAsset,
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) {
        _pool = pool;
        _underlyingAsset = underlyingAsset;
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override(ERC20)
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev Calculates the balance of the user: principal balance + interest generated by the principal
     * @param user The user whose balance is calculated
     * @return The balance of the user
     **/
    function balanceOf(address user)
        public
        view
        override(ERC20)
        returns (uint256)
    {
        return
            super.balanceOf(user).rayMul(
                _pool.getReserveNormalizedIncome(_underlyingAsset)
            );
    }

    // AB: only lending pool modifier removed from the original AToken implementation
    /**
     * @dev Mints `amount` aTokens to `user`
     * - Only callable by the LendingPool, as extra state updates there need to be managed
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external override returns (bool) {
        uint256 previousBalance = super.balanceOf(user);

        uint256 amountScaled = amount.rayDiv(index);

        require(amountScaled != 0, "CT_INVALID_MINT_AMOUNT");
        _mint(user, amountScaled);

        emit Transfer(address(0), user, amount);

        return previousBalance == 0;
    }

    /**
     * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * - Only callable by the LendingPool, as extra state updates there need to be managed
     * @param user The owner of the aTokens, getting them burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external override onlyLendingPool {
        uint256 amountScaled = amount.rayDiv(index);
        require(amountScaled != 0, "CT_INVALID_BURN_AMOUNT");
        _burn(user, amountScaled);

        // AB: changed from safeTransfer to transfer for simplicity
        IERC20Minimal(_underlyingAsset).transfer(receiverOfUnderlying, amount);

        emit Transfer(user, address(0), amount);
    }

    /**
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
     * updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user)
        external
        view
        override
        returns (uint256)
    {
        return super.balanceOf(user);
    }

    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address user)
        external
        view
        override
        returns (uint256, uint256)
    {
        return (super.balanceOf(user), super.totalSupply());
    }

    /**
     * @dev calculates the total supply of the specific aToken
     * since the balance of every single user increases over time, the total supply
     * does that too.
     * @return the current total supply
     **/
    // AB: when add IERC20Minimal to the override: Invalid contract specified in override list: "IERC20Minimal" (investigate)
    // https://github.com/aave/protocol-v2/blob/61c2273a992f655c6d3e7d716a0c2f1b97a55a92/contracts/protocol/tokenization/AToken.sol#L248
    function totalSupply() public view override(ERC20) returns (uint256) {
        uint256 currentSupplyScaled = super.totalSupply();

        if (currentSupplyScaled == 0) {
            return 0;
        }

        return
            currentSupplyScaled.rayMul(
                _pool.getReserveNormalizedIncome(_underlyingAsset)
            );
    }

    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return the scaled total supply
     **/
    function scaledTotalSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return super.totalSupply();
    }

    /**
     * @dev Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
     **/
    function UNDERLYING_ASSET_ADDRESS()
        public
        view
        override
        returns (IERC20Minimal)
    {
        return _underlyingAsset;
    }

    /**
     * @dev Returns the address of the lending pool where this aToken is used
     **/
    function POOL() public view returns (IAaveV2LendingPool) {
        return _pool;
    }

    /**
     * @dev Transfers the aTokens between two users. Validates the transfer
     * (ie checks for valid HF after the transfer) if required
     * @param from The source address
     * @param to The destination address
     * @param amount The amount getting transferred
     **/
    // AB: removed validate parameter
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        IERC20Minimal underlyingAsset = _underlyingAsset;
        IAaveV2LendingPool pool = _pool;

        uint256 index = pool.getReserveNormalizedIncome(underlyingAsset);

        super._transfer(from, to, amount.rayDiv(index));
    }

    function approveInternal(
        address owner,
        address spender,
        uint256 value
    ) public {
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;
import "./interfaces/IFactory.sol";
import "./interfaces/IPeriphery.sol";
import "./interfaces/rate_oracles/IRateOracle.sol";
import "./interfaces/IMarginEngine.sol";
import "./interfaces/IVAMM.sol";
import "./interfaces/fcms/IFCM.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "contracts/utils/CustomErrors.sol";

contract VoltzERC1967Proxy is ERC1967Proxy, CustomErrors {
  constructor(address _logic, bytes memory _data) payable ERC1967Proxy(_logic, _data) {}
}


/// @title Voltz Factory Contract
/// @notice Deploys Voltz VAMMs and MarginEngines and manages ownership and control over amm protocol fees
// Following this example https://github.com/OriginProtocol/minimal-proxy-example/blob/master/contracts/PairFactory.sol
contract Factory is IFactory, Ownable {

  /// @dev master MarginEngine implementation that MarginEngine proxies can delegate call to
  IMarginEngine public override masterMarginEngine;

  /// @dev master VAMM implementation that VAMM proxies can delegate call to
  IVAMM public override masterVAMM;

  /// @dev yieldBearingProtocolID --> master FCM implementation for the underlying yield bearing protocol with the corresponding id
  mapping(uint8 => IFCM) public override masterFCMs;

  /// @dev owner --> integration contract address --> isApproved
  /// @dev if an owner wishes to allow a given intergration contract to act on thir behalf with Voltz Core
  /// @dev they need to set the approval via the setApproval function
  mapping(address => mapping(address => bool)) private _isApproved;
  
  /// @dev Voltz Periphery
  IPeriphery public override periphery;  

  function setApproval(address intAddress, bool allowIntegration) external override {
    _isApproved[msg.sender][intAddress] = allowIntegration;
    emit Approval(msg.sender, intAddress, allowIntegration);
  }

  function isApproved(address _owner, address _intAddress) override view public returns (bool) {

    require(_owner != address(0), "owner does not exist");
    require(_intAddress != address(0), "int does not exist");

    /// @dev Voltz periphery is always approved to act on behalf of the owner
    if (_intAddress == address(periphery)) {
      return true;
    } else {
      return _isApproved[_owner][_intAddress];
    }

  }

  constructor(IMarginEngine _masterMarginEngine, IVAMM _masterVAMM) {
    require(address(_masterMarginEngine) != address(0), "master me must exist");
    require(address(_masterVAMM) != address(0), "master vamm must exist");

    masterMarginEngine = _masterMarginEngine;
    masterVAMM = _masterVAMM;
  }

  function setMasterFCM(IFCM _masterFCM, uint8 _yieldBearingProtocolID) external override onlyOwner {

    require(address(_masterFCM) != address(0), "master fcm must exist");
    masterFCMs[_yieldBearingProtocolID] = _masterFCM;
    emit MasterFCM(_masterFCM, _yieldBearingProtocolID);
  }

  function setMasterMarginEngine(IMarginEngine _masterMarginEngine) external override onlyOwner {
    require(address(_masterMarginEngine) != address(0), "master me must exist");

    if (address(masterMarginEngine) != address(_masterMarginEngine)) {
      masterMarginEngine = _masterMarginEngine;
    }

  }


  function setMasterVAMM(IVAMM _masterVAMM) external override onlyOwner {

    require(address(_masterVAMM) != address(0), "master vamm must exist");

    if (address(masterVAMM) != address(_masterVAMM)) {
      masterVAMM = _masterVAMM;
    }

  }


  function setPeriphery(IPeriphery _periphery) external override onlyOwner {
    
    require(address(_periphery) != address(0), "periphery must exist");

    if (address(periphery) != address(_periphery)) {
      periphery = _periphery;
      emit PeripheryUpdate(periphery);
    }

  }


  function deployIrsInstance(IERC20Minimal _underlyingToken, IRateOracle _rateOracle, uint256 _termStartTimestampWad, uint256 _termEndTimestampWad, int24 _tickSpacing) external override onlyOwner returns (IMarginEngine marginEngineProxy, IVAMM vammProxy, IFCM fcmProxy) {
    IMarginEngine marginEngine = IMarginEngine(address(new VoltzERC1967Proxy(address(masterMarginEngine), "")));
    IVAMM vamm = IVAMM(address(new VoltzERC1967Proxy(address(masterVAMM), "")));
    marginEngine.initialize(_underlyingToken, _rateOracle, _termStartTimestampWad, _termEndTimestampWad);
    vamm.initialize(marginEngine, _tickSpacing);
    marginEngine.setVAMM(vamm);

    IRateOracle r = IRateOracle(_rateOracle);
    require(r.underlying() == _underlyingToken, "Tokens do not match");
    uint8 yieldBearingProtocolID = r.UNDERLYING_YIELD_BEARING_PROTOCOL_ID();
    IFCM _masterFCM = masterFCMs[yieldBearingProtocolID];
    IFCM fcm;

    if (address(_masterFCM) != address(0)) {
      fcm = IFCM(address(new VoltzERC1967Proxy(address(_masterFCM), "")));
      fcm.initialize(vamm, marginEngine);
      marginEngine.setFCM(fcm);
      Ownable(address(fcm)).transferOwnership(msg.sender);
    }

    uint8 underlyingTokenDecimals = _underlyingToken.decimals();

    emit IrsInstance(_underlyingToken, _rateOracle, _termStartTimestampWad, _termEndTimestampWad, _tickSpacing, marginEngine, vamm, fcm, yieldBearingProtocolID, underlyingTokenDecimals);

    // Transfer ownership of all instances to the factory owner
    Ownable(address(vamm)).transferOwnership(msg.sender);
    Ownable(address(marginEngine)).transferOwnership(msg.sender);

    return(marginEngine, vamm, fcm);
  }



}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlot.BooleanSlot storage rollbackTesting = StorageSlot.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            Address.functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;

import "../core_libraries/Tick.sol";

contract TickTest {
    using Tick for mapping(int24 => Tick.Info);

    mapping(int24 => Tick.Info) public ticks;

    function setTick(int24 tick, Tick.Info memory info) external {
        ticks[tick] = info;
    }

    // DONE
    function checkTicks(int24 tickLower, int24 tickUpper) public pure {
        return Tick.checkTicks(tickLower, tickUpper);
    }

    // DONE
    function getFeeGrowthInside(
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        uint256 feeGrowthGlobalX128
    ) external view returns (uint256 feeGrowthInsideX128) {
        return
            ticks.getFeeGrowthInside(
                Tick.FeeGrowthInsideParams(
                    tickLower,
                    tickUpper,
                    tickCurrent,
                    feeGrowthGlobalX128
                )
            );
    }

    // DONE
    // function tickSpacingToMaxLiquidityPerTick(int24 tickSpacing)
    //     public
    //     pure
    //     returns (uint128)
    // {
    //     return Tick.tickSpacingToMaxLiquidityPerTick(tickSpacing);
    // }

    // DONE
    function getVariableTokenGrowthInside(
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        int256 variableTokenGrowthGlobalX128
    ) public view returns (int256 variableTokenGrowthInsideX128) {
        return
            ticks.getVariableTokenGrowthInside(
                Tick.VariableTokenGrowthInsideParams({
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    tickCurrent: tickCurrent,
                    variableTokenGrowthGlobalX128: variableTokenGrowthGlobalX128
                })
            );
    }

    // DONE
    function getFixedTokenGrowthInside(
        int24 tickLower,
        int24 tickUpper,
        int24 tickCurrent,
        int256 fixedTokenGrowthGlobalX128
    ) public view returns (int256 fixedTokenGrowthInsideX128) {
        return
            ticks.getFixedTokenGrowthInside(
                Tick.FixedTokenGrowthInsideParams({
                    tickLower: tickLower,
                    tickUpper: tickUpper,
                    tickCurrent: tickCurrent,
                    fixedTokenGrowthGlobalX128: fixedTokenGrowthGlobalX128
                })
            );
    }

    // DONE
    function update(
        int24 tick,
        int24 tickCurrent,
        int128 liquidityDelta,
        int256 fixedTokenGrowthGlobalX128,
        int256 variableTokenGrowthGlobalX128,
        uint256 feeGrowthGlobalX128,
        bool upper,
        uint128 maxLiquidity
    ) external returns (bool flipped) {
        return
            ticks.update(
                tick,
                tickCurrent,
                liquidityDelta,
                fixedTokenGrowthGlobalX128,
                variableTokenGrowthGlobalX128,
                feeGrowthGlobalX128,
                upper,
                maxLiquidity
            );
    }

    // DONE
    function clear(int24 tick) external {
        ticks.clear(tick);
    }

    // DONE
    function cross(
        int24 tick,
        int256 fixedTokenGrowthGlobalX128,
        int256 variableTokenGrowthGlobalX128,
        uint256 feeGrowthGlobalX128
    ) external returns (int128 liquidityNet) {
        return
            ticks.cross(
                tick,
                fixedTokenGrowthGlobalX128,
                variableTokenGrowthGlobalX128,
                feeGrowthGlobalX128
            );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;

import "../core_libraries/MarginCalculator.sol";
import "../core_libraries/FixedAndVariableMath.sol";

contract MarginCalculatorTest {
    function getAbsoluteFixedTokenDeltaUnbalancedSimulatedUnwind(
        uint256 variableTokenDeltaAbsolute,
        uint160 sqrtRatioCurrX96,
        uint256 startingFixedRateMultiplierWad,
        uint256 fixedRateDeviationMinWad,
        uint256 termEndTimestampWad,
        uint256 currentTimestampWad,
        uint256 tMaxWad,
        uint256 gammaWad,
        bool isFTUnwind
    ) external pure returns (uint256 fixedTokenDeltaUnbalanced) {
        return
            MarginCalculator
                .getAbsoluteFixedTokenDeltaUnbalancedSimulatedUnwind(
                    variableTokenDeltaAbsolute,
                    sqrtRatioCurrX96,
                    startingFixedRateMultiplierWad,
                    fixedRateDeviationMinWad,
                    termEndTimestampWad,
                    currentTimestampWad,
                    tMaxWad,
                    gammaWad,
                    isFTUnwind
                );
    }

    function computeTimeFactor(
        uint256 termEndTimestampWad,
        uint256 currentTimestampWad,
        IMarginEngine.MarginCalculatorParameters
            memory _marginCalculatorParameters
    ) external pure returns (int256 timeFactor) {
        return
            MarginCalculator.computeTimeFactor(
                termEndTimestampWad,
                currentTimestampWad,
                _marginCalculatorParameters
            );
    }

    function computeApyBound(
        uint256 termEndTimestampWad,
        uint256 currentTimestampWad,
        uint256 historicalApyWad,
        bool isUpper,
        IMarginEngine.MarginCalculatorParameters
            memory _marginCalculatorParameters
    ) external pure returns (uint256 apyBoundWad) {
        return
            MarginCalculator.computeApyBound(
                termEndTimestampWad,
                currentTimestampWad,
                historicalApyWad,
                isUpper,
                _marginCalculatorParameters
            );
    }

    function worstCaseVariableFactorAtMaturity(
        uint256 timeInSecondsFromStartToMaturityWad,
        uint256 termEndTimestampWad,
        uint256 currentTimestampWad,
        bool isFT,
        bool isLM,
        uint256 historicalApyWad,
        IMarginEngine.MarginCalculatorParameters
            memory _marginCalculatorParameters
    ) external pure returns (uint256 variableFactorWad) {
        return
            MarginCalculator.worstCaseVariableFactorAtMaturity(
                timeInSecondsFromStartToMaturityWad,
                termEndTimestampWad,
                currentTimestampWad,
                isFT,
                isLM,
                historicalApyWad,
                _marginCalculatorParameters
            );
    }

    function getFixedTokenBalanceFromMCTest(
        int256 amount0,
        int256 amount1,
        uint256 accruedVariableFactor,
        uint256 termStartTimestamp,
        uint256 termEndTimestamp
    ) external view returns (int256 fixedTokenBalance) {
        return
            FixedAndVariableMath.getFixedTokenBalance(
                amount0,
                amount1,
                accruedVariableFactor,
                termStartTimestamp,
                termEndTimestamp
            );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;

import "../core_libraries/FixedAndVariableMath.sol";

contract FixedAndVariableMathTest {
    function calculateSettlementCashflow(
        int256 fixedTokenBalance,
        int256 variableTokenBalance,
        uint256 termStartTimestamp,
        uint256 termEndTimestamp,
        uint256 variableFactorToMaturity
    ) external view returns (int256 cashflow) {
        return
            FixedAndVariableMath.calculateSettlementCashflow(
                fixedTokenBalance,
                variableTokenBalance,
                termStartTimestamp,
                termEndTimestamp,
                variableFactorToMaturity
            );
    }

    function accrualFact(uint256 timeInSeconds)
        public
        pure
        returns (uint256 timeInYears)
    {
        return FixedAndVariableMath.accrualFact(timeInSeconds);
    }

    function fixedFactorTest(
        bool atMaturity,
        uint256 termStartTimestamp,
        uint256 termEndTimestamp
    ) public view returns (uint256 fixedFactorValue) {
        return
            FixedAndVariableMath.fixedFactor(
                atMaturity,
                termStartTimestamp,
                termEndTimestamp
            );
    }

    function calculateFixedTokenBalance(
        int256 amount0,
        int256 excessBalance,
        uint256 termStartTimestamp,
        uint256 termEndTimestamp
    ) public view returns (int256 fixedTokenBalance) {
        return
            FixedAndVariableMath.calculateFixedTokenBalance(
                amount0,
                excessBalance,
                termStartTimestamp,
                termEndTimestamp
            );
    }

    function getExcessBalance(
        int256 amount0,
        int256 amount1,
        uint256 accruedVariableFactor,
        uint256 termStartTimestamp,
        uint256 termEndTimestamp
    ) public view returns (int256) {
        return
            FixedAndVariableMath.getExcessBalance(
                amount0,
                amount1,
                accruedVariableFactor,
                termStartTimestamp,
                termEndTimestamp
            );
    }

    function getFixedTokenBalance(
        int256 amount0,
        int256 amount1,
        uint256 accruedVariableFactor,
        uint256 termStartTimestamp,
        uint256 termEndTimestamp
    ) external view returns (int256 fixedTokenBalance) {
        return
            FixedAndVariableMath.getFixedTokenBalance(
                amount0,
                amount1,
                accruedVariableFactor,
                termStartTimestamp,
                termEndTimestamp
            );
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity =0.8.9;

import "./interfaces/fcms/IFCM.sol";
import "./interfaces/fcms/ICompoundFCM.sol";
import "./storage/FCMStorage.sol";
import "./core_libraries/TraderWithYieldBearingAssets.sol";
import "./interfaces/IERC20Minimal.sol";
import "./interfaces/IVAMM.sol";
import "./interfaces/rate_oracles/ICompoundRateOracle.sol";
import "prb-math/contracts/PRBMathUD60x18.sol";
import "./core_libraries/FixedAndVariableMath.sol";
import "./interfaces/rate_oracles/IRateOracle.sol";
import "./utils/WadRayMath.sol";
import "./utils/Printer.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./core_libraries/SafeTransferLib.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract CompoundFCM is CompoundFCMStorage, IFCM, ICompoundFCM, Initializable, OwnableUpgradeable, PausableUpgradeable, UUPSUpgradeable {

  using WadRayMath for uint256;
  using SafeCast for uint256;
  using SafeCast for int256;

  using TraderWithYieldBearingAssets for TraderWithYieldBearingAssets.Info;

  using SafeTransferLib for IERC20Minimal;

  /// @dev modifier which checks if the msg.sender is not equal to the address of the MarginEngine, if that's the case, a revert is raised
  modifier onlyMarginEngine () {
    if (msg.sender != address(_marginEngine)) {
        revert CustomErrors.OnlyMarginEngine();
    }
    _;
  }

  // https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor () initializer {}

  /// @dev in the initialize function we set the vamm and the margiEngine associated with the fcm
  function initialize(IVAMM __vamm, IMarginEngine __marginEngine) external override initializer {
    /// @dev we additionally cache the rateOracle, _aaveLendingPool, underlyingToken, cToken
    _vamm = __vamm;
    _marginEngine = __marginEngine;
    _rateOracle = _marginEngine.rateOracle();
    underlyingToken = _marginEngine.underlyingToken();
    _ctoken = ICToken(ICompoundRateOracle(address(_rateOracle)).ctoken());
    tickSpacing = _vamm.tickSpacing(); // retrieve tick spacing of the VAM

    __Ownable_init();
    __Pausable_init();
    __UUPSUpgradeable_init();
  }

    // GETTERS FOR STORAGE SLOTS
    // Not auto-generated by public variables in the storage contract, cos solidity doesn't support that for functions that implement an interface
    /// @inheritdoc ICompoundFCM
    function cToken() external view override returns (ICToken) {
        return _ctoken;
    }
    /// @inheritdoc IFCM
    function marginEngine() external view override returns (IMarginEngine) {
        return _marginEngine;
    }
    /// @inheritdoc IFCM
    function vamm() external view override returns (IVAMM) {
        return _vamm;
    }
    /// @inheritdoc IFCM
    function rateOracle() external view override returns (IRateOracle) {
        return _rateOracle;
    }

  // To authorize the owner to upgrade the contract we implement _authorizeUpgrade with the onlyOwner modifier.
  // ref: https://forum.openzeppelin.com/t/uups-proxies-tutorial-solidity-javascript/7786
  function _authorizeUpgrade(address) internal override onlyOwner {}

  function getTraderWithYieldBearingAssets(
        address trader
    ) external override view returns (TraderWithYieldBearingAssets.Info memory traderInfo) {
      return traders[trader];
    }


  /// @notice Initiate a Fully Collateralised Fixed Taker Swap
  /// @param notional Notional that cover by a fully collateralised fixed taker interest rate swap
  /// @param sqrtPriceLimitX96 The binary fixed point math representation of the sqrtPriceLimit beyond which the fixed taker swap will not be executed with the VAMM
  function initiateFullyCollateralisedFixedTakerSwap(uint256 notional, uint160 sqrtPriceLimitX96) external override returns 
    (int256 fixedTokenDelta, int256 variableTokenDelta, uint256 cumulativeFeeIncurred, int256 fixedTokenDeltaUnbalanced) {

    require(notional!=0, "notional = 0");

    // initiate a swap
    // the default tick range for a Position associated with the FCM is tickLower: -tickSpacing and tickUpper: tickSpacing
    // isExternal is true since the state updates following a VAMM induced swap are done in the FCM (below)
    IVAMM.SwapParams memory params = IVAMM.SwapParams({
        recipient: address(this),
        amountSpecified: notional.toInt256(),
        sqrtPriceLimitX96: sqrtPriceLimitX96,
        tickLower: -tickSpacing,
        tickUpper: tickSpacing
    });

    (fixedTokenDelta, variableTokenDelta, cumulativeFeeIncurred, fixedTokenDeltaUnbalanced,) = _vamm.swap(params);

    require(variableTokenDelta <=0, "VT delta sign");

    TraderWithYieldBearingAssets.Info storage trader = traders[msg.sender];

    // When dealing with wei (or smallest unit of tokens), rather than human denominations like USD and cUSD, we can simply
    // divide the underlying wei value by the exchange rate to get the number of ctoken wei
    uint256 currentExchangeRate = _ctoken.exchangeRateCurrent();

    uint256 yieldBearingTokenDelta = uint256(-variableTokenDelta).wadDiv(currentExchangeRate);
    uint256 updatedTraderMargin = trader.marginInScaledYieldBearingTokens + yieldBearingTokenDelta;
    trader.updateMarginInScaledYieldBearingTokens(updatedTraderMargin);

    // update trader fixed and variable token balances
    trader.updateBalancesViaDeltas(fixedTokenDelta, variableTokenDelta);

    // deposit notional executed in terms of cTokens (e.g. cDAI) to fully collateralise the position
    // we need a number of tokens equal to the variable token delta divided by the exchange rate
    IERC20Minimal(address(_ctoken)).safeTransferFrom(msg.sender, address(this), yieldBearingTokenDelta);

    // transfer fees to the margin engine (in terms of the underlyingToken e.g. DAI)
    underlyingToken.safeTransferFrom(msg.sender, address(_marginEngine), cumulativeFeeIncurred);

    emit FullyCollateralisedSwap(
      msg.sender,
      notional,
      sqrtPriceLimitX96,
      cumulativeFeeIncurred,
      fixedTokenDelta, 
      variableTokenDelta,
      fixedTokenDeltaUnbalanced
    );

    emit FCMTraderUpdate(
      msg.sender,
      trader.marginInScaledYieldBearingTokens,
      trader.fixedTokenBalance,
      trader.variableTokenBalance
    );  
  }

  function getTraderMarginInUnderlyingTokens(uint256 traderMarginInScaledYieldBearingTokens) internal view returns (uint256 marginInYieldBearingTokens) {
      uint256 currentExchangeRate = _ctoken.exchangeRateStored();
      return traderMarginInScaledYieldBearingTokens.wadMul(currentExchangeRate);
  }

  function getTraderMarginInCTokens(address traderAddress)
        external
        view
        returns (uint256 marginInYieldBearingTokens)
    {
        TraderWithYieldBearingAssets.Info storage trader = traders[
            traderAddress
        ];
        marginInYieldBearingTokens = trader.marginInScaledYieldBearingTokens;
    }


  /// @notice Unwind Fully Collateralised Fixed Taker Swap
  /// @param notionalToUnwind The amount of notional to unwind (stop securing with a fixed rate)
  /// @param sqrtPriceLimitX96 The sqrt price limit (binary fixed point notation) beyond which the unwind cannot progress
  function unwindFullyCollateralisedFixedTakerSwap(uint256 notionalToUnwind, uint160 sqrtPriceLimitX96) external override returns 
    (int256 fixedTokenDelta, int256 variableTokenDelta, uint256 cumulativeFeeIncurred, int256 fixedTokenDeltaUnbalanced) {

    TraderWithYieldBearingAssets.Info storage trader = traders[msg.sender];

    require(trader.variableTokenBalance <= 0, "Trader VT balance positive");

    /// @dev it is impossible to unwind more variable token exposure than the user already has
    /// @dev hence, the notionalToUnwind needs to be <= absolute value of the variable token balance of the trader
    require(uint256(-trader.variableTokenBalance) >= notionalToUnwind, "notional to unwind > notional");

    // initiate a swap
    /// @dev as convention, specify the tickLower to be equal to -tickSpacing and tickUpper to be equal to tickSpacing
    // since the unwind is in the Variable Taker direction, the amountSpecified needs to be exact output => needs to be negative = -int256(notionalToUnwind),
    IVAMM.SwapParams memory params = IVAMM.SwapParams({
        recipient: address(this),
        amountSpecified: -notionalToUnwind.toInt256(),
        sqrtPriceLimitX96: sqrtPriceLimitX96,
        tickLower: -tickSpacing,
        tickUpper: tickSpacing
    });

    (fixedTokenDelta, variableTokenDelta, cumulativeFeeIncurred, fixedTokenDeltaUnbalanced,) = _vamm.swap(params);

    require(variableTokenDelta >= 0, "VT delta negative");

    // update trader fixed and variable token balances
    (int256 _fixedTokenBalance, int256 _variableTokenBalance) = trader.updateBalancesViaDeltas(fixedTokenDelta, variableTokenDelta);

    uint256 currentExchangeRate = _ctoken.exchangeRateStored();
    uint256 yieldBearingTokenDelta = uint256(variableTokenDelta).wadDiv(
        currentExchangeRate
    );

    uint256 updatedTraderMargin = trader.marginInScaledYieldBearingTokens - yieldBearingTokenDelta;
    trader.updateMarginInScaledYieldBearingTokens(updatedTraderMargin);

    // check the margin requirement of the trader post unwind, if the current balances still support the unwind, they it can happen, otherwise the unwind will get reverted
    checkMarginRequirement(_fixedTokenBalance, _variableTokenBalance, trader.marginInScaledYieldBearingTokens);

    // transfer fees to the margin engine
    underlyingToken.safeTransferFrom(msg.sender, address(_marginEngine), cumulativeFeeIncurred);

    // transfer the yield bearing tokens to trader address and update margin in terms of yield bearing tokens
    // variable token delta should be positive
    IERC20Minimal(address(_ctoken)).safeTransfer(msg.sender, yieldBearingTokenDelta);

    emit FullyCollateralisedUnwind(
      msg.sender,
      notionalToUnwind,
      sqrtPriceLimitX96,
      cumulativeFeeIncurred,
      fixedTokenDelta, 
      variableTokenDelta,
      fixedTokenDeltaUnbalanced
    );

    emit FCMTraderUpdate(
      msg.sender,
      trader.marginInScaledYieldBearingTokens,
      trader.fixedTokenBalance,
      trader.variableTokenBalance
    );
  }


  /// @notice Check Margin Requirement post unwind of a fully collateralised fixed taker
  function checkMarginRequirement(int256 traderFixedTokenBalance, int256 traderVariableTokenBalance, uint256 traderMarginInScaledYieldBearingTokens) internal {

    // variable token balance should never be positive
    // margin in scaled tokens should cover the variable leg from now to maturity

    /// @dev we can be confident the variable token balance of a fully collateralised fixed taker is always going to be negative (or zero)
    /// @dev hence, we can assume that the variable cashflows from now to maturity is covered by a portion of the trader's collateral in yield bearing tokens
    /// @dev once future variable cashflows are covered, we need to check if the remaining settlement cashflow is covered by the remaining margin in yield bearing tokens

    // @audit: casting variableTokenDelta is expected to be positive here, but what if goes below 0 due to rounding imprecision?
    uint256 marginToCoverVariableLegFromNowToMaturity = uint256(-traderVariableTokenBalance);
    int256 marginToCoverRemainingSettlementCashflow = int256(getTraderMarginInUnderlyingTokens(traderMarginInScaledYieldBearingTokens)) - int256(marginToCoverVariableLegFromNowToMaturity);

    int256 remainingSettlementCashflow = calculateRemainingSettlementCashflow(traderFixedTokenBalance, traderVariableTokenBalance);

    if (remainingSettlementCashflow < 0) {

      if (-remainingSettlementCashflow > marginToCoverRemainingSettlementCashflow) {
        revert CustomErrors.MarginRequirementNotMetFCM(int256(marginToCoverVariableLegFromNowToMaturity) + remainingSettlementCashflow);
      }

    }

  }


  /// @notice Calculate remaining settlement cashflow
  function calculateRemainingSettlementCashflow(int256 traderFixedTokenBalance, int256 traderVariableTokenBalance) internal returns (int256 remainingSettlementCashflow) {

    int256 fixedTokenBalanceWad = PRBMathSD59x18.fromInt(traderFixedTokenBalance);

    int256 variableTokenBalanceWad = PRBMathSD59x18.fromInt(
        traderVariableTokenBalance
    );

    /// @dev fixed cashflow based on the full term of the margin engine
    int256 fixedCashflowWad = PRBMathSD59x18.mul(
      fixedTokenBalanceWad,
      int256(
        FixedAndVariableMath.fixedFactor(true, _marginEngine.termStartTimestampWad(), _marginEngine.termEndTimestampWad())
      )
    );

    int256 variableFactorFromTermStartTimestampToNow = int256(_rateOracle.variableFactor(
      _marginEngine.termStartTimestampWad(),
      _marginEngine.termEndTimestampWad()
    ));

    /// @dev variable cashflow form term start timestamp to now
    int256 variableCashflowWad = PRBMathSD59x18.mul(
      variableTokenBalanceWad,
      variableFactorFromTermStartTimestampToNow
    );

    /// @dev the total cashflows as a sum of fixed and variable cashflows
    int256 cashflowWad = fixedCashflowWad + variableCashflowWad;

    /// @dev convert back to non-fixed point representation
    remainingSettlementCashflow = PRBMathSD59x18.toInt(cashflowWad);

  }

  modifier onlyAfterMaturity () {
    if (_marginEngine.termEndTimestampWad() > Time.blockTimestampScaled()) {
        revert CannotSettleBeforeMaturity();
    }
    _;
  }

  /// @notice Settle Trader
  /// @dev This function lets us settle a fully collateralised fixed taker position post term end timestamp of the MarginEngine
  /// @dev the settlement cashflow is calculated by invoking the calculateSettlementCashflow function of FixedAndVariableMath.sol (based on the fixed and variable token balance)
  /// @dev if the settlement cashflow of the trader is positive, then the settleTrader() function invokes the transferMarginToFCMTrader function of the MarginEngine which transfers the settlement cashflow the trader in terms of the underlying tokens
  /// @dev if settlement cashflow of the trader is negative, we need to update trader's margin in terms of scaled yield bearing tokens to account the settlement casflow
  /// @dev once settlement cashflows are accounted for, we safeTransfer the scaled yield bearing tokens in the margin account of the trader back to their wallet address
  function settleTrader() external override onlyAfterMaturity returns (int256 traderSettlementCashflow) {

    TraderWithYieldBearingAssets.Info storage trader = traders[msg.sender];

    int256 settlementCashflow = FixedAndVariableMath.calculateSettlementCashflow(trader.fixedTokenBalance, trader.variableTokenBalance, _marginEngine.termStartTimestampWad(), _marginEngine.termEndTimestampWad(), _rateOracle.variableFactor(_marginEngine.termStartTimestampWad(), _marginEngine.termEndTimestampWad()));
    trader.updateBalancesViaDeltas(-trader.fixedTokenBalance, -trader.variableTokenBalance);

    if (settlementCashflow < 0) {
      uint256 currentExchangeRate = _ctoken.exchangeRateStored();
      uint256 updatedTraderMarginInScaledYieldBearingTokens = trader.marginInScaledYieldBearingTokens - uint256(-settlementCashflow).wadDiv(currentExchangeRate);
      trader.updateMarginInScaledYieldBearingTokens(updatedTraderMarginInScaledYieldBearingTokens);
    }

    uint256 amountToSettle = trader.marginInScaledYieldBearingTokens;
    trader.updateMarginInScaledYieldBearingTokens(0);
    trader.settleTrader();
    IERC20Minimal(address(_ctoken)).safeTransfer(msg.sender, amountToSettle);
    if (settlementCashflow > 0) {
      // transfers margin in terms of underlying tokens (e.g. USDC) from the margin engine to the msg.sender
      // as long as the margin engine is active and solvent it shoudl be able to cover the settlement cashflows of the fully collateralised traders
      _marginEngine.transferMarginToFCMTrader(msg.sender, uint256(settlementCashflow));
    }

    emit fcmPositionSettlement(
      msg.sender,
      settlementCashflow
    );

    emit FCMTraderUpdate(
      msg.sender,
      trader.marginInScaledYieldBearingTokens,
      trader.fixedTokenBalance,
      trader.variableTokenBalance
    );

    return settlementCashflow;
  }


  /// @notice Transfer Margin (in underlying tokens) from the FCM to a MarginEngine trader
  /// @dev in case of Compound this is done by redeeming the underlying token directly from the cToken: https://compound.finance/docs/ctokens#redeem-underlying
  function transferMarginToMarginEngineTrader(address account, uint256 marginDeltaInUnderlyingTokens) external onlyMarginEngine whenNotPaused override {
    if (underlyingToken.balanceOf(address(_ctoken)) >= marginDeltaInUnderlyingTokens) {
      require(_ctoken.redeemUnderlying(marginDeltaInUnderlyingTokens) == 0); // Require success
      underlyingToken.safeTransfer(account, marginDeltaInUnderlyingTokens);
    } else {
      IERC20Minimal(address(_ctoken)).safeTransfer(account, marginDeltaInUnderlyingTokens.wadDiv(_ctoken.exchangeRateCurrent()));
    }
  }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../compound/ICToken.sol";
import "../IERC20Minimal.sol";

interface ICompoundFCM {

    /// The CToken
    function cToken() external returns (ICToken);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;
import "../core_libraries/Position.sol";

contract PositionTest {
    Position.Info public position;
    using Position for Position.Info;

    function updateLiquidity(int128 liquidityDelta) public {
        position.updateLiquidity(liquidityDelta);
    }

    function updateMargin(int256 marginDelta) public {
        position.updateMarginViaDelta(marginDelta);
    }

    function updateBalances(
        int256 fixedTokenBalanceDelta,
        int256 variableTokenBalanceDelta
    ) public {
        position.updateBalancesViaDeltas(
            fixedTokenBalanceDelta,
            variableTokenBalanceDelta
        );
    }

    function calculateFixedAndVariableDelta(
        int256 fixedTokenGrowthInside,
        int256 variableTokenGrowthInside
    )
        public
        view
        returns (int256 _fixedTokenBalance, int256 _variableTokenBalance)
    {
        (_fixedTokenBalance, _variableTokenBalance) = position
            .calculateFixedAndVariableDelta(
                fixedTokenGrowthInside,
                variableTokenGrowthInside
            );
    }

    function updateFixedAndVariableTokenGrowthInside(
        int256 fixedTokenGrowthInside,
        int256 variableTokenGrowthInside
    ) public {
        position.updateFixedAndVariableTokenGrowthInside(
            fixedTokenGrowthInside,
            variableTokenGrowthInside
        );
    }

    function updateFeeGrowthInside(uint256 feeGrowthInside) public {
        position.updateFeeGrowthInside(feeGrowthInside);
    }

    function calculateFeeDelta(uint256 feeGrowthInside)
        public
        view
        returns (uint256 feeDelta)
    {
        return position.calculateFeeDelta(feeGrowthInside);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;

import "../core_libraries/SwapMath.sol";

contract SwapMathTest {
    function computeFeeAmount(
        uint256 notional,
        uint256 timeToMaturityInSeconds,
        uint256 feePercentage
    ) external pure returns (uint256) {
        return
            SwapMath.computeFeeAmount(
                notional,
                timeToMaturityInSeconds,
                feePercentage
            );
    }

    function computeSwapStep(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        int256 amountRemaining,
        uint256 feePercentage,
        uint256 timeToMaturityInSeconds
    )
        external
        pure
        returns (
            uint160 sqrtQ,
            uint256 amountIn,
            uint256 amountOut,
            uint256 feeAmount
        )
    {
        return
            SwapMath.computeSwapStep(
                SwapMath.SwapStepParams(
                    sqrtRatioCurrentX96,
                    sqrtRatioTargetX96,
                    liquidity,
                    amountRemaining,
                    feePercentage,
                    timeToMaturityInSeconds
                )
            );
    }

    function getGasCostOfComputeSwapStep(
        uint160 sqrtRatioCurrentX96,
        uint160 sqrtRatioTargetX96,
        uint128 liquidity,
        int256 amountRemaining,
        uint256 feePercentage,
        uint256 timeToMaturityInSeconds
    ) external view returns (uint256) {
        uint256 gasBefore = gasleft();
        SwapMath.computeSwapStep(
            SwapMath.SwapStepParams(
                sqrtRatioCurrentX96,
                sqrtRatioTargetX96,
                liquidity,
                amountRemaining,
                feePercentage,
                timeToMaturityInSeconds
            )
        );
        return gasBefore - gasleft();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;
import "../utils/SqrtPriceMath.sol";

contract SqrtPriceMathTest {
    function getAmount0Delta(
        uint160 sqrtLower,
        uint160 sqrtUpper,
        uint128 liquidity,
        bool roundUp
    ) external pure returns (uint256 amount0) {
        return
            SqrtPriceMath.getAmount0Delta(
                sqrtLower,
                sqrtUpper,
                liquidity,
                roundUp
            );
    }

    function getAmount1Delta(
        uint160 sqrtLower,
        uint160 sqrtUpper,
        uint128 liquidity,
        bool roundUp
    ) external pure returns (uint256 amount1) {
        return
            SqrtPriceMath.getAmount1Delta(
                sqrtLower,
                sqrtUpper,
                liquidity,
                roundUp
            );
    }

    function getNextSqrtPriceFromInput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountIn,
        bool zeroForOne
    ) external pure returns (uint160 sqrtQX96) {
        return
            SqrtPriceMath.getNextSqrtPriceFromInput(
                sqrtPX96,
                liquidity,
                amountIn,
                zeroForOne
            );
    }

    function getNextSqrtPriceFromOutput(
        uint160 sqrtPX96,
        uint128 liquidity,
        uint256 amountOut,
        bool zeroForOne
    ) external pure returns (uint160 sqrtQX96) {
        return
            SqrtPriceMath.getNextSqrtPriceFromOutput(
                sqrtPX96,
                liquidity,
                amountOut,
                zeroForOne
            );
    }

    function getAmount0DeltaRoundUpIncluded(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) external pure returns (int256 amount0) {
        return
            SqrtPriceMath.getAmount0Delta(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
    }

    function getAmount1DeltaRoundUpIncluded(
        uint160 sqrtRatioAX96,
        uint160 sqrtRatioBX96,
        int128 liquidity
    ) external pure returns (int256 amount0) {
        return
            SqrtPriceMath.getAmount1Delta(
                sqrtRatioAX96,
                sqrtRatioBX96,
                liquidity
            );
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;

import "../core_libraries/Time.sol";

contract TimeTest {
    function blockTimestampScaled() public view returns (uint256) {
        return Time.blockTimestampScaled();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.9;

import "../interfaces/IMarginEngine.sol";

contract TestLiquidatorBot {
    IMarginEngine public marginEngine;

    constructor() {}

    function setMarginEngine(IMarginEngine _marginEngine) external {
        // in order to restrict this function to only be callable by the owner of the bot you can apply the onlyOwner modifier by OZ
        require(address(_marginEngine) != address(0), "me must exist");
        require(
            (address(marginEngine) != address(_marginEngine)),
            "me already set"
        );
        marginEngine = _marginEngine;
    }

    function getMELiquidatorRewardWad() external view returns (uint256) {
        require(address(marginEngine) != address(0), "me must be set");
        return marginEngine.liquidatorRewardWad();
    }

    function getLiquidationMarginRequirement(
        address _recipient,
        int24 _tickLower,
        int24 _tickUpper
    ) external returns (uint256) {
        require(address(marginEngine) != address(0), "me must be set");

        return
            marginEngine.getPositionMarginRequirement(
                _recipient,
                _tickLower,
                _tickUpper,
                true // isLM, i.e. is liquidation margin
            );
    }

    function liquidatePosition(
        address _owner,
        int24 _tickLower,
        int24 _tickUpper
    ) external returns (uint256) {
        require(address(marginEngine) != address(0), "me must be set");

        return marginEngine.liquidatePosition(_owner, _tickLower, _tickUpper);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;

import "../utils/LiquidityMath.sol";

contract LiquidityMathTest {
    function addDelta(uint128 x, int128 y) external pure returns (uint128 z) {
        return LiquidityMath.addDelta(x, y);
    }

    function getGasCostOfAddDelta(uint128 x, int128 y)
        external
        view
        returns (uint256)
    {
        uint256 gasBefore = gasleft();
        LiquidityMath.addDelta(x, y);
        return gasBefore - gasleft();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;

import "../utils/TickMath.sol";

contract TickMathTest {
    function getSqrtRatioAtTick(int24 tick) external pure returns (uint160) {
        return TickMath.getSqrtRatioAtTick(tick);
    }

    function getGasCostOfGetSqrtRatioAtTick(int24 tick)
        external
        view
        returns (uint256)
    {
        uint256 gasBefore = gasleft();
        TickMath.getSqrtRatioAtTick(tick);
        return gasBefore - gasleft();
    }

    function getTickAtSqrtRatio(uint160 sqrtPriceX96)
        external
        pure
        returns (int24)
    {
        return TickMath.getTickAtSqrtRatio(sqrtPriceX96);
    }

    function getGasCostOfGetTickAtSqrtRatio(uint160 sqrtPriceX96)
        external
        view
        returns (uint256)
    {
        uint256 gasBefore = gasleft();
        TickMath.getTickAtSqrtRatio(sqrtPriceX96);
        return gasBefore - gasleft();
    }

    // solhint-disable-next-line func-name-mixedcase
    function MIN_SQRT_RATIO() external pure returns (uint160) {
        return TickMath.MIN_SQRT_RATIO;
    }

    // solhint-disable-next-line func-name-mixedcase
    function MAX_SQRT_RATIO() external pure returns (uint160) {
        return TickMath.MAX_SQRT_RATIO;
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable reason-string

pragma solidity =0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// mock class using ERC20
contract ERC20Mock is ERC20 {
    constructor(string memory name, string memory symbol)
        payable
        ERC20(name, symbol)
    {
        // be default 18 decimals: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/abdb20a6bdb1700d58ea9e01b7471dafdef52a68/contracts/token/ERC20/ERC20.sol#L48
        mint(msg.sender, 1e12);
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function transferInternal(
        address from,
        address to,
        uint256 value
    ) public {
        _transfer(from, to, value);
    }

    function approveInternal(
        address owner,
        address spender,
        uint256 value
    ) public {
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.9;

import "../core_libraries/TickBitmap.sol";

contract TickBitmapTest {
    using TickBitmap for mapping(int16 => uint256);

    mapping(int16 => uint256) public bitmap;

    function flipTick(int24 tick) external {
        bitmap.flipTick(tick, 1);
    }

    function getGasCostOfFlipTick(int24 tick) external returns (uint256) {
        uint256 gasBefore = gasleft();
        bitmap.flipTick(tick, 1);
        return gasBefore - gasleft();
    }

    function nextInitializedTickWithinOneWord(int24 tick, bool lte)
        external
        view
        returns (int24 next, bool initialized)
    {
        return bitmap.nextInitializedTickWithinOneWord(tick, 1, lte);
    }

    function getGasCostOfNextInitializedTickWithinOneWord(int24 tick, bool lte)
        external
        view
        returns (uint256)
    {
        uint256 gasBefore = gasleft();
        bitmap.nextInitializedTickWithinOneWord(tick, 1, lte);
        return gasBefore - gasleft();
    }

    // returns whether the given tick is initialized
    function isInitialized(int24 tick) external view returns (bool) {
        (int24 next, bool initialized) = bitmap
            .nextInitializedTickWithinOneWord(tick, 1, true);
        return next == tick ? initialized : false;
    }
}