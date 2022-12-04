/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.4.25;

contract DepositWithdraw {
    // Mapping to store the balance of each wallet address
    mapping(address => uint256) public balances;

    // Function to deposit ETH into the contract
    function deposit() public payable {
        // Store the amount of ETH being deposited in a variable
        uint256 amount = msg.value;

        // Add the amount of ETH to the balance of the wallet that made the deposit
        balances[msg.sender] += amount;
    }

    // Function to withdraw ETH from the contract
    function withdraw() public payable {
        // Store the amount of ETH the wallet is trying to withdraw in a variable
        uint256 amount = msg.value;

        // Check if the wallet has enough ETH to withdraw
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Subtract the amount of ETH from the wallet's balance
        balances[msg.sender] -= amount;

        // Send the ETH to the wallet
        msg.sender.transfer(amount);
    }

    // Function to withdraw ETH to another wallet
    function withdrawTo(address _to) public payable {
        // Store the amount of ETH the wallet is trying to withdraw in a variable
        uint256 amount = msg.value;

        // Check if the wallet has enough ETH to withdraw
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Subtract the amount of ETH from the wallet's balance
        balances[msg.sender] -= amount;

        // Send the ETH to the specified wallet
        _to.transfer(amount);
    }
}