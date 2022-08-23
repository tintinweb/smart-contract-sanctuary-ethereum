// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract HolaMundo{
    event UpdatedMessages(string oldMsg, string newMsg);

    string public message;

    constructor(string memory initMessage){
        message = initMessage;
    }

    function update(string memory newMassage) public{
        string memory oldMsg = message;
        message = newMassage;
        emit UpdatedMessages(oldMsg, newMassage);
    }
}