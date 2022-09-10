// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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

  mapping ( address => uint256 ) public balances; // map balances
  uint256 public constant threshold = 1 ether; // const threshold
  uint256 public deadline = block.timestamp + 72 hours;
  bool openforWithdraw;
    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

  event Stake(address, uint256);

  function stake() public payable {
    balances[msg.sender] = msg.value;
    emit Stake(msg.sender, msg.value);  
  }

  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
  function execute() public {
    if (block.timestamp >= deadline && address(this).balance >= threshold) {
    exampleExternalContract.complete{value: address(this).balance}();
    }
  }

  // If the `threshold` was not met, allow everyone to call a `withdraw()` function


  // Add a `withdraw()` function to let users withdraw their balance
  modifier isOpen() {
    require (address(this).balance <= threshold, "not open to withdraw");
    _;
  }
  function withdraw() public payable isOpen {
    uint256 _amount = balances[msg.sender];
    balances[msg.sender] = 0;
    payable(msg.sender).transfer(_amount);
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns(uint256){
    return block.timestamp < deadline ? deadline-block.timestamp : 0;
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }

}