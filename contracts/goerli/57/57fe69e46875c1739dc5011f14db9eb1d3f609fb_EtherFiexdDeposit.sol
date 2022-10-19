// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Durations.sol';
import './IERC20.sol';
import './ReentrancyGuard.sol';



contract EtherFiexdDeposit is Durations,ReentrancyGuard{

  uint256 public apr;  //50000/500%

  uint256 public tradeFeeRate = 0;

  uint256 public protectionPeriod = 7 days;

  uint256 public startBlock;
  uint256 public endBlock;

  uint256 public yitian = 1 days;

  uint256 public totalDeposit;
  uint256 public debt;

  uint8 public constant extensionCountLimit = 2;



  mapping(address => DepositSlip) depositSlips;
  mapping(address => RewardPool[]) rewardPools;
  mapping(address => uint8) extensionCount;

  struct DepositSlip{
    address user;
    uint256 balance;
    uint256 startTime;
    uint256 duration;
    uint256 apr;
    uint256 reward;
    bool isClaimed;
  }

  struct RewardPool{
    uint256 startTime;
    uint256 duration;
    uint256 amount;
    uint256 claimed;
  }

  struct LockReward{
    uint256 lockAmount;
    uint256 unlockAmount;
    uint256 claimed;
  }

  event Deposit(address indexed user,uint256 amount,uint256 duration);
  event Extension(address indexed user,uint256 amount,uint256 duration);
  event Withdraw(address indexed user,uint256 amount,uint256 reward);
  event Claim(address indexed user,uint256 amount);



  constructor(
    uint256 _apr,
    uint256 _startBlock,
    uint256 _endBlock,
    uint256[] memory _durations
  ){
    require(_apr > 0,'interestRate params error');
    require(_startBlock > block.number,'startBlock params error');
    require(_endBlock > _startBlock, 'endBlock params error');
    require(_durations.length > 0,'durations params error');

    apr = _apr;
    startBlock = _startBlock;
    endBlock = _endBlock;
    _add(_durations);
  }



  function deposit(uint256 amount,uint256 duration) nonReentrant payable external{
    require(startBlock <= block.number && endBlock >= block.number,'deposit not open');
    require(amount > 0,'amount error');
    require(durationContains(duration),'deadline param is error');
    DepositSlip storage depositSlip =  depositSlips[_msgSender()];
    if(!depositSlip.isClaimed){
      _update(depositSlip);
    }

    amount = msg.value;
    
    depositSlip.balance += amount;  
    depositSlip.user = _msgSender();
    depositSlip.apr = apr;
    depositSlip.duration = duration;
    depositSlip.startTime = block.timestamp;
    depositSlip.isClaimed = false;
    totalDeposit += amount;
    
    emit Deposit(depositSlip.user,amount,duration);
  }

  function _update(DepositSlip storage depositSlip) internal {
    if(depositSlip.balance > 0){
      depositSlip.reward += _getReward(depositSlip);
    }
  }

  function _getReward(DepositSlip memory depositSlip) internal view returns (uint256 reward) {
    if(depositSlip.balance > 0){
      uint256 rewardByDay = (depositSlip.balance * depositSlip.apr)/10000/365;
      uint256 depositDays = (block.timestamp - depositSlip.startTime)/yitian;
      depositDays = depositDays > depositSlip.duration ? depositSlip.duration : depositDays;
      reward = rewardByDay * depositDays;
    }
  }

  function extension(uint256 duration) nonReentrant external {
    require(durationContains(duration),'deadline param is error');
    require(extensionCount[_msgSender()] < extensionCountLimit,'out of extension count');
    DepositSlip storage depositSlip = depositSlips[_msgSender()];
    require(depositSlip.balance > 0,'no balance');


    uint256 deadline = (depositSlip.duration * yitian)+depositSlip.startTime;
    require(deadline < block.timestamp,'deposit not due');
    require((block.timestamp - deadline) < protectionPeriod,'too late');
   
    if(!depositSlip.isClaimed){
      _update(depositSlip);
      _addRewardPool(depositSlip.reward, depositSlip.duration, deadline);
    }else{
      depositSlip.isClaimed = false;
    }
    
    depositSlip.reward = 0;

    depositSlip.apr = apr - ((extensionCount[_msgSender()] + 1) * 10000);
    depositSlip.duration = duration;
    depositSlip.startTime = block.timestamp;

    extensionCount[_msgSender()] += 1;

    emit Extension(depositSlip.user, depositSlip.balance, depositSlip.duration);
  }

  function _addRewardPool(uint256 reward,uint256 duration,uint256 deadline) internal {
    reward -= reward * tradeFeeRate / 10000;
    debt += reward;
    RewardPool[] storage rewardPool = rewardPools[_msgSender()];
    rewardPool.push(RewardPool({
      amount: reward,
      duration: duration,
      startTime: deadline,
      claimed: 0
    }));
  }


  function withdraw() nonReentrant external {
    DepositSlip storage depositSlip = depositSlips[_msgSender()];

    uint256 deadline = (depositSlip.duration * yitian)+depositSlip.startTime;
    require(deadline < block.timestamp,'deposit not due');
    require(depositSlip.balance > 0,'no balance');
    
    if(!depositSlip.isClaimed){
      _update(depositSlip);
      _addRewardPool(depositSlip.reward, depositSlip.duration, deadline);
      depositSlip.isClaimed = true;
    }
    uint256 balance = depositSlip.balance;
    uint256 reward = depositSlip.reward;
    
    payable(_msgSender()).transfer(balance);
    totalDeposit -= balance;
    depositSlip.balance = 0;
    depositSlip.reward = 0;
    
    emit Withdraw(depositSlip.user, balance, reward);
  }

  function claim() nonReentrant external {
    DepositSlip storage depositSlip = depositSlips[_msgSender()];
    uint256 deadline = (depositSlip.duration * yitian)+depositSlip.startTime;
    if(deadline < block.timestamp){
      if(depositSlip.balance > 0){
        if(!depositSlip.isClaimed){
          _update(depositSlip);
          _addRewardPool(depositSlip.reward, depositSlip.duration, deadline);
          depositSlip.isClaimed = true;
          depositSlip.reward = 0;
        }
      }
    }


    RewardPool[] storage rewardPool = rewardPools[_msgSender()];
    uint256 claimAmount;
    for(uint256 i; i < rewardPool.length; i++){
      uint256 releaseAmount =_getReleaseReward(rewardPool[i]);
      if(rewardPool[i].claimed < releaseAmount){
        claimAmount += releaseAmount - rewardPool[i].claimed;
        rewardPool[i].claimed = releaseAmount;
      }
    }

    require(claimAmount > 0, 'no rewards to claim');
    payable(_msgSender()).transfer(claimAmount);
    
    emit Claim(_msgSender(), claimAmount);
  }

  function _getReleaseReward(RewardPool memory rewardPool)internal view returns(uint256){
    if(rewardPool.amount > rewardPool.claimed){
      uint256 releaseTime = block.timestamp - rewardPool.startTime;
      uint256 releaseDuration = releaseTime/yitian;
      uint256 releaseAmount = rewardPool.amount * releaseDuration * 100 / rewardPool.duration ;
      return (releaseAmount/100) >= rewardPool.amount ? rewardPool.amount : (releaseAmount/100);
    }
    return rewardPool.amount;
  }


  function viewLockReward(address user)external view returns(LockReward memory lockReward){
    RewardPool[] memory rewardPool = rewardPools[user];

    uint256 claimed;
    uint256 lockAmount;
    uint256 unlockAmount;
    for(uint256 i; i < rewardPool.length; i++){
      claimed += rewardPool[i].claimed;
      if(rewardPool[i].amount > rewardPool[i].claimed){
        uint256 releaseAmount = _getReleaseReward(rewardPool[i]);
        
        lockAmount += rewardPool[i].amount - releaseAmount;
        unlockAmount += releaseAmount - rewardPool[i].claimed;
      }
    }

    DepositSlip memory depositSlip = depositSlips[user];
    if(depositSlip.balance > 0 && !depositSlip.isClaimed){
      uint256 deadline = (depositSlip.duration * yitian)+depositSlip.startTime;
      if(deadline <= block.timestamp){
        RewardPool memory newRewardPool = RewardPool({startTime: deadline,duration: depositSlip.duration,amount: _getReward(depositSlip),claimed: 0});
        uint256 releaseAmount = _getReleaseReward(newRewardPool);
        lockAmount += newRewardPool.amount - releaseAmount;
        unlockAmount += releaseAmount;
      }
    }

    lockReward = LockReward({
      lockAmount: lockAmount,
      unlockAmount: unlockAmount,
      claimed: claimed
    });
  }


  function viewDepositSlip(address user) external view returns(DepositSlip memory){
    DepositSlip memory depositSlip = depositSlips[user];  
    if(!depositSlip.isClaimed){
      depositSlip.reward += _getReward(depositSlip);
    }
    
    return depositSlip;
  }

  function viewUserExtensionCount(address user) external view returns(uint8){
    return extensionCount[user];
  } 


  function updateApr(uint256 _apr) external onlyOwner{
    require(_apr != apr,'no change');
    apr = _apr;
  }

  function updateTradeFeeRate(uint256 _tradeFeeRate) external onlyOwner{
    require(_tradeFeeRate != tradeFeeRate,'no change');
    tradeFeeRate = _tradeFeeRate;
  }

  function updateProtectionPeriod(uint256 _protectionPeriod)external onlyOwner{
    require(_protectionPeriod != protectionPeriod,'no change');
    protectionPeriod = _protectionPeriod;
  }

  function updateDepositDate(uint256 _startBlock,uint256 _endBlock)external onlyOwner{
    require(_startBlock > block.number && _endBlock > _startBlock,'date is error');
    startBlock = _startBlock;
    endBlock = _endBlock;
  }

  function updateYiTian(uint256 _yitian) external onlyOwner{
    require(_yitian != yitian,'no change');
    yitian = _yitian;
  }

}