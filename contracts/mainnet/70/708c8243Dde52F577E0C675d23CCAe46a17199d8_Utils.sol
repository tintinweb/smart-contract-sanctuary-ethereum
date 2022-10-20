/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

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

// File: source/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// File: source/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol

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

// File: source/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Metadata.sol

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

// File: source/openzeppelin-contracts/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

// File: source/openzeppelin-contracts/contracts/utils/Context.sol

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

// File: source/openzeppelin-contracts/contracts/utils/math/Math.sol

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

// File: source/openzeppelin-contracts/contracts/utils/Strings.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

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

// File: source/openzeppelin-contracts/contracts/utils/introspection/ERC165.sol

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

// File: source/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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

        _beforeTokenTransfer(address(0), to, tokenId);

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

        _afterTokenTransfer(address(0), to, tokenId);
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

        _beforeTokenTransfer(owner, address(0), tokenId);

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

        _afterTokenTransfer(owner, address(0), tokenId);
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

        _beforeTokenTransfer(from, to, tokenId);

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

        _afterTokenTransfer(from, to, tokenId);
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
     * @dev Hook that is called before any (single) token transfer. This includes minting and burning.
     * See {_beforeConsecutiveTokenTransfer}.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any (single) transfer of tokens. This includes minting and burning.
     * See {_afterConsecutiveTokenTransfer}.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called before "consecutive token transfers" as defined in ERC2309 and implemented in
     * {ERC721Consecutive}.
     * Calling conditions are similar to {_beforeTokenTransfer}.
     */
    function _beforeConsecutiveTokenTransfer(
        address from,
        address to,
        uint256, /*first*/
        uint96 size
    ) internal virtual {
        if (from != address(0)) {
            _balances[from] -= size;
        }
        if (to != address(0)) {
            _balances[to] += size;
        }
    }

    /**
     * @dev Hook that is called after "consecutive token transfers" as defined in ERC2309 and implemented in
     * {ERC721Consecutive}.
     * Calling conditions are similar to {_afterTokenTransfer}.
     */
    function _afterConsecutiveTokenTransfer(
        address, /*from*/
        address, /*to*/
        uint256, /*first*/
        uint96 /*size*/
    ) internal virtual {}
}

