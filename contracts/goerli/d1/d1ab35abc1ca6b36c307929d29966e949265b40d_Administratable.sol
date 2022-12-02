/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

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

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title ERC-721 Errors Interface
interface IERC721Errors {

    /// @notice Originating address does not own the NFT.
    error OwnerInvalid();

    /// @notice Receiving address cannot be the zero address.
    error ReceiverInvalid();

    /// @notice Receiving contract does not implement the ERC-721 wallet interface.
    error SafeTransferUnsupported();

    /// @notice Sender is not NFT owner, approved address, or owner operator.
    error SenderUnauthorized();

    /// @notice NFT supply has hit maximum capacity.
    error SupplyMaxCapacity();

    /// @notice Token has already minted.
    error TokenAlreadyMinted();

    /// @notice NFT does not exist.
    error TokenNonexistent();

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title ERC-721 Implementation
abstract contract ERC721 is IERC721, IERC721Metadata, IERC721Errors {

    /// @notice The total number of ERC-721 NFTs in circulation.
    uint256 public totalSupply;

    /// @notice Maps tokens to their owner addresses.
    mapping(uint256 => address) public ownerOf;

    /// @notice Checks for an owner if an address is an authorized operator.
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @notice Gets the approved address for an NFT.
    mapping(uint256 => address) public getApproved;

    /// @notice Gets the number of NFTs owned by an address.
    mapping(address => uint256) public balanceOf;

    /// @dev EIP-165 identifiers for all supported interfaces.
    bytes4 internal constant _ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 internal constant _ERC721_INTERFACE_ID = 0x80ac58cd;
    bytes4 internal constant _ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;

    /// @notice Gets the name associated with the ERC721 collection.
    function name() public virtual view returns(string memory);

    /// @notice Gets the symbol associated with the ERC721 collection.
    function symbol() public virtual view returns(string memory);

    /// @notice Gets the token metadata for an NFT identified by `tokenId`.
    function tokenURI(uint256 tokenId) external virtual view returns (string memory);

    /// @inheritdoc IERC721
    function setApprovalForAll(address operator, bool approved) external {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @inheritdoc IERC721
    function approve(address approved, uint256 tokenId) public virtual {
        address owner = ownerOf[tokenId];
        if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) {
            revert SenderUnauthorized();
        }
        getApproved[tokenId] = approved;
        emit Approval(owner, approved, tokenId);
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external {
        transferFrom(from, to, tokenId);
        if (
            to.code.length != 0 &&
                IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data)
                !=
                IERC721Receiver.onERC721Received.selector
        ) {
            revert SafeTransferUnsupported();
        }
    }

    /// @inheritdoc IERC721
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external {
        transferFrom(from, to, tokenId);
        if (
            to.code.length != 0 &&
                IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, "")
                !=
                IERC721Receiver.onERC721Received.selector
        ) {
            revert SafeTransferUnsupported();
        }
    }

    /// @inheritdoc IERC721
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual;

    function _isApprovedOrOwner(address account, uint256 tokenId) public view returns (bool) {
        address owner = ownerOf[tokenId];
        return (account == owner || isApprovedForAll[owner][account] || getApproved[tokenId] == account);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 id) public view virtual override(IERC165) returns (bool);

    /// @notice Mints an NFT of identifier `tokenId` to recipient address `to`.
    function _mint(address to, uint256 tokenId) internal virtual {
        if (to == address(0)) {
            revert ReceiverInvalid();
        }

        if (ownerOf[tokenId] != address(0)) {
            revert TokenAlreadyMinted();
        }

        unchecked {
            totalSupply++;
            balanceOf[to]++;
        }

        ownerOf[tokenId] = to;
        emit Transfer(address(0), to, tokenId);
    }

    /// @notice Burns an NFT with identifier `tokenId`.
    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf[tokenId];

        if (owner == address(0)) {
            revert TokenNonexistent();
        }

        unchecked {
            totalSupply--;
            balanceOf[owner]--;
        }

        delete ownerOf[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

}

// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title ERC-721 & ERC-1155 Bindable Errors Interface
interface IBindableErrors {

    /// @notice Bind already exists.
    error BindExistent();

    /// @notice Bind does not exist.
    error BindNonexistent();

    /// @notice Bind is not valid.
    error BindInvalid();

    /// @notice Bound asset or bound asset owner is not valid.
    error BinderInvalid();

}

/// @title ERC-721 Bindable Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-5700
///  Note: the ERC-165 identifier for this interface is 0x82a34a7d.
interface IERC721Bindable is IERC721, IBindableErrors {

    /// @notice The `Bind` event MUST emit when NFT ownership is delegated
    ///  through an asset and when minting an NFT bound to an existing asset.
    /// @dev When minting bound NFTs, `from` MUST be set to the zero address.
    /// @param operator The address calling the bind (SHOULD be `msg.sender`).
    /// @param from The address which owns the unbound NFT.
    /// @param to The address which owns the asset being bound to.
    /// @param tokenId The identifier of the NFT being bound.
    /// @param bindId The identifier of the asset being bound to.
    /// @param bindAddress The contract address handling asset ownership.
    event Bind(
        address indexed operator,
        address indexed from,
        address to,
        uint256 tokenId,
        uint256 bindId,
        address indexed bindAddress
    );

    /// @notice The `Unbind` event MUST emit when asset-delegated NFT ownership
    ///  is revoked, as well as when burning an NFT bound to an existing asset.
    /// @dev When burning bound NFTs, `to` MUST be set to the zero address.
    /// @param operator The address calling the unbind (SHOULD be `msg.sender`).
    /// @param from The address which owns the asset the NFT is bound to.
    /// @param to The address which will own the NFT once unbound.
    /// @param tokenId The identifier of the NFT being unbound.
    /// @param bindId The identifier of the asset being unbound from.
    /// @param bindAddress The contract address handling bound asset ownership.
    event Unbind(
        address indexed operator,
        address indexed from,
        address to,
        uint256 tokenId,
        uint256 bindId,
        address indexed bindAddress
    );

    /// @notice Delegates NFT ownership of NFT `tokenId` from address `from`
    ///  through the asset `bindId` owned by address `to`.
    /// @dev The function MUST throw unless `msg.sender` is the current owner,
    ///  an authorized operator, or the approved address for the NFT. It also
    ///  MUST throw if NFT `tokenId` is already bound, if `from` is not the NFT
    ///  owner, or if `to` is not the asset owner. After ownership delegation,
    ///  the function MUST check if `bindAddress` is a valid contract (code size
    ///  > 0), and if so, call `onERC721Bind` on the contract, throwing if the
    ///  wrong identifier is returned (see "Binding Rules") or if the contract
    ///  is invalid. On bind completion, the function MUST emit both `Bind` and
    ///  IERC-721 `Transfer` events to reflect delegated ownership change.
    /// @param from The address which owns the unbound NFT.
    /// @param to The address which owns the asset being bound to.
    /// @param tokenId The identifier of the NFT being bound.
    /// @param bindId The identifier of the asset being bound to.
    /// @param bindAddress The contract address handling asset ownership.
    /// @param data Additional data sent with the `onERC721Bind` hook.
    function bind(
        address from,
        address to,
        uint256 tokenId,
        uint256 bindId,
        address bindAddress,
        bytes calldata data
    ) external;

