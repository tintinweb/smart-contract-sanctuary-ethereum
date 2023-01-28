// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Create a smart contract that can do whitelisting and can get the email address of your user using Hardhat.
// Compile, Deploy and Verify those smart contract on the blockchain.
// Create a frontend interface using React.js

contract Whitelist {
    uint8 public maxWhitelistAddresses; // max number of address that can whitelist
    uint8 public numWhitelistAddresses; // number of whitelisted address
    // address and email will be associated and be determined if whitelisted
    mapping(address => mapping(string => bool)) public whitelistAddresses;

    // set the max number of address that can whitelist upon deployment of contract
    constructor(uint8 _maxWhitelistaddresses) {
        maxWhitelistAddresses = _maxWhitelistaddresses;
    }

    // `addAddressToWhitelist` will add the sender and the email to the whitelist
    function addAddressToWhitelist(string memory _email) public {
        // check if address is already whitelisted or not
        require(
            !whitelistAddresses[msg.sender][_email],
            "Sender has already been whitelisted"
        );
        //check if number of whitelisted addresses is less than the max allowed
        require(
            numWhitelistAddresses <= maxWhitelistAddresses,
            "Maximum limit of whitelist has been reached"
        );
        // set to true if sender is not yet whitelisted and if number of address
        // whitelisted doesn't exceed yet the max allowed whitelist addresses
        whitelistAddresses[msg.sender][_email] = true;
        numWhitelistAddresses++; // increment number of whitelist
    }
}