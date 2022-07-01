/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract CounterTracker {
    uint256 private _counter;

    constructor() {
        _counter = 0;
    }

    function increment() external {
        _counter += 1;
    }

    function get() external view  returns (uint256) {
        return _counter;
    }
}