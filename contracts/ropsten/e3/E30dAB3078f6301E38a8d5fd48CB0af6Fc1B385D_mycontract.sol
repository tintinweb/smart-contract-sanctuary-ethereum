/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract mycontract{
//private
string _name;
uint _balance;
constructor(string memory name,uint balance){
    // require(balance>=500,"balance greater zero (money>500)");
    _name=name;
    _balance=balance;

}

function getbalance() public  view returns(uint balance){
    return _balance;
}

// function deposite(uint amount) public {
//     _balance+=amount;   

// }
}