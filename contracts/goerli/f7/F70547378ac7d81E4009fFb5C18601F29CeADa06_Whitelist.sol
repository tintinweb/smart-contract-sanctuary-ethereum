//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

error UnableToWithelist_SpotsFilled();
error UserAlreadyWhitelisted();

contract Whitelist {
    address public immutable owner;
    uint8 public maxWhitelistedAddresses;

    // no more whitelist addresses if this is equal to `maxWhitelistedAddresses`
    uint8 public numAddressesWhitelisted;

    // Create a mapping of whitelistedAddresses to keep track of which address has been listed
    mapping(address => bool) public whitelistedAddresses;

    constructor(uint8 _maxWhitelistedAddresses) {
        owner = msg.sender;
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    /*
     *@dev addAddressToWhitelist - This function adds the address of the sender to the whitelist
     */
    function addAddressToWhitelist() public {
        // check if the user has already been whitelisted
        if (whitelistedAddresses[msg.sender]) {
            revert UserAlreadyWhitelisted();
        }
        if (numAddressesWhitelisted >= maxWhitelistedAddresses) {
            revert UnableToWithelist_SpotsFilled();
        }

        // Add the address which called the function to the whitelistedAddress array
        whitelistedAddresses[msg.sender] = true;
        // Increase the number of whitelisted addresses
        numAddressesWhitelisted += 1;
    }
}