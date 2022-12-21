/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

contract PyroStakingV2 is Auth {

    struct StakeState {
		uint256 stakedAmount;
		uint256 rewardDebt;
        uint256 aprIndex;
		uint32 lastChangeTime;
		uint32 lockEndTime;
	}

	address public stakingToken;
    uint256 public stakedTokens;
    uint16 public constant denominator = 10000;
    uint16 public depositFee;
    uint16 public earlyWithdrawFee;
    uint32 public withdrawLockPeriod;
    bool public available;
    mapping (uint256 => uint16) internal _aprValues;
    uint256 internal activeAPRIndex;
    uint256 internal lastAPRupdate;
	mapping (address => StakeState) internal stakerDetails;

    event TokenStaked(address indexed user, uint256 amount);
	event TokenUnstaked(address indexed user, uint256 amount, uint256 yield);
	event RewardClaimed(address indexed user, uint256 outAmount);
	event StakingConfigured(uint16 newAPR, uint16 newDepositFee, uint32 newLockPeriod, uint16 newWithdrawFee, bool available);
	event StakingTokenUpdate(address indexed oldToken, address indexed newToken);

    error LockedStake(uint32 unlockTime);
    error NoStakesRequired();
    error DepositFeeTooHigh(uint16 attemptedFee, uint16 maxFee);
    error InvalidWithdrawFee(uint16 attemptedFee, uint16 maxFee);
    error LockTooLong(uint32 attemptedLock, uint32 maxLock);
    error InvalidAPR(uint16 attempted, uint16 min, uint16 max);
    error ZeroStake();
    error StakingUnavailable();
    error NoAvailableYield();
    error StakingActive();
    error NoRewardTokens(uint256 needed, uint256 owned);
    error InvalidWithdraw();
    error GuaranteeTooShort();

    modifier noStakes {
        if (stakedTokens > 0) {
            revert NoStakesRequired();
        }
		_;
	}

	modifier validDepositFee(uint16 fee) {
        uint16 max = denominator / 2;
        if (fee > max) {
            revert DepositFeeTooHigh(fee, max);
        }
		_;
	}

    modifier validWithdrawFee(uint16 fee) {
        if (fee > denominator) {
            revert InvalidWithdrawFee(fee, denominator);
        }
		_;
	}

	modifier validLockPeriod(uint32 time) {
        if (time > 365 days) {
            revert LockTooLong(time, 365 days);
        }
		_;
	}

    modifier validAPR(uint16 proposedAPR) {
        uint16 max = type(uint16).max;
        if (proposedAPR == 0) {
            revert InvalidAPR(0, 1, max);
        }
        if (proposedAPR > max) {
            revert InvalidAPR(proposedAPR, 1, max);
        }
        _;
    }

	constructor(address tokenToStake) Auth(msg.sender) {
		stakingToken = tokenToStake;
		_setStakingConfig(4000, 670, 30 days, 5000, true);
	}

	function setStakingConfiguration(
		uint16 newAPR, uint16 newDepositFee, uint32 newLockPeriod,
        uint16 newWithdrawFee, bool active
	)
		external authorized validAPR(newAPR) validDepositFee(newDepositFee)
        validWithdrawFee(newWithdrawFee) validLockPeriod(newLockPeriod)
	{
		_setStakingConfig(newAPR, newDepositFee, newLockPeriod, newWithdrawFee, active);
	}

	function _setStakingConfig(
		uint16 newAPR, uint16 newDepositFee, uint32 newLockPeriod,
        uint16 newWithdrawFee, bool newAvailability
	) internal {
		_updateAPR(newAPR);
		depositFee = newDepositFee;
		withdrawLockPeriod = newLockPeriod;
        earlyWithdrawFee = newWithdrawFee;
		available = newAvailability;

		emit StakingConfigured(newAPR, newDepositFee, newLockPeriod, newWithdrawFee, newAvailability);
	}

	function setAPR(uint16 newAPR) external authorized validAPR(newAPR) {
		_updateAPR(newAPR);
		emit StakingConfigured(newAPR, depositFee, withdrawLockPeriod, earlyWithdrawFee, available);
	}

    function _updateAPR(uint16 newAPR) internal {
        ++activeAPRIndex;
        _aprValues[activeAPRIndex] = newAPR;
        lastAPRupdate = block.timestamp;
    }

	function setDepositFee(uint16 fee) external authorized validDepositFee(fee) {
		depositFee = fee;
        emit StakingConfigured(getCurrentAPR(), fee, withdrawLockPeriod, earlyWithdrawFee, available);
	}

	function setEarlyWithdrawFee(uint16 fee) external authorized validWithdrawFee(fee) {
		earlyWithdrawFee = fee;
        emit StakingConfigured(getCurrentAPR(), depositFee, withdrawLockPeriod, fee, available);
	}

	function setPoolAvailable(bool active) external authorized {
		available = active;
		emit StakingConfigured(getCurrentAPR(), depositFee, withdrawLockPeriod, earlyWithdrawFee, active);
	}

	function setEarlyWithdrawLock(uint32 time) external authorized validLockPeriod(time) {
		withdrawLockPeriod = time;
		emit StakingConfigured(getCurrentAPR(), depositFee, time, earlyWithdrawFee, available);
	}

    function updateStakingToken(address newToken) external authorized noStakes {
		emit StakingTokenUpdate(stakingToken, newToken);
        stakingToken = newToken;
    }

	function pendingReward(address account) public view virtual returns (uint256) {
		StakeState storage user = stakerDetails[account];
        return _pendingReward(user);
	}

    function _pendingReward(StakeState storage user) internal view returns (uint256) {
        // Last change time of 0 means there's never been a stake to begin with.
		if (user.lastChangeTime == 0) {
			return 0;
		}

		// Elapsed time since last stake update.
		if (block.timestamp <= user.lastChangeTime) {
			return 0;
		}

        // Check whether APR has changed since stake was done.
        // Take this into consideration while securing past APR.
        uint256 accrued;
        uint256 deltaTime;

        if (user.aprIndex != activeAPRIndex) {
            if (user.lastChangeTime >= lastAPRupdate) {
                deltaTime = block.timestamp - user.lastChangeTime;
                accrued = yieldFromElapsedTime(user.stakedAmount, deltaTime, _aprValues[activeAPRIndex]);
            } else {
                uint256 recentDelta = block.timestamp - lastAPRupdate;
                deltaTime = lastAPRupdate - user.lastChangeTime;
                accrued = yieldFromElapsedTime(user.stakedAmount, recentDelta, _aprValues[activeAPRIndex]);
                accrued += yieldFromElapsedTime(user.stakedAmount, deltaTime, _aprValues[user.aprIndex]);
            }
        } else {
            deltaTime = block.timestamp - user.lastChangeTime;
            accrued = yieldFromElapsedTime(user.stakedAmount, deltaTime, _aprValues[user.aprIndex]);
        }

        // Accrued is what currently is pending, reward debt is stored unclaimed yield value from a update.
		return accrued + user.rewardDebt;
    }

	function yieldFromElapsedTime(uint256 amount, uint256 deltaTime, uint16 appliedAPR) public pure returns (uint256) {
		// No elapsed time, no amount, 0% APR obviously means 0 tokens yielded.
		if (amount == 0 || deltaTime == 0 || appliedAPR == 0) {
			return 0;
		}

		// Calculate the owed reward by seconds elapsed derived from the total reward.
		uint256 annuality = annualYield(amount, appliedAPR);
		if (annuality == 0) {
			return 0;
		}

		return (deltaTime * annuality) / 365 days;
	}

	function annualYield(uint256 amount, uint16 appliedAPR) public pure returns (uint256) {
		if (amount == 0 || appliedAPR == 0) {
			return 0;
		}

		return amount * appliedAPR / denominator;
	}

	function stake(uint256 amount) external {
        _stake(msg.sender, amount);
	}

    function _stake(address staker, uint256 amount) internal {
        if (amount == 0) {
            revert ZeroStake();
        }
        if (!available) {
            revert StakingUnavailable();
        }

		StakeState storage user = stakerDetails[staker];
		// Calc unclaimed reward on stake update and set reward timer to now.
        // This allows to increase the stake without needing a claim.
		if (user.lastChangeTime != 0 && user.stakedAmount > 0) {
			user.rewardDebt = _pendingReward(user);
		}
        uint256 stakeAmount = amount;
        // Is deposit fee appliable?
        if (depositFee > 0) {
            uint256 dFee = depositFeeFromAmount(amount);
            unchecked {
                stakeAmount -= dFee;
            }
        }
        unchecked {
		    user.stakedAmount += stakeAmount;
        }

        // First index is 1 and in case of re-stake pending yield has been stored already.
        if (user.aprIndex != activeAPRIndex) {
            user.aprIndex = activeAPRIndex;
        }

        // For a first stake we get the lock period from current configuration.
		uint32 rnow = uint32(block.timestamp);
		user.lastChangeTime = rnow;
        if (user.lockEndTime == 0) {
            user.lockEndTime = rnow + withdrawLockPeriod;
        }

        // Keeping track of overall staked tokens.
        unchecked {
            stakedTokens += stakeAmount;
        }

        // Transfer tokens from staker to the contract.
        IERC20(stakingToken).transferFrom(staker, address(this), amount);

		emit TokenStaked(staker, stakeAmount);
    }

	function depositFeeFromAmount(uint256 amount) public view returns (uint256) {
		if (depositFee == 0) {
			return 0;
		}
		return amount * depositFee / denominator;
	}

	function unstake() public virtual {
		_unstake(msg.sender, false);
	}

    function emergencyUnstake() external {
        _unstake(msg.sender, true);
    }

    function unstakeFor(address staker) external authorized {
        _unstake(staker, false);
    }

    function emergencyUnstakeFor(address staker) external authorized {
        _unstake(staker, true);
    }

	function _unstake(address staker, bool forfeit) internal {
		StakeState storage user = stakerDetails[staker];
		uint256 userStakedTokens = user.stakedAmount;
        if (userStakedTokens == 0) {
            revert ZeroStake();
        }
        uint256 yield;
        uint256 unstakeAmount = userStakedTokens;
        bool isEarlyWithdraw = earlyWithdrawFee > 0 && block.timestamp < user.lockEndTime;

		// Update user staking status.
		// When unstaking is done, claim is automatically done.
        if (forfeit) {
            user.lastChangeTime = uint32(block.timestamp);
            user.rewardDebt = 0;
        } else {
            yield = _claim(user);
        }
		user.stakedAmount = 0;

        // Early withdraw fee.
        if (isEarlyWithdraw) {
            // If withdraw fee is set at 100%, it means the stake is fully locked.
            if (earlyWithdrawFee == denominator) {
                revert LockedStake(user.lockEndTime);
            }
            uint256 fee = userStakedTokens * earlyWithdrawFee / denominator;
            unchecked {
                unstakeAmount -= fee;
            }
        }
        user.lockEndTime = 0;

        // Return token to staker and update staking values.
		IERC20(stakingToken).transfer(staker, unstakeAmount + yield);
        unchecked {
		    stakedTokens -= userStakedTokens;
        }

		emit TokenUnstaked(staker, unstakeAmount, yield);
	}

	function claim() external {
        _claim(msg.sender);
	}

    function claimFor(address staker) external {
         _claim(staker);
    }

    function _claim(address staker) internal {
        StakeState storage user = stakerDetails[staker];
		uint256 outAmount = _claim(user);
        if (outAmount == 0) {
            revert NoAvailableYield();
        }
        if (user.aprIndex != activeAPRIndex) {
            user.aprIndex = activeAPRIndex;
        }
        IERC20(stakingToken).transfer(staker, outAmount);
        emit RewardClaimed(staker, outAmount);
	}

    /**
     * @dev Returns amount to be sent to user after calculating and updating yield.
     */
	function _claim(StakeState storage user) internal returns (uint256) {
		uint256 outAmount = _pendingReward(user);
		if (outAmount > 0) {
			// To protect user funds, reward tokens must not come from their staked tokens.
            // Claim transactions will all fail.
            // Non emergency unstake transactions as well, so it's up to the user to decide either:
            // Wait for availability of reward tokens.
            // Recover stake and forfeit any yield.
			uint256 availableReward = availableRewardTokens();
            if (availableReward < outAmount) {
                revert NoRewardTokens(outAmount, availableReward);
            }
			user.rewardDebt = 0;
			user.lastChangeTime = uint32(block.timestamp);
		}

        return outAmount;
	}

	function canWithdrawTokensNoFee(address user) external view returns (bool) {
		if (stakerDetails[user].lastChangeTime == 0) {
			return false;
		}

		return block.timestamp > stakerDetails[user].lockEndTime;
	}

	function rescueToken(address t) external authorized {
        if (t == stakingToken) {
            revert InvalidWithdraw();
        }
        IERC20 rescuee = IERC20(t);
		uint256 balance = rescuee.balanceOf(address(this));
		rescuee.transfer(msg.sender, balance);
	}

    function rescuePrizeTokens() external authorized {
        uint256 prize = availableRewardTokens();
        if (prize > 0) {
            IERC20(stakingToken).transfer(msg.sender, prize);
        }
	}

	function _getStake(address staker) internal view returns (StakeState memory) {
		return stakerDetails[staker];
	}

	function getOwnPendingReward() external view virtual returns (uint256) {
        StakeState storage user = stakerDetails[msg.sender];
		return _pendingReward(user);
	}

    function getCurrentAPR() public view returns (uint16) {
        return _aprValues[activeAPRIndex];
    }

    function availableRewardTokens() public view virtual returns (uint256) {
        uint256 balance = IERC20(stakingToken).balanceOf(address(this));
        if (stakedTokens >= balance) {
            return 0;
        }
        return balance - stakedTokens;
    }

    function getLastAPRUpdate() external view returns (uint256) {
        return lastAPRupdate;
    }

    function countAPRUpdates() external view returns (uint256) {
        if (activeAPRIndex == 0) {
            return 0;
        }
        return activeAPRIndex - 1;
    }

    function _totalStakedTokens() internal view returns (uint256) {
        return stakedTokens;
    }
}

