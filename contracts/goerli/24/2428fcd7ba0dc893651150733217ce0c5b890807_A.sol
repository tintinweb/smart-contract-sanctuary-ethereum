/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract A {
  uint a;
  function setA(uint _a) public returns(uint) {
    a = _a;
    return a;
  }
}