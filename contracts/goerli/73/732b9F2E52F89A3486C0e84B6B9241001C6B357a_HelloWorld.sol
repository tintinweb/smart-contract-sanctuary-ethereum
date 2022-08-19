// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.3;

contract HelloWorld {

    event UpdateMessages(string OldStr, string newStr);

    string public message;

    constructor(string memory _message) {
        message = _message;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdateMessages(oldMsg, newMessage);
    }
}