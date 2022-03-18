/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract mycontract{
//private
string  _name = "Sign";
uint _balance = 1000;
constructor(string memory name,uint balance){

    _name = name;
    _balance = balance;
} 

function getBlance() public view returns(uint blance){
    return _balance;
}



}