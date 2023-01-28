// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Whitelist {
    uint8 public maxWhitelistedAddresses; //Maximum address that can be part of the Whitelist   
    mapping(address => bool) public whitelistedAddresses;  //Every address will default as false, will only become true if already part of the whitelist
    uint8 public numAddressesWhitelisted; //The total number of whitelisted addresses

    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    // Function to add address to whitelist, anyone can access it and not limited to owner
    function addAddresstoWhitelist() public {
        
        require(!whitelistedAddresses[msg.sender], "You have already been Whitelisted"); // To check if the sender who will call this function is already on the whitelist
        require(numAddressesWhitelisted < maxWhitelistedAddresses, "The Whitelist has reached its limit");
        
        whitelistedAddresses[msg.sender] = true; //To add the address if still not whitelisted and haven't reached the limit yet
        numAddressesWhitelisted += 1;
    }
}