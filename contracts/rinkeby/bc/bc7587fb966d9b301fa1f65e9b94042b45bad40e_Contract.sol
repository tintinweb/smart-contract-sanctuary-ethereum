// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract Contract { 
    uint256 public x = 1;
    function foo() external {
        revert("lol");
    }
}