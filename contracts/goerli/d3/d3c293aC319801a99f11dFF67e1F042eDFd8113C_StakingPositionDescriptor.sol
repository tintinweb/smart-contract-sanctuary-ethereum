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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SignedSafeMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SignedSafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SignedSafeMath {
    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        return a / b;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
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

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IStakingNFT {
    function skimExcessEth(address to_) external returns (uint256 excess);

    function skimExcessToken(address to_) external returns (uint256 excess);

    function depositToken(uint8 magic_, uint256 amount_) external;

    function depositEth(uint8 magic_) external payable;

    function lockPosition(
        address caller_,
        uint256 tokenID_,
        uint256 lockDuration_
    ) external returns (uint256);

    function lockOwnPosition(uint256 tokenID_, uint256 lockDuration_) external returns (uint256);

    function lockWithdraw(uint256 tokenID_, uint256 lockDuration_) external returns (uint256);

    function mint(uint256 amount_) external returns (uint256 tokenID);

    function mintTo(
        address to_,
        uint256 amount_,
        uint256 lockDuration_
    ) external returns (uint256 tokenID);

    function burn(uint256 tokenID_) external returns (uint256 payoutEth, uint256 payoutALCA);

    function burnTo(
        address to_,
        uint256 tokenID_
    ) external returns (uint256 payoutEth, uint256 payoutALCA);

    function collectEth(uint256 tokenID_) external returns (uint256 payout);

    function collectToken(uint256 tokenID_) external returns (uint256 payout);

    function collectAllProfits(
        uint256 tokenID_
    ) external returns (uint256 payoutToken, uint256 payoutEth);

    function collectEthTo(address to_, uint256 tokenID_) external returns (uint256 payout);

    function collectTokenTo(address to_, uint256 tokenID_) external returns (uint256 payout);

    function collectAllProfitsTo(
        address to_,
        uint256 tokenID_
    ) external returns (uint256 payoutToken, uint256 payoutEth);

    function getPosition(
        uint256 tokenID_
    )
        external
        view
        returns (
            uint256 shares,
            uint256 freeAfter,
            uint256 withdrawFreeAfter,
            uint256 accumulatorEth,
            uint256 accumulatorToken
        );

    function getTotalShares() external view returns (uint256);

    function getTotalReserveEth() external view returns (uint256);

    function getTotalReserveALCA() external view returns (uint256);

    function estimateEthCollection(uint256 tokenID_) external view returns (uint256 payout);

    function estimateTokenCollection(uint256 tokenID_) external view returns (uint256 payout);

    function estimateAllProfits(
        uint256 tokenID_
    ) external view returns (uint256 payoutEth, uint256 payoutToken);

    function estimateExcessToken() external view returns (uint256 excess);

    function estimateExcessEth() external view returns (uint256 excess);

    function getEthAccumulator() external view returns (uint256 accumulator, uint256 slush);

    function getTokenAccumulator() external view returns (uint256 accumulator, uint256 slush);

    function getLatestMintedPositionID() external view returns (uint256);

    function getAccumulatorScaleFactor() external pure returns (uint256);

    function getMaxMintLock() external pure returns (uint256);

    function getMaxGovernanceLock() external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

import "contracts/interfaces/IStakingNFT.sol";

/// @title Describes a staked position NFT tokens via URI
interface IStakingNFTDescriptor {
    /// @notice Produces the URI describing a particular token ID for a staked position
    /// @dev Note this URI may be a data: URI with the JSON contents directly inlined
    /// @param _stakingNFT The stake NFT for which to describe the token
    /// @param tokenId The ID of the token for which to produce a description, which may not be valid
    /// @return The URI of the ERC721-compliant metadata
    function tokenURI(
        IStakingNFT _stakingNFT,
        uint256 tokenId
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library Base64Errors {
    error InvalidDecoderInput(uint256 inputLength);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

/* solhint-disable */
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/SignedSafeMath.sol";
import "contracts/utils/Base64.sol";
import "contracts/libraries/metadata/StakingSVG.sol";

library StakingDescriptor {
    using Strings for uint256;

    struct ConstructTokenURIParams {
        uint256 tokenId;
        uint256 shares;
        uint256 freeAfter;
        uint256 withdrawFreeAfter;
        uint256 accumulatorEth;
        uint256 accumulatorToken;
    }

    /// @notice Constructs a token URI out of token URI parameters
    /// @param params parameters of the token URI
    /// @return the token URI
    function constructTokenURI(
        ConstructTokenURIParams memory params
    ) internal pure returns (string memory) {
        string memory name = generateName(params);
        string memory description = generateDescription();
        string memory attributes = generateAttributes(
            params.tokenId.toString(),
            params.shares.toString(),
            params.freeAfter.toString(),
            params.withdrawFreeAfter.toString(),
            params.accumulatorEth.toString(),
            params.accumulatorToken.toString()
        );
        string memory image = Base64.encode(bytes(generateSVGImage(params)));

        return
            string(
                abi.encodePacked(
                    "data:application/json;utf8,",
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name,
                            '", "description":"',
                            description,
                            '", "attributes": ',
                            attributes,
                            ', "image_data": "',
                            "data:image/svg+xml;base64,",
                            image,
                            '"}'
                        )
                    )
                )
            );
    }

    /// @notice Escapes double quotes from a string
    /// @param symbol the string to be processed
    /// @return The string with escaped quotes
    function escapeQuotes(string memory symbol) internal pure returns (string memory) {
        bytes memory symbolBytes = bytes(symbol);
        uint8 quotesCount = 0;
        for (uint8 i = 0; i < symbolBytes.length; i++) {
            if (symbolBytes[i] == '"') {
                quotesCount++;
            }
        }
        if (quotesCount > 0) {
            bytes memory escapedBytes = new bytes(symbolBytes.length + (quotesCount));
            uint256 index;
            for (uint8 i = 0; i < symbolBytes.length; i++) {
                if (symbolBytes[i] == '"') {
                    escapedBytes[index++] = "\\";
                }
                escapedBytes[index++] = symbolBytes[i];
            }
            return string(escapedBytes);
        }
        return symbol;
    }

    /// @notice Generates a SVG image out of a token URI
    /// @param params parameters of the token URI
    /// @return svg A string with SVG data
    function generateSVGImage(
        ConstructTokenURIParams memory params
    ) internal pure returns (string memory svg) {
        StakingSVG.StakingSVGParams memory svgParams = StakingSVG.StakingSVGParams({
            shares: params.shares.toString(),
            freeAfter: params.freeAfter.toString(),
            withdrawFreeAfter: params.withdrawFreeAfter.toString(),
            accumulatorEth: params.accumulatorEth.toString(),
            accumulatorToken: params.accumulatorToken.toString()
        });

        return StakingSVG.generateSVG(svgParams);
    }

    /// @notice Generates the description of the Staking Descriptor
    /// @return A string with the description of the Staking Descriptor
    function generateDescription() private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "This NFT represents a staked position on AliceNet. The owner of this NFT can modify or redeem the position."
                )
            );
    }

    /// @notice Generates the attributes part of the Staking Descriptor
    /// @param  tokenId the token id of this descriptor
    /// @param  shares number of ALCA
    /// @param  freeAfter block number after which the position may be burned.
    /// @param  withdrawFreeAfter block number after which the position may be collected or burned
    /// @param  accumulatorEth the last value of the ethState accumulator this account performed a withdraw at
    /// @param  accumulatorToken the last value of the tokenState accumulator this account performed a withdraw at
    /// @return A string with the attributes part of the Staking Descriptor
    function generateAttributes(
        string memory tokenId,
        string memory shares,
        string memory freeAfter,
        string memory withdrawFreeAfter,
        string memory accumulatorEth,
        string memory accumulatorToken
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "[",
                    '{"trait_type": "Shares", "value": "',
                    shares,
                    '"},'
                    '{"trait_type": "Free After", "value": "',
                    freeAfter,
                    '"},'
                    '{"trait_type": "Withdraw Free After", "value": "',
                    withdrawFreeAfter,
                    '"},'
                    '{"trait_type": "Accumulator Eth", "value": "',
                    accumulatorEth,
                    '"},'
                    '{"trait_type": "Accumulator Token", "value": "',
                    accumulatorToken,
                    '"},'
                    '{"trait_type": "Token ID", "value": "',
                    tokenId,
                    '"}'
                    "]"
                )
            );
    }

    function generateName(
        ConstructTokenURIParams memory params
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked("AliceNet Staked Token For Position #", params.tokenId.toString())
            );
    }
}
/* solhint-enable */

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

