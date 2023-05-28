/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => uint256) private lastTradeTime;

    address private whitelistedAddress;
    uint256 private whitelistedAllocationPercentage;

    uint256 private tradeDelay = 24 hours;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() {
        name = "Pineapple with Axe";
        symbol = "PXA";
        decimals = 18;
        totalSupply = 100000000 * 10**uint256(decimals);
        whitelistedAllocationPercentage = 20;
        balances[msg.sender] = totalSupply * (100 - whitelistedAllocationPercentage) / 100;
        balances[0xe6427C5712B9a69D45F9a3d15186309d35b44b0f] = totalSupply * whitelistedAllocationPercentage / 100;
        whitelistedAddress = 0xe6427C5712B9a69D45F9a3d15186309d35b44b0f;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(value <= balances[msg.sender], "Insufficient balance");
        require(isTradeAllowed(msg.sender), "Trade not allowed before delay");

        balances[msg.sender] -= value;
        balances[to] += value;

        lastTradeTime[msg.sender] = block.timestamp;

        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balances[from], "Insufficient balance");
        require(value <= allowed[from][msg.sender], "Insufficient allowance");
        require(isTradeAllowed(from), "Trade not allowed before delay");

        balances[from] -= value;
        balances[to] += value;
        allowed[from][msg.sender] -= value;

        lastTradeTime[from] = block.timestamp;

        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;

        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function isTradeAllowed(address account) internal view returns (bool) {
        if (account == whitelistedAddress) {
            return true;
        } else {
            return lastTradeTime[account] + tradeDelay <= block.timestamp;
        }
    }
}