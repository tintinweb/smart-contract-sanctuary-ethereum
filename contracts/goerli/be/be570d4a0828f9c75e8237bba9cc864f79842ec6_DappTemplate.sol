// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

contract DappTemplate {
  uint256 public immutable a;
  uint256 public immutable b;

  constructor(uint256 a_, uint256 b_) {
    a = a_;
    b = b_;
  }
}