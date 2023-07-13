/**
 *Submitted for verification at Etherscan.io on 2023-07-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract AiMuskToken {
    string public name; 
    string public symbol; 
    uint8 public decimals; 
    uint256 public totalSupply; 

    mapping(address => uint256) public balanceOf; 
    mapping(address => mapping(address => uint256)) public allowance; 

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    
    constructor() {
        name = "Ai Musk";
        symbol = "AI MUSK";
        decimals = 18;
        totalSupply = 1000000000 * (10**uint256(decimals)); 

        
        balanceOf[msg.sender] = totalSupply;
    }

    
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Invalid address");
        require(balanceOf[msg.sender] >= _value, "Insufficient balance"); 

        uint256 taxAmount = (_value * 1) / 100; 
        uint256 transferAmount = _value - taxAmount; 

        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += transferAmount;
        balanceOf[address(this)] += taxAmount;

        emit Transfer(msg.sender, _to, transferAmount);

        return true;
    }

    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "Invalid address"); 

        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_from != address(0), "Invalid address"); 
        require(_to != address(0), "Invalid address"); 
        require(balanceOf[_from] >= _value, "Insufficient balance"); 
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance"); 

        uint256 taxAmount = (_value * 1) / 100; 
        uint256 transferAmount = _value - taxAmount; 
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += transferAmount;
        balanceOf[address(this)] += taxAmount;

        
        allowance[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, transferAmount);

        return true;
    }
}