/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;


interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/utils/math/SignedMath.sol


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

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// File: @openzeppelin/contracts/access/IAccessControl.sol


// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/access/AccessControl.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;





/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// File: contracts/IndexToken.sol



pragma solidity ^0.8.18 ;


//import "@openzeppelin/contracts/security/Pausable.sol";


contract IndexToken is ERC20, ERC20Burnable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint8 private tokenDecimal ; 
    constructor(  string memory name, string memory symbol , uint8 _tokenDecimal) ERC20( name , symbol ) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        tokenDecimal = _tokenDecimal ;
    }


    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }


    function decimals() public view  override returns (uint8) {
        return tokenDecimal;
    }

    

    function addMinter(address account) public  onlyRole (DEFAULT_ADMIN_ROLE)
    {
        grantRole(MINTER_ROLE, account);
    }


    function RemoveMinter(address account) public onlyRole (DEFAULT_ADMIN_ROLE)
    {
        //require( isRootAdmin(account) == false , "Removing Root Admin is not Allowed" );
        revokeRole(MINTER_ROLE, account);
    }

    function addPauser(address account) public  onlyRole (DEFAULT_ADMIN_ROLE)
    {
        grantRole(PAUSER_ROLE, account);
    }


    function RemovePauser(address account) public onlyRole (DEFAULT_ADMIN_ROLE)
    {
        //require( isRootAdmin(account) == false , "Removing Root Admin is not Allowed" );
        revokeRole(PAUSER_ROLE, account);
    }


}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/Bank.sol



pragma solidity ^0.8.18 ;








contract Bank is Pausable , Ownable  , AccessControl {

    // Library

    using SafeMath for uint;  
    using Counters for Counters.Counter;

    // STATE VARIABLES

    Counters.Counter private  purchaseIdCounter;
    bytes32 public constant Admin = keccak256("Admin");

    mapping (address => mapping (uint256 => uint256)) public purchasedIndexAmount; //buyer => indexID => amount of index that buyed in one transaction
    
    mapping (address => uint256) public purchasedTotalIndices; //amount of indices token that user have

    mapping (address => PurchasedIndicesInfo[]) public customerRecord;

    //mapping (address => mapping (address => uint256) ) public mintedTokens ;

    mapping ( address => mapping ( uint256 => PurchasedAssetInIndex ) ) public purchasedIndexAssetsInfo ;

    mapping ( uint256 => PurchasedIndicesInfo ) PurchasedHistory ; 

    // STRUCTS

    struct PurchasedIndicesInfo 
    {
        address owner ;
        uint256 purchaseId ; 
        uint256 indexId;
        uint256 purchaseValue;
        uint256 purchaseDate;
        uint256 amount ; 
        bool sold;
        uint256 sellPrice;
        uint256 sellDate;
        bool isOwner; 
        bool exist ; 
    }


    struct PurchasedAssetInIndex
    {

        uint256 purchaseId ;
        uint256[] assetIdList;
        uint256[] amount;
        uint256[] weightList;
        bool exist ; 

    }





    // EVENTS

    event AddAdminRole(address indexed adminAddress, string indexed role );
    event DelAdminRole(address indexed adminAddress, string indexed role );
    event AddPurchaseRecord( address indexed buyer , uint256 indexed purchaseId , uint256 indexed indexId , uint256 purchaseValue  , uint256 purchaseDate  , uint256 amount  );
    event PurchaseAssets ( address indexed buyer , uint256 indexed purchaseId , uint256 indexed indexId , uint256[] assetIdList  , uint256[] amount  , uint256[] weightList );



    // MODIFIERS & RELATED FUNCTIONS

    modifier onlyAdmin()
    {
        require(isAdmin(msg.sender) || isRootAdmin(msg.sender) , "Restricted to Admins.");
        _;
    }

    modifier onlyRootAdmin()
    {
        require( isRootAdmin(msg.sender) , "Restricted to Admins.");
        _;
    }



    function isRootAdmin(address account) public  view returns (bool)
    {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }


    function isAdmin(address account) public  view returns (bool)
    {
        return hasRole(Admin, account);
    }
    

    function addAdmin(address account) public  onlyRootAdmin
    {
        grantRole(Admin, account);
        emit AddAdminRole(  account , "Admin");
    }


    function RemoveAdmin(address account) public  onlyRootAdmin
    {
        require( isRootAdmin(account) == false , "Removing Root Admin is not Allowed" );
        revokeRole(Admin, account);
        emit DelAdminRole ( account , "Admin" ); 
    }


    function  PauseContract() public onlyAdmin //onlyAdmins
    {
        _pause();
    }

    function UnPauseContract() public onlyAdmin //onlyAdmins
    {
        _unpause();
    }

    // CONSTRUCTOR
    constructor(   )  
    {
        // assetManager = Assets( _assetManager ) ;
        // indexManager = Indices(_indexManager ) ;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(Admin, DEFAULT_ADMIN_ROLE);
        purchaseIdCounter.increment();
    }




    // Functions
    
    function addPurchaseRecord (  address _buyer ,  uint256 _indexId , uint256 _purchaseValue , uint256 _purchaseDate , uint256 _amount , uint256[] memory _assetIdList , uint256[] memory _amountAsset , uint256[] memory _weightList  ) public onlyAdmin returns ( uint256 )
    {
        uint256 purchaseIdValue = purchaseIdCounter.current() ; 

        PurchasedIndicesInfo memory purchasedIndexInfo = PurchasedIndicesInfo( _buyer , purchaseIdValue , _indexId , _purchaseValue , _purchaseDate , _amount , false , 0 , 0 , true , true   ) ;
        PurchasedAssetInIndex memory purchasedAssetInIndex = PurchasedAssetInIndex ( purchaseIdValue , _assetIdList ,  _amountAsset ,  _weightList  , true  ); 
        purchasedIndexInfo.purchaseId = purchaseIdValue ; 
        purchasedAssetInIndex.purchaseId = purchaseIdValue ; 
        purchasedIndexAmount[_buyer][ purchasedIndexInfo.indexId ] = purchasedIndexAmount[_buyer][ purchasedIndexInfo.indexId ].add(  purchasedIndexInfo.amount) ; 
        purchasedTotalIndices[_buyer] = purchasedTotalIndices[_buyer].add( purchasedIndexInfo.amount ) ;
        customerRecord[_buyer].push( purchasedIndexInfo );
        purchasedIndexAssetsInfo[_buyer][purchasedIndexInfo.purchaseId] = purchasedAssetInIndex ;
        PurchasedHistory[purchaseIdValue] = purchasedIndexInfo ; 

        purchaseIdCounter.increment() ; 
        emit  AddPurchaseRecord(  _buyer , purchasedIndexInfo.purchaseId , purchasedIndexInfo.indexId , purchasedIndexInfo.purchaseValue  , purchasedIndexInfo.purchaseDate  , purchasedIndexInfo.amount  );
        emit  PurchaseAssets ( _buyer , purchasedIndexInfo.purchaseId , purchasedIndexInfo.indexId  , _assetIdList  , _amountAsset  , _weightList );

        return purchaseIdValue ; 

    }


    // GETTER FUNCTIONS


    function getPurchasedIndexAmount ( uint256 _indexId , address _buyer  ) public view returns ( uint256)
    {
        return ( purchasedIndexAmount[_buyer][_indexId] );
    }

    function getPurchasedIndicesInfo ( address _buyer  ) public view returns ( PurchasedIndicesInfo[] memory )
    {
        require ( customerRecord[_buyer].length > 0 , "Record Doesn't exist.  " ); 
        return customerRecord[_buyer] ;
    }

    function getPurchasedAssetInIndex ( address _buyer , uint256 _purchaseId  ) public view returns ( PurchasedAssetInIndex memory ) 
    {
        require ( purchasedIndexAssetsInfo[_buyer][_purchaseId].exist == true , "Record Doesn't exist.  "  );
        return purchasedIndexAssetsInfo[_buyer][_purchaseId] ; 
    }



    function getPurchaseByPurchaseId (  uint256 _purchaseId ) public view returns ( PurchasedIndicesInfo memory , PurchasedAssetInIndex memory )
    {

        return ( PurchasedHistory[_purchaseId] , purchasedIndexAssetsInfo[  PurchasedHistory[_purchaseId].owner ] [_purchaseId] ) ; 
    }




}











