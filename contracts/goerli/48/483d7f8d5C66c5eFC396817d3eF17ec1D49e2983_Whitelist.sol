// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Whitelist {
    uint8 public maxWhitelistAddresses;
    mapping(address => bool) public whitelistAddresses;
    uint8 public numAddressesWhitelisted;

    constructor(uint8 _maxWhitelistAddresses) {
        maxWhitelistAddresses = _maxWhitelistAddresses;
    }

    function addAddressToWhitelist() public {
        require(!whitelistAddresses[msg.sender], "This address has already been whitelisted!");
        require(numAddressesWhitelisted < maxWhitelistAddresses, "More addresses cannot be added, limit reached");
        whitelistAddresses[msg.sender] = true;
        numAddressesWhitelisted += 1;
    }
}