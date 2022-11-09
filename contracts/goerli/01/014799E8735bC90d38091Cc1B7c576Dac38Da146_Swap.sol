/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// File: utils/LoanDataTypes.sol



pragma solidity ^0.8.9;

// @TODO Rethink data types and tight packing of structs for gas optimization

struct LoanOffer {
    address nftCollateralContract;
    uint256 nftCollateralId;
    address owner;
    uint256 nonce;
    address loanPaymentToken;
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 loanDuration;
    uint256 loanInterestRate;
    bool isLoanProrated;
    uint256 adminFees;
}

struct OpenLoanOffer {
    address nftCollateralContract;
    bytes32 nftCollateralIdRoot;
    address owner;
    uint256 nonce;
    address loanPaymentToken;
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 loanDuration;
    uint256 loanInterestRate;
    bool isLoanProrated;
    uint256 adminFees;
}

struct LoanUpdateOffer {
    uint256 loanId;
    uint256 maximumRepaymentAmount;
    uint256 loanDuration;
    uint256 loanInterestRate;
    bool isLoanProrated;
    address owner;
    uint256 nonce;
}

struct Loan {
    uint256 loanId;
    address nftCollateralContract;
    uint256 nftCollateralId;
    address loanPaymentToken;
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 loanStartTime;
    uint256 loanDuration;
    uint256 loanInterestRate;
    uint256 adminFees;
    bool isLoanProrated;
}

// File: @openzeppelin/contracts/utils/math/Math.sol


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

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

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

// File: @openzeppelin/contracts/utils/cryptography/ECDSA.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;


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

// File: utils/DataTypes.sol


pragma solidity ^0.8.9;

/// @dev Royalties for collection creators and platform fee for platform manager. 
///      to[0] is platform owner address.
/// @param to Creators and platform manager address array
/// @param percentage Royalty percentage based on the listed FT
struct Royalty {
    address[] to;
    uint256[] percentage;
}

/// @dev Common Assets type, packing bundle of NFTs and FTs.
/// @param tokens NFT asset address
/// @param tokenIds NFT token id
/// @param paymentTokens FT asset address
/// @param amounts FT token amount
struct Assets {
    address[] tokens;
    uint256[] tokenIds;
    address[] paymentTokens;
    uint256[] amounts;
}

/// @dev Common SwapAssets type, packing Bundle of NFTs and FTs. Notice tokenIds is a 2d array.
///      Each collection address ie. tokens[i] will have an array tokenIds[i] corrosponding to it.
///      This is used to select particular tokenId in corrospoding collection. If tokenIds[i]
///      is empty, this means the entire collection is considered valid.
/// @param tokens NFT asset address
/// @param roots Merkle roots of the criterias. NOTE: bytes32(0) represents the entire collection
/// @param paymentTokens FT asset address
/// @param amounts FT token amount
struct SwapAssets {
    address[] tokens;
    bytes32[] roots;
    address[] paymentTokens;
    uint256[] amounts;
}

/// @dev Common Reserve type, packing data related to reserve listing and reserve offer.
/// @param deposit Assets considered as initial deposit
/// @param remaining Assets considered as due amount
/// @param duration Duration of reserve now swap later
struct ReserveInfo {
    Assets deposit;
    Assets remaining;
    uint256 duration;
}

