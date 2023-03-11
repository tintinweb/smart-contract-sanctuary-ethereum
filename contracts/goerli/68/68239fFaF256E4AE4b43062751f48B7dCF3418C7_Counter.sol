// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract Counter {
    address owner;
    uint public counter;

    constructor() {
        owner = msg.sender;
    }

    function count() public {
        require(owner == msg.sender, 'Only owner can call this');
        counter++;
    }
}