// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract Box {
    uint256 public val;

    function initialize(uint256 _val) external {
        val = _val;
    }
}