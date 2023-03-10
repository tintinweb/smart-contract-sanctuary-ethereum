// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// import './SafeMath.sol';
import './TransferHelper.sol';

//
//
// Alchemy HTTPS
// https://eth-mainnet.g.alchemy.com/v2/UDwRjbbyUVA5qTpiAXhyZSQSCct28qQM
// Alchemy WEBSOCKET
// wss://eth-mainnet.g.alchemy.com/v2/UDwRjbbyUVA5qTpiAXhyZSQSCct28qQM

contract SwapTrade {
	using SafeMath for uint;
    using SafeMath for uint256;

    struct PairInfo {
        address pair;
        address fromToken;
        address toToken;
        uint112 fromReserve;
        uint112 toReserve;
    }

    struct AmountInfo {
        address fromToken;
        uint tradeFee;
        uint256 fromAmountMin;
        uint256 fromAmountMax;
        uint256 fromAmountStep;
        uint minTradePercent;
    }

    struct MaxProfitAmountInfo {
        uint256 profit;
        // trade start amount
        uint256 tradeAmount;
        // trade amounts across the swaps
        uint256[] tradeAmounts;
        uint profitPercent;
    }

    //  https://docs.uniswap.org/contracts/v2/reference/smart-contracts/router-02
    // address private constant UNISWAP_V2_ROUTER02 = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    // IUniswapV2Router private v2_router = IUniswapV2Router(UNISWAP_V2_ROUTER02);

    // https://docs.uniswap.org/contracts/v2/reference/smart-contracts/factory
    // address private constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    // address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    // Strings.toHexString(uint160(owner), 20))

    // IUniswapV2Factory private v2_factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);
    mapping(address => PairInfo) internal pairInfoMapping;
    address payable public owner;

    modifier ensure(uint deadline) {
        require(deadline >= block.timestamp, 'EXPIRED');
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier validAddress(address _addr) {
        require(_addr != address(0), "Not valid address");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
        // TODO: Do we need to pass-in the token address list we want to support doing the "trade"?
    }

    function changeOwner(address _newOwner) external onlyOwner validAddress(_newOwner) {
        owner = payable(_newOwner);
    }

    // Approve
    // Parameter 1: spenderAddress
    // Parameter 2: tokenAddress
    // Parameter 3: amount to be approved
    // Note: max amount is 115792089237316195423570985008687907853269984665640564039457584007913129639935
    function approve(address _spenderAddress, address _tokenAddress, uint _amountToBeApproved) external onlyOwner {
        IERC20(_tokenAddress).approve(_spenderAddress, _amountToBeApproved);
    }

    // This function is used to transfer amount of a token out from contract to an address
    // Parameter1: token address
    // Parameter2: to addresss
    // Parameter3: amount
    // Note: Before calling this, needs to call approve so that owner can access fund from this contract address
    function transfer(address _tokenAddress, address _toAddress, uint _amount) external onlyOwner {
        IERC20(_tokenAddress).transferFrom(address(this), _toAddress, _amount);
    }

	function trade(
        // pair address like, for example, [USDC->WETH, WETH->DAI, DAI->USDT]
        address[] calldata _pairPath,
        // Trade fee on Dex, 30 means 0.3%, 25 means 0.25%
        uint _tradeFee,
        address _fromToken,
        // fromAmountMin/Max/Step will used to find the best trade amount
        uint256 _fromAmountMin,
        uint256 _fromAmountMax,
        uint256 _fromAmountStep,
        // 1 equals 0.1%, 5 is 0.5%, use this to decide whether we should trade or not
        uint _minTradePercent,
        // Client will tell us how much gasFee we should set
        uint _gasFee,
        uint _deadline)
    public ensure(_deadline) returns (uint status_code, string memory reason) {
        require(_pairPath.length > 0, "pairPath is empty");

        // TODO:  ETH has 18 decimals while USDC has 6 decimals, do we need to handle

        //1) Get each IUniswapV2Pair's token0/1 and reserve0/1 only once
        // NOTE: For any pair, we don't know whether it's token0->token1 or token1->token0, so we'll depends on the fromToken
        //       to decide the startToken of our pairPath, then setup the chain.fromToken
        ///      So in PairInfo array, it'll always be pairPath[0].token0->pairPath[0].token1->pairPath[1].token1->pairPath[2].token1
        PairInfo[] memory pairInfoList = _getPairInfoList(_pairPath, _fromToken);

        // 2) find the best profitable Amount
        AmountInfo memory amountInfo = AmountInfo({fromToken: _fromToken, tradeFee: _tradeFee, fromAmountMin: _fromAmountMin, fromAmountMax: _fromAmountMax, fromAmountStep: _fromAmountStep, minTradePercent: _minTradePercent});

        MaxProfitAmountInfo memory maxProfitableAmountInfo = _getBestProfitableAmount(pairInfoList, amountInfo);
        if (maxProfitableAmountInfo.tradeAmount == 0) {
            // Can't profit, just return
            return (101, string(abi.encodePacked("Cannot profit, profitPercent=", Strings.toString(maxProfitableAmountInfo.profitPercent))));
        }

        //3) Swap the tokens
		//4.1) send money from msg.sender to the first token
        TransferHelper.safeTransferFrom(
            _fromToken, msg.sender, pairInfoList[0].pair, maxProfitableAmountInfo.tradeAmount
        );
		// fromTokenIERC20.transferFrom(msg.sender, address(this), fromAmount);

        //4.2) Do the swaps
        //TODO: check the logic
        _swap(maxProfitableAmountInfo.tradeAmounts, pairInfoList, msg.sender);

        // TODO: where to set the gasFee?
        // 4.3) Send money back to msg.sender
        // TransferHelper.safeTransfer(toToken, msg.sender, toTokenIERC20.balanceOf(msg.sender));
        // Get new wallet balance
        // IERC20(pairInfoList[pairPath.length.sub(1)].toToken).balanceOf(msg.sender)

        return (0, '');
	}

    function _getPairInfoList(address[] calldata pairPath, address fromToken) internal returns (PairInfo[] memory pairInfoList) {
        PairInfo[] memory infoList = new PairInfo[](pairPath.length);
        address formerToken = fromToken;
        for (uint i; i < pairPath.length; i++) {
            (address token0, address token1, uint112 reserve0, uint112 reserve1) = _getPairInfo(pairPath[i]);
            if (formerToken == token0) {
                infoList[i] = PairInfo({pair: pairPath[i], fromToken: token0, toToken: token1, fromReserve: reserve0, toReserve: reserve1});
                pairInfoMapping[pairPath[i]] = infoList[i];
                formerToken = token1;
            } else if (formerToken == token1) {
                infoList[i] = PairInfo({pair: pairPath[i], fromToken: token1, toToken: token0, fromReserve: reserve1, toReserve: reserve0});
                pairInfoMapping[pairPath[i]] = infoList[i];
                formerToken = token0;
            } else {
                string memory errMsg = string(abi.encodePacked("pairPath can't create a swap token chain. formerToken=", Strings.toHexString(uint160(formerToken), 20), ", token0=", Strings.toHexString(uint160(token0), 20)));
                require(false, errMsg);
            }
        }

        return infoList;
    }

    // Find the max profitable amount
    function _getBestProfitableAmount(PairInfo[] memory pairInfoList, AmountInfo memory amountInfo) internal view returns (MaxProfitAmountInfo memory returnAmountInfo) {
        IERC20 fromTokenIERC20 = IERC20(amountInfo.fromToken);

        uint256 walletBalance = fromTokenIERC20.balanceOf(msg.sender);
        require(walletBalance >= amountInfo.fromAmountMin, "wallet balance must greater than fromAmountMin");

        //2) Find the max profitable amount
        uint256 maxAmount = amountInfo.fromAmountMax;
        if (maxAmount > walletBalance) {
            maxAmount = walletBalance;
        }

        MaxProfitAmountInfo memory maxProfitAmountInfo = MaxProfitAmountInfo({profit: 0, tradeAmount: 0, tradeAmounts: new uint256[](0), profitPercent: 0});
        uint256 currentAmount = amountInfo.fromAmountMin;

        uint256[] memory amounts;
        while(currentAmount <= maxAmount) {
            amounts = new uint256[](pairInfoList.length+1);
            amounts[0] = currentAmount;
            for (uint i; i < pairInfoList.length; i++) {
                amounts[i + 1] = _getAmountOut(amounts[i], pairInfoList[i].fromReserve, pairInfoList[i].toReserve, amountInfo.tradeFee);
            }

            uint256 profit = amounts[pairInfoList.length-1].sub(currentAmount);

            // If profit is less than minTradePercent, we'll stop increasing the amount
            if (profit.mul(1000).div(currentAmount) < amountInfo.minTradePercent) {
                // TODO: Should we start from startAmount or endAmount?
                break;
            }

            if (profit > maxProfitAmountInfo.profit) {
                maxProfitAmountInfo.profit = profit;
                maxProfitAmountInfo.tradeAmount = currentAmount;
                maxProfitAmountInfo.tradeAmounts = amounts;
            }

            currentAmount += amountInfo.fromAmountStep;
        }

        // If the trade is not profitable, will raise an error
        maxProfitAmountInfo.profitPercent = maxProfitAmountInfo.profit.mul(1000).div(maxProfitAmountInfo.tradeAmount);
        if (maxProfitAmountInfo.profitPercent < amountInfo.minTradePercent) {
            // External logic will check tradeAmount to decide whether it should continue do the swap or not
            maxProfitAmountInfo.tradeAmount = 0;
        }

        return maxProfitAmountInfo;
    }

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function _sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'ZERO_ADDRESS');
    }


    // fetches and sorts the reserves for a pair
    function _getPairInfo(address pairAddress) internal view returns (address token0, address token1, uint112 reserve0, uint112 reserve1) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint112 pairReserve0, uint112 pairReserve1,) = pair.getReserves();
        address pairToken0 = pair.token0.address;
        address pairToken1 = pair.token1.address;
        return (pairToken0, pairToken1, pairReserve0, pairReserve1);
    }

    // requires the initial amount to have already been sent to the first pair
    function _swap(uint256[] memory amounts, PairInfo[] memory pairInfoList, address _to) internal {
        for (uint i; i < pairInfoList.length; i++) {
            address to = i < pairInfoList.length - 1 ? pairInfoList[i+1].pair : _to;
            IUniswapV2Pair(pairInfoList[i].pair).swap(
                uint(0), amounts[i + 1], to, new bytes(0)
            );
        }
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut, uint tradeFee) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, 'INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
        uint256 feeDenominator = 10000 - tradeFee;
        uint256 amountInWithFee = amountIn.mul(feeDenominator);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(10000).add(amountInWithFee);
        // x*y=k, numerator is k, assuming AmountIn is a, AmountOut is b
        // (x+a)*(y-b)=x*y => y-b=(x*y)/(x+a) => b=y-(x*y)/(x+a) => b=(y*x+y*a-x*y)/(x+a) => b=(y*a)/(x+a)
        amountOut = numerator / denominator;
        return amountOut;
    }

