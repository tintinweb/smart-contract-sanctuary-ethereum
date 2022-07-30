// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MyNewBlockly {
  function calculateBMI(int weight, int height) public pure returns (int){
    int bmi = 0;
    bmi = (weight * 10000) / (height * height);
    return bmi;
  }
}