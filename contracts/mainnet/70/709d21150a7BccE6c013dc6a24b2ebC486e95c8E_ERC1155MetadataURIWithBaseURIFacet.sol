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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
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
pragma solidity ^0.8.8;

/// @title ERC-173 Contract Ownership Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-173
/// @dev Note: the ERC-165 identifier for this interface is 0x7f5828d0
interface IERC173 {
    /// @notice Emitted when the contract ownership changes.
    /// @param previousOwner the previous contract owner.
    /// @param newOwner the new contract owner.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Sets the address of the new contract owner.
    /// @dev Reverts if the sender is not the contract owner.
    /// @dev Emits an {OwnershipTransferred} event if `newOwner` is different from the current contract owner.
    /// @param newOwner The address of the new contract owner. Using the zero address means renouncing ownership.
    function transferOwnership(address newOwner) external;

    /// @notice Gets the address of the contract owner.
    /// @return contractOwner The address of the contract owner.
    function owner() external view returns (address contractOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC173} from "./../interfaces/IERC173.sol";
import {ProxyInitialization} from "./../../proxy/libraries/ProxyInitialization.sol";
import {InterfaceDetectionStorage} from "./../../introspection/libraries/InterfaceDetectionStorage.sol";

library ContractOwnershipStorage {
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;

    struct Layout {
        address contractOwner;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.access.ContractOwnership.storage")) - 1);
    bytes32 internal constant PROXY_INIT_PHASE_SLOT = bytes32(uint256(keccak256("animoca.core.access.ContractOwnership.phase")) - 1);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Initializes the storage with an initial contract owner (immutable version).
    /// @notice Marks the following ERC165 interface(s) as supported: ERC173.
    /// @dev Note: This function should be called ONLY in the constructor of an immutable (non-proxied) contract.
    /// @dev Emits an {OwnershipTransferred} if `initialOwner` is not the zero address.
    /// @param initialOwner The initial contract owner.
    function constructorInit(Layout storage s, address initialOwner) internal {
        if (initialOwner != address(0)) {
            s.contractOwner = initialOwner;
            emit OwnershipTransferred(address(0), initialOwner);
        }
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC173).interfaceId, true);
    }

    /// @notice Initializes the storage with an initial contract owner (proxied version).
    /// @notice Sets the proxy initialization phase to `1`.
    /// @notice Marks the following ERC165 interface(s) as supported: ERC173.
    /// @dev Note: This function should be called ONLY in the init function of a proxied contract.
    /// @dev Reverts if the proxy initialization phase is set to `1` or above.
    /// @dev Emits an {OwnershipTransferred} if `initialOwner` is not the zero address.
    /// @param initialOwner The initial contract owner.
    function proxyInit(Layout storage s, address initialOwner) internal {
        ProxyInitialization.setPhase(PROXY_INIT_PHASE_SLOT, 1);
        s.constructorInit(initialOwner);
    }

    /// @notice Sets the address of the new contract owner.
    /// @dev Reverts if `sender` is not the contract owner.
    /// @dev Emits an {OwnershipTransferred} event if `newOwner` is different from the current contract owner.
    /// @param newOwner The address of the new contract owner. Using the zero address means renouncing ownership.
    function transferOwnership(Layout storage s, address sender, address newOwner) internal {
        address previousOwner = s.contractOwner;
        require(sender == previousOwner, "Ownership: not the owner");
        if (previousOwner != newOwner) {
            s.contractOwner = newOwner;
            emit OwnershipTransferred(previousOwner, newOwner);
        }
    }

    /// @notice Gets the address of the contract owner.
    /// @return contractOwner The address of the contract owner.
    function owner(Layout storage s) internal view returns (address contractOwner) {
        return s.contractOwner;
    }

