/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;

contract Contador {
    int public count;

    // You need to send a transaction to write to a state variable.
    function setZero() public {
        count = 0;
    }

    // Function to get the current count
    function get() public view returns (int) {
        return count;
    }

    // Function to increment count by 1
    function inc() public {
        count += 1;
    }

    // Function to decrement count by 1
    function dec() public {
        count -= 1;
    }
}