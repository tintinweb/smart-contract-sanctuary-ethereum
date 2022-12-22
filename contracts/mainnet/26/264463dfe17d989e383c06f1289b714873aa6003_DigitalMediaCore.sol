/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// File: VaultCoreInterface.sol



pragma solidity 0.8.9;

abstract contract VaultCoreInterface {
    function getVersion() public pure virtual returns (uint);
    function typeOfContract() public pure virtual returns (bytes32);
    function approveToken(
        uint256 _tokenId,
        address _tokenContractAddress) external virtual;
}
// File: RoyaltyRegistryInterface.sol



pragma solidity 0.8.9;


/**
 * Interface to the RoyaltyRegistry responsible for looking payout addresses
 */
abstract contract RoyaltyRegistryInterface {
    function getAddress(address custodial) external view virtual returns (address);
    function getMediaCustomPercentage(uint256 mediaId, address tokenAddress) external view virtual returns(uint16);
    function getExternalTokenPercentage(uint256 tokenId, address tokenAddress) external view virtual returns(uint16, uint16);
    function typeOfContract() virtual public pure returns (string calldata);
    function VERSION() virtual public pure returns (uint8);
}
// File: ApprovedCreatorRegistryInterface.sol



pragma solidity 0.8.9;


/**
 * Interface to the digital media store external contract that is
 * responsible for storing the common digital media and collection data.
 * This allows for new token contracts to be deployed and continue to reference
 * the digital media and collection data.
 */
abstract contract ApprovedCreatorRegistryInterface {

    function getVersion() virtual public pure returns (uint);
    function typeOfContract() virtual public pure returns (string calldata);
    function isOperatorApprovedForCustodialAccount(
        address _operator,
        address _custodialAddress) virtual public view returns (bool);

}
// File: utils/Collaborator.sol



pragma solidity 0.8.9;

library Collaborator {
    bytes32 public constant TYPE_HASH = keccak256("Share(address account,uint48 value,uint48 royalty)");

    struct Share {
        address payable account;
        uint48 value;
        uint48 royalty;
    }

    function hash(Share memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value, part.royalty));
    }
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

// File: OBOControl.sol



pragma solidity 0.8.9;



contract OBOControl is Ownable {
    address public oboAdmin;
    uint256 constant public newAddressWaitPeriod = 1 days;
    bool public canAddOBOImmediately = true;

    // List of approved on behalf of users.
    mapping (address => uint256) public approvedOBOs;

    event NewOBOAddressEvent(
        address OBOAddress,
        bool action);

    event NewOBOAdminAddressEvent(
        address oboAdminAddress);

    modifier onlyOBOAdmin() {
        require(owner() == _msgSender() || oboAdmin == _msgSender(), "not oboAdmin");
        _;
    }

    function setOBOAdmin(address _oboAdmin) external onlyOwner {
        oboAdmin = _oboAdmin;
        emit NewOBOAdminAddressEvent(_oboAdmin);
    }

    /**
     * Add a new approvedOBO address. The address can be used after wait period.
     */
    function addApprovedOBO(address _oboAddress) external onlyOBOAdmin {
        require(_oboAddress != address(0), "cant set to 0x");
        require(approvedOBOs[_oboAddress] == 0, "already added");
        approvedOBOs[_oboAddress] = block.timestamp;
        emit NewOBOAddressEvent(_oboAddress, true);
    }

    /**
     * Removes an approvedOBO immediately.
     */
    function removeApprovedOBO(address _oboAddress) external onlyOBOAdmin {
        delete approvedOBOs[_oboAddress];
        emit NewOBOAddressEvent(_oboAddress, false);
    }

    /*
     * Add OBOAddress for immediate use. This is an internal only Fn that is called
     * only when the contract is deployed.
     */
    function addApprovedOBOImmediately(address _oboAddress) internal onlyOwner {
        require(_oboAddress != address(0), "addr(0)");
        // set the date to one in past so that address is active immediately.
        approvedOBOs[_oboAddress] = block.timestamp - newAddressWaitPeriod - 1;
        emit NewOBOAddressEvent(_oboAddress, true);
    }

    function addApprovedOBOAfterDeploy(address _oboAddress) external onlyOBOAdmin {
        require(canAddOBOImmediately == true, "disabled");
        addApprovedOBOImmediately(_oboAddress);
    }

    function blockImmediateOBO() external onlyOBOAdmin {
        canAddOBOImmediately = false;
    }

    /*
     * Helper function to verify is a given address is a valid approvedOBO address.
     */
    function isValidApprovedOBO(address _oboAddress) public view returns (bool) {
        uint256 createdAt = approvedOBOs[_oboAddress];
        if (createdAt == 0) {
            return false;
        }
        return block.timestamp - createdAt > newAddressWaitPeriod;
    }

    /**
    * @dev Modifier to make the obo calls only callable by approved addressess
    */
    modifier isApprovedOBO() {
        require(isValidApprovedOBO(msg.sender), "unauthorized OBO user");
        _;
    }
}
// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;








