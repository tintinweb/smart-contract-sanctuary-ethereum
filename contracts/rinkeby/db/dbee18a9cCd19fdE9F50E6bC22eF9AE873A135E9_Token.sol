/**
 *Submitted for verification at Etherscan.io on 2022-05-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 < 0.9.0;
contract Token{
   string public name="hardhat Token";
   string public sybmol="HHT";
   uint public totalSupply=100000;

   address public owner;

   mapping(address=>uint) balances;

   constructor(){
       balances[msg.sender]=totalSupply;
       owner=msg.sender;
   }

   //transfer function 
   function transfer(address to,uint amount) external{
       require(balances[msg.sender]>=amount,"Not enough balance");
       balances[msg.sender]-=amount;
       balances[to]+=amount;
   }

   function balanceOf(address account) external view returns(uint balance){
       return balances[account];
   }
}