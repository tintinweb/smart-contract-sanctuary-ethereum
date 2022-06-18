/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract{

//นิยามตัวแปล
/*
โครงสร้่างการนิยามตัวแปร
type access_modifier  name;
*/

string  _name="noraset";
uint _balance = 100000;

constructor(string memory name,uint balance){
    require(balance>=500,"balance greater 500");
    _name=name;
    _balance = balance;
    
}

function getBlance() public view returns(uint balance){
    return _balance;
}

function getDegree() public pure returns(uint ins){
    return 50;
}

function deposite(uint  amount) public {
     require(amount>=0,"amount greater 0");
    _balance+=amount;
}

}