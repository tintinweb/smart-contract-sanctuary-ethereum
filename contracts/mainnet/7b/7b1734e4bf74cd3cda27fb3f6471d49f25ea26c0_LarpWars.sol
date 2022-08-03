/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

/**
Larp Wars is the only meme coin battle royale game. Biggest Game of 2022. May the best Larp win.
0% TAX TOKEN
BURNED LIQUIDITY
NO TEAM TOKENS
50% SUPPLY BURNED

https://twitter.com/Larpwars
https://larpwars.io/
https://t.me/Larpwars
*/


// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.7;

contract LarpWars {
    
    string public constant name = "LARPWARS";
    string public constant symbol = "LARPWARS";
    uint8 public constant decimals = 9;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    uint256 totalsupply;
    
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    constructor(){
        
        totalsupply = 1000000000 * 10 ** decimals;
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