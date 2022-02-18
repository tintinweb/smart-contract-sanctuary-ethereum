/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;


contract Reproducer {
    uint256 x;
    constructor() {
        x = 1;
    }

    function setX(uint256 _x) public {
        x = _x;
    }
}