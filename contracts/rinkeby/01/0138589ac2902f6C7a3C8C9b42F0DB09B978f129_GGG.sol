/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract GGG{
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    string public constant name = "GG Token";
    string public constant symbol = "GG";
    uint8 public constant decimals = 18;

    mapping(address => mapping (address => uint256)) allowed;

    constructor(){
        totalSupply = 1000 * 1000 * (10 ** decimals);
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address user) public view returns (uint256){
        return balances[user];
    }
    
    mapping(address => uint256) lastTimes;

    function transfer(address receiver, uint256 amount) public {
        require(receiver != address(0), "Transfer: invalid receiver");
        require(amount > 0, "Transfer: invalid amount");
        require(balances[msg.sender] >= amount, "Transfer: insufficent amount");

        require(block.timestamp - lastTimes[msg.sender] >= 10000, "Transfer: restricted");


        balances[msg.sender] = balances[msg.sender] - amount;
        balances[receiver] = balances[receiver] + amount;

        lastTimes[msg.sender] = block.timestamp;
    }

    function transferFrom(address sender, address receiver, uint256 amount) public {
        require(receiver != address(0) && sender != address(0), "Transfer: invalid addresses");
        require(amount > 0, "Transfer From: invalid amount");
        require(balances[sender] >= amount, "Transfer From: insufficent amount");
        require(allowance(sender, receiver) >= amount, "Tranfer From: Not approved");

        balances[sender] = balances[sender] - amount;
        balances[receiver] = balances[receiver] + amount;
        allowed[sender][receiver] = allowed[sender][receiver] - amount;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        // emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }
}