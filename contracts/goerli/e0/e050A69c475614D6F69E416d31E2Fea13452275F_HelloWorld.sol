/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

contract HelloWorld {

    event UpdatedMessage(string oldString, string newString);

    string public message;

    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessage(oldMsg, newMessage);
    }

}