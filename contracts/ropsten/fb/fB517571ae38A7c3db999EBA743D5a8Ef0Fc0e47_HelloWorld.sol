// SPDX-License-Identifier: MIT

pragma solidity >= 0.7.3;

contract HelloWorld
{
    event UpdatedMessages(string oldStr, string newStr);

    string public message;
    
    constructor (string memory initMessage)
    {
        message = initMessage;
    }

    function update(string memory newMessage) public
    {
        emit UpdatedMessages(message, newMessage);
        message = newMessage;
    }
}