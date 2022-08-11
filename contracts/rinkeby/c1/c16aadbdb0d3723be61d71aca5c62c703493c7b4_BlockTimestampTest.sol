/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlockTimestampTest {
  uint256 public blockNumber;
  uint256 public blockTimestamp;

  function save() external {
    blockNumber = block.number;
    blockTimestamp = block.timestamp;
  }
}