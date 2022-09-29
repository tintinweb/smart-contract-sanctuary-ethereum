//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

contract Counter {
  uint public counter;

  function increase() external {
    counter++;
  }
}