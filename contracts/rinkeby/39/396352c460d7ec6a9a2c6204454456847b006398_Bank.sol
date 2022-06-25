/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract Bank {
    mapping(address => uint) _balance;
    uint _totalsupply;

    function Deposit() public payable {
        _balance[msg.sender] += msg.value;
        _totalsupply += msg.value;
    }

    function Withdraw(uint amount) public payable {
        require(amount <= _balance[msg.sender], "You do not have enough monty");
        
        payable(msg.sender).transfer(amount);
        _balance[msg.sender] -= amount;
        _totalsupply -= amount;
    }

    function Netbalance() public view returns (uint _Outstanding){
        return _balance[msg.sender];
    }

    function Checktotalsupply() public view returns (uint Totalsupply){
        return _totalsupply;
    }

}