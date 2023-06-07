/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HashLabsToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    mapping(address => uint256) balances;

    constructor() {
        name = "HashLabs";
        symbol = "HASH";
        totalSupply = 1000000000;
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
}