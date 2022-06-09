// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract TheMerge {
  function hasMergeSucceeded() public view returns (bool) {
    return block.difficulty > 2**64;
  }
}