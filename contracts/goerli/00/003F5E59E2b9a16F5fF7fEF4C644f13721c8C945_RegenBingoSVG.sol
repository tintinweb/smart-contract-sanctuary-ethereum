// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0;

import "../contracts/RegenBingoSVG.sol";

contract $RegenBingoSVG is RegenBingoSVG {
    bytes32 public __hh_exposed_bytecode_marker = "hardhat-exposed";

    constructor(address _dateTimeContractAddress) RegenBingoSVG(_dateTimeContractAddress) {}

    function $xOffset() external pure returns (uint256) {
        return xOffset;
    }

    function $yOffset() external pure returns (uint256) {
        return yOffset;
    }

    function $circleXOffset() external pure returns (uint256) {
        return circleXOffset;
    }

    function $circleYOffset() external pure returns (uint256) {
        return circleYOffset;
    }

    function $backgroundColors() external view returns (string[40] memory) {
        return backgroundColors;
    }

    function $MONTHS() external view returns (string[12] memory) {
        return MONTHS;
    }

    function $dateTimeContract() external view returns (IDateTime) {
        return dateTimeContract;
    }

    function $defs1() external pure returns (string memory) {
        return defs1;
    }

    function $defs2() external pure returns (string memory) {
        return defs2;
    }

    function $styles() external pure returns (string memory) {
        return styles;
    }

    function $cardPattern() external pure returns (string memory) {
        return cardPattern;
    }

    function $header() external pure returns (string memory) {
        return header;
    }

    function $footer() external pure returns (string memory) {
        return footer;
    }

    function $_generateRollingText(uint256 donationAmount,string calldata donationName,address donationAddress,bool isBingoFinished,uint256 drawTimestamp) external view returns (string memory ret0) {
        (ret0) = super._generateRollingText(donationAmount,donationName,donationAddress,isBingoFinished,drawTimestamp);
    }

    function $_generateDate(uint256 timestamp) external view returns (string memory ret0) {
        (ret0) = super._generateDate(timestamp);
    }

    function $_convertWEIToEtherInString(uint256 amount) external pure returns (string memory ret0) {
        (ret0) = super._convertWEIToEtherInString(amount);
    }

    function $_generateNumbers(uint256[9][3] calldata numbers,bool[9][3] calldata covered) external pure returns (string memory ret0) {
        (ret0) = super._generateNumbers(numbers,covered);
    }

    function $_generateNumberSVG(uint256 y,uint256 x,uint256 number,bool covered) external pure returns (string memory ret0) {
        (ret0) = super._generateNumberSVG(y,x,number,covered);
    }

    function $_generatePillPattern(uint256 tokenId) external pure returns (string memory ret0) {
        (ret0) = super._generatePillPattern(tokenId);
    }

    receive() external payable {}
}

interface IDateTime {
    function timestampToDate(uint256)
        external
        pure
        returns (
            uint256,
            uint256,
            uint256
        );

    function timestampToDateTime(uint256 timestamp)
        external
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        );
}

