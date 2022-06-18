// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
/**
 *Submitted for verification at BscScan.com on 2022-05-10
*/

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

abstract contract ERC20Interface {
    function burn(uint256 amount) 
        public
        virtual;
    function totalSupply() 
		public 
		virtual 
		returns (uint256);

    function balanceOf(address tokenOwner) 
		public 
		virtual 
		returns (uint256 balance);
    
	function allowance
		(address tokenOwner, address spender) 
		public 
		virtual 
		returns (uint256 remaining);

    function transfer(address to, uint256 tokens) public virtual
		returns (bool success);
    
	function approve(address spender, uint256 tokens) public virtual
		returns (bool success);

    function transferFrom 
		(address from, address to, uint256 tokens) public virtual
		returns (bool success);


    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract Ownable {

  // Owner of the contract
  address payable public owner;
  address payable internal _newOwner;

    constructor() {
        owner = payable(address(msg.sender));
    }

  /**
  * @dev Event to show ownership has been transferred
  * @param previousOwner representing the address of the previous owner
  * @param newOwner representing the address of the new owner
  */
  event OwnershipTransferred(address previousOwner, address newOwner);


  /**
   * @dev Sets a new owner address
   */
  function setOwner(address payable newOwner) internal {
    _newOwner = newOwner;
  }

  /**
  * @dev Throws if called by any account other than the owner.
  */
  modifier onlyOwner() {
    require(msg.sender == owner, "Not Owner");
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address payable newOwner) public onlyOwner {
    require(newOwner != address(0), "Invalid Address");
    setOwner(newOwner);
  }

  //this flow is to prevent transferring ownership to wrong wallet by mistake
  function acceptOwnership() public returns (address){
      require(msg.sender == _newOwner,"Invalid new owner");
      emit OwnershipTransferred(owner, _newOwner);
      owner = _newOwner;
      _newOwner = payable(address(0));
      return owner;
  }
}

contract ViccStaking is Ownable {
    using SafeMath for uint256;

    uint256 constant public PERCENTS_DIVIDER = 10**6;
	uint256 constant public DAILY_ROI = 15000;                  // 1.5%
    uint256 constant public REFERRAL_PERCENTS = 120000;         // 12%
    uint256 constant public FEE_PERCENTS = 60000;               // 6%
    uint256 constant public STAKERS_SHARE_PERCENTS_OF_FEE = 20000;    // 2%
    uint256 constant public BURNNING_PERCENTS = 100000;
    uint256 constant public TIME_STEP = 1 days;
    uint256 constant public MIN_STAKE_AMOUNT = 100 * (10**18);
    uint256 constant public LIMIT_REWARD_PERCENTS = 365000;

    uint256 constant public BACKUP_FOR_FUTURE_REWARD = 2500;
    uint256 constant public BACKUP_FOR_DEVELOPER = 500;
	
	ERC20Interface ViccToken;

    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalWithdrawnForInvested;
    uint256 public totalDeposits;
    uint256 public stakingOpenedAt;

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 invested;
        uint256 withdrawn;
        uint256 checkpoint;
        uint256 bonus;
        uint256 rewardFromFee;
        address referrer;
        uint256 referralCount;
        uint256 sharePercents;
    }

    mapping (address => User) internal users;
    address[] availableUsers;

    modifier onlyValidUser() {
        require(msg.sender != address(0), "Invalid user");
        require(msg.sender != address(this), "Invalid user");
        _;
    }

    modifier onlyHodler() {
        require(users[msg.sender].invested - users[msg.sender].withdrawn > 0, "Not Holder");
        _;
    }

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event onReinvestment(address indexed user, uint256 reinvestAmount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 amount);

    constructor(address _ViccToken) {
        ViccToken = ERC20Interface(_ViccToken);
        stakingOpenedAt = block.timestamp;
    }

    receive() external payable {}

    function _distributeFee(address txSender, uint256 txAmount) internal returns(uint256) {
        uint256 totalFee = txAmount.mul(FEE_PERCENTS).div(PERCENTS_DIVIDER);

        uint256 totalStakerShare = txAmount.mul(STAKERS_SHARE_PERCENTS_OF_FEE).div(PERCENTS_DIVIDER);
        uint256 totalBalanceInvested = totalInvested.sub(totalWithdrawnForInvested);
        if (totalBalanceInvested == 0) {
            return totalFee;
        }
        for (uint256 i = 0; i < availableUsers.length; i++) {
            if (availableUsers[i] == address(0) || availableUsers[i] == txSender) {
                continue;
            }
            uint256 balanceInvested = users[availableUsers[i]].invested.sub(users[availableUsers[i]].withdrawn);
            if (balanceInvested < MIN_STAKE_AMOUNT) {
                continue;
            }
            users[availableUsers[i]].sharePercents = balanceInvested.mul(PERCENTS_DIVIDER).div(totalBalanceInvested);
            users[availableUsers[i]].rewardFromFee.add(users[availableUsers[i]].sharePercents.mul(totalStakerShare));
        }
        return totalFee;
    }

    function invest(address referrer, uint256 amount) onlyValidUser public {
        require(amount > MIN_STAKE_AMOUNT, "Too small invested");
		ViccToken.transferFrom(msg.sender, address(this), amount);

        User storage user = users[msg.sender];
        user.invested.add(amount);

        uint256 fee = _distributeFee(msg.sender, amount);

        uint256 realInvestingAmount = amount.sub(fee);
		

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }

        // Calculate referral bonus for referrer
        if (user.referrer != address(0)) {
            address upline = user.referrer;
			if (upline != address(0)) {
				uint256 _referralBonus = realInvestingAmount.mul(REFERRAL_PERCENTS).div(PERCENTS_DIVIDER);
                realInvestingAmount = realInvestingAmount.sub(_referralBonus);
				users[upline].bonus = users[upline].bonus.add(_referralBonus);
                users[upline].referralCount.add(1);
				emit RefBonus(upline, msg.sender, _referralBonus);
			}
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(realInvestingAmount, 0, block.timestamp));

        availableUsers.push(msg.sender);

        totalInvested = totalInvested.add(realInvestingAmount);
        totalDeposits = totalDeposits.add(1);

        ViccToken.burn(amount.mul(BURNNING_PERCENTS).div(PERCENTS_DIVIDER)); // Burn 10%

        emit NewDeposit(msg.sender, realInvestingAmount);
    }

    function withdraw() public {
        User storage user = users[msg.sender];

        uint256 totalAmount = updateWithdrawns(msg.sender);

        ViccToken.burn(totalAmount.mul(BURNNING_PERCENTS).div(PERCENTS_DIVIDER)); // Burn 10%

        user.withdrawn.add(totalAmount);
        totalWithdrawnForInvested = totalWithdrawnForInvested.add(totalAmount);
        totalAmount = totalAmount.sub(_distributeFee(msg.sender, totalAmount));
        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            totalAmount = totalAmount.add(referralBonus);
            user.bonus = 0;
        }
        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = ViccToken.balanceOf(address(this));
        /*
         * Implementation of 5% for future reward
         */
        uint bkupForFutureReward = 0;
        if (block.timestamp - stakingOpenedAt < 95 days) {
            bkupForFutureReward = BACKUP_FOR_FUTURE_REWARD;
        }
        /*
         * Implementation of 1% for developer
         */
        if (block.timestamp - stakingOpenedAt < 730 days) {
            bkupForFutureReward = bkupForFutureReward.add(BACKUP_FOR_DEVELOPER);
        }
        require(contractBalance - bkupForFutureReward > totalAmount, "Insufficient balance of contract");

        user.checkpoint = block.timestamp;
		
		ViccToken.transfer(msg.sender, totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
    }

    function reinvest() onlyHodler public
    {
        User storage user = users[msg.sender];
        // fetch dividends
        uint256 dividends = updateWithdrawns(msg.sender); // retrieve ref. bonus later in the code

        ViccToken.burn(dividends.mul(BURNNING_PERCENTS).div(PERCENTS_DIVIDER)); // Burn 10%

        dividends = dividends.sub(_distributeFee(msg.sender, dividends));

        user.deposits.push(Deposit(dividends, 0, block.timestamp));

        // updateWithdrawns(msg.sender);

        user.checkpoint = block.timestamp;

        totalInvested = totalInvested.add(dividends);
        totalDeposits = totalDeposits.add(1);
        totalWithdrawn = totalWithdrawn.add(dividends);
        // fire event
        emit onReinvestment(msg.sender, dividends);
    }


    function getSumOfDividends(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(365).div(100)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (user.deposits[i].amount.mul(DAILY_ROI).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (user.deposits[i].amount.mul(DAILY_ROI).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);
                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(365).div(100)) {
                    dividends = (user.deposits[i].amount.mul(365).div(100)).sub(user.deposits[i].withdrawn);
                }
                totalDividends = totalDividends.add(dividends);
            }
        }

        return totalDividends;
    }

    function updateWithdrawns(address userAddress) public returns (uint256) {
        User storage user = users[userAddress];

        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(365).div(100)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (user.deposits[i].amount.mul(DAILY_ROI).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (user.deposits[i].amount.mul(DAILY_ROI).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);
                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(365).div(100)) {
                    dividends = (user.deposits[i].amount.mul(365).div(100)).sub(user.deposits[i].withdrawn);
                }
                user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
                totalDividends = totalDividends.add(dividends);
            }
        }

        return totalDividends;
    }

    function minimumStakeValue() public pure returns(uint256) {
        return MIN_STAKE_AMOUNT;
    }

    function getUserReferralBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].bonus;
    }

    function getUserReferralCount(address referrer) public view returns(uint256) {
        return users[referrer].referralCount;
    }

    function getUserReferrer(address userAddress) public view returns(address) {
        return users[userAddress].referrer;
    }

    function getUserCheckpoint(address userAddress) public view returns(uint256) {
        return users[userAddress].checkpoint;
    }

    function getUserAvailable(address userAddress) public view returns(uint256) {
        return getUserReferralBonus(userAddress).add(getSumOfDividends(userAddress));
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        if (user.deposits.length > 0) {
            if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(365).div(100)) {
                return true;
            }
        }
        return false;
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
        User storage user = users[userAddress];

        return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].withdrawn);
        }

        return amount;
    }
}