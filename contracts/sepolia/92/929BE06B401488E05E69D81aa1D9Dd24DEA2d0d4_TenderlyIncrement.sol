// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TenderlyIncrement {

    event CounterSet(uint256 count);

    uint private counter;

    function getCounter() public view returns (uint) {
        return counter;
    }

    function setCounter(uint value) public {
        counter = value;
        emit CounterSet(counter);
    }

}