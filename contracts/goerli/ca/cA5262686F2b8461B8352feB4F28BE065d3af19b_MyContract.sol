/**
 *Submitted for verification at Etherscan.io on 2022-12-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract{

/*นิยามตัวแปร
type access_modifier name; กำหนดให้คนใดเข้าถึงได้บา้ง
*/
string _name;
uint _amount;

constructor(string memory name, uint amount){
    require(amount>0,"amount greater zero(money>0)"); //กำหนดข้อบังคับโดยใช้ require
    _name = name;
    _amount = amount;
}
function getAmount() public view returns(uint amount){
    return _amount;
}
}