    /// @dev The function MUST throw unless `msg.sender` is an approved operator
    ///  or owner of the delegated asset of `tokenId`. It also MUST throw if NFT
    ///  `tokenId` is not bound, if `from` is not the asset owner, or if `to`
    ///  is the zero address. After ownership transition, the function MUST
    ///  check if `bindAddress` is a valid contract (code size > 0), and if so,
    ///  call `onERC721Unbind` the contract, throwing if the wrong identifier is
    ///  returned (see "Binding Rules") or if the contract is invalid.
    ///  The function also MUST check if `to` is a valid contract, and if so,
    ///  call `onERC721Received`, throwing if the wrong identifier is returned.
    ///  On unbind completion, the function MUST emit both `Unbind` and IERC-721
    ///  `Transfer` events to reflect delegated ownership change.
    /// @param from The address which owns the asset the NFT is bound to.
    /// @param to The address which will own the NFT once unbound.
    /// @param tokenId The identifier of the NFT being unbound.
    /// @param bindId The identifier of the asset being unbound from.
    /// @param bindAddress The contract address handling bound asset ownership.
    /// @param data Additional data sent with the `onERC721Unbind` hook.
    function unbind(
        address from,
        address to,
        uint256 tokenId,
        uint256 bindId,
        address bindAddress,
        bytes calldata data
    ) external;

    /// @notice Gets the asset identifier and address which a token is bound to.
    /// @param tokenId The identifier of the NFT being queried.
    /// @return The bound asset identifier and contract address.
    function binderOf(uint256 tokenId) external returns (address, uint256);

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title ERC-721 & ERC-1155 Binder Errors Interface
interface IBinderErrors {

    /// @notice Asset binding already exists.
    error BindExistent();

    /// @notice Asset binding is not valid.
    error BindInvalid();

    /// @notice Asset binding does not exist.
    error BindNonexistent();

}

/// @dev Note: the ERC-165 identifier for this interface is 0x2ac2d2bc.
interface IERC721Binder is IERC165, IBinderErrors {

    /// @notice Handles the binding of an IERC721Bindable-compliant NFT.
    /// @dev An IERC721Bindable-compliant smart contract MUST call this function
    ///  at the end of a `bind` after delegating ownership to the asset owner.
    ///  The function MUST revert if `to` is not the asset owner of `bindId` or
    ///  if asset `bindId` is not a valid asset. The function MUST revert if it
    ///  rejects the bind. If accepting the bind, the function MUST return
    /// `bytes4(keccak256("onERC721Bind(address,address,address,uint256,uint256,bytes)"))`
    ///  Caller MUST revert the transaction if the above value is not returned.
    ///  Note: The contract address of the binding NFT is `msg.sender`.
    /// @param operator The address responsible for initiating the bind.
    /// @param from The address which owns the unbound NFT.
    /// @param to The address which owns the asset being bound to.
    /// @param tokenId The identifier of the NFT being bound.
    /// @param bindId The identifier of the asset being bound to.
    /// @param data Additional data sent along with no specified format.
    /// @return `bytes4(keccak256("onERC721Bind(address,address,address,uint256,uint256,bytes)"))`
    function onERC721Bind(
            address operator,
            address from,
            address to,
            uint256 tokenId,
            uint256 bindId,
            bytes calldata data
    ) external returns (bytes4);

    /// @notice Handles the unbinding of an IERC721Bindable-compliant NFT.
    /// @dev An IERC721Bindable-compliant smart contract MUST call this function
    ///  at the end of an `unbind` after revoking delegated asset ownership.
    ///  The function MUST revert if `from` is not the asset owner of `bindId`
    ///  or if `bindId` is not a valid asset. The function MUST revert if it
    ///  rejects the unbind. If accepting the unbind, the function MUST return
    ///  `bytes4(keccak256("onERC721Unbind(address,address,address,uint256,uint256,bytes)"))`
    ///  Caller MUST revert the transaction if the above value is not returned.
    ///  Note: The contract address of the unbinding NFT is `msg.sender`.
    /// @param from The address which owns the asset the NFT is bound to.
    /// @param to The address which will own the NFT once unbound.
    /// @param tokenId The identifier of the NFT being unbound.
    /// @param bindId The identifier of the asset being unbound from.
    /// @param data Additional data with no specified format.
    /// @return `bytes4(keccak256("onERC721Unbind(address,address,address,uint256,uint256,bytes)"))`
    function onERC721Unbind(
            address operator,
            address from,
            address to,
            uint256 tokenId,
            uint256 bindId,
            bytes calldata data
    ) external returns (bytes4);

    /// @notice Gets the owner address of the asset represented by id `bindId`.
    /// @dev Queries for assets assigned to the zero address MUST throw.
    /// @param bindId The identifier of the asset whose owner is being queried.
    /// @return The address of the owner of the asset.
    function ownerOf(uint256 bindId) external view returns (address);