// File: contracts/Assets.sol



pragma solidity ^0.8.18 ;







contract Assets is Pausable , Ownable  , AccessControl {

    // Library

    using SafeMath for uint; // 
    using Counters for Counters.Counter;


    // STATE VARIABLES

    Counters.Counter private  assetId;
    bytes32 public constant Admin = keccak256("Admin");

    mapping (uint256 => Asset) public whiteListAssetMap; /// @dev indexId => asset struct

    // CONSTRUCTOR
    constructor(  )  
    {

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(Admin, DEFAULT_ADMIN_ROLE);
        assetId.increment();
    }


    // STRUCTS

    struct Asset {

        uint256 id;
        uint256 decimal;
        string name;
        string symbol;
        string chainName;
        uint256 chainId;
        address tokenAddress;
        bool exist;
        bool enabled;         

    }

    

    
    // EVENTS

    event AssetCreated ( uint256 _id, string _name, string _symbol, string _chainName, address _tokenAddress);
    event AssetUpdated ( uint256 _id, string _name, string _symbol, string _chainName, address _tokenAddress);
    event AssetEnabled ( uint256 _id ) ;
    event AssetDisabled ( uint256 _id  ) ;
    event AddAdminRole(address indexed adminAddress, string indexed role );
    event DelAdminRole(address indexed adminAddress, string indexed role );


    // MODIFIERS & RELATED FUNCTIONS

    modifier onlyAdmin()
    {
        require(isAdmin(msg.sender) || isRootAdmin(msg.sender) , "Restricted to Admins.");
        _;
    }

    modifier onlyRootAdmin()
    {
        require( isRootAdmin(msg.sender) , "Restricted to Admins.");
        _;
    }



    function isRootAdmin(address account) public  view returns (bool)
    {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }


    function isAdmin(address account) public  view returns (bool)
    {
        return hasRole(Admin, account);
    }
    

    function addAdmin(address account) public  onlyRootAdmin
    {
        grantRole(Admin, account);
        emit AddAdminRole(  account , "Admin");
    }


    function RemoveAdmin(address account) public  onlyRootAdmin
    {
        require( isRootAdmin(account) == false , "Removing Root Admin is not Allowed" );
        revokeRole(Admin, account);
        emit DelAdminRole ( account , "Admin" ); 
    }


    function  PauseContract() public onlyAdmin //onlyAdmins
    {
        _pause();
    }

    function UnPauseContract() public onlyAdmin //onlyAdmins
    {
        _unpause();
    }



   // Functions



    function addAsset(uint256 _decimal, string memory _name, string memory _symbol, string memory _chainName, uint256 _chainId, address _tokenAddress  , bool _enabled ) public whenNotPaused onlyAdmin
    {  
        
        
        require(_decimal != 0, "decimal shoulden't be 0 ");
        require( keccak256(abi.encodePacked( _name )) != keccak256(abi.encodePacked("")) , "name shoulden't be null");
        require( keccak256(abi.encodePacked( _symbol )) != keccak256(abi.encodePacked("")) , "symbol shoulden't be null");
        require( keccak256(abi.encodePacked( _chainName )) != keccak256(abi.encodePacked("")) , "chainName shoulden't be null");
        require( _chainId != 0, "chainId shoulden't be 0 "); 
        require( _tokenAddress != address(0) , "tokenAddress shoulden't be 0 ");
        require ( checkAssetExist ( _decimal , _chainId , _tokenAddress ) == false , "Asset already exist. ") ;
        uint256 _id = assetId.current( );
        require(whiteListAssetMap[_id].exist == false, "Asset already exist. ");

        Asset memory asset = Asset ( _id , _decimal , _name , _symbol , _chainName , _chainId , _tokenAddress , _enabled , true   ) ;   
        
        whiteListAssetMap[_id] = asset ; 

        assetId.increment();

        emit AssetCreated(_id, _name, _symbol, _chainName, _tokenAddress);


    }

    function disableAsset(uint256 _id) public onlyAdmin whenNotPaused
    {
        require(_id != 0, "id shoulden't be 0 ");
        require(whiteListAssetMap[_id].exist == true, "Asset Doesn't exist. ");
        require( whiteListAssetMap[_id].enabled  == true , "Asset is Disabled");
        whiteListAssetMap[_id].enabled = false;
        emit AssetDisabled(_id);
    }

    function enableAsset(uint256 _id) public onlyAdmin whenNotPaused {
        require( _id != 0, "id shoulden't be 0 ");
        require(whiteListAssetMap[_id].exist == true, "Asset Doesn't exist. ");
        require( whiteListAssetMap[_id].enabled  == false , "Asset is Enabled");
        whiteListAssetMap[_id].enabled = true;
        emit AssetEnabled(_id);
    }

    function updateAsset ( uint256 _id ,uint256 _decimal, string memory _name, string memory _symbol, string memory _chainName, uint256 _chainId, address _tokenAddress  , bool _enabled ) public whenNotPaused onlyAdmin
    {

        require(_decimal != 0, "decimal shoulden't be 0 ");
        require( keccak256(abi.encodePacked( _name )) != keccak256(abi.encodePacked("")) , "name shoulden't be null");
        require( keccak256(abi.encodePacked( _symbol )) != keccak256(abi.encodePacked("")) , "symbol shoulden't be null");
        require( keccak256(abi.encodePacked( _chainName )) != keccak256(abi.encodePacked("")) , "chainName shoulden't be null");
        require( _chainId != 0, "chainId shoulden't be 0 "); 
        require( _tokenAddress != address(0) , "tokenAddress shoulden't be 0 ");
        require ( checkAssetExist ( _decimal , _chainId , _tokenAddress ) == false , "Asset already exist. ") ;

        require(whiteListAssetMap[_id].exist == true, "Asset Doesn't exist. ");

        Asset memory asset = Asset ( _id , _decimal , _name , _symbol , _chainName , _chainId , _tokenAddress , _enabled , true   ) ;   
        
        whiteListAssetMap[_id] = asset ; 


        emit AssetUpdated(_id, _name, _symbol, _chainName, _tokenAddress);

    }



    // GETTER FUNCTIONS

    function getAsset(uint256 _id) public view returns ( Asset memory ) {
        require( _id != 0, "id shoulden't be 0 ");
        require( whiteListAssetMap[_id].exist == true , "id is not valid");
        return (whiteListAssetMap[_id]);

    }

    function getAssetsOfIndex(uint256 [] memory  _ids ) public view returns ( Asset [] memory ) {
        
        Asset[] memory  result  = new Asset[] ( _ids.length ) ;
        uint256 array_index = 0 ;

        for ( uint256 i = 0  ; i < _ids.length;  i++ )
        {
            require( whiteListAssetMap[ _ids[i]  ].exist == true , "id is not valid"); 
            result[ array_index ] = whiteListAssetMap[ _ids[i] ]  ;
            array_index = array_index.add(1) ; 
        }
        
        return result;

    }

    function getAssetCount () public view returns ( uint256 )
    {
        return assetId.current().sub(1) ;
    }

    function checkAssetExist ( uint256 _decimal  , uint256 _chainId, address _tokenAddress  ) public view returns ( bool )
    {
        for (  uint256 i = 1 ; i <= getAssetCount () ; i++  )
        {
            if (  whiteListAssetMap[i].decimal == _decimal   && 
                  whiteListAssetMap[i].chainId == _chainId   && 
                  whiteListAssetMap[i].tokenAddress == _tokenAddress  )
            {
                return true ;
            }

        }

        return false ; 

    }







}








