// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Test {
    uint256 public tokenIdCounter = 1818;

    function update(uint256 num) public {
        tokenIdCounter = num;
    }
}