    /// @notice Checks if an operator can act on behalf of an asset owner.
    /// @param owner The address that owns an asset.
    /// @param operator The address that acts on behalf of owner `owner`.
    /// @return True if `operator` can act on behalf of `owner`, else False.
    function isApprovedForAll(address owner, address operator) external view returns (bool);

}

/// @title  ERC-721 Bindable
/// @notice An ERC-721 bindable is an ERC-721 that can delegate NFT ownership
///         ("bind") to ERC-721 binders, which are ERC-721 NFTs capable of being
///         bound to. When bound to a binder, an ERC-721 bindable's ownership
///         attribution is delegated through the binder, meaning the owner of
///         the bindable will always be the owner of the binder, and transfer
///         logs are likewise emitted to keep ownership state of the two synced.
///         A bindable is bound until the binder owner invokes an unbind. While
///         a bindable is bound and its binder is transferred, the binder must
///         ensure the bindable owner is updated to match the new binder owner.
/// @dev Note that when bound, even though ERC-721 bindables essentially act as
///      read-only registrars to mirror their binder owner state, the bound
///      owner address still must be redundantly tracked to ensure a malicious
///      binder not adhering to the ERC-721 binder standard cannot break the
///      transfer attribution logs of its bindables.
abstract contract ERC721Bindable is ERC721, IERC721Bindable {

    /// @notice Encapsulates an ERC-721 binder.
    struct Binder {
        // The contract address of the binder NFT.
        address bindAddress;
        // The identifier of the binder NFT.
        uint256 bindId;
    }

    /// @notice Maps ERC-721 bindables to ERC-721 binders they are bound to.
    /// @dev Binder mappings are added during binds, and deleted on unbinds.
    mapping(uint256 => Binder) internal _binder;

    /// @dev EIP-165 identifiers for all supported interfaces.
    bytes4 internal constant _ERC721_BINDABLE_INTERFACE_ID = 0xd92c3ff0; // TODO: Update to correct interface id.

    /// @notice Gets the binder an ERC-721 bindable is bound to.
    /// @return bindAddress The address of the binder NFT contract.
    /// @return bindId      The identifier of the binder NFT.
    function binderOf(uint256 tokenId) public view returns (address, uint256) {
        Binder memory binder = _binder[tokenId];
        return (binder.bindAddress, binder.bindId);
    }

    /// @notice Executes an ERC-721 bindable transfer. If unbound, this performs
    ///         a normal ERC-721 transfer. When bound, there are 2 common cases:
    ///         (1) Caller is the binder:
    ///             Occurs when the binder owner is transferred, and the call is
    ///             made to sync ownership of binder with its bound bindables.
    ///         (2) Caller is binder owner:
    ///             Occurs when the binder owner wishes to transfer the bindable
    ///             directly to another account, in which case an unbind occurs.
    /// @param from    Owner address of the bindable - when bound, `from` is the
    ///                owner address of the binder which `tokenId` is bound to.
    /// @param to      Address receiving the bindable - when bound and caller is
    ///                the binder, this will be the new binder owner address.
    /// @param tokenId The identifier of the bindable NFT being transferred.
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(ERC721, IERC721) {
        (address bindAddress, uint256 bindId) = binderOf(tokenId);
        // Determine transfer method based on whether bindable is bound or not.
        if (bindAddress == address(0)) {
            // If unbound, perform a regular transfer.
            _transfer(from, to, tokenId, bindAddress);
        } else {
            // Bound transfer transfers depends on whether caller is the binder.
            if (msg.sender == bindAddress) {
                // If caller is the binder, transfer without unbinding, in which
                // case we must check that the receiver is the new binder owner.
                _transfer(from, to, tokenId, bindAddress);
            } else {
                // If caller is not the binder, unbind the bindable.
                _unbind(from, to, tokenId, bindId, bindAddress);
            }
        }
    }

    /// @notice Binds an ERC-721 bindable NFT to an ERC-721 binder.
    /// @dev When the bindable is already bound, this function must throw.
    /// @param from        The owner address of the unbound NFT.
    /// @param to          The address of the ERC-721 binder owner.
    /// @param tokenId     The identifier of the bindable NFT being bound.
    /// @param bindId      The identifier of the binder being bound to.
    /// @param bindAddress The address of the binder contract.
    function bind(
        address from,
        address to,
        uint256 tokenId,
        uint256 bindId,
        address bindAddress,
        bytes calldata data
    ) public virtual {
        // If a bind already exists, throw.
        (address boundAddress, ) = binderOf(tokenId);
        if (boundAddress != address(0)) revert BindExistent();

        // If recipient is not the owner of the binder being bound to, throw.
        if (to != IERC721Binder(bindAddress).ownerOf(bindId)) {
            revert ReceiverInvalid();
        }

        // Binds involve 2 sequential steps: (1) transfer, (2) perform bind
        // 1. Transfer the bindable to binder owner and emit the Transfer event.
        _transfer(from, to, tokenId, address(0));

        // 2. Perform the binding, emit the bind event and call the bind hook.
        _binder[tokenId] = Binder(bindAddress, bindId);
        emit Bind(msg.sender, from, to, tokenId, bindId, bindAddress);

        if (
            IERC721Binder(bindAddress).onERC721Bind(
                msg.sender,
                from,
                to,
                tokenId,
                bindId,
                data
            ) != IERC721Binder.onERC721Bind.selector
        ) {
            revert BindInvalid();
        }
    }

    /// @notice Unbinds an ERC-721 bindable NFT from an ERC-721 binder.
    /// @dev When the bindable is already unbound, this function must throw.
    /// @param from        The address of the binder owner the NFT is bound to.
    /// @param to          The recipient unbound NFT owner address.
    /// @param tokenId     The identifier of the bindable NFT being unbound.
    /// @param bindId      The identifier of the binder being unbound from.
    /// @param bindAddress The address of the binder contract.
    /// @param data        Calldata to be passed to the unbind hook.
    function unbind(
        address from,
        address to,
        uint256 tokenId,
        uint256 bindId,
        address bindAddress,
        bytes calldata data
    ) public virtual {
        // If the `from` address is not the existing binder owner, throw.
        if (from != IERC721Binder(bindAddress).ownerOf(bindId)) {
            revert BinderInvalid();
        }

        // Perform the unbind.
        _unbind(from, to, tokenId, bindId, bindAddress);

        if (
            to.code.length != 0 &&
            IERC721Receiver(to).onERC721Received(
                msg.sender,
                from,
                tokenId,
                data
            ) !=
            IERC721Receiver.onERC721Received.selector
        ) {
            revert SafeTransferUnsupported();
        }
    }

    /// @notice Internal function to authorize and transfer a bindable NFT.
    /// @dev When called by a bind or unbind where the recipient is the same as
    ///      the original owner, this function is used purely for authorization.
    /// @param from        The current owner of the bindable NFT. When bound,
    ///                    this is the owner address of the bindable's binder.
    /// @param to          The transfer recipient owner address. When performing
    ///                    a bound transfer or bind, this is the binder owner.
    /// @param tokenId     The identifier of the bindable NFT being transferred.
    /// @param bindAddress If the bindable is already bound, this is the address
    ///                    of the binder contract, otherwise it is `address(0)`.
    function _transfer(
        address from,
        address to,
        uint256 tokenId,
        address bindAddress
    ) internal {
        // If `from` is not the current bound or unbound bindable owner, throw.
        if (from != ownerOf[tokenId]) revert OwnerInvalid();
        if (to == address(0)) revert ReceiverInvalid();

        // Apart from standard ERC-721 transfer checks, we also permit transfers
        // when sender is the contract address of the binder of the bindable.
        if (
            msg.sender != bindAddress &&
            msg.sender != from &&
            msg.sender != getApproved[tokenId] &&
            !isApprovedForAll[from][msg.sender]
        ) {
            revert SenderUnauthorized();
        }

        // Unset the approval on any kind of transfer.
        delete getApproved[tokenId];

        // Only change transfer state if `from` and `to` are not equal.
        if (from != to) {
            ownerOf[tokenId] = to;
            unchecked {
                balanceOf[from]--;
                balanceOf[to]++;
            }
            emit Transfer(from, to, tokenId);
        }
    }

    /// @notice Internal function for invoking an unbind of an ERC-721 bindable.
    /// @param from        The address of the binder owner the NFT is bound to.
    /// @param to          The recipient unbound NFT owner address.
    /// @param tokenId     The identifier of the bindable NFT being unbound.
    /// @param bindId      The identifier of the binder being unbound from.
    /// @param bindAddress The address of the binder contract.
    function _unbind(
        address from,
        address to,
        uint256 tokenId,
        uint256 bindId,
        address bindAddress
    ) internal {
        // Unbinds involve 2 sequential steps: (1) perform unbind, (2) transfer
        // 1. Perform the unbinding and emit the unbind event.
        delete _binder[tokenId];
        emit Unbind(msg.sender, from, to, tokenId, bindId, bindAddress);

        // 2. Transfer the unbound NFT to recipient and emit the Transfer event.
        _transfer(from, to, tokenId, bindAddress);

        // Invoke the unbind hook. Note that this is intentionally done after
        // transferring so internal state is updated prior to external calls.
        if (
            IERC721Binder(bindAddress).onERC721Unbind(
                msg.sender,
                from,
                to,
                tokenId,
                bindId,
                ""
            ) != IERC721Binder.onERC721Unbind.selector
        ) {
            revert BindInvalid();
        }
    }

    /// @notice Checks if a specific IERC-165 interface id is supported.
    /// @param id The identifier of the interface whose support is queried for.
    function supportsInterface(bytes4 id) public view virtual override(IERC165, ERC721) returns (bool);
}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title ERC-721 Bindable Permittable Errors Interface
interface IERC721BindablePermittableErrors {

    /// @notice ERC-721 permit has expired.
    error PermitExpired();

    /// @notice ERC-721 permit signature is not valid.
    error SignatureInvalid();

}

/// @title Dopamine ERC-721 Permit (EIP-4494) Interface
interface IERC721BindablePermittable is IERC721, IERC721BindablePermittableErrors {

    function permit(address relayer, uint256 tokenId, uint256 expiry, bytes memory signature) external;

    function nonces(uint256 tokenId) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title ERC-721 Permit (EIP-4494) Contract
abstract contract ERC721BindablePermittable is ERC721Bindable, IERC721BindablePermittable {

    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)");

    mapping(uint256 => uint256) public nonces;

