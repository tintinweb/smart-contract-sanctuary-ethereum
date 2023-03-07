pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

contract ExampleExternalContract {
  bool public completed;

  function complete() public payable {
    require(!completed, 'Staking has concluded');
    completed = true;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ExampleExternalContract.sol';

contract Staker {
  ExampleExternalContract public exampleExternalContract;
  mapping(address => uint256) public balances;
  uint256 public constant threshold = 0.0025 ether;
  uint256 public totalStaked;
  uint256 public deadline = 0;
  bool public isDeadline = true;
  bool public openForWithdraw;

  event Stake(address indexed from, uint256 amount);
  event Withdraw(address indexed from, uint256 amount);

  constructor(address _exampleExternalContract) {
    exampleExternalContract = ExampleExternalContract(_exampleExternalContract);
  }

  function stake() public payable {
    openForWithdraw = true;
    balances[msg.sender] += msg.value;
    totalStaked += msg.value;
    if (totalStaked >= threshold) {
      openForWithdraw = false;
    }
    emit Stake(msg.sender, msg.value);
    isDeadline = true;
    deadline = block.timestamp + 10 seconds;
  }

  function execute() public {
    uint256 amount = address(this).balance;
    require(amount == totalStaked, 'Staker balance not equal to totalStaked');
    require(amount >= threshold, 'Threshold not yet reached');
    require(isDeadline == true, 'Deadline has not yet been set');
    require(block.timestamp >= deadline, 'Deadline has not expired');
    exampleExternalContract.complete{value: address(this).balance}();
    totalStaked -= amount;
    balances[msg.sender] = totalStaked;
  }

  function withdraw() public {
    uint256 amount = balances[msg.sender];
    require(msg.sender.balance >= amount, 'Not enough ETH');
    require(amount > 0, 'Not enough ETH');
    require(totalStaked < threshold, 'Total staked has exceeded the threshold');
    require(block.timestamp >= deadline, 'Deadline has not expired');
    payable(msg.sender).transfer(amount);
    balances[msg.sender] = 0;
    totalStaked -= amount;
    emit Withdraw(msg.sender, amount);
  }

  function timeLeft() public view returns (uint256) {
    require(isDeadline == true, 'Deadline has not been set');
    if (block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

  receive() external payable {
    stake();
  }
}