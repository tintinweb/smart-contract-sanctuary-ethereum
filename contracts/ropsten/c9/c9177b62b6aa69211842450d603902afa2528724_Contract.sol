/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract Contract {
    uint256 public counter;

    constructor() {
        counter = 0;
    }

    function increment() public {
        counter++;
    }
    
}