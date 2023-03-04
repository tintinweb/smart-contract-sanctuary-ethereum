// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/// Common mathematical functions used in both SD59x18 and UD60x18. Note that these global functions do not
/// always operate with SD59x18 and UD60x18 numbers.

/*//////////////////////////////////////////////////////////////////////////
                                CUSTOM ERRORS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Emitted when the ending result in the fixed-point version of `mulDiv` would overflow uint256.
error PRBMath_MulDiv18_Overflow(uint256 x, uint256 y);

/// @notice Emitted when the ending result in `mulDiv` would overflow uint256.
error PRBMath_MulDiv_Overflow(uint256 x, uint256 y, uint256 denominator);

/// @notice Emitted when attempting to run `mulDiv` with one of the inputs `type(int256).min`.
error PRBMath_MulDivSigned_InputTooSmall();

/// @notice Emitted when the ending result in the signed version of `mulDiv` would overflow int256.
error PRBMath_MulDivSigned_Overflow(int256 x, int256 y);

/*//////////////////////////////////////////////////////////////////////////
                                    CONSTANTS
//////////////////////////////////////////////////////////////////////////*/

/// @dev The maximum value an uint128 number can have.
uint128 constant MAX_UINT128 = type(uint128).max;

/// @dev The maximum value an uint40 number can have.
uint40 constant MAX_UINT40 = type(uint40).max;

/// @dev How many trailing decimals can be represented.
uint256 constant UNIT = 1e18;

/// @dev Largest power of two that is a divisor of `UNIT`.
uint256 constant UNIT_LPOTD = 262144;

/// @dev The `UNIT` number inverted mod 2^256.
uint256 constant UNIT_INVERSE = 78156646155174841979727994598816262306175212592076161876661_508869554232690281;

