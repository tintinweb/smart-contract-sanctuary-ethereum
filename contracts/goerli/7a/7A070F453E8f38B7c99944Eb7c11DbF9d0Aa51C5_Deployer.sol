/**
 *Submitted for verification at Etherscan.io on 2022-03-07
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/Deployer.sol
// SPDX-License-Identifier: MIT AND Unlicense AND AGPL-3.0-or-later AND Unlicensed
pragma solidity >=0.8.4 >=0.8.0 <0.9.0 >=0.8.4 <0.9.0;

////// lib/fiat/lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

/* pragma solidity ^0.8.0; */

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

////// lib/fiat/lib/prb-math/contracts/PRBMath.sol
/* pragma solidity >=0.8.4; */

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

////// lib/fiat/lib/prb-math/contracts/PRBMathUD60x18.sol
/* pragma solidity >=0.8.4; */

/* import "./PRBMath.sol"; */

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

////// lib/fiat/src/interfaces/ICodex.sol
/* pragma solidity ^0.8.4; */

interface ICodex {
    function init(address vault) external;

    function setParam(bytes32 param, uint256 data) external;

    function setParam(
        address,
        bytes32,
        uint256
    ) external;

    function credit(address) external view returns (uint256);

    function unbackedDebt(address) external view returns (uint256);

    function balances(
        address,
        uint256,
        address
    ) external view returns (uint256);

    function vaults(address vault)
        external
        view
        returns (
            uint256 totalNormalDebt,
            uint256 rate,
            uint256 debtCeiling,
            uint256 debtFloor
        );

    function positions(
        address vault,
        uint256 tokenId,
        address position
    ) external view returns (uint256 collateral, uint256 normalDebt);

    function globalDebt() external view returns (uint256);

    function globalUnbackedDebt() external view returns (uint256);

    function globalDebtCeiling() external view returns (uint256);

    function delegates(address, address) external view returns (uint256);

    function grantDelegate(address) external;

    function revokeDelegate(address) external;

    function modifyBalance(
        address,
        uint256,
        address,
        int256
    ) external;

    function transferBalance(
        address vault,
        uint256 tokenId,
        address src,
        address dst,
        uint256 amount
    ) external;

    function transferCredit(
        address src,
        address dst,
        uint256 amount
    ) external;

    function modifyCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address user,
        address collateralizer,
        address debtor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function transferCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address src,
        address dst,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function confiscateCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address user,
        address collateralizer,
        address debtor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external;

    function settleUnbackedDebt(uint256 debt) external;

    function createUnbackedDebt(
        address debtor,
        address creditor,
        uint256 debt
    ) external;

    function modifyRate(
        address vault,
        address creditor,
        int256 rate
    ) external;

    function lock() external;
}

////// lib/fiat/src/interfaces/IDebtAuction.sol
/* pragma solidity ^0.8.4; */

/* import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol"; */

/* import {ICodex} from "./ICodex.sol"; */

interface IDebtAuction {
    function auctions(uint256)
        external
        view
        returns (
            uint256,
            uint256,
            address,
            uint48,
            uint48
        );

    function codex() external view returns (ICodex);

    function token() external view returns (IERC20);

    function minBidBump() external view returns (uint256);

    function tokenToSellBump() external view returns (uint256);

    function bidDuration() external view returns (uint48);

    function auctionDuration() external view returns (uint48);

    function auctionCounter() external view returns (uint256);

    function live() external view returns (uint256);

    function aer() external view returns (address);

    function setParam(bytes32 param, uint256 data) external;

    function startAuction(
        address recipient,
        uint256 tokensToSell,
        uint256 bid
    ) external returns (uint256 id);

    function redoAuction(uint256 id) external;

    function submitBid(
        uint256 id,
        uint256 tokensToSell,
        uint256 bid
    ) external;

    function closeAuction(uint256 id) external;

    function lock() external;

    function cancelAuction(uint256 id) external;
}

////// lib/fiat/src/interfaces/ISurplusAuction.sol
/* pragma solidity ^0.8.4; */

/* import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol"; */

/* import {ICodex} from "./ICodex.sol"; */

interface ISurplusAuction {
    function auctions(uint256)
        external
        view
        returns (
            uint256,
            uint256,
            address,
            uint48,
            uint48
        );

    function codex() external view returns (ICodex);

    function token() external view returns (IERC20);

    function minBidBump() external view returns (uint256);

    function bidDuration() external view returns (uint48);

    function auctionDuration() external view returns (uint48);

    function auctionCounter() external view returns (uint256);

    function live() external view returns (uint256);

    function setParam(bytes32 param, uint256 data) external;

    function startAuction(uint256 creditToSell, uint256 bid) external returns (uint256 id);

    function redoAuction(uint256 id) external;

    function submitBid(
        uint256 id,
        uint256 creditToSell,
        uint256 bid
    ) external;

    function closeAuction(uint256 id) external;

    function lock(uint256 credit) external;

    function cancelAuction(uint256 id) external;
}

////// lib/fiat/src/interfaces/IAer.sol
/* pragma solidity ^0.8.4; */

/* import {ICodex} from "./ICodex.sol"; */
/* import {IDebtAuction} from "./IDebtAuction.sol"; */
/* import {ISurplusAuction} from "./ISurplusAuction.sol"; */

interface IAer {
    function codex() external view returns (ICodex);

    function surplusAuction() external view returns (ISurplusAuction);

    function debtAuction() external view returns (IDebtAuction);

    function debtQueue(uint256) external view returns (uint256);

    function queuedDebt() external view returns (uint256);

    function debtOnAuction() external view returns (uint256);

    function auctionDelay() external view returns (uint256);

    function debtAuctionSellSize() external view returns (uint256);

    function debtAuctionBidSize() external view returns (uint256);

    function surplusAuctionSellSize() external view returns (uint256);

    function surplusBuffer() external view returns (uint256);

    function live() external view returns (uint256);

    function setParam(bytes32 param, uint256 data) external;

    function setParam(bytes32 param, address data) external;

    function queueDebt(uint256 debt) external;

    function unqueueDebt(uint256 queuedAt) external;

    function settleDebtWithSurplus(uint256 debt) external;

    function settleAuctionedDebt(uint256 debt) external;

    function startDebtAuction() external returns (uint256 auctionId);

    function startSurplusAuction() external returns (uint256 auctionId);

    function transferCredit(address to, uint256 credit) external;

    function lock() external;
}

////// lib/fiat/src/interfaces/IGuarded.sol
/* pragma solidity ^0.8.4; */

interface IGuarded {
    function ANY_SIG() external view returns (bytes32);

    function ANY_CALLER() external view returns (address);

    function allowCaller(bytes32 sig, address who) external;

    function blockCaller(bytes32 sig, address who) external;

    function canCall(bytes32 sig, address who) external view returns (bool);
}

////// lib/fiat/src/utils/Guarded.sol
/* pragma solidity ^0.8.4; */

/* import {IGuarded} from "../interfaces/IGuarded.sol"; */

/// @title Guarded
/// @notice Mixin implementing an authentication scheme on a method level
abstract contract Guarded is IGuarded {
    /// ======== Custom Errors ======== ///

    error Guarded__notRoot();
    error Guarded__notGranted();

    /// ======== Storage ======== ///

    /// @notice Wildcard for granting a caller to call every guarded method
    bytes32 public constant override ANY_SIG = keccak256("ANY_SIG");
    /// @notice Wildcard for granting a caller to call every guarded method
    address public constant override ANY_CALLER = address(uint160(uint256(bytes32(keccak256("ANY_CALLER")))));

    /// @notice Mapping storing who is granted to which method
    /// @dev Method Signature => Caller => Bool
    mapping(bytes32 => mapping(address => bool)) private _canCall;

    /// ======== Events ======== ///

    event AllowCaller(bytes32 sig, address who);
    event BlockCaller(bytes32 sig, address who);

    constructor() {
        // set root
        _setRoot(msg.sender);
    }

    /// ======== Auth ======== ///

    modifier callerIsRoot() {
        if (_canCall[ANY_SIG][msg.sender]) {
            _;
        } else revert Guarded__notRoot();
    }

    modifier checkCaller() {
        if (canCall(msg.sig, msg.sender)) {
            _;
        } else revert Guarded__notGranted();
    }

    /// @notice Grant the right to call method `sig` to `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function allowCaller(bytes32 sig, address who) public override callerIsRoot {
        _canCall[sig][who] = true;
        emit AllowCaller(sig, who);
    }

    /// @notice Revoke the right to call method `sig` from `who`
    /// @dev Only the root user (granted `ANY_SIG`) is able to call this method
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should not be able to call `sig` anymore
    function blockCaller(bytes32 sig, address who) public override callerIsRoot {
        _canCall[sig][who] = false;
        emit BlockCaller(sig, who);
    }

    /// @notice Returns if `who` can call `sig`
    /// @param sig Method signature (4Byte)
    /// @param who Address of who should be able to call `sig`
    function canCall(bytes32 sig, address who) public view override returns (bool) {
        return (_canCall[sig][who] || _canCall[ANY_SIG][who] || _canCall[sig][ANY_CALLER]);
    }

    /// @notice Sets the root user (granted `ANY_SIG`)
    /// @param root Address of who should be set as root
    function _setRoot(address root) internal {
        _canCall[ANY_SIG][root] = true;
        emit AllowCaller(ANY_SIG, root);
    }

    /// @notice Unsets the root user (granted `ANY_SIG`)
    /// @param root Address of who should be unset as root
    function _unsetRoot(address root) internal {
        _canCall[ANY_SIG][root] = false;
        emit AllowCaller(ANY_SIG, root);
    }
}

////// lib/fiat/src/utils/Math.sol
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
/* pragma solidity ^0.8.4; */

uint256 constant MLN = 10**6;
uint256 constant BLN = 10**9;
uint256 constant WAD = 10**18;
uint256 constant RAY = 10**18;
uint256 constant RAD = 10**18;

/* solhint-disable func-visibility, no-inline-assembly */

error Math__toInt256_overflow(uint256 x);

function toInt256(uint256 x) pure returns (int256) {
    if (x > uint256(type(int256).max)) revert Math__toInt256_overflow(x);
    return int256(x);
}

function min(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = x <= y ? x : y;
    }
}

function max(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = x >= y ? x : y;
    }
}

error Math__diff_overflow(uint256 x, uint256 y);

function diff(uint256 x, uint256 y) pure returns (int256 z) {
    unchecked {
        z = int256(x) - int256(y);
        if (!(int256(x) >= 0 && int256(y) >= 0)) revert Math__diff_overflow(x, y);
    }
}

error Math__add_overflow(uint256 x, uint256 y);

function add(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if ((z = x + y) < x) revert Math__add_overflow(x, y);
    }
}

error Math__add48_overflow(uint256 x, uint256 y);

function add48(uint48 x, uint48 y) pure returns (uint48 z) {
    unchecked {
        if ((z = x + y) < x) revert Math__add48_overflow(x, y);
    }
}

error Math__add_overflow_signed(uint256 x, int256 y);

function add(uint256 x, int256 y) pure returns (uint256 z) {
    unchecked {
        z = x + uint256(y);
        if (!(y >= 0 || z <= x)) revert Math__add_overflow_signed(x, y);
        if (!(y <= 0 || z >= x)) revert Math__add_overflow_signed(x, y);
    }
}

error Math__sub_overflow(uint256 x, uint256 y);

function sub(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if ((z = x - y) > x) revert Math__sub_overflow(x, y);
    }
}

error Math__sub_overflow_signed(uint256 x, int256 y);

function sub(uint256 x, int256 y) pure returns (uint256 z) {
    unchecked {
        z = x - uint256(y);
        if (!(y <= 0 || z <= x)) revert Math__sub_overflow_signed(x, y);
        if (!(y >= 0 || z >= x)) revert Math__sub_overflow_signed(x, y);
    }
}

error Math__mul_overflow(uint256 x, uint256 y);

function mul(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if (!(y == 0 || (z = x * y) / y == x)) revert Math__mul_overflow(x, y);
    }
}

error Math__mul_overflow_signed(uint256 x, int256 y);

function mul(uint256 x, int256 y) pure returns (int256 z) {
    unchecked {
        z = int256(x) * y;
        if (int256(x) < 0) revert Math__mul_overflow_signed(x, y);
        if (!(y == 0 || z / y == int256(x))) revert Math__mul_overflow_signed(x, y);
    }
}

function wmul(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = mul(x, y) / WAD;
    }
}

function wmul(uint256 x, int256 y) pure returns (int256 z) {
    unchecked {
        z = mul(x, y) / int256(WAD);
    }
}

error Math__div_overflow(uint256 x, uint256 y);

function div(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        if (y == 0) revert Math__div_overflow(x, y);
        return x / y;
    }
}

function wdiv(uint256 x, uint256 y) pure returns (uint256 z) {
    unchecked {
        z = mul(x, WAD) / y;
    }
}

// optimized version from dss PR #78
function wpow(
    uint256 x,
    uint256 n,
    uint256 b
) pure returns (uint256 z) {
    unchecked {
        assembly {
            switch n
            case 0 {
                z := b
            }
            default {
                switch x
                case 0 {
                    z := 0
                }
                default {
                    switch mod(n, 2)
                    case 0 {
                        z := b
                    }
                    default {
                        z := x
                    }
                    let half := div(b, 2) // for rounding.
                    for {
                        n := div(n, 2)
                    } n {
                        n := div(n, 2)
                    } {
                        let xx := mul(x, x)
                        if shr(128, x) {
                            revert(0, 0)
                        }
                        let xxRound := add(xx, half)
                        if lt(xxRound, xx) {
                            revert(0, 0)
                        }
                        x := div(xxRound, b)
                        if mod(n, 2) {
                            let zx := mul(z, x)
                            if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                                revert(0, 0)
                            }
                            let zxRound := add(zx, half)
                            if lt(zxRound, zx) {
                                revert(0, 0)
                            }
                            z := div(zxRound, b)
                        }
                    }
                }
            }
        }
    }
}

/* solhint-disable func-visibility, no-inline-assembly */

////// lib/fiat/src/Aer.sol
// Copyright (C) 2018 Rain <[email protected]>
/* pragma solidity ^0.8.4; */

/* import {ICodex} from "./interfaces/ICodex.sol"; */
/* import {IDebtAuction} from "./interfaces/IDebtAuction.sol"; */
/* import {IAer} from "./interfaces/IAer.sol"; */
/* import {ISurplusAuction} from "./interfaces/ISurplusAuction.sol"; */

/* import {Guarded} from "./utils/Guarded.sol"; */
/* import {WAD, min, add, sub} from "./utils/Math.sol"; */

