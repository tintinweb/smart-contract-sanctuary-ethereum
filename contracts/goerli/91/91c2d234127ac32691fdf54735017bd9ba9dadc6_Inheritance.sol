// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./Ownable.sol";

contract Inheritance is Ownable {

    // Struct to store user data
    struct User {
        address payable cefiAccount;
        uint expiration;
        uint renewalPeriodInMinutes;
        uint balance;
    }

    // Mapping from user addresses to their data
    mapping(address => User) public users;

    // Declare events to monitor
    event Joined(address indexed _who);
    event Died(address indexed _who);

    // Check cefiAccount, time left, renewal period, and balance of the given user
    function viewDetails() public view returns (
        address payable cefiAccount, uint timeLeftInSeconds, uint renewalPeriodInMinutes, uint balance) {
        // Calculate the time left if not already expired
        uint _timeLeftInSeconds = 0;
        if (block.timestamp < users[msg.sender].expiration) {
            _timeLeftInSeconds = (users[msg.sender].expiration - block.timestamp) * 1 seconds;
        }
        // Convert balance from wei to eth
        uint _balance = users[msg.sender].balance / 1000000000000000000;
        return (
            users[msg.sender].cefiAccount,
            _timeLeftInSeconds,
            users[msg.sender].renewalPeriodInMinutes,
            _balance
        );
    }

    // Adds a cefi account address and renewal period for the given user
    function addMyCefi(address payable cefiAccount, uint renewalPeriodInMinutes) public payable {
        // Ensure user has not already added a cefi account
        require(users[msg.sender].cefiAccount == address(0), "CeFi account already set for user");
        // Ensure user is not adding the same address
        require(cefiAccount != address(msg.sender), "Cannot set the same address as beneficiary");
        // Ensure msg.value is not 0
        require(msg.value != 0, "Inheritance must be greater than 0");
        // Set the cefi account, expiration, renewal period, and balance for the user
        users[msg.sender].cefiAccount = cefiAccount;
        users[msg.sender].expiration = block.timestamp + (renewalPeriodInMinutes * 1 minutes);
        users[msg.sender].renewalPeriodInMinutes = renewalPeriodInMinutes;
        users[msg.sender].balance = msg.value;
        // Emit a Joined event
        emit Joined(msg.sender);
    }

    // Update cefi account address for the given user
    function updateCefiAccount(address payable newCefiAccount) public {
        // Ensure user has added a cefi account
        require(users[msg.sender].cefiAccount != address(0), "CeFi account not set for user");
        // Ensure user is not adding the same address
        require(newCefiAccount != address(msg.sender), "Cannot set the same address as beneficiary");
        // Ensure user is still alive
        require(block.timestamp < users[msg.sender].expiration, "Too late ...");
        // Update the cefi account for the user
        users[msg.sender].cefiAccount = newCefiAccount;
        // Update the expiration for the user
        users[msg.sender].expiration = block.timestamp + (users[msg.sender].renewalPeriodInMinutes * 1 minutes);
    }

    // Update renewal period for the given user
    function updateRenewalPeriod(uint newRenewalPeriodInMinutes) public {
        // Ensure user has added a cefi account
        require(users[msg.sender].cefiAccount != address(0), "CeFi account not set for user");
        // Ensure user is still alive
        require(block.timestamp < users[msg.sender].expiration, "Too late ...");
        // Update the renewal period for the user
        users[msg.sender].renewalPeriodInMinutes = newRenewalPeriodInMinutes;
        // Update the expiration for the user
        users[msg.sender].expiration = block.timestamp + (newRenewalPeriodInMinutes * 1 minutes);
    }

    // Renews the expiration for the given user
    function imAlive() public {
        // Ensure user has added a cefi account
        require(users[msg.sender].cefiAccount != address(0), "CeFi account not set for user");
        // Ensure user is still alive
        require(block.timestamp < users[msg.sender].expiration, "Too late ...");
        // Update the expiration for the user
        users[msg.sender].expiration = block.timestamp + (users[msg.sender].renewalPeriodInMinutes * 1 minutes);
    }

    // Checks the expiration for the given user and sends the funds to cefi account if expired
    function dead(address payable disinherited) public onlyOwner {
        // Ensure user has added a cefi account
        require(users[disinherited].cefiAccount != address(0), "CeFi account not set for user");
        // Ensure user is not dead
        require(block.timestamp >= users[disinherited].expiration, "Still alive ...");
        // Ensure user balance is not 0
        if (users[disinherited].balance > 0) {
            // Send the funds to the cefi account
            users[disinherited].cefiAccount.transfer(users[disinherited].balance);
        }
        // Delete the disinherited record
        delete users[disinherited];
        // Emit a Died event
        emit Died(disinherited);
    }

    // Adds inheritance balance for the given user
    function addInheritance() public payable {
        // Ensure user has added a cefi account
        require(users[msg.sender].cefiAccount != address(0), "CeFi account not set for user");
        // Ensure user is still alive
        require(block.timestamp < users[msg.sender].expiration, "Too late ...");
        // Ensure msg.value is not 0
        require(msg.value != 0, "Value must be greater than 0");
        // Update user balance
        users[msg.sender].balance += msg.value;
        // Update the expiration for the user
        users[msg.sender].expiration = block.timestamp + (users[msg.sender].renewalPeriodInMinutes * 1 minutes);
    }

    // Withdraw inheritance balance for the given user
    function withdrawInheritance(uint amount_in_wei) public {
        // Amount is in wei
        uint amount = amount_in_wei;
        // Ensure user has added a cefi account
        require(users[msg.sender].cefiAccount != address(0), "CeFi account not set for user");
        // Ensure user is still alive
        require(block.timestamp < users[msg.sender].expiration, "Too late ...");
        // Ensure amount is not 0
        require(amount > 0, "Value must be greater than 0");
        // Ensure user balance is sufficient
        require(amount <= users[msg.sender].balance, "Amount exceeded current balance");
        // Send 1% fee to owner
        uint fee = amount / 100;
        payable(owner()).transfer(fee);
        amount -= fee;
        // Send amount to user
        payable(msg.sender).transfer(amount);
        // Update user balance
        users[msg.sender].balance -= amount + fee;
        // Update the expiration for the user
        users[msg.sender].expiration = block.timestamp + (users[msg.sender].renewalPeriodInMinutes * 1 minutes);
    }
}