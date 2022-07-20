// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity >= 0.8.9;

// Defines a contract named 'Hello World'
contract HelloWorld {

    // Emmited when update function is called
    event UpdatedMessages(string oldStr, string newStr);   

    // Declared a state variable 'message' of type 'string'
    string public message;

    constructor(string memory initMessage) {
        // Accepts a string argument 'initMessage' and set the value in the contract's 'message' store variable
        message = initMessage;
    }

    // A public function that accepts a string argument and update the 'message' store variable
    function update(string memory newMessage)  public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}