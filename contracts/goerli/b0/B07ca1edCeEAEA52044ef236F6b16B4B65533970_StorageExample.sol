// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract StorageExample {
  uint public storedData;

  constructor(uint x) {
    require(x != 1, "no 1");
    storedData = x;
  }

  function set(uint x) public {
    require(x != 1, "no 1");
    storedData = x;
  }

  function get() public view returns (uint) {
    return storedData;
  }

  function calledBy() public view returns (address) {
    return msg.sender;
  }
}