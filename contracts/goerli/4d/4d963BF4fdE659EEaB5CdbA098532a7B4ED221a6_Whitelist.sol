/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Whitelist {
    uint8 public maxWhitelistedAddress;
    mapping(address => bool) public whitelistAddresses;
    uint8 public numAddressesWhitelisted;

    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddress = _maxWhitelistedAddresses;
    }

    function addAddressToWhitelist() public {
        require(!whitelistAddresses[msg.sender], "Senderhas already been Whitelisted");
        require(numAddressesWhitelisted < maxWhitelistedAddress, "More Addresses Cant Be Added, Limit Reached");
        whitelistAddresses[msg.sender] = true;
        numAddressesWhitelisted += 1;
    }
}