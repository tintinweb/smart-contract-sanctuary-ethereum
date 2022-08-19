// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Counter {
    uint256 public s_counter;

    constructor() {
        s_counter = 10;
    }

    function incrementCounter() public {
        s_counter += 1;
    } 

    function decrementCounter() public {
        s_counter -= 1;
    }

    function viewCounter() public view returns (uint256) {
        return s_counter;
    }
}