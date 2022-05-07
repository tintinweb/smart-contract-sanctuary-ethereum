// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Bar {
    address private immutable addr;
    uint256 private immutable num;

    constructor(address _addr, uint256 _num) {
        addr = _addr;
        num = _num;
    }
}