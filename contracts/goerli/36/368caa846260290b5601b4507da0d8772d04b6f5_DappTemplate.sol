// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

contract DappTemplate {
  uint256 public x;
  uint256 public y;

  constructor(uint256 a, uint256 b) {
    x = a;
    y = b;
  }
}