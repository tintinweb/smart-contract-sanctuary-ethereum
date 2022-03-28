/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
 
contract khuncontract{

string _name;
uint _balance;

constructor(string memory name,uint balance){
    _name=name;
    _balance=balance;
}

function getbalance()public view returns(uint s){
    return _balance;
}

}