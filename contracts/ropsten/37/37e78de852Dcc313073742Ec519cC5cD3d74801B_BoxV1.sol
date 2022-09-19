//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BoxV1 {
    uint256 public val;

    function initialize(uint256 _val) external {
        val = _val;
    }
}