// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed;

  modifier notCompleted(){
    require(!completed);
    _;
  }

  function complete() public payable notCompleted {
    completed = true;
  }

}