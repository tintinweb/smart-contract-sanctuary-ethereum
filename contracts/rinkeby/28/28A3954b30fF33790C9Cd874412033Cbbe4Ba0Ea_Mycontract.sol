/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Mycontract{

//private 
string _name;
uint256 _balance;

constructor(string memory name, uint256 balance) {
    require(balance >= 499, "balance greater and equal 500");
    _name = name;
    _balance = balance;
}

function getBalance() public view returns(uint256 balance){
    return _balance;
}

function deposite(uint256 amount) public {
    _balance += amount;
}
}