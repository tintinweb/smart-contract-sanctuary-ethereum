// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IMetadataRenderer} from "https://github.com/ourzora/zora-drops-contracts/blob/main/src/interfaces/IMetadataRenderer.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {SvgBuilder} from "./SvgBuilder.sol";

/// @notice Custom metadata renderer template
contract MyMetadataRenderer is SvgBuilder, IMetadataRenderer {

    /// @notice checks if provided number is even
    /// @param number uint256 value
    function isEven(uint256 number) internal pure returns (bool) {
        if (number % 2 == 0) {
            return true;
        } else {
            return false;
        }
    }

    /// @notice returns even/odd string
    /// @param number uint256 value
    function propertyGenerator(uint256 number) internal pure returns (string memory) {
        if (isEven(number) == true ) {
            return "even";
        } else {
            return "odd";
        }
    }

    /// @notice returns encoded svg depeneding on input number
    /// @param number uint256 value
    function svgGenerator(uint256 number) internal pure returns (string memory) {
        if (isEven(number) == true) {
            return evenSvg();
        } else {
            return oddSvg();
        }
    }

    /// @notice generates base64 encoded tokenURI JSON metadata
    /// @param tokenId uint256 value
    function constructTokenURI(uint256 tokenId) internal pure returns (string memory) {

        // generate + copy base64 encoded svg to memory
        string memory image = string(
            abi.encodePacked(Base64.encode(bytes(svgGenerator(tokenId))))
        );

        // constructs + returns base64 encoded metadata JSON
        return 
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    '{"name": "',
                                    "Even or Odd",
                                    ' #',
                                    abi.encodePacked(
                                        Strings.toString(tokenId)
                                    ),
                                    '","image": "data:image/svg+xml;base64,',
                                    abi.encodePacked(string(image)),
                                    '","properties": ',
                                    "{type: ",
                                    propertyGenerator(tokenId),
                                    '}'"}"
                                )                                
                            )
                        )
                    )
                )
            );
    }

    // /// @notice generates base64 encoded contractURI JSON metadata
    // function constructContractURI() internal pure returns (string memory) {

    //     // generate + copy base64 encoded svg to memory
    //     string memory image = string(
    //         abi.encodePacked(Base64.encode(bytes(svgGenerator(tokenId))))
    //     );

    //     // constructs + returns base64 encoded metadata JSON
    //     return 
    //         string(
    //             abi.encodePacked(
    //                 "data:application/json;base64,",
    //                 Base64.encode(
    //                     bytes(
    //                         string(
    //                             abi.encodePacked(
    //                                 '{"name": "',
    //                                 "Even or Odd",
    //                                 ' #',
    //                                 abi.encodePacked(
    //                                     Strings.toString(tokenId)
    //                                 ),
    //                                 '","image": "data:image/svg+xml;base64,',
    //                                 abi.encodePacked(string(image)),
    //                                 '","properties": ',
    //                                 "{type: ",
    //                                 propertyGenerator(tokenId),
    //                                 '}'"}"
    //                             )                                
    //                         )
    //                     )
    //                 )
    //             )
    //         );
    // }    

    function initializeWithData(bytes memory data) external {}

    function contractURI() public view returns (string memory) {
        return "hi";
    }

    /// @notice returns base64 encoded tokenURI JSON metadata for given tokenId
    /// @param tokenId uint256 value
    function tokenURI(uint256 tokenId) public view returns (string memory) {
        return constructTokenURI(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

/// @notice Helper contract for generating onchain svgs
contract SvgBuilder {

    /// @notice returns abi.encoded svg that spells "odd"
    function oddSvg() internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<svg width="361.784375px" height="206.6px" xmlns="http://www.w3.org/2000/svg" viewBox="69.1078125 -28.299999999999997 361.784375 206.6" style="background: rgb(29, 14, 11);" preserveAspectRatio="xMidYMid"><defs><filter id="editing-metal-beveled"><feGaussianBlur stdDeviation="4" in="SourceAlpha" result="blur"></feGaussianBlur><feSpecularLighting surfaceScale="5" specularConstant="0.8" specularExponent="7.5" lighting-color="#b0b2ff" in="blur" result="specular"><fePointLight x="-250" y="-50" z="300"></fePointLight></feSpecularLighting><feComposite operator="in" in="specular" in2="SourceAlpha" result="comp"></feComposite><feComposite in="SourceGraphic" in2="comp" operator="arithmetic" k1="0" k2="1" k3="1" k4="0"></feComposite></filter></defs><g filter="url(#editing-metal-beveled)"><g transform="translate(124.34499025344849, 116.13000345230103)"><path d="M43.51 1.58L43.51 1.58Q32.20 1.58 23.33-3.50L23.33-3.50L23.33-3.50Q14.46-8.59 9.49-17.91L9.49-17.91L9.49-17.91Q4.52-27.23 4.52-39.55L4.52-39.55L4.52-39.55Q4.52-51.87 9.49-61.19L9.49-61.19L9.49-61.19Q14.46-70.51 23.33-75.60L23.33-75.60L23.33-75.60Q32.20-80.68 43.51-80.68L43.51-80.68L43.51-80.68Q54.80-80.68 63.68-75.60L63.68-75.60L63.68-75.60Q72.55-70.51 77.52-61.19L77.52-61.19L77.52-61.19Q82.49-51.87 82.49-39.55L82.49-39.55L82.49-39.55Q82.49-27.23 77.52-17.91L77.52-17.91L77.52-17.91Q72.55-8.59 63.68-3.50L63.68-3.50L63.68-3.50Q54.80 1.58 43.51 1.58L43.51 1.58ZM43.51-8.81L43.51-8.81Q52.32-8.81 58.53-12.83L58.53-12.83L58.53-12.83Q64.75-16.84 67.86-23.79L67.86-23.79L67.86-23.79Q70.96-30.74 70.96-39.55L70.96-39.55L70.96-39.55Q70.96-48.36 67.86-55.31L67.86-55.31L67.86-55.31Q64.75-62.26 58.53-66.27L58.53-66.27L58.53-66.27Q52.32-70.29 43.51-70.29L43.51-70.29L43.51-70.29Q34.69-70.29 28.48-66.27L28.48-66.27L28.48-66.27Q22.26-62.26 19.15-55.31L19.15-55.31L19.15-55.31Q16.05-48.36 16.05-39.55L16.05-39.55L16.05-39.55Q16.05-30.74 19.15-23.79L19.15-23.79L19.15-23.79Q22.26-16.84 28.48-12.83L28.48-12.83L28.48-12.83Q34.69-8.81 43.51-8.81L43.51-8.81ZM96.05 0L96.05-79.10L125.32-79.10L125.32-79.10Q136.84-79.10 145.77-74.41L145.77-74.41L145.77-74.41Q154.70-69.72 159.67-60.74L159.67-60.74L159.67-60.74Q164.64-51.75 164.64-39.55L164.64-39.55L164.64-39.55Q164.64-27.35 159.67-18.36L159.67-18.36L159.67-18.36Q154.70-9.38 145.77-4.69L145.77-4.69L145.77-4.69Q136.84 0 125.32 0L125.32 0L96.05 0ZM106.79-9.72L125.32-9.72L125.32-9.72Q138.54-9.72 145.71-17.80L145.71-17.80L145.71-17.80Q152.89-25.88 152.89-39.55L152.89-39.55L152.89-39.55Q152.89-53.22 145.71-61.30L145.71-61.30L145.71-61.30Q138.54-69.38 125.32-69.38L125.32-69.38L106.79-69.38L106.79-9.72ZM178.20 0L178.20-79.10L207.47-79.10L207.47-79.10Q218.99-79.10 227.92-74.41L227.92-74.41L227.92-74.41Q236.85-69.72 241.82-60.74L241.82-60.74L241.82-60.74Q246.79-51.75 246.79-39.55L246.79-39.55L246.79-39.55Q246.79-27.35 241.82-18.36L241.82-18.36L241.82-18.36Q236.85-9.38 227.92-4.69L227.92-4.69L227.92-4.69Q218.99 0 207.47 0L207.47 0L178.20 0ZM188.94-9.72L207.47-9.72L207.47-9.72Q220.69-9.72 227.86-17.80L227.86-17.80L227.86-17.80Q235.04-25.88 235.04-39.55L235.04-39.55L235.04-39.55Q235.04-53.22 227.86-61.30L227.86-61.30L227.86-61.30Q220.69-69.38 207.47-69.38L207.47-69.38L188.94-69.38L188.94-9.72Z" fill="#0e00ff"></path></g></g><style>text {',
                'font-size: 64px;',
                'font-family: Arial Black;',
                'dominant-baseline: central;',
                'text-anchor: middle;',
                '}</style></svg>'                        
            )
        );
    }

    /// @notice returns abi.encoded svg that spells "even"
    function evenSvg() internal pure returns (string memory) {
        return string(
            abi.encodePacked(
                '<svg width="392.215625px" height="206.6px" xmlns="http://www.w3.org/2000/svg" viewBox="53.892187500000006 -28.299999999999997 392.215625 206.6" style="background: rgb(29, 14, 11);" preserveAspectRatio="xMidYMid"><defs><filter id="editing-metal-beveled"><feGaussianBlur stdDeviation="4" in="SourceAlpha" result="blur"></feGaussianBlur><feSpecularLighting surfaceScale="5" specularConstant="0.8" specularExponent="7.5" lighting-color="#ff7777" in="blur" result="specular"><fePointLight x="-250" y="-50" z="300"></fePointLight></feSpecularLighting><feComposite operator="in" in="specular" in2="SourceAlpha" result="comp"></feComposite><feComposite in="SourceGraphic" in2="comp" operator="arithmetic" k1="0" k2="1" k3="1" k4="0"></feComposite></filter></defs><g filter="url(#editing-metal-beveled)"><g transform="translate(113.15498447418213, 114.55000162124634)"><path d="M9.04 0L9.04-79.10L57.29-79.10L57.29-69.38L19.78-69.38L19.78-46.22L49.61-46.22L49.61-36.50L19.78-36.50L19.78-9.72L58.31-9.72L58.31 0L9.04 0ZM119.78-79.10L131.08-79.10L102.72 0L91.42 0L63.05-79.10L74.35-79.10L97.07-15.03L119.78-79.10ZM140.57 0L140.57-79.10L188.82-79.10L188.82-69.38L151.31-69.38L151.31-46.22L181.14-46.22L181.14-36.50L151.31-36.50L151.31-9.72L189.84-9.72L189.84 0L140.57 0ZM203.17 0L203.17-79.10L214.81-79.10L253.80-19.89L253.80-79.10L264.65-79.10L264.65 0L255.49 0L213.91-62.49L213.91 0L203.17 0Z" fill="#ff0000"></path></g></g><style>text {',
                'font-size: 64px;',
                'font-family: Arial Black;',
                'dominant-baseline: central;',
                'text-anchor: middle;',
                '}</style></svg>'
            )
        );
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
pragma solidity ^0.8.10;

interface IMetadataRenderer {
    function tokenURI(uint256) external view returns (string memory);
    function contractURI() external view returns (string memory);
    function initializeWithData(bytes memory initData) external;
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