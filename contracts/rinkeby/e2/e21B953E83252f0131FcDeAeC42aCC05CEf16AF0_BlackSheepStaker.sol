// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract BlackSheepStaker {
	using SafeMath for uint256;

	uint256 public REFERRAL_FEE = 100;
	uint256 public DEPOSIT_FEE = 10;
	uint256 public WITHDRAW_FEE = 30;
	uint256 public PERCENTS_DIVIDER = 1000;
    uint256 public ROI = 15;
    uint256 public LOCK_TIME = 30 seconds;
	
	uint256 public totalStaked;

	struct Deposit {
		uint256 lockedAmount;
		uint256 releasedAmount;
		uint256 reward;
		uint256 timestamp;
		uint256 lastCheckPoint;
	}

	struct User {
		Deposit deposit;
		address referrer;
		uint256 referralBonus;
		uint256 referralCount;
	}

	mapping (address => User) internal users;

    IBEP20 token;

	constructor(address _tokenAddress) {
        token = IBEP20(_tokenAddress);
	}

	function calcReleaseAmount() private {
		User storage user = users[msg.sender];
		if(user.deposit.releasedAmount > 0 && user.deposit.lastCheckPoint > 0) {
			uint256 reward;
			uint256 timeDiff = block.timestamp - user.deposit.lastCheckPoint;
			reward = user.deposit.releasedAmount.mul(ROI).div(PERCENTS_DIVIDER);
			// reward = reward.mul(timeDiff).div(3600 * 24);
			reward = reward.mul(timeDiff);
			user.deposit.reward += reward;
			user.deposit.lastCheckPoint = block.timestamp;
		}
		if(block.timestamp - user.deposit.timestamp >= LOCK_TIME && user.deposit.timestamp > 0) {
			uint256 reward;
			uint256 timeDiff = block.timestamp - user.deposit.timestamp - LOCK_TIME;
			reward = user.deposit.lockedAmount.mul(ROI).div(PERCENTS_DIVIDER);
			// reward = reward.mul(timeDiff).div(3600 * 24);
			reward = reward.mul(timeDiff);
			user.deposit.reward += reward;

			user.deposit.releasedAmount += user.deposit.lockedAmount;
			user.deposit.lockedAmount = 0;
			user.deposit.timestamp = block.timestamp;
			user.deposit.lastCheckPoint = block.timestamp;
		}
	}

	function invest(address referrer, uint256 amount) public {
		token.transferFrom(msg.sender, address(this), amount);
		totalStaked = totalStaked.add(amount);

		User storage user = users[msg.sender];

		if (user.referrer == address(0)) {
			if (users[referrer].deposit.releasedAmount > 0 || users[referrer].deposit.lockedAmount > 0) {
				if (referrer != msg.sender && referrer != address(0)) {
					user.referrer = referrer;
					uint256 referralFee = amount.mul(REFERRAL_FEE).div(PERCENTS_DIVIDER);
					users[referrer].referralBonus += referralFee;
					users[referrer].referralCount += 1;
					amount = amount.sub(referralFee);
				}
			}
		}
		uint256 fee = amount.mul(DEPOSIT_FEE).div(PERCENTS_DIVIDER);
		amount = amount.sub(fee);

		calcReleaseAmount();

		user.deposit.lockedAmount += amount;
		user.deposit.timestamp = block.timestamp;
	}

	function withdraw() public {
		User storage user = users[msg.sender];
		calcReleaseAmount();
		require(user.deposit.releasedAmount > 0, "You can't withdraw funds for 14 days.");

		uint256 withdrawAmount = user.deposit.releasedAmount;
		uint256 contractBalance = token.balanceOf(address(this));
		if (contractBalance < withdrawAmount) {
			withdrawAmount = contractBalance;
		}
		user.deposit.releasedAmount -= withdrawAmount;

		uint256 fees = withdrawAmount.mul(WITHDRAW_FEE).div(PERCENTS_DIVIDER);
		withdrawAmount = withdrawAmount.sub(fees);
		totalStaked -= withdrawAmount;

		token.transfer(msg.sender, withdrawAmount);
	}

	function claimReward() public {
		uint256 totalAmount;
		User storage user = users[msg.sender];
		totalAmount = user.deposit.reward + user.referralBonus;

		uint256 contractBalance = token.balanceOf(address(this));
		if (contractBalance < totalAmount) {
			user.deposit.reward = totalAmount - contractBalance;
			user.referralBonus = 0;
			totalAmount = contractBalance;
		}
		else {
			user.deposit.reward = 0;
			user.referralBonus = 0;
		}

		uint256 fees = totalAmount.mul(WITHDRAW_FEE).div(PERCENTS_DIVIDER);
		totalAmount = totalAmount.sub(fees);
		totalStaked -= totalAmount;

		token.transfer(msg.sender, totalAmount);
	}

	function compoundDividends() public {
		calcReleaseAmount();
	}

	function getUserDepositReward(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		return user.deposit.reward;
	}

	function getUserReferralReward(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		return user.referralBonus;
	}

	function getUserDividents(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		return user.deposit.reward + user.referralBonus;
	}

	function getUserReferralCount(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		return user.referralCount;
	}

	function getUserWithdrawableState(address userAddress) public view returns(bool) {
		User storage user = users[userAddress];
		if(user.deposit.releasedAmount > 0 || block.timestamp - user.deposit.timestamp >= LOCK_TIME) {
			return true;
		}
		return false;
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		uint256 totalAmount;
		User storage user = users[userAddress];
		totalAmount = user.deposit.lockedAmount + user.deposit.releasedAmount;
		return totalAmount;
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}


library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}