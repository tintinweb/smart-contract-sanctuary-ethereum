//SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

pragma solidity 0.8.12;

contract TypeConversion {
    function uint2hexstr(uint i) public pure returns (string memory) {
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j = j >> 4;
        }
        uint mask = 15;
        bytes memory bstr = new bytes(length);
        uint k = length;
        while (i != 0) {
            uint curr = (i & mask);
            bstr[--k] = curr > 9 ?
                bytes1(uint8(55 + curr)) :
                bytes1(uint8(48 + curr)); // 55 = 65 - 10
            i = i >> 4;
        }
        return string(bstr);
    }
}

contract SVGCreator {
    function returnSVG() public view returns (string memory){
        bytes memory svgImage = abi.encodePacked(
            '<svg version="1.1" id="Layers" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"',
            'viewBox="0 0 595.3 841.9" style="enable-background:new 0 0 595.3 841.9;" xml:space="preserve">',
            '<style type="text/css">',
            '*{stroke-width:4.252;stroke-linejoin:round;stroke-miterlimit:11.3386;}',
            '.st0{fill:#B9CEB8;stroke:#B9C0A5}',
            '.st1{fill:#E1D0A5;stroke:#CFA98B}',
            '.st2{fill:#CFA8D3;stroke:#55AFFF}',
            '.st3{fill:#55A9BE;stroke:#FFFEB8}',
            '.st4{fill:#FFFFFF;stroke:#7BA71F}',
            '.st5{fill:#7BA71F;stroke:#809884}',
            '.st6{fill:#809BBC;stroke:#88B272}',
            '.st7{fill:#88B884;stroke:#CA7C6F}',
            '.st8{fill:#CA7272;stroke:#CDAE1D}',
            '.st9{fill:#CDAC6F;stroke:#C6F8D3}',
            '</style>',
            '<rect id="bg" x="-15.4" y="-4.4" class="st0" width="656.3" height="857.8"/>',
            '<rect id="face" x="139.2" y="161.2" class="st1" width="302.4" height="447.3"',
            'transform="translate(0,0) rotate(0,300,380)"/>',
            '<g id="cheeks">',
            '<path id="cheek_r" class="st2" d="M335.1,339.8l78,53.8l102.2-105.4L436,570.5L335.1,339.8z"',
            'transform="rotate(0,380,455)"/>',
            '<path id="cheek_l" class="st2" d="M105,416.8c-7.8-16.5,51.5,23.1,88.9,5.4s52.9-92.7,60.7-76.2s7.9,124.4-29.5,142.1C187.7,505.8,112.8,433.2,105,416.8L105,416.8z"',
            'transform="rotate(0,150,460)"/>',
            '</g>',
            '<path id="nose" class="st3" d="M248.7,133.4c0,7.1,6.2,315,6.2,315s132.2-36.5,133-39.9S248.7,133.4,248.7,133.4L248.7,133.4z"',
            'transform="rotate(0,280,280)"/>',
            '<g id="eyes">',
            '<g transform="rotate(0,200,330)">',
            '<path id="eye_l" class="st4" d="M88.6,331.1c36.4-23.2,72.7-46.3,110-46.4s75.5,22.9,113.7,46c-38.7,21.9-77.5,43.9-114.7,44C154.9,367.4,119.1,345.6,88.6,331.1L88.6,331.1z"/>',
            '<ellipse id="pupil_l" class="st5" cx="199.5" cy="313.7" rx="30.7" ry="27.8"',
            'transform="translate(0,0)"/>',
            '<path id="eyelid_l_t" class="st7" d="M88.6,331.1l112.1-95.5l113.1,94.3c-37.1-11.3-74.2-22.6-111.8-22.4C164.6,307.7,126.6,319.4,88.6,331.1L88.6,331.1z"',
            'transform="translate(0,0)"/>',
            '<path id="eyelid_l_b" class="st7" d="M313,332.1l-108.7,97.2l-115.9-97c38.1,12.2,76.1,24.4,113.6,24.4S276.2,344.3,313,332.1L313,332.1z"',
            'transform="translate(0,0)"/>',
            '</g>',
            '<g transform="rotate(0,390,250)">',
            '<path id="eye_r" class="st4" d="M282.5,268.3c-0.1-20.8,53.1-41.1,108.2-41.2c55.1-0.1,111.9,20,112,40.8s-56.7,42.2-111.8,42.3C335.9,310.2,282.6,289,282.5,268.3L282.5,268.3z"/>',
            '<ellipse id="pupil_r" class="st5" cx="389.9" cy="256" rx="29.6" ry="27.4"',
            'transform="translate(0,0)"/>',
            '<path id="eyelid_r_t" class="st6" d="M271.4,258.5c-0.4-15.9,57.9-65.8,117.4-65.8s119.9,50,120.4,65.9c0.4,15.9-59.2-2.4-118.6-2.5C331.1,256.1,271.8,274.4,271.4,258.5L271.4,258.5z"',
            'transform="translate(0,0)"/>',
            '<path id="eyelid_r_b" class="st6" d="M510,274.4c0.4,15.9-57.9,65.8-117.4,65.7c-59.5-0.1-119.9-50.1-120.3-66c-0.4-15.9,59.2,2.5,118.6,2.6C450.3,276.7,509.6,258.5,510,274.4L510,274.4z"',
            'transform="translate(0,0)"/>',
            '</g>',
            '</g>',
            '<path id="mouth" class="st8" d="M109.7,600.8c3,0.5,215.8-33.3,215.8-33.3l140.9,37l-164.8,64.7L109.7,600.8z"',
            'transform="rotate(0,280,550)"/>',
            '<g id="lips">',
            '<path id="lips_t" class="st9" d="M107.4,600.1l44.6-47.8l44.6-47.8l83.4,69.3l75.5-75.2l112,105c-32.2-8.5-64.4-17-124.4-17.6S195.2,592.8,107.4,600.1L107.4,600.1z"',
            'transform="rotate(0,300,600)"/>',
            '<path id="lips_b" class="st9" d="M467.3,606.1C409.7,645.3,352,684.5,292,683.7c-60-0.9-122.3-41.8-184.7-82.8c52.1,15.9,104.2,31.8,164.2,32.7C331.6,634.5,399.4,620.3,467.3,606.1L467.3,606.1z"',
            'transform="rotate(0,300,600)"/>',
            '</g>',
            '</svg>'
        );
        return string.concat("data:image/svg;base64,",Base64.encode(svgImage));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
        return a >= b ? a : b;
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
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

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
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

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