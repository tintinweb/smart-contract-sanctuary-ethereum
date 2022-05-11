/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: MIT
pragma solidity^0.8.0;
contract My_contracts {

//นิยามตัวแปร

/*
โครงสร้างการนิยามตัวแปร
type(ชนิด) acccess_modifier(ใครเขาถึงได้บ้าง defualt เป็น private) name(พิมพ์เล็กพิมพ์ใหญ่ต่างกัน);
*/

//private
bool _status = false;
string _text = "Hi!";
uint _amount = 1000; // เก็บ +,0 ได้ - ไม่ได้

//private
string _name;
uint _balance;

constructor(string memory name,uint balance){
    require (balance >= 100,"balance greater and equal 100");
    _name = name;
    _balance = balance;
}

function getBalance() public view returns(uint balance){
    return _balance;
    //ถ้าไม่ได้ดึงค่าต้องใช้ pure
}
/*function deposit(uint amount) public{
    _balance+=amount;
}*/
}