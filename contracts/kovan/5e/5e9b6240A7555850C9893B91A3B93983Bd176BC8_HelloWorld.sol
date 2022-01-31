pragma solidity ^0.7.0;

contract HelloWorld {

    event UpdatedMessages(string oldStr, string newStr);

    string public message;

    constructor (string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldmsg = message;
        message = newMessage;
        emit UpdatedMessages(oldmsg, newMessage);
    }
}