//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract ModifyVariable {
  uint public x;
  string public word;

  constructor(uint _x, string memory _word) {
    x = _x;
    word = _word;
  }

  function modifyToLeet() public {
    x = 1337;
  }

  function modifyWord() public {
    word = 'hey u changed me!';
  }

}