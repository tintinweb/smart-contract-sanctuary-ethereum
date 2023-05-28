/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TheCode {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public sellLimit;
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    constructor() {
        name = "The Code";
        symbol = "CODE";
        decimals = 18;
        totalSupply = 1_000_000_000_000 * 10**uint256(decimals);
        sellLimit = 100_000 * 10**uint256(decimals);
        
        balanceOf[msg.sender] = totalSupply;
        
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= balanceOf[msg.sender], "Insufficient balance");
        require(to != address(0), "Invalid recipient");
        
        balanceOf[msg.sender] -= value;
        balanceOf[to] += value;
        
        emit Transfer(msg.sender, to, value);
        
        return true;
    }
    
    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        
        emit Approval(msg.sender, spender, value);
        
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balanceOf[from], "Insufficient balance");
        require(value <= allowance[from][msg.sender], "Insufficient allowance");
        require(to != address(0), "Invalid recipient");
        
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        
        emit Transfer(from, to, value);
        
        return true;
    }
}