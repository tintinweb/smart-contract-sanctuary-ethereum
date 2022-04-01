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

// import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  mapping(address => uint) public balances;

  bool public executeFunctionCalled;
  bool openForWithdraw;

  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 2 minutes;

  event Stake(address indexed _from, uint256 _amount);

  constructor(address exampleExternalContractAddress) public {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  function execute() public {
    require(!executeFunctionCalled, "Execute already called");
    require(deadline <= block.timestamp, "Deadline not yet expired");
    executeFunctionCalled = true;
    if(address(this).balance > threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else {
      openForWithdraw = true;
    }
  }

  function timeLeft() public view returns (uint) {
    uint num = 0;
    if(block.timestamp < deadline) {
      return deadline - block.timestamp;
    } else if (block.timestamp >= deadline) {
      return num;
    }
  }

  function getContractBalance() public view returns (uint256) {
    return address(this).balance;
  }

  function getContractAddress() public view returns (address) {
    return address(this);
  }
  

  function withdraw() public payable {
    require(openForWithdraw, "Cant withdraw at the moment");
    address _to = msg.sender;
    uint amount = balances[msg.sender];
    (bool sent, bytes memory data) = _to.call{value: amount}("");
    require(sent, "Failed to send Ether");
  }


  function send(address _to) public payable {
    (bool sent, bytes memory data) = _to.call{value: msg.value}("");
    require(sent, "Failed to send Ether");
  }

  receive() external payable {
    stake();
  }

  fallback() external payable {
  }

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value


  // if the `threshold` was not met, allow everyone to call a `withdraw()` function


  // Add a `withdraw()` function to let users withdraw their balance


  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend


  // Add the `receive()` special function that receives eth and calls stake()


}