//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

contract Whitelist {
    uint8 public maxWhitelistAddresses;

    mapping(address => bool) public whitelistedAddress;

    uint8 public numAddressesWhitelisted;

    constructor(uint8 _maxWhitelistAddresses) {
        maxWhitelistAddresses = _maxWhitelistAddresses;
    }

    function addAddressToWhitelisted() public {
        require(
            !whitelistedAddress[msg.sender],
            "Sender has already been whitelisted"
        );
        require(
            numAddressesWhitelisted < maxWhitelistAddresses,
            "More addresses cant be added, limit reached"
        );

        whitelistedAddress[msg.sender] = true;
        numAddressesWhitelisted += 1;
    }
}