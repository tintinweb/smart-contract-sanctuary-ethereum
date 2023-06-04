/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IdleBurn {
    string public constant name = "IdleBurn";
    string public constant symbol = "IDBN";
    uint256 public constant totalSupply = 10_000_000_000;
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
        updateActivity(recipient);

        uint256 senderBurnAmount = calculateBurnAmount(msg.sender);
        uint256 recipientBurnAmount = calculateBurnAmount(recipient);

        require(amount <= balances[msg.sender] - senderBurnAmount, "Exceeds allowed transfer amount");

        if (senderBurnAmount > 0) {
            burnTokens(msg.sender, senderBurnAmount);
            balances[msg.sender] -= senderBurnAmount;
        }

        if (recipientBurnAmount > 0) {
            burnTokens(recipient, recipientBurnAmount);
            balances[recipient] -= recipientBurnAmount;
        }

        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function updateActivity(address account) private {
        lastActivity[account] = block.timestamp;
    }

    function burnTokens(address account, uint256 amount) private {
        balances[account] -= amount;
        balances[address(0)] += amount; // Sending to the burn address (address(0))
        totalBurned[account] += amount;
        emit Transfer(account, address(0), amount);
    }

    function calculateBurnAmount(address account) private view returns (uint256) {
        uint256 inactiveIntervals = (block.timestamp - lastActivity[account]) / (3 minutes);
        uint256 burnPercentage = inactiveIntervals * 1; // 1% burn per 3 minutes of inactivity
        uint256 burnAmount = (balances[account] * burnPercentage) / 100;
        return burnAmount > balances[account] ? balances[account] : burnAmount;
    }

    event Transfer(address indexed from, address indexed to, uint256 amount);
}