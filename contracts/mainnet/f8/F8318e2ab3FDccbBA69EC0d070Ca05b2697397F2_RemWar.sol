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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// IRem64 Contracts v0.2

pragma solidity ^0.8.12;

interface IRem64 {
    //String No Space
    function getFactionName(uint256 key) external view returns (string memory);

    // INT index
    function getFaction(uint256 tokenId) external view returns (uint256);

    //Human Readable
    function getFactionString(uint256 key)
        external
        view
        returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: MIT
// RemWar Contracts v0.2

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IRem64.sol";

// Game Ownership
error TestModeOff();

// Rem alive status
error RemDead();

// Friendly Fire
error NoFriendlyFire();

// Shot Price Checker
error InvalidShotPrice();
error PaidTooMuch();

// War not started
error WarNotStarted();
error WarStarted();
error WarOver();

contract RemWar is Ownable, ReentrancyGuard {

    // Initialization and constructor
    IRem64 Rem64;
    using SafeMath for uint256;

    constructor(address rem64Address) {
        Rem64 = IRem64(rem64Address);
    }

    /// -------------------------------------
    /// ❌ Test Mode is just for automated
    ///    testing.
    /// -------------------------------------

    bool testModeOff = false;

    modifier notTestMode() {
        if (testModeOff == true) {
            revert TestModeOff();
        }
        _;
    }

    // One way function, rip 🪦
    function disableTestMode() public onlyOwner {
        testModeOff = true;
    }

    /// -------------------------------------
    /// 😵 Alive Or Dead
    /// -------------------------------------

    //ToDo: figure out what default value is and name accordingly;
    mapping(uint256 => bool) public remDead;

    function getRemDead(uint256 tokenId) public view returns (bool) {
        return remDead[tokenId];
    }

    // Owner override for killing Rem64, used for testing.
    function killRem(uint256 tokenId) public onlyOwner notTestMode {
        remDead[tokenId] = true;
    }

    /// -------------------------------------
    /// 💰 Bounties
    /// -------------------------------------

    // Token Bounty
    mapping(uint256 => uint256) public remBounty;

    function getRemBounty(uint256 tokenId) public view returns (uint256) {
        return remBounty[tokenId];
    }

    // Faction Bounty
    uint256[] public factionBounty = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

    function getFactionBounty(uint256 index) public view returns (uint256) {
        return factionBounty[index];
    }

    // Owner override for checking RemBounty, used for testing.
    function changeRemBounty(uint256 tokenId, uint256 bounty)
        public
        onlyOwner
        notTestMode
    {
        remBounty[tokenId] = bounty;
    }

    /// -------------------------------------
    /// 🔫 Shooting
    /// -------------------------------------

    event Shot(uint256 shotta, uint256 target, uint256 amount);

    event Killed(uint256 shotta, uint256 target);

    // REMI64 KILL COUNT VANITY METRIC
    mapping(uint256 => uint256) public killCount;

    // MODIFIERS FOR SHOOTING
    modifier checkAlive(uint256 tokenId) {
        if (remDead[tokenId] == true) {
            revert RemDead();
        }
        _;
    }

    modifier minShotPrice(uint256 shotPrice) {
        if (shotPrice < 0.001 ether) {
            revert InvalidShotPrice();
        }
        _;
    }

    // Check to make sure caller owns the shooter to claim
    modifier shooterIsOwned(uint256 tokenId, address sender) {
        if (Rem64.ownerOf(tokenId) != sender) {
            revert("not owner of");
        }
        _;
    }

    // Helper functions to add/subtract from Rem64 and
    // associated faction.
    function addToBounty(uint256 tokenId, uint256 faction, uint256 bounty) private {
        remBounty[tokenId] += bounty;
        factionBounty[faction] += bounty;
    }

    function subFromBounty(uint256 tokenId, uint256 faction, uint256 bounty) private {
        remBounty[tokenId] -= bounty;
        factionBounty[faction] -= bounty;
    }

    // Helper function to add shooter to has shot list
    // and increment faction shooter counter
    mapping(uint256 => bool) public hasShot;

    uint256[] factionShooterCount = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

    function shottaAdd(uint256 tokenId, uint256 faction) private {
        hasShot[tokenId] = true;
        factionShooterCount[faction] += 1;
    }

    // REAL KILLAS 💧🩸 call this function
    function shootRem(uint256 shotta, uint256 target)
        public
        payable
        checkAlive(shotta)
        checkAlive(target)
        shooterIsOwned(shotta, msg.sender)
        minShotPrice(msg.value)
    {
        require(war == true, "War Not Started");
        require(block.timestamp < endDate, "War is Over");
        //Split payment

        //GET FACTIONS for gas savings
        uint256 shottaFaction = Rem64.getFaction(shotta);
        uint256 targetFaction = Rem64.getFaction(target);

        require(shottaFaction != targetFaction, "Cannot Friendly Fire");

        uint256 targetBounty = remBounty[target];

        // Initial check to see if rem is instantly killed.
        if (targetBounty == 0) {
            remDead[target] = true;
            addToBounty(shotta, shottaFaction, msg.value);
            killCount[shotta] += 1;
            shottaAdd(shotta, shottaFaction);
            emit Killed(shotta, target);
        } else {
            // Branch that deals with real killa logic.
            uint256 damage;
            if (msg.value >= targetBounty) {
                // Headshot 🎯
                remDead[target] = true;
                killCount[shotta] += 1;
                damage = targetBounty;
                emit Killed(shotta, target);
            } else {
                // He's clapped 👏 but still moving.
                damage = Math.mulDiv(msg.value, msg.value, targetBounty);
                emit Shot(shotta, target, msg.value);
            }
            addToBounty(shotta, shottaFaction, msg.value + damage);
            subFromBounty(target, targetFaction, damage);
            shottaAdd(shotta, shottaFaction);
        }
    }

    /// -------------------------------------
    /// 💣 WAR DECLARED
    /// -------------------------------------

    bool war = false;
    uint256 startDate;
    uint256 endDate;

    function getWarStatus() view public returns (bool) {
        return war;
    }

    modifier warOn() {
        if (war == false) {
            revert WarNotStarted();
        }
        _;
    }

    modifier warNotOver() {
        if (war == true && block.timestamp > endDate) {
            revert WarOver();
        }
        _;
    }

    modifier warOff() {
        if (war == true) {
            revert WarStarted();
        }
        _;
    }

    modifier warNeverStarted() {
        if (endDate != 0) {
            revert WarStarted();
        }
        _;
    }

    function startWar(uint256 endingDate)
        public
        onlyOwner
        warOff
        warNeverStarted
    {
        startDate = block.timestamp;
        endDate = endingDate;
        war = true;
    }

    /// -------------------------------------
    /// 💣 WAR ENDED
    /// -------------------------------------

    // Variables to hold the paid totals for withdrawal;
    uint256 public FINAL_BOUNTY;
    uint256 public SHOOTER_BOUNTY;
    uint256 public DEV_TOTAL;

    // PUBLIC function anyone can call to end the
    // war. BUT it has to be called after the
    // official end date, and only if the war
    // is still on going. Consider this a
    // public service should dev team be unable
    // to call off the war.
    uint256 totalPot;

    function endWarOfficially() public warOn {
        if (war == true && block.timestamp > endDate) {
            war = false;
            totalPot = address(this).balance;
            DEV_TOTAL = Math.mulDiv(totalPot, 23, 100);
            SHOOTER_BOUNTY = Math.mulDiv(totalPot, 10, 100);
            FINAL_BOUNTY = Math.mulDiv(totalPot, 67, 100);
            determineWinningFaction();
        }
    }

    uint256 public winningFactionCount = 0;

    function getWinningFactionCount() view public returns (uint256) {
        return winningFactionCount;
    }

    function determineWinningFaction() private {
        uint256 largest = 0; 
        uint256 i;

        for(i = 0; i < factionBounty.length; i++){
            if(factionBounty[i] > largest) {
                largest = factionBounty[i]; 
            } 
        }

        for(i = 0; i < factionBounty.length; i++){
            if(factionBounty[i] == largest) {
                winningFactionCount += 1;
            } 
        }

        FINAL_BOUNTY = Math.mulDiv(FINAL_BOUNTY, 1, winningFactionCount);
        SHOOTER_BOUNTY = Math.mulDiv(SHOOTER_BOUNTY, 1, winningFactionCount);
    }


    // WITHDRAW FOR DEV - 33%
    function withdrawDevWarProceeds() external onlyOwner warOff {
        require(address(this).balance > 0, "Nothing to release"); 
        (bool success, ) = payable(owner()).call{value: DEV_TOTAL}("");
        require(success, "withdraw failed");
    }

    function emergencyWithdraw() external onlyOwner {
        require(address(this).balance > 0, "Nothing to release");
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "withdraw failed");
    }
    // Modifier to ensure token's faction
    // won for a claim.
    modifier tokenWon(uint256 tokenId) {
        uint256 faction = Rem64.getFaction(tokenId);
        uint256 factionAmount = factionBounty[faction];

        for (uint256 i = 0; i < factionBounty.length; i++) {
            if (factionBounty[i] > factionAmount) {
                revert("Faction didn't win");
            }
        }
        _;
    }

