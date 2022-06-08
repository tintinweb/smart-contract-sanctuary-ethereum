// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract V1Fuck {
  uint public var1;

  function updateVar1(uint _var1) external {
    var1 = _var1;
  }
}