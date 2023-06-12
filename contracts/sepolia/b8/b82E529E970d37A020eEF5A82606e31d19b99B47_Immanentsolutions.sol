/**
 *Submitted for verification at Etherscan.io on 2023-06-12
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8;

contract Immanentsolutions {
    string public name = "IMMANENT SOLUTIONS";
    string public symbol = "IMNTS";
    uint public decimals = 18;
    uint public totalSupply = 10000000000000000000000;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowances;

    constructor() {
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address account) public view returns (uint) {
        return balances[account];
    }

    function transfer(address to, uint amount) public {
        require(amount <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function transferFrom(address from, address to, uint amount) public {
        require(amount <= balances[from], "Insufficient balance");
        require(amount <= allowances[from][msg.sender], "Insufficient allowance");
        balances[from] -= amount;
        balances[to] += amount;
        allowances[from][msg.sender] -= amount;
    }

    function approve(address spender, uint amount) public {
        allowances[msg.sender][spender] = amount;
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return allowances[owner][spender];
    }
}