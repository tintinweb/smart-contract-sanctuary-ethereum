//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Whitelist {

    uint8 public maxWhitelistedAddresses;

    mapping(address => bool) public whitelistedAddresses;

    uint8 public numAddressesWhitelisted;

    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    function addAddressToWhiteList(address _toBeWhitelisted) public {
        require(whitelistedAddresses[_toBeWhitelisted] == false, "You're already in the whitelist");
        require(numAddressesWhitelisted < maxWhitelistedAddresses, "More addresses cant be added, limit reached");

        whitelistedAddresses[_toBeWhitelisted] = true;
        numAddressesWhitelisted += 1; 
    } 

}