// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  //mapping of address to balance
  mapping(address => uint256 ) public balance;

  //treshold 
  uint256 constant treshold = 3 ether;
  
  //setting deadline
  uint256 public deadline = block.timestamp + 72 hours;

  modifier withdrawal(){
    bool check = exampleExternalContract.completed();
    if(!check){
      revert();
    }
    _;
  }

  modifier deadlineReached(bool requiredReached){

    uint256 timeRemaining = timeLeft();
    if( requiredReached) {
      require(timeRemaining == 0, "Deadline is not reached yet");
    } else {
      require(timeRemaining > 0, "Deadline is already reached");
    }
    _;

  }
  
  //Events
  event Stake(address indexed user,  uint amount);


  function stake() public payable deadlineReached(false) withdrawal {

    // update the user's balance
    balance[msg.sender] += msg.value;
    
    // emit the event to notify the blockchain that we have correctly Staked some fund for the user
    emit Stake(msg.sender, msg.value);

  }

  function execute() public deadlineReached(false) withdrawal {
     uint256 contractBalance = address(this).balance;

    require(contractBalance >= treshold, "Threshold not reached");

    (bool sent,) = address(exampleExternalContract).call{value: contractBalance}(abi.encodeWithSignature("complete()"));
    require(sent, "exampleExternalContract.complete failed");
  }
 
  //function to withdraw when stake is not completed
  function withdraw() public deadlineReached(true) withdrawal {

    //require user has enough ether 
    require(balance[msg.sender] > 0);

    //set user balance to zero
    balance[msg.sender] = 0;

    (bool sent,) = msg.sender.call{value:balance[msg.sender]}("");
    require(sent, "not sent");
  }

  
  function timeLeft() public view returns(uint){
    if(block.timestamp >= deadline){
      return 0;
    }else{
      return deadline - block.timestamp;
    }
  }

  receive() external payable{

  }

}