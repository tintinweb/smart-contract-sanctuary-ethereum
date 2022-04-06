/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
contract myContract{
//นิยามตัวแปร

/* private ตั้งค่าปกป้อง */
//private   
string _name;
uint _balance;
    constructor(string memory name,uint balance){
        _balance = balance;
        _name = name;
    }
    function get_balance1() public view returns(uint balance){  //view อ่านข้อมูลได้อย่างเดียวแก้ไขไม่ได้ ไม่ต้องจ่ายค่า Gas
        return _balance;
    }
}