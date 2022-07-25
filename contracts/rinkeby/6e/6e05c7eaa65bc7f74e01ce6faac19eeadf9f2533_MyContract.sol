/**
 *Submitted for verification at Etherscan.io on 2022-07-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract{

//private 
string _name;
string _surname;
uint _stdid;

constructor(string memory name, uint stdid){
    _name = name;
    _stdid = stdid;
}

function getBalance()public view returns(uint stdid){
    return _stdid;
}
}