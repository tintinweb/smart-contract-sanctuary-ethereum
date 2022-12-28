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

// SPDX-License-Identifier: Unlicense
// Creator: 0xYeety/YEETY.eth - CTO, Virtue Labs

pragma solidity ^0.8.17;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/utils/Address.sol";
import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/*********************************************************************************************************************/
/*       ___           ___                       ___       ___                 ___           ___           ___       */
/*      /\  \         /\__\          ___        /\__\     /\  \               /\  \         /\__\         /\  \      */
/*     /::\  \       /:/  /         /\  \      /:/  /    /::\  \              \:\  \       /:/  /        /::\  \     */
/*    /:/\:\  \     /:/  /          \:\  \    /:/  /    /:/\:\  \              \:\  \     /:/__/        /:/\:\  \    */
/*   /::\~\:\__\   /:/  /  ___      /::\__\  /:/  /    /:/  \:\__\             /::\  \   /::\  \ ___   /::\~\:\  \   */
/*  /:/\:\ \:|__| /:/__/  /\__\  __/:/\/__/ /:/__/    /:/__/ \:|__|           /:/\:\__\ /:/\:\  /\__\ /:/\:\ \:\__\  */
/*  \:\~\:\/:/  / \:\  \ /:/  / /\/:/  /    \:\  \    \:\  \ /:/  /          /:/  \/__/ \/__\:\/:/  / \:\~\:\ \/__/  */
/*   \:\ \::/  /   \:\  /:/  /  \::/__/      \:\  \    \:\  /:/  /          /:/  /           \::/  /   \:\ \:\__\    */
/*    \:\/:/  /     \:\/:/  /    \:\__\       \:\  \    \:\/:/  /           \/__/            /:/  /     \:\ \/__/    */
/*     \::/__/       \::/  /      \/__/        \:\__\    \::/__/                            /:/  /       \:\__\      */
/*      ~~            \/__/                     \/__/     ~~                                \/__/         \/__/      */
/*                                                                                                                   */
/*         ___           ___       ___           ___           ___           ___           ___           ___         */
/*        /\  \         /\__\     /\  \         /\  \         /\  \         /\  \         /\  \         /\__\        */
/*       /::\  \       /:/  /    /::\  \        \:\  \       /::\  \       /::\  \       /::\  \       /::|  |       */
/*      /:/\:\  \     /:/  /    /:/\:\  \        \:\  \     /:/\:\  \     /:/\:\  \     /:/\:\  \     /:|:|  |       */
/*     /::\~\:\  \   /:/  /    /::\~\:\  \       /::\  \   /::\~\:\  \   /:/  \:\  \   /::\~\:\  \   /:/|:|__|__     */
/*    /:/\:\ \:\__\ /:/__/    /:/\:\ \:\__\     /:/\:\__\ /:/\:\ \:\__\ /:/__/ \:\__\ /:/\:\ \:\__\ /:/ |::::\__\    */
/*    \/__\:\/:/  / \:\  \    \/__\:\/:/  /    /:/  \/__/ \/__\:\ \/__/ \:\  \ /:/  / \/_|::\/:/  / \/__/~~/:/  /    */
/*         \::/  /   \:\  \        \::/  /    /:/  /           \:\__\    \:\  /:/  /     |:|::/  /        /:/  /     */
/*          \/__/     \:\  \       /:/  /     \/__/             \/__/     \:\/:/  /      |:|\/__/        /:/  /      */
/*                     \:\__\     /:/  /                                   \::/  /       |:|  |         /:/  /       */
/*                      \/__/     \/__/                                     \/__/         \|__|         \/__/        */
/*********************************************************************************************************************/

