/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Array {
  uint[] private arr;

  function pushElement(uint _element) public { arr.push(_element); }
  function popElement() public { arr.pop(); }

  function returnArr() public view returns (uint[] memory) { return arr; }
  function getLength() public view returns (uint) { return arr.length; }

  modifier checkRange(uint _index) { require( _index < arr.length, "the number entered is out of bound" ); _; }

  function getElement(uint _index) public view checkRange(_index) returns (uint) { return arr[_index]; }

  // length of array remains the same
  function deleteElement(uint _index) public checkRange(_index) {  delete arr[_index]; }

  function replaceLast(uint _index) internal checkRange(_index) {
    arr[_index] = arr[arr.length - 1];
    arr.pop();
  }

  function replaceLastT1() external {
    arr = [1, 2, 3, 4];
    replaceLast(1);
    // [1, 4, 3]
    assert(arr[0] == 1);
    assert(arr[1] == 4);
    assert(arr[2] == 3);
    assert(arr.length == 3);
  }

  function replaceLastT2() external {
    arr = [1, 4, 3];
    replaceLast(2);
    // [1, 4]
    assert(arr[0] == 1);
    assert(arr[1] == 4);
    assert(arr.length == 2);
  }

  function replaceLastT3() external {
    arr = [1];
    replaceLast(0);
    // []
    assert(arr.length == 0);
  }

  function arrShift(uint _index) internal checkRange(_index) {
    for ( uint i = _index; i < arr.length - 1; i++ ) {
      arr[i] = arr[i + 1];
    }
    arr.pop();
  }

  function arrShiftT1() external {
    arr = [1, 2, 3, 4];
    arrShift(1);
    // [1, 3, 4]
    assert(arr[0] == 1);
    assert(arr[1] == 3);
    assert(arr[2] == 4);
    assert(arr.length == 3);
  }

  function arrShiftT2() external {
    arr = [1, 4, 3];
    arrShift(2);
    // [1, 4]
    assert(arr[0] == 1);
    assert(arr[1] == 4);
    assert(arr.length == 2);
  }

  function arrShiftT3() external {
    arr = [1];
    arrShift(0);
    // []
    assert(arr.length == 0);
  }
}