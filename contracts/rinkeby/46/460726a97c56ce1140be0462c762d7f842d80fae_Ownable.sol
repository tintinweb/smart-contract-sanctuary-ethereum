// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Ownable {
    address owner;

    modifier onlyOwner() virtual{
        require(msg.sender == owner, "Invalid, only the owner can use this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function switchOwner(address _addr) public virtual onlyOwner {
        require(_addr != address(0), "Invalid address");
        owner = _addr;
    }
}