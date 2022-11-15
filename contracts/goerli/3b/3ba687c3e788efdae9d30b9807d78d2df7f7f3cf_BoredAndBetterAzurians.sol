/**
 *Submitted for verification at Etherscan.io on 2022-11-15
*/

// File: @openzeppelin/contracts/utils/math/Math.sol


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

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/interfaces/IERC2981.sol


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


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

// File: @openzeppelin/contracts/token/common/ERC2981.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol


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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


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

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/ERC721.sol)

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

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
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

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

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

        _afterTokenTransfer(from, to, tokenId, 1);
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

// File: @openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/extensions/ERC721Enumerable.sol)

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
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

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

// File: dfd.sol


pragma solidity >=0.7.0 <0.9.0;
// /0xa7c41368FCE2f510f8424140BC700ec5c82B7fC1

//Ownable is needed to setup sales royalties on Open Sea
//if you are the owner of the contract you can configure sales Royalties in the Open Sea website

//ipfs://QmcFkAYR95GfcpiPN2WZuCF7kbgwLY5apw7JZ8mrJJDjtC/
//give your contract a name
contract BoredAndBetterAzurians is ERC2981,ERC721Enumerable {
  using Strings for uint256;

//configuration
  string baseURI;
  string public baseExtension = ".json";
  bool public paused = false;

//set the cost to mint each NFT
  uint256 public cost = 0.003 ether;

//set the max supply of NFT's
  uint256 public maxSupply = 5555;
   address public owner;


//are the NFT's revealed (viewable)? If true users can see the NFTs. 
//if false everyone sees a reveal picture
  bool public revealed = true;

  mapping(address => bool) public isWhitelisted;
  mapping(address => uint256) public maxUMint;
  mapping(address => bool) public freeMinted;
  uint256 maxMint = 10;


 // bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

  constructor(string memory _initBaseURI) ERC721("Bored & Better Azurians", "BBA NFT") {
    baseURI = _initBaseURI;
    owner = 0xa7c41368FCE2f510f8424140BC700ec5c82B7fC1;
    _setDefaultRoyalty(owner, 550);
       isWhitelisted[0xc0237e3BF59761A149696c2474BE8fd36370ea6a] = true;
   isWhitelisted[0x1e10A9C9E479130331e9B2b23d6CDE2aB5aaC526] = true;
   isWhitelisted[0xdCA477380D7C900E837893e005095Cc4Ae4b8109] = true;
   isWhitelisted[0x1298B2688bba1b07C9b870bB6Ee5a1896C8cC4cc] = true;
   isWhitelisted[0x01aC6170Cfe8AeB0599791e77D240b5649c82019] = true;
   isWhitelisted[0x38E181B329bB4d433a192110C2E1780a1aae75A7] = true;
   isWhitelisted[0xEEf58Bc9A927698005517a6F1404345332634a6c] = true;
   isWhitelisted[0x1d197a512b33F26DAbAFf498769BBD5A37Df13B6] = true;
   isWhitelisted[0x917cb2AC7E75CAF5a24a780cd6812AF9c3A24b7E] = true;
   isWhitelisted[0x127ec63C079cE2986752Bc4EBdB4f6F1Ae642b12] = true;
   isWhitelisted[0x3dB63BC12c0822EfFE844320a54E7F3D61B91C8a] = true;
   isWhitelisted[0x2fb8179c8ca593913A620894e9Be85199c27520E] = true;
   isWhitelisted[0xf659287d878c0E5c4262eEbE8470c859Cc0dd2d0] = true;
   isWhitelisted[0x2B314B18fEb6288b6b2aB86C77E13f1404dFa858] = true;
   isWhitelisted[0x1945e89f56e34F47250219b809d33A68C1354825] = true;
   isWhitelisted[0xA194557E55254e6251986982E63A0C813ed18758] = true;
   isWhitelisted[0xdcF2e719edD8E90DcBa981161f62a1667c68a5a8] = true;
   isWhitelisted[0x7B8F1C54E8068960AE703D62aAD4fc1E1B23AdAD] = true;
   isWhitelisted[0x8752752f7dFbbeE2A767E84Cd54844DAFe20f659] = true;
   isWhitelisted[0x6c1f1a4C4F79c3bf05AB66c2794fd06cfFB3D60C] = true;
   isWhitelisted[0x9E52c050DB6aBd8a806aE321ede55b8bBE581053] = true;
   isWhitelisted[0x215bC454dA079d610abDf1619D1B29C7795A7996] = true;
   isWhitelisted[0xC995073Cc9620FeCD487ed9Ce85E0e434EF0e6d0] = true;
   isWhitelisted[0x5192e971E7587c1e11B7f5fA6730761c3cE6FE67] = true;
   isWhitelisted[0xaE9Ff5669A5B08685A31e1628F5e0De4F25fa7A7] = true;
   isWhitelisted[0x980F18a06a74005ff6BaA867fF617198db85a590] = true;
   isWhitelisted[0xF82f170951dcDd975aF7418292c545e8dDa7878E] = true;
   isWhitelisted[0x41820b093214C882E1c1F4f2D2FC31E12454d7D9] = true;
   isWhitelisted[0x35760c130C64422A5D9Bc611Ce9185a67cB2c859] = true;
   isWhitelisted[0x3aAAE5C3c0f1F3b239cb6a5F02e105674De13bB2] = true;
   isWhitelisted[0x6CF0264773F9c48cb69D066e748a725b7F14b37C] = true;
   isWhitelisted[0x867D8D20009B8b875C46dB5904c2CB40380587CD] = true;
   isWhitelisted[0xD4a75dBc3B3814d3cB9f080548Cc205DF2A89d70] = true;
   isWhitelisted[0x50B44FdB2863ECfdCB2371A8a470f8239BeF7D01] = true;
   isWhitelisted[0x2e57203018d6d3A6a6d6239735501C30185Da659] = true;
   isWhitelisted[0xD4a75dBc3B3814d3cB9f080548Cc205DF2A89d70] = true;
   isWhitelisted[0x1901fb29Dc5eB7736C633811f1117A1a05F5C5aa] = true;
   isWhitelisted[0xF27f5bA2744F0c81d857aC41caf17d15758993BA] = true;
   isWhitelisted[0xe3b1A119262ae006149B93BF5d0268c01458122b] = true;
   isWhitelisted[0xC8e78d7e59318D564ea55838D7E0caa775cc0BFF] = true;
   isWhitelisted[0x5C9E05b8426BA9C4a74eA10cfDb1fb2DcB0d3802] = true;
   isWhitelisted[0x02082f45eE3A5d224e0e0d5E79FCD271FEedBf8A] = true;
   isWhitelisted[0xfc3E12F5762777F30ACCb6d155e18C6217209E79] = true;
   isWhitelisted[0xd4D3Dc5dfe9018C8B96fD9e3acC1F1BebD99ad3e] = true;
   isWhitelisted[0x16c5F0f89C19081F8ACC3f6913406f2FB24F48b2] = true;
   isWhitelisted[0xF38b8ca997Da3D26454b75EA526b5704464B534b] = true;
   isWhitelisted[0x74aba40276a2bD38447493B36628F7929c16E20a] = true;
//   isWhitelisted[0xa66eff1127f7ec4006d5127ac6c6d2a8a911f04a] = true;
   isWhitelisted[0x24260672D7123BA8b62f0c3726fFC2C163D5897f] = true;
   isWhitelisted[0xe372194D6941d80055795e9Bb078e357D2ad4a75] = true;
   isWhitelisted[0xb14C4B37D21C32c8Bc5C8A7fDcf71A896a929e9e] = true;
   isWhitelisted[0xfbADA7b9F5470994e8975cD9cFef4Ea3809f13ED] = true;
   isWhitelisted[0x8c7247F7Dff6488809A65A7dB055539aFb954dD7] = true;
   isWhitelisted[0x3BF2fE6BFB2c713fd82ca4b93f1Fbb507A389671] = true;
   isWhitelisted[0x4474aFF745BdeaD9b72698f40922E57072410753] = true;
   isWhitelisted[0x7D5E9455A935927d223F64Ad5556114F79e46BC4] = true;
   isWhitelisted[0x2afCad81d08C2a1dD55f35670e518A486Ca6489B] = true;
   isWhitelisted[0x4A2BCf5425355E1e46473B9D4A6d13c5C570aaAf] = true;
   isWhitelisted[0xEE11D85440a16ca3CDbd9e6b30Ba89822231B225] = true;
   isWhitelisted[0x5606f4599684d7e8d19cA69dE79Ad78f498EF08e] = true;
   isWhitelisted[0x8F6F61dC51A120b83a058384FE031E25b1C2B37a] = true;
   isWhitelisted[0xe63E675e737cdCB4ac0ECe9320a62e0857179e26] = true;
   isWhitelisted[0x0233fdbAA08e028E70E1364F34f36238cbdc6479] = true;
   isWhitelisted[0x3E87182E4fA1A3AF295FC9A927Dd73Bd3317D86A] = true;
  // isWhitelisted[0x978259e821b98060290cf4269334843f8feff90b] = true;
   isWhitelisted[0x521167AA23F20b746c9E9f1c32CeD9f1b4Cc579d] = true;
   isWhitelisted[0x73a82FFC0597D8d62B2E5a37f3eaB80D7A430C8F] = true;
   isWhitelisted[0x2B314B18fEb6288b6b2aB86C77E13f1404dFa858] = true;
   isWhitelisted[0x1945e89f56e34F47250219b809d33A68C1354825] = true;
   isWhitelisted[0xA194557E55254e6251986982E63A0C813ed18758] = true;
   isWhitelisted[0xdcF2e719edD8E90DcBa981161f62a1667c68a5a8] = true;
   isWhitelisted[0x7B8F1C54E8068960AE703D62aAD4fc1E1B23AdAD] = true;
   isWhitelisted[0x8752752f7dFbbeE2A767E84Cd54844DAFe20f659] = true;
   isWhitelisted[0x6c1f1a4C4F79c3bf05AB66c2794fd06cfFB3D60C] = true;

   isWhitelisted[0x9E52c050DB6aBd8a806aE321ede55b8bBE581053] = true;
   isWhitelisted[0x215bC454dA079d610abDf1619D1B29C7795A7996] = true;
   isWhitelisted[0xC995073Cc9620FeCD487ed9Ce85E0e434EF0e6d0] = true;

   isWhitelisted[0x5192e971E7587c1e11B7f5fA6730761c3cE6FE67] = true;
   isWhitelisted[0xaE9Ff5669A5B08685A31e1628F5e0De4F25fa7A7] = true;
   isWhitelisted[0x980F18a06a74005ff6BaA867fF617198db85a590] = true;
   isWhitelisted[0x35760c130C64422A5D9Bc611Ce9185a67cB2c859] = true;
   isWhitelisted[0xF82f170951dcDd975aF7418292c545e8dDa7878E] = true;
   isWhitelisted[0x41820b093214C882E1c1F4f2D2FC31E12454d7D9] = true;
   isWhitelisted[0x3aAAE5C3c0f1F3b239cb6a5F02e105674De13bB2] = true;

   isWhitelisted[0x6CF0264773F9c48cb69D066e748a725b7F14b37C] = true;
   isWhitelisted[0x867D8D20009B8b875C46dB5904c2CB40380587CD] = true;
   isWhitelisted[0xD4a75dBc3B3814d3cB9f080548Cc205DF2A89d70] = true;
   isWhitelisted[0x50B44FdB2863ECfdCB2371A8a470f8239BeF7D01] = true;
   isWhitelisted[0x2e57203018d6d3A6a6d6239735501C30185Da659] = true;

    isWhitelisted[0xc0237e3BF59761A149696c2474BE8fd36370ea6a] = true;
   isWhitelisted[0x1e10A9C9E479130331e9B2b23d6CDE2aB5aaC526] = true;
   isWhitelisted[0xdCA477380D7C900E837893e005095Cc4Ae4b8109] = true;
   isWhitelisted[0x1298B2688bba1b07C9b870bB6Ee5a1896C8cC4cc] = true;
   isWhitelisted[0x01aC6170Cfe8AeB0599791e77D240b5649c82019] = true;
   isWhitelisted[0x38E181B329bB4d433a192110C2E1780a1aae75A7] = true;
   isWhitelisted[0xEEf58Bc9A927698005517a6F1404345332634a6c] = true;
   isWhitelisted[0x1d197a512b33F26DAbAFf498769BBD5A37Df13B6] = true;
   isWhitelisted[0x917cb2AC7E75CAF5a24a780cd6812AF9c3A24b7E] = true;
   isWhitelisted[0x127ec63C079cE2986752Bc4EBdB4f6F1Ae642b12] = true;
   isWhitelisted[0x3dB63BC12c0822EfFE844320a54E7F3D61B91C8a] = true;
   isWhitelisted[0x2fb8179c8ca593913A620894e9Be85199c27520E] = true;
   isWhitelisted[0xf659287d878c0E5c4262eEbE8470c859Cc0dd2d0] = true;
   isWhitelisted[0x2B314B18fEb6288b6b2aB86C77E13f1404dFa858] = true;
   isWhitelisted[0x1945e89f56e34F47250219b809d33A68C1354825] = true;
   isWhitelisted[0xA194557E55254e6251986982E63A0C813ed18758] = true;
   isWhitelisted[0xdcF2e719edD8E90DcBa981161f62a1667c68a5a8] = true;
   isWhitelisted[0x7B8F1C54E8068960AE703D62aAD4fc1E1B23AdAD] = true;
   isWhitelisted[0x8752752f7dFbbeE2A767E84Cd54844DAFe20f659] = true;
   isWhitelisted[0x6c1f1a4C4F79c3bf05AB66c2794fd06cfFB3D60C] = true;

   isWhitelisted[0x9E52c050DB6aBd8a806aE321ede55b8bBE581053] = true;
   isWhitelisted[0x215bC454dA079d610abDf1619D1B29C7795A7996] = true;
   isWhitelisted[0xC995073Cc9620FeCD487ed9Ce85E0e434EF0e6d0] = true;

   isWhitelisted[0x5192e971E7587c1e11B7f5fA6730761c3cE6FE67] = true;
   isWhitelisted[0xaE9Ff5669A5B08685A31e1628F5e0De4F25fa7A7] = true;
   isWhitelisted[0x980F18a06a74005ff6BaA867fF617198db85a590] = true;
   isWhitelisted[0x35760c130C64422A5D9Bc611Ce9185a67cB2c859] = true;
   isWhitelisted[0xF82f170951dcDd975aF7418292c545e8dDa7878E] = true;
   isWhitelisted[0x41820b093214C882E1c1F4f2D2FC31E12454d7D9] = true;
   isWhitelisted[0x3aAAE5C3c0f1F3b239cb6a5F02e105674De13bB2] = true;

isWhitelisted[0x9Ad45Ad957ab6E824e19052e1857D3c8eD277956] = true;
isWhitelisted[0xcA4f1c5a8d87977128AcbF3F4B06B05c30508c18] = true;
isWhitelisted[0xf4DF2FF2B0da2713D2Cc11c1107a4bF16Fe4BFE0] = true;
isWhitelisted[0x86A05D1126CB88E83B8f2c78d3a83a28452C9596] = true;
isWhitelisted[0xcEea4692118870cE7a7F06CB9DD5ad7AE3aaaB34] = true;
isWhitelisted[0x112CDe137e6e33E10013C11Ae1f68CD794E7681b] = true;
isWhitelisted[0xf51040e6104A86ec66B0ece14E09De7d24a1eC2A] = true;
isWhitelisted[0x4f8Ac8dDf07594Dc07eFAB48CDc1aCa5602FD50c] = true;
isWhitelisted[0x14336c4d418470216234854CeF785456C46776Ba] = true;
isWhitelisted[0xb6CC2F281e1656175B3Ee89d296363CD60CB960f] = true;
isWhitelisted[0x7E379700e7aBFA425425a2D60C83E9f433b76f89] = true;
isWhitelisted[0x11F65410e735C6F6594081AFcEbb65D8322686c9] = true;
isWhitelisted[0xB79B199e265026b0A6C16F3087A994E283a8c28D] = true;
isWhitelisted[0xD91F62B8099005d2b9c9E7F07c2e4421E5312365] = true;
isWhitelisted[0x151d38bf67EecA05b60D540571bDf5d4D3fE22F9] = true;
isWhitelisted[0x0A945Bd1447e62f6641F1D07f858F4C7929eeea3] = true;
isWhitelisted[0xa410C73Cec32a90ddbdbf3AB22Ff577223e79f61] = true;
isWhitelisted[0xAa73A22a7c06ee84A6F2b131521e619F25Ef2604] = true;
isWhitelisted[0x2C2e865C7b9502F463DB9712D3F96d065430ec2b] = true;
isWhitelisted[0x84ea0b8D5B920e6A10043AB9C6F7500bCb2C9D25] = true;
isWhitelisted[0x1d98E614Af33103Db041C4E6f1BB7B8b80B365c7] = true;
isWhitelisted[0x22804662402C91506B417B2f230Ec985D11E1b61] = true;
isWhitelisted[0xEE7094B0D871b9c86d6205A560E6b7f7F3934EaE] = true;
isWhitelisted[0x3E978737B944Aa84cf289108C5c5D8C3b84C748A] = true;
isWhitelisted[0x760794E900773A1B156320310B49FD6d0e1aC8f7] = true;
isWhitelisted[0x300dA6033Db2a0980F1D57F911404630Ba4B201b] = true;
isWhitelisted[0x2cbfcDf7C9a902165F424353DABeA0dEd36C4D43] = true;
isWhitelisted[0x9E9D1685B1c8dC39C093F6e9dFF98883653E6082] = true;
isWhitelisted[0xF1916e25c9faB017b96731862bbac79014965c70] = true;
isWhitelisted[0x258398E02394Dfa32617E1704F978367237De1df] = true;
isWhitelisted[0xC2eaCFbB2FE0064523758687fE3dDe3bAa76dE4C] = true;
isWhitelisted[0xFe0a7d7C7398344d44aD01C2E43eF8CBE23951a3] = true;
isWhitelisted[0xD2768183Eac450C8b2512EBFAECE0a530561d3F8] = true;
isWhitelisted[0xA3834d217fF52424aE8fC4E2e3Fb606402cbCeF5] = true;
isWhitelisted[0x42aAeb300DfFdEFF24C8011cc8AF812f17Db4FA3] = true;
isWhitelisted[0xabC57fa5f1B1d8167b09470F9321fd541d8DD716] = true;
isWhitelisted[0x71dd00b6DB497B7DdaAbCb2D1cd4DF59Eea9965B] = true;
isWhitelisted[0x14A800De3C0417955177b795f6CD641cab38e80F] = true;
isWhitelisted[0x02e3D364666cCE698883aE5d3DD2b8f763effD26] = true;
isWhitelisted[0xB6de61396E901733BF32aC526df88a0D919F9BA7] = true;
isWhitelisted[0x35146c49702c57D39CC7574815a3e77481c0e844] = true;
isWhitelisted[0x34Ee2a04a890748F73eE8F5297ee0c2f8723e326] = true;
isWhitelisted[0x3161C3275AB9Cd4dE09b5D1c030A63620c38fF74] = true;
isWhitelisted[0xC6519EaB2e1AccB4f861BB0372E7b4EAA561061D] = true;
isWhitelisted[0x0646DFd4471C92bBa29e5E4Ea129E1E8952FBe50] = true;
isWhitelisted[0xff1C967488C44d55a3aDF184AAbf51eFEB8f434D] = true;
isWhitelisted[0xA05B34672288523824FDF41389CD5E2555534171] = true;
isWhitelisted[0x0A89D35FCF6a00199eE44188bb23264E002Cf45d] = true;
isWhitelisted[0xd74B62D56C5f6D8Cf72c6267Ba51A05EaDb31302] = true;
isWhitelisted[0xbc490601Ca43849C3cc56090A6bed245f34E899C] = true;
isWhitelisted[0xD0b891D75A3441518fBc732b64030597e976bEAB] = true;
isWhitelisted[0x528848397D0e914EC951dB10A506Cc0820a81C17] = true;
isWhitelisted[0xDB5Df77973d383cdd8873Def4e89dC779aA36c85] = true;
isWhitelisted[0xA2682ceF27A63e7237A6Dfd8775BaEC62B044BFB] = true;
isWhitelisted[0xa4c65b3aEa78D9541090066aA316D23F6C8f1888] = true;
isWhitelisted[0x75Ecf7A13DdcD1fBf5630B0dd321660F6183b7aB] = true;
isWhitelisted[0xc6Bd4003139cF6473029a17978912ad57db80D0F] = true;
isWhitelisted[0xB47832cA65E661b2b54dE39F24775C1d82C216f9] = true;
isWhitelisted[0xA89fF0c83fe738caC5266373f15Da2e38eA557E3] = true;
isWhitelisted[0x5794C30A3Bc498928170B0d65A10893e2cC4BcBB] = true;
isWhitelisted[0xe8d253b40b6d72e760b6C3fCCA59f298F25faefe] = true;
isWhitelisted[0x3e0fa59be2E617BDf6B8B941b27f3b6938221860] = true;
isWhitelisted[0x188CAC6862FA7fd569FffA4cd9E03D7b8D905583] = true;
isWhitelisted[0x25D58D37443D24Af757B290dA92a10022b704e7a] = true;
isWhitelisted[0x07E1Beb5e3F5A1A0a5DcA1b0F6Da28395fBFB5fF] = true;
isWhitelisted[0x3FD10008230d8d7D2f2E6645F625913359Ff988b] = true;
isWhitelisted[0x14131498D74A0a54453B81e667d0f657feCb1A81] = true;
isWhitelisted[0x4E48670aac02291014Dd28DcEba999Cbc44f88Aa] = true;
isWhitelisted[0x592467de8e2d90cf2eF255b27D6aCf3AFC32a43C] = true;
isWhitelisted[0x69cdfD80aDbeFD5170e24785222A54D27Fc695Ab] = true;
isWhitelisted[0xDd7Ef33957AbE444E364081B5cfE92b238d7A72B] = true;
//isWhitelisted[0xe08a23ae2c7adad00fe2ff5ca8aed58a3dd30db0] = true;
isWhitelisted[0x10A2C4790F045C2B1A3c47A97815f765c124621A] = true;
isWhitelisted[0x40E949E851722407950870e2403f71670A8c4500] = true;
isWhitelisted[0x4C667769cfb14DC6186F8E2e29d550c3E538D89b] = true;
isWhitelisted[0xCeAed802B8a70D119533fe664592FB432B153489] = true;
isWhitelisted[0x816342193A94aE0Bf0A4807976F78d5Ab03D12EF] = true;
isWhitelisted[0x4882cDECdd1fd12378429D7F0060A74220a88662] = true;
isWhitelisted[0x0e1248BE29D02fb62461b32aEBd77C330E9CDa00] = true;
isWhitelisted[0x42DdFA7855199bdb666D16f346683Bd4355C1c4B] = true;
isWhitelisted[0x9f786E348B8e27de9A15eFD7cd72a380e0F978D7] = true;
isWhitelisted[0x0B526D6b016e55EE5D7b81497D36FCF8EeCd0B2c] = true;
isWhitelisted[0x04FFE17dc350F5642C9bB601244BCF70ee18E2B1] = true;
isWhitelisted[0x0E9d8D217919fF7265a6059147f41076C1b4D61b] = true;
isWhitelisted[0x18eE63b1A7041BF44b4Df93a6918558404ef9FDF] = true;
isWhitelisted[0xf8c09DAEEce7D41136626De44bcB9438ecD468bf] = true;
isWhitelisted[0xbB61a87614A75Dc8d9475935b67f7181E6585E0A] = true;
isWhitelisted[0xd2ec2681f57159BE4b7AEFa765AA998623E70f09] = true;
isWhitelisted[0x42674BD41D9c1De2082f4dF2A982d66bf8c3e9DB] = true;
isWhitelisted[0xD32497Ce675A70Ac3Cb847822F1eCBCae7A0D5D2] = true;
isWhitelisted[0x460Dc65b93BB4c271DeD8AD3D19c0b4922F6F5Ae] = true;
isWhitelisted[0x29E73e95dd5d1C9CC62caC0E1A22896343C77dCD] = true;
isWhitelisted[0x312Bf4C683a0E6ca4D6f1cC955AD6AdD321D2D6A] = true;
isWhitelisted[0x0c3Efbe3e7CecEE4d6247436475b400c12A3623c] = true;
isWhitelisted[0x154D801857b44C770241845195902098e4184ac3] = true;
isWhitelisted[0x9b7BA182296B63aB2D48A06Dc96D66499e19b6d9] = true;
isWhitelisted[0x7562F42f9E673bC6B49D4A4D5D4E543D7c98CC5C] = true;
isWhitelisted[0xCAd350b4f2284b9F7D44b345BbE89FeC539A543D] = true;
isWhitelisted[0x1e8C88e051f5747E0d74d4D100Fe254a33158A67] = true;
isWhitelisted[0xB57e20c15c19D172aF38211170c1F7181A49A3B4] = true;
isWhitelisted[0x1Af7e4f484cb2542b518Fb1B521B1af585F6cA89] = true;
isWhitelisted[0x16C7080663e4CA5B5960BB02bBB5019624A4De6b] = true;
isWhitelisted[0xb8d1af5612377692859bb4f1b0ec95770Ded6214] = true;
//isWhitelisted[0x970f69e6b0563922d206efa4696c00a2b46592de] = true;
isWhitelisted[0x989Cae3d77853E73957fa8bE58A360f3C00fe4E8] = true;
isWhitelisted[0x4b5D448082809a3aA567Cbd22778533e6dC2014b] = true;
isWhitelisted[0x0B2bDc536E0FF3F4E868B4D401700788CCf26689] = true;
isWhitelisted[0xe723cA6Dbd2fB1aD9823e581433EA9fd3a9E1c2c] = true;
isWhitelisted[0xf49f1A14c73FEd03D1B1D2d77547865bbdAB8F72] = true;
isWhitelisted[0x09E7c874004e7504cb2c8CF8D74106f627501A66] = true;
isWhitelisted[0x9DfAC321d473953065A6B1C98F1E8F16A02a6EB5] = true;
isWhitelisted[0x306BD95c744269d56ED69df1152884cF1cC7749B] = true;
isWhitelisted[0x86508f8707dfe30E30Ee8B9f2aa357d93EF76606] = true;
isWhitelisted[0x4613D3aB1A6e4e99407Fed763CC89Fbc44B8F093] = true;
isWhitelisted[0xf5d3cA65C56c2F7417de060a6383F241Ad7405F0] = true;
isWhitelisted[0xd38D057F68C20965f870811E8eF935Ffa66cEEcc] = true;
isWhitelisted[0x243D4a4686a5698aC5B2e707D73EB3AD5d712C3e] = true;
isWhitelisted[0x589B4d7a2AE20Dbc2A425522a6Bab40F881B8d42] = true;
isWhitelisted[0x2294E4345ed8BEd4e98a1523205c23740DE221e3] = true;
isWhitelisted[0x825acd62C9F7631939681d00802E7d58fec19F83] = true;
isWhitelisted[0x1724f84dE8b6DDdA1833fb031eaB8b093BB648f1] = true;
isWhitelisted[0xaaCA3427C4b7E9FAF6F931EDC8Ae947b2C1cE81D] = true;
isWhitelisted[0xd9008CAFED0263cc9730A1035db1fE14c29ce8d9] = true;
isWhitelisted[0xc2dA4EaD71A2b02B9dA4679Fad969058d3B4E30F] = true;
isWhitelisted[0x80ec0E51EFB14c766Af9967770105C9D51e5473d] = true;
isWhitelisted[0x9714F318BB0606f284Ee2d40c51Ba05193eC6822] = true;
isWhitelisted[0xf43890CB8c11508b000A32caD5aeD9aA506aFF27] = true;
isWhitelisted[0xdaf4B76B9eCFc758D8d3f46A3a0BF9df2797A122] = true;				
isWhitelisted[0x0D1d5976b3E0400df0Aee00c93E77DDfD0e2Db57] = true;
isWhitelisted[0x07F3AF0547c45390a44FC62B2D4BeA0670Fb6147] = true;				
isWhitelisted[0x55eb72F2A5694aee534B8dd2cf7ea1F8bAe584C5] = true;
isWhitelisted[0x54cC37D004bD21A2134b3264a1C769110728d84c] = true;
isWhitelisted[0x1DEb1577aDe681A1D5C691849f86E17a3eb10094] = true;
isWhitelisted[0x6D0c5B9Ebd21f82C6e144A91eE368052AcFdb828] = true;
isWhitelisted[0x408ce0389e54a4A5f14EFa5c33bf854CB9058F5D] = true;				
isWhitelisted[0xE0C7df73489d86fa72d78BAd3E053572a042EB11] = true;
isWhitelisted[0xfa30D4b626f2f991911dc27022F4e1A0Abb7bD17] = true;				
isWhitelisted[0xAAAB2Fa4EcE4459A92Ab0d89EF52644CFEe02BA7] = true;
isWhitelisted[0x50Bf12AfA927dE8B029706106eDE5b9A2884b597] = true;				
isWhitelisted[0x11b459F0cFb526EBdEaE78E4f49a6029cbd8Ce47] = true;				
isWhitelisted[0xBbc43C8Ba140e56306264cdd29fa90d9584b58CE] = true;
isWhitelisted[0x8Ef9713a159413f6617dC1E5b10eeEaDbf7D4273] = true;
isWhitelisted[0x055C5F004564Df49f58e5D5206567B28bD01f305] = true;
isWhitelisted[0x508c1474d0331a7D89D5169849Eb5c30220Cf289] = true;
//isWhitelisted[0xf941e30b4aafab54652dd5d3dcb99a1e9985721b] = true;		
isWhitelisted[0xF31E22A7580520b70B04089435d3BC5cDFC89Cda] = true;
isWhitelisted[0xBD7C5fF269BAa9C4793F68d624D0f7fBaA421b63] = true;
isWhitelisted[0x9d176e7Ce4A2F68E258913417Cb23008aD5eE3B5] = true;
isWhitelisted[0x161E4f0051e03e8F30C3A0f685917f173A1B0a3E] = true;
isWhitelisted[0x614D2Cd03A4E5e8e28b7eEF4692c8B1854F5e333] = true;
isWhitelisted[0x4662f95b81018bC91c5D478Aa12C9Db9A5007755] = true;
isWhitelisted[0xd4aCad6D89DcC601bA239826e7F052a20a6976f4] = true;
isWhitelisted[0xCB9b7BC07E3a5603AFdB9dD3c5b4C73256Aa5c8c] = true;
isWhitelisted[0xfBC2e1991382669e6d5c7b6dB73410984a4B814b] = true;
isWhitelisted[0xea2D0f402766C435556C090eC8e3691aE19E7e64] = true;
isWhitelisted[0x892A06e25AFD1E3e6aded066E9fBd61b39F33Cff] = true;
isWhitelisted[0x59D4B0BEEC360f27d26988351De0eA2a9bE92E11] = true;
isWhitelisted[0x0f0E02f79D1629F13419eCaE49F85BC3c0786BD0] = true;
isWhitelisted[0x709C54205382d9Ff0b31F1EAc8041afd78fC6B67] = true;
isWhitelisted[0x9F82FCA6Fa33F4dA2acBd87ceda56cf4f8bA9996] = true;
isWhitelisted[0x4a0B7153f3610CfDf2D28939d21A8621FB8552C4] = true;
isWhitelisted[0x7e1d21715bfc0EE269268C619363DD1c6EFf2b52] = true;
isWhitelisted[0xf81E7500ac2512ecA096301eBD4fa2dE19Cd3DC5] = true;
isWhitelisted[0xb1fAf1AeD6f3b5667A768Bca4A140A0FfB518e94] = true;
isWhitelisted[0x07E1dC8ECdD1332aA3716416Bd1DF2b7Bfa1afE1] = true;
isWhitelisted[0x86bBd91d67E872dD1831198b64Eed723DE61240e] = true;
isWhitelisted[0xfc3E12F5762777F30ACCb6d155e18C6217209E79] = true;
isWhitelisted[0x49F657082E0Da88Fb45eC876201E95CB1078A9C3] = true;
isWhitelisted[0x0cA311791BD64856B5c36eC047c9DbC82a083859] = true;
isWhitelisted[0x42eB5E1A075d397024099173D3deAA3E7Fd380B0] = true;
isWhitelisted[0x68Aa761c027B5d5f528f359101bC9EC31504a18C] = true;
isWhitelisted[0xC4808f39fCe8d4ef8aAA0B013727d3025d4BCc23] = true;
isWhitelisted[0x457Bf0C1666C13c31100868727525984d162Dd79] = true;
isWhitelisted[0x734a3E37A47F69acF34D3430a99d0a76FE078118] = true;
isWhitelisted[0xE34CEa6bA44080Fb5C2307db6c0b375Edb5E6e54] = true;
isWhitelisted[0xc0B98b79e4ae406A05f35C334D28C6b613C1EC9f] = true;
isWhitelisted[0xb0246c3aBD71b90949541dF2e185df4740e04DcD] = true;
isWhitelisted[0xe511786A12C99A803b51a95CC68cfbb4267f666d] = true;
isWhitelisted[0xAaa25b61814f4AaaAE0993770b1dF86b70076c58] = true;
isWhitelisted[0x17B4579A8E4E3eF61A3437931f6550F12B032CB5] = true;
isWhitelisted[0xD67590C2cf95544Db488d160C81C9C8d1B81f19C] = true;
isWhitelisted[0x87e44Bc66A71b999b1B9097602182CB58dC0A1a0] = true;
isWhitelisted[0x1A0A1B4Ad49a6728F28e1ad43B04c73a2661d6dA] = true;
isWhitelisted[0xD9b2993De41962F385C3866a1e3C463bb8ce8EB4] = true;			
//isWhitelisted[0X191De41A568De8205117Cb10894C2D50Da2038F2] = true;			
isWhitelisted[0x9ce8219a0104AfDC5cDA0c20563C3af1C0bEf68e] = true;			
isWhitelisted[0x0872310CFE6e5EAEAa468dabC744ad3d91e08de9] = true;
isWhitelisted[0x8Fc015f2cd9707361528bcE580593f6fc26F0adC] = true;	
			
//isWhitelisted[0x5FC5DE10b0Bab154c6D64B56F3c6287138462E36] = true;			
//isWhitelisted[0x7086d6f28b3022da6f915d8217a78ba7f33b06a3] = true;			
isWhitelisted[0x65726422bfB7F654A8d9bD18aAe063728D475b1E] = true;			
isWhitelisted[0x69A4cdc298012Ca0242ffcd08621a7cAB382478f] = true;			
isWhitelisted[0x957ea7523Bce280c95C0a474843f0641FB265AC2] = true;			
isWhitelisted[0x5c5FA1ea5a3C5d87B1d6b4E128a7553DE0260863] = true;			
isWhitelisted[0x3f3Ac45b916821af2106FB3Fb04db3aA12C59061] = true;
isWhitelisted[0x0C179227Cc88e6780bBE6B2226D9DF51A5eaA340] = true;
isWhitelisted[0xccD75449E369d6a70337442eC61A0d9291E4542d] = true;
isWhitelisted[0x4FaB7fEDE39476B020d2d40D81976A29aE2D2F55] = true;
isWhitelisted[0x62ea03AfCbC013fdC554E23221D099c89Cc5fd80] = true;
isWhitelisted[0x4f8C19ae8aA24b98Ffd9c8B88b6FD75cfcB63b0d] = true;
isWhitelisted[0x0ecAA331dB09CaDBaFD0d9a8ed49ff5Eb68B8702] = true;
isWhitelisted[0xCFafb58fE229Ab2b56424668281dA8B6eF4D2353] = true;
isWhitelisted[0xd85857F659E2158dde5d0Aa5Cd885a7dDBFC37D8] = true;
isWhitelisted[0xa2b9E94df4dae0EA0Fc1D02F6ac7F63D395b9B32] = true;
isWhitelisted[0xd4869Af355dbc9A9974Fba94E6e110305205d1F2] = true;
isWhitelisted[0x534a03F24DcC904be70D735e013130f82b16925c] = true;
isWhitelisted[0x9329DdDfd794750422be6D1c1e4531ef7Bd03911] = true;
isWhitelisted[0xfaDc1c930057eB02829FB4961C13E35b4f8308bf] = true;
isWhitelisted[0x7409aD9E19e0Bc635ea22615613F768fb95a5465] = true;
isWhitelisted[0x63CC810A5671E40C4c3E4d8E923AdF41cE573dAD] = true;
isWhitelisted[0xb2bFFAeaD4F4A4344E115f0c28eB16BC8f183b80] = true;
isWhitelisted[0x4E331616a6f65eA8012C9e4c0C81Bfe30EA7fa06] = true;
isWhitelisted[0xc17E19c7196372c2E0391a2E2B9DffDCc2408e2F] = true;
isWhitelisted[0xD50a0315094540f76a884b0d570F3AF870Ca6F15] = true;
isWhitelisted[0xa44e72126738ba60898521E95CE2f392A40F155C] = true;
isWhitelisted[0x8E04Ac8dB448F8045cD28B5d69577085Bf9EB580] = true;
isWhitelisted[0x35D2e8a8c9f0F6521a509287fD8c1d6a718D8806] = true;
isWhitelisted[0x180f79B2809C3D341a5B7a06fB059B388433fA2A] = true;
isWhitelisted[0x97c4A9935441ca9Ee67C673E293e9a5c6A170631] = true;
isWhitelisted[0xCC7f30f5a09B90Fe9576392Bd49CF1c856C5B5C9] = true;
isWhitelisted[0xA7839B0d337AEff5d51Dd61a6c8393EA06e67638] = true;
isWhitelisted[0x837A9901300312c86884902DB2bFd343A93604Dc] = true;
//isWhitelisted[0x996c63b339530c309305a1870a18f2c8d83095b7] = true;
isWhitelisted[0x5b8F61034880908d9BED15BbD3154Ae9357830f1] = true;
isWhitelisted[0x713d63C51894bA27E1D844D9992F6d3e92685582] = true;
isWhitelisted[0x2cEa922beDd4796265DDA912DEb2B5f61032F55F] = true;
isWhitelisted[0x6d96f35442D3d55978c103577C7905B72b40050b] = true;
isWhitelisted[0x89d2f42420DFa7Bf5a71a672B9a6856B9A5c4eE6] = true;
isWhitelisted[0x12513059Da3607ad4652C33D8b50ea189192D6B1] = true;
isWhitelisted[0x217B616d843e4e0028EEf0379734C764Fa57e5eC] = true;
isWhitelisted[0xe347845CD3502E8c21Ef588EfF38fadF9E78eaF3] = true;
isWhitelisted[0xcDc7B472e4cd7d8Ca1D2470Ab665A9BE1C2bb24b] = true;
isWhitelisted[0x196D34dD5091A74e391b7f0ED2Fe62328285a85A] = true;
isWhitelisted[0x6a93Cb1807155b07720ABb80527647eec777703D] = true;
isWhitelisted[0xb251e24A2f657Dcdc1Ade27990269f34dCB57613] = true;
isWhitelisted[0xc173E56c96BA3af606d75ED4f97A85FCeE107166] = true;
isWhitelisted[0x48f9E54ea73EAB6C5506844bc08B91a5Cd43daB3] = true;
isWhitelisted[0xB2817Ed45f3a24962634A31d18a72022787a6c99] = true;
isWhitelisted[0x6e668bA3D44E5304eeEDfb222d57455d463BECCe] = true;
// isWhitelisted[0xc5d846fd69118d5f535ef9f8debf9eb5d8025466] = true;
// isWhitelisted[0x07c80edf955789a6a00ae3953c322336ab64adeb] = true;
isWhitelisted[0xFbcEE54023922fC4f44C03622A28D74c88A26609] = true;
isWhitelisted[0xfb4b0015ccB490f631087a4867405B76EBFce79A] = true;
isWhitelisted[0x0Ad76F6fe77683CD4408F21925c1cB03cf9270C3] = true;
isWhitelisted[0x630A2Ff284b1D9034e873Bda412122fe8fEd0630] = true;
isWhitelisted[0x9B51F735d58D6FfeaaEC31ed5b5D0Ad881db6204] = true;
isWhitelisted[0x1D3d0992bd1dC67242018Eccf3Eadea711982382] = true;
isWhitelisted[0x52dab65C4Dd615caB6B6E49E23c8Ba4FCd892307] = true;
isWhitelisted[0x9967EB7D1A48Bb5b56dce00a175DA2c1169B7A06] = true;
isWhitelisted[0x51baA32Ba08FFaf3FA54b0cc0A0F7550FB3f6171] = true;
isWhitelisted[0x81170e8142d93Ec62c0846BF83BC1C6480ac0C2c] = true;
isWhitelisted[0x13d9Dd731F17cE6c4E32cC362906781bf9412495] = true;
isWhitelisted[0xB12E3d04d7E626f459E10A1037C2a11Ed89B06F1] = true;
isWhitelisted[0x05B783AAd022ee0386010F88E3b70b42A782d767] = true;
isWhitelisted[0xc04bB6702A9E258A40dba648a0EB8d57ECDE0C3a] = true;
isWhitelisted[0xB394281870E98f0cca0ADCC0cC41E9d741D0d0FC] = true;
isWhitelisted[0xfbBEAC42cEd6dd1F9Aa36a55ACef75fEF997102d] = true;
isWhitelisted[0x7300c04a527Af09148a7Bf00AFBB1FA075fe1459] = true;
isWhitelisted[0x265a19c8547Ee8cCe9b4238B42FD173c8118f9c1] = true;
isWhitelisted[0x3ceF651a075C4f056025984B7A0307f401cE7F6B] = true;
isWhitelisted[0x33061835721753AAACF7817DDd2aaC8375f6b800] = true;
//isWhitelisted[0xc40d12779854d9e0934f5e70f0b9081a4bfc27e1] = true;
isWhitelisted[0x6DBDf7Ae61410142Ae8B6c1Bd7Ecb0E286FcA9ae] = true;
isWhitelisted[0xCcb928CE40bA12C65A47dAEC2BE4152d34f53080] = true;
isWhitelisted[0xfBCfB8cFE56D9eA1471b4DF7f0b3c91214e360E4] = true;
isWhitelisted[0x9262794380A91a82BfdaaF971842FB1ba4a40f02] = true;
isWhitelisted[0xA9C703a7161B5699E5282400C388B825F8d2e76E] = true;
isWhitelisted[0xd4dca0547f02a4AB5a61Ea7fB70671C86113Ec18] = true;
isWhitelisted[0xcdc4707C6f14205392225281E53FEF77A17d4010] = true;
isWhitelisted[0x562b74a4BeFbE9BDD2A4B2c92d8871557b2F9a38] = true;
isWhitelisted[0x5b2E3e001F2a279b975CdbB8CcC88445098aCbFB] = true;
isWhitelisted[0x4a8A0e0d293Ad5A0536b86AbE7B0948c49971977] = true;
isWhitelisted[0x0Ca20bB767A53881cA599D8BD1de944Cf85a7779] = true;
isWhitelisted[0x165628107cAe2B10ACa873C3936e439D387E22b3] = true;
isWhitelisted[0x5b033b4E794136f763e82eBA877DF6fDdfB1f1EA] = true;
isWhitelisted[0x292Be0246834665206B81Fd8C45132feb3Bfa340] = true;
isWhitelisted[0x0349c1eed4224a7D8802CDEC0040690c8820cC31] = true;
isWhitelisted[0x0Fe9D683aF4E50Dd5B7E35C496E12F37c95A0e4d] = true;
isWhitelisted[0x890301776f74Fed4Ba6fEC86710cD29BF7c79Ff5] = true;
isWhitelisted[0xAdC04c42681C9de2973BC3dff2FF4a8b56e89896] = true;
isWhitelisted[0xa0331e00C1592b3A8C8E2109946bfC9AD344264a] = true;
isWhitelisted[0x6fe7F3BC9A5F94a0a4bb3513ce23c8A2A17FC367] = true;
isWhitelisted[0xaE73F3527a334196bd3d38a48e4621b7Eca02761] = true;
isWhitelisted[0x5A7b394B42B184C71e63058062c966C0dfd8A91C] = true;
isWhitelisted[0x547486014c096bF8eBd43d9B2090db6DAeEF2B23] = true;
isWhitelisted[0xB8c17DCf5397bef9B2507ce5C3FDB311Fc0d1295] = true;
isWhitelisted[0x6006eb7Dc114f2AbB8Bdfd4c1Bf28f2A7eDB93D6] = true;
isWhitelisted[0xEE3BCA6833215eB2C4140BdF74F6653cCFA2e04D] = true;
isWhitelisted[0xEd5F4B85b1b1E8ed831979AA3D4222969b7a81Fd] = true;
isWhitelisted[0xe2502EB83f07244A5b5a5Fa878BdBE9c8DF07d93] = true;
isWhitelisted[0xce5B30FDFbb67b4868ABA01754298067fF658778] = true;
isWhitelisted[0x5694d5d95C820B90603D869DA4E63eA43B476dBA] = true;
//isWhitelisted[0x07c80edf955789a6a00ae3953c322336ab64adeb] = true;
isWhitelisted[0x7a855526F3CF3722BB2944037960d5Adc4f00BEE] = true;
isWhitelisted[0x38fAe8DE066c8053AC38Ab625C35A87A9CEF727B] = true;
isWhitelisted[0x168a1203B278B303737728B608a439f98aae8144] = true;
isWhitelisted[0x6a71118F37E055601FB5eA3EB6d1Ac344ADfdEa5] = true;
isWhitelisted[0x3162947986982E70B2FAC2A90bA49d8657F34334] = true;
isWhitelisted[0x1e06FDB842256f9CCe789d7c12E3c2b51B8D9f8a] = true;
isWhitelisted[0x6525ef363d7C5B5C2147705B1E9c43B134708a7F] = true;
isWhitelisted[0x2C94edD8cE8117e084b9A8a82727224cDb7911Ae] = true;
isWhitelisted[0x616e662D822f683B65a67b56aD19F0F4dB87260a] = true;
isWhitelisted[0xd28D16aE1187a56605c11B946502a4EFe8351C9d] = true;
isWhitelisted[0x1BFeA0b4346E3dE1518efABA7a8e7315ff7159f3] = true;
isWhitelisted[0x72113B1aF4579d5865B720e92F8B069838A0fdF9] = true;
isWhitelisted[0x36E8c7FF963F87B362e4A456a2E72b536A3C2D15] = true;
isWhitelisted[0x56Ce43010da792334D8c4A1883EC8028D40c7B70] = true;
isWhitelisted[0x5DCe4a5f28501a0A95031Daa2b748a2864ed2ffC] = true;
isWhitelisted[0x6A64B1BfA53cF8Ce27c906769f7725240bf89b5C] = true;
isWhitelisted[0x2aEd2F8bf852E819b816C8d3D98c96E6ea3068A8] = true;
isWhitelisted[0xfDBFbBEA572cdE5b8497D2BA134508159bd9BeF7] = true;
isWhitelisted[0xD1789248d74123238891201180ba5486e10C8170] = true;
isWhitelisted[0xfbBEAC42cEd6dd1F9Aa36a55ACef75fEF997102d] = true;
isWhitelisted[0x0115Cc8540DE6754af0d634Ae0C40A9065c47350] = true;
isWhitelisted[0x164cDb6bc2430875D865Dd0342d46eb9959647c1] = true;
isWhitelisted[0x820653DbBce12d51781D08D852FD54182d2cc64b] = true;
isWhitelisted[0x3bAA11e659528b84B77dd41075692cfd7433e312] = true;
isWhitelisted[0x6930890A9D838890eD79338bC62a2c28641d066E] = true;
isWhitelisted[0x0612c44541Ae421b5Aeca1B13f41F815b0b2a542] = true;
isWhitelisted[0x8fd564772383Af39D62e99adeB7AC2056c09C1C5] = true;
isWhitelisted[0x146024f37d9E0786C7Da338547218f6229653635] = true;
isWhitelisted[0x24fA9EA7eccB93c4BE60A0cAf238b99426bDD817] = true;
isWhitelisted[0x76DF767ba7576ECA390b80804e2d3fEDECE7C3A9] = true;
isWhitelisted[0xfe45635e4C979b94A8C84D1A00c3C00AA4Bc72bD] = true;
isWhitelisted[0xCFf772D187C308F5F1702Bbb63341E56DB861F7c] = true;
isWhitelisted[0x831A2dAED034Ab0E8955A40230D531f5E58bf6a3] = true;
isWhitelisted[0x22f04f66bEEc899a2e8FD530E0A975DBDfa471dD] = true;
isWhitelisted[0xa3b466dF2E9f4FafF6A031E77D81983322A87543] = true;
isWhitelisted[0x597227b11e66c0E0B744cCae627Ff6fE868bD71D] = true;
isWhitelisted[0xa9EA7a50BFd7a254Bf92A7457fEbc935c5c61F94] = true;
isWhitelisted[0xF1D8eaDE65271Bcd008f7c7AC0F1467f5C675a26] = true;
isWhitelisted[0x0798872F5548FDa38571fFAB2932908b780C0008] = true;
isWhitelisted[0x7CEC1c2F645a535D631b36AfDFBc7F7b95bA680C] = true;			
isWhitelisted[0xb43c98bCCbe3D139c7522B3D283d379C0556fa79] = true;			
isWhitelisted[0x2f902C2664adB96256249f3716405F68788a2775] = true;
isWhitelisted[0x0f3b515313f85F896142067af145c69FB56cD5B8] = true;
isWhitelisted[0xE531a0d87592a44fDb6a97B913Ae5885c9CC74EB] = true;
isWhitelisted[0x0dB03Ac82e0DB70285f91a26534458AA04a54f1F] = true;
isWhitelisted[0xb78D50200070d87ceef5fC4A869dC7cdcD8DeCf0] = true;
isWhitelisted[0x6659e01D258101600C0E08Ccd0a84771B830e9F4] = true;
isWhitelisted[0x517550318518B940434aEbfd0D3c453e42BD2dB9] = true;
isWhitelisted[0x68f3b75DB6e8fE312101aDAE93e017e3F982266D] = true;
isWhitelisted[0xCb81228ad16de47Bc3291DF4aFF6f7a878323b73] = true;
isWhitelisted[0x5c5FA1ea5a3C5d87B1d6b4E128a7553DE0260863] = true;
isWhitelisted[0x7bf5cFEbff76BD377De21E4a5aB6Bf4E2fc34941] = true;
isWhitelisted[0x7ADb4B33B61E130682dE222402FD30108Dc6b91B] = true;
isWhitelisted[0x94352D0aF040Ca385De3758b495Fd4e878Cb5Fff] = true;
isWhitelisted[0x19ff3Cc0B1A38aE29b01c4D0912728831695B0d0] = true;
isWhitelisted[0x8076E55d064D0d05e16994C228D84c6AD7464fa4] = true;
isWhitelisted[0x4b333eCbAdd00717B6959E8f594f65c276EF3F8D] = true;			
isWhitelisted[0xF7656f88C09284D339Be17Dc4CD51c75a0c1d421] = true;			
isWhitelisted[0xAc0a6726B6E9347a7f74EC62127ae64ae01D56Fe] = true;			
isWhitelisted[0xbfEb47eDc734Ca51DD99067Fc4D84Be40b84a593] = true;			
isWhitelisted[0x78b004D04403D40F2d59F4F7685Cab9860689155] = true;	
isWhitelisted[0xd043e26bf75C4747fb236c58728E7e7DBc43871b] = true;	
isWhitelisted[0x8614E2c5C29E7f519df5C74BaEC54C2F77D0Ba5D] = true;	
isWhitelisted[0xcC20B20394Ee0083A6f9EC1904b3BD41756A23Cb] = true;	
isWhitelisted[0xb1d1CAcB757B204Eada4e3C86bf3c9053b95f933] = true;	
isWhitelisted[0xD57d05A2bcDA336B5ac9468A281A3109BE384ba6] = true;	
isWhitelisted[0x972096A793dEf1A76fFF0f33a8f051CA436cF9d5] = true;	
isWhitelisted[0xc938fA75761D43571015A0a58112B4005d12da0C] = true;	
isWhitelisted[0x5Eaf1c13076DDD70fF3c99c39b8Cd77e3507aA58] = true;	
isWhitelisted[0x884BB0501f0602F6AfFe1aA69ab76F095a0B94Ab] = true;	
isWhitelisted[0xDf3A26fC13075d4C641cC6C4CeA4a207fBBF7622] = true;	
isWhitelisted[0xeaC199D7ED06fe0c28759FED24a13e240B8C7F45] = true;	
isWhitelisted[0xe82FA5d95E2A583C7D523F3DC33A0a7260B52dfe] = true;	
isWhitelisted[0x52A404B8A680f088eD9f5005BEF05CaB08bC7603] = true;	
isWhitelisted[0x506c3AD4EB7489672bef74CDC8450d7D94DB95d0] = true;	
isWhitelisted[0x53c54A47e961a1284eec9689C3926106B4D795fC] = true;	
isWhitelisted[0x2b352496283e612f3ef6C558FAb4B3dE7aa0F6d0] = true;	
isWhitelisted[0x1f9142C7e57006398029087Fca029A6e89cF7A8A] = true;	
isWhitelisted[0x904c4400CcEe376229F1252002bd941E0c389808] = true;	
isWhitelisted[0xAc9D8bfE33f953F78149107ef3Adb56F1f95f094] = true;	
isWhitelisted[0x836Bd6323baEBE0Fd3eDACe43A8889a71dE09759] = true;	
isWhitelisted[0xA554E23983b2B6e4edc8F35A023ffc29cFa2C86E] = true;	
isWhitelisted[0x76f391F3eF409deFD54A16AD96dc00BCC6E6D7b7] = true;	
isWhitelisted[0xB10358c6F6b9c42c28947d5294f4406CaaeB25E5] = true;	
isWhitelisted[0x537cf2c6ED631BEBbd3Aeab7D1f38C93E6D380ef] = true;	
isWhitelisted[0x77d0638a584f70290d476F3da48Fd2fb05156106] = true;	
isWhitelisted[0x9af77776EC7bE29dF8d19De062C1611672822dF4] = true;	
isWhitelisted[0xfCd6c48E1152AfbA2b5fd3a93a2424F42B67514f] = true;	
isWhitelisted[0x387b642FDf145CCa403CB3a726c22c7Ac7E6d596] = true;	
isWhitelisted[0x0cdB0D572D696Fc41f9AcC6365aEa6506B1345cE] = true;	
isWhitelisted[0x5ea5ba55F66Edc3a3bf19B9349BCe18584a915B5] = true;	
isWhitelisted[0x8F4a3167c8EB3F4BbF86724387AB4984C9809385] = true;	
isWhitelisted[0x971D108A1De89Ee981e32e60A4D870CE8d362E70] = true;	
isWhitelisted[0x26Dfe3De1DBFC99910fd77f4D45Fd755e6FcbEaD] = true;	
isWhitelisted[0xBF1Fa2011c8869d3416f60b520bE8e534dA375A4] = true;	
isWhitelisted[0x665A6f361345744dA87D5d6c1Cd504499b0645Bd] = true;	
isWhitelisted[0x2d215a46cbF8C2D83b940C0BEE7756815E467873] = true;	
isWhitelisted[0x5A74F7856181EF63A9F2Cf9B331Db67c34E30dd0] = true;	
isWhitelisted[0xA87804498F6AE59B9add422201b310Fe50ffE4B5] = true;	
isWhitelisted[0xa46aDD9d96CeA9b7b85046c75Fa44572c2fEc2C1] = true;	
isWhitelisted[0x793f1d0dDAf3BeEF61c84E826373B4419109B160] = true;	
isWhitelisted[0x6B981D972b09Fd5210ab7E3974D58f10601bd7fB] = true;	
isWhitelisted[0x3deeE1ceF20AdC0d9a8ABf120D1EB082AE39c069] = true;	
isWhitelisted[0x5211258c175506adbe11b3662868C493757ed846] = true;	
isWhitelisted[0xa1d9e0351B194E27f2c487F841e7b77A04fc563a] = true;	
isWhitelisted[0x68f053A5B3DdF30628c6D69a0426263c68B0b4B1] = true;	
isWhitelisted[0x1f003C83920d91D1E1F15458C27f07B18fc65ad3] = true;	
isWhitelisted[0xCD4bF42baa0687d7B1260480a7549C29455F29A9] = true;	
isWhitelisted[0x937b4FB18ac77d72cC8b3E822207714A4015d02f] = true;	
isWhitelisted[0x29D7f67Ad1a22Fcc91C02e0049032119A6c57743] = true;	
isWhitelisted[0x33b122f01C4C79faa6ab1b072a73289364FB493a] = true;	
isWhitelisted[0x597A3eB6c8acC00FD63Bc3466e6dd6E3F084d9bE] = true;	
isWhitelisted[0x75fa24AcF88D0284d60987EbBB2F77BA02e9a622] = true;	
isWhitelisted[0xced5F74513b76A26AF215A1bfaD2890B58391300] = true;	
isWhitelisted[0xe9d73032aB07C7f49B4258fBaA2EBC37ec1BcaaB] = true;	
isWhitelisted[0xb605e3a35BD67c6Ca27f1bAA8De3007CB6B4192F] = true;	
isWhitelisted[0xC406CE88ADAeBDB477789D7FaA562D6205063f27] = true;	
isWhitelisted[0xc3fe6330e3F87CddDFDB6C6E55F9c8590f3061A9] = true;	
isWhitelisted[0x05765aE889864E1197359C274eFaB48B723F0E40] = true;	
isWhitelisted[0x8ccCC03aB120Cf05bc2d20af7639Df9875e80911] = true;	
isWhitelisted[0x4A8fD93b6eaC83118e9E1C0ecdc4303806091916] = true;	
isWhitelisted[0x32BFAC6440F6a336e580aEFBf0ae5aE961eFc5C7] = true;	
isWhitelisted[0xc3bc408c22dC3E944bcCb15ed058283827BEFdA3] = true;	
isWhitelisted[0x3E03EFA72cF10444546C314ABEa664A8ED8B11F9] = true;	
isWhitelisted[0x751eBbDe885D07887b50906c3cE4fC7F2E98524E] = true;	
isWhitelisted[0xd97873bE563B20a18041AeBEAb87dBb1ce0BB7AD] = true;	
isWhitelisted[0xA3A9c042aAb749A2762eb960f87e82D29c953d29] = true;	
isWhitelisted[0x80cC64E09293EaF79bc29c70dA6dd9a669D62f0f] = true;	
isWhitelisted[0x77F00a4676844AF2C576aB240a423DCd81664c8E] = true;	
isWhitelisted[0x9AeBa416045C51069b7196a87D747f038D13Faca] = true;	
isWhitelisted[0x8249E744e1674B3fbC6067dD6F68B6E54EB46C79] = true;	
isWhitelisted[0x6895467f723e30E4CE89D3944a9360FbBd48De7C] = true;	
isWhitelisted[0xEE8b4C22C22Fa9773379692B8C6C3C0E0C02a335] = true;	
isWhitelisted[0x57eE67529E535F55afe0a2cd0C668Aa28eE2B870] = true;	
isWhitelisted[0x642adf666fe0ab32324999257b4b24A92F1A9a6d] = true;	
isWhitelisted[0xAdCf36552eD6B9b31DcDF161FD450B81adCF9F54] = true;	
isWhitelisted[0x3492606E68208B40C96f2F5771EcCF6e49239241] = true;	
isWhitelisted[0xF55Cd0Fd4C67E8547c5bc6F161a1868737BAF66B] = true;	
isWhitelisted[0x38412fdEF61E75764a360912dc8B117958E10918] = true;	
isWhitelisted[0x65bd4Ae93950CB21A0973c53Dd92a1BD6EA9350D] = true;	
isWhitelisted[0xbDab1Ee7BCCd3483E79bf27182b15E7211B1D157] = true;	
isWhitelisted[0xB10Dbe3602dbc411D6639c6a21D513d604A87E5c] = true;	
isWhitelisted[0x2D56AeAC04Bf2Ed584A953d7a34c04acf7748f52] = true;	
isWhitelisted[0xDF702A8cb7781afA9a7248C9E7FD7a07f9750e77] = true;	
isWhitelisted[0x460A8beb9a585D81e9d7526EF3f1C10443ded892] = true;	
isWhitelisted[0x040669C291c33b5eb0Da034c708175a63121E5Aa] = true;	
isWhitelisted[0xb8a1Cc5040148FE4a9E72F36f3e05B5566F6cbFe] = true;	
isWhitelisted[0x8A8565128547CF8e8F0D78AAF14c7e2A6866ed10] = true;	
isWhitelisted[0x1578304E0CD5B946BdA817037cC3dd446766Fae4] = true;	
isWhitelisted[0x75c482cD751363C8e4EE40FA3430aDBEF12fD4cB] = true;	
isWhitelisted[0x402FFA947E1bD9Dfc83e6b853Be63D69a7f1FB4c] = true;	
isWhitelisted[0x8fdE0910177c742E5A50604aE18b3fb53C6948c9] = true;	
isWhitelisted[0xC2978441F46a76c60e0cd59E986498b75a40572D] = true;	
// isWhitelisted[0xc4C6C27B2259794a1Dd35D438E703281C0e4A004] = true;	
// isWhitelisted[0x0206ca683e4be8096e656bd77b4baa22fba10098] = true;	
// isWhitelisted[0x1aa4e5d423186a6099b6d5a02857400b39871c35] = true;	
// isWhitelisted[0x1ab1c070c7f1958dbfc5537340cd8056580c43fc] = true;	
// isWhitelisted[0x32e2a213d7c5407411a081fb14e31edb754cfe2f] = true;	
// isWhitelisted[0x382c6f4dd388a71458aaefa837b385ac6c33ddf0] = true;	
// isWhitelisted[0x3bf2fe6bfb2c713fd82ca4b93f1fbb507a389671] = true;	
// isWhitelisted[0x40efc3d9a5fcf82e71c63391fe1578f7172c977e] = true;	
// isWhitelisted[0x42409fca8bf3a84aa3123e10953be83c7eceb5a6] = true;	
// isWhitelisted[0x51c93d6c6a2a4e48b149ed8d391259985ab2f139] = true;	
// isWhitelisted[0x52c394477d6bdac9353e77aab9ef5d500b213627] = true;	
// isWhitelisted[0x52f76f9c2b777cf6b15fbaeb0d6f24ee5ac2f91b] = true;	
// isWhitelisted[0x5fd6ca5c0c182ea12280801d9e360cce9fa896a3] = true;	
// isWhitelisted[0x602160f62d420e9154fc5167243440891d6efb4b] = true;	
// isWhitelisted[0x64c828bda206fb33a4be2bf68acd975c98edc6ad] = true;	
// isWhitelisted[0x6cd7d609b155cd5d36ea5b9a4ceabd0cdde50844] = true;	
// isWhitelisted[0x8DcEA94561F262ef21B393Ed13dEb023Ad0d7e3a] = true;	
// isWhitelisted[0x8f02512e87b7fcb421676cfd9fbb8bd54214d734] = true;	
// isWhitelisted[0x90325dc16afa2c06cca4d926017c6c5914477604] = true;	
// isWhitelisted[0x90d97772f4469df443273d2946aaebd5158f75af] = true;	
// isWhitelisted[0x94e39d7ee253116574fa4c664581d0adbe6e25c7] = true;	
// isWhitelisted[0x98ec10ad6d59ad1bad41f976358b7b5e82e400a1] = true;	
// isWhitelisted[0xa471ffde4e914131db746b60c8c209b817d3acc5] = true;	
// isWhitelisted[0xad990b2d8f63cef4de48d9b685c3a712b621be3e] = true;	
// isWhitelisted[0xb18e3c41faf4139b89b4ebf1f5ef645a3ad0ec7f] = true;	
// isWhitelisted[0xb51667ddaffdbe32e676704a0ca280ea19eb342b] = true;	
// isWhitelisted[0xbb0287fe22870eee2191ebe61ba742f5a6b93a46] = true;	
// isWhitelisted[0xbcc84dd5456fab41d2abe9d54c7a1abc8e74cd7e] = true;	
// isWhitelisted[0xbe8968EE25FBD5EbbAc867f07436770E2efF51D7] = true;	
// isWhitelisted[0xc167513801a009972f655ce8f57c50b0b4e70489] = true;	
// isWhitelisted[0xc3925ccb3547f45c3a8b7eba14a8aada957e6a80] = true;	
// isWhitelisted[0xcea9fc54d686bfc26541e6088ede8d04063459ce] = true;	
// isWhitelisted[0xcedfdf7444b9508e2be6671ec0d015037d6a7f62] = true;	
// isWhitelisted[0xcfff685979320598034d27c673937a3ec33beec3] = true;	
isWhitelisted[0xe5Db91eDe7387428825c04A588eA007CdB15bEa7] = true;	
// isWhitelisted[0xf2bd3daea43ed0e66bbdf5ac8b0bc853903b3187] = true;	
// isWhitelisted[0xf34429badf0e55b8362f3a6fe697da9e72539d1f] = true;	
isWhitelisted[0x4474aFF745BdeaD9b72698f40922E57072410753] = true;	
isWhitelisted[0xCBF07f3f3FdaD94b6179f5c446493C9D66968E95] = true;			
isWhitelisted[0x135FB3c7e03F51d29C895a3793c7bD1C01Dd6837] = true;			
isWhitelisted[0xbD3217feb2Db1cb4eB4CA2B852e03Fd34C673085] = true;
isWhitelisted[0x477F4D267B1174Df556A78A29C58A70d64c62140] = true;
isWhitelisted[0x0A9B9ee7c73A49C2b281A5eAb318e993A3A80A87] = true;
isWhitelisted[0xbE58d7cEA23C0F29f9be1095Af19E9FcF8dFD766] = true;
//isWhitelisted[0X57025c48548D5ABEd5Ab7b10A745F6274516b59b] = true;
isWhitelisted[0xe694767fe6aA32B19800E7E7A16064b9CD0Bb6C6] = true;
isWhitelisted[0x62a78c23937f88dBD4855Ba89c95Bd00F65e151e] = true;
isWhitelisted[0x41956a33cD29996368F49329399A6DBDB07AbCA3] = true;			
isWhitelisted[0xE0eae7e94eD4d8741Bc0b255c3D4BBF964d63874] = true;			
isWhitelisted[0x21b2F41E097B25813970225ACAb8Bc0e79F56eE1] = true;			
isWhitelisted[0x5de073EfED60A6a12f08f303B2DA4CaA9743442b] = true;			
isWhitelisted[0x3eb92eC890d05587C007Af793D1c61b839D1a7F6] = true;			
isWhitelisted[0xaE6D28aA68096CFD12a71beCbBEb9B0e56c873E6] = true;
isWhitelisted[0x9d3F56186CE4bA86214AE9127e07491f2449D698] = true;
isWhitelisted[0x7B9ceE7a68880f1261f4691A8a0BfB88f9DFA1BE] = true;
isWhitelisted[0xeb55370405F4dE3071c5EE47cBe37Ec66F3FE5b5] = true;
isWhitelisted[0x02E1a1b47231387260413d4AA630A2E40317702f] = true;
isWhitelisted[0xEe1DDD1C6Eb79Da9F78bc052F96eF9fD954bC0A6] = true;
isWhitelisted[0x5191410D10E5d9c493D6247A752DC38D0bDC6024] = true;
isWhitelisted[0xf4769f50C9436178737874A9380531503a71D532] = true;
isWhitelisted[0x18297C502C0a0a7c50D096be03Ec1FC6bcc5D98e] = true;
isWhitelisted[0x860F22d6b02F3eA0cAC639513b0b96AaF9edd2CA] = true;
isWhitelisted[0xe09283B2bE9431B6c9d866Ce1e1317F435d073e9] = true;
isWhitelisted[0x75F4fA23c6A2727Ba507362e1F52946c810073c0] = true;
isWhitelisted[0x46E0D6360C4115fb765C212105539DE5e2F1415d] = true;
isWhitelisted[0xBE63785D994eFa22B4c08d8F54b0E1E4bB5386d2] = true;
isWhitelisted[0x175a1b494F64ead9d63a9deF3b1DEA0e0b907EC3] = true;
isWhitelisted[0x3Fb47F7db5ab1a3Af5aC3417a77CB7DBe70ee6C5] = true;
isWhitelisted[0xa4435869AdA25A3198b5bf9F99f31825464E80Ab] = true;
isWhitelisted[0x497c2121825910D239b863efD57F981B252BD5F5] = true;
isWhitelisted[0x393dc35a5842798425aBc1a55DFF8353236f71bb] = true;
isWhitelisted[0xFEc9E73d40751d7563d4056C461BFD4526Ce813c] = true;
isWhitelisted[0x635C8284c700f6b67ff428C832cbe65b76f8d623] = true;
isWhitelisted[0x1f629351b4cBfBbc05e6183FB26554Deae0973C5] = true;
isWhitelisted[0xfe351a6F3239fc63b941CD9d27917B373fcBDD98] = true;
isWhitelisted[0x610F97454045182Eaddd842A62Cb01936aa3945D] = true;
isWhitelisted[0x437c1212A1eb8F6eD3Be7Af1f133E88Ea870Ce1a] = true;
isWhitelisted[0xA5287D4FD7A2cC3735F4550a86Db5C235C674730] = true;
isWhitelisted[0x4A9A80B052F3F8Ed3DDd105C840a260fa54DcA36] = true;
isWhitelisted[0x81c4E429BA7b191fb9b394640E3688eda566D790] = true;
isWhitelisted[0xeAc73674D57D673FF5D67453aa8D863a264B3b2c] = true;
isWhitelisted[0x11a566A145E7D8CA52bE20a80813dB48B7da206E] = true;
isWhitelisted[0x6EE1E9FC50d672bA16a9c457CA6013C4202E614e] = true;
isWhitelisted[0x7e1041636cF7c027Fa1E5c3afF597f81D8705A93] = true;
isWhitelisted[0x98F83281aa0759c0b5446dacD86f2d25a4323DD5] = true;
isWhitelisted[0x35AfB11b210CFABf2c1114F6731626018A3e54aB] = true;
isWhitelisted[0xc20cB8B2d300CDB049280F7ACa9DDD8046E1113D] = true;
isWhitelisted[0x04bE6360aAaE20ea1911944205D3FC2f2512a6B6] = true;
isWhitelisted[0x45784354E739BB0F6bD370F9fC32F77dfEC7138b] = true;
isWhitelisted[0x861607bB77bD51DBA9D85455FC00d970e3AA2eBe] = true;
isWhitelisted[0x3Ed18D98bF2D60Df3C7b46D8B012405AEED2c2c1] = true;
isWhitelisted[0x5E818831aCA49b631C783731f3006aA6950d19ab] = true;
isWhitelisted[0xf4E2a7eaE4Bc3e3746811f260b3C2c91285a1B2e] = true;
isWhitelisted[0xa9Af5143c8331C567eFe8fF3E64b5DbDaE2a959D] = true;
isWhitelisted[0x65940f5dB023587a663D4a20a4c7cd3FE209C1f5] = true;
isWhitelisted[0xcAe5c090Dd0f7ef8927ebDd8d433C33BB5D5E8f6] = true;
isWhitelisted[0xBA189a4F264f5A434B5DCD49Df5aB150DD0e54Ae] = true;
isWhitelisted[0x3a684E5382477Ecc874d66B73E85653b1fb8C355] = true;
isWhitelisted[0x7Aed6acd803DFB3A1B3FD86f3d502512151A1144] = true;
isWhitelisted[0xefE3cE598D49056828e8f4694e5AE2C988D57f04] = true;
isWhitelisted[0x8f1e9170c29FFF012Dde017F6CFC3333Fd4696a6] = true;
isWhitelisted[0xF6e4Cc5F0eFafD89B7357f162dF2Fbf865CE3ace] = true;
isWhitelisted[0x4c946b702ebD9b1071f10ccDa03d58d3696AcDF0] = true;
isWhitelisted[0x5CbF217cC7EE0B4e16A703b60095f15b44dAB09c] = true;
isWhitelisted[0xAd3f8be5F5712825AaE2551A4628d7876Cfa435D] = true;
isWhitelisted[0x3B209185d34775862BA932c09BC9732A69739E2E] = true;
isWhitelisted[0x4F8bdD55E45f7E16E16Ba598291B6BEdcf9D56E4] = true;
isWhitelisted[0x6ae84a40B93a9F2548D407E6887F84Eb88A640DE] = true;
isWhitelisted[0x3089c3370DaEEFD20FEF5b31cE023c010359C5AF] = true;
isWhitelisted[0x57B85900394dDAFF0912EB9C711fb342b360e66c] = true;
isWhitelisted[0x81E768f036aC8F3eACF4fbe01927D9EA4D2d7af9] = true;
isWhitelisted[0x2728AdCE631A6909Bc43d445E2e9cec5184D405F] = true;
isWhitelisted[0x34a0e8Cc759BBb6380b9774baF7C4dfc982b0D38] = true;
isWhitelisted[0x6ED75E43E7eeC0b3f95E2daC87920dE66f1E494f] = true;
isWhitelisted[0x7334400F80EaaC595DFb859d3e027Dd561a240Ee] = true;
isWhitelisted[0x1c98d47e1065Ca1dbDeB94dd0B16E7E7d0F819b6] = true;
isWhitelisted[0xf99bff640f8C09384629ECda3244DCA24B10B979] = true;			
isWhitelisted[0x59f4Eb2766C9031525d1C746E4Dd67798Ed76d3a] = true;			
isWhitelisted[0x1996578c0ADFa4eA9444060907C953EaF1D8C96b] = true;			
isWhitelisted[0x2687B8f2762D557fBC8CFBb5a73aeE71fDd5C604] = true;			
isWhitelisted[0x6d3C1B048F45E008f3C205C292cdB21318865DD3] = true;			
isWhitelisted[0x08EDA6288d98fF58eA32bC06D45c9B25Db44188D] = true;			
isWhitelisted[0xeE0201E07db325a5D732AeB9b9Fba7b5B8E92c2A] = true;			
//isWhitelisted[0x6246f145a5d4221ed9a37c6c537940c86dbb390e] = true;			
isWhitelisted[0xC5746Fa1550B45a5D9E3477d153cc8c744e7A829] = true;			
isWhitelisted[0x183e65C5061333D8B0b8f9C251d8772cfEb4caCF] = true;			
isWhitelisted[0x0Cb68E2bE8E397eE5529Fa63DEf7926D6c185729] = true;			
isWhitelisted[0x3E5fce21497Ba4aCff43e7F3111b85C47cfaDdF4] = true;			
isWhitelisted[0xA355790983B6b1dB7B1d4cA2f865fBa9166dc320] = true;			
isWhitelisted[0xe3bca6755abdA45f3f1bA4815103235400eeAf63] = true;			
isWhitelisted[0xB47832cA65E661b2b54dE39F24775C1d82C216f9] = true;			
isWhitelisted[0x033d1a2357307Ae3f8a2D7aC15931f555d37D41d] = true;			
isWhitelisted[0x48Cf414179B53E5011DbaeE808877bA93c18C506] = true;			
isWhitelisted[0x7d86550aCA13995DC5fC5E0Df6c7B57F4d72e714] = true;			
isWhitelisted[0x6031B736D50F0D4845eB756169E74F7e3756e157] = true;			
isWhitelisted[0x9be4310F5b69cC00644f06bfd2D17bf635E84e15] = true;			
isWhitelisted[0x199E056a0CA59Dc40C19f625efaC86eEF7a55731] = true;			
isWhitelisted[0xA68c1bDF04149679CC141D527f09981316cb64fd] = true;			
isWhitelisted[0x2687B8f2762D557fBC8CFBb5a73aeE71fDd5C604] = true;			
isWhitelisted[0x09A3Ed4C3B477E53850edE0AAC96681BA314193B] = true;			
isWhitelisted[0xD52a71194297cCE8f9E6d116eE731966F0c6A978] = true;
isWhitelisted[0xa5F111b5617dcD1561609eB4457E687af3Ba1378] = true;			
isWhitelisted[0x4A19Db71516eDDbF7554cB622CD7eA053Edc9733] = true;
isWhitelisted[0x489C7047b30a241A3675816d109bC632b545C442] = true;
isWhitelisted[0x3BDF8C4F5Fd8E40CAcb8DFDa2B9cA5049DF1610B] = true;
isWhitelisted[0xDEff70a9BA589F6089C9a2fA82087a7489Eb65ed] = true;
isWhitelisted[0xCDee006CEA5662F555713adE5885c27CbDdee3e3] = true;
isWhitelisted[0xbCaC01A558014D68EFdf409aC0473336E7e040c0] = true;
isWhitelisted[0x790117d9Fd5812CafcF3C95Ad1bb368cC206E6A1] = true;
isWhitelisted[0xd478e5ba0613Fa9d7E7c9E0a8d4D2669fDd287F0] = true;
isWhitelisted[0x99B20597423cc0f6256DD7542D0Ca6A67e96d23b] = true;
isWhitelisted[0x8D71230CA870Af8E264F69797D09f070Ad39D364] = true;
isWhitelisted[0xD16459f84720115B6b85cce92a8D051313aA407E] = true;
isWhitelisted[0x0dB1357668b10e4C68115092Dae092B5BcE2D19a] = true;
isWhitelisted[0x61063C8b5482b40E0dA2a2D6CB1D8F1C8B2977dE] = true;
isWhitelisted[0xA6eCB85188272613C3BbbEb21A2994502803AF6D] = true;			
isWhitelisted[0x10Eda8Ab8ccCC9f79009b5aD43C4AC7b8f0b1600] = true;			
isWhitelisted[0x990A8da34812705A96FB0c70B1427B19c339FB3b] = true;			
isWhitelisted[0xC7AfE6417D52EcbA8e6324C1d0020ca58ea6d70b] = true;			
isWhitelisted[0x725428d21aF962C471Cb1d70Ab27866fCfCCCCc4] = true;			
isWhitelisted[0x7BBBbe79950387B0F0Bfff28C03B9c88CDBa8b04] = true;			
isWhitelisted[0xb24fc16B9Bdd08c33309ae5B2cE5Ef748437A8Df] = true;			
isWhitelisted[0x3Ae6280f3524001Dc74C20E152eF155E56a6BEeb] = true;			
isWhitelisted[0x3692E5a3861a41c70cf11693682adC3875b518Df] = true;
isWhitelisted[0x0c7d6a37D4015a0F837348F8aA95fC11C70037bD] = true;			
isWhitelisted[0x11a566A145E7D8CA52bE20a80813dB48B7da206E] = true;
isWhitelisted[0xf2d6155CDCf72B5cda8631764a464eDCad64b8c7] = true;
isWhitelisted[0x504fc15807a2f55f642B34c6Aa43B1970d6b7548] = true;
isWhitelisted[0x7F8F5Da84114F09b0777035d7fD5642Fad07c1f3] = true;
//isWhitelisted[0xf0109ca8714c5865e17c3cf479ae4bded0cd459b] = true;
isWhitelisted[0x506B7c9692117DdEbB14D19d3C7cE1e998DBA11a] = true;
isWhitelisted[0xE6b5931c9Af4f50cd532f93359c7F55dc2504675] = true;
isWhitelisted[0x1DEaF07c8D99fe579C16Afb8f0A3AcD1dF703B70] = true;
isWhitelisted[0x209a38a8f1612316B54C62A81e0F245a1F9b157e] = true;
isWhitelisted[0xB36F1cD4AD753Bc4034eF24F45B97606041f7066] = true;
isWhitelisted[0x29E73e95dd5d1C9CC62caC0E1A22896343C77dCD] = true;
isWhitelisted[0xdB8Bd7aCf67Aa9423288D14613B4d2683d24151c] = true;
isWhitelisted[0x4052B6DaF98E8c135ED94852F87905fEBbFF13a7] = true;
isWhitelisted[0x7CEC1c2F645a535D631b36AfDFBc7F7b95bA680C] = true;			
isWhitelisted[0x5E7C56FDD722c3Da150D8950D3EdAb1eB2f8D1cA] = true;			
isWhitelisted[0xbC409FAf353AB0549Ea0F842dEA111A7C6c1043B] = true;						
isWhitelisted[0x30b36A74003ED363114b87e7a678DfF1e029F88F] = true;						
isWhitelisted[0xdC9A46214A870Dc71C89Cb4f05A52aD2D2E4a8F8] = true;						
isWhitelisted[0x8a87149072817293ACc15478D0fd8a64248974b3] = true;						
isWhitelisted[0x9034937050B8372778Be13df8efd9476c027810C] = true;						
isWhitelisted[0xC94ad4C8f7F7211682E60086195d020eebc5d7da] = true;						
isWhitelisted[0xA602a1bc54344da90a61654cB64e34913907b0a2] = true;						
isWhitelisted[0x7a998777a733D7F7c32e74453B10e4BfA6bCE22B] = true;
  }


  //internal function for base uri
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
      modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    function Whitelist(address _whitelistAddress) external onlyOwner{
        isWhitelisted[_whitelistAddress] = true;
    }

      function getPrice(address _address) public view returns(uint256, string memory){
        if(isWhitelisted[_address]==true){
            return (0, "You are Whitelisted for free mint");
        }
        else{
            return (cost, "You are not whitelisted");
        }
    }


  //function allows you to mint an NFT token
  function mint(uint256 _mintAmount) public payable {
    require(_mintAmount > 0);
    uint256 ts = totalSupply();
        require(ts + _mintAmount <= maxSupply, "Purchase would exceed Collection Size");
        if(isWhitelisted[msg.sender] == true && !freeMinted[msg.sender]){
            for (uint256 i = 1; i <= 1; i++) { 
            _safeMint(msg.sender, ts + i);
        }
        unchecked{
          maxUMint[msg.sender] +=1;
        }
        freeMinted[msg.sender] = true;
        }
        else{
        require(!paused, "Sale has'nt been started yet!");
        require(cost * _mintAmount <= msg.value, "Ether value sent is not correct");
        if(freeMinted[msg.sender]){
          require(maxUMint[msg.sender] + _mintAmount <= 9, "MAX Nfts: 10!"); 
        }
        else{
        require(maxUMint[msg.sender] + _mintAmount <= maxMint, "MAX Nfts: 10!"); 
        }
        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(msg.sender, ts + i);
        } unchecked{
         maxUMint[msg.sender] += _mintAmount;
        }
        }
        (bool success, ) = owner.call{value: (address(this).balance)} ("");
        require(success);
        payable(owner).transfer(address(this).balance);
  }

//input a NFT token ID and get the IPFS URI
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }
  
//set the cost of an NFT
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

//set the base URI on IPFS
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }


  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

//start the sale the contract and do not allow any more minting
  function startSale() public onlyOwner {
    paused = true;
  }

 function supportsInterface(bytes4 interfaceId)
    public view virtual override(ERC721Enumerable, ERC2981)
    returns (bool) {
      return super.supportsInterface(interfaceId);
  }

}