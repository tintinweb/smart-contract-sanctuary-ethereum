/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;
contract ercTest {
    
    string public constant name = "Vlad test Coin ";
    
    string public constant symbol = "VTC";
    
    uint32 public constant decimals = 2;
     
    uint public totalCoin = 100000;
     mapping (address => uint256) public balances;
    constructor (){
        balances[msg.sender] = totalCoin;
    }

   event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function totalSupply() public view returns (uint256){
        return totalCoin;
    }

    function transfer(address _to, uint _amount)  public  returns ( bool success){
        require(balances[msg.sender] >= _amount,  "Not enough tokens" );
        balances[msg.sender]-= _amount;
        balances[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }
    function transferFrom(address _from, address _to, uint _amount)  public  returns (bool success){
        require(balances[_from] >= _amount,  "Not enough tokens" );
        balances[_from]-= _amount;
        balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function balanceOf(address _account)public view  returns(uint256 balance){
        return  balances[_account];
    }
    

    
}