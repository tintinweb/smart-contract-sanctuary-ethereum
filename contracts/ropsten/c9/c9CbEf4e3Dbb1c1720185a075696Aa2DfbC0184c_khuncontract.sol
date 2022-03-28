/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract khuncontract{

mapping(address=>uint) _balance;
uint _totalsupply;

function getbalance()public view returns(uint b){
    return _balance[msg.sender];
}

function deposit()public payable{
    _balance[msg.sender] += msg.value;
    _totalsupply+=msg.value;
}

//msg.sender=address

function withdraw(uint amount)public payable{
    require(amount<=_balance[msg.sender]);
    payable(msg.sender).transfer(amount);
    _totalsupply-=amount;
    _balance[msg.sender] -= amount;
}

function checksupply()public view returns(uint totalsupply){
    return _totalsupply;
}
}