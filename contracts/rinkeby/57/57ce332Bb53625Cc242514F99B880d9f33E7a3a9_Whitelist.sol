// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Whitelist {
    uint8 public maxWhiteListedAddresses;
    uint8 public numAddressesWhiteListed;

    mapping(address => bool) public whiteListedAddresses;

    constructor(uint8 _maxWhiteListedAddresses) {
        maxWhiteListedAddresses = _maxWhiteListedAddresses;
    }

    function addAddressToWhiteList() public {
        require(
            whiteListedAddresses[msg.sender],
            "Sender has already been white-listed!"
        );
        require(
            numAddressesWhiteListed < maxWhiteListedAddresses,
            "Limit reached! More addresses cannot be white-listed!"
        );
        whiteListedAddresses[msg.sender] = true;
        numAddressesWhiteListed += 1;
    }
}