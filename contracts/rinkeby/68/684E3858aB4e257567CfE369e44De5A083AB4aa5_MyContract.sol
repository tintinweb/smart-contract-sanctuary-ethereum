/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // ระบุ version

contract MyContract{
// นิยามตัวแปร // declare
// type acccess_modifier name;

// private
string _name;
uint _balance;


constructor(string memory name, uint balance){
    // return(เงื่อนไข , ถ้าผิดพลาดแจ้งเตือน);
    // require(balance>=500, "balance greater zero (money>o)");
    _name = name;
    _balance = balance;
}

function getBalance() public view returns(uint balance){
    return _balance;
}
// function deposite(uint amount) public{
//     _balance+=amount;
// }
// function getName() public view returns(string memory name){
//     return _name;
// }
}