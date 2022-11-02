// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Lock {
  uint256 private age;

    constructor(uint256 _age) {
      age = _age;
    }

    function setAge(uint256 _age) public {
         age = _age;
    }
}