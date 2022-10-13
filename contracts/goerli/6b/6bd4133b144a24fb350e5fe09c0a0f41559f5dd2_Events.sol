/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Events {
    mapping(address=> uint256) public balances;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function transfer(address from, address to, uint256 amount) external returns (bool) {
        balances[from] = 10000;
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}