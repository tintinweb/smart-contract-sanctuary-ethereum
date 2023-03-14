/**
 *Submitted for verification at Etherscan.io on 2023-03-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ChatContract {
    struct Message {
        address from;
        string message;
    }

    mapping(address => Message[]) private userMessages;
    mapping(address => uint256) private messageCount;

    event NewMessage(address indexed from, address indexed to, string message);

    function sendMessage(address recipient, string memory message) public {
        require(recipient != msg.sender, "Cannot send message to yourself");
        Message memory newMessage = Message(msg.sender, message);
        userMessages[msg.sender].push(newMessage);
        messageCount[msg.sender]++;
        userMessages[recipient].push(newMessage);
        messageCount[recipient]++;
        emit NewMessage(msg.sender, recipient, message);
    }

    function getMessages() public view returns (Message[] memory) {
        return userMessages[msg.sender];
    }

    function getMessagesForUser(address user) public view returns (Message[] memory) {
        return userMessages[user];
    }
}