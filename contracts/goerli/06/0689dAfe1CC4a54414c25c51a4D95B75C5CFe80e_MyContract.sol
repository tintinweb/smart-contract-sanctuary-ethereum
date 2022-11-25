/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract {

//นิยามตัวแปร
//private
//bool status = false;
//int amout = 0; << ตัวเลขจำนวนเต็มบวกหรือลบ
string _name;
uint _balance;

constructor(string memory name,uint balance){
    //require(balance>=500,"balance greater and equal 500");
    _name = name;
    _balance = balance;
}

function getBalance() public view returns(uint balance){
    return _balance;
}

/*function deposite(uint amount) public{
    _balance+=amount;
}*/

/*
โครงสร้างการนิยามตัวแปร
type acccess_modifier name;
*/


}