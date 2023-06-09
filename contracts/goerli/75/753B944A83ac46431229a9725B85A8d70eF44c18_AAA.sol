/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract AAA {
  uint public a = 100;

  function setA(uint _a) public {
    a = _a;
  }

  function add(uint _a, uint _b) public pure returns(uint) {
    return _a+_b;
  }
}