    uint256 internal immutable _CHAIN_ID;
    bytes32 internal immutable _DOMAIN_SEPARATOR;

    constructor() {
        _CHAIN_ID = block.chainid;
        _DOMAIN_SEPARATOR = _buildDomainSeparator();
    }

    function _NAME() internal view returns (string memory) {
        return name();
    }

    function _VERSION() internal pure returns (string memory) {
        return "1.0";
    }

    function EIP712Data() external view 
        returns (
            string memory name,
            string memory version,
            address verifyingContract,
            bytes32 domainSeparator
        )
    {
        name = _NAME();
        version = _VERSION();
        verifyingContract = address(this);
        domainSeparator = _buildDomainSeparator();
    }

    function getPermitHash(address relayer, uint256 tokenId, uint256 nonce, uint256 expiry) public pure returns (bytes32) {
        return keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                relayer,
                tokenId,
                nonce,
                expiry
            )
        );
    }

    function _deriveEIP712Digest(bytes32 hash) internal view returns (bytes32) {
        return ECDSA.toTypedDataHash(DOMAIN_SEPARATOR(), hash);
    }

    function _verifySignature(bytes memory signature, bytes32 digest, uint256 tokenId) internal view {
        address signatory = ECDSA.recover(digest, signature);
        if (signatory == address(0) || !_isApprovedOrOwner(signatory, tokenId)) {
            revert SignatureInvalid();
        }
    }

    /// @dev Generates an EIP-712 domain separator.
    /// @return A 256-bit domain separator tied to this contract.
    function _buildDomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(_NAME())),
                keccak256(bytes(_VERSION())),
                block.chainid,
                address(this)
            )
        );
    }

    /// @dev Returns the domain separator tied to the contract.
    /// @return 256-bit domain separator tied to this contract.
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        if (block.chainid == _CHAIN_ID) {
            return _DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator();
        }
    }

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Bindable Events & Errors Interface
interface IERC721DopamineBindableEventsAndErrors {

    /// @notice The drop URI is now immutable and cannot be changed.
    error DropURIImmutable();

    /// @notice The function may only be called by the minter.
    error MinterOnly();

    /// @notice The provenance hash is now immutable and may not be changed.
    error ProvenanceHashImmutable();

    /// @notice The bound registrar is invalid.
    error RegistrarInvalid();

    /// @notice Emits when a new base URI is set for the collection.
    event BaseURISet(string baseURI);

    /// @notice Emits when a new contract URI is set for the collection.
    event ContractURISet(string contractURI);

    /// @notice Emits when a new drop URI is set for the collection.
    event DropURISet(string dropURI);

    /// @notice Emits when the minter is changed.
    event MinterSet(address minter);

    /// @notice Emits when the provenance hash is set for the collection.
    event ProvenanceHashSet(bytes32 provenanceHsh);

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title IERC173 Events & Errors Interface
interface IERC173EventsAndErrors {

    /// @notice Emits when ownership is transferred to another address.
    /// @param previousOwner The address of the prior owner.
    /// @param newOwner The address of the new owner.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title IERC173 Interface
interface IERC173 is IERC165, IERC173EventsAndErrors {

    /// @notice Get the owner address of the contract.
    /// @return The address of the owner.
    function owner() view external returns(address);

    /// @notice Set the new owner address of the contract.
    function transferOwnership(address newOwner) external;

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Ownable Events & Errors Interface
interface IOwnableEventsAndErrors {

    /// @notice Emits when a new pending owner is set.
    /// @param pendingOwner The address of the new pending owner.
    event PendingOwnerSet(
        address indexed pendingOwner
    );

    /// @notice Caller is not the owner of the contract.
    error OwnerOnly();

    /// @notice The pending owner is invalid.
    error PendingOwnerInvalid();

    /// @notice Caller is not the pending owner of the contract.
    error PendingOwnerOnly();

    /// @notice The pending owner is already set to the specified address.
    error PendingOwnerAlreadySet();

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Ownable Interface
interface IOwnable is IERC173, IOwnableEventsAndErrors {

    /// @notice Gets the pending owner of the contract.
    /// @return The pending owner address for the contract.
    function pendingOwner() external returns(address);

    /// @notice Sets the pending owner address for the contract.
    /// @param pendingOwner The address of the new pending owner.
    function setPendingOwner(address pendingOwner) external;

    /// @notice Permanently renounces contract ownership.
    function renounceOwnership() external;

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Administratable Events & Errors Interface
interface IAdministratableEventsAndErrors {

    /// @notice Emits when a new admin is set.
    /// @param admin The new admin address.
    event AdminSet(address indexed admin);

    /// @notice Emits when a new pending owner is set.
    /// @param pendingAdmin The address of the new pending owner.
    event PendingAdminSet(
        address indexed pendingAdmin
    );

    /// @notice Caller is not the owner of the contract.
    error AdminOnly();

    /// @notice The pending owner is invalid.
    error PendingAdminInvalid();

    /// @notice Caller is not the pending owner of the contract.
    error PendingAdminOnly();

    /// @notice The pending owner is already set to the specified address.
    error PendingAdminAlreadySet();

}

/// @title Administratable Interface
interface IAdministratable is IAdministratableEventsAndErrors {

    /// @notice Get the admin address of the contract.
    /// @return The address of the admin.
    function admin() view external returns(address);

    /// @notice Set the new admin address of the contract.
    function transferAdmin(address newAdmin) external;

    /// @notice Gets the pending admin of the contract.
    /// @return The pending admin address for the contract.
    function pendingAdmin() external returns(address);

    /// @notice Sets the pending admin address for the contract.
    /// @param pendingAdmin The address of the new pending admin.
    function setPendingAdmin(address pendingAdmin) external;

    /// @notice Permanently renounces contract adminship.
    function renounceAdmin() external;

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */


////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @notice A Dopamine resolver
    struct ResolverParameters {
        bytes32 chip;
        address chipOwner;
        bytes hash;
        address registrant;
    }

/// @title ERC-2981 Errors Interface
interface IERC2981Errors {

    /// @notice Royalties are set too high.
    error RoyaltiesTooHigh();

}

/// @title Interface for the ERC-2981 royalties standard.
interface IERC2981 is IERC2981Errors, IERC165 {

    /// @notice Returns the address to which royalties are received along with
    ///  the royalties amount to be paid to them for a given sale price.
    /// @param id The id of the NFT being queried for royalties information.
    /// @param salePrice The sale price of the NFT, in some unit of exchange.
    /// @return receiver The address of the royalties receiver.
    /// @return royaltyAmount The royalty payment to be made given `salePrice`.
    function royaltyInfo(
        uint256 id,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);

}

/// @title Dopamine Bindable Events & Errors Interface
interface IERC721DopamineBindable is IERC721Bindable, IOwnable, IAdministratable, IERC2981, IERC721DopamineBindableEventsAndErrors {

    /// @notice Mints and binds an ERC-721 bindable to a binder in one go.
    function mint(address to, uint256 bindId, address bindAddress) external returns (uint256);

    /// @notice Sets the provenance hash for the NFT collection.
    /// @param newProvenanceHash The new provenance hash to set.
    function setProvenanceHash(bytes32 newProvenanceHash) external;

    /// @notice Sets the contract URI for the NFT collection.
    /// @param newContractURI The new contract metadata URI to set.
    function setContractURI(string memory newContractURI) external;

    /// @notice Sets the base URI for the NFT collection.
    /// @param newBaseURI The new base URI to set.
    function setBaseURI(string memory newBaseURI) external;

