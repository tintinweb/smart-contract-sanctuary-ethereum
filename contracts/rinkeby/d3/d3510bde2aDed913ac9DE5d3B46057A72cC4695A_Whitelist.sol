//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Whitelist {
    uint8 public maxWhiteListedAddresses;

    uint8 public numAddressesWhitelisted;

    mapping (address => bool) public whitelistedAddresses;

    constructor (uint8 _maxWhiteListedAddresses) {
        maxWhiteListedAddresses= _maxWhiteListedAddresses;
    }

    function addAddressToWhitelist () public {
        require(!whitelistedAddresses[msg.sender], "sender already whitelisted" );
        require(numAddressesWhitelisted<= maxWhiteListedAddresses, "no more addresses can be whitelisted" );
        whitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted++; 
    }

    function AmIWhitelisted () public  view returns (bool ans) {
        return whitelistedAddresses[msg.sender];

    }
}