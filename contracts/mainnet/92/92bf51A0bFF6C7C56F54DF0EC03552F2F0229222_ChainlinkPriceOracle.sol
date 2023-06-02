// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

interface IWstETH is IERC20 {
    // --- Functions ---

    function stETH() external returns (IERC20);

    /// @notice Exchanges stETH to wstETH
    /// @param stETHAmount amount of stETH to wrap in exchange for wstETH
    /// @dev Requirements:
    ///  - `stETHAmount` must be non-zero
    ///  - msg.sender must approve at least `stETHAmount` stETH to this
    ///    contract.
    ///  - msg.sender must have at least `stETHAmount` of stETH.
    /// User should first approve `stETHAmount` to the WstETH contract
    /// @return Amount of wstETH user receives after wrap
    function wrap(uint256 stETHAmount) external returns (uint256);

    /// @notice Exchanges wstETH to stETH.
    /// @param wstETHAmount Amount of wstETH to unwrap in exchange for stETH.
    /// @dev Requirements:
    ///  - `wstETHAmount` must be non-zero
    ///  - msg.sender must have at least `wstETHAmount` wstETH.
    /// @return Amount of stETH user receives after unwrap.
    function unwrap(uint256 wstETHAmount) external returns (uint256);

    /// @notice Get amount of wstETH for a given amount of stETH.
    /// @param stETHAmount Amount of stETH.
    /// @return Amount of wstETH for a given stETH amount.
    function getWstETHByStETH(uint256 stETHAmount) external view returns (uint256);

    /// @notice Get amount of stETH for a given amount of wstETH.
    /// @param wstETHAmount amount of wstETH.
    /// @return Amount of stETH for a given wstETH amount.
    function getStETHByWstETH(uint256 wstETHAmount) external view returns (uint256);

    /// @notice Get amount of stETH for a one wstETH.
    /// @return Amount of stETH for 1 wstETH.
    function stEthPerToken() external view returns (uint256);

    /// @notice Get amount of wstETH for a one stETH.
    /// @return Amount of wstETH for a 1 stETH.
    function tokensPerStEth() external view returns (uint256);
}

library Fixed256x18 {
    uint256 internal constant ONE = 1e18; // 18 decimal places

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / ONE;
    }

    function mulUp(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 product = a * b;

        if (product == 0) {
            return 0;
        } else {
            return ((product - 1) / ONE) + 1;
        }
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * ONE) / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        } else {
            return (((a * ONE) - 1) / b) + 1;
        }
    }

    function complement(uint256 x) internal pure returns (uint256) {
        return (x < ONE) ? (ONE - x) : 0;
    }
}

library MathUtils {
    // --- Constants ---

    /// @notice Represents 100%.
    /// @dev 1e18 is the scaling factor (100% == 1e18).
    uint256 public constant _100_PERCENT = Fixed256x18.ONE;

    /// @notice Precision for Nominal ICR (independent of price).
    /// @dev Rationale for the value:
    /// - Making it “too high” could lead to overflows.
    /// - Making it “too low” could lead to an ICR equal to zero, due to truncation from floor division.
    ///
    /// This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 collateralToken,
    /// and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
    uint256 internal constant _NICR_PRECISION = 1e20;

    /// @notice Number of minutes in 1000 years.
    uint256 internal constant _MINUTES_IN_1000_YEARS = 1000 * 365 days / 1 minutes;

    // --- Functions ---

    /// @notice Multiplies two decimal numbers and use normal rounding rules:
    /// - round product up if 19'th mantissa digit >= 5
    /// - round product down if 19'th mantissa digit < 5.
    /// @param x First number.
    /// @param y Second number.
    function _decMul(uint256 x, uint256 y) internal pure returns (uint256 decProd) {
        decProd = (x * y + Fixed256x18.ONE / 2) / Fixed256x18.ONE;
    }

    /// @notice Exponentiation function for 18-digit decimal base, and integer exponent n.
    ///
    /// @dev Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity. The exponent is capped to
    /// avoid reverting due to overflow.
    ///
    /// If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
    /// negligibly different from just passing the cap, since the decayed base rate will be 0 for 1000 years or > 1000
    /// years.
    /// @param base The decimal base.
    /// @param exponent The exponent.
    /// @return The result of the exponentiation.
    function _decPow(uint256 base, uint256 exponent) internal pure returns (uint256) {
        if (exponent == 0) {
            return Fixed256x18.ONE;
        }

        uint256 y = Fixed256x18.ONE;
        uint256 x = base;
        uint256 n = Math.min(exponent, _MINUTES_IN_1000_YEARS); // cap to avoid overflow

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 != 0) {
                y = _decMul(x, y);
            }
            x = _decMul(x, x);
            n /= 2;
        }

        return _decMul(x, y);
    }

    /// @notice Computes the Nominal Individual Collateral Ratio (NICR) for given collateral and debt. If debt is zero,
    /// it returns the maximal value for uint256 (represents "infinite" CR).
    /// @param collateral Collateral amount.
    /// @param debt Debt amount.
    /// @return NICR.
    function _computeNominalCR(uint256 collateral, uint256 debt) internal pure returns (uint256) {
        return debt > 0 ? collateral * _NICR_PRECISION / debt : type(uint256).max;
    }

    /// @notice Computes the Collateral Ratio for given collateral, debt and price. If debt is zero, it returns the
    /// maximal value for uint256 (represents "infinite" CR).
    /// @param collateral Collateral amount.
    /// @param debt Debt amount.
    /// @param price Collateral price.
    /// @return Collateral ratio.
    function _computeCR(uint256 collateral, uint256 debt, uint256 price) internal pure returns (uint256) {
        return debt > 0 ? collateral * price / debt : type(uint256).max;
    }
}

