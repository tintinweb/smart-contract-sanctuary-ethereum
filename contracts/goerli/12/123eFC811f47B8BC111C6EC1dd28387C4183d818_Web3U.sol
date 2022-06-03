//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract Web3U {
    // 1. we want to have a message
    string public message;

    // 2. we want to set a message everytime the contract is run
    constructor(string memory _initMessage) {
        message = _initMessage;
    }

    event UpdatedMessages(string oldStr, string newStr);

    // 3. we want to be able to update a message
    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        // 4. we want to make a message update event
        emit UpdatedMessages(oldMsg, newMessage);
    }
}