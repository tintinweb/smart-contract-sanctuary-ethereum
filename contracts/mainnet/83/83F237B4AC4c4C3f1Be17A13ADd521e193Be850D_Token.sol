/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

//SPDX-License-Identifier: MIT


pragma solidity ^0.8.9;



contract Token {
    
      string public name = "Genesis";
    string public symbol = "Gen";
    uint8 public decimals = 18;
    uint256 public totalSupply = 400000000000 * 10**uint256(decimals);

    
    address public owner;

    
    mapping(address => uint256) balances;

    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

  
    constructor() {
        
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }

    function transfer(address to, uint256 amount) external {
        
        require(balances[msg.sender] >= amount, "Not enough tokens");

        
        balances[msg.sender] -= amount;
        balances[to] += amount;

        
        emit Transfer(msg.sender, to, amount);
    }

    
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}