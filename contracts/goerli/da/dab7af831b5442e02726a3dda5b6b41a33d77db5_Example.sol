// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

contract Example {
  uint256 public immutable a;

  constructor(uint256 a_) {
    a = a_;
  }
}