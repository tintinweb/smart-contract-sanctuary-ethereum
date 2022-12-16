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

import {IERC721Metadata} from "./../interfaces/IERC721Metadata.sol";
import {ERC721Storage} from "./../libraries/ERC721Storage.sol";
import {ERC721ContractMetadataStorage} from "./../libraries/ERC721ContractMetadataStorage.sol";
import {TokenMetadataWithBaseURIStorage} from "./../../metadata/libraries/TokenMetadataWithBaseURIStorage.sol";
import {ContractOwnershipStorage} from "./../../../access/libraries/ContractOwnershipStorage.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";

/// @title ERC721 Non-Fungible Token Standard (proxiable version), optional extension: Metadata (proxiable version).
/// @notice ERC721Metadata implementation where tokenURIs are the concatenation of a base metadata URI and the token identifier (decimal).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Note: This contract requires ERC721 (Non-Fungible Token Standard).
/// @dev Note: This contract requires ERC173 (Contract Ownership standard).
abstract contract ERC721MetadataWithBaseURIBase is Context, IERC721Metadata {
    using ERC721Storage for ERC721Storage.Layout;
    using ERC721ContractMetadataStorage for ERC721ContractMetadataStorage.Layout;
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

    /// @inheritdoc IERC721Metadata
    function name() external view override returns (string memory tokenName) {
        return ERC721ContractMetadataStorage.layout().name();
    }

    /// @inheritdoc IERC721Metadata
    function symbol() external view override returns (string memory tokenSymbol) {
        return ERC721ContractMetadataStorage.layout().symbol();
    }

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenId) external view override returns (string memory uri) {
        ERC721Storage.layout().ownerOf(tokenId); // reverts if the token does not exist
        return TokenMetadataWithBaseURIStorage.layout().tokenMetadataURI(tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IForwarderRegistry} from "./../../../metatx/interfaces/IForwarderRegistry.sol";
import {ERC721ContractMetadataStorage} from "./../libraries/ERC721ContractMetadataStorage.sol";
import {TokenMetadataWithBaseURIStorage} from "./../../metadata/libraries/TokenMetadataWithBaseURIStorage.sol";
import {ProxyAdminStorage} from "./../../../proxy/libraries/ProxyAdminStorage.sol";
import {ERC721MetadataWithBaseURIBase} from "./../base/ERC721MetadataWithBaseURIBase.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import {ForwarderRegistryContextBase} from "./../../../metatx/base/ForwarderRegistryContextBase.sol";

/// @title ERC721 Non-Fungible Token Standard, optional extension: Metadata (facet version).
/// @dev This contract is to be used as a diamond facet (see ERC2535 Diamond Standard https://eips.ethereum.org/EIPS/eip-2535).
/// @dev Note: This facet depends on {ProxyAdminFacet}, {ContractOwnershipFacet} and {InterfaceDetectionFacet}.
contract ERC721MetadataWithBaseURIFacet is ERC721MetadataWithBaseURIBase, ForwarderRegistryContextBase {
    using ProxyAdminStorage for ProxyAdminStorage.Layout;
    using ERC721ContractMetadataStorage for ERC721ContractMetadataStorage.Layout;
    using TokenMetadataWithBaseURIStorage for TokenMetadataWithBaseURIStorage.Layout;

    constructor(IForwarderRegistry forwarderRegistry) ForwarderRegistryContextBase(forwarderRegistry) {}

    /// @notice Initializes the storage with a name and a symbol.
    /// @notice Sets the proxy initialization phase for ERC721ContractMetadataStorage to `1`.
    /// @notice Marks the following ERC165 interface(s) as supported: ERC721Metadata.
    /// @dev Reverts if the sender is not the proxy admin.
    /// @dev Reverts if the proxy initialization phase for ERC721ContractMetadataStorage is set to `1` or above.
    /// @param tokenName The token name
    /// @param tokenSymbol The token symbol
    function initERC721MetadataStorage(string calldata tokenName, string calldata tokenSymbol) external {
        ProxyAdminStorage.layout().enforceIsProxyAdmin(_msgSender());
        ERC721ContractMetadataStorage.layout().proxyInit(tokenName, tokenSymbol);
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

/// @title ERC721 Non-Fungible Token Standard, basic interface (functions).
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev This interface only contains the standard functions. See IERC721Events for the events.
/// @dev Note: The ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 {
    /// @notice Sets or unsets an approval to transfer a single token on behalf of its owner.
    /// @dev Note: There can only be one approved address per token at a given time.
    /// @dev Note: A token approval gets reset when this token is transferred, including a self-transfer.
    /// @dev Reverts if `tokenId` does not exist.
    /// @dev Reverts if `to` is the token owner.
    /// @dev Reverts if the sender is not the token owner and has not been approved by the token owner.
    /// @dev Emits an {Approval} event.
    /// @param to The address to approve, or the zero address to remove any existing approval.
    /// @param tokenId The token identifier to give approval for.
    function approve(address to, uint256 tokenId) external;

    /// @notice Sets or unsets an approval to transfer all tokens on behalf of their owner.
    /// @dev Reverts if the sender is the same as `operator`.
    /// @dev Emits an {ApprovalForAll} event.
    /// @param operator The address to approve for all tokens.
    /// @param approved True to set an approval for all tokens, false to unset it.
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Unsafely transfers the ownership of a token to a recipient.
    /// @dev Note: Usage of this method is discouraged, use `safeTransferFrom` whenever possible.
    /// @dev Resets the token approval for `tokenId`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` is not the owner of `tokenId`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Emits a {Transfer} event.
    /// @param from The current token owner.
    /// @param to The recipient of the token transfer. Self-transfers are possible.
    /// @param tokenId The identifier of the token to transfer.
    function transferFrom(address from, address to, uint256 tokenId) external;

    /// @notice Safely transfers the ownership of a token to a recipient.
    /// @dev Resets the token approval for `tokenId`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` is not the owner of `tokenId`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Reverts if `to` is a contract and the call to {IERC721Receiver-onERC721Received} fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event.
    /// @param from The current token owner.
    /// @param to The recipient of the token transfer.
    /// @param tokenId The identifier of the token to transfer.
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /// @notice Safely transfers the ownership of a token to a recipient.
    /// @dev Resets the token approval for `tokenId`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` is not the owner of `tokenId`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Reverts if `to` is a contract and the call to {IERC721Receiver-onERC721Received} fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event.
    /// @param from The current token owner.
    /// @param to The recipient of the token transfer.
    /// @param tokenId The identifier of the token to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /// @notice Gets the balance of an address.
    /// @dev Reverts if `owner` is the zero address.
    /// @param owner The address to query the balance of.
    /// @return balance The amount owned by the owner.
    function balanceOf(address owner) external view returns (uint256 balance);

    /// @notice Gets the owner of a token.
    /// @dev Reverts if `tokenId` does not exist.
    /// @param tokenId The token identifier to query the owner of.
    /// @return tokenOwner The owner of the token identifier.
    function ownerOf(uint256 tokenId) external view returns (address tokenOwner);

    /// @notice Gets the approved address for a token.
    /// @dev Reverts if `tokenId` does not exist.
    /// @param tokenId The token identifier to query the approval of.
    /// @return approved The approved address for the token identifier, or the zero address if no approval is set.
    function getApproved(uint256 tokenId) external view returns (address approved);

    /// @notice Gets whether an operator is approved for all tokens by an owner.
    /// @param owner The address which gives the approval for all tokens.
    /// @param operator The address which receives the approval for all tokens.
    /// @return approvedForAll Whether the operator is approved for all tokens by the owner.
    function isApprovedForAll(address owner, address operator) external view returns (bool approvedForAll);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721 Non-Fungible Token Standard, optional extension: Batch Transfer.
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev Note: The ERC-165 identifier for this interface is 0xf3993d11.
interface IERC721BatchTransfer {
    /// @notice Unsafely transfers a batch of tokens to a recipient.
    /// @dev Resets the token approval for each of `tokenIds`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if one of `tokenIds` is not owned by `from`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for each of `tokenIds`.
    /// @dev Emits an {IERC721-Transfer} event for each of `tokenIds`.
    /// @param from Current tokens owner.
    /// @param to Address of the new token owner.
    /// @param tokenIds Identifiers of the tokens to transfer.
    function batchTransferFrom(address from, address to, uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721 Non-Fungible Token Standard, optional extension: Burnable.
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev Note: The ERC-165 identifier for this interface is 0x8b8b4ef5.
interface IERC721Burnable {
    /// @notice Burns a token.
    /// @dev Reverts if `tokenId` is not owned by `from`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Emits an {IERC721-Transfer} event with `to` set to the zero address.
    /// @param from The current token owner.
    /// @param tokenId The identifier of the token to burn.
    function burnFrom(address from, uint256 tokenId) external;

    /// @notice Burns a batch of tokens.
    /// @dev Reverts if one of `tokenIds` is not owned by `from`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for each of `tokenIds`.
    /// @dev Emits an {IERC721-Transfer} event with `to` set to the zero address for each of `tokenIds`.
    /// @param from The current tokens owner.
    /// @param tokenIds The identifiers of the tokens to burn.
    function batchBurnFrom(address from, uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721 Non-Fungible Token Standard, optional extension: Deliverable.
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev Note: The ERC-165 identifier for this interface is 0x9da5e832.
interface IERC721Deliverable {
    /// @notice Unsafely mints tokens to multiple recipients.
    /// @dev Reverts if `recipients` and `tokenIds` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if one of `tokenIds` already exists.
    /// @dev Emits an {IERC721-Transfer} event from the zero address for each of `recipients` and `tokenIds`.
    /// @param recipients Addresses of the new tokens owners.
    /// @param tokenIds Identifiers of the tokens to mint.
    function deliver(address[] calldata recipients, uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721 Non-Fungible Token Standard, optional extension: Metadata.
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev Note: The ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata {
    /// @notice Gets the name of the token. E.g. "My Token".
    /// @return tokenName The name of the token.
    function name() external view returns (string memory tokenName);

    /// @notice Gets the symbol of the token. E.g. "TOK".
    /// @return tokenSymbol The symbol of the token.
    function symbol() external view returns (string memory tokenSymbol);

    /// @notice Gets the metadata URI for a token identifier.
    /// @dev Reverts if `tokenId` does not exist.
    /// @param tokenId The token identifier.
    /// @return uri The metadata URI for the token identifier.
    function tokenURI(uint256 tokenId) external view returns (string memory uri);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721 Non-Fungible Token Standard, optional extension: Mintable.
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev Note: The ERC-165 identifier for this interface is 0x8e773e13.
interface IERC721Mintable {
    /// @notice Unsafely mints a token.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `tokenId` already exists.
    /// @dev Emits an {IERC721-Transfer} event from the zero address.
    /// @param to Address of the new token owner.
    /// @param tokenId Identifier of the token to mint.
    function mint(address to, uint256 tokenId) external;

    /// @notice Safely mints a token.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `tokenId` already exists.
    /// @dev Reverts if `to` is a contract and the call to {IERC721Receiver-onERC721Received} fails, reverts or is rejected.
    /// @dev Emits an {IERC721-Transfer} event from the zero address.
    /// @param to Address of the new token owner.
    /// @param tokenId Identifier of the token to mint.
    /// @param data Optional data to pass along to the receiver call.
    function safeMint(address to, uint256 tokenId, bytes calldata data) external;

    /// @notice Unsafely mints a batch of tokens.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if one of `tokenIds` already exists.
    /// @dev Emits an {IERC721-Transfer} event from the zero address for each of `tokenIds`.
    /// @param to Address of the new tokens owner.
    /// @param tokenIds Identifiers of the tokens to mint.
    function batchMint(address to, uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC721 Non-Fungible Token Standard, Tokens Receiver.
/// @notice Interface for supporting safe transfers from ERC721 contracts.
/// @dev See https://eips.ethereum.org/EIPS/eip-721
/// @dev Note: The ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721Receiver {
    /// @notice Handles the receipt of an ERC721 token.
    /// @dev Note: This function is called by an ERC721 contract after a safe transfer.
    /// @dev Note: The ERC721 contract address is always the message sender.
    /// @param operator The initiator of the safe transfer.
    /// @param from The previous token owner.
    /// @param tokenId The token identifier.
    /// @param data Optional additional data with no specified format.
    /// @return magicValue `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))` (`0x150b7a02`) to accept, any other value to refuse.
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC721Metadata} from "./../interfaces/IERC721Metadata.sol";
import {ProxyInitialization} from "./../../../proxy/libraries/ProxyInitialization.sol";
import {InterfaceDetectionStorage} from "./../../../introspection/libraries/InterfaceDetectionStorage.sol";

library ERC721ContractMetadataStorage {
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;
    using ERC721ContractMetadataStorage for ERC721ContractMetadataStorage.Layout;

    struct Layout {
        string tokenName;
        string tokenSymbol;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.token.ERC721.ERC721ContractMetadata.storage")) - 1);
    bytes32 internal constant PROXY_INIT_PHASE_SLOT = bytes32(uint256(keccak256("animoca.token.ERC721.ERC712ContractMetadata.phase")) - 1);

    /// @notice Initializes the storage with a name and symbol (immutable version).
    /// @notice Marks the following ERC165 interface(s) as supported: ERC721Metadata.
    /// @dev Note: This function should be called ONLY in the constructor of an immutable (non-proxied) contract.
    /// @param tokenName The token name.
    /// @param tokenSymbol The token symbol.
    function constructorInit(Layout storage s, string memory tokenName, string memory tokenSymbol) internal {
        s.tokenName = tokenName;
        s.tokenSymbol = tokenSymbol;
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC721Metadata).interfaceId, true);
    }

    /// @notice Initializes the storage with a name and symbol (proxied version).
    /// @notice Sets the proxy initialization phase to `1`.
    /// @notice Marks the following ERC165 interface(s) as supported: ERC721Metadata.
    /// @dev Note: This function should be called ONLY in the init function of a proxied contract.
    /// @dev Reverts if the proxy initialization phase is set to `1` or above.
    /// @param tokenName The token name.
    /// @param tokenSymbol The token symbol.
    function proxyInit(Layout storage s, string calldata tokenName, string calldata tokenSymbol) internal {
        ProxyInitialization.setPhase(PROXY_INIT_PHASE_SLOT, 1);
        s.tokenName = tokenName;
        s.tokenSymbol = tokenSymbol;
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC721Metadata).interfaceId, true);
    }

    /// @notice Gets the name of the token. E.g. "My Token".
    /// @return tokenName The name of the token.
    function name(Layout storage s) internal view returns (string memory tokenName) {
        return s.tokenName;
    }

    /// @notice Gets the symbol of the token. E.g. "TOK".
    /// @return tokenSymbol The symbol of the token.
    function symbol(Layout storage s) internal view returns (string memory tokenSymbol) {
        return s.tokenSymbol;
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

import {IERC721} from "./../interfaces/IERC721.sol";
import {IERC721BatchTransfer} from "./../interfaces/IERC721BatchTransfer.sol";
import {IERC721Mintable} from "./../interfaces/IERC721Mintable.sol";
import {IERC721Deliverable} from "./../interfaces/IERC721Deliverable.sol";
import {IERC721Burnable} from "./../interfaces/IERC721Burnable.sol";
import {IERC721Receiver} from "./../interfaces/IERC721Receiver.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ProxyInitialization} from "./../../../proxy/libraries/ProxyInitialization.sol";
import {InterfaceDetectionStorage} from "./../../../introspection/libraries/InterfaceDetectionStorage.sol";

library ERC721Storage {
    using Address for address;
    using ERC721Storage for ERC721Storage.Layout;
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;

    struct Layout {
        mapping(uint256 => uint256) owners;
        mapping(address => uint256) balances;
        mapping(uint256 => address) approvals;
        mapping(address => mapping(address => bool)) operators;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.token.ERC721.ERC721.storage")) - 1);

    bytes4 internal constant ERC721_RECEIVED = IERC721Receiver.onERC721Received.selector;

    // Single token approval flag
    // This bit is set in the owner's value to indicate that there is an approval set for this token
    uint256 internal constant TOKEN_APPROVAL_OWNER_FLAG = 1 << 160;

    // Burnt token magic value
    // This magic number is used as the owner's value to indicate that the token has been burnt
    uint256 internal constant BURNT_TOKEN_OWNER_VALUE = 0xdead000000000000000000000000000000000000000000000000000000000000;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /// @notice Marks the following ERC165 interface(s) as supported: ERC721.
    function init() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC721).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC721BatchTransfer.
    function initERC721BatchTransfer() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC721BatchTransfer).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC721Mintable.
    function initERC721Mintable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC721Mintable).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC721Deliverable.
    function initERC721Deliverable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC721Deliverable).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: ERC721Burnable.
    function initERC721Burnable() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IERC721Burnable).interfaceId, true);
    }

    /// @notice Sets or unsets an approval to transfer a single token on behalf of its owner.
    /// @dev Note: This function implements {ERC721-approve(address,uint256)}.
    /// @dev Reverts if `tokenId` does not exist.
    /// @dev Reverts if `to` is the token owner.
    /// @dev Reverts if `sender` is not the token owner and has not been approved by the token owner.
    /// @dev Emits an {Approval} event.
    /// @param sender The message sender.
    /// @param to The address to approve, or the zero address to remove any existing approval.
    /// @param tokenId The token identifier to give approval for.
    function approve(Layout storage s, address sender, address to, uint256 tokenId) internal {
        uint256 owner = s.owners[tokenId];
        require(_tokenExists(owner), "ERC721: non-existing token");
        address ownerAddress = _tokenOwner(owner);
        require(to != ownerAddress, "ERC721: self-approval");
        require(_isOperatable(s, ownerAddress, sender), "ERC721: non-approved sender");
        if (to == address(0)) {
            if (_tokenHasApproval(owner)) {
                // remove the approval bit if it is present
                s.owners[tokenId] = uint256(uint160(ownerAddress));
            }
        } else {
            uint256 ownerWithApprovalBit = owner | TOKEN_APPROVAL_OWNER_FLAG;
            if (owner != ownerWithApprovalBit) {
                // add the approval bit if it is not present
                s.owners[tokenId] = ownerWithApprovalBit;
            }
            s.approvals[tokenId] = to;
        }
        emit Approval(ownerAddress, to, tokenId);
    }

    /// @notice Sets or unsets an approval to transfer all tokens on behalf of their owner.
    /// @dev Note: This function implements {ERC721-setApprovalForAll(address,bool)}.
    /// @dev Reverts if `sender` is the same as `operator`.
    /// @dev Emits an {ApprovalForAll} event.
    /// @param sender The message sender.
    /// @param operator The address to approve for all tokens.
    /// @param approved True to set an approval for all tokens, false to unset it.
    function setApprovalForAll(Layout storage s, address sender, address operator, bool approved) internal {
        require(operator != sender, "ERC721: self-approval for all");
        s.operators[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /// @notice Unsafely transfers the ownership of a token to a recipient by a sender.
    /// @dev Note: This function implements {ERC721-transferFrom(address,address,uint256)}.
    /// @dev Resets the token approval for `tokenId`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` is not the owner of `tokenId`.
    /// @dev Reverts if `sender` is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Emits a {Transfer} event.
    /// @param sender The message sender.
    /// @param from The current token owner.
    /// @param to The recipient of the token transfer.
    /// @param tokenId The identifier of the token to transfer.
    function transferFrom(Layout storage s, address sender, address from, address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: transfer to address(0)");

        uint256 owner = s.owners[tokenId];
        require(_tokenExists(owner), "ERC721: non-existing token");
        require(_tokenOwner(owner) == from, "ERC721: non-owned token");

        if (!_isOperatable(s, from, sender)) {
            require(_tokenHasApproval(owner) && sender == s.approvals[tokenId], "ERC721: non-approved sender");
        }

        s.owners[tokenId] = uint256(uint160(to));
        if (from != to) {
            unchecked {
                // cannot underflow as balance is verified through ownership
                --s.balances[from];
                //  cannot overflow as supply cannot overflow
                ++s.balances[to];
            }
        }

        emit Transfer(from, to, tokenId);
    }

    /// @notice Safely transfers the ownership of a token to a recipient by a sender.
    /// @dev Note: This function implements {ERC721-safeTransferFrom(address,address,uint256)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Resets the token approval for `tokenId`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` is not the owner of `tokenId`.
    /// @dev Reverts if `sender` is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Reverts if `to` is a contract and the call to {IERC721Receiver-onERC721Received} fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event.
    /// @param sender The message sender.
    /// @param from The current token owner.
    /// @param to The recipient of the token transfer.
    /// @param tokenId The identifier of the token to transfer.
    function safeTransferFrom(Layout storage s, address sender, address from, address to, uint256 tokenId) internal {
        s.transferFrom(sender, from, to, tokenId);
        if (to.isContract()) {
            _callOnERC721Received(sender, from, to, tokenId, "");
        }
    }

    /// @notice Safely transfers the ownership of a token to a recipient by a sender.
    /// @dev Note: This function implements {ERC721-safeTransferFrom(address,address,uint256,bytes)}.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Resets the token approval for `tokenId`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `from` is not the owner of `tokenId`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Reverts if `to` is a contract and the call to {IERC721Receiver-onERC721Received} fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event.
    /// @param sender The message sender.
    /// @param from The current token owner.
    /// @param to The recipient of the token transfer.
    /// @param tokenId The identifier of the token to transfer.
    /// @param data Optional data to send along to a receiver contract.
    function safeTransferFrom(Layout storage s, address sender, address from, address to, uint256 tokenId, bytes calldata data) internal {
        s.transferFrom(sender, from, to, tokenId);
        if (to.isContract()) {
            _callOnERC721Received(sender, from, to, tokenId, data);
        }
    }

    /// @notice Unsafely transfers a batch of tokens to a recipient by a sender.
    /// @dev Note: This function implements {ERC721BatchTransfer-batchTransferFrom(address,address,uint256[])}.
    /// @dev Resets the token approval for each of `tokenIds`.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if one of `tokenIds` is not owned by `from`.
    /// @dev Reverts if the sender is not `from` and has not been approved by `from` for each of `tokenIds`.
    /// @dev Emits a {Transfer} event for each of `tokenIds`.
    /// @param sender The message sender.
    /// @param from Current tokens owner.
    /// @param to Address of the new token owner.
    /// @param tokenIds Identifiers of the tokens to transfer.
    function batchTransferFrom(Layout storage s, address sender, address from, address to, uint256[] calldata tokenIds) internal {
        require(to != address(0), "ERC721: transfer to address(0)");
        bool operatable = _isOperatable(s, from, sender);

        uint256 length = tokenIds.length;
        unchecked {
            for (uint256 i; i != length; ++i) {
                uint256 tokenId = tokenIds[i];
                uint256 owner = s.owners[tokenId];
                require(_tokenExists(owner), "ERC721: non-existing token");
                require(_tokenOwner(owner) == from, "ERC721: non-owned token");
                if (!operatable) {
                    require(_tokenHasApproval(owner) && sender == s.approvals[tokenId], "ERC721: non-approved sender");
                }
                s.owners[tokenId] = uint256(uint160(to));
                emit Transfer(from, to, tokenId);
            }

            if (from != to && length != 0) {
                // cannot underflow as balance is verified through ownership
                s.balances[from] -= length;
                // cannot overflow as supply cannot overflow
                s.balances[to] += length;
            }
        }
    }

    /// @notice Unsafely mints a token.
    /// @dev Note: This function implements {ERC721Mintable-mint(address,uint256)}.
    /// @dev Note: Either `mint` or `mintOnce` should be used in a given contract, but not both.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `tokenId` already exists.
    /// @dev Emits a {Transfer} event from the zero address.
    /// @param to Address of the new token owner.
    /// @param tokenId Identifier of the token to mint.
    function mint(Layout storage s, address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to address(0)");
        require(!_tokenExists(s.owners[tokenId]), "ERC721: existing token");

        s.owners[tokenId] = uint256(uint160(to));

        unchecked {
            // cannot overflow due to the cost of minting individual tokens
            ++s.balances[to];
        }

        emit Transfer(address(0), to, tokenId);
    }

    /// @notice Safely mints a token.
    /// @dev Note: This function implements {ERC721Mintable-safeMint(address,uint256,bytes)}.
    /// @dev Note: Either `safeMint` or `safeMintOnce` should be used in a given contract, but not both.
    /// @dev Warning: Since a `to` contract can run arbitrary code, developers should be aware of potential re-entrancy attacks.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `tokenId` already exists.
    /// @dev Reverts if `to` is a contract and the call to {IERC721Receiver-onERC721Received} fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event from the zero address.
    /// @param to Address of the new token owner.
    /// @param tokenId Identifier of the token to mint.
    /// @param data Optional data to pass along to the receiver call.
    function safeMint(Layout storage s, address sender, address to, uint256 tokenId, bytes memory data) internal {
        s.mint(to, tokenId);
        if (to.isContract()) {
            _callOnERC721Received(sender, address(0), to, tokenId, data);
        }
    }

    /// @notice Unsafely mints a batch of tokens.
    /// @dev Note: This function implements {ERC721Mintable-batchMint(address,uint256[])}.
    /// @dev Note: Either `batchMint` or `batchMintOnce` should be used in a given contract, but not both.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if one of `tokenIds` already exists.
    /// @dev Emits a {Transfer} event from the zero address for each of `tokenIds`.
    /// @param to Address of the new tokens owner.
    /// @param tokenIds Identifiers of the tokens to mint.
    function batchMint(Layout storage s, address to, uint256[] memory tokenIds) internal {
        require(to != address(0), "ERC721: mint to address(0)");

        uint256 length = tokenIds.length;
        unchecked {
            for (uint256 i; i != length; ++i) {
                uint256 tokenId = tokenIds[i];
                require(!_tokenExists(s.owners[tokenId]), "ERC721: existing token");

                s.owners[tokenId] = uint256(uint160(to));
                emit Transfer(address(0), to, tokenId);
            }

            s.balances[to] += length;
        }
    }

    /// @notice Unsafely mints tokens to multiple recipients.
    /// @dev Note: This function implements {ERC721Deliverable-deliver(address[],uint256[])}.
    /// @dev Note: Either `deliver` or `deliverOnce` should be used in a given contract, but not both.
    /// @dev Reverts if `recipients` and `tokenIds` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if one of `tokenIds` already exists.
    /// @dev Emits a {Transfer} event from the zero address for each of `recipients` and `tokenIds`.
    /// @param recipients Addresses of the new tokens owners.
    /// @param tokenIds Identifiers of the tokens to mint.
    function deliver(Layout storage s, address[] memory recipients, uint256[] memory tokenIds) internal {
        uint256 length = recipients.length;
        require(length == tokenIds.length, "ERC721: inconsistent arrays");
        unchecked {
            for (uint256 i; i != length; ++i) {
                s.mint(recipients[i], tokenIds[i]);
            }
        }
    }

    /// @notice Unsafely mints a token once.
    /// @dev Note: This function implements {ERC721Mintable-mint(address,uint256)}.
    /// @dev Note: Either `mint` or `mintOnce` should be used in a given contract, but not both.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `tokenId` already exists.
    /// @dev Reverts if `tokenId` has been previously burnt.
    /// @dev Emits a {Transfer} event from the zero address.
    /// @param to Address of the new token owner.
    /// @param tokenId Identifier of the token to mint.
    function mintOnce(Layout storage s, address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to address(0)");

        uint256 owner = s.owners[tokenId];
        require(!_tokenExists(owner), "ERC721: existing token");
        require(!_tokenWasBurnt(owner), "ERC721: burnt token");

        s.owners[tokenId] = uint256(uint160(to));

        unchecked {
            // cannot overflow due to the cost of minting individual tokens
            ++s.balances[to];
        }

        emit Transfer(address(0), to, tokenId);
    }

    /// @notice Safely mints a token once.
    /// @dev Note: This function implements {ERC721Mintable-safeMint(address,uint256,bytes)}.
    /// @dev Note: Either `safeMint` or `safeMintOnce` should be used in a given contract, but not both.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if `tokenId` already exists.
    /// @dev Reverts if `tokenId` has been previously burnt.
    /// @dev Reverts if `to` is a contract and the call to {IERC721Receiver-onERC721Received} fails, reverts or is rejected.
    /// @dev Emits a {Transfer} event from the zero address.
    /// @param to Address of the new token owner.
    /// @param tokenId Identifier of the token to mint.
    /// @param data Optional data to pass along to the receiver call.
    function safeMintOnce(Layout storage s, address sender, address to, uint256 tokenId, bytes memory data) internal {
        s.mintOnce(to, tokenId);
        if (to.isContract()) {
            _callOnERC721Received(sender, address(0), to, tokenId, data);
        }
    }

    /// @notice Unsafely mints a batch of tokens once.
    /// @dev Note: This function implements {ERC721Mintable-batchMint(address,uint256[])}.
    /// @dev Note: Either `batchMint` or `batchMintOnce` should be used in a given contract, but not both.
    /// @dev Reverts if `to` is the zero address.
    /// @dev Reverts if one of `tokenIds` already exists.
    /// @dev Reverts if one of `tokenIds` has been previously burnt.
    /// @dev Emits a {Transfer} event from the zero address for each of `tokenIds`.
    /// @param to Address of the new tokens owner.
    /// @param tokenIds Identifiers of the tokens to mint.
    function batchMintOnce(Layout storage s, address to, uint256[] memory tokenIds) internal {
        require(to != address(0), "ERC721: mint to address(0)");

        uint256 length = tokenIds.length;
        unchecked {
            for (uint256 i; i != length; ++i) {
                uint256 tokenId = tokenIds[i];
                uint256 owner = s.owners[tokenId];
                require(!_tokenExists(owner), "ERC721: existing token");
                require(!_tokenWasBurnt(owner), "ERC721: burnt token");

                s.owners[tokenId] = uint256(uint160(to));

                emit Transfer(address(0), to, tokenId);
            }

            s.balances[to] += length;
        }
    }

    /// @notice Unsafely mints tokens to multiple recipients once.
    /// @dev Note: This function implements {ERC721Deliverable-deliver(address[],uint256[])}.
    /// @dev Note: Either `deliver` or `deliverOnce` should be used in a given contract, but not both.
    /// @dev Reverts if `recipients` and `tokenIds` have different lengths.
    /// @dev Reverts if one of `recipients` is the zero address.
    /// @dev Reverts if one of `tokenIds` already exists.
    /// @dev Reverts if one of `tokenIds` has been previously burnt.
    /// @dev Emits a {Transfer} event from the zero address for each of `recipients` and `tokenIds`.
    /// @param recipients Addresses of the new tokens owners.
    /// @param tokenIds Identifiers of the tokens to mint.
    function deliverOnce(Layout storage s, address[] memory recipients, uint256[] memory tokenIds) internal {
        uint256 length = recipients.length;
        require(length == tokenIds.length, "ERC721: inconsistent arrays");
        unchecked {
            for (uint256 i; i != length; ++i) {
                address to = recipients[i];
                require(to != address(0), "ERC721: mint to address(0)");

                uint256 tokenId = tokenIds[i];
                uint256 owner = s.owners[tokenId];
                require(!_tokenExists(owner), "ERC721: existing token");
                require(!_tokenWasBurnt(owner), "ERC721: burnt token");

                s.owners[tokenId] = uint256(uint160(to));
                ++s.balances[to];

                emit Transfer(address(0), to, tokenId);
            }
        }
    }

    /// @notice Burns a token by a sender.
    /// @dev Note: This function implements {ERC721Burnable-burnFrom(address,uint256)}.
    /// @dev Reverts if `tokenId` is not owned by `from`.
    /// @dev Reverts if `sender` is not `from` and has not been approved by `from` for `tokenId`.
    /// @dev Emits a {Transfer} event with `to` set to the zero address.
    /// @param sender The message sender.
    /// @param from The current token owner.
    /// @param tokenId The identifier of the token to burn.
    function burnFrom(Layout storage s, address sender, address from, uint256 tokenId) internal {
        uint256 owner = s.owners[tokenId];
        require(from == _tokenOwner(owner), "ERC721: non-owned token");

        if (!_isOperatable(s, from, sender)) {
            require(_tokenHasApproval(owner) && sender == s.approvals[tokenId], "ERC721: non-approved sender");
        }

        s.owners[tokenId] = BURNT_TOKEN_OWNER_VALUE;

        unchecked {
            // cannot underflow as balance is verified through TOKEN ownership
            --s.balances[from];
        }
        emit Transfer(from, address(0), tokenId);
    }

    /// @notice Burns a batch of tokens by a sender.
    /// @dev Note: This function implements {ERC721Burnable-batchBurnFrom(address,uint256[])}.
    /// @dev Reverts if one of `tokenIds` is not owned by `from`.
    /// @dev Reverts if `sender` is not `from` and has not been approved by `from` for each of `tokenIds`.
    /// @dev Emits a {Transfer} event with `to` set to the zero address for each of `tokenIds`.
    /// @param sender The message sender.
    /// @param from The current tokens owner.
    /// @param tokenIds The identifiers of the tokens to burn.
    function batchBurnFrom(Layout storage s, address sender, address from, uint256[] calldata tokenIds) internal {
        bool operatable = _isOperatable(s, from, sender);

        uint256 length = tokenIds.length;
        unchecked {
            for (uint256 i; i != length; ++i) {
                uint256 tokenId = tokenIds[i];
                uint256 owner = s.owners[tokenId];
                require(from == _tokenOwner(owner), "ERC721: non-owned token");
                if (!operatable) {
                    require(_tokenHasApproval(owner) && sender == s.approvals[tokenId], "ERC721: non-approved sender");
                }
                s.owners[tokenId] = BURNT_TOKEN_OWNER_VALUE;
                emit Transfer(from, address(0), tokenId);
            }

            if (length != 0) {
                s.balances[from] -= length;
            }
        }
    }

    /// @notice Gets the balance of an address.
    /// @dev Note: This function implements {ERC721-balanceOf(address)}.
    /// @dev Reverts if `owner` is the zero address.
    /// @param owner The address to query the balance of.
    /// @return balance The amount owned by the owner.
    function balanceOf(Layout storage s, address owner) internal view returns (uint256 balance) {
        require(owner != address(0), "ERC721: balance of address(0)");
        return s.balances[owner];
    }

    /// @notice Gets the owner of a token.
    /// @dev Note: This function implements {ERC721-ownerOf(uint256)}.
    /// @dev Reverts if `tokenId` does not exist.
    /// @param tokenId The token identifier to query the owner of.
    /// @return tokenOwner The owner of the token.
    function ownerOf(Layout storage s, uint256 tokenId) internal view returns (address tokenOwner) {
        uint256 owner = s.owners[tokenId];
        require(_tokenExists(owner), "ERC721: non-existing token");
        return _tokenOwner(owner);
    }

    /// @notice Gets the approved address for a token.
    /// @dev Note: This function implements {ERC721-getApproved(uint256)}.
    /// @dev Reverts if `tokenId` does not exist.
    /// @param tokenId The token identifier to query the approval of.
    /// @return approved The approved address for the token identifier, or the zero address if no approval is set.
    function getApproved(Layout storage s, uint256 tokenId) internal view returns (address approved) {
        uint256 owner = s.owners[tokenId];
        require(_tokenExists(owner), "ERC721: non-existing token");
        if (_tokenHasApproval(owner)) {
            return s.approvals[tokenId];
        } else {
            return address(0);
        }
    }

    /// @notice Gets whether an operator is approved for all tokens by an owner.
    /// @dev Note: This function implements {ERC721-isApprovedForAll(address,address)}.
    /// @param owner The address which gives the approval for all tokens.
    /// @param operator The address which receives the approval for all tokens.
    /// @return approvedForAll Whether the operator is approved for all tokens by the owner.
    function isApprovedForAll(Layout storage s, address owner, address operator) internal view returns (bool approvedForAll) {
        return s.operators[owner][operator];
    }

    /// @notice Gets whether a token was burnt.
    /// @param tokenId The token identifier.
    /// @return tokenWasBurnt Whether the token was burnt.
    function wasBurnt(Layout storage s, uint256 tokenId) internal view returns (bool tokenWasBurnt) {
        return _tokenWasBurnt(s.owners[tokenId]);
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }

    /// @notice Calls {IERC721Receiver-onERC721Received} on a target contract.
    /// @dev Reverts if the call to the target fails, reverts or is rejected.
    /// @param sender The message sender.
    /// @param from Previous token owner.
    /// @param to New token owner.
    /// @param tokenId Identifier of the token transferred.
    /// @param data Optional data to send along with the receiver contract call.
    function _callOnERC721Received(address sender, address from, address to, uint256 tokenId, bytes memory data) private {
        require(IERC721Receiver(to).onERC721Received(sender, from, tokenId, data) == ERC721_RECEIVED, "ERC721: safe transfer rejected");
    }

    /// @notice Returns whether an account is authorised to make a transfer on behalf of an owner.
    /// @param owner The token owner.
    /// @param account The account to check the operatability of.
    /// @return operatable True if `account` is `owner` or is an operator for `owner`, false otherwise.
    function _isOperatable(Layout storage s, address owner, address account) private view returns (bool operatable) {
        return (owner == account) || s.operators[owner][account];
    }

    function _tokenOwner(uint256 owner) private pure returns (address tokenOwner) {
        return address(uint160(owner));
    }

    function _tokenExists(uint256 owner) private pure returns (bool tokenExists) {
        return uint160(owner) != 0;
    }

    function _tokenWasBurnt(uint256 owner) private pure returns (bool tokenWasBurnt) {
        return owner == BURNT_TOKEN_OWNER_VALUE;
    }

    function _tokenHasApproval(uint256 owner) private pure returns (bool tokenHasApproval) {
        return owner & TOKEN_APPROVAL_OWNER_FLAG != 0;
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