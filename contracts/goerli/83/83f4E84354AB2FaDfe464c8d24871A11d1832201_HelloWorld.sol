// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    // Emitted when update function is called
    event UpdatedMessages(string oldStr, string newStr);

    // Declare a state variable 'message' of type 'string'
    string public message;

    // Constructor function is executed once on contract creation
    // Constructors are used to initialize the contract's data
    constructor(string memory initMessage) {
        // Accepts string argument 'initMessage' and sets the value into the contract's 'message' storage variable
        message = initMessage;
    }

    // Public function that accepts a string argument and updates the 'message' storage variable
    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}