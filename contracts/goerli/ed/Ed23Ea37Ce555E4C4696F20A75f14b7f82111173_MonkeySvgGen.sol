/**
 *Submitted for verification at Etherscan.io on 2023-02-11
*/

// File: contracts/TnmtLibrary.sol

// SPDX-License-Identifier: MIT


/// @title TNMT Structs

pragma solidity ^0.8.18;

library ITnmtLibrary {

    struct Tnmt {
        uint256 auctionId;
        uint256 monkeyId;
        uint8 noColors;
        ColorDec[11] colors;
        string evento;
        uint8 rotations;
        bool hFlip;
        bool vFlip;
        bool updated;
    }

    struct Attributes {
        uint256 auctionId;
        uint256 monkeyId;
        uint8 noColors;
        uint8 rotations;
        bool hFlip;
        bool vFlip;
        string evento;
    }

    struct Edit {
        uint256 auctionId;
        uint256 monkeyId;
        uint8 manyEdits;
        uint8 rotations;
        ColorDec[3] colors;
        address editor;
    }

    struct Bid {
        address bidder;
        uint256 amount;
    }

    struct ColorDec {
        uint8 colorId;
        uint8 color_R;
        uint8 color_G;
        uint8 color_B;
        uint8 color_A;
    }

}
// File: @openzeppelin/contracts/utils/math/Math.sol


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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Base64.sol


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

// File: contracts/MonkeySvgGen.sol



///@title The NFT Monkey Theorem ERC-721 token

pragma solidity ^0.8.18;