// File: source/openzeppelin-contracts/contracts/token/ERC721/extensions/IERC721Enumerable.sol

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: source/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and 'to' cannot be the zero address at the same time.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Hook that is called before any batch token transfer. For now this is limited
     * to batch minting by the {ERC721Consecutive} extension.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeConsecutiveTokenTransfer(
        address,
        address,
        uint256,
        uint96 size
    ) internal virtual override {
        // We revert because enumerability is not supported with consecutive batch minting.
        // This conditional is only needed to silence spurious warnings about unreachable code.
        if (size > 0) {
            revert("ERC721Enumerable: consecutive transfers not supported");
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// File: source/openzeppelin-contracts/contracts/interfaces/IERC2981.sol

// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: source/openzeppelin-contracts/contracts/token/common/ERC2981.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// File: source/openzeppelin-contracts/contracts/access/Ownable.sol

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

// File: source/Agreements.sol

/*
 * @title: Asteroid Belt Club NFT Strategic Agreements
 * @author: Gustavo Hernandez Baratta  (The Pan de Azucar Bay Company LLC)
 * Strategic agreements allow defining an amount in ETH that can be used to make property claims on asteroids, 
 * above the 550 thousand claims cap, although minted NFTs will not initially grant membership rights in the CLUB.
 *
 * Logic of the creation, approval and use of strategic agreements:
 * a) An agreement proposal can be made only from the DAO. This proposal must specify the wallet of the beneficiary, 
 * the amount in ETH that will be credited, the address of the contract that can activate it (the voting contract) 
 * and the amount in ETH that will be required for a minted NFT to acquire full rights in the CLUB.
 * Proposal.
 * To create an agreement, createAgreement() must be called from the DAO address. Initially the DAO address is not 
 * a valid address, so no agreement can be created. This function adds to the map _agreements a new agreement structure 
 * containing the agreement information, linked to the address of the wallet beneficiary of the agreement.
 *
 * b) The voting contract defines the rules governing the vote (majorities, deadlines, etc.) 
 * and if they are met, the activation is triggered. The activateAgreement() function activates a previously created agreement 
 * and can only be called from the address that was defined in the _activator parameter when creating the agreement.
 *
 * c) Finally, the beneficiary makes use of the assigned balance.
 * A safety delay of 63600 blocks is included between each of the steps. updateAgreementBalance() is called each time the 
 * balance of an agreement is used as the method of payment of the claim cost. The token is also incorporated into the NFT 
 * agreementTokens variable minted with those funds by calling the updateTokensMinted() function.
 * In case of emergency, the agreement can be paused/resumed by the owner by calling pauseAgreement()
 *
 * agreementMinted stores the number of claims made with agreement funds and agreementUsed the total amount of agreement funds already used. 
 * 
 * email: [email protected]
 */

pragma solidity ^0.8.14;

abstract contract Agreements is Ownable {

    /* agreement structure */ 
    struct agreement {
        uint256 id; //sequence
        string name; //identifying name
        string description; //breaf description
        uint256 credits; //amount in ETH available to beneficiary
        uint256 used; //amount used from credit
        bool active; //active flag
        bool paused; //emergency pause
        address activator; //voting contract address
        uint256 validblock; //block from which the agreement can be approved // block from which the agreement remains in force
        uint256 befull; //amount in ETH that give full CLUB membership (0 could'n)
    }

    mapping(address => agreement) private _agreements; //map beneficiary address to agreement data
    mapping(uint256 => address) public agreementTokens; //register each token minted from agreement
    address[] private _idagreements; //array of beneficiary addresses

    uint256 public agreementMinted=0; //total of claims
    uint256 public agreementUsed=0; //total of balance used
    //uint256 public constant agreementRestrictionLimit=10; //10% of total (maxSupply) && 10% of total sales
    //uint256 public constant agreementRestrictionExpires=500000; //10% of sales restriction 
    uint256 public minToBeFull=0.1 ether;

    uint256 public constant blocksDelay=72000; //safety pause between instances

    /* Events */
    event AgreementUsed(address agreement, uint256 amount, uint256 tokens);
    event AgreementAproved(uint256 id, uint256 sinceBlock);
    event NewAgreementProposed(uint256 id, string name, string description, uint256 credit, address activator, address beneficiary, uint256 blocksDelay);
    event AgreementPaused(address agreement, bool state);


    constructor() {
        _idagreements.push(address(0)); //To get all real agreement ids over 0 index
    }

    /* @dev: Emergency pause/restore an active agreement. Only Owner can call it. 
     * Emit an AgreementPaused event with new state */
    
    function pauseAgreement(address _address, bool _state) public onlyOwner {
        require(_agreements[_address].id > 0 
         && _agreements[_address].active==true ,"Agreement not found or not active");
        _agreements[_address].paused = _state;
        emit AgreementPaused(_address, _state);
    }



    /* @dev: Return an array with all beneficiary agreements */
    function getList() public view returns(address[] memory) {
        return(_idagreements);
    }

    /* @dev: Return agreement data for given beneficiary address */
    function getAgreement(address _address) public view returns(agreement memory) {
        return(_agreements[_address]);
    }

    /* @dev: return the current available balance for a given beneficiary address */ 

    function getAgreementBalance(address _address) public view returns(uint256) {
        if(_agreements[_address].paused==false && _agreements[_address].active && block.number > _agreements[_address].validblock ) {
            return _agreements[_address].credits - _agreements[_address].used;
        }
        return(0);
    }

    /* @dev: updates Agreement Balance. Called from ABC contract when minting
     * msgSender() must be owner of an agreement
     * @params:
     * _amount: cost of the minting
     * _tokens: quantity of tokens minted
     * Execution stopped if not found an agreement for msg.sender address, if agreement was paused, 
     * if not active, or with less credit amount than required.
     * Updates agreement.used credit, agreementUsed with _amount and agreementMinted with _tokens
     * Emit an AgreementUsed event
     */

    function updateAgreementBalance(uint256 _amount, uint256 _tokens) internal {
        require(_agreements[_msgSender()].id >0 
         && _agreements[_msgSender()].paused==false 
         && _agreements[_msgSender()].active 
         && block.number > _agreements[_msgSender()].validblock , "Agreement not found or not ready");

        require(_agreements[_msgSender()].credits-_agreements[_msgSender()].used >= _amount,"Not enough available credit");
        _agreements[_msgSender()].used=_agreements[_msgSender()].used+_amount;
        agreementUsed=agreementUsed+_amount;
        agreementMinted=agreementMinted+_tokens;
        emit AgreementUsed(_msgSender(),_amount, _tokens);
    }

    /* @dev: Adds the id of the minted token to the agreementTokens list, which is used to determine if the token has CLUB membership rights.*/
    function updateTokensMinted(uint256 _tokenId) internal {
        agreementTokens[_tokenId]=_msgSender();
    }

    /* @dev Creates a new agreement with _address as beneficiary, and delegates to _activator the power to activate it.
     * @params:
     * name: identification of the agreement
     * description: a brief description
     * credits: amount to be assigned
     * activator: address authorized to activate agreement
     * address: if active, from what address can mint using credit.
     * befull: amount the NFT holder must pay to become a full member of the ABC. zero closes the possibility. must be at least minToBeFull
     * The agreement cannot be activated before the block set in ValidBlock.
     * This gives the community a time frame to react in case of a spuriously created agreement.
     * Execution is stopped if a previously defined agreement is found for that beneficiary
     * Emit a NewAgreementProposed event
     * Returns a structure with the information of the newly created agreement
     */

    function createAgreement(string memory _name, string memory _description, uint256 _credits, address _activator, address _address, uint256 _befull) public onlyOwner returns(agreement memory) {
        require(_agreements[_address].id == 0 ,"Already exists an agreement owned by that address");
        require(_befull==0 || _befull >=minToBeFull, "If want to grant DAO rights payment must be at least minToBeFull");
        agreement memory _agreement;
        _agreement.id=_idagreements.length;
        _agreement.name=_name;
        _agreement.description=_description;
        _agreement.credits=_credits;
        _agreement.active=false;
        _agreement.paused=false;
        _agreement.activator=_activator;
        _agreement.validblock=block.number+blocksDelay;
        _agreement.befull=_befull;
        _idagreements.push(_address);
        _agreements[_address]=_agreement;
        emit NewAgreementProposed(_agreement.id, _name, _description, _credits, _activator, _address, _agreement.validblock);      
        return _agreement;  
    }

    /* @dev: This function must be called by the DAO contract where the agreement is voted on.
     * No agreement is effective until the function is executed. 
     * The voting contract must include a call to this function once the successful result of the vote is verified. 
     * The agreement has a delay of blocksDelay before it becomes valid. This gives the community a time frame to
     * react in case of a spuriously activated agreement.
     * Execution is stopped if _id is not a valid agreement, if caller is not the activator, if activation occurs before validblock 
     * or if already active.
     * A new validblock is set delaying it in blocksDelay
     * Emit an AgreementAproved event.
     */
    function activateAgreement(uint256 _id) public {
        require(_idagreements[_id] != address(0), "Agreement not found");
        address _agreement=_idagreements[_id];
        require(_agreements[_agreement].activator == _msgSender(),"Only activator can activate agreement");
        require(block.number > _agreements[_agreement].validblock,"Wait for valid block until activate");
        require(_agreements[_agreement].active==false,"Agreement already active");
        _agreements[_agreement].active=true;
        _agreements[_agreement].validblock=block.number+blocksDelay;

        emit AgreementAproved(_id, _agreements[_agreement].validblock);
    }

  function setMinToBeFull(uint256 _newValue) public onlyOwner {
    require(_newValue > minToBeFull, "New value must be greather than current");
    minToBeFull=_newValue;
  }     

}

// File: source/Kickstarter.sol

/*
 * @title: Asteroid Belt Club NFT KickStarter Program Implementation
 * @author: Gustavo Hernandez Baratta  (The Pan de Azucar Bay Company LLC)
 * @dev: Abstract Smart Contract that implements the KickStarter program.
 * The Kickstarter program aims to collect 500 ETH from early enthusiasts of the project. 
 * To do so, it grants a benefit consisting of multiplying the spending power of the funds deposited, according to a decreasing table.
 * Thus, the first 50 ETH deposited will have a spending power multiplied by 8, the next 50 ETH one multiplied by 4, 
 * the next 100 ETH one multiplied by 3 and the last 200 one multiplied by 2. 
 * The private variables kickStartTargets and kickStartBoost define this scale and the function kickStartThreshold() can be called 
 * to obtain the current reward level and the remaining amount in ETH of the current threshold. A minimum of 0.05 ETH is required as a deposit.
 * 
 * The balance of the accounts is stored in the kickStarters variable. 
 * The function getKickStartBalance() can be called at any time to obtain the available balance for a given address.
 * Multiple deposits can be made from a single ETH wallet. Funds are deposited by calling the kickstart function, 
 * which can only be called from the ABC website, as the transaction is signed by the CLUB.
 * 
 * The public variables kickStartCollected, kickStartSpent and kickStartMinted can be called to obtain information about the progress of the program.
 * kickStartCollected returns the total amount of funds collected by the program, kickStartSpent returns the total amount of collected 
 * funds already used and kickStartMinted returns the amount of claims made using the deposited funds.
 * 
 * When the contract is deployed, 1000 ETH are allocated to the Igniter, the owner of the contract. 
 * These are the assets he will have available to carry out the kickoff of the project, including rewarding his collaborators. 
 * Three public variables can be queried to determine the expenditure of these funds: ownerSpent, which stores the amount spent, 
 * ownerMinted, which stores the number of claims made, and ownerTransfered, which stores the total transferred by Ingiter to third parties.
 * 
 * @email: [email protected]
 */

pragma solidity ^0.8.14;

//import "github.com/OpenZeppelin/openzeppelin-contracts/contracts/utils/Context.sol";

abstract contract Kickstarter {
    using Strings for uint256;
    /* Kickstart parameters and stored data */
    uint256[4] private kickStartTargets = [50 ether,100 ether,200 ether,500 ether];
    uint256[4] private kickStartBoost=[800,400,300,200];  
    uint256 constant kickStartMin = 0.05 ether;
    mapping(address => uint256) public kickStarters; //Balances for kickstarters
    uint256 public kickStartCollected=0; //Collected thru kikStart Campaign
    uint256 public kickStartSpent=0; //Cost of Tokens minted using kickStart funds. (MAX: 1500)
    uint256 public kickStartMinted=0; //Tokens minted using kickstart balances
    uint256 public ownerSpent=0; //Cost of token minted by owner using constructor credit
    uint256 public ownerMinted=0; //Token minted by owner using constructor credit;
    uint256 public ownerTransfered=0; //Amount transfered to others by owner
    address private _owner=address(0);

    /* @dev: Event fired when Kickstart Balance was transferred */
    event KickstartBalanceTransfered(address from, address to,  uint256 amount);


    constructor(uint256 _credit) {
      kickStarters[msg.sender]=_credit;
      _owner=msg.sender;
    }

    /* @dev: returns current reward multiplier and the remaining to reach current threshold 
     * After reaching 500 ether, return 1x multiplier and 1000 ether max deposit, to allow to use remaining balance
     * if any */
    function kickStartThreshold() public view returns (uint256[] memory) {
        uint256[] memory boost = new uint256[](2);
        boost[0]=1;
        boost[1]=1000 ether;
        
        for(uint i=0;i<kickStartTargets.length;i++) {
            if(kickStartCollected < kickStartTargets[i]) {
                boost[0]=(kickStartBoost[i]/100);
                boost[1]=kickStartTargets[i]-kickStartCollected;
                break;
            }
        }
        return(boost);
    }

    /* @dev: return the current kickStarter Program balance for the given _address */
    function getKickStartBalance(address _address) public view returns(uint256) {
        return(kickStarters[_address]);
    }
 
    /* @dev: Called internally when the claim was made using kickstarter balance */
    function updateKickStartBalance(uint256 _cost,uint256 _minted) internal {
        require(kickStarters[msg.sender] >= _cost, "Not enough balance");
        kickStarters[msg.sender]=kickStarters[msg.sender]-_cost;
        if(msg.sender != _owner) {
            kickStartSpent=kickStartSpent+_cost;
            kickStartMinted=kickStartMinted+_minted;
        }
        else {
            ownerSpent=ownerSpent+_cost;
            ownerMinted=ownerMinted+_minted;
        }
    }
   
    /* @dev: Creates or increases the balance of an account with the amount resulting from multiplying the original amount deposited 
     * by the reward corresponding to the current program threshold. The deposit must be greater than or equal to the minimum amount 
     * determined in the kickStartMin variable, but equal to or less than the amount remaining to complete the current threshold.
     *
     * This function can only be called from the website, because it is signed.
     * If the _referer parameter is a valid ETH address, the referrers account will be credited with the corresponding commission.
     * The execution is stopped if: The threshold of 500 ETH was reached and kickStartThreshold() returned 0 as deposit reward; 
     * If more than the amount remaining to complete the current threshold is sent; If less than the minimum set in kickStartMin was sent; 
     * If the block timestamp is greater than the _expiration parameter; If the _msgHash parameter is invalid; 
     * Or if the signer is invalid (the signer's address does not match the one stored in the _signatureWallet variable.
     * As a result, in the array variable kickStarters, the msg.sender is assigned (or incremented by, if it already exists) 
     * the msg.value multiplied by the reward, and the kickStartCollected variable is updated with the amount entered. 
     * The _registerTotal function is also invoked to increment the total amount collected by the CLUB with the amount entered.
     */
    function kickstart(address _referer, uint32 _expiration, bytes32 _msgHash, bytes memory _signature) public payable {
        uint256[] memory boost= kickStartThreshold();
        _checkPaused();
        require(boost[0] > 0, "KickStart ended. Thanks!");
        require(boost[1] >=msg.value, string(abi.encodePacked("Please send no more than ", boost[1].toString())));
        require(msg.value >= kickStartMin, string(abi.encodePacked("Must send at least ", kickStartMin.toString())));
        require(_expiration > block.timestamp, "Signature expired");

        bytes memory __rawMsg = abi.encodePacked(Strings.toHexString(uint256(uint160(_referer)), 20),Strings.toString(_expiration));
        _checkSignature(__rawMsg, _msgHash, _signature);
        
        kickStarters[msg.sender]=kickStarters[msg.sender]+(msg.value*boost[0]);
        kickStartCollected=kickStartCollected+msg.value;
        _registerTotal(msg.value);
        if(_referer != address(0)){
            _referrerPay(_referer,msg.value);
        }        
    }

    /* @dev: The holder of funds deposited in the kickStarter program can transfer them to a third party by invoking this function. 
     * The execution of the function is interrupted: If the parameter _to is not a valid address; OR if msg.sender does not have 
     * in its account an amount equal to or greater than the amount to be transferred. 
     * As a result, the amount transferred is subtracted from msg.sender's balance and credited to the recipient.
     *
     * If msg.sender is Igniter (the owner of the contract) the ownerTransferred variable is updated. 
     * Finally, it fires an event notifying the transfer. 
     */

    function kickStartTransfer(address _to, uint256 _amount  ) public {
        require(_to != address(0), "Please transfer your balance to a real address!");
        require(kickStarters[msg.sender] >=_amount, "You must have at least the amount in your kickstart balance");
        kickStarters[msg.sender] = kickStarters[msg.sender] - _amount;
        kickStarters[_to]=kickStarters[_to] + _amount;
       if(msg.sender == _owner) {
            ownerTransfered=ownerTransfered+ _amount;
        }        
        emit KickstartBalanceTransfered(msg.sender, _to, _amount);
    }

    function _registerTotal(uint256 value) internal virtual {}
    function _referrerPay(address referer, uint256 amount) internal virtual {}
    function _checkPaused() internal virtual {}
    function _checkSignature(bytes memory _raw, bytes32 _msgHash, bytes memory _signature) internal virtual {}

}

// File: source/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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

// File: source/utils/Utils.sol

pragma solidity >= 0.8.0 <0.9.0;


/*
 * @title: Misc Utils
 * @author: Gustavo Hernandez Baratta for The Pan de Azucar Bay Company LLC
 * @dev: provide usefull stuffs
 * email: [email protected]
 */

library Utils { 

  using Strings for uint256;  
  
  /* @dev: return array elements imploded in a string */
  function implodeIds(uint256[] memory _ids) public pure returns (string memory) {
    bytes memory output;

    for (uint256 i = 0; i < _ids.length; i++) {
      output = abi.encodePacked(output, Strings.toString(_ids[i]));
    }
    return string(output);      
  }


  function SignatureCheck(bytes memory _rawMsg, bytes32 _msgHash, bytes memory _signature, address _validSigner) public pure {
    bytes32 __msgHash=ECDSA.toEthSignedMessageHash(_rawMsg);
    require(_msgHash==__msgHash, "Invalid Signature: malformed hash");
    require(ECDSA.recover(_msgHash,_signature)==_validSigner,"Invalid Signature: invalid signed");        
  }

/*
 * @title: Random Number generator
 * @author: Gustavo Hernandez Baratta for The Pan de Azucar Bay Company LLC
 * @dev Provides a simple way to get a random value between 0 and the defined maximum. 
 * @notice It should be studied in which cases it can be used since it can be hacked, as explained in the 
 * ollowing article: 
 * https://coredevs.medium.com/safe-practice-of-tron-solidity-smart-contracts-implement-random-numbers-in-the-contracts-9c7ad8f6f9b0
 * email: [email protected]
 */
  function RandomGenerate(uint256 _minRange, uint256 _maxRange, uint256 _seed) public view returns(uint256) {
    require(_maxRange >0, 'Value must be greather than zero');
    require(_maxRange > _minRange, 'Max value must be greather than min value');
    uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
        block.gaslimit+
        ((uint256(keccak256(abi.encodePacked(msg.sender))) / (block.timestamp)) +
        block.number
    )+_seed)));
    uint256 generated = seed - ((seed / _maxRange) * _maxRange);
    if(generated < _minRange) {
        generated = generated + _minRange;
    }
    if(generated > _maxRange) {
        generated = _maxRange;
    }
    return generated;
  }

}

