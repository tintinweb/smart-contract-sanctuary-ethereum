// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Variable {

  uint256 public x;

  constructor(uint256 initValue){
    x = initValue;
  }

  function increase() public{
    x=x+1;
  }
  function decrease() public{
    x=x-1;
  }


}