/**
 *Submitted for verification at Etherscan.io on 2023-01-07
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract Inheritance {
    // Struct to store user data
    struct User {
        address payable beneficiary;
        uint expiration;
    }

    // Mapping from user addresses to their data
    mapping(address => User) public users;

    // Adds a beneficiary address for the given user
    function addBeneficiary(address payable beneficiary) public {
        // Ensure the user has not already added a beneficiary
        require(users[msg.sender].beneficiary == address(0), "Beneficiary already set for user");
        // Set the beneficiary and expiration for the user
        users[msg.sender].beneficiary = beneficiary;
        users[msg.sender].expiration = block.timestamp + 1 hours;
    }

    // Renews the expiration for the given user
    function renew() public {
        // Ensure the user has added a beneficiary
        require(users[msg.sender].beneficiary != address(0), "Beneficiary not set for user");
        // Update the expiration for the user
        users[msg.sender].expiration = block.timestamp + 1 hours;
    }

    // Checks the expiration for the given user and sends the funds to the beneficiary if expired
    function check() public {
        // Ensure the user has added a beneficiary
        require(users[msg.sender].beneficiary != address(0), "Beneficiary not set for user");
        // Check if the expiration has passed
        if (block.timestamp >= users[msg.sender].expiration) {
            // Send the funds to the beneficiary
            users[msg.sender].beneficiary.transfer(address(this).balance);
        }
    }
}