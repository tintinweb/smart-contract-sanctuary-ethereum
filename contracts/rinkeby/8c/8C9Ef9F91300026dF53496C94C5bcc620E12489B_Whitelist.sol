// SPDX-License-Identifier: MIT
pragma solidity >0.7.0 <0.9.0;

// n number of addresses can be in the whitelist
// not more than
// same address can't be in the whitelist more than once
contract Whitelist {
    uint256 public maxWhitelistedAddresses;
    uint256 public numAddressesWhitelisted;
    mapping(address => bool) public whitelistedAddresses;

    constructor(uint256 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    modifier underLimit() {
        require(
            numAddressesWhitelisted < maxWhitelistedAddresses,
            "Whitelist limit reached"
        );
        _;
    }
    modifier onlyUniqueCandidate() {
        require(
            whitelistedAddresses[msg.sender] != true,
            "Same address can not be added twice"
        );
        _;
    }

    function addAddressToWhitelist() public underLimit onlyUniqueCandidate {
        whitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted++;
    }
}