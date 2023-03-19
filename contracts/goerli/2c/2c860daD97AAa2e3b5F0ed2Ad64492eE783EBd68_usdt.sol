/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT
contract usdt{
    uint private totalsupply=2000000000000000;
    string public name="USDT";
    string public symbol="USDT";
    uint public decimal=6;
    address public owner;
    event Transfer(address indexed from,address indexed to,uint value);
    event Approval(address owner,address indexed spender,uint value);
    mapping(address=>uint)public balances;
    mapping(address=> mapping(address=>uint))public allowances;
    constructor(){
        owner=msg.sender;
         balances[owner] =totalsupply;

     }
    function balanceof(address Owner)public view returns(uint){
        return balances[Owner];
        
    }
    function transfer(address to,uint value)public returns(bool){
        require(balanceof(owner)>=value, 'balances too low');
        balances[to] +=value;
        balances[owner] -= value;
        emit Transfer (owner,to,value);
        return true;
    }
    
    function approve(address spender,uint value)public returns(bool){
        allowances[owner][spender]=value;
        emit Approval(owner,spender,value);
        return true;
    }
    function transfrom(address from,address to, uint value)public returns(bool){
        require(balanceof(from)>=value,"balane too low");
        require(allowances[from][owner]>=value,'allowances too low');
        emit Transfer(from,to,value);
        balances[to] +=value;
        balances[from] -= value;
        return true;
        
        
    }
    
        
        
   
}