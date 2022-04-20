/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

contract TimeLock {
  mapping(address => uint256) public balances;
  mapping(address => uint256) public lockTime;

  function deposit() public payable {
    balances[msg.sender] += msg.value;
    lockTime[msg.sender] = now + 1 weeks;
  }

  function increaseLockTime(uint256 _secondsToIncrease) public {
    lockTime[msg.sender] += _secondsToIncrease;
  }

  function withdraw() public {
    require(balances[msg.sender] > 0);
    require(now > lockTime[msg.sender]);
    msg.sender.transfer(balances[msg.sender]);
    balances[msg.sender] = 0;
  }
}