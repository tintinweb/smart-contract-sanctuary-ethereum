//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Whitelist {
    uint256 public maxWhitelistedAddress;
    uint256 public numAddressesWhitelisted;

    mapping(address => bool) public whitelistedAddresses;

    constructor(uint256 _maxWhitelistedAddress) {
        maxWhitelistedAddress = _maxWhitelistedAddress;
    }

    function addAddressToWhitelist() public {
        require(
            !whitelistedAddresses[msg.sender],
            "Sender has already been whitelisted"
        );
        require(
            numAddressesWhitelisted < maxWhitelistedAddress,
            "Whitelist is full"
        );
        whitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted++;
    }
}