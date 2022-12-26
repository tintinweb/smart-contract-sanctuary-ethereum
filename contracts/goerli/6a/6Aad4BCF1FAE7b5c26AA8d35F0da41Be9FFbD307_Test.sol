// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
  uint[] array;

  function setName(uint _num) public {
    array.push(_num);
  }

  function getLength() public view returns(uint) {
    return array.length;
  }

  function getBigger(uint _a, uint _b) public pure returns(uint){
    if(_a>_b){
      return _a;
    }
    return _b;
  }
}