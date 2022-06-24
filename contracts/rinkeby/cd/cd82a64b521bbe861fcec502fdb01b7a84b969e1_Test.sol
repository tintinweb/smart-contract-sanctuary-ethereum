// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

contract Test {
    uint256 public val = 11;

    function setter(uint256 newVal) external {
        val = newVal;
    }
}