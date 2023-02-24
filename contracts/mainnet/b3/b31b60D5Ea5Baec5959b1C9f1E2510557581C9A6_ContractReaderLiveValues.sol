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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

// Contract by @backseats_eth

contract ContractReaderLiveValues {

    function tokenURI(uint256 _tokenId) public pure returns (string memory) {
        return string.concat(
            'data:application/json;base64,',
            Base64.encode(
                bytes(
                    string.concat(
                        '{"name": "Contract Reader Live Values #',
                            Strings.toString(_tokenId),
                        '",',
                        '"description": "The second feature-release NFT minted from the team at ContractReader.io (but the first one fully onchain). Contract Reader is the better way to read and understand smart contracts. This NFT commemorates the launch of the Live Onchain Values feature, where storage variabels and read-only functions are readable right inline next to the code!",',
                        '"image":"data:image/svg+xml;base64,',
                            Base64.encode(bytes(generateLiveValuesNFT())),
                        '",',
                        '"attributes": "[',
                            '{"trait_type": "Release Date", "value": "February 24, 2023"}',
                        ']" }'
                    )
                )
            )
        );
    }

    function generateLiveValuesNFT() internal pure returns (string memory) {
        return string.concat(
            '<svg width="1660" height="1300" viewBox="0 0 1660 1300" fill="none" xmlns="http://www.w3.org/2000/svg">',
                '<rect width="1660" height="1300" fill="black"/>',
                '<rect x="505" y="182" width="650" height="936" rx="6" fill="white" fill-opacity="0.1"/>',
                '<rect x="502" y="179" width="656" height="942" rx="9" stroke="white" stroke-opacity="0.25" stroke-width="6"/>',
                '<path d="M505 188C505 184.686 507.686 182 511 182H1149C1152.31 182 1155 184.686 1155 188V266H505V188Z" fill="url(#paint0_linear_260_2)"/>',
                '<path d="M505 266H1155V1112C1155 1115.31 1152.31 1118 1149 1118H511C507.686 1118 505 1115.31 505 1112V266Z" fill="black"/>',
                '<path d="M505 387H1155V1118H511C507.686 1118 505 1115.31 505 1112V387Z" fill="#0F172A"/>',
                '<rect x="505" y="387" width="650" height="77" fill="#1E3B8B"/>',
                '<rect x="517" y="403" width="126" height="8" fill="white" fill-opacity="0.7"/>',
                '<rect x="517" y="487" width="126" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="505" width="380" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="523" width="361" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="541" width="253" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="559" width="269" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="577" width="211" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="637" width="211" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="655" width="269" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="673" width="282" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="691" width="273" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="709" width="207" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="727" width="253" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="745" width="122" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="805" width="297" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="823" width="186" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="841" width="186" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="859" width="163" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="877" width="49" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="937" width="245" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="955" width="245" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="973" width="158" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="991" width="207" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="517" y="1009" width="97" height="4" fill="white" fill-opacity="0.2"/>',
                '<rect x="527" y="293" width="126" height="13" fill="white" fill-opacity="0.7"/>',
                '<circle cx="666" cy="300" r="5" fill="#2363ED"/>',
                '<path d="M665 300.5L664 299L663 300L665 302.5L669.5 299L668.5 298L665 300.5Z" fill="white"/>',
                '<rect x="526" y="316" width="144" height="17" rx="2" fill="#1E3B8B"/>',
                '<rect x="989" y="215" width="144" height="17" rx="2" fill="white" fill-opacity="0.4"/>',

                '<path d="M886 522C886 520.895 886.895 520 888 520H905V529H888C886.895 529 886 528.105 886 527V522Z" fill="#1D43D8">',
                    '<animate attributename="opacity" values="0;1;0" dur="3s" repeatcount="indefinite" fill="freeze" />',
                '</path>',
                '<rect x="905" y="520" width="19" height="9" fill="white">',
                    '<animate attributename="opacity" values="0;1;0" dur="3s" repeatcount="indefinite" fill="freeze" />',
                '</rect>',

                '<path d="M778 540C778 538.895 778.895 538 780 538H797V547H780C778.895 547 778 546.105 778 545V540Z" fill="#1D43D8">',
                    '<animate attributename="opacity" values="0;1;0" dur="3s" repeatcount="indefinite" fill="freeze" />',
                '</path>',
                '<rect x="797" y="538" width="19" height="9" fill="white">',
                    '<animate attributename="opacity" values="0;1;0" dur="3s" repeatcount="indefinite" fill="freeze" />',
                '</rect>',

                '<path d="M822 804C822 802.895 822.895 802 824 802H841V811H824C822.895 811 822 810.105 822 809V804Z" fill="#1D43D8">',
                    '<animate attributename="opacity" values="0;1;0" dur="3s" repeatcount="indefinite" fill="freeze" />',
                '</path>',
                '<rect x="841" y="802" width="19" height="9" fill="white">',
                    '<animate attributename="opacity" values="0;1;0" dur="3s" repeatcount="indefinite" fill="freeze" />',
                '</rect>',

                '<path d="M770 936C770 934.895 770.895 934 772 934H789V943H772C770.895 943 770 942.105 770 941V936Z" fill="#1D43D8">',
                    '<animate attributename="opacity" values="0;1;0" dur="3s" repeatcount="indefinite" fill="freeze" />',
                '</path>',
                '<rect x="789" y="934" width="19" height="9" fill="white">',
                    '<animate attributename="opacity" values="0;1;0" dur="3s" repeatcount="indefinite" fill="freeze" />',
                '</rect>',

                '<defs>',
                    '<linearGradient id="paint0_linear_260_2" x1="830" y1="182" x2="830" y2="266" gradientUnits="userSpaceOnUse">',
                        '<stop stop-color="#BE00F2"/>',
                        '<stop offset="0.72619" stop-color="#7403F9"/>',
                    '</linearGradient>',
                '</defs>',
            '</svg>'
        );
    }
}