interface IPriceOracle {
    // --- Types ---

    struct PriceOracleResponse {
        bool isBrokenOrFrozen;
        bool priceChangeAboveMax;
        uint256 price;
    }

    // --- Errors ---

    /// @dev Invalid wstETH address.
    error InvalidWstETHAddress();

    // --- Functions ---

    /// @dev Return price oracle response which consists the following information: oracle is broken or frozen, the
    /// price change between two rounds is more than max, and the price.
    function getPriceOracleResponse() external returns (PriceOracleResponse memory);

    /// @dev Return wstETH address.
    function wstETH() external view returns (IWstETH);

    /// @dev Maximum time period allowed since oracle latest round data timestamp, beyond which oracle is considered
    /// frozen.
    function TIMEOUT() external view returns (uint256);

    /// @dev Used to convert a price answer to an 18-digit precision uint.
    function TARGET_DIGITS() external view returns (uint256);

    /// @dev price deviation for the oracle in percentage.
    function DEVIATION() external view returns (uint256);
}

interface IChainlinkPriceOracle is IPriceOracle {
    // --- Types ---

    struct ChainlinkResponse {
        uint80 roundId;
        int256 answer;
        uint256 timestamp;
        bool success;
        uint8 decimals;
        uint80 answeredInRound;
    }

    // --- Errors ---

    /// @dev Emitted when the price aggregator address is invalid.
    error InvalidPriceAggregatorAddress();

    // --- Functions ---

    /// @dev Mainnet Chainlink aggregator.
    function priceAggregator() external returns (AggregatorV3Interface);

    /// @dev Maximum deviation allowed between two consecutive Chainlink oracle prices. 18-digit precision.
    function MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND() external returns (uint256);
}

abstract contract BasePriceOracle is IPriceOracle {
    // --- Types ---

    using Fixed256x18 for uint256;

    // --- Variables ---

    IWstETH public immutable override wstETH;

    uint256 public constant override TIMEOUT = 2 hours;

    uint256 public constant override TARGET_DIGITS = 18;

    // --- Constructor ---

    constructor(IWstETH wstETH_) {
        if (address(wstETH_) == address(0)) {
            revert InvalidWstETHAddress();
        }
        wstETH = IWstETH(wstETH_);
    }

    // --- Functions ---

    function _oracleIsFrozen(uint256 responseTimestamp) internal view returns (bool) {
        return (block.timestamp - responseTimestamp) > TIMEOUT;
    }

    function _convertIntoWstETHPrice(uint256 price, uint256 answerDigits) internal view returns (uint256) {
        return _scalePriceByDigits(price, answerDigits).mulDown(wstETH.stEthPerToken());
    }

    function _scalePriceByDigits(uint256 price, uint256 answerDigits) internal pure returns (uint256) {
        /*
        * Convert the price returned by the oracle to an 18-digit decimal for use by Raft.
        */
        if (answerDigits > TARGET_DIGITS) {
            // Scale the returned price value down to Raft's target precision
            return price / (10 ** (answerDigits - TARGET_DIGITS));
        }
        if (answerDigits < TARGET_DIGITS) {
            // Scale the returned price value up to Raft's target precision
            return price * (10 ** (TARGET_DIGITS - answerDigits));
        }
        return price;
    }
}

