// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Foo {
  uint public x = 1;

  function getChainId() public view returns (uint) {
    return block.chainid;
  }
}