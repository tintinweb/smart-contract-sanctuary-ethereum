/**
 *Submitted for verification at Etherscan.io on 2022-10-23
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
	mapping (uint256 => uint256) poolStakedTokens;
	mapping (uint256 => mapping (address => uint256)) poolStakes;
	Status matchStatus;
	uint256 totalPrize;
	uint256 winningPoolTokens;
	uint256 iteration;
}

contract AegisStaking is Auth {
	address public stakingToken;
	Fraction internal depositFee = Fraction(1, 4);
	address internal feeReceiver;
	Match internal stakingMatch;
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
		stakingMatch.winningPool = -1;
		stakingMatch.matchStatus = Status.ACTIVE;
		stakingMatch.stakingEnabled = true;
		stakingMatch.iteration = 1;
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
		require(stakingMatch.stakingEnabled, "Staking is not currently enabled.");
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
	function stake(uint256 externalPoolId, uint256 amount) external validPool(externalPoolId) validTokenAmount(amount) stakingIsEnabled nonReentrant {
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

		uint256 realPoolId = getRealPoolID(externalPoolId);

		// Add stake to corresponding pool.
		stakeFor(msg.sender, realPoolId, toStake);

		emit Stake(msg.sender, externalPoolId, toStake);
	}

	function stakeFor(address staker, uint256 realPoolId, uint256 amount) internal {
		stakingMatch.poolStakes[realPoolId][staker] += amount;
		stakingMatch.poolStakedTokens[realPoolId] += amount;
	}

	function getRealPoolID(uint256 externalPoolId) internal view returns (uint256) {
		uint256 realPoolId;
		if (externalPoolId == 0) {
			realPoolId = getPoolAID();
		} else {
			realPoolId = getPoolBID();
		}

		return realPoolId;
	}

	/**
	 * @dev Unstake to remove part or the entirety of a stake.
	 */
	function unstake(uint256 externalPoolId, uint256 amount) external validPool(externalPoolId) validTokenAmount(amount) stakingIsEnabled nonReentrant {
		uint256 realPoolId = getRealPoolID(externalPoolId);
		uint256 toUnstake = unstakeFor(msg.sender, realPoolId, amount);
		if (toUnstake > 0) {
			IERC20(stakingToken).transfer(msg.sender, toUnstake);

			emit Unstake(msg.sender, externalPoolId, toUnstake);
		}
	}

	function unstakeFor(address staker, uint256 realPoolId, uint256 amount) internal returns (uint256) {
		// Check staked tokens status and update the amount.
		uint256 toUnstake = amount;

		if (stakingMatch.poolStakes[realPoolId][staker] == 0) {
			return 0;
		}
		// If attempting to unstake more than staked simply unstake all at once.
		if (amount > stakingMatch.poolStakes[realPoolId][staker]) {
			toUnstake = stakingMatch.poolStakes[realPoolId][staker];
		}
		stakingMatch.poolStakes[realPoolId][staker] -= toUnstake;
		stakingMatch.poolStakedTokens[realPoolId] -= toUnstake;

		return toUnstake;
	}

	function setWinningPool(uint256 externalPoolId) external validPool(externalPoolId) authorized {
		require(stakingMatch.matchStatus == Status.INACTIVE, "The staking must have been closed before picking a winning pool.");
		stakingMatch.matchStatus = Status.FINISHED;
		stakingMatch.winningPool = int8(uint8(externalPoolId));
		uint256 realAID = getPoolAID();
		uint256 realBID = getPoolBID();
		uint256 poolAStake = stakingMatch.poolStakedTokens[realAID];
		uint256 poolBStake = stakingMatch.poolStakedTokens[realBID];

		stakingMatch.totalPrize = externalPoolId == 0 ? poolBStake : poolAStake;
		stakingMatch.winningPoolTokens = externalPoolId == 0 ? poolAStake : poolBStake;

		emit WinningPool(externalPoolId);
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
		uint256 realAID = getPoolAID();
		uint256 realBID = getPoolBID();
		uint256 poolAStake = stakingMatch.poolStakedTokens[realAID];
		uint256 poolBStake = stakingMatch.poolStakedTokens[realBID];
		return poolAStake + poolBStake;
	}

	function getPoolAStakedTokens() external view returns (uint256) {
		uint256 poolAID = getPoolAID();
		return stakingMatch.poolStakedTokens[poolAID];
	}

	function getPoolBStakedTokens() external view returns (uint256) {
		uint256 poolBID = getPoolBID();
		return stakingMatch.poolStakedTokens[poolBID];
	}

	function getUserStakedTokens(address user, uint256 externalPoolId) public view returns (uint256) {
		uint256 realPoolId = getRealPoolID(externalPoolId);
		return stakingMatch.poolStakes[realPoolId][user];
	}

	function isStakingEnabled() external view returns (bool) {
		return stakingMatch.stakingEnabled;
	}

	function getCurrentStakingStatus() public view returns (Status) {
		return stakingMatch.matchStatus;
	}

	function getTotalPrize() external view returns (uint256) {
		return stakingMatch.totalPrize;
	}

	function getWinningPoolTokens() external view returns (uint256) {
		return stakingMatch.winningPoolTokens;
	}

	function getWinningPool() external view returns (int8) {
		return stakingMatch.winningPool;
	}

	function setStakingEnabled(bool enabled) external authorized {
		if (enabled) {
			// Enable staking from either uninitialised state or restarting the stake before a winner is picked.
			require(stakingMatch.matchStatus == Status.INACTIVE, "Staking must be inactive.");
			stakingMatch.stakingEnabled = true;
			stakingMatch.matchStatus = Status.ACTIVE;

			emit StakingOpen();
		} else {
			// Turn staking off in order to decide a winning pool or to temporarily pause the stake process.
			require(stakingMatch.matchStatus == Status.ACTIVE, "Staking must be active.");
			stakingMatch.stakingEnabled = false;
			stakingMatch.matchStatus = Status.INACTIVE;

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
		require(stakingMatch.matchStatus == Status.FINISHED, "Winning bets can only be claimed when a winning pool has been decided.");
		uint256 win = uint256(uint8(stakingMatch.winningPool));
		require(win == 0 || win == 1, "Winning pool is not correctly set!");
		uint256 stakedTokens = getUserStakedTokens(staker, win);
		require(stakedTokens > 0, "No stake on winning pool.");
		uint256 prize = getUserPrize(staker);
		require(prize > 0, "No prize to claim.");
		uint256 toGive = prize + stakedTokens;

		// Reset staking for user.
		uint256 realPoolId = getRealPoolID(win);
		stakingMatch.poolStakes[realPoolId][staker] = 0;
		stakingMatch.poolStakedTokens[realPoolId] -= stakedTokens;
		if (stakingMatch.poolStakedTokens[realPoolId] == 0) {
			stakingMatch.matchStatus = Status.CLEARED;
		}

		IERC20(stakingToken).transfer(staker, toGive);
	}

	function resetStaking() external authorized {
		require(
			stakingMatch.matchStatus == Status.CLEARED || getTotalStakedTokens() == 0,
			"New staking can only be started when previous one is cleared."
		);
		stakingMatch.winningPool = -1;
		stakingMatch.matchStatus = Status.INACTIVE;
		stakingMatch.iteration += 1;
		stakingMatch.stakingEnabled = false;
		stakingMatch.totalPrize = 0;
		stakingMatch.winningPoolTokens = 0;

		emit NewStakingPools();
	}

	/**
	 * @dev Gets the price for a specific staker.
	 */
	function getUserPrize(address staker) public view returns (uint256) {
		uint256 stakedTokens;
		uint256 realPoolID;
		int8 win = stakingMatch.winningPool;

		// Wrongly set winning pool.
		if (win < 0 || win > 1) {
			return 0;
		}

		// Winner is pool A.
		if (win == 0) {
			realPoolID = getPoolAID();
		} else {
			// Winner is pool B.
			realPoolID = getPoolBID();
		}
		stakedTokens = stakingMatch.poolStakes[realPoolID][staker];
		if (stakedTokens > 0) {
			return calculatePrize(stakedTokens, stakingMatch.winningPoolTokens, stakingMatch.totalPrize);
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
		require(stakingMatch.matchStatus == Status.CLEARED, "Requires all prizes to have been given out.");
		IERC20 st = IERC20(stakingToken);
		st.transfer(feeReceiver, st.balanceOf(address(this)));
	}

	/**
	 * @dev Internal pool IDs. Public IDs are always 0 for A and 1 for B.
	 */
	function getPoolAID() public view returns (uint256) {
		return stakingMatch.iteration * 2 - 1;
	}

	function getPoolBID() public view returns (uint256) {
		return stakingMatch.iteration * 2;
	}

	function getCurrentIteration() external view returns (uint256) {
		return stakingMatch.iteration;
	}
}