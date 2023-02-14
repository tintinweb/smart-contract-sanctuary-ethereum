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

import { Strings} from "openzeppelin/utils/Strings.sol";
import { DynamicBuffer } from 'ethier/utils/DynamicBuffer.sol';
import { Base64 } from "solady/utils/Base64.sol";
import "./interfaces/IIndelible.sol";
import {IGenericRender} from "./interfaces/IGenericRender.sol";
// import "forge-std/console.sol";

interface ICrypToadzMetadata {
    function getMetadata(uint256 tokenId) external view returns (uint8[] memory metadata);
}

interface ICrypToadzStrings {
    function getString(uint8 key) external view returns (string memory);
}

interface ICrypToadzBuilder {
  struct GIF {
    uint32 frameCount;
    GIFFrame[] frames;
    uint16 width;
    uint16 height;
  }
  struct GIFFrame {
      uint32[] buffer;
      uint16 delay;
      uint16 width;
      uint16 height;
  }
    function getImage(uint8[] memory metadata, uint256 tokenId) external view returns (GIF memory gif);
    function getImage(uint8[] memory metadata) external view returns (GIF memory gif);
}

interface ICrypToadzCustomImages {
    function isCustomImage(uint256 tokenId) external view returns (bool);
    function getCustomImage(uint256 tokenId) external view returns (bytes memory buffer);
}

interface ICrypToadzCustomAnimations {
    function isCustomAnimation(uint256 tokenId) external view returns (bool);
    function getCustomAnimation(uint256 tokenId) external view returns (bytes memory buffer);
}

