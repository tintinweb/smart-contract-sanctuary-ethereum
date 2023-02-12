// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "src/interfaces/IGenerator.sol";
import "src/interfaces/IRoshambo.sol";

contract Generator is IGenerator {
    using Strings for uint256;
    string[] public palettes;

    constructor() {
        palettes = [BLUE, GREEN, ORANGE, PURPLE, WHITE];
    }

    function generateSVG(
        uint256 _gameId,
        Player memory _p1,
        Player memory _p2
    ) external view returns (string memory svg) {
        Choice c1 = _p1.choice;
        Choice c2 = _p2.choice;
        svg = _generateRoot(c1, c2);
        svg = string.concat(svg, _generateFill(_gameId));
        if (
            (c1 == Choice.ROCK || c2 == Choice.ROCK) &&
            (c1 == Choice.PAPER || c2 == Choice.PAPER)
        ) {
            svg = string.concat(svg, _generateRockPaper());
        } else if (
            (c1 == Choice.PAPER || c2 == Choice.PAPER) &&
            (c1 == Choice.SCISSORS || c2 == Choice.SCISSORS)
        ) {
            svg = string.concat(svg, _generatePaperScissors());
        } else if (
            (c1 == Choice.SCISSORS || c2 == Choice.SCISSORS) &&
            (c1 == Choice.ROCK || c2 == Choice.ROCK)
        ) {
            svg = string.concat(svg, _generateScissorsRock());
        } else {
            svg = string.concat(svg, _generateRoshambo());
        }

        svg = string.concat(svg, "</svg>");
    }

    function _generateRoot(Choice _c1, Choice _c2) internal pure returns (string memory) {
        if (
            (_c1 == Choice.PAPER && _c2 == Choice.ROCK) ||
            (_c1 == Choice.SCISSORS && _c2 == Choice.PAPER) ||
            (_c1 == Choice.ROCK && _c2 == Choice.SCISSORS)
        ) {
            return "<svg version='1.1' viewBox='0 0 1200 1200' xmlns='http://www.w3.org/2000/svg' transform='scale (-1, 1)' transform-origin='center'>";
        } else {
            return "<svg version='1.1' viewBox='0 0 1200 1200' xmlns='http://www.w3.org/2000/svg'>";
        }
    }

    function _generateFill(uint256 _gameId) internal view returns (string memory) {
        uint256 index = _gameId % palettes.length;
        string memory fill = palettes[index];
        string[3] memory rect;
        rect[0] = "<rect width='1200' height='1200' fill='";
        rect[1] = fill;
        rect[2] = "'/>";

        return string(abi.encodePacked(rect[0], rect[1], rect[2]));
    }

    function _generateRoshambo() internal pure returns (string memory) {
        return
            "<path d='m697.2 548.4c10.801 7.1992 25.199 10.801 39.602 6 19.199-6 32.398-25.199 32.398-45.602v-42c16.801-9.6016 28.801-26.398 31.199-46.801l8.3984-61.199c4.8008-32.398-6-66-27.602-91.199l-54-62.398v-49.199c0-8.3984-6-14.398-14.398-14.398s-14.398 6-14.398 14.398v55.199c0 3.6016 1.1992 7.1992 3.6016 9.6016l57.602 66c16.801 19.199 24 43.199 20.398 68.398l-8.3984 61.199c-2.3984 18-18 31.199-36 30l-74.398-1.1992c-9.6016 0-16.801-7.1992-16.801-16.801 0-4.8008 2.3984-8.3984 4.8008-12 3.6016-3.6016 7.1992-4.8008 12-4.8008l50.398 2.3984c7.1992 0 13.199-4.8008 14.398-12l4.8008-32.398c1.1992-8.3984-4.8008-15.602-12-16.801s-15.602 4.8008-16.801 12l-2.3984 16.801c-50.398-24-46.801-73.199-46.801-75.602 1.1992-8.3984-4.8008-14.398-13.199-15.602h-1.1992c-7.1992 0-13.199 6-14.398 13.199-2.3984 20.398 3.6016 54 28.801 80.398-9.6016 1.1992-19.199 4.8008-26.398 12-3.6016 3.6016-6 7.1992-8.3984 10.801-7.1992-4.8008-15.602-7.1992-25.199-7.1992-14.398 0-27.602 7.1992-36 18-7.1992-6-16.801-8.3984-26.398-8.3984-7.1992 0-13.199 1.1992-19.199 4.8008-7.1992-40.801-8.3984-82.801-8.3984-112.8 0-26.398 14.398-50.398 36-64.801l13.199-8.3984c4.8008-2.3984 7.1992-7.1992 7.1992-12v-57.602c0-8.3984-6-14.398-14.398-14.398s-14.398 6-14.398 14.398v49.199l-2.4141 1.207c-31.199 19.199-49.199 52.801-50.398 88.801 0 37.199 1.1992 91.199 13.199 140.4-1.1992 4.8008-2.3984 9.6016-2.3984 14.398v46.801c0 25.199 20.398 48 45.602 48 10.801 0 19.199-3.6016 27.602-8.3984 8.3984 10.801 21.602 18 36 18 9.6016 0 19.199-3.6016 26.398-8.3984 8.3984 10.801 21.602 19.199 37.199 19.199 14.398-1.2031 27.598-8.4023 35.996-19.203zm8.4023-74.398 28.801 1.1992h4.8008v36c0 9.6016-7.1992 16.801-16.801 16.801-9.6016 0-16.801-7.1992-16.801-16.801zm-153.6 27.602c0 9.6016-7.1992 16.801-16.801 16.801-9.6016 0-16.801-7.1992-16.801-16.801v-49.199c0-9.6016 7.1992-16.801 16.801-16.801 9.6016 0 16.801 7.1992 16.801 16.801zm62.398 8.3984c0 9.6016-7.1992 16.801-16.801 16.801-9.6016 0-16.801-7.1992-16.801-16.801l0.003906-66c0-9.6016 7.1992-16.801 16.801-16.801 9.6016 0 16.801 7.1992 16.801 16.801zm28.801 10.801v-51.602c6 2.3984 12 3.6016 18 4.8008h15.602v46.801c0 9.6016-7.1992 16.801-16.801 16.801s-16.801-7.2031-16.801-16.801z'/><path d='m546 687.6c-10.801-4.8008-24-6-34.801-1.1992l-108 39.602 72-60c19.199-15.602 21.602-45.602 6-64.801-16.801-19.199-45.602-21.602-64.801-6l-128.4 106.8c-16.801-12-39.602-14.398-60-6l-57.602 24c-31.199 13.199-54 38.398-64.801 69.602l-26.398 78-43.199 25.199c-7.1992 3.6016-9.6016 13.199-4.8008 19.199s13.199 9.6016 19.199 4.8008l48-27.602c3.6016-1.1992 4.8008-4.8008 6-8.3984l27.602-82.801c8.3984-24 25.199-43.199 49.199-52.801l57.602-24c16.801-7.1992 34.801 0 44.398 14.398v1.1992l36 64.801c4.8008 8.3984 1.1992 18-6 22.801-3.5977 3.6016-8.3984 3.6016-13.199 2.4023s-8.3984-4.8008-9.6016-8.3984l-24-45.602c-3.6016-6-10.801-9.6016-18-7.1992l-30 12c-7.1992 2.3984-10.801 10.801-8.3984 18 2.3984 7.1992 10.801 10.801 18 8.3984l15.602-6c4.8008 55.199-39.602 76.801-42 78-7.1992 3.6016-10.801 12-7.1992 19.199 0 0 0 1.1992 1.1992 1.1992 3.6016 6 12 9.6016 18 6 18-8.3984 44.398-30 55.199-64.801 6 7.1992 14.398 13.199 24 15.602 4.8008 1.1992 9.6016 2.3984 15.602 1.1992 0 6 0 13.199 2.3984 19.199 1.1992 2.3984 2.3984 4.8008 3.6016 7.1992 6 9.6016 15.602 16.801 25.199 20.398-3.6016 10.805-3.6016 20.406 0 30.004 1.1992 2.3984 2.3984 4.8008 3.6016 7.1992 3.6016 6 8.3984 10.801 13.199 14.398-30 24-62.398 43.199-86.398 57.602-22.801 13.199-50.398 13.199-74.398 1.1992l-14.398-7.1992c-4.8008-2.3984-9.6016-2.3984-14.398 0l-49.207 27.602c-7.1992 3.6016-9.6016 13.199-4.8008 19.199 3.6016 7.1992 13.199 9.6016 19.199 4.8008l43.199-25.199 7.1992 3.6016c32.398 16.801 70.801 16.801 102-1.1992 30-16.801 72-43.199 108-74.398 2.3984 0 3.6016-1.1992 6-1.1992l45.602-16.801c24-8.3984 36-34.801 27.602-58.801-3.6016-9.6016-9.6016-16.801-18-21.602 1.1992-1.1992 2.3984-3.6016 3.6016-4.8008 4.8008-10.801 6-24 1.1992-34.801-2.3984-6-4.8008-10.801-8.3984-14.398l92.398-33.602c12-3.6016 20.398-12 26.398-24 4.8008-10.801 6-24 1.1992-34.801-4.8008-12-13.199-20.398-24-26.398zm-237.6 36s0-1.1992-1.1992-1.1992l126-105.6c7.1992-6 18-4.8008 24 2.3984 1.1992 1.1992 1.1992 1.1992 1.1992 2.3984 3.6016 7.1992 2.3984 16.801-3.6016 21.602l-130.8 109.2zm37.203 151.2c-3.6016-2.3984-7.1992-4.8008-8.3984-9.6016-3.6016-8.3984 1.1992-19.199 9.6016-21.602l62.398-22.801c4.8008-1.1992 8.3984-1.1992 13.199 0 3.6016 1.1992 6 3.6016 7.1992 7.1992 0 1.1992 1.1992 1.1992 1.1992 2.3984 1.1992 4.8008 1.1992 8.3984-1.1992 13.199-2.3984 3.6016-4.8008 7.1992-9.6016 8.3984l-62.398 22.801c-3.6016 2.4062-8.4023 2.4062-12 0.007812zm98.398 31.199c-2.3984 3.6016-4.8008 7.1992-9.6016 8.3984l-45.602 16.801c-4.8008 1.1992-8.3984 1.1992-13.199 0-4.8008-1.1992-7.1992-4.8008-8.3984-9.6016-1.1992-4.8008-1.1992-8.3984 0-13.199 2.3984-3.6016 6-7.1992 9.6016-8.3984l45.602-16.801c8.3984-3.6016 19.199 1.1992 21.602 9.6016 2.3945 4.8008 2.3945 8.3984-0.003906 13.199zm97.199-169.2c-2.3984 3.6016-4.8008 7.1992-9.6016 8.3984l-182.4 66c0-7.1992-1.1992-15.602-4.8008-22.801l-4.8008-9.6016 181.2-66c4.8008-1.1992 8.3984-1.1992 13.199 0 3.6016 2.3984 7.1992 4.8008 8.3984 9.6016 1.207 6 1.207 9.6016-1.1953 14.402z'/><path d='m1162.8 882-42-24-21.602-70.801c-9.6016-33.602-32.398-61.199-63.602-78l-90-48c-21.602-12-48-4.8008-61.199 16.801-1.1992 1.1992-1.1992 3.6016-2.3984 4.8008l-97.199-54c-21.602-12-50.398-4.8008-62.398 16.801-3.6016 6-4.8008 13.199-6 20.398-18-2.3984-36 6-45.602 22.801-9.6016 16.801-7.1992 37.199 3.6016 50.398-6 3.6016-10.801 8.3984-14.398 15.602-12 21.602-4.8008 50.398 16.801 62.398l16.801 9.6016c-4.8008 3.6016-8.3984 8.3984-10.801 13.199-12 21.602-4.8008 50.398 16.801 62.398l61.199 34.801c14.398 8.3984 30 18 46.801 32.398l2.3984 1.1992c38.398 30 139.2 108 212.4 61.199l42 24c7.1992 3.6016 15.602 1.1992 19.199-6 3.6016-7.1992 1.1992-15.602-6-19.199l-49.199-27.602c-4.8008-2.3984-10.801-2.3984-15.602 1.1992-56.398 44.398-150-28.801-186-56.398l-2.3984-1.1992c-18-14.398-34.801-25.199-50.398-33.602l-61.199-34.801c-8.3984-4.8008-10.801-14.398-6-22.801 4.8008-8.3984 15.602-10.801 22.801-6l90 50.398c7.1992 3.6016 15.602 1.1992 19.199-6 3.6016-7.1992 1.1992-15.602-6-19.199l-140.41-82.793c-8.3984-4.8008-10.801-15.602-6-22.801 4.8008-8.3984 14.398-10.801 22.801-6l123.6 69.602c7.1992 3.6016 15.602 1.1992 19.199-4.8008 3.6016-7.1992 1.1992-15.602-6-19.199l-144-81.602c-8.3984-4.8008-10.801-15.602-6-22.801 4.8008-8.3984 15.602-10.801 22.801-6l133.2 75.602c7.1992 3.6016 15.602 1.1992 19.199-6 3.6016-7.1992 1.1992-15.602-6-19.199l-112.8-63.602c-8.3984-4.8008-10.801-15.602-6-22.801 4.8008-8.3984 14.398-10.801 22.801-6l108 61.199c3.6016 12 10.801 22.801 21.602 28.801l31.199 18c-25.199 100.8 54 134.4 55.199 134.4 7.1992 2.3984 14.398 0 18-6 0 0 0-1.1992 1.1992-1.1992 2.3984-7.1992-1.1992-15.602-8.3984-18-2.3984-1.1992-54-22.801-40.801-92.398 3.6016 2.3984 8.3984 6 12 9.6016l7.1992 6c6 4.8008 14.398 4.8008 20.398-1.1992 4.8008-6 4.8008-14.398-1.1992-20.398l-7.1992-6c-7.1992-13.203-15.598-20.402-26.398-25.203l-45.602-26.398c-4.8008-2.3984-7.1992-6-8.3984-10.801s0-9.6016 2.3984-13.199c4.8008-8.3984 15.602-10.801 22.801-6l90 48c24 13.199 42 34.801 50.398 61.199l22.801 76.801c1.1992 3.6016 3.6016 6 7.1992 8.3984l46.801 26.398c7.1992 3.6016 15.602 1.1992 19.199-6 4.8008-7.1992 2.4023-16.797-4.7969-20.398z'/></g>";
    }

    function _generateRockPaper() internal pure returns (string memory) {
        return
            "<path d='m511.2 573.6c0-16.801-8.3984-32.398-21.602-42 8.3984-12 12-28.801 7.1992-45.602-7.1992-21.602-28.801-36-51.602-36h-48c-10.801-19.199-30-32.398-52.801-34.801l-69.602-9.6016c-37.199-4.8008-74.398 7.1992-103.2 31.199l-69.602 61.199-55.191 0.003906c-8.3984 0-16.801 7.1992-16.801 16.801 0 9.6016 7.1992 16.801 16.801 16.801h61.199c3.6016 0 7.1992-1.1992 10.801-3.6016l74.398-66c21.602-19.199 49.199-27.602 76.801-24l69.602 9.6016c20.398 2.3984 34.801 20.398 34.801 40.801l-1.1992 84c0 10.801-8.3984 18-19.199 18-4.8008 0-9.6016-2.3984-13.199-6-3.6055-3.6016-4.8047-8.4023-4.8047-14.402l2.3984-57.602c0-8.3984-6-15.602-13.199-16.801l-36-6c-8.3984-1.1992-16.801 4.8008-18 13.199s4.8008 16.801 13.199 18l18 2.3984c-26.398 57.602-82.801 52.801-85.199 52.801-8.3984-1.1992-16.801 6-18 14.398v1.1992c0 8.3984 6 15.602 14.398 15.602 22.801 2.3984 61.199-3.6016 91.199-33.602 1.1992 10.801 6 21.602 14.398 28.801 3.6016 3.6016 7.1992 6 12 9.6016-4.8008 8.3984-8.3984 18-8.3984 28.801 0 16.801 8.3984 31.199 20.398 40.801-6 8.3984-9.6016 19.199-9.6016 30 0 8.3984 2.3984 15.602 4.8008 21.602-45.602 8.3984-93.602 9.6016-128.4 8.3984-30 0-57.602-15.602-73.199-40.801l-9.6016-15.602c-2.3984-4.8008-8.3984-7.1992-13.199-7.1992l-67.195 0.003906c-8.3984 0-16.801 7.1992-16.801 16.801 0 9.6016 7.1992 16.801 16.801 16.801h56.398l4.8008 7.1992c21.602 34.801 60 56.398 100.8 56.398 42 0 103.2-1.1992 158.4-14.398 4.8008 1.1992 10.801 2.3984 15.602 2.3984h52.801c28.801 0 54-22.801 54-51.602 0-12-3.6016-21.602-9.6016-31.199 12-9.6016 20.398-24 20.398-40.801 0-10.801-3.6016-21.602-9.6016-30 12.004-3.5977 20.402-19.199 20.402-35.996zm-103.2-90h40.801c10.801 0 19.199 8.3984 19.199 19.199s-8.3984 19.199-19.199 19.199h-40.801l1.1992-33.602c-1.1992-1.1992-1.1992-3.5977-1.1992-4.7969zm30 252h-55.199c-10.801 0-19.199-8.3984-19.199-19.199 0-10.801 8.3984-19.199 19.199-19.199h55.199c10.801 0 19.199 8.3984 19.199 19.199 0 9.5977-8.3984 19.199-19.199 19.199zm9.6016-72h-75.602c-10.801 0-19.199-8.3984-19.199-19.199 0-10.801 8.3984-19.199 19.199-19.199h75.602c10.801 0 19.199 8.3984 19.199 19.199 1.1992 10.797-8.4023 19.199-19.199 19.199zm12-70.801h-58.801c2.3984-6 4.8008-13.199 4.8008-20.398v-18h54c10.801 0 19.199 8.3984 19.199 19.199 0 10.797-8.4023 19.199-19.199 19.199z'/><path d='m1153.2 696h-64.801c-6 0-12 3.6016-14.398 9.6016-31.199 75.602-164.4 55.199-214.8 48h-2.3984c-26.398-3.6016-48-6-68.398-6h-80.398c-10.801 0-19.199-8.3984-19.199-19.199 0-10.801 8.3984-19.199 19.199-19.199h116.4c8.3984 0 16.801-7.1992 16.801-16.801 0-8.3984-7.1992-15.602-16.801-15.602h-184.8c-10.801 0-19.199-8.3984-19.199-19.199 0-10.801 8.3984-19.199 19.199-19.199h160.8c9.6016 0 16.801-7.1992 16.801-15.602 0-9.6016-7.1992-16.801-16.801-16.801h-187.2c-10.801 0-19.199-8.3984-19.199-19.199s8.3984-19.199 19.199-19.199h172.8c9.6016 0 16.801-7.1992 16.801-16.801 0-8.3984-7.1992-15.602-16.801-15.602h-146.4c-10.801 0-19.199-8.3984-19.199-19.199s8.3984-19.199 19.199-19.199h140.4c9.6016 10.801 24 15.602 38.398 15.602h40.801c30 112.8 128.4 102 129.6 102 8.3984-1.1992 14.398-8.3984 14.398-15.602v-2.3984c-1.1992-8.3984-9.6016-15.602-18-14.398-3.6016 0-66 7.1992-91.199-68.398 6 0 10.801 1.1992 16.801 2.3984l10.801 2.3984c8.3984 2.3984 16.801-3.6016 19.199-12 2.3984-8.3984-3.6016-16.801-12-19.199l-10.801-2.3984c-12-2.3984-25.199-3.6016-38.398-3.6016h-60c-6 0-10.801-2.3984-14.398-6-3.6016-3.6016-6-9.6016-6-14.398 0-10.801 9.6016-19.199 19.199-19.199l115.2-2.3984c31.199-1.1992 60 10.801 82.801 32.398l64.801 62.398c3.6016 2.3984 7.1992 4.8008 10.801 4.8008h61.199c8.3984 0 16.801-7.1992 16.801-16.801-0.003906-9.6055-7.2031-18.004-16.805-18.004h-55.199l-60-57.602c-28.801-27.602-66-42-105.6-40.801l-116.4 2.4023c-27.602 1.1992-50.398 22.801-51.602 50.398v6h-124.8c-27.602 0-51.602 22.801-51.602 51.602 0 8.3984 2.3984 15.602 6 22.801-19.199 7.1992-32.398 26.398-32.398 48 0 21.602 13.199 39.602 32.398 48-3.6016 7.1992-6 14.398-6 22.801 0 28.801 22.801 51.602 51.602 51.602h21.602c-2.3984 6-3.6016 12-3.6016 19.199 0 28.801 22.801 51.602 51.602 51.602h80.398c19.199 0 39.602 1.1992 63.602 4.8008h2.3984c55.199 8.3984 196.8 28.801 243.6-57.602h54c8.3984 0 16.801-7.1992 16.801-16.801-0.003906-7.2031-7.2031-14.402-16.805-14.402z'/></g>";
    }

    function _generatePaperScissors() internal pure returns (string memory) {
        return
            "<path d='m1155.6 672h-56.398c-4.8008 0-9.6016 2.3984-12 7.1992l-8.3984 13.199c-14.398 22.801-38.398 36-63.602 36-27.602 0-64.801-1.1992-102-6 2.3984-6 4.8008-12 4.8008-19.199 0-2.3984 0-4.8008-1.1992-8.3984-1.1992-9.6016-6-18-13.199-25.199 7.1992-8.3984 12-19.199 12-30 0-2.3984 0-4.8008-1.1992-8.3984-1.1992-6-3.6016-12-7.1992-18 4.8008-2.3984 8.3984-4.8008 12-8.3984 7.1992-7.1992 10.801-15.602 12-25.199 26.398 25.199 60 31.199 79.199 28.801 7.1992-1.1992 13.199-7.1992 13.199-14.398v-1.1992c-1.1992-7.1992-7.1992-13.199-15.602-13.199-2.3984 0-51.602 3.6016-74.398-45.602l15.602-2.3984c7.1992-1.1992 13.199-8.3984 12-15.602-1.1992-7.1992-8.3984-13.199-15.602-12l-32.398 4.8008c-7.1992 1.1992-12 7.1992-12 14.398l2.3984 50.398c0 4.8008-1.1992 8.3984-4.8008 12-3.6016 3.6016-7.1992 4.8008-12 4.8008-8.3984 0-16.801-7.1992-16.801-16.801l-1.1992-73.199v-1.1992c0-18 13.199-32.398 30-34.801l61.199-8.3984c24-3.6016 49.199 4.8008 67.199 20.398l64.801 57.602c2.3984 2.3984 6 3.6016 9.6016 3.6016h54c8.3984 0 14.398-6 14.398-14.398 0-8.3984-6-14.398-14.398-14.398h-49.199l-61.199-54c-25.199-21.602-57.602-31.199-90-27.602l-61.199 8.3984c-21.602 2.3984-39.602 16.801-48 34.801l-160.8-28.801c-25.199-4.8008-48 12-52.801 37.199-4.8008 24 12 48 37.199 52.801l91.199 15.602-112.8 22.789c-12 2.3984-22.801 8.3984-28.801 19.199-7.1992 9.6016-9.6016 21.602-7.1992 33.602 2.3984 12 8.3984 22.801 18 28.801 9.6016 7.1992 21.602 9.6016 33.602 7.1992l96-16.801c-1.1992 6-1.1992 10.801 0 16.801 2.3984 12 8.3984 22.801 18 28.801 1.1992 1.1992 3.6016 2.3984 4.8008 2.3984-3.6016 8.3984-6 18-3.6016 27.602 4.8008 24 27.602 40.801 52.801 37.199l48-8.3984c2.3984 0 3.6016-1.1992 6-1.1992 46.801 9.6016 96 10.801 129.6 10.801 36 0 68.398-19.199 87.602-49.199l3.6016-6h49.199c8.3984 0 14.398-6 14.398-14.398-0.003906-8.4062-6.0039-14.406-14.402-14.406zm-481.2-165.6c-8.3984-1.1992-14.398-8.3984-14.398-16.801v-2.3984c1.1992-9.6016 10.801-15.602 19.199-13.199l160.8 27.602v1.1992l1.1992 32.398zm-15.598 124.8c-4.8008 1.1992-8.3984 0-12-2.3984-3.6016-2.3984-6-6-7.1992-10.801-1.1992-4.8008 0-9.6016 2.3984-13.199 2.3984-3.6016 6-6 10.801-7.1992l187.2-33.602v10.801c0 8.3984 2.3984 15.602 7.1992 21.602zm128.4 24v-2.3984c0-3.6016 1.1992-7.1992 2.3984-9.6016 2.3984-3.6016 6-6 10.801-7.1992l64.801-12c9.6016-1.1992 18 4.8008 19.199 13.199 1.1992 4.8008 0 8.3984-2.3984 12-2.3984 3.6016-6 6-10.801 7.1992l-64.801 12c-4.8008 1.1992-8.3984 0-12-2.3984-3.5977-3.6016-6-7.1992-7.1992-10.801zm98.402 57.602c-2.3984 3.6016-6 6-10.801 7.1992l-48 8.3984c-4.8008 1.1992-8.3984 0-13.199-2.3984-3.6016-2.3984-6-6-7.1992-10.801-1.1992-9.6016 4.8008-18 13.199-19.199l48-8.3984c4.8008-1.1992 8.3984 0 13.199 2.3984 3.6016 2.3984 6 6 7.1992 10.801 0 3.5977 0 8.3984-2.3984 12z'/><path d='m532.8 547.2c3.6016-6 4.8008-13.199 4.8008-20.398 0-25.199-20.398-45.602-45.602-45.602h-109.2v-4.8008c-1.1992-24-20.398-43.199-44.398-44.398l-100.8-2.3984c-34.801-1.1992-67.199 12-92.398 36l-52.805 50.398h-48c-8.3984 0-14.398 6-14.398 14.398 0 8.3984 6 14.398 14.398 14.398h54c3.6016 0 7.1992-1.1992 9.6016-3.6016l57.602-54c19.199-19.199 45.602-28.801 72-27.602l100.8 2.3984c9.6016 0 16.801 7.1992 16.801 16.801 0 4.8008-1.1992 9.6016-4.8008 13.199-3.6016 3.6016-8.3984 6-13.199 6h-51.602c-10.801 0-22.801 1.1992-33.602 3.6016l-9.6016 2.3984c-7.1992 1.1992-12 9.6016-10.801 16.801 1.1992 7.1992 9.6016 12 16.801 10.801l9.6016-2.3984c4.8008-1.1992 9.6016-1.1992 14.398-2.3984-21.602 66-76.801 60-79.199 60-7.1992-1.1992-14.398 4.8008-15.602 12v2.3984c0 7.1992 4.8008 13.199 12 14.398 1.1992 0 86.398 9.6016 112.8-88.801h34.801c13.199 0 24-4.8008 33.602-14.398h122.4c9.6016 0 16.801 7.1992 16.801 16.801 0 9.6016-7.1992 16.801-16.801 16.801l-128.4 0.003906c-8.3984 0-14.398 6-14.398 14.398 0 8.3984 6 14.398 14.398 14.398l151.2 0.003906c9.6016 0 16.801 7.1992 16.801 16.801 0 9.6016-7.1992 16.801-16.801 16.801l-164.4-0.003906c-8.3984 0-14.398 6-14.398 14.398 0 7.1992 6 14.398 14.398 14.398h140.4c9.6016 0 16.801 7.1992 16.801 16.801 0 9.6016-7.1992 16.801-16.801 16.801l-160.8 0.003906c-8.3984 0-14.398 6-14.398 14.398 0 8.3984 6 14.398 14.398 14.398h102c9.6016 0 16.801 7.1992 16.801 16.801 0 9.6016-7.1992 16.801-16.801 16.801h-69.602c-18 0-37.199 1.1992-60 4.8008h-2.3984c-43.199 6-159.6 24-187.2-42-2.3984-8.3984-7.1992-12-13.199-12h-56.402c-7.1992 0-14.398 6-14.398 14.398 0 8.3984 6 14.398 14.398 14.398h48c40.801 75.602 165.6 57.602 213.6 50.398h2.3984c21.602-3.6016 39.602-4.8008 56.398-4.8008h69.602c25.199 0 45.602-20.398 45.602-45.602 0-6-1.1992-12-3.6016-16.801h18c25.199 0 45.602-20.398 45.602-45.602 0-7.1992-2.3984-14.398-4.8008-20.398 16.801-7.1992 28.801-22.801 28.801-42-2.3984-17.992-14.398-34.793-31.199-40.793z'/></g>";
    }

    function _generateScissorsRock() internal pure returns (string memory) {
        return
            "<path d='m868.8 459.6 67.199-8.3984c27.602-3.6016 54 4.8008 74.398 22.801l72 63.602c2.3984 2.3984 6 3.6016 10.801 3.6016h60c8.3984 0 15.602-7.1992 15.602-15.602 0-8.3984-7.1992-15.602-15.602-15.602h-54l-68.398-60c-27.602-24-63.602-34.801-99.602-30l-67.199 8.3945c-22.801 2.3984-40.801 15.602-51.602 33.602h-46.801c-22.801 0-43.199 13.199-50.398 34.801-4.8008 16.801-1.1992 32.398 7.1992 44.398-12 9.6016-20.398 24-20.398 40.801s8.3984 31.199 20.398 39.602c-6 8.3984-9.6016 18-9.6016 28.801 0 15.602 7.1992 30 19.199 39.602-6 8.3984-9.6016 18-9.6016 30 0 27.602 25.199 50.398 52.801 50.398l52.805-0.003906c6 0 10.801-1.1992 15.602-2.3984 54 12 112.8 14.398 153.6 14.398 39.602 0 76.801-20.398 97.199-55.199l4.8008-7.1992h54c8.3984 0 15.602-7.1992 15.602-15.602 0-8.3984-7.1992-15.602-15.602-15.602h-63.602c-6 0-10.801 2.3984-13.199 7.1992l-8.4023 13.203c-15.602 25.199-42 39.602-70.801 39.602-33.602 0-79.199-1.1992-123.6-8.3984 3.6016-6 4.8008-13.199 4.8008-21.602 0-10.801-3.6016-21.602-9.6016-30 12-9.6016 19.199-24 19.199-39.602 0-10.801-3.6016-20.398-8.3984-27.602 4.8008-2.3984 8.3984-4.8008 12-8.3984 7.1992-8.3984 12-18 13.199-28.801 28.801 27.602 66 34.801 87.602 32.398 8.3984-1.1992 14.398-7.1992 14.398-15.602l0.003906-1.1953c-1.1992-8.3984-8.3984-14.398-16.801-14.398-2.3984 0-56.398 4.8008-82.801-51.602l18-2.3984c8.3984-1.1992 14.398-9.6016 13.199-18-1.1992-8.3984-9.6016-14.398-18-13.199l-36 4.8008c-8.3984 1.1992-13.199 8.3984-13.199 16.801l2.3984 55.199c0 4.8008-1.1992 9.6016-4.8008 13.199-3.6016 3.6016-8.3984 6-13.199 6-9.6016 0-18-8.3984-18-18l-1.1992-81.602c-1.1992-16.801 13.203-34.801 32.402-37.199zm-104.4 34.797h39.602v6l1.1992 32.398h-39.602c-10.801 0-19.199-8.3984-19.199-19.199-1.1992-10.797 8.4023-19.199 18-19.199zm-30 87.602c0-10.801 8.3984-19.199 19.199-19.199h51.602v18c0 7.1992 2.3984 13.199 4.8008 20.398h-56.398c-10.801-1.1992-19.203-9.5977-19.203-19.199zm93.602 156h-54c-10.801 0-19.199-8.3984-19.199-19.199s8.3984-19.199 19.199-19.199h54c10.801 0 19.199 8.3984 19.199 19.199s-8.3984 19.199-19.199 19.199zm9.6016-105.6c10.801 0 19.199 8.3984 19.199 19.199 0 10.801-8.3984 19.199-19.199 19.199h-73.199c-10.801 0-19.199-8.3984-19.199-19.199 0-10.801 8.3984-19.199 19.199-19.199z'/><path d='m608.4 574.8-123.6-22.801 100.8-18c27.602-4.8008 45.602-31.199 40.801-57.602-4.8008-27.602-31.199-45.602-58.801-40.801l-178.8 31.199c-9.6016-20.398-30-36-54-38.398l-67.199-8.3984c-36-4.8008-72 6-99.602 30l-68.398 60h-54c-8.3984 0-15.602 7.1992-15.602 15.602 0 8.3984 7.1992 15.602 15.602 15.602h60c3.6016 0 7.1992-1.1992 10.801-3.6016l72-63.602c20.398-18 48-26.398 74.398-22.801l67.199 8.3984c19.199 2.3984 33.602 19.199 33.602 38.398v1.1992l-1.1992 81.602c0 9.6016-8.3984 18-18 18-4.8008 0-9.6016-2.3984-13.199-6-3.6016-3.6016-4.8008-8.3984-4.8008-13.199l2.3984-55.199c0-8.3984-6-15.602-13.199-16.801l-36-4.8008c-8.3984-1.1992-16.801 4.8008-18 13.199-1.1992 8.3984 4.8008 16.801 13.199 18l18 2.3984c-26.398 55.199-80.398 51.602-82.801 51.602-8.3984-1.1992-16.801 6-16.801 14.398v1.1992c0 8.3984 6 14.398 14.398 15.602 21.602 2.3984 58.801-3.6016 87.602-32.398 1.1992 10.801 6 20.398 13.199 27.602 3.6016 3.6016 8.3984 7.1992 13.199 9.6016-3.6016 6-7.1992 12-8.3984 19.199 0 3.6016-1.1992 6-1.1992 8.3984 0 13.199 4.8008 25.199 13.199 33.602-7.1992 7.1992-13.199 16.801-14.398 27.602 0 2.3984-1.1992 6-1.1992 8.3984 0 7.1992 1.1992 14.398 4.8008 21.602-40.801 6-82.801 7.1992-112.8 7.1992-28.801 0-55.199-15.602-70.801-39.602l-9.6016-14.398c-2.3984-4.8008-8.3984-7.1992-13.199-7.1992h-62.398c-8.3984 0-15.602 7.1992-15.602 15.602 0 8.3984 7.1992 15.602 15.602 15.602h54l4.8008 7.1992c21.602 33.602 57.602 54 97.199 55.199 37.199 0 92.398-1.1992 144-12 2.3984 1.1992 3.6016 1.1992 6 1.1992l52.801 9.6016c27.602 4.8008 52.801-13.199 58.801-40.801 2.3984-10.801 0-21.602-4.8008-31.199 2.3984-1.1992 3.6016-2.3984 6-3.6016 10.801-7.1992 18-19.199 20.398-32.398 1.1992-6 1.1992-13.199 0-19.199l105.6 18c13.199 2.3984 26.398 0 37.199-8.3984 10.801-7.1992 18-19.199 20.398-32.398s0-26.398-8.3984-37.199c-6-9.6094-18-16.809-31.203-19.207zm-212.4-76.801 177.6-31.199c9.6016-2.3984 20.398 4.8008 21.602 15.602v3.6016c0 8.3984-6 16.801-15.602 18l-183.6 32.395 1.1992-36c-1.1992-1.1992-1.1992-2.3984-1.1992-2.3984zm37.199 236.4c-1.1992 4.8008-3.6016 9.6016-7.1992 12-3.6016 2.3984-9.6016 3.6016-14.398 3.6016l-52.801-9.6016c-4.8008-1.1992-9.6016-3.6016-12-7.1992-2.3984-3.6016-3.6016-9.6016-3.6016-14.398 1.1992-4.8008 3.6016-9.6016 7.1992-12 3.6016-2.3984 9.6016-3.6016 14.398-3.6016l52.801 9.6016c9.6016 1.1992 16.801 12 15.602 21.598zm21.602-66c-1.1992 4.8008-3.6016 9.6016-7.1992 12-3.6016 2.3984-9.6016 3.6016-14.398 3.6016l-72-13.199c-4.8008-1.1992-9.6016-3.6016-12-7.1992-2.3984-3.6016-3.6016-9.6016-3.6016-14.398 1.1992-9.6016 12-16.801 21.602-15.602l72 13.199c4.8008 1.1992 9.6016 3.6016 12 7.1992 2.3984 3.6016 3.6016 7.1992 3.6016 10.801-0.003907 1.1992-0.003907 2.3984-0.003907 3.5977zm156-28.797c-3.6016 2.3984-9.6016 3.6016-14.398 3.6016l-210-37.199c4.8008-7.1992 7.1992-15.602 7.1992-24v-12l208.8 37.199c4.8008 1.1992 9.6016 3.6016 12 7.1992 2.3984 3.6016 3.6016 9.6016 3.6016 14.398-0.003906 3.5977-3.6055 7.1992-7.2031 10.801z'/></g>";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Player} from "src/interfaces/IRoshambo.sol";

string constant BLUE = "#3B6BF9";
string constant GREEN = "#007435";
string constant ORANGE = "#FF824A";
string constant PURPLE = "#C462DD";
string constant WHITE = "#ffffff";

interface IGenerator {
    function generateSVG(
        uint256 _gameId,
        Player memory _p1,
        Player memory _p2
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

uint256 constant DENOMINATOR = 10000;

enum State {
    INACTIVE,
    PENDING,
    ACTIVE,
    SUCCESS,
    DRAW
}

enum Stage {
    NOT_STARTED,
    COMMIT,
    REVEAL,
    SETTLE
}

enum Choice {
    NONE,
    ROCK,
    PAPER,
    SCISSORS
}

struct Game {
    Player p1;
    Player p2;
    uint256 pot;
    State state;
    Stage stage;
    address winner;
    uint256 commit;
    uint256 reveal;
}

struct Player {
    address player;
    Choice choice;
    bytes32 commitment;
}

struct Record {
    uint64 rank;
    uint64 wins;
    uint64 losses;
    uint64 ties;
    uint256[] gameIds;
}

interface IRoshambo {
    error AlreadyCommited();
    error InsufficientBalance();
    error InsufficientWager();
    error InvalidChoice();
    error InvalidGame();
    error InvalidPlayer();
    error InvalidSecret();
    error InvalidStage();
    error InvalidState();
    error InvalidWager();
    error PastDeadline();
    error TransferFailed();

    event NewGame(uint256 indexed _gameId, address indexed _player, uint256 indexed _wager);
    event JoinGame(uint256 indexed _gameId, address indexed _player, uint256 indexed _pot);
    event Commit(uint256 indexed _gameId, address indexed _player, bytes32 _commit, Stage _stage);
    event Reveal(
        uint256 indexed _gameId,
        address indexed _player,
        Choice _choice,
        string _secret,
        Stage _stage
    );
    event Settle(
        uint256 indexed _gameId,
        address indexed _winner,
        Choice _choice1,
        Choice _choice2,
        State _state
    );
    event Cancel(uint256 indexed _gameId, address indexed _player, uint256 indexed _refund);

    function DURATION() external view returns (uint256);

    function MIN_WAGER() external view returns (uint256);

    function beneficiary() external view returns (address);

    function cancel(uint256 _gameId) external;

    function commit(uint256 _gameId, bytes32 _commit) external;

    function currentId() external view returns (uint256);

    function generator() external view returns (address);

    function generateCommit(
        uint256 _gameId,
        address _player,
        Choice _choice,
        string memory _secret
    ) external view returns (bytes32);

    function joinGame(uint256 _gameId) external payable;

    function lobby(uint256) external view returns (uint256);

    function newGame() external payable returns (uint256);

    function payouts(address) external view returns (uint256);

    function rake() external view returns (uint256);

    function reveal(uint256 _gameId, Choice _choice, string memory _secret) external;

    function setBeneficiary(address _beneficiary) external payable;

    function setRake(uint256 _rake) external payable;

    function settle(uint256 _gameId) external;

    function totalSupply() external view returns (uint256);

    function withdraw(address _to) external;
}