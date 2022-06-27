// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract HelloWorld {

    event UdpateMessages(string oldStr, string newStr);

    string public message;

    constructor (string memory initMessage) {
        message = initMessage;
    }

    function update (string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UdpateMessages(oldMsg, newMessage);
    }

}