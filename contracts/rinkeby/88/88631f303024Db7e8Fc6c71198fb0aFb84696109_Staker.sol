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

//import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  mapping(address => uint256) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 72 hours;
  
  ExampleExternalContract public exampleExternalContract;
  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  event Stake(address indexed sender, uint256 amount);

  modifier deadlineReached (bool requireReached ) {
    uint256 timeRemaining = timeLeft();
    if ( requireReached ) {
      require(timeRemaining == 0, "Deadline is not reached yet");
    } else {
      require(timeRemaining > 0, "Deadline is already reached");
    }
    _;
  }
  modifier stakeNotCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "staking process already completeed");
    _;
  }
  
  function execute() public stakeNotCompleted deadlineReached(false) {
    uint256 contractBalance = address(this).balance;
    require(contractBalance >= threshold, "threshold not reached");
    (bool sent, ) = address(exampleExternalContract).call{value: contractBalance}(abi.encodeWithSignature("complete()"));
    require(sent, "exampleExternalContract.complete failed");
  }
  function stake() public payable deadlineReached(false) stakeNotCompleted {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  function withdraw() public deadlineReached(true) stakeNotCompleted {
    uint256 userBalance = balances[msg.sender];
    require(userBalance > 0, "You dont have balance to withdraw");
    balances[msg.sender] = 0;
    (bool sent,) = msg.sender.call{value: userBalance}("");
    require(sent, "Failed to send user balance back to the user");
  }
  function timeLeft() public view returns (uint256 timeleft){
    if(block.timestamp >= deadline) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }
}