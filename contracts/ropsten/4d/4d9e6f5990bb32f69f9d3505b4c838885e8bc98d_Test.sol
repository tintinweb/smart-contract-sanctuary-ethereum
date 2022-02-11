/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.11;

contract Test {
    uint256 public x;
    function overflow() public {
        x = type(uint256).max + 3;
    }
}