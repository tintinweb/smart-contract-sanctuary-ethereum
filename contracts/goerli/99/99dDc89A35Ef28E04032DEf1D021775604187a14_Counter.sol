//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter {
    uint public number;

    function retrieve() public view returns (uint) {
        return number;
    }

    function increment(uint numberToAdd) public {
        number = numberToAdd + number;
    }

    function decrement(uint numberToSubtract) public {
        number = number - numberToSubtract;
    }
}