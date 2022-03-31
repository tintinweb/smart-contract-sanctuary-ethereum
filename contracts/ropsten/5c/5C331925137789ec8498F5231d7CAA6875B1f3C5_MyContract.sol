/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
contract MyContract{
// private 
bool _status = false;
int _amount = 0;
string _name;
uint _balance ; // = 1000;

constructor(string memory name, uint balance){
    
    _name = name;
    _balance = balance;
}

function getBalance() public view returns(uint balance){
    return _balance; // ดึงค่า _balance จาก storage
}

function deposite(uint amount) public{
    _balance +=amount;
}
}