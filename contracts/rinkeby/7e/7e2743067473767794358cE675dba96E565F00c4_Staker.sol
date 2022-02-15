pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}

pragma solidity 0.8.4;

// SPDX-License-Identifier: UNLICENSED
// import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;
  
  mapping ( address => uint256 ) public balances;

  uint256 public deadline = block.timestamp + 72 hours;

  uint256 public constant threshold = 1 ether;

  bool public openForWithdraw;

  event Stake(address indexed staker, uint256 amt);

constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier notCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "stake has already been transferred");
    _;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() payable public {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public notCompleted {  
    require(block.timestamp > deadline, "Still time to stake");
    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    }
    // if the `threshold` was not met, allow everyone to call a `withdraw()` function
    else {
      openForWithdraw = true;
    }
    
  }

  // Add a `withdraw(address payable)` function lets users withdraw their balance
  function withdraw(address payable caller) public notCompleted {
    require(openForWithdraw, "Withdraw not allowed");
    uint256 amt = balances[msg.sender];
    balances[msg.sender] = 0;
    (bool success, ) = caller.call{value: amt}("");
    require( success, "Failed");
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    }
    return deadline - block.timestamp;
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }

}