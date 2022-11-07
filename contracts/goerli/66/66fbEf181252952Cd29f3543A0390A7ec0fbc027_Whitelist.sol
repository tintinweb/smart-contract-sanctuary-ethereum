//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Whitelist {

    // Identify the owner of the contract.
    address public owner;

    // Max number of whitelisted addresses.
    uint8 public maxWhitelistedAddresses;

    // Create a mapping of whitelistedAddresses.
    // If an address is whitelisted, it's set to true, it is false by default for all other addresses.
    mapping(address => bool) public whitelistedAddresses;

    // numAddressesWhitelisted it's used to keep track of how many addresses have been whitelisted.
    // NOTE: Don't change this variable name, as it will be part of verification.
    uint8 public numAddressesWhitelisted;

    // This variable tells you how many whitelist spots are left.
    uint8 public whitelistSpotsLeft;

    // Modifier to check if the caller of a function is the owner. 
    // It's an excellent alternative to 'require' inside a function.
    modifier isOwner() {
        require(msg.sender == owner, "Sorry, you don't have access to this.");
        _;
    }

    // Constructor setting the Max number of whitelisted addresses and the contract's owner.
    // You pick this number when deploying the contract
    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses =  _maxWhitelistedAddresses;
        whitelistSpotsLeft = _maxWhitelistedAddresses;
        owner = msg.sender;
    }


    // addAddressToWhitelist - This function adds the address of the sender to the whitelist
    function addAddressToWhitelist() public {

        // check if the user has already been whitelisted
        require(!whitelistedAddresses[msg.sender], "This address is already whitelisted.");

        // check if the numAddressesWhitelisted < maxWhitelistedAddresses, if not then throw an error.
        require(numAddressesWhitelisted < maxWhitelistedAddresses, "Sorry, no more spots left.");

        // Add the address which called the function to the whitelistedAddress array
        whitelistedAddresses[msg.sender] = true;

        // Increase the number of whitelisted addresses
        numAddressesWhitelisted += 1;

        // Update how many spots are left
        whitelistSpotsLeft -= 1;
    }

    // This function allows the owner of the contract to add whitelist spots.
    function addWhitelistSpots(uint8 _extraSpots) public isOwner {
        // Add spots
        maxWhitelistedAddresses +=  _extraSpots;

        // Updates the spots left counter.
        whitelistSpotsLeft += _extraSpots;
    }
}