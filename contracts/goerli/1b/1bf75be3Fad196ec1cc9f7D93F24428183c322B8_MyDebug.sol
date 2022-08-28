// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract MyDebug {
  function getNow() external view returns (uint256 nowTimestamp, uint256 nowBlock) {
    nowTimestamp = block.timestamp;
    nowBlock = block.number;
  }
}