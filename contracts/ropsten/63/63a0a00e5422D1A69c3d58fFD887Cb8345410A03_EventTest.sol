// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventTest {
  event Minted(address indexed _owner, uint256 indexed  _tokenid, bytes32 indexed  _background);
  function test(uint256 _tokenid) public {
      emit Minted(msg.sender, _tokenid, 0x20feefc1a5ac2e30b6b8cf926fb6df028a98666522440121640831c5f507dd03);
  }
}