/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

// File: DigitalMediaToken.sol



pragma solidity 0.8.9;








contract DigitalMediaToken is ERC721, OBOControl, Pausable {
    // creator address has to be set during deploy via constructor only.
    address public singleCreatorAddress;
    address public signerAddress;
    bool public enableExternalMinting;
    bool public canRoyaltyRegistryChange = true;

    struct DigitalMedia {
        uint32 totalSupply; // The total supply of collectibles available
        uint32 printIndex; // The current print index
        address creator; // The creator of the collectible
        uint16 royalty;
        bool immutableMedia;
        Collaborator.Share[] collaborators;
        string metadataPath; // Hash of the media content, with the actual data stored on a secondary
        // data store (ideally decentralized)
    }

    struct DigitalMediaRelease {
        uint32 printEdition; // The unique edition number of this digital media release
        uint256 digitalMediaId; // Reference ID to the digital media metadata
    }

    ApprovedCreatorRegistryInterface public creatorRegistryStore;
    RoyaltyRegistryInterface public royaltyStore;
    VaultCoreInterface public vaultStore;

    // Event fired when a new digital media is created. No point in returning printIndex
    // since its always zero when created.
    event DigitalMediaCreateEvent(
        uint256 id,
        address creator,
        uint32 totalSupply,
        uint32 royalty,
        bool immutableMedia,
        string metadataPath);

    event DigitalMediaReleaseCreateEvent(
        uint256 id,
        address owner,
        uint32 printEdition,
        string tokenURI,
        uint256 digitalMediaId);

    // Event fired when a creator assigns a new creator address.
    event ChangedCreator(
        address creator,
        address newCreator);

    // Event fired when a digital media is burned
    event DigitalMediaBurnEvent(
        uint256 id,
        address caller);

    // Event fired when burning a token
    event DigitalMediaReleaseBurnEvent(
        uint256 tokenId,
        address owner);

    event NewSignerEvent(
        address signer);

    event NewRoyaltyEvent(
        uint16 value);

    // ID to Digital Media object
    mapping (uint256 => DigitalMedia) public idToDigitalMedia;
    // Maps internal ERC721 token ID to digital media release object.
    mapping (uint256 => DigitalMediaRelease) public tokenIdToDigitalMediaRelease;
    // Maps a creator address to a new creator address.  Useful if a creator
    // changes their address or the previous address gets compromised.
    mapping (address => address) public changedCreators;

    constructor(string memory _tokenName, string memory _tokenSymbol) ERC721(_tokenName, _tokenSymbol) {}

    // Set the creator registry address upon construction. Immutable.
    function setCreatorRegistryStore(address _crsAddress) internal {
        ApprovedCreatorRegistryInterface candidateCreatorRegistryStore = ApprovedCreatorRegistryInterface(_crsAddress);
        // require(candidateCreatorRegistryStore.getVersion() == 1, "registry store is not version 1");
        // Simple check to make sure we are adding the registry contract indeed
        // https://fravoll.github.io/solidity-patterns/string_equality_comparison.html
        bytes32 contractType = keccak256(abi.encodePacked(candidateCreatorRegistryStore.typeOfContract()));
        // keccak256(abi.encodePacked("approvedCreatorRegistry")) = 0x74cb6de1099c3d993f336da7af5394f68038a23980424e1ae5723d4110522be4
        // keccak256(abi.encodePacked("approvedCreatorRegistryReadOnly")) = 0x9732b26dfb8751e6f1f71e8f21b28a237cfe383953dce7db3dfa1777abdb2791
        require(
            contractType == 0x74cb6de1099c3d993f336da7af5394f68038a23980424e1ae5723d4110522be4
            || contractType == 0x9732b26dfb8751e6f1f71e8f21b28a237cfe383953dce7db3dfa1777abdb2791,
            "not crtrRegistry");
        creatorRegistryStore = candidateCreatorRegistryStore;
    }

    function setRoyaltyRegistryStore(address _royaltyStore) external whenNotPaused onlyOBOAdmin {
        require(canRoyaltyRegistryChange == true, "no");
        RoyaltyRegistryInterface candidateRoyaltyStore = RoyaltyRegistryInterface(_royaltyStore);
        require(candidateRoyaltyStore.VERSION() == 1, "roylty v!= 1");
        bytes32 contractType = keccak256(abi.encodePacked(candidateRoyaltyStore.typeOfContract()));
        // keccak256(abi.encodePacked("royaltyRegistry")) = 0xb590ff355bf2d720a7e957392d3b76fd1adda1832940640bf5d5a7c387fed323
        require(contractType == 0xb590ff355bf2d720a7e957392d3b76fd1adda1832940640bf5d5a7c387fed323,
            "not royalty");
        royaltyStore = candidateRoyaltyStore;
    }

    function setRoyaltyRegistryForever() external whenNotPaused onlyOwner {
        canRoyaltyRegistryChange = false;
    }

    function setVaultStore(address _vaultStore) external whenNotPaused onlyOwner {
        VaultCoreInterface candidateVaultStore = VaultCoreInterface(_vaultStore);
        bytes32 contractType = candidateVaultStore.typeOfContract();
        require(contractType == 0x6d707661756c7400000000000000000000000000000000000000000000000000, "invalid mpvault");
        vaultStore = candidateVaultStore;
    }

    /*
     * Set signer address on the token contract. Setting signer means we are opening
     * the token contract for external accounts to create tokens. Call this to change
     * the signer immediately.
     */
    function setSignerAddress(address _signerAddress, bool _enableExternalMinting) external whenNotPaused
            isApprovedOBO {
        require(_signerAddress != address(0), "cant be zero");
        signerAddress = _signerAddress;
        enableExternalMinting = _enableExternalMinting;
        emit NewSignerEvent(signerAddress);
    }

     /**
     * Validates that the Registered store is initialized.
     */
    modifier registryInitialized() {
        require(address(creatorRegistryStore) != address(0), "registry = 0x0");
        _;
    }

    /**
     * Validates that the Vault store is initialized.
     */
    modifier vaultInitialized() {
        require(address(vaultStore) != address(0), "vault = 0x0");
        _;
    }

    function _setCollaboratorsOnDigitalMedia(DigitalMedia storage _digitalMedia,
            Collaborator.Share[] memory _collaborators) internal {
        uint total = 0;
        uint totalRoyalty = 0;
        for (uint i = 0; i < _collaborators.length; i++) {
            require(_collaborators[i].account != address(0x0) ||
                _collaborators[i].account != _digitalMedia.creator, "collab 0x0/creator");
            require(_collaborators[i].value != 0 || _collaborators[i].royalty != 0,
                "share/royalty = 0");
            _digitalMedia.collaborators.push(_collaborators[i]);
            total = total + _collaborators[i].value;
            totalRoyalty = totalRoyalty + _collaborators[i].royalty;
        }
        require(total <= 10000, "total <=10000");
        require(totalRoyalty <= 10000, "totalRoyalty <=10000");
    }

    /**
     * Creates a new digital media object.
     * @param  _creator address  the creator of this digital media
     * @param  _totalSupply uint32 the total supply a creation could have
     * @param  _metadataPath string the path to the ipfs metadata
     * @return uint the new digital media id
     */
    function _createDigitalMedia(
            address _creator, uint256 _onchainId, uint32 _totalSupply,
            string memory _metadataPath, Collaborator.Share[] memory _collaborators,
            uint16 _royalty, bool _immutableMedia)
            internal returns (uint) {
        // If this is a single creator contract make sure _owner matches single creator
        if (singleCreatorAddress != address(0)) {
            require(singleCreatorAddress == _creator, "Creator must match single creator address");
        }
        // Verify this media does not exist already
        DigitalMedia storage _digitalMedia = idToDigitalMedia[_onchainId];
        require(_digitalMedia.creator == address(0), "media already exists");
        // TODO: Dannie check this require throughly.
        require((_totalSupply > 0) && address(_creator) != address(0) && _royalty <= 10000, "invalid params");
        _digitalMedia.printIndex = 0;
        _digitalMedia.totalSupply = _totalSupply;
        _digitalMedia.creator = _creator;
        _digitalMedia.metadataPath = _metadataPath;
        _digitalMedia.immutableMedia = _immutableMedia;
        _digitalMedia.royalty = _royalty;
        _setCollaboratorsOnDigitalMedia(_digitalMedia, _collaborators);
        emit DigitalMediaCreateEvent(
            _onchainId, _creator, _totalSupply,
            _royalty, _immutableMedia, _metadataPath);
        return _onchainId;
    }

    /**
     * Creates _count number of new digital media releases (i.e a token).
     * Bumps up the print index by _count.
     * @param  _owner address the owner of the digital media object
     * @param  _digitalMediaId uint256 the digital media id
     */
    function _createDigitalMediaReleases(
        address _owner, uint256 _digitalMediaId, uint256[] memory _releaseIds)
        internal {
        require(_releaseIds.length > 0 && _releaseIds.length < 10000, "0 < count <= 10000");
        DigitalMedia storage _digitalMedia = idToDigitalMedia[_digitalMediaId];
        require(_digitalMedia.creator != address(0), "media does not exist");
        uint32 currentPrintIndex = _digitalMedia.printIndex;
        require(_checkApprovedCreator(_digitalMedia.creator, _owner), "Creator not approved");
        require(_releaseIds.length + currentPrintIndex <= _digitalMedia.totalSupply, "Total supply exceeded.");

        for (uint32 i=0; i < _releaseIds.length; i++) {
            uint256 newDigitalMediaReleaseId = _releaseIds[i];
            DigitalMediaRelease storage release = tokenIdToDigitalMediaRelease[newDigitalMediaReleaseId];
            require(release.printEdition == 0, "tokenId already used");
            uint32 newPrintEdition = currentPrintIndex + 1 + i;
            release.printEdition = newPrintEdition;
            release.digitalMediaId = _digitalMediaId;
            emit DigitalMediaReleaseCreateEvent(
                newDigitalMediaReleaseId,
                _owner,
                newPrintEdition,
                _digitalMedia.metadataPath,
                _digitalMediaId
            );

            // This will assign ownership and also emit the Transfer event as per ERC721
            _mint(_owner, newDigitalMediaReleaseId);
        }
        _digitalMedia.printIndex = _digitalMedia.printIndex + uint32(_releaseIds.length);
    }


    /**
     * Checks that a given caller is an approved creator and is allowed to mint or burn
     * tokens.  If the creator was changed it will check against the updated creator.
     * @param  _caller the calling address
     * @return bool allowed or not
     */
    function _checkApprovedCreator(address _creator, address _caller)
            internal
            view
            returns (bool) {
        address approvedCreator = changedCreators[_creator];
        if (approvedCreator != address(0)) {
            return approvedCreator == _caller;
        } else {
            return _creator == _caller;
        }
    }

    /**
     * Burns a token for a given tokenId and caller.
     * @param  _tokenId the id of the token to burn.
     * @param  _caller the address of the caller.
     */
    function _burnToken(uint256 _tokenId, address _caller) internal {
        address owner = ownerOf(_tokenId);
        require(_isApprovedOrOwner(_caller, _tokenId), "ERC721: burn caller is not owner nor approved");
        _burn(_tokenId);
        // Dont delete the tokenIdToDMR as we dont want to reissue another release
        // with the same id. Leaving the data will prevent reissuing.
        // delete tokenIdToDigitalMediaRelease[_tokenId];
        emit DigitalMediaReleaseBurnEvent(_tokenId, owner);
    }

    /**
     * Burns a digital media.  Once this function succeeds, this digital media
     * will no longer be able to mint any more tokens.  Existing tokens need to be
     * burned individually though.
     * @param  _digitalMediaId the id of the digital media to burn
     * @param  _caller the address of the caller.
     */
    function _burnDigitalMedia(uint256 _digitalMediaId, address _caller) internal {
        DigitalMedia storage _digitalMedia = idToDigitalMedia[_digitalMediaId];
        require(_digitalMedia.creator != address(0), "media does not exist");
        require(_checkApprovedCreator(_digitalMedia.creator, _caller) ||
                isApprovedForAll(_digitalMedia.creator, _caller),
                "Failed digital media burn.  Caller not approved.");

        _digitalMedia.printIndex = _digitalMedia.totalSupply;
        emit DigitalMediaBurnEvent(_digitalMediaId, _caller);
    }

    /**
       * @dev Returns an URI for a given token ID
       * @dev Throws if the token ID does not exist. May return an empty string.
       * @param _tokenId uint256 ID of the token to query
       */
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId));
        DigitalMediaRelease storage digitalMediaRelease = tokenIdToDigitalMediaRelease[_tokenId];
        uint256 _digitalMediaId = digitalMediaRelease.digitalMediaId;
        DigitalMedia storage _digitalMedia = idToDigitalMedia[_digitalMediaId];
        string memory prefix = "ipfs://";
        return string(abi.encodePacked(prefix, string(_digitalMedia.metadataPath)));
    }

    /*
     * Look up a royalty payout address if royaltyStore is set otherwise we returns
     * the same argument.
     */
    function _getRoyaltyAddress(address custodial) internal view returns(address) {
        return address(royaltyStore) == address(0) ? custodial : royaltyStore.getAddress(custodial);
    }
}
// File: DigitalMediaCore.sol



