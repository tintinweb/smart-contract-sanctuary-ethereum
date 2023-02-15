/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlockchainMessenger {
    
    struct Message {
        address sender;
        address receiver;
        string text;
        bytes32[] pictureHashes;
        bytes32[] videoHashes;
        uint timestamp;
        bool deleted;
    }

    mapping (uint => Message) private messages;
    uint private messageCount;
    
    event MessageSent(uint indexed messageId, address indexed sender, address indexed receiver, string text, bytes32[] pictureHashes, bytes32[] videoHashes, uint timestamp);
    event MessageDeleted(uint indexed messageId);
    
    function sendMessage(address receiver, string memory text, bytes32[] memory pictureHashes, bytes32[] memory videoHashes) public {
        require(msg.sender != receiver, "You cannot send a message to yourself");
        uint messageId = messageCount + 1;
        messages[messageId] = Message(msg.sender, receiver, text, pictureHashes, videoHashes, block.timestamp, false);
        messageCount++;
        emit MessageSent(messageId, msg.sender, receiver, text, pictureHashes, videoHashes, block.timestamp);
    }
    
    function deleteMessage(uint messageId) public {
        Message storage message = messages[messageId];
        require(msg.sender == message.sender || msg.sender == message.receiver, "You can only delete your own messages");
        require(!message.deleted, "This message has already been deleted");
        message.deleted = true;
        emit MessageDeleted(messageId);
    }
    
    function getMessage(uint messageId) public view returns (address, address, string memory, bytes32[] memory, bytes32[] memory, uint, bool) {
        Message storage message = messages[messageId];
        require(!message.deleted, "This message has been deleted");
        return (message.sender, message.receiver, message.text, message.pictureHashes, message.videoHashes, message.timestamp, message.deleted);
    }
    
    function updateMessageText(uint messageId, string memory newText) public {
        Message storage message = messages[messageId];
        require(msg.sender == message.sender, "You can only update messages you sent");
        require(!message.deleted, "This message has been deleted");
        message.text = newText;
    }
    
    function addPictureToMessage(uint messageId, bytes32 pictureHash) public {
        Message storage message = messages[messageId];
        require(msg.sender == message.sender || msg.sender == message.receiver, "You can only add pictures to your own messages");
        require(!message.deleted, "This message has been deleted");
        message.pictureHashes.push(pictureHash);
    }
    
    function addVideoToMessage(uint messageId, bytes32 videoHash) public {
        Message storage message = messages[messageId];
        require(msg.sender == message.sender || msg.sender == message.receiver, "You can only add videos to your own messages");
        require(!message.deleted, "This message has been deleted");
        message.videoHashes.push(videoHash);
    }
    
    function getMessageCount() public view returns (uint) {
        return messageCount;
    }
}