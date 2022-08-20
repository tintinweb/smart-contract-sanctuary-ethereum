// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract myNewGuiBMI {
  int myInt = 0;
  function calculateBMI(int weight, int height) public pure returns (int){
    int bmi = 0;
    bmi = (weight * 10000) / (height * height);
    return bmi;
  }
  function getMyInt() public view returns (int){
    return myInt;
  }
  function setMyInt(int newIntValue) public  {
    myInt = newIntValue;
  }
}