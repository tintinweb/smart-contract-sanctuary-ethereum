/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: @openzeppelin/contracts/utils/Base64.sol


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

// File: Interfaces.sol


pragma solidity ^0.8.17;


interface IMainContract {
    
    function getNickName(uint16 tokenId) external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function getRewardContract() external view returns (address);
}

interface ITraitChangeCost {
    struct TraitChangeCost {
        uint8 minValue;
        uint8 maxValue;
        bool allowed;
        uint32 changeCostEthMillis;
        uint32 increaseStepCostEthMillis;
        uint32 decreaseStepCostEthMillis;
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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: TokenUriLogicContract.sol


pragma solidity ^0.8.17;





contract TokenUriLogicContract is Ownable, ITraitChangeCost {
    using Strings for uint256;

    IMainContract public MainContract;

    //bool _revealed = false;
    //string private _contractUri = "https://rubykitties.tk/MBBcontractUri";
    //string private _baseRevealedUri = "https://rubykitties.tk/kitties/";
    //string private _baseNotRevealedUri = "https://rubykitties.tk/kitties/";
    mapping(uint8 => TraitChangeCost) public TraitChangeCosts;    
    mapping(uint16 => uint64) public TokenIdDNA;

    constructor(address maincontract) {
        MainContract = IMainContract(maincontract);
        // setChageTraitPrice(uint8 traitId,
        //      bool allowed, uint32 changeCostEthMillis,
        //      uint32 increaseStepCostEthMillis, uint32 decreaseStepCostEthMillis,
        //      uint8 minValue, uint8 maxValue)
        //setChageTraitPrice(0, true, 100, 0, 0, 0, 255); // undef
        setChageTraitPrice(1, true, 0, 100 * 1000, 0, 0, 4); // type
        setChageTraitPrice(2, true, 0, 50 * 1000, 0, 0, 2); // eyes
        setChageTraitPrice(3, true, 0, 20 * 1000, 0, 0, 3); // beak
        setChageTraitPrice(4, true, 10 * 1000, 0, 0, 0, 255); // throat
        setChageTraitPrice(5, true, 10 * 1000, 0, 0, 0, 255); // head
        setChageTraitPrice(6, true, 0, 5 * 1000, 0, 0, 255); // level
        setChageTraitPrice(7, true, 0, 5 * 1000, 0, 0, 255); // stamina
    }

    function cloneTokenUriLogic(address tokenUriLogic) external onlyOwner {
        uint16 i = 1;
        while (TokenUriLogicContract(tokenUriLogic).TokenIdDNA(i) > 0) {
            TokenIdDNA[i] = TokenUriLogicContract(tokenUriLogic).TokenIdDNA(i);
            i = i+1;
        }
    }    

    function setChageTraitPrice(
        uint8 traitId,
        bool allowed,
        uint32 changeCostEthMillis,
        uint32 increaseStepCostEthMillis,
        uint32 decreaseStepCostEthMillis,
        uint8 minValue,
        uint8 maxValue
    ) internal {
        require(msg.sender == address(MainContract) || msg.sender == owner());
        require(traitId < 8, "trait err");
        TraitChangeCost memory tc = TraitChangeCost(
            minValue,
            maxValue,
            allowed,
            changeCostEthMillis,
            increaseStepCostEthMillis,
            decreaseStepCostEthMillis
        );
        TraitChangeCosts[traitId] = tc;
    }

    function randInitTokenDNA(uint16 tokenId) external {
        require(msg.sender == address(MainContract));
        uint256 rand = (uint256)(keccak256(abi.encodePacked(block.timestamp,msg.sender,tokenId)));
        uint32 randL32 = uint32(rand & uint64(0x00000000FFFFFFFF));
        uint32 randH32 = (uint32)((rand & uint64(0xFFFFFFFF00000000)) >> 32);
        // offset 0 undef
        // offset 1 type
        // offset 2 eyes
        // offset 3 beak
        // offset 4 throat
        // offset 5 head
        // offset 6 level
        // offset 7 stamina
        uint64 dnaeye = randL32 % 1000;
        if (dnaeye <= 47)
            dnaeye = uint64(randL32 & uint32(0x00FF0000));
        else
            dnaeye = 0;
        uint64 dnabeak = (randH32 % 1000);
        if (dnabeak <= 7) dnabeak = ((3) << (3 * 8));
        else if (dnabeak <= 47) dnabeak = ((2) << (3 * 8));
        else if (dnabeak <= 500) dnabeak = ((1) << (3 * 8));
        else dnabeak = 0;        
        uint64 dnathroat = uint64(randL32 & uint32(0x000000FF)) << (4 * 8);
        uint64 dnahead = uint64(randL32 & uint32(0x0000FF00)) << (4 * 8);
        uint64 dnatype = uint64((uint64(randL32) + uint64(randH32)) % 1000);
        if (dnatype <= 5) dnatype = ((4) << (1 * 8));
        else if (dnatype <= 40) dnatype = ((3) << (1 * 8));
        else if (dnatype <= 100) dnatype = ((2) << (1 * 8));
        else if (dnatype <= 250) dnatype = ((1) << (1 * 8));
        else dnatype = 0;        
        TokenIdDNA[tokenId] = (dnaeye + dnabeak + dnathroat + dnahead + dnatype);
    }

    function getTraitValues(uint16 tokenId)
        internal
        view
        returns (uint8[] memory)
    {
        uint64 oldvalue = TokenIdDNA[tokenId];
        uint64 TRAIT_MASK = 255;
        uint8[] memory traits = new uint8[](8);
        for (uint256 i = 0; i < 8; ) {
            unchecked {            
                uint64 shift = uint64(8 * i);
                uint64 bitMask = (TRAIT_MASK << shift);
                uint64 value = ((oldvalue & bitMask) >> shift);
                traits[i] = uint8(value);
                i++;
            }
        }
        return traits;
    }

    function getTraitValue(uint16 tokenId, uint8 traitId)
        public
        view
        returns (uint8)
    {
        require(traitId < 8, "trait err");
        return getTraitValues(tokenId)[traitId];
    }

    function getTraitCost(uint8 traitId)
        public
        view
        returns (TraitChangeCost memory)
    {
        require(traitId < 8, "trait err");
        return TraitChangeCosts[traitId];
    }

    function setTraitValue(
        uint16 tokenId,
        uint8 traitId,
        uint8 traitValue
    ) public {
        require(msg.sender == address(MainContract));
        require(traitId < 8, "trait err");
        uint64 newvalue = traitValue;
        newvalue = newvalue << (8 * traitId);
        uint64 oldvalue = TokenIdDNA[tokenId];
        uint64 TRAIT_MASK = 255;
        for (uint256 i = 0; i < 8; ) {
            unchecked {
                if (i != traitId) {
                    uint64 shift = uint64(8 * i);
                    uint64 bitMask = TRAIT_MASK << shift;
                    uint64 value = (oldvalue & bitMask);
                    newvalue |= value;
                }
                i++;
            }
        }
        TokenIdDNA[tokenId] = newvalue;
    }

    function getRgbFromTraitVal(uint8 traitval)
        internal/*public*/
        pure
        returns (bytes memory)
    {
        uint256 r = (traitval >> 5);
        r = (r * 255) / 7;
        uint256 gmask = 7; // 0x07
        uint256 g = (traitval >> 2);
        g = (g & gmask);
        g = (g * 255) / 7;
        uint256 bmask = 3; // 0x03
        uint256 b = (traitval & bmask);
        b = (b * 255) / 3;
        return
            bytes.concat(
                "rgb(",
                bytes(Strings.toString(r & 255)),
                ",",
                bytes(Strings.toString(g & 255)),
                ",",
                bytes(Strings.toString(b & 255)),
                ")"
            );
    }

    function getBirdEyes()
        internal
        pure
        returns (
            /*bool crazy*/
            bytes memory
        )
    {
        return
            bytes.concat(
                '<rect class="ew" x="275" y="200" width="40" height="40" rx="3" stroke-width="0.25%" />',
                '<rect class="ey" x="275" y="220" width="20" height="20" rx="3" stroke-width="0.25%" />',
                '<rect class="ew" x="215" y="200" width="40" height="40" rx="3" stroke-width="0.25%" />',
                '<rect class="ey" x="215" y="220" width="20" height="20" rx="3" stroke-width="0.25%" />'
            );
    }

    function getBirdLayout(uint8 shapetype, bytes memory filterRef)
        internal
        pure
        returns (bytes memory)
    {
        if (shapetype == 0) {
            // basic
            return
                bytes.concat(
                    '<path class="hd" d="M170,480l0,-90l-35,-50l0,-155l45,-69l40,-30l46,0l55,60l0,190l-5,0l0,40l-40,40l0,65" stroke-width="2%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="th" d="M193,480l0,-99l30,-45l91,0l0,39l-40,40l0,66" stroke-width="0.15%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="bk" d="M235,275l110,0l20,25l0,80l-10,-25l-120,0" stroke-width="2%" ', filterRef, '/>'
                );
        } else if (shapetype == 1) {
            // jay
            return
                bytes.concat(
                    '<path class="hd" d="M170,480 l0,-90l-35,-50l0,-155l-60,-120l140,0l20,5l80,80l6,10l0,176l-5,0l0,40l-40,40l0,65" stroke-width="2%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="th" d="M193,480l0,-99l30,-45l91,0l0,39l-40,40l0,66" stroke-width="0.15%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="bk" d="M235,275l110,0l20,25l0,80l-10,-25l-120,0" stroke-width="2%" ', filterRef, '/>'
                );
        } else if (shapetype == 2) {
            // whoodpecker
            return
                bytes.concat(
                    '<path class="hd" d="M170,480 l0,-90l-35,-50l0,-155l45,-69l40,-30l46,0l55,60l0,190l-5,0l0,40l-40,40l0,65" stroke-width="2%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="th" d="M193,480l0,-99l30,-45l91,0l0,39l-40,40l0,66" stroke-width="0.15%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="bk" d="M245,285l225,0l-20,25l-75,35l-130,0" stroke-width="2%" ', filterRef, '/>'
                );
        } else if (shapetype == 3) {
            // eagle
            return
                bytes.concat(
                    '<path class="hd" d="M170,480 l0,-90l-35,-50l0,-155l45,-69l40,-30l46,0l55,60l0,190l-5,0l0,40l-40,40l0,65" stroke-width="2%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="th" d="M172,480l0,-70l102,20l0,51" stroke-width="0.15%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="bk" d="M235,270l100,0l40,35l0,80l-20,-25l-120,0" stroke-width="2%" ', filterRef, '/>'
                );
        }
        /*if (shapetype == 4)*/
        else {
            // cockatoo
            return
                bytes.concat(
                    '<path class="hd" d="M170,480l0,-90l-35,-50l0,-115l25,-49l60,-25l60,0l41,30l0,155l-5,0l0,40l-40,40l0,65" stroke-width="0.15%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="cr" d="M321,181l0,-50l5,-50l10,-50l10,-20l0-5l-5,0l-30,10l-30,30l-12,30l-10,30l-2,25l1,-15l-30,-30l0,-50l3,-20l-10,0l-10,5l-25,35l0,70l5,20l-5,-20l-30,-10l-10,-10l-10,-30l0,-20l-10,0l-15,20l-5,30l0,20l10,20l40,40l-10,-10l-40,0l-40,-10l-5,0l0,10l20,25l20,10l20,10l14,55l20,-60l50,-45l60,-10l29,0l15,11z" stroke-width="0.15%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="th" d="M193,480l0,-99l30,-45l91,0l0,39l-40,40l0,66" stroke-width="0.15%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="ol" d="M275,481l0,-65l40,-40l0,-40l5,0l0,-205l5,-50l10,-50l10,-20l0-5l-5,0l-30,10l-30,30l-12,30l-10,30l-2,25l1,-15l-30,-30l0,-50l3,-20l-10,0l-10,5l-25,35l0,70l5,20l-5,-20l-30,-10l-10,-10l-10,-30l0,-20l-10,0l-15,20l-5,30l0,20l10,20l40,40l-10,-10l-40,0l-40,-10l-5,0l0,10l20,25l20,10l20,10l14,55l0,63l35,50l0,91M118,220l10,5" stroke-width="2%" stroke-linejoin="round" ', filterRef, '/>',
                    '<path class="bk" d="M235,275l110,0l20,25l0,60l-10,-25l-20,0l-15,25l-85,0" stroke-width="2%" ', filterRef, '/>'
                );
        }
    }

    function generateCharacterFilter(uint16 ownedcount)
        internal
        pure
        returns (bytes memory)
    {
        uint256 irr = 10 + ((ownedcount > 50) ? 50 : ownedcount);
        return
            bytes.concat(
                '<filter id="sofGlow" height="300%" width="300%" x="-75%" y="-75%">', // <!--Thicken out the original shape-->
                '<feMorphology operator="dilate" radius="4" in="SourceAlpha" result="thicken"/>', // <!--Use a gaussian blur to create the soft blurriness of the glow-->
                '<feGaussianBlur in="thicken" stdDeviation="',
                bytes(irr.toString()),
                '" result="blurred"/>', // <!--Change the colour-->
                '<feFlood flood-color="rgb(0,186,255)" result="glowColor"/>', // <!--Color in the glows-->
                '<feComposite in="glowColor" in2="blurred" operator="in" result="softGlow_colored"/>', //<!--Layer the effects together-->
                '<feMerge><feMergeNode in="softGlow_colored"/> <feMergeNode in="SourceGraphic"/></feMerge>',
                "</filter>"
            );
    }

    function generateCharacterStyles(
        bool nightly,
        bytes memory eycolor,
        bytes memory ewcolor,
        bytes memory beakColor,
        bytes memory throatColor,
        bytes memory headColor
    ) internal pure returns (bytes memory) {
        //bytes memory filterRef = "";
        //if (nightly) {
        //    filterRef = bytes(';filter="url(#sofGlow)"');
        //}
        bytes memory p1 = bytes.concat(
            //<style type="text/css">.hd{fill:rgb(138,28,94);}.ew{fill:rgb(240,248,255);}.th, .cr {fill:rgb(8,32,220);}.bk{fill:rgb(152,152,152);}.ol{fill:rgba(0,0,0,0);}</style>
            '<style type="text/css">.hd{fill:',
            headColor,
            ";stroke:",
            (nightly ? headColor : bytes("black")),
            //filterRef,
            ";}.ey{fill:",
            eycolor,
            ";stroke:",
            /*nightly ? getRgbFromTraitVal(traits[5]) :*/
            bytes("black"),
            //filterRef,
            ";}.ew{fill:",
            ewcolor,
            ";stroke:",
            /*(nightly ? ewcolor : bytes("black")*/
            bytes("black")//,
            //filterRef
        );
        bytes memory p2 = bytes.concat(
            ";}.th, .cr {fill:",
            throatColor,
            ";stroke:",
            (nightly ? throatColor : bytes("black")),
            //filterRef,
            ";}.bk{fill:",
            beakColor,
            ";stroke:",
            (nightly ? beakColor : bytes("black")),
            //filterRef,
            ";}.ol{fill:rgba(0,0,0,0);}</style>"
        );
        return bytes.concat(p1, p2);
    }

    function generateCharacterSvg(
        uint16 tokenId,
        bool nightly,
        uint16 ownedcount
    ) internal view returns (bytes memory) {
        uint8[] memory traits = getTraitValues(tokenId);
        bytes memory eycolor = "rgb(0, 0, 0)";
        bytes memory ewcolor = "rgb(240,248,255)";
        if (traits[2] != 0) {
            eycolor = "rgb(154, 0, 0)";
            ewcolor = getRgbFromTraitVal(traits[2]);
        }
        bytes memory beakColor = "grey";
        if (traits[3] == 1) beakColor = "gold";
        else if (traits[3] == 2) beakColor = "red";
        else if (traits[3] == 3) beakColor = "black";
        return
            bytes.concat(
                generateCharacterStyles(
                    nightly,
                    eycolor,
                    ewcolor,
                    beakColor,
                    getRgbFromTraitVal(traits[4]),
                    getRgbFromTraitVal(traits[5])
                ),
                (nightly ? generateCharacterFilter(ownedcount) : bytes(" ")),
                getBirdLayout(getTraitValue(tokenId, 1), ((nightly) ? bytes(' filter="url(#sofGlow)" ') : bytes(" "))),
                getBirdEyes()
            );
    }

    function generateCharacter(uint16 tokenId, uint16 ownedcount)
        internal/*public*/
        view
        returns (bytes memory)
    {
        uint256 dayHour = (block.timestamp % 86400) / 3600;
        bool isNight = ((dayHour >= 21) || (dayHour <= 4));
        bytes memory svg = bytes.concat(
            '<?xml version="1.0" encoding="UTF-8"?>',
            '<svg x="0px" y="0px" viewBox="0 0 480 480" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" version="1.1" preserveAspectRatio="xMinYMin meet">',
            '<rect x="0" y="0" width="480" height="480" fill="',
            (isNight ? bytes("rgb(8,42,97)") : bytes("rgb(238,238,238)")),
            '" />',
            generateCharacterSvg(tokenId, isNight, ownedcount),
            "</svg>"
        );
        return
            bytes.concat(
                "data:image/svg+xml;base64,",
                bytes(Base64.encode(svg))
            );
    }

    function getColorMapName(uint8 colourVal)
        internal/*public*/
        pure
        returns (bytes memory)
    {
        uint8[256] memory colourList = [uint8(98), 110, 110, 66, 98, 110, 110, 66, 103, 116, 116, 66, 103, 116, 116, 66, 103, 116, 116, 97, 
                                        103, 116, 116, 97, 108, 108, 97, 97, 108, 108, 97, 97, 98, 110, 110, 66, 98, 110, 110, 66, 103, 116, 
                                        116, 66, 103, 116, 116, 66, 103, 116, 116, 97, 103, 116, 116, 97, 108, 108, 97, 97, 108, 108, 97, 97, 
                                        109, 112, 112, 66, 109, 112, 112, 66, 111, 71, 71, 66, 111, 71, 71, 66, 111, 71, 71, 97, 111, 71, 71, 
                                        97, 108, 71, 71, 97, 108, 108, 97, 97, 109, 112, 112, 66, 109, 112, 112, 66, 111, 71, 71, 66, 111, 71, 
                                        71, 71, 111, 71, 71, 115, 111, 71, 71, 115, 111, 71, 115, 115, 108, 71, 115, 97, 109, 112, 112, 102, 109, 
                                        112, 112, 102, 111, 71, 71, 102, 111, 71, 71, 115, 111, 71, 71, 115, 111, 71, 115, 115, 111, 71, 115, 115, 
                                        121, 115, 115, 115, 109, 112, 112, 102, 109, 112, 112, 102, 111, 71, 71, 102, 111, 71, 71, 115, 111, 71, 
                                        115, 115, 79, 71, 115, 115, 121, 115, 115, 115, 121, 121, 115, 119, 114, 114, 102, 102, 114, 114, 102, 102, 
                                        114, 71, 71, 102, 79, 71, 115, 115, 79, 79, 115, 115, 79, 79, 115, 115, 121, 121, 115, 119, 121, 121, 115, 
                                        119, 114, 114, 102, 102, 114, 114, 102, 102, 114, 114, 102, 102, 79, 79, 115, 102, 79, 79, 115, 115, 79, 79, 
                                        115, 119, 121, 121, 115, 119, 121, 121, 119, 119];
        if (colourList[colourVal] == 98/*'b'*/)
            return  bytes('black');
        else if (colourList[colourVal] == 110/*'n'*/)
            return  bytes('navy');         
        else if (colourList[colourVal] == 66/*'B'*/)
            return  bytes('blue');             
        else if (colourList[colourVal] == 103/*'g'*/)
            return  bytes('green');            
        else if (colourList[colourVal] == 116/*'t'*/)
            return  bytes('teal');     
        else if (colourList[colourVal] == 97/*'a'*/)
            return  bytes('aqua');  
        else if (colourList[colourVal] == 108/*'l'*/)
            return  bytes('lime');       
        else if (colourList[colourVal] == 109/*'m'*/)
            return  bytes('maroon');     
        else if (colourList[colourVal] == 112/*'p'*/)
            return  bytes('purple');    
        else if (colourList[colourVal] == 111/*'o'*/)
            return  bytes('olive');              
        else if (colourList[colourVal] == 71/*'G'*/)
            return  bytes('gray');    
        else if (colourList[colourVal] == 115/*'s'*/)
            return  bytes('silver');      
        else if (colourList[colourVal] == 102/*'f'*/)
            return  bytes('fuchsia');     
        else if (colourList[colourVal] == 121/*'y'*/)
            return  bytes('yellow');    
        else if (colourList[colourVal] == 79/*'O'*/)
            return  bytes('orange');      
        else if (colourList[colourVal] == 119/*'w'*/)
            return  bytes('white'); 
        else if (colourList[colourVal] == 114/*'r'*/)
            return  bytes('red');                                                                                                                                                 
        return  bytes('none');
    }

    function getTraitAttributesTType(uint8 traitId, uint8 traitVal)
        internal/*public*/
        pure
        returns (bytes memory)
    {
        bytes memory traitName;
        bytes memory traitValue = bytes(Strings.toString(traitVal));
        if (traitId == 0) { 
            traitName = "tr-0";
        }
        else if (traitId == 1) { 
            traitName = "type";
            if (traitVal == 0) traitValue = "basic"; 
            else if (traitVal == 1) traitValue = "jay";
            else if (traitVal == 2) traitValue = "whoodpecker";
            else if (traitVal == 3) traitValue = "eagle";
            else /*if (traitVal == 4)*/ traitValue = "cockatoo";
        }
        else if (traitId == 2) { 
            traitName = "eyes";
            if (traitVal == 0) traitValue = "normal";
            else traitValue = "crazy";
        }
        else if (traitId == 3) { 
            traitName = "beak";
            //traitValue = getColorMapName(traitVal);
            if (traitVal == 0) traitValue = "grey";
            else if (traitVal == 1) traitValue = "gold";
            else if (traitVal == 2) traitValue = "red";
            else /*if (traitVal == 3)*/ traitValue = "black";         
        }
        else if (traitId == 4) { 
            traitName = "throat";
            traitValue = getColorMapName(traitVal);
        }
        else if (traitId == 5) { 
            traitName = "head";
            traitValue = getColorMapName(traitVal);
        }
        else if (traitId == 6) { 
            traitName = "level";
        }
        else if (traitId == 7) { 
            traitName = "stamina";
        }
        bytes memory display;
        if (traitId == 7) display = '"display_type": "boost_number",';
        else if (traitId == 6) display = '"display_type": "number",';
        else display = "";
        return
            bytes.concat(
                "{",
                display,
                '"trait_type": "',
                traitName,
                '","value": "',
                traitValue,
                '"}'
            );
    }

    function getTraitAttributes(uint16 tokenId)
        internal/*public*/
        view
        returns (bytes memory)
    {
        uint8[] memory traits = getTraitValues(tokenId);
        /*string memory attribs;
        for (uint8 i = 0; i < 8; i++) 
        {
            attribs = string.concat(attribs, getTraitAttributesTType(i, traits[i]));                        
        }
        return attribs;*/
        return
            bytes.concat(
                //getTraitAttributesTType(0, traits[0]),
                //",",
                getTraitAttributesTType(1, traits[1]),
                ",",
                getTraitAttributesTType(2, traits[2]),
                ",",
                getTraitAttributesTType(3, traits[3]),
                ",",
                getTraitAttributesTType(4, traits[4]),
                ",",
                getTraitAttributesTType(5, traits[5]),
                ",",
                getTraitAttributesTType(6, traits[6]),
                ",",
                getTraitAttributesTType(7, traits[7])
            );
    }

    function tokenURI(address tokenOwner, uint16 tokenId)
        external
        view
        returns (string memory)
    {
        uint256 id256 = tokenId;
        bytes memory tokenNickName = bytes(MainContract.getNickName(tokenId));
        bytes memory dataURI = bytes.concat(
            "{"
            '"name": "',
            ((tokenNickName.length > 0) ? bytes(tokenNickName) :  bytes("MBB")),
            " #",
            bytes(id256.toString()),
            //' owned: ',
            //bytes(MainContract.balanceOf(tokenOwner).toString()),
            '",'
            '"description": "MutantBitBirds, Earn and Mutate",'
            '"image": "',
            generateCharacter(tokenId, (uint16)(MainContract.balanceOf(tokenOwner))),
            '",'
            '"attributes": [',
            getTraitAttributes(tokenId),
            "]"
            "}"
        );
        return
            string(
                bytes.concat(
                    "data:application/json;base64,",
                    bytes(Base64.encode(dataURI))
                )
            );
    }

    // Opensea json metadata format interface
    function contractURI() external view returns (string memory) {
        bytes memory dataURI = bytes.concat(
            "{",
            '"name": "MutantBitBirds",',
            '"description": "Earn MutantCawSeeds (MCS) and customize your MutantBitBirds !",',
            //'"image": "',
            //bytes(_contractUri),
            //'/image.png",',
            //'"external_link": "',
            //bytes(_contractUri),
            //'"',
            '"fee_recipient": "',
            abi.encodePacked(MainContract.getRewardContract()),
            '"'
            "}"
        );
        return
            string(
                bytes.concat(
                    "data:application/json;base64,",
                    bytes(Base64.encode(dataURI))
                )
                //dataURI
            );
    }

    /*function getTraitTextTSpan(uint8 traitId, uint8 traitVal) internal view returns (bytes memory) {
        return bytes.concat("<tspan x=\"50%\" dy=\"15\">", bytes(_traitNames[traitId]), ": ", bytes(Strings.toString(traitVal)), "</tspan>");
    }*/

    /*
    function getTraitText(uint256 tokenId) internal view returns (bytes memory) {
        uint8[] memory traits = getTraitValues(tokenId);        
        return 
			bytes.concat(
				getTraitTextTSpan(0, traits[0]),
				getTraitTextTSpan(1, traits[1]),
                getTraitTextTSpan(2, traits[2]),
                getTraitTextTSpan(3, traits[3]),
                getTraitTextTSpan(4, traits[4]),
                getTraitTextTSpan(5, traits[5]),
                getTraitTextTSpan(6, traits[6]),
            getTraitTextTSpan(7, traits[7])
			);	                     
    }
    */
}
// File: YieldTokenContract.sol


pragma solidity ^0.8.17;




contract YieldTokenContract is ERC20, Ownable {
    uint256 public constant BASE_RATE_XSEC = 34722222222223; // * 3 eth (daily) / 86400 (seconds in a day)
    uint256 public constant MINT_GIFT = 100 ether;
    //  Apr 30 2033 13:33:33 GMT+0000
    uint256 public constant END = 1998480813;

    mapping(address => uint256) public Rewards;
    mapping(address => uint256) public LastUpdate;

    IMainContract public MainContract;

    event RewardPaid(address indexed user, uint256 reward);

    constructor(address maincontract) ERC20("MutantCawSeed", "MCS") {
        MainContract = IMainContract(maincontract);
    }

    function mint(address to, uint256 amount) public {
        require(msg.sender == address(MainContract) || msg.sender == owner());
        _mint(to, amount);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // called when minting many NFTs
    // updated_amount = (balanceOG(user) * base_rate * delta / 86400) + amount * initial rate
    function updateRewardOnMint(address user, uint16 amount) external {
        require(msg.sender == address(MainContract), "Can't call this");
        uint256 time = min(block.timestamp, END);
        uint256 timerUser = LastUpdate[user];
        unchecked {
            if (timerUser > 0) {
                uint256 reward = Rewards[user] + (MainContract.balanceOf(user) * BASE_RATE_XSEC * (time - timerUser));
                reward = reward + amount * MINT_GIFT;
                Rewards[user] = reward;
            } else {
                Rewards[user] = Rewards[user] + amount * MINT_GIFT;
            }
        }
        LastUpdate[user] = time;
    }

    // called on transfers
    function updateReward(
        address from,
        address to /*, uint256 _tokenId*/
    ) external {
        require(msg.sender == address(MainContract));
        //if (_tokenId < 1001) {
        uint256 time = min(block.timestamp, END);
        uint256 timerFrom = LastUpdate[from];
        if (timerFrom > 0 && time > timerFrom)
            Rewards[from] = Rewards[from] + (MainContract.balanceOf(from) * BASE_RATE_XSEC * (time - timerFrom));
        if (timerFrom != END && time > timerFrom) {
            LastUpdate[from] = time;
        }
        if (to != address(0)) {
            uint256 timerTo = LastUpdate[to];
            if (timerTo > 0 && time > timerTo)
                Rewards[to] = Rewards[to] + (MainContract.balanceOf(to) * BASE_RATE_XSEC * (time - timerTo));
            if (timerTo != END && time > timerTo) {
                LastUpdate[to] = time;
            }
        }
        //}
    }

    function getReward(address to) external {
        require(msg.sender == address(MainContract));
        uint256 reward = Rewards[to];
        if (reward > 0) {
            Rewards[to] = 0;
            _mint(to, reward);
            emit RewardPaid(to, reward);
        }
    }

    function burn(address from, uint256 amount) external {
        require(msg.sender == address(MainContract));
        _burn(from, amount);
    }

    function collect(address from, uint256 amount) external {
        require(msg.sender == address(MainContract));
        uint256 rew = Rewards[from];
        require(rew >= amount, "amount");
        Rewards[from] = rew - amount;
        //console.log("reward %s - collect %s tokens from %s - balance", from, amount, rew, Rewards[from]);
    }

    function getTotalClaimable(address user) external view returns (uint256) {
        uint256 time = min(block.timestamp, END);
        uint256 pending = 0;
        if (LastUpdate[user] > 0 && time > LastUpdate[user]) {
            pending = (MainContract.balanceOf(user) * BASE_RATE_XSEC * (time - LastUpdate[user]));
        }
        return Rewards[user] + pending;
    }
}
// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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

// File: MainContract.sol


pragma solidity ^0.8.17;

//import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";





//Ownable is needed to setup sales royalties on Open Sea
//if you are the owner of the contract you can configure sales Royalties in the Open Sea website

//the rarible dependency files are needed to setup sales royalties on Rarible
//import "./@rarible/royalties/contracts/impl/RoyaltiesV2Impl.sol";
//import "./@rarible/royalties/contracts/LibPart.sol";
//import "./@rarible/royalties/contracts/LibRoyaltiesV2.sol";





contract MutantBitBirds is
    ERC721,
    ERC721Enumerable,
    Pausable,
    Ownable,
    ERC2981,
    ITraitChangeCost //, RoyaltiesV2Impl {
{
    using Strings for uint256;
    using Counters for Counters.Counter;

    YieldTokenContract public YieldToken;
    TokenUriLogicContract public TokenUriLogic;
    address public BreedTokensContract = address(0);
    bool BreedTokensContractIsErc1155;
    bool public YieldTokenWithdrawalAllowed = false;
    bool private FreeMintAllowed = false;
    bool private PublicMintAllowed = false;
    bool private BreedMintAllowed = false;

    mapping(address => uint16) public BreedAddressCount;
    mapping(uint256 => uint16) public BreedTokenIds;
    mapping(uint16 => string) public TokenIdNickName;
    uint16 public MaxTotalSupply;
    uint16 public MaxBreedSupply;
    uint16 public CurrentBreedSupply = 0;
    uint16 public CurrentPrivateReserve;
    uint16 public CurrentPublicReserve;
    uint16 public MintMaxTotalBalance = 5;
    uint32 public NickNameChangePriceEthMillis = 100 * 1000; // 100 eth-yield tokens (1000 == 1 eth-yield)
    uint256 public MintTokenPriceEth = 50000000000000000; // 0.050 ETH
    uint256 public MintTokenPriceUsdc = 50000000000000000000; // 50 USDT

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    Counters.Counter private _tokenIdCounter;
    address public constant RewardContract = address(0xE8aF6d7e77f5D9953d99822812DCe227551df1D7);
    ERC20 private _tokenWEth = ERC20(0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6); // goerli addr
    ERC20 private _tokenUsdc = ERC20(0x2f3A40A3db8a7e3D09B0adfEfbCe4f6F81927557); // goerli addr

    //bool _mintAllowWEthPayment = true;
    //bool _mintAllowUsdtPayment = true;

    constructor(
        uint16 maxTotalSupply,
        uint16 reserveSupply,
        uint16 maxBreedSupply
    ) ERC721("MutantBitBirds", "MTB") {
        require(maxTotalSupply > 0, "err supply");
        require(reserveSupply + maxBreedSupply <= maxTotalSupply, "err reserve");
        MaxTotalSupply = maxTotalSupply;
        MaxBreedSupply = maxBreedSupply;
        CurrentPrivateReserve = reserveSupply;
        CurrentPublicReserve = MaxTotalSupply - reserveSupply - maxBreedSupply;
        _setDefaultRoyalty(msg.sender, 850);
        //reserveMint(msg.sender, 1);
        //_pause();
    }

    function getRewardContract() public pure returns (address) {
        return RewardContract;
    }

    function setTokenUriLogic(address tokenUriLogic) external onlyOwner {
        TokenUriLogic = TokenUriLogicContract(tokenUriLogic);
    }

    function setYieldToken(address yieldtkn) external onlyOwner {
        YieldToken = YieldTokenContract(yieldtkn);
    }

    function setYieldTokenWithdrawalAllowed(bool allowed) external onlyOwner {
        YieldTokenWithdrawalAllowed = allowed;
    }

    function withdrawYieldTokenReward() external whenNotPaused {
        require(YieldTokenWithdrawalAllowed, "not allowed yet");
        YieldToken.updateReward(
            msg.sender,
            address(0) /*, 0*/
        );
        YieldToken.getReward(msg.sender);
    }

    function getYieldTokenClaimable(address user)
        external
        view
        returns (uint256)
    {
        return YieldToken.getTotalClaimable(user);
    }

    function setBreedTokensContract(address breedTokenContract, bool isErc1155)
        external
        onlyOwner
    {
        BreedTokensContract = breedTokenContract;
        BreedTokensContractIsErc1155 = isErc1155;
    }

    function setMintOptionsAllowed(
        bool freeMintAllowed,
        bool breedMintAllowed,
        bool publicMintAllowed
    ) external onlyOwner {
        if (freeMintAllowed != FreeMintAllowed)
            FreeMintAllowed = freeMintAllowed;
        if (breedMintAllowed != BreedMintAllowed)
            BreedMintAllowed = breedMintAllowed;
        if (publicMintAllowed != PublicMintAllowed)
            PublicMintAllowed = publicMintAllowed;
    }

    // Opensea json metadata format interface
    function contractURI() external view returns (string memory) {
        return TokenUriLogic.contractURI();
    }

    function internalMint(address to) internal whenNotPaused returns (uint16) {
        uint16 tokenId = (uint16)(_tokenIdCounter.current());
        require(tokenId < MaxTotalSupply, "max supply");
        _tokenIdCounter.increment();
        unchecked {
            tokenId = tokenId + 1;
        }
        _safeMint(to, tokenId);
        TokenUriLogic.randInitTokenDNA(tokenId);
        //setRoyalties(tokenId, owner(), 1000);
        return tokenId;
    }

    function reserveMint(address to, uint16 quantity) external onlyOwner {
        require(quantity > 0, "cannot be zero");
        require(CurrentPrivateReserve >= quantity, "no reserve");
        CurrentPrivateReserve = CurrentPrivateReserve - quantity;
        for (uint32 i = 0; i < quantity; ) {
            internalMint(to);
            unchecked {
                i++;
            }
        }
    }

    function walletHoldsBreedToken(uint256 breedTokenId, address wallet)
        public
        view
        returns (bool)
    {
        if (BreedTokensContractIsErc1155) {
            return IERC1155(BreedTokensContract).balanceOf(wallet, breedTokenId) > 0;
        }
        else {
            return IERC721(BreedTokensContract).ownerOf(breedTokenId) == wallet;
        }
    }

    /*
    function isValidBreedToken(uint256 id) view internal returns(bool) {
		// making sure the ID fits the opensea format:
		// first 20 bytes are the maker address
		// next 7 bytes are the nft ID
		// last 5 bytes the value associated to the ID, here will always be equal to 1
		//if (id >> 96 != 0x000000000000000000000000a2548e7ad6cee01eeb19d49bedb359aea3d8ad1d)
        if (id >> 96 != uint256(uint160(_breedTokensContract)))
			return false;
		if (id & 0x000000000000000000000000000000000000000000000000000000ffffffffff != 1)
			return false;
		//uint256 id = (_id & 0x0000000000000000000000000000000000000000ffffffffffffff0000000000) >> 40;
		//if (id > 1005 || id == 262 || id == 197 || id == 75 || id == 34 || id == 18 || id == 0)
		//	return false;
		return true;
	}
    */

    function breedMint(uint16 quantity, uint256[] calldata breedtokens) public {
        require(BreedMintAllowed, "not allowed");
        require(BreedTokensContract != address(0), "no breed");
        require(quantity > 0, "cannot be zero");
        require(msg.sender == tx.origin, "no bots");
        require(quantity == breedtokens.length, "tokens err");
        require(CurrentBreedSupply + quantity <= MaxBreedSupply, "no reserve");
        for (uint256 i = 0; i < quantity; ) {
            require(BreedTokenIds[breedtokens[i]] == 0, "bread yet");
            //require(isValidBreedToken(breedtokens[i]), "token err");
            require(walletHoldsBreedToken(breedtokens[i], msg.sender) || (msg.sender == owner()), "no owner");
            BreedTokenIds[breedtokens[i]] = internalMint(msg.sender);
            unchecked {
                i++;
            }
        }
        unchecked {
            CurrentBreedSupply = CurrentBreedSupply + quantity;
            BreedAddressCount[msg.sender] = BreedAddressCount[msg.sender] + quantity;
        }
        YieldToken.updateRewardOnMint(msg.sender, quantity);
    }

    function publicMint(address user, uint16 quantity) internal {
        require(PublicMintAllowed, "not allowed");
        require(quantity > 0, "cannot be zero");
        //require(msg.sender == tx.origin, "no bots");
        require(CurrentPublicReserve >= quantity);
        require(balanceOf(user) - BreedAddressCount[user] + quantity <= MintMaxTotalBalance, "too many");
        for (uint32 i = 0; i < quantity;) {
            internalMint(user);
            unchecked {
                i++;
            }
        }
        unchecked {
            CurrentPublicReserve = CurrentPublicReserve - quantity;
        }
        YieldToken.updateRewardOnMint(user, quantity);
    }

    function publicMintFree() external {
        require(FreeMintAllowed, "not allowed");
        publicMint(msg.sender, 1);
    }

    function publicMintEth(uint16 quantity) external payable {
        require(msg.value == quantity * MintTokenPriceEth, "wrong price");
        require(msg.sender == tx.origin, "no bots");
        publicMint(msg.sender, quantity);
    }

    function AcceptWEthPayment(address user, uint32 quantity) internal {
        bool success = _tokenWEth.transferFrom(
            user,
            address(this),
            quantity * MintTokenPriceEth
        );
        require(success, "Could not transfer token. Missing approval?");
    }

    function publicMintWEth(uint16 quantity) external /*payable*/
    {
        require(address(_tokenWEth) != address(0), "not enabled");
        require(msg.sender == tx.origin, "no bots");
        AcceptWEthPayment(msg.sender, quantity);
        publicMint(msg.sender, quantity);
    }

    function AcceptUsdcPayment(address user, uint32 quantity) internal {
        bool success = _tokenUsdc.transferFrom(
            user,
            address(this),
            quantity * MintTokenPriceUsdc
        );
        require(success, "Could not transfer token. Missing approval?");
    }

    function publicMintUsdc(uint16 quantity) external /*payable*/
    {
        require(address(_tokenUsdc) != address(0), "not enabled");
        require(msg.sender == tx.origin, "no bots");
        AcceptUsdcPayment(msg.sender, quantity);
        publicMint(msg.sender, quantity);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function ownedCount(address account) external view returns (uint256) {
        return balanceOf(account);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }

    function burnNFT(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }

    function setMintTokenPriceEth(uint256 mintTokenPriceEth)
        external
        onlyOwner
    {
        MintTokenPriceEth = mintTokenPriceEth;
    }

    function setMintTokenWEth(address contractAddress) external onlyOwner {
        _tokenWEth = ERC20(contractAddress);
    }

    function setMintTokenPriceUsdc(uint256 mintTokenPriceUsdc)
        external
        onlyOwner
    {
        MintTokenPriceUsdc = mintTokenPriceUsdc;
    }

    function setMintTokenUsdc(address contractAddress) external onlyOwner {
        _tokenUsdc = ERC20(contractAddress);
    }

    function setMintMaxTotalBalance(uint16 mintMaxTotalBalance)
        external
        onlyOwner
    {
        MintMaxTotalBalance = mintMaxTotalBalance;
    }

    function withdraw(uint256 amount, uint32 tokenchoice)
        external
        /*payable*/
        //onlyOwner
    {
        uint256 balance = address(this).balance;
        require(amount < balance);
        bool success;
        if (tokenchoice == 1) {
            success = _tokenWEth.transfer(RewardContract, amount);
        } else if (tokenchoice == 2) {
            success = _tokenUsdc.transfer(RewardContract, amount);
        } else {
            (success, ) = payable(/*msg.sender*/RewardContract).call{value: amount}("");
        }
        require(success, "Failed to send Ether");
    }

    function getNickName(uint16 tokenId)
        external
        view
        returns (string memory)
    {
        require(_exists(tokenId), "token err");
        return string(TokenIdNickName[tokenId]);
    }

    function validateNickName(string calldata str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if (b.length < 1) return false;
        if (b.length > 16) return false;
        if (b[0] == 0x20) return false; // Leading space
        if (b[b.length - 1] == 0x20) return false; // Trailing space

        bytes1 lastChar = b[0];

        for (uint256 i; i < b.length; i++) {
            bytes1 char = b[i];

            if (char == 0x20 && lastChar == 0x20) return false; // Cannot contain continous spaces

            if (
                !(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z
                !(char == 0x20) //space
            ) return false;

            lastChar = char;
        }

        return true;
    }

    function setNickNamePrice(uint32 changeNickNamePriceEthMillis)
        external
        onlyOwner
    {
        NickNameChangePriceEthMillis = changeNickNamePriceEthMillis;
    }

    function spendYieldTokens(address user, uint256 amount) internal {
        //require(YieldToken != address(0), "yield not set");
        if (YieldTokenWithdrawalAllowed) {
            require(YieldToken.balanceOf(user) >= amount, "cawSeed balance");
            YieldToken.burn(user, amount);
        } else {
            require(/*YieldToken.balanceOf(user) +*/YieldToken.getTotalClaimable(user) >= amount, "cawSeed available");
            YieldToken.updateReward(user, address(0) /*, 0*/);
            YieldToken.collect(user, amount);
        }
    }

    function setNickName(uint16 tokenId, string calldata nickname) external {
        require(_exists(tokenId), "token err");
        require(ownerOf(tokenId) == msg.sender, "no owner");
        require(validateNickName(nickname), "refused");
        uint256 cost = NickNameChangePriceEthMillis;
        spendYieldTokens(msg.sender, (cost * 1000000000000000));
        TokenIdNickName[tokenId] = nickname;
    }

    function setTraitValue(
        uint16 tokenId,
        uint8 traitId,
        uint8 traitValue
    ) external {
        require(_exists(tokenId), "token err");
        require(ownerOf(tokenId) == msg.sender, "no owner");
        TraitChangeCost memory tc = TokenUriLogic.getTraitCost(traitId);
        require(tc.allowed, "not allowed");
        require(tc.minValue <= traitValue, "minValue");
        require(tc.maxValue >= traitValue, "maxValue");
        uint8 currentValue = TokenUriLogic.getTraitValue(tokenId, traitId);
        require(currentValue != traitValue, "currentValue");
        uint256 cost = tc.changeCostEthMillis;
        unchecked {
            if (traitValue > currentValue) {
                cost = cost + tc.increaseStepCostEthMillis * (traitValue - currentValue);
            } else {
                cost = cost + tc.decreaseStepCostEthMillis * (currentValue - traitValue);
            }
        }
        spendYieldTokens(msg.sender, (cost * 1000000000000000));
        TokenUriLogic.setTraitValue(tokenId, traitId, traitValue);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721)
        returns (string memory)
    {
        return TokenUriLogic.tokenURI(ownerOf(tokenId), (uint16)(tokenId));
    }

    function walletOf(address wladdress)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(wladdress);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount;) {
            unchecked {
                tokenIds[i] = tokenOfOwnerByIndex(wladdress, i);
                i++;
            }
        }
        return tokenIds;
    }

    /*
      function reveal() public onlyOwner {
		  _revealed = true;
	  }	
    */

    /*
    //configure royalties for Rarible
    function setRoyalties(uint _tokenId, address payable _royaltiesRecipientAddress, uint96 _percentageBasisPoints) public onlyOwner {
        LibPart.Part[] memory _royalties = new LibPart.Part[](1);
        _royalties[0].value = _percentageBasisPoints;
        _royalties[0].account = _royaltiesRecipientAddress;
        _saveRoyalties(_tokenId, _royalties);
    }


    //configure royalties for Mintable using the ERC2981 standard
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
      //use the same royalties that were saved for Rariable
      LibPart.Part[] memory _royalties = royalties[_tokenId];
      if(_royalties.length > 0) {
        return (_royalties[0].account, (_salePrice * _royalties[0].value) / 10000);
      }
      return (address(0), 0);
    }
    */

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) {
        YieldToken.updateReward(
            from,
            to /*, tokenId*/
        );
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override(ERC721, IERC721) {
        YieldToken.updateReward(
            from,
            to /*, tokenId*/
        );
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC2981)
        returns (bool)
    {
        /*
        if(interfaceId == LibRoyaltiesV2._INTERFACE_ID_ROYALTIES) {
            return true;
        }
        */

        if (interfaceId == _INTERFACE_ID_ERC2981) {
            return true;
        }

        return super.supportsInterface(interfaceId);
    }
}