/// @title Aer (short for Aerarium)
/// @notice `Aer` is used for managing the protocol's debt and surplus balances via the DebtAuction and
/// SurplusAuction contracts.
/// Uses Vow.sol from DSS (MakerDAO) / AccountingEngine.sol from GEB (Reflexer Labs) as a blueprint
/// Changes from Vow.sol / AccountingEngine.sol:
/// - only WAD precision is used (no RAD and RAY)
/// - uses a method signature based authentication scheme
contract Aer is Guarded, IAer {
    /// ======== Custom Errors ======== ///

    error Aer__setParam_unrecognizedParam();
    error Aer__unqueueDebt_auctionDelayNotPassed();
    error Aer__settleDebtWithSurplus_insufficientSurplus();
    error Aer__settleDebtWithSurplus_insufficientDebt();
    error Aer__settleAuctionedDebt_notEnoughDebtOnAuction();
    error Aer__settleAuctionedDebt_insufficientSurplus();
    error Aer__startDebtAuction_insufficientDebt();
    error Aer__startDebtAuction_surplusNotZero();
    error Aer__startSurplusAuction_insufficientSurplus();
    error Aer__startSurplusAuction_debtNotZero();
    error Aer__transferCredit_insufficientCredit();
    error Aer__lock_notLive();

    /// ======== Storage ======== ///

    /// @notice Codex
    ICodex public immutable override codex;
    /// @notice SurplusAuction
    ISurplusAuction public override surplusAuction;
    /// @notice DebtAuction
    IDebtAuction public override debtAuction;

    /// @notice List of debt amounts to be auctioned sorted by the time at which they where queued
    /// @dev Queued at timestamp => Debt [wad]
    mapping(uint256 => uint256) public override debtQueue;
    /// @notice Queued debt amount [wad]
    uint256 public override queuedDebt;
    /// @notice Amount of debt currently on auction [wad]
    uint256 public override debtOnAuction;

    /// @notice Time after which queued debt can be put up for auction [seconds]
    uint256 public override auctionDelay;
    /// @notice Amount of tokens to sell in each debt auction [wad]
    uint256 public override debtAuctionSellSize;
    /// @notice Min. amount of (credit to bid or debt to sell) for tokens [wad]
    uint256 public override debtAuctionBidSize;

    /// @notice Amount of credit to sell in each surplus auction [wad]
    uint256 public override surplusAuctionSellSize;
    /// @notice Amount of credit required for starting a surplus auction [wad]
    uint256 public override surplusBuffer;

    /// @notice Boolean indicating if this contract is live (0 - not live, 1 - live)
    uint256 public override live;

    /// ======== Events ======== ///
    event SetParam(bytes32 indexed param, uint256 data);
    event SetParam(bytes32 indexed param, address indexed data);
    event QueueDebt(uint256 indexed queuedAt, uint256 debtQueue, uint256 queuedDebt);
    event UnqueueDebt(uint256 indexed queuedAt, uint256 queuedDebt);
    event StartDebtAuction(uint256 debtOnAuction, uint256 indexed auctionId);
    event SettleAuctionedDebt(uint256 debtOnAuction);
    event StartSurplusAuction(uint256 indexed auctionId);
    event SettleDebtWithSurplus(uint256 debt);
    event Lock();

    constructor(
        address codex_,
        address surplusAuction_,
        address debtAuction_
    ) Guarded() {
        codex = ICodex(codex_);
        surplusAuction = ISurplusAuction(surplusAuction_);
        debtAuction = IDebtAuction(debtAuction_);
        ICodex(codex_).grantDelegate(surplusAuction_);
        live = 1;
    }

    /// ======== Configuration ======== ///

    /// @notice Sets various variables for this contract
    /// @dev Sender has to be allowed to call this method
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [wad]
    function setParam(bytes32 param, uint256 data) external override checkCaller {
        if (param == "auctionDelay") auctionDelay = data;
        else if (param == "surplusAuctionSellSize") surplusAuctionSellSize = data;
        else if (param == "debtAuctionBidSize") debtAuctionBidSize = data;
        else if (param == "debtAuctionSellSize") debtAuctionSellSize = data;
        else if (param == "surplusBuffer") surplusBuffer = data;
        else revert Aer__setParam_unrecognizedParam();
        emit SetParam(param, data);
    }

    /// @notice Sets various variables for this contract
    /// @dev Sender has to be allowed to call this method
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [address]
    function setParam(bytes32 param, address data) external override checkCaller {
        if (param == "surplusAuction") {
            codex.revokeDelegate(address(surplusAuction));
            surplusAuction = ISurplusAuction(data);
            codex.grantDelegate(data);
        } else if (param == "debtAuction") debtAuction = IDebtAuction(data);
        else revert Aer__setParam_unrecognizedParam();
        emit SetParam(param, data);
    }

    /// ======== Debt Auction ======== ///

    /// @notice Pushes new debt to the debt queue
    /// @dev Sender has to be allowed to call this method
    /// @param debt Amount of debt [wad]
    function queueDebt(uint256 debt) external override checkCaller {
        debtQueue[block.timestamp] = add(debtQueue[block.timestamp], debt);
        queuedDebt = add(queuedDebt, debt);
        emit QueueDebt(block.timestamp, debtQueue[block.timestamp], queuedDebt);
    }

    /// @notice Pops debt from the debt queue
    /// @param queuedAt Timestamp at which the debt has been queued [seconds]
    function unqueueDebt(uint256 queuedAt) external override {
        if (add(queuedAt, auctionDelay) > block.timestamp) revert Aer__unqueueDebt_auctionDelayNotPassed();
        queuedDebt = sub(queuedDebt, debtQueue[queuedAt]);
        debtQueue[queuedAt] = 0;
        emit UnqueueDebt(queuedAt, queuedDebt);
    }

    /// @notice Starts a debt auction
    /// @dev Sender has to be allowed to call this method
    /// Checks if enough debt exists to be put up for auction
    /// debtAuctionBidSize > (unbackedDebt - queuedDebt - debtOnAuction)
    /// @return auctionId Id of the debt auction
    function startDebtAuction() external override checkCaller returns (uint256 auctionId) {
        if (debtAuctionBidSize > sub(sub(codex.unbackedDebt(address(this)), queuedDebt), debtOnAuction))
            revert Aer__startDebtAuction_insufficientDebt();
        if (codex.credit(address(this)) != 0) revert Aer__startDebtAuction_surplusNotZero();
        debtOnAuction = add(debtOnAuction, debtAuctionBidSize);
        auctionId = debtAuction.startAuction(address(this), debtAuctionSellSize, debtAuctionBidSize);
        emit StartDebtAuction(debtOnAuction, auctionId);
    }

    /// @notice Settles debt collected from debt auctions
    /// @dev Cannot settle debt with accrued surplus (only from debt auctions)
    /// @param debt Amount of debt to settle [wad]
    function settleAuctionedDebt(uint256 debt) external override {
        if (debt > debtOnAuction) revert Aer__settleAuctionedDebt_notEnoughDebtOnAuction();
        if (debt > codex.credit(address(this))) revert Aer__settleAuctionedDebt_insufficientSurplus();
        debtOnAuction = sub(debtOnAuction, debt);
        codex.settleUnbackedDebt(debt);
        emit SettleAuctionedDebt(debtOnAuction);
    }

    /// ======== Surplus Auction ======== ///

    /// @notice Starts a surplus auction
    /// @dev Sender has to be allowed to call this method
    /// Checks if enough surplus has accrued (surplusAuctionSellSize + surplusBuffer) and there's
    /// no queued debt to be put up for a debt auction
    /// @return auctionId Id of the surplus auction
    function startSurplusAuction() external override checkCaller returns (uint256 auctionId) {
        if (
            codex.credit(address(this)) <
            add(add(codex.unbackedDebt(address(this)), surplusAuctionSellSize), surplusBuffer)
        ) revert Aer__startSurplusAuction_insufficientSurplus();
        if (sub(sub(codex.unbackedDebt(address(this)), queuedDebt), debtOnAuction) != 0)
            revert Aer__startSurplusAuction_debtNotZero();
        auctionId = surplusAuction.startAuction(surplusAuctionSellSize, 0);
        emit StartSurplusAuction(auctionId);
    }

    /// @notice Settles debt with the accrued surplus
    /// @dev Sender has to be allowed to call this method
    /// Can not settle more debt than there's unbacked debt and which is not expected
    /// to be settled via debt auctions (queuedDebt + debtOnAuction)
    /// @param debt Amount of debt to settle [wad]
    function settleDebtWithSurplus(uint256 debt) external override checkCaller {
        if (debt > codex.credit(address(this))) revert Aer__settleDebtWithSurplus_insufficientSurplus();
        if (debt > sub(sub(codex.unbackedDebt(address(this)), queuedDebt), debtOnAuction))
            revert Aer__settleDebtWithSurplus_insufficientDebt();
        codex.settleUnbackedDebt(debt);
        emit SettleDebtWithSurplus(debt);
    }

    /// @notice Transfer accrued credit surplus to another account
    /// @dev Can only transfer backed credit out of Aer
    /// @param credit Amount of debt to settle [wad]
    function transferCredit(address to, uint256 credit) external override checkCaller {
        if (credit > sub(codex.credit(address(this)), codex.unbackedDebt(address(this))))
            revert Aer__transferCredit_insufficientCredit();
        codex.transferCredit(address(this), to, credit);
    }

    /// ======== Shutdown ======== ///

    /// @notice Locks the contract
    /// @dev Sender has to be allowed to call this method
    /// Wipes queued debt and debt on auction, locks DebtAuction and SurplusAuction and
    /// settles debt with what it has available
    function lock() external override checkCaller {
        if (live == 0) revert Aer__lock_notLive();
        live = 0;
        queuedDebt = 0;
        debtOnAuction = 0;
        surplusAuction.lock(codex.credit(address(surplusAuction)));
        debtAuction.lock();
        codex.settleUnbackedDebt(min(codex.credit(address(this)), codex.unbackedDebt(address(this))));
        emit Lock();
    }
}

////// lib/fiat/src/interfaces/ICollybus.sol
/* pragma solidity ^0.8.4; */

/* import {ICodex} from "./ICodex.sol"; */

interface IPriceFeed {
    function peek() external returns (bytes32, bool);

    function read() external view returns (bytes32);
}

interface ICollybus {
    function vaults(address) external view returns (uint128, uint128);

    function spots(address) external view returns (uint256);

    function rates(uint256) external view returns (uint256);

    function rateIds(address, uint256) external view returns (uint256);

    function redemptionPrice() external view returns (uint256);

    function live() external view returns (uint256);

    function setParam(bytes32 param, uint256 data) external;

    function setParam(
        address vault,
        bytes32 param,
        uint128 data
    ) external;

    function setParam(
        address vault,
        uint256 tokenId,
        bytes32 param,
        uint256 data
    ) external;

    function updateDiscountRate(uint256 rateId, uint256 rate) external;

    function updateSpot(address token, uint256 spot) external;

    function read(
        address vault,
        address underlier,
        uint256 tokenId,
        uint256 maturity,
        bool net
    ) external view returns (uint256 price);

    function lock() external;
}

////// lib/fiat/src/interfaces/IVault.sol
/* pragma solidity ^0.8.4; */

/* import {ICodex} from "./ICodex.sol"; */
/* import {ICollybus} from "./ICollybus.sol"; */

interface IVault_1 {
    function codex() external view returns (ICodex);

    function collybus() external view returns (ICollybus);

    function token() external view returns (address);

    function tokenScale() external view returns (uint256);

    function underlierToken() external view returns (address);

    function underlierScale() external view returns (uint256);

    function vaultType() external view returns (bytes32);

    function live() external view returns (uint256);

    function lock() external;

    function setParam(bytes32 param, address data) external;

    function maturity(uint256 tokenId) external returns (uint256);

    function fairPrice(
        uint256 tokenId,
        bool net,
        bool face
    ) external view returns (uint256);

    function enter(
        uint256 tokenId,
        address user,
        uint256 amount
    ) external;

    function exit(
        uint256 tokenId,
        address user,
        uint256 amount
    ) external;
}

////// lib/fiat/src/Codex.sol
// Copyright (C) 2018 Rain <[email protected]>
/* pragma solidity ^0.8.4; */

/* import {ICodex} from "./interfaces/ICodex.sol"; */
/* import {IVault} from "./interfaces/IVault.sol"; */

/* import {Guarded} from "./utils/Guarded.sol"; */
/* import {WAD, add, sub, wmul} from "./utils/Math.sol"; */

/// @title Codex
/// @notice `Codex` is responsible for the accounting of collateral and debt balances
/// Uses Vat.sol from DSS (MakerDAO) / SafeEngine.sol from GEB (Reflexer Labs) as a blueprint
/// Changes from Vat.sol / SafeEngine.sol:
/// - only WAD precision is used (no RAD and RAY)
/// - uses a method signature based authentication scheme
/// - supports ERC1155, ERC721 style assets by TokenId
contract Codex is Guarded, ICodex {
    /// ======== Custom Errors ======== ///

    error Codex__init_vaultAlreadyInit();
    error Codex__setParam_notLive();
    error Codex__setParam_unrecognizedParam();
    error Codex__transferBalance_notAllowed();
    error Codex__transferCredit_notAllowed();
    error Codex__modifyCollateralAndDebt_notLive();
    error Codex__modifyCollateralAndDebt_vaultNotInit();
    error Codex__modifyCollateralAndDebt_ceilingExceeded();
    error Codex__modifyCollateralAndDebt_notSafe();
    error Codex__modifyCollateralAndDebt_notAllowedSender();
    error Codex__modifyCollateralAndDebt_notAllowedCollateralizer();
    error Codex__modifyCollateralAndDebt_notAllowedDebtor();
    error Codex__modifyCollateralAndDebt_debtFloor();
    error Codex__transferCollateralAndDebt_notAllowed();
    error Codex__transferCollateralAndDebt_notSafeSrc();
    error Codex__transferCollateralAndDebt_notSafeDst();
    error Codex__transferCollateralAndDebt_debtFloorSrc();
    error Codex__transferCollateralAndDebt_debtFloorDst();
    error Codex__modifyRate_notLive();

    /// ======== Storage ======== ///

    // Vault Data
    struct Vault {
        // Total Normalised Debt in Vault [wad]
        uint256 totalNormalDebt;
        // Vault's Accumulation Rate [wad]
        uint256 rate;
        // Vault's Debt Ceiling [wad]
        uint256 debtCeiling;
        // Debt Floor for Positions corresponding to this Vault [wad]
        uint256 debtFloor;
    }
    // Position Data
    struct Position {
        // Locked Collateral in Position [wad]
        uint256 collateral;
        // Normalised Debt (gross debt before rate is applied) generated by Position [wad]
        uint256 normalDebt;
    }

    /// @notice Map of delegatees who can modify collateral, debt and credit on behalf of a delegator
    /// @dev Delegator => Delegatee => hasDelegate
    mapping(address => mapping(address => uint256)) public override delegates;
    /// @notice Vaults
    /// @dev Vault => Vault Data
    mapping(address => Vault) public override vaults;
    /// @notice Positions
    /// @dev Vault => TokenId => Owner => Position
    mapping(address => mapping(uint256 => mapping(address => Position))) public override positions;
    /// @notice Token balances not put up for collateral in a Position
    /// @dev Vault => TokenId => Owner => Balance [wad]
    mapping(address => mapping(uint256 => mapping(address => uint256))) public override balances;
    /// @notice Credit balances
    /// @dev Account => Credit [wad]
    mapping(address => uint256) public override credit;
    /// @notice Unbacked Debt balances
    /// @dev Account => Unbacked Debt [wad]
    mapping(address => uint256) public override unbackedDebt;

    /// @notice Global Debt (incl. rate) outstanding == Credit Issued [wad]
    uint256 public override globalDebt;
    /// @notice Global Unbacked Debt (incl. rate) oustanding == Total Credit [wad]
    uint256 public override globalUnbackedDebt;
    /// @notice Global Debt Ceiling [wad]
    uint256 public override globalDebtCeiling;

    /// @notice Boolean indicating if this contract is live (0 - not live, 1 - live)
    uint256 public live;

    /// ======== Events ======== ///
    event Init(address indexed vault);
    event SetParam(address indexed vault, bytes32 indexed param, uint256 data);
    event GrantDelegate(address indexed delegator, address indexed delegatee);
    event RevokeDelegate(address indexed delegator, address indexed delegatee);
    event ModifyBalance(
        address indexed vault,
        uint256 indexed tokenId,
        address indexed user,
        int256 amount,
        uint256 balance
    );
    event TransferBalance(
        address indexed vault,
        uint256 indexed tokenId,
        address indexed src,
        address dst,
        uint256 amount,
        uint256 srcBalance,
        uint256 dstBalance
    );
    event TransferCredit(
        address indexed src,
        address indexed dst,
        uint256 amount,
        uint256 srcCredit,
        uint256 dstCredit
    );
    event ModifyCollateralAndDebt(
        address indexed vault,
        uint256 indexed tokenId,
        address indexed user,
        address collateralizer,
        address creditor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    );
    event TransferCollateralAndDebt(
        address indexed vault,
        uint256 indexed tokenId,
        address indexed src,
        address dst,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    );
    event ConfiscateCollateralAndDebt(
        address indexed vault,
        uint256 indexed tokenId,
        address indexed user,
        address collateralizer,
        address debtor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    );
    event SettleUnbackedDebt(address indexed debtor, uint256 debt);
    event CreateUnbackedDebt(address indexed debtor, address indexed creditor, uint256 debt);
    event ModifyRate(address indexed vault, address indexed creditor, int256 deltaRate);
    event Lock();

    constructor() Guarded() {
        live = 1;
    }

    /// ======== Configuration ======== ///

    /// @notice Initializes a new Vault
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the Vault
    function init(address vault) external override checkCaller {
        if (vaults[vault].rate != 0) revert Codex__init_vaultAlreadyInit();
        vaults[vault].rate = WAD;
        emit Init(vault);
    }

    /// @notice Sets various variables for this contract
    /// @dev Sender has to be allowed to call this method
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [wad]
    function setParam(bytes32 param, uint256 data) external override checkCaller {
        if (live == 0) revert Codex__setParam_notLive();
        if (param == "globalDebtCeiling") globalDebtCeiling = data;
        else revert Codex__setParam_unrecognizedParam();
        emit SetParam(address(0), param, data);
    }

    /// @notice Sets various variables for a Vault
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the Vault
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [wad]
    function setParam(
        address vault,
        bytes32 param,
        uint256 data
    ) external override checkCaller {
        if (live == 0) revert Codex__setParam_notLive();
        if (param == "debtCeiling") vaults[vault].debtCeiling = data;
        else if (param == "debtFloor") vaults[vault].debtFloor = data;
        else revert Codex__setParam_unrecognizedParam();
        emit SetParam(vault, param, data);
    }

    /// ======== Caller Delegation ======== ///

    /// @notice Grants the delegatee the ability to modify collateral, debt and credit balances on behalf of the caller
    /// @param delegatee Address of the delegatee
    function grantDelegate(address delegatee) external override {
        delegates[msg.sender][delegatee] = 1;
        emit GrantDelegate(msg.sender, delegatee);
    }

    /// @notice Revokes the delegatee's ability to modify collateral, debt and credit balances on behalf of the caller
    /// @param delegatee Address of the delegatee
    function revokeDelegate(address delegatee) external override {
        delegates[msg.sender][delegatee] = 0;
        emit RevokeDelegate(msg.sender, delegatee);
    }

    /// @notice Checks the delegate
    /// @param delegator Address of the delegator
    /// @param delegatee Address of the delegatee
    /// @return True if delegate is granted
    function hasDelegate(address delegator, address delegatee) internal view returns (bool) {
        return delegator == delegatee || delegates[delegator][delegatee] == 1;
    }

    /// ======== Credit and Token Balance Administration ======== ///

    /// @notice Updates the token balance for a `user`
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the Vault
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param user Address of the user
    /// @param amount Amount to add (positive) or subtract (negative) [wad]
    function modifyBalance(
        address vault,
        uint256 tokenId,
        address user,
        int256 amount
    ) external override checkCaller {
        balances[vault][tokenId][user] = add(balances[vault][tokenId][user], amount);
        emit ModifyBalance(vault, tokenId, user, amount, balances[vault][tokenId][user]);
    }

    /// @notice Transfer an `amount` of tokens from `src` to `dst`
    /// @dev Sender has to be delegated by `src`
    /// @param vault Address of the Vault
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param src From address
    /// @param dst To address
    /// @param amount Amount to be transferred [wad]
    function transferBalance(
        address vault,
        uint256 tokenId,
        address src,
        address dst,
        uint256 amount
    ) external override {
        if (!hasDelegate(src, msg.sender)) revert Codex__transferBalance_notAllowed();
        balances[vault][tokenId][src] = sub(balances[vault][tokenId][src], amount);
        balances[vault][tokenId][dst] = add(balances[vault][tokenId][dst], amount);
        emit TransferBalance(
            vault,
            tokenId,
            src,
            dst,
            amount,
            balances[vault][tokenId][src],
            balances[vault][tokenId][dst]
        );
    }

    /// @notice Transfer an `amount` of Credit from `src` to `dst`
    /// @dev Sender has to be delegated by `src`
    /// @param src From address
    /// @param dst To address
    /// @param amount Amount to be transferred [wad]
    function transferCredit(
        address src,
        address dst,
        uint256 amount
    ) external override {
        if (!hasDelegate(src, msg.sender)) revert Codex__transferCredit_notAllowed();
        credit[src] = sub(credit[src], amount);
        credit[dst] = add(credit[dst], amount);
        emit TransferCredit(src, dst, amount, credit[src], credit[dst]);
    }

    /// ======== Position Administration ======== ///

    /// @notice Modifies a Position's collateral and debt balances
    /// @dev Checks that the global debt ceiling and the vault's debt ceiling have not been exceeded,
    /// that the Position is still safe after the modification,
    /// that the sender is delegated by the owner if the collateral-to-debt ratio decreased,
    /// that the sender is delegated by the collateralizer if new collateral is put up,
    /// that the sender is delegated by the creditor if debt is settled,
    /// and that the vault debt floor is exceeded
    /// @param vault Address of the Vault
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param user Address of the user
    /// @param collateralizer Address of who puts up or receives the collateral delta
    /// @param creditor Address of who provides or receives the credit delta for the debt delta
    /// @param deltaCollateral Amount of collateral to put up (+) for or remove (-) from this Position [wad]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to generate (+) or
    /// settle (-) on this Position [wad]
    function modifyCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address user,
        address collateralizer,
        address creditor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external override {
        // system is live
        if (live == 0) revert Codex__modifyCollateralAndDebt_notLive();

        Position memory p = positions[vault][tokenId][user];
        Vault memory v = vaults[vault];
        // vault has been initialised
        if (v.rate == 0) revert Codex__modifyCollateralAndDebt_vaultNotInit();

        p.collateral = add(p.collateral, deltaCollateral);
        p.normalDebt = add(p.normalDebt, deltaNormalDebt);
        v.totalNormalDebt = add(v.totalNormalDebt, deltaNormalDebt);

        int256 deltaDebt = wmul(v.rate, deltaNormalDebt);
        uint256 debt = wmul(v.rate, p.normalDebt);
        globalDebt = add(globalDebt, deltaDebt);

        // either debt has decreased, or debt ceilings are not exceeded
        if (deltaNormalDebt > 0 && (wmul(v.totalNormalDebt, v.rate) > v.debtCeiling || globalDebt > globalDebtCeiling))
            revert Codex__modifyCollateralAndDebt_ceilingExceeded();
        // position is either less risky than before, or it is safe
        if (
            (deltaNormalDebt > 0 || deltaCollateral < 0) &&
            debt > wmul(p.collateral, IVault_1(vault).fairPrice(tokenId, true, false))
        ) revert Codex__modifyCollateralAndDebt_notSafe();

        // position is either more safe, or the owner consents
        if ((deltaNormalDebt > 0 || deltaCollateral < 0) && !hasDelegate(user, msg.sender))
            revert Codex__modifyCollateralAndDebt_notAllowedSender();
        // collateralizer consents if new collateral is put up
        if (deltaCollateral > 0 && !hasDelegate(collateralizer, msg.sender))
            revert Codex__modifyCollateralAndDebt_notAllowedCollateralizer();

        // creditor consents if debt is settled with credit
        if (deltaNormalDebt < 0 && !hasDelegate(creditor, msg.sender))
            revert Codex__modifyCollateralAndDebt_notAllowedDebtor();

        // position has no debt, or a non-dusty amount
        if (p.normalDebt != 0 && debt < v.debtFloor) revert Codex__modifyCollateralAndDebt_debtFloor();

        balances[vault][tokenId][collateralizer] = sub(balances[vault][tokenId][collateralizer], deltaCollateral);
        credit[creditor] = add(credit[creditor], deltaDebt);

        positions[vault][tokenId][user] = p;
        vaults[vault] = v;

        emit ModifyCollateralAndDebt(vault, tokenId, user, collateralizer, creditor, deltaCollateral, deltaNormalDebt);
    }

    /// @notice Transfers a Position's collateral and debt balances to another Position
    /// @dev Checks that the sender is delegated by `src` and `dst` Position owners,
    /// that the `src` and `dst` Positions are still safe after the transfer,
    /// and that the `src` and `dst` Positions' debt exceed the vault's debt floor
    /// @param vault Address of the Vault
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param src Address of the `src` Positions owner
    /// @param dst Address of the `dst` Positions owner
    /// @param deltaCollateral Amount of collateral to send to (+) or from (-) the `src` Position [wad]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to send to (+) or
    /// from (-) the `dst` Position [wad]
    function transferCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address src,
        address dst,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external override {
        Position storage pSrc = positions[vault][tokenId][src];
        Position storage pDst = positions[vault][tokenId][dst];
        Vault storage v = vaults[vault];

        pSrc.collateral = sub(pSrc.collateral, deltaCollateral);
        pSrc.normalDebt = sub(pSrc.normalDebt, deltaNormalDebt);
        pDst.collateral = add(pDst.collateral, deltaCollateral);
        pDst.normalDebt = add(pDst.normalDebt, deltaNormalDebt);

        uint256 debtSrc = wmul(pSrc.normalDebt, v.rate);
        uint256 debtDst = wmul(pDst.normalDebt, v.rate);

        // both sides consent
        if (!hasDelegate(src, msg.sender) || !hasDelegate(dst, msg.sender))
            revert Codex__transferCollateralAndDebt_notAllowed();

        // both sides safe
        if (debtSrc > wmul(pSrc.collateral, IVault_1(vault).fairPrice(tokenId, true, false)))
            revert Codex__transferCollateralAndDebt_notSafeSrc();
        if (debtDst > wmul(pDst.collateral, IVault_1(vault).fairPrice(tokenId, true, false)))
            revert Codex__transferCollateralAndDebt_notSafeDst();

        // both sides non-dusty
        if (pSrc.normalDebt != 0 && debtSrc < v.debtFloor) revert Codex__transferCollateralAndDebt_debtFloorSrc();
        if (pDst.normalDebt != 0 && debtDst < v.debtFloor) revert Codex__transferCollateralAndDebt_debtFloorDst();

        emit TransferCollateralAndDebt(vault, tokenId, src, dst, deltaCollateral, deltaNormalDebt);
    }

    /// @notice Confiscates a Position's collateral and debt balances
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the Vault
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param user Address of the user
    /// @param collateralizer Address of who puts up or receives the collateral delta
    /// @param debtor Address of who provides or receives the debt delta
    /// @param deltaCollateral Amount of collateral to put up (+) for or remove (-) from this Position [wad]
    /// @param deltaNormalDebt Amount of normalized debt (gross, before rate is applied) to generate (+) or
    /// settle (-) on this Position [wad]
    function confiscateCollateralAndDebt(
        address vault,
        uint256 tokenId,
        address user,
        address collateralizer,
        address debtor,
        int256 deltaCollateral,
        int256 deltaNormalDebt
    ) external override checkCaller {
        Position storage position = positions[vault][tokenId][user];
        Vault storage v = vaults[vault];

        position.collateral = add(position.collateral, deltaCollateral);
        position.normalDebt = add(position.normalDebt, deltaNormalDebt);
        v.totalNormalDebt = add(v.totalNormalDebt, deltaNormalDebt);

        int256 deltaDebt = wmul(v.rate, deltaNormalDebt);

        balances[vault][tokenId][collateralizer] = sub(balances[vault][tokenId][collateralizer], deltaCollateral);
        unbackedDebt[debtor] = sub(unbackedDebt[debtor], deltaDebt);
        globalUnbackedDebt = sub(globalUnbackedDebt, deltaDebt);

        emit ConfiscateCollateralAndDebt(
            vault,
            tokenId,
            user,
            collateralizer,
            debtor,
            deltaCollateral,
            deltaNormalDebt
        );
    }

    /// ======== Unbacked Debt ======== ///

    /// @notice Settles unbacked debt with the sender's credit
    /// @dev Reverts if the sender does not have sufficient credit available to settle the debt
    /// @param debt Amount of debt to settle [wawd]
    function settleUnbackedDebt(uint256 debt) external override {
        address debtor = msg.sender;
        unbackedDebt[debtor] = sub(unbackedDebt[debtor], debt);
        credit[debtor] = sub(credit[debtor], debt);
        globalUnbackedDebt = sub(globalUnbackedDebt, debt);
        globalDebt = sub(globalDebt, debt);
        emit SettleUnbackedDebt(debtor, debt);
    }

    /// @notice Create unbacked debt / credit
    /// @dev Sender has to be allowed to call this method
    /// @param debtor Address of the account who takes the unbacked debt
    /// @param creditor Address of the account who gets the credit
    /// @param debt Amount of unbacked debt / credit to generate [wad]
    function createUnbackedDebt(
        address debtor,
        address creditor,
        uint256 debt
    ) external override checkCaller {
        unbackedDebt[debtor] = add(unbackedDebt[debtor], debt);
        credit[creditor] = add(credit[creditor], debt);
        globalUnbackedDebt = add(globalUnbackedDebt, debt);
        globalDebt = add(globalDebt, debt);
        emit CreateUnbackedDebt(debtor, creditor, debt);
    }

    /// ======== Debt Interest Rates ======== ///

    /// @notice Updates the rate value and collects the accrued interest for a Vault
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the vault
    /// @param creditor Address of the account who gets the accrued interest
    /// @param deltaRate Delta to increase (+) or decrease (-) the rate [percentage in wad]
    function modifyRate(
        address vault,
        address creditor,
        int256 deltaRate
    ) external override checkCaller {
        if (live == 0) revert Codex__modifyRate_notLive();
        Vault storage v = vaults[vault];
        v.rate = add(v.rate, deltaRate);
        int256 wad = wmul(v.totalNormalDebt, deltaRate);
        credit[creditor] = add(credit[creditor], wad);
        globalDebt = add(globalDebt, wad);
        emit ModifyRate(vault, creditor, deltaRate);
    }

    /// ======== Shutdown ======== ///

    /// @notice Locks the contract
    /// @dev Sender has to be allowed to call this method
    function lock() external override checkCaller {
        live = 0;
        emit Lock();
    }
}

