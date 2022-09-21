// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract NumIncreament {
    uint public val;

    function increment() external {
        val += 1;
    }
}