// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

contract HelloWorld {
    event UpgradeMessages(string oldMessage, string newMessage);

    string public message;

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function upgrade(string memory newMessage) public {
        string memory oldMessage = message;
        message = newMessage;
        emit UpgradeMessages(oldMessage, message);
    }
}