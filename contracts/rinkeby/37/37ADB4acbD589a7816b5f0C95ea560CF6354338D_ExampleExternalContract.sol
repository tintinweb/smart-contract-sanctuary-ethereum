/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

}