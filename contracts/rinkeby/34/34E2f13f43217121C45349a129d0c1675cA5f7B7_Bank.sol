/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

contract Bank {
    mapping(address => uint) _balance;
    uint _totalSupply;

    function deposit() public payable {
        _balance[msg.sender] += msg.value;
    }

    function withdraw(uint amount) public payable {
        require(amount <= _balance[msg.sender], "not enough money");
        payable(msg.sender).transfer(amount);
        _balance[msg.sender] -= amount;
        _totalSupply -= amount;
    }

    function checkBalance() public view returns (uint balance){
        return _balance[msg.sender];
    }

    function checkTotalSupply() public view returns (uint totalSupply) {
        return _totalSupply;
    }
}