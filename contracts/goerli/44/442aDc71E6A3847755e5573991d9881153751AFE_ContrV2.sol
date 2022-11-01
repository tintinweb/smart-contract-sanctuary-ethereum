//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract ContrV2 {
    uint256 public val;

    function inc() external {
        val += 1;
    }
}