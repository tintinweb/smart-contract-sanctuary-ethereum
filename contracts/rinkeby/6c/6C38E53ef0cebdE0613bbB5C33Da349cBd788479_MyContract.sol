/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract{

string _name;        
uint _balance;                      

constructor(string memory cusname,uint newbalance){
    _name       = cusname;
    _balance    = newbalance;
}

function getBalance() public view returns(uint balance){
    return _balance;
}
}