// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract BmiReborn {
  function calculateBMI(uint height, uint weight) public returns (uint){
    uint bmi = 0;
    bmi = (weight * 10000) / (height * height);
    return bmi;
  }
}