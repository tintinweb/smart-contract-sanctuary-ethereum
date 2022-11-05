// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ChatApp {
    struct Message {
        uint256 timestamp;
        address authorAddress;
        string authorName;
        string message;
    }

    mapping(address => string) public users;
    Message[] public messages;

    event AssignUsername(string username);
    event NewMessage(Message message);

    constructor() {}

    function assignUsername(string calldata username) external {
        require(
            bytes(username).length >= 4 || bytes(username).length <= 12,
            "Username must be between 4 and 12 characters"
        );
        users[msg.sender] = username;
    }

    function sendMessage(string calldata text) external {
        require(bytes(users[msg.sender]).length != 0, "Username not set");

        messages.push(
            Message(block.timestamp, msg.sender, users[msg.sender], text)
        );
    }

    function getMessages() public view returns (Message[] memory) {
        return messages;
    }

    function hasUsername() public view returns (bool) {
        return bytes(users[msg.sender]).length != 0;
    }
}