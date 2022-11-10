/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

/**

 __          __                                          _                           _   _     _               _                      _               _
 \ \        / /                                         (_)                         | | | |   (_)             | |                    | |             | |
  \ \  /\  / /__    __ _ _ __ ___   _ __  _ __ _____   ___ _ __   __ _   _ __   ___ | |_| |__  _ _ __   __ _  | |_ ___    _ __   ___ | |__   ___   __| |_   _
   \ \/  \/ / _ \  / _` | '__/ _ \ | '_ \| '__/ _ \ \ / / | '_ \ / _` | | '_ \ / _ \| __| '_ \| | '_ \ / _` | | __/ _ \  | '_ \ / _ \| '_ \ / _ \ / _` | | | |
    \  /\  /  __/ | (_| | | |  __/ | |_) | | | (_) \ V /| | | | | (_| | | | | | (_) | |_| | | | | | | | (_| | | || (_) | | | | | (_) | |_) | (_) | (_| | |_| |
     \/  \/ \___|  \__,_|_|  \___| | .__/|_|  \___/ \_/ |_|_| |_|\__, | |_| |_|\___/ \__|_| |_|_|_| |_|\__, |  \__\___/  |_| |_|\___/|_.__/ \___/ \__,_|\__, |
                                   | |                            __/ |                                 __/ |                                            __/ |
                                   |_|                           |___/                                 |___/                                            |___/

*/




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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
    external
    returns (uint[] memory amounts);
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}


