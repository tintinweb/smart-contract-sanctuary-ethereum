pragma solidity >=0.8.9;

contract HelloWorld {
    event MessageUpdated(string oldStr, string newStr);

    string public message;

    constructor(string memory initialMessage) {
        message = initialMessage;
    }

    function update(string memory newStr) public {
        string memory oldMessage = message;
        message = newStr;
        emit MessageUpdated(oldMessage, newStr);
    }
}