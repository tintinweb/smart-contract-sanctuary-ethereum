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

//import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  constructor(address exampleExternalContractAddress)  {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  mapping ( address => uint256 ) public balances;
  event Stake(address indexed sender, uint256 stakedAmount);

  uint256 public constant threshold = 1 ether;

  function stake() public payable {
    balances[msg.sender] += msg.value;
    emit Stake(msg.sender, msg.value);
  }

  uint256 public deadline = block.timestamp + 72 hours;
  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  
  function execute() public {
    require(timeLeft() == 0, "Deadline hasn't been reached, time still dey");

    uint256 totalBalance = address(this).balance;

    require(totalBalance >= threshold, "Threshold hasn't been hit yet");

    (bool sent,) = address(exampleExternalContract).call{value: totalBalance}(abi.encodeWithSignature("complete()"));
    require(sent, "exampleExternalContract failed");
  }

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function
    // Add a `withdraw()` function to let users withdraw their balance
  function withdraw() public {

    // uint256 totalBalance = address(this).balance;
    // require(totalBalance < threshold, "Threshold has been hit");

    uint stakerBalance = balances[msg.sender];
    
    require(timeLeft() == 0, "Deadline hasn't been reached yet");
    require(stakerBalance > 0, "You don't have enough to withdraw");

    balances[msg.sender] = 0;

    address staker = msg.sender;

    //send the balance back
    (bool sent,) = staker.call{value: stakerBalance}("");
    require(sent, "Failed sending the staker balance back to this staker");
  }

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns(uint256 timeleft) {
    return deadline >= block.timestamp ? deadline - block.timestamp : 0;
  }

  // Add the `receive()` special function that receives eth and calls stake()
  receive() payable external {
    stake();
  }

}