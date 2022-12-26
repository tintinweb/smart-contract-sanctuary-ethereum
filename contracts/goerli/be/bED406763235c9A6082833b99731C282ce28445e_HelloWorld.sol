// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.13 and less than 0.9.0
pragma solidity ^0.8.13;

contract HelloWorld {
    uint public counts;

    // Function to get the current count
    function get() public view returns (uint) {
        return counts;
    }

    // Function to increment count by 1
    function inc() public {
        counts += 1;
    }

    // Function to decrement count by 1
    function dec() public {
        // This function will fail if count = 0
        counts -= 1;
    }
}