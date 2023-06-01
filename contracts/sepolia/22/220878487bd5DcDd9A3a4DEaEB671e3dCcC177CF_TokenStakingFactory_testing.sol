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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface Factory{
    function addContractStaker(address _staker, address _contractAddress) external;
}

contract TokenStaking_testing {
    struct User {
        uint256[10] amountStaked; // Array to store the amount staked by the user in each pool
        uint256[10] stakingPool; // Array to store the pool number in which the user has staked
        uint256[10] rewardPoints; // Array to store the accumulated reward points of the user in each pool
        uint256[10] unclaimedReward; // Array to store the unclaimed reward of the user in each pool
        uint256[10] lastClaimedTimestamp; // Array to store the timestamp of the last reward claim of the user in each pool
        uint256[10] lastDepositTimestamp; // Array to store the timestamp of the last deposit made by the user in each pool
    }
    mapping(address => User) private users;

    struct StakingPool {
        uint256 apr; // Annual percentage rate of the pool
        uint256 stakeTime; // Duration of the stake in seconds
        uint256 penaltyPercentage; // Penalty percentage applied if unstaked before lock time
        uint256 claimTime; // Time interval between reward claims in seconds
        uint256 stakeMin; // Minimum amount that can be staked in the pool
        uint256 stakeMax; // Maximum amount that can be staked in the pool
        uint256 stakeLimit; // Maximum total amount that can be staked in the pool
        uint256 stakedNow; // Total amount currently staked in the pool
        uint256 totalStaked; // Total amount staked in the pool since its creation
        uint256 totalRewardClaimed; // Total reward claimed from the pool
        uint256 rewardPool; // Total reward pool of the pool
        uint256 undistributedReward; // Undistributed reward remaining in the pool
    }
        //Staking Pool
        StakingPool[5] public stakingPools; // Array to store the staking pools
        uint256 public registerTime; // Start time of the staking registration period
        uint256 public endRegisterTime; // End time of the staking registration period
        uint256 public immutable deployTime; // Deployment time of the contract
        uint256 public totalReward; // Total reward across all staking pools
        address public immutable factoryAddress; // Address of the factory contract
        address public immutable stakeToken; // Address of the staking token

        //addressing contributor
        mapping(address => bool) private contributors;
        uint256 public contributorCount;

    modifier onlyFactory() {
        require(factoryAddress == msg.sender, "only factory can Interact");
        _;
    }

    constructor(
        address _stakeToken,
        uint256 _registerTime,
        uint256 _endRegisterTime,
        uint256[] memory _apr,
        uint256[] memory _stakeTime,
        uint256[] memory _penaltyPercentage,
        uint256[] memory _claimTime,
        uint256[] memory _stakeMin,
        uint256[] memory _stakeMax,
        uint256[] memory _stakeLimit
    ) {
    // Check that all arrays have the same length
        require(
            _apr.length == _stakeTime.length &&
            _stakeTime.length == _penaltyPercentage.length &&
            _penaltyPercentage.length == _claimTime.length &&
            _claimTime.length == _stakeMin.length &&
            _stakeMin.length == _stakeMax.length &&
            _stakeMax.length == _stakeLimit.length,
            "require same length of array"
        );

        // Check the number of staking pools does not exceed the maximum limit
        require(_apr.length <= 5, "Maximum 5 staking pools allowed");

        // Check that the registration time and end registration time fall within a valid range
        require(
            block.timestamp + 60 <= _registerTime && _registerTime <= block.timestamp + 30 * 60,
            "register time and end time must be in the range of 1 and 30 days from now!"
        );

        // Check that the end registration time falls within a valid range based on the registration time
        require(
            _registerTime + 60 * 2 <= _endRegisterTime && _endRegisterTime <= _registerTime + 10 * 60,
            "end Register time must be in the range of 2 and 10 days from the register Time!"
            );

        stakeToken = _stakeToken;
        factoryAddress = msg.sender;
        deployTime = block.timestamp;
        registerTime = _registerTime;
        endRegisterTime = _endRegisterTime;

        // Iterate over the arrays to create staking pools
        for (uint256 i = 0; i < _apr.length; i++) {
            // Calculate the initial reward pool based on APR, stake limit, stake time, and scaling factors
            uint256 _rewardPool = _apr[i] * _stakeLimit[i] * _stakeTime[i] / (365*60*10000);

            // Create a new StakingPool struct with the provided parameters
            StakingPool memory pool = StakingPool({
                apr: _apr[i],
                stakeTime: _stakeTime[i],
                penaltyPercentage: _penaltyPercentage[i],
                claimTime: _claimTime[i],
                stakeMin: _stakeMin[i],
                stakeMax: _stakeMax[i],
                stakeLimit: _stakeLimit[i],
                stakedNow: 0,
                totalStaked: 0,
                totalRewardClaimed: 0,
                rewardPool: _rewardPool,
                undistributedReward: _rewardPool
            });

            // Add the new pool to the stakingPools array
            stakingPools[i] = pool;

            // Increase the total reward by the reward pool of the current pool
            totalReward += stakingPools[i].rewardPool;
        }
    }

    function changeStakeInfo(
        uint256 _registerTime,
        uint256 _endRegisterTime,
        uint256[] memory _apr,
        uint256[] memory _stakeTime,
        uint256[] memory _penaltyPercentage,
        uint256[] memory _claimTime,
        uint256[] memory _stakeMin,
        uint256[] memory _stakeMax,
        uint256[] memory _stakeLimit
    ) external onlyFactory {
        // Check that all arrays have the same length
        require(
            _apr.length == _stakeTime.length &&
            _stakeTime.length == _penaltyPercentage.length &&
            _penaltyPercentage.length == _claimTime.length &&
            _claimTime.length == _stakeMin.length &&
            _stakeMin.length == _stakeMax.length &&
            _stakeMax.length == _stakeLimit.length,
            "Require same length of array"
        );

        // Check the number of staking pools does not exceed the maximum limit
        require(_apr.length <= 5, "Maximum 10 staking pools allowed");

        // Check that the registration time and end registration time fall within valid ranges
        require(
            block.timestamp + 60 <= _registerTime && _registerTime <= deployTime + 30 * 60,
            "register time must be in the range of 1 and 30 days from now!"
        );
        require(
            _registerTime + 60 * 2 <= _endRegisterTime && _endRegisterTime <= _registerTime + 10 * 60,
            "end Register time must be in the range of 2 and 10 days from the register Time!"
        );

        // Update registration and end registration times
        registerTime = _registerTime;
        endRegisterTime = _endRegisterTime;

        // Clear existing staking pools
        uint256 length = stakingPools.length;
        for (uint256 i = 0; i < length; i++) {
            delete stakingPools[i];
        }

        // Reset totalReward to zero and store the previous totalReward
        uint256 prevTotalReward = totalReward;
        totalReward = 0;

        // Create new staking pools
        for (uint256 i = 0; i < _apr.length; i++) {
            // Calculate the reward pool for the new staking pool based on the provided parameters
            uint256 _rewardPool = _apr[i] * _stakeLimit[i] * _stakeTime[i] / (365*60*10000);

            // Create a new StakingPool struct with the provided parameters
            StakingPool memory pool = StakingPool({
                apr: _apr[i],
                stakeTime: _stakeTime[i],
                penaltyPercentage: _penaltyPercentage[i],
                claimTime: _claimTime[i],
                stakeMin: _stakeMin[i],
                stakeMax: _stakeMax[i],
                stakeLimit: _stakeLimit[i],
                stakedNow: 0,
                totalStaked: 0,
                totalRewardClaimed: 0,
                rewardPool: _rewardPool,
                undistributedReward: _rewardPool
            });

            // Add the new pool to the stakingPools array
            stakingPools[i] = pool;

            // Increase the total reward by the reward pool of the current pool
            totalReward += pool.rewardPool;
        }

        // If the previous totalReward is greater than the current totalReward, approve the difference amount
        if (prevTotalReward > totalReward) {
            require(IERC20(stakeToken).approve(factoryAddress, prevTotalReward - totalReward));
        }
    }

    function checkReward(uint256 _poolNumber, address _user) public view returns (uint256) {
        // Retrieve the User struct associated with the given user address
        User storage user = users[_user];

        // Calculate the time elapsed since the last claimed timestamp for the specified pool
        uint256 timeElapsed = (block.timestamp - user.lastClaimedTimestamp[_poolNumber]);

        // Retrieve the reward rate (APR) for the specified pool
        uint256 rewardRate = stakingPools[user.stakingPool[_poolNumber]].apr;

        // Calculate the reward based on the staked amount, reward rate, time elapsed, and a conversion factor
        uint256 reward = user.amountStaked[_poolNumber] * rewardRate * timeElapsed * (365*60*10000);

        // Add any unclaimed reward to the calculated reward
        reward += user.unclaimedReward[_poolNumber];

        // If the calculated reward exceeds the user's reward points, limit it to the reward points
        if (reward >= user.rewardPoints[_poolNumber]) {
            reward = user.rewardPoints[_poolNumber];
        }
        return reward;
    }

    function calculateRewardPoints(uint256 _poolNumber, bool _unstake, address _user) public view returns (uint256) {
        // Retrieve the User struct associated with the given user address
        User storage user = users[_user];

        // Calculate the time elapsed since the last claimed timestamp for the specified pool
        uint256 timeElapsed = (block.timestamp - user.lastClaimedTimestamp[_poolNumber]);

        // Retrieve the reward rate (APR) for the specified pool
        uint256 rewardRate = stakingPools[user.stakingPool[_poolNumber]].apr;

        // Calculate the reward based on the staked amount, reward rate, time elapsed, and a conversion factor
        uint256 reward = user.amountStaked[_poolNumber] * rewardRate * timeElapsed / (365*60*10000);

        // Add any unclaimed reward to the calculated reward
        reward += user.unclaimedReward[_poolNumber];

        // If it's not an unstake calculation, calculate additional rewards based on the claim time and adjust the reward
        if (!_unstake) {
            uint256 timeReward = user.amountStaked[_poolNumber] * rewardRate * stakingPools[user.stakingPool[_poolNumber]].claimTime / (365*60*10000);
            uint256 rewardCount = reward / timeReward;
            reward = timeReward * rewardCount;
        }

        // If the calculated reward exceeds the user's reward points, limit it to the reward points
        if (reward >= user.rewardPoints[_poolNumber]) {
            reward = user.rewardPoints[_poolNumber];
        }
    return reward;
    }


    function stake(uint256 _amount, uint256 _stakingPool) external {
        // Check if the registration period is active
        require(block.timestamp <= endRegisterTime && registerTime <= block.timestamp, "Registration not started or already ended!");

        //everyone that already staked once, will be counted as Contributor
        if (!contributors[msg.sender]) {
            contributors[msg.sender] = true;
            contributorCount++;
            Factory(factoryAddress).addContractStaker(msg.sender, address(this));
        }

        // Retrieve the User struct associated with the sender's address
        User storage user = users[msg.sender];

        uint256 _poolNumber;
        // Find an available pool slot for the user
        for (uint256 i = 0; i < 10; i++) {
            if (user.amountStaked[i] == 0) {
                _poolNumber = i;
                break;
            }
        }

        // Check if the specified staking pool is initialized
        require(_stakingPool < stakingPools.length, "Pool not initialized");

        // Check if the staked amount is within the allowed range
        require(_amount >= stakingPools[_stakingPool].stakeMin, "Amount must be greater than the minimum staking amount");
        require(_amount <= stakingPools[_stakingPool].stakeMax, "Amount must be lower than the maximum staking amount");

        // Update total staked amount and staked amount for the specified pool
        require(stakingPools[_stakingPool].totalStaked + _amount <= stakingPools[_stakingPool].stakeLimit, "Exceeded staking limit, please lower your staking amount");
        stakingPools[_stakingPool].totalStaked += _amount;
        stakingPools[_stakingPool].stakedNow += _amount;

        // Transfer tokens from the user to the contract
        require(IERC20(stakeToken).transferFrom(msg.sender, address(this), _amount), "Token transfer failed");

        // Add the staked amount to the user's balance and update timestamps
        user.stakingPool[_poolNumber] = _stakingPool;
        user.amountStaked[_poolNumber] += _amount;
        user.lastDepositTimestamp[_poolNumber] = block.timestamp;
        user.lastClaimedTimestamp[_poolNumber] = block.timestamp;

        // Calculate reward points based on the staked amount, APR, and stake time
        uint256 rewardPoints = (_amount * stakingPools[_stakingPool].apr * stakingPools[_stakingPool].stakeTime) / (365*60*10000);
        user.rewardPoints[_poolNumber] += rewardPoints;
        user.unclaimedReward[_poolNumber] = 0;
        stakingPools[_stakingPool].undistributedReward -= rewardPoints;
    }

    function unstake(uint256 _poolNumber) external {
        // Retrieve the User struct associated with the sender's address
        User storage user = users[msg.sender];
        uint256 _stakingPool = user.stakingPool[_poolNumber];

        // Check if the user has a staked balance
        require(user.amountStaked[_poolNumber] > 0, "No staked balance");

        // Calculate penalty if unstaked before the lock time
        uint256 penalty = 0;
        if (block.timestamp <= user.lastDepositTimestamp[_poolNumber] + stakingPools[_stakingPool].stakeTime) {
            penalty = (user.amountStaked[_poolNumber] * stakingPools[_stakingPool].penaltyPercentage) / 10000;
        }

        // Calculate reward points and update total reward points for the staking pool
        uint256 rewardPoints = calculateRewardPoints(_poolNumber, true, msg.sender);
        stakingPools[_stakingPool].totalRewardClaimed += rewardPoints;
        stakingPools[_stakingPool].undistributedReward += user.rewardPoints[_poolNumber] - rewardPoints;
        user.rewardPoints[_poolNumber] = 0;

        // Calculate the amount to unstake (minus penalty) and transfer it to the user
        uint256 amountToUnstake = user.amountStaked[_poolNumber] - penalty;
        stakingPools[_stakingPool].stakedNow -= user.amountStaked[_poolNumber];
        user.amountStaked[_poolNumber] = 0;

        uint256 amountClaim = amountToUnstake + rewardPoints;
        require(IERC20(stakeToken).transfer(msg.sender, amountClaim), "Token transfer failed");

        // Transfer penalty tokens to the contract owner
        if (penalty > 0) {
            require(IERC20(stakeToken).transfer(address(this), penalty), "Token transfer failed");
            stakingPools[_stakingPool].undistributedReward += penalty;
        }

        // Update the user's staking pool and timestamps
        user.stakingPool[_poolNumber] = 0;
        user.lastClaimedTimestamp[_poolNumber] = 0;
        user.lastDepositTimestamp[_poolNumber] = 0;
    }


    function claimReward(uint256 _poolNumber) external {
        // Retrieve the User struct associated with the sender's address
        User storage user = users[msg.sender];
        uint256 _stakingPool = user.stakingPool[_poolNumber];

        // Check if the user has a staked balance and available reward points
        require(user.amountStaked[_poolNumber] > 0, "No staked balance");
        require(user.rewardPoints[_poolNumber] > 0, "No available rewards, please unstake your tokens");

        // Calculate the available reward and limited reward based on the staking pool and user's reward points
        uint256 totalRewardAvailable = checkReward(_poolNumber, msg.sender);
        uint256 rewardLimited = calculateRewardPoints(_poolNumber, false, msg.sender);
        uint256 rewardRate = stakingPools[user.stakingPool[_poolNumber]].apr;
        uint256 periodReward = (user.amountStaked[_poolNumber] * rewardRate * stakingPools[user.stakingPool[_poolNumber]].claimTime) / (365*60*10000);
        uint256 allocatedReward;

        // Check if it's within the claim hour or after the claim period
        if ((block.timestamp - user.lastDepositTimestamp[_poolNumber]) <= (stakingPools[user.stakingPool[_poolNumber]].stakeTime - stakingPools[user.stakingPool[_poolNumber]].claimTime)) {
            require(rewardLimited >= periodReward, "Please wait until the claim hour");
            allocatedReward = rewardLimited;
        } else {
            allocatedReward = totalRewardAvailable;
            if (rewardLimited >= periodReward) {
                allocatedReward = rewardLimited;
            } else {
                require(allocatedReward == user.rewardPoints[_poolNumber], "Please wait until the time ends to claim your last staked reward");
            }
        }

        // Update total reward claimed, user's reward points, and unclaimed rewards
        stakingPools[_stakingPool].totalRewardClaimed += allocatedReward;
        user.rewardPoints[_poolNumber] -= allocatedReward;
        user.unclaimedReward[_poolNumber] = totalRewardAvailable - allocatedReward;

        // Transfer the allocated reward tokens to the user
        require(IERC20(stakeToken).transfer(msg.sender, allocatedReward), "Token transfer failed");

        // Update the last claimed timestamp
        user.lastClaimedTimestamp[_poolNumber] = block.timestamp;
    }

    function withdrawUndistributedReward() external onlyFactory() returns (uint256) {
        uint256 undistributedReward = returnTotalUndistributedReward();

        // Approve the transfer of undistributed reward tokens to the factory address
        require(IERC20(stakeToken).approve(factoryAddress, undistributedReward));

    return undistributedReward;
    }
    
    function highestAPR() public view returns (uint256) {
        uint256 highestApr = 0;

        // Iterate over the stakingPools array to compare APR values
        for (uint256 i = 0; i < stakingPools.length; i++) {
            if (stakingPools[i].apr > highestApr) {
                highestApr = stakingPools[i].apr;
            }
        }
    return highestApr;
    }

    function highestStake() public view returns (uint256) {
        uint256 highestStaked = 0;

        // Iterate over the stakingPools array to compare APR values
        for (uint256 i = 0; i < stakingPools.length; i++) {
            if (stakingPools[i].stakeMax > highestStaked) {
                highestStaked = stakingPools[i].stakeMax;
            }
        }
    return highestStaked;
    }

    function lowestStake() public view returns (uint256) {
        uint256 lowestStaked = stakingPools[0].stakeMin;

        // Iterate over the stakingPools array to compare APR values
        for (uint256 i = 1; i < stakingPools.length; i++) {
            if (stakingPools[i].stakeMin < lowestStaked && stakingPools[i].stakeMin != 0) {
                lowestStaked = stakingPools[i].stakeMin;
            }
        }
    return lowestStaked;
    }

    function returnTotalTokenLocked() public view returns (uint256) {
        uint256 tokenLocked = 0;

        // Iterate over the stakingPools array to sum up the stakedNow values
        for (uint256 i = 0; i < stakingPools.length; i++) {
            tokenLocked += stakingPools[i].stakedNow;
        }
    return tokenLocked;
    }

    function returnTotalUndistributedReward() public view returns (uint256) {
        uint256 undistributedReward = 0;

        // Iterate over the stakingPools array to sum up the stakedNow values
        for (uint256 i = 0; i < stakingPools.length; i++) {
            undistributedReward += stakingPools[i].undistributedReward;
        }
    return undistributedReward;
    }

    function stakeInfo(address _user) public view returns (User memory) {
        // Retrieve the User struct associated with the given user address from the users mapping
        User storage user = users[_user];
    return user;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./TokenStaking_testing.sol";

contract TokenStakingFactory_testing is Ownable {
    // Array to store the addresses of deployed staking contracts
    address[] public deployedContracts;

    // Mapping to track staking contracts owned by each address
    mapping(address => address[]) public ownerToContracts;

    // Mapping to track Staker into the contract they staked
    mapping(address => address[]) public stakerToContracts;

    // Mapping to store the owner of a staking contract
    mapping(address => address) public contractOwner;

    // Mapping to store the owner of a staking contract
    mapping(address => bool) public undistributedClaimed;

    // Mapping to store the end time of staking for each contract
    mapping(address => uint256) public endTimeStake;

    event ContractDeployed(address indexed contractAddress);

    /**
     * @dev Creates a new staking contract with the provided parameters.
     * @param _stakeToken Address of the token to be staked
     * @param _apr Array of annual percentage rates (APRs) for each staking pool
     * @param _stakeTime Array of stake durations for each staking pool
     * @param _registerTime Start time of the registration period
     * @param _endRegisterTime End time of the registration period
     * @param _penaltyPercentage Array of penalty percentages for early unstaking
     * @param _claimTime Array of claim waiting times for each staking pool
     * @param _stakeMin Array of minimum staking amounts for each staking pool
     * @param _stakeMax Array of maximum staking amounts for each staking pool
     * @param _stakeLimit Array of stake limits for each staking pool
     */
    function createTokenStaking(
        address _stakeToken,
        uint256[] memory _apr,
        uint256[] memory _stakeTime,
        uint256 _registerTime,
        uint256 _endRegisterTime,
        uint256[] memory _penaltyPercentage,
        uint256[] memory _claimTime,
        uint256[] memory _stakeMin,
        uint256[] memory _stakeMax,
        uint256[] memory _stakeLimit
    ) external {
        // Calculate the total reward pool and the end time of staking
        uint256 totalRewardPool = 0;
        uint256 endTime = 0;
        for (uint256 i = 0; i < _apr.length; i++) {
            uint256 rewardPoolNumber = _apr[i] * _stakeLimit[i] * _stakeTime[i] / (365*60*10000);
            totalRewardPool += rewardPoolNumber;
            if (endTime < _registerTime + _stakeTime[i]) {
                endTime = _registerTime + _stakeTime[i];
            }
        }

        // Transfer the required amount of stake tokens from the caller to the factory contract
        require(IERC20(_stakeToken).transferFrom(msg.sender, address(this), totalRewardPool));

        // Deploy a new instance of the TokenStaking contract
        TokenStaking_testing tokenStaking = new TokenStaking_testing(
            _stakeToken,
            _registerTime,
            _endRegisterTime,
            _apr,
            _stakeTime,
            _penaltyPercentage,
            _claimTime,
            _stakeMin,
            _stakeMax,
            _stakeLimit
        );

        // Transfer the reward pool to the staking contract
        require(IERC20(_stakeToken).transfer(address(tokenStaking), totalRewardPool));

        // Map the stake end time
        endTimeStake[address(tokenStaking)] = endTime;

        // Update mappings and emit an event to notify about the contract deployment
        deployedContracts.push(address(tokenStaking));
        ownerToContracts[msg.sender].push(address(tokenStaking));
        contractOwner[address(tokenStaking)] = msg.sender;

        emit ContractDeployed(address(tokenStaking));
    }

    event UpdatePoolInfo(address indexed contractAddress);

    /**
     * @dev Updates the pool information of a staking contract.
     * @param _contractAddress Address of the staking contract to be updated
     * @param _apr Array of updated annual percentage rates (APRs)
     * @param _stakeTime Array of updated stake durations
     * @param _registerTime Updated start time of the registration period
     * @param _endRegisterTime Updated end time of the registration period
     * @param _penaltyPercentage Array of updated penalty percentages
     * @param _claimTime Array of updated claim waiting times
     * @param _stakeMin Array of updated minimum staking amounts
     * @param _stakeMax Array of updated maximum staking amounts
     * @param _stakeLimit Array of updated stake limits
     */
    function updatePoolInfo(
        address _contractAddress,
        uint256[] memory _apr,
        uint256[] memory _stakeTime,
        uint256 _registerTime,
        uint256 _endRegisterTime,
        uint256[] memory _penaltyPercentage,
        uint256[] memory _claimTime,
        uint256[] memory _stakeMin,
        uint256[] memory _stakeMax,
        uint256[] memory _stakeLimit
    ) external {
        // Ensure that only the owner can interact with the contract
        require(contractOwner[_contractAddress] == msg.sender, "Only the owner can interact with the contract!");

        // Calculate the updated total reward pool and the updated end time of staking
        uint256 totalRewardPool = 0;
        uint256 endTime = 0;
        for (uint256 i = 0; i < _apr.length; i++) {
            uint256 rewardPoolNumber = _apr[i] * _stakeLimit[i] * _stakeTime[i] / (365*60*10000);
            totalRewardPool += rewardPoolNumber;
            if (endTime < _registerTime + _stakeTime[i]) {
                endTime = _registerTime + _stakeTime[i];
            }
        }

        // Get the last reward pool of the staking contract
        uint256 lastReward = TokenStaking_testing(_contractAddress).totalReward();

        // Update the staking contract with the new pool information
        TokenStaking_testing(_contractAddress).changeStakeInfo(
            _registerTime,
            _endRegisterTime,
            _apr,
            _stakeTime,
            _penaltyPercentage,
            _claimTime,
            _stakeMin,
            _stakeMax,
            _stakeLimit
        );

        // Transfer additional reward tokens (or retrieve excess tokens) between the owner and the staking contract
        if (totalRewardPool > lastReward) {
            require(IERC20(TokenStaking_testing(_contractAddress).stakeToken()).transferFrom(msg.sender, _contractAddress, totalRewardPool - lastReward), "Insufficient balance to send to contract!");
        } else {
            require(IERC20(TokenStaking_testing(_contractAddress).stakeToken()).transferFrom(_contractAddress, msg.sender, lastReward - totalRewardPool), "Insufficient balance to send to contract!");
        }

        // Update the stake end time
        endTimeStake[_contractAddress] = endTime;

        emit UpdatePoolInfo(_contractAddress);
    }

    /**
    * @dev Retrieves information about a pool based on the provided timestamp and contract address.
    * @param _unixTimestamp The timestamp to check the pool status.
    * @param _contractAddress The address of the contract representing the pool.
    * @return poolStatusNow The current status of the pool:
    *         - 1: Upcoming
    *         - 2: Active
    *         - 3: Ended
    * @return registerTime The registration time of the pool.
    * @return endRegisterTime The end registration time of the pool.
    * @return endPoolTime The end time of the pool.
    * @return deployTime The deployment time of the pool contract.
    * @return totalReward The total reward of the pool.
    * @return contributorCount The amount of contributors in the pool.
    * @return highestAPR The highest APR from all pools.
    * @return highestStake The highest stake amount in the pool.
    * @return lowestStake The lowest stake amount in the pool.
    * @return lockedToken The total token locked in all pools.
    * @return undistributedReward The total undistributed reward remaining in the pool.
    * @return stakeToken The token used for staking in the pool.
    */
    function getPoolInfo(uint256 _unixTimestamp, address _contractAddress) external view returns (
        uint24 poolStatusNow,
        uint256 registerTime,
        uint256 endRegisterTime,
        uint256 endPoolTime,
        uint256 deployTime,
        uint256 totalReward,
        uint256 contributorCount,
        uint256 highestAPR,
        uint256 highestStake,
        uint256 lowestStake,
        uint256 lockedToken,
        uint256 undistributedReward,
        address stakeToken
    ) {
        registerTime = TokenStaking_testing(_contractAddress).registerTime();
        endRegisterTime = TokenStaking_testing(_contractAddress).endRegisterTime();
        endPoolTime = endTimeStake[_contractAddress];
        deployTime = TokenStaking_testing(_contractAddress).deployTime();
        totalReward = TokenStaking_testing(_contractAddress).totalReward();
        stakeToken = TokenStaking_testing(_contractAddress).stakeToken();
        highestAPR = TokenStaking_testing(_contractAddress).highestAPR();
        highestStake = TokenStaking_testing(_contractAddress).highestStake();
        lowestStake = TokenStaking_testing(_contractAddress).lowestStake();
        contributorCount = TokenStaking_testing(_contractAddress).contributorCount();
        lockedToken = TokenStaking_testing(_contractAddress).returnTotalTokenLocked();
        undistributedReward = TokenStaking_testing(_contractAddress).returnTotalUndistributedReward();
    
        // Determine the current pool status
        if (_unixTimestamp <= registerTime) {
            poolStatusNow = 1;  // Upcoming
        } else if (registerTime <= _unixTimestamp && endPoolTime >= _unixTimestamp) {
            poolStatusNow = 2;  // Active
        } else if (_unixTimestamp >= endPoolTime) {
            poolStatusNow = 3;  // Ended
        }
    }

    /**
     * @dev Withdraws the undistributed reward from a staking contract after the staking period has ended.
     * @param _contractAddress Address of the staking contract
     */
    function withdrawUndistributedRewardFromContract(address _contractAddress) external {
        require(undistributedClaimed[_contractAddress] == false);
        // Ensure that only the owner can interact with the contract
        require(contractOwner[_contractAddress] == msg.sender, "Only the owner can interact with the contract!");

        // Check if the staking period has ended
        require(block.timestamp >= endTimeStake[_contractAddress], "Wait until the staking period has ended!");

        // Withdraw the undistributed reward from the staking contract
        undistributedClaimed[_contractAddress]= true;
        uint256 undistributedReward = TokenStaking_testing(_contractAddress).withdrawUndistributedReward();
        require(IERC20(TokenStaking_testing(_contractAddress).stakeToken()).transferFrom(_contractAddress, msg.sender, undistributedReward), "Insufficient balance to send to contract!");
    }

    /**
     * @dev Returns the array of addresses for all deployed staking contracts.
     * @return Array of addresses for all deployed staking contracts
     */
    function getDeployedContracts() external view returns (address[] memory) {
        return deployedContracts;
    }

    /**
    * @dev Retrieves an array of staking contracts owned by the specified address.
    * @param owner The address of the owner whose contracts are to be retrieved.
    * @return contracts An array of staking contracts owned by the specified address.
    */
    function getContractsByOwner(address owner) public view returns (address[] memory) {
        return ownerToContracts[owner];
    }

    /**
    * @dev Retrieves an array of staking contracts owned by the specified address.
    * @param _staker The address of the _staker whose contracts are to be retrieved.
    * @return contracts An array of staking contracts owned by the specified address.
    */
    function getContractByStaker(address _staker) public view returns (address[] memory) {
        return stakerToContracts[_staker];
    }

    /**
    * @dev Adds a staking contract to the list of contracts associated with a staker address.
    * @param _staker The staker address.
    * @param _contractAddress The address of the staking contract to be added.
    */
    function addContractStaker(address _staker, address _contractAddress) external {
        stakerToContracts[_staker].push(_contractAddress);
    }
}