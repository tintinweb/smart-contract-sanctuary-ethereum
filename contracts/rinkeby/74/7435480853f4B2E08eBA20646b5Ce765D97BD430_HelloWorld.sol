//SPDX-License-Identifier: MIT

pragma solidity >=0.4.0 <0.9.0;

contract HelloWorld {
    event UpdatedMessage(string oldString, string newString);

    string public message;

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        emit UpdatedMessage(message, newMessage);
        message = newMessage;
    }
}