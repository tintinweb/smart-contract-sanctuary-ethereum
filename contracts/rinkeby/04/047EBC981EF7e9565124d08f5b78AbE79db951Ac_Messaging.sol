//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Messaging {
    /* These events fire when a chat or a message sent to the chat is successful */
    event newChat(string chatName);
    event newMessage(string chatName, string chatMessage, uint256 time);

    //for each message sent to a chat it contains the sender and the message itself
    struct Messages {
        address sender;
        string chatName;
        string message;
        uint256 time;
    }

    //mapping is for matching a chat room name to the array of chat messages
    mapping(string => Messages[]) public chatRoomToMessages;
    string[] public chatNames;

    // function takes in a potential chatName parameter

    /* 
    First checking if the chat exits, and if it does, the transaction will be reverted  
    But if chat room name does exists, it'll create the room with initial welcome message from the creator 
    and frontend will recieve the event notification to implement the functionalities 
    */

    function createChat(string memory _chatName) external {
        if (chatRoomToMessages[_chatName].length > 0) {
            revert("Chat room already Exists");
        }
        chatRoomToMessages[_chatName].push(
            Messages(
                msg.sender,
                _chatName,
                string.concat("Welcome to the ", _chatName, " chat"),
                block.timestamp
            )
        );
        chatNames.push(_chatName);
        emit newChat(_chatName);
    }

    // function adds a message from a user to a chat they want to discuss on
    function addMessageToChat(string memory _chatName, string memory _message)
        external
    {
        uint256 time = block.timestamp;
        chatRoomToMessages[_chatName].push(
            Messages(msg.sender, _chatName, _message, time)
        );
        emit newMessage(_chatName, _message, time);
    }

    //this gets the messages from a chat room for display
    function getChatMessages(string memory _chatName)
        external
        view
        returns (Messages[] memory)
    {
        return chatRoomToMessages[_chatName];
    }

    function getChatNames() external view returns (string[] memory) {
        return chatNames;
    }

    /* function deleteMessages(string memory _chatName) external {
        delete(chatRoomToMessages[_chatName]);
    } */
}