// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

// Author: throuz
contract FairGame {
    address payable public owner;
    uint seed;
    mapping(address => uint) public users;

    constructor() payable {
        owner = payable(msg.sender);
        seed = (block.timestamp + block.difficulty) % 100;
    }

    function deposit() public payable {
        users[msg.sender] += msg.value;
    }

    function bet(uint amount) public {
        require(amount < users[msg.sender]);
        seed = (block.difficulty + block.timestamp + seed) % 100;
        if (seed > 50) {
            users[msg.sender] += amount;
        } else {
            users[msg.sender] -= amount;
        }
    }

    function withdraw(uint amount) public {
        require(amount <= users[msg.sender]);
        users[msg.sender] -= amount;
        (bool success, ) = (msg.sender).call{value: amount}("");
        require(success);
    }

    function withdrawByOwner() public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }
}