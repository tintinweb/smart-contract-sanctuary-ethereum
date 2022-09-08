/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

//SPDX-License-Identifier: MIT


pragma solidity ^0.8.9;

contract Token {

    string public name = "New Practice Token";
    string public symbol = "NPT";
    uint8 public decimals;

    uint256 public totalSupply = 1_000_000_000_000_000_000_000;

    address public owner;

    mapping(address => uint256) balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
        decimals = 18;
    }

    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough tokens");
        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}