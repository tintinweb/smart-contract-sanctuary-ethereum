/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Bank {

    mapping(address => uint) _balance;
    event Deposit(address indexed owner, uint amount); // indexed เพื่อไว้ filter 
    event Withdraw(address indexed owner, uint amount);

    function deposit() public payable {
        require(msg.value > 0, "deposit money is zero");

        _balance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amount) public payable {
        require(amount > 0 && amount <= _balance[msg.sender], "not enough money");

        payable(msg.sender).transfer(amount);
        _balance[msg.sender] -= amount;
        emit Withdraw(msg.sender, amount);
    }

    function checkBalance() public view returns (uint myBalance) {
        return _balance[msg.sender];
    }

    function checkBalanceByAddress(address owner) public view returns (uint myBalance) {
        return _balance[owner];
    }
}