//SPDX-License-Identifier: ISC
pragma solidity ^0.8.4;

contract MessageBox {

    struct Message {
      uint index; 
      uint content;
      address author;
      uint timestamp;
    }

    event MessageAdded(
        uint index,
        uint content,
        address author,
        uint timestamp
    );

    uint public messageCounter = 0;
    mapping(uint => Message) public messages;

    constructor(uint _firstMessageContent) {
        addMessage(_firstMessageContent);
    }

    function getMessage(uint _index) public view returns (Message memory) {
        return messages[_index];
    }

    function getAllMessages() public view returns (Message[] memory) {
        Message[] memory messageArray = new Message[](messageCounter);
        for (uint i = 0; i < messageCounter; i++) {
            messageArray[i] = messages[i];
        }
        return messageArray;
    }

    function addMessage(uint _content) public {
        messages[messageCounter] = Message(messageCounter, _content, msg.sender, block.timestamp);
        emit MessageAdded(messageCounter, _content, msg.sender, block.timestamp);
        messageCounter++;
    }
}