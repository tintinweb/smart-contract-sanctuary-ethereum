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

    function len() public view returns (uint256) {
        return messages.length;
    }
    
}


contract Sender {
    function sendMultiple(address[] calldata receivers) public payable {
        require(msg.value % receivers.length == 0, "Uneven amount");
        uint256 amountWei = msg.value / receivers.length;

        for (uint256 i = 0; i < receivers.length; i++) {
            payable(receivers[i]).transfer(amountWei);
        }
    }
}