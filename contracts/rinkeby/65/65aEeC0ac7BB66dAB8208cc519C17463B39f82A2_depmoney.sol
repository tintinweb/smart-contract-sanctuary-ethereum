/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

//SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.0;
contract depmoney{

string _name;
uint _balance;

constructor (string memory name,uint balance){
    require (balance>=100,"must greater than 100");
    _name=name;
    _balance=balance;

}
function getbal() public view returns(uint balance){
    return _balance;
}

function deposit(uint amount) public{
    _balance+=amount;
}

}