/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

// SPDX-License-Identifier: AFL-3.0
pragma solidity ^0.8.6;

contract investment_normal{

    uint public totalDepositAmount;
    uint public totalInvestmentAmount;

    mapping (address => uint) public investments;

    uint private constant TIME_LOCK = 1667928600; // 11-08-22, 9:30AM

    address private owner;
    address[] private keys;

    event depositEvent(uint amount);
    event investEvent(address investor, uint amount);
    event interestEvent(address investor, uint amount);
    event testEvent(uint remainingBalance);

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
        uint tempTotalDeposit = totalDepositAmount + msg.value;
        require (tempTotalInvestment <= (tempTotalDeposit / 2)); // make sure there is enough deposit to pay back interest
        totalInvestmentAmount = tempTotalInvestment;
        totalDepositAmount = tempTotalDeposit;
        investments[msg.sender] += msg.value;
        keys.push(msg.sender);
        emit investEvent(msg.sender, msg.value);
    }

    function getInterest() public{
        require (block.timestamp > TIME_LOCK);
        uint total = investments[msg.sender] * 2;
        require (total > 0);
        payable(msg.sender).transfer(total);
        totalDepositAmount -= total;
        totalInvestmentAmount -= (total / 2);
        investments[msg.sender] = 0;
        emit interestEvent(msg.sender, total);
    }

    function resetDeposit() public{ // for testing
        require (msg.sender == owner);
        emit testEvent(totalDepositAmount);
        payable(owner).transfer(address(this).balance);
        totalDepositAmount = 0;
        totalInvestmentAmount = 0;
        uint index;
        for(index = 0; index < keys.length; index++){
            investments[keys[index]] = 0;
        }
    }

}