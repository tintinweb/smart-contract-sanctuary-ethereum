// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract Test {
    uint256 public val;

    constructor(uint256 initialVal) {
        val = initialVal;
    }

    function setter(uint256 newVal) external {
        val = newVal;
    }
}