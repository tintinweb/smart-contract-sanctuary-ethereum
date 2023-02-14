// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

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
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
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
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address, RecoverError) {
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
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
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
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 message) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, "\x19Ethereum Signed Message:\n32")
            mstore(0x1c, hash)
            message := keccak256(0x00, 0x3c)
        }
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
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice storage for nayms v3 decentralized insurance platform

import "./interfaces/FreeStructs.sol";

struct AppStorage {
    // Has this diamond been initialized?
    bool diamondInitialized;
    //// EIP712 domain separator ////
    uint256 initialChainId;
    bytes32 initialDomainSeparator;
    //// Reentrancy guard ////
    uint256 reentrancyStatus;
    //// NAYMS ERC20 TOKEN ////
    string name;
    mapping(address => mapping(address => uint256)) allowance;
    uint256 totalSupply;
    mapping(bytes32 => bool) internalToken;
    mapping(address => uint256) balances;
    //// Object ////
    mapping(bytes32 => bool) existingObjects; // objectId => is an object?
    mapping(bytes32 => bytes32) objectParent; // objectId => parentId
    mapping(bytes32 => bytes32) objectDataHashes;
    mapping(bytes32 => string) objectTokenSymbol;
    mapping(bytes32 => string) objectTokenName;
    mapping(bytes32 => address) objectTokenWrapper;
    mapping(bytes32 => bool) existingEntities; // entityId => is an entity?
    mapping(bytes32 => bool) existingSimplePolicies; // simplePolicyId => is a simple policy?
    //// ENTITY ////
    mapping(bytes32 => Entity) entities; // objectId => Entity struct
    //// SIMPLE POLICY ////
    mapping(bytes32 => SimplePolicy) simplePolicies; // objectId => SimplePolicy struct
    //// External Tokens ////
    mapping(address => bool) externalTokenSupported;
    address[] supportedExternalTokens;
    //// TokenizedObject ////
    mapping(bytes32 => mapping(bytes32 => uint256)) tokenBalances; // tokenId => (ownerId => balance)
    mapping(bytes32 => uint256) tokenSupply; // tokenId => Total Token Supply
    //// Dividends ////
    uint8 maxDividendDenominations;
    mapping(bytes32 => bytes32[]) dividendDenominations; // object => tokenId of the dividend it allows
    mapping(bytes32 => mapping(bytes32 => uint8)) dividendDenominationIndex; // entity ID => (token ID => index of dividend denomination)
    mapping(bytes32 => mapping(uint8 => bytes32)) dividendDenominationAtIndex; // entity ID => (index of dividend denomination => token id)
    mapping(bytes32 => mapping(bytes32 => uint256)) totalDividends; // token ID => (denomination ID => total dividend)
    mapping(bytes32 => mapping(bytes32 => mapping(bytes32 => uint256))) withdrawnDividendPerOwner; // entity => (tokenId => (owner => total withdrawn dividend)) NOT per share!!! this is TOTAL
    //// ACL Configuration////
    mapping(bytes32 => mapping(bytes32 => bool)) groups; //role => (group => isRoleInGroup)
    mapping(bytes32 => bytes32) canAssign; //role => Group that can assign/unassign that role
    //// User Data ////
    mapping(bytes32 => mapping(bytes32 => bytes32)) roles; // userId => (contextId => role)
    //// MARKET ////
    uint256 lastOfferId;
    mapping(uint256 => MarketInfo) offers; // offer Id => MarketInfo struct
    mapping(bytes32 => mapping(bytes32 => uint256)) bestOfferId; // sell token => buy token => best offer Id
    mapping(bytes32 => mapping(bytes32 => uint256)) span; // sell token => buy token => span
    address naymsToken; // represents the address key for this NAYMS token in AppStorage
    bytes32 naymsTokenId; // represents the bytes32 key for this NAYMS token in AppStorage
    /// Trading Commissions (all in basis points) ///
    uint16 tradingCommissionTotalBP; // the total amount that is deducted for trading commissions (BP)
    // The total commission above is further divided as follows:
    uint16 tradingCommissionNaymsLtdBP;
    uint16 tradingCommissionNDFBP;
    uint16 tradingCommissionSTMBP;
    uint16 tradingCommissionMakerBP;
    // Premium Commissions
    uint16 premiumCommissionNaymsLtdBP;
    uint16 premiumCommissionNDFBP;
    uint16 premiumCommissionSTMBP;
    // A policy can pay out additional commissions on premiums to entities having a variety of roles on the policy
    mapping(bytes32 => mapping(bytes32 => uint256)) lockedBalances; // keep track of token balance that is locked, ownerId => tokenId => lockedAmount
    /// Simple two phase upgrade scheme
    mapping(bytes32 => uint256) upgradeScheduled; // id of the upgrade => the time that the upgrade is valid until.
    uint256 upgradeExpiration; // the period of time that an upgrade is valid until.
    uint256 sysAdmins; // counter for the number of sys admin accounts currently assigned
}

