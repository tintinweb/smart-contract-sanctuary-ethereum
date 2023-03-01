// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@dex/lib/Structs.sol';
import '@dex/lib/FinMath.sol';

import '@dex/perp/interfaces/IConfig.sol';

import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

library FeesMath {
    using FinMath for uint;
    using FinMath for uint24;
    using FinMath for int24;

    // @dev External function used in engine to compute premium and premium fee
    function premium(
        Order storage o,
        PriceData memory p,
        int24 premiumBps,
        IConfig config,
        uint8 minPremiumFeeDiscountPerc
    ) public view returns (int premium_, uint premiumFee) {
        uint notional = o.amount.wmul(p.price);
        premium_ = premiumBps.bps(notional);
        int fee = config.premiumFeeBps().bps(premium_);
        int _minPremiumFee = int(
            (config.getAmounts().minPremiumFee *
                uint((minPremiumFeeDiscountPerc))) / 100
        );
        premiumFee = uint((fee > _minPremiumFee) ? fee : _minPremiumFee);
    }

    // @dev External function used in engine.
    function traderFees(
        Order storage o,
        PriceData memory p,
        IConfig config
    ) external view returns (uint) {
        uint notional = o.amount.wmul(p.price);
        int fee = config.traderFeeBps().bps(int(notional));
        return uint(fee);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@dex/lib/SafeCast.sol';

// Percentage using BPS
// https://stackoverflow.com/questions/3730019/why-not-use-double-or-float-to-represent-currency/3730040#3730040
// Ranges:
// int(x): -2^(x-1) to [2^(x-1)]-1
// uint(x): 0 to [2^(x)]-1

// @notice Simple multiplication with native overflow protection for uint when
// using solidity above 0.8.17.
library FinMath {
    using SafeCast for uint;
    using SafeCast for int;

    // Bps
    int public constant iBPS = 10 ** 4; // basis points [TODO: move to 10**4]
    uint public constant uBPS = 10 ** 4; // basis points [TODO: move to 10**4]

    // Fixed Point arithimetic
    uint constant WAD = 10 ** 18;
    int constant iWAD = 10 ** 18;
    uint constant LIMIT = 2 ** 255;

    int internal constant iMAX_128 = 0x100000000000000000000000000000000; // 2^128
    int internal constant iMIN_128 = -0x100000000000000000000000000000000; // 2^128
    uint internal constant uMAX_128 = 0x100000000000000000000000000000000; // 2^128

    // --- SIGNED CAST FREE

    function mul(int x, int y) internal pure returns (int z) {
        z = x * y;
    }

    function div(int a, int b) internal pure returns (int z) {
        z = a / b;
    }

    function sub(int a, int b) internal pure returns (int z) {
        z = a - b;
    }

    function add(int a, int b) internal pure returns (int z) {
        z = a + b;
    }

    // --- UNSIGNED CAST FREE

    function mul(uint x, uint y) internal pure returns (uint z) {
        z = x * y;
    }

    function div(uint a, uint b) internal pure returns (uint z) {
        z = a / b;
    }

    function add(uint a, uint b) internal pure returns (uint z) {
        z = a + b;
    }

    function sub(uint a, uint b) internal pure returns (uint z) {
        z = a - b;
    }

    // --- MIXED TYPES SAFE CAST
    function mul(uint x, int y) internal pure returns (int z) {
        z = x.i256() * y;
    }

    function div(int a, uint b) internal pure returns (int z) {
        z = a / b.i256();
    }

    function add(uint x, int y) internal pure returns (uint z) {
        bool flip = y < 0 ? true : false;
        z = flip ? x - (-y).u256() : x + y.u256();
    }

    function add(int x, uint y) internal pure returns (int z) {
        z = x + y.i256();
    }

    function sub(uint x, int y) internal pure returns (uint z) {
        bool flip = y < 0 ? true : false;
        z = flip ? x + (-y).u256() : x - y.u256();
    }

    function sub(int x, uint y) internal pure returns (int z) {
        z = x - y.i256();
    }

    function isub(uint x, uint y) internal pure returns (int z) {
        int x1 = x.i256();
        int y1 = y.i256();
        z = x1 - y1;
    }

    // --- FIXED POINT [1e18 precision]

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wmul(int x, int y) internal pure returns (int z) {
        z = add(mul(x, y), iWAD / 2) / iWAD;
    }

    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function wdiv(int x, int y) internal pure returns (int z) {
        z = add(mul(x, iWAD), y / 2) / y;
    }

    // --- FIXED POINT BPS [1e4 precision]

    // @notice Calculate percentage using BPS precision
    // @param bps input in base points
    // @param x the number we want to calculate percentage
    // @return the % of the x including fixed-point arithimetic
    function bps(int bp, uint x) internal pure returns (int z) {
        require(bp < iMAX_128, 'bps-x-overflow');
        z = (mul(x.i256(), bp)) / iBPS;
    }

    function bps(uint bp, uint x) internal pure returns (uint z) {
        require(bp < uMAX_128, 'bps-x-overflow');
        z = mul(x, bp) / uBPS;
    }

    function bps(uint bp, int x) internal pure returns (int z) {
        require(bp < uMAX_128, 'bps-x-overflow');
        z = mul(x, bp.i256()) / iBPS;
    }

    function bps(int bp, int x) internal pure returns (int z) {
        require(bp < iMAX_128, 'bps-x-overflow');
        z = mul(x, bp) / iBPS;
    }

    function ibps(uint bp, uint x) internal pure returns (int z) {
        require(bp < uMAX_128, 'bps-x-overflow');
        z = (mul(x, bp) / uBPS).i256();
    }

    // @dev Transform to BPS precision
    function bps(uint x) internal pure returns (uint) {
        return mul(x, uBPS);
    }

    // @notice Return the positive number of an int256 or zero if it was negative
    // @parame x the number we want to normalize
    // @return zero or a positive number
    function pos(int a) internal pure returns (uint) {
        return (a >= 0) ? uint(a) : 0;
    }

    // @notice somethimes we need to print int but cast them to uint befor
    function inv(int x) internal pure returns (uint z) {
        z = x < 0 ? uint(-x) : uint(x);
    }

    // @notice Copied from open-zeppelin SignedMath
    // @dev must be unchecked in order to support `n = type(int256).min`
    function abs(int x) internal pure returns (uint) {
        unchecked {
            return uint(x >= 0 ? x : -x);
        }
    }

    // --- MINIMUM and MAXIMUM

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }

    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }

    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }

    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import './Positions.sol';
