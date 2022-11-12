// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Receiver.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import 'lib/openzeppelin-contracts/contracts/utils/Strings.sol';
import 'lib/openzeppelin-contracts/contracts/interfaces/IERC721Metadata.sol';
import 'lib/openzeppelin-contracts/contracts/interfaces/IERC721Receiver.sol';

abstract contract ERC721 is IERC721Metadata {
    using Strings for uint256;

    error IsZeroAddress();
    error IsInvalidNft();
    error Unauthorized();
    error SelfTarget();
    error NonERC721Receiver();

    string private _baseURI;
    string private _name;
    string private _symbol;

    // token id -> owner
    mapping(uint256 => address) private _owners;
    // owner -> amount of tokens
    mapping(address => uint256) private _balances;
    // owner -> operator -> authorized
    mapping(address => mapping(address => bool)) private _operators;
    // token id -> approved
    mapping(uint256 => address) private _approvals;

    constructor(
        string memory nftName,
        string memory nftSymbol,
        string memory baseURI
    ) {
        _name = nftName;
        _symbol = nftSymbol;
        _baseURI = baseURI;
    }

    /* ---------- EXTERNAL ----------  */

    /** @notice Query if a contract implements an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function uses less than 30,000 gas.
     *
     * @return bool `true` if the contract implements `interfaceId` and `interfaceId` is not 0xffffffff, `false` otherwise
     */
    function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
        return interfaceId == type(IERC721Metadata).interfaceId || interfaceId == type(IERC721).interfaceId;
    }

    /**
     * @notice A descriptive name for a collection of NFTs in this contract
     */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @notice An abbreviated name for NFTs in this contract
     */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
     * 3986. The URI may point to a JSON file that conforms to the "ERC721 Metadata JSON Schema".
     * @param tokenId The identifier for an NFT
     */
    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        _assertIsValidNft(tokenId);

        return string(abi.encodePacked(_baseURI, tokenId.toString()));
    }

    /**
     * @notice Count all NFTs assigned to an owner
     * @dev NFTs assigned to the zero address are considered invalid, and this
     * function throws for queries about the zero address.
     *
     * @param owner An address for whom to query the balance
     *
     * @return uint256 number of NFTs owned by `_owner`, possibly zero
     */
    function balanceOf(address owner) external view override returns (uint256) {
        _assertIsNotZeroAddress(owner);

        return _balances[owner];
    }

    /**
     * @notice Find the owner of an NFT
     * @dev NFTs assigned to zero address are considered invalid, and queries about them do throw.
     *
     * @param tokenId The identifier for an NFT
     *
     * @return address address of the owner of the NFT
     */
    function ownerOf(uint256 tokenId) external view override returns (address) {
        _assertIsValidNft(tokenId);

        return _owners[tokenId];
    }

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     * operator, or the approved address for this NFT. Throws if `from` is
     * not the current owner. Throws if `to` is the zero address. Throws if
     * `tokenId` is not a valid NFT. When transfer is complete, this function
     * checks if `to` is a smart contract (code size > 0). If so, it calls
     * `onERC721Received` on `to` and throws if the return value is not
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
     *
     * @param from The current owner of the NFT
     * @param to The new owner
     * @param tokenId The NFT to transfer
     * @param data Additional data with no specified format, sent in call to `to`
     **/
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external override {
        _assertIsValidNft(tokenId);
        _assertIsNotZeroAddress(to);
        _assertIsTheOwner(from, tokenId);
        _assertItCanTransfer(tokenId);

        _transfer(from, to, tokenId);

        if (!_isContract(to)) {
            return;
        }

        _assertIsERC721Receiver(to, from, tokenId, data);
    }

    /**
     * @notice Transfers the ownership of an NFT from one address to another address
     * @dev This works identically to the other function with an extra data parameter except
     * this function just sets data to "".
     *
     * @param from The current owner of the NFT
     * @param to The new owner
     * @param tokenId The NFT to transfer
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        _assertIsValidNft(tokenId);
        _assertIsNotZeroAddress(to);
        _assertIsTheOwner(from, tokenId);
        _assertItCanTransfer(tokenId);

        _transfer(from, to, tokenId);

        if (!_isContract(to)) {
            return;
        }

        _assertIsERC721Receiver(to, from, tokenId, '');
    }

    /**
     * @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
     * TO CONFIRM THAT `to` IS CAPABLE OF RECEIVING NFTS OR ELSE THEY MAY BE PERMANENTLY LOST
     * @dev Throws unless `msg.sender` is the current owner, an authorized
     * operator, or the approved address for this NFT. Throws if `from` is
     * not the current owner. Throws if `to` is the zero address. Throws if `tokenId` is not a valid NFT.
     *
     * @param from The current owner of the NFT
     * @param to The new owner
     * @param tokenId The NFT to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external override {
        _assertIsValidNft(tokenId);
        _assertIsNotZeroAddress(to);
        _assertIsTheOwner(from, tokenId);
        _assertItCanTransfer(tokenId);

        _transfer(from, to, tokenId);
    }

    /**
     * @notice Change or reaffirm the approved address for an NFT.
     * @dev The zero address indicates there is no approved address.
     * Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
     *
     * @param approved The new approved NFT controller
     * @param tokenId The NFT to approve
     */
    function approve(address approved, uint256 tokenId) external override {
        _assertItCanApprove(tokenId);
        _assertIsNotSelf(approved);

        _approvals[tokenId] = approved;

        emit Approval(_owners[tokenId], approved, tokenId);
    }

    /**
     * @notice Enable or disable approval for a third party ("operator") to manage all of `msg.sender`'s assets
     * @dev Emits the ApprovalForAll event. The contract MUST allow multiple operators per owner.
     *
     * @param operator address to add to the set of authorized operators
     * @param approved true if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address operator, bool approved) external override {
        _assertIsAnOwner();
        _assertIsNotSelf(operator);
        _assertIsNotZeroAddress(operator);

        _operators[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @notice Get the approved address for a single NFT
     * @dev Throws if `tokenId` is not a valid NFT.
     *
     * @param tokenId The NFT to find the approved address for
     *
     * @return address approved address for this NFT, or the zero address if there is none
     */
    function getApproved(uint256 tokenId) external view override returns (address) {
        _assertIsValidNft(tokenId);

        return _approvals[tokenId];
    }

    /**
     * @notice Query if an address is an authorized operator for another address
     *
     * @param owner The address that owns the NFTs
     * @param operator The address that acts on behalf of the owner
     *
     * @return bool true if `operator` is an approved operator for `owner`, false otherwise
     */
    function isApprovedForAll(address owner, address operator) external view override returns (bool) {
        return _operators[owner][operator];
    }

    /* ---------- INTERNAL ---------- */

    /**
     * @notice Safely mint a new nft
     * @dev Throws unless `to` is not the zero address and if being a contract, it does implement ERC721Receiver
     *
     * @param to address that will receive the nft
     * @param tokenId The id of the nft
     */
    function _safeMint(address to, uint256 tokenId) internal {
        _mint(to, tokenId);

        if (!_isContract(to)) {
            return;
        }

        _assertIsERC721Receiver(to, address(0), tokenId, '');
    }

    /**
     * @notice Burn `tokenId`
     * @dev The approval is cleared when the token is burned. Throws if `tokenId` is not a valid NFT
     * or if `msg.sender` is not the current owner
     *
     * @param tokenId The id of the nft
     */
    function _burn(uint256 tokenId) internal {
        _assertIsValidNft(tokenId);
        _assertIsTheOwner(msg.sender, tokenId);

        delete _approvals[tokenId];
        delete _owners[tokenId];
        unchecked {
            --_balances[msg.sender];
        }

        emit Transfer(msg.sender, address(0), tokenId);
    }

    /**
     * @notice Check if an address is the zero address
     * @dev Throws unless `target` is not the zero address
     *
     * @param target The address to verify
     */
    function _assertIsNotZeroAddress(address target) internal pure {
        if (target != address(0)) {
            return;
        }

        revert IsZeroAddress();
    }

    /* ---------- PRIVATE ---------- */

    /**
     * @notice Check if a contract implements `onERC721Received`
     * @dev Throws unless `to` implements `onERC721Received`
     *
     * @param to The address of the contract
     * @param previousOwner The address of previous owner
     * @param tokenId The NFT to transfer
     * @param data The calldata
     */
    function _assertIsERC721Receiver(
        address to,
        address previousOwner,
        uint256 tokenId,
        bytes memory data
    ) private {
        (, bytes memory result) = to.call(
            abi.encodeWithSelector(IERC721Receiver.onERC721Received.selector, msg.sender, previousOwner, tokenId, data)
        );

        if (bytes4(result) == IERC721Receiver.onERC721Received.selector) {
            return;
        }

        revert NonERC721Receiver();
    }

    /**
     * @notice Mint a new nft
     * @dev Throws if `to` is the zero address.
     *
     * @param to address that will receive the nft
     * @param tokenId The id of the nft
     */
    function _mint(address to, uint256 tokenId) private {
        _assertIsNotZeroAddress(to);

        _owners[tokenId] = to;
        unchecked {
            ++_balances[to];
        }

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @notice Check if a given address is a contract
     *
     * @param target The address to verify
     *
     * @return bool true if `target` is a contract, false otherwise
     */
    function _isContract(address target) private view returns (bool) {
        return target.code.length > 0;
    }

    /**
     * @notice Transfer ownership of `tokenId` to `to` address
     *
     * @param from The current owner of the NFT
     * @param to The new owner
     * @param tokenId The NFT to transfer
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        delete _approvals[tokenId];
        _owners[tokenId] = to;
        unchecked {
            --_balances[from];
            ++_balances[to];
        }

        emit Transfer(from, to, tokenId);
    }

    /* ---------- PRIVATE - ASSERTIONS ---------- */

    /**
     * @notice Check if a NFT is valid
     * @dev Throws unless `tokenId` exists
     *
     * @param tokenId The NFT id to verify
     */
    function _assertIsValidNft(uint256 tokenId) private view {
        if (_owners[tokenId] != address(0)) {
            return;
        }

        revert IsInvalidNft();
    }

    /**
     * @notice Check if a `msg.sender` is a holder of NFT
     * @dev Throws unless `msg.sender` is a holder
     */
    function _assertIsAnOwner() private view {
        if (_balances[msg.sender] > 0) {
            return;
        }

        revert Unauthorized();
    }

    /**
     * @notice Check if `msg.sender` can approve a certain NFT
     * @dev Throws unless `msg.sender` is the NFT owner or a valid operator
     *
     * @param tokenId The NFT id to verify
     */
    function _assertItCanApprove(uint256 tokenId) private view {
        address owner = _owners[tokenId];

        if (msg.sender == owner || _operators[owner][msg.sender]) {
            return;
        }

        revert Unauthorized();
    }

    /**
     * @notice Check if `msg.sender` can transfer a certain NFT
     * @dev Throws unless `msg.sender` is the NFT owner, a valid operator or an approved address
     *
     * @param tokenId The NFT id to verify
     */
    function _assertItCanTransfer(uint256 tokenId) private view {
        address owner = _owners[tokenId];

        if (msg.sender == owner || _operators[owner][msg.sender] || msg.sender == _approvals[tokenId]) {
            return;
        }

        revert Unauthorized();
    }

    /**
     * @notice Check if `target` is the holder of a specific NFT
     * @dev Throws unless `target` is the NFT owner of `tokenId` and `target` is not the zero address
     *
     * @param target The address to verify
     * @param tokenId The NFT id to verify
     */
    function _assertIsTheOwner(address target, uint256 tokenId) private view {
        if (target != address(0) && _owners[tokenId] == target) {
            return;
        }

        revert Unauthorized();
    }

    /**
     * @notice Check if `target` is not the `msg.sender`
     * @dev Throws unless `target` is not the `msg.sender`
     *
     * @param target The address to verify
     */
    function _assertIsNotSelf(address target) private view {
        if (target != msg.sender) {
            return;
        }

        revert SelfTarget();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './ERC721.sol';

contract Pretty is ERC721 {
    error IncorrectPayment();
    error NoMoreSupply();

    uint8 public immutable MAX_SUPPLY;
    uint8 private tokenIdTracker;
    address payable public owner;
    uint256 private constant MINT_PRICE = 0.0001 ether;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized();
        }
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        string memory baseURI,
        uint8 maxSupply
    ) ERC721(name, symbol, baseURI) {
        owner = payable(msg.sender);
        MAX_SUPPLY = maxSupply;

        for (uint256 i; i < maxSupply; ) {
            _safeMint(msg.sender, i + 1);
            unchecked {
                ++i;
            }
        }
    }

    /* ---------- EXTERNAL ----------  */

    /**
     * @notice Withdraw contract funds.
     */
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}('');
        require(success);
    }

    /**
     * @notice Transfer ownership of the contract.
     *
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) external onlyOwner {
        _assertIsNotZeroAddress(newOwner);

        owner = payable(newOwner);
    }

    /**
     * @notice Mint a Pretty NFT
     */
    function mint() external payable {
        _assertIsCorrectPayment();
        _assertItHasSupply();

        _safeMint(msg.sender, ++tokenIdTracker);
    }

    /**
     * @notice Burn `tokenId`
     *
     * @param tokenId The id of the nft
     */
    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }

    /* ---------- PRIVATE - ASSERTIONS ---------- */

    /**
     * @notice Check if payment if valid
     * @dev Throws unless `msg.value` is equal to `MINT_PRICE`
     */
    function _assertIsCorrectPayment() private view {
        if (msg.value == MINT_PRICE) {
            return;
        }

        revert IncorrectPayment();
    }

    /**
     * @notice Check if total supply has been reached
     * @dev Throws unless the next token id is not bigger than `MAX_SUPPLY`
     */
    function _assertItHasSupply() private view {
        if (tokenIdTracker + 1 <= MAX_SUPPLY) {
            return;
        }

        revert NoMoreSupply();
    }
}