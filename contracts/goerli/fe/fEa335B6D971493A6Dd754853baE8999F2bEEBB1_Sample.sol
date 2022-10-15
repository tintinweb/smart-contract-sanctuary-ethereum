// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

contract Sample {
  uint32 public sample = 0;

  function increase() public {
    sample = sample + 1;
  }
}