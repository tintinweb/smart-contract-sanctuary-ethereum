/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract test01{
    uint _balance;
    string _name;
    constructor(string memory name, uint amount){
        require(amount>=500, "amount must be equal or greater than 500");
        _balance = amount;
        _name = name;
    }
    function getBalance()public view returns(uint eiei){
        return _balance;
    }
    function deposit(uint amount) public{
        _balance+=amount;
    }
}