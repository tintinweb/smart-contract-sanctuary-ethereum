/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Whitelist{
    uint8 public maxWhitelistedAddresses;
    mapping(address=>bool)public whitelistedAddresses;
    uint8 public numAddressesWhitelisted;
    constructor(uint8 _maxWhitelistedAddresses){
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }
    function addAddressToWhitelist()public{
        require(!whitelistedAddresses[msg.sender],"sender has already been whitelisted");
        require(numAddressesWhitelisted<maxWhitelistedAddresses,"more addresses cant be added, limit reached");
        whitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted +=1;
    }
}