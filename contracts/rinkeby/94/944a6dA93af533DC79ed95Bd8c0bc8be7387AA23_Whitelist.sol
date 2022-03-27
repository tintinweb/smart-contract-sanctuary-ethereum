//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Whitelist {
    uint8 public maxWhitelistedAddresses = 10;

    mapping(address => bool) public whitelistedAddresses;

    uint8 public numAddressesWhitelisted;

    constructor() {}
  
    function addAddressToWhitelist() public {
        require(!whitelistedAddresses[msg.sender], "Bu adres ile zaten whiteliste katilmissin.");
        require(numAddressesWhitelisted < maxWhitelistedAddresses, "Whitelistler tukendi.");
        whitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted += 1;
    }
}