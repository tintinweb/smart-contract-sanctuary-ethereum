/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ERC20Basic {

    string public constant name = "ARSENII USD";
    string public constant symbol = "AUSD";
    uint8 public constant decimals = 18;  


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) balances;

    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_ = 1000 ether;



   constructor() {  
	balances[msg.sender] = totalSupply_;
    }  

    function totalSupply() public  view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public  view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public  returns (bool) {
        balances[msg.sender] = balances[msg.sender]- numTokens;
        balances[receiver] = balances[receiver] + numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public  returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public  view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public  returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner] - numTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numTokens;
        balances[buyer] = balances[buyer] + numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}