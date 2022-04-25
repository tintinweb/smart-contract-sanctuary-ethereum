// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


//import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
  
  modifier notCompleted(){
    require(exampleExternalContract.completed() == false, "is already completed");
    _;
  }

  // set an event
   event Stake(address,uint256);

  ExampleExternalContract public exampleExternalContract;
  
  // mapping to trank the balances 
  mapping (address => uint256) public balances;
  // set the threshold
  uint256 public constant THRESHOLD = 1 ether;
  // set the deadline
  uint256 public deadline = block.timestamp + 72 hours;
  // boolean 
  bool openForWithdraw = false;
  

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
      
  }
  
  
  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable notCompleted {
    require(msg.value>0);
    balances[tx.origin] += msg.value;
    emit Stake(tx.origin,msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public notCompleted {
    require(timeLeft() == 0);
    if(address(this).balance >= THRESHOLD){
      exampleExternalContract.complete{value: address(this).balance}();
    }
    else{
      openForWithdraw = true;
    }

  }
  

  

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function


  // Add a `withdraw()` function to let users withdraw their balance
  function withdraw() public notCompleted{
    require(openForWithdraw == true, "is not allowed withdraw");
    require(balances[msg.sender]>0,"this address doesn't have stake");
    
    uint256 valueToSend = balances[msg.sender];
    address payable receiver = payable(msg.sender);
    balances[msg.sender] = 0;
    
    receiver.transfer(valueToSend);
    
  }


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() view public returns (uint256) {
    if(deadline > block.timestamp){
      return (deadline-block.timestamp);
    }
    else{
      return 0;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()
  function receive() public payable {
    stake();
  }

}