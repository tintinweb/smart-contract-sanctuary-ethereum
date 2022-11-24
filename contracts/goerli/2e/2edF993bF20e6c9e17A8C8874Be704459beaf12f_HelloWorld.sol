// SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.8.17;

contract HelloWorld
{
    event UpdateMessages(string oldStr, string newStr);

    string public message; // all people on blockchain can access it

    // run only one when the contract is deploy
    constructor (string memory initMessage)  
    {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdateMessages(oldMsg, newMessage);
    }


}