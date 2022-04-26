// SPDX-License-Identifier: MIT

pragma solidity  >= 0.7.3;

contract HelloWorld {
    // An event to broadcast when the state changes
    event UpdatedMessages(string oldStr, string newStr);

    string public message;

    // Only called once when the smart contract is deployed
    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMessage = message;
        message = newMessage;
        emit UpdatedMessages(oldMessage, newMessage);
    }
}