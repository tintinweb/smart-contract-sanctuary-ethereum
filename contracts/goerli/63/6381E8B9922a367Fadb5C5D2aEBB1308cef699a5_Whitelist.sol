// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Whitelist {
    
    // Max number of whitelisted addresses allowed
    uint256 public maxWhitelistedAddresses;

    mapping(address => bool) public whitelistedAddresses;

    // Variable to keep trcak of number of whitelisted address
    uint256 public numAddressesWhitelisted;

    constructor (uint256 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    function addAddressToWhitelist() public {
        require(!whitelistedAddresses[msg.sender], "Sender has already been whitelisted");
        require(numAddressesWhitelisted < maxWhitelistedAddresses, "Max Limit reached");
        whitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted++;
    }
}