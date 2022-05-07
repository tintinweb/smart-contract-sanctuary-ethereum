/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
contract PrathuangContract{

// private modifier คนอื่นไม่สามารถเห็นค่าตัวแปนที่กำหดไว้ได้
string _name;
uint _balance;

//นิยามตัวแปร

/*
โครงสร้างการนิยามตัวแปร
type access_modifyier name;
data type:bool, string,int, no float 
uint เป็นตัวเลขจำนวนเต็มไม่ให้มีลบ เช่น เงินคงเหลือในบัญชี
An access modifier has 2 type that is a private and public.
The sign of private is _ (underscore) in front of an avialable, 
and also add public in the term of public. 

*/
//สร้างDefault constructor เพื่อกำหนดค่าเริ่มต้นตัวแปรprathuangContract
//command function "require"เป็นการกำหนดข้อบังคับใน contract parameter

 constructor(string memory name,uint balance){
    _name = name;
    _balance = balance;                          
 }   
 function getBalance() public view returns(uint balance){
     return _balance;
 }
 
                         

}