/* solhint-disable */
import "@openzeppelin/contracts/utils/Strings.sol";
import "contracts/utils/Base64.sol";

/// @title StakingSVG
/// @notice Provides a function for generating an SVG associated with a Staking NFT position
library StakingSVG {
    using Strings for uint256;

    struct StakingSVGParams {
        string shares;
        string freeAfter;
        string withdrawFreeAfter;
        string accumulatorEth;
        string accumulatorToken;
    }

    function generateSVG(StakingSVGParams memory params) internal pure returns (string memory svg) {
        return string(abi.encodePacked(generateSVGDefs(params), generateSVGText(params)));
    }

    function generateSVGText(StakingSVGParams memory params)
        private
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                params.shares,
                '</tspan></text><text xml:space="preserve" fill="#F812C6" font-family="Arial" font-size="13" font-weight="bold" letter-spacing="0em" style="white-space:pre"><tspan x="153" y="598.007">',
                params.withdrawFreeAfter,
                '</tspan></text><text xml:space="preserve" fill="#F812C6" font-family="Arial" font-size="13" font-weight="bold" letter-spacing="0em" style="white-space:pre"><tspan x="153" y="568.007">',
                params.freeAfter,
                '</tspan></text><path stroke="#F2EAE9" stroke-opacity=".06" d="M12 608.5h476M12 578.5h476"/></svg>'
            )
        );
    }

    function generateSVGDefs(StakingSVGParams memory params)
        private
        pure
        returns (string memory svg)
    {
        params; //to silence the warnings
        svg = '<svg xmlns="http://www.w3.org/2000/svg" width="500" height="645" fill="none"><mask id="a" width="500" height="440" x="0" y="0" maskUnits="userSpaceOnUse" style="mask-type:alpha"><path fill="#280029" d="M0 0h500v440H0z"/></mask><g mask="url(#a)"><path fill="#F2EAE9" d="M0 0h500v440H0z"/><path fill="#F812C6" d="M75.088 194.011 85.43 176l10.4 18.011H75.088ZM87.404 219.75l11.562-20.103 11.621 20.103H87.404Z"/><path fill="#FA1A22" d="m53.53 231.487 20.394-35.384 20.393 35.384H53.53Z"/><path fill="#F812C6" d="m112.329 272.332 14.351-24.926 14.351 24.926h-28.702Z"/><path fill="#F812C6" d="m98.908 247.464 13.944-24.17 13.945 24.17H98.908Z"/><path fill="#FA1A22" d="m70.788 272.273 23.531-40.786 23.473 40.786H70.788Z"/><path fill="#FF9C00" d="m30 272.332 27.307-47.353 27.308 47.353H30Z"/><path fill="#49004B" d="m450.245 203.947 8.773-6.624v14.932h10.981v7.495h-10.981v19.057c0 4.939 1.976 5.927 5.636 5.927 1.511 0 3.602-.175 5.345-1.046v7.785c-2.091 1.046-4.531 1.22-6.797 1.22-8.541 0-13.015-3.602-13.015-12.666V219.75h-7.263v-7.495h7.263v-8.308h.058Zm-40.438 24.402c.581-5.81 4.648-9.761 10.632-9.761 5.985 0 10.052 3.893 10.633 9.761h-21.265Zm11.504 24.577c7.437 0 14.583-2.963 18.127-8.832l-6.275-5.577c-2.149 5.055-6.623 6.914-11.62 6.914-5.403 0-10.981-2.789-11.794-10.4h30.212c.058-1.337.175-2.615.175-3.777 0-11.271-7.495-20.161-19.464-20.161-11.562 0-20.161 8.831-20.161 21.033-.117 12.143 8.482 20.8 20.8 20.8Zm-73.324-56.997h12.434l23.357 44.563v-44.563h8.773v55.835h-12.434L356.761 207.2v44.564h-8.774v-55.835Zm-38.056 32.42c.581-5.81 4.648-9.761 10.633-9.761 5.984 0 10.051 3.893 10.632 9.761h-21.265Zm11.504 24.577c7.437 0 14.583-2.963 18.128-8.832l-6.275-5.577c-2.15 5.055-6.624 6.914-11.62 6.914-5.404 0-10.982-2.789-11.795-10.4h30.213c.058-1.337.174-2.615.174-3.777 0-11.271-7.495-20.161-19.464-20.161-11.562 0-20.161 8.831-20.161 21.033-.116 12.143 8.541 20.8 20.8 20.8Zm-55.777-20.975c0 7.96 5.055 13.015 12.259 13.015 4.881 0 9.18-2.963 10.401-7.727l7.669 4.648c-2.498 6.391-9.761 11.097-18.011 11.097-12.55 0-21.324-8.715-21.324-20.916 0-12.202 8.774-20.917 21.324-20.917 8.715 0 15.571 4.706 18.011 11.097l-7.844 4.707c-1.22-4.765-5.345-7.844-10.226-7.844-7.204 0-12.259 4.822-12.259 12.84Zm-25.506 19.813h8.773v-39.567h-8.773v39.567Zm-.407-46.713h9.471v-9.064h-9.471v9.064Zm-17.314 46.713h8.773v-55.835h-8.773v55.835Zm-42.181-21.672 9.238-23.763 9.18 23.763H180.25Zm-18.128 21.672h9.877l5.171-13.712h24.403l5.287 13.712h9.993l-22.427-55.835h-9.703l-22.601 55.835Z"/></g><path fill="#280029" d="M0 440h500v205H0z"/><path fill="#F2EAE9" d="M40.73 486h-6.289l-2.5-6.504H20.496L18.133 486H12l11.152-28.633h6.114L40.73 486Zm-10.644-11.328-3.945-10.625-3.868 10.625h7.813ZM43.973 486v-28.398h5.78v23.574H64.13V486H43.973ZM86.59 475.473l5.605 1.777c-.86 3.125-2.291 5.449-4.297 6.973-1.992 1.51-4.524 2.265-7.597 2.265-3.802 0-6.927-1.295-9.375-3.886-2.448-2.605-3.672-6.159-3.672-10.664 0-4.766 1.23-8.464 3.691-11.094 2.461-2.643 5.697-3.965 9.707-3.965 3.503 0 6.348 1.035 8.535 3.105 1.303 1.224 2.28 2.982 2.93 5.274l-5.723 1.367c-.338-1.484-1.048-2.656-2.128-3.516-1.068-.859-2.37-1.289-3.907-1.289-2.122 0-3.847.762-5.175 2.285-1.316 1.524-1.973 3.991-1.973 7.403 0 3.62.651 6.198 1.953 7.734 1.302 1.537 2.995 2.305 5.078 2.305 1.537 0 2.858-.488 3.965-1.465 1.107-.977 1.901-2.513 2.383-4.609ZM122.996 486h-6.289l-2.5-6.504h-11.445L100.398 486h-6.132l11.152-28.633h6.113L122.996 486Zm-10.644-11.328-3.946-10.625-3.867 10.625h7.813ZM134.266 476.684l5.625-.547c.338 1.888 1.022 3.274 2.05 4.16 1.042.885 2.442 1.328 4.2 1.328 1.862 0 3.261-.391 4.199-1.172.95-.794 1.426-1.719 1.426-2.773 0-.677-.202-1.25-.606-1.719-.39-.482-1.081-.899-2.07-1.25-.677-.234-2.22-.651-4.629-1.25-3.099-.768-5.273-1.712-6.523-2.832-1.758-1.576-2.637-3.496-2.637-5.762 0-1.458.41-2.819 1.23-4.082.834-1.276 2.025-2.246 3.574-2.91 1.563-.664 3.444-.996 5.645-.996 3.594 0 6.296.788 8.105 2.363 1.823 1.576 2.78 3.679 2.872 6.309l-5.782.254c-.247-1.472-.781-2.526-1.601-3.164-.808-.651-2.025-.977-3.653-.977-1.679 0-2.994.345-3.945 1.035-.612.443-.918 1.035-.918 1.778 0 .677.287 1.256.86 1.738.729.612 2.5 1.25 5.312 1.914 2.812.664 4.889 1.354 6.23 2.07 1.355.703 2.409 1.673 3.165 2.91.768 1.224 1.152 2.741 1.152 4.551 0 1.641-.456 3.177-1.367 4.61-.912 1.432-2.201 2.5-3.868 3.203-1.666.69-3.743 1.035-6.23 1.035-3.62 0-6.4-.834-8.34-2.5-1.94-1.68-3.099-4.121-3.476-7.324ZM171.883 465.258v4.375h-3.75v8.359c0 1.693.032 2.682.097 2.969.079.273.241.501.489.684.26.182.573.273.937.273.508 0 1.244-.176 2.207-.527l.469 4.257c-1.276.547-2.721.821-4.336.821-.989 0-1.881-.163-2.676-.489-.794-.338-1.38-.768-1.758-1.289-.364-.533-.618-1.25-.761-2.148-.117-.638-.176-1.927-.176-3.867v-9.043h-2.52v-4.375h2.52v-4.121l5.508-3.203v7.324h3.75ZM179.793 471.586l-4.981-.898c.56-2.006 1.524-3.49 2.891-4.454 1.367-.963 3.399-1.445 6.094-1.445 2.448 0 4.271.293 5.469.879 1.198.573 2.037 1.309 2.519 2.207.495.885.742 2.52.742 4.902l-.058 6.407c0 1.823.084 3.17.254 4.043.182.859.514 1.783.996 2.773h-5.43a20.241 20.241 0 0 1-.527-1.621 9.785 9.785 0 0 0-.196-.645c-.937.912-1.94 1.595-3.007 2.051a8.611 8.611 0 0 1-3.418.684c-2.136 0-3.822-.58-5.059-1.739-1.224-1.158-1.836-2.623-1.836-4.394 0-1.172.28-2.214.84-3.125a5.408 5.408 0 0 1 2.344-2.109c1.015-.495 2.474-.925 4.375-1.29 2.565-.481 4.342-.93 5.332-1.347v-.547c0-1.055-.261-1.803-.782-2.246-.52-.456-1.503-.684-2.949-.684-.976 0-1.738.196-2.285.586-.547.378-.989 1.048-1.328 2.012Zm7.344 4.453c-.703.234-1.817.514-3.34.84-1.524.325-2.52.644-2.988.957-.717.508-1.075 1.152-1.075 1.934 0 .768.287 1.432.86 1.992s1.302.84 2.187.84c.99 0 1.934-.326 2.832-.977.664-.495 1.101-1.1 1.309-1.816.143-.469.215-1.361.215-2.676v-1.094ZM197.762 486v-28.633h5.488v15.195l6.426-7.304h6.758l-7.09 7.578L216.941 486h-5.918l-5.214-9.316-2.559 2.675V486h-5.488ZM232.234 479.398l5.469.918c-.703 2.006-1.816 3.536-3.34 4.59-1.51 1.042-3.405 1.563-5.683 1.563-3.607 0-6.276-1.179-8.008-3.535-1.367-1.888-2.051-4.271-2.051-7.149 0-3.437.899-6.126 2.695-8.066 1.797-1.953 4.069-2.93 6.817-2.93 3.086 0 5.521 1.022 7.305 3.066 1.783 2.032 2.636 5.15 2.558 9.356h-13.75c.039 1.628.482 2.897 1.328 3.809.847.898 1.901 1.347 3.164 1.347.86 0 1.582-.234 2.168-.703.586-.469 1.029-1.224 1.328-2.266Zm.313-5.546c-.039-1.589-.449-2.793-1.231-3.614-.781-.833-1.731-1.25-2.851-1.25-1.198 0-2.188.436-2.969 1.309-.781.872-1.165 2.057-1.152 3.555h8.203ZM261.512 486h-5.098v-3.047c-.846 1.185-1.849 2.07-3.008 2.656-1.146.573-2.304.86-3.476.86-2.383 0-4.427-.957-6.133-2.871-1.693-1.927-2.539-4.61-2.539-8.047 0-3.516.827-6.185 2.48-8.008 1.654-1.836 3.744-2.754 6.27-2.754 2.318 0 4.323.964 6.015 2.891v-10.313h5.489V486Zm-14.649-10.82c0 2.213.306 3.815.918 4.804.886 1.433 2.123 2.149 3.711 2.149 1.263 0 2.337-.534 3.223-1.602.885-1.08 1.328-2.689 1.328-4.824 0-2.383-.43-4.095-1.289-5.137-.859-1.054-1.96-1.582-3.301-1.582-1.302 0-2.396.521-3.281 1.563-.873 1.028-1.309 2.571-1.309 4.629ZM278.113 486v-28.633h9.278c3.515 0 5.807.143 6.875.43 1.64.43 3.014 1.367 4.121 2.812 1.106 1.433 1.66 3.288 1.66 5.567 0 1.758-.319 3.235-.957 4.433-.638 1.198-1.452 2.142-2.442 2.832-.976.677-1.972 1.127-2.988 1.348-1.38.273-3.379.41-5.996.41h-3.769V486h-5.782Zm5.782-23.789v8.125h3.164c2.278 0 3.802-.15 4.57-.449.768-.3 1.367-.769 1.797-1.407.442-.638.664-1.38.664-2.226 0-1.042-.306-1.901-.918-2.578-.612-.677-1.387-1.1-2.324-1.27-.69-.13-2.077-.195-4.16-.195h-2.793ZM303.484 475.336c0-1.823.45-3.587 1.348-5.293.898-1.706 2.168-3.008 3.809-3.906 1.653-.899 3.496-1.348 5.527-1.348 3.138 0 5.71 1.022 7.715 3.066 2.005 2.032 3.008 4.603 3.008 7.715 0 3.138-1.016 5.742-3.047 7.813-2.018 2.057-4.564 3.086-7.637 3.086a12.11 12.11 0 0 1-5.449-1.289c-1.719-.86-3.028-2.116-3.926-3.77-.898-1.667-1.348-3.691-1.348-6.074Zm5.625.293c0 2.057.489 3.633 1.465 4.726.977 1.094 2.181 1.641 3.614 1.641 1.432 0 2.63-.547 3.593-1.641.977-1.093 1.465-2.682 1.465-4.765 0-2.031-.488-3.594-1.465-4.688-.963-1.093-2.161-1.64-3.593-1.64-1.433 0-2.637.547-3.614 1.64-.976 1.094-1.465 2.67-1.465 4.727ZM327.273 480.082l5.508-.84c.235 1.068.71 1.882 1.426 2.442.716.546 1.719.82 3.008.82 1.419 0 2.487-.261 3.203-.781.482-.365.723-.853.723-1.465 0-.417-.131-.762-.391-1.035-.273-.261-.885-.502-1.836-.723-4.427-.977-7.233-1.868-8.418-2.676-1.641-1.12-2.461-2.676-2.461-4.668 0-1.797.71-3.307 2.129-4.531 1.419-1.224 3.62-1.836 6.602-1.836 2.838 0 4.948.462 6.328 1.387 1.38.924 2.33 2.291 2.851 4.101l-5.175.957c-.222-.807-.645-1.425-1.27-1.855-.612-.43-1.491-.645-2.637-.645-1.445 0-2.48.202-3.105.606-.417.286-.625.657-.625 1.113 0 .391.182.723.547.996.494.365 2.2.879 5.117 1.543 2.93.664 4.974 1.478 6.133 2.442 1.146.976 1.718 2.337 1.718 4.082 0 1.901-.794 3.535-2.382 4.902-1.589 1.367-3.939 2.051-7.051 2.051-2.826 0-5.065-.573-6.719-1.719-1.641-1.146-2.715-2.702-3.223-4.668ZM351.473 462.445v-5.078h5.488v5.078h-5.488Zm0 23.555v-20.742h5.488V486h-5.488ZM372.117 465.258v4.375h-3.75v8.359c0 1.693.033 2.682.098 2.969.078.273.241.501.488.684.261.182.573.273.938.273.507 0 1.243-.176 2.207-.527l.468 4.257c-1.276.547-2.721.821-4.336.821-.989 0-1.881-.163-2.675-.489-.795-.338-1.381-.768-1.758-1.289-.365-.533-.619-1.25-.762-2.148-.117-.638-.176-1.927-.176-3.867v-9.043h-2.519v-4.375h2.519v-4.121l5.508-3.203v7.324h3.75ZM375.926 462.445v-5.078h5.488v5.078h-5.488Zm0 23.555v-20.742h5.488V486h-5.488ZM385.789 475.336c0-1.823.449-3.587 1.348-5.293.898-1.706 2.168-3.008 3.808-3.906 1.654-.899 3.496-1.348 5.528-1.348 3.138 0 5.709 1.022 7.715 3.066 2.005 2.032 3.007 4.603 3.007 7.715 0 3.138-1.015 5.742-3.047 7.813-2.018 2.057-4.563 3.086-7.636 3.086-1.901 0-3.718-.43-5.45-1.289-1.718-.86-3.027-2.116-3.925-3.77-.899-1.667-1.348-3.691-1.348-6.074Zm5.625.293c0 2.057.488 3.633 1.465 4.726.976 1.094 2.181 1.641 3.613 1.641s2.63-.547 3.594-1.641c.976-1.093 1.465-2.682 1.465-4.765 0-2.031-.489-3.594-1.465-4.688-.964-1.093-2.162-1.64-3.594-1.64s-2.637.547-3.613 1.64c-.977 1.094-1.465 2.67-1.465 4.727ZM430.379 486h-5.488v-10.586c0-2.24-.118-3.685-.352-4.336-.234-.664-.618-1.178-1.152-1.543-.521-.364-1.153-.547-1.895-.547a4.4 4.4 0 0 0-2.558.782 3.98 3.98 0 0 0-1.563 2.07c-.273.859-.41 2.448-.41 4.765V486h-5.488v-20.742h5.097v3.047c1.81-2.344 4.089-3.516 6.836-3.516 1.211 0 2.318.221 3.321.664 1.002.43 1.757.983 2.265 1.66a5.858 5.858 0 0 1 1.074 2.305c.209.859.313 2.09.313 3.691V486Z"/><path fill="#F812C6" d="M16.02 619.964c-1.776 0-3.276 1.02-3.276 2.628 0 3.492 5.292 1.74 5.292 3.984 0 .852-.816 1.368-1.932 1.368-1.392 0-2.208-.84-2.208-2.148l-1.356.648c.228 1.74 1.68 2.736 3.564 2.736 1.932 0 3.396-.972 3.396-2.664 0-3.552-5.304-1.872-5.304-4.02 0-.816.756-1.296 1.824-1.296 1.272 0 2.052.768 2.052 1.836l1.308-.564c-.168-1.368-1.404-2.508-3.36-2.508ZM24.252 622.544c-.948 0-1.584.384-1.968 1.032v-3.396h-1.38V629h1.38v-3.324c0-1.188.6-1.86 1.584-1.86.924 0 1.344.516 1.344 1.644V629h1.38v-3.732c0-1.752-.816-2.724-2.34-2.724ZM27.892 627.368c0 1.116.876 1.8 2.124 1.8.864 0 1.644-.312 2.1-.936l.264.768h1.224l-.216-1.236v-3.06c0-1.392-1.02-2.16-2.64-2.16-1.452 0-2.556.828-2.736 2.004l1.224.48c0-.888.624-1.392 1.512-1.392.732 0 1.296.276 1.296.888 0 .576-.276.624-2.076.936-1.26.228-2.076.84-2.076 1.908Zm1.452-.072c0-.552.42-.792 1.008-.912 1.14-.216 1.5-.264 1.692-.432v.54c0 .924-.588 1.632-1.716 1.632-.624 0-.984-.36-.984-.828ZM35.035 622.76V629h1.38v-3.012c0-1.38.66-2.028 1.62-2.028a2.3 2.3 0 0 1 .708.108V622.7a1.403 1.403 0 0 0-.552-.084c-.576 0-1.32.228-1.776 1.128v-.984h-1.38ZM42.389 622.544c-1.812 0-3.132 1.416-3.132 3.348s1.248 3.288 3.216 3.288c1.152 0 2.22-.444 2.808-1.392l-.996-.888c-.336.768-.9 1.116-1.776 1.116-.948 0-1.656-.516-1.8-1.704h4.632c.024-.216.036-.372.036-.552 0-1.908-1.152-3.216-2.988-3.216Zm-1.668 2.76c.168-1.08.828-1.596 1.644-1.596.96 0 1.524.636 1.524 1.596H40.72ZM49.058 622.544c-1.392 0-2.568.828-2.568 1.98 0 2.508 3.912 1.464 3.912 2.784 0 .516-.54.768-1.2.768-.864 0-1.524-.408-1.572-1.332l-1.332.564c.216 1.164 1.308 1.872 2.904 1.872 1.524 0 2.676-.648 2.676-1.956 0-2.484-3.972-1.5-3.972-2.784 0-.468.42-.804 1.152-.804.864 0 1.392.444 1.44 1.2l1.308-.492c-.204-1.092-1.248-1.8-2.748-1.8ZM12.12 590.18l2.364 8.82h1.704l1.836-6.564L19.836 599h1.704l2.364-8.82H22.38l-1.752 6.816-1.86-6.696h-1.5l-1.86 6.696-1.764-6.816H12.12ZM24.84 592.76V599h1.38v-6.24h-1.38Zm-.06-1.128h1.488v-1.452H24.78v1.452ZM28.44 591.44v1.32h-1.117v1.188h1.116v3.216c0 1.428.744 1.992 2.1 1.992.204 0 .756-.048.96-.132v-1.212a4.206 4.206 0 0 1-.756.096c-.624 0-.924-.156-.924-.924v-3.036h1.776v-1.188H29.82v-2.352l-1.38 1.032ZM36.298 592.544c-.948 0-1.584.384-1.968 1.032v-3.396h-1.38V599h1.38v-3.324c0-1.188.6-1.86 1.584-1.86.924 0 1.344.516 1.344 1.644V599h1.38v-3.732c0-1.752-.816-2.724-2.34-2.724ZM46.55 590.18h-1.38v3.336c-.491-.588-1.211-.972-2.171-.972-1.884 0-3.156 1.452-3.156 3.336 0 1.872 1.284 3.3 3.156 3.3.972 0 1.692-.384 2.184-.972V599h1.368v-8.82Zm-5.28 5.7c0-1.212.805-2.088 1.98-2.088 1.129 0 1.969.864 1.969 2.088 0 1.212-.84 2.04-1.968 2.04-1.176 0-1.98-.852-1.98-2.04ZM48.242 592.76V599h1.38v-3.012c0-1.38.66-2.028 1.62-2.028a2.3 2.3 0 0 1 .708.108V592.7a1.403 1.403 0 0 0-.552-.084c-.576 0-1.32.228-1.776 1.128v-.984h-1.38ZM52.689 597.368c0 1.116.876 1.8 2.124 1.8.864 0 1.644-.312 2.1-.936l.264.768H58.4l-.216-1.236v-3.06c0-1.392-1.02-2.16-2.64-2.16-1.452 0-2.556.828-2.736 2.004l1.224.48c0-.888.624-1.392 1.512-1.392.732 0 1.296.276 1.296.888 0 .576-.276.624-2.076.936-1.26.228-2.076.84-2.076 1.908Zm1.452-.072c0-.552.42-.792 1.008-.912 1.14-.216 1.5-.264 1.692-.432v.54c0 .924-.588 1.632-1.716 1.632-.624 0-.984-.36-.984-.828ZM59.067 592.76 61.07 599h1.572l1.308-4.236L65.295 599h1.56l2.016-6.24h-1.44l-1.404 4.608-1.428-4.56h-1.284l-1.428 4.56-1.356-4.608h-1.464ZM71.85 599h1.548l.84-2.148h3.864l.816 2.148h1.572l-3.54-8.82h-1.536L71.85 599Zm2.88-3.42 1.452-3.732 1.428 3.732h-2.88ZM83.999 589.964c-1.224 0-2.016.888-2.016 2.124v.672h-1.129v1.176h1.129V599h1.38v-5.064h1.8v-1.176h-1.8v-.636c0-.66.335-.948.912-.948.24 0 .503.024.731.072v-1.176a3.995 3.995 0 0 0-1.007-.108ZM86.951 591.44v1.32h-1.116v1.188h1.116v3.216c0 1.428.744 1.992 2.1 1.992.204 0 .756-.048.96-.132v-1.212a4.206 4.206 0 0 1-.756.096c-.624 0-.924-.156-.924-.924v-3.036h1.776v-1.188h-1.776v-2.352l-1.38 1.032ZM94.127 592.544c-1.812 0-3.132 1.416-3.132 3.348s1.248 3.288 3.216 3.288c1.152 0 2.22-.444 2.808-1.392l-.996-.888c-.336.768-.9 1.116-1.776 1.116-.948 0-1.656-.516-1.8-1.704h4.632c.024-.216.036-.372.036-.552 0-1.908-1.152-3.216-2.988-3.216Zm-1.668 2.76c.168-1.08.828-1.596 1.644-1.596.96 0 1.524.636 1.524 1.596h-3.168ZM98.469 592.76V599h1.38v-3.012c0-1.38.659-2.028 1.619-2.028a2.3 2.3 0 0 1 .708.108V592.7a1.403 1.403 0 0 0-.552-.084c-.576 0-1.32.228-1.775 1.128v-.984h-1.38ZM13.02 569h1.428v-3.672h4.008v-1.272h-4.008v-2.58h4.44v-1.296H13.02V569ZM20.234 562.76V569h1.38v-3.012c0-1.38.66-2.028 1.62-2.028a2.3 2.3 0 0 1 .708.108V562.7a1.403 1.403 0 0 0-.552-.084c-.576 0-1.32.228-1.776 1.128v-.984h-1.38ZM27.588 562.544c-1.812 0-3.132 1.416-3.132 3.348s1.248 3.288 3.216 3.288c1.152 0 2.22-.444 2.808-1.392l-.996-.888c-.336.768-.9 1.116-1.776 1.116-.948 0-1.656-.516-1.8-1.704h4.632c.024-.216.036-.372.036-.552 0-1.908-1.152-3.216-2.988-3.216Zm-1.668 2.76c.168-1.08.828-1.596 1.644-1.596.96 0 1.524.636 1.524 1.596H25.92ZM34.69 562.544c-1.813 0-3.133 1.416-3.133 3.348s1.248 3.288 3.216 3.288c1.152 0 2.22-.444 2.808-1.392l-.996-.888c-.336.768-.9 1.116-1.776 1.116-.948 0-1.656-.516-1.8-1.704h4.632c.024-.216.036-.372.036-.552 0-1.908-1.152-3.216-2.988-3.216Zm-1.669 2.76c.168-1.08.828-1.596 1.644-1.596.96 0 1.524.636 1.524 1.596h-3.168ZM41.03 569h1.547l.84-2.148h3.864l.816 2.148h1.572l-3.54-8.82h-1.536L41.03 569Zm2.88-3.42 1.451-3.732 1.428 3.732h-2.88ZM53.178 559.964c-1.224 0-2.016.888-2.016 2.124v.672h-1.128v1.176h1.128V569h1.38v-5.064h1.8v-1.176h-1.8v-.636c0-.66.336-.948.912-.948.24 0 .504.024.732.072v-1.176a3.995 3.995 0 0 0-1.008-.108ZM56.13 561.44v1.32h-1.115v1.188h1.116v3.216c0 1.428.744 1.992 2.1 1.992.204 0 .756-.048.96-.132v-1.212a4.206 4.206 0 0 1-.756.096c-.624 0-.924-.156-.924-.924v-3.036h1.776v-1.188H57.51v-2.352l-1.38 1.032ZM63.307 562.544c-1.812 0-3.132 1.416-3.132 3.348s1.248 3.288 3.216 3.288c1.152 0 2.22-.444 2.808-1.392l-.996-.888c-.336.768-.9 1.116-1.776 1.116-.948 0-1.656-.516-1.8-1.704h4.632c.024-.216.036-.372.036-.552 0-1.908-1.152-3.216-2.988-3.216Zm-1.668 2.76c.168-1.08.828-1.596 1.644-1.596.96 0 1.524.636 1.524 1.596h-3.168ZM67.648 562.76V569h1.38v-3.012c0-1.38.66-2.028 1.62-2.028a2.3 2.3 0 0 1 .708.108V562.7a1.403 1.403 0 0 0-.552-.084c-.576 0-1.32.228-1.776 1.128v-.984h-1.38Z"/><text xml:space="preserve" fill="#F812C6" font-family="Arial" font-size="13" font-weight="bold" letter-spacing="0em" style="white-space:pre"><tspan x="153" y="628.007">';
    }
}
/* solhint-enable */

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.16;

