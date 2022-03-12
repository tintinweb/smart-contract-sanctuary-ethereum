/**
 *Submitted for verification at Etherscan.io on 2022-03-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyBank {

mapping(address => uint) _balances;
event ReportDeposit(address indexed Owner, uint amount);
event ReportWithdraw(address indexed Owner, uint amount);

function deposit() public payable {
      require(_balances[msg.sender] >= 0 ,"Deposit money is zero");

    _balances[msg.sender] += msg.value;
    emit ReportDeposit(msg.sender,msg.value);
}

function withdraw(uint amount) public{
      require(amount <= _balances[msg.sender] && amount > 0 ,"not enough money" );

     emit ReportWithdraw(msg.sender,amount);
    payable(msg.sender).transfer(amount);
    _balances[msg.sender] -= amount;

    
}

function getBalance() public view returns(uint){
    return _balances[msg.sender];
}

}