////// lib/fiat/src/Collybus.sol
/* pragma solidity ^0.8.4; */

/* import {PRBMathUD60x18} from "prb-math/contracts/PRBMathUD60x18.sol"; */

/* import {ICodex} from "./interfaces/ICodex.sol"; */
/* import {ICollybus} from "./interfaces/ICollybus.sol"; */

/* import {Guarded} from "./utils/Guarded.sol"; */
/* import {WAD, add, sub, wmul, wdiv} from "./utils/Math.sol"; */

/// @title Collybus
/// @notice `Collybus` stores a spot price and discount rate for every Vault / asset.
contract Collybus is Guarded, ICollybus {
    /// ======== Custom Errors ======== ///

    error Collybus__setParam_notLive();
    error Collybus__setParam_unrecognizedParam();
    error Collybus__updateSpot_notLive();
    error Collybus__updateDiscountRate_notLive();
    error Collybus__updateDiscountRate_invalidRateId();
    error Collybus__updateDiscountRate_invalidRate();

    using PRBMathUD60x18 for uint256;

    /// ======== Storage ======== ///

    struct VaultConfig {
        // Liquidation ratio [wad]
        uint128 liquidationRatio;
        // Default fixed interest rate oracle system rateId
        uint128 defaultRateId;
    }

    /// @notice Vault Configuration
    /// @dev Vault => Vault Config
    mapping(address => VaultConfig) public override vaults;
    /// @notice Spot prices by token address
    /// @dev Token address => spot price [wad]
    mapping(address => uint256) public override spots;
    /// @notice Fixed interest rate oracle system rateId
    /// @dev RateId => Discount Rate [wad]
    mapping(uint256 => uint256) public override rates;
    // Fixed interest rate oracle system rateId for each TokenId
    // Vault => TokenId => RateId
    mapping(address => mapping(uint256 => uint256)) public override rateIds;

    /// @notice Redemption Price of a Credit unit [wad]
    uint256 public immutable override redemptionPrice;

    /// @notice Boolean indicating if this contract is live (0 - not live, 1 - live)
    uint256 public override live;

    /// ======== Events ======== ///
    event SetParam(bytes32 indexed param, uint256 data);
    event SetParam(address indexed vault, bytes32 indexed param, uint256 data);
    event SetParam(address indexed vault, uint256 indexed tokenId, bytes32 indexed param, uint256 data);
    event UpdateSpot(address indexed token, uint256 spot);
    event UpdateDiscountRate(uint256 indexed rateId, uint256 rate);
    event Lock();

    // TODO: why not making timeScale and redemption price function arguments?
    constructor() Guarded() {
        redemptionPrice = WAD; // 1.0
        live = 1;
    }

    /// ======== Configuration ======== ///

    /// @notice Sets various variables for this contract
    /// @dev Sender has to be allowed to call this method
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [wad]
    function setParam(bytes32 param, uint256 data) external override checkCaller {
        if (live == 0) revert Collybus__setParam_notLive();
        if (param == "live") live = data;
        else revert Collybus__setParam_unrecognizedParam();
        emit SetParam(address(0), param, data);
    }

    /// @notice Sets various variables for a Vault
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the Vault
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [wad]
    function setParam(
        address vault,
        bytes32 param,
        uint128 data
    ) external override checkCaller {
        if (live == 0) revert Collybus__setParam_notLive();
        if (param == "liquidationRatio") vaults[vault].liquidationRatio = data;
        else if (param == "defaultRateId") vaults[vault].defaultRateId = data;
        else revert Collybus__setParam_unrecognizedParam();
        emit SetParam(vault, param, data);
    }

    /// @notice Sets various variables for a Vault
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the Vault
    /// @param param Name of the variable to set
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param data New value to set for the variable [wad]
    function setParam(
        address vault,
        uint256 tokenId,
        bytes32 param,
        uint256 data
    ) external override checkCaller {
        if (live == 0) revert Collybus__setParam_notLive();
        if (param == "rateId") rateIds[vault][tokenId] = data;
        else revert Collybus__setParam_unrecognizedParam();
        emit SetParam(vault, tokenId, param, data);
    }

    /// ======== Spot Prices ======== ///

    /// @notice Sets a token's spot price
    /// @dev Sender has to be allowed to call this method
    /// @param token Address of the token
    /// @param spot Spot price [wad]
    function updateSpot(address token, uint256 spot) external override checkCaller {
        if (live == 0) revert Collybus__updateSpot_notLive();
        spots[token] = spot;
        emit UpdateSpot(token, spot);
    }

    /// ======== Discount Rate ======== ///

    /// @notice Sets the discount rate by RateId
    /// @param rateId RateId of the discount rate feed
    /// @param rate Discount rate [wad]
    function updateDiscountRate(uint256 rateId, uint256 rate) external override checkCaller {
        if (live == 0) revert Collybus__updateDiscountRate_notLive();
        if (rateId >= type(uint128).max) revert Collybus__updateDiscountRate_invalidRateId();
        if (rate >= 2e10) revert Collybus__updateDiscountRate_invalidRate();
        rates[rateId] = rate;
        emit UpdateDiscountRate(rateId, rate);
    }

    /// @notice Returns the internal price for an asset
    /// @dev
    ///                 redemptionPrice
    /// v = ----------------------------------------
    ///                       (maturity - timestamp)
    ///     (1 + discountRate)
    ///
    /// @param vault Address of the asset corresponding Vault
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param maturity Maturity of the asset [unix timestamp in seconds]
    /// @param net Boolean (true - with liquidation safety margin, false - without)
    /// @return price Internal price [wad]
    function read(
        address vault,
        address underlier,
        uint256 tokenId,
        uint256 maturity,
        bool net
    ) external view override returns (uint256 price) {
        VaultConfig memory vaultConfig = vaults[vault];
        // fetch applicable fixed interest rate oracle system rateId
        uint256 rateId = rateIds[vault][tokenId];
        if (rateId == uint256(0)) rateId = vaultConfig.defaultRateId; // if not set, use default rateId
        // fetch discount rate
        uint256 discountRate = rates[rateId];
        // apply discount rate if discountRate > 0
        if (discountRate != 0 && maturity > block.timestamp) {
            uint256 rate = add(WAD, discountRate).powu(sub(maturity, block.timestamp));
            price = wdiv(redemptionPrice, rate); // den. in Underlier
        } else {
            price = redemptionPrice; // den. in Underlier
        }
        price = wmul(price, spots[underlier]); // den. in USD
        if (net) price = wdiv(price, vaultConfig.liquidationRatio); // with liquidation safety margin
    }

    /// ======== Shutdown ======== ///

    /// @notice Locks the contract
    /// @dev Sender has to be allowed to call this method
    function lock() external override checkCaller {
        live = 0;
        emit Lock();
    }
}

////// lib/fiat/src/interfaces/IFIAT.sol
/* pragma solidity ^0.8.4; */

interface IFIAT {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function version() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external view returns (bytes32);

    function transfer(address from, uint256 amount) external returns (bool);

    function transferFrom(
        address to,
        address from,
        uint256 amount
    ) external returns (bool);

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function approve(address spender, uint256 amount) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

////// lib/fiat/src/FIAT.sol
/* pragma solidity ^0.8.4; */

/* import "./interfaces/IFIAT.sol"; */

/* import "./utils/Guarded.sol"; */
/* import "./utils/Math.sol"; */

/// @title Fixed Income Asset Token (FIAT)
/// @notice `FIAT` is the protocol's stable asset which can be redeemed for `Credit` via `Moneta`
contract FIAT is Guarded, IFIAT {
    /// ======== Custom Errors ======== ///

    error FIAT__transferFrom_insufficientBalance();
    error FIAT__transferFrom_insufficientAllowance();
    error FIAT__burn_insufficientBalance();
    error FIAT__burn_insufficientAllowance();
    error FIAT__permit_ownerIsZero();
    error FIAT__permit_invalidOwner();
    error FIAT__permit_deadline();

    /// ======== Storage ======== ///

    /// @notice Name of the token
    string public constant override name = "Fixed Income Asset Token";
    /// @notice Symbol of the token
    string public constant override symbol = "FIAT";
    /// @notice Version of the token contract. Used by `permit`.
    string public constant override version = "1";
    /// @notice Uses WAD precision
    uint8 public constant override decimals = 18;
    /// @notice Amount of tokens in existence [wad]
    uint256 public override totalSupply;

    /// @notice Amount of tokens owned by `Account`
    /// @dev Account => Balance [wad]
    mapping(address => uint256) public override balanceOf;
    /// @notice Remaining amount of tokens that `spender` will be allowed to spend on behalf of `owner`
    /// @dev Owner => Spender => Allowance [wad]
    mapping(address => mapping(address => uint256)) public override allowance;
    /// @notice Current nonce for `owner`. This value must be included whenever a signature is generated for `permit`.
    /// @dev Account => nonce
    mapping(address => uint256) public override nonces;

    /// @notice Domain Separator used in the encoding of the signature for `permit`, as defined by EIP712 and EIP2612
    bytes32 public immutable override DOMAIN_SEPARATOR;
    /// @notice Hash of the permit data structure. Used to verify the callers signature for `permit`,
    /// as defined by EIP2612.
    bytes32 public immutable override PERMIT_TYPEHASH;

    /// ======== Events ======== ///

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    constructor() Guarded() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                block.chainid,
                address(this)
            )
        );
        PERMIT_TYPEHASH = keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );
    }

    /// ======== ERC20 ======== ///

    /// @notice Transfers `amount` tokens from the caller's account to `to`
    /// @dev Boolean value indicating whether the operation succeeded
    /// @param to Address of the recipient
    /// @param amount Amount of tokens to transfer [wad]
    function transfer(address to, uint256 amount) external override returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }

    /// @notice Transfers `amount` tokens from `from` to `to` using the allowance mechanism
    /// `amount` is then deducted from the caller's allowance
    /// @dev Boolean value indicating whether the operation succeeded
    /// @param from Address of the sender
    /// @param to Address of the recipient
    /// @param amount Amount of tokens to transfer [wad]
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override returns (bool) {
        if (from != msg.sender) {
            uint256 allowance_ = allowance[from][msg.sender];
            if (allowance_ != type(uint256).max) {
                if (allowance_ < amount) revert FIAT__transferFrom_insufficientAllowance();
                allowance[from][msg.sender] = sub(allowance_, amount);
            }
        }

        if (balanceOf[from] < amount) revert FIAT__transferFrom_insufficientBalance();
        balanceOf[from] = sub(balanceOf[from], amount);
        unchecked {
            // Cannot overflow because the sum of all user balances can't exceed the max uint256 value.
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens
    /// @param spender Address of the spender
    /// @param amount Amount of tokens the spender is allowed to spend
    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /// ======== Minting and Burning ======== ///

    /// @notice Increases the totalSupply by `amount` and transfers the new tokens to `to`
    /// @dev Sender has to be allowed to call this method
    /// @param to Address to which tokens should be credited to
    /// @param amount Amount of tokens to be minted [wad]
    function mint(address to, uint256 amount) external override checkCaller {
        totalSupply = add(totalSupply, amount);
        // Cannot overflow because the sum of all user balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }
        emit Transfer(address(0), to, amount);
    }

    /// @notice Decreases the totalSupply by `amount` and using the tokens from `from`
    /// @dev If `from` is not the caller, caller needs to have sufficient allowance from `from`,
    /// `amount` is then deducted from the caller's allowance
    /// @param from Address from which tokens should be burned from
    /// @param amount Amount of tokens to be burned [wad]
    function burn(address from, uint256 amount) external override {
        if (from != msg.sender) {
            uint256 allowance_ = allowance[from][msg.sender];
            if (allowance_ != type(uint256).max) {
                if (allowance_ < amount) revert FIAT__transferFrom_insufficientAllowance();
                allowance[from][msg.sender] = sub(allowance_, amount);
            }
        }

        uint256 balance = balanceOf[from];
        if (balance < amount) revert FIAT__burn_insufficientBalance();
        balanceOf[from] = sub(balance, amount);

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }
        emit Transfer(from, address(0), amount);
    }

    /// ======== EIP2612 ======== ///

    /// @notice Sets `value` as the allowance of `spender` over `owner`'s tokens, given `owner`'s signed approval
    /// @dev Check that the `owner` cannot is not zero, that `deadline` is greater than the current block.timestamp
    /// and that the signature uses the `owner`'s current nonce
    /// @param owner Address of the owner who sets allowance for `spender`
    /// @param spender Address of the spender for is given allowance to
    /// @param value Amount of tokens the `spender` is allowed to spend
    /// @param v From the secp256k1 signature
    /// @param r From the secp256k1 signature
    /// @param s From the secp256k1 signature
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR,
                    // owner's nonce which cannot realistically overflow
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            if (owner == address(0)) revert FIAT__permit_ownerIsZero();
            if (owner != ecrecover(digest, v, r, s)) revert FIAT__permit_invalidOwner();
            if (block.timestamp > deadline) revert FIAT__permit_deadline();

            allowance[owner][spender] = value;
            emit Approval(owner, spender, value);
        }
    }
}

