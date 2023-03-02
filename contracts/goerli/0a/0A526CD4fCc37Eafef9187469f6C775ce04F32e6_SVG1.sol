// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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
pragma solidity ^0.8.9;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import "@openzeppelin/contracts/utils/Base64.sol";
import "../interfaces/ITreasury.sol";
import "../libraries/Encoding.sol";
import "../interfaces/IArt.sol";

contract SVG1 is EArt {
    using Strings for uint;
    using Strings for uint8;
    using Strings for uint64;

    ITreasury private _treasury;

    function treasury() external view returns (ITreasury) {
        return _treasury;
    }

    function tokenImage(Art memory painting) external pure returns (string memory) {
        return string(_encodeSVG(painting));
    }

    function tokenImageURI(Art memory painting) external pure returns (string memory) {
       return string(_encodeSVGURI(painting));
    }

    function tokenData(
        Art memory painting,
        Note memory note
    ) external view returns (string memory) {
        return string(_encodeData(painting, note));
    }

    function tokenDataURI(
        Art memory painting,
        Note memory note
    ) external view returns (string memory) {
        return string(
             abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(_encodeData(painting, note))
            )
        );
    }

    function _encodeData(
        Art memory painting,
        Note memory note
    ) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            '{"id":', painting.id.toString(),
            _encodeArt1(painting),
            _encodeArt2(painting),
            _encodeNote1(note),
            _encodeNote2(note),
            _encodeImage(painting),
            '"}'
        );
    }

    function _encodeNote1(Note memory note) internal virtual view returns (bytes memory) {
        return abi.encodePacked(
            ',"artId":', note.artId.toString(),
            ',"duration":', note.duration.toString(),
            ',"createdAt":', note.createdAt.toString(),
            ',"burnedAt":', note.burnedAt.toString()
        );
    }

    function _encodeNote2(Note memory note) internal virtual view returns (bytes memory) {
        address delegate = _treasury.delegateOf(note.id);
        uint released = _treasury.released(note.id);
        uint commission = _treasury.commission(note.id);
        uint claim = _treasury.claimed(note.id);

        return abi.encodePacked(
            ',"delegate":', Encoding.encodeAddress(delegate),
            ',"released":', Encoding.encodeDecimals(released),
            ',"commission":', Encoding.encodeDecimals(commission),
            ',"claim":', Encoding.encodeDecimals(claim),
            ',"amount":', Encoding.encodeDecimals(note.amount)
        );
    }

    function _encodeImage(Art memory painting) internal virtual pure returns (bytes memory) {
        if (painting.shapes.length > 0) {
            return abi.encodePacked(
                ',"shapes":[', _encodeShapes(painting),
                '],"image":"', _encodeSVGURI(painting)
            );
        }

        return abi.encodePacked(
            ',"image":"', painting.imageUrl
        );
    }

    function _encodeArt1(Art memory painting) internal pure returns (bytes memory) {
        return abi.encodePacked(
            ',"name":"', painting.name,
            '","symbol":"', painting.symbol,
            '","script":"', painting.script,
            '","dataUrl":"', painting.dataUrl,
            '","imageUrl":"', painting.imageUrl
        );
    }

    function _encodeArt2(Art memory painting) internal pure returns (bytes memory) {
        return abi.encodePacked(
            '","color1":"', Encoding.encodeColor(painting.color1),
            '","color2":"', Encoding.encodeColor(painting.color2),
            '","updatedAt":', painting.createdAt.toString(),
            ',"createdAt":', painting.createdAt.toString()
        );
    }

    function _encodeSVGURI(Art memory painting) internal virtual pure returns (bytes memory) {
        return abi.encodePacked(
            'data:image/svg+xml;base64,',
            Base64.encode(_encodeSVG(painting))
        );
    }

    function _encodeSVG(Art memory painting) internal pure returns (bytes memory) {
        return abi.encodePacked(
            '<svg width="512" height="512" viewBox="0 0 255 255" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
            string(_encodeSVGShapes(painting)),
            '</svg>'
        );
    }

    function _encodeShapes(Art memory painting) internal pure returns (bytes memory) {
        bytes memory out;
        uint l = painting.shapes.length;

        for (uint i = 0; i < l - 1; i += 1) {
            out = abi.encodePacked(out, painting.shapes[i].toString(), ",");
        }

        return abi.encodePacked(out, painting.shapes[l - 1].toString());
    }

    function _encodeSVGShapes(Art memory painting) internal pure returns (bytes memory) {
        bytes memory out;
        uint l = painting.shapes.length;

        for (uint i = 0; i < l; i += 1) {
            out = abi.encodePacked(out, _encodeSVGShape(painting.shapes[i]));
        }

        return out;
    }

    function _encodeSVGShape(uint64 part) internal pure returns (bytes memory) {
        uint8 t = uint8(part >> 56);

        if (t == 0) {
            return _encodeSVGRect(part);
        } if (t == 1) {
            return _encodeSVGEllipse(part);
        }

        return _encodeSVGLine(part, t - 1);
    }

    function _encodeSVGLine(uint64 part, uint8 thickness) internal pure returns (bytes memory) {
        uint8 x1 = uint8(part >> 48);
        uint8 y1 = uint8(part >> 40);
        uint8 x2 = uint8(part >> 32);
        uint8 y2 = uint8(part >> 24);

        return abi.encodePacked(
            '<line x1="', x1.toString(),
            '" y1="', y1.toString(),
            '" x2="', x2.toString(),
            '" y2="', y2.toString(),
            '" stroke="', _encodeSVGColor(part),
            '" stroke-width="', thickness.toString(),
            '" stroke-linecap="round"/>'
        );
    }

    function _encodeSVGEllipse(uint64 part) internal pure returns (bytes memory) {
        uint8 cx = uint8(part >> 48);
        uint8 cy = uint8(part >> 40);
        uint8 rx = uint8(part >> 32);
        uint8 ry = uint8(part >> 24);

        return abi.encodePacked(
            '<ellipse cx="', cx.toString(),
            '" cy="', cy.toString(),
            '" rx="', rx.toString(),
            '" ry="', ry.toString(),
            '" fill="', _encodeSVGColor(part),
            '"/>'
        );
    }

    function _encodeSVGRect(uint64 part) internal pure returns (bytes memory) {
        uint8 w = uint8(part >> 48);
        uint8 h = uint8(part >> 40);
        uint8 x = uint8(part >> 32);
        uint8 y = uint8(part >> 24);

        return abi.encodePacked(
            '<rect width="', w.toString(),
            '" height="', h.toString(),
            '" x="', x.toString(),
            '" y="', y.toString(),
            '" fill="', _encodeSVGColor(part),
            '"/>'
        );
    }

    function _encodeSVGColor(uint64 part) internal pure returns (bytes memory) {
        uint8 r = uint8(part >> 16);
        uint8 g = uint8(part >> 8);
        uint8 b = uint8(part);

        return abi.encodePacked(
            'rgb(',
                r.toString(), ',',
                g.toString(), ',',
                b.toString(),
            ')'
        );
    }

    constructor(ITreasury treasury_) {
        _treasury = treasury_;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "../interfaces/IData.sol";
import "./ITreasury.sol";

interface EArt {
    function tokenData(Art memory painting, Note memory note) external view returns (string memory);
    function tokenDataURI(Art memory painting, Note memory note) external view returns (string memory);
    function tokenImage(Art memory painting) external view returns (string memory);
    function tokenImageURI(Art memory painting) external view returns (string memory);
}

struct ArtParams {
    string name;
    string symbol;
    string script;
    string dataUrl;
    string imageUrl;
    EArt encoder;
    uint64[] shapes;
    uint32 color1;
    uint32 color2;
}

struct Art {
    uint id;
    string name;
    string symbol;
    string script;
    string dataUrl;
    string imageUrl;
    EArt encoder;
    uint64[] shapes;
    uint32 color1;
    uint32 color2;
    uint createdAt;
    uint updatedAt;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IData {
    function nameOf(uint tokenId) external view returns (string memory);
    function symbolOf(uint tokenId) external view returns (string memory);
    function tokenData(uint tokenId) external view returns (string memory);
    function tokenImage(uint tokenId) external view returns (string memory);
    function tokenImageURI(uint tokenId) external view returns (string memory);
    function tokenDataURI(uint tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IArt.sol";
import "./IData.sol";

struct Note {
    uint id;
    IData art;
    uint artId;
    uint amount;
    uint duration;
    uint createdAt;
    uint burnedAt;
}

struct NoteParams {
    address from;
    address to;
    uint amount;
    uint duration;
    address delegate;
}

interface ITreasury is IData, IERC721 {
    event Print(
        uint indexed tokenId,
        address indexed from,
        address indexed to,
        string name,
        string symbol,
        string script,
        string dataUrl,
        string imageUrl,
        EArt encoder,
        uint64[] shapes,
        uint32 color1,
        uint32 color2,
        uint timestamp
    );

    event Update(
        uint indexed tokenId,
        address indexed from,
        string name,
        string symbol,
        string script,
        string dataUrl,
        string imageUrl,
        EArt encoder,
        uint64[] shapes,
        uint32 color1,
        uint32 color2,
        uint timestamp
    );

    event Stake(
        uint indexed tokenId,
        address indexed from,
        address indexed to,
        address delegate,
        uint principal,
        uint duration,
        uint amount,
        uint value,
        uint artId,
        uint timestamp
    );

    event Delegate(
        uint indexed tokenId,
        address indexed from,
        address indexed to,
        uint timestamp
    );

    event Claim(
        uint indexed tokenId,
        address indexed from,
        address indexed to,
        uint amount,
        uint timestamp
    );

    event Withdraw(
        uint indexed tokenId,
        address indexed from,
        address indexed to,
        uint amount,
        uint timestamp
    );

    event Burn(
        uint indexed tokenId,
        address indexed from,
        address indexed interestTo,
        address principalTo,
        uint principal,
        uint interest,
        uint penalty,
        uint timestamp
    );

    event Capture(
        uint indexed tokenId,
        address indexed from,
        uint amount,
        uint timestamp
    );

    function nameOf(uint tokenId) external view returns (string memory);
    function symbolOf(uint tokenId) external view returns (string memory);
    function delegateOf(uint tokenId) external view returns (address);
    function getArt(uint tokenId) external view returns (Art memory);
    function getNote(uint tokenId) external view returns (Note memory);
    function getImage(uint tokenId) external view returns (Art memory);

    function released(uint tokenId) external view returns (uint);
    function claimed(uint tokenId) external view returns (uint);
    function captured(uint tokenId) external view returns (uint);
    function commission(uint tokenId) external view returns (uint);

    function tokenCount() external view returns (uint);
    function tokenImage(uint tokenId) external view returns (string memory);
    function tokenImageURI(uint tokenId) external view returns (string memory);
    function tokenData(uint tokenId) external view returns (string memory);
    function tokenDataURI(uint tokenId) external view returns (string memory);

    function calculateInterest(uint amount, uint duration, uint time) external pure returns (uint);
    function calculatePenalty(uint amount, uint duration, uint time) external pure returns (uint);
    function calculateUnstakeWindow(uint duration) external pure returns (uint);
    function calculateCurve(uint amount, uint duration, uint time) external pure returns (uint);

    function print(ArtParams memory art, NoteParams memory params) external payable returns (uint);
    function update(uint256 tokenId, ArtParams calldata params) external returns (uint);
    function stake(uint artId, NoteParams memory params) external payable returns (uint);
    function delegate(address to, uint256 tokenId) external;
    function claim(address to, uint tokenId, uint amount) external;
    function withdraw(address to, uint tokenId, uint amount) external;
    function burn(address interestTo, address principalTo, uint tokenId) external payable;
    function capture(uint[] memory tokenIds) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';

library Encoding {
    using Strings for uint;

    function encodeDecimals(uint num) internal pure returns (bytes memory) {
        bytes memory decimals = bytes((num % 1e18).toString());
        uint length = decimals.length;

        for (uint i = length; i < 18; i += 1) {
            decimals = abi.encodePacked('0', decimals);
        }

        return abi.encodePacked(
            (num / 1e18).toString(),
            '.',
            decimals
        );
    }

    function encodeAddress(address addr) internal pure returns (bytes memory) {
        if (addr == address(0)) {
            return 'null';
        }

        return abi.encodePacked(
            '"', uint(uint160(addr)).toHexString(), '"'
        );
    }

    function encodeColorValue(uint8 colorValue) internal pure returns (bytes memory) {
        bytes memory hexValue = new bytes(2);
        bytes memory hexChars = "0123456789abcdef";
        hexValue[0] = hexChars[colorValue / 16];
        hexValue[1] = hexChars[colorValue % 16];
        return hexValue;
    }

    function encodeColor(uint color) internal pure returns (bytes memory) {
        uint8 r = uint8(color >> 24);
        uint8 g = uint8(color >> 16);
        uint8 b = uint8(color >> 8);
        // uint8 a = uint8(color);

        return abi.encodePacked(
            '#',
             encodeColorValue(r),
             encodeColorValue(g),
             encodeColorValue(b)
        );
    }

    function encodeUintArray(uint[] memory arr) internal pure returns (string memory) {
        bytes memory values;
        uint total = arr.length;

        for (uint i = 0; i < total; i += 1) {
            uint v = arr[i];
            if (i == total - 1) {
                values = abi.encodePacked(values, v.toString());
            } else {
                values = abi.encodePacked(values, v.toString(), ',');
            }
        }

        return string(abi.encodePacked('[', values ,']'));
    }

    function encodeDecimalArray(uint[] memory arr) internal pure returns (string memory) {
        bytes memory values;
        uint total = arr.length;

        for (uint i = 0; i < total; i += 1) {
            uint v = arr[i];
            if (i == total - 1) {
                values = abi.encodePacked(values, encodeDecimals(v));
            } else {
                values = abi.encodePacked(values, encodeDecimals(v), ',');
            }
        }

        return string(abi.encodePacked('[', values ,']'));
    }
}