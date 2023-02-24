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

import "./ud60x18/Casting.sol";
import "./ud60x18/Constants.sol";
import "./ud60x18/Conversions.sol";
import "./ud60x18/Errors.sol";
import "./ud60x18/Helpers.sol";
import "./ud60x18/Math.sol";
import "./ud60x18/ValueType.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @dev DonatorBlacklist interface.
interface IDonatorBlacklist {
    /// @dev Gets account blacklisting status.
    /// @param account Account address.
    /// @return status Blacklisting status.
    function isDonatorBlacklisted(address account) external view returns (bool status);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @dev Errors.
interface IErrorsTokenomics {
    /// @dev Only `manager` has a privilege, but the `sender` was provided.
    /// @param sender Sender address.
    /// @param manager Required sender address as a manager.
    error ManagerOnly(address sender, address manager);

    /// @dev Only `owner` has a privilege, but the `sender` was provided.
    /// @param sender Sender address.
    /// @param owner Required sender address as an owner.
    error OwnerOnly(address sender, address owner);

    /// @dev Provided zero address.
    error ZeroAddress();

    /// @dev Wrong length of two arrays.
    /// @param numValues1 Number of values in a first array.
    /// @param numValues2 Number of values in a second array.
    error WrongArrayLength(uint256 numValues1, uint256 numValues2);

    /// @dev Service Id does not exist in registry records.
    /// @param serviceId Service Id.
    error ServiceDoesNotExist(uint256 serviceId);

    /// @dev Zero value when it has to be different from zero.
    error ZeroValue();

    /// @dev Non-zero value when it has to be zero.
    error NonZeroValue();

    /// @dev Value overflow.
    /// @param provided Overflow value.
    /// @param max Maximum possible value.
    error Overflow(uint256 provided, uint256 max);

    /// @dev Service was never deployed.
    /// @param serviceId Service Id.
    error ServiceNeverDeployed(uint256 serviceId);

    /// @dev Token is disabled or not whitelisted.
    /// @param tokenAddress Address of a token.
    error UnauthorizedToken(address tokenAddress);

    /// @dev Provided token address is incorrect.
    /// @param provided Provided token address.
    /// @param expected Expected token address.
    error WrongTokenAddress(address provided, address expected);

    /// @dev Bond is not redeemable (does not exist or not matured).
    /// @param bondId Bond Id.
    error BondNotRedeemable(uint256 bondId);

    /// @dev The product is expired.
    /// @param tokenAddress Address of a token.
    /// @param productId Product Id.
    /// @param deadline The program expiry time.
    /// @param curTime Current timestamp.
    error ProductExpired(address tokenAddress, uint256 productId, uint256 deadline, uint256 curTime);

    /// @dev The product is already closed.
    /// @param productId Product Id.
    error ProductClosed(uint256 productId);

    /// @dev The product supply is low for the requested payout.
    /// @param tokenAddress Address of a token.
    /// @param productId Product Id.
    /// @param requested Requested payout.
    /// @param actual Actual supply left.
    error ProductSupplyLow(address tokenAddress, uint256 productId, uint256 requested, uint256 actual);

    /// @dev Received lower value than the expected one.
    /// @param provided Provided value is lower.
    /// @param expected Expected value.
    error LowerThan(uint256 provided, uint256 expected);

    /// @dev Wrong amount received / provided.
    /// @param provided Provided amount.
    /// @param expected Expected amount.
    error WrongAmount(uint256 provided, uint256 expected);

    /// @dev Insufficient token allowance.
    /// @param provided Provided amount.
    /// @param expected Minimum expected amount.
    error InsufficientAllowance(uint256 provided, uint256 expected);

    /// @dev Failure of a transfer.
    /// @param token Address of a token.
    /// @param from Address `from`.
    /// @param to Address `to`.
    /// @param amount Token amount.
    error TransferFailed(address token, address from, address to, uint256 amount);

    /// @dev Incentives claim has failed.
    /// @param account Account address.
    /// @param reward Reward amount.
    /// @param topUp Top-up amount.
    error ClaimIncentivesFailed(address account, uint256 reward, uint256 topUp);

    /// @dev Caught reentrancy violation.
    error ReentrancyGuard();

    /// @dev Failure of treasury re-balance during the reward allocation.
    /// @param epochNumber Epoch number.
    error TreasuryRebalanceFailed(uint256 epochNumber);

    /// @dev Operation with a wrong component / agent Id.
    /// @param unitId Component / agent Id.
    /// @param unitType Type of the unit (component / agent).
    error WrongUnitId(uint256 unitId, uint256 unitType);

    /// @dev The donator address is blacklisted.
    /// @param account Donator account address.
    error DonatorBlacklisted(address account);

    /// @dev The contract is already initialized.
    error AlreadyInitialized();

    /// @dev The contract has to be delegate-called via proxy.
    error DelegatecallOnly();

    /// @dev The contract is paused.
    error Paused();

