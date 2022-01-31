/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MyContract {
    string _name;
    uint _balance;

    constructor(string memory name, uint balance) {
        require(balance >= 500,"balance greater than 500");
        _name = name;
        _balance = balance;
    }

    function getBalance() public view returns(uint balance) {
        return _balance;
    }

    function deposit(uint amount) public {
        require(amount >=1,"amount greater than 1");
        _balance += amount;
    }

}