/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

contract BlockchainChat {
  event NewMessage(address indexed from, uint timestamp, string message);

  struct Message {
    address waver;
    string content;
    uint timestamp;
  }

  Message[] messages;

  function sendMessage(string calldata _content) public {
    // TODO: add a require so if there is no message: fuck off
    messages.push(Message(msg.sender, _content, block.timestamp));
    emit NewMessage(msg.sender, block.timestamp, _content);
  }

  function getMessages() view public returns (Message[] memory) {
    return messages;
  }
}