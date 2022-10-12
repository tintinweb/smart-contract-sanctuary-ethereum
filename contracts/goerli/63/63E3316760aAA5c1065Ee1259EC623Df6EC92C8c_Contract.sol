// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Contract {
    uint256 public zx;
    string public zy;
    uint256[] public zz;

    constructor(uint256 x, string memory y, uint256[] memory z) payable {
        zx = x;
        zy = y;
        zz = z;
    }
}