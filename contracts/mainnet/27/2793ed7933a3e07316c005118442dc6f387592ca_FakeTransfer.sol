// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @notice FakeTransfer event emits the current block number. This is just used for testing.
contract FakeTransfer {
  event Transfer(address indexed from, address indexed to, uint);

  function fakeTransfer() public returns(uint) {
    emit Transfer(msg.sender, address(this),  block.number);
    return block.number;
  }
}