// SPDX-License-Identifier: MIT
pragma solidity 0.4.24;

contract Counter {
    uint256 public count2;

    // Function to get the current count
    function get() public view returns (uint256) {
        return count2;
    }

    // Function to increment count by 1
    function inc() public {
        count2 += 1;
    }

    // Function to decrement count by 1
    function dec() public {
        // This function will fail if count = 0
        count2 -= 1;
    }
}