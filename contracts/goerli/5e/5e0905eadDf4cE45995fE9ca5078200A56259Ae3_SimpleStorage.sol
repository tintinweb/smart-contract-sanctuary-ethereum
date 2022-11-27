//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint number;

    function increment(uint _numToAdd) public {
        number = number + _numToAdd;
    }

    function decrement(uint _numToTake) public {
        number = number - _numToTake;
        if (number < 0) {
            revert();
        }
    }

    function retrieve() public view returns (uint) {
        return number;
    }
}