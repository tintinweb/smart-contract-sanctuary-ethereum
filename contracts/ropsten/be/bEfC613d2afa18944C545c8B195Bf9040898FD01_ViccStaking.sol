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

    uint256 constant public PERCENTS_DIVIDER = 100;
	uint256 constant public DAILY_ROI = 15;
    uint256 constant public REFERRAL_PERCENTS = 12; // 12%
    uint256 constant public TIME_STEP = 1 days;
    uint256 constant public MIN_STAKE_AMOUNT = 1000 * (10**18);
	
	ERC20Interface VictoryCoin;

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        uint256 bonus;
        address referrer;
        uint256 referralCount;
    }

    mapping (address => User) internal users;

    modifier onlyhodler() {
        require(getUserDividends(msg.sender) > 0, "Not Holder");
        _;
    }

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event onReinvestment(address indexed user, uint256 reinvestAmount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 amount);

    constructor(address _VictoryCoin) {
        VictoryCoin = ERC20Interface(_VictoryCoin);
    }

    receive() external payable {}

    function invest(address referrer, uint256 amount) public {
		VictoryCoin.transferFrom(msg.sender, address(this), amount);
		
        User storage user = users[msg.sender];

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
			if (upline != address(0)) {
				uint256 _amount = amount.mul(REFERRAL_PERCENTS).div(PERCENTS_DIVIDER);
				users[upline].bonus = users[upline].bonus.add(_amount);
                users[upline].referralCount.add(1);
				emit RefBonus(upline, msg.sender, _amount);
			}
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            totalUsers = totalUsers.add(1);
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(amount, 0, block.timestamp));

        totalInvested = totalInvested.add(amount);
        totalDeposits = totalDeposits.add(1);

        emit NewDeposit(msg.sender, amount);
    }

    function withdraw() public {
        User storage user = users[msg.sender];

        uint256 totalAmount;
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
                totalAmount = totalAmount.add(dividends);
            }
        }

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            totalAmount = totalAmount.add(referralBonus);
            user.bonus = 0;
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = VictoryCoin.balanceOf(address(this));
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;
		
		VictoryCoin.transfer(msg.sender, totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
    }

    function reinvest() onlyhodler() public
    {
        User storage user = users[msg.sender];
        // fetch dividends
        uint256 _dividends = getUserDividends(msg.sender); // retrieve ref. bonus later in the code
        uint256 totalAmount;
        uint256 dividends;

        user.deposits.push(Deposit(_dividends, 0, block.timestamp));

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
                totalAmount = totalAmount.add(dividends);
            }
        }

        user.checkpoint = block.timestamp;

        totalInvested = totalInvested.add(_dividends);
        totalDeposits = totalDeposits.add(1);
        totalWithdrawn = totalWithdrawn.add(totalAmount);
        // fire event
        emit onReinvestment(msg.sender, _dividends);
    }


    function getUserDividends(address userAddress) public view returns (uint256) {
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

    function minimumStakeValue() public view returns(uint256) {
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
        return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        if (user.deposits.length > 0) {
            if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(365).div(100)) {
                return true;
            }
        }
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