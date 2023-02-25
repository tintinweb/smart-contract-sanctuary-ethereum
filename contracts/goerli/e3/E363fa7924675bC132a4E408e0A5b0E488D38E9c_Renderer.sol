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
// Copyright (c) 2018 The Officious BokkyPooBah / Bok Consulting Pty Ltd
// Copyright (c) 2022 NFTXYZ (Olivier Winkler) Added & Modified Functions

pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Strings.sol";

struct Date {
    string year;
    string month;
    string day;
    string dayOfWeek;
    string hour;
    string minute;
}

contract DateTime {
    uint256 private constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 private constant SECONDS_PER_HOUR = 60 * 60;
    uint256 private constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    function timestampToDateTime(uint256 _timestamp)
        public
        pure
        returns (Date memory)
    {
        (
            string memory year,
            string memory month,
            string memory day
        ) = _daysToDate(_timestamp / SECONDS_PER_DAY);
        uint256 secs = _timestamp % SECONDS_PER_DAY;
        uint256 _hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        uint256 _minute = secs / SECONDS_PER_MINUTE;

        string memory hour = _formatOctalNumbers(_hour);
        string memory minute = _formatOctalNumbers(_minute);
        string memory dayOfWeek = _getDayOfWeek(_timestamp);

        return Date(year, month, day, dayOfWeek, hour, minute);
    }

    function formatDate(Date memory _date) public pure returns (string memory) {
        return
            string.concat(
                _date.day,
                " ",
                _date.month,
                " ",
                _date.year,
                " ",
                _date.hour,
                ":",
                _date.minute
            );
    }

    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            string memory year,
            string memory month,
            string memory day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = Strings.toString(uint256(_year));
        month = _getMonthByNumber(uint256(_month));
        day = _formatOctalNumbers(uint256(_day));
    }

    function _formatOctalNumbers(uint256 _number)
        internal
        pure
        returns (string memory temp)
    {
        temp = Strings.toString(_number);
        if (_number < 10) temp = string.concat("0", temp);
    }

    function _getDayOfWeek(uint256 _timestamp)
        internal
        pure
        returns (string memory)
    {
        uint256 _days = _timestamp / SECONDS_PER_DAY;
        uint256 dayOfWeek = ((_days + 3) % 7) + 1;

        if (dayOfWeek == 1) return "MON";
        if (dayOfWeek == 2) return "TUE";
        if (dayOfWeek == 3) return "WED";
        if (dayOfWeek == 4) return "THU";
        if (dayOfWeek == 5) return "FRI";
        if (dayOfWeek == 6) return "SAT";
        if (dayOfWeek == 7) return "SUN";

        return "";
    }

    function _getMonthByNumber(uint256 _month)
        internal
        pure
        returns (string memory month)
    {
        if (_month == 1) return "JAN";
        if (_month == 2) return "FEB";
        if (_month == 3) return "MAR";
        if (_month == 4) return "APR";
        if (_month == 5) return "MAY";
        if (_month == 6) return "JUN";
        if (_month == 7) return "JUL";
        if (_month == 8) return "AUG";
        if (_month == 9) return "SEP";
        if (_month == 10) return "OCT";
        if (_month == 11) return "NOV";
        if (_month == 12) return "DEC";
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./SVG.sol";
import "./Utils.sol";
import "./DateTime.sol";

contract Renderer {
    function render(Date memory date) public pure returns (string memory) {
        return
            string.concat(
                prepareSVGStyle(),
                renderDayAttributes(date),
                renderClockAttributes()
            );
    }

    function prepareSVGStyle() internal pure returns (string memory) {
        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" width="1000" height="1000" style="background:#000">',
                '<defs><style>@font-face{font-family:"HelveticaNowDisplayMd"; src:url("https://nftime.vercel.app/_next/static/media/HelveticaNowDisplayMd.e2e7c552.woff2");} .container {height: 100%; display:flex; align-items:center; justify-content:center;} p {font-family:"HelveticaNowDisplayMd"; color:white; margin:0;}</style></defs>'
            );
    }

    function renderDayAttributes(Date memory date)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                getSVGPath("M0 0h1000.8v1000.8H0z"),
                getDayAttribute(":", "126", "200", "40", "720", "520"),
                getDayAttribute(date.hour, "142", "200", "200", "520", "520"),
                getDayAttribute(date.minute, "142", "200", "200", "760", "520"),
                getDayAttribute(
                    date.dayOfWeek,
                    "138",
                    "200",
                    "440",
                    "520",
                    "760"
                ),
                getDayAttribute(date.year, "142", "200", "440", "520", "40"),
                getDayAttribute(date.month, "142", "200", "440", "520", "280"),
                getDayAttribute(date.day, "360", "440", "440", "40", "40"),
                getDayAttribute(date.day, "11", "20", "20", "334", "730")
            );
    }

    function renderClockAttributes() internal pure returns (string memory) {
        return
            string.concat(
                getSVGPath(
                    "M520 620h200m40 0h200M520 860h440M520 380h440M520 140h440M40 260h440"
                ),
                getSVGPath(
                    "M278.835 918.99l-1.6-14.6m-36.1-343.4l1.6 14.6m36.1-14.6l-1.6 14.6m-36.1 343.4l1.6-14.6m-20.2-340.5l3.1 14.4m71.8 337.8l-3.1-14.4m-90-332.9l4.6 13.9m106.7 328.5l-4.5-13.9m22.1 7.2l-6-13.4m-140.5-315.6l6 13.4m173.1 296.7l-8.7-11.8m-202.9-279.4l8.6 11.9m-23.3-.1l9.8 11m231.1 256.6l-9.8-10.9m-244.4-243.3l10.9 9.8m256.6 231.1l-10.9-9.9m-268.5-216.4l11.9 8.6m279.4 203l-11.9-8.6m30.7-24l-13.4-5.9m-315.5-140.5l13.4 6m-20.2 11.6l14 4.5m328.5 106.7l-14-4.5m18.9-13.7l-14.4-3m-337.8-71.8l14.3 3m340.8 53.2l-14.6-1.5m-343.5-36.1l14.6 1.5m-14.6 36.1l14.6-1.5m343.5-36.1l-14.6 1.5m-340.5 54.7l14.3-3m337.9-71.8l-14.4 3m-333 90l14-4.5m328.5-106.7l-14 4.5m-308.3 118.4l-13.4 5.9m328.9-146.4l-13.4 6m-5.4-38.6l-11.9 8.6m-279.4 203l11.9-8.6m267.5-217.6l-10.9 9.8m-256.6 231.1l10.9-9.9m243.3-244.4l-9.8 11m-231.1 256.6l9.8-10.9m4.9 22.7l8.6-11.8m203-279.4l-8.7 11.9m-170.4 298.2l6-13.4m140.5-315.6l-6 13.4m-11.6-20.1l-4.5 13.9m-106.8 328.5l4.6-13.9m13.6 18.8l3.1-14.4m71.8-337.8l-3.1 14.4"
                ),
                getSVGPath(
                    "M364.635 739.99h75.4m-360 0h75.3m104.7 104.7v75.3m0-360v75.3m-90-51.2l37.6 65.2m104.7 181.4l37.7 65.2m-245.9-245.9l65.2 37.7m246.6 142.3l-65.3-37.6m0-104.7l65.3-37.7m-311.8 180l65.2-37.6m143-143.1l37.7-65.2m-142.4 246.6l-37.6 65.2"
                ),
                svg.g(
                    svg.prop("transform", "translate(141.12 743.15)"),
                    string.concat(
                        svg.circle(
                            string.concat(
                                svg.prop("cx", "118.9"),
                                svg.prop("cy", "-3.2"),
                                svg.prop("r", "8.8")
                            ),
                            ""
                        ),
                        getSVGPath(
                            "M102.058 154.95L118.683-3.277l1.591.167-16.625 158.23z"
                        ),
                        getSVGPath(
                            "M232.3-101.2l3.5-7.3-7.7 2.7L116.8-5.5 121-.9l111.3-100.3z"
                        ),
                        getSVGPath(
                            "M33.3-52.6l5.4 6.7L117.4-.5l3.1-5.4-78.7-45.4-8.5-1.3z"
                        ),
                        getSVGPath(
                            "M120-28.7l-2 25.4 1.6.2 3.3-25.3 1.6-15.5-3-.3-1.5 15.5z"
                        )
                    )
                ),
                getSVGPath(
                    "M960 220c0 11-9 20-20 20H540c-11 0-20-9-20-20V60c0-11 9-20 20-20h400c11 0 20 9 20 20v160zm0 240c0 11-9 20-20 20H540c-11 0-20-9-20-20V300c0-11 9-20 20-20h400c11 0 20 9 20 20v160zM720 700c0 11-9 20-20 20H540c-11 0-20-9-20-20V540c0-11 9-20 20-20h160c11 0 20 9 20 20v160zm240 0c0 11-9 20-20 20H780c-11 0-20-9-20-20V540c0-11 9-20 20-20h160c11 0 20 9 20 20v160zm0 240c0 11-9 20-20 20H540c-11 0-20-9-20-20V780c0-11 9-20 20-20h400c11 0 20 9 20 20v160zM480 460c0 11-9 20-20 20H60c-11 0-20-9-20-20V60c0-11 9-20 20-20h400c11 0 20 9 20 20v400zm0 480c0 11-9 20-20 20H60c-11 0-20-9-20-20V540c0-11 9-20 20-20h400c11 0 20 9 20 20v400z"
                ),
                getSVGPath(
                    "M350.5 745.9c0 2.2-1.8 4-4 4h-12c-2.2 0-4-1.8-4-4v-12c0-2.2 1.8-4 4-4h12c2.2 0 4 1.8 4 4v12z"
                ),
                "</svg>"
            );
    }

    function getDayAttribute(
        string memory attribute,
        string memory fontSize,
        string memory height,
        string memory width,
        string memory transformX,
        string memory transformY
    ) internal pure returns (string memory) {
        return
            string.concat(
                '<foreignObject x="',
                transformX,
                '" y="',
                transformY,
                '" height="',
                height,
                '" width="',
                width,
                '">',
                '<div class="container" xmlns="http://www.w3.org/1999/xhtml">',
                '<p style="font-size: ',
                fontSize,
                'px;">',
                attribute,
                "</p>"
                "</div>",
                "</foreignObject>"
            );
    }

    function getSVGPath(string memory d) internal pure returns (string memory) {
        return
            svg.path(
                string.concat(
                    svg.prop("fill", "none"),
                    svg.prop("stroke", "#fff"),
                    svg.prop("d", d)
                ),
                ""
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;
import "./Utils.sol";

// Core SVG utilitiy library which helps us construct
// onchain SVG's with a simple, web-like API.
library svg {
    /* MAIN ELEMENTS */
    function g(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("g", _props, _children);
    }

    function path(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("path", _props, _children);
    }

    function text(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("text", _props, _children);
    }

    function line(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("line", _props, _children);
    }

    function circle(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("circle", _props, _children);
    }

    function circle(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("circle", _props);
    }

    function rect(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("rect", _props, _children);
    }

    function rect(string memory _props) internal pure returns (string memory) {
        return el("rect", _props);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("filter", _props, _children);
    }

    function cdata(string memory _content)
        internal
        pure
        returns (string memory)
    {
        return string.concat("<![CDATA[", _content, "]]>");
    }

    /* GRADIENTS */
    function radialGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("radialGradient", _props, _children);
    }

    function linearGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("linearGradient", _props, _children);
    }

    function gradientStop(
        uint256 offset,
        string memory stopColor,
        string memory _props
    ) internal pure returns (string memory) {
        return
            el(
                "stop",
                string.concat(
                    prop("stop-color", stopColor),
                    " ",
                    prop("offset", string.concat(utils.uint2str(offset), "%")),
                    " ",
                    _props
                )
            );
    }

    function animateTransform(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("animateTransform", _props);
    }

    function image(string memory _href, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("image", string.concat(prop("href", _href), " ", _props));
    }

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
    function el(
        string memory _tag,
        string memory _props,
        string memory _children
    ) internal pure returns (string memory) {
        return
            string.concat(
                "<",
                _tag,
                " ",
                _props,
                ">",
                _children,
                "</",
                _tag,
                ">"
            );
    }

    // A generic element, can be used to construct any SVG (or HTML) element without children
    function el(string memory _tag, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return string.concat("<", _tag, " ", _props, "/>");
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_key, "=", '"', _val, '" ');
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

// Core utils used extensively to format CSS and numbers.
library utils {
    // used to simulate empty strings
    string internal constant NULL = "";

    // formats a CSS variable line. includes a semicolon for formatting.
    function setCssVar(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat("--", _key, ":", _val, ";");
    }

    // formats getting a css variable
    function getCssVar(string memory _key)
        internal
        pure
        returns (string memory)
    {
        return string.concat("var(--", _key, ")");
    }

    // formats getting a def URL
    function getDefURL(string memory _id)
        internal
        pure
        returns (string memory)
    {
        return string.concat("url(#", _id, ")");
    }

    // formats rgba white with a specified opacity / alpha
    function white_a(uint256 _a) internal pure returns (string memory) {
        return rgba(255, 255, 255, _a);
    }

    // formats rgba black with a specified opacity / alpha
    function black_a(uint256 _a) internal pure returns (string memory) {
        return rgba(0, 0, 0, _a);
    }

    // formats generic rgba color in css
    function rgba(
        uint256 _r,
        uint256 _g,
        uint256 _b,
        uint256 _a
    ) internal pure returns (string memory) {
        string memory formattedA = _a < 100
            ? string.concat("0.", utils.uint2str(_a))
            : "1";
        return
            string.concat(
                "rgba(",
                utils.uint2str(_r),
                ",",
                utils.uint2str(_g),
                ",",
                utils.uint2str(_b),
                ",",
                formattedA,
                ")"
            );
    }

    // checks if two strings are equal
    function stringsEqual(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    // returns the length of a string in characters
    function utfStringLength(string memory _str)
        internal
        pure
        returns (uint256 length)
    {
        uint256 i = 0;
        bytes memory string_rep = bytes(_str);

        while (i < string_rep.length) {
            if (string_rep[i] >> 7 == 0) i += 1;
            else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) i += 2;
            else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) i += 3;
            else if (string_rep[i] >> 3 == bytes1(uint8(0x1E)))
                i += 4;
                //For safety
            else i += 1;

            length++;
        }
    }

    // converts an unsigned integer to a string
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}