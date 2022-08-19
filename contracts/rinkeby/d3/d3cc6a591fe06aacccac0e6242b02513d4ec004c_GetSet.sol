/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GetSet {
  uint256 public num;
  function setNumber(uint256 _num) external {
    num = _num;
  }
}