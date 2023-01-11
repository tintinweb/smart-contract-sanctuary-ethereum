/**
 *Submitted for verification at Etherscan.io on 2023-01-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract ModifyVariable {
  uint public x;
  string public str; 

  constructor(uint _x,string memory _str) {
    x = _x;
    str = _str;
  }

  function modifyToLeet() public {
    x = 1337;
  }

  function modifyToFuck() public {
    str = "Fuck";
  }


}