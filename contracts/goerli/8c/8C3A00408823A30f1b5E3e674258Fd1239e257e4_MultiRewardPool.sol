//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./LPTokenWrapper.sol";
import "./interfaces/IERC20Metadata.sol";

/**
 * @title MultiRewardPool
 * @author Empire Capital
 * @dev Stake token to earn multiple different reward tokens

 Credit to Synthetix for original StakingReward contract
 */
contract MultiRewardPool is LPTokenWrapper, ReentrancyGuard {
    using SafeERC20 for IERC20Metadata;
    uint256 public immutable stakingTokenMultiplier;

    struct PoolInfo {
        IERC20Metadata rewardTokenAddress;
        uint256 rewardPoolID;
        uint256 duration;
        uint256 periodFinish;
        uint256 startTime;
        uint256 lastUpdateTime;
        uint256 rewardRate;
        uint256 rewardPerTokenStored;
    }

    struct UserRewardInfo {
        uint256 rewards;
        uint256 userRewardPerTokenPaid;
    }

    PoolInfo[] public poolInfo;

    mapping(address => bool) public addedRewardTokens;
    mapping(uint256 => mapping(address => UserRewardInfo)) public rewardsInPool;

    event Withdrawn(address indexed user, uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event RewardPaid(
        address indexed user,
        address rewardToken,
        uint256 rewardAmount
    );
    event RewardPoolAdded(
        uint256 rewardPoolID,
        address rewardTokenAddress
    );
    event RewardPoolStarted(
        uint256 rewardPoolID,
        address rewardTokenAddress,
        uint256 rewardAmount,
        uint256 rewardDuration,
        uint256 rewardPeriodFinish
    );
    event RewardPoolExtended(
        uint256 rewardPoolID,
        address rewardTokenAddress,
        uint256 oldRewardAmount,
        uint256 newRewardAmount,
        uint256 totalRewardAmount,
        uint256 rewardDuration,
        uint256 rewardPeriodFinish
    );

    constructor(
        address _stakingToken,
        address _treasury,
        uint256 _devFee,
        uint256 _tokenFee
    )
        public
        LPTokenWrapper(_devFee, _stakingToken, _treasury, _tokenFee)
    {
        require(
            _stakingToken != address(0) &&
                _treasury != address(0),
            "!constructor"
        );
        stakingTokenMultiplier =
            10**uint256(IERC20Metadata(_stakingToken).decimals());
    }

    /* @dev Updates the rewards a user has earned */
    function updateReward(address account) internal {
        // loop through all reward pools for user
        for (uint256 i = 0; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];

            if (address(pool.rewardTokenAddress) == address(0)) {
                continue;
            } else {
                updateRewardPerTokenStored(i);
                rewardsInPool[i][account].rewards = earned(account, i);
                rewardsInPool[i][account].userRewardPerTokenPaid = pool.rewardPerTokenStored;
            }
        }
    }

    /* Updates the amount of rewards to distribute in a pool per staked token */
    function updateRewardPerTokenStored(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];

        pool.rewardPerTokenStored = rewardPerToken(_pid);
        pool.lastUpdateTime = lastTimeRewardsActive(_pid);
    }

    /* @dev Updates the last time the calculations were done for pool rewards */
    function lastTimeRewardsActive(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        return Math.min(block.timestamp, pool.periodFinish);
    }

    /* @dev Returns the time that a specified pool will end */
    function endDate(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];

        return pool.periodFinish;
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    /* @dev Returns the current rate of rewards per token */
    function rewardPerToken(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];

        // Do not distribute rewards before startTime.
        if (block.timestamp < pool.startTime) {
            return 0;
        }

        if (totalSupply == 0) {
            return pool.rewardPerTokenStored;
        }

        // The returrn value is time-based on last time the contract had rewards active multipliede by the reward-rate.
        // It's evened out with a division of bonus effective supply.
        return
            pool.rewardPerTokenStored.add(
                lastTimeRewardsActive(_pid)
                    .sub(pool.lastUpdateTime)
                    .mul(pool.rewardRate)
                    .mul(stakingTokenMultiplier)
                    .div(totalSupply)
            );
    }

    /** @dev Returns the claimable tokens for user.*/
    function earned(address account, uint256 _pid)
        public
        view
        returns (uint256)
    {
        uint256 reward = rewardsInPool[_pid][msg.sender].rewards;
        uint256 rewardPerTokenPaid = rewardsInPool[_pid][msg.sender].userRewardPerTokenPaid;

        return
            _balances[account]
                .balance
                .mul(rewardPerToken(_pid)
                .sub(rewardPerTokenPaid))
                .div(stakingTokenMultiplier)
                .add(reward);
    }

    /** @dev Staking function which updates the user balances in the parent contract */
    function stake(uint256 amount) public override nonReentrant {
        require(amount > 0, "Cannot stake 0");
        updateReward(msg.sender);
        super.stake(amount);
        emit Staked(msg.sender, amount);
    }

    /** @dev Withdraw function, this pool contains a tax which is defined in the constructor */
    function withdraw(uint256 amount) public override nonReentrant {
        require(amount > 0, "Cannot withdraw 0");
        updateReward(msg.sender);
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    /** @dev Ease-of-access function for user to remove assets from the pool */
    function exit() external nonReentrant {
        getReward();
        withdraw(balanceOf(msg.sender));
    }

    /** @dev Sends out the reward tokens to the user */
    function getReward() public nonReentrant {
        updateReward(msg.sender);
        uint256 arraysize = poolInfo.length;

        // loop through all the reward pools for a user
        for (uint256 i = 0; i < arraysize; i++) {
            PoolInfo storage pool = poolInfo[i];
            uint256 reward = rewardsInPool[i][msg.sender].rewards;

            if (address(pool.rewardTokenAddress) == address(0) || reward == 0) {
                continue;
            } else {
                rewardsInPool[i][msg.sender].rewards = 0;
                pool.rewardTokenAddress.safeTransfer(msg.sender, reward);
                emit RewardPaid(
                    msg.sender,
                    address(pool.rewardTokenAddress),
                    reward
                );
            }
        }
    }

    /** @dev Sends out the reward tokens to the user, while also re-staking reward tokens if it is the same as the staking tokens */
    function getRewardCompound() public nonReentrant {
        updateReward(msg.sender);

        // loop through all the reward pools for a user
        for (uint256 i = 0; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            uint256 reward = rewardsInPool[i][msg.sender].rewards;

            if (address(pool.rewardTokenAddress) == address(0) || reward == 0) {
                continue;
            } else {
                rewardsInPool[i][msg.sender].rewards = 0;

                if (address(pool.rewardTokenAddress) == address(stakingToken)) {
                    stake(reward);
                } else {
                    pool.rewardTokenAddress.safeTransfer(msg.sender, reward);
                    emit RewardPaid(
                        msg.sender,
                        address(pool.rewardTokenAddress),
                        reward
                    );
                }
            }
        }
    }

    /** @dev Adds a new reward pool */
    function addRewardPool(IERC20Metadata _rewardToken)
        public
        onlyOwner
    {
        require(address(_rewardToken) != address(0), "Cannot add burn address");
        require(
            !addedRewardTokens[address(_rewardToken)],
            "Token already added"
        );
        // calculate info relevant for storing in the pool array
        uint256 totalPools = poolInfo.length;
        uint256 _rewardTokenID = totalPools++;

        poolInfo.push(
            PoolInfo({
                rewardTokenAddress: _rewardToken,
                rewardPoolID: _rewardTokenID,
                duration: 0,
                periodFinish: 0,
                startTime: 0,
                lastUpdateTime: 0,
                rewardRate: 0,
                rewardPerTokenStored: 0
            })
        );

        addedRewardTokens[address(_rewardToken)] = true;

        emit RewardPoolAdded(_rewardTokenID, address(_rewardToken));
    }

    /** @dev Called to add more reward tokens to an existing pool */
    function extendRewardPool(uint256 _pid, uint256 _reward, uint256 _duration)
        external
        onlyOwner
    {
        require(_reward > 0, "Can not add zero balance");
        require(_duration > 0, "Must define valid duration length");

        PoolInfo storage pool = poolInfo[_pid];
        uint256 timeNow = block.timestamp;
        uint256 rewardsRemaining;
        uint256 totalRewards;

        // Transfer reward token from caller to contract
        pool.rewardTokenAddress.safeTransferFrom(
            msg.sender,
            address(this),
            _reward
        );

        // Update reward per token stored value + last updated value
        updateRewardPerTokenStored(_pid);

        // Update duration of pool
        pool.duration = _duration;

        // Update reward rate
        // if pool has already finished
        if (timeNow > pool.periodFinish) {
            pool.rewardRate = _reward.div(_duration);
            totalRewards = _reward;
        } else {
            // if pool has not finished yet
            // Remaining time for the pool
            uint256 remainingTime = pool.periodFinish.sub(timeNow);
            // And the rewards
            rewardsRemaining = remainingTime.mul(pool.rewardRate);
            // Find new amount of rewards in pool
            totalRewards = rewardsRemaining.add(_reward);
            // Set the current rate
            pool.rewardRate = totalRewards.div(pool.duration);            
        }

        // Set the last updated time
        pool.lastUpdateTime = timeNow;

        // Add the period to be equal to duration set
        pool.periodFinish = timeNow.add(pool.duration);

        emit RewardPoolExtended(
            _pid,
            address(pool.rewardTokenAddress),
            rewardsRemaining,
            _reward,
            totalRewards,
            pool.duration,
            pool.periodFinish
        );
    }

    /** @dev Called to start the pool. Reward amount + duration is defined in the input. */
    function startRewardPool(uint256 _pid, uint256 _reward, uint256 _duration)
        external
        onlyOwner
    {
        require(_reward > 0, "Can not add zero balance");
        require(_duration > 0, "Must define valid duration length");

        PoolInfo storage pool = poolInfo[_pid];
        uint256 timeNow = block.timestamp;

        // Transfer reward token from caller to contract
        pool.rewardTokenAddress.safeTransferFrom(
            msg.sender,
            address(this),
            _reward
        );

        // Set reward values
        updateRewardPerTokenStored(_pid);

        // Set duration of pool
        pool.duration = _duration;

        // Set the current rate
        pool.rewardRate = _reward.div(pool.duration);

        // Set the last updated time
        pool.lastUpdateTime = timeNow;

        // Set the initial start time
        pool.startTime = timeNow;

        // Add the period to be equal to duration set
        pool.periodFinish = timeNow.add(pool.duration);
        emit RewardPoolStarted(
            _pid,
            address(pool.rewardTokenAddress),
            _reward,
            pool.duration,
            pool.periodFinish
        );
    }

    /** @dev Ejects any remaining tokens from the reward pool specified.
             Callable only after the pool has started and the pools reward distribution period has finished.
     */
    function eject(uint256 _pid) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];

        require(block.timestamp >= pool.periodFinish.add(24 hours),
            "Cannot eject before pool ends or within 24 hours of finish"
        );
        uint256 currBalance = pool.rewardTokenAddress.balanceOf(address(this));

        // If Staking Token = Reward Token of Pool, do not withdraw the users staked tokens
        if (address(stakingToken) == address(pool.rewardTokenAddress)) {
            currBalance = currBalance.sub(totalSupply);
        }

        pool.rewardTokenAddress.safeTransfer(msg.sender, currBalance);
    }

    /** @dev Ejects any remaining tokens from all reward pool */
    function ejectAll() public onlyOwner {
        // loop through all reward pools to eject all
        for (uint256 i = 0; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];

            if (address(pool.rewardTokenAddress) == address(0)) {
                continue;
            } else {
                eject(i);
            }
        }
    }

    /** @dev Removes a specific pool in the array, leaving the pid slot empty */
    function removeRewardPool(uint256 _pid) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        addedRewardTokens[address(pool.rewardTokenAddress)] = false;
        eject(_pid);
        delete poolInfo[_pid];
    }

    /** @dev Removes all reward pools */
    function removeAllRewardPools() external onlyOwner {
        for (uint256 i = 0; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            addedRewardTokens[address(pool.rewardTokenAddress)] = false;
        }
        ejectAll();
        delete poolInfo;
    }

    /** @dev Forcefully retire a pool. Only sets the period finish to 0. Will prevent more rewards from being distributed */
    function kill(uint256 _pid) external onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];

        pool.periodFinish = block.timestamp;
    }

    /** @dev Added to support recovering tokens that are stuck on the contract */
    function emergencyWithdraw(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        require(
            tokenAddress != address(stakingToken),
            "Cannot withdraw staking token"
        );
        require(
            addedRewardTokens[tokenAddress] == false,
            "Cannot withdraw reward token"
        );
        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);
    }

    /** @dev Sets a new treasury address */
    function setNewTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }
    
    // Gets total number of pools
    function getTotalPools() external view returns(uint256) {
        return poolInfo.length;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

abstract contract LPTokenWrapper is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable stakingToken;
    uint256 public immutable devFee;        // 10 = 1%

    // Returns the total staked tokens within the contract
    uint256 public totalSupply;
    uint256 public tokenFee;

    struct Balance {
        uint256 balance;
    }

    address public treasury;    // The address to receive devFee

    mapping(address => Balance) internal _balances;

    constructor(
        uint256 _devFee,
        address _stakingToken,
        address _treasury,
        uint256 _tokenFee
    ) public {
        devFee = _devFee;
        stakingToken = IERC20(_stakingToken);
        treasury = _treasury;
        tokenFee = _tokenFee;
    }

    // Returns staking balance of the account
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account].balance;
    }

    // Stake funds into the pool
    function stake(uint256 amount) public virtual {
        // Transfer staking token from caller to contract
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);

        // Increment sender's balances and total supply
        if (tokenFee > 0) {
            uint256 tokenFeeBalance = amount.mul(tokenFee).div(10000);
            uint256 stakedBalance = amount.sub(tokenFeeBalance);
            _balances[msg.sender].balance = _balances[msg.sender].balance.add(stakedBalance);
            totalSupply = totalSupply.add(stakedBalance);
            return;
        } else {
            _balances[msg.sender].balance = _balances[msg.sender].balance.add(amount);
            totalSupply = totalSupply.add(amount);
            return;
        }

    }

    // Subtract balances withdrawn from the user
    function withdraw(uint256 amount) public virtual {
        // Reduce sender's balances and total supply
        totalSupply = totalSupply.sub(amount);
        _balances[msg.sender].balance = _balances[msg.sender].balance.sub(
            amount
        );

        // Calculate the withdraw tax
        uint256 tax = amount.mul(devFee).div(1000);

        // Transfer the tokens to user
        stakingToken.safeTransfer(msg.sender, amount - tax);
        // Tax to treasury
        stakingToken.safeTransfer(treasury, tax);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}