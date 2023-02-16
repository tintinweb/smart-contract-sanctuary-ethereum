// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./IData.sol";

contract AsteroidsGame {
    address[] public _datas;
    address[] public _thumbnailDatas;

    uint256 public constant TOKENS_AMOUNT = 100;

    struct AttributeOption {
        uint256 index;
        string name;
        uint256 amount;
    }

    constructor(address[] memory datas, address[] memory thumbnailDatas) {
        _datas = datas;
        _thumbnailDatas = thumbnailDatas;
    }

    function tokenURI(uint256 tokenId, uint256 seed)
        public
        view
        returns (string memory)
    {
        require(tokenId < TOKENS_AMOUNT);

        AttributeOption memory spaceship = getAttribute(
            spaceshipOptions(),
            tokenId,
            0,
            seed,
            7
        );
        AttributeOption memory bulletType = getAttribute(
            bulletTypeOptions(),
            tokenId,
            1,
            seed,
            9
        );
        AttributeOption memory bulletColor = getAttribute(
            bulletColorOptions(),
            tokenId,
            2,
            seed,
            11
        );
        AttributeOption memory bg = getAttribute(
            backgroundOptions(),
            tokenId,
            3,
            seed,
            13
        );
        AttributeOption memory filter = getAttribute(
            filterOptions(),
            tokenId,
            4,
            seed,
            17
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json,{",
                    '"name": "Cloud Poppers #',
                    Strings.toString(tokenId),
                    '",',
                    '"description": "The first drop on the LEVELS.art platform is Bryan Brinkman\'s Cloud Poppers. It\'s his take on the 80s classic space-themed multidirectional shooter. The gameplay may feel familiar, but in Cloud Poppers the objective is to shoot and destroy Bryan\'s famed colorful clouds.",',
                    '"image": "',
                    allThumbnailData(),
                    '",',
                    '"attributes": [',
                    '{ "trait_type": "Spaceship", "value": "',
                    spaceship.name,
                    '" },',
                    '{ "trait_type": "Bullet Type", "value": "',
                    bulletType.name,
                    '" },',
                    '{ "trait_type": "Bullet Color", "value": "',
                    bulletColor.name,
                    '" },',
                    '{ "trait_type": "Background", "value": "',
                    bg.name,
                    '" },',
                    '{ "trait_type": "Filter", "value": "',
                    filter.name,
                    '" }',
                    "],",
                    string(
                        abi.encodePacked(
                            '"animation_url": "data:text/html,<html><title>Asteroids</title><body style=\\"margin: 0px;\\"><canvas id=\\"canvas\\" width=\\"512\\" height=\\"512\\" style=\\"width: 100%;height: 100%;object-fit: contain;\\"></canvas><script>var nft = { ',
                            "index: ",
                            Strings.toString(tokenId),
                            ", spaceship: ",
                            Strings.toString(spaceship.index),
                            ", bulletType: ",
                            Strings.toString(bulletType.index),
                            ", bulletColor: ",
                            Strings.toString(bulletColor.index),
                            ", bg: ",
                            Strings.toString(bg.index),
                            ", filter: ",
                            Strings.toString(filter.index),
                            " };</script><script>",
                            allData(),
                            '</script></body></html>"}'
                        )
                    )
                )
            );
    }

    function allData() public view returns (string memory) {
        bytes memory data;

        for (uint256 i = 0; i < _datas.length; i++) {
            data = bytes.concat(data, IData(_datas[i]).data());
        }

        return string(data);
    }

    function allThumbnailData() public view returns (string memory) {
        bytes memory data;

        for (uint256 i = 0; i < _thumbnailDatas.length; i++) {
            data = bytes.concat(data, IData(_thumbnailDatas[i]).data());
        }

        return string(data);
    }

    function spaceshipOptions()
        private
        pure
        returns (AttributeOption[] memory attributes)
    {
        attributes = new AttributeOption[](5);
        attributes[0] = AttributeOption(0, "Blue", 40);
        attributes[1] = AttributeOption(1, "Yellow", 30);
        attributes[2] = AttributeOption(2, "Green", 20);
        attributes[3] = AttributeOption(3, "Red", 9);
        attributes[4] = AttributeOption(4, "Ultra", 1);
    }

    function bulletTypeOptions()
        private
        pure
        returns (AttributeOption[] memory attributes)
    {
        attributes = new AttributeOption[](4);
        attributes[0] = AttributeOption(0, "Diamond", 40);
        attributes[1] = AttributeOption(1, "Fireball", 30);
        attributes[2] = AttributeOption(2, "Scribble", 20);
        attributes[3] = AttributeOption(3, "Sketchy", 10);
    }

    function bulletColorOptions()
        private
        pure
        returns (AttributeOption[] memory attributes)
    {
        attributes = new AttributeOption[](4);
        attributes[0] = AttributeOption(0, "Red", 40);
        attributes[1] = AttributeOption(1, "Yellow", 30);
        attributes[2] = AttributeOption(2, "Green", 20);
        attributes[3] = AttributeOption(3, "Blue", 10);
    }

    function backgroundOptions()
        private
        pure
        returns (AttributeOption[] memory attributes)
    {
        attributes = new AttributeOption[](4);
        attributes[0] = AttributeOption(0, "Normal", 90);
        attributes[1] = AttributeOption(1, "Grid", 5);
        attributes[2] = AttributeOption(2, "Spiral", 4);
        attributes[3] = AttributeOption(3, "Faces", 1);
    }

    function filterOptions()
        private
        pure
        returns (AttributeOption[] memory attributes)
    {
        attributes = new AttributeOption[](6);
        attributes[0] = AttributeOption(0, "None", 98);
        attributes[3] = AttributeOption(1, "Black & White", 1);
        attributes[4] = AttributeOption(2, "Sepia", 1);
    }

    function getAttribute(
        AttributeOption[] memory options,
        uint256 tokenId,
        uint256 attributeIndex,
        uint256 seed,
        uint256 mul
    ) private pure returns (AttributeOption memory result) {
        tokenId *= mul;
        tokenId += uint256(keccak256(abi.encodePacked(attributeIndex, seed)));
        tokenId = tokenId % TOKENS_AMOUNT;

        for (uint256 i = 0; i < options.length; i++) {
            if (tokenId < options[i].amount) {
                return options[i];
            }
            tokenId -= options[i].amount;
        }
        revert();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IData {
    function data() external pure returns (bytes memory);
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