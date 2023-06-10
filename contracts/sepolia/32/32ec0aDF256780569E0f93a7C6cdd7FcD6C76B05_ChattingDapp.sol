// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ChattingDapp {
  
  struct Message {
    address sender;
    address recipient;
    uint256 timestamp;
    string content;
  }

  mapping(address => Message[]) private sentMessages;
  mapping(address => Message[]) private receivedMessages;

  function sendMessage (address recipient, string memory message) public {
    Message memory newMessage = Message (msg.sender, recipient, block.timestamp, message);
    sentMessages[msg.sender].push(newMessage);
    receivedMessages[recipient].push(newMessage);
  }

  function getSentMessages () public view returns (Message[] memory) {
    return sentMessages[msg.sender];
  }

  function getReceivedMEssages () public view returns (Message[] memory) {
    return receivedMessages[msg.sender];
  }
}