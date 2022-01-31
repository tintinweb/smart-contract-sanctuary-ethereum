// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BoxV2 {
    uint256 public val;

    function inc() external {
        val += 1;
    }
}