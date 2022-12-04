/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract MyEthDepositContract {
    // The current balance of the contract
    uint256 public balance;

    // A mapping that tracks the balance of each wallet
    mapping(address => uint256) public walletBalances;

    // The event that is emitted when ETH is deposited
    event Deposit(address indexed _from, uint256 _value);

    // The event that is emitted when ETH is withdrawn
    event Withdrawal(address indexed _to, uint256 _value);

    // Deposit ETH to the contract
    function deposit() public payable {
        // Update the contract's balance
        balance += msg.value;

        // Update the balance of the wallet that deposited the ETH
        walletBalances[msg.sender] += msg.value;

        // Emit the Deposit event
        emit Deposit(msg.sender, msg.value);
    }

    // Withdraw ETH from the contract
    function withdraw(uint256 _amount) public {
        // Convert the specified amount of ETH to Wei
        uint256 amountInWei = _amount * 1 ether;

        // Reject withdrawal requests that exceed the wallet's balance
        require(
            walletBalances[msg.sender] >= amountInWei,
            "Insufficient funds"
        );

        // Transfer the requested amount of ETH to the wallet that made the withdrawal request
        msg.sender.transfer(amountInWei);

        // Update the contract's balance
        balance -= amountInWei;

        // Update the balance of the wallet that withdrew the ETH
        walletBalances[msg.sender] -= amountInWei;

        // Emit the Withdrawal event
        emit Withdrawal(msg.sender, amountInWei);
    }
}