contract MonkeySvgGen {

    /// @notice prbSqrt Function and notes from https://github.com/PaulRBerg/prb-math :

    /// @notice Calculates the square root of x, rounding down if x is not a perfect square.
    /// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
    /// Credits to OpenZeppelin for the explanations in code comments below.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The uint256 number for which to calculate the square root.
    /// @return result The result as an uint256.
    function prbSqrt(uint256 x) public pure returns (uint256 result) {
        if (x == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of x.
        //
        // We know that the "msb" (most significant bit) of x is a power of 2 such that we have:
        //
        // $$
        // msb(x) <= x <= 2*msb(x)$
        // $$
        //
        // We write $msb(x)$ as $2^k$ and we get:
        //
        // $$
        // k = log_2(x)
        // $$
        //
        // Thus we can write the initial inequality as:
        //
        // $$
        // 2^{log_2(x)} <= x <= 2*2^{log_2(x)+1} \\
        // sqrt(2^k) <= sqrt(x) < sqrt(2^{k+1}) \\
        // 2^{k/2} <= sqrt(x) < 2^{(k+1)/2} <= 2^{(k/2)+1}
        // $$
        //
        // Consequently, $2^{log_2(x) /2}` is a good first approximation of sqrt(x) with at least one correct bit.
        uint256 xAux = uint256(x);
        result = 1;
        if (xAux >= 2 ** 128) {
            xAux >>= 128;
            result <<= 64;
        }
        if (xAux >= 2 ** 64) {
            xAux >>= 64;
            result <<= 32;
        }
        if (xAux >= 2 ** 32) {
            xAux >>= 32;
            result <<= 16;
        }
        if (xAux >= 2 ** 16) {
            xAux >>= 16;
            result <<= 8;
        }
        if (xAux >= 2 ** 8) {
            xAux >>= 8;
            result <<= 4;
        }
        if (xAux >= 2 ** 4) {
            xAux >>= 4;
            result <<= 2;
        }
        if (xAux >= 2 ** 2) {
            result <<= 1;
        }

        // At this point, `result` is an estimation with at least one bit of precision. We know the true value has at
        // most 128 bits, since  it is the square root of a uint256. Newton's method converges quadratically (precision
        // doubles at every iteration). We thus need at most 7 iteration to turn our partial result with one bit of
        // precision into the expected uint128 result.
        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;

            // Round down the result in case x is not a perfect square.
            uint256 roundedDownResult = x / result;
            if (result >= roundedDownResult) {
                result = roundedDownResult;
            }
        }
    }
    /**
     * Min value 
     */
    function min(uint256 a, uint256 b) public pure returns (uint256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    /**
     * Max value 
     */
    function max(uint256 a, uint256 b) public pure returns (uint256) {
        if (a >= b) {
            return a;
        } else {
            return b;
        }
    }

    /**
     * @notice Compares two colors and returns the dif value
     */
    function colorDif(ITnmtLibrary.ColorDec memory _colorOne, ITnmtLibrary.ColorDec memory _colorTwo) public pure returns (uint) {
        uint rDif = max(_colorOne.color_R, _colorTwo.color_R) - min(_colorOne.color_R, _colorTwo.color_R);
        uint gDif = max(_colorOne.color_G, _colorTwo.color_G) - min(_colorOne.color_G, _colorTwo.color_G);
        uint bDif = max(_colorOne.color_B, _colorTwo.color_B) - min(_colorOne.color_B, _colorTwo.color_B);
        uint difSquared = rDif * rDif + gDif * gDif + bDif * bDif;
        return prbSqrt(difSquared);
    }


    /**
     *   @notice At least one color must be different enough
     **/
    function editColorsAreValid(uint256 minColorDifValue, uint8 _manyEdits, ITnmtLibrary.ColorDec[3] memory _colors, ITnmtLibrary.ColorDec[11] memory _tnmtColors) public pure returns(bool) {

        bool valid = false;

        for (uint c = 0; c < _manyEdits; c++) {

            if( colorDif(_colors[c], _tnmtColors[_colors[c].colorId]) >= minColorDifValue ) {
                valid = true;
            }
        }

        return valid;
    }

    function ColorDecToColorString(ITnmtLibrary.ColorDec memory color) public pure returns (bytes memory) {
        bytes memory str = abi.encodePacked(
                Strings.toString(color.color_R),
                ",",
                Strings.toString(color.color_G),
                ",",
                Strings.toString(color.color_B),
                ", 1"
                );

        return str;
    }

    /**
     * @notice Tnmt SVG code generator
     */
    function svgCode(
        ITnmtLibrary.Attributes memory attrbts,
        ITnmtLibrary.ColorDec[11] memory tokenColors,
        uint8[1024] memory pixls,
        ITnmtLibrary.Edit memory _edit ) public pure returns (bytes memory) {
        
        bytes memory attributes = abi.encodePacked(
            "{\"name\": \"TNMT #",
            Strings.toString(attrbts.auctionId),
            "_",
            Strings.toString(attrbts.monkeyId),
            "\",\"external_url\": \"https://TheNFTMonkeyTheorem.io/stuffs?auctionId=",
            Strings.toString(attrbts.auctionId),
            "&monkeyId=",
           Strings.toString( attrbts.monkeyId),
           "&rots=",
           Strings.toString(attrbts.rotations),
            "\",\"description\":\"The NFT Monkey Theorem is a one-of-a-kind-ish 32x32 pixel randomized NFT project that combines",
            " creativity, all RGB colors, pixels and the excitement of owning a rare piece of digital art drawn by pure chance.",
            " 2000 new posibilities out for auction every 24 hours.",
            " Edit up to 3 colors of any original, if sold you earn a commission! Have fun! n_n\"");

        attributes = abi.encodePacked(
            attributes,
            ", \"attributes\":[{\"display_type\":\"number\",\"trait_type\":",
            "\"Monkey Id #\",\"value\":\"",
            Strings.toString(attrbts.monkeyId),
            "\"},{\"display_type\":\"number\",\"trait_type\":",
            "\"Rotations\",\"value\":\"",
            Strings.toString(attrbts.rotations),
            "\"}"
            );

        if(_edit.editor != address(0)) {
            string memory editorAddress = Strings.toHexString(uint256(uint160(_edit.editor)),20);
            attributes = abi.encodePacked(
                attributes,
                ",{\"trait_type\":\"Type\",\"value\":\"Edited\"}",
                ",{\"trait_type\":\"Colors Edited\",\"value\":\"",
                Strings.toString(_edit.manyEdits),"\"}",
                ",{\"display_type\":\"string\",\"trait_type\":\"Editor\",\"value\":\"",
                editorAddress,
                "\"}");
        } else {
            attributes = abi.encodePacked(
                attributes,
                ",{\"trait_type\":\"Type\",\"value\":\"Original\"}");
        }
        
        bytes[] memory colorStrs = new bytes[](11);
        
        if(keccak256(abi.encodePacked(attrbts.evento)) != keccak256(abi.encodePacked(""))) {
            attributes = abi.encodePacked(
                attributes,
                ",{\"display_type\":\"string\",\"trait_type\":",
                "\"Evento\",\"value\":\"",
                attrbts.evento,
                "\"}"
                );
            colorStrs[10] = ColorDecToColorString(tokenColors[10]);
        }
        

        attributes = abi.encodePacked(
                attributes,
                ",{\"trait_type\":\"No. Colors\",\"value\":\"",
                Strings.toString(attrbts.noColors),
                "\"}");

        if(attrbts.hFlip) {
            attributes = abi.encodePacked(
                attributes,
                ",{\"value\":\"Horizontal Mirror\"}");
        }

        if(attrbts.vFlip) {
            attributes = abi.encodePacked(
                attributes,
                ",{\"value\":\"Vertical Mirror\"}");
        }

        attributes = abi.encodePacked(
            attributes,
            "],\"image\":\"data:image/svg+xml;base64,");

        uint8 rots = attrbts.rotations * 25;

        bytes[] memory cPths = new bytes[](11);
        uint8 color = 0;


        for (uint8 i = 0; i < attrbts.noColors; i++) {
            colorStrs[i] = ColorDecToColorString(tokenColors[i]);
        }

        if(keccak256(abi.encodePacked(attrbts.evento)) != keccak256(abi.encodePacked(""))) {
            colorStrs[10] = ColorDecToColorString(tokenColors[10]);
        }

        for (uint8 i = 0; i < attrbts.noColors; i++) {
            if(_edit.editor != address(0) && color < _edit.manyEdits){
                if(i == _edit.colors[color].colorId){
                    colorStrs[i] = ColorDecToColorString(_edit.colors[i]);
                    color++;
                }
            }
            cPths[i] = abi.encodePacked(
                "<path style=\"stroke-width:16;stroke:rgba(",
                colorStrs[i],
                ")\" d=\""
            );
        }

        
        if(keccak256(abi.encodePacked(attrbts.evento)) != keccak256(abi.encodePacked(""))) {
            cPths[10] = abi.encodePacked(
                "<path style=\"stroke-width:16;stroke:rgba(",
                colorStrs[10],
                ")\" d=\""
            );
        }

        bytes memory svgStr = abi.encodePacked(
            "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"512\" height=\"512\" viewBox=\"0 0 512 512\" style=\"background-color:rgba(42,45,58,1); transform: rotate(.",
            Strings.toString(rots),
            "turn)\" shape-rendering=\"crispEdges\"> "
        );


        uint256 pixel = 0;
        color = 0;

        bytes memory posStr = "";
        bytes[512] memory xPosStrs; 

        for (uint xPos = 0; xPos < 512; xPos += 16) {
            xPosStrs[xPos]=abi.encodePacked("M",Strings.toString(xPos));
        }

        for (uint yPos = 8; yPos < 512; yPos += 16) {
            posStr = abi.encodePacked(" ", Strings.toString(yPos), "h16");

            for (uint xPos = 0; xPos < 512; xPos += 16) {
                color = pixls[pixel];           
                cPths[color] = abi.encodePacked(
                    cPths[color],
                    xPosStrs[xPos],
                    posStr
                );
                pixel++;
            }
        }

        for (uint8 c = 0; c < attrbts.noColors; c++) {
            svgStr = abi.encodePacked(
                svgStr,
                cPths[c],
                "\"/>");
        }

        if(keccak256(abi.encodePacked(attrbts.evento)) != keccak256(abi.encodePacked(""))) {
            svgStr = abi.encodePacked(
                svgStr,
                cPths[10],
                "\"/>");
        }
        svgStr = abi.encodePacked(svgStr,"</svg>");
        
        return abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        attributes,
                        Base64.encode(svgStr),
                        "\"}"
                    )
                )
            );

    }
}