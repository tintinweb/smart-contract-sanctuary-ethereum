// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Token {
    string public name = "My Hardhat Token";
    string public symbol = "MBT";

    uint256 public totalSupply = 1000000;

    address public owner;
    mapping(address => uint256) balances;

    /**
     * 合约构造函数
     *
     * The `constructor` is executed only once when the contract is created.
     */
    constructor() {
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    /**
     * 代币转账.
     *
     * The `external` modifier makes a function *only* callable from outside
     * the contract.
     */
    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Not enough tokens");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}