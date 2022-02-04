/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract Test {
    uint temp;
    function mint(uint x) public returns (uint id) {
        x = x + 1;
        temp = x;
        id = x;
    }
}