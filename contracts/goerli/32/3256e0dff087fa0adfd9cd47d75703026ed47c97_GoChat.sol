/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.5;

contract GoChat {
    
    mapping(address => mapping(address => string[])) private messages;
    mapping(address => mapping(address => uint)) private messageCouns;

    function sendMessage(address toAddress, string memory message) public {
        messages[msg.sender][toAddress].push(message);
        messageCouns[msg.sender][toAddress] += 1;
    }

    function getMessage(address fromAddress, uint index) public view returns(string memory) {
        uint count = messageCouns[fromAddress][msg.sender];
        require(count >= 1, "the address doesn't have any message from a given address");
        require(index < count, "invalid index number");

        return messages[fromAddress][msg.sender][index];
    }

    function totalMessages(address fromAddress) public view returns(uint) {
        return messageCouns[fromAddress][msg.sender];
    }
}