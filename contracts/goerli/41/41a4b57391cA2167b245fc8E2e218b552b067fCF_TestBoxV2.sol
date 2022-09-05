// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TestBoxV2 {
    uint256 public val;

    // function initialize(uint _val) external {
    //     val = _val;
    // }

    function inc() external {
        val += 1;
    }
}