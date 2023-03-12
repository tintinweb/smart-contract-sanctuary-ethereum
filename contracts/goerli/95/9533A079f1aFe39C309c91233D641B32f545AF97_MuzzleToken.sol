/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MuzzleToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => bool) private whitelist;
    mapping(address => bool) private blacklist;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        name = "Muzzle Token";
        symbol = "MUZZ";
        totalSupply = 2100000000000000;
        balances[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance");

        if (blacklist[msg.sender]) {
            return false;
        }

        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(amount <= balances[sender], "Insufficient balance");
        require(amount <= allowances[sender][msg.sender], "Insufficient allowance");

        if (blacklist[sender]) {
            return false;
        }

        balances[sender] -= amount;
        allowances[sender][msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowances[owner][spender];
    }

    function addToWhitelist(address account) public returns (bool) {
        require(!whitelist[account], "Account is already whitelisted");
        
        whitelist[account] = true;
        
        return true;
    }
    
    function removeFromWhitelist(address account) public returns (bool) {
        require(whitelist[account], "Account is not whitelisted");
        
        whitelist[account] = false;
        
        return true;
    }
    
    function addToBlacklist(address account) public returns (bool) {
        require(!blacklist[account], "Account is already blacklisted");
        
        blacklist[account] = true;
        
        return true;
    }
    
    function removeFromBlacklist(address account) public returns (bool) {
        require(blacklist[account], "Account is not blacklisted");
        
        blacklist[account] = false;
        
        return true;
    }
    
    function sellTax(uint256 amount) internal pure returns (uint256) {
        return amount / 10;
    }

    function buyTax(uint256) internal pure returns (uint256) {
        return 0;
    }
}