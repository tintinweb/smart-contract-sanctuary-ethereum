// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract CountContract {
  uint public count;

  constructor (uint _count) {
    count = _count;
  }

  function setCount (uint _count) public {
    count = _count;
  }

  function increment() public {
    count++;
  }

  function decrement() public {
    count--;
  }
}