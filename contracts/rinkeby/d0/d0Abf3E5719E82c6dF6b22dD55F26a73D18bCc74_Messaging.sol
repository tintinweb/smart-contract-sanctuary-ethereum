//SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract Messaging {
    /* These events fire when a chat or a message sent to the chat is successful */
    event newChat(string chatName);
    event newMessage(string chatName, string chatMessage, uint256 time);

    struct Message {
        address sender;
        string chatName;
        string message;
        uint256 time;
    }

    //for each message sent to a chat it contains the sender and the message itself
    struct Chat {
        string chatName;
        uint256 created;
        uint256 messagesId;
    }

    //mapping is for matching a chat room name to the array of chat messages
    // mapping(string => Chat) public chatRoomToMessages;
    Chat[] private chatRoomsInfo;
    mapping(uint256 => Message[]) private IdToMessages;
    // string[] public chatNames;
    uint256 private messagesID;

    // function takes in a potential chatName parameter

    /* 
    First checking if the chat exits, and if it does, the transaction will be reverted  
    But if chat room name does exists, it'll create the room with initial welcome message from the creator 
    and frontend will recieve the event notification to implement the functionalities 
    */

    function createChat(string memory _chatName) external {
        Chat[] memory chatsInfo = chatRoomsInfo;
        for (uint256 i = 0; i < chatsInfo.length; i++) {
            if (
                keccak256(abi.encodePacked(chatsInfo[i].chatName)) ==
                keccak256(abi.encodePacked(_chatName))
            ) {
                revert("Chat room already Exists");
            }
        }

        chatRoomsInfo.push(Chat(_chatName, block.timestamp, messagesID));

        IdToMessages[messagesID].push(
            Message(
                msg.sender,
                _chatName,
                string.concat("Welcome to the ", _chatName, " chat"),
                block.timestamp
            )
        );
        // chatNames.push(_chatName);
        emit newChat(_chatName);
        messagesID++;
    }

    // function adds a message from a user to a chat they want to discuss on
    function addMessageToChat(string memory _chatName, string memory _message)
        external
    {
        Chat[] memory chatsInfo = chatRoomsInfo;
        uint256 messagesIdentification;
        for (uint256 i = 0; i < chatsInfo.length; i++) {
            if (
                keccak256(abi.encodePacked(chatsInfo[i].chatName)) ==
                keccak256(abi.encodePacked(_chatName))
            ) {
                messagesIdentification = chatsInfo[i].messagesId;
            }
        }
        uint256 time = block.timestamp;
        IdToMessages[messagesIdentification].push(
            Message(msg.sender, _chatName, _message, block.timestamp)
        );
        emit newMessage(_chatName, _message, time);
    }

    //this gets the messages from a chat room for display
    function getChatInfo() external view returns (Chat[] memory) {
        return chatRoomsInfo;
    }

    function getChat(string memory _chatName)
        external
        view
        returns (Message[] memory)
    {
        Chat[] memory chatsInfo = chatRoomsInfo;
        uint256 messagesIdentification;
        for (uint256 i = 0; i < chatsInfo.length; i++) {
            if (
                keccak256(abi.encodePacked(chatsInfo[i].chatName)) ==
                keccak256(abi.encodePacked(_chatName))
            ) {}
            messagesIdentification = chatsInfo[i].messagesId;
        }
        return IdToMessages[messagesIdentification];
    }

    /*   function getChatNames() external view returns (string[] memory) {
        return chatNames;
    } */
    /* function deleteMessages(string memory _chatName) external {
        delete(chatRoomToMessages[_chatName]);
    } */
}