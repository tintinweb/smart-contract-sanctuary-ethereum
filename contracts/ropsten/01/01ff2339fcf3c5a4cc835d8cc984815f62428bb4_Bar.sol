// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Bar {
    address private immutable addr;
    uint256 private immutable num;
    bytes32 private immutable bites;

    constructor(
        address _addr,
        uint256 _num,
        bytes32 _bites
    ) {
        addr = _addr;
        num = _num;
        bites = _bites;
    }
}