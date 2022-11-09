/**
 *Submitted for verification at Etherscan.io on 2022-11-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Whitelist {
    
    uint8 public maxWhitelistedAddresses ;
    uint8 public numAddressesWhitelisted ;

    mapping(address => bool) public whitelistedAddress;

    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    function addAddressToWhitelist() public {
        require(!whitelistedAddress[msg.sender], "Sender has already already whitelisted");
        require(numAddressesWhitelisted < maxWhitelistedAddresses, "Max number of addresses already whitelisted");
        whitelistedAddress[msg.sender] = true;
        maxWhitelistedAddresses += 1;
    }
}