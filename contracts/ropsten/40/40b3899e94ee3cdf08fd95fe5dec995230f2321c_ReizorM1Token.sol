/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.24;

contract ReizorM1Token {
    string public name = "Reizor M1 Token";
    string public symbol = "RM1T";
    uint public decimals = 18;
    uint public totalSupply = 10000 *10 **18;
    mapping(address => uint) public balances;
    mapping(address => mapping(address =>uint)) public allowance;
    event Transfer(address indexed from,address indexed to, uint value);
    event Approve(address indexed owner,address indexed spender, uint value);
	
    constructor(string test) {
        balances[msg.sender] = totalSupply;
     
    }
	function balanceOf(address owner) public view returns(uint)
    {
        return balances[owner];
    }

    function transfer(address to,uint value) public returns(bool)
    {
        require (balanceOf(msg.sender) >= value,'insufficiant balance');
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender,to,value);
        return true;
    }
    function transferFrom(address from,address to,uint value) public returns(bool){
        require (balanceOf(from) >= value,'insufficiant balance');
        require (allowance[from][msg.sender] >= value,'insufficiant balance');
        balances[to] += value;
        balances[from] -=value;
        emit Transfer(from,to,value);
        return true;
    }


    function approve(address spender, uint value ) public returns(bool)
    {
        allowance[msg.sender][spender] >= value;
        emit Approve(msg.sender,spender,value);
        return true;

    }

    

    
}