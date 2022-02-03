/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.0;

contract test {
    
    string public constant name = "test Coin ";
    
    string public constant symbol = "YTC";
    
    uint32 public constant decimals = 2;
     
    uint public totalCoin = 100000;
    mapping(address=>uint)balances;
    constructor (){
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
    function balanceAccount(address _acconts) view public returns(uint){
        return  balances[_acconts];
    }
}