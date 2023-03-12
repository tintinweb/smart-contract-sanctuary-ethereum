// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

contract Counter {
  uint public val;
  address owner;
  constructor() {
    val = 0;
    owner = msg.sender;
  }
  function count() public {
    require(owner == msg.sender, "error!");
    val++;
  }
}