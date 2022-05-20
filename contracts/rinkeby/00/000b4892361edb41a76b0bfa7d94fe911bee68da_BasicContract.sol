// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract BasicContract {
    uint256 public a;

    constructor(uint256 _a) {
        a = _a;
    }

    function increment() public {
        a = a + 1;
    }
}