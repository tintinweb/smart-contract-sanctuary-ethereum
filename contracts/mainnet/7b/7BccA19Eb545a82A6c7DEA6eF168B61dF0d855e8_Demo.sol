// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Demo {
    uint32 private sum = 0;

    function Add (uint32 a, uint32 b) public {
        sum = a + b;
    }

    function getSum() view public returns (uint32) {
        return sum;
    }
}