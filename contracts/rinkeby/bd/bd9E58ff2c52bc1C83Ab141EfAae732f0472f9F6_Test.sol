// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract Test {
  
  struct Test {
    address user;
    uint256 age;
  }

  mapping(uint256 => Test) tests;

  function set(uint256 a) external {
    tests[a] = Test({
      user: msg.sender,
      age: 1
    });
  }

  function get(uint256 a) external view returns(Test memory) {
    return tests[a];
  }
}