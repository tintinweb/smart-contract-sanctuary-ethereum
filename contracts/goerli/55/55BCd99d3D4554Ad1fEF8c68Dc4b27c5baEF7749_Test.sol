//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Test {
  uint[] public array;
  uint public arrayLength;

  function setArrayElement(uint index, uint value) public {
    require(index < arrayLength, "Index out of bounds");
    array[index] = value;
  }

  function getLargerValue(uint a, uint b) public pure returns (uint) {
    return a > b ? a : b;
  }
}