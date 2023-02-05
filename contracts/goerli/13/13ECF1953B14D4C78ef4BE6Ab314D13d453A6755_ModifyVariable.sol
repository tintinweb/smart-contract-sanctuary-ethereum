/**
 *Submitted for verification at Etherscan.io on 2023-02-05
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract ModifyVariable {
  uint public x;
  string public str; // = "Glavryba";

  constructor(uint _x, string memory _str) {
    x = _x;    
    str = _str;
  }

  function modifyToLeet() public {
    x = 1337;
    str = "Abyrvalg";
  }

}