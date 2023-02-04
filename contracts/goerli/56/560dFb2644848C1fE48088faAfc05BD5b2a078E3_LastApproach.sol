// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// Mob
uint256 constant MINIMAL_RAISE_TARGET = 1000000000000000; // 0.001 ETH
uint256 constant MINIMAL_FEE = 25000000000000; // 0.000025 ETH

// below taken from seaport
uint256 constant EIP712_Order_size = 0x180;
uint256 constant EIP712_OfferItem_size = 0xc0;
uint256 constant EIP712_ConsiderationItem_size = 0xe0;
uint256 constant AdditionalRecipients_size = 0x40;

uint256 constant EIP712_DomainSeparator_offset = 0x02;
uint256 constant EIP712_OrderHash_offset = 0x22;
uint256 constant EIP712_DigestPayload_size = 0x42;

bytes32 constant EIP1271_isValidSignature_selector = (
    0x1626ba7e00000000000000000000000000000000000000000000000000000000
);
uint256 constant EIP1271_isValidSignature_signatureHead_negativeOffset = 0x20;
uint256 constant EIP1271_isValidSignature_digest_negativeOffset = 0x40;
uint256 constant EIP1271_isValidSignature_selector_negativeOffset = 0x44;
uint256 constant EIP1271_isValidSignature_calldata_baseLength = 0x64;

