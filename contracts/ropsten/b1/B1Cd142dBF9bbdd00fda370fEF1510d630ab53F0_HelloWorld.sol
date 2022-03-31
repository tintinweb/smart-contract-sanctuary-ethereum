/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// File: contracts\HelloWorld.sol

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract HelloWorld {
    event UpdatedMessages(string oldStr, string newStr);

    string public message;

    constructor (string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}