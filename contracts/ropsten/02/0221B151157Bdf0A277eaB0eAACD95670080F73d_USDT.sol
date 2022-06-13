/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract USDT {
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);

    string public constant name = "Tether USD";
    string public constant symbol = "USDT";
    
    uint8 public constant decimals = 18;

    uint256 public totalSupply_;

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        totalSupply_ = 20 * 1000 * 1000 * 1000 * (10 ** decimals);
        balances[msg.sender] = totalSupply_;

    }

    function transfer(address receiver, uint256 amount) public returns (bool) {
        require(balances[msg.sender] >= amount, "Transfer: insufficient tokens amount");
        
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Transfer(msg.sender, receiver, amount);
        return true;
    }

    function transferFrom(address sender, address receiver, uint256 amount) public returns (bool) {
        require(balances[sender] >= amount, "Transfer From: insufficient amount");
        require(allowance(sender, receiver) >= amount, "Transfer From: Not approved");

        balances[sender] -= amount;
        balances[receiver] += amount;
        allowed[sender][receiver] = allowed[sender][receiver] - amount;
        emit Transfer(sender, receiver, amount);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address ownerAddress, address delegate) public view returns (uint256) {
        return allowed[ownerAddress][delegate];
    }

    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }
}