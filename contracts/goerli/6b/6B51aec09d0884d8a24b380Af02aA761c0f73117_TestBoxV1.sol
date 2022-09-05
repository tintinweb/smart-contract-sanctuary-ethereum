// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract TestBoxV1 {
    uint256 public val;

    // constructor(uint _val){
    //     val = _val;
    // }

    function initialize(uint256 _val) external {
        val = _val;
    }
}