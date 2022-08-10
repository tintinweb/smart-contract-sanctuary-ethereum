// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function isComplete() external view returns (bool) {
    return completed;
  }

  function complete() public payable {
    completed = true;
  }

  // function setComplete() public {
  //   completed = !completed;
  // }


}