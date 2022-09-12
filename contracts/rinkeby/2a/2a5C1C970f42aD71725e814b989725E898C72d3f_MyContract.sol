/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract MyContract {

string _name;
uint _balance;
constructor(string memory name, uint balance){
    require(balance>=50,"balance must be greater than zewro");
    _name = name;
    _balance = balance;

}
function getBalance() public view returns (uint balance) {
    return _balance;
}

// function sayHi() public pure returns (string hi) {
//     hi = "hi";
//     return hi;
// }

function deposite(uint amount) public{
    _balance+=amount;
}

}