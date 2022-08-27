/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Demo {
    uint256 public a;

    constructor() {
        a = 1000;
    }

    function setA(uint256 _a) external {
        a = _a;
    }
}