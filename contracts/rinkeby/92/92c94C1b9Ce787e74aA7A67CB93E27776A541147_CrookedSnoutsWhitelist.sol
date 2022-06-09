//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract CrookedSnoutsWhitelist {

    uint16 public maxWhitelistedAddresses;
    uint16 public numAddressesWhitelisted;

    mapping(address => bool) public whitelistedAddresses;


    constructor() {
        maxWhitelistedAddresses = 500;
    }

    function addAddressToWhitelist() public {
        require(!whitelistedAddresses[msg.sender], "Sender is already whitelisted");
        require(numAddressesWhitelisted < maxWhitelistedAddresses, "Whitelisted addresses limit reached");

        whitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted += 1;
    }

}