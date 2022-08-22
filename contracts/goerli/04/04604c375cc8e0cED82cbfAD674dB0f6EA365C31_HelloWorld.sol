/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

contract HelloWorld {
    string public message;

    event UpdateMessage(address indexed from, string oldStr, string newStr);

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function updateMessage(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdateMessage(msg.sender, oldMsg, newMessage);
    }
}