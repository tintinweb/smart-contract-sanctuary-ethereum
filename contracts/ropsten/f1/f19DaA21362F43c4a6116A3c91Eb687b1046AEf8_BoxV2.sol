// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract BoxV2 {
    uint256 public val;

    function increase() external {
        val += 5;
    }
}