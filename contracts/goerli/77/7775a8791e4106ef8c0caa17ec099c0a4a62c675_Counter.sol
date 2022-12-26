/**
 *Submitted for verification at Etherscan.io on 2022-12-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Counter {
    int private count = 0;
    function incrementCounter(int value) public {
        count += value;
    }
    function decrementCounter(int value) public {
        require(count - value >= 0, "Counter cannot below 0");

        count -= value;
    }

    function getCount() public view returns (int) {
        return count;
    }
}