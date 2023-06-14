/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

contract SampleContract {
    mapping(address => uint) public balances;

    constructor() {
        balances[msg.sender] = 100; // The deployer gets 100 Wei
    }

    function transfer(address to, uint value) external {
        balances[msg.sender] -= value;
        balances[to] += value;
    }

    function myVeryOwnCustomFunctionThatActsLikeTransfer(address to, uint value) public {
        balances[msg.sender] -= value;
        balances[to] += value;
    }
}