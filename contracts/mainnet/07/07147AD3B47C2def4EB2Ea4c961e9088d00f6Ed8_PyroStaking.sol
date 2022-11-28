/**
 *Submitted for verification at Etherscan.io on 2022-11-28
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

contract PyroStaking is Auth {

    struct PoolConfiguration {
        uint256 poolStakedTokens;
		uint16 depositFee;
        uint16 earlyWithdrawFee;
        uint32 withdrawLockPeriod;
		bool available;
    }

	struct StakeState {
		uint256 stakedAmount;
		uint256 rewardDebt; 
		uint32 lastChangeTime;
		uint32 lockEndTime;
	}

	event TokenStaked(address indexed user, uint256 amount);
	event TokenUnstaked(address indexed user, uint256 amount);
	event RewardClaimed(address indexed user, uint256 outAmount);
	event PoolAvailability(bool available);
	event PoolConfigurated(uint16 numerator, uint32 lockPeriod, bool available);

	// Informs about the address for the token being used for staking.
	address public stakingToken;

	// Quick view to the total amount of staked tokens in a specific pool.
	uint256 public totalStakedTokens;

    // Taxes are set in /10000
    uint256 public immutable taxDenominator = 10000;

    // Staking pool configuration.
	PoolConfiguration private poolConfig;

	// Info of each user that stakes tokens.
	mapping (address => StakeState) public stakerDetails;

	constructor(address t) Auth(msg.sender) {
		stakingToken = t;
        poolConfig.available = true;
        poolConfig.depositFee = 5;
        poolConfig.earlyWithdrawFee = 5000;
        poolConfig.withdrawLockPeriod = 30 days;

        emit PoolConfigurated(5, 30 days, false);
	}

	function setPoolConfiguration(uint16 depositFee, uint16 earlyWithdrawFee, uint32 withdrawLockPeriod, bool active) external authorized {
		require(poolConfig.poolStakedTokens == 0, "Pool data cannot be changed while there are still tokens staked.");
        require(depositFee <= 3300, "Deposit fee cannot be more than 33%.");
        require(earlyWithdrawFee <= 5000, "Early withdraw fee cannot be more than 50%.");
		poolConfig.depositFee = depositFee;
        poolConfig.earlyWithdrawFee = earlyWithdrawFee;
		poolConfig.withdrawLockPeriod = withdrawLockPeriod;
		poolConfig.available = active;

		emit PoolConfigurated(depositFee, withdrawLockPeriod, active);
	}

	function setPoolAvailable(bool active) external authorized {
		poolConfig.available = active;

		emit PoolAvailability(active);
	}

    function updateStakingToken(address t) external authorized {
		require(totalStakedTokens == 0, "You cannot update the staking token while users are still staking.");
        stakingToken = t;
    }

	/**
	 * @dev Check the current unclaimed pending reward for a specific stake.
	 */
	function pendingReward(address account) public view returns (uint256) {
		StakeState storage user = stakerDetails[account];
		// Last change time of 0 means there's never been a stake to begin with.
		if (user.lastChangeTime == 0) {
			return 0;
		}
		// Ellapsed time since staking and now.
		uint256 endTime = block.timestamp;
		uint256 deltaTime = (endTime > user.lastChangeTime) ? endTime - user.lastChangeTime : 0;
		if (deltaTime == 0) {
			return 0;
		}

		/**
		 * Get the accrued reward:
		 * An entire year is the 100% of the reward, thus it's quite simply to derived owed reward from elapsed time.
		 * Total APR reward plus time elapsed divided by a year.
		 */
		uint256 rewardVal = (deltaTime * (user.stakedAmount * poolConfig.depositFee / taxDenominator)) / 365 days;

		return rewardVal + user.rewardDebt;
	}

	function stake(uint256 amount) external {
		require(amount > 0, "Amount needs to be bigger than 0");
		require(poolConfig.available, "Pool is not accepting staking right now.");

		IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);
		StakeState storage user = stakerDetails[msg.sender];
		user.rewardDebt = pendingReward(msg.sender);
        uint256 stakeAmount = amount;

        // Check deposit fee
        if (poolConfig.depositFee > 0) {
            uint256 dFee = amount * poolConfig.depositFee / taxDenominator;
            stakeAmount -= dFee;
        }

		user.stakedAmount += stakeAmount;
		uint32 rnow = uint32(block.timestamp);
		user.lastChangeTime = rnow;
        if (user.lockEndTime == 0) {
            user.lockEndTime = rnow + poolConfig.withdrawLockPeriod;
        }
		poolConfig.poolStakedTokens += stakeAmount;
		totalStakedTokens += stakeAmount;

		emit TokenStaked(msg.sender, stakeAmount);
	}

	function unstake() external {
		unstakeFor(msg.sender);
	}

	function unstakeFor(address staker) internal {
		StakeState storage user = stakerDetails[staker];
		uint256 amount = user.stakedAmount;
        uint256 unstakeAmount = amount;
		require(amount > 0, "No stake on pool.");
		require(IERC20(stakingToken).balanceOf(address(this)) >= amount, "Staking contract does not have enough tokens.");

		// Update user staking status.
		// When unstaking is done, claim is automatically done.
		claimFor(staker);
		user.stakedAmount = 0;

        // Check for early withdraw fee.
        if (block.timestamp < user.lockEndTime && poolConfig.earlyWithdrawFee > 0) {
            uint256 fee = amount * poolConfig.earlyWithdrawFee / taxDenominator;
            unstakeAmount -= fee;
        }
        user.lockEndTime = 0;

		// Return token to staker and update pool and overall staking values.
		IERC20(stakingToken).transfer(staker, unstakeAmount);
		poolConfig.poolStakedTokens -= amount;
		totalStakedTokens -= amount;

		emit TokenUnstaked(staker, unstakeAmount);
	}

	function claim() external {
		claimFor(msg.sender);
	}

	/**
	 * @dev Allows an authorised account to finalise a staking that has not claimed nor unstaked while the period is over.
	 */
	function forceClaimUnstake(address staker) external authorized {
		// Pool must not be available for staking, otherwise the user should be free to renew their stake.
		require(!poolConfig.available, "Pool is still available.");
		// The stake must have finished its lock time and accrued all the APR.
		require(block.timestamp > stakerDetails[staker].lockEndTime, "User's lock time has not finished yet.");
		// Run their claim and unstake.
		unstakeFor(staker);
	}

	function claimFor(address staker) internal {
		StakeState storage user = stakerDetails[staker];
		uint256 outAmount = pendingReward(staker);
		require(outAmount > 0, "Nothing to claim.");
		uint256 contractBalance = IERC20(stakingToken).balanceOf(address(this));
		require(contractBalance > outAmount && contractBalance - outAmount >= totalStakedTokens, "Staking contract does not own enough tokens.");

		IERC20(stakingToken).transfer(staker, outAmount);
		user.rewardDebt = 0;
		user.lastChangeTime = uint32(block.timestamp);

		emit RewardClaimed(staker, outAmount);
	}

	/**
	 * @dev Checks whether there's a stake withdraw fee or not.
	 */
	function canWithdrawTokensNoFee(address user) external view returns (bool) {
		if (stakerDetails[user].lastChangeTime == 0) {
			return false;
		}

		return block.timestamp > stakerDetails[user].lockEndTime;
	}

	/**
	 * @dev Rescue non staking tokens sent to this contract by accident.
	 */
	function rescueToken(address t, address receiver) external authorized {
		require(t != stakingToken, "Staking token can't be withdrawn!");
		uint256 balance = IERC20(t).balanceOf(address(this));
		IERC20(t).transfer(receiver, balance);
	}

	function viewPoolDetails() external view returns (PoolConfiguration memory) {
		return poolConfig;
	}

	function viewStake(address staker) public view returns (StakeState memory) {
		return stakerDetails[staker];
	}

	function viewMyStake() external view returns (StakeState memory) {
		return viewStake(msg.sender);
	}
}