/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

// caller opens a channel and registers the interchain account and then sends a msg to execute and all
contract IcaCalldata {
    event IcaCallEvent(address indexed caller, string icamsg);
    event IcaRegsiterEvent(address indexed caller);

    mapping(address => bool) public whitelisted;

    constructor() {
        whitelisted[msg.sender] = true;
    }

    function whitelist(address to) public {
        require(whitelisted[msg.sender], "NOT_ALLOWED");
        whitelisted[to] = true;
    }

    function register() public {
        emit IcaRegsiterEvent(msg.sender);
    }

    function IcaCall(string memory icamsg) public {
        emit IcaCallEvent(msg.sender, icamsg);
    }

    function IcaCallWhitelist(string memory icamsg, address caller) public {
        require(whitelisted[msg.sender], "NOT_WHITELISTED");
        emit IcaCallEvent(caller, icamsg);
    }

    function RegisterWhitelisted(address caller) public {
        require(whitelisted[msg.sender], "NOT_WHITELISTED");
        emit IcaRegsiterEvent(caller);
    }
}