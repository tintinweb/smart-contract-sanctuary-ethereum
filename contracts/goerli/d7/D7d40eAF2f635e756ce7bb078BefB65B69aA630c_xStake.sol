/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// SPDX-License-Identifier: MIT

// xStake
// https://www.xstake.online/

pragma solidity 0.8.17;

interface IERC20 {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function decimals() external view returns (uint8);
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address to, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface DeFiLottery {
  function xStakeLotteryParticipate(uint256 id, address participant, uint256 tickets) external payable;
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    return msg.data;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event ownershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    _setOwner(_msgSender());
  }

  function owner() public view virtual returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Caller must be the owner.");

    _;
  }

  function renounceOwnership() external virtual onlyOwner {
    _setOwner(address(0));
  }

  function transferOwnership(address newOwner) external virtual onlyOwner {
    require(newOwner != address(0), "New owner is now the zero address.");

    _setOwner(newOwner);
  }

  function _setOwner(address newOwner) private {
    address oldOwner = _owner;
    _owner = newOwner;

    emit ownershipTransferred(oldOwner, newOwner);
  }
}

abstract contract ReentrancyGuard is Ownable {
  bool internal locked;

  modifier nonReEntrant() {
    require(!locked, "No re-entrancy.");
    locked = true;
    _;
    locked = false;
  }

  function resetLocked() public onlyOwner {
    locked = false;
  }
}

