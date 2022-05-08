// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Bar {
    address private immutable addr1;
    uint256 private immutable num;
    bytes32 private immutable bites;
    address private immutable addr2;

    constructor(
        address _addr1,
        uint256 _num,
        bytes32 _bites,
        address _addr2
    ) {
        addr1 = _addr1;
        num = _num;
        bites = _bites;
        addr2 = _addr2;
    }
}