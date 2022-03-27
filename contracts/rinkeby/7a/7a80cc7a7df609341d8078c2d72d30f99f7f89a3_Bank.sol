/**
 *Submitted for verification at Etherscan.io on 2022-03-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract Bank{

    mapping(address => uint) _balance;
    event Deposite(address indexed owner , uint amount);
    event Withdraw(address indexed owner , uint amount);

    function deposit() public payable {
        require(msg.value > 0, "deposite money must more zero");
        _balance[msg.sender] += msg.value;
        emit Deposite(msg.sender , msg.value);
    }

    function withdraw(uint amount) public{
        require(amount > 0 && amount <= _balance[msg.sender], "Not enough money");

        payable(msg.sender).transfer(amount);
        _balance[msg.sender] -= amount;
        emit Withdraw(msg.sender , amount);
    }

    function balance() public view returns(uint){
        return _balance[msg.sender];
    }
    
    function balanceOf(address owner) public view returns(uint){
        return _balance[owner];
    }
}