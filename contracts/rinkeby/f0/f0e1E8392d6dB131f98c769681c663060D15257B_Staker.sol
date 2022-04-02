// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

// import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
mapping (address => uint256) public balances;
uint256 public constant threshold = 1 ether;


//events
event Stake(address,uint256);
// modifiers
modifier notCompleted(){
 require(block.timestamp >= deadline,"Deadline time has not yet Elasped.");
  _;
}
modifier isvalidStakePeriod(){
  require(block.timestamp <= deadline,"Valid Staking Period is over");
  _;
}
modifier canwithdraw(){
  require(balances[msg.sender]>0,"Cannot withdraw : Insufficient withdrawal balance.");
  _;
}
  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() external payable isvalidStakePeriod returns (uint256){
    //track current user stake
    balances[msg.sender]+=msg.value;
    //emit Stake event 
    emit Stake(msg.sender,msg.value);
    return msg.value;

}

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value

uint256 public deadline = block.timestamp + 72 hours;
bool  openForWithdraw =false;

function execute() public notCompleted returns(bool){
  if (address(this).balance >= threshold){
    exampleExternalContract.complete{value: address(this).balance}();
  }
  if(address(this).balance < threshold && block.timestamp >= deadline){
    openForWithdraw = true;
  }
  return (true);
}
  // if the `threshold` was not met, allow everyone to call a `withdraw()` function

  // Add a `withdraw()` function to let users withdraw their balance
function withdraw() external payable notCompleted canwithdraw returns(bool){
   payable(msg.sender).transfer(balances[msg.sender]);
  balances[msg.sender]=0;
   return true;
}

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
function timeLeft() public view returns(uint256){
  if(deadline >= block.timestamp){
    uint256 timeRemaining = deadline - block.timestamp;
    return timeRemaining;
  }
  return 0;
  
}

  // Add the `receive()` special function that receives eth and calls stake()

receive() external payable {
  (this).stake();
}
}