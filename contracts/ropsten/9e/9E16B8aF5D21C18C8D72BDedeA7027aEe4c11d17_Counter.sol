//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Counter {
    uint256 public counter;

    constructor() {
    }

    function increment() external {
        counter++;    
    }
}