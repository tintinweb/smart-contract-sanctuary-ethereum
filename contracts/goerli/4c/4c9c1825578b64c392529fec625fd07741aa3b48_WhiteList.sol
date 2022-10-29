/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract WhiteList {
    uint8 maximumWhiteListAllowed;
    mapping(address => bool) whiteListedAddress;
    uint8 whiteListedCounter = 0;
    constructor(uint8 _maximumWhiteListAllowed) {
        maximumWhiteListAllowed = _maximumWhiteListAllowed;
    }

    event addressIsWhiteListed(address whiteListedUser, string message);

    function addToWhiteList() public {
        address user = msg.sender;
        require(!whiteListedAddress[user], "You are already whitelisted.");
        require(!(maximumWhiteListAllowed == whiteListedCounter), "Whitelisted bucket is full now.");
        whiteListedAddress[user] = true;
        emit addressIsWhiteListed(user, "user is whitelisted");
        whiteListedCounter++;
    }
}