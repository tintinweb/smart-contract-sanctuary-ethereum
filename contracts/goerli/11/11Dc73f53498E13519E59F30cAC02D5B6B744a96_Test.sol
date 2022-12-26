// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Test {
  uint[] array;

  function getArrayLength() public view returns (uint) {
    return array.length;
  }

  function setArrayElementPush(uint value) public {
    array.push(value);
  }

  function getLargerNumber(uint a, uint b) public pure returns (uint) {
    return a > b ? a : b;
  }
}