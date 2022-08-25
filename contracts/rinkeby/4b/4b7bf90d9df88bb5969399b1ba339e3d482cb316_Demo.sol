/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

contract Demo {
    uint256 public a;
    constructor() {
        a = 1000000;
    }

    function setA(uint _a) external {
        a = _a;
    }
}