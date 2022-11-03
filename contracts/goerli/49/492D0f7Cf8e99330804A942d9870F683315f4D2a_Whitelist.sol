/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
 
contract Whitelist {

    uint8 public maxWhitelistedAddresses;

    mapping(address => bool) public whitelistedAddresses;

    uint8 public numAddressesWhitelisted;

    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses =  _maxWhitelistedAddresses;
    }

    function addAddressToWhitelist() public {
        require(!whitelistedAddresses[msg.sender], "Sender has already been whitelisted");
        require(numAddressesWhitelisted < maxWhitelistedAddresses, "More addresses cant be added, limit reached");
        whitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted += 1;
    }

    function removeAddressFromWhitelist() public {
        require(whitelistedAddresses[msg.sender], "Sender is not in the whitelist");
        whitelistedAddresses[msg.sender] = false;
        numAddressesWhitelisted -= 1;
    }
}