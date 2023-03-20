//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SmartSaver {
    // Map the balances of users to their addresses
    mapping(address => uint) balances;

    // Define the events emitted by the contract
    event Deposit(address indexed user, uint amount);
    event Withdrawal(address indexed user, uint amount);

    // Allow users to deposit Ether into the contract
    function deposit() public payable {
        // Increase the user's balance by the deposited amount
        balances[msg.sender] += msg.value;
        // Emit a Deposit event
        emit Deposit(msg.sender, msg.value);
    }

function withdraw(uint amount) public {
    // Ensure the user has enough balance to withdraw the requested amount
    require(balances[msg.sender] >= amount, "Insufficient balance");

    // Ensure that the one hour time lock has elapsed
    require(block.timestamp >= balances[msg.sender] + 3600, "Withdrawal time lock has not expired");

    // Decrease the user's balance by the requested amount
    balances[msg.sender] -= amount;

    // Transfer the requested amount to the user with a gas limit
    (bool success, ) = payable(msg.sender).call{value: amount, gas: 2300}("");
    // Ensure the transfer was successful
    require(success, "Transfer failed.");

    // Emit a Withdrawal event
    emit Withdrawal(msg.sender, amount);
}
    // Allow users to check their current balance
    function getBalance() public view returns (uint) {
        return balances[msg.sender];
    }
}