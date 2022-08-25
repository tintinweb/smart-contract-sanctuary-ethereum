// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.9;

contract HelloWorld {
    event UpdatedMessages(string oldStr, string newStr);

    string public message;
    
    constructor(string memory _initMessage) {
        message = _initMessage;
    }

    function update(string memory _newMessage) public {
        string memory oldMsg = message;
        message = _newMessage;
        emit UpdatedMessages(oldMsg, _newMessage);
    }
}