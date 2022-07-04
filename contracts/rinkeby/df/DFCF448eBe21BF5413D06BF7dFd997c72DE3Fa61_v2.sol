// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract v2 {
    uint public val;

    function update() external {
        val = val + 1;
    }
}