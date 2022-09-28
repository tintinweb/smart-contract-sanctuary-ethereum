/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0; 

interface ERC20Interface {
    function totalSupply() external view returns (uint); 
    function balanceOf(address tokenOwner) external view returns (uint balance); 
    function transfer(address to, uint tokens) external returns (bool success); 
    
    // function allowance(address tokenOwner, address spender) external view returns(uint remaining); 
    // function approve(address spender, uint tokens) external returns (bool success); 
    // function transferFrom(address from, address to, uint tokens) external returns (bool success); 

    event Transfer(address indexed from, address indexed to, uint tokens); 
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens); 

}

contract Cryptos is ERC20Interface {
    string public name = "CoochieCoin"; 
    string public symbol = "CCOIN"; 
    uint public decimals = 0; // 18 is the most popular number that is used 
    uint public override totalSupply; 

    address public founder; 
    mapping(address => uint) public balances; // Making a mapping of the balances here
    
    constructor() {
        founder = msg.sender; 
        totalSupply = 1000000; 
        balances[founder] = totalSupply; 
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner]; 
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        require(balances[msg.sender] >= tokens, "You do not have enough tokens to send!"); // On failure we are going to revert

        balances[to] += tokens; 
        balances[msg.sender] -= tokens; 
        
        // We are going to emit an event
        emit Transfer(msg.sender, to, tokens); 
        return true; 
    }





}