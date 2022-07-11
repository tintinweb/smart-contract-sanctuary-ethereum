// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed = false;

  function complete() public payable {
    completed = true;
  }

  function getCompleted() public view returns (bool) {
    return completed;
  }

}