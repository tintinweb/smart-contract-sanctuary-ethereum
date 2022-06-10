// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  mapping ( address => uint256 ) public balances;

  uint256 public constant threshold = 1 ether;

  uint256 public deadline = block.timestamp + 72 hours;

  bool public openForWithdraw;

  event Stake(address, uint256);

  function stake() public payable {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  function execute() public notCompleted {
    if (address(this).balance > threshold && block.timestamp < deadline) {
      exampleExternalContract.complete{value: address(this).balance}();
    }
    if (address(this).balance < threshold) {
      openForWithdraw = true;
    }
  }

  function withdraw() public notCompleted {
    require(openForWithdraw, "not open for withdraw");
    payable(msg.sender).transfer(address(this).balance);
  }

  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    }
    else {
      return deadline - block.timestamp;
    }
  }

  receive() external payable {
    stake();
  }

  modifier notCompleted {
    require(!exampleExternalContract.completed(), "external contract is complete");
    _;
  }

}