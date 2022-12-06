/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.7;

contract Assembly {
    mapping(uint256 => uint256) public test;
    constructor() {
        test[1] = 2;
        test[2] = 4;
        test[3] = 6;
    }

    function foo() public {
        delete test[1];
        test[2] = 0;
    }
}