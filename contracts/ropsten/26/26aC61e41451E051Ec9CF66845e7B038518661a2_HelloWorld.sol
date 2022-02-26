//SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

contract HelloWorld {
    event UpdatedMessages(string oldMessage, string newMessage);

    string public message;

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function setMessage(string memory newMessage) public {
        emit UpdatedMessages(message, newMessage);
        message = newMessage;
    }
}