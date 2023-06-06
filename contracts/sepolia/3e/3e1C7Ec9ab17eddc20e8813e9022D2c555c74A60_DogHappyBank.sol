/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

//SPDX-License-Identifier: MIT

// This is a basic contract for understanding Deposit/Withdraw/checkBalance.

pragma solidity ^0.8.0;

contract DogHappyBank {
    
    mapping(address => uint) _balances;
    event Deposit(address indexed owner, uint amount);
    event Withdraw(address indexed owner, uint amount);

    address public shelter;

    constructor() {
        shelter = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == shelter, "Only Shelter can call this function.");
        _;
    }

    function deposit() public payable {
        require(msg.value > 0, "deposit money is zero !!!");

        _balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amount) onlyOwner public {
        require(amount > 0 && amount <= _balances[msg.sender], "not enough money !!!");

        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        emit Withdraw(msg.sender, amount);
    }

    function balance() public view returns(uint) {
        return _balances[msg.sender];
    }

    function balanceOf(address owner) public view returns(uint) {
        return _balances[owner];
    }
}