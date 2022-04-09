// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Box {
  uint256 public value;

  event ValueChanged(uint256 newValue);

  function store(uint256 newValue) public {
    value = newValue;
    emit ValueChanged(newValue);
  }
}