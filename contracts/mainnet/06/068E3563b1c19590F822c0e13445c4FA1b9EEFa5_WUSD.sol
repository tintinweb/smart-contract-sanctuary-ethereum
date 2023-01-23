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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


interface IERC20
{
  function name () external view returns (string memory);

  function symbol () external view returns (string memory);

  function decimals () external view returns (uint8);

  function totalSupply () external view returns (uint256);

  function balanceOf (address account) external view returns (uint256);


  function allowance (address owner, address spender) external view returns (uint256);

  function approve (address spender, uint256 amount) external returns (bool);


  function transfer (address to, uint256 amount) external returns (bool);

  function transferFrom (address from, address to, uint256 amount) external returns (bool);


  function mint (address account, uint256 amount) external;

  function burn (address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


interface IFrontender
{
  function isRegistered (address account) external view returns (bool);

  function refer (address account, uint256 amount, address referrer) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


interface IGlove
{
  function balanceOf (address account) external view returns (uint256);


  function creditOf (address account) external view returns (uint256);

  function creditlessOf (address account) external view returns (uint256);


  function transfer (address to, uint256 amount) external returns (bool);

  function transferFrom (address from, address to, uint256 amount) external returns (bool);

  function transferCreditless (address to, uint256 amount) external returns (bool);


  function mint (address account, uint256 amount) external;

  function mintCreditless (address account, uint256 amount) external;

  function creditize (address account, uint256 credits) external returns (bool);


  function burn (address account, uint256 amount) external;

  function decreditize (address account, uint256 credits) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


interface IRegistry
{
  function get (string calldata name) external view returns (address);


  function provisioner () external view returns (address);

  function frontender () external view returns (address);

  function collector () external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


struct Snapshot
{
  uint32 epoch;
  uint112 last;
  uint112 cumulative;
}

interface IWUSD
{
  function balanceOf (address account) external view returns (uint256);


  function snapshot () external view returns (Snapshot memory);

  function epochOf (address account) external view returns (uint256);


  function allowance (address owner, address spender) external view returns (uint256);

  function approve (address spender, uint256 amount) external returns (bool);


  function transfer (address to, uint256 amount) external returns (bool);

  function transferFrom (address from, address to, uint256 amount ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


abstract contract ReentrancyGuard
{
  uint256 private _status = 1;


  modifier nonReentrant ()
  {
    require(_status == 1, "reentrance");


    _status = 2;

    _;

    _status = 1;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IERC20 } from "../interfaces/IERC20.sol";


library SafeToken
{
  function _getRevertErr (bytes memory data, string memory message) private pure returns (string memory)
  {
    if (data.length < 68)
    {
      return message;
    }


    assembly
    {
      data := add(data, 0x04)
    }


    return abi.decode(data, (string));
  }


  function _call (address token, bytes memory encoded, string memory message) private
  {
    (bool success, bytes memory data) = token.call(encoded);


    require(success && (data.length == 0 || abi.decode(data, (bool))), _getRevertErr(data, message));
  }

  function safeApprove (IERC20 token, address spender, uint256 amount) internal
  {
    _call(address(token), abi.encodeWithSelector(IERC20.approve.selector, spender, amount), "!sa");
  }

  function safeTransfer (IERC20 token, address to, uint256 amount) internal
  {
    _call(address(token), abi.encodeWithSelector(IERC20.transfer.selector, to, amount), "!st");
  }

  function safeTransferFrom (IERC20 token, address from, address to, uint256 amount) internal
  {
    _call(address(token), abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount), "!stf");
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import { ReentrancyGuard } from "./utils/ReentrancyGuard.sol";
import { SafeToken } from "./utils/SafeToken.sol";

import { IERC20 } from "./interfaces/IERC20.sol";
import { IGlove } from "./interfaces/IGlove.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";
import { IFrontender } from "./interfaces/IFrontender.sol";
import { Snapshot, IWUSD } from "./interfaces/IWUSD.sol";


contract WUSD is IWUSD, ReentrancyGuard
{
  using SafeToken for IERC20;
  using EnumerableSet for EnumerableSet.AddressSet;


  bytes32 private constant _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
  bytes32 private constant _DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

  bytes32 private constant _NAME_HASH = keccak256("Wrapped USD");
  bytes32 private constant _VERSION_HASH = keccak256("1");


  ISwapRouter private constant _ROUTER = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

  IRegistry private constant _REGISTRY = IRegistry(0x4E23524aA15c689F2d100D49E27F28f8E5088C0D);

  address private constant _GLOVE = 0x70c5f366dB60A2a0C59C4C24754803Ee47Ed7284;
  address private constant _USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  address private constant _USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

  uint256 private constant _MIN_GLOVABLE = 100e18;
  uint256 private constant _MID_GLOVE = 0.01e18;
  uint256 private constant _MAX_GLOVE = 2e18;
  uint256 private constant _EPOCH = 100_000e18;

  uint24 private constant _ROUTE = 500;


  bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
  uint256 private immutable _CACHED_CHAIN_ID;
  address private immutable _CACHED_THIS;


  Snapshot private _snapshot;
  EnumerableSet.AddressSet private _fiatcoins;


  uint256 private _totalSupply;

  mapping(address => uint256) private _epoch;
  mapping(address => uint256) private _decimal;

  mapping(address => uint256) private _nonce;

  mapping(address => uint256) private _balance;
  mapping(address => mapping(address => uint256)) private _allowance;


  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  event Wrap(address indexed account, address fiatcoin, uint256 amount, address referrer);
  event Unwrap(address indexed account, address fiatcoin, uint256 amount);


  constructor (address[] memory fiatcoins)
  {
    uint256 decimal;
    address fiatcoin;

    for (uint256 i; i < fiatcoins.length;)
    {
      fiatcoin = fiatcoins[i];
      decimal = IERC20(fiatcoin).decimals();

      _fiatcoins.add(fiatcoin);
      _decimal[fiatcoin] = decimal;

      IERC20(fiatcoin).safeApprove(address(_ROUTER), type(uint128).max);


      unchecked { i++; }
    }


    _CACHED_THIS = address(this);
    _CACHED_CHAIN_ID = block.chainid;
    _CACHED_DOMAIN_SEPARATOR = _separator();


    _snapshot = Snapshot({ epoch: 1, last: 0, cumulative: 0 });
  }

  function name () public pure returns (string memory)
  {
    return "Wrapped USD";
  }

  function symbol () public pure returns (string memory)
  {
    return "WUSD";
  }

  function decimals () public pure returns (uint8)
  {
    return 18;
  }

  function totalSupply () public view returns (uint256)
  {
    return _totalSupply;
  }

  function balanceOf (address account) public view returns (uint256)
  {
    return _balance[account];
  }


  function snapshot () public view returns (Snapshot memory)
  {
    return _snapshot;
  }

  function epochOf (address account) public view returns (uint256)
  {
    return _epoch[account];
  }


  function _separator () private view returns (bytes32)
  {
    return keccak256(abi.encode(_DOMAIN_TYPEHASH, _NAME_HASH, _VERSION_HASH, block.chainid, address(this)));
  }

  function DOMAIN_SEPARATOR () public view returns (bytes32)
  {
    return (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) ? _CACHED_DOMAIN_SEPARATOR : _separator();
  }

  function nonces (address owner) public view returns (uint256)
  {
    return _nonce[owner];
  }

  function allowance (address owner, address spender) public view returns (uint256)
  {
    return _allowance[owner][spender];
  }


  function _approve (address owner, address spender, uint256 amount) internal
  {
    _allowance[owner][spender] = amount;


    emit Approval(owner, spender, amount);
  }

  function approve (address spender, uint256 amount) public returns (bool)
  {
    _approve(msg.sender, spender, amount);


    return true;
  }

  function increaseAllowance (address spender, uint256 amount) public returns (bool)
  {
    _approve(msg.sender, spender, _allowance[msg.sender][spender] + amount);


    return true;
  }

  function decreaseAllowance (address spender, uint256 amount) public returns (bool)
  {
    uint256 currentAllowance = _allowance[msg.sender][spender];

    require(currentAllowance >= amount, "WUSD: decreasing < 0");


    unchecked
    {
      _approve(msg.sender, spender, currentAllowance - amount);
    }


    return true;
  }

  function permit (address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) public
  {
    require(block.timestamp <= deadline, "WUSD: expired deadline");


    bytes32 hash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _nonce[owner]++, deadline));
    address signer = ecrecover(keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), hash)), v, r, s);

    require(signer != address(0) && signer == owner, "WUSD: !valid signature");


    _approve(owner, spender, value);
  }


  function _transfer (address from, address to, uint256 amount) internal
  {
    require(to != address(0), "WUSD: transfer to 0 addr");


    uint256 balance = _balance[from];

    require(balance >= amount, "WUSD: amount > balance");


    unchecked
    {
      _balance[from] = balance - amount;
      _balance[to] += amount;
    }


    emit Transfer(from, to, amount);
  }

  function transfer (address to, uint256 amount) public returns (bool)
  {
    _transfer(msg.sender, to, amount);


    return true;
  }

  function transferFrom (address from, address to, uint256 amount) public returns (bool)
  {
    uint256 currentAllowance = _allowance[from][msg.sender];


    if (currentAllowance != type(uint256).max)
    {
      require(currentAllowance >= amount, "WUSD: !enough allowance");


      unchecked
      {
        _approve(from, msg.sender, currentAllowance - amount);
      }
    }


    _transfer(from, to, amount);


    return true;
  }


  function _percent (uint256 amount, uint256 percent) internal pure returns (uint256)
  {
    return (amount * percent) / 100_00;
  }

  function _normalize (uint256 amount, uint256 decimal) internal pure returns (uint256)
  {
    return (amount * 1e18) / (10 ** decimal);
  }

  function _denormalize (uint256 amount, uint256 decimal) internal pure returns (uint256)
  {
    return (amount * (10 ** decimal)) / 1e18;
  }


  function _isFiatcoin (address token) internal view
  {
    require(_fiatcoins.contains(token), "WUSD: !fiatcoin");
  }


  function _snap (uint256 wrapping) internal
  {
    Snapshot memory snap = _snapshot;


    if ((snap.cumulative - snap.last) >= _EPOCH)
    {
      _snapshot.epoch = snap.epoch + 1;
      _snapshot.last = snap.cumulative;
    }

    if (wrapping >= _MIN_GLOVABLE || _epoch[msg.sender] > 0)
    {
      _epoch[msg.sender] = _snapshot.epoch;
    }


    _snapshot.cumulative = snap.cumulative + uint112(wrapping);
  }

  function _englove (uint256 wrapping) internal
  {
    uint256 gloves = IGlove(_GLOVE).balanceOf(msg.sender);


    if (wrapping >= _MIN_GLOVABLE && gloves < _MAX_GLOVE)
    {
      IGlove(_GLOVE).mintCreditless(msg.sender, Math.min(_MAX_GLOVE - gloves, wrapping > 1_000e18 ? ((_MAX_GLOVE * wrapping) / _EPOCH) : ((_MID_GLOVE * wrapping) / 1_000e18)));
    }
  }

  function _mint (address account, uint256 amount) internal
  {
    require(account != address(0), "WUSD: mint to 0 addr");


    _totalSupply += amount;


    unchecked
    {
      _balance[account] += amount;
    }


    emit Transfer(address(0), account, amount);
  }

  function _parse (uint256 amount, uint256 decimal) internal pure returns (uint256, uint256)
  {
    return (Math.max(10 ** decimal, _percent(amount, 1_00)), _normalize(amount, decimal));
  }

  function wrap (address fiatcoin, uint256 amount, address referrer) external nonReentrant
  {
    _isFiatcoin(fiatcoin);
    require(amount > 0, "WUSD: wrap(0)");


    (uint256 fee, uint256 wrapping) = _parse(amount, _decimal[fiatcoin]);


    _snap(wrapping);
    _mint(msg.sender, wrapping);

    _englove(wrapping);
    IERC20(fiatcoin).safeTransferFrom(msg.sender, address(this), amount + fee);


    if (fiatcoin != _USDT && fiatcoin != _USDC)
    {
      _ROUTER.exactInputSingle(ISwapRouter.ExactInputSingleParams
      ({
        tokenIn: fiatcoin,
        tokenOut: _USDC,
        fee: fiatcoin != 0x0000000000085d4780B73119b644AE5ecd22b376 ? _ROUTE : 100,
        recipient: _REGISTRY.collector(),
        deadline: block.timestamp,
        amountIn: fee,
        amountOutMinimum: _percent(_denormalize(_normalize(fee, _decimal[fiatcoin]), 6), 95_00),
        sqrtPriceLimitX96: 0
      }));
    }
    else
    {
      IERC20(fiatcoin).safeTransfer(_REGISTRY.collector(), fee);
    }


    if (referrer != address(0))
    {
      IFrontender(_REGISTRY.frontender()).refer(msg.sender, wrapping, referrer);
    }


    emit Wrap(msg.sender, fiatcoin, amount, referrer);
  }


  function _burn (address account, uint256 amount) internal
  {
    uint256 balance = _balance[account];

    require(balance >= amount, "WUSD: burn > balance");


    unchecked
    {
      _balance[account] = balance - amount;
      _totalSupply -= amount;
    }


    emit Transfer(account, address(0), amount);
  }

  function _deglove (uint256 amount, uint256 balance) internal
  {
    uint256 creditless = IGlove(_GLOVE).creditlessOf(msg.sender);

    uint256 credits = _percent(creditless, Math.min((amount * 100_00) / balance, (_snapshot.epoch - _epoch[msg.sender]) * 100));


    if (_epoch[msg.sender] > 0)
    {
      if (amount == balance)
      {
        _epoch[msg.sender] = 0;

        IGlove(_GLOVE).burn(msg.sender, creditless - credits);
      }
      else
      {
        _epoch[msg.sender] = _snapshot.epoch;
      }


      IGlove(_GLOVE).creditize(msg.sender, credits);
    }
  }

  function unwrap (address fiatcoin, uint256 amount) external nonReentrant
  {
    _isFiatcoin(fiatcoin);


    uint256 balance = _balance[msg.sender];
    uint256 unwrapping = _denormalize(amount, _decimal[fiatcoin]);

    require(amount > 0, "WUSD: unwrap(0)");
    require((IERC20(fiatcoin).balanceOf(address(this)) - (10 ** _decimal[fiatcoin])) >= unwrapping, "WUSD: !enough fiatcoin");


    _burn(msg.sender, amount);
    _deglove(amount, balance);
    IERC20(fiatcoin).safeTransfer(msg.sender, unwrapping);


    emit Unwrap(msg.sender, fiatcoin, amount);
  }
}