    // modifier for SHOOTER CLAIM - 10%
    mapping(uint256 => bool) public shooterClaimed;

    // Claim 10% for having fired a shot and being on the
    // the winning faction

    function shooterClaim(uint256 tokenId)
        public
        warOff
        tokenWon(tokenId)
        shooterIsOwned(tokenId, msg.sender)
        nonReentrant
    {
        require(hasShot[tokenId] == true, "Shooter never shot");
        require(shooterClaimed[tokenId] != true, "Already Claimed");
        
        uint256 numberOfShooters = factionShooterCount[Rem64.getFaction(tokenId)];
        uint256 withdrawAmount = Math.mulDiv(SHOOTER_BOUNTY, 1, numberOfShooters);

        (bool success, ) = payable(address(msg.sender)).call{
            value: withdrawAmount
        }("");

        shooterClaimed[tokenId] = true;
        require(success, "withdraw failed");
    }

    // modifier for SOLDIER CLAIM
    // FINAL BOUNTY * (FACTION BOUNTY/TOKEN BOUTNY)
    mapping(uint256 => bool) public soldierClaimed;

    modifier soldierClaimedCheck(uint256 tokenId) {
        if (soldierClaimed[tokenId] == true) {
            revert("Soldier already claimed");
        }
        _;
    }

    // Claim the full bounty the shooter has accumulated
    // throughout play

    function getPotentialWinnings(uint256 tokenId) view public returns (uint256){
        uint256 faction = Rem64.getFaction(tokenId);
        uint256 facBounty = factionBounty[faction];
        return Math.mulDiv(FINAL_BOUNTY, remBounty[tokenId],facBounty);
    }

    function soldierClaim(uint256 tokenId)
        public
        warOff
        tokenWon(tokenId)
        checkAlive(tokenId)
        soldierClaimedCheck(tokenId)
        shooterIsOwned(tokenId, msg.sender)
        nonReentrant
    {
        require(address(this).balance > 0, "Nothing to release");

        uint256 faction = Rem64.getFaction(tokenId);

        uint256 facBounty = factionBounty[faction];

        uint256 withdrawAmount = Math.mulDiv(FINAL_BOUNTY, remBounty[tokenId],facBounty);

        (bool success, ) = payable(address(msg.sender)).call{
            value: withdrawAmount
        }("");

        soldierClaimed[tokenId] = true;

        require(success, "withdraw failed");
    }
}