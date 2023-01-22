/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract MyContract {
    mapping(address => uint256) public balance;

    constructor() {
        balance[msg.sender] = 100;
    }

    function transfer(address to, uint256 amt) public {
        balance[msg.sender] -= amt;
        balance[to] += amt;
    }

    function f(address add) public view returns (uint256) {
        return balance[add];
    }
}