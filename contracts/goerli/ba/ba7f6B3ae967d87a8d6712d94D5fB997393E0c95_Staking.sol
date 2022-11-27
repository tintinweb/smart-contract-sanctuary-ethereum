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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
pragma solidity ^0.8.0;

interface IStaking {
    function rewardToken() external view returns (uint256);

    function stakingToken() external view returns (uint256);

    function allStakedBalance() external view returns (uint256);

    function startStakeTimestamp() external view returns (uint256);

    function startWitdrawTimestamp() external view returns (uint256);

    function endStakeTimestamp() external view returns (uint256);

    function endWitdrawTimestamp() external view returns (uint256);

    function duration() external view returns (uint256);

    function StakedReward() external view returns (uint256);

    function allStakedBalances(uint256 index) external view returns (uint256);

    function allRewards(uint256 index) external view returns (uint256);

    function stakers(uint256 index) external view returns (address);

    function stakedTime(address user) external view returns (uint256);

    function stakedBalance(address user) external view returns (uint256);

    function stake(uint256 amount) external;

    function unstake() external;

    function getReward(address user) external view returns (uint256);

    function setReward(uint256 amount) external;

    function addReward(uint256 amount) external;

    function setStake() external;

    function setWitdraw() external;

    function witdrawOwnerLP(uint256 amount) external;

    function witdrawOwnerReward(uint256 amount) external;

    function setDuration(uint256 timestamp) external;

    function topTen()
        external
        view
        returns (address[] memory TopTen, uint256[] memory TopTenAmount);
    
    function findIndex(address sender) external view returns (uint256);

    function _getReward(address user)
        external
        view
        returns (uint256 commingReward, uint256 reward);

    function calculate(uint256 deposited, uint256 Balance)
        external
        pure
        returns (uint256 percentShares);

    function percentageShare(address _sender) external view returns (uint256);

    function getAll(address user)
        external
        view
        returns (
            uint256 percentShares,
            uint256 shares,
            uint256 value,
            uint256 reward
        );





    function isStartedStake() external view returns (bool start);

