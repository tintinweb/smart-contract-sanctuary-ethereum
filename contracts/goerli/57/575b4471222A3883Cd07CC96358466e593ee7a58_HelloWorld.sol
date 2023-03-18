// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.18;

contract HelloWorld{
    event UpdatedMessages(string oldString, string newString);

    string public message;

    constructor (string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMessage = message;
        message = newMessage;
        emit UpdatedMessages(oldMessage, message);
    }
}