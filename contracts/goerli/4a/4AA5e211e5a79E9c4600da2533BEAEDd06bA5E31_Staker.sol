pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

contract ExampleExternalContract {
  bool public completed;

  function complete() public payable {
    completed = true;
  }
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import './ExampleExternalContract.sol';

contract Staker {
  mapping(address => uint256) public balances;
  uint256 public constant threshold = 1 ether;
  uint256 public deadline = block.timestamp + 72 hours;

  ExampleExternalContract public exampleExternalContract;

  event Stake(address indexed from, uint256 value);

  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  modifier notCompleted() {
    require(!exampleExternalContract.completed());
    // Underscore is a special character only used inside
    // a function modifier and it tells Solidity to
    // execute the rest of the code.
    _;
  }

  // TODO: Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
  //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
  function stake() public payable notCompleted {
    // Must accept more than 0 ETH for a coffee.
    require(msg.value > 0, "can't buy coffee for free!");
    balances[msg.sender] = msg.value;

    // Emit a NewMemo event with details about the memo.
    emit Stake(msg.sender, msg.value);
  }

  // TODO: After some `deadline` allow anyone to call an `execute()` function
  //  It should call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value
  function execute() public {
    require(block.timestamp >= deadline, 'not time');
    // require(address(this).balance >= threshold, 'balance is not enough');
    if (address(this).balance >= threshold) {
      exampleExternalContract.complete{value: address(this).balance}();
    }
  }

  // TODO: if the `threshold` was not met, allow everyone to call a `withdraw()` function
  function withdraw() public notCompleted {
    require(balances[msg.sender] > 0);
    payable(msg.sender).transfer(balances[msg.sender]);
    balances[msg.sender] = 0;
  }

  // TODO: Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
  function timeLeft() public view returns (uint256 timeL) {
    if (block.timestamp >= deadline) {
      return 0;
    }
    return deadline - block.timestamp;
  }

  // TODO: Add the `receive()` special function that receives eth and calls stake()
  receive() external payable {
    stake();
  }
}