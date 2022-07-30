/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Contract {
  int private count = 0;

  function inc() public {
    count += 1;
  }
  function dec() public {
    count -= 1;
  }
  function get() public view returns (int) {
    return count;
  }
}