/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract{

//private bool คือ ค่าตัวแปร 
string _name;
uint _balance;

constructor(string memory name,uint balance){
    _name = name;
    _balance = balance;
}

function geBalance() public view returns(uint balance){
    return _balance;
}
}