// SPDX-License-Identifier: UNLICENSED

// Specifies the version of Solidity, using semantic versioning.
pragma solidity >=0.7.3;

// A contract named `HelloWorld`.
contract HelloWorld {
    // Emitted when update function is called
    event UpdatedMessages(string oldStr, string newStr);

    // state variable `message` of type `string`.
    string public message;

    constructor(string memory initMessage) {
        message = initMessage;
    }

    // updates the `message` storage variable.
    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}