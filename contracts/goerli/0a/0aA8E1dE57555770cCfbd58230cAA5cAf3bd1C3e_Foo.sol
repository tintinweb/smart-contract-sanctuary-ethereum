// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Foo {
  uint public x = 1;
  bool public b;

  constructor (bool b_) {
    b = b_;
  }

  function inc() public {
    x++;
  }
}