interface IRegenBingoSVG {
    function generateTokenSVG(
        uint256 tokenId,
        uint256[9][3] calldata numbers,
        bool[9][3] calldata covered,
        uint256 donationAmount,
        string memory donationName,
        address donationAddress,
        bool isBingoFinished,
        uint256 drawTimestamp
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./interfaces/IRegenBingoSVG.sol";
import "./interfaces/IDateTime.sol";

contract RegenBingoSVG is IRegenBingoSVG {
    uint256 constant xOffset = 240;
    uint256 constant yOffset = 935;
    uint256 constant circleXOffset = 300;
    uint256 constant circleYOffset = 900;
    string[40] backgroundColors = [
        "#5f9e80",
        "#909F79",
        "#9C9491",
        "#A0B59E",
        "#a3b18a",
        "#A9B9A9",
        "#b08968",
        "#b1a7a6",
        "#b57170",
        "#b5e48c",
        "#BAB86C",
        "#c9ada7",
        "#cad2c5",
        "#cbf3f0",
        "#ccd5ae",
        "#cce3de",
        "#D0C4AB",
        "#d2b48c",
        "#d4a373",
        "#d5bdaf",
        "#d9ed92",
        "#dad7cd",
        "#dcae96",
        "#dda15e",
        "#ddb892",
        "#E0BB44",
        "#e6ccb2",
        "#e9d8a6",
        "#e9edc9",
        "#eaac8b",
        "#eec643",
        "#f2c078",
        "#f5f5dc",
        "#f7c59f",
        "#fec89a",
        "#ffb5a7",
        "#ffc43d",
        "#ffdab9",
        "#ffe5b4",
        "#ffefd5"
    ];
    string[12] MONTHS = [
        "January",
        "February",
        "March",
        "April",
        "May",
        "June",
        "July",
        "August",
        "September",
        "October",
        "November",
        "December"
    ];

    IDateTime dateTimeContract;

    constructor(address _dateTimeContractAddress) {
        dateTimeContract = IDateTime(_dateTimeContractAddress);
    }

    string constant defs1 =
        string(
            abi.encodePacked(
                "<defs>",
                '<g id="p"><path fill="#02E2AC" d="M10-0 10-16A1 1 0 00-10-16L-10 0z"/><path fill="#B3FFED" d="M-10 0-10 16A1 1 18 0010 16L10-0z"/></g><g id="pbg"><use href="#p" transform="translate(1600 1733) rotate(130 442 41) scale(2,2)"/><use href="#p" transform="translate(500 2133) rotate(44 11 555) scale(2,2)"/><use href="#p" transform="translate(200 2200) rotate(20 200 200) scale(2,2)"/><use href="#p" transform="translate(1000 315) rotate(130 442 41) scale(2,2)"/><use href="#p" transform="translate(50 250) rotate(80 200 200) scale(2,2)"/><use href="#p" transform="translate(444 888) rotate(160 400 400) scale(2,2)"/><use href="#p" transform="translate(400 1700) rotate(40 67 124) scale(2,2)"/><use href="#p" transform="translate(0 550) rotate(140 11 362) scale(2,2)"/><use href="#p" transform="translate(0 1100) rotate(0 200 200) scale(3,3)"/><use href="#p" transform="translate(1733 333) rotate(299 60 60) scale(3,3)"/><use href="#p" transform="translate(1312 50) rotate(99 14 21) scale(3,3)"/><use href="#p" transform="translate(2200 1993) rotate(11 414 241) scale(3,3)"/><use href="#p" transform="translate(630 0) rotate(30 124 532) scale(3,3)"/><use href="#p" transform="translate(1750 850) rotate(60 200 200) scale(3,3)"/><use href="#p" transform="translate(0 0) rotate(310 595 381) scale(3,3)"/><use href="#p" transform="translate(300 1100) rotate(180 491 372) scale(3,3)"/><use href="#p" transform="translate(2150 650) rotate(320 713 321) scale(4,4)"/><use href="#p" transform="translate(400 400) rotate(180 700 700) scale(4,4)"/><use href="#p" transform="translate(10 155) rotate(280 412 132) scale(4,4)"/><use href="#p" transform="translate(12 93) rotate(33 241 414) scale(4,4)"/><use href="#p" transform="translate(250 1997) rotate(100 200 200) scale(4,4)"/><use href="#p" transform="translate(1114 2141) rotate(51 11 410) scale(4,4)"/><use href="#p" transform="translate(-162 1693) rotate(40 414 241) scale(4,4)"/><use href="#p" transform="translate(395 113) rotate(140 241 251) scale(4,4)"/></g>',
                '<path id="pt" d="M0 0 L4800 0 Z"/>',
                '<text id="t">',
                '<textPath xlink:href="#pt" textLength="2200" font-size="35">'
            )
        );

    string constant defs2 =
        string(
            abi.encodePacked(
                '<animate attributeName="startOffset" values="2400; 0" dur="9s" repeatCount="indefinite"/> ',
                "</textPath>",
                "</text>",
                "</defs>"
            )
        );

    string constant styles =
        "<style>text{font-family:Monaco;font-size:100px}svg{stroke:black;stroke-width:1}.a{fill:#57b592}.b{fill:#bde4df}.c{fill:#f8ce47}.d{fill:#fcf2b1}</style>";

    string constant cardPattern =
        string(
            abi.encodePacked(
                '<pattern id="bg" width="0.111111111111" height="0.333333333333">',
                '<polygon class="a" points="0,0 0,200 200,200"/>',
                '<polygon class="c" points="0,0 200,0 200,200"/>',
                '<rect class="d" x="20" y="20" width="160" height="160"/>'
                "</pattern>"
            )
        );

    string constant header =
        string(
            abi.encodePacked(
                '<polygon class="b" points="200,500 200,800 2000,800 2000,500"/>',
                '<polygon class="c" points="200,500 200,800 350,650"/>',
                '<polygon class="c" points="2000,500 2000,800 1850,650"/>',
                '<rect class="d" x="220" y="520" width="1760" height="260"/>',
                '<text x="1100" y="650" dominant-baseline="middle" text-anchor="middle" style="font-size:150">Regen Bingo</text>'
            )
        );

    string constant footer =
        string(
            abi.encodePacked(
                '<polygon class="b" points="200,1400 200,1500 2000,1500 2000,1400"/>',
                '<polygon class="a" points="200,1400 200,1500 250,1450"/>',
                '<polygon class="a" points="2000,1400 2000,1500 1950,1450"/>',
                '<rect class="d" x="220" y="1420" width="1760" height="60"/>',
                '<clipPath id="clip">',
                '<rect x="230" y="1420" width="1740" height="60"/>',
                "</clipPath>",
                '<g clip-path="url(#clip)">',
                '<use x="-1900" y="1460" href="#t"/>',
                '<use x="500" y="1460" href="#t"/>',
                "</g>"
            )
        );

    function generateTokenSVG(
        uint256 tokenId,
        uint256[9][3] calldata numbers,
        bool[9][3] calldata covered,
        uint256 donationAmount,
        string memory donationName,
        address donationAddress,
        bool isBingoFinished,
        uint256 drawTimestamp
    ) external view returns (string memory) {
        return (
            string(
                abi.encodePacked(
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 2200 2200" style="background-color:',
                    backgroundColors[tokenId % backgroundColors.length],
                    '">',
                    defs1,
                    _generateRollingText(
                        donationAmount,
                        donationName,
                        donationAddress,
                        isBingoFinished,
                        drawTimestamp
                    ),
                    defs2,
                    styles,
                    _generatePillPattern(tokenId),
                    cardPattern,
                    '<g><polygon style="stroke-width: 20" points="200,500 200,1500 2000,1500 2000,500"/>'
                    '<rect fill="url(#bg)" x="200" y="800" width="1800" height="600"/>',
                    _generateNumbers(numbers, covered),
                    header,
                    footer,
                    "</g></svg>"
                )
            )
        );
    }

    function _generateRollingText(
        uint256 donationAmount,
        string memory donationName,
        address donationAddress,
        bool isBingoFinished,
        uint256 drawTimestamp
    ) internal view returns (string memory) {
        // temp = unicode("Donating 0.05 ETH · Gitcoin Alpha Round · 0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2 · January 31, 2023")
        return (
            string(
                abi.encodePacked(
                    isBingoFinished ? "Donated " : "Donating ",
                    _convertWEIToEtherInString(donationAmount),
                    unicode" · ",
                    donationName,
                    unicode" · ",
                    Strings.toHexString(uint256(uint160(donationAddress)), 20),
                    unicode" · ",
                    _generateDate(drawTimestamp)
                )
            )
        );
    }

    function _generateDate(uint256 timestamp)
        internal
        view
        returns (string memory)
    {
        uint256 year;
        uint256 month;
        uint256 day;
        uint256 hour;
        uint256 minute;

        (year, month, day, hour, minute, ) = dateTimeContract
            .timestampToDateTime(timestamp);

        string memory minuteString;
        string memory hourString;

        if (minute < 10) {
            minuteString = string(
                abi.encodePacked("0", Strings.toString(minute))
            );
        } else {
            minuteString = Strings.toString(minute);
        }

        if (hour < 10) {
            hourString = string(abi.encodePacked("0", Strings.toString(hour)));
        } else {
            hourString = Strings.toString(hour);
        }

        return (
            string(
                abi.encodePacked(
                    MONTHS[month - 1],
                    " ",
                    Strings.toString(day),
                    ", ",
                    Strings.toString(year),
                    " ",
                    hourString,
                    ":",
                    minuteString,
                    " UTC"
                )
            )
        );
    }

    function _convertWEIToEtherInString(uint256 amount)
        internal
        pure
        returns (string memory)
    {
        string memory decimalPart;
        string memory floatingPart;

        decimalPart = Strings.toString(amount / 1 ether);

        if (amount % 1 ether == 0) {
            floatingPart = ".00";
        } else {
            bytes memory fpart = bytes(Strings.toString(amount % 1 ether));
            uint256 numberOfZeroes = 18 - fpart.length;

            bool isFirstNonZeroSeen = false;

            for (uint256 i = fpart.length; i > 0; i--) {
                if (fpart[i - 1] != bytes1("0")) {
                    isFirstNonZeroSeen = true;
                }
                if (isFirstNonZeroSeen) {
                    floatingPart = string(
                        abi.encodePacked(fpart[i - 1], floatingPart)
                    );
                }
            }

            for (uint256 i = 0; i < numberOfZeroes; i++) {
                floatingPart = string(abi.encodePacked("0", floatingPart));
            }
            floatingPart = string(abi.encodePacked(".", floatingPart));
        }
        return string(abi.encodePacked(decimalPart, floatingPart, " ETH"));
    }

    function _generateNumbers(
        uint256[9][3] calldata numbers,
        bool[9][3] calldata covered
    ) internal pure returns (string memory) {
        string memory output;
        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = 0; j < 9; j++) {
                if (numbers[i][j] > 0) {
                    output = string(
                        abi.encodePacked(
                            output,
                            _generateNumberSVG(
                                i,
                                j,
                                numbers[i][j],
                                covered[i][j]
                            )
                        )
                    );
                }
            }
        }
        return output;
    }

