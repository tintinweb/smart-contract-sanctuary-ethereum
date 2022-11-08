/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

// SPDX-License-Identifier: AFL-3.0
pragma solidity ^0.8.6;

contract investment_normal{

    uint public totalDepositAmount;
    uint public totalInvestmentAmount;

    mapping (address => uint) public investments;

    uint private constant TIME_LOCK = 1667873160;

    address private owner;

    event depositEvent(uint amount);
    event investEvent(address investor, uint amount);
    event interestEvent(address investor, uint amount);

    constructor() {
        totalDepositAmount = 0;
        totalInvestmentAmount = 0;

        owner = msg.sender;
    }

    function deposit() public payable {
        require (msg.sender == owner);
        totalDepositAmount += msg.value;
        emit depositEvent(msg.value);
    }

    function invest() public payable {
        uint tempTotalInvestment = totalInvestmentAmount + msg.value;
        require (tempTotalInvestment <= (totalDepositAmount / 2)); // make sure there is enough deposit to pay back interest
        totalInvestmentAmount = tempTotalInvestment;
        investments[msg.sender] += msg.value;
        emit investEvent(msg.sender, msg.value);
    }

    function getInterest() public{
        require (block.timestamp > TIME_LOCK);
        uint total = investments[msg.sender] * 2;
        require (total > 0);
        payable(msg.sender).transfer(total);
        investments[msg.sender] = 0;
        emit interestEvent(msg.sender, total);
    }

}