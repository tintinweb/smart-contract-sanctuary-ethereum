// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GhostV2 {
  uint256 public data;

  constructor(uint256 _data) {
    data = _data;
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
import {Ghost} from '../tests/mocks/Ghost.sol';
import {GhostV2} from './GhostV2.sol';

contract MultiDeployment {
  uint256 public test;

  constructor(uint256 _test) {
    test = _test;
    bytes32 salt = keccak256('test');
    new Ghost(2);
    new Ghost{salt: salt}(3);
    new GhostV2(4);
    new GhostV2{salt: salt}(3);
  }

  function testDeployment() external {
    bytes32 salt = keccak256('test1');
    new Ghost(10);
    new Ghost{salt: salt}(11);
    new GhostV2(4);
  }
}

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