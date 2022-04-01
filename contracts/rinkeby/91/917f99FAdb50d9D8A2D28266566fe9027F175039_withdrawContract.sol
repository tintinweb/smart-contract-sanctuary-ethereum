// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract withdrawContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}