// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract accessVuln {

    error notWhitelisted();
    error notOwner();

    bool pwn;
    address owner;
    mapping(address => bool) whitelistedMinters;

    constructor() {
        owner = msg.sender;
    }

    modifier whitelisted(address addr) {
        if(!whitelistedMinters[addr]) revert notWhitelisted();
        _;
    }

    function addToWhitelist(address addr) public {
        require(addr != address(0), "Zero address");
        whitelistedMinters[addr] = true;
    }

    function changeOwner(address addr) public whitelisted(addr) {
        owner = msg.sender;
    }

    function pwnOwner() public {
        require (msg.sender == owner);
        pwn = true;
    }

}