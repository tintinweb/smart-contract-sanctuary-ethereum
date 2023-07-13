// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Whitelist {
    error Whitelist__SenderAlreadyWhitelisted(address user);
    error Whitelist__limitReached(string limitReached);
    // Max number of whitelisted addresses allowed

    uint8 public maxWhitelistedAddresses;

    // Create a mapping of whitelistedAddresses
    // if an address is whitelisted, we would set it to true, it is false by default for all other addresses.
    mapping(address => bool) public whitelistedAddresses;

    // numAddressesWhitelisted would be used to keep track of how many addresses have been whitelisted
    uint8 public numAddressesWhitelisted;

    // Setting the Max number of whitelisted addresses
    // User will put the value at the time of deployment
    constructor(uint8 _maxWhitelistedAddresses) {
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    /**
     * addAddressToWhitelist - This function adds the address of the sender to the
     *     whitelist
     */
    function addAddressToWhitelist() public {
        // check if the user has already been whitelisted
        if (!whitelistedAddresses[msg.sender]) {
            revert Whitelist__SenderAlreadyWhitelisted(msg.sender);
        }
        // check if the numAddressesWhitelisted < maxWhitelistedAddresses, if not then throw an error.
        if (numAddressesWhitelisted >= maxWhitelistedAddresses) {
            revert Whitelist__limitReached("More addresses cant be added, limit reached");
        }
        // Add the address which called the function to the whitelistedAddress array
        whitelistedAddresses[msg.sender] = true;
        // Increase the number of whitelisted addresses
        numAddressesWhitelisted += 1;
    }
}