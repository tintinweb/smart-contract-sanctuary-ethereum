// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract BMIblockly {
  function CalculationOfBMI(int weight, int height) public pure returns (int){
    int BMI = 0;
    BMI = (weight * 10000) / (height * height);
    return BMI;
  }
}