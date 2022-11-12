/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: GPL-3.0-or-later
/*
    Blogtary: a minimalistic notary for my ramblings. 
    https://github.com/kairosdojo/blogtary
*/ 
pragma solidity ^0.8.17;

/// @title Blogtary
/// @notice It just records a given hash (bytes32) as an Event. Designed to be simple and inexpensive to use.
contract Blogtary {

    address admin;

    constructor () {
        admin = msg.sender;

        // The sha-256 hash of the url of my blog
        emit log(0x021adf127c84724dcc979aaab4b1b36b62d3f54894e5b0e19d56d78cdfd9e288);
    }

    event log(
        bytes32 sha256Post
    );

    modifier onlyAdminCan() {
        require(admin == msg.sender, "Sorry, you can't do that.");
        _;
    }

    function blogtary(bytes32 sha256Post) public onlyAdminCan {
        emit log(sha256Post);
    }
}