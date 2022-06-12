/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract{

// นิยามตัวแปร

/*
โครงสร้างการนิยามตัวแปร
type access_modifier name;
*/

/* default of access_modifier = private key
bool _status = false;
string public name = "Rungthida";
int _amount = 0;
uint _balance = 1000;
*/

/* private
string _name; // เรียกว่า attribute
uint _balance;

// constructor
constructor(string memory name, uint balance){
    require(balance >= 500, "balance greater than or equal 500 (money >= 500)");
    _name = name; //การกำหนดค่าเริ่มต้น
    _balance = balance;
}
*/

string _name; // เรียกว่า attribute
uint _balance;

constructor(string memory name, uint balance){
    //require(balance >= 500, "balance greater than or equal 500 (money >= 500)");
    _name = name; //การกำหนดค่าเริ่มต้น
    _balance = balance;
}

function getBalance() public view returns(uint balance){
    return _balance;
}

/*
function getBalance() public pure returns(uint balance){
    return 50;
}
*/

/*
function deposite(uint amount) public{
    _balance += amount;
}
*/

}