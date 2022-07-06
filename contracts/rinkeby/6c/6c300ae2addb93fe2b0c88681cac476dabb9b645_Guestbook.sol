// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Guestbook {
    struct Message {
        address sender;
        string message;
    }

    Message[] messages;

    mapping(address => uint256) public lastMessagedAt;

    function message(string memory _message) public {
        require(
            lastMessagedAt[msg.sender] + 30 seconds < block.timestamp,
            "Wait 30 seconds"
        );

        lastMessagedAt[msg.sender] = block.timestamp;

        messages.push(Message(msg.sender, _message));
    }

    function getAllMessages() public view returns (Message[] memory) {
        return messages;
    }
}