////// lib/fiat/src/interfaces/ILimes.sol
/* pragma solidity ^0.8.4; */

/* import {ICodex} from "./ICodex.sol"; */
/* import {IAer} from "./IAer.sol"; */

interface ILimes {
    function codex() external view returns (ICodex);

    function aer() external view returns (IAer);

    function vaults(address)
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        );

    function live() external view returns (uint256);

    function globalMaxDebtOnAuction() external view returns (uint256);

    function globalDebtOnAuction() external view returns (uint256);

    function setParam(bytes32 param, address data) external;

    function setParam(bytes32 param, uint256 data) external;

    function setParam(
        address vault,
        bytes32 param,
        uint256 data
    ) external;

    function setParam(
        address vault,
        bytes32 param,
        address collateralAuction
    ) external;

    function liquidationPenalty(address vault) external view returns (uint256);

    function liquidate(
        address vault,
        uint256 tokenId,
        address position,
        address keeper
    ) external returns (uint256 auctionId);

    function liquidated(
        address vault,
        uint256 tokenId,
        uint256 debt
    ) external;

    function lock() external;
}

////// lib/fiat/src/interfaces/IPriceCalculator.sol
/* pragma solidity ^0.8.4; */

interface IPriceCalculator {
    // 1st arg: initial price [wad]
    // 2nd arg: seconds since auction start [seconds]
    // returns: current auction price [wad]
    function price(uint256, uint256) external view returns (uint256);
}

////// lib/fiat/src/interfaces/ICollateralAuction.sol
/* pragma solidity ^0.8.4; */

/* import {IPriceCalculator} from "./IPriceCalculator.sol"; */
/* import {ICodex} from "./ICodex.sol"; */
/* import {ICollybus} from "./ICollybus.sol"; */
/* import {IAer} from "./IAer.sol"; */
/* import {ILimes} from "./ILimes.sol"; */

interface CollateralAuctionCallee {
    function collateralAuctionCall(
        address,
        uint256,
        uint256,
        bytes calldata
    ) external;
}

interface ICollateralAuction {
    function vaults(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            ICollybus,
            IPriceCalculator
        );

    function codex() external view returns (ICodex);

    function limes() external view returns (ILimes);

    function aer() external view returns (IAer);

    function feeTip() external view returns (uint64);

    function flatTip() external view returns (uint192);

    function auctionCounter() external view returns (uint256);

    function activeAuctions(uint256) external view returns (uint256);

    function auctions(uint256)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            address,
            uint96,
            uint256
        );

    function stopped() external view returns (uint256);

    function init(address vault, address collybus) external;

    function setParam(bytes32 param, uint256 data) external;

    function setParam(bytes32 param, address data) external;

    function setParam(
        address vault,
        bytes32 param,
        uint256 data
    ) external;

    function setParam(
        address vault,
        bytes32 param,
        address data
    ) external;

    function startAuction(
        uint256 debt,
        uint256 collateralToSell,
        address vault,
        uint256 tokenId,
        address user,
        address keeper
    ) external returns (uint256 auctionId);

    function redoAuction(uint256 auctionId, address keeper) external;

    function takeCollateral(
        uint256 auctionId,
        uint256 collateralAmount,
        uint256 maxPrice,
        address recipient,
        bytes calldata data
    ) external;

    function count() external view returns (uint256);

    function list() external view returns (uint256[] memory);

    function getStatus(uint256 auctionId)
        external
        view
        returns (
            bool needsRedo,
            uint256 price,
            uint256 collateralToSell,
            uint256 debt
        );

    function updateAuctionDebtFloor(address vault) external;

    function cancelAuction(uint256 auctionId) external;
}

////// lib/fiat/src/Limes.sol
// Copyright (C) 2020-2021 Maker Ecosystem Growth Holdings, INC.
/* pragma solidity ^0.8.4; */

/* import {ICodex} from "./interfaces/ICodex.sol"; */
/* import {ICollateralAuction} from "./interfaces/ICollateralAuction.sol"; */
/* import {IAer} from "./interfaces/IAer.sol"; */
/* import {ILimes} from "./interfaces/ILimes.sol"; */
/* import {IVault} from "./interfaces/IVault.sol"; */

/* import {Guarded} from "./utils/Guarded.sol"; */
/* import {WAD, min, add, sub, mul, wmul} from "./utils/Math.sol"; */

/// @title Limes
/// @notice `Limes` is responsible for triggering liquidations of unsafe Positions and
/// putting the Position's collateral up for auction
/// Uses Dog.sol from DSS (MakerDAO) as a blueprint
/// Changes from Dog.sol:
/// - only WAD precision is used (no RAD and RAY)
/// - uses a method signature based authentication scheme
/// - supports ERC1155, ERC721 style assets by TokenId
contract Limes is Guarded, ILimes {
    /// ======== Custom Errors ======== ///

    error Limes__setParam_liquidationPenaltyLtWad();
    error Limes__setParam_unrecognizedParam();
    error Limes__liquidate_notLive();
    error Limes__liquidate_notUnsafe();
    error Limes__liquidate_maxDebtOnAuction();
    error Limes__liquidate_dustyAuctionFromPartialLiquidation();
    error Limes__liquidate_nullAuction();
    error Limes__liquidate_overflow();

    /// ======== Storage ======== ///

    // Vault specific configuration data
    struct VaultConfig {
        // Auction contract for collateral
        address collateralAuction;
        // Liquidation penalty [wad]
        uint256 liquidationPenalty;
        // Max credit needed to cover debt+fees of active auctions per vault [wad]
        uint256 maxDebtOnAuction;
        // Amount of credit needed to cover debt+fees for all active auctions per vault [wad]
        uint256 debtOnAuction;
    }

    /// @notice Vault Configs
    /// @dev Vault => Vault Config
    mapping(address => VaultConfig) public override vaults;

    /// @notice Codex
    ICodex public immutable override codex;
    /// @notice Aer
    IAer public override aer;

    /// @notice Max credit needed to cover debt+fees of active auctions [wad]
    uint256 public override globalMaxDebtOnAuction;
    /// @notice Amount of credit needed to cover debt+fees for all active auctions [wad]
    uint256 public override globalDebtOnAuction;

    /// @notice Boolean indicating if this contract is live (0 - not live, 1 - live)
    uint256 public override live;

    /// ======== Events ======== ///

    event SetParam(bytes32 indexed param, uint256 data);
    event SetParam(bytes32 indexed param, address data);
    event SetParam(address indexed vault, bytes32 indexed param, uint256 data);
    event SetParam(address indexed vault, bytes32 indexed param, address collateralAuction);

    event Liquidate(
        address indexed vault,
        uint256 indexed tokenId,
        address position,
        uint256 collateral,
        uint256 normalDebt,
        uint256 due,
        address collateralAuction,
        uint256 indexed auctionId
    );
    event Liquidated(address indexed vault, uint256 indexed tokenId, uint256 debt);
    event Lock();

    constructor(address codex_) Guarded() {
        codex = ICodex(codex_);
        live = 1;
    }

    /// ======== Configuration ======== ///

    /// @notice Sets various variables for this contract
    /// @dev Sender has to be allowed to call this method
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [address]
    function setParam(bytes32 param, address data) external override checkCaller {
        if (param == "aer") aer = IAer(data);
        else revert Limes__setParam_unrecognizedParam();
        emit SetParam(param, data);
    }

    /// @notice Sets various variables for this contract
    /// @dev Sender has to be allowed to call this method
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [wad]
    function setParam(bytes32 param, uint256 data) external override checkCaller {
        if (param == "globalMaxDebtOnAuction") globalMaxDebtOnAuction = data;
        else revert Limes__setParam_unrecognizedParam();
        emit SetParam(param, data);
    }

    /// @notice Sets various variables for a Vault
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the Vault
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [wad]
    function setParam(
        address vault,
        bytes32 param,
        uint256 data
    ) external override checkCaller {
        if (param == "liquidationPenalty") {
            if (data < WAD) revert Limes__setParam_liquidationPenaltyLtWad();
            vaults[vault].liquidationPenalty = data;
        } else if (param == "maxDebtOnAuction") vaults[vault].maxDebtOnAuction = data;
        else revert Limes__setParam_unrecognizedParam();
        emit SetParam(vault, param, data);
    }

    /// @notice Sets various variables for a Vault
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the Vault
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [address]
    function setParam(
        address vault,
        bytes32 param,
        address data
    ) external override checkCaller {
        if (param == "collateralAuction") {
            vaults[vault].collateralAuction = data;
        } else revert Limes__setParam_unrecognizedParam();
        emit SetParam(vault, param, data);
    }

    /// ======== Liquidations ======== ///

    /// @notice Direct access to the current liquidation penalty set for a Vault
    /// @param vault Address of the Vault
    /// @return liquidation penalty [wad]
    function liquidationPenalty(address vault) external view override returns (uint256) {
        return vaults[vault].liquidationPenalty;
    }

    /// @notice Liquidate a Position and start a Dutch auction to sell its collateral for credit.
    /// @dev The third argument is the address that will receive the liquidation reward, if any.
    /// The entire Position will be liquidated except when the target amount of credit to be raised in
    /// the resulting auction (debt of Position + liquidation penalty) causes either globalDebtOnAuction to exceed
    /// globalMaxDebtOnAuction or vault.debtOnAuction to exceed vault.maxDebtOnAuction by an economically
    /// significant amount. In that case, a partial liquidation is performed to respect the global and per-vault limits
    /// on outstanding credit target. The one exception is if the resulting auction would likely
    /// have too little collateral to be of interest to Keepers (debt taken from Position < vault.debtFloor),
    /// in which case the function reverts. Please refer to the code and comments within if more detail is desired.
    /// @param vault Address of the Position's Vault
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20) of the Position
    /// @param position Address of the owner of the Position
    /// @param keeper Address of the keeper who triggers the liquidation and receives the reward
    /// @return auctionId Indentifier of the started auction
    function liquidate(
        address vault,
        uint256 tokenId,
        address position,
        address keeper
    ) external override returns (uint256 auctionId) {
        if (live == 0) revert Limes__liquidate_notLive();

        VaultConfig memory mvault = vaults[vault];
        uint256 deltaNormalDebt;
        uint256 rate;
        uint256 debtFloor;
        uint256 deltaCollateral;
        unchecked {
            {
                (uint256 collateral, uint256 normalDebt) = codex.positions(vault, tokenId, position);
                uint256 price = IVault_1(vault).fairPrice(tokenId, true, false);
                (, rate, , debtFloor) = codex.vaults(vault);
                if (price == 0 || mul(collateral, price) >= mul(normalDebt, rate)) revert Limes__liquidate_notUnsafe();

                // Get the minimum value between:
                // 1) Remaining space in the globalMaxDebtOnAuction
                // 2) Remaining space in the vault.maxDebtOnAuction
                if (!(globalMaxDebtOnAuction > globalDebtOnAuction && mvault.maxDebtOnAuction > mvault.debtOnAuction))
                    revert Limes__liquidate_maxDebtOnAuction();

                uint256 room = min(
                    globalMaxDebtOnAuction - globalDebtOnAuction,
                    mvault.maxDebtOnAuction - mvault.debtOnAuction
                );

                // normalize room by subtracting rate and liquidationPenalty
                deltaNormalDebt = min(normalDebt, (((room * WAD) / rate) * WAD) / mvault.liquidationPenalty);

                // Partial liquidation edge case logic
                if (normalDebt > deltaNormalDebt) {
                    if (wmul(normalDebt - deltaNormalDebt, rate) < debtFloor) {
                        // If the leftover Position would be dusty, just liquidate it entirely.
                        // This will result in at least one of v.debtOnAuction > v.maxDebtOnAuction or
                        // globalDebtOnAuction > globalMaxDebtOnAuction becoming true. The amount of excess will
                        // be bounded above by ceiling(v.debtFloor * v.liquidationPenalty / WAD). This deviation is
                        // assumed to be small compared to both v.maxDebtOnAuction and globalMaxDebtOnAuction, so that
                        // the extra amount of credit is not of economic concern.
                        deltaNormalDebt = normalDebt;
                    } else {
                        // In a partial liquidation, the resulting auction should also be non-dusty.
                        if (wmul(deltaNormalDebt, rate) < debtFloor)
                            revert Limes__liquidate_dustyAuctionFromPartialLiquidation();
                    }
                }

                deltaCollateral = mul(collateral, deltaNormalDebt) / normalDebt;
            }
        }

        if (deltaCollateral == 0) revert Limes__liquidate_nullAuction();
        if (!(deltaNormalDebt <= 2**255 && deltaCollateral <= 2**255)) revert Limes__liquidate_overflow();

        codex.confiscateCollateralAndDebt(
            vault,
            tokenId,
            position,
            mvault.collateralAuction,
            address(aer),
            -int256(deltaCollateral),
            -int256(deltaNormalDebt)
        );

        uint256 due = wmul(deltaNormalDebt, rate);
        aer.queueDebt(due);

        {
            // Avoid stack too deep
            // This calcuation will overflow if deltaNormalDebt*rate exceeds ~10^14
            uint256 debt = wmul(due, mvault.liquidationPenalty);
            globalDebtOnAuction = add(globalDebtOnAuction, debt);
            vaults[vault].debtOnAuction = add(mvault.debtOnAuction, debt);

            auctionId = ICollateralAuction(mvault.collateralAuction).startAuction({
                debt: debt,
                collateralToSell: deltaCollateral,
                vault: vault,
                tokenId: tokenId,
                user: position,
                keeper: keeper
            });
        }

        emit Liquidate(
            vault,
            tokenId,
            position,
            deltaCollateral,
            deltaNormalDebt,
            due,
            mvault.collateralAuction,
            auctionId
        );
    }

    /// @notice Marks the liquidated Position's debt as sold
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the liquidated Position's Vault
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20) of the liquidated Position
    /// @param debt Amount of debt sold
    function liquidated(
        address vault,
        uint256 tokenId,
        uint256 debt
    ) external override checkCaller {
        globalDebtOnAuction = sub(globalDebtOnAuction, debt);
        vaults[vault].debtOnAuction = sub(vaults[vault].debtOnAuction, debt);
        emit Liquidated(vault, tokenId, debt);
    }

    /// ======== Shutdown ======== ///

    /// @notice Locks the contract
    /// @dev Sender has to be allowed to call this method
    function lock() external override checkCaller {
        live = 0;
        emit Lock();
    }
}

////// lib/fiat/src/interfaces/IMoneta.sol
/* pragma solidity ^0.8.4; */

/* import {ICodex} from "./ICodex.sol"; */
/* import {IFIAT} from "./IFIAT.sol"; */

interface IMoneta {
    function codex() external view returns (ICodex);

    function fiat() external view returns (IFIAT);

    function live() external view returns (uint256);

    function lock() external;

    function enter(address user, uint256 amount) external;

    function exit(address user, uint256 amount) external;
}

////// lib/fiat/src/Moneta.sol
// Copyright (C) 2018 Rain <[email protected]>
/* pragma solidity ^0.8.4; */

/* import {ICodex} from "./interfaces/ICodex.sol"; */
/* import {IFIAT} from "./interfaces/IFIAT.sol"; */
/* import {IMoneta} from "./interfaces/IMoneta.sol"; */

/* import {Guarded} from "./utils/Guarded.sol"; */
/* import {WAD, wmul} from "./utils/Math.sol"; */

/// @title Moneta (FIAT Mint)
/// @notice The canonical mint for FIAT (Fixed Income Asset Token),
/// where users can redeem their internal credit for FIAT
contract Moneta is Guarded, IMoneta {
    /// ======== Custom Errors ======== ///

    error Moneta__exit_notLive();

    /// ======== Storage ======== ///

    /// @notice Codex
    ICodex public immutable override codex;
    /// @notice FIAT (Fixed Income Asset Token)
    IFIAT public immutable override fiat;

    /// @notice Boolean indicating if this contract is live (0 - not live, 1 - live)
    uint256 public override live;

    /// ======== Events ======== ///

    event Enter(address indexed user, uint256 amount);
    event Exit(address indexed user, uint256 amount);
    event Lock();

    constructor(address codex_, address fiat_) Guarded() {
        live = 1;
        codex = ICodex(codex_);
        fiat = IFIAT(fiat_);
    }

    /// ======== Redemption ======== ///

    /// @notice Redeems FIAT for internal credit
    /// @dev User has to set allowance for Moneta to burn FIAT
    /// @param user Address of the user
    /// @param amount Amount of FIAT to be redeemed for internal credit
    function enter(address user, uint256 amount) external override {
        codex.transferCredit(address(this), user, amount);
        fiat.burn(msg.sender, amount);
        emit Enter(user, amount);
    }

    /// @notice Redeems internal credit for FIAT
    /// @dev User has to grant the delegate of transferring credit to Moneta
    /// @param user Address of the user
    /// @param amount Amount of credit to be redeemed for FIAT
    function exit(address user, uint256 amount) external override {
        if (live == 0) revert Moneta__exit_notLive();
        codex.transferCredit(msg.sender, address(this), amount);
        fiat.mint(user, amount);
        emit Exit(user, amount);
    }

    /// ======== Shutdown ======== ///

    /// @notice Locks the contract
    /// @dev Sender has to be allowed to call this method
    function lock() external override checkCaller {
        live = 0;
        emit Lock();
    }
}

////// lib/fiat/src/interfaces/IPublican.sol
/* pragma solidity ^0.8.4; */

/* import {ICodex} from "./ICodex.sol"; */
/* import {IAer} from "./IAer.sol"; */

interface IPublican {
    function vaults(address vault) external view returns (uint256, uint256);

    function codex() external view returns (ICodex);

    function aer() external view returns (IAer);

    function baseInterest() external view returns (uint256);

    function init(address vault) external;

    function setParam(
        address vault,
        bytes32 param,
        uint256 data
    ) external;

    function setParam(bytes32 param, uint256 data) external;

    function setParam(bytes32 param, address data) external;

    function collect(address vault) external returns (uint256 rate);
}

////// lib/fiat/src/Publican.sol
// Copyright (C) 2018 Rain <[email protected]>
/* pragma solidity ^0.8.4; */

