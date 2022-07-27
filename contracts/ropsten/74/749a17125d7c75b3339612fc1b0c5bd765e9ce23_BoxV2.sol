// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract BoxV2 {
    uint public val;

    function inc() external {
        val++;
    }

    function getVal() public view returns (uint) {
        return val;
    }
}