library LibAppStorage {
    bytes32 internal constant NAYMS_DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.nayms.storage");

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        bytes32 position = NAYMS_DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// solhint-disable no-empty-blocks

import { IDiamondCut } from "../shared/interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "../shared/interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../shared/interfaces/IERC165.sol";
import { IERC173 } from "../shared/interfaces/IERC173.sol";

import { IACLFacet } from "./interfaces/IACLFacet.sol";
import { IUserFacet } from "./interfaces/IUserFacet.sol";
import { IAdminFacet } from "./interfaces/IAdminFacet.sol";
import { ISystemFacet } from "./interfaces/ISystemFacet.sol";
import { INaymsTokenFacet } from "./interfaces/INaymsTokenFacet.sol";
import { ITokenizedVaultFacet } from "./interfaces/ITokenizedVaultFacet.sol";
import { ITokenizedVaultIOFacet } from "./interfaces/ITokenizedVaultIOFacet.sol";
import { IMarketFacet } from "./interfaces/IMarketFacet.sol";
import { IEntityFacet } from "./interfaces/IEntityFacet.sol";
import { ISimplePolicyFacet } from "./interfaces/ISimplePolicyFacet.sol";
import { IGovernanceFacet } from "./interfaces/IGovernanceFacet.sol";

/**
 * @title Nayms Diamond
 * @notice Everything is a part of one big diamond.
 * @dev Every facet should be cut into this diamond.
 */
interface INayms is
    IDiamondCut,
    IDiamondLoupe,
    IERC165,
    IERC173,
    IACLFacet,
    IAdminFacet,
    IUserFacet,
    ISystemFacet,
    INaymsTokenFacet,
    ITokenizedVaultFacet,
    ITokenizedVaultIOFacet,
    IMarketFacet,
    IEntityFacet,
    ISimplePolicyFacet,
    IGovernanceFacet
{

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice modifiers

import { LibMeta } from "../shared/libs/LibMeta.sol";
import { LibAdmin } from "./libs/LibAdmin.sol";
import { LibConstants } from "./libs/LibConstants.sol";
import { LibHelpers } from "./libs/LibHelpers.sol";
import { LibObject } from "./libs/LibObject.sol";
import { LibACL } from "./libs/LibACL.sol";

/**
 * @title Modifiers
 * @notice Function modifiers to control access
 * @dev Function modifiers to control access
 */
contract Modifiers {
    modifier assertSysAdmin() {
        require(
            LibACL._isInGroup(LibHelpers._getIdForAddress(LibMeta.msgSender()), LibAdmin._getSystemId(), LibHelpers._stringToBytes32(LibConstants.GROUP_SYSTEM_ADMINS)),
            "not a system admin"
        );
        _;
    }

    modifier assertSysMgr() {
        require(
            LibACL._isInGroup(LibHelpers._getIdForAddress(LibMeta.msgSender()), LibAdmin._getSystemId(), LibHelpers._stringToBytes32(LibConstants.GROUP_SYSTEM_MANAGERS)),
            "not a system manager"
        );
        _;
    }

    modifier assertEntityAdmin(bytes32 _context) {
        require(
            LibACL._isInGroup(LibHelpers._getIdForAddress(LibMeta.msgSender()), _context, LibHelpers._stringToBytes32(LibConstants.GROUP_ENTITY_ADMINS)),
            "not the entity's admin"
        );
        _;
    }

    modifier assertPolicyHandler(bytes32 _context) {
        require(
            LibACL._isInGroup(LibObject._getParentFromAddress(LibMeta.msgSender()), _context, LibHelpers._stringToBytes32(LibConstants.GROUP_POLICY_HANDLERS)),
            "not a policy handler"
        );
        _;
    }

    modifier assertIsInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _group
    ) {
        require(LibACL._isInGroup(_objectId, _contextId, _group), "not in group");
        _;
    }

    modifier assertERC20Wrapper(bytes32 _tokenId) {
        (, , , , address erc20Wrapper) = LibObject._getObjectMeta(_tokenId);
        require(msg.sender == erc20Wrapper, "only wrapper calls allowed");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Modifiers } from "../Modifiers.sol";
import { Entity } from "../AppStorage.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibObject } from "../libs/LibObject.sol";
import { LibEntity } from "../libs/LibEntity.sol";
import { ISystemFacet } from "../interfaces/ISystemFacet.sol";
import { ReentrancyGuard } from "../../../utils/ReentrancyGuard.sol";

/**
 * @title System
 * @notice Use it to perform system level operations
 * @dev Use it to perform system level operations
 */
contract SystemFacet is ISystemFacet, Modifiers, ReentrancyGuard {
    /**
     * @notice Create an entity
     * @dev An entity can be created with a zero max capacity! This is in the event where an entity cannot write any policies.
     * @param _entityId Unique ID for the entity
     * @param _entityAdmin Unique ID of the entity administrator
     * @param _entityData remaining entity metadata
     * @param _dataHash hash of the offchain data
     */
    function createEntity(
        bytes32 _entityId,
        bytes32 _entityAdmin,
        Entity memory _entityData,
        bytes32 _dataHash
    ) external assertSysMgr {
        LibEntity._createEntity(_entityId, _entityAdmin, _entityData, _dataHash);
    }

    /**
     * @notice Convert a string type to a bytes32 type
     * @param _strIn a string
     */
    function stringToBytes32(string memory _strIn) external pure returns (bytes32 result) {
        result = LibHelpers._stringToBytes32(_strIn);
    }

    /**
     * @dev Get whether given id is an object in the system.
     * @param _id object id.
     * @return true if it is an object, false otherwise
     */
    function isObject(bytes32 _id) external view returns (bool) {
        return LibObject._isObject(_id);
    }

    /**
     * @dev Get meta of given object.
     * @param _id object id.
     * @return parent object parent
     * @return dataHash object data hash
     * @return tokenSymbol object token symbol
     * @return tokenName object token name
     * @return tokenWrapper object token ERC20 wrapper address
     */
    function getObjectMeta(bytes32 _id)
        external
        view
        returns (
            bytes32 parent,
            bytes32 dataHash,
            string memory tokenSymbol,
            string memory tokenName,
            address tokenWrapper
        )
    {
        return LibObject._getObjectMeta(_id);
    }

    /**
     * @notice Wrap an object token as ERC20
     * @param _objectId ID of the tokenized object
     */
    function wrapToken(bytes32 _objectId) external nonReentrant assertSysMgr {
        LibObject._wrapToken(_objectId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @dev Passing in a missing role when trying to assign a role.
error RoleIsMissing();

/// @dev Passing in a missing group when trying to assign a role to a group.
error AssignerGroupIsMissing();

/// @dev Passing in a missing address when trying to add a token address to the supported external token list.
error CannotAddNullSupportedExternalToken();

/// @dev Cannot add a ERC20 token to the supported external token list that has more than 18 decimal places.
error CannotSupportExternalTokenWithMoreThan18Decimals();

/// @dev Passing in a missing address when trying to assign a new token address as the new discount token.
error CannotAddNullDiscountToken();

/// @dev The entity does not exist when it should.
error EntityDoesNotExist(bytes32 objectId);
/// @dev Cannot create an entity that already exists.
error CreatingEntityThatAlreadyExists(bytes32 entityId);

/// @dev (non specific) the object is not enabled to be tokenized.
error ObjectCannotBeTokenized(bytes32 objectId);

/// @dev Passing in a missing symbol when trying to enable an object to be tokenized.
error MissingSymbolWhenEnablingTokenization(bytes32 objectId);

/// @dev Passing in 0 amount for deposits is not allowed.
error ExternalDepositAmountCannotBeZero();

/// @dev Passing in 0 amount for withdraws is not allowed.
error ExternalWithdrawAmountCannotBeZero();

/// @dev Cannot create a simple policy with policyId of 0
error PolicyIdCannotBeZero();

/// @dev Policy commissions among commission receivers cannot sum to be greater than 10_000 basis points.
error PolicyCommissionsBasisPointsCannotBeGreaterThan10000(uint256 calculatedTotalBp);

/// @dev When validating an entity, the utilized capacity cannot be greater than the max capacity.
error UtilizedCapacityGreaterThanMaxCapacity(uint256 utilizedCapacity, uint256 maxCapacity);

/// @dev Policy stakeholder signature validation failed
error SimplePolicyStakeholderSignatureInvalid(bytes32 signingHash, bytes signature, bytes32 signerId, bytes32 signersParent, bytes32 entityId);

/// @dev When creating a simple policy, the total claims paid should start at 0.
error SimplePolicyClaimsPaidShouldStartAtZero();

/// @dev When creating a simple policy, the total premiums paid should start at 0.
error SimplePolicyPremiumsPaidShouldStartAtZero();

/// @dev The cancel bool should not be set to true when creating a new simple policy.
error CancelCannotBeTrueWhenCreatingSimplePolicy();

/// @dev (non specific) The policyId must exist.
error PolicyDoesNotExist(bytes32 policyId);

/// @dev There is a duplicate address in the list of signers (the previous signer in the list is not < the next signer in the list).
error DuplicateSignerCreatingSimplePolicy(address previousSigner, address nextSigner);

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct MarketInfo {
    bytes32 creator; // entity ID
    bytes32 sellToken;
    uint256 sellAmount;
    uint256 sellAmountInitial;
    bytes32 buyToken;
    uint256 buyAmount;
    uint256 buyAmountInitial;
    uint256 feeSchedule;
    uint256 state;
    uint256 rankNext;
    uint256 rankPrev;
}

struct TokenAmount {
    bytes32 token;
    uint256 amount;
}

/**
 * @param maxCapacity Maxmimum allowable amount of capacity that an entity is given. Denominated by assetId.
 * @param utilizedCapacity The utilized capacity of the entity. Denominated by assetId.
 */
struct Entity {
    bytes32 assetId;
    uint256 collateralRatio;
    uint256 maxCapacity;
    uint256 utilizedCapacity;
    bool simplePolicyEnabled;
}

struct SimplePolicy {
    uint256 startDate;
    uint256 maturationDate;
    bytes32 asset;
    uint256 limit;
    bool fundsLocked;
    bool cancelled;
    uint256 claimsPaid;
    uint256 premiumsPaid;
    bytes32[] commissionReceivers;
    uint256[] commissionBasisPoints;
}

struct SimplePolicyInfo {
    uint256 startDate;
    uint256 maturationDate;
    bytes32 asset;
    uint256 limit;
    bool fundsLocked;
    bool cancelled;
    uint256 claimsPaid;
    uint256 premiumsPaid;
}

struct PolicyCommissionsBasisPoints {
    uint16 premiumCommissionNaymsLtdBP;
    uint16 premiumCommissionNDFBP;
    uint16 premiumCommissionSTMBP;
}

struct Stakeholders {
    bytes32[] roles;
    bytes32[] entityIds;
    bytes[] signatures;
}

// Used in StakingFacet
struct LockedBalance {
    uint256 amount;
    uint256 endTime;
}

struct StakingCheckpoint {
    int128 bias;
    int128 slope; // - dweight / dt
    uint256 ts; // timestamp
    uint256 blk; // block number
}

struct FeeRatio {
    uint256 brokerShareRatio;
    uint256 naymsLtdShareRatio;
    uint256 ndfShareRatio;
}

struct TradingCommissions {
    uint256 roughCommissionPaid;
    uint256 commissionNaymsLtd;
    uint256 commissionNDF;
    uint256 commissionSTM;
    uint256 commissionMaker;
    uint256 totalCommissions;
}

struct TradingCommissionsBasisPoints {
    uint16 tradingCommissionTotalBP;
    uint16 tradingCommissionNaymsLtdBP;
    uint16 tradingCommissionNDFBP;
    uint16 tradingCommissionSTMBP;
    uint16 tradingCommissionMakerBP;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Access Control List
 * @notice Use it to authorize various actions on the contracts
 * @dev Use it to (un)assign or check role membership
 */
interface IACLFacet {
    /**
     * @notice Assign a `_roleId` to the object in given context
     * @dev Any object ID can be a context, system is a special context with highest priority
     * @param _objectId ID of an object that is being assigned a role
     * @param _contextId ID of the context in which a role is being assigned
     * @param _role Name of the role being assigned
     */
    function assignRole(
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _role
    ) external;

    /**
     * @notice Unassign object from a role in given context
     * @dev Any object ID can be a context, system is a special context with highest priority
     * @param _objectId ID of an object that is being unassigned from a role
     * @param _contextId ID of the context in which a role membership is being revoked
     */
    function unassignRole(bytes32 _objectId, bytes32 _contextId) external;

    /**
     * @notice Checks if an object belongs to `_group` group in given context
     * @dev Assigning a role to the object makes it a member of a corresponding role group
     * @param _objectId ID of an object that is being checked for role group membership
     * @param _contextId Context in which membership should be checked
     * @param _group name of the role group
     * @return true if object with given ID is a member, false otherwise
     */
    function isInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _group
    ) external view returns (bool);

    /**
     * @notice Check whether a parent object belongs to the `_group` group in given context
     * @dev Objects can have a parent object, i.e. entity is a parent of a user
     * @param _objectId ID of an object whose parent is being checked for role group membership
     * @param _contextId Context in which the role group membership is being checked
     * @param _group name of the role group
     * @return true if object's parent is a member of this role group, false otherwise
     */
    function isParentInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _group
    ) external view returns (bool);

    /**
     * @notice Check whether a user can assign specific object to the `_role` role in given context
     * @dev Check permission to assign to a role
     * @param _assignerId The object ID of the user who is assigning a role to  another object.
     * @param _objectId ID of an object that is being checked for assigning rights
     * @param _contextId ID of the context in which permission is checked
     * @param _role name of the role to check
     * @return true if user the right to assign, false otherwise
     */
    function canAssign(
        bytes32 _assignerId,
        bytes32 _objectId,
        bytes32 _contextId,
        string memory _role
    ) external view returns (bool);

    /**
     * @notice Get a user's (an objectId's) assigned role in a specific context
     * @param objectId ID of an object that is being checked for its assigned role in a specific context
     * @param contextId ID of the context in which the objectId's role is being checked
     * @return roleId objectId's role in the contextId
     */
    function getRoleInContext(bytes32 objectId, bytes32 contextId) external view returns (bytes32);

    /**
     * @notice Get whether role is in group.
     * @dev Get whether role is in group.
     * @param role the role.
     * @param group the group.
     * @return true if role is in group, false otherwise.
     */
    function isRoleInGroup(string memory role, string memory group) external view returns (bool);

    /**
     * @notice Get whether given group can assign given role.
     * @dev Get whether given group can assign given role.
     * @param role the role.
     * @param group the group.
     * @return true if role can be assigned by group, false otherwise.
     */
    function canGroupAssignRole(string memory role, string memory group) external view returns (bool);

    /**
     * @notice Update who can assign `_role` role
     * @dev Update who has permission to assign this role
     * @param _role name of the role
     * @param _assignerGroup Group who can assign members to this role
     */
    function updateRoleAssigner(string memory _role, string memory _assignerGroup) external;

    /**
     * @notice Update role group memebership for `_role` role and `_group` group
     * @dev Update role group memebership
     * @param _role name of the role
     * @param _group name of the group
     * @param _roleInGroup is member of
     */
    function updateRoleGroup(
        string memory _role,
        string memory _group,
        bool _roleInGroup
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { PolicyCommissionsBasisPoints, TradingCommissionsBasisPoints } from "./FreeStructs.sol";

/**
 * @title Administration
 * @notice Exposes methods that require administrative priviledges
 * @dev Use it to configure various core parameters
 */
interface IAdminFacet {
    /**
     * @notice Set `_newMax` as the max dividend denominations value.
     * @param _newMax new value to be used.
     */
    function setMaxDividendDenominations(uint8 _newMax) external;

    /**
     * @notice Update policy commission basis points configuration.
     * @param _policyCommissions policy commissions configuration to set
     */
    function setPolicyCommissionsBasisPoints(PolicyCommissionsBasisPoints calldata _policyCommissions) external;

    /**
     * @notice Update trading commission basis points configuration.
     * @param _tradingCommissions trading commissions configuration to set
     */
    function setTradingCommissionsBasisPoints(TradingCommissionsBasisPoints calldata _tradingCommissions) external;

    /**
     * @notice Get the max dividend denominations value
     * @return max dividend denominations
     */
    function getMaxDividendDenominations() external view returns (uint8);

    /**
     * @notice Is the specified tokenId an external ERC20 that is supported by the Nayms platform?
     * @param _tokenId token address converted to bytes32
     * @return whether token issupported or not
     */
    function isSupportedExternalToken(bytes32 _tokenId) external view returns (bool);

    /**
     * @notice Add another token to the supported tokens list
     * @param _tokenAddress address of the token to support
     */
    function addSupportedExternalToken(address _tokenAddress) external;

    /**
     * @notice Get the supported tokens list as an array
     * @return array containing address of all supported tokens
     */
    function getSupportedExternalTokens() external view returns (address[] memory);

    /**
     * @notice Gets the System context ID.
     * @return System Identifier
     */
    function getSystemId() external pure returns (bytes32);

    /**
     * @notice Check if object can be tokenized
     * @param _objectId ID of the object
     */
    function isObjectTokenizable(bytes32 _objectId) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { SimplePolicy, Entity, Stakeholders } from "./FreeStructs.sol";

/**
 * @title Entities
 * @notice Used to handle policies and token sales
 * @dev Mainly used for token sale and policies
 */
interface IEntityFacet {
    /**
     * @dev Returns the domain separator for the current chain.
     */
    function domainSeparatorV4() external view returns (bytes32);

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function hashTypedDataV4(bytes32 structHash) external view returns (bytes32);

    /**
     * @notice Create a Simple Policy
     * @param _policyId id of the policy
     * @param _entityId id of the entity
     * @param _stakeholders Struct of roles, entity IDs and signatures for the policy
     * @param _simplePolicy policy to create
     * @param _dataHash hash of the offchain data
     */
    function createSimplePolicy(
        bytes32 _policyId,
        bytes32 _entityId,
        Stakeholders calldata _stakeholders,
        SimplePolicy calldata _simplePolicy,
        bytes32 _dataHash
    ) external;

    /**
     * @notice Enable an entity to be tokenized
     * @param _entityId ID of the entity
     * @param _symbol The symbol assigned to the entity token
     * @param _name The name assigned to the entity token
     */
    function enableEntityTokenization(
        bytes32 _entityId,
        string memory _symbol,
        string memory _name
    ) external;

    /**
     * @notice Start token sale of `_amount` tokens for total price of `_totalPrice`
     * @dev Entity tokens are minted when the sale is started
     * @param _entityId ID of the entity
     * @param _amount amount of entity tokens to put on sale
     * @param _totalPrice total price of the tokens
     */
    function startTokenSale(
        bytes32 _entityId,
        uint256 _amount,
        uint256 _totalPrice
    ) external;

    /**
     * @notice Check if an entity token is wrapped as ERC20
     * @param _entityId ID of the entity
     */
    function isTokenWrapped(bytes32 _entityId) external view returns (bool);

    /**
     * @notice Update entity metadata
     * @param _entityId ID of the entity
     * @param _entity metadata of the entity
     */
    function updateEntity(bytes32 _entityId, Entity calldata _entity) external;

    /**
     * @notice Get the the data for entity with ID: `_entityId`
     * @dev Get the Entity data for a given entityId
     * @param _entityId ID of the entity
     * @return Entity struct with metadata of the entity
     */
    function getEntityInfo(bytes32 _entityId) external view returns (Entity memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IGovernanceFacet {
    /**
     * @notice Approve the following upgrade hash: `id`
     * @dev The diamondCut() has been modified to check if the upgrade has been scheduled. This method needs to be called in order
     *      for an upgrade to be executed.
     * @param id This is the keccak256(abi.encode(cut)), where cut is the array of FacetCut struct, IDiamondCut.FacetCut[].
     */
    function createUpgrade(bytes32 id) external;

    /**
     * @notice Update the diamond cut upgrade expiration period.
     * @dev When createUpgrade() is called, it allows a diamondCut() upgrade to be executed. This upgrade must be executed before the
     *      upgrade expires. The upgrade expires based on when the upgrade was scheduled (when createUpgrade() was called) + AppStorage.upgradeExpiration.
     * @param duration The duration until the upgrade expires.
     */
    function updateUpgradeExpiration(uint256 duration) external;

    /**
     * @notice Cancel the following upgrade hash: `id`
     * @dev This will set the mapping AppStorage.upgradeScheduled back to 0.
     * @param id This is the keccak256(abi.encode(cut)), where cut is the array of FacetCut struct, IDiamondCut.FacetCut[].
     */
    function cancelUpgrade(bytes32 id) external;

    /**
     * @notice Get the expiry date for provided upgrade hash.
     * @dev This will get the value from AppStorage.upgradeScheduled  mapping.
     * @param id This is the keccak256(abi.encode(cut)), where cut is the array of FacetCut struct, IDiamondCut.FacetCut[].
     */
    function getUpgrade(bytes32 id) external view returns (uint256 expiry);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { MarketInfo, TradingCommissions, TradingCommissionsBasisPoints } from "./FreeStructs.sol";

/**
 * @title Matching Market (inspired by MakerOTC: https://github.com/nayms/maker-otc/blob/master/contracts/matching_market.sol)
 * @notice Trade entity tokens
 * @dev This should only be called through an entity, never directly by an EOA
 */
interface IMarketFacet {
    /**
     * @notice Execute a limit offer.
     *
     * @param _sellToken Token to sell.
     * @param _sellAmount Amount to sell.
     * @param _buyToken Token to buy.
     * @param _buyAmount Amount to buy.
     * @return offerId_ returns >0 if a limit offer was created on the market because the offer couldn't be totally fulfilled immediately. In this case the return value is the created offer's id.
     * @return buyTokenCommissionsPaid_ The amount of the buy token paid as commissions on this particular order.
     * @return sellTokenCommissionsPaid_ The amount of the sell token paid as commissions on this particular order.
     */
    function executeLimitOffer(
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount
    )
        external
        returns (
            uint256 offerId_,
            uint256 buyTokenCommissionsPaid_,
            uint256 sellTokenCommissionsPaid_
        );

    /**
     * @notice Cancel offer #`_offerId`. This will cancel the offer so that it's no longer active.
     *
     * @dev This function can be frontrun: In the scenario where a user wants to cancel an unfavorable market offer, an attacker can potentially monitor and identify
     *       that the user has called this method, determine that filling this market offer is profitable, and as a result call executeLimitOffer with a higher gas price to have
     *       their transaction filled before the user can have cancelOffer filled. The most ideal situation for the user is to not have placed the unfavorable market offer
     *       in the first place since an attacker can always monitor our marketplace and potentially identify profitable market offers. Our UI will aide users in not placing
     *       market offers that are obviously unfavorable to the user and/or seem like mistake orders. In the event that a user needs to cancel an offer, it is recommended to
     *       use Flashbots in order to privately send your transaction so an attack cannot be triggered from monitoring the mempool for calls to cancelOffer. A user is recommended
     *       to change their RPC endpoint to point to https://rpc.flashbots.net when calling cancelOffer. We will add additional documentation to aide our users in this process.
     *       More information on using Flashbots: https://docs.flashbots.net/flashbots-protect/rpc/quick-start/
     *
     * @param _offerId offer ID
     */
    function cancelOffer(uint256 _offerId) external;

    /**
     * @notice Get current best offer for given token pair.
     *
     * @dev This means finding the highest sellToken-per-buyToken price, i.e. price = sellToken / buyToken
     *
     * @return offerId, or 0 if no current best is available.
     */
    function getBestOfferId(bytes32 _sellToken, bytes32 _buyToken) external view returns (uint256);

    /**
     * @dev Get last created offer.
     *
     * @return offer id.
     */
    function getLastOfferId() external view returns (uint256);

    /**
     * @dev Get the details of the offer #`_offerId`
     * @param _offerId ID of a particular offer
     * @return _offerState details of the offer
     */
    function getOffer(uint256 _offerId) external view returns (MarketInfo memory _offerState);

    /**
     * @dev Check if the offer #`_offerId` is active or not.
     * @param _offerId ID of a particular offer
     * @return active or not
     */
    function isActiveOffer(uint256 _offerId) external view returns (bool);

    /**
     * @dev Calculate the trading commissions based on a buy amount.
     * @param buyAmount The amount that the commissions payments are calculated from.
     * @return tc TradingCommissions struct with metadata regarding the trade commission payment amounts.
     */
    function calculateTradingCommissions(uint256 buyAmount) external view returns (TradingCommissions memory tc);

    /**
     * @notice Get the marketplace's trading commissions basis points.
     * @return bp - TradingCommissionsBasisPoints struct containing the individual basis points set for each marketplace commission receiver.
     */
    function getTradingCommissionsBasisPoints() external view returns (TradingCommissionsBasisPoints memory bp);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Nayms token facet.
 * @dev Use it to access and manipulate Nayms token.
 */
interface INaymsTokenFacet {
    /**
     * @dev Get total supply of token.
     * @return total supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Get token balance of given wallet.
     * @param addr wallet whose balance to get.
     * @return balance of wallet.
     */
    function balanceOf(address addr) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { SimplePolicy, SimplePolicyInfo, PolicyCommissionsBasisPoints } from "./FreeStructs.sol";

/**
 * @title Simple Policies
 * @notice Facet for working with Simple Policies
 * @dev Simple Policy facet
 */
interface ISimplePolicyFacet {
    /**
     * @dev Generate a simple policy hash for singing by the stakeholders
     * @param _startDate Date when policy becomes active
     * @param _maturationDate Date after which policy becomes matured
     * @param _asset ID of the underlying asset, used as collateral and to pay out claims
     * @param _limit Policy coverage limit
     * @param _offchainDataHash Hash of all the important policy data stored offchain
     * @return signingHash_ hash for signing
     */
    function getSigningHash(
        uint256 _startDate,
        uint256 _maturationDate,
        bytes32 _asset,
        uint256 _limit,
        bytes32 _offchainDataHash
    ) external view returns (bytes32 signingHash_);

    /**
     * @dev Pay a premium of `_amount` on simple policy
     * @param _policyId Id of the simple policy
     * @param _amount Amount of the premium
     */
    function paySimplePremium(bytes32 _policyId, uint256 _amount) external;

    /**
     * @dev Pay a claim of `_amount` for simple policy
     * @param _claimId Id of the simple policy claim
     * @param _policyId Id of the simple policy
     * @param _insuredId Id of the insured party
     * @param _amount Amount of the claim
     */
    function paySimpleClaim(
        bytes32 _claimId,
        bytes32 _policyId,
        bytes32 _insuredId,
        uint256 _amount
    ) external;

    /**
     * @dev Get simple policy info
     * @param _id Id of the simple policy
     * @return Simple policy metadata
     */
    function getSimplePolicyInfo(bytes32 _id) external view returns (SimplePolicyInfo memory);

    /**
     * @notice Get the policy premium commissions basis points.
     * @return PolicyCommissionsBasisPoints struct containing the individual basis points set for each policy commission receiver.
     */
    function getPremiumCommissionBasisPoints() external view returns (PolicyCommissionsBasisPoints memory);

    /**
     * @dev Check and update simple policy state
     * @param _id Id of the simple policy
     */
    function checkAndUpdateSimplePolicyState(bytes32 _id) external;

    /**
     * @dev Cancel a simple policy
     * @param _policyId Id of the simple policy
     */
    function cancelSimplePolicy(bytes32 _policyId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { Entity } from "./FreeStructs.sol";

/**
 * @title System
 * @notice Use it to perform system level operations
 * @dev Use it to perform system level operations
 */
interface ISystemFacet {
    /**
     * @notice Create an entity
     * @dev An entity can be created with a zero max capacity! This is in the event where an entity cannot write any policies.
     * @param _entityId Unique ID for the entity
     * @param _entityAdmin Unique ID of the entity administrator
     * @param _entityData remaining entity metadata
     * @param _dataHash hash of the offchain data
     */
    function createEntity(
        bytes32 _entityId,
        bytes32 _entityAdmin,
        Entity memory _entityData,
        bytes32 _dataHash
    ) external;

    /**
     * @notice Convert a string type to a bytes32 type
     * @param _strIn a string
     */
    function stringToBytes32(string memory _strIn) external pure returns (bytes32 result);

    /**
     * @dev Get whether given id is an object in the system.
     * @param _id object id.
     * @return true if it is an object, false otherwise
     */
    function isObject(bytes32 _id) external view returns (bool);

    /**
     * @dev Get meta of given object.
     * @param _id object id.
     * @return parent object parent
     * @return dataHash object data hash
     * @return tokenSymbol object token symbol
     * @return tokenName object token name
     * @return tokenWrapper object token ERC20 wrapper address
     */
    function getObjectMeta(bytes32 _id)
        external
        view
        returns (
            bytes32 parent,
            bytes32 dataHash,
            string memory tokenSymbol,
            string memory tokenName,
            address tokenWrapper
        );

    /**
     * @notice Wrap an object token as ERC20
     * @param _objectId ID of the tokenized object
     */
    function wrapToken(bytes32 _objectId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ITokenizedVaultFacet {
    /**
     * @notice Gets balance of an account within platform
     * @dev Internal balance for given account
     * @param tokenId Internal ID of the asset
     * @return current balance
     */
    function internalBalanceOf(bytes32 accountId, bytes32 tokenId) external view returns (uint256);

    /**
     * @notice Current supply for the asset
     * @dev Total supply of platform asset
     * @param tokenId Internal ID of the asset
     * @return current balance
     */
    function internalTokenSupply(bytes32 tokenId) external view returns (uint256);

    /**
     * @notice Internal transfer of `amount` tokens
     * @dev Transfer tokens internally
     * @param to token receiver
     * @param tokenId Internal ID of the token
     */
    function internalTransferFromEntity(
        bytes32 to,
        bytes32 tokenId,
        uint256 amount
    ) external;

    /**
     * @notice Internal transfer of `amount` tokens `from` -> `to`
     * @dev Transfer tokens internally between two IDs
     * @param from token sender
     * @param to token receiver
     * @param tokenId Internal ID of the token
     */
    function wrapperInternalTransferFrom(
        bytes32 from,
        bytes32 to,
        bytes32 tokenId,
        uint256 amount
    ) external;

    function internalBurn(
        bytes32 from,
        bytes32 tokenId,
        uint256 amount
    ) external;

    /**
     * @notice Get withdrawable dividend amount
     * @dev Divident available for an entity to withdraw
     * @param _entityId Unique ID of the entity
     * @param _tokenId Unique ID of token
     * @param _dividendTokenId Unique ID of dividend token
     * @return _entityPayout accumulated dividend
     */
    function getWithdrawableDividend(
        bytes32 _entityId,
        bytes32 _tokenId,
        bytes32 _dividendTokenId
    ) external view returns (uint256 _entityPayout);

    /**
     * @notice Withdraw available dividend
     * @dev Transfer dividends to the entity
     * @param ownerId Unique ID of the dividend receiver
     * @param tokenId Unique ID of token
     * @param dividendTokenId Unique ID of dividend token
     */
    function withdrawDividend(
        bytes32 ownerId,
        bytes32 tokenId,
        bytes32 dividendTokenId
    ) external;

    /**
     * @notice Withdraws a user's available dividends.
     * @dev Dividends can be available in more than one dividend denomination. This method will withdraw all available dividends in the different dividend denominations.
     * @param ownerId Unique ID of the dividend receiver
     * @param tokenId Unique ID of token
     */
    function withdrawAllDividends(bytes32 ownerId, bytes32 tokenId) external;

    /**
     * @notice Pay `amount` of dividends
     * @dev Transfer dividends to the entity
     * @param guid Globally unique identifier of a dividend distribution.
     * @param amount the mamount of the dividend token to be distributed to NAYMS token holders.
     */
    function payDividendFromEntity(bytes32 guid, uint256 amount) external;

    /**
     * @notice Get the amount of tokens that an entity has for sale in the marketplace.
     * @param _entityId  Unique platform ID of the entity.
     * @param _tokenId The ID assigned to an external token.
     * @return amount of tokens that the entity has for sale in the marketplace.
     */
    function getLockedBalance(bytes32 _entityId, bytes32 _tokenId) external view returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Token Vault IO
 * @notice External interface to the Token Vault
 * @dev Used for external transfers. Adaptation of ERC-1155 that uses AppStorage and aligns with Nayms ACL implementation.
 *      https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC1155
 */
interface ITokenizedVaultIOFacet {
    /**
     * @notice Deposit funds into msg.sender's Nayms platform entity
     * @dev Deposit from msg.sender to their associated entity
     * @param _externalTokenAddress Token address
     * @param _amount deposit amount
     */
    function externalDeposit(address _externalTokenAddress, uint256 _amount) external;

    /**
     * @notice Withdraw funds out of Nayms platform
     * @dev Withdraw from entity to an external account
     * @param _entityId Internal ID of the entity the user is withdrawing from
     * @param _receiverId Internal ID of the account receiving the funds
     * @param _externalTokenAddress Token address
     * @param _amount amount to withdraw
     */
    function externalWithdrawFromEntity(
        bytes32 _entityId,
        address _receiverId,
        address _externalTokenAddress,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Users
 * @notice Manage user entity
 * @dev Use manage user entity
 */
interface IUserFacet {
    /**
     * @notice Get the platform ID of `addr` account
     * @dev Convert address to platform ID
     * @param addr Account address
     * @return userId Unique platform ID
     */
    function getUserIdFromAddress(address addr) external pure returns (bytes32 userId);

    /**
     * @notice Get the token address from ID of the external token
     * @dev Convert the bytes32 external token ID to its respective ERC20 contract address
     * @param _externalTokenId The ID assigned to an external token
     * @return tokenAddress Contract address
     */
    function getAddressFromExternalTokenId(bytes32 _externalTokenId) external pure returns (address tokenAddress);

    /**
     * @notice Set the entity for the user
     * @dev Assign the user an entity. The entity must exist in order to associate it with a user.
     * @param _userId Unique platform ID of the user account
     * @param _entityId Unique platform ID of the entity
     */
    function setEntity(bytes32 _userId, bytes32 _entityId) external;

    /**
     * @notice Get the entity for the user
     * @dev Gets the entity related to the user
     * @param _userId Unique platform ID of the user account
     * @return entityId Unique platform ID of the entity
     */
    function getEntity(bytes32 _userId) external view returns (bytes32 entityId);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibObject } from "./LibObject.sol";
import { LibConstants } from "./LibConstants.sol";
import { RoleIsMissing, AssignerGroupIsMissing } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

library LibACL {
    /**
     * @dev Emitted when a role gets updated. Empty roleId is assigned upon role removal
     * @param objectId The user or object that was assigned the role.
     * @param contextId The context where the role was assigned to.
     * @param assignedRoleId The ID of the role which got (un)assigned. (empty ID when unassigned)
     * @param functionName The function performing the action
     */
    event RoleUpdate(bytes32 indexed objectId, bytes32 contextId, bytes32 assignedRoleId, string functionName);
    /**
     * @dev Emitted when a role group gets updated.
     * @param role The role name.
     * @param group the group name.
     * @param roleInGroup whether the role is now in the group or not.
     */
    event RoleGroupUpdated(string role, string group, bool roleInGroup);
    /**
     * @dev Emitted when a role assigners gets updated.
     * @param role The role name.
     * @param group the name of the group that can now assign this role.
     */
    event RoleCanAssignUpdated(string role, string group);

    function _assignRole(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _roleId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_objectId != "", "invalid object ID");
        require(_contextId != "", "invalid context ID");
        require(_roleId != "", "invalid role ID");

        s.roles[_objectId][_contextId] = _roleId;

        if (_contextId == LibAdmin._getSystemId() && _roleId == LibHelpers._stringToBytes32(LibConstants.ROLE_SYSTEM_ADMIN)) {
            unchecked {
                s.sysAdmins += 1;
            }
        }

        emit RoleUpdate(_objectId, _contextId, _roleId, "_assignRole");
    }

    function _unassignRole(bytes32 _objectId, bytes32 _contextId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 roleId = s.roles[_objectId][_contextId];
        if (_contextId == LibAdmin._getSystemId() && roleId == LibHelpers._stringToBytes32(LibConstants.ROLE_SYSTEM_ADMIN)) {
            require(s.sysAdmins > 1, "must have at least one system admin");
            unchecked {
                s.sysAdmins -= 1;
            }
        }

        emit RoleUpdate(_objectId, _contextId, s.roles[_objectId][_contextId], "_unassignRole");
        delete s.roles[_objectId][_contextId];
    }

    function _isInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _groupId
    ) internal view returns (bool ret) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Check for the role in the context
        bytes32 objectRoleInContext = s.roles[_objectId][_contextId];

        if (objectRoleInContext != 0 && s.groups[objectRoleInContext][_groupId]) {
            ret = true;
        } else {
            // A role in the context of the system covers all objects
            bytes32 objectRoleInSystem = s.roles[_objectId][LibAdmin._getSystemId()];

            if (objectRoleInSystem != 0 && s.groups[objectRoleInSystem][_groupId]) {
                ret = true;
            }
        }
    }

    function _isParentInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _groupId
    ) internal view returns (bool) {
        bytes32 parentId = LibObject._getParent(_objectId);
        return _isInGroup(parentId, _contextId, _groupId);
    }

    /**
     * @notice Checks if assigner has the authority to assign object to a role in given context
     * @dev Any object ID can be a context, system is a special context with highest priority
     * @param _assignerId ID of an account wanting to assign a role to an object
     * @param _objectId ID of an object that is being assigned a role
     * @param _contextId ID of the context in which a role is being assigned
     * @param _roleId ID of a role being assigned
     */
    function _canAssign(
        bytes32 _assignerId,
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _roleId
    ) internal view returns (bool) {
        // we might impose additional restrictions on _objectId in the future
        require(_objectId != "", "invalid object ID");

        bool ret = false;
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 assignerGroup = s.canAssign[_roleId];

        // assigners group undefined
        if (assignerGroup == 0) {
            ret = false;
        }
        // Check for assigner's group membership in given context
        else if (_isInGroup(_assignerId, _contextId, assignerGroup)) {
            ret = true;
        }
        // Otherwise, check his parent's membership in system context
        // if account itself does not have the membership in given context, then having his parent
        // in the system context grants him the privilege needed
        else if (_isParentInGroup(_assignerId, LibAdmin._getSystemId(), assignerGroup)) {
            ret = true;
        }

        return ret;
    }

    function _getRoleInContext(bytes32 _objectId, bytes32 _contextId) internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.roles[_objectId][_contextId];
    }

    function _isRoleInGroup(string memory role, string memory group) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.groups[LibHelpers._stringToBytes32(role)][LibHelpers._stringToBytes32(group)];
    }

    function _canGroupAssignRole(string memory role, string memory group) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.canAssign[LibHelpers._stringToBytes32(role)] == LibHelpers._stringToBytes32(group);
    }

    function _updateRoleAssigner(string memory _role, string memory _assignerGroup) internal {
        if (bytes32(bytes(_role)) == "") {
            revert RoleIsMissing();
        }
        if (bytes32(bytes(_assignerGroup)) == "") {
            revert AssignerGroupIsMissing();
        }
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.canAssign[LibHelpers._stringToBytes32(_role)] = LibHelpers._stringToBytes32(_assignerGroup);
        emit RoleCanAssignUpdated(_role, _assignerGroup);
    }

    function _updateRoleGroup(
        string memory _role,
        string memory _group,
        bool _roleInGroup
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (bytes32(bytes(_role)) == "") {
            revert RoleIsMissing();
        }
        if (bytes32(bytes(_group)) == "") {
            revert AssignerGroupIsMissing();
        }

        s.groups[LibHelpers._stringToBytes32(_role)][LibHelpers._stringToBytes32(_group)] = _roleInGroup;
        emit RoleGroupUpdated(_role, _group, _roleInGroup);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibERC20 } from "src/erc20/LibERC20.sol";

import { CannotAddNullDiscountToken, CannotAddNullSupportedExternalToken, CannotSupportExternalTokenWithMoreThan18Decimals } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

library LibAdmin {
    event MaxDividendDenominationsUpdated(uint8 oldMax, uint8 newMax);
    event SupportedTokenAdded(address tokenAddress);

    function _getSystemId() internal pure returns (bytes32) {
        return LibHelpers._stringToBytes32(LibConstants.SYSTEM_IDENTIFIER);
    }

    function _getEmptyId() internal pure returns (bytes32) {
        return LibHelpers._stringToBytes32(LibConstants.EMPTY_IDENTIFIER);
    }

    function _updateMaxDividendDenominations(uint8 _newMaxDividendDenominations) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_newMaxDividendDenominations > s.maxDividendDenominations, "_updateMaxDividendDenominations: cannot reduce");
        uint8 old = s.maxDividendDenominations;
        s.maxDividendDenominations = _newMaxDividendDenominations;

        emit MaxDividendDenominationsUpdated(old, _newMaxDividendDenominations);
    }

    function _getMaxDividendDenominations() internal view returns (uint8) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.maxDividendDenominations;
    }

    function _isSupportedExternalTokenAddress(address _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.externalTokenSupported[_tokenId];
    }

    function _isSupportedExternalToken(bytes32 _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.externalTokenSupported[LibHelpers._getAddressFromId(_tokenId)];
    }

    function _addSupportedExternalToken(address _tokenAddress) internal {
        if (LibERC20.decimals(_tokenAddress) > 18) {
            revert CannotSupportExternalTokenWithMoreThan18Decimals();
        }
        AppStorage storage s = LibAppStorage.diamondStorage();

        bool alreadyAdded = s.externalTokenSupported[_tokenAddress];
        if (!alreadyAdded) {
            s.externalTokenSupported[_tokenAddress] = true;
            LibObject._createObject(LibHelpers._getIdForAddress(_tokenAddress));
            s.supportedExternalTokens.push(_tokenAddress);
            emit SupportedTokenAdded(_tokenAddress);
        }
    }

    function _getSupportedExternalTokens() internal view returns (address[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Supported tokens cannot be removed because they may exist in the system!
        return s.supportedExternalTokens;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev Settings keys.
 */
library LibConstants {
    //Reserved IDs
    string internal constant EMPTY_IDENTIFIER = "";
    string internal constant SYSTEM_IDENTIFIER = "System";
    string internal constant NDF_IDENTIFIER = "NDF";
    string internal constant STM_IDENTIFIER = "Staking Mechanism";
    string internal constant SSF_IDENTIFIER = "SSF";
    string internal constant NAYM_TOKEN_IDENTIFIER = "NAYM"; //This is the ID in the system as well as the token ID
    string internal constant DIVIDEND_BANK_IDENTIFIER = "Dividend Bank"; //This will hold all the dividends
    string internal constant NAYMS_LTD_IDENTIFIER = "Nayms Ltd";

    //Roles
    string internal constant ROLE_SYSTEM_ADMIN = "System Admin";
    string internal constant ROLE_SYSTEM_MANAGER = "System Manager";
    string internal constant ROLE_ENTITY_ADMIN = "Entity Admin";
    string internal constant ROLE_ENTITY_MANAGER = "Entity Manager";
    string internal constant ROLE_BROKER = "Broker";
    string internal constant ROLE_INSURED_PARTY = "Insured";
    string internal constant ROLE_UNDERWRITER = "Underwriter";
    string internal constant ROLE_CAPITAL_PROVIDER = "Capital Provider";
    string internal constant ROLE_CLAIMS_ADMIN = "Claims Admin";
    string internal constant ROLE_TRADER = "Trader";
    string internal constant ROLE_SEGREGATED_ACCOUNT = "Segregated Account";
    string internal constant ROLE_SERVICE_PROVIDER = "Service Provider";

    //Groups
    string internal constant GROUP_SYSTEM_ADMINS = "System Admins";
    string internal constant GROUP_SYSTEM_MANAGERS = "System Managers";
    string internal constant GROUP_ENTITY_ADMINS = "Entity Admins";
    string internal constant GROUP_ENTITY_MANAGERS = "Entity Managers";
    string internal constant GROUP_APPROVED_USERS = "Approved Users";
    string internal constant GROUP_BROKERS = "Brokers";
    string internal constant GROUP_INSURED_PARTIES = "Insured Parties";
    string internal constant GROUP_UNDERWRITERS = "Underwriters";
    string internal constant GROUP_CAPITAL_PROVIDERS = "Capital Providers";
    string internal constant GROUP_CLAIMS_ADMINS = "Claims Admins";
    string internal constant GROUP_TRADERS = "Traders";
    string internal constant GROUP_SEGREGATED_ACCOUNTS = "Segregated Accounts";
    string internal constant GROUP_SERVICE_PROVIDERS = "Service Providers";
    string internal constant GROUP_POLICY_HANDLERS = "Policy Handlers";

    /*///////////////////////////////////////////////////////////////////////////
                        Market Fee Schedules
    ///////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Standard fee is charged.
     */
    uint256 internal constant FEE_SCHEDULE_STANDARD = 1;
    /**
     * @dev Platform-initiated trade, e.g. token sale or buyback.
     */
    uint256 internal constant FEE_SCHEDULE_PLATFORM_ACTION = 2;

    /*///////////////////////////////////////////////////////////////////////////
                        MARKET OFFER STATES
    ///////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant OFFER_STATE_ACTIVE = 1;
    uint256 internal constant OFFER_STATE_CANCELLED = 2;
    uint256 internal constant OFFER_STATE_FULFILLED = 3;

    uint256 internal constant DUST = 1;
    uint256 internal constant BP_FACTOR = 10000;

    /*///////////////////////////////////////////////////////////////////////////
                        SIMPLE POLICY STATES
    ///////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant SIMPLE_POLICY_STATE_CREATED = 0;
    uint256 internal constant SIMPLE_POLICY_STATE_APPROVED = 1;
    uint256 internal constant SIMPLE_POLICY_STATE_ACTIVE = 2;
    uint256 internal constant SIMPLE_POLICY_STATE_MATURED = 3;
    uint256 internal constant SIMPLE_POLICY_STATE_CANCELLED = 4;
    uint256 internal constant STAKING_WEEK = 7 days;
    uint256 internal constant STAKING_MINTIME = 60 days; // 60 days min lock
    uint256 internal constant STAKING_MAXTIME = 4 * 365 days; // 4 years max lock
    uint256 internal constant SCALE = 1e18; //10 ^ 18

    /// _depositFor Types for events
    int128 internal constant STAKING_DEPOSIT_FOR_TYPE = 0;
    int128 internal constant STAKING_CREATE_LOCK_TYPE = 1;
    int128 internal constant STAKING_INCREASE_LOCK_AMOUNT = 2;
    int128 internal constant STAKING_INCREASE_UNLOCK_TIME = 3;

    string internal constant VE_NAYM_NAME = "veNAYM";
    string internal constant VE_NAYM_SYMBOL = "veNAYM";
    uint8 internal constant VE_NAYM_DECIMALS = 18;
    uint8 internal constant INTERNAL_TOKEN_DECIMALS = 18;
    address internal constant DAI_CONSTANT = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library LibEIP712 {
    function _domainSeparatorV4() internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return block.chainid == s.initialChainId ? s.initialDomainSeparator : _computeDomainSeparator();
    }

    function _computeDomainSeparator() internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(s.name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    function _hashTypedDataV4(bytes32 structHash) internal view returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LibAppStorage, AppStorage } from "../AppStorage.sol";
import { Entity, SimplePolicy, Stakeholders } from "../AppStorage.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibACL } from "./LibACL.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibMarket } from "./LibMarket.sol";
import { LibSimplePolicy } from "./LibSimplePolicy.sol";
import { LibEIP712 } from "src/diamonds/nayms/libs/LibEIP712.sol";

import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import { EntityDoesNotExist, DuplicateSignerCreatingSimplePolicy, PolicyIdCannotBeZero, ObjectCannotBeTokenized, CreatingEntityThatAlreadyExists, SimplePolicyStakeholderSignatureInvalid, SimplePolicyClaimsPaidShouldStartAtZero, SimplePolicyPremiumsPaidShouldStartAtZero, CancelCannotBeTrueWhenCreatingSimplePolicy, UtilizedCapacityGreaterThanMaxCapacity } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

library LibEntity {
    using ECDSA for bytes32;
    /**
     * @notice New entity has been created
     * @dev Thrown when entity is created
     * @param entityId Unique ID for the entity
     * @param entityAdmin Unique ID of the entity administrator
     */
    event EntityCreated(bytes32 indexed entityId, bytes32 entityAdmin);
    event EntityUpdated(bytes32 indexed entityId);
    event SimplePolicyCreated(bytes32 indexed id, bytes32 entityId);
    event TokenSaleStarted(bytes32 indexed entityId, uint256 offerId, string tokenSymbol, string tokenName);
    event CollateralRatioUpdated(bytes32 indexed entityId, uint256 collateralRatio, uint256 utilizedCapacity);

    /**
     * @dev If an entity passes their checks to create a policy, ensure that the entity's capacity is appropriately decreased by the amount of capital that will be tied to the new policy being created.
     */
    function _validateSimplePolicyCreation(bytes32 _entityId, SimplePolicy calldata simplePolicy) internal view {
        // The policy's limit cannot be 0. If a policy's limit is zero, this essentially means the policy doesn't require any capital, which doesn't make business sense.
        require(simplePolicy.limit > 0, "limit not > 0");
        require(LibAdmin._isSupportedExternalToken(simplePolicy.asset), "external token is not supported");

        if (simplePolicy.claimsPaid != 0) {
            revert SimplePolicyClaimsPaidShouldStartAtZero();
        }
        if (simplePolicy.premiumsPaid != 0) {
            revert SimplePolicyPremiumsPaidShouldStartAtZero();
        }
        if (simplePolicy.cancelled) {
            revert CancelCannotBeTrueWhenCreatingSimplePolicy();
        }
        AppStorage storage s = LibAppStorage.diamondStorage();
        Entity memory entity = s.entities[_entityId];

        require(LibAdmin._isSupportedExternalToken(simplePolicy.asset), "external token is not supported");
        require(simplePolicy.asset == entity.assetId, "asset not matching with entity");

        // Calculate the entity's utilized capacity after it writes this policy.
        uint256 updatedUtilizedCapacity = entity.utilizedCapacity + ((simplePolicy.limit * entity.collateralRatio) / LibConstants.BP_FACTOR);

        // The entity must have enough capacity available to write this policy.
        // An entity is not able to write an additional policy that will utilize its capacity beyond its assigned max capacity.
        require(entity.maxCapacity >= updatedUtilizedCapacity, "not enough available capacity");

        // The entity's balance must be >= to the updated capacity requirement
        // todo: business only wants to count the entity's balance that was raised from the participation token sale and not its total balance
        require(LibTokenizedVault._internalBalanceOf(_entityId, simplePolicy.asset) >= updatedUtilizedCapacity, "not enough capital");

        require(simplePolicy.startDate >= block.timestamp, "start date < block.timestamp");
        require(simplePolicy.maturationDate > simplePolicy.startDate, "start date > maturation date");

        uint256 commissionReceiversArrayLength = simplePolicy.commissionReceivers.length;
        require(commissionReceiversArrayLength > 0, "must have commission receivers");

        uint256 commissionBasisPointsArrayLength = simplePolicy.commissionBasisPoints.length;
        require(commissionBasisPointsArrayLength > 0, "must have commission basis points");
        require(commissionReceiversArrayLength == commissionBasisPointsArrayLength, "commissions lengths !=");

        uint256 totalBP;
        for (uint256 i; i < commissionBasisPointsArrayLength; ++i) {
            totalBP += simplePolicy.commissionBasisPoints[i];
        }
        require(totalBP <= LibConstants.BP_FACTOR, "bp cannot be > 10000");
    }

    function _createSimplePolicy(
        bytes32 _policyId,
        bytes32 _entityId,
        Stakeholders calldata _stakeholders,
        SimplePolicy calldata _simplePolicy,
        bytes32 _offchainDataHash
    ) internal {
        if (_policyId == 0) {
            revert PolicyIdCannotBeZero();
        }

        AppStorage storage s = LibAppStorage.diamondStorage();
        if (!s.existingEntities[_entityId]) {
            revert EntityDoesNotExist(_entityId);
        }
        require(_stakeholders.entityIds.length == _stakeholders.signatures.length, "incorrect number of signatures");

        _validateSimplePolicyCreation(_entityId, _simplePolicy);

        Entity storage entity = s.entities[_entityId];
        uint256 factoredLimit = (_simplePolicy.limit * entity.collateralRatio) / LibConstants.BP_FACTOR;

        entity.utilizedCapacity += factoredLimit;
        s.lockedBalances[_entityId][entity.assetId] += factoredLimit;

        // hash contents are implicitlly checked by making sure that resolved signer is the stakeholder entity's admin
        bytes32 signingHash = LibSimplePolicy._getSigningHash(_simplePolicy.startDate, _simplePolicy.maturationDate, _simplePolicy.asset, _simplePolicy.limit, _offchainDataHash);

        LibObject._createObject(_policyId, _entityId, signingHash);
        s.simplePolicies[_policyId] = _simplePolicy;
        s.simplePolicies[_policyId].fundsLocked = true;

        uint256 rolesCount = _stakeholders.roles.length;
        address signer;
        address previousSigner;

        for (uint256 i = 0; i < rolesCount; i++) {
            previousSigner = signer;

            signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(signingHash), _stakeholders.signatures[i]);

            // Ensure there are no duplicate signers.
            if (previousSigner >= signer) {
                revert DuplicateSignerCreatingSimplePolicy(previousSigner, signer);
            }

            if (LibObject._getParentFromAddress(signer) != _stakeholders.entityIds[i]) {
                revert SimplePolicyStakeholderSignatureInvalid(
                    signingHash,
                    _stakeholders.signatures[i],
                    LibHelpers._getIdForAddress(signer),
                    LibObject._getParentFromAddress(signer),
                    _stakeholders.entityIds[i]
                );
            }
            LibACL._assignRole(_stakeholders.entityIds[i], _policyId, _stakeholders.roles[i]);
        }

        s.existingSimplePolicies[_policyId] = true;
        emit SimplePolicyCreated(_policyId, _entityId);
    }

    /// @param _amount the amount of entity token that is minted and put on sale
    /// @param _totalPrice the buy amount
    function _startTokenSale(
        bytes32 _entityId,
        uint256 _amount,
        uint256 _totalPrice
    ) internal {
        require(_amount > 0, "mint amount must be > 0");
        require(_totalPrice > 0, "total price must be > 0");
        require(LibObject._isObjectTokenizable(_entityId), "must be tokenizable");

        AppStorage storage s = LibAppStorage.diamondStorage();

        if (!s.existingEntities[_entityId]) {
            revert EntityDoesNotExist(_entityId);
        }

        if (!LibObject._isObjectTokenizable(_entityId)) {
            revert ObjectCannotBeTokenized(_entityId);
        }

        Entity memory entity = s.entities[_entityId];

        // note: The participation tokens of the entity are minted to the entity. The participation tokens minted have the same ID as the entity.
        LibTokenizedVault._internalMint(_entityId, _entityId, _amount);

        (uint256 offerId, , ) = LibMarket._executeLimitOffer(_entityId, _entityId, _amount, entity.assetId, _totalPrice, LibConstants.FEE_SCHEDULE_STANDARD);

        emit TokenSaleStarted(_entityId, offerId, s.objectTokenSymbol[_entityId], s.objectTokenName[_entityId]);
    }

    function _createEntity(
        bytes32 _entityId,
        bytes32 _entityAdmin,
        Entity memory _entity,
        bytes32 _dataHash
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (s.existingEntities[_entityId]) {
            revert CreatingEntityThatAlreadyExists(_entityId);
        }
        validateEntity(_entity);

        LibObject._createObject(_entityId, _dataHash);
        LibObject._setParent(_entityAdmin, _entityId);
        s.existingEntities[_entityId] = true;

        LibACL._assignRole(_entityAdmin, _entityId, LibHelpers._stringToBytes32(LibConstants.ROLE_ENTITY_ADMIN));

        // An entity starts without any capacity being utilized
        require(_entity.utilizedCapacity == 0, "utilized capacity starts at 0");

        s.entities[_entityId] = _entity;

        emit EntityCreated(_entityId, _entityAdmin);
    }

    function _updateEntity(bytes32 _entityId, Entity memory _entity) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Cannot update a non-existing entity's metadata.
        if (!s.existingEntities[_entityId]) {
            revert EntityDoesNotExist(_entityId);
        }

        validateEntity(_entity);

        uint256 oldCollateralRatio = s.entities[_entityId].collateralRatio;
        uint256 oldUtilizedCapacity = s.entities[_entityId].utilizedCapacity;
        bytes32 originalAssetId = s.entities[_entityId].assetId;

        s.entities[_entityId] = _entity;
        s.entities[_entityId].assetId = originalAssetId; // assetId change not allowed

        // if it's a cell, and collateral ratio changed
        if (_entity.assetId != 0 && _entity.collateralRatio != oldCollateralRatio) {
            uint256 newUtilizedCapacity = (oldUtilizedCapacity * _entity.collateralRatio) / oldCollateralRatio;
            uint256 newLockedBalance = s.lockedBalances[_entityId][_entity.assetId] - oldUtilizedCapacity + newUtilizedCapacity;

            require(LibTokenizedVault._internalBalanceOf(_entityId, _entity.assetId) >= newLockedBalance, "collateral ratio invalid, not enough balance");

            s.entities[_entityId].utilizedCapacity = newUtilizedCapacity;
            s.lockedBalances[_entityId][_entity.assetId] = newLockedBalance;

            emit CollateralRatioUpdated(_entityId, _entity.collateralRatio, s.entities[_entityId].utilizedCapacity);
        }

        emit EntityUpdated(_entityId);
    }

    function validateEntity(Entity memory _entity) internal view {
        if (_entity.assetId != 0) {
            // entity has an underlying asset, which means it's a cell

            // External token must be whitelisted by the platform
            require(LibAdmin._isSupportedExternalToken(_entity.assetId), "external token is not supported");

            // Collateral ratio must be in acceptable range of 1 to 10000 basis points (0.01% to 100% collateralized).
            // Cannot ever be completely uncollateralized (0 basis points), if entity is a cell.
            require(1 <= _entity.collateralRatio && _entity.collateralRatio <= LibConstants.BP_FACTOR, "collateral ratio should be 1 to 10000");

            // Max capacity is the capital amount that an entity can write across all of their policies.
            // note: We do not directly use the value maxCapacity to determine if the entity can or cannot write a policy.
            //       First, we use the bool simplePolicyEnabled to toggle (enable / disable) whether an entity can or cannot write a policy.
            //       If an entity has this set to true, then we check if an entity has enough capacity to write a policy.
            require(!_entity.simplePolicyEnabled || (_entity.maxCapacity > 0), "max capacity should be greater than 0 for policy creation");

            if (_entity.utilizedCapacity > _entity.maxCapacity) {
                revert UtilizedCapacityGreaterThanMaxCapacity(_entity.utilizedCapacity, _entity.maxCapacity);
            }
        } else {
            // non-cell entity
            require(_entity.collateralRatio == 0, "only cell has collateral ratio");
            require(!_entity.simplePolicyEnabled, "only cell can issue policies");
            require(_entity.maxCapacity == 0, "only cells have max capacity");
        }
    }

    function _getEntityInfo(bytes32 _entityId) internal view returns (Entity memory entity) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        entity = s.entities[_entityId];
    }

    function _isEntity(bytes32 _entityId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.existingEntities[_entityId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage, SimplePolicy, PolicyCommissionsBasisPoints, TradingCommissions, TradingCommissionsBasisPoints } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { PolicyCommissionsBasisPointsCannotBeGreaterThan10000 } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

library LibFeeRouter {
    event TradingCommissionsPaid(bytes32 indexed takerId, bytes32 tokenId, uint256 amount);
    event PremiumCommissionsPaid(bytes32 indexed policyId, bytes32 indexed entityId, uint256 amount);

    function _payPremiumCommissions(bytes32 _policyId, uint256 _premiumPaid) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        SimplePolicy memory simplePolicy = s.simplePolicies[_policyId];
        bytes32 policyEntityId = LibObject._getParent(_policyId);

        uint256 commissionsCount = simplePolicy.commissionReceivers.length;
        for (uint256 i = 0; i < commissionsCount; i++) {
            uint256 commission = (_premiumPaid * simplePolicy.commissionBasisPoints[i]) / LibConstants.BP_FACTOR;
            LibTokenizedVault._internalTransfer(policyEntityId, simplePolicy.commissionReceivers[i], simplePolicy.asset, commission);
        }

        uint256 commissionNaymsLtd = (_premiumPaid * s.premiumCommissionNaymsLtdBP) / LibConstants.BP_FACTOR;
        uint256 commissionNDF = (_premiumPaid * s.premiumCommissionNDFBP) / LibConstants.BP_FACTOR;
        uint256 commissionSTM = (_premiumPaid * s.premiumCommissionSTMBP) / LibConstants.BP_FACTOR;

        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), simplePolicy.asset, commissionNaymsLtd);
        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), simplePolicy.asset, commissionNDF);
        LibTokenizedVault._internalTransfer(policyEntityId, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), simplePolicy.asset, commissionSTM);

        uint256 premiumCommissionPaid = commissionNaymsLtd + commissionNDF + commissionSTM;

        emit PremiumCommissionsPaid(_policyId, policyEntityId, premiumCommissionPaid);
    }

    function _payTradingCommissions(
        bytes32 _makerId,
        bytes32 _takerId,
        bytes32 _tokenId,
        uint256 _requestedBuyAmount
    ) internal returns (uint256 commissionPaid_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(s.tradingCommissionTotalBP <= LibConstants.BP_FACTOR, "commission total must be<=10000bp");
        require(
            s.tradingCommissionNaymsLtdBP + s.tradingCommissionNDFBP + s.tradingCommissionSTMBP + s.tradingCommissionMakerBP <= LibConstants.BP_FACTOR,
            "commissions sum over 10000 bp"
        );

        TradingCommissions memory tc = _calculateTradingCommissions(_requestedBuyAmount);
        // The rough commission deducted. The actual total might be different due to integer division

        // Pay Nayms, LTD commission
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.NAYMS_LTD_IDENTIFIER), _tokenId, tc.commissionNaymsLtd);

        // Pay Nayms Discretionsry Fund commission
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.NDF_IDENTIFIER), _tokenId, tc.commissionNDF);

        // Pay Staking Mechanism commission
        LibTokenizedVault._internalTransfer(_takerId, LibHelpers._stringToBytes32(LibConstants.STM_IDENTIFIER), _tokenId, tc.commissionSTM);

        // Pay market maker commission
        LibTokenizedVault._internalTransfer(_takerId, _makerId, _tokenId, tc.commissionMaker);

        // Work it out again so the math is precise, ignoring remainers
        commissionPaid_ = tc.totalCommissions;

        emit TradingCommissionsPaid(_takerId, _tokenId, commissionPaid_);
    }

    function _updateTradingCommissionsBasisPoints(TradingCommissionsBasisPoints calldata bp) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(
            bp.tradingCommissionNaymsLtdBP + bp.tradingCommissionNDFBP + bp.tradingCommissionSTMBP + bp.tradingCommissionMakerBP == LibConstants.BP_FACTOR,
            "trading commission BPs must sum up to 10000"
        );

        s.tradingCommissionTotalBP = bp.tradingCommissionTotalBP;
        s.tradingCommissionNaymsLtdBP = bp.tradingCommissionNaymsLtdBP;
        s.tradingCommissionNDFBP = bp.tradingCommissionNDFBP;
        s.tradingCommissionSTMBP = bp.tradingCommissionSTMBP;
        s.tradingCommissionMakerBP = bp.tradingCommissionMakerBP;
    }

    function _updatePolicyCommissionsBasisPoints(PolicyCommissionsBasisPoints calldata bp) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 totalBp = bp.premiumCommissionNaymsLtdBP + bp.premiumCommissionNDFBP + bp.premiumCommissionSTMBP;
        if (totalBp > LibConstants.BP_FACTOR) {
            revert PolicyCommissionsBasisPointsCannotBeGreaterThan10000(totalBp);
        }
        s.premiumCommissionNaymsLtdBP = bp.premiumCommissionNaymsLtdBP;
        s.premiumCommissionNDFBP = bp.premiumCommissionNDFBP;
        s.premiumCommissionSTMBP = bp.premiumCommissionSTMBP;
    }

    function _calculateTradingCommissions(uint256 buyAmount) internal view returns (TradingCommissions memory tc) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // The rough commission deducted. The actual total might be different due to integer division
        tc.roughCommissionPaid = (s.tradingCommissionTotalBP * buyAmount) / LibConstants.BP_FACTOR;

        // Pay Nayms, LTD commission
        tc.commissionNaymsLtd = (s.tradingCommissionNaymsLtdBP * tc.roughCommissionPaid) / LibConstants.BP_FACTOR;

        // Pay Nayms Discretionsry Fund commission
        tc.commissionNDF = (s.tradingCommissionNDFBP * tc.roughCommissionPaid) / LibConstants.BP_FACTOR;

        // Pay Staking Mechanism commission
        tc.commissionSTM = (s.tradingCommissionSTMBP * tc.roughCommissionPaid) / LibConstants.BP_FACTOR;

        // Pay market maker commission
        tc.commissionMaker = (s.tradingCommissionMakerBP * tc.roughCommissionPaid) / LibConstants.BP_FACTOR;

        // Work it out again so the math is precise, ignoring remainers
        tc.totalCommissions = tc.commissionNaymsLtd + tc.commissionNDF + tc.commissionSTM + tc.commissionMaker;
    }

    function _getTradingCommissionsBasisPoints() internal view returns (TradingCommissionsBasisPoints memory bp) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bp.tradingCommissionTotalBP = s.tradingCommissionTotalBP;
        bp.tradingCommissionNaymsLtdBP = s.tradingCommissionNaymsLtdBP;
        bp.tradingCommissionNDFBP = s.tradingCommissionNDFBP;
        bp.tradingCommissionSTMBP = s.tradingCommissionSTMBP;
        bp.tradingCommissionMakerBP = s.tradingCommissionMakerBP;
    }

    function _getPremiumCommissionBasisPoints() internal view returns (PolicyCommissionsBasisPoints memory bp) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bp.premiumCommissionNaymsLtdBP = s.premiumCommissionNaymsLtdBP;
        bp.premiumCommissionNDFBP = s.premiumCommissionNDFBP;
        bp.premiumCommissionSTMBP = s.premiumCommissionSTMBP;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Pure functions
