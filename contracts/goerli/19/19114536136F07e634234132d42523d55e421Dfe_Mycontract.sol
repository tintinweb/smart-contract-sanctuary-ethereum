/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

//Function
/*
โครงสร้าง
function ชื่อฟังก์ชั่น(<parameter types>) {public|private}
[pure|view|payable][returns(<return types>)]
pure : แจ้งว่า Function นี้ใช้งานกับค่าคงที่เท่านั้นไม่มีการยุ่งเกี่ยวกับการเปลี่ยนแปลงค่า Storage
view : แจ้งว่า Function นี้มีการยุ่งเกี่ยวกับค่าใน Storage หรือสามารถอ่านค่าจาก Storage ได้เพียงอย่างเดียว
payable : เป็นการบ่งบอกว่า Function นี้มีการเรียกเก็บเงิน(Ether)ก่อนจะทำงานใน Function
*/
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0 ;
contract Mycontract{

//private
string _name ;
uint _balance ;

constructor(string memory name,uint balance){
    require(balance >= 500,"balance greater and equal 500") ;
    _name = name ;
    _balance = balance ;
}

function getbalance() public view returns(uint balance){ //view ดึงข้อมูลออกมาใช้งาน
    return _balance ;
}

function deposite(uint amount) public{
    _balance+=amount ;
}


}