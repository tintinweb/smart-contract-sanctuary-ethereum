/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Counter {
    uint public count;

    // Function to get the current count
    function get() public view returns (uint) {
        return count;
    }

    // Function to increment count by 1
    function inc(uint a) public {
        count += a;
    }

    // Function to decrement count by 1
    function dec(uint b) public {
        // This function will fail if count = 0
        if(b < count)
        {
          count -= b;
        }
        else
        {
          count = 0;
        }

    }
}