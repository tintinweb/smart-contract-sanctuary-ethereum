// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IStaking.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Staking is IStaking, Ownable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private stakeholdersCount;
    IERC20 private immutable token;

    uint256 public startTimeRewards;
    uint256 public finishTimeRewards;

    mapping(address => Stakeholder) public stakeholders;
    mapping(address => bool) public stakeHoldersInPool;

    uint256 private cooldown;
    uint256 private stakingPeriod;
    uint256 private fee;
    uint256 private stakingPoolCap;
    uint256 private stakingPoolApy;
    uint256 private stakingPoolTotalAmount;
    uint256 private stakingCap;
    uint256 private rewardsAmount;
    uint256 private rewardsApy;
    uint256 private usedAmounts;

    constructor(address _token) {
        require(_token != address(0), "Staking: Invalid token address");
        token = IERC20(_token);

        cooldown = 864000;
        stakingPeriod = 5184000;
        fee = 40; // 40%
        stakingPoolCap = 5000000;
        stakingPoolApy = 10; // 10%
        stakingCap = 5000000;
    }

    modifier onlyStaker() {
        require(
            stakeholders[msg.sender].isStaked == true,
            "Staking: Only staker can call function"
        );
        _;
    }

    modifier onlyNotStaker() {
        require(
            stakeholders[msg.sender].isStaked == false,
            "Staking: all except of staker can call function"
        );
        _;
    }

    function setRewards(
        uint256 _start,
        uint256 _finish,
        uint256 _rewardsAmount,
        uint256 _apy
    ) external override onlyOwner {
        require(
            _start > finishTimeRewards,
            "Staking: previous reward`s period is not finished"
        );

        // check if all stakeholders unstake
        require(
            stakeholdersCount.current() == 0,
            "Staking: not all stakeholders unstake their tokens"
        );
        require(
            _start >= block.timestamp && _finish > _start,
            "Staking: not correct time interval"
        );
        require(
            _rewardsAmount > 0,
            "Staking: rewards amount should be more than zero"
        );
        require(_apy > 0, "Staking: apy should be more than zero");

        startTimeRewards = _start;
        finishTimeRewards = _finish;
        rewardsAmount = _rewardsAmount;
        rewardsApy = _apy;

        emit AddedReward(_start, _finish, _rewardsAmount, _apy);
    }

    function stake(uint256 _amount) external override onlyNotStaker {
        _stake(_amount);
    }

    function addToStakingPool(uint256 _amount) external override onlyNotStaker {
        require(
            _amount + stakingPoolTotalAmount <= stakingPoolCap,
            "Staking: staking pool is over"
        );
        stakingPoolTotalAmount += _amount;
        stakeHoldersInPool[msg.sender] = true;
        _stake(_amount);
    }

    function unstake() external override onlyStaker {
        uint256 stakedTime = stakeholders[msg.sender].stakeTime;
        require(
            block.timestamp > stakedTime + cooldown,
            "Staking: cooldown period is not finished"
        );
        stakeholders[msg.sender].unstakeTime = block.timestamp;
        uint256 unstakedTime = stakeholders[msg.sender].unstakeTime;
        bool isInStakinPool = stakeHoldersInPool[msg.sender];
        uint256 stakedAmount = stakeholders[msg.sender].stakedAmount;
        uint256 rewardAmount;
        if (block.timestamp < stakedTime + stakingPeriod) {
            if (isInStakinPool) {
                rewardAmount =
                    (calculateRewardAmount(
                        stakingPoolTotalAmount,
                        stakedTime,
                        unstakedTime,
                        stakingPoolApy
                    ) * fee) /
                    100;
            } else {
                rewardAmount =
                    (calculateRewardAmount(
                        stakedAmount,
                        stakedTime,
                        unstakedTime,
                        rewardsApy
                    ) * fee) /
                    100;
            }
        } else {
            // block.timestamp >= stakedTime + stakingPeriod
            if (isInStakinPool) {
                rewardAmount = calculateRewardAmount(
                    stakingPoolTotalAmount,
                    stakedTime,
                    unstakedTime,
                    stakingPoolApy
                );
            } else {
                rewardAmount = calculateRewardAmount(
                    stakedAmount,
                    stakedTime,
                    unstakedTime,
                    rewardsApy
                );
            }
        }

        uint256 totalWithdrawAmount = stakeholders[msg.sender].stakedAmount +
            rewardAmount;
        usedAmounts += rewardAmount;

        token.transfer(msg.sender, totalWithdrawAmount);
        emit Unstaked(msg.sender, totalWithdrawAmount, rewardAmount);

        stakeholdersCount.decrement();

        deleteFromStake(msg.sender);
    }

    function withdrawAmounts() external override onlyOwner {
        uint256 contractBalance = token.balanceOf(address(this));
        require(
            contractBalance > 0,
            "Staking: contract has not tokens to withdraw"
        );
        token.transfer(msg.sender, contractBalance);
    }

    function calculateRewardAmount(
        uint256 stakedAmount,
        uint256 startStakeTime,
        uint256 endStakeTime,
        uint256 apy
    ) private pure returns (uint256) {
        // reward amount = staked amount * reward rate(apy) * time diff / 365 days
        return
            (((stakedAmount * apy) / 100) * (endStakeTime - startStakeTime)) /
            31536000;
    }

    function deleteFromStake(address stakehokder) private {
        if (stakeHoldersInPool[stakehokder]) {
            stakeHoldersInPool[stakehokder] = false;
        }
        stakeholders[stakehokder].isStaked = false;
    }

    function _stake(uint256 _amount) private {
        require(
            block.timestamp >= startTimeRewards,
            "Staking: stake early than reward`s interval is started"
        );
        require(
            block.timestamp <= finishTimeRewards,
            "Staking: stake lately than reward`s interval is finished"
        );
        require(_amount > 0, "Staking: amount should be more than zero");
        require(
            token.balanceOf(msg.sender) >= _amount,
            "Staking: cannot stake more than you own"
        );
        require(
            token.balanceOf(address(this)) + _amount <= stakingCap,
            "Staking: staking capability is over"
        );
        //check the max rewards
        uint256 maxAvailableReward;
        if (stakeHoldersInPool[msg.sender]) {
            maxAvailableReward = calculateRewardAmount(
                _amount,
                block.timestamp,
                finishTimeRewards,
                stakingPoolApy
            );
        } else {
            maxAvailableReward = calculateRewardAmount(
                _amount,
                block.timestamp,
                finishTimeRewards,
                rewardsApy
            );
        }
        require(
            usedAmounts + maxAvailableReward <= rewardsAmount,
            "Staking: available rewards is over"
        );

        token.transferFrom(msg.sender, address(this), _amount);

        stakeholdersCount.increment();

        stakeholders[msg.sender].isStaked = true;
        stakeholders[msg.sender].stakedAmount = _amount;
        stakeholders[msg.sender].stakeTime = block.timestamp;

        emit Staked(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStaking {
    event AddedReward(
        uint256 start,
        uint256 finish,
        uint256 rewardsAmount,
        uint256 apy
    );
    event Staked(address indexed sender, uint256 amount);
    event Unstaked(address indexed recipient, uint256 amount, uint256 reward);

    struct Stakeholder {
        bool isStaked;
        uint256 stakedAmount;
        uint256 stakeTime;
        uint256 unstakeTime;
    }

    function setRewards(
        uint256 _start,
        uint256 _finish,
        uint256 _rewardsAmount,
        uint256 _apy
    ) external;

    function addToStakingPool(uint256 _amount) external;

    function stake(uint256 _amount) external;

    function unstake() external;

    function withdrawAmounts() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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