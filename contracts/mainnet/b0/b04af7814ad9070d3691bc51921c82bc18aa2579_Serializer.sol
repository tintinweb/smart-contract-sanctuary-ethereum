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
pragma solidity ^0.8.15;

enum Shape {
    NO_SHAPE,
    PEAR,
    ROUND,
    OVAL,
    CUSHION
}

enum Grade {
    NO_GRADE,
    GOOD,
    VERY_GOOD,
    EXCELLENT
}

enum Clarity {
    NO_CLARITY,
    VS2,
    VS1,
    VVS2,
    VVS1,
    IF,
    FL
}

enum Fluorescence {
    NO_FLUORESCENCE,
    FAINT,
    NONE
}

enum Color {
    NO_COLOR,
    K,
    L,
    M,
    N,
    O,
    P,
    Q,
    R,
    S,
    T,
    U,
    V,
    W,
    X,
    Y,
    Z
}

struct Certificate {
    uint64 number;
    uint32 date;
    uint16 length;
    uint16 width;
    uint16 depth;
    uint8 points;
    Clarity clarity;
    Color color;
    Color toColor;
    Grade cut;
    Grade symmetry;
    Grade polish;
    Fluorescence fluorescence;
    Shape shape;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./Diamond.sol";
import "./System.sol";

enum RoughShape {
    NO_SHAPE,
    MAKEABLE_1,
    MAKEABLE_2
}

struct RoughMetadata {
    uint16 id;
    uint8 extraPoints;
    RoughShape shape;
}

struct CutMetadata {
    uint16 id;
    uint8 extraPoints;
}

struct PolishedMetadata {
    uint16 id;
}

struct RebornMetadata {
    uint16 id;
}

struct Metadata {
    Stage state_;
    RoughMetadata rough;
    CutMetadata cut;
    PolishedMetadata polished;
    RebornMetadata reborn;
    Certificate certificate;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

enum Stage {
    NO_STAGE,
    KEY,
    MINE,
    CUT,
    POLISH,
    DAWN,
    COMPLETED
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../objects/Diamond.sol";
import "../objects/Mine.sol";

library Serializer {
    struct NFTMetadata {
        string name;
        string image;
        string animationUrl;
        Attribute[] attributes;
    }

    struct Attribute {
        string traitType;
        string value;
        string maxValue;
        string displayType;
        bool isString;
    }

    function toStrAttribute(string memory traitType, string memory value) public pure returns (Attribute memory) {
        return Attribute({traitType: traitType, value: value, maxValue: "", displayType: "", isString: true});
    }

    function toAttribute(
        string memory traitType,
        string memory value,
        string memory displayType
    ) public pure returns (Attribute memory) {
        return Attribute({traitType: traitType, value: value, maxValue: "", displayType: displayType, isString: false});
    }

    function toMaxValueAttribute(
        string memory traitType,
        string memory value,
        string memory maxValue,
        string memory displayType
    ) public pure returns (Attribute memory) {
        return
            Attribute({
                traitType: traitType,
                value: value,
                maxValue: maxValue,
                displayType: displayType,
                isString: false
            });
    }

    function serialize(NFTMetadata memory metadata) public pure returns (string memory) {
        bytes memory bytes_;
        bytes_ = abi.encodePacked(bytes_, _openObject());
        bytes_ = abi.encodePacked(bytes_, _pushAttr("name", metadata.name, true, false));
        bytes_ = abi.encodePacked(bytes_, _pushAttr("image", metadata.image, true, false));
        bytes_ = abi.encodePacked(bytes_, _pushAttr("animation_url", metadata.animationUrl, true, false));
        bytes_ = abi.encodePacked(bytes_, _pushAttr("attributes", _serializeAttrs(metadata.attributes), false, true));
        bytes_ = abi.encodePacked(bytes_, _closeObject());
        return string(bytes_);
    }

    function _serializeAttrs(Attribute[] memory attributes) public pure returns (string memory) {
        bytes memory bytes_;
        bytes_ = abi.encodePacked(bytes_, _openArray());
        for (uint i = 0; i < attributes.length; i++) {
            Attribute memory attribute = attributes[i];
            bytes_ = abi.encodePacked(bytes_, _pushArray(_serializeAttr(attribute), i == attributes.length - 1));
        }
        bytes_ = abi.encodePacked(bytes_, _closeArray());
        return string(bytes_);
    }

    function _serializeAttr(Attribute memory attribute) public pure returns (string memory) {
        bytes memory bytes_;
        bytes_ = abi.encodePacked(bytes_, _openObject());
        if (bytes(attribute.displayType).length > 0) {
            bytes_ = abi.encodePacked(bytes_, _pushAttr("display_type", attribute.displayType, true, false));
        }
        if (bytes(attribute.maxValue).length > 0) {
            bytes_ = abi.encodePacked(bytes_, _pushAttr("max_value", attribute.maxValue, attribute.isString, false));
        }
        bytes_ = abi.encodePacked(bytes_, _pushAttr("trait_type", attribute.traitType, true, false));
        bytes_ = abi.encodePacked(bytes_, _pushAttr("value", attribute.value, attribute.isString, true));
        bytes_ = abi.encodePacked(bytes_, _closeObject());
        return string(bytes_);
    }

    // Objects
    function _openObject() public pure returns (bytes memory) {
        return abi.encodePacked("{");
    }

    function _closeObject() public pure returns (bytes memory) {
        return abi.encodePacked("}");
    }

    function _pushAttr(
        string memory key,
        string memory value,
        bool isStr,
        bool isLast
    ) public pure returns (bytes memory) {
        if (isStr) value = string.concat('"', value, '"');
        return abi.encodePacked('"', key, '": ', value, isLast ? "" : ",");
    }

    // Arrays
    function _openArray() public pure returns (bytes memory) {
        return abi.encodePacked("[");
    }

    function _closeArray() public pure returns (bytes memory) {
        return abi.encodePacked("]");
    }

    function _pushArray(string memory value, bool isLast) public pure returns (bytes memory) {
        return abi.encodePacked(value, isLast ? "" : ",");
    }

    function toColorStr(Color color, Color toColor) public pure returns (string memory) {
        return
            toColor == Color.NO_COLOR
                ? _toColorStr(color)
                : string.concat(_toColorStr(color), "-", _toColorStr(toColor));
    }

    function toGradeStr(Grade grade) public pure returns (string memory) {
        if (grade == Grade.GOOD) return "Good";
        if (grade == Grade.VERY_GOOD) return "Very Good";
        if (grade == Grade.EXCELLENT) return "Excellent";
        revert();
    }

    function toClarityStr(Clarity clarity) public pure returns (string memory) {
        if (clarity == Clarity.VS2) return "VS2";
        if (clarity == Clarity.VS1) return "VS1";
        if (clarity == Clarity.VVS2) return "VVS2";
        if (clarity == Clarity.VVS1) return "VVS1";
        if (clarity == Clarity.IF) return "IF";
        if (clarity == Clarity.FL) return "FL";
        revert();
    }

    function toFluorescenceStr(Fluorescence fluorescence) public pure returns (string memory) {
        if (fluorescence == Fluorescence.FAINT) return "Faint";
        if (fluorescence == Fluorescence.NONE) return "None";
        revert();
    }

    function toMeasurementsStr(
        bool isRound,
        uint16 length,
        uint16 width,
        uint16 depth
    ) public pure returns (string memory) {
        string memory separator = isRound ? " - " : " x ";
        return string.concat(toDecimalStr(length), separator, toDecimalStr(width), " x ", toDecimalStr(depth));
    }

    function toShapeStr(Shape shape) public pure returns (string memory) {
        if (shape == Shape.PEAR) return "Pear";
        if (shape == Shape.ROUND) return "Round";
        if (shape == Shape.OVAL) return "Oval";
        if (shape == Shape.CUSHION) return "Cushion";
        revert();
    }

    function toRoughShapeStr(RoughShape shape) public pure returns (string memory) {
        if (shape == RoughShape.MAKEABLE_1) return "Makeable 1";
        if (shape == RoughShape.MAKEABLE_2) return "Makeable 2";
        revert();
    }

    function getName(Metadata memory metadata, uint tokenId) public pure returns (string memory) {
        if (metadata.state_ == Stage.KEY) return string.concat("Mine Key #", Strings.toString(tokenId));
        if (metadata.state_ == Stage.MINE) return string.concat("Rough Stone #", Strings.toString(metadata.rough.id));
        if (metadata.state_ == Stage.CUT) return string.concat("Formation #", Strings.toString(metadata.cut.id));
        if (metadata.state_ == Stage.POLISH) return string.concat("Diamond #", Strings.toString(metadata.polished.id));
        if (metadata.state_ == Stage.DAWN) return string.concat("Dawn #", Strings.toString(metadata.reborn.id));
        revert();
    }

    function toDecimalStr(uint percentage) public pure returns (string memory) {
        uint remainder = percentage % 100;
        string memory quotient = Strings.toString(percentage / 100);
        if (remainder < 10) return string.concat(quotient, ".0", Strings.toString(remainder));
        return string.concat(quotient, ".", Strings.toString(remainder));
    }

    function toTypeStr(Stage state_) public pure returns (string memory) {
        if (state_ == Stage.KEY) return "Key";
        if (state_ == Stage.MINE || state_ == Stage.CUT || state_ == Stage.POLISH) return "Diamond";
        if (state_ == Stage.DAWN) return "Certificate";
        revert();
    }

    function toStageStr(Stage state_) public pure returns (string memory) {
        if (state_ == Stage.MINE) return "Rough";
        if (state_ == Stage.CUT) return "Cut";
        if (state_ == Stage.POLISH) return "Polished";
        if (state_ == Stage.DAWN) return "Reborn";
        revert();
    }

    function _toColorStr(Color color) public pure returns (string memory) {
        if (color == Color.K) return "K";
        if (color == Color.L) return "L";
        if (color == Color.M) return "M";
        if (color == Color.N) return "N";
        if (color == Color.O) return "O";
        if (color == Color.P) return "P";
        if (color == Color.Q) return "Q";
        if (color == Color.R) return "R";
        if (color == Color.S) return "S";
        if (color == Color.T) return "T";
        if (color == Color.U) return "U";
        if (color == Color.V) return "V";
        if (color == Color.W) return "W";
        if (color == Color.X) return "X";
        if (color == Color.Y) return "Y";
        if (color == Color.Z) return "Z";
        revert();
    }
}