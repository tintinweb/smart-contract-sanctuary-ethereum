// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.18;

contract S {
    uint256 public x;
    bool public y;
    constructor(uint256 x_, bool y_) {
        x = x_;
        y = y_;
    }
}