/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Whitelist {
    // Maximum number of whitelisted addresses allowed
    uint8 public maxWhitelistedAddresses;

    // if an address is whitelisted, set true
    mapping(address => bool) public whitelistedAddresses;

    // keep track of how many addresses have been whitelisted
    uint8 public numAddressesWhitelisted;

    // User set number of whitelisted assets at deployment
    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    /**
        Add the address of the sender to the whitelist
    */
    function addAddressToWhitelist() public {
        require(
            !whitelistedAddresses[msg.sender],
            "Sender already whitelisted"
        );
        require(
            numAddressesWhitelisted < maxWhitelistedAddresses,
            "WHITELIST LIMIT REACHED!"
        );

        // Add user address which called the function to the whitelistedAddresses array
        whitelistedAddresses[msg.sender] = true;

        numAddressesWhitelisted += 1;
    }
}