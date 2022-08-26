/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

/**
Sun Finance

Sun Finance is the permissionless money market for borrowing, lending, and shorting crypto assets. This means that anyone at anytime is able to create a money market for any crypto asset.

Token Allocation

25% Team and Staking Tokens locked for 7 days.
25% Burn
50% LP Tokens

Total Tax 0%

https://twitter.com/SunFinanceERC
https://sunfinance.io/
https://t.me/SunFinanceVERIFY
*/


// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.7;

contract SunFinance {
    
    string public constant name = "Sun Finance";
    string public constant symbol = "SF";
    uint8 public constant decimals = 9;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    uint256 totalsupply;
    
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    constructor(){
        
        totalsupply = 10000000 * 10 ** decimals;
        balances[msg.sender] = totalsupply;
    }
    
    function totalSupply() public view returns (uint256) {
        
        return totalsupply;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint){
        
        return balances[tokenOwner];
    }
    
    function transfer(address receiver, uint numTokens) public returns(bool){
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender] - numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    function approve(address delegate, uint numTokens) public returns (bool){
        
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    
    function allowance(address owner, address delegate) public view returns (uint){
        
        return allowed[owner][delegate];
        
    }
    
    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool){
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
        balances[owner] = balances[owner] - numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
        balances[buyer] = balances[buyer] + numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
        
    }
 }