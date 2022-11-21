// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract NumSetter {
  event NumSet(uint256 n);

  uint256 public n;

  constructor(uint256 num) {
    n = num;
  }

  function setNum(uint256 num) external {
    n = num;
    emit NumSet(num);
  }
}