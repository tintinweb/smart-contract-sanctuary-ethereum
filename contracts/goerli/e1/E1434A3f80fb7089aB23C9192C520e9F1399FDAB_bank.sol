/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.4.22 <0.9.0;

contract bank{

uint balance;
constructor() {
    balance = 550;
}
function getBalance() view public returns(uint){
     return balance;
}

function withdraw(uint amount) public{

    balance -= amount;
}

function deposit(uint amount) public{

    balance += amount;
}
}