// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    event UpdateMessage(string odlStr, string newStr);

    string public message;

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMessage = message;
        message = newMessage;
        emit UpdateMessage(oldMessage, newMessage);
    }
}