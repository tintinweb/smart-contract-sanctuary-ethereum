//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Whitelist {

    uint8 public maxWhiteListedAddresses;

    mapping(address => bool) whiteListedAddresses;

    uint8 public numAddressesWhitelisted;

    constructor(uint8 _maxWhiteListedAddresses) {
        maxWhiteListedAddresses = _maxWhiteListedAddresses;
    }

    function addAddressToWhitelist() public {
        require(!whiteListedAddresses[msg.sender], "Sender has already benn whitelisted");
        require(numAddressesWhitelisted < maxWhiteListedAddresses, "The Whitelist is full.");
        numAddressesWhitelisted++;
    }
}