contract ProofOfNothing is Context, IERC20, Ownable
{


    // Info? are you sure?
    string private constant Name = "Proof Of Nothing";
    string private constant Symbol = "PON";
    uint8 private constant Decimals = 18;
    uint256 private TotalSupply = 100_000_000 * 10**Decimals;
    uint256 private constant MAX = ~uint256(0);
    uint256 private ReflactionaryTotal = (MAX - (MAX % TotalSupply));

    // Routing to nowhere
    IUniswapV2Router02 public UniswapV2Router;
    address public PancakeSwapAddress;

    // Snipers are not welcomed
    uint256 public liqAddedBlockNumber;
    uint256 public blocksToWait = 0;

    // Important addresses
    address payable private DevAddress = payable(0xd660145C3092100d9dd83ECe6c0449d992c8Df6E);
    address payable private MarketingAddress = payable(0xe175D48089df657C392bCF50Acf32E8CaE62Cbd7);
    address payable private BurnAddress = payable(0x000000000000000000000000000000000000dEaD);

    uint256 private HardCap = TotalSupply / 33;
    uint256 private HardCapBuy = HardCap;
    uint256 private HardCapSell = HardCap;

    mapping (address => uint256) private BalancesRefraccionarios;
    mapping (address => uint256) private BalancesReales;
    mapping (address => mapping (address => uint256)) private Allowances;
    mapping (address => bool) private Bots;


    mapping (address => bool) private WalletsExcludedFromFee;
    mapping (address => bool) private WalletsExcludedFromHardCap;
    mapping (address => bool) public AutomatedMarketMakerPairs;

    // Some cool statistics
    uint256 public TotalFee;
    uint256 public TotalSwapped;
    uint256 private TotalTokenBurn;

    // Swap for... nothing...
    bool private InSwap = false;
    bool private SwapEnabled = false;


    // Cool trick to control swap
    modifier swaping {
        InSwap = true;
        _;
        InSwap = false;
    }

    // Distribution based on taxes collected.
    uint256 private MarketingDistributionPct = 50;
    uint256 private DevDistributionPct = 25;
    uint256 private LPDistributionPct = 25;

    uint256 private LiquidityThreshold = 1 * 10 ** Decimals;

    // Tax rates
    struct TaxRates
    {
        uint256 BurnTax;
        uint256 LiquidityTax;
        uint256 MarketingTax;
        uint256 DevelopmentTax;
        uint256 RewardTax;
        string TaxPresetName;
    }

    // Fees, which are amounts calculated based on tax
    struct TransactionFees
    {
        uint256 TransactionFee;
        uint256 BurnFee;
        uint256 DevFee;
        uint256 MarketingFee;
        uint256 LiquidityFee;
        uint256 TransferrableFee;
        uint256 TotalFee;
    }

    TaxRates public BuyingTaxes =
    TaxRates({
    RewardTax: 0,
    BurnTax: 0,
    DevelopmentTax: 33,
    MarketingTax: 33,
    LiquidityTax: 33,
    TaxPresetName: "Buying"
    });

    TaxRates public SellTaxes =
    TaxRates({
    RewardTax: 0,
    BurnTax: 0,
    DevelopmentTax: 33,
    MarketingTax: 33,
    LiquidityTax: 33,
    TaxPresetName: "Selling"
    });

    TaxRates public AppliedRatesPercentage = BuyingTaxes;


    TransactionFees private AccumulatedFeeForDistribution = TransactionFees({
    DevFee: 0,
    MarketingFee: 0,
    LiquidityFee: 0,
    BurnFee:0,
    TransferrableFee: 0,
    TotalFee: 0,
    TransactionFee: 0
    });


    // Events
    event setDevAddress(address indexed previous, address indexed adr);
    event setMktAddress(address indexed previous, address indexed adr);
    event LiquidityAdded(uint256 tokenAmount, uint256 ETHAmount);
    event TreasuryAndDevFeesAdded(uint256 devFee, uint256 treasuryFee);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event BlacklistedUser(address botAddress, bool indexed value);
    event MaxWalletAmountUpdated(uint256 amount);
    event ExcludeFromMaxWallet(address account, bool indexed isExcluded);
    event SwapAndLiquifyEnabledUpdated(bool _enabled);


    constructor(address swap)
    {
        // Discovering Uniswap, where is the unicorn??
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(swap);
        UniswapV2Router = _uniswapV2Router;

        PancakeSwapAddress = IUniswapV2Factory(UniswapV2Router.factory()).createPair(address(this), UniswapV2Router.WETH());

        AutomatedMarketMakerPairs[PancakeSwapAddress] = true;

        // Some nifty configs

        WalletsExcludedFromFee[owner()] = true;
        WalletsExcludedFromFee[address(this)] = true;
        WalletsExcludedFromFee[DevAddress] = true;
        WalletsExcludedFromFee[MarketingAddress] = true;
        WalletsExcludedFromFee[swap] = true;


        WalletsExcludedFromHardCap[owner()] = true;
        WalletsExcludedFromHardCap[address(this)] = true;
        WalletsExcludedFromHardCap[DevAddress] = true;
        WalletsExcludedFromHardCap[MarketingAddress] = true;
        WalletsExcludedFromHardCap[PancakeSwapAddress] = true;
        WalletsExcludedFromHardCap[swap] = true;

        BalancesRefraccionarios[_msgSender()] = ReflactionaryTotal;

        // Approving swap for LP
        _approve(address(this), address(UniswapV2Router), ~uint256(0));

        // Notifying the initial mint
        emit Transfer(address(0x0000000000000000000000000000000000000000), _msgSender(), TotalSupply);
    }

    function ChangeTaxes(uint256 rewardTax, uint256 mktTax, uint256 devTax, uint256 lpTax, bool buying) public onlyOwner
    {
        if(buying)
        {
            BuyingTaxes.RewardTax = rewardTax;
            BuyingTaxes.MarketingTax = mktTax;
            BuyingTaxes.DevelopmentTax = devTax;
            BuyingTaxes.LiquidityTax = lpTax;
        }
        else
        {
            SellTaxes.RewardTax = rewardTax;
            SellTaxes.MarketingTax = mktTax;
            SellTaxes.DevelopmentTax = devTax;
            SellTaxes.LiquidityTax = lpTax;
        }
    }


    function AdjustMaxHardCap(uint256 newHardCap) public onlyOwner
    {
        HardCap = newHardCap;
    }

    function AdjustMaxTxSell(uint256 maxTxSell) public onlyOwner
    {
        HardCapSell = maxTxSell;
    }

    function AdjustMaxTxBuy(uint256 mxTxBuy) public onlyOwner
    {
        HardCapBuy = mxTxBuy;
    }

    function swapTokensForETH(uint256 tokenAmount) private
    {
        // generate the pair path of token
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2Router.WETH();

        // make the swap
        UniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function SwapPct(uint256 pct) public
    {
        uint256 balance = (balanceOf(address(this)) * pct) / 100;

        if(balance > 0)
        {
            uint256 tokensForLP = (balance * LPDistributionPct)/100;
            uint256 tokensForLiquidity = tokensForLP / 2;
            uint256 tokensToSwap = balance - tokensForLiquidity;

            swapTokensForETH(tokensToSwap);
            uint256 contractBalance = address(this).balance;

            uint256 devShare = (contractBalance * DevDistributionPct)/100;
            uint256 mktShare = (contractBalance * MarketingDistributionPct)/100;

            DevAddress.transfer(devShare);
            MarketingAddress.transfer(mktShare);

            uint256 eth = address(this).balance;

            UniswapV2Router.addLiquidityETH{value: address(this).balance}(
                address(this),
                tokensForLiquidity,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                DevAddress,
                block.timestamp
            );


            AccumulatedFeeForDistribution.LiquidityFee = 0;
            AccumulatedFeeForDistribution.DevFee = 0;
            AccumulatedFeeForDistribution.MarketingFee = 0;

            TotalSwapped += tokensForLiquidity;

            emit LiquidityAdded(tokensForLiquidity, eth);
        }
    }

    // Funciones para cambiar las wallets de los VIP
    function ChangeExcludeFromFeeToForWallet(address add, bool isExcluded) public onlyOwner
    {
        WalletsExcludedFromFee[add] = isExcluded;
    }

    function IsWalletExcludedFromFee(address targetAddress) public view returns(bool)
    {
        return WalletsExcludedFromFee[targetAddress];
    }

    function ChangeDevAddress(address payable newDevAddress) public onlyOwner
    {
        address oldAddress = DevAddress;
        emit setDevAddress(oldAddress, newDevAddress);
        ChangeExcludeFromFeeToForWallet(DevAddress, false); // Excluyendo la wallet antigua, que se joda ese cabron
        DevAddress = newDevAddress;
        ChangeExcludeFromFeeToForWallet(DevAddress, true);  // Incluyendo a la nueva
    }

    function ChangeMarketingAddress(address payable marketingAddress) public onlyOwner
    {
        address oldAddress = MarketingAddress;
        emit setMktAddress(oldAddress, marketingAddress);
        ChangeExcludeFromFeeToForWallet(MarketingAddress, false); // Excluyendo la wallet antigua, que se joda ese cabron
        MarketingAddress = marketingAddress;
        ChangeExcludeFromFeeToForWallet(MarketingAddress, true);  // Incluyendo a la nueva
    }


    function totalSupply() public view override returns (uint256)
    {
        return TotalSupply;
    }

    function decimals() public pure returns (uint8)
    {
        return Decimals;
    }

    function symbol() public pure returns (string memory)
    {
        return Symbol;
    }


    function name() public pure returns (string memory)
    {
        return Name;
    }

    function getOwner() external view returns (address)
    {
        return owner();
    }


    function totalBurn() public view returns (uint256)
    {
        return TotalTokenBurn;
    }

    function balanceOf(address account) public view override returns (uint256)
    {
        return tokenFromReflection(BalancesRefraccionarios[account]);
    }

    function allowance(address owner, address spender) public view override returns (uint256)
    {
        return Allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool)
    {
        uint256 currentAllowance = allowance(sender,_msgSender());
        require(currentAllowance >= amount, "BEP20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);

    unchecked
    {
        _approve(sender, _msgSender(), currentAllowance - amount);
    }

        return true;
    }

    // Funciones para modificar  las lista de wallets
    // Funcion para banear a una wallet de usar el contrato (a.k.a decir que es un bot/apestao)
    // Esto lo tiene 100million
    function MarkBot(address targetAddress, bool isBot) public onlyOwner
    {
        Bots[targetAddress] = isBot;
        emit BlacklistedUser(targetAddress, isBot);
    }

    function IsBot(address targetAddress) public view returns(bool)
    {
        return Bots[targetAddress];
    }

    function ChangeExclusionFromHardCap(address targetAddress, bool isExcluded) public onlyOwner
    {
        WalletsExcludedFromHardCap[targetAddress] = isExcluded;
        emit ExcludeFromMaxWallet(targetAddress, isExcluded);
    }

    function IsExcludedFromHardCap(address targetAddress) public view returns(bool)
    {
        return WalletsExcludedFromHardCap[targetAddress];
    }

    // Funcion para setear una address para que pueda hacer tradeo automatico
    function setAutomatedMarketMakerPair(address _pair, bool value) external onlyOwner
    {
        require( AutomatedMarketMakerPairs[_pair] != value,"Automated market maker pair is already set to that value");
        AutomatedMarketMakerPairs[_pair] = value;
        ChangeExclusionFromHardCap(_pair, value);
        emit SetAutomatedMarketMakerPair(_pair, value);
    }

    // Funciones para manipular el allowance
    function _approve(address owner, address spender, uint256 amount) private
    {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        Allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool)
    {
        _approve(_msgSender(), spender, Allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool)
    {
        uint256 currentAllowance = Allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked
    {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
    }

        return true;
    }


    // Funciones de transferencia
    function _transfer(address from, address to, uint256 amount) private
    {
        if (liqAddedBlockNumber == 0 && AutomatedMarketMakerPairs[to])
        {
            liqAddedBlockNumber = block.number;
        }

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!IsBot(from), "ERC20: address blacklisted (bot)");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from), "You are trying to transfer more than your balance");

        bool takeFee =  !(IsWalletExcludedFromFee(from) || IsWalletExcludedFromFee(to));

        if (takeFee)
        {
            // Hello stranger, what are you buying?
            if (AutomatedMarketMakerPairs[from])
            {
                // Not so fast ma boi
                if (block.number < liqAddedBlockNumber + blocksToWait)
                {
                    MarkBot(to, true);
                }

                // Si, el origen es el address de la transaccion, estamos sacando tokens del pool. Aplicamos el hard cap de compra
                AppliedRatesPercentage = BuyingTaxes;
                require(amount <= HardCapBuy, "amount must be <= maxTxAmountBuy" );
            }
            // What are you sellin'?
            else
            {
                // Si, la transferencia la inicia un address que no es de trading, aplicamos rates de venta (o transferencia entre peers)
                AppliedRatesPercentage = SellTaxes;
                require(amount <= HardCapSell,"amount must be <= maxTxAmountSell");
            }
        }

        // Repartir lo que ya hay si no estamos interactuando con el pair
        if (
            !InSwap &&
            !AutomatedMarketMakerPairs[from] &&
            SwapEnabled &&
            from != owner() && 
            to != owner() &&
            from != address(UniswapV2Router)
        ) {
            //add liquidity
            swapAndLiquify();
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    // This method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 cantidadBruta, bool takeFee) private
    {

        (uint256 cantidadNeta,
        uint256 cantidadBrutaRefracionaria,
        uint256 cantidadNetaRefracionaria,
        TransactionFees memory feesReales,
        TransactionFees memory feesRefracionarios) = GenerarFeesYCantidadesATransferir(cantidadBruta, takeFee);

        // Comprobando que el receptor de la transferencia no supere el hard cap de tokens
        require(WalletsExcludedFromHardCap[recipient] ||
            (balanceOf(recipient) + cantidadNeta) <= HardCap,
            "Recipient cannot hold more than maxWalletAmount");

        // Se siguen actualizando los valore reflaccionarios en caso de que las wallets
        // sean reincluidas en las recompensas de nuevo
        BalancesRefraccionarios[sender] -= cantidadBrutaRefracionaria;
        BalancesRefraccionarios[recipient] += cantidadNetaRefracionaria;

        if (takeFee)
        {

            ReflactionaryTotal -= feesRefracionarios.TransactionFee;
            TotalFee += feesReales.TransactionFee;

            AccumulateFee(feesReales, feesRefracionarios);
            // Quemando tokens
            TotalTokenBurn += feesReales.BurnFee;
            BalancesRefraccionarios[BurnAddress] += feesRefracionarios.BurnFee;

            // Emitiendo enventos para reflejar las acciones realizadas
            emit Transfer(address(this), BurnAddress, feesReales.BurnFee);
            emit Transfer(sender, address(this), feesReales.TransferrableFee);
        }
       
        emit Transfer(sender, recipient, cantidadNeta);
    }

    function GenerarFeesYCantidadesATransferir(uint256 cantidadBruta, bool aplicarImpuestos) private view returns(
        uint256 cantidadNeta,
        uint256 cantidadBrutaRefracionaria,
        uint256 cantidadNetaRefracionaria,
        TransactionFees memory feesReales,
        TransactionFees memory feesRefracionarios)
    {
        (feesReales, feesRefracionarios) = CalcularTasasRealesYRefracionarias(cantidadBruta, aplicarImpuestos);
        cantidadNeta = cantidadBruta - feesReales.TotalFee;
        cantidadBrutaRefracionaria =  cantidadBruta * GetConversionRate();
        cantidadNetaRefracionaria = cantidadBrutaRefracionaria - feesRefracionarios.TotalFee;
    }


    function CalcularTasasRealesYRefracionarias(uint256 cantidadBruta, bool takeFee) private view returns (TransactionFees memory realFees, TransactionFees memory refractionaryFees)
    {
        if (takeFee)
        {
            uint256 currentRate = GetConversionRate();

            // Caluclando las tasas
            realFees.TransactionFee = (cantidadBruta * AppliedRatesPercentage.RewardTax) / 100;
            realFees.BurnFee =  (cantidadBruta * AppliedRatesPercentage.BurnTax) / 100;
            realFees.DevFee =  (cantidadBruta * AppliedRatesPercentage.DevelopmentTax) / 100;
            realFees.MarketingFee =  (cantidadBruta * AppliedRatesPercentage.MarketingTax) / 100;
            realFees.LiquidityFee =  (cantidadBruta * AppliedRatesPercentage.LiquidityTax) / 100;

            // Sumando las tasas y agrupando entre las que se van al contrato y las que no
            realFees.TransferrableFee = realFees.DevFee + realFees.MarketingFee + realFees.LiquidityFee;
            realFees.TotalFee = realFees.TransactionFee + realFees.BurnFee + realFees.TransferrableFee;

            refractionaryFees.TransactionFee = realFees.TransactionFee * currentRate;
            refractionaryFees.BurnFee =  realFees.BurnFee * currentRate;
            refractionaryFees.DevFee =   realFees.DevFee * currentRate;
            refractionaryFees.MarketingFee = realFees.MarketingFee * currentRate;
            refractionaryFees.LiquidityFee = realFees.LiquidityFee * currentRate;

            refractionaryFees.TotalFee = realFees.TotalFee * currentRate;
            refractionaryFees.TransferrableFee = realFees.TransferrableFee * currentRate;
        }
    }

    function AccumulateFee(TransactionFees memory realFees, TransactionFees memory refractionaryFees) private
    {
        BalancesRefraccionarios[address(this)] += refractionaryFees.TransferrableFee;

        AccumulatedFeeForDistribution.LiquidityFee += realFees.LiquidityFee;

        AccumulatedFeeForDistribution.DevFee += realFees.DevFee;

        AccumulatedFeeForDistribution.MarketingFee += realFees.MarketingFee;

    }



    function swapAndLiquify() private swaping
    {
        // Swapping the rest of the fees
        if(balanceOf(address(this)) > 0)
        {
            uint256 tokensToSwap = AccumulatedFeeForDistribution.LiquidityFee / 2;
            uint256 tokensForLiquidity = AccumulatedFeeForDistribution.LiquidityFee - tokensToSwap;

            swapTokensForETH(AccumulatedFeeForDistribution.DevFee + AccumulatedFeeForDistribution.MarketingFee + tokensToSwap);

            uint256 contractBalance = address(this).balance;
            uint256 devShare = (contractBalance* DevDistributionPct)/100;
            uint256 mktShare = (contractBalance * MarketingDistributionPct)/100;

            DevAddress.transfer(devShare);
            MarketingAddress.transfer(mktShare);

            uint256 eth = address(this).balance;

            UniswapV2Router.addLiquidityETH{value: address(this).balance}(
                address(this),
                tokensForLiquidity,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                DevAddress,
                block.timestamp
            );

            AccumulatedFeeForDistribution.LiquidityFee = 0;
            AccumulatedFeeForDistribution.DevFee = 0;
            AccumulatedFeeForDistribution.MarketingFee = 0;

            TotalSwapped += tokensForLiquidity;


            emit LiquidityAdded(tokensForLiquidity, eth);
        }
    }

    function tokenFromReflection(uint256 reflactionaryAmount) public view returns (uint256)
    {
        require(reflactionaryAmount <= ReflactionaryTotal,"Amount must be less than total reflections");
        return reflactionaryAmount / GetConversionRate();
    }

    function GetConversionRate() private view returns (uint256)
    {
        return ReflactionaryTotal / totalSupply();
    }

    // Funciones para modificar cositas del swap
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner
    {
        SwapEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }


    // Esto es para poder recibir cosas de pancake swap
    receive() external payable {}

}