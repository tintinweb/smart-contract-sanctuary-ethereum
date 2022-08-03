/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Counter  {
    uint public counter;

    constructor() {
      counter = 1;
    }
 
    function increment() external {
        unchecked {
            ++counter;
        }
    }
}