/*//////////////////////////////////////////////////////////////////////////
                                    FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Finds the zero-based index of the first one in the binary representation of x.
/// @dev See the note on msb in the "Find First Set" Wikipedia article https://en.wikipedia.org/wiki/Find_first_set
///
/// Each of the steps in this implementation is equivalent to this high-level code:
///
/// ```solidity
/// if (x >= 2 ** 128) {
///     x >>= 128;
///     result += 128;
/// }
/// ```
///
/// Where 128 is swapped with each respective power of two factor. See the full high-level implementation here:
/// https://gist.github.com/PaulRBerg/f932f8693f2733e30c4d479e8e980948
///
/// A list of the Yul instructions used below:
/// - "gt" is "greater than"
/// - "or" is the OR bitwise operator
/// - "shl" is "shift left"
/// - "shr" is "shift right"
///
/// @param x The uint256 number for which to find the index of the most significant bit.
/// @return result The index of the most significant bit as an uint256.
function msb(uint256 x) pure returns (uint256 result) {
    // 2^128
    assembly ("memory-safe") {
        let factor := shl(7, gt(x, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^64
    assembly ("memory-safe") {
        let factor := shl(6, gt(x, 0xFFFFFFFFFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^32
    assembly ("memory-safe") {
        let factor := shl(5, gt(x, 0xFFFFFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^16
    assembly ("memory-safe") {
        let factor := shl(4, gt(x, 0xFFFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^8
    assembly ("memory-safe") {
        let factor := shl(3, gt(x, 0xFF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^4
    assembly ("memory-safe") {
        let factor := shl(2, gt(x, 0xF))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^2
    assembly ("memory-safe") {
        let factor := shl(1, gt(x, 0x3))
        x := shr(factor, x)
        result := or(result, factor)
    }
    // 2^1
    // No need to shift x any more.
    assembly ("memory-safe") {
        let factor := gt(x, 0x1)
        result := or(result, factor)
    }
}

/// @notice Calculates floor(x*y÷denominator) with full precision.
///
/// @dev Credits to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
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
function mulDiv(uint256 x, uint256 y, uint256 denominator) pure returns (uint256 result) {
    // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
    // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
    // variables such that product = prod1 * 2^256 + prod0.
    uint256 prod0; // Least significant 256 bits of the product
    uint256 prod1; // Most significant 256 bits of the product
    assembly ("memory-safe") {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    // Handle non-overflow cases, 256 by 256 division.
    if (prod1 == 0) {
        unchecked {
            return prod0 / denominator;
        }
    }

    // Make sure the result is less than 2^256. Also prevents denominator == 0.
    if (prod1 >= denominator) {
        revert PRBMath_MulDiv_Overflow(x, y, denominator);
    }

    ///////////////////////////////////////////////
    // 512 by 256 division.
    ///////////////////////////////////////////////

    // Make division exact by subtracting the remainder from [prod1 prod0].
    uint256 remainder;
    assembly ("memory-safe") {
        // Compute remainder using the mulmod Yul instruction.
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
        assembly ("memory-safe") {
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
    }
}

/// @notice Calculates floor(x*y÷1e18) with full precision.
///
/// @dev Variant of `mulDiv` with constant folding, i.e. in which the denominator is always 1e18. Before returning the
/// final result, we add 1 if `(x * y) % UNIT >= HALF_UNIT`. Without this adjustment, 6.6e-19 would be truncated to 0
/// instead of being rounded to 1e-18. See "Listing 6" and text above it at https://accu.org/index.php/journals/1717.
///
/// Requirements:
/// - The result must fit within uint256.
///
/// Caveats:
/// - The body is purposely left uncommented; to understand how this works, see the NatSpec comments in `mulDiv`.
/// - It is assumed that the result can never be `type(uint256).max` when x and y solve the following two equations:
///     1. x * y = type(uint256).max * UNIT
///     2. (x * y) % UNIT >= UNIT / 2
///
/// @param x The multiplicand as an unsigned 60.18-decimal fixed-point number.
/// @param y The multiplier as an unsigned 60.18-decimal fixed-point number.
/// @return result The result as an unsigned 60.18-decimal fixed-point number.
function mulDiv18(uint256 x, uint256 y) pure returns (uint256 result) {
    uint256 prod0;
    uint256 prod1;
    assembly ("memory-safe") {
        let mm := mulmod(x, y, not(0))
        prod0 := mul(x, y)
        prod1 := sub(sub(mm, prod0), lt(mm, prod0))
    }

    if (prod1 >= UNIT) {
        revert PRBMath_MulDiv18_Overflow(x, y);
    }

    uint256 remainder;
    assembly ("memory-safe") {
        remainder := mulmod(x, y, UNIT)
    }

    if (prod1 == 0) {
        unchecked {
            return prod0 / UNIT;
        }
    }

    assembly ("memory-safe") {
        result := mul(
            or(
                div(sub(prod0, remainder), UNIT_LPOTD),
                mul(sub(prod1, gt(remainder, prod0)), add(div(sub(0, UNIT_LPOTD), UNIT_LPOTD), 1))
            ),
            UNIT_INVERSE
        )
    }
}

/// @notice Calculates floor(x*y÷denominator) with full precision.
///
/// @dev An extension of `mulDiv` for signed numbers. Works by computing the signs and the absolute values separately.
///
/// Requirements:
/// - None of the inputs can be `type(int256).min`.
/// - The result must fit within int256.
///
/// @param x The multiplicand as an int256.
/// @param y The multiplier as an int256.
/// @param denominator The divisor as an int256.
/// @return result The result as an int256.
function mulDivSigned(int256 x, int256 y, int256 denominator) pure returns (int256 result) {
    if (x == type(int256).min || y == type(int256).min || denominator == type(int256).min) {
        revert PRBMath_MulDivSigned_InputTooSmall();
    }

    // Get hold of the absolute values of x, y and the denominator.
    uint256 absX;
    uint256 absY;
    uint256 absD;
    unchecked {
        absX = x < 0 ? uint256(-x) : uint256(x);
        absY = y < 0 ? uint256(-y) : uint256(y);
        absD = denominator < 0 ? uint256(-denominator) : uint256(denominator);
    }

    // Compute the absolute value of (x*y)÷denominator. The result must fit within int256.
    uint256 rAbs = mulDiv(absX, absY, absD);
    if (rAbs > uint256(type(int256).max)) {
        revert PRBMath_MulDivSigned_Overflow(x, y);
    }

    // Get the signs of x, y and the denominator.
    uint256 sx;
    uint256 sy;
    uint256 sd;
    assembly ("memory-safe") {
        // This works thanks to two's complement.
        // "sgt" stands for "signed greater than" and "sub(0,1)" is max uint256.
        sx := sgt(x, sub(0, 1))
        sy := sgt(y, sub(0, 1))
        sd := sgt(denominator, sub(0, 1))
    }

    // XOR over sx, sy and sd. What this does is to check whether there are 1 or 3 negative signs in the inputs.
    // If there are, the result should be negative. Otherwise, it should be positive.
    unchecked {
        result = sx ^ sy ^ sd == 0 ? -int256(rAbs) : int256(rAbs);
    }
}

/// @notice Calculates the binary exponent of x using the binary fraction method.
/// @dev Has to use 192.64-bit fixed-point numbers.
/// See https://ethereum.stackexchange.com/a/96594/24693.
/// @param x The exponent as an unsigned 192.64-bit fixed-point number.
/// @return result The result as an unsigned 60.18-decimal fixed-point number.
function prbExp2(uint256 x) pure returns (uint256 result) {
    unchecked {
        // Start from 0.5 in the 192.64-bit fixed-point format.
        result = 0x800000000000000000000000000000000000000000000000;

        // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
        // because the initial result is 2^191 and all magic factors are less than 2^65.
        if (x & 0xFF00000000000000 > 0) {
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
        }

        if (x & 0xFF000000000000 > 0) {
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
        }

        if (x & 0xFF0000000000 > 0) {
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
        }

        if (x & 0xFF00000000 > 0) {
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
        }

        if (x & 0xFF00000000 > 0) {
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
        }

        if (x & 0xFF0000 > 0) {
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
        }

        if (x & 0xFF00 > 0) {
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
        }

        if (x & 0xFF > 0) {
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
        }

        // We're doing two things at the same time:
        //
        //   1. Multiply the result by 2^n + 1, where "2^n" is the integer part and the one is added to account for
        //      the fact that we initially set the result to 0.5. This is accomplished by subtracting from 191
        //      rather than 192.
        //   2. Convert the result to the unsigned 60.18-decimal fixed-point format.
        //
        // This works because 2^(191-ip) = 2^ip / 2^191, where "ip" is the integer part "2^n".
        result *= UNIT;
        result >>= (191 - (x >> 64));
    }
}

/// @notice Calculates the square root of x, rounding down if x is not a perfect square.
/// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
/// Credits to OpenZeppelin for the explanations in code comments below.
///
/// Caveats:
/// - This function does not work with fixed-point numbers.
///
/// @param x The uint256 number for which to calculate the square root.
/// @return result The result as an uint256.
function prbSqrt(uint256 x) pure returns (uint256 result) {
    if (x == 0) {
        return 0;
    }

    // For our first guess, we get the biggest power of 2 which is smaller than the square root of x.
    //
    // We know that the "msb" (most significant bit) of x is a power of 2 such that we have:
    //
    // $$
    // msb(x) <= x <= 2*msb(x)$
    // $$
    //
    // We write $msb(x)$ as $2^k$ and we get:
    //
    // $$
    // k = log_2(x)
    // $$
    //
    // Thus we can write the initial inequality as:
    //
    // $$
    // 2^{log_2(x)} <= x <= 2*2^{log_2(x)+1} \\
    // sqrt(2^k) <= sqrt(x) < sqrt(2^{k+1}) \\
    // 2^{k/2} <= sqrt(x) < 2^{(k+1)/2} <= 2^{(k/2)+1}
    // $$
    //
    // Consequently, $2^{log_2(x) /2}` is a good first approximation of sqrt(x) with at least one correct bit.
    uint256 xAux = uint256(x);
    result = 1;
    if (xAux >= 2 ** 128) {
        xAux >>= 128;
        result <<= 64;
    }
    if (xAux >= 2 ** 64) {
        xAux >>= 64;
        result <<= 32;
    }
    if (xAux >= 2 ** 32) {
        xAux >>= 32;
        result <<= 16;
    }
    if (xAux >= 2 ** 16) {
        xAux >>= 16;
        result <<= 8;
    }
    if (xAux >= 2 ** 8) {
        xAux >>= 8;
        result <<= 4;
    }
    if (xAux >= 2 ** 4) {
        xAux >>= 4;
        result <<= 2;
    }
    if (xAux >= 2 ** 2) {
        result <<= 1;
    }

    // At this point, `result` is an estimation with at least one bit of precision. We know the true value has at
    // most 128 bits, since  it is the square root of a uint256. Newton's method converges quadratically (precision
    // doubles at every iteration). We thus need at most 7 iteration to turn our partial result with one bit of
    // precision into the expected uint128 result.
    unchecked {
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;

        // Round down the result in case x is not a perfect square.
        uint256 roundedDownResult = x / result;
        if (result >= roundedDownResult) {
            result = roundedDownResult;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./sd59x18/Casting.sol";
import "./sd59x18/Constants.sol";
import "./sd59x18/Conversions.sol";
import "./sd59x18/Errors.sol";
import "./sd59x18/Helpers.sol";
import "./sd59x18/Math.sol";
import "./sd59x18/ValueType.sol";

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./ud60x18/Casting.sol";
import "./ud60x18/Constants.sol";
import "./ud60x18/Conversions.sol";
import "./ud60x18/Errors.sol";
import "./ud60x18/Helpers.sol";
import "./ud60x18/Math.sol";
import "./ud60x18/ValueType.sol";

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { MAX_UINT40 } from "../Common.sol";
import { SD59x18 } from "../sd59x18/ValueType.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "../ud60x18/ValueType.sol";
import {
    PRBMath_SD1x18_ToUD2x18_Underflow,
    PRBMath_SD1x18_ToUD60x18_Underflow,
    PRBMath_SD1x18_ToUint128_Underflow,
    PRBMath_SD1x18_ToUint256_Underflow,
    PRBMath_SD1x18_ToUint40_Overflow,
    PRBMath_SD1x18_ToUint40_Underflow
} from "./Errors.sol";
import { SD1x18 } from "./ValueType.sol";

/// @notice Casts an SD1x18 number into SD59x18.
/// @dev There is no overflow check because the domain of SD1x18 is a subset of SD59x18.
function intoSD59x18(SD1x18 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(int256(SD1x18.unwrap(x)));
}

/// @notice Casts an SD1x18 number into UD2x18.
/// - x must be positive.
function intoUD2x18(SD1x18 x) pure returns (UD2x18 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD1x18_ToUD2x18_Underflow(x);
    }
    result = UD2x18.wrap(uint64(xInt));
}

/// @notice Casts an SD1x18 number into UD60x18.
/// @dev Requirements:
/// - x must be positive.
function intoUD60x18(SD1x18 x) pure returns (UD60x18 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD1x18_ToUD60x18_Underflow(x);
    }
    result = UD60x18.wrap(uint64(xInt));
}

/// @notice Casts an SD1x18 number into uint256.
/// @dev Requirements:
/// - x must be positive.
function intoUint256(SD1x18 x) pure returns (uint256 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD1x18_ToUint256_Underflow(x);
    }
    result = uint256(uint64(xInt));
}

/// @notice Casts an SD1x18 number into uint128.
/// @dev Requirements:
/// - x must be positive.
function intoUint128(SD1x18 x) pure returns (uint128 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD1x18_ToUint128_Underflow(x);
    }
    result = uint128(uint64(xInt));
}

/// @notice Casts an SD1x18 number into uint40.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(SD1x18 x) pure returns (uint40 result) {
    int64 xInt = SD1x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD1x18_ToUint40_Underflow(x);
    }
    if (xInt > int64(uint64(MAX_UINT40))) {
        revert PRBMath_SD1x18_ToUint40_Overflow(x);
    }
    result = uint40(uint64(xInt));
}

/// @notice Alias for the `wrap` function.
function sd1x18(int64 x) pure returns (SD1x18 result) {
    result = wrap(x);
}

/// @notice Unwraps an SD1x18 number into int64.
function unwrap(SD1x18 x) pure returns (int64 result) {
    result = SD1x18.unwrap(x);
}

/// @notice Wraps an int64 number into the SD1x18 value type.
function wrap(int64 x) pure returns (SD1x18 result) {
    result = SD1x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { SD1x18 } from "./ValueType.sol";

/// @dev Euler's number as an SD1x18 number.
SD1x18 constant E = SD1x18.wrap(2_718281828459045235);

/// @dev The maximum value an SD1x18 number can have.
int64 constant uMAX_SD1x18 = 9_223372036854775807;
SD1x18 constant MAX_SD1x18 = SD1x18.wrap(uMAX_SD1x18);

/// @dev The maximum value an SD1x18 number can have.
int64 constant uMIN_SD1x18 = -9_223372036854775808;
SD1x18 constant MIN_SD1x18 = SD1x18.wrap(uMIN_SD1x18);

/// @dev PI as an SD1x18 number.
SD1x18 constant PI = SD1x18.wrap(3_141592653589793238);

/// @dev The unit amount that implies how many trailing decimals can be represented.
SD1x18 constant UNIT = SD1x18.wrap(1e18);
int256 constant uUNIT = 1e18;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { SD1x18 } from "./ValueType.sol";

/// @notice Emitted when trying to cast a SD1x18 number that doesn't fit in UD2x18.
error PRBMath_SD1x18_ToUD2x18_Underflow(SD1x18 x);

/// @notice Emitted when trying to cast a SD1x18 number that doesn't fit in UD60x18.
error PRBMath_SD1x18_ToUD60x18_Underflow(SD1x18 x);

/// @notice Emitted when trying to cast a SD1x18 number that doesn't fit in uint128.
error PRBMath_SD1x18_ToUint128_Underflow(SD1x18 x);

/// @notice Emitted when trying to cast a SD1x18 number that doesn't fit in uint256.
error PRBMath_SD1x18_ToUint256_Underflow(SD1x18 x);

/// @notice Emitted when trying to cast a SD1x18 number that doesn't fit in uint40.
error PRBMath_SD1x18_ToUint40_Overflow(SD1x18 x);

/// @notice Emitted when trying to cast a SD1x18 number that doesn't fit in uint40.
error PRBMath_SD1x18_ToUint40_Underflow(SD1x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./Casting.sol" as C;

/// @notice The signed 1.18-decimal fixed-point number representation, which can have up to 1 digit and up to 18 decimals.
/// The values of this are bound by the minimum and the maximum values permitted by the underlying Solidity type int64.
/// This is useful when end users want to use int64 to save gas, e.g. with tight variable packing in contract storage.
type SD1x18 is int64;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using { C.intoSD59x18, C.intoUD2x18, C.intoUD60x18, C.intoUint256, C.intoUint128, C.intoUint40, C.unwrap } for SD1x18 global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { MAX_UINT128, MAX_UINT40 } from "../Common.sol";
import { uMAX_SD1x18, uMIN_SD1x18 } from "../sd1x18/Constants.sol";
import { SD1x18 } from "../sd1x18/ValueType.sol";
import { uMAX_UD2x18 } from "../ud2x18/Constants.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "../ud60x18/ValueType.sol";
import {
    PRBMath_SD59x18_IntoSD1x18_Overflow,
    PRBMath_SD59x18_IntoSD1x18_Underflow,
    PRBMath_SD59x18_IntoUD2x18_Overflow,
    PRBMath_SD59x18_IntoUD2x18_Underflow,
    PRBMath_SD59x18_IntoUD60x18_Underflow,
    PRBMath_SD59x18_IntoUint128_Overflow,
    PRBMath_SD59x18_IntoUint128_Underflow,
    PRBMath_SD59x18_IntoUint256_Underflow,
    PRBMath_SD59x18_IntoUint40_Overflow,
    PRBMath_SD59x18_IntoUint40_Underflow
} from "./Errors.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Casts an SD59x18 number into int256.
/// @dev This is basically a functional alias for the `unwrap` function.
function intoInt256(SD59x18 x) pure returns (int256 result) {
    result = SD59x18.unwrap(x);
}

/// @notice Casts an SD59x18 number into SD1x18.
/// @dev Requirements:
/// - x must be greater than or equal to `uMIN_SD1x18`.
/// - x must be less than or equal to `uMAX_SD1x18`.
function intoSD1x18(SD59x18 x) pure returns (SD1x18 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < uMIN_SD1x18) {
        revert PRBMath_SD59x18_IntoSD1x18_Underflow(x);
    }
    if (xInt > uMAX_SD1x18) {
        revert PRBMath_SD59x18_IntoSD1x18_Overflow(x);
    }
    result = SD1x18.wrap(int64(xInt));
}

/// @notice Casts an SD59x18 number into UD2x18.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `uMAX_UD2x18`.
function intoUD2x18(SD59x18 x) pure returns (UD2x18 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD59x18_IntoUD2x18_Underflow(x);
    }
    if (xInt > int256(uint256(uMAX_UD2x18))) {
        revert PRBMath_SD59x18_IntoUD2x18_Overflow(x);
    }
    result = UD2x18.wrap(uint64(uint256(xInt)));
}

/// @notice Casts an SD59x18 number into UD60x18.
/// @dev Requirements:
/// - x must be positive.
function intoUD60x18(SD59x18 x) pure returns (UD60x18 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD59x18_IntoUD60x18_Underflow(x);
    }
    result = UD60x18.wrap(uint256(xInt));
}

/// @notice Casts an SD59x18 number into uint256.
/// @dev Requirements:
/// - x must be positive.
function intoUint256(SD59x18 x) pure returns (uint256 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD59x18_IntoUint256_Underflow(x);
    }
    result = uint256(xInt);
}

/// @notice Casts an SD59x18 number into uint128.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `uMAX_UINT128`.
function intoUint128(SD59x18 x) pure returns (uint128 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD59x18_IntoUint128_Underflow(x);
    }
    if (xInt > int256(uint256(MAX_UINT128))) {
        revert PRBMath_SD59x18_IntoUint128_Overflow(x);
    }
    result = uint128(uint256(xInt));
}

/// @notice Casts an SD59x18 number into uint40.
/// @dev Requirements:
/// - x must be positive.
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(SD59x18 x) pure returns (uint40 result) {
    int256 xInt = SD59x18.unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD59x18_IntoUint40_Underflow(x);
    }
    if (xInt > int256(uint256(MAX_UINT40))) {
        revert PRBMath_SD59x18_IntoUint40_Overflow(x);
    }
    result = uint40(uint256(xInt));
}

/// @notice Alias for the `wrap` function.
function sd(int256 x) pure returns (SD59x18 result) {
    result = wrap(x);
}

/// @notice Alias for the `wrap` function.
function sd59x18(int256 x) pure returns (SD59x18 result) {
    result = wrap(x);
}

/// @notice Unwraps an SD59x18 number into int256.
function unwrap(SD59x18 x) pure returns (int256 result) {
    result = SD59x18.unwrap(x);
}

/// @notice Wraps an int256 number into the SD59x18 value type.
function wrap(int256 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { SD59x18 } from "./ValueType.sol";

/// NOTICE: the "u" prefix stands for "unwrapped".

/// @dev Euler's number as an SD59x18 number.
SD59x18 constant E = SD59x18.wrap(2_718281828459045235);

/// @dev Half the UNIT number.
int256 constant uHALF_UNIT = 0.5e18;
SD59x18 constant HALF_UNIT = SD59x18.wrap(uHALF_UNIT);

/// @dev log2(10) as an SD59x18 number.
int256 constant uLOG2_10 = 3_321928094887362347;
SD59x18 constant LOG2_10 = SD59x18.wrap(uLOG2_10);

/// @dev log2(e) as an SD59x18 number.
int256 constant uLOG2_E = 1_442695040888963407;
SD59x18 constant LOG2_E = SD59x18.wrap(uLOG2_E);

/// @dev The maximum value an SD59x18 number can have.
int256 constant uMAX_SD59x18 = 57896044618658097711785492504343953926634992332820282019728_792003956564819967;
SD59x18 constant MAX_SD59x18 = SD59x18.wrap(uMAX_SD59x18);

/// @dev The maximum whole value an SD59x18 number can have.
int256 constant uMAX_WHOLE_SD59x18 = 57896044618658097711785492504343953926634992332820282019728_000000000000000000;
SD59x18 constant MAX_WHOLE_SD59x18 = SD59x18.wrap(uMAX_WHOLE_SD59x18);

/// @dev The minimum value an SD59x18 number can have.
int256 constant uMIN_SD59x18 = -57896044618658097711785492504343953926634992332820282019728_792003956564819968;
SD59x18 constant MIN_SD59x18 = SD59x18.wrap(uMIN_SD59x18);

/// @dev The minimum whole value an SD59x18 number can have.
int256 constant uMIN_WHOLE_SD59x18 = -57896044618658097711785492504343953926634992332820282019728_000000000000000000;
SD59x18 constant MIN_WHOLE_SD59x18 = SD59x18.wrap(uMIN_WHOLE_SD59x18);

/// @dev PI as an SD59x18 number.
SD59x18 constant PI = SD59x18.wrap(3_141592653589793238);

/// @dev The unit amount that implies how many trailing decimals can be represented.
int256 constant uUNIT = 1e18;
SD59x18 constant UNIT = SD59x18.wrap(1e18);

/// @dev Zero as an SD59x18 number.
SD59x18 constant ZERO = SD59x18.wrap(0);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { uMAX_SD59x18, uMIN_SD59x18, uUNIT } from "./Constants.sol";
import { PRBMath_SD59x18_Convert_Overflow, PRBMath_SD59x18_Convert_Underflow } from "./Errors.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Converts a simple integer to SD59x18 by multiplying it by `UNIT`.
///
/// @dev Requirements:
/// - x must be greater than or equal to `MIN_SD59x18` divided by `UNIT`.
/// - x must be less than or equal to `MAX_SD59x18` divided by `UNIT`.
///
/// @param x The basic integer to convert.
/// @param result The same number converted to SD59x18.
function convert(int256 x) pure returns (SD59x18 result) {
    if (x < uMIN_SD59x18 / uUNIT) {
        revert PRBMath_SD59x18_Convert_Underflow(x);
    }
    if (x > uMAX_SD59x18 / uUNIT) {
        revert PRBMath_SD59x18_Convert_Overflow(x);
    }
    unchecked {
        result = SD59x18.wrap(x * uUNIT);
    }
}

/// @notice Converts an SD59x18 number to a simple integer by dividing it by `UNIT`. Rounds towards zero in the process.
/// @param x The SD59x18 number to convert.
/// @return result The same number as a simple integer.
function convert(SD59x18 x) pure returns (int256 result) {
    result = SD59x18.unwrap(x) / uUNIT;
}

/// @notice Alias for the `convert` function defined above.
/// @dev Here for backward compatibility. Will be removed in V4.
function fromSD59x18(SD59x18 x) pure returns (int256 result) {
    result = convert(x);
}

/// @notice Alias for the `convert` function defined above.
/// @dev Here for backward compatibility. Will be removed in V4.
function toSD59x18(int256 x) pure returns (SD59x18 result) {
    result = convert(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { SD59x18 } from "./ValueType.sol";

/// @notice Emitted when taking the absolute value of `MIN_SD59x18`.
error PRBMath_SD59x18_Abs_MinSD59x18();

/// @notice Emitted when ceiling a number overflows SD59x18.
error PRBMath_SD59x18_Ceil_Overflow(SD59x18 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows SD59x18.
error PRBMath_SD59x18_Convert_Overflow(int256 x);

/// @notice Emitted when converting a basic integer to the fixed-point format underflows SD59x18.
error PRBMath_SD59x18_Convert_Underflow(int256 x);

/// @notice Emitted when dividing two numbers and one of them is `MIN_SD59x18`.
error PRBMath_SD59x18_Div_InputTooSmall();

/// @notice Emitted when dividing two numbers and one of the intermediary unsigned results overflows SD59x18.
error PRBMath_SD59x18_Div_Overflow(SD59x18 x, SD59x18 y);

/// @notice Emitted when taking the natural exponent of a base greater than 133.084258667509499441.
error PRBMath_SD59x18_Exp_InputTooBig(SD59x18 x);

/// @notice Emitted when taking the binary exponent of a base greater than 192.
error PRBMath_SD59x18_Exp2_InputTooBig(SD59x18 x);

/// @notice Emitted when flooring a number underflows SD59x18.
error PRBMath_SD59x18_Floor_Underflow(SD59x18 x);

/// @notice Emitted when taking the geometric mean of two numbers and their product is negative.
error PRBMath_SD59x18_Gm_NegativeProduct(SD59x18 x, SD59x18 y);

/// @notice Emitted when taking the geometric mean of two numbers and multiplying them overflows SD59x18.
error PRBMath_SD59x18_Gm_Overflow(SD59x18 x, SD59x18 y);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in SD1x18.
error PRBMath_SD59x18_IntoSD1x18_Overflow(SD59x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in SD1x18.
error PRBMath_SD59x18_IntoSD1x18_Underflow(SD59x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in UD2x18.
error PRBMath_SD59x18_IntoUD2x18_Overflow(SD59x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in UD2x18.
error PRBMath_SD59x18_IntoUD2x18_Underflow(SD59x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in UD60x18.
error PRBMath_SD59x18_IntoUD60x18_Underflow(SD59x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in uint128.
error PRBMath_SD59x18_IntoUint128_Overflow(SD59x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in uint128.
error PRBMath_SD59x18_IntoUint128_Underflow(SD59x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in uint256.
error PRBMath_SD59x18_IntoUint256_Underflow(SD59x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in uint40.
error PRBMath_SD59x18_IntoUint40_Overflow(SD59x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in uint40.
error PRBMath_SD59x18_IntoUint40_Underflow(SD59x18 x);

/// @notice Emitted when taking the logarithm of a number less than or equal to zero.
error PRBMath_SD59x18_Log_InputTooSmall(SD59x18 x);

/// @notice Emitted when multiplying two numbers and one of the inputs is `MIN_SD59x18`.
error PRBMath_SD59x18_Mul_InputTooSmall();

/// @notice Emitted when multiplying two numbers and the intermediary absolute result overflows SD59x18.
error PRBMath_SD59x18_Mul_Overflow(SD59x18 x, SD59x18 y);

/// @notice Emitted when raising a number to a power and hte intermediary absolute result overflows SD59x18.
error PRBMath_SD59x18_Powu_Overflow(SD59x18 x, uint256 y);

/// @notice Emitted when taking the square root of a negative number.
error PRBMath_SD59x18_Sqrt_NegativeInput(SD59x18 x);

/// @notice Emitted when the calculating the square root overflows SD59x18.
error PRBMath_SD59x18_Sqrt_Overflow(SD59x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { unwrap, wrap } from "./Casting.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Implements the checked addition operation (+) in the SD59x18 type.
function add(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    return wrap(unwrap(x) + unwrap(y));
}

/// @notice Implements the AND (&) bitwise operation in the SD59x18 type.
function and(SD59x18 x, int256 bits) pure returns (SD59x18 result) {
    return wrap(unwrap(x) & bits);
}

/// @notice Implements the equal (=) operation in the SD59x18 type.
function eq(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = unwrap(x) == unwrap(y);
}

/// @notice Implements the greater than operation (>) in the SD59x18 type.
function gt(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = unwrap(x) > unwrap(y);
}

/// @notice Implements the greater than or equal to operation (>=) in the SD59x18 type.
function gte(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = unwrap(x) >= unwrap(y);
}

/// @notice Implements a zero comparison check function in the SD59x18 type.
function isZero(SD59x18 x) pure returns (bool result) {
    result = unwrap(x) == 0;
}

/// @notice Implements the left shift operation (<<) in the SD59x18 type.
function lshift(SD59x18 x, uint256 bits) pure returns (SD59x18 result) {
    result = wrap(unwrap(x) << bits);
}

/// @notice Implements the lower than operation (<) in the SD59x18 type.
function lt(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = unwrap(x) < unwrap(y);
}

/// @notice Implements the lower than or equal to operation (<=) in the SD59x18 type.
function lte(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = unwrap(x) <= unwrap(y);
}

/// @notice Implements the unchecked modulo operation (%) in the SD59x18 type.
function mod(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(unwrap(x) % unwrap(y));
}

/// @notice Implements the not equal operation (!=) in the SD59x18 type.
function neq(SD59x18 x, SD59x18 y) pure returns (bool result) {
    result = unwrap(x) != unwrap(y);
}

/// @notice Implements the OR (|) bitwise operation in the SD59x18 type.
function or(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(unwrap(x) | unwrap(y));
}

/// @notice Implements the right shift operation (>>) in the SD59x18 type.
function rshift(SD59x18 x, uint256 bits) pure returns (SD59x18 result) {
    result = wrap(unwrap(x) >> bits);
}

/// @notice Implements the checked subtraction operation (-) in the SD59x18 type.
function sub(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(unwrap(x) - unwrap(y));
}

/// @notice Implements the unchecked addition operation (+) in the SD59x18 type.
function uncheckedAdd(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    unchecked {
        result = wrap(unwrap(x) + unwrap(y));
    }
}

/// @notice Implements the unchecked subtraction operation (-) in the SD59x18 type.
function uncheckedSub(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    unchecked {
        result = wrap(unwrap(x) - unwrap(y));
    }
}

/// @notice Implements the unchecked unary minus operation (-) in the SD59x18 type.
function uncheckedUnary(SD59x18 x) pure returns (SD59x18 result) {
    unchecked {
        result = wrap(-unwrap(x));
    }
}

/// @notice Implements the XOR (^) bitwise operation in the SD59x18 type.
function xor(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    result = wrap(unwrap(x) ^ unwrap(y));
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { MAX_UINT128, MAX_UINT40, msb, mulDiv, mulDiv18, prbExp2, prbSqrt } from "../Common.sol";
import {
    uHALF_UNIT,
    uLOG2_10,
    uLOG2_E,
    uMAX_SD59x18,
    uMAX_WHOLE_SD59x18,
    uMIN_SD59x18,
    uMIN_WHOLE_SD59x18,
    UNIT,
    uUNIT,
    ZERO
} from "./Constants.sol";
import {
    PRBMath_SD59x18_Abs_MinSD59x18,
    PRBMath_SD59x18_Ceil_Overflow,
    PRBMath_SD59x18_Div_InputTooSmall,
    PRBMath_SD59x18_Div_Overflow,
    PRBMath_SD59x18_Exp_InputTooBig,
    PRBMath_SD59x18_Exp2_InputTooBig,
    PRBMath_SD59x18_Floor_Underflow,
    PRBMath_SD59x18_Gm_Overflow,
    PRBMath_SD59x18_Gm_NegativeProduct,
    PRBMath_SD59x18_Log_InputTooSmall,
    PRBMath_SD59x18_Mul_InputTooSmall,
    PRBMath_SD59x18_Mul_Overflow,
    PRBMath_SD59x18_Powu_Overflow,
    PRBMath_SD59x18_Sqrt_NegativeInput,
    PRBMath_SD59x18_Sqrt_Overflow
} from "./Errors.sol";
import { unwrap, wrap } from "./Helpers.sol";
import { SD59x18 } from "./ValueType.sol";

/// @notice Calculate the absolute value of x.
///
/// @dev Requirements:
/// - x must be greater than `MIN_SD59x18`.
///
/// @param x The SD59x18 number for which to calculate the absolute value.
/// @param result The absolute value of x as an SD59x18 number.
function abs(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    if (xInt == uMIN_SD59x18) {
        revert PRBMath_SD59x18_Abs_MinSD59x18();
    }
    result = xInt < 0 ? wrap(-xInt) : x;
}

/// @notice Calculates the arithmetic average of x and y, rounding towards zero.
/// @param x The first operand as an SD59x18 number.
/// @param y The second operand as an SD59x18 number.
/// @return result The arithmetic average as an SD59x18 number.
function avg(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    int256 yInt = unwrap(y);

    unchecked {
        // This is equivalent to "x / 2 +  y / 2" but faster.
        // This operation can never overflow.
        int256 sum = (xInt >> 1) + (yInt >> 1);

        if (sum < 0) {
            // If at least one of x and y is odd, we add 1 to the result, since shifting negative numbers to the right rounds
            // down to infinity. The right part is equivalent to "sum + (x % 2 == 1 || y % 2 == 1)" but faster.
            assembly ("memory-safe") {
                result := add(sum, and(or(xInt, yInt), 1))
            }
        } else {
            // We need to add 1 if both x and y are odd to account for the double 0.5 remainder that is truncated after shifting.
            result = wrap(sum + (xInt & yInt & 1));
        }
    }
}

/// @notice Yields the smallest whole SD59x18 number greater than or equal to x.
///
/// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
/// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
///
/// Requirements:
/// - x must be less than or equal to `MAX_WHOLE_SD59x18`.
///
/// @param x The SD59x18 number to ceil.
/// @param result The least number greater than or equal to x, as an SD59x18 number.
function ceil(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    if (xInt > uMAX_WHOLE_SD59x18) {
        revert PRBMath_SD59x18_Ceil_Overflow(x);
    }

    int256 remainder = xInt % uUNIT;
    if (remainder == 0) {
        result = x;
    } else {
        unchecked {
            // Solidity uses C fmod style, which returns a modulus with the same sign as x.
            int256 resultInt = xInt - remainder;
            if (xInt > 0) {
                resultInt += uUNIT;
            }
            result = wrap(resultInt);
        }
    }
}

/// @notice Divides two SD59x18 numbers, returning a new SD59x18 number. Rounds towards zero.
///
/// @dev This is a variant of `mulDiv` that works with signed numbers. Works by computing the signs and the absolute values
/// separately.
///
/// Requirements:
/// - All from `Common.mulDiv`.
/// - None of the inputs can be `MIN_SD59x18`.
/// - The denominator cannot be zero.
/// - The result must fit within int256.
///
/// Caveats:
/// - All from `Common.mulDiv`.
///
/// @param x The numerator as an SD59x18 number.
/// @param y The denominator as an SD59x18 number.
/// @param result The quotient as an SD59x18 number.
function div(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    int256 yInt = unwrap(y);
    if (xInt == uMIN_SD59x18 || yInt == uMIN_SD59x18) {
        revert PRBMath_SD59x18_Div_InputTooSmall();
    }

    // Get hold of the absolute values of x and y.
    uint256 xAbs;
    uint256 yAbs;
    unchecked {
        xAbs = xInt < 0 ? uint256(-xInt) : uint256(xInt);
        yAbs = yInt < 0 ? uint256(-yInt) : uint256(yInt);
    }

    // Compute the absolute value (x*UNIT)÷y. The resulting value must fit within int256.
    uint256 resultAbs = mulDiv(xAbs, uint256(uUNIT), yAbs);
    if (resultAbs > uint256(uMAX_SD59x18)) {
        revert PRBMath_SD59x18_Div_Overflow(x, y);
    }

    // Check if x and y have the same sign. This works thanks to two's complement; the left-most bit is the sign bit.
    bool sameSign = (xInt ^ yInt) > -1;

    // If the inputs don't have the same sign, the result should be negative. Otherwise, it should be positive.
    unchecked {
        result = wrap(sameSign ? int256(resultAbs) : -int256(resultAbs));
    }
}

/// @notice Calculates the natural exponent of x.
///
/// @dev Based on the formula:
///
/// $$
/// e^x = 2^{x * log_2{e}}
/// $$
///
/// Requirements:
/// - All from `log2`.
/// - x must be less than 133.084258667509499441.
///
/// Caveats:
/// - All from `exp2`.
/// - For any x less than -41.446531673892822322, the result is zero.
///
/// @param x The exponent as an SD59x18 number.
/// @return result The result as an SD59x18 number.
function exp(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    // Without this check, the value passed to `exp2` would be less than -59.794705707972522261.
    if (xInt < -41_446531673892822322) {
        return ZERO;
    }

    // Without this check, the value passed to `exp2` would be greater than 192.
    if (xInt >= 133_084258667509499441) {
        revert PRBMath_SD59x18_Exp_InputTooBig(x);
    }

    unchecked {
        // Do the fixed-point multiplication inline to save gas.
        int256 doubleUnitProduct = xInt * uLOG2_E;
        result = exp2(wrap(doubleUnitProduct / uUNIT));
    }
}

/// @notice Calculates the binary exponent of x using the binary fraction method.
///
/// @dev Based on the formula:
///
/// $$
/// 2^{-x} = \frac{1}{2^x}
/// $$
///
/// See https://ethereum.stackexchange.com/q/79903/24693.
///
/// Requirements:
/// - x must be 192 or less.
/// - The result must fit within `MAX_SD59x18`.
///
/// Caveats:
/// - For any x less than -59.794705707972522261, the result is zero.
///
/// @param x The exponent as an SD59x18 number.
/// @return result The result as an SD59x18 number.
function exp2(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    if (xInt < 0) {
        // 2^59.794705707972522262 is the maximum number whose inverse does not truncate down to zero.
        if (xInt < -59_794705707972522261) {
            return ZERO;
        }

        unchecked {
            // Do the fixed-point inversion $1/2^x$ inline to save gas. 1e36 is UNIT * UNIT.
            result = wrap(1e36 / unwrap(exp2(wrap(-xInt))));
        }
    } else {
        // 2^192 doesn't fit within the 192.64-bit format used internally in this function.
        if (xInt >= 192e18) {
            revert PRBMath_SD59x18_Exp2_InputTooBig(x);
        }

        unchecked {
            // Convert x to the 192.64-bit fixed-point format.
            uint256 x_192x64 = uint256((xInt << 64) / uUNIT);

            // It is safe to convert the result to int256 with no checks because the maximum input allowed in this function is 192.
            result = wrap(int256(prbExp2(x_192x64)));
        }
    }
}

/// @notice Yields the greatest whole SD59x18 number less than or equal to x.
///
/// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
/// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
///
/// Requirements:
/// - x must be greater than or equal to `MIN_WHOLE_SD59x18`.
///
/// @param x The SD59x18 number to floor.
/// @param result The greatest integer less than or equal to x, as an SD59x18 number.
function floor(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    if (xInt < uMIN_WHOLE_SD59x18) {
        revert PRBMath_SD59x18_Floor_Underflow(x);
    }

    int256 remainder = xInt % uUNIT;
    if (remainder == 0) {
        result = x;
    } else {
        unchecked {
            // Solidity uses C fmod style, which returns a modulus with the same sign as x.
            int256 resultInt = xInt - remainder;
            if (xInt < 0) {
                resultInt -= uUNIT;
            }
            result = wrap(resultInt);
        }
    }
}

/// @notice Yields the excess beyond the floor of x for positive numbers and the part of the number to the right.
/// of the radix point for negative numbers.
/// @dev Based on the odd function definition. https://en.wikipedia.org/wiki/Fractional_part
/// @param x The SD59x18 number to get the fractional part of.
/// @param result The fractional part of x as an SD59x18 number.
function frac(SD59x18 x) pure returns (SD59x18 result) {
    result = wrap(unwrap(x) % uUNIT);
}

/// @notice Calculates the geometric mean of x and y, i.e. sqrt(x * y), rounding down.
///
/// @dev Requirements:
/// - x * y must fit within `MAX_SD59x18`, lest it overflows.
/// - x * y must not be negative, since this library does not handle complex numbers.
///
/// @param x The first operand as an SD59x18 number.
/// @param y The second operand as an SD59x18 number.
/// @return result The result as an SD59x18 number.
function gm(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    int256 yInt = unwrap(y);
    if (xInt == 0 || yInt == 0) {
        return ZERO;
    }

    unchecked {
        // Equivalent to "xy / x != y". Checking for overflow this way is faster than letting Solidity do it.
        int256 xyInt = xInt * yInt;
        if (xyInt / xInt != yInt) {
            revert PRBMath_SD59x18_Gm_Overflow(x, y);
        }

        // The product must not be negative, since this library does not handle complex numbers.
        if (xyInt < 0) {
            revert PRBMath_SD59x18_Gm_NegativeProduct(x, y);
        }

        // We don't need to multiply the result by `UNIT` here because the x*y product had picked up a factor of `UNIT`
        // during multiplication. See the comments within the `prbSqrt` function.
        uint256 resultUint = prbSqrt(uint256(xyInt));
        result = wrap(int256(resultUint));
    }
}

/// @notice Calculates 1 / x, rounding toward zero.
///
/// @dev Requirements:
/// - x cannot be zero.
///
/// @param x The SD59x18 number for which to calculate the inverse.
/// @return result The inverse as an SD59x18 number.
function inv(SD59x18 x) pure returns (SD59x18 result) {
    // 1e36 is UNIT * UNIT.
    result = wrap(1e36 / unwrap(x));
}

/// @notice Calculates the natural logarithm of x.
///
/// @dev Based on the formula:
///
/// $$
/// ln{x} = log_2{x} / log_2{e}$$.
/// $$
///
/// Requirements:
/// - All from `log2`.
///
/// Caveats:
/// - All from `log2`.
/// - This doesn't return exactly 1 for 2.718281828459045235, for that more fine-grained precision is needed.
///
/// @param x The SD59x18 number for which to calculate the natural logarithm.
/// @return result The natural logarithm as an SD59x18 number.
function ln(SD59x18 x) pure returns (SD59x18 result) {
    // Do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value that log2(x)
    // can return is 195.205294292027477728.
    result = wrap((unwrap(log2(x)) * uUNIT) / uLOG2_E);
}

/// @notice Calculates the common logarithm of x.
///
/// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
/// logarithm based on the formula:
///
/// $$
/// log_{10}{x} = log_2{x} / log_2{10}
/// $$
///
/// Requirements:
/// - All from `log2`.
///
/// Caveats:
/// - All from `log2`.
///
/// @param x The SD59x18 number for which to calculate the common logarithm.
/// @return result The common logarithm as an SD59x18 number.
function log10(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD59x18_Log_InputTooSmall(x);
    }

    // Note that the `mul` in this block is the assembly mul operation, not the SD59x18 `mul`.
    // prettier-ignore
    assembly ("memory-safe") {
        switch x
        case 1 { result := mul(uUNIT, sub(0, 18)) }
        case 10 { result := mul(uUNIT, sub(1, 18)) }
        case 100 { result := mul(uUNIT, sub(2, 18)) }
        case 1000 { result := mul(uUNIT, sub(3, 18)) }
        case 10000 { result := mul(uUNIT, sub(4, 18)) }
        case 100000 { result := mul(uUNIT, sub(5, 18)) }
        case 1000000 { result := mul(uUNIT, sub(6, 18)) }
        case 10000000 { result := mul(uUNIT, sub(7, 18)) }
        case 100000000 { result := mul(uUNIT, sub(8, 18)) }
        case 1000000000 { result := mul(uUNIT, sub(9, 18)) }
        case 10000000000 { result := mul(uUNIT, sub(10, 18)) }
        case 100000000000 { result := mul(uUNIT, sub(11, 18)) }
        case 1000000000000 { result := mul(uUNIT, sub(12, 18)) }
        case 10000000000000 { result := mul(uUNIT, sub(13, 18)) }
        case 100000000000000 { result := mul(uUNIT, sub(14, 18)) }
        case 1000000000000000 { result := mul(uUNIT, sub(15, 18)) }
        case 10000000000000000 { result := mul(uUNIT, sub(16, 18)) }
        case 100000000000000000 { result := mul(uUNIT, sub(17, 18)) }
        case 1000000000000000000 { result := 0 }
        case 10000000000000000000 { result := uUNIT }
        case 100000000000000000000 { result := mul(uUNIT, 2) }
        case 1000000000000000000000 { result := mul(uUNIT, 3) }
        case 10000000000000000000000 { result := mul(uUNIT, 4) }
        case 100000000000000000000000 { result := mul(uUNIT, 5) }
        case 1000000000000000000000000 { result := mul(uUNIT, 6) }
        case 10000000000000000000000000 { result := mul(uUNIT, 7) }
        case 100000000000000000000000000 { result := mul(uUNIT, 8) }
        case 1000000000000000000000000000 { result := mul(uUNIT, 9) }
        case 10000000000000000000000000000 { result := mul(uUNIT, 10) }
        case 100000000000000000000000000000 { result := mul(uUNIT, 11) }
        case 1000000000000000000000000000000 { result := mul(uUNIT, 12) }
        case 10000000000000000000000000000000 { result := mul(uUNIT, 13) }
        case 100000000000000000000000000000000 { result := mul(uUNIT, 14) }
        case 1000000000000000000000000000000000 { result := mul(uUNIT, 15) }
        case 10000000000000000000000000000000000 { result := mul(uUNIT, 16) }
        case 100000000000000000000000000000000000 { result := mul(uUNIT, 17) }
        case 1000000000000000000000000000000000000 { result := mul(uUNIT, 18) }
        case 10000000000000000000000000000000000000 { result := mul(uUNIT, 19) }
        case 100000000000000000000000000000000000000 { result := mul(uUNIT, 20) }
        case 1000000000000000000000000000000000000000 { result := mul(uUNIT, 21) }
        case 10000000000000000000000000000000000000000 { result := mul(uUNIT, 22) }
        case 100000000000000000000000000000000000000000 { result := mul(uUNIT, 23) }
        case 1000000000000000000000000000000000000000000 { result := mul(uUNIT, 24) }
        case 10000000000000000000000000000000000000000000 { result := mul(uUNIT, 25) }
        case 100000000000000000000000000000000000000000000 { result := mul(uUNIT, 26) }
        case 1000000000000000000000000000000000000000000000 { result := mul(uUNIT, 27) }
        case 10000000000000000000000000000000000000000000000 { result := mul(uUNIT, 28) }
        case 100000000000000000000000000000000000000000000000 { result := mul(uUNIT, 29) }
        case 1000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 30) }
        case 10000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 31) }
        case 100000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 32) }
        case 1000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 33) }
        case 10000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 34) }
        case 100000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 35) }
        case 1000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 36) }
        case 10000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 37) }
        case 100000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 38) }
        case 1000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 39) }
        case 10000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 40) }
        case 100000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 41) }
        case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 42) }
        case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 43) }
        case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 44) }
        case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 45) }
        case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 46) }
        case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 47) }
        case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 48) }
        case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 49) }
        case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 50) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 51) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 52) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 53) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 54) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 55) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 56) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 57) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 58) }
        default {
            result := uMAX_SD59x18
        }
    }

    if (unwrap(result) == uMAX_SD59x18) {
        unchecked {
            // Do the fixed-point division inline to save gas.
            result = wrap((unwrap(log2(x)) * uUNIT) / uLOG2_10);
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
/// @param x The SD59x18 number for which to calculate the binary logarithm.
/// @return result The binary logarithm as an SD59x18 number.
function log2(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    if (xInt <= 0) {
        revert PRBMath_SD59x18_Log_InputTooSmall(x);
    }

    unchecked {
        // This works because of:
        //
        // $$
        // log_2{x} = -log_2{\frac{1}{x}}
        // $$
        int256 sign;
        if (xInt >= uUNIT) {
            sign = 1;
        } else {
            sign = -1;
            // Do the fixed-point inversion inline to save gas. The numerator is UNIT * UNIT.
            xInt = 1e36 / xInt;
        }

        // Calculate the integer part of the logarithm and add it to the result and finally calculate $y = x * 2^(-n)$.
        uint256 n = msb(uint256(xInt / uUNIT));

        // This is the integer part of the logarithm as an SD59x18 number. The operation can't overflow
        // because n is maximum 255, UNIT is 1e18 and sign is either 1 or -1.
        int256 resultInt = int256(n) * uUNIT;

        // This is $y = x * 2^{-n}$.
        int256 y = xInt >> n;

        // If y is 1, the fractional part is zero.
        if (y == uUNIT) {
            return wrap(resultInt * sign);
        }

        // Calculate the fractional part via the iterative approximation.
        // The "delta >>= 1" part is equivalent to "delta /= 2", but shifting bits is faster.
        int256 DOUBLE_UNIT = 2e18;
        for (int256 delta = uHALF_UNIT; delta > 0; delta >>= 1) {
            y = (y * y) / uUNIT;

            // Is $y^2 > 2$ and so in the range [2,4)?
            if (y >= DOUBLE_UNIT) {
                // Add the 2^{-m} factor to the logarithm.
                resultInt = resultInt + delta;

                // Corresponds to z/2 on Wikipedia.
                y >>= 1;
            }
        }
        resultInt *= sign;
        result = wrap(resultInt);
    }
}

/// @notice Multiplies two SD59x18 numbers together, returning a new SD59x18 number.
///
/// @dev This is a variant of `mulDiv` that works with signed numbers and employs constant folding, i.e. the denominator
/// is always 1e18.
///
/// Requirements:
/// - All from `Common.mulDiv18`.
/// - None of the inputs can be `MIN_SD59x18`.
/// - The result must fit within `MAX_SD59x18`.
///
/// Caveats:
/// - To understand how this works in detail, see the NatSpec comments in `Common.mulDivSigned`.
///
/// @param x The multiplicand as an SD59x18 number.
/// @param y The multiplier as an SD59x18 number.
/// @return result The product as an SD59x18 number.
function mul(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    int256 yInt = unwrap(y);
    if (xInt == uMIN_SD59x18 || yInt == uMIN_SD59x18) {
        revert PRBMath_SD59x18_Mul_InputTooSmall();
    }

    // Get hold of the absolute values of x and y.
    uint256 xAbs;
    uint256 yAbs;
    unchecked {
        xAbs = xInt < 0 ? uint256(-xInt) : uint256(xInt);
        yAbs = yInt < 0 ? uint256(-yInt) : uint256(yInt);
    }

    uint256 resultAbs = mulDiv18(xAbs, yAbs);
    if (resultAbs > uint256(uMAX_SD59x18)) {
        revert PRBMath_SD59x18_Mul_Overflow(x, y);
    }

    // Check if x and y have the same sign. This works thanks to two's complement; the left-most bit is the sign bit.
    bool sameSign = (xInt ^ yInt) > -1;

    // If the inputs have the same sign, the result should be negative. Otherwise, it should be positive.
    unchecked {
        result = wrap(sameSign ? int256(resultAbs) : -int256(resultAbs));
    }
}

/// @notice Raises x to the power of y.
///
/// @dev Based on the formula:
///
/// $$
/// x^y = 2^{log_2{x} * y}
/// $$
///
/// Requirements:
/// - All from `exp2`, `log2` and `mul`.
/// - x cannot be zero.
///
/// Caveats:
/// - All from `exp2`, `log2` and `mul`.
/// - Assumes 0^0 is 1.
///
/// @param x Number to raise to given power y, as an SD59x18 number.
/// @param y Exponent to raise x to, as an SD59x18 number
/// @return result x raised to power y, as an SD59x18 number.
function pow(SD59x18 x, SD59x18 y) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    int256 yInt = unwrap(y);

    if (xInt == 0) {
        result = yInt == 0 ? UNIT : ZERO;
    } else {
        if (yInt == uUNIT) {
            result = x;
        } else {
            result = exp2(mul(log2(x), y));
        }
    }
}

/// @notice Raises x (an SD59x18 number) to the power y (unsigned basic integer) using the famous algorithm
/// algorithm "exponentiation by squaring".
///
/// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
///
/// Requirements:
/// - All from `abs` and `Common.mulDiv18`.
/// - The result must fit within `MAX_SD59x18`.
///
/// Caveats:
/// - All from `Common.mulDiv18`.
/// - Assumes 0^0 is 1.
///
/// @param x The base as an SD59x18 number.
/// @param y The exponent as an uint256.
/// @return result The result as an SD59x18 number.
function powu(SD59x18 x, uint256 y) pure returns (SD59x18 result) {
    uint256 xAbs = uint256(unwrap(abs(x)));

    // Calculate the first iteration of the loop in advance.
    uint256 resultAbs = y & 1 > 0 ? xAbs : uint256(uUNIT);

    // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
    uint256 yAux = y;
    for (yAux >>= 1; yAux > 0; yAux >>= 1) {
        xAbs = mulDiv18(xAbs, xAbs);

        // Equivalent to "y % 2 == 1" but faster.
        if (yAux & 1 > 0) {
            resultAbs = mulDiv18(resultAbs, xAbs);
        }
    }

    // The result must fit within `MAX_SD59x18`.
    if (resultAbs > uint256(uMAX_SD59x18)) {
        revert PRBMath_SD59x18_Powu_Overflow(x, y);
    }

    unchecked {
        // Is the base negative and the exponent an odd number?
        int256 resultInt = int256(resultAbs);
        bool isNegative = unwrap(x) < 0 && y & 1 == 1;
        if (isNegative) {
            resultInt = -resultInt;
        }
        result = wrap(resultInt);
    }
}

/// @notice Calculates the square root of x, rounding down. Only the positive root is returned.
/// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
///
/// Requirements:
/// - x cannot be negative, since this library does not handle complex numbers.
/// - x must be less than `MAX_SD59x18` divided by `UNIT`.
///
/// @param x The SD59x18 number for which to calculate the square root.
/// @return result The result as an SD59x18 number.
function sqrt(SD59x18 x) pure returns (SD59x18 result) {
    int256 xInt = unwrap(x);
    if (xInt < 0) {
        revert PRBMath_SD59x18_Sqrt_NegativeInput(x);
    }
    if (xInt > uMAX_SD59x18 / uUNIT) {
        revert PRBMath_SD59x18_Sqrt_Overflow(x);
    }

    unchecked {
        // Multiply x by `UNIT` to account for the factor of `UNIT` that is picked up when multiplying two SD59x18
        // numbers together (in this case, the two numbers are both the square root).
        uint256 resultUint = prbSqrt(uint256(xInt * uUNIT));
        result = wrap(int256(resultUint));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./Casting.sol" as C;
import "./Helpers.sol" as H;
import "./Math.sol" as M;

/// @notice The signed 59.18-decimal fixed-point number representation, which can have up to 59 digits and up to 18 decimals.
/// The values of this are bound by the minimum and the maximum values permitted by the underlying Solidity type int256.
type SD59x18 is int256;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using {
    C.intoInt256,
    C.intoSD1x18,
    C.intoUD2x18,
    C.intoUD60x18,
    C.intoUint256,
    C.intoUint128,
    C.intoUint40,
    C.unwrap
} for SD59x18 global;

/*//////////////////////////////////////////////////////////////////////////
                            MATHEMATICAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    M.abs,
    M.avg,
    M.ceil,
    M.div,
    M.exp,
    M.exp2,
    M.floor,
    M.frac,
    M.gm,
    M.inv,
    M.log10,
    M.log2,
    M.ln,
    M.mul,
    M.pow,
    M.powu,
    M.sqrt
} for SD59x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

