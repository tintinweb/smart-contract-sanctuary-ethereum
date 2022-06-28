/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract MyContract {
    string private name;
    uint private balance;

    constructor(string memory _name, uint _balance) {
        name = _name;
        balance = _balance;
    }

    function getBalance() public view returns(uint _balance){
        return balance;
    }

    function getName() public view returns(string memory _name){
        return name;
    }

    function deposit(uint amount) public {
        balance += amount;
    }

    function withdraw(uint amount) public{
        balance -= amount;
    }
  
}