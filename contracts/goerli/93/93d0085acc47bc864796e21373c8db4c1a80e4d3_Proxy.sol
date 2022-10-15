/**
 *Submitted for verification at Etherscan.io on 2022-10-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract Proxy {
    address public owner;
    address public mpAddress;
    uint balance;

    constructor(address approver) {
        owner = msg.sender;
        mpAddress = approver;
    }

    function deposit() public payable {
        require(owner == msg.sender, "only sender can deposit!");
        balance += msg.value;
    }

    function transferTo(address receiver, uint amount) public {
        require(msg.sender == owner || msg.sender == mpAddress, "widthdrow can deposit only owner or mpAddress");
        require(balance >= amount, "insufficient balance");
        payable(receiver).transfer(amount);
        balance -= amount;
    }
}