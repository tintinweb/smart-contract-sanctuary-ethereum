// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

/// @title
/// @notice
contract ExampleContract {
  ///@notice Emits the block time
  address public immutable owner;

  ///@notice Emits the block time
  ///@param block block number
  event ReallyCoolEvent(uint256 indexed block);

  constructor() {
    owner = msg.sender;
  }

  ///@notice Emits the block time
  function callMe() external {
    emit ReallyCoolEvent(block.number);
  }
}