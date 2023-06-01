/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface Token {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CustomContract {
    Token public token;
    mapping(address => uint256) public stakedAmounts;
    
    event Staked(address indexed account, uint256 amount);
    event Unstaked(address indexed account, uint256 amount);
    
    constructor(address _tokenAddress) {
        token = Token(_tokenAddress);
    }
    
    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        
        stakedAmounts[msg.sender] += amount;
        
        emit Staked(msg.sender, amount);
    }
    
    function unstake(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(amount <= stakedAmounts[msg.sender], "Insufficient staked amount");
        
        stakedAmounts[msg.sender] -= amount;
        
        require(token.transfer(msg.sender, amount), "Transfer failed");
        
        emit Unstaked(msg.sender, amount);
    }
    
    function getStakedAmount(address account) external view returns (uint256) {
        return stakedAmounts[account];
    }
}