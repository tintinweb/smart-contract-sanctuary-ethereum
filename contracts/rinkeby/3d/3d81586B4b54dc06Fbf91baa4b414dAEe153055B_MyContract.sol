/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract{

//private
string _name;
uint _balance;

constructor(string memory name,uint balance){
    require(balance >= 500 ," deposit must more than 500");
    _name = name;
    _balance = balance;
}

function getBalance() public view returns (uint balance){
    return _balance;
}

}