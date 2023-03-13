// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Counter {
  uint public counter;
  address owner;

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can call add() function");
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  function add(uint x)  public onlyOwner {
    counter = counter + x;
  } 
}