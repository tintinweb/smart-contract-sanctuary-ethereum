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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract TypeBlocksPepes {

    uint256 internal constant XSTART = 313;
    uint256 internal constant YSTART = 306;
    uint256 internal constant SPACING = 40;

    function ALPHABETPLOT(bytes1 letter) internal pure returns (uint8[20] memory) {
        if(letter == 0x41) {
            return [ 2, 3, 4, 6, 10, 11, 15, 16, 20, 21, 22, 23, 24, 25, 26, 30, 31, 35, 0, 0 ];
        } else if(letter == 0x42) {
            return [ 1, 2, 3, 4, 6, 10, 11, 15, 16, 17, 18, 19, 21, 25, 26, 30, 31, 32, 33, 34 ];
        } else if(letter == 0x43) {
            return [ 2, 3, 4, 6, 10, 11, 16, 21, 26, 30, 32, 33, 34, 0, 0, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x44) {
            return [ 1, 2, 3, 4, 6, 10, 11, 15, 16, 20, 21, 25, 26, 30, 31, 32, 33, 34, 0, 0 ];
        } else if(letter == 0x45) {
            return [ 1, 2, 3, 4, 5, 6, 11, 16, 17, 18, 19, 21, 26, 31, 32, 33, 34, 35, 0, 0 ];
        } else if(letter == 0x46) {
            return [ 1, 2, 3, 4, 5, 6, 11, 16, 17, 18, 19, 21, 26, 31, 0, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x47) {
            return [ 2, 3, 4, 6, 10, 11, 16, 21, 24, 25, 26, 30, 32, 33, 34, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x48) {
            return [ 1, 5, 6, 10, 11, 15, 16, 17, 18, 19, 20, 21, 25, 26, 30, 31, 35, 0, 0, 0 ];
        } else if(letter == 0x49) {
            return [ 2, 3, 4, 8, 13, 18, 23, 28, 32, 33, 34, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x4A) {
            return [ 2, 3, 4, 5, 9, 14, 19, 24, 26, 29, 32, 33, 0, 0, 0, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x4B) {
            return [ 1, 5, 6, 9, 11, 13, 16, 17, 21, 23, 26, 29, 31, 35, 0, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x4C) {
            return [ 1, 6, 11, 16, 21, 26, 31, 32, 33, 34, 35, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x4D) {
            return [ 1, 5, 6, 7, 9, 10, 11, 13, 15, 16, 20, 21, 25, 26, 30, 31, 35, 0, 0, 0 ];
        } else if(letter == 0x4E) {
            return [ 1, 5, 6, 7, 10, 11, 13, 15, 16, 19, 20, 21, 25, 26, 30, 31, 35, 0, 0, 0 ];
        } else if(letter == 0x4F) {
            return [ 2, 3, 4, 6, 10, 11, 15, 16, 20, 21, 25, 26, 30, 32, 33, 34, 0, 0, 0, 0 ];
        } else if(letter == 0x50) {
            return [ 1, 2, 3, 4, 6, 10, 11, 15, 16, 17, 18, 19, 21, 26, 31, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x51) {
            return [ 2, 3, 4, 6, 10, 11, 15, 16, 20, 21, 23, 25, 26, 29, 30, 32, 33, 34, 35, 0 ];
        } else if(letter == 0x52) {
            return [ 1, 2, 3, 4, 6, 10, 11, 15, 16, 17, 18, 19, 21, 23, 26, 29, 31, 35, 0, 0 ];
        } else if(letter == 0x53) {
            return [ 2, 3, 4, 6, 10, 11, 17, 18, 19, 25, 26, 30, 32, 33, 34, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x54) {
            return [ 1, 2, 3, 4, 5, 8, 13, 18, 23, 28, 33, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x55) {
            return [ 1, 5, 6, 10, 11, 15, 16, 20, 21, 25, 26, 30, 32, 33, 34, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x56) {
            return [ 1, 5, 6, 10, 11, 15, 16, 20, 21, 25, 27, 29, 33, 0, 0, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x57) {
            return [ 1, 5, 6, 10, 11, 15, 16, 20, 21, 23, 25, 26, 28, 30, 32, 34, 0, 0, 0, 0 ];
        } else if(letter == 0x58) {
            return [ 1, 5, 6, 10, 11, 15, 17, 18, 19, 21, 25, 26, 30, 31, 35, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x59) {
            return [ 1, 5, 6, 10, 11, 15, 17, 18, 19, 23, 28, 33, 0, 0, 0, 0, 0, 0, 0, 0 ];
        } else if(letter == 0x5A) {
            return [ 1, 2, 3, 4, 5, 10, 14, 18, 22, 26, 31, 32, 33, 34, 35, 0, 0, 0, 0, 0 ];
        } else {
            return [ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 ];
        }
    }

    function generateArt(bytes1[] memory letters, string memory color) external pure returns (string memory) {
        return Base64.encode(abi.encodePacked(
            '<svg ',
                'viewBox="0 0 500 500" ',
                'fill="none" xmlns="http://www.w3.org/2000/svg" ',
                'style="width:100%;background:#111;"',
            '>',
                '<rect width="500" height="500" fill="#111"/>',
                '<g><path fill="#019a02" d="M156.9,266h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C153,267.8,154.8,266,156.9,266z"/><path fill="#019a02" d="M196.9,266h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C193,267.8,194.8,266,196.9,266z"/><path fill="#019a02" d="M236.9,266h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C233,267.8,234.8,266,236.9,266z"/><path fill="#019a02" d="M276.9,266h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C273,267.8,274.8,266,276.9,266z"/><path fill="#019a02" d="M316.9,266h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C313,267.8,314.8,266,316.9,266z"/><path fill="#019a02" d="M156.9,360h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C153,361.8,154.8,360,156.9,360z"/><path fill="#019a02" d="M196.9,360h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C193,361.8,194.8,360,196.9,360z"/><path fill="#019a02" d="M236.9,360h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C233,361.8,234.8,360,236.9,360z"/><path fill="#019a02" d="M276.9,360h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C273,361.8,274.8,360,276.9,360z"/><path fill="#019a02" d="M316.9,360h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C313,361.8,314.8,360,316.9,360z"/><path fill="#019a02" d="M156.9,226h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C153,227.8,154.8,226,156.9,226z"/><path fill="#019a02" d="M196.9,226h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C193,227.8,194.8,226,196.9,226z"/><path fill="#019a02" d="M236.9,226h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C233,227.8,234.8,226,236.9,226z"/><path fill="#019a02" d="M276.9,226h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C273,227.8,274.8,226,276.9,226z"/><path fill="#019a02" d="M316.9,226h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C313,227.8,314.8,226,316.9,226z"/><path fill="#fff" d="M156.9,186h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C153,187.8,154.8,186,156.9,186z"/><path fill="#000" d="M196.9,186h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C193,187.8,194.8,186,196.9,186z"/><path fill="#019a02" d="M236.9,186h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C233,187.8,234.8,186,236.9,186z"/><path fill="#fff" d="M276.9,186h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C273,187.8,274.8,186,276.9,186z"/><path fill="#000" d="M316.9,186h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C313,187.8,314.8,186,316.9,186z"/><path fill="#fff" d="M156.9,146h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C153,147.8,154.8,146,156.9,146z"/><path fill="#000" d="M196.9,146h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C193,147.8,194.8,146,196.9,146z"/><path fill="#019a02" d="M236.9,146h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C233,147.8,234.8,146,236.9,146z"/><path fill="#fff" d="M276.9,146h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C273,147.8,274.8,146,276.9,146z"/><path fill="#000" d="M316.9,146h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C313,147.8,314.8,146,316.9,146z"/><path fill="#019a02" d="M156.9,106h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C153,107.8,154.8,106,156.9,106z"/><path fill="#019a02" d="M196.9,106h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C193,107.8,194.8,106,196.9,106z"/><path fill="#019a02" d="M236.9,106h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C233,107.8,234.8,106,236.9,106z"/><path fill="#019a02" d="M276.9,106h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C273,107.8,274.8,106,276.9,106z"/><path fill="#019a02" d="M316.9,106h26.2c2.2,0,3.9,1.8,3.9,3.9v26.2c0,2.2-1.8,3.9-3.9,3.9h-26.2c-2.2,0-3.9-1.8-3.9-3.9v-26.2 C313,107.8,314.8,106,316.9,106z"/></g>',
                generateBlocks(letters, color),
            '</svg>'
        ));
    }

    function generateBlocks(bytes1[] memory letters, string memory color) internal pure returns (bytes memory blocks) {
        for (uint256 i; i < 5; i++) {
            blocks = abi.encodePacked(
                blocks,
                '<g>',
                generateBlock(i, letters, color),
                '</g>'
            );
        }

        return blocks;
    }
    
    function generateBlock(uint256 number, bytes1[] memory letters, string memory color) internal pure returns (bytes memory typeBlock) {
        uint256 xStart = XSTART - number * SPACING;
        uint256 yStart = YSTART;
        string memory opacity = "0.09";
        uint256 count = 1;
        bytes1 letter;

        if(letters.length > 0 && number < letters.length ) {
            letter = letters[letters.length - 1 - number];
        }
        
        for (uint256 i; i < 7; i++) {
            for (uint256 j; j < 5; j++) {
                uint256 cx = xStart + (j * 7);
                uint256 cy = yStart + (i * 7);
                uint8[20] memory plot = ALPHABETPLOT(letter);
                
                for (uint256 k; k < plot.length; k++) {
                    opacity = "0.3";
                    if(0 == plot[k]) {
                        break;
                    } else if(count == plot[k]) {
                        opacity = "1";
                        break;
                    }
                }
                
                typeBlock = abi.encodePacked(
                    typeBlock,
                    '<rect x="', Strings.toString(cx), '" y="', Strings.toString(cy), '" fill="#cf0001" fill-opacity="', opacity ,'" width="6" height="6" rx=".69" ry=".69"/>'
                );
                unchecked { count++; }
            }
        }

        return typeBlock;
    }
}