/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract DeflationaryToken {
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    uint public totalSupply;
    string public name;
    string public symbol;
    uint public decimals;
    uint public deflation;
    uint public minSupply;
    uint public initialSupply;
    uint public burnt;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
    constructor(string memory _name, string memory _symbol, uint _dec, uint _supply, uint _deflation, uint _minSupply, address _owner) {
        name = _name;
        symbol = _symbol;
        decimals = _dec;
        totalSupply = _supply * 10 ** decimals;
        initialSupply = _supply * 10 ** decimals;
        deflation = _deflation;
        minSupply = _minSupply * 10 ** decimals;
        burnt = 0;
        balances[_owner] = totalSupply;
        emit Transfer(address(0), _owner, totalSupply);
    }
    
    function balanceOf(address owner) public view returns(uint) {
        return balances[owner];
    }
    
    function transfer(address to, uint value) public returns(bool) {
        require(balances[msg.sender] >= value, 'balance too low');
        
        balances[msg.sender] -= value;
        
        if (deflation > 0 && totalSupply > minSupply) {
            uint defAmount = value * deflation / 1000;
            
            if (defAmount > 0) {
                
                if (totalSupply - defAmount < minSupply) {
                    defAmount = totalSupply - minSupply;
                }
                value = value - defAmount;
                totalSupply -= defAmount;
                burnt += defAmount;
                emit Transfer(msg.sender, address(0), defAmount);
            }
        }
        
        balances[to] += value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
    function transferFrom(address from, address to, uint value) public returns(bool) {
        require(balances[from] >= value, 'balance too low');
        require(allowed[from][msg.sender] >= value, 'allowance too low');
        
        balances[from] -= value;
        allowed[from][msg.sender] -=value;

        if (deflation > 0 && totalSupply > minSupply) {
            uint defAmount = value * deflation / 1000;
            
            if (defAmount > 0) {
                
                if (totalSupply - defAmount < minSupply) {
                    defAmount = totalSupply - minSupply;
                }
                
                value = value - defAmount;
                totalSupply -= defAmount;
                burnt += defAmount;
                emit Transfer(from, address(0), defAmount);
            }
        }
        
        balances[to] += value;
        emit Transfer(from, to, value);
        return true;   
    }
    
    function approve(address spender, uint value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;   
    }
    
    function allowance(address owner, address spender) public view returns (uint) {
        return allowed[owner][spender];
    }
    
}