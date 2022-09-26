//SPDX-License-Identifier: MIT

pragma solidity >= 0.7.3;

contract HelloWorld {
    event UpdataMessages(string oldStr, string newStr);

    string public message;

    constructor (string memory insiMEssage){
        message = insiMEssage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdataMessages(oldMsg, newMessage);
    } 
}