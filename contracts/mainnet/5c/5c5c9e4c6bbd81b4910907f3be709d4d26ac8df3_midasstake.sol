/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

/**
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

contract midasstake is Auth {

    struct PoolConfiguration {
        uint256 poolStakedTokens;
		uint16 apr;
		uint16 depositFee;
        uint16 earlyWithdrawFee;
        uint32 withdrawLockPeriod;
		bool available;
		bool burnDeposit;
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
	event PoolConfigurated(uint16 apr, uint16 depositFee, uint32 lockPeriod, uint16 earlyWithdrawFee);
	event DepositFeeBurnStatus(bool active);
	event DepositFeeBurn(uint256 burn);
	event StakingTokenUpdate(address indexed oldToken, address indexed newToken);

	// Informs about the address for the token being used for staking.
	address public stakingToken;

    // Taxes are set in /10000.
	// Using solidity underscore separator for easier reading.
	// Digits before underscore are the percentage.
	// Digits after underscore are decimals for said percentage.
    uint256 public immutable denominator = 100_00;

    // Staking pool configuration.
	PoolConfiguration private poolConfig;

	// Info of each user that stakes tokens.
	mapping (address => StakeState) public stakerDetails;

	// Burn address.
	address public immutable DEAD = address(0xdead);

	constructor(address t) Auth(msg.sender) {
		stakingToken = t;

		uint16 apr = 100_00; // 100%
		uint16 depositFee = 3_00; // 3%
		uint16 earlyWithdrawFee = 70_00; // 70%
		uint32 lockPeriod = 7 days;
		bool available = true;

		_setStakingConfig(apr, depositFee, earlyWithdrawFee, lockPeriod, available, false);
	}

	modifier noStakes {
		require(poolConfig.poolStakedTokens == 0, "Action can only be done when there are no staked tokens.");
		_;
	}

	modifier positiveAPR(uint16 apr) {
		require(apr > 0, "APR cannot be 0.");
		_;
	}

	modifier validFee(uint16 fee) {
		require(fee <= 5000, "Fees cannot be more than 50%.");
		_;
	}

	modifier validLockPeriod(uint32 time) {
		require(time < 365 days, "Lockout period should be less than a year.");
		_;
	}

	function setPoolConfiguration(
		uint16 apr, uint16 depositFee, uint16 earlyWithdrawFee, uint32 withdrawLockPeriod, bool active, bool burn
	)
		external authorized noStakes positiveAPR(apr)
		validFee(depositFee) validFee(earlyWithdrawFee)
		validLockPeriod(withdrawLockPeriod)
	{		
		_setStakingConfig(apr, depositFee, earlyWithdrawFee, withdrawLockPeriod, active, burn);
	}

	/**
	 * @dev Internal function for updating full stake configuration.
	 */
	function _setStakingConfig(
		uint16 apr, uint16 depositFee, uint16 earlyWithdrawFee, uint32 withdrawLockPeriod, bool active, bool burn
	) internal {
		poolConfig.apr = apr;
		poolConfig.depositFee = depositFee;
        poolConfig.earlyWithdrawFee = earlyWithdrawFee;
		poolConfig.withdrawLockPeriod = withdrawLockPeriod;
		poolConfig.available = active;
		poolConfig.burnDeposit = burn;

		emit PoolConfigurated(apr, depositFee, withdrawLockPeriod, earlyWithdrawFee);
		emit PoolAvailability(active);
		emit DepositFeeBurnStatus(burn);
	}

	/**
	 * @dev Sets APR out of / 10000.
	 * Each 100 means 1%.
	 */
	function setAPR(uint16 apr) external authorized positiveAPR(apr) {
		if (poolConfig.poolStakedTokens > 0) {
			require(apr >= poolConfig.apr, "APR cannot be lowered while there are tokens staked.");
		}
		poolConfig.apr = apr;

		emit PoolConfigurated(apr, poolConfig.depositFee, poolConfig.withdrawLockPeriod, poolConfig.earlyWithdrawFee);
	}

	/**
	 * @dev Sets deposit fee out of / 10000.
	 */
	function setDepositFee(uint16 fee) external authorized validFee(fee) {
		poolConfig.depositFee = fee;

		emit PoolConfigurated(poolConfig.apr, fee, poolConfig.withdrawLockPeriod, poolConfig.earlyWithdrawFee);
	}

	/**
	 * @dev Early withdraw fee out of / 10000.
	 */
	function setEarlyWithdrawFee(uint16 fee) external authorized validFee(fee) {
		poolConfig.earlyWithdrawFee = fee;

		emit PoolConfigurated(poolConfig.apr, poolConfig.depositFee, poolConfig.withdrawLockPeriod, fee);
	}

	/**
	 * @dev Pool can be set inactive to end staking after the last lock and restart with new values.
	 */
	function setPoolAvailable(bool active) external authorized {
		poolConfig.available = active;
		emit PoolAvailability(active);
	}

	/**
	 * @dev Early withdraw penalty in seconds.
	 */
	function setEarlyWithdrawLock(uint32 time) external authorized noStakes validLockPeriod(time) {
		poolConfig.withdrawLockPeriod = time;
		emit PoolConfigurated(poolConfig.apr, poolConfig.depositFee, time, poolConfig.earlyWithdrawFee);
	}

	function setFeeBurn(bool burn) external authorized {
		poolConfig.burnDeposit = burn;
		emit DepositFeeBurnStatus(burn);
	}

    function updateStakingToken(address t) external authorized noStakes {
		emit StakingTokenUpdate(stakingToken, t);
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
		if (block.timestamp <= user.lastChangeTime) {
			return 0;
		}
		uint256 deltaTime = block.timestamp - user.lastChangeTime;
		uint256 accrued = yieldFromElapsedTime(user.stakedAmount, deltaTime);

		return accrued + user.rewardDebt;
	}

	function yieldFromElapsedTime(uint256 amount, uint256 deltaTime) public view returns (uint256) {
		// No elapsed time or no amount means no reward accrued.
		if (amount == 0 || deltaTime == 0) {
			return 0;
		}

		/**
		 * It's quite simple to derive owed reward from time using the set duration (APR):
		 * Total cycle reward plus time elapsed divided by cycle duration.
		 * Time is counted by seconds, so we divide the total reward by seconds and calculate the amount due to seconds passed.
		 */
		uint256 annuality = annualYield(amount);
		if (annuality == 0) {
			return 0;
		}

		return (deltaTime * annuality) / 365 days;
	}

	/**
	 * @dev Given an amount to stake returns a total yield as per APR.
	 */
	function annualYield(uint256 amount) public view returns (uint256) {
		if (amount == 0 || poolConfig.apr == 0) {
			return 0;
		}

		return amount * poolConfig.apr / denominator;
	}

	function dailyYield(uint256 amount) external view returns (uint256) {
		// Due to how Solidity decimals work, any amount less than 365 will yield 0 per day.
		// On a 9 decimal token this means less than 0.000000365 -- basically nothing at all.
		// Once the time has surpassed 365 days the yield will be owed normally as soon as the decimal place jumps.
		if (amount < 365) {
			return 0;
		}
		if (amount == 365) {
			return 1;
		}

		return annualYield(amount) / 365;
	}

	function stake(uint256 amount) external {
		require(amount > 0, "Amount needs to be bigger than 0");
		require(poolConfig.available, "Pool is not accepting staking right now.");

		IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);
		StakeState storage user = stakerDetails[msg.sender];
		// Calc unclaimed reward on stake update.
		if (user.lastChangeTime != 0 && user.stakedAmount > 0) {
			user.rewardDebt = pendingReward(msg.sender);
		}
        uint256 stakeAmount = amount;

        // Check deposit fee
        if (poolConfig.depositFee > 0) {
            uint256 dFee = depositFeeFromAmount(amount);
            stakeAmount -= dFee;
			// If the pool has enough for rewards, deposit fee can be sent to burn address instead.
			if (poolConfig.burnDeposit) {
				IERC20(stakingToken).transfer(DEAD, dFee);
				emit DepositFeeBurn(dFee);
			}
        }

		user.stakedAmount += stakeAmount;
		uint32 rnow = uint32(block.timestamp);
		user.lastChangeTime = rnow;
        if (user.lockEndTime == 0) {
            user.lockEndTime = rnow + poolConfig.withdrawLockPeriod;
        }
		poolConfig.poolStakedTokens += stakeAmount;

		emit TokenStaked(msg.sender, stakeAmount);
	}

	function depositFeeFromAmount(uint256 amount) public view returns (uint256) {
		if (poolConfig.depositFee == 0) {
			return 0;
		}
		return amount * poolConfig.depositFee / denominator;
	}

	function unstake() external {
		unstakeFor(msg.sender);
	}

	function unstakeFor(address staker) internal {
		StakeState storage user = stakerDetails[staker];
		uint256 amount = user.stakedAmount;
		require(amount > 0, "No stake on pool.");

		// Update user staking status.
		// When unstaking is done, claim is automatically done.
		_claim(staker);
		user.stakedAmount = 0;

		uint256 unstakeAmount = amount;
        // Check for early withdraw fee.
        if (block.timestamp < user.lockEndTime && poolConfig.earlyWithdrawFee > 0) {
            uint256 fee = amount * poolConfig.earlyWithdrawFee / denominator;
            unstakeAmount -= fee;
        }
        user.lockEndTime = 0;

		IERC20 stakedToken = IERC20(stakingToken);
		// Check for a clear revert error if rewards+unstake surpass balance.
		require(stakedToken.balanceOf(address(this)) >= unstakeAmount, "Staking contract does not have enough tokens.");

		// Return token to staker and update staking values.
		stakedToken.transfer(staker, unstakeAmount);
		poolConfig.poolStakedTokens -= amount;

		emit TokenUnstaked(staker, unstakeAmount);
	}

	function claim() external {
		_claim(msg.sender);
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

	function _claim(address staker) internal {
		StakeState storage user = stakerDetails[staker];
		uint256 outAmount = pendingReward(staker);
		if (outAmount > 0) {
			// Check for a clear revert error if rewards+unstake surpass balance.
			uint256 contractBalance = IERC20(stakingToken).balanceOf(address(this));
			require(contractBalance >= outAmount, "Staking contract does not own enough tokens.");

			IERC20(stakingToken).transfer(staker, outAmount);
			user.rewardDebt = 0;
			user.lastChangeTime = uint32(block.timestamp);

			emit RewardClaimed(staker, outAmount);
		}
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

	function viewMyPendingReward() external view returns (uint256) {
		return pendingReward(msg.sender);
	}

	/**
	 * @dev Returns APR in percentage.
	 */
	function viewAPRPercent() external view returns (uint16) {
		return poolConfig.apr / 100;
	}

	/**
	 * @dev Returns APR in percentage and 2 decimal points in an extra varaible.
	 */
	function viewAPRPercentDecimals() external view returns (uint16 aprPercent, uint16 decimalValue) {
		return (poolConfig.apr / 100, poolConfig.apr % 100);
	}

	/**
	 * @dev Given a theroetical stake, returns the unstake returning amount, deposit fee paid, and yield on a full cycle.
	 */
	function simulateYearStake(uint256 amount) external view returns (uint256 unstakeAmount, uint256 depositFee, uint256 yield) {
		if (amount == 0) {
			return (0, 0, 0);
		}
		uint256 fee = depositFeeFromAmount(amount);
		uint256 actual = amount - fee;
		uint256 y = annualYield(actual);

		return (actual, fee, y);
	}

	/**
	 * @dev Given an amount to stake and a duration, returns unstake returning amount, deposit fee paid, and yield.
	 */
	function simulateStake(uint256 amount, uint32 duration) external view returns (uint256 unstakeAmount, uint256 depositFee, uint256 yield) {
		if (amount == 0 || duration == 0) {
			return (0, 0, 0);
		}
		uint256 fee = depositFeeFromAmount(amount);
		uint256 actual = amount - fee;
		uint256 y = yieldFromElapsedTime(actual, duration);
		if (duration < poolConfig.withdrawLockPeriod && poolConfig.earlyWithdrawFee > 0) {
            uint256 withdrawFee = amount * poolConfig.earlyWithdrawFee / denominator;
            actual -= withdrawFee;
        }

		return (actual, fee, y);
	}

	/**
	 * @dev Returns total amount of tokens staked by users.
	 */
	function totalStakedTokens() external view returns (uint256) {
		return poolConfig.poolStakedTokens;
	}
}