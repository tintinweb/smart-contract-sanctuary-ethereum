//SPDX-License-Identifier: UNLICENSED

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

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
contract XSeedStake {
	using SafeMath for uint256;
    using SafeMath for uint8;

	uint256 constant public INVEST_MIN_AMOUNT = 0.001 ether; // 0.001 MATIC
	uint256 constant public DEVELOPER_FEE = 5; //5%
    uint256 constant public COMMISSION_FEE = 5; //5%
	uint256 constant public TIME_STEP = 1 days;
	uint256 constant public MAX_ACTIVE_STAKES = 5;
    IERC20 public xseed = IERC20(0xf905d6B4Ce89cfFbC1D18541cAA8BBf24062adDc); //custom rinkby erc20 for testing

	address private owner;

	uint256 public totalStaked;
	uint256 public totalRefBonus;
	uint256 public totalUsers;

    struct Plan {
        uint256 time;
        uint256 stakePercent;
    }

    Plan[] internal plans;

	struct Deposit {
        uint256 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
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
        uint256 lastStake;
        uint256 lastUnstake;
        uint256 expectedEarnings;
	}

	mapping (address => User) public users;
    address[] public userAddresses;

	uint256 public startUNIX;
	address payable private sustenanceCommissionWallet;
	address payable private developerWallet;
	
	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 amount);

	constructor(address payable wallet, address payable _developer) {
		require(!isContract(wallet));
		sustenanceCommissionWallet = wallet;
		developerWallet = _developer;
        startUNIX = block.timestamp.add(365 days);
		
		plans.push(Plan(90, 1000)); //   90 days, 10% profit
        plans.push(Plan(180, 2500)); //  180 days, 25% profit
        plans.push(Plan(270, 5000)); //  270 days, 50% profit
        plans.push(Plan(360, 7500)); //  360 days, 75% profit
        plans.push(Plan(720, 15000)); // 720 days, 150% profit
		owner = msg.sender;
	}

    function launch() public {
        require(msg.sender == developerWallet, "Must be the developer to launch contract!");
		startUNIX = block.timestamp;
    } 

    function invest(address payable referrer, uint8 plan, uint256 amount) public {
        require(!isContract(msg.sender), "Cannot invest from a smart contract!");
        _invest(referrer, plan, payable(msg.sender), amount);
    }

	function _invest(address payable referrer, uint8 _plan, address payable sender, uint256 value) private {
		require(value >= INVEST_MIN_AMOUNT, "Amount must be greater than minimum investment");
        require(_plan >= 0 && _plan < plans.length, "Invalid plan selected");
        require(startUNIX < block.timestamp, "Contract hasn`t started yet");
		require(referrer != sender, "You cannot be your own referrer!");
		User storage user = users[sender];
		if(user.referrer != address(0)) {
			require(user.referrer == referrer, "Referrer wallet cannot be changed once set");
		}
		require(user.activeInvestments < 6, "Cannot have more than 6 active investments!");
        require(xseed.allowance(sender, address(this)) >= value, "Allowance too low" );
		uint256 cfee = value.mul(COMMISSION_FEE).div(100);
		xseed.transferFrom(sender, sustenanceCommissionWallet, cfee);
		uint256 developerFee = value.mul(DEVELOPER_FEE).div(100);
		xseed.transferFrom(sender, developerWallet, developerFee);

		if (user.referrer == address(0)) {
			user.referrer = referrer;
			address upline = user.referrer;
			users[upline].referrals = users[upline].referrals.add(1);
		}
		else {
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
				_refBonus = _refBonus.add(amount);
					
				emit RefBonus(upline, sender, amount);
				upline = users[upline].referrer;
			} 
			totalRefBonus = totalRefBonus.add(_refBonus);
        }

		if (user.deposits.length == 0) {
            userAddresses.push(address(sender));
			totalUsers = totalUsers.add(1);
			emit Newbie(sender);
		}
		(uint256 percent, uint256 profit, uint256 finish) = getResult(_plan, value);
		
		user.totalStaked = user.totalStaked.add(value);
		user.deposits.push(Deposit(_plan, percent, value, profit, block.timestamp, finish,true));
		user.activeInvestments += 1;
		totalStaked = totalStaked.add(value);
        user.lastStake = block.timestamp;
        user.expectedEarnings += profit;
		emit NewDeposit(sender, _plan, percent, value, profit, block.timestamp, finish);
	}

	function withdraw(uint256 depositIndex) public {
		require(depositIndex < users[msg.sender].deposits.length, "Invalid deposit index");
		require(users[msg.sender].deposits[depositIndex].isInvestmentActive, "Already withdrawn");
		uint256 stakedamount = 0;

		stakedamount = getStakeByDeposit(msg.sender, depositIndex);
		uint256 withdrawamount = 0;

        require(users[msg.sender].deposits[depositIndex].finish<=block.timestamp, "Cannot unstake before staking period is over!");
        withdrawamount = stakedamount;

        users[msg.sender].deposits[depositIndex].isInvestmentActive = false;
        users[msg.sender].activeInvestments = users[msg.sender].activeInvestments-1;
		users[msg.sender].withdrawn = users[msg.sender].withdrawn.add(withdrawamount);
        users[msg.sender].expectedEarnings -= withdrawamount;
        users[msg.sender].lastUnstake = block.timestamp;
        xseed.transfer(msg.sender, withdrawamount);
		emit Withdrawn(msg.sender, withdrawamount);
	}

	function bonusClaim() external {
		require(users[msg.sender].totalBonus > 0, "You don't have any referral bonus available");
		uint256 userBonus = users[msg.sender].totalBonus;
		users[msg.sender].totalBonus = 0;
        xseed.transfer(msg.sender, userBonus);
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 stakingPeriod, uint256 stakePercent) {
        require(plan > 0 && plan < plans.length, "Invalid plan!");
		stakingPeriod = plans[plan].time;
		stakePercent = plans[plan].stakePercent;
	}

	function getPercent(uint256 plan) public view returns (uint256) {
        require(plan >= 0 && plan < plans.length, "Invalid plan!");
	    uint256 temp = plans[plan].stakePercent;
		return temp; //divide result by hundred to get total daily % profit	
    }
    
	function getResult(uint256 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
        require(plan >= 0 && plan < plans.length, "Invalid plan!");
		percent = getPercent(plan);
		profit = deposit + deposit.mul(percent).div(10000);
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

	function getTotalActiveStaked(address userAddress) public view returns (uint256) {
		uint256 stakeBalance = 0;
		uint256[] memory userDeposits = getActiveDeposits(userAddress);

		for(uint256 i=0; i<userDeposits.length; i++) {
			stakeBalance = stakeBalance.add(getStakeByDeposit(userAddress, userDeposits[i]));
		}

		return stakeBalance;
	}

	function getStakeByDeposit(address userAddress, uint256 depositIndex) public view returns(uint256) {
		User storage user = users[userAddress];
		require(depositIndex < user.deposits.length, "Invalid deposit index!");
		require(user.deposits[depositIndex].isInvestmentActive, "Investment not active in that deposit");
		Deposit storage userDeposit = user.deposits[depositIndex];
		uint256 stakeBalance = 0;
        if( user.deposits[depositIndex].finish <= block.timestamp ) {
            stakeBalance = userDeposit.profit;
        }
		return stakeBalance;
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

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish, bool isInvestmentActive) {
	    User memory user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
		isInvestmentActive = user.deposits[index].isInvestmentActive;
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}