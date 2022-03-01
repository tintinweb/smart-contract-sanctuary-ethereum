// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


contract Box0 {
  uint public var1;

  function updateVar1(uint _var1) public {
    var1 = _var1;
  }

  function showVar1() public view returns (uint) {
    return var1;
  }
}