using {
    H.add,
    H.and,
    H.eq,
    H.gt,
    H.gte,
    H.isZero,
    H.lshift,
    H.lt,
    H.lte,
    H.mod,
    H.neq,
    H.or,
    H.rshift,
    H.sub,
    H.uncheckedAdd,
    H.uncheckedSub,
    H.uncheckedUnary,
    H.xor
} for SD59x18 global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { MAX_UINT40 } from "../Common.sol";
import { uMAX_SD1x18 } from "../sd1x18/Constants.sol";
import { SD1x18 } from "../sd1x18/ValueType.sol";
import { SD59x18 } from "../sd59x18/ValueType.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import { UD60x18 } from "../ud60x18/ValueType.sol";
import { PRBMath_UD2x18_IntoSD1x18_Overflow, PRBMath_UD2x18_IntoUint40_Overflow } from "./Errors.sol";
import { UD2x18 } from "./ValueType.sol";

/// @notice Casts an UD2x18 number into SD1x18.
/// - x must be less than or equal to `uMAX_SD1x18`.
function intoSD1x18(UD2x18 x) pure returns (SD1x18 result) {
    uint64 xUint = UD2x18.unwrap(x);
    if (xUint > uint64(uMAX_SD1x18)) {
        revert PRBMath_UD2x18_IntoSD1x18_Overflow(x);
    }
    result = SD1x18.wrap(int64(xUint));
}

