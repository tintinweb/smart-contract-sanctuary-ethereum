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

contract SRI is Auth {

	struct StakeState {
		uint256 stakedAmount;
		uint32 since;
		uint32 lastUpdate;
	}

	// Staking token and fee receivers.
	address public stakingToken;
	address constant public DEAD = address(0xdead);
	address public devFeeReceiver;
	address public lpFeeReceiver;
	// APR% with 2 decimals.
	uint256 public aprNumerator = 3600;
	uint256 constant public aprDenominator = 10000;
	// Fees in % with 2 decimals.
	uint256 public burnFeeNumerator = 300;
	uint256 constant public burnFeeDenominator = 10000;
	uint256 public devFeeNumerator = 50;
	uint256 constant public devFeeDenominator = 10000;
	uint256 public lpFeeNumerator = 50;
	uint256 constant public lpFeeDenominator = 10000;
	// Staking status.
	uint256 public totalStakedTokens;
	mapping (address => StakeState) internal stakerDetails;

	event TokenStaked(address indexed user, uint256 amount);
	event TokenUnstaked(address indexed user, uint256 amount, uint256 reward);
	event RewardClaimed(address indexed user, uint256 reward);
	event Compounded(address indexed user, uint256 amount);

	constructor(address tokenToStake, address devFee, address lpAddress) Auth(msg.sender) {
		stakingToken = tokenToStake;
		devFeeReceiver = devFee;
		lpFeeReceiver = lpAddress;
	}

	function stake(uint256 amount) external {
		require(amount > 0, "Amount needs to be bigger than 0");

		StakeState storage user = stakerDetails[msg.sender];
		uint32 ts = uint32(block.timestamp);

		// New staking
		if (user.since == 0) {
			user.since = ts;
		} else {
			compoundFor(msg.sender);
		}
		user.lastUpdate = ts;
		user.stakedAmount += amount;
		totalStakedTokens += amount;

		IERC20(stakingToken).transferFrom(msg.sender, address(this), amount);

		emit TokenStaked(msg.sender, amount);
	}

	function unstake(uint256 amount) public {
		require(amount > 0, "Amount needs to be bigger than 0");
		unstakeFor(msg.sender, amount);
	}

	function unstakeAll() external {
		StakeState storage user = stakerDetails[msg.sender];
		require(user.since > 0, "You are not staking.");
		require(user.stakedAmount > 0, "You are not staking.");
		uint256 toUnstake = user.stakedAmount;
		require(toUnstake > 0, "You are not staking.");
		unstakeFor(msg.sender, toUnstake);
	}

	function unstakeFor(address staker, uint256 amount) internal {
		StakeState storage user = stakerDetails[staker];
		require(user.stakedAmount >= amount, "Not enough tokens staked.");

		// Unstaking automatically gives the pending reward.
		uint256 pending = pendingReward(staker);
		uint256 total = amount + pending;
		uint256 burnFee = executeBurnFee(total);
		uint256 devFee = executeDevFee(total);
		uint256 lpFee = executeLPFee(total);
		uint256 toReceive = total - burnFee - devFee - lpFee;
		user.stakedAmount -= amount;
		totalStakedTokens -= amount;
		user.lastUpdate = uint32(block.timestamp);

		IERC20(stakingToken).transfer(staker, toReceive);

		emit TokenUnstaked(staker, toReceive, pending);
	}

	function executeBurnFee(uint256 amount) internal returns (uint256) {
		return executeFee(amount, burnFeeNumerator, burnFeeDenominator, DEAD);
	}

	function executeDevFee(uint256 amount) internal returns (uint256) {
		return executeFee(amount, devFeeNumerator, devFeeDenominator, devFeeReceiver);
	}

	function executeLPFee(uint256 amount) internal returns (uint256) {
		return executeFee(amount, lpFeeNumerator, lpFeeDenominator, lpFeeReceiver);
	}

	function executeFee(uint256 amount, uint256 numerator, uint256 denominator, address receiver) internal returns (uint256) {
		uint256 fee = calcFee(amount, numerator, denominator);
		if (fee > 0) {
			IERC20(stakingToken).transfer(receiver, fee);
			return fee;
		}

		return 0;
	}

	function calcFee(uint256 amount, uint256 num, uint256 den) public pure returns (uint256) {
		if (amount == 0) {
			return 0;
		}
		if (num == 0 || den == 0) {
			return 0;
		}

		return amount * num / den;
	}

	function claim() external {
		StakeState storage user = stakerDetails[msg.sender];
		require(user.since > 0, "You are not staking.");
		uint256 pending = pendingReward(msg.sender);
		if (pending > 0) {
			IERC20(stakingToken).transfer(msg.sender, pending);
			user.lastUpdate = uint32(block.timestamp);

			emit RewardClaimed(msg.sender, pending);
		}
	}

	function compound() external {
		compoundFor(msg.sender);
	}

	function compoundFor(address staker) internal {
		StakeState storage user = stakerDetails[staker];
		uint256 pending = pendingReward(staker);
		if (pending > 0) {
			user.lastUpdate = uint32(block.timestamp);
			user.stakedAmount += pending;
			totalStakedTokens += pending;

			emit Compounded(staker, pending);
		}
	}

	function getPendingReward() external view returns (uint256) {
		return pendingReward(msg.sender);
	}

	/**
	 * @dev Check the current unclaimed pending reward for a user.
	 */
	function pendingReward(address staker) public view returns (uint256) {
		StakeState storage user = stakerDetails[staker];
		// Check if the user ever staked.
		if (user.since == 0) {
			return 0;
		}

		// Should not happen but block.timestamp is not 100% secure.
		if (block.timestamp <= user.lastUpdate) {
			return 0;
		}

		uint256 deltaTime = block.timestamp - user.lastUpdate;
		uint256 annualReward = user.stakedAmount * aprNumerator / aprDenominator;
		return annualReward * deltaTime / 365 days;
	}

	/**
	 * @dev Get the APR values, returns a numerator to divide by a denominator to get the decimal value of the percentage.
	 * Example: 20% can be 2000 / 10000, which is 0.2, the decimal representation of 20%.
	 * @notice APY = (1 + APR / n) ** n - 1;
	 * Where n is the compounding rate (times of compounding in a year)
	 * This is better calculated on a frontend, as Solidity does not do floating point arithmetic.
	 */
	function getAPR() external view returns (uint256 numerator, uint256 denominator) {
		return (aprNumerator, aprDenominator);
	}

	/**
	 * @dev Gets an approximated APR percentage rounded to no decimals.
	 */
	function getAPRRoundedPercentage() external view returns (uint256) {
		return 100 * aprNumerator / aprDenominator;
	}

	/**
	 * @dev Gets an approximated APR percentage rounded to specified decimals.
	 */
	function getAPRPercentage(uint256 desiredDecimals) external view returns (uint256 percentage, uint256 decimals) {
		uint256 factor = 10 ** desiredDecimals;
		uint256 integerPercent = 100 * factor * aprNumerator / aprDenominator;
		return (integerPercent / factor, integerPercent % factor);
	}

	function setDevFeeReceiver(address receiver) external authorized {
		devFeeReceiver = receiver;
	}

	function setLPAddress(address lp) external authorized {
		lpFeeReceiver = lp;
	}

	/**
	 * @dev Sets the unstake burn fee. It is then divided by 10000, so for 1% fee you would set it to 100.
	 */
	function setBurnFeeNumerator(uint256 numerator) external authorized {
		require(numerator + lpFeeNumerator + devFeeNumerator < 3333, "Total fee has to be lower than 33.33%.");
		burnFeeNumerator = numerator;
	}

	function setDevFeeNumerator(uint256 numerator) external authorized {
		require(numerator + lpFeeNumerator + burnFeeNumerator < 3333, "Total fee has to be lower than 33.33%.");
		devFeeNumerator = numerator;
	}

	function setLPFeeNumerator(uint256 numerator) external authorized {
		require(numerator + burnFeeNumerator + devFeeNumerator < 3333, "Total fee has to be lower than 33.33%.");
		lpFeeNumerator = numerator;
	}

	function getStake(address staker) external view returns (StakeState memory) {
		return stakerDetails[staker];
	}

	function availableRewardTokens() external view returns (uint256) {
		uint256 tokens = IERC20(stakingToken).balanceOf(address(this));
		if (tokens <= totalStakedTokens) {
			return 0;
		}
		return tokens - totalStakedTokens;
	}

	function setStakingToken(address newToken) external authorized {
		require(totalStakedTokens == 0, "Cannot change staking token while people are still staking.");
		stakingToken = newToken;
	}

	function forceUnstakeAll(address staker) external authorized {
		StakeState storage user = stakerDetails[staker];
		require(user.since > 0, "User is not staking.");
		require(user.stakedAmount > 0, "User is not staking.");
		uint256 toUnstake = user.stakedAmount;
		require(toUnstake > 0, "User is not staking.");
		unstakeFor(staker, toUnstake);
	}
}