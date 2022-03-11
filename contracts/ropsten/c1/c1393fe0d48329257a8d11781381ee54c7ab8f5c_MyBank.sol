/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyBank {

mapping(address => uint) _balances;
event ReportDeposit(address indexed Owner, uint amount);
event ReportWithdraw(address indexed Owner, uint amount);

function deposit() public payable {
    _balances[msg.sender] += msg.value;
    emit ReportDeposit(msg.sender,msg.value);
}

function withdraw() public payable {
    _balances[msg.sender] -= msg.value;
    emit ReportWithdraw(msg.sender,msg.value);
}

function getBalance() public view returns(uint){
    return _balances[msg.sender];
}

}