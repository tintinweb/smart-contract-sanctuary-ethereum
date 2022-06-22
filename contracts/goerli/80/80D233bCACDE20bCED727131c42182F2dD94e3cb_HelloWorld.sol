// SPDX-License-Identifier: MIT
pragma solidity >= 0.7.3;

contract HelloWorld {
    // when the message is updated this event will be called
    event UpdatedMessages(string oldStr, string newStr);

    // keeps track of the current state of the message
    string public message;

    // when the contract is deployed for the first time the message state will be modified to initMessage
    constructor (string memory initMessage) {
        message = initMessage;
    }

    // when message is updated
    function Update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}