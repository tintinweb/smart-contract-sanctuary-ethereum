/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Whitelist {
    uint8 public maxWhitelistedAddresses;

    // mapping to check if a address is whitelisted using true or false

    mapping(address=>bool) public WhitelistedAddresses;

    // number of whitelisted address

    uint8 public numAddressesWhitelisted;

    // setting max number of address to be whitelisted

    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    } 

    // function to add address to whitelist

    function addAddressToWhitelist() public {
        // check if user has been whitelisted before
        require(!WhitelistedAddresses[msg.sender], "Sender has already been whitelisted");
        // check if whitelist spots havent been filled
        require(numAddressesWhitelisted < maxWhitelistedAddresses, "More Addresses Cant be added, limit reached");

        // Add the address which called the function to the whitelistedAddress array
        WhitelistedAddresses[msg.sender] = true;
        
        //increase the number of whitelisted addresses
        numAddressesWhitelisted += 1;
    }

    

}