pragma solidity 0.8.9;




contract DigitalMediaCore is DigitalMediaToken {
    using ECDSA for bytes32;
    uint8 constant public VERSION = 3;
    struct DigitalMediaCreateRequest {
        uint256 onchainId; // onchain id for this media
        uint32 totalSupply; // The total supply of collectibles available
        address creator; // The creator of the collectible
        uint16 royalty;
        bool immutableMedia;
        Collaborator.Share[] collaborators;
        string metadataPath; // Hash of the media content
        uint256[] releaseIds; // number of releases to mint
    }

    struct DigitalMediaUpdateRequest {
        uint256 onchainId; // onchain id for this media
        uint256 metadataId;
        uint32 totalSupply; // The total supply of collectibles available
        address creator; // The creator of the collectible
        uint16 royalty;
        Collaborator.Share[] collaborators;
        string metadataPath; // Hash of the media content
    }

    struct DigitalMediaReleaseCreateRequest {
        uint256 digitalMediaId;
        uint256[] releaseIds; // number of releases to mint
        address owner;
    }

    struct TokenDestinationRequest {
        uint256 tokenId;
        address destinationAddress;
    }

    struct ChainSignatureRequest {
        uint256 onchainId;
        address owner;
    }

    struct PayoutInfo {
        address user;
        uint256 amount;
    }

    event DigitalMediaUpdateEvent(
        uint256 id,
        uint32 totalSupply,
        uint16 royalty,
        string metadataPath,
        uint256 metadataId);

    event MediasImmutableEvent(
        uint256[] mediaIds);
    
    event MediaImmutableEvent(
        uint256 mediaId);


    constructor(string memory _tokenName, string memory _tokenSymbol,
            address _crsAddress) DigitalMediaToken(_tokenName, _tokenSymbol) {
        setCreatorRegistryStore(_crsAddress);
    }

    /**
     * Retrieves a Digital Media object.
     */
    function getDigitalMedia(uint256 _id)
            external
            view
            returns (DigitalMedia memory) {
        DigitalMedia memory _digitalMedia = idToDigitalMedia[_id];
        require(_digitalMedia.creator != address(0), "DigitalMedia not found.");
        return _digitalMedia;
    }

    /**
     * Ok I am not proud of this function but sale conract needs to getDigitalMedia
     * while I tried to write a interface file DigitalMediaBurnInterfaceV3.sol I could
     * not include the DigitalMedia struct in that abstract contract. So I am writing
     * another endpoint to return just the bare minimum data required for the sale contract.
     */
    function getDigitalMediaForSale(uint256 _id) external view returns(
            address, bool, uint16) {
        DigitalMedia storage _digitalMedia = idToDigitalMedia[_id];
        require(_digitalMedia.creator != address(0), "DigitalMedia not found.");
        return (_digitalMedia.creator, _digitalMedia.collaborators.length > 0,
                _digitalMedia.royalty);
    }

    /**
     * Retrieves a Digital Media Release (i.e a token)
     */
    function getDigitalMediaRelease(uint256 _id)
            external
            view
            returns (DigitalMediaRelease memory) {
        require(_exists(_id), "release does not exist");
        DigitalMediaRelease storage digitalMediaRelease = tokenIdToDigitalMediaRelease[_id];
        return digitalMediaRelease;
    }

    /**
     * Creates a new digital media object and mints it's first digital media release token.
     * The onchainid and creator has to be signed by signerAddress in order to create.
     * No creations of any kind are allowed when the contract is paused.
     */
    function createDigitalMediaAndReleases(
            DigitalMediaCreateRequest memory request,
            bytes calldata signature)
            external
            whenNotPaused {
        require(request.creator == msg.sender, "msgSender != creator");
        ChainSignatureRequest memory signatureRequest = ChainSignatureRequest(request.onchainId, request.creator);
        _verifyReleaseRequestSignature(signatureRequest, signature);
        uint256 digitalMediaId = _createDigitalMedia(msg.sender, request.onchainId, request.totalSupply,
            request.metadataPath, request.collaborators, request.royalty, request.immutableMedia);
        _createDigitalMediaReleases(msg.sender, digitalMediaId, request.releaseIds);
    }

    /**
     * Creates a new digital media release (token) for a given digital media id.
     * This request needs to be signed by the authorized signerAccount to prevent
     * from user stealing media & release ids on chain and frontrunning.
     * No creations of any kind are allowed when the contract is paused.
     */
    function createDigitalMediaReleases(
            DigitalMediaReleaseCreateRequest memory request)
            external
            whenNotPaused {
        // require(request.owner == msg.sender, "owner != msg.sender");
        require(signerAddress != address(0), "signer not set");
        _createDigitalMediaReleases(msg.sender, request.digitalMediaId, request.releaseIds);
    }

    /**
     * Creates a new digital media object and mints it's digital media release tokens.
     * Called on behalf of the _owner. Pass count to mint `n` number of tokens.
     *
     * Only approved creators are allowed to create Obo.
     *
     * No creations of any kind are allowed when the contract is paused.
     */
    function oboCreateDigitalMediaAndReleases(
                DigitalMediaCreateRequest memory request)
            external
            whenNotPaused
            isApprovedOBO {
        uint256 digitalMediaId = _createDigitalMedia(request.creator, request.onchainId, request.totalSupply, request.metadataPath,
            request.collaborators, request.royalty, request.immutableMedia);
        _createDigitalMediaReleases(request.creator, digitalMediaId, request.releaseIds);
    }

    /**
     * Create many digital medias in one call. 
     */
    function oboCreateManyDigitalMedias(
            DigitalMediaCreateRequest[] memory requests) external whenNotPaused isApprovedOBO {
        for (uint32 i=0; i < requests.length; i++) {
            DigitalMediaCreateRequest memory request = requests[i];
            _createDigitalMedia(request.creator, request.onchainId, request.totalSupply,
                request.metadataPath, request.collaborators, request.royalty, request.immutableMedia);
        }
    }

    /**
     * Creates multiple digital media releases (tokens) for a given digital media id.
     * Called on behalf of the _owner.
     *
     * Only approved creators are allowed to create Obo.
     *
     * No creations of any kind are allowed when the contract is paused.
     */
    function oboCreateDigitalMediaReleases(
                DigitalMediaReleaseCreateRequest memory request)
            external
            whenNotPaused
            isApprovedOBO {
        _createDigitalMediaReleases(request.owner, request.digitalMediaId, request.releaseIds);
    }

    /*
     * Create multiple digital medias and associated releases (tokens). Called on behalf
     * of the _owner. Each media should mint atleast 1 token.
     * No creations of any kind are allowed when the contract is paused.
     */
    function oboCreateManyDigitalMediasAndReleases(
        DigitalMediaCreateRequest[] memory requests) external whenNotPaused isApprovedOBO {
        for (uint32 i=0; i < requests.length; i++) {
            DigitalMediaCreateRequest memory request = requests[i];
            uint256 digitalMediaId = _createDigitalMedia(request.creator, request.onchainId, request.totalSupply,
                request.metadataPath, request.collaborators, request.royalty, request.immutableMedia);
            _createDigitalMediaReleases(request.creator, digitalMediaId, request.releaseIds);
        }
    }

    /*
     * Create multiple releases (tokens) associated with existing medias. Called on behalf
     * of the _owner.
     * No creations of any kind are allowed when the contract is paused.
     */
    function oboCreateManyReleases(
        DigitalMediaReleaseCreateRequest[] memory requests) external whenNotPaused isApprovedOBO {
        for (uint32 i=0; i < requests.length; i++) {
            DigitalMediaReleaseCreateRequest memory request = requests[i];
            DigitalMedia storage _digitalMedia = idToDigitalMedia[request.digitalMediaId];
            require(_digitalMedia.creator != address(0), "DigitalMedia not found.");
            _createDigitalMediaReleases(request.owner, request.digitalMediaId, request.releaseIds);
        }
    }

    /**
     * Override the isApprovalForAll to check for a special oboApproval list.  Reason for this
     * is that we can can easily remove obo operators if they every become compromised.
     */
    function isApprovedForAll(address _owner, address _operator) public view override registryInitialized returns (bool) {
        if (creatorRegistryStore.isOperatorApprovedForCustodialAccount(_operator, _owner) == true) {
            return true;
        } else {
            return super.isApprovedForAll(_owner, _operator);
        }
    }

    /**
     * Changes the creator for the current sender, in the event we
     * need to be able to mint new tokens from an existing digital media
     * print production. When changing creator, the old creator will
     * no longer be able to mint tokens.
     *
     * A creator may need to be changed:
     * 1. If we want to allow a creator to take control over their token minting (i.e go decentralized)
     * 2. If we want to re-issue private keys due to a compromise.  For this reason, we can call this function
     * when the contract is paused.
     * @param _creator the creator address
     * @param _newCreator the new creator address
     */
    function changeCreator(address _creator, address _newCreator) external {
        address approvedCreator = changedCreators[_creator];
        require(msg.sender != address(0) && _creator != address(0), "Creator must be valid non 0x0 address.");
        require(msg.sender == _creator || msg.sender == approvedCreator, "Unauthorized caller.");
        if (approvedCreator == address(0)) {
            changedCreators[msg.sender] = _newCreator;
        } else {
            require(msg.sender == approvedCreator, "Unauthorized caller.");
            changedCreators[_creator] = _newCreator;
        }
        emit ChangedCreator(_creator, _newCreator);
    }

    // standard ERC721 burn interface
    function burn(uint256 _tokenId) external {
        _burnToken(_tokenId, msg.sender);
    }

    function burnToken(uint256 _tokenId) external {
        _burnToken(_tokenId, msg.sender);
    }

    /**
     * Ends the production run of a digital media.  Afterwards no more tokens
     * will be allowed to be printed for each digital media.  Used when a creator
     * makes a mistake and wishes to burn and recreate their digital media.
     *
     * When a contract is paused we do not allow new tokens to be created,
     * so stopping the production of a token doesn't have much purpose.
     */
    function burnDigitalMedia(uint256 _digitalMediaId) external whenNotPaused {
        _burnDigitalMedia(_digitalMediaId, msg.sender);
    }

    /*
     * Batch transfer multiple tokens from their sources to destination
     * Owner / ApproveAll user can call this endpoint.
     */
    function safeTransferMany(TokenDestinationRequest[] memory requests) external whenNotPaused {
        for (uint32 i=0; i < requests.length; i++) {
            TokenDestinationRequest memory request = requests[i];
            safeTransferFrom(ownerOf(request.tokenId), request.destinationAddress, request.tokenId);
        }
    }

    function _updateDigitalMedia(DigitalMediaUpdateRequest memory request,
            DigitalMedia storage _digitalMedia) internal {
        require(_digitalMedia.immutableMedia == false, "immutable");
        require(_digitalMedia.printIndex <= request.totalSupply, "< currentPrintIndex");
        _digitalMedia.totalSupply = request.totalSupply;
        _digitalMedia.metadataPath = request.metadataPath;
        _digitalMedia.royalty = request.royalty;
        delete _digitalMedia.collaborators;
        _setCollaboratorsOnDigitalMedia(_digitalMedia, request.collaborators);
        emit DigitalMediaUpdateEvent(request.onchainId,
            request.totalSupply, request.royalty, request.metadataPath,
            request.metadataId);
    }

    function updateMedia(DigitalMediaUpdateRequest memory request) external {
        require(request.creator == msg.sender, "msgSender != creator");
        DigitalMedia storage _digitalMedia = idToDigitalMedia[request.onchainId];
        require(_digitalMedia.creator != address(0) && _digitalMedia.creator == msg.sender,
            "DM creator issue");
        _updateDigitalMedia(request, _digitalMedia);
    }

    /*
     * Update existing digitalMedia's metadata, totalSupply, collaborated, royalty
     * and immutable attribute. Once a media is immutable you cannot call this function
     */
    function updateManyMedias(DigitalMediaUpdateRequest[] memory requests)
            external whenNotPaused isApprovedOBO vaultInitialized {
        for (uint32 i=0; i < requests.length; i++) {
            DigitalMediaUpdateRequest memory request = requests[i];
            DigitalMedia storage _digitalMedia = idToDigitalMedia[request.onchainId];
            // Call creator registry to check if the creator gave approveAll to vault
            require(_digitalMedia.creator != address(0) && _digitalMedia.creator == request.creator,
                "DM creator");
            require(isApprovedForAll(_digitalMedia.creator, address(vaultStore)) == true, "approveall missing");
            _updateDigitalMedia(request, _digitalMedia);
        }
    }

    function makeMediaImmutable(uint256 mediaId) external {
        DigitalMedia storage _digitalMedia = idToDigitalMedia[mediaId];
        require(_digitalMedia.creator != address(0) && _digitalMedia.creator == msg.sender,
            "DM creator");
        require(_digitalMedia.immutableMedia == false, "DM immutable");
        _digitalMedia.immutableMedia = true;
        emit MediaImmutableEvent(mediaId);
    }

    /*
     * Once we update media and feel satisfied with the changes, we can render it immutable now.
     */
    function makeMediasImmutable(uint256[] memory mediaIds) external whenNotPaused isApprovedOBO vaultInitialized {
        for (uint32 i=0; i < mediaIds.length; i++) {
            uint256 mediaId = mediaIds[i];
            DigitalMedia storage _digitalMedia = idToDigitalMedia[mediaId];
            require(_digitalMedia.creator != address(0), "DM not found.");
            require(_digitalMedia.immutableMedia == false, "DM immutable");
            require(isApprovedForAll(_digitalMedia.creator, address(vaultStore)) == true, "approveall missing");
            _digitalMedia.immutableMedia = true;
        }
        emit MediasImmutableEvent(mediaIds);
    }

    function _lookUpTokenAndReturnEntries(uint256 _tokenId, uint256 _salePrice,
            bool _isRoyalty) internal view returns(PayoutInfo[] memory entries) {
        require(_exists(_tokenId), "no token");
        DigitalMediaRelease memory digitalMediaRelease = tokenIdToDigitalMediaRelease[_tokenId];
        DigitalMedia memory _digitalMedia = idToDigitalMedia[digitalMediaRelease.digitalMediaId];
        uint256 size = _digitalMedia.collaborators.length + 1;
        entries = new PayoutInfo[](size);
        uint totalRoyaltyPercentage = 0;
        for (uint256 index = 0; index < _digitalMedia.collaborators.length; index++) {
            address payoutAddress = _getRoyaltyAddress(_digitalMedia.collaborators[index].account);
            if (_isRoyalty == true) {
                entries[index] = PayoutInfo(payoutAddress,
                    _digitalMedia.collaborators[index].royalty * _digitalMedia.royalty * _salePrice / (10000 * 10000));
                totalRoyaltyPercentage = totalRoyaltyPercentage + _digitalMedia.collaborators[index].royalty;
            } else {
                entries[index] = PayoutInfo(payoutAddress,
                _digitalMedia.collaborators[index].value * _salePrice / 10000);
                totalRoyaltyPercentage = totalRoyaltyPercentage + _digitalMedia.collaborators[index].value;
            }
        }
        address creatorPayoutAddress = _getRoyaltyAddress(_digitalMedia.creator);
        if (_isRoyalty == true) {
            entries[size-1]= PayoutInfo(creatorPayoutAddress, _salePrice * (10000 - totalRoyaltyPercentage) * _digitalMedia.royalty / (10000 * 10000));
        } else {
            entries[size-1]= PayoutInfo(creatorPayoutAddress, _salePrice * (10000 - totalRoyaltyPercentage) / 10000);
        }
        return entries;
    }

    /*
     * Return royalty for a given Token. Returns an array of PayoutInfo which consists
     * of address to pay to and amount.
     * Thank you for posting this gist. Helped me to figure out how to return an array of structs.
     * https://gist.github.com/minhth1905/4b6208372fc5e7343b5ce1fb6d42c942
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (
            PayoutInfo[] memory) {
        return _lookUpTokenAndReturnEntries(_tokenId, _salePrice, true);
    }

    /*
     * Given salePrice break down the amount between the creator and collabarators
      * according to their percentages.
     */
    function saleInfo(uint256 _tokenId, uint256 _totalPayout) external view returns (
            PayoutInfo[] memory) {
        return _lookUpTokenAndReturnEntries(_tokenId, _totalPayout, false);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /*
     * helper to verify signature signed by non-custodial creator.
     */
    function _verifyReleaseRequestSignature(
            ChainSignatureRequest memory request,
            bytes calldata signature) internal view {
        require(enableExternalMinting == true, "ext minting disabled");
        bytes32 encodedRequest = keccak256(abi.encode(request));
        address addressWhoSigned = encodedRequest.recover(signature);
        require(addressWhoSigned == signerAddress, "sig error");
    }
}