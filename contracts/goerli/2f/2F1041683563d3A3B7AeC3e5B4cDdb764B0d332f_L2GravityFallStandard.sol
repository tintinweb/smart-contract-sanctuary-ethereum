// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBridgedToken is IERC20 {
  function mint(address, uint256) external;

  function burn(address, uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBridgeConfig {
  struct Order {
    bool executed;
    address l1Token;
    address l2Token;
    address from;
    address to;
    uint256 amount;
    mapping(address => bool) isConfirmed;
  }

  /* Views */
  function keeper() external returns (address);

  function consensusPowerThreshold() external returns (uint256);

  function validatorPowers(address) external returns (uint256);

  function tokensGateway(address, address) external returns (bool);

  function getValidators() external returns (address[] memory, uint256[] memory);

  /* Actions */
  function updateKeeper(address _account) external;

  function updateConsensusPowerThreshold(uint256 _amount) external;

  function addValidators(address[] memory _accounts) external;

  function updateValidatorsPowers(address[] memory _validators, uint256[] memory _powers) external;

  function removeValidators(address[] memory _accounts) external;

  function updateTokensGateway(
    address[] memory _l1Tokens,
    address[] memory _l2Tokens,
    bool[] memory _status
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { MemberSet } from "../libs/MemberSet.sol";

// verified
contract Multisig {
  using MemberSet for MemberSet.Record;

  struct Transaction {
    bool executed;
    bytes data;
    uint256 value;
    uint256 numConfirmations;
  }

  // variables
  MemberSet.Record internal members;
  // mapping from tx index => owner => bool
  mapping(uint256 => mapping(address => bool)) public isConfirmed;
  Transaction[] public transactions;

  event SubmitTransaction(uint256 indexed txIndex, address indexed account, uint256 value, bytes data);
  event ConfirmTransaction(uint256 indexed txIndex, address indexed owner);
  event RevokeConfirmation(uint256 indexed txIndex, address indexed owner);
  event ExecuteTransaction(uint256 indexed txIndex, address indexed owner);

  constructor() {
    members.add(msg.sender);
  }

  /** Modifier */
  // verified
  modifier requireMultisig() {
    require(msg.sender == address(this), "Multisig required");
    _;
  }

  // verified
  modifier requireOwner() {
    require(members.contains(msg.sender), "Owner required");
    _;
  }

  // verified
  modifier requireTxExists(uint256 _txIndex) {
    require(_txIndex < transactions.length, "Nonexistent tx");
    _;
  }

  modifier requireTxNotExecuted(uint256 _txIndex) {
    require(!transactions[_txIndex].executed, "Tx already executed");
    _;
  }

  /* View */
  // verified
  function isOwner(address _account) public view returns (bool) {
    return members.contains(_account);
  }

  // verified
  function getMembers() public view returns (address[] memory) {
    uint256 size = members.size();
    address[] memory records = new address[](size);

    for (uint256 i = 0; i < size; i++) {
      records[i] = members.at(i);
    }
    return records;
  }

  // verified
  function getMemberByIndex(uint256 _index) public view returns (address) {
    return members.at(_index);
  }

  // verified
  function getTransactionCount() public view returns (uint256) {
    return transactions.length;
  }

  // verified
  function getTransaction(uint256 _idx) public view returns (Transaction memory, bytes4 funcSelector) {
    bytes memory data = transactions[_idx].data;
    assembly {
      funcSelector := mload(add(data, 32))
    }
    return (transactions[_idx], funcSelector);
  }

  // verified
  function getSelector(string calldata _func) external pure returns (bytes4) {
    return bytes4(keccak256(bytes(_func)));
  }

  /* Admins */
  // verified
  function addMember(address _account) public virtual requireMultisig {
    members.add(_account);
  }

  // verified
  function removeMember(address _account) public virtual requireMultisig {
    require(members.size() > 1, "Cannot remove last member");
    members.remove(_account);
  }

  // verified
  function submitTransaction(uint256 _value, bytes calldata _data) public requireOwner {
    _beforeAddTransaction(_data);

    uint256 txIndex = transactions.length;

    transactions.push(Transaction({ executed: false, data: _data, value: _value, numConfirmations: 0 }));

    confirmTransaction(txIndex);

    emit SubmitTransaction(txIndex, msg.sender, _value, _data);
  }

  // verified
  function confirmTransaction(uint256 _txIndex) public requireOwner requireTxExists(_txIndex) requireTxNotExecuted(_txIndex) {
    Transaction storage transaction = transactions[_txIndex];

    require(!isConfirmed[_txIndex][msg.sender], "Already confirmed");

    transaction.numConfirmations += 1;
    isConfirmed[_txIndex][msg.sender] = true;

    emit ConfirmTransaction(_txIndex, msg.sender);
  }

  // verified
  function executeTransaction(uint256 _txIndex) public requireOwner requireTxExists(_txIndex) requireTxNotExecuted(_txIndex) {
    Transaction storage transaction = transactions[_txIndex];
    uint256 numConfirmationsRequired = members.size() / 2 + 1;

    require(transaction.numConfirmations >= numConfirmationsRequired, "Confirmations required");

    transaction.executed = true;

    (bool success, ) = address(this).call{ value: transaction.value }(transaction.data);
    require(success, "Tx failed");

    emit ExecuteTransaction(_txIndex, msg.sender);
  }

  // verified
  function revokeConfirmation(uint256 _txIndex) public requireOwner requireTxExists(_txIndex) requireTxNotExecuted(_txIndex) {
    Transaction storage transaction = transactions[_txIndex];

    require(isConfirmed[_txIndex][msg.sender], "Confirmation required");

    transaction.numConfirmations -= 1;
    isConfirmed[_txIndex][msg.sender] = false;

    emit RevokeConfirmation(_txIndex, msg.sender);
  }

  /* Internal */
  // verified
  function _beforeAddTransaction(bytes calldata _data) internal pure virtual {
    bytes4 funcSelector = bytes4(_data[:4]);
    require(
      funcSelector == this.addMember.selector || //
        funcSelector == this.removeMember.selector,
      "Invalid function selector"
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IL2BridgeStandard {
  /* Events */
  event TokenDepositCompleted(uint256 indexed orderId, address indexed l1Token, address indexed l2Token, address from, address to, uint256 amount);
  event TokenWithdrawalQueued(uint256 indexed orderId, address indexed l1Token, address indexed l2Token, address from, address to, uint256 amount);

  /* Execute */
  function withdrawETH() external payable;

  // verified
  function withdrawETHTo(address _to) external payable;

  // verified
  function withdrawERC20(
    address _l1Token,
    address _l2Token,
    uint256 _amount
  ) external;

  // verified
  function withdrawERC20To(
    address _l1Token,
    address _l2Token,
    address _to,
    uint256 _amount
  ) external;

  function executeETHDeposit(
    address[] memory _currentValidators,
    bytes[] memory _signatures,
    // transaction data
    bytes32 _txnHash,
    uint256 _orderId,
    address _from,
    address _to,
    uint256 _amount
  ) external;

  function executeERC20Deposit(
    address[] memory _currentValidators,
    bytes[] memory _signatures,
    // transaction data
    bytes32 _txnHash,
    uint256 _orderId,
    address _l1Token,
    address _l2Token,
    address _from,
    address _to,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { Multisig, MemberSet } from "../common/Multisig.sol";
import { IBridgedToken } from "../common/IBridgedToken.sol";
import { IL2BridgeStandard } from "./IL2BridgeStandard.sol";
import { IBridgeConfig } from "../common/IConfig.sol";

contract L2GravityFallStandard is IBridgeConfig, ReentrancyGuard, Multisig, IL2BridgeStandard {
  using ECDSA for bytes32;
  using MemberSet for MemberSet.Record;

  // variables
  address public keeper;
  uint256 public consensusPowerThreshold;
  MemberSet.Record internal validators;
  mapping(address => uint256) public validatorPowers;
  mapping(uint256 => Order) public deposits;
  Order[] public withdrawals;

  mapping(address => mapping(address => bool)) public tokensGateway;

  receive() external payable {}

  /* Modifiers */
  // verified
  modifier onlyKeeper() {
    require(msg.sender == keeper, "Not Allow");
    _;
  }

  /* Views */
  function getValidators() public view returns (address[] memory, uint256[] memory) {
    uint256 size = validators.size();
    address[] memory _validators = new address[](size);
    uint256[] memory _powers = new uint256[](size);
    for (uint256 i = 0; i < size; i++) {
      _validators[i] = validators.at(i);
      _powers[i] = validatorPowers[_validators[i]];
    }
    return (_validators, _powers);
  }

  /* Admin */
  // verified
  function updateKeeper(address _account) public requireMultisig {
    keeper = _account;
  }

  // verified
  function updateConsensusPowerThreshold(uint256 _amount) public requireMultisig {
    consensusPowerThreshold = _amount;
  }

  // verified
  function updateValidatorsPowers(address[] memory _validators, uint256[] memory _powers) public requireMultisig {
    for (uint256 i = 0; i < _validators.length; i++) {
      require(validators.contains(_validators[i]), "Not validator");
      validatorPowers[_validators[i]] = _powers[i];
    }
  }

  // verified
  function addValidators(address[] memory _accounts) public requireMultisig {
    for (uint256 i = 0; i < _accounts.length; i++) {
      validators.add(_accounts[i]);
    }
  }

  // verified
  function removeValidators(address[] memory _accounts) public requireMultisig {
    for (uint256 i = 0; i < _accounts.length; i++) {
      validators.remove(_accounts[i]);
    }
  }

  // verified
  function updateTokensGateway(
    address[] memory _l1Tokens,
    address[] memory _l2Tokens,
    bool[] memory _status
  ) public requireMultisig {
    for (uint256 i = 0; i < _l1Tokens.length; i++) {
      tokensGateway[_l1Tokens[i]][_l2Tokens[i]] = _status[i];
    }
  }

  function adminWithdrawETHTo(address _to, uint256 _amount) public requireMultisig {
    require(_to != address(0), "Invalid address");
    (bool success, ) = _to.call{ value: _amount }("");
    require(success, "Transfer failed");
  }

  /* Execute */
  function withdrawETH() external payable {
    _initiateETHWithdraw(msg.sender, msg.sender, msg.value);
  }

  // verified
  function withdrawETHTo(address _to) external payable {
    _initiateETHWithdraw(msg.sender, _to, msg.value);
  }

  // verified
  function _initiateETHWithdraw(
    address _from,
    address _to,
    uint256 _amount
  ) internal {
    require(_amount > 0, "Not enough amount");
    require(_to != address(0), "Invalid address");
    require(tokensGateway[address(0)][address(0)], "Not supported");

    uint256 orderId = withdrawals.length;
    withdrawals.push();

    withdrawals[orderId].executed = true;
    withdrawals[orderId].from = _from;
    withdrawals[orderId].to = _to;
    withdrawals[orderId].amount = _amount;

    emit TokenWithdrawalQueued(orderId, address(0), address(0), _from, _to, _amount);
  }

  // verified
  function withdrawERC20(
    address _l1Token,
    address _l2Token,
    uint256 _amount
  ) external virtual {
    _initiateERC20Withdraw(_l1Token, _l2Token, msg.sender, msg.sender, _amount);
  }

  // verified
  function withdrawERC20To(
    address _l1Token,
    address _l2Token,
    address _to,
    uint256 _amount
  ) external virtual {
    _initiateERC20Withdraw(_l1Token, _l2Token, msg.sender, _to, _amount);
  }

  // verified
  function _initiateERC20Withdraw(
    address _l1Token,
    address _l2Token,
    address _from,
    address _to,
    uint256 _amount
  ) internal {
    require(_amount > 0, "Not enough amount");
    require(_to != address(0), "Invalid address");
    require(tokensGateway[_l1Token][_l2Token], "Not supported");

    IBridgedToken(_l2Token).burn(_from, _amount);

    uint256 orderId = withdrawals.length;
    withdrawals.push();

    withdrawals[orderId].executed = true;
    withdrawals[orderId].l1Token = _l1Token;
    withdrawals[orderId].l2Token = _l2Token;
    withdrawals[orderId].from = _from;
    withdrawals[orderId].to = _to;
    withdrawals[orderId].amount = _amount;

    emit TokenWithdrawalQueued(orderId, _l1Token, _l2Token, _from, _to, _amount);
  }

  function executeETHDeposit(
    address[] memory _currentValidators,
    bytes[] memory _signatures,
    // transaction data
    bytes32 _txnHash,
    uint256 _orderId,
    address _from,
    address _to,
    uint256 _amount
  ) public nonReentrant onlyKeeper {
    require(_to != address(0), "Invalid address");
    require(_amount > 0, "Not enough amount");
    require(tokensGateway[address(0)][address(0)], "Not supported");
    require(!deposits[_orderId].executed, "Order already executed");
    require(_currentValidators.length == _signatures.length, "Input mismatch");
    _checkValidatorSignatures(
      _orderId,
      _currentValidators,
      _signatures,
      // Get hash of the transaction batch and checkpoint
      keccak256(abi.encodePacked(_txnHash, _orderId, address(0), address(0), _from, _to, _amount)),
      consensusPowerThreshold
    );

    (bool success, ) = _to.call{ value: _amount }("");
    require(success, "ETH transfer failed");

    // store checkpoint
    deposits[_orderId].executed = true;
    deposits[_orderId].from = _from;
    deposits[_orderId].to = _to;
    deposits[_orderId].amount = _amount;

    emit TokenDepositCompleted(_orderId, address(0), address(0), _from, _to, _amount);
  }

  function executeERC20Deposit(
    address[] memory _currentValidators,
    bytes[] memory _signatures,
    // transaction data
    bytes32 _txnHash,
    uint256 _orderId,
    address _l1Token,
    address _l2Token,
    address _from,
    address _to,
    uint256 _amount
  ) public nonReentrant onlyKeeper {
    require(_to != address(0), "Invalid address");
    require(_amount > 0, "Not enough amount");
    require(tokensGateway[_l1Token][_l2Token], "Not supported");
    require(!deposits[_orderId].executed, "Order already executed");
    require(_currentValidators.length == _signatures.length, "Input mismatch");
    _checkValidatorSignatures(
      _orderId,
      _currentValidators,
      _signatures,
      // Get hash of the transaction batch and checkpoint
      keccak256(abi.encodePacked(_txnHash, _orderId, _l1Token, _l2Token, _from, _to, _amount)),
      consensusPowerThreshold
    );

    IBridgedToken(_l2Token).mint(_to, _amount);

    // store checkpoint
    deposits[_orderId].executed = true;
    deposits[_orderId].l1Token = _l1Token;
    deposits[_orderId].l2Token = _l2Token;
    deposits[_orderId].from = _from;
    deposits[_orderId].to = _to;
    deposits[_orderId].amount = _amount;

    emit TokenDepositCompleted(_orderId, _l1Token, _l2Token, _from, _to, _amount);
  }

  /* Internal */
  function _checkValidatorSignatures(
    uint256 _orderId,
    address[] memory _currentValidators,
    bytes[] memory _signatures,
    bytes32 _messageHash,
    uint256 _powerThreshold
  ) private {
    uint256 cumulativePower = 0;

    for (uint256 i = 0; i < _currentValidators.length; i++) {
      address signer = _messageHash.toEthSignedMessageHash().recover(_signatures[i]);
      require(signer == _currentValidators[i], "Validator signature does not match.");
      require(validators.contains(signer), "Invalid validator");
      require(!deposits[_orderId].isConfirmed[signer], "No duplicate validator");

      // prevent double-signing attacks
      deposits[_orderId].isConfirmed[signer] = true;

      // Sum up cumulative power
      cumulativePower += validatorPowers[signer];

      // Break early to avoid wasting gas
      if (cumulativePower >= _powerThreshold) {
        break;
      }
    }

    // Check that there was enough power
    require(cumulativePower >= _powerThreshold, "Submitted validator set signatures do not have enough power.");
    // Success
  }

  function _beforeAddTransaction(bytes calldata _data) internal pure override {
    bytes4 funcSelector = bytes4(_data[:4]);
    if (
      funcSelector == this.updateKeeper.selector || //
      funcSelector == this.updateConsensusPowerThreshold.selector ||
      funcSelector == this.addValidators.selector ||
      funcSelector == this.updateValidatorsPowers.selector ||
      funcSelector == this.removeValidators.selector ||
      funcSelector == this.updateTokensGateway.selector ||
      funcSelector == this.adminWithdrawETHTo.selector
    ) {
      return;
    }

    super._beforeAddTransaction(_data);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library MemberSet {
  struct Record {
    address[] values;
    mapping(address => uint256) indexes; // value to index
  }

  function add(Record storage _record, address _value) internal {
    if (contains(_record, _value)) return; // exist
    _record.values.push(_value);
    _record.indexes[_value] = _record.values.length;
  }

  function remove(Record storage _record, address _value) internal {
    uint256 valueIndex = _record.indexes[_value];
    if (valueIndex == 0) return; // removed non-exist value
    uint256 toDeleteIndex = valueIndex - 1; // dealing with out of bounds
    uint256 lastIndex = _record.values.length - 1;
    if (lastIndex != toDeleteIndex) {
      address lastvalue = _record.values[lastIndex];
      _record.values[toDeleteIndex] = lastvalue;
      _record.indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
    }
    _record.values.pop();
    _record.indexes[_value] = 0; // set to 0
  }

  function contains(Record storage _record, address _value) internal view returns (bool) {
    return _record.indexes[_value] != 0;
  }

  function size(Record storage _record) internal view returns (uint256) {
    return _record.values.length;
  }

  function at(Record storage _record, uint256 _index) internal view returns (address) {
    return _record.values[_index];
  }
}