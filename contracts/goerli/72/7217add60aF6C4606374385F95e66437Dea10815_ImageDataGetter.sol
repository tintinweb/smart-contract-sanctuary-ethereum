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
/**
 * Creator: Virtue Labs
 * Authors:
 *** Code: 0xYeety, CTO - Virtue labs
 *** Concept: Church, CEO - Virtue Labs
**/

pragma solidity ^0.8.17;

//enum HeartColor {
//    Red,
//    Blue,
//    Green,
//    Yellow,
//    Orange,
//    Purple,
//    Black,
//    White,
//    Length
//}

import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

using Strings for uint256;

type HeartColor is uint24;

function packHeartColor(uint8 r, uint8 g, uint8 b) pure returns (HeartColor) {
    return HeartColor.wrap((uint24(r)<<16) + (uint24(g)<<8) + uint24(b));
}

function heartColorOfUint256(uint256 i) pure returns (HeartColor) {
    return HeartColor.wrap(uint24(i%(1<<24)));
}

function safeHeartColorOfUint256(uint256 i) pure returns (HeartColor) {
    require(i < (1<<24), "bad hcNum");
    return HeartColor.wrap(uint24(i%(1<<24)));
}

function unpackHeartColor(HeartColor color) pure returns (uint8 r, uint8 g, uint8 b) {
    uint24 colorInt = HeartColor.unwrap(color);

    r = uint8(colorInt>>16);
    g = uint8((colorInt>>8)%256);
    b = uint8(colorInt%256);
}

function colorToString(HeartColor color) pure returns (string memory) {
//    (uint8 r, uint8 g, uint8 b) = unpackHeartColor(color);
//
//    return abi.encodePacked();

    return uint256(HeartColor.unwrap(color)).toHexString(6);
}

function baseHeartColor(uint256 i) pure returns (HeartColor) {
    uint24 toReturn;

    if (i == 0) {
        toReturn = 0xDD2E44;
    }
    else if (i == 1) {
        toReturn = 0x5CADED;
    }
    else if (i == 2) {
        toReturn = 0x77B05A;
    }
    else if (i == 3) {
        toReturn = 0xFCCB58;
    }
    else if (i == 4) {
        toReturn = 0xF2900D;
    }
    else if (i == 5) {
        toReturn = 0xA98FD5;
    }
    else if (i == 6) {
        toReturn = 0x31383C;
    }
    else if (i == 7) {
        toReturn = 0xE6E7E8;
    }
    else {
        revert("bad hcIndex");
    }

    return HeartColor.wrap(toReturn);
}

function heartColorToBase(HeartColor color) pure returns (uint8 toReturn) {
    uint24 colorNum = HeartColor.unwrap(color);

    if (colorNum == 0xDD2E44) {
        toReturn = 0;
    }
    else if (colorNum == 0x5CADED) {
        toReturn = 1;
    }
    else if (colorNum == 0x77B05A) {
        toReturn = 2;
    }
    else if (colorNum == 0xFCCB58) {
        toReturn = 3;
    }
    else if (colorNum == 0xF2900D) {
        toReturn = 4;
    }
    else if (colorNum == 0xA98FD5) {
        toReturn = 5;
    }
    else if (colorNum == 0x31383C) {
        toReturn = 6;
    }
    else if (colorNum == 0xE6E7E8) {
        toReturn = 7;
    }
    else {
        revert("bad color for base");
    }
}

function isBaseHeartColor(HeartColor color) pure returns (bool) {
    uint24 colorNum = HeartColor.unwrap(color);

    return (
        colorNum == 0xDD2E44 || colorNum == 0x5CADED ||
        colorNum == 0x77B05A || colorNum == 0xFCCB58 ||
        colorNum == 0xF2900D || colorNum == 0xA98FD5 ||
        colorNum == 0x31383C || colorNum == 0xE6E7E8
    );
}

function equal(HeartColor color1, HeartColor color2) pure returns (bool) {
    return (HeartColor.unwrap(color1) == HeartColor.unwrap(color2));
}

/**************************************/

// SPDX-License-Identifier: MIT
/**
 * Creator: Virtue Labs
 * Authors:
 *** Code: 0xYeety, CTO - Virtue labs
 *** Concept: Church, CEO - Virtue Labs
**/

pragma solidity ^0.8.17;

import "./HeartColors.sol";

