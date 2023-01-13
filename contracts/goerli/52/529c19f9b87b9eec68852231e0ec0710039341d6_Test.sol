/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Test {
    uint256 public val;

    constructor() {
        val = 1;
    }

    function setVal(uint256 newValue) external {
        require(newValue < 10, "newValue >= 10");

        val = newValue;
    }
}