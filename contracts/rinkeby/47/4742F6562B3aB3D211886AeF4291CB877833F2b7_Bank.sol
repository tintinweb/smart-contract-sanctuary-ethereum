/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Bank {

    mapping(address => uint) _balance;
    event ReportDeposit(address indexed Owner , uint amount);
    event ReportWithraw(address indexed Owner , uint amount);
    

    function deposit() public payable {
        require(msg.value > 0 , "Deposit money is zero");

        _balance[msg.sender] += msg.value;  
        emit ReportDeposit(msg.sender , msg.value);   
    }

    function withdraw(uint amount) public {
        require(amount > 0 && amount <= _balance[msg.sender],"not enough money");

        payable(msg.sender).transfer(amount);
        _balance[msg.sender] -= amount;
        emit ReportWithraw(msg.sender , amount);
    }
    function balance() public view returns(uint){
        return _balance[msg.sender];
    }

}