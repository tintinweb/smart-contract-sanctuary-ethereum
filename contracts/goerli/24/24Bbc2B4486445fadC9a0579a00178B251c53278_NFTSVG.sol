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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

library NFTSVG {
    using Strings for uint256;

    struct coordinate {
        uint256 x;
        uint256 xdecimal;
        uint256 y;
    }

    function getBlock(coordinate memory co, uint8 blockLevel, string memory fillcolor)
        public
        pure
        returns (string memory svg)
    {
        string memory blockbg = ' class="b1"';
        if (bytes(fillcolor).length > 0) {
            blockbg = string(abi.encodePacked(' style="fill:', fillcolor, ';"'));
        }
        svg = string(
            abi.encodePacked(
                '<use width="46.188" height="40" transform="translate(',
                co.x.toString(),
                ".",
                co.xdecimal.toString(),
                " ",
                co.y.toString(),
                ')"',
                blockbg,
                ' xlink:href="#Block"/>',
                getLevelItem(blockLevel, co.x, co.y)
            )
        );
    }

    function getLevelItem(uint8 level, uint256 x, uint256 y) public pure returns (string memory) {
        bytes memory svgbytes = abi.encodePacked('<use width="');
        if (level == 1 || level == 2 || level == 11) {
            svgbytes = abi.encodePacked(
                svgbytes,
                '20.5" height="20.5" transform="translate(',
                Strings.toString(x + 13),
                " ",
                Strings.toString(y + 10)
            );
        } else if (level == 3 || level == 6 || level == 12) {
            svgbytes = abi.encodePacked(
                svgbytes,
                '21.6349" height="18.7503" transform="translate(',
                Strings.toString(x + 12),
                " ",
                Strings.toString(y + 10)
            );
        } else if (level == 4 || level == 5 || level == 7 || level == 8) {
            svgbytes = abi.encodePacked(
                svgbytes,
                '18.5" height="18.5" transform="translate(',
                Strings.toString(x + 14),
                " ",
                Strings.toString(y + 11)
            );
        } else if (level == 9) {
            svgbytes = abi.encodePacked(
                svgbytes,
                '6.3999" height="5.4" transform="translate(',
                Strings.toString(x + 20),
                " ",
                Strings.toString(y + 18)
            );
        } else if (level == 10) {
            svgbytes = abi.encodePacked(
                svgbytes, '8" height="8" transform="translate(', Strings.toString(x + 19), " ", Strings.toString(y + 16)
            );
        }
        return string(abi.encodePacked(svgbytes, ')" xlink:href="#Lv', uint256(level).toString(), '" />'));
    }

    function ringBgColor(uint256 ringNum) public pure returns (string memory) {
        string[61] memory bgcolors = [
            "#c7a037",
            "#c7a037",
            "#c7a037",
            "#c7a037",
            "#c7a037",
            "#c7a037",
            "#c7a037",
            "#E8F3D6",
            "#FCF9BE",
            "#FFDCA9",
            "#FAAB78",
            "#FEFCF3",
            "#F5EBE0",
            "#F0DBDB",
            "#DBA39A",
            "#65647C",
            "#8B7E74",
            "#C7BCA1",
            "#F1D3B3",
            "#FBFACD",
            "#DEBACE",
            "#BA94D1",
            "#7F669D",
            "#F7A4A4",
            "#FEBE8C",
            "#FFFBC1",
            "#B6E2A1",
            "#E97777",
            "#FF9F9F",
            "#FCDDB0",
            "#7F7F7F",
            "#7F7F7F",
            "#7F7F7F",
            "#7F7F7F",
            "#7F7F7F",
            "#FFFAD7",
            "#FFE1E1",
            "#90A17D",
            "#829460",
            "#EEEEEE",
            "#B7C4CF",
            "#FFB9B9",
            "#FFDDD2",
            "#FFACC7",
            "#FF8DC7",
            "#FF8787",
            "#F8C4B4",
            "#E5EBB2",
            "#BCE29E",
            "#FDFDBD",
            "#C8FFD4",
            "#B8E8FC",
            "#B1AFFF",
            "#FFF8EA",
            "#9E7676",
            "#815B5B",
            "#594545",
            "#FAF7F0",
            "#CDFCF6",
            "#BCCEF8",
            "#554994"
        ];
        return bgcolors[ringNum];
    }

    function ringBorderColor(uint256 ringNum) public pure returns (string memory) {
        string memory bordcolor = "#F2F2F2";
        if (ringNum < 7) {
            bordcolor = "#FFD965";
        } else if (ringNum > 29 && ringNum < 35) {
            bordcolor = "#595959";
        }
        return bordcolor;
    }

    function getImage(string memory defs, string memory background, string memory blocks)
        public
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                '<?xml version="1.0" encoding="UTF-8"?><svg xmlns="http://www.w3.org/2000/svg" ',
                'xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 500 500">',
                defs,
                background,
                blocks,
                "</svg>"
            )
        );
    }

    function generateDefs(string memory ringbordercolor, string memory ringbgcolor)
        public
        pure
        returns (string memory svg)
    {
        svg = string(
            bytes.concat(
                abi.encodePacked(
                    "<defs><style>.c1 {font-size: 24px;}.c1,.c2 {font-family: ArialMT, Arial;isolation: isolate;}",
                    ".c2 {font-size: 14px;}.c3 {stroke-width: 0.25px;}.c3,.c4 {stroke: #000;stroke-miterlimit: 10;}",
                    ".c4 {fill: none;stroke-width: 0.5px;}.c5 {fill: ",
                    ringbordercolor,
                    ";}.c6 {fill: url(#background);}.b1 {fill: #fff;}</style>",
                    '<symbol id="Block" viewBox="0 0 46.188 40"><polygon class="c3" points="34.5688 .125 11.6192 .125 .1443 20 11.6192 39.875 34.5688 39.875 46.0437 20 34.5688 .125"/></symbol>',
                    '<symbol id="Lv1" viewBox="0 0 20.5 20.5"><circle class="c4" cx="10.25" cy="10.25" r="10"/></symbol>',
                    '<symbol id="Lv2" viewBox="0 0 20.5 20.5"><circle class="c4" cx="10.25" cy="10.25" r="10"/><circle class="c4" cx="10.25" cy="10.25" r="4"/></symbol>',
                    '<symbol id="Lv3" viewBox="0 0 21.6349 18.7503"><polygon class="c4" points="10.9588 .5003 .4357 18.5003 21.205 18.5003 10.9588 .5003" /></symbol>',
                    '<symbol id="Lv4" viewBox="0 0 18.5 18.5"><rect class="c4" x=".25" y=".25" width="18" height="18" /></symbol>'
                ),
                abi.encodePacked(
                    '<symbol id="Lv5" viewBox="0 0 18.5 18.5"><rect class="c4" x=".25" y=".25" width="18" height="18" /><circle class="c4" cx="9.25" cy="9.25" r="4" /></symbol>',
                    '<symbol id="Lv6" viewBox="0 0 21.6349 18.7503"><polygon class="c4" points="10.8146 9.0862 7.6146 14.4862 14.0146 14.4862 10.8146 9.0862" /><polygon class="c4" points="10.6761 .5003 .43 18.5003 21.1992 18.5003 10.6761 .5003" /></symbol>',
                    '<symbol id="Lv7" viewBox="0 0 18.5 18.5"><rect class="c4" x=".25" y=".25" width="18" height="18" /><polygon class="c4" points="9.25 6.55 6.05 11.95 12.45 11.95 9.25 6.55" /></symbol>',
                    '<symbol id="Lv8" viewBox="0 0 18.5 18.5"><rect class="c4" x="5.65" y="5.65" width="7.2" height="7.2" /><rect class="c4" x=".25" y=".25" width="18" height="18" /></symbol>',
                    '<symbol id="Lv9" viewBox="0 0 6.3999 5.4"><polygon points="3.3032 0 0 5.4 6.3999 5.4 3.3032 0" /></symbol>',
                    '<symbol id="Lv10" viewBox="0 0 8 8"><circle cx="4" cy="4" r="4" /></symbol>',
                    '<symbol id="Lv11" viewBox="0 0 20.5 20.5"><circle class="c4" cx="10.25" cy="10.25" r="10"/>',
                    '<g><circle cx="10.25" cy="10.25" r="4" /><animate attributeName="opacity" values="1;0;1" dur="3.85s" begin="0s" repeatCount="indefinite"/></g></symbol>',
                    '<symbol id="Lv12" viewBox="0 0 21.6349 18.7503"><g><polygon points="10.9236 9.3759 7.6204 14.7759 14.0204 14.7759 10.9236 9.3759" /><animate attributeName="opacity" values="1;0;1" dur="3.85s" begin="0s" repeatCount="indefinite"/></g>',
                    '<polygon class="c4" points="10.9588 .5003 .4357 18.5003 21.205 18.5003 10.9588 .5003" /></symbol>'
                ),
                abi.encodePacked(
                    '<linearGradient id="background" x1="391.1842" y1="434.6524" x2="107.8509" y2="-56.0954" gradientTransform="translate(0 440.1141) scale(1 -1)" gradientUnits="userSpaceOnUse">',
                    '<stop offset=".03" stop-color="',
                    ringbgcolor,
                    '" stop-opacity=".6" /><stop offset=".5" stop-color="',
                    ringbgcolor,
                    '" /><stop offset=".96" stop-color="',
                    ringbgcolor,
                    '" stop-opacity=".2" /></linearGradient></defs>'
                )
            )
        );
    }

    function generateBackground(uint256 id, string memory coordinateStr) public pure returns (string memory svg) {
        svg = string(
            abi.encodePacked(
                '<g><rect class="c6" width="500" height="500" /><path class="c5" d="M490,10V490H10V10H490m10-10H0V500H500V0h0Z" />',
                '<text class="c1" transform="translate(30 46.4014)"><tspan>MOPN PASS</tspan></text>',
                '<text class="c1" transform="translate(470 46.4014)" text-anchor="end"><tspan>#',
                id.toString(),
                '</tspan></text><text class="c2" transform="translate(30 475.4541)"><tspan>$ Energy 0</tspan>',
                '</text><text class="c2" transform="translate(470 475.4542)" text-anchor="end"><tspan>',
                coordinateStr,
                "</tspan></text></g>"
            )
        );
    }

    function generateBlocks(uint8[] memory blockLevels) public pure returns (string memory svg) {
        bytes memory output;
        uint256 ringNum = 0;
        uint256 ringPos = 1;
        uint256 cx = 226;
        uint256 cxdecimal = 906;
        uint256 cy = 230;
        coordinate memory co = coordinate(226, 906, 230);

        for (uint256 i = 0; i < blockLevels.length; i++) {
            output = abi.encodePacked(output, getBlock(co, blockLevels[i], ""));

            if (ringPos >= ringNum * 6) {
                ringPos = 1;
                ringNum++;
                if (ringNum > 5) {
                    break;
                }
                co.x = cx;
                co.xdecimal = cxdecimal;
                co.y = cy - 40 * ringNum;
            } else {
                uint256 side = Math.ceilDiv(ringPos, ringNum);
                if (side == 1) {
                    co.xdecimal += 641;
                    if (co.xdecimal > 1000) {
                        co.x += 35;
                        co.xdecimal -= 1000;
                    } else {
                        co.x += 34;
                    }
                    co.y += 20;
                } else if (side == 2) {
                    co.y += 40;
                } else if (side == 3) {
                    if (co.xdecimal < 641) {
                        co.xdecimal += 359;
                        co.x -= 35;
                    } else {
                        co.xdecimal -= 641;
                        co.x -= 34;
                    }
                    co.y += 20;
                } else if (side == 4) {
                    if (co.xdecimal < 641) {
                        co.xdecimal += 359;
                        co.x -= 35;
                    } else {
                        co.xdecimal -= 641;
                        co.x -= 34;
                    }
                    co.y -= 20;
                } else if (side == 5) {
                    co.y -= 40;
                } else if (side == 6) {
                    co.xdecimal += 641;
                    if (co.xdecimal > 1000) {
                        co.x += 35;
                        co.xdecimal -= 1000;
                    } else {
                        co.x += 34;
                    }
                    co.y -= 20;
                }
                ringPos++;
            }
        }

        svg = string(abi.encodePacked("<g>", output, "</g>"));
    }
}