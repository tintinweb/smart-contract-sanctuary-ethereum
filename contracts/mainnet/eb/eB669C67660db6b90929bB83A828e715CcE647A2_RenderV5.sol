// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)

pragma solidity >=0.8.0;

/// @title DynamicBuffer
/// @author David Huber (@cxkoda) and Simon Fremaux (@dievardump). See also
///         https://raw.githubusercontent.com/dievardump/solidity-dynamic-buffer
/// @notice This library is used to allocate a big amount of container memory
//          which will be subsequently filled without needing to reallocate
///         memory.
/// @dev First, allocate memory.
///      Then use `buffer.appendUnchecked(theBytes)` or `appendSafe()` if
///      bounds checking is required.
library DynamicBuffer {
    /// @notice Allocates container space for the DynamicBuffer
    /// @param capacity_ The intended max amount of bytes in the buffer
    /// @return buffer The memory location of the buffer
    /// @dev Allocates `capacity_ + 0x60` bytes of space
    ///      The buffer array starts at the first container data position,
    ///      (i.e. `buffer = container + 0x20`)
    function allocate(uint256 capacity_)
        internal
        pure
        returns (bytes memory buffer)
    {
        assembly {
            // Get next-free memory address
            let container := mload(0x40)

            // Allocate memory by setting a new next-free address
            {
                // Add 2 x 32 bytes in size for the two length fields
                // Add 32 bytes safety space for 32B chunked copy
                let size := add(capacity_, 0x60)
                let newNextFree := add(container, size)
                mstore(0x40, newNextFree)
            }

            // Set the correct container length
            {
                let length := add(capacity_, 0x40)
                mstore(container, length)
            }

            // The buffer starts at idx 1 in the container (0 is length)
            buffer := add(container, 0x20)

            // Init content with length 0
            mstore(buffer, 0)
        }

        return buffer;
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Does not perform out-of-bound checks (container capacity)
    ///      for efficiency.
    function appendUnchecked(bytes memory buffer, bytes memory data)
        internal
        pure
    {
        assembly {
            let length := mload(data)
            for {
                data := add(data, 0x20)
                let dataEnd := add(data, length)
                let copyTo := add(buffer, add(mload(buffer), 0x20))
            } lt(data, dataEnd) {
                data := add(data, 0x20)
                copyTo := add(copyTo, 0x20)
            } {
                // Copy 32B chunks from data to buffer.
                // This may read over data array boundaries and copy invalid
                // bytes, which doesn't matter in the end since we will
                // later set the correct buffer length, and have allocated an
                // additional word to avoid buffer overflow.
                mstore(copyTo, mload(data))
            }

            // Update buffer length
            mstore(buffer, add(mload(buffer), length))
        }
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Performs out-of-bound checks and calls `appendUnchecked`.
    function appendSafe(bytes memory buffer, bytes memory data) internal pure {
        checkOverflow(buffer, data.length);
        appendUnchecked(buffer, data);
    }

    /// @notice Appends data encoded as Base64 to buffer.
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// Author: Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
    /// Author: Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Base64.sol)
    /// Author: Modified from (https://github.com/Brechtpd/base64/blob/main/base64.sol) by Brecht Devos.
    function appendSafeBase64(
        bytes memory buffer,
        bytes memory data,
        bool fileSafe,
        bool noPadding
    ) internal pure {
        uint256 dataLength = data.length;

        if (data.length == 0) {
            return;
        }

        uint256 encodedLength;
        uint256 r;
        assembly {
            // For each 3 bytes block, we will have 4 bytes in the base64
            // encoding: `encodedLength = 4 * divCeil(dataLength, 3)`.
            // The `shl(2, ...)` is equivalent to multiplying by 4.
            encodedLength := shl(2, div(add(dataLength, 2), 3))

            r := mod(dataLength, 3)
            if noPadding {
                // if r == 0 => no modification
                // if r == 1 => encodedLength -= 2
                // if r == 2 => encodedLength -= 1
                encodedLength := sub(
                    encodedLength,
                    add(iszero(iszero(r)), eq(r, 1))
                )
            }
        }

        checkOverflow(buffer, encodedLength);

        assembly {
            let nextFree := mload(0x40)

            // Store the table into the scratch space.
            // Offsetted by -1 byte so that the `mload` will load the character.
            // We will rewrite the free memory pointer at `0x40` later with
            // the allocated size.
            mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
            mstore(
                0x3f,
                sub(
                    "ghijklmnopqrstuvwxyz0123456789-_",
                    // The magic constant 0x0230 will translate "-_" + "+/".
                    mul(iszero(fileSafe), 0x0230)
                )
            )

            // Skip the first slot, which stores the length.
            let ptr := add(add(buffer, 0x20), mload(buffer))
            let end := add(data, dataLength)

            // Run over the input, 3 bytes at a time.
            // prettier-ignore
            // solhint-disable-next-line no-empty-blocks
            for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(    ptr    , mload(and(shr(18, input), 0x3F)))
                    mstore8(add(ptr, 1), mload(and(shr(12, input), 0x3F)))
                    mstore8(add(ptr, 2), mload(and(shr( 6, input), 0x3F)))
                    mstore8(add(ptr, 3), mload(and(        input , 0x3F)))
                    
                    ptr := add(ptr, 4) // Advance 4 bytes.
                    // prettier-ignore
                    if iszero(lt(data, end)) { break }
                }

            if iszero(noPadding) {
                // Offset `ptr` and pad with '='. We can simply write over the end.
                mstore8(sub(ptr, iszero(iszero(r))), 0x3d) // Pad at `ptr - 1` if `r > 0`.
                mstore8(sub(ptr, shl(1, eq(r, 1))), 0x3d) // Pad at `ptr - 2` if `r == 1`.
            }

            mstore(buffer, add(mload(buffer), encodedLength))
            mstore(0x40, nextFree)
        }
    }

    /// @notice Returns the capacity of a given buffer.
    function capacity(bytes memory buffer) internal pure returns (uint256) {
        uint256 cap;
        assembly {
            cap := sub(mload(sub(buffer, 0x20)), 0x40)
        }
        return cap;
    }

    /// @notice Reverts if the buffer will overflow after appending a given
    /// number of bytes.
    function checkOverflow(bytes memory buffer, uint256 addedLength)
        internal
        pure
    {
        uint256 cap = capacity(buffer);
        uint256 newLength = buffer.length + addedLength;
        if (cap < newLength) {
            revert("DynamicBuffer: Appending out of bounds.");
        }
    }
}

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
pragma solidity ^0.8.4;

/// @notice Library to encode strings in Base64.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Base64.sol)
/// @author Modified from (https://github.com/Brechtpd/base64/blob/main/base64.sol) by Brecht Devos - <[email protected]>.
library Base64 {
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    function encode(bytes memory data, bool fileSafe, bool noPadding)
        internal
        pure
        returns (string memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                // Multiply by 4/3 rounded up.
                // The `shl(2, ...)` is equivalent to multiplying by 4.
                let encodedLength := shl(2, div(add(dataLength, 2), 3))

                // Set `result` to point to the start of the free memory.
                result := mload(0x40)

                // Store the table into the scratch space.
                // Offsetted by -1 byte so that the `mload` will load the character.
                // We will rewrite the free memory pointer at `0x40` later with
                // the allocated size.
                // The magic constant 0x0230 will translate "-_" + "+/".
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, sub("ghijklmnopqrstuvwxyz0123456789-_", mul(iszero(fileSafe), 0x0230)))

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, encodedLength)

                // Run over the input, 3 bytes at a time.
                for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(0, mload(and(shr(18, input), 0x3F)))
                    mstore8(1, mload(and(shr(12, input), 0x3F)))
                    mstore8(2, mload(and(shr(6, input), 0x3F)))
                    mstore8(3, mload(and(input, 0x3F)))
                    mstore(ptr, mload(0x00))

                    ptr := add(ptr, 4) // Advance 4 bytes.

                    if iszero(lt(ptr, end)) { break }
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))

                // Equivalent to `o = [0, 2, 1][dataLength % 3]`.
                let o := div(2, mod(dataLength, 3))

                // Offset `ptr` and pad with '='. We can simply write over the end.
                mstore(sub(ptr, o), shl(240, 0x3d3d))
                // Set `o` to zero if there is padding.
                o := mul(iszero(iszero(noPadding)), o)
                // Zeroize the slot after the string.
                mstore(sub(ptr, o), 0)
                // Write the length of the string.
                mstore(result, sub(encodedLength, o))
            }
        }
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, false, false)`.
    function encode(bytes memory data) internal pure returns (string memory result) {
        result = encode(data, false, false);
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, fileSafe, false)`.
    function encode(bytes memory data, bool fileSafe)
        internal
        pure
        returns (string memory result)
    {
        result = encode(data, fileSafe, false);
    }

    /// @dev Encodes base64 encoded `data`.
    ///
    /// Supports:
    /// - RFC 4648 (both standard and file-safe mode).
    /// - RFC 3501 (63: ',').
    ///
    /// Does not support:
    /// - Line breaks.
    ///
    /// Note: For performance reasons,
    /// this function will NOT revert on invalid `data` inputs.
    /// Outputs for invalid inputs will simply be undefined behaviour.
    /// It is the user's responsibility to ensure that the `data`
    /// is a valid base64 encoded string.
    function decode(string memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                let decodedLength := mul(shr(2, dataLength), 3)

                for {} 1 {} {
                    // If padded.
                    if iszero(and(dataLength, 3)) {
                        let t := xor(mload(add(data, dataLength)), 0x3d3d)
                        // forgefmt: disable-next-item
                        decodedLength := sub(
                            decodedLength,
                            add(iszero(byte(30, t)), iszero(byte(31, t)))
                        )
                        break
                    }
                    // If non-padded.
                    decodedLength := add(decodedLength, sub(and(dataLength, 3), 1))
                    break
                }
                result := mload(0x40)

                // Write the length of the bytes.
                mstore(result, decodedLength)

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, decodedLength)

                // Load the table into the scratch space.
                // Constants are optimized for smaller bytecode with zero gas overhead.
                // `m` also doubles as the mask of the upper 6 bits.
                let m := 0xfc000000fc00686c7074787c8084888c9094989ca0a4a8acb0b4b8bcc0c4c8cc
                mstore(0x5b, m)
                mstore(0x3b, 0x04080c1014181c2024282c3034383c4044484c5054585c6064)
                mstore(0x1a, 0xf8fcf800fcd0d4d8dce0e4e8ecf0f4)

                for {} 1 {} {
                    // Read 4 bytes.
                    data := add(data, 4)
                    let input := mload(data)

                    // Write 3 bytes.
                    // forgefmt: disable-next-item
                    mstore(ptr, or(
                        and(m, mload(byte(28, input))),
                        shr(6, or(
                            and(m, mload(byte(29, input))),
                            shr(6, or(
                                and(m, mload(byte(30, input))),
                                shr(6, mload(byte(31, input)))
                            ))
                        ))
                    ))

                    ptr := add(ptr, 3)

                    if iszero(lt(ptr, end)) { break }
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))
                // Zeroize the slot after the bytes.
                mstore(end, 0)
                // Restore the zero slot.
                mstore(0x60, 0)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;


