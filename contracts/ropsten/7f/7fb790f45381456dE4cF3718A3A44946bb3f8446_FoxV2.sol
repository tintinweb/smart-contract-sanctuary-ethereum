// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract FoxV2 {
    uint public val;

    function ince() external {
        val += 1;
    }
}