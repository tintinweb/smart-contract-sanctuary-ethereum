// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Counter {
    uint256 public counter;
    address owner;

    constructor() {
        counter = 0;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function count() public onlyOwner {
        counter += 1;
    }

    function add(uint256 x) public {
        counter = counter + x;
    }
}