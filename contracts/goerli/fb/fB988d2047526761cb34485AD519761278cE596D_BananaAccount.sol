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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable no-inline-assembly */

    /**
     * User Operation struct
     * @param sender the sender account of this request.
     * @param nonce unique value the sender uses to verify it is not a replay.
     * @param initCode if set, the account contract will be created by this constructor/
     * @param callData the method call to execute on this account.
     * @param callGasLimit the gas limit passed to the callData method call.
     * @param verificationGasLimit gas used for validateUserOp and validatePaymasterUserOp.
     * @param preVerificationGas gas not calculated by the handleOps method, but added to the gas paid. Covers batch overhead.
     * @param maxFeePerGas same as EIP-1559 gas parameter.
     * @param maxPriorityFeePerGas same as EIP-1559 gas parameter.
     * @param paymasterAndData if set, this field holds the paymaster address and paymaster-specific data. the paymaster will pay for the transaction instead of the sender.
     * @param signature sender-verified signature over the entire request, the EntryPoint address and the chain ID.
     */
    struct UserOperation {

        address sender;
        uint256 nonce;
        bytes initCode;
        bytes callData;
        uint256 callGasLimit;
        uint256 verificationGasLimit;
        uint256 preVerificationGas;
        uint256 maxFeePerGas;
        uint256 maxPriorityFeePerGas;
        bytes paymasterAndData;
        bytes signature;
    }

/**
 * Utility functions helpful when working with UserOperation structs.
 */
