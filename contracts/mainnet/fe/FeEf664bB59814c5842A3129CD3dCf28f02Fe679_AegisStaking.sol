/**
 *Submitted for verification at Etherscan.io on 2022-10-17
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
 * @dev Representation of a fraction
 */
struct Fraction {
	uint16 numerator;
	uint16 denominator;
}

/**
 * @dev Describes each possible pool status: Inactive it did not begin yet, active people can stake and unstake,
 * finished means the staking is over but the prize has not yet been entirely given, cleared means this match is entirely over and stakes done.
 */
enum Status {
	INACTIVE,
	ACTIVE,
	FINISHED,
	CLEARED
}

/**
 * @dev There are two pools to bet on when staking, pool A and pool B.
 * pool A is the ID 0 and pool B is the id 1.
 */
struct Match {
	bool stakingEnabled;
	int8 winningPool;
	uint256 poolAStakedTokens;
	uint256 poolBStakedTokens;
	mapping (address => uint256) poolAStakes;
	mapping (address => uint256) poolBStakes;
	Status matchStatus;
	uint256 totalPrize;
	uint256 winningPoolTokens;
}

contract AegisStaking is Auth {
	address public stakingToken;
	Fraction internal depositFee = Fraction(1, 10);
	address internal feeReceiver;
	Match internal currentMatch;
	uint256 internal reentrancyStatus;

	event Stake(address indexed staker, uint256 indexed poolId, uint256 amount);
	event Unstake(address indexed staker, uint256 indexed poolId, uint256 amount);
	event WinningPool(uint256 indexed poolId);
	event NewStakingPools();
	event StakingOpen();
	event StakingClosed();

	constructor(address t, address fr) Auth(msg.sender) {
		stakingToken = t;
		feeReceiver = fr;
		currentMatch;
		currentMatch.winningPool = -1;
		currentMatch.matchStatus = Status.ACTIVE;
		currentMatch.stakingEnabled = true;
	}

	modifier validPool(uint256 poolId) {
		require(poolId == 0 || poolId == 1, "Only valid pool IDs are 0 and 1.");
		_;
	}

	modifier validTokenAmount(uint256 amount) {
		require(amount > 0, "Amount needs to be bigger than 0");
		_;
	}

	modifier stakingIsEnabled {
		require(currentMatch.stakingEnabled, "Staking is not currently enabled.");
		_;
	}

	modifier nonReentrant() {
        require(reentrancyStatus == 0, "Reentrant call");
		reentrancyStatus = 1;
        _;
        reentrancyStatus = 0;
    }

	/**
	 * @dev Add your betting stake to a pool.
	 */
	function stake(uint256 poolId, uint256 amount) external validPool(poolId) validTokenAmount(amount) stakingIsEnabled nonReentrant {
		// Transfer tokens from the owner to the staking contract.
		IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);

		// If appliable, get the deposit fee and send to the set receiver.
		uint256 toStake = amount;
		Fraction memory df = depositFee;
		if (df.numerator > 0 && df.denominator > 0) {
			uint256 fee = amount * df.numerator / df.denominator;
			toStake = amount - fee;
			IERC20(stakingToken).transfer(feeReceiver, fee);
		}

		// Add stake to corresponding pool.
		stakeFor(msg.sender, poolId, toStake);

		emit Stake(msg.sender, poolId, toStake);
	}

	function stakeFor(address staker, uint256 poolId, uint256 amount) internal {
		if (poolId == 0) {
			currentMatch.poolAStakes[staker] += amount;
			currentMatch.poolAStakedTokens += amount;
		} else {
			currentMatch.poolBStakes[staker] += amount;
			currentMatch.poolBStakedTokens += amount;
		}
	}

	/**
	 * @dev Unstake to remove part or the entirety of a stake.
	 */
	function unstake(uint256 poolId, uint256 amount) external validPool(poolId) validTokenAmount(amount) stakingIsEnabled nonReentrant {
		uint256 toUnstake = unstakeFor(msg.sender, poolId, amount);
		if (toUnstake > 0) {
			IERC20(stakingToken).transfer(msg.sender, toUnstake);

			emit Unstake(msg.sender, poolId, toUnstake);
		}
	}

	function unstakeFor(address staker, uint256 poolId, uint256 amount) internal returns (uint256) {
		// Check staked tokens status and update the amount.
		uint256 toUnstake = amount;
		if (poolId == 0) {
			if (currentMatch.poolAStakes[staker] == 0) {
				return 0;
			}
			// If attempting to unstake more than staked simply unstake all at once.
			if (amount > currentMatch.poolAStakes[staker]) {
				toUnstake = currentMatch.poolAStakes[staker];
			}
			currentMatch.poolAStakes[staker] -= toUnstake;
			currentMatch.poolAStakedTokens -= toUnstake;
		} else {
			if (currentMatch.poolBStakes[staker] == 0) {
				return 0;
			}
			// If attempting to unstake more than staked simply unstake all at once.
			if (amount > currentMatch.poolBStakes[staker]) {
				toUnstake = currentMatch.poolBStakes[staker];
			}
			currentMatch.poolBStakes[staker] -= toUnstake;
			currentMatch.poolBStakedTokens -= toUnstake;
		}

		return toUnstake;
	}

	function setWinningPool(uint256 poolId) external validPool(poolId) authorized {
		require(currentMatch.matchStatus == Status.INACTIVE, "The staking must have been closed before picking a winning pool.");
		currentMatch.matchStatus = Status.FINISHED;
		currentMatch.winningPool = int8(uint8(poolId));
		uint256 poolAStake = currentMatch.poolAStakedTokens;
		uint256 poolBStake = currentMatch.poolBStakedTokens;
		currentMatch.totalPrize = poolId == 0 ? poolBStake : poolAStake;
		currentMatch.winningPoolTokens = poolId == 0 ? poolAStake : poolBStake;

		emit WinningPool(poolId);
	}

	/**
	 * @dev Sets which address receives the deposit fee.
	 */
	function setFeeReceiver(address newFeeReceier) external authorized {
		feeReceiver = newFeeReceier;
	}

	function setDepositFee(uint16 numerator, uint16 denominator) external authorized {
		depositFee.numerator = numerator;
		depositFee.denominator = denominator;
	}

	function getTotalStakedTokens() public view returns (uint256) {
		return currentMatch.poolAStakedTokens + currentMatch.poolBStakedTokens;
	}

	function getPoolAStakedTokens() external view returns (uint256) {
		return currentMatch.poolAStakedTokens;
	}

	function getPoolBStakedTokens() external view returns (uint256) {
		return currentMatch.poolBStakedTokens;
	}

	function getUserStakedTokens(address user, uint256 poolId) public view returns (uint256) {
		if (poolId == 0) {
			return currentMatch.poolAStakes[user];
		}
		if (poolId == 1) {
			return currentMatch.poolBStakes[user];
		}

		return 0;
	}

	function isStakingEnabled() external view returns (bool) {
		return currentMatch.stakingEnabled;
	}

	function getCurrentStakingStatus() public view returns (Status) {
		return currentMatch.matchStatus;
	}

	function getTotalPrize() external view returns (uint256) {
		return currentMatch.totalPrize;
	}

	function getWinningPoolTokens() external view returns (uint256) {
		return currentMatch.winningPoolTokens;
	}

	function getWinningPool() external view returns (int8) {
		return currentMatch.winningPool;
	}

	function setStakingEnabled(bool enabled) external authorized {
		if (enabled) {
			// Enable staking from either uninitialised state or restarting the stake before a winner is picked.
			require(currentMatch.matchStatus == Status.INACTIVE, "Staking must be inactive.");
			currentMatch.stakingEnabled = true;
			currentMatch.matchStatus = Status.ACTIVE;

			emit StakingOpen();
		} else {
			// Turn staking off in order to decide a winning pool or to temporarily pause the stake process.
			require(currentMatch.matchStatus == Status.ACTIVE, "Staking must be active.");
			currentMatch.stakingEnabled = false;
			currentMatch.matchStatus = Status.INACTIVE;

			emit StakingClosed();
		}
	}

	function forcePayout(address staker) external authorized {
		processPayout(staker);
	}

	function claimPrize() external {
		processPayout(msg.sender);
	}

	/**
	 * @dev Claim the stake and prize from a winning pool stake.
	 */
	function processPayout(address staker) internal nonReentrant {
		require(currentMatch.matchStatus == Status.FINISHED, "Winning bets can only be claimed when a winning pool has been decided.");
		uint256 win = uint256(uint8(currentMatch.winningPool));
		require(win == 0 || win == 1, "Winning pool is not correctly set!");
		uint256 prize = getUserPrize(staker);
		require(prize > 0, "No prize to claim.");
		uint256 stakedTokens = getUserStakedTokens(staker, win);
		uint256 toGive = prize + stakedTokens;

		// Remove stake and total count from winner pool to mark it as delivered.
		// Pool A
		if (win == 0) {
			delete currentMatch.poolAStakes[staker];
			currentMatch.poolAStakedTokens -= stakedTokens;
			if (currentMatch.poolAStakedTokens == 0) {
				currentMatch.matchStatus = Status.CLEARED;
			}
		}
		// Pool B
		if (win == 1) {
			delete currentMatch.poolBStakes[staker];
			currentMatch.poolBStakedTokens -= stakedTokens;
			if (currentMatch.poolBStakedTokens == 0) {
				currentMatch.matchStatus = Status.CLEARED;
			}
		}

		IERC20(stakingToken).transfer(staker, toGive);
	}

	function resetStaking() external authorized {
		require(
			currentMatch.matchStatus == Status.CLEARED || getTotalStakedTokens() == 0,
			"New staking can only be started when previous one is cleared."
		);
		delete currentMatch;
		currentMatch.winningPool = -1;
		currentMatch.matchStatus = Status.INACTIVE;

		emit NewStakingPools();
	}

	/**
	 * @dev Gets the price for a specific staker.
	 */
	function getUserPrize(address staker) public view returns (uint256) {
		uint256 stakedTokens;
		int8 win = currentMatch.winningPool;
		// Winner is pool A.
		if (win == 0) {
			stakedTokens = currentMatch.poolAStakes[staker];
		}
		// Winner is pool B.
		if (win == 1) {
			stakedTokens = currentMatch.poolBStakes[staker];
		}
		if (stakedTokens > 0) {
			return calculatePrize(stakedTokens, currentMatch.winningPoolTokens, currentMatch.totalPrize);
		}

		return 0;
	}

	/**
	 * @dev Calculates a price from the total prize and stake in a pool.
	 */
	function calculatePrize(uint256 stakedTokens, uint256 totalPoolStake, uint256 prize) public pure returns (uint256) {
		if (stakedTokens == 0 || totalPoolStake == 0 || prize == 0) {
			return 0;
		}
		// Factor used to avoid losing digits to rounding.
		uint256 factor = 10000;
		uint256 part = stakedTokens * factor / totalPoolStake;
		return part * prize / factor;
	}

	function recoverDust() external authorized {
		require(currentMatch.matchStatus == Status.CLEARED, "Requires all prizes to have been given out.");
		IERC20 st = IERC20(stakingToken);
		st.transfer(feeReceiver, st.balanceOf(address(this)));
	}
}