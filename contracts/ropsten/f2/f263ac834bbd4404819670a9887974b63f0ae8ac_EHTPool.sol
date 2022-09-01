// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./Manager.sol";

contract EHTPool is Manager{
    
  uint public idx;
  uint private nonCalculatedDeposits;
  uint private decimalsPrecision;
  uint public contractBalance;
  uint public lastWithDraw;

  struct User {
    uint balanceOf;
    uint unclaimedRewards;
    uint timeOfDeposit;
    uint nonCalculatedRewards;
  }

  mapping(address => User) users;

  mapping(uint => uint) public rewardsMapping;
  mapping(uint => uint) public prefixSumDeposits;

  constructor () {
      prefixSumDeposits[0] = 0;
      rewardsMapping[0] = 0;
      nonCalculatedDeposits = 0;
      idx = 1;
      decimalsPrecision = 2;
  }

  function addRewards(uint amount) public isManager {
    rewardsMapping[idx] = amount;

    prefixSumDeposits[idx] = prefixSumDeposits[idx - 1] + nonCalculatedDeposits;
    
    idx ++;
    nonCalculatedDeposits = 0;

    contractBalance += amount;
  }

  function calculateRewards(address _address) public view returns(uint) {
    uint rewardsReturn = 0;
    for(uint i = users[_address].timeOfDeposit; i < idx; i++ ) {
      uint participationPercent = ((users[_address].balanceOf * 100) * (10 ** decimalsPrecision) / prefixSumDeposits[i]);
      rewardsReturn += (participationPercent * rewardsMapping[i] / 100) / (10 ** decimalsPrecision);
    }
    return rewardsReturn;
  }

  function deposit(uint amount) public {
    if(users[msg.sender].balanceOf > 0) {
      users[msg.sender].unclaimedRewards = calculateRewards(msg.sender);
    }
    if(users[msg.sender].timeOfDeposit != idx) {
      users[msg.sender].nonCalculatedRewards = 0;
    }
    users[msg.sender].nonCalculatedRewards += amount;
    users[msg.sender].timeOfDeposit = idx;
    users[msg.sender].balanceOf += amount;
    nonCalculatedDeposits += amount;

    contractBalance += amount;
  }

  function withdraw() public returns(uint) {
    require(users[msg.sender].balanceOf > 0, "Balance 0");
    uint totalToWithdraw = users[msg.sender].balanceOf + users[msg.sender].unclaimedRewards;
    uint calculatedRewards = calculateRewards(msg.sender);
    if(calculatedRewards == 0) {
      nonCalculatedDeposits -= users[msg.sender].nonCalculatedRewards;
    }

    users[msg.sender].balanceOf = 0;
    users[msg.sender].timeOfDeposit = 0;
    users[msg.sender].unclaimedRewards = 0;
    users[msg.sender].nonCalculatedRewards = 0;
    lastWithDraw = totalToWithdraw + calculatedRewards;
    contractBalance -= lastWithDraw;
    return lastWithDraw;
  }

}