/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract ModifyVariable {
  uint public x;
  string public y;

  constructor(uint _x) {
    x = _x;
    y = "First message";
  }

  function modifyToLeet() public {
    x = 1337;
    y = "Default String";
  }

}