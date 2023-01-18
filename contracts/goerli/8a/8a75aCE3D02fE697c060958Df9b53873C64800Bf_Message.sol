// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0;

contract Message {
    event UpdateMessage(string newMsg, string oldMsg);

    string public message;

    constructor(string memory _message) {
        message = _message;
    }

    function update(string memory _message) public {
        string memory oldMsg = message;
        message = _message;
        emit UpdateMessage(_message, oldMsg);
    }
}