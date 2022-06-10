//  SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter {

  uint public counter;

  constructor() {
    counter = 0;
  }

  function count() public {
    counter = counter + 1;
  }


  function set(uint x) public {
      counter = counter + x;
  }

}