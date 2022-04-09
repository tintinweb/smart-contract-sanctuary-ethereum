//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0 <0.9.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
contract MATICALPHA {
	using SafeMath for uint256;
    using SafeMath for uint8;

	uint256 constant public INVEST_MIN_AMOUNT = 10; // 10 MATIC
	uint256 constant public DEVELOPER_FEE = 5; //5%
    uint256 constant public commission_FEE = 5; //5%
	uint256 constant public PERCENT_STEP = 5;
	uint256 constant public TIME_STEP = 1 days;
	
	uint256 constant public MAX_HOLD_PERCENT = 15;

	address private owner;

	uint256 WITHDRAW_FEE_1 = 100; //10%
	uint256 WITHDRAW_FEE_2 = 150; //15%

	uint256 public totalStaked;
	uint256 public totalRefBonus;
	uint256 public totalUsers;

    struct Plan {
        uint256 time;
        uint256 stakePercent;
        uint256 holderPercent;
        uint256 reinvestmentbonus;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
		uint256	stackedbalance;
		uint256	holdbalance;
		uint256 holdwithdrawn;
		uint256 planWithdrawn;
		bool elegible;
		// bool withdrawn;
	}

	struct User {
		Deposit[] deposits;
		// uint256 checkpoint;
		// uint256 holdBonusCheckpoint;
		address payable referrer;
		uint256 referrals;
		uint256 totalBonus;
		uint256 withdrawn;
		uint256 totalStaked;
	}

	mapping (address => User) public users;

	uint256 public startUNIX;
	address payable private commissionWallet;
	address payable private developerWallet;
	
	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 amount);

	constructor(address payable wallet, address payable _developer) {
		require(!isContract(wallet));
		commissionWallet = wallet;
		developerWallet = _developer;
        startUNIX = block.timestamp.add(365 days);
		
		plans.push(Plan(7, 1500, 71, 0)); //  7 days
        plans.push(Plan(14, 821, 107, 310)); //  14 days
        plans.push(Plan(21, 583, 143, 420)); //  21 days
        plans.push(Plan(28, 464, 179, 530)); //  28 days
        plans.push(Plan(35, 393, 214, 640)); //  35 days
		owner = msg.sender;
	}

    function launch() public {
        require(msg.sender == developerWallet);
		startUNIX = block.timestamp;
    } 

    function invest(address payable referrer, uint8 plan) public payable {
        _invest(referrer, plan, payable(msg.sender), msg.value);
    }

	function _invest(address payable referrer, uint8 _plan, address payable sender, uint256 value) private {
		require(value >= INVEST_MIN_AMOUNT, "Amount must be greater than minimum investment");
        require(_plan < 5, "Invalid plan selected");
        require(startUNIX < block.timestamp, "Contract hasn`t started yet");
		User storage user = users[sender];
		if(user.referrer != address(0)) {
			require(user.referrer == referrer, "Referrer wallet cannot be changed once set");
		}
		require(referrer != sender, "You cannot be your own referrer!");
		uint256 cfee = value.mul(commission_FEE).div(100);
		commissionWallet.transfer(cfee);
		uint256 developerFee = value.mul(DEVELOPER_FEE).div(100);
		developerWallet.transfer(developerFee);

		if (user.referrer == address(0)) {
			//require(users[referrer].deposits.length > 0, "Invalid referrer address - not registered.");
			// require(referrer != sender, "You cannot be your own referrer!");
			user.referrer = referrer;
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					users[upline].referrals = users[upline].referrals.add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}
		if (user.referrer != address(0)) {
			User storage referrerUser = users[referrer];
			uint256 _refBonus = 0;
			address payable upline = user.referrer;
			if (upline != address(0)) {	
                uint256 REFERRAL_PERCENTS = 0;
                if(referrerUser.referrals<11){
                    REFERRAL_PERCENTS = 200;
                }else if(referrerUser.referrals<31){
                    REFERRAL_PERCENTS = 300;
                }else if(referrerUser.referrals<51){
                    REFERRAL_PERCENTS = 500;
                }else if(referrerUser.referrals<71){
                    REFERRAL_PERCENTS = 700;
                }else if(referrerUser.referrals<100){
                    REFERRAL_PERCENTS = 1000;
                }else if(user.referrals>=100){
                    REFERRAL_PERCENTS = 2000;
                }
                uint256 amount = value.mul(REFERRAL_PERCENTS).div(10000);
							
				users[upline].totalBonus = users[upline].totalBonus.add(amount);
				upline.transfer(amount);
				_refBonus = _refBonus.add(amount);
					
				emit RefBonus(upline, sender, amount);
				upline = users[upline].referrer;
				} 
			totalRefBonus = totalRefBonus.add(_refBonus);
        }

		if (user.deposits.length == 0) {
			emit Newbie(sender);
		}
		uint256 s = plans[_plan].stakePercent.mul(value).div(10000);
		uint256 h = plans[_plan].holderPercent.mul(value).div(10000);
		(uint256 percent, uint256 profit, uint256 finish) = getResult(_plan, value);
		
		user.totalStaked = user.totalStaked.add(value);
		user.deposits.push(Deposit(_plan, percent, value, profit, block.timestamp, finish,s,h,0,0,true));
		//user.referrals++;
		totalStaked = totalStaked.add(value);
        totalUsers = totalUsers.add(1);
		emit NewDeposit(sender, _plan, percent, value, profit, block.timestamp, finish);
	}

    function reinvest(uint8 plan) payable public {
        _reinvest( plan, payable(msg.sender), msg.value);
    }

	function _reinvest( uint8 _plan, address payable sender, uint256 value) private {
		require(value >= INVEST_MIN_AMOUNT);
        require(_plan < 5, "Invalid plan");
        require(startUNIX < block.timestamp, "contract hasn`t started yet");
		User storage user = users[sender];
		require(canUserReinvest(sender, _plan));

		uint256 cfee = value.mul(commission_FEE).div(100);
		commissionWallet.transfer(cfee);
		uint256 developerFee = value.mul(DEVELOPER_FEE).div(100);
		developerWallet.transfer(developerFee);
		
        uint256 reinvestmentbonus = value.add(plans[_plan].reinvestmentbonus.mul(value).div(10000));
		sender.transfer(reinvestmentbonus);
		
		// uint256 s = plans[_plan].stakePercent.mul(value).div(10000);
		// uint256 h = plans[_plan].holderPercent.mul(value).div(10000);
		(uint256 percent, uint256 _profit, uint256 _finish) = getResult(_plan, value);
		for(uint256 i=0; i<user.deposits.length; i++) {
			if(user.deposits[i].plan == _plan && user.deposits[i].finish > block.timestamp) {
				user.deposits[i].amount = user.deposits[i].amount.add(value);
				user.deposits[i].profit = user.deposits[i].profit.add(_profit);
				user.deposits[i].finish = _finish;
				break;
			}
		}
		// user.deposits.push(Deposit(_plan, percent, value, profit, block.timestamp, finish,s,h,true, false));
		user.totalStaked.add(value);
		totalStaked = totalStaked.add(value);
        totalUsers = totalUsers.add(1);
		emit NewDeposit(sender, _plan, percent, value, _profit, block.timestamp, _finish);
	}

	// // call this function to update rewards daily for each user
	// function updateDailyRewards(address _user) public{
	// 		require(msg.sender==owner);
	// 		for(uint8 i=0;i<users[_user].deposits.length;i++){
    //             if(users[msg.sender].deposits[i].finish>=block.timestamp){
    //                 users[_user].deposits[i].stackedbalance += plans[users[_user].deposits[i].plan].stakePercent.mul(users[_user].deposits[i].amount).div(10000);
	// 			    users[_user].deposits[i].holdbalance += plans[users[_user].deposits[i].plan].holderPercent.mul(users[_user].deposits[i].amount).div(10000);
    //             }
	// 		}
	// }

	function withdrawall(uint _type) public {
		uint256 _sbalance = 0;
		uint256 _hbalance = 0;
		uint256 withdrawamount = 0;
		// getting total stacked and hold amount till now of plan
		for(uint8 i=0;i<users[msg.sender].deposits.length;i++) {
			// if(users[msg.sender].deposits[i].withdrawn == false) {
			// uint256 planTime = plans[users[msg.sender].deposits[i].plan].time.mul(TIME_STEP); //plan time in days
			// uint256 numberOfDaysPassed = (block.timestamp - planTime).div(TIME_STEP);
			if(_type==1) {
				_sbalance += getUserPlanBalance(msg.sender, users[msg.sender].deposits[i].plan);
				users[msg.sender].deposits[i].planWithdrawn += getUserPlanBalance(msg.sender, users[msg.sender].deposits[i].plan);
				users[msg.sender].deposits[i].stackedbalance = 0;
			}
			if(users[msg.sender].deposits[i].elegible){
				if(_type==2) {
					_hbalance += getUserHoldBalance(msg.sender, users[msg.sender].deposits[i].plan);
					users[msg.sender].deposits[i].holdwithdrawn += getUserHoldBalance(msg.sender, users[msg.sender].deposits[i].plan);
					users[msg.sender].deposits[i].holdbalance = 0;
				}
			}
			if(_type == 2 && users[msg.sender].deposits[i].finish > block.timestamp){
				users[msg.sender].deposits[i].elegible = false;
			}
			// }
		}

		withdrawamount = _sbalance+_hbalance;
		uint256 contractBalance = address(this).balance;
		require(contractBalance>=withdrawamount,"Contract dont have required fee to pay");

		users[msg.sender].withdrawn = users[msg.sender].withdrawn.add(withdrawamount);
		payable(msg.sender).transfer(withdrawamount);
		emit Withdrawn(msg.sender, withdrawamount);
	}

	function withdraw(uint8 _plan, uint8 _type) public {
		require(_plan < 5, "Invalid plan");
		require(_type < 3, "Invalid type");
		uint256 stackedamount = 0;
		uint256 holdamount = 0;
		// uint256 prevHoldWithdrawn = 0;
		uint depositindex=0;
		// uint256 planTime = plans[_plan].time; //plan time in days
		// uint256 numberOfDaysPassed = (block.timestamp - planTime).div(TIME_STEP);
		// getting total stacked and hold amount till now of plan
		for(uint256 i=0;i<users[msg.sender].deposits.length;i++){
			if(users[msg.sender].deposits[i].plan==_plan) {
				// if(users[msg.sender].deposits[i].withdrawn == false) {
					// stackedamount = users[msg.sender].deposits[i].stackedbalance;
					// holdamount = users[msg.sender].deposits[i].holdbalance;
				stackedamount = getUserPlanBalance(msg.sender, _plan);
				holdamount = getUserHoldBalance(msg.sender, _plan);
				depositindex = i;
				// if(_type == 1 && users[msg.sender].deposits[i].finish > block.timestamp) {
				// 	users[msg.sender].deposits[i].elegible = false;
				// }
				break;
				// }
			}
		}

		// uint256 sb = users[msg.sender].deposits[depositindex].stackedbalance;
		// uint256 hb = users[msg.sender].deposits[depositindex].holdbalance;
		uint256 sb = stackedamount;
		uint256 hb = holdamount;
		uint256 withdrawamount = 0;
		
		if(_type == 1){ // 1 for withdraw plan balance
			require(stackedamount>0,"available stacked amount is less");
			withdrawamount = sb;
			users[msg.sender].deposits[depositindex].stackedbalance -= 0;
			// users[msg.sender].deposits[depositindex].withdrawn = true;
			if(users[msg.sender].deposits[depositindex].finish>block.timestamp){
				users[msg.sender].deposits[depositindex].elegible=false;
			}
		}else if(_type == 2){// 2 for withdraw hold balance
			require(holdamount>0,"available hold amount is less");
			require(users[msg.sender].deposits[depositindex].elegible==true,"User is not elegible for hold bonus");
			withdrawamount = hb;
			users[msg.sender].deposits[depositindex].holdbalance -= 0;	
			// users[msg.sender].deposits[depositindex].withdrawn = true;		
		}else{
			revert("wrong withdrawal type selection");
		}
		users[msg.sender].withdrawn = users[msg.sender].withdrawn.add(withdrawamount);
		payable(msg.sender).transfer(withdrawamount);
		emit Withdrawn(msg.sender, withdrawamount);
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 spercent, uint256 hpercent) {
		time = plans[plan].time;
		spercent = plans[plan].stakePercent;
        hpercent = plans[plan].holderPercent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
	    uint256 temp = plans[plan].stakePercent+plans[plan].holderPercent;
		return temp; //divide result by hundred to get total daily % profit	
    }
    
	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);
		profit = deposit.mul(percent).mul(plans[plan].time).div(10000);
		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}
	
	// function getUserAvailable(address userAddress, uint256 _plan) public view returns (uint256 planBalance, uint256 holdBalance) {
	// 	require(_plan < 5, "Invalid plan selected");
	// 	User storage user = users[userAddress];
		
	// 	for (uint256 i = 0; i < user.deposits.length; i++) {
	// 		if (users[msg.sender].deposits[i].withdrawn == false) {
	// 			uint256 planTime = plans[users[msg.sender].deposits[i].plan].time; //plan time in days
	// 			uint256 numberOfDaysPassed = (block.timestamp - planTime).div(TIME_STEP);
	// 			planBalance = planBalance.add(plans[user.deposits[i].plan].stakePercent.mul(user.deposits[i].amount).div(10000)*numberOfDaysPassed);
	// 			holdBalance = holdBalance.add(plans[user.deposits[i].plan].holderPercent.mul(user.deposits[i].amount).div(10000)*numberOfDaysPassed);
	// 		}
	// 	}
	// }

	function getUserPlanBalance(address userAddress, uint256 _plan) public view returns (uint256) {
		require(_plan < 5, "Invalid plan selected");
		User storage user = users[userAddress];
		uint256 planBalance = 0;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].plan == _plan) {
				uint256 planTime = plans[user.deposits[i].plan].time.mul(TIME_STEP); //plan time in days
				uint256 numberOfDaysPassed = (block.timestamp - planTime).div(TIME_STEP);
				planBalance = plans[user.deposits[i].plan].stakePercent.mul(user.deposits[i].amount).mul(numberOfDaysPassed).sub(user.deposits[i].planWithdrawn).div(10000);
				break;
			}
		}
		return planBalance;	
	}

	function getUserHoldBalance(address userAddress, uint256 _plan) public view returns (uint256) {
		require(_plan < 5, "Invalid plan selected");
		User storage user = users[userAddress];
		uint256 holdBalance = 0;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].plan == _plan && user.deposits[i].elegible) {
				uint256 planTime = plans[user.deposits[i].plan].time.mul(TIME_STEP); //plan time in days
				uint256 numberOfDaysPassed = (block.timestamp - planTime).div(TIME_STEP);
				holdBalance = plans[user.deposits[i].plan].holderPercent.mul(user.deposits[i].amount).mul(numberOfDaysPassed).sub(user.deposits[i].holdwithdrawn).div(10000);
				break;
			}
		}
		return holdBalance;	
	}

    function getContractInfo() public view returns(uint256, uint256, uint256) {
        return(totalStaked, totalRefBonus, totalUsers);
    }

	function getUserWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].withdrawn;
	}

	// function getUserCheckpoint(address userAddress) public view returns(uint256) {
	// 	return users[userAddress].checkpoint;
	// }
    
	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	} 

	function getUserDownlineCount(address userAddress) public view returns(uint256) {
		return (users[userAddress].referrals);
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}


	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserTotalStaked(address userAddress) public view returns(uint256) {
		return users[userAddress].totalStaked;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256 amount) {
		
	}

	function getUserReferrals(address userAddress) public view returns(uint256 amount) {
		return users[userAddress].referrals;
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
	}

	function canUserReinvest(address _user, uint256 _plan) internal view returns (bool) {
		User storage user = users[_user];

		for(uint256 i=0; i<user.deposits.length; i++) {
			if(user.deposits[i].plan == _plan && block.timestamp > user.deposits[i].finish) {
				return true;
			}
		}

		return false;
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}