/* import {IAer} from "./interfaces/IAer.sol"; */
/* import {ICodex} from "./interfaces/ICodex.sol"; */
/* import {IPublican} from "./interfaces/IPublican.sol"; */

/* import {Guarded} from "./utils/Guarded.sol"; */
/* import {WAD, diff, add, sub, wmul, wpow} from "./utils/Math.sol"; */

/// @title Publican
/// @notice `Publican` is responsible for setting the debt interest rate and collecting interest
/// Uses Jug.sol from DSS (MakerDAO) / TaxCollector.sol from GEB (Reflexer Labs) as a blueprint
/// Changes from Jug.sol / TaxCollector.sol:
/// - only WAD precision is used (no RAD and RAY)
/// - uses a method signature based authentication scheme
/// - configuration by Vaults
contract Publican is Guarded, IPublican {
    /// ======== Custom Errors ======== ///

    error Publican__init_vaultAlreadyInit();
    error Publican__setParam_notCollected();
    error Publican__setParam_unrecognizedParam();
    error Publican__collect_invalidBlockTimestamp();

    /// ======== Storage ======== ///

    // Vault specific configuration data
    struct VaultConfig {
        // Collateral-specific, per-second stability fee contribution [wad]
        uint256 interestPerSecond;
        // Time of last drip [unix epoch time]
        uint256 lastCollected;
    }

    /// @notice Vault Configs
    /// @dev Vault => Vault Config
    mapping(address => VaultConfig) public override vaults;

    /// @notice Codex
    ICodex public immutable override codex;
    /// @notice Aer
    IAer public override aer;

    /// @notice Global, per-second stability fee contribution [wad]
    uint256 public override baseInterest;

    /// ======== Events ======== ///
    event Init(address indexed vault);
    event SetParam(address indexed vault, bytes32 indexed param, uint256 data);
    event SetParam(bytes32 indexed param, address indexed data);
    event Collect(address indexed vault);

    constructor(address codex_) Guarded() {
        codex = ICodex(codex_);
    }

    /// ======== Configuration ======== ///

    /// @notice Initializes a new Vault
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the Vault
    function init(address vault) external override checkCaller {
        VaultConfig storage v = vaults[vault];
        if (v.interestPerSecond != 0) revert Publican__init_vaultAlreadyInit();
        v.interestPerSecond = WAD;
        v.lastCollected = block.timestamp;
        emit Init(vault);
    }

    /// @notice Sets various variables for a Vault
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the Vault
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [wad]
    function setParam(
        address vault,
        bytes32 param,
        uint256 data
    ) external override checkCaller {
        if (block.timestamp != vaults[vault].lastCollected) revert Publican__setParam_notCollected();
        if (param == "interestPerSecond") vaults[vault].interestPerSecond = data;
        else revert Publican__setParam_unrecognizedParam();
        emit SetParam(vault, param, data);
    }

    /// @notice Sets various variables for this contract
    /// @dev Sender has to be allowed to call this method
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [wad]
    function setParam(bytes32 param, uint256 data) external override checkCaller {
        if (param == "baseInterest") baseInterest = data;
        else revert Publican__setParam_unrecognizedParam();
        emit SetParam(address(0), param, data);
    }

    /// @notice Sets various variables for this contract
    /// @dev Sender has to be allowed to call this method
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [address]
    function setParam(bytes32 param, address data) external override checkCaller {
        if (param == "aer") aer = IAer(data);
        else revert Publican__setParam_unrecognizedParam();
        emit SetParam(param, data);
    }

    /// ======== Interest Rates ======== ///

    /// @notice Collects accrued interest from all Position on a Vault by updating the Vault's rate
    /// @param vault Address of the Vault
    /// @return rate Set rate
    function collect(address vault) public override returns (uint256 rate) {
        if (block.timestamp < vaults[vault].lastCollected) revert Publican__collect_invalidBlockTimestamp();
        (, uint256 prev, , ) = codex.vaults(vault);
        rate = wmul(
            wpow(
                add(baseInterest, vaults[vault].interestPerSecond),
                sub(block.timestamp, vaults[vault].lastCollected),
                WAD
            ),
            prev
        );
        codex.modifyRate(vault, address(aer), diff(rate, prev));
        vaults[vault].lastCollected = block.timestamp;
        emit Collect(vault);
    }

    /// @notice Batches interest collection. See `collect(address vault)`.
    /// @param vaults_ Array of Vault addresses
    /// @return rates Set rates for each updated Vault
    function collectMany(address[] memory vaults_) external returns (uint256[] memory) {
        uint256[] memory rates = new uint256[](vaults_.length);
        for (uint256 i = 0; i < vaults_.length; i++) {
            rates[i] = collect(vaults_[i]);
        }
        return rates;
    }
}

////// lib/fiat/src/interfaces/ITenebrae.sol
/* pragma solidity ^0.8.4; */

/* import {ICodex} from "./ICodex.sol"; */
/* import {ICollateralAuction} from "./ICollateralAuction.sol"; */
/* import {ICollybus} from "./ICollybus.sol"; */
/* import {IAer} from "./IAer.sol"; */
/* import {ILimes} from "./ILimes.sol"; */
/* import {ITenebrae} from "./ITenebrae.sol"; */

interface ITenebrae {
    function codex() external view returns (ICodex);

    function limes() external view returns (ILimes);

    function aer() external view returns (IAer);

    function collybus() external view returns (ICollybus);

    function live() external view returns (uint256);

    function lockedAt() external view returns (uint256);

    function cooldownDuration() external view returns (uint256);

    function debt() external view returns (uint256);

    function lostCollateral(address, uint256) external view returns (uint256);

    function normalDebtByTokenId(address, uint256) external view returns (uint256);

    function claimed(
        address,
        uint256,
        address
    ) external view returns (uint256);

    function setParam(bytes32 param, address data) external;

    function setParam(bytes32 param, uint256 data) external;

    function lockPrice(address vault, uint256 tokenId) external view returns (uint256);

    function redemptionPrice(address vault, uint256 tokenId) external view returns (uint256);

    function lock() external;

    function skipAuction(address vault, uint256 auctionId) external;

    function offsetPosition(
        address vault,
        uint256 tokenId,
        address user
    ) external;

    function closePosition(address vault, uint256 tokenId) external;

    function fixGlobalDebt() external;

    function redeem(
        address vault,
        uint256 tokenId,
        uint256 credit
    ) external;
}

////// lib/fiat/src/Tenebrae.sol
// Copyright (C) 2018 Rain <[email protected]>
// Copyright (C) 2018 Lev Livnev <[email protected]>
// Copyright (C) 2020-2021 Maker Ecosystem Growth Holdings, INC.
/* pragma solidity ^0.8.4; */

/* import {ICodex} from "./interfaces/ICodex.sol"; */
/* import {ICollateralAuction} from "./interfaces/ICollateralAuction.sol"; */
/* import {ICollybus} from "./interfaces/ICollybus.sol"; */
/* import {IAer} from "./interfaces/IAer.sol"; */
/* import {ILimes} from "./interfaces/ILimes.sol"; */
/* import {ITenebrae} from "./interfaces/ITenebrae.sol"; */
/* import {IVault} from "./interfaces/IVault.sol"; */

/* import {Guarded} from "./utils/Guarded.sol"; */
/* import {WAD, min, add, sub, wmul, wdiv} from "./utils/Math.sol"; */

/// @title Tenebrae
/// @notice `Tenebrae` coordinates Global Settlement. This is an involved, stateful process that takes
/// place over nine steps.
///
/// Uses End.sol from DSS (MakerDAO) / GlobalSettlement SafeEngine.sol from GEB (Reflexer Labs) as a blueprint
/// Changes from End.sol / GlobalSettlement.sol:
/// - only WAD precision is used (no RAD and RAY)
/// - uses a method signature based authentication scheme
/// - supports ERC1155, ERC721 style assets by TokenId
///
/// @dev
/// First we freeze the system and lock the prices for each vault and TokenId.
///
/// 1. `lock()`:
///     - freezes user entrypoints
///     - cancels debtAuction/surplusAuction auctions
///     - starts cooldown period
///
/// We must process some system state before it is possible to calculate
/// the final credit / collateral price. In particular, we need to determine
///
///     a. `debt`, the outstanding credit supply after including system surplus / deficit
///
///     b. `lostCollateral`, the collateral shortfall per collateral type by
///     considering under-collateralised Positions.
///
/// We determine (a) by processing ongoing credit generating processes,
/// i.e. auctions. We need to ensure that auctions will not generate any
/// further credit income.
///
/// In the case of the Dutch Auctions model (CollateralAuction) they keep recovering
/// debt during the whole lifetime and there isn't a max duration time
/// guaranteed for the auction to end.
/// So the way to ensure the protocol will not receive extra credit income is:
///
///     2a. i) `skipAuctions`: cancel all ongoing auctions and seize the collateral.
///
///         `skipAuctions(vault, id)`:
///          - cancel individual running collateralAuction auctions
///          - retrieves remaining collateral and debt (including penalty) to owner's Position
///
/// We determine (b) by processing all under-collateralised Positions with `offsetPosition`:
///
/// 3. `offsetPosition(vault, tokenId, position)`:
///     - cancels the Position's debt with an equal amount of collateral
///
/// When a Position has been processed and has no debt remaining, the
/// remaining collateral can be removed.
///
/// 4. `closePosition(vault)`:
///     - remove collateral from the caller's Position
///     - owner can call as needed
///
/// After the processing period has elapsed, we enable calculation of
/// the final price for each collateral type.
///
/// 5. `fixGlobalDebt()`:
///     - only callable after processing time period elapsed
///     - assumption that all under-collateralised Positions are processed
///     - fixes the total outstanding supply of credit
///     - may also require extra Position processing to cover aer surplus
///
/// At this point we have computed the final price for each collateral
/// type and credit holders can now turn their credit into collateral. Each
/// unit credit can claim a fixed basket of collateral.
///
/// Finally, collateral can be obtained with `redeem`.
///
/// 6. `redeem(vault, tokenId wad)`:
///     - exchange some credit for collateral tokens from a specific vault and tokenId
contract Tenebrae is Guarded, ITenebrae {
    /// ======== Custom Errors ======== ///

    error Tenebrae__setParam_notLive();
    error Tenebrae__setParam_unknownParam();
    error Tenebrae__lock_notLive();
    error Tenebrae__skipAuction_debtNotZero();
    error Tenebrae__skipAuction_overflow();
    error Tenebrae__offsetPosition_debtNotZero();
    error Tenebrae__offsetPosition_overflow();
    error Tenebrae__closePosition_stillLive();
    error Tenebrae__closePosition_debtNotZero();
    error Tenebrae__closePosition_normalDebtNotZero();
    error Tenebrae__closePosition_overflow();
    error Tenebrae__fixGlobalDebt_stillLive();
    error Tenebrae__fixGlobalDebt_debtNotZero();
    error Tenebrae__fixGlobalDebt_surplusNotZero();
    error Tenebrae__fixGlobalDebt_cooldownNotFinished();
    error Tenebrae__redeem_redemptionPriceZero();

    /// ======== Storage ======== ///

    /// @notice Codex
    ICodex public override codex;
    /// @notice Limes
    ILimes public override limes;
    /// @notice Aer
    IAer public override aer;
    /// @notice Collybus
    ICollybus public override collybus;

    /// @notice Time of lock [unix epoch time]
    uint256 public override lockedAt;
    /// @notice  // Processing Cooldown Length [seconds]
    uint256 public override cooldownDuration;
    /// @notice Total outstanding credit after processing all positions and auctions [wad]
    uint256 public override debt;

    /// @notice Boolean indicating if this contract is live (0 - not live, 1 - live)
    uint256 public override live;

    /// @notice Total collateral shortfall for each asset
    /// @dev Vault => TokenId => Collateral shortfall [wad]
    mapping(address => mapping(uint256 => uint256)) public override lostCollateral;
    /// @notice Total normalized debt for each asset
    /// @dev Vault => TokenId => Total debt per vault [wad]
    mapping(address => mapping(uint256 => uint256)) public override normalDebtByTokenId;
    /// @notice Amount of collateral claimed by users
    /// @dev Vault => TokenId => Account => Collateral claimed [wad]
    mapping(address => mapping(uint256 => mapping(address => uint256))) public override claimed;

    /// ======== Events ======== ///

    event SetParam(bytes32 indexed param, uint256 data);
    event SetParam(bytes32 indexed param, address data);

    event Lock();
    event SkipAuction(
        uint256 indexed auctionId,
        address vault,
        uint256 tokenId,
        address indexed user,
        uint256 debt,
        uint256 collateralToSell,
        uint256 normalDebt
    );
    event SettlePosition(
        address indexed vault,
        uint256 indexed tokenId,
        address indexed user,
        uint256 settledCollateral,
        uint256 normalDebt
    );
    event ClosePosition(
        address indexed vault,
        uint256 indexed tokenId,
        address indexed user,
        uint256 collateral,
        uint256 normalDebt
    );
    event FixGlobalDebt();
    event Redeem(address indexed vault, uint256 indexed tokenId, address indexed user, uint256 credit);

    constructor() Guarded() {
        live = 1;
    }

    /// ======== Configuration ======== ///

    /// @notice Sets various variables for this contract
    /// @dev Sender has to be allowed to call this method
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [address]
    function setParam(bytes32 param, address data) external override checkCaller {
        if (live == 0) revert Tenebrae__setParam_notLive();
        if (param == "codex") codex = ICodex(data);
        else if (param == "limes") limes = ILimes(data);
        else if (param == "aer") aer = IAer(data);
        else if (param == "collybus") collybus = ICollybus(data);
        else revert Tenebrae__setParam_unknownParam();
        emit SetParam(param, data);
    }

    /// @notice Sets various variables for this contract
    /// @dev Sender has to be allowed to call this method
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [wad]
    function setParam(bytes32 param, uint256 data) external override checkCaller {
        if (live == 0) revert Tenebrae__setParam_notLive();
        if (param == "cooldownDuration") cooldownDuration = data;
        else revert Tenebrae__setParam_unknownParam();
        emit SetParam(param, data);
    }

    /// ======== Shutdown ======== ///

    /// @notice Returns the price fixed when the system got locked
    /// @dev Fair price remains fixed since no new rates or spot prices are submitted to Collybus
    /// @param vault Address of the Vault
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @return lockPrice [wad]
    function lockPrice(address vault, uint256 tokenId) public view override returns (uint256) {
        return wdiv(collybus.redemptionPrice(), IVault_1(vault).fairPrice(tokenId, false, true));
    }

    /// @notice Returns the price at which credit can be redeemed for collateral
    /// @notice vault Address of the Vault
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @return redemptionPrice [wad]
    function redemptionPrice(address vault, uint256 tokenId) public view override returns (uint256) {
        if (debt == 0) return 0;
        (, uint256 rate, , ) = codex.vaults(vault);
        uint256 collateral = wmul(wmul(normalDebtByTokenId[vault][tokenId], rate), lockPrice(vault, tokenId));
        return wdiv(sub(collateral, lostCollateral[vault][tokenId]), wmul(debt, WAD));
    }

    /// @notice Locks the system. See 1.
    /// @dev Sender has to be allowed to call this method
    function lock() external override checkCaller {
        if (live == 0) revert Tenebrae__lock_notLive();
        live = 0;
        lockedAt = block.timestamp;
        codex.lock();
        limes.lock();
        aer.lock();
        collybus.lock();
        emit Lock();
    }

    /// @notice Skips on-going collateral auction. See 2.
    /// @dev Has to be performed before global debt is fixed
    /// @param vault Address of the Vault
    /// @param auctionId Id of the collateral auction the skip
    function skipAuction(address vault, uint256 auctionId) external override {
        if (debt != 0) revert Tenebrae__skipAuction_debtNotZero();
        (address _collateralAuction, , , ) = limes.vaults(vault);
        ICollateralAuction collateralAuction = ICollateralAuction(_collateralAuction);
        (, uint256 rate, , ) = codex.vaults(vault);
        (, uint256 debt_, uint256 collateralToSell, , uint256 tokenId, address user, , ) = collateralAuction.auctions(
            auctionId
        );
        codex.createUnbackedDebt(address(aer), address(aer), debt_);
        collateralAuction.cancelAuction(auctionId);
        uint256 normalDebt = wdiv(debt_, rate);
        if (!(int256(collateralToSell) >= 0 && int256(normalDebt) >= 0)) revert Tenebrae__skipAuction_overflow();
        codex.confiscateCollateralAndDebt(
            vault,
            tokenId,
            user,
            address(this),
            address(aer),
            int256(collateralToSell),
            int256(normalDebt)
        );
        emit SkipAuction(auctionId, vault, tokenId, user, debt_, collateralToSell, normalDebt);
    }

    /// @notice Offsets the debt of a Position with its collateral. See 3.
    /// @dev Has to be performed before global debt is fixed
    /// @param vault Address of the Vault
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param user Address of the Position's owner
    function offsetPosition(
        address vault,
        uint256 tokenId,
        address user
    ) external override {
        if (debt != 0) revert Tenebrae__offsetPosition_debtNotZero();
        (, uint256 rate, , ) = codex.vaults(vault);
        (uint256 collateral, uint256 normalDebt) = codex.positions(vault, tokenId, user);
        // get price at maturity
        uint256 owedCollateral = wdiv(wmul(normalDebt, rate), IVault_1(vault).fairPrice(tokenId, false, true));
        uint256 offsetCollateral;
        if (owedCollateral > collateral) {
            // owing more collateral than the Position has
            lostCollateral[vault][tokenId] = add(lostCollateral[vault][tokenId], sub(owedCollateral, collateral));
            offsetCollateral = collateral;
        } else {
            offsetCollateral = owedCollateral;
        }
        normalDebtByTokenId[vault][tokenId] = add(normalDebtByTokenId[vault][tokenId], normalDebt);
        if (!(offsetCollateral <= 2**255 && normalDebt <= 2**255)) revert Tenebrae__offsetPosition_overflow();
        codex.confiscateCollateralAndDebt(
            vault,
            tokenId,
            user,
            address(this),
            address(aer),
            -int256(offsetCollateral),
            -int256(normalDebt)
        );
        emit SettlePosition(vault, tokenId, user, offsetCollateral, normalDebt);
    }

    /// @notice Closes a user's position, such that the user can exit part of their collateral. See 4.
    /// @dev Has to be performed before global debt is fixed
    /// @param vault Address of the Vault
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    function closePosition(address vault, uint256 tokenId) external override {
        if (live != 0) revert Tenebrae__closePosition_stillLive();
        if (debt != 0) revert Tenebrae__closePosition_debtNotZero();
        (uint256 collateral, uint256 normalDebt) = codex.positions(vault, tokenId, msg.sender);
        if (normalDebt != 0) revert Tenebrae__closePosition_normalDebtNotZero();
        normalDebtByTokenId[vault][tokenId] = add(normalDebtByTokenId[vault][tokenId], normalDebt);
        if (collateral > 2**255) revert Tenebrae__closePosition_overflow();
        codex.confiscateCollateralAndDebt(vault, tokenId, msg.sender, msg.sender, address(aer), -int256(collateral), 0);
        emit ClosePosition(vault, tokenId, msg.sender, collateral, normalDebt);
    }

    /// @notice Fixes the global debt of the system. See 5.
    /// @dev Can only be called once.
    function fixGlobalDebt() external override {
        if (live != 0) revert Tenebrae__fixGlobalDebt_stillLive();
        if (debt != 0) revert Tenebrae__fixGlobalDebt_debtNotZero();
        if (codex.credit(address(aer)) != 0) revert Tenebrae__fixGlobalDebt_surplusNotZero();
        if (block.timestamp < add(lockedAt, cooldownDuration)) revert Tenebrae__fixGlobalDebt_cooldownNotFinished();
        debt = codex.globalDebt();
        emit FixGlobalDebt();
    }

    /// @notice Gives users the ability to redeem their remaining collateral with credit. See 6.
    /// @dev Has to be performed after global debt is fixed otherwise redemptionPrice is 0
    /// @param vault Address of the Vault
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20)
    /// @param credit Amount of credit to redeem for collateral [wad]
    function redeem(
        address vault,
        uint256 tokenId,
        uint256 credit // credit amount
    ) external override {
        uint256 price = redemptionPrice(vault, tokenId);
        if (price == 0) revert Tenebrae__redeem_redemptionPriceZero();
        codex.transferCredit(msg.sender, address(aer), credit);
        aer.settleDebtWithSurplus(credit);
        codex.transferBalance(vault, tokenId, address(this), msg.sender, wmul(credit, price));
        claimed[vault][tokenId][msg.sender] = add(claimed[vault][tokenId][msg.sender], credit);
        emit Redeem(vault, tokenId, msg.sender, credit);
    }
}

