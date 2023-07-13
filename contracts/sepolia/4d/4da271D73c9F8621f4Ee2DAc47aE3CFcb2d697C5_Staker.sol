// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

//import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;
  
  //Global variables
  mapping ( address => uint256 ) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 72 hours;
  bool public isExecuted = false;
  bool public openForWithdraw = false;

  //Events
  event Stake(address indexed sender, uint256 value);

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  //modifiers
  modifier notCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "Stake already completed!");
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  // ( Make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable {
    balances[msg.sender] = balances[msg.sender] + msg.value;
    emit Stake(msg.sender, msg.value);
  }


  // After some `deadline` allow anyone to call an `execute()` function
  function execute() public notCompleted() {
    require(block.timestamp >= deadline, "deadline not achieved");
    require(isExecuted == false, "function already executed");
    isExecuted = true;
   // If the deadline has passed and the threshold is met, it should call `exampleExternalContract.complete{value: address(this).balance}()`
    if(address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    }
  // If the `threshold` was not met, allow everyone to call a `withdraw()` function to withdraw their balance
    else {
      openForWithdraw = true;
    }
  }

  function withdraw() public notCompleted() {
    require(openForWithdraw == true, "Withdraw not allowed");
    require(balances[msg.sender] > 0, "Sender has no funds to withdraw"); 
    address payable holder = payable(msg.sender); 
    uint256 withdrawAmount = balances[holder];

    balances[holder] = 0;
    holder.transfer(withdrawAmount);
  }
  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns(uint) {
    if(block.timestamp >= deadline){
      return 0;
    } else {
      return (deadline - block.timestamp);
    }
  }


  // Add the `receive()` special function that receives eth and calls stake()
  function recieve() public payable {
    stake();
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}