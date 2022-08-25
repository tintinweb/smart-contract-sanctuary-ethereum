// SPDX-License-Identifier: BlueOak-1.0.0
pragma solidity 0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "contracts/libraries/Fixed.sol";

error StalePrice();
error PriceOutsideRange();

/// Used by asset plugins to price their collateral
library OracleLib {
    /// @dev Use for on-the-fly calculations that should revert
    /// @param timeout The number of seconds after which oracle values should be considered stale
    /// @return {UoA/tok}
    function price(AggregatorV3Interface chainlinkFeed, uint48 timeout)
        internal
        view
        returns (uint192)
    {
        (uint80 roundId, int256 p, , uint256 updateTime, uint80 answeredInRound) = chainlinkFeed
            .latestRoundData();

        if (updateTime == 0 || answeredInRound < roundId) {
            revert StalePrice();
        }
        // Downcast is safe: uint256(-) reverts on underflow; block.timestamp assumed < 2^48
        uint48 secondsSince = uint48(block.timestamp - updateTime);
        if (secondsSince > timeout) revert StalePrice();

        // {UoA/tok}
        uint192 scaledPrice = shiftl_toFix(uint256(p), -int8(chainlinkFeed.decimals()));

        if (scaledPrice == 0) revert PriceOutsideRange();
        return scaledPrice;
    }

    /// @dev Use when a try-catch is necessary
    /// @param timeout The number of seconds after which oracle values should be considered stale
    /// @return {UoA/tok}
    function price_(AggregatorV3Interface chainlinkFeed, uint48 timeout)
        external
        view
        returns (uint192)
    {
        return price(chainlinkFeed, timeout);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

// SPDX-License-Identifier: BlueOak-1.0.0
// solhint-disable func-name-mixedcase func-visibility
pragma solidity ^0.8.9;

/// @title FixedPoint, a fixed-point arithmetic library defining the custom type uint192
/// @author Matt Elder <[email protected]> and the Reserve Team <https://reserve.org>

/** The logical type `uint192 ` is a 192 bit value, representing an 18-decimal Fixed-point
    fractional value.  This is what's described in the Solidity documentation as
    "fixed192x18" -- a value represented by 192 bits, that makes 18 digits available to
    the right of the decimal point.

    The range of values that uint192 can represent is about [-1.7e20, 1.7e20].
    Unless a function explicitly says otherwise, it will fail on overflow.
    To be clear, the following should hold:
    toFix(0) == 0
    toFix(1) == 1e18
*/

// A uint value passed to this library was out of bounds for uint192 operations
error UIntOutOfBounds();

// Used by P1 implementation for easier casting
uint256 constant FIX_ONE_256 = 1e18;
uint8 constant FIX_DECIMALS = 18;

// If a particular uint192 is represented by the uint192 n, then the uint192 represents the
// value n/FIX_SCALE.
uint64 constant FIX_SCALE = 1e18;

// FIX_SCALE Squared:
uint128 constant FIX_SCALE_SQ = 1e36;

// The largest integer that can be converted to uint192 .
// This is a bit bigger than 3.1e39
uint192 constant FIX_MAX_INT = type(uint192).max / FIX_SCALE;

uint192 constant FIX_ZERO = 0; // The uint192 representation of zero.
uint192 constant FIX_ONE = FIX_SCALE; // The uint192 representation of one.
uint192 constant FIX_MAX = type(uint192).max; // The largest uint192. (Not an integer!)
uint192 constant FIX_MIN = 0; // The smallest uint192.

/// An enum that describes a rounding approach for converting to ints
enum RoundingMode {
    FLOOR, // Round towards zero
    ROUND, // Round to the nearest int
    CEIL // Round away from zero
}

RoundingMode constant FLOOR = RoundingMode.FLOOR;
RoundingMode constant ROUND = RoundingMode.ROUND;
RoundingMode constant CEIL = RoundingMode.CEIL;

/* @dev Solidity 0.8.x only allows you to change one of type or size per type conversion.
   Thus, all the tedious-looking double conversions like uint256(uint256 (foo))
   See: https://docs.soliditylang.org/en/v0.8.9/080-breaking-changes.html#new-restrictions
 */

/// Explicitly convert a uint256 to a uint192. Revert if the input is out of bounds.
function _safeWrap(uint256 x) pure returns (uint192) {
    if (FIX_MAX < x) revert UIntOutOfBounds();
    return uint192(x);
}

/// Convert a uint to its uint192 representation. Fails if x is outside uint192's representable range.
function toFix(uint256 x) pure returns (uint192) {
    return _safeWrap(x * FIX_SCALE);
}

/// Convert a uint to its fixed-point representation after left-shifting its value `shiftLeft`
/// decimal digits. Fails if the result is outside uint192's representable range.
function shiftl_toFix(uint256 x, int8 shiftLeft) pure returns (uint192) {
    return shiftl_toFix(x, shiftLeft, FLOOR);
}

function shiftl_toFix(
    uint256 x,
    int8 shiftLeft,
    RoundingMode rounding
) pure returns (uint192) {
    shiftLeft += 18;

    if (x == 0 || shiftLeft < -77) return 0; // shift would clear a uint256; 0 -> 0
    if (77 < shiftLeft) revert UIntOutOfBounds(); // would unconditionally overflow x

    uint256 coeff = 10**abs(shiftLeft);
    uint256 shifted = (shiftLeft >= 0) ? x * coeff : _divrnd(x, coeff, rounding);

    return _safeWrap(shifted);
}

/// Divide a uint by a uint192 . Fails if the result is outside uint192's representable range
/// (May also fail if the result is MIN_uint192 ; not fixing this for optimization's sake.)
function divFix(uint256 x, uint192 y) pure returns (uint192) {
    // If we didn't have to worry about overflow, we'd just do `return x * 1e36 / _y`
    // If it's safe to do this operation the easy way, do it:
    if (x < uint256(type(uint256).max / FIX_SCALE_SQ)) {
        return _safeWrap(uint256(x * FIX_SCALE_SQ) / y);
    } else {
        return _safeWrap(mulDiv256(x, FIX_SCALE_SQ, y));
    }
}

/// Divide a uint by a uint, yielding a fix
function divuu(uint256 x, uint256 y) pure returns (uint192) {
    return _safeWrap(mulDiv256(FIX_SCALE, x, y));
}

function fixMin(uint192 x, uint192 y) pure returns (uint192) {
    return x < y ? x : y;
}

function fixMax(uint192 x, uint192 y) pure returns (uint192) {
    return x > y ? x : y;
}

function abs(int256 x) pure returns (uint256) {
    return x < 0 ? uint256(-x) : uint256(x);
}

/// internal: Do an internal division with given rounding. Where numerator and divisor are uint200s
/// (not presumed to be fixed-point values!), return numerator/divisor.
/// Round the division's result as specified by `rounding`.
function _divrnd(
    uint256 numerator,
    uint256 divisor,
    RoundingMode rounding
) pure returns (uint256) {
    uint256 result = numerator / divisor;

    if (rounding == FLOOR) return result;

    if (rounding == ROUND) {
        if (numerator % divisor > (divisor - 1) / 2) {
            result++;
        }
    } else {
        if (numerator % divisor > 0) {
            result++;
        }
    }

    return result;
}

library FixLib {
    /// All arithmetic functions fail if and only if the result is out of bounds.

    /// Convert this fixed-point value to a uint; round the result towards zero
    function toUint(uint192 x) internal pure returns (uint136) {
        return toUint(x, FLOOR);
    }

    /// Convert this uint192 to a uint, applying the rounding approach described by the enum
    function toUint(uint192 x, RoundingMode rounding) internal pure returns (uint136) {
        return uint136(_divrnd(uint256(x), FIX_SCALE, rounding));
    }

    /// Return the uint192 shifted to the left by `decimal` digits
    /// Similar to a bitshift but in base 10
    /// Equivalent to multiplying `x` by `10**decimal`
    function shiftl(uint192 x, int8 decimals) internal pure returns (uint192) {
        return shiftl(x, decimals, FLOOR);
    }

    /// Return the uint192 shifted to the left by `decimal` digits
    /// (Similar to a bitshift but in base 10)
    /// Equivalent to multiplying `x` by `10**decimal`
    function shiftl(
        uint192 x,
        int8 decimals,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        uint256 coeff = uint256(10**abs(decimals));
        return _safeWrap(decimals >= 0 ? x * coeff : _divrnd(x, coeff, rounding));
    }

    /// Add a uint192 to this uint192 .
    function plus(uint192 x, uint192 y) internal pure returns (uint192) {
        return x + y;
    }

    /// Add a uint to this uint192 .
    function plusu(uint192 x, uint256 y) internal pure returns (uint192) {
        return _safeWrap(x + y * FIX_SCALE);
    }

    /// Subtract a uint192 from this uint192 .
    function minus(uint192 x, uint192 y) internal pure returns (uint192) {
        return x - y;
    }

    /// Subtract a uint from this uint192 .
    function minusu(uint192 x, uint256 y) internal pure returns (uint192) {
        return _safeWrap(uint256(x) - uint256(y * FIX_SCALE));
    }

    /// Multiply this uint192 by a uint192 .
    /// Round truncated values to the nearest available value. 5e-19 rounds away from zero.
    function mul(uint192 x, uint192 y) internal pure returns (uint192) {
        return mul(x, y, ROUND);
    }

    function mul(
        uint192 x,
        uint192 y,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        return _safeWrap(_divrnd(uint256(x) * uint256(y), FIX_SCALE, rounding));
    }

    /// Multiply this uint192 by a uint.
    function mulu(uint192 x, uint256 y) internal pure returns (uint192) {
        return _safeWrap(x * y);
    }

    /// Divide this uint192 by a uint192 ; round the fractional part towards zero.
    function div(uint192 x, uint192 y) internal pure returns (uint192) {
        return div(x, y, FLOOR);
    }

    function div(
        uint192 x,
        uint192 y,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        // Multiply-in FIX_SCALE before dividing by y to preserve precision.
        return _safeWrap(_divrnd(uint256(x) * FIX_SCALE, y, rounding));
    }

    /// Divide this uint192 by a uint.
    function divu(uint192 x, uint256 y) internal pure returns (uint192) {
        return divu(x, y, FLOOR);
    }

    function divu(
        uint192 x,
        uint256 y,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        return _safeWrap(_divrnd(x, y, rounding));
    }

    uint64 constant FIX_HALF = uint64(FIX_SCALE) / 2;

    /// Raise this uint192 to a nonnegative integer power.
    /// Presumes that powu(0.0, 0) = 1
    /// @dev The gas cost is O(lg(y))
    /// Intermediate muls do nearest-value rounding.
    function powu(uint192 x_, uint48 y) internal pure returns (uint192) {
        // The algorithm is exponentiation by squaring. See: https://w.wiki/4LjE
        if (y == 1) return x_;
        if (x_ == FIX_ONE || y == 0) return FIX_ONE;
        uint256 x = uint256(x_);
        uint256 result = FIX_SCALE;
        while (true) {
            if (y & 1 == 1) result = (result * x + FIX_HALF) / FIX_SCALE;
            if (y <= 1) break;
            y = y >> 1;
            x = (x * x + FIX_HALF) / FIX_SCALE;
        }
        return _safeWrap(result);
    }

    /// Comparison operators...
    function lt(uint192 x, uint192 y) internal pure returns (bool) {
        return x < y;
    }

    function lte(uint192 x, uint192 y) internal pure returns (bool) {
        return x <= y;
    }

    function gt(uint192 x, uint192 y) internal pure returns (bool) {
        return x > y;
    }

    function gte(uint192 x, uint192 y) internal pure returns (bool) {
        return x >= y;
    }

    function eq(uint192 x, uint192 y) internal pure returns (bool) {
        return x == y;
    }

    function neq(uint192 x, uint192 y) internal pure returns (bool) {
        return x != y;
    }

    /// Return whether or not this uint192 is less than epsilon away from y.
    function near(
        uint192 x,
        uint192 y,
        uint192 epsilon
    ) internal pure returns (bool) {
        uint192 diff = x <= y ? y - x : x - y;
        return diff < epsilon;
    }

    // ================ Chained Operations ================
    // The operation foo_bar() always means:
    //   Do foo() followed by bar(), and overflow only if the _end_ result doesn't fit in an uint192

    function shiftl_toUint(uint192 x, int8 decimals) internal pure returns (uint256) {
        return shiftl_toUint(x, decimals, FLOOR);
    }

    /// Shift this uint192 , left by `decimals`, and then convert the result to a uint.
    /// Do all this applying the given rounding mode.
    /// Overflow only if the end result doesn't fit in an uint192 .
    function shiftl_toUint(
        uint192 x,
        int8 decimals,
        RoundingMode rounding
    ) internal pure returns (uint256) {
        decimals -= 18; // shift so that toUint happens at the same time.
        uint256 coeff = uint256(10**abs(decimals));
        return decimals >= 0 ? uint256(x * coeff) : uint256(_divrnd(x, coeff, rounding));
    }

    /// Multiply this uint192 by a uint and output the result as a uint, rounding towards zero.
    function mulu_toUint(uint192 x, uint256 y) internal pure returns (uint256) {
        return mulDiv256(uint256(x), y, FIX_SCALE);
    }

    /// Multiply this uint192 by a uint and output the result as a uint, rounding as specified.
    function mulu_toUint(
        uint192 x,
        uint256 y,
        RoundingMode rounding
    ) internal pure returns (uint256) {
        return mulDiv256(uint256(x), y, FIX_SCALE, rounding);
    }

    /// Multiply this uint192 by a uint192 and output the result as a uint, rounding towards zero.
    function mul_toUint(uint192 x, uint192 y) internal pure returns (uint256) {
        return mulDiv256(uint256(x), uint256(y), FIX_SCALE_SQ);
    }

    /// Multiply this uint192 by a uint192 and output the result as a uint, rounding towards zero.
    function mul_toUint(
        uint192 x,
        uint192 y,
        RoundingMode rounding
    ) internal pure returns (uint256) {
        return mulDiv256(uint256(x), uint256(y), FIX_SCALE_SQ, rounding);
    }

    /// A chained .mul + .div on uints that avoids intermediate overflow
    /// @dev Do not use if you don't need it; has higher gas costs than x * y / z
    function muluDivu(
        uint192 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint192) {
        return muluDivu(x, y, z, FLOOR);
    }

    /// A chained .mul + .div on uints that avoids intermediate overflow
    /// @dev Do not use if you don't need it; has higher gas costs than x * y / z
    function muluDivu(
        uint192 x,
        uint256 y,
        uint256 z,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        return _safeWrap(mulDiv256(x, y, z, rounding));
    }

    /// A chained .mul + .div on Fixes that avoids intermediate overflow
    /// @dev Do not use if you don't need it; has higher gas costs than x * y / z
    function mulDiv(
        uint192 x,
        uint192 y,
        uint192 z
    ) internal pure returns (uint192) {
        return mulDiv(x, y, z, FLOOR);
    }

    /// A chained .mul + .div on Fixes that avoids intermediate overflow
    /// @dev Do not use if you don't need it; has higher gas costs than x * y / z
    function mulDiv(
        uint192 x,
        uint192 y,
        uint192 z,
        RoundingMode rounding
    ) internal pure returns (uint192) {
        return _safeWrap(mulDiv256(x, y, z, rounding));
    }
}

// ================ a couple pure-uint helpers================

/// mulDiv: return (x*y/z), overflowing *only* if the end result is out of range.
///   Adapted from sources:
///   https://medium.com/coinmonks/4db014e080b1, https://medium.com/wicketh/afa55870a65
///   and quite a few of the other excellent "Mathemagic" posts from https://medium.com/wicketh
/// @dev Just use x*y/z unless you need to avoid intermediate overflow. This has higher gas costs
function mulDiv256(
    uint256 x,
    uint256 y,
    uint256 z
) pure returns (uint256 result) {
    unchecked {
        (uint256 lo, uint256 hi) = fullMul(x, y);
        if (hi >= z) revert UIntOutOfBounds();
        uint256 mm = mulmod(x, y, z);
        if (mm > lo) hi -= 1;
        lo -= mm;
        uint256 pow2 = z & (0 - z);
        z /= pow2;
        lo /= pow2;
        lo += hi * ((0 - pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        result = lo * r;
    }
}

/// return (x*y/z), overflowing only if the end result is out of range, and having the division
/// round as specified by `rounding`.
function mulDiv256(
    uint256 x,
    uint256 y,
    uint256 z,
    RoundingMode rounding
) pure returns (uint256) {
    uint256 result = mulDiv256(x, y, z);
    if (rounding == FLOOR) return result;

    uint256 mm = mulmod(x, y, z);
    if (rounding == CEIL) {
        if (mm > 0) result += 1;
    } else {
        if (mm > ((z - 1) / 2)) result += 1; // z should be z-1
    }
    return result;
}

/// fullMul: return (x*y) as a "virtual uint512"
/// The computed result is (hi*2^256 + lo)
///   Adapted from sources:
///   https://medium.com/wicketh/27650fec525d, https://medium.com/coinmonks/4db014e080b1
/// @dev Intended to be internal to this library
function fullMul(uint256 x, uint256 y) pure returns (uint256 lo, uint256 hi) {
    unchecked {
        uint256 mm = mulmod(x, y, uint256(0) - uint256(1));
        lo = x * y;
        hi = mm - lo;
        if (mm < lo) hi -= 1;
    }
}