interface IPyroStaking {
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
    function pendingReward(address account) external view returns (uint256);
    function forceClaimUnstake(address staker) external;
    function canWithdrawTokensNoFee(address user) external view returns (bool);
    function viewStake(address staker) external view returns (IPyroStaking.StakeState memory);
    function viewPoolDetails() external view returns (PoolConfiguration memory);
    function totalStakedTokens() external view returns (uint256);
}

struct CombinedStakeState {
    uint256 stakedAmount;
    uint256 rewardDebt;
    uint256 oldStaked;
    uint256 oldRewardDebt;
    uint256 newStaked;
    uint256 newRewardDebt;
    uint256 aprIndex;
    uint32 lastChangeTime;
    uint32 lockEndTime;
    uint32 oldLastChangeTime;
    uint32 oldLockEndTime;
}

/**
 * @dev Combines two staking strategies.
 */
contract PyroStakeUpgrader is PyroStakingV2 {

    address public previousStaking;
    bool internal _checkPrevious = true;

    constructor(address prevStaking, address token) PyroStakingV2(token) {
        previousStaking = prevStaking;
        stakingToken = token;
    }

    function pendingReward(address account) public view override returns (uint256) {
        uint256 previousPending;
        if (_checkPrevious && previousStaking != address(0)) {
            previousPending = IPyroStaking(previousStaking).pendingReward(account);
        }
        uint256 currPending = super.pendingReward(account);
        return previousPending + currPending;
    }

    function unstake() public override {
        if (_checkPrevious && previousStaking != address(0)) {
            try IPyroStaking(previousStaking).forceClaimUnstake(msg.sender) {} catch {}
        }
        super.unstake();
    }

    function unstakeV1Only() external {
        IPyroStaking(previousStaking).forceClaimUnstake(msg.sender);
    }

    function availableRewardTokens() public view override returns (uint256) {
        uint256 oldAvailable;
        if (_checkPrevious && previousStaking != address(0)) {
            uint256 oldBalance = IERC20(stakingToken).balanceOf(previousStaking);
            uint256 stakedOld = IPyroStaking(previousStaking).totalStakedTokens();
            if (oldBalance > stakedOld) {
                oldAvailable = oldBalance - stakedOld;
            }
        }
        uint256 v2Available = super.availableRewardTokens();

        return oldAvailable + v2Available;
    }

    function getStake(address staker) public view returns (CombinedStakeState memory) {
        CombinedStakeState memory comStake;
 
        PyroStakingV2.StakeState memory newStake = super._getStake(staker);
        comStake.stakedAmount = newStake.stakedAmount;
        comStake.newStaked = newStake.stakedAmount;
        comStake.rewardDebt = newStake.rewardDebt;
        comStake.newRewardDebt = newStake.rewardDebt;
        comStake.aprIndex = newStake.aprIndex;
        comStake.lastChangeTime = newStake.lastChangeTime;
        comStake.lockEndTime = newStake.lockEndTime;

        if (_checkPrevious && previousStaking != address(0)) {
            try IPyroStaking(previousStaking).viewStake(staker) returns (IPyroStaking.StakeState memory oldStake) {
                comStake.oldStaked = oldStake.stakedAmount;
                comStake.oldRewardDebt = oldStake.rewardDebt;
                comStake.stakedAmount += oldStake.stakedAmount;
                comStake.rewardDebt += oldStake.rewardDebt;
                comStake.oldLastChangeTime = oldStake.lastChangeTime;
                comStake.oldLockEndTime = oldStake.lockEndTime;
            } catch {}
        }

        return comStake;
    }

    function getOwnStake() external view returns (CombinedStakeState memory) {
        return getStake(msg.sender);
    }

	function getOwnPendingReward() external view override returns (uint256) {
        return pendingReward(msg.sender);
    }

    function totalStakedTokens() external view returns (uint256) {
        uint256 stakedOld;
        if (_checkPrevious && previousStaking != address(0)) {
            stakedOld = IPyroStaking(previousStaking).totalStakedTokens();
        }
        uint256 stakeV2 = super._totalStakedTokens();

        return stakedOld + stakeV2;
    }

    function setCheckV1(bool doCheck) external authorized {
        _checkPrevious = doCheck;
    }
}