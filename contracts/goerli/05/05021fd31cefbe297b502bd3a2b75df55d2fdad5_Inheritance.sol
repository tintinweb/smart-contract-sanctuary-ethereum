/**
 *Submitted for verification at Etherscan.io on 2023-01-07
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Inheritance {

    // Struct to store user data
    struct User {
        address payable coinbase_account;
        uint expiration;
    }

    // Mapping from user addresses to their data
    mapping(address => User) users;

    // Adds a coinbase account address for the given user
    function add_my_cefi(address payable coinbase_account) public {
        // Ensure the user has not already added a beneficiary
        require(users[msg.sender].coinbase_account == address(0), "Beneficiary already set for user");
        // Set the coinbase account and expiration for the user
        users[msg.sender].coinbase_account = coinbase_account;
        users[msg.sender].expiration = block.timestamp + 1 minutes;
    }

    // Renews the expiration for the given user
    function im_alive() public {
        // Ensure the user has added a beneficiary
        require(users[msg.sender].coinbase_account != address(0), "Beneficiary not set for user");
        // Update the expiration for the user
        users[msg.sender].expiration = block.timestamp + 1 minutes;
    }

    // Checks the expiration for the given user and sends the funds to the beneficiary if expired
    function im_dead() public {
        // Ensure the user has added a beneficiary
        require(users[msg.sender].coinbase_account != address(0), "Beneficiary not set for user");
        // Ensure the user is not dead
        require(block.timestamp >= users[msg.sender].expiration, "Not dead yet");
        // Check if the expiration has passed
        if (block.timestamp >= users[msg.sender].expiration) {
            // Send the funds to the beneficiary
            users[msg.sender].coinbase_account.transfer(address(this).balance);
        }
    }
}