////// lib/fiat/src/auctions/DebtAuction.sol
// Copyright (C) 2018 Rain <[email protected]>
/* pragma solidity ^0.8.4; */

/* import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol"; */

/* import {IAer} from "../interfaces/IAer.sol"; */
/* import {ICodex} from "../interfaces/ICodex.sol"; */
/* import {ICollybus} from "../interfaces/ICollybus.sol"; */
/* import {IDebtAuction} from "../interfaces/IDebtAuction.sol"; */

/* import {Guarded} from "../utils/Guarded.sol"; */
/* import {WAD, min, add48, mul} from "../utils/Math.sol"; */

/// @title DebtAuction
/// @notice
/// Uses Flop.sol from DSS (MakerDAO) as a blueprint
/// Changes from Flop.sol:
/// - only WAD precision is used (no RAD and RAY)
/// - uses a method signature based authentication scheme
/// - supports ERC1155, ERC721 style assets by TokenId
contract DebtAuction is Guarded, IDebtAuction {
    /// ======== Custom Errors ======== ///

    error DebtAuction__setParam_unrecognizedParam();
    error DebtAuction__startAuction_notLive();
    error DebtAuction__startAuction_overflow();
    error DebtAuction__redoAuction_notFinished();
    error DebtAuction__redoAuction_bidAlreadyPlaced();
    error DebtAuction__submitBid_notLive();
    error DebtAuction__submitBid_recipientNotSet();
    error DebtAuction__submitBid_expired();
    error DebtAuction__submitBid_alreadyFinishedAuctionExpiry();
    error DebtAuction__submitBid_notMatchingBid();
    error DebtAuction__submitBid_tokensToSellNotLower();
    error DebtAuction__submitBid_insufficientDecrease();
    error DebtAuction__closeAuction_notLive();
    error DebtAuction__closeAuction_notFinished();
    error DebtAuction__cancelAuction_stillLive();
    error DebtAuction__cancelAuction_recipientNotSet();

    /// ======== Storage ======== ///

    // Auction State
    struct Auction {
        // credit paid [wad]
        uint256 bid;
        // tokens in return for bid [wad]
        uint256 tokensToSell;
        // high bidder
        address recipient;
        // bid expiry time [unix epoch time]
        uint48 bidExpiry;
        // auction expiry time [unix epoch time]
        uint48 auctionExpiry;
    }

    /// @notice State of auctions
    // AuctionId => Auction
    mapping(uint256 => Auction) public override auctions;

    /// @notice Codex
    ICodex public immutable override codex;
    /// @notice Token to sell for debt
    IERC20 public immutable override token;

    /// @notice 5% minimum bid increase
    uint256 public override minBidBump = 1.05e18;
    /// @notice 50% tokensToSell increase for redoAuction
    uint256 public override tokenToSellBump = 1.50e18;
    /// @notice 3 hours bid lifetime [seconds]
    uint48 public override bidDuration = 3 hours;
    /// @notice 2 days total auction length [seconds]
    uint48 public override auctionDuration = 2 days;
    /// @notice Auction Counter
    uint256 public override auctionCounter = 0;

    /// @notice Boolean indicating if this contract is live (0 - not live, 1 - live)
    uint256 public override live;

    /// @notice Aer, not used until shutdown
    address public override aer;

    /// ======== Events ======== ///

    event StartAuction(uint256 id, uint256 tokensToSell, uint256 bid, address indexed recipient);

    constructor(address codex_, address token_) Guarded() {
        codex = ICodex(codex_);
        token = IERC20(token_);
        live = 1;
    }

    /// ======== Configuration ======== ///

    /// @notice Sets various variables for this contract
    /// @dev Sender has to be allowed to call this method
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [wad]
    function setParam(bytes32 param, uint256 data) external override checkCaller {
        if (param == "minBidBump") minBidBump = data;
        else if (param == "tokenToSellBump") tokenToSellBump = data;
        else if (param == "bidDuration") bidDuration = uint48(data);
        else if (param == "auctionDuration") auctionDuration = uint48(data);
        else revert DebtAuction__setParam_unrecognizedParam();
    }

    /// ======== Debt Auction ======== ///

    /// @notice Start a new debt auction
    /// @dev Sender has to be allowed to call this method
    /// @param recipient Initial recipient of the credit
    /// @param tokensToSell Amount of tokens to sell for credit [wad]
    /// @param bid Starting bid (in credit) of the auction [wad]
    /// @return auctionId Id of the started debt auction
    function startAuction(
        address recipient,
        uint256 tokensToSell,
        uint256 bid
    ) external override checkCaller returns (uint256 auctionId) {
        if (live == 0) revert DebtAuction__startAuction_notLive();
        if (auctionCounter >= type(uint256).max) revert DebtAuction__startAuction_overflow();
        unchecked {
            auctionId = ++auctionCounter;
        }

        auctions[auctionId].bid = bid;
        auctions[auctionId].tokensToSell = tokensToSell;
        auctions[auctionId].recipient = recipient;
        auctions[auctionId].auctionExpiry = add48(uint48(block.timestamp), uint48(auctionDuration));

        emit StartAuction(auctionId, tokensToSell, bid, recipient);
    }

    /// @notice Resets an existing debt auction
    /// @dev Auction expiry has to be exceeded and no bids have to be made
    /// @param auctionId Id of the auction to reset
    function redoAuction(uint256 auctionId) external override {
        if (auctions[auctionId].auctionExpiry >= block.timestamp) revert DebtAuction__redoAuction_notFinished();
        if (auctions[auctionId].bidExpiry != 0) revert DebtAuction__redoAuction_bidAlreadyPlaced();
        auctions[auctionId].tokensToSell = mul(tokenToSellBump, auctions[auctionId].tokensToSell) / WAD;
        auctions[auctionId].auctionExpiry = add48(uint48(block.timestamp), auctionDuration);
    }

    /// @notice Bid for the fixed credit amount (`bid`) by accepting a lower amount of `tokensToSell`
    /// @param auctionId Id of the debt auction
    /// @param tokensToSell Amount of tokens to receive (has to be lower than prev. bid)
    /// @param bid Amount of credit to pay for tokens (has to match)
    function submitBid(
        uint256 auctionId,
        uint256 tokensToSell,
        uint256 bid
    ) external override {
        if (live == 0) revert DebtAuction__submitBid_notLive();
        if (auctions[auctionId].recipient == address(0)) revert DebtAuction__submitBid_recipientNotSet();
        if (auctions[auctionId].bidExpiry <= block.timestamp && auctions[auctionId].bidExpiry != 0)
            revert DebtAuction__submitBid_expired();
        if (auctions[auctionId].auctionExpiry <= block.timestamp)
            revert DebtAuction__submitBid_alreadyFinishedAuctionExpiry();

        if (bid != auctions[auctionId].bid) revert DebtAuction__submitBid_notMatchingBid();
        if (tokensToSell >= auctions[auctionId].tokensToSell) revert DebtAuction__submitBid_tokensToSellNotLower();
        if (mul(minBidBump, tokensToSell) > mul(auctions[auctionId].tokensToSell, WAD))
            revert DebtAuction__submitBid_insufficientDecrease();

        if (msg.sender != auctions[auctionId].recipient) {
            codex.transferCredit(msg.sender, auctions[auctionId].recipient, bid);

            // on first submitBid, clear as much debtOnAuction as possible
            if (auctions[auctionId].bidExpiry == 0) {
                uint256 debtOnAuction = IAer(auctions[auctionId].recipient).debtOnAuction();
                IAer(auctions[auctionId].recipient).settleAuctionedDebt(min(bid, debtOnAuction));
            }

            auctions[auctionId].recipient = msg.sender;
        }

        auctions[auctionId].tokensToSell = tokensToSell;
        auctions[auctionId].bidExpiry = add48(uint48(block.timestamp), bidDuration);
    }

    /// @notice Closes a finished auction and transfers tokens to the winning bidders
    /// @param auctionId Id of the debt auction to close
    function closeAuction(uint256 auctionId) external override {
        if (live == 0) revert DebtAuction__closeAuction_notLive();
        if (
            !(auctions[auctionId].bidExpiry != 0 &&
                (auctions[auctionId].bidExpiry < block.timestamp ||
                    auctions[auctionId].auctionExpiry < block.timestamp))
        ) revert DebtAuction__closeAuction_notFinished();
        token.transfer(auctions[auctionId].recipient, auctions[auctionId].tokensToSell);
        delete auctions[auctionId];
    }

    /// ======== Shutdown ======== ///

    /// @notice Locks the contract and sets the address of Aer
    /// @dev Sender has to be allowed to call this method
    function lock() external override checkCaller {
        live = 0;
        aer = msg.sender;
    }

    /// @notice Cancels an existing auction by minting new credit directly to the auctions recipient
    /// @dev Can only be called when the contract is locked
    /// @param auctionId Id of the debt auction to cancel
    function cancelAuction(uint256 auctionId) external override {
        if (live == 1) revert DebtAuction__cancelAuction_stillLive();
        if (auctions[auctionId].recipient == address(0)) revert DebtAuction__cancelAuction_recipientNotSet();
        codex.createUnbackedDebt(aer, auctions[auctionId].recipient, auctions[auctionId].bid);
        delete auctions[auctionId];
    }
}

////// lib/fiat/src/interfaces/INoLossCollateralAuction.sol
/* pragma solidity ^0.8.4; */

/* import {IPriceCalculator} from "./IPriceCalculator.sol"; */
/* import {ICodex} from "./ICodex.sol"; */
/* import {ICollybus} from "./ICollybus.sol"; */
/* import {IAer} from "./IAer.sol"; */
/* import {ILimes} from "./ILimes.sol"; */

interface INoLossCollateralAuction {
    function vaults(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            ICollybus,
            IPriceCalculator
        );

    function codex() external view returns (ICodex);

    function limes() external view returns (ILimes);

    function aer() external view returns (IAer);

    function feeTip() external view returns (uint64);

    function flatTip() external view returns (uint192);

    function auctionCounter() external view returns (uint256);

    function activeAuctions(uint256) external view returns (uint256);

    function auctions(uint256)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            address,
            uint96,
            uint256
        );

    function stopped() external view returns (uint256);

    function init(address vault, address collybus) external;

    function setParam(bytes32 param, uint256 data) external;

    function setParam(bytes32 param, address data) external;

    function setParam(
        address vault,
        bytes32 param,
        uint256 data
    ) external;

    function setParam(
        address vault,
        bytes32 param,
        address data
    ) external;

    function startAuction(
        uint256 debt,
        uint256 collateralToSell,
        address vault,
        uint256 tokenId,
        address user,
        address keeper
    ) external returns (uint256 auctionId);

    function redoAuction(uint256 auctionId, address keeper) external;

    function takeCollateral(
        uint256 auctionId,
        uint256 collateralAmount,
        uint256 maxPrice,
        address recipient,
        bytes calldata data
    ) external;

    function count() external view returns (uint256);

    function list() external view returns (uint256[] memory);

    function getStatus(uint256 auctionId)
        external
        view
        returns (
            bool needsRedo,
            uint256 price,
            uint256 collateralToSell,
            uint256 debt
        );

    function updateAuctionDebtFloor(address vault) external;

    function cancelAuction(uint256 auctionId) external;
}

////// lib/fiat/src/auctions/NoLossCollateralAuction.sol
// Copyright (C) 2020-2021 Maker Ecosystem Growth Holdings, INC.
/* pragma solidity ^0.8.4; */

/* import {IPriceCalculator} from "../interfaces/IPriceCalculator.sol"; */
/* import {ICodex} from "../interfaces/ICodex.sol"; */
/* import {CollateralAuctionCallee} from "../interfaces/ICollateralAuction.sol"; */
/* import {INoLossCollateralAuction} from "../interfaces/INoLossCollateralAuction.sol"; */
/* import {ICollybus} from "../interfaces/ICollybus.sol"; */
/* import {IAer} from "../interfaces/IAer.sol"; */
/* import {ILimes} from "../interfaces/ILimes.sol"; */
/* import {IVault} from "../interfaces/IVault.sol"; */

/* import {Guarded} from "../utils/Guarded.sol"; */
/* import {WAD, max, min, add, sub, mul, wmul, wdiv} from "../utils/Math.sol"; */

