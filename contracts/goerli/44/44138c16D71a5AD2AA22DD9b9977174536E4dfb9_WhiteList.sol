// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract WhiteList {
    error AlreadyWhiteListed();
    error WhiteListMaxedOut();

    uint8 public maxWhiteListedAddresses;

    mapping(address => bool) public whitelistedAddresses;

    uint8 public numAddressesWhitelisted;

    constructor(uint8 _maxWhiteListedAddresses) {
        maxWhiteListedAddresses = _maxWhiteListedAddresses;
    }

    function addAddressToWhitelist() public {
        if (whitelistedAddresses[msg.sender]) revert AlreadyWhiteListed();

        if (numAddressesWhitelisted == maxWhiteListedAddresses)
            revert WhiteListMaxedOut();

        whitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted += 1;
    }
}