contract xStake is Context, Ownable, ReentrancyGuard {
  IERC20 private tokenInterface;
  DeFiLottery private lotteryInterface;

  address private tokenContract;
  address private devAddress;
  address private execAddress;
  address private lotteryContract;
  uint256 private lotteryId;
  uint256 private constant lotteryFee = 1;
  address constant burnAddress = 0x000000000000000000000000000000000000dEaD;
  uint256 constant tokenUnit = 1 ether;
  uint256 public constant contractFee = 5;
  uint256 public constant devFee = 4;
  uint256 public constant burnFee = 1;
  uint256 public constant refFee = 5;
  uint256 public constant refMaxUsage = 3;
  uint256 public contractLaunch = 1674237600; // Fri Jan 20 2023 18:00:00 GMT+0000
  uint256 public constant depositMin = 10 * tokenUnit;
  uint256 public constant depositMax = 10000 * tokenUnit;
  uint256 public constant maxPayout = 3;
  uint256 public constant dailyPercent = 3;
  uint256 public constant nextRewardsLevelConsecutiveClaims = 14;
  uint256 public constant nextRewardsLevelReferralsCount = 50;
  uint256 public constant maxRewardsLevel = 6;
  uint256 public constant maxAutoClaims = 28;
  uint256 constant timerWithdrawCompound = 7*2*60; // 7 days;
  uint256 constant timerClaimDailyRewards = 2*60; //1 days;
  uint256 private statsRewards;
  uint256 private statsBurned;
  uint256 private vipMax = 100;
  uint256 private vipAmount = 50 * tokenUnit;
  address[] private vipList;

  struct userDataStruct {
    bool exists;
    address userAddress;
    uint256 timestamp;
    uint256 deposits;
    uint256 deposited;
    uint256 invested;
    uint256 withdrawn;
    uint256 available;
    uint256 autoclaim;
    uint256 autoclaimTotal;
    uint256 autoclaimTimestamp;
    uint256 consecutiveClaims;
    uint256 rewardsLevel;
    int256 score;
    address referred;
    uint256 referredUsage;
    referralDataStruct[] referral;
    timerDataStruct timerWithdrawCompound;
    timerDataStruct timerClaimDailyRewards;
    bool isVIP;
    bool isEarlySupporter;
    refundDataStruct[] refund;
  }

  struct referralDataStruct {
    uint256 timestamp;
    address referralAddress;
    uint256 bonus;
  }

  struct refundDataStruct {
    uint256 timestamp;
    uint256 amount;
  }

  struct timerDataStruct {
    uint256 start;
    uint256 end;
  }

  struct contractBalanceTrendingStruct {
    uint256[] timestamp;
    uint256[] balance;
    int256 trending;
    uint256 rewardsLevel;
  }

  mapping(address => userDataStruct) userData;
  address[] userDataList;

  contractBalanceTrendingStruct contractBalanceTrending;

  modifier isContractStarted {
    require(contractLaunch <= getCurrentTime(), "Contract not yet started.");

    _;
  }

  modifier onlyExecAddress {
    require(msg.sender == address(execAddress), "Not executor address.");

    _;
  }

  event deposited(uint256 timestamp, address indexed addr, uint256 amount);
  event withdrawn(uint256 timestamp, address indexed addr, uint256 amount);
  event refund(uint256 timestamp, address indexed addr, uint256 amount);
  event autoClaim(uint256 timestamp, address indexed addr);
  event vipUser(uint256 timestamp, address indexed addr, uint256 level);
  event lotteryParticipate(uint256 timestamp, address indexed addr, uint256 tickets);
  event lotteryFail(uint256 timestamp, address indexed addr, uint256 tickets, string error);

  constructor(address _tokenContract, address _execAddress, address _devAddress) {
    tokenContract = _tokenContract;
    tokenInterface = IERC20(tokenContract);
    execAddress = _execAddress;
    devAddress = _devAddress;

    contractBalanceTrending.rewardsLevel = 1;
  }

  receive() external payable {}
  fallback() external payable {}

  function getCurrentTime() internal view returns (uint256) {
    return block.timestamp;
  }

  function setContractLaunchTime(uint256 time) external onlyOwner {
    require(time >= getCurrentTime(), "Launch date must be in the future.");

    contractLaunch = time;
    uint256 count = vipList.length;

    if (count > 0) {
      for (uint256 i = 0; i < count; i++) {
        userDataStruct memory data = userData[userDataList[i]];

        if (!data.exists) { continue; }

        userData[vipList[i]].timerClaimDailyRewards = timerDataStruct(contractLaunch, contractLaunch + timerClaimDailyRewards);
        userData[vipList[i]].timerWithdrawCompound = timerDataStruct(contractLaunch, contractLaunch + timerWithdrawCompound);
      }
    }
  }

  function getTokenContract() external view returns (address) {
    return tokenContract;
  }

  function getDevAddress() external view returns (address) {
    return devAddress;
  }

  function setDevAddress(address addr) external onlyOwner {
    devAddress = addr;
  }

  function getExecAddress() external view returns (address) {
    return execAddress;
  }

  function setExecAddress(address addr) external onlyOwner {
    execAddress = addr;
  }

  function getLotteryContract() external view returns (address, uint256 id) {
    return (lotteryContract, lotteryId);
  }

  function setLotteryContract(address addr, uint256 id) external onlyOwner {
    lotteryContract = addr;
    lotteryInterface = DeFiLottery(lotteryContract);
    lotteryId = id;
  }

  function getVIPList() external view returns (address[] memory list) {
    list = vipList;
  }

  function setVIPMax(uint256 max) external onlyOwner {
    require(contractLaunch >= getCurrentTime(), "Contract has already started.");

    vipMax = max;
  }

  function getStats() external view returns (uint256, uint256, int256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
    uint256 balance = getContractBalance();

    return (contractLaunch, balance, contractBalanceTrending.trending, contractBalanceTrending.rewardsLevel, contractFee, devFee, burnFee, refFee, statsRewards, statsBurned, userDataList.length, vipList.length, vipMax);
  }

  function getUserData(address userAddress) public view returns (userDataStruct memory data) {
    require(userData[userAddress].exists, "Unknown user address.");

    data = userData[userAddress];
  }

  function setContractBalanceTrending() internal {
    uint256 balance = getContractBalance();
    uint256[] memory _timestamp = contractBalanceTrending.timestamp;
    uint256[] memory _balance = contractBalanceTrending.balance;
    uint256 count = _balance.length;
    uint256 samples;
    uint256 total;
    uint256 average;

    unchecked {
      if (count > 0) {
        for (uint256 i = count; i > 0; i--) {
          if (_timestamp[i - 1] + 60*60 > getCurrentTime() && samples > 16) { break; }

          total += _balance[i - 1];
          samples++;
        }

        if (samples > 0) { average = total / samples; }
      }

      contractBalanceTrending.timestamp.push(getCurrentTime());
      contractBalanceTrending.balance.push(balance);

      uint256 trending = (balance / tokenUnit) * 100 / (average > 0 ? (average / tokenUnit) : 1);
      contractBalanceTrending.trending = int256(trending) - 100;

      if (contractBalanceTrending.trending <= -30) {
        contractBalanceTrending.rewardsLevel = maxRewardsLevel - 1;
      } else if (contractBalanceTrending.trending <= -20) {
        contractBalanceTrending.rewardsLevel = maxRewardsLevel - 2;
      } else if (contractBalanceTrending.trending <= -10) {
        contractBalanceTrending.rewardsLevel = maxRewardsLevel - 3;
      } else if (contractBalanceTrending.trending <= -5) {
        contractBalanceTrending.rewardsLevel = maxRewardsLevel - 4;
      } else {
        contractBalanceTrending.rewardsLevel = 1;
      }
    }
  }

  function setEarlySupporter(address userAddress, uint256 level) external onlyOwner {
    require(contractLaunch >= getCurrentTime(), "Contract has already started.");
    require(userAddress != owner(), "Owner cannot participate.");

    unchecked {
      require(level <= maxRewardsLevel, "Rewards level exceeded.");

      if (!userData[userAddress].exists) {
        userData[userAddress].exists = true;
        userData[userAddress].isVIP = true;
        userData[userAddress].isEarlySupporter = true;
        userData[userAddress].timestamp = getCurrentTime();
        userData[userAddress].userAddress = msg.sender;
        userData[userAddress].score = 2;

        userDataList.push(userAddress);
        vipList.push(userAddress);
      }

      userData[userAddress].rewardsLevel = level;

      emit vipUser(getCurrentTime(), userAddress, level);
    }
  }

  function removeEarlySupporter(address userAddress) external onlyOwner {
    require(contractLaunch >= getCurrentTime(), "Contract has already started.");
    require(userData[userAddress].exists, "Unknown user address.");
    require(userData[userAddress].isEarlySupporter, "Not an Early Supporter.");

    userData[userAddress].isVIP = false;
    userData[userAddress].isEarlySupporter = false;
    userData[userAddress].rewardsLevel = 1;
  }

  function newVIP() external payable nonReEntrant {
    require(contractLaunch >= getCurrentTime(), "Contract has already started.");
    require(msg.sender != owner(), "Owner cannot participate.");
    require(!userData[msg.sender].exists, "User already exists.");
    require(vipList.length < vipMax, "VIP members exceeded.");

    unchecked {
      require(tokenInterface.balanceOf(msg.sender) >= vipAmount, "Insufficient balance.");
      require(tokenInterface.allowance(msg.sender, address(this)) >= vipAmount, "Insufficient allowance.");

      uint256 devFeeAmount = vipAmount * 90 / 100;
      uint256 contractFeeAmount = vipAmount * 10 / 100;

      bool txDevFee = tokenInterface.transferFrom(msg.sender, devAddress, devFeeAmount);
      require(txDevFee, "Transfer error (devAddress)");

      bool txDeposit = tokenInterface.transferFrom(msg.sender, address(this), contractFeeAmount);
      require(txDeposit, "Transfer error (contractAddress)");

      uint256 level = 3;
      userData[msg.sender].exists = true;
      userData[msg.sender].isVIP = true;
      userData[msg.sender].timestamp = getCurrentTime();
      userData[msg.sender].userAddress = msg.sender;
      userData[msg.sender].rewardsLevel = level;
      userData[msg.sender].score = 2;

      userDataList.push(msg.sender);
      vipList.push(msg.sender);

      emit vipUser(getCurrentTime(), msg.sender, level);
    }
  }

  function newDeposit(uint256 amount, address referralAddress, bool lottery) external payable nonReEntrant {
    require(msg.sender != owner(), "Owner cannot participate.");
    require(tokenInterface.balanceOf(msg.sender) >= amount, "Insufficient balance.");
    require(tokenInterface.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance.");
    require(contractLaunch <= getCurrentTime() || (contractLaunch > getCurrentTime() && userData[msg.sender].exists && userData[msg.sender].isVIP), "Contract net yet started.");

    unchecked {
      uint256 contractFeeAmount = amount * contractFee / 100;
      uint256 devFeeAmount = amount * devFee / 100;
      uint256 burnFeeAmount = amount * burnFee / 100;
      uint256 totalFeeAmount = devFeeAmount + burnFeeAmount;
      uint256 depositAmount = amount - totalFeeAmount;
      uint256 investAmount = depositAmount - contractFeeAmount;

      require(investAmount >= 1 * tokenUnit, "Insufficient deposit amount.");
      require(userData[msg.sender].deposited + investAmount >= depositMin, "Insufficient deposit amount.");
      require(investAmount <= depositMax , "Deposit amount exceeded.");
      require(!userData[msg.sender].exists || (userData[msg.sender].exists && userData[msg.sender].deposited + investAmount <= depositMax), "Deposit amount exceeded.");

      if (devFeeAmount > 0) {
        bool txDevFee = tokenInterface.transferFrom(msg.sender, devAddress, devFeeAmount);
        require(txDevFee, "Transfer error (devAddress)");
      }

      if (burnFeeAmount > 0) {
        bool txBurnFee = tokenInterface.transferFrom(msg.sender, burnAddress, burnFeeAmount);
        require(txBurnFee, "Transfer error (burnAddress)");

        statsBurned += burnFeeAmount;
      }

      bool txDeposit = tokenInterface.transferFrom(msg.sender, address(this), depositAmount);
      require(txDeposit, "Transfer error (contractAddress)");

      if (!userData[msg.sender].exists) {
        userData[msg.sender].exists = true;
        userData[msg.sender].timestamp = getCurrentTime();
        userData[msg.sender].userAddress = msg.sender;
        userData[msg.sender].rewardsLevel = contractBalanceTrending.rewardsLevel;
        userData[msg.sender].score = 2;

        if (userData[msg.sender].refund.length == 0) { userDataList.push(msg.sender); }
      }

      if (contractLaunch <= getCurrentTime()) {
        userData[msg.sender].timerClaimDailyRewards = timerDataStruct(getCurrentTime(), getCurrentTime() + timerClaimDailyRewards);

        if (userData[msg.sender].deposited == 0) { userData[msg.sender].timerWithdrawCompound = timerDataStruct(getCurrentTime(), getCurrentTime() + timerWithdrawCompound); }
      } else {
        userData[msg.sender].timerClaimDailyRewards = timerDataStruct(contractLaunch, contractLaunch + timerClaimDailyRewards);
        userData[msg.sender].timerWithdrawCompound = timerDataStruct(contractLaunch, contractLaunch + timerWithdrawCompound);
      }

      userData[msg.sender].deposits += 1;
      userData[msg.sender].deposited += investAmount;
      userData[msg.sender].invested += investAmount;

      if ((userData[msg.sender].referred != address(0) && userData[msg.sender].referredUsage + 1 <= refMaxUsage) || (userData[msg.sender].referred == address(0) && referralAddress != address(0) && referralAddress != msg.sender && userData[referralAddress].exists && userData[referralAddress].deposits > 0)) {
        if (userData[msg.sender].referred != address(0)) { referralAddress = userData[msg.sender].referred; }

        uint256 refFeeAmount = amount * (refFee / 2) / 100;

        userData[msg.sender].invested += refFeeAmount;
        userData[msg.sender].referredUsage += 1;

        if (userData[referralAddress].deposited > 0) {
          userData[referralAddress].invested += refFeeAmount;
          userData[referralAddress].referral.push(referralDataStruct(getCurrentTime(), msg.sender, refFeeAmount));
        }

        if (userData[msg.sender].referred == address(0)) { userData[msg.sender].referred = referralAddress; }
        if (userData[msg.sender].referral.length >= nextRewardsLevelReferralsCount * userData[msg.sender].rewardsLevel && userData[msg.sender].rewardsLevel + 1 <= maxRewardsLevel) { userData[msg.sender].rewardsLevel += 1; }
      }

      if (lottery && amount >= 100 * tokenUnit) {
        uint256 tickets = uint256(amount / tokenUnit) * lotteryFee / 100;

        if (lotteryContract != address(0)) {
          uint256 lotteryAmount = tickets * tokenUnit;

          if (getContractBalance() >= lotteryAmount) {
            bool txLotteryFee = tokenInterface.transfer(lotteryContract, lotteryAmount);

            if (txLotteryFee) {
              try lotteryInterface.xStakeLotteryParticipate(lotteryId, msg.sender, tickets) {
                userData[msg.sender].deposited -= lotteryAmount;
                userData[msg.sender].invested -= lotteryAmount;

                emit lotteryParticipate(getCurrentTime(), msg.sender, tickets);
              } catch Error(string memory error) {
                emit lotteryFail(getCurrentTime(), msg.sender, tickets, error);
              }
            } else {
              emit lotteryFail(getCurrentTime(), msg.sender, tickets, "Transfer error (lotteryContract).");
            }
          }
        } else {
          emit lotteryFail(getCurrentTime(), msg.sender, tickets, "Lottery contract address not set.");
        }
      }

      emit deposited(getCurrentTime(), msg.sender, amount);

      setContractBalanceTrending();
    }
  }

  function withdrawCompoundRewards(bool compound) external isContractStarted nonReEntrant {
    require(userData[msg.sender].exists, "Unknown user address.");
    require(userData[msg.sender].timerWithdrawCompound.end <= getCurrentTime(), "User cannot yet withdraw rewards. Try again in a few moments.");

    uint256 availableAmount = userData[msg.sender].available;

    require(availableAmount > 0, "No available rewards.");

    unchecked {
      if (compound) {
        userData[msg.sender].invested += availableAmount;
        userData[msg.sender].score++;
      } else {
        require(userData[msg.sender].withdrawn <= userData[msg.sender].deposited * maxPayout, "User has already withdrawn max payout.");

        if (userData[msg.sender].withdrawn + availableAmount > userData[msg.sender].deposited * maxPayout) { availableAmount = userData[msg.sender].deposited * maxPayout - userData[msg.sender].withdrawn; }

        uint256 withdrawPct;
        uint256 reinvestPct;

        if (userData[msg.sender].score < 0) {
          if (userData[msg.sender].score == -2) {
            withdrawPct = 15;
            reinvestPct = 85;
          } else if (userData[msg.sender].score == -1) {
            withdrawPct = 30;
            reinvestPct = 70;
          }
        } else if (userData[msg.sender].score >= 0 && userData[msg.sender].score <= 1) {
          withdrawPct = 50;
          reinvestPct = 50;
        } else {
          if (userData[msg.sender].score == 2) {
            withdrawPct = 70;
            reinvestPct = 30;
          } else {
            withdrawPct = 85;
            reinvestPct = 15;
          }
        }

        uint256 rewardsAmount = availableAmount * withdrawPct / 100;
        uint256 compoundAmount  = availableAmount * reinvestPct / 100;

        require(getContractBalance() >= rewardsAmount, "Contract balance cannot satisfy your request.");

        uint256 contractFeeAmount = rewardsAmount * contractFee / 100;
        uint256 devFeeAmount = rewardsAmount * devFee / 100;
        uint256 burnFeeAmount = rewardsAmount * burnFee / 100;
        uint256 totalFeeAmount = contractFeeAmount + devFeeAmount + burnFeeAmount;
        uint256 totalAmount = rewardsAmount - totalFeeAmount;

        if (devFeeAmount > 0) {
          bool txDevFee = tokenInterface.transfer(devAddress, devFeeAmount);
          require(txDevFee, "Transfer error (devAddress)");
        }

        if (burnFeeAmount > 0) {
          bool txBurnFee = tokenInterface.transfer(burnAddress, burnFeeAmount);
          require(txBurnFee, "Transfer error (burnAddress)");

          statsBurned += burnFeeAmount;
        }

        bool txRewards = tokenInterface.transfer(msg.sender, totalAmount);
        require(txRewards, "Transfer error (rewardedAddress)");

        statsRewards += totalAmount;

        userData[msg.sender].score--;
        userData[msg.sender].withdrawn += totalAmount;
        userData[msg.sender].autoclaim = 0;
        userData[msg.sender].autoclaimTotal = 0;
        userData[msg.sender].autoclaimTimestamp = 0;

        if (compoundAmount > 0) { userData[msg.sender].invested += compoundAmount; }

        emit withdrawn(getCurrentTime(), msg.sender, totalAmount);

        setContractBalanceTrending();
      }

      if (userData[msg.sender].score > 3) { userData[msg.sender].score = 3; }
      if (userData[msg.sender].score < -2) { userData[msg.sender].score = -2; }

      userData[msg.sender].available = 0;
      userData[msg.sender].timerWithdrawCompound = timerDataStruct(getCurrentTime(), getCurrentTime() + timerWithdrawCompound);
    }
  }

  function refundDeposit() external isContractStarted nonReEntrant {
    require(userData[msg.sender].exists, "Unknown user address.");
    require(userData[msg.sender].withdrawn == 0, "Refund is no longer available after any withdrawal.");
    require(userData[msg.sender].deposited > 0, "Nothing to refund.");

    uint256 burnFeeAmount = userData[msg.sender].deposited * burnFee / 100;
    uint256 refundAmount = userData[msg.sender].deposited / 2;

    require(getContractBalance() >= refundAmount, "Contract balance cannot satisfy your request.");

    if (burnFeeAmount > 0) {
      bool txBurnFee = tokenInterface.transfer(burnAddress, burnFeeAmount);
      require(txBurnFee, "Transfer error (burnAddress)");

      statsBurned += burnFeeAmount;
    }

    bool txRefund = tokenInterface.transfer(msg.sender, refundAmount);
    require(txRefund, "Transfer error (txRefund)");

    statsRewards += refundAmount;

    delete userData[msg.sender];

    userData[msg.sender].refund.push(refundDataStruct(getCurrentTime(), refundAmount));

    emit refund(getCurrentTime(), msg.sender, refundAmount);

    setContractBalanceTrending();
  }

  function applyClaimDailyRewards(address addr) internal {
    unchecked {
      uint256 rewards = userData[addr].invested * (dailyPercent + (userData[addr].rewardsLevel - 1)) / 100;

      userData[addr].available += rewards;
      userData[addr].timerClaimDailyRewards = timerDataStruct(getCurrentTime(), getCurrentTime() + timerClaimDailyRewards);
      userData[addr].consecutiveClaims += 1;

      if (userData[addr].consecutiveClaims >= nextRewardsLevelConsecutiveClaims && userData[addr].rewardsLevel + 1 <= maxRewardsLevel) {
        userData[addr].consecutiveClaims = 0;
        userData[addr].rewardsLevel += 1;
      }
    }
  }

  function claimDailyRewards() external isContractStarted {
    require(userData[msg.sender].exists, "Unknown user address.");
    require(userData[msg.sender].timerClaimDailyRewards.end <= getCurrentTime(), "User cannot yet claim daily rewards. Try again in a few moments.");

    applyClaimDailyRewards(msg.sender);
  }

  function enableAutoClaimDailyRewards(uint256 count) public payable isContractStarted nonReEntrant {
    require(userData[msg.sender].exists, "Unknown user address.");
    require(count <= maxAutoClaims, "Maximum number of auto-claims exceeded.");

    uint256 amount = count * uint256(1 ether * 0.00175);

    require(msg.value >= amount, "Insufficient BNB amount.");

    (bool txAutoClaimFee, ) = payable(execAddress).call{ value: amount }("");
    require(txAutoClaimFee, "Transfer error (execAddress)");

    userData[msg.sender].autoclaim = count;
    userData[msg.sender].autoclaimTotal = count;
    userData[msg.sender].autoclaimTimestamp = 0;
  }

  function disableAutoClaimDailyRewards() external isContractStarted {
    require(userData[msg.sender].exists, "Unknown user address.");

    userData[msg.sender].autoclaim = 0;
    userData[msg.sender].autoclaimTotal = 0;
    userData[msg.sender].autoclaimTimestamp = 0;
  }

  function getUserAutoClaimDailyRewards() external view isContractStarted onlyExecAddress returns (address[] memory) {
    uint256 count = userDataList.length;
    address[] memory list = new address[](count);

    unchecked {
      for (uint256 i = 0; i < count; i++) {
        userDataStruct memory data = userData[userDataList[i]];

        if (!data.exists) { continue; }
        if (data.autoclaimTotal == 0) { continue; }
        if (data.timerClaimDailyRewards.end > getCurrentTime()) { continue; }

        list[i] = userDataList[i];
      }
    }

    return list;
  }

  function execAutoClaimDailyRewards(address addr) external isContractStarted onlyExecAddress {
    require(userData[addr].exists, "Unknown user address.");

    userDataStruct memory data = userData[addr];

    require(data.autoclaimTotal > 0);
    require(data.timerClaimDailyRewards.end <= getCurrentTime());

    applyClaimDailyRewards(addr);

    userData[addr].autoclaim--;
    userData[addr].autoclaimTimestamp = getCurrentTime();

    if (userData[addr].autoclaim == 0) {
      userData[addr].autoclaimTotal = 0;
      userData[addr].autoclaimTimestamp = 0;
    }

    emit autoClaim(getCurrentTime(), addr);
  }

  function getContractBalance() public view returns (uint256) {
    return tokenInterface.balanceOf(address(this));
  }
}