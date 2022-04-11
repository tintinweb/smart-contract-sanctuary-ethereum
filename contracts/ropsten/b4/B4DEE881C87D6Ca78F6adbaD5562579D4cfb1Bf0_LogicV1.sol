// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

contract LogicV1 {
  uint256 internal foo;

  function set(uint256 _foo) external {
    foo = _foo;
  }

  function get() external view returns (uint256) {
    return foo;
  }
}