// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

error WhiteListFull();
error AddressAlreadyWhiteListed();
error AddressNotWhiteListed();

contract WhiteList {
    // State Variables
    uint8 public maxWhiteListedAddresses;
    uint8 public numberOfWhiteListedAddresses;
    mapping(address => bool) public whiteListedAddresses;

    constructor(uint8 _maxWhiteListedAddresses) {
        maxWhiteListedAddresses = _maxWhiteListedAddresses;
    }

    // External Functions


    // Public Functions
    function addAddressToWhiteList() public {
        if (numberOfWhiteListedAddresses == maxWhiteListedAddresses) {
            revert WhiteListFull();
        }
        if (whiteListedAddresses[msg.sender]) {
            revert AddressAlreadyWhiteListed();
        }

        whiteListedAddresses[msg.sender] = true;
        numberOfWhiteListedAddresses++;
    } 
}