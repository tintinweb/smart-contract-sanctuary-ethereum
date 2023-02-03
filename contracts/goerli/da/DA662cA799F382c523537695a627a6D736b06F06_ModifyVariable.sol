/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract ModifyVariable {
  uint public x;

  constructor(uint _x) {
    x = _x;
  }

  function modifyToLeet() public {
    x = 1337;
  }

  function modifyX(uint num) public {
    x = num;
  }

}