import '@dex/lib/LeverageMath.sol';
import '@dex/lib/Structs.sol';
import '@dex/lib/FinMath.sol';
import '@dex/perp/interfaces/IVault.sol';
import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

error Inexistent(uint);

library JoinLib {
    using FinMath for uint24;
    using FinMath for int;
    using FinMath for uint;

    using LeverageMath for Match;

    event MatchInexistant(uint indexed matchId, uint indexed orderId);
    event MakerIsTrader(
        uint indexed matchId,
        address indexed maker,
        uint orderId
    );
    event LowTraderCollateral(
        uint indexed matchId,
        address indexed trader,
        uint orderId,
        uint traderCollateral,
        uint collateralNeeded
    );

    event LowMakerCollateralForFees(
        uint indexed matchId,
        address indexed maker,
        uint orderId,
        uint allocatedCollateral,
        uint makerFees
    );

    event LowTraderCollateralForFees(
        uint indexed matchId,
        address indexed trader,
        uint orderId,
        uint allocatedCollateral,
        uint traderFees
    );

    event MaxOpeningLeverage(
        address indexed user,
        uint matchId,
        uint orderId,
        uint price
    );

    event LowMakerCollateral(
        uint indexed matchId,
        address indexed maker,
        uint orderId,
        uint makerCollateral,
        uint collateralNeeded
    );

    event OrderExpired(
        uint indexed matchId,
        address indexed trader,
        address indexed maker,
        uint orderId,
        uint orderTimestamp
    );

    event MatchAlreadyActive(
        uint indexed matchId,
        uint indexed orderId,
        address indexed trader
    );

    // @notice Sometimes the trader choose a position size smaller than the picked
    // maker position, so we have to ajust the collateral and amount accordingly.
    function normalize(
        Match memory m,
        uint amount
    ) public pure returns (Match memory) {
        if (amount < m.amount) {
            m.collateralM = ((m.collateralM.mul(amount)) / m.amount);
            m.amount = amount;
        }
        return m;
    }

    function beforeChecks(
        Match memory m,
        Order memory o,
        uint orderId,
        uint matchId,
        address maker,
        uint balance,
        int feesM,
        int feesT
    ) public returns (bool) {
        // check if order is canceled or has already been matched
        if (m.trader != 0) {
            emit MatchAlreadyActive(matchId, orderId, o.owner);
            return false;
        }

        if (o.owner == maker) {
            emit MakerIsTrader(matchId, maker, orderId);
            return false;
        }

        if (balance < o.collateral) {
            emit LowTraderCollateral(
                matchId,
                o.owner,
                orderId,
                balance,
                o.collateral
            );
            return false;
        }

        if (int(o.collateral) <= feesT) {
            emit LowTraderCollateralForFees(
                matchId,
                o.owner,
                orderId,
                o.collateral,
                uint(feesT)
            );
            return false;
        }

        if (int(m.collateralM) <= feesM) {
            emit LowMakerCollateralForFees(
                matchId,
                maker,
                orderId,
                m.collateralM,
                uint(feesM)
            );
            return false;
        }

        return true;
    }

    struct AfterCheck {
        PriceData priceData;
        IConfig config;
        IVault vault;
        address maker;
        address trader;
        uint matchId;
        uint orderId;
        uint maxTimestamp;
        uint8 tokenDecimals;
    }

    function afterChecks(
        Match memory m,
        AfterCheck calldata params
    ) public returns (bool) {
        if (
            m.isOverLeveraged_(
                params.priceData,
                params.config,
                false,
                params.tokenDecimals
            )
        ) {
            emit MaxOpeningLeverage(
                params.trader,
                params.matchId,
                params.orderId,
                params.priceData.price
            );
            return false;
        }

        if (
            m.isOverLeveraged_(
                params.priceData,
                params.config,
                true,
                params.tokenDecimals
            )
        ) {
            emit MaxOpeningLeverage(
                params.maker,
                params.matchId,
                params.orderId,
                params.priceData.price
            );
            return false;
        }

        if (params.vault.collateral(params.maker) < m.collateralM) {
            emit LowMakerCollateral(
                params.matchId,
                params.maker,
                params.orderId,
                params.vault.collateral(params.maker),
                m.collateralM
            );
            return false;
        }

        if (
            params.maxTimestamp != 0 &&
            params.priceData.timestamp > params.maxTimestamp
        ) {
            emit OrderExpired(
                params.matchId,
                params.trader,
                params.maker,
                params.orderId,
                params.maxTimestamp
            );
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@dex/lib/Structs.sol';
import '@dex/lib/PnLMath.sol';
import '@dex/lib/FinMath.sol';

import '@dex/perp/interfaces/IConfig.sol';
import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

library LeverageMath {
    using FinMath for uint;
    using FinMath for int;
    using PnLMath for Match;

    // TODO: move min/max to be used from FinMath
    function _min(uint a, uint b) internal pure returns (uint res) {
        res = (a <= b) ? a : b;
    }

    function _max(uint a, uint b) internal pure returns (uint res) {
        res = (a >= b) ? a : b;
    }

    // @dev External function.
    function isOverLeveraged(
        Match storage m,
        PriceData calldata priceData,
        IConfig config,
        bool isMaker,
        uint8 collateralDecimals
    ) public view returns (bool) {
        return
            isOverLeveraged_(m, priceData, config, isMaker, collateralDecimals);
    }

    function isOverLeveraged_(
        Match memory m,
        PriceData calldata priceData,
        IConfig config,
        bool isMaker,
        uint8 collateralDecimals
    ) public view returns (bool) {
        Leverage memory leverage = config.getLeverage();
        uint timeElapsed = m.start == 0 ? 0 : block.timestamp - m.start;
        return
            getLeverage(m, priceData, isMaker, 0, collateralDecimals) >
            (
                isMaker
                    ? getMaxLeverage(
                        config,
                        m.frPerYear,
                        timeElapsed == 0
                            ? block.timestamp - priceData.timestamp
                            : timeElapsed
                    )
                    : timeElapsed == 0
                    ? leverage.maxLeverageOpen
                    : leverage.maxLeverageOngoing
            );
    }

    // @dev Internal function
    function getMaxLeverage(
        IConfig config,
        uint fr,
        uint timeElapsed
    ) public view returns (uint maxLeverage) {
        // console.log("[_getMaxLeverage()] fr >= fmfr --> ", fr >= fmfr);
        // console.log("[_getMaxLeverage()] timeElapsed >= leverage.maxTimeGuarantee --> ", timeElapsed >= leverage.maxTimeGuarantee);
        Leverage memory leverage = config.getLeverage();
        // NOTE: Expecting time elapsed in days
        timeElapsed = timeElapsed / 86400;
        maxLeverage = ((fr >= config.fmfrPerYear()) ||
            (timeElapsed >= leverage.maxTimeGuarantee))
            ? (timeElapsed == 0)
                ? leverage.maxLeverageOpen
                : leverage.maxLeverageOngoing
            : _min(
                _max(
                    ((leverage.s * leverage.FRTemporalBasis * leverage.b)
                        .bps() /
                        ((leverage.maxTimeGuarantee - timeElapsed) *
                            (config.fmfrPerYear() - fr + leverage.f0))),
                    leverage.minGuaranteedLeverage
                ),
                leverage.maxLeverageOpen
            );
        // maxLeverage = (fr >= fmfr) ? type(uint).max : (minRequiredMargin * timeToExpiry / (totTime * (fmfr - fr)));
    }

    // @dev Internal function
    // NOTE: For leverage, notional depends on entryPrice while accruedFR is transformed into collateral using currentPrice
    // Reasons
    // LP Pool risk is connected to Makers' Leverage
    // (even though we have a separate check for liquidation, we use leverage to control collateral withdrawal)
    // so higher leverage --> LP Pool risk increases
    // Makers' are implicitly always long market for the accruedFR component
    // NOTE: The `overrideAmount` is used in `join()` since we split after having done a bunch of checks so the `m.amount` is not the correct one in that case
    function getLeverage(
        Match memory m,
        PriceData calldata priceData,
        bool isMaker,
        uint overrideAmount,
        uint8 collateralDecimals
    ) public view returns (uint leverage) {
        // NOTE: This is correct almost always with the exception of the levarge computation
        // for the maker when they submit an order which is not picked yet and
        // as a consquence we to do not have an entryPrice yet so we use currentPrice
        uint notional = (10 ** (collateralDecimals))
            .wmul((overrideAmount > 0) ? overrideAmount : m.amount)
            .wmul(
                (isMaker && (m.trader == 0)) ? priceData.price : m.entryPrice
            );
        uint realizedPnL = m.accruedFR(priceData, collateralDecimals);
        uint collateral_plus_realizedPnL = (isMaker)
            ? m.collateralM + realizedPnL
            : m.collateralT - _min(m.collateralT, realizedPnL);
        if (collateral_plus_realizedPnL == 0) return type(uint).max;

        // TODO: this is a simplification when removing the decimals lib,
        //       need to check and move to FinMath lib
        leverage = notional.bps() / collateral_plus_realizedPnL;
    }
}

pragma solidity ^0.8.17;

import '@base64/base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

library NFTDescriptor {
    function constructTokenURI(
        uint tokenId
    ) public pure returns (string memory) {
        string memory name = string.concat(
            'test name: ',
            Strings.toString(tokenId)
        );
        string memory descriptionPartOne = 'test description part 1';
        string memory descriptionPartTwo = 'test description part 2';
        string memory image = Base64.encode(bytes(generateSVGImage()));

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "description":"',
                                descriptionPartOne,
                                descriptionPartTwo,
                                '", "image": "',
                                'data:image/svg+xml;base64,',
                                image,
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function generateSVGImage() internal pure returns (string memory svg) {
        return
            string(
                abi.encodePacked(
                    '<?xml version="1.0" encoding="UTF-8"?>',
                    '<svg version="1.1" viewBox="50 20 600 600" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
                    '<g>',
                    '<path d="m589.12 253.12h-82.883c-7.8398 0-15.121 3.3594-20.16 8.9609l-13.441 15.68-24.641-56c-6.1602-13.441-21.84-19.602-35.281-14-13.441 6.1602-19.602 21.84-14 35.281l41.441 94.641c3.9219 8.3984 11.199 14.559 20.719 15.68 1.1211 0 2.8008 0.55859 3.9219 0.55859 7.8398 0 15.121-3.3594 20.16-8.9609l33.039-38.078h70.559c14.559 0 26.879-11.762 26.879-26.879 0.56641-14.562-11.195-26.883-26.312-26.883z"/>',
                    '<path d="m353.92 221.76c-6.1602-13.441-21.84-19.602-35.281-14-13.441 6.1602-19.602 21.84-14 35.281l41.441 94.641c4.4805 10.078 14.559 16.238 24.641 16.238 3.3594 0 7.2812-0.55859 10.641-2.2383 13.441-6.1602 19.602-21.84 14-35.281z"/>',
                    '<path d="m259.28 221.76c-3.9219-8.3984-11.199-14.559-20.719-15.68-8.9609-1.6797-18.48 1.6797-24.078 8.9609l-33.039 38.078h-70.566c-14.559 0-26.879 11.762-26.879 26.879 0 14.559 11.762 26.879 26.879 26.879h82.879c7.8398 0 15.121-3.3594 20.16-8.9609l13.441-15.68 24.641 56c4.4805 10.078 14.559 16.238 24.641 16.238 3.3594 0 7.2812-0.55859 10.641-2.2383 13.441-6.1602 19.602-21.84 14-35.281z"/>',
                    '</g>',
                    '</svg>'
                )
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import './Positions.sol';
import '@dex/lib/LeverageMath.sol';
import '@dex/lib/Structs.sol';
import '@dex/perp/interfaces/IConfig.sol';
import '@dex/lib/FinMath.sol';
import '@dex/lib/SafeCast.sol';
import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

library PnLMath {
    using FinMath for uint24;
    using FinMath for int;
    using FinMath for uint;
    using SafeCast for uint;

    // NOTE: Need to move this computation out of `pnl()` to avoid the stack too deep issue in it
    function _gl(
        uint amount,
        int dp,
        uint collateralDecimals
    ) internal pure returns (int gl) {
        gl = int(10 ** (collateralDecimals)).wmul(int(amount)).wmul(dp); // Maker's GL
    }

    function pnl(
        Match memory m,
        uint tokenId,
        uint timestamp,
        uint exitPrice,
        uint makerFRFee,
        uint8 collateralDecimals
    ) public pure returns (int pnlM, int pnlT, uint FRfee) {
        require(timestamp > m.start, 'engine/wrong_timestamp');
        require(
            (tokenId == m.maker) || (tokenId == m.trader),
            'engine/invalid-tokenId'
        );
        // uint deltaT = timestamp.sub(m.start);
        // int deltaP = exitPrice.isub(m.entryPrice);
        // int delt = (m.pos == POS_SHORT) ? -deltaP : deltaP;

        // NOTE: FR is seen from the perspective of the maker and it is >= 0 always by construction
        uint aFR = _accruedFR(
            timestamp.sub(m.start),
            m.frPerYear,
            m.amount,
            exitPrice,
            collateralDecimals
        );

        // NOTE: `m.pos` is the Maker Position
        int mgl = (((m.pos == POS_SHORT) ? int(-1) : int(1)) *
            _gl(m.amount, exitPrice.isub(m.entryPrice), collateralDecimals));

        // NOTE: Before deducting FR Fees, the 2 PnLs need to be symmetrical
        pnlM = mgl + int(aFR);
        pnlT = -pnlM;

        // NOTE: After the FR fees, no more symmetry
        FRfee = makerFRfees(makerFRFee, aFR);
        pnlM -= int(FRfee);
    }

    function makerFRfees(
        uint makerFRFee,
        uint fundingRate
    ) internal pure returns (uint) {
        return makerFRFee.bps(fundingRate);
    }

    function accruedFR(
        Match memory m,
        PriceData memory priceData,
        uint8 collateralDecimals
    ) public view returns (uint) {
        if (m.start == 0) return 0;
        uint deltaT = block.timestamp.sub(m.start);
        return
            _accruedFR(
                deltaT,
                m.frPerYear,
                m.amount,
                priceData.price,
                collateralDecimals
            );
    }

    function _accruedFR(
        uint deltaT,
        uint frPerYear,
        uint amount,
        uint price,
        uint8 collateralDecimals
    ) public pure returns (uint) {
        return
            (10 ** (collateralDecimals))
                .mul(frPerYear)
                .bps(deltaT)
                .wmul(amount)
                .wmul(price) / (365 days); // 3600 * 24 * 365
    }

    function isLiquidatable(
        Match memory m,
        uint tokenId,
        uint price,
        IConfig config,
        uint8 collateralDecimals
    ) external view returns (int pnlM, int pnlT, bool) {
        // check if the match has not previously been deleted
        (pnlM, pnlT, ) = pnl(
            m,
            tokenId,
            block.timestamp,
            price,
            0,
            collateralDecimals
        );

        if (m.maker == 0) return (pnlM, pnlT, false);
        if (tokenId == m.maker) {
            return (
                pnlM,
                pnlT,
                pnlM.add(m.collateralM).sub(
                    config.bufferMakerBps().ibps(m.collateralM)
                ) < config.bufferMaker().i256()
            );
        } else if (tokenId == m.trader) {
            return (
                pnlM,
                pnlT,
                pnlT.add(m.collateralT).sub(
                    config.bufferTraderBps().ibps(m.collateralT)
                ) < config.bufferTrader().i256()
            );
        } else {
            return (pnlM, pnlT, false);
        }
    }
}

pragma solidity ^0.8.17;

int8 constant POS_SHORT = -1;
int8 constant POS_NEUTRAL = 0;
int8 constant POS_LONG = 1;

// SPDX-License-Identifier: GPL-2.0-or-later
// Uniswap lib
pragma solidity 0.8.17;

// @title Safe casting methods
// @notice Contains methods for safely casting between types
library SafeCast {
    // @notice Cast a uint256 to a uint160, revert on overflow
    // @param y The uint256 to be downcasted
    // @return z The downcasted integer, now type uint160
    function u160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y, 'cast-u160');
    }

    // @notice Cast a int256 to a int128, revert on overflow or underflow
    // @param y The int256 to be downcasted
    // @return z The downcasted integer, now type int128
    function i128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y, 'cast-i128');
    }

    // @notice Cast a uint256 to a int256, revert on overflow
    // @param y The uint256 to be casted
    // @return z The casted integer, now type int256
    function i256(uint256 y) internal pure returns (int256 z) {
        require(y < 2 ** 255, 'cast-i256');
        z = int256(y);
    }

    // @notice Cast an int256, check if it's not negative
    // @param y The uint256 to be downcasted
    // @return z The downcasted integer, now type uint160
    function u256(int256 y) internal pure returns (uint256 z) {
        require(y >= 0, 'cast-u256');
        z = uint256(y);
    }
}

pragma solidity ^0.8.17;

struct Match {
    int8 pos; // If maker is short = true
    int24 premiumBps; // In percent of the amount
    uint24 frPerYear;
    uint24 fmfrPerYear; // The fair market funding rate when the match was done
    uint maker; // maker vault token-id
    uint trader; // trader vault token-id
    uint amount;
    uint start; // timestamp of the match starting
    uint entryPrice;
    uint collateralM; // Maker  collateral
    uint collateralT; // Trader collateral
    // uint256 nextMatchId; // Next match id, in case of split, used by the automatic rerooting
    uint8 minPremiumFeeDiscountPerc; // To track what perc of minPreomiumFee to pay, used when the order is split
    bool close; // A close request for this match is pending
}

struct Order {
    bool canceled;
    int8 pos;
    address owner; // trader address
    uint tokenId;
    uint matchId; // trader selected matchid
    uint amount;
    uint collateral;
    uint collateralAdd;
    // NOTE: Used to apply the check for the Oracle Latency Protection
    uint timestamp;
    // NOTE: In this case, we give trader the max full control on the price for matching: no assumption it is symmetric and we do not compute any percentage so introducing some approximations, the trader writes the desired prices
    uint slippageMinPrice;
    uint slippageMaxPrice;
    uint maxTimestamp;
}

struct CloseOrder {
    uint matchId;
    uint timestamp;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct PriceData {
    // wad
    uint256 price;
    uint256 timestamp;
}

interface IOracle {
    event NewValue(uint256 value, uint256 timestamp);

    function setPrice(uint256 _value) external;

    function decimals() external view returns (uint8);

    function getPrice() external view returns (PriceData memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;
import '@dex/lib/NFTDescriptor.sol';
import '@dex/lib/PnLMath.sol';
import '@dex/lib/FeesMath.sol';
import '@dex/lib/FinMath.sol';
import '@dex/lib/Structs.sol';
import '@dex/lib/JoinLib.sol';
import '@dex/oracles/interfaces/IOracle.sol';
import '@dex/perp/interfaces/IEngine.sol';
import '@dex/perp/interfaces/IVault.sol';
import '@dex/perp/interfaces/IPoolRatio.sol';
import '@dex/perp/interfaces/IConfig.sol';

// import "@openzeppelin-upgradeable/contracts/token/ERC721/ERC721Upgradeable.sol";
error OrderMinAmount();
error MinFundingRate();
error FundingRateModulo();
error MissingCollateral();
error ZeroCollateral();
error OverLeveraged(uint matchId);
error SamePos();
error NeutralPos();
error UnexistingMatch();
error TraderIsMaker();
error NonTrader();
error CancelActiveMatch();
error OnlyMaker();
error OnlyTraderMakerOperation();
error InsufficientCollateral();
error MakerNorTrader();
error ZeroAmount();
error CollateralTooLow();
error MaxLeverageOpen();
error UnecessarySplit();
error PendingClose();
error ActivatedMatch();
error MatchExpirationUnreached();

uint constant EXPIRATION_ORDER_PERIOD = 7200;

contract Engine is IEngineEvents {
    using PnLMath for Match;
    using LeverageMath for Match;
    using FinMath for int;
    using FinMath for uint;
    using FeesMath for Order;
    using NFTDescriptor for uint;
    using JoinLib for Match;

    IOracle public oracle;

    // skip 0
    uint128 private nextMatchId;

    // pending orders
    uint128 private nextClose;
    uint128 private nextOpen;

    uint public openInterest;

    // trader order queues
    Order[] public opens;
    CloseOrder[] public closes;

    IConfig public config;

    IVault public vault;

    IPoolRatio public pool;

    uint8 private tokenDecimals;

    mapping(uint => Match) public matches;

    //@notice Instead of using constructor, this contract is cloned using the Clone lib
    //@dev https://docs.openzeppelin.com/contracts/4.x/api/proxy#Clones
    function initialize(
        address oracle_,
        IVault vault_,
        IPoolRatio pool_,
        IConfig config_
    ) external {
        oracle = IOracle(oracle_);
        vault = vault_;
        pool = pool_;
        config = config_;

        tokenDecimals = vault.token().decimals();

        // skip 0
        nextMatchId = 1;
    }

    function pnl(
        uint matchId,
        uint tokenId,
        uint timestamp,
        uint exitPrice
    )
        external
        view
        returns (
            int pnLM,
            int pnlT,
            uint FRfee
        )
    {
        return
            matches[matchId].pnl(
                tokenId,
                timestamp,
                exitPrice,
                config.makerFRFeeBps(),
                tokenDecimals
            );
    }

    function accruedFR(uint matchId) external view returns (uint) {
        Match memory m = matches[matchId];
        return m.accruedFR(oracle.getPrice(), tokenDecimals);
    }

    // @dev Temporary 'deep stack' fix, to be used on tests, used 0.25 kb margin, once
    // using the automatic generated viewer has to many args, after adding the `close`.
    function getMatch(uint matchId) external view returns (Match memory) {
        return matches[matchId];
    }

    function getMaxLeverageOpen(uint fr) external view returns (uint) {
        return
            LeverageMath.getMaxLeverage(
                config,
                fr,
                block.timestamp - oracle.getPrice().timestamp
            );
    }

    // @notice Here there is no check on the order min amount since it can be
    // created as a result of a split
    function open(
        uint amount,
        int24 premiumBps,
        // NOTE: We do not allow negative FRs in v1
        uint24 frPerYear,
        int8 pos,
        uint collateral_,
        address recipient
    ) external returns (uint matchId, uint tokenId) {
        if (amount < config.getAmounts().orderMinAmount)
            revert OrderMinAmount();
        if (frPerYear < config.minFRPerYear()) revert MinFundingRate();
        if ((frPerYear % config.frPerYearModulo()) != 0)
            revert FundingRateModulo();
        if (vault.collateral(recipient) < collateral_)
            revert MissingCollateral();
        if (collateral_ == 0) revert ZeroCollateral();

        tokenId = vault.mint(recipient);
        Match memory m;
        m.maker = tokenId; // the token owner is the maker of the match
        m.amount = amount;
        m.premiumBps = premiumBps;
        m.frPerYear = frPerYear;
        m.pos = pos;
        m.collateralM = collateral_;
        m.minPremiumFeeDiscountPerc = 100; // Initialize at 100%

        matches[(matchId = nextMatchId++)] = m; // use match-id as idx
        if (
            matches[matchId].isOverLeveraged(
                oracle.getPrice(),
                config,
                true,
                tokenDecimals
            )
        ) revert OverLeveraged(matchId);
        // m.auto_resubmit = auto_resubmit;
        emit NewMakerOrder(recipient, matchId, tokenId);
    }

    // --- Trader ---

    // @dev pick maker match
    function pick(
        uint matchId,
        uint amount,
        uint collateral_,
        int8 pos
    ) external {
        if (
            matches[matchId].pos != POS_NEUTRAL &&
            pos != -1 * matches[matchId].pos
        ) revert SamePos();
        if (pos == POS_NEUTRAL) revert NeutralPos();
        if (matches[matchId].maker == 0) revert UnexistingMatch();
        if (matches[matchId].trader != 0) revert ActivatedMatch();
        if (vault.ownerOf(matches[matchId].maker) == msg.sender)
            revert TraderIsMaker();
        if (amount <= config.getAmounts().orderMinAmount)
            revert OrderMinAmount();

        Order memory o;
        o.owner = msg.sender;
        o.matchId = matchId;
        o.amount = amount;
        o.collateral = collateral_;
        o.pos = pos;
        o.timestamp = block.timestamp;
        o.maxTimestamp = o.timestamp + EXPIRATION_ORDER_PERIOD;
        opens.push(o);

        emit NewTraderOrder(msg.sender, matchId, opens.length - 1);
    }

    // @notice Cancel trader order
    // @param id Order ID
    function cancelOrder(uint orderId) external {
        Order storage o = opens[orderId];
        if (o.owner != msg.sender) revert NonTrader();
        o.canceled = true;
        emit OrderCanceled(msg.sender, orderId, o.matchId);
    }

    function cancelMatch(uint matchId) external {
        if (matches[matchId].start != 0) revert CancelActiveMatch();
        if (vault.ownerOf(matches[matchId].maker) != msg.sender)
            revert OnlyMaker();
        emit MatchCanceled(msg.sender, matchId);
        delete matches[matchId];
    }

    // @notice submit close trader order
    // @matchId match id that comes from UI
    function close(uint matchId) external {
        bool isMaker = (msg.sender == vault.ownerOf(matches[matchId].maker))
            ? true
            : false;
        bool isTrader = (msg.sender == vault.ownerOf(matches[matchId].trader))
            ? true
            : false;
        if (!isTrader && !isMaker) revert OnlyTraderMakerOperation();
        if (matches[matchId].close) revert PendingClose();
        if (
            isMaker &&
            block.timestamp < matches[matchId].start + config.maxTimeGuarantee()
        ) revert MatchExpirationUnreached();
        emit MatchClose(msg.sender, matchId);
        matches[matchId].close = true; // flag true for the close request
        closes.push(CloseOrder(matchId, block.timestamp));
    }

    // @dev removing memory struct load here gave us 0.34 kb
    function increaseCollateral(uint matchId, uint amount) external {
        if (amount == 0) revert ZeroAmount();
        if (vault.collateral(msg.sender) < amount)
            revert InsufficientCollateral();
        // increase maker collateral
        if (msg.sender == vault.ownerOf(matches[matchId].maker)) {
            matches[matchId].collateralM += amount;
            emit CollateralIncreased(msg.sender, matchId, amount);
        } else if (msg.sender == vault.ownerOf(matches[matchId].trader)) {
            matches[matchId].collateralT += amount;
            emit CollateralIncreased(msg.sender, matchId, amount);
        } else {
            revert MakerNorTrader();
        }
        vault.lock(amount, msg.sender);
    }

    // @dev cleaning storage load on Match gave us 0.163 kb and reduced
    // average gas use from 15k to 13.5k
    function decreaseCollateral(uint matchId, uint amount) external {
        if (amount == 0) revert ZeroAmount();
        // Match storage m = matches[matchId];
        PriceData memory priceData = oracle.getPrice();
        // increase maker collateral
        if (msg.sender == vault.ownerOf(matches[matchId].maker)) {
            if (matches[matchId].collateralM < amount)
                revert CollateralTooLow();
            matches[matchId].collateralM -= amount;
            if (
                matches[matchId].isOverLeveraged(
                    priceData,
                    config,
                    true,
                    tokenDecimals
                )
            ) revert MaxLeverageOpen();

            emit CollateralDecreased(msg.sender, matchId, amount);
        } else if (msg.sender == vault.ownerOf(matches[matchId].trader)) {
            if (matches[matchId].collateralT < amount)
                revert CollateralTooLow();
            matches[matchId].collateralT -= amount;
            if (
                matches[matchId].isOverLeveraged(
                    priceData,
                    config,
                    true,
                    tokenDecimals
                )
            ) revert MaxLeverageOpen();

            emit CollateralDecreased(msg.sender, matchId, amount);
        } else {
            revert MakerNorTrader();
        }
        vault.unlock(amount, msg.sender);
    }

    // --- Keeper ---

    // associate trader order to maker match
    function join(Order storage order, PriceData memory priceData) internal {
        Match memory m = matches[order.matchId].normalize(order.amount); // load by the selected maker tokenid
        if (m.maker == 0) {
            emit MatchInexistant(order.matchId, nextOpen);
            return;
        }
        address maker = vault.ownerOf(m.maker);
        uint balance = vault.collateral(order.owner);

        // --- Trader Fees ---
        uint traderFees = order.traderFees(priceData, config);

        (int premiumT, uint premiumFee) = order.premium(
            priceData,
            m.premiumBps,
            config,
            m.minPremiumFeeDiscountPerc
        );

        //
        int _deltaM = int(premiumFee) - premiumT;
        int _deltaT = premiumT.add(traderFees); //  int256(traderFees) + premiumT;

        if (
            !m.beforeChecks(
                order,
                nextOpen,
                order.matchId,
                maker,
                balance,
                _deltaM,
                _deltaT
            )
        ) return;

        // NOTE: We can use negative premium to cover the traderFees at least partially, excess will go to Trader Vault Account
        m.collateralT = order.collateral - _deltaT.pos();

        // NOTE: We can use positive premium to cover the makerFees, excess will go to Maker Vault Account
        m.collateralM = m.collateralM - _deltaM.pos();

        if (
            !m.afterChecks(
                JoinLib.AfterCheck(
                    priceData,
                    config,
                    vault,
                    maker,
                    order.owner,
                    order.matchId,
                    nextOpen,
                    order.maxTimestamp,
                    tokenDecimals
                )
            )
        ) return;

        // No more checks so here we can modify the state safely

        uint tokenId = vault.mint(order.owner);
        m.trader = tokenId; // setup match with the trader token
        m.start = uint128(priceData.timestamp); // set oracle time we matched
        m.entryPrice = priceData.price; // set oracle price on match
        m.fmfrPerYear = config.fmfrPerYear();

        if (order.amount < matches[order.matchId].amount) {
            // create another match with the remaining amount from the original match
            (order.matchId, m.maker) = _split(matches[order.matchId], order);
        }
        // NOTE: Makers can choose to be long or short or neutral so that it is the trader deciding
        m.pos = (m.pos == POS_NEUTRAL) ? (-1 * order.pos) : m.pos;

        // update the balance available to trader/maker
        if (_deltaT < 0) {
            // NOTE: Crediting excess negative premium to the Trader Vault Account
            vault.unlock(uint(-_deltaT), order.owner);
        }

        if (_deltaM < 0) {
            // NOTE: Crediting excess positive premium to the Maker Vault Account
            vault.unlock(uint(-_deltaM), maker);
        }
        matches[order.matchId] = m;
        vault.lock(m.collateralT, order.owner);
        vault.lock(m.collateralM, maker);

        openInterest += order.amount;

        emit ActiveMatch(
            order.matchId,
            maker,
            order.owner,
            nextOpen,
            m.maker,
            m.trader
        );
    }

    // desassociate trader from match based on trader tokenid
    function unjoin(uint matchId, PriceData memory priceData) internal {
        Match storage m = matches[matchId]; // load Match by trader matchid
        // // early bailout in case the match is already closed
        if (m.maker == 0) return;
        (int pnlM, int pnlT, ) = m.pnl(
            m.maker,
            priceData.timestamp,
            priceData.price,
            config.makerFRFeeBps(),
            tokenDecimals
        );

        vault.settle(m.maker, m.collateralM, pnlM);
        vault.settle(m.trader, m.collateralT, pnlT);

        openInterest -= m.amount;
        emit CloseMatch(
            matchId,
            m.maker,
            m.trader,
            pnlM,
            pnlT,
            priceData.price
        );
        delete matches[matchId].maker;
    }

    function _split(Match storage m, Order storage o)
        internal
        returns (uint matchId, uint tokenId)
    {
        uint newAmount = m.amount - o.amount;
        if (newAmount <= config.getAmounts().orderMinAmount) {
            return (0, 0);
        }
        address maker = vault.ownerOf(m.maker);
        tokenId = vault.mint(maker); // mint maker token
        Match memory newMatch = m;
        newMatch.amount = newAmount;
        newMatch.collateralM =
            m.collateralM -
            ((m.collateralM * o.amount) / m.amount);
        newMatch.minPremiumFeeDiscountPerc =
            m.minPremiumFeeDiscountPerc -
            uint8((uint(m.minPremiumFeeDiscountPerc) * o.amount) / m.amount);
        // create a new potential match in the order book;
        // matches[(matchId = nextMatchId++)] = newMatch;
        matches[o.matchId] = newMatch;
        matchId = nextMatchId++;
        emit MatchSplitted(matchId, o.matchId, tokenId);
    }

    // @dev We need this function here to automate liquidations
    function isLiquidatable(uint matchId, uint tokenId)
        external
        view
        returns (bool)
    {
        Match memory m = matches[matchId];
        PriceData memory p = oracle.getPrice();
        (, , bool isLiq) = m.isLiquidatable(
            tokenId,
            p.price,
            config,
            tokenDecimals
        );
        return isLiq;
    }

    function liquidate(
        uint[] calldata matchIds,
        uint[] calldata tokenIds,
        address recipient
    ) external {
        PriceData memory p = oracle.getPrice(); // TODO: do we need to get price in the loop?
        for (uint i = 0; i < matchIds.length; i++) {
            uint matchId = matchIds[i];
            uint tokenId = tokenIds[i];

            Match memory m = matches[matchId];
            (int pnlM, int pnlT, bool isLiq) = m.isLiquidatable(
                tokenId,
                p.price,
                config,
                tokenDecimals
            );
            if (!isLiq) continue;
            if (tokenId == m.maker) {
                // TODO: Implement Maker Liquidation --> it means
                // 1) Decapitating current owner
                // 2) Recapitilizing through LP Pool
                // 3) Minting ownership to pool --> Take care about auction start
            } else {
                vault.adjust(m.collateralT, pnlT, recipient);
                // settle profitable pnl for the maker on the vault, if the trader
                // was liquidated, maker is profitable on the other side of the trade
                vault.unlock(
                    uint(int(m.collateralM) + pnlM),
                    vault.ownerOf(m.maker)
                );

                openInterest -= m.amount;

                emit MatchLiquidated(
                    matchId,
                    pnlM,
                    pnlT,
                    oracle.getPrice().price
                );
                delete matches[matchId].maker;
            }
        }
    }

    ///@notice returns the current market usage vs the insurance pool
    function poolUsage(uint price, uint orderAmount)
        public
        view
        returns (uint)
    {
        return
            openInterest.add(orderAmount).wmul(price).bps().div(
                pool.capLimit()
            );
    }

    function validateOICap(uint price, uint orderAmount)
        internal
        view
        returns (bool)
    {
        if (pool.capLimit() == 0) return false;
        return poolUsage(price, orderAmount) < config.openInterestCap();
    }

    //@dev return true if queue is ready to run `runOpens`
    function openStatus()
        public
        view
        returns (bool canExec, bytes memory execPayload)
    {
        PriceData memory p = oracle.getPrice();
        canExec =
            opens.length > nextOpen &&
            p.timestamp >= opens[nextOpen].timestamp &&
            validateOICap(p.price, 0);
        execPayload = abi.encodeCall(this.runOpens, 0);
    }

    function runOpens(uint n) external {
        PriceData memory p = oracle.getPrice();
        uint end = (n == 0)
            ? opens.length
            : Math.min(nextOpen + n, opens.length);
        // run the last queue and update the price
        while (nextOpen < end) {
            Order storage order = opens[nextOpen];
            // if order expired we simply instructs the counter to jump it forever
            if (order.canceled || order.maxTimestamp < block.timestamp) {
                delete opens[nextOpen];
                nextOpen++;
                continue;
            }
            // check if price is recent enough, break the loop if not as all further order will be too recent
            if (p.timestamp < order.timestamp) break;
            if (!validateOICap(p.price, order.amount)) break;
            join(order, p);
            delete opens[nextOpen];
            nextOpen++;
        }
    }

    //@dev return true if queue is ready to run `runOpens`
    function closeStatus()
        public
        view
        returns (bool canExec, bytes memory execPayload)
    {
        canExec =
            closes.length > nextClose &&
            oracle.getPrice().timestamp >= closes[nextClose].timestamp;
        execPayload = abi.encodeCall(this.runCloses, 0);
    }

    function runCloses(uint n) external {
        n = (n == 0) ? closes.length : Math.min(nextClose + n, closes.length);
        PriceData memory priceData = oracle.getPrice();
        while (nextClose < n) {
            CloseOrder memory order = closes[nextClose];
            // check if price is recent enough, break the loop if not as all further order will be too recent as well
            if (priceData.timestamp < order.timestamp) break;
            unjoin(order.matchId, priceData);
            delete closes[nextClose];
            nextClose++;
        }
    }
}

pragma solidity ^0.8.17;

struct Bips {
    uint24 bufferTraderBps;
    uint24 bufferMakerBps;
    uint24 openInterestCap; // 4 decimals (bips)
    uint24 fmfrPerYear; // 4 decimals (bips)
    uint24 frPerYearModulo; // 4 decimals (bips)
    uint24 premiumFeeBps; // % of the premium that protocol collects
    uint24 minFRPerYear; // 4 decimals (bips)
    uint24 traderFeeBps; // 4 decimals (bips)
    uint24 makerFRFeeBps; // 4 decimals (bips)
}

struct Amounts {
    uint bufferTrader;
    uint bufferMaker;
    uint128 minPremiumFee;
    uint128 orderMinAmount;
}

// @dev Leverage is defined by the formula:
// (units * openingPrice) / (collateral + accruedFR)
// maxLeverage is a market-specific governance parameter that
// determines maximum leverage for traders and makers.
// Like in PerpV2, we have 2 max leverages: one for when the position is opened and
// the other for the position ongoing. Leverage [lev] is defined by:
// if (FR < FMFR) {
//     lev = s.mul(b).mul(365).div(T-t).div(FMFR-FR+f0);
//     lev = lev < maxLev ? lev : maxLev;
// } else { lev = maxLeverage; }
// s  = scaling factor (governance parameter)
// b  = buffer (fraction, so ultimately affects denominator)
// T  = expiry (i.e. 180 days)
// t  = elapsed time since contract created
// FR = funding rate set by maker creating offer
// f0 = linear shift (governance parameter)
// FMFR = fair market funding rate (market-specific governance risk parameter)
// Atm we do not support negative FR

struct Leverage {
    uint24 maxLeverageOpen;
    uint24 maxLeverageOngoing;
    uint24 minGuaranteedLeverage;
    uint s;
    uint b;
    uint f0;
    uint maxTimeGuarantee; // Example 180 days
    uint FRTemporalBasis; // In case the above is measured in days then it is 365 days
}

interface IConfig {
    function maxTimeGuarantee() external view returns (uint);

    function fmfrPerYear() external view returns (uint24);

    function premiumFeeBps() external view returns (uint24);

    function openInterestCap() external view returns (uint24);

    function frPerYearModulo() external view returns (uint24);

    function minFRPerYear() external view returns (uint24);

    function traderFeeBps() external view returns (uint24);

    function bufferTraderBps() external view returns (uint24);

    function bufferMakerBps() external view returns (uint24);

    function makerFRFeeBps() external view returns (uint24);

    function bufferTrader() external view returns (uint);

    function bufferMaker() external view returns (uint);

    function getLeverage() external view returns (Leverage memory);

    function getBips() external view returns (Bips memory);

    function getAmounts() external view returns (Amounts memory);

    function setLeverage(Leverage calldata leverage) external;

    function setBips(Bips calldata) external;

    function setAmounts(Amounts calldata) external;

    function initialize(address owner) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@dex/lib/LeverageMath.sol';
import '@dex/perp/interfaces/IVault.sol';
import '@dex/perp/interfaces/IPoolRatio.sol';
import '@dex/perp/interfaces/IConfig.sol';

interface IEngineEvents {
    // TODO: move out [leave only on test]
    event MatchInexistant(uint indexed matchId, uint indexed orderId);
    event MakerIsTrader(
        uint indexed matchId,
        address indexed maker,
        uint orderId
    );
    event LowMakerCollateralForFees(
        uint indexed matchId,
        address indexed maker,
        uint orderId,
        uint allocatedCollateral,
        uint makerFees
    );

    event LowTraderCollateral(
        uint indexed matchId,
        address indexed trader,
        uint orderId,
        uint traderCollateral,
        uint collateralNeeded
    );
    event LowTraderCollateralForFees(
        uint indexed matchId,
        address indexed trader,
        uint orderId,
        uint allocatedCollateral,
        uint traderFees
    );
    event NewMakerOrder(
        address indexed recipient,
        uint indexed matchId,
        uint tokenId
    );

    event NewTraderOrder(
        address indexed recipient,
        uint indexed matchId,
        uint orderId
    );

    event ActiveMatch(
        uint indexed matchId,
        address indexed maker,
        address indexed trader,
        uint orderId,
        uint makerToken,
        uint traderToken
    );

    event CloseMatch(
        uint indexed matchId,
        uint indexed makerToken,
        uint indexed traderToken,
        int PnLM,
        int PnLT,
        uint price
    );

    event MatchLiquidated(uint indexed matchId, int pnlM, int pnlT, uint price);

    event LowMakerCollateral(
        uint indexed matchId,
        address indexed maker,
        uint orderId,
        uint makerCollateral,
        uint collateralNeeded
    );

    event OrderExpired(
        uint indexed matchId,
        address indexed trader,
        address indexed maker,
        uint orderId,
        uint orderTimestamp
    );

    event OrderCanceled(
        address indexed trader,
        uint indexed orderId,
        uint indexed matchId
    );

    event MatchCanceled(address indexed maker, uint indexed matchId);
    event MatchClose(address indexed maker, uint indexed matchId);

    event CollateralIncreased(
        address indexed sender,
        uint matchId,
        uint amount
    );

    event CollateralDecreased(
        address indexed sender,
        uint matchId,
        uint amount
    );

    event MaxOpeningLeverage(
        address indexed user,
        uint matchId,
        uint orderId,
        uint price
    );

    event MatchAlreadyActive(
        uint indexed matchId,
        uint indexed orderId,
        address indexed trader
    );

    event MatchSplitted(
        uint indexed newMatchId,
        uint indexed matchId,
        uint tokenId
    );
}

interface IEngine {
    function initialize(
        address oracle_,
        IVault vault_,
        IPoolRatio pool_,
        IConfig config_
    ) external;

    function getMatch(uint matchId) external view returns (Match memory);

    function liquidate(
        uint[] calldata matchIds,
        uint[] calldata tokenIds,
        address recipient
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IPool {
    struct Config {
        uint24 wfeeBps;
        uint door;
        uint hold;
        uint cap;
    }

    event Deposited(
        address indexed user,
        address indexed collateralToken,
        uint pay
    );

    event Withdrew(
        address indexed user,
        address indexed collateralToken,
        uint pay,
        uint per,
        uint fee
    );

    event Accumulate(int amount);

    function addMarket() external;

    function totalShares() external view returns (uint);

    function stake(uint amount, address recipient) external;

    function cancelStake() external;

    function unstake(uint amount, address recipient) external;

    function capLimit() external view returns (uint);
}

pragma solidity ^0.8.17;

interface IPoolRatio {
    // @dev accumulated rewards snapshot at lock are used
    // to avoid rewards aggregating while a withdraw is pending
    struct Withdrawal {
        uint timestamp; // timestamp the last time a user attempted a withdraw
        uint amount; // Promised withdraw amount on hold during the door period
        uint sharesAtLock; // accumulated shares when locking
    }

    struct Config {
        uint24 wfeeBps;
        uint door;
        uint hold;
        uint cap;
    }

    function capLimit() external view returns (uint);

    function addMarket() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import '@dex/perp/interfaces/IPool.sol';

interface IVault is IERC721 {
    struct LiquidationConfig {
        uint fixLiquidationFee;
        uint24 liquidationFeeBps;
        int24 splitRatio; // [bps] remaining collateral split between protocol and liquidator
    }

    function token() external view returns (IERC20Metadata);

    function collateral(address) external view returns (uint);

    function mint(address to) external returns (uint);

    function lock(uint amount, address account) external;

    function unlock(uint amount, address account) external;

    function deposit(uint amount, address recipient) external;

    function withdraw(uint amount, address recipient) external;

    function adjust(uint colT, int pnlT, address recipient) external;

    function settle(uint token, uint colT, int pnl) external;
}

interface IVaultAndPool is IVault, IPool {}