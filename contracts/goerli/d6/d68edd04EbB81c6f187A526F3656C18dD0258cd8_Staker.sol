pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

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
  ExampleExternalContract public exampleExternalContract;

  bool openForWithdraw = false; 
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 127 hours;
  mapping ( address => uint256 ) public balances;

  event Staked(address, uint);

  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier notCompleted() {
    require(!exampleExternalContract.completed(), "Contract is already completed");
    _;
  }

  function stake() public payable {
    require(block.timestamp < deadline, 'Staking period is over');
    balances[msg.sender] += msg.value;
    emit Staked(msg.sender, msg.value);
  }

  function execute() external notCompleted {
    require(block.timestamp >= deadline, 'Staking period is not over');
    require(!openForWithdraw, 'Withdraw is already open');
    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else {
      openForWithdraw = true;
    }
  }

  function withdraw() external notCompleted {
    require(openForWithdraw, 'Withdraw is not open');

    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
  }

  function timeLeft() external view returns (uint256) {
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