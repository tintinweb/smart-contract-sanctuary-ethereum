// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Initializable.sol";

contract BoxV1 is Initializable {
  // these state variables and their values
  // will be preserved forever, regardless of upgrading
  uint public width;
  uint public length;

  function initialize(uint _length, uint _width) public initializer {
    length = _length;
    width = _width;
  }
  
  function area() public view returns(uint) {
    return length * width;
  }
}