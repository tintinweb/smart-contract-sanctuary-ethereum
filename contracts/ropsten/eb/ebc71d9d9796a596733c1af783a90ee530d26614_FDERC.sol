/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// File: gist-8e81dbde10c9aeff69a1d683ed6870be/FDERC.sol

//SPDX-License-Identifier: MIT License
pragma solidity ^0.8.7;

contract FDERC {
 
    address public minter;


    event Approval(address indexed ownerToken, address indexed spender, uint tokens);
    event Send(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_;

    constructor(uint256 total) {  
        totalSupply_ = total;
        balances[msg.sender] = totalSupply_;
        minter = msg.sender;
    }

    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        balances[receiver] += amount;
    }

    error InsufficientBalance(uint requested, uint available);

    function totalSupply() public view returns (uint256) {
	    return totalSupply_;
    }
    
    function balanceOf(address ownerToken) public view returns (uint) {
        return balances[ownerToken];
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function send(address receiver, uint amount) public returns (bool) {
        if(amount <= balances[msg.sender]) {
            revert InsufficientBalance({
                requested: amount,
                available: balances[msg.sender]
            });
        }
        
        balances[msg.sender] = balances[msg.sender] -= amount;
        balances[receiver] = balances[receiver] += amount;
        emit Send(msg.sender, receiver, amount);
        return true;
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner] -= numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] -= numTokens;
        balances[buyer] = balances[buyer] += numTokens;
        emit Send(owner, buyer, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

}