library UserOperationLib {

    function getSender(UserOperation calldata userOp) internal pure returns (address) {
        address data;
        //read sender from userOp, which is first userOp member (saves 800 gas...)
        assembly {data := calldataload(userOp)}
        return address(uint160(data));
    }

    //relayer/block builder might submit the TX with higher priorityFee, but the user should not
    // pay above what he signed for.
    function gasPrice(UserOperation calldata userOp) internal view returns (uint256) {
    unchecked {
        uint256 maxFeePerGas = userOp.maxFeePerGas;
        uint256 maxPriorityFeePerGas = userOp.maxPriorityFeePerGas;
        if (maxFeePerGas == maxPriorityFeePerGas) {
            //legacy mode (for networks that don't support basefee opcode)
            return maxFeePerGas;
        }
        return min(maxFeePerGas, maxPriorityFeePerGas + block.basefee);
    }
    }

    function pack(UserOperation calldata userOp) internal pure returns (bytes memory ret) {
        //lighter signature scheme. must match UserOp.ts#packUserOp
        bytes calldata sig = userOp.signature;
        // copy directly the userOp from calldata up to (but not including) the signature.
        // this encoding depends on the ABI encoding of calldata, but is much lighter to copy
        // than referencing each field separately.
        assembly {
            let ofs := userOp
            let len := sub(sub(sig.offset, ofs), 32)
            ret := mload(0x40)
            mstore(0x40, add(ret, add(len, 32)))
            mstore(ret, len)
            calldatacopy(add(ret, 32), ofs, len)
        }
    }

    function hash(UserOperation calldata userOp) internal pure returns (bytes32) {
        return keccak256(pack(userOp));
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/Enum.sol";

/**
 * @title Executor - A contract that can execute transactions
 * @author Richard Meissner - @rmeissner
 */
abstract contract Executor {
    /**
     * @notice Executes either a delegatecall or a call with provided parameters.
     * @param to Destination address.
     * @param value Ether value.
     * @param data Data payload.
     * @param operation Operation type.
     * @return success boolean flag indicating if the call succeeded.
     */
    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    ) internal returns (bool success) {
        if (operation == Enum.Operation.DelegateCall) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../common/SelfAuthorized.sol";

/**
 * @title Fallback Manager - A contract managing fallback calls made to this contract
 * @author Richard Meissner - @rmeissner
 */
abstract contract FallbackManager is SelfAuthorized {
    event ChangedFallbackHandler(address handler);

    // keccak256("fallback_manager.handler.address")
    bytes32 internal constant FALLBACK_HANDLER_STORAGE_SLOT = 0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5;

    /**
     *  @notice Internal function to set the fallback handler.
     *  @param handler contract to handle fallback calls.
     */
    function internalSetFallbackHandler(address handler) internal {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, handler)
        }
    }

    /**
     * @notice Set Fallback Handler to `handler` for the Safe.
     * @dev Only fallback calls without value and with data will be forwarded.
     *      This can only be done via a Safe transaction.
     * @param handler contract to handle fallback calls.
     */
    function setFallbackHandler(address handler) public authorized {
        internalSetFallbackHandler(handler);
        emit ChangedFallbackHandler(handler);
    }

    // @notice Forwards all calls to the fallback handler if set. Returns 0 if no handler is set.
    // @dev Appends the non-padded caller address to the calldata to be optionally used in the handler
    //      The handler can make us of `HandlerContext.sol` to extract the address.
    //      This is done because in the next call frame the `msg.sender` will be FallbackManager's address
    //      and having the original caller address may enable additional verification scenarios.
    // solhint-disable-next-line payable-fallback,no-complex-fallback
    fallback() external {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let handler := sload(slot)
            if iszero(handler) {
                return(0, 0)
            }
            calldatacopy(0, 0, calldatasize())
            // The msg.sender address is shifted to the left by 12 bytes to remove the padding
            // Then the address without padding is stored right after the calldata
            mstore(calldatasize(), shl(96, caller()))
            // Add 20 bytes for the address appended add the end
            let success := call(gas(), handler, 0, 0, add(calldatasize(), 20), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if iszero(success) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "../interfaces/IERC165.sol";

interface Guard is IERC165 {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

abstract contract BaseGuard is Guard {
    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(Guard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }
}

/**
 * @title Guard Manager - A contract managing transaction guards which perform pre and post-checks on Safe transactions.
 * @author Richard Meissner - @rmeissner
 */
abstract contract GuardManager is SelfAuthorized {
    event ChangedGuard(address guard);

    // keccak256("guard_manager.guard.address")
    bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    /**
     * @dev Set a guard that checks transactions before execution
     *      This can only be done via a Safe transaction.
     * @notice Set Transaction Guard `guard` for the Safe.
     * @param guard The address of the guard to be used or the 0 address to disable the guard
     */
    function setGuard(address guard) external authorized {
        if (guard != address(0)) {
            require(Guard(guard).supportsInterface(type(Guard).interfaceId), "GS300");
        }
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, guard)
        }
        emit ChangedGuard(guard);
    }

    /**
     * @dev Internal method to retrieve the current guard
     *      We do not have a public method because we're short on bytecode size limit,
     *      to retrieve the guard address, one can use `getStorageAt` from `StorageAccessible` contract
     *      with the slot `GUARD_STORAGE_SLOT`
     * @return guard The address of the guard
     */
    function getGuard() internal view returns (address guard) {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            guard := sload(slot)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "./Executor.sol";

/**
 * @title Module Manager - A contract managing Safe modules
 * @notice Modules are pluggable extensions to the Safe that can be added to the Safe by the owner.
           Modules are a security risk since they can execute arbitrary transactions, so only trusted
           and audited modules should be added to the Safe. 
 * @author Stefan George - @Georgi87
 * @author Richard Meissner - @rmeissner
 */
abstract contract ModuleManager is SelfAuthorized, Executor {
    event EnabledModule(address module);
    event DisabledModule(address module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);

    address internal constant SENTINEL_MODULES = address(0x1);

    mapping(address => address) internal modules;

    /**
     * @notice Setup function sets the initial storage of the contract.
     *         Optionally executes a delegate call to another contract to setup the modules.
     * @param to Optional destination address of call to execute.
     * @param data Optional data of call to execute.
     */
    function setupModules(address to, bytes memory data) internal {
        require(modules[SENTINEL_MODULES] == address(0), "GS100");
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
        if (to != address(0)) {
            require(isContract(to), "GS002");
            // Setup has to complete successfully or transaction fails.
            require(execute(to, 0, data, Enum.Operation.DelegateCall, gasleft()), "GS000");
        }
    }

    /**
     * @notice Enables the module `module` for the Safe.
     * @dev This can only be done via a Safe transaction.
     * @param module Module to be whitelisted.
     */
    function enableModule(address module) public authorized {
        // Module address cannot be null or sentinel.
        require(module != address(0) && module != SENTINEL_MODULES, "GS101");
        // Module cannot be added twice.
        require(modules[module] == address(0), "GS102");
        modules[module] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = module;
        emit EnabledModule(module);
    }

    /**
     * @notice Disables the module `module` for the Safe.
     * @dev This can only be done via a Safe transaction.
     * @param prevModule Previous module in the modules linked list.
     * @param module Module to be removed.
     */
    function disableModule(address prevModule, address module) public authorized {
        // Validate module address and check that it corresponds to module index.
        require(module != address(0) && module != SENTINEL_MODULES, "GS101");
        require(modules[prevModule] == module, "GS103");
        modules[prevModule] = modules[module];
        modules[module] = address(0);
        emit DisabledModule(module);
    }

    /**
     * @notice Execute `operation` (0: Call, 1: DelegateCall) to `to` with `value` (Native Token)
     * @dev Function is virtual to allow overriding for L2 singleton to emit an event for indexing.
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operation Operation type of module transaction.
     * @return success Boolean flag indicating if the call succeeded.
     */
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public virtual returns (bool success) {
        // Only whitelisted modules are allowed.
        require(msg.sender != SENTINEL_MODULES && modules[msg.sender] != address(0), "GS104");
        // Execute transaction without further confirmations.
        success = execute(to, value, data, operation, type(uint256).max);
        if (success) emit ExecutionFromModuleSuccess(msg.sender);
        else emit ExecutionFromModuleFailure(msg.sender);
    }

    /**
     * @notice Execute `operation` (0: Call, 1: DelegateCall) to `to` with `value` (Native Token) and return data
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operation Operation type of module transaction.
     * @return success Boolean flag indicating if the call succeeded.
     * @return returnData Data returned by the call.
     */
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public returns (bool success, bytes memory returnData) {
        success = execTransactionFromModule(to, value, data, operation);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Load free memory location
            let ptr := mload(0x40)
            // We allocate memory for the return data by setting the free memory location to
            // current free memory location + data size + 32 bytes for data size value
            mstore(0x40, add(ptr, add(returndatasize(), 0x20)))
            // Store the size
            mstore(ptr, returndatasize())
            // Store the data
            returndatacopy(add(ptr, 0x20), 0, returndatasize())
            // Point the return data to the correct memory location
            returnData := ptr
        }
    }

    /**
     * @notice Returns if an module is enabled
     * @return True if the module is enabled
     */
    function isModuleEnabled(address module) public view returns (bool) {
        return SENTINEL_MODULES != module && modules[module] != address(0);
    }

    /**
     * @notice Returns an array of modules.
     *         If all entries fit into a single page, the next pointer will be 0x1.
     *         If another page is present, next will be the last element of the returned array.
     * @param start Start of the page. Has to be a module or start pointer (0x1 address)
     * @param pageSize Maximum number of modules that should be returned. Has to be > 0
     * @return array Array of modules.
     * @return next Start of the next page.
     */
    function getModulesPaginated(address start, uint256 pageSize) external view returns (address[] memory array, address next) {
        require(start == SENTINEL_MODULES || isModuleEnabled(start), "GS105");
        require(pageSize > 0, "GS106");
        // Init array with max page size
        array = new address[](pageSize);

        // Populate return array
        uint256 moduleCount = 0;
        next = modules[start];
        while (next != address(0) && next != SENTINEL_MODULES && moduleCount < pageSize) {
            array[moduleCount] = next;
            next = modules[next];
            moduleCount++;
        }

        /**
          Because of the argument validation we can assume that
          the `currentModule` will always be either a module address
          or sentinel address (aka the end). If we haven't reached the end
          inside the loop, we need to set the next pointer to the last element
          because it skipped over to the next module which is neither included
          in the current page nor won't be included in the next one
          if you pass it as a start. 
        */
        if (next != SENTINEL_MODULES) {
            next = array[moduleCount - 1];
        }
        // Set correct size of returned array
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(array, moduleCount)
        }
    }

    /**
     * @notice Returns true if `account` is a contract.
     * @dev This function will return false if invoked during the constructor of a contract,
     *      as the code is not actually created until after the constructor finishes.
     * @param account The address being queried
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/SelfAuthorized.sol";

/**
 * @title OwnerManager - Manages Safe owners and a threshold to authorize transactions.
 * @dev Uses a linked list to store the owners because the code generate by the solidity compiler
 *      is more efficient than using a dynamic array.
 * @author Stefan George - @Georgi87
 * @author Richard Meissner - @rmeissner
 */
abstract contract OwnerManager is SelfAuthorized {
    event AddedOwner(address owner);
    event RemovedOwner(address owner);
    event ChangedThreshold(uint256 threshold);

    address internal constant SENTINEL_OWNERS = address(0x1);

    mapping(address => address) internal owners;
    uint256 internal ownerCount;
    uint256 internal threshold;

    /**
     * @notice Sets the initial storage of the contract.
     * @param _owners List of Safe owners.
     * @param _threshold Number of required confirmations for a Safe transaction.
     */
    function setupOwners(address[] memory _owners, uint256 _threshold) internal {
        // Threshold can only be 0 at initialization.
        // Check ensures that setup function can only be called once.
        require(threshold == 0, "GS200");
        // Validate that threshold is smaller than number of added owners.
        require(_threshold <= _owners.length, "GS201");
        // There has to be at least one Safe owner.
        require(_threshold >= 1, "GS202");
        // Initializing Safe owners.
        address currentOwner = SENTINEL_OWNERS;
        for (uint256 i = 0; i < _owners.length; i++) {
            // Owner address cannot be null.
            address owner = _owners[i];
            require(owner != address(0) && owner != SENTINEL_OWNERS && owner != address(this) && currentOwner != owner, "GS203");
            // No duplicate owners allowed.
            require(owners[owner] == address(0), "GS204");
            owners[currentOwner] = owner;
            currentOwner = owner;
        }
        owners[currentOwner] = SENTINEL_OWNERS;
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    /**
     * @notice Adds the owner `owner` to the Safe and updates the threshold to `_threshold`.
     * @dev This can only be done via a Safe transaction.
     * @param owner New owner address.
     * @param _threshold New threshold.
     */
    function addOwnerWithThreshold(address owner, uint256 _threshold) public authorized {
        // Owner address cannot be null, the sentinel or the Safe itself.
        require(owner != address(0) && owner != SENTINEL_OWNERS && owner != address(this), "GS203");
        // No duplicate owners allowed.
        require(owners[owner] == address(0), "GS204");
        owners[owner] = owners[SENTINEL_OWNERS];
        owners[SENTINEL_OWNERS] = owner;
        ownerCount++;
        emit AddedOwner(owner);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) changeThreshold(_threshold);
    }

    /**
     * @notice Removes the owner `owner` from the Safe and updates the threshold to `_threshold`.
     * @dev This can only be done via a Safe transaction.
     * @param prevOwner Owner that pointed to the owner to be removed in the linked list
     * @param owner Owner address to be removed.
     * @param _threshold New threshold.
     */
    function removeOwner(address prevOwner, address owner, uint256 _threshold) public authorized {
        // Only allow to remove an owner, if threshold can still be reached.
        require(ownerCount - 1 >= _threshold, "GS201");
        // Validate owner address and check that it corresponds to owner index.
        require(owner != address(0) && owner != SENTINEL_OWNERS, "GS203");
        require(owners[prevOwner] == owner, "GS205");
        owners[prevOwner] = owners[owner];
        owners[owner] = address(0);
        ownerCount--;
        emit RemovedOwner(owner);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) changeThreshold(_threshold);
    }

    /**
     * @notice Replaces the owner `oldOwner` in the Safe with `newOwner`.
     * @dev This can only be done via a Safe transaction.
     * @param prevOwner Owner that pointed to the owner to be replaced in the linked list
     * @param oldOwner Owner address to be replaced.
     * @param newOwner New owner address.
     */
    function swapOwner(address prevOwner, address oldOwner, address newOwner) public authorized {
        // Owner address cannot be null, the sentinel or the Safe itself.
        require(newOwner != address(0) && newOwner != SENTINEL_OWNERS && newOwner != address(this), "GS203");
        // No duplicate owners allowed.
        require(owners[newOwner] == address(0), "GS204");
        // Validate oldOwner address and check that it corresponds to owner index.
        require(oldOwner != address(0) && oldOwner != SENTINEL_OWNERS, "GS203");
        require(owners[prevOwner] == oldOwner, "GS205");
        owners[newOwner] = owners[oldOwner];
        owners[prevOwner] = newOwner;
        owners[oldOwner] = address(0);
        emit RemovedOwner(oldOwner);
        emit AddedOwner(newOwner);
    }

    /**
     * @notice Changes the threshold of the Safe to `_threshold`.
     * @dev This can only be done via a Safe transaction.
     * @param _threshold New threshold.
     */
    function changeThreshold(uint256 _threshold) public authorized {
        // Validate that threshold is smaller than number of owners.
        require(_threshold <= ownerCount, "GS201");
        // There has to be at least one Safe owner.
        require(_threshold >= 1, "GS202");
        threshold = _threshold;
        emit ChangedThreshold(threshold);
    }

    /**
     * @notice Returns the number of required confirmations for a Safe transaction aka the threshold.
     * @return Threshold number.
     */
    function getThreshold() public view returns (uint256) {
        return threshold;
    }

    /**
     * @notice Returns if `owner` is an owner of the Safe.
     * @return Boolean if owner is an owner of the Safe.
     */
    function isOwner(address owner) public view returns (bool) {
        return owner != SENTINEL_OWNERS && owners[owner] != address(0);
    }

    /**
     * @notice Returns a list of Safe owners.
     * @return Array of Safe owners.
     */
    function getOwners() public view returns (address[] memory) {
        address[] memory array = new address[](ownerCount);

        // populate return array
        uint256 index = 0;
        address currentOwner = owners[SENTINEL_OWNERS];
        while (currentOwner != SENTINEL_OWNERS) {
            array[index] = currentOwner;
            currentOwner = owners[currentOwner];
            index++;
        }
        return array;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Enum - Collection of enums used in Safe contracts.
 * @author Richard Meissner - @rmeissner
 */
abstract contract Enum {
    enum Operation {
        Call,
        DelegateCall
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title NativeCurrencyPaymentFallback - A contract that has a fallback to accept native currency payments.
 * @author Richard Meissner - @rmeissner
 */
abstract contract NativeCurrencyPaymentFallback {
    event SafeReceived(address indexed sender, uint256 value);

    /**
     * @notice Receive function accepts native currency transactions.
     * @dev Emits an event with sender and received value.
     */
    receive() external payable {
        emit SafeReceived(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SecuredTokenTransfer - Secure token transfer.
 * @author Richard Meissner - @rmeissner
 */
abstract contract SecuredTokenTransfer {
    /**
     * @notice Transfers a token and returns a boolean if it was a success
     * @dev It checks the return data of the transfer call and returns true if the transfer was successful.
     * @param token Token that should be transferred
     * @param receiver Receiver to whom the token should be transferred
     * @param amount The amount of tokens that should be transferred
     * @return transferred Returns true if the transfer was successful
     */
    function transferToken(address token, address receiver, uint256 amount) internal returns (bool transferred) {
        // 0xa9059cbb - keccack("transfer(address,uint256)")
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, receiver, amount);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // We write the return value to scratch space.
            // See https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html#layout-in-memory
            let success := call(sub(gas(), 10000), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            switch returndatasize()
            case 0 {
                transferred := success
            }
            case 0x20 {
                transferred := iszero(or(iszero(success), iszero(mload(0))))
            }
            default {
                transferred := 0
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SelfAuthorized - Authorizes current contract to perform actions to itself.
 * @author Richard Meissner - @rmeissner
 */
abstract contract SelfAuthorized {
    function requireSelfCall() private view {
        require(msg.sender == address(this), "GS031");
    }

    modifier authorized() {
        // Modifiers are copied around during compilation. This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SignatureDecoder - Decodes signatures encoded as bytes
 * @author Richard Meissner - @rmeissner
 */
abstract contract SignatureDecoder {
    /**
     * @notice Splits signature bytes into `uint8 v, bytes32 r, bytes32 s`.
     * @dev Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures
     *      The signature format is a compact form of {bytes32 r}{bytes32 s}{uint8 v}
     *      Compact means uint8 is not padded to 32 bytes.
     * @param pos Which signature to read.
     *            A prior bounds check of this parameter should be performed, to avoid out of bounds access.
     * @param signatures Concatenated {r, s, v} signatures.
     * @return v Recovery ID or Safe signature type.
     * @return r Output value r of the signature.
     * @return s Output value s of the signature.
     */
    function signatureSplit(bytes memory signatures, uint256 pos) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            /**
             * Here we are loading the last 32 bytes, including 31 bytes
             * of 's'. There is no 'mload8' to do this.
             * 'byte' is not working due to the Solidity parser, so lets
             * use the second best option, 'and'
             */
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Singleton - Base for singleton contracts (should always be the first super contract)
 *        This contract is tightly coupled to our proxy contract (see `proxies/SafeProxy.sol`)
 * @author Richard Meissner - @rmeissner
 */
abstract contract Singleton {
    // singleton always has to be the first declared variable to ensure the same location as in the Proxy contract.
    // It should also always be ensured the address is stored alone (uses a full word)
    address private singleton;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title StorageAccessible - A generic base contract that allows callers to access all internal storage.
 * @notice See https://github.com/gnosis/util-contracts/blob/bb5fe5fb5df6d8400998094fb1b32a178a47c3a1/contracts/StorageAccessible.sol
 *         It removes a method from the original contract not needed for the Safe contracts.
 * @author Gnosis Developers
 */
abstract contract StorageAccessible {
    /**
     * @notice Reads `length` bytes of storage in the currents contract
     * @param offset - the offset in the current contract's storage in words to start reading from
     * @param length - the number of words (32 bytes) of data to read
     * @return the bytes that were read.
     */
    function getStorageAt(uint256 offset, uint256 length) public view returns (bytes memory) {
        bytes memory result = new bytes(length * 32);
        for (uint256 index = 0; index < length; index++) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let word := sload(add(offset, index))
                mstore(add(add(result, 0x20), mul(index, 0x20)), word)
            }
        }
        return result;
    }

    /**
     * @dev Performs a delegatecall on a targetContract in the context of self.
     * Internally reverts execution to avoid side effects (making it static).
     *
     * This method reverts with data equal to `abi.encode(bool(success), bytes(response))`.
     * Specifically, the `returndata` after a call to this method will be:
     * `success:bool || response.length:uint256 || response:bytes`.
     *
     * @param targetContract Address of the contract containing the code to execute.
     * @param calldataPayload Calldata that should be sent to the target contract (encoded method name and arguments).
     */
    function simulateAndRevert(address targetContract, bytes memory calldataPayload) external {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let success := delegatecall(gas(), targetContract, add(calldataPayload, 0x20), mload(calldataPayload), 0, 0)

            mstore(0x00, success)
            mstore(0x20, returndatasize())
            returndatacopy(0x40, 0, returndatasize())
            revert(0, add(returndatasize(), 0x40))
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title SafeMath
 * @notice Math operations with safety checks that revert on error (overflow/underflow)
 */
library SafeMath {
    /**
     * @notice Multiplies two numbers, reverts on overflow.
     * @param a First number
     * @param b Second number
     * @return Product of a and b
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @notice Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     * @param a First number
     * @param b Second number
     * @return Difference of a and b
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @notice Adds two numbers, reverts on overflow.
     * @param a First number
     * @param b Second number
     * @return Sum of a and b
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @notice Returns the largest of two numbers.
     * @param a First number
     * @param b Second number
     * @return Largest of a and b
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @notice More details at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by `interfaceId`.
     * See the corresponding EIP section
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

contract ISignatureValidatorConstants {
    // bytes4(keccak256("isValidSignature(bytes,bytes)")
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x20c13b0b;
}

abstract contract ISignatureValidator is ISignatureValidatorConstants {
    /**
     * @notice Legacy EIP1271 method to validate a signature.
     * @param _data Arbitrary length data signed on the behalf of address(this).
     * @param _signature Signature byte array associated with _data.
     *
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes memory _data, bytes memory _signature) public view virtual returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./base/ModuleManager.sol";
import "./base/OwnerManager.sol";
import "./base/FallbackManager.sol";
import "./base/GuardManager.sol";
import "./common/NativeCurrencyPaymentFallback.sol";
import "./common/Singleton.sol";
import "./common/SignatureDecoder.sol";
import "./common/SecuredTokenTransfer.sol";
import "./common/StorageAccessible.sol";
import "./interfaces/ISignatureValidator.sol";
import "./external/SafeMath.sol";

/**
 * @title Safe - A multisignature wallet with support for confirmations using signed messages based on EIP-712.
 * @dev Most important concepts:
 *      - Threshold: Number of required confirmations for a Safe transaction.
 *      - Owners: List of addresses that control the Safe. They are the only ones that can add/remove owners, change the threshold and
 *        approve transactions. Managed in `OwnerManager`.
 *      - Transaction Hash: Hash of a transaction is calculated using the EIP-712 typed structured data hashing scheme.
 *      - Nonce: Each transaction should have a different nonce to prevent replay attacks.
 *      - Signature: A valid signature of an owner of the Safe for a transaction hash.
 *      - Guard: Guard is a contract that can execute pre- and post- transaction checks. Managed in `GuardManager`.
 *      - Modules: Modules are contracts that can be used to extend the write functionality of a Safe. Managed in `ModuleManager`.
 *      - Fallback: Fallback handler is a contract that can provide additional read-only functional for Safe. Managed in `FallbackManager`.
 *      Note: This version of the implementation contract doesn't emit events for the sake of gas efficiency and therefore requires a tracing node for indexing/
 *      For the events-based implementation see `SafeL2.sol`.
 * @author Stefan George - @Georgi87
 * @author Richard Meissner - @rmeissner
 */
contract Safe is
    Singleton,
    NativeCurrencyPaymentFallback,
    ModuleManager,
    OwnerManager,
    SignatureDecoder,
    SecuredTokenTransfer,
    ISignatureValidatorConstants,
    FallbackManager,
    StorageAccessible,
    GuardManager
{
    using SafeMath for uint256;

    string public constant VERSION = "1.4.0";

    // keccak256(
    //     "EIP712Domain(uint256 chainId,address verifyingContract)"
    // );
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

    // keccak256(
    //     "SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
    // );
    bytes32 private constant SAFE_TX_TYPEHASH = 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;

    event SafeSetup(address indexed initiator, address[] owners, uint256 threshold, address initializer, address fallbackHandler);
    event ApproveHash(bytes32 indexed approvedHash, address indexed owner);
    event SignMsg(bytes32 indexed msgHash);
    event ExecutionFailure(bytes32 txHash, uint256 payment);
    event ExecutionSuccess(bytes32 txHash, uint256 payment);

    uint256 public nonce;
    bytes32 private _deprecatedDomainSeparator;
    // Mapping to keep track of all message hashes that have been approved by ALL REQUIRED owners
    mapping(bytes32 => uint256) public signedMessages;
    // Mapping to keep track of all hashes (message or transaction) that have been approved by ANY owners
    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;

    // This constructor ensures that this contract can only be used as a singleton for Proxy contracts
    constructor() {
        /**
         * By setting the threshold it is not possible to call setup anymore,
         * so we create a Safe with 0 owners and threshold 1.
         * This is an unusable Safe, perfect for the singleton
         */
        threshold = 1;
    }

    /**
     * @notice Sets an initial storage of the Safe contract.
     * @dev This method can only be called once.
     *      If a proxy was created without setting up, anyone can call setup and claim the proxy.
     * @param _owners List of Safe owners.
     * @param _threshold Number of required confirmations for a Safe transaction.
     * @param to Contract address for optional delegate call.
     * @param data Data payload for optional delegate call.
     * @param fallbackHandler Handler for fallback calls to this contract
     * @param paymentToken Token that should be used for the payment (0 is ETH)
     * @param payment Value that should be paid
     * @param paymentReceiver Address that should receive the payment (or 0 if tx.origin)
     */
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external {
        // setupOwners checks if the Threshold is already set, therefore preventing that this method is called twice
        setupOwners(_owners, _threshold);
        if (fallbackHandler != address(0)) internalSetFallbackHandler(fallbackHandler);
        // As setupOwners can only be called if the contract has not been initialized we don't need a check for setupModules
        setupModules(to, data);

        if (payment > 0) {
            // To avoid running into issues with EIP-170 we reuse the handlePayment function (to avoid adjusting code of that has been verified we do not adjust the method itself)
            // baseGas = 0, gasPrice = 1 and gas = payment => amount = (payment + 0) * 1 = payment
            handlePayment(payment, 0, 1, paymentToken, paymentReceiver);
        }
        emit SafeSetup(msg.sender, _owners, _threshold, to, fallbackHandler);
    }

    /** @notice Executes a `operation` {0: Call, 1: DelegateCall}} transaction to `to` with `value` (Native Currency)
     *          and pays `gasPrice` * `gasLimit` in `gasToken` token to `refundReceiver`.
     * @dev The fees are always transferred, even if the user transaction fails.
     * @param to Destination address of Safe transaction.
     * @param value Ether value of Safe transaction.
     * @param data Data payload of Safe transaction.
     * @param operation Operation type of Safe transaction.
     * @param safeTxGas Gas that should be used for the Safe transaction.
     * @param baseGas Gas costs that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
     * @param gasPrice Gas price that should be used for the payment calculation.
     * @param gasToken Token address (or 0 if ETH) that is used for the payment.
     * @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
     * @param signatures Signature data that should be verified.
     *                   Can be packed ECDSA signature ({bytes32 r}{bytes32 s}{uint8 v}), contract signature (EIP-1271) or approved hash.
     * @return success Boolean indicating transaction's success.
     */
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) public payable virtual returns (bool success) {
        bytes32 txHash;
        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {
            bytes memory txHashData = encodeTransactionData(
                // Transaction info
                to,
                value,
                data,
                operation,
                safeTxGas,
                // Payment info
                baseGas,
                gasPrice,
                gasToken,
                refundReceiver,
                // Signature info
                nonce
            );
            // Increase nonce and execute transaction.
            nonce++;
            txHash = keccak256(txHashData);
            checkSignatures(txHash, txHashData, signatures);
        }
        address guard = getGuard();
        {
            if (guard != address(0)) {
                Guard(guard).checkTransaction(
                    // Transaction info
                    to,
                    value,
                    data,
                    operation,
                    safeTxGas,
                    // Payment info
                    baseGas,
                    gasPrice,
                    gasToken,
                    refundReceiver,
                    // Signature info
                    signatures,
                    msg.sender
                );
            }
        }
        // We require some gas to emit the events (at least 2500) after the execution and some to perform code until the execution (500)
        // We also include the 1/64 in the check that is not send along with a call to counteract potential shortings because of EIP-150
        require(gasleft() >= ((safeTxGas * 64) / 63).max(safeTxGas + 2500) + 500, "GS010");
        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {
            uint256 gasUsed = gasleft();
            // If the gasPrice is 0 we assume that nearly all available gas can be used (it is always more than safeTxGas)
            // We only substract 2500 (compared to the 3000 before) to ensure that the amount passed is still higher than safeTxGas
            success = execute(to, value, data, operation, gasPrice == 0 ? (gasleft() - 2500) : safeTxGas);
            gasUsed = gasUsed.sub(gasleft());
            // If no safeTxGas and no gasPrice was set (e.g. both are 0), then the internal tx is required to be successful
            // This makes it possible to use `estimateGas` without issues, as it searches for the minimum gas where the tx doesn't revert
            require(success || safeTxGas != 0 || gasPrice != 0, "GS013");
            // We transfer the calculated tx costs to the tx.origin to avoid sending it to intermediate contracts that have made calls
            uint256 payment = 0;
            if (gasPrice > 0) {
                payment = handlePayment(gasUsed, baseGas, gasPrice, gasToken, refundReceiver);
            }
            if (success) emit ExecutionSuccess(txHash, payment);
            else emit ExecutionFailure(txHash, payment);
        }
        {
            if (guard != address(0)) {
                Guard(guard).checkAfterExecution(txHash, success);
            }
        }
    }

    /**
     * @notice Handles the payment for a Safe transaction.
     * @param gasUsed Gas used by the Safe transaction.
     * @param baseGas Gas costs that are independent of the transaction execution (e.g. base transaction fee, signature check, payment of the refund).
     * @param gasPrice Gas price that should be used for the payment calculation.
     * @param gasToken Token address (or 0 if ETH) that is used for the payment.
     * @return payment The amount of payment made in the specified token.
     */
    function handlePayment(
        uint256 gasUsed,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver
    ) private returns (uint256 payment) {
        // solhint-disable-next-line avoid-tx-origin
        address payable receiver = refundReceiver == address(0) ? payable(tx.origin) : refundReceiver;
        if (gasToken == address(0)) {
            // For ETH we will only adjust the gas price to not be higher than the actual used gas price
            payment = gasUsed.add(baseGas).mul(gasPrice < tx.gasprice ? gasPrice : tx.gasprice);
            require(receiver.send(payment), "GS011");
        } else {
            payment = gasUsed.add(baseGas).mul(gasPrice);
            require(transferToken(gasToken, receiver, payment), "GS012");
        }
    }

    /**
     * @notice Checks whether the signature provided is valid for the provided data and hash. Reverts otherwise.
     * @param dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param data That should be signed (this is passed to an external validator contract)
     * @param signatures Signature data that should be verified.
     *                   Can be packed ECDSA signature ({bytes32 r}{bytes32 s}{uint8 v}), contract signature (EIP-1271) or approved hash.
     */
    function checkSignatures(bytes32 dataHash, bytes memory data, bytes memory signatures) public view {
        // Load threshold to avoid multiple storage loads
        uint256 _threshold = threshold;
        // Check that a threshold is set
        require(_threshold > 0, "GS001");
        checkNSignatures(dataHash, data, signatures, _threshold);
    }

    /**
     * @notice Checks whether the signature provided is valid for the provided data and hash. Reverts otherwise.
     * @dev Since the EIP-1271 does an external call, be mindful of reentrancy attacks.
     * @param dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param data That should be signed (this is passed to an external validator contract)
     * @param signatures Signature data that should be verified.
     *                   Can be packed ECDSA signature ({bytes32 r}{bytes32 s}{uint8 v}), contract signature (EIP-1271) or approved hash.
     * @param requiredSignatures Amount of required valid signatures.
     */
    function checkNSignatures(bytes32 dataHash, bytes memory data, bytes memory signatures, uint256 requiredSignatures) public view {
        // Check that the provided signature data is not too short
        require(signatures.length >= requiredSignatures.mul(65), "GS020");
        // There cannot be an owner with address 0.
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < requiredSignatures; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            if (v == 0) {
                require(keccak256(data) == dataHash, "GS027");
                // If v is 0 then it is a contract signature
                // When handling contract signatures the address of the contract is encoded into r
                currentOwner = address(uint160(uint256(r)));

                // Check that signature data pointer (s) is not pointing inside the static part of the signatures bytes
                // This check is not completely accurate, since it is possible that more signatures than the threshold are send.
                // Here we only check that the pointer is not pointing inside the part that is being processed
                require(uint256(s) >= requiredSignatures.mul(65), "GS021");

                // Check that signature data pointer (s) is in bounds (points to the length of data -> 32 bytes)
                require(uint256(s).add(32) <= signatures.length, "GS022");

                // Check if the contract signature is in bounds: start of data is s + 32 and end is start + signature length
                uint256 contractSignatureLen;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    contractSignatureLen := mload(add(add(signatures, s), 0x20))
                }
                require(uint256(s).add(32).add(contractSignatureLen) <= signatures.length, "GS023");

                // Check signature
                bytes memory contractSignature;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    // The signature data for contract signatures is appended to the concatenated signatures and the offset is stored in s
                    contractSignature := add(add(signatures, s), 0x20)
                }
                require(ISignatureValidator(currentOwner).isValidSignature(data, contractSignature) == EIP1271_MAGIC_VALUE, "GS024");
            } else if (v == 1) {
                // If v is 1 then it is an approved hash
                // When handling approved hashes the address of the approver is encoded into r
                currentOwner = address(uint160(uint256(r)));
                // Hashes are automatically approved by the sender of the message or when they have been pre-approved via a separate transaction
                require(msg.sender == currentOwner || approvedHashes[currentOwner][dataHash] != 0, "GS025");
            } else if (v > 30) {
                // If v > 30 then default va (27,28) has been adjusted for eth_sign flow
                // To support eth_sign and similar we adjust v and hash the messageHash with the Ethereum message prefix before applying ecrecover
                currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
            } else {
                // Default is the ecrecover flow with the provided data hash
                // Use ecrecover with the messageHash for EOA signatures
                currentOwner = ecrecover(dataHash, v, r, s);
            }
            require(currentOwner > lastOwner && owners[currentOwner] != address(0) && currentOwner != SENTINEL_OWNERS, "GS026");
            lastOwner = currentOwner;
        }
    }

    /**
     * @notice Marks hash `hashToApprove` as approved.
     * @dev This can be used with a pre-approved hash transaction signature.
     * @param hashToApprove The hash to mark as approved for signatures that are verified by this contract.
     */
    function approveHash(bytes32 hashToApprove) external {
        require(owners[msg.sender] != address(0), "GS030");
        approvedHashes[msg.sender][hashToApprove] = 1;
        emit ApproveHash(hashToApprove, msg.sender);
    }

    /**
     * @notice Returns the ID of the chain the contract is currently deployed on.
     * @return The ID of the current chain as a uint256.
     */
    function getChainId() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * @dev Returns the domain separator for this contract, as defined in the EIP-712 standard.
     * @return bytes32 The domain separator hash.
     */
    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), this));
    }

    /**
     * @notice Returns the pre-image of the transaction hash (see getTransactionHash).
     * @param to Destination address.
     * @param value Ether value.
     * @param data Data payload.
     * @param operation Operation type.
     * @param safeTxGas Gas that should be used for the safe transaction.
     * @param baseGas Gas costs for that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
     * @param gasPrice Maximum gas price that should be used for this transaction.
     * @param gasToken Token address (or 0 if ETH) that is used for the payment.
     * @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
     * @param _nonce Transaction nonce.
     * @return Transaction hash bytes.
     */
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) public view returns (bytes memory) {
        bytes32 safeTxHash = keccak256(
            abi.encode(
                SAFE_TX_TYPEHASH,
                to,
                value,
                keccak256(data),
                operation,
                safeTxGas,
                baseGas,
                gasPrice,
                gasToken,
                refundReceiver,
                _nonce
            )
        );
        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), safeTxHash);
    }

    /**
     * @notice Returns transaction hash to be signed by owners.
     * @param to Destination address.
     * @param value Ether value.
     * @param data Data payload.
     * @param operation Operation type.
     * @param safeTxGas Fas that should be used for the safe transaction.
     * @param baseGas Gas costs for data used to trigger the safe transaction.
     * @param gasPrice Maximum gas price that should be used for this transaction.
     * @param gasToken Token address (or 0 if ETH) that is used for the payment.
     * @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
     * @param _nonce Transaction nonce.
     * @return Transaction hash.
     */
    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) public view returns (bytes32) {
        return keccak256(encodeTransactionData(to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, _nonce));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


import "../safe-contracts/Safe.sol";
import "../interfaces/UserOperation.sol";
import "./EllipticCurve.sol";
import "../utils/Exec.sol";
import './Base64.sol';

contract BananaAccount is Safe {
    using ECDSA for bytes32;

    //return value in case of signature failure, with no time-range.
    uint256 constant internal SIG_VALIDATION_FAILED = 1;

    //elliptic curve used for the signature verification
    address ellipticCurve;

    //EIP4337 trusted entrypoint
    address public entryPoint;

    //q values for the elliptic curve representing the public key of the user
    uint256[2] qValues;

    //mapping of used messages to prevent replay attacks
    mapping(bytes32 => bool) public usedMessages;
    
    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    /// @param to Contract address for optional delegate call.
    /// @param data Data payload for optional delegate call.
    /// @param fallbackHandler Handler for fallback calls to this contract
    /// @param paymentToken Token that should be used for the payment (0 is ETH)
    /// @param payment Value that should be paid
    /// @param paymentReceiver Address that should receive the payment (or 0 if tx.origin)
    /// @param _entryPoint Address for the trusted EIP4337 entrypoint
    function setupWithEntrypoint(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver,
        address _entryPoint,
        uint256[2] memory _qValues,
        address _ellipticCurve
    ) external {
        entryPoint = _entryPoint;
        qValues = _qValues;
        ellipticCurve = _ellipticCurve;

        _executeAndRevert(
            address(this),
            0,
            abi.encodeCall(Safe.setup, (
                _owners, _threshold,
                to, data,
                fallbackHandler,paymentToken,
                payment, paymentReceiver
            )),
            Enum.Operation.DelegateCall
        );
    }

    function _payPrefund(uint256 missingAccountFunds) internal {
        if (missingAccountFunds != 0) {
            (bool success,) = payable(msg.sender).call{value : missingAccountFunds, gas : type(uint256).max}("");
            (success);
            //ignore failure (its EntryPoint's job to verify, not account.)
        }
    }

    function validateUserOp(UserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
    external  returns (uint256 validationData) {
        _requireFromEntryPoint();
        validationData = _validateSignature(userOp, userOpHash);
        if (userOp.initCode.length == 0) {
            _validateAndUpdateNonce(userOp);
        }
        _payPrefund(missingAccountFunds);
    }

    /**
    * ensure the request comes from the known entrypoint.
    */
    function _requireFromEntryPoint() internal virtual view {
        require(msg.sender == entryPoint, "account: not from EntryPoint");
    }

    /// implement template method of BaseAccount
    function _validateAndUpdateNonce(
        UserOperation calldata userOp
    ) internal {
        require(nonce++ == userOp.nonce, "account: invalid nonce");
    }

    function _getRSValues(bytes calldata signature)
        external
        pure
        returns (uint256 r, uint256 s)
    {
        r = uint256(bytes32(signature[0:32]));
        s = uint256(bytes32(signature[32:64]));
    }

    function _getRequestId(bytes calldata clientDataJSON)
        external
        pure
        returns (bytes memory requestIdFromClientDataJSON)
    {
        return clientDataJSON[40:];
    }

    function concatBytes(bytes memory a, bytes memory b)
        public
        pure
        returns (bytes memory)
    {
        bytes memory result = new bytes(a.length + b.length);
        uint256 i;
        uint256 j;

        for (i = 0; i < a.length; i++) {
            result[j++] = a[i];
        }
        for (i = 0; i < b.length; i++) {
            result[j++] = b[i];
        }
        return result;
    }

    function toHex16(bytes16 data) internal pure returns (bytes32 result) {
        result =
            (bytes32(data) &
                0xFFFFFFFFFFFFFFFF000000000000000000000000000000000000000000000000) |
            ((bytes32(data) &
                0x0000000000000000FFFFFFFFFFFFFFFF00000000000000000000000000000000) >>
                64);
        result =
            (result &
                0xFFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000) |
            ((result &
                0x00000000FFFFFFFF000000000000000000000000FFFFFFFF0000000000000000) >>
                32);
        result =
            (result &
                0xFFFF000000000000FFFF000000000000FFFF000000000000FFFF000000000000) |
            ((result &
                0x0000FFFF000000000000FFFF000000000000FFFF000000000000FFFF00000000) >>
                16);
        result =
            (result &
                0xFF000000FF000000FF000000FF000000FF000000FF000000FF000000FF000000) |
            ((result &
                0x00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000) >>
                8);
        result =
            ((result &
                0xF000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000) >>
                4) |
            ((result &
                0x0F000F000F000F000F000F000F000F000F000F000F000F000F000F000F000F00) >>
                8);
        result = bytes32(
            0x3030303030303030303030303030303030303030303030303030303030303030 +
                uint256(result) +
                (((uint256(result) +
                    0x0606060606060606060606060606060606060606060606060606060606060606) >>
                    4) &
                    0x0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F) *
                7
        );
    }

    function toHex(bytes32 data) public pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '0x',
                    toHex16(bytes16(data)),
                    toHex16(bytes16(data << 128))
                )
            );
    }

    function lower(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    function _lower(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }

    function getRequestIdFromClientDataJSON(bytes calldata clientDataJSON)
        public
        pure
        returns (bytes calldata)
    {
        return clientDataJSON[36:124];
    }

    function compareBytes(bytes memory b1, bytes memory b2)
        public
        pure
        returns (bool)
    {
        if (b1.length != b2.length) {
            return false;
        }
        for (uint256 i = 0; i < b1.length; i++) {
            if (b1[i] != b2[i]) {
                return false;
            }
        }
        return true;
    }

    /// implement template method of BaseAccount
    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual returns (uint256 validationData) {

         (uint r, uint s, bytes32 message, bytes32 clientDataJsonHash) = abi.decode(
            userOp.signature,
            (uint, uint, bytes32, bytes32)
        );

        string memory userOpHashHex = lower(toHex(userOpHash));

        bytes memory base64RequestId = bytes(Base64.encode(userOpHashHex));

        require(keccak256(base64RequestId) == clientDataJsonHash, "Signed userOp doesn't match");

        bool success = EllipticCurve(ellipticCurve).validateSignature(
            message,
            [r, s],
            qValues
        );
        // bytes32 hash = userOpHash.toEthSignedMessageHash();
        if (!success) return SIG_VALIDATION_FAILED;
        return 0;
    }


    /// @dev Allows the entrypoint to execute a transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromEntrypoint(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public {
        // Only Entrypoint is allowed.
        require(msg.sender == entryPoint, "account: not from EntryPoint");
        // Execute transaction without further confirmations.
        _executeAndRevert(to, value, data, operation);
    }

    function _executeAndRevert(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal {

        bool success = execute(
            to,
            value,
            data,
            operation,
            type(uint256).max
        );

        bytes memory returnData = Exec.getReturnData(type(uint256).max);
        // Revert with the actual reason string
        // Adopted from: https://github.com/Uniswap/v3-periphery/blob/464a8a49611272f7349c970e0fadb7ec1d3c1086/contracts/base/Multicall.sol#L16-L23
        if (!success) {
            if (returnData.length < 68) revert();
            assembly {
                returnData := add(returnData, 0x04)
            }
            revert(abi.decode(returnData, (string)));
        }
    }

    /// @dev There should be only one verified entrypoint per chain
    /// @dev so this function should only be used if there is a problem with
    /// @dev the main entrypoint
    function replaceEntrypoint(address newEntrypoint) public authorized {
        entryPoint = newEntrypoint;
    }
}

pragma solidity ^0.8.12;

library Base64 {
    bytes private constant base64stdchars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes private constant base64urlchars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

    function encode(string memory _str) internal pure returns (string memory) {
        bytes memory _bs = bytes(_str);
        uint256 rem = _bs.length % 3;

        uint256 res_length = ((_bs.length + 2) / 3) * 4 - ((3 - rem) % 3);
        bytes memory res = new bytes(res_length);

        uint256 i = 0;
        uint256 j = 0;

        for (; i + 3 <= _bs.length; i += 3) {
            (res[j], res[j + 1], res[j + 2], res[j + 3]) = encode3(
                uint8(_bs[i]),
                uint8(_bs[i + 1]),
                uint8(_bs[i + 2])
            );

            j += 4;
        }

        if (rem != 0) {
            uint8 la0 = uint8(_bs[_bs.length - rem]);
            uint8 la1 = 0;

            if (rem == 2) {
                la1 = uint8(_bs[_bs.length - 1]);
            }

            (bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3) = encode3(la0, la1, 0);
            res[j] = b0;
            res[j + 1] = b1;
            if (rem == 2) {
                res[j + 2] = b2;
            }
        }

        return string(res);
    }

    function encode3(
        uint256 a0,
        uint256 a1,
        uint256 a2
    )
        private
        pure
        returns (
            bytes1 b0,
            bytes1 b1,
            bytes1 b2,
            bytes1 b3
        )
    {
        uint256 n = (a0 << 16) | (a1 << 8) | a2;

        uint256 c0 = (n >> 18) & 63;
        uint256 c1 = (n >> 12) & 63;
        uint256 c2 = (n >> 6) & 63;
        uint256 c3 = (n) & 63;

        b0 = base64urlchars[c0];
        b1 = base64urlchars[c1];
        b2 = base64urlchars[c2];
        b3 = base64urlchars[c3];
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/**
 * @title   EllipticCurve
 *
 * @author  Tilman Drerup;
 *
 * @notice  Implements elliptic curve math; Parametrized for SECP256R1.
 *
 *          Includes components of code by Andreas Olofsson, Alexander Vlasov
 *          (https://github.com/BANKEX/CurveArithmetics), and Avi Asayag
 *          (https://github.com/orbs-network/elliptic-curve-solidity)
 *
 * @dev     NOTE: To disambiguate public keys when verifying signatures, activate
 *          condition 'rs[1] > lowSmax' in validateSignature().
 */
contract EllipticCurve {

    // Set parameters for curve.
    uint constant a = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFC;
    uint constant b = 0x5AC635D8AA3A93E7B3EBBD55769886BC651D06B0CC53B0F63BCE3C3E27D2604B;
    uint constant gx = 0x6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296;
    uint constant gy = 0x4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5;
    uint constant p = 0xFFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF;
    uint constant n = 0xFFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551;

    uint constant lowSmax = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;

    /**
     * @dev Inverse of u in the field of modulo m.
     */
    function inverseMod(uint u, uint m) internal pure
        returns (uint)
    {
        if (u == 0 || u == m || m == 0)
            return 0;
        if (u > m)
            u = u % m;

        int t1;
        int t2 = 1;
        uint r1 = m;
        uint r2 = u;
        uint q;
        unchecked{
        while (r2 != 0) {
            q = r1 / r2;
            (t1, t2, r1, r2) = (t2, t1 - int(q) * t2, r2, r1 - q * r2);
        }

        if (t1 < 0)
            return (m - uint(-t1));
        
        return uint(t1);
        }
    }

    /**
     * @dev Transform affine coordinates into projective coordinates.
     */
    function toProjectivePoint(uint x0, uint y0) public pure
        returns (uint[3] memory P)
    {
        unchecked{
            P[2] = addmod(0, 1, p);
            P[0] = mulmod(x0, P[2], p);
            P[1] = mulmod(y0, P[2], p);
        }
    }

    /**
     * @dev Add two points in affine coordinates and return projective point.
     */
    function addAndReturnProjectivePoint(uint x1, uint y1, uint x2, uint y2) public pure
        returns (uint[3] memory P)
    {
        uint x;
        uint y;
        unchecked{
            (x, y) = add(x1, y1, x2, y2);
        }
        P = toProjectivePoint(x, y);
    }

    /**
     * @dev Transform from projective to affine coordinates.
     */
    function toAffinePoint(uint x0, uint y0, uint z0) public pure
        returns (uint x1, uint y1)
    {
        uint z0Inv;
        unchecked{
        z0Inv = inverseMod(z0, p);
        x1 = mulmod(x0, z0Inv, p);
        y1 = mulmod(y0, z0Inv, p);
        }
    }

    /**
     * @dev Return the zero curve in projective coordinates.
     */
    function zeroProj() public pure
        returns (uint x, uint y, uint z)
    {
        return (0, 1, 0);
    }

    /**
     * @dev Return the zero curve in affine coordinates.
     */
    function zeroAffine() public pure
        returns (uint x, uint y)
    {
        return (0, 0);
    }

    /**
     * @dev Check if the curve is the zero curve.
     */
    function isZeroCurve(uint x0, uint y0) public pure
        returns (bool isZero)
    {
        if(x0 == 0 && y0 == 0) {
            return true;
        }
        return false;
    }

    /**
     * @dev Check if a point in affine coordinates is on the curve.
     */
    function isOnCurve(uint x, uint y) public pure
        returns (bool)
    {
        if (0 == x || x == p || 0 == y || y == p) {
            return false;
        }
        unchecked{
        uint LHS = mulmod(y, y, p); // y^2
        uint RHS = mulmod(mulmod(x, x, p), x, p); // x^3

        if (a != 0) {
            RHS = addmod(RHS, mulmod(x, a, p), p); // x^3 + a*x
        }
        if (b != 0) {
            RHS = addmod(RHS, b, p); // x^3 + a*x + b
        }
        
        return LHS == RHS;
        }
    }

    /**
     * @dev Double an elliptic curve point in projective coordinates. See
     * https://www.nayuki.io/page/elliptic-curve-point-addition-in-projective-coordinates
     */
    function twiceProj(uint x0, uint y0, uint z0) public pure
        returns (uint x1, uint y1, uint z1)
    {
        uint t;
        uint u;
        uint v;
        uint w;

        if(isZeroCurve(x0, y0)) {
            return zeroProj();
        }
        unchecked{
        u = mulmod(y0, z0, p);
        u = mulmod(u, 2, p);

        v = mulmod(u, x0, p);
        v = mulmod(v, y0, p);
        v = mulmod(v, 2, p);

        x0 = mulmod(x0, x0, p);
        t = mulmod(x0, 3, p);

        z0 = mulmod(z0, z0, p);
        z0 = mulmod(z0, a, p);
        t = addmod(t, z0, p);

        w = mulmod(t, t, p);
        x0 = mulmod(2, v, p);
        w = addmod(w, p-x0, p);

        x0 = addmod(v, p-w, p);
        x0 = mulmod(t, x0, p);
        y0 = mulmod(y0, u, p);
        y0 = mulmod(y0, y0, p);
        y0 = mulmod(2, y0, p);
        y1 = addmod(x0, p-y0, p);

        x1 = mulmod(u, w, p);

        z1 = mulmod(u, u, p);
        z1 = mulmod(z1, u, p);
        }
    }

    /**
     * @dev Add two elliptic curve points in projective coordinates. See
     * https://www.nayuki.io/page/elliptic-curve-point-addition-in-projective-coordinates
     */
    function addProj(uint x0, uint y0, uint z0, uint x1, uint y1, uint z1) public pure
        returns (uint x2, uint y2, uint z2)
    {
        uint t0;
        uint t1;
        uint u0;
        uint u1;

        if (isZeroCurve(x0, y0)) {
            return (x1, y1, z1);
        }
        else if (isZeroCurve(x1, y1)) {
            return (x0, y0, z0);
        }
        unchecked{
        t0 = mulmod(y0, z1, p);
        t1 = mulmod(y1, z0, p);

        u0 = mulmod(x0, z1, p);
        u1 = mulmod(x1, z0, p);
        }
        if (u0 == u1) {
            if (t0 == t1) {
                return twiceProj(x0, y0, z0);
            }
            else {
                return zeroProj();
            }
        }
        unchecked{
        (x2, y2, z2) = addProj2(mulmod(z0, z1, p), u0, u1, t1, t0);
        }
    }

    /**
     * @dev Helper function that splits addProj to avoid too many local variables.
     */
    function addProj2(uint v, uint u0, uint u1, uint t1, uint t0) private pure
        returns (uint x2, uint y2, uint z2)
    {
        uint u;
        uint u2;
        uint u3;
        uint w;
        uint t;

        unchecked{
        t = addmod(t0, p-t1, p);
        u = addmod(u0, p-u1, p);
        u2 = mulmod(u, u, p);

        w = mulmod(t, t, p);
        w = mulmod(w, v, p);
        u1 = addmod(u1, u0, p);
        u1 = mulmod(u1, u2, p);
        w = addmod(w, p-u1, p);

        x2 = mulmod(u, w, p);

        u3 = mulmod(u2, u, p);
        u0 = mulmod(u0, u2, p);
        u0 = addmod(u0, p-w, p);
        t = mulmod(t, u0, p);
        t0 = mulmod(t0, u3, p);

        y2 = addmod(t, p-t0, p);

        z2 = mulmod(u3, v, p);
        }
    }

    /**
     * @dev Add two elliptic curve points in affine coordinates.
     */
    function add(uint x0, uint y0, uint x1, uint y1) public pure
        returns (uint, uint)
    {
        uint z0;

        (x0, y0, z0) = addProj(x0, y0, 1, x1, y1, 1);

        return toAffinePoint(x0, y0, z0);
    }

    /**
     * @dev Double an elliptic curve point in affine coordinates.
     */
    function twice(uint x0, uint y0) public pure
        returns (uint, uint)
    {
        uint z0;

        (x0, y0, z0) = twiceProj(x0, y0, 1);

        return toAffinePoint(x0, y0, z0);
    }

    /**
     * @dev Multiply an elliptic curve point by a 2 power base (i.e., (2^exp)*P)).
     */
    function multiplyPowerBase2(uint x0, uint y0, uint exp) public pure
        returns (uint, uint)
    {
        uint base2X = x0;
        uint base2Y = y0;
        uint base2Z = 1;

        for(uint i = 0; i < exp; i++) {
            (base2X, base2Y, base2Z) = twiceProj(base2X, base2Y, base2Z);
        }

        return toAffinePoint(base2X, base2Y, base2Z);
    }

    /**
     * @dev Multiply an elliptic curve point by a scalar.
     */
    function multiplyScalar(uint x0, uint y0, uint scalar) public pure
        returns (uint x1, uint y1)
    {
        if(scalar == 0) {
            return zeroAffine();
        }
        else if (scalar == 1) {
            return (x0, y0);
        }
        else if (scalar == 2) {
            return twice(x0, y0);
        }

        uint base2X = x0;
        uint base2Y = y0;
        uint base2Z = 1;
        uint z1 = 1;
        x1 = x0;
        y1 = y0;

        if(scalar%2 == 0) {
            x1 = y1 = 0;
        }

        scalar = scalar >> 1;

        while(scalar > 0) {
            (base2X, base2Y, base2Z) = twiceProj(base2X, base2Y, base2Z);

            if(scalar%2 == 1) {
                (x1, y1, z1) = addProj(base2X, base2Y, base2Z, x1, y1, z1);
            }

            scalar = scalar >> 1;
        }

        return toAffinePoint(x1, y1, z1);
    }

    /**
     * @dev Multiply the curve's generator point by a scalar.
     */
    function multipleGeneratorByScalar(uint scalar) public pure
        returns (uint, uint)
    {
        return multiplyScalar(gx, gy, scalar);
    }

    /**
     * @dev Validate combination of message, signature, and public key.
     */
    function validateSignature(bytes32 message, uint[2] memory rs, uint[2] memory Q) public pure
        returns (bool)
    {

        // To disambiguate between public key solutions, include comment below.
        if(rs[0] == 0 || rs[0] >= n || rs[1] == 0) {// || rs[1] > lowSmax)
            return false;
        }
        if (!isOnCurve(Q[0], Q[1])) {
            return false;
        }

        uint x1;
        uint x2;
        uint y1;
        uint y2;

        uint sInv = inverseMod(rs[1], n);
        (x1, y1) = multiplyScalar(gx, gy, mulmod(uint(message), sInv, n));
        (x2, y2) = multiplyScalar(Q[0], Q[1], mulmod(rs[0], sInv, n));
        uint[3] memory P = addAndReturnProjectivePoint(x1, y1, x2, y2);

        if (P[2] == 0) {
            return false;
        }

        uint Px = inverseMod(P[2], p);
        unchecked{
        Px = mulmod(P[0], mulmod(Px, Px, p), p);
        }

        return Px % n == rs[0];
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.5 <0.9.0;

// solhint-disable no-inline-assembly

/**
 * Utility functions helpful when making different kinds of contract calls in Solidity.
 */
library Exec {

    function call(
        address to,
        uint256 value,
        bytes memory data,
        uint256 txGas
    ) internal returns (bool success) {
        assembly {
            success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function staticcall(
        address to,
        bytes memory data,
        uint256 txGas
    ) internal view returns (bool success) {
        assembly {
            success := staticcall(txGas, to, add(data, 0x20), mload(data), 0, 0)
        }
    }

    function delegateCall(
        address to,
        bytes memory data,
        uint256 txGas
    ) internal returns (bool success) {
        assembly {
            success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
        }
    }

    // get returned data from last call or calldelegate
    function getReturnData(uint256 maxLen) internal pure returns (bytes memory returnData) {
        assembly {
            let len := returndatasize()
            if gt(len, maxLen) {
                len := maxLen
            }
            let ptr := mload(0x40)
            mstore(0x40, add(ptr, add(len, 0x20)))
            mstore(ptr, len)
            returndatacopy(add(ptr, 0x20), 0, len)
            returnData := ptr
        }
    }

    // revert with explicit byte array (probably reverted info from call)
    function revertWithData(bytes memory returnData) internal pure {
        assembly {
            revert(add(returnData, 32), mload(returnData))
        }
    }

    function callAndRevert(address to, bytes memory data, uint256 maxLen) internal {
        bool success = call(to,0,data,gasleft());
        if (!success) {
            revertWithData(getReturnData(maxLen));
        }
    }
}