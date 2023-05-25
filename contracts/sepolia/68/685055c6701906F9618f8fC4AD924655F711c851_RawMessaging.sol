/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract RawMessaging {
    string private message;

    constructor(string memory _message) {
        require(bytes(_message).length > 0, "Set an initial message!");
        message = _message;
    }

    function updateMessage(string calldata _newMessage) external {
        require(bytes(_newMessage).length > 0, "Set a new message!");
        message = _newMessage;
    }

    function readMessage() view external returns(string memory) {
        return message;
    } 
}