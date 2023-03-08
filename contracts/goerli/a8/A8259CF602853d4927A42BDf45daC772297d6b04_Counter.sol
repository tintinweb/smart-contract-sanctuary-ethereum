/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter {
    uint public counter;
    
    constructor() {
        counter = 0;
    }

    function add(uint x) public {
        counter = counter + x;
    }
}