    /// @notice Sets the drop URI for the NFT collection.
    /// @param newDropURI The new drop URI to set.
    function setDropURI(string memory newDropURI) external;

    /// @notice Sets the royalty information for all NFTs in the collection.
    /// @param receiver Address which will receive token royalties.
    /// @param royalties Royalties amount, in bips.
    function setRoyalties(address receiver, uint96 royalties) external;

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title String Utility Library
library StringUtil {

	/// @dev Converts a uint256 into a string.
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

struct ERC721Token {
    address token;
    uint256 id;
}

struct ERC1155Token {
    address token;
    uint256 id;
    uint256 amount;
}

/// @notice RoyaltiesInfo stores token royalties information.
struct RoyaltiesInfo {

    // The address to which royalties will be directed.
    address receiver;

    // The royalties amount, in bips.
    uint96 royalties;

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Ownable Contract
abstract contract Ownable is IOwnable {

    /// @notice Used for permanently revoking ownership.
    address public constant REVOKE_OWNER_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    address public owner;
    address public pendingOwner;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert OwnerOnly();
        }
        _;
    }

    modifier onlyPendingOwner() {
        if (msg.sender != pendingOwner) {
            revert PendingOwnerOnly();
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setPendingOwner(address newPendingOwner) public onlyOwner {
        if (pendingOwner == newPendingOwner) {
            revert PendingOwnerAlreadySet();
        }
        pendingOwner = newPendingOwner;
        emit PendingOwnerSet(newPendingOwner);
    }

    function renounceOwnership() public onlyOwner {
        if (pendingOwner != REVOKE_OWNER_ADDRESS) {
            revert PendingOwnerInvalid();
        }
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public onlyPendingOwner {
        if (pendingOwner != newOwner) {
            revert PendingOwnerInvalid();
        }
        _transferOwnership(newOwner);
    }

    function supportsInterface(bytes4 id) public view virtual returns (bool);

    /// @notice Transfers ownership to address `newOwner`.
    function _transferOwnership(address newOwner) internal {
        address oldOwner = owner;
        pendingOwner = address(0);
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Ownable Administratable Events & Errors Interface
interface IOwnableAdministratableErrors {

    /// @notice Caller is not the owner or admin of the contract.
    error OwnerOrAdminOnly();

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Administratable Contract
contract Administratable is IAdministratable {

    /// @notice Used for permanently revoking the admin address.
    address public constant REVOKE_ADMIN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    address public admin;
    address public pendingAdmin;

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert AdminOnly();
        }
        _;
    }

    modifier onlyPendingAdmin() {
        if (msg.sender != pendingAdmin) {
            revert PendingAdminOnly();
        }
        _;
    }

    constructor(address admin_) {
        admin = admin_;
        emit AdminSet(admin);
    }

    function setPendingAdmin(address newPendingAdmin) public onlyAdmin {
        if (pendingAdmin == newPendingAdmin) {
            revert PendingAdminAlreadySet();
        }
        pendingAdmin = newPendingAdmin;
        emit PendingAdminSet(newPendingAdmin);
    }

    function renounceAdmin() public onlyAdmin {
        if (pendingAdmin != REVOKE_ADMIN_ADDRESS) {
            revert PendingAdminInvalid();
        }
        _transferAdmin(address(0));
    }

    function transferAdmin(address newAdmin) public onlyPendingAdmin {
        if (pendingAdmin != newAdmin) {
            revert PendingAdminInvalid();
        }
        _transferAdmin(newAdmin);
    }

    /// @notice Transfers admin to address `newAdmin`.
    function _transferAdmin(address newAdmin) internal {
        pendingAdmin = address(0);
        admin = newAdmin;
        emit AdminSet(admin);
    }

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Contract that supports Ownable and Administratable functions
abstract contract OwnableAdministratable is Ownable, Administratable, IOwnableAdministratableErrors {

    modifier onlyOwnerOrAdmin() {
        if (msg.sender != owner && msg.sender != admin) {
            revert OwnerOrAdminOnly();
        }
        _;
    }

    constructor(address admin) Administratable(admin) {}

}

/// @title  ERC-721 Dopamine Bindable Contract
/// @notice ERC-721 bindable contract with metadata and administrative support.
abstract contract ERC721DopamineBindable is OwnableAdministratable, ERC721BindablePermittable, IERC721DopamineBindable {

    using StringUtil for uint256;

    /// @notice Max number of bindable NFTs that can exist in the collection.
    uint256 public immutable maxSupply;

    /// @notice The address that is eligible for minting the collection.
    address public minter;

    /// @notice The contract URI used for querying collection-wide metadata.
    string public contractURI;

    /// @notice The base URI NFTs initially point to for metadata resolution.
    string public baseURI;

    /// @notice When set, NFT metadata resolution is immutable and set to this.
    string public dropURI;

    /// @dev EIP-2981 collection-wide royalties information.
    RoyaltiesInfo internal _royaltiesInfo;

    /// @notice Ensures calls only be made by the Dopamine Registrar Controller.
    modifier onlyMinter() {
        if (msg.sender != minter) {
            revert MinterOnly();
        }
        _;
    }

    /// @notice Instantiates a new ERC-721 contract with metadata.
    /// @param baseURI_             Initial metadata URI for NFT resolution.
    /// @param contractURI_         Contract URI for collection-wide metadata.
    /// @param provenanceHash_      Concatenated hash of all images (optional).
    /// @param maxSupply_           The maximum supply of the NFT collection.
    /// @param admin_               A Dopamine contract administrator address.
    constructor(
        string memory baseURI_,
        string memory contractURI_,
        bytes32 provenanceHash_,
        uint256 maxSupply_,
        address admin_,
        address minter_
    ) OwnableAdministratable(admin_) {

        setBaseURI(baseURI_);
        setContractURI(contractURI_);
        setProvenanceHash(provenanceHash_);
        setMinter(minter_);

        maxSupply = maxSupply_;
    }

    /// @notice Gets the token metadata URI for an NFT identified by `tokenId`.
    function tokenURI(uint256 tokenId) external override view returns (string memory) {
        if (ownerOf[tokenId] == address(0)) {
            revert TokenNonexistent();
        }

        // If a finalized `dropURI` is not yet set, default to using `baseURI`.
        string memory uri = dropURI;
        if (bytes(uri).length == 0) {
            uri = baseURI;
        }

        return string(abi.encodePacked(uri, tokenId.toString()));
    }

    /// @notice Gets EIP-2981 royalties information for the collection.
    function royaltyInfo(
        uint256,
        uint256 salePrice
    ) external view virtual returns (address, uint256) {
        uint256 royalties = (salePrice * _royaltiesInfo.royalties) / 10000;
        return (_royaltiesInfo.receiver, royalties);
    }

    /// @notice Sets the address of the minter.
    /// @param newMinter The new minter for the NFT collection.
    function setMinter(address newMinter) public onlyOwnerOrAdmin {
        minter = newMinter;
        emit MinterSet(newMinter);
    }

    /// @notice Approves transfer for the NFT using an ERC-721 Permit. Permits
    ///         allow callers to approve and transfer NFTs in one transaction.
    ///         ERC-721 Permit spec: https://eips.ethereum.org/EIPS/eip-4494
    /// @param relayer   The address to be approved for transferring the NFT.
    /// @param tokenId   The identifier of the NFT being transferred.
    /// @param expiry    The time after which the permit becomes invalid.
    /// @param signature The SECP256k1 or EIP-2098 permit signature.
    function permit(
        address relayer,
        uint256 tokenId,
        uint256 expiry,
        bytes memory signature
    ) public {
        address owner = ownerOf[tokenId];
        // Revert if token does not exist.
        if (owner == address(0)) {
            revert TokenNonexistent();
        } 

        // Revert if permit has expired.
        if (block.timestamp > expiry) revert PermitExpired();

        // Get the EIP-712 permit hash and verify its validity.
        bytes32 permitHash = getPermitHash(
            relayer,
            tokenId,
            nonces[tokenId]++,
            expiry
        );
        _verifySignature(signature, _deriveEIP712Digest(permitHash), tokenId);

        // Approve the relayer for subsequent transferring.
        getApproved[tokenId] = relayer;
        
        emit Approval(owner, relayer, tokenId);
    }

    /// @notice Sets the provenance hash for the NFT collection.
    /// @param newProvenanceHash The new provenance hash to set.
    function setProvenanceHash(bytes32 newProvenanceHash) public onlyOwnerOrAdmin {
        if (totalSupply > 0) {
            revert ProvenanceHashImmutable();
        }
        emit ProvenanceHashSet(newProvenanceHash);
    }

    /// @notice Sets the contract URI for the NFT collection.
    /// @param newContractURI The new contract metadata URI to set.
    function setContractURI(string memory newContractURI) public onlyOwnerOrAdmin {
        contractURI = newContractURI;
        emit ContractURISet(newContractURI);
    }

    /// @notice Sets the base URI for the NFT collection.
    /// @param newBaseURI The new base URI to set.
    function setBaseURI(string memory newBaseURI) public onlyOwnerOrAdmin {
        baseURI = newBaseURI;
        emit BaseURISet(newBaseURI);
    }

    /// @notice Sets the drop URI for the NFT collection.
    /// @param newDropURI The new drop URI to set.
    function setDropURI(string memory newDropURI) public onlyOwnerOrAdmin {
        if (bytes(dropURI).length != 0) {
            revert DropURIImmutable();
        }
        dropURI = newDropURI;
        emit DropURISet(newDropURI);
    }

    /// @dev Sets the royalty information for all NFTs in the collection.
    /// @param receiver Address which will receive token royalties.
    /// @param royalties Royalties amount, in bips.
    function setRoyalties(address receiver, uint96 royalties) external onlyAdmin {
        if (royalties > 10000) {
            revert RoyaltiesTooHigh();
        }
        if (receiver == address(0)) {
            revert ReceiverInvalid();
        }
        _royaltiesInfo = RoyaltiesInfo(receiver, royalties);
    }

    /// @notice Checks if a specified interface of id `id` is supported.
    function supportsInterface(bytes4 id) public view virtual override(IERC165, ERC721Bindable, Ownable) returns (bool) {
        return 
            id == type(IERC165).interfaceId || 
            id == type(IERC721Bindable).interfaceId ||
            id == type(IERC721).interfaceId;
    }

    /// @notice Mints and binds an NFT to a binder in one go.
    /// @param to          The address of the ERC-721 binder owner.
    /// @param bindId      The identifier of the binder being bound & minted to.
    /// @param bindAddress The address of the binder contract.
    function mint(address to, uint256 bindId, address bindAddress) public virtual onlyMinter returns (uint256) {
        if (to != IERC721Binder(bindAddress).ownerOf(bindId)) {
            revert ReceiverInvalid();
        }

        // Mints involve 2 sequential steps: (1) mint, (2) perform bind
        // 1. First mint the NFT, transferring the bindable to the chip owner.
        uint256 tokenId = totalSupply;
        if (tokenId > maxSupply) {
            revert SupplyMaxCapacity();
        }
        _mint(to, tokenId);

        // 2. Perform the binding, emit the bind event and call the bind hook.
        _binder[tokenId] = Binder(bindAddress, bindId);
        emit Bind(msg.sender, address(0), to, tokenId, bindId, bindAddress);

        if (
            IERC721Binder(bindAddress).onERC721Bind(
                msg.sender,
                address(0),
                to,
                tokenId,
                bindId,
                ""
            ) != IERC721Binder.onERC721Bind.selector
        ) {
            revert BindInvalid();
        }

        return tokenId;
    }

}

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title PNFT Events & Errors Interface
interface IPNFTEventsAndErrors {

    /// @notice Function may only be called by the assigned registrar.
    error RegistrarOnly();

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Upgradable Registrar Interface
interface IUpgradableRegistrar {

    /// @notice Gets the address of the new Dopamine Registrar to migrate to.
    function upgradeRegistrar() external view returns(address);

    /// @notice Registers a chip to the Dopamine registry.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param registrant The address of the new chip registrant.
    /// @param permissions The registered chip registrar permissions.
    /// @param resolver The address of the resolver the chip record points to.
    function register(
        bytes32 chip,
        address registrant,
        address resolver,
        uint96 permissions
    ) external;

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @dev Note: the ERC-165 identifier for this interface is 0x6fc97e78.
interface IERC1155Binder is IERC165, IBinderErrors {

    /// @notice Handles binding of an IERC1155Bindable-compliant token type.
    /// @dev An IERC1155Bindable-compliant smart contract MUST call this
    ///  function at the end of a `bind` after delegating ownership to the asset
    ///  owner. The function MUST revert if `to` is not the asset owner of
    ///  `bindId`, or if `bindId` is not a valid asset. The function MUST revert
    ///  if it rejects the bind. If accepting the bind, the function MUST return
    ///  `bytes4(keccak256("onERC1155Bind(address,address,address,uint256,uint256,uint256,bytes)"))`
    ///  Caller MUST revert the transaction if the above value is not returned.
    ///  Note: The contract address of the binding token is `msg.sender`.
    /// @param operator The address responsible for binding.
    /// @param from The address which owns the unbound tokens.
    /// @param to The address which owns the asset being bound to.
    /// @param tokenId The identifier of the token type being bound.
    /// @param bindId The identifier of the asset being bound to.
    /// @param data Additional data sent along with no specified format.
    /// @return `bytes4(keccak256("onERC1155Bind(address,address,address,uint256,uint256,uint256,bytes)"))`
    function onERC1155Bind(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 bindId,
        bytes calldata data
    ) external returns (bytes4);

    /// @notice Handles binding of multiple IERC1155Bindable-compliant tokens
    ///  `tokenIds` to a single binder identified by `bindId`.
    /// @dev An IERC1155Bindable-compliant smart contract MUST call this
    ///  function at the end of a `batchBind` after delegating ownership of
    ///  multiple token types to the asset owner. The function MUST revert if
    ///  `to` is not the asset owner of `bindId`, or if `bindId` is not a valid
    ///  asset. The function MUST revert if it rejects the binds. If accepting
    ///  the binds, the function MUST return `bytes4(keccak256("onERC1155BatchBind(address,address,address,uint256[],uint256[],uint256[],bytes)"))`
    ///  Caller MUST revert the transaction if the above value is not returned.
    ///  Note: The contract address of the binding token is `msg.sender`.
    /// @param operator The address responsible for performing the binds.
    /// @param from The address which owns the unbound tokens.
    /// @param to The address which owns the assets being bound to.
    /// @param tokenIds The list of token types being bound.
    /// @param amounts The number of tokens for each token type being bound.
    /// @param bindId The identifiers of the asset being bound to.
    /// @param data Additional data sent along with no specified format.
    /// @return `bytes4(keccak256("onERC1155Bind(address,address,address,uint256[],uint256[],uint256[],bytes)"))`
    function onERC1155BatchBind(
        address operator,
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256 bindId,
        bytes calldata data
    ) external returns (bytes4);

    /// @notice Handles unbinding of an IERC1155Bindable-compliant token type.
    /// @dev An IERC1155Bindable-compliant contract MUST call this function at
    ///  the end of an `unbind` after revoking delegated asset ownership. The
    ///  function MUST revert if `from` is not the asset owner of `bindId`,
    ///  or if `bindId` is not a valid asset. The function MUST revert if it
    ///  rejects the unbind. If accepting the unbind, the function MUST return
    ///  `bytes4(keccak256("onERC1155Unbind(address,address,address,uint256,uint256,uint256,bytes)"))`
    ///  Caller MUST revert the transaction if the above value is not returned.
    ///  Note: The contract address of the unbinding token is `msg.sender`.
    /// @param operator The address responsible for performing the unbind.
    /// @param from The address which owns the asset the token type is bound to.
    /// @param to The address which will own the tokens once unbound.
    /// @param tokenId The token type being unbound.
    /// @param amount The number of tokens of type `tokenId` being unbound.
    /// @param bindId The identifier of the asset being unbound from.
    /// @param data Additional data sent along with no specified format.
    /// @return `bytes4(keccak256("onERC1155Unbind(address,address,address,uint256,uint256,uint256,bytes)"))`
    function onERC1155Unbind(
        address operator,
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        uint256 bindId,
        bytes calldata data
    ) external returns (bytes4);

    /// @notice Handles unbinding of multiple IERC1155Bindable-compliant token types.
    /// @dev An IERC1155Bindable-compliant contract MUST call this function at
    ///  the end of an `batchUnbind` after revoking delegated asset ownership.
    ///  The function MUST revert if `from` is not the asset owner of `bindId`,
    ///  or if `bindId` is not a valid asset. The function MUST revert if it
    ///  rejects the unbinds. If accepting the unbinds, the function MUST return
    ///  `bytes4(keccak256("onERC1155Unbind(address,address,address,uint256[],uint256[],uint256[],bytes)"))`
    ///  Caller MUST revert the transaction if the above value is not returned.
    ///  Note: The contract address of the unbinding token is `msg.sender`.
    /// @param operator The address responsible for performing the unbinds.
    /// @param from The address which owns the assets being unbound from.
    /// @param to The address which will own the tokens once unbound.
    /// @param tokenIds The list of token types being unbound.
    /// @param amounts The number of tokens for each token type being unbound.
    /// @param bindId The identifier of the asset being unbound from.
    /// @param data Additional data sent along with no specified format.
    /// @return `bytes4(keccak256("onERC1155Unbind(address,address,address,uint256[],uint256[],uint256[],bytes)"))`
    function onERC1155BatchUnbind(
        address operator,
        address from,
        address to,
        uint256[] calldata tokenIds,
        uint256[] calldata amounts,
        uint256 bindId,
        bytes calldata data
    ) external returns (bytes4);

    /// @notice Gets the owner address of the asset represented by id `bindId`.
    /// @param bindId The identifier of the asset whose owner is being queried.
    /// @return The address of the owner of the asset.
    function ownerOf(uint256 bindId) external view returns (address);

    /// @notice Checks if an operator can act on behalf of an asset owner.
    /// @param owner The address that owns an asset.
    /// @param operator The address that acts on behalf of owner `owner`.
    /// @return True if `operator` can act on behalf of `owner`, else False.
    function isApprovedForAll(address owner, address operator) external view returns (bool);

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

struct Registration {
    bytes32 chip;
    address registrant;
    uint256 blockNumber;
    bytes registerSignature;
    bytes scanSignature;
}

struct ClaimParameters {
    bytes32 chip;
    address claimant;
    uint256 blockNumber;
    uint256 expiry;
    bytes claimSignature;
    bytes scanSignature;
}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Registrar Events & Errors Interface
interface IDopamineRegistrarEventsAndErrors {

    event Lock();

    event Register(bytes32 chip, address registrant, address resolver, uint256 permissions);

    event BulkRegister(bytes32[] chips, address registrant, address resolver, uint256 permissions);

    /// @notice Emits when the base registrar URI is set for all chips.
    /// @param baseURI An IPFS string URI used for metadata resolution.
    event BaseURISet(string baseURI);

    /// @notice Emits when a registrar signer is set or unset.
    /// @param signer The address of specified registrar signer.
    /// @param setting A boolean indicating whether signing is permitted or not.
    event SignerSet(address signer, bool setting);

    /// @notice Emits when a chip registration has been claimed by a new owner.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param pnft The identifier of the claimed chip's physical-bound token.
    /// @param claimant The address of the new registrar owner.
    /// @param permissions The permissions associated with the claimed chip.
    event ClaimProcessed(
        bytes32 indexed chip,
        uint256 indexed pnft,
        address claimant,
        uint96 permissions
    );

    /// @notice Emits when a chip has its permissions modified to `perms`.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param permissions The newly set chip registration permissions.
    event SetPermission(bytes32 indexed chip, uint96 permissions);

    /// @notice Chip has already been registered.
    error AlreadyRegistered();

    /// @notice Caller is not an authorized chip registrant.
    error AuthorizedRegistrantOnly();

    /// @notice Caller must be an ERC721 bindable.
    error OnlyERC721Bindable(address bindable);

    /// @notice Caller must be an ERC1155 bindable.
    error OnlyERC1155Bindable(address bindable);

    /// @notice Chip does not have sufficient registrar permissions.
    error PermissionDenied();

    /// @notice Caller is not the chip registrant.
    error RegistrantOnly();

    /// @notice Caller is not the chip scanner.
    error ScannerOnly();

    /// @notice Upgrade contract is not yet set.
    error UpgradeUnavailable();
}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Registrar Interface
interface IDopamineRegistrar is IERC721Binder, IDopamineRegistrarEventsAndErrors {

    /// @notice Gets the owner address for a specific chip identifier.
    /// @param id The uint256 identifier of the chip being queried.
    function ownerOf(uint256 id) external view override(IERC721Binder) returns (address);

    /// @notice Gets the address of the new Dopamine Registrar to migrate to.
    function upgradeRegistrar() external view returns (address);

    /// @notice Checks if an operator can act on behalf of an asset owner.
    /// @param owner The address that owns an asset.
    /// @param operator The address that acts on behalf of owner `owner`.
    /// @return True if `operator` can act on behalf of `owner`, else False.
    function isApprovedForAll(address owner, address operator) external view override(IERC721Binder) returns (bool);

    /// @notice Gets the metadata URI associated with a registered chip.
    /// @param id The identifier of the chip being queried.
    function uri(uint256 id) external view returns (string memory);

    /// @notice Checks whether registrar permissions are set for a chip.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param permissions The permissions being checked for.
    /// @return True if the permissions are set, False otherwise.
    function checkPermissions(bytes32 chip, uint96 permissions) external view returns (bool);

    /// @notice Registers a chip to the Dopamine registry.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param registrant The address of the new chip registrant.
    /// @param resolver The address of the resolver the chip record points to.
    /// @param permissions The registered chip registrar permissions.
    function register(
        bytes32 chip,
        address registrant,
        address resolver,
        uint96 permissions
    ) external;

    /// @notice Transfers registration of a chip to a new registrant.
    function claim(ClaimParameters calldata claimParams) external;

    /// @notice Sets the base URI for the registrar metadata query resolution.
    /// @param baseURI The new URI string to set for metadata queries.
    function setBaseURI(string calldata baseURI) external;

    /// @notice Sets an authorized signer for the registrar.
    /// @param signer The address of an approved registration signer.
    /// @param setting Whether the signer may authorize registrations (boolean).
    function setSigner(address signer, bool setting) external;

    /// @notice Sets registrar permissions for a given chip.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param permissions The permissions to set for the chip.
    function setPermissions(bytes32 chip, uint96 permissions) external;

    /// @notice Clears registrar permissions for a given chip.
    /// @param chip The keccak-256 hash of the chip public key.
    /// @param permissions The permissions to unset for the chip.
    function unsetPermissions(bytes32 chip, uint96 permissions) external;

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine PNFT (Physical-bound NFT)
/// @notice PNFT is a Dopamine ERC-721 Bindable that only permits minted NFTs
///         to remain bound to chips in the Dopamine Registrar, and prohibits
///         normal transfers. PNFTs remain bound to their respective chips for
///         forever, unless their bound Dopamine Registrar is upgraded, in which
///         case PNFTs are unbound from the old registrar rebound to the new
///         registrar by the Dopamine Registrar Controller in one fell swoop.
abstract contract PNFT is ERC721DopamineBindable, IPNFTEventsAndErrors {

    /// @notice The Dopamine Registrar that PNFTs must be bound to.
    IUpgradableRegistrar public registrar;

    /// @notice Ensures calls only be made by the Dopamine Registrar.
    modifier onlyRegistrar() {
        if (msg.sender != address(registrar)) {
            revert RegistrarOnly();
        }
        _;
    }

    /// @notice Instantiates a new Dopamine ERC-721 Bindable Contract
    /// @param baseURI              Initial metadata URI for NFT resolution.
    /// @param contractURI          Contract URI for collection-wide metadata.
    /// @param provenanceHash       Concatenated hash of all images (optional).
    /// @param maxSupply            The maximum supply of the NFT collection.
    /// @param admin                A Dopamine contract administrator address.
    /// @param minter               The Dopamine Registrar Controller address.
    constructor(
        string memory baseURI,
        string memory contractURI,
        bytes32 provenanceHash,
        uint256 maxSupply,
        address admin,
        address minter,
        address registrar_
    )
    ERC721DopamineBindable(baseURI, contractURI, provenanceHash, maxSupply, admin, minter) {
        registrar = IUpgradableRegistrar(registrar_);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override(IERC721, ERC721Bindable) onlyRegistrar {
        (address bindAddress, uint256 bindId) = binderOf(tokenId);

        // PNFTs may not be transferred unless they are bound to a chip.
        if (bindAddress == address(0)) {
            revert BindNonexistent();
        } 

        // Extra sanity check to ensure PNFT is indeed bound to registrar.
        if (msg.sender != bindAddress) {
            revert BindInvalid();
        }

        _transfer(from, to, tokenId, bindAddress);
    }

    /// @notice Binds a PNFT to the currently configured Dopamine Registrar.
    /// @dev Binds should ONLY happen when a registrant is opting in to do an
    ///      upgrade for their chip, in which case the registrar will perform
    ///      an unbind, burn the chip NFT, and rebind all bindables that were
    ///      previously bound. 
    function bind(
        address from,
        address to,
        uint256 tokenId,
        uint256 bindId,
        address bindAddress,
        bytes calldata data
    ) public override(IERC721Bindable, ERC721Bindable) onlyRegistrar {
        // PNFTs can only be bound to the Dopamine Registrar.
        if (bindAddress != address(registrar)) {
            revert BinderInvalid();
        }
        super.bind(from, to, tokenId, bindId, bindAddress, data);
    }

    /// @notice Unbinds a PNFT from the currently configured Dopamine Registrar.
    /// @dev Unbinds should ONLY happen when a registrant is opting in to do an
    ///      upgrade for their chip, in which case the registrar will perform
    ///      an unbind, burn the chip NFT, and rebind all bindables that were
    ///      previously bound. As such, unbinds can only allow transfers to the
    ///      current registrar itself, and immediately thereafter the upgraded
    ///      registrar contract MUST be set to the PNFT's default registrar.
    function unbind(
        address from,
        address to,
        uint256 tokenId,
        uint256 bindId,
        address bindAddress,
        bytes calldata data
    ) public override(IERC721Bindable, ERC721Bindable) onlyRegistrar {
        if (to != address(registrar)) {
            revert ReceiverInvalid();
        }
        address upgradeRegistrar = registrar.upgradeRegistrar();
        if (upgradeRegistrar == address(0)) {
            revert BinderInvalid();
        }
        super.unbind(from, to, tokenId, bindId, bindAddress, data);
        registrar = IUpgradableRegistrar(upgradeRegistrar);
    }

    /// @notice Mints and binds an NFT to a binder in one go.
    /// @param to          The address of the ERC-721 binder owner.
    /// @param bindId      The identifier of the binder being bound & minted to.
    /// @param bindAddress The address of the binder contract.
    function mint(address to, uint256 bindId, address bindAddress) public override(ERC721DopamineBindable) returns (uint256) {
        if (bindAddress != address(registrar)) {
            revert RegistrarInvalid();
        }
        super.mint(to, bindId, bindAddress);
    }

}

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

contract DopamineGenesis02 is PNFT {

    /// @notice Experimental cop period is over!
    error ArtBaselFunIsOver();

    /// @notice Locks are immutable.
    error LockingImmutable();

    // Once locked, your genesis merch can become officaily bound to your shirt.
    bool public locked;

    // Tracks total # of cops till lock during Art Basel.
    mapping(bytes32 => uint256) cops;

    // Maps chips to tokenIds.
    mapping(bytes32 => uint256) chips;

    constructor(
        string memory baseURI,
        string memory contractURI,
        bytes32 provenanceHash,
        uint256 maxSupply, // Adjusted later during binding phase.
        address admin,
        address minter,
        address registrar
    )
    PNFT(baseURI, contractURI, provenanceHash, maxSupply, admin, minter, registrar) {}
    
    function name() public override pure returns (string memory) {
        return "DOPAMINE GENESIS 02";
    }

    function symbol() public override pure returns (string memory) {
        return "DG2";
    }

    function cop(bytes32 chip) public returns (uint256) {
        if (locked) {
            revert ArtBaselFunIsOver();
        }
        uint256 tokenId = chips[chip];
        if (ownerOf[tokenId] == address(0)) {
            uint256 tokenId = totalSupply + 1;
            _mint(msg.sender, tokenId);
            chips[chip] = tokenId;
        } else {
            uint256 tokenId = chips[chip];
            address owner = ownerOf[tokenId];
            if (msg.sender != owner) {
                ownerOf[tokenId] = msg.sender;
                unchecked {
                    balanceOf[owner]--;
                    balanceOf[msg.sender]++;
                }
                emit Transfer(owner, msg.sender, tokenId);
            }
        }
        cops[chip] += 1;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(PNFT) onlyRegistrar {
        if (locked) {
            (address bindAddress, uint256 bindId) = binderOf(tokenId);
            // PNFTs may not be transferred unless they are bound to a chip.
            if (bindAddress == address(0)) {
                revert BindNonexistent();
            } 

            // Extra sanity check to ensure PNFT is indeed bound to registrar.
            if (msg.sender != bindAddress) {
                revert BindInvalid();
            }
            _transfer(from, to, tokenId, bindAddress);
        } else {
            _transfer(from, to, tokenId, address(registrar));
        }
    }

    function lock() public onlyOwnerOrAdmin {
        if (locked) {
            revert LockingImmutable();
        }
        locked = true;
    }

    function burn(uint256 tokenId) public onlyOwnerOrAdmin {
        if (locked) {
            revert LockingImmutable();
        }
        _burn(tokenId);
    }

}