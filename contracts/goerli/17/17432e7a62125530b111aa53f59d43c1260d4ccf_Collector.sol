/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

struct Message {
    string message;
    address owner;
    uint256 timestamp;
}

contract Collector {

    Message[] public messages;

    mapping(address => bool) taken;

    function insertMe(string memory message) public {
        require(!taken[msg.sender], "You already have a message");
        taken[msg.sender] = true;
        messages.push(Message(message, msg.sender, block.timestamp));
    }
    
}