contract ERC721StorageLayer is Ownable {
    using Address for address;
    using Strings for uint256;

    //////////

    mapping(uint256 => address) private registeredContracts;
    mapping(address => uint256) private contractNumberings;
    mapping(address => bool) private isRegistered;
    uint256 numRegistered;

    modifier onlyRegistered() {
        _isRegistered();
        _;
    }
    function _isRegistered() internal view virtual {
        require(isRegistered[msg.sender], "r");
    }

    mapping(address => string) private _contractNames;
    mapping(address => string) private _contractSymbols;
    bool public canSetNameAndSymbol = true;

    mapping(address => string) private _contractDescriptions;
    mapping(address => string) private _contractImages;

    //////////

    address public mintingContract;

    modifier onlyMintingContract() {
        _isMintingContract();
        _;
    }
    function _isMintingContract() internal view virtual {
        require(msg.sender == mintingContract, "m");
    }

    //////////

    uint256 currentIndex;
    mapping(uint256 => address) _ownerships;
    mapping(address => uint256) _balances;

    address public immutable burnAddress = 0x000000000000000000000000000000000000dEaD;
    mapping(address => uint256) private _burnCounts;

    //////////

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => mapping(address => bool))) private _operatorApprovals;

    ////////////////////

    function registerTopLevel(
        string memory name_,
        string memory symbol_,
        string memory description_,
        string memory image_
    ) public {
        require(numRegistered < 5, "mr");
        require(tx.origin == owner(), "a");

        registeredContracts[numRegistered] = msg.sender;
        contractNumberings[msg.sender] = numRegistered;

        _contractNames[msg.sender] = name_;
        _contractSymbols[msg.sender] = symbol_;
        _contractDescriptions[msg.sender] = description_;
        _contractImages[msg.sender] = image_;

        isRegistered[msg.sender] = true;
        numRegistered++;
    }

    function registerMintingContract() public {
        require(tx.origin == owner(), "a");
        mintingContract = msg.sender;
    }

    //////////

    function storage_totalSupply(address collection) public view returns (uint256) {
        require(isRegistered[collection], "r");
        return (currentIndex/5) - _burnCounts[collection];
    }

    function storage_tokenByIndex(
        address collection,
        uint256 index
    ) public view returns (uint256) {
        require(isRegistered[collection], "r");
        require(index < (currentIndex/5), "g");
        require(storage_ownerOf(collection, index) != burnAddress, "b");
        return index;
    }

    function storage_tokenOfOwnerByIndex(
        address collection,
        address owner,
        uint256 index
    ) public view returns (uint256) {
        require(isRegistered[collection], "r");
        require(index < storage_balanceOf(collection, owner), "b");
        uint256 numTokenIds = currentIndex;
        uint256 tokenIdsIdx = 0;
        address currOwnershipAddr = address(0);
        uint256 j;
        uint256 offset = contractNumberings[collection];
        for (uint256 i = 0; i < numTokenIds/5; i++) {
            j = i*5 + offset;
            address ownership = _ownerships[j];
            if (ownership != address(0)) {
                currOwnershipAddr = ownership;
            }
            if (currOwnershipAddr == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("u");
    }

    function storage_tokenOfOwnerByIndexStepped(
        address collection,
        address owner,
        uint256 index,
        uint256 lastToken,
        uint256 lastIndex
    ) public view returns (uint256) {
        require(isRegistered[collection], "r");
        require(index < storage_balanceOf(collection, owner), "b");
        uint256 numTokenIds = currentIndex;
        uint256 tokenIdsIdx = ((lastIndex == 0) ? 0 : (lastIndex + 1));
        address currOwnershipAddr = address(0);
        uint256 j;
        uint256 offset = contractNumberings[collection];
        for (uint256 i = ((lastToken == 0) ? 0 : (lastToken + 1)); i < numTokenIds/5; i++) {
            j = i*5 + offset;
            address ownership = _ownerships[j];
            if (ownership != address(0)) {
                currOwnershipAddr = ownership;
            }
            if (currOwnershipAddr == owner) {
                if (tokenIdsIdx == index) {
                    return i;
                }
                tokenIdsIdx++;
            }
        }
        revert("u");
    }

    function storage_balanceOf(
        address collection,
        address owner
    ) public view returns (uint256) {
        require(isRegistered[collection], "r");
        require(owner != address(0) || owner != burnAddress, "0/burn");
        return (_balances[owner] >> (14*contractNumberings[collection]))%(1<<14);
    }

    function storage_ownerOf(
        address collection,
        uint256 tokenId
    ) public view returns (address) {
        require(isRegistered[collection], "r");
        require(tokenId < currentIndex/5, "t");

        uint256 offset = contractNumberings[collection];
        for (uint256 i = tokenId*5 + offset; i >= 0; i--) {
            address ownership = _ownerships[i];
            if (ownership != address(0)) {
                return ownership;
            }
        }

        revert("o");
    }

    function storage_name(address collection) public view returns (string memory) {
        require(isRegistered[collection], "r");
        return _contractNames[collection];
    }

    function storage_setName(address collection, string memory newName) public onlyOwner {
        require(isRegistered[collection] && canSetNameAndSymbol, "r/cs");
        _contractNames[collection] = newName;
    }

    function storage_symbol(address collection) public view returns (string memory) {
        require(isRegistered[collection] && canSetNameAndSymbol, "r/cs");
        return _contractSymbols[collection];
    }

    function storage_setSymbol(address collection, string memory newSymbol) public onlyOwner {
        require(isRegistered[collection], "r");
        _contractSymbols[collection] = newSymbol;
    }

    function flipCanSetNameAndSymbol() public onlyOwner {
        require(canSetNameAndSymbol, "cs");
        canSetNameAndSymbol = false;
    }

    function storage_setDescription(
        address collection,
        string memory newDescription
    ) public onlyOwner {
        require(isRegistered[collection], "r");
        _contractDescriptions[collection] = newDescription;
    }

    function storage_setImage(
        address collection,
        string memory newImage
    ) public onlyOwner {
        require(isRegistered[collection], "r");
        _contractImages[collection] = newImage;
    }

    function storage_approve(address msgSender, address to, uint256 tokenId) public onlyRegistered {
        address owner = ERC721StorageLayer.storage_ownerOf(msg.sender, tokenId);
        require(to != owner, "o");

        require(
            msgSender == owner || storage_isApprovedForAll(msg.sender, owner, msgSender),
            "a"
        );

        _approve(to, tokenId*5 + contractNumberings[msg.sender], owner);
    }

    function storage_getApproved(
        address collection,
        uint256 tokenId
    ) public view returns (address) {
        require(isRegistered[collection], "r");

        uint256 mappedTokenId = tokenId*5 + contractNumberings[collection];
        require(_exists(mappedTokenId, tokenId), "a");

        return _tokenApprovals[mappedTokenId];
    }

    function storage_setApprovalForAll(
        address msgSender,
        address operator,
        bool approved
    ) public onlyRegistered {
        require(operator != msgSender, "a");

        _operatorApprovals[msg.sender][msgSender][operator] = approved;
        ERC721TopLevelProto(msg.sender).emitApprovalForAll(msgSender, operator, approved);
    }

    function storage_globalSetApprovalForAll(
        address operator,
        bool approved
    ) public {
        require(operator != msg.sender, "a");

        for (uint256 i = 0; i < 5; i++) {
            address topLevelContract = registeredContracts[i];
            require(!(ERC721TopLevelProto(topLevelContract).operatorRestrictions(operator)), "r");
            _operatorApprovals[topLevelContract][msg.sender][operator] = approved;
            ERC721TopLevelProto(topLevelContract).emitApprovalForAll(msg.sender, operator, approved);
        }
    }

    function storage_isApprovedForAll(
        address collection,
        address owner,
        address operator
    ) public view returns (bool) {
        require(isRegistered[collection], "r");
        return _operatorApprovals[collection][owner][operator];
    }

    function storage_transferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public onlyRegistered {
        _transfer(msgSender, from, to, tokenId*5 + contractNumberings[msg.sender]);
        ERC721TopLevelProto(msg.sender).emitTransfer(from, to, tokenId);
    }

    function storage_safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) public onlyRegistered {
        storage_safeTransferFrom(msgSender, from, to, tokenId, "");
    }

    function storage_safeTransferFrom(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public onlyRegistered {
        _transfer(msgSender, from, to, tokenId*5 + contractNumberings[msg.sender]);
        ERC721TopLevelProto(msg.sender).emitTransfer(from, to, tokenId);
        require(
            _checkOnERC721Received(msgSender, from, to, tokenId, _data),
            "z"
        );
    }

    function storage_burnToken(address msgSender, uint256 tokenId) public onlyRegistered {
        _transfer(
            msgSender,
            storage_ownerOf(msg.sender, tokenId),
            burnAddress,
            tokenId*5 + contractNumberings[msg.sender]
        );
        _burnCounts[msg.sender] += 1;
        ERC721TopLevelProto(msg.sender).emitTransfer(msgSender, burnAddress, tokenId);
    }

    function storage_exists(
        address collection,
        uint256 tokenId
    ) public view returns (bool) {
        require(isRegistered[collection], "r");
        return _exists(tokenId*5 + contractNumberings[collection], tokenId);
    }

    function _exists(uint256 mappedTokenId, uint256 tokenId) private view returns (bool) {
        return (mappedTokenId < currentIndex && _ownerships[tokenId] != burnAddress);
    }

    function storage_safeMint(
        address msgSender,
        address to,
        uint256 quantity
    ) public onlyMintingContract {
        storage_safeMint(msgSender, to, quantity, "");
    }

    function storage_safeMint(
        address msgSender,
        address to,
        uint256 quantity,
        bytes memory _data
    ) public onlyMintingContract {
        storage_mint(to, quantity);
        require(_checkOnERC721Received(msgSender, address(0), to, (currentIndex/5) - 1, _data), "z");
    }

    function storage_mint(address to, uint256 quantity) private {
        uint256 startTokenId = currentIndex/5;
        require(to != address(0), "0");
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        require(!_exists(currentIndex, startTokenId), "a");

        uint256 balanceQtyAdd = 0;
        for (uint256 i = 0; i < 5; i++) {
            balanceQtyAdd += (quantity << (i*14));
        }
        _balances[to] = _balances[to] + balanceQtyAdd;
        _ownerships[currentIndex] = to;

        uint256 updatedIndex = startTokenId;

        for (uint256 i = 0; i < quantity; i++) {
            for (uint256 j = 0; j < 5; j++) {
                ERC721TopLevelProto(registeredContracts[j]).emitTransfer(address(0), to, updatedIndex);
            }
            updatedIndex++;
        }

        currentIndex = updatedIndex*5;
    }

    function storage_contractURI(address collection) public view virtual returns (string memory) {
        require(isRegistered[collection], "r");
        return string(
            abi.encodePacked(
                "data:application/json;utf8,{\"name\":\"", storage_name(collection), "\",",
                "\"description\":\"", _contractDescriptions[collection], "\",",
                "\"image\":\"", _contractImages[collection], "\",",
                "\"external_link\":\"https://crudeborne.wtf\",",
                "\"seller_fee_basis_points\":500,\"fee_recipient\":\"",
                uint256(uint160(mintingContract)).toHexString(), "\"}"
            )
        );
    }

    //////////

    function _transfer(
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) private {
        uint256 collectionTokenId = tokenId/5;
        address prevOwnership = storage_ownerOf(msg.sender, collectionTokenId);

        bool isApprovedOrOwner = (msgSender == prevOwnership ||
        storage_getApproved(msg.sender, collectionTokenId) == msgSender ||
        storage_isApprovedForAll(msg.sender, prevOwnership, msgSender));

        require(isApprovedOrOwner && prevOwnership == from, "a");
        require(prevOwnership == from, "o");
        require(to != address(0), "0");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwnership);

        _balances[from] -= (1 << (contractNumberings[msg.sender]*14));
        _balances[to] += (1 << (contractNumberings[msg.sender]*14));
        _ownerships[tokenId] = to;

        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        if (_ownerships[nextTokenId] == address(0)) {
            if (_exists(nextTokenId, nextTokenId/5)) {
                _ownerships[nextTokenId] = prevOwnership;
            }
        }
    }

    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        ERC721TopLevelProto(msg.sender).emitApproval(owner, to, tokenId/5);
    }

    function _checkOnERC721Received(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msgSender, from, tokenId, _data) returns (bytes4 retVal) {
                return retVal == IERC721Receiver(to).onERC721Received.selector;
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

    //////////

    receive() external payable {
        (bool success, ) = payable(mintingContract).call{value: msg.value}("");
        require(success, "F");
    }

    function withdrawTokens(address tokenAddress) external onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }
}

////////////////////

abstract contract ERC721TopLevelProto {
    mapping(address => bool) public operatorRestrictions;
    function emitTransfer(address from, address to, uint256 tokenId) public virtual;
    function emitApproval(address owner, address approved, uint256 tokenId) public virtual;
    function emitApprovalForAll(address owner, address operator, bool approved) public virtual;
}

////////////////////////////////////////