/// @dev Listing type, packing the assets being listed, listing parameters, listing owner
///      and users's nonce.
/// @param listingAssets All the assets listed
/// @param directSwaps List of options for direct swap
/// @param reserves List of options for reserve now swap later
/// @param royalty Listing royalty and platform fee info
/// @param timePeriod Time period of listing
/// @param owner Owner's address
/// @param nonce User's nonce
struct Listing {
    Assets listingAssets;
    SwapAssets[] directSwaps;
    ReserveInfo[] reserves;
    Royalty royalty;
    address tradeIntendedFor;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Listing type of special NF3 banner listing
/// @param token address of collection
/// @param tokenId token id being listed
/// @param editions number of tokenIds being distributed
/// @param gateCollectionsRoot merkle root for eligible collections
/// @param timePeriod timePeriod of listing
/// @param owner owner of listing
struct NF3GatedListing {
    address token;
    uint256 tokenId;
    uint256 editions;
    bytes32 gatedCollectionsRoot;
    uint256 timePeriod;
    address owner;
}

/// @dev Swap Offer type info.
/// @param offeringItems Assets being offered
/// @param royalty Swap offer royalty info
/// @param considerationRoot Assets to which this offer is made
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct SwapOffer {
    Assets offeringItems;
    Royalty royalty;
    bytes32 considerationRoot;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Reserve now swap later type offer info.
/// @param reserveDetails Reservation scheme begin offered
/// @param considerationItems Assets to which this offer is made
/// @param royalty Reserve offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct ReserveOffer {
    ReserveInfo reserveDetails;
    Assets considerationItems;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Collection offer type info.
/// @param offeringItems Assets being offered
/// @param considerationItems Assets to which this offer is made
/// @param royalty Collection offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct CollectionOffer {
    Assets offeringItems;
    SwapAssets considerationItems;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

enum Status {
    AVAILABLE,
    RESERVED,
    EXHAUSTED
}

enum AssetType {
    INVALID,
    ETH,
    ERC_20,
    ERC_721,
    ERC_1155,
    KITTIES,
    PUNK
}

// File: contracts/lib/Utils.sol


pragma solidity ^0.8.9;




/// @title NF3 Utils Library
/// @author Jack Jin
/// @author Priyam Anand
/// @dev This library contains all the pure functions that are used across the system of contracts.

library Utils {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum UtilsErrorCodes {
        INVALID_LISTING_SIGNATURE,
        INVALID_SWAP_OFFER_SIGNATURE,
        INVALID_COLLECTION_OFFER_SIGNATURE,
        INVALID_RESERVE_OFFER_SIGNATURE,
        INVALID_ITEMS,
        ONLY_OWNER,
        OWNER_NOT_ALLOWED,
        INVALID_LOAN_OFFER_SIGNATURE,
        INVALID_COLLECTION_LOAN_OFFER_SIGNATURE,
        INVALID_UPDATE_LOAN_OFFER_SIGNATURE
    }

    error UtilsError(UtilsErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Internal Functions
    /// -----------------------------------------------------------------------

    /* ===== Verify Signatures ===== */

    /// @dev Check the signature if the listing info is valid or not.
    /// @param _listing Listing info
    /// @param _signature Listing signature
    function verifyListingSignature(
        Listing calldata _listing,
        bytes memory _signature
    ) internal pure {
        address owner = getListingSignatureOwner(_listing, _signature);

        if (_listing.owner != owner) {
            revert UtilsError(UtilsErrorCodes.INVALID_LISTING_SIGNATURE);
        }
    }

    /// @dev Check the signature if the swap offer is valid or not.
    /// @param _offer Offer info
    /// @param _signature Offer signature
    function verifySwapOfferSignature(
        SwapOffer calldata _offer,
        bytes memory _signature
    ) internal pure {
        address owner = getSwapOfferSignatureOwner(_offer, _signature);

        if (_offer.owner != owner) {
            revert UtilsError(UtilsErrorCodes.INVALID_SWAP_OFFER_SIGNATURE);
        }
    }

    /// @dev Check the signature if the collection offer is valid or not.
    /// @param _offer Offer info
    /// @param _signature Offer signature
    function verifyCollectionOfferSignature(
        CollectionOffer calldata _offer,
        bytes memory _signature
    ) internal pure {
        address owner = getCollectionOfferOwner(_offer, _signature);

        if (_offer.owner != owner) {
            revert UtilsError(
                UtilsErrorCodes.INVALID_COLLECTION_OFFER_SIGNATURE
            );
        }
    }

    /// @dev Check the signature if the reserve offer is valid or not.
    /// @param _offer Reserve offer info
    /// @param _signature Reserve offer signature
    function verifyReserveOfferSignature(
        ReserveOffer calldata _offer,
        bytes memory _signature
    ) internal pure {
        address owner = getReserveOfferSignatureOwner(_offer, _signature);

        if (_offer.owner != owner) {
            revert UtilsError(UtilsErrorCodes.INVALID_RESERVE_OFFER_SIGNATURE);
        }
    }

    /// @dev Check the signature if the loan offer is valid or not.
    /// @param _loanOffer Loan offer info
    /// @param _signature Loa offer signature
    function verifyLoanOfferSignature(
        LoanOffer calldata _loanOffer,
        bytes memory _signature
    ) internal pure {
        address owner = getLoanOfferOwer(_loanOffer, _signature);

        if (_loanOffer.owner != owner) {
            revert UtilsError(UtilsErrorCodes.INVALID_LOAN_OFFER_SIGNATURE);
        }
    }

    /// @dev Check the signature if the collection loan offer is valid or not.
    /// @param _loanOffer Open Loan offer info
    /// @param _signature Open loan offer signature
    function verifyCollectionLoanOfferSignature(
        OpenLoanOffer calldata _loanOffer,
        bytes memory _signature
    ) internal pure {
        address owner = getCollectionLoanOwner(_loanOffer, _signature);

        if (_loanOffer.owner != owner) {
            revert UtilsError(
                UtilsErrorCodes.INVALID_COLLECTION_LOAN_OFFER_SIGNATURE
            );
        }
    }

    /// @dev Check the signature if the update loan offer is valid or not.
    /// @param _loanOffer update Loan offer info
    /// @param _signature update loan offer signature
    function verifyUpdateLoanSignature(
        LoanUpdateOffer calldata _loanOffer,
        bytes memory _signature
    ) internal pure {
        address owner = getUpdateLoanOfferOwner(_loanOffer, _signature);

        if (_loanOffer.owner != owner) {
            revert UtilsError(
                UtilsErrorCodes.INVALID_UPDATE_LOAN_OFFER_SIGNATURE
            );
        }
    }

    /* ===== Verify Assets ===== */

    /// @dev Verify assets1 and assets2 if they are the same.
    /// @param _assets1 First assets
    /// @param _assets2 Second assets
    function verifyAssets(Assets calldata _assets1, Assets calldata _assets2)
        internal
        pure
    {
        if (
            _assets1.paymentTokens.length != _assets2.paymentTokens.length ||
            _assets1.tokens.length != _assets2.tokens.length
        ) revert UtilsError(UtilsErrorCodes.INVALID_ITEMS);

        unchecked {
            uint256 i;
            for (i = 0; i < _assets1.paymentTokens.length; i++) {
                if (
                    _assets1.paymentTokens[i] != _assets2.paymentTokens[i] ||
                    _assets1.amounts[i] != _assets2.amounts[i]
                ) revert UtilsError(UtilsErrorCodes.INVALID_ITEMS);
            }

            for (i = 0; i < _assets1.tokens.length; i++) {
                if (
                    _assets1.tokens[i] != _assets2.tokens[i] ||
                    _assets1.tokenIds[i] != _assets2.tokenIds[i]
                ) revert UtilsError(UtilsErrorCodes.INVALID_ITEMS);
            }
        }
    }

    /// @dev Verify swap assets to be satisfied as the consideration items by the seller.
    /// @param _swapAssets Swap assets
    /// @param _tokens NFT addresses
    /// @param _tokenIds NFT token ids
    /// @param _value Eth value
    /// @return assets Verified swap assets
    function verifySwapAssets(
        SwapAssets memory _swapAssets,
        address[] memory _tokens,
        uint256[] memory _tokenIds,
        bytes32[][] memory _proofs,
        uint256 _value
    ) internal pure returns (Assets memory) {

        return
            Assets(
                _tokens,
                _tokenIds,
                _swapAssets.paymentTokens,
                _swapAssets.amounts
            );
    }

    /// @dev Verify if the passed asset is present in the merkle root passed.
    /// @param _root Merkle root to check in
    /// @param _consideration Consideration assets
    /// @param _proof Merkle proof
    function verifySwapOfferAsset(
        bytes32 _root,
        Assets calldata _consideration,
        bytes32[] calldata _proof
    ) internal pure {
        bytes32 _leaf = addAssets(_consideration, bytes32(0));

        if (!verifyMerkleProof(_root, _proof, _leaf)) {
            revert UtilsError(UtilsErrorCodes.INVALID_ITEMS);
        }
    }

    /* ===== Check Validations ===== */

    /// @dev Check if the ETH amount is valid.
    /// @param _assets Assets
    /// @param _value ETH amount
    function checkEthAmount(Assets memory _assets, uint256 _value)
        internal
        pure
    {
        uint256 ethAmount;

        for (uint256 i = 0; i < _assets.paymentTokens.length; ) {
            if (_assets.paymentTokens[i] == address(0))
                ethAmount += _assets.amounts[i];
            unchecked {
                ++i;
            }
        }
        if (ethAmount > _value) {
            revert UtilsError(UtilsErrorCodes.INVALID_ITEMS);
        }
    }

    /// @dev Check if the function is called by the item owner.
    /// @param _owner Owner address
    /// @param _caller Caller address
    function itemOwnerOnly(address _owner, address _caller) internal pure {
        if (_owner != _caller) {
            revert UtilsError(UtilsErrorCodes.ONLY_OWNER);
        }
    }

    /// @dev Check if the function is not called by the item owner.
    /// @param _owner Owner address
    /// @param _caller Caller address
    function notItemOwner(address _owner, address _caller) internal pure {
        if (_owner == _caller) {
            revert UtilsError(UtilsErrorCodes.OWNER_NOT_ALLOWED);
        }
    }

    /* ===== Get Functions ===== */

    /// @dev Get the hash of data saved in position token.
    /// @param _listingAssets Listing assets
    /// @param _reserveInfo Reserve ino
    /// @param _listingOwner Listing owner
    /// @return hash Hash of the passed data
    function getPostitionTokenDataHash(
        Assets calldata _listingAssets,
        ReserveInfo calldata _reserveInfo,
        address _listingOwner
    ) internal pure returns (bytes32 hash) {
        hash = addAssets(_listingAssets, hash);

        hash = keccak256(
            abi.encodePacked(getReserveHash(_reserveInfo), _listingOwner, hash)
        );
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    /* ===== Get Owner Of Signatures ===== */

    /// @dev Get the signature owner from listing data info and its signature.
    /// @param _listing Listing info
    /// @param _signature Listing signature
    /// @return owner Listing signature owner
    function getListingSignatureOwner(
        Listing calldata _listing,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = getListingHash(_listing);

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /// @dev Get the signature owner from the swap offer info and its signature.
    /// @param _offer Swap offer info
    /// @param _signature Swap offer signature
    /// @return owner Swap offer signature owner
    function getSwapOfferSignatureOwner(
        SwapOffer calldata _offer,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = getSwapOfferHash(_offer);

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /// @dev Get the signature owner from collection offer info and its signature.
    /// @param _offer Collection offer info
    /// @param _signature Collection offer signature
    /// @return owner Collection offer signature owner
    function getCollectionOfferOwner(
        CollectionOffer calldata _offer,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = getCollectionOfferHash(_offer);

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /// @dev Get the signature owner from reserve offer info and its signature.
    /// @param _offer Reserve offer info
    /// @param _signature Reserve offer signature
    /// @return owner Reserve offer signature owner
    function getReserveOfferSignatureOwner(
        ReserveOffer calldata _offer,
        bytes memory _signature
    ) internal pure returns (address owner) {
        bytes32 hash = getReserveOfferHash(_offer);

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /// @dev Get the signature owner from loan offer info and its signature.
    /// @param _loanOffer Loan offer info
    /// @param _signature Loan offer signature
    /// @return owner signature owner
    function getLoanOfferOwer(
        LoanOffer calldata _loanOffer,
        bytes memory _signature
    ) private pure returns (address owner) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                _loanOffer.nftCollateralContract,
                _loanOffer.nftCollateralId,
                _loanOffer.owner,
                _loanOffer.nonce,
                _loanOffer.loanPaymentToken,
                _loanOffer.loanPrincipalAmount,
                _loanOffer.maximumRepaymentAmount,
                _loanOffer.loanDuration,
                _loanOffer.loanInterestRate,
                _loanOffer.isLoanProrated,
                _loanOffer.adminFees
            )
        );

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /// @dev Get the signature owner from collection loan offer info and its signature.
    /// @param _loanOffer collection loan offer info
    /// @param _signature Reserve offer signature
    /// @return owner signature owner
    function getCollectionLoanOwner(
        OpenLoanOffer calldata _loanOffer,
        bytes memory _signature
    ) private pure returns (address owner) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                _loanOffer.nftCollateralContract,
                _loanOffer.nftCollateralIdRoot,
                _loanOffer.owner,
                _loanOffer.nonce,
                _loanOffer.loanPaymentToken,
                _loanOffer.loanPrincipalAmount,
                _loanOffer.maximumRepaymentAmount,
                _loanOffer.loanDuration,
                _loanOffer.loanInterestRate,
                _loanOffer.isLoanProrated,
                _loanOffer.adminFees
            )
        );

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /// @dev Get the signature owner from update loan offer info and its signature.
    /// @param _loanOffer update loan offer info
    /// @param _signature update loan offer signature
    /// @return owner signature owner
    function getUpdateLoanOfferOwner(
        LoanUpdateOffer calldata _loanOffer,
        bytes memory _signature
    ) private pure returns (address owner) {
        bytes32 hash = keccak256(
            abi.encodePacked(
                _loanOffer.loanId,
                _loanOffer.maximumRepaymentAmount,
                _loanOffer.loanDuration,
                _loanOffer.loanInterestRate,
                _loanOffer.isLoanProrated,
                _loanOffer.owner,
                _loanOffer.nonce
            )
        );

        bytes32 signedHash = getSignedMessageHash(hash);

        owner = ECDSA.recover(signedHash, _signature);
    }

    /* ===== Get Hash ===== */

    /// @dev Get the hash of listing info.
    /// @param _listing Listing info
    /// @return hash Hash of the listing info
    function getListingHash(Listing calldata _listing)
        internal
        pure
        returns (bytes32)
    {
        bytes32 signature;
        uint256 i;

        signature = addAssets(_listing.listingAssets, signature);

        unchecked {
            for (i = 0; i < _listing.directSwaps.length; i++) {
                signature = addSwapAssets(_listing.directSwaps[i], signature);
            }

            for (i = 0; i < _listing.reserves.length; i++) {
                signature = addAssets(_listing.reserves[i].deposit, signature);
                signature = addAssets(
                    _listing.reserves[i].remaining,
                    signature
                );
                signature = keccak256(
                    abi.encodePacked(_listing.reserves[i].duration, signature)
                );
            }

            for (i = 0; i < _listing.royalty.to.length; i++) {
                signature = keccak256(
                    abi.encodePacked(
                        _listing.royalty.to[i],
                        _listing.royalty.percentage[i],
                        signature
                    )
                );
            }
        }

        signature = keccak256(
            abi.encodePacked(
                _listing.tradeIntendedFor,
                _listing.timePeriod,
                _listing.owner,
                _listing.nonce,
                signature
            )
        );

        return signature;
    }

    /// @dev Get the hash of the swap offer info.
    /// @param _offer Offer info
    /// @return hash Hash of the offer
    function getSwapOfferHash(SwapOffer calldata _offer)
        internal
        pure
        returns (bytes32)
    {
        bytes32 signature;

        signature = addAssets(_offer.offeringItems, signature);

        unchecked {
            for (uint256 i = 0; i < _offer.royalty.to.length; i++) {
                signature = keccak256(
                    abi.encodePacked(
                        _offer.royalty.to[i],
                        _offer.royalty.percentage[i],
                        signature
                    )
                );
            }
        }

        signature = keccak256(
            abi.encodePacked(
                _offer.considerationRoot,
                _offer.timePeriod,
                _offer.owner,
                _offer.nonce,
                signature
            )
        );

        return signature;
    }

    /// @dev Get the hash of collection offer info.
    /// @param _offer Collection offer info
    /// @return hash Hash of the collection offer info
    function getCollectionOfferHash(CollectionOffer calldata _offer)
        internal
        pure
        returns (bytes32)
    {
        bytes32 signature;

        signature = addAssets(_offer.offeringItems, signature);

        signature = addSwapAssets(_offer.considerationItems, signature);

        unchecked {
            for (uint256 i = 0; i < _offer.royalty.to.length; i++) {
                signature = keccak256(
                    abi.encodePacked(
                        _offer.royalty.to[i],
                        _offer.royalty.percentage[i],
                        signature
                    )
                );
            }
        }

        signature = keccak256(
            abi.encodePacked(
                _offer.timePeriod,
                _offer.owner,
                _offer.nonce,
                signature
            )
        );

        return signature;
    }

    /// @dev Get the hash of reserve offer info.
    /// @param _offer Reserve offer info
    /// @return hash Hash of the reserve offer info
    function getReserveOfferHash(ReserveOffer calldata _offer)
        internal
        pure
        returns (bytes32)
    {
        bytes32 signature;

        signature = getReserveHash(_offer.reserveDetails);

        signature = addAssets(_offer.considerationItems, signature);

        unchecked {
            for (uint256 i = 0; i < _offer.royalty.to.length; i++) {
                signature = keccak256(
                    abi.encodePacked(
                        _offer.royalty.to[i],
                        _offer.royalty.percentage[i],
                        signature
                    )
                );
            }
        }

        signature = keccak256(
            abi.encodePacked(
                _offer.timePeriod,
                _offer.owner,
                _offer.nonce,
                signature
            )
        );

        return signature;
    }

    /// @dev Get the hash of reserve info.
    /// @param _reserve Reserve info
    /// @return hash Hash of the reserve info
    function getReserveHash(ReserveInfo calldata _reserve)
        internal
        pure
        returns (bytes32)
    {
        bytes32 signature;

        signature = addAssets(_reserve.deposit, signature);

        signature = addAssets(_reserve.remaining, signature);

        signature = keccak256(abi.encodePacked(_reserve.duration, signature));

        return signature;
    }

    /// @dev Get the hash of the given pair of hashes.
    /// @param _a First hash
    /// @param _b Second hash
    function getHash(bytes32 _a, bytes32 _b) internal pure returns (bytes32) {
        return _a < _b ? _hash(_a, _b) : _hash(_b, _a);
    }

    /// @dev Hash two bytes32 variables efficiently using assembly
    /// @param a First bytes variable
    /// @param b Second bytes variable
    function _hash(bytes32 a, bytes32 b) internal pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }

    /// @dev Get the final signed hash by appending the prefix to params hash.
    /// @param _messageHash Hash of the params message
    /// @return hash Final signed hash
    function getSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    /* ===== Verify Merkle Proof ===== */

    /// @dev Verify that the given leaf exist in the passed root and has the correct proof.
    /// @param _root Merkle root of the given criterial
    /// @param _proof Merkle proof of the given leaf and root
    /// @param _leaf Hash of the token id to be searched in the root
    /// @return bool Validation of the leaf, root and proof
    function verifyMerkleProof(
        bytes32 _root,
        bytes32[] memory _proof,
        bytes32 _leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = _leaf;

        unchecked {
            for (uint256 i = 0; i < _proof.length; i++) {
                computedHash = getHash(computedHash, _proof[i]);
            }
        }

        return computedHash == _root;
    }

    /* ===== Make Signature Hashes ===== */

    /// @dev Add the hash of type assets to signature.
    /// @param _assets Assets to be added in hash
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function addAssets(Assets calldata _assets, bytes32 _sig)
        internal
        pure
        returns (bytes32)
    {
        _sig = addNFTsArray(_assets.tokens, _assets.tokenIds, _sig);
        _sig = addFTsArray(_assets.paymentTokens, _assets.amounts, _sig);

        return _sig;
    }

    /// @dev Add the hash of type swap assets to signature.
    /// @param _assets Assets to be added in hash
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function addSwapAssets(SwapAssets calldata _assets, bytes32 _sig)
        internal
        pure
        returns (bytes32)
    {
        _sig = addSwapNFTsArray(_assets.tokens, _assets.roots, _sig);
        _sig = addFTsArray(_assets.paymentTokens, _assets.amounts, _sig);

        return _sig;
    }

    /// @dev Add the hash of NFT information to signature.
    /// @param _tokens Array of nft address to be hashed
    /// @param _tokenIds Array of NFT tokenIds to be hashed
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function addNFTsArray(
        address[] memory _tokens,
        uint256[] memory _tokenIds,
        bytes32 _sig
    ) internal pure returns (bytes32) {
        assembly {
            let len := mload(_tokens)
            if eq(eq(len, mload(_tokenIds)), 0) {
                revert(0, 0)
            }

            let fmp := mload(0x40)

            let tokenPtr := add(_tokens, 0x20)
            let idPtr := add(_tokenIds, 0x20)

            for {
                let tokenIdx := tokenPtr
            } lt(tokenIdx, add(tokenPtr, mul(len, 0x20))) {
                tokenIdx := add(tokenIdx, 0x20)
                idPtr := add(idPtr, 0x20)
            } {
                mstore(fmp, mload(tokenIdx))
                mstore(add(fmp, 0x20), mload(idPtr))
                mstore(add(fmp, 0x40), _sig)

                _sig := keccak256(add(fmp, 0xc), 0x54)
            }
        }
        return _sig;
    }

    /// @dev Add the hash of FT information to signature.
    /// @param _paymentTokens Array of FT address to be hashed
    /// @param _amounts Array of FT amounts to be hashed
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function addFTsArray(
        address[] memory _paymentTokens,
        uint256[] memory _amounts,
        bytes32 _sig
    ) internal pure returns (bytes32) {
        assembly {
            let len := mload(_paymentTokens)
            if eq(eq(len, mload(_amounts)), 0) {
                revert(0, 0)
            }

            let fmp := mload(0x40)

            let tokenPtr := add(_paymentTokens, 0x20)
            let idPtr := add(_amounts, 0x20)

            for {
                let tokenIdx := tokenPtr
            } lt(tokenIdx, add(tokenPtr, mul(len, 0x20))) {
                tokenIdx := add(tokenIdx, 0x20)
                idPtr := add(idPtr, 0x20)
            } {
                mstore(fmp, mload(tokenIdx))
                mstore(add(fmp, 0x20), mload(idPtr))
                mstore(add(fmp, 0x40), _sig)
                _sig := keccak256(add(fmp, 0xc), 0x54)
            }
        }
        return _sig;
    }

    /// @dev Add the hash of NFT information to signature.
    /// @param _tokens Array of nft address to be hashed
    /// @param _roots Array of valid tokenId's merkle root to be hashed
    /// @param _sig Hash to which assets need to be added
    /// @return hash Hash result
    function addSwapNFTsArray(
        address[] memory _tokens,
        bytes32[] memory _roots,
        bytes32 _sig
    ) internal pure returns (bytes32) {
        assembly {
            let len := mload(_tokens)
            if eq(eq(len, mload(_roots)), 0) {
                revert(0, 0)
            }

            let fmp := mload(0x40)

            let tokenPtr := add(_tokens, 0x20)
            let idPtr := add(_roots, 0x20)

            for {
                let tokenIdx := tokenPtr
            } lt(tokenIdx, add(tokenPtr, mul(len, 0x20))) {
                tokenIdx := add(tokenIdx, 0x20)
                idPtr := add(idPtr, 0x20)
            } {
                mstore(fmp, mload(tokenIdx))
                mstore(add(fmp, 0x20), mload(idPtr))
                mstore(add(fmp, 0x40), _sig)

                _sig := keccak256(add(fmp, 0xc), 0x54)
            }
        }
        return _sig;
    }
}

// File: contracts/Interfaces/IVault.sol


pragma solidity ^0.8.9;


/// @title NF3 Vault Interface
/// @author Jack Jin
/// @author Priyam Anand
/// @dev This interface defines all the functions related to assets transfer and assets escrow.

interface IVault {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum VaultErrorCodes {
        CALLER_NOT_APPROVED,
        FAILED_TO_SEND_ETH,
        ETH_NOT_ALLOWED,
        INVALID_ASSET_TYPE,
        COULD_NOT_RECEIVE_KITTY,
        COULD_NOT_SEND_KITTY,
        INVALID_PUNK,
        COULD_NOT_RECEIVE_PUNK,
        COULD_NOT_SEND_PUNK
    }

    error VaultError(VaultErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when the assets have transferred.
    /// @param assets Assets
    /// @param from Sender address
    /// @param to Receiver address
    event AssetsTransferred(Assets assets, address from, address to);

    /// @dev Emits when the assets have been received by the vault.
    /// @param assets Assets
    /// @param from Sender address
    event AssetsReceived(Assets assets, address from);

    /// @dev Emits when the assets have been sent by the vault.
    /// @param assets Assets
    /// @param to Receiver address
    event AssetsSent(Assets assets, address to);

    /// @dev Emits when new swap address has set.
    /// @param oldSwapAddress Previous swap contract address
    /// @param newSwapAddress New swap contract address
    event SwapSet(address oldSwapAddress, address newSwapAddress);

    /// @dev Emits when new reserve address has set.
    /// @param oldReserveAddress Previous reserve contract address
    /// @param newReserveAddress New reserve contract address
    event ReserveSet(address oldReserveAddress, address newReserveAddress);

    /// @dev Emits when new whitelist contract address has set
    /// @param oldWhitelistAddress Previous whitelist contract address
    /// @param newWhitelistAddress New whitelist contract address
    event WhitelistSet(
        address oldWhitelistAddress,
        address newWhitelistAddress
    );

    /// @dev Emits when new loan contract address has set
    /// @param oldLoanAddress Previous loan contract address
    /// @param newLoanAddress New whitelist contract address
    event LoanSet(address oldLoanAddress, address newLoanAddress);

    /// -----------------------------------------------------------------------
    /// Transfer actions
    /// -----------------------------------------------------------------------

    /// @dev Transfer the assets "assets" from "from" to "to".
    /// @param assets Assets to be transfered
    /// @param from Sender address
    /// @param to Receiver address
    /// @param royalty Royalty info
    /// @param allowEth Bool variable if can send ETH or not
    function transferAssets(
        Assets calldata assets,
        address from,
        address to,
        Royalty calldata royalty,
        bool allowEth
    ) external;

    /// @dev Receive assets "assets" from "from" address to the vault
    /// @param assets Assets to be transfered
    /// @param from Sender address
    /// @param royalty Royalty info
    function receiveAssets(
        Assets calldata assets,
        address from,
        Royalty calldata royalty
    ) external;

    /// @dev Send assets "assets" from the vault to "_to" address
    /// @param assets Assets to be transfered
    /// @param to Receiver address
    function sendAssets(Assets calldata assets, address to) external;

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @dev Set Swap contract address.
    /// @param swapAddress Swap contract address
    function setSwap(address swapAddress) external;

    /// @dev Set Reserve contract address.
    /// @param reserveAddress Reserve contract address
    function setReserve(address reserveAddress) external;

    /// @dev Set Whitelist contract address.
    /// @param whitelistAddress Whitelist contract address
    function setWhitelist(address whitelistAddress) external;

    /// @dev Set Loan contract address
    /// @param loanAddress Whitelist contract address
    function setLoan(address loanAddress) external;
}

// File: contracts/Interfaces/ISwap.sol


pragma solidity ^0.8.9;


/// @title NF3 Swap Interface
/// @author Jack Jin
/// @author Priyam Anand
/// @dev This interface defines all the functions related to swap features of the platform.

interface ISwap {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum SwapErrorCodes {
        NOT_MARKET,
        CALLER_NOT_APPROVED,
        INVALID_NONCE,
        ITEM_EXPIRED,
        OPTION_DOES_NOT_EXIST,
        INTENDED_FOR_PEER_TO_PEER_TRADE
    }

    error SwapError(SwapErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Events
    /// -----------------------------------------------------------------------

    /// @dev Emits when listing has cancelled.
    /// @param listing Listing assets, details and seller's info
    event ListingCancelled(Listing listing);

    /// @dev Emits when swap offer has cancelled.
    /// @param offer Offer information
    event SwapOfferCancelled(SwapOffer offer);

    /// @dev Emits when collection offer has cancelled.
    /// @param offer Offer information
    event CollectionOfferCancelled(CollectionOffer offer);

    /// @dev Emits when direct swap has happened.
    /// @param listing Listing assets, details and seller's info
    /// @param offeredAssets Assets offered by the buyer
    /// @param user Address of the buyer
    event DirectSwapped(
        Listing listing,
        Assets offeredAssets,
        address indexed user
    );

    /// @dev Emits when swap offer has been accepted by the user.
    /// @param offer Swap offer assets and details
    /// @param considerationItems Assets given by the user
    /// @param user Address of the user who accepted the offer
    event UnlistedSwapOfferAccepted(
        SwapOffer offer,
        Assets considerationItems,
        address indexed user
    );

    /// @dev Emits when swap offer has been accepted by a listing owner.
    /// @param listing Listing assets info
    /// @param offer Swap offer info
    /// @param user Listing owner
    event ListedSwapOfferAccepted(
        Listing listing,
        SwapOffer offer,
        address indexed user
    );

    /// @dev Emits when collection swap offer has accepted by the seller.
    /// @param offer Collection offer assets and details
    /// @param considerationItems Assets given by the seller
    /// @param user Address of the buyer
    event CollectionOfferAccepted(
        CollectionOffer offer,
        Assets considerationItems,
        address indexed user
    );

    /// @dev Emits when status has changed.
    /// @param oldStatus Previous status
    /// @param newStatus New status
    event NonceSet(Status oldStatus, Status newStatus);

    /// @dev Emits when new market address has set.
    /// @param oldMarketAddress Previous market contract address
    /// @param newMarketAddress New market contract address
    event MarketSet(address oldMarketAddress, address newMarketAddress);

    /// @dev Emits when new reserve address has set.
    /// @param oldVaultAddress Previous vault contract address
    /// @param newVaultAddress New vault contract address
    event VaultSet(address oldVaultAddress, address newVaultAddress);

    /// @dev Emits when new reserve address has set.
    /// @param oldReserveAddress Previous reserve contract address
    /// @param newReserveAddress New reserve contract address
    event ReserveSet(address oldReserveAddress, address newReserveAddress);

    /// -----------------------------------------------------------------------
    /// Cancel Actions
    /// -----------------------------------------------------------------------

    /// @dev Cancel listing.
    /// @param listing Listing parameters
    /// @param signature Signature of the listing parameters
    /// @param user Listing owner
    function cancelListing(
        Listing calldata listing,
        bytes memory signature,
        address user
    ) external;

    /// @dev Cancel Swap offer.
    /// @param offer Collection offer patameter
    /// @param signature Signature of the offer patameters
    /// @param user Collection offer owner
    function cancelSwapOffer(
        SwapOffer calldata offer,
        bytes memory signature,
        address user
    ) external;

    /// @dev Cancel collection level offer.
    /// @param offer Collection offer patameter
    /// @param signature Signature of the offer patameters
    /// @param user Collection offer owner
    function cancelCollectionOffer(
        CollectionOffer calldata offer,
        bytes memory signature,
        address user
    ) external;

    /// -----------------------------------------------------------------------
    /// Swap Actions
    /// -----------------------------------------------------------------------

    /// @dev Direct swap of bundle of NFTs + FTs with other bundles.
    /// @param listing Listing assets and details
    /// @param signature Signature as a proof of listing
    /// @param swapId Index of swap option being used
    /// @param tokens NFT addresses being offered
    /// @param tokenIds Token ids of NFT being offered
    /// @param value Eth value sent in the function call
    /// @param royalty Buyer's royalty info
    function directSwap(
        Listing calldata listing,
        bytes memory signature,
        uint256 swapId,
        address user,
        address[] memory tokens,
        uint256[] memory tokenIds,
        bytes32[][] memory proofs,
        uint256 value,
        Royalty calldata royalty
    ) external;

    /// @dev Accpet unlisted direct swap offer.
    /// @dev User should see the swap offer and accpet that offer.
    /// @param offer Multi offer assets and details
    /// @param signature Signature as a proof of offer
    /// @param consideration Consideration assets been provided by the user
    /// @param proof Merkle proof that the considerationItems is valid
    /// @param user Address of the user who accepted this offer
    /// @param royalty Seller's royalty info
    function acceptUnlistedDirectSwapOffer(
        SwapOffer calldata offer,
        bytes memory signature,
        Assets calldata consideration,
        bytes32[] calldata proof,
        address user,
        uint256 value,
        Royalty calldata royalty
    ) external;

    /// @dev Accept listed direct swap offer.
    /// @dev Only listing owner should accept that offer.
    /// @param listing Listing assets and parameters
    /// @param listingSignature Signature as a proof of listing
    /// @param offer Offering assets and parameters
    /// @param offerSignature Signature as a proof of offer
    /// @param proof Mekrle proof that the listed assets are valid
    /// @param user Listing owner
    function acceptListedDirectSwapOffer(
        Listing calldata listing,
        bytes memory listingSignature,
        SwapOffer calldata offer,
        bytes memory offerSignature,
        bytes32[] calldata proof,
        address user
    ) external;

    /// @dev Accept collection offer.
    /// @dev Anyone who holds the consideration assets can accpet this offer.
    /// @param offer Collection offer assets and details
    /// @param signature Signature as a proof of offer
    /// @param tokens NFT addresses being offered
    /// @param tokenIds Token ids of NFT being offered
    /// @param user Seller address
    /// @param value Eth value send in the function call
    /// @param royalty Seller's royalty info
    function acceptCollectionOffer(
        CollectionOffer memory offer,
        bytes memory signature,
        address[] memory tokens,
        uint256[] memory tokenIds,
        bytes32[][] memory proofs,
        address user,
        uint256 value,
        Royalty calldata royalty
    ) external;

    /// -----------------------------------------------------------------------
    /// Storage Actions
    /// -----------------------------------------------------------------------

    /// @dev Set the nonce value of a user. Can only be called by reserve contract.
    /// @param _owner Address of the user
    /// @param _nonce Nonce value of the user
    /// @param _status Status to be set
    function setNonce(
        address _owner,
        uint256 _nonce,
        Status _status
    ) external;

    /// -----------------------------------------------------------------------
    /// View actions
    /// -----------------------------------------------------------------------

    /// @dev Check if the nonce is in correct status.
    /// @param owner Owner address
    /// @param nonce Nonce value
    /// @param status Status of nonce
    function checkNonce(
        address owner,
        uint256 nonce,
        Status status
    ) external view;

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @dev Set Market contract address.
    /// @param _marketAddress Market contract address
    function setMarket(address _marketAddress) external;

    /// @dev Set Vault contract address.
    /// @param _vaultAddress Vault contract address
    function setVault(address _vaultAddress) external;

    /// @dev Set Reserve contract address.
    /// @param _reserveAddress Reserve contract address
    function setReserve(address _reserveAddress) external;
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/Swap.sol


pragma solidity ^0.8.9;





/// @title NF3 Swap
/// @author Jack Jin
/// @author Priyam Anand
/// @notice This contract inherits from ISwap interface.
/// @notice Functions in this contract are not public callable. They can only be called through the public facing contract(NF3Proxy).
/// @dev This contract has the functions related to all types of swaps.

contract Swap is ISwap, Ownable {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------

    using Utils for *;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    /// @notice NF3Market contract address
    address public marketAddress;

    /// @notice Vault contract address
    address public vaultAddress;

    /// @notice Reserve contract address
    address public reserveAddress;

    /// @notice Mapping of user's and their nonce
    mapping(address => mapping(uint256 => Status)) public nonce;

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    modifier onlyMarket() {
        if (msg.sender != marketAddress) {
            revert SwapError(SwapErrorCodes.NOT_MARKET);
        }
        _;
    }

    modifier onlyApproved() {
        if (msg.sender != reserveAddress) {
            revert SwapError(SwapErrorCodes.CALLER_NOT_APPROVED);
        }
        _;
    }

    /* ===== INIT ===== */

    /// @dev Constructor
    constructor() {}

    /// -----------------------------------------------------------------------
    /// Cancel Actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from ISwap
    function cancelListing(
        Listing calldata _listing,
        bytes memory _signature,
        address _user
    ) external override onlyMarket {

        // Update the nonce.
        nonce[_listing.owner][_listing.nonce] = Status.EXHAUSTED;

        emit ListingCancelled(_listing);
    }

    /// @notice Inherit from ISwap
    function cancelSwapOffer(
        SwapOffer calldata _offer,
        bytes memory _signature,
        address _user
    ) external override onlyMarket {

        // Update the nonce.
        nonce[_offer.owner][_offer.nonce] = Status.EXHAUSTED;

        emit SwapOfferCancelled(_offer);
    }

    /// @notice Inherit from ISwap
    function cancelCollectionOffer(
        CollectionOffer calldata _offer,
        bytes memory _signature,
        address _user
    ) external override onlyMarket {

        // Update the nonce.
        nonce[_offer.owner][_offer.nonce] = Status.EXHAUSTED;

        emit CollectionOfferCancelled(_offer);
    }

    /// -----------------------------------------------------------------------
    /// Swap Actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from ISwap
    function directSwap(
        Listing calldata _listing,
        bytes memory _signature,
        uint256 _swapId,
        address _user,
        address[] memory _tokens,
        uint256[] memory _tokenIds,
        bytes32[][] memory _proofs,
        uint256 _value,
        Royalty calldata _royalty
    ) external override onlyMarket {

        // Verify swap option with swapId exist.
        SwapAssets memory swapAssets = swapExists(
            _listing.directSwaps,
            _swapId
        );

        // Verfy incoming assets to be the same.
        Assets memory offeredAssets = swapAssets.verifySwapAssets(
            _tokens,
            _tokenIds,
            _proofs,
            _value
        );

        Listing memory listing = _listing;

        emit DirectSwapped(listing, offeredAssets, _user);
    }

    /// @notice Inherit from ISwap
    function acceptUnlistedDirectSwapOffer(
        SwapOffer calldata _offer,
        bytes memory _signature,
        Assets calldata _consideration,
        bytes32[] calldata _proof,
        address _user,
        uint256 _value,
        Royalty calldata _royalty
    ) external override onlyMarket {

        // Update the nonce.
        nonce[_offer.owner][_offer.nonce] = Status.EXHAUSTED;

        emit UnlistedSwapOfferAccepted(_offer, _consideration, _user);
    }

    /// @notice Inherit from ISwap
    function acceptListedDirectSwapOffer(
        Listing calldata _listing,
        bytes memory _listingSignature,
        SwapOffer calldata _offer,
        bytes memory _offerSignature,
        bytes32[] calldata _proof,
        address _user
    ) external override onlyMarket {
        // Update the nonce.
        nonce[_listing.owner][_listing.nonce] = Status.EXHAUSTED;

        nonce[_offer.owner][_offer.nonce] = Status.EXHAUSTED;

        emit ListedSwapOfferAccepted(_listing, _offer, _user);
    }

    /// @notice Inherit from ISwap
    function acceptCollectionOffer(
        CollectionOffer calldata _offer,
        bytes memory _signature,
        address[] memory _tokens,
        uint256[] memory _tokenIds,
        bytes32[][] memory _proofs,
        address _user,
        uint256 _value,
        Royalty calldata _royalty
    ) external override onlyMarket {

        // Verify incomming assets to be the same as consideration items.
        Assets memory offeredAssets = _offer
            .considerationItems
            .verifySwapAssets(_tokens, _tokenIds, _proofs, _value);
        // Update the nonce.
        nonce[_offer.owner][_offer.nonce] = Status.EXHAUSTED;

        emit CollectionOfferAccepted(_offer, offeredAssets, _user);
    }

    /// -----------------------------------------------------------------------
    /// Storage Actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from ISwap
    function setNonce(
        address _owner,
        uint256 _nonce,
        Status _status
    ) external override onlyApproved {
        emit NonceSet(nonce[_owner][_nonce], _status);

        nonce[_owner][_nonce] = _status;
    }

    /// -----------------------------------------------------------------------
    /// Public functions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from ISwap
    function checkNonce(
        address _owner,
        uint256 _nonce,
        Status _status
    ) public view {
        if (nonce[_owner][_nonce] != _status) {
            revert SwapError(SwapErrorCodes.INVALID_NONCE);
        }
    }

    /// -----------------------------------------------------------------------
    /// Owner actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from ISwap
    function setMarket(address _marketAddress) external override onlyOwner {
        emit MarketSet(marketAddress, _marketAddress);

        marketAddress = _marketAddress;
    }

    /// @notice Inherit from ISwap
    function setVault(address _vaultAddress) external override onlyOwner {
        emit VaultSet(vaultAddress, _vaultAddress);

        vaultAddress = _vaultAddress;
    }

    /// @notice Inherit from ISwap
    function setReserve(address _reserveAddress) external override onlyOwner {
        emit ReserveSet(reserveAddress, _reserveAddress);

        reserveAddress = _reserveAddress;
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    /// @dev Check if the swap option with given swap id exist or not.
    /// @param _swaps All the swap options
    /// @param _swapId Swap id to be checked
    /// @return swap Swap assets at given index
    function swapExists(SwapAssets[] calldata _swaps, uint256 _swapId)
        internal
        pure
        returns (SwapAssets calldata)
    {
        return _swaps[_swapId];
    }

    /// @dev Check if the item has expired.
    /// @param _timePeriod Expiration time
    function checkExpiration(uint256 _timePeriod) internal view {
        if (_timePeriod < block.timestamp) {
            revert SwapError(SwapErrorCodes.ITEM_EXPIRED);
        }
    }
}