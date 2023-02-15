/**
 *Submitted for verification at Etherscan.io on 2023-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PhoneService {
    address public owner;
    mapping(address => uint) public balance;
    mapping(address => uint) public dataUsage;
    mapping(address => mapping(address => uint)) public callHistory;
    mapping(address => mapping(uint => string)) public messages;
    uint public callRate = 1 ether;
    uint public dataRate = 0.1 ether;

    event NewBalance(address indexed user, uint amount);

    constructor() {
        owner = msg.sender;
    }

    function addBalance() public payable {
        balance[msg.sender] += msg.value;
        emit NewBalance(msg.sender, msg.value);
    }

    function makeCall(address recipient, uint duration) public {
        uint cost = duration * callRate;
        require(balance[msg.sender] >= cost, "Insufficient balance.");
        require(duration <= 600, "Call duration cannot exceed 10 minutes.");

        balance[msg.sender] -= cost;
        balance[recipient] += cost;

        callHistory[msg.sender][recipient] += duration;
        callHistory[recipient][msg.sender] += duration;
    }

    function sendSMS(address recipient, string memory message) public {
        require(bytes(message).length <= 140, "Message length cannot exceed 140 characters.");
        require(balance[msg.sender] >= 1 ether, "Insufficient balance to send SMS.");

        uint messageId = block.timestamp;
        messages[recipient][messageId] = message;
        balance[msg.sender] -= 1 ether;
    }

    function checkDataUsage() public view returns (uint) {
        return dataUsage[msg.sender];
    }

    function useData(uint amount) public {
        uint cost = amount * dataRate;
        require(balance[msg.sender] >= cost, "Insufficient balance to use data.");
        dataUsage[msg.sender] += amount;
        balance[msg.sender] -= cost;
    }

    function getCallHistory(address user, address recipient) public view returns (uint) {
        return callHistory[user][recipient];
    }

    function readMessage(address recipient, uint messageId) public view returns (string memory) {
        return messages[recipient][messageId];
    }

    function transferBalance(address recipient, uint amount) public {
        require(balance[msg.sender] >= amount, "Insufficient balance to transfer.");
        require(recipient != address(0), "Invalid recipient address.");

        balance[msg.sender] -= amount;
        balance[recipient] += amount;
    }

    function withdrawBalance(uint amount) public {
        require(msg.sender == owner, "Only contract owner can withdraw balance.");
        require(balance[msg.sender] >= amount, "Insufficient balance to withdraw.");

        balance[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }
}