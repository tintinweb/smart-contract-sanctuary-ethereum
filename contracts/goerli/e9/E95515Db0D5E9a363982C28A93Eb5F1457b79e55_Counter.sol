// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.18;
contract Counter {
  uint public counter;
  address public owner;

  constructor() {
    counter = 0;
    owner = msg.sender;
  }

  function add(uint x) public {
    counter = counter + x;
  }

  function count() public view returns (uint) {
    require(owner == msg.sender, 'you do not have permission');
    return counter;
  }
}