// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract v1 {
    uint public val;

    function initialise(uint _val) external {
        val = _val;
    }
}