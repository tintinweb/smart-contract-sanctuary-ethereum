/**
 *Submitted for verification at Etherscan.io on 2022-12-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Counter {
    int256 private count = 0;

    function increment() public {
        count += 1;
    }

    function decrement() public {
        count -= 1;
    }

    function getCounter() public view returns (int256) {
        return count;
    }
}