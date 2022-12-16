/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract Token {
    string public name = "My Hardhat Token";
    string public symbol = "MHT";
    uint256 public totalSupply = 1000000;
    address public owner;
    mapping(address => uint256) balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    /**
        A function to transfer tokens.

        The `external` modifier makes a function *only* callable from *outside* the contract.
     */
    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough tokens");

        // transfer amount
        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }

    /**
        Read only function to retrieve the token balance of a given account.

        The `view` modifier indicates that it doesn't modify the contract's
        state, which allows us to call it without executing a transaction.
     */
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}