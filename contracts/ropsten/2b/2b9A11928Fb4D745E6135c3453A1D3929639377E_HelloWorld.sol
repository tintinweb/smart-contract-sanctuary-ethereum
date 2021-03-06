// SDPX-License-Identifier: MIT

pragma solidity >= 0.7.3;

contract HelloWorld {
    event UdateMessages(string oldStr, string newStr);

    string public message;

    constructor (string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UdateMessages (oldMsg, newMessage);
    }
}