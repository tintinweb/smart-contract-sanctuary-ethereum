/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Mycontract{


string _name;
uint _balance;

constructor(string memory name,uint balance){
    require(balance>0,"balance greater zero");
    _name = name;
    _balance = balance;
}
function getBalance() public view returns(uint balance){
    return _balance;
}
}