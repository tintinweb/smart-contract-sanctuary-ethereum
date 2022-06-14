// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

contract BubblehouseETHReceiver {
  event ETHReceived(address from, uint256 value, uint256 timestamp);

  address payable constant public beneficiary = payable(0xa500c2ab319C54ef4d3266508f9f215f72fD6a3a);

  receive() external payable {
    payable(beneficiary).transfer(msg.value);
    emit ETHReceived(msg.sender, msg.value, block.timestamp);
  }
}