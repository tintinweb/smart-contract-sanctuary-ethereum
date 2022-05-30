/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
contract MyContract{

//นิยามตัวแปร
//private
string _name;
uint _balance;

constructor(string memory name, uint balance){
    /*require(balance>=500,"Balance greater and equal 500");*/
    _name = name;
    _balance = balance;
}

function getBalance() public view returns(uint balance) /* view มีการดึงค่าจาก constructor*/{
    return _balance;
}


//function getBalance1() public pure returns(uint balance) /* pure ไม่ได้ดึงค่าจาก constructor*/{
    //return 600;
//}

//function deposite(uint amount) public{
// _balance += amount;
//}
/*
โครงสร้างการนิยามตัวแปร
type access_modifier name;
*/
}