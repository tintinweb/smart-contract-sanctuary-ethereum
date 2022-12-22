// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {
    // Balance of each account
    mapping(address => uint) public balances;

    // Deposit function
    function deposit(uint256 amount) public {
        // Update the balance of the sender
        balances[msg.sender] += amount;
    }

    // Withdraw function
    function withdraw(uint256 amount) public {
        // Check if the sender has enough balance
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Update the balance of the sender
        balances[msg.sender] -= amount;
    }

    // Transfer function
    function transfer(address payable recipient, uint256 amount) public {
        // Check if the sender has enough balance
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Update the balance of the sender and the recipient
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
    }
}