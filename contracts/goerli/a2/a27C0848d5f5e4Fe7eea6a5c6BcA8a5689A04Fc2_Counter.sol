//  SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Counter {
    uint public counter;
    address owner;

    constructor(uint x) {
        counter = x;
        owner = msg.sender;
    }

    function count() public {
        require(msg.sender == owner, "invalid call");
        counter = counter + 1;
    }

    function add(uint x) public {
        require(msg.sender == owner, "invalid call");
        counter = counter + x;
    }
}