library LibHelpers {
    function _getIdForObjectAtIndex(uint256 _index) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_index));
    }

    function _getIdForAddress(address _addr) internal pure returns (bytes32) {
        return bytes32(bytes20(_addr));
    }

    function _getSenderId() internal view returns (bytes32) {
        return _getIdForAddress(msg.sender);
    }

    function _getAddressFromId(bytes32 _id) internal pure returns (address) {
        return address(bytes20(_id));
    }

    // Conversion Utilities

    function _addressToBytes32(address addr) internal pure returns (bytes32) {
        return _bytesToBytes32(abi.encode(addr));
    }

    function _stringToBytes32(string memory strIn) internal pure returns (bytes32) {
        return _bytesToBytes32(bytes(strIn));
    }

    function _bytes32ToString(bytes32 bytesIn) internal pure returns (string memory) {
        return string(_bytes32ToBytes(bytesIn));
    }

    function _bytesToBytes32(bytes memory source) internal pure returns (bytes32 result) {
        if (source.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    function _bytes32ToBytes(bytes32 input) internal pure returns (bytes memory) {
        bytes memory b = new bytes(32);
        assembly {
            mstore(add(b, 32), input)
        }
        return b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { MarketInfo, TokenAmount, TradingCommissions } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibFeeRouter } from "./LibFeeRouter.sol";
import { LibEntity } from "./LibEntity.sol";

library LibMarket {
    struct MatchingOfferResult {
        uint256 remainingBuyAmount;
        uint256 remainingSellAmount;
        uint256 buyTokenCommissionsPaid;
        uint256 sellTokenCommissionsPaid;
    }

    /// @notice order has been added
    event OrderAdded(
        uint256 indexed orderId,
        bytes32 indexed maker,
        bytes32 indexed sellToken,
        uint256 sellAmount,
        uint256 sellAmountInitial,
        bytes32 buyToken,
        uint256 buyAmount,
        uint256 buyAmountInitial,
        uint256 state
    );

    /// @notice order has been executed
    event OrderExecuted(uint256 indexed orderId, bytes32 indexed taker, bytes32 indexed sellToken, uint256 sellAmount, bytes32 buyToken, uint256 buyAmount, uint256 state);

    /// @notice order has been cancelled
    event OrderCancelled(uint256 indexed orderId, bytes32 indexed taker, bytes32 sellToken);

    function _getBestOfferId(bytes32 _sellToken, bytes32 _buyToken) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return s.bestOfferId[_sellToken][_buyToken];
    }

    function _insertOfferIntoSortedList(uint256 _offerId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // check that offer is NOT in the sorted list
        require(!_isOfferInSortedList(_offerId), "offer already in sorted list");

        bytes32 sellToken = s.offers[_offerId].sellToken;
        bytes32 buyToken = s.offers[_offerId].buyToken;

        uint256 prevId;

        // find position of next highest offer
        uint256 top = s.bestOfferId[sellToken][buyToken];
        uint256 oldTop;

        while (top != 0 && _isOfferPricedLtOrEq(_offerId, top)) {
            oldTop = top;
            top = s.offers[top].rankPrev;
        }

        uint256 pos = oldTop;

        // insert offer at position
        if (pos != 0) {
            prevId = s.offers[pos].rankPrev;
            s.offers[pos].rankPrev = _offerId;
            s.offers[_offerId].rankNext = pos;
        }
        // else this is the new best offer, so insert at top
        else {
            prevId = s.bestOfferId[sellToken][buyToken];
            s.bestOfferId[sellToken][buyToken] = _offerId;
        }

        if (prevId != 0) {
            // requirement below is satisfied by statements above
            // require(!_isOfferPricedLtOrEq(_offerId, prevId));
            s.offers[prevId].rankNext = _offerId;
            s.offers[_offerId].rankPrev = prevId;
        }

        s.span[sellToken][buyToken]++;
    }

    function _removeOfferFromSortedList(uint256 _offerId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // check that offer is in the sorted list
        require(_isOfferInSortedList(_offerId), "offer not in sorted list");

        bytes32 sellToken = s.offers[_offerId].sellToken;
        bytes32 buyToken = s.offers[_offerId].buyToken;

        require(s.span[sellToken][buyToken] > 0, "token pair list does not exist");

        // if offer is not the highest offer
        if (_offerId != s.bestOfferId[sellToken][buyToken]) {
            uint256 nextId = s.offers[_offerId].rankNext;
            require(s.offers[nextId].rankPrev == _offerId, "sort check failed");
            s.offers[nextId].rankPrev = s.offers[_offerId].rankPrev;
        }
        // if offer is the highest offer
        else {
            s.bestOfferId[sellToken][buyToken] = s.offers[_offerId].rankPrev;
        }

        // if offer is not the lowest offer
        if (s.offers[_offerId].rankPrev != 0) {
            uint256 prevId = s.offers[_offerId].rankPrev;
            require(s.offers[prevId].rankNext == _offerId, "sort check failed");
            s.offers[prevId].rankNext = s.offers[_offerId].rankNext;
        }

        // nullify
        delete s.offers[_offerId].rankNext;
        delete s.offers[_offerId].rankPrev;

        s.span[sellToken][buyToken]--;
    }

    /**
     * @dev If the relative price of the sell token for offer1 ("low offer") is more expensive than the relative price of of the sell token for offer2 ("high offer"), then this returns true.
     *      If the sell token for offer1 is "more expensive", this means that one will need more sell token to buy the same amount of buy token when comparing relative prices of offer1 to offer2.
     */
    function _isOfferPricedLtOrEq(uint256 _lowOfferId, uint256 _highOfferId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 lowSellAmount = s.offers[_lowOfferId].sellAmount;
        uint256 lowBuyAmount = s.offers[_lowOfferId].buyAmount;

        uint256 highSellAmount = s.offers[_highOfferId].sellAmount;
        uint256 highBuyAmount = s.offers[_highOfferId].buyAmount;

        return lowBuyAmount * highSellAmount >= highBuyAmount * lowSellAmount;
    }

    function _isOfferInSortedList(uint256 _offerId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bytes32 sellToken = s.offers[_offerId].sellToken;
        bytes32 buyToken = s.offers[_offerId].buyToken;

        return _offerId != 0 && (s.offers[_offerId].rankNext != 0 || s.offers[_offerId].rankPrev != 0 || s.bestOfferId[sellToken][buyToken] == _offerId);
    }

    function _matchToExistingOffers(
        bytes32 _takerId,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount
    ) internal returns (MatchingOfferResult memory result) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        result.remainingBuyAmount = _buyAmount;
        result.remainingSellAmount = _sellAmount;

        // sell: p100 buy: $100 =>  YES! buy more
        // sell: $100 buy: p100 =>  NO! DON'T buy more

        // If the buyToken is entity(p-token)   => limit both buy and sell amounts
        // If the buyToken is external          => limit only sell amount

        bool buyExternalToken = s.externalTokenSupported[LibHelpers._getAddressFromId(_buyToken)];
        while (result.remainingSellAmount != 0 && (buyExternalToken || result.remainingBuyAmount != 0)) {
            // there is at least one offer stored for token pair
            uint256 bestOfferId = s.bestOfferId[_buyToken][_sellToken];
            if (bestOfferId == 0) {
                break; // no market liquidity, bail out
            }

            uint256 makerBuyAmount = s.offers[bestOfferId].buyAmount;
            uint256 makerSellAmount = s.offers[bestOfferId].sellAmount;

            // Check if best available price on the market is better or same,
            // as the one taker is willing to pay, within error margin of ±1.
            // This ugly hack is to work around rounding errors. Based on the idea that
            // the furthest the amounts can stray from their "true" values is 1.
            // Ergo the worst case has `sellAmount` and `makerSellAmount` at +1 away from
            // their "correct" values and `makerBuyAmount` and `buyAmount` at -1.
            // Since (c - 1) * (d - 1) > (a + 1) * (b + 1) is equivalent to
            // c * d > a * b + a + b + c + d
            // (For detailed breakdown see https://hiddentao.com/archives/2019/09/08/maker-otc-on-chain-orderbook-deep-dive)
            if (
                makerBuyAmount * result.remainingBuyAmount >
                result.remainingSellAmount * makerSellAmount + makerBuyAmount + result.remainingBuyAmount + result.remainingSellAmount + makerSellAmount
            ) {
                break; // no matching price, bail out
            }

            // ^ The `rounding` parameter is a compromise borne of a couple days of discussion.

            // avoid stack-too-deep
            {
                // take the offer
                uint256 currentSellAmount;
                uint256 currentBuyAmount;

                if (buyExternalToken) {
                    // the amount to be sold is
                    // if the amount that wants to be purchased is less than the remaining amount, then the amount to be sold is the amount that is desired to be purchased.
                    // otherwise, it's the amount that is remaining to be sold
                    currentSellAmount = s.offers[bestOfferId].buyAmount < result.remainingSellAmount ? s.offers[bestOfferId].buyAmount : result.remainingSellAmount;
                    currentBuyAmount = (currentSellAmount * s.offers[bestOfferId].sellAmount) / s.offers[bestOfferId].buyAmount; // (a / b) * c = c * a / b  -> multiply first, avoid underflow

                    //
                    uint256 commissionsPaid = _takeOffer(bestOfferId, _takerId, currentBuyAmount, currentSellAmount, buyExternalToken);
                    result.buyTokenCommissionsPaid += commissionsPaid;
                } else {
                    currentBuyAmount = s.offers[bestOfferId].sellAmount < result.remainingBuyAmount ? s.offers[bestOfferId].sellAmount : result.remainingBuyAmount;
                    currentSellAmount = (currentBuyAmount * s.offers[bestOfferId].buyAmount) / s.offers[bestOfferId].sellAmount; // (a / b) * c = c * a / b  -> multiply first, avoid underflow
                    uint256 commissionsPaid = _takeOffer(bestOfferId, _takerId, currentBuyAmount, currentSellAmount, buyExternalToken);
                    result.sellTokenCommissionsPaid += commissionsPaid;
                }
                // calculate how much is left to buy/sell
                result.remainingSellAmount -= currentSellAmount;
                result.remainingBuyAmount = currentBuyAmount > result.remainingBuyAmount ? 0 : result.remainingBuyAmount - currentBuyAmount;
            }
        }
    }

    function _createOffer(
        bytes32 _creator,
        bytes32 _sellToken,
        uint256 _sellAmount,
        uint256 _sellAmountInitial,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _buyAmountInitial,
        uint256 _feeSchedule
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 lastOfferId = ++s.lastOfferId;

        MarketInfo memory marketInfo;
        marketInfo.creator = _creator;
        marketInfo.sellToken = _sellToken;
        marketInfo.sellAmount = _sellAmount;
        marketInfo.sellAmountInitial = _sellAmountInitial;
        marketInfo.buyToken = _buyToken;
        marketInfo.buyAmount = _buyAmount;
        marketInfo.buyAmountInitial = _buyAmountInitial;
        marketInfo.feeSchedule = _feeSchedule;

        if (_buyAmount < LibConstants.DUST || _sellAmount < LibConstants.DUST) {
            marketInfo.state = LibConstants.OFFER_STATE_FULFILLED;
        } else {
            marketInfo.state = LibConstants.OFFER_STATE_ACTIVE;

            // lock tokens!
            s.lockedBalances[_creator][_sellToken] += _sellAmount;
        }

        s.offers[lastOfferId] = marketInfo;
        emit OrderAdded(lastOfferId, marketInfo.creator, _sellToken, _sellAmount, _sellAmountInitial, _buyToken, _buyAmount, _buyAmountInitial, marketInfo.state);

        return lastOfferId;
    }

    function _takeOffer(
        uint256 _offerId,
        bytes32 _takerId,
        uint256 _buyAmount,
        uint256 _sellAmount,
        bool _takeExternalToken
    ) internal returns (uint256 commissionsPaid_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // check bounds and update balances
        _checkBoundsAndUpdateBalances(_offerId, _buyAmount, _sellAmount);

        // Check fee schedule, before paying commissions
        if (s.offers[_offerId].feeSchedule == LibConstants.FEE_SCHEDULE_STANDARD) {
            // Fees are always paid by the taker, maker pays no fees, also only in external token.
            if (_takeExternalToken) {
                // sellToken is external supported token, commissions are paid on top of _buyAmount in sellToken
                commissionsPaid_ = LibFeeRouter._payTradingCommissions(s.offers[_offerId].creator, _takerId, s.offers[_offerId].sellToken, _buyAmount);
            } else {
                // sellToken is internal/participation token, commissions are paid from _sellAmount in buyToken
                commissionsPaid_ = LibFeeRouter._payTradingCommissions(s.offers[_offerId].creator, _takerId, s.offers[_offerId].buyToken, _sellAmount);
            }
        }

        s.lockedBalances[s.offers[_offerId].creator][s.offers[_offerId].sellToken] -= _buyAmount;

        LibTokenizedVault._internalTransfer(s.offers[_offerId].creator, _takerId, s.offers[_offerId].sellToken, _buyAmount);
        LibTokenizedVault._internalTransfer(_takerId, s.offers[_offerId].creator, s.offers[_offerId].buyToken, _sellAmount);

        // close offer if it has become dust
        if (s.offers[_offerId].sellAmount < LibConstants.DUST) {
            s.offers[_offerId].state = LibConstants.OFFER_STATE_FULFILLED;
            _cancelOffer(_offerId);
        }

        emit OrderExecuted(
            _offerId,
            _takerId,
            s.offers[_offerId].sellToken,
            s.offers[_offerId].sellAmount,
            s.offers[_offerId].buyToken,
            s.offers[_offerId].buyAmount,
            s.offers[_offerId].state
        );
    }

    function _checkBoundsAndUpdateBalances(
        uint256 _offerId,
        uint256 _sellAmount,
        uint256 _buyAmount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        (TokenAmount memory offerSell, TokenAmount memory offerBuy) = _getOfferTokenAmounts(_offerId);

        _assertAmounts(_sellAmount, _buyAmount);

        require(_buyAmount <= offerBuy.amount, "requested buy amount too large");
        require(_sellAmount <= offerSell.amount, "calculated sell amount too large");

        // update balances
        s.offers[_offerId].sellAmount = offerSell.amount - _sellAmount;
        s.offers[_offerId].buyAmount = offerBuy.amount - _buyAmount;
    }

    function _cancelOffer(uint256 _offerId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (_isOfferInSortedList(_offerId)) {
            _removeOfferFromSortedList(_offerId);
        }

        MarketInfo memory marketInfo = s.offers[_offerId];

        // unlock the remaining sell amount back to creator
        if (marketInfo.sellAmount > 0) {
            // note nothing is transferred since tokens for sale are UN-escrowed. Just unlock!
            s.lockedBalances[s.offers[_offerId].creator][s.offers[_offerId].sellToken] -= marketInfo.sellAmount;
        }

        // don't emit event stating market order is cancelled if the market order was executed and fulfilled
        if (marketInfo.state != LibConstants.OFFER_STATE_FULFILLED) {
            s.offers[_offerId].state = LibConstants.OFFER_STATE_CANCELLED;
            emit OrderCancelled(_offerId, marketInfo.creator, marketInfo.sellToken);
        }
    }

    function _assertAmounts(uint256 _sellAmount, uint256 _buyAmount) internal pure {
        require(_sellAmount <= type(uint128).max, "sell amount exceeds uint128 limit");
        require(_buyAmount <= type(uint128).max, "buy amount exceeds uint128 limit");
        require(_sellAmount > 0, "sell amount must be >0");
        require(_buyAmount > 0, "buy amount must be >0");
    }

    function _assertValidOffer(
        bytes32 _entityId,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    ) internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // A valid offer can only be made by an existing entity.
        require(_entityId != 0 && s.existingEntities[_entityId], "offer must be made by an existing entity");

        // note: Clarification on terminology:
        // A participation token is also called an entity token. A par token is an entity tokenized.
        // An external token is an ERC20 token. An external token can be approved to be used on the Nayms platform.
        // There can only be one participation token and one external token involved in a trade. In other words, a par token cannot be traded for another par token.
        // The platform also does not allow entities to trade external tokens (cannot trade an external token for another external token).

        bool isSellTokenAParticipationToken = s.existingEntities[_sellToken];
        bool isSellTokenASupportedExternalToken = s.externalTokenSupported[LibHelpers._getAddressFromId(_sellToken)];
        bool isBuyTokenAParticipationToken = s.existingEntities[_buyToken];
        bool isBuyTokenASupportedExternalToken = s.externalTokenSupported[LibHelpers._getAddressFromId(_buyToken)];

        _assertAmounts(_sellAmount, _buyAmount);

        require(isSellTokenAParticipationToken || isSellTokenASupportedExternalToken, "sell token must be valid");
        require(isBuyTokenAParticipationToken || isBuyTokenASupportedExternalToken, "buy token must be valid");
        require(_sellToken != _buyToken, "cannot sell and buy same token");
        require(
            (isSellTokenAParticipationToken && isBuyTokenASupportedExternalToken) || (isSellTokenASupportedExternalToken && isBuyTokenAParticipationToken),
            "must be one participation token and one external token"
        );

        // note: add restriction to not be able to sell tokens that are already for sale
        // maker must own sell amount and it must not be locked
        require(s.tokenBalances[_sellToken][_entityId] >= _sellAmount, "insufficient balance");
        require(s.tokenBalances[_sellToken][_entityId] - s.lockedBalances[_entityId][_sellToken] >= _sellAmount, "insufficient balance available, funds locked");

        // must have a valid fee schedule
        require(_feeSchedule == LibConstants.FEE_SCHEDULE_PLATFORM_ACTION || _feeSchedule == LibConstants.FEE_SCHEDULE_STANDARD, "fee schedule invalid");
    }

    function _getOfferTokenAmounts(uint256 _offerId) internal view returns (TokenAmount memory sell_, TokenAmount memory buy_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        sell_.token = s.offers[_offerId].sellToken;
        sell_.amount = s.offers[_offerId].sellAmount;
        buy_.token = s.offers[_offerId].buyToken;
        buy_.amount = s.offers[_offerId].buyAmount;
    }

    function _executeLimitOffer(
        bytes32 _creator,
        bytes32 _sellToken,
        uint256 _sellAmount,
        bytes32 _buyToken,
        uint256 _buyAmount,
        uint256 _feeSchedule
    )
        internal
        returns (
            uint256 offerId_,
            uint256 buyTokenCommissionsPaid_,
            uint256 sellTokenCommissionsPaid_
        )
    {
        _assertValidOffer(_creator, _sellToken, _sellAmount, _buyToken, _buyAmount, _feeSchedule);

        MatchingOfferResult memory result = _matchToExistingOffers(_creator, _sellToken, _sellAmount, _buyToken, _buyAmount);
        buyTokenCommissionsPaid_ = result.buyTokenCommissionsPaid;
        sellTokenCommissionsPaid_ = result.sellTokenCommissionsPaid;

        offerId_ = _createOffer(_creator, _sellToken, result.remainingSellAmount, _sellAmount, _buyToken, result.remainingBuyAmount, _buyAmount, _feeSchedule);

        // if still some left
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.offers[offerId_].state == LibConstants.OFFER_STATE_ACTIVE) {
            // ensure it's in the right position in the list
            _insertOfferIntoSortedList(offerId_);
        }
    }

    function _getOffer(uint256 _offerId) internal view returns (MarketInfo memory _offerState) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.offers[_offerId];
    }

    function _getLastOfferId() internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.lastOfferId;
    }

    function _isActiveOffer(uint256 _offerId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.offers[_offerId].state == LibConstants.OFFER_STATE_ACTIVE;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { EntityDoesNotExist, MissingSymbolWhenEnablingTokenization } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

import { ERC20Wrapper } from "../../../erc20/ERC20Wrapper.sol";

/// @notice Contains internal methods for core Nayms system functionality
library LibObject {
    event TokenWrapped(bytes32 indexed entityId, address tokenWrapper);

    function _createObject(
        bytes32 _objectId,
        bytes32 _parentId,
        bytes32 _dataHash
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Check if the objectId is already being used by another object
        require(!s.existingObjects[_objectId], "objectId is already being used by another object");

        s.existingObjects[_objectId] = true;
        s.objectParent[_objectId] = _parentId;
        s.objectDataHashes[_objectId] = _dataHash;
    }

    function _createObject(bytes32 _objectId, bytes32 _dataHash) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(!s.existingObjects[_objectId], "objectId is already being used by another object");

        s.existingObjects[_objectId] = true;
        s.objectDataHashes[_objectId] = _dataHash;
    }

    function _createObject(bytes32 _objectId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(!s.existingObjects[_objectId], "objectId is already being used by another object");

        s.existingObjects[_objectId] = true;
    }

    function _setDataHash(bytes32 _objectId, bytes32 _dataHash) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(s.existingObjects[_objectId], "setDataHash: object doesn't exist");
        s.objectDataHashes[_objectId] = _dataHash;
    }

    function _getDataHash(bytes32 _objectId) internal view returns (bytes32 objectDataHash) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.objectDataHashes[_objectId];
    }

    function _getParent(bytes32 _objectId) internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.objectParent[_objectId];
    }

    function _getParentFromAddress(address addr) internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 objectId = LibHelpers._getIdForAddress(addr);
        return s.objectParent[objectId];
    }

    function _setParent(bytes32 _objectId, bytes32 _parentId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.objectParent[_objectId] = _parentId;
    }

    function _isObjectTokenizable(bytes32 _objectId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return (bytes(s.objectTokenSymbol[_objectId]).length != 0);
    }

    function _enableObjectTokenization(
        bytes32 _objectId,
        string memory _symbol,
        string memory _name
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (bytes(_symbol).length == 0) {
            revert MissingSymbolWhenEnablingTokenization(_objectId);
        }

        // Ensure the entity exists before tokenizing the entity, otherwise revert.
        if (!s.existingEntities[_objectId]) {
            revert EntityDoesNotExist(_objectId);
        }

        require(!_isObjectTokenizable(_objectId), "object already tokenized");
        require(bytes(_symbol).length < 16, "symbol must be less than 16 characters");

        s.objectTokenSymbol[_objectId] = _symbol;
        s.objectTokenName[_objectId] = _name;
    }

    function _isObjectTokenWrapped(bytes32 _objectId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return (s.objectTokenWrapper[_objectId] != address(0));
    }

    function _wrapToken(bytes32 _entityId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(_isObjectTokenizable(_entityId), "must be tokenizable");
        require(!_isObjectTokenWrapped(_entityId), "must not be wrapped already");

        ERC20Wrapper tokenWrapper = new ERC20Wrapper(_entityId);
        address wrapperAddress = address(tokenWrapper);

        s.objectTokenWrapper[_entityId] = wrapperAddress;

        emit TokenWrapped(_entityId, wrapperAddress);
    }

    function _isObject(bytes32 _id) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.existingObjects[_id];
    }

    function _getObjectMeta(bytes32 _id)
        internal
        view
        returns (
            bytes32 parent,
            bytes32 dataHash,
            string memory tokenSymbol,
            string memory tokenName,
            address tokenWrapper
        )
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        parent = s.objectParent[_id];
        dataHash = s.objectDataHashes[_id];
        tokenSymbol = s.objectTokenSymbol[_id];
        tokenName = s.objectTokenName[_id];
        tokenWrapper = s.objectTokenWrapper[_id];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { Entity, SimplePolicy } from "../AppStorage.sol";
