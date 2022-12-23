/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ChristmasMessages {
    // The address of the contract owner
    address public owner;

    // A mapping from addresses to messages
    mapping(address => string) public messages;

    // A list of recipients
    address[] public recipients;

    // The constructor sets the owner of the contract
    constructor() {
        owner = msg.sender;
    }

    // The owner can add a recipient to the contract
    function addRecipient(address _recipient) public {
        require(msg.sender == owner, "Only the owner can add recipients.");
        recipients.push(_recipient);
    }

    // The owner can send a message to a recipient
    function sendMessage(address _recipient, string memory _message) public {
        require(msg.sender == owner, "Only the owner can send messages.");
        require(isRecipient(_recipient), "The recipient is not on the list.");
        messages[_recipient] = _message;
    }

    // A recipient can view their message on December 25th
    function viewMessage() public view returns (string memory) {
        require(block.timestamp >= 1609459200 && block.timestamp <= 1609546399, "It is not Christmas yet.");
        return messages[msg.sender];
    }

    // A helper function to check if an address is a recipient
    function isRecipient(address _recipient) private view returns (bool) {
        for (uint i = 0; i < recipients.length; i++) {
            if (recipients[i] == _recipient) {
                return true;
            }
        }
        return false;
    }
}