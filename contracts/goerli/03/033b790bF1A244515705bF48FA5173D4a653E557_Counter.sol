/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity >0.8.2 <0.9.0;

contract Counter {
  uint number;
  constructor() {}
  function add(uint x) public {
    number = number + x;
  }
}