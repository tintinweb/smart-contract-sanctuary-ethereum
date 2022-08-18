/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ArgsTest {
  uint256 public num;

  constructor(uint256 _num) {
    num = _num;
  }

  function setNumber(uint256 _num) external {
    num = _num;
  }
  function getNumber() external view returns (uint256) {
    return num;
  }
}