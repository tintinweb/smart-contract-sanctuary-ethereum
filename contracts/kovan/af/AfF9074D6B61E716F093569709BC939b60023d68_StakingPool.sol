/**
 *Submitted for verification at Etherscan.io on 2022-04-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;



// Part: OpenZeppelin/[email protected]/IERC20

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

// File: StakingPool.sol

/// @notice StakingPool contract for zooDAO.
contract StakingPool
{
	/// @notice struct with epoch info.
	struct Epoch
	{
		uint256 start;
		uint256 tvl;
	}

	/// @notice struct with position info.
	struct Position
	{
		uint256 startEpochId;
		// uint256 endEpochId;
		uint256 value;
		uint256 accumulatedReward;
	}

	IERC20 public stakedToken;                         // Token for staking.
	IERC20 public rewardToken;                         // Stakers rewarded in this token.
	uint256 public totalRewardPerSecond;               // Total reward per time unit.
	Epoch[] public epochs;                             // Array of epochs.

	// position id => Position struct
	mapping (address => Position) public positions;    // Records id of positions.

	event Staked(address indexed staker, uint256 amount);

	event Unstaked(address indexed staker, uint256 amount);

	event Harvest(address indexed recipient, uint256 amount);

	event Withdraw(address indexed staker, uint256 amount);


	/// @notice contract constructor.
	/// @param _stakedToken - token address.
	/// @param _rewardToken - reward token address.
	/// @param _rewardPerSecond - base amount of reward per second.
	constructor(address _stakedToken, address _rewardToken, uint256 _rewardPerSecond)
	{
		rewardToken = IERC20(_rewardToken);
		stakedToken = IERC20(_stakedToken);

		totalRewardPerSecond = _rewardPerSecond;

		epochs.push(Epoch(block.timestamp, 0));
	}

	/// @notice Function to stake tokens. /// todo:should be internal
	/// @param value - amount of tokens to stake.
	function stake(uint256 value) public
	{
		stakedToken.transferFrom(msg.sender, address(this), value);             // transfers tokens from sender to this contract.

		uint256 len = epochs.length;                                            // Gets amount of epochs from array.
		uint256 newTvl = epochs[len - 1].tvl + value;                           // Calculates newTvl from last epoch tvl and added value.

		epochs.push(Epoch(block.timestamp, newTvl));                            // Pushes date and value to array.

		positions[msg.sender].startEpochId = len;                           // Records start epoch for position.
		positions[msg.sender].value = value;                                // Records new value for position.

		emit Staked(msg.sender, value);
	}

	/// @notice Functions to unstake tokens. todo:should be internal
	function unstake() public
	{
		uint256 value = positions[msg.sender].value;                            // Get value from position.
		uint256 tvl = epochs[epochs.length - 1].tvl;                            // Get tvl from position.

		stakedToken.transfer(msg.sender, value);                                // Transfers staked tokens to msg.sender.
		epochs.push(Epoch(block.timestamp, tvl - value));                       // Pushes date and tvl to array.

		uint256 reward = computeReward(msg.sender, epochs.length - 1);          // Computes reward for this position.
		rewardToken.transfer(msg.sender, reward);                               // Transfers reward tokens to msg.sender.

		positions[msg.sender].startEpochId = epochs.length - 1;                 // Records start epoch for position.
		positions[msg.sender].value = 0;                                        // Records new value for position.

		emit Unstaked(msg.sender, value);
	}

	/// @notice Function to claim reward from staking.
	/// @param who -- address of recipient.
	function harvest(address who) public
	{
		uint256 reward = computeReward(msg.sender, epochs.length - 1) + positions[msg.sender].accumulatedReward;          // Computes reward.

		rewardToken.transfer(who, reward);                                      // Transfers reward to recipient.

		positions[msg.sender].startEpochId = epochs.length - 1;                 // Sets new startEpochId.
		positions[msg.sender].accumulatedReward = 0;

		emit Harvest(msg.sender, reward);
	}

	/// @notice Function to compute reward.	/// todo: should be internal
	/// @param who - address staker.
	/// @param endEpochId - last epoch id of staking.
	/// @return - amount of reward.
	function computeReward(address who, uint256 endEpochId) public view returns (uint256)
	{
		uint256 reward;
		uint256 value = positions[who].value;                                   // Gets value from position.
		for (uint256 i = positions[who].startEpochId; i < endEpochId; i++)
		{
			uint256 time = epochs[i + 1].start - epochs[i].start;               // Calculates duration of staking.
			reward += time * totalRewardPerSecond * value / epochs[i].tvl;      // Calculates amount of reward per time unit.
		}

		return reward;                                                          // Gets reward amount.
	}

	/// @notice Function to deposit more tokens in staking pool.
	/// @param value - amount of tokens to add.
	function addLpToPosition(uint256 value) public
	{
		stakedToken.transferFrom(msg.sender, address(this), value);             // Transfers tokens to this contract from msg.sender.

		uint256 len = epochs.length;                                            // Gets amount of epochs.
		uint256 newTvl = epochs[len - 1].tvl + value;                           // Gets new tvl.
		epochs.push(Epoch(block.timestamp, newTvl + value));                    // Pushes new date and new tvl to array.

		positions[msg.sender].accumulatedReward += computeReward(msg.sender, len);
		positions[msg.sender].startEpochId = len;
		positions[msg.sender].value += value;                                   // Adds value to position.

		emit Staked(msg.sender, value);
	}

	/// @notice Function to withdraw tokens from pool.
	/// @param value - amount of tokens to withdraw.
	function withdraw(uint256 value) public
	{
		uint256 balance = positions[msg.sender].value;                          // Gets value amount from position of msg.sender.
		require(balance >= value, "withdraw exceeds limit");                     // Requires for withdraw amount to be less than staked amount.

		stakedToken.transfer(msg.sender, value);                                // Transfers staked tokens to msg.sender.

		uint256 len = epochs.length;                                            // Gets amount of epochs.
		uint256 newTvl = epochs[len - 1].tvl - value;                           // Gets new tvl.
		epochs.push(Epoch(block.timestamp, newTvl));                            // Pushes new date and new tvl to epochs array.

		uint reward = computeReward(msg.sender, len);
		
		positions[msg.sender].accumulatedReward += reward;
		positions[msg.sender].startEpochId = len;
		positions[msg.sender].value -= value;                                   // Withdraws value from position.

		emit Withdraw(msg.sender, value);
	}

	/// @notice Function to view lenght of epochs array.
	/// @return epochs array length.
	function numberOfEpochs() public view returns (uint256)
	{
		return epochs.length;
	}

	/// @notice Function to view current reward amount.
	/// @param user - user's address
	/// @param timestamp - date of reward.
	/// @return reward - amount of reward.
	function viewReward(address user, uint256 timestamp) external view returns (uint256)
	{
		uint256 endEpochId = epochs.length - 1;                                   // Gets id of last epoch.
		uint256 reward = computeReward(user, endEpochId);                         // Computes reward for this position and epoch.
		uint256 value = positions[user].value;                                    // Gets amount of tokens staked.
		uint256 time = timestamp - epochs[endEpochId].start;                      // Gets amount of time staked.
		reward += time * totalRewardPerSecond * value / epochs[endEpochId].tvl;   // Computes actual reward for staker.

		return reward + positions[user].accumulatedReward;
	}

	/// @notice Function to deposit in staking pool
	/// @param value - amount of deposit.
	function deposit(uint256 value) external
	{
		if (positions[msg.sender].value == 0)                                     // For the first time,
		{
			stake(value);                                                         // Staking for amount
		}
		else                                                                      // If staked before,
		{
			addLpToPosition(value);                                               // Adds amount.
		}
	}

	/// @notice Function to withdraw tokens from pool and harvest reward.
	/// @param value - amount to withdraw.
	function withdrawAndHarvest(uint256 value) external
	{
		withdraw(value);                                                          // Withdraws for amount.
		harvest(msg.sender);                                                      // harvest reward for msg.sender.
	}
}