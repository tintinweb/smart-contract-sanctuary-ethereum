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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Signed 18 decimal fixed point (wad) arithmetic library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SignedWadMath.sol)
/// @author Modified from Remco Bloemen (https://xn--2-umb.com/22/exp-ln/index.html)

/// @dev Will not revert on overflow, only use where overflow is not possible.
function toWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18.
        r := mul(x, 1000000000000000000)
    }
}

/// @dev Takes an integer amount of seconds and converts it to a wad amount of days.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative second amounts, it assumes x is positive.
function toDaysWadUnsafe(uint256 x) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and then divide it by 86400.
        r := div(mul(x, 1000000000000000000), 86400)
    }
}

/// @dev Takes a wad amount of days and converts it to an integer amount of seconds.
/// @dev Will not revert on overflow, only use where overflow is not possible.
/// @dev Not meant for negative day amounts, it assumes x is positive.
function fromDaysWadUnsafe(int256 x) pure returns (uint256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 86400 and then divide it by 1e18.
        r := div(mul(x, 86400), 1000000000000000000)
    }
}

/// @dev Will not revert on overflow, only use where overflow is not possible.
function unsafeWadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by y and divide by 1e18.
        r := sdiv(mul(x, y), 1000000000000000000)
    }
}

/// @dev Will return 0 instead of reverting if y is zero and will
/// not revert on overflow, only use where overflow is not possible.
function unsafeWadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Multiply x by 1e18 and divide it by y.
        r := sdiv(mul(x, 1000000000000000000), y)
    }
}

function wadMul(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * y in r for now.
        r := mul(x, y)

        // Equivalent to require(x == 0 || (x * y) / x == y)
        if iszero(or(iszero(x), eq(sdiv(r, x), y))) {
            revert(0, 0)
        }

        // Scale the result down by 1e18.
        r := sdiv(r, 1000000000000000000)
    }
}

function wadDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Store x * 1e18 in r for now.
        r := mul(x, 1000000000000000000)

        // Equivalent to require(y != 0 && ((x * 1e18) / 1e18 == x))
        if iszero(and(iszero(iszero(y)), eq(sdiv(r, 1000000000000000000), x))) {
            revert(0, 0)
        }

        // Divide r by y.
        r := sdiv(r, y)
    }
}

/// @dev Will not work with negative bases, only use when x is positive.
function wadPow(int256 x, int256 y) pure returns (int256) {
    // Equivalent to x to the power of y because x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)
    return wadExp((wadLn(x) * y) / 1e18); // Using ln(x) means x must be greater than 0.
}