import "openzeppelin/access/Ownable.sol";
import { Strings} from "openzeppelin/utils/Strings.sol";
import { Base64 } from "solady/utils/Base64.sol";
import 'ethier/utils/DynamicBuffer.sol';
import {SharedStructs as SSt} from "./sharedStructs.sol";
import "./interfaces/IIndelible.sol";
import {IGenericRender} from "./interfaces/IGenericRender.sol";
// import "forge-std/console.sol";

interface IMash {
    function getCollection(uint256 _collectionNr) external view returns(SSt.CollectionInfo memory);
    function getLayerNames(uint256 collectionNr) external view returns(string[] memory);
}

interface IBlitmap {
    function tokenNameOf(uint256 tokenId) external view returns(string memory);
    function tokenSvgDataOf(uint256 tokenId) external view returns(string memory);
}

interface IKevin {
    function traitTypes(uint256 layer, uint256 trait, uint256 selector) external view returns(string memory);
        function _tokenIdToHash(uint256 _tokenId)
        external
        view
        returns (string memory);
        function hashToSVG(string memory _hash)
        external
        view
        returns (string memory);
}

interface INounsDescriptorV2 {
    function palettes(uint8 paletteIndex) external view returns (bytes memory);
    function backgrounds(uint256 index) external view returns (string memory);
    function bodies(uint256 index) external view returns (bytes memory);
    function accessories(uint256 index) external view returns (bytes memory);
    function heads(uint256 index) external view returns (bytes memory);
    function glasses(uint256 index) external view returns (bytes memory);
    function generateSVGImage(INounsSeeder.Seed memory seed) external view returns (string memory);
    function getPartsForSeed(INounsSeeder.Seed memory seed) external view returns (ISVGRenderer.Part[] memory);
}