import { LibACL } from "./LibACL.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibObject } from "./LibObject.sol";
import { LibTokenizedVault } from "./LibTokenizedVault.sol";
import { LibFeeRouter } from "./LibFeeRouter.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibEIP712 } from "src/diamonds/nayms/libs/LibEIP712.sol";

import { EntityDoesNotExist, PolicyDoesNotExist } from "src/diamonds/nayms/interfaces/CustomErrors.sol";

library LibSimplePolicy {
    event SimplePolicyMatured(bytes32 indexed id);
    event SimplePolicyCancelled(bytes32 indexed id);
    event SimplePolicyPremiumPaid(bytes32 indexed id, uint256 amount);
    event SimplePolicyClaimPaid(bytes32 indexed _claimId, bytes32 indexed policyId, bytes32 indexed insuredId, uint256 amount);

    function _getSimplePolicyInfo(bytes32 _policyId) internal view returns (SimplePolicy memory simplePolicyInfo) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        simplePolicyInfo = s.simplePolicies[_policyId];
    }

    function _checkAndUpdateState(bytes32 _policyId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];

        if (!simplePolicy.cancelled && block.timestamp >= simplePolicy.maturationDate && simplePolicy.fundsLocked) {
            // When the policy matures, the entity regains their capacity that was being utilized for that policy.
            releaseFunds(_policyId);

            // emit event
            emit SimplePolicyMatured(_policyId);
        }
    }

    function _payPremium(
        bytes32 _payerEntityId,
        bytes32 _policyId,
        uint256 _amount
    ) internal {
        require(_amount > 0, "invalid premium amount");

        AppStorage storage s = LibAppStorage.diamondStorage();
        if (!s.existingEntities[_payerEntityId]) {
            revert EntityDoesNotExist(_payerEntityId);
        }
        if (!s.existingSimplePolicies[_policyId]) {
            revert PolicyDoesNotExist(_policyId);
        }
        bytes32 policyEntityId = LibObject._getParent(_policyId);
        SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];
        require(!simplePolicy.cancelled, "Policy is cancelled");

        LibTokenizedVault._internalTransfer(_payerEntityId, policyEntityId, simplePolicy.asset, _amount);
        LibFeeRouter._payPremiumCommissions(_policyId, _amount);

        simplePolicy.premiumsPaid += _amount;

        emit SimplePolicyPremiumPaid(_policyId, _amount);
    }

    function _payClaim(
        bytes32 _claimId,
        bytes32 _policyId,
        bytes32 _insuredEntityId,
        uint256 _amount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(_amount > 0, "invalid claim amount");
        require(LibACL._isInGroup(_insuredEntityId, _policyId, LibHelpers._stringToBytes32(LibConstants.GROUP_INSURED_PARTIES)), "not an insured party");

        SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];
        require(!simplePolicy.cancelled, "Policy is cancelled");

        uint256 claimsPaid = simplePolicy.claimsPaid;
        require(simplePolicy.limit >= _amount + claimsPaid, "exceeds policy limit");
        simplePolicy.claimsPaid += _amount;

        LibObject._createObject(_claimId);

        LibTokenizedVault._internalTransfer(LibObject._getParent(_policyId), _insuredEntityId, simplePolicy.asset, _amount);

        emit SimplePolicyClaimPaid(_claimId, _policyId, _insuredEntityId, _amount);
    }

    function _cancel(bytes32 _policyId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];
        require(!simplePolicy.cancelled, "Policy already cancelled");

        releaseFunds(_policyId);
        simplePolicy.cancelled = true;

        emit SimplePolicyCancelled(_policyId);
    }

    function releaseFunds(bytes32 _policyId) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 entityId = LibObject._getParent(_policyId);

        SimplePolicy storage simplePolicy = s.simplePolicies[_policyId];
        Entity storage entity = s.entities[entityId];

        uint256 policyLockedAmount = (simplePolicy.limit * entity.collateralRatio) / LibConstants.BP_FACTOR;
        entity.utilizedCapacity -= policyLockedAmount;
        s.lockedBalances[entityId][entity.assetId] -= policyLockedAmount;

        simplePolicy.fundsLocked = false;
    }

    function _getSigningHash(
        uint256 _startDate,
        uint256 _maturationDate,
        bytes32 _asset,
        uint256 _limit,
        bytes32 _offchainDataHash
    ) internal view returns (bytes32) {
        return
            LibEIP712._hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256("SimplePolicy(uint256 startDate,uint256 maturationDate,bytes32 asset,uint256 limit,bytes32 offchainDataHash)"),
                        _startDate,
                        _maturationDate,
                        _asset,
                        _limit,
                        _offchainDataHash
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibConstants } from "./LibConstants.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibObject } from "./LibObject.sol";

