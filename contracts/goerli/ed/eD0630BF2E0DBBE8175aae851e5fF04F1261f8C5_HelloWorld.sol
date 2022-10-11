pragma solidity >= 0.7.3;

contract HelloWorld {
    event UpdateMessages(string oldStr, string newStr);

    string public message;

    constructor(string memory inintMessage) {
        message = inintMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdateMessages(oldMsg, newMessage);
    }
}