/// @notice Casts an UD2x18 number into SD59x18.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of SD59x18.
function intoSD59x18(UD2x18 x) pure returns (SD59x18 result) {
    result = SD59x18.wrap(int256(uint256(UD2x18.unwrap(x))));
}

/// @notice Casts an UD2x18 number into UD60x18.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of UD60x18.
function intoUD60x18(UD2x18 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(UD2x18.unwrap(x));
}

/// @notice Casts an UD2x18 number into uint128.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of uint128.
function intoUint128(UD2x18 x) pure returns (uint128 result) {
    result = uint128(UD2x18.unwrap(x));
}

/// @notice Casts an UD2x18 number into uint256.
/// @dev There is no overflow check because the domain of UD2x18 is a subset of uint256.
function intoUint256(UD2x18 x) pure returns (uint256 result) {
    result = uint256(UD2x18.unwrap(x));
}

/// @notice Casts an UD2x18 number into uint40.
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(UD2x18 x) pure returns (uint40 result) {
    uint64 xUint = UD2x18.unwrap(x);
    if (xUint > uint64(MAX_UINT40)) {
        revert PRBMath_UD2x18_IntoUint40_Overflow(x);
    }
    result = uint40(xUint);
}

/// @notice Alias for the `wrap` function.
function ud2x18(uint64 x) pure returns (UD2x18 result) {
    result = wrap(x);
}