// File: contracts/Indices.sol



pragma solidity ^0.8.18 ;








contract Indices is Pausable , Ownable  , AccessControl {

    // Library

    using SafeMath for uint;  
    using Counters for Counters.Counter;


    // STATE VARIABLES

    Counters.Counter private  indexId;
    bytes32 public constant Admin = keccak256("Admin");

    mapping (uint256 => Index ) public indicesMap ;//indexId => indexInfo
    mapping ( uint256 => Constituent ) private indexConstituent ; 

    Assets private assetManager ; 

    // STRUCTS 

    struct Constituent{
        //uint256 indexId; 
        uint256[] assetIdList;
        uint256[] weightList; // it's from 10000
    }

    struct Index{
        uint256 id;
        string name;
        string symbol;
        string description;
        uint256 decimal ; 
        address tokenAddress ; 
        uint256 price; // price in stable coin  
        uint256 createDate;
        //uint256 lastUpdate;
        uint256 assetCount;
        string chainName;
        uint256 chainId;
        bool enabled;
        bool exist;
    }

      


    // EVENTS

    event AddAdminRole(address indexed adminAddress, string indexed role );
    event DelAdminRole(address indexed adminAddress, string indexed role );
    event IndexCreated ( uint256 id , string name , string symbol , string description , uint256 price , string chainName , uint256 chainId , uint256 assetCount  ) ; 
    event IndexUpdated ( uint256 id , string name , string symbol , string description , uint256 price , string chainName , uint256 chainId , uint256 assetCount  ) ; 
    event IndexEnabled ( uint256 id  ) ;
    event IndexDisabled ( uint256 id  ) ;


    // MODIFIERS & RELATED FUNCTIONS

    modifier onlyAdmin()
    {
        require(isAdmin(msg.sender) || isRootAdmin(msg.sender) , "Restricted to Admins.");
        _;
    }

    modifier onlyRootAdmin()
    {
        require( isRootAdmin(msg.sender) , "Restricted to Admins.");
        _;
    }



    function isRootAdmin(address account) public  view returns (bool)
    {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }


    function isAdmin(address account) public  view returns (bool)
    {
        return hasRole(Admin, account);
    }
    

    function addAdmin(address account) public  onlyRootAdmin
    {
        grantRole(Admin, account);
        emit AddAdminRole(  account , "Admin");
    }


    function RemoveAdmin(address account) public  onlyRootAdmin
    {
        require( isRootAdmin(account) == false , "Removing Root Admin is not Allowed" );
        revokeRole(Admin, account);
        emit DelAdminRole ( account , "Admin" ); 
    }


    function  PauseContract() public onlyAdmin //onlyAdmins
    {
        _pause();
    }

    function UnPauseContract() public onlyAdmin //onlyAdmins
    {
        _unpause();
    }

    // CONSTRUCTOR
    constructor(  address _assetManager )  
    {
        assetManager = Assets( _assetManager ) ;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(Admin, DEFAULT_ADMIN_ROLE);
        indexId.increment();
    }


    // Functions
    

    function createIndex( string memory _name, string memory _symbol , uint256 _price , string memory _description , string memory  _chainName , uint256 _chainId , bool _enabled , Constituent memory  _constituent  , uint256 _decimal , address _tokenAddress   ) public whenNotPaused  onlyAdmin
    {   
        require( keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")) , "name shoulden't be null");
        require( keccak256(abi.encodePacked(_symbol)) != keccak256(abi.encodePacked("")) , "symbol shoulden't be null");
        require( keccak256(abi.encodePacked(_description)) != keccak256(abi.encodePacked("")) , "description shoulden't be null");
        require( keccak256(abi.encodePacked(_chainName)) != keccak256(abi.encodePacked("")) , "chainName shoulden't be null");
        require( _price > 0 , "price should be > 0 ");
        require( _chainId != 0, "chainId shoulden't be 0 "); 
        require( _constituent.assetIdList.length > 0 , "asset count should > 0 ");
        require(  _constituent.assetIdList.length ==  _constituent.weightList.length , "asset count and weight count should be equal" );
        //require( _tokenAddress != address(0) , "tokenAddress shoulden't be 0 ");

        uint256 _id = indexId.current() ;
        require( indicesMap[_id].exist == false, "index already exist. ");

        for ( uint i = 0 ; i < _constituent.assetIdList.length ; i++)
        {
            require ( assetManager.getAsset( _constituent.assetIdList[i]  ).exist == true , "Asset Doesn't exist. " ) ;
            require ( assetManager.getAsset( _constituent.assetIdList[i]  ).enabled == true , "Asset isn't enabled. ") ; 
        }

        uint256 sum = 0 ;
        for ( uint i = 0 ; i < _constituent.weightList.length ; i++)
        {
            sum = sum.add(  _constituent.weightList[i]  ); 
        }
        require ( sum == 10000 , "Wrong weight sum");
        
        Index memory index =  Index ( _id , _name , _symbol ,  _description , _decimal , _tokenAddress , _price  , block.timestamp  , _constituent.assetIdList.length , _chainName , _chainId , _enabled , true );

        indicesMap[_id] = index ; 
        indexConstituent[_id] = _constituent ;  
        indexId.increment();
        emit IndexCreated (  _id ,  _name , _symbol , _description , _price ,  _chainName ,  _chainId ,   _constituent.assetIdList.length  ) ; 
        
    }

  
    function updateIndex(  uint256 _id , string memory _name, string memory _symbol , uint256 _price , string memory _description , string memory  _chainName , uint256 _chainId , bool _enabled , Constituent memory  _constituent   , uint256 _decimal , address _tokenAddress    ) public  whenNotPaused onlyAdmin
    {   
        require( keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")) , "name shoulden't be null");
        require( keccak256(abi.encodePacked(_symbol)) != keccak256(abi.encodePacked("")) , "symbol shoulden't be null");
        require( keccak256(abi.encodePacked(_description)) != keccak256(abi.encodePacked("")) , "description shoulden't be null");
        require( keccak256(abi.encodePacked(_chainName)) != keccak256(abi.encodePacked("")) , "chainName shoulden't be null");
        require( _price > 0 , "price should be > 0 ");
        require( _chainId != 0, "chainId shoulden't be 0 "); 
        require( _constituent.assetIdList.length > 0 , "asset count should > 0 ");
        require(  _constituent.assetIdList.length ==  _constituent.weightList.length , "asset count and weight count should be equal" );
        //require( _tokenAddress != address(0) , "tokenAddress shoulden't be 0 ");

        require( indicesMap[_id].exist == true, "index Doesn't exist. ");

        for ( uint i = 0 ; i < _constituent.assetIdList.length ; i++)
        {
            require ( assetManager.getAsset( _constituent.assetIdList[i]  ).exist == true , "Asset Doesn't exist. " ) ;
            require ( assetManager.getAsset( _constituent.assetIdList[i]  ).enabled == true , "Asset isn't enabled. ") ; 
        }

        uint256 sum = 0 ;
        for ( uint i = 0 ; i < _constituent.weightList.length ; i++)
        {
            sum = sum.add(  _constituent.weightList[i]  ); 
        }
        require ( sum == 10000 , "Wrong weight sum");

        Index memory index =  Index ( _id , _name , _symbol ,  _description , _decimal , _tokenAddress , _price  , block.timestamp  , _constituent.assetIdList.length , _chainName , _chainId , _enabled , true );

        indicesMap[_id] = index ; 
        indexConstituent[_id] = _constituent ;  

        emit IndexUpdated (  _id ,  _name , _symbol , _description , _price ,  _chainName ,  _chainId ,   _constituent.assetIdList.length  ) ; 
        
    }


    function enableIndex(uint256 _indexId) public whenNotPaused onlyAdmin 
    {
        require( _indexId != 0, "id shoulden't be 0 ");
        require( indicesMap[_indexId].exist == true, "Index Doesn't exist. ");
        require( indicesMap[_indexId].enabled == false, "Index is enabled. ");
        indicesMap[_indexId].enabled = true; 
        emit IndexEnabled( _indexId );
    }

    function disableIndex(uint256 _indexId) public whenNotPaused onlyAdmin 
    {
        require( _indexId != 0, "id shoulden't be 0 ");
        require( indicesMap[_indexId].exist == true, "Index Doesn't exist. ");
        require( indicesMap[_indexId].enabled == true, "Index is disabled. ");
        indicesMap[_indexId].enabled = false; 
        emit IndexDisabled( _indexId );
    }


    function addAssetToIndex (uint256 _indexId , uint256 _assetId , uint256 _weight ) public whenNotPaused onlyAdmin
    {
        require( _indexId != 0, "id shoulden't be 0 ");
        require( indicesMap[_indexId].exist == true, "Index Doesn't exist. ");
        require ( assetManager.getAsset( _assetId  ).exist == true , "Asset Doesn't exist. " ) ;
        require ( assetManager.getAsset( _assetId ).enabled == true , "Asset isn't enabled. ") ;
        require( checkAssetExistInIndex( _indexId , _assetId ) == false , "Asset exist in Index" );

        indicesMap[_indexId].assetCount = indicesMap[_indexId].assetCount.add(1);
        //indicesMap[_indexId].lastUpdate = block.timestamp ;
        indexConstituent[_indexId].assetIdList.push(_assetId);
        indexConstituent[_indexId].weightList.push(_weight) ;

    }

    function removeAssetFromIndex (uint256 _indexId , uint256 _assetId  ) public whenNotPaused onlyAdmin
    {
        require( _indexId != 0, "id shoulden't be 0 ");
        require( indicesMap[_indexId].exist == true, "Index Doesn't exist. ");
        require ( assetManager.getAsset( _assetId  ).exist == true , "Asset Doesn't exist. " ) ;
        require( checkAssetExistInIndex( _indexId , _assetId ) == true , "Asset exist in Index" );

        indicesMap[_indexId].assetCount = indicesMap[_indexId].assetCount.sub(1);
        //indicesMap[_indexId].lastUpdate = block.timestamp ;

        uint256 length = indexConstituent[_indexId].assetIdList.length ;

        for ( uint256 i = 0 ; i < indexConstituent[_indexId].assetIdList.length ; i++  )
        {
            if ( indexConstituent[_indexId].assetIdList[i] == _assetId )
            {
                indexConstituent[_indexId].assetIdList[i] = indexConstituent[_indexId].assetIdList[  length.sub(1)  ] ;
                indexConstituent[_indexId].weightList[i] = indexConstituent[_indexId].weightList[   length.sub(1) ]  ;
                indexConstituent[_indexId].assetIdList.pop();
                indexConstituent[_indexId].weightList.pop();
            }
        }
        // indexConstituent[_indexId].assetIdList.push(_assetId);
        // indexConstituent[_indexId].weightList.push(_weight) ;

    }



    function changeAssetWeight (uint256 _indexId , uint256 _assetId , uint256 _weight ) public whenNotPaused onlyAdmin
    {
        require( _indexId != 0, "id shoulden't be 0 ");
        require( indicesMap[_indexId].exist == true, "Index Doesn't exist. ");
        require( checkAssetExistInIndex( _indexId , _assetId ) == true , "Asset Doesn't exist in Index" );

        for ( uint256 i = 0 ; i < indexConstituent[_indexId].assetIdList.length ; i++  )
        {
            if ( indexConstituent[_indexId].assetIdList[i] == _assetId )
            {
                indexConstituent[_indexId].weightList[i] = _weight ;
            }
        }
        //indicesMap[_indexId].lastUpdate = block.timestamp ;
    }

    function setPriceOfIndex ( uint256 _indexId  , uint256 _price ) public whenNotPaused onlyAdmin
    {
        require( _indexId != 0, "id shoulden't be 0 ");
        require( indicesMap[_indexId].exist == true, "Index Doesn't exist. ");
        indicesMap[_indexId].price = _price ; 
    }


    // GETTER FUNCTIONS

    function checkAssetExistInIndex ( uint256 _indexId , uint256 _assetId ) public view returns (bool)
    {
        require( _indexId != 0, "id shoulden't be 0 ");
        require( indicesMap[_indexId].exist == true, "Index Doesn't exist. ");

        for ( uint256 i = 0 ; i < indexConstituent[_indexId].assetIdList.length ; i++  )
        {
            if ( indexConstituent[_indexId].assetIdList[i] == _assetId )
            {
                return true ;
            }
        }
        return false ; 
    }


    function getIndex(uint256 _id) public view returns(Index memory )
    {
        require( _id != 0, "id shoulden't be 0 ");
        require( indicesMap[_id].exist == true, "Index Doesn't exist. ");
        return ( indicesMap[_id] ); 
    }




    function getConstituent(uint256 _id ) public view returns ( Constituent memory ) 
    {

        require( _id != 0, "id shoulden't be 0 ");
        require( indicesMap[_id].exist == true, "Index Doesn't exist. ");
        return indexConstituent[_id] ;
    }

    function getIndices (uint256 [] memory  _ids ) public view returns ( Index [] memory ) {
        
        Index[] memory  result  = new Index[] ( _ids.length ) ;
        uint256 array_index = 0 ;

        for ( uint256 i = 0  ; i < _ids.length;  i++ )
        {
            require( indicesMap[ _ids[i]  ].exist == true , "id is not valid"); 
            result[ array_index ] = indicesMap[ _ids[i] ]  ;
            array_index = array_index.add(1) ; 
        }
        
        return result;

    }

    function getIndexAssetCount ( uint256 _indexId ) public view returns ( uint256 )
    {
        return indexConstituent[ _indexId ].assetIdList.length ; 
    }

    function getConstituents (uint256[] memory  _ids ) public view returns ( Constituent [] memory ) 
    {

        Constituent[] memory  result  = new Constituent[] ( _ids.length ) ;
        uint256 array_index = 0 ;

        for ( uint256 i = 0  ; i < _ids.length;  i++ )
        {
            require( indicesMap[ _ids[i]  ].exist == true , "id is not valid"); 
            result[ array_index ] = indexConstituent[ _ids[i] ]  ;
            array_index = array_index.add(1) ; 
        }
        
        return result;
    }

    function getAssetsOfIndex ( uint256 _indexId ) public view returns ( Assets.Asset [] memory )
    {
        require( _indexId != 0, "id shoulden't be 0 ");
        require( indicesMap[_indexId].exist == true, "Index Doesn't exist. ");
        return assetManager.getAssetsOfIndex(indexConstituent[_indexId].assetIdList) ; 
    }


    function getIndexAndItsAssets ( uint256 _indexId ) public view returns (Index  memory ,  Assets.Asset [] memory )
    {

        require( _indexId != 0, "id shoulden't be 0 ");
        require( indicesMap[_indexId].exist == true, "Index Doesn't exist. ");
        return ( indicesMap[_indexId] , getAssetsOfIndex(_indexId)  ) ;  

    }


}

// File: contracts/MainController.sol




pragma solidity ^0.8.18 ;












contract MainController is Pausable , Ownable  , AccessControl {

    // Library

    using SafeMath for uint;  


    // STATE VARIABLES

    bytes32 public constant Admin = keccak256("Admin");
    Assets private assetManager ; 
    Indices private indexManager ; 
    Bank private bankManager ; 

    uint256 public feePercent ;// it's from 10000
    uint256 public slippage ; 
    bool public automatic ; 
    bool public feeIsStableCoin ; 
    StableCoin public USDC ; 
 

    //address private constant UNISWAP_V2_ROUTER = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D" ;
    IUniswapV2Router02 private router ;



    // STRUCTS 

    struct StableCoin
    {
        address tokenAddress ; 
        string name ; 
        string symbol ; 
        string chainName ; 
        uint256 chainId ; 
        uint256 decimal ;  
    }


    // EVENTS

    event AddAdminRole(address indexed adminAddress, string indexed role );
    event DelAdminRole(address indexed adminAddress, string indexed role );
    event Log(string func, uint gas);
    event FinanceLog(   uint256 indexed purchaseId , uint256 purchaseValue , uint256 feeValue , uint256 receivedValue , uint256 remainderValue  ) ;


    // MODIFIERS & RELATED FUNCTIONS

    modifier onlyAdmin()
    {
        require(isAdmin(msg.sender) || isRootAdmin(msg.sender) , "Restricted to Admins.");
        _;
    }

    modifier onlyRootAdmin()
    {
        require( isRootAdmin(msg.sender) , "Restricted to Admins.");
        _;
    }



    function isRootAdmin(address account) public  view returns (bool)
    {
        return hasRole(DEFAULT_ADMIN_ROLE, account);
    }


    function isAdmin(address account) public  view returns (bool)
    {
        return hasRole(Admin, account);
    }
    

    function addAdmin(address account) public  onlyRootAdmin
    {
        grantRole(Admin, account);
        emit AddAdminRole(  account , "Admin");
    }


    function RemoveAdmin(address account) public  onlyRootAdmin
    {
        require( isRootAdmin(account) == false , "Removing Root Admin is not Allowed" );
        revokeRole(Admin, account);
        emit DelAdminRole ( account , "Admin" ); 
    }


    function  PauseContract() public onlyAdmin //onlyAdmins
    {
        _pause();
    }

    function UnPauseContract() public onlyAdmin //onlyAdmins
    {
        _unpause();
    }

    // CONSTRUCTOR
    constructor(  address _assetManager , address _indexManager , address _bankManager , address UNISWAP_V2_ROUTER  )  
    {
        assetManager = Assets( _assetManager ) ;
        indexManager = Indices ( _indexManager ) ; 
        bankManager = Bank ( _bankManager ) ; 
        router = IUniswapV2Router02(UNISWAP_V2_ROUTER);
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(Admin, DEFAULT_ADMIN_ROLE);
        
    }

    // Functions

    function buyIndex ( uint256 _indexId , uint256 amount ) public whenNotPaused  payable 
    {
        require ( indexManager.getIndex(_indexId).exist == true , "Index Doesn't exist. "   ) ;
        require ( indexManager.getIndex(_indexId).enabled == true , "Index isn't enabled. "   ) ;
        
        IERC20  token = IERC20( USDC.tokenAddress ) ;
        bool success = token.transferFrom ( msg.sender , address(this) , amount ) ; 
        require ( success , "Transfer Error") ; 


        uint256 amountAfterFee = amount ;


        if (feeIsStableCoin == true  )
        {
            amountAfterFee = amount.sub( amount.mul(feePercent).div(10000)   );
        }
        else 
        {
            //require ( msg.value == ( amount.mul(feePercent).div(10000)  )  , "Transaction Fee is not Enough"  );
            amountAfterFee = amount ; 
        }

        uint256 feeValue = amount.mul(feePercent).div(10000) ;
        //require (  ( amountAfterFee * ( 10 ** USDC.decimal ) ).mod(  indexManager.getIndex(_indexId).price   ) == 0 , "Amount after fee is not divisable by token price"    );
        uint256 indexTokenAmount = ( amountAfterFee  ).div(  indexManager.getIndex(_indexId).price   ) ; 
        uint256 remainder = ( amountAfterFee  ).mod(  indexManager.getIndex(_indexId).price   ) ; 
        amountAfterFee = amountAfterFee.sub(remainder);
        require ( indexTokenAmount > 0 , "insufficient money for one unit of token");

        if ( automatic == true )
        {
            
            require(token.approve(address(router), amountAfterFee ), "approve failed.");

            Assets.Asset[] memory assetsOfIndex = indexManager.getAssetsOfIndex ( _indexId ) ;
            Indices.Constituent memory assetConstituent = indexManager.getConstituent ( _indexId ) ; 

            uint256[] memory assetBoughtAmount = new uint256[]( indexManager.getIndexAssetCount(  _indexId ) ) ; 

            for ( uint256 i = 0 ; i < indexManager.getIndexAssetCount(  _indexId ) ; i++ )
            {
                address[] memory path;
                path = new address[](2);
                path[0] = USDC.tokenAddress;
                path[1] = assetsOfIndex[i].tokenAddress;

                require ( assetConstituent.assetIdList[i] == assetsOfIndex[i].id  , "Error");

                uint256 amountIn = ( amountAfterFee  ).mul( assetConstituent.weightList[i]  ).div(10000)  ;
                uint256[] memory amountOutMin =  router.getAmountsOut( amountIn , path ); 
                uint256 amountOutMinWithSlippage = amountOutMin[1].sub(   amountOutMin[1].mul(slippage).div(10000)   );


                uint256[] memory amounts = router.swapExactTokensForTokens(
                    amountIn,
                    amountOutMinWithSlippage,
                    path,
                    address(this),
                    block.timestamp
                );
                assetBoughtAmount[i] = amounts[1] ; 
            }
            
            uint256 purchaseId = bankManager.addPurchaseRecord ( msg.sender , _indexId , amountAfterFee ,  block.timestamp , indexTokenAmount , assetConstituent.assetIdList , assetBoughtAmount , assetConstituent.weightList );
            emit FinanceLog(  purchaseId  , amountAfterFee  , feeValue ,   amount , remainder ) ;
    

            
            IndexToken  indexTokenV1 = IndexToken( indexManager.getIndex(_indexId).tokenAddress )  ;
            indexTokenV1.mint( msg.sender , indexTokenAmount ); 
            require (token.transfer(msg.sender, remainder) == true , "Transfer Failed"  ) ;


        }

        // else 
        // {

        // }
        
    }



    
    function withdrawBalance  ( address dest , uint256 amount  ) public  onlyRootAdmin  returns ( bool )
    {
        (bool success, )= payable(dest).call{value: amount}("");
        require ( success );
        return success ; 
    }



    function withdrawBalanceStableCoin  ( address dest , uint256 amount ,  address StableCoinTokenAddress  ) public  onlyRootAdmin  returns ( bool )
    {
        //require ( ApprovedContracts[StableCoin] == true , "Contract is not Approved" ) ;
        IERC20  token = IERC20(StableCoinTokenAddress) ;
        bool success = token.transfer(dest, amount);
        require ( success ) ; 
        return success ; 
    }



   
    fallback() external payable {

        emit Log("fallback", gasleft());
    }

   
    receive() external payable {
        emit Log("receive", gasleft());
    }

    function setFeePercent ( uint256  _feePercent) public onlyAdmin
    {
        require( _feePercent <= 10000 , "Wrong fee Percent");
        feePercent = _feePercent ; 
    }

    function setSlippage ( uint256 _slippage ) public onlyAdmin
    {
        slippage = _slippage ; 
    }
    
    function setAutomatic ( bool _automatic ) public onlyAdmin
    {
        automatic = _automatic ; 
    }

    function setFeeIsStableCoin  ( bool _feeIsStableCoin  ) public  onlyAdmin
    {
        feeIsStableCoin = _feeIsStableCoin ;
 
    }


    function setUSDC ( string memory  _name , string memory _symbol , string memory  _chainName , uint256 _chainId , address _tokenAddress , uint256 _decimal ) public onlyAdmin
    {
        require( keccak256(abi.encodePacked(_name)) != keccak256(abi.encodePacked("")) , "name shoulden't be null");
        require( keccak256(abi.encodePacked(_symbol)) != keccak256(abi.encodePacked("")) , "symbol shoulden't be null");
        require( keccak256(abi.encodePacked(_chainName)) != keccak256(abi.encodePacked("")) , "chainName shoulden't be null");
        require( _tokenAddress != address(0) , "tokenAddress shoulden't be 0 ");
        require( _chainId != 0, "chainId shoulden't be 0 "); 
        USDC = StableCoin ( _tokenAddress , _name , _symbol ,  _chainName , _chainId  , _decimal  ) ;
    }



    // GETTER FUNCTIONS

    function getFeePercent () public view returns ( uint256 )
    {
        return feePercent ;  
    }

    function getSlippage () public view returns ( uint256 )
    {
        return slippage ;
    }

    function getAutomatic () public view returns ( bool )
    {
        return automatic ;
    }

    function getFeeIsStableCoin () public view returns ( bool )
    {
        return feeIsStableCoin ; 
    }

    function getUSDC() public view returns ( StableCoin memory )
    {
        return USDC ;
    }



}