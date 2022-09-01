// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test {
  uint256 public variable;

  event VariableRead(uint256 variable);

  function Read() public {
    variable++;
    emit VariableRead(variable);
  }
}