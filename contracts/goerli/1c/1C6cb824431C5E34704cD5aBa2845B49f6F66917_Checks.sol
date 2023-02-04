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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./CHECKS721.sol";
import "./ChecksArt.sol";
import "./ChecksMetadata.sol";
import "./IChecks.sol";
import "./IChecksEdition.sol";
import "./Utilities.sol";

/**
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓  ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓          ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓                      ✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓                        ✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓                ✓✓       ✓✓✓✓✓✓✓
✓✓✓✓✓                 ✓✓✓          ✓✓✓✓✓
✓✓✓✓                 ✓✓✓            ✓✓✓✓
✓✓✓✓✓          ✓✓  ✓✓✓             ✓✓✓✓✓
✓✓✓✓✓✓✓          ✓✓✓             ✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓                        ✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓                      ✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓          ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓  ✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓
@title  Checks
@author VisualizeValue
@notice This artwork is notable.
*/
contract Checks is IChecks, CHECKS721 {

    /// @notice The VV Checks Edition contract.
    IChecksEdition public editionChecks;

    /// @dev We use this database for persistent storage.
    Checks checks;

    /// @dev Initializes the Checks Originals contract and links the Edition contract.
    constructor() {
        editionChecks = IChecksEdition(0x1c3F1129B7E90B52c7A83d9AB9CC389543C1eA77);
        checks.day0 = uint32(block.timestamp);
    }

    /// @notice Migrate Checks Editions to Checks Originals by burning the Editions.
    ///         Requires the Approval of this contract on the Edition contract.
    /// @param tokenIds The Edition token IDs you want to migrate.
    /// @param recipient The address to receive the tokens.
    function mint(uint256[] calldata tokenIds, address recipient) external {
        uint256 count = tokenIds.length;

        // We need a base seed for pseudo-randomization.
        uint256 randomizer = Utils.seed(checks.minted + checks.burned);

        // Burn the Editions for the given tokenIds & mint the Originals.
        for (uint256 i; i < count;) {
            uint256 id = tokenIds[i];
            address owner = editionChecks.ownerOf(id);

            // Check whether we're allowed to migrate this Edition.
            require(
                owner == msg.sender ||
                editionChecks.isApprovedForAll(owner, msg.sender) ||
                editionChecks.getApproved(id) == msg.sender,
                "Minter not owner or approved."
            );

            // Burn the Edition.
            editionChecks.burn(id);

            // Initialize our Check.
            StoredCheck storage check = checks.all[id];
            check.divisorIndex = 0;

            // Randomized input with a uint32 max value.
            uint256 seed = (randomizer + id) % 4294967296;

            // Check genome.
            check.colorBands[0] = _band(Utils.random(seed + 1, 160));
            check.gradients[0] = _gradient(Utils.random(seed + 2, 100));
            check.animation = uint8(Utils.random(seed + 3, 100));
            check.day = Utils.day(checks.day0, block.timestamp);
            check.seed = uint32(seed);

            // Mint the original.
            // If we're minting to a vault, transfer it there.
            if (msg.sender != recipient) {
                _safeMintVia(recipient, msg.sender, id);
            } else {
                _safeMint(msg.sender, id);
            }

            unchecked { ++i; }
        }

        // Keep track of how many checks have been minted.
        unchecked { checks.minted += uint32(count); }
    }

    /// @notice Get a specific check with its genome settings.
    /// @param tokenId The token ID to fetch.
    function getCheck(uint256 tokenId) external view returns (Check memory check) {
        _requireMinted(tokenId);

        return ChecksArt.getCheck(tokenId, checks);
    }

    /// @notice Sacrifice a token to transfer its visual representation to another token.
    /// @param tokenId The token ID transfer the art into.
    /// @param burnId The token ID to sacrifice.
    function inItForTheArt(uint256 tokenId, uint256 burnId) external {
        _sacrifice(tokenId, burnId);

        unchecked { ++checks.burned; }
    }

    /// @notice Sacrifice multiple tokens to transfer their visual to other tokens.
    /// @param tokenIds The token IDs to transfer the art into.
    /// @param burnIds The token IDs to sacrifice.
    function inItForTheArts(uint256[] calldata tokenIds, uint256[] calldata burnIds) external {
        uint256 pairs = _multiTokenOperation(tokenIds, burnIds);

        for (uint256 i; i < pairs;) {
            _sacrifice(tokenIds[i], burnIds[i]);

            unchecked { ++i; }
        }

        unchecked { checks.burned += uint32(pairs); }
    }

    /// @notice Composite one token into another. This mixes the visual and reduces the number of checks.
    /// @param tokenId The token ID to keep alive. Its visual will change.
    /// @param burnId The token ID to composite into the tokenId.
    function composite(uint256 tokenId, uint256 burnId) external {
        _composite(tokenId, burnId);

        unchecked { ++checks.burned; }
    }

    /// @notice Composite multiple tokens. This mixes the visuals and checks in remaining tokens.
    /// @param tokenIds The token IDs to keep alive. Their art will change.
    /// @param burnIds The token IDs to composite.
    function compositeMany(uint256[] calldata tokenIds, uint256[] calldata burnIds) external {
        uint256 pairs = _multiTokenOperation(tokenIds, burnIds);

        for (uint256 i; i < pairs;) {
            _composite(tokenIds[i], burnIds[i]);

            unchecked { ++i; }
        }

        unchecked { checks.burned += uint32(pairs); }
    }

    /// @notice Sacrifice 64 single-check tokens to form a black check.
    /// @param tokenIds The token IDs to burn for the black check.
    /// @dev The check at index 0 survives.
    function infinity(uint256[] calldata tokenIds) external {
        uint256 count = tokenIds.length;
        require(count == 64, "Final composite requires 64 single Checks");
        for (uint256 i; i < count;) {
            uint256 id = tokenIds[i];
            require(checks.all[id].divisorIndex == 6, "Non-single Check used");
            require(_isApprovedOrOwner(msg.sender, id), "Not allowed");

            unchecked { ++i; }
        }

        // Complete final composite.
        uint256 blackCheckId = tokenIds[0];
        StoredCheck storage check = checks.all[blackCheckId];
        check.day = Utils.day(checks.day0, block.timestamp);
        check.divisorIndex = 7;

        // Burn all 63 other Checks.
        for (uint i = 1; i < count;) {
            _burn(tokenIds[i]);

            unchecked { ++i; }
        }
        unchecked { checks.burned += 63; }

        // When one is released from the prison of self, that is indeed freedom.
        // For the most great prison is the prison of self.
        emit Infinity(blackCheckId, tokenIds[1:]);
        emit MetadataUpdate(blackCheckId);
    }

    /// @notice Burn a check. Note: This burn does not composite or swap tokens.
    /// @param tokenId The token ID to burn.
    /// @dev A common purpose burn method.
    function burn(uint256 tokenId) external {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: caller is not token owner or approved");

        // Perform the burn.
        _burn(tokenId);

        // Keep track of supply.
        unchecked { ++checks.burned; }
    }

    /// @notice Get the colors of all checks in a given token.
    /// @param tokenId The token ID to get colors for.
    /// @dev Consider using the ChecksArt and EightyColors Libraries
    ///      in combination with the getCheck function to resolve this yourself.
    function colors(uint256 tokenId) external view returns (string[] memory, uint256[] memory)
    {
        return ChecksArt.colors(ChecksArt.getCheck(tokenId, checks), checks);
    }

    /// @notice Render the SVG for a given token.
    /// @param tokenId The token to render.
    /// @dev Consider using the ChecksArt Library directly.
    function svg(uint256 tokenId) external view returns (string memory) {
        _requireMinted(tokenId);

        return string(ChecksArt.generateSVG(tokenId, checks));
    }

    /// @notice Get the metadata for a given token.
    /// @param tokenId The token to render.
    /// @dev Consider using the ChecksMetadata Library directly.
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireMinted(tokenId);

        return ChecksMetadata.tokenURI(tokenId, checks);
    }

    /// @notice Returns how many tokens this contract currently manages.
    function totalSupply() public view returns (uint256) {
        return checks.minted - checks.burned;
    }

    /// @dev Sacrifice one token to transfer its art to another.
    /// @param tokenId The token ID to keep.
    /// @param burnId The token ID to burn.
    function _sacrifice(uint256 tokenId, uint256 burnId) internal {
        (,StoredCheck storage toBurn,) = _tokenOperation(tokenId, burnId);

        // Copy over static genome settings
        checks.all[tokenId] = toBurn;

        // Update the birth date for this token.
        checks.all[tokenId].day = Utils.day(checks.day0, block.timestamp);

        // Perform the burn.
        _burn(burnId);

        // Notify DAPPs about the Sacrifice.
        emit IChecks.Sacrifice(burnId, tokenId);
        emit MetadataUpdate(tokenId);
    }

    /// @dev Composite one token into to another and burn it.
    /// @param tokenId The token ID to keep. Its art and check-count will change.
    /// @param burnId The token ID to burn in the process.
    function _composite(uint256 tokenId, uint256 burnId) internal {
        (
            StoredCheck storage toKeep,
            StoredCheck storage toBurn,
            uint256 divisorIndex
        ) = _tokenOperation(tokenId, burnId);

        // Composite our check
        toKeep.day = Utils.day(checks.day0, block.timestamp);
        toKeep.composites[divisorIndex] = uint16(burnId);
        toKeep.divisorIndex += 1;

        if (toKeep.divisorIndex < 6) {
            // Need a randomizer for gene manipulation.
            uint256 randomizer = Utils.seed(checks.burned);

            // We take the smallest gradient in 20% of cases, or continue as random checks.
            toKeep.gradients[toKeep.divisorIndex] = Utils.random(randomizer, 100) > 80
                ? Utils.minGt0(toKeep.gradients[divisorIndex], toBurn.gradients[divisorIndex])
                : Utils.min(toKeep.gradients[divisorIndex], toBurn.gradients[divisorIndex]);

            // We breed the lower end average color band when breeding.
            toKeep.colorBands[toKeep.divisorIndex] = Utils.avg(
                toKeep.colorBands[divisorIndex],
                toBurn.colorBands[divisorIndex]
            );

            // Coin-toss keep either one or the other animation setting.
            toKeep.animation = (randomizer % 2 == 1) ? toKeep.animation : toBurn.animation;
        }

        // Perform the burn.
        _burn(burnId);

        // Notify DAPPs about the Composite.
        emit IChecks.Composite(tokenId, burnId, ChecksArt.DIVISORS()[toKeep.divisorIndex]);
        emit MetadataUpdate(tokenId);
    }

    /// @dev Make sure this is a valid request to composite/switch with multiple tokens.
    /// @param tokenIds The token IDs to keep.
    /// @param burnIds The token IDs to burn.
    function _multiTokenOperation(uint256[] calldata tokenIds, uint256[] calldata burnIds)
        internal pure returns (uint256 pairs)
    {
        pairs = tokenIds.length;
        require(pairs == burnIds.length, "Invalid number of tokens to composite");
    }

    /// @dev Make sure this is a valid request to composite/switch a token pair.
    /// @param tokenId The token ID to keep.
    /// @param burnId The token ID to burn.
    function _tokenOperation(uint256 tokenId, uint256 burnId)
        internal view returns (
            StoredCheck storage toKeep,
            StoredCheck storage toBurn,
            uint8 divisorIndex
        )
    {
        toKeep = checks.all[tokenId];
        toBurn = checks.all[burnId];
        divisorIndex = toKeep.divisorIndex;

        require(
            _isApprovedOrOwner(msg.sender, tokenId) &&
            _isApprovedOrOwner(msg.sender, burnId) &&
            divisorIndex == toBurn.divisorIndex &&
            tokenId != burnId &&
            divisorIndex < 6,
            "Token operation not allowed"
        );
    }

    /// @dev Get the index for a token gradient based on a number between 1 and 100.
    /// @param input The pseudorandom input to base the index on.
    function _gradient(uint256 input) internal pure returns(uint8) {
        return input > 10 ? 0
             : uint8(1 + (input % 6));
    }

    /// @dev Get the index for a token color band based on a number between 1 and 160.
    /// @param input The pseudorandom input to base the index on.
    function _band(uint256 input) internal pure returns(uint8) {
        return input > 80 ? 0
             : input > 40 ? 1
             : input > 20 ? 2
             : input > 10 ? 3
             : input >  8 ? 4
             : input >  2 ? 5
             : 6;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/CHECKS721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC4906.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract CHECKS721 is Context, ERC165, IERC721, IERC721Metadata, IERC4906 {
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
    constructor() {
        _name = "Checks";
        _symbol = "CHECKS";
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
        address owner = CHECKS721.ownerOf(tokenId);
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
        address owner = CHECKS721.ownerOf(tokenId);
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
     * @dev Safely mints `tokenId` and transfers it to `to` after an inital transfer to `via`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMintVia(address to, address via, uint256 tokenId) internal virtual {
        _safeMintVia(to, via, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMintVia(
        address to,
        address via,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mintVia(to, via, tokenId);
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
        _mintState(to, tokenId);

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to` after a transfer to `via`
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
    function _mintVia(address to, address via, uint256 tokenId) internal virtual {
        _mintState(to, tokenId);

        emit Transfer(address(0), via, tokenId);
        emit Transfer(via, to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
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
     */
    function _mintState(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

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
        address owner = CHECKS721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = CHECKS721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
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
        require(CHECKS721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(CHECKS721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

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

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(CHECKS721.ownerOf(tokenId), to, tokenId);
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
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256, /* firstTokenId */
        uint256 batchSize
    ) internal virtual {
        if (batchSize > 1) {
            if (from != address(0)) {
                _balances[from] -= batchSize;
            }
            if (to != address(0)) {
                _balances[to] += batchSize;
            }
        }
    }

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./EightyColors.sol";
import "./IChecks.sol";
import "./Utilities.sol";

/**

 /////////   VV CHECKS   /////////
 //                             //
 //                             //
 //                             //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //                             //
 //                             //
 //                             //
 /////   DONT TRUST, CHECK   /////

@title  ChecksArt
@author VisualizeValue
@notice Renders the Checks visuals.
*/
library ChecksArt {

    /// @dev The path for a 20x20 px check based on a 36x36 px frame.
    string public constant CHECKS_PATH = 'M21.36 9.886A3.933 3.933 0 0 0 18 8c-1.423 0-2.67.755-3.36 1.887a3.935 3.935 0 0 0-4.753 4.753A3.933 3.933 0 0 0 8 18c0 1.423.755 2.669 1.886 3.36a3.935 3.935 0 0 0 4.753 4.753 3.933 3.933 0 0 0 4.863 1.59 3.953 3.953 0 0 0 1.858-1.589 3.935 3.935 0 0 0 4.753-4.754A3.933 3.933 0 0 0 28 18a3.933 3.933 0 0 0-1.887-3.36 3.934 3.934 0 0 0-1.042-3.711 3.934 3.934 0 0 0-3.71-1.043Zm-3.958 11.713 4.562-6.844c.566-.846-.751-1.724-1.316-.878l-4.026 6.043-1.371-1.368c-.717-.722-1.836.396-1.116 1.116l2.17 2.15a.788.788 0 0 0 1.097-.22Z';

    /// @dev The semiperfect divisors of the 80 checks.
    function DIVISORS() public pure returns (uint8[8] memory) {
        return [ 80, 40, 20, 10, 5, 4, 1, 0 ];
    }

    /// @dev The different color band sizes that we use for the art.
    function COLOR_BANDS() public pure returns (uint8[7] memory) {
        return [ 80, 40, 20, 10, 5, 4, 1 ];
    }

    /// @dev The gradient increment steps.
    function GRADIENTS() public pure returns (uint8[7] memory) {
        return [ 0, 1, 2, 5, 8, 9, 10 ];
    }

    /// @dev Load a check from storage and fill its current state settings.
    /// @param tokenId The id of the check to fetch.
    /// @param checks The DB containing all checks.
    function getCheck(
        uint256 tokenId, IChecks.Checks storage checks
    ) public view returns (IChecks.Check memory check) {
        IChecks.StoredCheck memory stored = checks.all[tokenId];
        uint8 divisorIndex = stored.divisorIndex;

        check.stored = stored;
        check.hasManyChecks = divisorIndex < 6;
        check.checksCount = DIVISORS()[divisorIndex];
        check.composite = divisorIndex > 0 && divisorIndex < 7 ? stored.composites[divisorIndex - 1] : 0;
        check.colorBand = check.hasManyChecks ? COLOR_BANDS()[stored.colorBands[divisorIndex]] : 1;
        check.gradient  = check.hasManyChecks ? GRADIENTS()[stored.gradients[divisorIndex]] : 0;
        check.direction = uint8(stored.animation % 2);
        check.speed = uint8(2**(stored.animation % 3));
    }

    /// @dev Generate indexes for the color slots of check parents (up to the EightyColors.COLORS themselves).
    /// @param divisorIndex The current divisorIndex to query.
    /// @param check The current check to investigate.
    /// @param checks The DB containing all checks.
    function colorIndexes(
        uint8 divisorIndex, IChecks.Check memory check, IChecks.Checks storage checks
    )
        public view returns (uint256[] memory)
    {
        uint8[8] memory divisors = DIVISORS();
        uint256 checksCount = divisors[divisorIndex];
        uint32 seed = check.stored.seed;
        uint8 gradient = check.gradient;
        uint8 colorBand = check.colorBand;

        // If we're a composited check, we choose colors only based on
        // the slots available in our parents. Otherwise,
        // we choose based on our available spectrum.
        uint256 possibleColorChoices = divisorIndex > 0
            ? divisors[divisorIndex - 1] * 2
            : 80;

        // We initialize our index and select the first color
        uint256[] memory indexes = new uint256[](checksCount);
        indexes[0] = Utils.random(seed, possibleColorChoices - 1);

        // If we have more than one check, continue selecting colors
        if (check.hasManyChecks) {
            if (gradient > 0) {
                // If we're a gradient check, we select based on the color band looping around
                // the 80 possible colors
                for (uint256 i = 1; i < checksCount;) {
                    indexes[i] = (indexes[0] + (i * gradient * colorBand / checksCount) % colorBand) % 80;
                    unchecked { ++i; }
                }
            } else if (divisorIndex == 0) {
                // If we select initial non gradient colors, we just take random ones
                // available in our color band
                for (uint256 i = 1; i < checksCount;) {
                    indexes[i] = (indexes[0] + Utils.random(seed + i, colorBand)) % 80;
                    unchecked { ++i; }
                }
            } else {
                // If we have parent checks, we select our colors from their set
                for (uint256 i = 1; i < checksCount;) {
                    indexes[i] = Utils.random(seed + i, possibleColorChoices - 1);
                    unchecked { ++i; }
                }
            }
        }

        // We resolve our color indexes through our parent tree until we reach the root checks
        if (divisorIndex > 0) {
            uint8 previousDivisor = divisorIndex - 1;

            // We already have our current check, but need the our parent state color indices
            uint256[] memory parentIndexes = colorIndexes(previousDivisor, check, checks);

            // We also need to fetch the colors of the check that was composited into us
            IChecks.Check memory composited = getCheck(check.composite, checks);
            uint256[] memory compositedIndexes = colorIndexes(previousDivisor, composited, checks);

            // Replace random indices with parent / root color indices
            uint8 count = divisors[previousDivisor];

            // We always select the first color from our parent
            uint256 initialBranchIndex = indexes[0] % count;
            indexes[0] = indexes[0] < count
                ? parentIndexes[initialBranchIndex]
                : compositedIndexes[initialBranchIndex];

            // If we don't have a gradient, we continue resolving from our parent for the remaining checks
            if (gradient == 0) {
                for (uint256 i; i < checksCount;) {
                    uint256 branchIndex = indexes[i] % count;
                    indexes[i] = indexes[i] < count
                        ? parentIndexes[branchIndex]
                        : compositedIndexes[branchIndex];

                    unchecked { ++i; }
                }
            // If we have a gradient we base the remaining colors off our initial selection
            } else {
                for (uint256 i = 1; i < checksCount;) {
                    indexes[i] = (indexes[0] + (i * gradient * colorBand / checksCount) % colorBand) % 80;

                    unchecked { ++i; }
                }
            }
        }

        return indexes;
    }

    /// @dev Fetch all colors of a given Check.
    /// @param check The check to get colors for.
    /// @param checks The DB containing all checks.
    function colors(
        IChecks.Check memory check, IChecks.Checks storage checks
    ) public view returns (string[] memory, uint256[] memory) {
        // A fully composited check has no color.
        if (check.stored.divisorIndex == 7) {
            string[] memory zeroColors = new string[](1);
            uint256[] memory zeroIndexes = new uint256[](1);
            zeroColors[0] = '000';
            zeroIndexes[0] = 999;
            return (zeroColors, zeroIndexes);
        }

        // Fetch the indices on the original color mapping.
        uint256[] memory indexes = colorIndexes(check.stored.divisorIndex, check, checks);

        // Map over to get the colors.
        string[] memory checkColors = new string[](indexes.length);
        string[80] memory allColors = EightyColors.COLORS();

        // Always set the first color.
        checkColors[0] = allColors[indexes[0]];

        // Resolve each color via their index in EightyColors.COLORS.
        for (uint256 i = 1; i < indexes.length; i++) {
            checkColors[i] = allColors[indexes[i]];
        }

        return (checkColors, indexes);
    }

    /// @dev Get the number of checks we should display per row.
    /// @param checks The number of checks in the piece.
    function perRow(uint8 checks) public pure returns (uint8) {
        return checks == 80
            ? 8
            : checks >= 20
                ? 4
                : checks == 10 || checks == 4
                    ? 2
                    : 1;
    }

    /// @dev Get the X-offset for positioning checks horizontally.
    /// @param checks The number of checks in the piece.
    function rowX(uint8 checks) public pure returns (uint16) {
        return checks <= 1
            ? 286
            : checks == 5
                ? 304
                : checks == 10 || checks == 4
                    ? 268
                    : 196;
    }

    /// @dev Get the Y-offset for positioning checks vertically.
    /// @param checks The number of checks in the piece.
    function rowY(uint8 checks) public pure returns (uint16) {
        return checks > 4
            ? 160
            : checks == 4
                ? 268
                : checks > 1
                    ? 304
                    : 286;
    }

    /// @dev Get the animation SVG snipped for an individual check of a piece.
    /// @param data The data object containing rendering settings.
    /// @param offset The index position of the check in question.
    /// @param allColors All available colors.
    function fillAnimation(
        CheckRenderData memory data,
        uint256 offset,
        string[80] memory allColors
    ) public pure returns (bytes memory)
    {
        if (data.isBlack) {
            return '';
        }

        // We only pick 20 colors from our gradient to reduce execution time.
        uint8 count = 20;

        bytes memory values;

        // Reverse loop through our color gradient.
        if (data.check.direction == 0) {
            for (uint256 i = offset + 80; i > offset;) {
                values = abi.encodePacked(values, '#', allColors[i % 80], ';');
                unchecked { i-=4; }
            }
        // Forward loop through our color gradient.
        } else {
            for (uint256 i = offset; i < offset + 80;) {
                values = abi.encodePacked(values, '#', allColors[i % 80], ';');
                unchecked { i+=4; }
            }
        }

        // Add initial color as last one for smooth animations.
        values = abi.encodePacked(values, '#', allColors[offset]);

        // Render the SVG snipped for the animation
        return abi.encodePacked(
            '<animate ',
                'attributeName="fill" values="',values,'" ',
                'dur="',Utils.uint2str(count * 2 / data.check.speed),'s" begin="animation.begin" ',
                'repeatCount="indefinite" ',
            '/>'
        );
    }

    /// @dev Generate the SVG code for all checks in a given token.
    /// @param data The data object containing rendering settings.
    function generateChecks(CheckRenderData memory data) public pure returns (bytes memory) {
        bytes memory checksBytes;
        string[80] memory allColors = EightyColors.COLORS();

        uint8 checksCount = data.count;
        for (uint8 i; i < checksCount; i++) {
            // Compute row settings.
            data.indexInRow = i % data.perRow;
            data.isNewRow = data.indexInRow == 0 && i > 0;

            // Compute offsets.
            if (data.isNewRow) data.rowY += data.spaceY;
            if (data.isNewRow && data.indent) {
                if (i == 0) {
                    data.rowX += data.spaceX / 2;
                }

                if (i % (data.perRow * 2) == 0) {
                    data.rowX -= data.spaceX / 2;
                } else {
                    data.rowX += data.spaceX / 2;
                }
            }
            string memory translateX = Utils.uint2str(data.rowX + data.indexInRow * data.spaceX);
            string memory translateY = Utils.uint2str(data.rowY);

            // Render the current check.
            checksBytes = abi.encodePacked(checksBytes, abi.encodePacked(
                '<g transform="translate(', translateX, ', ', translateY, ') scale(', data.scale, ')">',
                    '<use href="#check" fill="#', data.colors[i], '">',
                        fillAnimation(data, data.colorIndexes[i], allColors),
                    '</use>'
                '</g>'
            ));
        }

        return checksBytes;
    }

    /// @dev Collect relevant rendering data for easy access across functions.
    /// @param check Our current check loaded from storage.
    /// @param checks The DB containing all checks.
    function collectRenderData(
        IChecks.Check memory check, IChecks.Checks storage checks
    ) public view returns (CheckRenderData memory data) {
        // Carry through base settings.
        data.check = check;
        data.isBlack = check.stored.divisorIndex == 7;
        data.count = data.isBlack ? 1 : DIVISORS()[check.stored.divisorIndex];

        // Compute colors and indexes.
        (string[] memory colors_, uint256[] memory colorIndexes_) = colors(check, checks);
        data.colorIndexes = colorIndexes_;
        data.colors = colors_;
        data.gridColor = data.isBlack ? '#F2F2F2' : '#191919';
        data.canvasColor = data.isBlack ? '#FFF' : '#111';

        // Compute positioning data.
        data.scale = data.count > 20 ? '1' : data.count > 1 ? '2' : '3';
        data.spaceX = data.count == 80 ? 36 : 72;
        data.spaceY = data.count > 20 ? 36 : 72;
        data.perRow = perRow(data.count);
        data.indent = data.count == 40;
        data.rowX = rowX(data.count);
        data.rowY = rowY(data.count);
    }

    /// @dev Generate the SVG code for rows in the 8x10 Checks grid.
    function generateGridRow() public pure returns (bytes memory) {
        bytes memory row;
        for (uint256 i; i < 8; i++) {
            row = abi.encodePacked(
                row,
                '<use href="#square" x="', Utils.uint2str(196 + i*36), '" y="160"/>'
            );
        }
        return row;
    }

    /// @dev Generate the SVG code for the entire 8x10 Checks grid.
    function generateGrid() public pure returns (bytes memory) {
        bytes memory grid;
        for (uint256 i; i < 10; i++) {
            grid = abi.encodePacked(
                grid,
                '<use href="#row" y="', Utils.uint2str(i*36), '"/>'
            );
        }

        return abi.encodePacked('<g id="grid" x="196" y="160">', grid, '</g>');
    }

    /// @dev Generate the complete SVG code for a given Check.
    /// @param tokenId The ID of the token to render.
    /// @param checks The DB containing all checks.
    function generateSVG(
        uint256 tokenId, IChecks.Checks storage checks
    ) public view returns (bytes memory) {
        CheckRenderData memory data = collectRenderData(getCheck(tokenId, checks), checks);

        return abi.encodePacked(
            '<svg ',
                'viewBox="0 0 680 680" ',
                'fill="none" xmlns="http://www.w3.org/2000/svg" ',
                'style="width:100%;background:black;"',
            '>',
                '<defs>',
                    '<path id="check" fill-rule="evenodd" d="', CHECKS_PATH, '"></path>',
                    '<rect id="square" width="36" height="36" stroke="', data.gridColor, '"></rect>',
                    '<g id="row">', generateGridRow(), '</g>'
                '</defs>',
                '<rect width="680" height="680" fill="black"/>',
                '<rect x="188" y="152" width="304" height="376" fill="', data.canvasColor, '"/>',
                generateGrid(),
                generateChecks(data),
                '<rect width="680" height="680" fill="transparent">',
                    '<animate ',
                        'attributeName="width" ',
                        'from="680" ',
                        'to="0" ',
                        'dur="0.2s" ',
                        'begin="click" ',
                        'fill="freeze" ',
                        'id="animation"',
                    '/>',
                '</rect>',
            '</svg>'
        );
    }
}

/// @dev Bag holding all data relevant for rendering.
struct CheckRenderData {
    IChecks.Check check;
    uint256[] colorIndexes;
    string[] colors;
    string canvasColor;
    string gridColor;
    string duration;
    string scale;
    uint32 seed;
    uint16 rowX;
    uint16 rowY;
    uint8 count;
    uint8 spaceX;
    uint8 spaceY;
    uint8 perRow;
    uint8 indexInRow;
    uint8 isIndented;
    bool indent;
    bool isNewRow;
    bool isBlack;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Base64.sol";

import "./ChecksArt.sol";
import "./IChecks.sol";
import "./Utilities.sol";

/**

✓✓✓✓✓✓✓  ✓✓✓✓✓✓✓✓    ✓✓✓✓✓✓    ✓✓✓✓✓✓✓✓   ✓✓✓✓✓✓✓     ✓✓
✓✓       ✓✓     ✓✓  ✓✓    ✓✓   ✓✓    ✓✓  ✓✓     ✓✓  ✓✓✓✓
✓✓       ✓✓     ✓✓  ✓✓             ✓✓           ✓✓    ✓✓
✓✓✓✓✓✓   ✓✓✓✓✓✓✓✓   ✓✓            ✓✓      ✓✓✓✓✓✓✓     ✓✓
✓✓       ✓✓   ✓✓    ✓✓           ✓✓      ✓✓           ✓✓
✓✓       ✓✓    ✓✓   ✓✓    ✓✓     ✓✓      ✓✓           ✓✓
✓✓✓✓✓✓✓  ✓✓     ✓✓   ✓✓✓✓✓✓      ✓✓      ✓✓✓✓✓✓✓✓✓   ✓✓✓✓

@title  ChecksMetadata
@author VisualizeValue
@notice Renders ERC721 compatible metadata for Checks.
*/
library ChecksMetadata {

    /// @dev Render the JSON Metadata for a given Checks token.
    /// @param tokenId The id of the token to render.
    /// @param checks The DB containing all checks.
    function tokenURI(
        uint256 tokenId, IChecks.Checks storage checks
    ) public view returns (string memory) {
        IChecks.Check memory check = ChecksArt.getCheck(tokenId, checks);

        bytes memory svg = ChecksArt.generateSVG(tokenId, checks);

        bytes memory metadata = abi.encodePacked(
            '{',
                '"name": "Checks ', Utils.uint2str(tokenId), '",',
                '"description": "This artwork is notable.",',
                '"image": ',
                    '"data:image/svg+xml;base64,',
                    Base64.encode(svg),
                    '",',
                '"animation_url": ',
                    '"data:text/html;base64,',
                    Base64.encode(generateHTML(tokenId, svg)),
                    '",',
                '"attributes": [',
                    check.hasManyChecks
                        ? trait('Color Band', colorBand(check.stored.colorBands[check.stored.divisorIndex]), ',')
                        : '',
                    check.hasManyChecks
                        ? trait('Gradient', gradients(check.stored.gradients[check.stored.divisorIndex]), ',')
                        : '',
                    check.checksCount > 0
                        ? trait('Speed', check.speed == 4 ? '2x' : check.speed == 2 ? '1x' : '0.5x', ',')
                        : '',
                    check.checksCount > 0
                        ? trait('Shift', check.direction == 0 ? 'IR' : 'UV', ',')
                        : '',
                    trait('Checks', Utils.uint2str(check.checksCount), ','),
                    trait('Day', Utils.uint2str(check.stored.day), ''),
                ']',
            '}'
        );

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(metadata)
            )
        );
    }

    /// @dev Get the names for different gradients. Compare ChecksArt.GRADIENTS.
    /// @param gradientIndex The index of the gradient.
    function gradients(uint8 gradientIndex) public pure returns (string memory) {
        return [
            'None', 'Linear', 'Double Linear', 'Reflected', 'Double Angled', 'Angled', 'Linear Z'
        ][gradientIndex];
    }

    /// @dev Get the percentage values for different color bands. Compare ChecksArt.COLOR_BANDS.
    /// @param bandIndex The index of the color band.
    function colorBand(uint8 bandIndex) public pure returns (string memory) {
        return [
            '100 Percent', '50 Percent', '25 Percent', '12.5 Percent', '6.25 Percent', '4 Percent', '1.25 Percent'
        ][bandIndex];
    }

    /// @dev Generate the SVG snipped for a single attribute.
    /// @param traitType The `trait_type` for this trait.
    /// @param traitValue The `value` for this trait.
    /// @param append Helper to append a comma.
    function trait(
        string memory traitType, string memory traitValue, string memory append
    ) public pure returns (string memory) {
        return string(abi.encodePacked(
            '{',
                '"trait_type": "', traitType, '",'
                '"value": "', traitValue, '"'
            '}',
            append
        ));
    }

    /// @dev Generate the HTML for the animation_url in the metadata.
    /// @param tokenId The id of the token to generate the embed for.
    /// @param svg The rendered SVG code to embed in the HTML.
    function generateHTML(uint256 tokenId, bytes memory svg) public pure returns (bytes memory) {
        return abi.encodePacked(
            '<!DOCTYPE html>',
            '<html lang="en">',
            '<head>',
                '<meta charset="UTF-8">',
                '<meta http-equiv="X-UA-Compatible" content="IE=edge">',
                '<meta name="viewport" content="width=device-width, initial-scale=1.0">',
                '<title>Check #', Utils.uint2str(tokenId), '</title>',
                '<style>',
                    'html,',
                    'body {',
                        'margin: 0;',
                        'background: #EFEFEF;',
                        'overflow: hidden;',
                    '}',
                    'svg {',
                        'max-width: 100vw;',
                        'max-height: 100vh;',
                    '}',
                '</style>',
            '</head>',
            '<body>',
                svg,
            '</body>',
            '</html>'
        );
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**

 /////////////////////////////////
 //                             //
 //                             //
 //                             //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //                             //
 //                             //
 //                             //
 /////////////////////////////////

@title  EightyColors
@author VisualizeValue
@notice The eighty colors of Checks.
*/
library EightyColors {

    /// @dev Theese are sorted in a gradient.
    function COLORS() public pure returns (string[80] memory) {
        return [
            'E84AA9',
            'F2399D',
            'DB2F96',
            'E73E85',
            'FF7F8E',
            'FA5B67',
            'E8424E',
            'D5332F',
            'C23532',
            'F2281C',
            'D41515',
            '9D262F',
            'DE3237',
            'DA3321',
            'EA3A2D',
            'EB4429',
            'EC7368',
            'FF8079',
            'FF9193',
            'EA5B33',
            'D05C35',
            'ED7C30',
            'EF9933',
            'EF8C37',
            'F18930',
            'F09837',
            'F9A45C',
            'F2A43A',
            'F2A840',
            'F2A93C',
            'FFB340',
            'F2B341',
            'FAD064',
            'F7CA57',
            'F6CB45',
            'FFAB00',
            'F4C44A',
            'FCDE5B',
            'F9DA4D',
            'F9DA4A',
            'FAE272',
            'F9DB49',
            'FAE663',
            'FBEA5B',
            'A7CA45',
            'B5F13B',
            '94E337',
            '63C23C',
            '86E48E',
            '77E39F',
            '5FCD8C',
            '83F1AE',
            '9DEFBF',
            '2E9D9A',
            '3EB8A1',
            '5FC9BF',
            '77D3DE',
            '6AD1DE',
            '5ABAD3',
            '4291A8',
            '33758D',
            '45B2D3',
            '81D1EC',
            'A7DDF9',
            '9AD9FB',
            'A4C8EE',
            '60B1F4',
            '2480BD',
            '4576D0',
            '3263D0',
            '2E4985',
            '25438C',
            '525EAA',
            '3D43B3',
            '322F92',
            '4A2387',
            '371471',
            '3B088C',
            '6C31D7',
            '9741DA'
        ];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IChecks {

    struct StoredCheck {
        uint16[6] composites;  // The tokenIds that were composited into this one
        uint8[6] colorBands;  // The length of the used color band in percent
        uint8[6] gradients;  // Gradient settings for each generation
        uint8 divisorIndex; // Easy access to next / previous divisor
        uint8 animation;   // Animation seed
        uint32 seed;      // The seed enables pseudo-randomisation
        uint16 day;      // The days since token was created
    }

    struct Check {
        StoredCheck stored;
        uint16 composite;     // The parent tokenId that was composited into this one
        bool hasManyChecks;  // Quick access for whether the check has many checks
        uint8 checksCount;  // How many checks this token has
        uint8 colorBand;   // 100%, 50%, 25%, 12.5%, 6.25%, 5%, 1.25%
        uint8 gradient;   // Linearly through the colorBand [1, 2, 3]
        uint8 direction; // Animation direction
        uint8 speed;    // Animation speed
    }

    struct Checks {
        uint32 day0;
        uint32 minted;
        uint32 burned;
        mapping(uint256 => StoredCheck) all;
    }

    event Sacrifice(
        uint256 indexed burnedId,
        uint256 indexed tokenId
    );

    event Composite(
        uint256 indexed tokenId,
        uint256 indexed burnedId,
        uint8 indexed checks
    );

    event Infinity(
        uint256 indexed tokenId,
        uint256[] indexed burnedIds
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IChecksEdition {
    /// @dev Burns `tokenId`. See {ERC721-_burn}.
    function burn(uint256 tokenId) external;

    /// @dev Returns the owner of the `tokenId` token.
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /// @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /// @dev Returns the approved operator of a specific token.
    function getApproved(uint256 tokenId) external view returns (address operator);

    /// @dev Error when burning unapproved tokens.
    error TransferCallerNotOwnerNorApproved();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/CHECKS721.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/// @title EIP-721 Metadata Update Extension
interface IERC4906 is IERC165, IERC721 {
    /// @dev This event emits when the metadata of a token is changed.
    /// Third-party platforms such as NFT marketplaces can listen to
    /// the event and auto-update the tokens in their apps.
    event MetadataUpdate(uint256 _tokenId);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Utils {
    /// @dev Create a pseudo random number
    function seed(uint256 nonce) public view returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(msg.sender, block.coinbase, nonce))
        );
    }

    /// @dev Pseudorandom number based on input max bound
    function random(uint256 input, uint256 max) public pure returns (uint256) {
        return max - (uint256(keccak256(abi.encodePacked(input))) % max);
    }

    /// @dev Convert an integer to a string
    function uint2str(uint256 _i) public pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            ++len;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /// @dev Get the smallest non zero number
    function minGt0(uint8 one, uint8 two) public pure returns (uint8) {
        return one > two
            ? two > 0
                ? two
                : one
            : two;
    }

    /// @dev Get the smallest number
    function min(uint8 one, uint8 two) public pure returns (uint8) {
        return one < two ? one : two;
    }

    /// @dev Get the average between two numbers
    function avg(uint8 one, uint8 two) public pure returns (uint8) {
        return (one & two) + (one ^ two) / 2;
    }

    /// @dev Get the days since another date (input is seconds)
    function day(uint256 from, uint256 to) public pure returns (uint16) {
        return uint16((to - from) / 86400 + 1);
    }
}