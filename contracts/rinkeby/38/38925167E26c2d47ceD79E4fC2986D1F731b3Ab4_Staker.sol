// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import './ExampleExternalContract.sol';

contract Staker {
  event Stake(address indexed staker, uint256 amount);

  ExampleExternalContract public exampleExternalContract;

  mapping(address => uint256) public balances;
  uint256 public constant threshold = 0.05 ether;
  uint256 public deadline = block.timestamp + 72 hours;

  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  function stake() external payable {
    require(msg.value != 0, 'Cannot stake 0');

    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  function execute() public notCompleted {
    require(block.timestamp >= deadline, 'Deadline not reached');

    if (address(this).balance < threshold) {
      return;
    }

    exampleExternalContract.complete{value: address(this).balance}();
  }

  function withdraw() external notCompleted {
    require(address(this).balance < threshold, 'Too much balance');
    require(block.timestamp >= deadline, 'Deadline not reached');

    uint256 toSend = balances[msg.sender];
    balances[msg.sender] = 0;
    payable(msg.sender).transfer(toSend);
  }

  function timeLeft() external view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    }

    return deadline - block.timestamp;
  }

  modifier notCompleted() {
    require(exampleExternalContract.completed() == false, 'Contract already completed');
    _;
  }

  receive() external payable {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }
}