pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

contract ExampleExternalContract {

    bool public completed;
    event Received(uint);

    receive() external payable {
        emit Received(address(this).balance);
    }

    function complete() public payable {
        completed = true;
    }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

//import 'hardhat/console.sol';
import './ExampleExternalContract.sol';

contract Staker {
  ExampleExternalContract public exampleExternalContract;

  mapping ( address => uint256 ) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 72 hours;
  bool openForWithdraw;
  event Staked(address, uint);

  receive() external payable {
    stake();
    emit Staked(msg.sender, msg.value);
  }

  constructor(address payable exampleExternalContractAddress) public {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  function stake() public payable {
    balances[msg.sender] += msg.value;
  }

  function execute() public  {
    require(block.timestamp > deadline, "Can only execute after deadline");
    bool isCompleted = exampleExternalContract.completed();
    require(!isCompleted, "Already executed by a user.");
    if (address(this).balance > threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    } else {
      openForWithdraw = true;
    }
  }

  function timeLeft() public view returns (uint256) {
    if (block.timestamp > deadline) return 0;
    return deadline - block.timestamp;
  }

  function withdraw() public {
    require(openForWithdraw, "You can not withdraw");
    require(balances[msg.sender] > 0, "You did not stake anything");
    bool isCompleted = exampleExternalContract.completed();
    require(!isCompleted, "Execute has been called.");
    payable(address(msg.sender)).transfer(balances[msg.sender]);
    balances[msg.sender] = 0;
  }

  // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )

  // After some `deadline` allow anyone to call an `execute()` function
  //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value

  // if the `threshold` was not met, allow everyone to call a `withdraw()` function

  // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend

  // Add the `receive()` special function that receives eth and calls stake()
}