// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "./Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


/** @title Omikujify Contract
  * @author @0xAnimist
  * @notice First Onchain GIF, collaboration between Cai Guo-Qiang and Kanon
  */
contract Omikujify {
  bool public _freeze;

  uint256 constant baseWidth = 384;
  uint256 constant baseHeight = 860;
  uint256 constant seedWidth = 434;
  uint256 constant seedHeight = 770;
  uint256 constant poemHeight = 255;
  uint256 constant twoPivotsHeight = 150;
  uint256 constant fontSize = 12;
  string constant _defs = '<defs><style><![CDATA[ .lines {stroke: white; stroke-width: 1;} .green {fill: #35A98E;} .violet {fill: #5F5FBC;} .white {fill: #FFFFFF} .grey {fill: #BDBDBD;} .mono {font-family:Monaco, monospace; font-size:10px;} .centered {text-anchor: middle;} .heading {font-family: "Times New Roman"; font-style:normal;font-weight:400;font-size:21px;letter-spacing: 0.03em;text-transform:uppercase;} .copy {font-size:18px;text-align: center;} .img {opacity:0.35;} ]]></style><pattern id="dot" viewBox="0,0,48,48" width="16.5%" height="7.692%"><circle cx="0" cy="1" r="1" fill="#ffffff" /></pattern><linearGradient id="topfade" x1="0" x2="0" y1="0"  y2="1"><stop offset="0%" stop-color="black" stop-opacity="0.75"/><stop offset="30%" stop-color="black" stop-opacity="0.35"/><stop offset="100%" stop-color="black" stop-opacity="0"/></linearGradient><linearGradient id="bottomfade" x1="0" x2="0" y1="0"  y2="1"><stop offset="0%" stop-color="black" stop-opacity="0"/><stop offset="30%" stop-color="black" stop-opacity="0.35"/><stop offset="100%" stop-color="black" stop-opacity="0.75"/></linearGradient></defs>';

  string constant _bg = '<rect x="0" y="0" width="100%" height="100%" fill="black" />';

  string constant _grid = '<rect x="48" y="169" width="290" height="576" fill="url(#dot)" /></svg>';

  string constant _numbers = '<svg class="mono white" x="47" y="115"><text y="10">0</text><text y="10" x="48">1</text><text y="10" x="96">2</text><text y="10" x="144">3</text><text y="10" x="192">4</text><text y="10" x="240">5</text><text y="10" x="288">6</text><text y="634">0</text><text y="634" x="48">1</text><text y="634" x="96">2</text><text y="634" x="144">3</text><text y="634" x="192">4</text><text y="634" x="240">5</text><text y="634" x="288">6</text></svg>';

  string constant _numbersGrey = '<svg class="mono grey" x="47" y="115"><text y="10">0</text><text y="10" x="48">1</text><text y="10" x="96">2</text><text y="10" x="144">3</text><text y="10" x="192">4</text><text y="10" x="240">5</text><text y="10" x="288">6</text><text y="634">0</text><text y="634" x="48">1</text><text y="634" x="96">2</text><text y="634" x="144">3</text><text y="634" x="192">4</text><text y="634" x="240">5</text><text y="634" x="288">6</text></svg>';

  string constant _changeLine = '<line x1="0" y1="20" x2="40" y2="20" stroke="white" stroke-opacity="0.5"/><line x1="20" y1="0" x2="20" y2="40" stroke="white" stroke-opacity="0.5"/><circle cx="20" cy="20" r="3" fill="white" fill-opacity="1.0"/>';

  string[] public _changeLineXvalues = ["78","125","173","221","269","317"];
  string[] public _changeLineYvalues = ["140","195","239","283","327","372","416","460","504","549","593","638","682"];


  constructor() { }


  function getHeight(uint256[] memory _pivots) public pure returns(uint256 hh) {
    hh = baseHeight + poemHeight;

    if(_pivots.length > 0){
      hh += poemHeight;
    }

    hh += (_pivots.length % 2) * twoPivotsHeight;
  }

  function formatSVG(string memory _seedGif, string memory _eetGif, string memory _forkGif, string[] memory _metadataArray) public view returns(string memory) {
    string memory hh = Strings.toString(baseHeight);
    //uint256 xx = (baseHeight - baseWidth) / 2;//left offset if 1:1 aspect ratio
    string memory ww = Strings.toString(baseWidth);

    string memory header = string(abi.encodePacked(
      '<svg version="1.1" width="',
      ww,
      '" height="',
      hh,
      '" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
      _defs
    ));

    string memory image = string(abi.encodePacked(
      '<svg width="100%" height="100%" x="0" y="0"><filter id="dither" x="0" y="0"><feTurbulence type="fractalNoise" baseFrequency="0.7" stitchTiles="stitch"/></filter><rect width="100%" height="100%" filter="url(#dither)" opacity="0.2"/><image class="img" preserveAspectRatio="none" x="-25" y="-25" width="434" height="910" xlink:href="data:image/gif;base64,',
      _seedGif,
      '"/><rect x="0" y="0" width="100%" height="30%" fill="url(#topfade)"/><rect x="0" y="70%" width="100%" height="30%" fill="url(#bottomfade)"/>',
      '<image preserveAspectRatio="none" x="-22" y="100" width="430" height="671" xlink:href="data:image/gif;base64,',
      _eetGif,
      '"/><image preserveAspectRatio="none" x="-22" y="100" width="430" height="671" xlink:href="data:image/gif;base64,',
      _forkGif,
      '"/></svg>'
    ));

    //string memory _svgHeader = '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 438 1200" style="enable-background:new 0 0 100 100;" xml:space="preserve">';

    string memory headerFooter = string(abi.encodePacked(
      '<svg x="0" y="0" width="100%" height="100%"><text class="heading green centered" y="59" x="50%">',
      _metadataArray[1],
      '</text><text class="mono white centered" y="77" x="50%">FORTUNE</text><text class="mono white centered" y="797" x="50%">FORK</text><text class="heading violet centered" y="821" x="50%">',
      _metadataArray[2],
      '</text></svg>'
    ));

    string memory svg = string(abi.encodePacked(
      header,
      _bg,
      '<svg width="100%" height="100%" y="0" x="0">',
      image,
      headerFooter,
      _numbers,
      _grid
    ));

    svg = string(abi.encodePacked(
      svg,
      _changeLines(_metadataArray[3], _metadataArray[4]),
      '</svg>'
    ));

    string memory metadata = string(abi.encodePacked(
      _metadataArray[0],
      '"image": "data:image/svg+xml;base64,'
    ));

    metadata = string(abi.encodePacked(
      metadata,
      Base64.encode(bytes(svg)),
      '"}'
    ));

    return string(abi.encodePacked(
      'data:application/json;base64,',
      Base64.encode(bytes(metadata))
    ));
  }

  function _changeLines(string memory _binomialFortuneAsString, string memory _binomialShiftsAsString) internal view returns(string memory) {
    string memory changes;
    uint256 path = 6;

    for(uint256 i = 0; i < 6; i++){
      if(_isOneAtIndex(_binomialFortuneAsString, i)){
        path--;
      }else{
        path++;
      }

      if(_isOneAtIndex(_binomialShiftsAsString, i)){
        changes = string(abi.encodePacked(
          changes,
          '<svg opacity="0" x="',
          _changeLineXvalues[i],
          '" y="',
          _changeLineYvalues[path],
          '" width="40" height="40">',
          _changeLine
        ));

        changes = string(abi.encodePacked(
          changes,
          '<animate attributeName="opacity" dur="0.5s" values="0;1" begin="',
          Strings.toString(i+1),
          's" fill="freeze" stroke="freeze"/>',
          '</svg>'
        ));
      }
    }

    return changes;
  }

  function _isOneAtIndex(string memory str, uint256 index) internal pure returns (bool) {
    bytes memory bytesStr = bytes(str);

    // Make sure the index is within the bounds of the string
    if (index >= bytesStr.length) {
        return false;
    }

    // Extract the character at the given index
    bytes1 character = bytesStr[index];

    // Compare the character to '1'
    return (character == '1');
  }



  function formatVirgin(string memory _metadataHeader) public pure returns(string memory) {
    string memory hh = Strings.toString(baseHeight);
    string memory ww = Strings.toString(baseWidth);

    string memory header = string(abi.encodePacked(
      '<svg version="1.1" width="',
      ww,
      '" height="',
      hh,
      '" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
      _defs
    ));

    string memory headings = string(abi.encodePacked(
      '<svg x="0" y="0" width="100%" height="100%"><text class="mono grey centered" y="55" x="50%">EET</text><text class="mono grey centered" y="69" x="50%">BY CAI GUO-QIANG x KANON</text><text class="mono grey centered" y="803" x="50%">REDEEMABLE FOR</text><text class="mono grey centered" y="817" x="50%">ONE EET FORTUNE</text></svg>'
    ));

    string memory svg = string(abi.encodePacked(
      header,
      _bg,
      '<svg width="100%" height="100%" y="0" x="0">',
      headings,
      _numbersGrey,
      _grid,
      '</svg>'
    ));

    string memory metadata = string(abi.encodePacked(
      _metadataHeader,
      '"image": "data:image/svg+xml;base64,'
    ));

    metadata = string(abi.encodePacked(
      metadata,
      Base64.encode(bytes(svg)),
      '"}'
    ));

    return string(abi.encodePacked(
      'data:application/json;base64,',
      Base64.encode(bytes(metadata))
    ));
  }



}//end Omikujify

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
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