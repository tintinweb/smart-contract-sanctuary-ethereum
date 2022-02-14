/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Whitelist  {
    mapping (address => bool) userAddr;

    function whitelistAddressBatch(address[] memory users) public{
        for (uint i = 0; i < users.length; i++) {
            userAddr[users[i]] = true;
        }
    }

    function whitelistAddress (address user) public {
        userAddr[user] = true;
    }
}