/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Whitelist{

    //maximum number of whitelist address
    uint8 public maxWhiteListedAddress;

    //number of addresses whitelisted
    uint8 public numAddressesWhitelisted;
 
    //hashmaps -> map something to something (can only have one map)
    mapping(address => bool) public whitelistedAddresses;

    constructor(uint8 _maxWhiteListedAddress){
        maxWhiteListedAddress = _maxWhiteListedAddress;
    }

    function addAddressToWhitelist() public {

        require(!whitelistedAddresses[msg.sender], "Sender is already in the whitelist");
        require(numAddressesWhitelisted < maxWhiteListedAddress, "Max Limit reached");

     whitelistedAddresses[msg.sender] = true;
     numAddressesWhitelisted += 1;
     
    }

    
}