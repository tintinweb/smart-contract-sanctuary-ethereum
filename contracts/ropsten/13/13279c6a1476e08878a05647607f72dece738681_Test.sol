/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;


contract Test {
    uint256 number;
    string str;
    bool boolean;

    constructor() {
        number = 0x61626364;
        str = "abc";
        boolean = true;
    }

    event Log(uint indexed number, string indexed str, bool indexed boolean);

    function log() external {
        emit Log(number, str, boolean);
    }
}