    /// @notice Ensures that an account is the contract owner.
    /// @dev Reverts if `account` is not the contract owner.
    /// @param account The account.
    function enforceIsContractOwner(Layout storage s, address account) internal view {
        require(account == s.contractOwner, "Ownership: not the owner");
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC165 Interface Detection Standard.
/// @dev See https://eips.ethereum.org/EIPS/eip-165.
/// @dev Note: The ERC-165 identifier for this interface is 0x01ffc9a7.
interface IERC165 {
    /// @notice Returns whether this contract implements a given interface.
    /// @dev Note: This function call must use less than 30 000 gas.
    /// @param interfaceId the interface identifier to test.
    /// @return supported True if the interface is supported, false if `interfaceId` is `0xffffffff` or if the interface is not supported.
    function supportsInterface(bytes4 interfaceId) external view returns (bool supported);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC165} from "./../interfaces/IERC165.sol";

library InterfaceDetectionStorage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.introspection.InterfaceDetection.storage")) - 1);

    bytes4 internal constant ILLEGAL_INTERFACE_ID = 0xffffffff;

    /// @notice Sets or unsets an ERC165 interface.
    /// @dev Reverts if `interfaceId` is `0xffffffff`.
    /// @param interfaceId the interface identifier.
    /// @param supported True to set the interface, false to unset it.
    function setSupportedInterface(Layout storage s, bytes4 interfaceId, bool supported) internal {
        require(interfaceId != ILLEGAL_INTERFACE_ID, "InterfaceDetection: wrong value");
        s.supportedInterfaces[interfaceId] = supported;
    }

    /// @notice Returns whether this contract implements a given interface.
    /// @dev Note: This function call must use less than 30 000 gas.
    /// @param interfaceId The interface identifier to test.
    /// @return supported True if the interface is supported, false if `interfaceId` is `0xffffffff` or if the interface is not supported.
    function supportsInterface(Layout storage s, bytes4 interfaceId) internal view returns (bool supported) {
        if (interfaceId == ILLEGAL_INTERFACE_ID) {
            return false;
        }
        if (interfaceId == type(IERC165).interfaceId) {
            return true;
        }
        return s.supportedInterfaces[interfaceId];
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IForwarderRegistry} from "./../interfaces/IForwarderRegistry.sol";
import {ERC2771Calldata} from "./../libraries/ERC2771Calldata.sol";

/// @title Meta-Transactions Forwarder Registry Context (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Derived from https://github.com/wighawag/universal-forwarder (MIT licence)
abstract contract ForwarderRegistryContextBase {
    IForwarderRegistry internal immutable _forwarderRegistry;

    constructor(IForwarderRegistry forwarderRegistry) {
        _forwarderRegistry = forwarderRegistry;
    }

    /// @notice Returns the message sender depending on the ForwarderRegistry-based meta-transaction context.
    function _msgSender() internal view virtual returns (address) {
        // Optimised path in case of an EOA-initiated direct tx to the contract or a call from a contract not complying with EIP-2771
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender == tx.origin || msg.data.length < 24) {
            return msg.sender;
        }

        address sender = ERC2771Calldata.msgSender();

        // Return the EIP-2771 calldata-appended sender address if the message was forwarded by the ForwarderRegistry or an approved forwarder
        if (msg.sender == address(_forwarderRegistry) || _forwarderRegistry.isApprovedForwarder(sender, msg.sender)) {
            return sender;
        }

        return msg.sender;
    }

    /// @notice Returns the message data depending on the ForwarderRegistry-based meta-transaction context.
    function _msgData() internal view virtual returns (bytes calldata) {
        // Optimised path in case of an EOA-initiated direct tx to the contract or a call from a contract not complying with EIP-2771
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender == tx.origin || msg.data.length < 24) {
            return msg.data;
        }

        // Return the EIP-2771 calldata (minus the appended sender) if the message was forwarded by the ForwarderRegistry or an approved forwarder
        if (msg.sender == address(_forwarderRegistry) || _forwarderRegistry.isApprovedForwarder(ERC2771Calldata.msgSender(), msg.sender)) {
            return ERC2771Calldata.msgData();
        }

        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title Universal Meta-Transactions Forwarder Registry.
/// @dev Derived from https://github.com/wighawag/universal-forwarder (MIT licence)
interface IForwarderRegistry {
    /// @notice Checks whether an account is as an approved meta-transaction forwarder for a sender account.
    /// @param sender The sender account.
    /// @param forwarder The forwarder account.
    /// @return isApproved True if `forwarder` is an approved meta-transaction forwarder for `sender`, false otherwise.
    function isApprovedForwarder(address sender, address forwarder) external view returns (bool isApproved);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @dev Derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT licence)
/// @dev See https://eips.ethereum.org/EIPS/eip-2771
library ERC2771Calldata {
    /// @notice Returns the sender address appended at the end of the calldata, as specified in EIP-2771.
    function msgSender() internal pure returns (address sender) {
        assembly {
            sender := shr(96, calldataload(sub(calldatasize(), 20)))
        }
    }

    /// @notice Returns the calldata while omitting the appended sender address, as specified in EIP-2771.
    function msgData() internal pure returns (bytes calldata data) {
        unchecked {
            return msg.data[:msg.data.length - 20];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {ProxyInitialization} from "./ProxyInitialization.sol";

library ProxyAdminStorage {
    using ProxyAdminStorage for ProxyAdminStorage.Layout;

    struct Layout {
        address admin;
    }

    // bytes32 public constant PROXYADMIN_STORAGE_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
    bytes32 internal constant PROXY_INIT_PHASE_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin.phase")) - 1);

    event AdminChanged(address previousAdmin, address newAdmin);

    /// @notice Initializes the storage with an initial admin (immutable version).
    /// @dev Note: This function should be called ONLY in the constructor of an immutable (non-proxied) contract.
    /// @dev Reverts if `initialAdmin` is the zero address.
    /// @dev Emits an {AdminChanged} event.
    /// @param initialAdmin The initial payout wallet.
    function constructorInit(Layout storage s, address initialAdmin) internal {
        require(initialAdmin != address(0), "ProxyAdmin: no initial admin");
        s.admin = initialAdmin;
        emit AdminChanged(address(0), initialAdmin);
    }

    /// @notice Initializes the storage with an initial admin (proxied version).
    /// @notice Sets the proxy initialization phase to `1`.
    /// @dev Note: This function should be called ONLY in the init function of a proxied contract.
    /// @dev Reverts if the proxy initialization phase is set to `1` or above.
    /// @dev Reverts if `initialAdmin` is the zero address.
    /// @dev Emits an {AdminChanged} event.
    /// @param initialAdmin The initial payout wallet.
    function proxyInit(Layout storage s, address initialAdmin) internal {
        ProxyInitialization.setPhase(PROXY_INIT_PHASE_SLOT, 1);
        s.constructorInit(initialAdmin);
    }

    /// @notice Sets a new proxy admin.
    /// @dev Reverts if `sender` is not the proxy admin.
    /// @dev Emits an {AdminChanged} event if `newAdmin` is different from the current proxy admin.
    /// @param newAdmin The new proxy admin.
    function changeProxyAdmin(Layout storage s, address sender, address newAdmin) internal {
        address previousAdmin = s.admin;
        require(sender == previousAdmin, "ProxyAdmin: not the admin");
        if (previousAdmin != newAdmin) {
            s.admin = newAdmin;
            emit AdminChanged(previousAdmin, newAdmin);
        }
    }

    /// @notice Gets the proxy admin.
    /// @return admin The proxy admin
    function proxyAdmin(Layout storage s) internal view returns (address admin) {
        return s.admin;
    }

    /// @notice Ensures that an account is the proxy admin.
    /// @dev Reverts if `account` is not the proxy admin.
    /// @param account The account.
    function enforceIsProxyAdmin(Layout storage s, address account) internal view {
        require(account == s.admin, "ProxyAdmin: not the admin");
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

/// @notice Multiple calls protection for storage-modifying proxy initialization functions.
library ProxyInitialization {
    /// @notice Sets the initialization phase during a storage-modifying proxy initialization function.
    /// @dev Reverts if `phase` has been reached already.
    /// @param storageSlot the storage slot where `phase` is stored.
    /// @param phase the initialization phase.
    function setPhase(bytes32 storageSlot, uint256 phase) internal {
        StorageSlot.Uint256Slot storage currentVersion = StorageSlot.getUint256Slot(storageSlot);
        require(currentVersion.value < phase, "Storage: phase reached");
        currentVersion.value = phase;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC1155MetadataURI} from "./../interfaces/IERC1155MetadataURI.sol";
import {ERC1155Storage} from "./../libraries/ERC1155Storage.sol";
import {TokenMetadataWithBaseURIStorage} from "./../../metadata/libraries/TokenMetadataWithBaseURIStorage.sol";
import {ContractOwnershipStorage} from "./../../../access/libraries/ContractOwnershipStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC1155 Multi Token Standard (proxiable version), optional extension: Metadata URI (proxiable version).
/// @notice ERC1155MetadataURI implementation where tokenURIs are the concatenation of a base metadata URI and the token identifier (decimal).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC1155 (Multi Token Standard).
/// @dev Note: This contract requires ERC173 (Contract Ownership standard).
abstract contract ERC1155MetadataURIWithBaseURIBase is Context, IERC1155MetadataURI {
    using ERC1155Storage for ERC1155Storage.Layout;
    using TokenMetadataWithBaseURIStorage for TokenMetadataWithBaseURIStorage.Layout;
    using ContractOwnershipStorage for ContractOwnershipStorage.Layout;

    /// @notice Emitted when the base token metadata URI is updated.
    /// @param baseMetadataURI The new base metadata URI.
    event BaseMetadataURISet(string baseMetadataURI);

    /// @notice Sets the base metadata URI.
    /// @dev Reverts if the sender is not the contract owner.
    /// @dev Emits a {BaseMetadataURISet} event.
    /// @param baseURI The base metadata URI.
    function setBaseMetadataURI(string calldata baseURI) external {
        ContractOwnershipStorage.layout().enforceIsContractOwner(_msgSender());
        TokenMetadataWithBaseURIStorage.layout().setBaseMetadataURI(baseURI);
    }

    /// @notice Gets the base metadata URI.
    /// @return baseURI The base metadata URI.
    function baseMetadataURI() external view returns (string memory baseURI) {
        return TokenMetadataWithBaseURIStorage.layout().baseMetadataURI();
    }

    /// @inheritdoc IERC1155MetadataURI
    function uri(uint256 id) external view override returns (string memory metadataURI) {
        return TokenMetadataWithBaseURIStorage.layout().tokenMetadataURI(id);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IForwarderRegistry} from "./../../../metatx/interfaces/IForwarderRegistry.sol";
import {ERC1155Storage} from "./../libraries/ERC1155Storage.sol";
import {TokenMetadataWithBaseURIStorage} from "./../../metadata/libraries/TokenMetadataWithBaseURIStorage.sol";
import {ProxyAdminStorage} from "./../../../proxy/libraries/ProxyAdminStorage.sol";
import {ERC1155MetadataURIWithBaseURIBase} from "./../base/ERC1155MetadataURIWithBaseURIBase.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ForwarderRegistryContextBase} from "./../../../metatx/base/ForwarderRegistryContextBase.sol";

/// @title ERC1155 Multi Token Standard, optional extension: Metadata URI (facet version).
/// @notice ERC1155MetadataURI implementation where tokenURIs are the concatenation of a base metadata URI and the token identifier (decimal).
/// @dev This contract is to be used as a diamond facet (see ERC2535 Diamond Standard https://eips.ethereum.org/EIPS/eip-2535).
/// @dev Note: This facet depends on {ProxyAdminFacet}, and {InterfaceDetectionFacet}.
contract ERC1155MetadataURIWithBaseURIFacet is ERC1155MetadataURIWithBaseURIBase, ForwarderRegistryContextBase {
    using TokenMetadataWithBaseURIStorage for TokenMetadataWithBaseURIStorage.Layout;
    using ProxyAdminStorage for ProxyAdminStorage.Layout;

    constructor(IForwarderRegistry forwarderRegistry) ForwarderRegistryContextBase(forwarderRegistry) {}

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155MetadataURI.
    /// @dev Reverts if the sender is not the proxy admin.
    function initERC1155MetadataURIStorage() external {
        ProxyAdminStorage.layout().enforceIsProxyAdmin(_msgSender());
        ERC1155Storage.initERC1155MetadataURI();
    }

    /// @inheritdoc ForwarderRegistryContextBase
    function _msgSender() internal view virtual override(Context, ForwarderRegistryContextBase) returns (address) {
        return ForwarderRegistryContextBase._msgSender();
    }

    /// @inheritdoc ForwarderRegistryContextBase
    function _msgData() internal view virtual override(Context, ForwarderRegistryContextBase) returns (bytes calldata) {
        return ForwarderRegistryContextBase._msgData();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC1155 Multi Token Standard, basic interface.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0xd9b67a26.
interface IERC1155 {
    /// @notice Emitted when some token is transferred.
    /// @param operator The initiator of the transfer.
    /// @param from The previous token owner.
    /// @param to The new token owner.
    /// @param id The transferred token identifier.
    /// @param value The amount of token.
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /// @notice Emitted when a batch of tokens is transferred.
    /// @param operator The initiator of the transfer.
    /// @param from The previous tokens owner.
    /// @param to The new tokens owner.
    /// @param ids The transferred tokens identifiers.
    /// @param values The amounts of tokens.
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /// @notice Emitted when an approval for all tokens is set or unset.
    /// @param owner The tokens owner.
    /// @param operator The approved address.
    /// @param approved True when then approval is set, false when it is unset.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @notice Emitted optionally when a token metadata URI is set.
    /// @param value The token metadata URI.
    /// @param id The token identifier.
    event URI(string value, uint256 indexed id);

    /// @notice Safely transfers some token.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance of `id`.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits a {TransferSingle} event.
    /// @param from Current token owner.
    /// @param to Address of the new token owner.
    /// @param id Identifier of the token to transfer.
    /// @param value Amount of token to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;

    /// @notice Safely transfers a batch of tokens.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance for any of `ids`.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155BatchReceived} fails, reverts or is rejected.
    /// @dev Emits a {TransferBatch} event.
    /// @param from Current tokens owner.
    /// @param to Address of the new tokens owner.
    /// @param ids Identifiers of the tokens to transfer.
    /// @param values Amounts of tokens to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external;

    /// @notice Enables or disables an operator's approval.
    /// @dev Emits an {ApprovalForAll} event.
    /// @param operator Address of the operator.
    /// @param approved True to approve the operator, false to revoke its approval.
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Retrieves the approval status of an operator for a given owner.
    /// @param owner Address of the authorisation giver.
    /// @param operator Address of the operator.
    /// @return approved True if the operator is approved, false if not.
    function isApprovedForAll(address owner, address operator) external view returns (bool approved);

    /// @notice Retrieves the balance of `id` owned by account `owner`.
    /// @param owner The account to retrieve the balance of.
    /// @param id The identifier to retrieve the balance of.
    /// @return balance The balance of `id` owned by account `owner`.
    function balanceOf(address owner, uint256 id) external view returns (uint256 balance);

    /// @notice Retrieves the balances of `ids` owned by accounts `owners`.
    /// @dev Reverts if `owners` and `ids` have different lengths.
    /// @param owners The addresses of the token holders
    /// @param ids The identifiers to retrieve the balance of.
    /// @return balances The balances of `ids` owned by accounts `owners`.
    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view returns (uint256[] memory balances);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/// @title ERC1155 Multi Token Standard, optional extension: Burnable.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0x921ed8d1.
interface IERC1155Burnable {
    /// @notice Burns some token.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance of `id`.
    /// @dev Emits an {IERC1155-TransferSingle} event.
    /// @param from Address of the current token owner.
    /// @param id Identifier of the token to burn.
    /// @param value Amount of token to burn.
    function burnFrom(address from, uint256 id, uint256 value) external;

    /// @notice Burns multiple tokens.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance for any of `ids`.
    /// @dev Emits an {IERC1155-TransferBatch} event.
    /// @param from Address of the current tokens owner.
    /// @param ids Identifiers of the tokens to burn.
    /// @param values Amounts of tokens to burn.
    function batchBurnFrom(address from, uint256[] calldata ids, uint256[] calldata values) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC1155 Multi Token Standard, optional extension: Deliverable.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0xe8ab9ccc.
interface IERC1155Deliverable {
    /// @notice Safely mints tokens to multiple recipients.
    /// @dev Reverts if `recipients`, `ids` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if one of `recipients` balance overflows.
    /// @dev Reverts if one of `recipients` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits an {IERC1155-TransferSingle} event from the zero address for each transfer.
    /// @param recipients Addresses of the new tokens owners.
    /// @param ids Identifiers of the tokens to mint.
    /// @param values Amounts of tokens to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeDeliver(address[] calldata recipients, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC1155 Multi Token Standard, optional extension: Metadata URI.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0x0e89341c.
interface IERC1155MetadataURI {
    /// @notice Retrieves the URI for a given token.
    /// @dev URIs are defined in RFC 3986.
    /// @dev The URI MUST point to a JSON file that conforms to the "ERC1155 Metadata URI JSON Schema".
    /// @dev The uri function SHOULD be used to retrieve values if no event was emitted.
    /// @dev The uri function MUST return the same value as the latest event for an _id if it was emitted.
    /// @dev The uri function MUST NOT be used to check for the existence of a token as it is possible for
    ///  an implementation to return a valid string even if the token does not exist.
    /// @return metadataURI The URI associated to the token.
    function uri(uint256 id) external view returns (string memory metadataURI);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/// @title ERC1155 Multi Token Standard, optional extension: Mintable.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0x5190c92c.
interface IERC1155Mintable {
    /// @notice Safely mints some token.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `to`'s balance of `id` overflows.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits an {IERC1155-TransferSingle} event.
    /// @param to Address of the new token owner.
    /// @param id Identifier of the token to mint.
    /// @param value Amount of token to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeMint(address to, uint256 id, uint256 value, bytes calldata data) external;

    /// @notice Safely mints a batch of tokens.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `to`'s balance overflows for one of `ids`.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155batchReceived} fails, reverts or is rejected.
    /// @dev Emits an {IERC1155-TransferBatch} event.
    /// @param to Address of the new tokens owner.
    /// @param ids Identifiers of the tokens to mint.
    /// @param values Amounts of tokens to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeBatchMint(address to, uint256[] calldata ids, uint256[] calldata values, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC1155 Multi Token Standard, Tokens Receiver.
/// @notice Interface for any contract that wants to support transfers from ERC1155 asset contracts.
/// @dev See https://eips.ethereum.org/EIPS/eip-1155
/// @dev Note: The ERC-165 identifier for this interface is 0x4e2312e0.
interface IERC1155TokenReceiver {
    /// @notice Handles the receipt of a single ERC1155 token type.
    /// @notice ERC1155 contracts MUST call this function on a recipient contract, at the end of a `safeTransferFrom` after the balance update.
    /// @dev Return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` (`0xf23a6e61`) to accept the transfer.
    /// @dev Return of any other value than the prescribed keccak256 generated value will result in the transaction being reverted by the caller.
    /// @param operator The address which initiated the transfer (i.e. msg.sender)
    /// @param from The address which previously owned the token
    /// @param id The ID of the token being transferred
    /// @param value The amount of tokens being transferred
    /// @param data Additional data with no specified format
    /// @return magicValue `0xf23a6e61` to accept the transfer, or any other value to reject it.
    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns (bytes4 magicValue);

    /// @notice Handles the receipt of multiple ERC1155 token types.
    /// @notice ERC1155 contracts MUST call this function on a recipient contract, at the end of a `safeBatchTransferFrom` after the balance updates.
    /// @dev Return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` (`0xbc197c81`) to accept the transfer.
    /// @dev Return of any other value than the prescribed keccak256 generated value will result in the transaction being reverted by the caller.
    /// @param operator The address which initiated the batch transfer (i.e. msg.sender)
    /// @param from The address which previously owned the token
    /// @param ids An array containing ids of each token being transferred (order and length must match _values array)
    /// @param values An array containing amounts of each token being transferred (order and length must match _ids array)
    /// @param data Additional data with no specified format
    /// @return magicValue `0xbc197c81` to accept the transfer, or any other value to reject it.
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC1155} from "./../interfaces/IERC1155.sol";
import {IERC1155MetadataURI} from "./../interfaces/IERC1155MetadataURI.sol";
import {IERC1155Mintable} from "./../interfaces/IERC1155Mintable.sol";
import {IERC1155Deliverable} from "./../interfaces/IERC1155Deliverable.sol";
import {IERC1155Burnable} from "./../interfaces/IERC1155Burnable.sol";
import {IERC1155TokenReceiver} from "./../interfaces/IERC1155TokenReceiver.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ProxyInitialization} from "./../../../proxy/libraries/ProxyInitialization.sol";
import {InterfaceDetectionStorage} from "./../../../introspection/libraries/InterfaceDetectionStorage.sol";

library ERC1155Storage {
    using Address for address;
    using ERC1155Storage for ERC1155Storage.Layout;
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;

    struct Layout {
        mapping(uint256 => mapping(address => uint256)) balances;
        mapping(address => mapping(address => bool)) operators;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.token.ERC1155.ERC1155.storage")) - 1);

    bytes4 internal constant ERC1155_SINGLE_RECEIVED = IERC1155TokenReceiver.onERC1155Received.selector;
    bytes4 internal constant ERC1155_BATCH_RECEIVED = IERC1155TokenReceiver.onERC1155BatchReceived.selector;

    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event URI(string value, uint256 indexed id);

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155.
    function init() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155MetadataURI.
    function initERC1155MetadataURI() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155MetadataURI).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155Mintable.
    function initERC1155Mintable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155Mintable).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155Deliverable.
    function initERC1155Deliverable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155Deliverable).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC1155Burnable.
    function initERC1155Burnable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC1155Burnable).interfaceId, true);
    }

    /// @notice Safely transfers some token by a sender.
    /// @dev Note: This function implements {ERC1155-safeTransferFrom(address,address,uint256,uint256,bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `sender` is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance of `id`.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits a {TransferSingle} event.
    /// @param sender The message sender.
    /// @param from Current token owner.
    /// @param to Address of the new token owner.
    /// @param id Identifier of the token to transfer.
    /// @param value Amount of token to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeTransferFrom(Layout storage s, address sender, address from, address to, uint256 id, uint256 value, bytes calldata data) internal {
        require(to != address(0), "ERC1155: transfer to address(0)");
        require(_isOperatable(s, from, sender), "ERC1155: non-approved sender");

        _transferToken(s, from, to, id, value);

        emit TransferSingle(sender, from, to, id, value);

        if (to.isContract()) {
            _callOnERC1155Received(sender, from, to, id, value, data);
        }
    }

    /// @notice Safely transfers a batch of tokens by a sender.
    /// @dev Note: This function implements {ERC1155-safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if `sender` is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance for any of `ids`.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155BatchReceived} fails, reverts or is rejected.
    /// @dev Emits a {TransferBatch} event.
    /// @param sender The message sender.
    /// @param from Current tokens owner.
    /// @param to Address of the new tokens owner.
    /// @param ids Identifiers of the tokens to transfer.
    /// @param values Amounts of tokens to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeBatchTransferFrom(
        Layout storage s,
        address sender,
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) internal {
        require(to != address(0), "ERC1155: transfer to address(0)");
        uint256 length = ids.length;
        require(length == values.length, "ERC1155: inconsistent arrays");

        require(_isOperatable(s, from, sender), "ERC1155: non-approved sender");

        unchecked {
            for (uint256 i; i != length; ++i) {
                _transferToken(s, from, to, ids[i], values[i]);
            }
        }

        emit TransferBatch(sender, from, to, ids, values);

        if (to.isContract()) {
            _callOnERC1155BatchReceived(sender, from, to, ids, values, data);
        }
    }

    /// @notice Safely mints some token by a sender.
    /// @dev Note: This function implements {ERC1155Mintable-safeMint(address,uint256,uint256,bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `to`'s balance of `id` overflows.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits a {TransferSingle} event.
    /// @param sender The message sender.
    /// @param to Address of the new token owner.
    /// @param id Identifier of the token to mint.
    /// @param value Amount of token to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeMint(Layout storage s, address sender, address to, uint256 id, uint256 value, bytes memory data) internal {
        require(to != address(0), "ERC1155: mint to address(0)");

        _mintToken(s, to, id, value);

        emit TransferSingle(sender, address(0), to, id, value);

        if (to.isContract()) {
            _callOnERC1155Received(sender, address(0), to, id, value, data);
        }
    }

    /// @notice Safely mints a batch of tokens by a sender.
    /// @dev Note: This function implements {ERC1155Mintable-safeBatchMint(address,uint256[],uint256[],bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `to`'s balance overflows for one of `ids`.
    /// @dev Reverts if `to` is a contract and the call to {IERC1155TokenReceiver-onERC1155batchReceived} fails, reverts or is rejected.
    /// @dev Emits a {TransferBatch} event.
    /// @param sender The message sender.
    /// @param to Address of the new tokens owner.
    /// @param ids Identifiers of the tokens to mint.
    /// @param values Amounts of tokens to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeBatchMint(Layout storage s, address sender, address to, uint256[] memory ids, uint256[] memory values, bytes memory data) internal {
        require(to != address(0), "ERC1155: mint to address(0)");
        uint256 length = ids.length;
        require(length == values.length, "ERC1155: inconsistent arrays");

        unchecked {
            for (uint256 i; i != length; ++i) {
                _mintToken(s, to, ids[i], values[i]);
            }
        }

        emit TransferBatch(sender, address(0), to, ids, values);

        if (to.isContract()) {
            _callOnERC1155BatchReceived(sender, address(0), to, ids, values, data);
        }
    }

    /// @notice Safely mints tokens to multiple recipients by a sender.
    /// @dev Note: This function implements {ERC1155Deliverable-safeDeliver(address[],uint256[],uint256[],bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts if `recipients`, `ids` and `values` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if one of `recipients` balance overflows.
    /// @dev Reverts if one of `recipients` is a contract and the call to {IERC1155TokenReceiver-onERC1155Received} fails, reverts or is rejected.
    /// @dev Emits a {TransferSingle} event from the zero address for each transfer.
    /// @param sender The message sender.
    /// @param recipients Addresses of the new tokens owners.
    /// @param ids Identifiers of the tokens to mint.
    /// @param values Amounts of tokens to mint.
    /// @param data Optional data to send along to a receiver contract.
    function safeDeliver(
        Layout storage s,
        address sender,
        address[] memory recipients,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) internal {
        uint256 length = recipients.length;
        require(length == ids.length && length == values.length, "ERC1155: inconsistent arrays");
        unchecked {
            for (uint256 i; i != length; ++i) {
                s.safeMint(sender, recipients[i], ids[i], values[i], data);
            }
        }
    }

    /// @notice Burns some token by a sender.
    /// @dev Reverts `sender` is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance of `id`.
    /// @dev Emits a {TransferSingle} event.
    /// @param sender The message sender.
    /// @param from Address of the current token owner.
    /// @param id Identifier of the token to burn.
    /// @param value Amount of token to burn.
    function burnFrom(Layout storage s, address sender, address from, uint256 id, uint256 value) internal {
        require(_isOperatable(s, from, sender), "ERC1155: non-approved sender");
        _burnToken(s, from, id, value);
        emit TransferSingle(sender, from, address(0), id, value);
    }

    /// @notice Burns multiple tokens by a sender.
    /// @dev Reverts if `ids` and `values` have different lengths.
    /// @dev Reverts if `sender` is not `from` and has not been approved by `from`.
    /// @dev Reverts if `from` has an insufficient balance for any of `ids`.
    /// @dev Emits an {IERC1155-TransferBatch} event.
    /// @param sender The message sender.
    /// @param from Address of the current tokens owner.
    /// @param ids Identifiers of the tokens to burn.
    /// @param values Amounts of tokens to burn.
    function batchBurnFrom(Layout storage s, address sender, address from, uint256[] calldata ids, uint256[] calldata values) internal {
        uint256 length = ids.length;
        require(length == values.length, "ERC1155: inconsistent arrays");
        require(_isOperatable(s, from, sender), "ERC1155: non-approved sender");

        unchecked {
            for (uint256 i; i != length; ++i) {
                _burnToken(s, from, ids[i], values[i]);
            }
        }

        emit TransferBatch(sender, from, address(0), ids, values);
    }

    /// @notice Enables or disables an operator's approval by a sender.
    /// @dev Emits an {ApprovalForAll} event.
    /// @param sender The message sender.
    /// @param operator Address of the operator.
    /// @param approved True to approve the operator, false to revoke its approval.
    function setApprovalForAll(Layout storage s, address sender, address operator, bool approved) internal {
        require(operator != sender, "ERC1155: self-approval for all");
        s.operators[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /// @notice Retrieves the approval status of an operator for a given owner.
    /// @param owner Address of the authorisation giver.
    /// @param operator Address of the operator.
    /// @return approved True if the operator is approved, false if not.
    function isApprovedForAll(Layout storage s, address owner, address operator) internal view returns (bool approved) {
        return s.operators[owner][operator];
    }

    /// @notice Retrieves the balance of `id` owned by account `owner`.
    /// @param owner The account to retrieve the balance of.
    /// @param id The identifier to retrieve the balance of.
    /// @return balance The balance of `id` owned by account `owner`.
    function balanceOf(Layout storage s, address owner, uint256 id) internal view returns (uint256 balance) {
        require(owner != address(0), "ERC1155: balance of address(0)");
        return s.balances[id][owner];
    }

    /// @notice Retrieves the balances of `ids` owned by accounts `owners`.
    /// @dev Reverts if `owners` and `ids` have different lengths.
    /// @param owners The addresses of the token holders
    /// @param ids The identifiers to retrieve the balance of.
    /// @return balances The balances of `ids` owned by accounts `owners`.
    function balanceOfBatch(Layout storage s, address[] calldata owners, uint256[] calldata ids) internal view returns (uint256[] memory balances) {
        uint256 length = owners.length;
        require(length == ids.length, "ERC1155: inconsistent arrays");

        balances = new uint256[](owners.length);

        unchecked {
            for (uint256 i; i != length; ++i) {
                balances[i] = s.balanceOf(owners[i], ids[i]);
            }
        }
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }

    /// @notice Returns whether an account is authorised to make a transfer on behalf of an owner.
    /// @param owner The token owner.
    /// @param account The account to check the operatability of.
    /// @return operatable True if `account` is `owner` or is an operator for `owner`, false otherwise.
    function _isOperatable(Layout storage s, address owner, address account) private view returns (bool operatable) {
        return (owner == account) || s.operators[owner][account];
    }

    function _transferToken(Layout storage s, address from, address to, uint256 id, uint256 value) private {
        if (value != 0) {
            unchecked {
                uint256 fromBalance = s.balances[id][from];
                uint256 newFromBalance = fromBalance - value;
                require(newFromBalance < fromBalance, "ERC1155: insufficient balance");
                if (from != to) {
                    uint256 toBalance = s.balances[id][to];
                    uint256 newToBalance = toBalance + value;
                    require(newToBalance > toBalance, "ERC1155: balance overflow");

                    s.balances[id][from] = newFromBalance;
                    s.balances[id][to] = newToBalance;
                }
            }
        }
    }

    function _mintToken(Layout storage s, address to, uint256 id, uint256 value) private {
        if (value != 0) {
            unchecked {
                uint256 balance = s.balances[id][to];
                uint256 newBalance = balance + value;
                require(newBalance > balance, "ERC1155: balance overflow");
                s.balances[id][to] = newBalance;
            }
        }
    }

    function _burnToken(Layout storage s, address from, uint256 id, uint256 value) private {
        if (value != 0) {
            unchecked {
                uint256 balance = s.balances[id][from];
                uint256 newBalance = balance - value;
                require(newBalance < balance, "ERC1155: insufficient balance");
                s.balances[id][from] = newBalance;
            }
        }
    }

    /// @notice Calls {IERC1155TokenReceiver-onERC1155Received} on a target contract.
    /// @dev Reverts if the call to the target fails, reverts or is rejected.
    /// @param sender The message sender.
    /// @param from Previous token owner.
    /// @param to New token owner.
    /// @param id Identifier of the token transferred.
    /// @param value Value transferred.
    /// @param data Optional data to send along with the receiver contract call.
    function _callOnERC1155Received(address sender, address from, address to, uint256 id, uint256 value, bytes memory data) private {
        require(IERC1155TokenReceiver(to).onERC1155Received(sender, from, id, value, data) == ERC1155_SINGLE_RECEIVED, "ERC1155: transfer rejected");
    }

    /// @notice Calls {IERC1155TokenReceiver-onERC1155BatchReceived} on a target contract.
    /// @dev Reverts if the call to the target fails, reverts or is rejected.
    /// @param sender The message sender.
    /// @param from Previous token owner.
    /// @param to New token owner.
    /// @param ids Identifiers of the tokens transferred.
    /// @param values Values transferred.
    /// @param data Optional data to send along with the receiver contract call.
    function _callOnERC1155BatchReceived(
        address sender,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values,
        bytes memory data
    ) private {
        require(
            IERC1155TokenReceiver(to).onERC1155BatchReceived(sender, from, ids, values, data) == ERC1155_BATCH_RECEIVED,
            "ERC1155: transfer rejected"
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {ProxyInitialization} from "./../../../proxy/libraries/ProxyInitialization.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

library TokenMetadataWithBaseURIStorage {
    using TokenMetadataWithBaseURIStorage for TokenMetadataWithBaseURIStorage.Layout;
    using Strings for uint256;

    struct Layout {
        string baseURI;
    }

    bytes32 public constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.token.metadata.TokenMetadataWithBaseURI.storage")) - 1);

    event BaseMetadataURISet(string baseMetadataURI);

    /// @notice Sets the base metadata URI.
    /// @dev Emits a {BaseMetadataURISet} event.
    /// @param baseURI The base metadata URI.
    function setBaseMetadataURI(Layout storage s, string calldata baseURI) internal {
        s.baseURI = baseURI;
        emit BaseMetadataURISet(baseURI);
    }

    /// @notice Gets the base metadata URI.
    /// @return baseURI The base metadata URI.
    function baseMetadataURI(Layout storage s) internal view returns (string memory baseURI) {
        return s.baseURI;
    }

    /// @notice Gets the token metadata URI for a token as the concatenation of the base metadata URI and the token identfier.
    /// @param id The token identifier.
    /// @return tokenURI The token metadata URI as the concatenation of the base metadata URI and the token identfier.
    function tokenMetadataURI(Layout storage s, uint256 id) internal view returns (string memory tokenURI) {
        return string(abi.encodePacked(s.baseURI, id.toString()));
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}