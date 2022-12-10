// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BoxV2 {
  uint256 private value;
  event ValueChanged(uint256 newValue);

  function store(uint256 newValue) public {
    value = newValue;
    emit ValueChanged(newValue);
  }

  function get() public view returns (uint256) {
    return value+1;
  }

  function add() public {
    value = value + 1;
  }
}