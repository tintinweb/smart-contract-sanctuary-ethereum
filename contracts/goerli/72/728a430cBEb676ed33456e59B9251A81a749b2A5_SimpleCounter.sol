// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract SimpleCounter {
  uint256 public val = 0;

  function inc() public {
    val += 1;
  }

  function dec() public {
    val -= 1;
  }
}