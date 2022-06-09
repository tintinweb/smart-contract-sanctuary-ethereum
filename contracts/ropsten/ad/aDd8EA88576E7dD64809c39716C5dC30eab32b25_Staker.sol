// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping(address => uint256) public balances;
  
  uint256 public deadline = block.timestamp + 72 hours;
  uint256 public constant threshold = 1 ether;
  bool public openForWithdraw;
  bool public isExecuted;

  event Stake(address staker, uint256 amount);

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier afterDeadline() {
    require(block.timestamp > deadline, "Wait for the deadline");
    _;
  }

  modifier notCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "Completed !");
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

  function stake() public payable {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value

  function execute() public afterDeadline notCompleted {
    require(!isExecuted, "Already completed");

    uint256 contractBalance = address(this).balance;

    if (contractBalance >= threshold) {
      complete();
    } else {
      openForWithdraw = true;
    }

    isExecuted = true;
  }

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw() public notCompleted {
    require(openForWithdraw, "Not open for withdraw");

    uint256 amountToSend = balances[msg.sender];
    balances[msg.sender] -= amountToSend;
    (bool sent, ) = msg.sender.call{value:amountToSend}("");

    require(sent, "Error in transfer");
  }

  function timeLeft() public view returns(uint256) {
    if(block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

  function complete() public {
    exampleExternalContract.complete{value: address(this).balance}();
  }

  receive() external payable {
      stake();
  }
}