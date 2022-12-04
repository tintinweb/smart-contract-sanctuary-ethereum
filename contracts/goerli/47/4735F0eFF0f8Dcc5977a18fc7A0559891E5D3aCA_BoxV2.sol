// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract BoxV2 {
    uint256 public val;

    // constructor(uint _val)  {
    //     val = _val;
    // }

    function inc() external {
        val += 1;
    }
}