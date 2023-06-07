// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TenderlyIncrement {

    event CounterIncremented(uint256 count);
    uint public counter;

    constructor() {
        counter = 0;
    }

    function increment() public {
        counter++;
        emit CounterIncremented(counter);
    }

    function getCounterValue() public view returns (uint) {
        return counter;
    }

}