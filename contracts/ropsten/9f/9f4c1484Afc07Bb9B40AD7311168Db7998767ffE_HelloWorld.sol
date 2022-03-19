// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract HelloWorld {
    event UpdatedMessages(string oldStr, string newStr);

    // State variable - stored in contract storage.
    // Public - accessible from outside contract, getter auto-generated.
    string public message;

    // Memory variable - temporary, erased between external function calls. 
    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMessage = message;
        message = newMessage;
        emit UpdatedMessages(oldMessage, newMessage);
    }
}