// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9;

contract HelloWorld {
    event UpdatedMessage(string oldStr, string newStr);

    string public message; // store permanently in blockchain that everyone can see it

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessage(oldMsg, newMessage);
    }
}