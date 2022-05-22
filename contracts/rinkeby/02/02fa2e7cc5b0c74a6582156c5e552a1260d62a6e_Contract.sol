// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Contract {
    bytes4 public b = hex"f0df";

    constructor() payable {
        b = hex"";
    }
}