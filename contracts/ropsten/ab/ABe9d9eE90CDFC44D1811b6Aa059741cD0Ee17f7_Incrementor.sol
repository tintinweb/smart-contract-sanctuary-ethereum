//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Incrementor {
    uint private counter;
    address public lastIncrementBy;

    constructor() {}

    function getCounter() public view returns(uint) {
        return counter;
    }

    function onlyIncrement(uint value) public {
        counter += value;
    }

    function increment(uint value) public {
        counter += value;
        lastIncrementBy = msg.sender;
    }

    function expensiveIncrement(uint value) public {
        for(uint i = 0; i < value ; i++) {
            _increment();
        }

        lastIncrementBy = msg.sender;
    }

    function _increment() internal {
        counter += 1;
    }
}