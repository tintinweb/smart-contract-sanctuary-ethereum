// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Box {
    uint public val;


    function initizlize() external {
        val = 42;
    }
}