/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Counter {
    uint public count; 

    // 
    function get() public view returns (uint) {
        return count;
    }

    function inc() public {
        count++;
    }

    function dec() public {
        count--;
    }
}