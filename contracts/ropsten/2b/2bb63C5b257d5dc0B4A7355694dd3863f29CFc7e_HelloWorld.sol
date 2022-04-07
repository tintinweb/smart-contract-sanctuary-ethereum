//SPDX-License-Identifier: <SPDX-License>
pragma solidity>=0.7.3;

contract HelloWorld{
    event UpdatedMessages(string oldStr, string newStr);

    string public message;

    constructor(string memory initMesssage){
        message = initMesssage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}