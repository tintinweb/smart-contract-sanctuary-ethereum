/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// Write a smart contract with 2 functions:
// 1. Store a number
// 2. Retrieve the same number

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.17;

contract Store {
    uint256 public number;

    function store(uint256 _number) public {
        number = _number;
    }

    function retrieve() public view returns (uint256) {
        return number;
    }
}