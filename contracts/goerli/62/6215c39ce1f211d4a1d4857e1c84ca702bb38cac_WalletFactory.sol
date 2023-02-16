// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
library StorageSlotUpgradeable {
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

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
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
            return toHexString(value, MathUpgradeable.log256(value) + 1);
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
library MathUpgradeable {
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
pragma solidity 0.8.17;

import "./ProxyUtils.sol";

/// @title Proxy
/// @notice Proxy-side code for a minimal version of [OpenZeppelin's `ERC1967Proxy`](https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/proxy/ERC1967/ERC1967Proxy.sol).
contract Proxy is ProxyUtils {
    /// @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
    /// If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
    /// function call, and allows initializing the storage of the proxy like a Solidity constructor.
    constructor(address _logic) {
        _upgradeTo(_logic);
    }

    /// @dev Delegates the current call to the address returned by `_implementation()`.
    /// This function does not return to its internal call site, it will return directly to the external caller.
    function _fallback() internal {
        _delegate(_implementation());
    }

    /// @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
    /// function in the contract matches the call data.
    fallback() external payable {
        _fallback();
    }

    /// @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
    /// is empty.
    receive() external payable {
        _fallback();
    }

    /// @dev Delegates the current call to `implementation`.
    /// This function does not return to its internal call site, it will return directly to the external caller.
    function _delegate(address implementation) internal {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts-upgradeable/contracts/utils/AddressUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/utils/StorageSlotUpgradeable.sol";

/// @title ProxyUtils
/// @notice Common code for `Proxy` and underlying implementation contracts.
contract ProxyUtils {
    /// @dev Storage slot with the address of the current implementation.
    /// This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
    /// validated in the constructor.
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev Emitted when the implementation is upgraded.
    event Upgraded(address indexed implementation);

    /// @dev Returns the current implementation address.
    function _implementation() internal view returns (address impl) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /// @dev Perform implementation upgrade
    /// Emits an {Upgraded} event.
    function _upgradeTo(address newImplementation) internal {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
        emit Upgraded(newImplementation);
    }

    /// @dev Perform implementation upgrade with additional setup call.
    /// Emits an {Upgraded} event.
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /// @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
    /// but performing a delegate call.
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts-upgradeable/contracts/utils/StringsUpgradeable.sol";

import "./WalletFactory.sol";
import "./ProxyUtils.sol";

/// @title Wallet
/// @notice Basic multisig smart contract wallet with a relay guardian.
contract Wallet is ProxyUtils {
    using AddressUpgradeable for address;

    /// @notice The creating `WalletFactory`.
    WalletFactory public walletFactory;

    /// @dev Struct for a signer.
    struct SignerConfig {
        uint8 votes;
        uint256 signingTimelock;
    }

    /// @notice Configs per signer.
    mapping(address => SignerConfig) public signerConfigs;

    /// @dev Event emitted when a signer config is changed.
    event SignerConfigChanged(address indexed signer, SignerConfig config);

    /// @notice Threshold of signer votes required to sign transactions.
    uint8 public threshold;

    /// @notice Timelock after which the contract can be upgraded and/or the relayer whitelist can be disabled.
    uint256 public relayerWhitelistTimelock;

    /// @dev Struct for a signature.
    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    /// @notice Last timestamp disabling the relayer whitelist was queued/requested.
    uint256 public disableRelayerWhitelistQueueTimestamp;

    /// @notice Maps pending (queued) signature hashes to queue timestamps.
    mapping(bytes32 => uint256) public pendingSignatures;

    /// @notice Current transaction nonce (prevents replays).
    uint256 public nonce;

    /// @dev Initializes the contract.
    /// See `WalletFactory` for details.
    function initialize(
        address[] calldata signers,
        SignerConfig[] calldata _signerConfigs,
        uint8 _threshold,
        uint256 _relayerWhitelistTimelock,
        bool _subscriptionPaymentsEnabled
    ) external {
        // Make sure not initialized already
        require(threshold == 0, "Already initialized.");

        // Input validation
        require(signers.length > 0, "Must have at least one signer.");
        require(signers.length == _signerConfigs.length, "Lengths of signer and signer config arrays must match.");
        require(_threshold > 0, "Vote threshold must be greater than 0.");

        // Set variables
        for (uint256 i = 0; i < _signerConfigs.length; i++) {
            signerConfigs[signers[i]] = _signerConfigs[i];
            emit SignerConfigChanged(signers[i], _signerConfigs[i]);
        }

        threshold = _threshold;
        relayerWhitelistTimelock = _relayerWhitelistTimelock;
        subscriptionPaymentsEnabled = _subscriptionPaymentsEnabled;

        // Set WalletFactory
        walletFactory = WalletFactory(msg.sender);

        // Set lastSubscriptionPaymentTimestamp
        if (_subscriptionPaymentsEnabled) lastSubscriptionPaymentTimestamp = block.timestamp - SUBSCRIPTION_PAYMENT_INTERVAL_SECONDS;
    }

    /// @dev Access control for the contract itself.
    /// Make sure to call functions marked with this modifier via `Wallet.functionCall`.
    modifier onlySelf() {
        require(msg.sender == address(this), "Sender is not self.");
        _;
    }

    /// @dev Internal function to verify `signatures` on `signedData`.
    function _validateSignatures(Signature[] calldata signatures, bytes32 signedDataHash, bool requireRelayGuardian) internal view {
        // Input validation
        require(signatures.length > 0, "No signatures supplied.");
        
        // Loop through signers to tally votes (keeping track of signers checked to look for duplicates)
        uint256 _votes = 0;
        address[] memory signers = new address[](signatures.length);

        for (uint256 i = 0; i < signatures.length; i++) {
            // Get signer
            Signature calldata sig = signatures[i];
            address signer = ecrecover(signedDataHash, sig.v, sig.r, sig.s);

            // Check for duplicate & keep track of signer to check for duplicates in the future
            for (uint256 j = 0; j < i; j++) require(signer != signers[j], "Duplicate signer in signatures array.");
            signers[i] = signer;

            // Get signer config
            SignerConfig memory config = signerConfigs[signer];
            require(config.votes > 0, "Unrecognized signer.");

            // Check signing timelock
            if (config.signingTimelock > 0) {
                uint256 timestamp = pendingSignatures[keccak256(abi.encode(sig))];
                require(timestamp > 0, "Signature not queued.");
                require(timestamp + config.signingTimelock <= block.timestamp, "Timelock not satisfied.");
            }

            // Tally votes
            _votes += config.votes;
        }

        // Check tally of votes against threshold
        require(_votes >= threshold, "Votes not greater than or equal to threshold.");

        // Relayer validation (if enabled)
        if (relayerWhitelistTimelock > 0 && requireRelayGuardian) walletFactory.checkRelayGuardian(msg.sender);
    }

    /// @notice Event emitted when a function call reverts.
    event FunctionCallReversion(uint256 indexed _nonce, uint256 indexA, uint256 indexB, string error);

    /// @notice Call any function on any contract given sufficient authentication.
    /// If the call reverts, the transaction will not revert but will emit a `FunctionCallReversion` event.
    /// @dev NOTICE: Does not validate that ETH balance is great enough for value + gas refund to paymaster + paymaster incentive. Handle this on the UI + relayer sides.
    /// Before the user signs, the UI should calculate gas usage and ensure the external function call will not revert with `eth_estimateGas`.
    /// Relayer should confirm the function call does not revert due to bad signatures or low gas limit by either `eth_call` or `eth_estimateGas` or by simulating signature validation off-chain.
    /// Predict user-specified gas limit (i.e., `feeData[0]`) using the following pseudocode:
    ///     const A = 22000; // Maximum base gas recognized by `gasleft()` in `functionCall` (assume `value` > 0). TODO: Should this include some leeway for unexpected increased in return data?
    ///     const B = 9000; // Maximum gas used by `_validateSignatures` per signature, without `signingTimelock`s (but assume `checkRelayGuardian` for now).
    ///     const C = 3000; // Additional gas used by `_validateSignatures` per signature due to presence of `signingTimelock > 0`.
    ///     const E = 0.195; // Additional gas used per byte of calldata in the external function call.
    ///     let sigGas = 0;
    ///     for (const sig of signatures) sigGas += B + (signerConfig.signingTimelock > 0 ? C : 0);
    ///     return A + sigGas + E * data.length + simulateFunctionCall(target, data, value);
    /// Predict paymaster incentive (i.e., `feeData[3]`) with the following pseudocode:
    ///     const X = 38000; // Maximum base gas unrecognized by `gasleft()` in `functionCall`.
    ///     const Y = 1200; // Maximum gas used per signature (in terms of built-in ABI decoding of `functionCall`'s data into its `signatures` parameter).
    ///     const W = 16.5; // Maximum gas used per byte of calldata in the external function call.
    ///     return X + Y * signatures.length + W * data.length;
    /// It's a good idea to add leeway by multiplying the user-specified gas limit by 1.1x to 1.5x since the risk of losing the leeway is low and the risk of not giving enough leeway is much greater (primarily because the external function call itself can vary greatly in gas usage).
    /// However, the paymaster incentive should be kept as is because, since the values are already higher than the average, the relayer will, on average, gain a small amount of ETH, and there is no penalty to the user if the relayer loses slightly.
    /// @param feeData Array of `[gasLimit, maxFeePerGas, maxPriorityFeePerGas, paymasterIncentive]`.
    function functionCall(
        Signature[] calldata signatures,
        address target,
        bytes calldata data,
        uint256 value,
        uint256[4] calldata feeData
    ) external {
        // Get initial gas
        uint256 initialGas = gasleft();

        // Get message hash (include chain ID, wallet contract address, and nonce) and validate signatures
        bytes32 dataHash = keccak256(abi.encode(block.chainid, address(this), ++nonce, this.functionCall.selector, target, data, value, feeData));
        _validateSignatures(signatures, dataHash, true);

        // Gas validation
        require(tx.gasprice <= feeData[1], "maxFeePerGas not satisfied.");
        require(tx.gasprice - block.basefee <= feeData[2], "maxPriorityFeePerGas not satisfied.");

        // Call contract
        (bool success, bytes memory ret) = target.call{ value: value, gas: gasleft() - 30000 }(data);
        if (!success) emit FunctionCallReversion(nonce, 0, 0, string(abi.encode(bytes32(ret))));

        // Send relayer the gas back
        uint256 gasUsed = initialGas - gasleft();
        require(gasUsed <= feeData[0], "Gas limit not satisfied.");
        msg.sender.call{value: (gasUsed * tx.gasprice) + feeData[3] }("");
    }

    /// @notice Checks gas usage (and revert string if a function reverts) for calling a function on a contract. Always reverts with the gas usage encoded, unless a revert happens earlier.
    /// @dev Requires that the sender is the zero address so that the function is read-only. (This prevents accidental use and might provide additional security, though it probably doesn't since this function always reverts at the end, but costs us nothing so why not?)
    function simulateFunctionCall(
        address target,
        bytes calldata data,
        uint256 value
    ) external {
        // Require sender == zero address
        require(msg.sender == address(0), "Sender must be the zero address for simulations.");

        // Bogus feeData (for abi.encode simulation below)
        uint256[4] memory feeData = [
            0x7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f,
            0x7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f,
            0x7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f,
            0x7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f
        ];

        // Get initial gas
        uint256 initialGas = gasleft();

        // Simulate getting message hash (since gas is hard to predict)
        keccak256(abi.encode(block.chainid, address(this), ++nonce, this.functionCall.selector, target, data, value, feeData));

        // Actually simulate the external function call
        (bool success, bytes memory ret) = target.call{ value: value, gas: gasleft() - 30000 }(data);

        // Bubble up revert
        if (!success) revert(string(abi.encodePacked("Call reverted: ", ret)));

        // Revert with gas used encoded as a decimal string
        revert(string(abi.encodePacked("WALLET_SIMULATE_FUNCTION_CALL_MULTI_GAS_USAGE=", StringsUpgradeable.toString(initialGas - gasleft()))));
    }

    /// @notice Call multiple functions on any contract(s) given sufficient authentication.
    /// If the call reverts, the transaction will not revert but will emit a `FunctionCallReversion` event.
    /// @dev NOTICE: Does not validate that ETH balance is great enough for value + gas refund to paymaster + paymaster incentive. Handle this on the UI + relayer sides.
    /// Before the user signs, the UI should calculate gas usage and ensure function calls will not revert with `simulateFunctionCallMulti`.
    /// Relayer should confirm the function call does not revert due to bad signatures or low gas limit by either `eth_call` or `eth_estimateGas` or by simulating signature validation off-chain.
    /// Predict user-specified gas limit (i.e., `feeData[0]`) using the following pseudocode:
    ///     const A; // Maximum base gas recognized by `gasleft()` in `functionCallMulti` (excluding paymaster incentive).
    ///     const B; // Maximum gas used by `_validateSignatures` per signature, without `signingTimelock`s (but assume `checkRelayGuardian` for now).
    ///     const C; // Additional gas used by `_validateSignatures` per signature due to presence of `signingTimelock > 0`.
    ///     const D; // Base gas used per external function call: only necessary if there is a need to include some leeway for unexpected increased in return data. TODO: Do we need this?
    ///     let sigGas = 0;
    ///     for (const sig of signatures) sigGas += B + (signerConfig.signingTimelock > 0 ? C : 0);
    ///     return A + sigGas + D * targets.length + simulateFunctionCallMulti(targets, data, values);
    /// Predict paymaster incentive (i.e., `feeData[3]`) with the following pseudocode:
    ///     const X; // Maximum base gas unrecognized by `gasleft()` in `functionCallMulti`.
    ///     const Y; // Maximum gas used per signature (in terms of built-in ABI decoding of `functionCallMulti`'s data into its `signatures` parameter).
    ///     const Z; // Maximum base gas used per external function call (in terms of built-in ABI decoding of `functionCallMulti`'s data into its `targets`, `data`, and `values` parameters).
    ///     const W; // Maximum gas used per byte of calldata in each external function call.
    ///     return X + Y * signatures.length + sum(Z + W * data[i].length);
    /// It's a good idea to add leeway to the user-specified gas limit since the risk of losing the leeway is low and the risk of not giving enough leeway is much greater.
    /// However, the paymaster incentive should be kept as is because, since the values are already higher than the average, the relayer will, on average, gain a small amount of ETH, and there is no penalty to the user if the relayer loses slightly.
    /// @param feeData Array of `[gasLimit, maxFeePerGas, maxPriorityFeePerGas, paymasterIncentive]`.
    function functionCallMulti(
        Signature[] calldata signatures,
        address[] calldata targets,
        bytes[] calldata data,
        uint256[] calldata values,
        uint256[4] calldata feeData
    ) external {
        // Get initial gas
        uint256 initialGas = gasleft();

        // Get message hash (include chain ID, wallet contract address, and nonce) and validate signatures
        bytes32 dataHash = keccak256(abi.encode(block.chainid, address(this), ++nonce, this.functionCallMulti.selector, targets, data, values, feeData));
        _validateSignatures(signatures, dataHash, true);

        // Gas validation
        require(tx.gasprice <= feeData[1], "maxFeePerGas not satisfied.");
        require(tx.gasprice - block.basefee <= feeData[2], "maxPriorityFeePerGas not satisfied.");

        // Input validation
        require(targets.length == data.length && targets.length == values.length, "Input array lengths must be equal.");

        // Call contracts
        for (uint256 i = 0; i < targets.length; i++) {
            uint256 gasl = gasleft();
            // If there isn't enough gas left to run the function, break now to avoid checked math reversion when subtracting 30000 from gas left
            if (gasl <= 30000) {
                emit FunctionCallReversion(nonce, 0, i, "Wallet: Function call ran out of gas.");
                break;
            }
            (bool success, bytes memory ret) = targets[i].call{ value: values[i], gas: gasl - 30000 }(data[i]);
            if (!success) emit FunctionCallReversion(nonce, 0, i, string(abi.encode(bytes32(ret))));
        }

        // Send relayer the gas back
        uint256 gasUsed = initialGas - gasleft();
        require(gasUsed <= feeData[0], "Gas limit not satisfied.");
        msg.sender.call{value: (gasUsed * tx.gasprice) + feeData[3] }("");
    }

    /// @notice Checks gas usage (and revert string if a function reverts) for calling multiple functions on contract(s). Always reverts with the gas usage encoded, unless a revert happens earlier.
    /// @dev Requires that the sender is the zero address so that the function is read-only. (This prevents accidental use and might provide additional security, though it probably doesn't since this function always reverts at the end, but costs us nothing so why not?)
    function simulateFunctionCallMulti(
        address[] calldata targets,
        bytes[] calldata data,
        uint256[] calldata values
    ) external {
        // Require sender == zero address
        require(msg.sender == address(0), "Sender must be the zero address for simulations.");

        // Bogus feeData (for abi.encode simulation below)
        uint256[4] memory feeData = [
            0x7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f,
            0x7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f,
            0x7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f,
            0x7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f7f
        ];

        // Get initial gas
        uint256 initialGas = gasleft();

        // Simulate getting message hash (since gas is hard to predict)
        keccak256(abi.encode(block.chainid, address(this), ++nonce, this.functionCallMulti.selector, targets, data, values, feeData));

        // Call contracts
        for (uint256 i = 0; i < targets.length; i++) {
            // Simulate these 2 operations to avoid having to factor it into the off-chain gas calculation
            uint256 gasl = gasleft();
            if (gasl <= 30000) revert(string(abi.encodePacked("Function call #", StringsUpgradeable.toString(i), " ran out of gas.")));

            // Actually simulate the external function call
            (bool success, bytes memory ret) = targets[i].call{ value: values[i], gas: gasl - 30000 }(data[i]);

            // Bubble up revert
            if (!success) revert(string(abi.encodePacked("Reverted on call #", StringsUpgradeable.toString(i), ": ", ret)));
        }

        // Revert with gas used encoded as a decimal string
        revert(string(abi.encodePacked("WALLET_SIMULATE_FUNCTION_CALL_MULTI_GAS_USAGE=", StringsUpgradeable.toString(initialGas - gasleft()))));
    }

    /// @notice Allows sending a combination of `functionCall`s and `functionCallMulti`s.
    /// Only useful for multi-party wallets--if using a single-party wallet, just re-sign all pending transactions and use `functionCallMulti` to save gas.
    /// If the call reverts, the transaction will not revert but will emit a `FunctionCallReversion` event.
    /// @dev NOTICE: Does not validate that ETH balance is great enough for value + gas refund to paymaster + paymaster incentive. Handle this on the UI + relayer sides.
    /// Relayer should confirm the function call does not revert due to bad signatures or low gas limit by either `eth_call` or `eth_estimateGas` or by simulating signature validation off-chain.
    /// @param multi Array of booleans indicating whether or not their associated item in `signedData` (and their associated item in `signatures`) is a `functionCall` or a `functionCallMulti`.
    /// @param signatures Array of arrays of signatures for each `functionCall` or `functionCallMulti`--each array corresponds to each item in the `multi` parameter and each item in the `signedData` parameter.
    /// @param signedData Array of signed data for each `functionCall` or `functionCallMulti`--each item corresponds to each item in the `multi` parameter and each item in the `signatures` parameter.
    function functionCallBatch(
        bool[] calldata multi,
        Signature[][] calldata signatures,
        bytes[] calldata signedData
    ) external {
        // Get initial gas
        uint256 initialGas = gasleft();

        // Input validation
        require(multi.length == signatures.length && multi.length == signedData.length, "Input array lengths must be equal.");

        // Loop through batch
        uint256 totalPaymasterIncentive = 0;

        for (uint256 i = 0; i < multi.length; i++) {
            uint256 minEndingGas = gasleft();
            _validateSignatures(signatures[i], keccak256(signedData[i]), true);

            if (multi[i]) {
                // Decode data and check relayer
                address[] memory targets;
                bytes[] memory data;
                uint256[] memory values;
                {
                    uint256 chainid;
                    address wallet;
                    uint256 _nonce;
                    bytes4 selector;
                    uint256[4] memory feeData;
                    (chainid, wallet, _nonce, selector, targets, data, values, feeData) =
                        abi.decode(signedData[i], (uint256, address, uint256, bytes4, address[], bytes[], uint256[], uint256[4]));
                    require(chainid == block.chainid && wallet == address(this) && _nonce == ++nonce && selector == this.functionCallMulti.selector, "Invalid functionCallMulti signature.");
                    totalPaymasterIncentive += feeData[3];

                    // Gas validation
                    minEndingGas -= feeData[0];
                    require(tx.gasprice <= feeData[1], "maxFeePerGas not satisfied.");
                    require(tx.gasprice - block.basefee <= feeData[2], "maxPriorityFeePerGas not satisfied.");
                }

                // Input validation
                require(targets.length == data.length && targets.length == values.length, "Input array lengths must be equal.");

                // Call contracts
                for (uint256 j = 0; j < targets.length; j++) {
                    bytes memory ret;
                    {
                        uint256 gasl = gasleft();
                        // If there isn't enough gas left to run the function, break now to avoid checked math reversion when subtracting 30000 from gas left
                        if (gasl <= 30000) {
                            emit FunctionCallReversion(nonce, i, j, "Wallet: function call ran out of gas.");
                            break;
                        }
                        bool success;
                        (success, ret) = targets[j].call{ value: values[j], gas: gasl - 30000 }(data[j]);
                        if (success) continue;
                    }

                    // If call reverted:
                    emit FunctionCallReversion(nonce, i, j, string(abi.encode(bytes32(ret))));
                }

                require(minEndingGas <= gasleft(), "Gas limit not satisfied.");
            } else {
                // Decode data and check relayer
                address target;
                bytes memory data;
                uint256 value;
                {
                    uint256 chainid;
                    address wallet;
                    uint256 _nonce;
                    bytes4 selector;
                    uint256[4] memory feeData;
                    (chainid, wallet, _nonce, selector, target, data, value, feeData) =
                        abi.decode(signedData[i], (uint256, address, uint256, bytes4, address, bytes, uint256, uint256[4]));
                    require(chainid == block.chainid && wallet == address(this) && _nonce == ++nonce && selector == this.functionCall.selector, "Invalid functionCall signature.");
                    totalPaymasterIncentive += feeData[3];

                    // Gas validation
                    minEndingGas -= feeData[0];
                    require(tx.gasprice <= feeData[1], "maxFeePerGas not satisfied.");
                    require(tx.gasprice - block.basefee <= feeData[2], "maxPriorityFeePerGas not satisfied.");
                }

                // Call contract
                (bool success, bytes memory ret) = target.call{ value: value, gas: gasleft() - 30000 }(data);
                if (!success) emit FunctionCallReversion(nonce, i, 0, string(abi.encode(bytes32(ret))));
                require(minEndingGas <= gasleft(), "Gas limit not satisfied.");
            }
        }

        // Send relayer the gas back
        msg.sender.call{value: ((initialGas - gasleft()) * tx.gasprice) + totalPaymasterIncentive }("");
    }

    /// @notice Modifies the signers on the wallet.
    /// WARNING: Does not validate that all signers have >= threshold votes.
    function modifySigners(address[] calldata signers, SignerConfig[] calldata _signerConfigs, uint8 _threshold) external onlySelf {
        // Input validation
        require(signers.length == _signerConfigs.length, "Lengths of signer and config arrays must match.");
        require(_threshold > 0, "Vote threshold must be greater than 0.");

        // Set variables
        for (uint256 i = 0; i < signers.length; i++) {
            signerConfigs[signers[i]] = _signerConfigs[i];
            emit SignerConfigChanged(signers[i], _signerConfigs[i]);
        }

        threshold = _threshold;
    }
    
    /// @notice Updates a signer on the wallet.
    /// WARNING: Does not validate that all signers have >= threshold votes.
    function modifySigner(address signer, uint8 votes, uint256 signingTimelock) external onlySelf {
        SignerConfig memory signerConfig = SignerConfig(votes, signingTimelock);
        signerConfigs[signer] = signerConfig;
        emit SignerConfigChanged(signer, signerConfig);
    }

    /// @notice Change the relayer whitelist timelock.
    /// Timelock can be enabled at any time.
    /// Off chain relay guardian logic: if changing the timelock from a non-zero value, requires that the user waits for the old timelock to pass (after calling `queueAction`).
    function setRelayerWhitelistTimelock(uint256 _relayerWhitelistTimelock) external onlySelf {
        relayerWhitelistTimelock = _relayerWhitelistTimelock;
        disableRelayerWhitelistQueueTimestamp = 0;
    }

    /// @notice Disable the relayer whitelist by setting the timelock to 0.
    /// Requires that the user waits for the old timelock to pass (after calling `queueAction`).
    function disableRelayerWhitelist(Signature[] calldata signatures) external {
        // Validate signatures
        bytes32 dataHash = keccak256(abi.encode(block.chainid, address(this), ++nonce, this.disableRelayerWhitelist.selector));
        if (msg.sender != address(this)) _validateSignatures(signatures, dataHash, false);

        // Check timelock
        if (relayerWhitelistTimelock > 0) {
            uint256 timestamp = disableRelayerWhitelistQueueTimestamp;
            require(timestamp > 0, "Action not queued.");
            require(timestamp + relayerWhitelistTimelock <= block.timestamp, "Timelock not satisfied.");
        }

        // Disable it
        require(relayerWhitelistTimelock > 0, "Relay whitelist already disabled.");
        relayerWhitelistTimelock = 0;
    }

    /// @notice Queues a timelocked action.
    /// @param signatures Only necessary if calling this function directly (i.e., not through `functionCall`).
    function queueDisableRelayerWhitelist(Signature[] calldata signatures) external {
        // Validate signatures
        bytes32 dataHash = keccak256(abi.encode(block.chainid, address(this), ++nonce, this.queueDisableRelayerWhitelist.selector));
        if (msg.sender != address(this)) _validateSignatures(signatures, dataHash, false);

        // Mark down queue timestamp
        disableRelayerWhitelistQueueTimestamp = block.timestamp;
    }

    /// @notice Unqueues a timelocked action.
    /// @param signatures Only necessary if calling this function directly (i.e., not through `functionCall`).
    function unqueueDisableRelayerWhitelist(Signature[] calldata signatures) external {
        // Validate signatures
        bytes32 dataHash = keccak256(abi.encode(block.chainid, address(this), ++nonce, this.unqueueDisableRelayerWhitelist.selector));
        if (msg.sender != address(this)) _validateSignatures(signatures, dataHash, false);

        // Reset queue timestamp
        disableRelayerWhitelistQueueTimestamp = 0;
    }

    /// @notice Queues a timelocked signature.
    /// No unqueue function because transaction nonces can be overwritten and signers can be removed.
    /// No access control because it's unnecessary and wastes gas.
    function queueSignature(bytes32 signatureHash) external {
        pendingSignatures[signatureHash] = block.timestamp;
    }

    /// @dev Receive ETH.
    receive() external payable { }

    /// @notice Returns the current `Wallet` implementation/logic contract.
    function implementation() external view returns (address) {
        return _implementation();
    }

    /// @notice Perform implementation upgrade.
    /// Emits an {Upgraded} event.
    function upgradeTo(address newImplementation) external onlySelf {
        _upgradeTo(newImplementation);
    }

    /// @notice Perform implementation upgrade with additional setup call.
    /// Emits an {Upgraded} event.
    function upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) external onlySelf {
        _upgradeToAndCall(newImplementation, data, forceCall);
    }

    /// @dev Payment amount enabled/diabled.
    bool public subscriptionPaymentsEnabled;

    /// @dev Payment amount per cycle.
    uint256 public constant SUBSCRIPTION_PAYMENT_AMOUNT = 0.164e18; // Approximately 2 ETH per year

    /// @dev Payment amount cycle interval (in seconds).
    uint256 public constant SUBSCRIPTION_PAYMENT_INTERVAL_SECONDS = 86400 * 30; // 30 days

    /// @dev Last recurring payment timestamp.
    uint256 public lastSubscriptionPaymentTimestamp;

    /// @dev Recurring payments transfer function.
    function subscriptionPayments() external {
        require(subscriptionPaymentsEnabled, "Subscription payments not enabled.");
        uint256 cycles = (block.timestamp - lastSubscriptionPaymentTimestamp) / SUBSCRIPTION_PAYMENT_INTERVAL_SECONDS;
        require(cycles > 0, "No cycles have passed.");
        uint256 amount = SUBSCRIPTION_PAYMENT_AMOUNT * cycles;
        require(address(this).balance > 0, "No ETH to transfer.");
        if (amount > address(this).balance) amount = address(this).balance;
        (bool success, ) = walletFactory.relayGuardianManager().call{value: amount}("");
        require(success, "Failed to transfer ETH.");
        lastSubscriptionPaymentTimestamp = block.timestamp;
    }

    /// @dev Enable/disable recurring payments.
    /// Relay guardian has permission to enable or disable at any time depending on if credit card payments are going through.
    function setSubscriptionPaymentsEnabled(bool enabled, uint256 secondsPaidForAlready) external {
        require(subscriptionPaymentsEnabled != enabled, "Status already set to desired status.");
        address relayGuardian = walletFactory.relayGuardian();
        // Allow relay guardian to enable/disable subscription payments, allow user to enable, or allow user to disable if relayed by guardian
        require(msg.sender == relayGuardian || msg.sender == walletFactory.secondaryRelayGuardian() ||
            (msg.sender == address(this) && (enabled || (relayerWhitelistTimelock > 0 && relayGuardian != address(0)))), "Sender is not relay guardian or user enabling payments.");
        subscriptionPaymentsEnabled = enabled;
        if (enabled) lastSubscriptionPaymentTimestamp = block.timestamp - SUBSCRIPTION_PAYMENT_INTERVAL_SECONDS + secondsPaidForAlready;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Wallet.sol";
import "./Proxy.sol";

import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/ClonesUpgradeable.sol";

/// @title WalletFactory
/// @notice Creates new `Wallet`s.
contract WalletFactory {
    using AddressUpgradeable for address;

    /// @notice The relay guardian.
    /// WARNING: If this variable is set to the zero address, the relay guardian whitelist will NOT be validated on wallets--so do NOT set this variable to the zero address unless you are sure you want to allow anyone to relay transactions.
    /// The relay guardian relays all transactions for a `Wallet`, unless the relay guardian whitelist is deactivated on a `Wallet` or if the relay guardian is set to the zero address here, in which case any address can relay transactions.
    /// The relay guardian can act as off-chain transaction policy node(s) permitting realtime/AI-based fraud detection, symmetric/access-token-based authentication mechanisms, and/or instant onboarding to the Waymont chain.
    /// The relay guardian whitelist can be disabled/enabled via a user-specified timelock on the `Wallet`.
    address public relayGuardian;

    /// @notice The secondary relay guardian.
    /// WARNING: Even if the secondary guardian is set, if the primary guardian is not set, the `Wallet` contract does not validate that the relayer is a whitelisted guardian.
    /// The secondary relay guardian is used as a fallback guardian.
    /// However, it can also double as an authenticated multicall contract to save gas while relaying transactions across multiple wallets in the same blocks.
    /// If using a secondary relay guardian, ideally, it is the less-used of the two guardians to conserve some gas.
    address public secondaryRelayGuardian;

    /// @notice The relay guardian manager.
    address public relayGuardianManager;

    /// @dev `Wallet` implementation/logic contract address.
    address public immutable walletImplementation;

    /// @notice Event emitted when the relay guardian is changed.
    event RelayGuardianChanged(address _relayGuardian);

    /// @notice Event emitted when the secondary relay guardian is changed.
    event SecondaryRelayGuardianChanged(address _relayGuardian);

    /// @notice Event emitted when the relay guardian manager is changed.
    event RelayGuardianManagerChanged(address _relayGuardianManager);

    /// @dev Constructor to initialize the factory by setting the relay guardian manager and creating and setting a new `Wallet` implementation.
    constructor(address _relayGuardianManager) {
        relayGuardianManager = _relayGuardianManager;
        emit RelayGuardianManagerChanged(_relayGuardianManager);
        walletImplementation = address(new Wallet());
    }

    /// @notice Deploys an upgradeable (or non-upgradeable) proxy over `Wallet`.
    /// WARNING: Does not validate that signers have >= threshold votes.
    /// Only callable by the relay guardian so nonces used on other chains can be kept unused on this chain until the same user deploys to this chain.
    /// @param nonce The unique nonce of the wallet to create. If the contract address of the `WalletFactory` and the `Wallet` implementation is the same across each chain (which it will be if the same private key deploys them with the same nonces), then the contract addresses of the wallets created will also be the same across all chains.
    /// @param signers Signers can be password-derived keys generated using bcrypt.
    /// @param signerConfigs Controls votes per signer as well as signing timelocks.
    /// @param threshold Threshold of votes required to sign transactions.
    /// @param relayerWhitelistTimelock Applies to disabling the relayer whitelist. If set to zero, the relayer whitelist is disabled.
    /// @param subscriptionPaymentsEnabled Whether or not automatic subscription payments are enabled (disabled if credit card payments are enabled off-chain).
    /// @param upgradeable Whether or not the contract is upgradeable (costs less gas to deploy and use if not).
    function createWallet(
        uint256 nonce,
        address[] calldata signers,
        Wallet.SignerConfig[] calldata signerConfigs,
        uint8 threshold,
        uint256 relayerWhitelistTimelock,
        bool subscriptionPaymentsEnabled,
        bool upgradeable
    ) external returns (Wallet) {
        require(msg.sender == relayGuardian || msg.sender == secondaryRelayGuardian, "Sender is not the relay guardian.");
        Wallet instance = Wallet(upgradeable ? payable(new Proxy{salt: bytes32(nonce)}(walletImplementation)) : payable(ClonesUpgradeable.cloneDeterministic(walletImplementation, bytes32(nonce))));
        instance.initialize(signers, signerConfigs, threshold, relayerWhitelistTimelock, subscriptionPaymentsEnabled);
        return instance;
    }

    /// @dev Access control for the relay guardian manager.
    modifier onlyRelayGuardianManager() {
        require(msg.sender == relayGuardianManager, "Sender is not the relay guardian manager.");
        _;
    }

    /// @notice Sets the relay guardian.
    /// WARNING: If this variable is set to the zero address, the relay guardian whitelist will NOT be validated on wallets--so do NOT set this variable to the zero address unless you are sure you want to allow anyone to relay transactions.
    function setRelayGuardian(address _relayGuardian) external onlyRelayGuardianManager {
        relayGuardian = _relayGuardian;
        emit RelayGuardianChanged(_relayGuardian);
    }

    /// @notice Sets the secondary relay guardian.
    /// WARNING: Even if the secondary guardian is set, if the primary guardian is not set, the `Wallet` contract does not validate that the relayer is a whitelisted guardian.
    function setSecondaryRelayGuardian(address _relayGuardian) external onlyRelayGuardianManager {
        secondaryRelayGuardian = _relayGuardian;
        emit SecondaryRelayGuardianChanged(_relayGuardian);
    }

    /// @notice Sets the relay guardian manager.
    function setRelayGuardianManager(address _relayGuardianManager) external onlyRelayGuardianManager {
        relayGuardianManager = _relayGuardianManager;
        emit RelayGuardianManagerChanged(_relayGuardianManager);
    }

    /// @dev Validates that `sender` is a valid relay guardian.
    function checkRelayGuardian(address sender) external view {
        address _relayGuardian = relayGuardian;
        require(sender == _relayGuardian || sender == secondaryRelayGuardian || _relayGuardian == address(0), "Sender is not relay guardian.");
    }
}