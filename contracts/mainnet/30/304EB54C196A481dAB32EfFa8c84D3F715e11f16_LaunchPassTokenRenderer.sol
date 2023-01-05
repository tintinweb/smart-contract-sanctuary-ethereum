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
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import {ITokenRenderer} from "../NFTPass/ITokenRenderer.sol";
import {Utils} from "../utils/Utils.sol";

contract LaunchPassTokenRenderer is ITokenRenderer, Ownable {
    constructor() {}

    function getTokenURI(uint256 tokenId, string memory name) public pure returns (string memory) {
        string memory tokenIdString = Strings.toString(tokenId);
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            string(abi.encodePacked(name, " #", Strings.toString(tokenId))),
                            '","description":"Launch Pass is a product NFT that unlocks your profile and the advanced features on [Launchcaster](https://www.launchcaster.xyz)\\r\\n\\r\\nArt by [@Bias on Farcaster](farcaster://profiles/1355) / mendicantbias.xyz","attributes":[{"trait_type":"Badge Number", "value":',
                            tokenIdString, '}]',
                            ',"image":"',
                            string(
                                abi.encodePacked(
                                    "data:image/svg+xml;base64,",
                                    Base64.encode(
                                        bytes(
                                            abi.encodePacked(
                                                '<svg id="uuid-a88c3ce8-5794-4ffc-a77b-d70d1b0204cd" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 493.5 493.5"><defs><linearGradient id="uuid-d759e902-2896-4c59-a8e2-a14ad637a1eb" x1="246.75" y1="705.16" x2="246.75" y2="725.37" gradientTransform="translate(0 -376)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#000" stop-opacity=".88"/><stop offset="1" stop-color="#000" stop-opacity="0"/></linearGradient><linearGradient id="uuid-c81e66a7-570a-4fa6-9383-3cb2d2472011" x1="246.7" y1="540.2" x2="246.7" y2="705.1" gradientTransform="translate(0 -376)" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#8861d0"/><stop offset=".04" stop-color="#865fce"/><stop offset=".06" stop-color="#8059c7"/><stop offset=".07" stop-color="#7550bb"/><stop offset=".08" stop-color="#6642aa"/><stop offset=".08" stop-color="#633fa7"/><stop offset=".08" stop-color="#6440a8"/><stop offset=".13" stop-color="#714bb6"/><stop offset=".15" stop-color="#6e49b3"/><stop offset=".16" stop-color="#6742ab"/><stop offset=".16" stop-color="#613da5"/><stop offset=".2" stop-color="#6843ad"/><stop offset=".25" stop-color="#7c56c3"/><stop offset=".27" stop-color="#865fce"/><stop offset=".51" stop-color="#845dcb"/><stop offset=".61" stop-color="#7d57c4"/><stop offset=".69" stop-color="#724cb8"/><stop offset=".75" stop-color="#623ea6"/><stop offset=".76" stop-color="#613da5"/><stop offset=".76" stop-color="#6440a9"/><stop offset=".76" stop-color="#704bb5"/><stop offset=".76" stop-color="#825cca"/><stop offset=".76" stop-color="#8a63d2"/><stop offset=".8" stop-color="#825cc9"/><stop offset=".85" stop-color="#6e49b3"/><stop offset=".88" stop-color="#613da5"/><stop offset=".88" stop-color="#734db8"/><stop offset=".88" stop-color="#8059c7"/><stop offset=".88" stop-color="#8760cf"/><stop offset=".89" stop-color="#8a63d2"/><stop offset="1" stop-color="#573399"/></linearGradient></defs><path d="m-.5-.5h494.5v494.5H-.5V-.5Z"/><path d="m373.4,477.4H120.1v-42.5c0-2-1.6-3.6-3.6-3.6h-20.2v-41.1c0-2-1.6-3.6-3.6-3.6h-17.1v-196.4c0-96.6,76.6-173.2,171.1-173.2s171.1,76.5,171.1,172.6v197h-17.1c-2,0-3.6,1.6-3.6,3.6v41.1h-20.1c-2,0-3.6,1.6-3.6,3.6v42.5h0Z" fill="#b3b3b3"/><path d="m121.1,476.4h251.3v-41.5c0-2.5,2-4.6,4.6-4.6h19.2v-40.1c0-2.5,2-4.6,4.6-4.6h16.1v-196c0-95.5-76.5-171.6-170.2-171.6S76.6,94.1,76.6,190.2v195.4h16.2c2.5,0,4.6,2,4.6,4.6v40.1h19.2c2.5,0,4.6,2,4.6,4.6,0,0-.1,41.5-.1,41.5Z"/><path d="m246.7,22.2c-91.4,0-165.9,74.2-165.9,168.3v190.5h13.1c4.4,0,8,3.6,8,8v36.4h16.1c4.4,0,8,3.6,8,8v37.8h241.4v-37.8c0-4.4,3.6-8,8-8h16v-36.4c0-4.4,3.6-8,8-8h13v-190.5c.2-94.1-74.2-168.3-165.7-168.3Zm155.9,348.8h-3c-9.9,0-18,8.1-18,18v26.4h-6c-9.9,0-18,8.1-18,18v27.8h-221.5v-27.8c0-9.9-8.1-18-18-18h-6.1v-26.4c0-9.9-8.1-18-18-18h-3.1v-180.4c0-88.6,70-158.3,156-158.3s155.7,69.7,155.7,158.3v180.4Z" fill="#573399"/><path d="m246.7,115.5c0,200.2-105.2,340.9-105.2,340.9h210.5s-105.3-140.7-105.3-340.9Z" fill="#573399"/><path d="m246.7,115.5c0,200.2-74.8,340.9-74.8,340.9h149.7s-74.9-140.7-74.9-340.9h0Z" fill="#8a63d2"/><path d="m198.2,351.5h97.1c-3-7.1-6-14.6-8.9-22.4h-79.4c-2.9,7.8-5.8,15.3-8.8,22.4Z" fill="url(#uuid-d759e902-2896-4c59-a8e2-a14ad637a1eb)"/><text transform="translate(475.48 40.52)" fill="#fff" font-family="Helvetica-Bold, Helvetica, sans-serif" font-size="32" font-weight="700" isolation="isolate"><tspan x="0" y="0" text-anchor="end">',
                                                tokenIdString,
                                                '</tspan></text><path d="m151.9,329.1v-16.1c0-3.1,2.5-5.5,5.6-5.5h.9v-13.9c0-3.1,2.5-5.5,5.6-5.5h1.8v-96.5h-.1c-3.1,0-5.6-2.5-5.6-5.6v-6.6h-2.6c-3.1,0-5.6-2.5-5.6-5.6v-9.6h66.3v9.6c0,3.1-2.5,5.6-5.6,5.6h-2.6v6.6c0,3.1-2.5,5.6-5.6,5.6h-.1v96.5h125.1c3.1,0,5.6,2.5,5.6,5.5v13.9h.9c3.1,0,5.6,2.5,5.6,5.5v16.1h-189.6Z" fill="url(#uuid-c81e66a7-570a-4fa6-9383-3cb2d2472011)" fill-rule="evenodd"/><path d="m417.9,285v8.3c15,11.8,22,22,17.7,28.7-13.8,21.5-103.9,11.1-203.7-22.3S50.5,216.4,58.2,193.6c1.7-5.1,7.9-8.7,17.6-10.6.1-3.4.4-6.7.7-10-26.5-1.8-43.9,1.9-47.1,11.5-8.4,25.2,82.6,78.8,199.7,118.1,117.1,39.3,224.7,53.6,233.1,28.4,3.7-11.5-13.5-27.9-44.3-46h0Z" fill="#fff"/><path d="m396.6,308.9c-5.9,17.5-80.9,7.6-162.5-19.8s-145.2-64.8-139.3-82.4c3.5-10.6,31.4-10.1,70.9-2v2.5c-28.3-4-48-2.6-50.8,5.8-5.3,15.9,51.6,50.7,121.1,74s132.4,30.5,142,15.5c8.6-13.5-47.7-46.6-113.3-69.8-2.2-.8-2.1-.8,0,0,77.2,26.8,137.5,59.3,131.9,76.2Zm-192.2-94.8v.8c8.6,2.1,14.1,3.5,26.6,7,0,0,1.9.5,0-.1-9.1-2.8-18-5.4-26.6-7.7Zm42.3-87.8c0-27.2-3.4-30.6-30.6-30.6,27.2,0,30.6-3.4,30.6-30.6,0,27.2,3.4,30.6,30.6,30.6-27.2-.1-30.6,3.3-30.6,30.6Zm36.3-58.5c-8.7,0-9.8-1.1-9.8-9.8,0,8.7-1.1,9.8-9.8,9.8,8.7,0,9.8,1.1,9.8,9.8,0-8.8,1.1-9.8,9.8-9.8Zm29.5,16c-3.9,0-4.4-.5-4.4-4.3,0,3.9-.5,4.3-4.4,4.3,3.9,0,4.4.5,4.4,4.3,0-3.8.5-4.3,4.4-4.3Zm-89.7-11.5c-3.9,0-4.4-.5-4.4-4.3,0,3.9-.5,4.3-4.4,4.3,3.9,0,4.4.5,4.4,4.3.1-3.8.5-4.3,4.4-4.3Zm-72.4,49.6c-3.9,0-4.4-.5-4.4-4.3,0,3.9-.5,4.3-4.4,4.3,3.9,0,4.4.5,4.4,4.3,0-3.8.5-4.3,4.4-4.3Zm167.3-7.7c-2.6,0-3-.3-3-3,0,2.6-.3,3-3,3,2.6,0,3,.3,3,3,.1-2.7.4-3,3-3Zm-129.8-10.5c-2.6,0-3-.3-3-3,0,2.6-.3,3-3,3,2.6,0,3,.3,3,3,.1-2.7.4-3,3-3Zm3.2-27.7c-2.6,0-3-.3-3-3,0,2.6-.3,3-3,3,2.6,0,3,.3,3,3,.1-2.7.4-3,3-3Zm-32.4,16.6c-2.6,0-3-.3-3-3,0,2.6-.3,3-3,3,2.6,0,3,.3,3,3,.1-2.6.4-3,3-3Zm146.4,60.5c-2.6,0-3-.3-3-3,0,2.6-.3,3-3,3,2.6,0,3,.3,3,3,0-2.7.3-3,3-3Zm-109.4-28c-2.6,0-3-.3-3-3,0,2.6-.3,3-3,3,2.6,0,3,.3,3,3,.1-2.6.4-3,3-3Zm173.8,26.6c-2.6,0-3-.3-3-3,0,2.6-.3,3-3,3,2.6,0,3,.3,3,3,.1-2.7.4-3,3-3Zm-86.9-32c-2.6,0-3-.3-3-3,0,2.6-.3,3-3,3,2.6,0,3,.3,3,3,.1-2.6.4-3,3-3Zm53.5,19.3c-2.6,0-3-.3-3-3,0,2.6-.3,3-3,3,2.6,0,3,.3,3,3,0-2.7.4-3,3-3Zm12-28.1c-2.6,0-3-.3-3-3,0,2.6-.3,3-3,3,2.6,0,3,.3,3,3,0-2.7.3-3,3-3Zm-84.4,107.6c54.2,18.4,103.1,38.8,138.9,57.9v6c-32.3-21-83.8-45.1-138.9-63.9Zm148.9,63.4v7.3c1.5,1.1,2.9,2.1,4.3,3.2v-8.1c-1.4-.7-2.9-1.6-4.3-2.4Zm-180-73.5c-9.6-3-19-5.8-28.2-8.5v.6c9.2,2.5,28.2,8,28.2,7.9Zm-141.5-26.9c11.2-.2,24.7,1,39.9,3.6,7.6,1.3,21.2,4.1,34.7,7v-.6h-.1c-2.1,0-3.8-1.1-4.8-2.8-11.8-3-23.1-5.8-29.8-7.3-14.3-3.2-27.5-5.6-39.3-7.1-.2,2.3-.4,5-.6,7.2h0Zm-9.4-8.2c-1.5-.1-2.8-.2-4.3-.4-.3,3.2-.6,6.5-.7,9.8,1.4-.2,2.8-.4,4.3-.6.2-2.7.5-6,.7-8.8Zm51.5,200.4v25h21.3v8.6h-30.9v-33.6h9.6Zm55,27.9h-19.8l-2.6,5.7h-10.4l15.9-33.6h14.2l15.7,33.6h-10.4l-2.6-5.7h0Zm-9-20.2h-1.8l-5.8,12.7h13.4l-5.8-12.7Zm31.4-7.7v15.5c0,1.3.1,2.3.1,3.1,0,.7,0,4.3.9,5.3,1,1,1.9,1.6,9.4,1.6s8.7-.5,9.6-2.2c.1-.2.6-1.1.7-6.1v-17.1h9.1v15.5c0,6.3-.4,9.9-.4,10.5-.2,1.9-.9,3.5-2,4.8-2.3,2.6-5.2,3.3-16.9,3.3-13.9,0-15.7-1.1-18.2-4.8-.4-.7-1.5-2.8-1.4-13.9v-15.5h9.1,0Zm49.4,0l15.7,25h.9l-.2-25h9.3v33.6h-15.9l-15.8-25h-1l.2,25h-9.2v-33.6h16Zm67.2,20.6c0,1,.1,2.9.1,3.2,0,2.7-.4,4.8-1.1,6.1s-1.9,2.4-3.5,3c-.6.2-1.3.4-2,.5-3.4.6-7.2.6-14.9.6s-11.3-.6-13.3-2c-1-.6-1.7-1.5-2.2-2.5-.8-1.6-1.2-3.8-1.2-12.6s.4-11.1.9-12.1c.4-1.1,1-2.1,1.7-2.8s1.8-1.2,3.3-1.6c.7-.2,3.1-1,13.7-1s13.8.2,16.3,2.9c.5.5.8,1.1,1.1,1.9.3.7.5,1.6.6,2.6s.2,2.2.2,3.5v1.7h-9.1c-.1-1-.1-1.7-.2-2-.3-1.7-1.2-2.3-13.2-2-.9,0-1.7.1-2.3.1-3.1.3-4.03,1.8-4.03,8.9s.73,8.2,4.43,8.6c1.3.1,3.2.1,5.6.1,9.4.1,9.5-.6,10-2.1.2-.7.2-1.6.2-2.9l8.9-.1h0Zm12.4-20.6v12h20.6v-12h9.6v33.6h-9.6v-12.1h-20.6v12.1h-9.6v-33.6h9.6Zm-163.6,42.6c6.81,0,9.3,1,10.5,1.6,1.1.5,1.9,1.2,2.5,2.1.6,1,1.1,2.2,1.4,3.7.3,1.6.4,3.6.4,6,0,2.1-.1,3.9-.3,5.4-.2,1.4-.5,2.6-1,3.6-.4.9-1,1.6-1.7,2.2s-1.6,1.1-2.7,1.4c-.6.2-1.3.4-1.9.5-.7.1-1.5.2-2.5.3-1.2.1-2.5.1-3.7.2-1.4,0-3.3.1-5.4.1h-16.3v9.4h-9.9v-36.4l30.6-.1m-20.7,19.5l20.72-.1c4.69,0,4.84-3.84,4.84-5.88,0-1.5-.24-2.79-.54-3.59-1.08-2.27-2.3-2.33-8.72-2.33h-16.2l-.1,11.9m20.7-20.5h-31.7v38.5h12.1v-9.4h15.2c2.1,0,3.9,0,5.4-.1,1.5,0,2.7-.1,3.7-.2s1.9-.2,2.6-.3,1.4-.3,2.1-.5c1.2-.4,2.2-1,3-1.6s1.5-1.5,2-2.6.9-2.4,1.1-3.9.3-3.4.3-5.5c0-2.5-.1-4.5-.4-6.2-.3-1.7-.8-3-1.5-4.1s-1.7-1.9-3-2.5c-1.2-.6-4.4-1.6-8.1-1.6h-2.8Zm-19.6,19.4v-9.8h18.2c3.61,0,4.26.75,4.8,1.8.35.68.4,1.7.4,3.1,0,3.2-.63,4.9-4.72,4.9h-18.68Zm71.8-18.4l19.6,36.4h-11.3l-3.1-6-.3-.6h-27.5l-.3.6-3.1,6h-11.4l19.9-36.4h17.5m-19.4,23.5h21.2l-.8-1.5-7.7-14.6-.3-.6h-3.7l-.3.6-7.7,14.6-.7,1.5m20-24.5h-18.8l-21,38.5h13.8l3.4-6.5h26.2l3.4,6.5h13.7l-20.7-38.5h0Zm-18.3,23.4l7.7-14.6h2.4l7.7,14.6h-17.8,0Zm116.3-23c2.8,0,5.3,0,7.2.1,2,.1,3.7.2,5,.4,5.89.64,7.28,3.2,7.68,4.3.82,1.68.72,5.85.72,5.85l-9.7.05c0-.6-.1-1-.2-1.3-.2-.6-.55-1.26-1.29-1.73-1.28-.82-4.82-.87-6.12-.87,0,0-10.43-.04-11.83.06-1.6.1-2.92.31-3.72.51-1,.3-1.56.98-1.86,1.68-.3.6-.26,1.14-.26,2.04-.02,2.33,1.81,3.08,2.81,3.28.3.1,2.96.35,3.97.39,2.07.1,11.17.34,16.8.63,3.34.08,7.25.61,7.85.91,2.92,1,3.79,2.88,4.29,4.08.5,1.3.77,3.31.77,5.81,0,3.2-.07,10-7.18,10.8-1.79.2-3.58.49-9.28.55-2.1.02-13.19.05-15.39-.05-6.35-.17-9.21-.86-11.12-1.81-1.83-1.23-2.68-1.75-3.26-5.02-.16-.89-.19-4.34-.19-4.34l9.6-.04c0,2.4,1.16,3.19,1.76,3.59,1.43.95,5.36.81,6.46.81,0,0,7.53.05,12.61.02,2.66-.08,5.13-.16,5.97-1.79.4-.87.47-3.33.13-4.3-.47-1.34-2.01-2.02-2.81-2.12-.7-.1-16.28-.72-18.38-.78s-7.35-.1-9.68-.8c-3.27-.71-4.35-3.29-4.75-4.49-.3-1.2-.55-3.04-.55-4.94,0-5.2,1.2-8.39,3.85-9.8.7-.4,1.5-.7,2.3-.9.9-.2,2-.4,3.5-.6,1.5-.1,3.4-.2,5.7-.3,2.1.1,5,.1,8.6.1m0-1c-3.6,0-6.5,0-8.9.1-2.3.1-4.3.1-5.8.3-1.5.1-2.8.3-3.7.6s-1.8.6-2.5,1c-2.8,1.5-4.12,5.03-4.12,10.63,0,2,.21,3.52.51,4.82.4,1.3.89,2.46,1.69,3.26.9,1,2.16,1.76,3.74,2.2,1.6.4,3.69.64,6.59.74l9.54.39,10.88.39c2.97.12,3.4,1.29,3.46,2.34.05.9.12,2.4-.42,2.91-1.03.96-3.32.92-5.03,1-2.98.14-12.04.12-15.72-.09-4.11-.24-3.91-2.27-3.89-4.29h-11.73v2.2c.08,3.69.47,5.28,1.3,6.65.69,1.14,2.72,3.46,8.46,3.96,9.37.82,16.96.45,21.6.45s9.4-.44,11.32-1.08c5.07-1.68,5.6-6.92,5.74-9.15.17-2.69,0-6.41-.55-7.87-.55-1.66-1.49-3.12-2.89-4.02-.6-.4-1.89-1.35-5.37-1.72-1.3-.14-5.1-.42-8.4-.52-3-.1-12.28-.42-13.81-.5s-3.12-.23-3.42-.33c-1.2-.3-1.89-.73-1.89-2.13,0-.7-.04-1.16.18-1.8.22-.55.6-1.39,4.02-1.54,2.22-.1,11.21-.08,11.21-.08,1.4,0,3.34.1,4.14.1,2.88.23,3.73.84,3.73,3.71l11.64.04c.11-4.38-.13-7.66-2.25-9.54-2.67-2.36-5.6-3.12-19.38-3.12h0Zm-51.49,1c2.8,0,5.3,0,7.2.1,2,.1,3.7.2,5,.4,5.89.64,7.28,3.2,7.68,4.3.82,1.68.72,5.85.72,5.85l-9.7.05c0-.6-.1-1-.2-1.3-.2-.6-.55-1.26-1.29-1.73-1.28-.82-4.82-.87-6.12-.87,0,0-10.43-.04-11.83.06-1.6.1-2.92.31-3.72.51-1,.3-1.56.98-1.86,1.68-.3.6-.26,1.14-.26,2.04-.02,2.33,1.81,3.08,2.81,3.28.3.1,2.96.35,3.97.39,2.07.1,11.17.34,16.8.63,3.34.08,7.25.61,7.85.91,2.92,1,3.79,2.88,4.29,4.08.5,1.3.77,3.31.77,5.81,0,3.2-.07,10-7.18,10.8-1.79.2-3.58.49-9.28.55-2.1.02-13.19.05-15.39-.05-6.35-.17-9.21-.86-11.12-1.81-1.83-1.23-2.68-1.75-3.26-5.02-.16-.89-.19-4.34-.19-4.34l9.6-.04c0,2.4,1.16,3.19,1.76,3.59,1.43.95,5.36.81,6.46.81,0,0,7.53.05,12.61.02,2.66-.08,5.13-.16,5.97-1.79.4-.87.47-3.33.13-4.3-.47-1.34-2.01-2.02-2.81-2.12-.7-.1-16.28-.72-18.38-.78s-7.35-.1-9.68-.8c-3.27-.71-4.35-3.29-4.75-4.49-.3-1.2-.55-3.04-.55-4.94,0-5.2,1.2-8.39,3.85-9.8.7-.4,1.5-.7,2.3-.9.9-.2,2-.4,3.5-.6,1.5-.1,3.4-.2,5.7-.3,2.1.1,5,.1,8.6.1m0-1c-3.6,0-6.5,0-8.9.1-2.3.1-4.3.1-5.8.3-1.5.1-2.8.3-3.7.6s-1.8.6-2.5,1c-2.8,1.5-4.12,5.03-4.12,10.63,0,2,.21,3.52.51,4.82.4,1.3.89,2.46,1.69,3.26.9,1,2.16,1.76,3.74,2.2,1.6.4,3.69.64,6.59.74l9.54.39,10.88.39c2.97.12,3.4,1.29,3.46,2.34.05.9.12,2.4-.42,2.91-1.03.96-3.32.92-5.03,1-2.98.14-12.04.12-15.72-.09-4.11-.24-3.91-2.27-3.89-4.29h-11.73v2.2c.08,3.69.47,5.28,1.3,6.65.69,1.14,2.72,3.46,8.46,3.96,9.37.82,16.96.45,21.6.45s9.4-.44,11.32-1.08c5.07-1.68,5.6-6.92,5.74-9.15.17-2.69,0-6.41-.55-7.87-.55-1.66-1.49-3.12-2.89-4.02-.6-.4-1.89-1.35-5.37-1.72-1.3-.14-5.1-.42-8.4-.52-3-.1-12.28-.42-13.81-.5s-3.12-.23-3.42-.33c-1.2-.3-1.89-.73-1.89-2.13,0-.7-.04-1.16.18-1.8.22-.55.6-1.39,4.02-1.54,2.22-.1,11.21-.08,11.21-.08,1.4,0,3.34.1,4.14.1,2.88.23,3.73.84,3.73,3.71l11.64.04c.11-4.38-.13-7.66-2.25-9.54-2.67-2.36-5.6-3.12-19.38-3.12h0Z" fill="#fff"/></svg>'
                                            )
                                        )
                                    )
                                )
                            ), '"}'
                        )
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ITokenRenderer {
    function getTokenURI(uint256 tokenId, string memory name) external view returns (string memory);
}

pragma solidity ^ 0.8.12;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Utils {
function strlen(string memory s) internal pure returns (uint256) {
uint256 len;
uint256 i = 0;
uint256 bytelength = bytes(s).length;
for (len = 0; i < bytelength; len++) {
bytes1 b = bytes(s)[i];
if (b < 0x80) {
i += 1;
} else if (b < 0xE0) {
i += 2;
} else if (b < 0xF0) {
i += 3;
} else if (b < 0xF8) {
i += 4;
} else if (b < 0xFC) {
i += 5;
} else {
i += 6;
}
}
return len;
}
}