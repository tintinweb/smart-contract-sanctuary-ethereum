/**
 *Submitted for verification at Etherscan.io on 2023-03-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface ITRC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract USDTToken is ITRC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    
    constructor() {
        name = "Tether USD";
        symbol = "USDT";
        decimals = 6;
        totalSupply = 1000000000000000;
        balances[msg.sender] = totalSupply;
    }
    
    function balanceOf(address account) public view override returns (uint256) {
        return balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view override returns (uint256) {
        return allowed[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public override returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(amount <= balances[sender], "Insufficient balance");
        require(amount <= allowed[sender][msg.sender], "Insufficient allowance");
        balances[sender] -= amount;
        balances[recipient] += amount;
        allowed[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }
}