/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.7.6;

contract Counter {
    uint256 count;  // persistent contract storage

    constructor(uint256 _count) { 
        count = _count;
    }

    function increment() public {
        count += 1;
    }

    function getCount() public view returns (uint256) {
        return count;
    } 
}