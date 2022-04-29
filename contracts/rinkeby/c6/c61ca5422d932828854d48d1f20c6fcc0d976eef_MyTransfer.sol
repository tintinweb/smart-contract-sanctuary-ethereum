/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MyTransfer{
    mapping(address => uint) _balance;

    event Transfer(address indexed from, address indexed to, uint value);
    event Deposit(address indexed from, uint value);

    function deposit() public payable{
        require(msg.value > 0, "zero");
        _balance[msg.sender] += msg.value; 
        emit Deposit(msg.sender, msg.value);
    }
    function transfer(address to, uint amount) public payable returns(bool success){
        require(_balance[msg.sender] >= amount);
        _balance[msg.sender] = _balance[msg.sender] - (amount);
        _balance[to] = _balance[to] + (amount);
        emit Transfer(msg.sender, to, amount);
        payable(to).transfer(amount);
        return true;
    }

    function getBalance() public view returns(uint balance){
        return _balance[msg.sender];
    }
}