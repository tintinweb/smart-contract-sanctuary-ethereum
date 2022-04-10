/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// Sources flattened with hardhat v2.6.0 https://hardhat.org

// File contracts/ExampleExternalContract.sol


pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}


// File contracts/Staker.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// import "hardhat/console.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }
  
  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  mapping ( address => uint256 ) public balances;

  uint256 public constant threshold = 1 ether;

  event Stake(address sender, uint256 amount);

  function stake() public payable beforeDeadline {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }
  
  
  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  uint256 public deadline = block.timestamp + 30 seconds;
  bool public openForWithdraw;


  function execute() public {
    require(block.timestamp >= deadline);
    if (address(this).balance > threshold) {
      return exampleExternalContract.complete{value: address(this).balance}();
    } else {
      openForWithdraw = true;
    }
  }

  modifier beforeDeadline() {
    require(block.timestamp < deadline, "Deadline has passed");
    _;
  }

  modifier withdrawOpen() {
    require(openForWithdraw == true, "The pool was completely staked no withdraw");
    _;
  }

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function


  // Add a `withdraw()` function to let users withdraw their balance

  function withdraw() public withdrawOpen {
    require(balances[msg.sender] > 0, "You have no ether in the contract.");
    (bool success, ) = msg.sender.call{value: balances[msg.sender]}("");
    require(success, "Failed to send Ether");
    balances[msg.sender]=0;
  }


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

  function timeLeft() public view returns(uint256) {
    if (block.timestamp >= deadline) {
      return 0;
    }
    return deadline - block.timestamp;
  }



  // Add the `receive()` special function that receives eth and calls stake()

  receive() external payable {
    return stake();
  }
}