import "contracts/libraries/metadata/StakingDescriptor.sol";
import "contracts/interfaces/IStakingNFTDescriptor.sol";

/// @custom:salt StakingPositionDescriptor
/// @custom:deploy-type deployUpgradeable
contract StakingPositionDescriptor is IStakingNFTDescriptor {
    function tokenURI(
        IStakingNFT _stakingNFT,
        uint256 tokenId
    ) external view override returns (string memory) {
        (
            uint256 shares,
            uint256 freeAfter,
            uint256 withdrawFreeAfter,
            uint256 accumulatorEth,
            uint256 accumulatorToken
        ) = _stakingNFT.getPosition(tokenId);

        return
            StakingDescriptor.constructTokenURI(
                StakingDescriptor.ConstructTokenURIParams({
                    tokenId: tokenId,
                    shares: shares,
                    freeAfter: freeAfter,
                    withdrawFreeAfter: withdrawFreeAfter,
                    accumulatorEth: accumulatorEth,
                    accumulatorToken: accumulatorToken
                })
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "contracts/libraries/errors/Base64Errors.sol";

/* solhint-disable */

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes internal constant TABLE_DECODE =
        hex"0000000000000000000000000000000000000000000000000000000000000000"
        hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
        hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
        hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly ("memory-safe") {
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
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);

        if (data.length % 4 != 0) {
            revert Base64Errors.InvalidDecoderInput(data.length % 4);
        }

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly ("memory-safe") {
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
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 4 characters
                dataPtr := add(dataPtr, 4)
                let input := mload(dataPtr)

                // write 3 bytes
                let output := add(
                    add(
                        shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                        shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))
                    ),
                    add(
                        shl(6, and(mload(add(tablePtr, and(shr(8, input), 0xFF))), 0xFF)),
                        and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}
/* solhint-enable */