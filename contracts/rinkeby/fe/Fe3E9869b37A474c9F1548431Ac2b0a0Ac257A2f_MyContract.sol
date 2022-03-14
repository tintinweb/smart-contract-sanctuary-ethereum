/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract{

//นิยามตัวแปร

/*
โครงสร้างการนิยามตัวแปร
type access_modifier name;
*/

//private มักนิยมใส่ _ นำหน้าชื่อ
string _name;
uint _balance;

//Constructor ฟังก์ชั่นที่ถูกเรียกใช้และทำงานอัตโนมัติเพียงครั้งเดียว ในตอนเริ่ม รันหรือ Deploy
//require(เงื่อนไข,ผลลัพท์);
constructor(string memory name, uint balance){
    _name = name;
    _balance = balance;

}

/* การเขียนโครงสร้าง function คือ กลุ่มคำสั่งหรือการแบ่งส่วนการทำงานที่อยู่ใน smart contract
    function ชื่อฟังก์ชั่น(<parameter type){public|private}
    [pure|view|payable][returns (<return types>)]
    pure => ใช้กับค่าคงเท่านั้น ไม่มีการยุ่งเกี่ยวกับการเปลี่ยนแปลงค่า storage
    view => แจ้งฟังก์ชั่นนี้มีการยุ่งเกี่ยวกับค่าใน storage สามารถอ่านค่าใน storage ได้อย่างเดียว
    payable => ฟังก์ชั่นนี้มีการเรียกเก็บเงิน(Ether) ก่อนจะทำงานในฟังก์ชั่น
*/

function getBalance() public view returns(uint balance){
    return _balance;
}

}