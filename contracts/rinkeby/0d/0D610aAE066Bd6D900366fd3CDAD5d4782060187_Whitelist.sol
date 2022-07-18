//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

error AlreadyWhitelisted();
error MaxAddressesWhitelisted();

contract Whitelist {
    uint8 private immutable maxWhitelistedAddresses;
    mapping(address => bool) public whitelistedAddresses;
    uint8 public numAddressesWhitelisted;

    event AddressWhitelisted(address indexed whitelistedAddress);

    modifier notWhitelisted() {
        if (whitelistedAddresses[msg.sender]) {
            revert AlreadyWhitelisted();
        }
        _;
    }

    modifier whitelistLimitNotReached() {
        if (numAddressesWhitelisted >= maxWhitelistedAddresses) {
            revert MaxAddressesWhitelisted();
        }
        _;
    }

    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    function addAddressToWhitelist()
        public
        notWhitelisted
        whitelistLimitNotReached
    {
        whitelistedAddresses[msg.sender] = true;
        numAddressesWhitelisted += 1;
        emit AddressWhitelisted(msg.sender);
    }
}