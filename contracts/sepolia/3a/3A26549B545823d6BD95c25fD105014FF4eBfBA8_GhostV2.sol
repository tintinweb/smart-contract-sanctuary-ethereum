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