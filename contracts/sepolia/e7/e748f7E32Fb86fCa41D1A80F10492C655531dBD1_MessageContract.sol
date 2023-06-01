/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MessageContract {
    struct Message {
        string jsonMessage;
        address sender;
    }
    
    mapping(uint256 => Message) private messages;
    uint256 private messageId;
    
    event MessageSent(uint256 indexed messageId, string jsonMessage, address sender);
    
    function sendMessage(string memory _jsonMessage) external {
        messageId++;
        messages[messageId] = Message(_jsonMessage, msg.sender);
        
        emit MessageSent(messageId, _jsonMessage, msg.sender);
    }
    
    function getMessage(uint256 _messageId) external view returns (string memory, address) {
        Message storage message = messages[_messageId];
        return (message.jsonMessage, message.sender);
    }
}