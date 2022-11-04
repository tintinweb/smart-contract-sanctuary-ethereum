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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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

pragma solidity ^0.8.0;

// EIP-712 is Final as of 2022-08-11. This file is deprecated.

import "./EIP712.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.13;

// interface
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {ICrabStrategyV2} from "../src/interfaces/ICrabStrategyV2.sol";

// contract
import {Ownable} from "openzeppelin/access/Ownable.sol";
import {EIP712} from "openzeppelin/utils/cryptography/draft-EIP712.sol";
import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";

/// @dev order struct for a signed order from market maker
struct Order {
    uint256 bidId;
    address trader;
    uint256 quantity;
    uint256 price;
    bool isBuying;
    uint256 expiry;
    uint256 nonce;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/// @dev struct to store proportional amounts of erc20s (received or to send)
struct Portion {
    uint256 usdc;
    uint256 crab;
    uint256 eth;
    uint256 sqth;
}

/// @dev params for deposit auction
struct DepositAuctionParams {
    /// @dev USDC to deposit
    uint256 depositsQueued;
    /// @dev minETH equivalent to get from uniswap of the USDC to deposit
    uint256 minEth;
    /// @dev total ETH to deposit after selling the minted SQTH
    uint256 totalDeposit;
    /// @dev orders to buy sqth
    Order[] orders;
    /// @dev price from the auction to sell sqth
    uint256 clearingPrice;
    /// @dev remaining ETH to flashDeposit
    uint256 ethToFlashDeposit;
    /// @dev fee to pay uniswap for usdETH swap
    uint24 usdEthFee;
    /// @dev fee to pay uniswap for sqthETH swap
    uint24 flashDepositFee;
}

/// @dev params for withdraw auction
struct WithdrawAuctionParams {
    uint256 crabToWithdraw;
    Order[] orders;
    uint256 clearingPrice;
    /// @dev minUSDC to receive from swapping the ETH obtained by withdrawing
    uint256 minUSDC;
}

/// @dev receipt used to store deposits and withdraws
struct Receipt {
    address sender;
    uint256 amount;
}

/**
 * @dev CrabNetting contract
 * @notice Contract for Netting Deposits and Withdrawals
 * @author Opyn team
 */
contract CrabNetting is Ownable, EIP712 {
    /// @dev typehash for signed orders
    bytes32 private constant _CRAB_NETTING_TYPEHASH =
        keccak256(
            "Order(uint256 bidId,address trader,uint256 quantity,uint256 price,bool isBuying,uint256 expiry,uint256 nonce)"
        );

    /// @dev owner sets to true when starting auction
    bool public isAuctionLive;

    /// @dev min USDC amounts to withdraw or deposit via netting
    uint256 public minUSDCAmount;

    /// @dev min CRAB amounts to withdraw or deposit via netting
    uint256 public minCrabAmount;

    /// @dev address for ERC20 tokens
    address public usdc;
    address public crab;
    address public weth;
    address public sqth;

    /// @dev address for uniswap router
    ISwapRouter public swapRouter;

    /// @dev array index of last processed deposits
    uint256 public depositsIndex;

    /// @dev array index of last processed withdraws
    uint256 public withdrawsIndex;

    /// @dev array of deposit receipts
    Receipt[] public deposits;
    /// @dev array of withdrawal receipts
    Receipt[] public withdraws;

    /// @dev usd amount to deposit for an address
    mapping(address => uint256) public usdBalance;

    /// @dev crab amount to withdraw for an address
    mapping(address => uint256) public crabBalance;

    /// @dev indexes of deposit receipts of an address
    mapping(address => uint256[]) public userDepositsIndex;

    /// @dev indexes of withdraw receipts of an address
    mapping(address => uint256[]) public userWithdrawsIndex;

    /// @dev store the used flag for a nonce for each address
    mapping(address => mapping(uint256 => bool)) public nonces;

    event USDCQueued(
        address depositor,
        uint256 amount,
        uint256 depositorsBalance,
        uint256 receiptIndex
    );

    event USDCDeQueued(
        address depositor,
        uint256 amount,
        uint256 depositorsBalance
    );

    event CrabQueued(
        address withdrawer,
        uint256 amount,
        uint256 withdrawersBalance,
        uint256 receiptIndex
    );

    event CrabDeQueued(
        address withdrawer,
        uint256 amount,
        uint256 withdrawersBalance
    );

    event USDCDeposited(
        address depositor,
        uint256 usdcAmount,
        uint256 crabAmount,
        uint256 receiptIndex
    );

    event CrabWithdrawn(
        address withdrawer,
        uint256 crabAmount,
        uint256 usdcAmount,
        uint256 receiptIndex
    );

    /**
     * @notice netting contract constructor
     * @dev initializes the erc20 address, uniswap router and approves them
     * @param _usdc address of usdc token
     * @param _weth address of weth token
     * @param _sqth address of sqth token
     * @param _crab address of crab contract token
     * @param _swapRouter address of uniswap swap router
     */
    constructor(
        address _usdc,
        address _crab,
        address _weth,
        address _sqth,
        address _swapRouter
    ) EIP712("CRABNetting", "1") {
        usdc = _usdc;
        crab = _crab;
        weth = _weth;
        sqth = _sqth;
        swapRouter = ISwapRouter(_swapRouter);

        // approve crab and sqth so withdraw can happen
        IERC20(crab).approve(crab, 10e36);
        IERC20(sqth).approve(crab, 10e36);

        IERC20(weth).approve(address(swapRouter), 10e36);
        IERC20(usdc).approve(address(swapRouter), 10e36);
    }

    /**
     * @dev view function to get the domain seperator used in signing
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev toggles the value of isAuctionLive
     */
    function toggleAuctionLive() external onlyOwner {
        isAuctionLive = !isAuctionLive;
    }

    /**
     * @notice set nonce to true
     * @param _nonce the number to be set true
     */
    function setNonceTrue(uint256 _nonce) external {
        nonces[msg.sender][_nonce] = true;
    }

    /**
     * @notice set minUSDCAmount
     * @param _amount the number to be set as minUSDC
     */
    function setMinUSDC(uint256 _amount) external {
        minUSDCAmount = _amount;
    }

    /**
     * @notice set minCrabAmount
     * @param _amount the number to be set as minCrab
     */
    function setMinCrab(uint256 _amount) external {
        minCrabAmount = _amount;
    }

    /**
     * @notice queue USDC for deposit into crab strategy
     * @param _amount USDC amount to deposit
     */
    function depositUSDC(uint256 _amount) external {
        require(_amount >= minUSDCAmount);

        IERC20(usdc).transferFrom(msg.sender, address(this), _amount);

        // update usd balance of user, add their receipt, and receipt index to user deposits index
        usdBalance[msg.sender] = usdBalance[msg.sender] + _amount;
        deposits.push(Receipt(msg.sender, _amount));
        userDepositsIndex[msg.sender].push(deposits.length - 1);

        emit USDCQueued(
            msg.sender,
            _amount,
            usdBalance[msg.sender],
            deposits.length - 1
        );
    }

    /**
     * @notice withdraw USDC from queue
     * @param _amount USDC amount to dequeue
     */
    function withdrawUSDC(uint256 _amount) external {
        require(_amount >= minUSDCAmount);
        require(!isAuctionLive, "auction is live"); // todo think about setting a time of the week , maker dao's codebase

        usdBalance[msg.sender] = usdBalance[msg.sender] - _amount;

        // remove that _amount the users last deposit
        uint256 toRemove = _amount;
        uint256 lastIndexP1 = userDepositsIndex[msg.sender].length;
        for (uint256 i = lastIndexP1; i > 0; i--) {
            // todo check gas optimization here by changing to memory
            Receipt storage r = deposits[userDepositsIndex[msg.sender][i - 1]];
            if (r.amount > toRemove) {
                r.amount -= toRemove;
                toRemove = 0;
                break;
            } else {
                toRemove -= r.amount;
                r.amount = 0; // todo remove this and run test
                delete deposits[userDepositsIndex[msg.sender][i - 1]];
            }
        }
        IERC20(usdc).transfer(msg.sender, _amount);

        emit USDCDeQueued(msg.sender, _amount, usdBalance[msg.sender]);
    }

    /**
     * @notice queue Crab for withdraw from crab strategy
     * @param _amount crab amount to withdraw
     */
    function queueCrabForWithdrawal(uint256 _amount) external {
        require(_amount >= minCrabAmount);
        IERC20(crab).transferFrom(msg.sender, address(this), _amount);
        crabBalance[msg.sender] = crabBalance[msg.sender] + _amount;
        withdraws.push(Receipt(msg.sender, _amount));
        userWithdrawsIndex[msg.sender].push(withdraws.length - 1);
        emit CrabQueued(
            msg.sender,
            _amount,
            crabBalance[msg.sender],
            withdraws.length - 1
        );
    }

    /**
     * @notice withdraw Crab from queue
     * @param _amount Crab amount to dequeue
     */
    function withdrawCrab(uint256 _amount) external {
        require(_amount >= minCrabAmount);
        require(!isAuctionLive, "auction is live");
        // require(crabBalance[msg.sender] >= _amount);
        crabBalance[msg.sender] = crabBalance[msg.sender] - _amount;
        // remove that _amount the users last deposit
        uint256 toRemove = _amount;
        uint256 lastIndexP1 = userWithdrawsIndex[msg.sender].length;
        for (uint256 i = lastIndexP1; i > 0; i--) {
            Receipt storage r = withdraws[
                userWithdrawsIndex[msg.sender][i - 1]
            ];
            if (r.amount > toRemove) {
                r.amount -= toRemove;
                toRemove = 0;
                break;
            } else {
                toRemove -= r.amount;
                r.amount = 0;
                delete userWithdrawsIndex[msg.sender][i - 1];
            }
        }
        IERC20(crab).transfer(msg.sender, _amount);
        emit CrabDeQueued(msg.sender, _amount, crabBalance[msg.sender]);
    }

    /**
     * @dev swaps _quantity amount of usdc for crab at _price
     * @param _price price of crab in usdc
     * @param _quantity amount of USDC to net
     */
    function netAtPrice(uint256 _price, uint256 _quantity) external onlyOwner {
        uint256 crabQuantity = (_quantity * 1e18) / _price;
        // todo write tests for reverts and may = in branches
        require(
            _quantity <= IERC20(usdc).balanceOf(address(this)),
            "Not enough deposits to net"
        );
        require(
            crabQuantity <= IERC20(crab).balanceOf(address(this)),
            "Not enough withdrawals to net"
        );

        // process deposits and send crab
        uint256 i = depositsIndex;
        uint256 amountToSend;
        while (_quantity > 0) {
            // todo may be second check is not required
            Receipt memory deposit = deposits[i];
            if (deposit.amount <= _quantity) {
                // deposit amount is lesser than quantity use it fully
                _quantity = _quantity - deposit.amount;
                usdBalance[deposit.sender] -= deposit.amount;
                amountToSend = (deposit.amount * 1e18) / _price;
                IERC20(crab).transfer(deposit.sender, amountToSend);
                emit USDCDeposited(
                    deposit.sender,
                    deposit.amount,
                    amountToSend,
                    i
                );
                delete deposits[i]; // todo may be just write a teset to ensure it does not screwn up the ReceiptUserMapping
                i++;
            } else {
                // deposit amount is greater than quantity; use it partially
                deposits[i].amount = deposit.amount - _quantity;
                usdBalance[deposit.sender] -= _quantity;
                amountToSend = (_quantity * 1e18) / _price;
                IERC20(crab).transfer(deposit.sender, amountToSend);
                emit USDCDeposited(
                    deposit.sender,
                    deposit.amount,
                    amountToSend,
                    i
                );
                _quantity = 0;
            }
        }
        depositsIndex = i;

        // process withdraws and send usdc
        uint256 j = withdrawsIndex;
        while (crabQuantity > 0) {
            // may be j check is not required todo
            Receipt memory withdraw = withdraws[j];
            if (withdraw.amount <= crabQuantity) {
                crabQuantity = crabQuantity - withdraw.amount;
                crabBalance[withdraw.sender] -= withdraw.amount;
                amountToSend = (withdraw.amount * _price) / 1e18;
                IERC20(usdc).transfer(withdraw.sender, amountToSend);

                emit CrabWithdrawn(
                    withdraw.sender,
                    withdraw.amount,
                    amountToSend,
                    j
                );

                delete withdraws[j];
                j++;
            } else {
                withdraws[j].amount = withdraw.amount - crabQuantity;
                crabBalance[withdraw.sender] -= crabQuantity;
                amountToSend = (crabQuantity * _price) / 1e18;
                IERC20(usdc).transfer(withdraw.sender, amountToSend);

                emit CrabWithdrawn(
                    withdraw.sender,
                    withdraw.amount,
                    amountToSend,
                    j
                );

                crabQuantity = 0;
            }
        }
        withdrawsIndex = j;
    }

    /// @dev @return sum usdc amount in queue
    function depositsQueued() external view returns (uint256) {
        uint256 j = depositsIndex;
        uint256 sum;
        while (j < deposits.length) {
            sum = sum + deposits[j].amount;
            j++;
        }
        return sum;
    }

    /// @dev @return sum crab amount in queue
    function withdrawsQueued() external view returns (uint256) {
        uint256 j = withdrawsIndex;
        uint256 sum;
        while (j < withdraws.length) {
            sum = sum + withdraws[j].amount;
            j++;
        }
        return sum;
    }

    function checkOrder(Order memory _order) internal {
        _useNonce(_order.trader, _order.nonce);
        bytes32 structHash = keccak256(
            abi.encode(
                _CRAB_NETTING_TYPEHASH,
                _order.bidId,
                _order.trader,
                _order.quantity,
                _order.price,
                _order.isBuying,
                _order.expiry,
                _order.nonce
            )
        );

        bytes32 hash = _hashTypedDataV4(structHash);
        address offerSigner = ECDSA.recover(hash, _order.v, _order.r, _order.s);
        require(offerSigner == _order.trader, "Signature not correct");
        require(_order.expiry >= block.timestamp, "order expired");
    }

    function _debtToMint(uint256 _amount) internal view returns (uint256) {
        // todo add fee adjustment
        (, , uint256 collateral, uint256 debt) = ICrabStrategyV2(crab)
            .getVaultDetails();
        uint256 wSqueethToMint = (_amount * (debt)) / collateral; // not added fee todo
        return wSqueethToMint;
    }

    // todo fix for ETH price going up, so less ETH to deposit, so less sqth used; not full sqth
    // eth at 1340 -> then eth goes upto 1440 . 2400 auction ; 2200 sqth
    function depositAuction(DepositAuctionParams calldata _p) external {
        uint256 sqthToSell = _debtToMint(_p.totalDeposit);
        uint256 initCrabBalance = IERC20(crab).balanceOf(address(this)); // todo should we?

        // get all the eth in
        uint256 remainingToSell = sqthToSell;
        for (uint256 i = 0; i < _p.orders.length && remainingToSell > 0; i++) {
            if (_p.orders[i].quantity >= remainingToSell) {
                IWETH(weth).transferFrom(
                    _p.orders[i].trader,
                    address(this),
                    (remainingToSell * _p.clearingPrice) / 1e18
                );
                remainingToSell = 0;
            } else {
                IWETH(weth).transferFrom(
                    _p.orders[i].trader,
                    address(this),
                    (_p.orders[i].quantity * _p.clearingPrice) / 1e18
                );
                remainingToSell -= _p.orders[i].quantity;
            }
        }
        require(remainingToSell == 0, "not enough buy orders for sqth");

        IERC20(usdc).approve(address(swapRouter), _p.depositsQueued); // TODO move all approves to constructor
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({ // todo think about doing an exactOutSwap
            tokenIn: address(usdc),
            tokenOut: address(weth),
            fee: _p.usdEthFee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _p.depositsQueued,
            amountOutMinimum: _p.minEth,
            sqrtPriceLimitX96: 0
        });

        // The call to `exactInputSingle` executes the swap.
        swapRouter.exactInputSingle(params);

        IWETH(weth).withdraw(IWETH(weth).balanceOf(address(this))); // todo move to line 538
        ICrabStrategyV2(crab).deposit{value: _p.totalDeposit}();
        // todo think about adding 1 to the sqth to auction

        Portion memory to_send;
        to_send.sqth = IERC20(sqth).balanceOf(address(this));
        // TODO the left overs of the previous tx from the flashDeposit will be added here
        to_send.eth = address(this).balance;

        if (to_send.eth > 0 && _p.ethToFlashDeposit > 0) {
            ICrabStrategyV2(crab).flashDeposit{value: to_send.eth}(
                _p.ethToFlashDeposit,
                _p.flashDepositFee
            );
        }

        to_send.crab = IERC20(crab).balanceOf(address(this)) - initCrabBalance;
        // get the balance between start and now

        remainingToSell = to_send.sqth;
        for (uint256 j = 0; j < _p.orders.length && remainingToSell > 0; j++) {
            require(_p.orders[j].isBuying);
            checkOrder(_p.orders[j]);
            if (_p.orders[j].quantity < remainingToSell) {
                IERC20(sqth).transfer(
                    _p.orders[j].trader,
                    _p.orders[j].quantity
                );
                remainingToSell -= _p.orders[j].quantity;
            } else {
                IERC20(sqth).transfer(_p.orders[j].trader, remainingToSell);
                remainingToSell = 0;
            }
        }

        // send crab to depositors
        uint256 remainingDeposits = _p.depositsQueued;
        uint256 k = depositsIndex;
        while (remainingDeposits > 0) {
            uint256 queuedAmount = deposits[k].amount;
            Portion memory portion;
            if (queuedAmount <= remainingDeposits) {
                remainingDeposits = remainingDeposits - queuedAmount;
                usdBalance[deposits[k].sender] -= queuedAmount;

                portion.crab = ((deposits[k].amount * to_send.crab) /
                    _p.depositsQueued);

                IERC20(crab).transfer(deposits[k].sender, portion.crab);

                portion.eth = ((deposits[k].amount * to_send.eth) /
                    _p.depositsQueued); // todo remove this if tammy
                //payable(deposits[depositsIndex].sender).transfer(portion.eth);

                deposits[k].amount = 0;
                //to_send.crab -= portion.crab; // todo write a test that fails then fix this
                k++; // todo make this i
            } else {
                usdBalance[deposits[k].sender] -= remainingDeposits;

                portion.crab = ((remainingDeposits * to_send.crab) /
                    _p.depositsQueued);
                IERC20(crab).transfer(deposits[k].sender, portion.crab);

                portion.eth = ((remainingDeposits * to_send.eth) /
                    _p.depositsQueued);
                //payable(deposits[depositsIndex].sender).transfer(portion.eth);

                deposits[k].amount -= remainingDeposits;
                //to_send.crab -= portion.crab; // todo remove this
                remainingDeposits = 0;
            }
        }
        depositsIndex = k;
        isAuctionLive = false;
    }

    function withdrawAuction(WithdrawAuctionParams calldata _p)
        public
        onlyOwner
    {
        // get all the sqth in
        // todo only pull the required sqth by calculating the debt from crab amount
        for (uint256 i = 0; i < _p.orders.length; i++) {
            checkOrder(_p.orders[i]);
            require(!_p.orders[i].isBuying);
            IERC20(sqth).transferFrom(
                _p.orders[i].trader,
                address(this),
                _p.orders[i].quantity
            );
        }
        ICrabStrategyV2(crab).withdraw(_p.crabToWithdraw);
        IWETH(weth).deposit{value: address(this).balance}();

        // pay all mms
        for (uint256 i = 0; i < _p.orders.length; i++) {
            IERC20(weth).transfer(
                _p.orders[i].trader,
                (_p.orders[i].quantity * _p.clearingPrice) / 1e18
            );
        }

        //convert WETH to USDC and send to withdrawers proportionally
        // convert to USDC
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(weth),
                tokenOut: address(usdc),
                fee: 500,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: IERC20(weth).balanceOf(address(this)),
                amountOutMinimum: _p.minUSDC,
                sqrtPriceLimitX96: 0
            });

