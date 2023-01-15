// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract HelloWorld {
    mapping(address => string[]) public messages;
    event listMessages(string[]);
    function setMessage(string memory newMessage) public {
        messages[msg.sender].push(newMessage);
        emit listMessages(messages[msg.sender]);
    }

    function getMessages(address user) public view returns (string[] memory) {
        return messages[user];
    }
}