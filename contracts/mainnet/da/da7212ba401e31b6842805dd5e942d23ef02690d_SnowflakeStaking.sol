/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * Multiple authorisation system.
 */
abstract contract Auth {

    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

/**
 * @dev Fractions can be used to represent fixed doubles to use as percentages
 * with more precision than an arbitrary length percentage, should you wish to.
 * Say, for a staking APR you initially wish 10%, then you would store on an uint8 a 10
 * and always divide by 100. This leaves you with only whole number percentages from 0 to 100.
 * You will always be limited by the digits initially available.
 * By picking a numerator and denominator, you can use whatever percentage floats your boat,
 * and using just about the right amount of storage space.
 */
struct Fraction {
	uint16 numerator;
	uint16 denominator;
}

contract SnowflakeStaking is Auth {

	/**
	 * @dev Pool specific configuration for the APR from the staked amount
	 * and how long to wait from initial staking until you can withdraw.
	 * It also holds who many tokens that specific pool has staked in.
	 * The APR is stored as a Fraction. You will multiply the original number
	 * by numerator and then divide by denominator.
	 * So storing a 1/10 APR means it's a total 10% of the stakes for the specified period.
	 * Availability specifies whether a new address can add a stake.
	 * Previously added stakes will always be available to be withdrawn.
	 */
    struct PoolConfiguration {
        uint256 poolStakedTokens;
		Fraction apr;
        uint32 withdrawLockPeriod;
		bool available;
    }

	/**
	 * @dev Represents a single address stake status within a specific pool.
	 * Includes the total staked tokens, how much reward an address is owed,
	 * when's the last time this stake status was updated, and when does the
	 * address become able to withdraw staked tokens.
	 */
	struct StakeState {
		uint256 stakedAmount;
		uint256 rewardDebt; 
		uint32 lastChangeTime;
		uint32 lockEndTime;
	}

	event TokenStaked(address indexed user, uint256 indexed poolId, uint256 amount);
	event TokenUnstaked(address indexed user, uint256 indexed poolId, uint256 amount);
	event RewardClaimed(address indexed user, uint256 indexed poolId, uint256 outAmount);
	event PoolAvailability(uint256 indexed poolId, bool available);
	event PoolConfigurated(uint256 indexed poolId, uint16 numerator, uint16 denominator, uint32 lockPeriod, bool available);

	// Informs about the address for the token being used for staking.
	address public stakingToken;

	// Quick view to the total amount of staked tokens in a specific pool.
	uint256 public totalStakedTokens;

	// List of configured pools.
	PoolConfiguration[3] private poolConfig;

	// Info of each user that stakes tokens.
	mapping (uint256 => mapping (address => StakeState)) public stakerDetails;

	constructor(address t) Auth(msg.sender) {
		stakingToken = t;
		// Bronze vault 30 days 15% APY
		generatePool(0, Fraction(15, 100), 30 days);
		// Gold vault 60 days  30% APY
		generatePool(1, Fraction(30, 100), 60 days);
		// Diamond vault 90 days 50% APY
		generatePool(2, Fraction(1, 2), 90 days);
	}

	modifier validFraction(Fraction memory fr) {
		require(fr.numerator > 0 && fr.denominator > 0, "Neither part of the fraction can be zero.");
		_;
	}

	function generatePool(uint256 poolId, Fraction memory apr, uint32 withdrawLockPeriod) private validFraction(apr) {
		PoolConfiguration memory pc;
		pc.apr = apr;
		pc.withdrawLockPeriod = withdrawLockPeriod;
		poolConfig[poolId] = pc;

		emit PoolConfigurated(poolId, apr.numerator, apr.denominator, withdrawLockPeriod, false);
	}

	function setPoolConfiguration(uint256 poolId, Fraction calldata apr, uint32 withdrawLockPeriod, bool active) external validFraction(apr) authorized {
		require(poolConfig[poolId].poolStakedTokens == 0, "A pool data cannot be changed while there are still tokens staked.");
		PoolConfiguration memory pool = poolConfig[poolId];
		pool.apr = apr;
		pool.withdrawLockPeriod = withdrawLockPeriod;
		pool.available = active;
		poolConfig[poolId] = pool;

		emit PoolConfigurated(poolId, apr.numerator, apr.denominator, withdrawLockPeriod, active);
	}

	function setPoolAvailable(uint256 poolId, bool active) external authorized {
		poolConfig[poolId].available = active;

		emit PoolAvailability(poolId, active);
	}

    function getNumOfPools() external view returns (uint256) {
        return poolConfig.length;
    }

    function updateStakingToken(address t) external authorized {
		require(totalStakedTokens == 0, "You cannot update the staking token while users are still staking.");
        stakingToken = t;
    }

	/**
	 * @dev Check the current unclaimed pending reward for a specific stake.
	 */
	function pendingReward(uint256 poolId, address account) public view returns (uint256) {
		StakeState storage user = stakerDetails[poolId][account];
		// Last change time of 0 means there's never been a stake to begin with.
		if (user.lastChangeTime == 0) {
			return 0;
		}
		// Ellapsed time since staking and now.
		// Rewards only accrue during lock time.
		uint256 endTime = (block.timestamp > user.lockEndTime) ? user.lockEndTime : block.timestamp;
		uint256 deltaTime = (endTime > user.lastChangeTime) ? endTime - user.lastChangeTime : 0;
		if (deltaTime == 0) {
			return 0;
		}
		PoolConfiguration storage pool = poolConfig[poolId];
		/**
		 * Get the accrued reward:
		 * An entire year is the 100% of the reward, thus it's quite simply to derived owed reward from elapsed time.
		 * Total APR reward plus time elapsed divided by a year.
		 */
		uint256 rewardVal = (deltaTime * (user.stakedAmount * pool.apr.numerator / pool.apr.denominator)) / 365 days;

		return rewardVal + user.rewardDebt;
	}

	function stake(uint256 poolId, uint256 amount) external {
		require(amount > 0, "Amount needs to be bigger than 0");
		PoolConfiguration storage pool = poolConfig[poolId];
		require(pool.available, "This pool is not accepting staking right now.");

		IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);
		StakeState storage user = stakerDetails[poolId][msg.sender];
		user.rewardDebt = pendingReward(poolId, msg.sender);
		user.stakedAmount += amount;
		uint32 rnow = uint32(block.timestamp);
		user.lastChangeTime = rnow;
		user.lockEndTime = rnow + pool.withdrawLockPeriod;
		pool.poolStakedTokens += amount;
		totalStakedTokens += amount;

		emit TokenStaked(msg.sender, poolId, amount);
	}

	function unstake(uint256 poolId) external {
		unstakeFor(poolId, msg.sender);
	}

	function unstakeFor(uint256 poolId, address staker) internal {
		StakeState storage user = stakerDetails[poolId][staker];
		uint256 amount = user.stakedAmount;
		require(amount > 0, "No stake on that pool.");
		require(IERC20(stakingToken).balanceOf(address(this)) >= amount, "Staking contract does not have enough tokens.");
		require(block.timestamp >= user.lockEndTime, "Your tokens are still locked.");

		// Update user staking status.
		// When unstaking is done, claim is automatically done.
		claimFor(poolId, staker);
		user.stakedAmount = 0;

		// Return token to staker and update pool and overall staking values.
		IERC20(stakingToken).transfer(staker, amount);
		PoolConfiguration storage pool = poolConfig[poolId];
		pool.poolStakedTokens -= amount;
		totalStakedTokens -= amount;

		emit TokenUnstaked(staker, poolId, amount);
	}

	function claim(uint256 poolId) external {
		require(block.timestamp > stakerDetails[poolId][msg.sender].lockEndTime, "User's lock time has not finished yet.");
		claimFor(poolId, msg.sender);
	}

	/**
	 * @dev Allows an authorised account to finalise a staking that has not claimed nor unstaked while the period is over.
	 */
	function forceClaimUnstake(uint256 poolId, address staker) external authorized {
		// The pool must not be available for staking, otherwise the user should be free to renew their stake.
		require(!poolConfig[poolId].available, "Pool is still available.");
		// The stake must have finished its lock time and accrued all the APR.
		require(block.timestamp > stakerDetails[poolId][staker].lockEndTime, "User's lock time has not finished yet.");
		// Run their claim and unstake.
		unstakeFor(poolId, staker);
	}

	function claimFor(uint256 poolId, address staker) internal {
		StakeState storage user = stakerDetails[poolId][staker];
		uint256 outAmount = pendingReward(poolId, staker);
		require(outAmount > 0, "Nothing to claim.");
		uint256 contractBalance = IERC20(stakingToken).balanceOf(address(this));
		require(contractBalance > outAmount && contractBalance - outAmount >= totalStakedTokens, "Staking contract does not own enough tokens.");

		IERC20(stakingToken).transfer(staker, outAmount);
		user.rewardDebt = 0;
		user.lastChangeTime = uint32(block.timestamp);

		emit RewardClaimed(staker, poolId, outAmount);
	}

	/**
	 * @dev Call for users to check if their account can already withdraw the staked tokens.
	 */
	function canWithdrawTokens(uint256 poolId, address user) external view returns (bool) {
		if (stakerDetails[poolId][user].lastChangeTime == 0) {
			return false;
		}

		return block.timestamp > stakerDetails[poolId][user].lockEndTime;
	}

	/**
	 * @dev Rescue non staking tokens sent to this contract by accident.
	 */
	function rescueToken(address t, address receiver) external authorized {
		require(t != stakingToken, "Staking token can't be withdrawn!");
		uint256 balance = IERC20(t).balanceOf(address(this));
		IERC20(t).transfer(receiver, balance);
	}

	function viewPoolDetails(uint256 poolId) external view returns (PoolConfiguration memory) {
		return poolConfig[poolId];
	}

	function viewStake(uint256 poolId, address staker) public view returns (StakeState memory) {
		return stakerDetails[poolId][staker];
	}

	function viewMyStake(uint256 poolId) external view returns (StakeState memory) {
		return viewStake(poolId, msg.sender);
	}
}