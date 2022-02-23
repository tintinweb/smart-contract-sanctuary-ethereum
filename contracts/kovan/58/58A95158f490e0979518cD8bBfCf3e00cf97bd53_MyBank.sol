/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyBank {

    mapping(address => uint) _balances;

    event Deposit(address indexed onwer, uint amount);
    event Withdraw(address indexed onwer, uint amount);
    event Transfer(address indexed onwer, address indexed to, uint amount);

    uint private _totalBankAmount = 0;

    function totalBankAmount() public view returns (uint total) {
        return _totalBankAmount;
    }

    function _balance() public view returns (uint total) {
        return _balances[msg.sender];
    }

    function deposit() public payable {
        require(
            msg.value > 0,
            "Your amount is incorrect."
        );

        uint amount = msg.value;
        _balances[msg.sender] += amount;
        _totalBankAmount += amount;
        emit Deposit(msg.sender, amount);
    }

    function withdraw(uint amount) public payable {
        require(
            _balances[msg.sender] >= amount,
            "Not enough money"
        );

        payable(msg.sender).transfer(amount);
        _balances[msg.sender] -= amount;
        _totalBankAmount -= amount;
        emit Withdraw(msg.sender, amount);
    }

    function transfer(address to, uint amount) public payable {
        require(
            _balances[to] >= 0,
            "The destination account is not found in the system or the balance is insufficient."
        );

        require(
            _balances[msg.sender] >= amount,
            "Not enough money"
        );

        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }
}