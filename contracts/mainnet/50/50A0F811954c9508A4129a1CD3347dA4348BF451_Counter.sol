/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Counter {
    uint256 private count;

    event CountUpdated(uint256 newValue);

    constructor() {
        count = 0;
    }

    function getCount() public view returns (uint256) {
        return count;
    }

    function increment() public {
        count++;
        emit CountUpdated(count);
    }

    function decrement() public {
        require(count > 0, "Count cannot be negative");
        count--;
        emit CountUpdated(count);
    }
}