/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract OhmCon{
    
    string name;
    int balance;
    constructor(string memory names,int balances){
            name = names;
            balance = balances;

    }

    function getBalance() public view returns(int balances){
        return balance;
    }

    function deposit(int amount) public {
        balance = balance + amount;
    }



}