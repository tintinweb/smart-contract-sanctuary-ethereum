/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract ModifyVariable {
  uint public x;
  string public foo;

  constructor(uint _x, string memory _foo) {
    x = _x;
    foo = _foo;
  }

  function modifyToLeet() public {
    x = 1337;
  }

  function modifyToBar() public {
    foo = 'bar';
  }

}