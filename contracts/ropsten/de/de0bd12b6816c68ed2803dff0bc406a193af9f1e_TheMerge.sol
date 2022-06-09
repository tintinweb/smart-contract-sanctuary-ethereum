// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

// Code from @m1guelpf:
// https://twitter.com/m1guelpf/status/1529340774286073857
// https://gist.github.com/m1guelpf/6d09b85d70a1dfd00d394b2acf789eeb
contract TheMerge {
  function hasMergeSucceeded() public view returns (bool) {
    return block.difficulty > 2**64;
  }
}