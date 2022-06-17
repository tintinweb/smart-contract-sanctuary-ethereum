/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyContract{

//private
/*
bool status = false;
string public name = "All";
int amount = 0;
uint balance = 1000;
*/

string _name;
uint _balance;

// Need gas
constructor(string memory name, uint balance) {
    //require(balance > 0,"balance greater zero (money>0)");
    require(balance >= 500, "balance greater and equal 500");

    _name = name;
    _balance = balance;
}

// reference value in constant value : pure (No need gas)   
//function getBalance() public pure returns(uint balance)  {   
    //return _balance;
    //return 50;
//}

// reference value in state or value : view (No need gas)
function getBalance() public view returns(uint balance) {
    return _balance;
}

/*
function deposite(uint amount) public {
    _balance += amount;
    
}
*/


}