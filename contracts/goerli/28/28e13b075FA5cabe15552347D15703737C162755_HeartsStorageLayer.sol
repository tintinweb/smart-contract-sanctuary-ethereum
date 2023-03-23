// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";
import {CANONICAL_CORI_SUBSCRIPTION} from "./lib/Constants.sol";
/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 * @dev    Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract DefaultOperatorFilterer is OperatorFilterer {
    /// @dev The constructor that is called when the contract is being deployed.
    constructor() OperatorFilterer(CANONICAL_CORI_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";
import {CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS} from "./lib/Constants.sol";
/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *         Please note that if your token contract does not provide an owner with EIP-173, it must provide
 *         administration methods on the contract itself to interact with the registry otherwise the subscription
 *         will be locked to the options set during construction.
 */

abstract contract OperatorFilterer {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS);

    /// @dev The constructor that is called when the contract is being deployed.
    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

address constant CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS = 0x000000000000AAeB6D7670E522A718067333cd4E;
address constant CANONICAL_CORI_SUBSCRIPTION = 0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6;

// SPDX-License-Identifier: MIT
/**
 * Creator: Virtue Labs
 * Authors:
 *** Code: 0xYeety, CTO - Virtue labs
 *** Concept: Church, CEO - Virtue Labs
**/

pragma solidity ^0.8.17;

//enum HeartColor {
//    Red,
//    Blue,
//    Green,
//    Yellow,
//    Orange,
//    Purple,
//    Black,
//    White,
//    Length
//}

import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";

using Strings for uint256;

type HeartColor is uint24;

function packHeartColor(uint8 r, uint8 g, uint8 b) pure returns (HeartColor) {
    return HeartColor.wrap((uint24(r)<<16) + (uint24(g)<<8) + uint24(b));
}

function heartColorOfUint256(uint256 i) pure returns (HeartColor) {
    return HeartColor.wrap(uint24(i%(1<<24)));
}

function safeHeartColorOfUint256(uint256 i) pure returns (HeartColor) {
    require(i < (1<<24), "bad hcNum");
    return HeartColor.wrap(uint24(i%(1<<24)));
}

function unpackHeartColor(HeartColor color) pure returns (uint8 r, uint8 g, uint8 b) {
    uint24 colorInt = HeartColor.unwrap(color);

    r = uint8(colorInt>>16);
    g = uint8((colorInt>>8)%256);
    b = uint8(colorInt%256);
}

function colorToString(HeartColor color) pure returns (string memory) {
//    (uint8 r, uint8 g, uint8 b) = unpackHeartColor(color);
//
//    return abi.encodePacked();

    return uint256(HeartColor.unwrap(color)).toHexString(6);
}

function baseHeartColor(uint256 i) pure returns (HeartColor) {
    uint24 toReturn;

    if (i == 0) {
        toReturn = 0xDD2E44;
    }
    else if (i == 1) {
        toReturn = 0x5CADED;
    }
    else if (i == 2) {
        toReturn = 0x77B05A;
    }
    else if (i == 3) {
        toReturn = 0xFCCB58;
    }
    else if (i == 4) {
        toReturn = 0xF2900D;
    }
    else if (i == 5) {
        toReturn = 0xA98FD5;
    }
    else if (i == 6) {
        toReturn = 0x31383C;
    }
    else if (i == 7) {
        toReturn = 0xE6E7E8;
    }
    else {
        revert("bad hcIndex");
    }

    return HeartColor.wrap(toReturn);
}

function heartColorToBase(HeartColor color) pure returns (uint8 toReturn) {
    uint24 colorNum = HeartColor.unwrap(color);

    if (colorNum == 0xDD2E44) {
        toReturn = 0;
    }
    else if (colorNum == 0x5CADED) {
        toReturn = 1;
    }
    else if (colorNum == 0x77B05A) {
        toReturn = 2;
    }
    else if (colorNum == 0xFCCB58) {
        toReturn = 3;
    }
    else if (colorNum == 0xF2900D) {
        toReturn = 4;
    }
    else if (colorNum == 0xA98FD5) {
        toReturn = 5;
    }
    else if (colorNum == 0x31383C) {
        toReturn = 6;
    }
    else if (colorNum == 0xE6E7E8) {
        toReturn = 7;
    }
    else {
        revert("bad color for base");
    }
}

function isBaseHeartColor(HeartColor color) pure returns (bool) {
    uint24 colorNum = HeartColor.unwrap(color);

    return (
        colorNum == 0xDD2E44 || colorNum == 0x5CADED ||
        colorNum == 0x77B05A || colorNum == 0xFCCB58 ||
        colorNum == 0xF2900D || colorNum == 0xA98FD5 ||
        colorNum == 0x31383C || colorNum == 0xE6E7E8
    );
}

function equal(HeartColor color1, HeartColor color2) pure returns (bool) {
    return (HeartColor.unwrap(color1) == HeartColor.unwrap(color2));
}

/**************************************/

// SPDX-License-Identifier: MIT
/**
 * Creator: Virtue Labs
 * Authors:
 *** Code: 0xYeety, CTO - Virtue labs
 *** Concept: Church, CEO - Virtue Labs
**/

pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/operator-filter-registry/src/DefaultOperatorFilterer.sol";
import "./HeartColors.sol";
import "./StorageTypes.sol";

contract HeartsStorageLayer is Ownable, DefaultOperatorFilterer {
    using Address for address;

    error TransferError(bool approvedOrOwner, bool fromPrevOwnership);

    uint256 public _nextToMint = 0;
    uint256 private _lineageNonce = 0;

    mapping(uint256 => string) private _bases;

//    struct TokenInfo {
//        uint256 genome;
//        address owner;
//        uint64 lastShifted;
//        HeartColor color;
////        uint24 padding;
//        uint8 padding;
//        address parent;
//        uint48 numChildren;
//        uint48 lineageDepth;
//    }

//    struct AddressInfo {
//        uint128 inactiveBalance;
//        uint128 activeBalance;
//    }

    mapping(uint256 => TokenInfo) private _tokenData;
//    mapping(address => AddressInfo) private _balances;
    mapping(address => mapping(address => uint256)) private _balances;
    mapping(address => uint256) private _totalBalances;
    mapping(address => mapping(uint256 => uint256)) private _ownershipOrderings;
    mapping(uint256 => uint256) private _orderPositions;

    mapping(uint256 => address) private _tokenApprovals;
//    mapping(address => mapping(address => uint256)) private _operatorApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(uint256 => uint256) private _activations;
    mapping(uint256 => uint256) private _burns;

    /** Top-level contracts + versioning **/
    address public inactiveContract;
    address public activeContract;

    mapping(address => VersionInfo) public _inactiveVersionData;
    mapping(address => VersionInfo) public _activeVersionData;
    mapping(uint8 => address) public _inactiveVersionRevMap;
    mapping(uint8 => address) public _activeVersionRevMap;

    uint8 public nextInactiveVersionIndex;
    uint8 public nextActiveVersionIndex;
    /**************************************/

    address public lbrContract;
    address public successorContract;

    modifier onlyHearts() {
        require(
            _inactiveVersionData[msg.sender].isVersion ||
            _activeVersionData[msg.sender].isVersion,
            "nh"
        );
        _;
    }

    modifier onlyInactive() {
        require(_inactiveVersionData[msg.sender].isVersion, "ni");
        _;
    }

    modifier onlyActive() {
        require(isActiveContract(msg.sender), "na");
        _;
    }

    function isActiveContract(address contractAddress) internal view virtual returns (bool) {
        return _activeVersionData[contractAddress].isVersion;
    }

    modifier onlyLatest() {
        require(msg.sender == inactiveContract || msg.sender == activeContract, "nh");
        _;
    }

    modifier onlySuccessor() {
        require(msg.sender == successorContract, "na");
        _;
    }

//    uint256 private _activeSupply;
//    uint256 private _burnedSupply;

    /******************/

    bool public royaltySwitch = true;

    modifier storage_onlyAllowedOperator(address from, address msgSender) virtual {
        if (royaltySwitch) {
            if (from != msgSender) {
                _checkFilterOperator(msgSender);
            }
        }
        _;
    }

    modifier storage_onlyAllowedOperatorApproval(address operator) virtual {
        if (royaltySwitch) {
            _checkFilterOperator(operator);
        }
        _;
    }

    function flipRoyaltySwitch() public onlyOwner {
        royaltySwitch = !royaltySwitch;
    }

    constructor() {
        _bases[0] = "A";
        _bases[1] = "C";
        _bases[2] = "G";
        _bases[3] = "T";
    }

    function storage_balanceOf(
//        bool active,
        address contractAddress,
        address owner
    ) public view returns (uint256) {
        require(owner != address(0), "0");
//        return (active ? _balances[owner].activeBalance : _balances[owner].inactiveBalance);
        // TODO: Think about whether to put any conditionals here and re-enable "bool active"
        return _balances[owner][contractAddress];
    }

    function storage_latestBalanceOf(bool active, address owner) public view returns (uint256) {
        return _balances[owner][active ? activeContract : inactiveContract];
    }

    function _totalBalance(address owner) private view returns (uint256) {
//        return _balances[owner].activeBalance + _balances[owner].inactiveBalance;
        return _totalBalances[owner];
    }

    function storage_ownerOf(
        bool active,
        address contractAddress,
        uint256 tokenId
    ) public view returns (address) {
        require(_exists(active, contractAddress, tokenId), "e");
//        require(
//            active ?
//                _activeVersionData[contractAddress].isVersion :
//                _inactiveVersionData[contractAddress].isVersion,
//            "e"
//        );
        return _tokenData[tokenId].owner;
    }

    function storage_colorOf(bool active, address contractAddress, uint256 tokenId) public view returns (HeartColor) {
        require(_exists(active, contractAddress, tokenId), "e");
        return _tokenData[tokenId].color;
    }

    function storage_parentOf(bool active, address contractAddress, uint256 tokenId) public view returns (address) {
        require(_exists(active, contractAddress, tokenId), "e");
        return _tokenData[tokenId].parent;
    }

    function storage_lineageDepthOf(bool active, address contractAddress, uint256 tokenId) public view returns (uint256) {
        require(_exists(active, contractAddress, tokenId), "e");
        return uint256(_tokenData[tokenId].lineageDepth);
    }

    function storage_numChildrenOf(bool active, address contractAddress, uint256 tokenId) public view returns (uint256) {
        require(_exists(active, contractAddress, tokenId), "e");
        return uint256(_tokenData[tokenId].numChildren);
    }

    function storage_rawGenomeOf(bool active, address contractAddress, uint256 tokenId) public view returns (uint256) {
        require(_exists(active, contractAddress, tokenId), "e");
        return _tokenData[tokenId].genome;
    }

    function storage_genomeOf(bool active, address contractAddress, uint256 tokenId) public view returns (string memory) {
        require(_exists(active, contractAddress, tokenId), "e");
        uint256 rawGenome = storage_rawGenomeOf(active, contractAddress, tokenId);
        string memory toReturn = "";
        for (uint256 i = 0; i < 128; i++) {
            toReturn = string(abi.encodePacked(toReturn, _bases[(rawGenome>>(i*2))%4]));
        }
        return toReturn;
    }

    function storage_lastShifted(bool active, address contractAddress, uint256 tokenId) public view returns (uint64) {
        require(_exists(active, contractAddress, tokenId), "e");
        return _tokenData[tokenId].lastShifted;
    }

    function storage_batchLastShifted(
        bool active,
        address contractAddress,
        uint256[] calldata tokenIds
    ) public view returns (uint64[] memory) {
        bool allExist = true;
        uint64[] memory toReturn = new uint64[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            allExist = (allExist && _exists(active, contractAddress, tokenId));
            toReturn[i] = _tokenData[tokenId].lastShifted;
        }
        require(allExist, "e_batch");
        return toReturn;
    }

    function storage_fullStorageOf(
        bool active,
        address contractAddress,
        uint256 tokenId
    ) public view returns (TokenInfo memory) {
        require(_exists(active, contractAddress, tokenId), "e");
        return _tokenData[tokenId];
    }

    function storage_transferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public onlyHearts storage_onlyAllowedOperator(from, msgSender) {
//        _transfer(msgSender, msg.sender == activeContract, from, to, tokenId);
        _transfer(msgSender, from, to, tokenId);
    }

    function storage_safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public onlyHearts storage_onlyAllowedOperator(from, msgSender) {
        storage_transferFrom(msgSender, from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "z");
    }

    function storage_safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public onlyHearts storage_onlyAllowedOperator(from, msgSender) {
        storage_safeTransferFrom(msgSender, from, to, tokenId, "");
    }

    function storage_approve(
        address msgSender,
        address to,
        uint256 tokenId
    ) public onlyHearts storage_onlyAllowedOperatorApproval(to) {
        address owner = storage_ownerOf(msg.sender == activeContract, msg.sender, tokenId);
        require(
            msgSender == owner ||
//            msgSender == storage_getApproved(msg.sender == activeContract, tokenId) ||
            msgSender == storage_getApproved(tokenId) ||
//            storage_isApprovedForAll(msg.sender == activeContract, owner, msgSender),
            storage_isApprovedForAll(owner, msgSender),
                "a");
        _approve(to, tokenId, owner);
    }

//    function storage_getApproved(bool active, uint256 tokenId) public view returns (address) {
    function storage_getApproved(uint256 tokenId) public view returns (address) {
//        if (active != _isActive(tokenId)) {
//            return address(0);
//        }
        return _tokenApprovals[tokenId];
    }

    function storage_setApprovalForAll(
        address msgSender,
        address operator,
        bool _approved
    ) public onlyHearts storage_onlyAllowedOperatorApproval(operator) {
//        uint256 operatorApproval = _operatorApprovals[msgSender][operator];
//
//        if (msg.sender == activeContract) {
//            operatorApproval = 2*(_approved ? 1 : 0) + operatorApproval%2;
//        }
//        else {
//            operatorApproval = 2*(operatorApproval>>1) + (_approved ? 1 : 0);
//        }
//
//        _operatorApprovals[msgSender][operator] = operatorApproval;
        _operatorApprovals[msgSender][operator] = _approved;
        ERC721TopLevelProto(msg.sender).emitApprovalForAll(msgSender, operator, _approved);
    }

//    function storage_isApprovedForAll(bool active, address owner, address operator) public view returns (bool) {
    function storage_isApprovedForAll(address owner, address operator) public view returns (bool) {
//        return ((_operatorApprovals[owner][operator] >> (active ? 1 : 0))%2 == 1);
        return (_operatorApprovals[owner][operator]);
    }

    /********/

//    function storage_totalSupply(bool active) public view returns (uint256) {
    function storage_totalSupply(bool active, address contractAddress) public view returns (uint256) {
        if (active) {
//            return _activeSupply;
            VersionInfo memory vi = _activeVersionData[contractAddress];
            require(vi.isVersion, "nv_a");
            return vi.totalSupply;
        }
        else {
//            return ((_nextToMint - _activeSupply) - _burnedSupply);
            VersionInfo memory vi = _inactiveVersionData[contractAddress];
            require(vi.isVersion, "nv_a");
            return vi.totalSupply;
        }
    }

//    function storage_tokenOfOwnerByIndex(
//        bool active,
//        address owner,
//        uint256 index
//    ) public view returns (uint256) {
    function storage_tokenOfOwnerByIndex(
        bool active,
        address contractAddress,
        address owner,
        uint256 index
    ) public view returns (uint256) {
        require(owner != address(0), "0");
        VersionInfo memory viA = _activeVersionData[contractAddress];
        VersionInfo memory viI = _inactiveVersionData[contractAddress];

        require(active ? viA.isVersion : viI.isVersion, "bad version");

//        uint256 thisBalance = storage_balanceOf(active, owner);
        uint256 thisBalance = storage_balanceOf(contractAddress, owner);
//        uint256 otherBalance = storage_balanceOf(!active, owner);
        uint256 totalBalance = _totalBalance(owner);
        require(index < thisBalance, "ind/bal");

        uint256 curIndex = 0;

        if (active) {
            for (uint256 i = 0; i < totalBalance; i++) {
                uint256 curToken = _ownershipOrderings[owner][i];
                if (
                    (_isActive(curToken) == active) &&
                    (_tokenData[curToken].activeVersionIndex == viA.versionId)
                ) {
                    if (curIndex == index) {
                        return curToken;
                    }
                    curIndex++;
                }
            }
        }
        else {
            for (uint256 i = 0; i < totalBalance; i++) {
                uint256 curToken = _ownershipOrderings[owner][i];
                if (
                    (_isActive(curToken) == active) &&
                    (_tokenData[curToken].inactiveVersionIndex == viI.versionId)
                ) {
                    if (curIndex == index) {
                        return curToken;
                    }
                    curIndex++;
                }
            }
        }

        revert("u");
    }

    function storage_tokenByIndex(
        bool active,
        address contractAddress,
        uint256 index
    ) public view returns (uint256) {
        require(_exists(active, contractAddress, index), "e");
        return index;
    }

    /********/

    function _generateRandomLineage(address to, bool mode) private view returns (uint256) {
        return uint256(
            keccak256(
                abi.encodePacked(
                    to,
                    tx.gasprice,
                    block.number,
                    block.timestamp,
                    block.difficulty,
                    blockhash(block.number - ((mode ? ((_lineageNonce>>128)%256) : ((_lineageNonce)%256)) + 1)),
                    (mode ? (_lineageNonce%(1<<128)) : (_lineageNonce>>128))
                )
            )
        );
    }

    function mint(
        address to,
        HeartColor color,
        uint256 lineageToken,
        uint256 lineageDepth,
        address parent
//    ) public onlyHearts returns (uint256) {
    ) public onlyLatest returns (uint256) {
        uint256 nextToMint = _nextToMint;
        TokenInfo memory newTokenData;

        newTokenData.owner = to;
        newTokenData.lastShifted = uint64(block.timestamp);
        newTokenData.color = color;
        newTokenData.parent = parent;

        uint256 newLineageData = _generateRandomLineage(to, true);
        _lineageNonce = _lineageNonce ^ newLineageData;
        if (msg.sender == activeContract) {
            uint256 lineageModifier = _generateRandomLineage(to, false);
            _lineageNonce = _lineageNonce ^ lineageModifier;
            uint256 tokenLineage = _tokenData[lineageToken].genome;

            uint256 newGenome = 0;
            for (uint256 i = 0; i < 256; i += 2) {
                if ((lineageModifier>>i)%4 == 0) {
                    newGenome += newLineageData & (3<<i);
                }
                else {
                    newGenome += tokenLineage & (3<<i);
                }
            }

            newTokenData.genome = newGenome;

            newTokenData.lineageDepth = (_tokenData[lineageToken].lineageDepth + 1);

            _tokenData[lineageToken].numChildren += 1;
        }
        else {
            newTokenData.genome = newLineageData;

            newTokenData.lineageDepth = uint40(lineageDepth);
        }

        newTokenData.activeVersionIndex = (nextActiveVersionIndex - 1);
        newTokenData.inactiveVersionIndex = (nextInactiveVersionIndex - 1);

        _tokenData[nextToMint] = newTokenData;

        uint256 toTotalBalance = _totalBalance(to);
        _ownershipOrderings[to][toTotalBalance] = nextToMint;
        _orderPositions[nextToMint] = toTotalBalance;

//        if (msg.sender == activeContract) {
        if (isActiveContract(msg.sender)) {
            _activations[nextToMint/256] += 1<<(nextToMint%256);
            _balances[to][msg.sender]++;
//            _activeSupply++;
            _activeVersionData[msg.sender].totalSupply++;
        }
        else {
            _balances[to][msg.sender]++;
            _inactiveVersionData[msg.sender].totalSupply++;
        }

        ERC721TopLevelProto(msg.sender).emitTransfer(address(0), to, _nextToMint);

        _nextToMint++;

        return nextToMint;
    }

    function mintExplicit(
        address to,
        HeartColor color,
        uint256 genome,
        uint256 lineageToken,
        uint256 lineageDepth,
        address parent
//    ) public onlyActive returns (uint256) {
    ) public onlyLatest returns (uint256) {
        uint256 nextToMint = _nextToMint;
        TokenInfo memory newTokenData;

        newTokenData.owner = to;
        newTokenData.lastShifted = uint64(block.timestamp);
        newTokenData.color = color;
        newTokenData.parent = parent;

        newTokenData.genome = genome;
//        newTokenData.lineageDepth = (_tokenData[lineageToken].lineageDepth + 1);
        newTokenData.lineageDepth = uint40(lineageDepth);

        newTokenData.activeVersionIndex = (nextActiveVersionIndex - 1);
        newTokenData.inactiveVersionIndex = (nextInactiveVersionIndex - 1);

        _tokenData[lineageToken].numChildren += 1;

        _tokenData[nextToMint] = newTokenData;

        uint256 toTotalBalance = _totalBalance(to);
        _ownershipOrderings[to][toTotalBalance] = nextToMint;
        _orderPositions[nextToMint] = toTotalBalance;

//        if (msg.sender == activeContract) {
        if (isActiveContract(msg.sender)) {
            _activations[nextToMint/256] += 1<<(nextToMint%256);
//            _balances[to].activeBalance += 1;
            _balances[to][msg.sender]++;
//            _activeSupply++;
            _activeVersionData[msg.sender].totalSupply++;
        }
        else {
//            _balances[to].inactiveBalance += 1;
            _balances[to][msg.sender]++;
            _inactiveVersionData[msg.sender].totalSupply++;
        }

        ERC721TopLevelProto(msg.sender).emitTransfer(address(0), to, _nextToMint);

        _nextToMint++;

        return nextToMint;
    }

    /******************/

    function _liquidate(uint256 tokenId, address contractAddress) private {
        address tokenOwner = storage_ownerOf(true, contractAddress, tokenId);

        _tokenData[tokenId].lastShifted = uint64(block.timestamp);
        _tokenData[tokenId].inactiveVersionIndex = (nextInactiveVersionIndex - 1);

        _activations[tokenId/256] -= 1<<(tokenId%256);

        address activeTokenAddress = _activeVersionRevMap[_tokenData[tokenId].activeVersionIndex];

        ERC721TopLevelProto(activeTokenAddress).emitTransfer(tokenOwner, address(0), tokenId);
        ERC721TopLevelProto(inactiveContract).emitTransfer(address(0), tokenOwner, tokenId);

//        _balances[tokenOwner].activeBalance -= 1;
//        _balances[tokenOwner].inactiveBalance += 1;
//        _activeSupply--;

        _balances[tokenOwner][activeTokenAddress]--;
        _balances[tokenOwner][inactiveContract]++;
        _activeVersionData[activeTokenAddress].totalSupply--;
        _inactiveVersionData[inactiveContract].totalSupply++;
    }

    function storage_liquidate(uint256 tokenId) public onlyActive {
        _liquidate(tokenId, msg.sender);
    }

    function _activate(uint256 tokenId, address contractAddress) private {
        address tokenOwner = storage_ownerOf(false, contractAddress, tokenId);

        _tokenData[tokenId].lastShifted = uint64(block.timestamp);
        _tokenData[tokenId].activeVersionIndex = (nextActiveVersionIndex - 1);

        _activations[tokenId/256] += 1<<(tokenId%256);

        address inactiveTokenAddress =
            _inactiveVersionRevMap[_tokenData[tokenId].inactiveVersionIndex];

        ERC721TopLevelProto(inactiveTokenAddress).emitTransfer(tokenOwner, address(0), tokenId);
        ERC721TopLevelProto(activeContract).emitTransfer(address(0), tokenOwner, tokenId);
        ActiveHearts(activeContract).initExpiryTime(tokenId);

//        _balances[tokenOwner].activeBalance += 1;
//        _balances[tokenOwner].inactiveBalance -= 1;
//        _activeSupply++;

        _balances[tokenOwner][activeContract]++;
        _balances[tokenOwner][inactiveTokenAddress]--;
        _activeVersionData[activeContract].totalSupply++;
        _inactiveVersionData[inactiveTokenAddress].totalSupply--;
    }

    function storage_activate(uint256 tokenId) public onlyInactive {
        _activate(tokenId, msg.sender);
    }

    function _burn(uint256 tokenId, address contractAddress) private {
        address prevOwnership = storage_ownerOf(false, contractAddress, tokenId);

//        _balances[prevOwnership].inactiveBalance -= 1;
        _totalBalances[prevOwnership] -= 1;

        _tokenData[tokenId].owner = address(0);

        uint256 fromBalanceTotal = _totalBalance(prevOwnership);
        uint256 curTokenOrder = _orderPositions[tokenId];
        uint256 lastFromTokenId = _ownershipOrderings[prevOwnership][fromBalanceTotal];
        if (tokenId != lastFromTokenId) {
            _ownershipOrderings[prevOwnership][curTokenOrder] = lastFromTokenId;
            _orderPositions[lastFromTokenId] = curTokenOrder;
            delete _ownershipOrderings[prevOwnership][fromBalanceTotal];
        }

        address inactiveTokenAddress = _inactiveVersionRevMap[_tokenData[tokenId].inactiveVersionIndex];

        ERC721TopLevelProto(inactiveTokenAddress).emitTransfer(prevOwnership, address(0), tokenId);

        delete _tokenData[tokenId];

        _balances[prevOwnership][inactiveTokenAddress]--;
        _inactiveVersionData[inactiveTokenAddress].totalSupply--;
    }

    function storage_burn(uint256 tokenId) public onlyInactive {
        _burn(tokenId, msg.sender);
    }

    function _batchLiquidate(uint256[] memory tokenIds) private {
        uint128 numTokens = uint128(tokenIds.length);

        address[] memory tokenOwners = new address[](numTokens);
        address[] memory zeroAddresses = new address[](numTokens);

        uint64 time64 = uint64(block.timestamp);

        address activeTokenAddress =
            _activeVersionRevMap[_tokenData[tokenIds[0]].activeVersionIndex];

        uint256 accumulator = 0;
        uint256 curSlot = 0;
        uint256 iterSlot;
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = tokenIds[i];
            iterSlot = tokenId/256;
            if (iterSlot != curSlot) {
                _activations[curSlot] -= accumulator;
                curSlot = iterSlot;
                accumulator = 0;
            }

            accumulator += (1<<(tokenId%256));

            tokenOwners[i] = _tokenData[tokenId].owner;
            _balances[tokenOwners[i]][activeTokenAddress]--;
            _balances[tokenOwners[i]][inactiveContract]++;

            _tokenData[tokenId].inactiveVersionIndex = (nextInactiveVersionIndex - 1);
            _tokenData[tokenId].lastShifted = time64;
        }
        _activations[curSlot] -= accumulator;

//        ERC721TopLevelProto(activeContract).batchEmitTransfers(tokenOwners, zeroAddresses, tokenIds);
        ERC721TopLevelProto(activeTokenAddress).batchEmitTransfers(tokenOwners, zeroAddresses, tokenIds);
        ERC721TopLevelProto(inactiveContract).batchEmitTransfers(zeroAddresses, tokenOwners, tokenIds);

        _activeVersionData[activeTokenAddress].totalSupply -= numTokens;
        _inactiveVersionData[inactiveContract].totalSupply += numTokens;
    }

    function storage_batchLiquidate(uint256[] calldata tokenIds) public onlyActive {
        _batchLiquidate(tokenIds);
    }

    function _batchActivate(uint256[] calldata tokenIds) private {
        uint128 numTokens = uint128(tokenIds.length);

        address[] memory tokenOwners = new address[](numTokens);
        address[] memory zeroAddresses = new address[](numTokens);

        uint64 time64 = uint64(block.timestamp);

        address inactiveTokenAddress =
            _inactiveVersionRevMap[_tokenData[tokenIds[0]].inactiveVersionIndex];

        uint256 accumulator = 0;
        uint256 curSlot = 0;
        uint256 iterSlot;
        for (uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = tokenIds[i];
            iterSlot = tokenId/256;
            if (iterSlot != curSlot) {
                _activations[curSlot] += accumulator;
                curSlot = iterSlot;
                accumulator = 0;
            }

            accumulator += (1<<(tokenId%256));

            tokenOwners[i] = _tokenData[tokenId].owner;
            _balances[tokenOwners[i]][activeContract]++;
            _balances[tokenOwners[i]][inactiveTokenAddress]--;

            _tokenData[tokenId].activeVersionIndex = (nextActiveVersionIndex - 1);
            _tokenData[tokenId].lastShifted = time64;
        }
        _activations[curSlot] += accumulator;

//        ERC721TopLevelProto(inactiveContract).batchEmitTransfers(tokenOwners, zeroAddresses, tokenIds);
        ERC721TopLevelProto(inactiveTokenAddress).batchEmitTransfers(tokenOwners, zeroAddresses, tokenIds);
        ERC721TopLevelProto(activeContract).batchEmitTransfers(zeroAddresses, tokenOwners, tokenIds);
        ActiveHearts(activeContract).batchInitExpiryTime(tokenIds);

        _activeVersionData[activeContract].totalSupply += numTokens;
        _inactiveVersionData[inactiveTokenAddress].totalSupply -= numTokens;
    }

    function storage_batchActivate(uint256[] calldata tokenIds) public onlyInactive {
        _batchActivate(tokenIds);
    }

    function _batchBurn(uint256[] memory tokenIds) private {
        uint128 numTokens = uint128(tokenIds.length);

        address[] memory tokenOwners = new address[](numTokens);
        address[] memory zeroAddresses = new address[](numTokens);

        address inactiveEmissionTarget =
            _inactiveVersionRevMap[_tokenData[tokenIds[0]].inactiveVersionIndex];

        for (uint256 i = 0; i < numTokens; i++) {
            uint256 tokenId = tokenIds[i];
            tokenOwners[i] = _tokenData[tokenId].owner;

//            _balances[tokenOwners[i]][inactiveEmissionTarget]--;
            _totalBalances[tokenOwners[i]]--;

            _tokenData[tokenId].owner = address(0);

            uint256 fromBalanceTotal = _totalBalance(tokenOwners[i]);
            uint256 curTokenOrder = _orderPositions[tokenId];
            uint256 lastFromTokenId = _ownershipOrderings[tokenOwners[i]][fromBalanceTotal];
            if (tokenId != lastFromTokenId) {
                _ownershipOrderings[tokenOwners[i]][curTokenOrder] = lastFromTokenId;
                _orderPositions[lastFromTokenId] = curTokenOrder;
                delete _ownershipOrderings[tokenOwners[i]][fromBalanceTotal];
            }

            delete _tokenData[tokenId];
        }

//        ERC721TopLevelProto(
//            _inactiveVersionRevMap[_tokenData[tokenId].inactiveVersionIndex]
//        ).batchEmitTransfers(tokenOwners, zeroAddresses, tokenIds);
        ERC721TopLevelProto(inactiveEmissionTarget).batchEmitTransfers(
            tokenOwners, zeroAddresses, tokenIds);

        _inactiveVersionData[inactiveEmissionTarget].totalSupply -= numTokens;
    }

//    function _batchBurnMultiple(uint256[] memory tokenIds) private {
//        address[] memory tokenOwners = new address[](tokenIds.length);
////        address[] memory zeroAddresses = new address[](tokenIds.length);
//
//        uint8 curVersionIndex = _tokenData[tokenIds[0]].inactiveVersionIndex;
//        uint256 lastCheckpoint = 0;
//
//        for (uint256 i = 0; i < tokenIds.length; i++) {
//            uint256 tokenId = tokenIds[i];
//
//            tokenOwners[i] = _tokenData[tokenId].owner;
//
//            uint8 nextVersionIndex = _tokenData[tokenId].inactiveVersionIndex;
//            if (nextVersionIndex != curVersionIndex) {
//                uint256 numToEmit = i - lastCheckpoint;
//                address[] memory zeroAddresses = new address[](numToEmit);
//                address[] memory emittedTokenOwners = new address[](numToEmit);
//                for (uint256 j = 0; j < numToEmit; j++) {
//                    emittedTokenOwners[j] = tokenOwners[lastCheckpoint + j];
//                }
//
//                ERC721TopLevelProto(_inactiveVersionRevMap[curVersionIndex]).batchEmitTransfers(
//                    emittedTokenOwners, zeroAddresses, tokenIds);
//
//                curVersionIndex = nextVersionIndex;
//                lastCheckpoint = i;
//            }
//
//            _balances[tokenOwners[i]].inactiveBalance -= 1;
//
//            _tokenData[tokenId].owner = address(0);
//
//            uint256 fromBalanceTotal = _totalBalance(tokenOwners[i]);
//            uint256 curTokenOrder = _orderPositions[tokenId];
//            uint256 lastFromTokenId = _ownershipOrderings[tokenOwners[i]][fromBalanceTotal];
//            if (tokenId != lastFromTokenId) {
//                _ownershipOrderings[tokenOwners[i]][curTokenOrder] = lastFromTokenId;
//                _orderPositions[lastFromTokenId] = curTokenOrder;
//                delete _ownershipOrderings[tokenOwners[i]][fromBalanceTotal];
//            }
//        }
//
//        uint256 numToEmit = tokenIds.length - lastCheckpoint;
//        address[] memory zeroAddresses = new address[](numToEmit);
//        address[] memory emittedTokenOwners = new address[](numToEmit);
//        for (uint256 j = 0; j < numToEmit; j++) {
//            emittedTokenOwners[j] = tokenOwners[lastCheckpoint + j];
//        }
//
//        ERC721TopLevelProto(_inactiveVersionRevMap[curVersionIndex]).batchEmitTransfers(
//            emittedTokenOwners, zeroAddresses, tokenIds);
//
////        ERC721TopLevelProto(inactiveContract).batchEmitTransfers(tokenOwners, zeroAddresses, tokenIds);
//
//        _burnedSupply += tokenIds.length;
//    }

    function storage_batchBurn(uint256[] calldata tokenIds) public onlyInactive {
        _batchBurn(tokenIds);
    }

    /******************/

    function storage_upgrade(uint256 tokenId) public onlyHearts {
//        require(_tokenData[tokenId].owner != address(0), "upg_e");

        if (isActiveContract(msg.sender)) {
            require(_exists(true, msg.sender, tokenId), "upg_e");
            VersionInfo memory vi = _activeVersionData[msg.sender];
            if (vi.versionId < (nextActiveVersionIndex - 1)) {
                _tokenData[tokenId].activeVersionIndex = (nextActiveVersionIndex - 1);
            }
        }
        else {
            require(_exists(false, msg.sender, tokenId), "upg_e");
            VersionInfo memory vi = _inactiveVersionData[msg.sender];
            if (vi.versionId < (nextInactiveVersionIndex - 1)) {
                _tokenData[tokenId].inactiveVersionIndex = (nextInactiveVersionIndex - 1);
            }
        }

        revert("cannot upgrade this token");
    }

    function storage_batchUpgrade(uint256[] calldata tokenIds) public onlyHearts {
        bool allExist = true;

        if (isActiveContract(msg.sender)) {
            VersionInfo memory vi = _activeVersionData[msg.sender];
            if (vi.versionId < (nextActiveVersionIndex - 1)) {
                for (uint256 i = 0; i < tokenIds.length; i++) {
                    uint256 tokenId = tokenIds[i];
                    allExist = (allExist && (_tokenData[tokenId].owner != address(0)));
                    _tokenData[tokenId].activeVersionIndex = (nextActiveVersionIndex - 1);
                }
                require(allExist, "b_upg__ae");
            }
        }
        else {
            VersionInfo memory vi = _inactiveVersionData[msg.sender];
            if (vi.versionId < (nextInactiveVersionIndex - 1)) {
                for (uint256 i = 0; i < tokenIds.length; i++) {
                    uint256 tokenId = tokenIds[i];
                    allExist = (allExist && (_tokenData[tokenId].owner != address(0)));
                    _tokenData[tokenId].inactiveVersionIndex = (nextInactiveVersionIndex - 1);
                }
                require(allExist, "b_upg__ae");
            }
        }

        revert("cannot upgrade this token");
    }

    /******************/

    function setSuccessor(address _successor) public onlyOwner {
        successorContract = _successor;
    }

    function storage_migrate(uint256 tokenId, address msgSender) public onlySuccessor {
        require(msgSender == tx.origin, "bad origin");
        require(_tokenData[tokenId].owner != address(0), "mig_e");

        if (_isActive(tokenId)) {
            _liquidate(tokenId, _activeVersionRevMap[_tokenData[tokenId].activeVersionIndex]);
            _burn(tokenId, inactiveContract);
        }
        else {
            _burn(tokenId, _inactiveVersionRevMap[_tokenData[tokenId].inactiveVersionIndex]);
        }

        LiquidationBurnRewardsProto(lbrContract).disburseMigrationReward(tokenId, msgSender);
    }

//    function storage_batchMigrate(uint256[] calldata tokenIds, address msgSender) public onlySuccessor {
//        require(msgSender == tx.origin, "bad origin");
//        uint256[] memory existsActive = new uint256[](tokenIds.length);
//        uint256[] memory existsInactive = new uint256[](tokenIds.length);
//        uint256 numExistsActive = 0;
//        uint256 numExistsInactive = 0;
//        for (uint256 i = 0; i < tokenIds.length; i++) {
//            if (_exists(true, tokenIds[i])) {
//                existsActive[numExistsActive] = tokenIds[i];
//                existsInactive[numExistsInactive] = tokenIds[i];
//                numExistsActive++;
//                numExistsInactive++;
//            }
//            else if (_exists(false, tokenIds[i])) {
//                existsInactive[numExistsInactive] = tokenIds[i];
//                numExistsInactive++;
//            }
//            else {
//                revert("ne");
//            }
//        }
//
//        if (numExistsActive > 0) {
//            uint256[] memory toLiquidate = new uint256[](numExistsActive);
//            for (uint256 i = 0; i < numExistsActive; i++) {
//                toLiquidate[i] = existsActive[i];
//            }
//
//            _batchLiquidate(toLiquidate);
//        }
//
//        if (numExistsActive > 0) {
//            uint256[] memory toBurn = new uint256[](numExistsInactive);
//            for (uint256 i = 0; i < numExistsInactive; i++) {
//                toBurn[i] = existsInactive[i];
//            }
//
//            _batchBurn(toBurn);
//        }
//
//        LiquidationBurnRewardsProto(lbrContract).batchDisburseMigrationReward(tokenIds, msgSender);
//    }

    function storage_batchMigrate(uint256[] calldata tokenIds, address msgSender) public onlySuccessor {
        require(msgSender == tx.origin, "bad origin");
        bool allExist = true;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            allExist = (allExist && (_tokenData[tokenId].owner != address(0)));
            if (_isActive(tokenId)) {
                _liquidate(tokenId, _activeVersionRevMap[_tokenData[tokenId].activeVersionIndex]);
                _burn(tokenId, inactiveContract);
            }
            else {
                _burn(tokenId, _inactiveVersionRevMap[_tokenData[tokenId].inactiveVersionIndex]);
            }
        }

        require(allExist, "b_mig__ae");

        LiquidationBurnRewardsProto(lbrContract).batchDisburseMigrationReward(tokenIds, msgSender);
    }

    /******************/

    function setNewActiveContract(address _activeContract) public onlyOwner {
        activeContract = _activeContract;

        VersionInfo memory vi;
        vi.versionId = nextActiveVersionIndex;
        vi.isVersion = true;
        _activeVersionData[_activeContract] = vi;
        _activeVersionRevMap[vi.versionId] = _activeContract;

        nextActiveVersionIndex++;
    }

    function setNewInactiveContract(address _inactiveContract) public onlyOwner {
        inactiveContract = _inactiveContract;

        VersionInfo memory vi;
        vi.versionId = nextInactiveVersionIndex;
        vi.isVersion = true;
        _inactiveVersionData[_inactiveContract] = vi;
        _inactiveVersionRevMap[vi.versionId] = _inactiveContract;

        nextInactiveVersionIndex++;
    }

    function setLBRContract(address _lbrContract) public onlyOwner {
        lbrContract = _lbrContract;
    }

    /******************/

    function _isActive(uint256 tokenId) private view returns (bool) {
        return (((_activations[tokenId/256])>>(tokenId%256))%2 == 1);
    }

//    function _tokenVersionIndex(bool active, uint256 tokenId) private view returns (uint8) {
//        if (active) {
//            return (_tokenData[tokenId].versionIndex)%16;
//        }
//        else {
//            return (_tokenData[tokenId].versionIndex)>>4;
//        }
//    }

    function _exists(bool active, address contractAddress, uint256 tokenId) public view returns (bool) {
        bool baseExists = (
            (tokenId < _nextToMint) &&
            (_tokenData[tokenId].owner != address(0))) &&
            (_isActive(tokenId) == active
        );

        if (!baseExists) {
            return false;
        }

        if (active) {
            VersionInfo memory avInfo = _activeVersionData[contractAddress];
            if (!avInfo.isVersion) {
                return false;
            }

            return (avInfo.versionId == _tokenData[tokenId].activeVersionIndex);
        }
        else {
            VersionInfo memory ivInfo = _inactiveVersionData[contractAddress];
            if (!ivInfo.isVersion) {
                return false;
            }

            return (ivInfo.versionId == _tokenData[tokenId].inactiveVersionIndex);
        }
    }

    function _approve(address to, uint256 tokenId, address owner) private {
        _tokenApprovals[tokenId] = to;
        ERC721TopLevelProto(msg.sender).emitApproval(owner, to, tokenId);
    }

    function _transfer(
        address msgSender,
//        bool active,
        address from,
        address to,
        uint256 tokenId
    ) private {
        require(to != address(0), "t0");

//        address prevOwnership = storage_ownerOf(active, tokenId);
        address prevOwnership = _tokenData[tokenId].owner;

        bool isApprovedOrOwner = (
            msgSender == prevOwnership ||
//            msgSender == storage_getApproved(active, tokenId) ||
            msgSender == storage_getApproved(tokenId) ||
//            storage_isApprovedForAll(active, prevOwnership, msgSender)
            storage_isApprovedForAll(prevOwnership, msgSender)
        );
        bool fromPrevOwnership = (prevOwnership == from);
        if (!(isApprovedOrOwner || fromPrevOwnership)) {
            revert TransferError(isApprovedOrOwner, fromPrevOwnership);
        }

        _approve(address(0), tokenId, prevOwnership);

//        if (active) {
//            _balances[from].activeBalance -= 1;
//        }
//        else {
//            _balances[from].inactiveBalance -= 1;
//        }
        _balances[from][msg.sender]--;
        _totalBalances[from]--;

        _tokenData[tokenId].owner = to;

//        uint256 fromBalanceTotal = _totalBalance(from);
        uint256 fromBalanceTotal = _totalBalances[from];
        uint256 curTokenOrder = _orderPositions[tokenId];
        uint256 lastFromTokenId = _ownershipOrderings[from][fromBalanceTotal];
        if (tokenId != lastFromTokenId) {
            _ownershipOrderings[from][curTokenOrder] = lastFromTokenId;
            _orderPositions[lastFromTokenId] = curTokenOrder;
            delete _ownershipOrderings[from][fromBalanceTotal];
        }

//        uint256 toBalanceTotal = _totalBalance(to);
        uint256 toBalanceTotal = _totalBalances[to];
        _ownershipOrderings[to][toBalanceTotal] = tokenId;
        _orderPositions[tokenId] = toBalanceTotal;

//        if (active) {
//            _balances[to].activeBalance += 1;
//        }
//        else {
//            _balances[to].inactiveBalance += 1;
//        }
        _balances[to][msg.sender]++;
        _totalBalances[to]++;

        ERC721TopLevelProto(msg.sender).emitTransfer(from, to, tokenId);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("z");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /******************/

    receive() external payable {}

    function withdraw() public onlyOwner {
        (bool success, ) = payable(inactiveContract).call{value: address(this).balance}("");
        require(success, "Payment failed!");
    }

    function withdrawTokens(address tokenAddress) public onlyOwner {
        IERC20(tokenAddress).transfer(inactiveContract, IERC20(tokenAddress).balanceOf(address(this)));
    }
}

////////////////////

abstract contract ERC721TopLevelProto {
    function emitTransfer(address from, address to, uint256 tokenId) public virtual;
    function batchEmitTransfers(
        address[] calldata from,
        address[] calldata to,
        uint256[] calldata tokenIds
    ) public virtual;

    function emitApproval(address owner, address approved, uint256 tokenId) public virtual;

    function emitApprovalForAll(address owner, address operator, bool approved) public virtual;
}

//////////

abstract contract ActiveHearts is ERC721TopLevelProto {
    function initExpiryTime(uint256 heartId) public virtual;
    function batchInitExpiryTime(uint256[] calldata heartIds) public virtual;
}

//////////

abstract contract LiquidationBurnRewardsProto {
    function disburseMigrationReward(uint256 heartId, address to) public virtual;
    function batchDisburseMigrationReward(uint256[] calldata heartIds, address to) public virtual;
}

////////////////////////////////////////

// SPDX-License-Identifier: MIT
/**
 * Creator: Virtue Labs
 * Authors:
 *** Code: 0xYeety, CTO - Virtue labs
 *** Concept: Church, CEO - Virtue Labs
**/

import "./HeartColors.sol";

pragma solidity ^0.8.17;

struct TokenInfo {
    uint256 genome;
    address owner;
    uint64 lastShifted;
    HeartColor color;
    //uint24 padding;
    //uint8 padding;
    uint8 padding;
    address parent;
//    uint48 numChildren;
//    uint48 lineageDepth;
    uint40 numChildren;
    uint40 lineageDepth;
    uint8 inactiveVersionIndex;
    uint8 activeVersionIndex;
}

struct VersionInfo {
    uint128 totalSupply;
    bool isVersion;
    uint8 versionId;
}

struct AddressInfo {
    uint128 inactiveBalance;
    uint128 activeBalance;
}