/// @title NoLossCollateralAuction
/// @notice Same as CollateralAuction but enforces a floor price of debt / collateral
/// Uses Clip.sol from DSS (MakerDAO) as a blueprint
/// Changes from Clip.sol:
/// - only WAD precision is used (no RAD and RAY)
/// - uses a method signature based authentication scheme
/// - supports ERC1155, ERC721 style assets by TokenId
contract NoLossCollateralAuction is Guarded, INoLossCollateralAuction {
    /// ======== Custom Errors ======== ///

    error NoLossCollateralAuction__init_vaultAlreadyInit();
    error NoLossCollateralAuction__checkReentrancy_reentered();
    error NoLossCollateralAuction__isStopped_stoppedIncorrect();
    error NoLossCollateralAuction__setParam_unrecognizedParam();
    error NoLossCollateralAuction__startAuction_zeroDebt();
    error NoLossCollateralAuction__startAuction_zeroCollateralToSell();
    error NoLossCollateralAuction__startAuction_zeroUser();
    error NoLossCollateralAuction__startAuction_overflow();
    error NoLossCollateralAuction__startAuction_zeroStartPrice();
    error NoLossCollateralAuction__redoAuction_notRunningAuction();
    error NoLossCollateralAuction__redoAuction_cannotReset();
    error NoLossCollateralAuction__redoAuction_zeroStartPrice();
    error NoLossCollateralAuction__takeCollateral_notRunningAuction();
    error NoLossCollateralAuction__takeCollateral_needsReset();
    error NoLossCollateralAuction__takeCollateral_tooExpensive();
    error NoLossCollateralAuction__takeCollateral_noPartialPurchase();
    error NoLossCollateralAuction__cancelAuction_notRunningAction();

    /// ======== Storage ======== ///

    // Vault specific configuration data
    struct VaultConfig {
        // Multiplicative factor to increase start price [wad]
        uint256 multiplier;
        // Time elapsed before auction reset [seconds]
        uint256 maxAuctionDuration;
        // Cache (v.debtFloor * v.liquidationPenalty) to prevent excessive SLOADs [wad]
        uint256 auctionDebtFloor;
        // Collateral price module
        ICollybus collybus;
        // Current price calculator
        IPriceCalculator calculator;
    }

    /// @notice Vault Configs
    /// @dev Vault => Vault Config
    mapping(address => VaultConfig) public override vaults;

    /// @notice Codex
    ICodex public immutable override codex;
    /// @notice Limes
    ILimes public override limes;
    /// @notice Aer (Recipient of credit raised in auctions)
    IAer public override aer;
    /// @notice Percentage of debt to mint from aer to incentivize keepers [wad]
    uint64 public override feeTip;
    /// @notice Flat fee to mint from aer to incentivize keepers [wad]
    uint192 public override flatTip;
    /// @notice Total auctions (includes past auctions)
    uint256 public override auctionCounter;
    /// @notice Array of active auction ids
    uint256[] public override activeAuctions;

    // Auction State
    struct Auction {
        // Index in activeAuctions array
        uint256 index;
        // Debt to sell == Credit to raise [wad]
        uint256 debt;
        // collateral to sell [wad]
        uint256 collateralToSell;
        // Vault of the liquidated Positions collateral
        address vault;
        // TokenId of the liquidated Positions collateral
        uint256 tokenId;
        // Owner of the liquidated Position
        address user;
        // Auction start time
        uint96 startsAt;
        // Starting price [wad]
        uint256 startPrice;
    }
    /// @notice State of auctions
    /// @dev AuctionId => Auction
    mapping(uint256 => Auction) public override auctions;

    // reentrancy guard
    uint256 private entered;

    /// @notice Circuit breaker level
    /// Levels for circuit breaker
    /// 0: no breaker
    /// 1: no new startAuction()
    /// 2: no new startAuction() or redoAuction()
    /// 3: no new startAuction(), redoAuction(), or takeCollateral()
    uint256 public override stopped = 0;

    /// ======== Events ======== ///

    event Init(address vault);

    event SetParam(bytes32 indexed param, uint256 data);
    event SetParam(bytes32 indexed param, address data);

    event StartAuction(
        uint256 indexed auctionId,
        uint256 startPrice,
        uint256 debt,
        uint256 collateralToSell,
        address vault,
        uint256 tokenId,
        address user,
        address indexed keeper,
        uint256 tip
    );
    event TakeCollateral(
        uint256 indexed auctionId,
        uint256 maxPrice,
        uint256 price,
        uint256 owe,
        uint256 debt,
        uint256 collateralToSell,
        address vault,
        uint256 tokenId,
        address indexed user
    );
    event RedoAuction(
        uint256 indexed auctionId,
        uint256 startPrice,
        uint256 debt,
        uint256 collateralToSell,
        address vault,
        uint256 tokenId,
        address user,
        address indexed keeper,
        uint256 tip
    );

    event StopAuction(uint256 auctionId);

    event UpdateAuctionDebtFloor(address indexed vault, uint256 auctionDebtFloor);

    constructor(address codex_, address limes_) Guarded() {
        codex = ICodex(codex_);
        limes = ILimes(limes_);
    }

    modifier checkReentrancy() {
        if (entered == 0) {
            entered = 1;
            _;
            entered = 0;
        } else revert NoLossCollateralAuction__checkReentrancy_reentered();
    }

    modifier isStopped(uint256 level) {
        if (stopped < level) {
            _;
        } else revert NoLossCollateralAuction__isStopped_stoppedIncorrect();
    }

    /// ======== Configuration ======== ///

    /// @notice Initializes a new Vault for which collateral can be auctioned off
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the Vault
    /// @param collybus Address of the Collybus the Vault uses for pricing
    function init(address vault, address collybus) external override checkCaller {
        if (vaults[vault].calculator != IPriceCalculator(address(0)))
            revert NoLossCollateralAuction__init_vaultAlreadyInit();
        vaults[vault].multiplier = WAD;
        vaults[vault].collybus = ICollybus(collybus);

        emit Init(vault);
    }

    /// @notice Sets various variables for this contract
    /// @dev Sender has to be allowed to call this method
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [wad]
    function setParam(bytes32 param, uint256 data) external override checkCaller checkReentrancy {
        if (param == "feeTip")
            feeTip = uint64(data); // Percentage of debt to incentivize (max: 2^64 - 1 => 18.xxx WAD = 18xx%)
        else if (param == "flatTip")
            flatTip = uint192(data); // Flat fee to incentivize keepers (max: 2^192 - 1 => 6.277T WAD)
        else if (param == "stopped")
            stopped = data; // Set breaker (0, 1, 2, or 3)
        else revert NoLossCollateralAuction__setParam_unrecognizedParam();
        emit SetParam(param, data);
    }

    /// @notice Sets various variables for this contract
    /// @dev Sender has to be allowed to call this method
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [address]
    function setParam(bytes32 param, address data) external override checkCaller checkReentrancy {
        if (param == "limes") limes = ILimes(data);
        else if (param == "aer") aer = IAer(data);
        else revert NoLossCollateralAuction__setParam_unrecognizedParam();
        emit SetParam(param, data);
    }

    /// @notice Sets various variables for a Vault
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the Vault
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [wad]
    function setParam(
        address vault,
        bytes32 param,
        uint256 data
    ) external override checkCaller checkReentrancy {
        if (param == "multiplier") vaults[vault].multiplier = data;
        else if (param == "maxAuctionDuration")
            vaults[vault].maxAuctionDuration = data; // Time elapsed before auction reset
        else revert NoLossCollateralAuction__setParam_unrecognizedParam();
        emit SetParam(param, data);
    }

    /// @notice Sets various variables for a Vault
    /// @dev Sender has to be allowed to call this method
    /// @param vault Address of the Vault
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [address]
    function setParam(
        address vault,
        bytes32 param,
        address data
    ) external override checkCaller checkReentrancy {
        if (param == "collybus") vaults[vault].collybus = ICollybus(data);
        else if (param == "calculator") vaults[vault].calculator = IPriceCalculator(data);
        else revert NoLossCollateralAuction__setParam_unrecognizedParam();
        emit SetParam(param, data);
    }

    /// ======== No Loss Collateral Auction ======== ///

    // get price at maturity
    function _getPrice(address vault, uint256 tokenId) internal view returns (uint256) {
        return IVault_1(vault).fairPrice(tokenId, false, true);
    }

    /// @notice Starts a collateral auction
    /// The start price `startPrice` is obtained as follows:
    ///     startPrice = val * multiplier / redemptionPrice
    /// Where `val` is the collateral's unitary value in USD, `multiplier` is a
    /// multiplicative factor to increase the start price, and `redemptionPrice` is a reference per Credit.
    /// @dev Sender has to be allowed to call this method
    /// - trusts the caller to transfer collateral to the contract
    /// - reverts if circuit breaker is set to 1 (no new auctions)
    /// @param debt Amount of debt to sell / credit to buy [wad]
    /// @param collateralToSell Amount of collateral to sell [wad]
    /// @param vault Address of the collaterals Vault
    /// @param tokenId ERC1155 or ERC721 style TokenId (leave at 0 for ERC20) of the collateral
    /// @param user Address that will receive any leftover collateral
    /// @param keeper Address that will receive incentives
    /// @return auctionId Identifier of started auction
    function startAuction(
        uint256 debt,
        uint256 collateralToSell,
        address vault,
        uint256 tokenId,
        address user,
        address keeper
    ) external override checkCaller checkReentrancy isStopped(1) returns (uint256 auctionId) {
        // Input validation
        if (debt == 0) revert NoLossCollateralAuction__startAuction_zeroDebt();
        if (collateralToSell == 0) revert NoLossCollateralAuction__startAuction_zeroCollateralToSell();
        if (user == address(0)) revert NoLossCollateralAuction__startAuction_zeroUser();
        unchecked {
            auctionId = ++auctionCounter;
        }
        if (auctionId == 0) revert NoLossCollateralAuction__startAuction_overflow();

        activeAuctions.push(auctionId);

        auctions[auctionId].index = activeAuctions.length - 1;

        auctions[auctionId].debt = debt;
        auctions[auctionId].collateralToSell = collateralToSell;
        auctions[auctionId].vault = vault;
        auctions[auctionId].tokenId = tokenId;
        auctions[auctionId].user = user;
        auctions[auctionId].startsAt = uint96(block.timestamp);

        uint256 startPrice;
        startPrice = wmul(_getPrice(vault, tokenId), vaults[vault].multiplier);
        if (startPrice <= 0) revert NoLossCollateralAuction__startAuction_zeroStartPrice();
        auctions[auctionId].startPrice = startPrice;

        // incentive to startAuction auction
        uint256 _tip = flatTip;
        uint256 _feeTip = feeTip;
        uint256 tip;
        if (_tip > 0 || _feeTip > 0) {
            tip = add(_tip, wmul(debt, _feeTip));
            codex.createUnbackedDebt(address(aer), keeper, tip);
        }

        emit StartAuction(auctionId, startPrice, debt, collateralToSell, vault, tokenId, user, keeper, tip);
    }

    /// @notice Resets an existing collateral auction
    /// See `startAuction` above for an explanation of the computation of `startPrice`.
    /// multiplicative factor to increase the start price, and `redemptionPrice` is a reference per Credit.
    /// @dev Reverts if circuit breaker is set to 2 (no new auctions and no redos of auctions)
    /// @param auctionId Id of the auction to reset
    /// @param keeper Address that will receive incentives
    function redoAuction(uint256 auctionId, address keeper) external override checkReentrancy isStopped(2) {
        // Read auction data
        Auction memory auction = auctions[auctionId];

        if (auction.user == address(0)) revert NoLossCollateralAuction__redoAuction_notRunningAuction();

        // Check that auction needs reset
        // and compute current price [wad]
        {
            (bool done, ) = status(auction);
            if (!done) revert NoLossCollateralAuction__redoAuction_cannotReset();
        }

        uint256 debt = auctions[auctionId].debt;
        uint256 collateralToSell = auctions[auctionId].collateralToSell;
        auctions[auctionId].startsAt = uint96(block.timestamp);

        uint256 price = _getPrice(auction.vault, auction.tokenId);
        uint256 startPrice = wmul(price, vaults[auction.vault].multiplier);
        if (startPrice <= 0) revert NoLossCollateralAuction__redoAuction_zeroStartPrice();
        auctions[auctionId].startPrice = startPrice;

        // incentive to redoAuction auction
        uint256 tip;
        {
            uint256 _tip = flatTip;
            uint256 _feeTip = feeTip;
            if (_tip > 0 || _feeTip > 0) {
                uint256 _auctionDebtFloor = vaults[auction.vault].auctionDebtFloor;
                if (debt >= _auctionDebtFloor && wmul(collateralToSell, price) >= _auctionDebtFloor) {
                    tip = add(_tip, wmul(debt, _feeTip));
                    codex.createUnbackedDebt(address(aer), keeper, tip);
                }
            }
        }

        emit RedoAuction(
            auctionId,
            startPrice,
            debt,
            collateralToSell,
            auction.vault,
            auction.tokenId,
            auction.user,
            keeper,
            tip
        );
    }

    /// @notice Buy up to `collateralAmount` of collateral from the auction indexed by `id`
    ///
    /// Auctions will not collect more Credit than their assigned Credit target,`debt`;
    /// thus, if `collateralAmount` would cost more Credit than `debt` at the current price, the
    /// amount of collateral purchased will instead be just enough to collect `debt` in Credit.
    ///
    /// To avoid partial purchases resulting in very small leftover auctions that will
    /// never be cleared, any partial purchase must leave at least `CollateralAuction.auctionDebtFloor`
    /// remaining Credit target. `auctionDebtFloor` is an asynchronously updated value equal to
    /// (Codex.debtFloor * Limes.liquidationPenalty(vault) / WAD) where the values are understood to be determined
    /// by whatever they were when CollateralAuction.updateAuctionDebtFloor() was last called. Purchase amounts
    /// will be minimally decreased when necessary to respect this limit; i.e., if the
    /// specified `collateralAmount` would leave `debt < auctionDebtFloor` but `debt > 0`, the amount actually
    /// purchased will be such that `debt == auctionDebtFloor`.
    ///
    /// If `debt <= auctionDebtFloor`, partial purchases are no longer possible; that is, the remaining
    /// collateral can only be purchased entirely, or not at all.
    ///
    /// Enforces a price floor of debt / collateral
    ///
    /// @dev Reverts if circuit breaker is set to 3 (no new auctions, no redos of auctions and no collateral buying)
    /// @param auctionId Id of the auction to buy collateral from
    /// @param collateralAmount Upper limit on amount of collateral to buy [wad]
    /// @param maxPrice Maximum acceptable price (Credit / collateral) [wad]
    /// @param recipient Receiver of collateral and external call address
    /// @param data Data to pass in external call; if length 0, no call is done
    function takeCollateral(
        uint256 auctionId, // Auction id
        uint256 collateralAmount, // Upper limit on amount of collateral to buy [wad]
        uint256 maxPrice, // Maximum acceptable price (Credit / collateral) [wad]
        address recipient, // Receiver of collateral and external call address
        bytes calldata data // Data to pass in external call; if length 0, no call is done
    ) external override checkReentrancy isStopped(3) {
        Auction memory auction = auctions[auctionId];

        if (auction.user == address(0)) revert NoLossCollateralAuction__takeCollateral_notRunningAuction();

        uint256 price;
        {
            bool done;
            (done, price) = status(auction);

            // Check that auction doesn't need reset
            if (done) revert NoLossCollateralAuction__takeCollateral_needsReset();
            // Ensure price is acceptable to buyer
            if (maxPrice < price) revert NoLossCollateralAuction__takeCollateral_tooExpensive();
        }

        uint256 collateralToSell = auction.collateralToSell;
        uint256 debt = auction.debt;
        uint256 owe;

        unchecked {
            {
                // Purchase as much as possible, up to collateralAmount
                // collateralSlice <= collateralToSell
                uint256 collateralSlice = min(collateralToSell, collateralAmount);

                // Credit needed to buy a collateralSlice of this auction
                owe = wmul(collateralSlice, price);

                // owe can be greater than debt and thus user would pay a premium to the recipient

                if (owe < debt && collateralSlice < collateralToSell) {
                    // If collateralSlice == collateralToSell => auction completed => debtFloor doesn't matter
                    uint256 _auctionDebtFloor = vaults[auction.vault].auctionDebtFloor;
                    if (debt - owe < _auctionDebtFloor) {
                        // safe as owe < debt
                        // If debt <= auctionDebtFloor, buyers have to take the entire collateralToSell.
                        if (debt <= _auctionDebtFloor)
                            revert NoLossCollateralAuction__takeCollateral_noPartialPurchase();
                        // Adjust amount to pay
                        owe = debt - _auctionDebtFloor; // owe' <= owe
                        // Adjust collateralSlice
                        // collateralSlice' = owe' / price < owe / price == collateralSlice < collateralToSell
                        collateralSlice = wdiv(owe, price);
                    }
                }

                // Calculate remaining collateralToSell after operation
                collateralToSell = collateralToSell - collateralSlice;

                // Send collateral to recipient
                codex.transferBalance(auction.vault, auction.tokenId, address(this), recipient, collateralSlice);

                // Do external call (if data is defined) but to be
                // extremely careful we don't allow to do it to the two
                // contracts which the CollateralAuction needs to be authorized
                ILimes limes_ = limes;
                if (data.length > 0 && recipient != address(codex) && recipient != address(limes_)) {
                    CollateralAuctionCallee(recipient).collateralAuctionCall(msg.sender, owe, collateralSlice, data);
                }

                // Get Credit from caller
                codex.transferCredit(msg.sender, address(aer), owe);

                // Removes Credit out for liquidation from accumulator
                // if all collateral has been sold or owe is larger than remaining debt
                //  then just remove the remaining debt from the accumulator
                limes_.liquidated(auction.vault, auction.tokenId, (collateralToSell == 0 || debt < owe) ? debt : owe);

                // Calculate remaining debt after operation
                debt = (owe < debt) ? debt - owe : 0; // safe since owe <= debt
            }
        }

        if (collateralToSell == 0) {
            _remove(auctionId);
        } else if (debt == 0) {
            codex.transferBalance(auction.vault, auction.tokenId, address(this), auction.user, collateralToSell);
            _remove(auctionId);
        } else {
            auctions[auctionId].debt = debt;
            auctions[auctionId].collateralToSell = collateralToSell;
        }

        emit TakeCollateral(
            auctionId,
            maxPrice,
            price,
            owe,
            debt,
            collateralToSell,
            auction.vault,
            auction.tokenId,
            auction.user
        );
    }

    // Removes an auction from the active auctions array
    function _remove(uint256 auctionId) internal {
        uint256 _move = activeAuctions[activeAuctions.length - 1];
        if (auctionId != _move) {
            uint256 _index = auctions[auctionId].index;
            activeAuctions[_index] = _move;
            auctions[_move].index = _index;
        }
        activeAuctions.pop();
        delete auctions[auctionId];
    }

    /// @notice The number of active auctions
    /// @return Number of active auctions
    function count() external view override returns (uint256) {
        return activeAuctions.length;
    }

    /// @notice Returns the entire array of active auctions
    /// @return List of active auctions
    function list() external view override returns (uint256[] memory) {
        return activeAuctions;
    }

    /// @notice Externally returns boolean for if an auction needs a redo and also the current price
    /// @param auctionId Id of the auction to get the status for
    /// @return needsRedo If the auction needs a redo (max duration or max discount exceeded)
    /// @return price Current price of the collateral determined by the calculator [wad]
    /// @return collateralToSell Amount of collateral left to buy for credit [wad]
    /// @return debt Amount of debt / credit to sell for collateral [wad]
    function getStatus(uint256 auctionId)
        external
        view
        override
        returns (
            bool needsRedo,
            uint256 price,
            uint256 collateralToSell,
            uint256 debt
        )
    {
        Auction memory auction = auctions[auctionId];

        bool done;
        (done, price) = status(auction);

        needsRedo = auction.user != address(0) && done;
        collateralToSell = auction.collateralToSell;
        debt = auction.debt;
    }

    // Internally returns boolean for if an auction needs a redo
    function status(Auction memory auction) internal view returns (bool done, uint256 price) {
        uint256 floorPrice = wdiv(auction.debt, auction.collateralToSell);
        price = max(
            floorPrice,
            vaults[auction.vault].calculator.price(auction.startPrice, sub(block.timestamp, auction.startsAt))
        );
        done = (sub(block.timestamp, auction.startsAt) > vaults[auction.vault].maxAuctionDuration ||
            price == floorPrice);
    }

    /// @notice Public function to update the cached vault.debtFloor*vault.liquidationPenalty value
    /// @param vault Address of the Vault for which to update the auctionDebtFloor variable
    function updateAuctionDebtFloor(address vault) external override {
        (, , , uint256 _debtFloor) = ICodex(codex).vaults(vault);
        uint256 auctionDebtFloor = wmul(_debtFloor, limes.liquidationPenalty(vault));
        vaults[vault].auctionDebtFloor = auctionDebtFloor;
        emit UpdateAuctionDebtFloor(vault, auctionDebtFloor);
    }

    /// ======== Shutdown ======== ///

    /// @notice Cancels an auction during shutdown or via governance action
    /// @dev Sender has to be allowed to call this method
    /// @param auctionId Id of the auction to cancel
    function cancelAuction(uint256 auctionId) external override checkCaller checkReentrancy {
        if (auctions[auctionId].user == address(0)) revert NoLossCollateralAuction__cancelAuction_notRunningAction();
        address vault = auctions[auctionId].vault;
        uint256 tokenId = auctions[auctionId].tokenId;
        limes.liquidated(vault, tokenId, auctions[auctionId].debt);
        codex.transferBalance(vault, tokenId, address(this), msg.sender, auctions[auctionId].collateralToSell);
        _remove(auctionId);
        emit StopAuction(auctionId);
    }
}

////// lib/fiat/src/auctions/SurplusAuction.sol
// Copyright (C) 2018 Rain <[email protected]>
/* pragma solidity ^0.8.4; */

/* import {IERC20} from "openzeppelin/contracts/token/ERC20/IERC20.sol"; */

/* import {ICodex} from "../interfaces/ICodex.sol"; */
/* import {ISurplusAuction} from "../interfaces/ISurplusAuction.sol"; */

/* import {Guarded} from "../utils/Guarded.sol"; */
/* import {WAD, add48, sub, mul} from "../utils/Math.sol"; */

