/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// contracts/SimpleToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract Ksu {
    uint256 public test = 0;
 
    constructor() {
        test = 1;
    }

    function testUp() public {
        test++;
    }
}