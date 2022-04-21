/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract BankSmartContract {
    mapping(address => uint) _balances; // owner => balance
    uint _totalBalance;
    event Deposit(address indexed from, uint amount);
    event Transfer(address indexed from, address indexed to, uint amount);
    event Withdraw(address indexed to, uint amount);

    function checkTotal() public view returns (uint totalBalance) {
        return _totalBalance;
    }

    function checkBalanceOwner(address owner) public view returns (uint balance) {
        return _balances[owner];
    }

    function deposit() public payable {
        _balances[msg.sender] += msg.value;
        _totalBalance += msg.value;

        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amount) public payable {
        require(amount < _balances[msg.sender], "balance not enough");
        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        _totalBalance -= amount;

        emit Withdraw(msg.sender, amount);
    }

    function transfer(address to, uint amount) public {
        require(amount < _balances[msg.sender], "balance not enough");
        require(to != address(0), "don't transfer to address zero");
        
        _balances[msg.sender] -= amount;
        _balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
    }
}