/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

contract Counter {
    uint256 public count;

    // Function to get the current count
    function get() public view returns (uint256) {
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