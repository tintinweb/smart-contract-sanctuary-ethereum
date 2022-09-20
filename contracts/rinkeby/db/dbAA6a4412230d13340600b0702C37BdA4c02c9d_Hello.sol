/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Hello {
    string public hello = "Hello";
    string private _name;
    uint private _balance;

    constructor(string memory name, uint balance) {
        require(balance >= 100, "Minimum initial balance is 100");
        _name = name;
        _balance = balance;
    }

    function getBalance() public view returns(uint balance) {
        return _balance;
    }

    function transfer(uint amount) public returns(uint balance) {
        require(_balance >= amount, "Insufficient balance.");
        _balance -= amount;
        return _balance;
    }
}