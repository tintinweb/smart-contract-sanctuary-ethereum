/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract{
//นิยามตัวเเปร
/*
โครงสร้างการนิยามตัวเเปร 
type access_modifier name;
*/

//private
bool _status = false;
string _name;
uint _amount;
uint _balance;

//Constructor: one time function เวลา deploy ต้องใส่ค่า "Safe",500 ด้วย
constructor(string memory name, uint balance){
    require(balance>0,"balance greater zero (money>0)");
    _name = name;
    _balance = balance;

}

// function: pure view payable 
function getBalance() public view returns(uint balance){
    return _balance;
}
/*
function deposit(uint amount) public{
    _balance+=amount;
}
*/
}