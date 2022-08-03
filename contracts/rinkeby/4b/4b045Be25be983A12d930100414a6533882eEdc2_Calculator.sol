// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract Calculator {
  uint128 public answer=0;
  function add(uint128 _a, uint128 _b) public {
     answer = _a+_b;
  }   
  function minus(uint128 _a, uint128 _b) public {
     answer = _a-_b;
  }   
  function multiply(uint128 _a, uint128 _b) public {
     answer = _a*_b;
  }   
  function divide(uint128 _a, uint128 _b) public {
     answer = _a/_b;
  }
}