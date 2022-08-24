// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

// Author: @avezorgen
contract Collector {
    mapping (address => uint) private lastTransactionFrom;
    address public owner;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        lastTransactionFrom[msg.sender] = msg.value;
    }    
    
    function MoneyIn() public payable {
        lastTransactionFrom[msg.sender] = msg.value;
    }

    function MoneyOut(uint value) public isOwner {
        payable(owner).transfer(value);
    }
    function getLastTransactionFrom(address from) view public returns (uint) {
        return lastTransactionFrom[from];
    }

    function getBalance() view public returns (uint) {
        return address(this).balance;
    }
}