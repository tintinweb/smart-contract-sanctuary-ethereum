/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

contract FeeCollector {
    address public owner;
    uint256 public balance;

    constructor() public{
        owner = msg.sender;
    }

    receive() payable external{
        balance+=msg.value;
    }

    function withdraw(uint256 amount, address payable destAddress) public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(amount <= balance, "Insufficient funds");

        destAddress.transfer(amount);
        balance-=amount;
    }
}