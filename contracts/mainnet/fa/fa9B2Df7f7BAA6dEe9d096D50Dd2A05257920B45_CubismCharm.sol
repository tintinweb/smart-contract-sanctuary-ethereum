/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/utils/math/SignedMath.sol


// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// File: @openzeppelin/contracts/utils/math/Math.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
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
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

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
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
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
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
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
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
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
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

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
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
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

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
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
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
    }
}

// File: contracts/CubismCharm.sol



// Created by Colored Chain
/**
                                                                                                                                                                          
                                                                                                                                                                          
                                                                                                                                                                          
                                                                                                                                                                          
                                                                                                                                                                          
                                                                                                                                                                          
                              `_+jz2uInnnnnIIIIIIIuuxxaa]ee52zl1i+++++++++++!!++jclz2Innnnnnnnnnnnnnnnnnnnnnnnnyc+||||||||||||||||||~^',`                                 
                        `|1xqPX&&&&&[email protected]@@@@@@@[email protected]@&XG02sttttttttttttt??????t}+>_'`                           
                    `|zqGW&&&&&&&&&&&WWWWWWWWXXXXXXmmmOGGPPPAAgZ%0qnz2I$AOXWW&&@@@@@@@@@[email protected]@[email protected]@@&XGAbltttttttttttttttttttt?tt??t+>\`                       
                  ~2AW&&&&&&&&&&&&&WWWWWWWWWWWXXXXXmmmOGGPPPAAgZ%0q8wAOmXXXWW&&&@@@@@@@@[email protected]@[email protected]@&XGA8ztttttttttttttttttttttttt??jj?t!^`                    
                _qX&&&&&&&&&&&&&&&&WWWWWWWWWWXXXXXmmmmOOGPPPAAgZp%UAPGmmmXXWW&&&@@@@@@@@[email protected]@[email protected]@&XGgnvtttttttttttttttttttttttt?????j?ji|`                  
              |$W&&&&&&&&&&&&&&&&&&&&WWWWWWWXmGPPPPAAAAAggUh%0dqZgAPGGOmXXXWW&&@@@@@@@@@[email protected]@&WWWWWWWWXmmmmOGA0Ic}+++++}ittttt???tttttttttt??????????t"`                
            `cO&&&&&&&&&&&&&&&&&&&&&WXAS2s!_:,````````````````iTFAAPPGOmmXXWW&&@@@@@@@@mPkdCIye2222222zzv_`` `            ```,\_"+t??????tttt?????????tti+`               
           `]X&&&&&&&&&&&&&&&&&&&&Pnt\`                     `sT%FAAPPGOmmXXWW&&@@@@mASa2z22zzzz2zzzzzzzzzl|                       `\>}?ttt????????????ttt}!,              
           lW&&&&&&&&&&&&&&&&&&&Pz`                         +S0pFAAPPGOmmXXWW&&@&Ac,`"cz22zzzzzzzzzzzzzz2zl^                         `\+?t???j????????tti}+"`             
          _O&&&&&&&&&&&&&&&&&&Xa,                          \aT0pFAAPPGOmmXXWW&&m2`    `+z2zzzzzzzzzzzzzz2zz?`                           >??tt?????????ttt}+!_             
          2&&&&&&&&&&&&&&&&&&Wl                            +Cd0pFAAPPGOmmXXWW&X7       `!z2zzzzzzzzzzzzz2zzl~                            |?tt?????????ttt}+!>`            
          x&&&&&&&&&&&&&&&&&&X"                            }CT0pFAAPPGOmmXXWW&O|        \l22zzzzzzzzzzzz2z2z>                            ,?tt?????????ttt}+!",            
          2&&&&&&&&&&&&&&&&&&Wz                            +CdqpFAAPPGOmmXXWW&X1       `!zzzzzzzzzzzzzzz2zzl~                            |?tt?????????ttt}+!>`            
          |m&&&&&&&&&&&&&&&&&&mz`                          ^xd0pFAAPPGOmmXXWW&&mc`    `!z2zzzzzzzzzzzzzz2zzj`                           |tt?t?????????ttt}+!_             
           5W&&&&&&&&&&&&&&&&&&Wgs`                        `iS0pFAAPPGOmmXXWW&&&&kt``|7z22zzzzzzzzzzzzzz2zl_                          :!?tttt?????????tti}+!`             
           `2W&&&&&&&&&&&&&&&&&&&&GCs^                      `twpggAPPGOmmXXWW&&&@@@XATx2z22zzzz2zzzzzzzzzc_                       `\"}t?ttttt?????????tti}!,              
            `1O&&&&&&&&&&&&&&&&&&&&&WXPqac+>\,````````````````}wFAAPPGOmmXXWW&&&@@@@@@@XPF0Snxy222222222c_`````           ```-\|!+t???t?ttttt?????????ttt+`               
              _SW&&&&&&&&&&&&&&&&&&&WWWWWWWWWmOGGGPPPPPAAAAgZ%q0ZgAPPGOmXXXWW&&&@@@@@@@@[email protected]&&&&&&&&&WXXXXXmPknci}}}}}}tttttt?????tttttttt?????????tt>`                
                "FW&&&&&&&&&&&&&&&&WWWWWWWWWWXXXXXXmmmOGGPPPAAgUhpFAGGOmmXXWW&&&@@@@@@@@[email protected]@@&XOgI1t?tttttttttttttttttttttt???????jt",                  
                 `"IP&&&&&&&&&&&&&&WWWWWWWWWWXXXXXXmmmOGGPPPAAgZp0qdqPOmXXXWW&&&@@@@@@@@[email protected]@@[email protected]@&XGAbzttttttttttttttttttttttt?jj????+_`                    
                     ~c8PW&&&&&&&&&WWWWWWWWWWXXXXXXmmmOGGPPPAAgZp0qnz2xwgGXWW&&&@@@@@@@@[email protected]@[email protected]@@&XGAblttttttttttttttttttttt?t?jt+|'`                       
                        `_jyTAmW&&&&WWWWWWWWWXXXXXXmmmOGGPPPAAgZ%[email protected]@@@@@@@[email protected]@&XPqzjttttttttttttttt????t}!>~:`                           
                              `\"}vzeyInnnnnnnnnnIIIIuxxaaye2zl1i+++++++++++++++isvlzeanCCCCCCCCCCCCCCCCCCCCCCuec+>|||||||||||||||__^\-,`                                 
                                                                                                                                                                          
                                                                                                                                                                          
                                                                                                                                                                          
                                                                                                                                                                          
                -"!!!!!!"`           `^!+!^`            `>"`                     ,|+!^`               '"!!!!!!!!_`      \!!!!!!!!^`          \!!!!!!!!>'`                 
            [email protected]       ?dmDHHHHHQmq1`       +MHHD7                ^[email protected]`        :nmBHHHHHHHHHBA,  ^[email protected]@F}      `TBHHHHHHHHHBMPe^              
          ,0BHHHMA000000qa'     \%HHHBWA0AXBHHHWt      lHHHHx              ,qRHHHMPZUXBHHH&7      `[email protected]%0000000wt  -mHHHX000000XHHHB1     `mHHHBA000%PMHHHQn`            
          0HHHBI`               [email protected]}     +WHHHM|     lHHHHx              dHHHBn`    >OHHHQ+     _MHHHb            |DHHHMmmmXXmMHHHD+     `mHHHR>     `2RHHBy            
          0HHHBu`               %HHH&+     "XHHHM>     lHHHHx              qHHHBx`    _GHHHR+     ~MHHHb            |DHHHMXXXXXXXG0l,      `mHHHR>     `zRHHH]            
          ,0BHHHMA0$$$$$dy:     ^[email protected]      }RHHHWq$$$$$$$u^    '[email protected]      ~MHHHb            :mHHHWq$$$$$$$$$e-     `mHHHBA$$$%[email protected]`            
            |[email protected]       cpWRHHHHHBWkl`        [email protected]      "nGMHHHHHB&Fl,       ,gBHQl             ^SMBHHHHHHHHHHHDj     `qBHHHHHHHHHBMGa~              
                '!++++++!`           ,|+++|,               \!+++++++!:          `^!++>-             ^+,                `^!+++++++++!,        \++++++++>\`                 
                                                                                                                                                                          
                                                                                                                                                                          
                                                                                                                                                                          
                                                                                                                                                                          
                  `\>+}}}}}}}}}}+\          ,!}+^              ~+}!`           '+}}}}}}}}}}}}}}}}!\`               \+}+`            _}71111111117t}!\`                    
              `+nGMBHHHHHHHHHHHHHBC`      `CDHHHBP_          >GBHHHM}        \[email protected]`          :[email protected]         _GBHHHHHHHHHHHHHHHBMGTv:                
            >%RHHHHHHHHHHHHHHHHHHH0`      -&HHHHHHl          zHHHHHH0        ~mHHHHHHHHHHHHHHHHHHHHHHHX!         iHHHHHHA         eHHHHHHHHHHHHHHHHHHHHHHB0|              
           5RHHHHHH&kI2zzzzzzzzzc!        -&HHHHHHl          zHHHHHH0         `!l22zzzzzzzzzzzz2hHHHHHHg         }HHHHHHA         [email protected]
[email protected]`                      -&[email protected]@HHHHHH0           ,[email protected]         }HHHHHHA         eHHHHHH0          `lMHHHHHRt            
          CHHHHHHI                        -&HHHHHHHHHHHHHHHHHHHHHHHH0         ^dMHHHHHHHHHHHHHHHHHHHHHHA         }HHHHHHA         eHHHHHH0            CHHHHHHn            
          zHHHHHHX+                       -&HHHHHHRMMMMMMMMMMRHHHHHH0        ^XHHHHHHRMMMMMMMMMMRHHHHHHA         }HHHHHHA         eHHHHHH0            CHHHHHHC            
           5RHHHHHH&kIzzzzzzzzzzc!        -&HHHHHHl          zHHHHHH0        +BHHHHHBazzzzzzzzzz%HHHHHHg         }HHHHHHA         eHHHHHH0            CHHHHHHC            
            >0QHHHHHHHHHHHHHHHHHHB0`      -&HHHHHHl          zHHHHHH0        `CBHHHHHHHHHHHHHHHHHHHHHHW+         iHHHHHHA         eHHHHHH0            CHHHHHHC            
              '[email protected]`      `0BHHHHX>          +&HHHHRv          !$&BHHHHHHHHHHHHHHHHBXC,          ^OHHHHRa         >XHHHHMc            +&[email protected]            
                 `'!jlzzzzzzzzzzl!          |vzl!`            `+lz7^             `^}lzzzzzzzzzzzzc+\              `"czc\           `!lzv,              `+lz}`             
                                                                                                                                                                          
                                                                                                                                                                          
----------------.-.-__-..-___-.---,_--_---.......'.--.''.-'-_----..!vy5$g0$D0R6ddOOdMMbMddbdOddZZdRD6OdRERZd6O69EORO6D6DRD0$0D0$OD90D6d6RED00$8Q8$$8Q88Q$gQQQ$gQB####$RMwx*^>^**^*^^^^^^^^^^>=^*^^*^^^**^^**^^^^;^^^>~;;^*^^^***^^^<^
---------------..-.-------.-.-.''.----__------.--``---..'..'.._"rybDDD00DEDgE6O66dOZMdMHdMZdddddMb6ZdddRR9dMRddddO66d6OR66R0$$$$O$D0gRdOER$$g888Q8g8$g8Qg8QQQggQBBB########$PT)rrrr^*^^^^^<^<~^***^^*^^^^^^^<^^^^<^^;>><^*^^^^*^^>~<^
.------------_--...-----------...'.-------_---..--'..``````'~}3E0g00D00g0EOR6OZ6dMbddOMWMdddddO6RZZd6dOR6O966ROd6OOddRR0OOR$0RD0EERR06d6DDg$$0Egg$D0$DD$008QQgQQBQBB###########Qd}*>^^^**^**^~^^^^^^^^*^^^^^^<^^^^^<^>^<^^^^^^*^**^^^
----------------..-.------.---....''----..-......'`..'``.*ydgg$g$0$$DE0$RE60O6MZMMdZddMMdMZ6ddOdOMMMd9ORdORDd6dd9ZZdZ66EOM6OEO696b6EDDDR9$D$$$0gg$$D6DR0g888888QBBBBB#BB##########BZc*^*<^^**^**^^^^**^^^***^^^^<>^^<<^^^^^^^^*rr^^^^
-----------------.-----_--___--.-..-.----.----.'`'.-..*3QQQQQ8$$8RE966dR6D66E66OZZdMMP5MddZdZdROZbdMdE6OOO666ZbO6MMMMd66d5MEddbdb69R99ORRR6E$g$g88E9E6Eg8QQg888QBBQQQBBQBB############$j)<^*^~<^~^*^r*^^**^^*^^^>~~~^^^^^^^^*^^^^^<>;
-----------------.---_-,-------''-_----_----....-.'.=bQBQQQ8gD$0E6966OEEOd6ddOROddbObdMMZZZdO6OZb6dGdOdO96ED6d69dMdRd6d66MdRddZMdO666$RDDEER0$gg$$0$0RD00gQ00QgBBQ8QQBQQBBB#BBB##########dY*^<*^<^^^*^~>^**^*^^<~~~>^^^^^^^^^^*^^>>>>
..-------------------_____----..-_-.''..-----_---.*O#BQQQg0D0000OdRO6bOOOd6OMddOObMMdZM5MW5MMO6dddMMdOdddZMdMM69OdbdR6ddddZR9O9Odddd6D6DD6RRDDg$EDDD6O0ggQ88888QQ8QQBQQQBBBBQB##B##########BK|^^^**^^^<>^^^^^^^<>>~;^^^^^^^^^^^^~~~~~
'..---....-----...._,"_-_-..--'.--.'`.'-...-....^ZBBBBQQQgg$g000DR066O6dZdbbdddbbdbMbddOdMMdddbbMdZMddZMMKHHMZdZKhkIUzwjjhPWMZdMMdbZOddR$DRDDD$RR$0D0Dgg88QQQQQQQg8BQQQQQQBB#BBBBB#BBB########K)***^^;~~><^^^^^^^^<;<^^^^^^^^^^^>;;;;
-_-----...---.....-_,_---..--....-.'`.---.---.=M##BBBQBBQgg$000$RRDRRRdbdbddMMdM5ddddMMG5MPMZMdMM665MzY\r>!:_'```````````-`````'."=*x}Vm6RE0$D69R$$g0E00g8Q8QQ88Q8gQ8QQQBQBBBB##BBBBBB######@@@#m|rr^;>;>^^^^^>>^^^^>><^^*^^^^^^^^>^>
.--------------...-__--..-.`.-.'`---_---.'.',yQ###BBBBQ888g0$$609D69ROOOdd6OddMMMd6MZdddbbdaZZIY)^:.``````````````` ``` `-` ``   ` ``'``'-:^vcd0RD$DD$$g88QQQQ8QgQ8QQ8QQBQQBBB##BQBB##B#B#####@##gx)*><<>><^^^<<^<><<^^^^^^^^^^^^****
_---.-----_--_-...--_---..'.----_:"-_---'`_}Q####BBBBQ8$88g800DOOODdddbZdMbOdddOR69OdOdd5Y*!_`````````````````````````` `'  ```````````````````.~vj6D$888QBQ$D$888gQQQQQQQQQQQBBBBQBBBBBBB########Qkx)***^^^**^^<;><^^^^^^>^^^^^^^^^^
_-_------------.-.------..--.---_,,--.``',P######BBBBQg$8gggD0066R6dOR9b6R9RbMdOR966mY*_`   ```````````````````````  `` ``  ````   ` ``````````    .~YM8QQQQgg88$gg8QQQQBBBBBQBBQBBBBBQB#B##########MTx)*^^**^^^<>^^^^^^^^^^^^^^*^^^^
-----------.---...-..``.-....__--_-----'^$######BBBQQQ$O$$$0$DE6R660R0E9OdORdZMdjx=.    ` ````````````````````````   `` ``   `````  ````````````  ```' .*k0QQQ88Qg88QQQBBBQQBQQBBQQBBBBB#############Ey}v)rr*^^^^^^^^<^^^^^<^^^^^^^^^
.--------...---....'`'.-.`--__-::,,_-`'Y########BQQQQ8g$g$g$g$$6Rdd0RRDZMdMMGV*_           ```````  ``   `` ``````````````  ````````````````   ```````   `'^I8QQQQQQQQBBBBQQBQQBQQQQB##B##############$jYx|r*^^^^^^^^^<^^^><^^^^^^^^^
------.'''...--.....___,---_":,=:_.'`-m#@###BBBQQQBQ8Q$8g8$0$6RE6dOdddRbddhr.      ` `  `````            ``````````   `````  `````'````````    ````````      'v$BBBQQQBBQQBBBQQQQQBBBBBBBBB##########@@0Uuix)***^^^^^^>^^<>>>^^^^^^^^
_--.'......''.....-_-___------.-,-``[email protected]@####BB#BQQBQ8$D888$0RDRObZdbbdRdu:``        ` ```````             ```            `   ``` `` ````````   `'````'``       `<aBBBBBBQQBBBQQQBQQQBBQBBB###B######@@@@0hVLx)rr***^^^^^^^>^^^*^^*^^*
---..---.......--.-_-___---...'[email protected]#######BBBBBQQ8QQ8$$$E0E66OOZddOm,`````               ````   ```    ``    `````          ````` ``````````````````           !3BB##BBQBBBQQQQBBBBBBBBB#########@@@@#dhVYxxv)r**^^>^^^^<<^*^^^^^^
------_----.---.-----__----.-.'`-``[email protected]@######BB#BBBBQQ8Q8g$gDE6OZdOOOK~``                      `````````  ``     `   ```         ```````````````````````             ,sB#####BBBBBBBBB#BQB############@@@@#MUVYxv)*rr^^^^**^^***^^^^<^
---------...-......--__-_--.-.'```:[email protected]@##########BBBQ88Qg8g$000RZOddL.                               `          `  ````           ```````'''`'..---_,_"::::::!!~>^**r)rkQ####B#BB####B###BB############@@@@8PXcL\)**r^^^>>^^^^^***^^^^
----------..--.--.--___,__--_-''``[email protected]@@@########B#BQQg88$g$0ER06Obk,```````    `````` ` `  ```'..''.-__-___,,,,,",_)xxii}T}x}}TcywyVVVyVjjkykkXyuVVcVyyyVyzyykkzkzzwyyyyk$########BBB#B##BB#B##########@@@@#b3XV}xvr*^*^<^^^^^^^*^**^^
-----------_------.---_,__"_-.'.`~#@@@@##########BQBQ88Q8$009D96k^~<>~~!!!!!!!:::!!!:!!!:,:!!!!:::!:!====!====~=!:YVcyTcuuuVTcykkyyVykykzyyyVyVTuVucyVucyzkyzyyzjjywkyVVVZ########BB###B#BBB####B#B##@#@@@@8GUkcYx|)**^^^^<^*^^*^^**^
--------_---__-...-_"_,__-.__---`[email protected]#@@@########BBBQQQQQ8$0$gg0DV<<^^<~^^~~~=~=!!======!!::!!!!:!:!::!========!==!:xVcucVuucuccVyVucyyzXwyzycuVyVyyccccVzkkzzyVcyyyyyyyyVuV3B########B##BQQ###BB#########@@@B5KIyu}xvr*^^*^^^^^^^****^
--------__---.'`.'.-,__---_"::---g#@#######B###BBQ8QQQ88888D$QK^^^^^>^>^>~~=!!:!==~==!!=!:!!!!!!:!!!==!=!!======!:rVVVyVcucccVVVckyzjyyyykyucwyyVycVywkzkyyVwVyyVyVVwykwkyzM#######BBBBBQB###B##########@@@#MPsy}xv|*r*rr*^*^^**^^***
---_---__-........---_---------.:Q#@#####BBBB###BQQ8Qgg88g0$g6\^^;^^<*^<^=!!!:::!!=~~==~!!!!!!::!!!=======!=!!!!!:^VVuccccVyywVcyyzzkzwwkzyyyyccccVyyyyVucyyyyyVyyyykkzyyyykmB#####BBBBBBBB###B########@@@@#bPUVYxxvr**)(|rrr********
-__--------..-..--..--.--.:__--.:[email protected]@@@##BBBBQBBBBQQQ88g80EDg0Y**<~^^^^^<~~!:!!!::!!=====!!!!!!::!!!!!!!===!=!==!!!^VyyVVyyVyyyVcucyjyykyVyyVVyVucVVVkykzyyyuukzmIzykwyVVyyyjwZ#######BB#B#####B########@@@@#ZGKz}Lx|*r*r)v\r*^**^^***
--_----.--.`'....._,-....._`````[email protected]@@@##B#BBB#BBQQQ8QD0DD$08j*r^~>^^<<^~==!!:!!!!=:!!=!!:!:::::::!!!!!!!!=!=====!:~cVykywjkzccuccVyyyVcuucyVucTccVcuVcVyyczwkzXUmjzzywVcVyywzzg#######B#######B#B######@@#@QMGKzcTLx)rr***rr)r^^*****
_----...-..````.--_-```..---_...'[email protected]@@@##B#BBB#BBQQQ888Q88QQRr**^>~=~~~~===!!!!=!:!:!!=!::!:::::::!!=!=!===!!=====!^ywjVywkzIzzykjVyyVVVccyVVVuywVyywhzVcVVzyyyzXzyywyyykykkVyks######BB####B###BBB####@@@@@0WGmzcTix\())^*rrr)*^^*^**
--....--.`'...''----'`---"=^>,[email protected]@@@#####BBBBQQBQQBBQ8888i><**^~!~=!=!=!====!!!::!!!!!!!:!!:::::!=!=!!=!=======!<VyVckkwkkykyykcyVcVVVycVcTVyyyykyyVVVVkkywXXzkkyyzUkkXIIIwjyZ#@######B####BQQBB###@@#@@#OMGmyuTxxv()r**rrrr***^^^^
.-_----_,:_____,_-____-~*~vxxx!":[email protected]@@@@#######BBQBBBBQ8Q8BK~<><~~<=!!!!::!!====!:::!!!!!!!:!!::::!!!!!=!!!!==~!!!!>ccVVywzIXzIkywVccuTTyVVywyVVVyykwkwkykzhIsKhzXXwkkjzywykkyjzyg#####BB###BBBQBBB####@@@@8OZGIc}xxxvr)r**rrrrr*****^
--__-----.---_-------_::":!-'-'[email protected]@@@@######BBBBBBBQ888Bx~;;!!=~!::::::!!!=!=!:!!!=!!==!!!!!!!!!!!:!==!=!==~!==!=TuVVkzUmsjzyVVccuVyVVVyVyVyVywzkwwzykIIXIzhIkIjyzIzyyVyywwkkyM##########BB#B########@@QEdMKyTLxxiv)*rrr))))r^***^^
-----...'`-___--_.-_-.":"_.````'``[email protected]@@@@#######B#BBQBBBQQm=~~=!!!!!!:,:::!!!!!!!::!!==!!~=!:!=!!!!!!!!!:!!!=~!!!!!!YcVVVjwykykyVVVyyyyyyyyyVyyykyyyyywkjkjIjyzwkjkkkkVwkzzyykkkyy###########BB########@#QROZHXu}ixxv|))r)rrrrrr**^**^
..---....'.-__-__-...._,..`````,_`[email protected]@@@@@########BBBBBQQx~~=!!!===~~!:!::!!!!!::!!!~~~~~!!!!==!!!!!!:!!!!!!==!!!!![email protected]#@@################@B$RdWhVu}xx||rr****^**r*rr*^*^
.--.....''.---_":",_.._,-__` `_"__"[email protected]@@@@######B####BBQM=~=!!!^vYyIU3PMMMMd9R9OdRER9dZMHmXy}xr~!!!!!!!!!!=!===!!!:ukzjIkwjkkyyyIaM9R$8BB##@@@@@@@@@@@@@@@@@@@###[email protected]@@@##@###########@@#Q$OMKyT}ivvv)rr***^^^*******^^
,_--''.'``._-_,,:!!:,____.```.__-_:_)#@@@@@##########BQBmxTyPDB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#Q0dPkY(~:!!!!==!:::uIjkIwjIM0QB#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@##[email protected]@@@@#@########@@@@#QgOZPjTxxx|vr)r***^***^*****^^^
----..-..-__,_:,::",_--_.`-`.-""-'-_-*#@@@@@@@########QO)v}kmWGHZO0QBB#####@@@@@@@@@@@@@@@@@@@@@@@@@@@@#BgGkY)~!:::VHZEDQ###@@@@@@@@@@@@@@@@###BB8BQBQBQBBBQ#######@@@@@@@@@##[email protected]@@@@@@@@@@###@@@@#Q$6MPXy}xv(()rr****^^^^^***^^^^^
----..-----____-__.-_.'.----___:,....-*[email protected]@@@@@@@#######I~*)x}T}yzhmMdMOdd6Dg0D$QQBBB#####@@@@@@@@@@@@@@@@@@@@@8m|:[email protected]@@@@@@@@@@@@@@@##BQg8Q8$96EDdOMb5bMZOdbD9E$gg$gg8g8g$$RdPIuk#@@@@@@@@@@@@#@@@@#Q$6MazyTixv)rr)*****^^^^^^^^^^^^^
-..------..--.-_--__-.``'-,-.-_,-._._..,[email protected]@@@@@@@@@@@@@}:~>\xixxx}uucVyyyzshhIKGMdZbZddddMbO$08gQQBQQQBBBQ88Q0My=-:[email protected]@@@@@@@@##[email protected]@@@@@@@@@@@@@@@#Qg6ZakuYxx\\(rrrr****^^^^^^^^^^^^^
....----..'''-------_-```.--.'-_--,-..-.,y#@@@@@@@@@@@@v"=>*x)|\\vxxxiLi}uTuTuVccVzIhIyVkwyjhhUyzUKsImaa3mI55PV)[email protected]@@@@##[email protected]@@@@@@@@@@@@@@#Q8Dd3wTYixxvvv)))****^^^^^^^^^^^^^^
---....--...-_-_---":_``..---::_.`.-'.---_^[email protected]@@@@@@@@@@v:!;^x(vxxxxYxxv|()xxvvxxxvxvxxv\xL}Lv(vvxi}TTL}VKOdsy}):.`[email protected]@@@@###[email protected]@@@@@@@@@@@@@#B8RbGkTixxv|()\vrrr*r*^^^^^^^^^^^^^^
.....-...---_"___!!::-.'-.--.----'`''.-'''-^[email protected]@@@@@@@@@):=^xz3HWPmc}xvxxvvxxxvxxvvv\(vxxvxxi\xxxiLLTzMDQB9uixr^"[email protected]@@###QDD8Q0RMKjyyucuccyuuuuuuucuuuuuuuTuT}[email protected]@@@@@@@@@@@#BQ89MPhuYLivv()))v|r*****^^**^^^^^^^^^
.....--.'.-_-_---_,__.``'.-----`---.```````'[email protected]@@@@@@@@\:~~^^r)uPR8B###Qg6MKhkVuTT}LLL}TcwImGZ9$8QB#BQ$Zyxr**^[email protected]@@@##[email protected]@@@@@@@@@@#B809MKyc}xx|))**)))rrr****^^^^<<^><^>^^
-.''.-..`.'.....-_,_---.'`````'`..'``````````[email protected]@@@@@@i~~!!!>*rviTkU5dD8BB###@@@@@@@@@@@@@##BQ8gROZsV})^^**^[email protected]@@@##BmcVVjImG5OD8B###############@@######[email protected]@@@@@@@@@#BQ0OZKy}Lx\|))r*rr)rr******^^^^^^^>>^>;>
**(r|(r^^r^^!_:_-.__---.```'...``.'``````````'[email protected]@@@@@c=^==!!^~^rvx}YVyhMb6RR$8QBBBB#BBQ880Rd5KhyTTY)**^~<~~!"-.``[email protected]@@####0T}TuVkzIsPMd$8QBB################[email protected]@@@@@@@@#B8DOHUwcixv)rrrrr**rr*****^^**^^^^<>;<;;<
xvxiLYi)rxxL)*xxvxvr)^;=:-...````'``'````````````[email protected]@@@s~!=~!!;<~***rvxiTcyXhPMZdO9DDER9ZG3zkzuYiv\r^~<;!~~=~!_-```[email protected]@@##BB#muu}}[email protected]@@@@@@##QgDMmkciix)r)rrr*******r**^^^^^^^^^>;~;~~~
xxxixiL))\xvr|xxLxv\v)v)\\\)^^^="-````````'```````[email protected]@@6!=!!:!=~<^^*<^r(vxY}TTVwVVcyyzIsjkVuxxxvr*^><>;==;~~!:_-.`[email protected]@@#[email protected]@@@@@@#BQg6bKyV}ix)rrrrrr**r*******^^*^^^^^<;;;;~!:
LxixxL}}}vxxx)xix|x(vx)\xvxxvxYvvx\*!:,.``.`````````[email protected]@#r=!!:!~~~;;~<*^(vxxLTTVjIhhmsXcLTTiix(|vxxvr^!!~^>~=::_-``.)#@@#QQ88#BV}TT}[email protected]@@@@##B8EOMmkuYxvv)**r*r***r****r***^^^^^^^^<<<~~:,
LxxvxYVT}ixTiriYixxvxvvxxxxxTuiv|vvxvxxxr^:-```'`````Y#@V!!==~~~~>~==~~~>vVwmbdPGd9EOMGcvyT|*r)vxxL}|;;^*<;=!"-.``.*#@##[email protected]}}[email protected]@@@##BB8RdGhkcTYxv)|***************^*^^^^^<^^^<>;;!,
xi}ii}c}Lxxxvxi}}YLYYxxxvxxY}uxvvxvv\vxxYixx)<:-.'''`'~$6==~~~~~~~~~==~^~xIhUHDg96E$09WTxVr^rvv|vxix)\*^>;!!:"-'```[email protected]##BQg$8B##ZYxixxLL}}}TTuu}[email protected]@@@##BQgEdGIyu}ixxv|)r******^*^^^***^^^^^^^<^^^<>;~=)
iiiLLT}LixixxLx}}iY}}xxxvxxi}Txxix\)(xYxY}YxvxLx^:.`'-_,Vx~~~;~==~~>~==~~>rYcyzmZ6ROGwixvv*****^**>=rr^;>~=~!_.`` `:g###BQ0g$Eg#@BKYLiLLiL}T}}TTuTYTuywyyyyuTTT}}TTuucVVuTuc5#@@@@#BB8gRZPUwVTYxxv\)r*^^^*^^*^^<***^^^^^^^^^^^^^>;^x}
}}ixxxxxxvvvxvxLTLiY}ixxiiiiY}Liixv\\xxiLLiixxxvvxxv^,--:~*^~~~=~~~~;>*;~^~~rTKMk))))vx\)Vr^^^^^>=~*)*^^~=:,,-.`  `-0###[email protected]@#RITxxiixxxxxLYTcucuTT}T}[email protected]@@@@#BQg06M3IyuYxxxvv))r^*^^^^^^^^>^*^^^^^^^^^^^^^^^)Y}}
Y}}xiLxxvxvxixLiLYL}YL}iLY}xYYx|Y\*rvxxxxixLxvxxxxxxix)>:-=r^~~=~;>~~^*~^^^>*)aP**rrr**rrxjur*)(r^**r*~~==:",-``   [email protected]##[email protected]@@##8d3zVTYL}}}iLYYiYLLYYiLL}}}TT}LyM$#@@@@@@#Q8g06ZPjyc}xxx\\|)rr^^^^^^^^^^^^^^^^^^^^^^^^^^^xxiiL
ixLiLLx\)|)xL|xxiii}Y}uY}uYvLx)x)xixvvxvxvxxvvvixxvvx}Lxxr^~(**;;<>>;~;;;~;<^*x((vL}LxxxiysMD6mr*)***^~!:!:"_.`   `[email protected]#BBQ06dZWPGRB#@B$$g88QB#BQ8DdGswVuT}}u}TTukaM0Q#@@@@@@@@@#BgDOd5IwVuYLxvv))rr**^^^^<^^^^^^^^^^^^^^^^^^^^(xiiuyT
xiLLLxv)|xxxxxxxiixxxLLviiir(Lxi*ix)vxiiLxvvxxxiLiiLTTxxxix)^r^<^^<~~~~~~~;~^^*^)xyZDgQQBB####G~^**^^^!!!!",_'`   `[email protected]##BQg6EMGmIhZg#@BZGGGGHMbO0QB#@@@##BBBB##@@@@@@@@@@@@@@@BQgEOMHsyyu}Yxv\|rr****^;>^^^^^^^<^^^^^^*^<<^^*x}uTTVcu
xi}Lxxv)\xxxxxixxixixx}ixv|TYxx)vTv)\xLL}LxxxiLiLLxxxvvvixxxxrrr^^*;>^~~~!=~;<^*^ricysMddRB6ZT!_`-<*^;;=!!:,_`     'V###BQ$065aUjyymMB##dhIUUsUssmPHGMR8B#@@@@@@@@@@@@@@@@@@@B8$RdMahyuuTLxv)r))))*****^^^^^^^^^>^^^^^^^^^*xyyVcVyuVc
xxLxxx\\|vviLixixx\xv\|r|(|i)*xiLiv)}TLYLxiixxxxiYxxxxixxYiYi}))*^**^^^~;~>~;**^^^|xi}yyXO$Kx=,.``_rYi*<~=:,_'  ```'T###BB8DbPXzyycVkGg##[email protected]@@@@@@@@@@@@@#Qg06dWKjkyu}ixv\())r*******^*^^^^^^^^****^^^^(YucVVyycuuu
xvxxvv(vvv\|xixvxxvxx)vv|^xxvrr*iucuTixY}LxxixxxxxxvviLLiL}x}T}v****^^*;~;^^**^^^^***)v)xPKr,_-.'`[email protected]@@#Mk###Q8RDPjuT}xxx}TkR##[email protected]@@@@@@@@@@#Qg$RdMKUzVu}ixvv\)rrr*r****^^^^*^^^^^^^***^*vTcT}TyyVVyVVc
vvxv\|\vxxxvvxvixvxxxvxxLY}iiYLuccT}TxxLL}}}TYivvxxvviLxLxii}LYyLr)()r*)*>~~)x*^*r^>^**^*h~---'.````.,(kRB###@@@@@@@###QQ6ZKVYLiv\**)xVwWB##[email protected]@@@@@@@@@BQg06ZM3yV}}Lixv||)rrrr*******^^*^^^*^**^***(}TTVTTVyyycVuVV
)xxv||)\|vvxxxLYLiLLv|)\LY}xLLLxxcVuV}}cVVcuyy}LiLYLxYiixxi}YLLYTxxxvxv)*^^^*xrr^^*~>^^r\<---'```````.,!*m$QB######BBQ80EHkuYvvvv*^*^|}cIZ###dkywkXjhIXIssssP$#@@@@@@@@#Qg$EOM3Uy}}Yxxv\(r)))r*rrr***^*^^^^^***^^**rYcVccuTT}TVVVVyVT
xxxv)v\xvxixYLY}i}}xv(|xLLixii}xxwc}uVucTccVVivxv\vx\v))(xvvxiiiTcxx}Lv)r***^vx**r*^*^^^(..-.```````'..'.,^YMR08g0R6Od6MPVTxv\)|r*^*^*v}uj6B##[email protected]@@@@@@@@@B8$09dPXzyuLixxv())rr*rr******^^^^^^^^**^^^*vuuccVyVcTTVyVVVyu}
vvvv|vvxxL}}TuVcxTTix|vxYxxYxxxvvVVuVTY}TuucLxxv|vxvvix(xxvvv\xxTc}vxLx||r)\)vx*))*^*^**"'..```````'`.--'``._^izGMMMaWGUzux\()***^^^;^r|Yz3MQ###QEOdODgQ##@@@@@@@@@@@Bg$06ZaIVuT}xvxv|)rrr***********^**^^^^^^^^|LuVycVcccuuTuTTVccuu
vxv|vxLixxx}}u}ixxiYvvLiivLiLYLxv}cTYTYYYTu}ixxx}YixLTixxxxxvxxLuVjui}YLxv(())vrrr*^*^^_'``````` ``````` `'`_:~)VPPG3XkcTLxv)\(|vr^*^^vvxYj5a0B#B#########@@@@@@@@@#8E99dMUycTYLxx(|)r))r***r*******^^^****^^^ricVTuuVucTucuuuTuTTTVV
(|(\(xixxxvxxYLLxxxLxx}}YLui}TixviT}xLYYiYixiLxxYLixi}LLiivxiiiTTycTVYi}Yxxvrrvr*(^^^^_`````_=rvxiLi}TucVkPb0QBBBBB##BBBQ$9dMGMZMKXIKadddddWIkMBBBBB#######@@@@@@@#$96OM3XycTYLixxrrrrrrr*********^*^^^^^^^^)YuVyVTuVVVVuuuTuTTT}uuVc
)|\vvY}xvvxxxxxxxYxxxxiLixiviT}}xiLixYLi}TixLYxxixxxxiLxxxxxvxxLLu}x0KL}iLYxv)x)rr**^_.```````.~TGbd66OOd6R6D090000$0g8ggg0DDg0dE$QBB$0dGMUccyVsQBQBB######@@@@@#QD6dM5skVTYLixix\)rr*************^^^^^^^^)iTuTcyyVcTuVuccT}}}uVcTuTu
(\vxxL}vvxvvxxvxxxv)vxvxx\vvx\vxxxxvxLiLLYxvxYxxxxxxxxix\vvvxYivx}}x8#dxxLix((v)r*^^_'.`````````-,^xkK3GKKmKPKHMMZMbZbZGHGG35ZO08g6ddM5KIkyuTVycdQBB##B###@@@@@#8EOdMmXycuYixixxxx)*rr*************^*^^^riYYYuTu}}VcuccTcVuYLTyuVTTuV
xvv\vxLxxxxx|v\vvxx|\xLxxx))vvv()(v\LY}}LYixiY}YxxxxxxYxvxLL}}[email protected]@ZiLxxr)v)r))_```````````''._:=^vTykXIjImKKmsPGHmjhI3dgQQQ86MGKXzyykVTucyyk8BB#####@@@@#Q0Rb53hkc}Lixxvvv)(\r*r***r*********^^^^rLL}}T}LxY}}}iLxYYYTuiTuV}Y}}Tu
v\)|vxivixiLvvvvxxxvvxYLxvr)ixLxxixxxxxxxxixiiiixxY}Lx}[email protected]@@R}x()vv)vr~```````````'--::~rvYya5MMMPPPaKmPHGMd0QB80dWHjyYTuT}LuVu}TuyXzZ#B####@@@#B8$9d53szuYLxxvvv\v))()rr*rr********^^^^rxixiLxxYT}xYvvxixixiiYLTuTYT}TcV
xvvxxxi\vxxixxxixxi)v}TLxixxxvxvxLLiixxxxxxYYxxxxxxxLiiixL}xLLiYYxxV#@@@@#dL)||xvr:`''``'```'.-.-__::~\iLTzzMM$0g8QQB#BBQ09ZdscTL}YYTTiYYY}uTTTyyPBB##@@@#BQg0RbGhzyV}xxvv\vv|\|)rr*********^****^*vixxxixxvY}TTuVVuTTuYL}uYTT}Tcu}}T
LxvxxiixvxxxxixiiLixiiYxxLixvxLxxLiLLiixxxxYixxxvLxvxxxxxxxvvxxvxxxV#@@@@@@#dLrxv^"'``'''''```''-_-__,:!~^*)v(kTTykVM9d5G3sXy}YYYixxiixxx}xV}c}ywKB#@@@#BQ8g06ZKXzV}YLxxvvv|r)rrrrr**********^*^)xVuTuu}}Yxxxi}uuT}cuY}TYYT}}YuuYYLiY
xxxxxx[email protected]@@@@@@@@8z:`'----'...``````````----!=:>^r^*(r*TkyykjVcTLLiYYix}[email protected]@#BQQ8g09d5azVuTLxxvv(\|r)\r*rrrr**^*******vYTTTcucuLYLTLx}TYuyVVcT}TuYTTLYYu}}Lxi
vv\vxxvxxxxxxxLxxxiYYxvY}xr\ixxLxxxxLixxxxx}}Yivxxixxxx\[email protected]@@@@@@@@@@#M)-..-.`.'``````````'...-_,:":!!!!:xTxxLiYLYixxxvxxYYiiiY}T}yksd##QQ8g0DRO5mjkuT}Lxxv\\())rr))*****r*^***rxTuTucuYLY}}YY}LxY}TcTTuTTYLL}}T}YLY}}Y}YY
xxxxxLxxiixLYxiYT}xYvr*Lv~^\xvxLxxxxxxxixvx}}YLxxxxxxxxvxxxxxxi}iixxX#@@@@@@@@@@@@@BP\,.'.-.```````'`.-.-..__-,!::=:)Lxxx\vxv*)*rrr)vx}u}TVwkIDBBQQ8g$DROMPhVuTYiixvvv|)rr)r)r*******^^*vxY}uY}uuTYYu}LxxiLii}T}Y}}xiiLY}}}}}}LY}}T}Y
vvxxixxL}u}}Y}TYr)cTY*rx*r|ixxxxLiLxiLiixiLYT}[email protected]@@@@@@@@@@@@@@@@gz^_..``````''._--..-.-,",_:"~xvvxvv|()xr*xvxiYuT}TVM8#BQQQ8gDdbMHhkc}}}xxxvv)(v||rrrrr*^^****v}VyuuTT}ucuVcTxixxYxi}TcVVyycuxLiL}}uu}TTu}TTT}
ixiYLLiLYT}LiiYY\!Lxv)}v!rvLxxiixiixxxixxiYYuYYxvv(vvvxxiLixx}[email protected]@@@@@@@@@@@@@@@@@@BZVr"```....--.----_"_-,,,!xxvv(vx|xxviui}i}TwdQ##QQQQ80D6MHmKUVu}Yixxxv|)r()r))r*^***^*vLTYYuVcTuVT}TVuc}}}vxux}}YucuTuTLLiY}YTuTY}uuccTTY
xxLLixLLLY}xrr|x}k*Yc)}vvux*YiL}[email protected]@@@@@@@@@@@@@@@@@@@@@@#$HVx^:----_---_,___,"v(xvxvxvxxxwzKd0Q#@#Qgg88g09dMamjyccTLxxvvvv\)r*rrrr*rr*r(x}u}}T}YL}uuYuTTuVu}}yuLTcYuTLY}Y}u}TxL}ixTuTLuTTT}Tui
LiiiLYixL}cuxxxL~LivvriVu}LxiiLxxxxxxxxvvxxxxxxxxxxxxixxxLLxxxvxxxxxxxviM#@@@@@@@@@@@@@@@@@@@@@@@@@@##Q8D6GhTLiiLYYTVMMMd6D8QB##@@@@@@@Bg888$0EOMGmjkc}Yxiix\\\||()r****r)\vxxiTYiYTLLL}YYYx}Tiiu}YLYLiLuTY}}Y}VVTLTTuTLLYY}}}}}uu}YY
cVuLxxY}}}Tu}T}}uvv)>x}LxiLY}x^(}}ixiYixxxxxLLxxxxxvxxxxLLLxxxv|[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@#######@@@@@@@@@@@@@@@@@@@@@@@@@@Qg8g$0RdGKmXwuT}ixxv|\)())rr)))|xixLxxixYu}xxTT}TTYTY\LT}TTT}LixvxYY}xLYT}}T}YiiLLYYTT}TuVkcuc}
uTTLiYLxvxixx)))}TcviL})*TuxxxvY}YiLxiLxxxxxxxxxxxvxxxvvxiixxxxxxxxxixxLxxxy$#@@@@@@@@@@@@@@@@@@@@@@@#######@@@@@@@@@@@@@@@@@@@@@@@@#88g0DRd5PhwyuT}Lixxvv\|))r)))r\vxvvxxxxLiLLixxTc}}}TTYxTTx}}cT}xxxL}uY}TixvL}}uT}uVVcu}TccuyyuTT
uVTxucuurrxT}}}i)cx^*x*}xxTYi)*vxxvxxLYixxxxLLxxiixxvxxxxxxxxLxLiLi}}iiixxxxLVO#@@@@@@@@@@@@@@@@@@@@@#############@#####@@@@@@@@@@@Bg$DRdM5PPIwuu}Yixxxxv\\|))))))r))r)vi}xiiiiu}xx}}LY}YTTY}TVTuyuuTYL}uTuVcVcTucuy}TTVuuTT}cVyyVcyu
YT}YixT}Lxv}TTxvL}Yx*)*vuui)rvxLT}ixxxxxxLL}[email protected]@@@@@@@@@@@@@@@@@@BQBBBB##############@@@@@@@@@B00RdMW3mIwVuT}ixxxxxxvv||)))))r)rr)r**v(xxi}YxxxxTYY}uc}L}uccyuT}iiY}ucyuuuccTucccccTTcc}}TcyyVcVc
xT}}}}Y}uYv^L}xu(i=*T)xL|xvxiLL}uixvi}ixxxxxxxxLiLiixxxxxxxxxiixxx|xxxxvxixixLYYYYj0#@@@@@@@@@@@@@@@@B8QQQQQQBBB###BBBB###@@@@@@@BD9d5GPmIkyuLxxxvxxvvvvv\)))()r))r***rr)*^*vvxiLxxYYY}TT}YYTuVuTVTYLYYTT}TTT}L}}TuuuuuuTTcT}VVuVyyVV
Tuu}YLiTucyiT|vuci\xi^x}L}xvL}[email protected]@@@@@@@@@@@@@#g$g8888QQQQBBQBBBB###@@@@@@DbMGGKUkVu}Yixxxvvx\vvv\)r())rrrr***r)|)^^**^^*vLi}}}uuuTTY}uV}uVu}L}Y}}}}u}}i}}LLYuVuVVTTuTuVVyyVVV
Tu}LYLxiTuuT}}v*T*rTy)vvTVVkTLY}YiLiixxLixixxvvxxiLxxxxxxxxxxvvxvv\vvxLxvvxxiLixxxxYYTuzO#@@@@@@@@@@@@g0$$$g$$$$gg888QQQBB##@@@@BdbPmXyVT}}Lxxvvvxvvv)\|\vv|\()rrrr)rv(\*^<<><;~~>*\LuT}TLLi}u}TTuYYLYY}}cTTTcTucucuuyuYuccucyyVccTuV                                                                                                                                                                          
                                                                                                                                                                          
                                                                                                                                                                          
                                                                                                                                                                          
*/

pragma solidity >=0.7.0 <0.9.0;




contract CubismCharm is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.00 ether;
  uint256 public maxSupply = 1050;
  uint256 public maxMintAmountPerTx = 1050;

  bool public paused = true;
  bool public revealed = false;

  constructor() ERC721("Cubism Charm", "CCM") {
    setHiddenMetadataUri("ipfs://bafybeifhe6snt6oz5ftf6ywagrrrziivhqorymvpdyh2nza54sff3lkazy/");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

    _mintLoop(msg.sender, _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    // =============================================================================
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}