contract ToadzRender is IGenericRender {
    using DynamicBuffer for bytes;

    bytes private constant PNG_URI_PREFIX = "data:image/png;base64,";
    bytes private constant GIF_URI_PREFIX = "data:image/gif;base64,";
    bytes private constant SVG_URI_PREFIX = "data:image/svg+xml;base64,";

    ICrypToadzMetadata metadata = ICrypToadzMetadata(0x317aD381543Ec87DD9341Ee123a5E4e87d4dc495); 
    ICrypToadzBuilder builder = ICrypToadzBuilder(0xB982741Fa2f6727e6c355E78574212C0d59e6768);
    ICrypToadzCustomImages customImages = ICrypToadzCustomImages(0x30730e1978CD7B32D858734c322fB1fFA8ff854f ); 
    ICrypToadzCustomAnimations customAnimations = ICrypToadzCustomAnimations(0x5aD2Abcbc10bD3b04D4Cfbf1089AcF0FCeD67642 );
    ICrypToadzStrings toadStrings = ICrypToadzStrings(0xE79BA77C0B35636D36A2aB8A93426fAF98686B7e);

    error TraitDetailsError();
    error NothingToShow();
    error CustomAnimation();

    function getTraitDetails(uint8 _layerId, uint8 _traitId) external view returns(IIndelible.Trait memory){
        return IIndelible.Trait(toadStrings.getString(getTraitNr(_layerId, _traitId)) , "image/svg+xml");
    }


    /*@dev The following serves as a guideline for forming the input metadata buffer:
         - The array must be between 2 and 7 elements in length
         - The first byte must be `119` (Short) or `120` (Tall)
         - The second byte must be between 0 and 16, and defines the Background         
         - The third byte must be between 17 and 50, and defines the Body
         - The next (up to 5) bytes must define traits in this order: 
           Mouth: between 121 and 139
           Head: between 51 and  104
           Eyes: between 139 and 170
           Clothes: between 246 and clothes 248
           Accessory II: between 104 and 111
           Accessory I: between 237 and 245
         - Trait values can be determined by checking comments in `CrypToadzStrings.sol`
         - The last byte defines the number of traits, based on this look-up table:
           | # Traits | Value |
           | -------- | ----- |
           |        2 |   114 |
           |        3 |   116 |
           |        4 |   112 |
           |        5 |   113 |
           |        6 |   115 |
           |        7 |   118 |
    */
    function getTraitData(uint8 _layerId, uint8 _traitId) external view returns(bytes memory){
        uint8[] memory meta = getMeta(_layerId, _traitId);
        ICrypToadzBuilder.GIF memory data = builder.getImage(meta);
        bytes memory buffer = DynamicBuffer.allocate(2**18);
        buffer.appendSafe(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" version="1.1" viewBox="0 0 36 36" width="360" height="360">'));
        _writeSVGPixels(data.frames[0].buffer, buffer);
        buffer.appendSafe('</svg>');
        if(buffer.length == 134) revert NothingToShow();
        return buffer;
    }

    function getMeta(uint8 _layerId, uint8 _traitId) public pure returns(uint8[] memory) {
      uint8[] memory meta = new uint8[](2);
      meta[0] = _layerId < 8 ? 119 : 120;
      meta[1] = getTraitNr(_layerId, _traitId);
      return meta;
    }

    function getTraitNr(uint8 _layerId, uint8 _traitId) public pure returns(uint8 ) {
      uint8[8] memory start = [0, 17, 121, 51, 139, 245, 104, 237];
      uint8[8] memory end = [16, 50, 137, 103, 167, 248, 111, 244]; 
      uint8 _correctedLayerId = _layerId / 8 > 0 ? _layerId - 7 : _layerId;
      if(_traitId + start[_correctedLayerId] > end[_correctedLayerId]) revert TraitDetailsError();
      return _traitId + start[_correctedLayerId];
    }

    function getCollectionName() external pure returns(string memory){
        return "CrypToadz";
    }

    function getToken(uint256 _tokenId) external view returns(string memory) {
    uint8[] memory meta = metadata.getMetadata(_tokenId);
    meta[1] = 0;
    uint8[] memory newMeta = new uint8[](meta.length-1);
    newMeta[0] = meta[0];
    for(uint i = 1; i < newMeta.length; i++) {
      newMeta[i] = meta[i+1];
    }
    return (_getImageURI(_tokenId, newMeta));
    }

    function _getImageURI(uint256 tokenId, uint8[] memory meta)
        private
        view
        returns (string memory)
    {
        if (customImages.isCustomImage(tokenId)) {
            bytes memory customImage = customImages.getCustomImage(tokenId);
            return string(
                abi.encodePacked(
                    PNG_URI_PREFIX,
                    Base64.encode(customImage)
                )
            );
        }
        if (customAnimations.isCustomAnimation(tokenId)) {
          revert CustomAnimation();
            // bytes memory customAnimation = customAnimations.getCustomAnimation(
            //     tokenId
            // );
            // return string(
            //     abi.encodePacked(
            //         GIF_URI_PREFIX,
            //         Base64.encode(customAnimation)
            //     )
            // );
        }
        
        ICrypToadzBuilder.GIF memory data = builder.getImage(meta);
        bytes memory buffer = DynamicBuffer.allocate(2**18);
        buffer.appendSafe(abi.encodePacked('<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" version="1.1" viewBox="0 0 36 36" width="360" height="360">'));
        _writeSVGPixels(data.frames[0].buffer, buffer);
        buffer.appendSafe('</svg>');
        return string.concat("data:image/svg+xml;base64,", Base64.encode(buffer));
        //return string(buffer);
    }

  function _writeSVGPixels(uint32[] memory data, bytes memory buffer)
    public
    pure
  {
    bytes4 colorbytes;
    uint256 width;
    uint256 pixelNum = 0;
    uint256 imageWidth = 36;
    uint256 xLoc;
    uint256 yLoc;

    // Write every pixel into the buffer
    while (pixelNum < data.length) {
        // so we should start with the pixels that are left botom
        colorbytes = bytes4(data[pixelNum]);
        //only skip if background color (query wiht one coloer)
        if (colorbytes == bytes4(0)) {
            pixelNum++;
            continue;
        }

      width = 1;
      while ((pixelNum + width) % imageWidth != 0) {
        if (colorbytes == bytes4(data[pixelNum+width]) ) {
          width++;
        } else break;
      }

    xLoc = ((pixelNum) % imageWidth);
    yLoc = (pixelNum / imageWidth);

      buffer.appendSafe(
        abi.encodePacked(
          '<rect fill="#',
          _invertUint32ToColor(uint32(colorbytes)),
          '" x="',
          Strings.toString(xLoc),
          '" y="',
          Strings.toString(yLoc),
          '" height="1" width="',
          Strings.toString(width),
          '"/>'
        )
      );

      unchecked {
        pixelNum += width;
      }
    }
  }

    /// Converts 4 bytes (uint32) to a RGBA hex string
  /// @param u the uint32 to convert to a color
  /// @return bytes8 the color in RBGA hex format
  function _invertUint32ToColor(uint32 u) internal pure returns (string memory) {
    bytes memory b = new bytes(8);
    for (uint256 j = 0; j < 6; j = j+2) {
      b[5 - j] = _getHexChar(uint8(uint32(u) & 0x0f));
      u = u >> 4;
      b[5 - (j+1)] = _getHexChar(uint8(uint32(u) & 0x0f));
      u = u >> 4;
    }
    b[6] = _getHexChar(uint8(uint32(u) & 0x0f));
    u = u >> 4;
    b[7] = _getHexChar(uint8(uint32(u) & 0x0f));
    return string(b);
  }


    /// Gets the ascii hex character for a uint8 (byte)
  /// @param char the uint8 to get the ascii hex character for
  /// @return bytes1 ascii hex character for the given uint8
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