    /// @dev Caught an operation that is not supposed to happen in the same block.
    error SameBlockNumberViolation();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IOLAS {
    /// @dev Mints OLA tokens.
    /// @param account Account address.
    /// @param amount OLA token amount.
    function mint(address account, uint256 amount) external;

    /// @dev Provides OLA token time launch.
    /// @return Time launch.
    function timeLaunch() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @dev Required interface for the service registry.
interface IServiceRegistry {
    enum UnitType {
        Component,
        Agent
    }

    /// @dev Checks if the service Id exists.
    /// @param serviceId Service Id.
    /// @return true if the service exists, false otherwise.
    function exists(uint256 serviceId) external view returns (bool);

    /// @dev Gets the full set of linearized components / canonical agent Ids for a specified service.
    /// @notice The service must be / have been deployed in order to get the actual data.
    /// @param serviceId Service Id.
    /// @return numUnitIds Number of component / agent Ids.
    /// @return unitIds Set of component / agent Ids.
    function getUnitIdsOfService(UnitType unitType, uint256 serviceId) external view
        returns (uint256 numUnitIds, uint32[] memory unitIds);

    /// @dev Gets the value of slashed funds from the service registry.
    /// @return amount Drained amount.
    function slashedFunds() external view returns (uint256 amount);

    /// @dev Drains slashed funds.
    /// @return amount Drained amount.
    function drain() external returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @dev Generic token interface for IERC20 and IERC721 tokens.
interface IToken {
    /// @dev Gets the amount of tokens owned by a specified account.
    /// @param account Account address.
    /// @return Amount of tokens owned.
    function balanceOf(address account) external view returns (uint256);

    /// @dev Gets the owner of the token Id.
    /// @param tokenId Token Id.
    /// @return Token Id owner address.
    function ownerOf(uint256 tokenId) external view returns (address);

    /// @dev Gets the total amount of tokens stored by the contract.
    /// @return Amount of tokens.
    function totalSupply() external view returns (uint256);

    /// @dev Transfers the token amount.
    /// @param to Address to transfer to.
    /// @param amount The amount to transfer.
    /// @return True if the function execution is successful.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @dev Gets remaining number of tokens that the `spender` can transfer on behalf of `owner`.
    /// @param owner Token owner.
    /// @param spender Account address that is able to transfer tokens on behalf of the owner.
    /// @return Token amount allowed to be transferred.
    function allowance(address owner, address spender) external view returns (uint256);

    /// @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @param spender Account address that will be able to transfer tokens on behalf of the caller.
    /// @param amount Token amount.
    /// @return True if the function execution is successful.
    function approve(address spender, uint256 amount) external returns (bool);

    /// @dev Transfers the token amount that was previously approved up until the maximum allowance.
    /// @param from Account address to transfer from.
    /// @param to Account address to transfer to.
    /// @param amount Amount to transfer to.
    /// @return True if the function execution is successful.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @dev Interface for treasury management.
interface ITreasury {
    /// @dev Allows approved address to deposit an asset for OLAS.
    /// @param account Account address making a deposit of LP tokens for OLAS.
    /// @param tokenAmount Token amount to get OLAS for.
    /// @param token Token address.
    /// @param olaMintAmount Amount of OLAS token issued.
    function depositTokenForOLAS(address account, uint256 tokenAmount, address token, uint256 olaMintAmount) external;

    /// @dev Deposits service donations in ETH.
    /// @param serviceIds Set of service Ids.
    /// @param amounts Set of corresponding amounts deposited on behalf of each service Id.
    function depositServiceDonationsETH(uint256[] memory serviceIds, uint256[] memory amounts) external payable;

    /// @dev Gets information about token being enabled.
    /// @param token Token address.
    /// @return enabled True is token is enabled.
    function isEnabled(address token) external view returns (bool enabled);

    /// @dev Withdraws ETH and / or OLAS amounts to the requested account address.
    /// @notice Only dispenser contract can call this function.
    /// @notice Reentrancy guard is on a dispenser side.
    /// @notice Zero account address is not possible, since the dispenser contract interacts with msg.sender.
    /// @param account Account address.
    /// @param accountRewards Amount of account rewards.
    /// @param accountTopUps Amount of account top-ups.
    /// @return success True if the function execution is successful.
    function withdrawToAccount(address account, uint256 accountRewards, uint256 accountTopUps) external returns (bool success);

    /// @dev Re-balances treasury funds to account for the treasury reward for a specific epoch.
    /// @param treasuryRewards Treasury rewards.
    /// @return success True, if the function execution is successful.
    function rebalanceTreasury(uint256 treasuryRewards) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/// @dev Interface for voting escrow.
interface IVotingEscrow {
    /// @dev Gets the voting power.
    /// @param account Account address.
    function getVotes(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./TokenomicsConstants.sol";
import "./interfaces/IDonatorBlacklist.sol";
import "./interfaces/IErrorsTokenomics.sol";
import "./interfaces/IOLAS.sol";
import "./interfaces/IServiceRegistry.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITreasury.sol";
import "./interfaces/IVotingEscrow.sol";

/*
* In this contract we consider both ETH and OLAS tokens.
* For ETH tokens, there are currently about 121 million tokens.
* Even if the ETH inflation rate is 5% per year, it would take 130+ years to reach 2^96 - 1 of ETH total supply.
* Lately the inflation rate was lower and could actually be deflationary.
*
* For OLAS tokens, the initial numbers will be as follows:
*  - For the first 10 years there will be the cap of 1 billion (1e27) tokens;
*  - After 10 years, the inflation rate is capped at 2% per year.
* Starting from a year 11, the maximum number of tokens that can be reached per the year x is 1e27 * (1.02)^x.
* To make sure that a unit(n) does not overflow the total supply during the year x, we have to check that
* 2^n - 1 >= 1e27 * (1.02)^x. We limit n by 96, thus it would take 220+ years to reach that total supply.
*
* We then limit each time variable to last until the value of 2^32 - 1 in seconds.
* 2^32 - 1 gives 136+ years counted in seconds starting from the year 1970.
* Thus, this counter is safe until the year 2106.
*
* The number of blocks cannot be practically bigger than the number of seconds, since there is more than one second
* in a block. Thus, it is safe to assume that uint32 for the number of blocks is also sufficient.
*
* We also limit the number of registry units by the value of 2^32 - 1.
* We assume that the system is expected to support no more than 2^32-1 units.
*
* Lastly, we assume that the coefficients from tokenomics factors calculation are bound by 2^16 - 1.
*
* In conclusion, this contract is only safe to use until 2106.
*/

// Structure for component / agent point with tokenomics-related statistics
// The size of the struct is 96 + 32 + 8 * 2 = 144 (1 slot)
struct UnitPoint {
    // Summation of all the relative OLAS top-ups accumulated by each component / agent in a service
    // After 10 years, the OLAS inflation rate is 2% per year. It would take 220+ years to reach 2^96 - 1
    uint96 sumUnitTopUpsOLAS;
    // Number of new units
    // This number cannot be practically bigger than the total number of supported units
    uint32 numNewUnits;
    // Reward component / agent fraction
    // This number cannot be practically bigger than 100 as the summation with other fractions gives at most 100 (%)
    uint8 rewardUnitFraction;
    // Top-up component / agent fraction
    // This number cannot be practically bigger than 100 as the summation with other fractions gives at most 100 (%)
    uint8 topUpUnitFraction;
}

// Structure for epoch point with tokenomics-related statistics during each epoch
// The size of the struct is 96 * 2 + 64 + 32 * 2 + 8 * 2 = 256 + 80 (2 slots)
struct EpochPoint {
    // Total amount of ETH donations accrued by the protocol during one epoch
    // Even if the ETH inflation rate is 5% per year, it would take 130+ years to reach 2^96 - 1 of ETH total supply
    uint96 totalDonationsETH;
    // Amount of OLAS intended to fund top-ups for the epoch based on the inflation schedule
    // After 10 years, the OLAS inflation rate is 2% per year. It would take 220+ years to reach 2^96 - 1
    uint96 totalTopUpsOLAS;
    // Inverse of the discount factor
    // IDF is bound by a factor of 18, since (2^64 - 1) / 10^18 > 18
    // IDF uses a multiplier of 10^18 by default, since it is a rational number and must be accounted for divisions
    // The IDF depends on the epsilonRate value, idf = 1 + epsilonRate, and epsilonRate is bound by 17 with 18 decimals
    uint64 idf;
    // Number of new owners
    // Each unit has at most one owner, so this number cannot be practically bigger than numNewUnits
    uint32 numNewOwners;
    // Epoch end timestamp
    // 2^32 - 1 gives 136+ years counted in seconds starting from the year 1970, which is safe until the year of 2106
    uint32 endTime;
    // Parameters for rewards and top-ups (in percentage)
    // Each of these numbers cannot be practically bigger than 100 as they sum up to 100%
    // treasuryFraction + rewardComponentFraction + rewardAgentFraction = 100%
    // Treasury fraction
    uint8 rewardTreasuryFraction;
    // maxBondFraction + topUpComponentFraction + topUpAgentFraction <= 100%
    // Amount of OLAS (in percentage of inflation) intended to fund bonding incentives during the epoch
    uint8 maxBondFraction;
}

// Structure for tokenomics point
// The size of the struct is 256 * 2 + 256 * 2 = 256 * 4 (4 slots)
struct TokenomicsPoint {
    // Two unit points in a representation of mapping and not on array to save on gas
    // One unit point is for component (key = 0) and one is for agent (key = 1)
    mapping(uint256 => UnitPoint) unitPoints;
    // Epoch point
    EpochPoint epochPoint;
}

// Struct for component / agent incentive balances
struct IncentiveBalances {
    // Reward in ETH
    // Even if the ETH inflation rate is 5% per year, it would take 130+ years to reach 2^96 - 1 of ETH total supply
    uint96 reward;
    // Pending relative reward in ETH
    uint96 pendingRelativeReward;
    // Top-up in OLAS
    // After 10 years, the OLAS inflation rate is 2% per year. It would take 220+ years to reach 2^96 - 1
    uint96 topUp;
    // Pending relative top-up
    uint96 pendingRelativeTopUp;
    // Last epoch number the information was updated
    // This number cannot be practically bigger than the number of blocks
    uint32 lastEpoch;
}

/// @title Tokenomics - Smart contract for tokenomics logic with incentives for unit owners and discount factor regulations for bonds.
/// @author AL
/// @author Aleksandr Kuperman - <[email protected]>
contract Tokenomics is TokenomicsConstants, IErrorsTokenomics {
    event OwnerUpdated(address indexed owner);
    event TreasuryUpdated(address indexed treasury);
    event DepositoryUpdated(address indexed depository);
    event DispenserUpdated(address indexed dispenser);
    event EpochLengthUpdated(uint256 epochLen);
    event EffectiveBondUpdated(uint256 effectiveBond);
    event IDFUpdated(uint256 idf);
    event TokenomicsParametersUpdateRequested(uint256 indexed epochNumber, uint256 devsPerCapital, uint256 codePerDev,
        uint256 epsilonRate, uint256 epochLen, uint256 veOLASThreshold);
    event TokenomicsParametersUpdated(uint256 indexed epochNumber);
    event IncentiveFractionsUpdateRequested(uint256 indexed epochNumber, uint256 rewardComponentFraction,
        uint256 rewardAgentFraction, uint256 maxBondFraction, uint256 topUpComponentFraction, uint256 topUpAgentFraction);
    event IncentiveFractionsUpdated(uint256 indexed epochNumber);
    event ComponentRegistryUpdated(address indexed componentRegistry);
    event AgentRegistryUpdated(address indexed agentRegistry);
    event ServiceRegistryUpdated(address indexed serviceRegistry);
    event DonatorBlacklistUpdated(address indexed blacklist);
    event EpochSettled(uint256 indexed epochCounter, uint256 treasuryRewards, uint256 accountRewards, uint256 accountTopUps);
    event TokenomicsImplementationUpdated(address indexed implementation);

    // Owner address
    address public owner;
    // Max bond per epoch: calculated as a fraction from the OLAS inflation parameter
    // After 10 years, the OLAS inflation rate is 2% per year. It would take 220+ years to reach 2^96 - 1
    uint96 public maxBond;

    // OLAS token address
    address public olas;
    // Inflation amount per second
    uint96 public inflationPerSecond;

    // Treasury contract address
    address public treasury;
    // veOLAS threshold for top-ups
    // This number cannot be practically bigger than the number of OLAS tokens
    uint96 public veOLASThreshold;

    // Depository contract address
    address public depository;
    // effectiveBond = sum(MaxBond(e)) - sum(BondingProgram) over all epochs: accumulates leftovers from previous epochs
    // Effective bond is updated before the start of the next epoch such that the bonding limits are accounted for
    // This number cannot be practically bigger than the inflation remainder of OLAS
    uint96 public effectiveBond;

    // Dispenser contract address
    address public dispenser;
    // Number of units of useful code that can be built by a developer during one epoch
    // We assume this number will not be practically bigger than 4,722 of its integer-part (with 18 digits of fractional-part)
    uint72 public codePerDev;
    // Current year number
    // This number is enough for the next 255 years
    uint8 public currentYear;
    // Tokenomics parameters change request flag
    bytes1 public tokenomicsParametersUpdated;
    // Reentrancy lock
    uint8 internal _locked;

    // Component Registry
    address public componentRegistry;
    // Default epsilon rate that contributes to the interest rate: 10% or 0.1
    // We assume that for the IDF calculation epsilonRate must be lower than 17 (with 18 decimals)
    // (2^64 - 1) / 10^18 > 18, however IDF = 1 + epsilonRate, thus we limit epsilonRate by 17 with 18 decimals at most
    uint64 public epsilonRate;
    // Epoch length in seconds
    // By design, the epoch length cannot be practically bigger than one year, or 31_536_000 seconds
    uint32 public epochLen;

    // Agent Registry
    address public agentRegistry;
    // veOLAS threshold for top-ups that will be set in the next epoch
    // This number cannot be practically bigger than the number of OLAS tokens
    uint96 public nextVeOLASThreshold;

    // Service Registry
    address public serviceRegistry;
    // Global epoch counter
    // This number cannot be practically bigger than the number of blocks
    uint32 public epochCounter;
    // Time launch of the OLAS contract
    // 2^32 - 1 gives 136+ years counted in seconds starting from the year 1970, which is safe until the year of 2106
    uint32 public timeLaunch;
    // Epoch length in seconds that will be set in the next epoch
    // By design, the epoch length cannot be practically bigger than one year, or 31_536_000 seconds
    uint32 public nextEpochLen;

    // Voting Escrow address
    address public ve;
    // Number of valuable devs that can be paid per units of capital per epoch in fixed point format
    // We assume this number will not be practically bigger than 4,722 of its integer-part (with 18 digits of fractional-part)
    uint72 public devsPerCapital;

    // Blacklist contract address
    address public donatorBlacklist;
    // Last donation block number to prevent the flash loan attack
    // This number cannot be practically bigger than the number of seconds
    uint32 public lastDonationBlockNumber;

    // Map of service Ids and their amounts in current epoch
    mapping(uint256 => uint256) public mapServiceAmounts;
    // Mapping of owner of component / agent address => reward amount (in ETH)
    mapping(address => uint256) public mapOwnerRewards;
    // Mapping of owner of component / agent address => top-up amount (in OLAS)
    mapping(address => uint256) public mapOwnerTopUps;
    // Mapping of epoch => tokenomics point
    mapping(uint256 => TokenomicsPoint) public mapEpochTokenomics;
    // Map of new component / agent Ids that contribute to protocol owned services
    mapping(uint256 => mapping(uint256 => bool)) public mapNewUnits;
    // Mapping of new owner of component / agent addresses that create them
    mapping(address => bool) public mapNewOwners;
    // Mapping of component / agent Id => incentive balances
    mapping(uint256 => mapping(uint256 => IncentiveBalances)) public mapUnitIncentives;

    /// @dev Tokenomics constructor.
    constructor()
        TokenomicsConstants()
    {}

    /// @dev Tokenomics initializer.
    /// @notice Tokenomics contract must be initialized no later than one year from the launch of the OLAS token contract.
    /// @param _olas OLAS token address.
    /// @param _treasury Treasury address.
    /// @param _depository Depository address.
    /// @param _dispenser Dispenser address.
    /// @param _ve Voting Escrow address.
    /// @param _epochLen Epoch length.
    /// @param _componentRegistry Component registry address.
    /// @param _agentRegistry Agent registry address.
    /// @param _serviceRegistry Service registry address.
    /// @param _donatorBlacklist DonatorBlacklist address.
    /// #if_succeeds {:msg "ep is correct endTime"} mapEpochTokenomics[0].epochPoint.endTime > 0;
    /// #if_succeeds {:msg "maxBond eq effectiveBond form start"} effectiveBond == maxBond;
    /// #if_succeeds {:msg "olas must not be a zero address"} old(_olas) != address(0) ==> olas == _olas;
    /// #if_succeeds {:msg "treasury must not be a zero address"} old(_treasury) != address(0) ==> treasury == _treasury;
    /// #if_succeeds {:msg "depository must not be a zero address"} old(_depository) != address(0) ==> depository == _depository;
    /// #if_succeeds {:msg "dispenser must not be a zero address"} old(_dispenser) != address(0) ==> dispenser == _dispenser;
    /// #if_succeeds {:msg "vaOLAS must not be a zero address"} old(_ve) != address(0) ==> ve == _ve;
    /// #if_succeeds {:msg "epochLen"} old(_epochLen > MIN_EPOCH_LENGTH && _epochLen <= type(uint32).max) ==> epochLen == _epochLen;
    /// #if_succeeds {:msg "componentRegistry must not be a zero address"} old(_componentRegistry) != address(0) ==> componentRegistry == _componentRegistry;
    /// #if_succeeds {:msg "agentRegistry must not be a zero address"} old(_agentRegistry) != address(0) ==> agentRegistry == _agentRegistry;
    /// #if_succeeds {:msg "serviceRegistry must not be a zero address"} old(_serviceRegistry) != address(0) ==> serviceRegistry == _serviceRegistry;
    /// #if_succeeds {:msg "donatorBlacklist assignment"} donatorBlacklist == _donatorBlacklist;
    /// #if_succeeds {:msg "inflationPerSecond must not be zero"} inflationPerSecond > 0 && inflationPerSecond <= getInflationForYear(0);
    /// #if_succeeds {:msg "Zero epoch point end time must be non-zero"} mapEpochTokenomics[0].epochPoint.endTime > 0;
    /// #if_succeeds {:msg "maxBond"} old(_epochLen > MIN_EPOCH_LENGTH && _epochLen <= type(uint32).max && inflationPerSecond > 0 && inflationPerSecond <= getInflationForYear(0))
    /// ==> maxBond == (inflationPerSecond * _epochLen * mapEpochTokenomics[1].epochPoint.maxBondFraction) / 100;
    function initializeTokenomics(
        address _olas,
        address _treasury,
        address _depository,
        address _dispenser,
        address _ve,
        uint256 _epochLen,
        address _componentRegistry,
        address _agentRegistry,
        address _serviceRegistry,
        address _donatorBlacklist
    ) external
    {
        // Check if the contract is already initialized
        if (owner != address(0)) {
            revert AlreadyInitialized();
        }

        // Check for at least one zero contract address
        if (_olas == address(0) || _treasury == address(0) || _depository == address(0) || _dispenser == address(0) ||
            _ve == address(0) || _componentRegistry == address(0) || _agentRegistry == address(0) ||
            _serviceRegistry == address(0)) {
            revert ZeroAddress();
        }

        // Initialize storage variables
        owner = msg.sender;
        _locked = 1;
        epsilonRate = 1e17;
        veOLASThreshold = 10_000e18;

        // Check that the epoch length has at least a practical minimal value
        if (uint32(_epochLen) < MIN_EPOCH_LENGTH) {
            revert LowerThan(_epochLen, MIN_EPOCH_LENGTH);
        }

        // Check that the epoch length is not bigger than one year
        if (uint32(_epochLen) > ONE_YEAR) {
            revert Overflow(_epochLen, ONE_YEAR);
        }

        // Assign other input variables
        olas = _olas;
        treasury = _treasury;
        depository = _depository;
        dispenser = _dispenser;
        ve = _ve;
        epochLen = uint32(_epochLen);
        componentRegistry = _componentRegistry;
        agentRegistry = _agentRegistry;
        serviceRegistry = _serviceRegistry;
        donatorBlacklist = _donatorBlacklist;

        // Time launch of the OLAS contract
        uint256 _timeLaunch = IOLAS(_olas).timeLaunch();
        // Check that the tokenomics contract is initialized no later than one year after the OLAS token is deployed
        if (block.timestamp >= (_timeLaunch + ONE_YEAR)) {
            revert Overflow(_timeLaunch + ONE_YEAR, block.timestamp);
        }
        // Seconds left in the deployment year for the zero year inflation schedule
        // This value is necessary since it is different from a precise one year time, as the OLAS contract started earlier
        uint256 zeroYearSecondsLeft = uint32(_timeLaunch + ONE_YEAR - block.timestamp);
        // Calculating initial inflation per second: (mintable OLAS from getInflationForYear(0)) / (seconds left in a year)
        // Note that we lose precision here dividing by the number of seconds right away, but to avoid complex calculations
        // later we consider it less error-prone and sacrifice at most 6 insignificant digits (or 1e-12) of OLAS per year
        uint256 _inflationPerSecond = getInflationForYear(0) / zeroYearSecondsLeft;
        inflationPerSecond = uint96(_inflationPerSecond);
        timeLaunch = uint32(_timeLaunch);

        // The initial epoch start time is the end time of the zero epoch
        mapEpochTokenomics[0].epochPoint.endTime = uint32(block.timestamp);

        // The epoch counter starts from 1
        epochCounter = 1;
        TokenomicsPoint storage tp = mapEpochTokenomics[1];

        // Setting initial parameters and fractions
        devsPerCapital = 1e18;
        tp.epochPoint.idf = 1e18;

        // Reward fractions
        // 0 stands for components and 1 for agents
        // The initial target is to distribute around 2/3 of incentives reserved to fund owners of the code
        // for components royalties and 1/3 for agents royalties
        tp.unitPoints[0].rewardUnitFraction = 83;
        tp.unitPoints[1].rewardUnitFraction = 17;
        // tp.epochPoint.rewardTreasuryFraction is essentially equal to zero

        // We consider a unit of code as n agents or m components.
        // Initially we consider 1 unit of code as either 2 agents or 1 component.
        // E.g. if we have 2 profitable components and 2 profitable agents, this means there are (2 x 2.0 + 2 x 1.0) / 3 = 2
        // units of code.
        // We assume that during one epoch the developer can contribute with one piece of code (1 component or 2 agents)
        codePerDev = 1e18;

        // Top-up fractions
        uint256 _maxBondFraction = 50;
        tp.epochPoint.maxBondFraction = uint8(_maxBondFraction);
        tp.unitPoints[0].topUpUnitFraction = 41;
        tp.unitPoints[1].topUpUnitFraction = 9;

        // Calculate initial effectiveBond based on the maxBond during the first epoch
        // maxBond = inflationPerSecond * epochLen * maxBondFraction / 100
        uint256 _maxBond = (_inflationPerSecond * _epochLen * _maxBondFraction) / 100;
        maxBond = uint96(_maxBond);
        effectiveBond = uint96(_maxBond);
    }

    /// @dev Gets the tokenomics implementation contract address.
    /// @return implementation Tokenomics implementation contract address.
    function tokenomicsImplementation() external view returns (address implementation) {
        assembly {
            implementation := sload(PROXY_TOKENOMICS)
        }
    }

    /// @dev Changes the tokenomics implementation contract address.
    /// @notice Make sure the implementation contract has a function to change the implementation.
    /// @param implementation Tokenomics implementation contract address.
    /// #if_succeeds {:msg "new implementation"} implementation == tokenomicsImplementation();
    function changeTokenomicsImplementation(address implementation) external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the zero address
        if (implementation == address(0)) {
            revert ZeroAddress();
        }

        // Store the implementation address under the designated storage slot
        assembly {
            sstore(PROXY_TOKENOMICS, implementation)
        }
        emit TokenomicsImplementationUpdated(implementation);
    }

    /// @dev Changes the owner address.
    /// @param newOwner Address of a new owner.
    function changeOwner(address newOwner) external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the zero address
        if (newOwner == address(0)) {
            revert ZeroAddress();
        }

        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    /// @dev Changes various managing contract addresses.
    /// @param _treasury Treasury address.
    /// @param _depository Depository address.
    /// @param _dispenser Dispenser address.
    function changeManagers(address _treasury, address _depository, address _dispenser) external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Change Treasury contract address
        if (_treasury != address(0)) {
            treasury = _treasury;
            emit TreasuryUpdated(_treasury);
        }
        // Change Depository contract address
        if (_depository != address(0)) {
            depository = _depository;
            emit DepositoryUpdated(_depository);
        }
        // Change Dispenser contract address
        if (_dispenser != address(0)) {
            dispenser = _dispenser;
            emit DispenserUpdated(_dispenser);
        }
    }

    /// @dev Changes registries contract addresses.
    /// @param _componentRegistry Component registry address.
    /// @param _agentRegistry Agent registry address.
    /// @param _serviceRegistry Service registry address.
    function changeRegistries(address _componentRegistry, address _agentRegistry, address _serviceRegistry) external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for registries addresses
        if (_componentRegistry != address(0)) {
            componentRegistry = _componentRegistry;
            emit ComponentRegistryUpdated(_componentRegistry);
        }
        if (_agentRegistry != address(0)) {
            agentRegistry = _agentRegistry;
            emit AgentRegistryUpdated(_agentRegistry);
        }
        if (_serviceRegistry != address(0)) {
            serviceRegistry = _serviceRegistry;
            emit ServiceRegistryUpdated(_serviceRegistry);
        }
    }

    /// @dev Changes donator blacklist contract address.
    /// @notice DonatorBlacklist contract can be disabled by setting its address to zero.
    /// @param _donatorBlacklist DonatorBlacklist contract address.
    function changeDonatorBlacklist(address _donatorBlacklist) external {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        donatorBlacklist = _donatorBlacklist;
        emit DonatorBlacklistUpdated(_donatorBlacklist);
    }

    /// @dev Changes tokenomics parameters.
    /// @notice Parameter values are not updated for those that are passed as zero or out of defined bounds.
    /// @param _devsPerCapital Number of valuable devs can be paid per units of capital per epoch.
    /// @param _codePerDev Number of units of useful code that can be built by a developer during one epoch.
    /// @param _epsilonRate Epsilon rate that contributes to the interest rate value.
    /// @param _epochLen New epoch length.
    /// #if_succeeds {:msg "ep is correct endTime"} epochCounter > 1
    /// ==> mapEpochTokenomics[epochCounter - 1].epochPoint.endTime > mapEpochTokenomics[epochCounter - 2].epochPoint.endTime;
    /// #if_succeeds {:msg "epochLen"} old(_epochLen > MIN_EPOCH_LENGTH && _epochLen <= ONE_YEAR && epochLen != _epochLen) ==> nextEpochLen == _epochLen;
    /// #if_succeeds {:msg "devsPerCapital"} _devsPerCapital > MIN_PARAM_VALUE && _devsPerCapital <= type(uint72).max ==> devsPerCapital == _devsPerCapital;
    /// #if_succeeds {:msg "codePerDev"} _codePerDev > MIN_PARAM_VALUE && _codePerDev <= type(uint72).max ==> codePerDev == _codePerDev;
    /// #if_succeeds {:msg "epsilonRate"} _epsilonRate > 0 && _epsilonRate < 17e18 ==> epsilonRate == _epsilonRate;
    /// #if_succeeds {:msg "veOLASThreshold"} _veOLASThreshold > 0 && _veOLASThreshold <= type(uint96).max ==> nextVeOLASThreshold == _veOLASThreshold;
    function changeTokenomicsParameters(
        uint256 _devsPerCapital,
        uint256 _codePerDev,
        uint256 _epsilonRate,
        uint256 _epochLen,
        uint256 _veOLASThreshold
    ) external
    {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // devsPerCapital is the part of the IDF calculation and thus its change will be accounted for in the next epoch
        if (uint72(_devsPerCapital) > MIN_PARAM_VALUE) {
            devsPerCapital = uint72(_devsPerCapital);
        } else {
            // This is done in order not to pass incorrect parameters into the event
            _devsPerCapital = devsPerCapital;
        }

        // devsPerCapital is the part of the IDF calculation and thus its change will be accounted for in the next epoch
        if (uint72(_codePerDev) > MIN_PARAM_VALUE) {
            codePerDev = uint72(_codePerDev);
        } else {
            // This is done in order not to pass incorrect parameters into the event
            _codePerDev = codePerDev;
        }

        // Check the epsilonRate value for idf to fit in its size
        // 2^64 - 1 < 18.5e18, idf is equal at most 1 + epsilonRate < 18e18, which fits in the variable size
        // epsilonRate is the part of the IDF calculation and thus its change will be accounted for in the next epoch
        if (_epsilonRate > 0 && _epsilonRate <= 17e18) {
            epsilonRate = uint64(_epsilonRate);
        } else {
            _epsilonRate = epsilonRate;
        }

        // Check for the epochLen value to change
        if (uint32(_epochLen) >= MIN_EPOCH_LENGTH && uint32(_epochLen) <= ONE_YEAR) {
            nextEpochLen = uint32(_epochLen);
        } else {
            _epochLen = epochLen;
        }

        // Adjust veOLAS threshold for the next epoch
        if (uint96(_veOLASThreshold) > 0) {
            nextVeOLASThreshold = uint96(_veOLASThreshold);
        } else {
            _veOLASThreshold = veOLASThreshold;
        }

        // Set the flag that tokenomics parameters are requested to be updated (1st bit is set to one)
        tokenomicsParametersUpdated = tokenomicsParametersUpdated | 0x01;
        emit TokenomicsParametersUpdateRequested(epochCounter + 1, _devsPerCapital, _codePerDev, _epsilonRate, _epochLen,
            _veOLASThreshold);
    }

    /// @dev Sets incentive parameter fractions.
    /// @param _rewardComponentFraction Fraction for component owner rewards funded by ETH donations.
    /// @param _rewardAgentFraction Fraction for agent owner rewards funded by ETH donations.
    /// @param _maxBondFraction Fraction for the maxBond that depends on the OLAS inflation.
    /// @param _topUpComponentFraction Fraction for component owners OLAS top-up.
    /// @param _topUpAgentFraction Fraction for agent owners OLAS top-up.
    /// #if_succeeds {:msg "maxBond"} mapEpochTokenomics[epochCounter + 1].epochPoint.maxBondFraction == _maxBondFraction;
    function changeIncentiveFractions(
        uint256 _rewardComponentFraction,
        uint256 _rewardAgentFraction,
        uint256 _maxBondFraction,
        uint256 _topUpComponentFraction,
        uint256 _topUpAgentFraction
    ) external
    {
        // Check for the contract ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check that the sum of fractions is 100%
        if (_rewardComponentFraction + _rewardAgentFraction > 100) {
            revert WrongAmount(_rewardComponentFraction + _rewardAgentFraction, 100);
        }

        // Same check for top-up fractions
        if (_maxBondFraction + _topUpComponentFraction + _topUpAgentFraction > 100) {
            revert WrongAmount(_maxBondFraction + _topUpComponentFraction + _topUpAgentFraction, 100);
        }

        // All the adjustments will be accounted for in the next epoch
        uint256 eCounter = epochCounter + 1;
        TokenomicsPoint storage tp = mapEpochTokenomics[eCounter];
        // 0 stands for components and 1 for agents
        tp.unitPoints[0].rewardUnitFraction = uint8(_rewardComponentFraction);
        tp.unitPoints[1].rewardUnitFraction = uint8(_rewardAgentFraction);
        // Rewards are always distributed in full: the leftovers will be allocated to treasury
        tp.epochPoint.rewardTreasuryFraction = uint8(100 - _rewardComponentFraction - _rewardAgentFraction);

        tp.epochPoint.maxBondFraction = uint8(_maxBondFraction);
        tp.unitPoints[0].topUpUnitFraction = uint8(_topUpComponentFraction);
        tp.unitPoints[1].topUpUnitFraction = uint8(_topUpAgentFraction);

        // Set the flag that incentive fractions are requested to be updated (2nd bit is set to one)
        tokenomicsParametersUpdated = tokenomicsParametersUpdated | 0x02;
        emit IncentiveFractionsUpdateRequested(eCounter, _rewardComponentFraction, _rewardAgentFraction,
            _maxBondFraction, _topUpComponentFraction, _topUpAgentFraction);
    }

    /// @dev Reserves OLAS amount from the effective bond to be minted during a bond program.
    /// @notice Programs exceeding the limit of the effective bond are not allowed.
    /// @param amount Requested amount for the bond program.
    /// @return success True if effective bond threshold is not reached.
    /// #if_succeeds {:msg "effectiveBond"} old(effectiveBond) > amount ==> effectiveBond == old(effectiveBond) - amount;
    function reserveAmountForBondProgram(uint256 amount) external returns (bool success) {
        // Check for the depository access
        if (depository != msg.sender) {
            revert ManagerOnly(msg.sender, depository);
        }

        // Effective bond must be bigger than the requested amount
        uint256 eBond = effectiveBond;
        if (eBond >= amount) {
            // The effective bond value is adjusted with the amount that is reserved for bonding
            // The unrealized part of the bonding amount will be returned when the bonding program is closed
            eBond -= amount;
            effectiveBond = uint96(eBond);
            success = true;
            emit EffectiveBondUpdated(eBond);
        }
    }

    /// @dev Refunds unused bond program amount when the program is closed.
    /// @param amount Amount to be refunded from the closed bond program.
    /// #if_succeeds {:msg "effectiveBond"} old(effectiveBond + amount) <= type(uint96).max ==> effectiveBond == old(effectiveBond) + amount;
    function refundFromBondProgram(uint256 amount) external {
        // Check for the depository access
        if (depository != msg.sender) {
            revert ManagerOnly(msg.sender, depository);
        }

        uint256 eBond = effectiveBond + amount;
        // This scenario is not realistically possible. It is only possible when closing the bonding program
        // with the effectiveBond value close to uint96 max
        if (eBond > type(uint96).max) {
            revert Overflow(eBond, type(uint96).max);
        }
        effectiveBond = uint96(eBond);
        emit EffectiveBondUpdated(eBond);
    }

    /// @dev Finalizes epoch incentives for a specified component / agent Id.
    /// @param epochNum Epoch number to finalize incentives for.
    /// @param unitType Unit type (component / agent).
    /// @param unitId Unit Id.
    function _finalizeIncentivesForUnitId(uint256 epochNum, uint256 unitType, uint256 unitId) internal {
        // Gets the overall amount of unit rewards for the unit's last epoch
        // The pendingRelativeReward can be zero if the rewardUnitFraction was zero in the first place
        // Note that if the rewardUnitFraction is set to zero at the end of epoch, the whole pending reward will be zero
        // reward = (pendingRelativeReward * rewardUnitFraction) / 100
        uint256 totalIncentives = mapUnitIncentives[unitType][unitId].pendingRelativeReward;
        if (totalIncentives > 0) {
            totalIncentives *= mapEpochTokenomics[epochNum].unitPoints[unitType].rewardUnitFraction;
            // Add to the final reward for the last epoch
            totalIncentives = mapUnitIncentives[unitType][unitId].reward + totalIncentives / 100;
            mapUnitIncentives[unitType][unitId].reward = uint96(totalIncentives);
            // Setting pending reward to zero
            mapUnitIncentives[unitType][unitId].pendingRelativeReward = 0;
        }

        // Add to the final top-up for the last epoch
        totalIncentives = mapUnitIncentives[unitType][unitId].pendingRelativeTopUp;
        // The pendingRelativeTopUp can be zero if the service owner did not stake enough veOLAS
        // The topUpUnitFraction was checked before and if it were zero, pendingRelativeTopUp would be zero as well
        if (totalIncentives > 0) {
            // Summation of all the unit top-ups and total amount of top-ups per epoch
            // topUp = (pendingRelativeTopUp * totalTopUpsOLAS * topUpUnitFraction) / (100 * sumUnitTopUpsOLAS)
            totalIncentives *= mapEpochTokenomics[epochNum].epochPoint.totalTopUpsOLAS;
            totalIncentives *= mapEpochTokenomics[epochNum].unitPoints[unitType].topUpUnitFraction;
            uint256 sumUnitIncentives = uint256(mapEpochTokenomics[epochNum].unitPoints[unitType].sumUnitTopUpsOLAS) * 100;
            totalIncentives = mapUnitIncentives[unitType][unitId].topUp + totalIncentives / sumUnitIncentives;
            mapUnitIncentives[unitType][unitId].topUp = uint96(totalIncentives);
            // Setting pending top-up to zero
            mapUnitIncentives[unitType][unitId].pendingRelativeTopUp = 0;
        }
    }

    /// @dev Records service donations into corresponding data structures.
    /// @param serviceIds Set of service Ids.
    /// @param amounts Correspondent set of ETH amounts provided by services.
    /// @param curEpoch Current epoch number.
    function _trackServiceDonations(uint256[] memory serviceIds, uint256[] memory amounts, uint256 curEpoch) internal {
        // Component / agent registry addresses
        address[] memory registries = new address[](2);
        (registries[0], registries[1]) = (componentRegistry, agentRegistry);

        // Check all the unit fractions and identify those that need accounting of incentives
        bool[] memory incentiveFlags = new bool[](4);
        incentiveFlags[0] = (mapEpochTokenomics[curEpoch].unitPoints[0].rewardUnitFraction > 0);
        incentiveFlags[1] = (mapEpochTokenomics[curEpoch].unitPoints[1].rewardUnitFraction > 0);
        incentiveFlags[2] = (mapEpochTokenomics[curEpoch].unitPoints[0].topUpUnitFraction > 0);
        incentiveFlags[3] = (mapEpochTokenomics[curEpoch].unitPoints[1].topUpUnitFraction > 0);

        // Get the number of services
        uint256 numServices = serviceIds.length;
        // Loop over service Ids to calculate their partial contributions
        for (uint256 i = 0; i < numServices; ++i) {
            // Check if the service owner stakes enough OLAS for its components / agents to get a top-up
            // If both component and agent owner top-up fractions are zero, there is no need to call external contract
            // functions to check each service owner veOLAS balance
            bool topUpEligible;
            if (incentiveFlags[2] || incentiveFlags[3]) {
                address serviceOwner = IToken(serviceRegistry).ownerOf(serviceIds[i]);
                topUpEligible = IVotingEscrow(ve).getVotes(serviceOwner) >= veOLASThreshold ? true : false;
            }

            // Loop over component and agent Ids
            for (uint256 unitType = 0; unitType < 2; ++unitType) {
                // Get the number and set of units in the service
                (uint256 numServiceUnits, uint32[] memory serviceUnitIds) = IServiceRegistry(serviceRegistry).
                    getUnitIdsOfService(IServiceRegistry.UnitType(unitType), serviceIds[i]);
                // Service has to be deployed at least once to be able to receive donations,
                // otherwise its components and agents are undefined
                if (numServiceUnits == 0) {
                    revert ServiceNeverDeployed(serviceIds[i]);
                }
                // Record amounts data only if at least one incentive unit fraction is not zero
                if (incentiveFlags[unitType] || incentiveFlags[unitType + 2]) {
                    // The amount has to be adjusted for the number of units in the service
                    uint96 amount = uint96(amounts[i] / numServiceUnits);
                    // Accumulate amounts for each unit Id
                    for (uint256 j = 0; j < numServiceUnits; ++j) {
                        // Get the last epoch number the incentives were accumulated for
                        uint256 lastEpoch = mapUnitIncentives[unitType][serviceUnitIds[j]].lastEpoch;
                        // Check if there were no donations in previous epochs and set the current epoch
                        if (lastEpoch == 0) {
                            mapUnitIncentives[unitType][serviceUnitIds[j]].lastEpoch = uint32(curEpoch);
                        } else if (lastEpoch < curEpoch) {
                            // Finalize unit rewards and top-ups if there were pending ones from the previous epoch
                            // Pending incentives are getting finalized during the next epoch the component / agent
                            // receives donations. If this is not the case before claiming incentives, the finalization
                            // happens in the accountOwnerIncentives() where the incentives are issued
                            _finalizeIncentivesForUnitId(lastEpoch, unitType, serviceUnitIds[j]);
                            // Change the last epoch number
                            mapUnitIncentives[unitType][serviceUnitIds[j]].lastEpoch = uint32(curEpoch);
                        }
                        // Sum the relative amounts for the corresponding components / agents
                        if (incentiveFlags[unitType]) {
                            mapUnitIncentives[unitType][serviceUnitIds[j]].pendingRelativeReward += amount;
                        }
                        // If eligible, add relative top-up weights in the form of donation amounts.
                        // These weights will represent the fraction of top-ups for each component / agent relative
                        // to the overall amount of top-ups that must be allocated
                        if (topUpEligible && incentiveFlags[unitType + 2]) {
                            mapUnitIncentives[unitType][serviceUnitIds[j]].pendingRelativeTopUp += amount;
                            mapEpochTokenomics[curEpoch].unitPoints[unitType].sumUnitTopUpsOLAS += amount;
                        }
                    }
                }

                // Record new units and new unit owners
                for (uint256 j = 0; j < numServiceUnits; ++j) {
                    // Check if the component / agent is used for the first time
                    if (!mapNewUnits[unitType][serviceUnitIds[j]]) {
                        mapNewUnits[unitType][serviceUnitIds[j]] = true;
                        mapEpochTokenomics[curEpoch].unitPoints[unitType].numNewUnits++;
                        // Check if the owner has introduced component / agent for the first time
                        // This is done together with the new unit check, otherwise it could be just a new unit owner
                        address unitOwner = IToken(registries[unitType]).ownerOf(serviceUnitIds[j]);
                        if (!mapNewOwners[unitOwner]) {
                            mapNewOwners[unitOwner] = true;
                            mapEpochTokenomics[curEpoch].epochPoint.numNewOwners++;
                        }
                    }
                }
            }
        }
    }

    /// @dev Tracks the deposited ETH service donations during the current epoch.
    /// @notice This function is only called by the treasury where the validity of arrays and values has been performed.
    /// @notice Donating to services must not be followed by the checkpoint in the same block.
    /// @param donator Donator account address.
    /// @param serviceIds Set of service Ids.
    /// @param amounts Correspondent set of ETH amounts provided by services.
    /// @param donationETH Overall service donation amount in ETH.
    /// #if_succeeds {:msg "totalDonationsETH can only increase"} old(mapEpochTokenomics[epochCounter].epochPoint.totalDonationsETH) + donationETH <= type(uint96).max
    /// ==> mapEpochTokenomics[epochCounter].epochPoint.totalDonationsETH == old(mapEpochTokenomics[epochCounter].epochPoint.totalDonationsETH) + donationETH;
    /// #if_succeeds {:msg "sumUnitTopUpsOLAS for components can only increase"} mapEpochTokenomics[epochCounter].unitPoints[0].sumUnitTopUpsOLAS >= old(mapEpochTokenomics[epochCounter].unitPoints[0].sumUnitTopUpsOLAS);
    /// #if_succeeds {:msg "sumUnitTopUpsOLAS for agents can only increase"} mapEpochTokenomics[epochCounter].unitPoints[1].sumUnitTopUpsOLAS >= old(mapEpochTokenomics[epochCounter].unitPoints[1].sumUnitTopUpsOLAS);
    /// #if_succeeds {:msg "numNewOwners can only increase"} mapEpochTokenomics[epochCounter].epochPoint.numNewOwners >= old(mapEpochTokenomics[epochCounter].epochPoint.numNewOwners);
    function trackServiceDonations(
        address donator,
        uint256[] memory serviceIds,
        uint256[] memory amounts,
        uint256 donationETH
    ) external {
        // Check for the treasury access
        if (treasury != msg.sender) {
            revert ManagerOnly(msg.sender, treasury);
        }

        // Check if the donator blacklist is enabled, and the status of the donator address
        address bList = donatorBlacklist;
        if (bList != address(0) && IDonatorBlacklist(bList).isDonatorBlacklisted(donator)) {
            revert DonatorBlacklisted(donator);
        }

        // Get the number of services
        uint256 numServices = serviceIds.length;
        // Loop over service Ids, accumulate donation value and check for the service existence
        for (uint256 i = 0; i < numServices; ++i) {
            // Check for the service Id existence
            if (!IServiceRegistry(serviceRegistry).exists(serviceIds[i])) {
                revert ServiceDoesNotExist(serviceIds[i]);
            }
        }
        // Get the current epoch
        uint256 curEpoch = epochCounter;
        // Increase the total service donation balance per epoch
        donationETH += mapEpochTokenomics[curEpoch].epochPoint.totalDonationsETH;
        mapEpochTokenomics[curEpoch].epochPoint.totalDonationsETH = uint96(donationETH);

        // Track service donations
        _trackServiceDonations(serviceIds, amounts, curEpoch);

        // Set the current block number
        lastDonationBlockNumber = uint32(block.number);
    }

    /// @dev Gets the inverse discount factor value.
    /// @param treasuryRewards Treasury rewards.
    /// @param numNewOwners Number of new owners of components / agents registered during the epoch.
    /// @return idf IDF value.
    function _calculateIDF(
        uint256 treasuryRewards,
        uint256 numNewOwners
    ) internal view returns (uint256 idf) {
        // Calculate the inverse discount factor based on the tokenomics parameters and values of units per epoch
        // df = 1 / (1 + iterest_rate), idf = (1 + iterest_rate) >= 1.0
        // Calculate IDF from epsilon rate and f(K,D)
        // f(K(e), D(e)) = d * k * K(e) + d * D(e),
        // where d corresponds to codePerDev and k corresponds to devPerCapital
        // codeUnits (codePerDev) is the estimated value of the code produced by a single developer for epoch
        UD60x18 codeUnits = UD60x18.wrap(codePerDev);
        // fKD = codeUnits * devsPerCapital * treasuryRewards + codeUnits * newOwners;
        // Convert all the necessary values to fixed-point numbers considering OLAS decimals (18 by default)
        UD60x18 fp = UD60x18.wrap(treasuryRewards);
        // Convert devsPerCapital
        UD60x18 fpDevsPerCapital = UD60x18.wrap(devsPerCapital);
        fp = fp.mul(fpDevsPerCapital);
        UD60x18 fpNumNewOwners = toUD60x18(numNewOwners);
        fp = fp.add(fpNumNewOwners);
        fp = fp.mul(codeUnits);
        // fp = fp / 100 - calculate the final value in fixed point
        fp = fp.div(UD60x18.wrap(100e18));
        // fKD in the state that is comparable with epsilon rate
        uint256 fKD = UD60x18.unwrap(fp);

        // Compare with epsilon rate and choose the smallest one
        if (fKD > epsilonRate) {
            fKD = epsilonRate;
        }
        // 1 + fKD in the system where 1e18 is equal to a whole unit (18 decimals)
        idf = 1e18 + fKD;
    }

    /// @dev Record global data with a new checkpoint.
    /// @notice Note that even though a specific epoch can last longer than the epochLen, it is practically
    ///         not valid not to call a checkpoint for longer than a year. Thus, the function will return false otherwise.
    /// @notice Checkpoint must not be called in the same block with the service donation.
    /// @return True if the function execution is successful.
    /// #if_succeeds {:msg "epochCounter can only increase"} $result == true ==> epochCounter == old(epochCounter) + 1;
    /// #if_succeeds {:msg "two events will never happen at the same time"} $result == true && (block.timestamp - timeLaunch) / ONE_YEAR > old(currentYear) ==> currentYear == old(currentYear) + 1;
    /// #if_succeeds {:msg "previous epoch endTime must never be zero"} mapEpochTokenomics[epochCounter - 1].epochPoint.endTime > 0;
    /// #if_succeeds {:msg "when the year is the same, the adjusted maxBond (incentives[4]) will never be lower than the epoch maxBond"}
    ///$result == true && (block.timestamp - timeLaunch) / ONE_YEAR == old(currentYear)
    /// ==> old((inflationPerSecond * (block.timestamp - mapEpochTokenomics[epochCounter - 1].epochPoint.endTime) * mapEpochTokenomics[epochCounter].epochPoint.maxBondFraction) / 100) >= old(maxBond);
    /// #if_succeeds {:msg "idf check"} $result == true ==> mapEpochTokenomics[epochCounter].epochPoint.idf >= 1e18 && mapEpochTokenomics[epochCounter].epochPoint.idf <= 18e18;
    /// #if_succeeds {:msg "devsPerCapital check"} $result == true ==> devsPerCapital > MIN_PARAM_VALUE;
    /// #if_succeeds {:msg "codePerDev check"} $result == true ==> codePerDev > MIN_PARAM_VALUE;
    /// #if_succeeds {:msg "sum of reward fractions must result in 100"} $result == true
    /// ==> mapEpochTokenomics[epochCounter].unitPoints[0].rewardUnitFraction + mapEpochTokenomics[epochCounter].unitPoints[1].rewardUnitFraction + mapEpochTokenomics[epochCounter].epochPoint.rewardTreasuryFraction == 100;
    function checkpoint() external returns (bool) {
        // Get the implementation address that was written to the proxy contract
        address implementation;
        assembly {
            implementation := sload(PROXY_TOKENOMICS)
        }
        // Check if there is any address in the PROXY_TOKENOMICS address slot
        if (implementation == address(0)) {
            revert DelegatecallOnly();
        }

        // Check the last donation block number to avoid the possibility of a flash loan attack
        if (lastDonationBlockNumber == block.number) {
            revert SameBlockNumberViolation();
        }

        // New point can be calculated only if we passed the number of blocks equal to the epoch length
        uint256 prevEpochTime = mapEpochTokenomics[epochCounter - 1].epochPoint.endTime;
        uint256 diffNumSeconds = block.timestamp - prevEpochTime;
        uint256 curEpochLen = epochLen;
        // Check if the time passed since the last epoch end time is bigger than the specified epoch length,
        // but not bigger than a year in seconds
        if (diffNumSeconds < curEpochLen || diffNumSeconds > ONE_YEAR) {
            return false;
        }

        uint256 eCounter = epochCounter;
        TokenomicsPoint storage tp = mapEpochTokenomics[eCounter];

        // 0: total incentives funded with donations in ETH, that are split between:
        // 1: treasuryRewards, 2: componentRewards, 3: agentRewards
        // OLAS inflation is split between:
        // 4: maxBond, 5: component ownerTopUps, 6: agent ownerTopUps
        uint256[] memory incentives = new uint256[](7);
        incentives[0] = tp.epochPoint.totalDonationsETH;
        incentives[1] = (incentives[0] * tp.epochPoint.rewardTreasuryFraction) / 100;
        // 0 stands for components and 1 for agents
        incentives[2] = (incentives[0] * tp.unitPoints[0].rewardUnitFraction) / 100;
        incentives[3] = (incentives[0] * tp.unitPoints[1].rewardUnitFraction) / 100;

        // The actual inflation per epoch considering that it is settled not in the exact epochLen time, but a bit later
        uint256 inflationPerEpoch;
        // Record the current inflation per second
        uint256 curInflationPerSecond = inflationPerSecond;
        // Current year
        uint256 numYears = (block.timestamp - timeLaunch) / ONE_YEAR;
        // Amounts for the yearly inflation change from year to year, so if the year changes in the middle
        // of the epoch, it is necessary to adjust epoch inflation numbers to account for the year change
        if (numYears > currentYear) {
            // Calculate remainder of inflation for the passing year
            // End of the year timestamp
            uint256 yearEndTime = timeLaunch + numYears * ONE_YEAR;
            // Initial inflation per epoch during the end of the year minus previous epoch timestamp
            inflationPerEpoch = (yearEndTime - prevEpochTime) * curInflationPerSecond;
            // Recalculate the inflation per second based on the new inflation for the current year
            curInflationPerSecond = getInflationForYear(numYears) / ONE_YEAR;
            // Add the remainder of inflation amount for this epoch based on a new inflation per second ratio
            inflationPerEpoch += (block.timestamp - yearEndTime) * curInflationPerSecond;
            // Updating state variables
            inflationPerSecond = uint96(curInflationPerSecond);
            currentYear = uint8(numYears);
            // Set the tokenomics parameters flag such that the maxBond is correctly updated below (3rd bit is set to one)
            tokenomicsParametersUpdated = tokenomicsParametersUpdated | 0x04;
        } else {
            // Inflation per epoch is equal to the inflation per second multiplied by the actual time of the epoch
            inflationPerEpoch = curInflationPerSecond * diffNumSeconds;
        }

        // Bonding and top-ups in OLAS are recalculated based on the inflation schedule per epoch
        // Actual maxBond of the epoch
        tp.epochPoint.totalTopUpsOLAS = uint96(inflationPerEpoch);
        incentives[4] = (inflationPerEpoch * tp.epochPoint.maxBondFraction) / 100;

        // Get the maxBond that was credited to effectiveBond during this settled epoch
        // If the year changes, the maxBond for the next epoch is updated in the condition below and will be used
        // later when the effectiveBond is updated for the next epoch
        uint256 curMaxBond = maxBond;

        // Effective bond accumulates bonding leftovers from previous epochs (with the last max bond value set)
        // It is given the value of the maxBond for the next epoch as a credit
        // The difference between recalculated max bond per epoch and maxBond value must be reflected in effectiveBond,
        // since the epoch checkpoint delay was not accounted for initially
        // This has to be always true, or incentives[4] == curMaxBond if the epoch is settled exactly at the epochLen time
        if (incentives[4] > curMaxBond) {
            // Adjust the effectiveBond
            incentives[4] = effectiveBond + incentives[4] - curMaxBond;
            effectiveBond = uint96(incentives[4]);
        }

        // Get the tokenomics point of the next epoch
        TokenomicsPoint storage nextEpochPoint = mapEpochTokenomics[eCounter + 1];
        // Update incentive fractions for the next epoch if they were requested by the changeIncentiveFractions() function
        // Check if the second bit is set to one
        if (tokenomicsParametersUpdated & 0x02 == 0x02) {
            // Confirm the change of incentive fractions
            emit IncentiveFractionsUpdated(eCounter + 1);
        } else {
            // Copy current tokenomics point into the next one such that it has necessary tokenomics parameters
            for (uint256 i = 0; i < 2; ++i) {
                nextEpochPoint.unitPoints[i].topUpUnitFraction = tp.unitPoints[i].topUpUnitFraction;
                nextEpochPoint.unitPoints[i].rewardUnitFraction = tp.unitPoints[i].rewardUnitFraction;
            }
            nextEpochPoint.epochPoint.rewardTreasuryFraction = tp.epochPoint.rewardTreasuryFraction;
            nextEpochPoint.epochPoint.maxBondFraction = tp.epochPoint.maxBondFraction;
        }
        // Update parameters for the next epoch, if changes were requested by the changeTokenomicsParameters() function
        // Check if the second bit is set to one
        if (tokenomicsParametersUpdated & 0x01 == 0x01) {
            // Update epoch length and set the next value back to zero
            if (nextEpochLen > 0) {
                curEpochLen = nextEpochLen;
                epochLen = uint32(curEpochLen);
                nextEpochLen = 0;
            }

            // Update veOLAS threshold and set the next value back to zero
            if (nextVeOLASThreshold > 0) {
                veOLASThreshold = nextVeOLASThreshold;
                nextVeOLASThreshold = 0;
            }

            // Confirm the change of tokenomics parameters
            emit TokenomicsParametersUpdated(eCounter + 1);
        }
        // Record settled epoch timestamp
        tp.epochPoint.endTime = uint32(block.timestamp);

        // Adjust max bond value if the next epoch is going to be the year change epoch
        // Note that this computation happens before the epoch that is triggered in the next epoch (the code above) when
        // the actual year changes
        numYears = (block.timestamp + curEpochLen - timeLaunch) / ONE_YEAR;
        // Account for the year change to adjust the max bond
        if (numYears > currentYear) {
            // Calculate the inflation remainder for the passing year
            // End of the year timestamp
            uint256 yearEndTime = timeLaunch + numYears * ONE_YEAR;
            // Calculate the inflation per epoch value until the end of the year
            inflationPerEpoch = (yearEndTime - block.timestamp) * curInflationPerSecond;
            // Recalculate the inflation per second based on the new inflation for the current year
            curInflationPerSecond = getInflationForYear(numYears) / ONE_YEAR;
            // Add the remainder of the inflation for the next epoch based on a new inflation per second ratio
            inflationPerEpoch += (block.timestamp + curEpochLen - yearEndTime) * curInflationPerSecond;
            // Calculate the max bond value
            curMaxBond = (inflationPerEpoch * nextEpochPoint.epochPoint.maxBondFraction) / 100;
            // Update state maxBond value
            maxBond = uint96(curMaxBond);
            // Reset the tokenomics parameters update flag
            tokenomicsParametersUpdated = 0;
        } else if (tokenomicsParametersUpdated > 0) {
            // Since tokenomics parameters have been updated, maxBond has to be recalculated
            curMaxBond = (curEpochLen * curInflationPerSecond * nextEpochPoint.epochPoint.maxBondFraction) / 100;
            // Update state maxBond value
            maxBond = uint96(curMaxBond);
            // Reset the tokenomics parameters update flag
            tokenomicsParametersUpdated = 0;
        }
        // Update effectiveBond with the current or updated maxBond value
        curMaxBond += effectiveBond;
        effectiveBond = uint96(curMaxBond);

        // Update the IDF value for the next epoch or assign a default one if there are no ETH donations
        if (incentives[0] > 0) {
            // Calculate IDF based on the incoming donations
            uint256 idf = _calculateIDF(incentives[1], tp.epochPoint.numNewOwners);
            nextEpochPoint.epochPoint.idf = uint64(idf);
            emit IDFUpdated(idf);
        } else {
            // Assign a default IDF value
            nextEpochPoint.epochPoint.idf = 1e18;
        }

        // Cumulative incentives
        uint256 accountRewards = incentives[2] + incentives[3];
        // Owner top-ups: epoch incentives for component owners funded with the inflation
        incentives[5] = (inflationPerEpoch * tp.unitPoints[0].topUpUnitFraction) / 100;
        // Owner top-ups: epoch incentives for agent owners funded with the inflation
        incentives[6] = (inflationPerEpoch * tp.unitPoints[1].topUpUnitFraction) / 100;
        // Even if there was no single donating service owner that had a sufficient veOLAS balance,
        // we still record the amount of OLAS allocated for component / agent owner top-ups from the inflation schedule.
        // This amount will appear in the EpochSettled event, and thus can be tracked historically
        uint256 accountTopUps = incentives[5] + incentives[6];

        // Treasury contract rebalances ETH funds depending on the treasury rewards
        if (incentives[1] == 0 || ITreasury(treasury).rebalanceTreasury(incentives[1])) {
            // Emit settled epoch written to the last economics point
            emit EpochSettled(eCounter, incentives[1], accountRewards, accountTopUps);
            // Start new epoch
            epochCounter = uint32(eCounter + 1);
        } else {
            // If the treasury rebalance was not executed correctly, the new epoch does not start
            revert TreasuryRebalanceFailed(eCounter);
        }

        return true;
    }

    /// @dev Gets component / agent owner incentives and clears the balances.
    /// @notice `account` must be the owner of components / agents Ids, otherwise the function will revert.
    /// @notice If not all `unitIds` belonging to `account` were provided, they will be untouched and keep accumulating.
    /// @notice Component and agent Ids must be provided in the ascending order and must not repeat.
    /// @param account Account address.
    /// @param unitTypes Set of unit types (component / agent).
    /// @param unitIds Set of corresponding unit Ids where account is the owner.
    /// @return reward Reward amount.
    /// @return topUp Top-up amount.
    function accountOwnerIncentives(address account, uint256[] memory unitTypes, uint256[] memory unitIds) external
        returns (uint256 reward, uint256 topUp)
    {
        // Check for the dispenser access
        if (dispenser != msg.sender) {
            revert ManagerOnly(msg.sender, dispenser);
        }

        // Check array lengths
        if (unitTypes.length != unitIds.length) {
            revert WrongArrayLength(unitTypes.length, unitIds.length);
        }

        // Component / agent registry addresses
        address[] memory registries = new address[](2);
        (registries[0], registries[1]) = (componentRegistry, agentRegistry);

        // Component / agent total supply
        uint256[] memory registriesSupply = new uint256[](2);
        for (uint256 i = 0; i < 2; ++i) {
            registriesSupply[i] = IToken(registries[i]).totalSupply();
        }

        // Check the input data
        uint256[] memory lastIds = new uint256[](2);
        for (uint256 i = 0; i < unitIds.length; ++i) {
            // Check for the unit type to be component / agent only
            if (unitTypes[i] > 1) {
                revert Overflow(unitTypes[i], 1);
            }

            // Check that the unit Ids are in ascending order, not repeating, and no bigger than registries total supply
            if (unitIds[i] <= lastIds[unitTypes[i]] || unitIds[i] > registriesSupply[unitTypes[i]]) {
                revert WrongUnitId(unitIds[i], unitTypes[i]);
            }
            lastIds[unitTypes[i]] = unitIds[i];

            // Check the component / agent Id ownership
            address unitOwner = IToken(registries[unitTypes[i]]).ownerOf(unitIds[i]);
            if (unitOwner != account) {
                revert OwnerOnly(unitOwner, account);
            }
        }

        // Get the current epoch counter
        uint256 curEpoch = epochCounter;

        for (uint256 i = 0; i < unitIds.length; ++i) {
            // Get the last epoch number the incentives were accumulated for
            uint256 lastEpoch = mapUnitIncentives[unitTypes[i]][unitIds[i]].lastEpoch;
            // Finalize unit rewards and top-ups if there were pending ones from the previous epoch
            // The finalization is needed when the trackServiceDonations() function did not take care of it
            // since between last epoch the donations were received and this current epoch there were no more donations
            if (lastEpoch > 0 && lastEpoch < curEpoch) {
                _finalizeIncentivesForUnitId(lastEpoch, unitTypes[i], unitIds[i]);
                // Change the last epoch number
                mapUnitIncentives[unitTypes[i]][unitIds[i]].lastEpoch = 0;
            }

            // Accumulate total rewards and clear their balances
            reward += mapUnitIncentives[unitTypes[i]][unitIds[i]].reward;
            mapUnitIncentives[unitTypes[i]][unitIds[i]].reward = 0;
            // Accumulate total top-ups and clear their balances
            topUp += mapUnitIncentives[unitTypes[i]][unitIds[i]].topUp;
            mapUnitIncentives[unitTypes[i]][unitIds[i]].topUp = 0;
        }
    }

    /// @dev Gets the component / agent owner incentives.
    /// @notice `account` must be the owner of components / agents they are passing, otherwise the function will revert.
    /// @param account Account address.
    /// @param unitTypes Set of unit types (component / agent).
    /// @param unitIds Set of corresponding unit Ids where account is the owner.
    /// @return reward Reward amount.
    /// @return topUp Top-up amount.
    function getOwnerIncentives(address account, uint256[] memory unitTypes, uint256[] memory unitIds) external view
        returns (uint256 reward, uint256 topUp)
    {
        // Check array lengths
        if (unitTypes.length != unitIds.length) {
            revert WrongArrayLength(unitTypes.length, unitIds.length);
        }

        // Component / agent registry addresses
        address[] memory registries = new address[](2);
        (registries[0], registries[1]) = (componentRegistry, agentRegistry);

        // Component / agent total supply
        uint256[] memory registriesSupply = new uint256[](2);
        for (uint256 i = 0; i < 2; ++i) {
            registriesSupply[i] = IToken(registries[i]).totalSupply();
        }

        // Check the input data
        uint256[] memory lastIds = new uint256[](2);
        for (uint256 i = 0; i < unitIds.length; ++i) {
            // Check for the unit type to be component / agent only
            if (unitTypes[i] > 1) {
                revert Overflow(unitTypes[i], 1);
            }

            // Check that the unit Ids are in ascending order, not repeating, and no bigger than registries total supply
            if (unitIds[i] <= lastIds[unitTypes[i]] || unitIds[i] > registriesSupply[unitTypes[i]]) {
                revert WrongUnitId(unitIds[i], unitTypes[i]);
            }
            lastIds[unitTypes[i]] = unitIds[i];

            // Check the component / agent Id ownership
            address unitOwner = IToken(registries[unitTypes[i]]).ownerOf(unitIds[i]);
            if (unitOwner != account) {
                revert OwnerOnly(unitOwner, account);
            }
        }

        // Get the current epoch counter
        uint256 curEpoch = epochCounter;

        for (uint256 i = 0; i < unitIds.length; ++i) {
            // Get the last epoch number the incentives were accumulated for
            uint256 lastEpoch = mapUnitIncentives[unitTypes[i]][unitIds[i]].lastEpoch;
            // Calculate rewards and top-ups if there were pending ones from the previous epoch
            if (lastEpoch > 0 && lastEpoch < curEpoch) {
                // Get the overall amount of unit rewards for the component's last epoch
                // reward = (pendingRelativeReward * rewardUnitFraction) / 100
                uint256 totalIncentives = mapUnitIncentives[unitTypes[i]][unitIds[i]].pendingRelativeReward;
                if (totalIncentives > 0) {
                    totalIncentives *= mapEpochTokenomics[lastEpoch].unitPoints[unitTypes[i]].rewardUnitFraction;
                    // Accumulate to the final reward for the last epoch
                    reward += totalIncentives / 100;
                }
                // Add the final top-up for the last epoch
                totalIncentives = mapUnitIncentives[unitTypes[i]][unitIds[i]].pendingRelativeTopUp;
                if (totalIncentives > 0) {
                    // Summation of all the unit top-ups and total amount of top-ups per epoch
                    // topUp = (pendingRelativeTopUp * totalTopUpsOLAS * topUpUnitFraction) / (100 * sumUnitTopUpsOLAS)
                    totalIncentives *= mapEpochTokenomics[lastEpoch].epochPoint.totalTopUpsOLAS;
                    totalIncentives *= mapEpochTokenomics[lastEpoch].unitPoints[unitTypes[i]].topUpUnitFraction;
                    uint256 sumUnitIncentives = uint256(mapEpochTokenomics[lastEpoch].unitPoints[unitTypes[i]].sumUnitTopUpsOLAS) * 100;
                    // Accumulate to the final top-up for the last epoch
                    topUp += totalIncentives / sumUnitIncentives;
                }
            }

            // Accumulate total rewards to finalized ones
            reward += mapUnitIncentives[unitTypes[i]][unitIds[i]].reward;
            // Accumulate total top-ups to finalized ones
            topUp += mapUnitIncentives[unitTypes[i]][unitIds[i]].topUp;
        }
    }

    /// @dev Gets inflation per last epoch.
    /// @return inflationPerEpoch Inflation value.
    function getInflationPerEpoch() external view returns (uint256 inflationPerEpoch) {
        inflationPerEpoch = inflationPerSecond * epochLen;
    }

    /// @dev Gets component / agent point of a specified epoch number and a unit type.
    /// @param epoch Epoch number.
    /// @param unitType Component (0) or agent (1).
    /// @return up Unit point.
    function getUnitPoint(uint256 epoch, uint256 unitType) external view returns (UnitPoint memory up) {
        up = mapEpochTokenomics[epoch].unitPoints[unitType];
    }

    /// @dev Gets inverse discount factor with the multiple of 1e18.
    /// @param epoch Epoch number.
    /// @return idf Discount factor with the multiple of 1e18.
    function getIDF(uint256 epoch) external view returns (uint256 idf)
    {
        idf = mapEpochTokenomics[epoch].epochPoint.idf;
        if (idf == 0) {
            idf = 1e18;
        }
    }

    /// @dev Gets inverse discount factor with the multiple of 1e18 of the last epoch.
    /// @return idf Discount factor with the multiple of 1e18.
    function getLastIDF() external view returns (uint256 idf)
    {
        idf = mapEpochTokenomics[epochCounter - 1].epochPoint.idf;
        if (idf == 0) {
            idf = 1e18;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@prb/math/src/UD60x18.sol";

/// @title TokenomicsConstants - Smart contract with tokenomics constants
/// @author AL
/// @author Aleksandr Kuperman - <[email protected]>
abstract contract TokenomicsConstants {
    // Tokenomics version number
    string public constant VERSION = "1.0.0";
    // Tokenomics proxy address slot
    // keccak256("PROXY_TOKENOMICS") = "0xbd5523e7c3b6a94aa0e3b24d1120addc2f95c7029e097b466b2bedc8d4b4362f"
    bytes32 public constant PROXY_TOKENOMICS = 0xbd5523e7c3b6a94aa0e3b24d1120addc2f95c7029e097b466b2bedc8d4b4362f;
    // One year in seconds
    uint256 public constant ONE_YEAR = 1 days * 365;
    // Minimum epoch length
    uint256 public constant MIN_EPOCH_LENGTH = 1 weeks;
    // Minimum fixed point tokenomics parameters
    uint256 public constant MIN_PARAM_VALUE = 1e14;

    /// @dev Gets an inflation cap for a specific year.
    /// @param numYears Number of years passed from the launch date.
    /// @return supplyCap Supply cap.
    /// supplyCap = 1e27 * (1.02)^(x-9) for x >= 10
    /// if_succeeds {:msg "correct supplyCap"} (numYears >= 10) ==> (supplyCap > 1e27);  
    /// There is a bug in scribble tools, a broken instrumented version is as follows:
    /// function getSupplyCapForYear(uint256 numYears) public returns (uint256 supplyCap)
    /// And the test is waiting for a view / pure function, which would be correct
    function getSupplyCapForYear(uint256 numYears) public pure returns (uint256 supplyCap) {
        // For the first 10 years the supply caps are pre-defined
        if (numYears < 10) {
            uint96[10] memory supplyCaps = [
                529_659_000_00e16,
                569_913_084_00e16,
                641_152_219_50e16,
                708_500_141_72e16,
                771_039_876_00e16,
                828_233_282_97e16,
                879_860_040_11e16,
                925_948_139_65e16,
                966_706_331_40e16,
                1_000_000_000e18
            ];
            supplyCap = supplyCaps[numYears];
        } else {
            // Number of years after ten years have passed (including ongoing ones)
            numYears -= 9;
            // Max cap for the first 10 years
            supplyCap = 1_000_000_000e18;
            // After that the inflation is 2% per year as defined by the OLAS contract
            uint256 maxMintCapFraction = 2;

            // Get the supply cap until the current year
            for (uint256 i = 0; i < numYears; ++i) {
                supplyCap += (supplyCap * maxMintCapFraction) / 100;
            }
            // Return the difference between last two caps (inflation for the current year)
            return supplyCap;
        }
    }

    /// @dev Gets an inflation amount for a specific year.
    /// @param numYears Number of years passed from the launch date.
    /// @return inflationAmount Inflation limit amount.
    function getInflationForYear(uint256 numYears) public pure returns (uint256 inflationAmount) {
        // For the first 10 years the inflation caps are pre-defined as differences between next year cap and current year one
        if (numYears < 10) {
            // Initial OLAS allocation is 526_500_000_0e17
            uint88[10] memory inflationAmounts = [
                3_159_000_00e16,
                40_254_084_00e16,
                71_239_135_50e16,
                67_347_922_22e16,
                62_539_734_28e16,
                57_193_406_97e16,
                51_626_757_14e16,
                46_088_099_54e16,
                40_758_191_75e16,
                33_293_668_60e16
            ];
            inflationAmount = inflationAmounts[numYears];
        } else {
            // Number of years after ten years have passed (including ongoing ones)
            numYears -= 9;
            // Max cap for the first 10 years
            uint256 supplyCap = 1_000_000_000e18;
            // After that the inflation is 2% per year as defined by the OLAS contract
            uint256 maxMintCapFraction = 2;

            // Get the supply cap until the year before the current year
            for (uint256 i = 1; i < numYears; ++i) {
                supplyCap += (supplyCap * maxMintCapFraction) / 100;
            }

            // Inflation amount is the difference between last two caps (inflation for the current year)
            inflationAmount = (supplyCap * maxMintCapFraction) / 100;
        }
    }
}