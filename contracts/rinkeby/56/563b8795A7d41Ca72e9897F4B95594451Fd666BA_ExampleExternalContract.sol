// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ExampleExternalContract {

  mapping ( address => uint256 ) public balances;

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}