    function isStartedWitdraw() external view returns (bool start);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//* ================ IMPORTS ================ *//

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IStaking.sol";

contract Staking is Ownable, ReentrancyGuard {
    //* ========== STATE PUBLIC VARIABLES ========== *//

    IERC20 public rewardToken; //?REWARD TOKEN ADDRESS
    IERC20 public stakingToken; //?LP TOKEN ADDRESS
    uint256 public allStakedBalance; //? ALL STAKE BALANCE OF CONTRACT
    uint256 public startStakeTimestamp; //?TIMESTAMP STAKE START
    uint256 public startWitdrawTimestamp; //?TIMESTAMP WITDRAW START
    uint256 public endStakeTimestamp; //?TIMESTAMP STAKE END
    uint256 public endWitdrawTimestamp; //?TIMESTAMP WITDRAW END
    uint256 public duration;
    uint256 public StakedReward; //?REWARD OF THIS MONTH
    uint256[] public allStakedBalances; //?ALL STAKES BALANCES FROM BEGINNING
    uint256[] public allRewards; //?ALL REWARDS FROM BEGINNING
    address[] public stakers;
    mapping(address => uint32) public stakedTime; //?WHENE THE USER DID STAKE
    mapping(address => uint256) public stakedBalance; //? BALANCE OF EACH PERSON IN CONTRACT
    //* ========== STATE PRIVATE VARIABLES ========== *//
    bool private timeSet = false; //?BOOLEAN FOR SET THE TIME
    uint32 private stakeTimes; //?HOW MANY STAKE TIMES ARE SET
    uint32 private witdrawTimes; //?HOW MANY WITDRAW TIMES ARE SET
    mapping(address => uint256) private stakedBalanceCopy; //?A COPY FOR stakedBalance ;

    //* ================= EVENTS ================= *//
    event rewardAmount(address indexed user, uint256 reward);
    event Stake(address indexed user, uint256 amount, uint256 endTime);
    event Unstake(address indexed user, uint256 amountStaked, uint256 shares);
    event SetReward(address user, uint256 reward);

    //* ============== CONSTRUCTOR ============== *//
    constructor(address _stakingToken, address _rewardToken) {
        //! STAKING TOKEN HAS TO BE A PAIR ADDRESS
        stakingToken = IERC20(_stakingToken); //?LP TOKEN ADDRESS

        rewardToken = IERC20(_rewardToken); //? REWARD ROKEN ADDRESS
    }

    //* =============== MODIFIERS =============== *//
    modifier haveReward(address sender) {
        require(stakedTime[msg.sender] != 0, "you did not stake");
        require(
            stakedTime[sender] != witdrawTimes + 1,
            "You have already withdrawn your reward"
        );
        _;
    }
    modifier startStake() {
        require(
            block.timestamp >= startStakeTimestamp &&
                block.timestamp <= endStakeTimestamp,
            "you cant stake at this time"
        );

        _;
    }
    modifier zeroAmount(uint256 amount) {
        require(amount != 0, "zero amount");
        _;
    }
    modifier haveShares(address sender) {
        require(stakedBalance[sender] != 0, "you have no shares");

        _;
    }

    modifier startWitdraw(address sender) {
        require(
            block.timestamp >= startWitdrawTimestamp &&
                block.timestamp <= endWitdrawTimestamp,
            "you cant witdraw at this time"
        );

        _;
    }

    //* ============== SEND METHODS ============== *//

    function stake(uint256 _amount)
        external
        nonReentrant
        startStake
        zeroAmount(_amount)
    {
        require(
            stakedBalance[msg.sender] == 0,
            "you have already staked amount"
        );

        stakedTime[msg.sender] = witdrawTimes + 1;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        addStaker(_amount, msg.sender);
        stakedBalance[msg.sender] += _amount;

        stakedBalanceCopy[msg.sender] = stakedBalance[msg.sender];
        allStakedBalance += _amount;
    }

    function unstake()
        external
        nonReentrant
        startWitdraw(msg.sender)
        haveShares(msg.sender)
    {
        uint256 deposited = stakedBalance[msg.sender];
        (, uint256 reward) = _getReward(msg.sender);
        require(reward == 0, "you have to get your reward first");

        stakedBalance[msg.sender] = 0;
        stakedTime[msg.sender] = 0;
        removeStaker(msg.sender);
        uint256 shares = calculate(deposited, allStakedBalance);
        allStakedBalance -= deposited;

        emit Unstake(msg.sender, deposited, shares);
        stakingToken.transfer(msg.sender, deposited);
    }

    function getReward(address sender)
        external
        nonReentrant
        haveReward(msg.sender)
        returns (uint256 reward)
    {
        require(sender == msg.sender);

        (, reward) = _getReward(sender);
        require(reward != 0, "no reward to recieve");
        stakedTime[sender] = witdrawTimes + 1;

        rewardToken.transfer(sender, reward);
        emit rewardAmount(sender, reward);
    }

    function setReward(uint256 _reward) external onlyOwner {
        require(_reward > 0, "Cannot setReward 0");

        rewardToken.transferFrom(msg.sender, address(this), _reward + 3000);
        StakedReward = _reward;
        emit SetReward(msg.sender, _reward);
    }

    function addReward(uint256 _reward) external onlyOwner {
        require(_reward > 0, "Cannot setReward 0");

        rewardToken.transferFrom(msg.sender, address(this), _reward);
        StakedReward += _reward;

        emit SetReward(msg.sender, _reward);
    }

    function setStake() external onlyOwner {
        require(
            !timeSet,
            "you can't set stake until witdraw is still going on "
        );
        startWitdrawTimestamp = 0;
        endWitdrawTimestamp = 0;
        startStakeTimestamp = block.timestamp;
        endStakeTimestamp = block.timestamp + 24 hours;
        stakeTimes++;

        timeSet = true;
    }

    function setWitdraw() external onlyOwner {
        require(timeSet, "you can't set witdraw until stake is still going on");
        startStakeTimestamp = 0;
        endStakeTimestamp = 0;
        witdrawTimes++;
        allRewards.push(StakedReward);
        allStakedBalances.push(allStakedBalance);
        StakedReward = 0;
        timeSet = false;
        startWitdrawTimestamp = block.timestamp;
        endWitdrawTimestamp = block.timestamp + 24 hours;
    }

    function witdrawOwnerLP(uint256 amount)
        external
        onlyOwner
        zeroAmount(amount)
    {
        stakingToken.transfer(owner(), amount);
    }

    function witdrawOwnerReward(uint256 amount)
        external
        onlyOwner
        zeroAmount(amount)
    {
        require(amount < rewardToken.balanceOf(address(this)) - 3000);
        rewardToken.transfer(owner(), amount);
    }

    function setDuration(uint256 timestamp) external onlyOwner {
        duration = timestamp;
    }

    //* ============== INTERNAL METHODS ============== *//

    function removeStaker(address sender) internal {
        uint256 index = findIndex(sender) - 1;
        for (uint256 i = index; i < stakers.length - 1; i++) {
            stakers[i] = stakers[i + 1];
        }
        stakers.pop();
    }

    function addStaker(uint256 _amount, address sender) internal {
        uint256 len = stakers.length;
        uint256 index;
        if (len != 0) {
            for (uint256 i = 0; i < len; ) {
                uint256 stakerShare = stakedBalance[stakers[i]];
                if (_amount > stakerShare) {
                    index = i;
                    break;
                }
                unchecked {
                    i++;
                }
            }
            stakers.push(stakers[len - 1]);
            for (uint256 j = len - 1; j > index; ) {
                stakers[j] = stakers[j - 1];

                unchecked {
                    j--;
                }
            }
            stakers[index] = sender;
        } else stakers.push(sender);
    }

    //* ============== CALL METHODS ============== *//
    function topTen()
        external
        view
        returns (address[] memory TopTen, uint256[] memory TopTenAmount)
    {
        uint256 len = stakers.length;
        if (len > 10) {
            len = 10;
        }
        TopTen = new address[](len);
        TopTenAmount = new uint256[](len);
        for (uint256 i = 0; i < stakers.length; ) {
            TopTen[i] = stakers[i];
            TopTenAmount[i] = stakedBalance[stakers[i]];
            if (i == len - 1) {
                break;
            }
            unchecked {
                i++;
            }
        }
    }

    function findIndex(address sender) public view returns (uint256) {
        for (uint256 i = 0; i <= stakers.length; i++) {
            if (stakers[i] == sender) {
                return i + 1;
            }
        }
        return 0;
    }

    function _getReward(address sender)
        public
        view
        returns (uint256 commingReward, uint256 reward)
    {
        uint256 percentShares;
        if (witdrawTimes >= stakedTime[sender]) {
            for (uint256 i = stakedTime[sender]; i <= witdrawTimes; i++) {
                percentShares = calculate(
                    stakedBalanceCopy[sender],
                    allStakedBalances[i - 1]
                );

                reward += Math.ceilDiv(
                    (percentShares * allRewards[i - 1]),
                    100 * 10**18
                );
            }

            if (reward > 0) commingReward = 0;
        }

        if (StakedReward != 0 && commingReward == 0) {
            percentShares = calculate(
                stakedBalanceCopy[sender],
                allStakedBalance
            );
            commingReward =
                Math.ceilDiv((percentShares * StakedReward), 100 * 10**18) +
                reward;
        }
    }

    function calculate(uint256 deposited, uint256 Balance)
        public
        pure
        returns (uint256 percentShares)
    {
        uint256 div = 100 * 10**18;
        percentShares = Math.ceilDiv(deposited * div, Balance);
    }

    function percentageShare(address _sender) public view returns (uint256) {
        uint256 deposited = stakedBalance[_sender];
        return calculate(deposited, allStakedBalance);
    }

    function getAll(address sender)
        public
        view
        returns (
            uint256 percentShares,
            uint256 shares,
            uint256 reward
        )
    {
        percentShares = percentageShare(sender);
        shares = stakedBalance[sender];
        (uint256 commingReward, uint256 reward_) = _getReward(sender);

        if (reward != 0) reward = reward_;
        else reward = commingReward;
    }

    function isStartedStake() public view returns (bool start) {
        start = false;
        if (
            block.timestamp >= startStakeTimestamp &&
            block.timestamp <= endStakeTimestamp
        ) start = true;
    }

    function isStartedWitdraw() public view returns (bool start) {
        start = false;
        if (
            block.timestamp >= startWitdrawTimestamp &&
            block.timestamp <= endWitdrawTimestamp
        ) start = true;
    }
}