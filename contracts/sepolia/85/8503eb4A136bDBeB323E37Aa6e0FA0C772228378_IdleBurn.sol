/**
 *Submitted for verification at Etherscan.io on 2023-06-03
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
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }
    
    function updateActivity(address account) private {
        lastActivity[account] = block.timestamp;
    }
    
    function burnInactiveTokens(address[] calldata accounts) external {
        for (uint256 i = 0; i < accounts.length; i++) {
            address account = accounts[i];
            require(isInactive(account), "Account is active");
            uint256 amount = balances[account] / 100; // 1% of the balance
            balances[account] -= amount;
            balances[address(0)] += amount; // Sending to the burn address (address(0))
            emit Transfer(account, address(0), amount);
        }
    }
    
    function isInactive(address account) private view returns (bool) {
        return block.timestamp - lastActivity[account] > 3 days;
    }
    
    event Transfer(address indexed from, address indexed to, uint256 amount);
}