// File: source/ABC.sol

/*
 * @title: Asteroid Belt Club NFT Smart Contract
 * @author: Gustavo Hernandez Baratta  (The Pan de Azucar Bay Company LLC)
 * @dev Smart contract for the creation and management of the NFTs corresponding
 * to the first property claim on the asteroids of the Asteroid Belt.
 
 * email: [email protected]
 *
 */

pragma solidity ^0.8.14;




contract ABC is ERC2981, ERC721Enumerable, Agreements, Kickstarter {
  using Strings for uint256;
  

  /* ABC Collection parameters and stored data */    
  string public baseURI; 
  string public constant baseExtension = ".json";
  string public constant _name='Asteroid Belt Club';
  string public constant _symbol='ABC';
  

  /* Asteroid Naming Services*/
  mapping(uint256 => string) private _ansModifiedURI; //Asteroid Naming Services Modifier;
  address private _ansAddress=address(0); //Pending to be defined using setAnsAddress()

 /* Asteroid Belt Club Web Signature */
  address private _signatureWallet=address(0); //Pending to be defined using setSignatureWallet()
  mapping(string => bool) private _usedUniqids; //On random minting, a random selection could be used only once
  
  uint256 public maxSupply = 605011; //Initially, the asteroids numbered by the IAU as of December 31, 2021 are contemplated,
                                     //then others will be incorporated according to the schedule established in the Whitepaper.

  uint256 public  maxToSale = 550000; //Max membership.
  uint256 public totalSales = 0; //Total incomes
  uint256 public constant maxMinting=10; //Max token minting in one call to mint() or random() functions.
  bool public paused = false; //Emergency pause

  /* ABC Starter Minting Privileges passed to kickstarter*/
  uint256 public constant ownerCanMintMax=1000 ether; //Buying power granted to Igniter (see Whitepaper)
  uint8 public constant ownerInitialMinting=10; //10 random claims created to start markets like Opensea
  
  /* ABC Vault and Payment Splitter address filled at deployment */

  address public abcPayment;


  /* ABC referer program */
  uint256 public referrersPaid = 0; //Total commissions generated with the referral program
  uint256 public referrersWidthrawn = 0; //Withdrawn commissiones
  uint96 private constant referrerFee = 500; //5% 
  uint96 private constant referrerFeeDenominator=10000;
  mapping(address => uint256) private _referrerBalance; //Referral Program Balances

  /* ABC Belter's Day */
  uint16 public beltersDayMinted =0; //Minted counter
  uint16 public constant beltersDayMax=10000;  //Max to mint

  /* Events */
  event PaymentReceived(address from, uint256 amount);
  event StateChanged(bool newState);
  event Withdrawn(address sender, uint256 amount);
  event NewMaxSupply(uint256 oldMaxSupply, uint256 newMaxSupply);
  event URIChanged(uint256 indexed tokenId, string newURI);
  event RightsUpgraded(uint256 indexed tokenId);
  event ReferrerPaid(address referer, uint256 amount);
  event ReferrerWidthraw(address referer, uint256 amount );
  event ReferrerCanceled(address referer, uint256 amount );

  
  constructor(address _vault, address _splitter) ERC721(_name, _symbol) Kickstarter(ownerCanMintMax) {
 
    //Payment splitter receive payments and split them between ABC Vault and Igniter
    abcPayment = _splitter;
    _setDefaultRoyalty(abcPayment, 1000); //Royalties must be paid directly to abcPayment.  
    _initialMint(_vault);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC2981, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  /* @dev: Direct payments to the contract not covered by a specific function 
   * Emit a paymentReceived Event*/
  receive() external payable  {      
    emit PaymentReceived(_msgSender(), msg.value);

  }
  /* @dev: Mints one or more NFTs up to the maximum specified in maxMinting.
   * The function call is signed, so it can only be called from the CLUB web site.
   * @params:
   * _to the owner of the minted tokens
   * _referrer, address of referrer or address(0)
   * _tokenIds, array with token to be minted
   * _cost, total cost of minting _tokenIds.
   * _msgHash, obtained from concatenating _to, _referrer, ids, _cost
   * _signature, signature of the transaction
   * The execution is interrupted if: the contract is paused, if it was not specified which tokenIds want to be minted; 
   * if _cost parameter is 0.
   * If it is intended to mint more than maxMinting in the function call; If all NFTs representing claims on the 
   * total numbered asteroids already incorporated (maxSupply) have been minted; If it is not minting by strategic agreement 
   * but the maxToSale limit was reached; If the amount transferred in the call is greater than zero but different from _cost; 
   * If the amount is zero but there are no funds in either agreements or kickStarter covering the cost;  
   * Or if simultaneously with the call the asteroid was already claimed.
   * 
   */
  function mint(address _to, address _referrer, uint256[] memory _tokenIds, uint256 _cost,  bytes32 _msgHash, bytes memory _signature) external payable {

    uint256 __realMaxToSale = maxToSale - (beltersDayMax-beltersDayMinted); //Belter's Day raffles must be reserved
    bool __agreement=false;

    _checkPaused();
    require(_tokenIds.length >0, "Specify at least one tokenId");
    require(_cost >0, "Direct mint for free not allowed");
    require(_tokenIds.length <= maxMinting,string(abi.encodePacked("Mint no more that 10 per call")));
    require(totalSupply() + _tokenIds.length < maxSupply, "Currently no NFT left to mint");

    if(getAgreementBalance(_msgSender()) < _cost || msg.value > 0 ) {
      require((totalSupply() + _tokenIds.length - agreementMinted) <= __realMaxToSale, "Currently no NFT left to mint");
    }

    require(msg.value==0 || msg.value==_cost, string(abi.encodePacked("Amount invalid ",_cost.toString())));

    
    string memory __implodedIds=Utils.implodeIds(_tokenIds);
    bytes memory __rawMsg = abi.encodePacked(Strings.toHexString(uint256(uint160(_to)), 20),Strings.toHexString(uint256(uint160(_referrer)), 20),__implodedIds,_cost.toString());
    _checkSignature(__rawMsg, _msgHash, _signature);
 
    /*Chequeo de los fondos con los que se hace el minteo */
    if(msg.value==0 && getKickStartBalance(_msgSender()) >= _cost) {
      updateKickStartBalance(_cost,_tokenIds.length);
    }
    else if(msg.value==0 && getAgreementBalance(_msgSender())>=_cost) {

      require(maxToSale/10 >= agreementMinted + _tokenIds.length, "Agreement threshold reached. Try later "  );
      require(totalSales/10 >= agreementUsed + _cost || totalSupply() > 500000, "Agreement threshold reached. Try later "  );
      updateAgreementBalance(_cost,_tokenIds.length);
      __agreement=true;
    }
    else {
      require(msg.value == _cost,string(abi.encodePacked("Must send ", _cost.toString())));
    }

    if(msg.value >0) {
      _registerTotal(msg.value);
      if(_referrer != address(0)){
        _referrerPay(_referrer,msg.value);
      }
    }
    _mint(_to,_tokenIds.length,__agreement, _tokenIds,false);

  }

  /* @dev: It randomly mints up to n tokens specified in amount using the tokens specified in tokenIds as a base.   
   * The msgHash is the hash of the message obtained by concatenating _to, implode _tokenIds, _amount, _cost, 
   * _uniqid and _expiration _signature is the signature of the msgHash signed with the private key of _signatureWallet.
   * @params:
   * _to: Beneficiary address
   * _referrer: address of the referrer or address(0)
   * _amount: quantity of nft to be minted
   * _tokenIds: randomly generated ids. One or more of them will also be chosen at random.
   * _cost: the total cost of the claim. 
   * _uniqid: a unique identifier that prevents the randomly generated list from being used more than once.
   * _expiration: timestamp after which the signature that validates the parameters of the function call expires and prevents manipulation of the random choice.
   * _msgHash: obtained from concatenating _to, _referrer, _amount, _cost, _uniqid and _expiration
   * _signature: signature of the transaction
   * The execution is interrupted if: contract is paused; random tokenlist is invalid; _amount > maxMinting; maxSupply reached; 
   * cost == 0 (only possible when claim is from Belter's Day winner) but beltersDayMax was previously reached
   * cost == 0 (only possible when claim is from Belter's Day winner) but _amount greather than 1;
   * if it is not minting by strategic agreement but the maxToSale limit was reached;
   * if msg.value >0 but is not equal to _cost
   * if Signature already used, or expired.
   * If something was wrong and the randomly choosen token was already minted
   * 
   */
  function random(address _to, address _referrer, uint256 _amount, uint256[] memory _tokenIds, uint256 _cost, string memory _uniqid, uint32 _expiration, bytes32 _msgHash, bytes memory _signature) external payable {
    bool __agreement=false;
    uint256 __realMaxToSale = maxToSale - (beltersDayMax-beltersDayMinted); //Belter's Day raffles must be reserved

    _checkPaused();
    require(_tokenIds.length==200, "Invalid tokenlist");
    require(_amount >0 && _amount <= maxMinting,string(abi.encodePacked("Max mint 10 per call")));
    require(totalSupply() + _amount < maxSupply, "No NFT left to mint");

    if(beltersDayMax-beltersDayMinted==0) {
      require(_cost >0, "Belters Day total reached");
    }

    if(_cost==0) {
      //Only Belter's Day winner can mint for free but only one. 
      require(_amount==1,"Only one to mint if it for free");
      beltersDayMinted++;
    }

    if((_cost >0 && getAgreementBalance(_msgSender()) < _cost) || msg.value > 0 ) {
      require((totalSupply() + _amount - agreementMinted) <= __realMaxToSale, "Currently no NFT left to mint");
    }
    require(msg.value==0 || msg.value==_cost, string(abi.encodePacked("Transfer ",_cost.toString())));

    /* Signature Checking */
    require(_usedUniqids[_uniqid]==false, "Signature already used");
    require(_expiration > block.timestamp, "Signature expired");
    string memory __implodedIds=Utils.implodeIds(_tokenIds);
    bytes memory __rawMsg = abi.encodePacked(Strings.toHexString(uint256(uint160(_to)), 20),Strings.toHexString(uint256(uint160(_referrer)), 20),__implodedIds,_amount.toString(), _cost.toString(),_uniqid,Strings.toString(_expiration));
    _checkSignature(__rawMsg, _msgHash, _signature);
    _usedUniqids[_uniqid]=true;

    /* kickstartBalance or agreementBalance or msg.value source */
    if(msg.value==0 && getKickStartBalance(_msgSender()) >= _cost) {
      updateKickStartBalance(_cost,_amount);
    }
    else if(msg.value==0 && getAgreementBalance(_msgSender())>=_cost) {

      require(totalSales/10 >= agreementUsed + _cost || totalSupply() > 500000, "Agreement threshold reached. Try later "  );      
      require(maxToSale/10 >= agreementMinted + _amount, "Agreement threshold reached. Try later "  );
   
      updateAgreementBalance(_cost,_amount);
      __agreement=true;
    }
    else {
      require(msg.value == _cost,string(abi.encodePacked("To do this mint you must send ", _cost.toString())));
    }
  
    if(msg.value >0) {
      _registerTotal(msg.value);
      if(_referrer != address(0)){
        _referrerPay(_referrer,msg.value);
      }      
    }
    
    _mint(_to,_amount,__agreement, _tokenIds,true);
  }

  /* @dev: internal function called to mint direct or random */
  function _mint(address _to, uint256 _amount, bool _agreement, uint256[] memory _tokenIds, bool _random) private {
    uint256 __tokenId=0;
    for(uint256 i=0; i<_amount; i++) {
      if(_random){
      __tokenId=_getRandomTokenFromList(__tokenId, _tokenIds);
      }
      else {
        __tokenId=_tokenIds[i];
        require(!_exists(__tokenId), "Token already minted ");      
      }
      if(_agreement) {
        updateTokensMinted(__tokenId);
      }
      _safeMint(_to,__tokenId);     
    }
  }

 
  /* Developed using Hashlips (https://github.com/HashLips) and another sources as examples. */
  function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  /* @dev: Returns the URI of the token. If the asteroid was renamed by the Asteroid Naming Service 
   * then the URI returned will be the one corresponding to the modified manifest.
   * Developed using Hashlips (https://github.com/HashLips) and another sources as examples. 
   */
  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    string memory currentBaseURI = _baseURI();
    if(bytes(_ansModifiedURI[tokenId]).length >0) {
      return _ansModifiedURI[tokenId];
    }
    else {
      return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
    }
  }

  /* @dev: Checks if the NFT _tokenId has full rights in the DAO. */
  function hasDaoRights(uint256 tokenId) public view returns(bool) {
    require(_exists(tokenId), "Token not minted");
    if(agreementTokens[tokenId] != address(0)) return(false);
    return(true);
  }


  /* @dev: If it possible by agreement, and msg.value equals to agreement.befull * _votes _tokenId convert owner to a full member of the CLUB 
   */

  function giveMeDaoRights(uint256 _tokenId, uint256 _votes, string memory _uniqid, uint32 _expiration, bytes32 _msgHash, bytes memory _signature) public payable {        
    require(_exists(_tokenId), "Token not minted");
    require(agreementTokens[_tokenId] != address(0), "Token already have full rights");
    agreement memory _agreement=getAgreement(agreementTokens[_tokenId]);
    require(_agreement.befull>0, "Agreement don't allow improve token rights");

    require(_usedUniqids[_uniqid]==false, "Signature already used");
    require(_expiration > block.timestamp, "Signature expired");

    bytes memory __rawMsg = abi.encodePacked(_tokenId.toString(),_votes.toString(),_uniqid,Strings.toString(_expiration));
    _checkSignature(__rawMsg, _msgHash, _signature);
     _usedUniqids[_uniqid]=true;
    uint256 __cost=_agreement.befull*_votes;
    require(msg.value==__cost,string(abi.encodePacked("You must send ", __cost.toString()," to get full rights")));
    delete agreementTokens[_tokenId];
    emit RightsUpgraded(_tokenId);
  }



  /* @dev: Transfer funds to the Payment Splitter
   * The function remains public for anyone to initiate transfers, which prevents funds 
   * from being held hostage in the contract, in case of discrepancies between the final 
   * beneficiaries of the funds. The function remains public so that anyone can initiate transfers, 
   * which prevents funds from being held hostage in the contract, in case of discrepancies between 
   * the final beneficiaries of the funds.
   *
   * Since PaymentSplitter is invariant after the contract is launched, and the funds cannot be sent 
   * to any other address, it is safe for the function to remain public.
   *
   * Subtract from the transferable balance the outstanding amounts to be paid to the referrers.
   * 
   */
  function withdraw() public {
    address payable __to=payable(abcPayment);      
    uint256 __available=(address(this).balance-_referrersPending());
    require(__available >0,"Insuficient funds");
    __to.transfer(__available);
    emit Withdrawn(_msgSender(),__available);
  }

  /* @dev: Returns the referral balance of the queried _referrer address */
  function referrerBalance(address _referrer) public view returns(uint256){
    return _referrerBalance[_referrer];
  }

  /* If the msgSender has a balance, 
   * calling the function initiates the withdrawal to your wallet of the available balance generated with the referral program.
   * if referrer didn't whidthrawn after 1 year of it's  first payment or last widthraw we can revert payment or last cancel Payment
   */
  function referrerWidthraw(address _referrer) public {
    uint256 __available=_referrerBalance[_referrer];
    require(__available >0, "Insuficient funds");
    _referrerBalance[_referrer]=0;
    referrersWidthrawn=referrersWidthrawn+__available;
    if(_msgSender()==_signatureWallet) {
      emit ReferrerCanceled(_referrer,__available);
    }
    else {
      payable(_referrer).transfer(__available);
      emit ReferrerWidthraw(_referrer,__available);
    }

  }

  /* @dev: Overwrite the token URI to reflect changes made from the Asteroid Naming Service (ANS). 
   * Until the service is available this function cannot be used. The function cannot be used more 
   * than once per token. ANS will not call this function if the asteroid was named by the IAU.
   */
  function ansSetNewURI(uint256 _tokenId, address _owner, string memory _newURI) public {
    require(ownerOf(_tokenId)==_owner, "Not the owner");
    require(_msgSender() == _ansAddress, "Only Asteroid Naming Services can call that function");
    require(_exists(_tokenId), "Token not yet minted");
    require(bytes(_newURI).length >0, "Please set a new URI");
    require(bytes(_ansModifiedURI[_tokenId]).length==0, "Token already named");
    _ansModifiedURI[_tokenId]=_newURI;
    emit URIChanged(_tokenId, _newURI);
  }





  /* @dev: Set the base URI   */
  function setBaseURI(string memory _newBaseURI) public onlyOwner {      
    baseURI = _newBaseURI;
  }

  /* @dev: Pause and restart minting functions */
  function pause(bool _state) public onlyOwner {
    paused = _state;
    emit StateChanged(_state);
  }

  function _checkPaused() internal view  override {
    require (!paused , "Contract paused");
  }

  /* @dev: Update maxSupply and maxToSale
   * maxSupply represents the highest number of asteroids numbered by the IAU. Periodically ABC Starter 
   * will update the maxSupply, and generate the files available to be claimed. In case the maximum amount 
   * to be offered to the market has been reached, they can only be claimed through strategic agreements.
   * After initial offer maxToSale will never be more than 9/10 of maxSupply.
   */
  function setMaxSupply(uint256 _newMaxSupply) public onlyOwner {
    require(_newMaxSupply > maxSupply, "New max supply must be greather than current");
    uint256 __oldMaxSupply=maxSupply;
    maxSupply=_newMaxSupply;
    maxToSale=maxSupply*90/100;
    emit NewMaxSupply(__oldMaxSupply, maxSupply);
  }
 

  /* @dev: Allows to configure the address that signs the messages in mint, random and kickstart.*/
  function setSignatureWallet(address _newWallet) public onlyOwner {
    require(_newWallet != address(0), "Set Valid Address");
    _signatureWallet=_newWallet;
  }

  /* @dev: To be used to configure the ANS wallet address. */
  function setAnsAddress(address _newAddress) public onlyOwner {
    _ansAddress=_newAddress;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  /* @dev: Calculates the total amount due to referrers */
  function _referrersPending() private view returns (uint256) {
    return referrersPaid-referrersWidthrawn;
  }

  function _checkSignature(bytes memory _raw, bytes32 _msgHash, bytes memory _signature) internal view override {
    Utils.SignatureCheck(_raw, _msgHash, _signature, _signatureWallet);
  }


  /* @dev: Register a new fund entry by mint, random or kickstarter */
  function _registerTotal(uint256 amount) internal override {
    totalSales=totalSales+amount;
    emit PaymentReceived(_msgSender(), amount);
  }

  /* @dev: Adds the commission generated by the referral program to the referrer's account*/
  function _referrerPay(address _referrer, uint256 _amount) internal override {
    referrersPaid=referrersPaid+((_amount*referrerFee)/referrerFeeDenominator);
    _referrerBalance[_referrer]=_referrerBalance[_referrer]+((_amount*referrerFee)/referrerFeeDenominator);
    emit ReferrerPaid(_referrer, ((_amount*referrerFee)/referrerFeeDenominator));
  }


  /* @dev: generate CERES token and transfer it to vault. Mint ownerInitialMinting NFTs and transfer it to Igniter */
  function _initialMint(address _abcVault) private {
    uint256 __tokenId=0;
    _safeMint(payable(_abcVault),1);
    for(uint16 i=0; i<ownerInitialMinting; i++){
      __tokenId=_getRandomTokenId(__tokenId);
      _safeMint(_msgSender(),__tokenId);     
    }      
  }

  /* @dev: get a randomly chosen token Id from list. Used in random mint mint */
  function _getRandomTokenFromList(uint256 _seed, uint256[] memory _ids) private view returns (uint256) {
    uint256 __tokenId=_ids[Utils.RandomGenerate(0,_ids.length -1,_seed)];
    uint16 __iterations=0;
    while(_exists(__tokenId)) {
      __tokenId=_ids[Utils.RandomGenerate(0,_ids.length -1,__tokenId)];
      __iterations++;
      require(__iterations < 10, "An error occurs. Please retry");         
    }
    return(__tokenId);

  }
  /* @dev: get a randomly chosen token Id from total. Used in initial mint */
  function _getRandomTokenId(uint256 _seed) private view returns (uint256) {
    uint256 __tokenId=Utils.RandomGenerate(2,maxToSale,_seed);
    uint16 __iterations=0;
    while(_exists(__tokenId)) {
      __tokenId=Utils.RandomGenerate(2,maxToSale,__tokenId);
      __iterations++;
      require(__iterations < 10, "An error occurs. Please retry");
    } 
    return __tokenId;
  }
}