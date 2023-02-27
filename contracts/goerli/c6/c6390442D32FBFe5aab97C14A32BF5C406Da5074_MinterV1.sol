/**
 *Submitted for verification at Etherscan.io on 2023-02-27
*/

// Sources flattened with hardhat v2.12.6 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


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


// File @openzeppelin/contracts/utils/introspection/[email protected]


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


// File @openzeppelin/contracts/token/ERC721/[email protected]


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


// File @openzeppelin/contracts/utils/math/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/utils/cryptography/[email protected]


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


// File contracts/v1/interfaces/IERC721MultiCollection.sol


pragma solidity ^0.8.9;

/// @title ERC721Multi collection interface
/// @author Particle Collection - valdi.eth
/// @notice Adds public facing and multi collection balanceOf and collectionId to tokenId functions
/// @dev This implements an optional extension of {ERC721} that adds
/// support for multiple collections and enumerability of all the
/// token ids in the contract as well as all token ids owned by each account per collection.
interface IERC721MultiCollection is IERC721 {
    /// @notice Collection ID `_collectionId` added
    event CollectionAdded(uint256 indexed collectionId);

    /// @notice Balance for `owner` in `collectionId`
    function balanceOf(address owner, uint256 collectionId) external view returns (uint256);

    /// @notice Get the collection ID for a given token ID
    function tokenIdToCollectionId(uint256 tokenId) external pure returns (uint256 collectionId);

    /// @notice returns the total number of collections.
    function numberOfCollections() external view returns (uint256);

    /// @dev Returns the total amount of tokens stored by the contract for `collectionId`.
    function totalSupply(uint256 collectionId) external view returns (uint256);

    /// @dev Returns a token ID owned by `owner` at a given `index` of its token list on `collectionId`.
    /// Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
    function tokenOfOwnerByIndex(address owner, uint256 index, uint256 collectionId) external view returns (uint256);
}


// File contracts/v1/interfaces/IManifold.sol



pragma solidity ^0.8.0;

/// @author: manifold.xyz

/**
 * @dev Royalty interface for creator core classes
 */
interface IManifold {

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
}


// File contracts/v1/interfaces/IPRTCLCollections721V1.sol


pragma solidity ^0.8.9;

/// use the Royalty Registry's IManifold interface for token royalties


/// @title Interface for Core ERC721 contract for multiple collections
/// @author Particle Collection - valdi.eth
/// @notice Manages all collections tokens
/// @dev Exposes all public functions and events needed by the Particle Collection's smart contracts
/// @dev Adheres to the ERC721 standard, ERC721MultiCollection extension and Manifold for secondary royalties
interface IPRTCLCollections721V1 is IERC721, IERC721MultiCollection, IManifold {
    /// @notice Collection ID `_collectionId` updated
    event CollectionUpdated(uint256 indexed _collectionId);

    /// @notice Collection ID `_collectionId` sold through governance
    event CollectionSold(uint256 indexed _collectionId, address _buyer);

    ///
    /// Collection data
    ///

    /// @notice Artist address for collection ID `_collectionId`
    function collectionIdToArtistAddress(uint256 _collectionId) external view returns (address payable);

    /// @notice Get the primary revenue splits for a given collection ID and sale price
    /// @dev Used by minter contract
    function getPrimaryRevenueSplits(uint256 _collectionId, uint256 _price) external view
        returns (
            uint256 FJMRevenue_,
            address payable FJMAddress_,
            uint256 DAORevenue_,
            address payable DAOAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_
        );

    /// @notice Main collection data
    function collectionData(uint256 _collectionId) external view returns (
        uint256 nParticles,
        uint256 maxParticles,
        bool active,
        string memory collectionName,
        bool sold,
        uint256[] memory seeds,
        uint256 setSeedsAfterBlock
    );

    /// @notice Check if the collection can be sold
    /// @dev Used by governance contract
    function collectionCanBeSold(uint256 _collectionId) external view returns (bool);

    /// @notice Get the proceeds per token for a given collection ID and sale price
    /// @dev Used by governance contract
    function proceedsPerToken(uint256 _collectionId, uint256 _salePriceInWei) external view returns (uint256);

    /// @notice Get coordinates within an artwork for a given token ID
    function getCoordinate(uint256 _tokenId) external view returns (uint256);

    ///
    /// Collection interactions
    ///