uint256 constant EIP1271_isValidSignature_signature_head_offset = 0x40;
uint256 constant EIP_712_PREFIX = (
    0x1901000000000000000000000000000000000000000000000000000000000000
);

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ERC721 {
    /**
     * isApprovedForAll
     */
    function isApprovedForAll(
        address account,
        address operator
    ) external returns (bool);

    /**
     * setApprovalForAll
     */
    function setApprovalForAll(address operator, bool approved) external;

    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 id) external view returns (address owner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import "./ERC721.sol";
import "./Seaport.sol";

import "./Constants.sol";
import "./MobStruct.sol";

contract LastApproach {
    using SafeMath for uint256;

    string public constant VERSION = "1.0.0";

    /** @dev bytes4(keccak256("isValidSignature(bytes32,bytes)") */
    bytes4 internal constant MAGIC_VALUE = 0x1626ba7e;

    bytes public constant MAGIC_SIGNATURE = "0x42";

    /** @dev seaport Opensea proxy  */
    //todo: change to const for production
    address public SEAPORT_CORE = 0x00000000006c3852cbEf3e08E8dF289169EdE581;

    MobMetadata public metadata;
    address[] public members;

    mapping(bytes32 => bool) public allowConduitKeys;

    mapping(address => uint256) public memberDetails;

    mapping(address => uint256) public settlements;

    mapping(bytes32 => bool) public registerOrderHashDigest; // orderHash eip1271 digest

    event MemberJoin(address member, uint256 value);
    event Buy(address indexed seller, uint256 price);
    event Settlement(uint256 total, uint256 time);
    event SettlementAfterDeadline(uint256 total, uint256 time);
    event SettlementAfterBuyFailed(uint256 total);
    event DepositEth(address sender, uint256 amt);
    event Claim(address member, uint256 amt);
    event RefundAfterRaiseFailed(address member, uint256 amt);

    modifier requireStatus(MobStatus _status) {
        require(metadata.status == _status, "wrong status");
        _;
    }

    // Whether the mob deadline has reached
    modifier deadlineReached() {
        require(block.timestamp > metadata.deadline, "still in deadline");
        _;
    }

    // Whether the mob deadline has reached
    modifier deadlineOpen() {
        require(block.timestamp < metadata.deadline, "deadline reached");
        _;
    }

    // Whether the raising has close the time window
    modifier fundRaiseTimeClosed() {
        require(block.timestamp > metadata.raiseDeadline, "fund raising");
        _;
    }

    // Whether the raising is open
    modifier fundRaiseOpen() {
        require(block.timestamp < metadata.raiseDeadline, "time closed");
        require(
            metadata.raisedAmount < metadata.raiseTarget,
            "target already meet"
        );
        _;
    }

    // Whether the raising is open
    modifier fundRaiseFailed() {
        require(block.timestamp > metadata.raiseDeadline, "time not closed");
        require(
            metadata.raisedAmount < metadata.raiseTarget,
            "target already meet"
        );
        _;
    }

    // Whether the raising has been successfully completed
    modifier fundRaiseMeetsTarget() {
        require(
            metadata.raisedAmount == metadata.raiseTarget,
            "target not meet"
        );
        _;
    }

    // Whether the NFT has been successfully owned
    modifier ownedNFT() {
        if (metadata.targetMode == TargetMode.FULL_OPEN) {
            uint256 bal = ERC721(metadata.token).balanceOf(address(this));
            require(bal > 0, "no nft bal");
        }

        if (metadata.targetMode == TargetMode.RESTRICT) {
            address owner = ERC721(metadata.token).ownerOf(metadata.tokenId);
            require(owner == address(this), "not nft owner");
        }
        _;
    }

    // Whether the NFT has been unowned
    modifier unownedNFT() {
        if (metadata.targetMode == TargetMode.FULL_OPEN) {
            uint256 bal = ERC721(metadata.token).balanceOf(address(this));
            require(bal == 0, "nft bal not 0");
        }

        if (metadata.targetMode == TargetMode.RESTRICT) {
            address owner = ERC721(metadata.token).ownerOf(metadata.tokenId);
            require(owner != address(this), "nft still owned");
        }
        _;
    }

    // @custom:oz-upgrades-unsafe-allow constructor
    bytes32 key =
        0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000;
    address conduit = 0x1E0049783F008A0085193E00003D00cd54003c71;

    constructor() {
        SEAPORT_CORE = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
    }

    receive() external payable {
        if (msg.value > 0) {
            emit DepositEth(msg.sender, msg.value);
        }
    }

    /**
     * @notice members join pay ETH
     */
    function joinPay(
        address member
    ) public payable fundRaiseOpen requireStatus(MobStatus.RAISING) {
        memberDeposit(member, msg.value);
    }

    function memberDeposit(
        address addr,
        uint256 amt
    ) internal fundRaiseOpen requireStatus(MobStatus.RAISING) {
        require(amt > 0, "Value must gt 0");
        require(
            metadata.raiseTarget >= metadata.raisedAmount + amt,
            "Exceeding the limit"
        );

        if (memberDetails[addr] == 0) {
            members.push(addr);
        }
        memberDetails[addr] = memberDetails[addr] + amt;

        if (metadata.raiseTarget == metadata.raisedAmount + amt) {
            _applyNextStatus();
        }

        metadata.raisedAmount += amt;

        emit MemberJoin(addr, amt);
    }

    /** @notice refund stake after raise failed */
    function refundAfterRaiseFailed()
        public
        fundRaiseTimeClosed
        requireStatus(MobStatus.RAISING)
    {
        require(memberDetails[msg.sender] > 0, "no share");

        uint256 amt = memberDetails[msg.sender];
        memberDetails[msg.sender] = 0;
        metadata.raisedAmount -= amt;

        payable(msg.sender).transfer(amt);

        emit RefundAfterRaiseFailed(msg.sender, amt);
    }

    // simple eth_to_erc721 buying
    function buyBasicOrder(
        BasicOrderParameters calldata parameters
    )
        external
        payable
        deadlineOpen
        fundRaiseMeetsTarget
        requireStatus(MobStatus.RAISE_SUCCESS)
        returns (bool isFulFilled)
    {
        _verifyBuyBasicOrder(parameters);

        bool isSuccess = SeaportInterface(SEAPORT_CORE).fulfillBasicOrder{
            value: address(this).balance
        }(parameters);

        if (isSuccess) {
            emit Buy(parameters.offerer, address(this).balance);
            _applyNextStatus();

            // record the token id if it is full open mode
            if (metadata.targetMode == TargetMode.FULL_OPEN) {
                metadata.tokenId = parameters.offerIdentifier;
            }
        }

        return isSuccess;
    }

    function _verifyBuyBasicOrder(
        BasicOrderParameters calldata parameters
    ) internal view {
        require(
            parameters.basicOrderType == BasicOrderType.ETH_TO_ERC721_FULL_OPEN,
            "wrong order type"
        );
        require(parameters.offerToken == metadata.token, "buying wrong token");
        require(
            parameters.fulfillerConduitKey == bytes32(0),
            "fulfillerConduitKey must be zero"
        );

        if (metadata.targetMode == TargetMode.RESTRICT) {
            require(
                parameters.offerIdentifier == metadata.tokenId,
                "wrong offer.tokenId"
            );
        }
    }

    // buy with seaport fulFillOrder
    function buyOrder(
        Order calldata order,
        bytes32 fulfillerConduitKey
    )
        external
        payable
        deadlineOpen
        fundRaiseMeetsTarget
        requireStatus(MobStatus.RAISE_SUCCESS)
        returns (bool isFulFilled)
    {
        _verifyBuyOrder(order);
        _verifyFulfillerConduitKey(fulfillerConduitKey);

        bool isSuccess = SeaportInterface(SEAPORT_CORE).fulfillOrder{
            value: address(this).balance
        }(order, fulfillerConduitKey);

        if (isSuccess) {
            emit Buy(order.parameters.offerer, address(this).balance);
            _applyNextStatus();

            // record the token id if it is full open mode
            if (metadata.targetMode == TargetMode.FULL_OPEN) {
                metadata.tokenId = order
                    .parameters
                    .offer[0]
                    .identifierOrCriteria;
            }
        }

        return isSuccess;
    }

    function _verifyFulfillerConduitKey(
        bytes32 fulfillerConduitKey
    ) internal pure {
        require(fulfillerConduitKey == bytes32(0), "fulfillerConduitKey not 0");
    }

    function _verifyBuyOrder(Order calldata order) internal view {
        OrderParameters calldata orderParameters = order.parameters;
        // check order parameters
        require(orderParameters.offer.length == 1, "offer length !=1");

        _verifyBuyOrderOfferItem(orderParameters.offer[0]);
        _verifyBuyOrderConsiderationItem(orderParameters.consideration[0]);
    }

    function _verifyBuyOrderOfferItem(OfferItem calldata offer) internal view {
        require(offer.itemType == ItemType.ERC721, "wrong offer.ItemType");
        require(offer.token == metadata.token, "wrong offer.token");
        require(offer.startAmount == 1, "wrong offer.startAmount");
        require(offer.endAmount == 1, "wrong offer.endAmount");

        if (metadata.targetMode == TargetMode.RESTRICT) {
            require(
                offer.identifierOrCriteria == metadata.tokenId,
                "wrong offer.tokenId"
            );
        }
    }

    // only accept ether
    function _verifyBuyOrderConsiderationItem(
        ConsiderationItem calldata consider
    ) internal pure {
        require(
            consider.itemType == ItemType.NATIVE,
            "wrong consider.ItemType"
        );
        require(consider.token == address(0), "wrong consider.token");
    }

    // submit sell orders on chain
    // only the offerer require no signature
    function validateSellOrders(
        Order[] calldata orders
    )
        external
        ownedNFT
        deadlineOpen
        requireStatus(MobStatus.NFT_BOUGHT)
        returns (bool isValidated)
    {
        _verifySellOrders(orders);

        // submit order ot seaport
        return SeaportInterface(SEAPORT_CORE).validate(orders);
    }

    function _verifySellOrders(Order[] calldata orders) internal view {
        // Skip overflow check as for loop is indexed starting at zero.
        unchecked {
            // Read length of the orders array from memory and place on stack.
            uint256 totalOrders = orders.length;

            // Iterate over each order.
            for (uint256 i = 0; i < totalOrders; ) {
                // Retrieve the order.
                Order calldata order = orders[i];
                // Retrieve the order parameters.
                OrderParameters calldata orderParameters = order.parameters;

                // check order parameters
                require(
                    orderParameters.offerer == address(this),
                    "wrong offerer"
                );
                require(orderParameters.zone == address(0), "zone != 0");
                require(
                    orderParameters.zoneHash == bytes32(0),
                    "zoneHash != 0"
                );

                // allow to accept extra offer/consideration
                require(orderParameters.offer.length >= 1, "offer length 0");
                require(
                    orderParameters.consideration.length >= 1,
                    "consideration length 0"
                );
                require(
                    orderParameters.orderType == OrderType.FULL_OPEN,
                    "wrong orderType"
                );
                require(
                    orderParameters.conduitKey == bytes32(0) ||
                        allowConduitKeys[orderParameters.conduitKey] == true,
                    "conduitKey not allowed"
                );

                // only check if first offer/consideration meet requirement
                _verifyOfferItem(orderParameters.offer[0]);
                _verifyConsiderationItem(orderParameters.consideration[0]);

                // Increment counter inside body of the loop for gas efficiency.
                ++i;
            }
        }
    }

    function _verifyOfferItem(OfferItem calldata offer) internal view {
        require(offer.itemType == ItemType.ERC721, "wrong offer.ItemType");
        require(offer.token == metadata.token, "wrong offer.token");
        require(offer.startAmount == 1, "wrong offer.startAmount");
        require(offer.endAmount == 1, "wrong offer.endAmount");

        if (metadata.targetMode == TargetMode.RESTRICT) {
            require(
                offer.identifierOrCriteria == metadata.tokenId,
                "wrong offer.tokenId"
            );
        }
    }

    // only accept ether
    function _verifyConsiderationItem(
        ConsiderationItem calldata consider
    ) internal view {
        require(
            consider.itemType == ItemType.NATIVE,
            "wrong consider.ItemType"
        );
        require(consider.token == address(0), "wrong consider.token");

        // TODO: introduce price Oracle to enable stopLossPrice selling
        require(
            consider.startAmount >= metadata.takeProfitPrice,
            "wrong consider.startAmount"
        );
        require(
            consider.endAmount >= metadata.takeProfitPrice,
            "wrong consider.endAmount"
        );

        require(
            consider.recipient == address(this),
            "wrong consider.recipient"
        );
    }

    // register sell orders for later isValidSignature checking
    function registerSellOrder(
        Order[] calldata orders
    ) external ownedNFT deadlineOpen requireStatus(MobStatus.NFT_BOUGHT) {
        _verifySellOrders(orders);

        // Skip overflow check as for loop is indexed starting at zero.
        unchecked {
            // Read length of the orders array from memory and place on stack.
            uint256 totalOrders = orders.length;
            uint256 counter = SeaportInterface(SEAPORT_CORE).getCounter(
                address(this)
            );

            // Iterate over each order.
            for (uint256 i = 0; i < totalOrders; ) {
                Order calldata order = orders[i];
                OrderParameters calldata orderParameters = order.parameters;

                OrderComponents memory orderComponents = OrderComponents(
                    orderParameters.offerer,
                    orderParameters.zone,
                    orderParameters.offer,
                    orderParameters.consideration,
                    orderParameters.orderType,
                    orderParameters.startTime,
                    orderParameters.endTime,
                    orderParameters.zoneHash,
                    orderParameters.salt,
                    orderParameters.conduitKey,
                    counter
                );

                // register orderHash
                bytes32 orderHash = SeaportInterface(SEAPORT_CORE).getOrderHash(
                    orderComponents
                );
                // Derive EIP-712 digest using the domain separator and the order hash.
                bytes32 digest = _deriveEIP712Digest(
                    _deriveDomainSeparator(),
                    orderHash
                );
                registerOrderHashDigest[digest] = true;

                // Increment counter inside body of the loop for gas efficiency.
                ++i;
            }
        }
    }

    // taken from seaport contract
    /**
     * @dev Internal pure function to efficiently derive an digest to sign for
     *      an order in accordance with EIP-712.
     *
     * @param domainSeparator The domain separator.
     * @param orderHash       The order hash.
     *
     * @return value The hash.
     */
    function _deriveEIP712Digest(
        bytes32 domainSeparator,
        bytes32 orderHash
    ) internal pure returns (bytes32 value) {
        // Leverage scratch space to perform an efficient hash.
        assembly {
            // Place the EIP-712 prefix at the start of scratch space.
            mstore(0, EIP_712_PREFIX)

            // Place the domain separator in the next region of scratch space.
            mstore(EIP712_DomainSeparator_offset, domainSeparator)

            // Place the order hash in scratch space, spilling into the first
            // two bytes of the free memory pointer — this should never be set
            // as memory cannot be expanded to that size, and will be zeroed out
            // after the hash is performed.
            mstore(EIP712_OrderHash_offset, orderHash)

            // Hash the relevant region (65 bytes).
            value := keccak256(0, EIP712_DigestPayload_size)

            // Clear out the dirtied bits in the memory pointer.
            mstore(EIP712_OrderHash_offset, 0)
        }
    }

    /**
     * @dev Internal view function to derive the EIP-712 domain separator.
     *
     * @return The derived domain separator.
     */
    function _deriveDomainSeparator() internal view returns (bytes32) {
        bytes32 _EIP_712_DOMAIN_TYPEHASH = keccak256(
            abi.encodePacked(
                "EIP712Domain(",
                "string name,",
                "string version,",
                "uint256 chainId,",
                "address verifyingContract",
                ")"
            )
        );
        // Derive hash of the name of the contract.
        bytes32 nameHash = keccak256(bytes("Seaport"));

        // Derive hash of the version string of the contract.
        bytes32 versionHash = keccak256(bytes("1.1"));

        // prettier-ignore
        return keccak256(
            abi.encode(
                _EIP_712_DOMAIN_TYPEHASH,
                nameHash,
                versionHash,
                block.chainid,
                address(SEAPORT_CORE)
            )
        );
    }

    /** TODO
     * @notice Verifies that the signer is the owner of the signing contract.
     */
    function isValidSignature(
        bytes32 _orderHashDigest,
        bytes calldata _signature
    )
        external
        view
        ownedNFT
        requireStatus(MobStatus.NFT_BOUGHT) // only selling needs signature
        returns (bytes4)
    {
        // must use special magic signature placeholder
        require(
            keccak256(_signature) == keccak256(MAGIC_SIGNATURE),
            "unallow signature"
        );
        require(
            registerOrderHashDigest[_orderHashDigest] == true,
            "orderHash not register"
        );

        return MAGIC_VALUE;
    }

    /** @dev Distribute profits */
    function settlementAllocation()
        external
        unownedNFT
        requireStatus(MobStatus.NFT_BOUGHT)
    {
        uint256 amt = address(this).balance;
        require(amt > 0, "Amt must gt 0");

        _applyNextStatus();

        for (uint256 i = 0; i < members.length; i++) {
            uint256 share = memberDetails[members[i]];
            settlements[members[i]] = (amt / metadata.raisedAmount) * share;
        }

        emit Settlement(amt, block.timestamp);
    }

    /** @dev Distribute profits after deadline,
     *  use for two situation
     *      1. nft balance attacking(contract already sold nft)
     *      2. nft can not be sold after deadline
     *
     * Note: another way to deal with nft balance attacking
     * is to continually sell the new receieved attacking nft
     * to empty the balance so that settlement can be called.
     * In that case, members might gain some extra profit,
     * and there remains little motivation for attacker to do that.
     */
    function settlementAfterDeadline()
        external
        deadlineReached
        requireStatus(MobStatus.NFT_BOUGHT)
    {
        uint256 amt = address(this).balance;
        require(amt > 0, "Amt must gt 0");

        _applyNextStatus();

        for (uint256 i = 0; i < members.length; i++) {
            uint256 share = memberDetails[members[i]];
            settlements[members[i]] = (amt / metadata.raisedAmount) * share;
        }

        emit SettlementAfterDeadline(amt, block.timestamp);
    }

    /** @dev refund after deadline, use for buy failed */
    function settlementAfterBuyFailed()
        external
        deadlineReached
        requireStatus(MobStatus.RAISE_SUCCESS)
    {
        uint256 amt = address(this).balance;
        require(amt > 0, "Amt must gt 0");

        // raise_success to can_claim
        _applyNextStatusWithJump(2);

        for (uint256 i = 0; i < members.length; i++) {
            uint256 share = memberDetails[members[i]];
            settlements[members[i]] = (amt / metadata.raisedAmount) * share;
        }

        emit SettlementAfterBuyFailed(amt);
    }

    /** @dev receive income  */
    function claim() public requireStatus(MobStatus.CAN_CLAIM) {
        uint256 amt = settlements[msg.sender];
        if (amt > 0) {
            settlements[msg.sender] = 0;
            emit Claim(msg.sender, amt);
        }

        bool isAllClaimed = true;
        for (uint256 i = 0; i < members.length; i++) {
            if (settlements[members[i]] > 0) {
                isAllClaimed = false;
            }
        }
        if (isAllClaimed) {
            _applyNextStatus();
        }

        if (amt > 0) {
            payable(msg.sender).transfer(amt);
        }
    }

    function _applyNextStatus() internal {
        metadata.status = MobStatus(uint256(metadata.status) + 1);
    }

    function _applyNextStatusWithJump(uint8 steps) internal {
        metadata.status = MobStatus(uint256(metadata.status) + steps);
    }

    function _getTargetMode(
        uint8 mode
    ) internal pure returns (TargetMode targetMode) {
        if (mode == uint256(TargetMode.RESTRICT)) {
            return TargetMode.RESTRICT;
        } else if (mode == uint256(TargetMode.FULL_OPEN)) {
            return TargetMode.RESTRICT;
        } else {
            revert("invalid target mode");
        }
    }

    // todo: remove this
    // only for local test
    function setSeaportAddress(address seaport) external {
        SEAPORT_CORE = seaport;
        // Approve All Token Nft-Id For SeaportCore contract
        ERC721(metadata.token).setApprovalForAll(SEAPORT_CORE, true);
    }

    // todo: should add onlyOwner modifier
    function setAllowConduitKey(bytes32 _key, address _conduit) external {
        if (allowConduitKeys[_key] == false) {
            allowConduitKeys[_key] = true;

            // Approve All Token Nft-Id For conduit contract
            ERC721(metadata.token).setApprovalForAll(_conduit, true);
        } else {
            revert("conduitKey already allow");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// note: only include successful status
enum MobStatus {
    RAISING,
    RAISE_SUCCESS,
    NFT_BOUGHT,
    CAN_CLAIM, // NFT_SOLD is not including, we can not check nft is sold on chain
    ALL_CLAIMED
}

enum TargetMode {
    // only buy tokenId NFT
    RESTRICT,
    // don't check tokenId, any tokenId within token is good
    FULL_OPEN
}

struct MobMetadata {
    string name;
    address creator;
    address token; // nft token address
    uint256 tokenId; // nft token id, ERC721 standard require uint256
    uint256 raisedAmount;
    uint256 raiseTarget;
    uint256 takeProfitPrice;
    uint256 stopLossPrice;
    uint256 fee;
    uint64 deadline;
    uint64 raiseDeadline;
    TargetMode targetMode;
    MobStatus status;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface SeaportInterface {
    function fulfillBasicOrder(
        BasicOrderParameters calldata parameters
    ) external payable returns (bool fulfilled);

    function fulfillOrder(
        Order calldata order,
        bytes32 fulfillerConduitKey
    ) external payable returns (bool fulfilled);

    function validate(
        Order[] calldata orders
    ) external returns (bool validated);

    function getOrderHash(
        OrderComponents calldata order
    ) external view returns (bytes32 orderHash);

    function getCounter(
        address offerer
    ) external view returns (uint256 counter);
}

struct OrderComponents {
    address offerer;
    address zone;
    OfferItem[] offer;
    ConsiderationItem[] consideration;
    OrderType orderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 conduitKey;
    uint256 counter;
}

struct OfferItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
}

struct ConsiderationItem {
    ItemType itemType;
    address token;
    uint256 identifierOrCriteria;
    uint256 startAmount;
    uint256 endAmount;
    address payable recipient;
}

struct OrderParameters {
    address offerer; // 0x00
    address zone; // 0x20
    OfferItem[] offer; // 0x40
    ConsiderationItem[] consideration; // 0x60
    OrderType orderType; // 0x80
    uint256 startTime; // 0xa0
    uint256 endTime; // 0xc0
    bytes32 zoneHash; // 0xe0
    uint256 salt; // 0x100
    bytes32 conduitKey; // 0x120
    uint256 totalOriginalConsiderationItems; // 0x140
    // offer.length                          // 0x160
}

/**
 * @dev Orders require a signature in addition to the other order parameters.
 */
struct Order {
    OrderParameters parameters;
    bytes signature;
}

struct BasicOrderParameters {
    address considerationToken;
    uint256 considerationIdentifier;
    uint256 considerationAmount;
    address payable offerer;
    address zone;
    address offerToken;
    uint256 offerIdentifier;
    uint256 offerAmount;
    BasicOrderType basicOrderType;
    uint256 startTime;
    uint256 endTime;
    bytes32 zoneHash;
    uint256 salt;
    bytes32 offererConduitKey;
    bytes32 fulfillerConduitKey;
    uint256 totalOriginalAdditionalRecipients;
    AdditionalRecipient[] additionalRecipients;
    bytes signature;
}

// prettier-ignore
enum BasicOrderType {
    // 0: no partial fills, anyone can execute
    ETH_TO_ERC721_FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    ETH_TO_ERC721_PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    ETH_TO_ERC721_FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC721_PARTIAL_RESTRICTED,

    // 4: no partial fills, anyone can execute
    ETH_TO_ERC1155_FULL_OPEN,

    // 5: partial fills supported, anyone can execute
    ETH_TO_ERC1155_PARTIAL_OPEN,

    // 6: no partial fills, only offerer or zone can execute
    ETH_TO_ERC1155_FULL_RESTRICTED,

    // 7: partial fills supported, only offerer or zone can execute
    ETH_TO_ERC1155_PARTIAL_RESTRICTED,

    // 8: no partial fills, anyone can execute
    ERC20_TO_ERC721_FULL_OPEN,

    // 9: partial fills supported, anyone can execute
    ERC20_TO_ERC721_PARTIAL_OPEN,

    // 10: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC721_FULL_RESTRICTED,

    // 11: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC721_PARTIAL_RESTRICTED,

    // 12: no partial fills, anyone can execute
    ERC20_TO_ERC1155_FULL_OPEN,

    // 13: partial fills supported, anyone can execute
    ERC20_TO_ERC1155_PARTIAL_OPEN,

    // 14: no partial fills, only offerer or zone can execute
    ERC20_TO_ERC1155_FULL_RESTRICTED,

    // 15: partial fills supported, only offerer or zone can execute
    ERC20_TO_ERC1155_PARTIAL_RESTRICTED,

    // 16: no partial fills, anyone can execute
    ERC721_TO_ERC20_FULL_OPEN,

    // 17: partial fills supported, anyone can execute
    ERC721_TO_ERC20_PARTIAL_OPEN,

    // 18: no partial fills, only offerer or zone can execute
    ERC721_TO_ERC20_FULL_RESTRICTED,

    // 19: partial fills supported, only offerer or zone can execute
    ERC721_TO_ERC20_PARTIAL_RESTRICTED,

    // 20: no partial fills, anyone can execute
    ERC1155_TO_ERC20_FULL_OPEN,

    // 21: partial fills supported, anyone can execute
    ERC1155_TO_ERC20_PARTIAL_OPEN,

    // 22: no partial fills, only offerer or zone can execute
    ERC1155_TO_ERC20_FULL_RESTRICTED,

    // 23: partial fills supported, only offerer or zone can execute
    ERC1155_TO_ERC20_PARTIAL_RESTRICTED
}

// prettier-ignore
enum OrderType {
    // 0: no partial fills, anyone can execute
    FULL_OPEN,

    // 1: partial fills supported, anyone can execute
    PARTIAL_OPEN,

    // 2: no partial fills, only offerer or zone can execute
    FULL_RESTRICTED,

    // 3: partial fills supported, only offerer or zone can execute
    PARTIAL_RESTRICTED
}

// prettier-ignore
enum ItemType {
    // 0: ETH on mainnet, MATIC on polygon, etc.
    NATIVE,

    // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
    ERC20,

    // 2: ERC721 items
    ERC721,

    // 3: ERC1155 items
    ERC1155,

    // 4: ERC721 items where a number of tokenIds are supported
    ERC721_WITH_CRITERIA,

    // 5: ERC1155 items where a number of ids are supported
    ERC1155_WITH_CRITERIA
}

struct AdditionalRecipient {
    uint256 amount;
    address payable recipient;
}