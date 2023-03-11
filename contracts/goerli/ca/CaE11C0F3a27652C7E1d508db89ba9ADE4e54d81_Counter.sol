// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Counter {
    uint256 private _counter;

    constructor() {
        _counter = 0;
    }

    function getCounter() public view returns (uint256) {
        return _counter;
    }

    function setCounter(uint256 newCounter) public {
        _counter = newCounter;
    }
}