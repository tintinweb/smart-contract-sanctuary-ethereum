// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract accessControlVuln {

    error notWhitelisted();

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

    function isPwn() public view returns(bool){
        return pwn;
    }

    function isOwner() public view returns(bool){
        if (msg.sender==owner) {
            return true;
        }
        else return false;
    }

    function resetPwn() public {
        pwn=false;
    }
}