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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IMOPassMetaDataRender {
    function constructTokenURI(uint256 RegionId, bytes memory blockLevelsBytes) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";

error BlockIndexOverFlow();
error BlockNotInPass();

bytes constant initBlockLevels =
    "678851ac687a239ab7ba923c49bcbb995c45accb6b508c4c6897a59cbcba98853ab3bca69c7c6878a967742b4a1";

library HexGridsMath {
    struct Block {
        int256 x;
        int256 y;
        int256 z;
    }

    function RegionIdRingNum(uint256 RegionId) public pure returns (uint256 n) {
        // RegionId = 3 * n * n + 3 * n + 1;
        n = (Math.sqrt(9 + 12 * (RegionId - 1)) - 3) / (6);
        if ((3 * n * n + 3 * n + 1) == RegionId) {
            return n;
        } else {
            return n + 1;
        }
    }

    function RegionIdRingPos(uint256 RegionId) public pure returns (uint256) {
        uint256 ringNum = RegionIdRingNum(RegionId) - 1;
        return RegionId - (3 * ringNum * ringNum + 3 * ringNum + 1);
    }

    function RegionIdRingStartCenterPoint(uint256 RegionIdRingNum_) public pure returns (Block memory) {
        int256 RegionIdRingNum__ = int256(RegionIdRingNum_);
        return Block(-RegionIdRingNum__ * 5, RegionIdRingNum__ * 11, -RegionIdRingNum__ * 6);
    }

    function RegionIdCenterPoint(uint256 RegionId) public pure returns (Block memory block_) {
        if (RegionId == 1) {
            return block_;
        }

        uint256 RegionIdRingNum_ = RegionIdRingNum(RegionId);
        int256 RegionIdRingNum__ = int256(RegionIdRingNum_);
        Block memory startblock = RegionIdRingStartCenterPoint(RegionIdRingNum_);
        uint256 RegionIdRingPos_ = RegionIdRingPos(RegionId);
        int256 RegionIdRingPos__ = int256(RegionIdRingPos_) - 1;

        uint256 side = Math.ceilDiv(RegionIdRingPos_, RegionIdRingNum_);
        int256 sidepos = 0;
        if (RegionIdRingNum__ > 1) {
            sidepos = RegionIdRingPos__ % RegionIdRingNum__;
        }

        if (side == 1) {
            block_.x = startblock.x + sidepos * 11;
            block_.y = startblock.y - sidepos * 6;
            block_.z = startblock.z - sidepos * 5;
        } else if (side == 2) {
            block_.x = -startblock.z + sidepos * 5;
            block_.y = -startblock.x - sidepos * 11;
            block_.z = -startblock.y + sidepos * 6;
        } else if (side == 3) {
            block_.x = startblock.y - sidepos * 6;
            block_.y = startblock.z - sidepos * 5;
            block_.z = startblock.x + sidepos * 11;
        } else if (side == 4) {
            block_.x = -startblock.x - sidepos * 11;
            block_.y = -startblock.y + sidepos * 6;
            block_.z = -startblock.z + sidepos * 5;
        } else if (side == 5) {
            block_.x = startblock.z - sidepos * 5;
            block_.y = startblock.x + sidepos * 11;
            block_.z = startblock.y - sidepos * 6;
        } else if (side == 6) {
            block_.x = -startblock.y + sidepos * 6;
            block_.y = -startblock.z + sidepos * 5;
            block_.z = -startblock.x - sidepos * 11;
        }
    }

    function RegionIdCenterPointRange(Block memory block_)
        public
        pure
        returns (int256[] memory, int256[] memory, int256[] memory)
    {
        int256[] memory xrange = new int256[](11);
        int256[] memory yrange = new int256[](11);
        int256[] memory zrange = new int256[](11);
        for (uint256 i = 1; i < 6; i++) {
            xrange[i * 2] = block_.x + int256(i);
            xrange[i * 2 - 1] = block_.x - int256(i);
            yrange[i * 2] = block_.y + int256(i);
            yrange[i * 2 - 1] = block_.y - int256(i);
            zrange[i * 2] = block_.z + int256(i);
            zrange[i * 2 - 1] = block_.z - int256(i);
        }
        xrange[0] = block_.x;
        yrange[0] = block_.y;
        zrange[0] = block_.z;
        return (xrange, yrange, zrange);
    }

    function buildBlockLevels(bytes32 randomseed) public pure returns (bytes memory) {
        bytes memory randomcombined = abi.encodePacked(
            randomseed, keccak256(abi.encodePacked(randomseed)), keccak256(abi.encodePacked(randomseed, randomseed))
        );
        bytes memory alphabet = initBlockLevels;
        bytes memory passBlockLevels = new bytes(alphabet.length);

        uint256 randIndex;
        uint256 alphabetremain;
        for (uint256 i = 0; i < alphabet.length; i++) {
            randIndex = uint256(uint8(randomcombined[i])) % 10;
            alphabetremain = alphabet.length - 1 - i;
            if (randIndex > alphabetremain) {
                randIndex = alphabetremain;
            }

            passBlockLevels[i] = alphabet[randIndex];

            alphabet[randIndex] = alphabet[alphabetremain];
        }
        return passBlockLevels;
    }

    function blockIndex(Block memory block_, uint256 RegionId) public pure returns (int256 blockIndex_) {
        Block memory centerPointBlock = RegionIdCenterPoint(RegionId);
        int256 dis = block_distance(centerPointBlock, block_);
        if (dis > 5) revert BlockNotInPass();
        dis--;
        blockIndex_ = 3 * dis * dis + 3 * dis;
        dis++;
        block_ = block_subtract(block_, centerPointBlock);
        if (block_.x >= 0 && block_.y > 0 && block_.z < 0) {
            blockIndex_ += block_distance(Block(0, dis, -dis), block_) + 1;
        } else if (block_.x > 0 && block_.y <= 0 && block_.z < 0) {
            blockIndex_ += block_distance(Block(dis, 0, -dis), block_) + 1 + dis;
        } else if (block_.x > 0 && block_.y < 0 && block_.z >= 0) {
            blockIndex_ += block_distance(Block(dis, -dis, 0), block_) + 1 + dis * 2;
        } else if (block_.x <= 0 && block_.y < 0 && block_.z > 0) {
            blockIndex_ += block_distance(Block(0, -dis, dis), block_) + 1 + dis * 3;
        } else if (block_.x < 0 && block_.y >= 0 && block_.z > 0) {
            blockIndex_ += block_distance(Block(-dis, 0, dis), block_) + 1 + dis * 4;
        } else {
            blockIndex_ += block_distance(Block(-dis, dis, 0), block_) + 1 + dis * 5;
        }
    }

    function block_add(Block memory a, Block memory b) public pure returns (Block memory) {
        return Block(a.x + b.x, a.y + b.y, a.z + b.z);
    }

    function block_subtract(Block memory a, Block memory b) public pure returns (Block memory) {
        return Block(a.x - b.x, a.y - b.y, a.z - b.z);
    }

    function block_length(Block memory a) public pure returns (int256) {
        return int256((SignedMath.abs(a.x) + SignedMath.abs(a.y) + SignedMath.abs(a.z)) / 2);
    }

    function block_distance(Block memory a, Block memory b) public pure returns (int256) {
        return block_length(block_subtract(a, b));
    }

    function blockLevel(bytes memory passBlockLevels, uint256 blockIndex_) public pure returns (uint8) {
        if (blockIndex_ >= passBlockLevels.length) {
            revert BlockIndexOverFlow();
        }
        bytes1 level = passBlockLevels[blockIndex_];
        return convertBytes1level(level);
    }

    function blockLevels(bytes memory passBlockLevels) public pure returns (uint8[] memory) {
        uint8[] memory blockLevels_ = new uint8[](passBlockLevels.length);
        for (uint8 i; i < passBlockLevels.length; i++) {
            blockLevels_[i] = convertBytes1level(passBlockLevels[i]);
        }
        return blockLevels_;
    }

    function convertBytes1level(bytes1 level) public pure returns (uint8) {
        uint8 uint8level = uint8(level);
        if (uint8level < 97) {
            return uint8level - 48;
        } else {
            return uint8level - 87;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./HexGridsMath.sol";
import "./NFTSVG.sol";
import "base64-sol/base64.sol";

library NFTMetaData {
    using Strings for uint256;

    enum PassType {
        REGULAR,
        SILVER,
        GOLD
    }

    function constructTokenURI(uint256 RegionId, bytes memory blockLevelsBytes)
        public
        pure
        returns (string memory tokenuri)
    {
        HexGridsMath.Block memory _block = HexGridsMath.RegionIdCenterPoint(RegionId);
        uint256 ringNum = HexGridsMath.RegionIdRingNum(RegionId);
        string memory coordinateStr =
            string(abi.encodePacked(_int2str(_block.x), ".", _int2str(_block.y), ".", _int2str(_block.z)));

        string memory image = constructTokenImage(RegionId, ringNum, coordinateStr, blockLevelsBytes);

        (int256[] memory xrange, int256[] memory yrange, int256[] memory zrange) =
            HexGridsMath.RegionIdCenterPointRange(_block);

        bytes memory tokenuribytes = bytes.concat(
            abi.encodePacked(
                '{"name":"MOPN Pass #',
                RegionId.toString(),
                " (",
                coordinateStr,
                ")",
                '", "description":"A Pass is a certificate of future distribution of earnings for the MOPN, Once you own a Pass, you can receive dividends from the land ('
            ),
            abi.encodePacked(
                coordinateStr,
                ").",
                " Each Pass is a unique (non-fungible) token lying on the public Ethereum blockchain (ERC-721)",
                '.", "attributes": [{"trait_type": "type", "value": "',
                getPassTypeString(RegionId),
                '"}'
            ),
            getAttributesArray("x", xrange),
            getAttributesArray("y", yrange),
            getAttributesArray("z", zrange)
        );
        tokenuribytes = abi.encodePacked(tokenuribytes, '], "image": "', image, '"}');
        tokenuri = string(abi.encodePacked("data:application/json;base64,", Base64.encode(tokenuribytes)));
    }

    function constructTokenImage(
        uint256 RegionId,
        uint256 ringNum,
        string memory coordinateStr,
        bytes memory blockLevelsBytes
    ) public pure returns (string memory) {
        string memory defs = NFTSVG.generateDefs(NFTSVG.ringBorderColor(ringNum), NFTSVG.ringBgColor(ringNum));
        string memory background = NFTSVG.generateBackground(RegionId, coordinateStr);
        uint8[] memory blockLevels = HexGridsMath.blockLevels(blockLevelsBytes);
        string memory blocks = NFTSVG.generateBlocks(blockLevels);

        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,", Base64.encode(bytes(NFTSVG.getImage(defs, background, blocks)))
            )
        );
    }

    function getAttributesArray(string memory trait_type, int256[] memory ary)
        public
        pure
        returns (bytes memory attributesBytes)
    {
        for (uint256 i = 0; i < ary.length; i++) {
            attributesBytes = abi.encodePacked(
                attributesBytes, ', {"trait_type": "', trait_type, '", "value": "', _int2str(ary[i]), '"}'
            );
        }
    }

    function getPassType(uint256 RegionId) public pure returns (PassType _passType) {
        uint256 ringNum = HexGridsMath.RegionIdRingNum(RegionId);
        if (ringNum <= 6) {
            _passType = PassType.GOLD;
        } else if (ringNum >= 30 && ringNum <= 34) {
            _passType = PassType.SILVER;
        }
    }

    function getPassTypeString(uint256 RegionId) public pure returns (string memory typeStr) {
        PassType _passType = getPassType(RegionId);

        typeStr = "Regular";

        if (_passType == PassType.GOLD) {
            typeStr = "Gold";
        } else if (_passType == PassType.SILVER) {
            typeStr = "Silver";
        }
    }

    function _int2str(int256 n) internal pure returns (string memory) {
        if (n >= 0) {
            return uint256(n).toString();
        } else {
            n = -n;
            return string(abi.encodePacked("-", uint256(n).toString()));
        }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IMOPassMetaDataRender.sol";
import "./libs/NFTMetaData.sol";

contract MOPassMetaDataRenderV1 is IMOPassMetaDataRender {
    function constructTokenURI(uint256 RegionId, bytes memory blockLevelsBytes) public pure returns (string memory) {
        return NFTMetaData.constructTokenURI(RegionId, blockLevelsBytes);
    }
}