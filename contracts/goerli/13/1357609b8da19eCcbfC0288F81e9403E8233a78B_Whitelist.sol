// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.9;

contract Whitelist {

    uint8 public maxWhitelistedAddresses;

    mapping(address => bool) public whitelistedAddresses;

    uint8 public numWhitelistedAddresses;

    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    function addAddressToWhitelist() public {
        require(!whitelistedAddresses[msg.sender], "Sender is already whitelisted");
        require(numWhitelistedAddresses < maxWhitelistedAddresses, "Cannot whitelist more addresses");
        whitelistedAddresses[msg.sender] = true;
        numWhitelistedAddresses += 1;
    }

}