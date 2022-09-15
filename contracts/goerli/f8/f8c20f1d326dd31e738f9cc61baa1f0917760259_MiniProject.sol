/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: SEE IN LICENSE    



pragma solidity ^0.8.9;


contract MiniProject {
    
    string public name= "MiniProject";
    string public symbol = "MIP";
    uint256 public decimals = 18;
    uint public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
    address public owner;

    mapping (address => uint) balance;
    mapping(address=> mapping(address=>uint)) public allowance;

    constructor()
    {
        balance[msg.sender] = totalSupply;
        owner = msg.sender;

    }

    function transfer(address _to, uint256 _amount) external
    {
        
        require(balance[msg.sender] >= _amount, "Insufficient Balance");

        balance[msg.sender] = balance[msg.sender] - _amount;
        balance[_to] = balance[_to] + (_amount);
    }

    function balanceOf(address account) public view returns (uint256) 
    {
     return balance[account];
    }

    function approval(address spender, uint value) public returns(bool)
    {

        require(msg.sender == owner , "You are not the owner");
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferfrom(address from, address to, uint value) public returns(bool)
    {
        require(balance[msg.sender]>= value, "Insufficient balance");
        require(allowance[from][msg.sender]>= value, "you are not allowed to make this transaction");

        balance[from] -= value;
        balance[to] += value;

        emit Transfer(from,to,value);

        return true;

    }



    function mint(uint amount ) external
    {
        require(msg.sender == owner, "You are not owner");
        balance[msg.sender] +=amount;
        totalSupply += amount;
        
        emit Transfer(address(0),msg.sender,amount);
    }
    
    function burn(uint amount) external
    {   
        require(msg.sender == owner, "You are not owner");
        balance[msg.sender] -=amount;
        totalSupply -= amount;
        emit Transfer(msg.sender,address(0),amount);
    }

}