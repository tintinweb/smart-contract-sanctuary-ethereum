/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract {

string _name;
uint _balance;

// เริ่ม contract จะทำงานรอบเดียว ใช้นิยามค่าเริ่มต้น
constructor(string memory name,uint balance){
    // access_modifier private
    require(balance>=500,"Balance greater zero and 500");
    _name = name;
    _balance = balance;
}
// สามารถอ่านได้อย่างเดียว
function getbalance() public view returns(uint balance){
    return _balance;
}

}