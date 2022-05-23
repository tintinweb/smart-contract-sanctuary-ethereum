/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract Counter {
    uint256 public x;

    function incrementBy(uint256 _inc) public {
        x += _inc;
    }
}