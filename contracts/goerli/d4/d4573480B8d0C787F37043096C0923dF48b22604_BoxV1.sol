// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract BoxV1 {
    uint256 public val;

    // constructor(uint _val)  {
    //     val = _val;
    // }

    function initialize(uint _val) external {
        val = _val;
    }
}