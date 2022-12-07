// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// region MainLab

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

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{ value: amount }("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{ value: value }(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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
    function sqrt(uint256 a, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = sqrt(a);
            return
                result +
                (rounding == Rounding.Up && result * result < a ? 1 : 0);
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
    function log2(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log2(value);
            return
                result +
                (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
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
    function log10(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log10(value);
            return
                result +
                (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
    function log256(uint256 value, Rounding rounding)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 result = log256(value);
            return
                result +
                (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
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
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
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
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );

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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: caller is not token owner or approved"
        );
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
        require(
            _checkOnERC721Received(from, to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId) == spender);
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
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );

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
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721.balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );
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
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < ERC721Enumerable.totalSupply(),
            "ERC721Enumerable: global index out of bounds"
        );
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
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId)
        private
    {
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

// library MerkleProof {
//     /**
//      * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
//      * defined by `root`. For this, a `proof` must be provided, containing
//      * sibling hashes on the branch from the leaf to the root of the tree. Each
//      * pair of leaves and each pair of pre-images are assumed to be sorted.
//      */
//     function verify(
//         bytes32[] memory proof,
//         bytes32 root,
//         bytes32 leaf
//     ) internal pure returns (bool) {
//         return processProof(proof, leaf) == root;
//     }

//     /**
//      * @dev Calldata version of {verify}
//      *
//      * _Available since v4.7._
//      */
//     function verifyCalldata(
//         bytes32[] calldata proof,
//         bytes32 root,
//         bytes32 leaf
//     ) internal pure returns (bool) {
//         return processProofCalldata(proof, leaf) == root;
//     }

//     /**
//      * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
//      * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
//      * hash matches the root of the tree. When processing the proof, the pairs
//      * of leafs & pre-images are assumed to be sorted.
//      *
//      * _Available since v4.4._
//      */
//     function processProof(bytes32[] memory proof, bytes32 leaf)
//         internal
//         pure
//         returns (bytes32)
//     {
//         bytes32 computedHash = leaf;
//         for (uint256 i = 0; i < proof.length; i++) {
//             computedHash = _hashPair(computedHash, proof[i]);
//         }
//         return computedHash;
//     }

//     /**
//      * @dev Calldata version of {processProof}
//      *
//      * _Available since v4.7._
//      */
//     function processProofCalldata(bytes32[] calldata proof, bytes32 leaf)
//         internal
//         pure
//         returns (bytes32)
//     {
//         bytes32 computedHash = leaf;
//         for (uint256 i = 0; i < proof.length; i++) {
//             computedHash = _hashPair(computedHash, proof[i]);
//         }
//         return computedHash;
//     }

//     /**
//      * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
//      * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
//      *
//      * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
//      *
//      * _Available since v4.7._
//      */
//     function multiProofVerify(
//         bytes32[] memory proof,
//         bool[] memory proofFlags,
//         bytes32 root,
//         bytes32[] memory leaves
//     ) internal pure returns (bool) {
//         return processMultiProof(proof, proofFlags, leaves) == root;
//     }

//     /**
//      * @dev Calldata version of {multiProofVerify}
//      *
//      * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
//      *
//      * _Available since v4.7._
//      */
//     function multiProofVerifyCalldata(
//         bytes32[] calldata proof,
//         bool[] calldata proofFlags,
//         bytes32 root,
//         bytes32[] memory leaves
//     ) internal pure returns (bool) {
//         return processMultiProofCalldata(proof, proofFlags, leaves) == root;
//     }

//     /**
//      * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
//      * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
//      * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
//      * respectively.
//      *
//      * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
//      * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
//      * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
//      *
//      * _Available since v4.7._
//      */
//     function processMultiProof(
//         bytes32[] memory proof,
//         bool[] memory proofFlags,
//         bytes32[] memory leaves
//     ) internal pure returns (bytes32 merkleRoot) {
//         // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
//         // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
//         // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
//         // the merkle tree.
//         uint256 leavesLen = leaves.length;
//         uint256 totalHashes = proofFlags.length;

//         // Check proof validity.
//         require(
//             leavesLen + proof.length - 1 == totalHashes,
//             "MerkleProof: invalid multiproof"
//         );

//         // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
//         // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
//         bytes32[] memory hashes = new bytes32[](totalHashes);
//         uint256 leafPos = 0;
//         uint256 hashPos = 0;
//         uint256 proofPos = 0;
//         // At each step, we compute the next hash using two values:
//         // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
//         //   get the next hash.
//         // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
//         //   `proof` array.
//         for (uint256 i = 0; i < totalHashes; i++) {
//             bytes32 a = leafPos < leavesLen
//                 ? leaves[leafPos++]
//                 : hashes[hashPos++];
//             bytes32 b = proofFlags[i]
//                 ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]
//                 : proof[proofPos++];
//             hashes[i] = _hashPair(a, b);
//         }

//         if (totalHashes > 0) {
//             return hashes[totalHashes - 1];
//         } else if (leavesLen > 0) {
//             return leaves[0];
//         } else {
//             return proof[0];
//         }
//     }

//     /**
//      * @dev Calldata version of {processMultiProof}.
//      *
//      * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
//      *
//      * _Available since v4.7._
//      */
//     function processMultiProofCalldata(
//         bytes32[] calldata proof,
//         bool[] calldata proofFlags,
//         bytes32[] memory leaves
//     ) internal pure returns (bytes32 merkleRoot) {
//         // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
//         // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
//         // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
//         // the merkle tree.
//         uint256 leavesLen = leaves.length;
//         uint256 totalHashes = proofFlags.length;

//         // Check proof validity.
//         require(
//             leavesLen + proof.length - 1 == totalHashes,
//             "MerkleProof: invalid multiproof"
//         );

//         // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
//         // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
//         bytes32[] memory hashes = new bytes32[](totalHashes);
//         uint256 leafPos = 0;
//         uint256 hashPos = 0;
//         uint256 proofPos = 0;
//         // At each step, we compute the next hash using two values:
//         // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
//         //   get the next hash.
//         // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
//         //   `proof` array.
//         for (uint256 i = 0; i < totalHashes; i++) {
//             bytes32 a = leafPos < leavesLen
//                 ? leaves[leafPos++]
//                 : hashes[hashPos++];
//             bytes32 b = proofFlags[i]
//                 ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++]
//                 : proof[proofPos++];
//             hashes[i] = _hashPair(a, b);
//         }

//         if (totalHashes > 0) {
//             return hashes[totalHashes - 1];
//         } else if (leavesLen > 0) {
//             return leaves[0];
//         } else {
//             return proof[0];
//         }
//     }

//     function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
//         return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
//     }

//     function _efficientHash(bytes32 a, bytes32 b)
//         private
//         pure
//         returns (bytes32 value)
//     {
//         /// @solidity memory-safe-assembly
//         assembly {
//             mstore(0x00, a)
//             mstore(0x20, b)
//             value := keccak256(0x00, 0x40)
//         }
//     }
// }

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */

library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// endregion

contract Epiddha is ERC721Enumerable, IERC2981, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _nextTokenId;

    constructor() ERC721("Epiddha", "EPI") {
        customBaseURI = "http://epiddha.io/nft/metadata/";
        allowedMintCountMap[0x6DF916b50EcAA4A6add5fFfDaAdC80B1B757CEf3] = 30;
        allowedMintCountMap[0x34b0EfE74aE1FB54343e4A4AC5F05c2d34A33f8B] = 30;
        allowedMintCountMap[0xE54FeC8f28c1705EE3F42d203D3fF5aF6aD52893] = 30;
        allowedMintCountMap[0x1d41D6B1091C1a8A334096771bd1776019243d5e] = 30;
        allowedMintCountMap[0x67592072be349f16622986ec18E6b2c54c5fcC0d] = 20;
        allowedMintCountMap[0xC0c2e5D7E4d59b63B25f6cc9fCb7c52c76e981f9] = 1;
        allowedMintCountMap[0xEC1fFF8e6E519B21b2bd7d8a6E9803A21b7eDcec] = 1;
        allowedMintCountMap[0x82E6b17b47dc6f96E29392256370C5745ED71ADa] = 1;
        allowedMintCountMap[0x4Cd0A6Bc401b728e2977dc352eB72A50156E123B] = 1;
        allowedMintCountMap[0x5A9999171AF407298b1Cc9993f779a1eD94768E1] = 1;
        allowedMintCountMap[0x7988e87F9B4aDf9C2D6b6ED79A11B088681bAeaE] = 1;
        allowedMintCountMap[0xB6e82950B2D6FB64BB35b61456B90D103087D796] = 1;
        allowedMintCountMap[0xd4dFf494527500241126DDF910a0b21fe09D6990] = 1;
        allowedMintCountMap[0xc6cC81f525eA2232F451e765e86959E37C376fEF] = 1;
        allowedMintCountMap[0xec7978fc8c9C5Cb718F096e10801648f53f0dd95] = 1;
        allowedMintCountMap[0xea012B4394cBc5cBD592B8998e979E7b51617f46] = 1;
        allowedMintCountMap[0x600aA0E703f7bEA5FFE2344da9aB037eF83118E5] = 1;
        allowedMintCountMap[0x1E126C22b765760aB283De230891F76b3A7c35A3] = 1;
        allowedMintCountMap[0x6c2608bc3d87637dfa1e38dEa49a0a426d8206AA] = 1;
        allowedMintCountMap[0xcEA048974d1D8394AB5fb0d66B53C23B1794EeCb] = 1;
        allowedMintCountMap[0x09c25858D90b63FE8F2F225322B314ec802E153A] = 1;
        allowedMintCountMap[0x5bEF493EFC3aCC42F3c6Af93Cd942c7A2FC520Fb] = 1;
        allowedMintCountMap[0x3D971E8D2eD8c0B43bb91215DbF9a3d6Def2267c] = 1;
        allowedMintCountMap[0x61324B5db9e3f99123a9B5794e8898783FcB1e3a] = 1;
        allowedMintCountMap[0x33D035283F2e58ed0670731a7971B05ba36Fb0a1] = 1;
        allowedMintCountMap[0xeF15d4d1fB0B26CC4158087963E183f41c38AbF1] = 1;
        allowedMintCountMap[0x51F5B0F48843E37044f35f5c75e6bD7E4d7568Ad] = 1;
        allowedMintCountMap[0x1234287b487e9df877337b66AA9306045ACE557e] = 1;
        allowedMintCountMap[0x13f19C81C97CE9d9C91dCd6CdbA50F1484AEC370] = 1;
        allowedMintCountMap[0xB818EE8102e566207d32217CD38aCb6A9211007b] = 1;
        allowedMintCountMap[0x2c81EFd9C410678217e22435F070ddc998EB0D75] = 1;
        allowedMintCountMap[0x26426AA335BB400c1fE8C32CF9eCCB65fa321Bd3] = 1;
        allowedMintCountMap[0x8aB092F018C1C36cCc8176ca601510120c70B6C9] = 1;
        allowedMintCountMap[0x1dcb20Adf398062BC861CFAFe8b72f26cc365686] = 1;
        allowedMintCountMap[0x0b0E075bFD7a7519A57A7BdFb1ccA366F362901c] = 1;
        allowedMintCountMap[0xB27e4958954d8b5B9FFAebf416AE235235CdE651] = 1;
        allowedMintCountMap[0x5D4207c8a59756dC23d99aC42CeFF0e2DFEf4064] = 1;
        allowedMintCountMap[0x4D8563A0c8761b56edBBD926bb844ADaca7A2cA6] = 1;
        allowedMintCountMap[0x5dD033716ED8293638deE697C08c7Dc107aC818C] = 1;
        allowedMintCountMap[0x0Dc9B90425ab8DAeAE34B961c69c974072321dC4] = 1;
        allowedMintCountMap[0xC59918bfC0eEA90bb664d6D2F9A71FC1DCCE0Ae3] = 1;
        allowedMintCountMap[0x7972CEC35cAeb514B24B811cb338BAeaD3341ff9] = 1;
        allowedMintCountMap[0xca85b2cdd59726F60D85e7B8bfA86a66ceE3ee68] = 1;
        allowedMintCountMap[0xf0f89A8B93e9093B999A92457E012350ef78Bee0] = 1;
        allowedMintCountMap[0x9D0281fE2cC6C271525F1fB21C08580ea3d38FC1] = 1;
        allowedMintCountMap[0xc5616e5A7b707b715Ee0e71291e7F6C17E345030] = 1;
        allowedMintCountMap[0x0DE30115A4B0D10B0e156daf07625eDA72B10010] = 1;
        allowedMintCountMap[0x4Df25F8ad2b1cd4fa985A78ee7DF0f4C00dc091d] = 1;
        allowedMintCountMap[0x02a2FEea6338aeBd9488c58F827d85054a71e65c] = 1;
        allowedMintCountMap[0x6Ec3951505f4f38e5E3e42be06F3877B375e1bFc] = 1;
        allowedMintCountMap[0xc02Aa80d6FbE85B78d7b34039B80315fD0376dDC] = 1;
        allowedMintCountMap[0xcDb00df61fAB72C6c1A1D757176E20B2583a844E] = 1;
        allowedMintCountMap[0x7D41abfD292a51b5aD1D346B592128f94d17fCBC] = 1;
        allowedMintCountMap[0xe8111e939364bb675BA2cECBdd253130D79e023e] = 1;
        allowedMintCountMap[0x665Df2dfc3B6F26E6803E85B917AEE629eBd4C75] = 1;
        allowedMintCountMap[0xe3037515524469Fbe2d521f750A3264C07EE811b] = 1;
        allowedMintCountMap[0x683aDa75FA2e795A8e134690c424A37dA5E570A0] = 1;
        allowedMintCountMap[0x5D964eC9b24236AE2Bd51e851338704AfB358A85] = 1;
        allowedMintCountMap[0xe28E4446494A667C71EE12798374B6F9D127e606] = 1;
        allowedMintCountMap[0xf167e383fE4Ed877e28e42f74F46F8A17061E4C7] = 1;
        allowedMintCountMap[0x1e7d1ad7FE2372eF64Bd4238d47891f675C75425] = 1;
        allowedMintCountMap[0x308bdB076678502a5407f7483AbbBFf7f1B8Ea68] = 1;
        allowedMintCountMap[0x91341D437DeafFF9CDe16a8b79fF58F997e5A0DB] = 1;
        allowedMintCountMap[0x01ed25CA4d5c728226d15149a4BfC622aCce64A7] = 1;
        allowedMintCountMap[0xebB1220E79Bd6fe01489Ee4eb5C419485582FE8B] = 1;
        allowedMintCountMap[0xd0943ED25bFA2e5a847D1A637d5b355aF334ccC7] = 1;
        allowedMintCountMap[0xca08542FB2C5aB11D406070ef7C29C0cfc2a2AD8] = 1;
        allowedMintCountMap[0xE8fe36bdA624f2b09322a81c1Ba25A4328fCae78] = 1;
        allowedMintCountMap[0xB55be0842771DaAB7Fbf6662C1bcD0B512D9A20a] = 1;
        allowedMintCountMap[0x00794b7B900165F452e2b02cC191e6b8B6F8F869] = 1;
        allowedMintCountMap[0xb8067570EE1c208EE9E4C61cF2E98cb882c1779E] = 1;
        allowedMintCountMap[0x5B8687f15C3eDBa87551787e2C7f68931F8f9074] = 1;
        allowedMintCountMap[0x271f971A031F30f9869D6B8835313b3e5939Cc9C] = 1;
        allowedMintCountMap[0x61560Fb79242A875408667353998db29153DaAFD] = 1;
        allowedMintCountMap[0x483Bc954aB5D1Ac43D743AbC847595303E0884F2] = 1;
        allowedMintCountMap[0x6063a4f96dC0b302A801A41BbeD9fd439f18BBEc] = 1;
        allowedMintCountMap[0x24a7750D542c9322112C84F5192fbbea0295De7D] = 1;
        allowedMintCountMap[0xFd60aFC70AA37d66737c2EFd06165550d41E88b9] = 1;
        allowedMintCountMap[0xF9c1f445736229680dF68f85b1F6c22E627A3f48] = 1;
        allowedMintCountMap[0xb8C52a4654DC0E8184a352755c30F8955B83e1B8] = 1;
        allowedMintCountMap[0x08d7eF7E2539F86Da7EDd1B993389935712D015D] = 1;
        allowedMintCountMap[0xb72616e80b0dEd8EEb9F642c24E651ddF5D96D6f] = 1;
        allowedMintCountMap[0x5801A83A13499B18eD301abb18D21fc7eB9844b5] = 1;
        allowedMintCountMap[0xD3bFCD76F8278a9e449AaeEC2cB2DFD2cFD215A5] = 1;
        allowedMintCountMap[0xb2973b2d1C150ACce90c7fc1cD5094261CbfdFaC] = 1;
        allowedMintCountMap[0x4721ef94251577691B641bB85030Be2287a46D18] = 1;
        allowedMintCountMap[0xd88cCdB3C32bA2654c21764408F0584676Ad4B23] = 1;
        allowedMintCountMap[0xe699985A927f73d44D06a1E996778E25db84130f] = 1;
        allowedMintCountMap[0x648198e33CED71AdbE3e7080C6e5Fa4De3590B76] = 1;
        allowedMintCountMap[0xd07898A7a44e93c9b1CD1C08A131C46451eb80A7] = 1;
        allowedMintCountMap[0xBB973F31Aa80C3B0e50741124C454ee44A09cf47] = 1;
        allowedMintCountMap[0xcF8D75809E9Cf0dC2D4D0eDeE65e87EB8005c3F4] = 1;
        allowedMintCountMap[0x23C7E5B1AD818F47b11d2E2dB65951A63D6Bcb7c] = 1;
        allowedMintCountMap[0x1A7e84f0cADa599E218C812E9aF0eFC5FF7FFE1C] = 1;
        allowedMintCountMap[0x06be64300CBD67aB0235176c76DAE2Bd99774fd0] = 1;
        allowedMintCountMap[0xdaD0c5b772B4bd0a4839C669cf1e95973779F0a7] = 1;
        allowedMintCountMap[0xBEe643FD4e58b2a4fd05685157F30aD9a5805e62] = 1;
        allowedMintCountMap[0x3ef6DF5BcC8B21227Dd8cEE92933592867ECfEa5] = 1;
        allowedMintCountMap[0xb06b0E1F00FE3Cf4c8Afd6D31d702Ebae6585eeF] = 1;
        allowedMintCountMap[0x839Bdf02465933A6a81356F9a48a9199b847DC70] = 1;
        allowedMintCountMap[0xB7572926ECc5937648f5FF2bB831A76cf6515A45] = 1;
        allowedMintCountMap[0x87bD9bFd74f995b52b8a498B41004dA2d4102645] = 1;
        allowedMintCountMap[0x4dEEA126bE27C80372C7e3a013EE1874188AC521] = 1;
        allowedMintCountMap[0xeCFbC7Ea4527A5326a07B26654B1601edcaf63B7] = 1;
        allowedMintCountMap[0x59E2fbA1B76F5fDA66Ee1fB64dd1c933203170Da] = 1;
        allowedMintCountMap[0xea4F5679Ab286d502016De868019a5A47629Abf6] = 1;
        allowedMintCountMap[0x531e2B80962557d0F170e4D55a41A1D59577e448] = 1;
        allowedMintCountMap[0x5779721C386bDd24FCF4AC144B8Ac463525D48CB] = 1;
        allowedMintCountMap[0x91e1265E1346390F9bdeA99E03bB8068eCF1ED39] = 1;
        allowedMintCountMap[0xEc6B015F5c023056d610C71316F0D4e244a716F2] = 1;
        allowedMintCountMap[0x830011E3BD0A6c68d7444C03a58E9Af6849A54dD] = 1;
        allowedMintCountMap[0x3a33F96D7dA0831b3FeffE46041510f0AEA9a2d8] = 1;
        allowedMintCountMap[0x8A652f9C667AEa7ab752703D50e8085dD535c772] = 1;
        allowedMintCountMap[0xaA18E269df3179DC4bfffd22CD87e1e97Ead6Da4] = 1;
        allowedMintCountMap[0xEEf563b5010D5B7af6f095757bf616f7e379A682] = 1;
        allowedMintCountMap[0xcF14F4Ae13E6C24f764F9Bc5d8C463562BB1498A] = 1;
        allowedMintCountMap[0x132a4945268148eCAf29D307c25766d9bD7e650D] = 1;
        allowedMintCountMap[0x64684587C187Ab56908785379bD1da5EcE619bb7] = 1;
        allowedMintCountMap[0x48693e852fcAe08711c92Ba129d1CcEd68448DfA] = 1;
        allowedMintCountMap[0x17dD29B5C7b6eD64eE4b320BedDe9A73a08979a1] = 1;
        allowedMintCountMap[0xa9C7144Bf6a17953DE1A327260e2AA37AD4561cE] = 1;
        allowedMintCountMap[0x7F588cC9Da18fAD315267054D173b2494888E873] = 1;
        allowedMintCountMap[0x4746D74127C272A144746a1f6acc1ad127A13801] = 1;
        allowedMintCountMap[0xC44d28D395EA961489991A85a4916c45f40912fd] = 1;
        allowedMintCountMap[0x60A1205A12F067c2F34025D111AB50F177682260] = 1;
        allowedMintCountMap[0xc944702447aa8BCb654FcB0937936778D086550f] = 1;
        allowedMintCountMap[0x2A3246975a0f32D0a78B90dd43a7AB8B1BA9A522] = 1;
        allowedMintCountMap[0xADDA95d3216336B3f7D5E7f94e94CB7988f498d0] = 1;
        allowedMintCountMap[0x4202Be88a1383BA719d8799e599A033967AbaeD4] = 1;
        allowedMintCountMap[0xb5ad42578F6A2B54c89901D09CE61149aef0B306] = 1;
        allowedMintCountMap[0x18cb209CEB60EeF8Be62e6F990d6B8b1A5303E28] = 1;
        allowedMintCountMap[0x78D77ACee2E154bA6A9ed28Fa40b768E09b3D804] = 1;
        allowedMintCountMap[0x449Edd96266072545CF143Fdfdd19c990c3d2BAc] = 1;
        allowedMintCountMap[0x673CDbFEf2642959E6B36Dde25c20b92952059D1] = 1;
        allowedMintCountMap[0x733D6295dbB57ca1f680fcbc00C128276237e759] = 1;
        allowedMintCountMap[0x3c34BD86fca5dCBf187FC9389012979990389c69] = 1;
        allowedMintCountMap[0x2Df095eD98b0Fd1FD6C2318585866d1459D86342] = 1;
        allowedMintCountMap[0xBC72d99C4D8B5872a8122244AfC84C1635194816] = 1;
        allowedMintCountMap[0xb3627a7C3e8dCBd8c2C5241Cf104575b8F9d5fe1] = 1;
        allowedMintCountMap[0xc457bc3BC88936358eeB5eaB5b2e3CD513c193b3] = 1;
        allowedMintCountMap[0x39F88a06891e289B084439362E8c98E745e0922c] = 1;
        allowedMintCountMap[0x084d7AaC7C474b089ca7139ae69cc768e368c3b2] = 1;
        allowedMintCountMap[0xA84B99E0401ae772354c850Cbcd2aDFd70e3b1b5] = 1;
        allowedMintCountMap[0x503d6fD533D1461fCDD9c5680766D538ffDbA783] = 1;
        allowedMintCountMap[0xDd33A5911cff5898f4138FD92607B8a028D26615] = 1;
        allowedMintCountMap[0x279648C291D4105444Cb989aAE8E54F81a888888] = 1;
        allowedMintCountMap[0xb1f0b4E47777e36F2fBEd4be3c9f3A37021Fc738] = 1;
        allowedMintCountMap[0x5286148f221e281b4034460140D5b63A39138e23] = 1;
        allowedMintCountMap[0x66Ea720B6EbefbC5E3859224FA291917517f3F86] = 1;
        allowedMintCountMap[0x253fE8AE5928566e9D9bD5869224EDEabbf1a40f] = 1;
        allowedMintCountMap[0x96484ba64C68607948B291e049D88fc2519Db8F6] = 1;
        allowedMintCountMap[0xB516e1DcE42180E06Ae485F1e251D5182eb6dd00] = 1;
        allowedMintCountMap[0x90587D9e4367992Aba93a67ea769Ae311e59469A] = 1;
        allowedMintCountMap[0x81BcC999C78655A792fCe41B96c214a1825d5cA1] = 1;
        allowedMintCountMap[0x164125DE6C55d2D20114d29370A2c812D7Be0B15] = 1;
        allowedMintCountMap[0xA91CAEECDf26767D8854DeAE5C9f30e73E3A2781] = 1;
        allowedMintCountMap[0xddb4221BF7E90A1484691130B0CB29A464377251] = 1;
        allowedMintCountMap[0x41c9A2Ded029B2Cd778D8A0FF3FDc0f20dc49B5E] = 1;
        allowedMintCountMap[0x161c5F394eE4c3e927d505c5DE51F93DdBb31B31] = 1;
        allowedMintCountMap[0x61D19fAdD34126e3334367c75a7dCbDeA6f6302F] = 1;
        allowedMintCountMap[0xdbAB7B57260107b7ac52FF68F6064d11D200F84E] = 1;
        allowedMintCountMap[0xE7225786EFd0E78a708CaDB2b2Ab88b42988Ec0B] = 1;
        allowedMintCountMap[0x2402F9AabDc6c1A229aF682eF3eb19BC21D0FAc1] = 1;
        allowedMintCountMap[0x09bc26E006c088f22Ff8782488Af1BF4fF0599A2] = 1;
        allowedMintCountMap[0xbbBF89cB082AEc247Fd52c6D8F985a72f7235df0] = 1;
        allowedMintCountMap[0x99CDf3C8f76228dEA41BCE3B578A998c619bD6b7] = 1;
        allowedMintCountMap[0xe8Ad39917651fD07E9b2FA5192aE95011F6C48Bf] = 1;
        allowedMintCountMap[0xE9962C1901d540A9ed2332abF0Eb27a402fFC568] = 1;
        allowedMintCountMap[0xa84F6967a3d1a1977ED84E8757264AA7cd8bC849] = 1;
        allowedMintCountMap[0x75Cf7533e708aC27D5f223C72369B2AA5ee0E07D] = 1;
        allowedMintCountMap[0xC3AaEb8DA38850083849E7EA490Ea41859c51941] = 1;
        allowedMintCountMap[0xf02aa140a3893acA9CC60e03C71E3c8A5eEC8550] = 1;
        allowedMintCountMap[0x684A3875a3c071cd14aB33AB2e9d454F5E185f64] = 1;
        allowedMintCountMap[0xe80f13DFae5A16a73433a0B51991641193cB6C91] = 1;
        allowedMintCountMap[0x55D909855Af65280494aF9fA4fC4532902E80206] = 1;
        allowedMintCountMap[0xe9Be604826618ce3927E21F9945c97D039827773] = 1;
        allowedMintCountMap[0xe90FCD8046E03EB27B8E5B2CcA72B94a01767ce1] = 1;
        allowedMintCountMap[0x730F69a6F60109674bF112f7A7F353a8fA6A1b7E] = 1;
        allowedMintCountMap[0xd2e40B96cC2905b8cd9D0f0a16fCb4F7726B919f] = 1;
        allowedMintCountMap[0xf42CdC13e0e99CF01980880357D9B68DC4d42083] = 1;
        allowedMintCountMap[0x5F87d6F2B82307F323E3e228D550dfD7A24e418C] = 1;
        allowedMintCountMap[0xC35286543dEd4F6445A543d58114EaB81B61C3Fa] = 1;
        allowedMintCountMap[0xB1C2c8f628C02B07dC9acc35963Af1c16D33e600] = 1;
        allowedMintCountMap[0xDA44D8268c23fb4Dc36Fb8F20A43115C79c5C79e] = 1;
        allowedMintCountMap[0x91b2320Ae01ed6F6A38f839B29a494bc505CC2Ec] = 1;
        allowedMintCountMap[0x2c3f4a55119809C1a778239Fd124630F5D9F530B] = 1;
        allowedMintCountMap[0x7311349f953f1F1542BEA688773322fF20Dd23Ed] = 1;
        allowedMintCountMap[0x73306b851A2d65C8fc8C4Fc01e5106F81EADBe27] = 1;
        allowedMintCountMap[0x6272EdB04f1593d7c8b30F5e34A037c72A5fe90e] = 1;
        allowedMintCountMap[0xAD990b2D8f63Cef4De48D9B685c3A712b621BE3e] = 1;
        allowedMintCountMap[0x0B2eD5C908D190c8dd60D06fFBCF7Fa9e1F16555] = 1;
        allowedMintCountMap[0xac3294bFE480609c942Ac5AFA65B49796A1294Bf] = 1;
        allowedMintCountMap[0x2b1f45DD72b278A829f0d047eB7Ed8A64EC80D92] = 1;
        allowedMintCountMap[0x71Aa6C4e87225fcAE2Df49f977C7FC0d1e8D2112] = 1;
        allowedMintCountMap[0x2781c274c184a90bF89f1f379232D8e3Ce3b1EcC] = 1;
        allowedMintCountMap[0xbB5adeD238318e9BF0a35e9F07B4F093262E9563] = 1;
        allowedMintCountMap[0x59b7AbbAa34De9f94A6ff79bD4531CD844637D0c] = 1;
        allowedMintCountMap[0x759BBDc0041d5A8F2be70D62791bA3e5947790aE] = 1;
        allowedMintCountMap[0x32ad63334bfC4EeA5B35329dc413B4b42D50eE7a] = 1;
        allowedMintCountMap[0x0F6e4145E878aE9047D55c5f24c7337D27a9Bc89] = 1;
        allowedMintCountMap[0xb3359A62fA47808c40979A40113C79744AB9cda7] = 1;
        allowedMintCountMap[0x3bc94735148FaCA654303ad25772eC5180fd6518] = 1;
        allowedMintCountMap[0x6d48c4bAb4AbEb7f8a907b80E55652f80A52777F] = 1;
        allowedMintCountMap[0xbA2b4240Ac736382b3549CfFE317Ef6868b5CFf1] = 1;
        allowedMintCountMap[0x4EA7558954Ffa62FD96Cb8AeebDC88469dB9311b] = 1;
        allowedMintCountMap[0x98cb129fBB5f792c9435E31368a2d66b99CA26C1] = 1;
        allowedMintCountMap[0xB1Bc710367b823da9a8461911878a785FED3d3c5] = 1;
        allowedMintCountMap[0x62e7ADaa619CE749e1E0bd4B31a71627978a36e2] = 1;
        allowedMintCountMap[0x28944257E11dbBbA3E0B9e0FDE7A9B4fbf8e572b] = 1;
        allowedMintCountMap[0xD0eFDFECe440aeae7F14be5E9E450d8b4839DFa6] = 1;
        allowedMintCountMap[0xde4059c8D60AF59677DBAbfDbE2c657b7F56C892] = 1;
        allowedMintCountMap[0xd1248C3979590A1A614f19E75a5bc30348c94828] = 1;
        allowedMintCountMap[0xF520523D8e902315D2DfB3F450efFe7D40E8272e] = 1;
        allowedMintCountMap[0x9388D79b22eE2ff60Ed703A7ddB9B1FB31007B7d] = 1;
        allowedMintCountMap[0x2229B8737d05769a8738b35918dDB17b5A52c523] = 1;
        allowedMintCountMap[0x6DD4086482d6F11c9CB001E45e83387EA45d4e0e] = 1;
        allowedMintCountMap[0xc3Caaa4a9422c625B9D7ac785BE66aBAf017584A] = 1;
        allowedMintCountMap[0xdcFb56b3BE21F511ea725Fc36973c4F39aA822B9] = 1;
        allowedMintCountMap[0xD7646114Bd2f5953391aBdA4e1439DC5D193961c] = 1;
        allowedMintCountMap[0xd361EAb04568FE2Ddd38EF0512bc1e010c473A76] = 1;
        allowedMintCountMap[0x98E78dDDb43B667C39c78B2d76630e10a290D78d] = 1;
        allowedMintCountMap[0x051C5559BC2a7Bd0066E58006E6747B4e7A7c328] = 1;
        allowedMintCountMap[0xa04082A4fc3A2D72138F034eC99F316aC5A90906] = 1;
        allowedMintCountMap[0x1b3f247965416346219487764f3B62fa8B219987] = 1;
        allowedMintCountMap[0x4a003D049B5Bdc48321053c92E37e48f78F03E16] = 1;
        allowedMintCountMap[0xFfFb3EdF7f5A408c2D657b605D787B15453b041f] = 1;
        allowedMintCountMap[0x77d6f5c54BBe2192281F7F49F673E786B0Fb88FC] = 1;
        allowedMintCountMap[0x27E979A437AAB21c32bea13eaECb41a481278E7A] = 1;
        allowedMintCountMap[0xDd4E23c1B224Ccfc83ff74903AFd58631e92a549] = 1;
        allowedMintCountMap[0x49Aa097eDDdb55Ef0503896974a447B5662874A5] = 1;
        allowedMintCountMap[0xE8C6368bf2Be291d64ED75Ca8fF9938D5Cc5CB5D] = 1;
        allowedMintCountMap[0xd732251bbcFb4B0E2c76E2cDC86a47f19B403e8f] = 1;
        allowedMintCountMap[0xAD80D10BE4C958ace6282347C15F3AD2E8C90475] = 1;
        allowedMintCountMap[0x2BF753B472998eecFdF86179d48C1c2d3e7e0284] = 1;
        allowedMintCountMap[0x81CBaDde0e6B853C999C903ea5d18eD643248196] = 1;
        allowedMintCountMap[0x100105Dc358a639C091C2E111f660E080E7382cB] = 1;
        allowedMintCountMap[0x3A01602A9E57B2B007635057e9CDa96080d7c2Dd] = 1;
        allowedMintCountMap[0x005ff96c67B622eE16598fDb7e2326c074A21836] = 1;
        allowedMintCountMap[0x3041138595603149b956804cE534A3034F35c6Aa] = 1;
        allowedMintCountMap[0x3A0Dd33BdCDd070d63208C6e57765f8fF787411D] = 1;
        allowedMintCountMap[0xbEe1f7e369B3271088Ed58bF225DF13Cd96D32d5] = 1;
        allowedMintCountMap[0x24Adab15FA8EC421A1Dd572A107D56F8b2F91008] = 1;
        allowedMintCountMap[0x79a752ad1CAFdCb189EA5A8d25bb112C57e767d9] = 1;
        allowedMintCountMap[0xe451F67fa26b860333D5866C7cCe3d73570bF6d3] = 1;
        allowedMintCountMap[0xb59eA14ebffff37a5fF8Eb7098F420260E33261F] = 1;
        allowedMintCountMap[0x4f0684e76c429E96215426B2A936749d23456EC3] = 1;
        allowedMintCountMap[0xb0ae08CA5e818473C728dcce669BC4B2d6c444eB] = 1;
        allowedMintCountMap[0xbb2249053064945d7CdD416e077634277760E14F] = 1;
        allowedMintCountMap[0xF1BdD1279d6E2787dCE77988096d53e39623Fa27] = 1;
        allowedMintCountMap[0x16B5f0De9FAe9FA6B290C4975962D2b5f8a0dc54] = 1;
        allowedMintCountMap[0xa8F32bd47bAb44e0C2935e4a9160644cdDb0e547] = 1;
        allowedMintCountMap[0x67a1cb82a2CE3Db0550E5faaa5F4Dc67D3598d4C] = 1;
        allowedMintCountMap[0x0745b719eF5aDBbF06d155b58801C2C1961f9EE1] = 1;
        allowedMintCountMap[0x1f6a939584721f487CeF15b8B115825cE4d77d66] = 1;
        allowedMintCountMap[0xEE3BCA6833215eB2C4140BdF74F6653cCFA2e04D] = 1;
        allowedMintCountMap[0x0C3aEBeC58bc80E026C368fD0A72a2cF6BfcBF96] = 1;
        allowedMintCountMap[0x4cdfd139D0D7Be39eb9849e970BAF00Cb37120C4] = 1;
        allowedMintCountMap[0x372894955A6F02510607e129f8286593Ccc5Df62] = 1;
        allowedMintCountMap[0x0146058fdD7966539f75725f63Fe344076F9BB8B] = 1;
        allowedMintCountMap[0xa4C45893F095F9DA82AcD9B52Fa16a7Eb947B02c] = 1;
        allowedMintCountMap[0x0a2d3Dd46E44AcEC0DA085268502880bB384bCC0] = 1;
        allowedMintCountMap[0x3C04182610360586237ba23BEF2dfeB146962eb2] = 1;
        allowedMintCountMap[0x0F5B7335F9860d07Ff3198cff7E63BBc6490409d] = 1;
        allowedMintCountMap[0xB5613944f0cf39b6C4CF0f2B422EBdebd67a8233] = 1;
        allowedMintCountMap[0x4474aFF745BdeaD9b72698f40922E57072410753] = 1;
        allowedMintCountMap[0x3D74B104dc5A47FBF52d168dd29219aB6098906f] = 1;
        allowedMintCountMap[0x92C283CD56b3A48Fa1AA83a2C0B631262b10A6B4] = 1;
        allowedMintCountMap[0x5F0d3527a53C21Ee4e20cF9EC03D68E74Ae320F4] = 1;
        allowedMintCountMap[0x35B9d8D6Bfb4B92Fb86371041721A5e1B6A7c6c4] = 1;
        allowedMintCountMap[0x08654146679792941d6B0c4BEfF1360624f16077] = 1;
        allowedMintCountMap[0xF123E2025E7790126045be0fce7107bF707275cf] = 1;
        allowedMintCountMap[0x0E9A1e0Eb8B1a7d8a6177005FF436Fc6B29ae62d] = 1;
        allowedMintCountMap[0xB2e1c9C2FfAef4883ad7E01Cf4F772346C0A935b] = 1;
        allowedMintCountMap[0x869d26FA7C0d013103FDfA575fADa69c1f2C95B1] = 1;
        allowedMintCountMap[0x21b05bA746c8B72BE437F97A8695bfC34Be5D01B] = 1;
        allowedMintCountMap[0x00d31FF4d4771BFFE896d33a0A4C41aFc47d97FB] = 1;
        allowedMintCountMap[0x52d32D91E18fF67206f63D73503b9184d2f23e8D] = 1;
        allowedMintCountMap[0xA15C4bEfA88D9B6E6bFb75cE11ebFDf4c4f7663E] = 1;
        allowedMintCountMap[0x36E18AB9dA425d5B59DE9176F19d867F8eb30B25] = 1;
        allowedMintCountMap[0x945d2b50e64a7666289a428019b18e1390791d9e] = 1;
        allowedMintCountMap[0xfD09166C490DdCc871D4a2eA71962347FD2C47C8] = 1;
        allowedMintCountMap[0xeff34fBAEAC88F6e36d4f6Ec8E43fCE016241a86] = 1;
        allowedMintCountMap[0x40d1103A1dC722ece92708097B7A1C75387B4368] = 1;
        allowedMintCountMap[0x9c9A550BA1D8b5D2969B571Ab663B3d8F116C4C4] = 1;
        allowedMintCountMap[0xFBB969B94803722d83DA92DE9366D2dB926687e3] = 1;
        allowedMintCountMap[0x731c1625251Dc470244E45eDc2a90D8DBeCa63bd] = 1;
        allowedMintCountMap[0x2a8920B334c9704b5377BcdC9dEe2526139C011D] = 1;
        allowedMintCountMap[0xADBDFB1Da28c26B43ebcb8cd540712B6a77E485a] = 1;
        allowedMintCountMap[0x05b582d0F86f621Dd59061f6D4496Fe8Dac018f3] = 1;
        allowedMintCountMap[0xab70C244F372dcBD5d313a6a9eEF4073A6523671] = 1;
        allowedMintCountMap[0x3eF67b18AeB2cBF7934191D40ce1BDa60b30C388] = 1;
        allowedMintCountMap[0x4DD3fEfA24615591262173B49d04f37c515742A2] = 1;
        allowedMintCountMap[0xbB809218C220e2f48D1Aa0Eed296B92432fC50eB] = 1;
        allowedMintCountMap[0x295f2a017D48370d9e3db906daC3E2885c02e3fd] = 1;
        allowedMintCountMap[0xc945A84e9e626315d8aB54503f132fD8d71bFd9f] = 1;
        allowedMintCountMap[0x492E115F9eB65c6dCb603479EA9f9274A5Bd0fa6] = 1;
        allowedMintCountMap[0xaaB9c13f39A2eFFD3268A7cA1cC1BfEA6C89149D] = 1;
        allowedMintCountMap[0xA8060a0d045D3e899EcE90A2907bc65037d7f6De] = 1;
        allowedMintCountMap[0xE4310f7aBa933f1537dB59660582b49522B3948E] = 1;
        allowedMintCountMap[0x2de081E063F847F2162DeE4006A045265fbBef41] = 1;
        allowedMintCountMap[0x6e34006E8F0D122d64dADE41CD427a0bA529F9E1] = 1;
        allowedMintCountMap[0x0Fb3a0fDdbFE0E9B5ca2fE9592D1A5ce233Cd097] = 1;
        allowedMintCountMap[0xE0e67Cc9131f68463DB4d7b8eA7f2Fc30091bc7E] = 1;
        allowedMintCountMap[0x328F84737cCA85aEd33B0B680B9a6788BC181870] = 1;
        allowedMintCountMap[0xE427f4202c3d43Cf2A538E1a3ED5a34B63d07150] = 1;
        allowedMintCountMap[0x4110b9A914764A851A64899d4116402E7bFca8E3] = 1;
        allowedMintCountMap[0x4a7AC390aC647ED19621A0930Ab6d7964cDbf022] = 1;
        allowedMintCountMap[0x942DD9AEe0f777E177fF5F0ca5E9cb73A66B9240] = 1;
        allowedMintCountMap[0x7589A0d5a86F9a0e928ff22b6b6A485B30ac0909] = 1;
        allowedMintCountMap[0x9b82a68b54Df5Ec31305579fa7be44E191A0E52F] = 1;
        allowedMintCountMap[0x8180e125d912D44e612A8EF5Ce8A17D5aB1806A1] = 1;
        allowedMintCountMap[0x6735b2eA1b3958768d73F0148a06cCB94220f33a] = 1;
        allowedMintCountMap[0xFd6444f4e122fE36a07C6Ef50214561972dCF47D] = 1;
        allowedMintCountMap[0x1e02D845bE96A542E089860578ab7706e4912F9b] = 1;
        allowedMintCountMap[0x1734A28705322cBa314DBC63706267C95eAf94C6] = 1;
        allowedMintCountMap[0xc29f7F36d4AA30c0Ec5C21186ff88Bb7C917B6E2] = 1;
        allowedMintCountMap[0x48cE884A1ecead469c50b42370aF2983D59Bbb94] = 1;
    }

    // Public Sale 2022/12/07 21:00 1670418000

    uint256 public publicSale = 1670418000;

    /** MINTING LIMITS **/

    mapping(address => uint256) private mintCountMap;

    mapping(address => uint256) private allowedMintCountMap;

    function addAllowedMintCountMap(address _address, uint256 amount)
        external
        onlyOwner
    {
        allowedMintCountMap[_address] = amount;
    }

    function multiAddAllowedMintCountMap(
        address[] memory _addresses,
        uint256 amount
    ) external onlyOwner {
        for (uint256 index = 0; index < _addresses.length; index++) {
            address _address = _addresses[index];
            allowedMintCountMap[_address] = amount;
        }
    }

    function allowedMintCount(address minter) public view returns (uint256) {
        return allowedMintCountMap[minter] - mintCountMap[minter];
    }

    function updateMintCount(address minter, uint256 count) private {
        mintCountMap[minter] += count;
    }

    uint256 public MAX_SUPPLY = 5000;

    uint256 public MAX_MULTIMINT = 2;

    uint256 public PRICE = 9000000000000000;

    function setPrice(uint256 _price) public onlyOwner returns (bool) {
        require(_price > 0, "price must be a positive number");
        PRICE = _price;
        return true;
    }

    function AdminMintToMul(address _to, uint256 count) public onlyOwner {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

        for (uint256 i = 0; i < count; i++) {
            uint256 currentTokenId = _nextTokenId.current();
            _safeMint(_to, currentTokenId);
            _nextTokenId.increment();
            mintCountMap[_to] += 1;
        }
    }

    function mint(uint256 count) public payable nonReentrant {
        require(totalSupply() + count - 1 < MAX_SUPPLY, "Exceeds max supply");

        if (allowedMintCount(msg.sender) >= count) {
            updateMintCount(msg.sender, count);
            for (uint256 i = 0; i < count; i++) {
                _mint(msg.sender, totalSupply());
            }
        } else {
            if (block.timestamp < publicSale) {
                revert("Sale not active");
            } else {
                require(
                    msg.value >= PRICE * count,
                    "Insufficient payment, 0.009ETH per item"
                );
                require(count <= MAX_MULTIMINT, "Mint at most 2 at a time");

                updateMintCount(msg.sender, count);

                for (uint256 i = 0; i < count; i++) {
                    _mint(msg.sender, totalSupply());
                }
            }
        }
    }

    /** URI HANDLING **/

    string private customContractURI = "http://epiddha.io/nft/Contract.json";

    function setContractURI(string memory customContractURI_)
        external
        onlyOwner
    {
        customContractURI = customContractURI_;
    }

    function contractURI() public view returns (string memory) {
        return customContractURI;
    }

    string private customBaseURI;

    function setBaseURI(string memory customBaseURI_) external onlyOwner {
        customBaseURI = customBaseURI_;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return customBaseURI;
    }

    /** PAYOUT **/

    address private constant payoutAddress1 =
        0x6DF916b50EcAA4A6add5fFfDaAdC80B1B757CEf3;

    address private constant payoutAddress2 =
        0x34b0EfE74aE1FB54343e4A4AC5F05c2d34A33f8B;

    address private constant payoutAddress3 =
        0xE54FeC8f28c1705EE3F42d203D3fF5aF6aD52893;

    address private constant payoutAddress4 =
        0x1d41D6B1091C1a8A334096771bd1776019243d5e;

    address private constant payoutAddress5 =
        0xfDd4C6aEcd82052b20F46C57C8e1c4c545a8C2d2;

    function withdrawAll() public {
        uint256 balance = address(this).balance;
        Address.sendValue(payable(payoutAddress1), (balance * 50) / 100);
        Address.sendValue(payable(payoutAddress2), (balance * 15) / 100);
        Address.sendValue(payable(payoutAddress3), (balance * 15) / 100);
        Address.sendValue(payable(payoutAddress4), (balance * 10) / 100);
        Address.sendValue(payable(payoutAddress5), (balance * 10) / 100);
    }

    // function withdraw(uint256 amount) public onlyOwner {
    //     address payable addr = payable(owner());
    //     addr.transfer(amount);
    // }

    // function withdrawTo(uint256 amount, address payable _to) public onlyOwner {
    //     _to.transfer(amount);
    // }

    /** ROYALTIES **/

    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (address(this), (salePrice * 800) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Enumerable, IERC165)
        returns (bool)
    {
        return (interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId));
    }

    // Burn

    function burn(uint256 tokenId) public virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Not approved to burn."
        );
        _burn(tokenId);
    }
}