/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT


contract FeeCollector { // 0xdea2DC218E53C4B59B7bAb1495e75e85C65C549f
    address public owner;
    uint256 public balance;
    
    constructor () {
        owner = msg.sender;
    }

    receive () payable external {
        balance += msg.value;

    }

    function withdraw(uint amount, address payable destAddr) private {
        require (msg.sender == owner, "Only owner can withdraw");

        destAddr.transfer(amount);
        balance -= amount;
    }
}