//    // fetches and sorts the reserves for a pair
//    function _getReserves(address tokenA, address tokenB) internal returns (uint112 reserveA, uint112 reserveB) {
//        (address token0,) = _sortTokens(tokenA, tokenB);
//        (uint112 reserve0, uint112 reserve1,) = IUniswapV2Pair(_pairFor(tokenA, tokenB)).getReserves();
//        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
//    }

//    // calculates the CREATE2 address for a pair without making any external calls
//    function _pairFor(address tokenA, address tokenB) internal returns (address pair) {
//        (address token0, address token1) = _sortTokens(tokenA, tokenB);
//        pair = address(uint(keccak256(abi.encodePacked(
//                hex'ff',
//                v2_factory,
//                keccak256(abi.encodePacked(token0, token1)),
//                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
//            ))));
//    }

//    function _swapExactTokensForTokens(
//        uint amountIn,
//        uint amountOutMin,
//        address fromToken,
//        address toToken,
//        address to,
//        uint deadline)
//    internal ensure(deadline) returns (uint[] memory amounts) {
//        amounts = _getAmountsOut(v2_factory, amountIn, path);
//        require(amounts[amounts.length - 1] >= amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
//        TransferHelper.safeTransferFrom(path[0], msg.sender, _pairFor(path[0], path[1]), amounts[0]);
//        _swap(amounts, path, to);
//    }
//
//    // performs chained getAmountOut calculations on any number of pairs
//    function _getAmountsOut(uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
//        require(path.length >= 2, 'INVALID_PATH');
//        amounts = new uint[](path.length);
//        amounts[0] = amountIn;
//        for (uint i; i < path.length - 1; i++) {
//            (uint reserveIn, uint reserveOut) = _getReserves(path[i], path[i + 1]);
//            amounts[i + 1] = _getAmountOut(amounts[i], reserveIn, reserveOut);
//        }
//    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}