// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

// Author: @avezorgen
contract Collector {
    mapping (address => uint) private lastTransactionFrom;
    address public owner;

    constructor() {
        owner = msg.sender;
    }
    
    function MoneyIn() public payable {
        lastTransactionFrom[msg.sender] = msg.value;
    }

    function MoneyOut(uint value) public {
        require(msg.sender == owner, "You aren't the owner");
        payable(owner).transfer(value);
    }

    function GETlastTransactionFrom(address from) view public returns (uint) {
        return lastTransactionFrom[from];
    }

    function getBalance() view public returns (uint) {
        return address(this).balance;
    }
}