contract ImageDataGetter {
    mapping(uint256 => string) private colorToHex;

    constructor() {
        colorToHex[0] = "DD2E44"; // red
        colorToHex[1] = "5CADED"; // blue
        colorToHex[2] = "77B05A"; // green
        colorToHex[3] = "FCCB58"; // yellow
        colorToHex[4] = "F2900D"; // orange
        colorToHex[5] = "A98FD5"; // purple
        colorToHex[6] = "31383C"; // black
        colorToHex[7] = "E6E7E8"; // white
    }

//    function getImageData(HeartColor color) public view returns (string memory) {
    function getImageData(HeartColor color) public pure returns (string memory) {
//        require(uint8(color) < uint8(HeartColor.Length), "c");
//        string memory colorStr = colorToHex[uint256(color)];

        string memory colorStr = colorToString(color);

        string memory toReturn = string(
            abi.encodePacked(
                "<svg width='100%25' height='100%25' viewBox='0 0 1000 1000' fill='none' xmlns='http://www.w3.org/2000/svg'>",
                "<rect width='1000' height='1000' fill='%231E1E1E'/>",
                "<g filter='url(%23filter0_d_0_1)'>",
                "<rect x='0.5' y='0.5' width='999' height='999' fill='%23232323' stroke='white'/>",
                "<rect x='354' y='350' width='300' height='300' rx='3' fill='white'/>",
                "<rect x='354.9' y='350.9' width='298.2' height='298.2' rx='2.1' fill='%231E1E1E' stroke='white' stroke-width='1.8'/>"
            )
        );

        toReturn = string(
            abi.encodePacked(
                toReturn,
                "<rect x='433.355' y='506.421' width='100' height='100' transform='rotate(-45 433.355 506.421)' fill='%23", colorStr, "'/>",
                "<circle cx='468.711' cy='471.066' r='50' transform='rotate(-45 468.711 471.066)' fill='%23", colorStr, "'/>",
                "<circle cx='539.421' cy='471.066' r='50' transform='rotate(-45 539.421 471.066)' fill='%23", colorStr, "'/>",
                "<g clip-path='url(%23clip0_0_1)'>"
            )
        );

        toReturn = string(
            abi.encodePacked(
                toReturn,
                "<path d='M650.1 350.9H357.9C356.243 350.9 354.9 352.243 354.9 353.9V646.1C354.9 647.757 356.243 649.1 357.9 649.1H650.1C651.757 649.1 653.1 647.757 653.1 646.1V353.9C653.1 352.243 651.757 350.9 650.1 350.9Z' fill='%231E1E1E' stroke='white' stroke-width='1.8' stroke-linejoin='round'/>",
                "<path d='M504.066 435.71L433.355 506.421L504.066 577.132L574.777 506.421L504.066 435.71Z' fill='%23", colorStr, "'/>",
                "<path d='M504.066 506.421C523.592 486.895 523.592 455.237 504.066 435.711C484.54 416.184 452.882 416.184 433.356 435.711C413.829 455.237 413.829 486.895 433.356 506.421C452.882 525.948 484.54 525.948 504.066 506.421Z' fill='%23", colorStr, "'/>",
                "<path d='M574.776 506.421C594.303 486.895 594.303 455.237 574.776 435.711C555.25 416.184 523.592 416.184 504.066 435.711C484.54 455.237 484.54 486.895 504.066 506.421C523.592 525.948 555.25 525.948 574.776 506.421Z' fill='%23", colorStr, "'/>"
            )
        );

        return string(
            abi.encodePacked(
                toReturn,
                "</g></g><defs>",
                "<filter id='filter0_d_0_1' x='0' y='0' width='1008' height='1008' filterUnits='userSpaceOnUse' color-interpolation-filters='sRGB'>",
                "<feFlood flood-opacity='0' result='BackgroundImageFix'/>",
                "<feColorMatrix in='SourceAlpha' type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0' result='hardAlpha'/>",
                "<feOffset dy='4'/><feGaussianBlur stdDeviation='2'/><feComposite in2='hardAlpha' operator='out'/>",
                "<feColorMatrix type='matrix' values='0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.25 0'/>",
                "<feBlend mode='normal' in2='BackgroundImageFix' result='effect1_dropShadow_0_1'/>",
                "<feBlend mode='normal' in='SourceGraphic' in2='effect1_dropShadow_0_1' result='shape'/>",
                "</filter><clipPath id='clip0_0_1'>",
                "<rect x='354' y='350' width='300' height='300' rx='6' fill='white'/>",
                "</clipPath></defs></svg>"
            )
        );
    }

    receive() external payable {
        require(false, "This address should not be receiving funds by fallback!");
    }
}