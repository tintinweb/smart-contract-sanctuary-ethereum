// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract LogicV2 {
  uint public num;

  function changeNum(uint _num) public{
    num = _num;
  }
}