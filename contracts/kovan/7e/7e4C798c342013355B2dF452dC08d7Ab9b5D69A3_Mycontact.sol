/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Mycontact{

string _name;
uint _balance;

constructor(string memory name, uint balance){
    // require(balance>0,"balance OVER");
    _name = name;
    _balance = balance;
}

function getBalance() public view returns(uint balance){
    return _balance;
}

// function getBalance() public pure returns(uint balance){
//     return 100;
// }

// function deposite(uint amount) public{
//     _balance += amount;
// }

}