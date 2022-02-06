pragma solidity ^0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  enum STAKE {stake , success , offdeadline , completed , withdrawEth}

  event Stake(address who , uint amount);
  
  
  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
      stakeState = STAKE.stake;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

  uint constant public threshold = 1 ether;
  mapping(address => uint) public balances;
  uint deadline = block.timestamp + 30 seconds;
  STAKE public stakeState;
  
  modifier inState( STAKE _stake) {
    require(stakeState == _stake , "Isnt the right time for this");
    _;
  }

  function stake() public payable inState(STAKE.stake){
    //require(address(this).balance <= threshold , "Theashold is 1 ether");
    //require(block.timestamp <= deadline , "Your time is up");
    balances[msg.sender] += msg.value ;
    emit Stake(msg.sender, msg.value);
    if (address(this).balance >= threshold) {
      stakeState = STAKE.success;
    }
    if (block.timestamp >= deadline){
      stakeState = STAKE.offdeadline ;
    }
  }



  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value

  function execute() public {
    require(stakeState == STAKE.offdeadline || stakeState == STAKE.success || stakeState == STAKE.stake);
    if (block.timestamp >= deadline && address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
      stakeState = STAKE.completed;
    }
    else if (block.timestamp >= deadline && address(this).balance < threshold){
      stakeState = STAKE.withdrawEth;
    }
  }

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
  // Add a `withdraw(address payable)` function lets users withdraw their balance

  function withdraw(address payable _to) public payable inState(STAKE.withdrawEth) {
    require(msg.sender == _to , "You are not authorized");
    _to.transfer(balances[_to]);
    balances[_to] -= balances[_to];
    
  } 

  

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

  function timeLeft() public view returns(uint){
    if (block.timestamp >= deadline){
      return 0;
    }
    else {
      return block.timestamp;
    }
  }

  // Add the `receive()` special function that receives eth and calls stake()

  receive() external payable{
    stake();
  }

  function getBlance() public view returns(uint) {
    return address(this).balance ;
  }

}