/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract FistContract {
  uint256 public num;

  function increase(uint256 _num) public {
    num = _num;
  }
}