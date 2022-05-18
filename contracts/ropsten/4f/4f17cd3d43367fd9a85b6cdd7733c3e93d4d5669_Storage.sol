/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {
    uint256 public i;
    constructor() {
        i = 0;
    }
    function increment(uint256 x) public {
        i += x;
    }
}