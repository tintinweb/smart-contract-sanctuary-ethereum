/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT อย่าลืมใส่ตามนี้
pragma solidity ^0.8.7; //ต้องการใช้งานภาษาใด พิมตามนั้น
contract Mycontract{

//private _ตัวแปร เป็นต้น คือรูปแบบในการเขียน
string _name;
uint _balance;

//constructor จะทำงานเริ่มต้นเสมอ รันครั้งเดียวเท่านั้น
constructor (string memory name , uint balance) {
        _name = name;
        _balance = balance;
}

function getbalance() public view returns(uint balance){
        return _balance;
}
}