interface ISVGRenderer {
    struct Part {
        bytes image;
        bytes palette;
    }
        struct SVGParams {
        Part[] parts;
        string background;
    }

    function generateSVGPart(Part memory part) external view returns (string memory partialSVG);
    function generateSVG(SVGParams calldata params) external pure returns (string memory svg);
}

interface INounsToken {
    function seeds(uint256 _tokenId) external view returns (INounsSeeder.Seed memory);
}

interface INounsSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }
}

contract RenderV5 is Ownable, SSt {
    using Strings for uint256;
    using DynamicBuffer for bytes;

    uint256 public constant MAX_LAYERS = 7; 

    IMash public mash;

    uint24[7] colors = [0xe1d7d5, 0xfbe3ab, 0x72969e, 0xd51e29, 0x174f87, 0x2afd2f, 0x621b62];

    struct CustomRenderer {
        address addr;
        bool base64Encoded; 
    }

    //Non indelible collections that need special treatment are here 
    address constant blitmap = 0x8d04a8c79cEB0889Bdd12acdF3Fa9D207eD3Ff63;
    address constant flipmap = 0x0E4B8e24789630618aA90072F520711D3d9Db647;
    address constant onChainKevin = 0xaC3AE179bB3c0edf2aB2892a2B6A4644A71627B6;
    address constant nounsToken = 0x9C8fF314C9Bc7F6e59A9d9225Fb22946427eDC03;
    INounsDescriptorV2 constant nounsDescriptor = INounsDescriptorV2(0x6229c811D04501523C6058bfAAc29c91bb586268);
    ISVGRenderer constant nounsRenderer = ISVGRenderer(0x81d94554A4b072BFcd850205f0c79e97c92aab56);

    //other contracts that are handled by a seperate renderer are in this mapping
    mapping (address => CustomRenderer) renderers;

    ////////////////////////  Setters /////////////////////////////////

    function setMash( address _newMash) external onlyOwner {
        mash = IMash(_newMash);
    }

    function setColore(uint24[7] calldata _newcolors) external onlyOwner {
        colors = _newcolors;
    }

    function addContract(address _collection, address _render, bool _base64Encoded) external onlyOwner {
        renderers[_collection] = CustomRenderer(_render, _base64Encoded);
    }

    ////////////////////////  Trait Data functions functions /////////////////////////////////

    function getTraitDetails(address _collection, uint8 _layerId, uint8 _traitId, bool _wholeToken) public view returns(IIndelible.Trait memory) {
        uint16 id = (uint16(_layerId) << 8) | uint16(_traitId);
        if(_wholeToken) {
            return IIndelible.Trait(string.concat(getCollectionName(_collection), " ", Strings.toString(id)), ""); //is this always true, also for birds and 
        }
        if(_collection == blitmap) return IIndelible.Trait(IBlitmap(blitmap).tokenNameOf(id),"image/svg+xml");
        if(_collection == flipmap) return IIndelible.Trait(string.concat("Flipmap ", Strings.toString(id)), "image/svg+xml");
        if(_collection == onChainKevin) return IIndelible.Trait(IKevin(onChainKevin).traitTypes(_layerId, _traitId, 0), "image/png");
        if(_collection == nounsToken) return IIndelible.Trait(getNounsTraits(_layerId, _traitId), "image/svg+xml");
        if(renderers[_collection].addr != address(0)) return IGenericRender(renderers[_collection].addr).getTraitDetails(_layerId, _traitId);
        return IIndelible(_collection).traitDetails(_layerId, _traitId);
    }

    function wrapAsBackground(string memory _data) internal pure returns(string memory) {
        bytes memory buffer = DynamicBuffer.allocate(2**20);
        buffer.appendSafe(abi.encodePacked('<svg width="100" height="100" viewBox="0 0 100 100" version="1.2" xmlns="http://www.w3.org/2000/svg" style="background-color:transparent;background-image:url('));
        buffer.appendSafe(bytes(_data));
        buffer.appendSafe(');background-repeat:no-repeat;background-size:contain;background-position:center;image-rendering:-webkit-optimize-contrast;-ms-interpolation-mode:nearest-neighbor;image-rendering:-moz-crisp-edges;image-rendering:pixelated;"></svg>');
        return string.concat('data:image/svg+xml;base64,',Base64.encode(buffer));
    }

    function getCollectionName(address _collection) public view returns(string memory) {
        if(_collection == blitmap) return "Blitmap";
        if(_collection == flipmap) return "Flipmap";
        if(_collection == onChainKevin) return "On Chain Kevin";
        if(_collection == nounsToken) return "Nouns";
        if(renderers[_collection].addr != address(0)) return IGenericRender(renderers[_collection].addr).getCollectionName();
        (string memory out,,,,,,) = IIndelible(_collection).contractData();
        return out;
    }

    // returns the base64 encoded layer including mimetype 
    function getTraitData(address _collection, uint8 _layerId, uint8 _traitId, bool _wholeToken) public view returns(string memory) { 
       uint16 id = (uint16(_layerId) << 8) | uint16(_traitId);

      IIndelible.Trait memory _traitDetails = getTraitDetails(_collection, _layerId, _traitId, _wholeToken) ;
      if(_wholeToken) {
            if(_collection == onChainKevin) return IKevin(onChainKevin).hashToSVG(IKevin(onChainKevin)._tokenIdToHash(id));
            if(_collection == nounsToken) {
                return getNounsToken(id); 
            }
            if(renderers[_collection].addr != address(0)) return IGenericRender(renderers[_collection].addr).getToken(id);
            return IIndelible(_collection).tokenIdToSVG(id);   
        }

        string memory _dataType = string.concat('data:',_traitDetails.mimetype,';base64,');
        
        //here we deal with the seperate layers 
        if(_collection == blitmap || _collection == flipmap) {
            return string.concat(_dataType,Base64.encode(bytes(IBlitmap(_collection).tokenSvgDataOf(id))));
        }
        if(_collection == onChainKevin) return wrapAsBackground(string.concat(_dataType,IKevin(onChainKevin).traitTypes(_layerId, _traitId, 1)));
        if(_collection == nounsToken) {
            return string.concat(_dataType,Base64.encode(abi.encodePacked('<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">', getNounsData(_layerId, _traitId), '</svg>'))); 
        }
        if(renderers[_collection].addr != address(0)) {
            if(renderers[_collection].base64Encoded) return string.concat(_dataType,string(IGenericRender(renderers[_collection].addr).getTraitData(_layerId, _traitId)));
            return string.concat(_dataType,Base64.encode(IGenericRender(renderers[_collection].addr).getTraitData(_layerId, _traitId)));
        }
        return wrapAsBackground(string.concat(_dataType,Base64.encode(bytes(IIndelible(_collection).traitData(_layerId, _traitId)))));
    }
    

    //// special collection functions
    function getNounsTraits(uint8 layerId, uint8 traitId) private pure returns (string memory) {
        if(layerId == 0) return string.concat("Body ", Strings.toString(traitId));
        if(layerId == 1) return string.concat("Accessory ", Strings.toString(traitId));
        if(layerId == 2) return string.concat("Head ", Strings.toString(traitId));
        return string.concat("Glasses ", Strings.toString(traitId));
    }
    
    function getNounsData(uint8 layerId, uint8 traitId) private view returns(string memory) {
        if(layerId == 0) return nounsRenderer.generateSVGPart( ISVGRenderer.Part (nounsDescriptor.bodies(traitId), nounsDescriptor.palettes(0)));
        if(layerId == 1) return nounsRenderer.generateSVGPart( ISVGRenderer.Part (nounsDescriptor.accessories(traitId), nounsDescriptor.palettes(0)));
        if(layerId == 2) return nounsRenderer.generateSVGPart( ISVGRenderer.Part (nounsDescriptor.heads(traitId), nounsDescriptor.palettes(0)));
        return nounsRenderer.generateSVGPart( ISVGRenderer.Part (nounsDescriptor.glasses(traitId), nounsDescriptor.palettes(0)));
    }

    function getNounsToken(uint256 _id) public view returns(string memory) {
        //get seed for token
        INounsSeeder.Seed memory _seed = INounsToken(nounsToken).seeds(_id);
        //get Token for seed
        ISVGRenderer.Part[] memory _parts = nounsDescriptor.getPartsForSeed(_seed);
        //string memory out = INounsDescriptorV2(nounsDescriptor).generateSVGImage(_seed);
        string memory out = nounsRenderer.generateSVG(ISVGRenderer.SVGParams(_parts, ""));
        return string.concat("data:image/svg+xml;base64,",Base64.encode(bytes(out)));
    }

    ////////////////////////  TokenURI and preview /////////////////////////////////

    function tokenURI(uint256 tokenId, LayerStruct[MAX_LAYERS] memory layerInfo, CollectionInfo[MAX_LAYERS] memory _collections) external view returns (string memory) { 
        uint8 numberOfLayers = 0;
        string[MAX_LAYERS] memory collectionNames;
        IIndelible.Trait[MAX_LAYERS] memory traitNames;
        for(uint256 i = 0; i < layerInfo.length; i++) {
            if(layerInfo[i].collection == 0) continue;
            numberOfLayers++; 
            collectionNames[i] = getCollectionName(_collections[i].collection);
            traitNames[i] = getTraitDetails(_collections[i].collection, layerInfo[i].layerId, layerInfo[i].traitId, _collections[i].maxSupply == 99);   
        }
        string memory _outString = string.concat('data:application/json,', '{', '"name" : "CC0 Mash ' , Strings.toString(tokenId), '", ',
            '"description" : "What Is This, a Crossover Episode?"');
        
        _outString = string.concat(_outString, ',"attributes":[');
        string[] memory layerNames; 
        for(uint8 i = 0; i < layerInfo.length; i++) {
            if(layerInfo[i].collection == 0) continue;
            layerNames = mash.getLayerNames(layerInfo[i].collection);
            if(i > 0) _outString = string.concat(_outString,',');
              _outString = string.concat(
              _outString,
             '{"trait_type":"', _collections[i].collection == blitmap ? "Blitmap" : _collections[i].collection == flipmap ? "Flipmap" : _collections[i].maxSupply == 99 ? "Token" :  layerNames[layerInfo[i].layerId], '","value":"', traitNames[i].name,' (from ', collectionNames[i] , ')"}'
             );
        }

        _outString = string.concat(_outString, ']');

        if(numberOfLayers != 0) {
            _outString = string.concat(_outString,',"image": "data:image/svg+xml;base64,',
                Base64.encode(_drawTraits(layerInfo, _collections)), '"');
        }
        else {
            _outString = string.concat(_outString,',"image": "data:image/svg+xml;base64,',
                Base64.encode(_drawPlaceholder()), '"');
        }
        _outString = string.concat(_outString,'}');
        return _outString; 
    }

    function previewCollage(LayerStruct[MAX_LAYERS] memory layerInfo) external view returns(string memory) {
        uint8 numberOfLayers = 0;
        CollectionInfo[MAX_LAYERS] memory _collections;
        IIndelible.Trait[MAX_LAYERS] memory traitNames;
        for(uint256 i = 0; i < layerInfo.length; i++) {
            if(layerInfo[i].collection == 0) continue;
            _collections[i] = mash.getCollection(layerInfo[i].collection);
            traitNames[i] = getTraitDetails(_collections[i].collection, layerInfo[i].layerId, layerInfo[i].traitId, _collections[i].maxSupply == 99);
            ++numberOfLayers;
        }
        if(numberOfLayers == 0 ) return string(_drawPlaceholder());
        return string(_drawTraits(layerInfo, _collections));
    }

    ////////////////////////  SVG functions /////////////////////////////////

    function _drawTraits(LayerStruct[MAX_LAYERS] memory _layerInfo, CollectionInfo[MAX_LAYERS] memory _collections) internal view returns(bytes memory) {
            bytes memory buffer = DynamicBuffer.allocate(2**23);
            //buffer.appendSafe(bytes(string.concat('<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" version="1.1" viewBox="0 0 ', Strings.toString(height), ' ', Strings.toString(width),'" width="',Strings.toString(height*5),'" height="',Strings.toString(width*5),'"> ')));
            int256 height = int256(uint256(_collections[0].xSize*_layerInfo[0].scale));
            int256 width = int256(uint256(_collections[0].ySize*_layerInfo[0].scale));
            if(_layerInfo[0].background != 0) {
                buffer.appendSafe(bytes(string.concat('<rect width="100%" height="100%" fill="#', bytes2hex(colors[_layerInfo[0].background-1]) ,'" />')));
            }
            for(uint256 i = 0; i < _layerInfo.length; i++) {
                if(_layerInfo[i].collection == 0) continue;
                _renderImg(_layerInfo[i], _collections[i], buffer);
                if(!_layerInfo[0].pfpRender) { 
                    if(int256(uint256(_collections[i].ySize*_layerInfo[i].scale))+_layerInfo[i].yOffset > height) height = int256(uint256(_collections[i].ySize*_layerInfo[i].scale))+_layerInfo[i].yOffset;
                    if(int256(uint256(_collections[i].xSize*_layerInfo[i].scale))+_layerInfo[i].xOffset > width) width = int256(uint256(_collections[i].xSize*_layerInfo[i].scale))+_layerInfo[i].xOffset;
                }
            }
            buffer.appendSafe('<style>#pixel {image-rendering: pixelated; image-rendering: -moz-crisp-edges; image-rendering: -webkit-crisp-edges; -ms-interpolation-mode: nearest-neighbor;}</style></svg>');
            return abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" version="1.1" id="pixel" viewBox="0 0 ', Strings.toString(uint256(width)), ' ', Strings.toString(uint256(height)),'" width="',Strings.toString(uint256(width)*20),'" height="',Strings.toString(uint256(height)*20),'"> ', buffer);
    }

    function _drawPlaceholder() private pure returns (bytes memory) {
        return abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" version="1.1" id="pixel" viewBox="0 0 12 12" width="1200" height="1200"><image width="12" height="12" href="', 
        wrapAsBackground("data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAwAAAAMCAYAAABWdVznAAAAAXNSR0IArs4c6QAAAExJREFUKJFjjAwL+s9AAmBBF1i+ah0KPzIsCIXPhE1xZFgQXCG6ASgasJmIDlA0EFKM1QZsziOoAZdivDbgAhjBistkgk5CD076OQkAXuUZII3EzXwAAAAASUVORK5CYII="),
        '"/><style>#pixel {image-rendering: pixelated; image-rendering: -moz-crisp-edges; image-rendering: -webkit-crisp-edges; -ms-interpolation-mode: nearest-neighbor;}</style></svg>');
    }

    function _renderImg(LayerStruct memory _currentLayer, CollectionInfo memory _currentCollection, bytes memory buffer) private view {
        string memory _traitData = getTraitData(_currentCollection.collection, _currentLayer.layerId, _currentLayer.traitId, _currentCollection.maxSupply == 99);
        buffer.appendSafe(bytes(string.concat('<image x="', int8ToString(_currentLayer.xOffset), '" y="', int8ToString(_currentLayer.yOffset),'" width="', Strings.toString(_currentCollection.xSize*_currentLayer.scale), '" height="', Strings.toString(_currentCollection.ySize*_currentLayer.scale),
         '" href="')));
        // if(_currentCollection.maxSupply == 99) {
            buffer.appendSafe(bytes(_traitData));
        // }
        // else {
        //     buffer.appendSafe(abi.encodePacked('data:image/svg+xml;base64,',_traitData));
        // }
        buffer.appendSafe(bytes('"/>'));
    }

    function int8ToString(int8 num) internal pure returns (string memory) {
        return num < 0 ? string.concat("-", Strings.toString(uint8(-1 * num) )): Strings.toString(uint8(num));
    }

    function bytes2hex(uint24 u) internal pure returns (string memory) {
        bytes memory b = new bytes(6);
        for (uint256 j = 0; j < 6; j++) {
        b[5 - j] = _getHexChar(uint8(uint24(u) & 0x0f));
        u = u >> 4;
        }
    return string(b);
    }

    function _getHexChar(uint8 char) internal pure returns (bytes1) {
    return
      (char > 9)
        ? bytes1(char + 87) // ascii a-f
        : bytes1(char + 48); // ascii 0-9
    } 

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IIndelible.sol";