    /// @notice Mark a collection as sold
    /// @dev Only callable by the governance role
    function markCollectionSold(uint256 _collectionId, address _buyer) external;
    
    /// @notice Mint a new token.
    /// Used by minter contract and BE infrastructure when handling fiat payments
    /// @dev Only callable by the minter role
    function mint(address _to, uint256 _collectionId, uint24 _amount) external returns (uint256 tokenId);

    /// @notice Burn all tokens owned by `owner` in collection `_collectionId`
    /// Used when redeeming tokens for sale proceeds
    /// @dev Only callable by the governance role
    function burn(address owner, uint256 collectionId) external returns (uint256 tokensBurnt);

    /// @notice Set the random prime seeds for a given collection ID, used to calculate token coordinates
    /// @dev Only callable by the Randomizer contract
    function setCollectionSeeds(uint256 _collectionId, uint256[2] calldata _seeds) external;
}


// File @openzeppelin/contracts/security/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File contracts/v1/MinterV1.sol


pragma solidity ^0.8.9;





/// @title Minter contract version 1
/// @author Particle Collection - valdi.eth
/// @notice Mint tokens for any collection in the core ERC721 contract
/// @dev Based on Artblock's Minter suite of contracts: https://github.com/ArtBlocks/artblocks-contracts/tree/main/contracts/minter-suite/Minters
/// Modifications to the original design:
/// - Max mints per wallet functionality
/// - Added pre sale and live sale minting phases
/// - Modified allowed currencies design
contract MinterV1 is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    /**
     * @notice Price per token in wei updated for collection `_collectionId` to
     * `_pricePerTokenInWei`.
     */
    event PricePerTokenInWeiUpdated(
        uint256 indexed _collectionId,
        uint256 indexed _pricePerTokenInWei
    );

    /**
     * @notice Max mints per wallet for collection `_collectionId` 
     * updated to `_maxMints`.
     */
    event MaxMintsUpdated(
        uint256 indexed _collectionId,
        uint24 indexed _maxMints
    );

    /**
     * @notice Currency updated for collection `_collectionId` to symbol
     * `_currencySymbol` and address `_currencyAddress`.
     */
    event CollectionCurrencyInfoUpdated(
        uint256 indexed _collectionId,
        address indexed _currencyAddress,
        string _currencySymbol
    );

    /**
     * @notice Allow holders of NFTs at addresses `_ownedNFTAddresses`, collection
     * IDs `_ownedNFTCollectionIds` to mint on collection `_collectionId`.
     * `_ownedNFTAddresses` assumed to be aligned with `_ownedNFTCollectionIds`.
     * e.g. Allows holders of collection `_ownedNFTCollectionIds[0]` on token
     * contract `_ownedNFTAddresses[0]` to mint.
     */
    event AllowedHoldersOfCollections(
        uint256 indexed _collectionId,
        address[] _ownedNFTAddresses,
        uint256[] _ownedNFTCollectionIds
    );

    /**
     * @notice Remove holders of NFTs at addresses `_ownedNFTAddresses`,
     * collection IDs `_ownedNFTCollectionIds` to mint on collection `_collectionId`.
     * `_ownedNFTAddresses` assumed to be aligned with `_ownedNFTCollectionIds`.
     * e.g. Removes holders of collection `_ownedNFTCollectionIds[0]` on token
     * contract `_ownedNFTAddresses[0]` from mint allowlist.
     */
    event RemovedHoldersOfCollections(
        uint256 indexed _collectionId,
        address[] _ownedNFTAddresses,
        uint256[] _ownedNFTCollectionIds
    );

    /**
     * @notice Pre mint done status updated to true for
     * collection `_collectionId`.
     */
    event HolderPreMintDone(uint256 indexed _collectionId);

    /// This contract handles cores with interface IPRTCLCollections721V1
    IPRTCLCollections721V1 public immutable collCoreContract;
    uint256 constant ONE_MILLION = 1_000_000;

    /// Collection configuration
    struct CollectionConfig {
        address currencyAddress;
        uint256 pricePerTokenInWei;
        string currencySymbol;
        uint24 maxMintsPerWallet;
        bool hasMaxPerWallet;
        bool holderPreMintDone;
    }

    mapping(uint256 => CollectionConfig) public collectionConfigs;

    // Number of tokens minted by a given wallet in a collection
    // CollectionId => wallet address => number of minted tokens
    mapping(uint256 => mapping(address => uint256)) public walletMintedPerCollection;

    /// @notice Used to validate whitelist addresses
    address public whitelistSigner;

    /**
     * collectionId => ownedNFTAddress => ownedNFTCollectionIds => bool
     * collections whose holders are allowed to purchase a token on `collectionId`
     */
    mapping(uint256 => mapping(address => mapping(uint256 => bool)))
        public allowedCollectionHolders;

    /**
     * @notice Initializes contract to be a Minter
     * integrated with Particle's core contract at 
     * address `_collCore721Address`.
     * @param _collCore721Address Particle's core contract for which this
     * contract will be a minter.
     */
    constructor(address _collCore721Address, address _signer)
        ReentrancyGuard()
    {
        collCoreContract = IPRTCLCollections721V1(_collCore721Address);
        whitelistSigner = _signer;
    }

    /**
     * @notice Gets the sender's balance of the ERC-20 token currently set
     * as the payment currency for collection `_collectionId`.
     * @param _collectionId Collection ID to be queried.
     * @return balance Balance of ERC-20
     */
    function balanceOfCollectionERC20(uint256 _collectionId)
        external
        view
        returns (uint256 balance)
    {
        balance = IERC20(collectionConfigs[_collectionId].currencyAddress).balanceOf(
            msg.sender
        );
        return balance;
    }

    /**
     * @notice Gets your allowance for this minter of the ERC-20
     * token currently set as the payment currency for collection
     * `_collectionId`.
     * @param _collectionId Collection ID to be queried.
     * @return remaining Remaining allowance of ERC-20
     */
    function allowanceOfCollectionERC20(uint256 _collectionId)
        external
        view
        returns (uint256 remaining)
    {
        remaining = IERC20(collectionConfigs[_collectionId].currencyAddress).allowance(
                msg.sender,
                address(this)
            );
        return remaining;
    }

    /**
     * @notice Updates this minter's price per token of collection `_collectionId`
     * to be '_pricePerTokenInWei`, in Wei.
     */
    function updatePricePerTokenInWei(
        uint256 _collectionId,
        uint256 _pricePerTokenInWei
    ) external onlyOwner {
        require(_pricePerTokenInWei > 0, "Price must be > 0");
        collectionConfigs[_collectionId].pricePerTokenInWei = _pricePerTokenInWei;
        emit PricePerTokenInWeiUpdated(_collectionId, _pricePerTokenInWei);
    }

    /**
     * @notice Updates this minter's max mints per wallet 
     * of collection `_collectionId` to be '_maxMints`
     */
    function updateMaxMints(
        uint256 _collectionId,
        uint24 _maxMints
    ) external onlyOwner {
        // 0 max mints == no limit
        // (max token ids enforced by core contract)
        collectionConfigs[_collectionId].maxMintsPerWallet = _maxMints;
        collectionConfigs[_collectionId].hasMaxPerWallet = true;
        emit MaxMintsUpdated(_collectionId, _maxMints);
    }

    /**
     * @notice Updates this minter's minting phase 
     * of collection `_collectionId` to be past pre mint
     */
    function holderPreMintDone(
        uint256 _collectionId
    ) external onlyOwner {
        collectionConfigs[_collectionId].holderPreMintDone = true;
        emit HolderPreMintDone(_collectionId);
    }

    /**
     * @notice Updates payment currency of collection `_collectionId` to be
     * `_currencySymbol` at address `_currencyAddress`.
     * @param _collectionId Collection ID to update.
     * @param _currencySymbol Currency symbol.
     * @param _currencyAddress Currency address.
     */
    function updateCollectionCurrencyInfo(
        uint256 _collectionId,
        string memory _currencySymbol,
        address _currencyAddress
    ) external onlyOwner {
        // require null address if symbol is "ETH"
        require(
            (keccak256(abi.encodePacked(_currencySymbol)) ==
                keccak256(abi.encodePacked("ETH"))) ==
                (_currencyAddress == address(0)),
            "ETH is only null address"
        );
        collectionConfigs[_collectionId].currencySymbol = _currencySymbol;
        collectionConfigs[_collectionId].currencyAddress = _currencyAddress;
        emit CollectionCurrencyInfoUpdated(
            _collectionId,
            _currencyAddress,
            _currencySymbol
        );
    }

    /**
     * @dev Update signer address.
     * Can only be called by owner.
     */
    function setSigner(address _signer) external onlyOwner {
        whitelistSigner = _signer;
    }

    /**
     * @notice Returns hashed address (to be used as merkle tree leaf).
     * @param _address address to be hashed
     * @return bytes32 hashed address, via keccak256 (using encodePacked)
     */
    function hashAddress(address _address) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address));
    }

    /**
     * @notice Verify signature
     */
    function _verifyAddressSigner(bytes memory _signature, uint256 _collectionId, address _address) public 
    view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(_collectionId, _address));
        return whitelistSigner == messageHash.toEthSignedMessageHash().recover(_signature);
    }

    /**
     * @notice Allows holders of NFTs at addresses `_ownedNFTAddresses`,
     * collection IDs `_ownedNFTCollectionIds` to mint on collection `_collectionId`. `_ownedNFTAddresses` assumed to be aligned with `_ownedNFTCollectionIds`.
     * e.g. Allows holders of collection `_ownedNFTCollectionIds[0]` on token
     * contract `_ownedNFTAddresses[0]` to mint `_collectionId`.
     * @param _collectionId Collection ID to enable minting on.
     * @param _ownedNFTAddresses NFT core addresses of collections to be
     * allowlisted. Indexes must align with `_ownedNFTCollectionIds`.
     * @param _ownedNFTCollectionIds Collection IDs on `_ownedNFTAddresses` 
     * whose holders shall be allowlisted to mint collection `_collectionId`. 
     * Indexes must align with `_ownedNFTAddresses`.
     * For regular, non multi collection NFTs, `_ownedNFTCollectionIds` should be 0 to allow token ids in the 0-999999 range,
     * 1 to allow token ids in the 1000000-1999999 range, etc.
     */
    function allowHoldersOfCollections(
        uint256 _collectionId,
        address[] memory _ownedNFTAddresses,
        uint256[] memory _ownedNFTCollectionIds
    ) public onlyOwner {
        // require same length arrays
        require(
            _ownedNFTAddresses.length == _ownedNFTCollectionIds.length,
            "Length of add arrays must match"
        );
        // for each approved collection
        for (uint256 i = 0; i < _ownedNFTAddresses.length; i++) {
            // approve
            allowedCollectionHolders[_collectionId][_ownedNFTAddresses[i]][
                _ownedNFTCollectionIds[i]
            ] = true;
        }
        // emit approve event
        emit AllowedHoldersOfCollections(
            _collectionId,
            _ownedNFTAddresses,
            _ownedNFTCollectionIds
        );
    }

    /**
     * @notice Removes holders of NFTs at addresses `_ownedNFTAddresses`,
     * collection IDs `_ownedNFTCollectionIds` to mint on collection `_collectionId`. If
     * other collections owned by a holder are still allowed to mint, holder will
     * maintain ability to purchase.
     * `_ownedNFTAddresses` assumed to be aligned with `_ownedNFTCollectionIds`.
     * e.g. Removes holders of collection `_ownedNFTCollectionIds[0]` on token
     * contract `_ownedNFTAddresses[0]` from mint allowlist of `_collectionId`.
     * @param _collectionId Collection ID to enable minting on.
     * @param _ownedNFTAddresses NFT core addresses of collections to be 
     * removed from allowlist. Indexes must align with `_ownedNFTCollectionIds`.
     * @param _ownedNFTCollectionIds Collection IDs on `_ownedNFTAddresses` 
     * whose holders will be removed from allowlist to mint project 
     * `_collectionId`. Indexes must align with `_ownedNFTAddresses`.
     */
    function removeHoldersOfCollections(
        uint256 _collectionId,
        address[] memory _ownedNFTAddresses,
        uint256[] memory _ownedNFTCollectionIds
    ) public onlyOwner {
        // require same length arrays
        require(
            _ownedNFTAddresses.length == _ownedNFTCollectionIds.length,
            "Length of remove arrays must match"
        );
        // for each removed project
        for (uint256 i = 0; i < _ownedNFTAddresses.length; i++) {
            // revoke
            allowedCollectionHolders[_collectionId][_ownedNFTAddresses[i]][
                _ownedNFTCollectionIds[i]
            ] = false;
        }
        // emit removed event
        emit RemovedHoldersOfCollections(
            _collectionId,
            _ownedNFTAddresses,
            _ownedNFTCollectionIds
        );
    }

    /**
     * @notice Allows holders of NFTs at addresses `_ownedNFTAddressesAdd`,
     * collection IDs `_ownedNFTCollectionIdsAdd` to mint on collection `_collectionId`.
     * Also removes holders of NFTs at addresses `_ownedNFTAddressesRemove`,
     * collection IDs `_ownedNFTCollectionIdsRemove` from minting on 
     * collection `_collectionId`. `_ownedNFTAddressesAdd` assumed to be 
     * aligned with `_ownedNFTCollectionIdsAdd`.
     * e.g. Allows holders of collection `_ownedNFTCollectionIdsAdd[0]` on 
     * token contract `_ownedNFTAddressesAdd[0]` to mint `_collectionId`.
     * `_ownedNFTAddressesRemove` also assumed to be aligned with
     * `_ownedNFTCollectionIdsRemove`.
     * @param _collectionId Collection ID to enable minting on.
     * @param _ownedNFTAddressesAdd NFT core addresses of collections to be
     * allowlisted. Indexes must align with `_ownedNFTCollectionIdsAdd`.
     * @param _ownedNFTCollectionIdsAdd Collection IDs on 
     * `_ownedNFTAddressesAdd` whose holders shall be allowlisted to mint 
     * collection `_collectionId`. Indexes must align with 
     * `_ownedNFTAddressesAdd`.
     * @param _ownedNFTAddressesRemove NFT core addresses of collections to be
     * removed from allowlist. Indexes must align with
     * `_ownedNFTCollectionIdsRemove`.
     * @param _ownedNFTCollectionIdsRemove Collection IDs on
     * `_ownedNFTAddressesRemove` whose holders will be removed from allowlist
     * to mint collection `_collectionId`. Indexes must align with
     * `_ownedNFTAddressesRemove`.
     * @dev if a collection is included in both add and remove arrays, it 
     * will be removed.
     */
    function allowRemoveHoldersOfProjects(
        uint256 _collectionId,
        address[] memory _ownedNFTAddressesAdd,
        uint256[] memory _ownedNFTCollectionIdsAdd,
        address[] memory _ownedNFTAddressesRemove,
        uint256[] memory _ownedNFTCollectionIdsRemove
    ) external onlyOwner {
        allowHoldersOfCollections(
            _collectionId,
            _ownedNFTAddressesAdd,
            _ownedNFTCollectionIdsAdd
        );
        removeHoldersOfCollections(
            _collectionId,
            _ownedNFTAddressesRemove,
            _ownedNFTCollectionIdsRemove
        );
    }

    /**
     * @notice Returns true if token is an allowlisted NFT for collection `_collectionId`.
     * @param _collectionId Collection ID to be checked.
     * @param _ownedNFTAddress ERC-721 NFT token address to be checked.
     * @param _ownedNFTTokenId ERC-721 NFT token ID to be checked.
     * @return bool Token is allowlisted
     * @dev does not check if token has been used to purchase
     * @dev assumes collection ID can be derived from tokenId / 1_000_000
     */
    function isAllowlistedNFT(
        uint256 _collectionId,
        address _ownedNFTAddress,
        uint256 _ownedNFTTokenId
    ) public view returns (bool) {
        uint256 ownedNFTCollectionId = _ownedNFTTokenId / ONE_MILLION;
        return
            allowedCollectionHolders[_collectionId][_ownedNFTAddress][
                ownedNFTCollectionId
            ];
    }

    /**
     * @notice Purchase a token from a collection during minting.
     * @param _to Receiver of the purchased token.
     * @param _collectionId Collection ID to be minted from.
     * @param _ownedNFTAddress ERC-721 NFT token address to be checked for pre sale phase.
     * @param _ownedNFTTokenId ERC-721 NFT token ID to be checked for pre sale phase.
     * @return tokenId First token id purchased.
     */
    function purchase(
        address _to,
        uint256 _collectionId,
        uint24 _amount,
        address _ownedNFTAddress,
        uint256 _ownedNFTTokenId,
        bytes memory signature
    )
        public
        payable
        nonReentrant
        returns (uint256 tokenId)
    {
        // CHECKS
        CollectionConfig storage _collectionConfig = collectionConfigs[_collectionId];
        uint256 _pricePerTokenInWei = _collectionConfig.pricePerTokenInWei;

        // require price of token to be configured on this minter
        require(_pricePerTokenInWei > 0 && _collectionConfig.hasMaxPerWallet, "Collection not configured");

        // require token used to claim to be in set of allowlisted NFTs if minting 
        // during holder pre mint phase
        require(_collectionConfig.holderPreMintDone ||
            (isAllowlistedNFT(_collectionId, _ownedNFTAddress, _ownedNFTTokenId) &&
            IERC721(_ownedNFTAddress).ownerOf(_ownedNFTTokenId) == msg.sender),
            "Only allowlisted NFT holders"
        );

        // require valid signature for minting in any phase
        require(_verifyAddressSigner(signature, _collectionId, msg.sender), "Invalid signature");

        uint256 newMintedAmount = walletMintedPerCollection[_collectionId][msg.sender] + _amount;
        uint256 maxMints = _collectionConfig.maxMintsPerWallet;
        require(maxMints == 0 || newMintedAmount <= maxMints, "Maximum amount exceeded");

        // EFFECTS
        unchecked {
            // Cannot overflow as max ids per colection is limited by the collection's max mints
            walletMintedPerCollection[_collectionId][msg.sender] = newMintedAmount;
        }

        tokenId = collCoreContract.mint(_to, _collectionId, _amount);

        // INTERACTIONS
        // Moving money after mint to pass core checks first
        uint256 _totalPrice = _pricePerTokenInWei * _amount;
        address _currencyAddress = _collectionConfig.currencyAddress;
        if (_currencyAddress != address(0)) {
            require(
                msg.value == 0,
                "This collection accepts a different currency and cannot accept ETH"
            );
            require(
                IERC20(_currencyAddress).allowance(msg.sender, address(this)) >=
                    _totalPrice,
                "Insufficient Funds Approved for TX"
            );
            require(
                IERC20(_currencyAddress).balanceOf(msg.sender) >=
                    _totalPrice,
                "Insufficient balance."
            );
            _splitFundsERC20(_collectionId, _totalPrice, _currencyAddress);
        } else {
            require(
                msg.value >= _totalPrice,
                "Must send minimum value to mint!"
            );
            _splitFundsETH(_collectionId, _totalPrice);
        }

        return tokenId;
    }

    /**
     * @dev splits ETH funds between sender (if refund), 4JM,
     * DAO, and artist for a token purchased on
     * collection `_collectionId`.
     * @dev possible DoS during splits is acknowledged, and mitigated by
     * admin-accepted artist payment addresses.
     */
    function _splitFundsETH(uint256 _collectionId, uint256 _pricePerTokenInWei)
        internal
    {
        if (msg.value > 0) {
            bool success_;
            // send refund to sender
            uint256 refund = msg.value - _pricePerTokenInWei;
            if (refund > 0) {
                (success_, ) = msg.sender.call{value: refund}("");
                require(success_, "Refund failed");
            }
            // split remaining funds between 4JM, DAO and artist
            (
                uint256 fjmRevenue_,
                address payable fjmAddress_,
                uint256 daoRevenue_,
                address payable daoAddress_,
                uint256 artistRevenue_,
                address payable artistAddress_
            ) = collCoreContract.getPrimaryRevenueSplits(
                    _collectionId,
                    _pricePerTokenInWei
                );
            // 4JM payment
            if (fjmRevenue_ > 0) {
                (success_, ) = fjmAddress_.call{value: fjmRevenue_}(
                    ""
                );
                require(success_, "Particle payment failed");
            }
            // Particle DAO payment
            if (daoRevenue_ > 0) {
                (success_, ) = daoAddress_.call{
                    value: daoRevenue_
                }("");
                require(success_, "DAO payment failed");
            }
            // artist payment
            if (artistRevenue_ > 0) {
                (success_, ) = artistAddress_.call{value: artistRevenue_}("");
                require(success_, "Artist payment failed");
            }
        }
    }

    /**
     * @dev splits ERC-20 funds between 4JM, Particle DAO and artist, for a token purchased on collection `_collectionId`.
     * @dev possible DoS during splits is acknowledged, and mitigated by
     * admin-accepted artist payment addresses.
     */
    function _splitFundsERC20(
        uint256 _collectionId,
        uint256 _pricePerTokenInWei,
        address _currencyAddress
    ) internal {
        // split remaining funds between 4JM, Particle DAO and artist
        (
            uint256 fjmRevenue_,
            address payable fjmAddress_,
            uint256 daoRevenue_,
            address payable daoAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_
        ) = collCoreContract.getPrimaryRevenueSplits(
                _collectionId,
                _pricePerTokenInWei
            );
        IERC20 _collectionCurrency = IERC20(_currencyAddress);
        // 4JM payment
        if (fjmRevenue_ > 0) {
            _collectionCurrency.transferFrom(
                msg.sender,
                fjmAddress_,
                fjmRevenue_
            );
        }
        // Particle DAO payment
        if (daoRevenue_ > 0) {
            _collectionCurrency.transferFrom(
                msg.sender,
                daoAddress_,
                daoRevenue_
            );
        }
        // artist payment
        if (artistRevenue_ > 0) {
            _collectionCurrency.transferFrom(
                msg.sender,
                artistAddress_,
                artistRevenue_
            );
        }
    }

    /**
     * @notice collectionId => maximum mints per allowlisted address. 
     * If a value of 0 is returned, there is no limit on the number of mints per allowlisted address.
     * Default behavior is no limit mint per address.
     */
    function collectionMaxMintsPerAddress(
        uint256 _collectionId
    ) public view returns (uint256) {
        return uint256(collectionConfigs[_collectionId].maxMintsPerWallet);
    }

    /**
     * @notice Returns remaining mints for a given address.
     * Returns 0 if no maximum per address is set for collection `_collectionId`.
     * Note that max mints per address can be changed at any time by the owner.
     * Also note that all max mints per address are limited by a 
     * collections's maximum mints as defined on the core contract. 
     * This function may return a value greater than the collection's remaining mints.
     */
    function collectionRemainingMintsForAddress(
        uint256 _collectionId,
        address _address
    )
        external
        view
        returns (
            uint256 mintsRemaining,
            bool hasLimit
        )
    {
        uint256 maxMintsPerAddress = collectionMaxMintsPerAddress(
            _collectionId
        );
        if (maxMintsPerAddress == 0) {
            // project does not limit mint invocations per address, so leave `mintsRemaining` at
            // solidity initial value of zero, and hasLimit as false
        } else {
            hasLimit = true;
            uint256 walletMints = walletMintedPerCollection[
                _collectionId
            ][_address];
            // if user has not reached max mints per address, return
            // remaining mints
            if (maxMintsPerAddress > walletMints) {
                unchecked {
                    // will never underflow due to the check above
                    mintsRemaining = maxMintsPerAddress - walletMints;
                }
            }
            // else user has reached their maximum invocations, so leave
            // `mintsRemaining` at solidity initial value of zero
        }
    }

    /**
     * @notice If price of token is configured, returns price of minting a
     * token on collection `_collectionId`, and currency symbol and address 
     * to be used as payment.
     * @param _collectionId Collection ID to get price information for.
     * @return isConfigured true only if token price has been configured on
     * this minter
     * @return tokenPriceInWei current price of token on this minter - invalid
     * if price has not yet been configured
     * @return currencySymbol currency symbol for purchases of collection on this
     * minter. "ETH" reserved for ether.
     * @return currencyAddress currency address for purchases of collection on
     * this minter. Null address reserved for ether.
     */
    function getPriceInfo(uint256 _collectionId)
        external
        view
        returns (
            bool isConfigured,
            uint256 tokenPriceInWei,
            string memory currencySymbol,
            address currencyAddress
        )
    {
        CollectionConfig storage _collectionConfig = collectionConfigs[_collectionId];
        tokenPriceInWei = _collectionConfig.pricePerTokenInWei;
        isConfigured = tokenPriceInWei > 0 && _collectionConfig.hasMaxPerWallet;
        currencyAddress = _collectionConfig.currencyAddress;
        if (currencyAddress == address(0)) {
            currencySymbol = "ETH";
        } else {
            currencySymbol = _collectionConfig.currencySymbol;
        }
    }

    /**
     * @notice Returns true if collection `_collectionId` has ended it's pre-mint phase.
     */
    function getCollectionPreMintDone(uint256 _collectionId)
        external
        view
        returns (bool)
    {
        return collectionConfigs[_collectionId].holderPreMintDone;
    }
}