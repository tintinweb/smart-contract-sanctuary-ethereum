/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IdleBurn {
    string public constant name = "IdleBurn";
    string public constant symbol = "IDBN";
    uint256 public constant totalSupply = 10000000000;
    uint8 public constant decimals = 0;
    
    mapping(address => uint256) private balances;
    mapping(address => uint256) private lastActivity;
    mapping(address => uint256) private totalBurned;

    constructor() {
        balances[msg.sender] = totalSupply;
        lastActivity[msg.sender] = block.timestamp;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    
    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(amount <= balances[msg.sender], "Insufficient balance");
        
        updateActivity(msg.sender);
        burnTokens(msg.sender);
        
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function updateActivity(address account) private {
        lastActivity[account] = block.timestamp;
    }
    
    function burnTokens(address account) private {
        uint256 burnPercentage = calculateBurnPercentage(account);
        uint256 amount = (balances[account] * burnPercentage) / 100;
        balances[account] -= amount;
        balances[address(0)] += amount; // Sending to the burn address (address(0))
        totalBurned[account] += amount;
        emit Transfer(account, address(0), amount);
    }
    
    function calculateBurnPercentage(address account) private view returns (uint256) {
        uint256 inactiveDays = (block.timestamp - lastActivity[account]) / 1 days;
        uint256 burnPercentage = (inactiveDays / 3) + 1; // Compounding burn percentage
        return burnPercentage > 100 ? 100 : burnPercentage; // Limiting burn percentage to 100%
    }
    
    event Transfer(address indexed from, address indexed to, uint256 amount);
}