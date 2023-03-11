/**
 *Submitted for verification at Etherscan.io on 2023-03-11
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract ModifyVariable {
  uint public x;
  string public name;

  constructor(uint _x, string memory _name) {
    x = _x;
    name = _name;
  }

  function modifyToLeet() public {
    x = 1337;
  }

  function changeName(string memory _name) public {
    name = _name;
  }

}