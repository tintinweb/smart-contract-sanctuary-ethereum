/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract BlockchainChat {
  struct Message {
    address waver;
    string content;
    uint timestamp;
  }

  Message[] messages;

  function sendMessage(string calldata _content) public {
    messages.push(Message(msg.sender, _content, block.timestamp));
  }

  function sendMes(string calldata _content) public {
  uint contentLength = bytes(_content).length;
  require(contentLength > 0, "Please provide a message!");
  messages.push(Message(msg.sender, _content, block.timestamp));
  }

  function gets() view public returns (Message[] memory) {
    return messages;
  }

}