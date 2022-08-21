/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.16;

contract Whitelist {

    address public owner;
    uint8 public maxWhitelistedAddresses;
    uint8 public numberWhitelistedAddresses;

    mapping(address => bool) public whitelistedAddress;

    constructor(uint8 _maxWhitelistedAddresses) {
        owner = msg.sender;
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    function addAddressWhitelisted(address _add) public returns (bool success) {

        require(!whitelistedAddress[_add], "User is already whitelisted");
        require(msg.sender == owner, "Only owner can whitelist");
        require(numberWhitelistedAddresses < maxWhitelistedAddresses, "Max whitelist reached!");
        
        whitelistedAddress[_add] = true;
        numberWhitelistedAddresses += 1;

        return true;
    }

    
}