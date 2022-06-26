/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Whitelist {

    uint8 public maxWhitelistedAddresses;

    // Keep track of number of addresses whitelisted till now
    uint8 public numAddressesWhitelisted;

    mapping(address => bool) public whitelistedAddresses;

    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    function addAddressToWhitelist() public {
        require(!whitelistedAddresses[msg.sender], "Sender already in the whitelist");
        require(numAddressesWhitelisted < maxWhitelistedAddresses, "Max limit reached");
        whitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted += 1;
    }


}