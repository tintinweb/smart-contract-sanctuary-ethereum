/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract bankBirth {
    mapping(address => uint) _balance;
    uint _totalTransaction;

    modifier isMoreBalance(uint amount) {
        require(_balance[msg.sender] > amount, "amount must be less balance");
        _;
    }
    function deposit() public payable {
        _balance[msg.sender] += msg.value;
        _totalTransaction += msg.value;
    }

    function withdraw(uint amount) public payable isMoreBalance(amount) {
        payable(msg.sender).transfer(amount);
        _balance[msg.sender] -= amount;
        _totalTransaction -= amount;
    }

    function checkBalance() public view returns (uint balance) {
        return _balance[msg.sender];
    }

    function checkTotal() public view returns (uint totalTransaction) {
        return _totalTransaction;
    }
}