/// @title SurplusAuction
/// @notice
/// Uses Flap.sol from DSS (MakerDAO) as a blueprint
/// Changes from Flap.sol:
/// - only WAD precision is used (no RAD and RAY)
/// - uses a method signature based authentication scheme
/// - supports ERC1155, ERC721 style assets by TokenId
contract SurplusAuction is Guarded, ISurplusAuction {
    /// ======== Custom Errors ======== ///

    error SurplusAuction__setParam_unrecognizedParam();
    error SurplusAuction__startAuction_notLive();
    error SurplusAuction__startAuction_overflow();
    error SurplusAuction__redoAuction_notFinished();
    error SurplusAuction__redoAuction_bidAlreadyPlaced();
    error SurplusAuction__submitBid_notLive();
    error SurplusAuction__submit_recipientNotSet();
    error SurplusAuction__submitBid_alreadyFinishedBidExpiry();
    error SurplusAuction__submitBid_alreadyFinishedAuctionExpiry();
    error SurplusAuction__submitBid_creditToSellNotMatching();
    error SurplusAuction__submitBid_bidNotHigher();
    error SurplusAuction__submitBid_insufficientIncrease();
    error SurplusAuction__closeAuction_notLive();
    error SurplusAuction__closeAuction_notFinished();
    error SurplusAuction__cancelAuction_stillLive();
    error SurplusAuction__cancelAuction_recipientNotSet();

    /// ======== Storage ======== ///

    // Auction State
    struct Auction {
        // tokens paid for credit [wad]
        uint256 bid;
        // amount of credit to sell for tokens (bid) [wad]
        uint256 creditToSell;
        // current highest bidder
        address recipient;
        // bid expiry time [unix epoch time]
        uint48 bidExpiry;
        // auction expiry time [unix epoch time]
        uint48 auctionExpiry;
    }

    /// @notice State of auctions
    // AuctionId => Auction
    mapping(uint256 => Auction) public override auctions;

    /// @notice Codex
    ICodex public immutable override codex;
    /// @notice Tokens to receive for credit
    IERC20 public immutable override token;

    /// @notice 5% minimum bid increase
    uint256 public override minBidBump = 1.05e18;
    /// @notice 3 hours bid duration [seconds]
    uint48 public override bidDuration = 3 hours;
    /// @notice 2 days total auction length [seconds]
    uint48 public override auctionDuration = 2 days;
    /// @notice Auction Counter
    uint256 public override auctionCounter = 0;

    /// @notice Boolean indicating if this contract is live (0 - not live, 1 - live)
    uint256 public override live;

    /// ======== Events ======== ///

    event StartAuction(uint256 id, uint256 creditToSell, uint256 bid);

    constructor(address codex_, address token_) Guarded() {
        codex = ICodex(codex_);
        token = IERC20(token_);
        live = 1;
    }

    /// @notice Sets various variables for this contract
    /// @dev Sender has to be allowed to call this method
    /// @param param Name of the variable to set
    /// @param data New value to set for the variable [wad]
    function setParam(bytes32 param, uint256 data) external override checkCaller {
        if (param == "minBidBump") minBidBump = data;
        else if (param == "bidDuration") bidDuration = uint48(data);
        else if (param == "auctionDuration") auctionDuration = uint48(data);
        else revert SurplusAuction__setParam_unrecognizedParam();
    }

    /// ======== Surplus Auction ======== ///

    /// @notice Start a new surplus auction
    /// @dev Sender has to be allowed to call this method
    /// @param creditToSell Amount of credit to sell for tokens [wad]
    /// @param bid Starting bid (in tokens) of the auction [wad]
    /// @return auctionId Id of the started surplus auction
    function startAuction(uint256 creditToSell, uint256 bid) external override checkCaller returns (uint256 auctionId) {
        if (live == 0) revert SurplusAuction__startAuction_notLive();
        if (auctionCounter >= ~uint256(0)) revert SurplusAuction__startAuction_overflow();
        unchecked {
            auctionId = ++auctionCounter;
        }

        auctions[auctionId].bid = bid;
        auctions[auctionId].creditToSell = creditToSell;
        auctions[auctionId].recipient = msg.sender; // configurable??
        auctions[auctionId].auctionExpiry = add48(uint48(block.timestamp), auctionDuration);

        codex.transferCredit(msg.sender, address(this), creditToSell);

        emit StartAuction(auctionId, creditToSell, bid);
    }

    /// @notice Resets an existing surplus auction
    /// @dev Auction expiry has to be exceeded and no bids have to be made
    /// @param auctionId Id of the auction to reset
    function redoAuction(uint256 auctionId) external override {
        if (auctions[auctionId].auctionExpiry >= block.timestamp) revert SurplusAuction__redoAuction_notFinished();
        if (auctions[auctionId].bidExpiry != 0) revert SurplusAuction__redoAuction_bidAlreadyPlaced();
        auctions[auctionId].auctionExpiry = add48(uint48(block.timestamp), auctionDuration);
    }

    /// @notice Bid for the fixed credit amount (`creditToSell`) with a higher amount of tokens (`bid`)
    /// @param auctionId Id of the debt auction
    /// @param creditToSell Amount of credit to receive (has to match)
    /// @param bid Amount of tokens to pay for credit (has to be higher than prev. bid)
    function submitBid(
        uint256 auctionId,
        uint256 creditToSell,
        uint256 bid
    ) external override {
        if (live == 0) revert SurplusAuction__submitBid_notLive();
        if (auctions[auctionId].recipient == address(0)) revert SurplusAuction__submit_recipientNotSet();
        if (auctions[auctionId].bidExpiry <= block.timestamp && auctions[auctionId].bidExpiry != 0)
            revert SurplusAuction__submitBid_alreadyFinishedBidExpiry();
        if (auctions[auctionId].auctionExpiry <= block.timestamp)
            revert SurplusAuction__submitBid_alreadyFinishedAuctionExpiry();

        if (creditToSell != auctions[auctionId].creditToSell)
            revert SurplusAuction__submitBid_creditToSellNotMatching();
        if (bid <= auctions[auctionId].bid) revert SurplusAuction__submitBid_bidNotHigher();
        if (mul(bid, WAD) < mul(minBidBump, auctions[auctionId].bid))
            revert SurplusAuction__submitBid_insufficientIncrease();

        if (msg.sender != auctions[auctionId].recipient) {
            token.transferFrom(msg.sender, auctions[auctionId].recipient, auctions[auctionId].bid);
            auctions[auctionId].recipient = msg.sender;
        }
        token.transferFrom(msg.sender, address(this), sub(bid, auctions[auctionId].bid));

        auctions[auctionId].bid = bid;
        auctions[auctionId].bidExpiry = add48(uint48(block.timestamp), bidDuration);
    }

    /// @notice Closes a finished auction and mints new tokens to the winning bidders
    /// @param auctionId Id of the debt auction to close
    function closeAuction(uint256 auctionId) external override {
        if (live == 0) revert SurplusAuction__closeAuction_notLive();
        if (
            !(auctions[auctionId].bidExpiry != 0 &&
                (auctions[auctionId].bidExpiry < block.timestamp ||
                    auctions[auctionId].auctionExpiry < block.timestamp))
        ) revert SurplusAuction__closeAuction_notFinished();
        codex.transferCredit(address(this), auctions[auctionId].recipient, auctions[auctionId].creditToSell);
        token.transfer(address(0), auctions[auctionId].bid);
        delete auctions[auctionId];
    }

    /// ======== Shutdown ======== ///

    /// @notice Locks the contract and transfer the credit in this contract to the caller
    /// @dev Sender has to be allowed to call this method
    function lock(uint256 credit) external override checkCaller {
        live = 0;
        codex.transferCredit(address(this), msg.sender, credit);
    }

    /// @notice Cancels an existing auction by returning the tokens bid to its bidder
    /// @dev Can only be called when the contract is locked
    /// @param auctionId Id of the surplus auction to cancel
    function cancelAuction(uint256 auctionId) external override {
        if (live == 1) revert SurplusAuction__cancelAuction_stillLive();
        if (auctions[auctionId].recipient == address(0)) revert SurplusAuction__cancelAuction_recipientNotSet();
        token.transferFrom(address(this), auctions[auctionId].recipient, auctions[auctionId].bid);
        delete auctions[auctionId];
    }
}

////// lib/guards/src/interfaces/IGuard.sol
/* pragma solidity >=0.8.4; */

interface IGuard {
    function isGuard() external view returns (bool);
}

////// src/Deployer.sol
// Copyright (C) 2018-2022 DAI Foundation
/* pragma solidity ^0.8.4; */

/* import {Codex} from "fiat/Codex.sol"; */
/* import {Publican} from "fiat/Publican.sol"; */
/* import {Aer} from "fiat/Aer.sol"; */
/* import {Limes} from "fiat/Limes.sol"; */
/* import {Moneta} from "fiat/Moneta.sol"; */
/* import {SurplusAuction} from "fiat/auctions/SurplusAuction.sol"; */
/* import {DebtAuction} from "fiat/auctions/DebtAuction.sol"; */
/* import {NoLossCollateralAuction} from "fiat/auctions/NoLossCollateralAuction.sol"; */
/* import {FIAT} from "fiat/FIAT.sol"; */
/* import {Tenebrae} from "fiat/Tenebrae.sol"; */
/* import {Collybus} from "fiat/Collybus.sol"; */
/* import {Guarded} from "fiat/utils/Guarded.sol"; */

/* import {IGuard} from "guards/interfaces/IGuard.sol"; */

contract CodexFactory {
    function newCodex(address owner) public returns (Codex codex) {
        codex = new Codex();
        codex.allowCaller(codex.ANY_SIG(), owner);
        codex.blockCaller(codex.ANY_SIG(), address(this));
    }
}

contract PublicanFactory {
    function newPublican(address owner, address codex) public returns (Publican publican) {
        publican = new Publican(codex);
        publican.allowCaller(publican.ANY_SIG(), owner);
        publican.blockCaller(publican.ANY_SIG(), address(this));
    }
}

contract AerFactory {
    function newAer(
        address owner,
        address codex,
        address surplusAuction,
        address debtAuction
    ) public returns (Aer aer) {
        aer = new Aer(codex, surplusAuction, debtAuction);
        aer.allowCaller(aer.ANY_SIG(), owner);
        aer.blockCaller(aer.ANY_SIG(), address(this));
    }
}

contract LimesFactory {
    function newLimes(address owner, address codex) public returns (Limes limes) {
        limes = new Limes(codex);
        limes.allowCaller(limes.ANY_SIG(), owner);
        limes.blockCaller(limes.ANY_SIG(), address(this));
    }
}

contract FIATFactory {
    function newFIAT(address owner) public returns (FIAT fiat) {
        fiat = new FIAT();
        fiat.allowCaller(fiat.ANY_SIG(), owner);
        fiat.blockCaller(fiat.ANY_SIG(), address(this));
    }
}

contract MonetaFactory {
    function newMoneta(address codex, address fiat) public returns (Moneta moneta) {
        moneta = new Moneta(codex, fiat);
    }
}

contract SurplusAuctionFactory {
    function newSurplusAuction(
        address owner,
        address codex,
        address gov
    ) public returns (SurplusAuction surplusAuction) {
        surplusAuction = new SurplusAuction(codex, gov);
        surplusAuction.allowCaller(surplusAuction.ANY_SIG(), owner);
        surplusAuction.blockCaller(surplusAuction.ANY_SIG(), address(this));
    }
}

contract DebtAuctionFactory {
    function newDebtAuction(
        address owner,
        address codex,
        address gov
    ) public returns (DebtAuction debtAuction) {
        debtAuction = new DebtAuction(codex, gov);
        debtAuction.allowCaller(debtAuction.ANY_SIG(), owner);
        debtAuction.blockCaller(debtAuction.ANY_SIG(), address(this));
    }
}

contract NoLossCollateralAuctionFactory {
    function newNoLossCollateralAuction(
        address owner,
        address codex,
        address limes
    ) public returns (NoLossCollateralAuction collateralAuction) {
        collateralAuction = new NoLossCollateralAuction(codex, limes);
        collateralAuction.allowCaller(collateralAuction.ANY_SIG(), owner);
        collateralAuction.blockCaller(collateralAuction.ANY_SIG(), address(this));
    }
}

contract CollybusFactory {
    function newCollybus(address owner) public returns (Collybus collybus) {
        collybus = new Collybus();
        collybus.allowCaller(collybus.ANY_SIG(), owner);
        collybus.blockCaller(collybus.ANY_SIG(), address(this));
    }
}

contract TenebraeFactory {
    function newTenebrae(address owner) public returns (Tenebrae tenebrae) {
        tenebrae = new Tenebrae();
        tenebrae.allowCaller(tenebrae.ANY_SIG(), owner);
        tenebrae.blockCaller(tenebrae.ANY_SIG(), address(this));
    }
}

/// @title Deployer
/// @notice Stateful contract managing the deployment of the protocol
contract Deployer is Guarded {
    /// ======== Custom Errors ======== ///

    error Deployer__checkStep_missingPreviousStep();
    error Deployer__deployAuctions_zeroGovToken();
    error Deployer__setGuard_notGuard();

    /// ======== Storage ======== ///

    CodexFactory public codexFactory;
    PublicanFactory public publicanFactory;
    AerFactory public aerFactory;
    LimesFactory public limesFactory;
    FIATFactory public fiatFactory;
    MonetaFactory public monetaFactory;
    SurplusAuctionFactory public surplusAuctionFactory;
    DebtAuctionFactory public debtAuctionFactory;
    NoLossCollateralAuctionFactory public collateralAuctionFactory;
    CollybusFactory public collybusFactory;
    TenebraeFactory public tenebraeFactory;

    Codex public codex;
    Publican public publican;
    Aer public aer;
    Limes public limes;
    FIAT public fiat;
    Moneta public moneta;
    NoLossCollateralAuction public collateralAuction;
    SurplusAuction public surplusAuction;
    DebtAuction public debtAuction;
    Collybus public collybus;
    Tenebrae public tenebrae;

    uint256 public step;

    modifier checkStep(uint256 prevStep) {
        uint256 _step = step;
        if (_step != prevStep) revert Deployer__checkStep_missingPreviousStep();
        _;
        step++;
    }

    /// ======== Deploy ======== ///

    function setFactory(
        CodexFactory codexFactory_,
        PublicanFactory publicanFactory_,
        AerFactory aerFactory_,
        LimesFactory limesFactory_,
        FIATFactory fiatFactory_,
        MonetaFactory monetaFactory_,
        SurplusAuctionFactory surplusAuctionFactory_,
        DebtAuctionFactory debtAuctionFactory_,
        NoLossCollateralAuctionFactory collateralAuctionFactory_,
        CollybusFactory collybusFactory_,
        TenebraeFactory tenebraeFactory_
    ) public checkCaller checkStep(0) {
        codexFactory = codexFactory_;
        publicanFactory = publicanFactory_;
        aerFactory = aerFactory_;
        limesFactory = limesFactory_;
        fiatFactory = fiatFactory_;
        monetaFactory = monetaFactory_;
        surplusAuctionFactory = surplusAuctionFactory_;
        debtAuctionFactory = debtAuctionFactory_;
        collateralAuctionFactory = collateralAuctionFactory_;
        collybusFactory = collybusFactory_;
        tenebraeFactory = tenebraeFactory_;
    }

    function deployCodex() public checkCaller checkStep(1) {
        codex = codexFactory.newCodex(address(this));
        collybus = collybusFactory.newCollybus(address(this));
    }

    function deployFIAT() public checkCaller checkStep(2) {
        fiat = fiatFactory.newFIAT(address(this));
        moneta = monetaFactory.newMoneta(address(codex), address(fiat));

        // contract permissions
        fiat.allowCaller(fiat.mint.selector, address(moneta));
    }

    function deployPublican() public checkCaller checkStep(3) {
        publican = publicanFactory.newPublican(address(this), address(codex));

        // contract permissions
        codex.allowCaller(codex.modifyRate.selector, address(publican));
    }

    function deployAuctions(address govToken) public checkCaller checkStep(4) {
        if (govToken == address(0)) revert Deployer__deployAuctions_zeroGovToken();

        surplusAuction = surplusAuctionFactory.newSurplusAuction(address(this), address(codex), govToken);
        debtAuction = debtAuctionFactory.newDebtAuction(address(this), address(codex), govToken);
        aer = aerFactory.newAer(address(this), address(codex), address(surplusAuction), address(debtAuction));

        // contract references
        publican.setParam("aer", address(aer));

        // contract permissions
        codex.allowCaller(codex.createUnbackedDebt.selector, address(debtAuction));
        surplusAuction.allowCaller(surplusAuction.startAuction.selector, address(aer));
        surplusAuction.allowCaller(surplusAuction.lock.selector, address(aer));
        debtAuction.allowCaller(debtAuction.startAuction.selector, address(aer));
        debtAuction.allowCaller(debtAuction.lock.selector, address(aer));
    }

    function deployLimes() public checkCaller checkStep(5) {
        limes = limesFactory.newLimes(address(this), address(codex));

        // contract references
        limes.setParam("aer", address(aer));

        // contract permissions
        codex.allowCaller(codex.confiscateCollateralAndDebt.selector, address(limes));
        aer.allowCaller(aer.queueDebt.selector, address(limes));
        limes.allowCaller(limes.liquidated.selector, address(collateralAuction));
    }

    function deployTenebrae() public checkCaller checkStep(6) {
        tenebrae = tenebraeFactory.newTenebrae(address(this));

        // contract references
        tenebrae.setParam("codex", address(codex));
        tenebrae.setParam("limes", address(limes));
        tenebrae.setParam("aer", address(aer));
        tenebrae.setParam("collybus", address(collybus));

        // contract permissions
        codex.allowCaller(codex.lock.selector, address(tenebrae));
        limes.allowCaller(limes.ANY_SIG(), address(tenebrae));
        aer.allowCaller(aer.ANY_SIG(), address(tenebrae));
        collybus.allowCaller(collybus.ANY_SIG(), address(tenebrae));
    }

    function deployCollateralAuction() public checkCaller checkStep(7) {
        collateralAuction = collateralAuctionFactory.newNoLossCollateralAuction(
            address(this),
            address(codex),
            address(limes)
        );

        // contract references
        collateralAuction.setParam("aer", address(aer));
        collateralAuction.setParam("limes", address(limes));

        // contract permissions
        codex.allowCaller(codex.transferCredit.selector, address(moneta));
        codex.allowCaller(codex.createUnbackedDebt.selector, address(collateralAuction));
        collateralAuction.allowCaller(collateralAuction.startAuction.selector, address(limes));
        collateralAuction.allowCaller(collateralAuction.cancelAuction.selector, address(tenebrae));
    }

    /// ======== Setup Parameters ======== ///

    function setAerGuard(address guard) public checkCaller checkStep(8) {
        _setGuard(guard);
    }

    function setAuctionGuard(address guard) public checkCaller checkStep(9) {
        _setGuard(guard);
    }

    function setCodexGuard(address guard, uint256 globalDebtCeiling) public checkCaller checkStep(10) {
        _setGuard(guard);
        codex.setParam("globalDebtCeiling", globalDebtCeiling);
    }

    function setCollybusGuard(
        address guard,
        address spotRelayer,
        address discountRateRelayer
    ) public checkCaller checkStep(11) {
        _setGuard(guard);
        collybus.allowCaller(Collybus.updateSpot.selector, spotRelayer);
        collybus.allowCaller(Collybus.updateDiscountRate.selector, discountRateRelayer);
    }

    function setLimesGuard(address guard, uint256 globalMaxDebtOnAuction) public checkCaller checkStep(12) {
        _setGuard(guard);
        limes.setParam("globalMaxDebtOnAuction", globalMaxDebtOnAuction);
    }

    function setPublicanGuard(address guard) public checkCaller checkStep(13) {
        _setGuard(guard);
    }

    function setVaultGuard(address guard) public checkCaller checkStep(14) {
        _setGuard(guard);
    }

    function renounce() public checkCaller checkStep(15) {
        codex.blockCaller(codex.ANY_SIG(), address(this));
        limes.blockCaller(limes.ANY_SIG(), address(this));
        aer.blockCaller(aer.ANY_SIG(), address(this));
        publican.blockCaller(publican.ANY_SIG(), address(this));
        fiat.blockCaller(fiat.ANY_SIG(), address(this));
        collybus.blockCaller(collybus.ANY_SIG(), address(this));
        collateralAuction.blockCaller(collateralAuction.ANY_SIG(), address(this));
        surplusAuction.blockCaller(surplusAuction.ANY_SIG(), address(this));
        debtAuction.blockCaller(debtAuction.ANY_SIG(), address(this));
        tenebrae.blockCaller(tenebrae.ANY_SIG(), address(this));
    }

    function _setGuard(address guard) internal {
        aer.allowCaller(aer.ANY_SIG(), guard);
        codex.allowCaller(codex.ANY_SIG(), guard);
        collateralAuction.allowCaller(collateralAuction.ANY_SIG(), guard);
        collybus.allowCaller(collybus.ANY_SIG(), guard);
        debtAuction.allowCaller(debtAuction.ANY_SIG(), guard);
        fiat.allowCaller(fiat.ANY_SIG(), guard);
        limes.allowCaller(limes.ANY_SIG(), guard);
        publican.allowCaller(publican.ANY_SIG(), guard);
        surplusAuction.allowCaller(surplusAuction.ANY_SIG(), guard);
        tenebrae.allowCaller(tenebrae.ANY_SIG(), guard);
        if (!IGuard(guard).isGuard()) revert Deployer__setGuard_notGuard();
    }
}