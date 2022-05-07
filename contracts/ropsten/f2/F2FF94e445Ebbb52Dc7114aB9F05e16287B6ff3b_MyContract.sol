/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract    MyContract{

//private
string _name;
uint _balance;

constructor(string memory name, uint balance){
    _name = name;
    _balance = balance;

}
function getBalance() public view returns(uint balance){
        return _balance;

}

function getName() public view returns(string memory name){
        return _name;

}

function deposite(uint amount) public{
        _balance+=amount;
}

}