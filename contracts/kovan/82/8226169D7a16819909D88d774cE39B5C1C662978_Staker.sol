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

  uint256 public constant threshold = 1 ether;

  uint256 public deadline;

  bool public openForWithdraw;

  bool public hasExecuted;

  address[] public fundersLedger;
  mapping(address => uint256) public balances;

  event Stake(address _stakeAdress, uint256 _stakeAmount);

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
      deadline = block.timestamp + 72 hours;
  }

  function stake() public payable {
    require(!hasExecuted, "Can not Stake ETH after Execution!");
    
    balances[msg.sender] += msg.value;
    
    emit Stake(msg.sender, msg.value);
    
  } 

  function execute() public {

    require(block.timestamp > deadline, "Deadline not Reached!");

    require(!hasExecuted, "Can Not Be Executed More Than Once");
    hasExecuted = true;

    if(address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    }else{
      openForWithdraw = true;
  }

  }

  function withdraw() public {
    require(openForWithdraw == true, "Must invoke the Execute");
    
    uint256 safetyBalance = balances[msg.sender];
    balances[msg.sender] = 0;
    require(safetyBalance>0, "There is no fund in the Contract");

    payable(msg.sender).transfer(safetyBalance);
    
  }
    
  function timeLeft() public view returns (uint256) {
    if(block.timestamp >= deadline) {
      return 0;
    }else{
      return deadline-block.timestamp;
    }

    }

    receive() external payable {

      stake();

    }
  }
    

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )


  // After some `deadline` allow anyone to call an `execute()` function
  // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`


  // If the `threshold` was not met, allow everyone to call a `withdraw()` function


  // Add a `withdraw()` function to let users withdraw their balance


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend


  // Add the `receive()` special function that receives eth and calls stake()