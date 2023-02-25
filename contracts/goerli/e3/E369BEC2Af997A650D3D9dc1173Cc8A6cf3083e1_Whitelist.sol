/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

contract Whitelist {

    uint8 public maxWhitelistedAddresses;
    uint8 public numAddressesWhitelisted;
    mapping(address => bool) public whitelistedAddresses;
    

    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    function addAddressToWhitelist() public {
        require(!whitelistedAddresses[msg.sender], "You are already whitelisted!");
        require(numAddressesWhitelisted < maxWhitelistedAddresses, "Max white limit addresses reached!");
        whitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted++;
    }



}