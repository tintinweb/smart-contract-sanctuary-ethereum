/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


contract PrivateAccessDemo {
    uint256 private privateVariable;
    uint256 public publicVariable;

    constructor(uint256 privateValue, uint256 publicValue) {
        privateVariable = privateValue;
        publicVariable = publicValue;
    }
}