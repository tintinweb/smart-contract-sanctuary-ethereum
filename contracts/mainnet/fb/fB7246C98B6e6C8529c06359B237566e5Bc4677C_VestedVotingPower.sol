// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ISt1inch {
    function expBase() external view returns (uint256);
    function origin() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IStepVesting {
    function receiver() external view returns (address);
    function claim() external;
    function started() external view returns (uint256);
    function cliffDuration() external view returns (uint256);
    function cliffAmount() external view returns (uint256);
    function stepDuration() external view returns (uint256);
    function stepAmount() external view returns (uint256);
    function numOfSteps() external view returns (uint256);
    function claimed() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;


interface IVestedToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function owner() external view returns (address);
    function transferOwnership(address newOwner) external;
    function registerVestings(address[] calldata vestings) external;
    function deregisterVestings(address[] calldata vestings) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/IStepVesting.sol";
import "./interfaces/ISt1inch.sol";
import "./interfaces/IVestedToken.sol";
import "./VotingPowerCalculator.sol";

contract VestedVotingPower is Ownable, VotingPowerCalculator {
    using EnumerableSet for EnumerableSet.AddressSet;

    IVestedToken public immutable vestedToken;
    mapping (address => EnumerableSet.AddressSet) private _vestingsByReceiver;

    uint256 private constant _VOTING_POWER_DIVIDER = 20;

    constructor(IVestedToken _vestedToken, ISt1inch st1inch) VotingPowerCalculator(st1inch.expBase(), st1inch.origin()) {
        vestedToken = _vestedToken;
    }

    function vestedTokenTransferOwnership(address newOwner) external onlyOwner {
        vestedToken.transferOwnership(newOwner);
    }

    function vestingsByReceiver(address receiver) external view returns (address[] memory) {
        return _vestingsByReceiver[receiver].values();
    }

    function votingPowerOf(address account) external view returns (uint256 votingPower) {
        EnumerableSet.AddressSet storage vestings = _vestingsByReceiver[account];
        uint256 len = vestings.length();
        unchecked {
            for (uint256 i = 0; i < len; i++) {
                IStepVesting vesting = IStepVesting(vestings.at(i));
                uint256 started = vesting.started();
                uint256 cliffDuration = vesting.cliffDuration();
                uint256 stepDuration = vesting.stepDuration();
                uint256 cliffAmount = vesting.cliffAmount();
                uint256 numOfSteps = vesting.numOfSteps();
                uint256 stepAmount = vesting.stepAmount();
                uint256 claimed = vesting.claimed();
                if (claimed < cliffAmount) {
                    votingPower += Math.min(cliffAmount, _votingPowerAt(_balanceAt(cliffAmount / _VOTING_POWER_DIVIDER, started + cliffDuration), block.timestamp));
                }
                for (uint256 j = 0; j < numOfSteps; j++) {
                    if (claimed < cliffAmount + stepAmount * (j + 1)) {
                        votingPower += Math.min(stepAmount, _votingPowerAt(_balanceAt(stepAmount / _VOTING_POWER_DIVIDER, started + cliffDuration + stepDuration * (j + 1)), block.timestamp));
                    }
                }
            }
        }
        return votingPower;
    }

    function registerVestings(address[] calldata vestings) external onlyOwner {
        if (vestedToken.owner() == address(this)) {
            vestedToken.registerVestings(vestings);
        }
        uint256 len = vestings.length;
        unchecked {
            for (uint256 i = 0; i < len; i++) {
                address vesting = vestings[i];
                address receiver = IStepVesting(vesting).receiver();
                require(_vestingsByReceiver[receiver].add(vesting), "Vesting is already registered");
            }
        }
    }

    function deregisterVestings(address[] calldata vestings) external onlyOwner {
        if (vestedToken.owner() == address(this)) {
            vestedToken.deregisterVestings(vestings);
        }
        uint256 len = vestings.length;
        unchecked {
            for (uint256 i = 0; i < len; i++) {
                address vesting = vestings[i];
                address receiver = IStepVesting(vesting).receiver();
                EnumerableSet.AddressSet storage receiverVestings = _vestingsByReceiver[receiver];
                require(receiverVestings.remove(vesting), "Vesting is not registered");
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

contract VotingPowerCalculator {
    error OriginInTheFuture();

    uint256 private constant _ONE_E18 = 1e18;

    uint256 public immutable origin;
    uint256 public immutable expBase;

    uint256 private immutable _expTable0;
    uint256 private immutable _expTable1;
    uint256 private immutable _expTable2;
    uint256 private immutable _expTable3;
    uint256 private immutable _expTable4;
    uint256 private immutable _expTable5;
    uint256 private immutable _expTable6;
    uint256 private immutable _expTable7;
    uint256 private immutable _expTable8;
    uint256 private immutable _expTable9;
    uint256 private immutable _expTable10;
    uint256 private immutable _expTable11;
    uint256 private immutable _expTable12;
    uint256 private immutable _expTable13;
    uint256 private immutable _expTable14;
    uint256 private immutable _expTable15;
    uint256 private immutable _expTable16;
    uint256 private immutable _expTable17;
    uint256 private immutable _expTable18;
    uint256 private immutable _expTable19;
    uint256 private immutable _expTable20;
    uint256 private immutable _expTable21;
    uint256 private immutable _expTable22;
    uint256 private immutable _expTable23;
    uint256 private immutable _expTable24;
    uint256 private immutable _expTable25;
    uint256 private immutable _expTable26;
    uint256 private immutable _expTable27;
    uint256 private immutable _expTable28;
    uint256 private immutable _expTable29;

    constructor(uint256 expBase_, uint256 origin_) {
        if (origin_ > block.timestamp) revert OriginInTheFuture();

        origin = origin_;
        expBase = expBase_;
        _expTable0 = expBase_;
        _expTable1 = (_expTable0 * _expTable0) / _ONE_E18;
        _expTable2 = (_expTable1 * _expTable1) / _ONE_E18;
        _expTable3 = (_expTable2 * _expTable2) / _ONE_E18;
        _expTable4 = (_expTable3 * _expTable3) / _ONE_E18;
        _expTable5 = (_expTable4 * _expTable4) / _ONE_E18;
        _expTable6 = (_expTable5 * _expTable5) / _ONE_E18;
        _expTable7 = (_expTable6 * _expTable6) / _ONE_E18;
        _expTable8 = (_expTable7 * _expTable7) / _ONE_E18;
        _expTable9 = (_expTable8 * _expTable8) / _ONE_E18;
        _expTable10 = (_expTable9 * _expTable9) / _ONE_E18;
        _expTable11 = (_expTable10 * _expTable10) / _ONE_E18;
        _expTable12 = (_expTable11 * _expTable11) / _ONE_E18;
        _expTable13 = (_expTable12 * _expTable12) / _ONE_E18;
        _expTable14 = (_expTable13 * _expTable13) / _ONE_E18;
        _expTable15 = (_expTable14 * _expTable14) / _ONE_E18;
        _expTable16 = (_expTable15 * _expTable15) / _ONE_E18;
        _expTable17 = (_expTable16 * _expTable16) / _ONE_E18;
        _expTable18 = (_expTable17 * _expTable17) / _ONE_E18;
        _expTable19 = (_expTable18 * _expTable18) / _ONE_E18;
        _expTable20 = (_expTable19 * _expTable19) / _ONE_E18;
        _expTable21 = (_expTable20 * _expTable20) / _ONE_E18;
        _expTable22 = (_expTable21 * _expTable21) / _ONE_E18;
        _expTable23 = (_expTable22 * _expTable22) / _ONE_E18;
        _expTable24 = (_expTable23 * _expTable23) / _ONE_E18;
        _expTable25 = (_expTable24 * _expTable24) / _ONE_E18;
        _expTable26 = (_expTable25 * _expTable25) / _ONE_E18;
        _expTable27 = (_expTable26 * _expTable26) / _ONE_E18;
        _expTable28 = (_expTable27 * _expTable27) / _ONE_E18;
        _expTable29 = (_expTable28 * _expTable28) / _ONE_E18;
    }

    function _votingPowerAt(uint256 balance, uint256 timestamp) internal view returns (uint256 votingPower) {
        timestamp = timestamp < origin ? origin : timestamp;  // logic in timestamps before origin is undefined
        unchecked {
            uint256 t = timestamp - origin;
            votingPower = balance;
            if (t & 0x01 != 0) {
                votingPower = (votingPower * _expTable0) / _ONE_E18;
            }
            if (t & 0x02 != 0) {
                votingPower = (votingPower * _expTable1) / _ONE_E18;
            }
            if (t & 0x04 != 0) {
                votingPower = (votingPower * _expTable2) / _ONE_E18;
            }
            if (t & 0x08 != 0) {
                votingPower = (votingPower * _expTable3) / _ONE_E18;
            }
            if (t & 0x10 != 0) {
                votingPower = (votingPower * _expTable4) / _ONE_E18;
            }
            if (t & 0x20 != 0) {
                votingPower = (votingPower * _expTable5) / _ONE_E18;
            }
            if (t & 0x40 != 0) {
                votingPower = (votingPower * _expTable6) / _ONE_E18;
            }
            if (t & 0x80 != 0) {
                votingPower = (votingPower * _expTable7) / _ONE_E18;
            }
            if (t & 0x100 != 0) {
                votingPower = (votingPower * _expTable8) / _ONE_E18;
            }
            if (t & 0x200 != 0) {
                votingPower = (votingPower * _expTable9) / _ONE_E18;
            }
            if (t & 0x400 != 0) {
                votingPower = (votingPower * _expTable10) / _ONE_E18;
            }
            if (t & 0x800 != 0) {
                votingPower = (votingPower * _expTable11) / _ONE_E18;
            }
            if (t & 0x1000 != 0) {
                votingPower = (votingPower * _expTable12) / _ONE_E18;
            }
            if (t & 0x2000 != 0) {
                votingPower = (votingPower * _expTable13) / _ONE_E18;
            }
            if (t & 0x4000 != 0) {
                votingPower = (votingPower * _expTable14) / _ONE_E18;
            }
            if (t & 0x8000 != 0) {
                votingPower = (votingPower * _expTable15) / _ONE_E18;
            }
            if (t & 0x10000 != 0) {
                votingPower = (votingPower * _expTable16) / _ONE_E18;
            }
            if (t & 0x20000 != 0) {
                votingPower = (votingPower * _expTable17) / _ONE_E18;
            }
            if (t & 0x40000 != 0) {
                votingPower = (votingPower * _expTable18) / _ONE_E18;
            }
            if (t & 0x80000 != 0) {
                votingPower = (votingPower * _expTable19) / _ONE_E18;
            }
            if (t & 0x100000 != 0) {
                votingPower = (votingPower * _expTable20) / _ONE_E18;
            }
            if (t & 0x200000 != 0) {
                votingPower = (votingPower * _expTable21) / _ONE_E18;
            }
            if (t & 0x400000 != 0) {
                votingPower = (votingPower * _expTable22) / _ONE_E18;
            }
            if (t & 0x800000 != 0) {
                votingPower = (votingPower * _expTable23) / _ONE_E18;
            }
            if (t & 0x1000000 != 0) {
                votingPower = (votingPower * _expTable24) / _ONE_E18;
            }
            if (t & 0x2000000 != 0) {
                votingPower = (votingPower * _expTable25) / _ONE_E18;
            }
            if (t & 0x4000000 != 0) {
                votingPower = (votingPower * _expTable26) / _ONE_E18;
            }
            if (t & 0x8000000 != 0) {
                votingPower = (votingPower * _expTable27) / _ONE_E18;
            }
            if (t & 0x10000000 != 0) {
                votingPower = (votingPower * _expTable28) / _ONE_E18;
            }
            if (t & 0x20000000 != 0) {
                votingPower = (votingPower * _expTable29) / _ONE_E18;
            }
        }
        return votingPower;
    }

    function _balanceAt(uint256 votingPower, uint256 timestamp) internal view returns (uint256 balance) {
        timestamp = timestamp < origin ? origin : timestamp;  // logic in timestamps before origin is undefined
        unchecked {
            uint256 t = timestamp - origin;
            balance = votingPower;
            if (t & 0x01 != 0) {
                balance = (balance * _ONE_E18) / _expTable0;
            }
            if (t & 0x02 != 0) {
                balance = (balance * _ONE_E18) / _expTable1;
            }
            if (t & 0x04 != 0) {
                balance = (balance * _ONE_E18) / _expTable2;
            }
            if (t & 0x08 != 0) {
                balance = (balance * _ONE_E18) / _expTable3;
            }
            if (t & 0x10 != 0) {
                balance = (balance * _ONE_E18) / _expTable4;
            }
            if (t & 0x20 != 0) {
                balance = (balance * _ONE_E18) / _expTable5;
            }
            if (t & 0x40 != 0) {
                balance = (balance * _ONE_E18) / _expTable6;
            }
            if (t & 0x80 != 0) {
                balance = (balance * _ONE_E18) / _expTable7;
            }
            if (t & 0x100 != 0) {
                balance = (balance * _ONE_E18) / _expTable8;
            }
            if (t & 0x200 != 0) {
                balance = (balance * _ONE_E18) / _expTable9;
            }
            if (t & 0x400 != 0) {
                balance = (balance * _ONE_E18) / _expTable10;
            }
            if (t & 0x800 != 0) {
                balance = (balance * _ONE_E18) / _expTable11;
            }
            if (t & 0x1000 != 0) {
                balance = (balance * _ONE_E18) / _expTable12;
            }
            if (t & 0x2000 != 0) {
                balance = (balance * _ONE_E18) / _expTable13;
            }
            if (t & 0x4000 != 0) {
                balance = (balance * _ONE_E18) / _expTable14;
            }
            if (t & 0x8000 != 0) {
                balance = (balance * _ONE_E18) / _expTable15;
            }
            if (t & 0x10000 != 0) {
                balance = (balance * _ONE_E18) / _expTable16;
            }
            if (t & 0x20000 != 0) {
                balance = (balance * _ONE_E18) / _expTable17;
            }
            if (t & 0x40000 != 0) {
                balance = (balance * _ONE_E18) / _expTable18;
            }
            if (t & 0x80000 != 0) {
                balance = (balance * _ONE_E18) / _expTable19;
            }
            if (t & 0x100000 != 0) {
                balance = (balance * _ONE_E18) / _expTable20;
            }
            if (t & 0x200000 != 0) {
                balance = (balance * _ONE_E18) / _expTable21;
            }
            if (t & 0x400000 != 0) {
                balance = (balance * _ONE_E18) / _expTable22;
            }
            if (t & 0x800000 != 0) {
                balance = (balance * _ONE_E18) / _expTable23;
            }
            if (t & 0x1000000 != 0) {
                balance = (balance * _ONE_E18) / _expTable24;
            }
            if (t & 0x2000000 != 0) {
                balance = (balance * _ONE_E18) / _expTable25;
            }
            if (t & 0x4000000 != 0) {
                balance = (balance * _ONE_E18) / _expTable26;
            }
            if (t & 0x8000000 != 0) {
                balance = (balance * _ONE_E18) / _expTable27;
            }
            if (t & 0x10000000 != 0) {
                balance = (balance * _ONE_E18) / _expTable28;
            }
            if (t & 0x20000000 != 0) {
                balance = (balance * _ONE_E18) / _expTable29;
            }
        }
        return balance;
    }
}