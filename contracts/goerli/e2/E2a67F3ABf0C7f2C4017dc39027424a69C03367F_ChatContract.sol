/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ChatContract {
    struct Messages {
        address from;
        address to;
        string message;
    }

    mapping(address => Messages[]) private messages;

    event NewMessage(address from, address to, string message);

    function sendMessage(address to, string memory _message) public {
        Messages memory newMessage = Messages(msg.sender, to, _message);
        messages[msg.sender].push(newMessage);
        messages[to].push(newMessage);
        emit NewMessage(msg.sender, to, _message);
    }

    function getMessages(address user) public view returns (Messages[] memory) {
        return messages[user];
    }
}