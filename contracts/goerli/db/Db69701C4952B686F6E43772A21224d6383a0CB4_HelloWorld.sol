// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract HelloWorld {
    event UpdateMessage(string oldMessage, string newMessage);

    string public message;

    constructor(string memory initialMessage) {
        message = initialMessage;
    }

    function update(string memory _message) public {
        string memory oldMessage = message;
        message = _message;
        emit UpdateMessage(oldMessage, _message);
    }
}