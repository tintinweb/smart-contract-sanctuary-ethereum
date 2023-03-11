// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Sample {
    uint256 public num;

    constructor() {
        num = 0;
    }

    function sample() public {
        num = num + 1;
    }
}