    function _generateNumberSVG(
        uint256 y,
        uint256 x,
        uint256 number,
        bool covered
    ) internal pure returns (string memory) {
        string memory output;
        string memory xCordinate;
        string memory yCordinate;
        string memory circleX = Strings.toString(x * 200 + circleXOffset);
        string memory circleY = Strings.toString(y * 200 + circleYOffset);

        if (number < 10) {
            xCordinate = Strings.toString(x * 200 + xOffset + 35);
        } else {
            xCordinate = Strings.toString(x * 200 + xOffset);
        }
        yCordinate = Strings.toString(y * 200 + yOffset);

        if (covered) {
            output = string(
                abi.encodePacked(
                    '<circle fill="#ee2d25" cx="',
                    circleX,
                    '" cy="',
                    circleY,
                    ' "r="75"></circle>'
                )
            );
        }

        output = string(
            abi.encodePacked(
                output,
                '<text x="',
                xCordinate,
                '" y="',
                yCordinate,
                '">',
                Strings.toString(number),
                "</text>"
            )
        );

        return output;
    }

    function _generatePillPattern(uint256 tokenId)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<use href="#pbg" class="rotate" transform="rotate(',
                    Strings.toString(
                        uint256(keccak256(abi.encodePacked(tokenId))) % 360
                    ),
                    ' 1100 1100)"/>'
                )
            );
    }
}