function wadExp(int256 x) pure returns (int256 r) {
    unchecked {
        // When the result is < 0.5 we return zero. This happens when
        // x <= floor(log(0.5e18) * 1e18) ~ -42e18
        if (x <= -42139678854452767551) return 0;

        // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
        // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
        if (x >= 135305999368893231589) revert("EXP_OVERFLOW");

        // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
        // for more intermediate precision and a binary basis. This base conversion
        // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
        x = (x << 78) / 5**18;

        // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
        // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
        // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
        int256 k = ((x << 96) / 54916777467707473351141471128 + 2**95) >> 96;
        x = x - k * 54916777467707473351141471128;

        // k is in the range [-61, 195].

        // Evaluate using a (6, 7)-term rational approximation.
        // p is made monic, we'll multiply by a scale factor later.
        int256 y = x + 1346386616545796478920950773328;
        y = ((y * x) >> 96) + 57155421227552351082224309758442;
        int256 p = y + x - 94201549194550492254356042504812;
        p = ((p * y) >> 96) + 28719021644029726153956944680412240;
        p = p * x + (4385272521454847904659076985693276 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        int256 q = x - 2855989394907223263936484059900;
        q = ((q * x) >> 96) + 50020603652535783019961831881945;
        q = ((q * x) >> 96) - 533845033583426703283633433725380;
        q = ((q * x) >> 96) + 3604857256930695427073651918091429;
        q = ((q * x) >> 96) - 14423608567350463180887372962807573;
        q = ((q * x) >> 96) + 26449188498355588339934803723976023;

        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial won't have zeros in the domain as all its roots are complex.
            // No scaling is necessary because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r should be in the range (0.09, 0.25) * 2**96.

        // We now need to multiply r by:
        // * the scale factor s = ~6.031367120.
        // * the 2**k factor from the range reduction.
        // * the 1e18 / 2**96 factor for base conversion.
        // We do this all at once, with an intermediate result in 2**213
        // basis, so the final right shift is always by a positive amount.
        r = int256((uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k));
    }
}

function wadLn(int256 x) pure returns (int256 r) {
    unchecked {
        require(x > 0, "UNDEFINED");

        // We want to convert x from 10**18 fixed point to 2**96 fixed point.
        // We do this by multiplying by 2**96 / 10**18. But since
        // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
        // and add ln(2**96 / 10**18) at the end.

        /// @solidity memory-safe-assembly
        assembly {
            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffff, shr(r, x))))
            r := or(r, shl(3, lt(0xff, shr(r, x))))
            r := or(r, shl(2, lt(0xf, shr(r, x))))
            r := or(r, shl(1, lt(0x3, shr(r, x))))
            r := or(r, lt(0x1, shr(r, x)))
        }

        // Reduce range of x to (1, 2) * 2**96
        // ln(2^k * x) = k * ln(2) + ln(x)
        int256 k = r - 96;
        x <<= uint256(159 - k);
        x = int256(uint256(x) >> 159);

        // Evaluate using a (8, 8)-term rational approximation.
        // p is made monic, we will multiply by a scale factor later.
        int256 p = x + 3273285459638523848632254066296;
        p = ((p * x) >> 96) + 24828157081833163892658089445524;
        p = ((p * x) >> 96) + 43456485725739037958740375743393;
        p = ((p * x) >> 96) - 11111509109440967052023855526967;
        p = ((p * x) >> 96) - 45023709667254063763336534515857;
        p = ((p * x) >> 96) - 14706773417378608786704636184526;
        p = p * x - (795164235651350426258249787498 << 96);

        // We leave p in 2**192 basis so we don't need to scale it back up for the division.
        // q is monic by convention.
        int256 q = x + 5573035233440673466300451813936;
        q = ((q * x) >> 96) + 71694874799317883764090561454958;
        q = ((q * x) >> 96) + 283447036172924575727196451306956;
        q = ((q * x) >> 96) + 401686690394027663651624208769553;
        q = ((q * x) >> 96) + 204048457590392012362485061816622;
        q = ((q * x) >> 96) + 31853899698501571402653359427138;
        q = ((q * x) >> 96) + 909429971244387300277376558375;
        /// @solidity memory-safe-assembly
        assembly {
            // Div in assembly because solidity adds a zero check despite the unchecked.
            // The q polynomial is known not to have zeros in the domain.
            // No scaling required because p is already 2**96 too large.
            r := sdiv(p, q)
        }

        // r is in the range (0, 0.125) * 2**96

        // Finalization, we need to:
        // * multiply by the scale factor s = 5.549…
        // * add ln(2**96 / 10**18)
        // * add k * ln(2)
        // * multiply by 10**18 / 2**96 = 5**18 >> 78

        // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
        r *= 1677202110996718588342820967067443963516166;
        // add ln(2) * k * 5e18 * 2**192
        r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
        // add ln(2**96 / 10**18) * 5e18 * 2**192
        r += 600920179829731861736702779321621459595472258049074101567377883020018308;
        // base conversion: mul 2**18 / 2**192
        r >>= 174;
    }
}

