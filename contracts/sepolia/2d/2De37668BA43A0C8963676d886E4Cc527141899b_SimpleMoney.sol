// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SimpleMoney {
    mapping (address => uint) public ledger;

    function deposit() external payable {
        ledger[msg.sender] += msg.value;
    }

    function withdraw(uint amt) external {
        require(amt != 0, "amout can't be 0");
        uint sendable = amt > ledger[msg.sender] ? ledger[msg.sender] : amt;

        // security tip: make all changes to data in a smart contract before you interract with any other smart contract
        ledger[msg.sender] -= sendable;
        payable(msg.sender).transfer(sendable);
    }

}