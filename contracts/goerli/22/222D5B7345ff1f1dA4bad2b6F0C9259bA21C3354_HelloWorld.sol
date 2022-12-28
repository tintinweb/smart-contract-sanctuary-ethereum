// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.17;

contract HelloWorld {
    event UpdateMessages(string oldStr, string newStr);

    string public message; //anybody can access once deployed on blockchain

    //when this contract is deployed its required to pass as argument a string
    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update (string memory newMessage) public {
        string memory oldMessage = message;
        message = newMessage;
        emit UpdateMessages(oldMessage, newMessage);
    } 

}