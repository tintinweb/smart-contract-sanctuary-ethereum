// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library MyLibrary {
  function add(uint256 a) external pure returns (uint256 number) {
    number = a++;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MyLibrary} from '../../src/Test_library.sol';

contract Ghost {
  uint256 public data;

  constructor(uint256 _data) {
    data = _data;
  }

  function increment(uint256 number) external {
    data = MyLibrary.add(number);
  }

  function boo() external pure returns (string memory) {
    return 'Boooooo!';
  }

  function baa() external pure returns (string memory) {
    return 'Baaaaaa!';
  }

  function test() external pure returns (string memory) {
    return 'THIS IS A TEST';
  }

  function doubleIncrement(uint256 number) external{
    data = MyLibrary.add(number * 2);
  }
}