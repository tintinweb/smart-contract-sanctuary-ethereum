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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IRenderer {
  function tokenURI(uint256 tokenId, uint256 seed) external view returns (string memory);
}

contract Renderer  {

  using Strings for uint256;

  struct GeneratorConfig {
    uint head;
    uint layerOne;
    uint layerTwo;
    uint layerThree;
    uint layerOneColor;
    uint layerTwoColor;
    uint layerThreeColor;
    uint headColor;
    bool isUnicolor;
    bool isSpecialHead;
    uint specialHead;
    bool hasTitle;
    uint titleColor;
    uint title;
    bool hasDecoration;
    uint decoration;
    uint decorationColor;
    bool hasConsistency;
  }

  enum RANDPOS{ TITLE, HEAD, LAYER_ONE, LAYER_TWO, LAYER_THREE, HEAD_COLOR, LAYER_ONE_COLOR, LAYER_TWO_COLOR, LAYER_THREE_COLOR, SPECIAL_HEAD, SPECIAL_HEAD_COLOR, TITLE_COLOR, DECORATION, DECORATION_COLOR }

  string[][] colors = [
  ["#e60049", "UA Red"],
  ["#82b6b9", "Pewter Blue"],
  ["#b3d4ff", "Pale Blue"],
  ["#00ffff", "Aqua"],
  ["#0bb4ff", "Blue Bolt"],
  ["#1853ff", "Blue RYB"],
  ["#35d435", "Lime Green"],
  ["#61ff75", "Screamin Green"],
  ["#00bfa0", "Caribbean Green"],
  ["#ffa300", "Orange"],
  ["#fd7f6f", "Coral Reef"],
  ["#d0f400", "Volt"],
  ["#9b19f5", "Purple X11"],
  ["#dc0ab4", "Deep Magenta"],
  ["#f46a9b", "Cyclamen"],
  ["#bd7ebe", "African Violet"],
  ["#fdcce5", "Classic Rose"],
  ["#FCE74C", "Gargoyle Gas"],
  ["#eeeeee", "Bright Gray"],
  ["#7f766d", "Sonic Silver"]
];

  string[][] specialHeads = [
[
    ')',
    ') \\',
    ' / ) (',
    '\\(_)/'
],
[
    '',
    'P~O~O~O~P',
    '\\|/',
    '    _^_    '
],
[
    '',
    '*  *  *',
    '\\|/',
    '    _^_    '
],
[
    '',
    '                        /)               ',
    '                    -:))  BzzzBzBzzzz ',
    '                   _^_  \\)               '
]
  ];

  string[7] heads = [
      unicode"    _꒰_    ", "    _#_    ", " _o_ ", " _ ", "  _$_  ", unicode"  _♢_  ", unicode"    _ヘ_    "
  ];
  string[7] layerThrees = [
      " (___) ", " {__#} ", " (OoO) ", " [___] ", " ($_$) ", unicode" (♢♢♢) ", " (___) "
  ];
  string[7] layerTwos = [
      " (_____) ", " {__#__} ", " (oOo0O) ", " [_____] ", " ($_$_$) ", unicode" (♢♢♢♢♢) ", " (_____) "
  ];
  string[7] layerOnes = [
      " (_______) ", " {_____#_} ", " (OOooOO0) ", " [_______] ", " ($_$_$_$) ", unicode" (♢♢♢♢♢♢♢) ", " (C_O_I_N) "
  ];

  string[7] titles = [
    "SOLID",
    "OLD",
    "FRACTIONALIZED",
    "HARD",
    "MICHELIN",
    "DIAMOND",
    "SHITCOIN"
  ];

  string[] decorations = ['#','**', unicode'°´´', '....', '~~'];

  function getPos(RANDPOS pos) public pure returns (uint8) {
    return uint8(pos);
  }

  function tokenURI(uint256 tokenId, uint256 seed) public view returns (string memory) {

    GeneratorConfig memory config = getGeneratorConfig(seed);
    
    string memory description = "Turds on-chain";

    bytes memory json = bytes (
      abi.encodePacked(
          '{',
          '"name":"OnChainTurds #', tokenId.toString(), '",',
          '"description":"', description, '",',
          '"image": "', getSvg(config), '",',
          '"attributes": ', getAttributesJson(config),
          '}'
        )
    );
    string memory base64Json = Base64.encode(bytes(json));
    
    return string(abi.encodePacked("data:application/json;base64,", base64Json));
  }

  function getAttributesJson(GeneratorConfig memory config) internal view returns (string memory) {
    string[4] memory specialHeadnames = [
      "HotPot",
      "Poop",
      "Rocket",
      "Fly"
    ];
    string[5] memory smell = ['Very Strong','Strong', 'Max Fear', 'Noticeable', 'Dominant'];
    string[8] memory trait_types = [
        "Head",
        "L1", 
        "L2", 
        "L3",
        "Smell",
        "Consistency",
        "Grade",
        "Color"
      ];
      string memory l1c = colors[config.layerOneColor][1];
      string memory l2c = colors[config.layerTwoColor][1];
      string memory l3c = colors[config.layerThreeColor][1];

      string[8] memory trait_values = [
        config.isSpecialHead ? specialHeadnames[config.specialHead] : titles[config.head],
        string(abi.encodePacked(config.hasConsistency ? titles[config.layerThree] : titles[config.layerOne], ' (', l1c, ')')),
        string(abi.encodePacked(config.hasConsistency ? titles[config.layerThree] : titles[config.layerTwo], ' (', l2c, ')')),
        string(abi.encodePacked(titles[config.layerThree], ' (', l3c, ')')),
        config.hasDecoration ? smell[config.decoration] : "None",
        config.hasConsistency ? titles[config.layerThree] : "Inconsistent",
        config.hasTitle ? titles[config.title] : "None",
        config.isUnicolor ? "Uniform" : "Multicolor"
      ];
      uint8 trait_count = uint8(trait_types.length);
      string memory attributes = '[\n';
      for (uint8 i = 0; i < trait_count; i++) {
        attributes = string(abi.encodePacked(attributes,
          (i > 0) ? ',' : '', '{"trait_type": "', trait_types[i], '", "value": "', trait_values[i],'"}','\n'
        ));
      }
      return string(abi.encodePacked(attributes, ']'));
    }

  function getVal(uint256 num, RANDPOS _pos) public view returns (uint8) {
    uint8 pos = uint8(_pos);
    return uint8((num & (255 << (8 * pos))) >> (8 * pos));
  }

  function joinStr(string[] memory strings) public view returns (string memory) {
    string memory result = "";
    for (uint i = 0; i < strings.length; i++) {
      result = string(abi.encodePacked(result, strings[i]));
    }
    return result;
  }

  function getGeneratorConfig(uint seed) private view returns (GeneratorConfig memory) {
    bool hasConsistency = getRand(seed, 100, "consistency") < 42;
    GeneratorConfig memory config = GeneratorConfig({
      head: getVal(seed, RANDPOS.HEAD) % heads.length,
      layerThree: getVal(seed, RANDPOS.LAYER_THREE) % layerThrees.length,
      layerTwo: getVal(seed, RANDPOS.LAYER_TWO) % layerTwos.length,
      layerOne: getVal(seed, RANDPOS.LAYER_ONE) % layerOnes.length,
      layerThreeColor: getVal(seed, RANDPOS.LAYER_THREE_COLOR) % colors.length,
      layerTwoColor: getVal(seed, RANDPOS.LAYER_TWO_COLOR) % colors.length,
      layerOneColor: getVal(seed, RANDPOS.LAYER_ONE_COLOR) % colors.length,
      headColor: getVal(seed, RANDPOS.HEAD_COLOR) % colors.length,
      isUnicolor: getRand(seed, 100, "ucolor") < 15,
      isSpecialHead: getRand(seed, 100, "shithead") < 10, // 10
      specialHead: getVal(seed, RANDPOS.SPECIAL_HEAD) % specialHeads.length,
      hasTitle: hasConsistency && getRand(seed, 100, "title") < 10,
      titleColor: getVal(seed, RANDPOS.TITLE_COLOR) % colors.length,
      title: getVal(seed, RANDPOS.TITLE) % titles.length,
      hasDecoration: getRand(seed, 100, "dec") < 35,
      decoration: getVal(seed, RANDPOS.DECORATION) % decorations.length,
      decorationColor: getVal(seed, RANDPOS.DECORATION_COLOR) % colors.length,
      hasConsistency: hasConsistency
    });
    return config;
  }

  function getLayers(GeneratorConfig memory config) private view returns (string memory) {
    string memory layerThree = layerThrees[config.layerThree];
    string memory layerTwo = config.hasConsistency ? layerTwos[config.layerThree] : layerTwos[config.layerTwo];
    string memory layerOne = config.hasConsistency ? layerOnes[config.layerThree] : layerOnes[config.layerOne];
    string memory l3c = colors[config.layerThreeColor][0];
    string memory l2c = config.isUnicolor ? l3c : colors[config.layerTwoColor][0];
    string memory l1c = config.isUnicolor ? l3c : colors[config.layerOneColor][0];
    string memory layers = string(abi.encodePacked(
      '<tspan dy="30" x="160" fill="',l3c,'" xml:space="preserve">',layerThree,'</tspan>',
      '<tspan dy="30" x="160" fill="',l2c,'" xml:space="preserve">',layerTwo,'</tspan>',
      '<tspan dy="30" x="160" fill="',l1c,'" xml:space="preserve">',layerOne,'</tspan>'
    ));
    return layers;
  }

  function getDecorations(GeneratorConfig memory config) private view returns (string memory) {
    if(!config.hasDecoration) return "";
    string memory decoration = decorations[config.decoration];
    string memory _decorations = string(abi.encodePacked(
    '<text style="font-size:12pt;" x="70" transform="rotate(40 160 160)">',
      '<tspan y="190" fill="red">',decoration,'</tspan>',
      '<tspan y="190" dy="20" fill="red">',decoration,'</tspan>',
    '</text>',
    '<text style="font-size:12pt;" x="200" transform="rotate(-40 160 160)">',
      '<tspan y="190" dy="20" fill="red">',decoration,'</tspan>',
      '<tspan y="190"  fill="red">',decoration,'</tspan>'
    '</text>'
    ));

    return _decorations;
  }

  function getTitle(GeneratorConfig memory config) private view returns (string memory) {
    if(!config.hasTitle) return "";
    string memory title = titles[config.title];
    return string(
      abi.encodePacked(
        '<tspan dy="15" x="160" font-family="arial" fill="',colors[config.titleColor][0],'" xml:space="preserve">',title,'</tspan>'
      )
    );
  }

  function getHead(GeneratorConfig memory config) private view returns (string memory) {
    string memory headColor = config.isUnicolor ? colors[config.layerThreeColor][0] : colors[config.headColor][0];
    string memory head = heads[config.head];

    string memory specialHead = "";
    string memory specialHeadColor = config.specialHead == 0 ? "red" : headColor;
    if(config.isSpecialHead) {
      string[] memory _specialHead = new string[](4);
      string[] storage selectedHead = specialHeads[config.specialHead];
      for (uint256 index = 0; index < 4; index++) {
        string memory s = string(abi.encodePacked('<tspan dy="20" x="160" fill="',specialHeadColor,'" xml:space="preserve">',selectedHead[index],'</tspan>'));
        _specialHead[index] = s;
      }
      //  '<animate attributeName="fill" values="red;blue;red" dur="5s" repeatCount="indefinite" />',
      specialHead = joinStr(_specialHead);
    }

    return config.isSpecialHead 
    ? string(abi.encodePacked(
       specialHead
    ))
    : string(abi.encodePacked(
       '<tspan dy="50" x="160" fill="',headColor,'" xml:space="preserve">',head,'</tspan>'
    ));
  }

  function getRand(uint256 seed, uint scale, string memory noise) private view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(seed, noise))) % scale;
  }

  function getSvg(GeneratorConfig memory config) private view returns (string memory) {
    
    uint size = 320;

    string memory svgStr = string(abi.encodePacked(
    '<svg xmlns="http://www.w3.org/2000/svg" width="',size.toString(),'" height="',size.toString(),'" viewBox="0 0 ',size.toString(),' ',size.toString(),'">',
    '<rect width="100%" height="100%" fill="#121212">',
    '</rect>',
    '<text x="160" y="50" font-family="Menlo,monospace" font-weight="700" font-size="20" text-anchor="middle" letter-spacing="1">',
      getTitle(config),
      getHead(config),
      getLayers(config),
    '</text>',
    getDecorations(config),
    '</svg>'
    ));

    bytes memory svg = bytes(svgStr);
    string memory svgBase64 = Base64.encode(bytes(svg));
    return string(abi.encodePacked("data:image/svg+xml;base64,", svgBase64));
  }

}