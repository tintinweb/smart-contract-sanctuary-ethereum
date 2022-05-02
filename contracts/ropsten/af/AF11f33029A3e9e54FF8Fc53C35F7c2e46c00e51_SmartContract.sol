pragma solidity >=0.7.3;

contract SmartContract {
    event UpdateMessage(string oldStr, string newStr);

    string public message;

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMessage = message;
        message = newMessage;
        emit UpdateMessage(oldMessage, newMessage);
    }
}