/// @notice Unwrap an UD2x18 number into uint64.
function unwrap(UD2x18 x) pure returns (uint64 result) {
    result = UD2x18.unwrap(x);
}

/// @notice Wraps an uint64 number into the UD2x18 value type.
function wrap(uint64 x) pure returns (UD2x18 result) {
    result = UD2x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { UD2x18 } from "./ValueType.sol";

/// @dev Euler's number as an UD2x18 number.
UD2x18 constant E = UD2x18.wrap(2_718281828459045235);

/// @dev The maximum value an UD2x18 number can have.
uint64 constant uMAX_UD2x18 = 18_446744073709551615;
UD2x18 constant MAX_UD2x18 = UD2x18.wrap(uMAX_UD2x18);

/// @dev PI as an UD2x18 number.
UD2x18 constant PI = UD2x18.wrap(3_141592653589793238);

/// @dev The unit amount that implies how many trailing decimals can be represented.
uint256 constant uUNIT = 1e18;
UD2x18 constant UNIT = UD2x18.wrap(1e18);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { UD2x18 } from "./ValueType.sol";

/// @notice Emitted when trying to cast a UD2x18 number that doesn't fit in SD1x18.
error PRBMath_UD2x18_IntoSD1x18_Overflow(UD2x18 x);

/// @notice Emitted when trying to cast a UD2x18 number that doesn't fit in uint40.
error PRBMath_UD2x18_IntoUint40_Overflow(UD2x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./Casting.sol" as C;

/// @notice The unsigned 2.18-decimal fixed-point number representation, which can have up to 2 digits and up to 18 decimals.
/// The values of this are bound by the minimum and the maximum values permitted by the underlying Solidity type uint64.
/// This is useful when end users want to use uint64 to save gas, e.g. with tight variable packing in contract storage.
type UD2x18 is uint64;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using { C.intoSD1x18, C.intoSD59x18, C.intoUD60x18, C.intoUint256, C.intoUint128, C.intoUint40, C.unwrap } for UD2x18 global;

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { MAX_UINT128, MAX_UINT40 } from "../Common.sol";
import { uMAX_SD1x18 } from "../sd1x18/Constants.sol";
import { SD1x18 } from "../sd1x18/ValueType.sol";
import { uMAX_SD59x18 } from "../sd59x18/Constants.sol";
import { SD59x18 } from "../sd59x18/ValueType.sol";
import { uMAX_UD2x18 } from "../ud2x18/Constants.sol";
import { UD2x18 } from "../ud2x18/ValueType.sol";
import {
    PRBMath_UD60x18_IntoSD1x18_Overflow,
    PRBMath_UD60x18_IntoUD2x18_Overflow,
    PRBMath_UD60x18_IntoSD59x18_Overflow,
    PRBMath_UD60x18_IntoUint128_Overflow,
    PRBMath_UD60x18_IntoUint40_Overflow
} from "./Errors.sol";
import { UD60x18 } from "./ValueType.sol";

/// @notice Casts an UD60x18 number into SD1x18.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_SD1x18`.
function intoSD1x18(UD60x18 x) pure returns (SD1x18 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > uint256(int256(uMAX_SD1x18))) {
        revert PRBMath_UD60x18_IntoSD1x18_Overflow(x);
    }
    result = SD1x18.wrap(int64(uint64(xUint)));
}

/// @notice Casts an UD60x18 number into UD2x18.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_UD2x18`.
function intoUD2x18(UD60x18 x) pure returns (UD2x18 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > uMAX_UD2x18) {
        revert PRBMath_UD60x18_IntoUD2x18_Overflow(x);
    }
    result = UD2x18.wrap(uint64(xUint));
}

