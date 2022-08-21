/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract JeremyCoin {
   
    string public name;
    string public symbol;

    uint256 public totalSupply;
 
    mapping(address => uint256) private accountBalances;

    address owner;

    
    constructor(string memory _name, string memory _symbol, uint256 _initialSupply){
        name = _name;
        symbol = _symbol;
        totalSupply += _initialSupply;

        owner = msg.sender;
        accountBalances[owner] = _initialSupply;
    }

    event Transfer(address _from, address _to, uint256 _amount);
    


    function transfer(address _to, uint256 _amount) public {
       
        require(accountBalances[msg.sender] >= _amount, "Yout don't have enough balance!");
        

        accountBalances[msg.sender] -= _amount;
        accountBalances[_to] += _amount;

  
        emit Transfer(msg.sender, _to, _amount);
    }
    
 
    function balanceOf(address _address) public view returns (uint256){
        return accountBalances[_address];
    }
    
}