// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Counter {
    uint256 public s_counter;

    constructor(uint256 number) {
        s_counter = number;
    }

    function incrementCounter(uint256 _number) public {
        s_counter += _number;
    } 

    function decrementCounter(uint256 _number) public {
        s_counter -= _number;
    }

    function viewCounter() public view returns (uint256) {
        return s_counter;
    }
}