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

        // Set the initial guess to the least power of two that is greater than or equal to sqrt(x).
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IERC3156FlashBorrower {

    /**
     * @dev    Receive a flash loan.
     * @param  initiator The initiator of the loan.
     * @param  token     The loan currency.
     * @param  amount    The amount of tokens lent.
     * @param  fee       The additional amount of tokens to repay.
     * @param  data      Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes   calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;
import { IERC3156FlashBorrower } from "./IERC3156FlashBorrower.sol";


interface IERC3156FlashLender {

    /**
     * @dev    The amount of currency available to be lent.
     * @param  token_ The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(
        address token_
    ) external view returns (uint256);

    /**
     * @dev    The fee to be charged for a given loan.
     * @param  token_    The loan currency.
     * @param  amount_   The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(
        address token_,
        uint256 amount_
    ) external view returns (uint256);

    /**
     * @dev    Initiate a flash loan.
     * @param  receiver_ The receiver of the tokens in the loan, and the receiver of the callback.
     * @param  token_    The loan currency.
     * @param  amount_   The amount of tokens lent.
     * @param  data_     Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver_,
        address token_,
        uint256 amount_,
        bytes   calldata data_
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { IPoolLenderActions }         from './commons/IPoolLenderActions.sol';
import { IPoolLiquidationActions }    from './commons/IPoolLiquidationActions.sol';
import { IPoolReserveAuctionActions } from './commons/IPoolReserveAuctionActions.sol';
import { IPoolImmutables }            from './commons/IPoolImmutables.sol';
import { IPoolState }                 from './commons/IPoolState.sol';
import { IPoolDerivedState }          from './commons/IPoolDerivedState.sol';
import { IPoolEvents }                from './commons/IPoolEvents.sol';
import { IPoolErrors }                from './commons/IPoolErrors.sol';
import { IERC3156FlashLender }        from './IERC3156FlashLender.sol';

/**
 * @title Base Pool
 */
interface IPool is
    IPoolLenderActions,
    IPoolLiquidationActions,
    IPoolReserveAuctionActions,
    IPoolImmutables,
    IPoolState,
    IPoolDerivedState,
    IPoolEvents,
    IPoolErrors,
    IERC3156FlashLender
{

}

enum PoolType { ERC20, ERC721 }

interface IERC20Token {
    function balanceOf(address account) external view returns (uint256);
    function burn(uint256 amount) external;
    function decimals() external view returns (uint8);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC721Token {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

/**
 * @title Pool Derived State
 */
interface IPoolDerivedState {

    function bucketExchangeRate(
        uint256 index_
    ) external view returns (uint256 exchangeRate_);

    /**
     *  @notice Returns the bucket index for a given debt amount.
     *  @param  debt_  The debt amount to calculate bucket index for.
     *  @return Bucket index.
     */
    function depositIndex(
        uint256 debt_
    ) external view returns (uint256);

    /**
     *  @notice Returns the total amount of quote tokens deposited in pool.
     *  @return Total amount of deposited quote tokens.
     */
    function depositSize() external view returns (uint256);

    /**
     *  @notice Returns the deposit utilization for given debt and collateral amounts.
     *  @param  debt_       The debt amount to calculate utilization for.
     *  @param  collateral_ The collateral amount to calculate utilization for.
     *  @return Deposit utilization.
     */
    function depositUtilization(
        uint256 debt_,
        uint256 collateral_
    ) external view returns (uint256);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

/**
 * @title Pool Errors
 */
interface IPoolErrors {
    /**************************/
    /*** Common Pool Errors ***/
    /**************************/

    /**
     *  @notice The action cannot be executed on an active auction.
     */
    error AuctionActive();

    /**
     *  @notice Attempted auction to clear doesn't meet conditions.
     */
    error AuctionNotClearable();

    /**
     *  @notice Head auction should be cleared prior of executing this action.
     */
    error AuctionNotCleared();

    /**
     *  @notice The auction price is greater than the arbed bucket price.
     */
    error AuctionPriceGtBucketPrice();

    /**
     *  @notice Pool already initialized.
     */
    error AlreadyInitialized();

    /**
     *  @notice Borrower is attempting to create or modify a loan such that their loan's quote token would be less than the pool's minimum debt amount.
     */
    error AmountLTMinDebt();

    /**
     *  @notice Recipient of borrowed quote tokens doesn't match the caller of the drawDebt function.
     */
    error BorrowerNotSender();

    /**
     *  @notice Borrower has a healthy over-collateralized position.
     */
    error BorrowerOk();

    /**
     *  @notice Borrower is attempting to borrow more quote token than they have collateral for.
     */
    error BorrowerUnderCollateralized();

    /**
     *  @notice Operation cannot be executed in the same block when bucket becomes insolvent.
     */
    error BucketBankruptcyBlock();

    /**
     *  @notice User attempted to merge collateral from a lower price bucket into a higher price bucket.
     */
    error CannotMergeToHigherPrice();

    /**
     *  @notice User attempted an operation which does not exceed the dust amount, or leaves behind less than the dust amount.
     */
    error DustAmountNotExceeded();

    /**
     *  @notice Callback invoked by flashLoan function did not return the expected hash (see ERC-3156 spec).
     */
    error FlashloanCallbackFailed();

    /**
     *  @notice Pool cannot facilitate a flashloan for the specified token address.
     */
    error FlashloanUnavailableForToken();

    /**
     *  @notice User is attempting to move or pull more collateral than is available.
     */
    error InsufficientCollateral();

    /**
     *  @notice Lender is attempting to move or remove more collateral they have claim to in the bucket.
     *  @notice Lender is attempting to remove more collateral they have claim to in the bucket.
     *  @notice Lender must have enough LP tokens to claim the desired amount of quote from the bucket.
     */
    error InsufficientLPs();

    /**
     *  @notice Bucket must have more quote available in the bucket than the lender is attempting to claim.
     */
    error InsufficientLiquidity();

    /**
     *  @notice When transferring LP tokens between indices, the new index must be a valid index.
     */
    error InvalidIndex();

    /**
     *  @notice Borrower is attempting to borrow more quote token than is available before the supplied limitIndex.
     */
    error LimitIndexReached();

    /**
     *  @notice When moving quote token HTP must stay below LUP.
     *  @notice When removing quote token HTP must stay below LUP.
     */
    error LUPBelowHTP();

    /**
     *  @notice Liquidation must result in LUP below the borrowers threshold price.
     */
    error LUPGreaterThanTP();

    /**
     *  @notice FromIndex_ and toIndex_ arguments to move are the same.
     */
    error MoveToSamePrice();

    /**
     *  @notice Owner of the LP tokens must have approved the new owner prior to transfer.
     */
    error NoAllowance();

    /**
     *  @notice Actor is attempting to take or clear an inactive auction.
     */
    error NoAuction();

    /**
     *  @notice No pool reserves are claimable.
     */
    error NoReserves();

    /**
     *  @notice Actor is attempting to take or clear an inactive reserves auction.
     */
    error NoReservesAuction();

    /**
     *  @notice Lender must have non-zero LPB when attemptign to remove quote token from the pool.
     */
    error NoClaim();

    /**
     *  @notice Borrower has no debt to liquidate.
     *  @notice Borrower is attempting to repay when they have no outstanding debt.
     */
    error NoDebt();

    /**
     *  @notice Borrower is attempting to borrow an amount of quote tokens that will push the pool into under-collateralization.
     */
    error PoolUnderCollateralized();

    /**
     *  @notice Actor is attempting to remove using a bucket with price below the LUP.
     */
    error PriceBelowLUP();

    /**
     *  @notice Lender is attempting to remove quote tokens from a bucket that exists above active auction debt from top-of-book downward.
     */
    error RemoveDepositLockedByAuctionDebt();

    /**
     * @notice User attempted to kick off a new auction less than 2 weeks since the last auction completed.
     */
    error ReserveAuctionTooSoon();

    /**
     *  @notice Take was called before 1 hour had passed from kick time.
     */
    error TakeNotPastCooldown();

    /**
     *  @notice The threshold price of the loan to be inserted in loans heap is zero.
     */
    error ZeroThresholdPrice();

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

/**
 * @title Pool Events
 */
interface IPoolEvents {
    /**
     *  @notice Emitted when lender adds quote token to the pool.
     *  @param  lender    Recipient that added quote tokens.
     *  @param  price     Price at which quote tokens were added.
     *  @param  amount    Amount of quote tokens added to the pool.
     *  @param  lpAwarded Amount of LP awarded for the deposit. 
     *  @param  lup       LUP calculated after deposit.
     */
    event AddQuoteToken(
        address indexed lender,
        uint256 indexed price,
        uint256 amount,
        uint256 lpAwarded,
        uint256 lup
    );

    /**
     *  @notice Emitted when auction is completed.
     *  @param  borrower   Address of borrower that exits auction.
     *  @param  collateral Borrower's remaining collateral when auction completed.
     */
    event AuctionSettle(
        address indexed borrower,
        uint256 collateral
    );

    /**
     *  @notice Emitted when NFT auction is completed.
     *  @param  borrower   Address of borrower that exits auction.
     *  @param  collateral Borrower's remaining collateral when auction completed.
     *  @param  lps        Amount of LPs given to the borrower to compensate fractional collateral (if any).
     *  @param  index      Index of the bucket with LPs to compensate fractional collateral.
     */
    event AuctionNFTSettle(
        address indexed borrower,
        uint256 collateral,
        uint256 lps,
        uint256 index
    );

    /**
     *  @notice Emitted when LPs are forfeited as a result of the bucket losing all assets.
     *  @param  index       The index of the bucket.
     *  @param  lpForfeited Amount of LP forfeited by lenders.
     */
    event BucketBankruptcy(
        uint256 indexed index,
        uint256 lpForfeited
    );

    /**
     *  @notice Emitted when an actor uses quote token to arb higher-priced deposit off the book.
     *  @param  borrower    Identifies the loan being liquidated.
     *  @param  index       The index of the Highest Price Bucket used for this take.
     *  @param  amount      Amount of quote token used to purchase collateral.
     *  @param  collateral  Amount of collateral purchased with quote token.
     *  @param  bondChange  Impact of this take to the liquidation bond.
     *  @param  isReward    True if kicker was rewarded with `bondChange` amount, false if kicker was penalized.
     *  @dev    amount / collateral implies the auction price.
     */
    event BucketTake(
        address indexed borrower,
        uint256 index,
        uint256 amount,
        uint256 collateral,
        uint256 bondChange,
        bool    isReward
    );

    /**
     *  @notice Emitted when LPs are awarded to a taker or kicker in a bucket take.
     *  @param  taker           Actor who invoked the bucket take.
     *  @param  kicker          Actor who started the auction.
     *  @param  lpAwardedTaker  Amount of LP awarded to the taker.
     *  @param  lpAwardedKicker Amount of LP awarded to the actor who started the auction.
     */
    event BucketTakeLPAwarded(
        address indexed taker,
        address indexed kicker,
        uint256 lpAwardedTaker,
        uint256 lpAwardedKicker
    );

    /**
     *  @notice Emitted when an actor settles debt in a completed liquidation
     *  @param  borrower   Identifies the loan under liquidation.
     *  @param  settledDebt Amount of pool debt settled in this transaction.
     *  @dev    When amountRemaining_ == 0, the auction has been completed cleared and removed from the queue.
     */
    event Settle(
        address indexed borrower,
        uint256 settledDebt
    );

    /**
     *  @notice Emitted when a liquidation is initiated.
     *  @param  borrower   Identifies the loan being liquidated.
     *  @param  debt       Debt the liquidation will attempt to cover.
     *  @param  collateral Amount of collateral up for liquidation.
     *  @param  bond       Bond amount locked by kicker
     */
    event Kick(
        address indexed borrower,
        uint256 debt,
        uint256 collateral,
        uint256 bond
    );

    /**
     *  @notice Emitted when lender moves quote token from a bucket price to another.
     *  @param  lender         Recipient that moved quote tokens.
     *  @param  from           Price bucket from which quote tokens were moved.
     *  @param  to             Price bucket where quote tokens were moved.
     *  @param  amount         Amount of quote tokens moved.
     *  @param  lpRedeemedFrom Amount of LP removed from the `from` bucket.
     *  @param  lpAwardedTo    Amount of LP credited to the `to` bucket.
     *  @param  lup            LUP calculated after removal.
     */
    event MoveQuoteToken(
        address indexed lender,
        uint256 indexed from,
        uint256 indexed to,
        uint256 amount,
        uint256 lpRedeemedFrom,
        uint256 lpAwardedTo,
        uint256 lup
    );

    /**
     *  @notice Emitted when lender claims collateral from a bucket.
     *  @param  claimer    Recipient that claimed collateral.
     *  @param  price      Price at which collateral was claimed.
     *  @param  amount     The amount of collateral (or number of NFT tokens) transferred to the claimer.
     *  @param  lpRedeemed Amount of LP exchanged for quote token.
     */
    event RemoveCollateral(
        address indexed claimer,
        uint256 indexed price,
        uint256 amount,
        uint256 lpRedeemed
    );

    /**
     *  @notice Emitted when lender removes quote token from the pool.
     *  @param  lender     Recipient that removed quote tokens.
     *  @param  price      Price at which quote tokens were removed.
     *  @param  amount     Amount of quote tokens removed from the pool.
     *  @param  lpRedeemed Amount of LP exchanged for quote token.
     *  @param  lup        LUP calculated after removal.
     */
    event RemoveQuoteToken(
        address indexed lender,
        uint256 indexed price,
        uint256 amount,
        uint256 lpRedeemed,
        uint256 lup
    );

    /**
     *  @notice Emitted when borrower repays quote tokens to the pool, and/or pulls collateral from the pool.
     *  @param  borrower         `msg.sender` or on behalf of sender.
     *  @param  quoteRepaid      Amount of quote tokens repaid to the pool.
     *  @param  collateralPulled The amount of collateral (or number of NFT tokens) transferred to the claimer.
     *  @param  lup              LUP after repay.
     */
    event RepayDebt(
        address indexed borrower,
        uint256 quoteRepaid,
        uint256 collateralPulled,
        uint256 lup
    );

    /**
     *  @notice Emitted when a Claimaible Reserve Auction is started or taken.
     *  @return claimableReservesRemaining Amount of claimable reserves which has not yet been taken.
     *  @return auctionPrice               Current price at which 1 quote token may be purchased, denominated in Ajna.
     */
    event ReserveAuction(
        uint256 claimableReservesRemaining,
        uint256 auctionPrice
    );

    /**
     *  @notice Emitted when an actor uses quote token outside of the book to purchase collateral under liquidation.
     *  @param  borrower   Identifies the loan being liquidated.
     *  @param  amount     Amount of quote token used to purchase collateral.
     *  @param  collateral Amount of collateral purchased with quote token (ERC20 pool) or number of NFTs purchased (ERC721 pool).
     *  @param  bondChange Impact of this take to the liquidation bond.
     *  @param  isReward   True if kicker was rewarded with `bondChange` amount, false if kicker was penalized.
     *  @dev    amount / collateral implies the auction price.
     */
    event Take(
        address indexed borrower,
        uint256 amount,
        uint256 collateral,
        uint256 bondChange,
        bool    isReward
    );

    /**
     *  @notice Emitted when a lender transfers their LP tokens to a different address.
     *  @dev    Used by PositionManager.memorializePositions().
     *  @param  owner    The original owner address of the position.
     *  @param  newOwner The new owner address of the position.
     *  @param  indexes  Array of price bucket indexes at which LP tokens were transferred.
     *  @param  lpTokens Amount of LP tokens transferred.
     */
    event TransferLPTokens(
        address owner,
        address newOwner,
        uint256[] indexes,
        uint256 lpTokens
    );

    /**
     *  @notice Emitted when pool interest rate is updated.
     *  @param  oldRate Old pool interest rate.
     *  @param  newRate New pool interest rate.
     */
    event UpdateInterestRate(
        uint256 oldRate,
        uint256 newRate
    );
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

/**
 * @title Pool Immutables
 */
interface IPoolImmutables {

    /**
     *  @notice Returns the type of the pool (0 for ERC20, 1 for ERC721)
     */
    function poolType() external pure returns (uint8);

    /**
     *  @notice Returns the address of the pool's collateral token
     */
    function collateralAddress() external pure returns (address);

    /**
     *  @notice Returns the address of the pools quote token
     */
    function quoteTokenAddress() external pure returns (address);

    /**
     *  @notice Returns the `quoteTokenScale` state variable.
     *  @return The precision of the quote ERC-20 token based on decimals.
     */
    function quoteTokenScale() external pure returns (uint256);

    /**
     *  @notice Returns the minimum amount of quote token a lender may have in a bucket.
     */
    function quoteTokenDust() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

/**
 * @title Internal structs used by the pool / libraries
 */

/*****************************/
/*** Auction Param Structs ***/
/*****************************/

struct BucketTakeResult {
    uint256 collateralAmount;
    uint256 t0RepayAmount;
    uint256 t0DebtPenalty;
    uint256 remainingCollateral;
    uint256 poolDebt;
    uint256 newLup;
    uint256 t0DebtInAuctionChange;
    bool    settledAuction;
}

struct KickResult {
    uint256 amountToCoverBond; // amount of bond that needs to be covered
    uint256 kickPenalty;       // kick penalty
    uint256 t0KickPenalty;     // t0 kick penalty
    uint256 t0KickedDebt;      // new t0 debt after kick
    uint256 lup;               // current lup
}

struct SettleParams {
    address borrower;    // borrower address to settle
    uint256 reserves;    // current reserves in pool
    uint256 inflator;    // current pool inflator
    uint256 bucketDepth; // number of buckets to use when settle debt
    uint256 poolType;    // number of buckets to use when settle debt
}

struct TakeResult {
    uint256 collateralAmount;
    uint256 quoteTokenAmount;
    uint256 t0RepayAmount;
    uint256 t0DebtPenalty;
    uint256 excessQuoteToken;
    uint256 remainingCollateral;
    uint256 poolDebt;
    uint256 newLup;
    uint256 t0DebtInAuctionChange;
    bool    settledAuction;
}

/******************************************/
/*** Liquidity Management Param Structs ***/
/******************************************/

struct AddQuoteParams {
    uint256 amount;          // [WAD] amount to be added
    uint256 index;           // the index in which to deposit
}

struct MoveQuoteParams {
    uint256 fromIndex;       // the deposit index from where amount is moved
    uint256 maxAmountToMove; // [WAD] max amount to move between deposits
    uint256 toIndex;         // the deposit index where amount is moved to
    uint256 thresholdPrice;  // [WAD] max threshold price in pool
}

struct RemoveQuoteParams {
    uint256 index;           // the deposit index from where amount is removed
    uint256 maxAmount;       // [WAD] max amount to be removed
    uint256 thresholdPrice;  // [WAD] max threshold price in pool
}

/*************************************/
/*** Loan Management Param Structs ***/
/*************************************/

struct DrawDebtResult {
    uint256 newLup;                // [WAD] new pool LUP after draw debt
    uint256 poolCollateral;        // [WAD] total amount of collateral in pool after pledge collateral
    uint256 poolDebt;              // [WAD] total accrued debt in pool after draw debt
    uint256 remainingCollateral;   // [WAD] amount of borrower collateral after draw debt (for NFT can be diminished if auction settled)
    bool    settledAuction;        // true if collateral pledged settles auction
    uint256 t0DebtInAuctionChange; // [WAD] change of t0 pool debt in auction after pledge collateral
    uint256 t0DebtChange;          // [WAD] change of total t0 pool debt after after draw debt
}

struct RepayDebtResult {
    uint256 newLup;                // [WAD] new pool LUP after draw debt
    uint256 poolCollateral;        // [WAD] total amount of collateral in pool after pull collateral
    uint256 poolDebt;              // [WAD] total accrued debt in pool after repay debt
    uint256 remainingCollateral;   // [WAD] amount of borrower collateral after pull collateral
    bool    settledAuction;        // true if repay debt settles auction
    uint256 t0DebtInAuctionChange; // [WAD] change of t0 pool debt in auction after repay debt
    uint256 t0RepaidDebt;          // [WAD] amount of t0 repaid debt
    uint256 quoteTokenToRepay;     // [WAD] quote token amount to be transferred from sender to pool
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

/**
 * @title Pool Lender Actions
 */
interface IPoolLenderActions {
    /**
     *  @notice Called by lenders to add an amount of credit at a specified price bucket.
     *  @param  amount    The amount of quote token to be added by a lender.
     *  @param  index     The index of the bucket to which the quote tokens will be added.
     *  @return lpbChange The amount of LP Tokens changed for the added quote tokens.
     */
    function addQuoteToken(
        uint256 amount,
        uint256 index
    ) external returns (uint256 lpbChange);

    /**
     *  @notice Called by lenders to approve transfer of LP tokens to a new owner.
     *  @dev    Intended for use by the PositionManager contract.
     *  @param  allowedNewOwner The new owner of the LP tokens.
     *  @param  index           The index of the bucket from where LPs tokens are transferred.
     *  @param  amount          The amount of LP tokens approved to transfer.
     */
    function approveLpOwnership(
        address allowedNewOwner,
        uint256 index,
        uint256 amount
    ) external;

    /**
     *  @notice Called by lenders to move an amount of credit from a specified price bucket to another specified price bucket.
     *  @param  maxAmount     The maximum amount of quote token to be moved by a lender.
     *  @param  fromIndex     The bucket index from which the quote tokens will be removed.
     *  @param  toIndex       The bucket index to which the quote tokens will be added.
     *  @return lpbAmountFrom The amount of LPs moved out from bucket.
     *  @return lpbAmountTo   The amount of LPs moved to destination bucket.
     */
    function moveQuoteToken(
        uint256 maxAmount,
        uint256 fromIndex,
        uint256 toIndex
    ) external returns (uint256 lpbAmountFrom, uint256 lpbAmountTo);

    /**
     *  @notice Called by lenders to claim collateral from a price bucket.
     *  @param  maxAmount        The amount of collateral (or the number of NFT tokens) to claim.
     *  @param  index            The bucket index from which collateral will be removed.
     *  @return collateralAmount The amount of collateral removed.
     *  @return lpAmount         The amount of LP used for removing collateral amount.
     */
    function removeCollateral(
        uint256 maxAmount,
        uint256 index
    ) external returns (uint256 collateralAmount, uint256 lpAmount);

    /**
     *  @notice Called by lenders to remove an amount of credit at a specified price bucket.
     *  @param  maxAmount        The max amount of quote token to be removed by a lender.
     *  @param  index            The bucket index from which quote tokens will be removed.
     *  @return quoteTokenAmount The amount of quote token removed.
     *  @return lpAmount         The amount of LP used for removing quote tokens amount.
     */
    function removeQuoteToken(
        uint256 maxAmount,
        uint256 index
    ) external returns (uint256 quoteTokenAmount, uint256 lpAmount);

    /**
     *  @notice Called by lenders to transfers their LP tokens to a different address. approveLpOwnership needs to be run first
     *  @dev    Used by PositionManager.memorializePositions().
     *  @param  owner    The original owner address of the position.
     *  @param  newOwner The new owner address of the position.
     *  @param  indexes  Array of price buckets index at which LP tokens were moved.
     */
    function transferLPs(
        address owner,
        address newOwner,
        uint256[] calldata indexes
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

/**
 * @title Pool Liquidation Actions
 */
interface IPoolLiquidationActions {
    /**
     *  @notice Called by actors to use quote token to arb higher-priced deposit off the book.
     *  @param  borrower    Identifies the loan to liquidate.
     *  @param  depositTake If true then the take will happen at an auction price equal with bucket price. Auction price is used otherwise.
     *  @param  index       Index of a bucket, likely the HPB, in which collateral will be deposited.
     */
    function bucketTake(
        address borrower,
        bool    depositTake,
        uint256 index
    ) external;

    /**
     *  @notice Called by actors to settle an amount of debt in a completed liquidation.
     *  @param  borrowerAddress Address of the auctioned borrower.
     *  @param  maxDepth        Measured from HPB, maximum number of buckets deep to settle debt.
     *  @dev    maxDepth is used to prevent unbounded iteration clearing large liquidations.
     */
    function settle(
        address borrowerAddress,
        uint256 maxDepth
    ) external;

    /**
     *  @notice Called by actors to initiate a liquidation.
     *  @param  borrower Identifies the loan to liquidate.
     */
    function kick(
        address borrower
    ) external;

    /**
     *  @notice Called by lenders to liquidate the top loan using their deposits.
     *  @param  index_  The deposit index to use for kicking the top loan.
     */
    function kickWithDeposit(
        uint256 index_
    ) external;

    /**
     *  @notice Called by actors to purchase collateral from the auction in exchange for quote token.
     *  @param  borrower  Address of the borower take is being called upon.
     *  @param  maxAmount Max amount of collateral that will be taken from the auction (max number of NFTs in case of ERC721 pool).
     *  @param  callee    Identifies where collateral should be sent and where quote token should be obtained.
     *  @param  data      If provided, take will assume the callee implements IERC*Taker.  Take will send collateral to 
     *                    callee before passing this data to IERC*Taker.atomicSwapCallback.  If not provided, 
     *                    the callback function will not be invoked.
     */
    function take(
        address        borrower,
        uint256        maxAmount,
        address        callee,
        bytes calldata data
    ) external;

    /**
     *  @notice Called by kickers to withdraw their auction bonds (the amount of quote tokens that are not locked in active auctions).
     */
    function withdrawBonds() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

/**
 * @title Pool Reserve Auction Actions
 */
interface IPoolReserveAuctionActions {
    /**
     *  @notice Called by actor to start a Claimable Reserve Auction (CRA).
     */
    function startClaimableReserveAuction() external;

    /**
     *  @notice Purchases claimable reserves during a CRA using Ajna token.
     *  @param  maxAmount Maximum amount of quote token to purchase at the current auction price.
     *  @return amount    Actual amount of reserves taken.
     */
    function takeReserves(
        uint256 maxAmount
    ) external returns (uint256 amount);
}

/*********************/
/*** Param Structs ***/
/*********************/

struct StartReserveAuctionParams {
    uint256 poolSize;    // [WAD] total deposits in pool (with accrued debt)
    uint256 poolDebt;    // [WAD] current t0 pool debt
    uint256 poolBalance; // [WAD] pool quote token balance
    uint256 inflator;    // [WAD] pool current inflator
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

/**
 * @title Pool State
 */
interface IPoolState {
    /**
     *  @notice Returns details of an auction for a given borrower address.
     *  @param  borrower     Address of the borrower that is liquidated.
     *  @return kicker       Address of the kicker that is kicking the auction.
     *  @return bondFactor   The factor used for calculating bond size.
     *  @return bondSize     The bond amount in quote token terms.
     *  @return kickTime     Time the liquidation was initiated.
     *  @return kickPrice    Highest Price Bucket at time of liquidation.
     *  @return neutralPrice Neutral Price of auction.
     *  @return head         Address of the head auction.
     *  @return next         Address of the next auction in queue.
     *  @return prev         Address of the prev auction in queue.
     */
    function auctionInfo(
        address borrower
    )
        external
        view
        returns (
            address kicker,
            uint256 bondFactor,
            uint256 bondSize,
            uint256 kickTime,
            uint256 kickPrice,
            uint256 neutralPrice,
            address head,
            address next,
            address prev
        );

    /**
     *  @notice Returns pool related debt values.
     *  @return debt_            Current amount of debt owed by borrowers in pool.
     *  @return accruedDebt_     Debt owed by borrowers based on last inflator snapshot.
     *  @return debtInAuction_   Total amount of debt in auction.
     */
    function debtInfo()
        external
        view
        returns (uint256 debt_, uint256 accruedDebt_, uint256 debtInAuction_);

    /**
     *  @notice Mapping of borrower addresses to {Borrower} structs.
     *  @dev    NOTE: Cannot use appended underscore syntax for return params since struct is used.
     *  @param  borrower   Address of the borrower.
     *  @return t0Debt     Amount of debt borrower would have had if their loan was the first debt drawn from the pool
     *  @return collateral Amount of collateral that the borrower has deposited, in collateral token.
     *  @return t0Np       Np / borrowerInflatorSnapshot
     */
    function borrowerInfo(
        address borrower
    ) external view returns (uint256 t0Debt, uint256 collateral, uint256 t0Np);

    /**
     *  @notice Mapping of buckets indexes to {Bucket} structs.
     *  @dev    NOTE: Cannot use appended underscore syntax for return params since struct is used.
     *  @param  index               Bucket index.
     *  @return lpAccumulator       Amount of LPs accumulated in current bucket.
     *  @return availableCollateral Amount of collateral available in current bucket.
     *  @return bankruptcyTime      Timestamp when bucket become insolvent, 0 if healthy.
     *  @return bucketDeposit       Amount of quote tokens in bucket.
     *  @return bucketScale         Bucket multiplier.
     */
    function bucketInfo(
        uint256 index
    )
        external
        view
        returns (
            uint256 lpAccumulator,
            uint256 availableCollateral,
            uint256 bankruptcyTime,
            uint256 bucketDeposit,
            uint256 bucketScale
        );

    /**
     *  @notice Mapping of burnEventEpoch to {BurnEvent} structs.
     *  @dev    Reserve auctions correspond to burn events.
     *  @param  burnEventEpoch_  Id of the current reserve auction.
     *  @return burnBlock        Block in which a reserve auction started.
     *  @return totalInterest    Total interest as of the reserve auction.
     *  @return totalBurned      Total ajna tokens burned as of the reserve auction.
     */
    function burnInfo(
        uint256 burnEventEpoch_
    ) external view returns (uint256, uint256, uint256);

    /**
     *  @notice Returns the latest burnEventEpoch of reserve auctions.
     *  @dev    If a reserve auction is active, it refers to the current reserve auction. If no reserve auction is active, it refers to the last reserve auction.
     *  @return burnEventEpoch Current burnEventEpoch.
     */
    function currentBurnEpoch() external view returns (uint256);

    /**
     *  @notice Returns information about the pool EMA (Exponential Moving Average) variables.
     *  @return debtEma   Exponential debt moving average.
     *  @return lupColEma Exponential LUP * pledged collateral moving average.
     */
    function emasInfo()
        external
        view
        returns (uint256 debtEma, uint256 lupColEma);

    /**
     *  @notice Returns information about pool inflator.
     *  @return inflatorSnapshot A snapshot of the last inflator value.
     *  @return lastUpdate       The timestamp of the last `inflatorSnapshot` update.
     */
    function inflatorInfo()
        external
        view
        returns (uint256 inflatorSnapshot, uint256 lastUpdate);

    /**
     *  @notice Returns information about pool interest rate.
     *  @return interestRate       Current interest rate in pool.
     *  @return interestRateUpdate The timestamp of the last interest rate update.
     */
    function interestRateInfo()
        external
        view
        returns (uint256 interestRate, uint256 interestRateUpdate);

    /**
     *  @notice Returns details about kicker balances.
     *  @param  kicker    The address of the kicker to retrieved info for.
     *  @return claimable Amount of quote token kicker can claim / withdraw from pool at any time.
     *  @return locked    Amount of quote token kicker locked in auctions (as bonds).
     */
    function kickerInfo(
        address kicker
    ) external view returns (uint256 claimable, uint256 locked);

    /**
     *  @notice Mapping of buckets indexes and owner addresses to {Lender} structs.
     *  @param  index            Bucket index.
     *  @param  lp               Address of the liquidity provider.
     *  @return lpBalance        Amount of LPs owner has in current bucket.
     *  @return lastQuoteDeposit Time the user last deposited quote token.
     */
    function lenderInfo(
        uint256 index,
        address lp
    ) external view returns (uint256 lpBalance, uint256 lastQuoteDeposit);

    /**
     *  @notice Returns information about a loan in the pool.
     *  @param  loanId Loan's id within loan heap. Max loan is position 1.
     *  @return borrower       Borrower address at the given position.
     *  @return thresholdPrice Borrower threshold price in pool.
     */
    function loanInfo(
        uint256 loanId
    ) external view returns (address borrower, uint256 thresholdPrice);

    /**
     *  @notice Returns information about pool loans.
     *  @return maxBorrower       Borrower address with highest threshold price.
     *  @return maxThresholdPrice Highest threshold price in pool.
     *  @return noOfLoans         Total number of loans.
     */
    function loansInfo()
        external
        view
        returns (
            address maxBorrower,
            uint256 maxThresholdPrice,
            uint256 noOfLoans
        );

    /**
     *  @notice Returns information about pool reserves.
     *  @return liquidationBondEscrowed Amount of liquidation bond across all liquidators.
     *  @return reserveAuctionUnclaimed Amount of claimable reserves which has not been taken in the Claimable Reserve Auction.
     *  @return reserveAuctionKicked    Time a Claimable Reserve Auction was last kicked.
     */
    function reservesInfo()
        external
        view
        returns (
            uint256 liquidationBondEscrowed,
            uint256 reserveAuctionUnclaimed,
            uint256 reserveAuctionKicked
        );

    /**
     *  @notice Returns the `pledgedCollateral` state variable.
     *  @return The total pledged collateral in the system, in WAD units.
     */
    function pledgedCollateral() external view returns (uint256);
}

/*********************/
/*** State Structs ***/
/*********************/

/*** Pool State ***/

struct InflatorState {
    uint208 inflator; // [WAD] pool's inflator
    uint48 inflatorUpdate; // [SEC] last time pool's inflator was updated
}

struct InterestState {
    uint208 interestRate; // [WAD] pool's interest rate
    uint48 interestRateUpdate; // [SEC] last time pool's interest rate was updated (not before 12 hours passed)
    uint256 debtEma; // [WAD] sample of debt EMA
    uint256 lupColEma; // [WAD] sample of LUP price * collateral EMA. capped at 10 times current pool debt
}

struct PoolBalancesState {
    uint256 pledgedCollateral; // [WAD] total collateral pledged in pool
    uint256 t0DebtInAuction; // [WAD] Total debt in auction used to restrict LPB holder from withdrawing
    uint256 t0Debt; // [WAD] Pool debt as if the whole amount was incurred upon the first loan
}

struct PoolState {
    uint8 poolType; // pool type, can be ERC20 or ERC721
    uint256 debt; // [WAD] total debt in pool, accrued in current block
    uint256 collateral; // [WAD] total collateral pledged in pool
    uint256 inflator; // [WAD] current pool inflator
    bool isNewInterestAccrued; // true if new interest already accrued in current block
    uint256 rate; // [WAD] pool's current interest rate
    uint256 quoteDustLimit; // [WAD] quote token dust limit of the pool
}

/*** Buckets State ***/

struct Lender {
    uint256 lps; // [RAY] Lender LP accumulator
    uint256 depositTime; // timestamp of last deposit
}

struct Bucket {
    uint256 lps; // [RAY] Bucket LP accumulator
    uint256 collateral; // [WAD] Available collateral tokens deposited in the bucket
    uint256 bankruptcyTime; // Timestamp when bucket become insolvent, 0 if healthy
    mapping(address => Lender) lenders; // lender address to Lender struct mapping
}

/*** Deposits State ***/

struct DepositsState {
    uint256[8193] values; // Array of values in the FenwickTree.
    uint256[8193] scaling; // Array of values which scale (multiply) the FenwickTree accross indexes.
}

/*** Loans State ***/

struct LoansState {
    Loan[] loans;
    mapping(address => uint) indices; // borrower address => loan index mapping
    mapping(address => Borrower) borrowers; // borrower address => Borrower struct mapping
}

struct Loan {
    address borrower; // borrower address
    uint96 thresholdPrice; // [WAD] Loan's threshold price.
}

struct Borrower {
    uint256 t0Debt; // [WAD] Borrower debt time-adjusted as if it was incurred upon first loan of pool.
    uint256 collateral; // [WAD] Collateral deposited by borrower.
    uint256 t0Np; // [WAD] Neutral Price time-adjusted as if it was incurred upon first loan of pool.
}

/*** Auctions State ***/

struct AuctionsState {
    uint96 noOfAuctions; // total number of auctions in pool
    address head; // first address in auction queue
    address tail; // last address in auction queue
    uint256 totalBondEscrowed; // [WAD] total amount of quote token posted as auction kick bonds
    mapping(address => Liquidation) liquidations; // mapping of borrower address and auction details
    mapping(address => Kicker) kickers; // mapping of kicker address and kicker balances
}

struct Liquidation {
    address kicker; // address that initiated liquidation
    uint96 bondFactor; // [WAD] bond factor used to start liquidation
    uint96 kickTime; // timestamp when liquidation was started
    address prev; // previous liquidated borrower in auctions queue
    uint96 kickMomp; // [WAD] Momp when liquidation was started
    address next; // next liquidated borrower in auctions queue
    uint160 bondSize; // [WAD] liquidation bond size
    uint96 neutralPrice; // [WAD] Neutral Price when liquidation was started
    bool alreadyTaken; // true if take has been called on auction
}

struct Kicker {
    uint256 claimable; // [WAD] kicker's claimable balance
    uint256 locked; // [WAD] kicker's balance of tokens locked in auction bonds
}

/*** Reserve Auction State ***/

struct ReserveAuctionState {
    uint256 kicked; // Time a Claimable Reserve Auction was last kicked.
    uint256 unclaimed; // [WAD] Amount of claimable reserves which has not been taken in the Claimable Reserve Auction.
    uint256 latestBurnEventEpoch; // Latest burn event epoch.
    uint256 totalAjnaBurned; // [WAD] Total ajna burned in the pool.
    uint256 totalInterestEarned; // [WAD] Total interest earned by all lenders in the pool.
    mapping(uint256 => BurnEvent) burnEvents; // Mapping burnEventEpoch => BurnEvent.
}

struct BurnEvent {
    uint256 timestamp; // time at which the burn event occured
    uint256 totalInterest; // [WAD] current pool interest accumulator `PoolCommons.accrueInterest().newInterest`
    uint256 totalBurned; // [WAD] burn amount accumulator
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import { PRBMathSD59x18 } from "@prb-math/contracts/PRBMathSD59x18.sol";

import { PoolType } from '../../interfaces/pool/IPool.sol';

import {
    AuctionsState,
    Borrower,
    Bucket,
    DepositsState,
    Kicker,
    Lender,
    Liquidation,
    LoansState,
    PoolState,
    ReserveAuctionState
}                                    from '../../interfaces/pool/commons/IPoolState.sol';
import {
    BucketTakeResult,
    KickResult,
    SettleParams,
    TakeResult
}                                    from '../../interfaces/pool/commons/IPoolInternals.sol';
import { StartReserveAuctionParams } from '../../interfaces/pool/commons/IPoolReserveAuctionActions.sol';

import {
    _claimableReserves,
    _indexOf,
    _isCollateralized,
    _priceAt,
    _reserveAuctionPrice,
    _roundToScale,
    MAX_FENWICK_INDEX,
    MAX_PRICE,
    MIN_PRICE
}                           from '../helpers/PoolHelper.sol';
import { _revertOnMinDebt } from '../helpers/RevertsHelper.sol';

import { Buckets }  from '../internal/Buckets.sol';
import { Deposits } from '../internal/Deposits.sol';
import { Loans }    from '../internal/Loans.sol';
import { Maths }    from '../internal/Maths.sol';

/**
    @title  Auctions library
    @notice External library containing actions involving auctions within pool:
            - Kickers: kick undercollateralized loans; settle auctions; claim bond rewards
            - Bidders: take auctioned collateral
            - Reserve purchasers: start auctions; take reserves
 */
library Auctions {

    /*******************************/
    /*** Function Params Structs ***/
    /*******************************/

    struct BucketTakeParams {
        address borrower;        // borrower address to take from
        uint256 collateral;      // [WAD] borrower available collateral to take
        bool    depositTake;     // deposit or arb take, used by bucket take
        uint256 index;           // bucket index, used by bucket take
        uint256 inflator;        // [WAD] current pool inflator
        uint256 t0Debt;          // [WAD] borrower t0 debt
        uint256 collateralScale; // precision of collateral token based on decimals
    }
    struct TakeParams {
        address borrower;        // borrower address to take from
        uint256 collateral;      // [WAD] borrower available collateral to take
        uint256 t0Debt;          // [WAD] borrower t0 debt
        uint256 takeCollateral;  // [WAD] desired amount to take
        uint256 inflator;        // [WAD] current pool inflator
        uint256 poolType;        // pool type (ERC20 or NFT)
        uint256 collateralScale; // precision of collateral token based on decimals
    }

    /*************************/
    /*** Local Var Structs ***/
    /*************************/

    struct KickWithDepositLocalVars {
        uint256 amountToDebitFromDeposit; // [WAD] the amount of quote tokens used to kick and debited from lender deposit
        uint256 bucketCollateral;         // [WAD] amount of collateral in bucket
        uint256 bucketDeposit;            // [WAD] amount of quote tokens in bucket
        uint256 bucketLPs;                // [RAY] LPs of the bucket
        uint256 bucketPrice;              // [WAD] bucket price
        uint256 bucketRate;               // [RAY] bucket exchange rate
        uint256 bucketScale;              // [WAD] bucket scales
        uint256 bucketUnscaledDeposit;    // [WAD] unscaled amount of quote tokens in bucket
        uint256 lenderLPs;                // [RAY] LPs of lender in bucket
        uint256 redeemedLPs;              // [RAY] LPs used by kick action
    }
    struct SettleLocalVars {
        uint256 collateralUsed;    // [WAD] collateral used to settle debt
        uint256 debt;              // [WAD] debt to settle
        uint256 depositToRemove;   // [WAD] deposit used by settle auction
        uint256 index;             // index of settling bucket
        uint256 maxSettleableDebt; // [WAD] max amount that can be settled with existing collateral
        uint256 price;             // [WAD] price of settling bucket
        uint256 scaledDeposit;     // [WAD] scaled amount of quote tokens in bucket
        uint256 scale;             // [WAD] scale of settling bucket
        uint256 unscaledDeposit;   // [WAD] unscaled amount of quote tokens in bucket
    }
    struct TakeLocalVars {
        uint256 auctionPrice;             // [WAD] The price of auction.
        uint256 bondChange;               // [WAD] The change made on the bond size (beeing reward or penalty).
        uint256 borrowerDebt;             // [WAD] The accrued debt of auctioned borrower.
        int256  bpf;                      // The bond penalty factor.
        uint256 bucketPrice;              // [WAD] The bucket price.
        uint256 bucketScale;              // [WAD] The bucket scale.
        uint256 collateralAmount;         // [WAD] The amount of collateral taken.
        uint256 excessQuoteToken;         // [WAD] Difference of quote token that borrower receives after take (for fractional NFT only)
        uint256 factor;                   // The take factor, calculated based on bond penalty factor.
        bool    isRewarded;               // True if kicker is rewarded (auction price lower than neutral price), false if penalized (auction price greater than neutral price).
        address kicker;                   // Address of auction kicker.
        uint256 scaledQuoteTokenAmount;   // [WAD] Unscaled quantity in Fenwick tree and before 1-bpf factor, paid for collateral
        uint256 t0RepayAmount;            // [WAD] The amount of debt (quote tokens) that is recovered / repayed by take t0 terms.
        uint256 t0Debt;                   // [WAD] Borrower's t0 debt.
        uint256 t0DebtPenalty;            // [WAD] Borrower's t0 penalty - 7% from current debt if intial take, 0 otherwise.
        uint256 unscaledDeposit;          // [WAD] Unscaled bucket quantity
        uint256 unscaledQuoteTokenAmount; // [WAD] The unscaled token amount that taker should pay for collateral taken.
    }
    struct TakeLoanLocalVars {
        uint256 repaidDebt;   // [WAD] the amount of debt repaid to th epool by take auction
        uint256 borrowerDebt; // [WAD] the amount of borrower debt
        bool    inAuction;    // true if loan in auction
    }
    struct TakeFromLoanLocalVars {
        uint256 borrowerDebt;          // [WAD] borrower's accrued debt
        bool    inAuction;             // true if loan still in auction after auction is taken, false otherwise
        uint256 newLup;                // [WAD] LUP after auction is taken
        uint256 repaidDebt;            // [WAD] debt repaid when auction is taken
        uint256 t0DebtInAuction;       // [WAD] t0 pool debt in auction
        uint256 t0DebtInAuctionChange; // [WAD] t0 change amount of debt after auction is taken
        uint256 t0PoolDebt;            // [WAD] t0 pool debt
    }

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolEvents` for descriptions
    event AuctionSettle(address indexed borrower, uint256 collateral);
    event AuctionNFTSettle(address indexed borrower, uint256 collateral, uint256 lps, uint256 index);
    event BucketTake(address indexed borrower, uint256 index, uint256 amount, uint256 collateral, uint256 bondChange, bool isReward);
    event BucketTakeLPAwarded(address indexed taker, address indexed kicker, uint256 lpAwardedTaker, uint256 lpAwardedKicker);
    event Kick(address indexed borrower, uint256 debt, uint256 collateral, uint256 bond);
    event Take(address indexed borrower, uint256 amount, uint256 collateral, uint256 bondChange, bool isReward);
    event RemoveQuoteToken(address indexed lender, uint256 indexed price, uint256 amount, uint256 lpRedeemed, uint256 lup);
    event ReserveAuction(uint256 claimableReservesRemaining, uint256 auctionPrice);
    event Settle(address indexed borrower, uint256 settledDebt);

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    event BucketBankruptcy(uint256 indexed index, uint256 lpForfeited);
    error AuctionActive();
    error AuctionNotClearable();
    error AuctionPriceGtBucketPrice();
    error BorrowerOk();
    error InsufficientLiquidity();
    error InsufficientCollateral();
    error NoAuction();
    error NoReserves();
    error NoReservesAuction();
    error PriceBelowLUP();
    error TakeNotPastCooldown();

    /***************************/
    /***  External Functions ***/
    /***************************/

    /**
     *  @notice Settles the debt of the given loan / borrower.
     *  @dev    write state:
     *          - Deposits.unscaledRemove() (remove amount in Fenwick tree, from index):
     *              - update values array state
     *          - Buckets.addCollateral:
     *              - increment bucket.collateral and bucket.lps accumulator
     *              - addLenderLPs:
     *                  - increment lender.lps accumulator and lender.depositTime state
     *          - update borrower state
     *  @dev    reverts on:
     *              - loan is not in auction NoAuction()
     *              - 72 hours didn't pass and auction still has collateral AuctionNotClearable()
     *  @dev    emit events:
     *              - Settle
     *              - BucketBankruptcy
     *  @param  params_ Settle params
     *  @return collateralRemaining_ The amount of borrower collateral left after settle.
     *  @return t0DebtRemaining_     The amount of t0 debt left after settle.
     *  @return collateralSettled_   The amount of collateral settled.
     *  @return t0DebtSettled_       The amount of t0 debt settled.
     */
    function settlePoolDebt(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState storage loans_,
        SettleParams memory params_
    ) external returns (
        uint256 collateralRemaining_,
        uint256 t0DebtRemaining_,
        uint256 collateralSettled_,
        uint256 t0DebtSettled_
    ) {
        uint256 kickTime = auctions_.liquidations[params_.borrower].kickTime;
        if (kickTime == 0) revert NoAuction();

        Borrower memory borrower = loans_.borrowers[params_.borrower];
        if ((block.timestamp - kickTime < 72 hours) && (borrower.collateral != 0)) revert AuctionNotClearable();

        t0DebtSettled_     = borrower.t0Debt;
        collateralSettled_ = borrower.collateral;

        // auction has debt to cover with remaining collateral
        while (params_.bucketDepth != 0 && borrower.t0Debt != 0 && borrower.collateral != 0) {
            SettleLocalVars memory vars;

            (vars.index, , vars.scale) = Deposits.findIndexAndSumOfSum(deposits_, 1);
            vars.unscaledDeposit = Deposits.unscaledValueAt(deposits_, vars.index);
            vars.price           = _priceAt(vars.index);

            if (vars.unscaledDeposit != 0) {
                vars.debt              = Maths.wmul(borrower.t0Debt, params_.inflator);       // current debt to be settled
                vars.maxSettleableDebt = Maths.wmul(borrower.collateral, vars.price);         // max debt that can be settled with existing collateral
                vars.scaledDeposit     = Maths.wmul(vars.scale, vars.unscaledDeposit);

                // enough deposit in bucket and collateral avail to settle entire debt
                if (vars.scaledDeposit >= vars.debt && vars.maxSettleableDebt >= vars.debt) {
                    borrower.t0Debt      = 0;                                                 // no remaining debt to settle

                    vars.unscaledDeposit = Maths.wdiv(vars.debt, vars.scale);                 // remove only what's needed to settle the debt
                    vars.collateralUsed  = Maths.wdiv(vars.debt, vars.price);
                }

                // enough collateral, therefore not enough deposit to settle entire debt, we settle only deposit amount
                else if (vars.maxSettleableDebt >= vars.scaledDeposit) {
                    borrower.t0Debt     -= Maths.wdiv(vars.scaledDeposit, params_.inflator);  // subtract from debt the corresponding t0 amount of deposit

                    vars.collateralUsed = Maths.wdiv(vars.scaledDeposit, vars.price);
                } 

                // settle constrained by collateral available
                else {
                    borrower.t0Debt      -= Maths.wdiv(vars.maxSettleableDebt, params_.inflator);

                    vars.unscaledDeposit = Maths.wdiv(vars.maxSettleableDebt, vars.scale);
                    vars.collateralUsed  = borrower.collateral;
                }

                borrower.collateral             -= vars.collateralUsed;               // move settled collateral from loan into bucket
                buckets_[vars.index].collateral += vars.collateralUsed;

                Deposits.unscaledRemove(deposits_, vars.index, vars.unscaledDeposit); // remove amount to settle debt from bucket (could be entire deposit or only the settled debt)
            }

            else {
                // Deposits in the tree is zero, insert entire collateral into lowest bucket 7388
                Buckets.addCollateral(
                    buckets_[vars.index],
                    params_.borrower,
                    0,  // zero deposit in bucket
                    borrower.collateral,
                    vars.price
                );
                borrower.collateral = 0; // entire collateral added into bucket
            }

            --params_.bucketDepth;
        }

        // if there's still debt and no collateral
        if (borrower.t0Debt != 0 && borrower.collateral == 0) {
            // settle debt from reserves -- round reserves down however
            borrower.t0Debt -= Maths.min(borrower.t0Debt, (params_.reserves / params_.inflator) * 1e18);

            // if there's still debt after settling from reserves then start to forgive amount from next HPB
            // loop through remaining buckets if there's still debt to settle
            while (params_.bucketDepth != 0 && borrower.t0Debt != 0) {
                SettleLocalVars memory vars;

                (vars.index, , vars.scale) = Deposits.findIndexAndSumOfSum(deposits_, 1);
                vars.unscaledDeposit = Deposits.unscaledValueAt(deposits_, vars.index);
                vars.depositToRemove = Maths.wmul(vars.scale, vars.unscaledDeposit);
                vars.debt            = Maths.wmul(borrower.t0Debt, params_.inflator);

                // enough deposit in bucket to settle entire debt
                if (vars.depositToRemove >= vars.debt) {
                    Deposits.unscaledRemove(deposits_, vars.index, Maths.wdiv(vars.debt, vars.scale));
                    borrower.t0Debt  = 0;                                                              // no remaining debt to settle

                // not enough deposit to settle entire debt, we settle only deposit amount
                } else {
                    borrower.t0Debt -= Maths.wdiv(vars.depositToRemove, params_.inflator);             // subtract from remaining debt the corresponding t0 amount of deposit

                    Deposits.unscaledRemove(deposits_, vars.index, vars.unscaledDeposit);              // Remove all deposit from bucket
                    Bucket storage hpbBucket = buckets_[vars.index];
                    
                    if (hpbBucket.collateral == 0) {                                                   // existing LPB and LP tokens for the bucket shall become unclaimable.
                        emit BucketBankruptcy(vars.index, hpbBucket.lps);
                        hpbBucket.lps            = 0;
                        hpbBucket.bankruptcyTime = block.timestamp;
                    }
                }

                --params_.bucketDepth;
            }
        }

        t0DebtRemaining_ =  borrower.t0Debt;
        t0DebtSettled_   -= t0DebtRemaining_;

        emit Settle(params_.borrower, t0DebtSettled_);

        if (borrower.t0Debt == 0) {
            // settle auction
            borrower.collateral = _settleAuction(
                auctions_,
                buckets_,
                deposits_,
                params_.borrower,
                borrower.collateral,
                params_.poolType
            );
        }

        collateralRemaining_ =  borrower.collateral;
        collateralSettled_   -= collateralRemaining_;

        // update borrower state
        loans_.borrowers[params_.borrower] = borrower;
    }

    /**
     *  @notice Called to start borrower liquidation and to update the auctions queue.
     *  @param  poolState_       Current state of the pool.
     *  @param  borrowerAddress_ Address of the borrower to kick.
     *  @return kickResult_      The result of the kick action.
     */
    function kick(
        AuctionsState storage auctions_,
        DepositsState storage deposits_,
        LoansState    storage loans_,
        PoolState calldata poolState_,
        address borrowerAddress_
    ) external returns (
        KickResult memory
    ) {
        return _kick(
            auctions_,
            deposits_,
            loans_,
            poolState_,
            borrowerAddress_,
            0
        );
    }

    /**
     *  @notice Called by lenders to kick loans using their deposits.
     *  @dev    write state:
     *              - Deposits.unscaledRemove (remove amount in Fenwick tree, from index):
     *                  - update values array state
     *              - decrement lender.lps accumulator
     *              - decrement bucket.lps accumulator
     *  @dev    emit events:
     *              - RemoveQuoteToken
     *  @param  poolState_           Current state of the pool.
     *  @param  index_               The deposit index from where lender removes liquidity.
     *  @return kickResult_ The result of the kick action.
     */
    function kickWithDeposit(
        AuctionsState storage auctions_,
        DepositsState storage deposits_,
        mapping(uint256 => Bucket) storage buckets_,
        LoansState storage loans_,
        PoolState memory poolState_,
        uint256 index_
    ) external returns (
        KickResult memory kickResult_
    ) {
        Bucket storage bucket = buckets_[index_];
        Lender storage lender = bucket.lenders[msg.sender];

        KickWithDepositLocalVars memory vars;

        if (bucket.bankruptcyTime < lender.depositTime) vars.lenderLPs = lender.lps;

        vars.bucketLPs             = bucket.lps;
        vars.bucketCollateral      = bucket.collateral;
        vars.bucketPrice           = _priceAt(index_);
        vars.bucketUnscaledDeposit = Deposits.unscaledValueAt(deposits_, index_);
        vars.bucketScale           = Deposits.scale(deposits_, index_);
        vars.bucketDeposit         = Maths.wmul(vars.bucketUnscaledDeposit, vars.bucketScale);

        // calculate max amount that can be removed (constrained by lender LPs in bucket, bucket deposit and the amount lender wants to remove)
        vars.bucketRate = Buckets.getExchangeRate(
            vars.bucketCollateral,
            vars.bucketLPs,
            vars.bucketDeposit,
            vars.bucketPrice
        );

        vars.amountToDebitFromDeposit = Maths.rayToWad(Maths.rmul(vars.lenderLPs, vars.bucketRate));  // calculate amount to remove based on lender LPs in bucket

        if (vars.amountToDebitFromDeposit > vars.bucketDeposit) vars.amountToDebitFromDeposit = vars.bucketDeposit; // cap the amount to remove at bucket deposit

        // revert if no amount that can be removed
        if (vars.amountToDebitFromDeposit == 0) revert InsufficientLiquidity();

        // kick top borrower
        kickResult_ = _kick(
            auctions_,
            deposits_,
            loans_,
            poolState_,
            Loans.getMax(loans_).borrower,
            vars.amountToDebitFromDeposit
        );

        // amount to remove from deposit covers entire bond amount
        if (vars.amountToDebitFromDeposit > kickResult_.amountToCoverBond) {
            vars.amountToDebitFromDeposit = kickResult_.amountToCoverBond;                      // cap amount to remove from deposit at amount to cover bond

            kickResult_.lup = _lup(deposits_, poolState_.debt + vars.amountToDebitFromDeposit); // recalculate the LUP with the amount to cover bond
            kickResult_.amountToCoverBond = 0;                                                  // entire bond is covered from deposit, no additional amount to be send by lender
        } else {
            kickResult_.amountToCoverBond -= vars.amountToDebitFromDeposit;                     // lender should send additional amount to cover bond
        }

        // revert if the bucket price used to kick and remove is below new LUP
        if (vars.bucketPrice < kickResult_.lup) revert PriceBelowLUP();

        // remove amount from deposits
        if (vars.amountToDebitFromDeposit == vars.bucketDeposit && vars.bucketCollateral == 0) {
            // In this case we are redeeming the entire bucket exactly, and need to ensure bucket LPs are set to 0
            vars.redeemedLPs = vars.bucketLPs;

            Deposits.unscaledRemove(deposits_, index_, vars.bucketUnscaledDeposit);

        } else {
            vars.redeemedLPs = Maths.wrdivr(vars.amountToDebitFromDeposit, vars.bucketRate);

            Deposits.unscaledRemove(
                deposits_,
                index_,
                Maths.wdiv(vars.amountToDebitFromDeposit, vars.bucketScale)
            );
        }

        // remove bucket LPs coresponding to the amount removed from deposits
        lender.lps -= vars.redeemedLPs;
        bucket.lps -= vars.redeemedLPs;

        emit RemoveQuoteToken(msg.sender, index_, vars.amountToDebitFromDeposit, vars.redeemedLPs, kickResult_.lup);
    }

    /**
     *  @notice Performs bucket take collateral on an auction, rewards taker and kicker (if case) and updates loan info (settles auction if case).
     *  @dev    reverts on:
     *              - insufficient collateral InsufficientCollateral()
     *  @param  borrowerAddress_ Borrower address to take.
     *  @param  depositTake_     If true then the take will happen at an auction price equal with bucket price. Auction price is used otherwise.
     *  @param  index_           Index of a bucket, likely the HPB, in which collateral will be deposited.
     *  @return result_          BucketTakeResult struct containing details of take.
    */
    function bucketTake(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState storage loans_,
        PoolState memory poolState_,
        address borrowerAddress_,
        bool    depositTake_,
        uint256 index_,
        uint256 collateralScale_
    ) external returns (BucketTakeResult memory result_) {
        Borrower memory borrower = loans_.borrowers[borrowerAddress_];

        if (borrower.collateral == 0) revert InsufficientCollateral(); // revert if borrower's collateral is 0

        (
            result_.collateralAmount,
            result_.t0RepayAmount,
            borrower.t0Debt,
            result_.t0DebtPenalty 
        ) = _takeBucket(
            auctions_,
            buckets_,
            deposits_,
            BucketTakeParams({
                borrower:        borrowerAddress_,
                collateral:      borrower.collateral,
                t0Debt:          borrower.t0Debt,
                inflator:        poolState_.inflator,
                depositTake:     depositTake_,
                index:           index_,
                collateralScale: collateralScale_
            })
        );

        borrower.collateral -= result_.collateralAmount;

        if (result_.t0DebtPenalty != 0) {
            poolState_.debt += Maths.wmul(result_.t0DebtPenalty, poolState_.inflator);
        }

        (
            result_.poolDebt,
            result_.newLup,
            result_.t0DebtInAuctionChange,
            result_.settledAuction
        ) = _takeLoan(
            auctions_,
            buckets_,
            deposits_,
            loans_,
            poolState_,
            borrower,
            borrowerAddress_,
            result_.t0RepayAmount
        );
    }

    /**
     *  @notice Performs take collateral on an auction, rewards taker and kicker (if case) and updates loan info (settles auction if case).
     *  @dev    reverts on:
     *              - insufficient collateral InsufficientCollateral()
     *  @param  borrowerAddress_ Borrower address to take.
     *  @param  collateral_      Max amount of collateral that will be taken from the auction (max number of NFTs in case of ERC721 pool).
     *  @return result_          TakeResult struct containing details of take.
    */
    function take(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState storage loans_,
        PoolState memory poolState_,
        address borrowerAddress_,
        uint256 collateral_,
        uint256 collateralScale_
    ) external returns (TakeResult memory result_) {
        Borrower memory borrower = loans_.borrowers[borrowerAddress_];

        // revert if borrower's collateral is 0 or if maxCollateral to be taken is 0
        if (borrower.collateral == 0 || collateral_ == 0) revert InsufficientCollateral();

        (
            result_.collateralAmount,
            result_.quoteTokenAmount,
            result_.t0RepayAmount,
            borrower.t0Debt,
            result_.t0DebtPenalty,
            result_.excessQuoteToken
        ) = _take(
            auctions_,
            TakeParams({
                borrower:        borrowerAddress_,
                collateral:      borrower.collateral,
                t0Debt:          borrower.t0Debt,
                takeCollateral:  collateral_,
                inflator:        poolState_.inflator,
                poolType:        poolState_.poolType,
                collateralScale: collateralScale_
            })
        );

        borrower.collateral -= result_.collateralAmount;

        if (result_.t0DebtPenalty != 0) {
            poolState_.debt += Maths.wmul(result_.t0DebtPenalty, poolState_.inflator);
        }

        (
            result_.poolDebt,
            result_.newLup,
            result_.t0DebtInAuctionChange,
            result_.settledAuction
        ) = _takeLoan(
            auctions_,
            buckets_,
            deposits_,
            loans_,
            poolState_,
            borrower,
            borrowerAddress_,
            result_.t0RepayAmount
        );
    }

    /**
     *  @notice See `IPoolReserveAuctionActions` for descriptions.
     *  @dev    write state:
     *              - update reserveAuction.unclaimed accumulator
     *              - update reserveAuction.kicked timestamp state
     *  @dev    reverts on:
     *          - no reserves to claim NoReserves()
     *  @dev    emit events:
     *              - ReserveAuction
     */
    function startClaimableReserveAuction(
        AuctionsState storage auctions_,
        ReserveAuctionState storage reserveAuction_,
        StartReserveAuctionParams calldata params_
    ) external returns (uint256 kickerAward_) {
        uint256 curUnclaimedAuctionReserve = reserveAuction_.unclaimed;

        uint256 claimable = _claimableReserves(
            Maths.wmul(params_.poolDebt, params_.inflator),
            params_.poolSize,
            auctions_.totalBondEscrowed,
            curUnclaimedAuctionReserve,
            params_.poolBalance
        );

        kickerAward_ = Maths.wmul(0.01 * 1e18, claimable);

        curUnclaimedAuctionReserve += claimable - kickerAward_;

        if (curUnclaimedAuctionReserve == 0) revert NoReserves();

        reserveAuction_.unclaimed = curUnclaimedAuctionReserve;
        reserveAuction_.kicked    = block.timestamp;

        emit ReserveAuction(curUnclaimedAuctionReserve, _reserveAuctionPrice(block.timestamp));
    }

    /**
     *  @notice See `IPoolReserveAuctionActions` for descriptions.
     *  @dev    write state:
     *              - decrement reserveAuction.unclaimed accumulator
     *  @dev    reverts on:
     *              - not kicked or 72 hours didn't pass NoReservesAuction()
     *  @dev    emit events:
     *              - ReserveAuction
     */
    function takeReserves(
        ReserveAuctionState storage reserveAuction_,
        uint256 maxAmount_
    ) external returns (uint256 amount_, uint256 ajnaRequired_) {
        uint256 kicked = reserveAuction_.kicked;

        if (kicked != 0 && block.timestamp - kicked <= 72 hours) {
            uint256 unclaimed = reserveAuction_.unclaimed;
            uint256 price     = _reserveAuctionPrice(kicked);

            amount_       = Maths.min(unclaimed, maxAmount_);
            ajnaRequired_ = Maths.wmul(amount_, price);

            unclaimed -= amount_;

            reserveAuction_.unclaimed = unclaimed;

            emit ReserveAuction(unclaimed, price);
        } else {
            revert NoReservesAuction();
        }
    }

    /***************************/
    /***  Internal Functions ***/
    /***************************/

    /**
     *  @notice Performs auction settle based on pool type, emits settle event and removes auction from auctions queue.
     *  @dev    emit events:
     *              - AuctionNFTSettle or AuctionSettle
     *  @param  borrowerAddress_     Address of the borrower that exits auction.
     *  @param  borrowerCollateral_  Borrower collateral amount before auction exit (in NFT could be fragmented as result of partial takes).
     *  @param  poolType_            Type of the pool (can be ERC20 or NFT).
     *  @return remainingCollateral_ Collateral remaining after auction is settled (same amount for ERC20 pool, rounded collateral for NFT pool).
     */
    function _settleAuction(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        address borrowerAddress_,
        uint256 borrowerCollateral_,
        uint256 poolType_
    ) internal returns (uint256 remainingCollateral_) {
        if (poolType_ == uint8(PoolType.ERC721)) {
            uint256 lps;
            uint256 bucketIndex;

            (remainingCollateral_, lps, bucketIndex) = _settleNFTCollateral(
                auctions_,
                buckets_,
                deposits_,
                borrowerAddress_,
                borrowerCollateral_
            );

            emit AuctionNFTSettle(borrowerAddress_, remainingCollateral_, lps, bucketIndex);

        } else {
            remainingCollateral_ = borrowerCollateral_;

            emit AuctionSettle(borrowerAddress_, remainingCollateral_);
        }

        _removeAuction(auctions_, borrowerAddress_);
    }

    /**
     *  @notice Performs NFT collateral settlement by rounding down borrower's collateral amount and by moving borrower's token ids to pool claimable array.
     *  @param borrowerAddress_    Address of the borrower that exits auction.
     *  @param borrowerCollateral_ Borrower collateral amount before auction exit (could be fragmented as result of partial takes).
     *  @return floorCollateral_   Rounded down collateral, the number of NFT tokens borrower can pull after auction exit.
     *  @return lps_               LPs given to the borrower to compensate fractional collateral (if any).
     *  @return bucketIndex_       Index of the bucket with LPs to compensate.
     */
    function _settleNFTCollateral(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        address borrowerAddress_,
        uint256 borrowerCollateral_
    ) internal returns (uint256 floorCollateral_, uint256 lps_, uint256 bucketIndex_) {
        floorCollateral_ = (borrowerCollateral_ / Maths.WAD) * Maths.WAD; // floor collateral of borrower

        // if there's fraction of NFTs remaining then reward difference to borrower as LPs in auction price bucket
        if (floorCollateral_ != borrowerCollateral_) {
            // cover borrower's fractional amount with LPs in auction price bucket
            uint256 fractionalCollateral = borrowerCollateral_ - floorCollateral_;

            uint256 auctionPrice = _auctionPrice(
                auctions_.liquidations[borrowerAddress_].kickMomp,
                auctions_.liquidations[borrowerAddress_].neutralPrice,
                auctions_.liquidations[borrowerAddress_].kickTime
            );

            bucketIndex_ = auctionPrice > MIN_PRICE ? _indexOf(auctionPrice) : MAX_FENWICK_INDEX;

            lps_ = Buckets.addCollateral(
                buckets_[bucketIndex_],
                borrowerAddress_,
                Deposits.valueAt(deposits_, bucketIndex_),
                fractionalCollateral,
                _priceAt(bucketIndex_)
            );
        }
    }

    /**
     *  @notice Called to start borrower liquidation and to update the auctions queue.
     *  @dev    write state:
     *              - _recordAuction:
     *                  - borrower -> liquidation mapping update
     *                  - increment auctions count accumulator
     *                  - increment auctions.totalBondEscrowed accumulator
     *                  - updates auction queue state
     *              - _updateKicker:
     *                  - update locked and claimable kicker accumulators
     *              - Loans.remove:
     *                  - delete borrower from indices => borrower address mapping
     *                  - remove loan from loans array
     *  @dev    emit events:
     *              - Kick
     *  @param  poolState_       Current state of the pool.
     *  @param  borrowerAddress_ Address of the borrower to kick.
     *  @param  additionalDebt_  Additional debt to be used when calculating proposed LUP.
     *  @return kickResult_      The result of the kick action.
     */
    function _kick(
        AuctionsState storage auctions_,
        DepositsState storage deposits_,
        LoansState    storage loans_,
        PoolState memory poolState_,
        address borrowerAddress_,
        uint256 additionalDebt_
    ) internal returns (
        KickResult memory kickResult_
    ) {
        Borrower storage borrower = loans_.borrowers[borrowerAddress_];

        kickResult_.t0KickedDebt = borrower.t0Debt;

        uint256 borrowerDebt       = Maths.wmul(kickResult_.t0KickedDebt, poolState_.inflator);
        uint256 borrowerCollateral = borrower.collateral;

        // add amount to remove to pool debt in order to calculate proposed LUP
        kickResult_.lup = _lup(deposits_, poolState_.debt + additionalDebt_);

        if (_isCollateralized(borrowerDebt , borrowerCollateral, kickResult_.lup, poolState_.poolType)) {
            revert BorrowerOk();
        }

        // calculate auction params
        uint256 noOfLoans = Loans.noOfLoans(loans_) + auctions_.noOfAuctions;

        uint256 momp = _priceAt(
            Deposits.findIndexOfSum(
                deposits_,
                Maths.wdiv(poolState_.debt, noOfLoans * 1e18)
            )
        );

        (uint256 bondFactor, uint256 bondSize) = _bondParams(
            borrowerDebt,
            borrowerCollateral,
            momp
        );

        // when loan is kicked, penalty of three months of interest is added
        kickResult_.kickPenalty   = Maths.wmul(Maths.wdiv(poolState_.rate, 4 * 1e18), borrowerDebt);
        kickResult_.t0KickPenalty = Maths.wdiv(kickResult_.kickPenalty, poolState_.inflator);

        // record liquidation info
        uint256 neutralPrice = Maths.wmul(borrower.t0Np, poolState_.inflator);
        _recordAuction(
            auctions_,
            borrowerAddress_,
            bondSize,
            bondFactor,
            momp,
            neutralPrice
        );

        // update kicker balances and get the difference needed to cover bond (after using any kick claimable funds if any)
        kickResult_.amountToCoverBond = _updateKicker(auctions_, bondSize);

        // remove kicked loan from heap
        Loans.remove(loans_, borrowerAddress_, loans_.indices[borrowerAddress_]);

        kickResult_.t0KickedDebt += kickResult_.t0KickPenalty;

        borrower.t0Debt = kickResult_.t0KickedDebt;

        emit Kick(
            borrowerAddress_,
            borrowerDebt + kickResult_.kickPenalty,
            borrower.collateral,
            bondSize
        );
    }

    /**
     *  @notice Performs take collateral on an auction and updates bond size and kicker balance accordingly.
     *  @dev    emit events:
     *              - Take
     *  @param  params_ Struct containing take action params details.
     *  @return Collateral amount taken.
     *  @return Quote token to be received from taker.
     *  @return T0 debt amount repaid.
     *  @return T0 borrower debt (including penalty).
     *  @return T0 penalty debt.
     *  @return Excess quote token that can result after a take (NFT case).
    */
    function _take(
        AuctionsState storage auctions_,
        TakeParams memory params_
    ) internal returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        Liquidation storage liquidation = auctions_.liquidations[params_.borrower];

        TakeLocalVars memory vars = _prepareTake(liquidation, params_.t0Debt, params_.collateral, params_.inflator);

        // These are placeholder max values passed to calculateTakeFlows because there is no explicit bound on the
        // quote token amount in take calls (as opposed to bucketTake)
        vars.unscaledDeposit = type(uint256).max;
        vars.bucketScale     = Maths.WAD;

        // In the case of take, the taker binds the collateral qty but not the quote token qty
        // ugly to get take work like a bucket take -- this is the max amount of quote token from the take that could go to
        // reduce the debt of the borrower -- analagous to the amount of deposit in the bucket for a bucket take
        vars = _calculateTakeFlowsAndBondChange(
            Maths.min(params_.collateral, params_.takeCollateral),
            params_.inflator,
            params_.collateralScale,
            vars
        );

        _rewardTake(auctions_, liquidation, vars);

        emit Take(
            params_.borrower,
            vars.scaledQuoteTokenAmount,
            vars.collateralAmount,
            vars.bondChange,
            vars.isRewarded
        );

        if (params_.poolType == uint8(PoolType.ERC721)) {
            // slither-disable-next-line divide-before-multiply
            uint256 collateralTaken = (vars.collateralAmount / 1e18) * 1e18; // solidity rounds down, so if 2.5 it will be 2.5 / 1 = 2

            if (collateralTaken != vars.collateralAmount && params_.collateral >= collateralTaken + 1e18) { // collateral taken not a round number
                collateralTaken += 1e18; // round up collateral to take
                // taker should send additional quote tokens to cover difference between collateral needed to be taken and rounded collateral, at auction price
                // borrower will get quote tokens for the difference between rounded collateral and collateral taken to cover debt
                vars.excessQuoteToken = Maths.wmul(collateralTaken - vars.collateralAmount, vars.auctionPrice);
            }

            vars.collateralAmount = collateralTaken;
        }

        return (
            vars.collateralAmount,
            vars.scaledQuoteTokenAmount,
            vars.t0RepayAmount,
            vars.t0Debt,
            vars.t0DebtPenalty,
            vars.excessQuoteToken
        );
    }

    /**
     *  @notice Performs bucket take collateral on an auction and rewards taker and kicker (if case).
     *  @dev    emit events:
     *              - BucketTake
     *  @param  params_ Struct containing take action details.
     *  @return Collateral amount taken.
     *  @return T0 debt amount repaid.
     *  @return T0 borrower debt (including penalty).
     *  @return T0 penalty debt.
    */
    function _takeBucket(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        BucketTakeParams memory params_
    ) internal returns (uint256, uint256, uint256, uint256) {

        Liquidation storage liquidation = auctions_.liquidations[params_.borrower];

        TakeLocalVars memory vars = _prepareTake(liquidation, params_.t0Debt, params_.collateral, params_.inflator);

        vars.unscaledDeposit = Deposits.unscaledValueAt(deposits_, params_.index);

        if (vars.unscaledDeposit == 0) revert InsufficientLiquidity(); // revert if no quote tokens in arbed bucket

        vars.bucketPrice  = _priceAt(params_.index);

        // cannot arb with a price lower than the auction price
        if (vars.auctionPrice > vars.bucketPrice) revert AuctionPriceGtBucketPrice();
        
        // if deposit take then price to use when calculating take is bucket price
        if (params_.depositTake) vars.auctionPrice = vars.bucketPrice;

        vars.bucketScale = Deposits.scale(deposits_, params_.index);

        vars = _calculateTakeFlowsAndBondChange(
            params_.collateral,
            params_.inflator,
            params_.collateralScale,
            vars
        );

        _rewardBucketTake(
            auctions_,
            deposits_,
            buckets_,
            liquidation,
            params_.index,
            params_.depositTake,
            vars
        );

        emit BucketTake(
            params_.borrower,
            params_.index,
            vars.scaledQuoteTokenAmount,
            vars.collateralAmount,
            vars.bondChange,
            vars.isRewarded
        );

        return (
            vars.collateralAmount,
            vars.t0RepayAmount,
            vars.t0Debt,
            vars.t0DebtPenalty
        );
    }

    /**
     *  @notice Performs update of an auctioned loan that was taken (using bucket or regular take).
     *  @notice If borrower becomes recollateralized then auction is settled. Update loan's state.
     *  @dev    reverts on:
     *              - borrower debt less than pool min debt AmountLTMinDebt()
     *  @param  borrower_               The borrower details owning loan that is taken.
     *  @param  borrowerAddress_        The address of the borrower.
     *  @param  t0RepaidDebt_           T0 debt amount repaid by the take action.
     *  @return poolDebt_               Accrued debt pool after debt is repaid.
     *  @return newLup_                 The new LUP of pool (after debt is repaid).
     *  @return t0DebtInAuctionChange_  The overall debt in auction change (remaining borrower debt if auction settled, repaid debt otherwise).
     *  @return settledAuction_         True if auction is settled by the take action.
    */
    function _takeLoan(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState storage loans_,
        PoolState memory poolState_,
        Borrower memory borrower_,
        address borrowerAddress_,
        uint256 t0RepaidDebt_
    ) internal returns (
        uint256 poolDebt_,
        uint256 newLup_,
        uint256 t0DebtInAuctionChange_,
        bool settledAuction_
    ) {

        TakeLoanLocalVars memory vars;

        vars.repaidDebt   = Maths.wmul(t0RepaidDebt_,    poolState_.inflator);
        vars.borrowerDebt = Maths.wmul(borrower_.t0Debt, poolState_.inflator);

        vars.borrowerDebt -= vars.repaidDebt;
        poolDebt_ = poolState_.debt - vars.repaidDebt;

        // check that taking from loan doesn't leave borrower debt under min debt amount
        _revertOnMinDebt(loans_, poolDebt_, vars.borrowerDebt, poolState_.quoteDustLimit);

        newLup_ = _lup(deposits_, poolDebt_);

        vars.inAuction = true;

        if (_isCollateralized(vars.borrowerDebt, borrower_.collateral, newLup_, poolState_.poolType)) {
            // settle auction if borrower becomes re-collateralized

            vars.inAuction  = false;
            settledAuction_ = true;

            // the overall debt in auction change is the total borrower debt exiting auction
            t0DebtInAuctionChange_ = borrower_.t0Debt;

            // settle auction and update borrower's collateral with value after settlement
            borrower_.collateral = _settleAuction(
                auctions_,
                buckets_,
                deposits_,
                borrowerAddress_,
                borrower_.collateral,
                poolState_.poolType
            );
        } else {
            // the overall debt in auction change is the amount of partially repaid debt
            t0DebtInAuctionChange_ = t0RepaidDebt_;
        }

        borrower_.t0Debt -= t0RepaidDebt_;

        // update loan state, stamp borrower t0Np only when exiting from auction
        Loans.update(
            loans_,
            auctions_,
            deposits_,
            borrower_,
            borrowerAddress_,
            vars.borrowerDebt,
            poolState_.rate,
            newLup_,
            vars.inAuction,
            !vars.inAuction // stamp borrower t0Np if exiting from auction
        );
    }

    /**
     *  @notice Calculates bond parameters of an auction.
     *  @param  borrowerDebt_ Borrower's debt before entering in liquidation.
     *  @param  collateral_   Borrower's collateral before entering in liquidation.
     *  @param  momp_         Current pool momp.
     */
    function _bondParams(
        uint256 borrowerDebt_,
        uint256 collateral_,
        uint256 momp_
    ) internal pure returns (uint256 bondFactor_, uint256 bondSize_) {
        uint256 thresholdPrice = borrowerDebt_  * Maths.WAD / collateral_;

        // bondFactor = min(30%, max(1%, (MOMP - thresholdPrice) / MOMP))
        if (thresholdPrice >= momp_) {
            bondFactor_ = 0.01 * 1e18;
        } else {
            bondFactor_ = Maths.min(
                0.3 * 1e18,
                Maths.max(
                    0.01 * 1e18,
                    1e18 - Maths.wdiv(thresholdPrice, momp_)
                )
            );
        }

        bondSize_ = Maths.wmul(bondFactor_,  borrowerDebt_);
    }

    /**
     *  @notice Updates kicker balances.
     *  @dev    write state:
     *              - update locked and claimable kicker accumulators
     *  @param  bondSize_       Bond size to cover newly kicked auction.
     *  @return bondDifference_ The amount that kicker should send to pool to cover auction bond.
     */
    function _updateKicker(
        AuctionsState storage auctions_,
        uint256 bondSize_
    ) internal returns (uint256 bondDifference_){
        Kicker storage kicker = auctions_.kickers[msg.sender];

        kicker.locked += bondSize_;

        uint256 kickerClaimable = kicker.claimable;

        if (kickerClaimable >= bondSize_) {
            kicker.claimable -= bondSize_;
        } else {
            bondDifference_  = bondSize_ - kickerClaimable;
            kicker.claimable = 0;
        }
    }

    /**
     *  @notice Computes the flows of collateral, quote token between the borrower, lender and kicker.
     *  @param  totalCollateral_        Total collateral in loan.
     *  @param  inflator_               Current pool inflator.
     *  @param  vars                    TakeParams for the take/buckettake
     */
    function _calculateTakeFlowsAndBondChange(
        uint256              totalCollateral_,
        uint256              inflator_,
        uint256              collateralScale_,
        TakeLocalVars memory vars
    ) internal pure returns (
        TakeLocalVars memory
    ) {
        // price is the current auction price, which is the price paid by the LENDER for collateral
        // from the borrower point of view, the price is actually (1-bpf) * price, as the rewards to the
        // bond holder are effectively paid for by the borrower.
        uint256 borrowerPayoffFactor = (vars.isRewarded) ? Maths.WAD - uint256(vars.bpf)                       : Maths.WAD;
        uint256 borrowerPrice        = (vars.isRewarded) ? Maths.wmul(borrowerPayoffFactor, vars.auctionPrice) : vars.auctionPrice;

        // If there is no unscaled quote token bound, then we pass in max, but that cannot be scaled without an overflow.  So we check in the line below.
        vars.scaledQuoteTokenAmount = (vars.unscaledDeposit != type(uint256).max) ? Maths.wmul(vars.unscaledDeposit, vars.bucketScale) : type(uint256).max;

        uint256 borrowerCollateralValue = Maths.wmul(totalCollateral_, borrowerPrice);
        
        if (vars.scaledQuoteTokenAmount <= vars.borrowerDebt && vars.scaledQuoteTokenAmount <= borrowerCollateralValue) {
            // quote token used to purchase is constraining factor
            vars.collateralAmount         = _roundToScale(Maths.wdiv(vars.scaledQuoteTokenAmount, borrowerPrice), collateralScale_);
            vars.t0RepayAmount            = Maths.wdiv(vars.scaledQuoteTokenAmount, inflator_);
            vars.unscaledQuoteTokenAmount = vars.unscaledDeposit;

        } else if (vars.borrowerDebt <= borrowerCollateralValue) {
            // borrower debt is constraining factor
            vars.collateralAmount         = _roundToScale(Maths.wdiv(vars.borrowerDebt, borrowerPrice), collateralScale_);
            vars.t0RepayAmount            = vars.t0Debt;
            vars.unscaledQuoteTokenAmount = Maths.wdiv(vars.borrowerDebt, vars.bucketScale);

            vars.scaledQuoteTokenAmount   = (vars.isRewarded) ? Maths.wdiv(vars.borrowerDebt, borrowerPayoffFactor) : vars.borrowerDebt;

        } else {
            // collateral available is constraint
            vars.collateralAmount         = totalCollateral_;
            vars.t0RepayAmount            = Maths.wdiv(borrowerCollateralValue, inflator_);
            vars.unscaledQuoteTokenAmount = Maths.wdiv(borrowerCollateralValue, vars.bucketScale);

            vars.scaledQuoteTokenAmount   = Maths.wmul(vars.collateralAmount, vars.auctionPrice);
        }

        if (vars.isRewarded) {
            // take is above neutralPrice, Kicker is rewarded
            vars.bondChange = Maths.wmul(vars.scaledQuoteTokenAmount, uint256(vars.bpf));
        } else {
            // take is above neutralPrice, Kicker is penalized
            vars.bondChange = Maths.wmul(vars.scaledQuoteTokenAmount, uint256(-vars.bpf));
        }

        return vars;
    }

    /**
     *  @notice Saves a new liquidation that was kicked.
     *  @dev    write state:
     *              - borrower -> liquidation mapping update
     *              - increment auctions count accumulator
     *              - increment auctions.totalBondEscrowed accumulator
     *              - updates auction queue state
     *  @param  borrowerAddress_ Address of the borrower that is kicked.
     *  @param  bondSize_        Bond size to cover newly kicked auction.
     *  @param  bondFactor_      Bond factor of the newly kicked auction.
     *  @param  momp_            Current pool MOMP.
     *  @param  neutralPrice_    Current pool Neutral Price.
     */
    function _recordAuction(
        AuctionsState storage auctions_,
        address borrowerAddress_,
        uint256 bondSize_,
        uint256 bondFactor_,
        uint256 momp_,
        uint256 neutralPrice_
    ) internal {
        Liquidation storage liquidation = auctions_.liquidations[borrowerAddress_];
        if (liquidation.kickTime != 0) revert AuctionActive();

        // record liquidation info
        liquidation.kicker       = msg.sender;
        liquidation.kickTime     = uint96(block.timestamp);
        liquidation.kickMomp     = uint96(momp_);
        liquidation.bondSize     = uint160(bondSize_);
        liquidation.bondFactor   = uint96(bondFactor_);
        liquidation.neutralPrice = uint96(neutralPrice_);

        // increment number of active auctions
        ++auctions_.noOfAuctions;

        // update totalBondEscrowed accumulator
        auctions_.totalBondEscrowed += bondSize_;

        // update auctions queue
        if (auctions_.head != address(0)) {
            // other auctions in queue, liquidation doesn't exist or overwriting.
            auctions_.liquidations[auctions_.tail].next = borrowerAddress_;
            liquidation.prev = auctions_.tail;
        } else {
            // first auction in queue
            auctions_.head = borrowerAddress_;
        }
        // update liquidation with the new ordering
        auctions_.tail = borrowerAddress_;
    }

    /**
     *  @notice Removes auction and repairs the queue order.
     *  @notice Updates kicker's claimable balance with bond size awarded and subtracts bond size awarded from liquidationBondEscrowed.
     *  @dev    write state:
     *              - decrement kicker locked accumulator, increment kicker claimable accumumlator
     *              - decrement auctions count accumulator
     *              - decrement auctions.totalBondEscrowed accumulator
     *              - update auction queue state
     *  @param  borrower_ Auctioned borrower address.
     */
    function _removeAuction(
        AuctionsState storage auctions_,
        address borrower_
    ) internal {
        Liquidation memory liquidation = auctions_.liquidations[borrower_];
        // update kicker balances
        Kicker storage kicker = auctions_.kickers[liquidation.kicker];

        kicker.locked    -= liquidation.bondSize;
        kicker.claimable += liquidation.bondSize;

        // decrement number of active auctions
        -- auctions_.noOfAuctions;

        // remove auction bond size from bond escrow accumulator
        auctions_.totalBondEscrowed -= liquidation.bondSize;

        // update auctions queue
        if (auctions_.head == borrower_ && auctions_.tail == borrower_) {
            // liquidation is the head and tail
            auctions_.head = address(0);
            auctions_.tail = address(0);
        }
        else if(auctions_.head == borrower_) {
            // liquidation is the head
            auctions_.liquidations[liquidation.next].prev = address(0);
            auctions_.head = liquidation.next;
        }
        else if(auctions_.tail == borrower_) {
            // liquidation is the tail
            auctions_.liquidations[liquidation.prev].next = address(0);
            auctions_.tail = liquidation.prev;
        }
        else {
            // liquidation is in the middle
            auctions_.liquidations[liquidation.prev].next = liquidation.next;
            auctions_.liquidations[liquidation.next].prev = liquidation.prev;
        }
        // delete liquidation
        delete auctions_.liquidations[borrower_];
    }

    /**
     *  @notice Rewards actors of a regular take action.
     *  @dev    write state:
     *              - update liquidation bond size accumulator
     *              - update kicker's locked balance accumulator
     *              - update auctions.totalBondEscrowed accumulator
     *  @param  vars  Struct containing take action result details.
     */
    function _rewardTake(
        AuctionsState storage auctions_,
        Liquidation storage liquidation_,
        TakeLocalVars memory vars
    ) internal {
        if (vars.isRewarded) {
            // take is below neutralPrice, Kicker is rewarded
            liquidation_.bondSize                 += uint160(vars.bondChange);
            auctions_.kickers[vars.kicker].locked += vars.bondChange;
            auctions_.totalBondEscrowed           += vars.bondChange;
        } else {
            // take is above neutralPrice, Kicker is penalized
            vars.bondChange = Maths.min(liquidation_.bondSize, vars.bondChange);

            liquidation_.bondSize                 -= uint160(vars.bondChange);
            auctions_.kickers[vars.kicker].locked -= vars.bondChange;
            auctions_.totalBondEscrowed           -= vars.bondChange;
        }
    }

    /**
     *  @notice Rewards actors of a bucket take action.
     *  @dev    write state:
     *              - Buckets.addLenderLPs:
     *                  - increment taker lender.lps accumulator and lender.depositTime state
     *                  - increment kicker lender.lps accumulator and lender.depositTime state
     *              - update liquidation bond size accumulator
     *              - update kicker's locked balance accumulator
     *              - update auctions.totalBondEscrowed accumulator
     *              - Deposits.unscaledRemove() (remove amount in Fenwick tree, from index):
     *                  - update values array state
     *              - increment bucket.collateral and bucket.lps accumulator
     *  @dev    emit events:
     *              - BucketTakeLPAwarded
     *  @param  vars Struct containing take action result details.
     */
    function _rewardBucketTake(
        AuctionsState storage auctions_,
        DepositsState storage deposits_,
        mapping(uint256 => Bucket) storage buckets_,
        Liquidation storage liquidation_,
        uint256 bucketIndex_,
        bool depositTake_,
        TakeLocalVars memory vars
    ) internal {
        Bucket storage bucket = buckets_[bucketIndex_];

        uint256 bucketExchangeRate = Buckets.getUnscaledExchangeRate(
            bucket.collateral,
            bucket.lps,
            vars.unscaledDeposit,
            vars.bucketScale,
            vars.bucketPrice
        );

        uint256 bankruptcyTime = bucket.bankruptcyTime;
        uint256 totalLPsReward;

        // if arb take - taker is awarded collateral * (bucket price - auction price) worth (in quote token terms) units of LPB in the bucket
        if (!depositTake_) {
            uint256 takerReward                   = Maths.wmul(vars.collateralAmount, vars.bucketPrice - vars.auctionPrice);
            uint256 takerRewardUnscaledQuoteToken = Maths.wdiv(takerReward,           vars.bucketScale);

            totalLPsReward = Maths.wrdivr(takerRewardUnscaledQuoteToken, bucketExchangeRate);

            Buckets.addLenderLPs(bucket, bankruptcyTime, msg.sender, totalLPsReward);
        }

        uint256 kickerLPsReward;

        // the bondholder/kicker is awarded bond change worth of LPB in the bucket
        if (vars.isRewarded) {
            kickerLPsReward = Maths.wrdivr(Maths.wdiv(vars.bondChange, vars.bucketScale), bucketExchangeRate);
            totalLPsReward  += kickerLPsReward;

            Buckets.addLenderLPs(bucket, bankruptcyTime, vars.kicker, kickerLPsReward);
        } else {
            // take is above neutralPrice, Kicker is penalized
            vars.bondChange = Maths.min(liquidation_.bondSize, vars.bondChange);

            liquidation_.bondSize                 -= uint160(vars.bondChange);

            auctions_.kickers[vars.kicker].locked -= vars.bondChange;
            auctions_.totalBondEscrowed           -= vars.bondChange;
        }

        Deposits.unscaledRemove(deposits_, bucketIndex_, vars.unscaledQuoteTokenAmount); // remove quote tokens from bucket’s deposit

        // total rewarded LPs are added to the bucket LP balance
        bucket.lps += totalLPsReward;

        // collateral is added to the bucket’s claimable collateral
        bucket.collateral += vars.collateralAmount;

        emit BucketTakeLPAwarded(
            msg.sender,
            vars.kicker,
            totalLPsReward - kickerLPsReward,
            kickerLPsReward
        );
    }

    /**
     *  @notice Calculates auction price.
     *  @param  kickMomp_     MOMP recorded at the time of kick.
     *  @param  neutralPrice_ Neutral Price of the auction.
     *  @param  kickTime_     Time when auction was kicked.
     *  @return price_        Calculated auction price.
     */
    function _auctionPrice(
        uint256 kickMomp_,
        uint256 neutralPrice_,
        uint256 kickTime_
    ) internal view returns (uint256 price_) {
        uint256 elapsedHours = Maths.wdiv((block.timestamp - kickTime_) * 1e18, 1 hours * 1e18);

        elapsedHours -= Maths.min(elapsedHours, 1e18);  // price locked during cure period

        int256 timeAdjustment  = PRBMathSD59x18.mul(-1 * 1e18, int256(elapsedHours)); 
        uint256 referencePrice = Maths.max(kickMomp_, neutralPrice_); 

        price_ = 32 * Maths.wmul(referencePrice, uint256(PRBMathSD59x18.exp2(timeAdjustment)));
    }

    /**
     *  @notice Calculates bond penalty factor.
     *  @dev    Called in kick and take.
     *  @param debt_         Borrower debt.
     *  @param collateral_   Borrower collateral.
     *  @param neutralPrice_ NP of auction.
     *  @param bondFactor_   Factor used to determine bondSize.
     *  @param auctionPrice_ Auction price at the time of call.
     *  @return bpf_         Factor used in determining bond Reward (positive) or penalty (negative).
     */
    function _bpf(
        uint256 debt_,
        uint256 collateral_,
        uint256 neutralPrice_,
        uint256 bondFactor_,
        uint256 auctionPrice_
    ) internal pure returns (int256) {
        int256 thresholdPrice = int256(Maths.wdiv(debt_, collateral_));

        int256 sign;
        if (thresholdPrice < int256(neutralPrice_)) {
            // BPF = BondFactor * min(1, max(-1, (neutralPrice - price) / (neutralPrice - thresholdPrice)))
            sign = Maths.minInt(
                1e18,
                Maths.maxInt(
                    -1 * 1e18,
                    PRBMathSD59x18.div(
                        int256(neutralPrice_) - int256(auctionPrice_),
                        int256(neutralPrice_) - thresholdPrice
                    )
                )
            );
        } else {
            int256 val = int256(neutralPrice_) - int256(auctionPrice_);
            if (val < 0 )      sign = -1e18;
            else if (val != 0) sign = 1e18;
        }

        return PRBMathSD59x18.mul(int256(bondFactor_), sign);
    }

    /**
     *  @notice Utility function to validate take and calculate take's parameters.
     *  @dev    write state:
     *              - update liquidation.alreadyTaken state
     *  @dev    reverts on:
     *              - loan is not in auction NoAuction()
     *              - in 1 hour cool down period TakeNotPastCooldown()
     *  @param  liquidation_ Liquidation struct holding auction details.
     *  @param  t0Debt_      Borrower t0 debt.
     *  @param  collateral_  Borrower collateral.
     *  @param  inflator_    The pool's inflator, used to calculate borrower debt.
     *  @return vars         The prepared vars for take action.
     */
    function _prepareTake(
        Liquidation storage liquidation_,
        uint256 t0Debt_,
        uint256 collateral_,
        uint256 inflator_
    ) internal returns (TakeLocalVars memory vars) {

        uint256 kickTime = liquidation_.kickTime;
        if (kickTime == 0) revert NoAuction();
        if (block.timestamp - kickTime <= 1 hours) revert TakeNotPastCooldown();

        vars.t0Debt = t0Debt_;

        // if first take borrower debt is increased by 7% penalty
        if (!liquidation_.alreadyTaken) {
            vars.t0DebtPenalty = Maths.wmul(t0Debt_, 0.07 * 1e18);
            vars.t0Debt        += vars.t0DebtPenalty;

            liquidation_.alreadyTaken = true;
        }

        vars.borrowerDebt = Maths.wmul(vars.t0Debt, inflator_);

        uint256 neutralPrice = liquidation_.neutralPrice;

        vars.auctionPrice = _auctionPrice(liquidation_.kickMomp, neutralPrice, kickTime);
        vars.bpf          = _bpf(
            vars.borrowerDebt,
            collateral_,
            neutralPrice,
            liquidation_.bondFactor,
            vars.auctionPrice
        );
        vars.factor       = uint256(1e18 - Maths.maxInt(0, vars.bpf));
        vars.kicker       = liquidation_.kicker;
        vars.isRewarded   = (vars.bpf  >= 0);
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    function _lup(
        DepositsState storage deposits_,
        uint256 debt_
    ) internal view returns (uint256) {
        return _priceAt(Deposits.findIndexOfSum(deposits_, debt_));
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import {
    AuctionsState,
    Borrower,
    Bucket,
    DepositsState,
    LoansState,
    PoolState
}                   from '../../interfaces/pool/commons/IPoolState.sol';
import {
    DrawDebtResult,
    RepayDebtResult
}                   from '../../interfaces/pool/commons/IPoolInternals.sol';

import {
    _feeRate,
    _priceAt,
    _isCollateralized
}                           from '../helpers/PoolHelper.sol';
import { _revertOnMinDebt } from '../helpers/RevertsHelper.sol';

import { Buckets }  from '../internal/Buckets.sol';
import { Deposits } from '../internal/Deposits.sol';
import { Loans }    from '../internal/Loans.sol';
import { Maths }    from '../internal/Maths.sol';

import { Auctions } from './Auctions.sol';

/**
    @title  BorrowerActions library
    @notice External library containing logic for for pool actors:
            - Borrowers: pledge collateral and draw debt; repay debt and pull collateral
 */
library BorrowerActions {

    /*************************/
    /*** Local Var Structs ***/
    /*************************/

    struct DrawDebtLocalVars {
        uint256 borrowerDebt; // [WAD] borrower's accrued debt
        uint256 debtChange;   // [WAD] additional debt resulted from draw debt action
        bool    inAuction;    // true if loan is auctioned
        uint256 lupId;        // id of new LUP
        bool    stampT0Np;    // true if loan's t0 neutral price should be restamped (when drawing debt or pledge settles auction)
    }
    struct RepayDebtLocalVars {
        uint256 borrowerDebt;          // [WAD] borrower's accrued debt
        bool    inAuction;             // true if loan still in auction after repay, false otherwise
        uint256 newLup;                // [WAD] LUP after repay debt action
        bool    pull;                  // true if pull action
        bool    repay;                 // true if repay action
        bool    stampT0Np;             // true if loan's t0 neutral price should be restamped (when repay settles auction or pull collateral)
        uint256 t0DebtInAuctionChange; // [WAD] t0 change amount of debt after repayment
        uint256 t0RepaidDebt;          // [WAD] t0 debt repaid
    }

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error BorrowerNotSender();
    error BorrowerUnderCollateralized();
    error InsufficientCollateral();
    error LimitIndexReached();
    error NoDebt();

    /***************************/
    /***  External Functions ***/
    /***************************/

    /**
     *  @notice See `IERC20PoolBorrowerActions` and `IERC721PoolBorrowerActions` for descriptions
     *  @dev    write state:
     *              - Auctions._settleAuction:
     *                  - _removeAuction:
     *                      - decrement kicker locked accumulator, increment kicker claimable accumumlator
     *                      - decrement auctions count accumulator
     *                      - decrement auctions.totalBondEscrowed accumulator
     *                      - update auction queue state
     *              - Loans.update:
     *                  - _upsert:
     *                      - insert or update loan in loans array
     *                  - remove:
     *                      - remove loan from loans array
     *                  - update borrower in address => borrower mapping
     *  @dev    reverts on:
     *              - borrower not sender BorrowerNotSender()
     *              - borrower debt less than pool min debt AmountLTMinDebt()
     *              - limit price reached LimitIndexReached()
     *              - borrower cannot draw more debt BorrowerUnderCollateralized()
     *  @dev    emit events:
     *              - Auctions._settleAuction:
     *                  - AuctionNFTSettle or AuctionSettle
     */
    function drawDebt(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState    storage loans_,
        PoolState calldata poolState_,
        address borrowerAddress_,
        uint256 amountToBorrow_,
        uint256 limitIndex_,
        uint256 collateralToPledge_
    ) external returns (
        DrawDebtResult memory result_
    ) {
        Borrower memory borrower = loans_.borrowers[borrowerAddress_];

        result_.poolDebt       = poolState_.debt;
        result_.newLup         = _lup(deposits_, result_.poolDebt);
        result_.poolCollateral = poolState_.collateral;

        DrawDebtLocalVars memory vars;

        vars.borrowerDebt = Maths.wmul(borrower.t0Debt, poolState_.inflator);

        // pledge collateral to pool
        if (collateralToPledge_ != 0) {
            // add new amount of collateral to pledge to borrower balance
            borrower.collateral  += collateralToPledge_;

            // load loan's auction state
            vars.inAuction = _inAuction(auctions_, borrowerAddress_);
            // if loan is auctioned and becomes collateralized by newly pledged collateral then settle auction
            if (
                vars.inAuction &&
                _isCollateralized(vars.borrowerDebt, borrower.collateral, result_.newLup, poolState_.poolType)
            ) {
                // borrower becomes collateralized
                vars.inAuction = false;
                vars.stampT0Np = true;  // stamp borrower t0Np when exiting from auction

                result_.settledAuction = true;

                // remove debt from pool accumulator and settle auction
                result_.t0DebtInAuctionChange = borrower.t0Debt;

                // settle auction and update borrower's collateral with value after settlement
                result_.remainingCollateral = Auctions._settleAuction(
                    auctions_,
                    buckets_,
                    deposits_,
                    borrowerAddress_,
                    borrower.collateral,
                    poolState_.poolType
                );

                borrower.collateral = result_.remainingCollateral;
            }

            // add new amount of collateral to pledge to pool balance
            result_.poolCollateral += collateralToPledge_;
        }

        // borrow against pledged collateral
        // check both values to enable an intentional 0 borrow loan call to update borrower's loan state
        if (amountToBorrow_ != 0 || limitIndex_ != 0) {
            // only intended recipient can borrow quote
            if (borrowerAddress_ != msg.sender) revert BorrowerNotSender();

            // add origination fee to the amount to borrow and add to borrower's debt
            vars.debtChange = Maths.wmul(amountToBorrow_, _feeRate(poolState_.rate) + Maths.WAD);

            vars.borrowerDebt += vars.debtChange;

            // check that drawing debt doesn't leave borrower debt under min debt amount
            _revertOnMinDebt(loans_, result_.poolDebt, vars.borrowerDebt, poolState_.quoteDustLimit);

            // add debt change to pool's debt
            result_.poolDebt += vars.debtChange;

            // determine new lup index and revert if borrow happens at a price higher than the specified limit (lower index than lup index)
            vars.lupId = _lupIndex(deposits_, result_.poolDebt);
            if (vars.lupId > limitIndex_) revert LimitIndexReached();

            // calculate new lup and check borrow action won't push borrower into a state of under-collateralization
            // this check also covers the scenario when loan is already auctioned
            result_.newLup = _priceAt(vars.lupId);

            if (!_isCollateralized(vars.borrowerDebt, borrower.collateral, result_.newLup, poolState_.poolType)) {
                revert BorrowerUnderCollateralized();
            }

            // stamp borrower t0Np when draw debt
            vars.stampT0Np = true;

            result_.t0DebtChange = Maths.wdiv(vars.debtChange, poolState_.inflator);

            borrower.t0Debt += result_.t0DebtChange;
        }

        // update loan state
        Loans.update(
            loans_,
            auctions_,
            deposits_,
            borrower,
            borrowerAddress_,
            vars.borrowerDebt,
            poolState_.rate,
            result_.newLup,
            vars.inAuction,
            vars.stampT0Np
        );
    }

    /**
     *  @notice See `IERC20PoolBorrowerActions` and `IERC721PoolBorrowerActions` for descriptions
     *  @dev    write state:
     *              - Auctions._settleAuction:
     *                  - _removeAuction:
     *                      - decrement kicker locked accumulator, increment kicker claimable accumumlator
     *                      - decrement auctions count accumulator
     *                      - decrement auctions.totalBondEscrowed accumulator
     *                      - update auction queue state
     *              - Loans.update:
     *                  - _upsert:
     *                      - insert or update loan in loans array
     *                  - remove:
     *                      - remove loan from loans array
     *                  - update borrower in address => borrower mapping
     *  @dev    reverts on:
     *              - no debt to repay NoDebt()
     *              - borrower debt less than pool min debt AmountLTMinDebt()
     *              - borrower not sender BorrowerNotSender()
     *              - not enough collateral to pull InsufficientCollateral()
     *  @dev    emit events:
     *              - Auctions._settleAuction:
     *                  - AuctionNFTSettle or AuctionSettle
     */
    function repayDebt(
        AuctionsState storage auctions_,
        mapping(uint256 => Bucket) storage buckets_,
        DepositsState storage deposits_,
        LoansState    storage loans_,
        PoolState calldata poolState_,
        address borrowerAddress_,
        uint256 maxQuoteTokenAmountToRepay_,
        uint256 collateralAmountToPull_
    ) external returns (
        RepayDebtResult memory result_
    ) {
        Borrower memory borrower = loans_.borrowers[borrowerAddress_];

        RepayDebtLocalVars memory vars;

        vars.repay        = maxQuoteTokenAmountToRepay_ != 0;
        vars.pull         = collateralAmountToPull_ != 0;
        vars.borrowerDebt = Maths.wmul(borrower.t0Debt, poolState_.inflator);

        result_.poolDebt       = poolState_.debt;
        result_.poolCollateral = poolState_.collateral;

        if (vars.repay) {
            if (borrower.t0Debt == 0) revert NoDebt();

            if (maxQuoteTokenAmountToRepay_ == type(uint256).max) {
                result_.t0RepaidDebt = borrower.t0Debt;
            } else {
                result_.t0RepaidDebt = Maths.min(
                    borrower.t0Debt,
                    Maths.wdiv(maxQuoteTokenAmountToRepay_, poolState_.inflator)
                );
            }

            result_.quoteTokenToRepay = Maths.wmul(result_.t0RepaidDebt, poolState_.inflator);

            result_.poolDebt -= result_.quoteTokenToRepay;
            vars.borrowerDebt -= result_.quoteTokenToRepay;

            // check that paying the loan doesn't leave borrower debt under min debt amount
            _revertOnMinDebt(loans_, result_.poolDebt, vars.borrowerDebt, poolState_.quoteDustLimit);

            result_.newLup = _lup(deposits_, result_.poolDebt);
            vars.inAuction = _inAuction(auctions_, borrowerAddress_);

            if (vars.inAuction) {
                if (_isCollateralized(vars.borrowerDebt, borrower.collateral, result_.newLup, poolState_.poolType)) {
                    // borrower becomes re-collateralized
                    vars.inAuction = false;
                    vars.stampT0Np = true;  // stamp borrower t0Np when exiting from auction

                    result_.settledAuction = true;

                    // remove entire borrower debt from pool auctions debt accumulator
                    result_.t0DebtInAuctionChange = borrower.t0Debt;

                    // settle auction and update borrower's collateral with value after settlement
                    result_.remainingCollateral = Auctions._settleAuction(
                        auctions_,
                        buckets_,
                        deposits_,
                        borrowerAddress_,
                        borrower.collateral,
                        poolState_.poolType
                    );

                    borrower.collateral = result_.remainingCollateral;
                } else {
                    // partial repay, remove only the paid debt from pool auctions debt accumulator
                    result_.t0DebtInAuctionChange = result_.t0RepaidDebt;
                }
            }

            borrower.t0Debt -= result_.t0RepaidDebt;
        }

        if (vars.pull) {
            // only intended recipient can pull collateral
            if (borrowerAddress_ != msg.sender) revert BorrowerNotSender();

            // calculate LUP only if it wasn't calculated by repay action
            if (!vars.repay) result_.newLup = _lup(deposits_, result_.poolDebt);

            uint256 encumberedCollateral = borrower.t0Debt != 0 ? Maths.wdiv(vars.borrowerDebt, result_.newLup) : 0;

            if (borrower.collateral - encumberedCollateral < collateralAmountToPull_) revert InsufficientCollateral();

            // stamp borrower t0Np when pull collateral action
            vars.stampT0Np = true;

            borrower.collateral    -= collateralAmountToPull_;
            result_.poolCollateral -= collateralAmountToPull_;
        }

        // calculate LUP if repay is called with 0 amount
        if (!vars.repay && !vars.pull) {
            result_.newLup = _lup(deposits_, result_.poolDebt);
        }

        // update loan state
        Loans.update(
            loans_,
            auctions_,
            deposits_,
            borrower,
            borrowerAddress_,
            vars.borrowerDebt,
            poolState_.rate,
            result_.newLup,
            vars.inAuction,
            vars.stampT0Np
        );
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @notice Returns true if borrower is in auction.
     *  @dev    Used to accuratley increment and decrement t0DebtInAuction.
     *  @param  borrower_ Borrower address to check auction status for.
     *  @return  active_ Boolean, based on if borrower is in auction.
     */
    function _inAuction(
        AuctionsState storage auctions_,
        address borrower_
    ) internal view returns (bool) {
        return auctions_.liquidations[borrower_].kickTime != 0;
    }

    function _lupIndex(
        DepositsState storage deposits_,
        uint256 debt_
    ) internal view returns (uint256) {
        return Deposits.findIndexOfSum(deposits_, debt_);
    }

    function _lup(
        DepositsState storage deposits_,
        uint256 debt_
    ) internal view returns (uint256) {
        return _priceAt(_lupIndex(deposits_, debt_));
    }

}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import { PRBMathSD59x18 } from "@prb-math/contracts/PRBMathSD59x18.sol";

import { PoolType } from '../../interfaces/pool/IPool.sol';

import { Buckets } from '../internal/Buckets.sol';
import { Maths }   from '../internal/Maths.sol';

    error BucketIndexOutOfBounds();
    error BucketPriceOutOfBounds();

    /*************************/
    /*** Price Conversions ***/
    /*************************/

    /**
        @dev constant price indices defining the min and max of the potential price range
     */
    int256  constant MAX_BUCKET_INDEX  =  4_156;
    int256  constant MIN_BUCKET_INDEX  = -3_232;
    uint256 constant MAX_FENWICK_INDEX =  7_388;

    uint256 constant MIN_PRICE = 99_836_282_890;
    uint256 constant MAX_PRICE = 1_004_968_987.606512354182109771 * 1e18;
    /**
        @dev step amounts in basis points. This is a constant across pools at .005, achieved by dividing WAD by 10,000
     */
    int256 constant FLOAT_STEP_INT = 1.005 * 1e18;

    /**
     *  @notice Calculates the price for a given Fenwick index
     *  @dev    Throws if index exceeds maximum constant
     *  @dev    Uses fixed-point math to get around lack of floating point numbers in EVM
     *  @dev    Price expected to be inputted as a 18 decimal WAD
     *  @dev    Fenwick index is converted to bucket index
     *  @dev    Fenwick index to bucket index conversion
     *          1.00      : bucket index 0,     fenwick index 4146: 7388-4156-3232=0
     *          MAX_PRICE : bucket index 4156,  fenwick index 0:    7388-0-3232=4156.
     *          MIN_PRICE : bucket index -3232, fenwick index 7388: 7388-7388-3232=-3232.
     *  @dev    V1: price = MIN_PRICE + (FLOAT_STEP * index)
     *          V2: price = MAX_PRICE * (FLOAT_STEP ** (abs(int256(index - MAX_PRICE_INDEX))));
     *          V3 (final): x^y = 2^(y*log_2(x))
     */
    function _priceAt(
        uint256 index_
    ) pure returns (uint256) {
        // Lowest Fenwick index is highest price, so invert the index and offset by highest bucket index.
        int256 bucketIndex = MAX_BUCKET_INDEX - int256(index_);
        if (bucketIndex < MIN_BUCKET_INDEX || bucketIndex > MAX_BUCKET_INDEX) revert BucketIndexOutOfBounds();

        return uint256(
            PRBMathSD59x18.exp2(
                PRBMathSD59x18.mul(
                    PRBMathSD59x18.fromInt(bucketIndex),
                    PRBMathSD59x18.log2(FLOAT_STEP_INT)
                )
            )
        );
    }

    /**
     *  @notice Calculates the Fenwick index for a given price
     *  @dev    Throws if price exceeds maximum constant
     *  @dev    Price expected to be inputted as a 18 decimal WAD
     *  @dev    V1: bucket index = (price - MIN_PRICE) / FLOAT_STEP
     *          V2: bucket index = (log(FLOAT_STEP) * price) /  MAX_PRICE
     *          V3 (final): bucket index =  log_2(price) / log_2(FLOAT_STEP)
     *  @dev    Fenwick index = 7388 - bucket index + 3232
     */
    function _indexOf(
        uint256 price_
    ) pure returns (uint256) {
        if (price_ < MIN_PRICE || price_ > MAX_PRICE) revert BucketPriceOutOfBounds();

        int256 index = PRBMathSD59x18.div(
            PRBMathSD59x18.log2(int256(price_)),
            PRBMathSD59x18.log2(FLOAT_STEP_INT)
        );

        int256 ceilIndex = PRBMathSD59x18.ceil(index);
        if (index < 0 && ceilIndex - index > 0.5 * 1e18) {
            return uint256(4157 - PRBMathSD59x18.toInt(ceilIndex));
        }
        return uint256(4156 - PRBMathSD59x18.toInt(ceilIndex));
    }

    /**********************/
    /*** Pool Utilities ***/
    /**********************/

    /**
     *  @notice Calculates the minimum debt amount that can be borrowed or can remain in a loan in pool.
     *  @param  debt_          The debt amount to calculate minimum debt amount for.
     *  @param  loansCount_    The number of loans in pool.
     *  @return minDebtAmount_ Minimum debt amount value of the pool.
     */
    function _minDebtAmount(
        uint256 debt_,
        uint256 loansCount_
    ) pure returns (uint256 minDebtAmount_) {
        if (loansCount_ != 0) {
            minDebtAmount_ = Maths.wdiv(Maths.wdiv(debt_, Maths.wad(loansCount_)), 10**19);
        }
    }

    /**
     *  @notice Calculates fee rate for a given interest rate.
     *  @notice Calculated as greater of the current annualized interest rate divided by 52 (one week of interest) or 5 bps.
     *  @param  interestRate_ The current interest rate.
     *  @return Fee rate applied to the given interest rate.
     */
    function _feeRate(
        uint256 interestRate_
    ) pure returns (uint256) {
        // greater of the current annualized interest rate divided by 52 (one week of interest) or 5 bps
        return Maths.max(Maths.wdiv(interestRate_, 52 * 1e18), 0.0005 * 1e18);
    }

    /**
     *  @notice Calculates Pool Threshold Price (PTP) for a given debt and collateral amount.
     *  @param  debt_       The debt amount to calculate PTP for.
     *  @param  collateral_ The amount of collateral to calculate PTP for.
     *  @return ptp_        Pool Threshold Price value.
     */
    function _ptp(
        uint256 debt_,
        uint256 collateral_
    ) pure returns (uint256 ptp_) {
        if (collateral_ != 0) ptp_ = Maths.wdiv(debt_, collateral_);
    }

    /**
     *  @notice Collateralization calculation.
     *  @param debt_       Debt to calculate collateralization for.
     *  @param collateral_ Collateral to calculate collateralization for.
     *  @param price_      Price to calculate collateralization for.
     *  @param type_       Type of the pool.
     *  @return True if collateralization calculated is equal or greater than 1.
     */
    function _isCollateralized(
        uint256 debt_,
        uint256 collateral_,
        uint256 price_,
        uint8 type_
    ) pure returns (bool) {
        if (type_ == uint8(PoolType.ERC20)) return Maths.wmul(collateral_, price_) >= debt_;
        else {
            //slither-disable-next-line divide-before-multiply
            collateral_ = (collateral_ / Maths.WAD) * Maths.WAD; // use collateral floor
            return Maths.wmul(collateral_, price_) >= debt_;
        }
    }

    /**
     *  @notice Price precision adjustment used in calculating collateral dust for a bucket.
     *          To ensure the accuracy of the exchange rate calculation, buckets with smaller prices require
     *          larger minimum amounts of collateral.  This formula imposes a lower bound independent of token scale.
     *  @param  bucketIndex_              Index of the bucket, or 0 for encumbered collateral with no bucket affinity.
     *  @return pricePrecisionAdjustment_ Unscaled integer of the minimum number of decimal places the dust limit requires.
     */
    function _getCollateralDustPricePrecisionAdjustment(
        uint256 bucketIndex_
    ) pure returns (uint256 pricePrecisionAdjustment_) {
        // conditional is a gas optimization
        if (bucketIndex_ > 3900) {
            int256 bucketOffset = int256(bucketIndex_ - 3900);
            int256 result = PRBMathSD59x18.sqrt(PRBMathSD59x18.div(bucketOffset * 1e18, int256(36 * 1e18)));
            pricePrecisionAdjustment_ = uint256(result / 1e18);
        }
    }

    /**
     *  @notice Returns the amount of collateral calculated for the given amount of LPs.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLPs_        Amount of LPs in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / LPs.
     *  @param  lenderLPsBalance_ The amount of LPs to calculate collateral for.
     *  @param  bucketPrice_      Bucket price.
     *  @return collateralAmount_ Amount of collateral calculated for the given LPs amount.
     */
    function _lpsToCollateral(
        uint256 bucketCollateral_,
        uint256 bucketLPs_,
        uint256 deposit_,
        uint256 lenderLPsBalance_,
        uint256 bucketPrice_
    ) pure returns (uint256 collateralAmount_) {
        // max collateral to lps
        uint256 rate = Buckets.getExchangeRate(bucketCollateral_, bucketLPs_, deposit_, bucketPrice_);

        collateralAmount_ = Maths.rwdivw(Maths.rmul(lenderLPsBalance_, rate), bucketPrice_);

        if (collateralAmount_ > bucketCollateral_) {
            // user is owed more collateral than is available in the bucket
            collateralAmount_ = bucketCollateral_;
        }
    }

    /**
     *  @notice Returns the amount of quote tokens calculated for the given amount of LPs.
     *  @param  bucketLPs_        Amount of LPs in bucket.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  deposit_          Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / LPs.
     *  @param  lenderLPsBalance_ The amount of LPs to calculate quote token amount for.
     *  @param  maxQuoteToken_    The max quote token amount to calculate LPs for.
     *  @param  bucketPrice_      Bucket price.
     *  @return quoteTokenAmount_ Amount of quote tokens calculated for the given LPs amount.
     */
    function _lpsToQuoteToken(
        uint256 bucketLPs_,
        uint256 bucketCollateral_,
        uint256 deposit_,
        uint256 lenderLPsBalance_,
        uint256 maxQuoteToken_,
        uint256 bucketPrice_
    ) pure returns (uint256 quoteTokenAmount_) {
        uint256 rate = Buckets.getExchangeRate(bucketCollateral_, bucketLPs_, deposit_, bucketPrice_);

        quoteTokenAmount_ = Maths.rayToWad(Maths.rmul(lenderLPsBalance_, rate));

        if (quoteTokenAmount_ > deposit_)       quoteTokenAmount_ = deposit_;
        if (quoteTokenAmount_ > maxQuoteToken_) quoteTokenAmount_ = maxQuoteToken_;
    }

    /**
     *  @notice Rounds a token amount down to the minimum amount permissible by the token scale.
     *  @param  amount_       Value to be rounded.
     *  @param  tokenScale_   Scale of the token, presented as a power of 10.
     *  @return scaledAmount_ Rounded value.
     */
    function _roundToScale(
        uint256 amount_,
        uint256 tokenScale_
    ) pure returns (uint256 scaledAmount_) {
        scaledAmount_ = (amount_ / tokenScale_) * tokenScale_;
    }

    /**
     *  @notice Rounds a token amount up to the next amount permissible by the token scale.
     *  @param  amount_       Value to be rounded.
     *  @param  tokenScale_   Scale of the token, presented as a power of 10.
     *  @return scaledAmount_ Rounded value.
     */
    function _roundUpToScale(
        uint256 amount_,
        uint256 tokenScale_
    ) pure returns (uint256 scaledAmount_) {
        if (amount_ % tokenScale_ == 0)
            scaledAmount_ = amount_;
        else
            scaledAmount_ = _roundToScale(amount_, tokenScale_) + tokenScale_;
    }

    /*********************************/
    /*** Reserve Auction Utilities ***/
    /*********************************/

    uint256 constant MINUTE_HALF_LIFE    = 0.988514020352896135_356867505 * 1e27;  // 0.5^(1/60)

    function _claimableReserves(
        uint256 debt_,
        uint256 poolSize_,
        uint256 totalBondEscrowed_,
        uint256 reserveAuctionUnclaimed_,
        uint256 quoteTokenBalance_
    ) pure returns (uint256 claimable_) {
        claimable_ = Maths.wmul(0.995 * 1e18, debt_) + quoteTokenBalance_;

        claimable_ -= Maths.min(claimable_, poolSize_ + totalBondEscrowed_ + reserveAuctionUnclaimed_);
    }

    function _reserveAuctionPrice(
        uint256 reserveAuctionKicked_
    ) view returns (uint256 _price) {
        if (reserveAuctionKicked_ != 0) {
            uint256 secondsElapsed   = block.timestamp - reserveAuctionKicked_;
            uint256 hoursComponent   = 1e27 >> secondsElapsed / 3600;
            uint256 minutesComponent = Maths.rpow(MINUTE_HALF_LIFE, secondsElapsed % 3600 / 60);

            _price = Maths.rayToWad(1_000_000_000 * Maths.rmul(hoursComponent, minutesComponent));
        }
    }

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import {
    AuctionsState,
    Borrower,
    DepositsState,
    LoansState,
    PoolBalancesState
} from '../../interfaces/pool/commons/IPoolState.sol';

import { _minDebtAmount } from './PoolHelper.sol';

import { Loans }    from '../internal/Loans.sol';
import { Deposits } from '../internal/Deposits.sol';
import { Maths }    from '../internal/Maths.sol';

    // See `IPoolErrors` for descriptions
    error AuctionNotCleared();
    error AmountLTMinDebt();
    error DustAmountNotExceeded();
    error RemoveDepositLockedByAuctionDebt();

    /**
     *  @notice Called by LPB removal functions assess whether or not LPB is locked.
     *  @param  index_    The deposit index from which LPB is attempting to be removed.
     *  @param  inflator_ The pool inflator used to properly assess t0 debt in auctions.
     */
    function _revertIfAuctionDebtLocked(
        DepositsState storage deposits_,
        PoolBalancesState storage poolBalances_,
        uint256 index_,
        uint256 inflator_
    ) view {
        uint256 t0AuctionDebt = poolBalances_.t0DebtInAuction;
        if (t0AuctionDebt != 0 ) {
            // deposit in buckets within liquidation debt from the top-of-book down are frozen.
            if (index_ <= Deposits.findIndexOfSum(deposits_, Maths.wmul(t0AuctionDebt, inflator_))) revert RemoveDepositLockedByAuctionDebt();
        } 
    }

    /**
     *  @notice Check if head auction is clearable (auction is kicked and 72 hours passed since kick time or auction still has debt but no remaining collateral).
     *  @notice Revert if auction is clearable
     */
    function _revertIfAuctionClearable(
        AuctionsState storage auctions_,
        LoansState    storage loans_
    ) view {
        address head     = auctions_.head;
        uint256 kickTime = auctions_.liquidations[head].kickTime;
        if (kickTime != 0) {
            if (block.timestamp - kickTime > 72 hours) revert AuctionNotCleared();

            Borrower storage borrower = loans_.borrowers[head];
            if (borrower.t0Debt != 0 && borrower.collateral == 0) revert AuctionNotCleared();
        }
    }

    function _revertOnMinDebt(
        LoansState storage loans_,
        uint256 poolDebt_,
        uint256 borrowerDebt_,
        uint256 quoteDust_
    ) view {
        if (borrowerDebt_ != 0) {
            uint256 loansCount = Loans.noOfLoans(loans_);
            if (loansCount >= 10) {
                if (borrowerDebt_ < _minDebtAmount(poolDebt_, loansCount)) revert AmountLTMinDebt();
            } else {
                if (borrowerDebt_ < quoteDust_)                            revert DustAmountNotExceeded();
            }
        }
    }

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import { Bucket, Lender } from '../../interfaces/pool/commons/IPoolState.sol';

import { Maths } from './Maths.sol';

/**
    @title  Buckets library
    @notice Internal library containing common logic for buckets management.
 */
library Buckets {

    /**************/
    /*** Events ***/
    /**************/

    // See `IPoolError` for descriptions
    error BucketBankruptcyBlock();

    /***********************************/
    /*** Bucket Management Functions ***/
    /***********************************/

    /**
     *  @notice Add collateral to a bucket and updates LPs for bucket and lender with the amount coresponding to collateral amount added.
     *  @dev    Increment bucket.collateral and bucket.lps accumulator
     *             - addLenderLPs:
     *               - increment lender.lps accumulator and lender.depositTime state
     *  @param  lender_                Address of the lender.
     *  @param  deposit_               Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / LPs
     *  @param  collateralAmountToAdd_ Additional collateral amount to add to bucket.
     *  @param  bucketPrice_           Bucket price.
     *  @return addedLPs_              Amount of bucket LPs for the collateral amount added.
     */
    function addCollateral(
        Bucket storage bucket_,
        address lender_,
        uint256 deposit_,
        uint256 collateralAmountToAdd_,
        uint256 bucketPrice_
    ) internal returns (uint256 addedLPs_) {
        // cannot deposit in the same block when bucket becomes insolvent
        uint256 bankruptcyTime = bucket_.bankruptcyTime;
        if (bankruptcyTime == block.timestamp) revert BucketBankruptcyBlock();

        // calculate amount of LPs to be added for the amount of collateral added to bucket
        addedLPs_ = collateralToLPs(
            bucket_.collateral,
            bucket_.lps,
            deposit_,
            collateralAmountToAdd_,
            bucketPrice_
        );
        // update bucket LPs balance and collateral

        // update bucket collateral
        bucket_.collateral += collateralAmountToAdd_;
        // update bucket and lender LPs balance and deposit timestamp
        bucket_.lps += addedLPs_;

        addLenderLPs(bucket_, bankruptcyTime, lender_, addedLPs_);
    }

    /**
     *  @notice Add amount of LPs for a given lender in a given bucket.
     *  @dev    Increments bucket.collateral and bucket.lps accumulator state.
     *  @param  bucket_         Bucket to record lender LPs.
     *  @param  bankruptcyTime_ Time when bucket become insolvent.
     *  @param  lender_         Lender address to add LPs for in the given bucket.
     *  @param  lpsAmount_      Amount of LPs to be recorded for the given lender.
     */
    function addLenderLPs(
        Bucket storage bucket_,
        uint256 bankruptcyTime_,
        address lender_,
        uint256 lpsAmount_
    ) internal {
        Lender storage lender = bucket_.lenders[lender_];

        if (bankruptcyTime_ >= lender.depositTime) lender.lps = lpsAmount_;
        else lender.lps += lpsAmount_;

        lender.depositTime = block.timestamp;
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @notice Returns the amount of bucket LPs calculated for the given amount of collateral.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLPs_        Amount of LPs in bucket.
     *  @param  deposit_     Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / LPs.
     *  @param  collateral_  The amount of collateral to calculate bucket LPs for.
     *  @param  bucketPrice_ Price bucket.
     *  @return lps_         Amount of LPs calculated for the amount of collateral.
     */
    function collateralToLPs(
        uint256 bucketCollateral_,
        uint256 bucketLPs_,
        uint256 deposit_,
        uint256 collateral_,
        uint256 bucketPrice_
    ) internal pure returns (uint256 lps_) {
        uint256 rate = getExchangeRate(bucketCollateral_, bucketLPs_, deposit_, bucketPrice_);

        lps_ = (collateral_ * bucketPrice_ * 1e18 + rate / 2) / rate;
    }

    /**
     *  @notice Returns the amount of LPs calculated for the given amount of quote tokens.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLPs_        Amount of LPs in bucket.
     *  @param  deposit_     Current bucket deposit (quote tokens). Used to calculate bucket's exchange rate / LPs.
     *  @param  quoteTokens_ The amount of quote tokens to calculate LPs amount for.
     *  @param  bucketPrice_ Price bucket.
     *  @return The amount of LPs coresponding to the given quote tokens in current bucket.
     */
    function quoteTokensToLPs(
        uint256 bucketCollateral_,
        uint256 bucketLPs_,
        uint256 deposit_,
        uint256 quoteTokens_,
        uint256 bucketPrice_
    ) internal pure returns (uint256) {
        return Maths.rdiv(
            Maths.wadToRay(quoteTokens_),
            getExchangeRate(bucketCollateral_, bucketLPs_, deposit_, bucketPrice_)
        );
    }

    /**
     *  @notice Returns the exchange rate for a given bucket.
     *  @param  bucketCollateral_ Amount of collateral in bucket.
     *  @param  bucketLPs_        Amount of LPs in bucket.
     *  @param  bucketDeposit_    The amount of quote tokens deposited in the given bucket.
     *  @param  bucketPrice_      Bucket's price.
     */
    function getExchangeRate(
        uint256 bucketCollateral_,
        uint256 bucketLPs_,
        uint256 bucketDeposit_,
        uint256 bucketPrice_
    ) internal pure returns (uint256) {
        return bucketLPs_ == 0
            ? Maths.RAY
            : (bucketDeposit_ * 1e18 + bucketPrice_ * bucketCollateral_) * 1e18 / bucketLPs_;
            // 10^36 * 1e18 / 10^27 = 10^54 / 10^27 = 10^27
    }

    /**
     *  @notice Returns the unscaled exchange rate for a given bucket.
     *  @param  bucketCollateral_       Amount of collateral in bucket.
     *  @param  bucketLPs_              Amount of LPs in bucket.
     *  @param  bucketUnscaledDeposit_  The amount of unscaled Fenwick tree amount in bucket.
     *  @param  bucketScale_            Bucket scale factor
     *  @param  bucketPrice_            Bucket's price.
     */
    function getUnscaledExchangeRate(
        uint256 bucketCollateral_,
        uint256 bucketLPs_,
        uint256 bucketUnscaledDeposit_,
        uint256 bucketScale_,
        uint256 bucketPrice_
    ) internal pure returns (uint256) {
        return bucketLPs_ == 0
            ? Maths.RAY
            : (bucketUnscaledDeposit_ + bucketPrice_ * bucketCollateral_ / bucketScale_ ) * 10**36 / bucketLPs_;
            // 10^18 * 1e36 / 10^27 = 10^54 / 10^27 = 10^27
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import { DepositsState } from '../../interfaces/pool/commons/IPoolState.sol';

import { _priceAt, MAX_FENWICK_INDEX } from '../helpers/PoolHelper.sol';

import { Maths } from './Maths.sol';

/**
    @title  Deposits library
    @notice Internal library containing common logic for deposits management.
    @dev    Implemented as Fenwick Tree data structure.
 */
library Deposits {

    // Max index supported in the Fenwick tree
    uint256 internal constant SIZE = 8192;

    /**
     *  @notice increase a value in the FenwickTree at an index.
     *  @dev    Starts at leaf/target and moved up towards root
     *  @param  index_             The deposit index.
     *  @param  unscaledAddAmount_ The unscaled amount to increase deposit by.
     */
    function unscaledAdd(
        DepositsState storage deposits_,
        uint256 index_,
        uint256 unscaledAddAmount_
    ) internal {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++index_;

        // unscaledAddAmount_ is the raw amount to add directly to the value at index_, unaffected by the scale array
        // For example, to denote an amount of deposit added to the array, we would need to call unscaledAdd with
        // (deposit amount) / scale(index).  There are two reasons for this:
        // 1- scale(index) is often already known in the context of where unscaledAdd(..) is called, and we want to avoid
        //    redundant iterations through the Fenwick tree.
        // 2- We often need to precisely change the value in the tree, avoiding the rounding that dividing by scale(index).
        //    This is more relevant to unscaledRemove(...), where we need to ensure the value is precisely set to 0, but we
        //    also prefer it here for consistency.
        
        while (index_ <= SIZE) {
            uint256 value    = deposits_.values[index_];
            uint256 scaling  = deposits_.scaling[index_];

            // Compute the new value to be put in location index_
            uint256 newValue = value + unscaledAddAmount_;

            // Update unscaledAddAmount to propogate up the Fenwick tree
            // Note: we can't just multiply addAmount_ by scaling[i_] due to rounding
            // We need to track the precice change in values[i_] in order to ensure
            // obliterated indices remain zero after subsequent adding to related indices
            // if scaling==0, the actual scale value is 1, otherwise it is scaling
            if (scaling != 0) unscaledAddAmount_ = Maths.wmul(newValue, scaling) - Maths.wmul(value, scaling);

            deposits_.values[index_] = newValue;

            // traverse upwards through tree via "update" route
            index_ += lsb(index_);
        }
    }

    /**
     *  @notice Finds index and sum of first bucket that EXCEEDS the given sum
     *  @dev    Used in lup calculation
     *  @param  targetSum_     The sum to find index for.
     *  @return sumIndex_      Smallest index where prefixsum greater than the sum
     *  @return sumIndexSum_   Sum at index PRECEDING sumIndex_
     *  @return sumIndexScale_ Scale of bucket PRECEDING sumIndex_
     */
    function findIndexAndSumOfSum(
        DepositsState storage deposits_,
        uint256 targetSum_
    ) internal view returns (uint256 sumIndex_, uint256 sumIndexSum_, uint256 sumIndexScale_) {
        // i iterates over bits from MSB to LSB.  We check at each stage if the target sum is to the left or right of sumIndex_+i
        uint256 i  = 4096; // 1 << (_numBits - 1) = 1 << (13 - 1) = 4096
        uint256 runningScale = Maths.WAD;

        // We construct the target sumIndex_ bit by bit, from MSB to LSB.  lowerIndexSum_ always maintains the sum
        // up to the current value of sumIndex_
        uint256 lowerIndexSum;

        while (i > 0) {
            // Consider if the target index is less than or greater than sumIndex_ + i
            uint256 value   = deposits_.values[sumIndex_ + i];
            uint256 scaling = deposits_.scaling[sumIndex_ + i];

            // Compute sum up to sumIndex_ + i
            uint256 scaledValue =
                lowerIndexSum +
                (scaling != 0 ?  Maths.wmul(Maths.wmul(runningScale, scaling), value) : Maths.wmul(runningScale, value));

            if (scaledValue  < targetSum_) {
                // Target value is too small, need to consider increasing sumIndex_ still
                if (sumIndex_ + i <= MAX_FENWICK_INDEX) {
                    // sumIndex_+i is in range of Fenwick prices.  Target index has this bit set to 1.  
                    sumIndex_ += i;
                    lowerIndexSum = scaledValue;
                }
            } else {
                // Target index has this bit set to 0
                // scaling == 0 means scale factor == 1, otherwise scale factor == scaling
                if (scaling != 0) runningScale = Maths.wmul(runningScale, scaling);

                // Current scaledValue is <= targetSum_, it's a candidate value for sumIndexSum_
                sumIndexSum_   = scaledValue;
                sumIndexScale_ = runningScale;
            }
            // Shift i to next less significant bit
            i = i >> 1;
        }
    }

    /**
     *  @notice Finds index of passed sum.  Helper function for findIndexAndSumOfSum
     *  @dev    Used in lup calculation
     *  @param  sum_      The sum to find index for.
     *  @return sumIndex_ Smallest index where prefixsum greater than the sum
     */
    function findIndexOfSum(
        DepositsState storage deposits_,
        uint256 sum_
    ) internal view returns (uint256 sumIndex_) {
        (sumIndex_,,) = findIndexAndSumOfSum(deposits_, sum_);
    }

    /**
     *  @notice Get least significant bit (LSB) of intiger, i_.
     *  @dev    Used primarily to decrement the binary index in loops, iterating over range parents.
     *  @param  i_  The integer with which to return the LSB.
     */
    function lsb(
        uint256 i_
    ) internal pure returns (uint256 lsb_) {
        if (i_ != 0) {
            // "i & (-i)"
            lsb_ = i_ & ((i_ ^ 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff) + 1);
        }
    }

    /**
     *  @notice Scale values in the tree from the index provided, upwards.
     *  @dev    Starts at passed in node and increments through range parent nodes, and ends at 8192.
     *  @param  index_   The index to start scaling from.
     *  @param  factor_  The factor to scale the values by.
     */
    function mult(
        DepositsState storage deposits_,
        uint256 index_,
        uint256 factor_
    ) internal {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++index_;

        uint256 sum;
        uint256 value;
        uint256 scaling;
        uint256 bit = lsb(index_);

        // Starting with the LSB of index, we iteratively move up towards the MSB of SIZE
        // Case 1:     the bit of index_ is set to 1.  In this case, the entire subtree below index_
        //             is scaled.  So, we include factor_ into scaleing[index_], and remember in sum how much
        //             we increased the subtree by, so that we can use it in case we encounter 0 bits (below).
        // Case 2:     The bit of index_ is set to 0.  In this case, consider the subtree below the node
        //             index_+bit. The subtree below that is not entirely scaled, but it does contain the
        //             subtree what was scaled earlier.  Therefore: we need to increment it's stored value
        //             (in sum) which was set in a prior interation in case 1.
        while (bit <= SIZE) {
            if((bit & index_) != 0) {
                // Case 1 as described above
                value   = deposits_.values[index_];
                scaling = deposits_.scaling[index_];

                // Calc sum, will only be stored in range parents of starting node, index_
                if (scaling != 0) {
                    // Note: we can't just multiply by factor_ - 1 in the following line, as rounding will
                    // cause obliterated indices to have nonzero values.  Need to track the actual
                    // precise delta in the value array
                    uint256 scaledFactor = Maths.wmul(factor_, scaling);

                    sum += Maths.wmul(scaledFactor, value) - Maths.wmul(scaling, value);

                    // Apply scaling to all range parents less then starting node, index_
                    deposits_.scaling[index_] = scaledFactor;
                } else {
                    // this node's scale factor is 1
                    sum += Maths.wmul(factor_, value) - value;
                    deposits_.scaling[index_] = factor_;
                }
                // Unset the bit in index to continue traversing up the Fenwick tree
                index_ -= bit;
            } else {
                // Case 1 above.  superRangeIndex is the index of the node to consider that
                //                contains the sub range that was already scaled in prior iteration
                uint256 superRangeIndex = index_ + bit;

                value   = (deposits_.values[superRangeIndex] += sum);
                scaling = deposits_.scaling[superRangeIndex];

                // Need to be careful due to rounding to propagate actual changes upwards in tree.
                // sum is always equal to the actual value we changed deposits_.values[] by
                if (scaling != 0) sum = Maths.wmul(value, scaling) - Maths.wmul(value - sum, scaling);
            }
            // consider next most significant bit
            bit = bit << 1;
        }
    }

    /**
     *  @notice Get prefix sum of all indexes from provided index downwards.
     *  @dev    Starts at tree root and decrements through range parent nodes summing from index i_'s range to index 0.
     *  @param  sumIndex_  The index to receive the prefix sum.
     *  @param  sum_       The prefix sum from current index downwards.
     */
    function prefixSum(
        DepositsState storage deposits_,
        uint256 sumIndex_
    ) internal view returns (uint256 sum_) {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++sumIndex_;

        uint256 runningScale = Maths.WAD; // Tracks scale(index_) as we move down Fenwick tree
        uint256 j            = SIZE;      // bit that iterates from MSB to LSB
        uint256 index        = 0;         // build up sumIndex bit by bit

        // Used to terminate loop.  We don't need to consider final 0 bits of sumIndex_
        uint256 indexLSB = lsb(sumIndex_);

        while (j >= indexLSB) {
            // Skip considering indices outside bounds of Fenwick tree
            if (index + j > SIZE) continue;

            // We are considering whether to include node index_+j in the sum or not.  Either way, we need to scaling[index_+j],
            // either to increment sum_ or to accumulate in runningScale
            uint256 scaled = deposits_.scaling[index+j];

            if (sumIndex_ & j != 0) {
                // node index+j of tree is included in sum
                uint256 value = deposits_.values[index+j];

                // Accumulate in sum_, recall that scaled==0 means that the scale factor is actually 1
                sum_  += scaled != 0 ? Maths.wmul(Maths.wmul(runningScale, scaled), value) : Maths.wmul(runningScale, value);
                // Build up index bit by bit
                index += j;

                // terminate if we've already matched sumIndex_
                if (index == sumIndex_) break;
            } else {
                // node is not included in sum, but its scale needs to be included for subsequent sums
                if (scaled != 0) runningScale = Maths.wmul(runningScale, scaled);
            }
            // shift j to consider next less signficant bit
            j = j >> 1;
        }
    }

    /**
     *  @notice Decrease a node in the FenwickTree at an index.
     *  @dev    Starts at leaf/target and moved up towards root
     *  @param  index_                  The deposit index.
     *  @param  unscaledRemoveAmount_   Unscaled amount to decrease deposit by.
     */
    function unscaledRemove(
        DepositsState storage deposits_,
        uint256 index_,
        uint256 unscaledRemoveAmount_
    ) internal {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++index_;

        // We operate with unscaledRemoveAmount_ here instead of a scaled quantity to avoid duplicate computation of scale factor
        // (thus redundant iterations through the Fenwick tree), and ALSO so that we can set the value of a given deposit exactly
        // to 0.
        
        while (index_ <= SIZE) {
            // Decrement deposits_ at index_ for removeAmount, storing new value in value
            uint256 value   = (deposits_.values[index_] -= unscaledRemoveAmount_);
            uint256 scaling = deposits_.scaling[index_];

            // If scale factor != 1, we need to adjust unscaledRemoveAmount by scale factor to adjust values further up in tree
            // On the line below, it would be tempting to replace this with:
            // unscaledRemoveAmount_ = Maths.wmul(unscaledRemoveAmount, scaling).  This will introduce nonzero values up
            // the tree due to rounding.  It's important to compute the actual change in deposits_.values[index_]
            // and propogate that upwards.
            if (scaling != 0) unscaledRemoveAmount_ = Maths.wmul(value + unscaledRemoveAmount_, scaling) - Maths.wmul(value,  scaling);

            // Traverse upward through the "update" path of the Fenwick tree
            index_ += lsb(index_);
        }
    }

    /**
     *  @notice Scale tree starting from given index.
     *  @dev    Starts at leaf/target and moved up towards root
     *  @param  index_  The deposit index.
     *  @return scaled_ Scaled value.
     */
    function scale(
        DepositsState storage deposits_,
        uint256 index_
    ) internal view returns (uint256 scaled_) {
        // price buckets are indexed starting at 0, Fenwick bit logic is more elegant starting at 1
        ++index_;

        // start with scaled_1 = 1
        scaled_ = Maths.WAD;
        while (index_ <= SIZE) {
            // Traverse up through Fenwick tree via "update" path, accumulating scale factors as we go
            uint256 scaling = deposits_.scaling[index_];
            // scaling==0 means actual scale factor is 1
            if (scaling != 0) scaled_ = Maths.wmul(scaled_, scaling);
            index_ += lsb(index_);
        }
    }

    /**
     *  @notice Returns sum of all deposits.
     */
    function treeSum(
        DepositsState storage deposits_
    ) internal view returns (uint256) {
        // In a scaled Fenwick tree, sum is at the root node, but needs to be scaled
        uint256 scaling = deposits_.scaling[SIZE];
        // scaling == 0 means scale factor is actually 1
        return (scaling != 0) ? Maths.wmul(scaling, deposits_.values[SIZE]) : deposits_.values[SIZE]; 
    }

    /**
     *  @notice Returns deposit value for a given deposit index.
     *  @param  index_        The deposit index.
     *  @return depositValue_ Value of the deposit.
     */
    function valueAt(
        DepositsState storage deposits_,
        uint256 index_
    ) internal view returns (uint256 depositValue_) {
        // Get unscaled value at index and multiply by scale
        depositValue_ = Maths.wmul(unscaledValueAt(deposits_, index_), scale(deposits_,index_));
    }

    function unscaledValueAt(
        DepositsState storage deposits_,
        uint256 index_
    ) internal view returns (uint256 unscaledDepositValue_) {
        // In a scaled Fenwick tree, sum is at the root node, but needs to be scaled
        ++index_;

        uint256 j = 1;

        // Returns the unscaled value at the node.  We consider the unscaled value for two reasons:
        // 1- If we want to zero out deposit in bucket, we need to subtract the exact unscaled value
        // 2- We may already have computed the scale factor, so we can avoid duplicate traversal

        unscaledDepositValue_ = deposits_.values[index_];
        while (j & index_ == 0) {
            uint256 value   = deposits_.values[index_ - j];
            uint256 scaling = deposits_.scaling[index_ - j];

            unscaledDepositValue_ -= scaling != 0 ? Maths.wmul(scaling, value) : value;
            j = j << 1;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

import {AuctionsState, Borrower, DepositsState, Loan, LoansState} from "../../interfaces/pool/commons/IPoolState.sol";

import {_priceAt} from "../helpers/PoolHelper.sol";

import {Deposits} from "./Deposits.sol";
import {Maths} from "./Maths.sol";

/**
    @title  Loans library
    @notice Internal library containing common logic for loans management.
    @dev    Implemented as Max Heap data structure.
 */
library Loans {
    uint256 constant ROOT_INDEX = 1;

    /**************/
    /*** Errors ***/
    /**************/

    // See `IPoolErrors` for descriptions
    error ZeroThresholdPrice();

    /***********************/
    /***  Initialization ***/
    /***********************/

    /**
     *  @notice Initializes Loans Max Heap.
     *  @dev    Organizes loans so Highest Threshold Price can be retreived easily.
     *  @param loans_ Holds Loan heap data.
     */
    function init(LoansState storage loans_) internal {
        loans_.loans.push(Loan(address(0), 0));
    }

    /**
     * The Loans heap is a Max Heap data structure (complete binary tree), the root node is the loan with the highest threshold price (TP)
     * at a given time. The heap is represented as an array, where the first element is a dummy element (Loan(address(0), 0)) and the first
     * value of the heap starts at index 1, ROOT_INDEX. The threshold price of a loan's parent is always greater than or equal to the
     * threshold price of the loan.
     * This code was modified from the following source: https://github.com/zmitton/eth-heap/blob/master/contracts/Heap.sol
     */

    /***********************************/
    /***  Loans Management Functions ***/
    /***********************************/

    /**
     *  @notice Updates a loan: updates heap (upsert if TP not 0, remove otherwise) and borrower balance.
     *  @dev    write state:
     *          - _upsert:
     *            - insert or update loan in loans array
     *          - remove:
     *            - remove loan from loans array
     *          - update borrower in address => borrower mapping
     *  @param loans_               Holds loan heap data.
     *  @param borrower_            Borrower struct with borrower details.
     *  @param borrowerAddress_     Borrower's address to update.
     *  @param borrowerAccruedDebt_ Borrower's current debt.
     *  @param poolRate_            Pool's current rate.
     *  @param lup_                 Current LUP.
     *  @param inAuction_           Whether the loan is in auction or not.
     *  @param t0NpUpdate_          Whether the neutral price of borrower should be updated or not.
     */
    function update(
        LoansState storage loans_,
        AuctionsState storage auctions_,
        DepositsState storage deposits_,
        Borrower memory borrower_,
        address borrowerAddress_,
        uint256 borrowerAccruedDebt_,
        uint256 poolRate_,
        uint256 lup_,
        bool inAuction_,
        bool t0NpUpdate_
    ) internal {
        bool activeBorrower = borrower_.t0Debt != 0 &&
            borrower_.collateral != 0;

        uint256 t0ThresholdPrice = activeBorrower
            ? Maths.wdiv(borrower_.t0Debt, borrower_.collateral)
            : 0;

        // loan not in auction, update threshold price and position in heap
        if (!inAuction_) {
            // get the loan id inside the heap
            uint256 loanId = loans_.indices[borrowerAddress_];
            if (activeBorrower) {
                // revert if threshold price is zero
                if (t0ThresholdPrice == 0) revert ZeroThresholdPrice();

                // update heap, insert if a new loan, update loan if already in heap
                _upsert(
                    loans_,
                    borrowerAddress_,
                    loanId,
                    uint96(t0ThresholdPrice)
                );

                // if loan is in heap and borrwer is no longer active (no debt, no collateral) then remove loan from heap
            } else if (loanId != 0) {
                remove(loans_, borrowerAddress_, loanId);
            }
        }

        // update t0 neutral price of borrower
        if (t0NpUpdate_) {
            if (t0ThresholdPrice != 0) {
                uint256 loansInPool = loans_.loans.length -
                    1 +
                    auctions_.noOfAuctions;
                uint256 curMomp = _priceAt(
                    Deposits.findIndexOfSum(
                        deposits_,
                        Maths.wdiv(borrowerAccruedDebt_, loansInPool * 1e18)
                    )
                );

                borrower_.t0Np =
                    ((1e18 + poolRate_) * curMomp * t0ThresholdPrice) /
                    lup_ /
                    1e18;
            } else {
                borrower_.t0Np = 0;
            }
        }

        // save borrower state
        loans_.borrowers[borrowerAddress_] = borrower_;
    }

    /**************************************/
    /***  Loans Heap Internal Functions ***/
    /**************************************/

    /**
     *  @notice Moves a Loan up the heap.
     *  @param loans_ Holds loan heap data.
     *  @param loan_ Loan to be moved.
     *  @param i_    Index for Loan to be moved to.
     */
    function _bubbleUp(
        LoansState storage loans_,
        Loan memory loan_,
        uint i_
    ) private {
        uint256 count = loans_.loans.length;
        if (
            i_ == ROOT_INDEX ||
            loan_.thresholdPrice <= loans_.loans[i_ / 2].thresholdPrice
        ) {
            _insert(loans_, loan_, i_, count);
        } else {
            _insert(loans_, loans_.loans[i_ / 2], i_, count);
            _bubbleUp(loans_, loan_, i_ / 2);
        }
    }

    /**
     *  @notice Moves a Loan down the heap.
     *  @param loans_ Holds Loan heap data.
     *  @param loan_ Loan to be moved.
     *  @param i_    Index for Loan to be moved to.
     */
    function _bubbleDown(
        LoansState storage loans_,
        Loan memory loan_,
        uint i_
    ) private {
        // Left child index.
        uint cIndex = i_ * 2;

        uint256 count = loans_.loans.length;
        if (count <= cIndex) {
            _insert(loans_, loan_, i_, count);
        } else {
            Loan memory largestChild = loans_.loans[cIndex];

            if (
                count > cIndex + 1 &&
                loans_.loans[cIndex + 1].thresholdPrice >
                largestChild.thresholdPrice
            ) {
                largestChild = loans_.loans[++cIndex];
            }

            if (largestChild.thresholdPrice <= loan_.thresholdPrice) {
                _insert(loans_, loan_, i_, count);
            } else {
                _insert(loans_, largestChild, i_, count);
                _bubbleDown(loans_, loan_, cIndex);
            }
        }
    }

    /**
     *  @notice Inserts a Loan in the heap.
     *  @param loans_ Holds loan heap data.
     *  @param loan_ Loan to be inserted.
     *  @param i_    index for Loan to be inserted at.
     */
    function _insert(
        LoansState storage loans_,
        Loan memory loan_,
        uint i_,
        uint256 count_
    ) private {
        if (i_ == count_) loans_.loans.push(loan_);
        else loans_.loans[i_] = loan_;

        loans_.indices[loan_.borrower] = i_;
    }

    /**
     *  @notice Removes loan from heap given borrower address.
     *  @param loans_    Holds loan heap data.
     *  @param borrower_ Borrower address whose loan is being updated or inserted.
     *  @param id_       Loan id.
     */
    function remove(
        LoansState storage loans_,
        address borrower_,
        uint256 id_
    ) internal {
        delete loans_.indices[borrower_];
        uint256 tailIndex = loans_.loans.length - 1;
        if (id_ == tailIndex)
            loans_.loans.pop(); // we're removing the tail, pop without sorting
        else {
            Loan memory tail = loans_.loans[tailIndex];
            loans_.loans.pop(); // remove tail loan
            _bubbleUp(loans_, tail, id_);
            _bubbleDown(loans_, loans_.loans[id_], id_);
        }
    }

    /**
     *  @notice Performs an insert or an update dependent on borrowers existance.
     *  @param loans_ Holds loan heap data.
     *  @param borrower_       Borrower address that is being updated or inserted.
     *  @param id_             Loan id.
     *  @param thresholdPrice_ Threshold Price that is updated or inserted.
     */
    function _upsert(
        LoansState storage loans_,
        address borrower_,
        uint256 id_,
        uint96 thresholdPrice_
    ) internal {
        // Loan exists, update in place.
        if (id_ != 0) {
            Loan memory currentLoan = loans_.loans[id_];
            if (currentLoan.thresholdPrice > thresholdPrice_) {
                currentLoan.thresholdPrice = thresholdPrice_;
                _bubbleDown(loans_, currentLoan, id_);
            } else {
                currentLoan.thresholdPrice = thresholdPrice_;
                _bubbleUp(loans_, currentLoan, id_);
            }

            // New loan, insert it
        } else {
            _bubbleUp(
                loans_,
                Loan(borrower_, thresholdPrice_),
                loans_.loans.length
            );
        }
    }

    /**********************/
    /*** View Functions ***/
    /**********************/

    /**
     *  @notice Retreives Loan by index, i_.
     *  @param loans_ Holds loan heap data.
     *  @param i_    Index to retreive Loan.
     *  @return Loan Loan retrieved by index.
     */
    function getByIndex(
        LoansState storage loans_,
        uint256 i_
    ) internal view returns (Loan memory) {
        return
            loans_.loans.length > i_ ? loans_.loans[i_] : Loan(address(0), 0);
    }

    /**
     *  @notice Retreives Loan with the highest threshold price value.
     *  @param loans_ Holds loan heap data.
     *  @return Loan Max Loan in the Heap.
     */
    function getMax(
        LoansState storage loans_
    ) internal view returns (Loan memory) {
        return getByIndex(loans_, ROOT_INDEX);
    }

    /**
     *  @notice Returns number of loans in pool.
     *  @param loans_ Holds loan heap data.
     *  @return number of loans in pool.
     */
    function noOfLoans(
        LoansState storage loans_
    ) internal view returns (uint256) {
        return loans_.loans.length - 1;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

/**
    @title  Maths library
    @notice Internal library containing common maths.
 */
library Maths {

    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 10**27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y + 1e18 / 2) / 1e18;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * 1e18 + y / 2) / y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x >= y ? x : y;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x <= y ? x : y;
    }

    function wad(uint256 x) internal pure returns (uint256) {
        return x * 1e18;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y + 10**27 / 2) / 10**27;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * 10**27 + y / 2) / y;
    }

    /** @notice Divides a WAD by a RAY and returns a RAY */
    function wrdivr(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * 1e36 + y / 2) / y;
    }

    /** @notice Divides a WAD by a WAD and returns a RAY */
    function wwdivr(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * 1e27 + y / 2) / y;
    }

    /** @notice Divides a RAY by another RAY and returns a WAD */
    function rrdivw(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * 1e18 + y / 2) / y;
    }

    /** @notice Divides a RAY by a WAD and returns a WAD */
    function rwdivw(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * 1e9 + y / 2) / y;
    }

    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : 10**27;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function wadToRay(uint256 x) internal pure returns (uint256) {
        return x * 10**9;
    }

    function rayToWad(uint256 x) internal pure returns (uint256) {
        return (x + 10**9 / 2) / 10**9;
    }

    /*************************/
    /*** Integer Functions ***/
    /*************************/

    function maxInt(int256 x, int256 y) internal pure returns (int256) {
        return x >= y ? x : y;
    }

    function minInt(int256 x, int256 y) internal pure returns (int256) {
        return x <= y ? x : y;
    }

}