/// @notice Casts an UD60x18 number into SD59x18.
/// @dev Requirements:
/// - x must be less than or equal to `uMAX_SD59x18`.
function intoSD59x18(UD60x18 x) pure returns (SD59x18 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > uint256(uMAX_SD59x18)) {
        revert PRBMath_UD60x18_IntoSD59x18_Overflow(x);
    }
    result = SD59x18.wrap(int256(xUint));
}

/// @notice Casts an UD60x18 number into uint128.
/// @dev This is basically a functional alias for the `unwrap` function.
function intoUint256(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x);
}

/// @notice Casts an UD60x18 number into uint128.
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UINT128`.
function intoUint128(UD60x18 x) pure returns (uint128 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > MAX_UINT128) {
        revert PRBMath_UD60x18_IntoUint128_Overflow(x);
    }
    result = uint128(xUint);
}

/// @notice Casts an UD60x18 number into uint40.
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UINT40`.
function intoUint40(UD60x18 x) pure returns (uint40 result) {
    uint256 xUint = UD60x18.unwrap(x);
    if (xUint > MAX_UINT40) {
        revert PRBMath_UD60x18_IntoUint40_Overflow(x);
    }
    result = uint40(xUint);
}

/// @notice Alias for the `wrap` function.
function ud(uint256 x) pure returns (UD60x18 result) {
    result = wrap(x);
}

/// @notice Alias for the `wrap` function.
function ud60x18(uint256 x) pure returns (UD60x18 result) {
    result = wrap(x);
}

/// @notice Unwraps an UD60x18 number into uint256.
function unwrap(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x);
}

/// @notice Wraps an uint256 number into the UD60x18 value type.
function wrap(uint256 x) pure returns (UD60x18 result) {
    result = UD60x18.wrap(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { UD60x18 } from "./ValueType.sol";

/// @dev Euler's number as an UD60x18 number.
UD60x18 constant E = UD60x18.wrap(2_718281828459045235);

/// @dev Half the UNIT number.
uint256 constant uHALF_UNIT = 0.5e18;
UD60x18 constant HALF_UNIT = UD60x18.wrap(uHALF_UNIT);

/// @dev log2(10) as an UD60x18 number.
uint256 constant uLOG2_10 = 3_321928094887362347;
UD60x18 constant LOG2_10 = UD60x18.wrap(uLOG2_10);

/// @dev log2(e) as an UD60x18 number.
uint256 constant uLOG2_E = 1_442695040888963407;
UD60x18 constant LOG2_E = UD60x18.wrap(uLOG2_E);

/// @dev The maximum value an UD60x18 number can have.
uint256 constant uMAX_UD60x18 = 115792089237316195423570985008687907853269984665640564039457_584007913129639935;
UD60x18 constant MAX_UD60x18 = UD60x18.wrap(uMAX_UD60x18);

/// @dev The maximum whole value an UD60x18 number can have.
uint256 constant uMAX_WHOLE_UD60x18 = 115792089237316195423570985008687907853269984665640564039457_000000000000000000;
UD60x18 constant MAX_WHOLE_UD60x18 = UD60x18.wrap(uMAX_WHOLE_UD60x18);

/// @dev PI as an UD60x18 number.
UD60x18 constant PI = UD60x18.wrap(3_141592653589793238);

/// @dev The unit amount that implies how many trailing decimals can be represented.
uint256 constant uUNIT = 1e18;
UD60x18 constant UNIT = UD60x18.wrap(uUNIT);

/// @dev Zero as an UD60x18 number.
UD60x18 constant ZERO = UD60x18.wrap(0);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { uMAX_UD60x18, uUNIT } from "./Constants.sol";
import { PRBMath_UD60x18_Convert_Overflow } from "./Errors.sol";
import { UD60x18 } from "./ValueType.sol";

/// @notice Converts an UD60x18 number to a simple integer by dividing it by `UNIT`. Rounds towards zero in the process.
/// @dev Rounds down in the process.
/// @param x The UD60x18 number to convert.
/// @return result The same number in basic integer form.
function convert(UD60x18 x) pure returns (uint256 result) {
    result = UD60x18.unwrap(x) / uUNIT;
}

/// @notice Converts a simple integer to UD60x18 by multiplying it by `UNIT`.
///
/// @dev Requirements:
/// - x must be less than or equal to `MAX_UD60x18` divided by `UNIT`.
///
/// @param x The basic integer to convert.
/// @param result The same number converted to UD60x18.
function convert(uint256 x) pure returns (UD60x18 result) {
    if (x > uMAX_UD60x18 / uUNIT) {
        revert PRBMath_UD60x18_Convert_Overflow(x);
    }
    unchecked {
        result = UD60x18.wrap(x * uUNIT);
    }
}

/// @notice Alias for the `convert` function defined above.
/// @dev Here for backward compatibility. Will be removed in V4.
function fromUD60x18(UD60x18 x) pure returns (uint256 result) {
    result = convert(x);
}

/// @notice Alias for the `convert` function defined above.
/// @dev Here for backward compatibility. Will be removed in V4.
function toUD60x18(uint256 x) pure returns (UD60x18 result) {
    result = convert(x);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { UD60x18 } from "./ValueType.sol";

/// @notice Emitted when ceiling a number overflows UD60x18.
error PRBMath_UD60x18_Ceil_Overflow(UD60x18 x);

/// @notice Emitted when converting a basic integer to the fixed-point format overflows UD60x18.
error PRBMath_UD60x18_Convert_Overflow(uint256 x);

/// @notice Emitted when taking the natural exponent of a base greater than 133.084258667509499441.
error PRBMath_UD60x18_Exp_InputTooBig(UD60x18 x);

/// @notice Emitted when taking the binary exponent of a base greater than 192.
error PRBMath_UD60x18_Exp2_InputTooBig(UD60x18 x);

/// @notice Emitted when taking the geometric mean of two numbers and multiplying them overflows UD60x18.
error PRBMath_UD60x18_Gm_Overflow(UD60x18 x, UD60x18 y);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in SD1x18.
error PRBMath_UD60x18_IntoSD1x18_Overflow(UD60x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in SD59x18.
error PRBMath_UD60x18_IntoSD59x18_Overflow(UD60x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in UD2x18.
error PRBMath_UD60x18_IntoUD2x18_Overflow(UD60x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in uint128.
error PRBMath_UD60x18_IntoUint128_Overflow(UD60x18 x);

/// @notice Emitted when trying to cast an UD60x18 number that doesn't fit in uint40.
error PRBMath_UD60x18_IntoUint40_Overflow(UD60x18 x);

/// @notice Emitted when taking the logarithm of a number less than 1.
error PRBMath_UD60x18_Log_InputTooSmall(UD60x18 x);

/// @notice Emitted when calculating the square root overflows UD60x18.
error PRBMath_UD60x18_Sqrt_Overflow(UD60x18 x);

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { unwrap, wrap } from "./Casting.sol";
import { UD60x18 } from "./ValueType.sol";

/// @notice Implements the checked addition operation (+) in the UD60x18 type.
function add(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) + unwrap(y));
}

/// @notice Implements the AND (&) bitwise operation in the UD60x18 type.
function and(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) & bits);
}

/// @notice Implements the equal operation (==) in the UD60x18 type.
function eq(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = unwrap(x) == unwrap(y);
}

/// @notice Implements the greater than operation (>) in the UD60x18 type.
function gt(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = unwrap(x) > unwrap(y);
}

/// @notice Implements the greater than or equal to operation (>=) in the UD60x18 type.
function gte(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = unwrap(x) >= unwrap(y);
}

/// @notice Implements a zero comparison check function in the UD60x18 type.
function isZero(UD60x18 x) pure returns (bool result) {
    // This wouldn't work if x could be negative.
    result = unwrap(x) == 0;
}

/// @notice Implements the left shift operation (<<) in the UD60x18 type.
function lshift(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) << bits);
}

/// @notice Implements the lower than operation (<) in the UD60x18 type.
function lt(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = unwrap(x) < unwrap(y);
}

/// @notice Implements the lower than or equal to operation (<=) in the UD60x18 type.
function lte(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = unwrap(x) <= unwrap(y);
}

/// @notice Implements the checked modulo operation (%) in the UD60x18 type.
function mod(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) % unwrap(y));
}

/// @notice Implements the not equal operation (!=) in the UD60x18 type
function neq(UD60x18 x, UD60x18 y) pure returns (bool result) {
    result = unwrap(x) != unwrap(y);
}

/// @notice Implements the OR (|) bitwise operation in the UD60x18 type.
function or(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) | unwrap(y));
}