contract ChainlinkPriceOracle is IChainlinkPriceOracle, BasePriceOracle {
    // --- Types ---

    using Fixed256x18 for uint256;

    // --- Constants & immutables ---

    AggregatorV3Interface public immutable override priceAggregator;

    uint256 public constant override MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND = 15e16; // 15%

    uint256 public constant override DEVIATION = 1e16; // 1%

    // --- Constructor ---

    constructor(AggregatorV3Interface _priceAggregatorAddress, IWstETH _wstETH) BasePriceOracle(_wstETH) {
        if (address(_priceAggregatorAddress) == address(0)) {
            revert InvalidPriceAggregatorAddress();
        }
        priceAggregator = _priceAggregatorAddress;
    }

    // --- Functions ---

    function getPriceOracleResponse() external view override returns (PriceOracleResponse memory) {
        ChainlinkResponse memory chainlinkResponse = _getCurrentChainlinkResponse();
        ChainlinkResponse memory prevChainlinkResponse =
            _getPrevChainlinkResponse(chainlinkResponse.roundId, chainlinkResponse.decimals);

        if (
            _chainlinkIsBroken(chainlinkResponse, prevChainlinkResponse)
                || _oracleIsFrozen(chainlinkResponse.timestamp)
        ) {
            return (PriceOracleResponse(true, false, 0));
        }
        return (
            PriceOracleResponse(
                false,
                _chainlinkPriceChangeAboveMax(chainlinkResponse, prevChainlinkResponse),
                _convertIntoWstETHPrice(uint256(chainlinkResponse.answer), chainlinkResponse.decimals)
            )
        );
    }

    function _getCurrentChainlinkResponse() internal view returns (ChainlinkResponse memory chainlinkResponse) {
        // First, try to get current decimal precision:
        try priceAggregator.decimals() returns (uint8 decimals) {
            // If call to Chainlink succeeds, record the current decimal precision
            chainlinkResponse.decimals = decimals;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return chainlinkResponse;
        }

        // Secondly, try to get latest price data:
        try priceAggregator.latestRoundData() returns (
            uint80 roundId, int256 answer, uint256, /* startedAt */ uint256 timestamp, uint80 answeredInRound
        ) {
            // If call to Chainlink succeeds, return the response and success = true
            chainlinkResponse.roundId = roundId;
            chainlinkResponse.answer = answer;
            chainlinkResponse.timestamp = timestamp;
            chainlinkResponse.answeredInRound = answeredInRound;
            chainlinkResponse.success = true;
            return chainlinkResponse;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return chainlinkResponse;
        }
    }

    function _getPrevChainlinkResponse(
        uint80 currentRoundID,
        uint8 currentDecimals
    )
        internal
        view
        returns (ChainlinkResponse memory prevChainlinkResponse)
    {
        /*
        * NOTE: Chainlink only offers a current decimals() value - there is no way to obtain the decimal precision used
        * in a previous round.  We assume the decimals used in the previous round are the same as the current round.
        */

        if (currentRoundID == 0) {
            return prevChainlinkResponse;
        }

        // Try to get the price data from the previous round:
        try priceAggregator.getRoundData(currentRoundID - 1) returns (
            uint80 roundId, int256 answer, uint256, /* startedAt */ uint256 timestamp, uint80 answeredInRound
        ) {
            // If call to Chainlink succeeds, return the response and success = true
            prevChainlinkResponse.roundId = roundId;
            prevChainlinkResponse.answer = answer;
            prevChainlinkResponse.timestamp = timestamp;
            prevChainlinkResponse.decimals = currentDecimals;
            prevChainlinkResponse.answeredInRound = answeredInRound;
            prevChainlinkResponse.success = true;
            return prevChainlinkResponse;
        } catch {
            // If call to Chainlink aggregator reverts, return a zero response with success = false
            return prevChainlinkResponse;
        }
    }

    /* Chainlink is considered broken if its current or previous round data is in any way bad. We check the previous
    * round for two reasons:
    *
    * 1) It is necessary data for the price deviation check in case 1.
    * 2) Chainlink is the PriceFeed's preferred primary oracle - having two consecutive valid round responses adds
    * peace of mind when using or returning to Chainlink.
    */
    function _chainlinkIsBroken(
        ChainlinkResponse memory currentResponse,
        ChainlinkResponse memory prevResponse
    )
        internal
        view
        returns (bool)
    {
        return _badChainlinkResponse(currentResponse) || _badChainlinkResponse(prevResponse)
            || currentResponse.timestamp <= prevResponse.timestamp;
    }

    function _badChainlinkResponse(ChainlinkResponse memory response) internal view returns (bool) {
        return !response.success || response.roundId == 0 || response.timestamp == 0 || response.answer <= 0
            || response.answeredInRound != response.roundId || response.timestamp > block.timestamp;
    }

    function _chainlinkPriceChangeAboveMax(
        ChainlinkResponse memory currentResponse,
        ChainlinkResponse memory prevResponse
    )
        internal
        view
        returns (bool)
    {
        // Not needed to be converted to WstETH price, as we are only checking for a percentage change.
        // Also, not needed to be converted by decimals, because aggregator decimals are the same for both responses.
        uint256 currentScaledPrice = uint256(currentResponse.answer);
        uint256 prevScaledPrice = uint256(prevResponse.answer);

        uint256 minPrice = Math.min(currentScaledPrice, prevScaledPrice);
        uint256 maxPrice = Math.max(currentScaledPrice, prevScaledPrice);

        // Use the previous round price as the denominator
        uint256 percentDeviation = (maxPrice - minPrice).divDown(prevScaledPrice);

        // Return true if price has more than doubled, or more than halved.
        return percentDeviation > MAX_PRICE_DEVIATION_FROM_PREVIOUS_ROUND;
    }
}