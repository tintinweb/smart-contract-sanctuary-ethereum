// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

contract Counter {
  uint256 public num;

  constructor(uint256 _startNum) {
    num = _startNum;
  }

  function incraese(uint256 _num) external {
    num += _num;
  }

  function decrease(uint256 _num) external {
    num += _num;
  }
}