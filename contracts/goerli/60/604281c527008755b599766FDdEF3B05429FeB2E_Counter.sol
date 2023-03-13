//  SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

contract Counter {
    uint public counter;

    constructor() {
        counter = 0;
    }

    function count() public {
        counter = counter + 1;
    }

    function add(uint x) public {
        counter = counter + x;
    }
    
}