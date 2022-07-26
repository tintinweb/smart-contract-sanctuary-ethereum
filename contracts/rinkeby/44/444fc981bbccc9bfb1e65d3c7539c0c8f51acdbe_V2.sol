/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract V2 {
  uint public var1;
  uint public var2;
  uint public var3;

  function updateVar1(uint _var1) external {
    var1 = _var1;
  }
  function updateVar2(uint _var2) external {
    var2 = _var2;
  }
  function updateVar3(uint _var3) external {
    var3 = _var3;
  }
}