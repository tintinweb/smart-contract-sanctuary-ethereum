/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HashLabsToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    constructor() {
        name = "HashLabs";
        symbol = "HASH";
        totalSupply = 1000000000;
        balanceOf[msg.sender] = totalSupply;
    }
}