        // The call to `exactInputSingle` executes the swap.
        uint256 usdcReceived = swapRouter.exactInputSingle(params);

        // pay all withdrawers and mark their withdraws as done
        uint256 remainingWithdraws = _p.crabToWithdraw;
        while (remainingWithdraws > 0) {
            Receipt storage withdraw = withdraws[withdrawsIndex];
            if (withdraw.amount <= remainingWithdraws) {
                // full usage
                remainingWithdraws -= withdraw.amount;
                crabBalance[withdraw.sender] -= withdraw.amount;
                withdrawsIndex++; // todo make it j

                // send proportional usdc
                uint256 usdcAmount = (withdraw.amount * usdcReceived) /
                    _p.crabToWithdraw;
                IERC20(usdc).transfer(withdraw.sender, usdcAmount);
                withdraw.amount = 0;
            } else {
                withdraw.amount -= remainingWithdraws;
                crabBalance[withdraw.sender] -= withdraw.amount;

                // send proportional usdc
                uint256 usdcAmount = (remainingWithdraws * usdcReceived) /
                    _p.crabToWithdraw;
                IERC20(usdc).transfer(withdraw.sender, usdcAmount);

                remainingWithdraws = 0;
            }
        }

        isAuctionLive = false;
        // check if all balances are zero
    }

    /**
     * @dev set nonce flag of the trader to true
     * @param _trader address of the signer
     * @param _nonce number that is to be traded only once
     */
    function _useNonce(address _trader, uint256 _nonce) internal {
        require(!nonces[_trader][_nonce], "C27");
        nonces[_trader][_nonce] = true;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin/interfaces/IERC20.sol";

interface ICrabStrategyV2 is IERC20 {
    function getVaultDetails()
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        );

    function deposit() external payable;

    function withdraw(uint256 _crabAmount) external;

    function flashDeposit(uint256 _ethToDeposit, uint24 _poolFee)
        external
        payable;

    function getWsqueethFromCrabAmount(uint256 _crabAmount)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "openzeppelin/interfaces/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}