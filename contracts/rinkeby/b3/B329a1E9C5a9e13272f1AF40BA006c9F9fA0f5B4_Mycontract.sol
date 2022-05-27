/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Mycontract {

//private
string _name;
uint _balance;

constructor(string memory name,uint balance){
    require(balance>5,"balance must greater than 5");
    _name = name;
    _balance = balance+50;
}

function getBalance() public view returns(uint balance){
    return _balance; 
}

// function deposit(uint amount) public{
//     _balance += amount;
// }
}