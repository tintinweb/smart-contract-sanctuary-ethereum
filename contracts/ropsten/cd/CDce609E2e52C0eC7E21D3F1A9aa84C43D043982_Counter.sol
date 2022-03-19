// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

contract Counter {
    uint private count;

    constructor () {
        count = 0;
    }

    function countMe() external {
        count += 1;
    }

    function currentCount() view external returns (uint) {
        return count;
    }
}