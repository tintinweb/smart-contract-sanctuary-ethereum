// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract MyContract {
  function anotherMethod() public {
  }
  function myMethod(bool paramBool) public returns (bool){
    bool myBool = false;
    myBool = paramBool;
    return myBool;
  }
}