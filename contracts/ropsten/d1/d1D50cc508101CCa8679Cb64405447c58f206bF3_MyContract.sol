/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract{
//นิยามตัวแปร
/*
โครงสร้างการนิยามตัวแปร
type access_modifier name;
*/
//private
string _name ;
uint _balance ;
constructor(string memory name,uint balance){
    require(balance>=500,"balance greater and equal 500");
    _name = name;
    _balance = balance;
}
function getBalance() public view returns(uint balance){
    return _balance;
}
function getStablePureValue() public pure returns(uint x){
    return 50;
}
// function deposite(uint amount) public{
//     _balance+=amount;
// }
}