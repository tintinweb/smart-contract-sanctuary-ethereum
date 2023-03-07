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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

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
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../interface/IBurner.sol";
import "../interface/IBurnSigner.sol";
import "../common/Signer.sol";
import "openzeppelin-contracts/utils/cryptography/EIP712.sol";

/// Signer for Burn transactions. Used to execute burns via the `Burner` contract.
contract BurnSigner is Signer, IBurnSigner, EIP712 {
    bytes32 public constant BURN_TYPEHASH =
        keccak256("Burn(address burner,uint256[] ids)");

    constructor(
        address owner_,
        uint8 minSigners_,
        address[] memory eoaSigners_,
        address[] memory signerContractSigners_,
        address[] memory requiredSigners_
    )
        Signer(
            owner_,
            minSigners_,
            eoaSigners_,
            signerContractSigners_,
            requiredSigners_
        )
        EIP712("BurnSigner", "0.0.1")
    {}

    /// @inheritdoc IBurnSigner
    function enforceBurnSigned(
        address burner,
        uint256[] calldata ids,
        bytes[] calldata signatures
    ) public view {
        bytes32 msgHash = _hashTypedDataV4(
            keccak256(abi.encode(BURN_TYPEHASH, burner, ids))
        );
        enforceSigned(msgHash, signatures);
    }

    /// @inheritdoc IBurnSigner
    function executeBurn(
        address burner,
        uint256[] calldata ids,
        bytes[] calldata signatures
    ) external {
        enforceBurnSigned(burner, ids, signatures);
        IBurner(burner).burn(ids);
    }

    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../interface/ISigner.sol";
import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

error NoActionRequired();

/// Base multisig contract. It knows how to manage signers and verify
/// signatures, but it cannot execute anything by itself. It's intended
/// to be inherited by Mint/Burn signer contracts.
contract Signer is Ownable, ISigner {
    using ECDSA for bytes32;

    /// @dev maximum number of signatures allowed (10)
    uint8 public constant MAX_SIGNATURES = 10;

    /// @inheritdoc ISigner
    uint8 public minSignatures;

    /// @inheritdoc ISigner
    uint8 public numSigners;

    /// @inheritdoc ISigner
    uint8 public numRequiredSignatures;

    /// @dev signers mapped to their type
    mapping(address => SignerType) public signers;

    /// @dev required signers, if any
    mapping(address => bool) public requiredSignatures;

    /// @dev upgrade gap, if needed
    uint256[50] private gap_;

    /// @param owner_ the initial owner
    /// @param minSignatures_ minimum number of signatures required
    /// @param eoaSigners_ signers that are EOAs
    /// @param signerContractSigners_ signers that are `Signer` contracts
    /// @param requiredSignatures_ signer addresses that are always required
    constructor(
        address owner_,
        uint8 minSignatures_,
        address[] memory eoaSigners_,
        address[] memory signerContractSigners_,
        address[] memory requiredSignatures_
    ) Ownable() {
        if (owner_ != _msgSender()) {
            Ownable.transferOwnership(owner_);
        }

        for (uint8 i = 0; i < eoaSigners_.length; i++) {
            _updateSigners(eoaSigners_[i], SignerType.EOA);
        }
        for (uint8 i = 0; i < signerContractSigners_.length; i++) {
            _updateSigners(
                signerContractSigners_[i],
                SignerType.SIGNER_CONTRACT
            );
        }
        for (uint8 i = 0; i < requiredSignatures_.length; i++) {
            _updateRequiredSignatures(requiredSignatures_[i], true);
        }

        _updateMinSignatures(minSignatures_);
    }

    /// @inheritdoc ISigner
    /// @dev reverts if `verifySignatures(msgHash, signatures)` returns false
    function enforceSigned(
        bytes32 msgHash,
        bytes[] calldata signatures
    ) public view {
        if (signatures.length > MAX_SIGNATURES) {
            revert TooManySignatures();
        }
        if (!verifySignatures(msgHash, signatures)) {
            revert TooFewSignatures();
        }
    }

    /// @inheritdoc ISigner
    /// @dev calls `_updateSigners()` to update signer info. Only callable by owner.
    function updateSigners(
        address signer_,
        SignerType signerType_
    ) external onlyOwner {
        _updateSigners(signer_, signerType_);
    }

    /// @param signer_ signer address
    /// @param signerType_ type of signer
    /// @dev sets `signer_` to `signerType_`
    function _updateSigners(address signer_, SignerType signerType_) internal {
        if (
            signers[signer_] == SignerType.INACTIVE &&
            signerType_ != SignerType.INACTIVE
        ) {
            // new signer added
            numSigners++;
        } else if (
            signerType_ == SignerType.INACTIVE &&
            // signer being removed
            signers[signer_] != SignerType.INACTIVE
        ) {
            numSigners--;
            if (numSigners < minSignatures) {
                revert TooFewSigners();
            }
        } else {
            revert NoActionRequired();
        }

        emit UpdateSigners(signer_, signerType_, numSigners);
        signers[signer_] = signerType_;
    }

    /// @inheritdoc ISigner
    /// @dev calls `_updateRequiredSignatures()` to update the required signer info. Only callable by owner.
    function updateRequiredSignatures(
        address signer_,
        bool required_
    ) external onlyOwner {
        _updateRequiredSignatures(signer_, required_);
    }

    /// @param signer_ signer address
    /// @param required_ true if signer should be required, false if it should not be
    /// @dev sets `requiredSigner` to `required_`
    function _updateRequiredSignatures(
        address signer_,
        bool required_
    ) internal {
        if (requiredSignatures[signer_] == required_) {
            // do nothing if already at desired state
            return;
        }

        if (signers[signer_] == SignerType.INACTIVE) {
            revert UnknownSigner();
        }

        // update numRequiredSignatures & set updated requiredSignatures state
        if (required_) {
            numRequiredSignatures++;
        } else {
            numRequiredSignatures--;
        }
        emit UpdateRequiredSignatures(
            signer_,
            required_,
            numRequiredSignatures
        );
        requiredSignatures[signer_] = required_;
    }

    /// @inheritdoc ISigner
    /// @dev calls `_updateMinSignatures()` to update minSignatures. Only callable by owner.
    function updateMinSignatures(uint8 minSignatures_) external onlyOwner {
        _updateMinSignatures(minSignatures_);
    }

    /// @param minSignatures_ minimum number of signatures this Signer requires
    /// @dev sets `minSignatures` to `minSignatures_
    function _updateMinSignatures(uint8 minSignatures_) internal {
        if (minSignatures_ == 0 || minSignatures_ > numSigners) {
            revert TooFewSigners();
        }
        emit UpdateMinSignatures(minSignatures_, minSignatures);
        minSignatures = minSignatures_;
    }

    /// @param msgHash signed hash
    /// @param signatures signatures over hash
    /// @dev returns true if all signature requirements are ment, false otherwise
    function verifySignatures(
        bytes32 msgHash,
        bytes[] calldata signatures
    ) public view returns (bool) {
        address[] memory msgSigners = authorizedSigners(
            getUniqueSigners(msgHash, signatures)
        );

        // ensure minSigner threshold is met
        if (msgSigners.length < minSignatures) {
            return false;
        }

        // no required signers and we've met the minSigner threshold
        if (numRequiredSignatures == 0) {
            return true;
        }

        // check that we have all required signatures
        if (enoughRequiredSignatures(msgSigners)) {
            return true;
        } else {
            return false;
        }
    }

    /// @param uniqueSigners a list of unique addresses, created with `getUniqueSigners()`
    /// @dev returns true if `numRequiredSignatures` requirement is met
    function enoughRequiredSignatures(
        address[] memory uniqueSigners
    ) public view returns (bool) {
        if (uniqueSigners.length == 0) {
            revert TooFewSignatures();
        }
        uint8 signatureCount = 0;
        for (uint8 i = 0; i < uniqueSigners.length; i++) {
            if (requiredSignatures[uniqueSigners[i]]) {
                signatureCount++;
                if (signatureCount >= numRequiredSignatures) {
                    return true;
                }
            }
        }
        if (signatureCount >= numRequiredSignatures) {
            return true;
        } else {
            return false;
        }
    }

    /// determine unique signers from an array of signatures
    /// @param msgHash hash that was signed
    /// @param signatures array of signatures
    /// @dev returns array of recovered signers
    /// @dev this does NOT check if the recovered signers are authorized signers
    function getUniqueSigners(
        bytes32 msgHash,
        bytes[] calldata signatures
    ) public pure returns (address[] memory signers_) {
        signers_ = new address[](signatures.length);
        for (uint8 i = 0; i < signatures.length; i++) {
            address signer = msgHash.recover(signatures[i]);

            // ensure this isn't a duplicate signature
            for (uint8 j = 0; j < signers_.length; j++) {
                if (signers_[j] == signer) {
                    revert DuplicateSigner(signer);
                }
            }

            signers_[i] = signer;
        }
    }

    /// determine authorized signers from an array of addresses
    /// @param signers_ array of signers returned from getUniqueSigners()
    /// @dev returns an array containing the subset of signers_ that are authorized signers
    function authorizedSigners(
        address[] memory signers_
    ) public view returns (address[] memory) {
        uint8 count = 0;
        for (uint8 i = 0; i < signers_.length; i++) {
            address signer = signers_[i];
            if (signers[signer] != SignerType.INACTIVE) {
                count++;
            }
        }
        if (count == signers_.length) {
            return signers_;
        }
        address[] memory authorized = new address[](count);
        for (uint8 i = 0; i < signers_.length && count > 0; i++) {
            address signer = signers_[i];
            if (signers[signer] != SignerType.INACTIVE) {
                authorized[--count] = signer;
            }
        }
        return authorized;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./ISigner.sol";

/// Interface for BurnSigner
interface IBurnSigner is ISigner {
    /// @param burner Burner contract address
    /// @param ids burn IDs
    /// @param signatures signatures for the burn request
    function enforceBurnSigned(
        address burner,
        uint256[] calldata ids,
        bytes[] calldata signatures
    ) external view;

    /// @param burner Burner contract address
    /// @param ids burn IDs
    /// @param signatures signatures for the burn request
    function executeBurn(
        address burner,
        uint256[] calldata ids,
        bytes[] calldata signatures
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/// Interface for Burner
interface IBurner {
    enum BurnStatus {
        PENDING,
        BURNED,
        RETURNED
    }

    struct BurnRequest {
        BurnStatus status;
        address token;
        address from;
        uint256 amount;
    }

    /// @param token token address
    /// @param from token sender
    /// @param amount amount sent
    /// @dev logged when new burn request is created
    event BurnRequested(
        address indexed token,
        address indexed from,
        uint256 amount,
        uint256 id
    );

    /// @param token token address
    /// @param from token sender
    /// @param amount amount sent
    /// @param id burn request ID
    /// @param newTokenBalance updated balance of `token` held by the Burner
    /// @dev logged when a burn request is completed
    event Burned(
        address indexed token,
        address indexed from,
        uint256 amount,
        uint256 id,
        uint256 newTokenBalance
    );

    /// @param token token address
    /// @param permitted allowed or denied
    /// @dev logged when the token allowlist is updated
    event PermittedToken(address token, bool permitted);

    /// request a burn
    /// @param from the token sender
    /// @param amount amount of tokens sent
    /// @dev creates a new burn request. Can only be called from permitted token.
    function burnRequest(address from, uint256 amount) external;

    /// initiates multiple burns
    /// @param ids a list of burn IDs
    function burn(uint256[] memory ids) external;

    /// add token to burn request allow list
    /// @param token the LagoStable token
    /// @param status permit (true) or deny (false)
    /// @dev adds or removes `token` from allow list.
    function permitToken(address token, bool status) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

error TooManySignatures();
error TooFewSignatures();
error DuplicateSigner(address signer);
error InvalidAdditionalSigner(string additionalSigner);
error TooFewSigners();
error UnknownSigner();

interface ISigner {
    event UpdateSigners(
        address signer,
        SignerType signerType,
        uint8 numSigners
    );
    event UpdateRequiredSignatures(
        address signer,
        bool required,
        uint8 numRequiredSignatures
    );
    event UpdateMinSignatures(uint8 minSigs, uint8 prevMinSigs);

    enum SignerType {
        INACTIVE,
        EOA,
        SIGNER_CONTRACT
    }

    /// @dev minimum number of signatures required
    function minSignatures() external returns (uint8);

    /// @dev number of signers configured
    function numSigners() external returns (uint8);

    /// @dev number of `requiredSignatures` configured
    function numRequiredSignatures() external returns (uint8);

    /// obtain signer type
    /// @param signer address of signer
    /// @return signerType the type of signer (INACTIVE, EOA, SIGNER_CONTRACT)
    function signers(address signer) external returns (SignerType signerType);

    /// @dev required signers, if any
    /// @param signer address of signer to check
    /// @return isRequired true if the signer's signature is required, false otherwise
    function requiredSignatures(
        address signer
    ) external returns (bool isRequired);

    /// @param signer signer address
    /// @param signerType type of signer
    function updateSigners(address signer, SignerType signerType) external;

    /// @param signer signer address
    /// @param required true if signer should be required, false if it should not be
    function updateRequiredSignatures(address signer, bool required) external;

    /// @param minSignatures_ minimum number of signatures this Signer requires
    function updateMinSignatures(uint8 minSignatures_) external;

    /// @param msgHash signed hash
    /// @param signatures signatures over hash
    function enforceSigned(
        bytes32 msgHash,
        bytes[] calldata signatures
    ) external;
}