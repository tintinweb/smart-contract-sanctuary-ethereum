// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Counter {
  uint256 public count;

  function increment() external {
    count += 1;
  }
}