library LibTokenizedVault {
    /**
     * @dev Emitted when a token balance gets updated.
     * @param ownerId Id of owner
     * @param tokenId ID of token
     * @param newAmountOwned new amount owned
     * @param functionName Function name
     * @param msgSender msg.sende
     */
    event InternalTokenBalanceUpdate(bytes32 indexed ownerId, bytes32 tokenId, uint256 newAmountOwned, string functionName, address msgSender);

    /**
     * @dev Emitted when a token supply gets updated.
     * @param tokenId ID of token
     * @param newTokenSupply New token supply
     * @param functionName Function name
     * @param msgSender msg.sende
     */
    event InternalTokenSupplyUpdate(bytes32 indexed tokenId, uint256 newTokenSupply, string functionName, address msgSender);

    /**
     * @dev Emitted when a dividend gets payed out.
     * @param guid divident distribution ID
     * @param from distribution intiator
     * @param to distribution receiver
     * @param amount distributed amount
     */
    event DividendDistribution(bytes32 indexed guid, bytes32 from, bytes32 to, bytes32 dividendTokenId, uint256 amount);

    function _internalBalanceOf(bytes32 _ownerId, bytes32 _tokenId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.tokenBalances[_tokenId][_ownerId];
    }

    function _internalTokenSupply(bytes32 _objectId) internal view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.tokenSupply[_objectId];
    }

    function _internalTransfer(
        bytes32 _from,
        bytes32 _to,
        bytes32 _tokenId,
        uint256 _amount
    ) internal returns (bool success) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(s.tokenBalances[_tokenId][_from] >= _amount, "_internalTransfer: insufficient balance");
        require(s.tokenBalances[_tokenId][_from] - s.lockedBalances[_from][_tokenId] >= _amount, "_internalTransfer: insufficient balance available, funds locked");

        _withdrawAllDividends(_from, _tokenId);

        s.tokenBalances[_tokenId][_from] -= _amount;
        s.tokenBalances[_tokenId][_to] += _amount;

        _normalizeDividends(_to, _tokenId, _amount, false);

        emit InternalTokenBalanceUpdate(_from, _tokenId, s.tokenBalances[_tokenId][_from], "_internalTransfer", msg.sender);
        emit InternalTokenBalanceUpdate(_to, _tokenId, s.tokenBalances[_tokenId][_to], "_internalTransfer", msg.sender);

        success = true;
    }

    function _internalMint(
        bytes32 _to,
        bytes32 _tokenId,
        uint256 _amount
    ) internal {
        require(_to != "", "_internalMint: mint to zero address");
        require(_amount > 0, "_internalMint: mint zero tokens");

        AppStorage storage s = LibAppStorage.diamondStorage();

        _normalizeDividends(_to, _tokenId, _amount, true);

        s.tokenSupply[_tokenId] += _amount;
        s.tokenBalances[_tokenId][_to] += _amount;

        emit InternalTokenSupplyUpdate(_tokenId, s.tokenSupply[_tokenId], "_internalMint", msg.sender);
        emit InternalTokenBalanceUpdate(_to, _tokenId, s.tokenBalances[_tokenId][_to], "_internalMint", msg.sender);
    }

    function _normalizeDividends(
        bytes32 _to,
        bytes32 _tokenId,
        uint256 _amount,
        bool _updateTotals
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 supply = _internalTokenSupply(_tokenId);

        // This must be done BEFORE the supply increases!!!
        // This will calcualte the hypothetical dividends that would correspond to this number of shares.
        // It must be added to the withdrawn dividend for every denomination for the user who receives the minted tokens
        bytes32[] memory dividendDenominations = s.dividendDenominations[_tokenId];

        for (uint256 i = 0; i < dividendDenominations.length; ++i) {
            bytes32 dividendDenominationId = dividendDenominations[i];
            uint256 totalDividend = s.totalDividends[_tokenId][dividendDenominationId];

            // Dividend deduction for newly issued shares
            uint256 dividendDeductionIssued = _getWithdrawableDividendAndDeductionMath(_amount, supply, totalDividend, 0);

            // Scale total dividends and withdrawn dividend for new owner
            s.withdrawnDividendPerOwner[_tokenId][dividendDenominationId][_to] += dividendDeductionIssued;
            if (_updateTotals) {
                s.totalDividends[_tokenId][dividendDenominationId] += (s.totalDividends[_tokenId][dividendDenominationId] * _amount) / supply;
            }
        }
    }

    function _internalBurn(
        bytes32 _from,
        bytes32 _tokenId,
        uint256 _amount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(s.tokenBalances[_tokenId][_from] >= _amount, "_internalBurn: insufficient balance");
        require(s.tokenBalances[_tokenId][_from] - s.lockedBalances[_from][_tokenId] >= _amount, "_internalBurn: insufficient balance available, funds locked");

        _withdrawAllDividends(_from, _tokenId);

        s.tokenSupply[_tokenId] -= _amount;
        s.tokenBalances[_tokenId][_from] -= _amount;

        emit InternalTokenSupplyUpdate(_tokenId, s.tokenSupply[_tokenId], "_internalBurn", msg.sender);
        emit InternalTokenBalanceUpdate(_from, _tokenId, s.tokenBalances[_tokenId][_from], "_internalBurn", msg.sender);
    }

    //   DIVIDEND PAYOUT LOGIC
    //
    // When a dividend is payed, you divide by the total supply and add it to the totalDividendPerToken
    // Dividends are held by the diamond contract at: LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER)
    // When dividends are paid, they are transfered OUT of that same diamond contract ID.
    //
    // To calculate withdrawableDividiend = ownedTokens * totalDividendPerToken - totalWithdrawnDividendPerOwner
    //
    // When a dividend is collected you set the totalWithdrawnDividendPerOwner to the total amount the owner withdrew
    //
    // When you trasnsfer, you pay out all dividends to previous owner first, then transfer ownership
    // !!!YOU ALSO TRANSFER totalWithdrawnDividendPerOwner for those shares!!!
    // totalWithdrawnDividendPerOwner(for new owner) += numberOfSharesTransfered * totalDividendPerToken
    // totalWithdrawnDividendPerOwner(for previous owner) -= numberOfSharesTransfered * totalDividendPerToken (can be optimized)
    //
    // When minting
    // Add the token balance to the new owner
    // totalWithdrawnDividendPerOwner(for new owner) += numberOfSharesMinted * totalDividendPerToken
    //
    // When doing the division theser will be dust. Leave the dust in the diamond!!!
    function _withdrawDividend(
        bytes32 _ownerId,
        bytes32 _tokenId,
        bytes32 _dividendTokenId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 dividendBankId = LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER);

        uint256 amountOwned = s.tokenBalances[_tokenId][_ownerId];
        uint256 supply = _internalTokenSupply(_tokenId);
        uint256 totalDividend = s.totalDividends[_tokenId][_dividendTokenId];
        uint256 withdrawnSoFar = s.withdrawnDividendPerOwner[_tokenId][_dividendTokenId][_ownerId];

        uint256 withdrawableDividend = _getWithdrawableDividendAndDeductionMath(amountOwned, supply, totalDividend, withdrawnSoFar);
        if (withdrawableDividend > 0) {
            // Bump the withdrawn dividends for the owner
            s.withdrawnDividendPerOwner[_tokenId][_dividendTokenId][_ownerId] += withdrawableDividend;

            // Move the dividend
            s.tokenBalances[_dividendTokenId][dividendBankId] -= withdrawableDividend;
            s.tokenBalances[_dividendTokenId][_ownerId] += withdrawableDividend;

            emit InternalTokenBalanceUpdate(dividendBankId, _dividendTokenId, s.tokenBalances[_dividendTokenId][dividendBankId], "_withdrawDividend", msg.sender);
            emit InternalTokenBalanceUpdate(_ownerId, _dividendTokenId, s.tokenBalances[_dividendTokenId][_ownerId], "_withdrawDividend", msg.sender);
        }
    }

    function _getWithdrawableDividend(
        bytes32 _ownerId,
        bytes32 _tokenId,
        bytes32 _dividendTokenId
    ) internal view returns (uint256 withdrawableDividend_) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 amount = s.tokenBalances[_tokenId][_ownerId];
        uint256 supply = _internalTokenSupply(_tokenId);
        uint256 totalDividend = s.totalDividends[_tokenId][_dividendTokenId];
        uint256 withdrawnSoFar = s.withdrawnDividendPerOwner[_tokenId][_dividendTokenId][_ownerId];

        withdrawableDividend_ = _getWithdrawableDividendAndDeductionMath(amount, supply, totalDividend, withdrawnSoFar);
    }

    function _withdrawAllDividends(bytes32 _ownerId, bytes32 _tokenId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32[] memory dividendDenominations = s.dividendDenominations[_tokenId];

        for (uint256 i = 0; i < dividendDenominations.length; ++i) {
            _withdrawDividend(_ownerId, _tokenId, dividendDenominations[i]);
        }
    }

    function _payDividend(
        bytes32 _guid,
        bytes32 _from,
        bytes32 _to,
        bytes32 _dividendTokenId,
        uint256 _amount
    ) internal {
        require(_amount > 0, "dividend amount must be > 0");
        require(LibAdmin._isSupportedExternalToken(_dividendTokenId), "must be supported dividend token");
        require(!LibObject._isObject(_guid), "nonunique dividend distribution identifier");

        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 dividendBankId = LibHelpers._stringToBytes32(LibConstants.DIVIDEND_BANK_IDENTIFIER);

        // If no tokens are issued, then deposit directly.
        // note: This functionality is for the business case where we want to distribute dividends directly to entities.
        // How this functionality is implemented may be changed in the future.
        if (_internalTokenSupply(_to) == 0) {
            _internalTransfer(_from, _to, _dividendTokenId, _amount);
        }
        // Otherwise pay as dividend
        else {
            // issue dividend. if you are owed dividends on the _dividendTokenId, they will be collected
            // Check for possible infinite loop, but probably not
            _internalTransfer(_from, dividendBankId, _dividendTokenId, _amount);
            s.totalDividends[_to][_dividendTokenId] += _amount;

            // keep track of the dividend denominations
            // if dividend has not yet been issued in this token, add it to the list and update mappings
            if (s.dividendDenominationIndex[_to][_dividendTokenId] == 0) {
                // We must limit the number of different tokens dividends are paid in
                if (s.dividendDenominations[_to].length > LibAdmin._getMaxDividendDenominations()) {
                    revert("exceeds max div denominations");
                }

                s.dividendDenominationIndex[_to][_dividendTokenId] = uint8(s.dividendDenominations[_to].length);
                s.dividendDenominationAtIndex[_to][uint8(s.dividendDenominations[_to].length)] = _dividendTokenId;
                s.dividendDenominations[_to].push(_dividendTokenId);
            }
        }

        // prevent guid reuse/collision
        LibObject._createObject(_guid);

        // Events are emitted from the _internalTransfer()
        emit DividendDistribution(_guid, _from, _to, _dividendTokenId, _amount);
    }

    function _getWithdrawableDividendAndDeductionMath(
        uint256 _amount,
        uint256 _supply,
        uint256 _totalDividend,
        uint256 _withdrawnSoFar
    ) internal pure returns (uint256 _withdrawableDividend) {
        // The holder dividend is: holderDividend = (totalDividend/tokenSupply) * _amount. The remainer (dust) is lost.
        // To get a smaller remainder we re-arrange to: holderDividend = (totalDividend * _amount) / _supply
        uint256 totalDividendTimesAmount = _totalDividend * _amount;
        uint256 holderDividend = _supply == 0 ? 0 : (totalDividendTimesAmount / _supply);

        _withdrawableDividend = (_withdrawnSoFar >= holderDividend) ? 0 : holderDividend - _withdrawnSoFar;
    }

    function _getLockedBalance(bytes32 _accountId, bytes32 _tokenId) internal view returns (uint256 amount) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.lockedBalances[_accountId][_tokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0 is ERC165
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

library LibMeta {
    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// solhint-disable func-name-mixedcase

import { IERC20 } from "./IERC20.sol";
import { INayms } from "../diamonds/nayms/INayms.sol";
import { LibHelpers } from "../diamonds/nayms/libs/LibHelpers.sol";
import { LibConstants } from "../diamonds/nayms/libs/LibConstants.sol";
import { ReentrancyGuard } from "../utils/ReentrancyGuard.sol";

contract ERC20Wrapper is IERC20, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/
    bytes32 internal immutable tokenId;
    INayms internal immutable nayms;
    mapping(address => mapping(address => uint256)) public allowances;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/
    uint256 internal immutable INITIAL_CHAIN_ID;
    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;
    mapping(address => uint256) public nonces;

    constructor(bytes32 _tokenId) {
        // ensure only diamond can instantiate this
        nayms = INayms(msg.sender);

        require(nayms.isObjectTokenizable(_tokenId), "must be tokenizable");
        require(!nayms.isTokenWrapped(_tokenId), "must not be wrapped already");

        tokenId = _tokenId;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    function name() external view returns (string memory) {
        (, , , string memory tokenName, ) = nayms.getObjectMeta(tokenId);
        return tokenName;
    }

    function symbol() external view returns (string memory) {
        (, , string memory tokenSymbol, , ) = nayms.getObjectMeta(tokenId);
        return tokenSymbol;
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() external view returns (uint256) {
        return nayms.internalTokenSupply(tokenId);
    }

    function balanceOf(address who) external view returns (uint256) {
        return nayms.internalBalanceOf(LibHelpers._getIdForAddress(who), tokenId);
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    function transfer(address to, uint256 value) external nonReentrant returns (bool) {
        bytes32 fromId = LibHelpers._getIdForAddress(msg.sender);
        bytes32 toId = LibHelpers._getIdForAddress(to);

        emit Transfer(msg.sender, to, value);

        nayms.wrapperInternalTransferFrom(fromId, toId, tokenId, value);

        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowances[msg.sender][spender] = value;
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external nonReentrant returns (bool) {
        if (value == 0) {
            revert();
        }
        uint256 allowed = allowances[from][msg.sender]; // Saves gas for limited approvals.
        require(allowed >= value, "not enough allowance");

        if (allowed != type(uint256).max) allowances[from][msg.sender] = allowed - value;

        bytes32 fromId = LibHelpers._getIdForAddress(from);
        bytes32 toId = LibHelpers._getIdForAddress(to);

        emit Transfer(from, to, value);

        nayms.wrapperInternalTransferFrom(fromId, toId, tokenId, value);

        return true;
    }

    // refer to https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol#L116
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowances[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(LibHelpers._bytes32ToBytes(tokenId)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * See https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC20
 */
interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge
*
/******************************************************************************/

import { IERC20 } from "./IERC20.sol";

library LibERC20 {
    function decimals(address _token) internal returns (uint8) {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: ERC20 token address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.decimals.selector));
        if (success) {
            return abi.decode(result, (uint8));
        } else {
            revert("LibERC20: call to decimals() failed");
        }
    }

    function balanceOf(address _token, address _who) internal returns (uint256) {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: ERC20 token address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.balanceOf.selector, _who));
        if (success) {
            return abi.decode(result, (uint256));
        } else {
            revert("LibERC20: call to balanceOf() failed");
        }
    }

    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: ERC20 token address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, _from, _to, _value));
        handleReturn(success, result);
    }

    function transfer(
        address _token,
        address _to,
        uint256 _value
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: ERC20 token address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transfer.selector, _to, _value));
        handleReturn(success, result);
    }

    function handleReturn(bool _success, bytes memory _result) internal pure {
        if (_success) {
            if (_result.length > 0) {
                require(abi.decode(_result, (bool)), "LibERC20: transfer or transferFrom returned false");
            }
        } else {
            if (_result.length > 0) {
                // bubble up any reason for revert
                // see https://github.com/OpenZeppelin/openzeppelin-contracts/blob/c239e1af8d1a1296577108dd6989a17b57434f8e/contracts/utils/Address.sol#L201
                assembly {
                    revert(add(32, _result), mload(_result))
                }
            } else {
                revert("LibERC20: transfer or transferFrom reverted");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { LibAppStorage } from "src/diamonds/nayms/AppStorage.sol";

// From OpenZeppellin: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol

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

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(LibAppStorage.diamondStorage().reentrancyStatus != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        LibAppStorage.diamondStorage().reentrancyStatus = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        LibAppStorage.diamondStorage().reentrancyStatus = _NOT_ENTERED;
    }
}