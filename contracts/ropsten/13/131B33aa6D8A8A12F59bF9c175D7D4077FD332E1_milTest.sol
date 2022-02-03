/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;


contract milTest{
    
    string public constant name = "Milion";

    string public constant symbol = "MIL";

    uint32 public constant decimals = 2;
    
    uint256 public constant totalCoin = 1000000;
    
    address public owner;
    
    mapping(address => uint256) balances;
    
    constructor() {
        
        
        balances[msg.sender] = totalCoin;
    
    }
  
      function transfer(address _to, uint _amount)  public  returns ( bool success){
        require(balances[msg.sender] >= _amount,  "Not enough tokens" );
        balances[msg.sender]-= _amount;
        balances[_to] += _amount;
        return true;
    }

      function transferFrom(address _from, address _to, uint _amount)  public  returns (bool success){
        require(balances[_from] >= _amount,  "Not enough tokens" );
        balances[_from]-= _amount;
        balances[_to] += _amount;
        return true;
    }

    
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
}