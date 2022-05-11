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

  mapping (address => uint256 ) public balances;

  uint256 public constant threshold = 0.01 ether;

  event Stake(address indexed depositor, uint256 amount );

  uint256 public deadline = block.timestamp + 72 hours;

  bool public openForWithdraw;

  /**
  * @notice Modifier that require the deadline to be reached or not
  * @param requireReached Check if the deadline has reached or not
  */
  modifier deadlineReached( bool requireReached) {
  uint256 timeRemaining = timeLeft();
    if(requireReached){
      require(timeRemaining <= 0, "Deadline not reached yet");
    } else{
      require(timeRemaining > 0, "Deadline has already been reached");
    }
    _;
  }

  /**
  * @notice Modifier that require the external contract to not be completed
  */
  modifier stakeNotCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "staking process already completed");
    _;
  }

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable deadlineReached(false) stakeNotCompleted {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }


  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public stakeNotCompleted {
    uint256 contractBalance = address(this).balance;
    // check the contract has enough ETH to reach the treshold
    if(contractBalance >= threshold){
      exampleExternalContract.complete{value: contractBalance}();
    } else {
      openForWithdraw = true;
    }
  }

  // Add a `withdraw()` function to let users withdraw their balance
  function withdraw(address payable _depositor) public deadlineReached(true) stakeNotCompleted{
    require(openForWithdraw, "Not open");
    uint userbalance = balances[msg.sender];
    require(userbalance > 0 );

    // protect against reentrancy.
    balances[msg.sender] = 0;

    (bool sent,) = _depositor.call{value: userbalance}("");
    require(sent, "Failed to send value back");
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    return block.timestamp >= deadline ? 0 : deadline - block.timestamp;
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable { 
    stake();
  }

}