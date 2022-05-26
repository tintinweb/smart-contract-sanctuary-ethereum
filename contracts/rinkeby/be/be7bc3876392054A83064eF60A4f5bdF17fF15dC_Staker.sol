// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ExampleExternalContract.sol";

contract Staker {

  // collect eth from multiple addresses
  // track deadline and threshold
  // if deadline reached + threshold reached, send funds to contracy
  // if reach but threshold not reached, let funds get withdrawn

  ExampleExternalContract public exampleExternalContract;
  mapping (address => uint256) public balances;
  uint public immutable threshold = 1 ether;
  uint public deadline;
  bool public canWithdraw = false;

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
      deadline = block.timestamp + 72 hours;
  }

  event Stake(address addr, uint stakeAmount);
  
  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  
  // check that other contract was not yet completed and that withdraw is not eligible
  modifier notCompleted(){
    require(!exampleExternalContract.completed() && !canWithdraw, "contract already completed");
    _;
  }

  modifier eligibleForWithdraw(){
    require(canWithdraw, 'Contract not eligible for withdraw');
    _;
  }

  function stake() public payable notCompleted {
    require(block.timestamp <= deadline, "Deadline has passed");
    uint balance = balances[msg.sender];
    
    //original it's 0
    balances[msg.sender] = msg.value + balance; 
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  // if the `threshold` was not met, allow everyone to call a `withdraw()` function

  function execute() public notCompleted  {
    // contract can't execute automatically, so anyone should be able to call this function once after the deadline
    require(block.timestamp >= deadline, "deadline has not yet passed." );
    
    if (address(this).balance >= threshold) {
         exampleExternalContract.complete{
          value: address(this).balance
    }();
    } else {
      canWithdraw = true;
    }
  }
  

  // Add a `withdraw()` function to let users withdraw their balance
  function withdraw() public eligibleForWithdraw {
    uint256 userBalance = balances[msg.sender];
    require(userBalance > 0, "userBalance is 0");
    balances[msg.sender] = 0;
    payable(msg.sender).transfer(userBalance);
  }


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint) {
    if (deadline >= block.timestamp) {
      return deadline - block.timestamp; 
    } else {
      return 0;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }


}