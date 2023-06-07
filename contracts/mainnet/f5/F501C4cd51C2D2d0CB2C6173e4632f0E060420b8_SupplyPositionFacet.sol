// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {DiamondERC721} from "./SupplyPositionLogic/DiamondERC721.sol";
import {ERC721InvalidTokenId} from "./DataStructure/ERC721Errors.sol";
import {SupplyPosition, Provision} from "./DataStructure/Storage.sol";
import {supplyPositionStorage, supplyPositionMetadataStorage} from "./DataStructure/Global.sol";
import {IOwnershipFacet} from "./interface/IOwnershipFacet.sol";
import {CallerIsNotOwner} from "./DataStructure/Errors.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/// @notice NFT collection facet for transferable tradable non fungible supply positions
contract SupplyPositionFacet is DiamondERC721 {
    // constructor equivalent is in the Initializer contract
    using Strings for uint256;

    /// @notice get metadata on provision linked to the supply position
    /// @param tokenId token identifier of the supply position
    /// @return provision metadata
    function position(uint256 tokenId) external view returns (Provision memory) {
        SupplyPosition storage sp = supplyPositionStorage();

        if (tokenId > sp.totalSupply) {
            revert ERC721InvalidTokenId();
        }

        return sp.provision[tokenId];
    }

    /// @notice total number of supply positions ever minted (counting burned ones)
    /// @return totalSupply the number
    function totalSupply() external view returns (uint256) {
        return supplyPositionStorage().totalSupply;
    }

    /// @notice get the token URI for a given token identifier
    /// @param tokenId token identifier of the supply position
    /// @return URI univeral resource identifier of the token metadata
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        _ownerOf(tokenId); // revert on invalid tokenId
        return string(abi.encodePacked(supplyPositionMetadataStorage().baseUri, tokenId.toString()));
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

error ERC721AddressZeroIsNotAValidOwner();
error ERC721InvalidTokenId();
error ERC721ApprovalToCurrentOwner();
error ERC721CallerIsNotOwnerNorApprovedForAll();
error ERC721CallerIsNotOwnerNorApproved();
error ERC721TransferToNonERC721ReceiverImplementer();
error ERC721MintToTheZeroAddress();
error ERC721TokenAlreadyMinted();
error ERC721TransferFromIncorrectOwner();
error ERC721TransferToTheZeroAddress();
error ERC721ApproveToCaller();
error ERC721CallerIsNotOwner();

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {NFToken, Offer} from "./Objects.sol";

error BadCollateral(Offer offer, NFToken providedNft);
error ERC20TransferFailed(IERC20 token, address from, address to);
error OfferHasExpired(Offer offer, uint256 expirationDate);
error RequestedAmountIsUnderMinimum(Offer offer, uint256 requested, uint256 lowerBound);
error RequestedAmountTooHigh(uint256 requested, uint256 offered, Offer offer);
error LoanAlreadyRepaid(uint256 loanId);
error LoanNotRepaidOrLiquidatedYet(uint256 loanId);
error NotBorrowerOfTheLoan(uint256 loanId);
error BorrowerAlreadyClaimed(uint256 loanId);
error CallerIsNotOwner(address admin);
error InvalidTranche(uint256 nbOfTranches);
error CollateralIsNotLiquidableYet(uint256 endDate, uint256 loanId);
error UnsafeAmountLent(uint256 lent);
error MultipleOffersUsed();
error PriceOverMaximum(uint256 maxPrice, uint256 price);
error CurrencyNotSupported(IERC20 currency);
error ShareMatchedIsTooLow(Offer offer, uint256 requested);

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {Protocol, SupplyPosition, SupplyPositionOffChainMetadata} from "./Storage.sol";
import {Ray} from "./Objects.sol";

/* rationale of the naming of the hash is to use kairos loan's ENS as domain, the subject of the storage struct as
subdomain and the version to anticipate upgrade. Order is revered compared to urls as it's the usage in code such as in
java imports */
bytes32 constant PROTOCOL_SP = keccak256("eth.kairosloan.protocol.v1.0");
bytes32 constant SUPPLY_SP = keccak256("eth.kairosloan.supply-position.v1.0");
bytes32 constant POSITION_OFF_CHAIN_METADATA_SP = keccak256("eth.kairosloan.position-off-chain-metadata.v1.0");

/* Ray is chosed as the only fixed-point decimals approach as it allow extreme and versatile precision accross erc20s
and timeframes */
uint256 constant RAY = 1e27;
Ray constant ONE = Ray.wrap(RAY);
Ray constant ZERO = Ray.wrap(0);

/* solhint-disable func-visibility */

/// @dev getters of storage regions of the contract for specified usage

/* we access storage only through functions in facets following the diamond storage pattern */

function protocolStorage() pure returns (Protocol storage protocol) {
    bytes32 position = PROTOCOL_SP;
    /* solhint-disable-next-line no-inline-assembly */
    assembly {
        protocol.slot := position
    }
}

function supplyPositionStorage() pure returns (SupplyPosition storage sp) {
    bytes32 position = SUPPLY_SP;
    /* solhint-disable-next-line no-inline-assembly */
    assembly {
        sp.slot := position
    }
}

function supplyPositionMetadataStorage() pure returns (SupplyPositionOffChainMetadata storage position) {
    bytes32 position_off_chain_metadata_sp = POSITION_OFF_CHAIN_METADATA_SP;
    /* solhint-disable-next-line no-inline-assembly */
    assembly {
        position.slot := position_off_chain_metadata_sp
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @notice file for type definitions not used in storage

/// @notice 27-decimals fixed point unsigned number
type Ray is uint256;

/// @notice Arguments to buy the collateral of one loan
/// @param loanId loan identifier
/// @param to address that will receive the collateral
/// @param maxPrice maximum price to pay for the collateral
struct BuyArg {
    uint256 loanId;
    address to;
    uint256 maxPrice;
}

/// @notice Arguments to borrow from one collateral
/// @param nft asset to use as collateral
/// @param args arguments for the borrow parameters of the offers to use with the collateral
struct BorrowArg {
    NFToken nft;
    OfferArg[] args;
}

/// @notice Arguments for the borrow parameters of an offer
/// @dev '-' means n^th
/// @param signature - of the offer
/// @param amount - to borrow from this offer
/// @param offer intended for usage in the loan
struct OfferArg {
    bytes signature;
    uint256 amount;
    Offer offer;
}

/// @notice Data on collateral state during the matching process of a NFT
///     with multiple offers
/// @param matched proportion from 0 to 1 of the collateral value matched by offers
/// @param assetLent - ERC20 that the protocol will send as loan
/// @param tranche identifier of the interest rate tranche that will be used for the loan
/// @param minOfferDuration minimal duration among offers used
/// @param minOfferLoanToValue
/// @param maxOfferLoanToValue
/// @param from original owner of the nft (borrower in most cases)
/// @param nft the collateral asset
/// @param loanId loan identifier
struct CollateralState {
    Ray matched;
    IERC20 assetLent;
    uint256 tranche;
    uint256 minOfferDuration;
    uint256 minOfferLoanToValue;
    uint256 maxOfferLoanToValue;
    address from;
    NFToken nft;
    uint256 loanId;
}

/// @notice Loan offer
/// @param assetToLend address of the ERC-20 to lend
/// @param loanToValue amount to lend per collateral
/// @param duration in seconds, time before mandatory repayment after loan start
/// @param expirationDate date after which the offer can't be used
/// @param tranche identifier of the interest rate tranche
/// @param collateral the NFT that can be used as collateral with this offer
struct Offer {
    IERC20 assetToLend;
    uint256 loanToValue;
    uint256 duration;
    uint256 expirationDate;
    uint256 tranche;
    NFToken collateral;
}

/// @title Non Fungible Token
/// @notice describes an ERC721 compliant token, can be used as single spec
///     I.e Collateral type accepting one specific NFT
/// @dev found in storgae
/// @param implem address of the NFT contract
/// @param id token identifier
struct NFToken {
    IERC721 implem;
    uint256 id;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {NFToken, Ray} from "./Objects.sol";

/// @notice type definitions of data permanently stored

/// @notice Parameters affecting liquidations by dutch auctions. The current auction parameters
///         are assigned to new loans at borrow time and can't be modified during the loan life.
/// @param duration number of seconds after the auction start when the price hits 0
/// @param priceFactor multiplier of the mean tvl used as start price for the auction
struct Auction {
    uint256 duration;
    Ray priceFactor;
}

/// @notice General protocol
/// @param nbOfLoans total number of loans ever issued (active and ended)
/// @param nbOfTranches total number of interest rates tranches ever created (active and inactive)
/// @param auctionParams - sets auctions duration and initial prices
/// @param tranche interest rate of tranche of provided id, in multiplier per second
///         I.e lent * time since loan start * tranche = interests to repay
/// @param loan - of id -
/// @param minOfferCost minimum amount repaid per offer used in a loan
/// @param offerBorrowAmountLowerBound borrow amount per offer has to be strightly higher than this value
struct Protocol {
    uint256 nbOfLoans;
    uint256 nbOfTranches;
    Auction auction;
    mapping(uint256 => Ray) tranche;
    mapping(uint256 => Loan) loan;
    mapping(IERC20 => uint256) minOfferCost;
    mapping(IERC20 => uint256) offerBorrowAmountLowerBound;
}

/// @notice Issued Loan (corresponding to one collateral)
/// @param assetLent currency lent
/// @param lent total amount lent
/// @param shareLent between 0 and 1, the share of the collateral value lent
/// @param startDate timestamp of the borrowing transaction
/// @param endDate timestamp after which sale starts & repay is impossible
/// @param auction duration and price factor of the collateral auction in case of liquidation
/// @param interestPerSecond share of the amount lent added to the debt per second
/// @param borrower borrowing account
/// @param collateral NFT asset used as collateral
/// @param payment data on the payment, a non-0 payment.paid value means the loan lifecyle is over
struct Loan {
    IERC20 assetLent;
    uint256 lent;
    Ray shareLent;
    uint256 startDate;
    uint256 endDate;
    Auction auction;
    Ray interestPerSecond;
    address borrower;
    NFToken collateral;
    Payment payment;
}

/// @notice tracking of the payment state of a loan
/// @param paid amount sent on the tx closing the loan, non-zero value means loan's lifecycle is over
/// @param minInterestsToRepay minimum amount of interests that the borrower will need to repay
/// @param liquidated this loan has been closed at the liquidation stage, the collateral has been sold
/// @param borrowerClaimed borrower claimed his rights on this loan (either collateral or share of liquidation)
struct Payment {
    uint256 paid;
    uint256 minInterestsToRepay;
    bool liquidated;
    bool borrowerClaimed;
}

/// @notice storage for the ERC721 compliant supply position facet. Related NFTs represent supplier positions
/// @param name - of the NFT collection
/// @param symbol - of the NFT collection
/// @param totalSupply number of supply position ever issued - not decreased on burn
/// @param owner - of nft of id -
/// @param balance number of positions owned by -
/// @param tokenApproval address approved to transfer position of id - on behalf of its owner
/// @param operatorApproval address is approved to transfer all positions of - on his behalf
/// @param provision supply position metadata
struct SupplyPosition {
    string name;
    string symbol;
    uint256 totalSupply;
    mapping(uint256 => address) owner;
    mapping(address => uint256) balance;
    mapping(uint256 => address) tokenApproval;
    mapping(address => mapping(address => bool)) operatorApproval;
    mapping(uint256 => Provision) provision;
}

/// @notice storage for the ERC721 compliant supply position facet. Related NFTs represent supplier positions
/// @param baseUri - base uri
struct SupplyPositionOffChainMetadata {
    string baseUri;
}

/// @notice data on a liquidity provision from a supply offer in one existing loan
/// @param amount - supplied for this provision
/// @param share - of the collateral matched by this provision
/// @param loanId identifier of the loan the liquidity went to
struct Provision {
    uint256 amount;
    Ray share;
    uint256 loanId;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC721} from "../interface/IERC721.sol";
import {NFTUtils} from "./NFTUtils.sol";
import {SupplyPosition} from "../DataStructure/Storage.sol";
import {supplyPositionStorage} from "../DataStructure/Global.sol";
import {ERC721AddressZeroIsNotAValidOwner, ERC721ApprovalToCurrentOwner, ERC721CallerIsNotOwnerNorApproved, ERC721CallerIsNotOwnerNorApprovedForAll} from "../DataStructure/ERC721Errors.sol";

/// @title ERC721 Diamond Facet
/// @notice implements basic ERC721 for usage as a diamond facet
/// @dev based on OpenZeppelin's implementation
///     this is a minimalist implementation, notably missing are the
///     tokenURI, _baseURI, _beforeTokenTransfer and _afterTokenTransfer methods
/// @author Kairos protocol
abstract contract DiamondERC721 is IERC721, NFTUtils {
    using Address for address;

    error Unauthorized();

    // constructor equivalent is in the Initializer contract

    /// @dev don't use this method for inclusion in the facet function selectors
    ///     prefer the LibDiamond implementation for this method
    ///     it is included here for IERC721-compliance
    /* solhint-disable-next-line no-empty-blocks */
    function supportsInterface(bytes4 interfaceId) public view returns (bool) {}

    function balanceOf(address owner) public view virtual returns (uint256) {
        SupplyPosition storage sp = supplyPositionStorage();

        if (owner == address(0)) {
            revert ERC721AddressZeroIsNotAValidOwner();
        }
        return sp.balance[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return _ownerOf(tokenId);
    }

    function name() public view virtual returns (string memory) {
        SupplyPosition storage sp = supplyPositionStorage();

        return sp.name;
    }

    function symbol() public view virtual returns (string memory) {
        SupplyPosition storage sp = supplyPositionStorage();

        return sp.symbol;
    }

    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf(tokenId);
        if (to == owner) {
            revert ERC721ApprovalToCurrentOwner();
        }
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) {
            revert ERC721CallerIsNotOwnerNorApprovedForAll();
        }

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        return _getApproved(tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        _setApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _isApprovedForAll(owner, operator);
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert ERC721CallerIsNotOwnerNorApproved();
        }

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual {
        if (!_isApprovedOrOwner(msg.sender, tokenId)) {
            revert ERC721CallerIsNotOwnerNorApproved();
        }
        _safeTransfer(from, to, tokenId, data);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import {IERC721Events} from "../interface/IERC721Events.sol";
import {supplyPositionStorage} from "../DataStructure/Global.sol";
import {SupplyPosition} from "../DataStructure/Storage.sol";
import {ERC721ApproveToCaller, ERC721InvalidTokenId, ERC721TokenAlreadyMinted, ERC721MintToTheZeroAddress, ERC721TransferFromIncorrectOwner, ERC721TransferToNonERC721ReceiverImplementer, ERC721TransferToTheZeroAddress} from "../DataStructure/ERC721Errors.sol";

/// @notice internal logic for DiamondERC721 adapted fo usage with diamond storage
abstract contract NFTUtils is IERC721Events {
    using Address for address;

    function emitTransfer(address from, address to, uint256 tokenId) internal {
        emit Transfer(from, to, tokenId);
    }

    function emitApproval(address owner, address approved, uint256 tokenId) internal {
        emit Approval(owner, approved, tokenId);
    }

    function emitApprovalForAll(address owner, address operator, bool approved) internal {
        emit ApprovalForAll(owner, operator, approved);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert ERC721TransferToNonERC721ReceiverImplementer();
                } else {
                    /* solhint-disable-next-line no-inline-assembly */
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data)) {
            revert ERC721TransferToNonERC721ReceiverImplementer();
        }
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory data) internal {
        _mint(to, tokenId);
        if (!_checkOnERC721Received(address(0), to, tokenId, data)) {
            revert ERC721TransferToNonERC721ReceiverImplementer();
        }
    }

    function _mint(address to, uint256 tokenId) internal {
        SupplyPosition storage sp = supplyPositionStorage();

        if (to == address(0)) {
            revert ERC721MintToTheZeroAddress();
        }
        if (_exists(tokenId)) {
            revert ERC721TokenAlreadyMinted();
        }

        sp.balance[to] += 1;
        sp.owner[tokenId] = to;

        emitTransfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal {
        SupplyPosition storage sp = supplyPositionStorage();

        address owner = _ownerOf(tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        sp.balance[owner] -= 1;
        delete sp.owner[tokenId];

        emitTransfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        SupplyPosition storage sp = supplyPositionStorage();

        if (_ownerOf(tokenId) != from) {
            revert ERC721TransferFromIncorrectOwner();
        }
        if (to == address(0)) {
            revert ERC721TransferToTheZeroAddress();
        }

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        sp.balance[from] -= 1;
        sp.balance[to] += 1;
        sp.owner[tokenId] = to;

        emitTransfer(from, to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal {
        SupplyPosition storage sp = supplyPositionStorage();

        sp.tokenApproval[tokenId] = to;
        emitApproval(_ownerOf(tokenId), to, tokenId);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal {
        SupplyPosition storage sp = supplyPositionStorage();

        if (owner == operator) {
            revert ERC721ApproveToCaller();
        }
        sp.operatorApproval[owner][operator] = approved;
        emitApprovalForAll(owner, operator, approved);
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        SupplyPosition storage sp = supplyPositionStorage();

        return sp.owner[tokenId] != address(0);
    }

    function _ownerOf(uint256 tokenId) internal view returns (address) {
        SupplyPosition storage sp = supplyPositionStorage();

        address owner = sp.owner[tokenId];
        if (owner == address(0)) {
            revert ERC721InvalidTokenId();
        }
        return owner;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = _ownerOf(tokenId);
        return (spender == owner || _isApprovedForAll(owner, spender) || _getApproved(tokenId) == spender);
    }

    function _getApproved(uint256 tokenId) internal view returns (address) {
        if (!_exists(tokenId)) {
            revert ERC721InvalidTokenId();
        }

        return supplyPositionStorage().tokenApproval[tokenId];
    }

    function _isApprovedForAll(address owner, address operator) internal view returns (bool) {
        return supplyPositionStorage().operatorApproval[owner][operator];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity 0.8.18;

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721Events} from "./IERC721Events.sol";

/**
 * @dev Required interface without events of an ERC721 compliant contract.
 */
interface IERC721 is IERC165, IERC721Events {
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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity 0.8.18;

/**
 * @dev Required events of an ERC721 compliant contract.
 */
interface IERC721Events {
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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

interface IOwnershipFacet {
    function transferOwnership(address _newOwner) external;

    function owner() external view returns (address owner_);
}