/// @notice Implements the right shift operation (>>) in the UD60x18 type.
function rshift(UD60x18 x, uint256 bits) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) >> bits);
}

/// @notice Implements the checked subtraction operation (-) in the UD60x18 type.
function sub(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) - unwrap(y));
}

/// @notice Implements the unchecked addition operation (+) in the UD60x18 type.
function uncheckedAdd(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(unwrap(x) + unwrap(y));
    }
}

/// @notice Implements the unchecked subtraction operation (-) in the UD60x18 type.
function uncheckedSub(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    unchecked {
        result = wrap(unwrap(x) - unwrap(y));
    }
}

/// @notice Implements the XOR (^) bitwise operation in the UD60x18 type.
function xor(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(unwrap(x) ^ unwrap(y));
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { msb, mulDiv, mulDiv18, prbExp2, prbSqrt } from "../Common.sol";
import { unwrap, wrap } from "./Casting.sol";
import { uHALF_UNIT, uLOG2_10, uLOG2_E, uMAX_UD60x18, uMAX_WHOLE_UD60x18, UNIT, uUNIT, ZERO } from "./Constants.sol";
import {
    PRBMath_UD60x18_Ceil_Overflow,
    PRBMath_UD60x18_Exp_InputTooBig,
    PRBMath_UD60x18_Exp2_InputTooBig,
    PRBMath_UD60x18_Gm_Overflow,
    PRBMath_UD60x18_Log_InputTooSmall,
    PRBMath_UD60x18_Sqrt_Overflow
} from "./Errors.sol";
import { UD60x18 } from "./ValueType.sol";

/*//////////////////////////////////////////////////////////////////////////
                            MATHEMATICAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// @notice Calculates the arithmetic average of x and y, rounding down.
///
/// @dev Based on the formula:
///
/// $$
/// avg(x, y) = (x & y) + ((xUint ^ yUint) / 2)
/// $$
//
/// In English, what this formula does is:
///
/// 1. AND x and y.
/// 2. Calculate half of XOR x and y.
/// 3. Add the two results together.
///
/// This technique is known as SWAR, which stands for "SIMD within a register". You can read more about it here:
/// https://devblogs.microsoft.com/oldnewthing/20220207-00/?p=106223
///
/// @param x The first operand as an UD60x18 number.
/// @param y The second operand as an UD60x18 number.
/// @return result The arithmetic average as an UD60x18 number.
function avg(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);
    uint256 yUint = unwrap(y);
    unchecked {
        result = wrap((xUint & yUint) + ((xUint ^ yUint) >> 1));
    }
}

/// @notice Yields the smallest whole UD60x18 number greater than or equal to x.
///
/// @dev This is optimized for fractional value inputs, because for every whole value there are "1e18 - 1" fractional
/// counterparts. See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
///
/// Requirements:
/// - x must be less than or equal to `MAX_WHOLE_UD60x18`.
///
/// @param x The UD60x18 number to ceil.
/// @param result The least number greater than or equal to x, as an UD60x18 number.
function ceil(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);
    if (xUint > uMAX_WHOLE_UD60x18) {
        revert PRBMath_UD60x18_Ceil_Overflow(x);
    }

    assembly ("memory-safe") {
        // Equivalent to "x % UNIT" but faster.
        let remainder := mod(x, uUNIT)

        // Equivalent to "UNIT - remainder" but faster.
        let delta := sub(uUNIT, remainder)

        // Equivalent to "x + delta * (remainder > 0 ? 1 : 0)" but faster.
        result := add(x, mul(delta, gt(remainder, 0)))
    }
}

/// @notice Divides two UD60x18 numbers, returning a new UD60x18 number. Rounds towards zero.
///
/// @dev Uses `mulDiv` to enable overflow-safe multiplication and division.
///
/// Requirements:
/// - The denominator cannot be zero.
///
/// @param x The numerator as an UD60x18 number.
/// @param y The denominator as an UD60x18 number.
/// @param result The quotient as an UD60x18 number.
function div(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(mulDiv(unwrap(x), uUNIT, unwrap(y)));
}

/// @notice Calculates the natural exponent of x.
///
/// @dev Based on the formula:
///
/// $$
/// e^x = 2^{x * log_2{e}}
/// $$
///
/// Requirements:
/// - All from `log2`.
/// - x must be less than 133.084258667509499441.
///
/// @param x The exponent as an UD60x18 number.
/// @return result The result as an UD60x18 number.
function exp(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);

    // Without this check, the value passed to `exp2` would be greater than 192.
    if (xUint >= 133_084258667509499441) {
        revert PRBMath_UD60x18_Exp_InputTooBig(x);
    }

    unchecked {
        // We do the fixed-point multiplication inline rather than via the `mul` function to save gas.
        uint256 doubleUnitProduct = xUint * uLOG2_E;
        result = exp2(wrap(doubleUnitProduct / uUNIT));
    }
}

/// @notice Calculates the binary exponent of x using the binary fraction method.
///
/// @dev See https://ethereum.stackexchange.com/q/79903/24693.
///
/// Requirements:
/// - x must be 192 or less.
/// - The result must fit within `MAX_UD60x18`.
///
/// @param x The exponent as an UD60x18 number.
/// @return result The result as an UD60x18 number.
function exp2(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);

    // Numbers greater than or equal to 2^192 don't fit within the 192.64-bit format.
    if (xUint >= 192e18) {
        revert PRBMath_UD60x18_Exp2_InputTooBig(x);
    }

    // Convert x to the 192.64-bit fixed-point format.
    uint256 x_192x64 = (xUint << 64) / uUNIT;

    // Pass x to the `prbExp2` function, which uses the 192.64-bit fixed-point number representation.
    result = wrap(prbExp2(x_192x64));
}

/// @notice Yields the greatest whole UD60x18 number less than or equal to x.
/// @dev Optimized for fractional value inputs, because for every whole value there are (1e18 - 1) fractional counterparts.
/// See https://en.wikipedia.org/wiki/Floor_and_ceiling_functions.
/// @param x The UD60x18 number to floor.
/// @param result The greatest integer less than or equal to x, as an UD60x18 number.
function floor(UD60x18 x) pure returns (UD60x18 result) {
    assembly ("memory-safe") {
        // Equivalent to "x % UNIT" but faster.
        let remainder := mod(x, uUNIT)

        // Equivalent to "x - remainder * (remainder > 0 ? 1 : 0)" but faster.
        result := sub(x, mul(remainder, gt(remainder, 0)))
    }
}

/// @notice Yields the excess beyond the floor of x.
/// @dev Based on the odd function definition https://en.wikipedia.org/wiki/Fractional_part.
/// @param x The UD60x18 number to get the fractional part of.
/// @param result The fractional part of x as an UD60x18 number.
function frac(UD60x18 x) pure returns (UD60x18 result) {
    assembly ("memory-safe") {
        result := mod(x, uUNIT)
    }
}

/// @notice Calculates the geometric mean of x and y, i.e. $$sqrt(x * y)$$, rounding down.
///
/// @dev Requirements:
/// - x * y must fit within `MAX_UD60x18`, lest it overflows.
///
/// @param x The first operand as an UD60x18 number.
/// @param y The second operand as an UD60x18 number.
/// @return result The result as an UD60x18 number.
function gm(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);
    uint256 yUint = unwrap(y);
    if (xUint == 0 || yUint == 0) {
        return ZERO;
    }

    unchecked {
        // Checking for overflow this way is faster than letting Solidity do it.
        uint256 xyUint = xUint * yUint;
        if (xyUint / xUint != yUint) {
            revert PRBMath_UD60x18_Gm_Overflow(x, y);
        }

        // We don't need to multiply the result by `UNIT` here because the x*y product had picked up a factor of `UNIT`
        // during multiplication. See the comments in the `prbSqrt` function.
        result = wrap(prbSqrt(xyUint));
    }
}

/// @notice Calculates 1 / x, rounding toward zero.
///
/// @dev Requirements:
/// - x cannot be zero.
///
/// @param x The UD60x18 number for which to calculate the inverse.
/// @return result The inverse as an UD60x18 number.
function inv(UD60x18 x) pure returns (UD60x18 result) {
    unchecked {
        // 1e36 is UNIT * UNIT.
        result = wrap(1e36 / unwrap(x));
    }
}

/// @notice Calculates the natural logarithm of x.
///
/// @dev Based on the formula:
///
/// $$
/// ln{x} = log_2{x} / log_2{e}$$.
/// $$
///
/// Requirements:
/// - All from `log2`.
///
/// Caveats:
/// - All from `log2`.
/// - This doesn't return exactly 1 for 2.718281828459045235, for that more fine-grained precision is needed.
///
/// @param x The UD60x18 number for which to calculate the natural logarithm.
/// @return result The natural logarithm as an UD60x18 number.
function ln(UD60x18 x) pure returns (UD60x18 result) {
    unchecked {
        // We do the fixed-point multiplication inline to save gas. This is overflow-safe because the maximum value
        // that `log2` can return is 196.205294292027477728.
        result = wrap((unwrap(log2(x)) * uUNIT) / uLOG2_E);
    }
}

/// @notice Calculates the common logarithm of x.
///
/// @dev First checks if x is an exact power of ten and it stops if yes. If it's not, calculates the common
/// logarithm based on the formula:
///
/// $$
/// log_{10}{x} = log_2{x} / log_2{10}
/// $$
///
/// Requirements:
/// - All from `log2`.
///
/// Caveats:
/// - All from `log2`.
///
/// @param x The UD60x18 number for which to calculate the common logarithm.
/// @return result The common logarithm as an UD60x18 number.
function log10(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);
    if (xUint < uUNIT) {
        revert PRBMath_UD60x18_Log_InputTooSmall(x);
    }

    // Note that the `mul` in this assembly block is the assembly multiplication operation, not the UD60x18 `mul`.
    // prettier-ignore
    assembly ("memory-safe") {
        switch x
        case 1 { result := mul(uUNIT, sub(0, 18)) }
        case 10 { result := mul(uUNIT, sub(1, 18)) }
        case 100 { result := mul(uUNIT, sub(2, 18)) }
        case 1000 { result := mul(uUNIT, sub(3, 18)) }
        case 10000 { result := mul(uUNIT, sub(4, 18)) }
        case 100000 { result := mul(uUNIT, sub(5, 18)) }
        case 1000000 { result := mul(uUNIT, sub(6, 18)) }
        case 10000000 { result := mul(uUNIT, sub(7, 18)) }
        case 100000000 { result := mul(uUNIT, sub(8, 18)) }
        case 1000000000 { result := mul(uUNIT, sub(9, 18)) }
        case 10000000000 { result := mul(uUNIT, sub(10, 18)) }
        case 100000000000 { result := mul(uUNIT, sub(11, 18)) }
        case 1000000000000 { result := mul(uUNIT, sub(12, 18)) }
        case 10000000000000 { result := mul(uUNIT, sub(13, 18)) }
        case 100000000000000 { result := mul(uUNIT, sub(14, 18)) }
        case 1000000000000000 { result := mul(uUNIT, sub(15, 18)) }
        case 10000000000000000 { result := mul(uUNIT, sub(16, 18)) }
        case 100000000000000000 { result := mul(uUNIT, sub(17, 18)) }
        case 1000000000000000000 { result := 0 }
        case 10000000000000000000 { result := uUNIT }
        case 100000000000000000000 { result := mul(uUNIT, 2) }
        case 1000000000000000000000 { result := mul(uUNIT, 3) }
        case 10000000000000000000000 { result := mul(uUNIT, 4) }
        case 100000000000000000000000 { result := mul(uUNIT, 5) }
        case 1000000000000000000000000 { result := mul(uUNIT, 6) }
        case 10000000000000000000000000 { result := mul(uUNIT, 7) }
        case 100000000000000000000000000 { result := mul(uUNIT, 8) }
        case 1000000000000000000000000000 { result := mul(uUNIT, 9) }
        case 10000000000000000000000000000 { result := mul(uUNIT, 10) }
        case 100000000000000000000000000000 { result := mul(uUNIT, 11) }
        case 1000000000000000000000000000000 { result := mul(uUNIT, 12) }
        case 10000000000000000000000000000000 { result := mul(uUNIT, 13) }
        case 100000000000000000000000000000000 { result := mul(uUNIT, 14) }
        case 1000000000000000000000000000000000 { result := mul(uUNIT, 15) }
        case 10000000000000000000000000000000000 { result := mul(uUNIT, 16) }
        case 100000000000000000000000000000000000 { result := mul(uUNIT, 17) }
        case 1000000000000000000000000000000000000 { result := mul(uUNIT, 18) }
        case 10000000000000000000000000000000000000 { result := mul(uUNIT, 19) }
        case 100000000000000000000000000000000000000 { result := mul(uUNIT, 20) }
        case 1000000000000000000000000000000000000000 { result := mul(uUNIT, 21) }
        case 10000000000000000000000000000000000000000 { result := mul(uUNIT, 22) }
        case 100000000000000000000000000000000000000000 { result := mul(uUNIT, 23) }
        case 1000000000000000000000000000000000000000000 { result := mul(uUNIT, 24) }
        case 10000000000000000000000000000000000000000000 { result := mul(uUNIT, 25) }
        case 100000000000000000000000000000000000000000000 { result := mul(uUNIT, 26) }
        case 1000000000000000000000000000000000000000000000 { result := mul(uUNIT, 27) }
        case 10000000000000000000000000000000000000000000000 { result := mul(uUNIT, 28) }
        case 100000000000000000000000000000000000000000000000 { result := mul(uUNIT, 29) }
        case 1000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 30) }
        case 10000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 31) }
        case 100000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 32) }
        case 1000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 33) }
        case 10000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 34) }
        case 100000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 35) }
        case 1000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 36) }
        case 10000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 37) }
        case 100000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 38) }
        case 1000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 39) }
        case 10000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 40) }
        case 100000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 41) }
        case 1000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 42) }
        case 10000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 43) }
        case 100000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 44) }
        case 1000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 45) }
        case 10000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 46) }
        case 100000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 47) }
        case 1000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 48) }
        case 10000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 49) }
        case 100000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 50) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 51) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 52) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 53) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 54) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 55) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 56) }
        case 1000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 57) }
        case 10000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 58) }
        case 100000000000000000000000000000000000000000000000000000000000000000000000000000 { result := mul(uUNIT, 59) }
        default {
            result := uMAX_UD60x18
        }
    }

    if (unwrap(result) == uMAX_UD60x18) {
        unchecked {
            // Do the fixed-point division inline to save gas.
            result = wrap((unwrap(log2(x)) * uUNIT) / uLOG2_10);
        }
    }
}

/// @notice Calculates the binary logarithm of x.
///
/// @dev Based on the iterative approximation algorithm.
/// https://en.wikipedia.org/wiki/Binary_logarithm#Iterative_approximation
///
/// Requirements:
/// - x must be greater than or equal to UNIT, otherwise the result would be negative.
///
/// Caveats:
/// - The results are nor perfectly accurate to the last decimal, due to the lossy precision of the iterative approximation.
///
/// @param x The UD60x18 number for which to calculate the binary logarithm.
/// @return result The binary logarithm as an UD60x18 number.
function log2(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);

    if (xUint < uUNIT) {
        revert PRBMath_UD60x18_Log_InputTooSmall(x);
    }

    unchecked {
        // Calculate the integer part of the logarithm, add it to the result and finally calculate y = x * 2^(-n).
        uint256 n = msb(xUint / uUNIT);

        // This is the integer part of the logarithm as an UD60x18 number. The operation can't overflow because n
        // n is maximum 255 and UNIT is 1e18.
        uint256 resultUint = n * uUNIT;

        // This is $y = x * 2^{-n}$.
        uint256 y = xUint >> n;

        // If y is 1, the fractional part is zero.
        if (y == uUNIT) {
            return wrap(resultUint);
        }

        // Calculate the fractional part via the iterative approximation.
        // The "delta.rshift(1)" part is equivalent to "delta /= 2", but shifting bits is faster.
        uint256 DOUBLE_UNIT = 2e18;
        for (uint256 delta = uHALF_UNIT; delta > 0; delta >>= 1) {
            y = (y * y) / uUNIT;

            // Is y^2 > 2 and so in the range [2,4)?
            if (y >= DOUBLE_UNIT) {
                // Add the 2^{-m} factor to the logarithm.
                resultUint += delta;

                // Corresponds to z/2 on Wikipedia.
                y >>= 1;
            }
        }
        result = wrap(resultUint);
    }
}

/// @notice Multiplies two UD60x18 numbers together, returning a new UD60x18 number.
/// @dev See the documentation for the `Common.mulDiv18` function.
/// @param x The multiplicand as an UD60x18 number.
/// @param y The multiplier as an UD60x18 number.
/// @return result The product as an UD60x18 number.
function mul(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    result = wrap(mulDiv18(unwrap(x), unwrap(y)));
}

/// @notice Raises x to the power of y.
///
/// @dev Based on the formula:
///
/// $$
/// x^y = 2^{log_2{x} * y}
/// $$
///
/// Requirements:
/// - All from `exp2`, `log2` and `mul`.
///
/// Caveats:
/// - All from `exp2`, `log2` and `mul`.
/// - Assumes 0^0 is 1.
///
/// @param x Number to raise to given power y, as an UD60x18 number.
/// @param y Exponent to raise x to, as an UD60x18 number.
/// @return result x raised to power y, as an UD60x18 number.
function pow(UD60x18 x, UD60x18 y) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);
    uint256 yUint = unwrap(y);

    if (xUint == 0) {
        result = yUint == 0 ? UNIT : ZERO;
    } else {
        if (yUint == uUNIT) {
            result = x;
        } else {
            result = exp2(mul(log2(x), y));
        }
    }
}

/// @notice Raises x (an UD60x18 number) to the power y (unsigned basic integer) using the famous algorithm
/// "exponentiation by squaring".
///
/// @dev See https://en.wikipedia.org/wiki/Exponentiation_by_squaring
///
/// Requirements:
/// - The result must fit within `MAX_UD60x18`.
///
/// Caveats:
/// - All from "Common.mulDiv18".
/// - Assumes 0^0 is 1.
///
/// @param x The base as an UD60x18 number.
/// @param y The exponent as an uint256.
/// @return result The result as an UD60x18 number.
function powu(UD60x18 x, uint256 y) pure returns (UD60x18 result) {
    // Calculate the first iteration of the loop in advance.
    uint256 xUint = unwrap(x);
    uint256 resultUint = y & 1 > 0 ? xUint : uUNIT;

    // Equivalent to "for(y /= 2; y > 0; y /= 2)" but faster.
    for (y >>= 1; y > 0; y >>= 1) {
        xUint = mulDiv18(xUint, xUint);

        // Equivalent to "y % 2 == 1" but faster.
        if (y & 1 > 0) {
            resultUint = mulDiv18(resultUint, xUint);
        }
    }
    result = wrap(resultUint);
}

/// @notice Calculates the square root of x, rounding down.
/// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
///
/// Requirements:
/// - x must be less than `MAX_UD60x18` divided by `UNIT`.
///
/// @param x The UD60x18 number for which to calculate the square root.
/// @return result The result as an UD60x18 number.
function sqrt(UD60x18 x) pure returns (UD60x18 result) {
    uint256 xUint = unwrap(x);

    unchecked {
        if (xUint > uMAX_UD60x18 / uUNIT) {
            revert PRBMath_UD60x18_Sqrt_Overflow(x);
        }
        // Multiply x by `UNIT` to account for the factor of `UNIT` that is picked up when multiplying two UD60x18
        // numbers together (in this case, the two numbers are both the square root).
        result = wrap(prbSqrt(xUint * uUNIT));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import "./Casting.sol" as C;
import "./Helpers.sol" as H;
import "./Math.sol" as M;

/// @notice The unsigned 60.18-decimal fixed-point number representation, which can have up to 60 digits and up to 18 decimals.
/// The values of this are bound by the minimum and the maximum values permitted by the Solidity type uint256.
/// @dev The value type is defined here so it can be imported in all other files.
type UD60x18 is uint256;

/*//////////////////////////////////////////////////////////////////////////
                                    CASTING
//////////////////////////////////////////////////////////////////////////*/

using { C.intoSD1x18, C.intoUD2x18, C.intoSD59x18, C.intoUint128, C.intoUint256, C.intoUint40, C.unwrap } for UD60x18 global;

/*//////////////////////////////////////////////////////////////////////////
                            MATHEMATICAL FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// The global "using for" directive makes the functions in this library callable on the UD60x18 type.
using {
    M.avg,
    M.ceil,
    M.div,
    M.exp,
    M.exp2,
    M.floor,
    M.frac,
    M.gm,
    M.inv,
    M.ln,
    M.log10,
    M.log2,
    M.mul,
    M.pow,
    M.powu,
    M.sqrt
} for UD60x18 global;

/*//////////////////////////////////////////////////////////////////////////
                                HELPER FUNCTIONS
//////////////////////////////////////////////////////////////////////////*/

/// The global "using for" directive makes the functions in this library callable on the UD60x18 type.
using {
    H.add,
    H.and,
    H.eq,
    H.gt,
    H.gte,
    H.isZero,
    H.lshift,
    H.lt,
    H.lte,
    H.mod,
    H.neq,
    H.or,
    H.rshift,
    H.sub,
    H.uncheckedAdd,
    H.uncheckedSub,
    H.xor
} for UD60x18 global;

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import { UD60x18, UNIT } from "@prb-math/UD60x18.sol";
import "@prb-math/SD59x18.sol" as SD59x18;
import { TokenInfo } from "./structs/TokenInfo.sol";
import { Stewardable } from "./utils/Stewardable.sol";

contract Registra is Stewardable {
    address private s_bookkeeper;
    address private s_pud;
    address private s_treasurer;
    UD60x18 private s_interestRate = UNIT; // avoid to get zero ratio
    UD60x18 private s_penaltyRate;
    mapping(address => TokenInfo) private s_tokenInfos;

    modifier requireZeroAddress(address address_) {
        require(address_ == address(0), "Registra: require zero address");
        _;
    }

    constructor(address steward) Stewardable(steward) { }

    function setBookkeeper(address bookkeeper) external requireZeroAddress(s_bookkeeper) {
        s_bookkeeper = bookkeeper;
    }

    function setPud(address pud) external requireZeroAddress(s_pud) {
        s_pud = pud;
    }

    function setTreasurer(address treasurer) external requireZeroAddress(s_treasurer) {
        s_treasurer = treasurer;
    }

    function setInterestRate(SD59x18.SD59x18 interestRate) external requireSteward {
        SD59x18.SD59x18 multipler = SD59x18.UNIT.add(interestRate);
        s_interestRate = SD59x18.intoUD60x18(multipler);
    }

    function setPenaltyRate(UD60x18 penaltyRate) external requireSteward {
        s_penaltyRate = penaltyRate;
    }

    function setTokenInfo(address token, TokenInfo calldata tokenInfo) external requireSteward {
        s_tokenInfos[token] = tokenInfo;
    }

    function getBookkeeper() external view returns (address bookkeeper) {
        bookkeeper = s_bookkeeper;
    }

    function getPud() external view returns (address pud) {
        pud = s_pud;
    }

    function getTreasurer() external view returns (address treasurer) {
        treasurer = s_treasurer;
    }

    function getInterestRate() external view returns (UD60x18 interestRate) {
        interestRate = s_interestRate;
    }

    function getPenaltyRate() external view returns (UD60x18 penaltyRate) {
        penaltyRate = s_penaltyRate;
    }

    function tokenInfoOf(address token) external view returns (TokenInfo memory tokenInfo) {
        tokenInfo = s_tokenInfos[token];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

import {UD60x18} from "@prb-math/UD60x18.sol";
import "./TokenType.sol";

struct TokenInfo {
    bool enabled;
    TokenType type_;
    address priceOracle;
    UD60x18 liquidationRatio;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

enum TokenType {
    Unknown,
    ERC20,
    ERC721
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

contract Stewardable {
    address private s_steward;
    address private s_successor;

    modifier requireSteward() {
        require(msg.sender == s_steward, "Require steward");
        _;
    }

    modifier requireSuccessor() {
        require(msg.sender == s_successor, "Require successor");
        _;
    }

    constructor(address steward) {
        s_steward = steward;
    }

    function getSteward() external view returns (address) {
        return s_steward;
    }

    function succeedSteward() external requireSuccessor {
        s_steward = s_successor;
        s_successor = address(0);
    }

    function appointSuccessor(address successor) external requireSteward {
        s_successor = successor;
    }
}