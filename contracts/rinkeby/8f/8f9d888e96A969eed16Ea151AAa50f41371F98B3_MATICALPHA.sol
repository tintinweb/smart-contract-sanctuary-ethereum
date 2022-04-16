//SPDX-License-Identifier: UNLICENSED

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

pragma solidity >=0.5.0 <0.9.0;
contract MATICALPHA {
	using SafeMath for uint256;
    using SafeMath for uint8;

	uint256 constant public INVEST_MIN_AMOUNT = 10 ether; // 10 MATIC
	uint256 constant public DEVELOPER_FEE = 5; //5%
    uint256 constant public commission_FEE = 5; //5%
	uint256 constant public PERCENT_STEP = 5;
	uint256 constant public TIME_STEP = 1 days;
	uint256 constant public MAX_ACTIVE_STAKES = 6;
	uint256 constant public MAX_HOLD_PERCENT = 15;

	address private owner;

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
        uint256 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
		uint256	planBalance;
		uint256	holdBalance;
		uint256 holdwithdrawn;
		uint256 planWithdrawn;
		bool eligible;
		bool isInvestmentActive;
	}

	struct User {
		Deposit[] deposits;
		address payable referrer;
		uint256 referrals;
		uint256 totalBonus;
		uint256 withdrawn;
		uint256 totalStaked; 
		uint256 activeInvestments;
	}

	mapping (address => User) public users;

	uint256 public startUNIX;
	address payable private commissionWallet;
	address payable private developerWallet;
	
	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
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
		require(referrer != sender, "You cannot be your own referrer!");
		User storage user = users[sender];
		if(user.referrer != address(0)) {
			require(user.referrer == referrer, "Referrer wallet cannot be changed once set");
		}
		require(user.activeInvestments < 6, "Cannot have more than 6 active investments!");
		uint256 cfee = value.mul(commission_FEE).div(100);
		commissionWallet.transfer(cfee);
		uint256 developerFee = value.mul(DEVELOPER_FEE).div(100);
		developerWallet.transfer(developerFee);

		if (user.referrer == address(0)) {
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
			totalUsers = totalUsers.add(1);
			emit Newbie(sender);
		}
		uint256 s = plans[_plan].stakePercent.mul(plans[_plan].time).mul(value).div(10000);
		uint256 h = plans[_plan].holderPercent.mul(plans[_plan].time).mul(value).div(10000);
		(uint256 percent, uint256 profit, uint256 finish) = getResult(_plan, value);
		
		user.totalStaked = user.totalStaked.add(value);
		user.deposits.push(Deposit(_plan, percent, value, profit, block.timestamp, finish,s,h,0,0,true, true));
		user.activeInvestments += 1;
		totalStaked = totalStaked.add(value);
		emit NewDeposit(sender, _plan, percent, value, profit, block.timestamp, finish);
	}

    function reinvest(uint256 reinvestInPlan, uint256 oldDepositID) public {
        _reinvest( reinvestInPlan, payable(msg.sender), oldDepositID);
    }

	function reinvestAll(uint256 _plan) public {
		uint256[] memory userDeposits = getActiveDeposits(msg.sender);

		User storage user = users[msg.sender];

		require(startUNIX < block.timestamp, "contract hasn`t started yet");
		require(_plan < 5, "Invalid plan");
		// require(user.deposits[depositID].isInvestmentActive, "Cannot reinvest from this deposit");
		require(user.activeInvestments < 6, "Cannot have more than 6 investments");
		Plan memory userPlan = plans[_plan];
		uint256 uplan = _plan;
		uint256 totalDepositBalance;

		for(uint256 depositID=0; depositID<userDeposits.length; depositID++) {

			uint256 userPlanBalance = getPlanBalanceByDeposit(msg.sender, depositID);
			uint256 userHoldBalance = getHoldBalanceByDeposit(msg.sender, depositID);
			totalDepositBalance = totalDepositBalance.add(userPlanBalance.add(userHoldBalance));

			user.deposits[depositID].planWithdrawn += userPlanBalance;
			user.deposits[depositID].holdwithdrawn += userHoldBalance;

			if(user.deposits[depositID].eligible) {
				if(user.deposits[depositID].planWithdrawn + user.deposits[depositID].holdwithdrawn == user.deposits[depositID].profit) {
					user.deposits[depositID].isInvestmentActive = false;
					users[msg.sender].activeInvestments = users[msg.sender].activeInvestments-1;
				}
			}
			else {
				if(user.deposits[depositID].planWithdrawn == user.deposits[depositID].planBalance) {
					user.deposits[depositID].isInvestmentActive = false;
					users[msg.sender].activeInvestments = users[msg.sender].activeInvestments-1;
				}
			}
		}

		uint256 cfee = totalDepositBalance.mul(commission_FEE).div(100);
		payable(commissionWallet).transfer(cfee);
		uint256 developerFee = totalDepositBalance.mul(DEVELOPER_FEE).div(100);
		payable(developerWallet).transfer(developerFee);
		
		uint256 reinvestmentbonus = userPlan.reinvestmentbonus.mul(totalDepositBalance).div(10000);
		payable(msg.sender).transfer(reinvestmentbonus);
		
		uint256 s = userPlan.stakePercent.mul(totalDepositBalance).div(10000);
		uint256 h = userPlan.holderPercent.mul(totalDepositBalance).div(10000);
		(uint256 percent, uint256 _profit, uint256 _finish) = getResult(uplan, totalDepositBalance);
		user.deposits.push(Deposit(uplan, percent, totalDepositBalance, _profit, block.timestamp, _finish,s,h,0,0,true, true));
		user.totalStaked.add(totalDepositBalance);
		user.activeInvestments += 1;
		totalStaked = totalStaked.add(totalDepositBalance);
		// totalUsers = totalUsers.add(1);
		emit NewDeposit(msg.sender, uplan, percent, totalDepositBalance, _profit, block.timestamp, _finish);
		// _reinvest(_plan, payable(msg.sender), userDeposits[i]);
	}

	function _reinvest( uint256 _plan, address payable sender, uint256 depositID) private {
        
	}

	function withdrawall(uint _type) public {
		uint256 _sbalance = 0;
		uint256 _hbalance = 0;
		uint256 withdrawamount = 0;
		for(uint256 i=0;i<users[msg.sender].deposits.length;i++) {
			if(users[msg.sender].deposits[i].isInvestmentActive == true) {
				if(_type==1) {
					_sbalance += getPlanBalanceByDeposit(msg.sender, i);
					users[msg.sender].deposits[i].planWithdrawn += getPlanBalanceByDeposit(msg.sender, i);
					if(block.timestamp > users[msg.sender].deposits[i].finish && !users[msg.sender].deposits[i].eligible) {
						users[msg.sender].deposits[i].isInvestmentActive = false;
						users[msg.sender].activeInvestments = users[msg.sender].activeInvestments-1;
					}
					else if(block.timestamp > users[msg.sender].deposits[i].finish && users[msg.sender].deposits[i].eligible && users[msg.sender].deposits[i].holdwithdrawn == users[msg.sender].deposits[i].holdBalance) {
						users[msg.sender].deposits[i].isInvestmentActive = false;
						users[msg.sender].activeInvestments = users[msg.sender].activeInvestments-1;
					}
				}
				if(users[msg.sender].deposits[i].eligible) {
					if(_type==2) {
						_hbalance += getHoldBalanceByDeposit(msg.sender, i);
						users[msg.sender].deposits[i].holdwithdrawn += getHoldBalanceByDeposit(msg.sender, i);
						if(block.timestamp > users[msg.sender].deposits[i].finish && users[msg.sender].deposits[i].planWithdrawn ==  users[msg.sender].deposits[i].planBalance) {
							users[msg.sender].deposits[i].isInvestmentActive = false;
							users[msg.sender].activeInvestments = users[msg.sender].activeInvestments-1;	
						}
					}
				}
				if(_type == 1 && users[msg.sender].deposits[i].finish > block.timestamp){
					users[msg.sender].deposits[i].eligible = false;
				}
			}
		}

		withdrawamount = _sbalance+_hbalance;
		uint256 contractBalance = address(this).balance;
		require(contractBalance>=withdrawamount,"Contract dont have required fee to pay");

		users[msg.sender].withdrawn = users[msg.sender].withdrawn.add(withdrawamount);
		payable(msg.sender).transfer(withdrawamount);
		emit Withdrawn(msg.sender, withdrawamount);
	}

	function withdraw(uint256 depositIndex, uint8 _type) public {
		require(_type > 0 && _type < 3, "Invalid type");
		require(depositIndex < users[msg.sender].deposits.length, "Invalid deposit index");
		require(users[msg.sender].deposits[depositIndex].isInvestmentActive, "Already withdrawn");
		uint256 stackedamount = 0;
		uint256 holdamount = 0;

		stackedamount = getPlanBalanceByDeposit(msg.sender, depositIndex);
		holdamount = getHoldBalanceByDeposit(msg.sender, depositIndex);
		uint256 sb = stackedamount;
		uint256 hb = holdamount;
		uint256 withdrawamount = 0;
		
		if(_type == 1){ // 1 for withdraw plan balance
			require(stackedamount>0,"available stacked amount is less");
			withdrawamount = sb;
			if(users[msg.sender].deposits[depositIndex].finish>block.timestamp){
				users[msg.sender].deposits[depositIndex].eligible=false;
				withdrawamount = withdrawamount - users[msg.sender].deposits[depositIndex].holdwithdrawn;
			}
			users[msg.sender].deposits[depositIndex].planWithdrawn += stackedamount;
			if(block.timestamp > users[msg.sender].deposits[depositIndex].finish && !users[msg.sender].deposits[depositIndex].eligible) {
				users[msg.sender].deposits[depositIndex].isInvestmentActive = false;
				users[msg.sender].activeInvestments = users[msg.sender].activeInvestments-1;
			}
			else if(block.timestamp > users[msg.sender].deposits[depositIndex].finish && users[msg.sender].deposits[depositIndex].eligible && users[msg.sender].deposits[depositIndex].holdwithdrawn == users[msg.sender].deposits[depositIndex].holdBalance) {
				users[msg.sender].deposits[depositIndex].isInvestmentActive = false;
				users[msg.sender].activeInvestments = users[msg.sender].activeInvestments-1;
			}
		}else if(_type == 2){// 2 for withdraw hold balance
			require(holdamount>0,"available hold amount is less");
			require(users[msg.sender].deposits[depositIndex].eligible==true, "User is not eligible for hold bonus");
			withdrawamount = hb;	
			users[msg.sender].deposits[depositIndex].holdwithdrawn += holdamount;	
			if(block.timestamp > users[msg.sender].deposits[depositIndex].finish && users[msg.sender].deposits[depositIndex].planWithdrawn ==  users[msg.sender].deposits[depositIndex].planBalance) {
				users[msg.sender].deposits[depositIndex].isInvestmentActive = false;
				users[msg.sender].activeInvestments = users[msg.sender].activeInvestments-1;	
			}
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

	function getPercent(uint256 plan) public view returns (uint256) {
	    uint256 temp = plans[plan].stakePercent+plans[plan].holderPercent;
		return temp; //divide result by hundred to get total daily % profit	
    }
    
	function getResult(uint256 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);
		profit = deposit.mul(percent).mul(plans[plan].time).div(10000);
		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}

	function getActiveDeposits(address userAddress) public view returns(uint256[] memory) {
		User memory user = users[userAddress];
		uint256[] memory userDeposits = new uint[](user.activeInvestments);
		uint256 index = 0;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if(user.deposits[i].isInvestmentActive) {
				userDeposits[index] = i;
				index = index + 1;
			}
		}
		return userDeposits;
	}

	function getTotalPlanBalance(address userAddress) public view returns (uint256) {
		uint256 planBalance = 0;
		uint256[] memory userDeposits = getActiveDeposits(userAddress);

		for(uint256 i=0; i<userDeposits.length; i++) {
			planBalance = planBalance.add(getPlanBalanceByDeposit(userAddress, userDeposits[i]));
		}

		return planBalance;
	}

	function getPlanBalanceByDeposit(address userAddress, uint256 depositIndex) public view returns(uint256) {
		User storage user = users[userAddress];
		require(depositIndex < user.deposits.length, "Invalid deposit index!");
		require(user.deposits[depositIndex].isInvestmentActive, "Investment not active in that deposit");
		Deposit storage userDeposit = user.deposits[depositIndex];
		uint256 planBalance = 0;
		uint256 planStart = user.deposits[depositIndex].start; //plan start time
		uint256 currentTime = 0;
		if(user.deposits[depositIndex].finish > block.timestamp) {
			currentTime = block.timestamp;
		}
		else {
			currentTime = user.deposits[depositIndex].finish;
		}
		uint256 numberOfDaysPassed = (currentTime - planStart).div(TIME_STEP);
		planBalance = plans[userDeposit.plan].stakePercent.mul(userDeposit.amount).mul(numberOfDaysPassed).div(10000).sub(userDeposit.planWithdrawn);
		return planBalance;
	}

	function getTotalHoldBalance(address userAddress) public view returns (uint256) {
		uint256 holdBalance = 0;
		uint256[] memory userDeposits = getActiveDeposits(userAddress);

		for(uint256 i=0; i<userDeposits.length; i++) {
			holdBalance = holdBalance.add(getHoldBalanceByDeposit(userAddress, userDeposits[i]));
		}
		return holdBalance;
	}

	function getHoldBalanceByDeposit(address userAddress, uint256 depositIndex) public view returns(uint256) {
		User storage user = users[userAddress];
		require(depositIndex < user.deposits.length, "Invalid deposit index!");
		require(user.deposits[depositIndex].isInvestmentActive, "Investment not active in that deposit");
		if(user.deposits[depositIndex].eligible) {
			uint256 holdBalance = 0;
			Deposit storage userDeposit = user.deposits[depositIndex];
			uint256 planStart = userDeposit.start; //plan start time
			uint256 currentTime = 0;
			if(userDeposit.finish > block.timestamp) {
				currentTime = block.timestamp;
			}
			else {
				currentTime = userDeposit.finish;
			}
			uint256 numberOfDaysPassed = (currentTime - planStart).div(TIME_STEP);
			holdBalance = plans[userDeposit.plan].holderPercent.mul(userDeposit.amount).mul(numberOfDaysPassed).div(10000).sub(userDeposit.holdwithdrawn);
			return holdBalance;
		}
		else return 0;
	}

    function getContractInfo() public view returns(uint256, uint256, uint256) {
        return(totalStaked, totalRefBonus, totalUsers);
    }
    
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

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].withdrawn;
	}

	function getUserReferrals(address userAddress) public view returns(uint256 amount) {
		return users[userAddress].referrals;
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish, uint256 holdwithdrawn, uint256 planWithdrawn, bool eligible, bool isInvestmentActive) {
	    User memory user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
		holdwithdrawn = user.deposits[index].holdwithdrawn;
		planWithdrawn = user.deposits[index].planWithdrawn;
		eligible = user.deposits[index].eligible;
		isInvestmentActive = user.deposits[index].isInvestmentActive;
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}