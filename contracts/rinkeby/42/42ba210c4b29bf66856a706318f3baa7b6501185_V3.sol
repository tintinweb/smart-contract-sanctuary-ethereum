/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract V3 {
  uint public var4;
  uint public var2;
  uint public var5;
  uint public var3;

  function updateVar1(uint _var1) external {
    var4 = _var1;
  }

  function updateVar4(uint _var4) external {
    var4 = _var4;
  }
  function updateVar2(uint _var2) external {
    var2 = _var2;
  }
  function updateVar5(uint _var5) external {
    var5 = _var5;
  }
  function updateVar3(uint _var3) external {
    var3 = _var3;
  }
}