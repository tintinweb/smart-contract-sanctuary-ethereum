// SPDX-License-Identifier: MIT
pragma solidity = 0.5.15;

contract HelloWorld {

    event UpdatedMessages(string oldStr, string newStr);

    string public message;


    constructor(string memory initMessage ) public {
        message = initMessage;
    }

    function update(string memory newMessage)  public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}