/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// A basic smart contract that stores a message
contract Message {
    // A state variable to store the message
    string public message;

    // A constructor to initialize the message
    constructor(string memory _message) {
        message = _message;
    }

    // A function to update the message
    function updateMessage(string memory _newMessage) public {
        message = _newMessage;
    }
}