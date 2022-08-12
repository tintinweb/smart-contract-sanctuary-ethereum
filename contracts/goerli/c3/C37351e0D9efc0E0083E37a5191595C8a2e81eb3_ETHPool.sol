/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

contract ETHPool {

    struct User {
        address _address;
        uint _balance;
    }

    address public team;
    User[] participants;
    mapping(address => uint) idx;

    constructor() {
        team = msg.sender;
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        require(msg.value > 0, "No balance.");
        if (idx[msg.sender] == 0) {
            idx[msg.sender] = participants.length + 1;
            participants.push(User(msg.sender, msg.value));
        }
        else {
            participants[idx[msg.sender]-1]._balance += msg.value;
        }
    }

    function withdrawAll() external {
        require(idx[msg.sender] > 0, "No participated.");
        payable(msg.sender).transfer(participants[idx[msg.sender]-1]._balance);
    }

    function withdraw(uint _amount) external {
        require(idx[msg.sender] > 0, "No participated.");
        require(_amount <= participants[idx[msg.sender]-1]._balance, "Amount exceed user balance.");
        participants[idx[msg.sender]-1]._balance -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function depositRewards() external payable {
        require(msg.sender == team, "Only team can deposit rewards.");
        uint balance = address(this).balance - msg.value;
        require(balance > 0, "No diposit yet.");
        for (uint i = 0; i < participants.length; i ++) {
            participants[i]._balance += msg.value * participants[i]._balance / balance;
        }
    }
}