//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import { OpenAave } from './OpenAave.sol';

interface IBrige {
  function depositEth(
    uint256 gasLimit,
    bytes calldata message
  ) external payable;

  function depositEthTo(
    address to,
    uint256 gasLimit,
    bytes calldata message
  ) external payable;
}

interface IMessageSender {
  function sendMessage(address, bytes memory, uint256) external returns (uint256);
}

contract L1OpenBridge {
   IMessageSender messageSender;
   IBrige bridge;

   event OpenOnL2(address sender, address action, uint256 amount);

  constructor() {
    bridge = IBrige(0x636Af16bf2f682dD3109e60102b8E1A089FedAa8);
    messageSender = IMessageSender(0x5086d1eEF304eb5284A0f6720f79403b4e9bE294);
  }
  function openOnL2(address l2Action, uint256 l2gasLimit, bytes calldata message) public payable {
    uint256 balance = msg.value;
    emit OpenOnL2(msg.sender, l2Action, balance); 

    bridge.depositEthTo{value: balance}(l2Action, 1920000, message);
    messageSender.sendMessage(l2Action, message, l2gasLimit);
  }
}