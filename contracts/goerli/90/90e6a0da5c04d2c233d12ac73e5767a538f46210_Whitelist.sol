/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Whitelist {
    uint8 public maxWhitelistedAddresses;
    mapping(address => bool) public whitelistedAddresses;
    uint8 public numAddressesWhitelisted = 0;

    constructor(uint8 _maximumWhiteListAllowed) {
        maxWhitelistedAddresses = _maximumWhiteListAllowed;
    }

    event addressIsWhiteListed(address whiteListedUser, string message);

    function addAddressToWhitelist() public {
        address user = msg.sender;
        require(!whitelistedAddresses[user], "You are already whitelisted.");
        require(
            !(maxWhitelistedAddresses == numAddressesWhitelisted),
            "Whitelisted bucket is full now."
        );
        whitelistedAddresses[user] = true;
        emit addressIsWhiteListed(user, "user is whitelisted");
        numAddressesWhitelisted++;
    }
}