interface IGenericRender {
    function getTraitDetails(uint8 _layerId, uint8 _traitId) external view returns(IIndelible.Trait memory);
    function getTraitData(uint8 _layerId, uint8 _traitId) external view returns(bytes memory);
    function getCollectionName() external view returns(string memory);
    function getToken(uint256 _tokenId) external view returns(string memory);
}

pragma solidity ^0.8.4;

interface IIndelible {
    struct Trait {
        string name;
        string mimetype;
        //bool hide;
    }

    struct ContractData {
            string name;
            string description;
            string image;
            string banner;
            string website;
            uint royalties;
            string royaltiesRecipient;
    }

    function traitData(uint layerIndex, uint traitIndex)
        external
        view
        returns (string memory);

    function traitDetails(uint layerIndex, uint traitIndex)
        external
        view
        returns (Trait memory);

    function contractData() external view returns(string memory, string memory, string memory, string memory , string memory, uint, string memory );
    
    function tokenIdToSVG(uint tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface SharedStructs {

    struct OwnerStruct {
        address owner; //20 bytes
        bytes6 layer1;
        bytes6 layer2;
        bytes6[5] layers;
    }
   
    struct LayerStruct {
        uint8 collection;
        uint8 layerId;
        uint8 traitId;
        bool pfpRender;
        uint8 background;
        uint8 scale;
        int8 xOffset;
        int8 yOffset;
    }

    struct CollectionInfo {
        address collection;
        uint16 maxSupply; 
        uint16 minted; 
        uint8 xSize;
        uint8 ySize;
    }
}