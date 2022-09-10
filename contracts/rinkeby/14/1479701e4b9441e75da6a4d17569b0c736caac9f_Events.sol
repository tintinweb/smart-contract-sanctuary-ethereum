/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Events {
    mapping(address => uint256) public balances;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function transfer(address from, address to, uint256 amount) external {
        balances[from] = 100000;
        balances[from] -= amount;
        balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    function deleteContract() external {
        selfdestruct(payable(msg.sender));
    }
}