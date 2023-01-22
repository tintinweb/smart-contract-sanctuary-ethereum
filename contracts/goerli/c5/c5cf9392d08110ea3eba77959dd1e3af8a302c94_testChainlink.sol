/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract testChainlink {
  // give me 2 uint256 variable that are public, named as "a" and "b"
  uint256 a;
  uint256 b;

  // give me a function allow user to assign value to a and b
  function setA(uint256 _a) public {
    a = _a;
  }

  function setB(uint256 _b) public {
    b = _b;
  }

  // give me a function that takes 2 arguments which are string and uint256
  // the function will return a unint256 which is using a to multiple by b
  function multiply(uint256 _a, uint256 _b) public returns (uint256) {
    a = _a;
    b = _b;
    return a * b;
  }




}