/// @dev Will return 0 instead of reverting if y is zero.
function unsafeDiv(int256 x, int256 y) pure returns (int256 r) {
    /// @solidity memory-safe-assembly
    assembly {
        // Divide x by y.
        r := sdiv(x, y)
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./utils/FormatMetadata.sol";
import "./utils/StringList.sol";
import "./utils/GenerateShip.sol";

contract MiaocraftRenderer is Ownable {
    using Base64 for bytes;
    using Strings for uint256;
    using StringList for string[];

    uint256 constant FONT_SIZE = 14;
    uint256 constant LINE_HEIGHT = 16;
    uint256 constant FONT_WIDTH = 10;
    string constant description = "Miaocraft";

    function getStr(
        uint256 size,
        uint256 maxWidth,
        uint256 maxHeight,
        uint256 seed
    ) public pure returns (string[] memory str) {
        return GenerateShip.generateShip(size, maxWidth, maxHeight, seed);
    }

    function getHtml(
        uint256 size,
        uint256 maxWidth,
        uint256 maxHeight,
        uint256 seed
    ) public pure returns (string memory html) {
        string[] memory str = GenerateShip.generateShip(
            size,
            maxWidth,
            maxHeight,
            seed
        );

        for (uint256 i = 0; i < str.length; i++) {
            str[i] = _getText(str[i], i, maxWidth);
        }
        return str.join("", true);
    }

    function getSvg(
        uint256 size,
        uint256 maxWidth,
        uint256 maxHeight,
        uint256 seed
    ) public pure returns (string memory svg) {
        return
            string(
                abi.encodePacked(
                    header(maxWidth, maxHeight),
                    getHtml(size, maxWidth, maxHeight, seed),
                    footer()
                )
            );
    }

    function _getText(
        string memory str,
        uint256 row,
        uint256 maxWidth
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(_getTextOpenTag(row, maxWidth), str, "</text>")
            );
    }

    function _getTextOpenTag(uint256 row, uint256 maxWidth)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<text id='",
                    row.toString(),
                    "' x='",
                    ((maxWidth * FONT_WIDTH) / 2).toString(),
                    "' y='",
                    ((row + 1) * LINE_HEIGHT).toString(),
                    "'>"
                )
            );
    }

    function header(uint256 width, uint256 height)
        public
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    '<svg id="Miaocraft" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 ',
                    (width * FONT_WIDTH).toString(),
                    " ",
                    ((height) * LINE_HEIGHT).toString(),
                    '"><rect width="100%" height="100%" fill="black" />'
                )
            );
    }

    function footer() public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<style>#Miaocraft { fill: white; font-family: Menlo, Monaco; font-size: ",
                    (FONT_SIZE).toString(),
                    "px; white-space: pre; font-weight:bolder; dominant-baseline:central; text-anchor:middle}</style></svg>"
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library BitsToAscii {
    bytes constant ascii = ".*/-M\\m|'][";
    bytes constant asciiMirror = ".*\\-M/m|'[]";

    function toAscii(uint256 bitstring) internal pure returns (bytes1) {
        return mapKeyToAscii(toKey(bitstring));
    }

    function toAsciiMirror(uint256 bitstring) internal pure returns (bytes1) {
        return mapKeyToAsciiMirror(toKey(bitstring));
    }

    function mapKeyToAscii(uint256 label) internal pure returns (bytes1) {
        return ascii[label];
    }

    function mapKeyToAsciiMirror(uint256 label) internal pure returns (bytes1) {
        return asciiMirror[label];
    }

    function toKey(uint256 bitstring) internal pure returns (uint256) {
        uint256 invBitstring = ~bitstring;
        if (bitMatch(bitstring, 0x012) && bitMatch(invBitstring, 0x1ed)) {
            return 0;
        }
        if (bitMatch(bitstring, 0x090) && bitMatch(invBitstring, 0x16f)) {
            return 1;
        }
        if (bitMatch(bitstring, 0x014) && bitMatch(invBitstring, 0x1eb)) {
            return 2;
        }
        if (bitMatch(bitstring, 0x011) && bitMatch(invBitstring, 0x1ee)) {
            return 0;
        }
        if (bitMatch(bitstring, 0x018) && bitMatch(invBitstring, 0x1e7)) {
            return 3;
        }
        if (bitMatch(bitstring, 0x030) && bitMatch(invBitstring, 0x1cf)) {
            return 4;
        }
        if (bitMatch(bitstring, 0x110) && bitMatch(invBitstring, 0x0ef)) {
            return 5;
        }
        if (bitMatch(bitstring, 0x050) && bitMatch(invBitstring, 0x1af)) {
            return 2;
        }
        if (bitMatch(bitstring, 0x038) && bitMatch(invBitstring, 0x1c0)) {
            return 6;
        }
        if (bitMatch(bitstring, 0x038) && bitMatch(invBitstring, 0x007)) {
            return 6;
        }
        if (bitMatch(bitstring, 0x111) && bitMatch(invBitstring, 0x0c8)) {
            return 5;
        }
        if (bitMatch(bitstring, 0x111) && bitMatch(invBitstring, 0x026)) {
            return 5;
        }
        if (bitMatch(bitstring, 0x092) && bitMatch(invBitstring, 0x049)) {
            return 7;
        }
        if (bitMatch(bitstring, 0x092) && bitMatch(invBitstring, 0x124)) {
            return 7;
        }
        if (bitMatch(bitstring, 0x054) && bitMatch(invBitstring, 0x00b)) {
            return 2;
        }
        if (bitMatch(bitstring, 0x054) && bitMatch(invBitstring, 0x1a0)) {
            return 2;
        }
        if (bitMatch(bitstring, 0x031) && bitMatch(invBitstring, 0x1c8)) {
            return 3;
        }
        if (bitMatch(bitstring, 0x031) && bitMatch(invBitstring, 0x006)) {
            return 3;
        }
        if (bitMatch(bitstring, 0x01c) && bitMatch(invBitstring, 0x1e0)) {
            return 2;
        }
        if (bitMatch(bitstring, 0x01c) && bitMatch(invBitstring, 0x003)) {
            return 2;
        }
        if (bitMatch(bitstring, 0x070) && bitMatch(invBitstring, 0x180)) {
            return 3;
        }
        if (bitMatch(bitstring, 0x070) && bitMatch(invBitstring, 0x00f)) {
            return 3;
        }
        if (bitMatch(bitstring, 0x118) && bitMatch(invBitstring, 0x027)) {
            return 3;
        }
        if (bitMatch(bitstring, 0x118) && bitMatch(invBitstring, 0x0c0)) {
            return 3;
        }
        if (bitMatch(bitstring, 0x091) && bitMatch(invBitstring, 0x048)) {
            return 8;
        }
        if (bitMatch(bitstring, 0x091) && bitMatch(invBitstring, 0x126)) {
            return 8;
        }
        if (bitMatch(bitstring, 0x094) && bitMatch(invBitstring, 0x120)) {
            return 8;
        }
        if (bitMatch(bitstring, 0x094) && bitMatch(invBitstring, 0x04b)) {
            return 8;
        }
        if (bitMatch(bitstring, 0x052) && bitMatch(invBitstring, 0x1a4)) {
            return 0;
        }
        if (bitMatch(bitstring, 0x052) && bitMatch(invBitstring, 0x009)) {
            return 0;
        }
        if (bitMatch(bitstring, 0x112) && bitMatch(invBitstring, 0x024)) {
            return 0;
        }
        if (bitMatch(bitstring, 0x112) && bitMatch(invBitstring, 0x0c9)) {
            return 0;
        }
        if (bitMatch(bitstring, 0x015) && bitMatch(invBitstring, 0x1e8)) {
            return 0;
        }
        if (bitMatch(bitstring, 0x114) && bitMatch(invBitstring, 0x0cb)) {
            return 9;
        }
        if (bitMatch(bitstring, 0x150) && bitMatch(invBitstring, 0x02f)) {
            return 8;
        }
        if (bitMatch(bitstring, 0x051) && bitMatch(invBitstring, 0x1a6)) {
            return 10;
        }
        if (bitMatch(bitstring, 0x098) && bitMatch(invBitstring, 0x127)) {
            return 5;
        }
        if (bitMatch(bitstring, 0x032) && bitMatch(invBitstring, 0x1c9)) {
            return 5;
        }
        if (bitMatch(bitstring, 0x01a) && bitMatch(invBitstring, 0x1e4)) {
            return 2;
        }
        if (bitMatch(bitstring, 0x0b0) && bitMatch(invBitstring, 0x04f)) {
            return 0;
        }
        if (bitMatch(bitstring, 0x058) && bitMatch(invBitstring, 0x1a7)) {
            return 2;
        }
        if (bitMatch(bitstring, 0x0d0) && bitMatch(invBitstring, 0x12f)) {
            return 2;
        }
        if (bitMatch(bitstring, 0x190) && bitMatch(invBitstring, 0x06f)) {
            return 5;
        }
        if (bitMatch(bitstring, 0x130) && bitMatch(invBitstring, 0x0cf)) {
            return 5;
        }
        if (bitMatch(bitstring, 0x034) && bitMatch(invBitstring, 0x1cb)) {
            return 8;
        }
        if (bitMatch(bitstring, 0x016) && bitMatch(invBitstring, 0x1e9)) {
            return 2;
        }
        if (bitMatch(bitstring, 0x013) && bitMatch(invBitstring, 0x1ec)) {
            return 7;
        }
        if (bitMatch(bitstring, 0x019) && bitMatch(invBitstring, 0x1e6)) {
            return 3;
        }
        return 0;
    }

    function bitMatch(uint256 bitstring, uint256 pattern)
        internal
        pure
        returns (bool)
    {
        return bitstring & pattern == pattern;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./Base64.sol";
import "./StringList.sol";

library FormatMetadata {
    using Base64 for bytes;
    using StringList for string[];
    using Strings for uint256;

    function formatTraitString(string memory traitType, string memory value)
        internal
        pure
        returns (string memory)
    {
        if (bytes(value).length == 0) {
            return "";
        }
        return
            string.concat(
                '{"trait_type":"',
                traitType,
                '","value":"',
                value,
                '"}'
            );
    }

    function formatTraitNumber(
        string memory traitType,
        string memory value,
        string memory displayType
    ) internal pure returns (string memory) {
        return
            string.concat(
                '{"trait_type":"',
                traitType,
                '","value":',
                value,
                ',"display_type":"',
                displayType,
                '"}'
            );
    }

    function formatTraitNumber(
        string memory traitType,
        uint256 value,
        string memory displayType
    ) internal pure returns (string memory) {
        return formatTraitNumber(traitType, value.toString(), displayType);
    }

    function formatTraitNumber(
        string memory traitType,
        int256 value,
        string memory displayType
    ) internal pure returns (string memory) {
        return formatTraitNumber(traitType, intToString(value), displayType);
    }

    function formatMetadata(
        string memory name,
        string memory description,
        string memory image,
        string[] memory attributes,
        string memory additionalMetadata
    ) internal pure returns (string memory) {
        return
            string.concat(
                "data:application/json;base64,",
                bytes(
                    abi.encodePacked(
                        '{"name": "',
                        name,
                        '", "description": "',
                        description,
                        '", "image": "',
                        image,
                        '", "attributes": [',
                        attributes.join(", ", true),
                        "]",
                        bytes(additionalMetadata).length > 0 ? "," : "",
                        additionalMetadata,
                        "}"
                    )
                ).encode()
            );
    }

    function formatAdditionalMetadata(string memory name, string memory value)
        internal
        pure
        returns (string memory)
    {
        if (bytes(value).length == 0) {
            return "";
        }

        return string.concat('"', name, '":"', value, '"');
    }

    function formatMetadataWithSVG(
        string memory name,
        string memory description,
        string memory svg,
        string[] memory attributes,
        string memory additionalMetadata
    ) internal pure returns (string memory) {
        return
            string.concat(
                "data:application/json;base64,",
                bytes(
                    abi.encodePacked(
                        '{"name": "',
                        name,
                        '", "description": "',
                        description,
                        '", "image_data": "',
                        svg,
                        '", "attributes": [',
                        attributes.join(", ", true),
                        "]",
                        bytes(additionalMetadata).length > 0 ? "," : "",
                        additionalMetadata,
                        "}"
                    )
                ).encode()
            );
    }

    function intToString(int256 n) internal pure returns (string memory) {
        uint256 nAbs = n < 0 ? uint256(-n) : uint256(n);
        bool nNeg = n < 0;
        return string.concat(nNeg ? "-" : "", nAbs.toString());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Layout.sol";
import "./BitsToAscii.sol";

bytes1 constant PAD_CHAR = " ";

library GenerateShip {
    using Layout for bool[][];
    using BitsToAscii for uint256;

    function generateShip(
        uint256 size,
        uint256 maxWidth,
        uint256 maxHeight,
        uint256 seed
    ) internal pure returns (string[] memory ship) {
        bool[][] memory layout = Layout.sample(size, maxWidth, maxHeight, seed);

        bytes[] memory asciis = pad(
            layoutToAscii(layout),
            (maxWidth - layout[0].length) / 2,
            (maxHeight - layout.length) / 2
        );
        ship = new string[](asciis.length);
        for (uint256 i = 0; i < asciis.length; i++) {
            ship[i] = string(asciis[i]);
        }
    }

    function layoutToAscii(bool[][] memory layout)
        internal
        pure
        returns (bytes[] memory asciis)
    {
        asciis = new bytes[](layout.length);
        uint256 width = layout[0].length;
        uint256 center = (width + 1) / 2 - 1;
        for (uint256 i = 0; i < layout.length; i++) {
            asciis[i] = new bytes(width);
            for (uint256 j = 0; j <= center; j++) {
                uint256 key = bitConvolution(layout, i, j).toKey();
                if (layout[i][j]) {
                    asciis[i][j] = key.mapKeyToAscii();
                    asciis[i][width - j - 1] = key.mapKeyToAsciiMirror();
                } else {
                    asciis[i][j] = PAD_CHAR;
                    asciis[i][width - j - 1] = PAD_CHAR;
                }
            }
        }

        uint256 tailIndex = layout[layout.length - 1][center]
            ? layout.length - 1
            : layout.length - 2;

        // replace tail
        asciis[tailIndex][center] = "*";

        // replace body
        for (uint256 i = 0; i < tailIndex; i++) {
            if (!layout[i][center]) {
                asciis[i][center] = "|";
            }
        }

        // replace tip
        if (asciis[0][center] == "m") {
            asciis[0][center] = "'";
        }

        // replace wings
        asciis = tuneWings(asciis);
    }

    function bitConvolution(
        bool[][] memory layout,
        uint256 row,
        uint256 col
    ) internal pure returns (uint256) {
        unchecked {
            return
                (layout.getValue(int256(row) - 1, int256(col) - 1) << 8) |
                (layout.getValue(int256(row) - 1, int256(col)) << 7) |
                (layout.getValue(int256(row) - 1, int256(col) + 1) << 6) |
                (layout.getValue(int256(row), int256(col) - 1) << 5) |
                (layout.getValue(int256(row), int256(col)) << 4) |
                (layout.getValue(int256(row), int256(col) + 1) << 3) |
                (layout.getValue(int256(row) + 1, int256(col) - 1) << 2) |
                (layout.getValue(int256(row) + 1, int256(col)) << 1) |
                layout.getValue(int256(row) + 1, int256(col) + 1);
        }
    }

    function tuneWings(bytes[] memory asciis)
        internal
        pure
        returns (bytes[] memory)
    {
        uint256 width = asciis[0].length;
        uint256 center = (width + 1) / 2 - 1;
        for (uint256 i = 0; i < asciis.length; i++) {
            for (uint256 j = 1; j <= center; j++) {
                if (asciis[i][j] == "-" && isSlashOrM(asciis[i][j - 1])) {
                    asciis[i][j] = "m";
                    asciis[i][width - j - 1] = "m";
                }
                if (
                    isM(asciis[i][j - 1]) &&
                    asciis[i][j] == "m" &&
                    (!isM(asciis[i][j + 1]) || j == center)
                ) {
                    asciis[i][j] = "M";
                    asciis[i][width - j - 1] = "M";
                }
            }
        }
        return asciis;
    }

    function isM(bytes1 ascii) internal pure returns (bool) {
        return ascii == "m" || ascii == "M";
    }

    function isSlashOrM(bytes1 ascii) internal pure returns (bool) {
        return ascii == "/" || isM(ascii);
    }

    function pad(bytes memory ascii, uint256 width)
        internal
        pure
        returns (bytes memory)
    {
        uint256 totalWidth = width * 2 + ascii.length;
        bytes memory padded = new bytes(totalWidth);
        for (uint256 i = 0; i < width; i++) {
            padded[i] = PAD_CHAR;
            padded[totalWidth - i - 1] = PAD_CHAR;
        }
        for (uint256 i = 0; i < ascii.length; i++) {
            padded[width + i] = ascii[i];
        }
        return padded;
    }

    function pad(
        bytes[] memory asciis,
        uint256 width,
        uint256 height
    ) internal pure returns (bytes[] memory padded) {
        uint256 totalHeight = height * 2 + asciis.length;
        uint256 totalWidth = width * 2 + asciis[0].length;
        bytes memory paddingRow = new bytes(totalWidth);
        for (uint256 i = 0; i < totalWidth; i++) {
            paddingRow[i] = PAD_CHAR;
        }

        padded = new bytes[](totalHeight);
        for (uint256 i = 0; i < height; i++) {
            padded[i] = paddingRow;
            padded[totalHeight - i - 1] = paddingRow;
        }
        for (uint256 i = 0; i < asciis.length; i++) {
            padded[height + i] = pad(asciis[i], width);
        }

        return padded;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Sample.sol";
import "./ShortestPath.sol";

library Layout {
    function sample(
        uint256 size,
        uint256 maxWidth,
        uint256 maxHeight,
        uint256 seed
    ) internal pure returns (bool[][] memory layout) {
        (
            bool[][] memory halfLayout,
            uint256 width,
            uint256 height
        ) = sampleHalf(size, maxWidth, maxHeight, seed);
        layout = mirrorHalfLayout(
            connectParts(crop(halfLayout, (width + 1) / 2, height)),
            width,
            height
        );
    }

    function sampleHalf(
        uint256 size,
        uint256 maxWidth,
        uint256 maxHeight,
        uint256 seed
    )
        internal
        pure
        returns (
            bool[][] memory halfLayout,
            uint256 width,
            uint256 height
        )
    {
        seed = uint256(keccak256(abi.encode(seed)));

        uint256 halfWidth = (maxWidth + 1) / 2;
        halfLayout = new bool[][](maxHeight);

        uint256 prevHalfWidth = 1;
        uint256 currCol = 0;
        uint256 currRow = 0;
        while (size > 1 && currRow < maxHeight) {
            if (halfLayout[currRow].length == 0) {
                halfLayout[currRow] = new bool[](halfWidth);
                height = currRow + 1;
            }

            size -= currCol == 0 ? 1 : 2;
            bool nextRow = currCol + 1 == halfWidth;
            // sample with 50% chance except for the first row
            if (currRow == 0 || random(seed++, 1e18) < .5e18) {
                halfLayout[currRow][currCol] = true;

                // increase the odds of adding a new row as the current row
                // gets wider relative to the previous row
                if (
                    size > 1 &&
                    random(seed++, 1e18) <
                    wadSigmoid(
                        (int256(currCol + 1) - int256(prevHalfWidth)) * 1e18
                    )
                ) {
                    nextRow = true;
                }
            }

            currCol += 1;

            // trim whitespace and add back to size if new row or reached max
            // size
            if (size <= 1 || nextRow) {
                prevHalfWidth = currCol;
                width = max(width, prevHalfWidth * 2 - 1);

                while (currCol > 0 && !halfLayout[currRow][currCol - 1]) {
                    currCol -= 1;
                    size += currCol == 0 ? 1 : 2;
                }

                if (nextRow) {
                    currRow += 1;
                    currCol = 0;
                }
            }
        }

        if (size == 1) {
            if (currCol != 0) currRow += 1;
            halfLayout[currRow] = new bool[](halfWidth);
            halfLayout[currRow][0] = true;
            height = currRow + 1;
            width = max(width, 1);
        }
    }

    function crop(
        bool[][] memory layout,
        uint256 width,
        uint256 height
    ) internal pure returns (bool[][] memory cropped) {
        cropped = new bool[][](height);
        for (uint256 i = 0; i < height; i++) {
            cropped[i] = new bool[](width);
            for (uint256 j = 0; j < width; j++) {
                cropped[i][j] = layout[i][j];
            }
        }
    }

    function connectParts(bool[][] memory halfLayout)
        internal
        pure
        returns (bool[][] memory)
    {
        uint128 width = uint128(halfLayout[0].length);
        for (uint128 i = 0; i < halfLayout.length; i++) {
            for (uint128 j = width; j > 0; j--) {
                if (halfLayout[i][j - 1]) {
                    Point[] memory path = ShortestPath.shortestPath(
                        halfLayout,
                        Point(i, j - 1),
                        directions()
                    );
                    if (path.length > 2) {
                        for (uint128 k = 1; k < path.length - 1; k++) {
                            halfLayout[path[k].x][path[k].y] = true;
                        }
                    }
                }
            }
        }
        return halfLayout;
    }

    function mirrorHalfLayout(
        bool[][] memory halfLayout,
        uint256 width,
        uint256 height
    ) internal pure returns (bool[][] memory fullLayout) {
        uint256 halfWidth = (width + 1) / 2;
        fullLayout = new bool[][](height);
        for (uint256 i = 0; i < height; i++) {
            fullLayout[i] = new bool[](width);
            for (uint256 j = 0; j < halfWidth; j++) {
                fullLayout[i][j] = halfLayout[i][halfWidth - j - 1];
                fullLayout[i][width - j - 1] = halfLayout[i][halfWidth - j - 1];
            }
        }
    }

    function getValue(
        bool[][] memory layout,
        int256 row,
        int256 col
    ) internal pure returns (uint256) {
        if (
            row < 0 ||
            col < 0 ||
            row >= int256(layout.length) ||
            col >= int256(layout[0].length)
        ) {
            return 0;
        }
        uint256 ret = layout[uint256(row)][uint256(col)] ? 1 : 0;
        return ret;
    }
}

function max(uint256 a, uint256 b) pure returns (uint256) {
    return a > b ? a : b;
}

function directions() pure returns (Direction[] memory dirs) {
    dirs = new Direction[](8);

    dirs[0] = Direction(1, 0);
    dirs[1] = Direction(0, -1);
    dirs[2] = Direction(-1, 0);
    dirs[3] = Direction(1, 1);
    dirs[4] = Direction(-1, 1);
    dirs[5] = Direction(1, -1);
    dirs[6] = Direction(-1, -1);
    dirs[7] = Direction(0, 1);

    // dirs[0] = Direction(0, 1);
    // dirs[1] = Direction(-1, 0);
    // dirs[2] = Direction(0, -1);
    // dirs[3] = Direction(1, 1);
    // dirs[4] = Direction(1, -1);
    // dirs[5] = Direction(-1, 1);
    // dirs[6] = Direction(-1, -1);
    // dirs[7] = Direction(1, 0);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct Queue {
    bytes32[] enq;
    bytes32[] deq;
    uint256 enqLen;
    uint256 deqLen;
}

library QueueLib {
    function enqueue(Queue memory q, bytes32 value) internal pure {
        q.enq[q.enqLen++] = value;
    }

    function dequeue(Queue memory q) internal pure returns (bytes32) {
        if (q.deqLen == 0) {
            while (q.enqLen > 0) {
                q.deq[q.deqLen++] = q.enq[--q.enqLen];
            }
        }
        return q.deq[--q.deqLen];
    }

    function isEmpty(Queue memory q) internal pure returns (bool) {
        return q.enqLen == 0 && q.deqLen == 0;
    }

    function length(Queue memory q) internal pure returns (uint256) {
        return q.enqLen + q.deqLen;
    }

    function clear(Queue memory q) internal pure {
        q.enqLen = 0;
        q.deqLen = 0;
    }

    function create(uint256 size) internal pure returns (Queue memory) {
        return Queue(new bytes32[](size), new bytes32[](size), 0, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "solmate/utils/SignedWadMath.sol";

function wadSigmoid(int256 x) pure returns (uint256) {
    return uint256(unsafeWadDiv(1e18, 1e18 + wadExp(-x)));
}

function random(uint256 seed, uint256 max) pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(seed))) % max;
}

function sampleCircle(uint256 seed, uint256 radius)
    pure
    returns (int256 x, int256 y)
{
    unchecked {
        seed = uint256(keccak256(abi.encodePacked(seed)));
        int256 r = int256(random(seed++, radius)) + 1;
        int256 xUnit = int256(random(seed++, 2e18)) - 1e18;
        int256 yUnit = int256(Math.sqrt(1e36 - uint256(xUnit * xUnit)));
        x = int256((xUnit * r) / 1e18);
        y = int256((yUnit * r) / 1e18);
        if (random(seed, 2) == 0) {
            y = -y;
        }
    }
}

function sampleInvSqrt(uint256 seed, uint256 e) pure returns (uint256) {
    return wadInvSqrt(random(seed, 1e18), e) / 2;
}

function wadInvSqrt(uint256 x, uint256 e) pure returns (uint256) {
    return Math.sqrt(1e54 / (e + x));
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./Queue.sol";

struct Point {
    uint128 x;
    uint128 y;
}

struct Direction {
    int128 x;
    int128 y;
}

bytes32 constant VISITED_FLAG = bytes32(uint256(1) << 255);

library ShortestPath {
    using QueueLib for Queue;

    /**
     * @dev return the shortest path Point[] from start to any of the target values
     * @param grid the grid to search; first dimension is x, second dimension is y
     * @param start the starting point
     * @param directions the directions to search in
     * @return path the shortest path from start to any of the target values
     */
    function shortestPath(
        bool[][] memory grid,
        Point memory start,
        Direction[] memory directions
    ) internal pure returns (Point[] memory) {
        Queue memory q = QueueLib.create(grid.length * grid[0].length);
        bytes32[][] memory visited = new bytes32[][](grid.length);
        for (uint256 i = 0; i < grid.length; i++) {
            visited[i] = new bytes32[](grid[i].length);
        }

        q.enqueue(encode(start));
        visited[start.x][start.y] = encodeVisited(start);

        while (!q.isEmpty()) {
            Point memory p = decode(q.dequeue());
            for (uint256 i = 0; i < directions.length; i++) {
                int128 nx = int128(p.x) + directions[i].x;
                int128 ny = int128(p.y) + directions[i].y;
                if (
                    nx >= 0 &&
                    nx < int256(grid.length) &&
                    ny >= 0 &&
                    ny < int256(grid[0].length)
                ) {
                    Point memory np = Point(uint128(nx), uint128(ny));
                    if (visited[np.x][np.y] == bytes32(0)) {
                        visited[np.x][np.y] = encodeVisited(p);
                        if (grid[np.x][np.y]) {
                            return reconstructPath(visited, np);
                        }
                        q.enqueue(encode(np));
                    }
                }
            }
        }

        return new Point[](0);
    }

    function reconstructPath(bytes32[][] memory visited, Point memory end)
        internal
        pure
        returns (Point[] memory)
    {
        unchecked {
            Point[] memory path = new Point[](
                visited.length + visited[0].length
            );
            uint256 pathLen = 0;
            Point memory p = end;
            while (true) {
                path[pathLen++] = p;
                bytes32 value = visited[p.x][p.y];
                if (value == encodeVisited(p)) {
                    break;
                }
                p = decodeVisited(value);
            }
            Point[] memory result = new Point[](pathLen);
            for (uint256 i = 0; i < pathLen; i++) {
                result[i] = path[pathLen - i - 1];
            }
            return result;
        }
    }

    function decode(bytes32 value) internal pure returns (Point memory) {
        unchecked {
            return
                Point(uint128(uint256(value) >> 128), uint128(uint256(value)));
        }
    }

    function encode(Point memory p) internal pure returns (bytes32) {
        unchecked {
            return bytes32((uint256(p.x) << 128) | uint256(p.y));
        }
    }

    function encodeVisited(Point memory p) internal pure returns (bytes32) {
        unchecked {
            return encode(p) | VISITED_FLAG;
        }
    }

    function decodeVisited(bytes32 value) internal pure returns (Point memory) {
        return decode(value & ~VISITED_FLAG);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library StringList {
    /**
     * @dev join list of strings with delimiter
     */
    function join(
        string[] memory list,
        string memory delimiter,
        bool skipEmpty
    ) internal pure returns (string memory) {
        if (list.length == 0) {
            return "";
        }
        string memory result = list[0];
        for (uint256 i = 1; i < list.length; i++) {
            if (skipEmpty && bytes(list[i]).length == 0) continue;
            result = string.concat(result, delimiter, list[i]);
        }
        return result;
    }

    /**
     * @dev concatenate two lists of strings
     */
    function concat(string[] memory list1, string[] memory list2)
        internal
        pure
        returns (string[] memory)
    {
        string[] memory result = new string[](list1.length + list2.length);
        for (uint256 i = 0; i < list1.length; i++) {
            result[i] = list1[i];
        }
        for (uint256 i = 0; i < list2.length; i++) {
            result[list1.length + i] = list2[i];
        }
        return result;
    }
}