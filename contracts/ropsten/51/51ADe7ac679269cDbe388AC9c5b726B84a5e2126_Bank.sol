/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Bank{

mapping(address => uint) _balances; 
uint _totalSupply;
//รับเงินจริง

function deposite() public payable{
         
    //_balance+=amount;
    _balances[msg.sender]+=msg.value;
    _totalSupply +=msg.value;
}

function withdraw(uint  amount) public payable {
     require(amount<=_balances[msg.sender] ,"not enough money");  
    payable(msg.sender).transfer(amount);
    _balances[msg.sender]-=amount;
    _totalSupply -=amount;
}

function getBlance() public view returns(uint balance){
   // return _balance;
   return _balances[msg.sender];
}

function getBankBlance() public view returns(uint balance){
   // return _balance;
   return _totalSupply;
}

}